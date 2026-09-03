"use strict";

const {createHash, randomUUID} = require("node:crypto");
const {PronunciationRequestError, nextQuotaState, pronunciationReplayId,
  pronunciationReplayFromDocument, pronunciationReplayDocument} = require("./pronunciation_request_guard");
const {resolvePronunciationPolicy, readCostControl, prepareCostReservation} = require("./ai_policy");

const LEASE_MS = 60_000;
const RESULT_MS = 15 * 60_000;
const RECOVERY_MS = 24 * 60 * 60_000;
const hash = (text) => createHash("sha256").update(text).digest("hex");
const millis = (value) => value?.toMillis ? value.toMillis() : new Date(value || 0).getTime();

// The resolver runs in the same transaction, allowing server-owned access policy.
class PronunciationReceipts {
  constructor(db, {now = () => new Date(), resolvePolicy} = {}) {
    this.db = db; this.now = now;
    this.resolvePolicy = resolvePolicy || ((uid, tx, at) => resolvePronunciationPolicy(db, uid, tx, at));
  }
  refs(input) {
    return {
      receipt: this.db.collection("service_idempotency").doc(pronunciationReplayId(input.uid, input.assessmentId)),
      result: this.db.collection("service_idempotency_results").doc(pronunciationReplayId(input.uid, input.assessmentId)),
      quota: this.db.collection("users").doc(input.uid).collection("pronunciation_rate_limits").doc("current"),
      marker: this.db.collection("account_deletions").doc(input.uid),
    };
  }
  async fence(tx, marker) {
    if ((await tx.get(marker)).exists) throw new PronunciationRequestError("permission-denied", "Account unavailable.");
  }
  async claim(input) {
    const refs = this.refs(input);
    const fingerprint = hash(JSON.stringify([input.referenceText, input.audio.toString("base64")]));
    const ownerToken = randomUUID();
    return this.db.runTransaction(async (tx) => {
      const now = this.now();
      await this.fence(tx, refs.marker);
      const policy = await this.resolvePolicy(input.uid, tx, now);
      const snapshot = await tx.get(refs.receipt);
      const data = snapshot.exists ? snapshot.data() : null;
      if (data && millis(data.dedupeExpiresAt || data.expiresAt) > now.getTime()) {
        if (data.fingerprint && data.fingerprint !== fingerprint) {
          throw new PronunciationRequestError("invalid-argument", "Request ID was already used for different content.");
        }
        if (data.state === "completed" && millis(data.responseExpiresAt) > now.getTime()) {
          const saved = await tx.get(refs.result);
          const result = saved.exists ? saved.data() : null;
          const replay = result?.ownerToken === data.ownerToken &&
            millis(result.expiresAt) > now.getTime() ? pronunciationReplayFromDocument(
              {...result.result, kind: "pronunciation_v1", state: "completed", expiresAt: result.expiresAt}, input.assessmentId, now) : null;
          if (replay) return {state: "completed", replay};
        }
        if (data.state === "claimed" && millis(data.leaseExpiresAt) <= now.getTime()) {
          tx.set(refs.receipt, {...data, ownerToken, leaseExpiresAt: new Date(now.getTime() + LEASE_MS)});
          return {state: "claimed", ownerToken};
        }
        return {state: ["claimed", "pending"].includes(data.state) && millis(data.leaseExpiresAt) > now.getTime() ? "pending" : "uncertain"};
      }
      // Never re-dispatch legacy pending receipts merely because their old TTL expired.
      if (data && !data.dedupeExpiresAt) {
        tx.set(refs.receipt, {kind: "pronunciation_v1", state: "uncertain", fingerprint,
          ownerSubjectHash: hash(input.uid), assessmentId: input.assessmentId,
          dedupeExpiresAt: new Date(now.getTime() + RECOVERY_MS), expiresAt: new Date(now.getTime() + RECOVERY_MS)});
        return {state: "uncertain"};
      }
      const quota = await tx.get(refs.quota);
      const next = nextQuotaState(quota.exists ? quota.data() : {}, now, policy);
      if (!next) throw new PronunciationRequestError("resource-exhausted", "Pronunciation limit reached.");
      const config = await readCostControl(this.db, tx, now);
      const cost = await prepareCostReservation(this.db, tx, now, config);
      const expiresAt = new Date(now.getTime() + RECOVERY_MS);
      tx.set(cost.ref, cost.payload);
      tx.set(refs.quota, {...next, updatedAt: now});
      tx.set(refs.receipt, {kind: "pronunciation_v1", state: "claimed", ownerToken,
        ownerSubjectHash: hash(input.uid), fingerprint, assessmentId: input.assessmentId,
        reservation: {minuteBucket: next.minuteBucket, dayBucket: next.dayBucket}, costReservation: cost.reservation,
        leaseExpiresAt: new Date(now.getTime() + LEASE_MS), dedupeExpiresAt: expiresAt, expiresAt});
      return {state: "claimed", ownerToken};
    });
  }
  async transition(input, ownerToken, target, scores) {
    const refs = this.refs(input);
    return this.db.runTransaction(async (tx) => {
      const now = this.now();
      await this.fence(tx, refs.marker);
      const snapshot = await tx.get(refs.receipt);
      const data = snapshot.exists ? snapshot.data() : null;
      const source = target === "pending" || target === "refunded" ? "claimed" : "pending";
      if (!data || data.ownerToken !== ownerToken || data.state !== source || millis(data.leaseExpiresAt) <= now.getTime()) return false;
      let cost;
      if (target === "pending") {
        const config = await readCostControl(this.db, tx, now);
        if (config.dailyUnitLimit === 0) throw new PronunciationRequestError("resource-exhausted", "AI service paused.");
        cost = await prepareCostReservation(this.db, tx, now, config, data.costReservation);
      }
      if (target === "refunded") {
        const snapshot = await tx.get(refs.quota);
        const quota = snapshot.exists ? snapshot.data() : {};
        tx.set(refs.quota, {...quota,
          minuteCount: quota.minuteBucket === data.reservation.minuteBucket ? Math.max(0, quota.minuteCount - 1) : quota.minuteCount,
          dayCount: quota.dayBucket === data.reservation.dayBucket ? Math.max(0, quota.dayCount - 1) : quota.dayCount,
        });
        tx.delete(refs.receipt);
      } else {
        if (cost?.ref) tx.set(cost.ref, cost.payload);
        if (target === "completed") {
          const safe = pronunciationReplayDocument(scores, now);
          const result = pronunciationReplayFromDocument(safe, input.assessmentId, now);
          if (!result) throw new PronunciationRequestError("unavailable", "Invalid assessment result.");
          tx.set(refs.result, {kind: data.kind, ownerToken, ownerSubjectHash: data.ownerSubjectHash,
            result, expiresAt: new Date(now.getTime() + RESULT_MS)});
        }
        tx.set(refs.receipt, {...data, state: target,
          ...(cost ? {costReservation: cost.reservation} : {}),
          ...(target === "pending" ? {leaseExpiresAt: new Date(now.getTime() + LEASE_MS),
            dedupeExpiresAt: new Date(now.getTime() + RECOVERY_MS), expiresAt: new Date(now.getTime() + RECOVERY_MS)} : {}),
          ...(target === "completed" ? {responseExpiresAt: new Date(now.getTime() + RESULT_MS)} : {}),
        });
      }
      return true;
    });
  }
}

module.exports = {PronunciationReceipts};
