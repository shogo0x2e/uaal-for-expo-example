import ExpoModulesCore
import UIKit
import UnityFrameworkWrapper

final class ExpoUnityView: ExpoView {
  private var unityView: UIView?

  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    clipsToBounds = true
    backgroundColor = .clear
    attachUnityIfNeeded()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    unityView?.frame = bounds
  }

  // Always non-interactive: let touches pass through to RN hierarchy.
  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool { false }
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? { nil }

  private func attachUnityIfNeeded() {
    guard unityView == nil, let view = UnityRuntime.shared.unityView() else { return }
    view.removeFromSuperview()
    view.frame = bounds
    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.isUserInteractionEnabled = false
    addSubview(view)
    unityView = view
  }
}
