package com.synckord.horyzontal

import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity: local_auth needs a FragmentActivity for BiometricPrompt.
class MainActivity : FlutterFragmentActivity() {
    private val wifi by lazy { WifiLink(this) }
    private val incoming by lazy { IncomingFiles(this) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        EventChannel(messenger, "horyzontal/heading").setStreamHandler(HeadingStream(this))
        wifi.register(messenger)
        incoming.register(messenger)
        MethodChannel(messenger, "horyzontal/security").setMethodCallHandler { call, result ->
            when (call.method) {
                // FLAG_SECURE: no screenshots or screen recording, blank thumbnail
                // in the app switcher.
                "setSecure" -> {
                    if (call.arguments == true) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState == null) incoming.handle(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        incoming.handle(intent)
    }

    @Deprecated("Forwarded to WifiLink, which still uses the platform permission API")
    override fun onRequestPermissionsResult(code: Int, permissions: Array<out String>, grants: IntArray) {
        @Suppress("DEPRECATION")
        super.onRequestPermissionsResult(code, permissions, grants)
        wifi.onPermissionsResult(code, permissions, grants)
    }

    override fun onDestroy() {
        wifi.dispose()
        super.onDestroy()
    }
}
