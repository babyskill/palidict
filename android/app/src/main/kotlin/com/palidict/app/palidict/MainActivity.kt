package com.palidict.app.palidict

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var assetPackBridge: AssetPackBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        assetPackBridge = AssetPackBridge(this, flutterEngine.dartExecutor.binaryMessenger)
    }
}
