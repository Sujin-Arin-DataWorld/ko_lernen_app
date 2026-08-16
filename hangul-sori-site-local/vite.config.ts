import vinext from "vinext";
import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import { defineConfig } from "vite";

// macOS Seatbelt blocks FSEvents, so Codex previews need polling for HMR.
const isCodexSeatbeltSandbox = process.env.CODEX_SANDBOX === "seatbelt";

// The Vite plugin generates dist/server/wrangler.json from this build-time
// entrypoint. Runtime bindings and domains stay in wrangler.jsonc so they are
// defined exactly once.
const workerBuildConfig = {
  main: "./worker/index.ts",
  compatibility_flags: ["nodejs_compat"],
};

export default defineConfig(async () => {
  let releaseId = "development";
  try {
    const releaseIdentity = JSON.parse(
      await readFile(resolve(import.meta.dirname, ".wrangler/build-release.json"), "utf8"),
    ) as { releaseId?: unknown };
    if (typeof releaseIdentity.releaseId !== "string") {
      throw new Error("Build release identity is invalid.");
    }
    releaseId = releaseIdentity.releaseId;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
  }

  // Keep Wrangler and Miniflare state project-local. These are non-secret tool
  // settings; application environment belongs in ignored `.env*` files.
  process.env.WRANGLER_WRITE_LOGS ??= "false";
  process.env.WRANGLER_LOG_PATH ??= ".wrangler/logs";
  process.env.WRANGLER_REGISTRY_PATH ??= ".wrangler/registry";
  process.env.MINIFLARE_REGISTRY_PATH ??= ".wrangler/registry";

  // Wrangler snapshots its log path while the Cloudflare plugin is imported.
  const { cloudflare } = await import("@cloudflare/vite-plugin");

  return {
    define: {
      __HANGUL_SORI_RELEASE_ID__: JSON.stringify(releaseId),
    },
    server: {
      host: "0.0.0.0",
      allowedHosts: ["terminal.local"],
      ...(isCodexSeatbeltSandbox
        ? { watch: { useFsEvents: false, usePolling: true } }
        : {}),
    },
    plugins: [
      vinext(),
      cloudflare({
        viteEnvironment: { name: "rsc", childEnvironments: ["ssr"] },
        inspectorPort: false,
        config: workerBuildConfig,
      }),
    ],
  };
});
