# AGENTS.md — ko_lernen_app (Hangul Sori) · 모든 세션의 단일 진입점(SSoT)

> **⛔⛔ 어떤 AI 에이전트/환경(Codex · Claude Code · Cursor · Gemini 등)이든, 어떤 세션이든 시작 즉시 이 AGENTS.md를 가장 먼저 (상단 개요·파일맵·규칙 위주로) 읽고 시작한다 — 예외 없음.** 이 파일이 프로젝트의 유일한 단일 진실 원천이다. (구 `CLAUDE.md`·`memory/` 내용은 전부 이 파일로 통합됨. `CLAUDE.md`는 이 파일을 가리키는 포인터일 뿐.)
>
> **⛔ 필수 기록 규칙 (예외 없음):** 코드·데이터·에셋·설정·문서 등 무엇이든 하나라도 변경하면 반드시 `docs/SESSION_LOG.md` 최상단에 항목을 남긴다(무엇을·왜·검증·커밋해시). 기록 없이 변경만 커밋 금지. 로그 갱신은 같은/직후 커밋에 포함.
> **⛔ 커밋/푸시는 Jin이 명시적으로 요청할 때만.** 동시 세션이 흔하니 본인이 만진 파일만 골라 스테이징.

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
| `/vocab/legacy` | LegacyVocabScreen (구 플래시카드) |
| `/grammar` | GrammarScreen |
| `/hangul` | HangulScreen |
| `/chosung` | ChosungQuizScreen (초성 퀴즈 A1-B2) |
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
| `/bookshelf` | BookshelfScreen (내 책장 + 커스텀팩) |
| `/bookshelf/page` (args: pageId) | BookshelfPageScreen |
| `/custom_pack/play` (args: packId) | CustomPackPlayScreen (플립카드 학습) |
| `/custom_pack/edit·quiz·matching·typing` (args: packId) | 커스텀팩 편집 / 4지선다 / 짝맞추기 / 받아쓰기 |
| `/wordbook/search` | WordbookSearchScreen (내 저장 단어 통합 검색 + 품사 필터 — 2026-06-03) |
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
- `lib/services/tts_service.dart` — **고품질 한국어 음성: 캐시우선 3단, 캐시 리비전 v3** (① 로컬캐시 `tts_v3_{voice}_{sha1}.mp3` → ② Firebase Storage `tts/v3/{voice}/{sha1}.mp3` 사전생성 → ③ Cloud Function 동적합성 → ④ flutter_tts 폴백). `speak(text,{voice})`/`speakSlow`/`setRate` 인터페이스 유지(23화면 무수정). voice: **female=Chirp3-HD-Zephyr**(단어·예문·user 대화 사전생성 ~1211), **male=Chirp3-HD-Enceladus**(시나리오 NPC·narrator 사전생성 ~103 + 책한컷·내단어장 동적) — 실제 음성명은 CF에만 있고 클라는 'female'/'male'만 전송. 시나리오 대화는 화자별 voice (`scenario_player`: user=여 / 그 외=남). `audioplayers` 재생, sha1 키 계약은 `functions/tts/tts_contract.js` + `tool/generate_tts.py` + `test/tts_cache_key_test.dart` 3중 고정(동일 벡터). 버킷 `ko-lernen-app.firebasestorage.app`(europe-west3). 동적 CF `functions/tts/synthesize_tts`(callable, App Check enforce). (2026-08-02 검수로 v2/Aoede 표기 정정 — 상세 `docs/AUDIO_VIDEO_RELEASE_AUDIT_2026-08-02.md` §4.)
- **책 한 컷 (Phase 5)**:
  - `lib/services/snap_ocr_service.dart` — ML Kit **on-device 한국어 OCR** (`OcrResult`). 이미지 기기 밖 전송 X.
  - `lib/services/book_analysis_service.dart` — Cloud Function 클라이언트 + 오프라인 stub. `setEndpoint(url)` / `analyze(text, targetLang)`. endpoint 빈 값/장애 시 문법패턴만 폴백.
  - `lib/services/bookshelf_service.dart` — BookPage 로컬(`kl_bookshelf_v1`) + best-effort Firestore `users/{uid}/bookshelf/{id}`.
  - `lib/services/custom_pack_service.dart` — 커스텀팩 **로컬 only**(`kl_custom_packs_v1`). createFromPage/getAll/save/delete. **`quickAdd`**(고정 id `cp_quick_v1` "⭐빠른저장" find-or-create + 한국어 dedup, enum `WordbookAddResult`) — 전역 "＋단어장"의 코어.
  - `lib/widgets/sori/wordbook_add.dart` — `addToWordbook(ctx, korean,…)` + `AddToWordbookButton`(compact). 6개 학습화면(review·chosung·wordle·vocab_pack·smalltalk·scenario_player)에서 호출.
- **단어팩 (Phase 1·2)**: `lib/services/vocab_pack_service.dart` (CSV `pack_id`로 61팩 로드) + `pack_progress_service.dart` (진행도 로컬+Firestore `users/{uid}/packs`).
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
- `assets/data/korean_vocab.csv` — 단어장 (level 필드: A1/A2/B1/B2)
- `assets/data/grammar.csv` — 문법
- `assets/data/scenarios.json` — 회화 시나리오
- `assets/data/kkeunmari_pool.json` — 끝말잇기 단어 풀
- `assets/data/grammar_patterns.json` — 문법 패턴 정규식 (책 한 컷 오프라인 stub용). **Cloud Function 쪽 `functions/analyze_korean_text/grammar_patterns.json`과 schema 동기 필요.**
- 단어팩(61)은 별도 파일이 아니라 `korean_vocab.csv`의 `pack_id`/`pack_order`/`is_review_boss` 컬럼에서 파생.
- ✅ **콘텐츠 언어 (2026-06-09 해소)**: `korean_vocab.csv` `english`/`pos_en`/`example_english`(546/546)·`grammar.csv` `_en` 컬럼(88/88) 채움 — `meaning(lang)` 헬퍼로 EN UI 사용자도 영어 학습 콘텐츠 표시. (구 "독일어 전용" 메모는 stale.)

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
- `assets/illustrations/gye/` — **계(공동 한옥) 요소 8** (haenglangchae·byeoldang·jeongja·pond_large·garden·bridge·jangmyeongdeung_pair·gate_grand). 2026-06-03 드롭. **현재 코드 consumer 없음** — "계" 공동 마당 기능 제작 시 합성용. 명세 jongga-assets §6.
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

## 현재 진행 중인 작업 (2026-06-02 기준)

> **최신 현황 → `docs/release-readiness-2026-06-02.md`.** 앱은 **v2.0 (stately-rising-jongga)**, 버전 `2.0.0+3`, 안드로이드 내부 테스트 직전.
> - ✅ 사진→단어장("책 한 컷") 클라이언트 완성 · Cloud Function(`functions/analyze_korean_text` — kiwipiepy+DeepL+우리말샘) **배포 대기**
> - ✅ 단어팩 61(Learn→Quiz→Boss) · 특별 퀘스트→마당 장식 · 한옥 12단계 성장 · 홈 v4(호랑이 hero)
> - ✅ **2026-06-05: BottomNav IA 재설계 + 첫 사용자 온보딩 코치마크 (Stage 1)** — AppShell(4탭) + 허브 3종 + feature_coach.dart + Storage kl_tut_* 플래그 + P0 배선(책한컷·단어팩). 미커밋(Jin 확인 후).
> - ⏳ Jin 운영: 함수 배포(gcloud gen2) · AAB 빌드 · Play Console 업로드 · 실기기 검증
> - 🟡 후속: hanok_stages dark 12장 · 영어 학습 콘텐츠 · 수익화 · 허브 폴리시(진행도 헤더) · 탭 재선택 pop-to-root

### iOS `.ipa` 빌드 자동화 (2026-08-10)

- [x] **`scripts/build_ios_ipa.sh`** — macOS 전용 원커맨드 `.ipa` 빌더 (`a506813`).
  위 "iOS·iPad App Store 로컬 준비"의 마지막 항목이 **문서로만** 존재하던 걸 실행기로
  만들었다: 도구·`APPLE_TEAM_ID`(10자)·`RC_IOS_KEY`(`appl_`)·`GoogleService-Info.plist`
  확인 → `pub get` + `pod install`(`GoogleMLKit/TextRecognitionKorean` 존재 검사) →
  검증 게이트 2종 → `flutter build ipa --release`. **커밋된 `ios/ExportOptions.plist`
  의 빈 `teamID` 는 고치지 않고** `mktemp` 복사본에만 `PlistBuddy` 로 주입하고 `trap`
  으로 지운다 — 저장소 무자격증명 원칙을 우회하지 않으면서 자동화한 지점.
- [x] **검증 게이트를 빌드 경로에 편입.** `tool/verify_ios_firebase_config.dart` 와
  `tool/verify_ios_store_contract.dart` 는 존재만 하고 **아무도 호출하지 않고 있었다.**
  이제 `GoogleService-Info.plist` 누락·스토어 계약 위반이면 빌드가 시작조차 안 한다.
- [x] **업로드는 기본 미수행** (`destination: export` 존중). `ASC_KEY_ID`/`ASC_ISSUER_ID`/
  `ASC_KEY_PATH` 3종이 모두 있을 때만 `altool validate-app → upload-app` 까지 간다.
- [x] **`docs/store/APPSTORE_UPLOAD_KO.md`** — 한국어 순서표 (`a506813`·`ed51a18`).
  ⚠️ **앱 레코드는 파일 없이 먼저 만든다** — 없으면 업로드가
  `No suitable application record was found` 로 거부된다.
  빌드번호는 Android `versionCode` 와 **한 값을 공유**하므로 Play 로 소모한 번호는
  App Store 에서 재사용 불가.
- [ ] **Jin(macOS)**: 첫 실행이 곧 검증이다. 스크립트 본체(빌드·서명·업로드)는 실제
  애플 자격증명이 있어야 돌아가 리눅스 CI 에서 검증 불가 — `bash -n` 만 통과했다.
- [ ] **미결 판단 2건**: ① `pubspec.yaml` `2.0.5+13` vs
  `docs/store/app-store-connect-v2.0.5.md` `2.0.5 (11)` 문서 드리프트 ②
  `ios/Runner/Info.plist` 에 `ITSAppUsesNonExemptEncryption` 부재 → 업로드마다
  수출규정 질문. **법적 신고 항목이라 임의로 넣지 않았다.**

### 첫 화면 UX·온보딩 오버레이 + 짧은 뷰포트 반응형 (2026-08-06)

- [x] **코치마크를 타겟 옆 작은 contextual tooltip 으로** 재작성했다. 옛 `Positioned(left/right: 16)` 은 tight constraint 로 `maxWidth: 320` 을 무력화해(`BoxConstraints.enforce`) 태블릿에서 700dp 흰 판이 되고 가로모드에서는 화면 밖으로 나갔다. `_CoachTooltipLayout`(SingleChildLayoutDelegate)이 자식의 측정 크기를 보고 옆/아래/위를 고르고 safe-area 로 클램프한다. 폭 상한 340dp, 내부 스크롤, `1 / 5` 카운터, `Überspringen` 대비 7.0:1, `Weiter →`.
- [x] **레일 라벨 `Lerngrupp / e` 해소.** 라벨을 한 줄 고정 + `FittedBox(scaleDown)` 로 바꿔 줄바꿈 대신 축소하고, `navGye` 를 `Gruppe`/`Group` 으로 줄였다 (`Start · Üben · Gruppe · Profil`).
- [x] **짧은 뷰포트 규칙 신설.** `SoriBreakpoints.shortViewport`(640) 미만 높이에서 `HanokHeader` 10:3 배너가 스스로 접힌다 — CI 800×600 `grammar_screen` 37px 오버플로의 실제 원인이었고 17개 화면이 함께 고쳐진다. `SoriEmptyState` 도 일러스트를 가용 높이 38% 로 제한 + 스크롤 폴백.
- [x] **온보딩을 progressive 로.** 첫 실행 5단계 강제 투어 → 오늘의 미션 카드 1단계. 나머지는 각 탭 첫 진입에서 `ScreenCoachMixin` 이 설명한다(계 탭·프로필은 이미 있었고 = 투어와 중복, 연습 허브에 `practice_hub` 신설).
- [x] **홈 위계.** 한옥 지도 폭 상한 440dp(폰 시각 변화 0, 태블릿 높이 −1/4) + 진행률 % 를 바 옆으로 승격, 히어로 밴드 태블릿 상한 216→184, 카피 단축 및 `Meine Hanok` → `Mein Hanok` 문법 교정.
- [x] 검증: `flutter analyze` 0 issues · 전체 `flutter test` **2,337 통과 / 2 실패**. 잔여 2건은 baseline(2,168/3)에서도 같이 실패하는 `character_clip_matte_test` 드리프트다(`5927ae6` 이후 리포트 미재생성) — 내 범위 밖. 새 회귀는 옛 코드에 돌려 **실패하는 것까지 확인**했다(코치마크 12건 · 레일 4건).
- [x] **expanded 홈 2-column (2026-08-07).** 콘텐츠 폭이 744dp 이상일 때 [히어로 | 미션] · [한옥 지도 | 진행률] · 보조 카드 2열로 간다. 판정 기준은 **화면 폭이 아니라 `LayoutBuilder` 가 준 실제 콘텐츠 폭** — 홈은 NavigationRail 오른쪽에 있어 둘이 다르다(800dp 화면은 레일이 붙으면 1열로 남는다). 640dp 로 고정돼 있던 clamp 상한도 2열 경로에서만 984dp 로 푼다. 1280×800 실측: 스크롤 1542→1102(−29%), 미사용 폭 672dp(52.5%)→328dp(25.6%), 한옥 559→424. 폰은 스크롤 길이까지 **완전히 동일**(1526/1621).
- [x] **코치마크 접근성 결함 2건.** 새 a11y 게이트가 잡았다 — `Überspringen` 탭 영역이 152×**13dp**(`EdgeInsets.zero`+`Size.zero`+`shrinkWrap` 부작용), 단계 카운터 `1 / 3` 대비 4.11:1(AA 4.5 미달). 각각 높이 48dp 보장(가로 padding 은 0 유지 → 짧은 가로모드 방어 그대로)과 `#4A6560`(7.0:1)으로 수정.
- [x] **게임 화면 카드 크기·빈칸 채우기 (2026-08-07).** 실측이 내 초기 진단을 뒤집었다 — 세로 낭비는 Blitz-Paare(63%)·Satz bauen(57%) **두 화면만**의 문제였고, 네 화면 공통 결함은 **탭 타깃이 화면 크기와 무관하게 고정**(폰·태블릿 모두 42~53dp)인 것이었다. `soriFairTileHeight()`(신설 `game_layout.dart`)로 남는 세로를 타일이 나눠 갖게 하고, 빈칸 채우기는 고른 단어를 문장에 실제로 끼워 넣는다(오답 빨강 → 700ms 뒤 복귀 → 재시도). ⚠️ `QuizChoice.revealCorrect` 로 **오답 순간 정답을 감춘다** — 안 그러면 재시도가 무의미. 점수·SRS 는 첫 시도만 반영.
- [x] **Wortkette 히어로 크롭.** 동영상이 아니라 PNG 였다 — 1254×700(1.79)을 10/3 프레임에 cover 로 넣어 세로 46.3% 가 잘렸다. 프레임을 실제 비율로 교정(에셋 재작업 불필요).
- [x] **`MascotPartner` 원형 케이지 제거** — never-cage 규칙 ③ 위반이 7개 퀘스트 엔진 전부에 있었다.
- [ ] **후속(별도 visual audit): 히어로 크롭 5건.** ⛔ **숫자만 보고 일괄 수정 금지** (Jin 지시 2026-08-07) — 실제 화면을 눈으로 본 뒤 각각 유지/수정을 정한다. 인벤토리:

  | 에셋 | 사용 화면 | 원본 비율 | 선언 | BoxFit | 세로 crop |
  |---|---|---|---|---|---|
  | `madang(light).png` | scenarios_list | 848×1854 = 0.46 | 10/3 (기본) | cover (기본) | **86.3%** |
  | `listening_hero.png` | listening | 1254×700 = 1.79 | 10/3 (명시) | cover (기본) | **46.3%** |
  | `porch.png` | practice_hub, wordle | 1254×700 = 1.79 | 10/3 (기본) | cover (기본) | **46.3%** |
  | `study_scholar.png` | grammar, learn_hub, settings, hanok_header 기본값 | 1254×680 = 1.84 | 10/3 (기본) | cover (기본) | **44.7%** |
  | `achievements.png` | quests | 1254×608 = 2.06 | 10/3 (기본) | cover (기본) | **38.1%** |
  | `study_classroom.png` | legacy_vocab, vocab_packs, wordbook_hub | 1254×601 = 2.09 | 10/3 (기본) | cover (기본) | **37.4%** |

  판단 포인트: ① `madang(light)` 는 **세로 이미지(0.46)** 라 배너 크롭이 의도된 배경일 가능성이 높다 — 실제 비율로 바꾸면 화면 높이가 통째로 망가진다. ② `study_scholar` 는 `HanokHeader` **기본 에셋**이라 한 곳만 고쳐도 4개 화면이 함께 움직인다. ③ 나머지는 대부분 10/3 을 **명시하지 않고 기본값에 기대고 있다** — 기본값을 바꾸는 선택지도 있다. 정상(crop 0%)인 것: `calligraphy`(3.37) · `kkeunmari_hero`(1.79, 이번에 교정) · `taego-joy-duo`(contain).
- [ ] **미착수(P3)**: 캐릭터 idle 애니메이션 폴리시, 미세 spacing/타이포. 공용 `responsive_test.dart` 에 `360×400`·`800×360`·`1280×500` 추가는 **PR #8 정리 후**(같은 파일 충돌 회피 — Jin 지시).
- [ ] Jin 실기기: 갤탭·샤오미패드 세로/가로에서 코치마크가 `Üben` **옆에** 붙는지 · 폰 가로모드에서 카드 안 잘리는지 · 레일 `Gruppe` 한 줄(글자 1.0/1.3) · 첫 설치에서 투어 1단계 후 `Üben` 첫 진입 코치 1회 · 홈 한옥 카드 높이 체감(폰은 무변화여야 함).
- [x] 별도 정리 완료(2026-08-07, PR #7 로 분리): `tool/check_clip_matte.py` 를 ffmpeg 로 실제 돌려 리포트 재생성. 번들 20개 **전부 통과** — `magpie_choose.mp4` 는 교체된 새 파일도 `#FFFFFF`/흰 100%/169프레임이라 에셋 문제가 아니라 인증서 drift 였다.
- [x] **DE/EN humanizer pass (2026-08-10).** UI, 온보딩·코치마크, Gye·동의·단어장 문구를 원어민 앱 톤으로 다듬고, 문화 노트 30개와 시나리오 문화/소개 문구 9개에서 과장·고정관념·번역투를 제거했다. 학습 목표·한국어 원문·ID·ICU 플레이스홀더는 보존. `flutter analyze --fatal-infos` 0 issues · 로컬라이즈/콘텐츠 가드 14 통과 · 스모크/접근성 55 통과. 상세 `docs/SESSION_LOG.md` 최상단.
- [x] **투명 로고 생성 반영 (2026-08-10).** 새 `HanLogo.png`를 Android 런처/adaptive·Android 12 스플래시, iOS AppIcon·LaunchImage, 웹 PWA·스플래시에 재생성해 연결했다. iOS는 알파 불가라 `background_color_ios: #2AB7A9`로 흰 모서리를 방지했고, 웹 maskable은 한지색 `#FAF6EC`으로 평탄화했다. 생성 성공·치수/알파·시각 검수·`git diff --check` 확인. 상세 `docs/SESSION_LOG.md` 최상단.

### 출시 안정성 7대 과제 (2026-08-06)

- [x] **공통 창 분류** `lib/widgets/sori/window_class.dart` — `AppWindowClass`(compact<600 /
  medium<840 / expanded) + `windowClassFor` · `appWindowClassOf` · `SoriMaxWidth`(form 600 · prose
  720 · dialog 520) · `AppContentFrame`(내부는 `SoriCenterClamp` 위임). **기존 `SoriBreakpoints`
  픽셀값은 불변** — 분류만 위에 얹었다. `window_class_guard_test` 가 레이아웃 레이어의
  `Platform.is*` 0건과 숫자 리터럴 폭 비교 래칫(1)을 강제한다.
- [x] **골든·접근성** `test/goldens/screen_layout_golden_test.dart`(**3화면**(settings·learn_hub·
  vocab_packs) × compact/medium/expanded = **9장**, Linux+3.44.0 생성) ·
  `test/accessibility_guideline_test.dart`(6화면 × 터치영역·대비·라벨·1.3배·태블릿 = 30).
  골든이 단어팩 헤더 800dp 51px 오버플로를, 접근성 검사가 코치마크 13dp 터치 영역·동의 체크박스
  32dp/무라벨·대비 2.89 를 잡아 **전부 위젯을 고쳤다**.
  ⚠️ `stats` 는 골든 대상이 **아니다**(2026-08-10 제거). `_StreakWeekHeatmap` 이
  `DateTime.now().weekday` 로 "오늘" 칸 테두리를 그려 렌더가 **요일마다 달라지기** 때문 —
  기준선을 만든 요일에만 통과한다. 되살리려면 먼저 그 위젯에 시계 seam 을 줄 것.
- [x] **핵심 흐름 E2E** `test/e2e/app_flows_e2e_test.dart`(CI 실행) + `integration_test/`(실기기 전용,
  `integration_test` dev 의존성 추가). 시작 분기·오프라인 우선·재시작 진도 유지·손상 데이터 부팅·
  초기화·다운그레이드·창 분류 일관성.
- [x] **영상 디코더 계약** `test/video_lease_contract_test.dart` — **동시 네이티브 컨트롤러 최대 1개**를
  못 박고(dispose 지연 중에도), 회수·승계·release 멱등·생성/dispose 예외 복구를 고정.
- [x] **진단·오류 UI** `lib/services/diagnostics_service.dart`(키를 `DiagnosticKey` enum 으로 봉인,
  값 64자·개행 절단, 동의 off 면 no-op) + `diagnostics_route_observer.dart`.
  🔴 `linkWithGoogle()` 이 **Firebase 불가와 사용자 취소를 둘 다 null 로** 반환해 UI 가 "취소"로
  뭉개던 결함을 3갈래(`Cancelled`/`Unavailable`/`Failed(reason)`)로 분리하고 DE/EN 6키를 추가했다.
- [x] **데이터 복구·마이그레이션** 🔴 `kl_srs_v1`·`kl_pack_progress_v1` 손상 시 복습/저장 1회로
  학습 이력이 **통째로 덮어써지던 무음 소실**을 격리(`*_corrupt_v1`)+write 잠금으로 막았다.
  팩 진행도는 **읽기 전 쓰기**로도 전멸했었다(write 전 load). `data_migration_service.dart` 가
  `kl_schema_version`·멱등 러너·journal·백업/롤백·**다운그레이드 fail-closed** 를 맡는다
  (프로덕션 단계는 의도적으로 0개 — 러너만 주입 테스트).
- [x] **출시 QA 정본** `docs/store/RELEASE_QA_CHECKLIST.md` — 나머지 13개 항목(회전·글자확대·
  보조기술·다크·현지화·네트워크·권한·플랫폼 관례·영상/오디오·자산/성능·기기 매트릭스·스토어 트랙·
  버그 템플릿) 흡수. 구 `JIN_VERIFY_CHECKLIST.md`·`closed-testing-checklist-v2.md` 가 이걸 가리킨다.
- [ ] **Jin 실기기**: 체크리스트 §2 회전/멀티윈도우/폴더블, §4 TalkBack·VoiceOver, §5 다크 충돌,
  §7 네트워크 9상태, §9 권한 6상태, §15 스토어 단계 배포. 자동 테스트가 이걸 대체하지 않는다.
- [ ] **미결 부채**: `SoriColors.lightTextDim` 전역 대비 2.89(AA 미달 — 동의 화면 2곳만 `textMuted`
  로 올림) · `TigerGreetClip`/`TigerStageVideo` 다크 게이트 부재.

### 캐릭터 영상·오버레이 결함 12건 수정 (2026-08-06)

- [x] 전수 검사 6건 + 완성도 크리틱 6건을 모두 고쳤다. 규칙 3가지가 코드에 고정됐다: ① **불투명 매트 사각형은 자기가 놓인 도형 안에 들어가야 한다**(path_trail 클립 62→내접 48.1) ② **`blendColor` 는 실제로 뒤에 칠해진 색에서 파생**한다(Scaffold 위=`scaffoldBackgroundColor`, HanjiTexture 위=`SoriColors.lightBg` 상수. `s.bg` 는 팔레트 변종을 못 봐 항상 오답) ③ **never-cage 는 clip 뿐 아니라 테두리/프레임도 금지**(scenario_player 롤플레이 카드 border 제거).
- [x] `CharacterClipPlayer` 에 다크 게이트를 넣고 위젯 내부 3개 지점을 `videoUnavailable()` 로 배선했다. `ColorFiltered` 는 `ClipRect`(hardEdge)로 감싸 텍스처 saveLayer 의 파괴 반경을 영상 사각형 안에 묶었다 — RepaintBoundary 는 no-op 이라 채택하지 않았다.
- [x] 앰비언트 입자를 콘텐츠 **위**로 올려(홈·레벨선택) 꽃잎이 영상 사각형에 먹히지 않게 했고, `hanok_cinematic` 의 reduce-motion 토스트가 홈 전체를 덮던 버그를 래퍼 추가로 고쳤다.
- [x] 검증: `flutter analyze --fatal-infos lib/ test/` 0 · 전체 `flutter test` 2,159 통과. 잔여 3건은 `design_components_golden_test` 로, 내 변경을 stash 한 깨끗한 HEAD 에서도 동일하게 실패하는 **CI(Linux) 기준선 vs Windows 로컬** 차이다.
- [ ] Jin 실기기: ClipRect 가 헤더 소실을 막는지. **못 막으면 되돌리고** mp4 매트를 크림으로 재출력해 `ColorFiltered` 자체를 제거한다. 시각 확인: 학습경로 노드 캐릭터 축소(62→48), 프로필 호랑이 `tiger_walking_front` 프레이밍, 캐릭터 앞을 지나는 꽃잎.
- [ ] 다크 모드를 켤 때: `TigerGreetClip`(quick_onboarding 라이브)·`TigerStageVideo` 에는 아직 다크 게이트가 없다. 다크 테스트 커버리지도 저장소 전체에 0건.

### 홈 히어로 — 헤더 소실·영상 이음매 수리 (2026-08-06)

- [x] 홈 배경 상단 60%를 `SoriColors.lightBg` 평면 단색으로 두고 radial glow 를 히어로 밴드 아래로 내려, 캐릭터 mp4 흰 매트의 `multiply` 결과가 배경과 픽셀 동일해지게 했다(영상 사각형 "액자" 소멸).
- [x] 헤더(로고·스트릭/레벨 칩·설정)와 인사·말풍선이 캐릭터 영상보다 **나중에 paint** 되도록 `Column(verticalDirection: up)` 로 순서만 역전했다(배치는 동일). 밴드 높이는 화면 높이·폭·글자배율 반응형(≤216dp)으로 바꿨다. 회귀는 `test/home_hero_layout_test.dart` 16개가 고정한다.
- [ ] Jin 실기기 재빌드 검증: 헤더 복귀 · 영상 이음매 소멸 · 밴드 체감 크기(까치·호랑이 둘 다). 그래도 헤더가 안 보이면 원인은 `ColorFiltered`(saveLayer)+외부 텍스처 → mp4 매트를 크림으로 재출력해 `ColorFiltered` 제거가 다음 수(SESSION_LOG 2026-08-06 항목 참고).

### v2.0.5+11 내부 테스트 AAB (2026-08-05)

- [x] Play Console에 이미 등록된 `2.0.4+10`보다 높은 `2.0.5+11`로 버전을 올리고 새 signed AAB를 만들었다. `flutter analyze --fatal-infos`는 0 issues, 전체 직렬 `flutter test --no-pub --concurrency=1 --reporter compact`는 2,109 passed, AAB의 package/version·업로드 서명 검증도 통과했다. 정확한 SHA-256·인증서 지문은 아래 세션 로그에 기록한다.
- [ ] Jin 운영: Play Console internal track에 `2.0.5` (`versionCode 11`) AAB를 업로드하고 pre-launch report 및 테스터 설치를 확인한다.

### iOS·iPad App Store 로컬 준비 (2026-08-05)

- [x] iOS/iPad 정적 준비팩을 만들었다. Settings는 `PackageInfo`의 실제 `version (build)`를 표시하고, DE/EN 카메라·사진 권한 문자열은 Runner 리소스로 등록했다. 정적 iOS 계약 검사, DE/EN 스토어 문구·지원 페이지·App Store Connect 인수인계, 실제 iOS 캡처용 무알파 PNG 검사기를 함께 추가했다.
- [x] 로컬 통합: 포맷 게이트는 6파일 변경 없이 통과했고, iOS/Settings/태블릿 반응형 묶음 `flutter test`는 421 passed, 정적 iOS 계약 CLI와 범위 분석은 통과했으며 PNG 검사기 회귀는 18 passed다. 전역 `dart analyze --fatal-infos`는 동시 작업 범위 밖 `lib/screens/vocab_pack_screen.dart:331:8`의 unused `_speakCurrent` 하나 때문에 현재 green으로 기록하지 않는다.
- [ ] macOS 릴리스 담당: `docs/store/ios-external-setup.md`에 따라 iOS Firebase를 구성하고, Apple 팀/서명·공개 RevenueCat iOS dart-define로 Xcode archive를 만든 뒤 최종 privacy report를 검토한다. 그 다음 실제 iPhone·13-inch iPad(TestFlight 포함) 검증·실제 무알파 캡처·App Store Connect 메타데이터/연령 등급/App Privacy 입력·지원/개인정보/계정삭제 URL의 실제 호스팅·메일함을 확인한다. Windows에서는 IPA·TestFlight·실기기 완료를 주장하지 않는다.

### Android·태블릿 유동 레이아웃 (2026-08-04)

- [x] 폰 폭은 유지하고 600--720dp에서 탐색 콘텐츠 폭을 480→640dp로 확장했으며, 공통 타이포·CTA·모듈 카드가 태블릿에서 최대 10% 커지게 했다 (`596ef4f`).
- [x] AppShell은 폰 하단 탭·태블릿 세로 라벨 레일·넓은 태블릿 가로 확장 레일을 폭 기준으로 전환한다. 단위/상호작용 위젯 테스트와 targeted analyzer 통과 (`13c94e0`).
- [x] `soriClampPadding` 직접 사용 화면도 기본적으로 같은 태블릿 컬럼을 받고, 단어팩은 실제 부모 폭을 쓰는 `SoriContentClamp`로 옮겼다. 계약 테스트·targeted analyzer 통과 (`89ac3ae`).
- [x] 태블릿 레일은 긴 독일어 `Lerngruppe` 라벨과 시스템 글자 확대 1.3배에서도 안정적으로 렌더링되는 회귀 테스트를 갖췄다 (`c75ffc6`).
- [x] 세로 태블릿 레일의 최소 폭을 96dp로 두고, 공통 Sori 라벨 크기(태블릿 14.3px)를 사용해 기본 Material 라벨보다 읽기 쉽게 했다 (`4108b5d`).
- [x] 29개 핵심 화면의 전체 반응형 스모크를 308/360/600/720/800/1280dp 및 360/800dp × 시스템 글자 1.3배로 고정했다. `flutter test test/responsive_test.dart` 244개 통과 (`9c73854`).
- [x] AppShell의 96dp 태블릿 레일 뒤 프로필 탭은 전체 창 폭이 아니라 실제 남은 폭을 쓰는 `SoriContentClamp`로 여백을 계산한다. 전용 800dp/96dp 레일 회귀와 전체 프로필 테스트, targeted analyzer 통과 (`e9290c3`).
- [x] 논리 태블릿 세로 800×1280·가로 1280×800 및 가로 글자 1.3배를 29개 화면 회귀에 넣었다. `flutter test test/responsive_test.dart` 331개 통과 (`4478ded`).
- [x] 600dp 이상 중형 안드로이드 태블릿·폴더블은 96dp 라벨 레일을 쓰고, 720dp까지는 콘텐츠/CTA 확대를 점진 적용한다. 레일 단위 테스트와 331개 화면 매트릭스 통과 (`7cb426b`).
- [ ] Jin 실기기: Galaxy Tab 및 Xiaomi Pad에서 세로/가로 회전, 시스템 글자 확대 1.0/1.3, 탭 전환·재선택·학습 진입을 확인한다.

### 사랑방 배치 저장 복구 (2026-08-04)

- [x] `roomPlacement`가 일부 잘못된 SharedPreferences 항목 때문에 유효한 방 배치까지 전부 비우지 않도록 고쳤다. 유효한 `String → String` 항목은 보존하고, 손상 JSON/항목은 fail-closed로 제외한다 (`8e7dd88`).

### 사랑방 보상 꾸러미 지급 연결 (2026-08-04)

- [x] 새 특별 퀘스트 완료는 완료 marker 전에 출처 퀘스트 id를 가진 미개봉 꾸러미 하나를 저장한다. 중간 종료 뒤 재시도해도 기존 꾸러미를 재사용해 중복 지급하지 않는다 (`8a34f81`).

### 사랑방 보상 수령 서비스 (2026-08-04)

- [x] `DecorationRewardService`가 퀘스트별 결정적 세 후보, 이미 보유한 장식 제외, journal-first 수령·복구, 더블 탭 직렬화를 맡는다. `pendingBefore` 전체 스냅샷과 `prepared → queue_commit_started` 단계로 중간 종료 뒤에도 첫 상자 하나만 소비하고 뒤에 추가된 상자를 보존한다 (`f60662c`).
- [x] 새 퀘스트 완료가 보자기 상자를 넣는 생산 경로도 `DecorationRewardService.ensurePendingBoxForQuest`를 거쳐 수령과 같은 직렬 큐를 사용한다. 따라서 수령 중 뒤늦게 완료된 퀘스트의 상자가 소비 write와 경합해 유실되지 않으며 unknown source는 새로 저장하지 않는다 (`ee688e1`).
- [x] 원래 세 후보가 모두 보유된 경우에만 같은 결정적 순환 풀의 다음 미보유 후보로 이어지고, 풀 11종을 모두 모은 상자는 명시적 보관 처리로 첫 상자 하나만 소비한다. v1 장식 journal은 계속 읽고, v2는 보유 스냅샷을 기록해 대체 후보·보관 처리도 재시작 뒤 안전하게 복구한다 (`2124dcb`).

### 사랑방 슬롯 렌더 무결성 (2026-08-04)

- [x] 손상/구버전 저장값이 장식 카테고리와 맞지 않는 슬롯을 가리키면 RoomLayer가 해당 장식을 렌더하지 않도록 fail-closed 처리했다. 실제 위젯 회귀로 호환·비호환 경우를 고정했다 (`9a5f5e4`).

### 사랑방 보유 장식 동기화 (2026-08-04)

- [x] `ownedDecor`를 root backup의 `progress.owned_decor`로 저장·복원해 기기 교체/계정 병합에서 합집합으로 보존한다. 고유 보상 id와 충돌 정책이 없는 미개봉 꾸러미·슬롯 배치는 동기화 범위에 넣지 않았다 (`6d5d186`).

### 사랑방 배치 동작 서비스 (2026-08-04)

- [x] UI와 분리된 `RoomPlacementService`가 손상된 배치 정규화, 슬롯별 후보 계산, 보유·카테고리·중복 검증, 저장을 맡는다. 이후 어떤 화면도 raw Storage API를 직접 조합할 필요가 없다 (`1d5a754`).

### 사랑방 슬롯 배치 UI (2026-08-04)

- [x] `SarangbangScreen`과 `SlotPickerSheet`가 `RoomPlacementService`를 통해 슬롯 선택·배치·명시적 비우기를 제공한다. 닫힘(`null`)과 비우기 sentinel을 분리하고, 빈 슬롯 표식도 실제 후보 계산과 같은 규칙을 쓴다 (`9678510`).
- [x] 사랑방 UI의 ARB 키는 `flutter gen-l10n`으로 재생성해 공통 `AppL10n` 인터페이스 안에 선언되도록 복구했다 (`4391f80`).
- [x] 사랑방 화면의 새 텍스트는 공통 `SoriTextTheme` 프리셋으로 수렴해 전역 `w800`·Pretendard 래칫을 늘리지 않는다 (`4f3e83`).
- [x] 보상 꾸러미 개봉 UI: 묶인 보자기 → 후보 3개 → 선택 → 사랑방 CTA를 서비스 API만으로 연결했고, 연습 허브·사랑방에서 도달 가능하다 (`aec2846`). 실제 장식·보자기·빈 사랑방 에셋이 제공되면 화이트리스트와 함께 연결한다.
- [x] 전체 장식 수집 완료 보관 처리 UI: `collectionComplete` 상태를 DE/EN 안내와 명시적 보관 CTA로 연결하고, 마지막 장식 수령 뒤에도 다음 완주 꾸러미를 열 수 있게 했다 (`695e548`).
- [x] 전역 analyzer의 잔여 `_magpiePerched` dead 상수를 제거했다. 런타임 자산 선택은 건드리지 않았으며 `dart analyze` 0 issues와 마스코트·반응형 회귀 332개를 통과했다 (`de7f615`).
- [x] 색상 마커·흰 캔버스가 없는 3:4 불투명 사랑방 배경을 실제 경로에 반영했다. 기존 슬롯 좌표를 위한 좌측 2단 벽감·상단 횃대·빈 중앙 벽/바닥·우측 창 구성을 유지하며 관련 회귀 32개를 통과했다 (`78fc96d`).
- [x] 닫힌/열린 보자기 짝을 실제 `Format32bppArgb` PNG로 반영했다. 기존 흰 캔버스·수채화 외곽선 대신 공통 조각보 패턴과 투명 여백을 쓰며 꾸러미·무결성 회귀 12개를 통과했다 (`d5e3ecc`).
- [x] P1 실제 에셋 반영: 반려된 다운로드 묶음은 로컬 격리본으로 보존하고, 새 Faceted Minhwa 9종(3:4 빈 사랑방 1·RGBA 보자기 2·RGBA 실내 장식 6)을 실제 경로에 반영했다. 화이트리스트 6줄과 asset `pending` 3줄을 함께 갱신했으며, 갓·부채는 같은 횃대 보상 안에서 서로 닿지 않는 독립 전시로 수정했다 (`78fc96d`, `d5e3ecc`, `9b16bad`).

### 개인 한옥 채 짓기·내부 꾸미기 (P2–P4, 2026-08-04)

- [x] P2 구조 설계: 한옥은 `오늘의 다음 학습`을 공간으로 여는 한 개의 개인 성장 세계다. Home → 사랑방 학습 허브 → 기존 학습 표면의 원래 진입 경로를 보존하고, `/sarangbang/furnish`는 P1 수집·배치를 맡는다. 정본은 `docs/superpowers/specs/2026-08-04-living-hanok-learning-world-design.md`다.
- [x] P2a: 기존 `hanok_compound/` 프로토타입은 사용자 검수에서 반려되어 그대로 동결한다. 새 개인 전용 `personal_hanok_v2/`의 넓은 전통 종가 한 카메라(북쪽 위·동서 지붕 수평·상단 좌광)와 고밀도 Faceted Minhwa 에셋 9종을 반영했다. Gye 파일·진행·저장소는 직접 재사용하지 않으며, 개인 후원은 연못·다리·정자·장독대·등을 한 레이어로 보존해 다리가 물 위를 가로지르는 관계를 고정한다 (`bddc25a`).
- [x] P2b: `LevelRatios`만 읽는 pure `PersonalHanokProjection`·구조/조경 카탈로그·개인 전용 맵 레이어의 데이터 계약을 테스트 우선으로 구현했다. 7개 건축 milestone과 개인 후원 레이어의 순서·자산 루트·Gye/구 프로토타입 차단을 고정했고, 레거시 마당도 스크롤 가능한 유한 4:3 viewport로 안전하게 렌더하는 개인 지도/세계 화면을 추가했다 (`4b411f3`, `bddc25a`, `caa1cbb`).
- [x] P2c: `/hanok` 화면·라우트·학습 경로 CTA를 연결했다. 사랑채는 기존 `recommendMission`의 결과만 실행하는 `/sarangbang` 학습 허브로, 꾸미기는 `/sarangbang/furnish`로 분리했다. 대청·행랑·안채·후원·사당은 기존 학습/기록 표면으로 연결하며 Gye 길은 비상호작용으로 남긴다 (`0e30709`).
- [x] P2d: 308–1280dp 및 시스템 글자 1.3x의 반응형·접근성·상호작용 회귀를 고정했고, 앱 시작 시 portrait-only 제한을 해제해 phone·foldable·tablet의 네 방향을 허용한다. 새 한옥 세계·사랑방 학습·꾸미기 화면도 같은 matrix와 smoke gate에 포함했다 (`73693a4`).
- [x] P3: 배치를 `surfaceId + slotId → decorationSlug`로 확장해 안방·대청마루 내부를 추가한다. 현재 사랑방 배치는 안전하게 보존/읽기 마이그레이션한다 (`88c8564`).
- [x] P4a: 개인 한옥 지도에서 계를 개인 구조물로 섞지 않고 기존 공동 계 허브로 연결한다 (`d548032`).
- [x] P4c: 한옥·사랑방·실내·계 진입 CTA는 이미 있는 지도/카드 문맥을 유지하고 버튼 자체는 텍스트 우선으로 수렴했다. 중복 아이콘 다섯 개를 제거해 작은 폭의 라벨 가용 공간을 회복했고, 전체 Flutter 회귀 2,029개와 타이포그래피 가드를 통과했다 (`8d5ca97`).
- [x] P4b: 개인 장식의 계 헌납은 **소유권 이전이 아닌 공동 전시 헌정**으로 구현했다. 서버 callable·App Check·Firestore direct-write 차단·단조 tombstone·membership epoch·정리 경로를 갖추고, 개인 `ownedDecor`·방 배치·보상 journal은 전혀 옮기거나 수정하지 않는다 (`7061ab9`). 실물 이전은 서버 정본 inventory와 통합 journal을 선행하는 별도 P4b-II다.

### 한옥 세계 UX 정본 재구성 (2026-08-05)

- [x] 개인 한옥을 새 학습 엔진이 아니라 기존 추천·70% 성취·보상·계 도메인을 장소감 있게 여는 정본 경험으로 재설계했다. 최신 `main`에서 독립 브랜치 `merkmal/hanok-world-system-design`을 열었고, 명세와 테스트 우선 실행 계획을 추가했다.
- [x] P0: 지도 그림과 hit target을 분리해 안채/대청 겹침을 제거하고 접근성 장소 목록을 추가했다. 308dp에서 44dp 최소 터치 영역까지 실제 렌더 사각형을 전수 대조한다.
- [x] P1: Home과 사랑방이 동일한 read-only TodayLearningSnapshot을 사용하게 한다. 추천 우선순위와 원래 학습 목적지는 바꾸지 않고, Home은 사랑방 진입만 제공한다 (`0c8a564`).
- [x] P2: Home을 “오늘의 마당”으로 정리하고 WorldMapViewport·읽기 전용 venue scene을 반영한다.
  - [x] P2a: Home의 추천 CTA를 사랑방 맥락 하나로 수렴하고, 숨은 호랑이 탭을 제거했다. Home은 순수 한옥 투영을 읽기 전용으로 미리보며 308–1280dp·태블릿·1.3x 글자 회귀를 통과했다 (`a4b3411`).
  - [x] P2b: 지도는 실제 phone 화면폭에서 full-bleed viewport와 선택 후 상세 패널을 제공하고, 작은 화면의 최소 44dp target이 서로 겹치지 않게 고정했다 (`11cdd69`).
  - [x] P2c: 사랑방 학습 화면에서 배치된 실내를 읽기 전용 scene으로 보여주고, 꾸미기 화면의 write 경계를 유지한다 (`47edaa1`).
- [x] P4b-a: 공동 계 마당의 전시 장식을 서버 문서만으로 fail-closed 파싱·정규화·수동 렌더링한다. 개인 소유·방 배치·보상에는 접근하지 않는다 (`7e9aa60`).
- [x] P4b-b: 공동 전시 선택·확인 UI는 개인 보유 장식을 편의상 필터링하되, callable + 서버 stream만 사용한다. 개인 소유·방 배치·보상 journal에는 쓰지 않는다 (`3325d53`).
- [x] P4b-MVP: 개인 소유권을 옮기지 않는 callable-only 공동 전시 헌정을 구현했다. `uid + membershipId + joinedAt(seconds,nanoseconds)` 세대, active/withdrawn tombstone, bounded receipt ledger, leave/ban/account/Gye cleanup을 포함한다 (`7061ab9`). 실물 헌납은 서버 정본 inventory/tombstone으로 별도 단계다.

### 사선형 개인 한옥 정본·장소 맥락·해금 연출 (2026-08-05)

- [x] 개인 지도 런타임 정본을 `personal_hanok_v2/map` 9장(바탕·구조 6·후원·완성 QA 참조)으로 고정했다. `hanok_compound/`와 `gye/` 파일은 카메라/캔버스가 달라 개인 지도에 섞지 않으며, 후원은 연못·다리 관계를 보존하는 단일 레이어로 남긴다.
- [x] Flutter의 비재귀 asset 등록 문제를 해결해 중첩 `map/structures`·`map/landscape`와 실내 폴더를 실제 번들에 포함했다. 완성 참조 이미지는 런타임 paint 순서의 exact composite로 재생성하고, canvas·alpha·chroma-key·픽셀 일치 검사기로 고정했다.
- [x] 구조물 alpha bounds를 카탈로그에 기록하고, 실제 보이는 행랑채/후원 기준으로 탭 영역을 보정했다. 308dp에서 44dp 확장 뒤 서로 다른 장소 target이 겹치지 않는 회귀를 추가했다.
- [x] 안채·대청·행랑채·후원·사당은 새 콘텐츠/저장 write 없이 기존 목적지를 고르는 장소 맥락 시트로 연결했다. 사랑방은 여전히 기존 추천 엔진이 고른 다음 학습으로 직접 진입하며, 후원은 과거 `/daily` fallback 대신 오늘의 글자 시트/퀘스트 선택을 통과한다.
- [x] `kl_personal_hanok_milestones_seen_v1`은 local visual ledger로만 사용한다. 기존 학습자는 첫 지도 방문에서 현재 건물을 조용히 baseline하고, 그 뒤 새 milestone만 목재·먼지·단청 reveal로 한 번 보여 준다. reduce-motion에서는 정적 확인 CTA로 대체한다.
- [x] 768×576 초기/중간/완성 golden 3장과 asset-bundle·reveal-store·venue-sheet 회귀를 추가했다. 정본 계약은 `docs/PERSONAL_HANOK_CANONICAL_ASSET_CONTRACT.md`, 실기기 수용 절차는 `docs/HANOK_MAP_DEVICE_QA_2026-08-05.md`에 기록했다.
- [ ] Jin 실기기: Galaxy Tab·Xiaomi Pad에서 세로/가로·글자 1.0/1.3·초기/중간/완성 지도 탭·후원 다리·reduce-motion reveal을 확인한다. 자동 테스트가 이 수용 검사를 대체하지 않는다.
- [x] 구현은 `main`에 반영 완료다 (`b8b5ae8 feat(hanok): add oblique estate world`). 작업 브랜치 `merkmal/hanok-oblique-world`는 병합 후 삭제됐다 — 이 항목이 `[~] 미커밋`으로 남아 있어 "한옥 작업이 사라졌다"는 오해를 만들었다(2026-08-06 정정).

### 플러그인·Android 배포 호환성 (2026-08-05)

- [x] 안전한 일괄 업데이트: FlutterFire 4/6 세대, App Check 0.4, 공유·미디어·구매·Rive·패키지 메타데이터와 Google Services/Crashlytics Gradle 플러그인을 함께 올렸다. App Check provider API와 Share Plus 13 호출도 새 계약으로 옮겼다. Google Sign-In은 계정 링크·삭제·복구의 인증 흐름 자체가 바뀌는 7.x 대신 최신 호환 6.3.x로 유지했다.
- [x] 검증·통합: App Check/계정 경계 targeted 79개, 전체 Flutter 2,087개, `dart analyze --fatal-infos`, Web release, 서명 AAB(`2.0.4+10`)까지 통과했다. 플러그인 변경 `0324642`와 검증 기록 `8e911d1`을 main에 fast-forward했고, 새 의존성 해석 뒤 main 전체 Flutter serial suite exit 0과 main 기준 서명 AAB 재생성까지 확인했다.
- [ ] 외부 플러그인의 Built-in Kotlin 이행: 최신 버전에도 `cloud_functions` 등 10개가 Flutter 미래 호환 경고를 남긴다. 앱 Gradle/Kotlin 설정을 임의로 우회하지 말고 각 upstream release에서 이행되면 별도 유지보수 묶음으로 재검토한다.

### 계정·전체 데이터 삭제 복구 (2026-08-04)

- [x] 실패한 원격 계정 삭제 journal(`operation == null` 또는 retryable)을 `deletionRemotePending`으로 분리하고, Settings에서 같은 요청을 재시도할 수 있게 했다. Reset과 새 삭제 시작은 journal이 끝날 때까지 계속 잠긴다.
- [x] 회귀 검증: pending/비재시도 journal 분기, Settings 잠금, Retry callback을 테스트로 고정했다 (Flutter 153, Node runtime 81).
- [ ] Jin 운영: 현재 Android 설치본의 App Check를 정상화한 뒤 재시도하고 Cloud Logging에서 `app=VALID` 및 삭제 작업 생성 여부를 확인한다. Debug면 새 기기 debug token 등록, release면 Play Integrity와 서명·배포 경로를 확인한다.

### v2.0.1 릴리스 후보 (2026-08-01)

- [x] 정적·회귀 게이트: `flutter analyze` 0 issues, `flutter test` 1,293 통과, 캐릭터 MP4 매트 16/16 통과
- [x] 서명 산출물: release AAB/APK 재생성 및 패키지 `com.sujinarin.ko_lernen_app` `versionCode=6` 확인
- [~] Redmi M2101K6G 물리 검증: debug 서명 불일치로 안전한 업데이트가 거부된 뒤, debug 앱 제거까지 완료. release 설치는 MIUI의 `INSTALL_FAILED_USER_RESTRICTED` 승인 대기
- [ ] USB 설치 승인 뒤 cold-start·영상 경로·logcat 확인
- [x] 소스 후보 범위 커밋: `eda4c375dd3a06ef422e90ae0ab4dba3c5f8dbaf`
- [x] SSoT 기록·원격 푸시: `0e3ad8f7d8a1ab3c84bb5013e059b4f438055421`까지 완료 (최신 산출물 매니페스트는 아래 세션 로그에 기록)

### 캐릭터 MP4 매트 정규화 (2026-08-03)

- [x] 신규 미배선 클립 `tiger_magpie_play.mp4`의 near-white 매트(`#F7F7F7`, 5% 적격)를 프로젝트 표준 규격인 960²/24fps/H.264 High/yuv420p/CRF19/faststart/무음으로 재출력했다. `lutrgb`의 `>240 → #FFFFFF` 정규화 뒤 매트 검사 121프레임 모두 순백·100%로 통과했다.
- [x] 원본은 번들 제외 백업 `assets_unused/clip_matte_backup_2026-08-01/tiger_magpie_play.near-white.original.2026-08-03.mp4`에 보존했다. 전용 Flutter 매트 테스트 5/5도 통과했다.
- [x] 변환 과정의 바이트 동일 임시 중복 `_stage_play_v2.mp4`는 character 번들 디렉터리에서 제외하고 같은 백업 경로로 이동해 전수 리포트의 18개 클립 목록을 유지했다.

### 레벨 연동형 실전 한국어 커리큘럼 (2026-08-02) — 구조·트리거·전 레벨 재연결 및 A1 생활 시나리오 확장, main 병합

- [x] `CourseUnit → Concept → ContentLink` 그래프와 `FormFamily`·`SurfaceForm`·`MasteryEvidence` 계약, 콘텐츠 기준선 매니페스트 및 명시적 안정 ID를 추가했다.
- [x] 배치 레벨·현재 코스 위치·라이브러리 탐색 레벨을 분리하고, 70% 개념/시나리오 체크포인트 해금과 조사·말투·활용 오답 보정 큐를 기존 단어 SRS와 병행한다.
- [x] 홈 첫 CTA·학습 경로·온보딩 직접 선택/8문항 추천 진단을 현재 코스 미션에 연결했다. A1의 인사/한글 병행·자기소개/입니다·주제/주어 조사·주문/을·를 4개 파일럿을 실제 게임·시나리오 증거와 연결했다.
- [x] Phase 5: A1 16개 미션의 체크포인트에 A1 시나리오 13개를 배치했다. 수업 첫 만남·전화/메신저·배달 주소 확인·되묻기·호칭/거리 조절·병원/안전의 6개 현실 시나리오를 더하고, **모든 A1 시나리오**에 조사/활용 보정과 직접 산출 퀘스트를 연결했다.
- [x] Phase 6: 145개 스몰토크 모두에 상대/관계·안전한 대안 질문·다음 턴을 추가했다. A2의 `할까요? / 할래요? / 하자 / 할래?` 관계별 예문을 넣고 화면에서 관계와 안전한 대안을 확인할 수 있게 했다.
- [x] Phase 7: B1 6개·B2 6개 코스 미션 모두에 명시적 시나리오 평가 링크를 배치해, 기존 상위 레벨 콘텐츠를 이유·간접화법·완곡함·공식 말투 선택으로 재연결했다.
- [x] 최종 자동 검증: `dart analyze` 0 issues, 기능 브랜치 `flutter test --no-pub --concurrency=1` **1,479 통과**, 최신 `main` 병합 상태 **1,496 통과**, `git diff --check` 통과. 브라우저에서 캐릭터 선택 → 레벨 직접 선택·진단 진입 → 홈 `Jetzt lernen` → A1 첫 미션까지 확인했다.
- [~] 새 원문을 추가/배포하기 전에는 자동 검수와 별도로 한국어 화자가 자연스러움·관계 적절성·문화 맥락·받침/활용 정확성을 최종 검수한다.
- 기능 커밋: `49ce0a3`; 로컬 `main` 병합, 원격 푸시 없음.

### 학습 진도 흐름 안정화 (2026-08-03) — main 통합·원격 푸시 승인

- [x] `CoursePracticeContext`로 코스 미션에서 연 문법·스몰토크 화면의 원본 `ContentLink`·미션·콘텐츠 종류를 끝까지 전달하고, 위조·종류 불일치·이미 지난 미션 맥락은 fail-closed 처리한다.
- [x] 문법은 예문→패턴의 실제 선택 후에만, 스몰토크는 관계 선택 후에만 정확히 하나의 `assess` 개념 증거를 남긴다. 화면 방문·카드 뒤집기·TTS·답변/가이드 열람·자유 라이브러리 진입은 해금 증거가 될 수 없다.
- [x] 동적 문법 매핑 88개는 명시적 단일 개념 `assess`로 정규화했다. 스몰토크 카테고리 72개는 범위 안내 `practice`로만 두고, 관계 정답을 신뢰할 수 있는 `smalltalk_a2_0015`·`smalltalk_a2_0022`만 `speechStyle` 평가로 등록했다. 단일 문법 카드 미션은 오답 선택지 추가 전까지 학습 전용이다.
- [x] 70%는 현재 계약대로 같은 미션의 코스 적격 개념 시도 정확도이며, 직접 채점된 정답 1회는 그 표본의 100%다. 시나리오 체크포인트도 각각 70% 이상이어야 다음 미션이 열린다.
- [x] 핵심 회귀 48개, `dart analyze --fatal-infos`, `git diff --check` 통과. 전체 직렬 `flutter test`는 기존 account 구간 뒤 Flutter 컴파일러 무진행으로 중지했으므로 통과로 주장하지 않으며, 깨끗하고 비동시적인 릴리스 세션에서 재실행한다.
- [ ] 새 스몰토크 문구를 평가로 승격하거나 단일 문법 카드에 선택지를 추가하기 전 한국어 화자 콘텐츠 검수.
### 데이터 안정성·동기화 (2026-08-03) — CourseMastery v2 정본·계정/클라우드 병합·iOS/Web Firebase 코드 준비, main 통합·원격 푸시 승인

- [x] `kl_course_mastery_v2`/`version: 2`를 카탈로그 검증 정본으로 두고, v1·placement/current-unit mirror는 읽기 전용 마이그레이션 입력으로만 처리한다. canonical-first 기록 실패 시 mirror·browse 상태를 바꾸지 않는다.
- [x] 완료·우회·증거·시나리오 체크포인트는 stable ID 기반의 typed·결정론적 병합을 사용한다. placement 충돌은 자동 선택하지 않고 typed conflict로 멈추며, 현재 유닛은 카탈로그에서 재계산한다.
- [x] 정상 CloudSync 백업과 계정 교체 캡처도 UI 진입 전 v1/scalar 코스 상태를 카탈로그 검증·v2 승격 후 `course_mastery_json`으로 다룬다. malformed/future/catalog-invalid 입력은 원본을 덮어쓰지 않고 fail-closed 한다.
- [x] 계정/클라우드 적용은 기존 CAS·CloudWriteSession·로컬 canonical generation fence를 유지하고, 계정 삭제 Cloud Function allowlist에 `course_mastery_json`을 포함한다.
- [x] Web App Check는 빌드 환경 `FIREBASE_WEB_APP_CHECK_SITE_KEY` 주입 seam만 사용하며, 키가 없으면 주·임시 Firebase 앱 모두 보호된 호출 전 fail-closed 한다. Android/Apple provider 동작은 변경하지 않았다. iOS/Web 실제 Firebase·Apple 설정은 운영 런북으로 분리했다.
- [~] Firebase Console의 iOS/Web 앱 등록·FlutterFire 생성값·`GoogleService-Info.plist`·Auth 도메인·reCAPTCHA/App Check·Apple 서명/Sign in with Apple/APNs 및 macOS/실기기 검증은 운영 권한이 필요해 별도 수행한다.
- [x] **현재 main 통합 검증:** `dart analyze --fatal-infos` 오류 0, 직렬 `flutter test --no-pub --concurrency=1` **1,662 passed**, `node --test functions/gye/cloud_backup_deletion_runtime.test.js` **17/17**, `flutter build web --release` 성공 및 `git diff --check` 통과. Web Wasm dry-run의 `flutter_tts` 경고는 빌드 실패가 아니며, 실제 Web 배포에는 `FIREBASE_WEB_APP_CHECK_SITE_KEY` 주입이 필수다.
- [x] **통합 게시:** 병합 커밋 `f209290`이 코스 체크포인트 흐름(`cb66d4f`)과 데이터 안정성·동기화(`84537c2`/`87c214f`)를 함께 보존해 원격 `main`에 게시됐다. 게시 직후 `main == origin/main`, ahead/behind `0/0`, 작업 트리 clean을 확인했다.

### (이하 2026-05 히스토리 — 대부분 완료/대체됨)

### ★ "살아있는 한옥" UI/UX 대개편 (승인된 계획)
> 정적 "상자 더미" → 모션·깊이·캐릭터가 살아 움직이는 한옥. 컨셉(단청+한옥+호랑이/까치)은 유지.
> 전체 plan: `~/.claude/plans/claude-code-ko-leren-app-glimmering-storm.md`

- [x] **Phase 0** — 토대 안정화 (`flutter analyze` 0) + `flutter_animate` 모션 패키지
- [~] **Phase 1** — 솟을대문 시네마틱 인트로 (코드 완료 · 시각 검증 미완)
- [ ] **Phase 2** — 살아있는 한옥 환경 (홈=마당, ambient 모션) — *동시 세션 진행 중*
- [ ] **Phase 3** — 호랑이·까치 마스코트 생명력 (포즈 기반 2D 애니메이션)
- [ ] **Phase 4** — de-box + 모든 상호작용 생명력 (스프링·축하·물리 전환)
- [ ] **Phase 5** — 60fps 보증 + GitHub Actions CI

### 출시 폴리시 (2026-05-22 Week 1–4 완료)
> plan: `~/.claude/plans/hangul-sori-temporal-wombat.md`

**Week 1 — 접근성 + 모션 일원화 + 토큰**
- [x] 모든 Sori 위젯에 `Semantics` 적용 (button, chip, card, pressable, badge, mascot)
- [x] `SoriColors.primaryOnLight = primaryDark` 토큰 (≥7:1 대비, AA 통과)
- [x] `intro_gate_screen.dart`의 하드코딩 `_black`/`_white` → `SoriColors.darkBg`/`lightBg`
- [x] `flutter_animate` 패키지 완전 제거 + `app_error.dart`의 `.animate()` 호출을 `SoriEntrance` + 인라인 `_BreathingTransform`으로 재작성
- [x] `SoriMotion.reduceMotion(context)` 헬퍼 추가 — 4개 모션 위젯 reduce-motion 대응
- [x] `SoriTextTheme` 신규 (display/h1/h2/h3/body/bodySmall/caption/label, Pretendard 통일)
- [x] `HanokColors.cheongMuted/jeokMuted/hwangMuted` muted 변형 추가
- [x] `Mascot` 위젯 Semantics (`label: '호랑이 마스코트, 상태: $emotion'`)

**Week 2 — 빈/오류 상태 + 헤더 슬롯**
- [x] `SoriEmptyState` 위젯 신규 (asset + title + body + CTA + secondary)
- [x] `HanokHeader` 위젯 신규 (10:3 wide, gradient fallback)
- [x] 5개 빈/오류 상태 통일: 시나리오 B2 잠금 (`sleeping_tiger_b2.png`) · 단어장 due 완료 (`celebrate_complete.png`) · 통계 첫 진입 (`study_room_waiting.png`) · 설정 오프라인 (`offline_lantern.png`) · 시나리오 로드 실패 (`lost_magpie.png`)
- [x] Settings 헤더 (`scholar_room.png`) + Stats 헤더 (`achievements.png`) 통합
- [x] DE/EN ARB에 10개 빈/오류 키 추가

**Week 3 — 모듈 폴리시**
- [x] **Chosung 라운드 요약** — 10문제 단위 round 추적, 라운드 종료 시 정확도% + 평균 시간 + 레벨 추천 카드 (`_RoundSummaryCard` private 위젯)
- [x] **Wordle 키보드 폴리시** — 결과 카드에 `Focus(autofocus: true, onKeyEvent: ...)` → Enter/Space로 새 단어. 입력 자동 재포커스 (브라우저 IME가 한글 합성 처리)
- [x] **시나리오 백드롭** — `_backdropKey` getter (scenario ID → scene 키 매핑) + `assets/illustrations/scenes/{key}.png` opacity 0.08 백그라운드 + errorBuilder fallback (Jin이 PNG 만들기 전에도 정상 동작)
- [ ] **Hangul IoU 정확도 측정** — 캔버스 stroke vs ghost letter mask 비교, 80%+ 시 celebrate 팝업. 캔버스 구조 복잡도 때문에 출시 후 1차 업데이트로 이월

**Week 4 — 출시 자료 (모두 `docs/store/`)**
- [x] `docs/store/README.md` — Pre-submission 체크리스트 (Play Console + App Store Connect)
- [x] `docs/store/listing-de.md` — DE 짧은 설명(78자) + Promo(168자) + 전체 설명(~2950자) + Release Notes
- [x] `docs/store/listing-en.md` — EN 동일 + Apple Keywords(94자, 100자 한도 내)
- [x] `docs/store/data-safety.md` — Play Data Safety + Apple App Privacy 답변 (Firebase Anonymous + 옵션 Google Sign-In, 광고 없음 가정)
- [x] `docs/store/screenshot-shotlist.md` — 8슬롯 캡쳐 가이드 (어떤 state로 어떻게)
- [x] `docs/store/release-notes-v1.md` — v1.0.0 DE/EN

**Privacy URL**: `https://hangul-sori.com/privacy.html` (기존 `docs/privacy.html` + `docs/CNAME` 활용)

### v1.0.0 출시 준비 (2026-05-25 — 2주 plan)
> 전체 plan: `~/.claude/plans/snappy-conjuring-lemur.md` — 5 트랙 (자산정리·신규PNG·코드·콘텐츠·검증) + 부록 A에 PNG 18장 상세 스펙

**Track A — 자산 정리 (✅ 완료, 2026-05-25)**
- [x] hanok/ 중복 마스코트 7장 + 미참조 5장 + icon-512 삭제 (~17MB 절감)
- [x] `assets/illustrations/scenes/`, `empty/`, `error/` 폴더 생성 + pubspec 등록
- [x] feature-graphic.png → `docs/store/feature_graphic_v1_draft.png` 이동

**Track C — 코드 구현 (✅ 완료, 2026-05-25)**
- [x] `Mascot` 위젯 emotion enum에 `thinking` 추가, magpie worry/sleepy 매핑
- [x] `/listening` 화면 신규 — `ListeningScreen` (TTS dialog 재생 + 자막 토글 4모드 + 속도 3단계 + 진행/완료 카드)
- [x] `/kkeunmari` 화면 신규 — `KkeunmariScreen` + `KkeunmariEngine` 서비스 (chain 검증, 30s 타이머, dead_end 처리, XP 보상)
- [x] 홈 화면 카드 4종(Chosung/Wordle/Kkeunmari/Listening) 2×2 grid
- [x] Vocab/Grammar banner path → 신규 `study_classroom.png`/`study_scholar.png` (없으면 study.png fallback)
- [x] Wordle 게임판 단청 frame Container + 4코너 단청 dot + 결과 카드 mascot (까치 celebrate / 호랑이 worry)
- [x] Chosung 라운드 종료 → 정확도별 mascot (≥80% celebrate + 별 burst / 50-79% surprised / <50% worry)
- [x] DE/EN ARB에 listening 18키 + kkeunmari 19키 추가, gen-l10n 성공
- [x] `flutter analyze` 0 issues · `flutter build apk --debug` 통과

**Track B — 신규 PNG 자산 (Jin, 진행 중)**
- 전체 18장 스펙은 plan 부록 A 참조. 모두 errorBuilder fallback이 동작하므로 누락 상태에서도 빌드 정상.
- `docs/store/gate_decomposition_prompt.md` 작성 — gate.png 기반 3-layer animation prompt 생성
- 핵심 우선순위: ① 시나리오 백드롭 5장 (`scenes/`), ② 빈/오류 5장 (`empty/`+`error/`), ③ 헤더 6장 (`hanok/scholar_room`, `achievements`, `study_classroom`, `study_scholar`, `listening_hero`, `kkeunmari_hero`), ④ 마스코트 4장 (`mascot/tiger_thinking/neutral/sleepy`, `magpie_worry`), ⑤ feature graphic 1024×500.

**Track D — 콘텐츠 작성 (✅ 핵심 완료, 2026-05-27)**
- [x] B2 시나리오 3개 (`business_meeting_intro`, `complaint_delivery`, `doctor_consultation`) — 원어민 DE/EN 전면 교열 후 확정
- [x] 일상 시나리오 5개 신규 추가: `taxi_street` [A2] · `plans_with_friend` [A2] · `running_late` [A2] · `postpone_plans` [B1] · `cancel_plans` [B1]
- [x] `assets/data/scenarios.json` 13 → 21개 (A1×6, A2×7, B1×5, B2×3)
- [x] `docs/store/b2_scenarios_draft.json` 최종본 커밋
- 끝말잇기 풀은 v1 그대로 충분 (225 단어)
- 듣기는 시나리오 dialog 재사용 — 별도 콘텐츠 불필요
- [ ] optional: `apartment_viewing`, `job_interview` B2 2개 (백로그)

**Track E — 검증 & 출시 자료 (남은 작업)**
- [ ] **Data Safety 답변 확정** — `docs/store/data-safety.md` 끝의 "Open questions": Crashlytics/Analytics/AdMob이 release build에 포함되는지 확인
- [ ] **실기기 시각 검증** — Android 1대 + iPhone 1대에서 전 화면 진입, light/dark 둘 다 (특히 신규 `/listening`·`/kkeunmari`, Wordle 단청 frame, Chosung mascot, Vocab/Grammar banner fallback)
- [ ] **신규 PNG 적용 후 스크린샷 8슬롯 캡쳐** (Track B 일부 PNG 들어오면 재캡쳐)
- [ ] **Release notes 업데이트** — "신규 듣기 모드 + 끝말잇기 + B2 시나리오"

**🟡 출시 후 1차 업데이트 (v1.0.1) 후보**
- Hangul IoU 정확도 측정 (출시 전 deferred)
- Listening 받아쓰기 미니퀘스트 (현재는 step별 재생만)
- Kkeunmari 레벨 필터 (현재 단일 모드)
- 마스코트 추가 포즈 (tiger_thinking/neutral/sleepy + magpie_worry) — Jin이 만들면 자동 사용
- [ ] **madang(dark) v2** (계획 D5)

**🟢 콘텐츠 백로그 (별개 트랙)**
- [ ] 시나리오 21개 → 추가 양산 (apartment_viewing, job_interview 등)
- [ ] 동기 기반 온보딩 + 5분 코스 (Track C)
- [ ] 끝말잇기 게임 화면 (Track D, 풀 JSON만 있고 화면 없음)
- [ ] 모듈 통합 "Sori Brain" (Track B)

---

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

1. 브랜치 push 완료 확인
2. PR 생성 또는 갱신
3. `.github/workflows/ci.yml` 을 **PR head 브랜치에서 `workflow_dispatch` 로 명시 실행**
   (`workflow_dispatch` 는 자동화가 워크플로를 시작할 수 있는 예외 이벤트다)
4. run 이 **실제로 생성됐는지 확인** (run id 를 확보한다)
5. run 의 결과를 확인 — Analyze · Test · Build web · Book analysis security
6. **run 이 존재하고 결과를 확인하기 전까지 "PR 준비됨" 이라고 보고하지 않는다**

자동 트리거를 기다리며 시간을 보내지 말 것. 안 붙으면 3번을 바로 실행한다.
사람이 UI 에서 직접 만든 PR 은 원래대로 `pull_request` 트리거가 동작하므로 두 경로가 공존한다.

**⚠️ `workflow_dispatch` 로 돌리면 `regenerate-goldens` 잡도 함께 실행된다** (그 잡이
`if: github.event_name == 'workflow_dispatch'` 게이트라서). 아티팩트만 올리고 커밋하지 않으므로
무해하지만, 골든 기준선을 교체할 때는 그 아티팩트가 정본이다.

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
