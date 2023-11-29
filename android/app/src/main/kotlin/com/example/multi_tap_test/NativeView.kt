package com.example.multi_tap_test

import android.content.Context
import android.text.method.Touch
import android.util.DisplayMetrics
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

internal class NativeView(
    context: Context,
    messenger: BinaryMessenger,
    id: Int,
    creationParams: Map<String?, Any?>?
) : PlatformView, MethodChannel.MethodCallHandler {
    //    private val textView: TextView
    private val nativeView: View
    private val channel = MethodChannel(messenger, "multi_touch")

    override fun getView(): View {
        return nativeView
    }

    override fun dispose() {
    }

    init {
//        textView = TextView(context)
//        textView.textSize = 72f
//        textView.setBackgroundColor(Color.rgb(255, 255, 255))
//        textView.text = "Rendered on a native Android view (id: $id)"
        nativeView = NativeViewAndroid(context, channel)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "get_data") {
//            nativeView.someMethod()
//            result.success(true)
        } else {
            result.notImplemented()
        }
    }
}

class NativeViewAndroid(context: Context, methodChannel: MethodChannel) : FrameLayout(context) {
    private val channel = methodChannel

    init {
        // Initialize your native view here
        // You can add touch listeners, etc.
    }

    // Example method to be called from Flutter
    fun someMethod() {
        // Do something
    }

    // Example touch event handling
    override fun onTouchEvent(event: MotionEvent): Boolean {
        // Handle touch events and obtain coordinates

        var map = mutableMapOf<String, String>()
        for (i in 0 until event.pointerCount) {
            val x = event.getX(i)
            val y = event.getY(i)
            // Process x, y for each touch point
            map = (map + ("$i" to mapOf("x" to x, "y" to y))) as MutableMap<String, String>

        }
        val screenSize = getScreenSize()
        map = (map + ("size" to mapOf(
            "x" to screenSize.widthPixels,
            "y" to screenSize.heightPixels
        ))) as MutableMap<String, String>
        channel.invokeMethod("touch", map)
        performClick()

        return true
    }

    override fun performClick(): Boolean {
        super.performClick()
        return true
    }

    // Cleanup resources when the native view is disposed
    fun dispose() {
        // Dispose resources
    }

    private fun getScreenSize(): DisplayMetrics {
        val displayMetrics = DisplayMetrics()
        val display = (context.getSystemService(Context.WINDOW_SERVICE) as WindowManager).defaultDisplay
        display.getMetrics(displayMetrics)
        return displayMetrics
    }


}
