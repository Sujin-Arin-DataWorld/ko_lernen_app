# 운영 알림 런북 (ops-alerts)

정책 정의와 실제 적용 상태를 구분한다. 2026-09-22 읽기 전용 확인에서
`ko-lernen-app`의 알림 정책과 수신 채널은 각각 0개였다. 아래 코드 수정은
실제 정책 생성이나 알림 수신 성공을 의미하지 않는다.

Bash와 PowerShell은 `tool/ops/apply_alerts.py`를 공통으로 실행한다.
Python 3.12와 로그인된 `gcloud`가 필요하다. `GCP_PROJECT`는 반드시
`ko-lernen-app`, `NOTIFICATION_CHANNEL_ID`는 이 프로젝트의 실제 숫자 ID
또는 `projects/ko-lernen-app/notificationChannels/<ID>`여야 한다.
토큰은 메모리에만 두고 수신 주소·서버 응답 본문은 출력하지 않는다.

```powershell
$env:GCP_PROJECT = 'ko-lernen-app'
$env:NOTIFICATION_CHANNEL_ID = '<실제 채널 ID>'
python tool/ops/apply_alerts.py --dry-run --policy 01 --policy 02 --policy 04 --policy 05
```

`--dry-run`은 채널 상태, 메트릭 descriptor, 04의 최근 성공 시계열, 기존 정책을
GET으로 검사한다. 실제 변경 시 같은 명령에서 `--dry-run`만 뺀다.
`.sh`는 같은 인자, `.ps1`은 `-DryRun -Policy 01,02,04,05`를 사용한다.
`PYTHON` 환경 변수로 사용할 Python 실행 파일을 지정할 수 있다.

선택한 모든 정책의 사전 검사를 통과해야 첫 생성 요청을 보낸다. 같은 설정의
기존 정책은 건너뛰며, 중복 또는 수동 변경이 있으면 적용을 중단한다. 수정·삭제는
하지 않는다. 순차 재실행 시 이미 생성된 정책을 다시 만들지 않지만, API에는
원자적인 중복 방지 키가 없으므로 **한 작업자만 적용한다**. 생성 응답이 불명확하면
재시도하지 않고 실패로 종료한다. 다음 실행 전 실제 정책 목록을 확인한다.
이미 생성된 정책의 JSON 영수증은 유지되며 후속 실패도 종료 코드 1로 전달된다.
서버가 기존 정책의 `validity.code`를 0 이외로 반환하거나 상태 형식이 잘못되면
정상 정책으로 건너뛰지 않고 전체 적용을 중단한다. API가 생략한 기본 알림 시점과
`notificationPrompts: ["OPENED"]`는 같게 비교하되, 종료 알림 등 다른 동작은
수동 변경으로 판정한다.

03은 로그 발생 계약이 미검증이므로 기본 전체 적용은 생성 전에 실패한다.
위처럼 검증된 정책을 명시적으로 선택할 수 있다. 채널이 비활성 또는
`UNVERIFIED`여도 적용하지 않는다. 사전 검사와 정책 생성은 실제 알림 수신,
사고 재현, 계정 삭제 큐 처리 완료의 증거를 대신하지 않는다.

메트릭과 검증 한계는 `tool/ops/alert_policies/_sources.md`에 기록한다.

## 로그 기반 카운터 사전 검사와 생성

`tool/ops/log_metrics.py`는 비용 브레이커, Apple 설정 오류, Auth 생성의 기존
세 필터를 유지한다. Bash `log_metrics.sh`와 PowerShell `log_metrics.ps1`도
이 도구를 실행한다. Python 3.12와 로그인된 `gcloud`가 필요하며 프로젝트를
`ko-lernen-app`으로 명시해야 한다. 별도 수신 채널은 필요하지 않다.

```powershell
$env:GCP_PROJECT = 'ko-lernen-app'
python tool/ops/log_metrics.py --dry-run
# 한 카운터만 검사할 때:
python tool/ops/log_metrics.py --dry-run --metric auth_anonymous_account_created
```

`.sh`는 같은 인자, `.ps1`은 `-DryRun -Metric auth_anonymous_account_created`를
받는다. 실제 생성은 검토한 명령에서 dry-run 옵션만 제거한다.
선택한 카운터를 모두 GET으로 읽은 뒤 필요한 것만 생성한다. 명시적인 404만
부재로 판단하며 권한 거절·호출 제한·네트워크 오류는 쓰기 전에 중단한다.
필터, 설명, 활성 상태, 프로젝트/버킷 범위, DELTA/INT64 집계, 단위 또는
사용자 라벨이 다르면 기존 메트릭을 수정·삭제하지 않고 중단한다.

생성 직전 `create_requested`, 생성 응답과 재조회 설정이 모두 일치하면
`created`를 JSON으로 출력한다. 동일 설정은 `unchanged`, dry-run의 부재는
`would_create`다. 부분 성공 뒤 실패해도 앞의 영수증을 유지하고 종료 코드 1을
반환한다. 한 작업자만 적용하며 불명확한 POST 응답·409 충돌을 자동 재시도하지
않는다. 실제 상태를 dry-run으로 확인한 뒤 다시 판단한다. 토큰·서버 본문·실제
로그 항목은 출력하지 않는다.

이는 메트릭 **설정** 확인이다. 생성 이전 이벤트를 소급 집계하지 않으며,
실제 새 이벤트의 일치와 시계열 수신은 별도로 검증한다. 영수증의
`eventDeliveryVerified`는 항상 false다. 이 도구는 알림 정책이나 테스트 계정을
만들지 않으며, 03의 로그 계약 검증 차단도 해제하지 않는다.

---

## 01 — Functions 5xx ratio > 2% (5분, 서비스별)

**의미:** `gye-firebase-functions` / `tts-firebase-functions` /
`pronunciation-firebase-functions` / `analyze-korean-text` 중 하나가 2nd-gen
Cloud Run 리비전으로 europe-west3에서 돌면서 5xx 비율이 5분 창에서 2%를
넘었다. 메트릭: `run.googleapis.com/request_count`
(`response_code_class="5xx"` / 전체, `resource.label.service_name`별 그룹).

**먼저 확인할 것 3가지:**
1. 어느 서비스인지 `resource.label.service_name`로 확인 — Cloud Logging에서
   `resource.type="cloud_run_revision" AND resource.labels.service_name="<서비스>" AND severity>=ERROR`
   로 최근 에러 본문을 본다.
2. 최근 배포가 있었나 — `gcloud run revisions list --project=ko-lernen-app --region=europe-west3 --service=<서비스>`
   로 트래픽이 새 리비전으로 넘어간 시각과 알림 시각이 겹치는지 본다.
3. 업스트림 의존성(Firestore, App Check, 외부 TTS/발음 API, `analyze_korean_text`
   Python 백엔드)이 같이 흔들리는지 — 02/05번 알림이 같이 울렸는지 본다.

**잠재우는 법:** Cloud Console → Monitoring → Alerting → 해당 정책 → Snooze,
또는 `gcloud alpha monitoring snoozes create`로 특정 서비스만 기간 한정
스누즈. 정책 자체를 끄지 말 것(재발 시 무음이 된다) — 원인 조치 후 자연
해소를 기다리거나 스누즈만 쓴다.

---

## 02 — App Check 거부 급증 (>50건 / 5분)

**의미:** `firebaseappcheck.googleapis.com/services/verification_count`
(`result="DENY"`)가 5분 창에서 50건을 넘었다. 클라이언트 빌드가 오래된
App Check attestation을 들고 있거나, Play Integrity/DeviceCheck 공급자 설정이
깨졌거나, 스크래핑/어뷰징 시도.

**먼저 확인할 것 3가지:**
1. Firebase 콘솔 → App Check → APIs 탭에서 어떤 버킷(Invalid / Outdated
   client / Unknown origin / Reused token)이 늘었는지 본다 — 원인이 갈린다.
2. 최근 Android/iOS 릴리스가 있었나 — 구버전 클라이언트가 만료된
   attestation을 계속 보내는 패턴이면 배포 문제가 아니라 사용자 자연
   유입 문제일 수 있다.
3. App Check 강제 여부 — 어떤 Cloud Function이 App Check를 필수로 요구하는지
   `functions/*/index.js`에서 `enforceAppCheck` 관련 설정을 확인. 거부가
   해당 함수만 차단하는지, 앱 전체가 막히는지 구분한다.

**잠재우는 법:** 01번과 동일 — Snooze 또는 기간 한정 스누즈. 원인이
"릴리스 롤아웃 중 구버전 트래픽 자연 감소"로 확인되면 24시간 스누즈 후
재확인.

---

## 03 — AI 비용 브레이커 / Apple revocation 설정 불가 (10분 내 1건이라도)

**미검증 — 자동 적용 차단.** 두 로그 기반 카운터 중 하나라도 10분 창에서
0을 넘을 때의 정책 정의다. 예외를 던진다는 사실만으로 해당 문자열이 Cloud
Logging에 기록되는 것은 아니다. TTS는 `ServiceCostError`를 일반 오류 로거
앞에서 변환한다. 비용 정책·Apple 취소 양쪽의 실제 배포 코드, 개인정보 없는
진단 발생과 필터 일치, 메트릭 수신을 확인한 후 이 보류를 해제한다.
`log_metrics.sh`로 descriptor만 만드는 것은 이 검증을 충족하지 않는다.
- `ai_cost_breaker_unavailable`: `functions/pronunciation/service_cost_policy.js`
  / `functions/tts/service_cost_policy.js`의 `readCostControl()`이
  `service_cost_controls/ai_v1` Firestore 문서 검증에 실패해 `ServiceCostError
  ('unavailable', 'AI cost approval unavailable.')`를 던졌다 — **발음/TTS AI
  엔드포인트가 전부 거부되고 있을 수 있다.**
- `apple_revocation_config_invalid`: `functions/gye/apple_revocation_adapter.js`가
  `apple/revocation-config-invalid`를 던졌다 — **Apple 로그인 계정 삭제가
  Apple 측 토큰을 취소하지 못한 채(수동 처리 필요 플래그만 세우고) 넘어가고
  있다.**

**먼저 확인할 것 3가지:**
1. 어느 카운터가 울렸는지 정책의 조건 displayName으로 구분(두 조건이
   OR로 묶여 있다) — Cloud Logging에서
   `logging.googleapis.com/user/ai_cost_breaker_unavailable` 또는
   `.../apple_revocation_config_invalid` 메트릭 그래프를 본다.
2. (비용 브레이커) Firestore `service_cost_controls/ai_v1` 문서가 존재하고
   `schemaVersion=1`, `approvedBy="Jin"`, `approvalRef`, `dailyUnitLimit`,
   `bookReservationUnits`/`pronunciationReservationUnits`/`ttsReservationUnits`가
   모두 유효한 양수인지 콘솔에서 직접 연다.
3. (Apple revocation) `functions/gye`에 배포된 Apple revoke 시크릿
   (client secret / key)이 만료되지 않았는지, `apple_revocation_adapter.js`가
   기대하는 설정 키가 Secret Manager에 실제로 존재하는지 확인.

**잠재우는 법:** 원인 조치가 우선 — 이 알림은 실질적으로 "안전장치가
막혀서 기능이 죽어있다"는 신호라 장기 스누즈는 피한다. 조사 중 반복 알림이
시끄러우면 30분~1시간 짧은 스누즈만.

---

## 04 — 계정 삭제 워커 HTTP 성공 정지 (25시간)

**의미:** `account-deletion-worker`의 HTTP 2xx 응답이 5분 창마다 1건 미만인
상태를 24시간 55분 동안 재검사한다. 5분 정렬 창을 더한 총 평가 기간은
API 한도인 25시간이다. `europe-west3`의 실제 Cloud Run
`run.googleapis.com/request_count`를 리비전 전체로 합산한다. 데이터가
끊긴 경우도 위반으로 평가한다. 측정 수집 지연과 5분 정렬 경계 때문에 알림이
정확히 마지막 응답 25시간 뒤 도착한다고 보장하지 않는다.

2026-09-22 읽기 확인에서 최근 24시간 2xx 응답은 288건이었다. 이전
`cloudscheduler.googleapis.com/job/execution_count`는 직접 descriptor 조회가
404였으므로 제거했다. 적용 시에도 최근 24시간에 양수인 일치 시계열이 있어야
이 정책을 생성할 수 있다. 이미 고장 난 워커라 이 검사가 실패하면 먼저 원인을
조사한다. 인위적인 계정 삭제 호출로 검사를 통과시키지 않는다.

**한계:** HTTP 성공은 호출 생존 신호다. 큐가 비었거나 개별 삭제·Apple 토큰
취소가 완료됐다는 뜻이 아니다. 삭제 요청의 나이·재시도·완료 상태는 별도
운영 검증 대상으로 유지한다. 이 25시간 정지 알림의 실제 발화도 아직 미검증이다.

**확인 순서:**
1. Scheduler `firebase-schedule-account_deletion_worker-europe-west3`의 활성 상태와 최근 시도.
2. Cloud Run `account-deletion-worker`의 응답 상태·오류·최근 리비전 변경.
3. 권한이 있는 읽기 경로로 삭제 큐 정체와 Apple 취소 상태를 별도 확인.

원인 조사 중 필요하면 기간 한정 Snooze를 사용한다. 실제 계정 삭제 워커를
알림 테스트 용도로 수동 실행하지 않는다.

---

## 05 — Firestore 쓰기 급증 (>10,000 / 15분, 하루 200,000의 대리 지표)

**의미:** `firestore.googleapis.com/document/write_count`(project 전체 합)가
15분 창에서 10,000건을 넘었다. 계획 목표는 "하루 200,000건"이지만 Cloud
Monitoring 임계값 조건은 짧은 롤링 윈도우에 맞게 설계돼 있어, 하루 평균의
약 4.8배에 해당하는 15분 버스트를 대리 지표로 쓴다(정확한 산식은 정책
파일의 `documentation.content` 참조). 재시도 폭풍, 클라이언트 동기화 루프
버그, 또는 비용 브레이커가 열린 채로 방치된 상황을 잡기 위함.

**먼저 확인할 것 3가지:**
1. Cloud Logging에서 최근 15분 `resource.type="cloud_run_revision"` 에러율이
   같이 튀었는지(재시도 폭풍이면 01번도 같이 울릴 가능성이 높다).
2. Firestore 콘솔 → Usage에서 어느 컬렉션이 쓰기를 주도하는지 확인.
3. 최근 배포된 클라이언트(Flutter 앱)가 동기화 로직을 바꿨는지 — 무한
   루프성 재동기화 의심.

**잠재우는 법:** 01번과 동일한 패턴.

---

## B3 계정 생성 관측

`log_metrics.sh`는 `auth_anonymous_account_created`도 만든다. Auth 생성 트리거의
로그만 집계하며 로그인·토큰 갱신·TTS 호출 횟수를 가입 수로 대신 쓰지 않는다.
5분 `ALIGN_SUM`/전체 `REDUCE_SUM`으로 추이를 보고, 증가 시 02번 App Check와
05번 쓰기 지표·최근 테스트 계정 생성 작업을 함께 확인한다. 자동 차단이나
근거 없는 새 호출 한도는 추가하지 않는다.

분류 기준, Admin 생성 계정 포함 여부, 이벤트 중복 가능성과 배포 후 확인은
[Auth 생성 관측 계약](../../functions/gye/AUTH_CREATION_OBSERVATION.md)을 따른다.
함수·메트릭 배포 및 실제 이벤트 증거가 없으면 관측이 작동한다고 기록하지 않는다.

## 적용과 수신 증거

스크립트는 정책별 `created`, `unchanged`, `would_create`를 JSON 한 줄로
출력한다. 실패 시 `status=failed`와 고정 오류 코드를 출력하고 0이 아닌
코드로 종료한다. stdout을 저장하면 부분 적용 후의 정책 ID도 남는다.
`created`는 Monitoring API 접수 결과이며 실제 수신 성공과 구분한다.

운영 기록에는 실행 시각, 정확한 소스 SHA, 선택 정책, 수신 채널 ID,
생성·기존 정책 ID, 실제 수신 확인과 남은 검증을 따로 남긴다. 수신 이메일이나
자격 증명 원문을 저장소나 공개 로그에 남기지 않는다.
