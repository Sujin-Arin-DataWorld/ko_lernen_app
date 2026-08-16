import { execFile, spawn } from "node:child_process";
import { readFile, rm } from "node:fs/promises";
import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { pathToFileURL } from "node:url";
import { promisify } from "node:util";
import {
  GIT_SHA_PATTERN,
  WORKER_NAME,
  readCurrentGitState,
  validateProductionReleaseIdentity,
} from "./release-id.mjs";
import { runWrangler } from "./run-wrangler.mjs";

const execFileAsync = promisify(execFile);
const projectRoot = resolve(import.meta.dirname, "..");
const sourceConfig = "wrangler.jsonc";
const artifactConfig = "dist/server/wrangler.json";
const releaseManifestPath = resolve(projectRoot, "dist/release.json");
const liveOrigin = "https://hangul-sori.com";

function isUuid(value) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
    String(value ?? ""),
  );
}

export function parseActiveDeployment(value) {
  if (!value || !isUuid(value.id) || !Array.isArray(value.versions)) {
    throw new Error("Wrangler returned an invalid active deployment.");
  }
  if (value.versions.length !== 1) {
    throw new Error("Production must have exactly one active Worker version before an automatic deployment.");
  }
  const [version] = value.versions;
  if (!isUuid(version.version_id) || Number(version.percentage) !== 100) {
    throw new Error("Production must have one Worker version serving exactly 100% of traffic.");
  }
  return {
    deploymentId: value.id,
    versionId: version.version_id,
    percentage: 100,
  };
}

export function parseDeployOutput(ndjson) {
  const events = [];
  for (const line of String(ndjson ?? "").split(/\r?\n/)) {
    if (!line.trim()) continue;
    try {
      events.push(JSON.parse(line));
    } catch {
      throw new Error("Wrangler structured output contained invalid NDJSON.");
    }
  }
  const failed = events.find((event) => event?.type === "command-failed");
  const deployEvents = events.filter(
    (event) =>
      event?.type === "deploy" &&
      event?.version === 1 &&
      event?.worker_name === WORKER_NAME &&
      isUuid(event?.version_id),
  );
  return {
    failed,
    deploy: deployEvents.at(-1) ?? null,
    events,
  };
}

export function shouldRollback(currentDeployment, deployedVersionId) {
  try {
    return parseActiveDeployment(currentDeployment).versionId === deployedVersionId;
  } catch {
    return false;
  }
}

export function createDeployArguments(releaseSha, { bootstrap = false } = {}) {
  if (!GIT_SHA_PATTERN.test(String(releaseSha ?? ""))) {
    throw new Error("A production deploy requires a full Git release SHA.");
  }
  return [
    "deploy",
    "--config",
    artifactConfig,
    ...(bootstrap ? [] : ["--strict"]),
    "--tag",
    `release-${releaseSha.slice(0, 12)}`,
    "--message",
    `Release ${releaseSha}`,
  ];
}

async function git(args) {
  const { stdout } = await execFileAsync("git", args, {
    cwd: projectRoot,
    encoding: "utf8",
    maxBuffer: 16 * 1024 * 1024,
    windowsHide: true,
  });
  return stdout.trim();
}

async function gitExitCode(args) {
  return new Promise((resolveCode, reject) => {
    const child = spawn("git", args, {
      cwd: projectRoot,
      stdio: "ignore",
      windowsHide: true,
    });
    child.once("error", reject);
    child.once("exit", (code) => resolveCode(code ?? 1));
  });
}

async function readActiveDeployment() {
  const { stdout } = await runWrangler(
    ["deployments", "status", "--json", "--config", sourceConfig],
    { capture: true },
  );
  return JSON.parse(stdout);
}

async function readLiveRelease() {
  const response = await fetch(`${liveOrigin}/?__hangul_sori_release_probe=${Date.now()}`, {
    redirect: "manual",
    signal: AbortSignal.timeout(20_000),
    headers: {
      accept: "text/html",
      "cache-control": "no-cache",
      "user-agent": "hangul-sori-production-deployer/1.0",
    },
  });
  if (response.status !== 200) {
    throw new Error(`Production release probe returned HTTP ${response.status}.`);
  }
  return response.headers.get("x-hangul-sori-release")?.trim().toLowerCase() ?? null;
}

async function waitForLiveRelease(expectedRelease) {
  const deadline = Date.now() + 60_000;
  let observed = null;
  while (Date.now() < deadline) {
    try {
      observed = await readLiveRelease();
      if (observed === expectedRelease) return;
    } catch {
      // Deployment propagation can briefly fail at an individual edge.
    }
    await new Promise((resolveWait) => setTimeout(resolveWait, 2_000));
  }
  throw new Error(
    `Timed out waiting for live release ${expectedRelease ?? "without a release header"}; last observed ${observed ?? "no release header"}.`,
  );
}

async function runLiveVerifier(releaseSha) {
  const argumentsList = [resolve(projectRoot, "scripts/verify-live.mjs")];
  if (releaseSha) {
    argumentsList.push("--expect-release", releaseSha);
  } else {
    argumentsList.push("--allow-legacy-release");
  }
  await new Promise((resolveRun, reject) => {
    const child = spawn(process.execPath, argumentsList, {
      cwd: projectRoot,
      env: process.env,
      stdio: "inherit",
      windowsHide: true,
    });
    child.once("error", reject);
    child.once("exit", (code, signal) => {
      if (code === 0) resolveRun();
      else reject(new Error(`Live verification exited with ${code ?? signal}.`));
    });
  });
}

async function ensureTargetIsCurrentMain(releaseSha, previousLiveRelease) {
  const state = await readCurrentGitState();
  if (state.dirty || state.gitCommit !== releaseSha) {
    throw new Error("Deploy artifact no longer matches the clean checked-out Git commit.");
  }

  if (process.env.WORKERS_CI === "1") {
    if (process.env.WORKERS_CI_BRANCH !== "main") {
      throw new Error("Workers Builds production deploys are allowed only from main.");
    }
    if (String(process.env.WORKERS_CI_COMMIT_SHA ?? "").toLowerCase() !== releaseSha) {
      throw new Error("Workers Builds commit does not match the deploy artifact release.");
    }
  } else {
    const branch = await git(["rev-parse", "--abbrev-ref", "HEAD"]);
    if (branch !== "main") {
      throw new Error(`Local production deployment requires branch main; current branch is ${branch}.`);
    }
  }

  try {
    const remoteLine = await git(["ls-remote", "--heads", "origin", "refs/heads/main"]);
    const remoteSha = remoteLine.split(/\s+/)[0]?.toLowerCase();
    if (!GIT_SHA_PATTERN.test(remoteSha)) {
      throw new Error("origin/main did not return a full commit SHA.");
    }
    if (remoteSha !== releaseSha) {
      throw new Error(`Refusing stale deployment: origin/main is ${remoteSha}, artifact is ${releaseSha}.`);
    }
  } catch (error) {
    if (process.env.WORKERS_CI !== "1" || /Refusing stale deployment/.test(error.message)) {
      throw error;
    }
    console.warn(`Could not query private origin/main from Workers Builds: ${error.message}`);
  }

  if (previousLiveRelease === releaseSha) return "already-live";
  if (previousLiveRelease === null) {
    console.warn("Bootstrapping the first production release that exposes a Git release header.");
    return "bootstrap";
  }
  if (!GIT_SHA_PATTERN.test(previousLiveRelease)) {
    throw new Error(`Live production exposes an unrecognized release ID: ${previousLiveRelease}`);
  }

  let ancestryCode = await gitExitCode([
    "merge-base",
    "--is-ancestor",
    previousLiveRelease,
    releaseSha,
  ]);
  if (ancestryCode > 1) {
    try {
      await git(["fetch", "--no-tags", "--depth=100", "origin", "main"]);
    } catch {
      // The next ancestry check remains fail-closed if the object is unavailable.
    }
    ancestryCode = await gitExitCode([
      "merge-base",
      "--is-ancestor",
      previousLiveRelease,
      releaseSha,
    ]);
  }
  if (ancestryCode !== 0) {
    throw new Error(
      `Refusing stale deployment: live release ${previousLiveRelease} is not a known ancestor of ${releaseSha}.`,
    );
  }
  return "forward";
}

async function rollbackAfterFailure({ oldVersionId, newVersionId, previousLiveRelease, releaseSha }) {
  const current = await readActiveDeployment();
  if (!shouldRollback(current, newVersionId)) {
    throw new Error(
      "Automatic rollback was suppressed because production changed after this deployment. Manual review is required.",
    );
  }

  await runWrangler([
    "rollback",
    oldVersionId,
    "--config",
    sourceConfig,
    "--message",
    `Automatic rollback after failed release ${releaseSha}`,
    "--yes",
  ]);
  await waitForLiveRelease(previousLiveRelease);
  const rolledBack = parseActiveDeployment(await readActiveDeployment());
  if (rolledBack.versionId !== oldVersionId) {
    throw new Error(`Rollback did not restore Worker version ${oldVersionId}.`);
  }
  console.error(`Restored production Worker version ${oldVersionId}.`);
}

export async function deployProduction() {
  const identity = validateProductionReleaseIdentity(
    JSON.parse(await readFile(releaseManifestPath, "utf8")),
  );
  const releaseSha = identity.releaseId;
  const previousDeployment = parseActiveDeployment(await readActiveDeployment());
  const previousLiveRelease = await readLiveRelease();
  const direction = await ensureTargetIsCurrentMain(releaseSha, previousLiveRelease);

  if (direction === "already-live") {
    await runLiveVerifier(releaseSha);
    console.log(`Release ${releaseSha} is already live and verified.`);
    return;
  }

  const temporaryDirectory = await mkdtemp(join(tmpdir(), "hangul-sori-deploy-"));
  const outputPath = resolve(temporaryDirectory, "wrangler.ndjson");
  const bootstrap = direction === "bootstrap";
  if (bootstrap) {
    console.warn(
      "The first owned release will replace legacy Dashboard metadata with the checked-in Worker configuration.",
    );
  }
  let deployError = null;
  let deployEvent = null;
  try {
    try {
      await runWrangler(
        createDeployArguments(releaseSha, { bootstrap }),
        { env: { WRANGLER_OUTPUT_FILE_PATH: outputPath } },
      );
    } catch (error) {
      deployError = error;
    }

    let structuredOutput = "";
    try {
      structuredOutput = await readFile(outputPath, "utf8");
    } catch (error) {
      if (error?.code !== "ENOENT") throw error;
    }
    const parsedOutput = parseDeployOutput(structuredOutput);
    deployEvent = parsedOutput.deploy;

    if (!deployEvent) {
      const current = parseActiveDeployment(await readActiveDeployment());
      if (current.versionId === previousDeployment.versionId) {
        throw deployError ?? new Error("Wrangler did not emit a successful structured deploy event.");
      }
      throw new Error(
        `Deployment state changed to ${current.versionId} without an attributable Wrangler deploy event; automatic rollback is unsafe.`,
      );
    }

    try {
      await waitForLiveRelease(releaseSha);
      await runLiveVerifier(releaseSha);
      const current = parseActiveDeployment(await readActiveDeployment());
      if (current.versionId !== deployEvent.version_id) {
        throw new Error(
          `Verified release is not the active deployment version ${deployEvent.version_id}.`,
        );
      }
    } catch (verificationError) {
      try {
        await rollbackAfterFailure({
          oldVersionId: previousDeployment.versionId,
          newVersionId: deployEvent.version_id,
          previousLiveRelease,
          releaseSha,
        });
      } catch (rollbackError) {
        throw new AggregateError(
          [verificationError, rollbackError],
          "Production verification failed and automatic rollback could not be proven.",
        );
      }
      throw new Error(
        `Production verification failed; version ${previousDeployment.versionId} was restored.`,
        { cause: verificationError },
      );
    }

    if (deployError) {
      console.warn(`Wrangler reported an error after deployment, but the exact release was verified: ${deployError.message}`);
    }
    console.log(`Deployed and verified release ${releaseSha} as Worker version ${deployEvent.version_id}.`);
  } finally {
    await rm(temporaryDirectory, { recursive: true, force: true });
  }
}

const invokedPath = process.argv[1] ? pathToFileURL(resolve(process.argv[1])).href : "";
if (import.meta.url === invokedPath) {
  await deployProduction();
}
