const crypto = require("node:crypto");
const { normalizeVoice } = require("./tts_contract");

const CALLABLE_OPTIONS = Object.freeze({
  cors: true,
  memory: "256MiB",
  timeoutSeconds: 30,
  enforceAppCheck: true,
  consumeAppCheckToken: true,
});

class TtsRequestError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

function validateTtsRequest(request) {
  if (!request || !request.auth || !request.auth.uid) {
    throw new TtsRequestError("unauthenticated", "Sign in is required.");
  }
  if (request.app && request.app.alreadyConsumed) {
    throw new TtsRequestError(
      "failed-precondition",
      "This App Check token was already used.",
    );
  }

  const data = request.data && typeof request.data === "object" ? request.data : {};
  const text = typeof data.text === "string" ? data.text.trim() : "";
  if (!text) {
    throw new TtsRequestError("invalid-argument", "Text is required.");
  }
  if (text.length > 500) {
    throw new TtsRequestError("invalid-argument", "Text is too long.");
  }

  const rawInstallationId = data.installationId;
  let installationId;
  if (rawInstallationId === undefined || rawInstallationId === null) {
    // 이미 설치된 구버전 앱도 끊지 않는다. 구버전은 설치 ID가 없으므로
    // 계정별 legacy subject에 묶여 더 엄격한 30회 한도를 적용받는다.
    installationId = `legacy:${request.auth.uid}`;
  } else if (
    typeof rawInstallationId !== "string" ||
    !UUID_V4_PATTERN.test(rawInstallationId)
  ) {
    throw new TtsRequestError(
      "invalid-argument",
      "A valid installation ID is required.",
    );
  } else {
    installationId = rawInstallationId.toLowerCase();
  }

  return { text, voice: normalizeVoice(data.voice), installationId };
}

const UUID_V4_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

const DAILY_LIMIT_INSTALLATION = 30;
const DAILY_LIMIT_ACCOUNT = 50;
const DAILY_LIMIT_GLOBAL = 300;

const DEFAULT_DAILY_LIMITS = Object.freeze({
  installation: DAILY_LIMIT_INSTALLATION,
  account: DAILY_LIMIT_ACCOUNT,
  global: DAILY_LIMIT_GLOBAL,
});

function subjectHash(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
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

const ttsProviderBreaker = new CircuitBreaker();
const SYNTH_DEADLINE_MS = 8_000;
const MIN_AUDIO_BYTES = 32;

function isUsableAudioBuffer(value) {
  if (!Buffer.isBuffer(value) || value.length < MIN_AUDIO_BYTES) {
    return false;
  }
  if (value.subarray(0, 3).toString("ascii") === "ID3") {
    return true;
  }
  return value[0] === 0xff && (value[1] & 0xe0) === 0xe0;
}

function withDeadline(promise, timeoutMs, message = "TTS synthesis timed out.") {
  let timer;
  const timeout = new Promise((_, reject) => {
    timer = setTimeout(() => {
      reject(new Error(message));
    }, timeoutMs);
  });
  return Promise.race([promise, timeout]).finally(() => {
    clearTimeout(timer);
  });
}

function quotaExpiresAt(day) {
  const [year, month, date] = day.split("-").map(Number);
  return new Date(Date.UTC(year, month - 1, date + 2));
}

/**
 * 새 Cloud TTS 합성 한 건을 설치·계정·프로젝트 전체 세 범위에 원자적으로
 * 기록한다. 어느 하나라도 한도에 닿았으면 세 카운터 모두 증가시키지 않는다.
 * 원본 설치 ID와 uid는 문서 ID나 필드에 저장하지 않고 SHA-256만 사용한다.
 */
async function underDailyTtsQuotas(
  db,
  { uid, installationId, now = new Date(), limits = DEFAULT_DAILY_LIMITS },
) {
  const day = now.toISOString().slice(0, 10);
  const specs = [
    {
      scope: "installation",
      limit: limits.installation,
      ref: db
        .collection("usage")
        .doc(`tts_installation_${day}_${subjectHash(installationId)}`),
    },
    {
      scope: "account",
      limit: limits.account,
      ref: db.collection("usage").doc(`tts_account_${day}_${subjectHash(uid)}`),
    },
    {
      scope: "global",
      limit: limits.global,
      ref: db.collection("usage").doc(`tts_global_${day}`),
    },
  ];

  return db.runTransaction(async (tx) => {
    const snapshots = await Promise.all(specs.map(({ ref }) => tx.get(ref)));
    const counts = snapshots.map((snapshot) => {
      const raw = (snapshot.data() || {}).n;
      if (raw === undefined) {
        return 0;
      }
      return Number.isSafeInteger(raw) && raw >= 0 ? raw : null;
    });

    for (let index = 0; index < specs.length; index += 1) {
      const current = counts[index];
      const spec = specs[index];
      if (current === null || current >= spec.limit) {
        return { allowed: false, exceededScope: spec.scope };
      }
    }

    for (let index = 0; index < specs.length; index += 1) {
      const spec = specs[index];
      tx.set(
        spec.ref,
        {
          n: counts[index] + 1,
          kind: "tts",
          scope: spec.scope,
          day,
          limit: spec.limit,
          expiresAt: quotaExpiresAt(day),
        },
        { merge: true },
      );
    }
    return { allowed: true, exceededScope: null };
  });
}

async function refundDailyTtsQuotas(
  db,
  { uid, installationId, now = new Date(), limits = DEFAULT_DAILY_LIMITS },
) {
  const day = now.toISOString().slice(0, 10);
  const specs = [
    {
      scope: "installation",
      limit: limits.installation,
      ref: db
        .collection("usage")
        .doc(`tts_installation_${day}_${subjectHash(installationId)}`),
    },
    {
      scope: "account",
      limit: limits.account,
      ref: db.collection("usage").doc(`tts_account_${day}_${subjectHash(uid)}`),
    },
    {
      scope: "global",
      limit: limits.global,
      ref: db.collection("usage").doc(`tts_global_${day}`),
    },
  ];

  return db.runTransaction(async (tx) => {
    const snapshots = await Promise.all(specs.map(({ ref }) => tx.get(ref)));
    for (let index = 0; index < specs.length; index += 1) {
      const spec = specs[index];
      const raw = (snapshots[index].data() || {}).n;
      const current = Number.isSafeInteger(raw) && raw > 0 ? raw : 0;
      if (current === 0) {
        continue;
      }
      tx.set(
        spec.ref,
        {
          n: current - 1,
          kind: "tts",
          scope: spec.scope,
          day,
          limit: spec.limit,
          expiresAt: quotaExpiresAt(day),
        },
        { merge: true },
      );
    }
    return { refunded: true };
  });
}

module.exports = {
  CALLABLE_OPTIONS,
  CircuitBreaker,
  DEFAULT_DAILY_LIMITS,
  DAILY_LIMIT_ACCOUNT,
  DAILY_LIMIT_GLOBAL,
  DAILY_LIMIT_INSTALLATION,
  MIN_AUDIO_BYTES,
  SYNTH_DEADLINE_MS,
  TtsRequestError,
  isUsableAudioBuffer,
  quotaExpiresAt,
  refundDailyTtsQuotas,
  ttsProviderBreaker,
  validateTtsRequest,
  underDailyTtsQuotas,
  withDeadline,
};
