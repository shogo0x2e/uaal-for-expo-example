import ExpoModulesCore

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

    AsyncFunction("sendUnityMessage") { (message: [String: Any?]) in
      let objectName = message["objectName"] ?? "nil"
      let methodName = message["methodName"] ?? "nil"
      let body = message["message"] ?? "nil"
      print("ExpoUnityView sendUnityMessage objectName=\(objectName) methodName=\(methodName) message=\(body) // TODO: UnitySendMessage")
    }

    Function("addUnityMessageListener") {
      print("ExpoUnityView addUnityMessageListener // TODO: Unityからの受信をブリッジ")
    }

    // View only; props なし
    View(ExpoUnityView.self) { }
  }
}
