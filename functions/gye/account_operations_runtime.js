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
  "getAccountDeletionStatusByReceipt",
  "acknowledgeAccountDeletionStatusReceipt",
]);
// App Check is advisory on the account callables (2026-08-10): enforced
// attestation stranded durable deletion/replacement journals forever on
// devices whose provider was never registered (Play Integrity gap), locking
// the whole account UI. Fresh verified auth remains mandatory for mutations;
// post-Auth-deletion status and acknowledgement use a dedicated 256-bit
// read capability whose raw value is never persisted.
const CALLABLE_OPTIONS = Object.freeze({
  region: "europe-west3",
  enforceAppCheck: false,
});
const NORMAL_DELETION_PHASES = Object.freeze([
  "deletionRequested",
  "userTreeDeleting",
  "authDeleted",
  "communityCleanupPending",
  "processorCleanupPending",
]);
const ACTIONABLE_DELETION_PHASES = Object.freeze([
  "sourceCleanupPending",
  ...NORMAL_DELETION_PHASES,
]);
// Phases at which completeAppleRevocation may accept a revocation before the
// scheduled worker has advanced the operation to appleRevocationPending
// (TN-2026-09-05 T3): Apple authorization codes expire in ~5 minutes, well
// before the worker's multi-tick schedule would otherwise reach that phase.
const EARLY_APPLE_REVOCATION_PHASES = new Set([
  "deletionRequested",
  "userTreeDeleting",
]);
const TERMINAL_PHASES = new Set(["completed", "blocked", "cancelled"]);
const AUTH_MAX_AGE_SECONDS = 300;
const ANONYMOUS_RATE_WINDOW_MILLIS = 300_000;
const ANONYMOUS_RATE_LIMIT = 20;
const DELETION_PROOF_LIFETIME_MILLIS = 86_400_000;
const DELETION_PROOF_ISSUANCE_WINDOW_MILLIS = 86_400_000;
const DELETION_PROOF_ISSUANCE_LIMIT = 3;
const DELETION_PROOF_PURPOSE = "account-deletion-public-proof-v1";
const DELETION_STATUS_RECEIPT_PURPOSE =
  "account-deletion-status-receipt-v1";
const DELETION_CAPABILITY_PURPOSE_DOMAIN =
  "account-deletion-capability-purpose-v1";
const ACKNOWLEDGED_RECEIPT_RETENTION_MILLIS = 7 * 86_400_000;
const DELETION_STATUS_RATE_WINDOW_MILLIS = 300_000;
const DELETION_STATUS_RATE_LIMIT = 120;
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
const DEFAULT_WORKER_RETRY_DELAY_MILLIS = 60_000;
const MAX_WORKER_RETRY_DELAY_MILLIS = 3_600_000;
const DEFAULT_DELETE_PAGE_SIZE = 200;
const DEFAULT_DESTRUCTIVE_UNIT_TIMEOUT_MILLIS = 45_000;
const SCHEDULE_TIMEOUT_SECONDS = 300;
const SCHEDULE_WORKER_DEADLINE_MILLIS = 240_000;
const QUEUE_BUDGETS = Object.freeze({
  replacement: 20,
  deletion: 20,
  apple: 10,
});
const DELETION_SCHEDULER_MIGRATION_ID =
  "deletion-scheduler-next-at-v1";
const SAFE_DELETION_WORK_FAILURE_CODES = new Set(["worker-failed"]);

function scaleQueueBudgets(limit) {
  const names = Object.keys(QUEUE_BUDGETS);
  const totalWeight = Object.values(QUEUE_BUDGETS)
    .reduce((total, weight) => total + weight, 0);
  const minimum = limit >= names.length ? 1 : 0;
  const budgets = Object.fromEntries(
    names.map((name) => [name, minimum]),
  );
  let remaining = limit - (minimum * names.length);
  const shares = names.map((name, index) => {
    const exact = remaining * QUEUE_BUDGETS[name] / totalWeight;
    const whole = Math.floor(exact);
    budgets[name] += whole;
    return { name, index, remainder: exact - whole };
  });
  remaining = limit - Object.values(budgets)
    .reduce((total, budget) => total + budget, 0);
  shares
    .sort((left, right) =>
      right.remainder - left.remainder || left.index - right.index)
    .slice(0, remaining)
    .forEach(({ name }) => {
      budgets[name] += 1;
    });
  return budgets;
}

function dedupeCandidates(candidates) {
  const seen = new Set();
  return candidates.filter((candidate) => {
    if (!candidate || typeof candidate.id !== "string" ||
        seen.has(candidate.id)) {
      return false;
    }
    seen.add(candidate.id);
    return true;
  });
}

function interleaveCandidateQueues(queues) {
  const result = [];
  const largestQueue = Math.max(0, ...queues.map((queue) => queue.length));
  for (let index = 0; index < largestQueue; index += 1) {
    for (const queue of queues) {
      if (queue[index]) result.push(queue[index]);
    }
  }
  return result;
}

async function fetchActionableDeletionCandidates({
  collection,
  limit = 50,
  nowMillis,
} = {}) {
  if (!collection || typeof collection.where !== "function") {
    throw new TypeError("Account operation collection is required.");
  }
  if (!Number.isInteger(limit) || limit < 1) {
    throw new TypeError("Candidate limit must be a positive integer.");
  }
  if (!Number.isFinite(nowMillis) || nowMillis < 0) {
    throw new TypeError("Candidate time must be a non-negative number.");
  }
  const budget = scaleQueueBudgets(limit);
  const getSnapshot = (query, queryLimit) => queryLimit > 0
    ? query.limit(queryLimit).get()
    : Promise.resolve({ docs: [] });
  const [replacement, deletion, apple] = await Promise.all([
    getSnapshot(
      collection
        .where("kind", "==", "replacement")
        .where("phase", "==", "sourceCleanupPending")
        .where("nextAttemptAtMillis", "<=", nowMillis)
        .orderBy("nextAttemptAtMillis")
        .orderBy("updatedAtMillis"),
      budget.replacement,
    ),
    getSnapshot(
      collection
        .where("kind", "==", "deletion")
        .where("phase", "in", NORMAL_DELETION_PHASES)
        .where("nextAttemptAtMillis", "<=", nowMillis)
        .orderBy("nextAttemptAtMillis")
        .orderBy("updatedAtMillis"),
      budget.deletion,
    ),
    getSnapshot(
      collection
        .where("phase", "==", "appleRevocationPending")
        .where("deletionProgress.appleRevocationComplete", "==", true)
        .where("nextAttemptAtMillis", "<=", nowMillis)
        .orderBy("nextAttemptAtMillis")
        .orderBy("updatedAtMillis"),
      budget.apple,
    ),
  ]);
  const docs = (snapshot) => Array.isArray(snapshot?.docs)
    ? snapshot.docs
    : [];
  return dedupeCandidates(interleaveCandidateQueues([
    docs(replacement),
    docs(deletion),
    docs(apple),
  ]));
}

async function fetchStagedActionableDeletionCandidates({
  repository,
  collection,
  limit = 50,
  legacyBackfillLimit = 50,
  nowMillis,
} = {}) {
  if (!repository ||
      typeof repository.backfillLegacyDeletionSchedule !== "function") {
    throw new TypeError("Account operation repository is required.");
  }
  await repository.backfillLegacyDeletionSchedule({
    limit: legacyBackfillLimit,
    nowMillis,
  });
  return fetchActionableDeletionCandidates({
    collection,
    limit,
    nowMillis,
  });
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

class DeletionWorkerFailure extends Error {
  constructor(retryMetadata, { failureRecorded = false } = {}) {
    super("deletion-worker-failed");
    this.code = "worker-failed";
    this.retryMetadata = Object.freeze({ ...retryMetadata });
    this.failureRecorded = failureRecorded;
  }
}

function workerRetryDelayMillis(leaseVersion) {
  const exponent = Math.min(Math.max(leaseVersion - 1, 0), 10);
  return Math.min(
    DEFAULT_WORKER_RETRY_DELAY_MILLIS * (2 ** exponent),
    MAX_WORKER_RETRY_DELAY_MILLIS,
  );
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

function isRawDeletionStatusReceipt(value) {
  return isRawDeletionProof(value);
}

function requiredProofHash(value) {
  if (typeof value !== "string" ||
      !/^[A-Za-z0-9_-]{16,256}$/.test(value)) {
    throw repositoryFailure("invalid-deletion-proof-hash");
  }
  return value;
}

function requiredSha256Digest(value, safeCode) {
  if (typeof value !== "string" || !/^[0-9a-f]{64}$/.test(value)) {
    throw repositoryFailure(safeCode);
  }
  return value;
}

function requiredDeletionStatusReceiptDigest(value) {
  return requiredSha256Digest(
    value,
    "invalid-deletion-status-receipt-digest",
  );
}

function requiredDeletionCapabilityPurposeDigest(value) {
  return requiredSha256Digest(
    value,
    "invalid-deletion-capability-purpose-digest",
  );
}

function requiredDeletionStatusRateLimitKey(value) {
  return requiredSha256Digest(
    value,
    "invalid-deletion-status-rate-limit-key",
  );
}

function domainSeparatedSha256(domain, value) {
  if (typeof value !== "string") {
    throw new TypeError("A deletion capability string is required.");
  }
  return crypto
    .createHash("sha256")
    .update(`${domain}\u0000${value}`, "utf8")
    .digest("hex");
}

function deletionStatusReceiptDigest(receipt) {
  return domainSeparatedSha256(DELETION_STATUS_RECEIPT_PURPOSE, receipt);
}

function deletionCapabilityPurposeDigest(capability) {
  return domainSeparatedSha256(
    DELETION_CAPABILITY_PURPOSE_DOMAIN,
    capability,
  );
}

function timestampMillis(value) {
  if (value instanceof Date) return value.getTime();
  if (value && typeof value.toMillis === "function") {
    try {
      return value.toMillis();
    } catch {
      return NaN;
    }
  }
  return NaN;
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
    nextAttemptAtMillis: nowMillis,
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
  timestampFromMillis = (millis) => new Date(millis),
} = {}) {
  if (!firestore || typeof firestore.runTransaction !== "function") {
    throw new TypeError("A Firestore transaction adapter is required.");
  }
  if (typeof timestampFromMillis !== "function") {
    throw new TypeError("A Firestore timestamp adapter is required.");
  }

  const operations = firestore.collection("account_operations");
  const owners = firestore.collection("account_operation_owners");
  const requests = firestore.collection("account_operation_requests");
  const rateLimits = firestore.collection("account_operation_rate_limits");
  const deletionProofs = firestore.collection("account_deletion_proofs");
  const deletionProofOwners =
    firestore.collection("account_deletion_proof_owners");
  const deletionStatusReceipts =
    firestore.collection("account_deletion_status_receipts");
  const deletionCapabilityPurposes =
    firestore.collection("account_deletion_capability_purposes");
  const deletionStatusRateLimits =
    firestore.collection("account_deletion_status_rate_limits");
  const publicRateLimits =
    firestore.collection("account_deletion_proof_rate_limits");
  const deletionMarkers = firestore.collection("account_deletions");
  const schedulerMigrations =
    firestore.collection("account_operation_migrations");

  async function backfillLegacyDeletionSchedule({
    limit = 50,
    nowMillis: migrationTimeMillis,
  } = {}) {
    if (!Number.isInteger(limit) || limit < 1 || limit > 500) {
      throw repositoryFailure("invalid-migration-limit");
    }
    if (!Number.isFinite(migrationTimeMillis) ||
        migrationTimeMillis < 0) {
      throw repositoryFailure("invalid-migration-time");
    }
    const migrationRef =
      schedulerMigrations.doc(DELETION_SCHEDULER_MIGRATION_ID);
    return firestore.runTransaction(async (transaction) => {
      const migrationSnapshot = await transaction.get(migrationRef);
      const migration = migrationSnapshot.exists
        ? migrationSnapshot.data() || {}
        : {};
      if (migration.complete === true) {
        return { complete: true, backfilled: 0 };
      }

      let query = operations.orderBy("__name__");
      if (typeof migration.cursor === "string" &&
          migration.cursor.length > 0) {
        query = query.startAfter(migration.cursor);
      }
      const snapshot = await transaction.get(query.limit(limit + 1));
      const documents = Array.isArray(snapshot?.docs)
        ? snapshot.docs
        : [];
      const page = documents.slice(0, limit);
      let backfilled = 0;
      for (const document of page) {
        const stored = document.data() || {};
        if (!TERMINAL_PHASES.has(stored.phase) &&
            !Number.isFinite(stored.nextAttemptAtMillis)) {
          transaction.set(document.ref, {
            ...stored,
            nextAttemptAtMillis: migrationTimeMillis,
          });
          backfilled += 1;
        }
      }

      const complete = documents.length <= limit;
      const cursor = complete ? null : page.at(-1)?.id;
      transaction.set(migrationRef, {
        complete,
        cursor: typeof cursor === "string" ? cursor : null,
        backfilledCount:
          (Number.isInteger(migration.backfilledCount)
            ? migration.backfilledCount
            : 0) + backfilled,
        updatedAtMillis: migrationTimeMillis,
      });
      return { complete, backfilled };
    });
  }

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

  function receiptBindingUnavailable() {
    throw repositoryFailure("terminal-status-receipt-invalid");
  }

  function receiptBindingMatches(stored, {
    receiptDigest,
    capabilityPurposeDigest,
    sourceUid,
    operationId,
    requestKeyHash,
  }) {
    return stored?.purpose === DELETION_STATUS_RECEIPT_PURPOSE &&
      stored?.receiptDigest === receiptDigest &&
      stored?.capabilityPurposeDigest === capabilityPurposeDigest &&
      stored?.state === "active" &&
      stored?.sourceUid === sourceUid &&
      stored?.operationId === operationId &&
      stored?.requestKeyHash === requestKeyHash &&
      Number.isFinite(stored?.boundAtMillis) &&
      typeof receiptDigest === "string";
  }

  function receiptBindingDocument({
    receiptDigest,
    capabilityPurposeDigest,
    sourceUid,
    operationId,
    requestKeyHash,
    boundAtMillis,
  }) {
    return {
      purpose: DELETION_STATUS_RECEIPT_PURPOSE,
      receiptDigest,
      capabilityPurposeDigest,
      state: "active",
      sourceUid,
      operationId,
      requestKeyHash,
      boundAtMillis,
    };
  }

  function shouldCreateReceiptBinding({
    receiptDigest,
    capabilityPurposeDigest,
    receiptSnapshot,
    purposeSnapshot,
    requestRecord,
    ownerRecord,
    operation,
    request,
    operationIsNew = false,
  }) {
    if (!receiptDigest) return false;
    const mappedReceiptDigest = typeof requestRecord
      ?.terminalStatusReceiptDigest === "string"
      ? requestRecord.terminalStatusReceiptDigest
      : null;
    const ownerReceiptDigest = ownerRecord?.operationId === operation.id &&
      typeof ownerRecord.terminalStatusReceiptDigest === "string"
      ? ownerRecord.terminalStatusReceiptDigest
      : null;
    if (purposeSnapshot?.exists) {
      const purposeRecord = purposeSnapshot.data() || {};
      if (purposeRecord.purpose !== DELETION_STATUS_RECEIPT_PURPOSE ||
          purposeRecord.capabilityPurposeDigest !==
            capabilityPurposeDigest ||
          purposeRecord.receiptDigest !== receiptDigest ||
          purposeRecord.state !== "active") {
        receiptBindingUnavailable();
      }
    }
    if (receiptSnapshot?.exists) {
      const existingBinding = receiptSnapshot.data() || {};
      if (requestRecord &&
          mappedReceiptDigest === receiptDigest &&
          purposeSnapshot?.exists &&
          receiptBindingMatches(existingBinding, {
            receiptDigest,
            capabilityPurposeDigest,
            sourceUid: request.sourceUid,
            operationId: operation.id,
            requestKeyHash: request.requestKey,
          })) {
        return false;
      }
      receiptBindingUnavailable();
    }
    if (mappedReceiptDigest || ownerReceiptDigest ||
        (!operationIsNew && ownerRecord?.operationId !== operation.id) ||
        operation.requestKey !== request.requestKey) {
      receiptBindingUnavailable();
    }
    return true;
  }

  async function createOrReuse(request, {
    deletionRequested = false,
    terminalStatusReceiptDigest = null,
    terminalStatusReceiptPurposeDigest = null,
  } = {}) {
    const receiptDigest = terminalStatusReceiptDigest === null
      ? null
      : requiredDeletionStatusReceiptDigest(terminalStatusReceiptDigest);
    const capabilityPurposeDigest = terminalStatusReceiptPurposeDigest === null
      ? null
      : requiredDeletionCapabilityPurposeDigest(
        terminalStatusReceiptPurposeDigest,
      );
    if ((receiptDigest === null) !== (capabilityPurposeDigest === null)) {
      throw repositoryFailure("terminal-status-receipt-invalid");
    }
    if (receiptDigest && !deletionRequested) {
      throw repositoryFailure("invalid-operation");
    }
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
    const receiptRef = receiptDigest
      ? deletionStatusReceipts.doc(receiptDigest)
      : null;
    const purposeRef = capabilityPurposeDigest
      ? deletionCapabilityPurposes.doc(capabilityPurposeDigest)
      : null;
    return firestore.runTransaction(async (transaction) => {
      const requestSnapshot = await transaction.get(requestRef);
      const receiptSnapshot = receiptRef
        ? await transaction.get(receiptRef)
        : null;
      const purposeSnapshot = purposeRef
        ? await transaction.get(purposeRef)
        : null;
      const ownerSnapshot = await transaction.get(ownerRef);
      const ownerRecord = ownerSnapshot.exists
        ? ownerSnapshot.data() || {}
        : {};
      if (requestSnapshot.exists) {
        const requestRecord = requestSnapshot.data() || {};
        const mappedOperationId = requestRecord.operationId;
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
        const createReceiptBinding = shouldCreateReceiptBinding({
          receiptDigest,
          capabilityPurposeDigest,
          receiptSnapshot,
          purposeSnapshot,
          requestRecord,
          ownerRecord,
          operation,
          request,
        });
        let operationChanged = false;
        if (deletionRequested && operation.phase === "prepared") {
          operation = transitionOperation(operation, {
            toPhase: "deletionRequested",
            expectedVersion: operation.version,
          });
          operationChanged = true;
        }
        const currentTime = nowMillis();
        if (operationChanged) {
          transaction.set(mappedRef, persistedOperation(
            operation,
            stored,
            currentTime,
          ));
        }
        if (createReceiptBinding) {
          transaction.set(receiptRef, receiptBindingDocument({
            receiptDigest,
            capabilityPurposeDigest,
            sourceUid: request.sourceUid,
            operationId: operation.id,
            requestKeyHash: request.requestKey,
            boundAtMillis: currentTime,
          }));
          transaction.set(requestRef, {
            ...requestRecord,
            operationId: operation.id,
            terminalStatusReceiptDigest: receiptDigest,
          });
          transaction.set(ownerRef, {
            ...ownerRecord,
            operationId: operation.id,
            terminalStatusReceiptDigest: receiptDigest,
            updatedAtMillis: currentTime,
          });
          if (!purposeSnapshot.exists) {
            transaction.set(purposeRef, {
              purpose: DELETION_STATUS_RECEIPT_PURPOSE,
              capabilityPurposeDigest,
              receiptDigest,
              state: "active",
              registeredAtMillis: currentTime,
            });
          }
        }
        return operation;
      }

      let existing = null;
      let existingStored = null;
      if (ownerSnapshot.exists) {
        const existingId = ownerRecord.operationId;
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
      const createReceiptBinding = shouldCreateReceiptBinding({
        receiptDigest,
        capabilityPurposeDigest,
        receiptSnapshot,
        purposeSnapshot,
        requestRecord: null,
        ownerRecord,
        operation,
        request,
        operationIsNew: !creation.reused,
      });
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
          ...(receiptDigest
            ? { terminalStatusReceiptDigest: receiptDigest }
            : {}),
        });
        if (createReceiptBinding) {
          transaction.set(receiptRef, receiptBindingDocument({
            receiptDigest,
            capabilityPurposeDigest,
            sourceUid: request.sourceUid,
            operationId: operation.id,
            requestKeyHash: request.requestKey,
            boundAtMillis: currentTime,
          }));
          transaction.set(ownerRef, {
            ...ownerRecord,
            operationId: operation.id,
            terminalStatusReceiptDigest: receiptDigest,
            updatedAtMillis: currentTime,
          });
          if (!purposeSnapshot.exists) {
            transaction.set(purposeRef, {
              purpose: DELETION_STATUS_RECEIPT_PURPOSE,
              capabilityPurposeDigest,
              receiptDigest,
              state: "active",
              registeredAtMillis: currentTime,
            });
          }
        }
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
        ...(receiptDigest
          ? { terminalStatusReceiptDigest: receiptDigest }
          : {}),
      });
      transaction.set(requestRef, {
        operationId: operation.id,
        createdAtMillis: currentTime,
        ...(receiptDigest
          ? { terminalStatusReceiptDigest: receiptDigest }
          : {}),
      });
      if (createReceiptBinding) {
        transaction.set(receiptRef, receiptBindingDocument({
          receiptDigest,
          capabilityPurposeDigest,
          sourceUid: request.sourceUid,
          operationId: operation.id,
          requestKeyHash: request.requestKey,
          boundAtMillis: currentTime,
        }));
        if (!purposeSnapshot.exists) {
          transaction.set(purposeRef, {
            purpose: DELETION_STATUS_RECEIPT_PURPOSE,
            capabilityPurposeDigest,
            receiptDigest,
            state: "active",
            registeredAtMillis: currentTime,
          });
        }
      }
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

  async function getDeletionByStatusReceipt({ receiptDigest }) {
    const normalizedReceiptDigest =
      requiredDeletionStatusReceiptDigest(receiptDigest);
    const receiptRef = deletionStatusReceipts.doc(normalizedReceiptDigest);
    return firestore.runTransaction(async (transaction) => {
      const receiptSnapshot = await transaction.get(receiptRef);
      if (!receiptSnapshot.exists) {
        throw repositoryFailure("operation-not-found");
      }
      const receipt = receiptSnapshot.data() || {};
      if (receipt.purpose !== DELETION_STATUS_RECEIPT_PURPOSE ||
          receipt.receiptDigest !== normalizedReceiptDigest ||
          typeof receipt.capabilityPurposeDigest !== "string" ||
          receipt.state !== "active" ||
          typeof receipt.sourceUid !== "string" ||
          receipt.sourceUid.length === 0 ||
          typeof receipt.operationId !== "string" ||
          !/^[A-Za-z0-9_-]{1,128}$/.test(receipt.operationId) ||
          typeof receipt.requestKeyHash !== "string" ||
          receipt.requestKeyHash.length === 0 ||
          receipt.requestKeyHash.length > 256 ||
          !Number.isFinite(receipt.boundAtMillis)) {
        throw repositoryFailure("operation-not-found");
      }
      let normalizedPurposeDigest;
      try {
        normalizedPurposeDigest =
          requiredDeletionCapabilityPurposeDigest(
            receipt.capabilityPurposeDigest,
          );
      } catch {
        throw repositoryFailure("operation-not-found");
      }
      const purposeRef = deletionCapabilityPurposes.doc(
        normalizedPurposeDigest,
      );
      const purposeSnapshot = await transaction.get(purposeRef);
      const purposeRecord = purposeSnapshot.exists
        ? purposeSnapshot.data() || {}
        : {};
      if (purposeRecord.purpose !== DELETION_STATUS_RECEIPT_PURPOSE ||
          purposeRecord.capabilityPurposeDigest !==
            receipt.capabilityPurposeDigest ||
          purposeRecord.receiptDigest !== normalizedReceiptDigest ||
          purposeRecord.state !== "active") {
        throw repositoryFailure("operation-not-found");
      }
      const requestRef = requests.doc(stableKey(
        "account-operation-request",
        "deletion",
        receipt.sourceUid,
        receipt.requestKeyHash,
      ));
      const requestSnapshot = await transaction.get(requestRef);
      const requestRecord = requestSnapshot.exists
        ? requestSnapshot.data() || {}
        : {};
      if (requestRecord.operationId !== receipt.operationId ||
          requestRecord.terminalStatusReceiptDigest !==
            normalizedReceiptDigest) {
        throw repositoryFailure("operation-not-found");
      }
      const operationRef = operations.doc(receipt.operationId);
      const operationSnapshot = await transaction.get(operationRef);
      if (!operationSnapshot.exists) {
        throw repositoryFailure("operation-not-found");
      }
      const stored = operationSnapshot.data() || {};
      let operation;
      try {
        operation = normalizeOperation(stored);
      } catch {
        throw repositoryFailure("operation-not-found");
      }
      if (operation.kind !== "deletion" ||
          operation.sourceUid !== receipt.sourceUid ||
          operation.requestKey !== receipt.requestKeyHash) {
        throw repositoryFailure("operation-not-found");
      }
      return operation;
    });
  }

  async function acknowledgeDeletionStatusReceipt({
    receiptDigest,
    capabilityPurposeDigest,
  }) {
    const normalizedReceiptDigest =
      requiredDeletionStatusReceiptDigest(receiptDigest);
    const normalizedPurposeDigest =
      requiredDeletionCapabilityPurposeDigest(capabilityPurposeDigest);
    const receiptRef = deletionStatusReceipts.doc(normalizedReceiptDigest);
    const purposeRef = deletionCapabilityPurposes.doc(
      normalizedPurposeDigest,
    );
    return firestore.runTransaction(async (transaction) => {
      const [receiptSnapshot, purposeSnapshot] = await Promise.all([
        transaction.get(receiptRef),
        transaction.get(purposeRef),
      ]);
      const purposeRecord = purposeSnapshot.exists
        ? purposeSnapshot.data() || {}
        : {};
      const purposeMatchesReceipt =
        purposeRecord.purpose === DELETION_STATUS_RECEIPT_PURPOSE &&
        purposeRecord.capabilityPurposeDigest === normalizedPurposeDigest &&
        purposeRecord.receiptDigest === normalizedReceiptDigest;
      if (!receiptSnapshot.exists) {
        if (purposeMatchesReceipt &&
            purposeRecord.state === "acknowledged" &&
            Number.isFinite(purposeRecord.acknowledgedAtMillis)) {
          return true;
        }
        throw repositoryFailure("operation-not-found");
      }
      const receipt = receiptSnapshot.data() || {};
      if (receipt.purpose !== DELETION_STATUS_RECEIPT_PURPOSE ||
          receipt.receiptDigest !== normalizedReceiptDigest ||
          receipt.capabilityPurposeDigest !== normalizedPurposeDigest ||
          !purposeMatchesReceipt) {
        throw repositoryFailure("operation-not-found");
      }
      if (receipt.state === "acknowledged" &&
          purposeRecord.state === "acknowledged" &&
          Number.isFinite(receipt.acknowledgedAtMillis) &&
          Number.isFinite(timestampMillis(receipt.purgeAfter))) {
        return true;
      }
      if (receipt.state !== "active" || purposeRecord.state !== "active" ||
          typeof receipt.sourceUid !== "string" ||
          receipt.sourceUid.length === 0 ||
          typeof receipt.operationId !== "string" ||
          !/^[A-Za-z0-9_-]{1,128}$/.test(receipt.operationId) ||
          typeof receipt.requestKeyHash !== "string" ||
          receipt.requestKeyHash.length === 0 ||
          receipt.requestKeyHash.length > 256 ||
          !Number.isFinite(receipt.boundAtMillis)) {
        throw repositoryFailure("operation-not-found");
      }
      const requestRef = requests.doc(stableKey(
        "account-operation-request",
        "deletion",
        receipt.sourceUid,
        receipt.requestKeyHash,
      ));
      const ownerRef = owners.doc(stableKey(
        "account-operation-owner",
        receipt.sourceUid,
      ));
      const operationRef = operations.doc(receipt.operationId);
      const [requestSnapshot, ownerSnapshot, operationSnapshot] =
        await Promise.all([
          transaction.get(requestRef),
          transaction.get(ownerRef),
          transaction.get(operationRef),
        ]);
      const requestRecord = requestSnapshot.exists
        ? requestSnapshot.data() || {}
        : {};
      const ownerRecord = ownerSnapshot.exists
        ? ownerSnapshot.data() || {}
        : {};
      if (!operationSnapshot.exists ||
          requestRecord.operationId !== receipt.operationId ||
          requestRecord.terminalStatusReceiptDigest !==
            normalizedReceiptDigest) {
        throw repositoryFailure("operation-not-found");
      }
      let operation;
      try {
        operation = normalizeOperation(operationSnapshot.data() || {});
      } catch {
        throw repositoryFailure("operation-not-found");
      }
      if (operation.kind !== "deletion" ||
          operation.sourceUid !== receipt.sourceUid ||
          operation.requestKey !== receipt.requestKeyHash ||
          operation.phase !== "completed") {
        throw repositoryFailure("operation-not-found");
      }

      const currentTime = nowMillis();
      const purgeAfter = timestampFromMillis(
        currentTime + ACKNOWLEDGED_RECEIPT_RETENTION_MILLIS,
      );
      if (!Number.isFinite(timestampMillis(purgeAfter))) {
        throw repositoryFailure("invalid-deletion-status-receipt-timestamp");
      }
      transaction.set(receiptRef, {
        purpose: DELETION_STATUS_RECEIPT_PURPOSE,
        receiptDigest: normalizedReceiptDigest,
        capabilityPurposeDigest: normalizedPurposeDigest,
        state: "acknowledged",
        acknowledgedAtMillis: currentTime,
        purgeAfter,
      });
      transaction.set(purposeRef, {
        ...purposeRecord,
        state: "acknowledged",
        acknowledgedAtMillis: currentTime,
      });
      const {
        terminalStatusReceiptDigest: ignoredRequestReceiptDigest,
        ...cleanRequestRecord
      } = requestRecord;
      void ignoredRequestReceiptDigest;
      transaction.set(requestRef, cleanRequestRecord);
      if (ownerRecord.operationId === operation.id &&
          ownerRecord.terminalStatusReceiptDigest ===
            normalizedReceiptDigest) {
        const {
          terminalStatusReceiptDigest: ignoredOwnerReceiptDigest,
          ...cleanOwnerRecord
        } = ownerRecord;
        void ignoredOwnerReceiptDigest;
        transaction.set(ownerRef, cleanOwnerRecord);
      }
      return true;
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

  async function consumeDeletionStatusReceiptRequest({ key }) {
    const normalizedKey = requiredDeletionStatusRateLimitKey(key);
    const rateRef = deletionStatusRateLimits.doc(normalizedKey);
    return firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(rateRef);
      const current = snapshot.exists ? snapshot.data() || {} : {};
      const currentTime = nowMillis();
      const inWindow = Number.isFinite(current.windowStartedAtMillis) &&
        currentTime - current.windowStartedAtMillis <
          DELETION_STATUS_RATE_WINDOW_MILLIS;
      const count = inWindow && Number.isInteger(current.count)
        ? current.count
        : 0;
      if (count >= DELETION_STATUS_RATE_LIMIT) {
        throw repositoryFailure("deletion-status-rate-limit-exceeded");
      }
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

  async function issueDeletionProof({
    sourceUid,
    proofHash,
    capabilityPurposeDigest,
    appleRevocationRequired,
  }) {
    const normalizedPurposeDigest =
      requiredDeletionCapabilityPurposeDigest(capabilityPurposeDigest);
    const ownerRef = deletionProofOwners.doc(stableKey(
      "account-deletion-proof-owner",
      sourceUid,
    ));
    const proofRef = deletionProofs.doc(proofHash);
    const purposeRef = deletionCapabilityPurposes.doc(
      normalizedPurposeDigest,
    );
    return firestore.runTransaction(async (transaction) => {
      const [ownerSnapshot, purposeSnapshot] = await Promise.all([
        transaction.get(ownerRef),
        transaction.get(purposeRef),
      ]);
      const owner = ownerSnapshot.exists ? ownerSnapshot.data() || {} : {};
      const purposeRecord = purposeSnapshot.exists
        ? purposeSnapshot.data() || {}
        : {};
      if (purposeSnapshot.exists &&
          (purposeRecord.purpose !== DELETION_PROOF_PURPOSE ||
           purposeRecord.capabilityPurposeDigest !==
             normalizedPurposeDigest ||
           purposeRecord.state !== "active")) {
        throw repositoryFailure("invalid-deletion-proof");
      }
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
        purpose: DELETION_PROOF_PURPOSE,
        proofHash,
        capabilityPurposeDigest: normalizedPurposeDigest,
        sourceUid,
        appleRevocationRequired: appleRevocationRequired === true,
        issuedAtMillis: currentTime,
        expiresAtMillis,
        claimedOperationId: null,
      });
      if (!purposeSnapshot.exists) {
        transaction.set(purposeRef, {
          purpose: DELETION_PROOF_PURPOSE,
          capabilityPurposeDigest: normalizedPurposeDigest,
          state: "active",
          registeredAtMillis: currentTime,
        });
      }
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
      if (Object.hasOwn(storedProof, "capabilityPurposeDigest")) {
        let normalizedPurposeDigest;
        try {
          normalizedPurposeDigest =
            requiredDeletionCapabilityPurposeDigest(
              storedProof.capabilityPurposeDigest,
            );
        } catch {
          return false;
        }
        const purposeSnapshot = await transaction.get(
          deletionCapabilityPurposes.doc(normalizedPurposeDigest),
        );
        const purposeRecord = purposeSnapshot.exists
          ? purposeSnapshot.data() || {}
          : {};
        if (storedProof.purpose !== DELETION_PROOF_PURPOSE ||
            purposeRecord.purpose !== DELETION_PROOF_PURPOSE ||
            purposeRecord.capabilityPurposeDigest !==
              normalizedPurposeDigest ||
            purposeRecord.state !== "active") {
          return false;
        }
      }
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
      // The Apple-revocation callable claims the lease to persist revocation
      // progress without advancing the deletion phase (TN-2026-09-05 T3):
      // an early `deletionRequested` claim must not silently fast-forward
      // the operation into `userTreeDeleting` out from under the caller.
      if (operation.phase === "deletionRequested" &&
          allowAppleRevocationInput !== true) {
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
      const markerData = markerSnapshot.exists
        ? markerSnapshot.data() || {}
        : {};
      const retainsServerCleanupReceipt =
        markerData.serverOwned === true &&
        markerData.operationId === operationId;
      transaction.set(operationRef, updated);
      transaction.set(markerRef, {
        ...markerData,
        state: "active",
        serverOwned: true,
        operationId,
        sourceUid: operation.sourceUid,
        // A completed legacy cleanup is only a receipt for its legacy
        // trigger. A newly leased server operation must run its own
        // idempotent community cleanup; a reclaimed lease for the same
        // server operation keeps its established receipt.
        cleanupComplete: retainsServerCleanupReceipt
          ? markerData.cleanupComplete === true
          : false,
        createdAtMillis:
          markerData.createdAtMillis || currentTime,
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

  async function recordDeletionWorkFailure({
    operationId,
    workerId,
    operationVersion,
    leaseVersion,
    safeCode,
    nowMillis: failureTimeMillis,
  }) {
    const operationRef = operations.doc(requiredOperationId(operationId));
    requiredString(workerId, "worker-id-required");
    if (!Number.isInteger(operationVersion) || operationVersion < 0 ||
        !Number.isInteger(leaseVersion) || leaseVersion < 1) {
      throw repositoryFailure("invalid-worker-version");
    }
    if (!SAFE_DELETION_WORK_FAILURE_CODES.has(safeCode)) {
      throw repositoryFailure("invalid-worker-failure-code");
    }
    if (!Number.isFinite(failureTimeMillis) || failureTimeMillis < 0) {
      throw repositoryFailure("invalid-worker-failure-time");
    }
    return firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(operationRef);
      if (!snapshot.exists) {
        throw repositoryFailure("operation-not-found");
      }
      const stored = snapshot.data() || {};
      const operation = normalizeOperation(stored);
      const lease = stored.workerLease || {};
      if (operation.version !== operationVersion ||
          lease.workerId !== workerId ||
          lease.leaseVersion !== leaseVersion) {
        throw repositoryFailure("stale-worker-lease");
      }
      const updated = {
        ...stored,
        updatedAtMillis: failureTimeMillis,
        nextAttemptAtMillis:
          failureTimeMillis + workerRetryDelayMillis(leaseVersion),
        deletionProgress: {
          ...workerProgress(stored),
          statusCode: safeCode,
        },
        workerLease: {
          ...lease,
          leaseUntilMillis: failureTimeMillis,
        },
      };
      transaction.set(operationRef, updated);
      return workerResult(updated);
    });
  }

  return Object.freeze({
    backfillLegacyDeletionSchedule,
    acknowledgeDeletionStatusReceipt,
    checkpointDeletionWork,
    cancelReplacement,
    claimDeletionByProof,
    claimDeletionWork,
    consumeAnonymousRequest,
    consumeDeletionStatusReceiptRequest,
    consumePublicProofRequest,
    createOrReuseDeletion: (request) =>
      createOrReuse(request, {
        deletionRequested: true,
        terminalStatusReceiptDigest:
          request.terminalStatusReceiptDigest ?? null,
        terminalStatusReceiptPurposeDigest:
          request.terminalStatusReceiptPurposeDigest ?? null,
      }),
    createOrReuseReplacement: (request) => createOrReuse(request),
    get,
    getDeletionByStatusReceipt,
    issueDeletionProof,
    recordDeletionWorkFailure,
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
  unitTimeoutMillis = DEFAULT_DESTRUCTIVE_UNIT_TIMEOUT_MILLIS,
  newWorkerInvocationId = () => crypto.randomUUID(),
} = {}) {
  if (!repository ||
      typeof repository.claimDeletionWork !== "function" ||
      typeof repository.renewDeletionLease !== "function" ||
      typeof repository.checkpointDeletionWork !== "function" ||
      typeof repository.recordDeletionWorkFailure !== "function") {
    throw new TypeError("A deletion-worker repository is required.");
  }
  if (!auth || typeof auth.deleteUser !== "function" ||
      typeof deleteUserTreePage !== "function" ||
      typeof cleanupCommunity !== "function" ||
      typeof cleanupProcessor !== "function" ||
      typeof newWorkerInvocationId !== "function" ||
      !Number.isFinite(unitTimeoutMillis) ||
      unitTimeoutMillis <= 0) {
    throw new TypeError("Injected destructive worker adapters are required.");
  }

  async function processDeletionOperation({
    operationId,
    workerId,
    deadlineMillis,
  }) {
    if (deadlineMillis !== undefined &&
        (!Number.isFinite(deadlineMillis) || deadlineMillis < 0)) {
      throw new TypeError("Worker deadline must be a non-negative number.");
    }
    const assertWithinDeadline = () => {
      if (deadlineMillis !== undefined && nowMillis() >= deadlineMillis) {
        throw repositoryFailure("worker-deadline-exceeded");
      }
    };
    const invocationWorkerId = stableKey(
      "deletion-worker-invocation",
      requiredString(workerId, "worker-id-required"),
      requiredString(
        newWorkerInvocationId(),
        "worker-invocation-id-required",
      ),
    );
    let claim;
    let operation;
    try {
      assertWithinDeadline();
      claim = await repository.claimDeletionWork({
        operationId,
        workerId: invocationWorkerId,
        leaseMillis,
      });
      operation = claim.operation;
    if (TERMINAL_PHASES.has(operation.phase)) {
      return operationResult(operation);
    }
    if (claim.leaseAcquired === false) {
      return operationResult(operation);
    }

    const renew = async () => {
      assertWithinDeadline();
      claim = await repository.renewDeletionLease({
        operationId,
        workerId: invocationWorkerId,
        operationVersion: operation.version,
        leaseVersion: claim.leaseVersion,
        leaseMillis,
      });
      operation = claim.operation;
      assertWithinDeadline();
      return claim;
    };
    const checkpoint = async (change) => {
      assertWithinDeadline();
      claim = await repository.checkpointDeletionWork({
        operationId,
        workerId: invocationWorkerId,
        operationVersion: operation.version,
        leaseVersion: claim.leaseVersion,
        ...change,
      });
      operation = claim.operation;
      assertWithinDeadline();
      return operationResult(operation);
    };
    const workerFence = () => ({
      workerId: invocationWorkerId,
      operationVersion: operation.version,
      leaseVersion: claim.leaseVersion,
    });
    const retryMetadata = () => ({
      operationId,
      workerId: invocationWorkerId,
      operationVersion: operation.version,
      leaseVersion: claim.leaseVersion,
    });
    const runDestructiveUnit = async (start) => {
      assertWithinDeadline();
      const remainingMillis = deadlineMillis === undefined
        ? unitTimeoutMillis
        : Math.max(0, deadlineMillis - nowMillis());
      const timeoutMillis = Math.min(unitTimeoutMillis, remainingMillis);
      if (timeoutMillis <= 0) {
        throw repositoryFailure("worker-deadline-exceeded");
      }
      const abortController = new AbortController();
      let timeout;
      const timedOut = new Promise((_, reject) => {
        timeout = setTimeout(async () => {
          abortController.abort();
          const metadata = retryMetadata();
          let failureRecorded = false;
          try {
            await repository.recordDeletionWorkFailure({
              ...metadata,
              safeCode: "worker-failed",
              nowMillis: nowMillis(),
            });
            failureRecorded = true;
          } catch {
            // The scheduler will make one bounded best-effort recording attempt.
          }
          reject(new DeletionWorkerFailure(metadata, {
            failureRecorded,
          }));
        }, timeoutMillis);
      });
      try {
        return await Promise.race([
          Promise.resolve().then(() => start(abortController.signal)),
          timedOut,
        ]);
      } finally {
        clearTimeout(timeout);
      }
    };

    if (operation.kind === "replacement" &&
        operation.phase === "sourceCleanupPending") {
      if (!claim.progress.userTreeComplete) {
        await renew();
        const page = await runDestructiveUnit((signal) => deleteUserTreePage({
          uid: operation.sourceUid,
          cursor: claim.progress.cursor,
          limit: pageSize,
          operationId,
          workerFence: workerFence(),
          deadlineMillis,
          signal,
        }));
        assertWithinDeadline();
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
          await runDestructiveUnit(() =>
            auth.deleteUser(operation.sourceUid));
        } catch (error) {
          if (error?.code !== "auth/user-not-found") throw error;
        }
        assertWithinDeadline();
        return checkpoint({ progress: { authComplete: true } });
      }
      if (!claim.progress.communityComplete) {
        await renew();
        const cleanup = await runDestructiveUnit((signal) => cleanupCommunity({
          uid: operation.sourceUid,
          operationId,
          workerFence: workerFence(),
          deadlineMillis,
          signal,
        }));
        assertWithinDeadline();
        return checkpoint({
          progress: {
            communityComplete: cleanup?.done !== false,
          },
        });
      }
      await renew();
      const cleanup = await runDestructiveUnit((signal) => cleanupProcessor({
        uid: operation.sourceUid,
        operationId,
        workerFence: workerFence(),
        deadlineMillis,
        signal,
      }));
      assertWithinDeadline();
      return checkpoint({
        progress: { processorComplete: cleanup?.done !== false },
        toPhase: cleanup?.done === false ? undefined : "completed",
      });
    }

    if (operation.phase === "userTreeDeleting") {
      if (!claim.progress.userTreeComplete) {
        await renew();
        const page = await runDestructiveUnit((signal) => deleteUserTreePage({
          uid: operation.sourceUid,
          cursor: claim.progress.cursor,
          limit: pageSize,
          operationId,
          workerFence: workerFence(),
          deadlineMillis,
          signal,
        }));
        assertWithinDeadline();
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
      // NOTE (TN-2026-09-05 T3): an earlier attempt skipped this transition
      // entirely when claim.progress.appleRevocationComplete was already
      // true (set by an early completeAppleRevocation call at
      // deletionRequested/userTreeDeleting). That direct
      // userTreeDeleting -> authDeleted checkpoint is rejected by
      // account_operations.js's nextPhases()/transitionOperation() with
      // invalid-operation-transition: nextPhases() decides purely from
      // {phase, appleRevocationRequired} and has no visibility into
      // deletionProgress, so it always demands the appleRevocationPending
      // hop when appleRevocationRequired is true. appleRevocationRequired
      // itself cannot be flipped to false early either, since
      // completeAppleRevocation's own idempotent-return branch depends on
      // it staying true for the operation's whole lifetime. Left as the
      // pre-existing unconditional hop (reported to Fable rather than
      // changing the phase-transition table unilaterally); the
      // appleRevocationPending branch below already resolves in the very
      // next tick with no further Apple API call once progress is complete.
      if (operation.appleRevocationRequired) {
        return checkpoint({ toPhase: "appleRevocationPending" });
      }
      await renew();
      try {
        await runDestructiveUnit(() =>
          auth.deleteUser(operation.sourceUid));
      } catch (error) {
        if (error?.code !== "auth/user-not-found") throw error;
      }
      assertWithinDeadline();
      return checkpoint({ toPhase: "authDeleted" });
    }

    if (operation.phase === "authDeleted") {
      return checkpoint({ toPhase: "communityCleanupPending" });
    }

    if (operation.phase === "appleRevocationPending") {
      if (claim.progress.appleRevocationComplete) {
        await renew();
        try {
          await runDestructiveUnit(() =>
            auth.deleteUser(operation.sourceUid));
        } catch (error) {
          if (error?.code !== "auth/user-not-found") throw error;
        }
        assertWithinDeadline();
        return checkpoint({ toPhase: "authDeleted" });
      }
      return operationResult(operation);
    }

    if (operation.phase === "communityCleanupPending") {
      await renew();
      const cleanup = await runDestructiveUnit((signal) => cleanupCommunity({
        uid: operation.sourceUid,
        operationId,
        workerFence: workerFence(),
        deadlineMillis,
        signal,
      }));
      assertWithinDeadline();
      return checkpoint({
        toPhase: cleanup?.done === false
          ? undefined
          : "processorCleanupPending",
      });
    }

    if (operation.phase === "processorCleanupPending") {
      await renew();
      const cleanup = await runDestructiveUnit((signal) => cleanupProcessor({
        uid: operation.sourceUid,
        operationId,
        workerFence: workerFence(),
        deadlineMillis,
        signal,
      }));
      assertWithinDeadline();
      return checkpoint({
        toPhase: cleanup?.done === false ? undefined : "completed",
      });
    }

    return operationResult(operation);
    } catch (error) {
      if (error instanceof DeletionWorkerFailure) {
        throw error;
      }
      if (claim?.leaseAcquired !== false && operation) {
        throw new DeletionWorkerFailure({
          operationId,
          workerId: invocationWorkerId,
          operationVersion: operation.version,
          leaseVersion: claim.leaseVersion,
        });
      }
      throw error;
    }
  }

  return Object.freeze({ processDeletionOperation });
}

async function runScheduledDeletionCandidate({
  candidate,
  repository,
  workerRuntime,
  logger,
  deadlineMillis,
  nowMillis = () => Date.now(),
} = {}) {
  if (!candidate || typeof candidate.id !== "string" ||
      !repository ||
      typeof repository.recordDeletionWorkFailure !== "function" ||
      !workerRuntime ||
      typeof workerRuntime.processDeletionOperation !== "function" ||
      !logger ||
      typeof logger.warn !== "function" ||
      typeof nowMillis !== "function" ||
      (deadlineMillis !== undefined &&
        (!Number.isFinite(deadlineMillis) || deadlineMillis < 0))) {
    throw new TypeError("Scheduled deletion dependencies are required.");
  }
  if (deadlineMillis !== undefined && nowMillis() >= deadlineMillis) {
    return null;
  }
  try {
    return await workerRuntime.processDeletionOperation({
      operationId: candidate.id,
      workerId: `scheduled-${candidate.id}`,
      deadlineMillis,
    });
  } catch (error) {
    if (error instanceof DeletionWorkerFailure) {
      if (!error.failureRecorded) {
        try {
          await repository.recordDeletionWorkFailure({
            ...error.retryMetadata,
            safeCode: "worker-failed",
            nowMillis: nowMillis(),
          });
        } catch {
          logger.warn("account-deletion-worker-failure-recording-failed", {
            code: "worker-failed",
          });
          return null;
        }
      }
    }
    logger.warn("account-deletion-worker-failed", {
      code: "worker-failed",
    });
    return null;
  }
}

function scheduledCandidateClass(candidate) {
  if (candidate?.phase === "appleRevocationPending") return "apple";
  if (candidate?.kind === "replacement") return "replacement";
  return "deletion";
}

async function runScheduledDeletionBatch({
  candidates,
  repository,
  workerRuntime,
  logger,
  deadlineMillis,
  nowMillis = () => Date.now(),
} = {}) {
  if (!Array.isArray(candidates) ||
      !Number.isFinite(deadlineMillis) ||
      deadlineMillis < 0 ||
      typeof nowMillis !== "function") {
    throw new TypeError("Scheduled deletion batch dependencies are required.");
  }
  const queues = {
    replacement: [],
    deletion: [],
    apple: [],
  };
  for (const candidate of dedupeCandidates(candidates)) {
    queues[scheduledCandidateClass(candidate)].push(candidate);
  }

  const classOrder = ["replacement", "deletion", "apple"];
  while (classOrder.some((name) => queues[name].length > 0)) {
    if (nowMillis() >= deadlineMillis) break;
    const wave = classOrder
      .map((name) => queues[name].shift())
      .filter(Boolean);
    await Promise.all(wave.map((candidate) =>
      runScheduledDeletionCandidate({
        candidate,
        repository,
        workerRuntime,
        logger,
        deadlineMillis,
        nowMillis,
      })));
  }
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
    case "deletion-status-rate-limit-exceeded":
      return ["resource-exhausted", code];
    case "stale-operation-version":
      return ["aborted", code];
    case "operation-in-progress":
    case "terminal-operation":
    case "invalid-operation-transition":
      return ["failed-precondition", code];
    case "terminal-status-receipt-invalid":
      return ["invalid-argument", code];
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
  hashDeletionStatusReceipt,
  hashDeletionCapabilityPurpose,
  hashDeletionStatusRateLimitKey,
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
      typeof repository.consumeDeletionStatusReceiptRequest !== "function" ||
      typeof repository.getDeletionByStatusReceipt !== "function" ||
      typeof repository.acknowledgeDeletionStatusReceipt !== "function" ||
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
      typeof hashDeletionStatusReceipt !== "function" ||
      typeof hashDeletionCapabilityPurpose !== "function" ||
      typeof hashDeletionStatusRateLimitKey !== "function" ||
      typeof revokeAppleAuthorizationCode !== "function") {
    throw new TypeError("Deletion-proof crypto adapters are required.");
  }
  if (typeof makeError !== "function") {
    throw new TypeError("A safe callable error adapter is required.");
  }

  async function authenticate(request, requiredAccountType = "any") {
    if (!request?.app || typeof request.app.appId !== "string") {
      // Advisory only — see CALLABLE_OPTIONS. Log for abuse monitoring.
      console.warn("[accountOperations] request without App Check context");
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
        // Without App Check context the rate limit still applies per uid
        // under a fixed bucket instead of failing on a missing appId.
        appId: typeof request?.app?.appId === "string"
          ? request.app.appId
          : "app-check-absent",
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

  async function consumeDeletionStatusQuota(request) {
    const rawIp = request?.rawRequest?.ip;
    const normalizedIp = typeof rawIp === "string" &&
      rawIp.length > 0 && rawIp.length <= 128
      ? rawIp
      : "unknown";
    const key = requiredDeletionStatusRateLimitKey(
      await hashDeletionStatusRateLimitKey(normalizedIp),
    );
    await repository.consumeDeletionStatusReceiptRequest({ key });
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
      let terminalStatusReceiptDigest = null;
      let terminalStatusReceiptPurposeDigest = null;
      if (Object.hasOwn(data, "terminalStatusReceipt")) {
        if (!isRawDeletionStatusReceipt(data.terminalStatusReceipt)) {
          throw new BoundaryFailure(
            "invalid-argument",
            "terminal-status-receipt-invalid",
          );
        }
        terminalStatusReceiptDigest = requiredDeletionStatusReceiptDigest(
          await hashDeletionStatusReceipt(data.terminalStatusReceipt),
        );
        terminalStatusReceiptPurposeDigest =
          requiredDeletionCapabilityPurposeDigest(
            await hashDeletionCapabilityPurpose(
              data.terminalStatusReceipt,
            ),
          );
      }
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
        terminalStatusReceiptDigest,
        terminalStatusReceiptPurposeDigest,
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
      const capabilityPurposeDigest =
        requiredDeletionCapabilityPurposeDigest(
          await hashDeletionCapabilityPurpose(proof),
        );
      const issuance = await repository.issueDeletionProof({
        sourceUid: identity.uid,
        proofHash,
        capabilityPurposeDigest,
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
      // A bounded selector is not an OAuth client ID. Actual IDs and redirect
      // URLs are server configuration, and the adapter verifies Apple audience.
      const clientKind = data.clientKind === undefined ? 'native' : data.clientKind;
      const subjects = identity.decoded?.firebase?.identities?.['apple.com'];
      if (!['native', 'web'].includes(clientKind) ||
          !Array.isArray(subjects) || subjects.length !== 1 ||
          typeof subjects[0] !== 'string' || !subjects[0]) {
        throw repositoryFailure('invalid-operation');
      }
      const expectedSubject = subjects[0];
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
      // TN-2026-09-05 T3: Apple authorization codes expire in ~5 minutes,
      // long before the scheduled worker's multi-tick schedule would reach
      // appleRevocationPending on its own. deletionRequested/userTreeDeleting
      // may hand in the code early; the revocation is recorded as progress
      // with no phase transition, and the worker later skips
      // appleRevocationPending once it sees the completed progress.
      const isEarlyPhase = EARLY_APPLE_REVOCATION_PHASES.has(visible.phase);
      if ((visible.phase !== "appleRevocationPending" && !isEarlyPhase) ||
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
      const claimedPhaseMatches = isEarlyPhase
        ? EARLY_APPLE_REVOCATION_PHASES.has(operation.phase)
        : operation.phase === "appleRevocationPending";
      if (operation.version !== expectedVersion || !claimedPhaseMatches) {
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

      if (isEarlyPhase) {
        // No worker lease should outlive this callable: checkpoint() below
        // always sets workerLease.leaseUntilMillis to "now", so the
        // scheduled worker is never blocked by worker-lease-held.
        if (!claim.progress.appleRevocationComplete) {
          await renew();
          let revocationUnavailable = false;
          try {
            await revokeAppleAuthorizationCode({
              authorizationCode,
              uid: identity.uid,
              clientKind,
              expectedSubject,
            });
          } catch (error) {
            if (error?.code !== "apple/revocation-config-invalid") {
              await checkpoint({
                progress: { statusCode: "apple-revocation-retryable" },
              });
              throw repositoryFailure("apple-revocation-pending");
            }
            revocationUnavailable = true;
          }
          await checkpoint({
            progress: {
              appleRevocationComplete: true,
              statusCode: revocationUnavailable
                ? "apple-revocation-unavailable"
                : null,
            },
          });
        }
        return operationResult(operation);
      }

      if (!claim.progress.appleRevocationComplete) {
        await renew();
        let revocationUnavailable = false;
        try {
          await revokeAppleAuthorizationCode({
            authorizationCode,
            uid: identity.uid,
            clientKind,
            expectedSubject,
          });
        } catch (error) {
          // TN3194: missing/placeholder Apple revoke secrets must not
          // permanently stall account deletion. Network/provider failures
          // stay retryable so a fresh authorization code can be supplied.
          if (error?.code !== "apple/revocation-config-invalid") {
            await checkpoint({
              progress: { statusCode: "apple-revocation-retryable" },
            });
            throw repositoryFailure("apple-revocation-pending");
          }
          revocationUnavailable = true;
        }
        await checkpoint({
          progress: {
            appleRevocationComplete: true,
            statusCode: revocationUnavailable
              ? "apple-revocation-unavailable"
              : null,
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

    getAccountDeletionStatusByReceipt: (request) => execute(async () => {
      await consumeDeletionStatusQuota(request);
      const data = request?.data;
      const keys = data && typeof data === "object" && !Array.isArray(data)
        ? Object.keys(data)
        : [];
      const terminalStatusReceipt = keys.length === 1 &&
        keys[0] === "terminalStatusReceipt"
        ? data.terminalStatusReceipt
        : null;
      if (!isRawDeletionStatusReceipt(terminalStatusReceipt)) {
        throw new BoundaryFailure("not-found", "operation-not-found");
      }
      const receiptDigest = requiredDeletionStatusReceiptDigest(
        await hashDeletionStatusReceipt(terminalStatusReceipt),
      );
      const operation = await repository.getDeletionByStatusReceipt({
        receiptDigest,
      });
      return operationResult(operation);
    }),

    acknowledgeAccountDeletionStatusReceipt: (request) => execute(
      async () => {
        await consumeDeletionStatusQuota(request);
        const data = request?.data;
        const keys = data && typeof data === "object" && !Array.isArray(data)
          ? Object.keys(data)
          : [];
        const terminalStatusReceipt = keys.length === 1 &&
          keys[0] === "terminalStatusReceipt"
          ? data.terminalStatusReceipt
          : null;
        if (!isRawDeletionStatusReceipt(terminalStatusReceipt)) {
          throw new BoundaryFailure("not-found", "operation-not-found");
        }
        const receiptDigest = requiredDeletionStatusReceiptDigest(
          await hashDeletionStatusReceipt(terminalStatusReceipt),
        );
        const capabilityPurposeDigest =
          requiredDeletionCapabilityPurposeDigest(
            await hashDeletionCapabilityPurpose(terminalStatusReceipt),
          );
        await repository.acknowledgeDeletionStatusReceipt({
          receiptDigest,
          capabilityPurposeDigest,
        });
        return { acknowledged: true };
      },
    ),
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
  NORMAL_DELETION_PHASES,
  PUBLIC_ENDPOINT_OPTIONS,
  createAccountOperationCallables,
  createAccountOperationRuntime,
  createDeletionWorkerRuntime,
  createDeletionProofHttpEndpoint,
  createDeletionProofHttpHandler,
  createFirestoreAccountOperationRepository,
  createKeyedDeletionProofDigest,
  deletionCapabilityPurposeDigest,
  deletionStatusReceiptDigest,
  fetchActionableDeletionCandidates,
  fetchStagedActionableDeletionCandidates,
  legacyAccountTombstoneCleanupAction,
  runScheduledDeletionCandidate,
  runScheduledDeletionBatch,
  SCHEDULE_TIMEOUT_SECONDS,
  SCHEDULE_WORKER_DEADLINE_MILLIS,
};
