package com.example.aula_inteligente

import android.content.Context
import android.content.SharedPreferences
import android.nfc.cardemulation.HostApduService
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.widget.Toast

class HceService : HostApduService() {

    companion object {
        private val SELECT_AID = byteArrayOf(
            0x00, 0xA4.toByte(), 0x04, 0x00, 0x05,
            0xF0.toByte(), 0x00, 0x00, 0x00, 0x01.toByte()
        )
        private val SW_SUCCESS = byteArrayOf(0x90.toByte(), 0x00)
        private val SW_UNKNOWN = byteArrayOf(0x00, 0x00)
        private const val PREF_NAME = "hce_prefs"
        private const val KEY_UID = "hce_uid"

        fun setUid(context: Context, uid: String) {
            val prefs: SharedPreferences =
                context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
            prefs.edit().putString(KEY_UID, uid).apply()
        }

        fun getUid(context: Context): String {
            val prefs: SharedPreferences =
                context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
            return prefs.getString(KEY_UID, "") ?: ""
        }
    }

    private fun showToast(msg: String) {
        Handler(Looper.getMainLooper()).post {
            Toast.makeText(applicationContext, msg, Toast.LENGTH_SHORT).show()
        }
    }

    private fun vibrate(durationMs: Long) {
        try {
            val vibrator: Vibrator? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vm.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }
            if (vibrator != null && vibrator.hasVibrator()) {
                vibrator.vibrate(VibrationEffect.createOneShot(durationMs, VibrationEffect.DEFAULT_AMPLITUDE))
            }
        } catch (_: Exception) {}
    }

    override fun processCommandApdu(commandApdu: ByteArray, extras: Bundle?): ByteArray {
        val commandHex = commandApdu.joinToString("") { String.format("%02X", it) }
        println("[HCE_KOTLIN] processCommandApdu received command: $commandHex")
        // DIAGNOSTICO: vibracion confiable en MIUI; Toast como backup.
        vibrate(80)
        showToast("APDU: ${commandHex.take(20)}")

        val matchesSelect = commandApdu.size >= 10 && 
            commandApdu.sliceArray(0..9).contentEquals(SELECT_AID)

        if (matchesSelect) {
            println("[HCE_KOTLIN] SELECT AID matched! Returning SW_SUCCESS.")
            // Vibracion mas larga al hacer match con nuestro AID
            vibrate(300)
            showToast("SELECT AID OK")
            return SW_SUCCESS
        }

        val uid = getUid(this)
        println("[HCE_KOTLIN] Stored UID: $uid")
        if (uid.isEmpty()) {
            println("[HCE_KOTLIN] UID is empty! Returning SW_UNKNOWN.")
            return SW_UNKNOWN
        }

        val uidBytes = uid.toByteArray(Charsets.US_ASCII)
        println("[HCE_KOTLIN] Returning UID: $uid")
        return uidBytes + SW_SUCCESS
    }

    override fun onDeactivated(reason: Int) {
        println("[HCE_KOTLIN] Service deactivated. Reason: $reason")
    }
}
