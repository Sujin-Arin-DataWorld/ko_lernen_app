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

  return { text, voice: normalizeVoice(data.voice) };
}

/** uid 당 하루 합성 호출 상한. 인증·App Check 를 통과한 정상 클라이언트가
 * 폭주하거나 토큰이 유출됐을 때의 과금 상한선이다. 캐시 히트도 세는 이유는
 * 비용이 아니라 남용 자체를 막기 위해서다. */
const DAILY_LIMIT_TTS = 200;

/**
 * `usage/{kind}_{yyyy-mm-dd}_{uid}` 를 트랜잭션으로 1 증가시키고 한도 내인지
 * 반환한다. 초과면 증가시키지 않는다.
 *
 * session/2026-08-12-hardening 3cb1244 에서 이식. 그 브랜치는 raw HTTP +
 * Bearer 구조였지만 origin/main 은 onCall + App Check 로 진화했으므로 인증
 * 부분은 버리고 **쿼터만** 가져왔다(인증은 validateTtsRequest 담당).
 * db 를 주입받아 admin 초기화 순서에 의존하지 않는다.
 */
async function underDailyQuota(db, uid, kind, limit = DAILY_LIMIT_TTS) {
  const day = new Date().toISOString().slice(0, 10);
  const ref = db.collection("usage").doc(`${kind}_${day}_${uid}`);
  return db.runTransaction(async (tx) => {
    const snapshot = await tx.get(ref);
    const n = ((snapshot.data() || {}).n || 0) + 1;
    if (n > limit) {
      return false;
    }
    tx.set(ref, { n, uid, kind, day }, { merge: true });
    return true;
  });
}

module.exports = {
  CALLABLE_OPTIONS,
  TtsRequestError,
  validateTtsRequest,
  underDailyQuota,
  DAILY_LIMIT_TTS,
};
