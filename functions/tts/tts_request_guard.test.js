const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const {
  CALLABLE_OPTIONS,
  CircuitBreaker,
  DAILY_LIMIT_ACCOUNT,
  DAILY_LIMIT_GLOBAL,
  DAILY_LIMIT_INSTALLATION,
  TtsRequestError,
  abandonTtsReplay,
  claimTtsReplay,
  completeTtsReplay,
  isCurrentTtsReceipt,
  isUsableAudioBuffer,
  pendingTtsReceipt,
  quotaExpiresAt,
  refundDailyTtsQuotas,
  ttsLogErrorCode,
  ttsReplayId,
  ttsSynthesisPlan,
  underDailyTtsQuotas,
  validateTtsRequest,
  withDeadline,
} = require("./tts_request_guard");

const INSTALLATION_A = "c292226a-4c87-4e1f-98ef-21c76945cb65";
const INSTALLATION_B = "eb0fab89-b3e6-46c0-b6cb-03c48653e33d";

test("synthesis treats empty Storage objects as a miss and bounds Cloud TTS", () => {
  const source = fs.readFileSync(path.join(__dirname, "index.js"), "utf8");
  assert.match(source, /isUsableAudioBuffer/);
  assert.match(source, /withDeadline/);
  assert.match(source, /SYNTH_DEADLINE_MS/);
  assert.match(source, /empty TTS audio/);
  assert.match(source, /claimTtsReplay/);
  assert.match(source, /abandonTtsReplay/);
  assert.match(source, /ttsSynthesisPlan/);
  assert.match(source, /already in progress/);
  assert.match(source, /ttsLogErrorCode/);
  assert.doesNotMatch(source, /consume = true;/);
  assert.match(source, /console\.error\("synthesize_tts error", ttsLogErrorCode\(e\)\)/);
  assert.doesNotMatch(source, /console\.error\(\s*e\s*[,)]/);
});

test("expensive TTS callable enforces App Check and matches the 12s client", () => {
  assert.equal(CALLABLE_OPTIONS.enforceAppCheck, true);
  assert.equal(CALLABLE_OPTIONS.consumeAppCheckToken, true);
  assert.equal(CALLABLE_OPTIONS.timeoutSeconds, 12);
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

test("usage ledgers expire two UTC days after the counted day", async () => {
  const db = new FakeFirestore();
  const now = new Date("2026-08-16T10:00:00.000Z");
  await consume(db, {
    uid: "account-a",
    installationId: INSTALLATION_A,
    now,
  });

  const stored = [...db.documents.values()];
  assert.equal(stored.length, 3);
  for (const document of stored) {
    assert.deepEqual(document.expiresAt, quotaExpiresAt("2026-08-16"));
  }
  assert.deepEqual(
    quotaExpiresAt("2026-08-16"),
    new Date("2026-08-18T00:00:00.000Z"),
  );
});

test("refunds a reserved synthesis when the provider fails", async () => {
  const db = new FakeFirestore();
  const options = {
    uid: "account-a",
    installationId: INSTALLATION_A,
    now: new Date("2026-08-16T10:00:00.000Z"),
    limits: { installation: 2, account: 2, global: 2 },
  };
  assert.equal((await consume(db, options)).allowed, true);
  await refundDailyTtsQuotas(db, options);
  assert.equal((await consume(db, options)).allowed, true);
  assert.equal((await consume(db, options)).allowed, true);
  assert.deepEqual(await consume(db, options), {
    allowed: false,
    exceededScope: "installation",
  });
});

test("empty or non-buffer audio is never treated as a cache hit", () => {
  const mp3 = Buffer.alloc(32, 0);
  mp3[0] = 0xff;
  mp3[1] = 0xfb;
  const tagged = Buffer.alloc(32, 0);
  tagged.write("ID3", 0, "ascii");
  assert.equal(isUsableAudioBuffer(Buffer.alloc(0)), false);
  assert.equal(isUsableAudioBuffer(null), false);
  assert.equal(isUsableAudioBuffer(Buffer.from([0xff, 0xfb])), false);
  assert.equal(isUsableAudioBuffer(Buffer.alloc(32, 1)), false);
  assert.equal(isUsableAudioBuffer(mp3), true);
  assert.equal(isUsableAudioBuffer(tagged), true);
});

test("withDeadline rejects a hung synthesis before the client gives up", async () => {
  await assert.rejects(
    () => withDeadline(new Promise(() => {}), 20, "deadline"),
    (error) => error instanceof Error && error.message === "deadline",
  );
});

test("tts receipts hash the storage path and skip a second charge while pending", () => {
  const now = new Date("2026-08-17T00:00:00.000Z");
  const storagePath = "tts/v3/female/abc.mp3";
  const replayId = ttsReplayId(storagePath);
  assert.equal(replayId.length, 64);
  assert.equal(replayId.includes("female"), false);
  assert.notEqual(replayId, ttsReplayId("tts/v3/male/abc.mp3"));
  const pending = pendingTtsReceipt(now);
  assert.equal(isCurrentTtsReceipt(pending, now), true);
  assert.equal(
    isCurrentTtsReceipt(pending, new Date(now.getTime() + 16 * 60 * 1000)),
    false,
  );
});

test("a live pending claim is a lock: the loser does not reserve quota or synthesize", async () => {
  const db = new FakeFirestore();
  const storagePath = "tts/v3/female/abc.mp3";
  const first = await claimTtsReplay(db, storagePath);
  const second = await claimTtsReplay(db, storagePath);
  assert.deepEqual(first, { consume: true, state: "pending" });
  assert.deepEqual(second, { consume: false, state: "pending" });
  assert.deepEqual(ttsSynthesisPlan(first, false), { action: "synthesize" });
  assert.deepEqual(ttsSynthesisPlan(second, false), { action: "wait" });
  assert.deepEqual(ttsSynthesisPlan(first, true), {
    action: "return",
    refund: true,
  });
  assert.deepEqual(ttsSynthesisPlan(second, true), {
    action: "return",
    refund: false,
  });
  await completeTtsReplay(db, storagePath);
  const afterComplete = await claimTtsReplay(db, storagePath);
  assert.deepEqual(afterComplete, { consume: false, state: "completed" });
  assert.deepEqual(ttsSynthesisPlan(afterComplete, false), {
    action: "wait",
  });
});

test("loser poll covers the Cloud TTS deadline", () => {
  const indexSource = fs.readFileSync(path.join(__dirname, "index.js"), "utf8");
  assert.match(indexSource, /const INFLIGHT_POLL_ATTEMPTS = 14/);
  assert.match(indexSource, /const INFLIGHT_POLL_MS = 500/);
});

test("abandoning a pending claim lets the next retry reserve quota once", async () => {
  const db = new FakeFirestore();
  const storagePath = "tts/v3/female/abc.mp3";
  assert.equal((await claimTtsReplay(db, storagePath)).consume, true);
  await abandonTtsReplay(db, storagePath);
  assert.deepEqual(await claimTtsReplay(db, storagePath), {
    consume: true,
    state: "pending",
  });
});

test("error logs keep only a safe provider code, never request text", () => {
  assert.equal(ttsLogErrorCode(undefined), "internal");
  assert.equal(
    ttsLogErrorCode(new Error("Chirp3-HD-Zephyr 안녕하세요")),
    "internal",
  );
  assert.equal(
    ttsLogErrorCode({ code: "unavailable", message: "provider prompt" }),
    "unavailable",
  );
  assert.equal(ttsLogErrorCode({ code: "안녕하세요" }), "internal");
});

test("provider circuit opens after consecutive failures", () => {
  let now = 1_000;
  const breaker = new CircuitBreaker({
    failureThreshold: 2,
    cooldownMs: 30_000,
    now: () => now,
  });
  breaker.recordFailure();
  breaker.recordFailure();
  assert.equal(breaker.allow(), false);
  now = 31_000;
  assert.equal(breaker.allow(), true);
  breaker.recordSuccess();
  assert.equal(breaker.allow(), true);
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
      doc: (id) => ({
        path: `${name}/${id}`,
        set: async (data) => {
          this.documents.set(`${name}/${id}`, { ...data });
        },
      }),
    };
  }

  async runTransaction(callback) {
    const writes = [];
    const tx = {
      get: async (ref) => {
        const data = this.documents.get(ref.path);
        return {
          exists: data !== undefined,
          data: () => data,
        };
      },
      set: (ref, data) => writes.push({ type: "set", ref, data }),
      delete: (ref) => writes.push({ type: "delete", ref }),
    };
    const result = await callback(tx);
    for (const write of writes) {
      if (write.type === "delete") {
        this.documents.delete(write.ref.path);
      } else {
        this.documents.set(write.ref.path, { ...write.data });
      }
    }
    return result;
  }

  serialized() {
    return JSON.stringify([...this.documents.entries()].sort());
  }
}
