package com.sujinarin.ko_lernen_app

/**
 * Base-module boundary for the optional API 26+ proofreading split.
 *
 * Keep all ML Kit types out of this interface: API 24/25 devices install and
 * run the base application without loading the feature's classes.
 */
interface KoreanProofreadingGateway {
    fun check(callback: (Map<String, Any?>) -> Unit)

    fun download(callback: (Map<String, Any?>) -> Unit)

    fun proofread(text: String, callback: (Map<String, Any?>) -> Unit)

    fun close()
}
