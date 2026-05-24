package com.example.aula_inteligente

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.aula_inteligente/hce"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setHceUid" -> {
                    val uid = call.argument<String>("uid") ?: ""
                    HceService.setUid(this, uid)
                    result.success(true)
                }
                "getHceUid" -> {
                    val uid = HceService.getUid(this)
                    result.success(uid)
                }
                else -> result.notImplemented()
            }
        }
    }
}
