# Apple 로그인 설정 런북 — Firebase 제공자 활성화 + Android 웹 플로우 배선

> 갱신: 2026-09-05 · 대상: Jin (운영) · 코드는 이미 Apple 로그인을 시도하도록
> 작성돼 있으나, 아래 콘솔·시크릿 설정이 끝나기 전까지 모든 Apple 로그인은
> 즉시 실패한다. 콘솔 클릭, 시크릿 존재, 배포 성공, 실기기 동작은 서로 다른
> 증거다. 하나를 다른 하나의 완료로 기록하지 않는다.

---

## 0. 현재 상태 (2026-09-05 실측)

| # | 사실 | 근거 |
|---|---|---|
| 1 | **Firebase Auth에 Apple 제공자가 없다** | Identity Toolkit API `defaultSupportedIdpConfigs` = `google.com`만 존재. Apple 로그인 버튼을 누르면 iOS·Android 모두 `operation-not-allowed`로 즉시 실패한다 |
| 2 | `appleOAuthCallback`·`deleteCloudBackup`이 배포되어 있지 않다 | 배포본 updateTime 2026-08-12. Android 웹 플로우 콜백과 클라우드 데이터 삭제가 `not-found`로 종료된다 |
| 3 | Play/CI Android 릴리스 빌드에 `APPLE_SERVICES_ID`/`APPLE_REDIRECT_URI` dart-define이 없었다 | `.github/workflows/play_closed.yml`, `.github/workflows/ci.yml` — 본 변경으로 두 값을 GitHub repo variable에서 주입하도록 배선했다(§3). 값이 비어 있으면 지금까지와 동일하게 "Apple 미설정" 안내로 막힌다 — 이 변경만으로는 아무것도 켜지지 않는다 |
| 4 | `APPLE_REVOKE_*` 시크릿 4종은 2026-08-02 생성된 placeholder | 실제 Apple 값이 아니므로 지금 Apple 해지를 호출하면 `apple/revocation-config-invalid`로 실패한다. §4에서 실값으로 교체해야 한다 |

이 문서를 끝까지 따라 하기 전까지는 Apple 로그인 버튼을 노출해도 사용자에게
도달하지 않는다.

---

## 1. Apple Developer Console

전제: `developer.apple.com` Team 관리자 권한.

1. **Certificates, Identifiers & Profiles → Identifiers** → 기존 App ID
   `com.sujinarin.koLernenApp` (iOS 앱)을 연다. Capabilities에서
   **Sign in with Apple**을 켠다. 이미 Push Notifications가 켜져 있다면 함께
   유지한다.
2. **Identifiers → +** → **Services IDs** → 새로 만든다.
   - Identifier: `<SERVICES_ID>` (App ID와 **달라야** 함 — 예: `com.sujinarin.koLernenApp.signin`)
   - Description: 자유(예: `Hangul Sori Sign in with Apple`)
3. 방금 만든 Services ID를 열고 **Sign in with Apple**을 켠 뒤 **Configure**:
   - Primary App ID: `com.sujinarin.koLernenApp`
   - Domains and Subdomains: `ko-lernen-app.firebaseapp.com`,
     `europe-west3-ko-lernen-app.cloudfunctions.net`
   - Return URLs — **두 개 모두** 등록 (하나만 넣으면 Firebase 핸들러 또는
     Android 콜백 중 하나가 깨진다):
     - `https://ko-lernen-app.firebaseapp.com/__/auth/handler`
     - `https://europe-west3-ko-lernen-app.cloudfunctions.net/appleOAuthCallback`
4. **Keys → +** → **Sign in with Apple**을 체크하고 저장한 App ID를 연결 →
   키 생성. **Key ID**(`<KEY_ID>`, 10자)와 `.p8` 파일을 받는다. **`.p8`은
   콘솔에서 단 한 번만 다운로드할 수 있다** — 잃어버리면 키를 폐기하고
   재발급해야 한다. 다운로드한 `.p8`은 저장소에 절대 커밋하지 말고 로컬
   비밀 보관소에만 둔다.
5. **Membership** 페이지에서 **Team ID**(`<TEAM_ID>`, 10자)를 확인한다.

이 단계가 끝나면 손에 있어야 할 값: `<SERVICES_ID>`, `<TEAM_ID>`, `<KEY_ID>`,
`.p8` 파일 내용 1건.

---

## 2. Firebase Console — Apple 제공자 활성화

`console.firebase.google.com` → 프로젝트 `ko-lernen-app` → **Authentication →
Sign-in method → 새 제공자 추가 → Apple**.

- **Services ID**: `<SERVICES_ID>` (§1-2에서 만든 값)
- **OAuth code flow** 섹션을 펼쳐 입력:
  - Apple Team ID: `<TEAM_ID>`
  - Key ID: `<KEY_ID>`
  - Private key: `.p8` 파일 내용 전체(헤더 포함) 붙여넣기
- 저장.

네이티브 iOS 앱은 제공자 활성화만으로 동작한다(iOS는 Bundle ID를 그대로
audience로 쓰는 네이티브 Sign in with Apple 흐름). **Android/웹 플로우는 위
Services ID + OAuth code flow가 있어야만 동작한다** — 이게 지금까지 없었던
누락분(§0-1)이다.

---

## 3. GitHub repo variables

Android Play 빌드는 dart-define으로 아래 두 **공개** 값을 받는다(둘 다 비밀이
아니다 — Apple Services ID와 콜백 URL은 앱 바이너리와 Apple 콘솔에 이미
노출됨). 저장소 **Settings → Secrets and variables → Actions → Variables**
탭(Secrets 탭 아님)에서:

| Variable | 값 |
|---|---|
| `APPLE_SERVICES_ID` | `<SERVICES_ID>` |
| `APPLE_REDIRECT_URI` | `https://europe-west3-ko-lernen-app.cloudfunctions.net/appleOAuthCallback` |

`play_closed.yml`·`ci.yml`은 이미 이 두 variable을
`--dart-define=APPLE_SERVICES_ID=...`/`--dart-define=APPLE_REDIRECT_URI=...`로
appbundle 빌드에 넘기도록 배선돼 있다(본 커밋). 값을 넣기 전까지는 빈
문자열이 주입되어 지금과 동일하게 "Apple 미설정" 상태를 유지한다 — 순서를
신경 쓰지 않아도 안전하다.

---

## 4. 서버 파라미터 / 시크릿

### 4.1 공개 파라미터 (.env 파일, 커밋 금지)

Cloud Functions v2는 프로젝트별 `.env.<project-id>` 파일을 자동으로 읽는다.
`functions/gye/.env.ko-lernen-app`을 **로컬에서 새로 만든다**(`.gitignore`의
`.env*` 규칙 때문에 git에 잡히지 않는다 — 확인 사살로 `git status`에 안
뜨는지 볼 것):

```
APPLE_SERVICES_ID=<SERVICES_ID>
APPLE_REDIRECT_URI=https://europe-west3-ko-lernen-app.cloudfunctions.net/appleOAuthCallback
```

### 4.2 비밀 값 — `APPLE_REVOKE_*` 4종 교체

`functions/gye/apple_revocation_adapter.js`를 실측한 결과, 각 시크릿의 의미는
다음과 같다(native/web에 따라 사용되는 client id가 다르다는 점이 핵심):

| Secret | 값 | 왜 |
|---|---|---|
| `APPLE_REVOKE_CLIENT_ID` | `com.sujinarin.koLernenApp` (iOS **App ID**, Services ID 아님) | **네이티브**(iOS 앱) 해지 요청은 `clientKind==='native'`일 때 이 값을 Apple OAuth `client_id`로 쓴다(어댑터 `getClientId()`) |
| `APPLE_REVOKE_TEAM_ID` | `<TEAM_ID>` | JWT client-secret의 `iss` |
| `APPLE_REVOKE_KEY_ID` | `<KEY_ID>` | JWT 헤더 `kid` |
| `APPLE_REVOKE_PRIVATE_KEY` | `.p8` 파일 내용 전체(PEM, EC prime256v1) | JWT 서명 키 |

주의: **Services ID(`<SERVICES_ID>`)는 이 4개 시크릿에 들어가지 않는다.**
`clientKind==='web'`(Android/웹 로그인)일 때는 이미 §4.1의 공개 파라미터
`APPLE_SERVICES_ID`가 자동으로 쓰인다(어댑터 `getServicesId()`) — 시크릿이
아니라 위 `.env.ko-lernen-app`으로 배선된다.

값을 절대 셸 인자·리다이렉트 파일·CI 로그에 남기지 않는다. Firebase CLI의
숨김 프롬프트만 사용:

```bash
firebase functions:secrets:set APPLE_REVOKE_CLIENT_ID --project ko-lernen-app
firebase functions:secrets:set APPLE_REVOKE_TEAM_ID --project ko-lernen-app
firebase functions:secrets:set APPLE_REVOKE_KEY_ID --project ko-lernen-app
firebase functions:secrets:set APPLE_REVOKE_PRIVATE_KEY --project ko-lernen-app
```

각 프롬프트에서 값을 입력하면 새 시크릿 버전이 생성된다(기존 2026-08-02
placeholder 버전은 자동 비활성화되지 않으므로, 배포 후 `gcloud secrets
versions list APPLE_REVOKE_CLIENT_ID --project=ko-lernen-app` 등으로 최신
버전이 쓰이는지 확인).

---

## 5. 배포 (Jin 승인 후에만 실행)

**RC_\* (RevenueCat) 시크릿은 Secret Manager에 존재하지 않는다** — billing
관련 함수(`revenueCatWebhook`·`processRevenueCatEvent`·`refreshRevenueCatAccess`)를
포함해 `functions:gye-firebase-functions` 전체를 배포하면 그 함수들 때문에
실패하거나 의도치 않게 켜질 수 있다. 따라서 계정/Apple 관련 함수만 이름으로
지정해 배포한다.

```bash
npm ci --prefix functions/gye

# rules 먼저, 관련 index가 이미 READY인지 Console에서 확인 후에만 진행
firebase --config firebase.json deploy --only firestore:rules --project ko-lernen-app

export FUNCTIONS_DISCOVERY_TIMEOUT=120
firebase --config firebase.json deploy --project ko-lernen-app \
  --only functions:gye-firebase-functions:requestAccountDeletion,functions:gye-firebase-functions:getAccountDeletionStatusByReceipt,functions:gye-firebase-functions:acknowledgeAccountDeletionStatusReceipt,functions:gye-firebase-functions:completeAppleRevocation,functions:gye-firebase-functions:getAccountOperation,functions:gye-firebase-functions:account_deletion_worker,functions:gye-firebase-functions:deleteCloudBackup,functions:gye-firebase-functions:appleOAuthCallback,functions:gye-firebase-functions:submitTesterFeedback,functions:gye-firebase-functions:issueDeletionProof,functions:gye-firebase-functions:requestDeletionByProof
```

- `FUNCTIONS_DISCOVERY_TIMEOUT=120`은 콜드 discovery가 기본 10초 안에 끝나지
  않아 배포가 거짓 타임아웃으로 실패하는 것을 막는다(2026-08-04 실측 사례).
- `on_auth_user_deleted`(`functions/auth_cleanup`)는 이미 배포되어 있다 —
  이번 배포 대상에 포함하지 않는다.
- 배포 후 각 함수의 `updateTime`이 갱신됐는지, `completeAppleRevocation`에
  4개 Apple 시크릿이 모두 바인딩됐는지 `gcloud functions describe
  completeAppleRevocation --gen2 --project=ko-lernen-app
  --region=europe-west3 --format='yaml(serviceConfig.secretEnvironmentVariables)'`로
  확인한다.

---

## 6. 검증

1. **iOS 실기기(네이티브)**: Apple 계정으로 로그인 → 연동 → 계정 삭제까지
   1회 왕복. 재로그인 시 같은 Firebase UID로 돌아오는지 확인.
2. **Android(Play 빌드, 웹 플로우)**: §3 variable을 채운 뒤 새로 빌드된
   AAB에서 Apple 버튼 → Apple 로그인 웹뷰 → `AndroidManifest.xml`의
   `signinwithapple://callback` 인텐트로 앱에 복귀 → 로그인 성공까지 확인.
3. **Cloud Logging으로 콜백 확인**:
   ```bash
   gcloud logging read \
     'resource.type="cloud_run_revision" AND resource.labels.service_name="appleoauthcallback"' \
     --project=ko-lernen-app --limit=20 --format='table(timestamp,severity,textPayload)'
   ```
4. **실패 시**: Crashlytics → 비치명(non-fatal) → `AccountFailureRecord`를
   검색해 `stage`/`code`를 확인한다(원문 예외 메시지는 기록되지 않는다 —
   T1 참고).

---

## 7. 권장 (선택, 강제 아님)

Firebase Console → **Authentication → Settings → User actions** →
**익명 사용자 자동 삭제(30일)** 활성화. 계정 전환(Google/Apple로 갈아탄) 후
버려지는 익명 계정을 주기적으로 정리한다.
