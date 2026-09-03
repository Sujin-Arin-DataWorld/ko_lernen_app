"use strict";

const {
  DAY_MILLIS, entitlementDocumentId, resolveAccess, subjectHash, validUid,
} = require("./access_policy");

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

/** Access is resolved exclusively from server-controlled documents. Keeping
 * these reads inside the caller's transaction also fences account deletion.
 */
async function readAccessAuthority({firestore, transaction, uid, environment}) {
  const deletionRef = firestore.collection("account_deletions").doc(uid);
  const grantRef = firestore.collection("premium_grants").doc(uid);
  const entitlementRef = firestore.collection("customer_entitlements")
    .doc(entitlementDocumentId(uid, environment));
  const [deletion, grant, entitlement] = await Promise.all([
    transaction.get(deletionRef), transaction.get(grantRef), transaction.get(entitlementRef),
  ]);
  if (deletion.exists) throw new AccessFailure("failed-precondition");
  return {
    grant: grant.exists ? grant.data() : null,
    entitlement: entitlement.exists ? entitlement.data() : null,
  };
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
    try {
      const at = now();
      const environment = getEnvironment();
      const phase = getPhase();
      const ownerSubjectHash = subjectHash(uid);
      const rateRef = firestore.collection("access_rate_limits").doc(ownerSubjectHash);
      return await firestore.runTransaction(async (transaction) => {
        const authority = await readAccessAuthority({firestore, transaction, uid, environment});
        const rate = await transaction.get(rateRef);
        const minute = Math.floor(at / 60_000);
        const previous = rate.exists ? rate.data() : {};
        const count = previous.minute === minute &&
          Number.isSafeInteger(previous.count) && previous.count >= 0 ? previous.count : 0;
        if (count >= 30) throw new AccessFailure("resource-exhausted");
        const snapshot = resolveAccess({uid, environment, phase, now: at, ...authority});
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
