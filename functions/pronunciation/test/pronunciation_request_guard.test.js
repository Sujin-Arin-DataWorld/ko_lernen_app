"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const {
  IDEMPOTENCY_TTL_MS,
  MAX_PCM_BYTES,
  PronunciationRequestError,
  validatePronunciationRequest,
  pcm16ToWav,
  parseAzureAssessment,
  isPendingPronunciationReplay,
  pendingPronunciationDocument,
  pronunciationReplayDocument,
  pronunciationReplayFromDocument,
  pronunciationReplayId,
  nextQuotaState,
  previousQuotaState,
} = require("../pronunciation_request_guard");

function request(overrides = {}) {
  return {
    auth: {uid: "user-1"},
    app: {appId: "app-1"},
    data: {
      audioBase64: Buffer.from([0, 1, 2, 3]).toString("base64"),
      referenceText: "안녕하세요",
      assessmentId: "p-123456-abcdef12",
      ...overrides,
    },
  };
}

test("pins Azure processing to Germany West Central", () => {
  const source = fs.readFileSync(path.join(__dirname, "..", "index.js"), "utf8");
  assert.match(source, /const AZURE_SPEECH_REGION = "germanywestcentral";/);
  assert.doesNotMatch(source, /defineString\([^)]*REGION/i);
  assert.doesNotMatch(source, /process\.env\.[A-Z_]*REGION/);
});

test("validates auth, App Check, size, text, and assessment id", () => {
  const validated = validatePronunciationRequest(request());
  assert.equal(validated.uid, "user-1");
  assert.equal(validated.audio.length, 4);
  assert.equal(validated.referenceText, "안녕하세요");

  assert.throws(
    () => validatePronunciationRequest({...request(), auth: null}),
    (error) => error instanceof PronunciationRequestError && error.code === "unauthenticated",
  );
  assert.throws(
    () => validatePronunciationRequest({...request(), app: null}),
    (error) => error instanceof PronunciationRequestError && error.code === "failed-precondition",
  );
  assert.throws(
    () => validatePronunciationRequest(request({audioBase64: Buffer.alloc(MAX_PCM_BYTES + 1).toString("base64")})),
    (error) => error.code === "invalid-argument",
  );
  assert.throws(
    () => validatePronunciationRequest(request({referenceText: ""})),
    (error) => error.code === "invalid-argument",
  );
  assert.throws(
    () => validatePronunciationRequest(request({assessmentId: "../../unsafe"})),
    (error) => error.code === "invalid-argument",
  );
});

test("wraps raw 16 kHz mono PCM16 in a bounded WAV container", () => {
  const pcm = Buffer.from([0, 1, 2, 3]);
  const wav = pcm16ToWav(pcm);
  assert.equal(wav.toString("ascii", 0, 4), "RIFF");
  assert.equal(wav.toString("ascii", 8, 12), "WAVE");
  assert.equal(wav.readUInt32LE(24), 16000);
  assert.equal(wav.readUInt16LE(22), 1);
  assert.equal(wav.readUInt16LE(34), 16);
  assert.deepEqual(wav.subarray(44), pcm);
});

test("returns only aggregate scores from the Azure short-audio REST response", () => {
  // REST scores are directly on NBest[0], unlike Speech SDK result JSON.
  // https://learn.microsoft.com/azure/ai-services/speech-service/rest-speech-to-text-short#sample-responses
  const parsed = parseAzureAssessment({
    RecognitionStatus: "Success",
    NBest: [{
      PronScore: 82.5,
      AccuracyScore: 84,
      FluencyScore: 79,
      CompletenessScore: 100,
      Display: "안녕하세요",
      Words: [{Word: "안녕하세요"}],
    }],
  }, "p-123456-abcdef12");
  assert.deepEqual(parsed, {
    assessmentId: "p-123456-abcdef12",
    pronunciationScore: 82.5,
    accuracyScore: 84,
    fluencyScore: 79,
    completenessScore: 100,
  });
  assert.throws(
    () => parseAzureAssessment({RecognitionStatus: "Success", NBest: [{}]}, "p-123456-abcdef12"),
    (error) => error.code === "unavailable",
  );
});

test("rejects unsuccessful, incomplete, and invalid REST assessment results", () => {
  const scores = {
    PronScore: 82.5, AccuracyScore: 84, FluencyScore: 79, CompletenessScore: 100,
  };
  for (const raw of [
    {RecognitionStatus: "NoMatch", NBest: [scores]},
    {RecognitionStatus: "Success", NBest: []},
    {RecognitionStatus: "Success", NBest: [{...scores, FluencyScore: undefined}]},
    {RecognitionStatus: "Success", NBest: [{...scores, AccuracyScore: 101}]},
    {RecognitionStatus: "Success", NBest: [{...scores, PronScore: "82.5"}]},
  ]) {
    assert.throws(
      () => parseAzureAssessment(raw, "p-123456-abcdef12"),
      (error) => error instanceof PronunciationRequestError && error.code === "unavailable",
    );
  }
});

test("allows 5 per minute and 50 per day with exact boundary resets", () => {
  const now = new Date("2026-08-13T10:22:30.000Z");
  assert.deepEqual(nextQuotaState({}, now), {
    minuteBucket: "2026-08-13T10:22",
    minuteCount: 1,
    dayBucket: "2026-08-13",
    dayCount: 1,
  });
  assert.equal(nextQuotaState({
    minuteBucket: "2026-08-13T10:22",
    minuteCount: 5,
    dayBucket: "2026-08-13",
    dayCount: 5,
  }, now), null);
  assert.equal(nextQuotaState({
    minuteBucket: "2026-08-13T10:21",
    minuteCount: 5,
    dayBucket: "2026-08-13",
    dayCount: 50,
  }, now), null);
  assert.deepEqual(nextQuotaState({
    minuteBucket: "2026-08-12T23:59",
    minuteCount: 5,
    dayBucket: "2026-08-12",
    dayCount: 50,
  }, now), {
    minuteBucket: "2026-08-13T10:22",
    minuteCount: 1,
    dayBucket: "2026-08-13",
    dayCount: 1,
  });
});

test("replay receipts hash the caller and omit audio and reference text", () => {
  const now = new Date("2026-08-16T10:00:00.000Z");
  const assessmentId = "p-123456-abcdef12";
  const replayId = pronunciationReplayId("user-1", assessmentId);
  assert.equal(replayId.length, 64);
  assert.equal(replayId.includes("user-1"), false);
  assert.notEqual(replayId, pronunciationReplayId("user-2", assessmentId));

  const scores = {
    assessmentId,
    pronunciationScore: 82.5,
    accuracyScore: 84,
    fluencyScore: 79,
    completenessScore: 100,
  };
  const document = pronunciationReplayDocument(scores, now);
  assert.deepEqual(Object.keys(document).sort(), [
    "accuracyScore",
    "assessmentId",
    "completenessScore",
    "expiresAt",
    "fluencyScore",
    "kind",
    "pronunciationScore",
    "state",
  ]);
  const pending = pendingPronunciationDocument(assessmentId, now);
  assert.equal(isPendingPronunciationReplay(pending, assessmentId, now), true);
  assert.equal(pronunciationReplayFromDocument(pending, assessmentId, now), null);
  assert.deepEqual(
    pronunciationReplayFromDocument(document, assessmentId, now),
    scores,
  );
  assert.equal(
    pronunciationReplayFromDocument(
      document,
      assessmentId,
      new Date(now.getTime() + IDEMPOTENCY_TTL_MS + 1),
    ),
    null,
  );
});

test("previousQuotaState refunds the same minute and day buckets", () => {
  const now = new Date("2026-08-13T10:22:30.000Z");
  assert.deepEqual(previousQuotaState({
    minuteBucket: "2026-08-13T10:22",
    minuteCount: 3,
    dayBucket: "2026-08-13",
    dayCount: 9,
  }, now), {
    minuteBucket: "2026-08-13T10:22",
    minuteCount: 2,
    dayBucket: "2026-08-13",
    dayCount: 8,
  });
  assert.deepEqual(previousQuotaState({
    minuteBucket: "2026-08-13T10:21",
    minuteCount: 5,
    dayBucket: "2026-08-13",
    dayCount: 9,
  }, now), {
    minuteBucket: "2026-08-13T10:21",
    minuteCount: 5,
    dayBucket: "2026-08-13",
    dayCount: 8,
  });
});
