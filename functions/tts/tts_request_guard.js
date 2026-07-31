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

module.exports = { CALLABLE_OPTIONS, TtsRequestError, validateTtsRequest };
