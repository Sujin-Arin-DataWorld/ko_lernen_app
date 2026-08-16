# 책 한 컷 Cloud Function 안전 배포 런북

> 대상: Gen2 `analyze_korean_text`, 프로젝트 `ko-lernen-app`, 리전
> `europe-west3`. 이 문서는 명령을 설명할 뿐 배포 완료를 의미하지 않는다.
>
> **운영 상태:** 2026-08-15 감사 당시 live 함수는 저장소보다 오래된 소스였고
> 배포 ZIP에 `security.py`와 `grammar_analysis.py`가 없었다. 로컬 테스트만으로
> 운영 복구를 주장하지 않는다. 아래의 source SHA, signed Android/iOS smoke,
> TTL 검증까지 모두 통과한 시점에만 복구 완료로 기록한다.

## 1. 로컬 검증 환경

함수는 Python 3.12로만 검증·배포한다. 별도 가상환경에 고정 requirements를
설치한 다음 분석 컴포넌트 전용 preflight를 실행한다.

```bash
cd /path/to/ko_lernen_app
python3.12 -m venv .venv-book-analysis
source .venv-book-analysis/bin/activate
python -m pip install --upgrade pip
python -m pip install -r functions/analyze_korean_text/requirements.txt
bash functions/preflight.sh analyze
```

preflight는 다음을 모두 강제하며 외부 상태를 변경하지 않는다.

- 실제 Python 3.12와 모든 requirements import
- `test_*.py` 전체 discovery 성공 및 skip 0
- runtime/operator 모듈 컴파일
- Android+iOS App ID가 든 비밀 없는 `deploy.env.yaml`
- `.gcloudignore`의 exact runtime allowlist와 파일 존재 여부
- Firestore `translation_cache` server-only rule과 TTL 계약

저장소 전체 Gye/Firestore 정적 검사도 필요하면 `bash functions/preflight.sh all`을
별도로 실행한다.

## 2. 배포 ZIP exact allowlist

`functions/analyze_korean_text/.gcloudignore`는 모든 파일을 먼저 제외한 뒤 현재
import closure에 필요한 다음 **7개만** 허용한다.

1. `main.py`
2. `requirements.txt`
3. `dictionary_validation.py`
4. `grammar_analysis.py`
5. `grammar_patterns.json`
6. `security.py`
7. `text_quality.py`

계획 단계의 8개는 추정치였다. 실제 import closure가 7개이므로 불필요한 8번째
파일을 추가하지 않는다. `.env*`, `deploy.env.yaml`, 테스트, smoke 도구,
`__pycache__`, `*.pyc`는 source ZIP에 들어갈 수 없다.

로컬 allowlist와 canonical SHA 확인:

```bash
python functions/analyze_korean_text/verify_deployed_source.py \
  --check-gcloud-upload
```

## 3. Secret Manager와 전용 런타임 계정

`deploy.env.yaml`에는 두 Firebase App ID만 있다. DeepL 키는 파일이나 셸 history에
넣지 않고 Secret Manager에서 런타임에 연결한다. 과거 채팅에 붙여넣은 키는
재사용하지 말고 먼저 폐기·재발급한다.

최초 1회, 운영 승인 아래 전용 서비스 계정과 최소 권한을 만든다.

```bash
PROJECT_ID='ko-lernen-app'
RUNTIME_SA_NAME='hangul-sori-book-analysis'
RUNTIME_SA="${RUNTIME_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud iam service-accounts create "$RUNTIME_SA_NAME" \
  --project="$PROJECT_ID" \
  --display-name='Hangul Sori book analysis runtime'

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${RUNTIME_SA}" \
  --role='roles/datastore.user'
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${RUNTIME_SA}" \
  --role='roles/logging.logWriter'

gcloud secrets create DEEPL_API_KEY \
  --project="$PROJECT_ID" --replication-policy='automatic'
gcloud secrets add-iam-policy-binding DEEPL_API_KEY \
  --project="$PROJECT_ID" \
  --member="serviceAccount:${RUNTIME_SA}" \
  --role='roles/secretmanager.secretAccessor'
```

새 키 버전은 키가 화면에 재출력되지 않는 로컬 셸에서만 넣는다.

```bash
read -s DEEPL_API_KEY_VALUE
printf '%s' "$DEEPL_API_KEY_VALUE" | \
  gcloud secrets versions add DEEPL_API_KEY \
    --project='ko-lernen-app' --data-file=-
unset DEEPL_API_KEY_VALUE
```

배포 실행자에게는 이 런타임 계정을 사용할 `iam.serviceAccounts.actAs` 권한이
별도로 있어야 한다. 런타임 계정에는 프로젝트 Owner/Editor 역할을 주지 않는다.

## 4. Firestore 캐시 보호 준비

새 캐시 문서는 원문 `src` 없이 번역·대상 언어·버전·`expiresAt`만 저장한다.
`expiresAt`은 서버가 기록 시점+30일로 생성하며 TTL 필드는
`firestore.indexes.json`에 선언돼 있다. `firestore.rules`는
`translation_cache/{document=**}`의 모든 클라이언트 read/write를 명시적으로
거부한다. Admin SDK만 이 규칙의 외부에서 접근한다.

기존 문서 상태를 값 노출 없이 읽기만 하는 dry-run:

```bash
python functions/analyze_korean_text/cleanup_translation_cache.py \
  --project='ko-lernen-app'
```

Application Default Credentials가 없고 현재 `gcloud auth` 계정을 읽기 전용 감사에
사용할 때만 `--use-gcloud-credentials`를 추가한다. access token은 프로세스 메모리에
만 있고 출력·파일 저장하지 않는다.

출력은 `scanned`, `matched`, `deleted=0` 개수뿐이다. `src`가 있거나 현재
`_CACHE_VERSION`과 다르거나 유효한 `expiresAt` timestamp가 없는 문서만 match한다.
이 단계에서 `--apply`를 붙이지 않는다.
2026-08-15의 379개 측정치는 과거 스냅샷이며, 실행 시점 개수를 새로 확인한다.

## 5. Gen2 배포

사전 승인과 preflight 통과 후 저장소 루트에서 실행한다.

```bash
PROJECT_ID='ko-lernen-app'
RUNTIME_SA='hangul-sori-book-analysis@ko-lernen-app.iam.gserviceaccount.com'

gcloud functions deploy analyze_korean_text \
  --project="$PROJECT_ID" \
  --gen2 \
  --runtime='python312' \
  --region='europe-west3' \
  --source='functions/analyze_korean_text' \
  --entry-point='analyze_korean_text' \
  --service-account="$RUNTIME_SA" \
  --trigger-http \
  --allow-unauthenticated \
  --env-vars-file='functions/analyze_korean_text/deploy.env.yaml' \
  --set-secrets='DEEPL_API_KEY=DEEPL_API_KEY:latest'
```

`--allow-unauthenticated`는 Cloud IAM 입구만 연다. 함수 안에서 Firebase Auth와
App Check를 모두 검증하며 하나라도 없거나 변조되면 401이다. 서버 할당량은
사용자당 일 20회·분당 3회로 fail-closed한다.

## 6. 배포 source ZIP 동일성 검증

배포 직후 Cloud Functions가 가리키는 storage generation을 내려받아 로컬 7개
파일과 canonical SHA를 비교한다.

```bash
python functions/analyze_korean_text/verify_deployed_source.py \
  --function='analyze_korean_text' \
  --project='ko-lernen-app' \
  --region='europe-west3'
```

추가 파일, 빠진 파일, 한 바이트 차이 중 하나라도 있으면 exit 1이다. 도구는 source
내용이나 환경변수 값을 출력하지 않는다. PASS가 아니면 운영 복구로 기록하지 않고
다음 단계로 진행하지 않는다.

## 7. 독립 Auth/App Check signed smoke

서명된 테스트 앱에서 얻은 Firebase Auth ID token과 해당 플랫폼 App Check token을
현재 셸 환경변수로만 전달한다. 토큰을 문서·이슈·로그에 붙이지 않는다.

Android 토큰으로 독일어 계약을 검사한다.

```bash
export BOOK_ANALYSIS_ID_TOKEN='<Android test account ID token>'
export BOOK_ANALYSIS_APP_CHECK_TOKEN='<Android App Check token>'
python functions/analyze_korean_text/smoke_test.py '<deployed URL>' de \
  --expected-app-id='1:573567222361:android:38d26a50001ee64c356748'
unset BOOK_ANALYSIS_ID_TOKEN BOOK_ANALYSIS_APP_CHECK_TOKEN
```

iOS 토큰으로 영어 계약을 별도 검사한다.

```bash
export BOOK_ANALYSIS_ID_TOKEN='<iOS test account ID token>'
export BOOK_ANALYSIS_APP_CHECK_TOKEN='<iOS App Check token>'
python functions/analyze_korean_text/smoke_test.py '<deployed URL>' en \
  --expected-app-id='1:573567222361:ios:0f8c0734410bb6cc356748'
unset BOOK_ANALYSIS_ID_TOKEN BOOK_ANALYSIS_APP_CHECK_TOKEN
```

각 실행은 다음을 독립 검증한다.

- Auth+App Check 정상: 200, `analysisLanguage` 요청값 일치
- App Check JWT `sub`가 지정한 Android/iOS Firebase App ID와 일치
- 독일어 명사 `Nomen`, 영어 명사 `Noun`, 번역 1개 이상
- 유효 Auth만: 401
- 유효 App Check만: 401
- 유효 Auth+변조 App Check: 401
- KO+Latin+Arabic 정제, Arabic/bidi 응답 0건, 한글 없음·길이 제한

성공 분석 요청만 서버 할당량을 소비한다. 401 요청은 분석·번역·할당량 처리 전에
종료돼야 한다.

배포 URL은 다음처럼 값 하나만 확인한다.

```bash
gcloud functions describe analyze_korean_text \
  --project='ko-lernen-app' --region='europe-west3' --gen2 \
  --format='value(serviceConfig.uri)'
```

## 8. Rules/TTL 활성화와 기존 캐시 정리

별도 운영 승인 아래 rules와 indexes를 배포한다.

```bash
firebase deploy --only firestore:rules,firestore:indexes \
  --project='ko-lernen-app'
gcloud firestore fields ttls list \
  --project='ko-lernen-app' \
  --collection-group='translation_cache'
```

`translation_cache.expiresAt` 상태가 ACTIVE이고 새 함수의 source SHA·양 플랫폼
smoke가 모두 통과한 뒤에만 기존 cache dry-run을 다시 수행한다. Jin이 데이터
삭제를 명시적으로 승인한 경우에만 다음 명령을 수동 실행한다.

```bash
python functions/analyze_korean_text/cleanup_translation_cache.py \
  --project='ko-lernen-app' --use-gcloud-credentials --apply
```

이 명령은 구버전 또는 `src` 포함 문서만 batch delete하고 값은 출력하지 않는다.
승인 없이 `--apply`를 실행하지 않는다. 완료 후 dry-run 결과가 `matched=0`인지 다시
확인한다. Firestore TTL 삭제는 즉시성을 보장하지 않으므로 ACTIVE 상태와 후속
관측을 별도로 기록한다.

## 9. 실기기 완료 게이트

Android와 iOS에서 실제 KO+DE, KO+EN 교재를 각각 촬영해 사진→OCR 교정→분석→
저장까지 확인한다. 단일/2단/3단, 0/90/180/270도, 흐림·저대비·반사·원근,
confidence가 없는 iOS 결과를 포함한다. 다음이 모두 참이어야 한다.

- Arabic/bidi가 결과·TTS·저장 데이터에 없음
- 유효 콘텐츠 없는 결과에는 저장 동작이 없음
- DE/EN 번역과 `analysisLanguage`가 일치
- 관형형 양성/음성 문법 예문이 중복 없이 정확
- source SHA PASS, signed smoke 양 플랫폼 PASS
- 기존 캐시 `src` 0건, TTL ACTIVE

로컬/에뮬레이터 결과를 실기기나 운영 성공으로 대신 기록하지 않는다.

## 10. 별도 함수 경계

`functions/gye`, `functions/tts`, `functions/pronunciation`은 Firebase의 별도 Node
codebase다. 이 런북의 `gcloud functions deploy analyze_korean_text`와 함께
묶어 배포하지 않는다. 해당 운영 절차는 `closed-testing-checklist-v2.md`와 각
함수 디렉터리의 테스트/런북을 따른다.
