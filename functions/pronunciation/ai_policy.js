"use strict";

const {resolveAccess} = require("./access_policy");
const {readCostControl, prepareCostReservation} = require("./service_cost_policy");

async function resolvePronunciationPolicy(db, uid, tx, now) {
  const environment = process.env.ACCESS_ENVIRONMENT || "PRODUCTION";
  const access = resolveAccess({uid, environment, now: now.getTime()});
  return {minuteLimit: 5, dayLimit: access.pronunciationDailyLimit};
}

module.exports = {resolvePronunciationPolicy, readCostControl, prepareCostReservation};
