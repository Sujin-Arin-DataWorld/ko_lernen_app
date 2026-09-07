"use strict";

const {createHash} = require("node:crypto");

const DAY_MILLIS = 86_400_000;
const ACCESS_ENVIRONMENTS = new Set(["PRODUCTION", "SANDBOX"]);

function validUid(value) {
  return typeof value === "string" && value.length > 0 &&
    Buffer.byteLength(value, "utf8") <= 128 && value !== "." && value !== ".." &&
    !/[\u0000-\u0020\u007f/]/u.test(value);
}

function subjectHash(uid) {
  if (!validUid(uid)) throw new TypeError("Invalid account identity.");
  return createHash("sha256").update(uid, "utf8").digest("hex");
}

function millis(value) {
  const result = value instanceof Date ? value.getTime() :
    (typeof value?.toMillis === "function" ? value.toMillis() : value);
  return Number.isSafeInteger(result) && result >= 0 ? result : null;
}

/** Pure universal-access policy shared by callable access and server-side AI gates.
 * All authenticated learners receive the same content and daily AI limits.
 * All wire timestamps are UTC epoch milliseconds (never device time).
 */
function resolveAccess({uid, environment, now}) {
  if (!validUid(uid) || !ACCESS_ENVIRONMENTS.has(environment) || millis(now) === null) {
    throw new TypeError("Invalid access policy context.");
  }
  now = millis(now);
  const source = "universal";
  const aiPolicyId = "universal_v1";
  const revision = createHash("sha256")
    .update(JSON.stringify([2, uid, environment, source, aiPolicyId]))
    .digest("hex");
  return Object.freeze({
    schemaVersion: 2,
    ownerUid: uid,
    environment,
    revision,
    source,
    contentAccess: "all",
    aiPolicyId,
    bookDailyLimit: 20,
    pronunciationDailyLimit: 50,
    serverNow: now,
    nextResetAt: (Math.floor(now / DAY_MILLIS) + 1) * DAY_MILLIS,
  });
}

module.exports = {
  ACCESS_ENVIRONMENTS, DAY_MILLIS, validUid, subjectHash, resolveAccess,
};
