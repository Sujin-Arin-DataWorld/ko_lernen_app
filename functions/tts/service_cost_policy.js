"use strict";

// Canonical shared Node cost boundary. TTS carries a deployment-local checked copy.
const DAY_MS = 86400000;
class ServiceCostError extends Error {
  constructor(code, message) { super(message); this.code = code; }
}

const safeInt = (n) => Number.isSafeInteger(n) && n >= 0;
const approvalText = (v) => typeof v === "string" && v.trim().length > 0 &&
  Buffer.byteLength(v, "utf8") <= 512 && !/[\u0000-\u001f\u007f]/u.test(v);

async function readCostControl(db, tx, now) {
  const snapshot = await tx.get(db.collection("service_cost_controls").doc("ai_v1"));
  const config = snapshot.exists ? snapshot.data() : null;
  const approvedAt = config?.approvedAt instanceof Date ? config.approvedAt.getTime() :
    config?.approvedAt?.toMillis ? config.approvedAt.toMillis() : config?.approvedAt;
  if (config?.schemaVersion !== 1 || config.approvedBy !== "Jin" || !approvalText(config.approvalRef) ||
      !safeInt(approvedAt) || approvedAt > now.getTime() || !safeInt(config.dailyUnitLimit) ||
      !safeInt(config.bookReservationUnits) || config.bookReservationUnits === 0 ||
      !safeInt(config.pronunciationReservationUnits) || config.pronunciationReservationUnits === 0 ||
      !safeInt(config.ttsReservationUnits) || config.ttsReservationUnits === 0) {
    throw new ServiceCostError("unavailable", "AI cost approval unavailable.");
  }
  return config;
}

// Shared by all environments and AI endpoints: these are approved reservation
// units for bounded worst-case requests, not measured currency or client claims.
async function prepareCostReservation(db, tx, now, config, existing, kind = "pronunciation") {
  const field = {book: "bookReservationUnits", pronunciation: "pronunciationReservationUnits", tts: "ttsReservationUnits"}[kind];
  if (!field) throw new ServiceCostError("unavailable", "Unknown AI cost scope.");
  const day = now.toISOString().slice(0, 10);
  // Reclaimed undispatched claims carry an old reservation. On a different UTC
  // day reserve the current day too, without guessing that old work was refunded.
  const ref = db.collection("service_cost_ledgers").doc(day);
  const snapshot = await tx.get(ref);
  const previous = snapshot.exists ? snapshot.data() : {reservedUnits: 0};
  if (!safeInt(previous.reservedUnits)) {
    throw new ServiceCostError("unavailable", "AI cost ledger unavailable.");
  }
  if (existing?.day === day && safeInt(existing.units) &&
      existing.units >= config[field] && snapshot.exists) {
    if (previous.reservedUnits > config.dailyUnitLimit || previous.reservedUnits < existing.units) {
      throw new ServiceCostError("resource-exhausted", "AI service limit reached.");
    }
    return {reservation: existing};
  }
  const units = config[field];
  if (previous.reservedUnits > config.dailyUnitLimit - units) {
    throw new ServiceCostError("resource-exhausted", "AI service limit reached.");
  }
  return {reservation: {day, units}, ref, payload: {schemaVersion: 1, day,
    reservedUnits: previous.reservedUnits + units, updatedAt: now,
    expiresAt: new Date(Date.parse(`${day}T00:00:00Z`) + 2 * DAY_MS)}};
}

module.exports = {ServiceCostError, readCostControl, prepareCostReservation};
