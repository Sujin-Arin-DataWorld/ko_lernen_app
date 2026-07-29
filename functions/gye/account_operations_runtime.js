"use strict";

const crypto = require("node:crypto");
const {
  claimDeletionProof,
  createOrReuseOperation,
  normalizeOperation,
  operationResult,
  transitionOperation,
} = require("./account_operations");

const CALLABLE_NAMES = Object.freeze([
  "prepareAnonymousReplacement",
  "attachReplacementTarget",
  "commitReplacementReconciliation",
  "startSourceCleanup",
  "requestAccountDeletion",
  "issueDeletionProof",
  "getAccountOperation",
]);
const CALLABLE_OPTIONS = Object.freeze({
  region: "europe-west3",
  enforceAppCheck: true,
  consumeAppCheckToken: true,
});
const TERMINAL_PHASES = new Set(["completed", "blocked"]);
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
      if (operation.phase === "prepared") {
        operation = transitionOperation(operation, {
          toPhase: "deletionRequested",
          expectedVersion: operation.version,
        });
      }
      const currentTime = nowMillis();
      if (!creation.reused ||
          operation.phase !== existing?.phase ||
          operation.version !== existing?.version) {
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

  return Object.freeze({
    claimDeletionByProof,
    consumeAnonymousRequest,
    consumePublicProofRequest,
    createOrReuseDeletion: (request) =>
      createOrReuse(request, { deletionRequested: true }),
    createOrReuseReplacement: (request) => createOrReuse(request),
    get,
    issueDeletionProof,
    transition,
  });
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
  hashDeletionProof,
  makeError,
} = {}) {
  if (!auth || typeof auth.verifyIdToken !== "function") {
    throw new TypeError("A Firebase Auth verifier is required.");
  }
  if (!repository ||
      typeof repository.consumeAnonymousRequest !== "function" ||
      typeof repository.createOrReuseReplacement !== "function" ||
      typeof repository.createOrReuseDeletion !== "function" ||
      typeof repository.issueDeletionProof !== "function" ||
      typeof repository.transition !== "function" ||
      typeof repository.get !== "function") {
    throw new TypeError("An account-operation repository is required.");
  }
  if (typeof newDeletionProof !== "function" ||
      typeof hashDeletionProof !== "function") {
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
  CALLABLE_NAMES,
  CALLABLE_OPTIONS,
  FIRST_PARTY_ORIGIN,
  PUBLIC_ENDPOINT_OPTIONS,
  createAccountOperationCallables,
  createAccountOperationRuntime,
  createDeletionProofHttpEndpoint,
  createDeletionProofHttpHandler,
  createFirestoreAccountOperationRepository,
};
