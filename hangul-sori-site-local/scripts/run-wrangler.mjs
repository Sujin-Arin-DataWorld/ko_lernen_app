import { spawn } from "node:child_process";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";

const projectRoot = resolve(import.meta.dirname, "..");
const wranglerCli = resolve(projectRoot, "node_modules/wrangler/bin/wrangler.js");

export function wranglerEnvironment(overrides = {}) {
  const outputFilePath = overrides.WRANGLER_OUTPUT_FILE_PATH;
  return {
    ...process.env,
    ...overrides,
    WRANGLER_WRITE_LOGS: "false",
    WRANGLER_LOG_SANITIZE: "true",
    WRANGLER_LOG_PATH: resolve(projectRoot, ".wrangler/logs"),
    WRANGLER_REGISTRY_PATH: resolve(projectRoot, ".wrangler/registry"),
    MINIFLARE_REGISTRY_PATH: resolve(projectRoot, ".wrangler/registry"),
    ...(outputFilePath ? { WRANGLER_OUTPUT_FILE_PATH: outputFilePath } : {}),
  };
}

export class WranglerRunError extends Error {
  constructor(message, details) {
    super(message);
    this.name = "WranglerRunError";
    Object.assign(this, details);
  }
}

export function runWrangler(args, options = {}) {
  const { capture = false, env = {}, cwd = projectRoot } = options;
  return new Promise((resolveRun, reject) => {
    const child = spawn(process.execPath, [wranglerCli, ...args], {
      cwd,
      env: wranglerEnvironment(env),
      stdio: capture ? ["ignore", "pipe", "pipe"] : "inherit",
      windowsHide: true,
    });
    let stdout = "";
    let stderr = "";
    if (capture) {
      child.stdout.setEncoding("utf8");
      child.stderr.setEncoding("utf8");
      child.stdout.on("data", (chunk) => { stdout += chunk; });
      child.stderr.on("data", (chunk) => { stderr += chunk; });
    }
    child.once("error", reject);
    child.once("exit", (code, signal) => {
      if (code === 0) {
        resolveRun({ stdout, stderr });
        return;
      }
      const detail = capture ? `\n${stderr || stdout}` : "";
      reject(new WranglerRunError(`Wrangler exited with ${code ?? signal}.${detail}`, {
        code,
        signal,
        stdout,
        stderr,
      }));
    });
  });
}

const invokedPath = process.argv[1] ? pathToFileURL(resolve(process.argv[1])).href : "";
if (import.meta.url === invokedPath) {
  await runWrangler(process.argv.slice(2));
}
