/**
 * 계(契) Cloud Functions — Tier 3e/3f
 * ============================================================================
 * Node.js 18+ (firebase-functions ^5.0.0, firebase-admin ^12.0.0)
 *
 * 세 함수:
 *   1) on_pack_cleared — users/{uid}/packs/{packId} 쓰기 트리거
 *      팩이 '처음' cleared 되면 사용자의 모든 계에 대해:
 *      - weeklyGoalProgress +1
 *      - members/{uid}.weeklyPacksContributed +1
 *      - feed에 pack_cleared 이벤트
 *      (멤버는 rules상 weeklyGoalProgress를 직접 못 써서 이 admin 함수가 필수.)
 *
 *   2) weekly_goal_rollover — 매주 월 00:00 KST
 *      - 100% 달성 → lifetimeGoalsAchieved +1 (공동 한옥 영구 성장) + goal_achieved 피드
 *      - 70%+    → xpBoostActive=true (이번 주 부스트 플래그)
 *      - 진행도 리셋 + 피드 100개 초과분 prune
 *
 *   3) on_report_created — gye/{gyeId}/reports/{reportId} 생성 트리거
 *      같은 targetUid에 서로 다른 신고자 3명+ → members/{targetUid}.status='suspended'
 *      (자동 모더레이션. 신고 status는 reviewed/auto 마킹.)
 *
 * 배포:
 *   cd functions/gye && npm install
 *   firebase deploy --only functions:on_pack_cleared,functions:weekly_goal_rollover,functions:on_report_created
 *   (weekly_goal_rollover는 Cloud Scheduler 자동 생성 — Blaze + Scheduler API 필요.)
 *
 * TODO(후속): FCM 푸시(피드 이벤트 — notification_service의 kein-FCM 정책 결정 후),
 *   memberCount 정합성 재계산, admin 수동 검토 패널.
 * ============================================================================
 */

const admin = require("firebase-admin");
const functions = require("firebase-functions");

admin.initializeApp();
const db = admin.firestore();

/**
 * 팩이 처음 cleared 되는 순간 계 진행도·피드 갱신.
 */
exports.on_pack_cleared = functions.region("europe-west3").firestore
  .document("users/{uid}/packs/{packId}")
  .onWrite(async (change, context) => {
    const after = change.after.data();
    if (!after) return; // 삭제 이벤트 무시

    if (after.status !== "cleared") return;

    const before = change.before.data() || {};
    if (before.status === "cleared") return; // 이미 cleared → 중복 카운트 방지

    const uid = context.params.uid;
    const packId = context.params.packId;

    try {
      const userDoc = await db.collection("users").doc(uid).get();
      const userData = userDoc.data() || {};
      const gyeIds = userData.gyeIds || [];

      for (const gid of gyeIds) {
        const gref = db.collection("gye").doc(gid);
        const msnap = await gref.collection("members").doc(uid).get();

        if (!msnap.exists) continue; // 멤버 아님(캐시 불일치) → 건너뜀

        const memberData = msnap.data() || {};
        const nickname = memberData.nickname || "";

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

        // TODO: FCM 푸시 — 계 멤버 토큰 수집 후 "{nickname}님이 팩 클리어!" 전송.
      }
    } catch (error) {
      console.error(`[on_pack_cleared] Error for uid=${uid}:`, error);
    }
  });

/**
 * 매주 월 00:00 KST — 주간 진행도 리셋 + 보상.
 *   100% 달성 → lifetimeGoalsAchieved +1 (공동 한옥 영구 unlock) + goal_achieved 피드.
 *   70%+      → xpBoostActive = true.
 *   리셋 후 피드 100개 초과분 prune.
 */
exports.weekly_goal_rollover = functions.region("europe-west3").pubsub
  .schedule("0 0 * * 1")
  .timeZone("Asia/Seoul")
  .onRun(async () => {
    try {
      const gyeSnapshot = await db.collection("gye").get();

      for (const gdoc of gyeSnapshot.docs) {
        const gref = gdoc.ref;
        const meta = gdoc.data() || {};
        const progress = parseInt(meta.weeklyGoalProgress || 0, 10);
        const goal = parseInt(meta.weeklyGoalPacks || 0, 10);

        // 보상 판정 — 목표가 설정돼 있을 때만(goal>0).
        const achieved = goal > 0 && progress >= goal; // 100%+
        const boost = goal > 0 && progress >= Math.ceil(goal * 0.7); // 70%+

        const batch = db.batch();
        const metaUpdate = { weeklyGoalProgress: 0, xpBoostActive: boost };
        if (achieved) {
          // 공동 한옥 영구 요소 +1 (gye_hanok이 lifetimeGoalsAchieved로 unlock).
          metaUpdate.lifetimeGoalsAchieved =
            admin.firestore.FieldValue.increment(1);
          batch.set(gref.collection("feed").doc(), {
            type: "goal_achieved",
            actorUid: "",
            actorNickname: "",
            payload: { goal, progress },
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
        batch.update(gref, metaUpdate);

        const membersSnapshot = await gref.collection("members").get();
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
  });

/**
 * 신고 생성 트리거 — 같은 targetUid에 **서로 다른 신고자 3명+** → 자동 suspend.
 * rules상 members.status는 client가 직접 못 바꿈(정지 회피 방지) → admin SDK 필수.
 */
exports.on_report_created = functions.region("europe-west3").firestore
  .document("gye/{gyeId}/reports/{reportId}")
  .onCreate(async (snap, context) => {
    const report = snap.data() || {};
    const targetUid = report.targetUid;
    const gyeId = context.params.gyeId;
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
  });

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
 * 토큰 없으면 조용히 무동작. (피드 push는 스팸 우려로 현재 goal_achieved만.)
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
