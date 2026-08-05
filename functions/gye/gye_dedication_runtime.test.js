"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  CALLABLE_OPTIONS,
  DEDICATION_RECEIPT_LIMIT,
  DEDICATION_SLOT_COUNT,
  createGyeDedicationCallable,
  createGyeDedicationRuntime,
} = require("./gye_dedication_runtime");

const SERVER_TIMESTAMP = Object.freeze({ kind: "server-timestamp" });
const SERVER_NOW_MILLIS = Date.UTC(2026, 7, 5, 1, 0, 0);
const GYE_ID = "ABC234";
const UID = "member-one";
const MEMBERSHIP_ID = "membership-member-one-0123456789abcdef";
const JOINED_AT_SECONDS = 1_754_355_200;
const JOINED_AT_NANOS = 123_000_000;
const REJOINED_AT_SECONDS = JOINED_AT_SECONDS + 60;
const REJOINED_AT_NANOS = 456_000_000;

const BASE_PAYLOAD = Object.freeze({
  gyeId: GYE_ID,
  expectedMembershipId: MEMBERSHIP_ID,
  expectedJoinedAtSeconds: JOINED_AT_SECONDS,
  expectedJoinedAtNanos: JOINED_AT_NANOS,
  decorationSlug: "decoration_chaekgado",
  expectedRevision: 0,
  operationId: "dedication-op-0001",
});

function callableRequest(data = BASE_PAYLOAD, {
  uid = UID,
  appId = "test-app-id",
  alreadyConsumed = false,
} = {}) {
  return {
    auth: uid == null ? undefined : { uid },
    app: appId == null ? undefined : { appId, alreadyConsumed },
    data,
  };
}

function payload(overrides = {}) {
  return { ...BASE_PAYLOAD, ...overrides };
}

function receiptFingerprint({
  membershipId = MEMBERSHIP_ID,
  joinedAtSeconds = JOINED_AT_SECONDS,
  joinedAtNanos = JOINED_AT_NANOS,
  decorationSlug = "decoration_chaekgado",
  expectedRevision = 0,
} = {}) {
  return `${GYE_ID}\u0000${membershipId}\u0000${joinedAtSeconds}\u0000${joinedAtNanos}\u0000${decorationSlug || ""}\u0000${expectedRevision}`;
}

function safeCallableError(status, safeCode) {
  const error = new Error("Gye dedication request failed.");
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

class FakeReference {
  constructor(path) {
    this.path = path;
    this.id = path.split("/").at(-1);
  }

  collection(name) {
    return new FakeCollection(`${this.path}/${name}`);
  }
}

class FakeCollection {
  constructor(path) {
    this.path = path;
  }

  doc(id) {
    return new FakeReference(`${this.path}/${id}`);
  }
}

class FakeFirestore {
  constructor(initial = {}) {
    this.documents = new Map(
      Object.entries(initial).map(([path, value]) => [path, clone(value)]),
    );
    this.readPaths = [];
  }

  collection(name) {
    return new FakeCollection(name);
  }

  doc(path) {
    return new FakeReference(path);
  }

  async runTransaction(callback) {
    const writes = [];
    const transaction = {
      get: async (target) => {
        this.readPaths.push(target.path);
        if (target instanceof FakeCollection) {
          const prefix = `${target.path}/`;
          const docs = [...this.documents.entries()]
            .filter(([path]) => {
              const remaining = path.slice(prefix.length);
              return path.startsWith(prefix) && !remaining.includes("/");
            })
            .sort(([left], [right]) => left.localeCompare(right))
            .map(([path, value]) => ({
              exists: true,
              id: path.split("/").at(-1),
              ref: new FakeReference(path),
              data: () => clone(value),
            }));
          return { docs, empty: docs.length === 0 };
        }
        const exists = this.documents.has(target.path);
        const value = exists ? clone(this.documents.get(target.path)) : null;
        return {
          exists,
          id: target.id,
          ref: target,
          data: () => clone(value),
        };
      },
      set: (reference, value, options) => {
        writes.push({ type: "set", reference, value: clone(value), options });
      },
      update: (reference, value) => {
        writes.push({ type: "update", reference, value: clone(value) });
      },
      delete: (reference) => {
        writes.push({ type: "delete", reference });
      },
    };
    const result = await callback(transaction);
    for (const write of writes) {
      const existing = this.documents.get(write.reference.path);
      if (write.type === "delete") {
        this.documents.delete(write.reference.path);
      } else if (write.type === "update") {
        if (!existing) throw new Error("cannot update missing document");
        this.documents.set(
          write.reference.path,
          { ...clone(existing), ...clone(write.value) },
        );
      } else if (write.options?.merge === true && existing) {
        this.documents.set(
          write.reference.path,
          { ...clone(existing), ...clone(write.value) },
        );
      } else {
        this.documents.set(write.reference.path, clone(write.value));
      }
    }
    return result;
  }

  value(path) {
    return clone(this.documents.get(path));
  }

  paths() {
    return [...this.documents.keys()].sort();
  }
}

function createHarness(initial = {}, {
  serverNowMillis = () => SERVER_NOW_MILLIS,
  throttleMillis,
} = {}) {
  const firestore = new FakeFirestore({
    [`gye/${GYE_ID}`]: { lifecycleState: "active" },
    [`gye/${GYE_ID}/members/${UID}`]: {
      membershipId: MEMBERSHIP_ID,
      status: "active",
      joinedAt: {
        seconds: JOINED_AT_SECONDS,
        nanoseconds: JOINED_AT_NANOS,
      },
    },
    ...initial,
  });
  const handlers = createGyeDedicationRuntime({
    firestore,
    serverTimestamp: () => SERVER_TIMESTAMP,
    serverNowMillis,
    makeError: safeCallableError,
    ...(throttleMillis === undefined ? {} : { throttleMillis }),
  });
  return { firestore, handlers };
}

function dedication({
  uid,
  membershipId = `membership-${uid}-0123456789abcdef`,
  joinedAtSeconds = JOINED_AT_SECONDS,
  joinedAtNanos = JOINED_AT_NANOS,
  decorationSlug = "decoration_chaekgado",
  slotIndex = 0,
  revision = 1,
  createdAt = SERVER_TIMESTAMP,
} = {}) {
  return {
    schemaVersion: 1,
    state: "active",
    uid,
    membershipId,
    joinedAtSeconds,
    joinedAtNanos,
    decorationSlug,
    slotIndex,
    revision,
    lastOperationId: "previous-operation-0001",
    createdAt,
    updatedAt: createdAt,
  };
}

test("creates a public exhibit without changing the member's private decor", async () => {
  const { firestore, handlers } = createHarness({
    [`users/${UID}`]: { progress: { owned_decor: ["decoration_chaekgado"] } },
  });

  const result = await handlers.setGyeDecorationDedication(
    callableRequest(),
  );

  assert.deepEqual(result, {
    state: "dedicated",
    decorationSlug: "decoration_chaekgado",
    slotIndex: 0,
    revision: 1,
  });
  assert.deepEqual(
    firestore.value(`gye/${GYE_ID}/decor_dedications/${UID}`),
    {
      schemaVersion: 1,
      state: "active",
      uid: UID,
      membershipId: MEMBERSHIP_ID,
      joinedAtSeconds: JOINED_AT_SECONDS,
      joinedAtNanos: JOINED_AT_NANOS,
      decorationSlug: "decoration_chaekgado",
      slotIndex: 0,
      revision: 1,
      lastOperationId: "dedication-op-0001",
      createdAt: SERVER_TIMESTAMP,
      updatedAt: SERVER_TIMESTAMP,
    },
  );
  assert.deepEqual(
    firestore.value(`users/${UID}`),
    { progress: { owned_decor: ["decoration_chaekgado"] } },
  );
  assert.deepEqual(
    firestore.value(`gye/${GYE_ID}/decor_dedication_mutations/${UID}`),
    {
      schemaVersion: 3,
      uid: UID,
      membershipId: MEMBERSHIP_ID,
      joinedAtSeconds: JOINED_AT_SECONDS,
      joinedAtNanos: JOINED_AT_NANOS,
      lastOperationId: "dedication-op-0001",
      operationReceipts: [
        {
          operationId: "dedication-op-0001",
          payloadFingerprint: receiptFingerprint(),
          result: {
            state: "dedicated",
            decorationSlug: "decoration_chaekgado",
            slotIndex: 0,
            revision: 1,
          },
        },
      ],
      lastAcceptedAtMillis: SERVER_NOW_MILLIS,
      updatedAt: SERVER_TIMESTAMP,
    },
  );
  assert.equal(
    firestore.readPaths.includes(`users/${UID}`),
    false,
    "P4b is an exhibition record; it never reads or transfers private decor",
  );
});

test("registers the callable with the exact App Check protected v2 options", () => {
  const registrations = [];

  createGyeDedicationCallable({
    handler: async () => ({}),
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
});

test("rejects missing Auth or App Check before reading Gye state", async () => {
  const { handlers } = createHarness();

  await rejectsWithSafeCode(
    handlers.setGyeDecorationDedication(callableRequest(BASE_PAYLOAD, { uid: null })),
    "unauthenticated",
    "authentication-required",
  );
  await rejectsWithSafeCode(
    handlers.setGyeDecorationDedication(callableRequest(BASE_PAYLOAD, { appId: null })),
    "failed-precondition",
    "app-check-required",
  );
  await rejectsWithSafeCode(
    handlers.setGyeDecorationDedication(
      callableRequest(BASE_PAYLOAD, { alreadyConsumed: true }),
    ),
    "resource-exhausted",
    "app-check-token-consumed",
  );
});

test("rejects non-canonical Gye ids, unknown decoration slugs, and extra keys", async () => {
  const { handlers } = createHarness();

  for (const invalid of [
    payload({ gyeId: "ABC123" }),
    payload({ decorationSlug: "decoration_pond" }),
    payload({ expectedMembershipId: ` ${MEMBERSHIP_ID}` }),
    payload({ expectedMembershipId: `${MEMBERSHIP_ID} ` }),
    payload({ expectedJoinedAtSeconds: -1 }),
    payload({ expectedJoinedAtNanos: 1000000000 }),
    {
      gyeId: GYE_ID,
      decorationSlug: "decoration_chaekgado",
      expectedRevision: 0,
      operationId: "dedication-op-0001",
    },
    { ...payload(), unexpected: true },
  ]) {
    await rejectsWithSafeCode(
      handlers.setGyeDecorationDedication(callableRequest(invalid)),
      "invalid-argument",
      "invalid-dedication-payload",
    );
  }
});

test("uses the first unoccupied slot and retains a member's slot on replacement", async () => {
  const originalCreatedAt = { kind: "original-created-at" };
  const { firestore, handlers } = createHarness({
    [`gye/${GYE_ID}/decor_dedications/a-member`]: dedication({
      uid: "a-member",
      slotIndex: 0,
    }),
    [`gye/${GYE_ID}/decor_dedications/z-member`]: dedication({
      uid: "z-member",
      slotIndex: 2,
    }),
    [`gye/${GYE_ID}/decor_dedications/${UID}`]: dedication({
      uid: UID,
      membershipId: MEMBERSHIP_ID,
      slotIndex: 7,
      revision: 4,
      createdAt: originalCreatedAt,
    }),
  });

  const replaced = await handlers.setGyeDecorationDedication(
    callableRequest(payload({
      decorationSlug: "decoration_seoan",
      expectedRevision: 4,
      operationId: "dedication-op-0002",
    })),
  );

  assert.deepEqual(replaced, {
    state: "dedicated",
    decorationSlug: "decoration_seoan",
    slotIndex: 7,
    revision: 5,
  });
  assert.deepEqual(
    firestore.value(`gye/${GYE_ID}/decor_dedications/${UID}`).createdAt,
    originalCreatedAt,
  );

  const { handlers: secondHandlers } = createHarness({
    [`gye/${GYE_ID}/decor_dedications/a-member`]: dedication({
      uid: "a-member",
      slotIndex: 0,
    }),
    [`gye/${GYE_ID}/decor_dedications/z-member`]: dedication({
      uid: "z-member",
      slotIndex: 2,
    }),
    [`gye/${GYE_ID}/decor_dedications/withdrawn-member`]: {
      schemaVersion: 1,
      state: "withdrawn",
      uid: "withdrawn-member",
      membershipId: "membership-withdrawn-member-0123456789",
      decorationSlug: null,
      slotIndex: null,
      revision: 4,
      lastOperationId: "dedication-op-withdrawn-0001",
    },
  });
  const created = await secondHandlers.setGyeDecorationDedication(
    callableRequest(payload({ operationId: "dedication-op-0003" })),
  );
  assert.equal(created.slotIndex, 1);
});

test("returns a prior outcome for the same operation and rejects a payload collision", async () => {
  const { firestore, handlers } = createHarness();
  const first = await handlers.setGyeDecorationDedication(callableRequest());
  const replay = await handlers.setGyeDecorationDedication(callableRequest());

  assert.deepEqual(replay, first);
  await rejectsWithSafeCode(
    handlers.setGyeDecorationDedication(
      callableRequest(payload({ decorationSlug: "decoration_seoan" })),
    ),
    "already-exists",
    "dedication-operation-collision",
  );
  assert.equal(
    firestore.value(`gye/${GYE_ID}/decor_dedications/${UID}`).decorationSlug,
    "decoration_chaekgado",
  );
});

test("keeps a bounded ordered receipt ring, replays retained work, and rejects evicted stale work", async () => {
  const { firestore, handlers } = createHarness({}, { throttleMillis: 0 });
  const firstRequest = payload({ operationId: "dedication-op-ring-first" });
  const first = await handlers.setGyeDecorationDedication(
    callableRequest(firstRequest),
  );
  let retainedRequest;
  let retainedOutcome;
  for (let index = 0; index < DEDICATION_RECEIPT_LIMIT; index += 1) {
    retainedRequest = payload({
      expectedRevision: 1,
      operationId: `dedication-op-ring-${String(index).padStart(4, "0")}`,
    });
    retainedOutcome = await handlers.setGyeDecorationDedication(
      callableRequest(retainedRequest),
    );
  }

  const mutation = firestore.value(
    `gye/${GYE_ID}/decor_dedication_mutations/${UID}`,
  );
  assert.ok(Array.isArray(mutation.operationReceipts));
  assert.equal(mutation.operationReceipts.length, DEDICATION_RECEIPT_LIMIT);
  assert.equal(
    mutation.operationReceipts[0].operationId,
    "dedication-op-ring-0000",
  );
  assert.equal(
    mutation.operationReceipts.at(-1).operationId,
    "dedication-op-ring-0015",
  );
  assert.equal(
    mutation.operationReceipts.some(
      (entry) => entry.operationId === firstRequest.operationId,
    ),
    false,
  );

  const replay = await handlers.setGyeDecorationDedication(
    callableRequest(retainedRequest),
  );
  assert.deepEqual(replay, retainedOutcome);
  await rejectsWithSafeCode(
    handlers.setGyeDecorationDedication(callableRequest(firstRequest)),
    "aborted",
    "dedication-revision-conflict",
  );
  assert.deepEqual(first, {
    state: "dedicated",
    decorationSlug: "decoration_chaekgado",
    slotIndex: 0,
    revision: 1,
  });
});

test("a withdrawal tombstone defeats ABA while an old operation replays its stored outcome", async () => {
  const { firestore, handlers } = createHarness({}, { throttleMillis: 0 });
  const dedicateA = payload({ operationId: "dedication-op-aba-a" });
  const first = await handlers.setGyeDecorationDedication(
    callableRequest(dedicateA),
  );
  const withdrawB = payload({
    decorationSlug: null,
    expectedRevision: 1,
    operationId: "dedication-op-aba-b",
  });
  const withdrawn = await handlers.setGyeDecorationDedication(
    callableRequest(withdrawB),
  );

  assert.deepEqual(withdrawn, {
    state: "withdrawn",
    decorationSlug: null,
    slotIndex: null,
    revision: 2,
  });
  assert.equal(
    firestore.value(`gye/${GYE_ID}/decor_dedications/${UID}`).state,
    "withdrawn",
  );

  const replay = await handlers.setGyeDecorationDedication(
    callableRequest(dedicateA),
  );
  assert.deepEqual(replay, first);
  assert.deepEqual(
    firestore.value(`gye/${GYE_ID}/decor_dedications/${UID}`),
    {
      schemaVersion: 1,
      state: "withdrawn",
      uid: UID,
      membershipId: MEMBERSHIP_ID,
      joinedAtSeconds: JOINED_AT_SECONDS,
      joinedAtNanos: JOINED_AT_NANOS,
      decorationSlug: null,
      slotIndex: null,
      revision: 2,
      lastOperationId: "dedication-op-aba-b",
      createdAt: SERVER_TIMESTAMP,
      updatedAt: SERVER_TIMESTAMP,
    },
  );
});

test("rejects malformed idempotent receipts instead of returning an impossible state", async () => {
  const fingerprint = receiptFingerprint();
  const malformedOutcomes = [
    {
      state: "dedicated",
      decorationSlug: null,
      slotIndex: null,
      revision: 0,
    },
    {
      state: "withdrawn",
      decorationSlug: "decoration_chaekgado",
      slotIndex: 0,
      revision: 1,
    },
    {
      state: "unchanged",
      decorationSlug: "decoration_chaekgado",
      slotIndex: null,
      revision: 1,
    },
  ];

  for (const result of malformedOutcomes) {
    const { handlers } = createHarness({
      [`gye/${GYE_ID}/decor_dedication_mutations/${UID}`]: {
        schemaVersion: 3,
        uid: UID,
        membershipId: MEMBERSHIP_ID,
        joinedAtSeconds: JOINED_AT_SECONDS,
        joinedAtNanos: JOINED_AT_NANOS,
        lastOperationId: BASE_PAYLOAD.operationId,
        operationReceipts: [
          {
            operationId: BASE_PAYLOAD.operationId,
            payloadFingerprint: fingerprint,
            result,
          },
        ],
      },
    });
    await rejectsWithSafeCode(
      handlers.setGyeDecorationDedication(callableRequest()),
      "failed-precondition",
      "dedication-receipt-invalid",
    );
  }
});

test("fails closed when a retained receipt ledger contains an unrelated corrupt entry", async () => {
  const fingerprint = receiptFingerprint();
  const validResult = {
    state: "dedicated",
    decorationSlug: "decoration_chaekgado",
    slotIndex: 0,
    revision: 1,
  };
  const { handlers } = createHarness({
    [`gye/${GYE_ID}/decor_dedication_mutations/${UID}`]: {
      schemaVersion: 2,
      uid: UID,
      membershipId: MEMBERSHIP_ID,
      joinedAtSeconds: JOINED_AT_SECONDS,
      joinedAtNanos: JOINED_AT_NANOS,
      operationReceipts: {
        ZGVkaWNhdGlvbi1vcC0wMDAx: {
          operationId: BASE_PAYLOAD.operationId,
          payloadFingerprint: fingerprint,
          result: validResult,
        },
        constructor: {
          operationId: "dedication-op-corrupt",
          payloadFingerprint: fingerprint,
          result: {
            state: "dedicated",
            decorationSlug: null,
            slotIndex: null,
            revision: 0,
          },
        },
      },
    },
  });

  await rejectsWithSafeCode(
    handlers.setGyeDecorationDedication(callableRequest()),
    "failed-precondition",
    "dedication-receipt-invalid",
  );
});

test("validates every entry in a bounded receipt array before replaying any entry", async () => {
  const fingerprint = receiptFingerprint();
  const { handlers } = createHarness({
    [`gye/${GYE_ID}/decor_dedication_mutations/${UID}`]: {
      schemaVersion: 3,
      uid: UID,
      membershipId: MEMBERSHIP_ID,
      joinedAtSeconds: JOINED_AT_SECONDS,
      joinedAtNanos: JOINED_AT_NANOS,
      lastOperationId: "dedication-op-corrupt",
      operationReceipts: [
        {
          operationId: BASE_PAYLOAD.operationId,
          payloadFingerprint: fingerprint,
          result: {
            state: "dedicated",
            decorationSlug: "decoration_chaekgado",
            slotIndex: 0,
            revision: 1,
          },
        },
        {
          operationId: "dedication-op-corrupt",
          payloadFingerprint: fingerprint,
          result: {
            state: "dedicated",
            decorationSlug: null,
            slotIndex: null,
            revision: 0,
          },
        },
      ],
    },
  });

  await rejectsWithSafeCode(
    handlers.setGyeDecorationDedication(callableRequest()),
    "failed-precondition",
    "dedication-receipt-invalid",
  );
});

test("fails closed instead of discarding a malformed current-generation legacy receipt", async () => {
  const { handlers } = createHarness({
    [`gye/${GYE_ID}/decor_dedication_mutations/${UID}`]: {
      uid: UID,
      membershipId: MEMBERSHIP_ID,
      joinedAtSeconds: JOINED_AT_SECONDS,
      joinedAtNanos: JOINED_AT_NANOS,
      lastOperationId: "dedication-op-incomplete-legacy",
    },
  });

  await rejectsWithSafeCode(
    handlers.setGyeDecorationDedication(callableRequest()),
    "failed-precondition",
    "dedication-receipt-invalid",
  );
});

test("rejects a stale active-document revision instead of changing the exhibit", async () => {
  const { firestore, handlers } = createHarness({
    [`gye/${GYE_ID}/decor_dedications/${UID}`]: dedication({
      uid: UID,
      membershipId: MEMBERSHIP_ID,
      slotIndex: 3,
      revision: 2,
    }),
  });

  await rejectsWithSafeCode(
    handlers.setGyeDecorationDedication(
      callableRequest(payload({
        decorationSlug: "decoration_seoan",
        expectedRevision: 1,
        operationId: "dedication-op-0004",
      })),
    ),
    "aborted",
    "dedication-revision-conflict",
  );
  assert.equal(
    firestore.value(`gye/${GYE_ID}/decor_dedications/${UID}`).revision,
    2,
  );
});

test("fails closed when the caller's active exhibit is structurally invalid", async () => {
  const { handlers } = createHarness({
    [`gye/${GYE_ID}/decor_dedications/${UID}`]: dedication({
      uid: UID,
      membershipId: MEMBERSHIP_ID,
      slotIndex: 12,
      revision: 2,
    }),
  });

  await rejectsWithSafeCode(
    handlers.setGyeDecorationDedication(
      callableRequest(payload({
        expectedRevision: 2,
        operationId: "dedication-op-0004b",
      })),
    ),
    "failed-precondition",
    "dedication-state-invalid",
  );
});

test("withdrawal writes a monotonic non-rendering tombstone and preserves personal ownership", async () => {
  const { firestore, handlers } = createHarness({
    [`users/${UID}`]: { progress: { owned_decor: ["decoration_chaekgado"] } },
    [`gye/${GYE_ID}/decor_dedications/${UID}`]: dedication({
      uid: UID,
      membershipId: MEMBERSHIP_ID,
      slotIndex: 4,
      revision: 3,
    }),
  });

  const result = await handlers.setGyeDecorationDedication(
    callableRequest(payload({
      decorationSlug: null,
      expectedRevision: 3,
      operationId: "dedication-op-0005",
    })),
  );

  assert.deepEqual(result, {
    state: "withdrawn",
    decorationSlug: null,
    slotIndex: null,
    revision: 4,
  });
  assert.deepEqual(
    firestore.value(`gye/${GYE_ID}/decor_dedications/${UID}`),
    {
      schemaVersion: 1,
      state: "withdrawn",
      uid: UID,
      membershipId: MEMBERSHIP_ID,
      joinedAtSeconds: JOINED_AT_SECONDS,
      joinedAtNanos: JOINED_AT_NANOS,
      decorationSlug: null,
      slotIndex: null,
      revision: 4,
      lastOperationId: "dedication-op-0005",
      createdAt: SERVER_TIMESTAMP,
      updatedAt: SERVER_TIMESTAMP,
    },
  );
  assert.deepEqual(
    firestore.value(`users/${UID}`),
    { progress: { owned_decor: ["decoration_chaekgado"] } },
  );
});

test("backfills the creation timestamp when withdrawing a legacy active exhibit", async () => {
  const legacy = dedication({
    uid: UID,
    membershipId: MEMBERSHIP_ID,
    slotIndex: 4,
    revision: 1,
  });
  delete legacy.createdAt;
  delete legacy.updatedAt;
  const { firestore, handlers } = createHarness({
    [`gye/${GYE_ID}/decor_dedications/${UID}`]: legacy,
  });

  await handlers.setGyeDecorationDedication(
    callableRequest(payload({
      decorationSlug: null,
      expectedRevision: 1,
      operationId: "dedication-op-withdraw-legacy-active",
    })),
  );

  assert.deepEqual(
    firestore.value(`gye/${GYE_ID}/decor_dedications/${UID}`).createdAt,
    SERVER_TIMESTAMP,
  );
});

test("replaces a valid tombstone without giving it a rendered slot", async () => {
  const originalCreatedAt = { kind: "original-created-at" };
  const { firestore, handlers } = createHarness({
    [`gye/${GYE_ID}/decor_dedications/${UID}`]: {
      schemaVersion: 1,
      state: "withdrawn",
      uid: UID,
      membershipId: MEMBERSHIP_ID,
      joinedAtSeconds: JOINED_AT_SECONDS,
      joinedAtNanos: JOINED_AT_NANOS,
      decorationSlug: null,
      slotIndex: null,
      revision: 2,
      lastOperationId: "dedication-op-before-tombstone",
      createdAt: originalCreatedAt,
    },
  });

  const result = await handlers.setGyeDecorationDedication(
    callableRequest(payload({
      decorationSlug: "decoration_seoan",
      expectedRevision: 2,
      operationId: "dedication-op-after-tombstone",
    })),
  );

  assert.deepEqual(result, {
    state: "dedicated",
    decorationSlug: "decoration_seoan",
    slotIndex: 0,
    revision: 3,
  });
  assert.deepEqual(
    firestore.value(`gye/${GYE_ID}/decor_dedications/${UID}`).createdAt,
    originalCreatedAt,
  );
});

test("fails closed on an impossible revision-one tombstone", async () => {
  const { handlers } = createHarness({
    [`gye/${GYE_ID}/decor_dedications/${UID}`]: {
      schemaVersion: 1,
      state: "withdrawn",
      uid: UID,
      membershipId: MEMBERSHIP_ID,
      joinedAtSeconds: JOINED_AT_SECONDS,
      joinedAtNanos: JOINED_AT_NANOS,
      decorationSlug: null,
      slotIndex: null,
      revision: 1,
      lastOperationId: "dedication-op-impossible-tombstone",
    },
  });

  await rejectsWithSafeCode(
    handlers.setGyeDecorationDedication(
      callableRequest(payload({
        expectedRevision: 1,
        operationId: "dedication-op-after-impossible-tombstone",
      })),
    ),
    "failed-precondition",
    "dedication-state-invalid",
  );
});

test("does not let a stale prior membership occupy a rejoined member's exhibit", async () => {
  const newMembershipId = "membership-member-one-rejoined-0123456789";
  const { firestore, handlers } = createHarness({
    [`gye/${GYE_ID}/members/${UID}`]: {
      membershipId: newMembershipId,
      status: "active",
      joinedAt: {
        seconds: REJOINED_AT_SECONDS,
        nanoseconds: REJOINED_AT_NANOS,
      },
    },
    [`gye/${GYE_ID}/decor_dedications/${UID}`]: dedication({
      uid: UID,
      membershipId: MEMBERSHIP_ID,
      slotIndex: 6,
      revision: 9,
    }),
  });

  const result = await handlers.setGyeDecorationDedication(
    callableRequest(payload({
      expectedMembershipId: newMembershipId,
      expectedJoinedAtSeconds: REJOINED_AT_SECONDS,
      expectedJoinedAtNanos: REJOINED_AT_NANOS,
      operationId: "dedication-op-0006",
    })),
  );

  assert.deepEqual(result, {
    state: "dedicated",
    decorationSlug: "decoration_chaekgado",
    slotIndex: 0,
    revision: 1,
  });
  assert.equal(
    firestore.value(`gye/${GYE_ID}/decor_dedications/${UID}`).membershipId,
    newMembershipId,
  );
});

test("a delayed prior-membership request cannot create an exhibit after rejoin", async () => {
  const newMembershipId = "membership-member-one-rejoined-0123456789";
  const { firestore, handlers } = createHarness({
    [`gye/${GYE_ID}/members/${UID}`]: {
      membershipId: newMembershipId,
      status: "active",
      joinedAt: {
        seconds: REJOINED_AT_SECONDS,
        nanoseconds: REJOINED_AT_NANOS,
      },
    },
  });

  await rejectsWithSafeCode(
    handlers.setGyeDecorationDedication(callableRequest(payload({
      expectedMembershipId: MEMBERSHIP_ID,
      operationId: "dedication-op-old-membership",
    }))),
    "aborted",
    "dedication-membership-conflict",
  );
  assert.equal(
    firestore.value(`gye/${GYE_ID}/decor_dedications/${UID}`),
    undefined,
  );
});

test("M1 leave M2 leave then rejoin M1 cannot revive a delayed prior M1 request", async () => {
  const { firestore, handlers } = createHarness({
    [`gye/${GYE_ID}/members/${UID}`]: {
      membershipId: MEMBERSHIP_ID,
      status: "active",
      joinedAt: {
        seconds: REJOINED_AT_SECONDS,
        nanoseconds: REJOINED_AT_NANOS,
      },
    },
    [`gye/${GYE_ID}/decor_dedications/${UID}`]: dedication({
      uid: UID,
      membershipId: MEMBERSHIP_ID,
      joinedAtSeconds: JOINED_AT_SECONDS,
      joinedAtNanos: JOINED_AT_NANOS,
      slotIndex: 6,
      revision: 4,
    }),
    [`gye/${GYE_ID}/decor_dedication_mutations/${UID}`]: {
      schemaVersion: 3,
      uid: UID,
      membershipId: MEMBERSHIP_ID,
      joinedAtSeconds: JOINED_AT_SECONDS,
      joinedAtNanos: JOINED_AT_NANOS,
      lastOperationId: "dedication-op-old-m1",
      operationReceipts: [
        {
          operationId: "dedication-op-old-m1",
          payloadFingerprint: receiptFingerprint({
            joinedAtSeconds: JOINED_AT_SECONDS,
            joinedAtNanos: JOINED_AT_NANOS,
          }),
          result: {
            state: "dedicated",
            decorationSlug: "decoration_chaekgado",
            slotIndex: 6,
            revision: 4,
          },
        },
      ],
      lastAcceptedAtMillis: SERVER_NOW_MILLIS,
    },
  });
  const delayedM1 = {
    ...payload({ operationId: "dedication-op-reused-membership-id" }),
    expectedJoinedAtSeconds: JOINED_AT_SECONDS,
    expectedJoinedAtNanos: JOINED_AT_NANOS,
  };

  await rejectsWithSafeCode(
    handlers.setGyeDecorationDedication(callableRequest(delayedM1)),
    "aborted",
    "dedication-join-epoch-conflict",
  );
  assert.equal(
    firestore.value(`gye/${GYE_ID}/decor_dedications/${UID}`)
      .joinedAtSeconds,
    JOINED_AT_SECONDS,
  );

  const currentM3 = await handlers.setGyeDecorationDedication(
    callableRequest(payload({
      expectedJoinedAtSeconds: REJOINED_AT_SECONDS,
      expectedJoinedAtNanos: REJOINED_AT_NANOS,
      operationId: "dedication-op-current-m3",
    })),
  );
  assert.deepEqual(currentM3, {
    state: "dedicated",
    decorationSlug: "decoration_chaekgado",
    slotIndex: 0,
    revision: 1,
  });
  assert.equal(
    firestore.value(`gye/${GYE_ID}/decor_dedications/${UID}`)
      .joinedAtSeconds,
    REJOINED_AT_SECONDS,
  );
  assert.equal(
    firestore.value(`gye/${GYE_ID}/decor_dedication_mutations/${UID}`)
      .joinedAtNanos,
    REJOINED_AT_NANOS,
  );
});

test("a record with the wrong uid is stale even when membership and epoch match", async () => {
  const { firestore, handlers } = createHarness({
    [`gye/${GYE_ID}/decor_dedications/${UID}`]: dedication({
      uid: "other-member",
      membershipId: MEMBERSHIP_ID,
      joinedAtSeconds: JOINED_AT_SECONDS,
      joinedAtNanos: JOINED_AT_NANOS,
      slotIndex: 6,
      revision: 4,
    }),
    [`gye/${GYE_ID}/decor_dedication_mutations/${UID}`]: {
      schemaVersion: 3,
      uid: "other-member",
      membershipId: MEMBERSHIP_ID,
      joinedAtSeconds: JOINED_AT_SECONDS,
      joinedAtNanos: JOINED_AT_NANOS,
      lastOperationId: "dedication-op-foreign-uid",
      operationReceipts: [],
      lastAcceptedAtMillis: SERVER_NOW_MILLIS,
    },
  });

  const outcome = await handlers.setGyeDecorationDedication(
    callableRequest(payload({ operationId: "dedication-op-rebase-uid" })),
  );

  assert.deepEqual(outcome, {
    state: "dedicated",
    decorationSlug: "decoration_chaekgado",
    slotIndex: 0,
    revision: 1,
  });
  const exhibit = firestore.value(`gye/${GYE_ID}/decor_dedications/${UID}`);
  const mutation = firestore.value(
    `gye/${GYE_ID}/decor_dedication_mutations/${UID}`,
  );
  assert.equal(exhibit.uid, UID);
  assert.equal(exhibit.revision, 1);
  assert.equal(mutation.uid, UID);
  assert.equal(mutation.joinedAtSeconds, JOINED_AT_SECONDS);
  assert.equal(mutation.joinedAtNanos, JOINED_AT_NANOS);
});

test("a legacy record without an immutable epoch is safely rebased", async () => {
  const legacyExhibit = dedication({
    uid: UID,
    membershipId: MEMBERSHIP_ID,
    slotIndex: 6,
    revision: 4,
  });
  delete legacyExhibit.joinedAtSeconds;
  delete legacyExhibit.joinedAtNanos;
  const { firestore, handlers } = createHarness({
    [`gye/${GYE_ID}/decor_dedications/${UID}`]: legacyExhibit,
    [`gye/${GYE_ID}/decor_dedication_mutations/${UID}`]: {
      schemaVersion: 3,
      uid: UID,
      membershipId: MEMBERSHIP_ID,
      lastOperationId: "dedication-op-legacy-epoch",
      operationReceipts: [],
      lastAcceptedAtMillis: SERVER_NOW_MILLIS,
    },
  });

  const outcome = await handlers.setGyeDecorationDedication(
    callableRequest(payload({ operationId: "dedication-op-rebase-epoch" })),
  );

  assert.equal(outcome.revision, 1);
  assert.equal(
    firestore.value(`gye/${GYE_ID}/decor_dedications/${UID}`)
      .joinedAtSeconds,
    JOINED_AT_SECONDS,
  );
  assert.equal(
    firestore.value(`gye/${GYE_ID}/decor_dedication_mutations/${UID}`)
      .joinedAtNanos,
    JOINED_AT_NANOS,
  );
});

test("a structurally valid legacy active exhibit without state remains replaceable", async () => {
  const legacy = dedication({
    uid: UID,
    membershipId: MEMBERSHIP_ID,
    slotIndex: 3,
    revision: 2,
  });
  delete legacy.state;
  const { firestore, handlers } = createHarness({
    [`gye/${GYE_ID}/decor_dedications/${UID}`]: legacy,
  });

  const result = await handlers.setGyeDecorationDedication(
    callableRequest(payload({
      decorationSlug: "decoration_seoan",
      expectedRevision: 2,
      operationId: "dedication-op-legacy-active",
    })),
  );

  assert.equal(result.revision, 3);
  assert.equal(
    firestore.value(`gye/${GYE_ID}/decor_dedications/${UID}`).state,
    "active",
  );
});

test("caps the courtyard at ten occupied slots and throttles only a new mutation", async () => {
  const full = Object.fromEntries(Array.from(
    { length: DEDICATION_SLOT_COUNT },
    (_, slotIndex) => [
      `gye/${GYE_ID}/decor_dedications/other-${slotIndex}`,
      dedication({ uid: `other-${slotIndex}`, slotIndex }),
    ],
  ));
  const { handlers: fullHandlers } = createHarness(full);
  await rejectsWithSafeCode(
    fullHandlers.setGyeDecorationDedication(callableRequest()),
    "resource-exhausted",
    "dedication-slots-full",
  );

  const { handlers } = createHarness({
    [`gye/${GYE_ID}/decor_dedication_mutations/${UID}`]: {
      schemaVersion: 3,
      uid: UID,
      membershipId: MEMBERSHIP_ID,
      joinedAtSeconds: JOINED_AT_SECONDS,
      joinedAtNanos: JOINED_AT_NANOS,
      lastOperationId: "previous-operation-0002",
      operationReceipts: [
        {
          operationId: "previous-operation-0002",
          payloadFingerprint: receiptFingerprint(),
          result: {
            state: "dedicated",
            decorationSlug: "decoration_chaekgado",
            slotIndex: 0,
            revision: 1,
          },
        },
      ],
      lastAcceptedAtMillis: SERVER_NOW_MILLIS - 1,
    },
  });
  await rejectsWithSafeCode(
    handlers.setGyeDecorationDedication(callableRequest()),
    "resource-exhausted",
    "dedication-throttled",
  );
});

test("requires an active, unbanned member with no active account deletion", async () => {
  const cases = [
    {
      initial: { [`gye/${GYE_ID}`]: { lifecycleState: "deleting" } },
      status: "failed-precondition",
      code: "gye-not-active",
    },
    {
      initial: { [`gye/${GYE_ID}/members/${UID}`]: { status: "suspended" } },
      status: "permission-denied",
      code: "gye-membership-inactive",
    },
    {
      initial: {
        [`gye/${GYE_ID}/members/${UID}`]: {
          membershipId: MEMBERSHIP_ID,
          status: "active",
        },
      },
      status: "permission-denied",
      code: "gye-membership-inactive",
    },
    {
      initial: { [`gye/${GYE_ID}/bans/${UID}`]: { active: true } },
      status: "permission-denied",
      code: "gye-member-banned",
    },
    {
      initial: { [`gye/${GYE_ID}/bans/${UID}`]: { active: false } },
      status: "permission-denied",
      code: "gye-member-banned",
    },
    {
      initial: { [`account_deletions/${UID}`]: { state: "pending" } },
      status: "failed-precondition",
      code: "account-deletion-active",
    },
  ];

  for (const invalid of cases) {
    const { handlers } = createHarness(invalid.initial);
    await rejectsWithSafeCode(
      handlers.setGyeDecorationDedication(callableRequest()),
      invalid.status,
      invalid.code,
    );
  }
});
