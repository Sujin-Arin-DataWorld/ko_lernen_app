const crypto = require("crypto");

const TTS_CACHE_REVISION = "v2";

function normalizeVoice(voice) {
  return voice === "male" ? "male" : "female";
}

function cacheKey(voice, text) {
  const normalizedVoice = normalizeVoice(voice);
  const normalizedText = String(text || "").trim();
  const hash = crypto
    .createHash("sha1")
    .update(`${normalizedVoice}|${normalizedText}`)
    .digest("hex");

  return {
    voice: normalizedVoice,
    hash,
    storagePath: `tts/${TTS_CACHE_REVISION}/${normalizedVoice}/${hash}.mp3`,
  };
}

module.exports = { TTS_CACHE_REVISION, cacheKey, normalizeVoice };
