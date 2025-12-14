package com.shogo0x2e.uaalforexpoexample.unityview

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.util.Log
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.views.ExpoView

private const val PLACEHOLDER_COLOR: Int = Color.RED
private const val TAG = "ExpoUnityView"

class ExpoUnityView(context: Context, appContext: AppContext) : ExpoView(context, appContext) {
  private val surfaceView: SurfaceView = SurfaceView(context).apply {
    layoutParams = LayoutParams(MATCH_PARENT, MATCH_PARENT)
    holder.setFormat(PixelFormat.TRANSLUCENT)
    setBackgroundColor(PLACEHOLDER_COLOR)
    setWillNotDraw(false)
    holder.addCallback(object : SurfaceHolder.Callback {
      override fun surfaceCreated(holder: SurfaceHolder) {
        holder.lockCanvas()?.let { canvas ->
          canvas.drawColor(PLACEHOLDER_COLOR) // dummy clear until Unity is wired in
          holder.unlockCanvasAndPost(canvas)
        }
        Log.d(TAG, "surfaceCreated: placeholder drawn")
      }
      override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) = Unit
      override fun surfaceDestroyed(holder: SurfaceHolder) = Unit
    })

    // Let overlay React children handle input
    isClickable = false
    isFocusable = false
    isFocusableInTouchMode = false
  }

  init {
    addView(surfaceView)
  }
}
