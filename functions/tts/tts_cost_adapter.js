"use strict";
const {readCostControl, prepareCostReservation} = require("./service_cost_policy");

async function prepareTtsCost(db, tx, now, existing) {
  const config = await readCostControl(db, tx, now);
  return prepareCostReservation(db, tx, now, config, existing, "tts");
}

// Recheck current cap and UTC day immediately before the expensive call. Never
// refund cost on uncertain provider/save outcomes or legacy request-count refunds.
async function confirmTtsCost(db, existing) {
  return db.runTransaction(async (tx) => {
    const cost = await prepareTtsCost(db, tx, new Date(), existing);
    if (cost.ref) tx.set(cost.ref, cost.payload);
    return cost.reservation;
  });
}

module.exports = {prepareTtsCost, confirmTtsCost};
