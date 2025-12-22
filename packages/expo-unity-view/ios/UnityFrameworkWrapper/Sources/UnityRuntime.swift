import Foundation
import UIKit
#if canImport(UnityFramework)
import MachO
import UnityFramework
#endif

@objc protocol NativeCallsProtocol {
  func showHostMainWindow(_ color: String)
  func sendMessageToReactNative(_ message: String)
}

public protocol UnityRuntimeDelegate: AnyObject {
  func unityRuntime(_ runtime: UnityRuntime, didReceiveMessage message: String)
  func unityRuntimeDidStart(_ runtime: UnityRuntime)
  func unityRuntimeDidQuit(_ runtime: UnityRuntime)
}

public extension UnityRuntimeDelegate {
  func unityRuntimeDidStart(_ runtime: UnityRuntime) {}
  func unityRuntimeDidQuit(_ runtime: UnityRuntime) {}
}

public final class UnityRuntime: NSObject {
  public static let shared = UnityRuntime()

  private override init() {}

#if canImport(UnityFramework)
  private var ufw: UnityFramework?
  private var unityBundle: Bundle?
  private var hasRun = false
#else
  private var hasRun = false
#endif

  private weak var delegate: UnityRuntimeDelegate?

  private func runOnMain<T>(_ work: () -> T) -> T {
    if Thread.isMainThread {
      return work()
    }
    return DispatchQueue.main.sync { work() }
  }

  @discardableResult
  public func startIfNeeded() -> Bool {
    runOnMain { startUnityIfNeeded() }
  }

  public func unityView() -> UIView? {
    runOnMain {
#if canImport(UnityFramework)
      guard startUnityIfNeeded(), let view = ufw?.appController()?.rootView else { return nil }
      return view
#else
      return nil
#endif
    }
  }

  public func isInitialized() -> Bool {
    runOnMain { hasRun }
  }

  @discardableResult
  public func sendMessage(objectName: String, methodName: String, message: String) -> Bool {
    runOnMain {
#if canImport(UnityFramework)
      guard hasRun, let ufw else { return false }
      ufw.sendMessageToGO(withName: objectName, functionName: methodName, message: message)
      return true
#else
      return false
#endif
    }
  }

  public func setDelegate(_ delegate: UnityRuntimeDelegate?) {
    self.delegate = delegate
  }

  public func unload() {
#if canImport(UnityFramework)
    ufw?.unloadApplication()
    hasRun = false
    ufw = nil
    unityBundle = nil
#else
    hasRun = false
#endif
  }

  private func startUnityIfNeeded() -> Bool {
#if canImport(UnityFramework)
    if ufw == nil {
      ufw = loadUnityFramework()
    }
    guard let ufw else {
      NSLog("[UnityRuntime] UnityFramework not loaded")
      return false
    }

    if !hasRun {
      ufw.register(self)
      registerNativeCallsProxy()

      if let bundleId = resolveDataBundleId() {
        ufw.setDataBundleId(bundleId)
      } else {
        NSLog("[UnityRuntime] Data bundle not found; Unity may fail to locate assets.")
      }

      ufw.runEmbedded(
        withArgc: CommandLine.argc,
        argv: CommandLine.unsafeArgv,
        appLaunchOpts: nil
      )
      hasRun = true
      delegate?.unityRuntimeDidStart(self)

      if let unityWindow = ufw.appController()?.window {
        unityWindow.isHidden = true
      }
      if let appWindow = UIApplication.shared.windows.first {
        appWindow.makeKeyAndVisible()
      }
    }
    return true
#else
    return false
#endif
  }
}

#if canImport(UnityFramework)
extension UnityRuntime: UnityFrameworkListener, NativeCallsProtocol {
  public func showHostMainWindow(_ color: String) {
    NSLog("[UnityRuntime] showHostMainWindow noop color=%@", color)
  }

  public func sendMessageToReactNative(_ message: String) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      self.delegate?.unityRuntime(self, didReceiveMessage: message)
    }
  }

  public func unityDidUnload(_ notification: Notification) {
    hasRun = false
    ufw = nil
    unityBundle = nil
    delegate?.unityRuntimeDidQuit(self)
  }

  public func unityDidQuit(_ notification: Notification) {
    hasRun = false
    ufw = nil
    unityBundle = nil
    delegate?.unityRuntimeDidQuit(self)
  }

  private func loadUnityFramework() -> UnityFramework? {
    let bundlePath = Bundle.main.bundlePath + "/Frameworks/UnityFramework.framework"
    guard let bundle = Bundle(path: bundlePath) else {
      NSLog("[UnityRuntime] Missing UnityFramework at %@", bundlePath)
      return nil
    }
    unityBundle = bundle

    if !bundle.isLoaded { bundle.load() }

    guard let ufwClass = bundle.principalClass as? UnityFramework.Type,
          let framework = ufwClass.getInstance() else {
      NSLog("[UnityRuntime] Could not get UnityFramework instance.")
      return nil
    }

    if framework.appController() == nil, let headerPtr = _dyld_get_image_header(0) {
      let machHeader = UnsafeRawPointer(headerPtr).assumingMemoryBound(to: MachHeader.self)
      framework.setExecuteHeader(machHeader)
    }
    return framework
  }

  private func resolveDataBundleId() -> String? {
    let fm = FileManager.default
    var candidates: [(String, String)] = []

    if let mainId = Bundle.main.bundleIdentifier {
      candidates.append((mainId, Bundle.main.bundlePath + "/Data"))
    }

    if let unityBundle {
      let id = unityBundle.bundleIdentifier ?? "com.unity3d.framework"
      candidates.append((id, unityBundle.bundlePath + "/Data"))
    } else {
      let defaultId = "com.unity3d.framework"
      let defaultPath = Bundle.main.bundlePath + "/Frameworks/UnityFramework.framework/Data"
      candidates.append((defaultId, defaultPath))
    }

    let wrapperId = "org.cocoapods.UnityFrameworkWrapper"
    if let wrapperBundle = Bundle(identifier: wrapperId) {
      candidates.append((wrapperId, wrapperBundle.bundlePath + "/Data"))
    }

    for (bundleId, dataPath) in candidates {
      if fm.fileExists(atPath: dataPath) {
        return bundleId
      }
    }

    return nil
  }

  private func registerNativeCallsProxy() {
    guard let cls = NSClassFromString("FrameworkLibAPI") as? NSObjectProtocol else {
      NSLog("[UnityRuntime] FrameworkLibAPI not found; NativeCallProxy unavailable")
      return
    }
    let sel = NSSelectorFromString("registerAPIforNativeCalls:")
    if cls.responds(to: sel) {
      _ = (cls as AnyObject).perform(sel, with: self)
    }
  }
}
#endif
