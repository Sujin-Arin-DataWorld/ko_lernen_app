/**
 * auth_cleanup — Firebase **Auth 계정 삭제** 트리거 (GDPR 최종 보증)
 * ============================================================================
 * ⚠️ `on_user_deleted` 와 혼동하지 말 것 — 이벤트 소스가 다르다.
 *
 *   functions/gye/index.js  exports.on_user_deleted
 *     → onDocumentDeleted("users/{uid}")  = **Firestore 문서** 삭제 트리거.
 *       앱의 정상 삭제 플로우(account_operations → account_deletion_worker →
 *       users 트리 삭제)가 만들어 주는 이벤트다.
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
 * 2026-08-12 통합: session/2026-08-12-hardening a81418d 에서 이식했다. 원본은
 * 이름이 `on_user_deleted` 라 origin/main 의 gen-2 Firestore 트리거와 **같은
 * 리전에서 이름이 충돌**한다(GCF 는 동일 리전 동명 gen-1/gen-2 공존 불가) —
 * 그대로 배포하면 gen-2 트리거를 밀어낸다. 그래서 개명했다.
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
 *     --trigger-resource=ko-lernen-app --project=ko-lernen-app
 * ============================================================================
 */

const admin = require("firebase-admin");
const functionsV1 = require("firebase-functions/v1");

admin.initializeApp();
const db = admin.firestore();

const LOG = "[on_auth_user_deleted]";

exports.on_auth_user_deleted = functionsV1
  .region("europe-west3")
  .auth.user()
  .onDelete(async (user) => {
    const uid = user.uid;
    const userRef = db.collection("users").doc(uid);

    let gyeIds = [];
    try {
      const snap = await userRef.get();
      gyeIds = (snap.data() || {}).gyeIds || [];
    } catch (e) {
      console.error(`${LOG} gyeIds read failed uid=${uid}`, e);
    }

    for (const gyeId of gyeIds) {
      try {
        const metaRef = db.collection("gye").doc(gyeId);
        const metaSnap = await metaRef.get();
        const meta = metaSnap.data();
        if (!meta) {
          continue;
        }

        const members = await metaRef.collection("members").get();
        const others = members.docs.filter((d) => d.id !== uid);

        // 1인 계: 피드·스티커·신고까지 재귀 삭제 (admin SDK 는 rules 우회).
        if (meta.ownerId === uid && others.length === 0) {
          await db.recursiveDelete(metaRef);
          continue;
        }

        const batch = db.batch();
        if (meta.ownerId === uid) {
          // 최고참(joinedAt 오래된 순) 승계 — deletion_gye_page.js 의
          // successorUid 선정 규칙과 같은 기준이다.
          others.sort(
            (a, b) =>
              (a.data().joinedAt?.toMillis?.() ?? 0) -
              (b.data().joinedAt?.toMillis?.() ?? 0),
          );
          batch.update(metaRef, { ownerId: others[0].id });
        }
        if (members.docs.some((d) => d.id === uid)) {
          batch.delete(metaRef.collection("members").doc(uid));
          batch.update(metaRef, {
            memberCount: admin.firestore.FieldValue.increment(-1),
          });
        }
        await batch.commit();
      } catch (e) {
        console.error(`${LOG} gye=${gyeId} uid=${uid}`, e);
      }
    }

    // users/{uid} 트리 잔재 멱등 제거. 앱 플로우가 이미 지웠으면 no-op 이고,
    // 이 삭제가 gye 코드베이스의 on_user_deleted(Firestore 트리거)를 깨워
    // 나머지 정리를 이어서 하게 만든다.
    try {
      await db.recursiveDelete(userRef);
    } catch (e) {
      console.error(`${LOG} users tree uid=${uid}`, e);
    }
  });
