"use strict";

const CALLABLE_OPTIONS = Object.freeze({
  region: "europe-west3",
  enforceAppCheck: true,
  consumeAppCheckToken: true,
});

const DEDICATION_SCHEMA_VERSION = 1;
const MUTATION_SCHEMA_VERSION = 3;
const DEDICATION_SLOT_COUNT = 10;
const DEDICATION_RECEIPT_LIMIT = 16;
const DEDICATION_THROTTLE_MILLIS = 15 * 1000;
const GYE_ID_PATTERN = /^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{6}$/;
const OPERATION_ID_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._:-]{7,127}$/;
const DECORATION_SLUGS = new Set([
  "decoration_chaekgado",
  "decoration_seoan",
  "decoration_munbangsau",
  "decoration_sagunja_maehwa",
  "decoration_soban",
  "decoration_gat_buchae",
  "decoration_sagunja_nan",
  "decoration_jagae_mungap",
  "decoration_pyeonaek",
  "decoration_sagunja_guk",
  "decoration_sagunja_juk",
]);
const PAYLOAD_KEYS = new Set([
  "gyeId",
  "expectedMembershipId",
  "expectedJoinedAtSeconds",
  "expectedJoinedAtNanos",
  "decorationSlug",
  "expectedRevision",
  "operationId",
]);

class BoundaryFailure extends Error {
  constructor(status, safeCode) {
    super(safeCode);
    this.status = status;
    this.safeCode = safeCode;
  }
}

function invalidPayload() {
  throw new BoundaryFailure("invalid-argument", "invalid-dedication-payload");
}

function isPlainObject(value) {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    return false;
  }
  const prototype = Object.getPrototypeOf(value);
  return prototype === Object.prototype || prototype === null;
}

function validatePayload(raw) {
  if (!isPlainObject(raw) || Object.keys(raw).length !== PAYLOAD_KEYS.size) {
    invalidPayload();
  }
  for (const key of Object.keys(raw)) {
    if (!PAYLOAD_KEYS.has(key)) invalidPayload();
  }
  if (typeof raw.gyeId !== "string" || !GYE_ID_PATTERN.test(raw.gyeId)) {
    invalidPayload();
  }
  if (!validMembershipId(raw.expectedMembershipId)) {
    invalidPayload();
  }
  if (!validJoinedAt(
    raw.expectedJoinedAtSeconds,
    raw.expectedJoinedAtNanos,
  )) {
    invalidPayload();
  }
  if (raw.decorationSlug !== null &&
      (typeof raw.decorationSlug !== "string" ||
        !DECORATION_SLUGS.has(raw.decorationSlug))) {
    invalidPayload();
  }
  if (!Number.isSafeInteger(raw.expectedRevision) ||
      raw.expectedRevision < 0) {
    invalidPayload();
  }
  if (typeof raw.operationId !== "string" ||
      !OPERATION_ID_PATTERN.test(raw.operationId)) {
    invalidPayload();
  }
  return {
    gyeId: raw.gyeId,
    expectedMembershipId: raw.expectedMembershipId,
    expectedJoinedAtSeconds: raw.expectedJoinedAtSeconds,
    expectedJoinedAtNanos: raw.expectedJoinedAtNanos,
    decorationSlug: raw.decorationSlug,
    expectedRevision: raw.expectedRevision,
    operationId: raw.operationId,
  };
}

function validateRequestContext(request) {
  if (!request?.app || typeof request.app.appId !== "string" ||
      request.app.appId.trim().length === 0) {
    throw new BoundaryFailure("failed-precondition", "app-check-required");
  }
  if (request.app.alreadyConsumed === true) {
    throw new BoundaryFailure(
      "resource-exhausted",
      "app-check-token-consumed",
    );
  }
  const uid = request?.auth?.uid;
  if (typeof uid !== "string" || uid.trim().length === 0 ||
      uid.length > 128 || uid.includes("/")) {
    throw new BoundaryFailure("unauthenticated", "authentication-required");
  }
  return { uid };
}

function documentData(snapshot) {
  return snapshot?.exists ? snapshot.data() || {} : null;
}

function validJoinedAt(seconds, nanoseconds) {
  return Number.isSafeInteger(seconds) && seconds >= 0 &&
    Number.isSafeInteger(nanoseconds) && nanoseconds >= 0 &&
    nanoseconds < 1000000000;
}

function joinedAtParts(value) {
  if (!value || typeof value !== "object" ||
      !validJoinedAt(value.seconds, value.nanoseconds)) {
    return null;
  }
  return {
    seconds: value.seconds,
    nanoseconds: value.nanoseconds,
  };
}

function activeMembership(member) {
  if (!member || member.status !== "active" ||
      !validMembershipId(member.membershipId)) {
    return null;
  }
  const joinedAt = joinedAtParts(member.joinedAt);
  if (!joinedAt) return null;
  return { membershipId: member.membershipId, joinedAt };
}

function validMembershipId(value) {
  return typeof value === "string" && value.length >= 16 &&
    value.length <= 64 && value === value.trim() && !value.includes("/");
}

function activeRevision(dedication) {
  if (!dedication || !Number.isSafeInteger(dedication.revision) ||
      dedication.revision < 1) {
    return null;
  }
  return dedication.revision;
}

function storedJoinEpoch(value) {
  if (!value || typeof value !== "object" ||
      !validJoinedAt(value.joinedAtSeconds, value.joinedAtNanos)) {
    return null;
  }
  return {
    seconds: value.joinedAtSeconds,
    nanoseconds: value.joinedAtNanos,
  };
}

function matchesJoinEpoch(value, joinedAt) {
  const epoch = storedJoinEpoch(value);
  return epoch !== null && epoch.seconds === joinedAt.seconds &&
    epoch.nanoseconds === joinedAt.nanoseconds;
}

function isValidSlot(value) {
  return Number.isSafeInteger(value) &&
    value >= 0 && value < DEDICATION_SLOT_COUNT;
}

function isActiveState(value) {
  return value === undefined || value === "active";
}

function validCurrentActiveDedication(dedication, uid, membershipId, joinedAt) {
  return dedication?.schemaVersion === DEDICATION_SCHEMA_VERSION &&
    isActiveState(dedication.state) &&
    dedication.uid === uid && dedication.membershipId === membershipId &&
    matchesJoinEpoch(dedication, joinedAt) &&
    typeof dedication.decorationSlug === "string" &&
    DECORATION_SLUGS.has(dedication.decorationSlug) &&
    isValidSlot(dedication.slotIndex) && activeRevision(dedication) !== null;
}

function validCurrentTombstone(dedication, uid, membershipId, joinedAt) {
  return dedication?.schemaVersion === DEDICATION_SCHEMA_VERSION &&
    dedication.state === "withdrawn" &&
    dedication.uid === uid && dedication.membershipId === membershipId &&
    matchesJoinEpoch(dedication, joinedAt) &&
    dedication.decorationSlug === null && dedication.slotIndex === null &&
    activeRevision(dedication) !== null && dedication.revision >= 2;
}

function currentDedicationKind(dedication, uid, membershipId, joinedAt) {
  if (!dedication) return "absent";
  // A document at this UID path is current only for the exact three-part
  // membership generation. In particular, old P4b records have no immutable
  // epoch; they must never be mistaken for a later rejoin that happens to
  // reuse a membership id. A current caller can safely replace that stale
  // record inside this transaction.
  if (dedication.uid !== uid || dedication.membershipId !== membershipId ||
      !matchesJoinEpoch(dedication, joinedAt)) {
    return "stale";
  }
  if (validCurrentActiveDedication(dedication, uid, membershipId, joinedAt)) {
    return "active";
  }
  if (validCurrentTombstone(dedication, uid, membershipId, joinedAt)) {
    return "withdrawn";
  }
  return "invalid";
}

function payloadFingerprint({
  gyeId,
  expectedMembershipId,
  expectedJoinedAtSeconds,
  expectedJoinedAtNanos,
  decorationSlug,
  expectedRevision,
}) {
  return `${gyeId}\u0000${expectedMembershipId}\u0000${expectedJoinedAtSeconds}\u0000${expectedJoinedAtNanos}\u0000${decorationSlug || ""}\u0000${expectedRevision}`;
}

function result(state, decorationSlug, slotIndex, revision) {
  return {
    state,
    decorationSlug,
    slotIndex,
    revision,
  };
}

function receiptResult(data) {
  const receipt = data?.result;
  if (!isPlainObject(receipt) ||
      !["dedicated", "withdrawn", "unchanged"].includes(receipt.state) ||
      !Number.isSafeInteger(receipt.revision) || receipt.revision < 0) {
    return null;
  }
  const activeExhibit =
    typeof receipt.decorationSlug === "string" &&
    DECORATION_SLUGS.has(receipt.decorationSlug) &&
    isValidSlot(receipt.slotIndex) &&
    receipt.revision >= 1;
  const noExhibit =
    receipt.decorationSlug === null &&
    receipt.slotIndex === null &&
    receipt.revision >= 0;
  if ((receipt.state === "dedicated" && !activeExhibit) ||
      (receipt.state === "withdrawn" &&
        (!noExhibit || receipt.revision < 1)) ||
      (receipt.state === "unchanged" && !activeExhibit && !noExhibit)) {
    return null;
  }
  return result(
    receipt.state,
    activeExhibit ? receipt.decorationSlug : null,
    activeExhibit ? receipt.slotIndex : null,
    receipt.revision,
  );
}

function isActiveSlotOccupant(dedication) {
  return isActiveState(dedication?.state) &&
    storedJoinEpoch(dedication) !== null && isValidSlot(dedication.slotIndex);
}

function firstFreeSlot(documents, uid) {
  const occupied = new Set();
  for (const document of documents) {
    if (document.id === uid) continue;
    const data = document.data() || {};
    if (isActiveSlotOccupant(data)) occupied.add(data.slotIndex);
  }
  for (let slot = 0; slot < DEDICATION_SLOT_COUNT; slot += 1) {
    if (!occupied.has(slot)) return slot;
  }
  return null;
}

function hasOwn(object, key) {
  return Object.prototype.hasOwnProperty.call(object, key);
}

function validPayloadFingerprint(value, gyeId, membershipId, joinedAt) {
  if (typeof value !== "string" || value.length === 0 ||
      value.length > 256) {
    return false;
  }
  const parts = value.split("\u0000");
  if (parts.length !== 6 || parts[0] !== gyeId ||
      parts[1] !== membershipId) {
    return false;
  }
  const joinedAtSeconds = Number(parts[2]);
  const joinedAtNanos = Number(parts[3]);
  if (!validJoinedAt(joinedAtSeconds, joinedAtNanos) ||
      String(joinedAtSeconds) !== parts[2] ||
      String(joinedAtNanos) !== parts[3] ||
      joinedAtSeconds !== joinedAt.seconds ||
      joinedAtNanos !== joinedAt.nanoseconds) {
    return false;
  }
  if (parts[4] !== "" && !DECORATION_SLUGS.has(parts[4])) return false;
  const revision = Number(parts[5]);
  return Number.isSafeInteger(revision) && revision >= 0 &&
    String(revision) === parts[5];
}

function receiptEntry(value, gyeId, membershipId, joinedAt) {
  if (!isPlainObject(value) || Object.keys(value).length !== 3 ||
      !hasOwn(value, "operationId") ||
      !hasOwn(value, "payloadFingerprint") || !hasOwn(value, "result") ||
      typeof value.operationId !== "string" ||
      !OPERATION_ID_PATTERN.test(value.operationId) ||
      !validPayloadFingerprint(
        value.payloadFingerprint,
        gyeId,
        membershipId,
        joinedAt,
      )) {
    return null;
  }
  const outcome = receiptResult(value);
  if (!outcome) return null;
  return {
    operationId: value.operationId,
    payloadFingerprint: value.payloadFingerprint,
    result: outcome,
  };
}

function receiptHistory(value, gyeId, membershipId, joinedAt) {
  if (!Array.isArray(value) || value.length > DEDICATION_RECEIPT_LIMIT) {
    return null;
  }
  const operationIds = new Set();
  const receipts = [];
  for (const rawEntry of value) {
    const entry = receiptEntry(rawEntry, gyeId, membershipId, joinedAt);
    if (!entry || operationIds.has(entry.operationId)) return null;
    operationIds.add(entry.operationId);
    receipts.push(entry);
  }
  return receipts;
}

function legacyReceiptEntry(mutation, gyeId, membershipId, joinedAt) {
  if (!mutation || typeof mutation.lastOperationId !== "string" ||
      typeof mutation.payloadFingerprint !== "string") {
    return null;
  }
  return receiptEntry({
    operationId: mutation.lastOperationId,
    payloadFingerprint: mutation.payloadFingerprint,
    result: mutation.result,
  }, gyeId, membershipId, joinedAt);
}

function readLastAcceptedAtMillis(mutation) {
  if (mutation.lastAcceptedAtMillis === undefined ||
      mutation.lastAcceptedAtMillis === null) {
    return null;
  }
  if (!Number.isSafeInteger(mutation.lastAcceptedAtMillis) ||
      mutation.lastAcceptedAtMillis < 0) {
    return undefined;
  }
  return mutation.lastAcceptedAtMillis;
}

function receiptLedger(mutation, uid, membershipId, gyeId, joinedAt) {
  if (!mutation) {
    return { receipts: [], lastAcceptedAtMillis: null };
  }
  if (!isPlainObject(mutation)) return null;
  // Receipt replay is only meaningful for the exact public membership
  // generation. Any older/legacy identity is stale state, not corruption of
  // the current generation, so replace it transactionally rather than
  // replaying its operation or surfacing a false conflict.
  if (mutation.uid !== uid || mutation.membershipId !== membershipId ||
      !matchesJoinEpoch(mutation, joinedAt)) {
    return { receipts: [], lastAcceptedAtMillis: null };
  }
  const lastAcceptedAtMillis = readLastAcceptedAtMillis(mutation);
  if (lastAcceptedAtMillis === undefined) return null;
  if (mutation.operationReceipts !== undefined) {
    if (mutation.schemaVersion !== MUTATION_SCHEMA_VERSION) return null;
    const receipts = receiptHistory(
      mutation.operationReceipts,
      gyeId,
      membershipId,
      joinedAt,
    );
    if (!receipts || receipts.length === 0 ||
        mutation.lastOperationId !== receipts.at(-1).operationId) {
      return null;
    }
    return { receipts, lastAcceptedAtMillis };
  }
  const legacy = legacyReceiptEntry(
    mutation,
    gyeId,
    membershipId,
    joinedAt,
  );
  if (!legacy) return null;
  return {
    receipts: [legacy],
    lastAcceptedAtMillis,
  };
}

function receiptForOperation(receipts, operationId) {
  for (let index = receipts.length - 1; index >= 0; index -= 1) {
    if (receipts[index].operationId === operationId) {
      return {
        entry: {
          payloadFingerprint: receipts[index].payloadFingerprint,
          outcome: receipts[index].result,
        },
        invalid: false,
      };
    }
  }
  return { entry: null, invalid: false };
}

function appendReceipt(receipts, operationId, fingerprint, outcome) {
  return [
    ...receipts,
    {
      operationId,
      payloadFingerprint: fingerprint,
      result: outcome,
    },
  ].slice(-DEDICATION_RECEIPT_LIMIT);
}

function mutationData({
  uid,
  membershipId,
  joinedAt,
  operationId,
  fingerprint,
  outcome,
  receipts,
  nowMillis,
  timestamp,
}) {
  return {
    schemaVersion: MUTATION_SCHEMA_VERSION,
    uid,
    membershipId,
    joinedAtSeconds: joinedAt.seconds,
    joinedAtNanos: joinedAt.nanoseconds,
    lastOperationId: operationId,
    operationReceipts: appendReceipt(
      receipts,
      operationId,
      fingerprint,
      outcome,
    ),
    lastAcceptedAtMillis: nowMillis,
    updatedAt: timestamp,
  };
}

function createGyeDedicationRuntime({
  firestore,
  serverTimestamp,
  serverNowMillis = Date.now,
  makeError,
  throttleMillis = DEDICATION_THROTTLE_MILLIS,
} = {}) {
  if (!firestore || typeof firestore.collection !== "function" ||
      typeof firestore.runTransaction !== "function") {
    throw new TypeError("A Firestore transaction adapter is required.");
  }
  if (typeof serverTimestamp !== "function" ||
      typeof serverNowMillis !== "function" || typeof makeError !== "function" ||
      !Number.isSafeInteger(throttleMillis) || throttleMillis < 0) {
    throw new TypeError("Complete Gye dedication runtime dependencies are required.");
  }

  async function execute(callback) {
    try {
      return await callback();
    } catch (error) {
      if (error instanceof BoundaryFailure) {
        throw makeError(error.status, error.safeCode);
      }
      throw makeError("internal", "dedication-unavailable");
    }
  }

  async function setGyeDecorationDedication(request) {
    return execute(async () => {
      const { uid } = validateRequestContext(request);
      const data = validatePayload(request.data);
      const gref = firestore.collection("gye").doc(data.gyeId);
      const memberRef = gref.collection("members").doc(uid);
      const banRef = gref.collection("bans").doc(uid);
      const deletionRef = firestore.collection("account_deletions").doc(uid);
      const dedicationRef = gref.collection("decor_dedications").doc(uid);
      const mutationRef = gref.collection("decor_dedication_mutations").doc(uid);
      const fingerprint = payloadFingerprint(data);

      return firestore.runTransaction(async (transaction) => {
        const [
          metaSnapshot,
          memberSnapshot,
          banSnapshot,
          deletionSnapshot,
          dedicationSnapshot,
          mutationSnapshot,
          dedicationQuery,
        ] = await Promise.all([
          transaction.get(gref),
          transaction.get(memberRef),
          transaction.get(banRef),
          transaction.get(deletionRef),
          transaction.get(dedicationRef),
          transaction.get(mutationRef),
          transaction.get(gref.collection("decor_dedications")),
        ]);

        const meta = documentData(metaSnapshot);
        if (!meta || meta.lifecycleState !== "active") {
          throw new BoundaryFailure("failed-precondition", "gye-not-active");
        }
        const membership = activeMembership(documentData(memberSnapshot));
        if (!membership) {
          throw new BoundaryFailure(
            "permission-denied",
            "gye-membership-inactive",
          );
        }
        const { membershipId, joinedAt } = membership;
        const ban = documentData(banSnapshot);
        if (ban) {
          throw new BoundaryFailure("permission-denied", "gye-member-banned");
        }
        if (deletionSnapshot.exists) {
          throw new BoundaryFailure(
            "failed-precondition",
            "account-deletion-active",
          );
        }

        // The caller binds its request to the current membership generation.
        // This check deliberately happens before receipt replay so an M1
        // request delayed past leave/rejoin M2 cannot act in M2's courtyard.
        if (data.expectedMembershipId !== membershipId) {
          throw new BoundaryFailure(
            "aborted",
            "dedication-membership-conflict",
          );
        }
        if (data.expectedJoinedAtSeconds !== joinedAt.seconds ||
            data.expectedJoinedAtNanos !== joinedAt.nanoseconds) {
          throw new BoundaryFailure(
            "aborted",
            "dedication-join-epoch-conflict",
          );
        }

        const previousMutation = documentData(mutationSnapshot);
        const ledger = receiptLedger(
          previousMutation,
          uid,
          membershipId,
          data.gyeId,
          joinedAt,
        );
        if (!ledger) {
          throw new BoundaryFailure(
            "failed-precondition",
            "dedication-receipt-invalid",
          );
        }
        const prior = receiptForOperation(ledger.receipts, data.operationId);
        if (prior.invalid) {
          throw new BoundaryFailure(
            "failed-precondition",
            "dedication-receipt-invalid",
          );
        }
        if (prior.entry) {
          if (prior.entry.payloadFingerprint !== fingerprint) {
            throw new BoundaryFailure(
              "already-exists",
              "dedication-operation-collision",
            );
          }
          return prior.entry.outcome;
        }

        const nowMillis = serverNowMillis();
        if (!Number.isSafeInteger(nowMillis) || nowMillis < 0) {
          throw new Error("Server clock is unavailable.");
        }
        if (ledger.lastAcceptedAtMillis !== null &&
            nowMillis - ledger.lastAcceptedAtMillis < throttleMillis) {
          throw new BoundaryFailure(
            "resource-exhausted",
            "dedication-throttled",
          );
        }

        const storedDedication = documentData(dedicationSnapshot);
        const kind = currentDedicationKind(
          storedDedication,
          uid,
          membershipId,
          joinedAt,
        );
        if (kind === "invalid") {
          throw new BoundaryFailure(
            "failed-precondition",
            "dedication-state-invalid",
          );
        }
        const currentDedication = kind === "active" || kind === "withdrawn"
          ? storedDedication
          : null;
        const revision = activeRevision(currentDedication);
        const actualRevision = revision || 0;
        if (actualRevision !== data.expectedRevision) {
          throw new BoundaryFailure(
            "aborted",
            "dedication-revision-conflict",
          );
        }

        const timestamp = serverTimestamp();
        let outcome;
        if (data.decorationSlug === null) {
          if (kind === "active") {
            const nextRevision = revision + 1;
            if (!Number.isSafeInteger(nextRevision)) {
              throw new BoundaryFailure(
                "failed-precondition",
                "dedication-state-invalid",
              );
            }
            transaction.update(dedicationRef, {
              schemaVersion: DEDICATION_SCHEMA_VERSION,
              state: "withdrawn",
              uid,
              membershipId,
              joinedAtSeconds: joinedAt.seconds,
              joinedAtNanos: joinedAt.nanoseconds,
              decorationSlug: null,
              slotIndex: null,
              revision: nextRevision,
              lastOperationId: data.operationId,
              createdAt: currentDedication.createdAt ?? timestamp,
              updatedAt: timestamp,
            });
            outcome = result("withdrawn", null, null, nextRevision);
          } else if (kind === "withdrawn") {
            outcome = result("unchanged", null, null, revision);
          } else {
            if (kind === "stale" && storedDedication) {
              transaction.delete(dedicationRef);
            }
            outcome = result("unchanged", null, null, 0);
          }
        } else if (kind === "active" &&
            currentDedication.decorationSlug === data.decorationSlug) {
          outcome = result(
            "unchanged",
            data.decorationSlug,
            currentDedication.slotIndex,
            revision,
          );
        } else {
          const slotIndex = kind === "active"
            ? currentDedication.slotIndex
            : firstFreeSlot(dedicationQuery.docs || [], uid);
          if (!isValidSlot(slotIndex)) {
            throw new BoundaryFailure(
              "resource-exhausted",
              "dedication-slots-full",
            );
          }
          const nextRevision = currentDedication ? revision + 1 : 1;
          if (!Number.isSafeInteger(nextRevision)) {
            throw new BoundaryFailure(
              "failed-precondition",
              "dedication-state-invalid",
            );
          }
          const nextDedication = {
            schemaVersion: DEDICATION_SCHEMA_VERSION,
            state: "active",
            uid,
            membershipId,
            joinedAtSeconds: joinedAt.seconds,
            joinedAtNanos: joinedAt.nanoseconds,
            decorationSlug: data.decorationSlug,
            slotIndex,
            revision: nextRevision,
            lastOperationId: data.operationId,
            updatedAt: timestamp,
          };
          if (currentDedication) {
            transaction.update(dedicationRef, {
              ...nextDedication,
              createdAt: currentDedication.createdAt ?? timestamp,
            });
          } else {
            transaction.set(dedicationRef, {
              ...nextDedication,
              createdAt: timestamp,
            });
          }
          outcome = result(
            "dedicated",
            data.decorationSlug,
            slotIndex,
            nextRevision,
          );
        }

        transaction.set(mutationRef, mutationData({
          uid,
          membershipId,
          joinedAt,
          operationId: data.operationId,
          fingerprint,
          outcome,
          receipts: ledger.receipts,
          nowMillis,
          timestamp,
        }));
        return outcome;
      });
    });
  }

  return Object.freeze({ setGyeDecorationDedication });
}

function createGyeDedicationCallable({ handler, onCall } = {}) {
  if (typeof handler !== "function" || typeof onCall !== "function") {
    throw new TypeError("Gye dedication callable dependencies are required.");
  }
  return onCall(CALLABLE_OPTIONS, handler);
}

module.exports = {
  CALLABLE_OPTIONS,
  DECORATION_SLUGS,
  DEDICATION_RECEIPT_LIMIT,
  DEDICATION_SLOT_COUNT,
  createGyeDedicationCallable,
  createGyeDedicationRuntime,
};
