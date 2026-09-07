"use strict";

const {resolveAccess} = require("./access_policy");
const {readCostControl, prepareCostReservation} = require("./service_cost_policy");
const {FREE_TIER_DAILY_ASSESSMENTS} = require("./pronunciation_free_tier");

async function resolvePronunciationPolicy(db, uid, tx, now) {
  const environment = process.env.ACCESS_ENVIRONMENT || "PRODUCTION";
  const access = resolveAccess({uid, environment, now: now.getTime()});
  // min(): the free-tier cap only tightens dispatch while azure_f0 is the sole
  // provider; it must never widen the universal access policy's own limit.
  return {minuteLimit: 5, dayLimit: Math.min(FREE_TIER_DAILY_ASSESSMENTS, access.pronunciationDailyLimit)};
}

module.exports = {resolvePronunciationPolicy, readCostControl, prepareCostReservation};
