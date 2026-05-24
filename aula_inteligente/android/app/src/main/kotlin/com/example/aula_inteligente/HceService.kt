package com.example.aula_inteligente

import android.content.Context
import android.content.SharedPreferences
import android.nfc.cardemulation.HostApduService
import android.os.Bundle

class HceService : HostApduService() {

    companion object {
        private val SELECT_AID = byteArrayOf(
            0x00, 0xA4, 0x04, 0x00, 0x07,
            0xF0.toByte(), 0x00, 0x00, 0x00, 0x01.toByte(), 0x00, 0x00
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

    override fun processCommandApdu(commandApdu: ByteArray, extras: Bundle?): ByteArray {
        if (commandApdu.contentEquals(SELECT_AID)) {
            return SW_SUCCESS
        }
        val uid = getUid(this)
        if (uid.isEmpty()) return SW_UNKNOWN
        val uidBytes = uid.toByteArray(Charsets.US_ASCII)
        return uidBytes + SW_SUCCESS
    }

    override fun onDeactivated(reason: Int) {}
}
