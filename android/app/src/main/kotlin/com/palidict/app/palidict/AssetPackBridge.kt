package com.palidict.app.palidict

import android.content.Context
import com.google.android.play.core.assetpacks.AssetPackLocation
import com.google.android.play.core.assetpacks.AssetPackManager
import com.google.android.play.core.assetpacks.AssetPackManagerFactory
import com.google.android.play.core.assetpacks.AssetPackState
import com.google.android.play.core.assetpacks.AssetPackStateUpdateListener
import com.google.android.play.core.assetpacks.model.AssetPackStatus
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class AssetPackBridge(
    private val context: Context,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, "palidict/asset_packs")
    private val assetPackManager: AssetPackManager = AssetPackManagerFactory.getInstance(context)

    companion object {
        const val CORE_PACK_NAME = "core_pack"
        const val CORE_DB_FILE = "core_final.db"
    }

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "fetchCorePack" -> fetchCorePack(result)
            "getCorePackLocation" -> {
                val path = getCorePackPath()
                result.success(path)
            }
            else -> result.notImplemented()
        }
    }

    private fun getCorePackPath(): String? {
        val location: AssetPackLocation? = assetPackManager.getPackLocation(CORE_PACK_NAME)
        if (location != null) {
            val assetsPath = location.assetsPath()
            if (assetsPath != null) {
                val dbFile = File(assetsPath, CORE_DB_FILE)
                if (dbFile.exists()) {
                    return dbFile.absolutePath
                }
            }
        }
        return null
    }

    private fun fetchCorePack(result: MethodChannel.Result) {
        // If already available locally
        val existingPath = getCorePackPath()
        if (existingPath != null) {
            result.success(existingPath)
            return
        }

        var listener: AssetPackStateUpdateListener? = null
        var isResultReturned = false

        listener = AssetPackStateUpdateListener { state: AssetPackState ->
            if (state.name() == CORE_PACK_NAME) {
                when (state.status()) {
                    AssetPackStatus.COMPLETED -> {
                        listener?.let { assetPackManager.unregisterListener(it) }
                        if (!isResultReturned) {
                            isResultReturned = true
                            val path = getCorePackPath()
                            result.success(path)
                        }
                    }
                    AssetPackStatus.FAILED -> {
                        listener?.let { assetPackManager.unregisterListener(it) }
                        if (!isResultReturned) {
                            isResultReturned = true
                            result.error(
                                "ASSET_PACK_FAILED",
                                "Asset pack fetch failed with error code: ${state.errorCode()}",
                                null
                            )
                        }
                    }
                    AssetPackStatus.CANCELED -> {
                        listener?.let { assetPackManager.unregisterListener(it) }
                        if (!isResultReturned) {
                            isResultReturned = true
                            result.error("ASSET_PACK_CANCELED", "Asset pack fetch was canceled", null)
                        }
                    }
                    AssetPackStatus.DOWNLOADING -> {
                        val total = state.totalBytesToDownload()
                        val downloaded = state.bytesDownloaded()
                        if (total > 0) {
                            val progress = downloaded.toDouble() / total.toDouble()
                            channel.invokeMethod("onProgress", mapOf("progress" to progress))
                        }
                    }
                    AssetPackStatus.PENDING,
                    AssetPackStatus.TRANSFERRING,
                    AssetPackStatus.WAITING_FOR_WIFI,
                    AssetPackStatus.NOT_INSTALLED,
                    AssetPackStatus.UNKNOWN -> {
                        // Intermediate states
                    }
                }
            }
        }

        assetPackManager.registerListener(listener)

        assetPackManager.fetch(listOf(CORE_PACK_NAME))
            .addOnSuccessListener {
                val path = getCorePackPath()
                if (path != null && !isResultReturned) {
                    listener.let { assetPackManager.unregisterListener(it) }
                    isResultReturned = true
                    result.success(path)
                }
            }
            .addOnFailureListener { exception ->
                listener.let { assetPackManager.unregisterListener(it) }
                if (!isResultReturned) {
                    isResultReturned = true
                    result.error(
                        "ASSET_PACK_FETCH_ERROR",
                        exception.message ?: "Failed to initiate asset pack fetch",
                        null
                    )
                }
            }
    }
}
