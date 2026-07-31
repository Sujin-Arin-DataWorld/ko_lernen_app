const assert = require("node:assert/strict");
const test = require("node:test");

const {
  CALLABLE_OPTIONS,
  TtsRequestError,
  validateTtsRequest,
} = require("./tts_request_guard");

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
      data: { text: " 안녕하세요 ", voice: "male" },
    }),
    { text: "안녕하세요", voice: "male" },
  );
});
