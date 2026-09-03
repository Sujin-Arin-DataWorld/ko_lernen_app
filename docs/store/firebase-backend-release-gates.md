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
- `service_idempotency_results.expiresAt` TTL은15분 결과 보관, `service_idempotency.expiresAt`은
  책/발음24시간 hash-only 중복 방지다. API 접근 만료와 Firestore TTL 실제 삭제는 별개다.
- `premium_grants`, `customer_entitlements`, `billing_customers`, billing receipts, access rate
  documents는 서버 전용이며 계정 삭제 어댑터가 소유자 해시로 제거한다. late completion이
  삭제 계정을 다시 만드는지 계정 삭제 worker와 합동 검증한다.

### 테스터 권한과 비용 중단 장치

- 명시적으로 Jin이 승인한 최대100UID 명단만 `functions/gye/manage_premium_grants.js`에 입력한다.
  형식은 `schemaVersion:1`, `approvedBy:"Jin"`, `approvalRef`, `environment`,
  `action:"grant"|"revoke"`, `uids`다. 이 메타데이터는 사람 승인 자체의 암호학적 증명이 아니다.
  명단 검토와 제한된 ADC/IAM을 운영자가 책임지며 파일은 저장소/로그에 올리지 않는다.
- 구독·테스터 권한의 `accountCreatedAt`은 서버 Auth 생성 시각과 일치해야 한다.
  누락·불일치 문서는 Premium으로 인정하지 않는다. 구독은 검증된 provider 재조회와
  reconciliation으로 발급하고, 테스터 재부여는 새 명단 승인을 거친다. 값을 추측해 채우지 않는다.
  Admin Node 공개 metadata는 초 단위이므로 Python도 같은 정밀도를 쓴다. 관리자가 같은 UID를
  같은 초 안에 삭제·재생성한 경우는 이 필드로 구별하지 못한다. 운영 복구에 UID 재사용을
  금지하고 새 UID·새 승인을 사용한다. 정상 앱 삭제의 marker/cleanup 절차는 계속 적용한다.
- 기본은 read-only dry-run이다. `--project ko-lernen-app --approved-roster <검증된 파일>`로
  건수만 확인하고 명시적 승인 뒤에만 `--apply`한다. 이 작업에서 실제 권한 부여는 하지 않았다.
  feedback passport나 `BETA_UNLOCK_ALL`로 생성하지 않는다. 재생성 UID는 새 승인이 필요하다.
- `service_cost_controls/ai_v1`은 `schemaVersion:1`, `approvedBy:"Jin"`, `approvalRef`,
  `approvedAt`, `dailyUnitLimit`, `bookReservationUnits`, `pronunciationReservationUnits`,
  `ttsReservationUnits`를 요구한다. 모든 요청 가중치는 양수, 하루 한도는0이상 정수다.
  누락/잘못된 설정/한도0/소진은 새 외부 처리 전에 fail-closed다. 검증을 위해 임의 운영 예산을 넣지 않는다.
- `service_cost_ledgers/YYYY-MM-DD`는 두 환경·책·발음·새 TTS 합성의 비용 예약을 함께 제한한다.
  TTL은 UTC day+2일이다. 이미 처리했는지 불명확한 요청의 비용은 환급하지 않는다.
  가중치는 **설정된 보수적 예약 단위**이지 실제 유로 비용 측정값이 아니다.
- 최대 허용 입력의 provider 비용, 중복/실패/재시도, TTS, Firestore·함수·Storage 비용을 측정한다.
  원문/음성 대신 비식별 비용 표본의 n/평균/p95/max와 산출 근거를 남긴다. 무료 사용자 비용도 포함한다.
- 스토어 실제 정산 순수입과 무료/구독 사용자 사용 분포를 대조해 €5/월·20/50 정책을 승인한다.
  비용이 맞지 않거나 측정 증거가 없으면 유료 전환을 중단한다. 가격/한도를 자동으로 바꾸지 않는다.
  거절된 트래픽도 Auth/Firestore/인프라 비용이 있으므로 앱 한도는 계정 농장 방어의 완전한 증명이 아니다.

### 결제 운영과 출시 판정

- [구독 런북](subscription-setup-runbook.md)의 신규 구매/갱신/취소/만료/환불/복원/보류/유예
  매트릭스를 두 스토어에서 실제 후보 빌드로 수행한다. TestFlight는 sandbox다.
- Billing 기본 비활성, server environment 분리, Keep original App User ID 콘솔 설정, worker
  retry/scheduler 배포와 Secret 최소 바인딩을 검증한다. 새 Secret이 필요한 결제 함수까지 포함한
  전체 Gye deploy는 설정이 준비될 때까지 실행하지 않는다. 임의 Secret placeholder로 통과시키지 않는다.
- 미완료 결제 작업은 TTL로 버리지 않는다.7일 이상 지연되면 hourly 재시도와 aggregate review
  경고를 발생시킨다. 일반 pending/실패율도 운영 알림을 설정하고7일 전에 고객 지원이 개입한다.
  완료 receipt는 UID를 제거한 최소 hash-only metadata를30일 TTL로 보관한다.
- 실제 무료 공개 후 최소14일의 crash-free/ANR, 로그인 성공률, 삭제 큐, pending결제, AI 비용을
  관찰한다. 테스트나 시간이 적힌 문서로 실제 관찰 기간을 대체하지 않는다.
- 마이크/Azure 발음 평가, 개인 TTS 수명, 서버 권한/결제 처리에 맞게 공개 개인정보 문서와
  스토어 Data Safety/App Privacy 답변을 W9 소유자가 검토한다. 기존 "음성 녹음 없음" 문구는
  발음 평가가 포함된 후보의 제출 문구로 재사용하면 안 된다.
- fullSHA source→CI→배포revision→스토어업로드→설치기기→운영관찰의 각 증거가 없으면
  "상용화100%"로 표기하지 않는다. 코드를 main에 병합하는 것은 판매 활성화가 아니다.
