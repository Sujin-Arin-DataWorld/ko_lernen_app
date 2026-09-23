"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const logger = require("firebase-functions/logger");
const deployed = require("./index");

test("account creation observation is a bounded Auth event, not a callable", (t) => {
  const previousProject = process.env.GCLOUD_PROJECT;
  process.env.GCLOUD_PROJECT = "demo-hangul-sori";
  t.after(() => {
    if (previousProject === undefined) {
      delete process.env.GCLOUD_PROJECT;
    } else {
      process.env.GCLOUD_PROJECT = previousProject;
    }
  });
  const trigger = deployed.on_auth_account_created;
  assert.ok(trigger, "the observer must be exported for deployment");
  const endpoint = trigger.__endpoint;
  assert.equal(endpoint.platform, "gcfv1");
  assert.equal(endpoint.eventTrigger.eventType, "providers/firebase.auth/eventTypes/user.create");
  assert.deepEqual(endpoint.region, ["europe-west3"]);
  assert.equal(endpoint.maxInstances, 2);
  assert.equal(endpoint.timeoutSeconds, 30);
  assert.equal(endpoint.availableMemoryMb, 128);
  assert.equal(endpoint.eventTrigger.retry, false);
  assert.equal(endpoint.callableTrigger, undefined);
  assert.equal(endpoint.httpsTrigger, undefined);
});

test("creation logs classify identities without logging their attributes", async (t) => {
  const logs = [];
  t.mock.method(logger, "info", (...args) => logs.push(args));
  const anonymous = { uid: "private-uid", providerData: [] };
  for (const [user, kind] of [
    [anonymous, "anonymous"],
    [{ ...anonymous, providerData: [{ providerId: "google.com" }] }, "identified"],
    [{ ...anonymous, email: "private@example.com" }, "identified"],
    [{ ...anonymous, phoneNumber: "+491234567890" }, "identified"],
    [{ uid: "private-uid" }, "unknown"],
    [{ ...anonymous, providerData: [null] }, "unknown"],
    [{ ...anonymous, email: false }, "unknown"],
    [{ ...anonymous, uid: "" }, "unknown"],
    [null, "unknown"],
  ]) {
    await deployed.on_auth_account_created.run(user, {});
    assert.deepEqual(logs.at(-1), ["Auth account creation observed", {
      event: "auth_account_created", schemaVersion: 1, accountKind: kind,
    }]);
  }
  assert.equal(logs.length, 9);
  assert.ok(!JSON.stringify(logs).includes("private"));
  assert.ok(!JSON.stringify(logs).includes("491234"));
});

test("B1 metric selects the real observer's anonymous creation log contract", () => {
  const script = fs.readFileSync(path.join(__dirname, "../../tool/ops/log_metrics.py"), "utf8");
  assert.ok(script.includes('"auth_anonymous_account_created"'));
  for (const clause of [
    'resource.type="cloud_function"',
    'resource.labels.function_name="on_auth_account_created"',
    'jsonPayload.event="auth_account_created"',
    'jsonPayload.accountKind="anonymous"',
    'jsonPayload.schemaVersion=1',
  ]) {
    assert.ok(script.includes(clause), `metric filter must include ${clause}`);
  }
});
