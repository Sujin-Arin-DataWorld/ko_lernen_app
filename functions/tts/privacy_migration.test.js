"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
test("migration inventory compares hashes, excludes payloads, and gates mutation plans", () => {
  const { inventoryPlan, approvedMutationPlan } = require("./privacy_migration");
  const input = [
    { name: "tts/v3/female/cad639c2539393f15c209d28e6fafca1a5b2f1fa.mp3", generation: "1", metadata: { firebaseStorageDownloadTokens: "do-not-retain-token" } },
    { name: "tts/v3/female/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.mp3", generation: "2", audio: "do-not-retain-audio", text: "do-not-retain-personal-text" },
  ];
  const plan = inventoryPlan(input);
  assert.equal(plan.canonicalCount, 1);
  assert.equal(plan.unknownLegacyCount, 1);
  assert.equal(JSON.stringify(plan).includes("do-not-retain"), false);
  assert.throws(() => approvedMutationPlan(plan, null), /approval/);
  assert.throws(() => approvedMutationPlan(plan, { approvedInventorySha256: "wrong" }), /approval/);
  const approved = approvedMutationPlan(plan, { approvedInventorySha256: plan.inventorySha256 });
  assert.equal(approved.execute, false);
  const canonical = approved.operations.find((item) => item.name === input[0].name);
  const unknown = approved.operations.find((item) => item.name === input[1].name);
  assert.equal(canonical.metadata.canonical, "true");
  assert.equal(canonical.metadata.firebaseStorageDownloadTokens, null);
  assert.equal(unknown.metadata.canonical, null);
  assert.equal(unknown.metadata.firebaseStorageDownloadTokens, null);
});
