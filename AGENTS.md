# AGENTS.md — ko_lernen_app (Hangul Sori) · 모든 세션의 단일 진입점(SSoT)

> **⛔⛔ 어떤 AI 에이전트/환경(Codex · Claude Code · Cursor · Gemini 등)이든, 어떤 세션이든 시작 즉시 이 AGENTS.md를 가장 먼저 (상단 개요·파일맵·규칙 위주로) 읽고 시작한다 — 예외 없음.** 이 파일이 프로젝트의 유일한 단일 진실 원천이다. (구 `CLAUDE.md`·`memory/` 내용은 전부 이 파일로 통합됨. `CLAUDE.md`는 이 파일을 가리키는 포인터일 뿐.)
>
> **⛔ 필수 기록 규칙 (예외 없음):** 코드·데이터·에셋·설정·문서 등 무엇이든 하나라도 변경하면 반드시 `docs/SESSION_LOG.md` 최상단에 항목을 남긴다(무엇을·왜·검증·커밋해시). 기록 없이 변경만 커밋 금지. 로그 갱신은 같은/직후 커밋에 포함.
> **⛔ 커밋/푸시는 Jin이 명시적으로 요청할 때만.** 여러 AI 세션(Codex·Claude 등)이 동시에 돌 수 있으니 본인이 만진 파일만 골라 스테이징.
> **⛔ 개발 환경 = 단일 맥 (2026-08-13 확정).** 모든 개발이 맥 한 대로 통합됐다(Jin이 맥에서 Android 빌드도 가능함을 확인). 아래는 **전부 무효 — 어떤 세션도 이걸 전제로 대기/분담하지 말 것:**
> - ~~"Windows=UI/Android · Mac=데이터/iOS" 기계별 분담~~
> - ~~두 기계 동시 편집을 전제한 "ARB 충돌 최소화 규칙"~~ (기계가 한 대뿐이니 ARB 충돌 자체가 없다)
> - ~~"Windows에서 홈을 재디자인한 뒤 push" 흐름~~ — **Sori Stage가 현재 기본 홈 정본이다.** `79ae4a0c`가 feature gate와 레거시 `HomeScreen`/`WordleScreen`을 제거했으며, 캐릭터가 있는 5탭 Sori Stage 셸을 유지한다. UI/UX 개편 2의 구현 정본은 `docs/HANDOFF_UI_OVERHAUL_2_2026-08-14.md`이다.
> **⛔ 명령어 자율 실행 (승인 대기 생략):** `flutter`, `git`, `python`, `bash` 등 개발/검증에 필요한 모든 터미널 명령(`run_command`)은 **사용자에게 매번 질문하거나 확인 대기하지 않고 즉시 직접 실행**한다. (단, `git commit`/`push`는 Jin의 명시적 요청 시에만 수행)
>
---


> **⛔ 세션 시작 시 이 AGENTS.md(간결)를 읽고 시작한다 — 예외 없음.** 그 다음 필요한 파일만 grep/Read.
> 전역 운영 원칙은 `~/.claude/CLAUDE.md` 참조.
> **⛔ 필수 기록 규칙 (예외 없음):** 코드·데이터·에셋·설정 등 **무엇이든 하나라도 변경하면 반드시** `docs/SESSION_LOG.md`에 항목을 남긴다(무엇을·왜·검증·커밋해시). 커밋할 때 관련 로그 갱신을 **같은 커밋 또는 직후 커밋에 포함**. 기록 없이 변경만 커밋하는 것 금지. 프로젝트 밖 지속 사실은 `~/.claude/.../memory/`에도 남기고 MEMORY.md 인덱스에 한 줄 추가.
> **작업 완료 시마다** "현재 진행 중인 작업" 체크리스트를 업데이트할 것 (완료 항목 체크, 새 항목 추가).
> **비주얼 에셋 작업 전** `docs/ASSET_GENERATION_BIBLE.md` **하나만** 읽으면 됨 — 스타일 가이드·디자인 토큰·한옥/장식/도장/스티커/마스코트 프롬프트를 모두 흡수한 자급자족 AI 생성 바이블 (스타일명 **"Faceted Minhwa (모던 면 분할 민화)"**). 일러스트/아이콘/마케팅 자산 신규 제작·이터레이션 시 이 파일을 프롬프트 소스로 사용. (구 `HANGUL_SORI_STYLE_GUIDE.md`·`HANGUL_SORI_DESIGN_TOKENS.md`·`stately-rising-jongga-assets.md`는 상세 레퍼런스로만.)
> **마스코트(2026-06-02 v2)**: 업로드된 앉은 호랑이=`tiger_idle.png`, 갓 까치 비행 2프레임=`magpie_wingup/wingdown.png`가 캐릭터 source of truth. `tiger_sleepy`·`tiger_thinking`은 화풍 이질 → 교체 1순위. 상세는 BIBLE §2.

---

## 앱 개요

**Hangul Sori (한글소리)** — 독일어권 사용자를 위한 한국어 학습 Flutter 앱.
대상: 독일어 모국어 사용자 (UI 언어 독일어/영어, 학습 내용 한국어).
플랫폼: Android (주), iOS, Web (Chrome 개발 테스트).
Firebase 프로젝트: `ko-lernen-app`

---

## 기술 스택

- **Flutter** 3.x / Dart 3.x (null-safety)
- **Firebase**: Auth (익명 + Google 링크), Firestore (cloud sync), Remote Config (palette kill-switch)
- **로컬 저장**: `shared_preferences` (`StorageService`)
- **TTS**: `flutter_tts`
- **로컬라이제이션**: ARB (`l10n/`) — DE/EN 지원, `AppL10n.of(ctx)` 사용

---

## 설치된 GitHub 스킬 → 요청 라우팅 (2026-08-13)

전역 설치 위치 `~/.agents/skills` (확인: `npx skills ls -g` / 갱신: `npx skills update -g`).
**아래 상황에 해당하면 작업 전에 그 스킬을 먼저 호출한다.**

| 요청 / 상황 | 스킬 |
|---|---|
| 새 기능·설계 요구사항을 캐물어 다듬기 | `grill-me` (ADR·용어집까지 남길 땐 `grill-with-docs`) |
| 코드베이스 구조 개선점 스캔 | `improve-codebase-architecture` |
| 브랜치·PR·작업분 리뷰 (표준 vs 스펙 2축 병렬) | `code-review` |
| 세션 인수인계 문서 작성 | `handoff` |
| `flutter analyze` 경고 정리 · `dart fix` | `dart-run-static-analysis` |
| 런타임 에러·스택트레이스 수정 | `dart-fix-runtime-errors` |
| 순수 Dart 로직 유닛 테스트 | `dart-add-unit-test` |
| 커버리지(LCOV) 수집 | `dart-collect-coverage` |
| 위젯 테스트 추가 (`WidgetTester`) | `flutter-add-widget-test` |
| `integration_test` · 사용자 플로우 자동화 | `flutter-add-integration-test` |
| UI/Logic/Data 레이어 리팩터 | `flutter-apply-architecture-best-practices` |
| ARB·l10n 설정 (DE/EN) | `flutter-setup-localization` |
| 반응형 레이아웃 (폰·태블릿·폴더블) | `flutter-build-responsive-layout` |
| RenderFlex overflow · unbounded 제약 | `flutter-fix-layout-issues` |
| `firestore.rules`·Storage rules 감사 | `firebase-security-rules-auditor` |
| Firestore 모델링·쿼리·인덱스 | `firebase-firestore` |
| 익명↔Google 링크 등 Auth | `firebase-auth-basics` |
| Firebase CLI·프로젝트 전환·config 파일 | `firebase-basics` |
| 크래시 리포팅 | `firebase-crashlytics` |
| 실제 브라우저 조작·스크린샷·탐색적 QA | `agent-browser` |
| 로컬 Flutter web 앱 Playwright 검증 | `webapp-testing` |
| DE/EN 카피의 AI 티 제거 | `humanizer` |
| 위 표에 없는 능력이 필요할 때 | `find-skills` (설치 후보 탐색) |

⚠️ 스킬은 조언·절차서일 뿐 이 저장소의 규칙보다 우선하지 않는다. 충돌 시 **AGENTS.md 가 이긴다**
(특히 커밋 금지·SESSION_LOG 기록·하드코딩 문자열 금지·`if/else` 중괄호).

---

## 파일 맵 (SSoT)

### 진입점
- `lib/main.dart` — 라우트 테이블, Firebase/Ad 초기화, 팔레트 서비스. **`initialRoute: '/splash'`** — 스플래시 → 인트로/온보딩/홈 분기. **Analytics/Crashlytics는 opt-in** (2026-06-12): Manifest/Info.plist `*_collection_enabled=false` + `PrivacyConsentService.applyStored()`가 저장된 동의를 SDK에 적용
- `lib/screens/intro_gate_screen.dart` — 솟을대문 시네마틱 인트로 (Phase 1)
- `lib/motion/transitions.dart` — 공유 화면 전환 (`SoriTransitions.fadeScale`)

### 라우트
| 경로 | 화면 |
|---|---|
| `/intro` | IntroGateScreen (솟을대문 시네마틱 인트로 — **앱 진입점**) |
| `/` | **AppShell** (BottomNav 4탭 셸 — 홈/배우기/연습/단어장. 2026-06-05 IA 재설계) |
| `/onboarding` | OnboardingLevelScreen (첫 실행 레벨 선택) |
| `/vocab` | **VocabPacksScreen** (단어팩 그리드 — v2.0) |
| `/vocab/pack` (args: packId) | VocabPackScreen (Learn→Quiz→Boss 단계) |
| `/vocab/result` (args) | VocabPackResultScreen |
| `/vocab/recall` (args: packId) | VocabPackRecallScreen (선택형 Boss 단어 한국어 타이핑 회상) |
| `/vocab/legacy` | LegacyVocabScreen (구 플래시카드) |
| `/grammar` | GrammarScreen |
| `/hangul` | HangulScreen |
| `/chosung` | ChosungQuizScreen (초성 퀴즈 A1-C2) |
| `/wordle` | WordleScreen (한글 워들) |
| `/settings` | SettingsScreen |
| `/stats` | StatsScreen |
| `/profile` | ProfileScreen (프로필 허브 — 정체성·계정상태·요약 통계, 게스트→Google 유도. 진입: 홈 `_TopBar` 사람 아이콘) |
| `/scenarios` | ScenariosListScreen |
| `/scenario` (args: scenarioId) | ScenarioPlayerScreen |
| `/listening` | ListeningScreen (v1 — 시나리오 TTS 재생 + 자막 토글) |
| `/kkeunmari` | KkeunmariScreen (끝말잇기 호랑이↔사용자 턴제, 30s 타이머) |
| `/quests` | QuestsScreen (특별 퀘스트 — 마당 장식 언락) |
| `/book` | BookCaptureScreen (★ 책 한 컷: 사진→OCR) |
| `/book/preview` (args) | BookPreviewScreen (OCR 텍스트 수정) |
| `/book/result` (args) | BookResultScreen (단어·문법·문장 분석 결과) |
| `/vocab_notebook` | BookCaptureScreen(captureMode: notebook) — 단어장 사진 |
| `/vocab_notebook/result` (args) | VocabNotebookResultScreen (OCR에서 그 단어 쌍만 검토) |
| `/vocab_notebook/practice` (args: packId) | VocabNotebookPracticeScreen (카드·짝맞추기·받아쓰기·퀴즈·한자/유의어) |
| `/vocab_notebook/studio` (args: packId) | VocabNotebookStudioScreen (고른 단어로 기존 게임 만들기) |
| `/vocab_notebook/nuance` (args: packId) | VocabNuanceScreen (유의어·격식·한자 뿌리 비교 놀이) |
| `/bookshelf` | BookshelfScreen (내 책장 + 커스텀팩) |
| `/bookshelf/page` (args: pageId) | BookshelfPageScreen |
| `/custom_pack/play` (args: packId) | CustomPackPlayScreen (플립카드 학습) |
| `/custom_pack/edit·quiz·matching·typing` (args: packId) | 커스텀팩 편집 / 4지선다 / 짝맞추기 / 받아쓰기 |
| `/wordbook/search` | WordbookSearchScreen (내 저장 단어 통합 검색 + 품사 필터 — 2026-06-03) |
| `/word_web` | WordWebScreen (학습한 단어의 비슷한 말·반대말·연관어·표현. 기본은 `vokSeenIds`, 비면 레벨 누적 둘러보기) |
| `/dojangcheop` | DojangcheopScreen (도장첩 — 팩 클리어로 획득한 단청 도장 8 motif 갤러리. 진입: VocabPacksScreen AppBar) |
| `/gye/create` | GyeCreateScreen (계 만들기 — 이름·닉네임→6자리 코드 생성·공유) |
| `/gye/join` | GyeJoinScreen (계 입장 — 코드+닉네임 가입). 진입: 홈 둘러보기 "Lern-Gye" 카드→chooser 바텀시트 |
| `/gye` (args: gyeId) | GyeScreen (계 마당 — 멤버수·주간목표바·공동한옥(gye_* 8 합성)·피드·스티커 FAB·⋮멤버/나가기). 생성/입장 성공 시 진입 |
| `/gye/members` (args: gyeId) | GyeMembersScreen (멤버 목록 + 신고 다이얼로그). 진입: GyeScreen ⋮ |

### 서비스
- `lib/services/auth_service.dart` — Hybrid Auth. 항상 익명 로그인, Google 링크 선택. **주의**: web에서 Firebase 미설정 시 crash 방지를 위해 `_auth`가 nullable getter임.
- `lib/services/palette_service.dart` — Remote Config `palette_variant` 키로 단청/teal 토글. `paletteVariantNotifier` (ValueNotifier) → main.dart ListenableBuilder에서 ThemeData 재빌드.
- `lib/services/storage_service.dart` — SharedPreferences 래퍼 (레벨, streak, XP 등)
- `lib/services/data_loader.dart` — CSV/JSON 에셋 로드
- `lib/services/theme_service.dart` — 다크모드 toggle
- `lib/services/locale_service.dart` — 언어 선택 (DE/EN)
- `lib/services/kkeunmari_engine.dart` — 끝말잇기 풀 로더 + chain 검증 + 호랑이 다음 단어 선택 (`is_dead_end` 회피 우선)
- `lib/services/tts_service.dart` — **고품질 한국어 음성: 캐시우선 3단, 캐시 리비전 v3** (① 로컬캐시 `tts_v3_{voice}_{sha1}.mp3` → ② Firebase Storage `tts/v3/{voice}/{sha1}.mp3` 사전생성 → ③ Cloud Function 동적합성 → ④ flutter_tts 폴백). `speak(text,{voice})`/`speakSlow`/`setRate` 인터페이스 유지(23화면 무수정). voice: **female=Chirp3-HD-Zephyr**(Batch 05 포함 corpus 6,146), **male=Chirp3-HD-Enceladus**(시나리오 NPC·narrator corpus 175 + 책한컷·내단어장 동적). 전체 corpus 6,321개를 Storage에서 검증했으며 결과는 expected 6,321, remote 6,376, missing 0, stale 55다. 실제 음성명은 CF에만 있고 클라는 'female'/'male'만 전송한다. 시나리오 대화는 화자별 voice (`scenario_player`: user=여 / 그 외=남). `audioplayers` 재생, sha1 키 계약은 `functions/tts/tts_contract.js` + `tool/generate_tts.py` + `test/tts_cache_key_test.dart` 3중 고정(동일 벡터). 버킷 `ko-lernen-app.firebasestorage.app`(europe-west3). 동적 CF `functions/tts/synthesize_tts`(callable, App Check enforce).
- **책 한 컷 (Phase 5)**:
  - `lib/services/snap_ocr_service.dart` — ML Kit **on-device 한국어 OCR** (`OcrResult`). 이미지 기기 밖 전송 X.
  - `lib/services/book_analysis_service.dart` — Cloud Function 클라이언트 + 오프라인 stub. `setEndpoint(url)` / `analyze(text, targetLang)`. endpoint 빈 값/장애 시 문법패턴만 폴백.
  - `lib/services/bookshelf_service.dart` — BookPage 로컬(`kl_bookshelf_v1`) + best-effort Firestore `users/{uid}/bookshelf/{id}`.
  - `lib/services/custom_pack_service.dart` — 커스텀팩 **로컬 only**(`kl_custom_packs_v1`). createFromPage/getAll/save/delete. **`quickAdd`**(고정 id `cp_quick_v1` "⭐빠른저장" find-or-create + 한국어 dedup, enum `WordbookAddResult`) — 전역 "＋단어장"의 코어.
  - `lib/widgets/sori/wordbook_add.dart` — `addToWordbook(ctx, korean,…)` + `AddToWordbookButton`(compact). 6개 학습화면(review·chosung·wordle·vocab_pack·smalltalk·scenario_player)에서 호출.
- **단어팩 (Phase 1·2)**: `lib/services/vocab_pack_service.dart` (CSV `pack_id`로 117팩 로드) + `pack_progress_service.dart` (진행도 로컬+Firestore `users/{uid}/packs`).
- **한옥/퀘스트 (Phase 3·4)**: `lib/services/hanok_stage_service.dart` (진행도→한옥 12단계), `quest_tracker.dart` (특별 퀘스트), `daily_char_service.dart` (오늘의 글자).
- **동기화**: `lib/services/cloud_sync.dart` + `firestore_progress_service.dart`, `scenario_loader.dart` (시나리오 JSON).
- **계(契) (Phase 6·7·8 — 클라 완성 / CF 부분배포)**: `lib/services/gye_service.dart` (CRUD·6자리 코드·한도 3계/계10명·욕설·`sendSticker`·신고·나가기) + `lib/models/gye.dart` + `lib/data/profanity_denylist.dart` (`containsProfanity`) + `lib/services/age_gate_service.dart` (GDPR-K 16세). **UI 6화면 전부 구현**: create/join/gye(마당+공동한옥)/members + 홈 chooser, 스티커(catalog 30·`StickerPicker`·feed 렌더), `weekly_goal_bar`·`gye_hanok`·`gye_feed`. `firestore.rules` `gye/{gyeId}` 활성(멤버/계장/active/admin 게이트·reports collectionGroup·append-only). **CF `functions/gye/index.js`(v2/2nd gen, europe-west3) 3함수 코드 완성** — `on_pack_cleared`·`weekly_goal_rollover`·`on_report_created`. ✅ **배포(2026-06-05): CF 4종 전부 europe-west3·2nd gen·nodejs22·ACTIVE** — 계 자동집계(`on_pack_cleared`)·자동정지(`on_report_created`)·주간롤오버 프로덕션 작동. 미검증(Jin): 2계정 실동작 E2E·FCM 실도달·rules 재배포·admin claim. 상세 = 2026-06-05 세션로그.

### Sori 디자인 시스템 (`lib/widgets/sori/`)
- `tokens.dart` — **단일 색상 소스** (v6.0 단청 팔레트). `SoriColors`, `Spacing`, `SoriRadius`, `SoriElevation`, `SoriSurfaces`, **`SoriBreakpoints`(phone content=480·navigationRail=600·grid=600·tablet=720·wideTablet=1024)** 및 `soriComfortScale`(태블릿에서 앱 제어 글자/터치 영역 최대 10%, OS 접근성 글자 확대와 독립)
- `responsive.dart` — **반응형 콘텐츠 폭 클램프**. `soriClampPadding(width, {maxWidth, base})` + `SoriContentClamp`(LayoutBuilder 래퍼)는 폰에서 기존 480dp 컬럼을 보존하고 600--720dp 구간에서 탐색 화면을 640dp 컬럼까지 부드럽게 확장한다. 배경은 풀블리드, 집중형 학습 화면의 명시적 480dp 클램프는 유지한다.
- `hanok_tokens.dart` — 한옥 전용 색상 (단청 4색)
- `card.dart`, `button.dart`, `chip.dart`, `progress.dart`, `badge.dart`, `pressable.dart` — UI 컴포넌트
- `mascot.dart` — `Mascot.tiger` / `Mascot.magpie` (v6). **자산은 `assets/illustrations/mascot/`에 분리된 포즈 PNG**: 호랑이 5(idle/blink/happy/celebrate/sad) + 까치 4(perched/wingup/wingdown/celebrate). emotion → 포즈 매핑 (celebrate/worry/sleepy/surprised/thinking/neutral/smile). `tiger_thinking`/`tiger_sleepy`/`tiger_neutral`/`magpie_worry`는 Jin이 추후 추가하면 자동 사용, 미존재 시 errorBuilder fallback.
- ~~`tiger_stage.dart` / `tiger_stage_rive.dart`~~ — **2026-08-06 폐지**. 프레임 44장 애니메이션과 Rive 폴백을 함께 삭제했다. 홈이 `CharacterClipPlayer` 로 옮겨간 뒤 어떤 화면도 `TigerStageVideo` 를 만들지 않아 체인 전체가 데드코드였다. 프레임은 `assets_unused/illustrations/tiger_anim/` 으로 이동. 현재 정본은 `character_clip.dart` + `assets/video/character/`(호랑이 12클립), 영상 불가 시 `mascot.dart` 정지 PNG.
- `tiger_stage_rive.dart` — **Rive 리깅 호랑이 래퍼**(부드러운 sit→인사→pacing 목표). `assets/rive/tiger.riv` + `RiveNative.init()` 성공(`riveReady`) 시 Rive 재생, 그 외(미초기화·파일 없음·로드 실패·reduce-motion) `TigerStage`(프레임)로 자동 폴백. rive 0.14 API(`RiveWidgetBuilder`/`FileLoader.fromAsset`/`Factory.flutter`/`RiveWidget(fit:contain)`). **`tiger.riv` 리그는 미제작(Rive 경로 보류) — 프레임 폴백으로 동작.** 호랑이 전체 스펙은 `docs/TIGER_FULL_REMAKE_MASTER.md`. **홈은 2026-06-12부터 `tiger_video.dart`를 쓰고, 이건 그 폴백 체인의 중간 단계.**
- `tiger_video.dart` — **호랑이 영상 위젯 2종** (Jin 제작 mp4, 2026-06-12). ① `TigerStageVideo`(홈 밴드): 인사 `tiger_greet.mp4` launch당 1회 → 150ms 크로스페이드 → `tiger_pace.mp4` 무한루프, 항상 무음. ② `TigerGreetClip`(온보딩 첫 만남): 인사 영상 + `sfx/tiger_greet.mp3` 음성 1회. 영상이 H.264(알파 없음, 흰 배경)라 **`ColorFiltered`+`BlendMode.multiply`로 흰 배경을 크림에 흡수**(⚠️ 캔버스 saveLayer 블렌드는 비디오 Texture 레이어에 안 먹힘 — 반드시 ColorFiltered). multiply 특성상 **밝은 배경 전용** → 다크/reduce-motion/`videoReady=false`(테스트)/로드 실패 시 `TigerStageRive`→프레임 폴백. `videoReady`는 main.dart에서만 true. 탭 비가시(`TickerMode.getValuesNotifier`)·앱 백그라운드 시 pause. 홈 `_TigerHero`가 이걸 사용(rive·프레임은 폴백으로 강등).
- `mascot_pop.dart` — 퀘스트 피드백용 팝업 마스코트
- `hanok/` — 한옥 장식 위젯 (단청 divider, 기와 패턴, 처마, 창살, 마당 배경)
- `motion.dart` — `SoriEntrance` (진입 fade+slide+scale), `SoriKenBurns` (배경 느린 줌). **`SoriMotion.reduceMotion(context)` 헬퍼** — `MediaQuery.disableAnimations` 시 정적 fallback.
- `ambient_particles.dart` — 매화 꽃잎(light) / 불씨(dark) 입자. reduce-motion 시 SizedBox.
- `flying_magpie.dart` — 홈 상단을 가로지르는 비행 까치. reduce-motion 시 SizedBox.
- `empty_state.dart` — **표준 빈/오류 상태**. `SoriEmptyState(asset, title, body, ctaLabel, onCta, secondaryLabel)`. 일러스트 errorBuilder가 아이콘 fallback.
- `hanok_header.dart` — 10:3 wide 한옥 헤더 배너. 자산 미존재 시 단청 그라데이션 + 아이콘 fallback.
- `madang_background.dart` — 한옥 12단계 배경. 3단계 fallback: `hanok_stages/stage_{slug}_{light|dark}.png` → `hanok/madang(…).png` → 그라데이션. **dark stage PNG 0/12 → 다크모드는 그라데이션.**
- `hanok_cinematic.dart` — 단계 전환 시 1회 시네마틱 (Storage gating).
- `decoration_layer.dart` — 퀘스트 보상 장식 합성. 미존재 PNG는 초록 원형 placeholder.
- `dancheong_stamp.dart` — 단청 도장 (CustomPainter, PNG 미참조).
- `pack_card.dart` / `celebration.dart` — 단어팩 카드 / 축하 burst.
- `module_card.dart` — **ModuleCard** 공유 컴포넌트 (home·허브 3종 공용, 2026-06-05 추출).
- `feature_coach.dart` — **FeatureCoach** 마스코트 바텀시트 코치마크 (account_nudge 일반화, 2026-06-05).
- ✅ 모션 시스템 일원화 완료 — `flutter_animate` 패키지 제거. `motion.dart` + `lib/motion/transitions.dart` 둘만 공존 (역할 분리: entrance vs route transition).

### 데이터
- `assets/data/korean_vocab.csv` — 단어장 (level 필드: A1/A2/B1/B2/C1/C2)
- `assets/data/grammar.csv` — 문법
- `assets/data/scenarios.json` — 회화 시나리오
- `assets/data/kkeunmari_pool.json` — 끝말잇기 단어 풀
- `assets/data/word_relations.json` — 학습 단어 단어망(비슷한 말·반대말·연관어·표현). 코스/한옥 권한 없음.
- `assets/data/grammar_patterns.json` — 문법 패턴 정규식 (책 한 컷 오프라인 stub용). **Cloud Function 쪽 `functions/analyze_korean_text/grammar_patterns.json`과 schema 동기 필요.**
- 단어팩(117)은 별도 파일이 아니라 `korean_vocab.csv`의 `pack_id`/`pack_order`/`is_review_boss` 컬럼에서 파생.
- ✅ **콘텐츠 언어 (2026-08-15 갱신)**: `korean_vocab.csv` `english`/`pos_en`/`example_english`(1,188/1,188)·`grammar.csv` `_en` 컬럼(176/176) 채움 — `meaning(lang)` 헬퍼로 EN UI 사용자도 영어 학습 콘텐츠 표시. (구 "독일어 전용" 메모는 stale.)

### 에셋 (2026-05-26 복원 후 최종)
- `assets/icons/HanLogo.png` — **현재 앱 아이콘 소스** (Gemini 생성, 1024×1024, 갓+한)
- `assets/icons/icon-192.png` — pubspec 등록된 192 buffer
- `assets/illustrations/hanok/` — 한옥 공간 자산 (모두 사용 중):
  - `madang(light).png` / `madang(dark).png` — 홈 배경 (낮/밤)
  - `gate_door_left.png` / `gate_door_right.png` / `gate_frame.png` — IntroGateScreen GateArt 합성
  - `gate.png` — 한옥 솟을대문 단일 일러스트 (홈페이지 final-cta 배경, 앱은 미래 사용)
  - `welcome-hero.png` — 호랑이+어깨 까치+단청 점 통합 일러스트 (앱 미래 사용, 홈페이지 mascot-strip는 docs/assets/ 사본 사용)
  - `porch.png` — Chosung/Wordle 80px banner
  - `study.png` — Vocab/Grammar 80px banner (신규 `study_classroom.png`/`study_scholar.png`가 들어오면 자동 교체)
  - `calligraphy.png` — Hangul 화면 헤더
- `assets/illustrations/mascot/` — 분리 포즈 PNG (Mascot 위젯 소스, 11종):
  - 호랑이 7: `idle`, `blink`, `happy`, `celebrate`, `sad`, `neutral` (← tigerbasic1 복원), `smile` (← tiger_smile 복원)
  - 까치 5: `perched`, `wingup`, `wingdown`, `celebrate`, `perched_alt` (← v2 복원, fallback 다양성용)
- ~~`assets/illustrations/tiger_anim/`~~ — 프레임 44장. **2026-08-06 `assets_unused/illustrations/tiger_anim/` 로 이동**(pubspec 등록 해제 → 번들에서 제외). 44장 전부 `assets/video/character/` 의 상위 호환 클립으로 대체된다: 인트로 9→`tiger_rise`, idle 4→`tiger_rest`·`tiger_sitting2`, 좌우 보행 22→`tiger_walking_front`, stretch 3→`tiger_stretch`, roar 6→`tiger_roar`, 정적 폴백 `stand_greet`→`mascot/tiger_*.png`.
- `assets/video/home_hero/` — Today 전용 한지 매트 사전 합성 루프 2종:
  호랑이=`tiger_thinking_hanji.mp4`(10초 standing idle·중앙 1.2배),
  까치=`magpie_walking_front_hanji.mp4`(하단 1.2배). 둘 다 BT.709/tv의 실기기
  매트 `#FBF5EB`; 잘린 원샷 `tiger_rise_hanji`는 `assets_unused/video/`에 보존한다.
- `assets/illustrations/gye/` — 실제 가입 계의 진행도 합성 요소 8종
  (haenglangchae·byeoldang·jeongja·pond_large·garden·bridge·jangmyeongdeung_pair·gate_grand)은
  `GyeHanok`이 완성/다음/ghost 상태로 사용한다. 빈 Gye 소개는 이들을 모두 겹치지 않고
  단일 `gye_showcase_courtyard.webp`를 포스터로 쓰며, 빈 마당→완성 원샷
  `assets/video/gye/gye_shared_hanok_build.mp4`를 겹친다(2026-08-15 Jin 승인).
- `assets/illustrations/book/` — **책 한 컷 UI 일러스트 5, 전부 연결**(2026-06-03): empty_shelf→책장 빈 상태, camera_guide→book_capture idle, analyzing→book_result 로딩(`AppLoading.asset`), success→book_result 성공, error→book_result 에러(`AppError.asset`). 모두 errorBuilder→마스코트 fallback. 명세 §7.
- `assets/illustrations/scenes/` — 시나리오 backdrop 5종 (Jin 작업)
- `assets/illustrations/empty/` — 빈 상태 일러스트 3종 (Jin 작업)
- `assets/illustrations/error/` — 오류 상태 일러스트 2종 (Jin 작업)
- `docs/store/feature_graphic_v1_draft.png` — Play Store feature graphic 임시본
- `docs/assets/` — 홈페이지(hangul-sori.com) 자산: `logo.png`, `tiger.png`, `magpie.png`, `tiger_celebrate.png`, `favicon.png`, `welcome-hero.png` (mascot-strip), `gate.png` (final-cta 배경)
- ⚠️ **2026-05-25 → 26 변경 흐름**: 중복 마스코트 7장 + icon-512는 영구 삭제. 미참조 5장은 시각 검수 후 모두 복원 — tigerbasic1/tiger_smile/welcome-hero/gate는 적재적소 매핑(neutral/smile emotion + 홈페이지 hero/CTA), magpie_perched.v2는 fallback 다양성용 보존.

---

## 브랜드 팔레트 (v6.0 단청)

| 역할 | 이름 | 값 |
|---|---|---|
| Primary | 녹청 | `#1F7A6B` |
| Accent | 석간주 적 | `#A0524A` |
| Tiger | 호랑이 주황 | `#FF8C42` |
| Gold | 황 | `#C99A2E` |
| Light BG | 한지 cream | `#FAF6EC` |
| Dark BG | 먹 ink | `#0E1A18` |

**Kill-switch**: Firebase Remote Config `palette_variant` = `"teal"` → `#2AB7A9` 레거시로 롤백.

---

## 주요 패턴 & Gotchas

### Dart 문법
- `if/else` 반드시 중괄호 사용. 한 줄 생략 금지 (실제 오류 발생 이력 있음).
- 세미콜론 누락 주의.

### Web에서 Firebase
- `FirebaseAuth.instance`는 web에서 Firebase 미초기화 시 crash → `auth_service.dart`의 `_auth` getter가 try-catch로 nullable 반환하도록 수정되어 있음. 이 패턴 유지.

### 로컬라이제이션
- UI 텍스트는 `AppL10n.of(ctx).XXX` 사용. 하드코딩 금지.
- 독일어 = 주 언어. 새 문자열은 `l10n/app_de.arb` + `l10n/app_en.arb` 양쪽에 추가.

### 마스코트 (v6, 2026-05-25)
- `Mascot.tiger` / `Mascot.magpie` — 분리 포즈 PNG (`assets/illustrations/mascot/`).
- `emotion` 파라미터: celebrate/worry/sleepy/surprised/thinking/neutral/smile.
- 호랑이 매핑: celebrate=tiger_celebrate, worry=tiger_sad, sleepy=tiger_sleepy*, thinking=tiger_thinking*, surprised=tiger_happy, smile/neutral=tiger_idle (animate=true 시 blink 프레임).
- 까치 매핑: celebrate=magpie_celebrate, worry=magpie_worry*, animate 시 wingup/wingdown 교대, idle=magpie_perched.
- `*` 표시는 Jin이 PNG 추가 시 자동 사용. 미존재 시 _Fallback (색상 원+이모지).
- `animate: true` → hero 컨텍스트(결과/홈)용 부드러운 호흡 스케일 애니메이션.

### 아이콘 재생성
```bash
flutter pub run flutter_launcher_icons     # Android/iOS
npx sharp-cli --input assets/icons/HanLogo.png --output web/icons/Icon-192.png resize 192
npx sharp-cli --input assets/icons/HanLogo.png --output web/icons/Icon-512.png resize 512
```

### 개발 실행
```bash
flutter run -d chrome          # 웹 (개발)
flutter run -d <android-id>   # 안드로이드
```

---

## 현재 진행 중인 작업 (2026-08-16 기준)

> 완료 이력·커밋별 검증은 `docs/SESSION_LOG.md`에만 남긴다. 이 섹션은 다음 세션이
> 바로 행동할 수 있는 **현재 게이트**만 적는다.

- [x] **단어망 V1 + 검수 후속**: 학습한 단어의 비슷한 말·반대말·연관어·표현
 66클러스터(A1 42·A2 8·B1 8·B2 8)를 `assets/data/word_relations.json`에 두고,
 연습 허브·둘러보기·Learn 카탈로그에서 `/word_web`으로 공부·4지선다 연습을 연다.
 질문은 배운 단어, 보기는 전체 시드. 학습 범위는 `vokSeenIds`+SRS 한국어.
 코스 증거·한옥 보상은 쓰지 않는다. 단어장 뉘앙스(Hanja)와 입구를 나눈다.
- [x] **Google/Apple 연동·계정 삭제 클라 복구**: 모든 Google 경로가 web
  `serverClientId`와 비어 있지 않은 ID 토큰을 요구하고, 연동 전 익명 세션을
  다시 만들며, Apple 취소는 실패가 아니라 취소로 남는다. iOS Info.plist에
  공개 reversed client URL scheme을 넣었다. Apple 해지 시크릿이 placeholder/
  미구성이면 서버가 삭제를 멈추지 않고 TN3194대로 계정을 지운다. 실기기
  Google SHA·실제 Apple `.p8` 해지·Functions 재배포는 운영 게이트로 남는다.
- [x] **DE/EN 교과서 관용구 제거**: `오랜만이야` → `long time no see` /
 `lange nicht gesehen` 같은 세트 문구를 학습자용 DE/EN에서 걷어냈다. 인사·작별·
 안부·첫만남과 smalltalk 템플릿·폴백을 구어로 맞췄고, 한국어 원문과 ID는 유지했다.

- [x] **문화어 미니 이야기 V1**: 한옥·계·사랑방·마당·종가·단청·보자기·장독대·
 문방사우·매화·사군자·갓·책가도·소반·자개문갑 15개를 DE/EN/KO 공통 JSON으로
 고정했다. 앱은 제목·보상·장식함과 읽기 전용 사랑방/마당에 48dp 도움말·직접 탭·
 1회 안내를 제공하고, 홈페이지는 첫 등장 한옥/Gye에 데스크톱 대화상자·모바일 하단
 시트를 제공한다. 데이터 실패 시 기존 흐름/문장은 유지하고 도움말만 숨긴다. production
 반영은 `fc85a997`에서 문화어 요소로 나뉜 문장을 visible text로 검증해 확인했다.

- [x] **B2 문법 체크포인트 입력 복원**: `V-았/었더라면`을 포함한 코스 문법
  체크포인트는 카드 전체 탭과 하단 CTA가 같은 채점 시트를 열며, 정답 선택까지 실제
  위젯 탭 회귀로 고정했다. 일반 문법 카드의 앞뒤 뒤집기 동작은 유지한다.

- [x] **전체 시나리오 문제 프레임 통합**: 58개 시나리오·241개 문제의 7개 엔진을
  장면 포스터·문항 분절 진행·명시적 확인·2회 시도·단일 계속 CTA로 통일했다. 첫 실행은
  실제 마지막 문항 저장 성공 뒤에만 최종 성공 화면을 연다. 역할극도 장면 크롭·탭 재생
  문장 카드·제목 옆 배속·고정 CTA로 통합했고, 공유 카드/타일은 220ms 이하 눌림·상태
  모션과 reduced-motion 계약을 따른다. 자세한 검증은 세션 로그 최상단이다.

- [x] **첫 공항 초보자 탈출 경로 + Play·홈페이지 자동화**: 공항 2번 Cloze는
  `한국 처음이세요?`를 정확히 완성하고, courseContext 없는 첫 실행의 7개 엔진은
  정답을 공개하되 점수를 주지 않는 `모르겠어요` 보조 액션을 제공한다. 짧은 Cloze
  선택지는 남는 높이 중앙에 배치한다. `main` Flutter 변경은 기존 quality gate 성공 뒤
  서명 AAB를 Google Play Internal Testing에 자동 업로드한다. 홈페이지·공통 문화어
  JSON 변경은 웹 gate 뒤 exact Git SHA를 Cloudflare production에 배포하고 live SHA를
  검증한다. 두 release job은 각각 repository variable로 명시적으로 활성화한다.

- [x] **웹사이트 로컬 Sites/ZIP 탈출**: 정본은 부모 저장소가 추적하는
  `hangul-sori-site-local/` 하나다. Sites 패키징·Bash·중첩 Git·ZIP·기본 root Worker와
  Pages CNAME을 격리했고, Node 24.18.0 fresh build·17 tests·strict dry-run·전체 audit를
  통과했다. 배포는 커밋 SHA 확인과 조건부 자동 rollback을 포함한다.
- [x] **웹사이트 GitHub/Cloudflare 최종 전환**: GitHub `main` push가 redesign Workers
  Builds의 `npm run deploy:check` → `npm run deploy:production`으로 자동 배포된다. apex/www는
  `hangul-sori-redesign` production이며 exact release·11 routes·hashed build assets·21 owned
  assets·API/bindings·TestFlight를 배포 뒤 검사한다. 레거시 `hangulsori` build config/trigger와
  Sites custom-domain claim은 0개다. 과거 Wrangler OAuth grant와 로컬 credential 파일도
  폐기했으며, 수동 배포가 필요할 때만 `npm run cloudflare:login`으로 OS keychain 기반
  credential을 새로 만든다.
- [x] **웹사이트 모바일 DE/EN 전환**: 560px 이하에서도 헤더 언어 전환을 유지하고,
  360px 이하에서만 중복 헤더 CTA를 숨겨 공간을 확보한다. 390px DE/EN 실제 전환과
  360px·1440px 무오버플로 회귀를 고정했다.

- [x] **사랑방 자유 배치·에셋 전면 활용**: 고정 슬롯을 v3 연속 좌표 편집기로 교체하고
  보유 장식 11종·스티커 30종·도장 14종을 개인 방 인벤토리에 연결했다. 퀘스트 전용
  장식 13종은 기존 마당 경로를 유지하며, 상세 검증은 `docs/SESSION_LOG.md` 최상단이다.
- [x] **UI/UX 개편 2**: 정본은 `docs/HANDOFF_UI_OVERHAUL_2_2026-08-14.md`이고 구현은
  `main`의 `f718106c`에 통합됐다. 새 화면/흐름의 설계 기준은 이 문서 하나를 사용한다.
- [x] **시나리오 문제 UI 계약 마감 + 목업 프레임**: G1–G7 + B1–B8.
  포스터는 기존 12장 크롭. 실기기 TTS·키보드 inset은 Jin 게이트.
- [ ] **UI 실기기 게이트 (Jin)**: 덱 4방향 손맛·시스템 엣지·히어로 잘림, 승인 대기 중인
  아이콘/리소 자산을 실제 기기에서 검수한다. 승인 전에는 대규모 UI 재설계나 자산 덮어쓰기를
  하지 않는다.
- [x] **콘텐츠 Batch 01–05**: B1/B2 기존 확장에 더해 Batch 05의 B2/C1/C2
  vocabulary·grammar·smalltalk·Cloze·Satz 504개와 4개 고급 코스 단원이 앱 데이터에
  통합됐다. 기존 16개 시나리오/듣기 퀘스트도 유지한다. 콘텐츠 정본은
  `docs/CONTENT_AUTHORING_GUIDE.md`, `docs/CONTENT_ARCHITECTURE.md`,
  `docs/CONTENT_SOURCE_POLICY.md`, `docs/CONTENT_REFERENCE_INTAKE_GUIDE.md`다.
- [x] **C레벨 오늘·스몰톡 노출 계약**: 새 오늘의 단어는 학습자의 exact CEFR에서
  뽑고, 이미 학습해 복습일이 된 하위 레벨 카드만 SRS 복습으로 유지한다. Review,
  legacy Today, Practice Hub, Today snapshot, 개인화 코스가 같은 selection helper를
  사용한다. 비코스 Smalltalk도 사용자 exact level과 그 레벨에 실제 문장이 있는
  category로 시작하며 exact-level 콘텐츠가 없을 때만 누적 fallback한다.
- [x] **살아 있는 한옥 V1 PR1 선행 계약**: 40개 `CourseUnit`을 영구 보상 수로
  고정하지 않고 `core_2026_v1`의 검증 가능한 `CanDoSegment`를
  A1/A2/B1/B2/C1/C2 `16/16/18/20/8/8`, 총 86개로 분리했다. 같은 능력의 새 콘텐츠는
  cluster revision, 독립 can-do는 후방 extension track으로 추가해 과거 분모·한옥을
  낮추지 않는다. 정본은 `docs/ADR-003-can-do-segment-authority.md`다.
- [x] **살아 있는 한옥 V1 PR2 병합 게이트**: 86개 실제 segment·cluster와 118개 typed
  생산 평가 요구, CourseMastery V3 증거, C1/C2 4단계 project receipt, CourseUnit 완료와
  생산 도장을 분리한 재평가 경로까지 구현했다. 미승인 learner copy는 draft에만 격리하고
  production route를 fail closed했다. PR #31 exact-head CI를 통과하고 main merge
  `90613738`에 반영됐다.
- [ ] **살아 있는 한옥 V1 PR3 병합 게이트**: 검증된 productive `CanDoSegment`만
  86개 영구 보상을 여는 `HanokState v1`·grant catalog·projection·idempotent cutover·
  cloud/account merge를 구현한다. CourseUnit 완료는 재평가 자격만 열고 집을 올리지 않으며,
  room-v3·장식·Gye 데이터는 보존한다. 미승인 grant plan은 `tools/content_factory/drafts/`
  에만 두고 Flutter asset/production loader로 ship하지 않는다. PR3 병합 전에는 사용자
  기본 경로에 노출하지 않는다.
- [ ] **살아 있는 한옥 V1 PR4 자산 파이프라인**: A1 0–16 catalog·4:3 디코드 창
  renderer·투명 socket compositor·연속성/lineage gate·원자적 승격/썸네일 도구는
  코드로 고정됐다. 승인되지 않은 이미지는 runtime/pubspec에 넣지 않는다. Jin이
  남은 투명 레이어를 만들면 QA 합성 → 연속성 검사 → 16개 원자 승격 순서로만
  런타임에 넣는다. production route 연결과 PR3 Play 업로드 결정은 이 항목에
  포함되지 않는다. Codex 파일럿 A1-05~10 raw·레이어·QA WebP는 `9958a458`로
  `assets_unused/pending_review/`에 들어왔다(승격 아님). **Codex 06이 앞줄 기둥 7개만
  그려 07~10에 뒷줄·옆보가 없고 완성 사랑채는 앞기둥 8개(7칸)라, 05~10 계보 전체를 새로
  만든다.** BBANANA ledger 19건(13.5 credit)은 **이관하지 않기로 확정**(2026-08-17, Jin) —
  근거는 `docs/HANOK_V1_SOURCE_REGISTRY.md` 생성 기록 절.
- [x] **Batch 06 앱 데이터 승격 + 카탈로그 계약**: `fa86b7af`가 Batch 06
  68개 standalone + embedded quest 20개를 production asset과
  `curriculum_manifest.json` contentLinks에 올렸다. review ledger는 전부
  `approved`이고 manifest 상태는 `merged`다.
- [x] **한국 파트너 가족·명절 트랙 live 승격**: Batch 07/08 partner-family가
  live 자산에 들어갔다. 현재 카탈로그는 vocab 1620, cloze 962, satz 875,
  smalltalk 365, scenario 90, quest 359, pronunciation 20, A1–B2 smalltalk
  semantic decision 321이다.
- [x] **A1 partner 수리·생산 퀘스트 + typography 래칫**: 7개 A1 partner
  시나리오에 particlePop+satzBauen을 넣어 카탈로그 345→359. 단어장/커스텀팩
  라벨 CTA의 raw AppBar·w800·장식 아이콘을 걷어 래칫을 166/98/71로 내렸다.
- [ ] **레벨 콘텐츠 4× 잔량 초안 (Batch 09/10, review-only)**: partner-family
  승격 뒤 충돌하던 Batch 07/08 4× ID를 폐기하고, live max+1부터 다시 붙였다.
  Batch 09는 단어 48팩/576·문법 24·스몰토크 12·Cloze/Satz 각 576,
  Batch 10은 시나리오 174 + 미사용 live Satz 640이다. 적용 매니페스트는
  `batch_09_4x_manifest.json` / `batch_10_4x_manifest.json`이다.
  옛 `batch_07_4x` / `batch_08_4x`는 `superseded`. `--apply`/TTS/Firebase는
  Jin 승인 전 금지. 원래 4× 목표(vocab 4752 / scenario 232 / satz 1676)까지는
  이 슬라이스 이후에도 vocab 잔량이 남는다.
- [ ] **다음 콘텐츠**: 4× 잔량 초안은 Batch 09/10 manifest로 보존한다. loader 재계산
  작업량은 `docs/CONTENT_LOADER_GAP_AND_PDF_WORK_PLAN_2026-08-16.md`를 따른다.
  PDF, OCR, 표 판독은 `reference_intake/` 격리 DB를 거쳐 source가 제거된 brief만
  독립 집필에 쓴다. review 승인 전에는 앱 데이터, TTS, Firebase에 쓰지 않는다.
- [x] **Batch 05 TTS/Storage**: 신규 504개를 합성·업로드했고 전체 corpus 6,321개를
  Storage에서 검증했다. 결과는 expected 6,321, remote 6,376, missing 0, stale 55이며
  과거 immutable stale 객체는 삭제하지 않는다.
- [x] **책 한 컷 로컬 하드닝**: ML Kit Korean 단일 인식, 공용 NFC/혼합-text 계약,
  사진 선명도·명암·회전 gate와 3단 정렬, 엄격한 응답 schema/언어 검증, 빈·오염 결과의
  저장·팩·TTS 차단, DE/EN 출처, Kiwi 관형형, source-free 30일 cache, exact source
  allowlist와 배포 verifier를 구현했다. Flutter/Python/Firestore 회귀와 preflight는 통과했다.
- [x] **백엔드 신뢰성 1단계 (로컬)**: 책 분석·TTS·발음이 제공자 실패 시 할당량을
  환급하고, DeepL/Azure/Cloud TTS에 프로세스 내 서킷 브레이커를 둔다. TTS `usage`와
  `service_quota_ledgers`는 `expiresAt` TTL을 쓰고, 레거시 `cache/translations`와
  할당량 컬렉션은 클라 접근을 차단한다. 끝말잇기 사전 HTTP는 2KB 상한을 강제한다.
  live 배포·TTL ACTIVE 확인은 아래 운영 게이트에 남긴다.
- [x] **백엔드 신뢰성 2단계 (로컬)**: 끝말잇기 사전 503은 할당량을 환급하고, 빈
  TTS 버퍼는 Storage에 남기지 않으며, DeepL/Cloud TTS는 클라 12초보다 짧은
  deadline으로 실패한다. 같은 책 분석 지문과 같은 `assessmentId` 재시도는
  `service_idempotency` 영수증으로 한도를 다시 깎지 않는다. 클라 접근은 차단하고
  `expiresAt` TTL 15분이다. live 배포는 운영 게이트에 남긴다.
- [x] **유료 경로 4결함 완전 차단 (로컬)**: 책 분석·발음은 consume 전 pending
  선점으로 진행 중 재시도가 한도를 두 번 깎지 않는다. DeepL은 요청당 8초
  공유 예산, 사전 예외도 환급, TTS는 MPEG/ID3 최소 길이만 캐시 히트다.
- [x] **TTS 리뷰 잔여 4건 (로컬)**: 선점 실패는 과금하지 않고 503이다. pending
  패자는 재합성하지 않는다. 함수 timeout은 클라와 같은 12초, 합성은 7초다.
  에러 로그는 코드만, 클라 로컬 캐시는 MPEG/ID3만 재생한다.
- [ ] **TTS·Rules 배포 (Jin)**: 빈 캐시 거절·환급·12초 timeout·7초 deadline·
  fail-closed 선점은 `functions/tts` live에 아직 없다. indexes → rules →
  `functions:tts-firebase-functions` 순으로 올린다. 책 분석 Gen2는 별도
  운영 게이트다.
- [ ] **책 한 컷 운영 게이트 (Jin 승인 필요)**: 2026-08-15 live Gen2는 필수 모듈이 빠진
  구버전이고 cache 379건에 원문이 있으며 TTL 정책은 없다. Secret/전용 계정과 Rules+TTL,
  Python Gen2를 배포하고 source SHA, Android `de`/iOS `en` signed smoke, 실제 혼합 교재
  촬영을 통과한 뒤에만 별도 삭제 승인으로 legacy cache를 정리한다.
- [ ] **릴리스 운영 (Jin)**: App Store Connect 처리 뒤 TestFlight 실기기 확인, Android
  AAB의 Play Internal Testing 설치·App Check·데이터 보존 확인 뒤 Closed Testing 승격.
- [x] **문서 정리**: 활성 정본 목록은 `docs/README.md`에 둔다. 완료된 계획·세션별
 초안은 working tree에 되살리지 말고 Git history와 `docs/SESSION_LOG.md`로 추적한다.
- [x] **단어장 사진 → 그 단어만 놀이 연습**: 교재 분석과 분리된 Vokabelheft
 경로가 사진의 한국어–뜻 쌍을 그대로 팩으로 만들고, 카드·짝맞추기·받아쓰기·퀴즈와
 한자/유의어/격식 비교 놀이로 이어진다. CSV/TSV 가져오기는 8,000행까지 받는다.
 코드 리뷰 후 두 칸 OCR 짝짓기, 괄호 뜻, 추가 사진 시 저장, 교재 할당량 우회,
 중복 단어 제거를 고쳤다. 학습자는 그 단어 중 골라 카드·퀴즈와 기존 Cloze·
 문장 만들기·초성·스피드매치·스몰토크·발음·시나리오·단어망 콘텐츠로
 스스로 게임을 만든다. 없는 문장은 만들지 않는다. 실기기 촬영 검수는
 Jin 게이트로 남는다.

## 세션 로그 → docs/SESSION_LOG.md

> 세션 히스토리(2,700+줄)는 컨텍스트 비용 절감을 위해 **`docs/SESSION_LOG.md`** 로 분리했다.
> - 과거 맥락이 필요하면 그 파일만 **grep/Read**(자동 로드하지 않음).
> - ⛔ **새 변경 기록은 이제 `docs/SESSION_LOG.md` 최상단(최신이 위)에 남긴다** — 무엇을·왜·검증·커밋해시.

---

## PR·CI 규칙 (AI 에이전트 필수)

> **⛔ PR 을 만들거나 갱신하면, CI 실행을 직접 확인할 때까지 끝난 게 아니다.**

**왜 이 규칙이 필요한가 (2026-08-06 실측).** Claude GitHub App 을 통해 만든 PR #5 는
`pull_request` 이벤트로 **CI run 이 아예 생성되지 않았다**. `ci.yml` 의 트리거는 정상이고
(`push:[main]` + `pull_request:[main]` + `workflow_dispatch`), Actions 도 정상이며
(`workflow_dispatch` 는 즉시 큐에 잡혔다), 2026-07-31 PR #4(사람이 만든 PR)에서는 자동 CI 가
정상 동작했다. 즉 **YAML 문제도 권한 문제도 아니고, PR 생성 경로(앱 vs 사람)의 차이**다.
Cloudflare 앱은 같은 PR 이벤트로 자기 체크를 붙였기 때문에 "체크가 하나 붙어 있다"는 겉모습에
속기 쉽다 — 그건 CI 가 아니다.

**따라서 PR 작업의 완료 조건은 다음 6단계다:**

1. 로컬 관련 검증을 끝내고, 연속 수정은 모아 브랜치를 한 번 push한다.
2. PR 생성 또는 갱신 뒤 현재 head SHA를 확인한다.
3. 그 SHA의 자동 CI run이 이미 생성됐는지 먼저 확인한다. 있으면 **수동 run을 추가하지 않는다**.
4. 자동 run이 없을 때만 `.github/workflows/ci.yml`을 PR head 브랜치에서 기본
   `task=ci`로 한 번 `workflow_dispatch`한다.
5. run ID와 `Select required checks` 결과를 확인하고, 변경 범위에 맞는 Analyze/Test/Build,
   Website, Book, Gye, Pronunciation 잡의 결과를 확인한다.
6. **현재 head SHA의 필요한 run이 존재하고 결과를 확인하기 전까지 "PR 준비됨"이라고
   보고하지 않는다.**

**비용 안전장치.** 기본 `task=ci`는 `main`과 PR head의 차이를 읽어 필요한 영역만 연다.
앱 변경은 Flutter, `functions/analyze_korean_text/**`는 Book,
`functions/gye/**`는 Gye, `functions/pronunciation/**`는 Pronunciation,
`hangul-sori-site-local/**`는 Website만 실행한다. 공용 Rules·Firebase 설정·CI 자체 변경은
관련 게이트를 보수적으로 함께 연다. 일반 Markdown/세션 로그만 바뀐 push/PR은 run 자체를
만들지 않는다.

**PR은 범위 테스트, main은 전체 (2026-08-17, Actions 3,000분 소진 뒤 도입).**
`pull_request`의 Analyze & Build는 (1) draft PR이면 아예 돌지 않고, (2) `changes` 잡의
`.github/scripts/select_flutter_tests.py`가 변경 파일의 Dart import 폐포로 고른 테스트 +
상시 가드 4개(`typography_guard`·`l10n_parity`·`arb_l10n_guard`·`sori_activity_catalog`)만
돌리며, (3) `flutter build web`을 생략한다. `assets/**`·`lib/l10n/**`·`pubspec*`·
`analysis_options.yaml`·`test/goldens/**`·플랫폼 폴더가 바뀐 PR은 import 간선이 못 지키므로
전체 suite로 되돌아간다. `main` push와 `workflow_dispatch`는 예전처럼 전체 suite + web 빌드다.
즉 PR에서 초록이어도 merge 뒤 main run이 최종 그물이며, 선택기 오류는 fail-open(전체)이다.

- 의존 범위를 확신할 수 없는 교차 계층 변경이나 명시적 최종 전체 점검만 `task=full`.
- 골든 기준선을 실제로 교체할 때만 `task=regenerate-goldens`; 일반 CI와 중복 실행되지 않는다.
- 같은 SHA의 자동 run과 수동 run을 둘 다 만들지 않는다. 새 코드 변경 없이 재시도할 때는
  전체 재실행 대신 실패한 잡만 재실행한다.
- 같은 브랜치의 오래된 run은 `concurrency`가 취소한다. 실패 diff는 3일, 재생성 골든은
  7일만 보관한다.

---

## 금지 사항

- `dist/`, `build/` 내부 직접 편집 금지
- `--no-verify` git hook 우회 금지 (Jin 명시 요청 없이)
- 커밋/푸시는 Jin이 명시적으로 요청할 때만
- `palette_variant` 외 Remote Config 키 임의 추가 금지

---

## 지속 메모리 (구 memory/ 통합 — 세션 간 유지되는 사실)

### android-video-decoder-reclaim

---
name: android-video-decoder-reclaim
description: "2026-07-31 log audit disproved the earlier deterministic 2+ decoder ceiling claim; v2.0.1 uses one global video lease as a defensive ownership policy, with physical release verification pending MIUI installation approval"
metadata:
  node_type: memory
  type: project
  originSessionId: 0750265c-14ec-4416-add7-420b1a03289d
---

**정정 (2026-08-01):** 이 항목의 초기 결론은 실측 로그로 반박됐다. **M2101K6G / Redmi Note 10 / Snapdragon 678 / Android 12 / MIUI**, adb id `9053622f`에서 동시 player init이 최대 5개인 구간도 코덱 오류 없이 관측됐다. `MediaCodec: keep callback message for reclaim`은 오류를 동반하지 않는 debug 로그라 단독으로 강제 회수의 증거가 아니다. 따라서 “두 개 이상을 재생할 수 없다”나 “하나가 하드웨어 한계”라고 주장하지 않는다.

**현재 정책:** `video_player` controller의 수명은 전역 `VideoLeaseCoordinator`가 단일 소유한다. `TigerStageVideo`, `TigerGreetClip`, `CharacterClipPlayer`, `SoriPosterLoop`, `_IntroVideo`는 가시성·route·앱 생명주기에 따라 lease eligibility만 보고한다. 자연 종료·lease 회수·초기화 실패·dispose 예외 뒤에도 다음 후보가 진행되도록 하며, 이는 관측되지 않은 하드웨어 한계를 전제하는 우회가 아니라 누수와 경쟁을 피하는 방어적 소유권 정책이다.

**검증 경계:** 소스 게이트와 lease 테스트는 통과했지만, release APK의 실제 Redmi cold-start·영상 경로·logcat은 MIUI가 `INSTALL_FAILED_USER_RESTRICTED`로 설치를 취소해 아직 완료되지 않았다. 설치 승인 뒤에만 기기 동작을 주장한다. 상세는 `docs/ADR-001-video-decoder-budget.md`.

### cloze-shared-prompt-widget

---
name: cloze-shared-prompt-widget
description: Cloze/daily-challenge screens share lib/widgets/sori/cloze_prompt.dart
metadata:
  node_type: memory
  type: reference
  originSessionId: 6bad5992-9e0d-444b-bfb6-40537e8ed513
---

`daily_challenge_screen.dart`와 `cloze_game_screen.dart`는 문제 카드·선택지 UI가 동일 쌍둥이다. 2026-07-31부터 그 공통 블록은 **`lib/widgets/sori/cloze_prompt.dart`** 공유 위젯으로 추출됨:

- `ClozePromptCard` — 한국어 빈칸 문장 + `Text.rich` 번역(정답 단어 인라인 강조) + TTS.
- `ClozeOptionsList` — `LayoutBuilder`+`ConstrainedBox(minHeight)`+`IntrinsicHeight`+`Column(spaceEvenly)`로 선택지를 화면 하단까지 균등 분산(빈 하단 제거·큰 글자 스크롤 폴백).
- 순수함수 `splitEmphasis(sentence, gloss)` — 문장에서 뜻 단어를 대소문자 무시 부분일치로 찾아 강조 구간 분할(테스트 `test/cloze_prompt_test.dart`).

**How to apply:** cloze/데일리챌린지 UI를 바꿀 땐 두 화면을 각각 고치지 말고 이 공유 위젯 한 곳을 수정. 정답 단어의 독일어/영어 뜻은 별도 필드가 아니라 **런타임 조회**로 얻는다 — `DataLoader.loadVocab()`로 `Map<String,Vocab>` 만들고 `vocab[item.answer]?.translationFor(lang)`(wordle_screen과 동일 패턴). cloze.json에는 뜻 필드 없음. 관련: [[jin-no-ios-style-badges]].

### jin-no-ios-style-badges

---
name: jin-no-ios-style-badges
description: Jin dislikes iPhone-style badge/pill UI chrome; prefers in-content emphasis
metadata:
  node_type: memory
  type: feedback
  originSessionId: 6bad5992-9e0d-444b-bfb6-40537e8ed513
---

Jin은 iPhone풍 배지/필(둥근 pill 라벨, "칩" 강조 요소) UI를 싫어한다. 2026-07-31 Cloze 화면에서 정답 단어를 알려줄 때 "찾는 단어: X" 강조 배지를 제안하자 "배지 이미지 어떻게할건데?? 아이폰에서 쓰는것같은거 하려면 집어치워"라며 거부 → 대신 **독일어 문장 텍스트 안에서 해당 단어만 굵게·색으로 강조**하는 방식을 택함.

**Why:** 앱 화풍은 "Faceted Minhwa" 한옥/단청 정체성이고, Jin은 iOS 시스템풍 요소가 이질적이라고 느낀다. 강조는 별도 UI 크롬을 얹기보다 콘텐츠(텍스트) 자체에서 하는 걸 선호.

**How to apply:** 무언가를 강조/안내할 때 배지·필·칩을 새로 얹기 전에 **기존 텍스트/콘텐츠 내 인라인 강조**(fontWeight, 색, `Text.rich`)로 해결 가능한지 먼저 고려. 배지형 UI가 꼭 필요하면 제안 전 Jin에게 확인. 관련 작업: [[cloze-shared-prompt-widget]].
