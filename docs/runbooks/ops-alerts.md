# 운영 알림 런북 (ops-alerts)

`tool/ops/alert_policies/*.json`로 정의된 5개 알림 정책이 무엇을 뜻하는지,
울렸을 때 뭘 먼저 볼지, 어떻게 잠재울지 정리한다. 정책은 이 PR(B1) 병합
시점엔 **적용되어 있지 않다** — Jin이 `tool/ops/apply_alerts.sh`(또는
`.ps1`)를 직접 실행해야 실제로 생긴다. 실행 전 반드시 `tool/ops/log_metrics.sh`
로 로그 기반 메트릭부터 만든다 (03번 정책이 그 위에서 동작).

2026-09-14 실측: `gcloud alpha monitoring policies list --project=ko-lernen-app`
= 0건, `gcloud logging metrics list --project=ko-lernen-app` = 0건. 즉 지금
이 프로젝트엔 알림이 전혀 없다 — 이 PR은 그 공백을 코드로 채우는 것.

각 파일의 정확한 메트릭 타입·출처 문서·실측 방법은
`tool/ops/alert_policies/_sources.md`를 본다.

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

**의미:** 두 로그 기반 카운터 중 하나라도 10분 창에서 0을 넘었다.
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

## 04 — 계정 삭제 워커 정지 (25시간 동안 실행 0건) — **미검증 정책**

**의미:** `firebase-schedule-account_deletion_worker-europe-west3` Cloud
Scheduler 잡은 평소 5분마다 실행된다(2026-09-14 `gcloud scheduler jobs list`
로 실측). 25시간 동안 실행 기록이 전혀 없으면 스케줄러가 멈췄거나, IAM이
깨졌거나, 대상 Cloud Run 서비스가 invoke를 거부하고 있다 — **계정 삭제
요청이 조용히 쌓이고 있다는 뜻.**

**⚠️ 이 정책은 `_unverified: true`다.** `cloudscheduler.googleapis.com/job/execution_count`
메트릭을 이 프로젝트에서 라이브로 확인하지 못했다(문서 페이지도 스크래핑
실패, `metricDescriptors.list`도 0건 반환 — 상세는 `_sources.md`). Jin이
`apply_alerts.sh --dry-run` 결과를 검토하거나, 실제 적용 후 Metrics
Explorer에서 "Cloud Scheduler Job"으로 검색해 이 메트릭이 실제로 잡히는지
먼저 확인할 것. 안 잡히면 정책이 생성 자체가 실패하거나(존재하지 않는
메트릭 타입) 아무 데이터도 없어 계속 발동 상태로 남을 수 있다.

**먼저 확인할 것 3가지:**
1. `gcloud scheduler jobs describe firebase-schedule-account_deletion_worker-europe-west3 --project=ko-lernen-app --location=europe-west3` 로 잡이 `ENABLED`인지.
2. `gcloud scheduler jobs list --project=ko-lernen-app --location=europe-west3` 에서 마지막 실행 시각/상태.
3. Cloud Run `account-deletion-worker` 서비스가 최근 배포로 깨졌는지
   (`gcloud run services describe account-deletion-worker --project=ko-lernen-app --region=europe-west3`).

**잠재우는 법:** 원인 조치 우선. Scheduler 잡을 수동으로
`gcloud scheduler jobs run`으로 한 번 돌려 즉시 밀린 큐를 확인한 뒤에만
스누즈.

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

## 적용 영수증 (적용 영수증)

`tool/ops/apply_alerts.sh`(또는 `.ps1`) 실행 후, 출력된 `POLICY NAME / ERROR`
열의 값을 아래 표에 채운다. `gcloud alpha monitoring policies list
--project=ko-lernen-app`로도 다시 확인 가능.

| 날짜 | 정책 파일 | Policy ID (name) | 적용자 |
|---|---|---|---|
| _(미기입)_ | 01_functions_5xx_rate.json | | |
| _(미기입)_ | 02_appcheck_rejections.json | | |
| _(미기입)_ | 03_ai_cost_breaker_unavailable.json | | |
| _(미기입)_ | 04_deletion_worker_stalled.json | | |
| _(미기입)_ | 05_firestore_write_surge.json | | |
