"use strict";

const FREE_MONTHLY_AUDIO_SECONDS = 5 * 60 * 60;
const PCM_BYTES_PER_SECOND = 16000 * 2;
// Per-learner dispatch cap while the shared F0 pool is the only provider; the
// universal policy's 50/day remains the published ceiling. Worst case per
// learner per month = 8 * 10 s * 31 days = 2,480 s, under 14% of
// FREE_MONTHLY_AUDIO_SECONDS.
const FREE_TIER_DAILY_ASSESSMENTS = 8;

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

module.exports = {
  FREE_MONTHLY_AUDIO_SECONDS, FREE_TIER_DAILY_ASSESSMENTS, PCM_BYTES_PER_SECOND,
  freeTierAssessmentEnabled, nextFreeTierUsage,
};
