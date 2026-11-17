"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const source = fs.readFileSync(path.join(__dirname, "smoke_test.js"), "utf8");

function probe(env, args) {
  let imports = 0;
  let failure;
  try {
    vm.runInNewContext(source, {
      process: {env, argv: ["node", "smoke_test.js", ...args]},
      require: () => { imports++; throw new Error("SDK_BOUNDARY_REACHED"); },
    });
  } catch (error) { failure = error; }
  return {imports, failure};
}

test("production smoke refuses automatic discovery and missing explicit approval before SDK access", () => {
  for (const [env, args] of [
    [{}, []], [{GCLOUD_PROJECT: "test-project"}, []],
    [{}, ["--allow-production-smoke"]],
    [{GCLOUD_PROJECT: "test-project", NODE_TEST_CONTEXT: "child-v8"}, ["--allow-production-smoke"]],
  ]) {
    const result = probe(env, args);
    assert.equal(result.imports, 0);
    assert.match(result.failure.message, /Production smoke requires explicit/);
  }
});

test("explicit standalone smoke reaches the SDK boundary with no real SDK or network in this test", () => {
  const result = probe({GCLOUD_PROJECT: "test-project"}, ["--allow-production-smoke"]);
  assert.equal(result.imports, 1);
  assert.match(result.failure.message, /SDK_BOUNDARY_REACHED/);
});
