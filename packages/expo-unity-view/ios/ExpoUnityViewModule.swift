import ExpoModulesCore
import UnityFrameworkWrapper

public class ExpoUnityViewModule: Module {
  // Each module class must implement the definition function. The definition consists of components
  // that describes the module's functionality and behavior.
  // See https://docs.expo.dev/modules/module-api for more details about available components.
  public func definition() -> ModuleDefinition {
    // Sets the name of the module that JavaScript code will use to refer to the module. Takes a string as an argument.
    // Can be inferred from module's class name, but it's recommended to set it explicitly for clarity.
    // The module will be accessible from `requireNativeModule('ExpoUnityView')` in JavaScript.
    Name("ExpoUnityView")

    Events("unityMessage")

    OnCreate {
      UnityRuntime.shared.setDelegate(self)
    }

    OnDestroy {
      UnityRuntime.shared.setDelegate(nil)
    }

    AsyncFunction("sendUnityMessage") { (message: [String: Any?]) in
      let objectName = (message["objectName"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      let methodName = (message["methodName"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      let body = (message["message"] as? String ?? "")

      if objectName.isEmpty {
        throw NSError(domain: "ExpoUnityView", code: 1, userInfo: [NSLocalizedDescriptionKey: "objectName is required"])
      }
      if methodName.isEmpty {
        throw NSError(domain: "ExpoUnityView", code: 2, userInfo: [NSLocalizedDescriptionKey: "methodName is required"])
      }

      if !UnityRuntime.shared.isInitialized() {
        return
      }

      _ = UnityRuntime.shared.sendMessage(objectName: objectName, methodName: methodName, message: body)
    }

    Function("addUnityMessageListener") {
      // Listener is managed in OnCreate/OnDestroy.
    }

    // View only; props なし
    View(ExpoUnityView.self) { }
  }
}

extension ExpoUnityViewModule: UnityRuntimeDelegate {
  public func unityRuntime(_ runtime: UnityRuntime, didReceiveMessage message: String) {
    sendEvent("unityMessage", ["message": message])
  }
}
