"use strict";

const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {HttpsError, onCall} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {
  IDEMPOTENCY_COLLECTION,
  PronunciationRequestError,
  isPendingPronunciationReplay,
  pendingPronunciationDocument,
  pronunciationProviderBreaker,
  pronunciationReplayDocument,
  pronunciationReplayFromDocument,
  pronunciationReplayId,
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

async function claimPronunciationReplay(db, uid, assessmentId) {
  const ref = db
    .collection(IDEMPOTENCY_COLLECTION)
    .doc(pronunciationReplayId(uid, assessmentId));
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    const data = snapshot.exists ? snapshot.data() : null;
    const replay = pronunciationReplayFromDocument(data, assessmentId);
    if (replay) {
      return {replay, consume: false};
    }
    if (isPendingPronunciationReplay(data, assessmentId)) {
      return {replay: null, consume: false};
    }
    transaction.set(ref, pendingPronunciationDocument(assessmentId));
    return {replay: null, consume: true};
  });
}

async function savePronunciationReplay(db, uid, scores) {
  await db
    .collection(IDEMPOTENCY_COLLECTION)
    .doc(pronunciationReplayId(uid, scores.assessmentId))
    .set(pronunciationReplayDocument(scores));
}

async function abandonPronunciationReplay(db, uid, assessmentId) {
  const ref = db
    .collection(IDEMPOTENCY_COLLECTION)
    .doc(pronunciationReplayId(uid, assessmentId));
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists) {
      return;
    }
    if (isPendingPronunciationReplay(snapshot.data(), assessmentId)) {
      transaction.delete(ref);
    }
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
    const claim = await claimPronunciationReplay(
      getFirestore(),
      input.uid,
      input.assessmentId,
    );
    if (claim.replay) {
      return claim.replay;
    }
    if (!pronunciationProviderBreaker.allow()) {
      if (claim.consume) {
        await abandonPronunciationReplay(
          getFirestore(),
          input.uid,
          input.assessmentId,
        );
      }
      throw new HttpsError("unavailable", "Pronunciation assessment unavailable.");
    }
    let consumed = false;
    if (claim.consume) {
      if (!(await consumeQuota(getFirestore(), input.uid))) {
        await abandonPronunciationReplay(
          getFirestore(),
          input.uid,
          input.assessmentId,
        );
        throw new HttpsError("resource-exhausted", "Pronunciation limit reached.");
      }
      consumed = true;
    }
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15000);
    try {
      const providerResult = await callAzure({...input, signal: controller.signal});
      const parsed = parseAzureAssessment(providerResult, input.assessmentId);
      pronunciationProviderBreaker.recordSuccess();
      try {
        await savePronunciationReplay(getFirestore(), input.uid, parsed);
      } catch {
        // Keep the scored result even if the short-lived receipt cannot be stored.
      }
      return parsed;
    } catch (error) {
      pronunciationProviderBreaker.recordFailure();
      if (consumed) {
        try {
          await releaseQuota(getFirestore(), input.uid);
        } catch {
          // Keep the original provider failure; never leak refund internals.
        }
      }
      try {
        await abandonPronunciationReplay(
          getFirestore(),
          input.uid,
          input.assessmentId,
        );
      } catch {
        // A leftover pending receipt expires; do not hide the provider error.
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
