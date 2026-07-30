/**
 * REQUIRED DEPLOY ORDER (never use a generic functions deploy):
 *   1. npm run deploy:indexes
 *   2. Wait in Firebase Console until every new collection-group index is READY.
 *   3. npm run deploy:rules
 *   4. npm run deploy:functions
 * This prevents account-cleanup triggers from starting before their discovery
 * indexes can serve queries.
 *
 * 계(契) Cloud Functions — Tier 3e/3f (**2nd gen / v2 API**)
 * ============================================================================
 * firebase-functions v2 (onDocumentWritten/onDocumentCreated/onSchedule),
 * firebase-admin. region = europe-west3 (Firestore DB와 동일 — 1st gen은
 * europe-west3 Firestore 트리거 미지원이라 2nd gen 필수).
 *
 * 세 함수:
 *   1) on_pack_cleared — users/{uid}/packs/{packId} 쓰기 트리거
 *      팩이 '처음' cleared 되면 사용자의 모든 계에 대해 weeklyGoalProgress +1 +
 *      members/{uid}.weeklyPacksContributed +1 + feed pack_cleared.
 *   2) weekly_goal_rollover — 매주 월 00:00 KST
 *      100% → lifetimeGoalsAchieved +1 + goal_achieved 피드 · 70%+ → xpBoostActive ·
 *      진행도 리셋 + 피드 100 prune + (달성 시) FCM 푸시.
 *   3) on_report_created — gye/{gyeId}/reports/{reportId} 생성 트리거
 *      같은 targetUid에 서로 다른 신고자 3명+ → members/{targetUid}.status='suspended'.
 *
 * 배포는 REQUIRED DEPLOY ORDER의 codebase별 명령만 사용한다.
 *   weekly_goal_rollover는 Cloud Scheduler 자동 생성 — Blaze + Scheduler API 필요.
 * ============================================================================
 */

const admin = require("firebase-admin");
const functionsLogger = require("firebase-functions/logger");
const { defineSecret } = require("firebase-functions/params");
const { onDocumentWritten, onDocumentCreated, onDocumentDeleted } =
  require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { setGlobalOptions } = require("firebase-functions/v2");
const { HttpsError, onCall, onRequest } =
  require("firebase-functions/v2/https");
const {
  anonymizeFeed,
  anonymizeMeta,
  anonymizeReport,
  anonymizeSticker,
  buildGroupCleanupPlan,
  buildNotificationDeliveryUpdate,
  buildOwnerSuspensionPlan,
  buildWeeklyNotificationOutbox,
  chunkItems,
  classifyMulticastResponses,
  eligibleModerationReporterUids,
  filterUnsettledNotificationTokens,
  groupDeletionUserUids,
  isDeliverableGyeLifecycle,
  isAccountDeletionTombstoneOldEnough,
  isDurableReporterAuth,
  memberDeleteTriggerPlan,
  notificationOutboxBelongsToUid,
  notificationOutboxMaintenanceAction,
  notificationRetryDelayMillis,
  notificationTerminalExpiryMillis,
  pendingReporterUids,
  processedPackKey,
  selectWeeklyMvp,
  settledNotificationTokenHashes,
  shouldCreditPackClear,
  shouldDeleteReportForUid,
  shouldProcessWeeklyRollover,
  weeklyRolloverKey,
} = require("./lifecycle");
const {
  buildDeletionCleanupTargetClaim,
  cleanupGyeForDeletedUser,
  deletionCleanupTargetClaimMatches,
  mergeDeletionCleanupGyeIds,
  orphanGyeCleanupUserIds,
  processNotificationDocuments,
  runDeletedUserCleanupRuntime,
  stageNotificationOutboxWrites,
} = require("./runtime");
const {
  createAccountOperationCallables,
  createAccountOperationRuntime,
  createDeletionWorkerRuntime,
  createDeletionProofHttpEndpoint,
  createDeletionProofHttpHandler,
  createFirestoreAccountOperationRepository,
  createKeyedDeletionProofDigest,
  fetchStagedActionableDeletionCandidates,
  legacyAccountTombstoneCleanupAction,
  runScheduledDeletionCandidate,
} = require("./account_operations_runtime");
const {
  createFirestoreDeletionAdapters,
} = require("./deletion_adapters");

admin.initializeApp();
const db = admin.firestore();
setGlobalOptions({ region: "europe-west3" });
const deletionProofHmacKey = defineSecret("DELETION_PROOF_HMAC_KEY");
const keyedDeletionProofDigest = createKeyedDeletionProofDigest({
  getSecret: () => deletionProofHmacKey.value(),
});

const accountOperationRepository =
  createFirestoreAccountOperationRepository({ firestore: db });
const accountOperationHandlers = createAccountOperationRuntime({
  auth: admin.auth(),
  hashDeletionProof: (proof) =>
    keyedDeletionProofDigest("proof", proof),
  repository: accountOperationRepository,
  revokeAppleAuthorizationCode: async () => {
    const error = new Error("apple-revocation-adapter-unavailable");
    error.code = "apple/revocation-unavailable";
    throw error;
  },
  makeError: (status, safeCode) => new HttpsError(
    status,
    "Account operation request failed.",
    { code: safeCode },
  ),
});
Object.assign(
  exports,
  createAccountOperationCallables({
    handlers: accountOperationHandlers,
    onCall,
    optionsByName: {
      issueDeletionProof: {
        secrets: [deletionProofHmacKey],
      },
    },
  }),
);
const requestDeletionByProofHandler = createDeletionProofHttpHandler({
  repository: accountOperationRepository,
  hashDeletionProof: (proof) =>
    keyedDeletionProofDigest("proof", proof),
  getRateLimitKey: async (request) => keyedDeletionProofDigest(
    "rate",
    typeof request?.ip === "string" ? request.ip : "unknown",
  ),
  consumeRateLimit: ({ key }) =>
    accountOperationRepository.consumePublicProofRequest({ key }),
  logger: functionsLogger,
});
exports.requestDeletionByProof = createDeletionProofHttpEndpoint({
  handler: requestDeletionByProofHandler,
  onRequest,
  options: {
    secrets: [deletionProofHmacKey],
  },
});

const destructiveAdapterUnavailable = async () => {
  const error = new Error("destructive-adapter-unavailable");
  error.code = "failed-precondition";
  throw error;
};
const accountDeletionPageSize = 20;
const firestoreDeletionAdapters = createFirestoreDeletionAdapters({
  firestore: db,
  markerCollection: db.collection("account_deletions"),
  pageSize: accountDeletionPageSize,
});
const accountDeletionWorkerRuntime = createDeletionWorkerRuntime({
  repository: accountOperationRepository,
  auth: admin.auth(),
  deleteUserTreePage: firestoreDeletionAdapters.deleteUserTreePage,
  cleanupCommunity: destructiveAdapterUnavailable,
  cleanupProcessor: destructiveAdapterUnavailable,
  pageSize: accountDeletionPageSize,
});
exports.account_deletion_worker = onSchedule(
  {
    schedule: "every 5 minutes",
    timeZone: "Etc/UTC",
    retryCount: 3,
  },
  async () => {
    const nowMillis = Date.now();
    const candidates = await fetchStagedActionableDeletionCandidates({
      repository: accountOperationRepository,
      collection: db.collection("account_operations"),
      limit: 50,
      nowMillis,
    });
    for (const candidate of candidates) {
      await runScheduledDeletionCandidate({
        candidate,
        repository: accountOperationRepository,
        workerRuntime: accountDeletionWorkerRuntime,
        logger: functionsLogger,
      });
    }
  },
);

/**
 * 팩이 처음 cleared 되는 순간 계 진행도·피드 갱신.
 */
exports.on_pack_cleared = onDocumentWritten(
  {
    document: "users/{uid}/packs/{packId}",
    retry: true,
  },
  async (event) => {
    const after = event.data?.after?.data();
    if (!after) return; // 삭제 이벤트 무시
    if (!shouldCreditPackClear({
      beforeStatus: event.data?.before?.data()?.status,
      afterStatus: after.status,
    })) return;

    const before = event.data?.before?.data() || {};
    if (before.status === "cleared") return; // 이미 cleared → 중복 카운트 방지

    const uid = event.params.uid;
    const packId = event.params.packId;

    try {
      // Bounded self-reported gamification, not a verified credential: rules
      // admit only the 64 shipped packs, while this durable receipt limits
      // each account/pack/Gye tuple to one lifetime contribution.
      const userDoc = await db.collection("users").doc(uid).get();
      const gyeIds = (userDoc.data() || {}).gyeIds || [];

      for (const gid of gyeIds) {
        const gref = db.collection("gye").doc(gid);
        const memberRef = gref.collection("members").doc(uid);
        const banRef = gref.collection("bans").doc(uid);
        const markerRef = db.collection("account_deletions").doc(uid);
        const processingKey = processedPackKey(uid, packId);
        const processedRef = gref
          .collection("processed_packs")
          .doc(processingKey);
        const feedRef = gref.collection("feed").doc(`pack_${processingKey}`);
        await db.runTransaction(async (transaction) => {
          const marker = await transaction.get(markerRef);
          const gmeta = await transaction.get(gref);
          const member = await transaction.get(memberRef);
          const ban = await transaction.get(banRef);
          const processed = await transaction.get(processedRef);
          if (marker.exists ||
              !gmeta.exists ||
              (gmeta.data() || {}).lifecycleState === "deleting" ||
              !member.exists ||
              (member.data() || {}).status !== "active" ||
              ban.exists ||
              !shouldCreditPackClear({
                beforeStatus: before.status,
                afterStatus: after.status,
                receiptExists: processed.exists,
              })) {
            return;
          }
          transaction.update(gref, {
            weeklyGoalProgress: admin.firestore.FieldValue.increment(1),
          });
          transaction.update(memberRef, {
            weeklyPacksContributed: admin.firestore.FieldValue.increment(1),
          });
          transaction.set(feedRef, {
            type: "pack_cleared",
            actorUid: uid,
            actorNickname: (member.data() || {}).nickname || "",
            payload: { packId },
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          transaction.set(processedRef, {
            uid,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });
      }
    } catch (error) {
      console.error(`[on_pack_cleared] Error for uid=${uid}:`, error);
      throw error;
    }
  },
);

/**
 * 매주 월 00:00 KST — 주간 진행도 리셋 + 보상.
 */
exports.weekly_goal_rollover = onSchedule(
  {
    schedule: "0 0 * * 1",
    timeZone: "Asia/Seoul",
    retryCount: 3,
  },
  async (event) => {
    try {
      const rolloverKey = weeklyRolloverKey(
        event.scheduleTime || new Date().toISOString(),
      );
      const gyeSnapshot = await db.collection("gye").get();

      for (const gdoc of gyeSnapshot.docs) {
        const gref = gdoc.ref;
        const feedRef = gref
          .collection("feed")
          .doc(`goal_${rolloverKey}`);
        const result = await db.runTransaction(async (transaction) => {
          const metaSnapshot = await transaction.get(gref);
          if (!metaSnapshot.exists ||
              (metaSnapshot.data() || {}).lifecycleState === "deleting") {
            return { processed: false, achieved: false, name: "" };
          }
          if (!shouldProcessWeeklyRollover(
            (metaSnapshot.data() || {}).lastRolloverKey,
            rolloverKey,
          )) {
            return { processed: false, achieved: false, name: "" };
          }
          const membersSnapshot = await transaction.get(
            gref.collection("members"),
          );
          const bansSnapshot = await transaction.get(
            gref.collection("bans"),
          );
          const bannedUids = new Set(
            bansSnapshot.docs
              .filter((doc) => (doc.data() || {}).active !== false)
              .map((doc) => doc.id),
          );
          const members = membersSnapshot.docs.map((doc) => ({
            uid: doc.id,
            ...(doc.data() || {}),
          }));
          const accountDeletionMarkers = new Map();
          for (const member of membersSnapshot.docs) {
            accountDeletionMarkers.set(
              member.id,
              await transaction.get(
                db.collection("account_deletions").doc(member.id),
              ),
            );
          }
          const deletingUids = new Set(
            Array.from(accountDeletionMarkers.entries())
              .filter(([, marker]) => marker.exists)
              .map(([uid]) => uid),
          );

          const meta = metaSnapshot.data() || {};
          const progress = parseInt(meta.weeklyGoalProgress || 0, 10);
          const goal = parseInt(meta.weeklyGoalPacks || 0, 10);
          const achieved = goal > 0 && progress >= goal;
          const boost =
            goal > 0 && progress >= Math.ceil(goal * 0.7);
          const mvp = selectWeeklyMvp(
            members,
            bannedUids,
            deletingUids,
          );

          const metaUpdate = {
            weeklyGoalProgress: 0,
            xpBoostActive: boost,
            lastWeekMvp: mvp.nickname,
            lastWeekMvpUid: mvp.uid,
            lastWeekMvpPacks: mvp.packs,
            lastRolloverKey: rolloverKey,
          };
          if (achieved) {
            metaUpdate.lifetimeGoalsAchieved =
              admin.firestore.FieldValue.increment(1);
            transaction.set(feedRef, {
              type: "goal_achieved",
              actorUid: "",
              actorNickname: "",
              payload: {
                goal,
                progress,
                mvp: mvp.nickname,
                mvpUid: mvp.uid,
                mvpPacks: mvp.packs,
              },
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            const outbox = buildWeeklyNotificationOutbox({
              gyeId: gdoc.id,
              rolloverKey,
              members,
              bannedUids,
              deletingUids,
              title: "Wochenziel erreicht! \u{1F389}",
              body: `${meta.name || "Euer Gye"} hat das Wochenziel geschafft.`,
            });
            stageNotificationOutboxWrites({
              transaction,
              outboxCollection:
                gref.collection("notification_outbox"),
              notifications: outbox,
              serverTimestamp:
                admin.firestore.FieldValue.serverTimestamp(),
            });
          }
          transaction.update(gref, metaUpdate);
          for (const member of membersSnapshot.docs) {
            transaction.update(member.ref, { weeklyPacksContributed: 0 });
          }
          return {
            processed: true,
          };
        });
        if (!result.processed) continue;
        await pruneFeed(gref, 100);
      }

      console.log("[weekly_goal_rollover] Rollover + rewards complete");
    } catch (error) {
      console.error("[weekly_goal_rollover] Error:", error);
      throw error;
    }
  },
);

/**
 * 신고 생성 트리거 — 같은 targetUid에 서로 다른 신고자 3명+ → 자동 suspend.
 */
exports.on_notification_outbox_created = onDocumentCreated(
  {
    document: "gye/{gyeId}/notification_outbox/{messageId}",
    retry: true,
  },
  async (event) => {
    if (!event.data?.ref) return;
    await deliverNotificationOutboxDocument(event.data.ref);
  },
);

exports.pending_notification_outbox_drain = onSchedule(
  {
    schedule: "every 15 minutes",
    timeZone: "Etc/UTC",
    retryCount: 1,
  },
  async () => {
    const now = admin.firestore.Timestamp.now();
    const [pending, expiredLeases] = await Promise.all([
      db
        .collectionGroup("notification_outbox")
        .where("state", "==", "pending")
        .where("nextAttemptAt", "<=", now)
        .orderBy("nextAttemptAt")
        .limit(100)
        .get(),
      db
        .collectionGroup("notification_outbox")
        .where("state", "==", "sending")
        .where("deliveryLeaseUntil", "<=", now)
        .orderBy("deliveryLeaseUntil")
        .limit(100)
        .get(),
    ]);
    const documents = new Map();
    [...pending.docs, ...expiredLeases.docs].forEach((document) => {
      documents.set(document.ref.path, document);
    });
    await processNotificationDocuments(
      Array.from(documents.values()),
      (document) => deliverNotificationOutboxDocument(document.ref),
    );
  },
);

exports.notification_outbox_retention_cleanup = onSchedule(
  {
    schedule: "every 24 hours",
    timeZone: "Etc/UTC",
    retryCount: 3,
  },
  async () => {
    const nowMillis = Date.now();
    const cutoff = admin.firestore.Timestamp.fromMillis(
      nowMillis - 30 * 24 * 60 * 60 * 1000,
    );
    const terminal = await db
      .collectionGroup("notification_outbox")
      .where("state", "in", ["sent", "skipped"])
      .where("completedAt", "<=", cutoff)
      .orderBy("completedAt")
      .limit(400)
      .get();
    await commitDocumentChunks(
      terminal.docs.filter((document) =>
        notificationOutboxMaintenanceAction({
          state: (document.data() || {}).state,
          completedAtMillis:
            (document.data() || {}).completedAt?.toMillis?.(),
          nowMillis,
        }) === "delete"),
      (batch, document) => batch.delete(document.ref),
    );
  },
);

exports.on_report_created = onDocumentCreated(
  {
    document: "gye/{gyeId}/reports/{reportId}",
    retry: true,
  },
  async (event) => {
    const report = event.data?.data() || {};
    const targetUid = report.targetUid;
    const gyeId = event.params.gyeId;
    if (!targetUid) return;
    const gref = db.collection("gye").doc(gyeId);
    const currentMeta = await gref.get();
    if (!currentMeta.exists) return;
    if ((currentMeta.data() || {}).lifecycleState === "deleting") {
      await db.recursiveDelete(gref);
      return;
    }

    const reportsSnap = await gref
      .collection("reports")
      .where("targetUid", "==", targetUid)
      .get();

      // 서로 다른 신고자만 카운트(동일인 중복 신고 무력화).
    const pendingReports = reportsSnap.docs.filter(
      (doc) => (doc.data() || {}).status === "pending",
    );
    const candidateReporterUids = pendingReporterUids(
      pendingReports.map((doc) => doc.data() || {}),
      targetUid,
    );
    const durableReporters = new Map();
    for (const reporterUid of candidateReporterUids) {
      let reporterAuth;
      try {
        reporterAuth = await admin.auth().getUser(reporterUid);
      } catch (error) {
        if (error?.code === "auth/user-not-found") continue;
        throw error;
      }
      if (!isDurableReporterAuth(reporterAuth)) continue;
      const evidence = pendingReports.find(
        (doc) => (doc.data() || {}).reporterUid === reporterUid,
      );
      if (evidence) durableReporters.set(reporterUid, evidence.ref);
      if (durableReporters.size >= 3) break;
    }
    // Anonymous, disabled, and missing identities cannot drive a destructive
    // moderation action. Transient Auth errors throw so this trigger retries.
    if (durableReporters.size < 3) return;

    const memberRef = gref.collection("members").doc(targetUid);
    const banRef = gref.collection("bans").doc(targetUid);
    const userRef = db.collection("users").doc(targetUid);
    const accountDeletionRef = db
      .collection("account_deletions")
      .doc(targetUid);
    const outcome = await db.runTransaction(async (transaction) => {
      const meta = await transaction.get(gref);
      if (!meta.exists) return { action: "missing" };
      if ((meta.data() || {}).lifecycleState === "deleting") {
        return { action: "deleteGroup" };
      }
      const user = await transaction.get(userRef);
      const accountDeletion = await transaction.get(accountDeletionRef);
      const member = await transaction.get(memberRef);
      const membersSnapshot = await transaction.get(gref.collection("members"));
      const bansSnapshot = await transaction.get(gref.collection("bans"));
      const memberDeletionMarkers = membersSnapshot.empty
        ? []
        : await transaction.getAll(
          ...membersSnapshot.docs.map((doc) =>
            db.collection("account_deletions").doc(doc.id)),
        );
      const currentEvidence = await transaction.getAll(
        ...Array.from(durableReporters.values()),
      );
      const currentReporterUids = pendingReporterUids(
        currentEvidence
          .filter((doc) => doc.exists)
          .map((doc) => doc.data() || {})
          .filter((data) => data.targetUid === targetUid),
        targetUid,
      ).filter((uid) => durableReporters.has(uid));
      if (!user.exists || accountDeletion.exists) {
        return { action: "noop" };
      }
      const members = membersSnapshot.docs.map((doc) => ({
        uid: doc.id,
        ...(doc.data() || {}),
        joinedAtMillis: (doc.data() || {}).joinedAt?.toMillis?.(),
      }));
      const bannedUids = new Set(
        bansSnapshot.docs
          .filter((doc) => (doc.data() || {}).active !== false)
          .map((doc) => doc.id),
      );
      memberDeletionMarkers
        .filter((doc) => doc.exists)
        .forEach((doc) => bannedUids.add(doc.id));
      const targetBan = bansSnapshot.docs.find((doc) => doc.id === targetUid);
      if (targetBan &&
          (targetBan.data() || {}).reason === "automatic_report_threshold" &&
          member.exists &&
          (member.data() || {}).status === "suspended") {
        return { action: "alreadyModerated" };
      }
      if (!member.exists ||
          (member.data() || {}).status !== "active" ||
          bannedUids.has(targetUid)) {
        return { action: "noop" };
      }
      const eligibleReporterUids = eligibleModerationReporterUids(
        currentReporterUids,
        members,
        bannedUids,
      );
      if (eligibleReporterUids.length < 3) return { action: "noop" };
      const plan = buildOwnerSuspensionPlan({
        targetUid,
        ownerId: (meta.data() || {}).ownerId,
        members,
        bannedUids,
      });
      let affectedUsers = [];
      if (plan.action === "deleteGroup") {
        const affectedUids = groupDeletionUserUids(members, targetUid);
        affectedUsers = await transaction.getAll(
          ...affectedUids.map((uid) => db.collection("users").doc(uid)),
        );
      }

      transaction.set(banRef, {
        uid: targetUid,
        active: true,
        reason: "automatic_report_threshold",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      if (member.exists && (member.data() || {}).status !== "suspended") {
        transaction.update(memberRef, {
          status: "suspended",
          ...(plan.action === "transferOwner" ? { role: "member" } : {}),
        });
      } else if (member.exists && plan.action === "transferOwner") {
        transaction.update(memberRef, { role: "member" });
      }
      if (plan.action === "transferOwner") {
        transaction.update(gref, { ownerId: plan.successorUid });
        transaction.update(
          gref.collection("members").doc(plan.successorUid),
          { role: "owner", status: "active" },
        );
      } else if (plan.action === "deleteGroup") {
        affectedUsers.forEach((affectedUser) => {
          if (affectedUser.exists) {
            transaction.update(affectedUser.ref, {
              gyeIds: admin.firestore.FieldValue.arrayRemove(gyeId),
            });
          }
        });
        transaction.set(
          gref,
          { lifecycleState: "deleting" },
          { merge: true },
        );
      }
      return plan;
    });
    if (outcome.action === "missing" || outcome.action === "noop") return;
    if (outcome.action === "alreadyModerated") {
      await reviewPendingReports(pendingReports, targetUid);
      return;
    }
    if (outcome.action === "deleteGroup") {
      await db.recursiveDelete(gref);
      return;
    }

    await reviewPendingReports(pendingReports, targetUid);
    console.log(
      `[on_report_created] Banned ${targetUid} in ${gyeId} ` +
        `(${durableReporters.size} durable distinct reporters)`,
    );
  },
);

exports.on_gye_member_deleted = onDocumentDeleted(
  {
    document: "gye/{gyeId}/members/{uid}",
    retry: true,
  },
  async (event) => {
    const before = event.data?.data() || {};
    const markerRef = db
      .collection("gye")
      .doc(event.params.gyeId)
      .collection("departures")
      .doc(event.params.uid);
    const marker = await markerRef.get();
    const deletedMembershipId = before.membershipId || "legacy";
    const plan = memberDeleteTriggerPlan(
      marker.exists ? marker.data() || {} : null,
      deletedMembershipId,
    );
    if (plan.anonymizeIdentity) {
      await anonymizeGyeIdentity(
        event.params.gyeId,
        event.params.uid,
        before.nickname || "",
      );
    }
    if (plan.completeDepartureMarker) {
      await db.runTransaction(async (transaction) => {
        const parentRef = markerRef.parent.parent;
        const parent = await transaction.get(parentRef);
        const currentMarker = await transaction.get(markerRef);
        if (!parent.exists || !currentMarker.exists) return;
        const currentPlan = memberDeleteTriggerPlan(
          currentMarker.data() || {},
          deletedMembershipId,
        );
        if (!currentPlan.completeDepartureMarker) return;
        transaction.update(markerRef, {
          state: "complete",
          nickname: admin.firestore.FieldValue.delete(),
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
    }
    const outboxes = await markerRef.parent.parent
      .collection("notification_outbox")
      .where("uid", "==", event.params.uid)
      .get();
    await commitDocumentChunks(
      outboxes.docs.filter((document) =>
        notificationOutboxBelongsToUid(
          document.data() || {},
          event.params.uid,
        )),
      (batch, document) => batch.delete(document.ref),
    );
    // Normal leave already updates memberCount and users.gyeIds atomically
    // under rules. Reconciliation here could delete a rapid rejoin. Only the
    // users/{uid} deletion trigger owns forced membership/owner cleanup.
  },
);

exports.on_user_deleted = onDocumentDeleted(
  {
    document: "users/{uid}",
    retry: true,
  },
  async (event) => {
    const uid = event.params.uid;
    const before = event.data?.data() || {};
    const accountMarkerRef = db.collection("account_deletions").doc(uid);
    const accountMarker = await accountMarkerRef.get();
    if (accountMarker.exists &&
        (accountMarker.data() || {}).serverOwned === true) {
      return;
    }
    if (accountMarker.exists &&
        (accountMarker.data() || {}).cleanupComplete === true) {
      return;
    }
    const retainedCleanupGyeIds = accountMarker.exists
      ? (accountMarker.data() || {}).cleanupGyeIds
      : [];
    const gyeIds = new Set(
      mergeDeletionCleanupGyeIds(
        retainedCleanupGyeIds,
        Array.isArray(before.gyeIds) ? before.gyeIds : [],
      ),
    );

    // New member documents carry uid for a collection-group safety net. The
    // pre-delete gyeIds list remains the migration fallback for legacy docs.
    const membershipSnapshot = await db
      .collectionGroup("members")
      .where("uid", "==", uid)
      .get();
    membershipSnapshot.docs.forEach((doc) => {
      const gyeRef = doc.ref.parent.parent;
      if (gyeRef) gyeIds.add(gyeRef.id);
    });
    const departureSnapshot = await db
      .collectionGroup("departures")
      .where("uid", "==", uid)
      .get();
    const departureNicknames = new Map();
    departureSnapshot.docs.forEach((doc) => {
      const gyeRef = doc.ref.parent.parent;
      if (gyeRef) {
        gyeIds.add(gyeRef.id);
        departureNicknames.set(gyeRef.id, (doc.data() || {}).nickname || "");
      }
    });
    const banSnapshot = await db
      .collectionGroup("bans")
      .where("uid", "==", uid)
      .get();
    banSnapshot.docs.forEach((doc) => {
      const gyeRef = doc.ref.parent.parent;
      if (gyeRef) gyeIds.add(gyeRef.id);
    });
    const processedPacksSnapshot = await db
      .collectionGroup("processed_packs")
      .where("uid", "==", uid)
      .get();
    processedPacksSnapshot.docs.forEach((doc) => {
      const gyeRef = doc.ref.parent.parent;
      if (gyeRef) gyeIds.add(gyeRef.id);
    });
    const notificationOutboxSnapshot = await db
      .collectionGroup("notification_outbox")
      .where("uid", "==", uid)
      .get();
    notificationOutboxSnapshot.docs
      .filter((doc) =>
        notificationOutboxBelongsToUid(doc.data() || {}, uid))
      .forEach((doc) => {
        const gyeRef = doc.ref.parent.parent;
        if (gyeRef) gyeIds.add(gyeRef.id);
      });

    const cleanupClaim = await db.runTransaction(async (transaction) => {
      const currentMarker = await transaction.get(accountMarkerRef);
      const currentData = currentMarker.exists
        ? currentMarker.data() || {}
        : {};
      if (currentData.cleanupComplete === true) return null;
      const claim = buildDeletionCleanupTargetClaim({
        retainedGyeIds: currentData.cleanupGyeIds,
        discoveredGyeIds: Array.from(gyeIds),
        currentRevision: currentData.cleanupRevision,
      });
      if (currentMarker.exists) {
        transaction.update(accountMarkerRef, {
          cleanupGyeIds: claim.gyeIds,
          cleanupRevision: claim.revision,
        });
      } else {
        transaction.set(accountMarkerRef, {
          state: "active",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          cleanupGyeIds: claim.gyeIds,
          cleanupRevision: claim.revision,
        });
      }
      return claim;
    });
    if (!cleanupClaim) return;
    gyeIds.clear();
    cleanupClaim.gyeIds.forEach((gyeId) => gyeIds.add(gyeId));

    await runDeletedUserCleanupRuntime({
      cleanupGyes: async () => {
        for (const gyeId of Array.from(gyeIds).sort()) {
          const gref = db.collection("gye").doc(gyeId);
          const member = await gref
            .collection("members")
            .doc(uid)
            .get();
          const nickname = (member.data() || {}).nickname ||
            departureNicknames.get(gyeId) || "";
          await cleanupGyeForDeletedUser({
            anonymizeIdentity: () =>
              anonymizeGyeIdentity(gyeId, uid, nickname),
            reconcileMembership: () =>
              reconcileMembershipAfterDeletion(gyeId, uid),
            cleanupOrphanTree: () =>
              cleanupOrphanedGyeTree(gref, gyeId),
          });
          // Suspension tombstones are durable while an account exists. Once
          // the account is gone, retaining its UID would be unnecessary PII.
          await gref
            .collection("bans")
            .doc(uid)
            .delete();
          await gref
            .collection("departures")
            .doc(uid)
            .delete();
        }
      },
      cleanupSharedPacks: async () => {
        const sharedPacks = await db
          .collection("shared_packs")
          .where("createdBy", "==", uid)
          .get();
        await commitDocumentChunks(sharedPacks.docs, (batch, doc) => {
          batch.delete(doc.ref);
        });
      },
      cleanupProcessedPacks: async () => {
        await commitDocumentChunks(
          processedPacksSnapshot.docs,
          (batch, doc) => batch.delete(doc.ref),
        );
      },
      cleanupNotificationOutboxes: async () => {
        await commitDocumentChunks(
          notificationOutboxSnapshot.docs.filter((doc) =>
            notificationOutboxBelongsToUid(doc.data() || {}, uid)),
          (batch, doc) => batch.delete(doc.ref),
        );
      },
      markCleanupComplete: async () => {
        await db.runTransaction(async (transaction) => {
          const marker = await transaction.get(accountMarkerRef);
          if (!marker.exists ||
              !deletionCleanupTargetClaimMatches(
                marker.data() || {},
                cleanupClaim,
              )) {
            throw new Error(
              "Account cleanup targets changed before completion.",
            );
          }
          const receipt = {
            cleanupComplete: true,
            cleanupCompletedAt:
              admin.firestore.FieldValue.serverTimestamp(),
            authMissingSince: admin.firestore.FieldValue.delete(),
            cleanupGyeIds: admin.firestore.FieldValue.delete(),
            cleanupRevision: admin.firestore.FieldValue.delete(),
          };
          transaction.update(accountMarkerRef, receipt);
        });
      },
    });
  },
);

exports.account_deletion_tombstone_cleanup = onSchedule(
  {
    schedule: "every 24 hours",
    timeZone: "Etc/UTC",
    retryCount: 3,
  },
  async () => {
    const nowMillis = Date.now();
    const snapshot = await db.collection("account_deletions").get();
    for (const marker of snapshot.docs) {
      const markerData = marker.data() || {};
      if (markerData.serverOwned === true) continue;
      const createdAtMillis = markerData.createdAt?.toMillis?.();
      if (!isAccountDeletionTombstoneOldEnough(
        createdAtMillis,
        nowMillis,
      )) {
        continue;
      }
      let authUserExists = true;
      try {
        await admin.auth().getUser(marker.id);
      } catch (error) {
        if (error?.code === "auth/user-not-found") {
          authUserExists = false;
        } else {
          throw error;
        }
      }
      await db.runTransaction(async (transaction) => {
        const [currentMarker, currentUser] = await Promise.all([
          transaction.get(marker.ref),
          transaction.get(db.collection("users").doc(marker.id)),
        ]);
        if (!currentMarker.exists) return;
        const currentData = currentMarker.data() || {};
        const currentCreatedAtMillis = currentData.createdAt?.toMillis?.();
        // A replacement/generation change must never inherit stale Auth
        // evidence from the scheduler's outer snapshot.
        if (currentData.state !== markerData.state ||
            currentCreatedAtMillis !== createdAtMillis ||
            !isAccountDeletionTombstoneOldEnough(
              currentCreatedAtMillis,
              nowMillis,
            )) {
          return;
        }
        const action = legacyAccountTombstoneCleanupAction({
          marker: currentData,
          authUserExists,
          firestoreUserExists: currentUser.exists,
          cleanupComplete: currentData.cleanupComplete === true,
          cleanupStarted:
            currentData.cleanupComplete === true ||
            Object.prototype.hasOwnProperty.call(
              currentData,
              "cleanupRevision",
            ) ||
            Object.prototype.hasOwnProperty.call(
              currentData,
              "cleanupGyeIds",
            ),
          authMissingSinceMillis: currentData.authMissingSince?.toMillis?.(),
          nowMillis,
        });
        if (action === "cancel" || action === "delete") {
          transaction.delete(currentMarker.ref);
        } else if (action === "markMissing") {
          transaction.update(currentMarker.ref, {
            authMissingSince: admin.firestore.FieldValue.serverTimestamp(),
          });
        } else if (action === "clearMissing") {
          transaction.update(currentMarker.ref, {
            authMissingSince: admin.firestore.FieldValue.delete(),
          });
        }
      });
    }
  },
);

async function commitDocumentChunks(documents, appendMutation) {
  for (const chunk of chunkItems(documents, 450)) {
    const batch = db.batch();
    chunk.forEach((document) => appendMutation(batch, document));
    await batch.commit();
  }
}

async function reviewPendingReports(reportDocuments, targetUid) {
  for (const chunk of chunkItems(reportDocuments, 400)) {
    await db.runTransaction(async (transaction) => {
      const currentReports = await transaction.getAll(
        ...chunk.map((document) => document.ref),
      );
      currentReports.forEach((currentReport) => {
        if (!currentReport.exists) return;
        const data = currentReport.data() || {};
        if (data.status !== "pending" || data.targetUid !== targetUid) return;
        transaction.update(currentReport.ref, {
          status: "reviewed",
          reviewedBy: "auto",
          actionTaken: "suspended",
        });
      });
    });
  }
}

async function anonymizeGyeIdentity(gyeId, uid, legacyNickname) {
  const gref = db.collection("gye").doc(gyeId);
  const meta = await gref.get();
  if (!meta.exists) return;

  const metaSource = meta.data() || {};
  const transformedMeta = anonymizeMeta(
    metaSource,
    uid,
    legacyNickname,
  );
  if (transformedMeta !== metaSource) {
    await db.runTransaction(async (transaction) => {
      const currentMeta = await transaction.get(gref);
      if (!currentMeta.exists ||
          (currentMeta.data() || {}).lifecycleState === "deleting") {
        return;
      }
      const currentMetaSource = currentMeta.data() || {};
      const currentTransformed = anonymizeMeta(
        currentMetaSource,
        uid,
        legacyNickname,
      );
      if (currentTransformed === currentMetaSource) return;
      transaction.update(gref, {
        lastWeekMvpUid: currentTransformed.lastWeekMvpUid,
        lastWeekMvp: currentTransformed.lastWeekMvp,
      });
    });
  }

  const collections = [
    ["feed", (data) => anonymizeFeed(data, uid, legacyNickname)],
    ["reports", (data) => anonymizeReport(data, uid)],
    ["stickers", (data) => anonymizeSticker(data, uid, legacyNickname)],
  ];
  for (const [name, transform] of collections) {
    const snapshot = await gref.collection(name).get();
    const changed = snapshot.docs
      .map((doc) => {
        const source = doc.data() || {};
        const transformed = transform(source);
        if (transformed === source) return null;
        const fields = name === "reports"
          ? {
              reporterUid: transformed.reporterUid,
              targetUid: transformed.targetUid,
              note: transformed.note,
            }
          : name === "stickers"
            ? {
                senderUid: transformed.senderUid,
                senderNickname: transformed.senderNickname,
              }
            : {
                actorUid: transformed.actorUid,
                actorNickname: transformed.actorNickname,
                payload: transformed.payload,
              };
        return { ref: doc.ref, fields };
      })
      .filter(Boolean);
    for (const chunk of chunkItems(changed, 400)) {
      await db.runTransaction(async (transaction) => {
        const currentMeta = await transaction.get(gref);
        if (!currentMeta.exists ||
            (currentMeta.data() || {}).lifecycleState === "deleting") {
          return;
        }
        const currentDocuments = await transaction.getAll(
          ...chunk.map((item) => item.ref),
        );
        currentDocuments.forEach((currentDocument) => {
          if (!currentDocument.exists) return;
          const currentSource = currentDocument.data() || {};
          if (name === "reports" &&
              shouldDeleteReportForUid(currentSource, uid)) {
            transaction.delete(currentDocument.ref);
            return;
          }
          const currentTransformed = transform(currentSource);
          if (currentTransformed === currentSource) return;
          const fields = name === "reports"
            ? {
                reporterUid: currentTransformed.reporterUid,
                targetUid: currentTransformed.targetUid,
                note: currentTransformed.note,
              }
            : name === "stickers"
              ? {
                  senderUid: currentTransformed.senderUid,
                  senderNickname: currentTransformed.senderNickname,
                }
              : {
                  actorUid: currentTransformed.actorUid,
                  actorNickname: currentTransformed.actorNickname,
                  payload: currentTransformed.payload,
                };
          transaction.update(currentDocument.ref, fields);
        });
      });
    }
  }
}

async function cleanupOrphanedGyeTree(gref, gyeId) {
  const action = await db.runTransaction(async (transaction) => {
    const parent = await transaction.get(gref);
    if (parent.exists) {
      return (parent.data() || {}).lifecycleState === "deleting"
        ? "deleteTree"
        : "retryActiveParent";
    }
    const members = await transaction.get(gref.collection("members"));
    const cachedUsers = await transaction.get(
      db.collection("users").where("gyeIds", "array-contains", gyeId),
    );
    const affectedUids = orphanGyeCleanupUserIds(
      members.docs.map((document) => document.id),
      cachedUsers.docs.map((document) => document.id),
    );
    const cachedUserIds = new Set(
      cachedUsers.docs.map((document) => document.id),
    );
    const missingMemberUserRefs = affectedUids
      .filter((uid) => !cachedUserIds.has(uid))
      .map((uid) => db.collection("users").doc(uid));
    const missingMemberUsers = missingMemberUserRefs.length === 0
      ? []
      : await transaction.getAll(
        ...missingMemberUserRefs,
      );
    const affectedUsers = [...cachedUsers.docs, ...missingMemberUsers];
    affectedUsers.forEach((user) => {
      if (user.exists) {
        transaction.update(user.ref, {
          gyeIds: admin.firestore.FieldValue.arrayRemove(gyeId),
        });
      }
    });
    transaction.set(gref, {
      lifecycleState: "deleting",
      orphanCleanup: true,
    });
    return "deleteTree";
  });
  if (action !== "deleteTree") {
    throw new Error(
      `Gye ${gyeId} was recreated while orphan cleanup was starting.`,
    );
  }
  await db.recursiveDelete(gref);
}

async function reconcileMembershipAfterDeletion(gyeId, uid) {
  const gref = db.collection("gye").doc(gyeId);
  const outcome = await db.runTransaction(async (transaction) => {
    const meta = await transaction.get(gref);
    if (!meta.exists) return { action: "missing" };
    if ((meta.data() || {}).lifecycleState === "deleting") {
      return { action: "deleteGroup" };
    }

    const membersSnapshot = await transaction.get(gref.collection("members"));
    const bansSnapshot = await transaction.get(gref.collection("bans"));
    const memberDeletionMarkers = membersSnapshot.empty
      ? []
      : await transaction.getAll(
        ...membersSnapshot.docs.map((doc) =>
          db.collection("account_deletions").doc(doc.id)),
      );
    const members = membersSnapshot.docs.map((doc) => ({
      uid: doc.id,
      ...(doc.data() || {}),
      joinedAtMillis: (doc.data() || {}).joinedAt?.toMillis?.(),
    }));
    const bannedUids = new Set(
      bansSnapshot.docs
        .filter((doc) => (doc.data() || {}).active !== false)
        .map((doc) => doc.id),
    );
    memberDeletionMarkers
      .filter((doc) => doc.exists)
      .forEach((doc) => bannedUids.add(doc.id));
    const plan = buildGroupCleanupPlan({
      departingUid: uid,
      ownerId: (meta.data() || {}).ownerId,
      members,
      bannedUids,
    });

    if (plan.action === "deleteGroup") {
      const affectedUserRefs = groupDeletionUserUids(members)
        .map((memberUid) => db.collection("users").doc(memberUid));
      const affectedUsers = affectedUserRefs.length === 0
        ? []
        : await transaction.getAll(...affectedUserRefs);
      affectedUsers.forEach((affectedUser) => {
        if (affectedUser.exists) {
          transaction.update(affectedUser.ref, {
            gyeIds: admin.firestore.FieldValue.arrayRemove(gyeId),
          });
        }
      });
      transaction.set(gref, { lifecycleState: "deleting" }, { merge: true });
      return plan;
    }

    const departingRef = gref.collection("members").doc(uid);
    if (members.some((member) => member.uid === uid)) {
      transaction.delete(departingRef);
    }
    if (plan.action === "transferOwner") {
      transaction.update(gref, {
        ownerId: plan.successorUid,
        memberCount: plan.memberCount,
        lifecycleState: "active",
      });
      transaction.update(gref.collection("members").doc(plan.successorUid), {
        role: "owner",
        status: "active",
      });
    } else {
      const currentCount = (meta.data() || {}).memberCount;
      if (currentCount !== plan.memberCount) {
        transaction.update(gref, { memberCount: plan.memberCount });
      }
    }
    return plan;
  });

  if (outcome.action === "deleteGroup") {
    // Parent deletion does not remove subcollections. recursiveDelete is
    // intentionally used after lifecycleState closes the client join race.
    await db.recursiveDelete(gref);
  }
  return outcome.action;
}

/**
 * 피드 컬렉션을 최신 [keep]개로 정리. rules상 feed delete는 CF(admin)만 가능.
 * 한 번에 최대 400개 삭제(batch 500 한도 안전).
 */
async function pruneFeed(gref, keep) {
  try {
    const snap = await gref
      .collection("feed")
      .orderBy("createdAt", "desc")
      .offset(keep)
      .limit(400)
      .get();
    if (snap.empty) return;
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
  } catch (e) {
    console.error("[pruneFeed] Error:", e);
  }
}

async function claimNotificationOutbox(outboxRef) {
  const claimId = db.collection("_notification_claims").doc().id;
  const nowMillis = Date.now();
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(outboxRef);
    if (!snapshot.exists) return null;
    const data = snapshot.data() || {};
    const action = notificationOutboxMaintenanceAction({
      state: data.state,
      leaseUntilMillis: data.deliveryLeaseUntil?.toMillis?.(),
      nextAttemptAtMillis: data.nextAttemptAt?.toMillis?.(),
      nowMillis,
    });
    if (action !== "deliver") return null;
    transaction.update(outboxRef, {
      state: "sending",
      deliveryClaimId: claimId,
      nextAttemptAt: admin.firestore.FieldValue.delete(),
      deliveryLeaseUntil: admin.firestore.Timestamp.fromMillis(
        nowMillis + 5 * 60 * 1000,
      ),
      lastAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
      attemptCount: admin.firestore.FieldValue.increment(1),
    });
    return { claimId, data };
  });
}

async function finishNotificationOutboxClaim({
  outboxRef,
  claimId,
  update,
  userRef,
  permanentFailureTokens = [],
}) {
  return db.runTransaction(async (transaction) => {
    const current = await transaction.get(outboxRef);
    if (!current.exists) return false;
    const currentData = current.data() || {};
    if (currentData.state !== "sending" ||
        currentData.deliveryClaimId !== claimId) {
      return false;
    }
    let currentUser = null;
    if (userRef && permanentFailureTokens.length > 0) {
      currentUser = await transaction.get(userRef);
    }
    if (currentUser?.exists) {
      transaction.update(userRef, {
        fcmTokens: admin.firestore.FieldValue.arrayRemove(
          ...permanentFailureTokens,
        ),
      });
    }
    transaction.update(outboxRef, {
      ...update,
      deliveryClaimId: admin.firestore.FieldValue.delete(),
      deliveryLeaseUntil: admin.firestore.FieldValue.delete(),
    });
    return true;
  });
}

async function releaseNotificationOutboxClaim(
  outboxRef,
  claimId,
  attemptCount,
) {
  const nextAttemptAt = admin.firestore.Timestamp.fromMillis(
    Date.now() + notificationRetryDelayMillis(attemptCount),
  );
  await finishNotificationOutboxClaim({
    outboxRef,
    claimId,
    update: {
      state: "pending",
      lastErrorAt: admin.firestore.FieldValue.serverTimestamp(),
      nextAttemptAt,
    },
  });
}

function notificationTerminalFields() {
  const nowMillis = Date.now();
  return {
    completedAt: admin.firestore.Timestamp.fromMillis(nowMillis),
    expiresAt: admin.firestore.Timestamp.fromMillis(
      notificationTerminalExpiryMillis(nowMillis),
    ),
    nextAttemptAt: admin.firestore.FieldValue.delete(),
  };
}

async function deliverNotificationOutboxDocument(outboxRef) {
  const claim = await claimNotificationOutbox(outboxRef);
  if (!claim) return;

  const { claimId, data } = claim;
  const gref = outboxRef.parent.parent;
  const uid = data.uid;
  if (!gref || !uid || typeof data.eventKey !== "string" ||
      typeof data.title !== "string" || typeof data.body !== "string") {
    await finishNotificationOutboxClaim({
      outboxRef,
      claimId,
      update: {
        state: "skipped",
        skipReason: "malformed",
        ...notificationTerminalFields(),
      },
    });
    return;
  }

  const userRef = db.collection("users").doc(uid);
  const [meta, member, ban, marker, user] = await Promise.all([
    gref.get(),
    gref.collection("members").doc(uid).get(),
    gref.collection("bans").doc(uid).get(),
    db.collection("account_deletions").doc(uid).get(),
    userRef.get(),
  ]);
  const ineligible = !meta.exists ||
    !isDeliverableGyeLifecycle((meta.data() || {}).lifecycleState) ||
    !member.exists ||
    (member.data() || {}).status !== "active" ||
    (ban.exists && (ban.data() || {}).active !== false) ||
    marker.exists ||
    !user.exists;
  if (ineligible) {
    await finishNotificationOutboxClaim({
      outboxRef,
      claimId,
      update: {
        state: "skipped",
        skipReason: "ineligible",
        ...notificationTerminalFields(),
      },
    });
    return;
  }

  const rawTokens = Array.isArray((user.data() || {}).fcmTokens)
    ? (user.data() || {}).fcmTokens.filter(
      (token) => typeof token === "string" && token.length > 0,
    )
    : [];
  const settledTokenHashes = Array.isArray(data.settledTokenHashes)
    ? data.settledTokenHashes.filter((hash) => typeof hash === "string")
    : [];
  const tokens = filterUnsettledNotificationTokens(
    rawTokens,
    settledTokenHashes,
  ).slice(0, 500);
  if (tokens.length === 0) {
    const hasPriorDelivery = settledTokenHashes.length > 0;
    await finishNotificationOutboxClaim({
      outboxRef,
      claimId,
      update: {
        state: hasPriorDelivery ? "sent" : "skipped",
        ...(hasPriorDelivery
          ? {
              successCount: data.deliveredTokenCount || 0,
              permanentFailureCount: data.permanentFailureCount || 0,
            }
          : { skipReason: "no_tokens" }),
        ...notificationTerminalFields(),
      },
    });
    return;
  }

  let response;
  try {
    response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title: data.title, body: data.body },
      data: { eventKey: data.eventKey },
      android: { collapseKey: data.eventKey },
      apns: { headers: { "apns-collapse-id": data.eventKey } },
    });
  } catch (error) {
    await releaseNotificationOutboxClaim(
      outboxRef,
      claimId,
      data.attemptCount || 0,
    );
    throw error;
  }

  const classification = classifyMulticastResponses(
    tokens,
    response.responses || [],
  );
  const nextSettledTokenHashes = settledNotificationTokenHashes(
    settledTokenHashes,
    tokens,
    response.responses || [],
  );
  const remainingTokens = filterUnsettledNotificationTokens(
    rawTokens,
    nextSettledTokenHashes,
  );
  const shouldRetry = classification.action === "retry" ||
    remainingTokens.length > 0;
  const effectiveClassification = {
    ...classification,
    action: shouldRetry ? "retry" : "sent",
  };
  const deliveryUpdate = buildNotificationDeliveryUpdate(
    effectiveClassification,
  );
  const finished = await finishNotificationOutboxClaim({
    outboxRef,
    claimId,
    userRef,
    permanentFailureTokens: classification.permanentFailureTokens,
    update: {
      ...deliveryUpdate,
      settledTokenHashes: nextSettledTokenHashes,
      deliveredTokenCount:
        (data.deliveredTokenCount || 0) + classification.successCount,
      permanentFailureCount:
        (data.permanentFailureCount || 0) +
        classification.permanentFailureTokens.length,
      ...(shouldRetry
        ? {
            nextAttemptAt: admin.firestore.Timestamp.fromMillis(
              Date.now() +
              notificationRetryDelayMillis(data.attemptCount || 0),
            ),
          }
        : {
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            ...notificationTerminalFields(),
          }),
    },
  });
  if (finished && shouldRetry) {
    throw new Error("Notification outbox has retryable recipients.");
  }
}
