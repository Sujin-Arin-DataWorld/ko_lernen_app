import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { access, readFile, readdir, writeFile } from "node:fs/promises";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";
import { readBuildReleaseIdentity } from "./release-id.mjs";

const projectRoot = resolve(import.meta.dirname, "..");
const workerPath = resolve(projectRoot, "dist/server/index.js");
const wranglerPath = resolve(projectRoot, "dist/server/wrangler.json");
const releaseManifestPath = resolve(projectRoot, "dist/release.json");
const publicPath = resolve(projectRoot, "public");
const clientPath = resolve(projectRoot, "dist/client");

async function listFiles(directory, prefix = "") {
  const entries = await readdir(directory, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const relativePath = prefix ? `${prefix}/${entry.name}` : entry.name;
    if (entry.isDirectory()) {
      files.push(...await listFiles(resolve(directory, entry.name), relativePath));
    } else if (entry.isFile()) {
      files.push(relativePath);
    }
  }
  return files.sort();
}

async function sha256(path) {
  return createHash("sha256").update(await readFile(path)).digest("hex");
}

await Promise.all([access(workerPath), access(wranglerPath)]);

const wrangler = JSON.parse(await readFile(wranglerPath, "utf8"));
assert.equal(wrangler.name, "hangul-sori-redesign");
assert.equal(wrangler.main, "index.js");
assert.equal(wrangler.compatibility_date, "2026-05-22");
assert.deepEqual(wrangler.assets, {
  directory: "../client",
  not_found_handling: "none",
  binding: "ASSETS",
});
assert.deepEqual(wrangler.compatibility_flags, ["nodejs_compat"]);
assert.deepEqual(
  (wrangler.routes ?? [])
    .map(({ pattern, custom_domain }) => ({ pattern, custom_domain }))
    .sort((left, right) => left.pattern.localeCompare(right.pattern)),
  [
    { pattern: "hangul-sori.com", custom_domain: true },
    { pattern: "www.hangul-sori.com", custom_domain: true },
  ],
);
assert.deepEqual(wrangler.images, { binding: "IMAGES" });
assert.deepEqual(wrangler.send_email, [
  {
    name: "TESTER_EMAIL",
    destination_address: "vjinny2@gmail.com",
    allowed_sender_addresses: ["website@hangul-sori.com"],
  },
]);
assert.deepEqual(wrangler.ratelimits, [
  {
    name: "TESTER_RATE_LIMIT",
    namespace_id: "886231",
    simple: { limit: 3, period: 60 },
  },
]);

const workerUrl = pathToFileURL(workerPath);
workerUrl.searchParams.set("artifact-validation", `${process.pid}-${Date.now()}`);
const worker = await import(workerUrl.href);
assert.equal(typeof worker.default?.fetch, "function");
const releaseIdentity = await readBuildReleaseIdentity();
const releaseProbe = await worker.default.fetch(
  new Request("http://localhost/", { headers: { accept: "text/html" } }),
  { ASSETS: { fetch: async () => new Response("Not found", { status: 404 }) } },
  { waitUntil() {}, passThroughOnException() {} },
);
assert.equal(releaseProbe.status, 200);
assert.equal(
  releaseProbe.headers.get("x-hangul-sori-release"),
  releaseIdentity.releaseId,
  "built Worker release header must match the source identity captured before bundling",
);

const publicFiles = await listFiles(publicPath);
assert.ok(publicFiles.length > 0, "public/ must contain the owned website assets");
for (const relativePath of publicFiles) {
  const source = resolve(publicPath, relativePath);
  const deployed = resolve(clientPath, relativePath);
  await access(deployed);
  assert.equal(
    await sha256(deployed),
    await sha256(source),
    `${relativePath} must be copied byte-for-byte into the deploy artifact`,
  );
}

await writeFile(
  releaseManifestPath,
  `${JSON.stringify(releaseIdentity, null, 2)}\n`,
  "utf8",
);

console.log(
  `Validated release ${releaseIdentity.releaseId}, deployable Worker artifact, both custom domains, API bindings, and ${publicFiles.length} owned public assets.`,
);
