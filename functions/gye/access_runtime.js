"use strict";

const {DAY_MILLIS, resolveAccess, subjectHash, validUid} = require("./access_policy");

const ACCESS_CALLABLE_OPTIONS = Object.freeze({
  region: "europe-west3",
  enforceAppCheck: true,
  consumeAppCheckToken: true,
  timeoutSeconds: 15,
  maxInstances: 10,
});

class AccessFailure extends Error {
  constructor(code) {
    super("Account access could not be verified.");
    this.code = code;
  }
}

/** The account-deletion fence remains transactional, but retired premium and
 * subscription documents no longer participate in access decisions.
 */
async function readAccessAuthority({firestore, transaction, uid}) {
  const deletionRef = firestore.collection("account_deletions").doc(uid);
  const deletion = await transaction.get(deletionRef);
  if (deletion.exists) throw new AccessFailure("failed-precondition");
  return {};
}

function createAccessRuntime({firestore, auth, now = Date.now,
  getEnvironment = () => process.env.ACCESS_ENVIRONMENT || "PRODUCTION",
  getPhase = () => process.env.ACCESS_PHASE || "free_launch"}) {
  async function getAccessSnapshot(request) {
    const uid = request?.auth?.uid;
    if (!validUid(uid)) throw new AccessFailure("unauthenticated");
    if (typeof request?.app?.appId !== "string" || !request.app.appId ||
        request.app.alreadyConsumed === true) {
      throw new AccessFailure("failed-precondition");
    }
    const input = request.data ?? {};
    if (typeof input !== "object" || Array.isArray(input) || Object.keys(input).length) {
      throw new AccessFailure("invalid-argument");
    }
    let user;
    try {
      user = await auth.getUser(uid);
    } catch {
      throw new AccessFailure("unauthenticated");
    }
    if (user?.uid !== uid || user.disabled === true) {
      throw new AccessFailure("unauthenticated");
    }
    const accountCreatedAt = Date.parse(user?.metadata?.creationTime);
    try {
      const at = now();
      const environment = getEnvironment();
      const phase = getPhase();
      const ownerSubjectHash = subjectHash(uid);
      const rateRef = firestore.collection("access_rate_limits").doc(ownerSubjectHash);
      return await firestore.runTransaction(async (transaction) => {
        const authority = await readAccessAuthority({firestore, transaction, uid});
        const rate = await transaction.get(rateRef);
        const minute = Math.floor(at / 60_000);
        const previous = rate.exists ? rate.data() : {};
        const count = previous.minute === minute &&
          Number.isSafeInteger(previous.count) && previous.count >= 0 ? previous.count : 0;
        if (count >= 30) throw new AccessFailure("resource-exhausted");
        const snapshot = resolveAccess({uid, environment, phase, now: at, ...authority, accountCreatedAt});
        transaction.set(rateRef, {
          ownerSubjectHash, minute, count: count + 1, expiresAt: new Date(at + DAY_MILLIS),
        });
        return snapshot;
      });
    } catch (error) {
      if (error instanceof AccessFailure) throw error;
      throw new AccessFailure("unavailable");
    }
  }
  return {getAccessSnapshot};
}

module.exports = {ACCESS_CALLABLE_OPTIONS, AccessFailure,
  readAccessAuthority, createAccessRuntime};
