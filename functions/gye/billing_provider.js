"use strict";

const {validUid} = require("./access_policy");

const MAX_PROVIDER_BYTES = 262144;

class BillingProviderFailure extends Error {
  constructor() { super("Subscription verification unavailable."); }
}

function dateMillis(value) {
  if (typeof value !== "string" || value.length > 64) return null;
  const result = Date.parse(value);
  return Number.isSafeInteger(result) && result >= 0 ? result : null;
}

/** Current RevenueCat GET response, not the webhook event, controls access.
 * v1 mixes environments: entitlement -> product -> subscription.is_sandbox is
 * mandatory. Lifetime/promotional/family-shared products are not this monthly
 * subscription contract. They must never manufacture tester grants.
 */
function normalizeSubscriber(payload, {environment, entitlementId, now, accountCreatedAt}) {
  const subscriber = payload?.subscriber;
  if (!Number.isSafeInteger(payload?.request_date_ms) ||
      Math.abs(now - payload.request_date_ms) > 300000 ||
      !subscriber || typeof subscriber !== "object" ||
      !subscriber.entitlements || Array.isArray(subscriber.entitlements) ||
      !subscriber.subscriptions || Array.isArray(subscriber.subscriptions)) {
    throw new BillingProviderFailure();
  }
  const providerCheckedAt = Math.min(now, payload.request_date_ms);
  const inactive = {status: "inactive", accessUntil: now, providerCheckedAt};
  const entitlement = Object.hasOwn(subscriber.entitlements, entitlementId) ?
    subscriber.entitlements[entitlementId] : null;
  if (!entitlement) return inactive;
  const product = entitlement.product_identifier;
  const subscription = typeof product === "string" && Object.hasOwn(subscriber.subscriptions, product) ?
    subscriber.subscriptions[product] : null;
  if (!subscription || subscription.is_sandbox !== (environment === "SANDBOX") ||
      !["app_store", "play_store"].includes(subscription.store) ||
      (subscription.ownership_type && subscription.ownership_type !== "PURCHASED")) return inactive;
  const purchase = dateMillis(subscription.original_purchase_date);
  const expiry = dateMillis(subscription.expires_date);
  const entitlementExpiry = dateMillis(entitlement.expires_date);
  // An old purchase cannot be inherited by a newly created Firebase identity.
  if (purchase === null || purchase < accountCreatedAt || expiry === null ||
      entitlementExpiry === null || subscription.refunded_at != null) return inactive;
  let accessUntil = Math.min(expiry, entitlementExpiry);
  const grace = dateMillis(subscription.grace_period_expires_date);
  const entitlementGrace = dateMillis(entitlement.grace_period_expires_date);
  if (grace !== null && entitlementGrace !== null) {
    accessUntil = Math.max(accessUntil, Math.min(grace, entitlementGrace));
  }
  // A future auto-resume is a pause/account hold, not a grace entitlement.
  const resumesAt = dateMillis(subscription.auto_resume_date);
  if (resumesAt !== null && resumesAt > now) return inactive;
  return accessUntil > now ? {status: "active", accessUntil, providerCheckedAt,
    store: subscription.store} : inactive;
}

/** Server-only fixed-origin transport. Never logs URL, key, response, or PII.
 * HTTP redirects are rejected to prevent leaking Authorization to another host.
 * Body reads and deadline are bounded even when Content-Length is absent.
 */
function createRevenueCatFetcher({getApiKey, fetchImpl = globalThis.fetch}) {
  return async function fetchSubscriber(uid) {
    if (!validUid(uid)) throw new BillingProviderFailure();
    const apiKey = getApiKey();
    if (typeof apiKey !== "string" || apiKey.length < 16 || apiKey.length > 512 ||
        /[\r\n]/u.test(apiKey)) throw new BillingProviderFailure();
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 12000);
    try {
      const response = await fetchImpl(`https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(uid)}`, {
        method: "GET", redirect: "error", signal: controller.signal,
        headers: {Authorization: `Bearer ${apiKey}`, Accept: "application/json"},
      });
      if (!response.ok || !/^application\/json(?:\s*;|$)/iu.test(response.headers.get("content-type") || "") ||
          Number(response.headers.get("content-length") || 0) > MAX_PROVIDER_BYTES || !response.body) {
        throw new BillingProviderFailure();
      }
      const reader = response.body.getReader();
      const chunks = [];
      let size = 0;
      while (true) {
        const {done, value} = await reader.read();
        if (done) break;
        size += value.byteLength;
        if (size > MAX_PROVIDER_BYTES) {
          await reader.cancel();
          throw new BillingProviderFailure();
        }
        chunks.push(Buffer.from(value));
      }
      return JSON.parse(new TextDecoder("utf-8", {fatal: true}).decode(Buffer.concat(chunks)));
    } catch {
      throw new BillingProviderFailure();
    } finally {
      clearTimeout(timer);
    }
  };
}

module.exports = {MAX_PROVIDER_BYTES, BillingProviderFailure, normalizeSubscriber,
  createRevenueCatFetcher};
