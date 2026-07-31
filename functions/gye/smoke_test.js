#!/usr/bin/env node
/**
 * 계(契) Cloud Functions 배포 후 스모크 테스트 (Firestore 트리거 검증).
 *
 * 사용:
 *   export GOOGLE_APPLICATION_CREDENTIALS=/경로/serviceAccountKey.json
 *   cd functions/gye && npm install && node smoke_test.js   (또는 npm run smoke)
 *
 * 무엇을 검증하나 (배포된 함수가 실제로 도는지):
 *   1) on_pack_cleared  — 멤버가 팩 클리어 → 계 weeklyGoalProgress +1 + feed pack_cleared
 *   2) on_report_created — 서로 다른 3명 신고 → 대상 멤버 status=suspended
 *
 * ⚠️ weekly_goal_rollover 는 **스케줄(월 0시 KST)**이라 자동 스모크에서 제외.
 *   수동 검증: `gcloud scheduler jobs run firebase-schedule-weekly_goal_rollover-...`
 *   (배포 시 자동 생성된 job 이름은 `gcloud scheduler jobs list` 로 확인.)
 *
 * 테스트 데이터는 `SMOKE…` 프리픽스로 만들고 끝나면 recursiveDelete 로 정리한다.
 * admin SDK 는 rules 를 우회하므로 임의 doc id 사용 가능.
 */
const { initializeApp } = require("firebase-admin/app");
const { FieldValue, getFirestore } = require("firebase-admin/firestore");

initializeApp({ projectId: process.env.GCLOUD_PROJECT || "ko-lernen-app" });
const db = getFirestore();
const TS = FieldValue.serverTimestamp();
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function poll(label, fn, { tries = 20, delay = 1500 } = {}) {
  for (let i = 0; i < tries; i++) {
    if (await fn()) {
      console.log(`✅ ${label} (~${((i + 1) * delay) / 1000}s)`);
      return true;
    }
    await sleep(delay);
  }
  console.log(`❌ ${label} — ${(tries * delay) / 1000}s 내 미충족`);
  return false;
}

async function main() {
  const ts = Date.now();
  const gyeId = `SMOKE${String(ts).slice(-6)}`;
  const owner = `smoke_owner_${ts}`;
  const a = `smoke_a_${ts}`;
  const reporters = [`smoke_r1_${ts}`, `smoke_r2_${ts}`, `smoke_r3_${ts}`];
  const results = [];
  console.log(`테스트 gye=${gyeId}\n`);

  try {
    // setup: 계 메타 + 멤버(owner, a) + a 의 user 인덱스
    await db.doc(`gye/${gyeId}`).set({
      name: "SMOKE", code: gyeId, ownerId: owner, memberCount: 2,
      weeklyGoalPacks: 1, weeklyGoalProgress: 0, lifetimeGoalsAchieved: 0,
      createdAt: TS,
    });
    await db.doc(`gye/${gyeId}/members/${owner}`).set(
      { nickname: "owner", role: "owner", status: "active", weeklyPacksContributed: 0 });
    await db.doc(`gye/${gyeId}/members/${a}`).set(
      { nickname: "a", role: "member", status: "active", weeklyPacksContributed: 0 });
    await db.doc(`users/${a}`).set({ gyeIds: [gyeId] }, { merge: true });

    // 1) on_pack_cleared
    await db.doc(`users/${a}/packs/smoke_pack_${ts}`).set({ status: "cleared", clearedAt: TS });
    results.push(await poll("on_pack_cleared → weeklyGoalProgress ≥ 1", async () => {
      const m = await db.doc(`gye/${gyeId}`).get();
      return (m.data() && m.data().weeklyGoalProgress) >= 1;
    }));
    results.push(await poll("on_pack_cleared → feed pack_cleared", async () => {
      const f = await db.collection(`gye/${gyeId}/feed`)
        .where("type", "==", "pack_cleared").limit(1).get();
      return !f.empty;
    }));

    // 2) on_report_created — 서로 다른 3명
    for (const r of reporters) {
      await db.collection(`gye/${gyeId}/reports`).add({
        reporterUid: r, targetUid: a, reason: "spam", note: "smoke",
        status: "pending", createdAt: TS,
      });
      await sleep(400);
    }
    results.push(await poll("on_report_created → member a suspended", async () => {
      const m = await db.doc(`gye/${gyeId}/members/${a}`).get();
      return m.data() && m.data().status === "suspended";
    }));
  } finally {
    try {
      await db.recursiveDelete(db.doc(`gye/${gyeId}`));
      await db.recursiveDelete(db.doc(`users/${a}`));
      console.log("\n🧹 테스트 데이터 정리됨");
    } catch (e) {
      console.log("\n⚠️ 정리 실패(수동 삭제 필요):", e.message);
    }
  }

  const passed = results.filter(Boolean).length;
  console.log(`\n${passed}/${results.length} 통과`);
  process.exit(passed === results.length ? 0 : 1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
