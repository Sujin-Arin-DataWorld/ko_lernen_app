/**
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
 * 배포:  firebase deploy --only functions   (codebase gye-firebase-functions 전체)
 *   weekly_goal_rollover는 Cloud Scheduler 자동 생성 — Blaze + Scheduler API 필요.
 * ============================================================================
 */

const admin = require("firebase-admin");
const { onDocumentWritten, onDocumentCreated } =
  require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { setGlobalOptions } = require("firebase-functions/v2");

admin.initializeApp();
const db = admin.firestore();
setGlobalOptions({ region: "europe-west3" });

/**
 * 팩이 처음 cleared 되는 순간 계 진행도·피드 갱신.
 */
exports.on_pack_cleared = onDocumentWritten(
  "users/{uid}/packs/{packId}",
  async (event) => {
    const after = event.data?.after?.data();
    if (!after) return; // 삭제 이벤트 무시
    if (after.status !== "cleared") return;

    const before = event.data?.before?.data() || {};
    if (before.status === "cleared") return; // 이미 cleared → 중복 카운트 방지

    const uid = event.params.uid;
    const packId = event.params.packId;

    try {
      const userDoc = await db.collection("users").doc(uid).get();
      const gyeIds = (userDoc.data() || {}).gyeIds || [];

      for (const gid of gyeIds) {
        const gref = db.collection("gye").doc(gid);
        const msnap = await gref.collection("members").doc(uid).get();
        if (!msnap.exists) continue; // 멤버 아님(캐시 불일치) → 건너뜀

        const nickname = (msnap.data() || {}).nickname || "";

        const batch = db.batch();
        batch.update(gref, {
          weeklyGoalProgress: admin.firestore.FieldValue.increment(1),
        });
        batch.update(gref.collection("members").doc(uid), {
          weeklyPacksContributed: admin.firestore.FieldValue.increment(1),
        });
        batch.set(gref.collection("feed").doc(), {
          type: "pack_cleared",
          actorUid: uid,
          actorNickname: nickname,
          payload: { packId },
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await batch.commit();
      }
    } catch (error) {
      console.error(`[on_pack_cleared] Error for uid=${uid}:`, error);
    }
  },
);

/**
 * 매주 월 00:00 KST — 주간 진행도 리셋 + 보상.
 */
exports.weekly_goal_rollover = onSchedule(
  { schedule: "0 0 * * 1", timeZone: "Asia/Seoul" },
  async () => {
    try {
      const gyeSnapshot = await db.collection("gye").get();

      for (const gdoc of gyeSnapshot.docs) {
        const gref = gdoc.ref;
        const meta = gdoc.data() || {};
        const progress = parseInt(meta.weeklyGoalProgress || 0, 10);
        const goal = parseInt(meta.weeklyGoalPacks || 0, 10);

        const achieved = goal > 0 && progress >= goal; // 100%+
        const boost = goal > 0 && progress >= Math.ceil(goal * 0.7); // 70%+

        // 4픽 회고: MVP(이번 주 최다 기여자) — reset 전에 계산.
        const membersSnapshot = await gref.collection("members").get();
        let mvp = "";
        let mvpPacks = 0;
        for (const mdoc of membersSnapshot.docs) {
          const c = parseInt(
            (mdoc.data() || {}).weeklyPacksContributed || 0, 10);
          if (c > mvpPacks) {
            mvpPacks = c;
            mvp = (mdoc.data() || {}).nickname || "";
          }
        }

        const batch = db.batch();
        // 지난주 살림꾼 — 클라 _MvpCard가 축하 톤으로 표시 (기여 0이면 빈 값).
        const metaUpdate = {
          weeklyGoalProgress: 0,
          xpBoostActive: boost,
          lastWeekMvp: mvp,
          lastWeekMvpPacks: mvpPacks,
        };
        if (achieved) {
          metaUpdate.lifetimeGoalsAchieved =
            admin.firestore.FieldValue.increment(1);
          batch.set(gref.collection("feed").doc(), {
            type: "goal_achieved",
            actorUid: "",
            actorNickname: "",
            payload: { goal, progress, mvp, mvpPacks },
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
        batch.update(gref, metaUpdate);

        for (const mdoc of membersSnapshot.docs) {
          batch.update(mdoc.ref, { weeklyPacksContributed: 0 });
        }
        await batch.commit();

        await pruneFeed(gref, 100);
        if (achieved) {
          await pushToGyeMembers(
            gref,
            "Wochenziel erreicht! 🎉",
            (meta.name || "Euer Gye") + " hat das Wochenziel geschafft.",
          );
        }
      }

      console.log("[weekly_goal_rollover] Rollover + rewards complete");
    } catch (error) {
      console.error("[weekly_goal_rollover] Error:", error);
    }
  },
);

/**
 * 신고 생성 트리거 — 같은 targetUid에 서로 다른 신고자 3명+ → 자동 suspend.
 */
exports.on_report_created = onDocumentCreated(
  "gye/{gyeId}/reports/{reportId}",
  async (event) => {
    const report = event.data?.data() || {};
    const targetUid = report.targetUid;
    const gyeId = event.params.gyeId;
    if (!targetUid) return;

    try {
      const reportsSnap = await db
        .collection("gye")
        .doc(gyeId)
        .collection("reports")
        .where("targetUid", "==", targetUid)
        .get();

      // 서로 다른 신고자만 카운트(동일인 중복 신고 무력화).
      const reporters = new Set();
      reportsSnap.docs.forEach((d) => {
        const uid = (d.data() || {}).reporterUid;
        if (uid) reporters.add(uid);
      });
      if (reporters.size < 3) return;

      const memberRef = db
        .collection("gye")
        .doc(gyeId)
        .collection("members")
        .doc(targetUid);
      const m = await memberRef.get();
      if (!m.exists || (m.data() || {}).status === "suspended") return;

      const batch = db.batch();
      batch.update(memberRef, { status: "suspended" });
      reportsSnap.docs.forEach((d) => {
        if ((d.data() || {}).status === "pending") {
          batch.update(d.ref, {
            status: "reviewed",
            reviewedBy: "auto",
            actionTaken: "suspended",
          });
        }
      });
      await batch.commit();
      console.log(
        `[on_report_created] Suspended ${targetUid} in ${gyeId} ` +
          `(${reporters.size} distinct reporters)`,
      );
    } catch (error) {
      console.error(`[on_report_created] Error for gye=${gyeId}:`, error);
    }
  },
);

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
    const members = await gref.collection("members").get();
    const tokens = [];
    for (const md of members.docs) {
      const u = await db.collection("users").doc(md.id).get();
      const arr = (u.data() || {}).fcmTokens || [];
      for (const t of arr) {
        if (t) tokens.push(t);
      }
    }
    if (tokens.length === 0) return;
    await admin.messaging().sendEachForMulticast({
      tokens: tokens.slice(0, 500),
      notification: { title, body },
    });
  } catch (e) {
    console.error("[pushToGyeMembers] Error:", e);
  }
}
