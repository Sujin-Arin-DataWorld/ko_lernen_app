"use strict";

const {resolveAccess} = require("./access_policy");
const {readCostControl, prepareCostReservation} = require("./service_cost_policy");

async function resolvePronunciationPolicy(db, uid, tx, now, accountCreatedAt) {
  const environment = process.env.ACCESS_ENVIRONMENT || "PRODUCTION";
  const phase = process.env.ACCESS_PHASE || "free_launch";
  const access = resolveAccess({uid, environment, phase, now: now.getTime(), accountCreatedAt});
  return {minuteLimit: 5, dayLimit: access.pronunciationDailyLimit};
}

module.exports = {resolvePronunciationPolicy, readCostControl, prepareCostReservation};
