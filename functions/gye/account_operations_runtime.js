"use strict";

const crypto = require("node:crypto");
const {
  cancelReplacementOperation,
  claimDeletionProof,
  createOrReuseOperation,
  normalizeOperation,
  operationResult,
  transitionOperation,
} = require("./account_operations");
const {
  accountTombstoneCleanupAction,
} = require("./lifecycle");

const CALLABLE_NAMES = Object.freeze([
  "prepareAnonymousReplacement",
  "attachReplacementTarget",
  "commitReplacementReconciliation",
  "startSourceCleanup",
  "cancelAnonymousReplacement",
  "requestAccountDeletion",
  "issueDeletionProof",
  "completeAppleRevocation",
  "getAccountOperation",
]);
const CALLABLE_OPTIONS = Object.freeze({
  region: "europe-west3",
  enforceAppCheck: true,
  consumeAppCheckToken: true,
});
const ACTIONABLE_DELETION_PHASES = Object.freeze([
  "sourceCleanupPending",
  "deletionRequested",
  "userTreeDeleting",
  "authDeleted",
  "communityCleanupPending",
  "processorCleanupPending",
]);
const TERMINAL_PHASES = new Set(["completed", "blocked", "cancelled"]);
const AUTH_MAX_AGE_SECONDS = 300;
const ANONYMOUS_RATE_WINDOW_MILLIS = 300_000;
const ANONYMOUS_RATE_LIMIT = 20;
const DELETION_PROOF_LIFETIME_MILLIS = 86_400_000;
const DELETION_PROOF_ISSUANCE_WINDOW_MILLIS = 86_400_000;
const DELETION_PROOF_ISSUANCE_LIMIT = 3;
const PUBLIC_RATE_WINDOW_MILLIS = 300_000;
const PUBLIC_RATE_LIMIT = 20;
const PUBLIC_REQUEST_MAX_BYTES = 1_024;
const FIRST_PARTY_ORIGIN = "https://hangul-sori.com";
const PUBLIC_ENDPOINT_OPTIONS = Object.freeze({
  region: "europe-west3",
  cors: [FIRST_PARTY_ORIGIN],
});
const GENERIC_PUBLIC_RESULT = Object.freeze({
  status: "request-received",
});
const DEFAULT_WORKER_LEASE_MILLIS = 60_000;
const DEFAULT_DELETE_PAGE_SIZE = 200;

async function fetchActionableDeletionCandidates({
  collection,
  limit = 50,
} = {}) {
  if (!collection || typeof collection.where !== "function") {
    throw new TypeError("Account operation collection is required.");
  }
  if (!Number.isInteger(limit) || limit < 1) {
    throw new TypeError("Candidate limit must be a positive integer.");
  }
  const [phaseSnapshot, completedAppleSnapshot] = await Promise.all([
    collection
      .where("phase", "in", ACTIONABLE_DELETION_PHASES)
      .limit(limit)
      .get(),
    collection
      .where("phase", "==", "appleRevocationPending")
      .where("deletionProgress.appleRevocationComplete", "==", true)
      .limit(limit)
      .get(),
  ]);
  const phaseDocs = Array.isArray(phaseSnapshot?.docs)
    ? phaseSnapshot.docs
    : [];
  const completedAppleDocs = Array.isArray(completedAppleSnapshot?.docs)
    ? completedAppleSnapshot.docs
    : [];
  return [...phaseDocs, ...completedAppleDocs];
}

class BoundaryFailure extends Error {
  constructor(status, safeCode) {
    super(safeCode);
    this.status = status;
    this.safeCode = safeCode;
  }
}

function repositoryFailure(code) {
  const error = new Error(code);
  error.code = code;
  return error;
}

function stableKey(...parts) {
  return crypto
    .createHash("sha256")
    .update(parts.join("\u0000"), "utf8")
    .digest("hex");
}

function requiredString(value, safeCode) {
  if (typeof value !== "string" || value.length === 0 || value.length > 256) {
    throw new BoundaryFailure("invalid-argument", safeCode);
  }
  return value;
}

function requiredExpectedVersion(value) {
  if (!Number.isInteger(value) || value < 0) {
    throw new BoundaryFailure(
      "invalid-argument",
      "invalid-operation-version",
    );
  }
  return value;
}

function requiredOperationId(value) {
  if (typeof value !== "string" ||
      !/^[A-Za-z0-9_-]{1,128}$/.test(value)) {
    throw new BoundaryFailure("invalid-argument", "invalid-operation-id");
  }
  return value;
}

function isRawDeletionProof(value) {
  if (typeof value !== "string" ||
      !/^[A-Za-z0-9_-]{43}$/.test(value)) {
    return false;
  }
  const decoded = Buffer.from(value, "base64url");
  return decoded.length === 32 && decoded.toString("base64url") === value;
}

function requiredProofHash(value) {
  if (typeof value !== "string" ||
      !/^[A-Za-z0-9_-]{16,256}$/.test(value)) {
    throw repositoryFailure("invalid-deletion-proof-hash");
  }
  return value;
}

function createKeyedDeletionProofDigest({ getSecret } = {}) {
  if (typeof getSecret !== "function") {
    throw new TypeError("A deletion-proof secret accessor is required.");
  }
  return function keyedDeletionProofDigest(domain, value) {
    let encodedSecret;
    try {
      encodedSecret = getSecret();
    } catch {
      throw new Error("deletion-proof-secret-unavailable");
    }
    const canonicalHex = typeof encodedSecret === "string" &&
      encodedSecret.length >= 64 &&
      encodedSecret.length % 2 === 0 &&
      /^[0-9a-f]+$/.test(encodedSecret);
    if (!canonicalHex) {
      throw new Error("deletion-proof-secret-unavailable");
    }
    const keyBytes = Buffer.from(encodedSecret, "hex");
    if (keyBytes.length < 32 ||
        keyBytes.toString("hex") !== encodedSecret) {
      throw new Error("deletion-proof-secret-unavailable");
    }
    return crypto
      .createHmac("sha256", keyBytes)
      .update(`${domain}\u0000${value}`, "utf8")
      .digest("hex");
  };
}

function persistedOperation(operation, previous, nowMillis) {
  return {
    ...operation,
    createdAtMillis: Number.isFinite(previous?.createdAtMillis)
      ? previous.createdAtMillis
      : nowMillis,
    updatedAtMillis: nowMillis,
  };
}

function assertParticipant(operation, actorUid, role) {
  const permitted = role === "source"
    ? operation.sourceUid === actorUid
    : role === "target"
      ? operation.targetUid === actorUid
      : operation.sourceUid === actorUid || operation.targetUid === actorUid;
  if (!permitted) {
    throw repositoryFailure("operation-not-authorized");
  }
}

function createFirestoreAccountOperationRepository({
  firestore,
  nowMillis = () => Date.now(),
  newOperationId = () => crypto.randomUUID(),
} = {}) {
  if (!firestore || typeof firestore.runTransaction !== "function") {
    throw new TypeError("A Firestore transaction adapter is required.");
  }

  const operations = firestore.collection("account_operations");
  const owners = firestore.collection("account_operation_owners");
  const requests = firestore.collection("account_operation_requests");
  const rateLimits = firestore.collection("account_operation_rate_limits");
  const deletionProofs = firestore.collection("account_deletion_proofs");
  const deletionProofOwners =
    firestore.collection("account_deletion_proof_owners");
  const publicRateLimits =
    firestore.collection("account_deletion_proof_rate_limits");
  const deletionMarkers = firestore.collection("account_deletions");

  function workerProgress(stored) {
    const progress = stored?.deletionProgress;
    return {
      cursor: typeof progress?.cursor === "string"
        ? progress.cursor
        : null,
      userTreeComplete: progress?.userTreeComplete === true,
      authComplete: progress?.authComplete === true,
      communityComplete: progress?.communityComplete === true,
      processorComplete: progress?.processorComplete === true,
      appleRevocationComplete:
        progress?.appleRevocationComplete === true,
      statusCode: typeof progress?.statusCode === "string"
        ? progress.statusCode
        : null,
    };
  }

  function workerResult(stored) {
    return {
      operation: normalizeOperation(stored),
      progress: workerProgress(stored),
      leaseVersion: Number.isInteger(stored?.workerLease?.leaseVersion)
        ? stored.workerLease.leaseVersion
        : 0,
      leaseUntilMillis: Number.isFinite(stored?.workerLease?.leaseUntilMillis)
        ? stored.workerLease.leaseUntilMillis
        : 0,
    };
  }

  async function createOrReuse(request, { deletionRequested = false } = {}) {
    const operationId = newOperationId();
    const ownerRef = owners.doc(stableKey(
      "account-operation-owner",
      request.sourceUid,
    ));
    const requestRef = requests.doc(stableKey(
      "account-operation-request",
      request.kind,
      request.sourceUid,
      request.requestKey,
    ));
    return firestore.runTransaction(async (transaction) => {
      const requestSnapshot = await transaction.get(requestRef);
      if (requestSnapshot.exists) {
        const mappedOperationId =
          (requestSnapshot.data() || {}).operationId;
        if (typeof mappedOperationId !== "string" ||
            mappedOperationId.length === 0) {
          throw repositoryFailure("invalid-operation");
        }
        const mappedRef = operations.doc(mappedOperationId);
        const mappedSnapshot = await transaction.get(mappedRef);
        if (!mappedSnapshot.exists) {
          throw repositoryFailure("invalid-operation");
        }
        const stored = mappedSnapshot.data();
        let operation = normalizeOperation(stored);
        const sameTarget = request.kind !== "replacement" ||
          operation.targetUid === request.targetUid;
        if (operation.kind !== request.kind ||
            operation.sourceUid !== request.sourceUid ||
            !sameTarget) {
          throw repositoryFailure("invalid-operation");
        }
        if (deletionRequested && operation.phase === "prepared") {
          operation = transitionOperation(operation, {
            toPhase: "deletionRequested",
            expectedVersion: operation.version,
          });
          transaction.set(
            mappedRef,
            persistedOperation(operation, stored, nowMillis()),
          );
        }
        return operation;
      }

      const ownerSnapshot = await transaction.get(ownerRef);
      let existing = null;
      let existingStored = null;
      if (ownerSnapshot.exists) {
        const existingId = (ownerSnapshot.data() || {}).operationId;
        if (typeof existingId !== "string" || existingId.length === 0) {
          throw repositoryFailure("invalid-operation");
        }
        const existingSnapshot = await transaction.get(operations.doc(existingId));
        if (!existingSnapshot.exists) {
          throw repositoryFailure("invalid-operation");
        }
        existingStored = existingSnapshot.data();
        existing = normalizeOperation(existingStored);
      }

      const creation = createOrReuseOperation({
        existingOperations: existing ? [existing] : [],
        request: { ...request, id: operationId },
      });
      if (existing && !creation.reused && !TERMINAL_PHASES.has(existing.phase)) {
        throw repositoryFailure("operation-in-progress");
      }

      let operation = creation.operation;
      if (deletionRequested && operation.phase === "prepared") {
        operation = transitionOperation(operation, {
          toPhase: "deletionRequested",
          expectedVersion: operation.version,
        });
      }
      const currentTime = nowMillis();
      if (creation.reused) {
        if (operation.version !== existing.version ||
            operation.phase !== existing.phase) {
          transaction.set(
            operations.doc(operation.id),
            persistedOperation(operation, existingStored, currentTime),
          );
        }
        transaction.set(requestRef, {
          operationId: operation.id,
          createdAtMillis: currentTime,
        });
        return operation;
      }

      const operationRef = operations.doc(operation.id);
      transaction.set(
        operationRef,
        persistedOperation(operation, null, currentTime),
      );
      transaction.set(ownerRef, {
        operationId: operation.id,
        updatedAtMillis: currentTime,
      });
      transaction.set(requestRef, {
        operationId: operation.id,
        createdAtMillis: currentTime,
      });
      return operation;
    });
  }

  async function transition({
    operationId,
    actorUid,
    role,
    expectedVersion,
    toPhase,
  }) {
    const operationRef = operations.doc(operationId);
    return firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(operationRef);
      if (!snapshot.exists) {
        throw repositoryFailure("operation-not-found");
      }
      const stored = snapshot.data();
      const current = normalizeOperation(stored);
      assertParticipant(current, actorUid, role);

      if (current.phase === toPhase &&
          current.version === expectedVersion + 1) {
        return current;
      }
      const advanced = transitionOperation(current, {
        toPhase,
        expectedVersion,
      });
      transaction.set(
        operationRef,
        persistedOperation(advanced, stored, nowMillis()),
      );
      return advanced;
    });
  }

  async function cancelReplacement({
    operationId,
    actorUid,
    expectedVersion,
  }) {
    const operationRef = operations.doc(operationId);
    return firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(operationRef);
      if (!snapshot.exists) {
        throw repositoryFailure("operation-not-found");
      }
      const stored = snapshot.data();
      const current = normalizeOperation(stored);
      assertParticipant(current, actorUid, "source");
      const ownerRef = owners.doc(stableKey(
        "account-operation-owner",
        current.sourceUid,
      ));
      const ownerSnapshot = await transaction.get(ownerRef);
      const cancelled = cancelReplacementOperation(current, {
        expectedVersion,
      });
      if (cancelled.version !== current.version ||
          cancelled.phase !== current.phase) {
        transaction.set(
          operationRef,
          persistedOperation(cancelled, stored, nowMillis()),
        );
      }
      if (ownerSnapshot.exists &&
          (ownerSnapshot.data() || {}).operationId === current.id) {
        transaction.delete(ownerRef);
      }
      return cancelled;
    });
  }

  async function get({ operationId, actorUid }) {
    const operationRef = operations.doc(operationId);
    return firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(operationRef);
      if (!snapshot.exists) {
        throw repositoryFailure("operation-not-found");
      }
      const operation = normalizeOperation(snapshot.data());
      assertParticipant(operation, actorUid, "participant");
      return operation;
    });
  }

  async function consumeAnonymousRequest({ uid, appId }) {
    const rateRef = rateLimits.doc(stableKey(uid, appId));
    return firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(rateRef);
      const current = snapshot.exists ? snapshot.data() || {} : {};
      const currentTime = nowMillis();
      const inWindow = Number.isFinite(current.windowStartedAtMillis) &&
        currentTime - current.windowStartedAtMillis <
          ANONYMOUS_RATE_WINDOW_MILLIS;
      const count = inWindow && Number.isInteger(current.count)
        ? current.count
        : 0;
      if (count >= ANONYMOUS_RATE_LIMIT) {
        throw repositoryFailure("anonymous-rate-limit-exceeded");
      }
      transaction.set(rateRef, {
        windowStartedAtMillis: inWindow
          ? current.windowStartedAtMillis
          : currentTime,
        count: count + 1,
        updatedAtMillis: currentTime,
      });
    });
  }

  async function issueDeletionProof({
    sourceUid,
    proofHash,
    appleRevocationRequired,
  }) {
    const ownerRef = deletionProofOwners.doc(stableKey(
      "account-deletion-proof-owner",
      sourceUid,
    ));
    const proofRef = deletionProofs.doc(proofHash);
    return firestore.runTransaction(async (transaction) => {
      const ownerSnapshot = await transaction.get(ownerRef);
      const owner = ownerSnapshot.exists ? ownerSnapshot.data() || {} : {};
      const currentTime = nowMillis();
      const inWindow =
        Number.isFinite(owner.issuanceWindowStartedAtMillis) &&
        currentTime - owner.issuanceWindowStartedAtMillis <
          DELETION_PROOF_ISSUANCE_WINDOW_MILLIS;
      const issuanceCount = inWindow && Number.isInteger(owner.issuanceCount)
        ? owner.issuanceCount
        : 0;
      if (issuanceCount >= DELETION_PROOF_ISSUANCE_LIMIT) {
        throw repositoryFailure("proof-issuance-rate-exceeded");
      }

      const previousHash = typeof owner.activeProofHash === "string"
        ? owner.activeProofHash
        : null;
      if (previousHash && previousHash !== proofHash) {
        transaction.delete(deletionProofs.doc(previousHash));
      }
      const expiresAtMillis =
        currentTime + DELETION_PROOF_LIFETIME_MILLIS;
      transaction.set(proofRef, {
        proofHash,
        sourceUid,
        appleRevocationRequired: appleRevocationRequired === true,
        issuedAtMillis: currentTime,
        expiresAtMillis,
        claimedOperationId: null,
      });
      transaction.set(ownerRef, {
        activeProofHash: proofHash,
        issuanceWindowStartedAtMillis: inWindow
          ? owner.issuanceWindowStartedAtMillis
          : currentTime,
        issuanceCount: issuanceCount + 1,
        updatedAtMillis: currentTime,
      });
      return { expiresAtMillis };
    });
  }

  async function claimDeletionByProof({ proofHash }) {
    const proposedOperationId = newOperationId();
    const proofRef = deletionProofs.doc(proofHash);
    return firestore.runTransaction(async (transaction) => {
      const proofSnapshot = await transaction.get(proofRef);
      if (!proofSnapshot.exists) return false;
      const storedProof = proofSnapshot.data() || {};
      const claim = claimDeletionProof(storedProof, {
        proofHash,
        nowMillis: nowMillis(),
        operationId: proposedOperationId,
      });
      if (!claim.accepted) return false;

      if (storedProof.claimedOperationId) {
        const claimedSnapshot = await transaction.get(
          operations.doc(claim.operationId),
        );
        if (!claimedSnapshot.exists) return false;
        const claimedOperation = normalizeOperation(claimedSnapshot.data());
        return claimedOperation.kind === "deletion" &&
          claimedOperation.sourceUid === storedProof.sourceUid;
      }

      const sourceUid = storedProof.sourceUid;
      if (typeof sourceUid !== "string" || sourceUid.length === 0) {
        return false;
      }
      const ownerRef = owners.doc(stableKey(
        "account-operation-owner",
        sourceUid,
      ));
      const ownerSnapshot = await transaction.get(ownerRef);
      let existing = null;
      let existingStored = null;
      if (ownerSnapshot.exists) {
        const existingId = (ownerSnapshot.data() || {}).operationId;
        if (typeof existingId !== "string" || existingId.length === 0) {
          return false;
        }
        const existingSnapshot =
          await transaction.get(operations.doc(existingId));
        if (!existingSnapshot.exists) return false;
        existingStored = existingSnapshot.data();
        existing = normalizeOperation(existingStored);
      }

      const creation = createOrReuseOperation({
        existingOperations: existing ? [existing] : [],
        request: {
          id: proposedOperationId,
          kind: "deletion",
          sourceUid,
          requestKey: stableKey(
            "account-deletion-proof-operation",
            proofHash,
          ),
          appleRevocationRequired:
            storedProof.appleRevocationRequired === true,
        },
      });
      if (existing && !creation.reused &&
          !TERMINAL_PHASES.has(existing.phase)) {
        return false;
      }

      let operation = creation.operation;
      if (operation.kind === "deletion" &&
          storedProof.appleRevocationRequired === true &&
          operation.appleRevocationRequired !== true) {
        operation = normalizeOperation({
          ...operation,
          appleRevocationRequired: true,
        });
      }
      if (operation.phase === "prepared") {
        operation = transitionOperation(operation, {
          toPhase: "deletionRequested",
          expectedVersion: operation.version,
        });
      }
      const currentTime = nowMillis();
      if (!creation.reused ||
          operation.phase !== existing?.phase ||
          operation.version !== existing?.version ||
          operation.appleRevocationRequired !==
            existing?.appleRevocationRequired) {
        transaction.set(
          operations.doc(operation.id),
          persistedOperation(operation, existingStored, currentTime),
        );
      }
      if (!creation.reused) {
        transaction.set(ownerRef, {
          operationId: operation.id,
          updatedAtMillis: currentTime,
        });
      }
      transaction.set(proofRef, {
        ...storedProof,
        claimedOperationId: operation.id,
        claimedAtMillis: currentTime,
      });
      return true;
    });
  }

  async function consumePublicProofRequest({ key }) {
    const rateRef = publicRateLimits.doc(key);
    return firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(rateRef);
      const current = snapshot.exists ? snapshot.data() || {} : {};
      const currentTime = nowMillis();
      const inWindow = Number.isFinite(current.windowStartedAtMillis) &&
        currentTime - current.windowStartedAtMillis <
          PUBLIC_RATE_WINDOW_MILLIS;
      const count = inWindow && Number.isInteger(current.count)
        ? current.count
        : 0;
      if (count >= PUBLIC_RATE_LIMIT) return false;
      transaction.set(rateRef, {
        windowStartedAtMillis: inWindow
          ? current.windowStartedAtMillis
          : currentTime,
        count: count + 1,
        updatedAtMillis: currentTime,
      });
      return true;
    });
  }

  async function claimDeletionWork({
    operationId,
    workerId,
    leaseMillis = DEFAULT_WORKER_LEASE_MILLIS,
    allowAppleRevocationInput = false,
  }) {
    const operationRef = operations.doc(requiredOperationId(operationId));
    requiredString(workerId, "worker-id-required");
    return firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(operationRef);
      if (!snapshot.exists) {
        throw repositoryFailure("operation-not-found");
      }
      const stored = snapshot.data() || {};
      let operation = normalizeOperation(stored);
      const isReplacementCleanup =
        operation.kind === "replacement" &&
        operation.phase === "sourceCleanupPending";
      if (operation.kind !== "deletion" && !isReplacementCleanup) {
        throw repositoryFailure("invalid-operation");
      }
      const markerRef = deletionMarkers.doc(operation.sourceUid);
      if (TERMINAL_PHASES.has(operation.phase)) {
        return { ...workerResult(stored), leaseAcquired: false };
      }
      const progress = workerProgress(stored);
      if (operation.phase === "appleRevocationPending" &&
          !progress.appleRevocationComplete &&
          allowAppleRevocationInput !== true) {
        return {
          ...workerResult(stored),
          leaseAcquired: false,
        };
      }
      const currentTime = nowMillis();
      const activeLease = stored.workerLease || {};
      if (Number.isFinite(activeLease.leaseUntilMillis) &&
          activeLease.leaseUntilMillis > currentTime) {
        throw repositoryFailure("worker-lease-held");
      }
      if (operation.phase === "deletionRequested") {
        operation = transitionOperation(operation, {
          toPhase: "userTreeDeleting",
          expectedVersion: operation.version,
        });
      }
      const leaseVersion = Number.isInteger(activeLease.leaseVersion)
        ? activeLease.leaseVersion + 1
        : 1;
      const updated = {
        ...persistedOperation(operation, stored, currentTime),
        deletionProgress: workerProgress(stored),
        workerLease: {
          workerId,
          leaseVersion,
          leaseUntilMillis: currentTime + leaseMillis,
        },
      };
      const markerSnapshot = await transaction.get(markerRef);
      transaction.set(operationRef, updated);
      transaction.set(markerRef, {
        ...(markerSnapshot.exists ? markerSnapshot.data() || {} : {}),
        state: "active",
        serverOwned: true,
        operationId,
        sourceUid: operation.sourceUid,
        createdAtMillis:
          (markerSnapshot.data() || {}).createdAtMillis || currentTime,
        updatedAtMillis: currentTime,
      });
      return { ...workerResult(updated), leaseAcquired: true };
    });
  }

  async function renewDeletionLease({
    operationId,
    workerId,
    operationVersion,
    leaseVersion,
    leaseMillis = DEFAULT_WORKER_LEASE_MILLIS,
  }) {
    const operationRef = operations.doc(requiredOperationId(operationId));
    return firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(operationRef);
      if (!snapshot.exists) {
        throw repositoryFailure("operation-not-found");
      }
      const stored = snapshot.data() || {};
      const operation = normalizeOperation(stored);
      const lease = stored.workerLease || {};
      const currentTime = nowMillis();
      if (operation.version !== operationVersion ||
          lease.workerId !== workerId ||
          lease.leaseVersion !== leaseVersion ||
          !Number.isFinite(lease.leaseUntilMillis) ||
          lease.leaseUntilMillis <= currentTime) {
        throw repositoryFailure("stale-worker-lease");
      }
      const updated = {
        ...stored,
        updatedAtMillis: currentTime,
        workerLease: {
          workerId,
          leaseVersion: leaseVersion + 1,
          leaseUntilMillis: currentTime + leaseMillis,
        },
      };
      transaction.set(operationRef, updated);
      return workerResult(updated);
    });
  }

  async function checkpointDeletionWork({
    operationId,
    workerId,
    operationVersion,
    leaseVersion,
    progress,
    toPhase,
  }) {
    const operationRef = operations.doc(requiredOperationId(operationId));
    return firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(operationRef);
      if (!snapshot.exists) {
        throw repositoryFailure("operation-not-found");
      }
      const stored = snapshot.data() || {};
      const current = normalizeOperation(stored);
      const markerRef = deletionMarkers.doc(current.sourceUid);
      const lease = stored.workerLease || {};
      const currentTime = nowMillis();
      if (current.version !== operationVersion ||
          lease.workerId !== workerId ||
          lease.leaseVersion !== leaseVersion ||
          !Number.isFinite(lease.leaseUntilMillis) ||
          lease.leaseUntilMillis <= currentTime) {
        throw repositoryFailure("stale-worker-lease");
      }
      const operation = toPhase
        ? transitionOperation(current, {
          toPhase,
          expectedVersion: current.version,
        })
        : current;
      const nextProgress = {
        ...workerProgress(stored),
        ...(progress || {}),
      };
      const marker = operation.phase === "completed"
        ? await transaction.get(markerRef)
        : null;
      const updated = {
        ...persistedOperation(operation, stored, currentTime),
        deletionProgress: nextProgress,
        workerLease: {
          workerId,
          leaseVersion: leaseVersion + 1,
          leaseUntilMillis: currentTime,
        },
      };
      transaction.set(operationRef, updated);
      if (operation.phase === "completed") {
        transaction.set(markerRef, {
          ...(marker?.exists ? marker.data() || {} : {}),
          state: "complete",
          serverOwned: true,
          operationId,
          sourceUid: operation.sourceUid,
          cleanupComplete: true,
          cleanupCompletedAtMillis: currentTime,
          updatedAtMillis: currentTime,
        });
      }
      return workerResult(updated);
    });
  }

  return Object.freeze({
    checkpointDeletionWork,
    cancelReplacement,
    claimDeletionByProof,
    claimDeletionWork,
    consumeAnonymousRequest,
    consumePublicProofRequest,
    createOrReuseDeletion: (request) =>
      createOrReuse(request, { deletionRequested: true }),
    createOrReuseReplacement: (request) => createOrReuse(request),
    get,
    issueDeletionProof,
    renewDeletionLease,
    transition,
  });
}

function legacyAccountTombstoneCleanupAction({
  marker,
  ...context
} = {}) {
  if (marker?.serverOwned === true &&
      typeof marker.operationId === "string" &&
      marker.operationId.length > 0) {
    return "retain";
  }
  return accountTombstoneCleanupAction(context);
}

function createDeletionWorkerRuntime({
  repository,
  auth,
  deleteUserTreePage,
  cleanupCommunity,
  cleanupProcessor,
  nowMillis = () => Date.now(),
  leaseMillis = DEFAULT_WORKER_LEASE_MILLIS,
  pageSize = DEFAULT_DELETE_PAGE_SIZE,
  newWorkerInvocationId = () => crypto.randomUUID(),
} = {}) {
  if (!repository ||
      typeof repository.claimDeletionWork !== "function" ||
      typeof repository.renewDeletionLease !== "function" ||
      typeof repository.checkpointDeletionWork !== "function") {
    throw new TypeError("A deletion-worker repository is required.");
  }
  if (!auth || typeof auth.deleteUser !== "function" ||
      typeof deleteUserTreePage !== "function" ||
      typeof cleanupCommunity !== "function" ||
      typeof cleanupProcessor !== "function" ||
      typeof newWorkerInvocationId !== "function") {
    throw new TypeError("Injected destructive worker adapters are required.");
  }

  async function processDeletionOperation({ operationId, workerId }) {
    const invocationWorkerId = stableKey(
      "deletion-worker-invocation",
      requiredString(workerId, "worker-id-required"),
      requiredString(
        newWorkerInvocationId(),
        "worker-invocation-id-required",
      ),
    );
    let claim = await repository.claimDeletionWork({
      operationId,
      workerId: invocationWorkerId,
      leaseMillis,
    });
    let operation = claim.operation;
    if (TERMINAL_PHASES.has(operation.phase)) {
      return operationResult(operation);
    }
    if (claim.leaseAcquired === false) {
      return operationResult(operation);
    }

    const renew = async () => {
      claim = await repository.renewDeletionLease({
        operationId,
        workerId: invocationWorkerId,
        operationVersion: operation.version,
        leaseVersion: claim.leaseVersion,
        leaseMillis,
      });
      operation = claim.operation;
      return claim;
    };
    const checkpoint = async (change) => {
      claim = await repository.checkpointDeletionWork({
        operationId,
        workerId: invocationWorkerId,
        operationVersion: operation.version,
        leaseVersion: claim.leaseVersion,
        ...change,
      });
      operation = claim.operation;
      return operationResult(operation);
    };

    if (operation.kind === "replacement" &&
        operation.phase === "sourceCleanupPending") {
      if (!claim.progress.userTreeComplete) {
        await renew();
        const page = await deleteUserTreePage({
          uid: operation.sourceUid,
          cursor: claim.progress.cursor,
          limit: pageSize,
          operationId,
        });
        if (!page || typeof page.done !== "boolean" ||
            (!page.done && typeof page.nextCursor !== "string")) {
          throw repositoryFailure("invalid-deletion-page");
        }
        return checkpoint({
          progress: {
            cursor: page.done ? null : page.nextCursor,
            userTreeComplete: page.done,
          },
        });
      }
      if (!claim.progress.authComplete) {
        await renew();
        try {
          await auth.deleteUser(operation.sourceUid);
        } catch (error) {
          if (error?.code !== "auth/user-not-found") throw error;
        }
        return checkpoint({ progress: { authComplete: true } });
      }
      if (!claim.progress.communityComplete) {
        await renew();
        await cleanupCommunity({
          uid: operation.sourceUid,
          operationId,
        });
        return checkpoint({ progress: { communityComplete: true } });
      }
      await renew();
      await cleanupProcessor({
        uid: operation.sourceUid,
        operationId,
      });
      return checkpoint({
        progress: { processorComplete: true },
        toPhase: "completed",
      });
    }

    if (operation.phase === "userTreeDeleting") {
      if (!claim.progress.userTreeComplete) {
        await renew();
        const page = await deleteUserTreePage({
          uid: operation.sourceUid,
          cursor: claim.progress.cursor,
          limit: pageSize,
          operationId,
        });
        if (!page || typeof page.done !== "boolean" ||
            (!page.done && typeof page.nextCursor !== "string")) {
          throw repositoryFailure("invalid-deletion-page");
        }
        return checkpoint({
          progress: {
            cursor: page.done ? null : page.nextCursor,
            userTreeComplete: page.done,
          },
        });
      }
      if (operation.appleRevocationRequired) {
        return checkpoint({ toPhase: "appleRevocationPending" });
      }
      await renew();
      try {
        await auth.deleteUser(operation.sourceUid);
      } catch (error) {
        if (error?.code !== "auth/user-not-found") throw error;
      }
      return checkpoint({ toPhase: "authDeleted" });
    }

    if (operation.phase === "authDeleted") {
      return checkpoint({ toPhase: "communityCleanupPending" });
    }

    if (operation.phase === "appleRevocationPending") {
      if (claim.progress.appleRevocationComplete) {
        await renew();
        try {
          await auth.deleteUser(operation.sourceUid);
        } catch (error) {
          if (error?.code !== "auth/user-not-found") throw error;
        }
        return checkpoint({ toPhase: "authDeleted" });
      }
      return operationResult(operation);
    }

    if (operation.phase === "communityCleanupPending") {
      await renew();
      await cleanupCommunity({
        uid: operation.sourceUid,
        operationId,
      });
      return checkpoint({ toPhase: "processorCleanupPending" });
    }

    if (operation.phase === "processorCleanupPending") {
      await renew();
      await cleanupProcessor({
        uid: operation.sourceUid,
        operationId,
      });
      return checkpoint({ toPhase: "completed" });
    }

    return operationResult(operation);
  }

  return Object.freeze({ processDeletionOperation });
}

function authorizationHeader(request) {
  const headers = request?.rawRequest?.headers;
  const header = headers?.authorization ??
    request?.rawRequest?.get?.("authorization");
  if (typeof header !== "string") return null;
  const match = /^Bearer ([^\s]+)$/i.exec(header);
  return match ? match[1] : null;
}

function isAnonymousToken(decoded) {
  return decoded?.firebase?.sign_in_provider === "anonymous";
}

function hasAppleIdentity(decoded) {
  return decoded?.firebase?.sign_in_provider === "apple.com" ||
    Array.isArray(decoded?.firebase?.identities?.["apple.com"]);
}

function operationFailureMapping(code) {
  switch (code) {
    case "operation-not-found":
      return ["not-found", code];
    case "operation-not-authorized":
      return ["permission-denied", code];
    case "anonymous-rate-limit-exceeded":
    case "proof-issuance-rate-exceeded":
      return ["resource-exhausted", code];
    case "stale-operation-version":
      return ["aborted", code];
    case "operation-in-progress":
    case "terminal-operation":
    case "invalid-operation-transition":
      return ["failed-precondition", code];
    case "invalid-operation":
    case "source-and-target-must-differ":
      return ["invalid-argument", code];
    default:
      return ["internal", "account-operation-failed"];
  }
}

function createAccountOperationRuntime({
  auth,
  repository,
  nowMillis = () => Date.now(),
  newDeletionProof = () => crypto.randomBytes(32).toString("base64url"),
  newWorkerInvocationId = () => crypto.randomUUID(),
  hashDeletionProof,
  revokeAppleAuthorizationCode,
  makeError,
} = {}) {
  if (!auth || typeof auth.verifyIdToken !== "function" ||
      typeof auth.deleteUser !== "function") {
    throw new TypeError("A Firebase Auth verifier is required.");
  }
  if (!repository ||
      typeof repository.consumeAnonymousRequest !== "function" ||
      typeof repository.createOrReuseReplacement !== "function" ||
      typeof repository.createOrReuseDeletion !== "function" ||
      typeof repository.issueDeletionProof !== "function" ||
      typeof repository.claimDeletionWork !== "function" ||
      typeof repository.renewDeletionLease !== "function" ||
      typeof repository.checkpointDeletionWork !== "function" ||
      typeof repository.cancelReplacement !== "function" ||
      typeof repository.transition !== "function" ||
      typeof repository.get !== "function") {
    throw new TypeError("An account-operation repository is required.");
  }
  if (typeof newDeletionProof !== "function" ||
      typeof newWorkerInvocationId !== "function" ||
      typeof hashDeletionProof !== "function" ||
      typeof revokeAppleAuthorizationCode !== "function") {
    throw new TypeError("Deletion-proof crypto adapters are required.");
  }
  if (typeof makeError !== "function") {
    throw new TypeError("A safe callable error adapter is required.");
  }

  async function authenticate(request, requiredAccountType = "any") {
    if (!request?.app || typeof request.app.appId !== "string") {
      throw new BoundaryFailure("failed-precondition", "app-check-required");
    }
    if (request.app.alreadyConsumed === true) {
      throw new BoundaryFailure(
        "resource-exhausted",
        "app-check-token-consumed",
      );
    }
    const token = authorizationHeader(request);
    if (!token) {
      throw new BoundaryFailure(
        "unauthenticated",
        "authentication-required",
      );
    }

    let decoded;
    try {
      decoded = await auth.verifyIdToken(token, true);
    } catch {
      throw new BoundaryFailure("unauthenticated", "invalid-auth-token");
    }
    const uid = decoded?.uid;
    if (typeof uid !== "string" || uid.length === 0) {
      throw new BoundaryFailure("unauthenticated", "invalid-auth-token");
    }

    const anonymous = isAnonymousToken(decoded);
    if (requiredAccountType === "anonymous" && !anonymous) {
      throw new BoundaryFailure(
        "failed-precondition",
        "anonymous-account-required",
      );
    }
    if (requiredAccountType === "connected" && anonymous) {
      throw new BoundaryFailure(
        "failed-precondition",
        "connected-account-required",
      );
    }

    const claimTime = anonymous ? decoded.iat : decoded.auth_time;
    const nowSeconds = Math.floor(nowMillis() / 1000);
    if (!Number.isFinite(claimTime) ||
        claimTime > nowSeconds ||
        nowSeconds - claimTime > AUTH_MAX_AGE_SECONDS) {
      throw new BoundaryFailure(
        "failed-precondition",
        anonymous
          ? "fresh-anonymous-token-required"
          : "recent-authentication-required",
      );
    }
    if (anonymous) {
      await repository.consumeAnonymousRequest({
        uid,
        appId: request.app.appId,
      });
    }
    return { decoded, uid };
  }

  async function execute(callback) {
    try {
      return await callback();
    } catch (error) {
      if (error instanceof BoundaryFailure) {
        throw makeError(error.status, error.safeCode);
      }
      const [status, safeCode] = operationFailureMapping(error?.code);
      throw makeError(status, safeCode);
    }
  }

  const handlers = {
    prepareAnonymousReplacement: (request) => execute(async () => {
      const identity = await authenticate(request, "anonymous");
      const data = request.data || {};
      const requestKey = requiredString(
        data.requestKey,
        "request-key-required",
      );
      const operation = await repository.createOrReuseReplacement({
        kind: "replacement",
        sourceUid: identity.uid,
        targetUid: requiredString(data.targetUid, "target-uid-required"),
        requestKey: stableKey(
          "operation-request",
          identity.uid,
          "replacement",
          requestKey,
        ),
      });
      return operationResult(operation);
    }),

    attachReplacementTarget: (request) => execute(async () => {
      const identity = await authenticate(request, "connected");
      const data = request.data || {};
      const operation = await repository.transition({
        operationId: requiredOperationId(data.operationId),
        actorUid: identity.uid,
        role: "target",
        expectedVersion: requiredExpectedVersion(data.expectedVersion),
        toPhase: "targetVerified",
      });
      return operationResult(operation);
    }),

    commitReplacementReconciliation: (request) => execute(async () => {
      const identity = await authenticate(request, "connected");
      const data = request.data || {};
      const operation = await repository.transition({
        operationId: requiredOperationId(data.operationId),
        actorUid: identity.uid,
        role: "target",
        expectedVersion: requiredExpectedVersion(data.expectedVersion),
        toPhase: "reconciling",
      });
      return operationResult(operation);
    }),

    startSourceCleanup: (request) => execute(async () => {
      const identity = await authenticate(request, "connected");
      const data = request.data || {};
      const operation = await repository.transition({
        operationId: requiredOperationId(data.operationId),
        actorUid: identity.uid,
        role: "target",
        expectedVersion: requiredExpectedVersion(data.expectedVersion),
        toPhase: "sourceCleanupPending",
      });
      return operationResult(operation);
    }),

    cancelAnonymousReplacement: (request) => execute(async () => {
      const identity = await authenticate(request, "anonymous");
      const data = request.data || {};
      const operation = await repository.cancelReplacement({
        operationId: requiredOperationId(data.operationId),
        actorUid: identity.uid,
        expectedVersion: requiredExpectedVersion(data.expectedVersion),
      });
      return operationResult(operation);
    }),

    requestAccountDeletion: (request) => execute(async () => {
      const identity = await authenticate(request);
      const data = request.data || {};
      const requestKey = requiredString(
        data.requestKey,
        "request-key-required",
      );
      const operation = await repository.createOrReuseDeletion({
        kind: "deletion",
        sourceUid: identity.uid,
        requestKey: stableKey(
          "operation-request",
          identity.uid,
          "deletion",
          requestKey,
        ),
        appleRevocationRequired: hasAppleIdentity(identity.decoded),
      });
      return operationResult(operation);
    }),

    issueDeletionProof: (request) => execute(async () => {
      const identity = await authenticate(request);
      const proof = newDeletionProof();
      if (!isRawDeletionProof(proof)) {
        throw repositoryFailure("invalid-deletion-proof");
      }
      const proofHash = requiredProofHash(await hashDeletionProof(proof));
      const issuance = await repository.issueDeletionProof({
        sourceUid: identity.uid,
        proofHash,
        appleRevocationRequired: hasAppleIdentity(identity.decoded),
      });
      return {
        proof,
        expiresAtMillis: issuance.expiresAtMillis,
      };
    }),

    completeAppleRevocation: (request) => execute(async () => {
      const identity = await authenticate(request, "connected");
      const data = request.data || {};
      const operationId = requiredOperationId(data.operationId);
      const expectedVersion =
        requiredExpectedVersion(data.expectedVersion);
      const authorizationCode = requiredString(
        data.authorizationCode,
        "apple-authorization-code-required",
      );
      const visible = await repository.get({
        operationId,
        actorUid: identity.uid,
      });
      if (visible.kind !== "deletion" ||
          visible.appleRevocationRequired !== true) {
        throw repositoryFailure("invalid-operation");
      }
      if ([
        "authDeleted",
        "communityCleanupPending",
        "processorCleanupPending",
        "completed",
      ].includes(visible.phase)) {
        return operationResult(visible);
      }
      if (visible.phase !== "appleRevocationPending" ||
          visible.version !== expectedVersion) {
        throw repositoryFailure("stale-operation-version");
      }

      const workerId = stableKey(
        "apple-revocation-worker",
        operationId,
        identity.uid,
        requiredString(
          newWorkerInvocationId(),
          "worker-invocation-id-required",
        ),
      );
      let claim = await repository.claimDeletionWork({
        operationId,
        workerId,
        leaseMillis: DEFAULT_WORKER_LEASE_MILLIS,
        allowAppleRevocationInput: true,
      });
      let operation = claim.operation;
      if (operation.version !== expectedVersion ||
          operation.phase !== "appleRevocationPending") {
        throw repositoryFailure("stale-operation-version");
      }
      const renew = async () => {
        claim = await repository.renewDeletionLease({
          operationId,
          workerId,
          operationVersion: operation.version,
          leaseVersion: claim.leaseVersion,
          leaseMillis: DEFAULT_WORKER_LEASE_MILLIS,
        });
        operation = claim.operation;
      };
      const checkpoint = async (change) => {
        claim = await repository.checkpointDeletionWork({
          operationId,
          workerId,
          operationVersion: operation.version,
          leaseVersion: claim.leaseVersion,
          ...change,
        });
        operation = claim.operation;
      };

      if (!claim.progress.appleRevocationComplete) {
        await renew();
        try {
          await revokeAppleAuthorizationCode({
            authorizationCode,
            uid: identity.uid,
          });
        } catch {
          await checkpoint({
            progress: { statusCode: "apple-revocation-retryable" },
          });
          throw repositoryFailure("apple-revocation-pending");
        }
        await checkpoint({
          progress: {
            appleRevocationComplete: true,
            statusCode: null,
          },
        });
        claim = await repository.claimDeletionWork({
          operationId,
          workerId,
          leaseMillis: DEFAULT_WORKER_LEASE_MILLIS,
          allowAppleRevocationInput: true,
        });
        operation = claim.operation;
      }

      await renew();
      try {
        await auth.deleteUser(identity.uid);
      } catch (error) {
        if (error?.code !== "auth/user-not-found") throw error;
      }
      await checkpoint({ toPhase: "authDeleted" });
      return operationResult(operation);
    }),

    getAccountOperation: (request) => execute(async () => {
      const identity = await authenticate(request);
      const data = request.data || {};
      const operation = await repository.get({
        operationId: requiredOperationId(data.operationId),
        actorUid: identity.uid,
      });
      return operationResult(operation);
    }),
  };
  return Object.freeze(handlers);
}

function requestHeader(request, name) {
  const lowerName = name.toLowerCase();
  const value = request?.headers?.[lowerName] ?? request?.get?.(name);
  return typeof value === "string" ? value : null;
}

function requestBodyBytes(request) {
  if (Buffer.isBuffer(request?.rawBody)) return request.rawBody.length;
  try {
    return Buffer.byteLength(JSON.stringify(request?.body ?? null), "utf8");
  } catch {
    return PUBLIC_REQUEST_MAX_BYTES + 1;
  }
}

function hasQueryParameters(request) {
  return request?.query &&
    typeof request.query === "object" &&
    Object.keys(request.query).length > 0;
}

function createDeletionProofHttpHandler({
  repository,
  hashDeletionProof,
  getRateLimitKey = async (request) => stableKey(
    "public-deletion-proof-rate",
    typeof request?.ip === "string" ? request.ip : "unknown",
  ),
  consumeRateLimit,
  logger = { warn() {} },
} = {}) {
  if (!repository ||
      typeof repository.claimDeletionByProof !== "function") {
    throw new TypeError("A deletion-proof repository is required.");
  }
  if (typeof hashDeletionProof !== "function" ||
      typeof getRateLimitKey !== "function" ||
      typeof consumeRateLimit !== "function") {
    throw new TypeError("Public proof boundary adapters are required.");
  }
  if (!logger || typeof logger.warn !== "function") {
    throw new TypeError("A safe logger adapter is required.");
  }

  return async function requestDeletionByProof(request, response) {
    response.set("Cache-Control", "no-store");
    response.set("Referrer-Policy", "no-referrer");
    response.set("X-Content-Type-Options", "nosniff");
    const origin = requestHeader(request, "origin");
    if (origin !== FIRST_PARTY_ORIGIN) {
      response.status(403).json(GENERIC_PUBLIC_RESULT);
      return;
    }
    response.set("Access-Control-Allow-Origin", FIRST_PARTY_ORIGIN);
    response.set("Vary", "Origin");
    if (request?.method !== "POST") {
      response.status(405).json(GENERIC_PUBLIC_RESULT);
      return;
    }
    const contentType = requestHeader(request, "content-type");
    if (!contentType ||
        !/^application\/json(?:\s*;\s*charset=utf-8)?$/i.test(contentType)) {
      response.status(415).json(GENERIC_PUBLIC_RESULT);
      return;
    }
    if (hasQueryParameters(request)) {
      response.status(400).json(GENERIC_PUBLIC_RESULT);
      return;
    }
    const contentLength = requestHeader(request, "content-length");
    if (contentLength !== null &&
        (!/^\d+$/.test(contentLength) ||
         Number(contentLength) > PUBLIC_REQUEST_MAX_BYTES)) {
      response.status(413).json(GENERIC_PUBLIC_RESULT);
      return;
    }
    if (requestBodyBytes(request) > PUBLIC_REQUEST_MAX_BYTES) {
      response.status(413).json(GENERIC_PUBLIC_RESULT);
      return;
    }

    const body = request?.body;
    const bodyKeys = body && typeof body === "object" && !Array.isArray(body)
      ? Object.keys(body)
      : [];
    const proof = bodyKeys.length === 1 && bodyKeys[0] === "proof"
      ? body.proof
      : null;
    try {
      const rateLimitKey = requiredProofHash(
        await getRateLimitKey(request),
      );
      const permitted = await consumeRateLimit({
        key: rateLimitKey,
        origin,
      });
      if (permitted !== true) {
        response.status(429).json(GENERIC_PUBLIC_RESULT);
        return;
      }
      if (!isRawDeletionProof(proof)) {
        response.status(202).json(GENERIC_PUBLIC_RESULT);
        return;
      }
      const proofHash = requiredProofHash(await hashDeletionProof(proof));
      await repository.claimDeletionByProof({ proofHash });
    } catch {
      logger.warn("deletion-proof-request-failed", {
        code: "proof-request-failed",
      });
    }
    response.status(202).json(GENERIC_PUBLIC_RESULT);
  };
}

function createDeletionProofHttpEndpoint({
  handler,
  onRequest,
  options = {},
} = {}) {
  if (typeof handler !== "function" || typeof onRequest !== "function") {
    throw new TypeError("HTTP handler and onRequest adapter are required.");
  }
  return onRequest(
    { ...PUBLIC_ENDPOINT_OPTIONS, ...options },
    handler,
  );
}

function createAccountOperationCallables({
  handlers,
  onCall,
  optionsByName = {},
} = {}) {
  if (!handlers || typeof onCall !== "function") {
    throw new TypeError("Callable handlers and an onCall adapter are required.");
  }
  return Object.fromEntries(CALLABLE_NAMES.map((name) => {
    if (typeof handlers[name] !== "function") {
      throw new TypeError(`Missing callable handler: ${name}`);
    }
    return [
      name,
      onCall(
        { ...CALLABLE_OPTIONS, ...(optionsByName[name] || {}) },
        handlers[name],
      ),
    ];
  }));
}

module.exports = {
  ACTIONABLE_DELETION_PHASES,
  CALLABLE_NAMES,
  CALLABLE_OPTIONS,
  FIRST_PARTY_ORIGIN,
  PUBLIC_ENDPOINT_OPTIONS,
  createAccountOperationCallables,
  createAccountOperationRuntime,
  createDeletionWorkerRuntime,
  createDeletionProofHttpEndpoint,
  createDeletionProofHttpHandler,
  createFirestoreAccountOperationRepository,
  createKeyedDeletionProofDigest,
  fetchActionableDeletionCandidates,
  legacyAccountTombstoneCleanupAction,
};
