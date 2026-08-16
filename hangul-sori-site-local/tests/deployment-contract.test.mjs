import assert from "node:assert/strict";
import { access, readFile } from "node:fs/promises";
import test from "node:test";

const packageJson = JSON.parse(
  await readFile(new URL("../package.json", import.meta.url), "utf8"),
);
const wrangler = JSON.parse(
  await readFile(new URL("../wrangler.jsonc", import.meta.url), "utf8"),
);
const viteConfig = await readFile(
  new URL("../vite.config.ts", import.meta.url),
  "utf8",
);
const npmConfig = await readFile(new URL("../.npmrc", import.meta.url), "utf8");
const packageLock = await readFile(
  new URL("../package-lock.json", import.meta.url),
  "utf8",
);
const workerSource = await readFile(
  new URL("../worker/index.ts", import.meta.url),
  "utf8",
);
const productionDeploySource = await readFile(
  new URL("../scripts/deploy-production.mjs", import.meta.url),
  "utf8",
);
const liveVerificationSource = await readFile(
  new URL("../scripts/verify-live.mjs", import.meta.url),
  "utf8",
);
const cleanBuildSource = await readFile(
  new URL("../scripts/clean-build.mjs", import.meta.url),
  "utf8",
);
const githubCi = await readFile(
  new URL("../../.github/workflows/ci.yml", import.meta.url),
  "utf8",
);
const readme = await readFile(new URL("../README.md", import.meta.url), "utf8");
const localGuide = await readFile(
  new URL("../LOCAL_EDITING_GUIDE_KO.md", import.meta.url),
  "utf8",
);

async function exists(url) {
  try {
    await access(url);
    return true;
  } catch (error) {
    if (error?.code === "ENOENT") return false;
    throw error;
  }
}

test("deploys the GitHub-tracked source directly to the production Worker", () => {
  assert.equal(wrangler.name, "hangul-sori-redesign");
  assert.deepEqual(
    wrangler.routes
      .map(({ pattern, custom_domain }) => ({ pattern, custom_domain }))
      .sort((left, right) => left.pattern.localeCompare(right.pattern)),
    [
      { pattern: "hangul-sori.com", custom_domain: true },
      { pattern: "www.hangul-sori.com", custom_domain: true },
    ],
  );
  assert.match(viteConfig, /compatibility_flags:\s*\["nodejs_compat"\]/);
  assert.equal(
    packageJson.scripts["deploy:built"],
    "npm run cf -- deploy --strict --config dist/server/wrangler.json",
  );
  assert.deepEqual(wrangler.assets, {
    directory: "dist/client",
    not_found_handling: "none",
    binding: "ASSETS",
  });
  assert.doesNotMatch(viteConfig, /sites-vite-plugin|\.openai\/hosting|\bsites\(\)/);
  assert.doesNotMatch(npmConfig, /\.sites-runtime/);
  assert.doesNotMatch(packageLock, /git\.chatgpt-team\.site/i);
  assert.match(viteConfig, /__HANGUL_SORI_RELEASE_ID__/);
  assert.match(workerSource, /x-hangul-sori-release/);
});

test("keeps all quality gates and deployment in one command", () => {
  assert.deepEqual(packageJson.allowScripts, {
    "esbuild@0.28.1": true,
    "unrs-resolver@1.11.1": true,
    "workerd@1.20260811.1": true,
  });
  assert.equal(
    packageJson.scripts.deploy,
    "npm run deploy:check && npm run deploy:production",
  );
  assert.equal(
    packageJson.scripts["deploy:production"],
    "node scripts/deploy-production.mjs",
  );
  assert.match(packageJson.scripts["deploy:check"], /npm run lint/);
  assert.match(packageJson.scripts["deploy:check"], /npm run typecheck/);
  assert.match(packageJson.scripts["deploy:check"], /npm test/);
  assert.match(packageJson.scripts["deploy:check"], /deploy:dry-run/);
  assert.match(packageJson.scripts["deploy:check"], /audit:security/);
  assert.match(packageJson.scripts["deploy:dry-run"], /--strict/);
  assert.match(packageJson.scripts["test:unit"], /release-safety\.test\.mjs/);
  assert.equal(packageJson.scripts["audit:security"], "npm audit --audit-level=high");
  assert.match(packageJson.scripts.typecheck, /--incremental false/);
  assert.equal(
    packageJson.scripts["repair:domains"],
    "npm run test:deployment && npm run cf -- triggers deploy --config wrangler.jsonc && npm run verify:live",
  );
  assert.match(packageJson.engines.node, /24\.18\.0/);
  assert.equal(packageJson.scripts.cf, "node scripts/run-wrangler.mjs");
  assert.match(packageJson.scripts["cloudflare:login"], /--use-keyring/);
  assert.doesNotMatch(JSON.stringify(packageJson), /drizzle|db:generate/i);
  assert.match(productionDeploySource, /WRANGLER_OUTPUT_FILE_PATH/);
  assert.match(productionDeploySource, /rollbackAfterFailure/);
  assert.match(productionDeploySource, /origin\/main/);
  assert.match(workerSource, /no-store, max-age=0, must-revalidate/);
  assert.match(liveVerificationSource, /\/_next\/static\//);
  assert.match(liveVerificationSource, /referenced by live HTML must be available/);
  assert.match(liveVerificationSource, /immutable content-hash caching/);
  assert.match(cleanBuildSource, /maxRetries:\s*20/);
  assert.match(cleanBuildSource, /retryDelay:\s*250/);
  assert.match(githubCi, /Website source and Worker release gate/);
  assert.match(githubCi, /node-version-file:\s*hangul-sori-site-local\/\.node-version/);
  assert.match(githubCi, /npm run deploy:check/);
  assert.match(readme, /Node\.js 24\.18\.0/);
  assert.match(localGuide, /Node\.js 24\.18\.0/);
  assert.doesNotMatch(`${readme}\n${localGuide}`, /Node\.js 22\.13/);
});

test("owns every runtime layer without a Sites checkout", async () => {
  const required = [
    "app/site.tsx",
    "app/globals.css",
    "app/layout.tsx",
    "app/store-links.ts",
    "app/cookiebot.tsx",
    "app/privacy-consent-panel.tsx",
    "app/tester-access-form.tsx",
    "worker/index.ts",
    "worker/tester-application.ts",
    "scripts/verify-live.mjs",
    "scripts/verify-tester-email.mjs",
    "scripts/run-wrangler.mjs",
    "scripts/release-id.mjs",
    "scripts/deploy-production.mjs",
    ".node-version",
    "wrangler.jsonc",
    "public/hangul-sori-logo.png",
    "public/app-assets/taego-joy-duo.png",
    "public/app-assets/hanok-construction.mp4",
    "public/social/sori-check-01-reel.mp4",
  ];
  for (const path of required) {
    assert.equal(
      await exists(new URL(`../${path}`, import.meta.url)),
      true,
      `${path} must remain in the owned source tree`,
    );
  }

  const forbidden = [
    ".git",
    ".openai",
    ".sites-runtime",
    "SITES_RELEASE.md",
    "build/sites-vite-plugin.ts",
    "scripts/build-verified.sh",
    "scripts/install-ci.sh",
    "scripts/sites-env.sh",
  ];
  for (const path of forbidden) {
    assert.equal(
      await exists(new URL(`../${path}`, import.meta.url)),
      false,
      `${path} must not return to the canonical website`,
    );
  }
  assert.equal(
    await exists(new URL("../../wrangler.jsonc", import.meta.url)),
    false,
    "the repository root must not expose an accidental default Worker deploy",
  );
  assert.equal(
    await exists(new URL("../../docs/CNAME", import.meta.url)),
    false,
    "the legacy GitHub Pages source must not claim the production domain",
  );
});
