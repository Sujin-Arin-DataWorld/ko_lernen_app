/**
 * auth_cleanup — Firebase **Auth 계정 삭제** 트리거 (GDPR 최종 보증 브리지)
 * ============================================================================
 * ⚠️ `on_user_deleted` 와 혼동하지 말 것 — 이벤트 소스가 다르다.
 *
 *   functions/gye/index.js  exports.on_user_deleted
 *     → onDocumentDeleted("users/{uid}")  = **Firestore 문서** 삭제 트리거.
 *       앱의 정상 삭제 플로우(account_operations → account_deletion_worker →
 *       users 트리 삭제)가 만들어 주는 이벤트다. **계 정리의 단일 소유자**다.
 *
 *   이 파일     exports.on_auth_user_deleted
 *     → functionsV1.auth.user().onDelete() = **Auth 계정** 삭제 트리거.
 *       앱 플로우 **밖**에서 계정만 사라지는 경로를 받는다:
 *       Firebase Console 수동 삭제 · gcloud · CS 대응 · admin SDK 스크립트.
 *       그 경로에서는 users/{uid} 문서가 남아 있어 Firestore 트리거가 아예
 *       발화하지 않으므로, gye 멤버 문서·memberCount·ownerId 가 영구 잔존한다.
 *       account_deletion_tombstone_cleanup 은 account_deletions 툼스톤이 이미
 *       있을 때만 도는 24h 잡이라 이 경로를 잡지 못한다.
 *
 * **이 함수는 브리지일 뿐이다.** users/{uid} 를 지워 on_user_deleted 를 깨우고
 * 끝난다. 계 정리 규칙(승계 후보 필터·memberCount 정합·익명화·페이징)은 전부
 * functions/gye 가 소유한다 — 근거는 gye/index.js:1022 주석:
 *   "Only the users/{uid} deletion trigger owns forced membership/owner cleanup."
 * 왜 여기에 규칙을 복제하면 안 되는지는 bridge.js 헤더 참조.
 *
 * gen-1 API 인 이유: v2 에는 auth onDelete 트리거가 없다. 그리고 firebase CLI
 * 15.x 가 gen-1 에 CPU 설정을 시도하다 배포가 실패하는 버그가 있어(2026-08-12
 * 실측, 별도 코드베이스로 분리해도 동일) **firebase.json 코드베이스에 등록하지
 * 않고** gcloud 로만 배포한다.
 *
 * 배포 (저장소 루트에서):
 *   gcloud functions deploy on_auth_user_deleted --no-gen2 --runtime=nodejs20 \
 *     --region=europe-west3 --source=functions/auth_cleanup \
 *     --entry-point=on_auth_user_deleted \
 *     --trigger-event=providers/firebase.auth/eventTypes/user.delete \
 *     --trigger-resource=ko-lernen-app --project=ko-lernen-app --retry
 *
 * `--retry` 를 붙이는 이유: 브리지 실패는 계 정리 누락으로 직결되므로 재시도가
 * 맞다. 삭제는 멱등이라 재시도가 안전하다.
 * ============================================================================
 */

const admin = require("firebase-admin");
const functionsV1 = require("firebase-functions/v1");

const { createAuthUserDeletionBridge } = require("./bridge");

admin.initializeApp();

const bridge = createAuthUserDeletionBridge({ firestore: admin.firestore() });

exports.on_auth_user_deleted = functionsV1
  .region("europe-west3")
  .auth.user()
  .onDelete(async (user) => {
    // 실패를 삼키지 않는다 — 브리지가 실패하면 계 정리가 통째로 누락된다.
    // 던져야 실행이 실패로 기록되고 --retry 가 다시 시도한다.
    return bridge({ uid: user.uid });
  });
