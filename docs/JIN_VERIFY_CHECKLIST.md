# ⚠️ ARCHIVED — Jin 검증 체크리스트 (2026-06-02)

> **상태**: v2.0.0 내부 테스트용 체크리스트. 출시 후 갱신됨.  
> **현행 기준**: `docs/store/closed-testing-checklist-v2.md` 참조
>
> 작성: 2026-06-02 · v2.0 내부 테스트 직전
> 이 목록은 **이 세션(코드/이미지 작업)에서 할 수 없고, Jin의 로컬 PC·실기기·Firebase/Play Console에서만 가능한 것**만 모았습니다.
> 이미 끝낸 코드/이미지 작업은 §0 참고.

---

## 0. 이 세션에서 끝낸 것 (참고)
- ✅ 압축 이미지 48장 교체/추가 (`종가이미지 압축` → 앱 에셋). 새로 추가: `stage_beams_light.png`(beams 단계), `mascot/tiger_idle2.png`(미사용), `stickers/hangul_hh.png`.
- ✅ **다크모드 비활성화** — `main.dart` themeMode=light 고정 + darkTheme를 light로 미러 + Settings 테마 선택 UI 제거 + 미사용 import 정리.
- ✅ 카페 시나리오 독일어 문법 설명 오류 수정 + "americano→Iced Americano" 수정 (`scenarios.json`).
- ✅ 영어 스토어 리스팅 "Anlaut Quiz" → "Initial-Consonant Quiz".

---

## 1. 빌드 검증 (로컬 PC) — 🔴 필수
이 세션은 Flutter가 없어 빌드를 못 돌렸습니다. **내 변경 직후 반드시 1회 실행:**
```bash
cd ~/Developer/ko_lernen_app
flutter clean && flutter pub get && flutter gen-l10n
flutter analyze     # 기대: 0 errors (초성 known info 1건만 허용)
flutter test        # 기대: 직전 197건 수준 통과
```
- [x] **(2026-06-02) 빌드 통과 확인됨** — Jin: "전부 문제없이 빌드됐어".
- [ ] ⚠️ **그 이후 추가된 Dart 변경**(`definitionKo` + **"나만의 단어장"** 화면/모델/서비스 + **홈카드·CSV가져오기·사진첨부** + `path_provider` 의존성)이 있어 **반드시 `flutter pub get` → `flutter gen-l10n` → `flutter analyze` → `flutter test` 순서로 1회**. 신규 l10n 키는 생성 파일이 stale이라 gen-l10n 전엔 analyze 실패가 정상.
- [ ] `scenarios.json` 앱 로드 정상 (JSON 파싱은 이 세션에서 확인 완료, 화면 표시는 디바이스에서).
- 버전: `pubspec.yaml` 이미 `2.0.0+3` 으로 bump 완료 (이 세션).

---

## 2. 실기기 시각 검증 (Android 1대) — 🔴 필수 (지금까지 0회)
모든 핸드오버 문서가 "실기기 검증 미완"이라 명시. **내부 테스트의 1차 목적.**

### 2.1 다크모드 제거 확인
- [ ] 폰을 **다크모드로** 설정한 상태에서 앱 실행 → 앱이 **여전히 라이트(한지 cream)** 로 보이는지.
- [ ] 설정 화면에 "테마/Erscheinungsbild" 선택 항목이 **사라졌는지** + 다른 항목 정상.

### 2.2 교체/추가 이미지 렌더 확인
- [ ] 한옥 단계 배경 10종(빈터→창호) 표시 — 특히 **새 beams(대들보) 단계**가 인접 단계와 구도·정렬 어울리는지 (이 파일은 `.en` 변형 선택함).
- [ ] 마스코트: 호랑이 idle/blink/happy, 까치 wingup/wingdown 정상. (`tiger_idle2`는 코드 미연결 — 안 보여도 정상.)
- [ ] 장식(decorations) 10종, 도장(stamps) 6종, 스티커 11종, 솟을대문 gate 이미지 정상.
- [ ] 시나리오 backdrop(scenes) 정상.

### 2.3 핵심 흐름
- [ ] 온보딩(솟을대문 인트로 → A1 선택 → 홈).
- [ ] 홈 신규 카드 3개(책 한 컷 / 책장 / 퀘스트) 노출·진입.
- [ ] 단어팩: `/vocab` 첫 팩만 열림 → 학습→퀴즈→보스→70%→도장→다음 팩 잠금해제.
- [ ] 한옥 시네마틱: 단계 전환 시 토스트/연출 1회.
- [ ] **책 한 컷 (📷 플래그십)**: 카메라 권한 → 사진 → 자르기 → OCR → 분석 → 결과 → 저장 → 커스텀 팩 생성·학습.
- [ ] **나만의 단어장 (신규)**: 책장 → ＋(나만의 단어장) → 이름 → 편집 화면 → 단어 추가(한국어+뜻+예문) → "자동 채우기"(Cloud Function 배포 시 번역·뜻풀이 채워짐, 미배포 시 "직접 입력" 안내) → TTS 발음 → "카드 학습" + "퀴즈(4단어↑ 4지선다)" → 단어 편집·삭제·단어장 이름변경. 기존 커스텀팩 타일의 ✏️ 편집 아이콘도 확인.
- [ ] **나만의 단어장 — 홈 진입**: 홈 모듈 그리드에 "나만의 단어장" 카드(퀘스트 옆) → 책장 열림.
- [ ] **나만의 단어장 — CSV 가져오기**: 편집 화면 우상단 📤 → CSV 붙여넣기(`한국어,뜻,예문` 줄단위) → "가져오기" → N개 추가 SnackBar.
- [ ] **나만의 단어장 — 사진 첨부**: 단어 추가/편집 시트에서 카메라/갤러리 → 권한 → 썸네일 표시 → 저장 후 목록 타일·플립카드 앞면에 사진 보임. 사진 삭제도 확인. (앱 재시작 후에도 사진 유지 = 앱 문서 폴더 영구 저장)
- [ ] **암기 엔진 A1**: 커스텀/사진 단어를 카드/퀴즈/받아쓰기로 학습 → 홈 "오늘의 복습" 개수에 반영되고, 다음날 복습에 그 단어가 섞여 나옴.
- [ ] **암기 엔진 A2**: 같은 단어를 여러 번 틀리면 홈에 "어려운 단어" 카드 등장 → 탭 → 목록 + "집중 복습" 동작.
- [ ] **암기 엔진 A3**: 편집 화면 4모드(카드·짝맞추기·받아쓰기·퀴즈) 모두 진입·동작. 받아쓰기 정답/오답 채점, 짝맞추기 매칭, 퀴즈에 사진 노출 확인.
- [ ] 계정 삭제: 설정 → 계정 삭제 → 2단계 확인 → 재로그인(익명) 정상.
- [ ] 회귀: 한글/문법/워들/초성/끝말잇기/통계/설정(TTS·언어·백업) 정상.

---

## 3. Firebase 배포 — 🔴/🟠
- [ ] **Firestore 규칙 배포** (필수): `firebase deploy --only firestore:rules`
- [ ] **Cloud Function 배포** (강력 권장 — 안 하면 책 한 컷이 번역·단어추출·정의 없이 문법패턴만):
  - ✅ **API 키는 이미 코드에 반영됨** — `functions/analyze_korean_text/.env` 에 `DEEPL_API_KEY`(:fx Free) + `URIMALSAEM_API_KEY` 저장. `.gitignore` 처리되어 GitHub에 안 올라감. Firebase가 deploy 시 `.env`를 런타임 환경변수로 자동 로드.
  - 배포: `firebase deploy --only functions` (`firebase.json`의 functions.source = `functions/analyze_korean_text` 확인됨)
  - 출력된 함수 URL을 앱 **설정 → "Cloud-Analyse-Endpoint"** 에 붙여넣고 저장 → 재실행 후 유지 확인.
  - ⚠️ **우리말샘 키는 이 세션 네트워크 제한으로 실호출 검증 못 함**(403 터널). 배포 후 실제 페이지 분석 시 단어 카드에 "📖 뜻풀이"가 나오는지로 확인.
- [ ] 배포 후 책 한 컷으로 실제 한국어 페이지 분석 → 단어/번역(DeepL)/정의(우리말샘) 나오는지.
- [ ] DeepL Free 한도(50만 자/월) 모니터링 — 테스터 많아지면 Pro 검토.
- [ ] (출시 후) Crashlytics·Analytics 콘솔에 release 빌드 데이터 수신 확인.

---

## 4. AAB 빌드 & 버전 — 🔴
- [x] `pubspec.yaml` 버전 `2.0.0+3` 으로 bump 완료 (이 세션). — `2.0.0`=사용자에게 보이는 버전명, `+3`=Play Console 빌드 번호(매 업로드마다 +1 증가 필수, 이전 업로드 +2였음).
- [ ] ```flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols```
- [ ] AAB 크기 확인 (`ls -lh .../app-release.aab`, <100MB). 이미지 추가됐지만 모두 압축본이라 큰 증가 없을 것.
- [ ] native debug symbols(`build/app/outputs/symbols/`) 확보 → Play Console 업로드용.

---

## 5. Play Console (내부/Closed Testing) — 🔴
- [ ] Privacy URL: `https://hangul-sori.com/privacy.html`
- [ ] Data Safety: `docs/store/data-safety.md` 표 그대로 (카메라·DeepL 반영본).
- [ ] 콘텐츠 등급 IARC 13+, 타겟 연령 13+ (3개 체크), 카테고리 Education, 연락처 `hello@hangul-sori.com`.
- [ ] **Feature graphic 1024×500 업로드** (아직 미제작 — `docs/IMAGES_TO_CREATE.md` P1 참고).
- [ ] 스크린샷 8장 (실기기 캡처).
- [ ] **릴리스 노트: v2.0 사용** (`docs/store/release-notes-v2.md`). ⚠️ `listing-de.md`/`listing-en.md`의 "Was ist neu / What's new"가 아직 "v1.0"으로 적혀 있으니 게시 전 v2.0으로 교체.
- [ ] AAB + symbols 업로드 → 테스터 5~10명 초대 (`closed-testing-checklist-v2.md` §6.3 템플릿).

---

## 6. 게시 전 마지막 점검
- [ ] DE/EN 남은 nice-to-fix(선택): "Custom-Pack↔Eigene Packs" 용어 통일, "geklärt→geschafft", 따옴표 스타일. (출시 차단 아님)
- [ ] 웹사이트 v2.0 메시지·스크린샷·스토어 링크 갱신 (별도 작업).
