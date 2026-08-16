import assert from "node:assert/strict";
import test from "node:test";
import {
  normalizeGitSha,
  validateProductionReleaseIdentity,
  validateReleaseIdentity,
} from "../scripts/release-id.mjs";
import {
  createDeployArguments,
  parseActiveDeployment,
  parseDeployOutput,
  shouldRollback,
} from "../scripts/deploy-production.mjs";

const releaseSha = "a".repeat(40);
const oldVersion = "11111111-1111-4111-8111-111111111111";
const newVersion = "22222222-2222-4222-8222-222222222222";

test("accepts only full Git SHAs for production releases", () => {
  assert.equal(normalizeGitSha(releaseSha.toUpperCase()), releaseSha);
  assert.throws(() => normalizeGitSha("abc123"), /40-character/);
  assert.deepEqual(
    validateProductionReleaseIdentity({
      schema: 1,
      worker: "hangul-sori-redesign",
      releaseId: releaseSha,
      gitCommit: releaseSha,
      dirty: false,
      source: "git",
    }).releaseId,
    releaseSha,
  );
  assert.throws(
    () => validateProductionReleaseIdentity({
      schema: 1,
      worker: "hangul-sori-redesign",
      releaseId: `dirty-${"b".repeat(40)}`,
      gitCommit: releaseSha,
      dirty: true,
      source: "working-tree",
    }),
    /committed, clean/,
  );
  assert.throws(
    () => validateReleaseIdentity({
      schema: 1,
      worker: "hangul-sori-redesign",
      releaseId: "b".repeat(40),
      gitCommit: releaseSha,
      dirty: false,
      source: "git",
    }),
    /exactly match/,
  );
});

test("requires one active Worker version at 100 percent", () => {
  const active = parseActiveDeployment({
    id: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
    versions: [{ version_id: oldVersion, percentage: 100 }],
  });
  assert.equal(active.versionId, oldVersion);
  assert.throws(
    () => parseActiveDeployment({
      id: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
      versions: [
        { version_id: oldVersion, percentage: 50 },
        { version_id: newVersion, percentage: 50 },
      ],
    }),
    /exactly one/,
  );
});

test("uses Wrangler structured output and never guesses a deployed version", () => {
  const parsed = parseDeployOutput([
    JSON.stringify({ type: "session", version: 1 }),
    JSON.stringify({
      type: "deploy",
      version: 1,
      worker_name: "another-worker",
      version_id: oldVersion,
    }),
    JSON.stringify({
      type: "deploy",
      version: 1,
      worker_name: "hangul-sori-redesign",
      version_id: newVersion,
    }),
  ].join("\n"));
  assert.equal(parsed.deploy.version_id, newVersion);
  assert.throws(() => parseDeployOutput("not-json\n"), /invalid NDJSON/);
});

test("allows the legacy metadata replacement only for the first owned release", () => {
  const normalArguments = createDeployArguments(releaseSha);
  const bootstrapArguments = createDeployArguments(releaseSha, { bootstrap: true });
  assert.equal(normalArguments.includes("--strict"), true);
  assert.equal(bootstrapArguments.includes("--strict"), false);
  assert.deepEqual(
    bootstrapArguments.slice(-4),
    ["--tag", `release-${releaseSha.slice(0, 12)}`, "--message", `Release ${releaseSha}`],
  );
  assert.throws(() => createDeployArguments("abc123"), /full Git release SHA/);
});

test("rolls back only while the just-deployed version still owns production", () => {
  const current = {
    id: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
    versions: [{ version_id: newVersion, percentage: 100 }],
  };
  assert.equal(shouldRollback(current, newVersion), true);
  assert.equal(shouldRollback(current, oldVersion), false);
  assert.equal(
    shouldRollback({ ...current, versions: [{ version_id: newVersion, percentage: 50 }] }, newVersion),
    false,
  );
});
