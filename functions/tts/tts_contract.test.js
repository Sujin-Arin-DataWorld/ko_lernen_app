const assert = require("node:assert/strict");
const test = require("node:test");

const {
  TTS_CACHE_REVISION,
  cacheKey,
  normalizeVoice,
} = require("./tts_contract");

test("v3 storage key matches the Flutter cache contract", () => {
  const key = cacheKey("female", "안녕하세요");

  assert.equal(TTS_CACHE_REVISION, "v3");
  assert.equal(key.voice, "female");
  assert.equal(key.hash, "d84734f7d89bbd707dc52168c47309aed72b7f80");
  assert.equal(
    key.storagePath,
    "tts/v3/female/d84734f7d89bbd707dc52168c47309aed72b7f80.mp3",
  );
});

test("unsupported voices use the female cache namespace", () => {
  assert.equal(normalizeVoice("unknown"), "female");
});
