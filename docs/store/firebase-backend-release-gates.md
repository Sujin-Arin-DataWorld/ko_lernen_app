# Firebase backend production release gates

이 문서는 `ko-lernen-app`의 백엔드 배포 단위를 분리하고, 각 배포 뒤 무엇을
증거로 남겨야 하는지 고정한다. 명령이 저장소에 있다는 사실은 배포 권한이나 live
상태를 뜻하지 않는다. 운영 소유자의 명시적 승인 없이 아래 deploy/smoke 명령을
실행하지 않는다.

## 1. 공통 중단 조건

배포마다 다음이 모두 참이어야 한다.

1. clean worktree의 `HEAD`가 배포 대상으로 승인된 full SHA이며 `origin/main`과
   일치한다. 현재 작업 중인 변경이나 untracked 파일을 섞지 않는다.
2. 그 SHA의 서비스별 CI job과 필수 app CI가 성공했다. 다른 SHA의 green run은
   대신 쓸 수 없다.
3. 실행자는 `ko-lernen-app`만 선택했고 필요한 최소 IAM 권한을 가진다.
4. Secret은 존재 여부와 version 상태만 확인한다. 값 읽기, 셸 history, CI 출력,
   문서 복사는 금지한다.
5. shared `firestore.indexes.json`과 `firestore.rules`를 배포할 때는 영향받는 Gye,
   계정 삭제, tester feedback, TTS quota/idempotency, Book cache 계약을 함께 검사한다.
6. generic `firebase deploy` 또는 여러 codebase를 한 명령으로 묶지 않는다.

배포 직전 기록:

```bash
git fetch origin main
test "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)"
test -z "$(git status --porcelain)"
git rev-parse HEAD
test "$(node -p 'JSON.parse(require("fs").readFileSync(".firebaserc", "utf8")).projects.default')" = "ko-lernen-app"
```

`.firebaserc` 확인은 기본 프로젝트 계약일 뿐 배포 증거가 아니다. 아래 모든 deploy
명령은 실수 방지를 위해 `--project ko-lernen-app`을 다시 명시한다.

## 2. 로컬/CI preflight

Node 함수는 Gen1 Auth cleanup을 포함해 저장소가 지정한 Node 22를 사용한다.
Node 20은 2026-04-30 deprecated, 2026-10-30 decommission 예정이므로 새 후보는
Node 22로 검증한다. [공식 runtime 지원 일정](https://docs.cloud.google.com/functions/docs/runtime-support).
Firestore rules emulator에는 Java도 필요하다.

```bash
npm ci --prefix functions/gye
npm test --prefix functions/gye
npm --prefix functions/gye run test:rules
npm --prefix functions/gye run test:storage-rules

npm ci --prefix functions/tts
npm test --prefix functions/tts

npm ci --prefix functions/pronunciation
npm test --prefix functions/pronunciation

npm ci --prefix functions/auth_cleanup
npm test --prefix functions/auth_cleanup
```

Book Gen2는 Python 3.12와 별도 dependencies가 필요하다. 정확한 preflight와 source
closure는 [cloud-function-deploy.md](cloud-function-deploy.md)를 따른다.
CI는 의존성 설치 전에 `python -m pip install --upgrade pip==26.2.1`로 빌드 도구를
고정한다. [pip 공식 변경 기록](https://pip.pypa.io/en/stable/news/)의 보안 수정과
후속 keyring 회귀 수정을 포함한 버전이다. 배포 시에는 실제 buildpack의 도구 버전과
해결된 런타임 의존성도 별도로 기록·감사한다. 로컬 venv의 취약점0은 운영 이미지의 증명이 아니다.

### 개발 도구 감사의 잔여 항목

Gye의 `firebase-tools` → `@google-cloud/pubsub5.3.1` → `@opentelemetry/core1.30.1`
경로는 잠금 파일에서 `dev:true`다. 운영 의존성 감사와 전체 개발 의존성 감사를 구분한다.
[GHSA-8988-4f7v-96qf](https://github.com/advisories/GHSA-8988-4f7v-96qf)의 moderate
Baggage 입력 메모리 문제는 core2.8.0에서 수정됐지만, 현재 호환 PubSub5.x는 core1.x를
요구한다. 임의 major override나 오래된 Firebase CLI로의 자동 downgrade를 하지 않는다.
상위 도구의 호환 릴리스가 준비되면 별도 검증 후 갱신하며, 배포 환경의 실제 dev 제외 여부도 확인한다.

그동안 개발 도구/에뮬레이터는 공개 네트워크에 노출하지 않고, Node 기본 HTTP 헤더 한도를
키우지 않는다. HTTP 한도는 Pub/Sub 같은 비HTTP 전달의 보호가 아니므로 신뢰하지 않는
Baggage를 도구에 전달하지 않거나 입력 경계에서 크기를 제한한다. 이는 개발 도구 운영 조건이며,
운영 서버에 해당 문제가 없다는 실측이나 전체 의존성 취약점0의 주장이 아니다.

## 3. TTS와 shared Firestore 설정

TTS는 빈 요청 거절, quota 환급, callable 12초 timeout, provider 7초 deadline,
usable-audio 확인, `service_idempotency` 선점 계약을 source와 테스트로 잠근다.
배포 순서를 바꾸지 않는다.

```bash
firebase --config firebase.json deploy --only firestore:indexes \
  --project ko-lernen-app
```

Firebase Console에서 새/변경 composite index와 TTL 설정이 모두 READY/ACTIVE가 될
때까지 중단한다. 그 다음에만:

```bash
firebase --config firebase.json deploy --only firestore:rules \
  --project ko-lernen-app
firebase --config firebase.json deploy \
  --only functions:tts-firebase-functions \
  --project ko-lernen-app
```

사후 증거는 `synthesize_tts`와 `synthesize_tts_v2`의 runtime/region/update time,
배포 명령의 성공 receipt, signed release 앱의 Auth+App Check 요청, Storage에 없던
동적 문장의 첫 합성과 같은 문장의 cache hit를 각각 포함한다. Storage corpus의
파일 존재 검증은 callable 배포 증거를 대신하지 않는다.

```bash
for fn in synthesize_tts synthesize_tts_v2; do
  gcloud functions describe "$fn" --gen2 --project=ko-lernen-app \
    --region=europe-west3 \
    --format='yaml(name,state,updateTime,buildConfig.runtime,serviceConfig.timeoutSeconds)'
done
```

## 4. Gye, tester feedback, 계정 삭제

Gye codebase는 shared indexes와 rules가 먼저 준비되어야 한다. `functions/gye/index.js`
헤더와 같은 순서를 사용한다.

아래 명령은 `functions/gye/package.json`의 세 deploy script와 같은 단위를 사용하되,
운영 프로젝트를 매번 명시한다.

```bash
firebase --config firebase.json deploy --only firestore:indexes \
  --project ko-lernen-app
# Firebase Console에서 모든 새 collection-group index READY까지 대기
firebase --config firebase.json deploy --only firestore:rules \
  --project ko-lernen-app
firebase --config firebase.json deploy \
  --only functions:gye-firebase-functions \
  --project ko-lernen-app
```

배포 전에 `DELETION_PROOF_HMAC_KEY`, `APPLE_REVOKE_CLIENT_ID`,
`APPLE_REVOKE_TEAM_ID`, `APPLE_REVOKE_KEY_ID`, `APPLE_REVOKE_PRIVATE_KEY`의
metadata를 확인한다. placeholder인지 실제 운영값인지 판단할 권한은 release
owner에게 있다. 값을 읽어서 판정하지 않는다.

`functions/gye/smoke_test.js`는 production Firestore에 `SMOKE...` 데이터를 만들고
삭제하는 mutation이다. 별도 smoke 승인을 받은 서비스 계정으로만 실행한다. 성공
receipt에는 생성한 prefix, 3/3 통과, cleanup 성공을 남기되 UID나 Secret은 남기지
않는다. tester feedback callable, 삭제 callable/worker, scheduled jobs, public deletion
route는 이 legacy smoke만으로 증명되지 않으므로 승인된 test account와 실제 route로
별도 검증한다.

## 5. Pronunciation callable

먼저 Secret payload를 읽지 않고 `AZURE_SPEECH_KEY` 존재 metadata를 확인한다.

```bash
gcloud secrets describe AZURE_SPEECH_KEY \
  --project=ko-lernen-app --format='value(name)'
firebase --config firebase.json deploy \
  --only functions:pronunciation-firebase-functions \
  --project ko-lernen-app
```

배포 후에는 [pronunciation assessment runbook](../runbooks/pronunciation-assessment.md)의
signed-device consent/Auth/App Check/limited-use-token 검증을 수행한다. unit test나
debug-token 성공은 Play Integrity, App Attest, DeviceCheck, Azure production 성공을
대신하지 않는다.

## 6. Auth deletion bridge (Gen1)

`on_auth_user_deleted`는 Firebase CLI codebase가 아니다. Gye의 `on_user_deleted`가
먼저 live이고 정상임을 확인한 뒤에만 Gen1 bridge를 배포한다.

```bash
gcloud functions deploy on_auth_user_deleted \
  --no-gen2 --runtime=nodejs22 --region=europe-west3 \
  --source=functions/auth_cleanup --entry-point=on_auth_user_deleted \
  --trigger-event=providers/firebase.auth/eventTypes/user.delete \
  --trigger-resource=ko-lernen-app --project=ko-lernen-app --retry
```

실제 계정 삭제 smoke는 파괴적이다. 명시적으로 승인된 disposable test account와
예상된 Gye membership/owner/memberCount cleanup 목록이 없으면 실행하지 않는다.

## 7. Book analysis Gen2

`analyze_korean_text`는 Firebase Node codebase들과 묶지 않는다. Secret Manager,
전용 runtime service account, Python 3.12 source closure, signed Android/iOS smoke,
Firestore TTL ACTIVE, owner-approved legacy cache cleanup을 모두 요구한다. 전체 순서는
[책 한 컷 Cloud Function 안전 배포 런북](cloud-function-deploy.md)이 정본이다.
`cleanup_translation_cache.py --apply`는 별도 데이터 삭제 승인 없이는 금지한다.

## 8. 최소 배포 receipt

서비스마다 다음을 한 묶음으로 보존한다.

- full release SHA와 exact-SHA CI URL/conclusion
- 프로젝트, region, runtime, function/codebase 이름과 deploy 종료 코드
- Secret payload가 아닌 Secret 존재/version 상태
- 배포 직후 function update time/status와 필요한 index/TTL READY 상태
- signed-device 또는 승인된 production smoke 결과와 실행 시각
- Play/TestFlight/실기기처럼 아직 남은 사람·콘솔 게이트

source test, deploy command 성공, console 처리, 실제 기기 동작은 서로 다른 증거다.
하나를 다른 하나의 완료로 기록하지 않는다.

## 9. Commercial stability 동반 변경의 추가 게이트

W7의 TTS 로딩/프리패치, Living의 스타일 변경, W9의 배포 소유권은 유지한다.
아래는 기존 배포에 추가되는 안전 조건이며 새로운 자동 배포 경로가 아니다.

### Auth와 Apple

- `APPLE_SERVICES_ID`와 `APPLE_REDIRECT_URI`는 공개 설정이지만 실제 등록된 값만 사용한다.
  Dart release define과 서버 parameter를 일치시키고 Apple Services ID를 native App ID와 연결한다.
- `appleOAuthCallback`은 고정 Android package/scheme으로만 반환하는 공개 HTTPS POST relay다.
  HTTPS 반환 URL 등록, Firebase Apple provider audience, 서명 지문/SHA 설정은 콘솔에서 검증한다.
- Google-only→Apple, Apple-only→Google, iOS→Android→iOS 왕복에서 같은 Firebase UID와
  기존 학습 기록을 확인한다. 취소·충돌·네트워크 끊김·앱 재시작·삭제도 실제 기기로 검증한다.
- `apple-revocation-unavailable`은 계정 삭제 대체 경로이지 Apple 권한 철회 성공이 아니다.

### 개인정보와 배포 순서

- source corpus로 생성한 TTS canonical manifest를 `python functions/tts/build_canonical_manifest.py --check`로 검증한다.
  public canonical만 기존 `tts/v3/{voice}/{hash}.mp3`를 유지한다. 개인 합성은 UID-private이다.
- `functions/tts/privacy_migration.js`는 로컬 inventory→검토 가능한 계획만 만든다.
  실제 이름/generation inventory, canonical 비교, 승인 해시 없이 live metadata/token을 수정하지 않는다.
- 운영자가 승인한 canonical metadata `canonical=true` 표시와 legacy download-token 철회를
  완료해야 새 public get-only 규칙을 적용한다. 버킷/객체 IAM·ACL 우회 공개도 별도 확인한다.
  이미 다운로드된 사본이나 과거에 공개된 내용은 소급 회수할 수 없다.
- `storage_lifecycle.template.json`은 기존 bucket lifecycle에 **병합할 템플릿**이다.
  기존 규칙을 덮어쓰지 않는다. `tts_private/` 객체 접근은24시간에 종료되고 물리 삭제는 eventual이다.
  soft-delete/versioning/retention 정책과 실제 잔존 기간을 운영자가 함께 확인한다.
- 개인 클라이언트 음성은 메모리 전용이며 UID/epoch/클라우드 쓰기 모드 변경 시 개인 상태만
  무효화한다. 이 경로는 공개 canonical 학습 음성의 오프라인 캐시를 삭제하지 않는다.
  명시적인 전체 계정 삭제·로컬 초기화는 별도의 전체 정리 경로를 사용한다.
- 개인 응답에는 `cacheScope`, `expiresAtMillis`, `serverNowMillis`가 모두 필요하다. 클라이언트는
  서버가 계산할 수 있는 잔여 시간에서 요청 경과 시간을 보수적으로 차감하며, 단조 시간과
  관찰된 벽시계 진행을 함께 확인한다. 시계 역행·소진된 응답은 거부하고 실제 재생 직전에도
  같은 UID/epoch와 수명을 재검증한다. 기기 시각이 서버보다 느리다고 수명이 늘어나면 안 된다.
  앱 재시작 뒤에는 네트워크가 필요하고 필수 필드가 없는 구형 개인 응답은 거부한다.
  백엔드·메타데이터·규칙·클라이언트의 배포 순서를 W9에서 함께 검증한다.
- iOS 개인 재생은 `AVAudioPlayer(data:)`를 쓰는 앱 소유 브리지다. PR/main의 unsigned
  iOS 빌드와 simulator `RunnerTests`를 통과해야 한다. 이는 실제 기기의 재생·중단·계정 전환·
  삭제 시 메모리 해제와 임시 파일 미생성 확인을 대신하지 않는다. desktop 개인 재생은 차단한다.
- iOS CI는 Xcode26.3을 명시적으로 선택하고 준비·빌드·테스트에 같은 `DEVELOPER_DIR`를 쓴다.
  현재 `device_info_plus13.2.0`의 iOS26.1 API는 구형 SDK로 컴파일되지 않으므로
  `macos-15`의 기본 Xcode를 호환성 증거로 삼지 않는다. W9의 실제 Xcode Cloud/서명 빌드도
  호환 SDK를 선택했는지 별도 확인한다. 이 CI 변경은 Xcode Cloud 콘솔 설정을 바꾸지 않는다.
- unsigned release 빌드와 simulator `RunnerTests`는 서로 의존하지 않는 별도 잡이며,
  release는45분, 콜드 Intel simulator는75분 제한 안에 성공해야 한다. simulator 잡은
  전체 빌드·테스트 로그와 `.xcresult`를
  `native-privacy-results` 아티팩트로 항상 보관한다(3일). 업로드 성공만으로 테스트 통과를
  인정하지 않고 실제 XCTest 실행·결과를 확인한다.
- 잠긴 ML Kit 의존성은 arm64 기기용·x86_64 simulator용 바이너리를 제공하므로 simulator
  잡만 `macos-15-intel`에서 실행하고 `uname -m`이 `x86_64`인지 준비 전에 검증한다.
  destination과 빌드 `ARCHS`도 `x86_64`로 고정한다. unsigned release는 기존 arm64
  `macos-15` 잡을 유지한다. Intel XCTest 통과는 arm64 실기기 QA를 대신하지 않는다.
  simulator75분은 준비15분28초·계속 진행 중이던 빌드27분39초 뒤45분 제한에 도달한
  관측에 따른 유한한 다음 검증 예산이다. 완료 시간 예측이나 테스트 통과 면제가 아니다.
- `service_idempotency_results.expiresAt` TTL은15분 결과 보관, `service_idempotency.expiresAt`은
  책/발음24시간 hash-only 중복 방지다. API 접근 만료와 Firestore TTL 실제 삭제는 별개다.
- `premium_grants`, `customer_entitlements`, `billing_customers`, billing receipts는 폐기된
  결제 구조의 과거 레코드다. 새 접근 판정이나 신규 쓰기에 사용하지 않으며 서버 전용 상태로
  둔 채 계정 삭제 어댑터가 소유자 해시로 제거한다. 늦게 도착한 과거 작업이 삭제 계정이나
  결제 권한을 다시 만드는지도 계정 삭제 worker와 합동 검증한다.

### 공통 AI 비용 중단 장치와 과거 결제 데이터 정리

- 신규 Premium grant, 구독 entitlement, billing customer/receipt를 만들거나 복원하지 않는다.
  폐기된 `functions/gye/manage_premium_grants.js` 경로와 권한 발급 도구는 현재 소스에 다시
  추가하지 않는다. 과거 레코드 조사가 필요하면 먼저 read-only inventory를 만들고, 별도
  승인된 정리 작업에서는 삭제 대상만 명시한다. UID 명단과 계정 정보는 저장소나 로그에 올리지 않는다.
- 과거 레코드의 `accountCreatedAt`은 삭제 대상의 소유권을 확인하기 위한 방어 필드일 뿐,
  콘텐츠나 AI 한도를 올리는 권한이 아니다. 같은 UID 재생성 여부가 불명확하면 삭제를
  중단하고 새 UID 기준으로 조사한다. 정상 앱 삭제의 marker/cleanup 절차는 계속 적용한다.
- 모든 인증 사용자는 결제·테스터 문서와 무관하게 동일한 콘텐츠 접근과 책20회/발음50회
  일일 한도를 받는다. 클라이언트가 보낸 tier, Premium, grant, passport 값은 한도를 바꾸지 않는다.
- 새 앱은 `getUniversalAccessSnapshot`의 schema v2(`source: universal`,
  `aiPolicyId: universal_v1`)만 사용한다. 이미 설치된 구버전이 업데이트 전 다시 잠기지 않도록
  `getAccessSnapshot`은 같은 공통 정책을 구버전 파서가 이해하는 schema v1 모양으로만 변환한다.
  이 호환 함수도 grant·entitlement 문서를 읽지 않으며 두 함수는 같은 Auth, App Check,
  계정 삭제 fence와 rate-limit 문서를 공유한다. 둘 중 하나만 단독 배포하지 않는다.
- 배포 직전에 `firebase functions:list --project ko-lernen-app`으로 운영 함수를 새로
  조회해 결과를 release receipt에 남긴다. `getAccessSnapshot`,
  `getUniversalAccessSnapshot`, `revenueCatWebhook`, `processRevenueCatEvent`,
  `refreshRevenueCatAccess`의 실제 존재 여부를 이름별로 확인한다. 과거 결제 함수가 있으면
  이름과 region을 다시 대조한 뒤에만 명시적으로 삭제하고, 없다는 이전 조회를 재사용하지 않는다.
- Gye 전체 codebase 대신 두 접근 함수만 정확히 배포한다:
  `firebase --config firebase.json deploy --only functions:gye-firebase-functions:getAccessSnapshot,functions:gye-firebase-functions:getUniversalAccessSnapshot --project ko-lernen-app`.
  배포 뒤 두 함수의 update time과 서명 앱 요청을 각각 검증한다.
- `service_cost_controls/ai_v1`은 `schemaVersion:1`, `approvedBy:"Jin"`, `approvalRef`,
  `approvedAt`, `dailyUnitLimit`, `bookReservationUnits`, `pronunciationReservationUnits`,
  `ttsReservationUnits`를 요구한다. 모든 요청 가중치는 양수, 하루 한도는0이상 정수다.
  누락/잘못된 설정/한도0/소진은 새 외부 처리 전에 fail-closed다. 검증을 위해 임의 운영 예산을 넣지 않는다.
- `service_cost_ledgers/YYYY-MM-DD`는 두 환경·책·발음·새 TTS 합성의 비용 예약을 함께 제한한다.
  TTL은 UTC day+2일이다. 이미 처리했는지 불명확한 요청의 비용은 환급하지 않는다.
  가중치는 **설정된 보수적 예약 단위**이지 실제 유로 비용 측정값이 아니다.
- 최대 허용 입력의 provider 비용, 중복/실패/재시도, TTS, Firestore·함수·Storage 비용을 측정한다.
  원문/음성 대신 비식별 비용 표본의 n/평균/p95/max와 산출 근거를 남긴다. 무료 사용자 비용도 포함한다.
- 모든 사용자에게 공개된 책20회/발음50회 사용 분포와 provider·인프라 비용을 대조한다.
  비용이 맞지 않거나 측정 증거가 없으면 해당 외부 처리의 운영 한도를 보수적으로 중단하고
  다시 승인한다. 결제벽이나 구독 등급을 자동으로 되살리지 않는다.
  거절된 트래픽도 Auth/Firestore/인프라 비용이 있으므로 앱 한도는 계정 농장 방어의 완전한 증명이 아니다.

### 결제 폐기 이후 출시 판정

- [구독 런북](subscription-setup-runbook.md)은 폐기 기록과 제거 검증만 설명한다. 후보 빌드에서
  구매 SDK, paywall, 결제 라우트, RevenueCat webhook·worker·scheduler, 결제 Secret 요구가 모두
  없는지 정적 계약과 스토어 콘솔에서 확인한다. 과거 판매가 있었다면 고객 통지·환불·회계 의무는
  별도 운영 기록으로 처리하되 앱 접근 게이트를 되살리지 않는다.
- Firebase는 변경된 함수를 이름까지 좁혀 배포한다. 전체 Gye codebase 배포로 폐기된 결제 함수나
  운영에 없던 함수를 새로 만들지 않는다. 과거 결제 함수가 발견되면 live inventory와 명시적
  삭제 대상을 다시 확인한 뒤 별도 삭제한다.
- 과거 결제 레코드와 미완료 작업은 신규 처리를 재개하지 않는다. 법적 보존 기간과 계정 삭제
  계약을 함께 확인해 서버 전용으로 정리하며, 자동 TTL이나 임의 placeholder로 증거를 없애지 않는다.
- 실제 무료 공개 후 최소14일의 crash-free/ANR, 로그인 성공률, 삭제 큐, AI 비용을
  관찰한다. 테스트나 시간이 적힌 문서로 실제 관찰 기간을 대체하지 않는다.
- 마이크/Azure 발음 평가, 개인 TTS 수명, 과거 결제 데이터 정리에 맞게 공개 개인정보 문서와
  스토어 Data Safety/App Privacy 답변을 W9 소유자가 검토한다. 신규 결제 처리나 구독 판매를
  한다는 문구를 남기지 않는다. 기존 "음성 녹음 없음" 문구는
  발음 평가가 포함된 후보의 제출 문구로 재사용하면 안 된다.
- fullSHA source→CI→배포revision→스토어업로드→설치기기→운영관찰의 각 증거가 없으면
  "상용화100%"로 표기하지 않는다. 코드를 main에 병합하는 것은 판매 활성화가 아니다.

### Firebase Hosting 공개 묶음

- `docs/` 전체를 Hosting root로 쓰지 않는다. 이 폴더에는 내부 계획·감사 자료·검토 문서가
  함께 있으므로 `node scripts/prepare_firebase_hosting.cjs`가 만드는
  `build/firebase-hosting`의 명시적 11개 파일만 배포한다.
- 배포 전 `.github/scripts/test_firebase_hosting_contract.py`를 실행하고 산출물에 `.md`나
  `.json`이 없으며 원본과 byte-for-byte로 같은지 확인한다. 그 다음에만
  `firebase --config firebase.json deploy --only hosting --project ko-lernen-app`을 실행한다.
- 이 명령은 Firebase 기본 사이트만 갱신한다. `hangul-sori.com`은 별도 Cloudflare 공개
  경로이므로 이 배포의 성공을 해당 도메인 갱신 증거로 쓰지 않고, 스토어 URL은 실제 도메인에서
  각각 다시 확인한다.
