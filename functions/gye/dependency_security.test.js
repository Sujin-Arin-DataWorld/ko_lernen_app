"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const qs = require("qs");
const uuid = require("uuid");

test("query string roundtrip cannot invoke attacker-controlled isBuffer", () => {
  assert.doesNotThrow(() => qs.stringify(qs.parse(
    "x%5Bconstructor%5D%5BisBuffer%5D=y", {plainObjects: true},
  )));
});

test("UUID namespace output rejects undersized buffers", () => {
  assert.throws(() => uuid.v5("bounded", uuid.v5.DNS, Buffer.alloc(2)));
  assert.equal(uuid.validate(uuid.v4()), true);
});
