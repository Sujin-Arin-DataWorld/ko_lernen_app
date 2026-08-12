"use strict";

const crypto = require("node:crypto");

const minimumScenarioScore = 0.7;

// Keep this narrow, explicit allow-list in lockstep with the app's promise
// picker. A group cannot turn an arbitrary free-browse scenario into a shared
// contribution by changing a client payload. Each missionContentLinkId is the
// curriculum graph's stable `link` ID for that unit's declared assess edge.
const weeklyPromiseDefinitions = Object.freeze({
  cafe_order: Object.freeze({
    courseUnitId: "a1_04_order_request_object",
    scenarioId: "bunshik_tteokbokki",
    missionContentLinkId: "link:e6a9f1197b48c79f58655c9a",
    target: 3,
  }),
  directions: Object.freeze({
    courseUnitId: "a1_06_transport_directions",
    scenarioId: "taxi_kakao",
    missionContentLinkId: "link:49a189a1b8b9e4fa022a4557",
    target: 3,
  }),
  self_introduction: Object.freeze({
    courseUnitId: "a1_02_self_intro_identity",
    scenarioId: "introduce_yourself",
    missionContentLinkId: "link:94c139e887716700674589b2",
    target: 3,
  }),
});

function weeklyPromiseFor(id) {
  if (typeof id !== "string") return null;
  return weeklyPromiseDefinitions[id] || null;
}

function isFiniteScore(value) {
  return typeof value === "number" && Number.isFinite(value);
}

function parseCourseMasterySnapshot(raw) {
  if (typeof raw !== "string" || raw.length === 0 || raw.length > 200000) {
    return null;
  }
  try {
    const parsed = JSON.parse(raw);
    return parsed && typeof parsed === "object" && !Array.isArray(parsed)
      ? parsed
      : null;
  } catch (_) {
    return null;
  }
}

/// Returns the latest exact course checkpoint that may light this promise.
/// The source must carry the app's existing active-mission proof; browsing a
/// scenario, an unrelated course unit, a score below 70%, or malformed data
/// never becomes a community event. Only a checkpoint created or materially
/// changed by this write may contribute, and it must belong to the event's
/// Korea-week so unrelated snapshot writes cannot replay retained history.
function findEligiblePromiseCheckpoint({
  promiseId,
  previousCourseMasteryJson,
  courseMasteryJson,
  weekKey,
}) {
  const promise = weeklyPromiseFor(promiseId);
  const snapshot = parseCourseMasterySnapshot(courseMasteryJson);
  if (!promise ||
      !snapshot ||
      !Array.isArray(snapshot.scenarioCheckpoints) ||
      typeof weekKey !== "string" ||
      !/^\d{4}-\d{2}-\d{2}$/.test(weekKey)) {
    return null;
  }

  let previousCheckpoints = [];
  if (previousCourseMasteryJson !== undefined &&
      previousCourseMasteryJson !== null) {
    const previousSnapshot = parseCourseMasterySnapshot(
      previousCourseMasteryJson,
    );
    if (!previousSnapshot ||
        !Array.isArray(previousSnapshot.scenarioCheckpoints)) {
      return null;
    }
    previousCheckpoints = previousSnapshot.scenarioCheckpoints;
  }
  const previousCheckpointFingerprints = new Set(
    previousCheckpoints
      .filter((checkpoint) => checkpoint && typeof checkpoint === "object")
      .map((checkpoint) => JSON.stringify([
        checkpoint.id,
        checkpoint.scenarioId,
        checkpoint.courseUnitId,
        checkpoint.missionContentLinkId,
        checkpoint.score,
        checkpoint.occurredAt,
        checkpoint.courseEligible,
      ])),
  );

  let candidate = null;
  for (const checkpoint of snapshot.scenarioCheckpoints) {
    if (!checkpoint || typeof checkpoint !== "object" ||
        checkpoint.courseEligible !== true ||
        checkpoint.missionContentLinkId !== promise.missionContentLinkId ||
        checkpoint.courseUnitId !== promise.courseUnitId ||
        checkpoint.scenarioId !== promise.scenarioId ||
        !isFiniteScore(checkpoint.score) ||
        checkpoint.score < minimumScenarioScore ||
        typeof checkpoint.id !== "string" || checkpoint.id.length === 0 ||
        typeof checkpoint.occurredAt !== "string" ||
        Number.isNaN(Date.parse(checkpoint.occurredAt))) {
      continue;
    }
    if (weeklyContributionWeekKey(checkpoint.occurredAt) !== weekKey) {
      continue;
    }
    const checkpointFingerprint = JSON.stringify([
      checkpoint.id,
      checkpoint.scenarioId,
      checkpoint.courseUnitId,
      checkpoint.missionContentLinkId,
      checkpoint.score,
      checkpoint.occurredAt,
      checkpoint.courseEligible,
    ]);
    if (previousCheckpointFingerprints.has(checkpointFingerprint)) {
      continue;
    }
    if (!candidate || checkpoint.occurredAt > candidate.occurredAt) {
      candidate = checkpoint;
    }
  }
  return candidate;
}

/// Monday 00:00 in Korea is the contribution boundary, matching the existing
/// weekly scheduler. The key is stable under retries and carries no identity.
function weeklyContributionWeekKey(value) {
  const instant = new Date(value);
  if (Number.isNaN(instant.getTime())) {
    throw new TypeError("A valid contribution timestamp is required.");
  }
  const korea = new Date(instant.getTime() + 9 * 60 * 60 * 1000);
  const daysSinceMonday = (korea.getUTCDay() + 6) % 7;
  korea.setUTCDate(korea.getUTCDate() - daysSinceMonday);
  return korea.toISOString().slice(0, 10);
}

/// A receipt is private server state. Hashing avoids exposing a contributor's
/// uid through a readable collection document id.
function weeklyContributionReceiptId({ gyeId, uid, promiseId, weekKey }) {
  return crypto
    .createHash("sha256")
    .update(`${gyeId}\0${uid}\0${promiseId}\0${weekKey}`, "utf8")
    .digest("hex");
}

function shouldCreditPromiseContribution({
  meta,
  checkpoint,
  receiptExists = false,
  weekKey,
}) {
  if (receiptExists || !meta || !checkpoint) return false;
  const promise = weeklyPromiseFor(meta.weeklyPromiseId);
  if (!promise ||
      meta.weeklyPromiseSchemaVersion !== 1 ||
      meta.weeklyPromiseTarget !== promise.target) return false;
  if (typeof weekKey !== "string" || weekKey.length !== 10) return false;
  // A delayed trigger must not silently merge a new week's evidence into a
  // stale aggregate before the scheduled rollover has closed the old week.
  if (meta.weeklyPromiseWeekKey && meta.weeklyPromiseWeekKey !== weekKey) {
    return false;
  }
  if (typeof checkpoint.occurredAt !== "string" ||
      Number.isNaN(Date.parse(checkpoint.occurredAt)) ||
      weeklyContributionWeekKey(checkpoint.occurredAt) !== weekKey) {
    return false;
  }
  return checkpoint.courseEligible === true &&
    checkpoint.missionContentLinkId === promise.missionContentLinkId &&
    checkpoint.courseUnitId === promise.courseUnitId &&
    checkpoint.scenarioId === promise.scenarioId &&
    isFiniteScore(checkpoint.score) &&
    checkpoint.score >= minimumScenarioScore;
}

module.exports = {
  findEligiblePromiseCheckpoint,
  minimumScenarioScore,
  shouldCreditPromiseContribution,
  weeklyContributionReceiptId,
  weeklyContributionWeekKey,
  weeklyPromiseDefinitions,
  weeklyPromiseFor,
};
