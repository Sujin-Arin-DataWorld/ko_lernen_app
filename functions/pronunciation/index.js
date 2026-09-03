"use strict";

const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getAuth} = require("firebase-admin/auth");
const {HttpsError, onCall} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {PronunciationReceipts} = require("./billable_receipts");
const {ServiceCostError} = require("./service_cost_policy");
const {PronunciationRequestError, pronunciationProviderBreaker,
  validatePronunciationRequest, pcm16ToWav, parseAzureAssessment,
} = require("./pronunciation_request_guard");

initializeApp();
const AZURE_SPEECH_KEY = defineSecret("AZURE_SPEECH_KEY");
const AZURE_SPEECH_REGION = "germanywestcentral";

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


function unavailable(state = "uncertain") {
  return new HttpsError("unavailable", "Pronunciation assessment unavailable.", {state, retryAfterSeconds: 30});
}

exports.assessPronunciation = onCall({
  region: "europe-west3", enforceAppCheck: true, consumeAppCheckToken: true,
  timeoutSeconds: 30, memory: "256MiB", maxInstances: 20, secrets: [AZURE_SPEECH_KEY],
}, async (request) => {
  try {
    const validated = validatePronunciationRequest(request);
    // One server Auth read per request, outside retryable Firestore transactions.
    let user;
    try { user = await getAuth().getUser(validated.uid); }
    catch { throw new HttpsError("unauthenticated", "Account unavailable."); }
    if (user?.uid !== validated.uid || user.disabled === true) {
      throw new HttpsError("unauthenticated", "Account unavailable.");
    }
    const input = {...validated, accountCreatedAt: Date.parse(user?.metadata?.creationTime)};
    const receipts = new PronunciationReceipts(getFirestore());
    const claim = await receipts.claim(input);
    if (claim.state === "completed") return claim.replay;
    if (claim.state === "pending") throw new HttpsError("aborted", "Assessment in progress.", {state: "pending", retryAfterSeconds: 2});
    if (claim.state !== "claimed") throw unavailable();
    if (!pronunciationProviderBreaker.allow()) {
      await receipts.transition(input, claim.ownerToken, "refunded");
      throw unavailable("not-started");
    }
    // Commit the dispatch marker before Azure; a crash after this point is
    // uncertain, never proof that the provider did not process this request.
    if (!await receipts.transition(input, claim.ownerToken, "pending")) throw unavailable();
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15000);
    try {
      const raw = await callAzure({...input, signal: controller.signal});
      const parsed = parseAzureAssessment(raw, input.assessmentId);
      pronunciationProviderBreaker.recordSuccess();
      if (!await receipts.transition(input, claim.ownerToken, "completed", parsed)) throw unavailable();
      return parsed;
    } catch (error) {
      pronunciationProviderBreaker.recordFailure();
      try { await receipts.transition(input, claim.ownerToken, "uncertain"); } catch { /* durable pending still blocks retry */ }
      if (error instanceof PronunciationRequestError && error.code === "permission-denied") throw error;
      throw unavailable();
    } finally {
      clearTimeout(timeout);
    }
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    if (error instanceof PronunciationRequestError || error instanceof ServiceCostError) throw new HttpsError(error.code, error.message);
    // Never log audio, reference text, tokens, or provider payloads.
    throw unavailable("storage-unavailable");
  }
});
