"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const {ServiceCostError, readCostControl, prepareCostReservation, recordCostApprovalFailure} = require("./service_cost_policy");
const fixture = require("../../test/fixtures/access_policy/cost-v1.json");

test("deployed TTS cost boundary equals canonical Node source", () => {
  const read = (p) => fs.readFileSync(path.join(__dirname, p), "utf8").replace(/\r\n/g, "\n");
  assert.equal(read("service_cost_policy.js"), read("../pronunciation/service_cost_policy.js"));
});

test("cost diagnostics ignore untyped errors, other categories and unknown services", () => {
  const logs = [];
  const logger = {warn: (...args) => logs.push(args)};
  for (const error of [
    Object.assign(new Error("PRIVATE_CANARY"), {reason: "approval_unavailable"}),
    new ServiceCostError("resource-exhausted", "PRIVATE_CANARY"),
    new ServiceCostError("unavailable", "AI cost approval unavailable."),
  ]) recordCostApprovalFailure(error, "tts", logger);
  recordCostApprovalFailure(new ServiceCostError("unavailable", "PRIVATE_CANARY", "approval_unavailable"), "PRIVATE_SERVICE_CANARY", logger);
  assert.deepEqual(logs, []);
});

test("cost diagnostic never logs the error message or lets a broken sink escape", () => {
  const error = new ServiceCostError("unavailable", "PRIVATE_ERROR_CANARY", "approval_unavailable");
  error.uid = "PRIVATE_UID_CANARY";
  const logs = [];
  recordCostApprovalFailure(error, "tts", {warn: (...args) => logs.push(args)});
  assert.deepEqual(logs, [["AI cost approval unavailable.", {
    event: "ai_cost_approval_unavailable", service: "tts", schemaVersion: 1,
  }]]);
  assert.doesNotThrow(() => recordCostApprovalFailure(error, "tts", {warn() {throw new Error("sink down");}}));
});

for (const c of fixture.cases) {
  test(`shared service cost contract: ${c.name}`, async () => {
    const config = {...fixture.config, ...c.config};
    const db = {collection: (name) => ({doc: (id) => ({key: `${name}/${id}`})})};
    const tx = {get: async (ref) => ref.key === "service_cost_controls/ai_v1" ?
      {exists: !c.missingControl, data: () => config} :
      {exists: c.reservedUnits !== undefined, data: () => ({reservedUnits: c.reservedUnits})}};
    const run = async () => {
      const approved = await readCostControl(db, tx, new Date(fixture.now));
      return prepareCostReservation(db, tx, new Date(fixture.now), approved, c.existing, c.kind || "book");
    };
    if (c.wantCode) await assert.rejects(run(), {code: c.wantCode});
    else {
      const result = await run();
      assert.equal(result.payload?.reservedUnits ?? c.reservedUnits, c.wantUnits);
      assert.equal(result.reservation.day, "2026-09-03");
      if (result.payload) assert.equal(result.payload.expiresAt.toISOString(), "2026-09-05T00:00:00.000Z");
    }
  });
}
