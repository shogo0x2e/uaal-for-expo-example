package com.shogo0x2e.uaalforexpoexample.unityview

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.ViewGroup
import com.unity3d.player.UnityPlayer
import com.unity3d.player.UnityPlayerForActivityOrService

/**
 * Single UnityPlayer instance shared across all ExpoUnityView instances.
 */
object UnityManager {
  @Volatile
  private var unityPlayer: UnityPlayerForActivityOrService? = null
  private val lock = Any()

  fun isInitialized(): Boolean = unityPlayer != null

  private fun obtainPlayer(context: Context): UnityPlayerForActivityOrService {
    synchronized(lock) {
      if (unityPlayer == null) {
        unityPlayer = UnityPlayerForActivityOrService(context)
      }
      return requireNotNull(unityPlayer)
    }
  }

  fun ensureInitialized(context: Context) {
    val mainLooper = Looper.getMainLooper()
    if (Looper.myLooper() != mainLooper) {
      Handler(mainLooper).post { ensureInitialized(context) }
      return
    }
    obtainPlayer(context)
  }

  fun obtainView(context: Context): View {
    check(Looper.myLooper() == Looper.getMainLooper()) { "Unity view must be obtained on main thread" }
    val player = obtainPlayer(context)
    val playerView = player.view
    (playerView.parent as? ViewGroup)?.removeView(playerView)
    return playerView
  }

  fun sendMessage(objectName: String, methodName: String, message: String) {
    UnityPlayer.UnitySendMessage(objectName, methodName, message)
  }

  fun resume() {
    unityPlayer?.resume()
  }

  fun pause() {
    unityPlayer?.pause()
  }

  fun windowFocusChanged(hasFocus: Boolean) {
    unityPlayer?.windowFocusChanged(hasFocus)
  }

  fun destroy() {
    synchronized(lock) {
      unityPlayer?.destroy()
      unityPlayer = null
    }
  }
}
