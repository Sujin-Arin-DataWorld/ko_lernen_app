"use strict";

const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {HttpsError, onCall} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {
  PronunciationRequestError,
  pronunciationProviderBreaker,
  validatePronunciationRequest,
  pcm16ToWav,
  parseAzureAssessment,
  nextQuotaState,
  previousQuotaState,
} = require("./pronunciation_request_guard");

initializeApp();

const AZURE_SPEECH_KEY = defineSecret("AZURE_SPEECH_KEY");
const AZURE_SPEECH_REGION = "germanywestcentral";

async function consumeQuota(db, uid, now = new Date()) {
  const ref = db.collection("users").doc(uid)
    .collection("pronunciation_rate_limits").doc("current");
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    const previous = snapshot.exists ? snapshot.data() : {};
    const next = nextQuotaState(previous, now);
    if (next === null) return false;
    transaction.set(ref, {
      ...next,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return true;
  });
}

async function releaseQuota(db, uid, now = new Date()) {
  const ref = db.collection("users").doc(uid)
    .collection("pronunciation_rate_limits").doc("current");
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists) {
      return false;
    }
    const next = previousQuotaState(snapshot.data(), now);
    if (next === null) {
      return false;
    }
    transaction.set(ref, {
      ...next,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return true;
  });
}

async function callAzure({audio, referenceText, signal}) {
  const url = new URL(
    `https://${AZURE_SPEECH_REGION}.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1`,
  );
  url.searchParams.set("language", "ko-KR");
  url.searchParams.set("format", "detailed");
  const assessment = Buffer.from(JSON.stringify({
    ReferenceText: referenceText,
    GradingSystem: "HundredMark",
    Granularity: "FullText",
    Dimension: "Comprehensive",
    EnableMiscue: "True",
  }), "utf8").toString("base64");
  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Ocp-Apim-Subscription-Key": AZURE_SPEECH_KEY.value(),
      "Pronunciation-Assessment": assessment,
      "Content-Type": "audio/wav; codecs=audio/pcm; samplerate=16000",
      Accept: "application/json",
    },
    body: pcm16ToWav(audio),
    signal,
  });
  if (!response.ok) {
    throw new PronunciationRequestError("unavailable", "Pronunciation assessment unavailable.");
  }
  return response.json();
}

exports.assessPronunciation = onCall({
  region: "europe-west3",
  enforceAppCheck: true,
  consumeAppCheckToken: true,
  timeoutSeconds: 30,
  memory: "256MiB",
  maxInstances: 20,
  secrets: [AZURE_SPEECH_KEY],
}, async (request) => {
  try {
    const input = validatePronunciationRequest(request);
    if (!pronunciationProviderBreaker.allow()) {
      throw new HttpsError("unavailable", "Pronunciation assessment unavailable.");
    }
    if (!(await consumeQuota(getFirestore(), input.uid))) {
      throw new HttpsError("resource-exhausted", "Pronunciation limit reached.");
    }
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15000);
    try {
      const providerResult = await callAzure({...input, signal: controller.signal});
      const parsed = parseAzureAssessment(providerResult, input.assessmentId);
      pronunciationProviderBreaker.recordSuccess();
      return parsed;
    } catch (error) {
      pronunciationProviderBreaker.recordFailure();
      try {
        await releaseQuota(getFirestore(), input.uid);
      } catch {
        // Keep the original provider failure; never leak refund internals.
      }
      throw error;
    } finally {
      clearTimeout(timeout);
    }
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    if (error instanceof PronunciationRequestError) {
      throw new HttpsError(error.code, error.message);
    }
    // Do not log audio, reference text, provider payloads, or account details.
    throw new HttpsError("unavailable", "Pronunciation assessment unavailable.");
  }
});

module.exports.consumeQuota = consumeQuota;
module.exports.releaseQuota = releaseQuota;
