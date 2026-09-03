"use strict";

const crypto = require("node:crypto");

const MAX_PCM_BYTES = 320000;
const MAX_REFERENCE_CODEPOINTS = 200;
const ASSESSMENT_ID_PATTERN = /^[A-Za-z0-9_-]{8,128}$/;
const MINUTE_LIMIT = 5;
const DAY_LIMIT = 50;
const IDEMPOTENCY_TTL_MS = 15 * 60 * 1000;
const IDEMPOTENCY_COLLECTION = "service_idempotency";

class PronunciationRequestError extends Error {
  constructor(code, message) {
    super(message);
    this.name = "PronunciationRequestError";
    this.code = code;
  }
}

function invalidRequest() {
  return new PronunciationRequestError("invalid-argument", "Invalid pronunciation request.");
}

function decodeBase64(value) {
  if (typeof value !== "string" || value.length === 0 || value.length > 426668) {
    throw invalidRequest();
  }
  if (!/^[A-Za-z0-9+/]*={0,2}$/.test(value) || value.length % 4 !== 0) {
    throw invalidRequest();
  }
  const audio = Buffer.from(value, "base64");
  if (audio.length === 0 || audio.length > MAX_PCM_BYTES || audio.length % 2 !== 0) {
    throw invalidRequest();
  }
  if (audio.toString("base64") !== value) throw invalidRequest();
  return audio;
}

function validatePronunciationRequest(request) {
  if (!request || !request.auth || typeof request.auth.uid !== "string") {
    throw new PronunciationRequestError("unauthenticated", "Authentication required.");
  }
  if (!request.app || typeof request.app.appId !== "string" || !request.app.appId || request.app.alreadyConsumed === true) {
    throw new PronunciationRequestError("failed-precondition", "App verification required.");
  }
  const data = request.data;
  if (!data || typeof data !== "object" || Array.isArray(data)) throw invalidRequest();
  const referenceText = typeof data.referenceText === "string" ? data.referenceText.trim() : "";
  if (
    referenceText.length === 0 ||
    Array.from(referenceText).length > MAX_REFERENCE_CODEPOINTS ||
    typeof data.assessmentId !== "string" ||
    !ASSESSMENT_ID_PATTERN.test(data.assessmentId)
  ) {
    throw invalidRequest();
  }
  return {
    uid: request.auth.uid,
    audio: decodeBase64(data.audioBase64),
    referenceText,
    assessmentId: data.assessmentId,
  };
}

function pcm16ToWav(pcm) {
  if (!Buffer.isBuffer(pcm) || pcm.length === 0 || pcm.length > MAX_PCM_BYTES || pcm.length % 2 !== 0) {
    throw invalidRequest();
  }
  const header = Buffer.alloc(44);
  header.write("RIFF", 0, "ascii");
  header.writeUInt32LE(36 + pcm.length, 4);
  header.write("WAVE", 8, "ascii");
  header.write("fmt ", 12, "ascii");
  header.writeUInt32LE(16, 16);
  header.writeUInt16LE(1, 20);
  header.writeUInt16LE(1, 22);
  header.writeUInt32LE(16000, 24);
  header.writeUInt32LE(32000, 28);
  header.writeUInt16LE(2, 32);
  header.writeUInt16LE(16, 34);
  header.write("data", 36, "ascii");
  header.writeUInt32LE(pcm.length, 40);
  return Buffer.concat([header, pcm]);
}

function score(value) {
  return typeof value === "number" && Number.isFinite(value) && value >= 0 && value <= 100
    ? value
    : null;
}

function parseAzureAssessment(raw, assessmentId) {
  const assessment = raw && raw.RecognitionStatus === "Success" &&
    Array.isArray(raw.NBest) && raw.NBest[0]
    ? raw.NBest[0].PronunciationAssessment
    : null;
  if (!assessment || typeof assessment !== "object") {
    throw new PronunciationRequestError("unavailable", "Pronunciation assessment unavailable.");
  }
  const pronunciationScore = score(assessment.PronScore);
  const accuracyScore = score(assessment.AccuracyScore);
  const fluencyScore = score(assessment.FluencyScore);
  const completenessScore = score(assessment.CompletenessScore);
  if (
    pronunciationScore === null || accuracyScore === null ||
    fluencyScore === null || completenessScore === null
  ) {
    throw new PronunciationRequestError("unavailable", "Pronunciation assessment unavailable.");
  }
  return {assessmentId, pronunciationScore, accuracyScore, fluencyScore, completenessScore};
}

function nextQuotaState(previous, now, {minuteLimit = MINUTE_LIMIT, dayLimit = DAY_LIMIT} = {}) {
  const minuteBucket = now.toISOString().slice(0, 16);
  const dayBucket = now.toISOString().slice(0, 10);
  const minuteCount = previous && previous.minuteBucket === minuteBucket
    ? Number(previous.minuteCount) || 0
    : 0;
  const dayCount = previous && previous.dayBucket === dayBucket
    ? Number(previous.dayCount) || 0
    : 0;
  if (minuteCount >= minuteLimit || dayCount >= dayLimit) return null;
  return {
    minuteBucket,
    minuteCount: minuteCount + 1,
    dayBucket,
    dayCount: dayCount + 1,
  };
}

function previousQuotaState(previous, now) {
  if (!previous || typeof previous !== "object") {
    return null;
  }
  const minuteBucket = now.toISOString().slice(0, 16);
  const dayBucket = now.toISOString().slice(0, 10);
  return {
    minuteBucket: previous.minuteBucket,
    minuteCount: previous.minuteBucket === minuteBucket
      ? Math.max(0, (Number(previous.minuteCount) || 0) - 1)
      : Number(previous.minuteCount) || 0,
    dayBucket: previous.dayBucket,
    dayCount: previous.dayBucket === dayBucket
      ? Math.max(0, (Number(previous.dayCount) || 0) - 1)
      : Number(previous.dayCount) || 0,
  };
}

class CircuitBreaker {
  constructor({
    failureThreshold = 5,
    cooldownMs = 30_000,
    now = () => Date.now(),
  } = {}) {
    this.failureThreshold = failureThreshold;
    this.cooldownMs = cooldownMs;
    this.now = now;
    this.failures = 0;
    this.openedAt = null;
  }

  allow() {
    if (this.openedAt == null) {
      return true;
    }
    return this.now() - this.openedAt >= this.cooldownMs;
  }

  recordSuccess() {
    this.failures = 0;
    this.openedAt = null;
  }

  recordFailure() {
    const now = this.now();
    if (this.openedAt != null && now - this.openedAt >= this.cooldownMs) {
      this.failures = this.failureThreshold;
      this.openedAt = now;
      return;
    }
    this.failures += 1;
    if (this.failures >= this.failureThreshold) {
      this.openedAt = now;
    }
  }
}

const pronunciationProviderBreaker = new CircuitBreaker();

function pronunciationReplayId(uid, assessmentId) {
  return crypto
    .createHash("sha256")
    .update(`pronunciation_v1\0${uid}\0${assessmentId}`)
    .digest("hex");
}

function idempotencyExpiresAt(now = new Date()) {
  return new Date(now.getTime() + IDEMPOTENCY_TTL_MS);
}

function expiryMillis(value) {
  if (!value) {
    return 0;
  }
  if (typeof value.toMillis === "function") {
    return value.toMillis();
  }
  if (value instanceof Date) {
    return value.getTime();
  }
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  return 0;
}

function pronunciationReplayDocument(scores, now = new Date()) {
  return {
    kind: "pronunciation_v1",
    state: "completed",
    assessmentId: scores.assessmentId,
    pronunciationScore: scores.pronunciationScore,
    accuracyScore: scores.accuracyScore,
    fluencyScore: scores.fluencyScore,
    completenessScore: scores.completenessScore,
    expiresAt: idempotencyExpiresAt(now),
  };
}

function pendingPronunciationDocument(assessmentId, now = new Date()) {
  return {
    kind: "pronunciation_v1",
    state: "pending",
    assessmentId,
    expiresAt: idempotencyExpiresAt(now),
  };
}

function isPendingPronunciationReplay(data, assessmentId, now = new Date()) {
  return Boolean(
    data &&
    data.kind === "pronunciation_v1" &&
    data.state === "pending" &&
    data.assessmentId === assessmentId &&
    expiryMillis(data.expiresAt) > now.getTime(),
  );
}

function pronunciationReplayFromDocument(data, assessmentId, now = new Date()) {
  if (!data || data.kind !== "pronunciation_v1" || data.assessmentId !== assessmentId) {
    return null;
  }
  if (data.state === "pending") {
    return null;
  }
  if (expiryMillis(data.expiresAt) <= now.getTime()) {
    return null;
  }
  const pronunciationScore = score(data.pronunciationScore);
  const accuracyScore = score(data.accuracyScore);
  const fluencyScore = score(data.fluencyScore);
  const completenessScore = score(data.completenessScore);
  if (
    pronunciationScore === null ||
    accuracyScore === null ||
    fluencyScore === null ||
    completenessScore === null
  ) {
    return null;
  }
  return {
    assessmentId,
    pronunciationScore,
    accuracyScore,
    fluencyScore,
    completenessScore,
  };
}

module.exports = {
  CircuitBreaker,
  IDEMPOTENCY_COLLECTION,
  IDEMPOTENCY_TTL_MS,
  MAX_PCM_BYTES,
  PronunciationRequestError,
  idempotencyExpiresAt,
  pronunciationProviderBreaker,
  isPendingPronunciationReplay,
  pendingPronunciationDocument,
  pronunciationReplayDocument,
  pronunciationReplayFromDocument,
  pronunciationReplayId,
  validatePronunciationRequest,
  pcm16ToWav,
  parseAzureAssessment,
  nextQuotaState,
  previousQuotaState,
};
