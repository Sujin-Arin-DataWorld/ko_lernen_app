# Gye Admin 패널 (계 모더레이션)

> plan §9.2. 계(契) 신고 검토 + 멤버 정지/해제 + 계 조회/해체. **운영자(Jin) 전용.**
> 단일 `index.html`(Firebase v9 compat CDN, 빌드 불필요). `firestore.rules`의
> `isAdmin()`(custom claim `admin:true`)으로 보호.

## 1. 운영자 권한 부여 (Custom Claim)

내 Firebase UID에 `admin:true` 클레임 1회 설정. 로컬에서 admin SDK로:

```js
// setAdmin.js — node setAdmin.js <UID>  (서비스 계정 키 필요, 커밋 금지)
const admin = require('firebase-admin');
admin.initializeApp({ credential: admin.credential.cert(require('./serviceAccountKey.json')) });
admin.auth().setCustomUserClaims(process.argv[2], { admin: true })
  .then(() => { console.log('done'); process.exit(0); });
```

설정 후 해당 계정은 **재로그인**해야 토큰에 클레임이 반영됨.
내 UID는 앱 ProfileScreen 또는 Firebase Console → Authentication에서 확인.

## 2. Firestore 인덱스 (collectionGroup)

신고 큐는 `collectionGroup('reports').orderBy('createdAt')` 사용 → **collection group 인덱스** 필요.
첫 조회 시 콘솔 에러에 뜨는 "인덱스 생성" 링크를 클릭하거나, 수동 생성:
- Firestore → 색인 → collection group `reports`, 필드 `createdAt` (내림차순).

## 3. Web 앱 등록 (선택, 권장)

`index.html`의 `firebaseConfig.appId`는 현재 **Android 앱 ID**(Auth/Firestore는 동작하나 클린하지 않음).
Firebase Console → 프로젝트 설정 → **웹 앱 추가** → 발급된 `appId`로 교체 권장.
(apiKey 등 나머지는 공개 식별자라 그대로 사용.)

## 4. 실행

**로컬 검토:**
```bash
cd tools/admin && python3 -m http.server 8099   # http://localhost:8099
```
(Firebase Auth 팝업은 `localhost`가 승인된 도메인이어야 함 — Console → Authentication → Settings → 승인된 도메인.)

**배포 (Firebase Hosting, 별도 site 권장):**
```bash
firebase hosting:sites:create gye-admin           # 1회
firebase target:apply hosting admin gye-admin
# firebase.json hosting에 target "admin" → public: "tools/admin" 추가 후
firebase deploy --only hosting:admin
```
배포 후 URL은 비공개로 두고 운영자만 사용(클레임 없으면 어차피 데이터 접근 불가).

## 5. 기능

- **신고 큐**: 전체 계의 `reports` 최신순(offen 우선). 각 신고 → **Sperren**(대상 `status=suspended` + report `reviewed/manual`) / **Verwerfen**(`dismissed`).
- **계 조회**: 6자리 코드 → 메타 + 멤버 목록. 멤버별 **Sperren/Entsperren**, **닉네임 변경**. 계 **해체**(메타 삭제 — 하위 컬렉션은 CF/수동 정리).

## 6. 한계 (후속)

- 계 해체 시 하위 컬렉션(members/feed/stickers/reports) **cascade 삭제는 미구현** — Firestore 재귀 삭제 CF 또는 콘솔 수동. (`on_account_deleted` 류 CF로 확장 권장.)
- 자동정지(서로 다른 3명)는 `functions/gye/index.js`의 `on_report_created`가 별도 처리 — admin은 **수동 검토/오버라이드**용.
- 시각·실동작 미검증(custom claim + 실 Firestore 필요) → Jin 확인.
