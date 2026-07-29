"use strict";

const OPERATION_PHASES = Object.freeze([
  "prepared",
  "targetVerified",
  "reconciling",
  "sourceCleanupPending",
  "deletionRequested",
  "userTreeDeleting",
  "authDeleted",
  "appleRevocationPending",
  "communityCleanupPending",
  "processorCleanupPending",
  "completed",
  "blocked",
]);

const TERMINAL_PHASES = new Set(["completed", "blocked"]);
function operationError(code, message) {
  const error = new Error(message);
  error.code = code;
  return error;
}

function requiredString(value, name) {
  if (typeof value !== "string" || value.length === 0) {
    throw operationError("invalid-operation", `${name} is required.`);
  }
  return value;
}

function nonNegativeInteger(value) {
  return Number.isInteger(value) && value >= 0 ? value : 0;
}

function normalizedPhaseAttempts(value) {
  const result = {};
  if (!value || typeof value !== "object") return result;
  for (const phase of OPERATION_PHASES) {
    const attempts = nonNegativeInteger(value[phase]);
    if (attempts > 0) result[phase] = attempts;
  }
  return result;
}

function totalAttempts(phaseAttempts) {
  return Object.values(phaseAttempts).reduce((sum, count) => sum + count, 0);
}

function normalizeOperation(operation) {
  if (!operation || typeof operation !== "object") {
    throw operationError("invalid-operation", "An operation record is required.");
  }
  const kind = operation.kind;
  if (kind !== "replacement" && kind !== "deletion") {
    throw operationError("invalid-operation", "Operation kind must be replacement or deletion.");
  }
  const sourceUid = requiredString(operation.sourceUid, "sourceUid");
  const id = requiredString(operation.id, "id");
  const phase = OPERATION_PHASES.includes(operation.phase)
    ? operation.phase
    : "prepared";
  const targetUid = kind === "replacement"
    ? requiredString(operation.targetUid, "targetUid")
    : null;
  if (targetUid === sourceUid) {
    throw operationError(
      "source-and-target-must-differ",
      "Replacement sourceUid and targetUid must differ.",
    );
  }
  const phaseAttempts = normalizedPhaseAttempts(operation.phaseAttempts);
  return {
    id,
    kind,
    sourceUid,
    targetUid,
    requestKey: typeof operation.requestKey === "string" ? operation.requestKey : null,
    phase,
    version: nonNegativeInteger(operation.version),
    attemptCount: totalAttempts(phaseAttempts),
    phaseAttempts,
    appleRevocationRequired: kind === "deletion" &&
      operation.appleRevocationRequired === true,
    retry: operation.retry && typeof operation.retry === "object"
      ? { classification: operation.retry.classification || "none" }
      : { classification: "none" },
    blockedReason: phase === "blocked" && typeof operation.blockedReason === "string"
      ? operation.blockedReason
      : null,
  };
}

function initialOperation(request) {
  return normalizeOperation({
    id: request.id,
    kind: request.kind,
    sourceUid: request.sourceUid,
    targetUid: request.targetUid,
    requestKey: request.requestKey,
    appleRevocationRequired: request.appleRevocationRequired,
    phase: "prepared",
    version: 0,
    phaseAttempts: {},
  });
}

function requestMatches(operation, request) {
  if (operation.kind !== request.kind || operation.sourceUid !== request.sourceUid) {
    return false;
  }
  if (operation.requestKey && operation.requestKey === request.requestKey) {
    return true;
  }
  return !TERMINAL_PHASES.has(operation.phase) &&
    operation.targetUid === (request.kind === "replacement" ? request.targetUid : null);
}

function createOrReuseOperation({ existingOperations, request }) {
  const requested = initialOperation(request || {});
  const existing = Array.isArray(existingOperations) ? existingOperations : [];
  for (const candidate of existing) {
    const operation = normalizeOperation(candidate);
    if (requestMatches(operation, requested)) {
      return { operation, reused: true };
    }
  }
  return { operation: requested, reused: false };
}

function nextPhases(operation) {
  switch (operation.phase) {
    case "prepared":
      return operation.kind === "replacement" ? ["targetVerified"] : ["deletionRequested"];
    case "targetVerified":
      return ["reconciling"];
    case "reconciling":
      return ["sourceCleanupPending"];
    case "sourceCleanupPending":
      return ["completed"];
    case "deletionRequested":
      return ["userTreeDeleting"];
    case "userTreeDeleting":
      return ["authDeleted"];
    case "authDeleted":
      return [operation.appleRevocationRequired
        ? "appleRevocationPending"
        : "communityCleanupPending"];
    case "appleRevocationPending":
      return ["communityCleanupPending"];
    case "communityCleanupPending":
      return ["processorCleanupPending"];
    case "processorCleanupPending":
      return ["completed"];
    default:
      return [];
  }
}

function requireExpectedVersion(operation, expectedVersion) {
  if (!Number.isInteger(expectedVersion) || expectedVersion !== operation.version) {
    throw operationError("stale-operation-version", "The operation version is stale.");
  }
}

function transitionOperation(operation, { toPhase, expectedVersion, blockedReason } = {}) {
  const current = normalizeOperation(operation);
  requireExpectedVersion(current, expectedVersion);
  if (TERMINAL_PHASES.has(current.phase)) {
    throw operationError("terminal-operation", "Terminal operations cannot advance.");
  }
  const allowed = toPhase === "blocked" || nextPhases(current).includes(toPhase);
  if (!allowed) {
    throw operationError("invalid-operation-transition", "The requested operation transition is not allowed.");
  }
  return normalizeOperation({
    ...current,
    phase: toPhase,
    version: current.version + 1,
    retry: { classification: "none" },
    blockedReason: toPhase === "blocked"
      ? (typeof blockedReason === "string" ? blockedReason : "operation-blocked")
      : null,
  });
}

function recordAttempt(operation, { phase, attempt, expectedVersion } = {}) {
  const current = normalizeOperation(operation);
  requireExpectedVersion(current, expectedVersion);
  if (TERMINAL_PHASES.has(current.phase)) {
    throw operationError("terminal-operation", "Terminal operations cannot be retried.");
  }
  if (phase !== current.phase) {
    throw operationError("out-of-order-attempt", "Attempts must apply to the current phase.");
  }
  const previousAttempt = current.phaseAttempts[phase] || 0;
  if (!Number.isInteger(attempt) || attempt !== previousAttempt + 1) {
    throw operationError("non-monotonic-attempt", "Attempts must increase by exactly one.");
  }
  return normalizeOperation({
    ...current,
    version: current.version + 1,
    phaseAttempts: { ...current.phaseAttempts, [phase]: attempt },
  });
}

function classifyRetry(errorCode) {
  if (errorCode === "auth/user-not-found") return "terminal-success";
  if (!errorCode || errorCode === "success") return "none";
  if (/^(auth\/invalid|permission-denied|invalid-argument|proof\/)/.test(errorCode)) {
    return "permanent";
  }
  return "retryable";
}

function applyAttemptResult(operation, {
  phase,
  attempt,
  expectedVersion,
  errorCode,
} = {}) {
  const attempted = recordAttempt(operation, { phase, attempt, expectedVersion });
  const classification = classifyRetry(errorCode);
  if (classification === "terminal-success" && attempted.phase === "userTreeDeleting") {
    const advanced = transitionOperation(attempted, {
      toPhase: "authDeleted",
      expectedVersion: attempted.version,
    });
    return normalizeOperation({
      ...advanced,
      retry: { classification },
    });
  }
  return normalizeOperation({
    ...attempted,
    retry: { classification },
  });
}

function claimDeletionProof(proof, { proofHash, nowMillis, operationId } = {}) {
  if (!proof || typeof proof !== "object" ||
      typeof proof.proofHash !== "string" || proof.proofHash !== proofHash) {
    return { accepted: false, operationId: null, reason: "invalid", proof: null };
  }
  if (!Number.isFinite(proof.expiresAtMillis) || !Number.isFinite(nowMillis) ||
      nowMillis >= proof.expiresAtMillis) {
    return { accepted: false, operationId: null, reason: "expired", proof: null };
  }
  const claimedOperationId = typeof proof.claimedOperationId === "string" &&
    proof.claimedOperationId.length > 0
    ? proof.claimedOperationId
    : requiredString(operationId, "operationId");
  return {
    accepted: true,
    operationId: claimedOperationId,
    reason: null,
    proof: {
      proofHash: proof.proofHash,
      expiresAtMillis: proof.expiresAtMillis,
      claimedOperationId,
    },
  };
}

function operationResult(operation) {
  const current = normalizeOperation(operation);
  return {
    operationId: current.id,
    kind: current.kind,
    phase: current.phase,
    version: current.version,
    attemptCount: current.attemptCount,
    retryable: !TERMINAL_PHASES.has(current.phase) &&
      current.retry.classification !== "permanent",
    blockedReason: current.blockedReason,
  };
}

module.exports = {
  OPERATION_PHASES,
  applyAttemptResult,
  claimDeletionProof,
  classifyRetry,
  createOrReuseOperation,
  normalizeOperation,
  operationResult,
  recordAttempt,
  transitionOperation,
};
