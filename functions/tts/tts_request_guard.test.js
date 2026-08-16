const assert = require("node:assert/strict");
const test = require("node:test");

const {
  CALLABLE_OPTIONS,
  DAILY_LIMIT_ACCOUNT,
  DAILY_LIMIT_GLOBAL,
  DAILY_LIMIT_INSTALLATION,
  TtsRequestError,
  underDailyTtsQuotas,
  validateTtsRequest,
} = require("./tts_request_guard");

const INSTALLATION_A = "c292226a-4c87-4e1f-98ef-21c76945cb65";
const INSTALLATION_B = "eb0fab89-b3e6-46c0-b6cb-03c48653e33d";

test("expensive TTS callable enforces App Check and consumes replay tokens", () => {
  assert.equal(CALLABLE_OPTIONS.enforceAppCheck, true);
  assert.equal(CALLABLE_OPTIONS.consumeAppCheckToken, true);
});

test("rejects anonymous callers before any synthesis work", () => {
  assert.throws(
    () => validateTtsRequest({ data: { text: "안녕하세요" } }),
    (error) => error instanceof TtsRequestError && error.code === "unauthenticated",
  );
});

test("rejects a replayed limited-use App Check token", () => {
  assert.throws(
    () => validateTtsRequest({
      auth: { uid: "tester" },
      app: { alreadyConsumed: true },
      data: { text: "안녕하세요" },
    }),
    (error) => error instanceof TtsRequestError && error.code === "failed-precondition",
  );
});

test("normalizes a valid authenticated request", () => {
  assert.deepEqual(
    validateTtsRequest({
      auth: { uid: "tester" },
      app: {},
      data: {
        text: " 안녕하세요 ",
        voice: "male",
        installationId: INSTALLATION_A.toUpperCase(),
      },
    }),
    {
      text: "안녕하세요",
      voice: "male",
      installationId: INSTALLATION_A,
    },
  );
});

test("keeps older app versions on a stable stricter legacy subject", () => {
  assert.deepEqual(
    validateTtsRequest({
      auth: { uid: "tester" },
      app: {},
      data: { text: "안녕하세요" },
    }),
    {
      text: "안녕하세요",
      voice: "female",
      installationId: "legacy:tester",
    },
  );
});

test("rejects malformed installation IDs", () => {
  assert.throws(
    () => validateTtsRequest({
      auth: { uid: "tester" },
      app: {},
      data: { text: "안녕하세요", installationId: "device-123" },
    }),
    (error) => error instanceof TtsRequestError && error.code === "invalid-argument",
  );
});

test("allows the 30th synthesis and atomically blocks the 31st per installation", async () => {
  const db = new FakeFirestore();
  for (let count = 0; count < DAILY_LIMIT_INSTALLATION; count += 1) {
    const result = await consume(db, { uid: "account-a", installationId: INSTALLATION_A });
    assert.equal(result.allowed, true);
  }
  const before = db.serialized();
  const blocked = await consume(db, {
    uid: "account-a",
    installationId: INSTALLATION_A,
  });

  assert.deepEqual(blocked, {
    allowed: false,
    exceededScope: "installation",
  });
  assert.equal(db.serialized(), before);
});

test("separate installations share the 50 synthesis account cap", async () => {
  const db = new FakeFirestore();
  for (let count = 0; count < DAILY_LIMIT_ACCOUNT / 2; count += 1) {
    assert.equal((await consume(db, {
      uid: "account-a",
      installationId: INSTALLATION_A,
    })).allowed, true);
    assert.equal((await consume(db, {
      uid: "account-a",
      installationId: INSTALLATION_B,
    })).allowed, true);
  }

  const blocked = await consume(db, {
    uid: "account-a",
    installationId: "029ff69d-1b66-445a-ac13-b415638faabd",
  });
  assert.deepEqual(blocked, { allowed: false, exceededScope: "account" });
});

test("all accounts share the 300 synthesis project cap", async () => {
  const db = new FakeFirestore();
  for (let account = 0; account < 6; account += 1) {
    for (let installation = 0; installation < 2; installation += 1) {
      for (let count = 0; count < 25; count += 1) {
        const result = await consume(db, {
          uid: `account-${account}`,
          installationId: uuidFor(account, installation),
        });
        assert.equal(result.allowed, true);
      }
    }
  }
  assert.equal(DAILY_LIMIT_GLOBAL, 300);

  const blocked = await consume(db, {
    uid: "account-final",
    installationId: "f70daeb0-6664-42b6-8125-b94fd3357063",
  });
  assert.deepEqual(blocked, { allowed: false, exceededScope: "global" });
});

test("UTC day rollover starts fresh counters", async () => {
  const db = new FakeFirestore();
  const limits = { installation: 1, account: 1, global: 1 };
  assert.equal((await consume(db, {
    uid: "account-a",
    installationId: INSTALLATION_A,
    now: new Date("2026-08-16T23:59:59.000Z"),
    limits,
  })).allowed, true);
  assert.equal((await consume(db, {
    uid: "account-a",
    installationId: INSTALLATION_A,
    now: new Date("2026-08-17T00:00:00.000Z"),
    limits,
  })).allowed, true);
});

function consume(db, options) {
  return underDailyTtsQuotas(db, options);
}

function uuidFor(account, installation) {
  const suffix = (account * 2 + installation + 1).toString(16).padStart(12, "0");
  return `10000000-0000-4000-8000-${suffix}`;
}

class FakeFirestore {
  constructor() {
    this.documents = new Map();
  }

  collection(name) {
    return {
      doc: (id) => ({ path: `${name}/${id}` }),
    };
  }

  async runTransaction(callback) {
    const writes = [];
    const tx = {
      get: async (ref) => ({
        data: () => this.documents.get(ref.path),
      }),
      set: (ref, data) => writes.push({ ref, data }),
    };
    const result = await callback(tx);
    for (const write of writes) {
      this.documents.set(write.ref.path, { ...write.data });
    }
    return result;
  }

  serialized() {
    return JSON.stringify([...this.documents.entries()].sort());
  }
}
