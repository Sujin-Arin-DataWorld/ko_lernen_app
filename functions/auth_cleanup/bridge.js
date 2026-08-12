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
 *    게다가 피드·신고·스티커 익명화를 통째로 건너뛰어 GDPR 목적 자체를 못 지켰다.
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

    // recursiveDelete 는 이미 없는 문서에도 no-op 이라 멱등하다. 정상 삭제
    // 플로우(account_deletion_worker)가 먼저 지웠으면 여기서 아무 일도 없고,
    // 그 경우 on_user_deleted 도 이미 돌았다.
    //
    // ⚠️ 실패를 삼키면 안 된다. 브리지가 실패했는데 함수가 성공으로 끝나면
    //    계 정리가 통째로 누락된 채 아무도 모른다. 던져서 실패로 남긴다.
    await firestore.recursiveDelete(firestore.collection("users").doc(uid));
    return { status: "bridged" };
  };
}

module.exports = { createAuthUserDeletionBridge };
