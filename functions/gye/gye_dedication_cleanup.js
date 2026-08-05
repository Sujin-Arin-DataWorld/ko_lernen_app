"use strict";

function validUid(value) {
  return typeof value === "string" && value.length > 0 &&
    value.length <= 128 && !value.includes("/");
}

function validMembershipId(value) {
  return typeof value === "string" && value.length >= 16 &&
    value.length <= 64 && value === value.trim() && !value.includes("/");
}

function validJoinEpoch(value) {
  return value && typeof value === "object" &&
    Number.isSafeInteger(value.seconds) && value.seconds >= 0 &&
    Number.isSafeInteger(value.nanoseconds) && value.nanoseconds >= 0 &&
    value.nanoseconds < 1000000000;
}

function joinEpochFrom(joinedAt) {
  if (!validJoinEpoch(joinedAt)) return null;
  return {
    seconds: joinedAt.seconds,
    nanoseconds: joinedAt.nanoseconds,
  };
}

function belongsToMembership(snapshot, uid, membershipId, joinEpoch) {
  if (!snapshot?.exists) return false;
  const data = snapshot.data() || {};
  return data.uid === uid && data.membershipId === membershipId &&
    data.joinedAtSeconds === joinEpoch.seconds &&
    data.joinedAtNanos === joinEpoch.nanoseconds;
}

// Deletes only P4b documents that still belong to the departing membership
// generation. A delayed leave/ban/deletion path must never erase a later
// rejoin's exhibit or its private idempotency receipt.
async function deleteGyeDedicationForMembership(
  transaction,
  gref,
  uid,
  membershipId,
  joinEpoch,
) {
  if (!transaction || typeof transaction.getAll !== "function" ||
      typeof transaction.delete !== "function" ||
      !gref || typeof gref.collection !== "function" ||
      !validUid(uid) || !validMembershipId(membershipId) ||
      !validJoinEpoch(joinEpoch)) {
    return;
  }
  const dedicationRef = gref.collection("decor_dedications").doc(uid);
  const mutationRef = gref
    .collection("decor_dedication_mutations")
    .doc(uid);
  const [dedication, mutation] = await transaction.getAll(
    dedicationRef,
    mutationRef,
  );
  if (belongsToMembership(dedication, uid, membershipId, joinEpoch)) {
    transaction.delete(dedicationRef);
  }
  if (belongsToMembership(mutation, uid, membershipId, joinEpoch)) {
    transaction.delete(mutationRef);
  }
}

module.exports = {
  deleteGyeDedicationForMembership,
  joinEpochFrom,
};
