# Cloud Function 배포 런북 — `analyze_korean_text` (책 한 컷)

> 작성 2026-06-02 (갱신 2026-06-04: 우리말샘/사전 정의 비사용 — 정확도 미달로 제외). 사진→단어/문법/예문 분석 백엔드를 배포한다.
> 함수 코드는 완성 상태: **kiwipiepy(순수 Python)** 형태소 분석 + **DeepL** 번역.
> 코드가 `@functions_framework.http` (GCP 네이티브) 스타일이라 **`gcloud` 배포**가 정석이다.
> (`firebase deploy --only functions` 는 `firebase_functions` SDK 래퍼가 필요 → 코드 수정 유발하므로 권장 안 함.)

## 0. 사전 준비 (1회)
```bash
gcloud auth login                          # 본인 Google 계정
gcloud config set project ko-lernen-app
gcloud services enable run.googleapis.com cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com artifactregistry.googleapis.com
```

## 1. API 키 확인 (커밋 금지 — `.env*` 는 gitignore됨)
`functions/analyze_korean_text/.env` 에 **DeepL 키**가 있는지 확인:
```bash
grep -oE '^[A-Z_]+=' functions/analyze_korean_text/.env   # 변수명만 (값 비표시)
```
`DEEPL_API_KEY=` 가 있고, **값이 `.env.example` 의 placeholder 가 아니라 실제 발급 키**인지 직접 확인.
> `URIMALSAEM_API_KEY`·`STDICT_API_KEY` 가 남아 있어도 무방 — 현재 코드는 사전 정의(`definitionKo`)를 호출하지 않아 **미사용**이다(§3 참조). 런타임 영향 없음.
> ⚠️ DeepL 키가 과거 세션 대화에 평문 노출됨 → 배포·검증 후 **DeepL 무료키 재발급** 권장.

## 2. 배포 (Gen2)
```bash
cd /Users/sujinpark/Developer/ko_lernen_app
gcloud functions deploy analyze_korean_text \
  --gen2 --runtime=python312 --region=europe-west3 \
  --source=functions/analyze_korean_text \
  --entry-point=analyze_korean_text \
  --trigger-http --allow-unauthenticated \
  --set-env-vars "$(grep -v '^#' functions/analyze_korean_text/.env | grep -v '^$' | paste -sd, -)"
```
- `europe-west3`(Frankfurt) = privacy.html 의 "EU 서버" 주장과 일치.
- `--set-env-vars "$(…)"` 가 `.env` 를 읽어 키를 런타임에 주입 → 키를 쉘에 직접 타이핑하지 않음.
- `--allow-unauthenticated`: 앱이 익명 호출 (Firebase Auth 토큰 미전송). 남용 방지는 클라이언트 일일 20회 제한 + 추후 App Check 검토.

배포 URL 확인:
```bash
gcloud functions describe analyze_korean_text --region=europe-west3 --gen2 \
  --format='value(serviceConfig.uri)'
```

## 3. 검증 (curl)
```bash
curl -X POST '<배포-URL>' -H 'Content-Type: application/json' \
  -d '{"text":"저는 학생이에요. 오늘 날씨가 좋아요.","lang":"de"}'
```
기대: `{"words":[…],"grammar":[…],"sentences":[…],"warnings":[]}` — words 에 `translation`(독일어) 채워짐. 빈 `translation` → DeepL 키 문제.
> `definitionKo` 필드는 응답 스키마 유지를 위해 남아 있으나 **항상 빈 문자열**이다 — NIKL 사전 API(우리말샘·표준국어대사전)가 동음이의어의 "대표 뜻"을 안정적으로 주지 못해(정확도 미달) 비활성화([main.py](../../functions/analyze_korean_text/main.py) `enrich_definitions` 주석). 클라이언트는 빈 값이면 자동 숨김 → 정상.

## 4. 앱에 endpoint 연결
`lib/main.dart` 는 이미 3단계로 endpoint 를 정함: **Settings 저장값 > `--dart-define` > 기본값(`europe-west3-ko-lernen-app.cloudfunctions.net/...`)**.
- 위 기본 region/이름으로 배포하면 **추가 설정 없이 동작**.
- 다른 URL 이면: 릴리즈 빌드 시 `--dart-define=BOOK_ANALYSIS_ENDPOINT=<URL>` 추가, 또는 앱 Settings → "Cloud-Analyse-Endpoint" 에 입력.

## 5. Firestore Rules 배포 (gye·shared_packs·cache·age-gate·admin)
```bash
firebase deploy --only firestore:rules
```
> v2.0 rules: gye 멤버/피드/스티커/신고 + `isActiveGyeMember`(정지자 전송 차단) + `isAdmin()`(admin 패널) + `cache/translations`. 배포 후 에뮬레이터 또는 실기기 2계정으로 검증 권장.

## 6. Firestore 인덱스 배포 (admin 패널 신고 큐)
```bash
firebase deploy --only firestore:indexes
```
`firestore.indexes.json` 에 `reports` **collection-group** 단일필드(`createdAt`) override 정의됨 → admin 패널 `collectionGroup('reports').orderBy('createdAt')` 용.
> 형식 오류로 배포 실패 시, admin 패널 첫 조회에서 콘솔 에러의 "인덱스 생성" 링크 클릭으로 대체 가능.

## 7. 계(契) Cloud Functions 배포 (Node — `functions/gye`)
`analyze_korean_text`(Python·gcloud)와 **별개 codebase**. `firebase.json`: `source=functions/gye`, `codebase=gye-firebase-functions`, runtime nodejs20.
```bash
cd functions/gye && npm install
firebase deploy --only functions:on_pack_cleared,functions:weekly_goal_rollover,functions:on_report_created
# 또는 codebase 전체: firebase deploy --only functions
```
- `weekly_goal_rollover` 는 배포 시 **Cloud Scheduler job 자동 생성**(Blaze + Cloud Scheduler API 필요). 확인: `gcloud scheduler jobs list`.
- FCM 푸시(`pushToGyeMembers`)는 **iOS APNs 키 + FCM enable** 후에만 실제 전달됨.

## 8. 배포 후 스모크 테스트
**① 책 한 컷 (HTTP):**
```bash
python3 functions/analyze_korean_text/smoke_test.py '<배포-URL>'
```
응답 스키마(words/grammar/sentences) + DeepL 번역 + 빈/초과 엣지 검증. 전부 통과 시 exit 0. 빈 `translation` → `DEEPL_API_KEY` 확인.

**② 계 (Firestore 트리거):** 서비스 계정 키 필요.
```bash
export GOOGLE_APPLICATION_CREDENTIALS=/경로/serviceAccountKey.json
cd functions/gye && npm install && npm run smoke
```
`on_pack_cleared`(진행도·피드) + `on_report_created`(서로 다른 3명→정지) 를 실데이터로 검증 후 테스트 데이터(`SMOKE…`) 자동 정리. `weekly_goal_rollover`(스케줄)는 제외 — `gcloud scheduler jobs run …` 로 수동 트리거.
> ⚠️ 실 Firestore에 쓰므로 프로덕션에서는 신중히(테스트 데이터는 프리픽스·자동 삭제로 격리).

## 비용 / 한도
- kiwipiepy: 순수 Python, cold start 수 초. Gen2 기본 메모리(256MB)로 충분(필요 시 `--memory=512Mi`).
- DeepL Free: 500k 자/월.
- 클라이언트 일일 20장 제한(`kBookSnapDailyLimit`).
