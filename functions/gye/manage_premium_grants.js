#!/usr/bin/env node
"use strict";

// Privileged operator tool. Never imported by a Cloud Function or exposed to
// clients. ADC must already be configured; this script does not acquire keys.
const fs = require("node:fs");
const {validateApprovedRoster, createGrantManager} = require("./premium_grants");

async function main(args) {
  let projectId, rosterPath;
  let apply = false;
  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--project" && !projectId) projectId = args[++i];
    else if (args[i] === "--approved-roster" && !rosterPath) rosterPath = args[++i];
    else if (args[i] === "--apply" && !apply) apply = true;
    else throw new Error("Invalid arguments.");
  }
  if (!projectId || !/^[a-z][a-z0-9-]{4,61}[a-z0-9]$/u.test(projectId) || !rosterPath) {
    throw new Error("Use --project PROJECT_ID --approved-roster PATH [--apply]. Dry-run is default.");
  }
  const bytes = fs.readFileSync(rosterPath);
  if (bytes.length > 32768) throw new Error("Roster is too large.");
  const roster = validateApprovedRoster(JSON.parse(bytes.toString("utf8")));
  const {initializeApp, applicationDefault} = require("firebase-admin/app");
  const {getAuth} = require("firebase-admin/auth");
  const {getFirestore} = require("firebase-admin/firestore");
  const app = initializeApp({projectId, credential: applicationDefault()});
  try {
    const result = await createGrantManager({firestore: getFirestore(app), auth: getAuth(app)})
      .applyRoster(roster, {apply});
    process.stdout.write(`${JSON.stringify(result)}\n`);
  } finally {
    await app.delete();
  }
}

if (require.main === module) {
  main(process.argv.slice(2)).catch(() => {
    process.stderr.write("Grant operation failed. No account details are logged. Check arguments, approved roster, ADC permissions and account state.\n");
    process.exitCode = 1;
  });
}
module.exports = {main};
