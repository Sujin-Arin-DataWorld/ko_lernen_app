"use strict";

const crypto = require("node:crypto");

const ANONYMIZED_UID = "[deleted]";
const ANONYMIZED_NICKNAME = "Deleted member";

function normalizedMillis(value) {
  if (Number.isFinite(value)) return value;
  if (value && typeof value.toMillis === "function") return value.toMillis();
  return Number.MAX_SAFE_INTEGER;
}

function selectSuccessor(members, bannedUids) {
  const candidates = members
    .filter((member) =>
      member &&
      member.uid &&
      member.status === "active" &&
      !bannedUids.has(member.uid))
    .slice()
    .sort((left, right) => {
      const timeDifference =
        normalizedMillis(left.joinedAtMillis ?? left.joinedAt) -
        normalizedMillis(right.joinedAtMillis ?? right.joinedAt);
      return timeDifference || left.uid.localeCompare(right.uid);
    });
  return candidates[0] || null;
}

function buildGroupCleanupPlan({
  departingUid,
  ownerId,
  members,
  bannedUids,
}) {
  const departingMember = members.find((member) => member.uid === departingUid);
  const remaining = members.filter((member) => member.uid !== departingUid);
  const ownerCleanup = ownerId === departingUid;

  // At-least-once delivery can observe a partially completed first attempt:
  // the owner member is gone while ownerId still points to the deleted user.
  if (!departingMember && !ownerCleanup) {
    return {
      action: "noop",
      departingUid,
      successorUid: null,
      memberCount: remaining.length,
    };
  }

  if (!ownerCleanup) {
    return {
      action: "removeMember",
      departingUid,
      successorUid: null,
      memberCount: remaining.length,
    };
  }

  const successor = selectSuccessor(remaining, bannedUids);
  if (!successor) {
    return {
      action: "deleteGroup",
      departingUid,
      successorUid: null,
      memberCount: 0,
    };
  }
  return {
    action: "transferOwner",
    departingUid,
    successorUid: successor.uid,
    memberCount: remaining.length,
  };
}

function buildOwnerSuspensionPlan({
  targetUid,
  ownerId,
  members,
  bannedUids,
}) {
  if (ownerId !== targetUid) {
    return { action: "suspendMember", successorUid: null };
  }
  const successor = selectSuccessor(
    members.filter((member) => member.uid !== targetUid),
    bannedUids,
  );
  return successor
    ? { action: "transferOwner", successorUid: successor.uid }
    : { action: "deleteGroup", successorUid: null };
}

function selectPushRecipientUids(members, bannedUids, deletingUids) {
  return members
    .filter((member) =>
      member &&
      member.uid &&
      member.status === "active" &&
      !bannedUids.has(member.uid) &&
      !deletingUids.has(member.uid))
    .map((member) => member.uid);
}

function groupDeletionUserUids(members, additionalUid = null) {
  return Array.from(new Set([
    ...members.map((member) => member && member.uid).filter(Boolean),
    ...(additionalUid ? [additionalUid] : []),
  ])).sort();
}

function shouldCreditPackClear({
  beforeStatus,
  afterStatus,
  receiptExists = false,
}) {
  return afterStatus === "cleared" &&
    beforeStatus !== "cleared" &&
    !receiptExists;
}

function pendingReporterUids(reports, targetUid) {
  return Array.from(new Set(
    reports
      .filter((report) =>
        report &&
        report.status === "pending" &&
        report.reporterUid &&
        report.reporterUid !== targetUid &&
        report.reporterUid !== ANONYMIZED_UID)
      .map((report) => report.reporterUid),
  )).sort();
}

function isDurableReporterAuth(userRecord) {
  return Boolean(
    userRecord &&
    userRecord.disabled !== true &&
    Array.isArray(userRecord.providerData) &&
    userRecord.providerData.length > 0,
  );
}

function eligibleModerationReporterUids(reporterUids, members, excludedUids) {
  const activeUids = new Set(
    members
      .filter((member) => member && member.status === "active")
      .map((member) => member.uid),
  );
  return reporterUids.filter(
    (uid) => activeUids.has(uid) && !excludedUids.has(uid),
  );
}

function legacyIdentityMatches(storedUid, storedNickname, uid, nickname) {
  return storedUid === uid ||
    ((!storedUid || storedUid === ANONYMIZED_UID) &&
      Boolean(nickname) &&
      storedNickname === nickname);
}

function anonymizeFeed(source, uid, legacyNickname = "") {
  let changed = false;
  const result = { ...source };
  if (legacyIdentityMatches(
    source.actorUid,
    source.actorNickname,
    uid,
    legacyNickname,
  )) {
    result.actorUid = ANONYMIZED_UID;
    result.actorNickname = ANONYMIZED_NICKNAME;
    changed = true;
  }

  const originalPayload = source.payload || {};
  const payload = { ...originalPayload };
  if (legacyIdentityMatches(
    originalPayload.targetUid,
    originalPayload.targetNickname,
    uid,
    legacyNickname,
  )) {
    payload.targetUid = ANONYMIZED_UID;
    payload.targetNickname = ANONYMIZED_NICKNAME;
    changed = true;
  }
  if (legacyIdentityMatches(
    originalPayload.mvpUid,
    originalPayload.mvp,
    uid,
    legacyNickname,
  )) {
    payload.mvpUid = ANONYMIZED_UID;
    payload.mvp = ANONYMIZED_NICKNAME;
    changed = true;
  }
  if (changed) result.payload = payload;
  return changed ? result : source;
}

function anonymizeReport(source, uid) {
  const reporterMatches = source.reporterUid === uid;
  const targetMatches = source.targetUid === uid;
  if (!reporterMatches && !targetMatches) return source;
  return {
    ...source,
    ...(reporterMatches ? { reporterUid: ANONYMIZED_UID } : {}),
    ...(targetMatches ? { targetUid: ANONYMIZED_UID } : {}),
    note: "",
  };
}

function shouldDeleteReportForUid(source, uid) {
  return Boolean(
    source &&
    (source.reporterUid === uid || source.targetUid === uid),
  );
}

function anonymizeSticker(source, uid, legacyNickname = "") {
  if (!legacyIdentityMatches(
    source.senderUid,
    source.senderNickname,
    uid,
    legacyNickname,
  )) {
    return source;
  }
  return {
    ...source,
    senderUid: ANONYMIZED_UID,
    senderNickname: ANONYMIZED_NICKNAME,
  };
}

function anonymizeMeta(source, uid, legacyNickname = "") {
  if (!legacyIdentityMatches(
    source.lastWeekMvpUid,
    source.lastWeekMvp,
    uid,
    legacyNickname,
  )) {
    return source;
  }
  return {
    ...source,
    lastWeekMvpUid: ANONYMIZED_UID,
    lastWeekMvp: ANONYMIZED_NICKNAME,
  };
}

function chunkItems(items, size = 450) {
  if (!Number.isInteger(size) || size <= 0 || size >= 500) {
    throw new RangeError("Chunk size must be an integer from 1 through 499.");
  }
  const chunks = [];
  for (let index = 0; index < items.length; index += size) {
    chunks.push(items.slice(index, index + size));
  }
  return chunks;
}

function memberDeleteTriggerPlan(marker, deletedMembershipId) {
  const matchesPending =
    marker &&
    marker.state === "pending" &&
    marker.membershipId === deletedMembershipId;
  return matchesPending
    ? {
        anonymizeIdentity: true,
        completeDepartureMarker: true,
        reconcileMembership: false,
      }
    : {
        anonymizeIdentity: false,
        completeDepartureMarker: false,
        reconcileMembership: false,
      };
}

function isAccountDeletionTombstoneOldEnough(
  createdAtMillis,
  nowMillis,
  minimumAgeMillis = 24 * 60 * 60 * 1000,
) {
  return Number.isFinite(createdAtMillis) &&
    Number.isFinite(nowMillis) &&
    createdAtMillis <= nowMillis - minimumAgeMillis;
}

function accountTombstoneCleanupAction({
  authUserExists,
  firestoreUserExists,
  authMissingSinceMillis,
  nowMillis,
  minimumAgeMillis = 24 * 60 * 60 * 1000,
}) {
  if (authUserExists) {
    if (firestoreUserExists) return "cancel";
    return Number.isFinite(authMissingSinceMillis) ? "clearMissing" : "retain";
  }
  if (!Number.isFinite(authMissingSinceMillis)) return "markMissing";
  return isAccountDeletionTombstoneOldEnough(
    authMissingSinceMillis,
    nowMillis,
    minimumAgeMillis,
  )
    ? "delete"
    : "retain";
}

function processedPackKey(uid, packId) {
  return crypto
    .createHash("sha256")
    .update(`${uid}\0${packId}`, "utf8")
    .digest("hex");
}

function weeklyRolloverKey(scheduleTime) {
  const parsed = new Date(scheduleTime);
  if (Number.isNaN(parsed.getTime())) {
    throw new TypeError("A valid scheduler timestamp is required.");
  }
  const koreaTime = new Date(parsed.getTime() + 9 * 60 * 60 * 1000);
  return koreaTime.toISOString().slice(0, 10);
}

function shouldProcessWeeklyRollover(lastRolloverKey, rolloverKey) {
  return typeof lastRolloverKey !== "string" ||
    lastRolloverKey < rolloverKey;
}

module.exports = {
  ANONYMIZED_NICKNAME,
  ANONYMIZED_UID,
  accountTombstoneCleanupAction,
  anonymizeFeed,
  anonymizeMeta,
  anonymizeReport,
  anonymizeSticker,
  buildGroupCleanupPlan,
  buildOwnerSuspensionPlan,
  chunkItems,
  eligibleModerationReporterUids,
  groupDeletionUserUids,
  isDurableReporterAuth,
  isAccountDeletionTombstoneOldEnough,
  memberDeleteTriggerPlan,
  processedPackKey,
  pendingReporterUids,
  selectSuccessor,
  selectPushRecipientUids,
  shouldCreditPackClear,
  shouldDeleteReportForUid,
  shouldProcessWeeklyRollover,
  weeklyRolloverKey,
};
