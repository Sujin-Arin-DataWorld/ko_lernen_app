# Hangul Sori — 출시 준비도 진단 (2026-06-02)

> 작성: 2026-06-02 · 범위: 안드로이드 내부 테스터 모집 직전 전수 점검.
> 방법: 실제 파일·`flutter analyze` 출력 기준 (환각 정정 반영). 픽셀/시각 검증은 미포함 → Jin 실기기 필요.

## 0. 한 줄 결론

**안드로이드 내부 테스트를 거의 즉시 시작 가능.** 빌드 blocker 0, `flutter analyze` 0 issues, 서명키·Firebase·인앱 계정삭제 준비됨. 핵심 "사진→단어장" 백엔드(Cloud Function)는 코드 완성·**배포 대기**, 공유 기능은 신규 개발 중.

> ⚠️ 1차(2026-06-02 오전) 진단 정정: ① Cloud Function은 **konlpy/Java가 아니라 kiwipiepy(순수 Python)** — 배포 blocker 없음. ② **우리말샘(NIKL) 사전 연동 이미 구현됨**. ③ 버전은 **2.0.0+3**. ④ 홈/온보딩은 **v4 재설계 이미 반영**.

---

## 1. 영역별 상태

| 영역 | 상태 | 근거 |
|---|---|---|
| 빌드/릴리즈 | ✅ 준비됨 | `flutter analyze` 0 issues, `key.properties`+`upload-keystore.jks`, `google-services.json` package=`com.sujinarin.ko_lernen_app` 일치, AdMob 잔재 제거 |
| 버전 | `2.0.0+3` | `pubspec.yaml:4` |
| 앱 규모 | 화면 ~33, 서비스 ~22 | `lib/screens`, `lib/services` |
| 학습 콘텐츠 | 단어 526 · 문법 88 · 시나리오 21(A1·6/A2·7/B1·5/B2·3) · 단어팩 61 · 끝말잇기 225 | `assets/data/` |
| 게임 | Wordle·초성·끝말잇기·듣기 완성 | `quest_engines/` 6종 |
| 사진→단어장 | **백엔드 코드 완성·배포 대기** | `functions/analyze_korean_text/`, `book_*` |
| 공유 | ❌ 미구현 → 신규 개발 중 | `share_plus` 없음 |
| 로컬라이제이션 | DE/EN UI 각 474키, 누락 0 | `app_de.arb`/`app_en.arb` |
| 인앱 계정삭제 | ✅ 구현 (Play 정책 충족) | `settings_screen.dart` `_onDeleteAccount` |
| 수익화 | ❌ 미구현 (계획만) | `monetization-plan.md` |
| 웹사이트 | ★★★★☆ | `docs/index.html` (DE/EN/KO, 다크모드) |

---

## 2. 사진→단어장 ("책 한 컷") 흐름

**파이프라인** (전부 코드 완성):
사진/갤러리 → 자르기(`image_cropper`) → **on-device 한국어 OCR**(ML Kit) → 텍스트 수정 → **Cloud Function 분석** → 결과(단어·문법·문장 카드 + TTS) → 책장 저장 → 커스텀팩 생성 → 플립카드 학습.

**Cloud Function** `functions/analyze_korean_text/main.py`:
- 형태소 분석 = **kiwipiepy** (순수 Python, Java 불필요) → NNG/NNP/VV/VA 추출 (최대 30단어)
- 번역 = **DeepL** (`DEEPL_API_KEY`), 문장 단위 batch
- 국어 정의 = **우리말샘/NIKL** `opendict.korean.go.kr` (`URIMALSAEM_API_KEY`, best-effort, 최대 20개)
- 응답: `{words:[{korean,romanization,pos,translation,definitionKo,example,exampleTranslation}], grammar:[…], sentences:[…], warnings:[]}`
- endpoint 미설정/장애 시 → 클라이언트가 "오프라인 문법만" 폴백 (크래시 없음)

**남은 것**:
1. **Cloud Function 배포** (gcloud gen2 권장, region `europe-west3`) + 두 API 키 주입 — 인증 필요 = Jin
2. 배포 URL을 앱 기본 endpoint로 주입
3. `targetLang`이 앱 locale 따라가도록 보정 (현재 'de' 추정)
4. 로마자(`romanization`)는 항상 "" — 후속
5. 커스텀팩 Firestore 동기화 없음(로컬 only) — 기기 변경 시 소실 (후속)
6. **공유 기능** — 신규 개발 중 (친구코드 + OS공유)

---

## 3. 로컬라이제이션 (DE/EN)

- **독일어 ⭐⭐⭐⭐⭐** — UI + 학습 콘텐츠 모두 완비, 원어민 수준 캐주얼 "du".
- **영어: UI ⭐⭐⭐⭐⭐, 콘텐츠 ❌** — `korean_vocab.csv`(컬럼 `german`)·`grammar.csv`(`explanation_de`/`example_german`)에 **영어 컬럼 없음**. 영어 사용자는 단어 뜻·문법 설명을 **독일어로** 봄. (`moduleGrammarDesc`도 "German explanations" 명시.)
- → 1차 타깃이 독일어권이라 **내부 테스트엔 무방**. 영어권 출시 시 콘텐츠 영어화 필수. 그때까진 스토어 설명에 명시 권장.

---

## 4. 에셋 실측 (코드 cross-ref: 테스터에 깨진 이미지 0 — 전부 fallback)

| 카테고리 | 실제/spec | 미완 시 |
|---|---|---|
| hanok_stages light | 9/12 | beams·side_building·jongga → 그라데이션 폴백 |
| hanok_stages dark | 0/12 | 다크모드 홈 그라데이션 폴백 (살아있는 한옥 시각효과 손실) |
| decorations | 10/17 | 퀘스트 보상 시 초록 placeholder 7종 |
| stamps | 6/8 | 코드 미참조(CustomPainter) — 영향 0 |
| stickers | 11/30 | 코드 미참조 — 영향 0 |
| mascot(호랑이·까치) | 16/16 ✅ | — |
| scenes/empty/error | 5/3/2 ✅ | — |
| §6 gye_* · §7 book_* · §8 출시자료 | 0 | 코드 미참조 / 스토어용 |

가장 시각 임팩트 큰 후속: **hanok_stages dark 12장** (다크모드 홈이 한옥 그림 없이 그라데이션).

---

## 5. 웹사이트 (hangul-sori.com, `docs/`)

★★★★☆. 3개국어·다크모드·반응형·브랜드 일치, 참조 이미지 전부 존재.
출시 전 보완: ① Hero CTA `href="#"` → Play Store 링크, ② 스크린샷 placeholder → 실제 캡처, ③ v2.0 기능(Snap-and-Learn·한옥성장·61팩) 미반영, ④ OG 이미지 1200×630, ⑤ `privacy.html` 보라/금색 → 단청 팔레트 통일. (privacy.html은 2026-06-01자로 카메라/OCR/DeepL 반영 완료 = 법적 출시가능, account-deletion 링크도 존재.)

---

## 6. 출시 로드맵

### 🔴 P0 — 내부 테스트 업로드
대부분 완료(버전 bump, account-deletion 링크). 남은 건 운영:
```bash
flutter clean && flutter pub get && flutter gen-l10n
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
firebase deploy --only firestore:rules
# docs/privacy.html push → hangul-sori.com 반영 확인
```
→ Play Console 폼 입력(§7) → AAB + symbols 업로드.

### 🟡 P1 — 핵심 기능 작동
- Cloud Function 배포 + 두 키 주입 + 앱 endpoint 설정 (사진 기능 실작동)
- 공유 기능(친구코드+OS공유) 완성

### 🟢 P2 — 폴리시
- 홈 skill-path 레일, hanok_stages dark 12장, decorations 7장
- 커스텀팩 Firestore 동기화

### ⚪ P3 — 출시 후
- 수익화(구독), 영어 학습 콘텐츠, B2 시나리오 확충, 계(gye) 공동한옥, 한글 IoU

---

## 7. Play Console 입력값 (확정)

- **Privacy URL**: `https://hangul-sori.com/privacy.html`
- **Account deletion URL**: `https://hangul-sori.com/account-deletion.html`
- **App Access**: "All functionality available without special access" (익명 Firebase Auth)
- **Category**: Education · **Support email**: `hello@hangul-sori.com`
- **Content rating**: IARC 13+ · **Target audience**: 13–15 + 16–17 + 18+
- **Data Safety**:
  | 데이터 | 수집 | 선택 | 공유 | 암호화 |
  |---|---|---|---|---|
  | Email / Display name | Yes | Google opt-in | No | Yes |
  | Firebase UID | Yes | 자동 | No | Yes |
  | App activity (XP/Streak/Progress) | Yes | Cloud opt-in | No | Yes |
  | Analytics events | Yes | 자동 | No | Yes |
  | Crash logs / Diagnostics | Yes | 자동 | No | Yes |
  | Firebase Installation ID + Ad ID | Yes | 자동 | No | Yes |
  | **OCR 추출 한국어 텍스트** | Yes | Snap opt-in | **Yes (DeepL)** | Yes |
  | **카메라 사진** | No (기기에만) | — | — | — |
  - 판매: 없음 · 전송 중 암호화: Yes(TLS) · 삭제: 인앱 계정삭제 + 이메일

---

*상세 근거: `docs/store/data-safety.md`, `docs/store/closed-testing-checklist-v2.md`. 이 문서는 2026-06-02 전수 점검 스냅샷.*
