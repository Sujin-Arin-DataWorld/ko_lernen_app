"use strict";

const {DAY_MILLIS, resolveAccess, subjectHash, validUid} = require("./access_policy");

const LEGACY_CACHE_MILLIS = 30 * DAY_MILLIS;

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

/** Keep the account-deletion fence in the same transaction as rate limiting. */
async function assertAccountAvailable({firestore, transaction, uid}) {
  const deletionRef = firestore.collection("account_deletions").doc(uid);
  const deletion = await transaction.get(deletionRef);
  if (deletion.exists) throw new AccessFailure("failed-precondition");
  return {};
}

/**
 * Compatibility wire format for already-released clients that only parse
 * schema v1 and recognize the former highest-tier source vocabulary. This is
 * an adapter over universal access, not an entitlement or billing decision.
 */
function legacyCompatibilitySnapshot(snapshot) {
  return Object.freeze({
    schemaVersion: 1,
    ownerUid: snapshot.ownerUid,
    environment: snapshot.environment,
    revision: snapshot.revision,
    source: "closed_tester_lifetime",
    contentAccess: snapshot.contentAccess,
    aiPolicyId: "premium_v1",
    bookDailyLimit: snapshot.bookDailyLimit,
    pronunciationDailyLimit: snapshot.pronunciationDailyLimit,
    serverNow: snapshot.serverNow,
    accessUntil: null,
    offlineUntil: snapshot.serverNow + LEGACY_CACHE_MILLIS,
    nextResetAt: snapshot.nextResetAt,
  });
}

function createAccessRuntime({firestore, auth, now = Date.now,
  getEnvironment = () => process.env.ACCESS_ENVIRONMENT || "PRODUCTION"}) {
  async function getSnapshot(request, adapt) {
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
      const ownerSubjectHash = subjectHash(uid);
      const rateRef = firestore.collection("access_rate_limits").doc(ownerSubjectHash);
      return await firestore.runTransaction(async (transaction) => {
        await assertAccountAvailable({firestore, transaction, uid});
        const rate = await transaction.get(rateRef);
        const minute = Math.floor(at / 60_000);
        const previous = rate.exists ? rate.data() : {};
        const count = previous.minute === minute &&
          Number.isSafeInteger(previous.count) && previous.count >= 0 ? previous.count : 0;
        if (count >= 30) throw new AccessFailure("resource-exhausted");
        const snapshot = adapt(resolveAccess({uid, environment, now: at}));
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
  return {
    getAccessSnapshot: (request) => getSnapshot(request, legacyCompatibilitySnapshot),
    getUniversalAccessSnapshot: (request) => getSnapshot(request, (snapshot) => snapshot),
  };
}

module.exports = {ACCESS_CALLABLE_OPTIONS, AccessFailure,
  assertAccountAvailable, legacyCompatibilitySnapshot, createAccessRuntime};
