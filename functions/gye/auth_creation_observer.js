"use strict";

const functionsV1 = require("firebase-functions/v1");
const logger = require("firebase-functions/logger");

function accountKind(user) {
  if (!user || typeof user.uid !== "string" || !user.uid.trim() ||
      !Array.isArray(user.providerData) ||
      !user.providerData.every((provider) =>
        provider && typeof provider.providerId === "string" && provider.providerId.trim()) ||
      (user.email != null && typeof user.email !== "string") ||
      (user.phoneNumber != null && typeof user.phoneNumber !== "string")) {
    return "unknown";
  }
  return user.providerData.length === 0 && !user.email && !user.phoneNumber
    ? "anonymous" : "identified";
}

// Basic Auth creation events use generation 1. The existing generation-2
// account endpoints stay unchanged; this observer runs after account creation.
exports.onAuthAccountCreated = functionsV1
  .region("europe-west3")
  .runWith({ memory: "128MB", timeoutSeconds: 30, maxInstances: 2, failurePolicy: false })
  .auth.user().onCreate((user) => {
    // Only bounded categories are logged: never UID, provider attributes,
    // email, phone, tokens, event payloads or per-account metric labels.
    logger.info("Auth account creation observed", {
      event: "auth_account_created", schemaVersion: 1, accountKind: accountKind(user),
    });
  });
