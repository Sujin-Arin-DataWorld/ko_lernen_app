"use strict";

const FREE_MONTHLY_AUDIO_SECONDS = 5 * 60 * 60;
const PCM_BYTES_PER_SECOND = 16000 * 2;

function freeTierAssessmentEnabled(environment) {
  // This is enabled only after the release preflight verifies a dedicated F0
  // resource. Missing, paid, or misspelled modes must never contact a provider.
  return environment.PRONUNCIATION_ASSESSMENT_MODE === "azure_f0";
}

function nextFreeTierUsage(previous, audioBytes) {
  const used = previous == null ? 0 : previous.audioSeconds;
  if (!Number.isSafeInteger(used) || used < 0 ||
      !Number.isSafeInteger(audioBytes) || audioBytes <= 0) {
    return null;
  }
  const seconds = Math.ceil(audioBytes / PCM_BYTES_PER_SECOND);
  if (used + seconds > FREE_MONTHLY_AUDIO_SECONDS) {
    return null;
  }
  return {audioSeconds: used + seconds};
}

module.exports = {FREE_MONTHLY_AUDIO_SECONDS, freeTierAssessmentEnabled, nextFreeTierUsage};
