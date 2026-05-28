package com.example.aula_inteligente

import android.os.Build
import android.os.Bundle
import android.content.ComponentName
import android.content.Context
import android.nfc.NfcAdapter
import android.nfc.cardemulation.CardEmulation
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.aula_inteligente/hce"
    private var nfcAdapter: NfcAdapter? = null
    private var cardEmulation: CardEmulation? = null

    private fun diagVibrate(pattern: LongArray) {
        try {
            val vibrator: Vibrator? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vm.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }
            if (vibrator != null && vibrator.hasVibrator()) {
                vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
            }
        } catch (_: Exception) {}
    }

    private fun diagToast(msg: String) {
        Toast.makeText(this, msg, Toast.LENGTH_LONG).show()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        nfcAdapter = NfcAdapter.getDefaultAdapter(this)
        if (nfcAdapter != null) {
            cardEmulation = CardEmulation.getInstance(nfcAdapter)
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setHceUid" -> {
                    val uid = call.argument<String>("uid") ?: ""
                    HceService.setUid(this, uid)
                    
                    if (uid.isNotEmpty()) {
                        val ce = cardEmulation
                        if (ce == null) {
                            diagToast("NFC no disponible (CardEmulation null)")
                            diagVibrate(longArrayOf(0, 500))
                        } else {
                            val componentName = ComponentName(this, HceService::class.java)
                            val ok = ce.setPreferredService(this, componentName)
                            println("[HCE_KOTLIN] setPreferredService activated: $ok")
                            if (ok) {
                                diagToast("HCE preferred OK")
                                // 2 vibraciones cortas = exito
                                diagVibrate(longArrayOf(0, 80, 80, 80))
                            } else {
                                diagToast("HCE preferred FAIL")
                                // 1 vibracion larga = fallo
                                diagVibrate(longArrayOf(0, 500))
                            }
                        }
                    } else {
                        cardEmulation?.let { ce ->
                            val ok = ce.unsetPreferredService(this)
                            println("[HCE_KOTLIN] unsetPreferredService: $ok")
                        }
                    }
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

    override fun onResume() {
        super.onResume()
        val uid = HceService.getUid(this)
        if (uid.isNotEmpty()) {
            cardEmulation?.let { ce ->
                val componentName = ComponentName(this, HceService::class.java)
                val ok = ce.setPreferredService(this, componentName)
                println("[HCE_KOTLIN] onResume setPreferredService activated: $ok")
            }
        }
    }

    override fun onPause() {
        super.onPause()
        cardEmulation?.let { ce ->
            val ok = ce.unsetPreferredService(this)
            println("[HCE_KOTLIN] onPause unsetPreferredService: $ok")
        }
    }
}
