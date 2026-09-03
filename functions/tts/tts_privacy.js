"use strict";
const { cacheKey } = require("./tts_contract");
const manifest = require("./canonical_manifest.json");
const PRIVATE_TTL_MS = 24 * 60 * 60 * 1000;
const canonical = new Set(Object.entries(manifest.voices).flatMap(
  ([voice, hashes]) => hashes.map((hash) => `${voice}/${hash}`),
));

function scopedCacheKey(uid, voice, text) {
  const key = cacheKey(voice, text);
  const isCanonical = canonical.has(`${key.voice}/${key.hash}`);
  return { ...key, isCanonical,
    storagePath: isCanonical ? key.storagePath
      : `tts_private/${uid}/v3/${key.voice}/${key.hash}.mp3`,
  };
}

function privateMetadataIsCurrent(metadata, now = Date.now()) {
  const expires = Number(metadata?.metadata?.expiresAtMillis);
  return Number.isSafeInteger(expires) && expires > now &&
    expires <= now + PRIVATE_TTL_MS;
}

function cacheSaveOptions(key, now = Date.now()) {
  return { contentType: "audio/mpeg", resumable: false,
    metadata: key.isCanonical
      ? { cacheControl: "public, max-age=31536000", metadata: { canonical: "true" } }
      : { cacheControl: "private, no-store", metadata: {
        expiresAtMillis: String(now + PRIVATE_TTL_MS),
      } },
  };
}

module.exports = { PRIVATE_TTL_MS, scopedCacheKey, privateMetadataIsCurrent, cacheSaveOptions };
