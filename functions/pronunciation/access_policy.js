"use strict";

const {createHash} = require("node:crypto");

const DAY_MILLIS = 86_400_000;
const PAID_OFFLINE_MILLIS = 3 * DAY_MILLIS;
const TESTER_OFFLINE_MILLIS = 30 * DAY_MILLIS;
const ACCESS_ENVIRONMENTS = new Set(["PRODUCTION", "SANDBOX"]);
const ACCESS_PHASES = new Set(["free_launch", "paid"]);

function validUid(value) {
  return typeof value === "string" && value.length > 0 &&
    Buffer.byteLength(value, "utf8") <= 128 && value !== "." && value !== ".." &&
    !/[\u0000-\u0020\u007f/]/u.test(value);
}

function subjectHash(uid) {
  if (!validUid(uid)) throw new TypeError("Invalid account identity.");
  return createHash("sha256").update(uid, "utf8").digest("hex");
}

function entitlementDocumentId(uid, environment) {
  if (!ACCESS_ENVIRONMENTS.has(environment)) {
    throw new TypeError("Invalid access environment.");
  }
  return `${environment}_${subjectHash(uid)}`;
}

function millis(value) {
  const result = value instanceof Date ? value.getTime() :
    (typeof value?.toMillis === "function" ? value.toMillis() : value);
  return Number.isSafeInteger(result) && result >= 0 ? result : null;
}

function boundedText(value, max) {
  return typeof value === "string" && value.trim().length > 0 &&
    Buffer.byteLength(value, "utf8") <= max && !/[\u0000-\u001f\u007f]/u.test(value);
}

function matchesAuthority(value, uid, environment, accountCreatedAt) {
  return value?.schemaVersion === 1 && value.ownerUid === uid &&
    millis(accountCreatedAt) !== null && millis(value.accountCreatedAt) === accountCreatedAt &&
    value.environment === environment && Number.isSafeInteger(value.revision) &&
    value.revision > 0;
}

function activeTesterGrant(grant, uid, environment, now, accountCreatedAt) {
  const approvedAt = millis(grant?.approvedAt);
  return matchesAuthority(grant, uid, environment, accountCreatedAt) &&
    grant.kind === "closed_tester_lifetime" && grant.status === "active" &&
    boundedText(grant.grantId, 128) && grant.approvedBy === "Jin" &&
    boundedText(grant.approvalRef, 512) && approvedAt !== null && approvedAt <= now;
}

function activeSubscription(entitlement, uid, environment, now, accountCreatedAt) {
  const checkedAt = millis(entitlement?.providerCheckedAt);
  const accessUntil = millis(entitlement?.accessUntil);
  return matchesAuthority(entitlement, uid, environment, accountCreatedAt) &&
    entitlement.status === "active" && checkedAt !== null && checkedAt <= now &&
    checkedAt + PAID_OFFLINE_MILLIS > now && accessUntil !== null && accessUntil > now;
}

/** Pure policy shared by callable access and server-side AI gates.
 * Only server-read grant/entitlement documents belong here. Build flags and
 * feedback passports are intentionally not inputs to authority resolution.
 * All wire timestamps are UTC epoch milliseconds (never device time).
 */
function resolveAccess({uid, environment, phase, now, grant, entitlement, accountCreatedAt}) {
  if (!validUid(uid) || !ACCESS_ENVIRONMENTS.has(environment) ||
      !ACCESS_PHASES.has(phase) || millis(now) === null) {
    throw new TypeError("Invalid access policy context.");
  }
  now = millis(now);
  // Only server Auth metadata supplies this context. Legacy documents without
  // a generation are not silently rebound to whichever account now owns a UID.
  accountCreatedAt = millis(accountCreatedAt);
  if (accountCreatedAt !== null && accountCreatedAt > now) accountCreatedAt = null;
  const tester = activeTesterGrant(grant, uid, environment, now, accountCreatedAt);
  const subscriber = activeSubscription(entitlement, uid, environment, now, accountCreatedAt);
  const premium = tester || subscriber;
  const source = tester ? "closed_tester_lifetime" : subscriber ? "subscription" :
    phase === "free_launch" ? "free_launch" : "free";
  const accessUntil = subscriber && !tester ? millis(entitlement.accessUntil) : null;
  const offlineUntil = tester ? now + TESTER_OFFLINE_MILLIS : subscriber ?
    Math.min(accessUntil, millis(entitlement.providerCheckedAt) + PAID_OFFLINE_MILLIS) : now;
  const authorityRevision = tester ? grant.revision : subscriber ? entitlement.revision : 0;
  const revision = createHash("sha256")
    .update(JSON.stringify([1, uid, environment, phase, source, authorityRevision, accessUntil, accountCreatedAt]))
    .digest("hex");
  return Object.freeze({
    schemaVersion: 1,
    ownerUid: uid,
    environment,
    revision,
    source,
    // Subscription sales are disabled. Every authenticated learner receives
    // the former highest access tier; authority data is retained only for
    // migration and account-cleanup compatibility.
    contentAccess: "all",
    aiPolicyId: "premium_v1",
    bookDailyLimit: 20,
    pronunciationDailyLimit: 50,
    serverNow: now,
    accessUntil,
    offlineUntil,
    nextResetAt: (Math.floor(now / DAY_MILLIS) + 1) * DAY_MILLIS,
  });
}

module.exports = {
  ACCESS_ENVIRONMENTS, ACCESS_PHASES, DAY_MILLIS, PAID_OFFLINE_MILLIS,
  TESTER_OFFLINE_MILLIS, validUid, subjectHash, entitlementDocumentId,
  activeTesterGrant, activeSubscription, resolveAccess,
};
