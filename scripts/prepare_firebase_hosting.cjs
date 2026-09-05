"use strict";

const fs = require("node:fs");
const path = require("node:path");

const repositoryRoot = path.resolve(__dirname, "..");
const sourceRoot = path.join(repositoryRoot, "docs");
const outputRoot = path.join(repositoryRoot, "build", "firebase-hosting");

// This is an allowlist, not a directory copy. `docs/` also contains internal
// plans, audit evidence, review packets, and source assets that must never be
// published by Firebase Hosting.
const publicFiles = Object.freeze([
  "account-deletion-page.js",
  "account-deletion.html",
  "assets/favicon.png",
  "assets/gate.png",
  "assets/logo.png",
  "assets/welcome-hero.png",
  "impressum.html",
  "index.html",
  "privacy.html",
  "support.html",
  "terms.html",
]);

function normalizeRelativePath(value) {
  return value.split(path.sep).join("/");
}

function assertInside(parent, candidate, label) {
  const relative = path.relative(parent, candidate);
  if (relative === "" || relative.startsWith(`..${path.sep}`) || path.isAbsolute(relative)) {
    throw new Error(`${label} escapes its expected root: ${candidate}`);
  }
}

function localReferences(html, sourceRelativePath) {
  const references = [];
  const attributePattern = /\b(?:href|src)\s*=\s*["']([^"']+)["']/giu;
  for (const match of html.matchAll(attributePattern)) {
    const raw = match[1].trim();
    if (
      raw === "" ||
      raw.startsWith("#") ||
      raw.startsWith("data:") ||
      raw.startsWith("http://") ||
      raw.startsWith("https://") ||
      raw.startsWith("mailto:") ||
      raw.startsWith("tel:") ||
      raw.startsWith("/api/")
    ) {
      continue;
    }
    const withoutQuery = raw.split(/[?#]/u, 1)[0];
    const sourceDirectory = path.posix.dirname(sourceRelativePath);
    references.push(path.posix.normalize(path.posix.join(sourceDirectory, withoutQuery)));
  }

  const cssUrlPattern = /\burl\(\s*["']?([^"')]+)["']?\s*\)/giu;
  for (const match of html.matchAll(cssUrlPattern)) {
    const raw = match[1].trim();
    if (raw.startsWith("data:") || raw.startsWith("http://") || raw.startsWith("https://")) {
      continue;
    }
    const withoutQuery = raw.split(/[?#]/u, 1)[0];
    const sourceDirectory = path.posix.dirname(sourceRelativePath);
    references.push(path.posix.normalize(path.posix.join(sourceDirectory, withoutQuery)));
  }
  return references;
}

function listRelativeFiles(root, relativeDirectory = "") {
  const currentDirectory = path.join(root, relativeDirectory);
  const files = [];
  for (const entry of fs.readdirSync(currentDirectory, { withFileTypes: true })) {
    const relativePath = path.join(relativeDirectory, entry.name);
    if (entry.isDirectory()) {
      files.push(...listRelativeFiles(root, relativePath));
    } else if (entry.isFile()) {
      files.push(normalizeRelativePath(relativePath));
    } else {
      throw new Error(`Unexpected non-file Hosting output: ${relativePath}`);
    }
  }
  return files;
}

function prepareHostingBundle() {
  const outputParent = path.dirname(outputRoot);
  assertInside(repositoryRoot, outputParent, "Hosting build parent");
  assertInside(outputParent, outputRoot, "Hosting build output");

  const allowlist = new Set(publicFiles);
  for (const relativePath of publicFiles) {
    const source = path.resolve(sourceRoot, relativePath);
    assertInside(sourceRoot, source, `Public source ${relativePath}`);
    if (!fs.statSync(source).isFile()) {
      throw new Error(`Public source is not a file: ${relativePath}`);
    }

    if (relativePath.endsWith(".html")) {
      const html = fs.readFileSync(source, "utf8");
      for (const reference of localReferences(html, relativePath)) {
        if (!allowlist.has(reference)) {
          throw new Error(
            `${relativePath} references non-public or missing file: ${reference}`,
          );
        }
      }
    }
  }

  fs.rmSync(outputRoot, { recursive: true, force: true });
  for (const relativePath of publicFiles) {
    const source = path.resolve(sourceRoot, relativePath);
    const destination = path.resolve(outputRoot, relativePath);
    assertInside(outputRoot, destination, `Hosting destination ${relativePath}`);
    fs.mkdirSync(path.dirname(destination), { recursive: true });
    fs.copyFileSync(source, destination);
  }

  const copiedFiles = listRelativeFiles(outputRoot).sort();
  const expectedFiles = [...publicFiles].sort();
  if (JSON.stringify(copiedFiles) !== JSON.stringify(expectedFiles)) {
    throw new Error(`Unexpected Firebase Hosting bundle: ${JSON.stringify(copiedFiles)}`);
  }

  console.log(`Prepared ${copiedFiles.length} allowlisted Firebase Hosting files.`);
}

prepareHostingBundle();
