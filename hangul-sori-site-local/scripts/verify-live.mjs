import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { createHash } from "node:crypto";
import { readFile, readdir } from "node:fs/promises";
import { resolve } from "node:path";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const TESTFLIGHT_URL = "https://testflight.apple.com/join/sbvJNQSt";
const projectRoot = resolve(import.meta.dirname, "..");
const repositoryRoot = resolve(projectRoot, "..");
const publicPath = resolve(projectRoot, "public");
const DEFAULT_ORIGINS = [
  "https://hangul-sori.com",
  "https://www.hangul-sori.com",
];
const GIT_SHA_PATTERN = /^[0-9a-f]{40}$/;

const routeMarkers = new Map([
  ["/", "Learn Korean and build your own hanok"],
  ["/de", "Lerne Koreanisch und baue deinen eigenen Hanok"],
  ["/en", "Learn Korean and build your own hanok"],
  ["/ko", "한국어를 배우며 나만의 한옥을 지어요"],
  ["/features", "Alle Funktionen"],
  ["/support", "Direkter Kontakt"],
  ["/privacy", "Einwilligungsverwaltung mit Cookiebot"],
  ["/terms", "Kostenloser Start"],
  ["/account-deletion", "Konto direkt in der App löschen"],
  ["/impressum", "Anbieterkennzeichnung"],
  ["/press", "Hangul Sori in Kürze"],
]);

const cliArguments = process.argv.slice(2);
let external = false;
let allowLegacyRelease = false;
let expectedRelease = null;
const requestedOrigins = [];
for (let index = 0; index < cliArguments.length; index += 1) {
  const argument = cliArguments[index];
  if (argument === "--external") {
    external = true;
    continue;
  }
  if (argument === "--allow-legacy-release") {
    allowLegacyRelease = true;
    continue;
  }
  if (argument === "--expect-release") {
    expectedRelease = String(cliArguments[index + 1] ?? "").trim().toLowerCase();
    index += 1;
    if (!GIT_SHA_PATTERN.test(expectedRelease)) {
      throw new Error("--expect-release requires a full 40-character Git SHA.");
    }
    continue;
  }
  if (argument === "--origin") {
    requestedOrigins.push(new URL(cliArguments[index + 1]).origin);
    index += 1;
    continue;
  }
  if (argument.startsWith("--")) {
    throw new Error(`Unknown option: ${argument}`);
  }
  requestedOrigins.push(new URL(argument).origin);
}
if (allowLegacyRelease && expectedRelease) {
  throw new Error("--allow-legacy-release cannot be combined with --expect-release.");
}
const origins = requestedOrigins.length > 0 ? requestedOrigins : DEFAULT_ORIGINS;
let observedRelease;
const referencedBuildAssets = new Set();

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

function sha256(bytes) {
  return createHash("sha256").update(bytes).digest("hex");
}

function collectReferencedBuildAssets(html, documentUrl, origin) {
  for (const match of html.matchAll(/(?:src|href)=["']([^"']+)["']/gi)) {
    try {
      const assetUrl = new URL(match[1], documentUrl);
      if (assetUrl.origin === origin && assetUrl.pathname.startsWith("/_next/static/")) {
        referencedBuildAssets.add(`${assetUrl.pathname}${assetUrl.search}`);
      }
    } catch {
      // Ignore malformed third-party markup; owned build URLs must still parse below.
    }
  }
}

function assertBuildAssetHeaders(response, assetUrl) {
  const contentType = response.headers.get("content-type") ?? "";
  if (new URL(assetUrl).pathname.endsWith(".js")) {
    assert.match(contentType, /javascript/i, `${assetUrl} must use a JavaScript MIME type`);
  } else if (new URL(assetUrl).pathname.endsWith(".css")) {
    assert.match(contentType, /^text\/css\b/i, `${assetUrl} must use the CSS MIME type`);
  } else {
    assert.ok(contentType, `${assetUrl} must declare a content type`);
  }
  assert.match(
    response.headers.get("cache-control") ?? "",
    /\bimmutable\b/i,
    `${assetUrl} must retain immutable content-hash caching`,
  );
}

async function readExpectedPublicAsset(relativePath) {
  if (!expectedRelease) {
    return readFile(resolve(publicPath, relativePath));
  }
  const gitPath = `hangul-sori-site-local/public/${relativePath}`;
  const { stdout } = await execFileAsync(
    "git",
    ["cat-file", "blob", `${expectedRelease}:${gitPath}`],
    {
      cwd: repositoryRoot,
      encoding: "buffer",
      maxBuffer: 64 * 1024 * 1024,
      windowsHide: true,
    },
  );
  return stdout;
}

async function request(url, options = {}) {
  const { headers = {}, ...requestOptions } = options;
  return fetch(url, {
    redirect: "manual",
    signal: AbortSignal.timeout(20_000),
    headers: {
      accept: "text/html,application/xhtml+xml",
      "cache-control": "no-cache",
      "user-agent": "hangul-sori-release-verifier/1.0",
      ...headers,
    },
    ...requestOptions,
  });
}

function assertReleaseHeader(response, label) {
  const actual = response.headers.get("x-hangul-sori-release")?.trim().toLowerCase() ?? null;
  if (expectedRelease) {
    assert.equal(actual, expectedRelease, `${label} must serve release ${expectedRelease}`);
  } else if (actual !== null) {
    assert.match(actual, GIT_SHA_PATTERN, `${label} must expose a committed Git release SHA`);
  } else if (!allowLegacyRelease) {
    assert.fail(`${label} is missing x-hangul-sori-release`);
  }

  if (observedRelease === undefined) {
    observedRelease = actual;
  } else {
    assert.equal(actual, observedRelease, `${label} must match the release served by both domains`);
  }
}

async function waitForExpectedRelease() {
  if (!expectedRelease) return;
  const deadline = Date.now() + 60_000;
  let lastSeen = null;
  while (Date.now() < deadline) {
    const probeUrl = `${origins[0]}/?__hangul_sori_release_probe=${Date.now()}`;
    try {
      const response = await request(probeUrl);
      lastSeen = response.headers.get("x-hangul-sori-release")?.trim().toLowerCase() ?? null;
      if (response.status === 200 && lastSeen === expectedRelease) return;
    } catch {
      // A new global deployment can take a few seconds to reach every edge.
    }
    await new Promise((resolveWait) => setTimeout(resolveWait, 2_000));
  }
  throw new Error(
    `Timed out waiting for release ${expectedRelease}; last observed ${lastSeen ?? "no release header"}.`,
  );
}

function assertSecurityHeaders(response, label) {
  assert.match(
    response.headers.get("content-security-policy") ?? "",
    /frame-ancestors 'none'/,
    `${label} must include the production CSP`,
  );
  assert.match(
    response.headers.get("strict-transport-security") ?? "",
    /max-age=63072000/,
    `${label} must include HSTS`,
  );
  assert.equal(response.headers.get("x-content-type-options"), "nosniff");
  assert.equal(response.headers.get("x-frame-options"), "DENY");
  assert.equal(response.headers.get("referrer-policy"), "no-referrer");
}

await waitForExpectedRelease();

for (const origin of origins) {
  for (const [path, marker] of routeMarkers) {
    const url = `${origin}${path}`;
    const response = await request(url);
    assert.equal(response.status, 200, `${url} must respond directly with 200`);
    assert.match(
      response.headers.get("content-type") ?? "",
      /^text\/html\b/i,
      `${url} must serve HTML`,
    );
    assertSecurityHeaders(response, url);
    assertReleaseHeader(response, url);
    assert.match(
      response.headers.get("cache-control") ?? "",
      /\bno-store\b/i,
      `${url} must not cache release-specific HTML`,
    );

    const html = await response.text();
    collectReferencedBuildAssets(html, url, origin);
    assert.ok(html.includes(marker), `${url} must contain ${JSON.stringify(marker)}`);
    if (path === "/") {
      assert.match(
        html,
        /href=["']https:\/\/testflight\.apple\.com\/join\/sbvJNQSt["']/i,
        `${url} must retain the TestFlight CTA`,
      );
    }
  }

  const apiUrl = `${origin}/api/tester-application`;
  const apiResponse = await request(apiUrl, {
    headers: { accept: "application/json" },
  });
  assert.equal(apiResponse.status, 405, `${apiUrl} GET must be rejected`);
  assert.match(apiResponse.headers.get("allow") ?? "", /POST/i);
  assert.match(apiResponse.headers.get("cache-control") ?? "", /no-store/i);
  assert.equal(
    apiResponse.headers.get("x-hangul-sori-email-binding"),
    "ready",
    `${apiUrl} must have the Send Email binding`,
  );
  assert.equal(
    apiResponse.headers.get("x-hangul-sori-rate-limit-binding"),
    "ready",
    `${apiUrl} must have the Rate Limit binding`,
  );
  assertSecurityHeaders(apiResponse, apiUrl);
  assertReleaseHeader(apiResponse, apiUrl);

  const missingUrl = `${origin}/__hangul_sori_missing_route__`;
  const missingResponse = await request(missingUrl);
  assert.equal(missingResponse.status, 404, `${missingUrl} must stay missing`);
  assert.match(
    missingResponse.headers.get("content-type") ?? "",
    /^text\/plain\b/i,
    `${missingUrl} must preserve the production plain-text 404`,
  );
  assert.equal(await missingResponse.text(), "Not Found");
  assertSecurityHeaders(missingResponse, missingUrl);
  assertReleaseHeader(missingResponse, missingUrl);
}

assert.ok(referencedBuildAssets.size > 0, "rendered HTML must reference owned build assets");
for (const relativeUrl of [...referencedBuildAssets].sort()) {
  for (const origin of origins) {
    const assetUrl = `${origin}${relativeUrl}`;
    const response = await request(assetUrl, { headers: { accept: "*/*" } });
    assert.equal(response.status, 200, `${assetUrl} referenced by live HTML must be available`);
    assertBuildAssetHeaders(response, assetUrl);
    assert.ok(
      (await response.arrayBuffer()).byteLength > 0,
      `${assetUrl} referenced by live HTML must not be empty`,
    );
  }
}

const publicFiles = await listFiles(publicPath);
assert.ok(publicFiles.length > 0, "public/ must contain owned assets");
for (const relativePath of publicFiles) {
  const expectedHash = sha256(await readExpectedPublicAsset(relativePath));
  for (const origin of origins) {
    const assetUrl = `${origin}/${relativePath}`;
    const response = await request(assetUrl, { headers: { accept: "*/*" } });
    assert.equal(response.status, 200, `${assetUrl} must be available`);
    const bytes = new Uint8Array(await response.arrayBuffer());
    assert.ok(bytes.byteLength > 0, `${assetUrl} must not be empty`);
    assert.equal(
      sha256(bytes),
      expectedHash,
      `${assetUrl} must match the owned public asset byte-for-byte`,
    );
  }
}

if (external) {
  const response = await fetch(TESTFLIGHT_URL, {
    redirect: "follow",
    signal: AbortSignal.timeout(20_000),
    headers: { "user-agent": "hangul-sori-release-verifier/1.0" },
  });
  assert.equal(response.status, 200, "The TestFlight destination must be reachable");
  assert.match(
    await response.text(),
    /Join the Hangul Sori beta/i,
    "The TestFlight destination must still be the Hangul Sori beta",
  );
}

console.log(
  `Verified release ${observedRelease ?? "legacy-without-release-header"}, ${routeMarkers.size} routes, ${referencedBuildAssets.size} referenced build assets, exact 404 behavior, tester API GET rejection and binding presence, security headers, ${publicFiles.length} byte-exact assets, and the TestFlight CTA on ${origins.join(" and ")}${external ? ", including Apple" : ""}.`,
);
