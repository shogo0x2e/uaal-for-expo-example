package com.shogo0x2e.uaalforexpoexample.unityview

import android.util.Log
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class ExpoUnityViewModule : Module() {
  // Each module class must implement the definition function. The definition consists of components
  // that describes the module's functionality and behavior.
  // See https://docs.expo.dev/modules/module-api for more details about available components.
  override fun definition() = ModuleDefinition {
    // Sets the name of the module that JavaScript code will use to refer to the module. Takes a string as an argument.
    // Can be inferred from module's class name, but it's recommended to set it explicitly for clarity.
    // The module will be accessible from `requireNativeModule('ExpoUnityView')` in JavaScript.
    Name("ExpoUnityView")

    Events("unityMessage")

    AsyncFunction("sendUnityMessage") { message: Map<String, Any?> ->
      val objectName = message["objectName"]
      val methodName = message["methodName"]
      val body = message["message"]
      Log.d(
        "ExpoUnityView",
        "sendUnityMessage objectName=$objectName methodName=$methodName message=$body // TODO: UnitySendMessage"
      )
    }

    Function("addUnityMessageListener") {
      Log.d("ExpoUnityView", "addUnityMessageListener // TODO: Unityからの受信をブリッジ")
    }

    // No props/events on the view; pure rendering surface.
    View(ExpoUnityView::class) { }
  }
}
