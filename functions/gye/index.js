/**
 * 계(契) Cloud Functions — Tier 3e SKELETON
 * ============================================================================
 * Node.js 18+ (firebase-functions ^5.0.0, firebase-admin ^12.0.0)
 *
 * 두 함수:
 *   1) on_pack_cleared — users/{uid}/packs/{packId} 쓰기 트리거
 *      팩이 '처음' cleared 되면 사용자의 모든 계에 대해:
 *      - weeklyGoalProgress +1
 *      - members/{uid}.weeklyPacksContributed +1
 *      - feed에 pack_cleared 이벤트
 *      (멤버는 rules상 weeklyGoalProgress를 직접 못 써서 이 admin 함수가 필수.)
 *
 *   2) weekly_goal_rollover — 매주 월 00:00 KST
 *      진행도 리셋 + 보상(TODO)
 *
 * 배포:
 *   cd functions/gye
 *   npm install
 *   firebase deploy --only functions:on_pack_cleared,functions:weekly_goal_rollover
 *
 * TODO(검증 후): 피드 100개 초과 prune, FCM 푸시(피드 이벤트), 보상 로직 확정,
 *   memberCount 정합성, reports 자동 suspend 임계.
 * ============================================================================
 */

const admin = require("firebase-admin");
const functions = require("firebase-functions");

admin.initializeApp();
const db = admin.firestore();

/**
 * 팩이 처음 cleared 되는 순간 계 진행도·피드 갱신.
 */
exports.on_pack_cleared = functions.firestore
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
 * 매주 월 00:00 KST — 주간 진행도 리셋 + 보상(스켈레톤).
 */
exports.weekly_goal_rollover = functions.pubsub
  .schedule("0 0 * * 1")
  .timeZone("Asia/Seoul")
  .onRun(async (context) => {
    try {
      const gyeSnapshot = await db.collection("gye").get();

      for (const gdoc of gyeSnapshot.docs) {
        const gref = gdoc.ref;
        const meta = gdoc.data() || {};
        const progress = parseInt(meta.weeklyGoalProgress || 0);
        const goal = parseInt(meta.weeklyGoalPacks || 0);

        // TODO: 보상 로직 확정 — 100% 달성 시 공동 한옥 영구 장식 1개,
        //       70%+ 시 다음 주 XP +10%. 현재는 리셋만.
        // const achieved = goal > 0 && progress >= goal;

        const batch = db.batch();
        batch.update(gref, { weeklyGoalProgress: 0 });

        const membersSnapshot = await gref.collection("members").get();
        for (const mdoc of membersSnapshot.docs) {
          batch.update(mdoc.ref, { weeklyPacksContributed: 0 });
        }

        await batch.commit();
      }

      console.log("[weekly_goal_rollover] Reset complete");
    } catch (error) {
      console.error("[weekly_goal_rollover] Error:", error);
    }
  });
