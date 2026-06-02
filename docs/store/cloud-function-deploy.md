# Cloud Function 배포 런북 — `analyze_korean_text` (책 한 컷)

> 작성 2026-06-02. 사진→단어/문법/예문 분석 백엔드를 배포한다.
> 함수 코드는 완성 상태: **kiwipiepy(순수 Python)** + **DeepL** 번역 + **우리말샘(NIKL)** 정의.
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
`functions/analyze_korean_text/.env` 에 **실제** 키 2개가 있는지 확인:
```bash
grep -oE '^[A-Z_]+=' functions/analyze_korean_text/.env   # 변수명만 (값 비표시)
```
`DEEPL_API_KEY=` 와 `URIMALSAEM_API_KEY=` 가 있어야 하고, **값이 `.env.example` 의 placeholder 가 아니라 이번에 발급한 실제 키**인지 직접 확인. (현재 두 값 모두 채워져 있음.)
> ⚠️ DeepL 키가 이 세션 대화에 평문 노출됨 → 배포·검증 후 **DeepL 무료키 재발급** 권장.

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
기대: `{"words":[…],"grammar":[…],"sentences":[…],"warnings":[]}` — words 에 `translation`(독일어)·`definitionKo`(우리말샘) 채워짐. 빈 `translation` → DeepL 키 문제. 빈 `definitionKo` → 우리말샘 키 문제(비치명적).

## 4. 앱에 endpoint 연결
`lib/main.dart` 는 이미 3단계로 endpoint 를 정함: **Settings 저장값 > `--dart-define` > 기본값(`europe-west3-ko-lernen-app.cloudfunctions.net/...`)**.
- 위 기본 region/이름으로 배포하면 **추가 설정 없이 동작**.
- 다른 URL 이면: 릴리즈 빌드 시 `--dart-define=BOOK_ANALYSIS_ENDPOINT=<URL>` 추가, 또는 앱 Settings → "Cloud-Analyse-Endpoint" 에 입력.

## 5. Firestore Rules 배포 (공유 기능 `shared_packs`)
```bash
firebase deploy --only firestore:rules
```

## 비용 / 한도
- kiwipiepy: 순수 Python, cold start 수 초. Gen2 기본 메모리(256MB)로 충분(필요 시 `--memory=512Mi`).
- DeepL Free: 500k 자/월. 우리말샘: 무료.
- 클라이언트 일일 20장 제한(`kBookSnapDailyLimit`).
