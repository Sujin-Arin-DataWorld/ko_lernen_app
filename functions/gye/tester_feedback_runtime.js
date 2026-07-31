"use strict";

const { createHash } = require("node:crypto");

const CALLABLE_OPTIONS = Object.freeze({
  region: "europe-west3",
  enforceAppCheck: true,
  consumeAppCheckToken: true,
});

const CATALOG_VERSION = 1;
// Tester-friendly production quota: at most 20 newly accepted completions for
// the same authenticated UID and verified App Check app in any rolling 24h.
const FEEDBACK_RATE_LIMIT_MAX = 20;
const FEEDBACK_RATE_LIMIT_WINDOW_MILLIS = 24 * 60 * 60 * 1000;
const ACCOUNT_DELETION_INACTIVE_PHASES = new Set(["cancelled", "completed"]);
const REPLACEMENT_DELETION_PHASES = new Set([
  "sourceCleanupPending",
  "deletionRequested",
  "userTreeDeleting",
  "authDeleting",
  "communityDeleting",
  "processorDeleting",
  "appleRevocationPending",
  "blocked",
]);
const MISSION_CATALOG = Object.freeze([
  Object.freeze({
    id: "beta_scenario",
    labelKey: "testerFeedbackMissionScenario",
    allowedContentTypes: Object.freeze(["scenario"]),
  }),
  Object.freeze({
    id: "beta_word_work",
    labelKey: "testerFeedbackMissionWordWork",
    allowedContentTypes: Object.freeze([
      "vocab_pack",
      "review",
      "custom_wordbook",
      "custom_wordbook_game",
      "legacy_vocab",
    ]),
  }),
  Object.freeze({
    id: "beta_listening",
    labelKey: "testerFeedbackMissionListening",
    allowedContentTypes: Object.freeze(["listening"]),
  }),
  Object.freeze({
    id: "beta_games",
    labelKey: "testerFeedbackMissionGames",
    allowedContentTypes: Object.freeze(["game"]),
  }),
  Object.freeze({
    id: "beta_language_form",
    labelKey: "testerFeedbackMissionLanguageForm",
    allowedContentTypes: Object.freeze([
      "grammar_session",
      "hangul_cards",
      "hangul_writing",
      "daily_hangul",
    ]),
  }),
]);

const MISSION_BY_ID = new Map(
  MISSION_CATALOG.map((mission) => [mission.id, mission]),
);
const ALLOWED_CONTENT_TYPES = new Set(
  MISSION_CATALOG.flatMap((mission) => mission.allowedContentTypes),
);
const ALLOWED_FIELDS = new Set([
  "schemaVersion",
  "feedbackId",
  "completionId",
  "contentType",
  "contentId",
  "contentLabel",
  "level",
  "scoreSummary",
  "category",
  "message",
  "issueArea",
  "contentSignal",
  "contentFocus",
  "appVersion",
  "platform",
  "locale",
  "betaMissionId",
]);
const CATEGORIES = new Set(["bug", "content", "other"]);
const ISSUE_AREAS = new Set([
  "ui",
  "answer",
  "audio",
  "translation",
  "navigation",
  "other",
]);
const CONTENT_SIGNALS = new Set([
  "too_easy",
  "right",
  "too_hard",
  "unclear",
]);
const CONTENT_FOCUSES = new Set([
  "explanation",
  "examples",
  "questions",
  "pace",
  "translation",
  "other",
]);
const LEVELS = new Set(["A1", "A2", "B1", "B2"]);
const PLATFORMS = new Set(["android", "ios"]);
const LOCALES = new Set(["de", "en"]);

class BoundaryFailure extends Error {
  constructor(status, safeCode) {
    super(safeCode);
    this.status = status;
    this.safeCode = safeCode;
  }
}

function invalidPayload() {
  throw new BoundaryFailure(
    "invalid-argument",
    "invalid-feedback-payload",
  );
}

function isPlainObject(value) {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    return false;
  }
  const prototype = Object.getPrototypeOf(value);
  return prototype === Object.prototype || prototype === null;
}

function requireString(data, key, {
  minLength = 0,
  maxLength,
  allowedValues,
  documentId = false,
} = {}) {
  const value = data[key];
  if (typeof value !== "string" || value.length > maxLength) {
    invalidPayload();
  }
  if (minLength > 0 && value.trim().length < minLength) invalidPayload();
  if (allowedValues && !allowedValues.has(value)) invalidPayload();
  if (documentId && (
    value.includes("/") || value === "." || value === ".."
  )) {
    invalidPayload();
  }
  return value;
}

function optionalEnum(data, key, allowedValues) {
  if (!Object.hasOwn(data, key)) return undefined;
  return requireString(data, key, { maxLength: 64, allowedValues });
}

function validatePayload(raw) {
  if (!isPlainObject(raw)) invalidPayload();
  for (const key of Object.keys(raw)) {
    if (!ALLOWED_FIELDS.has(key)) invalidPayload();
  }
  if (raw.schemaVersion !== 1) invalidPayload();

  const feedbackId = requireString(raw, "feedbackId", {
    minLength: 1,
    maxLength: 64,
  });
  const completionId = requireString(raw, "completionId", {
    minLength: 1,
    maxLength: 64,
    documentId: true,
  });
  const contentType = requireString(raw, "contentType", {
    minLength: 1,
    maxLength: 48,
    allowedValues: ALLOWED_CONTENT_TYPES,
  });
  const contentId = requireString(raw, "contentId", {
    minLength: 1,
    maxLength: 128,
  });
  const contentLabel = requireString(raw, "contentLabel", { maxLength: 120 });
  const level = optionalEnum(raw, "level", LEVELS);
  const scoreSummary = requireString(raw, "scoreSummary", { maxLength: 64 });
  const category = requireString(raw, "category", {
    maxLength: 16,
    allowedValues: CATEGORIES,
  });
  const message = requireString(raw, "message", { maxLength: 1000 });
  const issueArea = optionalEnum(raw, "issueArea", ISSUE_AREAS);
  const contentSignal = optionalEnum(raw, "contentSignal", CONTENT_SIGNALS);
  const contentFocus = optionalEnum(raw, "contentFocus", CONTENT_FOCUSES);
  const appVersion = requireString(raw, "appVersion", {
    minLength: 1,
    maxLength: 64,
  });
  const platform = requireString(raw, "platform", {
    maxLength: 16,
    allowedValues: PLATFORMS,
  });
  const locale = requireString(raw, "locale", {
    maxLength: 8,
    allowedValues: LOCALES,
  });
  const betaMissionId = optionalEnum(
    raw,
    "betaMissionId",
    new Set(MISSION_BY_ID.keys()),
  );

  const hasMessage = message.trim().length > 0;
  if (category === "bug") {
    if (!hasMessage || contentSignal !== undefined || contentFocus !== undefined) {
      invalidPayload();
    }
  } else if (category === "other") {
    if (
      !hasMessage ||
      issueArea !== undefined ||
      contentSignal !== undefined ||
      contentFocus !== undefined
    ) {
      invalidPayload();
    }
  } else if (
    issueArea !== undefined ||
    (!hasMessage && contentSignal === undefined && contentFocus === undefined)
  ) {
    invalidPayload();
  }

  return {
    schemaVersion: 1,
    feedbackId,
    completionId,
    contentType,
    contentId,
    contentLabel,
    ...(level === undefined ? {} : { level }),
    scoreSummary,
    category,
    message,
    ...(issueArea === undefined ? {} : { issueArea }),
    ...(contentSignal === undefined ? {} : { contentSignal }),
    ...(contentFocus === undefined ? {} : { contentFocus }),
    appVersion,
    platform,
    locale,
    ...(betaMissionId === undefined ? {} : { betaMissionId }),
  };
}

function validateRequestContext(request) {
  if (
    !request?.app ||
    typeof request.app.appId !== "string" ||
    request.app.appId.trim().length === 0
  ) {
    throw new BoundaryFailure(
      "failed-precondition",
      "app-check-required",
    );
  }
  if (request.app.alreadyConsumed === true) {
    throw new BoundaryFailure(
      "resource-exhausted",
      "app-check-token-consumed",
    );
  }
  const uid = request?.auth?.uid;
  if (
    typeof uid !== "string" ||
    uid.trim().length === 0 ||
    uid.length > 128 ||
    uid.includes("/")
  ) {
    throw new BoundaryFailure(
      "unauthenticated",
      "authentication-required",
    );
  }
  return { uid, appId: request.app.appId };
}

function appIdDocumentId(appId) {
  return createHash("sha256").update(appId, "utf8").digest("hex");
}

function accountOperationOwnerDocumentId(uid) {
  return createHash("sha256")
    .update(`account-operation-owner\u0000${uid}`, "utf8")
    .digest("hex");
}

async function activeDeletionOperation({ firestore, transaction, uid }) {
  const ownerRef = firestore.doc(
    `account_operation_owners/${accountOperationOwnerDocumentId(uid)}`,
  );
  const ownerSnapshot = await transaction.get(ownerRef);
  if (!ownerSnapshot.exists) return false;

  const operationId = (ownerSnapshot.data() || {}).operationId;
  if (typeof operationId !== "string" ||
      !/^[A-Za-z0-9_-]{1,128}$/.test(operationId)) {
    return true;
  }
  const operationSnapshot = await transaction.get(
    firestore.doc(`account_operations/${operationId}`),
  );
  if (!operationSnapshot.exists) return true;
  const operation = operationSnapshot.data() || {};
  if (operation.sourceUid !== uid) return true;
  if (operation.kind === "deletion") {
    return !ACCOUNT_DELETION_INACTIVE_PHASES.has(operation.phase);
  }
  return operation.kind === "replacement" &&
    REPLACEMENT_DELETION_PHASES.has(operation.phase);
}

function recentAcceptedCompletionMillis(raw, nowMillis) {
  if (!Array.isArray(raw)) return [];
  const cutoff = nowMillis - FEEDBACK_RATE_LIMIT_WINDOW_MILLIS;
  return raw
    .filter((value) => Number.isSafeInteger(value) && value >= 0 && value > cutoff)
    .sort((left, right) => left - right)
    .slice(-FEEDBACK_RATE_LIMIT_MAX);
}

function normalizedCompletedMissionIds(raw) {
  const supplied = Array.isArray(raw) ? new Set(raw) : new Set();
  return MISSION_CATALOG
    .map((mission) => mission.id)
    .filter((missionId) => supplied.has(missionId));
}

function nextMission(completedMissionIds) {
  const completed = new Set(completedMissionIds);
  return MISSION_CATALOG.find((mission) => !completed.has(mission.id)) || null;
}

function response({ accepted, duplicate, stampAccepted, completedMissionIds }) {
  const next = nextMission(completedMissionIds);
  return {
    accepted,
    duplicate,
    stampAccepted,
    passportCompletedMissionIds: [...completedMissionIds],
    nextMissionId: next?.id || null,
    nextMissionLabelKey: next?.labelKey || null,
  };
}

function missionMatches(missionId, contentType) {
  const mission = MISSION_BY_ID.get(missionId);
  return mission?.allowedContentTypes.includes(contentType) === true;
}

function existingStampWasAccepted(existing, completedMissionIds) {
  return existing?.stampAccepted === true &&
    typeof existing.betaMissionId === "string" &&
    typeof existing.contentType === "string" &&
    missionMatches(existing.betaMissionId, existing.contentType) &&
    completedMissionIds.includes(existing.betaMissionId);
}

function createTesterFeedbackRuntime({
  firestore,
  serverTimestamp,
  serverNowMillis = Date.now,
  makeError,
} = {}) {
  if (
    !firestore ||
    typeof firestore.doc !== "function" ||
    typeof firestore.runTransaction !== "function"
  ) {
    throw new TypeError("A Firestore transaction adapter is required.");
  }
  if (typeof serverTimestamp !== "function") {
    throw new TypeError("A server timestamp adapter is required.");
  }
  if (typeof serverNowMillis !== "function") {
    throw new TypeError("A server clock adapter is required.");
  }
  if (typeof makeError !== "function") {
    throw new TypeError("A safe callable error adapter is required.");
  }

  async function execute(callback) {
    try {
      return await callback();
    } catch (error) {
      if (error instanceof BoundaryFailure) {
        throw makeError(error.status, error.safeCode);
      }
      throw makeError("internal", "feedback-unavailable");
    }
  }

  async function submitTesterFeedback(request) {
    return execute(async () => {
      const { uid, appId } = validateRequestContext(request);
      const data = validatePayload(request.data);
      const feedbackRef = firestore.doc(
        `users/${uid}/tester_feedback/${data.completionId}`,
      );
      const passportRef = firestore.doc(
        `users/${uid}/tester_passport/state`,
      );
      const accountDeletionRef = firestore.doc(`account_deletions/${uid}`);
      const rateLimitRef = firestore.doc(
        `users/${uid}/tester_feedback_rate_limits/${appIdDocumentId(appId)}`,
      );

      return firestore.runTransaction(async (transaction) => {
        const accountDeletionSnapshot = await transaction.get(
          accountDeletionRef,
        );
        if (accountDeletionSnapshot.exists) {
          throw new BoundaryFailure(
            "failed-precondition",
            "account-deletion-active",
          );
        }
        if (await activeDeletionOperation({
          firestore,
          transaction,
          uid,
        })) {
          throw new BoundaryFailure(
            "failed-precondition",
            "account-deletion-active",
          );
        }
        const feedbackSnapshot = await transaction.get(feedbackRef);
        const passportSnapshot = await transaction.get(passportRef);
        const passport = passportSnapshot.exists
          ? passportSnapshot.data() || {}
          : {};
        const completedMissionIds = normalizedCompletedMissionIds(
          passport.completedMissionIds,
        );

        if (feedbackSnapshot.exists) {
          const existing = feedbackSnapshot.data() || {};
          if (existing.feedbackId === data.feedbackId) {
            return response({
              accepted: true,
              duplicate: false,
              stampAccepted: existingStampWasAccepted(
                existing,
                completedMissionIds,
              ),
              completedMissionIds,
            });
          }
          return response({
            accepted: false,
            duplicate: true,
            stampAccepted: false,
            completedMissionIds,
          });
        }

        const rateLimitSnapshot = await transaction.get(rateLimitRef);
        const nowMillis = serverNowMillis();
        if (!Number.isSafeInteger(nowMillis) || nowMillis < 0) {
          throw new Error("Server clock is unavailable.");
        }
        const acceptedAtMillis = recentAcceptedCompletionMillis(
          rateLimitSnapshot.exists
            ? (rateLimitSnapshot.data() || {}).acceptedAtMillis
            : undefined,
          nowMillis,
        );
        if (acceptedAtMillis.length >= FEEDBACK_RATE_LIMIT_MAX) {
          throw new BoundaryFailure(
            "resource-exhausted",
            "feedback-rate-limit-exceeded",
          );
        }

        const stampAccepted = data.betaMissionId !== undefined &&
          missionMatches(data.betaMissionId, data.contentType) &&
          !completedMissionIds.includes(data.betaMissionId);
        const nextCompletedMissionIds = stampAccepted
          ? normalizedCompletedMissionIds([
              ...completedMissionIds,
              data.betaMissionId,
            ])
          : completedMissionIds;
        const timestamp = serverTimestamp();

        transaction.create(feedbackRef, {
          ...data,
          status: "new",
          createdAt: timestamp,
          stampAccepted,
        });
        if (stampAccepted) {
          transaction.set(passportRef, {
            catalogVersion: CATALOG_VERSION,
            completedMissionIds: nextCompletedMissionIds,
            updatedAt: timestamp,
          }, { merge: true });
        }
        transaction.set(rateLimitRef, {
          schemaVersion: 1,
          acceptedAtMillis: [...acceptedAtMillis, nowMillis],
          updatedAt: timestamp,
        });

        return response({
          accepted: true,
          duplicate: false,
          stampAccepted,
          completedMissionIds: nextCompletedMissionIds,
        });
      });
    });
  }

  return Object.freeze({ submitTesterFeedback });
}

function createTesterFeedbackCallable({ handler, onCall } = {}) {
  if (typeof handler !== "function" || typeof onCall !== "function") {
    throw new TypeError("Tester feedback callable dependencies are required.");
  }
  return onCall(CALLABLE_OPTIONS, handler);
}

module.exports = {
  CALLABLE_OPTIONS,
  MISSION_CATALOG,
  createTesterFeedbackCallable,
  createTesterFeedbackRuntime,
};
