# Phase 5 Handover — stately-rising-jongga

> ✅ **실행완료 — 코드 구현 완료** (2026-06-03 아카이브)
> 책 한 컷 클라이언트(OCR·분석 클라·UI)는 끝났고 `lib/`에 반영·검증됨 (`flutter analyze` 0 · `flutter test` 218 통과).
> ⚠️ **Cloud Function 미배포** → 현재 번역·단어추출 비작동(문법패턴 stub만). 배포는 → [`../IMPROVEMENT_PLAN_2026-06-03.md`](../IMPROVEMENT_PLAN_2026-06-03.md) TRACK 0.2 (P0).

> **세션**: 2026-06-01 · Claude
> **상위 plan**: `docs/plans/stately-rising-jongga.md` §6.5 (책 한 컷)
> **상태**: 코드 작성 완료 — Jin 로컬 검증 + Cloud Function 배포 대기

---

## 1. 변경 요약 (TL;DR)

Phase 5 는 사용자가 한국어 교재 페이지를 **사진 찍어서** 단어/문법/예문/번역을
자동 추출하는 "**책 한 컷**" 기능. ML Kit on-device OCR + Cloud Function
OKT/DeepL + 로컬 fallback.

| 영역 | 파일 | 변경 |
|---|---|---|
| 의존성 | `pubspec.yaml` | + google_mlkit_text_recognition, image_picker, image_cropper, permission_handler, http |
| 권한 | `android/app/src/main/AndroidManifest.xml` | + CAMERA + READ_MEDIA_IMAGES + READ_EXTERNAL_STORAGE(≤32) |
| 권한 | `ios/Runner/Info.plist` | + NSCameraUsageDescription + NSPhotoLibraryUsageDescription |
| 모델 | `lib/models/book_page.dart` | 신규 — ExtractedWord / GrammarHit / TranslatedSentence / BookPage / BookAnalysisResult |
| 서비스 | `lib/services/snap_ocr_service.dart` | 신규 — ML Kit Korean OCR wrapper, recognizer auto-close |
| 서비스 | `lib/services/book_analysis_service.dart` | 신규 — Cloud Function HTTP 클라이언트 + 로컬 stub fallback (12s timeout) |
| 서비스 | `lib/services/bookshelf_service.dart` | 신규 — local SoT + Firestore best-effort, ID 생성기 |
| 서비스 | `lib/services/storage_service.dart` | + `bookshelfRawJson`, `bookSnapCountToday / inc / kBookSnapDailyLimit / quotaReached` (3 신규 키) |
| 화면 | `lib/screens/book_capture_screen.dart` | 신규 — 카메라/갤러리 → permission → image_cropper → OCR → preview push |
| 화면 | `lib/screens/book_preview_screen.dart` | 신규 — OCR 결과 사용자 편집 textarea + Analyze CTA |
| 화면 | `lib/screens/book_result_screen.dart` | 신규 — 단어 카드(TTS) + 문법 카드 + 문장 카드 + Save to bookshelf |
| 라우트 | `lib/main.dart` | + `/book`, `/book/preview`, `/book/result` (3 라우트) |
| 자산 | `assets/data/grammar_patterns.json` | 신규 — 31 패턴 (-고 있다, -아/어서, -(으)ㄹ 거예요 등 A1~B1) |
| Cloud | `functions/analyze_korean_text/main.py` | 신규 — OKT + DeepL + 패턴 서버측. Jin 배포. |
| Cloud | `functions/analyze_korean_text/requirements.txt` | konlpy, JPype1, deepl, functions-framework, flask |
| Cloud | `functions/analyze_korean_text/grammar_patterns.json` | 동일 사본 (서버 측 사용) |
| l10n | DE/EN ARB + generated | + 28 키 (capture / preview / result 카피) |
| 테스트 | `test/grammar_patterns_test.dart` | 신규 — 31개 무결성 + 8 semantic spot-check |
| 테스트 | `test/book_page_test.dart` | 신규 — JSON round-trip + Bookshelf CRUD + quota |

---

## 2. 사용자 흐름 (사실 — 라우트와 args 검증됨)

```
/book               BookCaptureScreen
                    ├─ 카메라 / 갤러리 선택
                    ├─ permission_handler (CAMERA / PHOTOS)
                    ├─ image_picker (max 2400×2400, q=85)
                    ├─ image_cropper (free aspect, KR/DE 타이틀)
                    ├─ SnapOcrService.recognizeKorean (ML Kit on-device)
                    └─ push → /book/preview { text, blockCount, imagePath }

/book/preview       BookPreviewScreen
                    ├─ Multi-line TextField — 사용자 수정 가능
                    ├─ "Analysieren" → pushReplacement → /book/result
                    └─ "Neu aufnehmen" → maybePop

/book/result        BookResultScreen
                    ├─ BookAnalysisService.analyze(text)
                    │   ├─ POST endpoint (12s timeout)
                    │   └─ Fallback: local grammar regex stub
                    ├─ Quota: 성공한 Cloud 호출만 카운트 (DeepL 보호)
                    ├─ 단어/문법/문장 카드 표시 + TTS replay
                    └─ "Save" → BookshelfService.save → Firestore best-effort
```

---

## 3. Privacy 모델 (사실 — 코드 검증)

| 데이터 | 어디 머무는가 |
|---|---|
| **사진 파일** | 기기 로컬만 (`image_picker` 임시 경로). 서버 전송 X. |
| **OCR 결과 텍스트** | 사용자 미수정 시 Cloud Function 으로 POST. DeepL 으로 추가 전송. |
| **추출 단어/문법** | Firestore `users/{uid}/bookshelf/{pageId}` (Phase 1 rules 가 cover) |
| **로컬 thumbnail path** | Firestore 에 의도적으로 미저장 (다른 기기에서 의미 없음) |

`book_page.dart::BookPage.toFirestoreJson()` 가 `localThumbnailPath` 제외 —
테스트로 lock.

**개인정보처리방침 업데이트 (Phase 8)**:
- 카메라 권한 사용 명시
- DeepL EU 외부 데이터 처리 동의
- 사진 미저장 / 텍스트만 처리 명시

---

## 4. Cloud Function 배포 가이드 (Jin)

### 4.1 사전 작업

```bash
# DeepL Free 키 발급 (https://www.deepl.com/pro-api)
firebase functions:config:set deepl.api_key="YOUR_KEY"

# (선택) NIKL 한국어 정의 enrichment
firebase functions:config:set nikl.api_key="..."
```

### 4.2 배포

```bash
cd functions/
firebase deploy --only functions:analyze_korean_text
```

배포 후 endpoint URL 메모. Flutter 쪽에서 호출:

```dart
// 예: lib/main.dart 또는 settings에서
BookAnalysisService.setEndpoint(
  'https://us-central1-ko-lernen-app.cloudfunctions.net/analyze_korean_text',
);
```

또는 Remote Config 키 `book_analysis_endpoint` → 동적 주입 패턴 (RemoteConfig
이미 설치되어 있음 — `palette_service.dart` 와 같은 패턴).

### 4.3 Cloud Function 미배포 상태 동작

`BookAnalysisService.endpoint == ''` → 즉시 로컬 stub 사용:
- 단어 추출 X (Cloud Function 의 OKT 없으면 불가)
- 문법 패턴 31개는 정상 작동 (Dart RegExp 동일 사전)
- 문장 분리 단순 punctuation/newline 기반
- 번역 X (DeepL 클라이언트 측에서 안 부름)
- UI 에 "Server nicht erreichbar — nur Grammatikmuster" 알림 표시

**즉, Cloud Function 없어도 기능은 동작** — 그저 단어 추출/번역만 빠진 상태.
Closed Testing 초기에는 Cloud 미배포로도 동작 검증 가능.

---

## 5. Jin 로컬 검증 명령어

```bash
flutter pub get
flutter gen-l10n
flutter analyze
# 기대: 0 errors (1 info chosung known issue 그대로)

flutter test test/grammar_patterns_test.dart   # 14 케이스
flutter test test/book_page_test.dart          # 11 케이스
flutter test   # 전체 (~195 케이스 기대 — Phase 1-5 누적)
```

실기기 (SIM unlock 후):
```bash
flutter run -d 9053622f
# 시나리오:
#   a) URL 또는 임시 진입점으로 /book → BookCaptureScreen
#   b) "Kamera" 탭 → permission 다이얼로그 (첫 회만) → 사진 찍기
#   c) 자르기 화면 → 영역 선택 → "DONE"
#   d) OCR 결과 텍스트 표시 (text editable)
#   e) "Analysieren" → Cloud Function 호출 또는 stub (offline notice 카드)
#   f) 단어/문법/문장 카드 → TTS replay 정상
#   g) "Save" → bookshelf 저장 → SnackBar
```

---

## 6. 알려진 한계 & 향후 작업

### 6.1 Phase 5 범위 — 했음 / 안했음

**했음**:
- 5 신규 의존성 + Android/iOS 권한 + manifest 주석
- 5 신규 모델 + 3 신규 서비스
- 3 신규 화면 (capture/preview/result) + 3 라우트
- 31 grammar pattern 사전 (Dart + Python 양쪽)
- Cloud Function skeleton (배포 명령 포함)
- 28 신규 l10n 키 (DE/EN)
- 25 단위 테스트 (패턴 무결성 + book page round-trip)

**안했음 (Phase 5.1 후보)**:
- `/bookshelf` 목록 화면 — 저장된 페이지 list view
- `/bookshelf/page/{id}` 상세 화면 — 저장 page 다시 보기
- 단어 → 커스텀 팩 변환 (커스텀 팩 생성 UX)
- Cloud Function 의 NIKL enrichment 통합
- 발음 평가 (Phase 4 의 `q_seokdeung` 트리거)
- 홈 화면 진입점 (`/book` 카드 추가)
- Settings 의 endpoint 설정 UI

### 6.2 PNG 자산 — 코드는 fallback 동작

Phase 5 의 expected PNGs:
- `book_empty_shelf.png` — bookshelf 빈 상태 (Phase 5.1)
- `book_camera_guide.png` — 카메라 가이드 일러스트
- `book_analyzing.png` — 분석 중 시네마틱
- `book_success.png` — 단어 추출 축하
- `book_error.png` — 분석 실패

코드는 기존 Mascot widget 사용 (tiger/magpie 포즈) — PNG 들어와도 코드 변경
없이 일러스트로 교체 가능.

### 6.3 Cloud Function deploy 의존성

Closed Testing 출시 전:
- DeepL Free 키 확보
- `firebase deploy --only functions` 1회 실행
- endpoint URL 을 RemoteConfig 또는 코드에 박기

미배포 상태에서도 앱은 동작 (stub) — 다만 사용자가 "Server nicht erreichbar"
배너를 보게 됨. Beta 사용자에게는 OK, 출시는 권장 안 함.

### 6.4 DeepL 한도 관리 (사실)

- DeepL Free: 500k char/월
- 1 페이지 ≈ 30단어 + 10문장 ≈ 1500자 ≈ 0.3%/page
- 사용자당 1일 max 20장 (`Storage.kBookSnapDailyLimit`) → 30k자/일
- 100 DAU × 30일 → 9M자 → **DeepL Free 한도 초과** → Pro ($5.49/100만자) 필요

`Storage.bookSnapQuotaReached` 가 사용자 단위 한도 enforce. Closed Testing
(5~10명) 에서는 무관, Open 출시 시 Pro 전환 또는 캐시 적극 활용.

### 6.5 Hand-edited l10n vs gen-l10n

Phase 4 handover 후 Jin 이 `flutter gen-l10n` 1회 실행 → 내 hand-edit
generated 가 ARB 에서 재생성됨. 형태 동일 (idempotent), 단 헤더 주석은
빠짐. Phase 5 generated 도 동일 패턴 — Jin gen-l10n 후 깔끔히 정리됨.

---

## 7. 신뢰 가능한 사실 vs 가정

### 검증됨 (사실)
- 권한 manifest 정확 (Android 13+ READ_MEDIA_IMAGES + max-sdk fallback 패턴)
- 31 grammar pattern regex 모두 Dart RegExp 컴파일 통과 — 테스트
- Cloud Function fallback 흐름 — endpoint 빈 문자열 시 즉시 stub
- BookPage.toFirestoreJson 이 localThumbnailPath 제외 — 테스트
- Storage 신규 키 3개 모두 `kl_` prefix
- Phase 1 firestore.rules 가 `users/{uid}/{**}` 매칭 → `bookshelf/{pageId}` cover

### 가정 (Jin 검증 필요)
- `flutter pub get` 5 신규 dep 충돌 없음 — 가능성 낮음 (모두 안정 버전)
- ML Kit Korean OCR 정확도 — 실기기에서만 확인
- image_cropper의 Android↔iOS 동작 — 둘 다 사용 가능
- `flutter analyze` 0 errors
- `flutter test` ~195 통과
- DeepL Free 키 발급 + Cloud Function 배포 가능 (Firebase 권한)

### 의도적으로 미수행
- /bookshelf 목록·상세 화면 (Phase 5.1)
- 단어 → 커스텀 팩 생성 UX
- 홈 진입로
- Privacy policy update (Phase 8)
- Settings 의 Cloud endpoint 설정

---

## 8. 변경 파일 목록

```
신규:
  assets/data/grammar_patterns.json
  docs/plans/stately-rising-jongga-phase5-handover.md
  functions/analyze_korean_text/main.py
  functions/analyze_korean_text/grammar_patterns.json
  functions/analyze_korean_text/requirements.txt
  lib/models/book_page.dart
  lib/screens/book_capture_screen.dart
  lib/screens/book_preview_screen.dart
  lib/screens/book_result_screen.dart
  lib/services/book_analysis_service.dart
  lib/services/bookshelf_service.dart
  lib/services/snap_ocr_service.dart
  test/book_page_test.dart
  test/grammar_patterns_test.dart

수정:
  android/app/src/main/AndroidManifest.xml         (+ camera/photos)
  ios/Runner/Info.plist                            (+ NSCamera/NSPhotoLibrary)
  lib/main.dart                                    (+3 routes)
  lib/services/storage_service.dart                (+ bookshelf + quota)
  lib/l10n/app_de.arb                              (+28 keys)
  lib/l10n/app_en.arb                              (+28 keys)
  lib/l10n/generated/app_localizations.dart        (+ abstract method signatures)
  lib/l10n/generated/app_localizations_de.dart     (+ DE impl)
  lib/l10n/generated/app_localizations_en.dart     (+ EN impl)
  pubspec.yaml                                     (+5 dependencies)
```

---

## 9. 다음 단계 (Phase 5.1 → 6)

Phase 5 검증 끝나면 분기:

**Phase 5.1 (책 한 컷 완성 — 1주)**:
- /bookshelf 목록 + 상세 화면
- 단어 → custom pack 생성 흐름
- 홈 진입로 카드
- Closed Testing 1차 시작 가능

**Phase 6 (계 + 친구 — 3주)**:
- Gye 데이터 모델 + Firestore schema
- 모임방 UX + 주간 목표 + 스티커 (자유 텍스트 X)
- 모더레이션 + GDPR 16세 차단

Plan §7 (Phase 6) 그대로 진행.

Closed Testing 권장 시점:
- Phase 5.1 마무리 + 실기기 시각 검증 + Cloud Function 1회 배포 = **현 시점에서 1주 후**.

---

**작성**: Claude
**검토 대기**: Jin
**커밋 권한**: Jin 명시 요청 시
