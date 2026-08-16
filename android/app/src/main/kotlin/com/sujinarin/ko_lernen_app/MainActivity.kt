package com.sujinarin.ko_lernen_app

import android.os.Bundle
import android.os.Build
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val PROOFREADING_CHANNEL =
            "com.sujinarin.ko_lernen_app/korean_proofreading"
        private const val PROOFREADING_IMPLEMENTATION =
            "com.sujinarin.ko_lernen_app.proofreading.KoreanProofreadingGatewayImpl"
        private const val MAX_PROOFREADING_CODE_POINTS = 240
    }

    private var proofreadingChannel: MethodChannel? = null
    private var proofreadingGateway: KoreanProofreadingGateway? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // SDK 35 enforces edge-to-edge on Android 15. FlutterActivity is an
        // android.app.Activity rather than ComponentActivity, so use the
        // WindowCompat equivalent that also works with Flutter's embedding.
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        proofreadingChannel =
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                PROOFREADING_CHANNEL,
            ).also { channel ->
                channel.setMethodCallHandler { call, result ->
                    when (call.method) {
                        "check" -> withProofreadingGateway(result) { gateway, reply ->
                            gateway.check(reply)
                        }
                        "download" -> withProofreadingGateway(result) { gateway, reply ->
                            gateway.download(reply)
                        }
                        "proofread" -> {
                            val text = call.argument<String>("text")
                            if (!isValidProofreadingText(text)) {
                                result.success(
                                    mapOf(
                                        "status" to "failed",
                                        "error" to if (
                                            text != null &&
                                                text.codePointCount(0, text.length) >
                                                    MAX_PROOFREADING_CODE_POINTS
                                        ) {
                                            "inputTooLong"
                                        } else {
                                            "invalidInput"
                                        },
                                    ),
                                )
                            } else {
                                val validatedText = requireNotNull(text)
                                withProofreadingGateway(result) { gateway, reply ->
                                    gateway.proofread(validatedText, reply)
                                }
                            }
                        }
                        "close" -> {
                            closeProofreadingGateway()
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                }
            }
    }

    private fun withProofreadingGateway(
        result: MethodChannel.Result,
        action: (KoreanProofreadingGateway, (Map<String, Any?>) -> Unit) -> Unit,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.success(
                mapOf(
                    "status" to "unsupportedAndroidVersion",
                    "error" to "unavailable",
                ),
            )
            return
        }

        val gateway = proofreadingGateway ?: createProofreadingGateway()
        if (gateway == null) {
            result.success(
                mapOf(
                    "status" to "featureModuleMissing",
                    "error" to "featureModuleMissing",
                ),
            )
            return
        }

        var replied = false
        val reply: (Map<String, Any?>) -> Unit = { payload ->
            runOnUiThread {
                if (!replied) {
                    replied = true
                    result.success(payload)
                }
            }
        }
        try {
            action(gateway, reply)
        } catch (_: LinkageError) {
            reply(
                mapOf(
                    "status" to "featureModuleMissing",
                    "error" to "featureModuleMissing",
                ),
            )
        } catch (_: RuntimeException) {
            reply(mapOf("status" to "failed", "error" to "unknown"))
        }
    }

    private fun createProofreadingGateway(): KoreanProofreadingGateway? {
        return try {
            val implementation = Class.forName(PROOFREADING_IMPLEMENTATION)
            val instance =
                implementation
                    .getConstructor(android.content.Context::class.java)
                    .newInstance(applicationContext)
            (instance as? KoreanProofreadingGateway)?.also {
                proofreadingGateway = it
            }
        } catch (_: ReflectiveOperationException) {
            null
        } catch (_: LinkageError) {
            null
        }
    }

    private fun isValidProofreadingText(text: String?): Boolean {
        if (text.isNullOrBlank()) {
            return false
        }
        if (text.codePointCount(0, text.length) > MAX_PROOFREADING_CODE_POINTS) {
            return false
        }
        return text.codePoints().anyMatch { codePoint ->
            codePoint in 0x1100..0x11FF ||
                codePoint in 0x3130..0x318F ||
                codePoint in 0xAC00..0xD7A3
        }
    }

    private fun closeProofreadingGateway() {
        try {
            proofreadingGateway?.close()
        } catch (_: RuntimeException) {
            // Lifecycle cleanup is best-effort; never crash activity teardown.
        } finally {
            proofreadingGateway = null
        }
    }

    override fun onDestroy() {
        proofreadingChannel?.setMethodCallHandler(null)
        proofreadingChannel = null
        closeProofreadingGateway()
        super.onDestroy()
    }
}
