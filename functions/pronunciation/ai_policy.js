"use strict";

const {entitlementDocumentId, resolveAccess} = require("./access_policy");
const {readCostControl, prepareCostReservation} = require("./service_cost_policy");

async function resolvePronunciationPolicy(db, uid, tx, now, accountCreatedAt) {
  const environment = process.env.ACCESS_ENVIRONMENT || "PRODUCTION";
  const phase = process.env.ACCESS_PHASE || "free_launch";
  const [grant, entitlement] = await Promise.all([
    tx.get(db.collection("premium_grants").doc(uid)),
    tx.get(db.collection("customer_entitlements").doc(entitlementDocumentId(uid, environment))),
  ]);
  const access = resolveAccess({uid, environment, phase, now: now.getTime(), accountCreatedAt,
    grant: grant.exists ? grant.data() : null, entitlement: entitlement.exists ? entitlement.data() : null});
  return {minuteLimit: 5, dayLimit: access.pronunciationDailyLimit};
}

module.exports = {resolvePronunciationPolicy, readCostControl, prepareCostReservation};
