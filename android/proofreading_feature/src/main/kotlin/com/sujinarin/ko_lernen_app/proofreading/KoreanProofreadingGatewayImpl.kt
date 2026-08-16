package com.sujinarin.ko_lernen_app.proofreading

import android.content.Context
import com.google.mlkit.genai.common.DownloadCallback
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.common.GenAiException
import com.google.mlkit.genai.proofreading.Proofreader
import com.google.mlkit.genai.proofreading.ProofreaderOptions
import com.google.mlkit.genai.proofreading.Proofreading
import com.google.mlkit.genai.proofreading.ProofreadingRequest
import com.sujinarin.ko_lernen_app.KoreanProofreadingGateway
import java.util.concurrent.ExecutionException
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/** ML Kit implementation loaded reflectively by the API-24 base module. */
class KoreanProofreadingGatewayImpl(context: Context) : KoreanProofreadingGateway {
    private val executor: ExecutorService =
        Executors.newSingleThreadExecutor { runnable ->
            Thread(runnable, "hangul-sori-proofreading").apply { isDaemon = true }
        }
    private val client: Proofreader =
        Proofreading.getClient(
            ProofreaderOptions.builder(context.applicationContext)
                .setInputType(ProofreaderOptions.InputType.KEYBOARD)
                // The learning UI can be DE or EN; the text being corrected is
                // always Korean, so this option must never come from Dart.
                .setLanguage(ProofreaderOptions.Language.KOREAN)
                .build(),
        )
    private val closed = AtomicBoolean(false)
    private val inferenceInFlight = AtomicBoolean(false)

    @Volatile private var downloadedBytes: Long? = null
    @Volatile private var totalBytes: Long? = null

    override fun check(callback: (Map<String, Any?>) -> Unit) {
        if (closed.get()) {
            callback(failure("unavailable"))
            return
        }
        val future = client.checkFeatureStatus()
        future.addListener(
            {
                try {
                    callback(statusPayload(future.get()))
                } catch (throwable: Throwable) {
                    callback(errorPayload(unwrap(throwable)))
                }
            },
            executor,
        )
    }

    override fun download(callback: (Map<String, Any?>) -> Unit) {
        if (closed.get()) {
            callback(failure("unavailable"))
            return
        }
        val statusFuture = client.checkFeatureStatus()
        statusFuture.addListener(
            {
                try {
                    when (statusFuture.get()) {
                        FeatureStatus.AVAILABLE -> callback(statusPayload(FeatureStatus.AVAILABLE))
                        FeatureStatus.DOWNLOADING -> callback(statusPayload(FeatureStatus.DOWNLOADING))
                        FeatureStatus.DOWNLOADABLE -> startDownload(callback)
                        else -> callback(statusPayload(FeatureStatus.UNAVAILABLE))
                    }
                } catch (throwable: Throwable) {
                    callback(errorPayload(unwrap(throwable), downloadFailure = true))
                }
            },
            executor,
        )
    }

    private fun startDownload(callback: (Map<String, Any?>) -> Unit) {
        val completed = AtomicBoolean(false)
        client.downloadFeature(
            object : DownloadCallback {
                override fun onDownloadStarted(bytesToDownload: Long) {
                    downloadedBytes = 0
                    totalBytes = bytesToDownload.coerceAtLeast(0)
                }

                override fun onDownloadProgress(totalBytesDownloaded: Long) {
                    downloadedBytes = totalBytesDownloaded.coerceAtLeast(0)
                }

                override fun onDownloadCompleted() {
                    if (completed.compareAndSet(false, true)) {
                        totalBytes?.let { downloadedBytes = it }
                        callback(statusPayload(FeatureStatus.AVAILABLE))
                    }
                }

                override fun onDownloadFailed(exception: GenAiException) {
                    if (completed.compareAndSet(false, true)) {
                        callback(errorPayload(exception, downloadFailure = true))
                    }
                }
            },
        )
    }

    override fun proofread(text: String, callback: (Map<String, Any?>) -> Unit) {
        if (closed.get()) {
            callback(failure("unavailable"))
            return
        }
        // A Dart-side timeout cannot cancel the ML Kit ListenableFuture. Keep a
        // native guard so a retry cannot overlap the still-running inference
        // and consume a second on-device quota slot.
        if (!inferenceInFlight.compareAndSet(false, true)) {
            callback(mapOf("status" to "busy", "error" to "busy"))
            return
        }
        try {
            val request = ProofreadingRequest.builder(text).build()
            val future = client.runInference(request)
            future.addListener(
                {
                    try {
                        val suggestions =
                            future.get().results
                                .map { suggestion -> suggestion.text }
                                .filter { suggestion -> suggestion.isNotBlank() }
                        callback(
                            mapOf(
                                "status" to "completed",
                                "error" to "none",
                                "sourceText" to text,
                                "suggestions" to suggestions,
                                "isFinal" to true,
                            ),
                        )
                    } catch (throwable: Throwable) {
                        callback(errorPayload(unwrap(throwable)))
                    } finally {
                        inferenceInFlight.set(false)
                    }
                },
                executor,
            )
        } catch (throwable: Throwable) {
            inferenceInFlight.set(false)
            callback(errorPayload(unwrap(throwable)))
        }
    }

    override fun close() {
        if (!closed.compareAndSet(false, true)) {
            return
        }
        client.close()
        executor.shutdownNow()
    }

    private fun statusPayload(status: Int): Map<String, Any?> {
        val state =
            when (status) {
                FeatureStatus.DOWNLOADABLE -> "downloadable"
                FeatureStatus.DOWNLOADING -> "downloading"
                FeatureStatus.AVAILABLE -> "available"
                else -> "unavailable"
            }
        return mapOf(
            "status" to state,
            "error" to if (state == "unavailable") "unavailable" else "none",
            "downloadedBytes" to downloadedBytes,
            "totalBytes" to totalBytes,
        )
    }

    private fun errorPayload(
        throwable: Throwable,
        downloadFailure: Boolean = false,
    ): Map<String, Any?> {
        val exception = throwable as? GenAiException
        val error =
            when (exception?.errorCode) {
                GenAiException.ErrorCode.NOT_AVAILABLE -> "unavailable"
                GenAiException.ErrorCode.BUSY -> "busy"
                GenAiException.ErrorCode.NOT_ENOUGH_DISK_SPACE -> "notEnoughStorage"
                GenAiException.ErrorCode.NEEDS_SYSTEM_UPDATE -> "systemUpdateNeeded"
                GenAiException.ErrorCode.AICORE_INCOMPATIBLE -> "aicoreIncompatible"
                GenAiException.ErrorCode.REQUEST_PROCESSING_ERROR,
                GenAiException.ErrorCode.REQUEST_TOO_LARGE,
                GenAiException.ErrorCode.REQUEST_TOO_SMALL,
                GenAiException.ErrorCode.CANCELLED,
                -> "requestRejected"
                GenAiException.ErrorCode.RESPONSE_PROCESSING_ERROR,
                GenAiException.ErrorCode.RESPONSE_GENERATION_ERROR,
                -> "responseRejected"
                else -> if (downloadFailure) "downloadFailed" else "unknown"
            }
        val status =
            when (error) {
                "unavailable" -> "unavailable"
                "busy" -> "busy"
                else -> "failed"
            }
        return mapOf("status" to status, "error" to error)
    }

    private fun failure(error: String): Map<String, Any?> =
        mapOf("status" to "failed", "error" to error)

    private fun unwrap(throwable: Throwable): Throwable =
        if (throwable is ExecutionException && throwable.cause != null) {
            throwable.cause!!
        } else {
            throwable
        }
}
