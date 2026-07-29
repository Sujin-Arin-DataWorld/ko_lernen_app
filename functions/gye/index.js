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
const { onDocumentWritten, onDocumentCreated, onDocumentDeleted } =
  require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { setGlobalOptions } = require("firebase-functions/v2");
const {
  accountTombstoneCleanupAction,
  anonymizeFeed,
  anonymizeMeta,
  anonymizeReport,
  anonymizeSticker,
  buildGroupCleanupPlan,
  buildOwnerSuspensionPlan,
  chunkItems,
  eligibleModerationReporterUids,
  groupDeletionUserUids,
  isAccountDeletionTombstoneOldEnough,
  isDurableReporterAuth,
  memberDeleteTriggerPlan,
  pendingReporterUids,
  processedPackKey,
  selectPushRecipientUids,
  shouldCreditPackClear,
  shouldDeleteReportForUid,
  shouldProcessWeeklyRollover,
  weeklyRolloverKey,
} = require("./lifecycle");

admin.initializeApp();
const db = admin.firestore();
setGlobalOptions({ region: "europe-west3" });

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
          const accountDeletionMarkers = new Map();
          for (const member of membersSnapshot.docs) {
            accountDeletionMarkers.set(
              member.id,
              await transaction.get(
                db.collection("account_deletions").doc(member.id),
              ),
            );
          }

          const meta = metaSnapshot.data() || {};
          const progress = parseInt(meta.weeklyGoalProgress || 0, 10);
          const goal = parseInt(meta.weeklyGoalPacks || 0, 10);
          const achieved = goal > 0 && progress >= goal;
          const boost =
            goal > 0 && progress >= Math.ceil(goal * 0.7);
          let mvp = "";
          let mvpUid = "";
          let mvpPacks = 0;
          for (const member of membersSnapshot.docs) {
            if ((member.data() || {}).status !== "active") continue;
            if (bannedUids.has(member.id)) continue;
            if (accountDeletionMarkers.get(member.id)?.exists) continue;
            const contribution = parseInt(
              (member.data() || {}).weeklyPacksContributed || 0,
              10,
            );
            if (contribution > mvpPacks) {
              mvpPacks = contribution;
              mvp = (member.data() || {}).nickname || "";
              mvpUid = member.id;
            }
          }

          const metaUpdate = {
            weeklyGoalProgress: 0,
            xpBoostActive: boost,
            lastWeekMvp: mvp,
            lastWeekMvpUid: mvpUid,
            lastWeekMvpPacks: mvpPacks,
            lastRolloverKey: rolloverKey,
          };
          if (achieved) {
            metaUpdate.lifetimeGoalsAchieved =
              admin.firestore.FieldValue.increment(1);
            transaction.set(feedRef, {
              type: "goal_achieved",
              actorUid: "",
              actorNickname: "",
              payload: { goal, progress, mvp, mvpUid, mvpPacks },
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
          transaction.update(gref, metaUpdate);
          for (const member of membersSnapshot.docs) {
            transaction.update(member.ref, { weeklyPacksContributed: 0 });
          }
          return {
            processed: true,
            achieved,
            name: meta.name || "Euer Gye",
          };
        });
        if (!result.processed) continue;
        await pruneFeed(gref, 100);
        if (result.achieved) {
          await pushToGyeMembers(
            gref,
            "Wochenziel erreicht! 🎉",
            result.name + " hat das Wochenziel geschafft.",
          );
        }
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
    const gyeIds = new Set(
      Array.isArray(before.gyeIds) ? before.gyeIds.filter(Boolean) : [],
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

    for (const gyeId of Array.from(gyeIds).sort()) {
      const member = await db
        .collection("gye")
        .doc(gyeId)
        .collection("members")
        .doc(uid)
        .get();
      const nickname = (member.data() || {}).nickname ||
        departureNicknames.get(gyeId) || "";
      await anonymizeGyeIdentity(gyeId, uid, nickname);
      await reconcileMembershipAfterDeletion(gyeId, uid);
      // Suspension tombstones are durable while an account exists. Once the
      // account itself is gone, retaining its UID would be unnecessary PII.
      await db
        .collection("gye")
        .doc(gyeId)
        .collection("bans")
        .doc(uid)
        .delete();
      await db
        .collection("gye")
        .doc(gyeId)
        .collection("departures")
        .doc(uid)
        .delete();
    }

    const sharedPacks = await db
      .collection("shared_packs")
      .where("createdBy", "==", uid)
      .get();
    await commitDocumentChunks(sharedPacks.docs, (batch, doc) => {
      batch.delete(doc.ref);
    });
    await commitDocumentChunks(processedPacksSnapshot.docs, (batch, doc) => {
      batch.delete(doc.ref);
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
        const action = accountTombstoneCleanupAction({
          authUserExists,
          firestoreUserExists: currentUser.exists,
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

/**
 * 계 멤버 전체에 FCM 푸시. 토큰은 users/{uid}.fcmTokens(array) — PushService가 저장.
 */
async function pushToGyeMembers(gref, title, body) {
  try {
    const meta = await gref.get();
    if (!meta.exists ||
        (meta.data() || {}).lifecycleState !== "active") {
      return;
    }
    const [membersSnapshot, bansSnapshot] = await Promise.all([
      gref.collection("members").get(),
      gref.collection("bans").get(),
    ]);
    const members = membersSnapshot.docs.map((doc) => ({
      uid: doc.id,
      ...(doc.data() || {}),
    }));
    const bannedUids = new Set(
      bansSnapshot.docs
        .filter((doc) => (doc.data() || {}).active !== false)
        .map((doc) => doc.id),
    );
    const activeUids = members
      .filter((member) => member.status === "active")
      .map((member) => member.uid);
    const deletionMarkers = activeUids.length === 0
      ? []
      : await db.getAll(
        ...activeUids.map((uid) =>
          db.collection("account_deletions").doc(uid)),
      );
    const deletingUids = new Set(
      deletionMarkers.filter((doc) => doc.exists).map((doc) => doc.id),
    );
    const recipientUids = selectPushRecipientUids(
      members,
      bannedUids,
      deletingUids,
    );
    if (recipientUids.length === 0) return;
    const users = await db.getAll(
      ...recipientUids.map((uid) => db.collection("users").doc(uid)),
    );
    const tokens = new Set();
    for (const user of users) {
      if (!user.exists) continue;
      const arr = (user.data() || {}).fcmTokens || [];
      for (const t of arr) {
        if (t) tokens.add(t);
      }
    }
    if (tokens.size === 0) return;
    await admin.messaging().sendEachForMulticast({
      tokens: Array.from(tokens).slice(0, 500),
      notification: { title, body },
    });
  } catch (e) {
    console.error("[pushToGyeMembers] Error:", e);
  }
}
