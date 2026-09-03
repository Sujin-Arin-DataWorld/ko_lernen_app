"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {createRevenueCatFetcher, normalizeSubscriber, MAX_PROVIDER_BYTES} = require("./billing_provider");

const NOW = Date.parse("2026-09-03T12:00:00Z");
const DAY = 86400000;
function payload(overrides = {}) {
  return {request_date_ms: NOW, subscriber: {entitlements: {premium: {
    product_identifier: "monthly", expires_date: new Date(NOW + DAY).toISOString()}},
  subscriptions: {monthly: {is_sandbox: false, store: "app_store",
    expires_date: new Date(NOW + DAY).toISOString(),
    original_purchase_date: new Date(NOW - DAY).toISOString(), ...overrides}}}};
}
const context = {environment: "PRODUCTION", entitlementId: "premium", now: NOW,
  accountCreatedAt: NOW - 2 * DAY};

test("raw v1 Google base-plan metadata preserves product-key lookup and environment isolation", () => {
  // Raw v1 is keyed by product ID; SDK CustomerInfo may compose product:plan.
  // Shape: revenuecat.com/docs/api-v1/customer-info-model and purchases-ios PR #2654.
  // Synthetic dates/identifiers, not a captured customer or store-release proof.
  const raw = {request_date_ms: NOW, subscriber: {
    entitlements: {premium: {product_identifier: "premium_access",
      expires_date: new Date(NOW + DAY).toISOString()}},
    subscriptions: {premium_access: {product_plan_identifier: "monthly",
      store: "play_store", is_sandbox: false, ownership_type: "PURCHASED",
      period_type: "normal", original_purchase_date: new Date(NOW - DAY).toISOString(),
      expires_date: new Date(NOW + DAY).toISOString()}},
  }};
  assert.deepEqual(normalizeSubscriber(raw, context), {status: "active",
    store: "play_store", accessUntil: NOW + DAY, providerCheckedAt: NOW});
  assert.equal(normalizeSubscriber(raw, {...context, environment: "SANDBOX"}).status, "inactive");
  raw.subscriber.subscriptions.premium_access.is_sandbox = true;
  assert.equal(normalizeSubscriber(raw, context).status, "inactive");
  assert.equal(normalizeSubscriber(raw, {...context, environment: "SANDBOX"}).status, "active");
});

test("provider normalization rejects cross-env, nonmonthly ownership, refund, old account purchase, pause", () => {
  assert.equal(normalizeSubscriber(payload(), context).status, "active");
  for (const override of [{is_sandbox: true}, {is_sandbox: undefined},
    {store: "promotional"}, {ownership_type: "FAMILY_SHARED"},
    {refunded_at: new Date(NOW).toISOString()}, {expires_date: null},
    {original_purchase_date: new Date(NOW - 3 * DAY).toISOString()},
    {auto_resume_date: new Date(NOW + DAY).toISOString()}]) {
    assert.equal(normalizeSubscriber(payload(override), context).status, "inactive");
  }
  for (const response of [null, {}, {subscriber: {}}, {...payload(), request_date_ms: NOW - DAY},
    {...payload(), request_date_ms: NOW + DAY}]) {
    assert.throws(() => normalizeSubscriber(response, context));
  }
});

test("transport uses exact fixed HTTPS GET origin, encoded UID, server Bearer, no platform header", async () => {
  let received;
  const get = createRevenueCatFetcher({getApiKey: () => "test-secret-server-api-key",
    fetchImpl: async (...args) => {
      received = args;
      return new Response(JSON.stringify(payload()), {headers: {"content-type": "application/json"}});
    }});
  assert.deepEqual(await get("account+ä"), payload());
  assert.equal(received[0], "https://api.revenuecat.com/v1/subscribers/account%2B%C3%A4");
  assert.equal(received[1].method, "GET");
  assert.equal(received[1].redirect, "error");
  assert.equal(received[1].headers.Authorization, "Bearer test-secret-server-api-key");
  assert.equal(received[1].headers["X-Platform"], undefined);
});

test("transport fails closed on redirects, server errors, invalid JSON/type, oversized streamed body", async () => {
  for (const response of [
    new Response("{}", {status: 302}), new Response("private provider error", {status: 503}),
    new Response("{}", {headers: {"content-type": "text/html"}}),
    new Response("invalid", {headers: {"content-type": "application/json"}}),
    new Response("{}", {headers: {"content-type": "application/json", "content-length": MAX_PROVIDER_BYTES + 1}}),
    new Response("x".repeat(MAX_PROVIDER_BYTES + 1), {headers: {"content-type": "application/json"}}),
  ]) {
    const get = createRevenueCatFetcher({getApiKey: () => "test-secret-server-api-key",
      fetchImpl: async () => response});
    await assert.rejects(get("account-A"), {message: "Subscription verification unavailable."});
  }
  let called = false;
  const get = createRevenueCatFetcher({getApiKey: () => "short", fetchImpl: async () => { called = true; }});
  await assert.rejects(get("account-A"));
  assert.equal(called, false);
});
