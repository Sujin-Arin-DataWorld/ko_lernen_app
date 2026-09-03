"use strict";
// OFFLINE ONLY: consumes a names/generations inventory prepared by an approved
// operator. Does not import cloud SDKs, download audio, or execute mutations.
const crypto = require("node:crypto");
const fs = require("node:fs");
const manifest = require("./canonical_manifest.json");
const canonical = new Set(Object.entries(manifest.voices).flatMap(
  ([voice, hashes]) => hashes.map((hash) => `tts/v3/${voice}/${hash}.mp3`),
));
function inventoryPlan(inventory) {
  if (!Array.isArray(inventory)) throw new TypeError("Inventory must be an array.");
  const objects = inventory.filter((item) => typeof item.name === "string" && item.name.startsWith("tts/"))
    .map((item) => {
      if (!/^\d+$/.test(String(item.generation))) throw new Error("Exact object generation is required.");
      return { name: item.name, generation: String(item.generation), canonical: canonical.has(item.name) };
    }).sort((a, b) => a.name.localeCompare(b.name));
  const inventorySha256 = crypto.createHash("sha256").update(JSON.stringify(objects)).digest("hex");
  const canonicalCount = objects.filter((item) => item.canonical).length;
  return { inventorySha256, canonicalCount, unknownLegacyCount: objects.length - canonicalCount, objects };
}
function approvedMutationPlan(plan, approval) {
  if (!approval || approval.approvedInventorySha256 !== plan.inventorySha256) {
    throw new Error("Explicit approval for this exact inventory digest is required.");
  }
  // Output is reviewable, generation-guarded instructions, never live writes.
  // Unknown objects are quarantined by access metadata, never presumed safe or
  // deleted. Existing leaked/shared URLs cannot be retroactively recovered.
  return { execute: false, inventorySha256: plan.inventorySha256,
    operations: plan.objects.map((item) => ({ name: item.name,
      ifGenerationMatch: item.generation,
      cacheControl: item.canonical ? "public, max-age=31536000" : "private, no-store",
      metadata: { canonical: item.canonical ? "true" : null, firebaseStorageDownloadTokens: null },
    })) };
}
if (require.main === module) {
  const [mode = "inventory", inventoryPath, approvalPath] = process.argv.slice(2);
  if (!inventoryPath || !["inventory", "approved-plan"].includes(mode)) {
    throw new Error("Usage: node privacy_migration.js inventory <inventory.json> | approved-plan <inventory.json> <approval.json>");
  }
  const plan = inventoryPlan(JSON.parse(fs.readFileSync(inventoryPath, "utf8")));
  const output = mode === "inventory" ? plan : approvedMutationPlan(plan,
    approvalPath ? JSON.parse(fs.readFileSync(approvalPath, "utf8")) : null);
  process.stdout.write(JSON.stringify(output, null, 2) + "\n");
}
module.exports = { inventoryPlan, approvedMutationPlan };
