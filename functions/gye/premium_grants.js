"use strict";
const {createHash} = require("node:crypto");
const {validUid, subjectHash, ACCESS_ENVIRONMENTS} = require("./access_policy");

function rejected() {
  // Deliberately omit UID, profile data and approval evidence from errors/logs.
  return new Error("Grant request rejected. Check the approved roster and account state.");
}

function validateApprovedRoster(value) {
  const fields = ["schemaVersion", "approvedBy", "approvalRef", "environment", "action", "uids"];
  if (!value || typeof value !== "object" || Array.isArray(value) ||
      Object.keys(value).some((key) => !fields.includes(key)) ||
      value.schemaVersion !== 1 || value.approvedBy !== "Jin" ||
      typeof value.approvalRef !== "string" || !value.approvalRef.trim() ||
      Buffer.byteLength(value.approvalRef, "utf8") > 512 ||
      /[\u0000-\u001f\u007f]/u.test(value.approvalRef) ||
      !ACCESS_ENVIRONMENTS.has(value.environment) ||
      !["grant", "revoke"].includes(value.action) ||
      !Array.isArray(value.uids) || value.uids.length < 1 || value.uids.length > 100 ||
      !value.uids.every(validUid) || new Set(value.uids).size !== value.uids.length) {
    throw rejected();
  }
  return {...value, uids: [...value.uids]};
}

function createGrantManager({firestore, auth, now = Date.now}) {
  async function applyRoster(input, {apply = false} = {}) {
    if (typeof apply !== "boolean") throw rejected();
    const roster = validateApprovedRoster(input);
    const at = now();
    if (!Number.isSafeInteger(at) || at < 0) throw rejected();
    // Validate every identity before entering the atomic roster transaction.
    const accounts = await Promise.all(roster.uids.map(async (uid) => {
      let user;
      try { user = await auth.getUser(uid); } catch { throw rejected(); }
      const createdAt = Date.parse(user?.metadata?.creationTime);
      if (user?.uid !== uid || user.disabled === true ||
          !user.providerData?.some((p) => ["google.com", "apple.com"].includes(p.providerId)) ||
          !Number.isSafeInteger(createdAt) || createdAt < 0 || createdAt > at) throw rejected();
      return {uid, createdAt};
    }));
    return firestore.runTransaction(async (transaction) => {
      const plans = [];
      for (const {uid, createdAt} of accounts) {
        const ref = firestore.collection("premium_grants").doc(uid);
        const [deletion, existing] = await Promise.all([
          transaction.get(firestore.collection("account_deletions").doc(uid)),
          transaction.get(ref),
        ]);
        if (deletion.exists) throw rejected();
        const previous = existing.exists ? existing.data() : null;
        if (previous && (previous.environment !== roster.environment ||
            previous.ownerUid !== uid || previous.schemaVersion !== 1 ||
            !Number.isSafeInteger(previous.revision) || previous.revision < 1)) throw rejected();
        const status = roster.action === "grant" ? "active" : "revoked";
        if (previous?.approvalRef === roster.approvalRef) {
          if (previous.status !== status || previous.accountCreatedAt !== createdAt) throw rejected();
          plans.push({kind: "unchanged"});
          continue;
        }
        if (!previous && roster.action === "revoke") throw rejected();
        const revision = (previous?.revision || 0) + 1;
        if (!Number.isSafeInteger(revision)) throw rejected();
        const grantId = createHash("sha256").update(JSON.stringify([
          roster.environment, uid, roster.approvalRef,
        ])).digest("hex");
        plans.push({ref, kind: previous ? "update" : "create", value: {
          schemaVersion: 1, ownerUid: uid, ownerSubjectHash: subjectHash(uid),
          environment: roster.environment, revision,
          kind: "closed_tester_lifetime", status, grantId,
          approvedAt: at, approvedBy: roster.approvedBy, approvalRef: roster.approvalRef,
          accountCreatedAt: createdAt,
        }});
      }
      const counts = {create: 0, update: 0, unchanged: 0};
      for (const plan of plans) {
        counts[plan.kind]++;
        if (apply && plan.value) transaction.set(plan.ref, plan.value);
      }
      return {dryRun: !apply, environment: roster.environment, action: roster.action, counts};
    });
  }
  return {applyRoster};
}
module.exports = {validateApprovedRoster, createGrantManager};
