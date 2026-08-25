"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  CALLABLE_OPTIONS,
  MISSION_CATALOG,
  createTesterFeedbackCallable,
  createTesterFeedbackRuntime,
} = require("./tester_feedback_runtime");

const SERVER_TIMESTAMP = Object.freeze({ kind: "server-timestamp" });
const SERVER_NOW_MILLIS = Date.UTC(2026, 6, 31, 12, 0, 0);
const RATE_LIMIT_WINDOW_MILLIS = 24 * 60 * 60 * 1000;
const SAFE_UID = "anonymous-user";
const PRIVATE_OWNER_OPERATION_PATH =
  "account_operation_owners/" +
  "37d23a855c0ae1fc8a7168d3373783460412ac6bcef2e76a5cb1a507abd8385f";
const DEFAULT_OWNER_OPERATION_PATH =
  "account_operation_owners/" +
  "2403cb0bf68b674c57577d39f86f3c26aec72f3e2468aae7309f6991754cda9c";
const DEFAULT_RATE_LIMIT_PATH =
  "users/anonymous-user/tester_feedback_rate_limits/" +
  "5d59ba64d93a7a3c7af8856d2fbcdfc18c11436fdc93dfb2ec568ddf611cb9d4";

const BASE_PAYLOAD = Object.freeze({
  schemaVersion: 2,
  expectedOwnerUid: SAFE_UID,
  feedbackId: "feedback-1",
  completionId: "completion-1",
  contentType: "scenario",
  contentId: "cafe-order",
  contentLabel: "At the cafe",
  level: "A1",
  scoreSummary: "7/10",
  category: "bug",
  message: "The audio stopped.",
  issueArea: "audio",
  appVersion: "1.2.3+45",
  platform: "android",
  locale: "de",
  betaMissionId: "beta_scenario",
});
const VALID_PAYLOAD_V2 = Object.freeze({
  ...BASE_PAYLOAD,
});

function payload(overrides = {}) {
  return Object.fromEntries(Object.entries({ ...BASE_PAYLOAD, ...overrides })
    .filter(([, value]) => value !== undefined));
}

function callableRequest(data = BASE_PAYLOAD, {
  uid = SAFE_UID,
  appId = "test-app-id",
  alreadyConsumed = false,
} = {}) {
  return {
    auth: uid == null
      ? undefined
      : {
          uid,
          token: { firebase: { sign_in_provider: "anonymous" } },
        },
    app: appId == null ? undefined : { appId, alreadyConsumed },
    data,
  };
}

function safeCallableError(status, safeCode) {
  const error = new Error("Tester feedback request failed.");
  error.status = status;
  error.safeCode = safeCode;
  return error;
}

async function rejectsWithSafeCode(promise, status, safeCode) {
  await assert.rejects(promise, (error) => {
    assert.equal(error.status, status);
    assert.equal(error.safeCode, safeCode);
    return true;
  });
}

function clone(value) {
  return value === undefined ? undefined : structuredClone(value);
}

class FakeFirestore {
  constructor(initial = {}, { beforeFirstCommit } = {}) {
    this.documents = new Map(
      Object.entries(initial).map(([path, value]) => [path, clone(value)]),
    );
    this.versions = new Map(
      [...this.documents.keys()].map((path) => [path, 1]),
    );
    this.readPaths = [];
    this.referencedPaths = [];
    this.writeHistory = [];
    this.transactionCount = 0;
    this.transactionAttemptCount = 0;
    this.beforeFirstCommit = beforeFirstCommit;
    this.beforeFirstCommitCalled = false;
  }

  doc(path) {
    this.referencedPaths.push(path);
    return Object.freeze({ path });
  }

  async runTransaction(callback) {
    this.transactionCount += 1;
    for (let attempt = 0; attempt < 5; attempt += 1) {
      this.transactionAttemptCount += 1;
      const pendingWrites = [];
      const readVersions = new Map();
      const transaction = {
        get: async (reference) => {
          this.readPaths.push(reference.path);
          readVersions.set(reference.path, this.versions.get(reference.path) || 0);
          const exists = this.documents.has(reference.path);
          const value = exists ? clone(this.documents.get(reference.path)) : null;
          return {
            exists,
            data: () => clone(value),
          };
        },
        create: (reference, value) => {
          pendingWrites.push({ type: "create", reference, value: clone(value) });
        },
        set: (reference, value, options) => {
          pendingWrites.push({
            type: "set",
            reference,
            value: clone(value),
            options: clone(options),
          });
        },
      };

      const result = await callback(transaction);
      if (!this.beforeFirstCommitCalled && this.beforeFirstCommit) {
        this.beforeFirstCommitCalled = true;
        await this.beforeFirstCommit(this);
      }
      const staleRead = [...readVersions].some(
        ([path, version]) => (this.versions.get(path) || 0) !== version,
      );
      if (staleRead) continue;

      for (const write of pendingWrites) {
        const path = write.reference.path;
        if (write.type === "create" && this.documents.has(path)) {
          throw new Error("document already exists");
        }
        const existing = this.documents.get(path);
        const next = write.options?.merge === true && existing
          ? { ...clone(existing), ...clone(write.value) }
          : clone(write.value);
        this.documents.set(path, next);
        this.versions.set(path, (this.versions.get(path) || 0) + 1);
        this.writeHistory.push({
          type: write.type,
          path,
          value: clone(write.value),
          options: clone(write.options),
        });
      }
      return result;
    }
    throw new Error("transaction retry limit exceeded");
  }

  setConcurrent(path, value) {
    this.documents.set(path, clone(value));
    this.versions.set(path, (this.versions.get(path) || 0) + 1);
  }

  value(path) {
    return clone(this.documents.get(path));
  }

  paths() {
    return [...this.documents.keys()].sort();
  }
}

function createHarness(initial = {}, {
  beforeFirstCommit,
  serverNowMillis = () => SERVER_NOW_MILLIS,
} = {}) {
  const firestore = new FakeFirestore(initial, { beforeFirstCommit });
  const handlers = createTesterFeedbackRuntime({
    firestore,
    serverTimestamp: () => SERVER_TIMESTAMP,
    serverNowMillis,
    makeError: safeCallableError,
  });
  return { firestore, handlers };
}

test("registers the callable with the exact protected v2 options", () => {
  const registrations = [];
  const callable = createTesterFeedbackCallable({
    handler: async () => ({ accepted: true, duplicate: false }),
    onCall(options, handler) {
      registrations.push({ options, handler });
      return { options, handler };
    },
  });

  assert.deepEqual(CALLABLE_OPTIONS, {
    region: "europe-west3",
    enforceAppCheck: true,
    consumeAppCheckToken: true,
  });
  assert.equal(registrations.length, 1);
  assert.deepEqual(registrations[0].options, CALLABLE_OPTIONS);
  assert.equal(callable.options, registrations[0].options);
  assert.equal(callable.handler, registrations[0].handler);
});

test("requires Auth UID and live App Check context but allows anonymous auth", async () => {
  const { handlers } = createHarness();

  await rejectsWithSafeCode(
    handlers.submitTesterFeedback(callableRequest(BASE_PAYLOAD, { uid: null })),
    "unauthenticated",
    "authentication-required",
  );
  await rejectsWithSafeCode(
    handlers.submitTesterFeedback(callableRequest(BASE_PAYLOAD, { appId: null })),
    "failed-precondition",
    "app-check-required",
  );
  await rejectsWithSafeCode(
    handlers.submitTesterFeedback(callableRequest(BASE_PAYLOAD, { appId: "" })),
    "failed-precondition",
    "app-check-required",
  );
  await rejectsWithSafeCode(
    handlers.submitTesterFeedback(callableRequest(BASE_PAYLOAD, {
      alreadyConsumed: true,
    })),
    "resource-exhausted",
    "app-check-token-consumed",
  );

  const result = await handlers.submitTesterFeedback(callableRequest());
  assert.equal(result.accepted, true);
  assert.equal(result.duplicate, false);
});

test("binds schema v2 to Auth UID before any transaction or write", async (t) => {
  await t.test("matching immutable owner is accepted", async () => {
    const { firestore, handlers } = createHarness();

    const result = await handlers.submitTesterFeedback(
      callableRequest(VALID_PAYLOAD_V2),
    );

    assert.equal(result.accepted, true);
    assert.equal(firestore.transactionCount, 1);
    assert.equal(
      Object.hasOwn(
        firestore.value("users/anonymous-user/tester_feedback/completion-1"),
        "expectedOwnerUid",
      ),
      false,
    );
  });

  for (const [name, data, uid, status, safeCode] of [
    [
      "forged expected owner",
      { ...VALID_PAYLOAD_V2, expectedOwnerUid: "account-a" },
      "account-b",
      "permission-denied",
      "feedback-owner-mismatch",
    ],
    [
      "missing expected owner",
      { ...VALID_PAYLOAD_V2, expectedOwnerUid: undefined },
      SAFE_UID,
      "invalid-argument",
      "invalid-feedback-payload",
    ],
    [
      "legacy schema v1",
      { ...BASE_PAYLOAD, schemaVersion: 1 },
      SAFE_UID,
      "invalid-argument",
      "invalid-feedback-payload",
    ],
  ]) {
    await t.test(name, async () => {
      const { firestore, handlers } = createHarness();

      await rejectsWithSafeCode(
        handlers.submitTesterFeedback(callableRequest(data, { uid })),
        status,
        safeCode,
      );

      assert.equal(firestore.transactionCount, 0);
      assert.deepEqual(firestore.writeHistory, []);
      assert.deepEqual(firestore.paths(), []);
    });
  }
});

test("rejects unknown fields and any payload UID", async (t) => {
  for (const [name, data] of [
    ["unknown field", payload({ unexpected: true })],
    ["forged UID", payload({ uid: "another-user" })],
    ["matching UID", payload({ uid: SAFE_UID })],
  ]) {
    await t.test(name, async () => {
      const { handlers } = createHarness();
      await rejectsWithSafeCode(
        handlers.submitTesterFeedback(callableRequest(data)),
        "invalid-argument",
        "invalid-feedback-payload",
      );
    });
  }
});

test("rejects invalid enums, bounds, and category-specific combinations", async (t) => {
  const cases = [
    ["schema version", { schemaVersion: 1 }],
    ["blank feedback ID", { feedbackId: " " }],
    ["long feedback ID", { feedbackId: "f".repeat(65) }],
    ["blank completion ID", { completionId: "" }],
    ["long completion ID", { completionId: "c".repeat(65) }],
    ["unknown content type", { contentType: "billing" }],
    ["blank content ID", { contentId: " " }],
    ["long content ID", { contentId: "c".repeat(129) }],
    ["long content label", { contentLabel: "c".repeat(121) }],
    ["invalid level", { level: "D1" }],
    ["long score summary", { scoreSummary: "s".repeat(65) }],
    ["invalid category", { category: "praise" }],
    ["long message", { message: "m".repeat(1001) }],
    ["invalid issue area", { issueArea: "device" }],
    ["invalid content signal", {
      category: "content",
      message: "",
      issueArea: undefined,
      contentSignal: "perfect",
    }],
    ["invalid content focus", {
      category: "content",
      message: "",
      issueArea: undefined,
      contentSignal: "right",
      contentFocus: "colors",
    }],
    ["long expected outcome", {
      expectedOutcome: "e".repeat(501),
    }],
    ["long actual outcome", {
      actualOutcome: "a".repeat(501),
    }],
    ["invalid bug frequency", {
      expectedOutcome: "Expected result.",
      actualOutcome: "Actual result.",
      bugFrequency: "daily",
      bugImpact: "can_continue",
    }],
    ["invalid bug impact", {
      expectedOutcome: "Expected result.",
      actualOutcome: "Actual result.",
      bugFrequency: "once",
      bugImpact: "minor",
    }],
    ["blank app version", { appVersion: "" }],
    ["long app version", { appVersion: "v".repeat(65) }],
    ["invalid platform", { platform: "web" }],
    ["invalid locale", { locale: "ko" }],
    ["unknown beta mission", { betaMissionId: "beta_injected" }],
    ["bug without message", { category: "bug", message: "" }],
    ["bug with content fields", {
      category: "bug",
      contentSignal: "right",
    }],
    ["other with issue area", {
      category: "other",
      issueArea: "ui",
    }],
    ["other with content fields", {
      category: "other",
      issueArea: undefined,
      contentFocus: "pace",
    }],
    ["content with issue area", {
      category: "content",
      issueArea: "answer",
      contentSignal: "right",
    }],
    ["empty content feedback", {
      category: "content",
      message: " ",
      issueArea: undefined,
    }],
  ];

  for (const [name, overrides] of cases) {
    await t.test(name, async () => {
      const { handlers } = createHarness();
      const data = payload(overrides);
      for (const [key, value] of Object.entries(data)) {
        if (value === undefined) delete data[key];
      }
      await rejectsWithSafeCode(
        handlers.submitTesterFeedback(callableRequest(data)),
        "invalid-argument",
        "invalid-feedback-payload",
      );
    });
  }
});

test("accepts the 1000-character message boundary and structured content feedback", async () => {
  const messageHarness = createHarness();
  const boundary = await messageHarness.handlers.submitTesterFeedback(
    callableRequest(payload({ message: "m".repeat(1000) })),
  );
  assert.equal(boundary.accepted, true);

  const contentHarness = createHarness();
  const structured = payload({
    feedbackId: "feedback-content",
    completionId: "completion-content",
    category: "content",
    message: "",
    issueArea: undefined,
    contentSignal: "too_hard",
    contentFocus: "explanation",
  });
  delete structured.issueArea;
  const contentResult = await contentHarness.handlers.submitTesterFeedback(
    callableRequest(structured),
  );
  assert.equal(contentResult.accepted, true);
});

test("accepts C1 and C2 levels — scenarios_c1/c2.json 콘텐츠가 실제로 보내는 값", async () => {
  for (const level of ["C1", "C2"]) {
    const harness = createHarness();
    const result = await harness.handlers.submitTesterFeedback(
      callableRequest(payload({
        feedbackId: `feedback-${level}`,
        completionId: `completion-${level}`,
        level,
      })),
    );
    assert.equal(result.accepted, true);
  }
});

test("accepts Book Result experience feedback without a passport mission", async () => {
  const { handlers, firestore } = createHarness();
  const result = await handlers.submitTesterFeedback(callableRequest(payload({
    completionId: "book-1",
    feedbackId: "book-feedback-1",
    contentType: "book_analysis",
    contentId: "book_analysis",
    contentLabel: "book_analysis",
    scoreSummary: "words:4; grammar:1; source:offline",
    category: "content",
    message: "",
    issueArea: undefined,
    betaMissionId: undefined,
    experienceSignal: "mixed",
    experienceFocus: "translation",
  })));

  assert.equal(result.stampAccepted, false);
  assert.equal(
    firestore.value("users/anonymous-user/tester_feedback/book-1")
      .experienceFocus,
    "translation",
  );
});

test("accepts and persists a complete structured bug", async () => {
  const { handlers, firestore } = createHarness();
  await handlers.submitTesterFeedback(callableRequest(payload({
    completionId: "structured-bug-1",
    feedbackId: "structured-bug-feedback-1",
    category: "bug",
    message: "",
    issueArea: "audio",
    expectedOutcome: "The next line should play.",
    actualOutcome: "Playback stopped after one line.",
    bugFrequency: "every_time",
    bugImpact: "slows_learning",
  })));

  const stored = firestore.value(
    "users/anonymous-user/tester_feedback/structured-bug-1",
  );
  assert.deepEqual({
    issueArea: stored.issueArea,
    expectedOutcome: stored.expectedOutcome,
    actualOutcome: stored.actualOutcome,
    bugFrequency: stored.bugFrequency,
    bugImpact: stored.bugImpact,
  }, {
    issueArea: "audio",
    expectedOutcome: "The next line should play.",
    actualOutcome: "Playback stopped after one line.",
    bugFrequency: "every_time",
    bugImpact: "slows_learning",
  });
});

test("rejects Book Result and learning experience family mismatches", async (t) => {
  for (const [name, overrides] of [
    ["Book Result with content signal", {
      contentType: "book_analysis",
      contentId: "book_analysis",
      contentLabel: "book_analysis",
      category: "content",
      message: "",
      issueArea: undefined,
      betaMissionId: undefined,
      contentSignal: "right",
      contentFocus: "translation",
    }],
    ["scenario with experience signal", {
      category: "content",
      message: "",
      issueArea: undefined,
      contentSignal: undefined,
      contentFocus: undefined,
      experienceSignal: "mixed",
      experienceFocus: "translation",
    }],
  ]) {
    await t.test(name, async () => {
      const { handlers } = createHarness();
      await rejectsWithSafeCode(
        handlers.submitTesterFeedback(callableRequest(payload(overrides))),
        "invalid-argument",
        "invalid-feedback-payload",
      );
    });
  }
});

test("rejects a partial experience pair", async (t) => {
  for (const [name, overrides] of [
    ["signal only", { experienceSignal: "mixed" }],
    ["focus only", { experienceFocus: "translation" }],
  ]) {
    await t.test(name, async () => {
      const { handlers } = createHarness();
      await rejectsWithSafeCode(
        handlers.submitTesterFeedback(callableRequest(payload({
          contentType: "book_analysis",
          contentId: "book_analysis",
          contentLabel: "book_analysis",
          category: "content",
          message: "",
          issueArea: undefined,
          betaMissionId: undefined,
          ...overrides,
        }))),
        "invalid-argument",
        "invalid-feedback-payload",
      );
    });
  }
});

test("rejects invalid experience signals and cross-type focuses for feedback-only results", async (t) => {
  for (const [name, overrides] of [
    ["Book Result rejects an invalid signal", {
      contentType: "book_analysis",
      contentId: "book_analysis",
      contentLabel: "book_analysis",
      scoreSummary: "words:4; grammar:1; source:offline",
      experienceSignal: "celebrating",
      experienceFocus: "translation",
    }],
    ["Book Result rejects a Quest focus", {
      contentType: "book_analysis",
      contentId: "book_analysis",
      contentLabel: "book_analysis",
      scoreSummary: "words:4; grammar:1; source:offline",
      experienceSignal: "mixed",
      experienceFocus: "goal",
    }],
    ["Quest completion rejects an invalid signal", {
      contentType: "quest_reward",
      contentId: "quest:daily-1",
      contentLabel: "quest_reward",
      scoreSummary: "type:daily; target:1",
      experienceSignal: "celebrating",
      experienceFocus: "goal",
    }],
    ["Quest completion rejects a Book Result focus", {
      contentType: "quest_reward",
      contentId: "quest:daily-1",
      contentLabel: "quest_reward",
      scoreSummary: "type:daily; target:1",
      experienceSignal: "mixed",
      experienceFocus: "translation",
    }],
    ["Home Milestone rejects an invalid signal", {
      contentType: "milestone",
      contentId: "milestone:streak-7",
      contentLabel: "milestone",
      scoreSummary: "type:streak; value:7",
      experienceSignal: "celebrating",
      experienceFocus: "timing",
    }],
    ["Home Milestone rejects a Book Result focus", {
      contentType: "milestone",
      contentId: "milestone:streak-7",
      contentLabel: "milestone",
      scoreSummary: "type:streak; value:7",
      experienceSignal: "mixed",
      experienceFocus: "grammar",
    }],
  ]) {
    await t.test(name, async () => {
      const { handlers } = createHarness();
      await rejectsWithSafeCode(
        handlers.submitTesterFeedback(callableRequest(payload({
          category: "content",
          message: "",
          issueArea: undefined,
          betaMissionId: undefined,
          ...overrides,
        }))),
        "invalid-argument",
        "invalid-feedback-payload",
      );
    });
  }
});

test("rejects a structured bug missing a required field", async (t) => {
  const completeBug = {
    category: "bug",
    message: "",
    issueArea: "audio",
    expectedOutcome: "The next line should play.",
    actualOutcome: "Playback stopped after one line.",
    bugFrequency: "every_time",
    bugImpact: "slows_learning",
  };
  for (const missingKey of [
    "issueArea",
    "expectedOutcome",
    "actualOutcome",
    "bugFrequency",
    "bugImpact",
  ]) {
    await t.test(missingKey, async () => {
      const { handlers } = createHarness();
      const data = payload({ ...completeBug, [missingKey]: undefined });
      await rejectsWithSafeCode(
        handlers.submitTesterFeedback(callableRequest(data)),
        "invalid-argument",
        "invalid-feedback-payload",
      );
    });
  }
});

test("rejects new feedback fields on other", async (t) => {
  for (const [name, overrides] of [
    ["structured bug field", { expectedOutcome: "Expected result." }],
    ["experience field", { experienceSignal: "mixed" }],
  ]) {
    await t.test(name, async () => {
      const { handlers } = createHarness();
      await rejectsWithSafeCode(
        handlers.submitTesterFeedback(callableRequest(payload({
          category: "other",
          message: "A general note.",
          issueArea: undefined,
          betaMissionId: undefined,
          ...overrides,
        }))),
        "invalid-argument",
        "invalid-feedback-payload",
      );
    });
  }
});

test("rejects feedback-only content paired with a beta mission", async () => {
  const { handlers } = createHarness();
  await rejectsWithSafeCode(
    handlers.submitTesterFeedback(callableRequest(payload({
      contentType: "book_analysis",
      contentId: "book_analysis",
      contentLabel: "book_analysis",
      category: "content",
      message: "",
      issueArea: undefined,
      experienceSignal: "mixed",
      experienceFocus: "translation",
    }))),
    "invalid-argument",
    "invalid-feedback-payload",
  );
});

test("never returns free text, UID, or token detail in validation errors", async () => {
  const { handlers } = createHarness();
  const privateText = "DO-NOT-ECHO-private-feedback";
  const privateUid = "DO-NOT-ECHO-private-uid";
  let caught;
  try {
    await handlers.submitTesterFeedback(callableRequest(
      payload({
        expectedOwnerUid: privateUid,
        message: privateText.repeat(100),
      }),
      { uid: privateUid },
    ));
  } catch (error) {
    caught = error;
  }

  assert.ok(caught);
  const serialized = JSON.stringify(caught);
  assert.doesNotMatch(serialized, /DO-NOT-ECHO/);
  assert.deepEqual(Object.keys(caught).sort(), ["safeCode", "status"]);
});

test("a concurrent account-deletion intent retries and rejects the feedback transaction", async () => {
  const privateUid = "private-account-owner";
  const privateText = "DO-NOT-ECHO-CONCURRENT-FEEDBACK";
  const operationPath = "account_operations/server-owned-deletion";
  const { firestore, handlers } = createHarness({}, {
    beforeFirstCommit: async (database) => {
      database.setConcurrent(PRIVATE_OWNER_OPERATION_PATH, {
        operationId: "server-owned-deletion",
      });
      database.setConcurrent(operationPath, {
        id: "server-owned-deletion",
        kind: "deletion",
        sourceUid: privateUid,
        phase: "deletionRequested",
      });
    },
  });

  let caught;
  try {
    await handlers.submitTesterFeedback(callableRequest(
      payload({ expectedOwnerUid: privateUid, message: privateText }),
      { uid: privateUid },
    ));
  } catch (error) {
    caught = error;
  }

  assert.ok(caught);
  assert.equal(caught.status, "failed-precondition");
  assert.equal(caught.safeCode, "account-deletion-active");
  assert.doesNotMatch(JSON.stringify(caught), /private-account-owner|DO-NOT-ECHO/);
  assert.deepEqual(Object.keys(caught).sort(), ["safeCode", "status"]);
  assert.equal(firestore.transactionAttemptCount, 2);
  assert.deepEqual(firestore.writeHistory, []);
  assert.deepEqual(firestore.paths(), [
    PRIVATE_OWNER_OPERATION_PATH,
    operationPath,
  ]);
});

test("the rolling quota rejects a twenty-first new completion without leaking data", async () => {
  const privateUid = "quota-private-owner";
  const privateText = "DO-NOT-ECHO-QUOTA-FEEDBACK";
  const rateLimitPath =
    `users/${privateUid}/tester_feedback_rate_limits/` +
    "5d59ba64d93a7a3c7af8856d2fbcdfc18c11436fdc93dfb2ec568ddf611cb9d4";
  const { firestore, handlers } = createHarness();

  for (let index = 1; index <= 20; index += 1) {
    const result = await handlers.submitTesterFeedback(callableRequest(payload({
      expectedOwnerUid: privateUid,
      feedbackId: `quota-feedback-${index}`,
      completionId: `quota-completion-${index}`,
      message: privateText,
    }), { uid: privateUid }));
    assert.equal(result.accepted, true);
  }

  let caught;
  try {
    await handlers.submitTesterFeedback(callableRequest(payload({
      expectedOwnerUid: privateUid,
      feedbackId: "quota-feedback-21",
      completionId: "quota-completion-21",
      message: privateText,
    }), { uid: privateUid }));
  } catch (error) {
    caught = error;
  }

  assert.ok(caught);
  assert.equal(caught.status, "resource-exhausted");
  assert.equal(caught.safeCode, "feedback-rate-limit-exceeded");
  assert.doesNotMatch(JSON.stringify(caught), /quota-private-owner|DO-NOT-ECHO/);
  assert.deepEqual(Object.keys(caught).sort(), ["safeCode", "status"]);
  assert.deepEqual(firestore.value(rateLimitPath), {
    schemaVersion: 1,
    acceptedAtMillis: Array(20).fill(SERVER_NOW_MILLIS),
    updatedAt: SERVER_TIMESTAMP,
  });
  assert.equal(
    firestore.value(
      `users/${privateUid}/tester_feedback/quota-completion-21`,
    ),
    undefined,
  );
});

test("idempotent retry and duplicate acknowledgement consume no quota slots", async () => {
  const { firestore, handlers } = createHarness();

  await handlers.submitTesterFeedback(callableRequest());
  await handlers.submitTesterFeedback(callableRequest());
  await handlers.submitTesterFeedback(callableRequest(payload({
    feedbackId: "feedback-collision",
    message: "A different private message.",
  })));

  assert.deepEqual(firestore.value(DEFAULT_RATE_LIMIT_PATH), {
    schemaVersion: 1,
    acceptedAtMillis: [SERVER_NOW_MILLIS],
    updatedAt: SERVER_TIMESTAMP,
  });
  assert.equal(
    firestore.writeHistory.filter(
      ({ path }) => path === DEFAULT_RATE_LIMIT_PATH,
    ).length,
    1,
  );
});

test("the quota is isolated by the verified App Check app ID and hashes its path", async () => {
  const firstAppId = "private/app/id";
  const secondAppId = "other/app/id";
  const firstRatePath =
    "users/anonymous-user/tester_feedback_rate_limits/" +
    "f20a03d6e8c70ad43edaf62463328c961b88ebf89b56dc4d65f93f47568026dc";
  const secondRatePath =
    "users/anonymous-user/tester_feedback_rate_limits/" +
    "1746e1671dd302b3a7df2d8c6f6bc661e355e40c0362826e72462c4980be9e93";
  const { firestore, handlers } = createHarness();

  for (let index = 1; index <= 20; index += 1) {
    await handlers.submitTesterFeedback(callableRequest(payload({
      feedbackId: `first-app-feedback-${index}`,
      completionId: `first-app-completion-${index}`,
    }), { appId: firstAppId }));
  }
  const secondAppResult = await handlers.submitTesterFeedback(callableRequest(
    payload({
      feedbackId: "second-app-feedback-1",
      completionId: "second-app-completion-1",
    }),
    { appId: secondAppId },
  ));

  assert.equal(secondAppResult.accepted, true);
  assert.equal(firestore.value(firstRatePath).acceptedAtMillis.length, 20);
  assert.deepEqual(
    firestore.value(secondRatePath).acceptedAtMillis,
    [SERVER_NOW_MILLIS],
  );
  assert.doesNotMatch(
    JSON.stringify(firestore.referencedPaths),
    /private\/app\/id|other\/app\/id/,
  );
});

test("quota slots expire outside the rolling twenty-four-hour window", async () => {
  let nowMillis = SERVER_NOW_MILLIS;
  const { firestore, handlers } = createHarness({}, {
    serverNowMillis: () => nowMillis,
  });
  for (let index = 1; index <= 20; index += 1) {
    await handlers.submitTesterFeedback(callableRequest(payload({
      feedbackId: `window-feedback-${index}`,
      completionId: `window-completion-${index}`,
    })));
  }

  nowMillis += RATE_LIMIT_WINDOW_MILLIS + 1;
  const result = await handlers.submitTesterFeedback(callableRequest(payload({
    feedbackId: "window-feedback-21",
    completionId: "window-completion-21",
  })));

  assert.equal(result.accepted, true);
  assert.deepEqual(
    firestore.value(DEFAULT_RATE_LIMIT_PATH).acceptedAtMillis,
    [nowMillis],
  );
});

test("writes the completion sentinel and passport stamp in one transaction", async () => {
  const { firestore, handlers } = createHarness();

  const result = await handlers.submitTesterFeedback(callableRequest());

  assert.deepEqual(result, {
    accepted: true,
    duplicate: false,
    stampAccepted: true,
    passportCompletedMissionIds: ["beta_scenario"],
    nextMissionId: "beta_word_work",
    nextMissionLabelKey: "testerFeedbackMissionWordWork",
  });
  assert.equal(firestore.transactionCount, 1);
  assert.deepEqual(firestore.paths(), [
    "users/anonymous-user/tester_feedback/completion-1",
    DEFAULT_RATE_LIMIT_PATH,
    "users/anonymous-user/tester_passport/state",
  ].sort());
  assert.deepEqual(
    [...new Set(firestore.referencedPaths)].sort(),
    [
      "account_deletions/anonymous-user",
      DEFAULT_OWNER_OPERATION_PATH,
      "users/anonymous-user/tester_feedback/completion-1",
      DEFAULT_RATE_LIMIT_PATH,
      "users/anonymous-user/tester_passport/state",
    ].sort(),
  );
  assert.deepEqual(
    firestore.value("users/anonymous-user/tester_feedback/completion-1"),
    {
      schemaVersion: 2,
      feedbackId: "feedback-1",
      completionId: "completion-1",
      contentType: "scenario",
      contentId: "cafe-order",
      contentLabel: "At the cafe",
      level: "A1",
      scoreSummary: "7/10",
      category: "bug",
      message: "The audio stopped.",
      issueArea: "audio",
      appVersion: "1.2.3+45",
      platform: "android",
      locale: "de",
      betaMissionId: "beta_scenario",
      status: "new",
      createdAt: SERVER_TIMESTAMP,
      stampAccepted: true,
    },
  );
  assert.deepEqual(
    firestore.value("users/anonymous-user/tester_passport/state"),
    {
      catalogVersion: 1,
      completedMissionIds: ["beta_scenario"],
      updatedAt: SERVER_TIMESTAMP,
    },
  );
  assert.deepEqual(
    firestore.writeHistory.map(({ type, path }) => ({ type, path })),
    [
      {
        type: "create",
        path: "users/anonymous-user/tester_feedback/completion-1",
      },
      {
        type: "set",
        path: "users/anonymous-user/tester_passport/state",
      },
      {
        type: "set",
        path: DEFAULT_RATE_LIMIT_PATH,
      },
    ],
  );
});

test("same feedback ID retry is idempotently accepted without another write", async () => {
  const { firestore, handlers } = createHarness();

  const first = await handlers.submitTesterFeedback(callableRequest());
  const writesAfterFirst = firestore.writeHistory.length;
  const second = await handlers.submitTesterFeedback(callableRequest());

  assert.equal(first.stampAccepted, true);
  assert.deepEqual(second, first);
  assert.equal(firestore.writeHistory.length, writesAfterFirst);
  assert.equal(firestore.transactionCount, 2);
});

test("same completion with a different feedback ID is a safe duplicate", async () => {
  const { firestore, handlers } = createHarness();
  await handlers.submitTesterFeedback(callableRequest());
  const writesAfterFirst = firestore.writeHistory.length;

  const result = await handlers.submitTesterFeedback(callableRequest(payload({
    feedbackId: "feedback-collision",
    message: "Different private message.",
  })));

  assert.deepEqual(result, {
    accepted: false,
    duplicate: true,
    stampAccepted: false,
    passportCompletedMissionIds: ["beta_scenario"],
    nextMissionId: "beta_word_work",
    nextMissionLabelKey: "testerFeedbackMissionWordWork",
  });
  assert.equal(firestore.writeHistory.length, writesAfterFirst);
  assert.equal(
    firestore.value(
      "users/anonymous-user/tester_feedback/completion-1",
    ).feedbackId,
    "feedback-1",
  );
  assert.equal(firestore.paths().length, 3);
});

test("rejects a beta mission that does not allow the content type", async () => {
  const { firestore, handlers } = createHarness();
  await rejectsWithSafeCode(handlers.submitTesterFeedback(callableRequest(payload({
    contentType: "listening",
    betaMissionId: "beta_scenario",
  }))), "invalid-argument", "invalid-feedback-payload");
  assert.equal(firestore.transactionCount, 0);
  assert.deepEqual(firestore.writeHistory, []);
});

test("a mission can stamp only once across different completions", async () => {
  const { firestore, handlers } = createHarness();
  const first = await handlers.submitTesterFeedback(callableRequest());
  const second = await handlers.submitTesterFeedback(callableRequest(payload({
    feedbackId: "feedback-2",
    completionId: "completion-2",
  })));

  assert.equal(first.stampAccepted, true);
  assert.equal(second.accepted, true);
  assert.equal(second.stampAccepted, false);
  assert.deepEqual(second.passportCompletedMissionIds, ["beta_scenario"]);
  assert.deepEqual(
    firestore.value("users/anonymous-user/tester_passport/state")
      .completedMissionIds,
    ["beta_scenario"],
  );
  assert.equal(
    firestore.writeHistory.filter(
      ({ path }) => path.endsWith("/tester_passport/state"),
    ).length,
    1,
  );
  assert.deepEqual(firestore.paths(), [
    "users/anonymous-user/tester_feedback/completion-1",
    "users/anonymous-user/tester_feedback/completion-2",
    DEFAULT_RATE_LIMIT_PATH,
    "users/anonymous-user/tester_passport/state",
  ].sort());
});

test("the server mission allowlist matches every catalog content mapping", async (t) => {
  const expectedMappings = {
    beta_scenario: ["scenario"],
    beta_word_work: [
      "vocab_pack",
      "review",
      "custom_wordbook",
      "custom_wordbook_game",
      "legacy_vocab",
    ],
    beta_listening: ["listening"],
    beta_games: ["game"],
    beta_language_form: [
      "grammar_session",
      "hangul_cards",
      "hangul_writing",
      "daily_hangul",
    ],
  };
  assert.deepEqual(
    Object.fromEntries(MISSION_CATALOG.map((mission) => [
      mission.id,
      [...mission.allowedContentTypes],
    ])),
    expectedMappings,
  );

  let sequence = 0;
  for (const [missionId, contentTypes] of Object.entries(expectedMappings)) {
    for (const contentType of contentTypes) {
      await t.test(`${missionId} accepts ${contentType}`, async () => {
        sequence += 1;
        const { handlers } = createHarness();
        const result = await handlers.submitTesterFeedback(callableRequest(
          payload({
            feedbackId: `feedback-map-${sequence}`,
            completionId: `completion-map-${sequence}`,
            betaMissionId: missionId,
            contentType,
          }),
        ));
        assert.equal(result.stampAccepted, true);
      });
    }
  }
});
