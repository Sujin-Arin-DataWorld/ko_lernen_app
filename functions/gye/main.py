# 계(契) Cloud Functions — Tier 3e SKELETON
# ============================================================================
# ⚠️ 미검증 스켈레톤. 검토 + 배포 + 실검증 = Jin.
#
# 왜 별도 SDK인가: 기존 `functions/analyze_korean_text`는 functions_framework
# (HTTP, gcloud gen2)다. Firestore 트리거 + 스케줄은 firebase_functions SDK가
# 표준이라 여기선 그걸 쓴다(별도 source). 두 함수:
#   1) on_pack_cleared      — users/{uid}/packs/{packId} 쓰기 트리거.
#      팩이 '처음' cleared 되면 사용자의 모든 계에 대해 weeklyGoalProgress +1,
#      members/{uid}.weeklyPacksContributed +1, feed에 pack_cleared 이벤트.
#      (멤버는 rules상 weeklyGoalProgress를 직접 못 써서 이 admin 함수가 필수.)
#   2) weekly_goal_rollover — 매주 월 00:00 KST. 진행도 리셋 + 70/100% 보상.
#
# 배포(예시 — Jin이 firebase.json codebase 분리 또는 별도 프로젝트로):
#   pip install -r requirements.txt
#   firebase deploy --only functions:on_pack_cleared,functions:weekly_goal_rollover
#
# TODO(검증 후): 피드 100개 초과 prune, FCM 푸시(피드 이벤트), 보상 로직 확정,
#   memberCount 정합성(가입/탈퇴 시 재계산), reports 자동 suspend 임계.
# ============================================================================
from __future__ import annotations

from firebase_admin import firestore, initialize_app
from firebase_functions import firestore_fn, scheduler_fn

initialize_app()


@firestore_fn.on_document_written(document="users/{uid}/packs/{packId}")
def on_pack_cleared(event: firestore_fn.Event) -> None:
    """팩이 처음 cleared 되는 순간 계 진행도·피드 갱신."""
    after = event.data.after
    if after is None:
        return  # 삭제 이벤트 무시
    after_d = after.to_dict() or {}
    if after_d.get("status") != "cleared":
        return
    before = event.data.before
    before_d = (before.to_dict() if before is not None else {}) or {}
    if before_d.get("status") == "cleared":
        return  # 이미 cleared → 중복 카운트 방지

    uid = event.params["uid"]
    db = firestore.client()
    user = db.collection("users").document(uid).get().to_dict() or {}
    gye_ids = user.get("gyeIds", []) or []

    for gid in gye_ids:
        gref = db.collection("gye").document(gid)
        msnap = gref.collection("members").document(uid).get()
        if not msnap.exists:
            continue  # 멤버 아님(캐시 불일치) → 건너뜀
        nickname = (msnap.to_dict() or {}).get("nickname", "")

        batch = db.batch()
        batch.update(gref, {"weeklyGoalProgress": firestore.Increment(1)})
        batch.update(
            gref.collection("members").document(uid),
            {"weeklyPacksContributed": firestore.Increment(1)},
        )
        batch.set(
            gref.collection("feed").document(),
            {
                "type": "pack_cleared",
                "actorUid": uid,
                "actorNickname": nickname,
                "payload": {"packId": event.params.get("packId", "")},
                "createdAt": firestore.SERVER_TIMESTAMP,
            },
        )
        batch.commit()
        # TODO: FCM 푸시 — 계 멤버 토큰 수집 후 "{nickname}님이 팩 클리어!" 전송.


@scheduler_fn.on_schedule(schedule="0 0 * * 1", timezone="Asia/Seoul")
def weekly_goal_rollover(event: scheduler_fn.ScheduledEvent) -> None:
    """매주 월 00:00 KST — 주간 진행도 리셋 + 보상(스켈레톤)."""
    db = firestore.client()
    for gdoc in db.collection("gye").stream():
        gref = gdoc.reference
        meta = gdoc.to_dict() or {}
        progress = int(meta.get("weeklyGoalProgress", 0) or 0)
        goal = int(meta.get("weeklyGoalPacks", 0) or 0)

        # TODO: 보상 로직 확정 — 100% 달성 시 공동 한옥 영구 장식 1개,
        #       70%+ 시 다음 주 XP +10%. 현재는 리셋만.
        achieved = goal > 0 and progress >= goal  # noqa: F841 (보상 로직 대기)

        gref.update({"weeklyGoalProgress": 0})
        for m in gref.collection("members").stream():
            m.reference.update({"weeklyPacksContributed": 0})
