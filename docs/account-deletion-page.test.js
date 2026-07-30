"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  CONSUMPTION_ENDPOINT,
  consumeDeletionProof,
} = require("./account-deletion-page.js");

const VALID_PROOF = "A".repeat(43);

function browserHarness({
  hash = `#token=${VALID_PROOF}`,
  fetchImpl = async () => ({ status: 202 }),
} = {}) {
  const events = [];
  const rendered = [];
  return {
    events,
    rendered,
    options: {
      location: {
        hash,
        pathname: "/account-deletion.html",
        search: "",
      },
      history: {
        replaceState(state, title, url) {
          events.push({ type: "replaceState", state, title, url });
        },
      },
      async fetchImpl(url, init) {
        events.push({ type: "fetch", url, init });
        return fetchImpl(url, init);
      },
      renderStatus(status) {
        rendered.push(status);
      },
    },
  };
}

test("removes the fragment before posting the proof to the fixed first-party endpoint", async () => {
  const harness = browserHarness();

  await consumeDeletionProof(harness.options);

  assert.deepEqual(harness.events.map((event) => event.type), [
    "replaceState",
    "fetch",
  ]);
  assert.equal(harness.events[0].url, "/account-deletion.html");
  assert.equal(harness.events[1].url, CONSUMPTION_ENDPOINT);
  assert.equal(harness.events[1].init.method, "POST");
  assert.deepEqual(harness.events[1].init.headers, {
    "Content-Type": "application/json",
  });
  assert.deepEqual(JSON.parse(harness.events[1].init.body), {
    proof: VALID_PROOF,
  });
});

test("never renders a proof or raw network error", async () => {
  const secretBearingError = new Error(`backend rejected ${VALID_PROOF}`);
  const harness = browserHarness({
    fetchImpl: async () => {
      throw secretBearingError;
    },
  });

  await consumeDeletionProof(harness.options);

  assert.equal(harness.rendered.length, 1);
  assert.equal(harness.rendered[0], "request-unavailable");
  assert.equal(JSON.stringify(harness.rendered).includes(VALID_PROOF), false);
  assert.equal(JSON.stringify(harness.rendered).includes(secretBearingError.message), false);
});

test("renders the same generic receipt for valid, expired, and used proofs", async () => {
  for (const serverDetail of ["accepted", "expired", "already-used"]) {
    const harness = browserHarness({
      fetchImpl: async () => ({
        status: 202,
        body: { detail: serverDetail },
      }),
    });

    await consumeDeletionProof(harness.options);

    assert.deepEqual(harness.rendered, ["request-received"]);
  }
});

test("does not send a missing or malformed fragment value", async () => {
  for (const hash of ["", "#token=short", "#other=value"]) {
    const harness = browserHarness({ hash });

    await consumeDeletionProof(harness.options);

    assert.equal(
      harness.events.some((event) => event.type === "fetch"),
      false,
    );
    assert.deepEqual(harness.rendered, ["request-unavailable"]);
  }
});
