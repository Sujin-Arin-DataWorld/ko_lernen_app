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

Node 함수는 저장소가 지정한 Node 22를 사용한다. Auth cleanup만 Gen1 Node 20이다.
Firestore rules emulator에는 Java도 필요하다.

```bash
npm ci --prefix functions/gye
npm test --prefix functions/gye
npm --prefix functions/gye run test:rules

npm ci --prefix functions/tts
npm test --prefix functions/tts

npm ci --prefix functions/pronunciation
npm test --prefix functions/pronunciation

npm ci --prefix functions/auth_cleanup
npm test --prefix functions/auth_cleanup
```

Book Gen2는 Python 3.12와 별도 dependencies가 필요하다. 정확한 preflight와 source
closure는 [cloud-function-deploy.md](cloud-function-deploy.md)를 따른다.

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
  --no-gen2 --runtime=nodejs20 --region=europe-west3 \
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
