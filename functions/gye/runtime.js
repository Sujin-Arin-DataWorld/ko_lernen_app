"use strict";

function mergeDeletionCleanupGyeIds(retainedGyeIds, discoveredGyeIds) {
  return Array.from(new Set([
    ...(Array.isArray(retainedGyeIds) ? retainedGyeIds : []),
    ...(Array.isArray(discoveredGyeIds) ? discoveredGyeIds : []),
  ].filter((gyeId) => typeof gyeId === "string" && gyeId.length > 0))).sort();
}

function buildDeletionCleanupTargetClaim({
  retainedGyeIds,
  discoveredGyeIds,
  currentRevision,
}) {
  return {
    gyeIds: mergeDeletionCleanupGyeIds(
      retainedGyeIds,
      discoveredGyeIds,
    ),
    revision: (Number.isInteger(currentRevision) ? currentRevision : 0) + 1,
  };
}

function deletionCleanupTargetClaimMatches(marker, claim) {
  return marker &&
    marker.cleanupRevision === claim.revision &&
    JSON.stringify(mergeDeletionCleanupGyeIds(
      marker.cleanupGyeIds,
      [],
    )) === JSON.stringify(claim.gyeIds);
}

function orphanGyeCleanupUserIds(memberUids, cachedUserUids) {
  return Array.from(new Set([
    ...memberUids,
    ...cachedUserUids,
  ].filter(Boolean))).sort();
}

async function cleanupGyeForDeletedUser({
  anonymizeIdentity,
  reconcileMembership,
  cleanupOrphanTree,
}) {
  await anonymizeIdentity();
  const outcome = await reconcileMembership();
  if (outcome === "missing") {
    await cleanupOrphanTree();
  }
}

async function runDeletedUserCleanupRuntime({
  cleanupGyes,
  cleanupSharedPacks,
  cleanupProcessedPacks,
  cleanupNotificationOutboxes,
  markCleanupComplete,
}) {
  await cleanupGyes();
  await cleanupSharedPacks();
  await cleanupProcessedPacks();
  await cleanupNotificationOutboxes();
  await markCleanupComplete();
}

function stageNotificationOutboxWrites({
  transaction,
  outboxCollection,
  notifications,
  serverTimestamp,
}) {
  for (const notification of notifications) {
    transaction.set(outboxCollection.doc(notification.id), {
      ...notification,
      settledTokenHashes: [],
      attemptCount: 0,
      createdAt: serverTimestamp,
      nextAttemptAt: serverTimestamp,
    });
  }
}

async function processNotificationDocuments(documents, deliver) {
  const failures = [];
  for (const document of documents) {
    try {
      await deliver(document);
    } catch (error) {
      failures.push(error);
    }
  }
  if (failures.length > 0) {
    throw new Error(
      `Notification processing failed for ${failures.length} document(s).`,
      { cause: failures[0] },
    );
  }
}

module.exports = {
  buildDeletionCleanupTargetClaim,
  cleanupGyeForDeletedUser,
  deletionCleanupTargetClaimMatches,
  mergeDeletionCleanupGyeIds,
  orphanGyeCleanupUserIds,
  processNotificationDocuments,
  runDeletedUserCleanupRuntime,
  stageNotificationOutboxWrites,
};
