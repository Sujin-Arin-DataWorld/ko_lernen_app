/**
 * Auth 삭제 → Firestore 삭제 **브리지**. 정리 로직은 여기 없다.
 *
 * 설계 근거는 functions/gye/index.js:1022 주석이 정본이다:
 *   "Only the users/{uid} deletion trigger owns forced membership/owner cleanup."
 *
 * 즉 강제 멤버 제거·계장 승계·memberCount 정합·피드/신고/스티커 익명화는
 * `on_user_deleted`(onDocumentDeleted "users/{uid}") 하나가 소유한다. 이 브리지는
 * users/{uid} 트리를 지워 **그 트리거를 깨우는 일만** 한다.
 *
 * ⛔ 여기에 승계 규칙을 복제하지 말 것. 2026-08-12 에 그렇게 만들었다가
 *    lifecycle.js 와 어긋나 세 가지가 틀렸다:
 *      ① status !== "active" 와 ban 을 안 걸러 차단된 멤버가 계장이 될 수 있었다
 *      ② joinedAt 누락을 0 으로 봐서 오히려 **맨 앞** 후보가 됐다
 *         (lifecycle.js 는 Number.MAX_SAFE_INTEGER 로 뒤로 보낸다)
 *      ③ memberCount 를 무조건 increment(-1) 로 깎아 중복 전달에 취약했다
 *         (main 은 일반 경로 Math.max(0, n-1) + 계장 경로 절대 remainingCount)
 *
 *    실제 피해는 두 가지였다. 하나는 **정식 cleanup 이 이미 손댄 데이터 위에서
 *    돌게 만든 것** — 그 함수도 마지막에 users/{uid} 를 지워 on_user_deleted 를
 *    깨웠으므로 익명화·페이징은 그 뒤에 수행됐다(익명화를 "통째로 건너뛴" 것은
 *    아니다). 문제는 그 전에 gye 를 불완전한 규칙으로 먼저 바꿔 둔 점이다.
 *    다른 하나는 **그 마지막 삭제의 실패를 catch 로 삼킨 것** — 삭제가 실패하면
 *    on_user_deleted 가 아예 발화하지 않아 정식 cleanup 이 시작조차 못 하는데,
 *    함수는 성공으로 끝났다.
 *
 *    규칙을 복제하면 gye 쪽이 바뀔 때마다 같은 어긋남이 다시 생긴다.
 */

/**
 * @param {{firestore: FirebaseFirestore.Firestore}} deps
 * @returns {(input: {uid: string}) => Promise<{status: string}>}
 */
function createAuthUserDeletionBridge({ firestore } = {}) {
  if (
    !firestore ||
    typeof firestore.collection !== "function" ||
    typeof firestore.recursiveDelete !== "function"
  ) {
    throw new TypeError("A Firestore instance is required.");
  }

  return async function bridgeAuthUserDeletion({ uid } = {}) {
    if (typeof uid !== "string" || uid.length === 0) {
      throw new TypeError("uid is required.");
    }

    // recursiveDelete 는 users/{uid} 와 그 하위 문서·서브컬렉션을 재귀 정리한다.
    // Firestore 는 부모 문서가 없어도 서브컬렉션이 남을 수 있으므로 "부모가
    // 없으면 아무것도 안 한다"고 보면 안 된다. 이미 처리된 대상을 다시 돌려도
    // 안전하도록 반복 실행 가능하게 유지한다 — 정상 삭제 플로우
    // (account_deletion_worker)가 먼저 지운 뒤 Auth 삭제가 와도 문제없다.
    //
    // ⚠️ 실패를 삼키면 안 된다. 이 삭제가 실패하면 on_user_deleted 가 발화하지
    //    않아 정식 cleanup 이 시작조차 못 하는데, 삼키면 함수는 성공으로 끝난다.
    //    던져야 실패로 기록되고 배포 시 지정한 --retry 가 다시 시도한다.
    await firestore.recursiveDelete(firestore.collection("users").doc(uid));
    return { status: "bridged" };
  };
}

module.exports = { createAuthUserDeletionBridge };
