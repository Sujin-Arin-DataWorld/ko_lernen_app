"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  deleteGyeDedicationForMembership,
} = require("./gye_dedication_cleanup");

class FakeReference {
  constructor(firestore, path) {
    this.firestore = firestore;
    this.path = path;
    this.id = path.split("/").at(-1);
  }

  collection(name) {
    return new FakeCollection(this.firestore, `${this.path}/${name}`);
  }
}

class FakeCollection {
  constructor(firestore, path) {
    this.firestore = firestore;
    this.path = path;
  }

  doc(id) {
    return new FakeReference(this.firestore, `${this.path}/${id}`);
  }
}

class FakeFirestore {
  constructor(documents) {
    this.documents = new Map(Object.entries(documents));
    this.readPaths = [];
  }

  collection(name) {
    return new FakeCollection(this, name);
  }

  async runTransaction(callback) {
    const transaction = {
      getAll: async (...refs) => refs.map((ref) => {
        this.readPaths.push(ref.path);
        const data = this.documents.get(ref.path);
        return {
          exists: data !== undefined,
          ref,
          data: () => data,
        };
      }),
      delete: (ref) => this.documents.delete(ref.path),
    };
    return callback(transaction);
  }
}

const UID = "member-one";
const OLD_MEMBERSHIP_ID = "membership-member-one-old-0123456789";
const NEW_MEMBERSHIP_ID = "membership-member-one-new-0123456789";
const OLD_JOIN_EPOCH = Object.freeze({
  seconds: 1_754_355_200,
  nanoseconds: 123_000_000,
});
const NEW_JOIN_EPOCH = Object.freeze({
  seconds: 1_754_355_260,
  nanoseconds: 456_000_000,
});
const GYE_PATH = "gye/ABC234";
const EXHIBIT_PATH = `${GYE_PATH}/decor_dedications/${UID}`;
const RECEIPT_PATH = `${GYE_PATH}/decor_dedication_mutations/${UID}`;

function exhibit(membershipId, joinEpoch = OLD_JOIN_EPOCH) {
  return {
    schemaVersion: 1,
    state: "active",
    uid: UID,
    membershipId,
    joinedAtSeconds: joinEpoch.seconds,
    joinedAtNanos: joinEpoch.nanoseconds,
    decorationSlug: "decoration_chaekgado",
    slotIndex: 0,
    revision: 1,
  };
}

function withdrawnTombstone(membershipId, joinEpoch = OLD_JOIN_EPOCH) {
  return {
    schemaVersion: 1,
    state: "withdrawn",
    uid: UID,
    membershipId,
    joinedAtSeconds: joinEpoch.seconds,
    joinedAtNanos: joinEpoch.nanoseconds,
    decorationSlug: null,
    slotIndex: null,
    revision: 2,
    lastOperationId: "dedication-op-withdrawn-0001",
  };
}

function receipt(membershipId, joinEpoch = OLD_JOIN_EPOCH) {
  return {
    uid: UID,
    membershipId,
    joinedAtSeconds: joinEpoch.seconds,
    joinedAtNanos: joinEpoch.nanoseconds,
    lastOperationId: "dedication-op-0001",
  };
}

test("matching departing membership deletes both public tombstone and private receipt", async () => {
  const firestore = new FakeFirestore({
    [EXHIBIT_PATH]: withdrawnTombstone(OLD_MEMBERSHIP_ID),
    [RECEIPT_PATH]: receipt(OLD_MEMBERSHIP_ID),
  });
  const gref = firestore.collection("gye").doc("ABC234");

  await firestore.runTransaction((transaction) =>
    deleteGyeDedicationForMembership(
      transaction,
      gref,
      UID,
      OLD_MEMBERSHIP_ID,
      OLD_JOIN_EPOCH,
    ));

  assert.equal(firestore.documents.has(EXHIBIT_PATH), false);
  assert.equal(firestore.documents.has(RECEIPT_PATH), false);
});

test("old leave cleanup preserves a later rejoined membership generation", async () => {
  const firestore = new FakeFirestore({
    [EXHIBIT_PATH]: exhibit(NEW_MEMBERSHIP_ID),
    [RECEIPT_PATH]: receipt(NEW_MEMBERSHIP_ID),
  });
  const gref = firestore.collection("gye").doc("ABC234");

  await firestore.runTransaction((transaction) =>
    deleteGyeDedicationForMembership(
      transaction,
      gref,
      UID,
      OLD_MEMBERSHIP_ID,
      OLD_JOIN_EPOCH,
    ));

  assert.equal(
    firestore.documents.get(EXHIBIT_PATH).membershipId,
    NEW_MEMBERSHIP_ID,
  );
  assert.equal(
    firestore.documents.get(RECEIPT_PATH).membershipId,
    NEW_MEMBERSHIP_ID,
  );
});

test("a delayed M1 cleanup preserves a rejoined M3 using the same membership id", async () => {
  const firestore = new FakeFirestore({
    [EXHIBIT_PATH]: exhibit(OLD_MEMBERSHIP_ID, NEW_JOIN_EPOCH),
    [RECEIPT_PATH]: receipt(OLD_MEMBERSHIP_ID, NEW_JOIN_EPOCH),
  });
  const gref = firestore.collection("gye").doc("ABC234");

  await firestore.runTransaction((transaction) =>
    deleteGyeDedicationForMembership(
      transaction,
      gref,
      UID,
      OLD_MEMBERSHIP_ID,
      OLD_JOIN_EPOCH,
    ));

  assert.deepEqual(
    firestore.documents.get(EXHIBIT_PATH).joinedAtSeconds,
    NEW_JOIN_EPOCH.seconds,
  );
  assert.deepEqual(
    firestore.documents.get(RECEIPT_PATH).joinedAtNanos,
    NEW_JOIN_EPOCH.nanoseconds,
  );
});
