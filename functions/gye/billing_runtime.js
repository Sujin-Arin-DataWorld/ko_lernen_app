"use strict";

const {createHash, createHmac, randomUUID, timingSafeEqual} = require("node:crypto");
const {validUid, subjectHash, entitlementDocumentId, ACCESS_ENVIRONMENTS} = require("./access_policy");
const {normalizeSubscriber} = require("./billing_provider");

const MAX_BODY_BYTES = 65536;
const LEASE_MILLIS = 60000;
const DAY_MILLIS = 86400000;
const RECEIPT_RETENTION_MILLIS = 30 * DAY_MILLIS;
const NEEDS_REVIEW_AFTER_MILLIS = 7 * DAY_MILLIS;
const BILLING_WEBHOOK_OPTIONS = Object.freeze({region: "europe-west3", timeoutSeconds: 30,
  maxInstances: 5, concurrency: 20, invoker: "public"});
const BILLING_WORKER_OPTIONS = Object.freeze({region: "europe-west3", timeoutSeconds: 60,
  maxInstances: 5, concurrency: 5, retry: true});
const BILLING_SCHEDULE_OPTIONS = Object.freeze({region: "europe-west3", schedule: "every 5 minutes",
  timeoutSeconds: 540, maxInstances: 1});

function hash(value) { return createHash("sha256").update(value).digest("hex"); }
function billingEventId(environment, eventId) { return `${environment}_${hash(eventId)}`; }
function plain(value) { return value !== null && typeof value === "object" && !Array.isArray(value); }
function withoutRefreshDue(value) {
  const {refreshDueAt, ...remaining} = value;
  return remaining;
}
function bounded(value, limit) {
  return typeof value === "string" && value.length > 0 && Buffer.byteLength(value) <= limit &&
    !/[\u0000-\u001f\u007f]/u.test(value);
}
function candidateUid(value) {
  return validUid(value) && !value.startsWith("$RCAnonymousID:");
}
function durableGeneration(user, uid) {
  if (user?.uid !== uid || user.disabled === true ||
      !Array.isArray(user.providerData) || !user.providerData.some((entry) =>
        ["google.com", "apple.com", "password", "phone"].includes(entry.providerId))) return null;
  const generation = Date.parse(user?.metadata?.creationTime);
  return Number.isSafeInteger(generation) && generation >= 0 ? generation : null;
}
function equalSecret(received, expected) {
  if (!bounded(received, 1024) || !bounded(expected, 1024)) return false;
  return timingSafeEqual(Buffer.from(hash(received), "hex"), Buffer.from(hash(expected), "hex"));
}
function authenticated(rawBody, headers, config, now) {
  const hasAuthorization = bounded(config.authorization, 1024);
  const hasSignature = bounded(config.signingSecret, 512);
  if (!hasAuthorization && !hasSignature) return false;
  if (hasAuthorization && !equalSecret(headers.authorization, config.authorization)) return false;
  if (!hasSignature) return true;
  const header = headers["x-revenuecat-webhook-signature"];
  if (typeof header !== "string" || header.length > 256) return false;
  const match = /^t=(\d{1,12}),v1=([0-9a-f]{64})$/u.exec(header);
  if (!match || Math.abs(now - Number(match[1]) * 1000) > 300000) return false;
  const digest = createHmac("sha256", config.signingSecret)
    .update(`${match[1]}.`).update(rawBody).digest();
  return timingSafeEqual(digest, Buffer.from(match[2], "hex"));
}
function parseEvent(rawBody, now) {
  let envelope;
  try { envelope = JSON.parse(new TextDecoder("utf-8", {fatal: true}).decode(rawBody)); }
  catch { return null; }
  const event = envelope?.event;
  if (!plain(envelope) || envelope.api_version !== "1.0" || !plain(event) ||
      !bounded(event.id, 256) || !bounded(event.type, 64) ||
      !ACCESS_ENVIRONMENTS.has(event.environment) ||
      !Number.isSafeInteger(event.event_timestamp_ms) || event.event_timestamp_ms < 0 ||
      event.event_timestamp_ms > now + 300000) return null;
  const candidates = new Set();
  if (candidateUid(event.app_user_id)) candidates.add(event.app_user_id);
  for (const key of ["aliases", "transferred_from", "transferred_to"]) {
    if (event[key] === undefined) continue;
    if (!Array.isArray(event[key]) || event[key].length > 20 ||
        event[key].some((value) => !bounded(value, 256))) return null;
    for (const value of event[key]) if (candidateUid(value)) candidates.add(value);
  }
  if (candidates.size > 20 || (event.type !== "TRANSFER" && event.type !== "TEST" &&
      !candidateUid(event.app_user_id))) return null;
  const participants = [...candidates].sort();
  return {id: billingEventId(event.environment, event.id), environment: event.environment,
    type: event.type, uid: candidateUid(event.app_user_id) ? event.app_user_id : null,
    eventAt: event.event_timestamp_ms, participants,
    fingerprint: hash(JSON.stringify([event.type, event.environment,
      event.app_user_id || null, event.event_timestamp_ms, participants]))};
}

function createBillingRuntime({firestore, auth, fetchSubscriber, now = Date.now,
  getConfig = () => ({enabled: false})}) {
  const receipts = firestore.collection("billing_event_receipts");
  const customers = firestore.collection("billing_customers");
  const entitlements = firestore.collection("customer_entitlements");
  const deletion = firestore.collection("account_deletions");

  function config() {
    const value = getConfig();
    if (value?.enabled !== true || value.restorePolicy !== "keep_original" ||
        !bounded(value.entitlementId, 128)) throw new Error("Billing disabled.");
    return value;
  }
  async function generation(uid) {
    try { return durableGeneration(await auth.getUser(uid), uid); }
    catch (error) {
      if (error?.code === "auth/user-not-found") return null;
      throw new Error("Identity verification unavailable.");
    }
  }
  function snapshot(uid, environment, revision, at, state) {
    return {schemaVersion: 1, ownerUid: uid, ownerSubjectHash: subjectHash(uid),
      environment, revision, ...state, providerCheckedAt: state.providerCheckedAt ?? at};
  }
  function completed(job, status, at) {
    // Retain only dedup/integrity metadata, never a provider payload or raw UID.
    return {schemaVersion: 1, environment: job.environment, fingerprint: job.fingerprint,
      ownerSubjectHash: job.ownerSubjectHash ?? null, status, completedAt: at,
      expiresAt: new Date(at + RECEIPT_RETENTION_MILLIS)};
  }

  async function persist(event) {
    const at = now();
    const identities = await Promise.all(event.participants.map(async (uid) =>
      ({uid, created: await generation(uid)})));
    const durable = identities.filter((entry) => entry.created !== null);
    const owner = durable.find((entry) => entry.uid === event.uid);
    const ambiguous = durable.length > 1;
    const jobRef = receipts.doc(event.id);
    return firestore.runTransaction(async (tx) => {
      const existing = await tx.get(jobRef);
      if (existing.exists) return existing.data().fingerprint === event.fingerprint ? 200 : 409;
      const contexts = await Promise.all(durable.map(async (entry) => {
        const id = entitlementDocumentId(entry.uid, event.environment);
        const [marker, customer, entitlement] = await Promise.all([
          tx.get(deletion.doc(entry.uid)), tx.get(customers.doc(id)), tx.get(entitlements.doc(id)),
        ]);
        return {...entry, id, marker, customer: customer.exists ? customer.data() : {},
          entitlement: entitlement.exists ? entitlement.data() : {}};
      }));
      const ownerContext = contexts.find((entry) => entry.uid === owner?.uid);
      // Auth deletion is later than the marker/cleanup phase. Do not recreate
      // even a subject-linked receipt after that account's billing purge.
      if (ownerContext?.marker.exists ||
          (contexts.length > 0 && contexts.every((entry) => entry.marker.exists))) return 200;
      const receiptOwner = ownerContext || contexts.find((entry) => !entry.marker.exists);
      const base = {schemaVersion: 1, fingerprint: event.fingerprint, environment: event.environment,
        ownerSubjectHash: receiptOwner ? subjectHash(receiptOwner.uid) : null};
      if (ambiguous || event.type === "TRANSFER" || event.type === "SUBSCRIBER_ALIAS") {
        // No transfer/alias is a grant. Multiple verified durable owners are
        // quarantined until explicit support resolution; Jin grants untouched.
        if (ambiguous || event.type === "TRANSFER") {
          for (const context of contexts) {
            if (context.marker.exists || context.created > event.eventAt) continue;
            tx.set(customers.doc(context.id), {...withoutRefreshDue(context.customer), schemaVersion: 1,
              ownerUid: context.uid, ownerSubjectHash: subjectHash(context.uid),
              environment: event.environment, accountCreatedAt: context.created,
              generation: (context.customer.generation || 0) + 1, identityBlocked: true,
              leaseOwner: null, leaseUntil: 0});
            tx.set(entitlements.doc(context.id), snapshot(context.uid, event.environment,
              (context.entitlement.revision || 0) + 1, at,
              {status: "inactive", accessUntil: at}));
          }
        }
        tx.set(jobRef, completed(base, "quarantined", at));
        return 200;
      }
      const context = ownerContext;
      if (!context || context.marker.exists || context.created > event.eventAt ||
          (context.customer.accountCreatedAt !== undefined &&
           context.customer.accountCreatedAt !== context.created) || context.customer.identityBlocked) {
        tx.set(jobRef, completed(base, "ignored", at));
        return 200;
      }
      tx.set(customers.doc(context.id), {...context.customer, schemaVersion: 1,
        ownerUid: context.uid, ownerSubjectHash: subjectHash(context.uid),
        environment: event.environment, accountCreatedAt: context.created,
        generation: (context.customer.generation || 0) + 1, identityBlocked: false});
      tx.set(jobRef, {...base, ownerUid: context.uid, accountCreatedAt: context.created,
        eventType: event.type, eventAt: event.eventAt, status: "pending",
        createdAt: at, nextAttemptAt: at, attempts: 0});
      return 200;
    });
  }

  async function webhook(request, response) {
    try {
      const settings = config();
      if (request.method !== "POST") return response.status(405).send("Method not allowed.");
      if (!Buffer.isBuffer(request.rawBody) || request.rawBody.length > MAX_BODY_BYTES ||
          request.rawBody.length === 0) return response.status(413).send("Invalid body size.");
      if (!/^application\/json(?:\s*;|$)/iu.test(request.headers?.["content-type"] || "")) {
        return response.status(415).send("JSON required.");
      }
      if (!authenticated(request.rawBody, request.headers || {}, settings, now())) {
        return response.status(401).send("Unauthorized.");
      }
      const event = parseEvent(request.rawBody, now());
      if (!event) return response.status(400).send("Invalid event.");
      const status = await persist(event);
      return response.status(status).send(status === 200 ? "Accepted." : "Event conflict.");
    } catch {
      return response.status(503).send("Temporarily unavailable.");
    }
  }

  async function claim(id) {
    if (!/^(PRODUCTION|SANDBOX)_[a-f0-9]{64}$/u.test(id)) return null;
    const at = now();
    const token = randomUUID();
    return firestore.runTransaction(async (tx) => {
      const jobRef = receipts.doc(id);
      const doc = await tx.get(jobRef);
      if (!doc.exists) return null;
      const job = doc.data();
      if (!["pending", "processing"].includes(job.status) || job.nextAttemptAt > at ||
          !candidateUid(job.ownerUid)) return null;
      const customerRef = customers.doc(entitlementDocumentId(job.ownerUid, job.environment));
      const [customerDoc, marker] = await Promise.all([
        tx.get(customerRef), tx.get(deletion.doc(job.ownerUid)),
      ]);
      const customer = customerDoc.exists ? customerDoc.data() : {};
      if (marker.exists || customer.identityBlocked ||
          customer.accountCreatedAt !== job.accountCreatedAt) {
        tx.set(jobRef, completed(job, "ignored", at));
        return null;
      }
      if (customer.leaseUntil > at) {
        tx.set(jobRef, {...job, status: "pending", nextAttemptAt: customer.leaseUntil});
        return null;
      }
      const leaseUntil = at + LEASE_MILLIS;
      const needsReview = at - job.createdAt > NEEDS_REVIEW_AFTER_MILLIS;
      tx.set(customerRef, {...customer, leaseOwner: token, leaseUntil});
      tx.set(jobRef, {...job, status: "processing", leaseOwner: token, leaseUntil,
        nextAttemptAt: leaseUntil, attempts: (job.attempts || 0) + 1, needsReview});
      return {id, token, job: {...job, attempts: (job.attempts || 0) + 1},
        generation: customer.generation, customerRef};
    });
  }

  async function settle(work, state, outcome) {
    const at = now();
    return firestore.runTransaction(async (tx) => {
      const jobRef = receipts.doc(work.id);
      const entitlementRef = entitlements.doc(entitlementDocumentId(work.job.ownerUid, work.job.environment));
      const [jobDoc, customerDoc, marker, entitlementDoc] = await Promise.all([
        tx.get(jobRef), tx.get(work.customerRef), tx.get(deletion.doc(work.job.ownerUid)), tx.get(entitlementRef),
      ]);
      const job = jobDoc.exists ? jobDoc.data() : {};
      const customer = customerDoc.exists ? customerDoc.data() : {};
      if (job.leaseOwner !== work.token || customer.leaseOwner !== work.token ||
          customer.leaseUntil <= at) return "stale";
      const cleared = {...customer, leaseOwner: null, leaseUntil: 0};
      if (marker.exists || customer.identityBlocked || outcome === "invalid_identity" ||
          customer.accountCreatedAt !== work.job.accountCreatedAt) {
        // During deletion do not recreate any customer/entitlement document.
        if (!marker.exists) tx.set(work.customerRef, withoutRefreshDue(cleared));
        tx.set(jobRef, completed(job, "ignored", at));
        return "ignored";
      }
      if (outcome === "retry" || customer.generation !== work.generation) {
        const delay = customer.generation !== work.generation ? 0 :
          job.needsReview ? 3600000 : Math.min(3600000, 30000 * 2 ** Math.min(job.attempts || 1, 7));
        tx.set(work.customerRef, cleared);
        tx.set(jobRef, {...job, status: "pending", leaseOwner: null, leaseUntil: 0,
          nextAttemptAt: at + delay});
        return "pending";
      }
      const previous = entitlementDoc.exists ? entitlementDoc.data() : {};
      const blocked = outcome === "quarantined";
      const verified = blocked ? {status: "inactive", accessUntil: at, providerCheckedAt: at} : state;
      tx.set(entitlementRef, snapshot(job.ownerUid, job.environment, (previous.revision || 0) + 1, at, verified));
      const refreshed = {...withoutRefreshDue(cleared), identityBlocked: blocked};
      if (verified.status === "active") {
        refreshed.refreshDueAt = Math.min(at + DAY_MILLIS, verified.accessUntil);
      }
      tx.set(work.customerRef, refreshed);
      tx.set(jobRef, completed(job, blocked ? "quarantined" : "completed", at));
      return "completed";
    });
  }

  async function processEvent(id) {
    let settings;
    try { settings = config(); } catch { return "disabled"; }
    const work = await claim(id);
    if (!work) return "not_claimed";
    try {
      const before = await generation(work.job.ownerUid);
      if (before !== work.job.accountCreatedAt) return settle(work, null, "invalid_identity");
      const payload = await fetchSubscriber(work.job.ownerUid);
      const at = now();
      const state = normalizeSubscriber(payload, {environment: work.job.environment,
        entitlementId: settings.entitlementId, now: at, accountCreatedAt: before});
      const original = payload?.subscriber?.original_app_user_id;
      // A disappeared former Auth account is not proof of ownership transfer.
      // Anonymous RC bootstrap IDs are neutral; another identified original
      // requires explicit ownership resolution, even if Auth no longer has it.
      const differentOriginalOwner = candidateUid(original) && original !== work.job.ownerUid;
      if (await generation(work.job.ownerUid) !== before) return settle(work, null, "invalid_identity");
      return settle(work, state, differentOriginalOwner ? "quarantined" : "completed");
    } catch {
      // A failed GET is not an expiry event. Existing bounded access remains;
      // durable retry is picked up even if the create-trigger already succeeded.
      return settle(work, null, "retry");
    }
  }

  async function enqueueRefresh(customer) {
    if (!candidateUid(customer.ownerUid) || !ACCESS_ENVIRONMENTS.has(customer.environment) ||
        customer.identityBlocked) return;
    const at = now();
    const event = {id: billingEventId(customer.environment,
      `refresh:${subjectHash(customer.ownerUid)}:${Math.floor(at / 3600000)}`),
    environment: customer.environment, uid: customer.ownerUid, type: "SCHEDULED_REFRESH",
    eventAt: at, participants: [customer.ownerUid],
    fingerprint: hash(JSON.stringify(["refresh", customer.environment, subjectHash(customer.ownerUid),
      Math.floor(at / 3600000)]))};
    await persist(event);
  }

  async function sweep() {
    try { config(); } catch { return {disabled: true}; }
    const at = now();
    // Numeric fields support simple single-field indexes. Missing/null due dates
    // are excluded in memory too; no collection-wide user/receipt scans.
    const dueCustomers = await customers.where("refreshDueAt", "<=", at).limit(25).get();
    for (const doc of dueCustomers.docs) {
      const customer = doc.data();
      if (Number.isSafeInteger(customer.refreshDueAt) && customer.refreshDueAt <= at) {
        await enqueueRefresh(customer);
      }
    }
    const due = await receipts.where("nextAttemptAt", "<=", at).limit(25).get();
    for (const doc of due.docs) await processEvent(doc.id);
    const needsReview = await receipts.where("needsReview", "==", true).limit(25).get();
    return {refreshCandidates: dueCustomers.docs.length, processedCandidates: due.docs.length,
      needsReviewCandidates: needsReview.docs.length};
  }

  return {webhook, processEvent, sweep};
}

module.exports = {BILLING_WEBHOOK_OPTIONS, BILLING_WORKER_OPTIONS, BILLING_SCHEDULE_OPTIONS,
  MAX_BODY_BYTES, LEASE_MILLIS, billingEventId, createBillingRuntime};
