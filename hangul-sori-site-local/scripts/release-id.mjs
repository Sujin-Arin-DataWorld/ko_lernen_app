import { execFile } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, isAbsolute, relative, resolve, sep } from "node:path";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const projectRoot = resolve(import.meta.dirname, "..");
const buildIdentityPath = resolve(projectRoot, ".wrangler/build-release.json");

export const WORKER_NAME = "hangul-sori-redesign";
export const GIT_SHA_PATTERN = /^[0-9a-f]{40}$/;
export const DIRTY_RELEASE_PATTERN = /^dirty-[0-9a-f]{40}$/;

async function git(args, options = {}) {
  const { encoding = "utf8" } = options;
  const { stdout } = await execFileAsync("git", args, {
    cwd: projectRoot,
    encoding,
    maxBuffer: 64 * 1024 * 1024,
    windowsHide: true,
  });
  return stdout;
}

export function normalizeGitSha(value, label = "Git commit SHA") {
  const sha = String(value ?? "").trim().toLowerCase();
  if (!GIT_SHA_PATTERN.test(sha)) {
    throw new Error(`${label} must be a full 40-character hexadecimal SHA.`);
  }
  return sha;
}

export async function readCurrentGitState() {
  const gitCommit = normalizeGitSha(
    await git(["rev-parse", "--verify", "HEAD"]),
    "Current Git HEAD",
  );
  const status = await git([
    "status",
    "--porcelain=v1",
    "--untracked-files=all",
    "--",
    ".",
  ]);
  return { gitCommit, dirty: status.trim().length > 0, status };
}

async function dirtySourceDigest(gitCommit, status) {
  const hash = createHash("sha256");
  hash.update(`git\0${gitCommit}\0status\0${status}\0`);

  const diff = await git(
    ["diff", "--binary", "--no-ext-diff", "HEAD", "--", "."],
    { encoding: "buffer" },
  );
  hash.update(diff);

  const untracked = await git([
    "ls-files",
    "--others",
    "--exclude-standard",
    "-z",
    "--",
    ".",
  ]);
  for (const relativePath of untracked.split("\0").filter(Boolean).sort()) {
    const absolutePath = resolve(projectRoot, relativePath);
    const projectRelativePath = relative(projectRoot, absolutePath);
    if (
      projectRelativePath === ".." ||
      projectRelativePath.startsWith(`..${sep}`) ||
      isAbsolute(projectRelativePath)
    ) {
      throw new Error(`Refusing to hash an untracked path outside the website: ${relativePath}`);
    }
    hash.update(`path\0${relativePath}\0`);
    hash.update(await readFile(absolutePath));
    hash.update("\0");
  }

  return hash.digest("hex").slice(0, 40);
}

export async function resolveBuildReleaseIdentity(environment = process.env) {
  const state = await readCurrentGitState();
  const workersCi = environment.WORKERS_CI === "1";

  if (workersCi) {
    if (environment.WORKERS_CI_BRANCH !== "main") {
      throw new Error("Production Workers Builds must run from the main branch.");
    }
    const ciCommit = normalizeGitSha(
      environment.WORKERS_CI_COMMIT_SHA,
      "WORKERS_CI_COMMIT_SHA",
    );
    if (ciCommit !== state.gitCommit) {
      throw new Error(
        `Workers Builds commit ${ciCommit} does not match checked-out HEAD ${state.gitCommit}.`,
      );
    }
    if (state.dirty) {
      throw new Error("Workers Builds checkout contains uncommitted website source changes.");
    }
    return {
      schema: 1,
      worker: WORKER_NAME,
      releaseId: ciCommit,
      gitCommit: ciCommit,
      dirty: false,
      source: "workers-ci",
    };
  }

  if (!state.dirty) {
    return {
      schema: 1,
      worker: WORKER_NAME,
      releaseId: state.gitCommit,
      gitCommit: state.gitCommit,
      dirty: false,
      source: "git",
    };
  }

  return {
    schema: 1,
    worker: WORKER_NAME,
    releaseId: `dirty-${await dirtySourceDigest(state.gitCommit, state.status)}`,
    gitCommit: state.gitCommit,
    dirty: true,
    source: "working-tree",
  };
}

export function validateReleaseIdentity(identity) {
  if (!identity || identity.schema !== 1 || identity.worker !== WORKER_NAME) {
    throw new Error("Invalid Hangul Sori release identity.");
  }
  const gitCommit = normalizeGitSha(identity.gitCommit, "Release Git commit");
  const releaseId = String(identity.releaseId ?? "").trim().toLowerCase();
  if (!GIT_SHA_PATTERN.test(releaseId) && !DIRTY_RELEASE_PATTERN.test(releaseId)) {
    throw new Error("Release ID must be a Git SHA or a dirty-source fingerprint.");
  }
  if (typeof identity.dirty !== "boolean") {
    throw new Error("Release identity must declare whether the source was dirty.");
  }
  if (identity.dirty !== DIRTY_RELEASE_PATTERN.test(releaseId)) {
    throw new Error("Release dirty flag and release ID disagree.");
  }
  if (!identity.dirty && releaseId !== gitCommit) {
    throw new Error("A clean release ID must exactly match its Git commit.");
  }
  return { ...identity, gitCommit, releaseId };
}

export function validateProductionReleaseIdentity(identity) {
  const validated = validateReleaseIdentity(identity);
  if (validated.dirty || !GIT_SHA_PATTERN.test(validated.releaseId)) {
    throw new Error(
      "Production deployment requires a committed, clean website checkout. Commit the website changes first.",
    );
  }
  return validated;
}

export async function writeBuildReleaseIdentity(identity) {
  const validated = validateReleaseIdentity(identity);
  await mkdir(dirname(buildIdentityPath), { recursive: true });
  await writeFile(buildIdentityPath, `${JSON.stringify(validated, null, 2)}\n`, "utf8");
  return validated;
}

export async function readBuildReleaseIdentity() {
  return validateReleaseIdentity(
    JSON.parse(await readFile(buildIdentityPath, "utf8")),
  );
}

export { buildIdentityPath, projectRoot };
