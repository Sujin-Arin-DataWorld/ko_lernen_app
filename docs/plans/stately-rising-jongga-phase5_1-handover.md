# Phase 5.1 Handover — stately-rising-jongga (Closed Testing 준비)

> **세션**: 2026-06-01 · Claude
> **상위 plan**: `docs/plans/stately-rising-jongga.md` §6.5 (책 한 컷)
> **상태**: 코드 작성 완료 — Jin 로컬 검증 + Cloud Function 배포 + 실기기 점검 후 Closed Testing 가능

---

## 1. 변경 요약 (TL;DR)

Phase 5.1 은 책 한 컷의 사용자 흐름을 완성 — 캡쳐 → 분석 → **저장** → **목록** → **상세** →
**커스텀 팩 생성** → **연습**. Closed Testing 출시 준비 완료.

| 영역 | 파일 | 변경 |
|---|---|---|
| 모델 | `lib/models/custom_pack.dart` | 신규 — CustomPack DTO + fromBookPage factory |
| 서비스 | `lib/services/custom_pack_service.dart` | 신규 — CRUD + cp_ 시간기반 ID |
| 서비스 | `lib/services/storage_service.dart` | + `customPacksRawJson` + `bookAnalysisEndpoint` getter/setter (2 신규 키) |
| 화면 | `lib/screens/bookshelf_screen.dart` | 신규 — 2 섹션 (Pages + Custom Packs) + 빈 상태 + +CTA |
| 화면 | `lib/screens/bookshelf_page_screen.dart` | 신규 — 페이지 상세 + 단어/문법/문장 카드 + Create Pack/Delete |
| 화면 | `lib/screens/custom_pack_play_screen.dart` | 신규 — FlipCard 학습 + 결과 화면 |
| 화면 | `lib/screens/book_result_screen.dart` | + Save 후 "Create Custom Pack" CTA + 다이얼로그 |
| 라우트 | `lib/main.dart` | + `/bookshelf`, `/bookshelf/page`, `/custom_pack/play` |
| 라우트 | `lib/main.dart` | + 부팅 시 `BookAnalysisService.setEndpoint(Storage.bookAnalysisEndpoint)` |
| l10n | DE/EN ARB + generated | + 35 키 (bookshelf / customPack / endpoint) + btnPlay/btnDelete |
| 테스트 | `test/custom_pack_test.dart` | 신규 — JSON 라운드트립, CRUD, generateId, endpoint trim (10 케이스) |

---

## 2. 완성된 사용자 흐름 (사실 — 라우트 검증됨)

```
/                  → 홈 (Phase 6에서 진입로 카드 추가 예정)
↓
/book              BookCaptureScreen (Phase 5)
                   ├─ 카메라 / 갤러리 → permission → cropper → ML Kit OCR
                   └─ pushNamed /book/preview {text, blockCount, imagePath}

/book/preview      BookPreviewScreen (Phase 5)
                   └─ pushReplacement /book/result {text, imagePath}

/book/result       BookResultScreen (Phase 5 + 5.1 wire)
                   ├─ Cloud Function 분석 또는 offline stub
                   ├─ "Save" → bookshelf 저장
                   └─ Phase 5.1: "Create Custom Pack" CTA
                       └─ 이름 입력 → CustomPackService.createFromPage
                                  → /custom_pack/play 푸시

/bookshelf         BookshelfScreen (Phase 5.1 신규)
                   ├─ 섹션 1: Custom Packs (CustomPackService.getAll)
                   ├─ 섹션 2: Saved Pages (BookshelfService.getAllLocal)
                   ├─ AppBar +Add 버튼 → /book
                   └─ 빈 상태: SoriEmptyState + "Snap a page" CTA

/bookshelf/page    BookshelfPageScreen (Phase 5.1 신규)
                   args: pageId
                   ├─ 원문 + 단어 + 문법 + 문장 모두 표시
                   ├─ "Create Custom Pack" CTA → 다이얼로그 → CustomPack 생성
                   └─ Delete 버튼

/custom_pack/play  CustomPackPlayScreen (Phase 5.1 신규)
                   args: packId
                   ├─ FlipCard 단어 순회 (앞: 한국어/TTS, 뒤: DE/예문)
                   ├─ "Got it" → Storage.addVokSeen
                   └─ 끝나면 결과 화면 (다시/돌아가기)
```

---

## 3. 데이터 모델

### 3.1 Storage 신규 키 (2개)

- `kl_custom_packs_v1` — JSON Map<packId, CustomPack.toJson()>
- `kl_book_analysis_endpoint` — Cloud Function URL (Settings 에서 설정)

### 3.2 CustomPack JSON (사실)

```json
{
  "name": "Schritte 1 — Lektion 5",
  "sourcePageId": "p_xyz_abcd",
  "words": [
    {
      "korean": "공부",
      "romanization": "gongbu",
      "posDe": "Nomen",
      "translationDe": "Studium",
      "translationEn": "study",
      "exampleKorean": "한국어 공부 중",
      "exampleDe": "Mitten im Koreanisch-Lernen",
      "savedToPackId": null
    }
  ],
  "createdAt": "2026-05-31T12:00:00.000Z"
}
```

### 3.3 Firestore 영향

**Phase 5.1 에서는 추가 안 함**. CustomPack 은 v1 로컬 only.
v1.1 추가 검토: `users/{uid}/custom_packs/{packId}` (Phase 1 firestore.rules 가 이미 cover).

---

## 4. Closed Testing 출시 체크리스트

Jin 마무리:

### 4.1 코드 (이번 세션 완료) — 검증만
```bash
flutter pub get
flutter gen-l10n
flutter analyze
# 기대: 0 errors, 0 info (또는 chosung known issue 1 info)

flutter test test/custom_pack_test.dart   # 10 케이스
flutter test                              # 전체 ~205+ 케이스
```

### 4.2 인프라 (Jin 영역)

- [ ] **마스코트 백업 복원** (이미 직전 세션 완료, 확인만)
  ```bash
  cp -r assets/illustrations/.backup_uncompressed/mascot/*.png assets/illustrations/mascot/
  ls -la assets/illustrations/mascot/tiger_celebrate.png   # ~1.9MB 기대
  ```
- [ ] **CSV 백업 삭제** (이미 완료, 확인만)
- [ ] **Firestore rules 배포**
  ```bash
  firebase deploy --only firestore:rules
  ```
- [ ] **Cloud Function 배포** (선택 — 없어도 stub 으로 동작)
  ```bash
  firebase functions:config:set deepl.api_key="..."
  cd functions/
  firebase deploy --only functions:analyze_korean_text
  ```
  배포 후 endpoint URL 을 앱 Settings 에서 입력 (Phase 5.1 미구현 — v1.1 후보. 임시: 코드에서 `BookAnalysisService.setEndpoint(...)` 호출)

### 4.3 실기기 검증 (Jin SIM unlock 후)
```bash
flutter run -d 9053622f
```

핵심 시나리오:
1. 홈 → 메뉴 (현재는 URL 또는 settings 임시 진입) → /book
2. 사진 찍기 → OCR → 텍스트 수정 → 분석
3. 결과 보기 → "Save to bookshelf"
4. 결과 화면에서 "Create Custom Pack" → 이름 입력 → 자동 play 화면 진입
5. FlipCard 학습 → 결과 화면 → /bookshelf 으로 돌아가기
6. /bookshelf → 저장된 페이지 + 커스텀 팩 둘 다 보임
7. 페이지 상세 진입 → Delete 동작
8. 커스텀 팩 다시 play 동작

### 4.4 출시 자료 (Phase 8 이지만 Closed Testing 에는 일부 필요)

- [ ] **Privacy Policy 업데이트** (`docs/privacy.html`):
  - 카메라 권한 사용 명시
  - DeepL EU 외부 데이터 처리
  - 사진은 기기에만 저장, 텍스트만 서버 전송
- [ ] **Data Safety 업데이트** (`docs/store/data-safety.md`):
  - Camera, Photos & Videos 권한 추가
  - "Optional, app functionality, only extracted text shared"
- [ ] **Release Notes**: "v2.0-alpha Closed Testing — 책 한 컷 (Snap-and-Learn), 한옥 단계, 17 특별 퀘스트, 단어 팩 시스템"
- [ ] **스크린샷**: bookshelf, 단어 카드, 한옥 cinematic, 팩 그리드 (8슬롯)

### 4.5 Play Console Closed Testing

- [ ] AAB 빌드 + 업로드
  ```bash
  flutter build appbundle --release --obfuscate \
    --split-debug-info=build/app/outputs/symbols
  ```
- [ ] Tester 이메일 5~10명 추가
- [ ] Internal track 부터 (즉시 가용) → Closed Testing (지연 적음)

---

## 5. Phase 5.1 범위 — 했음 / 안했음

**했음**:
- CustomPack 모델 + Storage + CRUD 서비스
- 책장 목록 (2 섹션) + 페이지 상세 + 커스텀 팩 학습 (총 3 신규 화면)
- 결과 화면 → 커스텀 팩 생성 wire-up
- 35 신규 l10n 키 (DE/EN)
- 10 신규 테스트
- 부팅 시 endpoint 복원

**안했음 (v1.1 후보)**:
- **홈 진입로 카드 4개** — `homeBookCardTitle/Desc`, `homeBookshelfCardTitle/Desc`, `homeQuestsCardTitle/Desc` l10n 키만 준비. 홈 화면에 카드 추가는 다음 세션.
- **Settings 의 Cloud Endpoint UI** — `settingsBookEndpointSection/...` 키만 준비. Settings 화면에 섹션 추가는 다음 세션. 임시 우회: `Storage.setBookAnalysisEndpoint(...)` 직접 호출 또는 디버그 진입점.
- 커스텀 팩 Firestore 동기 (v1.1)
- 단어별 "팩에 추가" 멀티셀렉트 (현재는 페이지 단위 일괄 변환)
- 단어→일반 vocab pack 으로의 직접 매핑

---

## 6. 다음 단계

옵션 A (Closed Testing 직행, 추천):
- 위 4.4·4.5 출시 자료 + AAB 빌드만 마무리
- 5~10명 tester 추가
- 1~2주 운영 → 피드백

옵션 B (Phase 5.2 — 홈/Settings 진입로 완성):
- 홈 카드 4개 + Settings endpoint UI 추가 (1일)
- 그 후 Closed Testing

옵션 C (Phase 6 — 계 시스템):
- Closed Testing 병행하면서 계 데이터 모델 시작
- Plan §7 (Phase 6) 진행

---

## 7. 신뢰 가능한 사실 vs 가정

### 검증됨 (사실)
- 라우트 등록 + screen import — main.dart 확인
- CustomPack JSON 라운드트립 — 테스트
- Storage 신규 키 (kl_custom_packs_v1, kl_book_analysis_endpoint) — `kl_` prefix 일관
- 부팅 시 endpoint 복원 — `BookAnalysisService.setEndpoint(Storage.bookAnalysisEndpoint)`

### 가정 (Jin 검증 필요)
- `flutter analyze` 0 errors — 샌드박스 미실행
- `flutter test` ~205+ 통과
- image_picker / image_cropper 실기기 권한 흐름 (특히 MIUI/Redmi 변종)
- TTS 한국어 발음 자연스러움
- 책장 빈 상태 → 비CTA 흐름

---

## 8. 변경 파일 목록

```
신규:
  docs/plans/stately-rising-jongga-phase5_1-handover.md
  lib/models/custom_pack.dart
  lib/services/custom_pack_service.dart
  lib/screens/bookshelf_screen.dart
  lib/screens/bookshelf_page_screen.dart
  lib/screens/custom_pack_play_screen.dart
  test/custom_pack_test.dart

수정:
  lib/main.dart                                   (+3 routes + endpoint init + import)
  lib/services/storage_service.dart               (+ customPacksRawJson + bookAnalysisEndpoint)
  lib/screens/book_result_screen.dart             (+ Create Custom Pack CTA + dialog)
  lib/l10n/app_de.arb                             (+35 keys)
  lib/l10n/app_en.arb                             (+35 keys)
  lib/l10n/generated/app_localizations.dart       (+ abstract method signatures)
  lib/l10n/generated/app_localizations_de.dart    (+ DE impl)
  lib/l10n/generated/app_localizations_en.dart    (+ EN impl)
```

---

**작성**: Claude
**검토 대기**: Jin
**커밋 권한**: Jin 명시 요청 시
