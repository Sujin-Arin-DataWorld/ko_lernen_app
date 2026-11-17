"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const { createRequire } = require("node:module");

const indexPath = path.join(__dirname, "index.js");
const localRequire = createRequire(indexPath);

// Execute the real deployment entry point and real Gen-1 Auth SDK. Replace only
// Admin initialization and Firestore I/O; never call a production backend.
function loadTrigger({ failure = null } = {}) {
  const collections = [];
  const deletions = [];
  const firestore = {
    collection(name) {
      collections.push(name);
      return { doc: (id) => ({ path: `${name}/${id}` }) };
    },
    async recursiveDelete(reference) {
      if (failure) throw failure;
      deletions.push(reference.path);
    },
  };
  const output = {};
  vm.runInNewContext(fs.readFileSync(indexPath, "utf8"), {
    exports: output,
    module: { exports: output },
    process,
    require(name) {
      if (name === "firebase-admin") {
        return { initializeApp() {}, firestore: () => firestore };
      }
      return localRequire(name);
    },
  }, { filename: indexPath });
  return { trigger: output.on_auth_user_deleted, collections, deletions };
}

function preserveProject(t) {
  const previous = process.env.GCLOUD_PROJECT;
  t.after(() => {
    if (previous === undefined) delete process.env.GCLOUD_PROJECT;
    else process.env.GCLOUD_PROJECT = previous;
  });
}

function deletionContext(resource) {
  return {
    eventId: "local-deletion-event",
    eventType: typeof resource === "string"
      ? "providers/firebase.auth/eventTypes/user.delete"
      : "google.firebase.auth.user.delete",
    timestamp: "2026-10-30T00:00:00Z",
    resource,
  };
}

for (const resource of [
  "projects/demo-auth-cleanup",
  { name: "projects/demo-auth-cleanup", service: "firebaseauth.googleapis.com" },
]) {
  test(`provider ${typeof resource} context admits deletion with no legacy project environment`, async (t) => {
    preserveProject(t);
    delete process.env.GCLOUD_PROJECT;
    const { trigger, collections, deletions } = loadTrigger();
    await assert.doesNotReject(async () => {
      await trigger({ uid: "local-test-user" }, deletionContext(resource));
    });
    assert.equal(process.env.GCLOUD_PROJECT, "demo-auth-cleanup");
    assert.deepEqual(deletions, ["users/local-test-user"]);
    assert.deepEqual(collections, ["users"]);
  });
}

test("an explicitly configured project is retained", async (t) => {
  preserveProject(t);
  process.env.GCLOUD_PROJECT = "demo-configured-project";
  const { trigger, deletions } = loadTrigger();
  await trigger({ uid: "local-test-user" }, deletionContext("projects/demo-event-project"));
  assert.equal(process.env.GCLOUD_PROJECT, "demo-configured-project");
  assert.deepEqual(deletions, ["users/local-test-user"]);
});

for (const [name, resource] of [
  ["absent resource", undefined],
  ["non-project resource", "accounts/demo-not-a-project"],
  ["nested resource", { name: "projects/demo-project/users/local-test-user" }],
  ["empty project", { name: "projects/" }],
]) {
  test(`invalid ${name} cannot infer a project from the user payload`, async (t) => {
    preserveProject(t);
    delete process.env.GCLOUD_PROJECT;
    const { trigger, collections, deletions } = loadTrigger();
    await assert.rejects(async () => {
      await trigger({ uid: "local-test-user", projectId: "demo-payload-project" }, deletionContext(resource));
    }, /GCLOUD_PROJECT is not set/);
    assert.equal(process.env.GCLOUD_PROJECT, undefined);
    assert.deepEqual(deletions, []);
    assert.deepEqual(collections, []);
  });
}

test("bridge deletion errors still reject so the configured retry can run", async (t) => {
  preserveProject(t);
  delete process.env.GCLOUD_PROJECT;
  const failure = new Error("local injected Firestore failure");
  const { trigger, collections, deletions } = loadTrigger({ failure });
  await assert.rejects(async () => {
    await trigger({ uid: "local-test-user" }, deletionContext("projects/demo-auth-cleanup"));
  }, (error) => error === failure);
  assert.deepEqual(collections, ["users"]);
  assert.deepEqual(deletions, []);
});

test("deployment keeps the Gen-1 delete event, region and original test handler", async (t) => {
  preserveProject(t);
  process.env.GCLOUD_PROJECT = "demo-auth-cleanup";
  const { trigger, deletions } = loadTrigger();
  const endpoint = trigger.__endpoint;
  assert.equal(endpoint.platform, "gcfv1");
  assert.equal(endpoint.eventTrigger.eventType, "providers/firebase.auth/eventTypes/user.delete");
  assert.deepEqual(endpoint.region, ["europe-west3"]);
  assert.equal(endpoint.callableTrigger, undefined);
  assert.equal(endpoint.httpsTrigger, undefined);
  assert.equal(typeof trigger.run, "function");
  await trigger.run({ uid: "local-test-user" }, {});
  assert.deepEqual(deletions, ["users/local-test-user"]);
});
