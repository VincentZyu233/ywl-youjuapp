package com.youju.tcuapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    private var sppPlugin: BluetoothSppPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        sppPlugin = BluetoothSppPlugin(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onDestroy() {
        sppPlugin?.cleanUp()
        sppPlugin = null
        super.onDestroy()
    }
}
