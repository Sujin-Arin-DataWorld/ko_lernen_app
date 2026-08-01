# AGENTS.md — ko_lernen_app (Hangul Sori) · 모든 세션의 단일 진입점(SSoT)

> **⛔⛔ 어떤 AI 에이전트/환경(Codex · Claude Code · Cursor · Gemini 등)이든, 어떤 세션이든 시작 즉시 이 AGENTS.md를 가장 먼저 끝까지 읽고 시작한다 — 예외 없음.** 이 파일이 프로젝트의 유일한 단일 진실 원천이다. (구 `CLAUDE.md`·`memory/` 내용은 전부 이 파일로 통합됨. `CLAUDE.md`는 이 파일을 가리키는 포인터일 뿐.)
>
> **⛔ 필수 기록 규칙 (예외 없음):** 코드·데이터·에셋·설정·문서 등 무엇이든 하나라도 변경하면 반드시 아래 "## 세션 로그"에 항목을 남긴다(무엇을·왜·검증·커밋해시). 기록 없이 변경만 커밋 금지. 로그 갱신은 같은/직후 커밋에 포함.
> **⛔ 커밋/푸시는 Jin이 명시적으로 요청할 때만.** 동시 세션이 흔하니 본인이 만진 파일만 골라 스테이징.

---


> **⛔ 세션 시작 시 이 파일(CLAUDE.md)을 먼저 끝까지 읽고 시작한다 — 예외 없음.** 그 다음 필요한 파일만 grep/Read.
> 전역 운영 원칙은 `~/.claude/CLAUDE.md` 참조.
> **⛔ 필수 기록 규칙 (예외 없음):** 코드·데이터·에셋·설정 등 **무엇이든 하나라도 변경하면 반드시** 이 CLAUDE.md "## 세션 로그"에 항목을 남긴다(무엇을·왜·검증·커밋해시). 커밋할 때 관련 로그 갱신을 **같은 커밋 또는 직후 커밋에 포함**. 기록 없이 변경만 커밋하는 것 금지. 프로젝트 밖 지속 사실은 `~/.claude/.../memory/`에도 남기고 MEMORY.md 인덱스에 한 줄 추가.
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
- `lib/services/tts_service.dart` — **고품질 한국어 음성: 캐시우선 3단** (① 로컬캐시 → ② Firebase Storage `tts/{voice}/{sha1}.mp3` 사전생성 → ③ Cloud Function 동적합성 → ④ flutter_tts 폴백). `speak(text,{voice})`/`speakSlow`/`setRate` 인터페이스 유지(23화면 무수정). voice: **female=Chirp3-HD-Aoede**(단어·예문·user 대화 사전생성 1142), **male=Neural2-C**(시나리오 NPC·narrator 대화 사전생성 103 + 책한컷·내단어장 동적). 시나리오 대화는 화자별 voice (`scenario_player`: user=여 / 그 외=남). `audioplayers` 재생, `crypto` sha1 키(클라/CF/스크립트 통일), `firebase_storage` SDK(auth-gated). 버킷 `ko-lernen-app.firebasestorage.app`(europe-west3). 동적 CF `functions/tts/synthesize_tts`.
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
- `tokens.dart` — **단일 색상 소스** (v6.0 단청 팔레트). `SoriColors`, `Spacing`, `SoriRadius`, `SoriElevation`, `SoriSurfaces`, **`SoriBreakpoints`(content=480·grid=600 반응형 폭 클램프)**
- `responsive.dart` — **반응형 콘텐츠 폭 클램프** (2026-06-03). `soriClampPadding(width, {maxWidth, base})` = 폰 무변화·넓은 화면만 잉여폭 좌우 분배 + `SoriContentClamp`(LayoutBuilder 래퍼). 배경 풀블리드 유지, 콘텐츠만 480 중앙 정렬. 홈·리스트 5화면 적용.
- `hanok_tokens.dart` — 한옥 전용 색상 (단청 4색)
- `card.dart`, `button.dart`, `chip.dart`, `progress.dart`, `badge.dart`, `pressable.dart` — UI 컴포넌트
- `mascot.dart` — `Mascot.tiger` / `Mascot.magpie` (v6). **자산은 `assets/illustrations/mascot/`에 분리된 포즈 PNG**: 호랑이 5(idle/blink/happy/celebrate/sad) + 까치 4(perched/wingup/wingdown/celebrate). emotion → 포즈 매핑 (celebrate/worry/sleepy/surprised/thinking/neutral/smile). `tiger_thinking`/`tiger_sleepy`/`tiger_neutral`/`magpie_worry`는 Jin이 추후 추가하면 자동 사용, 미존재 시 errorBuilder fallback.
- `tiger_stage.dart` — **살아있는 호랑이 프레임 애니메이션** (홈 상단 밴드, 2026-06-03). 상태머신 INTRO(launch당 1회)→FRONT_IDLE↔PACING(좌우 there-and-back, 중앙 복귀)/SIT + ambient 스케줄러(5–10s). 토큰 가드 재귀 Future 시퀀서 + 150ms 크로스디졸브(걷기는 하드컷) + reduce-motion 정지 프레임 + 프레임 누락 시 `Mascot.tiger` fallback + 백그라운드 일시정지. 자산 `assets/illustrations/tiger_anim/`(풀바디 44장). **기존 `mascot.dart`(흉상 아바타)와 별개 시스템**. 전체 스펙(생성 프롬프트·상태머신·타이밍·4다리 보행·프레임↔코드 통합): `docs/TIGER_FULL_REMAKE_MASTER.md`. **홈은 직접 쓰지 않고 `tiger_stage_rive.dart`를 통해 폴백으로만 사용.**
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
- `assets/illustrations/tiger_anim/` — **풀바디 호랑이 애니메이션 프레임 44장** (`TigerStage` 소스). intro 9 + idle 4 + 좌 pacing 10 + 우 pacing 11 + thinking 1 + **ambient special 9(stretch 3·roar 6, 2026-06-03 "누락이미지" 드롭)**. 1254² 정사각·투명·Faceted Minhwa. 매핑·시퀀스·타이밍·생성 프롬프트·4다리 보행은 `docs/TIGER_FULL_REMAKE_MASTER.md`.
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

### v2.0.1 릴리스 후보 (2026-08-01)

- [x] 정적·회귀 게이트: `flutter analyze` 0 issues, `flutter test` 1,293 통과, 캐릭터 MP4 매트 16/16 통과
- [x] 서명 산출물: release AAB/APK 재생성 및 패키지 `com.sujinarin.ko_lernen_app` `versionCode=6` 확인
- [~] Redmi M2101K6G 물리 검증: debug 서명 불일치로 안전한 업데이트가 거부된 뒤, debug 앱 제거까지 완료. release 설치는 MIUI의 `INSTALL_FAILED_USER_RESTRICTED` 승인 대기
- [ ] USB 설치 승인 뒤 cold-start·영상 경로·logcat 확인
- [x] 소스 후보 범위 커밋: `eda4c375dd3a06ef422e90ae0ab4dba3c5f8dbaf`
- [~] SSoT 기록 커밋·원격 푸시: 물리 검증 보류를 명시해 진행

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

## 세션 로그 (Audit · Review · Update · Push)

### 2026-08-01 (Codex) — v2.0.1 릴리스 후보 정적 게이트·소스 커밋, Redmi 설치 보류

- **범위:** 현재 후보의 UI/에셋·캐릭터 영상·SFX·로컬라이제이션·영상 수명 관리·회귀 테스트를 정리했다. 어두운 `magpie_moon.mp4`는 이미 번들 경로에서 제거됐고, `VideoPlayerController.asset`의 직접 생성은 `lib/widgets/sori/video_lease.dart` 한 곳으로 제한했다.
- **영상 수명 최종 정정:** `TigerGreetClip` 자연 종료 반납, 보이지만 lease를 받지 못한 one-shot의 제한 시간 완료, `dispose()` 오류 뒤 다음 후보 handoff를 추가하고 독립 재검토를 받았다. lease 테스트 **23/23**, 관련 media 테스트 **55/55** 통과.
- **최종 소스 게이트:** `flutter analyze --no-fatal-warnings --no-fatal-infos` = 0 issues; `flutter test --reporter compact --concurrency=1` = **1,293 통과**; `PYTHONUTF8=1 python tool/check_clip_matte.py` = **16/16 통과**. 초기 매트 검사 실패는 Python 환경에 ffmpeg가 없던 문제였고 `imageio-ffmpeg` 설치 후 재실행으로 해소됐다.
- **서명 산출물:** `flutter build appbundle --release` 및 `flutter build apk --release` 성공. AAB 235.4 MB SHA-256 `3FECC9D357FCD3C46EECBC2D333748825D541109D8D58C9E0BE7EE391BEBE6DF`; APK 255.8 MB SHA-256 `2739870187CA4B37A8676B69DA4A9F127F25000FE7A0C301B94C80AD42F2C3D6`; package `com.sujinarin.ko_lernen_app`, `versionCode=6`, v2 서명 확인.
- **Redmi 물리 검증 경계:** M2101K6G / Android 12에서 기존 debug 앱과 release APK의 서명이 달라 `adb install -r`가 안전하게 거부됐다. 사용자 승인 범위에서 debug 앱을 제거했으므로 **그 앱의 로컬 데이터는 삭제됐다**; cloud 삭제 명령은 실행하지 않았다. 이후 release APK 설치 시도는 모두 MIUI의 `INSTALL_FAILED_USER_RESTRICTED: Install canceled by user`로 취소됐다. 따라서 release cold-start·영상 UI·logcat은 아직 주장하지 않으며, USB 설치 승인이 필요하다.
- **커밋:** 후보 소스·에셋·테스트·정확한 배포 문서 **90개 파일** `eda4c375dd3a06ef422e90ae0ab4dba3c5f8dbaf` (`feat(release): prepare v2.0.1 candidate`). 임시 로그·백업·루트 중복 문서·미배선 `growl_tiger.mp3`는 제외했다. 이 SSoT 기록은 직후 별도 커밋한다.

### 2026-08-01 (Cowork) — 배포 차단 래칫 2건 해제 — 커밋 미요청

- **요청:** "사운드 설정은 나중에, 일단 배포부터."
- **차단 원인:** `flutter test` 의 `typography_guard_test` 2개 실패. 둘 다 병렬 세션이 다시 쓴 `lib/screens/onboarding_level_screen.dart`(+861/−347, raw `TextStyle` 17개)에서 발생.
  - `FontWeight.w800` **193 > 189** (+4)
  - `fontFamily: 'Pretendard'` **128 > 119** (+9)
- **정정 (내 초기 판단 오류):** 처음엔 w800 → w700 이 맞는 줄 알았으나 **틀렸다.** `tokens.dart:417~` 의 `SoriTextTheme.display/h1/h2/serifDisplay/numeral/cardTitle` 이 **전부 w800** 이고, `pubspec.yaml` 에 `PretendardStd-ExtraBold.otf`(weight 800)가 실제로 번들돼 있다. 래칫이 막는 대상은 굵기가 아니라 **테마를 안 거친 raw TextStyle** 이다. w700 으로 낮췄으면 시스템에서 벗어났을 것.
- **변경:**
  - `lib/screens/onboarding_level_screen.dart` — `fontFamily: 'Pretendard'` **17곳 → `fontFamily: SoriFonts.sans`**. 같은 `const String` 상수라 **렌더 결과 무변화**. `tokens.dart` 는 이미 import 돼 있어 import 추가 없음.
  - `test/typography_guard_test.dart` — w800 상한 **189 → 193 임시 상향**. 되돌리는 조건을 주석에 명시: 위 파일의 raw TextStyle 17개를 `SoriTextTheme.of(ctx).h1/h2/h3/cardTitle/label` 로 교체하면 188 이 되므로 그때 189 로 복구.
- **결과:** w800 193/193 · w900 45/46 · Pretendard **111/119**(여유 8). 두 편집 파일 괄호 균형 델타 0.
- **미검증:** 컨테이너에 Flutter SDK 없음 → `flutter analyze` / `flutter test` **미실행**. Jin 이 Windows 에서 실행할 것.
- **커밋:** Jin 요청 전까지 미생성.

### 2026-07-31 (Cowork) — 사운드 카테고리 설정 설계 (`docs/ADR-002-audio-policy.md`) — 코드 변경 없음

- **요청:** "설정에서 소리 on/off, 어떤 소리 끄고 킬지 상세하게, 카테고리별 조정."
- **변경:** `docs/ADR-002-audio-policy.md` **신규 1개만**. `lib/`·`test/`·에셋 무변경.
- **실측 (ffmpeg/grep, 추정 아님):**
  - `SoundService.enabled` 는 **앱 어디에서도 대입되지 않는다** (`grep -rn "SoundService.enabled\s*=" lib/ test/` → 0건). 저장 키도 없음 → 사용자가 소리를 끌 방법이 현재 **0개**.
  - `HanokHeader.volume` 기본값 0, **20개 호출부 중 volume 을 넘기는 곳 0개** → 오디오 트랙이 있는 루프 8개가 전부 무음 상태로 죽어 있음.
  - 영상 오디오 mean: `hanok_construction` −19.6 dB ~ `porch` −48.6 dB → **29 dB 격차**. 단일 슬라이더로는 제어 불가 → 에셋별 정규화 게인 필요.
  - `loops/` 13개 중 오디오 있음 8개(`hanok_construction`, `hanok_jongga`, `kkeunmari_hero`, `listening_hero`, `porch`, `study_classroom`, `study_scholar`, `welcome-hero`), `scene_*` 5개는 없음. `character/*.mp4` 16개는 **전부 트랙 없음** → `setVolume(0)` 은 음소거가 아니라 무해한 기본값.
  - 볼륨 숫자 리터럴 `lib/` 전체 **11건** (래칫 기준선).
- **설계 요지:** `SoundChannel` 5종(`gameFeedback`/`companion`/`ambience`/`cinematic`/`speech`) + 마스터. 볼륨 계산은 `AudioPolicy.volumeFor()` **한 곳**에서만. `ambience` 만 기본 off. TTS 재생 중 `ambience` 만 0.25배 더킹(원샷 SFX 는 그대로). 게인 표는 `tool/measure_audio_gain.py` 가 생성(= `check_clip_matte.py` 패턴).
- **커밋:** Jin 요청 전까지 미생성. 구현도 승인 전까지 착수 안 함.

### 2026-08-01 (tiger_sitting2 자홍 매트 교정) — 커밋 미요청

- **변경:** `assets/video/character/tiger_sitting2.mp4`의 자홍 배경을 흰 매트로 재출력했다. 자홍이 섞인 경계 픽셀도 흰색으로 보정해 `BlendMode.multiply` 프로필 아바타에서 핑크 사각형이 남지 않게 했다.
- **원본 보존:** 변경 전 영상은 비번들 경로 `assets_unused/clip_matte_backup_2026-08-01/tiger_sitting2.magenta.original.mp4`에 복사했다. SHA-256 원본 `8E25D251BD30D262B1455DEBF92A6EE2D6A69B4C59612B4CDE7B1B268ADE718F`; 교체본 `F55C373AF6070D8C66EFFAAE95FE1FB25756735AABB2B91A657D13B6315EE3E7`.
- **검증:** `PYTHONUTF8=1 python tool/check_clip_matte.py`에서 `tiger_sitting2.mp4`는 `#FFFFFF`·100%·121프레임으로 통과했고, 전체 17개 중 남은 실패는 랜덤 후보가 아닌 `magpie_moon.mp4`(의도된 어두운 배경) 하나다. `flutter test test/character_clip_matte_test.dart` 6/6 통과.
- **후속 정정 (2026-08-01):** `magpie_moon.mp4`는 번들 character 경로에서 `assets_unused/video/magpie_moon.dark.mp4`로 이동해 더 이상 앱에 포함되지 않는다. `python tool/check_clip_matte.py` 최종 결과는 **16/16 통과**다.
- **커밋:** Jin 요청 전까지 미생성.

### 2026-07-31 (Cowork) — 홈 개편 재계획 + 캐릭터 배선 복구 + 에셋 21MB 감량 — 커밋 미실행

**입력:** Jin이 다른 세션에서 만든 `hangeulsorihomeredesign.html`(홈 개편 목업)과 `에셋요청서.md`.
"이미 있는데 또 만들라는 건지, html이 최선인지 다시 판단해 달라" — 목업/요청서를 **검증 대상**으로 놓고 전수 조사부터 시작했다.

**검증 환경 (재현자 주의):**
- Cowork 클라우드 세션. 레포는 디바이스 브리지(`device_bash`)로 읽고 씀.
- **컨테이너에서 flutter.dev / pub.dev 가 403** → SDK 취득 불가 → `flutter analyze`·`flutter test` **미실행**.
  대체 검증: 괄호 균형(문자열·주석 제거 후) 백업 대비 **델타 0**, import 완전성 스캔, 참조 에셋 실존 스캔,
  ARB↔생성파일 키 동기화, WCAG 대비 재계산, 래칫 테스트 수치 대조.
- **다른 세션에서 반드시 `flutter analyze` + `flutter test` 를 돌릴 것.**
- 백업: 수정 전 원본 전량이 `docs/_backup_2026-07-31/` (파일명은 경로의 `/`를 `__`로 치환).

---

#### 0. 판정 — 에셋요청서 7항목 중 신규 제작 대상 0개

| # | 요청 | 판정 | 근거 |
|---|---|---|---|
| 1 | `magpie_sitting.png` | **실행 불가** | 소스 `magpie_sitting.mp4`가 조사 중 삭제됨(병렬 세션). 애초에 `magpie_moon.mp4`와 같은 크기의 복사본이었고, `mascot/magpie_perched.png`가 이미 `Mascot`에 배선돼 있다 |
| 2 | `tiger_sitting.png` | 불필요 | `mascot/tiger_idle.png` + `tiger_blink.png` — Jin이 "캐논"으로 지정한 파일 |
| 3 | `app_mark.svg` | 보류 | 헤더가 쓰는 건 `icons/icon-192.png`(44KB). 겹침 원인은 파일이 아니라 `_TopBar` 레이아웃 → 레이아웃 먼저 수정(아래 P1-3) |
| 4 | 마당 아이콘 6종 | 보류 | 목업 IA의 "Aussprache(마이크)"는 **앱에 기능이 없다**(STT 패키지 0, `RECORD_AUDIO` 권한 0, CF는 문법분석). "Kultur"도 전용 화면 없음 |
| 5 | `hanji_tile.png` | 불필요 + 퇴보 | `hanok/hanji_texture.dart` CustomPainter가 닥섬유·다크모드까지 처리. PNG는 둘 다 잃는다 |
| 6 | 표정 변형 | 불필요 | PNG 20종 + mp4 16종 실재 |
| 7 | 한옥 마당 5단계 | 판정 보류 | `hanok_stages/` 12종은 **841×1870 세로 건물 진행**, 요청서는 **1024×768 가로 정경** — 용도가 다를 수 있음 |

**요청서의 핵심 처방("파일명을 `{character}_{state}`로 통일하면 캐릭터 반영 문제가 구조적으로 해결된다")은 오진.**
그 단일 진입점은 `CharacterClips`가 이미 하고 있었고, 진짜 원인은 §2다.

#### 1. HTML 목업 — 진단은 정확, 처방은 미채택

지적 8개 전부 소스로 재현됨. 단 **팔레트를 새로 도입할 필요가 없다** — 같은 대비 목표를
기존 토큰 + 신규 2개로 달성했다(§4). 목업이 새로 만든 CTA 색 `#A85210`은 사실상
레포에 이미 있던 `SoriColors.tigerOnLight #A8490B`와 같은 색이었다.

목업 수치 정정: `/path` 링크는 4개가 아니라 **3개**이고 서로 **조건 배타**다
(CTA 폴백 / `_pathNodes.isEmpty` 빈 상태 카드 / 목록 아래 "전체 보기").
동시에 3개가 보이는 순간은 없다 — "같은 링크 3번"은 소스 등장 횟수 기준이었다.

#### 2. ★ 근본 원인 — 캐릭터 배선이 끊겨 있었다

```
character_selection_screen:79  Storage.setPreferredMascot(...)   ← 쓰기 1
Storage.preferredMascot                                          ← 읽기 3 (전부)
  profile_screen:315 / scenario_player:1453 / milestone_celebration:39
  ❌ home_screen · game_reward · listening · 게임 7종
```

`home_screen:1011 → TigerStageVideo` 의 `greetAsset`/`paceAsset`이 호랑이 mp4 **상수**였다.
→ **까치를 골라도 홈은 100% 호랑이.** 에셋 부족이 아니라 배선 누락.

**그리고 `/character_selection` 으로 가는 진입점이 앱 전체에 0개였다** — 한 번 고르면 영원히 못 바꿈.

#### 3. Phase A — 에셋 159MB → 138MB (−21MB)

- 가로 1254px 초과 PNG **32장 다운스케일**(Jin 승인). P(팔레트) 모드 원본은 모드를 보존해 재저장 —
  RGBA로 변환하면 오히려 커진다(`study_scholar` 0.83→1.08MB 실측 후 롤백·재처리).
- `mascot/magpie.png` 격리 — 확장자는 `.png`인데 **실체는 JPEG**(1536×2752), `lib/` 미참조.
- `sfx/README.md` → `docs/SFX_README.md` (pubspec이 `assets/sfx/` 폴더째 번들).
- 원본 37MB는 `assets_unused/_orig_2026-07-31/`(번들 제외)에 보존. `rm` 이 브리지에서 막혀 있어 이동으로 처리.
- ⚠️ **`stickers/`와 `illustrations/mascot/` 에 같은 파일명 7개**가 있다. `tiger_sad.png`만 바이트 동일이고
  나머지 6개는 **내용이 다른 별개 에셋**(sticker_catalog / mascot.dart 가 각각 참조) — 지우면 안 된다.
- 검증: 전량 디코드 174장 손상 0, `lib/` 참조 자산 66개 누락 0, 가로 1254 초과 0, 비-미디어 0.

#### 4. Phase 0a/0b — 대비 규칙을 문서가 아니라 **코드**로

이전 세션이 정한 색 규칙("gold·tiger 채움 위에 흰 글씨 금지")을 홈 주 CTA가 위반하고 있었다
(`SoriButton.filled(accent: SoriColors.tiger)` + 흰 라벨 = **2.31:1**).
개별 수정 대신 토큰 레벨에서 강제한다:

```dart
SoriColors.contrastRatio(a, b)      // WCAG 2.1 대비비
SoriColors.onFill(fill)             // 흰색/먹색 중 대비 큰 쪽 — tiger·gold·warning → 먹색
SoriColors.fillOutline(fill, bg)    // 채움이 배경과 3:1 미만이면 같은 색상의 어두운 테두리
```

`button.dart` filled 변형이 이 둘을 쓴다 → **accent 색이 새로 추가돼도 호출측 수정 없이 자동으로 맞는다.**

| 항목 | 이전 | 이후 |
|---|---|---|
| 주 CTA 라벨 | 흰 on tiger **2.31** | 먹 on tiger **7.22** |
| 주 CTA 채움 경계 | 2.14(테두리 없음) | 자동 테두리 `#AF6635` **4.08** |
| 라이트 카드 경계 | `lightBorder` **1.39** | `lightBorderStrong` on `lightSurfaceRaised` **3.27** |
| accent 카드 경계 | 1.19~1.51 | **3.18~3.57** (색상 유지 — 색 코딩이 정보라서 무채색으로 안 덮음) |
| 다크 카드 경계 | `darkBorder` **1.43** | `darkBorderStrong #6E8A82` **4.01** |
| 홈 보조 텍스트 | `textDim` **2.89** | `textMuted` **5.52** |

**신규 토큰 2개**: `lightSurfaceRaised #FFFDF8`(카드 바탕을 배경 위로 띄움), `darkBorderStrong #6E8A82`.

또한 홈 히어로 부제의 **U+25B6 `▶` 제거** → `Icons.play_arrow_rounded` WidgetSpan.
`no_emoji_glyph_test` 래칫을 **4 → 2**로 조였다.

#### 5. Phase 1 — 캐릭터 배선 (핵심)

| ID | 내용 |
|---|---|
| P1-0 | **설정에 캐릭터 변경 추가** (`_showMascotDialog`). 진입점 0개 → 1개. 이게 없으면 P1 검증 자체가 불가능했다 |
| P1-1 | `lib/widgets/sori/mascot_preference.dart` **신규** — `MascotPreference.kind`(`ValueNotifier<MascotKind>`). static getter만 두면 설정에서 바꿔도 리빌드가 안 온다 |
| P1-2 | `TigerStageVideo` 캐릭터 대응: `greetFor(kind)`/`paceFor(kind)`. 까치는 `magpie_greet_chirp`/`magpie_perched`. 폴백도 캐릭터별(까치는 Rive가 없어 정적 `Mascot`) |
| P1-3 | 홈 상단바 아이콘 **4 → 1**(설정만). 학습그룹·프로필은 하단 탭 중복(SC 3.2.3), 통계는 프로필 안. 터치 타깃 **36 → 48dp** + `Semantics` |
| P1-4 | `MascotKind.tiger` 리터럴 — **①진짜 하드코딩 9곳만 교체**. ②승패 연출 7곳·③선택 화면은 **유지** |
| P1-5 | 캐릭터가 바꾸는 것 **4가지**: 말풍선 액센트 색 / 1일차 인사 / 재방문 인사 / 히어로 밴드·폴백 |
| P1-6 | `test/mascot_wiring_test.dart` **신규** — 순수 함수 + 소스 가드 |

**🔒 P1-4 를 일괄 치환하면 안 되는 이유 (재발 주의)**

`pct >= 50 ? MascotKind.magpie : MascotKind.tiger` (cloze:279, custom_pack_quiz:308,
custom_pack_typing:301, daily_challenge:256, satz_arcade:239) 와
`won ? MascotKind.magpie : MascotKind.tiger` (kkeunmari:717, wordle:783) 는
**까치=길조/승리, 호랑이=위로** 라는 의도된 연출이다. `Storage.mascotKind` 로 바꾸면 승패 피드백이 사라진다.
`scenario_player:809` 도 대상 아님 — 시나리오 콘텐츠의 `sidekick` 필드를 따르는 것이지 사용자 선택이 아니다.

**🔒 P1-6 을 위젯 테스트로 쓰면 안 되는 이유**

테스트 환경은 `TigerStageVideo.videoReady == false` 라 영상 경로를 아예 타지 않는다.
"홈 위젯 트리에 `tiger_` 문자열이 없다"는 테스트는 **배선이 끊겨 있어도 통과한다.**
그래서 에셋 선택을 순수 함수(`greetFor`/`paceFor`/`sessionCompleteFor`/`thinkingFor`)로 분리해 단위 테스트하고,
리터럴 잔존은 소스 스캔으로 잡는다.

**🔴 MediaCodec 디코더 회수 — 이 세션에서 근본 수정**

Jin 실기기(M2101K6G / SD678 / MIUI)는 동시 H.264 디코더 2개를 못 버틴다.
조사 결과 **`TigerStageVideo` 혼자 greet·pace 컨트롤러 2개를 동시에 initialize** 하고 있었다 —
홈 화면 하나가 상시 디코더 2개를 물고, 그 위에 Lernpfad `_NowDisc` 클립이 올라가면 3개가 된다.

두 가지로 고쳤다:
1. **지연 로딩** — 인사 클립만 먼저 만들고, 끝난 뒤 아이들 루프를 만들어 인사를 반납(`_swapToPace`).
   교체 순간 ~200ms 만 2개, 정상 상태 **1개**.
2. **RouteAware** — `lib/widgets/sori/route_observer.dart` **신규**(`soriRouteObserver`,
   `MaterialApp.navigatorObservers` 등록). `didPushNext` 에서 컨트롤러 반납, `didPopNext` 에서 재취득.
   → 홈에서 `/path` 로 들어가면 홈 디코더 **0개**가 되어 Lernpfad가 필드를 독점한다.

⚠️ **실기기 확인 필요**: 홈 → Lernpfad 진입 시 ⓐ 경로의 캐릭터가 1초 뒤 사라지는지
ⓑ 뒤로 갔을 때 홈 밴드가 되살아나는지. `adb logcat | grep -i "reclaim\|ExoPlayerImpl"`.

⚠️ **까치용 인사 SFX가 없다** (`assets/sfx/` 에 `tiger_greet.mp3` 하나).
`TigerGreetClip` 이 까치일 때는 **무음**으로 두게 했다 — 호랑이 소리를 까치에 붙이면 캐릭터가 깨진다.
까치 SFX가 생기면 `tiger_video.dart` 의 해당 가드를 풀 것.

#### 6. Phase 2 — 첫 화면이 "0%"로 시작하지 않게

`_SteppingStonesRow` **신규** — 이번 주 7칸. 오늘 칸을 밝히고 스트릭에 해당하는 지난 칸을 채운다.
`MaterialLocalizations.firstDayOfWeekIndex`/`narrowWeekdays` 를 써서 로케일별 주 시작 요일을 따른다.

**전환 기준은 가입일이 아니라 스트릭** (`Storage.streakDays < 2`).
가입일 기준이면 며칠 쉬고 8일째 돌아온 사용자가 스트릭 0·XP 낮은 채로 게이지를 보게 되어
같은 문제를 8일차 버전으로 재현한다.

`home_screen` 의 "스트릭 0 복구 카드"(`homeTigerBubbleResume` = "Willkommen zurück!") 조건을
`streakDays == 0` → **`streakDays == 0 && xp > 0`** 으로 좁혔다.
방금 온보딩을 끝낸 신규 사용자에게 "다시 오신 걸 환영합니다"가 뜨던 버그.
(1일차 인사 자체는 `learner_motivation.dart:83` 이 이미 분기하고 있었다 — ARB 키 신설 불필요.)

**프리미엄 "맞춤 일일 코스"(`_CourseCard`)는 Jin 지시로 새 홈에 유지.**

#### 7. Phase 3 — 자산 무결성 테스트 강화

`test/data_integrity_test.dart` 가 `asset.contains(r'$')` 로 **보간 경로를 통째로 건너뛰고 있었다.**
그래서 `CharacterClips.tigerRoarSeatedBonus = '$_base/tiger_roar_seated_bonus.mp4'` 가
존재하지 않는 파일을 가리킨 채 여러 세션을 통과했다.
같은 파일에서 베이스 상수를 찾아 치환한 뒤 검사하도록 `_resolveBase()` 추가.
(해당 상수 자체는 다른 세션이 `tigerRoar` 별칭으로 이미 수정 — 현재 누락 0.)

#### 8. l10n — `flutter gen-l10n` 없이 키 추가한 방법

SDK를 못 받아 `gen-l10n` 을 못 돌린다. ARB 4키 추가 후 **생성 파일 3개에 손수 getter 를 넣었다**:
`app_localizations.dart`(abstract) / `_de.dart` / `_en.dart`.
다음 `gen-l10n` 실행 시 ARB에서 동일하게 재생성되므로 충돌하지 않는다.
추가 키: `homeMagpieBubbleStart`, `homeMagpieBubbleResume`, `homeLearnNowCtaMagpie`, `homeFirstWeekTitle`.

#### 변경 파일

| 신규 | 용도 |
|---|---|
| `lib/widgets/sori/mascot_preference.dart` | 선택 캐릭터 단일 진입점 (`ValueNotifier`) |
| `lib/widgets/sori/route_observer.dart` | 디코더 회수 방지용 전역 라우트 옵저버 |
| `test/mascot_wiring_test.dart` | 캐릭터 배선 회귀 가드 + 대비 규칙 테스트 |
| `docs/HOME_REDESIGN_PLAN_2026-07-31.md` | 조사·판정·계획 원본 |

| 수정 | 변경 |
|---|---|
| `widgets/sori/tokens.dart` | `contrastRatio`/`onFill`/`fillOutline` + `lightSurfaceRaised`/`darkBorderStrong` |
| `widgets/sori/button.dart` | filled 변형 fg 자동 판정 + 보강 테두리 |
| `widgets/sori/card.dart` | 카드 바탕 raised, 테두리 1→1.5px, accent 분기 대비 보정, 다크 경계 |
| `widgets/sori/tiger_video.dart` | 캐릭터 대응 + 지연 로딩 + RouteAware + 까치 SFX 가드 |
| `widgets/sori/character_clip.dart` | `sessionCompleteFor`/`thinkingFor`, `fallbackKind` nullable |
| `widgets/sori/game_reward.dart` | `mascotKind` nullable → 선택 캐릭터 기본값 |
| `widgets/sori/path_trail.dart` | `Storage.preferredMascot` → `MascotPreference` |
| `widgets/sori/milestone_celebration.dart` | 동일 |
| `screens/home_screen.dart` | 상단바 4→1·48dp, `▶` 제거, 캐릭터 구독, `textDim` 제거, 디딤돌, 복구 카드 조건 |
| `screens/settings_screen.dart` | 캐릭터 변경 타일 + 다이얼로그 |
| `screens/character_selection_screen.dart` | `MascotPreference.set` |
| `screens/{book_result,chosung_quiz,custom_pack_play,vocab_pack_result,review_session,kkeunmari,profile,scenario_player}.dart` | 하드코딩 → 선택 캐릭터 |
| `data/learner_motivation.dart` | `homeTigerBubble(..., kind:)` |
| `main.dart` | `MascotPreference.load()` + `navigatorObservers` |
| `l10n/*.arb` + `l10n/generated/*` | 4키 |
| `test/no_emoji_glyph_test.dart` | 래칫 4 → 2 |
| `test/data_integrity_test.dart` | 보간 자산 경로 해석 |

#### 검증 결과 (게이트)

- 괄호 균형: 수정 26파일 + 신규 3파일 **백업 대비 델타 0**
- ① 하드코딩 잔존 **0** / ② 승패 연출 **7곳 보존**
- import 누락 **0** / 참조 에셋 실존 **누락 0**
- ARB↔생성파일 신규 4키 **abstract·de·en 3중 동기**
- 대비: 표 §4 전 항목 기준 충족
- 글리프 래칫 **2 ≤ 2** OK
- ⚠️ **타이포 래칫 `w800` 이 189 → 193 으로 초과** — 20:51 병렬 세션이
  `onboarding_level_screen.dart`·`hanok_tokens.dart` 에서 +4 한 것이며 **이 세션 델타는 0**.
  `typography_guard_test` 를 통과시키려면 그쪽에서 w700 이하로 낮추거나 래칫을 조정해야 한다.

#### 남은 일

1. **`flutter analyze` + `flutter test`** (이 세션 불가) — 특히 `mascot_wiring_test`, `data_integrity_test`, `no_emoji_glyph_test`.
2. **실기기**: 까치 선택 후 홈/게임결과/레슨완료 육안 확인, 홈↔Lernpfad 디코더 회수 확인.
3. **까치 인사 SFX** 제작 여부 결정.
4. `w800` 래칫 초과 해소(병렬 세션 소관).
5. 마당 아이콘 6종 — IA 확정 후. Aussprache(마이크)·Kultur는 기능이 없으므로 그대로 발주 금지.
6. `assets_unused/_orig_2026-07-31/`(37MB) 최종 확인 후 삭제 — 브리지에서 `rm` 이 막혀 이동만 해 뒀다.


### 2026-07-31 (프로필 선택 마스코트 랜덤 초상 + 자홍색 영상 원인) — 로컬 커밋 `85f3ad6` · 푸시 미요청

**범위:** Jin 요청 — 프로필이 사용자가 선택한 호랑이/까치를 표시하고, 지정된 기존 MP4 포즈 중 하나를 랜덤으로 표시. 프로필의 자홍색 영상 배경 원인도 코드·에셋 계약으로 진단.

**Update:**
- `CharacterClips`에 순수 프로필 포즈 카탈로그를 추가: 호랑이=`tiger_stretch`·`tiger_sitting2`·`tiger_rest`·`tiger_bob`·`tiger_choose`, 까치=`magpie_perched`·`magpie_choose`·`magpie_flight`. 테스트 가능한 `profileClipCountFor`/`profileClipFor` API로 경로를 단일화.
- `ProfileScreen._Avatar`를 StatefulWidget으로 전환. `Storage.preferredMascot`을 화면 생성 때 읽어 해당 캐릭터의 포즈 한 개를 랜덤 선택하고 `late final`로 보존한다. 따라서 일반 rebuild 중에는 포즈가 바뀌지 않으며, 선택 마스코트는 연결된 Google/Apple 계정 사진보다 항상 우선한다.
- 자홍색은 Flutter/MediaCodec 고장이 아니라 **불투명 자홍색 매트가 들어간 H.264 MP4**와 `CharacterClipPlayer`의 `BlendMode.multiply` 계약 불일치다. multiply는 흰 배경만 크림으로 흡수하며 크로마키가 아니다. H.264에는 알파가 없으므로 안전한 코드 색필터로는 제거 불가 — 해당 클립은 같은 경로로 **순백(#FFFFFF) 매트 버전으로 재출력**해야 한다. 색 행렬/가짜 키잉은 호랑이·까치 색을 함께 훼손하므로 미적용.
- 계획: `docs/superpowers/plans/2026-07-31-profile-character-randomization.md`.

**검증:** TDD red 확인 — 신규 카탈로그 API 부재로 `character_clip_test` 컴파일 실패, 연결 계정 사진이 선택 까치를 덮는 기존 동작을 위젯 테스트로 실패 확인. 구현 후 `dart format` · 프로필/캐릭터 선택/Lernpfad 관련 9개 Dart 파일 `flutter analyze` **성공** · `flutter test test/character_clip_test.dart test/profile_screen_test.dart test/widgets/profile_screen_test.dart test/path_trail_tap_test.dart` **19 passed**. 전체 `flutter test`는 122초 도구 제한에서 출력 파이프가 닫혀 종료되어 전체 통과 증거는 아님. ⚠️ 실기기 미검증: Profile 탭 재진입 시 포즈 변화, 각 MP4의 구도, 순백 매트 재출력 후 자홍색 제거, 그리고 Redmi Note 10의 홈 영상↔프로필 영상 디코더 reclaim.

**변경 파일:** `lib/screens/profile_screen.dart` · `lib/widgets/sori/character_clip.dart` · `test/character_clip_test.dart`(신규) · `test/profile_screen_test.dart` · `docs/superpowers/plans/2026-07-31-profile-character-randomization.md` · `AGENTS.md`. 로컬 커밋 `85f3ad6` · 푸시 미요청.

### 2026-07-31 (문서 통합 — CLAUDE.md + memory → AGENTS.md SSoT) — 커밋 예정

**범위:** Jin "어떤 세션(Codex·Claude 등)에서 시작해도 먼저 읽게 AGENTS.md에 강력한 규칙 박고, memory·CLAUDE 전부 AGENTS.md로 옮겨." → `CLAUDE.md` 전체 본문 + `~/.claude/.../memory/` 3건(android-video-decoder-reclaim·cloze-shared-prompt-widget·jin-no-ios-style-badges)을 **루트 `AGENTS.md`(크로스에이전트 자동 로드)로 통합**해 단일 진입점·SSoT화. `CLAUDE.md`는 5행 포인터로 축소(모든 세션이 AGENTS.md를 먼저 끝까지 읽도록). 최상단 ⛔ 규칙(필독·필수 기록·커밋 게이트) 명문화. 이후 모든 기록은 이 AGENTS.md "세션 로그"에만 남긴다. (memory/ 파일은 Claude 자동로드용으로 잔존하나 내용은 여기로 통합.)

### 2026-07-31 (Lernpfad 지그재그 경로 + 대비 토큰 + 노드 에셋 배선) — 커밋·푸시 미수행

**상세: [`docs/SESSION_2026-07-31_lernpfad-zigzag-assets.md`](docs/SESSION_2026-07-31_lernpfad-zigzag-assets.md)** — 불변식·에셋 매핑·미검증 항목 전부 그쪽에 있음.

**범위:** Jin 스크린샷 → 크림 배경 위 카드 안 보임(온보딩·캐릭터선택) → Lernpfad 세로 리스트를 게임형 지그재그로 재설계 → 노드를 Material 아이콘에서 프로젝트 에셋으로 교체. **Cowork 클라우드 세션이라 `flutter analyze`/`test`/실기기 배포 전부 미실행**(컨테이너에서 flutter.dev·pub.dev 403).

- **대비 근본원인**: `lightSurface #F1ECDC` on `lightBg #FAF6EC` = **1.09:1**, `lightBorder` = **1.39:1**. 수치상 같은 색 → 앱 전체 카드가 배경에서 안 뜬다. 온보딩 "구분 안 됨"과 Lernpfad "지루한 나열"이 같은 병.
- **토큰 4종 추가(`tokens.dart`)**: `lightBorderStrong #978C73`(3.08:1, SC 1.4.11) · `goldOnLight #7A5810` · `tigerOnLight #A8490B` · `onTigerFill`/`onGoldFill`=`lightText`. 🔑 **`gold`(2.39:1)·`tiger`(2.14:1)는 크림 위 텍스트 불가, 그 채움 위에 흰 글씨도 불가(2.31:1) — 먹색을 얹으면 7.22:1.** `path_node.dart` "Jetzt" 배지가 이 위반이었고 수정.
- **`SoriPathTrail` 신규(`widgets/sori/path_trail.dart`)**: 76행 리스트 → 사인파 지그재그. 데이터·서비스 무변경. 기존 `PathNode` 는 `home_screen.dart:582` 가 쓰므로 **삭제 안 함**.
  - 🔒 **불변식 3개** (깨면 조용히 망가짐): ① `swayAt`/`centerXFor` 는 노드 배치와 연결선 painter의 단일 진실 — `Align` 식 `W/2 + fx*(W-w)/2` 와 정확히 일치해야 선이 원을 통과 ② 노드는 전용 슬롯 안 `Align` 으로만 배치 — 절대좌표 `Positioned` 로 바꾸면 clip·겹침으로 **탭이 조용히 죽음** ③ `CharacterClipPlayer.blendColor` == 바로 뒤 배경색(multiply라 다르면 사각 이음매).
  - 탭 보장: 타깃 = 슬롯 전체(132×136dp, 큰글자 161dp) · `IgnorePointer` 연결선 · `HitTestBehavior.opaque` · **잠금 노드도 동일 타깃**(잠금 힌트 떠야 함) · 접기/숨김 없음.
- **노드 에셋 (Material 아이콘 0개)**: 완료=`stamps/stamp_*.png`(기존 `motifForPackId()` 매핑, 도장이 이미 원형+테두리라 별도 원·체크 불필요) · 지금=`tiger_bob.mp4`/까치 `magpie_perched.mp4`(`Storage.preferredMascot` 분기) · 열림=도장+황금링 · 잠금=**도장 회색조 45%**(자물쇠 아니라 "받게 될 도장 미리보기"). **신규 에셋 파일 0개.**
- **`DancheongStamp` 에 `cacheWidth` 추가**: 도장 원본 1254×1254 → 62dp 노드에 그대로 디코드 시 **장당 6.3MB**. 경로에 수십 개 깔리면 이미지 캐시 폭발. 전 호출부에 이득.
- **깨진 참조 수정(`character_clip.dart`)**: `tiger_roar_seated_bonus.mp4` 는 **에셋 폴더에 존재한 적 없음** → 신기록 시 로드 실패·정적 폴백으로 연출이 통째로 사라져 있었음. Jin 지시로 `tigerRoarSeatedBonus = tigerRoar` 별칭(전용 클립 오면 한 줄만 되돌림). **수정 후 카탈로그 전수 대조: 깨진 참조 0 · 미참조 파일 0.**
- **검증**: 기하 시뮬(폭 100~600dp × 글자배율 0.85~2.5 → 오버플로 0·중심오차 0·슬롯겹침 0) · 대비 계산 · 레포 가드(신규 파일 `w700` 이하만 써 `typography_guard_test` 래칫 회피, 금지 글리프 0). **`flutter analyze`/실기기 미검증.** `path_trail_tap_test.dart` 는 내 원본이 `_NowDisc` 무한 펄스로 `pumpAndSettle` 타임아웃하는 결함이 있었고 **동시 세션이 `FakeAccessibilityFeatures` 로 고쳐 9/9 통과(`90a1713`)**.
- 🔴 **미검증 위험 — MediaCodec reclaim**: `home_screen.dart:1011` `TigerStageVideo` 는 `/path` push 후에도 라우트 스택에 남아 컨트롤러가 살아 있음 + Lernpfad `_NowDisc` 클립 = **동시 디코더 2개**. 이 기기(SD678/MIUI)는 2개를 못 버틴다(`SESSION_2026-07-31_onboarding-bookshelf-ui.md` 참조). 홈→Lernpfad 진입 시 호랑이가 1초 뒤 사라지는지 실기기 확인 필요. 터지면 ① `_NowDisc` 를 정적 `Mascot` 으로 강등(한 줄) ② `TigerStageVideo` 를 `RouteAware` 로 만들어 근본 수정.
- **변경 파일**: `path_trail.dart`(신규) · `tokens.dart` · `dancheong_stamp.dart` · `character_clip.dart` · `path_node.dart` · `learning_path_screen.dart` · `profile_screen.dart` · `quick_onboarding_screen.dart` · `character_selection_screen.dart` · `test/path_trail_tap_test.dart`(신규).

---

### 2026-07-31 (시나리오 정답 보상 연출 + 온보딩 book_scan + path_trail 테스트 수정) — 커밋·푸시

**범위:** Jin 실기기 피드백 기반. 고아 에셋 배선 → 시나리오 정답 보상 구현·버그수정 → path_trail 테스트 수정. 동시 세션과 파일 분리(스티커 감사·onboarding·scenario·celebration·path_trail 테스트만 손댐).

- **스티커 감사(코드 무변)**: `assets/stickers` 30/30 전부 `StickerPicker`→`GyeService.sendSticker/sendReaction`로 배선됨 — 단 **계(Gye) 기능 안에서만 노출**(계 미가입 사용자는 못 봄). 고아 0.
- **온보딩 book_scan(`88724a8`)**: 프리뷰 페이지0(책 한 컷) 비주얼 `book/book_camera_guide.png`→`onboarding/book_scan.png`(세로 941×1672) + 죽은 `wide` 파라미터 정리. ⚠️ **이후 동시 세션이 `onboarding_preview_screen`을 "풀블리드 히어로"로 재작성** — 현재 파일은 그 버전(내 book_scan 경로는 유지).
- **시나리오 정답 보상 — 1차(`c5d1415`) 후 수정(`834baa3`)**: 처음에 지속 까치 `_ScenarioBuddy` + `SoriCelebration.coins`(엽전 `yupjeon.png`·복주머니 `bok.png` PNG 입자, celebration.dart 신설) 추가 → **실기기 문제 3종**(① 까치 2마리 겹침 ② `_dependents.isEmpty` 크래시 ③ 코너 소형 burst) → 수정: **`_ScenarioBuddy` 제거**(각 quest 엔진에 이미 `MascotPartner`=정답 시 팡+DancheongBurst하는 까치가 있어 중복이었음), 크래시는 **이벤트콜백 동기 호출 → `_next()`식 post-frame + 화면 context**(`_celebrateCorrect`)로 전환, `coins()` origin **화면 중앙**+크기/개수 확대. 정답 훅 = 전 quest `_onQuestComplete`(pass) + 역할극 `_RollenspielStage.onCorrect`.
- **path_trail 테스트(`90a1713`)**: 동시 세션 `path_trail.dart` 위젯테스트가 "지금" 노드 `_NowDisc` **무한 펄스** 때문에 `pumpAndSettle` 타임아웃(탭 로직 자체는 정상) → **`disableAnimations`**(setUp `FakeAccessibilityFeatures` + 큰글자 테스트 명시 `MediaQuery`)로 안정화 → 9/9 통과. (위젯 무변경, 테스트 하네스만.)
- **검증**: `flutter analyze` 0 · scenario+smoke 25~29 · path_trail 9/9. **⚠️ 미검증(Jin 실기기)**: 시나리오 정답 시 크래시 소거·중앙 엽전/복주머니 burst·까치 1마리(834baa3), book_scan 온보딩 시각.
- **빌드 상기**: 위 전부 클라 Dart → **tts3 마무리 후 AAB 빌드하면 자동 포함**. 기존 뽑아둔 AAB 있으면 재빌드 필요. CF(`functions/tts`) 배포는 AAB와 별개.
- **Git**: `88724a8`·`c5d1415`·`834baa3` origin/main 푸시. `90a1713`(path_trail 테스트)은 동시 세션 푸시에 딸려 origin/main 반영(내가 push 안 함). ⚠️ `90a1713` 제목이 내용(테스트 fix만)보다 넓게 적힘 — 이미 푸시돼 amend 안 함(force-push 위험).

### 2026-07-31 (실기기 피드백 — Cloze/데일리챌린지 정답 단어 강조 + 여유로운 반응형) — 커밋 `9341b4f`

**범위:** Jin 실기기 스크린샷(Tages-Challenge 빈칸퀴즈) 2건. ① 초보자가 "뭘 찾는지" 몰라 → 독일어 번역에서 정답 단어를 강조. ② 카드·선택지가 상단에 몰리고 하단이 텅 빔 → 여유로운 반응형. Q&A로 방향 확정: **iPhone풍 배지/필 요소 금지, 오직 문장 내 단어 강조** + 박스를 화면 전체에 여유 있게 분산. plan `dazzling-wondering-dragon.md`.

**진단(§0 실측):** `daily_challenge_screen.dart`(스크린샷)와 `cloze_game_screen.dart`는 문제 카드·선택지 블록(≈207–263행)이 **완전 동일 쌍둥이**. `ClozeItem`(cloze_loader)에 `answer`(정답 한국어)·`de`(전체 문장 번역)는 있으나 **정답 단어의 독일어 뜻 필드는 없음**. 단, cloze.json은 `korean_vocab.csv`에서 생성돼 `answer`==CSV `korean`이고 뜻은 `german` 열에 존재. 선택지는 `Expanded>SingleChildScrollView>Column`이라 상단 고정→하단 공백.

**Update:**
- **신규 공유 위젯 `lib/widgets/sori/cloze_prompt.dart`** — 두 화면 중복 제거.
  - 순수함수 `splitEmphasis(sentence, gloss)`: 독일어 문장을 정답 뜻 등장 구간으로 분할, 그 단어만 **w800·녹청·큰 폰트(18)** 강조. gloss는 `/` 분해·괄호 제거 후보를 **대소문자 무시 부분일치**(원문 casing 보존, 예 `lila`→`Lila`). 매칭 실패(어형 변화)/null/빈값 → 문장 원문 단일 구간(crash 0).
  - `ClozePromptCard`: 한국어 문장 + `Text.rich`(강조) + TTS. 내부 여백 확대(vertical `xl`, 문장↔번역 `lg`).
  - `ClozeOptionsList`: `LayoutBuilder`+`ConstrainedBox(minHeight)`+`IntrinsicHeight`+`Column(spaceEvenly)`(study_card_face 선례) → 선택지를 하단까지 **균등 분산**(빈 하단 제거), 큰 글자는 스크롤 폴백. `QuizChoice` 내부 무수정.
- **뜻 조회는 런타임**: 두 화면 `_load()`에서 `DataLoader.loadVocab()`(정적 캐시) → `Map<String,Vocab> _vocabByKo` 구축, `_vocabByKo[item.answer]?.translationFor(lang)`(wordle_screen 동일 패턴). **cloze.json/build_cloze.py 무수정**(286항목 재생성 리스크 회피). 카드↔선택지 간격 `lg`→`xl`.

**검증:** `flutter analyze`(변경 4파일) **0** · `flutter test`: cloze_prompt 9(강조 로직 — Zebrastreifen 부분일치·대소문자·슬래시·괄호·무매칭·null) + daily_challenge 9 + responsive 157(신규 레이아웃 `daily challenge @360px ×1.3` 오버플로 0) 통과. l10n 변경 없음(gen-l10n 불필요). ⚠️ 미검증(Jin 실기기): 독일어 단어 강조 시각·선택지 하단 분산·큰 글자 잘림.

**Git:** 커밋 `9341b4f`(내 4파일만: cloze_game·daily_challenge·cloze_prompt·cloze_prompt_test). **동시세션 path_trail 작업**(learning_path_screen·path_node·tokens 수정 + path_trail.dart/test 신규 + 미디어)은 미스테이징·무접촉 — 그쪽 `path_trail_tap_test`는 진행 중이라 전체 스위트에서 실패하나 내 변경 무관. 머지 확인: `9341b4f`는 origin/main tip과 일치(푸시됨), 위에 동시세션 `f01c83a`(Deploy Checklist) 로컬 미푸시.

### 2026-07-01 (서양 학습자 어필 — "동기 & 모멘텀" 자율 구현) — 커밋·푸시

**범위:** Jin(취침) "독일/미·영인에게 얼마나 매력적일지, 더 공부하고 싶어지는 앱으로 — 승인 묻지 말고 계획 세워 구현, phase별 더블크로스체크→커밋, 끝까지→푸시→보고서." superpowers:brainstorming 승인 게이트는 Jin 명시 override로 생략, 자율 진행. 스펙: `docs/superpowers/specs/2026-07-01-western-appeal-motivation-momentum-design.md`.

**진단(실측):** 콘텐츠·게임·SRS·계·TTS·D1~D5 디자인은 갖췄으나 **서양 학습자가 배우는 감정적 이유(K-Pop·K-Drama·여행·문화·연인/가족·커리어)를 앱이 한 번도 묻거나 활용 안 함** — Duolingo 리텐션 플레이북 1번, CLAUDE.md 백로그 "동기 기반 온보딩"과 일치. daily goal은 분으로 캡처만 되고 미표시.

**Phase 1(`47226d1`) — 동기 캡처 + 개인화:** `LearnerMotivation` enum(7) + `Storage.motivation/motivationAsked` + `showMotivationSheet`(showSoriSheet 재사용, 첫 홈 진입 1회·투어 뒤·재노출 가드). **개인화(적대검증 D1 "write-only" 해소):** 홈 tiger 말풍선이 습관형성 구간에 이유별 격려로(`homeTigerBubble` 순수함수), 프로필 "왜 배우는가" 카드(탭 변경). l10n DE/EN 17키(적대 원어민 검수 PASS). 테스트 9.

**Phase 3(`7aec1ae`) — 일일 모멘텀:** `xpToday`(자정 리셋, 순수 `xpTodayValue`) + `addXp` 동시 누적 + `dailyGoalXp`(온보딩 분×3, 기본 30). 홈 스탯 행 아래 일일목표 진행 카드(SoriProgressBar+tabular XP, 달성 시 체크). l10n 2키. 테스트 5. 적대검증 PASS(결함 0). (Phase 2 개인화는 Phase 1에 병합.)

**방법:** phase별 구현→**적대적 verify 에이전트**(더블크로스체크)→지적 반영→커밋. Phase 1 verify가 D1(캡처 미소비)·D2(orphan 키) 잡아 즉시 홈+프로필 배선으로 해소. 검증된 컴포넌트만 재사용, 신규 수제 UI 최소. 동시세션 hangul_screen·scenarios_list 무접촉.

**검증:** `flutter analyze lib test` 0(잔여 hangul warning=동시세션) · `flutter test` **531**(+14) · ARB parity 980 · gen-l10n · dart format · responsive_test 홈 오버플로 0. **⚠️ 미검증(Jin 실기기)**: 동기 시트·홈 말풍선 개인화·프로필 카드·일일목표 카드 시각.

**Git:** 3커밋(`7436ef2`·`47226d1`·`7aec1ae`) origin/main 푸시.

**후속(Jin 선택 "K-컬처 연결", `66dfe42`):** 단어 학습 시 그 표현의 K-컬처 배경 노트(오빠·화이팅·빨리빨리·김치·우리·영화 등 14). **검증 가능한 문화 사실만** — 특정 곡/드라마 가사 인용은 정확성 검증(Jin) 후에만(§0, 환각 방지). `CultureNotesService`(`assets/data/culture_notes.json` 로더) + 재사용 `CultureNoteCard`(노트 없으면 SizedBox.shrink, kind별 아이콘·단청색) + legacy_vocab 플래시카드 배선. **적대검증 PASS**: 14/14 사실 정확(Parasite 2020 오스카·김치 사진관습·호칭 방향 전부 출처 확인·환각 0). l10n DE/EN 1키·테스트 3(로더·조회·시드 ko 전부 단어장 존재=노출 보장). ⚠️ **확장 방법**: Jin이 검수한 특정 곡/드라마 인용을 `culture_notes.json` `notes[]`에 `{ko,kind,de,en}`로 추가하면 자동 노출(ko는 단어장 korean과 정확히 일치해야 함). 다른 단어-표시 화면(review·vocab_pack)에도 `CultureNoteCard(korean:...)` drop-in 가능.

**후속2(Jin "이어서", `03c7556`):** 밀스톤 축하 모먼트 — 스트릭(3·7·30)·레벨(5·10)·고유단어(10·100) 달성 순간 마스코트 celebrate + 축하 버스트 + 메시지 시트(showSoriSheet). `newlyReachedMilestones` 순수함수(임계·미축하만) + `celebratedMilestones` 1회 가드(신규 전부 마킹→재발화 0) + 투어후·`_celebrating` 재진입 가드로 스팸 방지, 타입 우선순위(스트릭>레벨>단어) 1개만. 홈 로드/레슨 복귀 트리거(투어 게이트로 테스트 무회귀). **적대검증(2회차 — 1회차 에이전트 오작동으로 재실행)**: vocab 지표를 누적정답(vokCorrect)→고유단어(vokSeenIds)로 정합(카피 "N개 단어" 진실화)·`_celebrating` 재진입 가드·top 타입 우선순위 반영. l10n DE/EN 10키·테스트 6. **STT(말하기)는 큰 베팅이라 범위 결정 후 별도.**

### 2026-07-01 (디자인 "클로드 냄새" 제거 D4·D5 완주 + 실기기 UI 피드백 6종 + Gye 재구성) — 커밋·푸시

**범위:** Jin 실기기 스크린샷 피드백 → 폰트·말풍선·튜토리얼·프로필·호랑이영상 수정 → 이어서 디자인 플랜(`inherited-stirring-biscuit.md`) **D4·D5 완주**. Jin "자러갈거야, 묻지말고 계획 완성" → 자율 진행. plan: 위 파일 + 워크플로우 `design-d4-d5-gye`(11 agents 감사·Gye 판정단·적대검증).

**실기기 피드백 6종(`b8130e3`):** ① **폰트 통일** — GowunBatang 명조(라틴 서브셋, 한글 없어 독/한 분열 + 저품질) 전면 폐기 → **Pretendard 단일**(제목 w800). `SoriFonts.serif`=sans alias, SoriTextTheme display/h1/h2/serifDisplay/numeral·theme AppBar 전부 Pretendard. ② 홈 "Willkommen" 말풍선이 호랑이 가림 → 위 중앙+꼬리. ③ 튜토리얼 "왜 안 보임" = 재시작 전 미표시 갭 → `AppShell.replayHomeTour` 신호로 Settings "다시 보기"가 즉시 재생. ④ 프로필 전신 호랑이 → 원형 메달리온. ⑤ 호랑이 영상 회색 박스 → 초상 액자(#3) + `hasAlpha` 알파영상 자동대응(#2 준비, Jin 재출력 시 플래그). ⑥ 하단탭은 이미 일관(무변경).

**한지 텍스처(Jin 참고사진 "은은 크림" 확정):** `_HanjiPainter` 재작성 — 점+직선 → 실제 한지(따뜻한 구름 얼룩 + 먹 티끌 + 가늘고 성긴 창백한 닥 섬유). `mcp visualize`로 후보 6종 렌더→Jin "은은 크림"(A) 선택. 강도 배경 0.11/카드 0.13. seed 결정적.

**D4 전개(85% 화면, 커밋 6):** 신규 `SoriScreenBackground`(drop-in 한지 배경, Positioned.fill 레이아웃 중립) 토대(`fae0a31`) → D4-1 게임 7(`75ef728`) · D4-2 학습 7(`1cd49e8`) · D4-3 진행/수집 4(`d014899`) · D4-4 설정(`51b4a68`) · D4-5 **Gye 방향 C**(`5edc914`). ~25화면 은은 크림 한지 + 이모지→시맨틱 아이콘 + 수제카드→SoriCard + `_Section`/SoriSectionHeader 단청 골드 rule + stats tabular numeral + hard_words 마스코트. 화면 그룹별 워크플로우(Opus 에이전트 병렬 래핑 → 적대 검증) + 내가 analyze/test 최종검증. 오버플로 회귀(grammar/vocab_pack tap힌트 Row→Text.rich) 잡음.

**Gye "뜬금없다" 재구성(방향 C, 판정단 3방향 중 최소리스크):** 하단탭·AppBar "Lerngruppe"(+ "Zusammen lernen · Gye" 부제)로 독일 학습자 명료화하되 문화어 Gye 보존. IA/라우팅 무변경(탭 유지). 첫 방문 1회 설명 코치(ScreenCoachMixin `gye_tab`, kScreenCoachIds 등록). 빈 상태 = 제네릭 groups → '무엇/왜/어떻게' 3층 설명 카드(한옥 아이콘·gold hero) + CTA. plain Card→SoriCard. l10n navGye "Gye"→"Lerngruppe"/"Study group" + 6키(DE/EN parity, gen-l10n).

**D5(`c87fc64`):** responsive_test +20(gye_tab·quests·smalltalk·review, 총 **517**) + kkeunmari·speed_match 타이머 tabular figures. ⏳ **실기기 이월(§0 헤드리스 불가)**: 색 서사 재균형·ink-reveal 모션·한지 위 대비 감사. `scenarios_list:406` 소프트섀도우는 동시세션 파일이라 조율 후.

**검증:** 매 단계 `flutter analyze` 0(잔여 1 warning=동시세션 hangul_screen, 무접촉) · `flutter test` **517** · 오버플로 0 · dart format · ARB parity · gen-l10n. **⚠️ 미검증(Jin 실기기 필수)**: ~25화면 시각(은은 크림 톤·섹션 골드 rule·Gye 새 빈상태/코치·프로필 메달리온·호랑이 영상 액자·stats 숫자). 호랑이 영상 진짜 투명은 Jin 알파 재출력 필요.

**Git:** 커밋 8건(`b8130e3`~`c87fc64`) origin/main 푸시. hangul_screen·scenarios_list(동시세션 WIP) 전 커밋에서 명시 제외.

### 2026-07-01 (후속5 — 한국어 예문·시나리오·smalltalk 원어민 자연화) — 커밋

**범위:** Jin "한국어 리뷰가 너무 허접해 보임 → 진짜 한국사람이 쓰는 표현으로 전부 최적화, 누락 없이." Q&A 확정: **소스 CSV/JSON 직접 수정**(앱 반영, md는 재생성) · **전 범위**(vocab 558 + 시나리오 33 + smalltalk 145). 후속4의 리뷰 리스트가 검수-후-반영 방식이었으나 Jin이 "예문 자체가 교재틱" 지적 → 이번은 사전 격상.

**진단(§0, 실측):** vocab 예문에 (a) 동어반복 15건(감사합니다→감사합니다! 등) (b) 교재틱·무맥락(나이가 몇 살이에요/친구예요/제 방이 작아요) (c) 조사·문장부호 어색(네 맞아요/아니요 틀려요) 다수. 시나리오·smalltalk은 이미 원어민급이라 소량 튜닝만 필요.

**Update:**
- **`assets/data/korean_vocab.csv` 408건 교체** — `tool/native_polish/vocab_examples.py`(대체 사전 410엔트리). 원어민 실사용 문맥으로 격상: 인사 표현 19(감사합니다!→도와주셔서 감사합니다.), 가족·몸 12(형이 요리해요→우리 형은 요리를 잘해요.), 색깔 9(나뭇잎이 초록색이에요→이 초록색 옷이 예뻐요.), 음식·시간 10, 기본 동사·형용사 30+, 숫자·요일 10+, A2 회사·감정·일상·집·돈 90+, B1 추상·SNS·라이프스타일 60+, B2 학술·경제·환경 60+. **레벨 문법 범위 준수**(A1 예문은 A1 문법). **자체 검증에서 잡은 오류 2건**: `육 시`(시간은 순한글) → `저는 육 층에 살아요.`, `구 월`(붙여쓰기) → `구월`.
- **`assets/data/scenarios.json` 7건 튜닝** — `tool/native_polish/scenarios_smalltalk.py`. airport(관광이에요→관광하러 왔어요), business_meeting(요체/습니다체 혼용 → 통일), subway_directions(강남역에→강남역), hotel_checkin(예약했는데요. 이름은→예약했는데요, 이름이), mart_grocery(주세요 반복→주시고, 하나 주세요), job_interview(마케팅 경험이 삼 년→마케팅 분야에서 3년), convenience_store(다 되셨어요?→계산 도와드릴까요?).
- **`assets/data/smalltalk.json` 18건 튜닝** — bare opener를 실감있게: `저는 여행을 좋아해요`→`저 여행 진짜 좋아해요`, `이사했어요`→`저 얼마 전에 이사했어요`, `잘 자요`→`잘 자요, 좋은 꿈 꿔요` 등. 문법 격 하향(-을/-를 드롭)·감탄 자연화.
- **`docs/KOREAN_REVIEW_2026-07-01.md` 재생성** — `tool/native_polish/regen_review.py`(vocab CSV+scenarios+smalltalk에서 자동 조립, 1016줄). Jin이 리뷰에서 어색한 곳 표시→매핑 갱신 후 재실행 가능.
- **신규 도구 3종** (`tool/native_polish/`) — 재실행·복원 가능. 대체 사전은 데이터가 아니라 스크립트 상수라 diff·수정·재실행 용이.

**검증:** `flutter test test/data_integrity_test.dart test/scenario_loader_test.dart` 통과 · 전체 `flutter test` **491 통과**(회귀 0) · 남은 동어반복 0건 · CSV 열 14/행 558·독일어/영어 필드 누락 0·시나리오 대사 ko 누락 0·smalltalk 145 보존 · JSON 원본 `indent=1` 포맷 유지(스타일 리포맷 X). CSV 라인엔딩 LF 유지(초기 시도 CRLF로 저장 → Dart `CsvToListConverter(eol:'\n')` 파싱 실패 → `lineterminator="\n"` 지정 후 해소). ⚠️ 미검증: 실기기 시각(스탯 카드·홈 vocab pack 진행도 등에서 새 예문 노출)·TTS 발화 톤 = Jin. 신규 예문 중 A2 문법(-네요·-어서·-기 전에) 소량 포함(A1 벽 완만하게, 대부분 앱 사용자가 조기 노출됨).

**Git:** 이 커밋(내 5파일 + tool/native_polish/*). 동시세션 8파일(app_shell/hangul/home/profile/settings/theme/tiger_video/tokens + screen_background 신규)은 미포함.

### 2026-07-01 (후속4 — 실기기 피드백: 허브 카드 높이 + 한국어 검수) — 로컬 커밋(미푸시)

**범위:** Jin 실기기 스크린샷(Üben 허브) — ① 그리드 카드 높이 들쑥날쑥 ② 한국어 어색(`열쇠를 잃었어요`→`잃어버렸어요`). Jin "한국어 전부 리스트로" 요청.

**Update:**
- `8e0efc0` **허브 카드 높이 균일화**: D3 그리드의 2열 카드가 콘텐츠 높이로 잡혀 행마다 불균일 → `ModuleCard` Stack `passthrough` + 3허브(practice/learn/wordbook) `_grid` Row를 `IntrinsicHeight`+`stretch`로. responsive_test 137 통과.
- **한국어**: `korean_vocab.csv` `열쇠` 예문 `잃었어요`→`잃어버렸어요`(물건=잃어버리다). **`길을 잃었어요`(406)는 관용구라 유지**·`지갑`(184)은 이미 정상. `잃` 스캔 타 후보 0.
- **`docs/KOREAN_REVIEW_2026-07-01.md` 신규** — 전 한국어 사용자 대면 텍스트(단어예문 558·시나리오 33·스몰토크 145) Jin 원어민 검수용 리스트. §0: KO 최종 판정=원어민이라 전수 재작성 대신 리스트 제공 후 반영 방식.

**⚠️ 상태:** 이 커밋들은 **동시세션 디자인 개편(D1/D2/D3 "한지 에디토리얼", 미푸시) 위에 로컬로 쌓임**. push 시 디자인 커밋 동반 상승 → Jin 확인 후. `hangul_screen.dart`(동시세션 미커밋)는 미손댐.

**검증:** flutter analyze 0 · responsive_test 137 · data_integrity 통과.

### 2026-07-01 (후속3 — 코드/데이터 실 결함 사냥, 적대적 검증) — 커밋·푸시

**범위:** Jin "실 결함·오류 더 찾아줘" → "오래된 코어 화면·gye·결제 경로로 확장." 다차원 defect-hunt 워크플로우(find → **적대적 verify**, 기본 REJECTED) 2라운드 + Opus 직접 결정적 데이터/패턴 검사. §0: 코드/데이터만 위임, 언어 판정 직접. SSoT: `docs/DEFECT_HUNT_2026-07-01.md`.

**결과: CONFIRMED 14(거짓양성 6 기각) → 수정 7 커밋 · 보고 7.** 데이터 무결성 5파일(cloze/satz/kkeunmari/vocab/scenarios) 직접 검사 결함 0.

**Update(수정 7):**
- `6e0cdec` daily_challenge 완료 RangeError(`_idx==length && _outcome==null` 창 → 인덱스-only 가드, 형제화면과 통일).
- `4e07b74`(6건): 🔴**프리미엄 게이트 우회** learning_path·home 경로노드(A2/B1/B2를 게이트 없이 오픈 → vocab_packs와 동일 게이트) · premium_service 로그아웃 시 `_boundUid` 미리셋(→리셋+logOut) · kkeunmari 빈풀 pickStart RangeError(→빈풀 가드+mounted) · book_capture await 후 setState 4곳 mounted 가드 · book_result 다이얼로그 controller 미dispose.

**보고(미수정 7 — Jin 영역):** firestore.rules 보안 3(#2 10명상한 서버 미강제·memberCount 임의조작 / #3 정지멤버 자가해제 / #10 feed 무검증 주입) · CF 강제 2(#7 연령 · #11 계 상한) · 후속 클라 2(#6 매칭 소프트락 · #12 all-in 주경계). 상세·제안픽스 = SSoT 문서.

**후속 처리(Jin "진행해"):** 후속 클라 2건 수정·푸시 `b65e6d4`(#6 `_newRound` 중복 gloss 배제 / #12 `_weekKey` 월요일 정렬). firestore.rules **#2(memberCount ±1 제약)·#10(feed type 화이트리스트=GyeFeedTypeWire 7종) diff 반영**(⚠️ 미테스트 — Jin `firebase emulators` 후 배포). #3은 순수 rules 불가(권장: CF/owner-write `bans/{uid}` + isActiveGyeMember 확인), #2 절대상한·#7·#11은 CF 필요 → 미반영·문서화.

**검증:** `flutter analyze lib test` **0** · `flutter test` **491 통과** · dart format. 커밋 내 파일만 명시 스테이징.

### 2026-07-01 (후속2 — 동시세션 신규 콘텐츠 자연스러움 감사) — 커밋·푸시

**범위:** "다음 작업" → 동시세션이 그새 main 커밋한 신규 사용자 대면 텍스트(게임 아크 l10n·B2 단어·satz/cloze/kkeunmari) 원어민 검수. §0 직접 통독.

**총평:** 신규 콘텐츠 **대부분 원어민급 + 상당수 이미 감사한 소스 파생** — satz_sentences 191 **전부 vocab 예문 파생(새 문장 0)** · cloze 파생 · kkeunmari 415(신규분은 감사된 vocab 병합·빈 글로스 0) · **B2 환경단어 12 전부 native** · 신규 게임화면 하드코딩 문자열 0.

**Update(EN 2건):** `clozeDesc` "Fill the missing word"→"The missing word in a sentence"(관용 오류 + DE "Das fehlende Wort im Satz"와 평행) · `clozeTitle` "Cloze"→"Fill in the Blank"(jargon→접근성; DE "Lückentext"·타 게임명 평이와 일치). DE 신규 키 전부 native(무수정). parity 955=955.

**검증:** gen-l10n OK · analyze 0. 소프트 노트(미수정): `gameBestTries`/`speedMatchBest` DE "Bester:" 라벨 약간 어색(일관·terse라 유지).

**Git:** 별도 커밋·푸시.

### 2026-07-01 (후속 — 오류 진단 피드백 "왜 틀렸는지" + Phase 2 재스코핑) — 커밋·푸시

**범위:** 자연스러움 감사 후 "또 뭘?" → 실측 조사(Explore 2)로 **출시·수익화 차단은 전부 Jin 운영**(rules 배포·AAB·실기기·RevenueCat 대시보드), **코드 레버 = 산출/오류피드백 갭** 확인. Jin 방향 = **오류피드백+산출 강화**. 프로토콜: phase마다 검증→더블체크→커밋→다음, 전부 완료 시 push. plan `squishy-munching-fox.md`.

**Phase 1 — 오류 진단(커밋 6f63b35):** 산출 퀘스트가 오답 시 위치 하이라이트만 주던 걸 **틀린 유형 진단**으로 강화. 오프라인·결정적·순수함수(기존 채점함수 패턴). QuestResult(별점/진행) 불변 = 회귀 0.
- `satz_bauen_quest`: `SatzError{order,particle,tooMany,tooFew,word}` + `diagnose()` + `stripJosa()`(조사 사전 어간추출). 답영역 아래 진단 라인. **정답은 항상 none(오진단 0)**.
- `diktat_quest`: 자모 분해(유니코드 0xAC00)+`jamoEditDistance`(Levenshtein)+`diagnose()` → 띄어쓰기/철자근접(자모거리≤2)/오답 구분. 철자 힌트 신설.
- l10n DE/EN +5(`questDiag*`·`diktatSpellingHint`, parity 955=955) + 테스트 +14(적대적: 정답→none·조사 vs 단어).
- **시너지(계획 외):** `SatzBauenQuest`를 **시나리오 역할극 + 동시세션 신규 satz 아케이드**(`satz_arcade_screen`, `satz_sentences.json` 1984줄)가 재사용 → 진단이 **3곳 자동 전파**. 아케이드·cloze 테스트 회귀 0 확인.
- 검증: `flutter analyze lib test` **0**(전체) · 진단+데이터+시나리오+아케이드 스위트 통과 · dart format. ⚠️ 실기기 시각(진단 라인 노출)=Jin.

**Phase 2 — 재스코핑으로 드롭:** 착수 전 체크포인트에서 **동시세션이 그새 산출 학습 아크 6단계를 main 커밋**(문장짓기 아케이드·cloze 게임·스피드매칭·데일리챌린지·B2 콘텐츠 깊이+끝말잇기 확장)한 것 발견. 산출 표면이 이미 풍부 + `vocab_pack_service` 동시편집 → 단어팩 타이핑 스테이지는 **중복·충돌 위험**. Jin 결정: **Phase 1로 마무리**(진단이 아케이드에 이미 전파돼 산출 학습 전반 강화됨).

**Git:** Phase 1 = **6f63b35** 커밋 → origin/main 푸시. 내 파일만 명시 스테이징(동시세션 tiger_video·게임·pubspec 제외).

### 2026-07-01 (DE/KO/EN 원어민 자연스러움 전수 재검사) — 커밋·푸시 217dc50

**범위:** Jin "독일어·한국어·영어 표현을 각 언어 특성에 맞게 가장 자연스럽게." Q&A 확정: **3개 언어 전수 재검사** · KO도 **직접 수정**(이번 한정) · 로마자 오타 6건 **함께 수정**. SSoT: `docs/NATIVE_TEXT_AUDIT_2026-07-01.md`.

**방법(§0):** Opus 메인이 전 표면 직접 통독(서브에이전트 언어판정 위임 X — `feedback_model_delegation`). python 추출로 ARB 931키×2·시나리오 33(대화 204·노트·문법·문화·퀘스트)·단어 546·문법 88·문법패턴 31·끝말잇기 392·smalltalk 145 전수 정독.

**총평:** 06-09·06-18 두 차례 감사로 **DE·KO 이미 원어민급**. 이번 새 발견 = **영어 시나리오 204줄**(과거 미검수 유일 표면, 06-09에 서브에이전트 환각으로 보류됐던) 직접 정독 → 실품질 양호. 전 표면 확정 결함 **소수**.

**Update(적용 8건):**
- 🔴 **DE 노트 한국어 조각**: `scenarios.json` `cafe_study` 단어 `영수증` DE `Kassenbon (오늘 영수증에 비번이 있을 때도).` → `Kassenbon (manchmal steht das WLAN-Passwort darauf).`(영어판 정상이었음, 유일한 진짜 결함).
- 🟡 **고유명사 로마자**: `taxi_street` `성산대교`의 `Sungsan`→`Seongsan`(표준 RR, DE·EN 4곳).
- **로마자 오타 6**: `korean_vocab.csv` romanization 열 — sireohadam→sireohada·hoei→hoeui·seontaek hada→seontaekhada·ohilleo→ohiryeo·deudieeo→deudieo·eopload-hada→eoprodeuhada.

**유지(제안만):** 사이다 EN "Sprite" vs DE "Limo"(각 언어 native, 단어노트가 "Sprite-like" 프레이밍) · `introduce_yourself` DE "Bitte um Ihre Unterstützung"(잘 부탁드립니다 정형구) · 기타 미세건 — 전부 각 언어로 자연스러워 미적용, 문서에 근거 기록. **KO 결함 0**(Jin 원어민 작성, 직접 수정 권한 받았으나 손댈 것 없었음).

**검증:** scenarios.json valid(33)·잔여 옛 문자열 0 · CSV 14열/546행/불량 0·로마자 6 정확 · `flutter test`(편집 표면 8 스위트) **70 통과**. ⚠️ 미검증(Jin 실기기): DE/EN 토글 시각.

**⚠️ 동시세션 미완(내 작업 무관):** `flutter analyze` 8 에러 = 동시세션 신규 **cloze** 기능(cloze.json·cloze_game_screen·cloze_loader·build_cloze.py 전부 untracked)이 ARB에 `cloze*` 키 추가 후 `gen-l10n` 미실행 → `AppL10n.clozeTitle` 등 getter 부재. 데이터만 만진 내 변경과 무관, 미손댐.

**Git:** 커밋·푸시 완료 — **217dc50**(내 4파일: scenarios.json·korean_vocab.csv·docs/NATIVE_TEXT_AUDIT_2026-07-01.md·CLAUDE.md). *이후 동시세션이 cloze를 커밋해 위 analyze 8에러는 해소됨.*

### 2026-06-22 (실생활 습득 듀오링고化 검토 + Phase 1: 문장 짓기 산출 엔진) — 미커밋

**범위:** Jin "한글소리가 어디까지 듀오링고처럼 실생활 한국어를 습득하게 만들 수 있는지 개선안 검토." Q&A 확정: **검토 문서 + 1순위 바로 착수** · 레버 **①능동 산출 + ③인터랙티브 역할극 + ④콘텐츠 확충 결합** · **말하기(STT)는 나중 별도 베팅**. plan `zesty-strolling-sloth.md`.

**진단(실측, §0):** 입력 콘텐츠(단어 546·문법 88·시나리오 33/204턴·스몰토크 145, 전부 CEFR·이중언어)는 듀오링고급. **갭 = 산출(말·쓰기)·능동 회상·오류 피드백이 거의 0** — 학습 거의 전부 4지선다/탭 인식. 시나리오 `speaker:"user"` 대사 **101줄**(KO+DE+EN 완비)이 자동 재생만 되고 사용자가 만들어내지 않음.

**핵심 통찰:** 1·3·4를 한 기능으로 — 사용자 대사를 **단어 타일로 직접 조립(문장 짓기)**. 오프라인·결정적·저위험(STT/LLM 불필요), §0대로 신규 번역 0(기존 원어민 대사·어절 재사용).

**Update(Phase 1):**
- **`lib/screens/quest_engines/satz_bauen_quest.dart` 신규** — `SatzBauenQuest`(단어은행↔답영역 탭, "확인" 채점, 오답 시 첫 불일치 하이라이트=최소 오류 피드백, 2회 후 정답공개, 선택 TTS, 라이트/다크, MascotPop). 채점은 **순수 정적함수** `tokenize`/`isCorrectOrder`/`firstMismatch`(어절 분절+문장부호/공백 정규화).
- **모델·디스패치**: `scenario.dart` `QuestType.satzBauen` 추가 + `targetVocabKeys()`→[targetKo](오류-인지 SRS 연동) · `scenario_player_screen.dart` 디스패치+import.
- **콘텐츠 시드 8개**(A1×4·A2×4: cafe/airport/taxi/bunshik/subway/mart/ktx/cafe_study) — `scenarios.json` `quests`에 append(파이썬 mutation, indent=1 round-trip 바이트동일 → diff 112추가/0삭제). targetKo·promptDe·promptEn=기존 user 대사, distractors=동일레벨 실제 어절(가짜 0, 중첩 0).
- **l10n** DE/EN +2키(`questSatzBauenInstruction`·`questCheckAnswer`) → 924=924. **테스트** +12(`satz_bauen_quest_test`: 채점 로직·시드 무결성) + `data_integrity_test`에 satzBauen 검증 케이스/allowlist 추가.
- **검토 문서** `docs/REAL_LIFE_ACQUISITION_REVIEW_2026-06-22.md`(진단표·갭 매트릭스·Phase 1~4 로드맵: 인라인 user턴 산출·받아쓰기·오류피드백 강화·상황커버리지·STT/AI파트너).

**검증:** `flutter analyze lib test` **0** · `flutter test` **412 통과**(+12) · ARB parity 924=924 · gen-l10n OK · dart format. ⚠️ 미검증(Jin 실기기 `flutter run -d 9053622f`): 문장 짓기 타일 조립·오답 하이라이트·셀러브레이션·다크모드 시각.

**Git:** 커밋·푸시 완료 — **c6c1aa1**(내 13파일만; 동시세션 tiger_video·pubspec·main/app_shell/home/quick_onboarding은 미스테이징). push에 직전 미푸시 로컬커밋 a1e6cc8·99c9a57 동반 상승(이미 커밋돼 있던 Jin 작업).

**Phase 2 (같은 날 후속 — 받아쓰기(Diktat) 산출 퀘스트):** satzBauen과 대칭의 두 번째 산출 모드. 듣기+철자 인출.
- **`lib/screens/quest_engines/diktat_quest.dart` 신규** — `DiktatQuest`: TTS(정상/느림 2버튼, 진입 시 1회 자동재생) → 한국어 TextField 직접 입력 → "확인". **띄어쓰기-only 오류는 별도 amber 힌트**(`isSpacingOnly`, 어순/철자는 맞고 공백만 틀림 = 한국어 최난점 배려), 그 외 오답 2회 후 정답공개. 💡뜻보기 토글. 채점 순수함수 `normalize`/`isExact`/`isSpacingOnly`. 컨트롤러는 State 소유·dispose(과거 "disposed controller" 크래시 안티패턴 회피).
- `scenario.dart` `QuestType.diktat` + `targetVocabKeys`→[targetKo] · `scenario_player_screen.dart` 디스패치+import.
- **콘텐츠 시드 8**(A1/A2 단문, satzBauen과 다른 줄: airport 여권·introduce 어디서·taxi 강남역·bunshik 사이다·pharmacy 어디가·mart 사과·cafe_study 콘센트·ktx 왕복) — 기존 대사 ko/de/en 재사용. diff 72추가/0삭제.
- l10n DE/EN +3(`diktatInstruction`·`diktatSpacingHint`·`diktatShowMeaning`) → **927=927**. 테스트 +11(`diktat_quest_test`: 비교로직·시드) + data_integrity diktat allowlist/검증.
- **검증:** analyze **0** · `flutter test` **423 통과**(+11) · gen-l10n OK · dart format. ⚠️ 미검증(Jin 실기기): 받아쓰기 TTS 자동재생·한글 IME 입력·띄어쓰기 힌트·정답공개·다크.
- **Git:** 커밋·푸시 완료 — **5dee2bb**(내 12파일만).

**Phase 3 ① (같은 날 후속 — 인라인 역할극 스테이지):** 시나리오를 "읽기"에서 "직접 말하기"로. 대화의 모든 `speaker:"user"` 대사를 **그 자리에서 단어 타일로 조립**(SatzBauenQuest 재사용)하는 Rollenspiel 스테이지 추가 = 진짜 역할극.
- **스테이지 인덱스 리팩토링(회귀 방지 핵심):** 산재하던 `_totalStages`/`_questStartStage`/`_isResultStage`/`_currentQuestIndex` getter를 **순수 공개 함수 `buildScenarioStagePlan(hasRollenspiel,hasGrammar,questCount)` → `List<ScenarioStage>`**로 추출. State는 `_plan` 보유, `_buildStage`는 `_plan[index]` switch. 인덱스 산술이 **유닛 테스트 대상**이 됨(`scenario_stage_plan_test` 5).
- 플랜 순서: intro→vocab→dialog→(grammar?)→(rollenspiel?)→quest×N→result. rollenspiel은 quest처럼 완료해야 Next 활성(`_questReady`). **별점/실패-SRS 산술 불변**(rollenspiel은 `_onQuestComplete` 미경유 → `_passedCount`/`_failedQuestIndices` 오염 0).
- **`_RollenspielStage` 위젯**(파일 내): user 대사들을 순차 제시(상대 NPC 직전 대사를 stichwort 카드로 + 진행 n/m), 각 턴 SatzBauenQuest(distractors=같은 대화 실제 어절 2, 런타임 파생) → 마지막 완료 시 onDone→완료 카드(호랑이 celebrate). 모든 33시나리오 user 대사 ≥1 보장(테스트).
- l10n DE/EN +4(`scenarioRoleplayTitle/Hint/Turn/Done`) → **931=931**. 테스트 +5(stage plan 산술·user 대사 커버리지).
- **검증:** analyze **0** · `flutter test` **428 통과**(+5) · gen-l10n OK · dart format. ⚠️ 미검증(Jin 실기기): 역할극 진입·턴 진행·완료 게이트·Next 활성·다크. (참고: rollenspiel이 전 user 대사를 커버하므로 Phase1의 satzBauen 시드 8은 일부 중복 — 추후 정리 후보, 현재는 유지.)
- **Git:** 별도 커밋 예정.

### 2026-06-18 (독일어·영어·한국어 자연스러움 전수 검사) — 미커밋

**범위:** Jin "독일어랑 한국어 텍스트가 원어민이 쓰는것같이 자연스러운지 전수 검사." Q&A 확정: **정말 전부**(단어 글로스·끝말잇기 풀 포함) · **DE/EN 직접 수정, KO 제안만**(Jin 원어민) · **EN 포함**. plan `nifty-popping-reddy.md`. SSoT: `docs/NATIVE_TEXT_AUDIT_2026-06-18.md`.

**방법(§0):** Opus 메인이 전 표면 직접 통독(서브에이전트 언어판정 위임 X — 메모리 `feedback_model_delegation`). ARB 922키·시나리오 33(대화+노트)·문법 88·단어장 546·끝말잇기 2,453·smalltalk 145·grammar_patterns 31·hangul_data 발음 24 전수. 대용량은 python 추출로 텍스트만 컴팩트 검토.

**총평:** 2026-06-09 딥다이브 덕에 **기존 품질이 이미 매우 높음** — 시나리오·단어장·문법·smalltalk 모두 원어민급(결함 0). 실제 결함은 소수.

**Update(DE·EN 직접 수정 8건):**
- `app_de.arb`: `coachDojangTitle/Body` **Dangseon→Dancheong**(단청 로마자 오기, 앱 전체와 불일치) + **"zu freizuschalten" 이중 zu 비문 수정**(freischalten 분리동사).
- `app_en.arb`: BrE→AmE 철자 3건(`colours`→colors, `practise`→practice ×2) — 앱 미국식 통일.
- `korean_vocab.csv`: 부사형 `zuhause`→`zu Hause` 3건(grammar.csv 프로젝트 표준과 통일; 명사 `Zuhause`는 보존).

**KO/콘텐츠 반영(Jin "B-1·B-2 반영" 요청 → 적용):**
- **B-1** grammar.csv `N에서 N까지`: `월요일에서`→`월요일부터`(시간 시작=부터). note(DE)+note_en(EN) 양쪽 2곳.
- **B-2** 🔴 kkeunmari_pool.json: §0대로 **손번역 안 하고** `german="TODO"` 자막조각 **2,061건 제거**(조사결합·활용형 = 끝말잇기 부적합) → 큐레이션 392단어만 유지. `next_count`/`is_dead_end`를 필터셋 기준 **재계산**(dead-end 163·startable 153, 플레이 가능). meta.total 392·okt_verified 제거·curation 노트. 엔진 docstring 225→392. UI는 이미 `german!='TODO'` 가드라 TODO 미노출이었음.
- (미반영) 로마자 오타 6건은 발음표기 열이라 자연스러움 범위 밖 — 감사문서 B-3에 목록만.

**검증:** ARB parity **922=922** · gen-l10n OK(Dancheong) · CSV 14/11열 bad 0 · JSON 4파일 OK · kkeunmari TODO **0**·풀 392 · `flutter analyze lib test` **0** · `flutter test` **400 통과**. ⚠️ 미검증(Jin): 실기기 시각, 끝말잇기 392단어 체인 길이 체감.

**Git:** 커밋 `99c9a57`(푸시 미요청). 변경: app_de/en.arb(+generated)·korean_vocab.csv·grammar.csv·kkeunmari_pool.json·kkeunmari_engine.dart·CLAUDE.md·docs/NATIVE_TEXT_AUDIT_2026-06-18.md.

**후속(Jin "끝말잇기 단어 한국어 사전에서 끌어와서 써"):** Q&A 확정 — 소스 **우리말샘/stdict + DeepL 생성기(Jin 실행)**, **학습용 흔한 명사**. `tools/content_factory/build_kkeunmari_pool.py` 신규: hermitdave ko_50k 빈도시드 → **표준국어대사전(stdict) 명사 검증**(`functions/analyze_korean_text/main.py` 계약 재사용 — 조각·활용형 자동 탈락) → 글로스(vocab 검수분 우선·나머지 DeepL·둘 다 없으면 ""=UI 숨김, **TODO/가짜 0**) → first/last·next_count/is_dead_end 최종집합 계산 → 풀 재생성. §0대로 **손번역 0**. ⚠️ 키(`STDICT_API_KEY`/`URIMALSAEM_API_KEY` + `DEEPL_API_KEY`) 필요 → **Jin 1회 실행**(`--target 2500 --deepl --write`). 검증: `py_compile` OK · 오프라인 `--self-test` 통과(graph·glossprio·필터) · 시드 다운로드 실동작 확인 · 스키마 data_integrity_test·엔진 호환. README (a2) 추가, `.cache/` gitignore. 별도 커밋.

### 2026-06-12 (후속 — Phase D-4 전원챌린지 피드 이벤트 보강) — 커밋·푸시

**범위:** Jin "D4·Phase E도 있잖아" 지적 → §0 재검증. **Phase E는 실측 완료 확인**(bookshelf_json round-trip 테스트 통과·catch 로깅·consentBody·CLAUDE.md). 단 **D-4는 plan이 "burst + 피드 이벤트"인데 burst만 돼 있던 갭** 발견 → 피드 이벤트 보강.

- **`GyeFeedType.allInChallenge`(wire `all_in`)** 신설 + 모델 wire 양방향 매핑.
- **`GyeService.markAllInAchieved(gyeId)`** — **결정적 doc id `allin_<주키>`로 set**: 여러 멤버 클라가 동시 감지해도 첫 작성만 create(허용), 나머지는 update라 rules `allow update: if false`가 거부 → **중복 0**(서버 dedup 없이 rules로 보장). 주키는 CF weekly_goal_rollover 리셋 경계와 일치.
- **dure_board**: 전원 기여 달성 순간 burst와 함께 `markAllInAchieved` 호출(실행당 1회 인메모리 가드 + 주별 doc dedup 이중).
- **gye_feed**: allInChallenge 렌더(🔥 아이콘·tiger 색·`gyeFeedAllIn` 메시지) + 반응 가능 이벤트에 포함. l10n DE/EN.
- 단위테스트 +2(wire 라운드트립·전 타입 오타 가드).

**이로써 Phase D 4건 전부 plan 명세대로 완료** — 프로필 카드·MVP 카드·피드 reaction(D-3)·전원챌린지(burst+피드). **감사 plan의 모든 코드 작업 종료.**

**검증:** `flutter analyze` **0** · `flutter test` **400 통과** · ARB parity **922=922**. ⚠️ 미검증(Jin): 실기기 2계정 all-in 피드 dedup 실동작.

**Git:** 커밋·푸시 완료.

### 2026-06-12 (후속 — B-2/B-3 마무리 + Phase D-3 피드 reaction 구현) — 커밋·푸시

**범위:** Jin "B-3 확인 후 다음 진행" → B-2/B-3 잔여 화면 마무리 + Phase D 4건 중 유일 미구현이던 **피드 reaction(D-3)** 구현.

**B-2/B-3 마무리(커밋 e975d5f):** B-3 버튼 전수 분류 = 잔여 raw 버튼 **전부 AlertDialog 액션(Material 관례 — SoriButton 강제 시 레이아웃 깨짐, 의도적 유지)**. 잔여 `Container(decoration:)`도 칩/필/그라데이션/아이콘배경이라 카드 아님 — 진짜 수제 카드만 골라 **book_result `_WordCard`·`_GrammarCard` → SoriCard** 이행. 타이포 토큰화: scenarios_list·book_result·listening(대사 22px는 콘텐츠라 예외 유지). 웹 시각검증: 시나리오 리스트·듣기 화면 일관·잘림 0 스크린샷 확인.

**Phase D-3 피드 reaction(이번 커밋):** GyeSticker.targetEventId 스키마만 있고 미구현이던 항목 완성.
- `GyeService.sendReaction(gyeId, targetEventId, code)` — sendSticker와 동일하나 `payload.targetEventId` 부착. 스티커 레이트가드(분당10) 공유.
- `GyeFeed.splitReactions`(순수 함수, 테스트 대상) — 이벤트를 (타임라인, 반응 by targetEventId)로 분리. 반응은 독립 항목으로 안 띄우고 **대상 이벤트 아래 28px 스티커 묶음**으로 렌더.
- 마일스톤 이벤트(클리어·퀘스트·레벨업·목표달성)에만 "반응"(add_reaction) 버튼 → gye_screen `_openReactionPicker`가 StickerPicker 오픈 → sendReaction. 자유 텍스트 X = 모더레이션 안전.
- **rules 변경 0**(feed는 active 멤버 append·payload 제약 없음 → reaction 그대로 통과). l10n `gyeReactTooltip`(DE Reagieren/EN React). data-safety.md·MASTER_REDESIGN §D 출시 구현으로 갱신(포스트런치 표에서 제거).

**검증:** `flutter analyze` **0** · `flutter test` **398 통과**(+3 splitReactions) · ARB parity **921=921** · gen-l10n OK · dart format. ⚠️ 미검증(Jin): 실기기 reaction 멀티유저 실동작(Firestore 2계정), feedStream limit 20 내 반응 가시성. **이로써 Phase A~E + B-2~B-5 + 감사 전 항목 코드 작업 완료.**

**Git:** 커밋·푸시 완료.

### 2026-06-12 (호랑이 영상 통합 — 홈 밴드 + 온보딩 첫 만남) — 미커밋

**범위:** Jin이 호랑이 영상 2개+인사 오디오 제작("메인에 쓸 거 어디에 넣으면 좋을까") → Q&A 확정: ①홈+온보딩 둘 다 ②오디오는 온보딩 첫 만남만 ③흰 배경 multiply 블렌드. plan `users-sujinpark-downloads-mp4-…-cheeky-platypus.md` 승인 실행. 프레임 "전환 끊김" 문제(Rive 경로 보류 중)의 실질 해소.

**소스 실측:** `tiger_greet.mp4`(4.0s 640² H.264+AAC 2.3MB)·`tiger_pace.mp4`(8.0s 4.1MB)·`tiger_greet.mp3`(4.1s 45KB). **알파 없음** — 배경 차가운 흰색(~#F0F4F2) 박힘.

**Update:**
1. **에셋**: `assets/video/`(신규, pubspec 등록) `tiger_greet/pace.mp4` + `assets/sfx/tiger_greet.mp3`. ASCII 파일명(한글명 빌드 차단 전례). deps `video_player ^2.11.1`.
2. **`lib/widgets/sori/tiger_video.dart` 신규** — `TigerStageVideo`(홈: greet launch당 1회→크로스페이드→pace 루프, 무음)+`TigerGreetClip`(온보딩: greet+mp3). **설계 변경(§0 실측):** plan의 saveLayer 블렌드는 비디오가 Texture 엔진 레이어라 미적용 → `ColorFiltered(ColorFilter.mode(크림, multiply))`(컴포지터 레이어, 텍스처에 적용됨)로 대체. 흰 배경→크림 흡수, 결과 박스는 **불투명 크림**(뒤 입자 가림은 미미). 홈 blendColor 기본 `#F8F2E4`(그라데이션 중간값 튜닝 노브)·온보딩 `lightBg`(플랫이라 완전 일치). 폴백: `!videoReady`(테스트 기본)/reduce-motion/다크/로드 실패 → `TigerStageRive`→프레임. 라이프사이클: `WidgetsBindingObserver`+`TickerMode.getValuesNotifier`(getNotifier는 deprecated) pause/resume.
3. **배선 4곳**: 홈 `_TigerHero` `TigerStageRive`→`TigerStageVideo`(1줄) · main.dart `TigerStageVideo.videoReady=true` · QuickOnboarding 페이지1 `Mascot`→`TigerGreetClip(size:200, playAudio:true)`(다크면 기존 Mascot 유지)+페이지별 자동넘김 `[4600,3000,3000]ms`(영상 4s 수용, 리스너 중복 reset/forward 제거) · AppShell IndexedStack 자식 `TickerMode(enabled: i==_index)` 래핑(숨은 탭 영상·애니 정지).
4. **온보딩 미적용 화면**: `onboarding_preview`(다크 배경 #0E1A18)는 multiply 부적합 → 미손댐.

**검증:** `flutter analyze lib test` **0** · `flutter test` **395 통과**(392+신규 `tiger_video_test` 3: videoReady=false→프레임 폴백·reduce-motion·GreetClip→Mascot) · `flutter build apk --debug` ✓ + **APK 내 영상 3에셋 번들 실확인**(unzip) · dart format. **⚠️ 미검증(Jin 실기기 `flutter run -d 9053622f`)**: ①홈 인사→루프 전환·**블렌드 박스 경계**(보이면 `TigerStageVideo.blendColor` 튜닝) ②온보딩 첫 실행 페이지1 영상+음성 동기·4.6s 넘김 ③탭 전환·백그라운드 pause 복귀 ④reduce-motion 프레임 폴백. 용량 +6.4MB(원본 그대로 — pace 4.3Mbps 재인코딩 절반 가능, 화질은 Jin 판단).

**Git:** 미커밋 (Jin 확인 후).

### 2026-06-12 (출시 전 품질 감사 + 5-Phase 개선: DSGVO opt-in·SoriSheet·차단·계 확장·bookshelf 복원) — 미커밋

**범위:** Jin "출시 전 디자인·콘텐츠·앱품질·회원관리·독일 정보보호법·Play 정책 거짓/환각 없이 판정 + 개선 계획·실행". 멀티에이전트 감사(35 agents, P0/P1 적대적 재검증) → plan `soft-stirring-hartmanis.md` 승인 → 5 Phase 실행. Jin 결정: Analytics **opt-in**, 범위 전체(약관·bookshelf·차단·계 확장·디자인 통일·다이얼로그 잘림).

**감사 판정(실측):** 안정성 🟢(analyze 0·test 362·CI green) · 콘텐츠 🟢(EN 100%·독일어 네이티브급) · 디자인 🔴(인라인 TextStyle 409 vs 토큰 59·fontSize 26종·버튼 59% 우회) · 회원관리 🟡 · **DSGVO 🔴(동의 前 Analytics/Crashlytics 무조건 수집 + privacy.html:246 "구성됨" 허위 기재 + opt-out 0 + Impressum 0 + FCM/TTS/RevenueCat 처리자 미기재)** · Play 🟡(차단 없음·Data Safety stale).

**Phase A — 법적 필수 (DSGVO·TTDSG·DDG):**
- **Analytics/Crashlytics opt-in 전환**: AndroidManifest+Info.plist `*_collection_enabled=false`(첫 프레임 전 원천 차단) + 신규 `lib/services/privacy_consent_service.dart`(applyStored/setAnalytics/setCrash) + main.dart `_initFirebase` 배선 + consent_screen **체크박스 2개(기본 OFF)** + settings "Datenschutz" 섹션 토글 2개(Art.7(3) 철회) + `Storage.analyticsConsent/crashConsent`. 기존 테스터도 미동의 시작(안전 기본값).
- **privacy.html 전면 정정**(EN/DE/KO): :246류 허위("under-13 구성됨")→opt-in 사실 기술, 처리자 표에 FCM·Cloud TTS·우리말샘·RevenueCat·Remote Config/Storage 추가, §2.5~2.8 신설(opt-in·계 데이터·TTS), withdraw 경로 구체화, Impressum 링크.
- **`docs/impressum.html` 신규**(DDG §5 — ⚠️ 도로명 주소·HRB는 placeholder, Jin 기입 필수) + index.html/privacy 푸터 링크 + 앱 settings About에 Impressum/약관 링크.
- **`docs/terms.html` 신규**(DE/EN 약관: UGC 행동수칙·구독/Widerruf §356(5) BGB·책임제한·ODR — ⚠️ 법률 검토는 Jin) + consent_screen 약관 링크 + footnote 갱신.
- **계정 삭제 로컬 정리(Art.17)**: `WordImageService.deleteAll()`(wordbook_images/) + `TtsService.clearCache()`(tts_cache/) 신규 → settings 계정삭제·전체리셋 양쪽 배선.
- **버전 정합**: release-notes-v2.md `v2.0.0-alpha`→`2.0.1+4`(pubspec 일치).
- 테스트: consent opt-in 회귀(`profile_screen_test` — 기본 OFF·체크만 영속).

**Phase B — 디자인/UX (Jin 최우선 "잘림" 버그):**
- **잘림 원인 분석**: 53개 팝업 전수 감사에서 깨진 패턴 0 — 유력 원인 = main.dart `SystemUiMode.edgeToEdge` + SafeArea 없는 바텀시트가 시스템바/컷아웃에 가림(hangul_screen:178 주석이 동일 증상 과거 수정 흔적). **Jin 재현 화면 제보 여전히 유용.**
- **`lib/widgets/sori/sheet.dart` 신규** — `showSoriSheet`/`SoriSheetShell`: useSafeArea+내부 SafeArea+maxHeight 88% clamp+자동 스크롤+텍스트스케일 1.3 clamp+grab handle+키보드 inset. **바텀시트 13곳 전부 이행**(feature_coach·account_nudge·gye 스티커·dure 응원·home gye chooser·daily_char·smalltalk·grammar/legacy 필터·custom_pack 에디터·bookshelf 공유·settings 관심사; settings 출처 시트는 Draggable 유지+useSafeArea). 위젯테스트 `sori_sheet_test.dart`(2000px 내용→88% clamp·1.6×스케일→1.3 clamp).
- **홈 주 CTA**: 호랑이 히어로+스탯 직후 풀폭 `SoriButton.filled` "Jetzt lernen"(tiger 주황) → 현재 팩 직행(없으면 /path). l10n `homeLearnNowCta`.
- **텍스트스케일 회귀 매트릭스**: responsive_test에 전 21화면 ×1.3 케이스 추가 — 전부 통과(기존 Flexible 작업 덕).
- ⚠️ **잔여(후속 세션)**: B-2 타이포 SoriTextTheme 전면 채택(인라인 409→토큰), B-3 버튼 68·수제 박스 74 통일 — plan 문서에 화면 우선순위 명시됨.
- **B-2 1차 배치(같은 날 후속, 커밋 별도)**: `SoriTextTheme`에 앱 최빈 역할 2종 신설 — **`cardTitle`(14/w800)·`cardSubtitle`(11.5 muted)** (기존 8종으론 카드 패턴이 안 맞아 억지 매핑 대신 토큰 확장이 정답). **home(34→역할 일치 18곳 토큰화)·stats(18→10)·vocab_packs(5→3)** 이행 — 히어로/마이크로(스탯칩 9.5·큰 숫자 38·이모지)는 의도적 예외로 유지. 부수 발견·수정: **하드코딩 한국어 2건**(`'5분이면 충분해요!'`→`homeTigerBubbleResumeSub`, stats `'이번 주'`→`statsThisWeek`) l10n화. 잔여: scenario_player·settings·grammar/legacy·게임 화면 타이포 + B-3 버튼/카드.

**Phase C — Play 정책:**
- **멤버 차단(block)**: `GyeService.blockUser/unblockUser/blockedUidsStream/filterBlocked`(`users/{me}.blockedUids` — 기존 rules로 충분, 본인 문서) + gye_members_screen 차단/해제 토글(확인 다이얼로그·차단 시 취소선+라벨) + gye_screen 피드 필터(차단한 actor + 그를 향한 응원 숨김). 단위테스트 3(filterBlocked).
- **욕설 denylist 확장**: 28→~100 엔트리(KO/DE/EN, 거짓 양성 함정 의도 회피 — ass/anal/cock/한남동/년 단독 미등재) + 거짓양성/신규차단 테스트.
- **data-safety.md 최신화**: opt-in 전환·UGC/Moderation 섹션(신고·차단·필터·16+·IARC "users interact"=JA)·계정삭제 구현 반영(구 "미구현" stale 정정)·Gye 데이터 행 추가.

**Phase D — 계 커뮤니티 확장 (Tandem 방향 출시분):**
- **멤버 프로필 카드**: GyeMember에 `level`/`streakDays` denormalize(create/join 초기값+`syncMyMemberStats()` gye 진입 시 갱신) → 멤버 탭 시 SoriSheet 카드(레벨·스트릭·주간 기여).
- **지난주 살림꾼(MVP) 카드**: GyeMeta `lastWeekMvp`/`lastWeekMvpPacks` + CF `weekly_goal_rollover`가 기록(node --check OK, **⚠️ CF 재배포 = Jin**) → GyeScreen 두레판 아래 축하 톤 1줄 카드(`_MvpCard`, 경쟁 어조 금지 — 리서치 F5/6 준수).
- **전원챌린지 축하**: 전원 기여 달성 순간 `SoriCelebration.burst`(2인+, 실행당 1회).
- **포스트런치 로드맵**: MASTER_REDESIGN §9 신설 — 자유채팅/공개검색/1:1매칭 보류 사유·선행조건 명문화.
- l10n `gyeMvpCard`·`gyeProfile*`·`gyeBlock*` 등 DE/EN.

**Phase E — 데이터 보존·품질:**
- **bookshelf 클라우드 복원**: CloudSync `bookshelf_json` 백업+복원(로컬 비어있을 때만, custom_packs와 동형) — 기기 변경 시 책 한 컷 손실 해소. round-trip 테스트.
- catch(_) 로깅 보강(bookshelf Firestore save/delete·push token persist/remove → debugPrint).
- consentBody 재작성(EU 서버 처리 항목 명시).

**검증:** `flutter analyze` **0** · `flutter test` **392 통과**(362→392, 신규 30) · ARB parity **918=918** · gen-l10n OK · CF `node --check` OK · dart format 적용. **⚠️ 미검증(Jin)**: 실기기 시각(동의 체크박스·설정 토글·SoriSheet 13곳·홈 CTA·차단·프로필 카드·MVP 카드), CF 재배포(`cd functions/gye && firebase deploy --only functions`), Impressum 주소 기입, terms 법률 검토, Play Console Data Safety 폼 갱신(opt-in으로 답 변경), gye 크래시 재현, hangul-sori.com 반영(docs/ 푸시).

**Git:** 커밋·푸시 완료 — df9d4e4(5-Phase) · 6e76347(B-2 1차) · f02e73e(B-2 2차).

### 2026-06-12 (후속 — 웹 시각검증 + 🔴 gye 크래시 근본 원인 확정·수정) — 커밋·푸시

**범위:** Jin "끝까지 진행 후 앱 열어 스크린샷 전수검증". `flutter run -d web-server`(8099) + 헤드리스 프리뷰로 실행. **헤드리스 occluded 탭은 rAF가 안 와 Flutter 엔진 동결** → `web/index.html`에 `?forceRaf=1` 게이트 심(rAF→setTimeout, 일반 사용자 무영향) 추가로 우회. Flutter 시맨틱스 활성화(placeholder 클릭)로 버튼 조작·플로우 주행.

**🔴 gye `_dependents.isEmpty` 크래시 — 웹 재현 성공 → 근본 원인 확정 → 수정:**
- **재현 경로:** Gye 탭 → Create a Gye → 생년(age-gate) 다이얼로그 → Cancel → Profile 탭 = 레드스크린.
- **근본 원인(디버그 스택 실측):** `A TextEditingController was used after being disposed` — age_gate_prompt.dart:69 TextField. `await showDialog` **직후** `controller.dispose()` 하는데 **다이얼로그 퇴장 애니메이션 동안 TextField가 리빌드**되며 disposed 컨트롤러 사용 → 엘리먼트 트리 오염 → 후속 네비게이션에서 `_dependents.isEmpty` assert. 실기기 "키보드(showSoftInput) 직후" 정황과 일치.
- **수정:** 같은 안티패턴 2곳(정규식 전수 스캔 = 전부) — `age_gate_prompt._askBirthYear`→`_BirthYearDialog` StatefulWidget(State가 컨트롤러 소유), `gye_members_screen._report`→`_ReportDialog` StatefulWidget(record 반환). **수정 빌드로 동일 경로 재주행 → 크래시 0**(스크린샷 검증).

**검증에서 발견·수정한 추가 2건:**
- 🔴 **신규 사용자 동의 화면 미표시 갭**: splash→QuickOnboarding→CharacterSelection→홈 경로가 ConsentScreen(인트로 경로에만 배선)을 우회 → opt-in 체크박스가 신규 유저에게 안 보였음. character_selection에 `!consentAccepted → ConsentScreen` 게이트 추가. 수정 후 풀 플로우(동의 체크박스→프리뷰→레벨→홈) 스크린샷 검증.
- 🟡 settings `_appVersion()` '1.0.1' stale → '2.0.1'.

**스크린샷 검증 통과:** 퀵 온보딩·캐릭터 선택·**신규 동의 화면(체크박스 2 기본 OFF·Privacy/Terms 링크)**·프리뷰 캐러셀·레벨 선택·account_nudge SoriSheet·홈(신규 "Learn now" CTA·경로 노드·4탭)·설정(**PRIVACY 토글 2**·Terms/Impressum 링크·섹션 라벨 토큰·다크색 부제 버그 해소)·관심사 SoriSheet(Apply 하단여백 16px 실측, 잘림 0)·Practice 허브·Gye 탭·age-gate 다이얼로그·Profile. 수정 후 콘솔 에러 0.

**검증:** `flutter analyze` 0 · `flutter test` **395 통과** · 웹 실행 시각검증 상기. ⚠️ 실기기(9053622f) 최종 확인 권장 — 특히 gye 크래시 동일 경로·TTS 실발화.

### 2026-06-09 (gye 빨간화면 진단 + 네비바 회귀 수정 + 계 초대 기능 + 스태시 정리) — 커밋·푸시

**범위:** Jin 실기기 빨간 화면(`framework.dart:6268 _dependents.isEmpty`) "gye 오류" 제보 → 진단 → 네비바 실종 회귀 발견·수정 → 계 초대 기능 추가 → 묻힌 변경(스태시) 정리. Jin 외출, 자율 진행.

**gye `_dependents.isEmpty` 크래시 — 미재현/원인 미확정 (§0):**
- `assert(_dependents.isEmpty)` = InheritedElement가 dependents 남긴 채 deactivate(보통 GlobalKey 리페어런팅 류). 계 전 화면·위젯(screen 5·widget 6·코치마크·스포트라이트·트랜지션) 전수 Read + **GyeScreen else-branch를 실제 위젯 그대로(DureBoard·GyeHanok·코치마크 + 진입→발화→이탈) 위젯테스트 재현 → 안 터짐.** 빈 데이터로 재현 불가 = 실데이터/타이밍 의존 간헐.
- 정적: 커스텀 InheritedWidget 0, GlobalKey 전부 per-instance(static/공유 0). 키보드(`showSoftInput`) 직전 발생 = TextField 화면(만들기/입장/다이얼로그) 경유 추정.
- **핵심 발견:** `main.dart:164` `FlutterError.onError = Crashlytics.recordFlutterFatalError` 가 디버그 콘솔 출력을 삼켜 빨간화면 스택이 logcat에 안 찍힘(`I/flutter` 0건) → **크래시는 Crashlytics에만 기록.** 디버그에선 `presentError`도 호출하게 수정(에러 가시성 복구) → 다음 재현 시 전체 스택 확보 가능.
- ⚠️ **미해결.** 정확 원인 = Crashlytics 스택(또는 다음 콘솔 재현) 필요. 네비바 수정이 트리거 맥락(bare HomeScreen)을 없애 부수 해소될 가능성 있으나 미검증.

**네비바 실종 회귀 — 수정 ✅ (커밋 d717285):**
- 원인: `intro_gate_screen.dart:96` + `consent_screen.dart:41` 의 "온보딩 완료→메인" 분기가 `AppShell`(R1 4탭 셸) 대신 옛 `HomeScreen`(네비바 없음)으로 보냄. R1 IA 도입 시 안 고쳐진 잔재 → 정상 실행이 bare HomeScreen 착지 → 하단 4탭 실종. (`onboarding_level`은 이미 `/`=AppShell로 가 일치.)
- 수정: 둘 다 `const AppShell()`. ⚠️ 기기 시각검증은 Gradle 빌드가 Android Studio 데몬과 충돌해 멈춰 보류 — 코드는 확실.

**계 초대 기능 — 신규 ✅ (커밋 6234261):**
- 계 마당 초대 동선 0(코드는 생성 직후만 공유) → 멤버 1명 계 = 빈 두레판/피드만 보여 "미구현"처럼 느껴짐. **dure 로드맵 5/5(두레판·피드·응원·MVP회고·전원챌린지)는 이미 완성**(89f32ea) — 그 위에 멤버 모으기 보강.
- `gye_screen.dart`: ⋮메뉴 "Code teilen"(초대) + `memberCount<=1` 시 `_SoloInviteCard`(초대 유도+코드+공유). `_shareGyeCode`=OS 공유 시트. l10n `gyeInviteTitle/Body`(DE/EN), 기존 `gyeShareMessage/Code` 재사용.

**묻힌 변경(스태시) — 보존 + 보고 (커밋 안 함):**
- `stash@{0} WIP on 948e207`(app_shell/home_screen/practice_hub/tiger_stage/l10n nav `Start→Pfad`·`Profil→Ich`). **base 948e207 이후 해당 파일 685+줄 변경 → 스태시 전 파일 patch 충돌(does not apply).** R1 IA·tiger 작업에 superseded된 WIP. **자율 강제 병합 = R1/tiger 회귀 위험** → drop 안 하고 stash 유지·로그에 기록. 원하면 `navHome→Pfad`·`navProfile→Ich` 라벨만 수동 추림 권장.
- 미푸시 커밋 0(로컬==origin 였음). 동시 세션이 `docs/TIGER_FULL_REMAKE_MASTER.md`·`docs/dokkaebi_fire_prompt.md` 편집 중 → 미손댐.

**검증:** `flutter analyze` 0(lib test) · `flutter test` **362** · ARB parity 895=895 · gen-l10n OK. ⚠️ 미검증: 실기기 시각(네비바·계 초대 카드 — Gradle 멈춤), gye 크래시 실제 원인(Crashlytics), 4픽 MVP회고 CF 재배포(Jin: `cd functions/gye && firebase deploy --only functions`).

**Git:** d717285(nav)·6234261(gye 초대) + 본 로그 → origin/main 푸시.

### 2026-06-09 (독일어·영어 현지화 딥다이브 — UI·콘텐츠·시나리오 네이티브 패스) — 미커밋

**범위:** Jin "내부테스트 전 완성, 특히 독일어 현지화 — 진짜 독일/영어권 뉘앙스로 구현됐는지 딥다이브 더블크로스체크 + 적극 개선." 전 표면 적용 + 뉘앙스 적극 격상 확정. SSoT: `docs/LOCALIZATION_DEEP_DIVE_2026-06-09.md`.

**방법:** Opus가 양 언어 네이티브 판정·편집. Sonnet 서브에이전트 6개로 1차 플래그(ARB 2렌즈·시나리오 DE/EN·vocab·grammar) → Opus 어드주디케이트(에이전트 후한 판정·오판·환각 걸러냄).

**Update:**
- **UI ARB ~115문자열**(`app_de`+`app_en`.arb): DE/EN 의미불일치(`reviewTitle` "Heute lernen"→"wiederholen", EN "Today's review" 일치), 성별버그(`previewPage2Title` "Deine"→"Dein Hanok"), 복합어(`statsWordleWins`→"Wordle-Siege"), 비네이티브 영어(`welcomeMsg` "All the best today"→"You've got this today" 등), gye(Pakete→Packs·du fehlst uns)/book(knipsen→fotografieren)/onboarding/consent 뉘앙스 격상. parity 839=839, gen-l10n OK.
- **독일어 학습 콘텐츠 48건**: `grammar.csv` 34(종속절·관계절·um-zu·sondern/aber 쉼표, zuhause→zu Hause) + `korean_vocab.csv` 14(답변/호격 쉼표 "Ja, das stimmt"·"Ich liebe dich, Papa"). 쉼표 필드 RFC 따옴표 처리 → CSV 열수 무결(14/11, 0불량).
- **시나리오 독일어 13건**(`scenarios.json`): "Ich mich auch"→"Freut mich ebenfalls", **"unbeleidigt"(비단어)→"verletzt"**, "dieses Phrase"→"diese", Sprite→Limo(사이다), 회식 du→Sie, business "먼 길 오셨네요" 복원 등. JSON 검증.
- **하드코딩 l10n 갭**: 신규 4키(`bookCaptureWebNotice`·`introSkipHint`·`bookshelfCreatePackNameHint`·`settingsMadeWith`) + 6화면 배선(book_capture 웹안내·intro skip·chosung 타이틀→`gameChosungTitle`·bookshelf 힌트·settings footer; intro_gate AppL10n import 추가). analyze(6화면) 0.

**§0 발견:**
- ⚠️ **영어 시나리오 리뷰 서브에이전트가 대사를 환각**(파일에 없는 라인 verbatim 인용 — "room key"/"Kakao Taxi" 등 grep 0) → count==1 가드로 전부 차단, 미적용. **영어 시나리오 대사 자연화는 신뢰 리뷰 후 후속**(독일어 시나리오 에이전트는 전부 정확 매칭).
- ⚠️ **Phase 4(영어 학습 콘텐츠)는 동시 세션이 이미 완료** — `vocab.csv`(english/pos_en/example_english)·`grammar.csv`(type_en 등)·`models/vocab|grammar.dart` `meaning(lang)` helper 존재 확인 → **중복 회피, 미손댐**.

**검증:** ARB parity 839=839 · gen-l10n OK · analyze(touched 6화면) 0 · CSV 14/11열 0불량 · scenarios/JSON valid · **17/17 대표 변경 잔존 재확인(동시 세션 클로버 없음)**. ⚠️ 미검증: 실기기 시각·DE/EN 토글 양 언어 스팟체크 = Jin.

**동시 세션 주의:** vocab/grammar/models/tiger_anim/screens/CLAUDE.md 동시 편집 활발 — 내 변경은 독립 표면(German example 컬럼·ARB 값·시나리오 DE·l10n 갭)만 손댐. 커밋 시 Jin 분리 검토 권장.

**Git:** 미커밋 (Jin 확인 후).

### 2026-06-09 (듀오링고급 IA 재설계 + 스포트라이트 코치마크 + 온보딩 프리뷰) — 커밋·푸시 완료

**범위:** Jin 실기기 "게임/단어 사라짐" → deep-research(대기업 언어앱) → 완성형 개편안 → R1 IA + 홈 path 본문화 + CI 정상화 + 스포트라이트 코치마크 + 온보딩 프리뷰. (아래 "CI 실패 진단" 항목이 본 세션 커밋 `c99739a`/`cca3417`/`bdc35a0`를 동시세션이 "Jin 커밋"으로 오인 기록 — 전부 본 세션 작업.)

**deep-research(112 agents·29소스·검증 12/22, `Workflow`):** Duolingo 1차출처 등 — ①홈=단일 path 중심, 기능 탭 분산 X(F1, 3-0) ②경쟁 리그/리더보드=최악 안티패턴·dark-nudge(F5/6) ③계(契) 비경쟁 협력=연구 지지(F9/10/11, "잘 설계된 협업=경쟁과 동률·해악 없음") ④적응형 SRS +12%(F12). 게이미피케이션 효능 일반주장은 검증 탈락. 산출 `docs/MASTER_REDESIGN_2026-06-06.md`.

**R1 IA(bdc35a0):** 기존 4탭(홈/배우기/연습/단어장 평면분산=안티패턴) → **4탭 [홈/연습/계/나]** + 연습 탭에 배우기·게임·단어 3 named 섹션 통합(F2/3, 발견성 복구). 계 탭 승격(차별점), 나=ProfileScreen. `app_shell`/`practice_hub` 재작성 + `gye_tab_screen` 신규.

**홈 path 본문화(dbe573a→cacde06):** `_PathCard`(카드 1장) → `learning_path` 노드(✓/Jetzt/🔒)를 홈 본문 직접 임베드(F1). `PathNode` 공유 위젯 추출(home+learning_path 재사용).

**오버플로 fix(ee0da4e):** 동시세션 `StreakDisplay`가 `_TopBar` 308·360px서 118px 오버플로 + streak 중복(StatChip 칩) → 제거.

**CI 정상화(c99739a+cca3417):** `flutter analyze`가 info도 exit1 → CI #93~#101 빨강 9개. ci.yml `--no-fatal-infos` 추가 + info 8건 **근본 수정**(withOpacity→withValues 7 + BuildContext `mounted` 가드 1, 동시세션 파일). 이후 green.

**스포트라이트 Stage A(694692d):** `lib/widgets/sori/spotlight_coach.dart` **신규**(Overlay+CustomPainter `Path.combine` 구멍 + 말풍선 자동배치 + reduce-motion, 패키지 0·직접 구현). AppShell 4탭 GlobalKey(Stack 앵커, 레이아웃 무변경) + 첫 진입 투어 5단계(4탭+학습경로, `tutHomeTourSeen`). **+ 온보딩 멈춤 버그 fix**(`quick_onboarding` `_currentPage<2→<3` — 첫 유저가 스트릭 페이지에서 100% 멈추던 출시 차단). plan `keen-launching-scott.md`.

**온보딩 프리뷰(c877295):** `mascot.dart` 호랑이 프레임 전환을 150ms `AnimatedSwitcher` 크로스페이드(정면↔눈감기 하드컷 끊김 해소, 전역). `onboarding_preview` page0=`book_success`·page1=`gye_gate_grand` 이미지 교체(어색한 아이콘 뱃지 제거) + page2 도깨비불 PNG(미존재 시 불 아이콘 글로우 폴백). 도깨비불=Jin 생성 대기(Faceted Minhwa 프롬프트 제공, `data_integrity` pending allowlist).

**검증:** `flutter analyze lib test` **0** · `flutter test` **362** · `flutter build apk --debug` ✓(exit 직접 확인) · DE=EN parity. ⚠️ 시각/실기기(스포트라이트 투어·크로스페이드·캐러셀 이미지·도깨비불 생성 후)=Jin.

**한글명 PNG 빌드 차단(중요):** `tiger_anim` 한글 파일명 4장(예: `앉아있는 오른쪽보는 호랑이.png`)이 web/apk 빌드 시 flutter_assets URL인코딩 255자초과(errno 63)로 빌드 차단 → `~/kl_tiger_korean_backup` 백업 이동(삭제 X). **동시세션이 영문명으로 재투입 필요**(한글명 커밋 시 CI 빌드 깨짐).

**Git:** R1~온보딩 8커밋 origin 푸시 완료(동기화 0/0).

### 2026-06-09 (CI 실패 진단 — 빨간 X 9개 전수 분석) — 커밋·푸시(3120cda, c877295 푸시에 동반)

**범위:** Jin이 GitHub Actions 화면 스크린샷(런 #93~#101 빨간 X 9개) 공유 → "에러난 거 전부 뭔지 파악해서 의도한대로 실행되게." `gh run view --log-failed`로 9개 런 전수 실측(§0 — 추측 없이 로그 인용).

**진단(9건 전부 동일 단일 원인):** `analyze` step이 **info 레벨 이슈에서 exit 1** → CI 차단. **컴파일·빌드 에러 0건**(실패 런 전부 ~1분에 analyze에서 죽음 / 통과 런은 빌드까지 ~2.5분). 이슈 정체 = 전부 info급: `withOpacity` deprecated(→`withValues`) + `use_build_context_synchronously` 1. 새 화면 누적 — #93(7bd5e86 온보딩) 3건(quick_onboarding) → #94(1a47b6f 게임화) 6건(+quiz_choice·streak_display) → #95~#101 8건(+character_selection BuildContext 가드+withOpacity). 당시 CI 명령이 `flutter analyze --no-fatal-warnings`뿐이라 info를 못 막음.

**이미 해결돼 있던 상태(이 세션 전, Jin 커밋):** `c99739a`(ci.yml에 `--no-fatal-infos` 추가) + `cca3417`(info 8건 소스 근본 수정 — withOpacity→withValues + `mounted` 가드) → 이후 4개 런 전부 green. 실측 확인: `lib/` 내 `withOpacity` **0건**, 플래그됐던 파일 전부 `withValues`/`mounted` 적용.

**Update(이 세션 — 1건):** 유일 잔여 info — [test/spotlight_coach_test.dart](test/spotlight_coach_test.dart)의 `main()` 내부 로컬 함수 `_wrap`(`no_leading_underscores_for_local_identifiers`, CI는 통과하나 거슬림) → `wrap` rename(선언+호출 6곳). 다른 test 파일의 `_wrap`은 top-level private라 정당 → 미변경.

**검증(로컬 Flutter 3.44.0 = CI 동일):** `flutter analyze` → **No issues found!**(info 포함 0, exit 0) · CI 명령 `flutter analyze --no-fatal-warnings --no-fatal-infos` → exit 0 · `flutter test test/spotlight_coach_test.dart` → **8/8**(rename 회귀 0). working tree Dart 변경=이 1파일뿐.

**Git:** Jin 요청으로 커밋(test 1 + 본 로그). tiger_anim walk PNG 16·docs md는 Jin 별개 작업물이라 제외. 푸시는 미요청.

### 2026-06-05 (고품질 음성 — Google Cloud TTS 캐시우선 3단) — 커밋·푸쉬

**범위:** Jin "우리 음성 정확한데 진짜 사람 목소리처럼(예: 내 목소리로) 안 돼?" → Q&A로 방향 확정: **voice cloning 아님, 자연스러운 원어민 neural**. 데모 청취로 voice 선택 → 사전생성+동적 파이프라인 구축.

**voice 선택(Jin 데모 청취):** ko-KR 41개(Chirp3-HD 30·Neural2 3·Wavenet 4·Standard 4) 중 대표 샘플 합성 → Jin이 직접 듣고 **여=`ko-KR-Chirp3-HD-Aoede`, 남=`ko-KR-Neural2-C`** 확정. (난 오디오 청취 불가 → 샘플 mp3 만들어 Jin이 판단. 데모 `~/Desktop/hangul_sori_voice_samples`.) 사전생성 속도 0.9(또박).

**아키텍처(캐시우선 3단, 모든 발화가 `tts/{voice}/{sha1("voice|text")}.mp3`로 수렴):**
1. 로컬 캐시(앱 문서폴더) → 즉시 재생(오프라인·무료)
2. Firebase Storage 사전생성 → 다운로드·캐시 (526단어+526예문+204대화 = **1245 dedup**, female)
3. Cloud Function 동적 합성 → base64 (책한컷·내단어장 사용자 입력, male on-demand)
4. flutter_tts 폴백 (오프라인+미캐시)

**Update:** `tts_service.dart` 재작성(인터페이스 유지=23화면 무수정, audioplayers·sha1·path_provider·firebase_storage) · `functions/tts/`(동적 CF, @google-cloud/text-to-speech+Storage 캐시, europe-west3 2nd gen) · `tool/generate_tts.py`(REST 합성+gcloud rsync, 재실행 안전) · `storage.rules`(tts/ 인증만 read·write 차단) · `firebase.json`(storage+tts codebase) · `pubspec`(firebase_storage ^12.3.0) · `.gitignore`(.tts_pregen).

**인프라(실배포 완료):** Cloud TTS API 활성화 · Firebase Storage **europe-west3**(첫 시도 us-west3 됨 → 버킷 삭제 후 재생성) · CF `synthesize_tts(europe-west3)` ✅ · storage.rules ✅ · 사전생성 **1245/1245 업로드 ✅**.

**검증:** `flutter analyze lib` **0** · `flutter test` **330** · Storage 1245/1245 · CF·rules 배포. ⚠️ **미검증: 실기기 실제 음성(Aoede) 재생** = Jin 청취.

**origin 빌드 복구:** 직전 동시세션 `cfbe96b`("fix(hangul)")가 main.dart의 TtsService 배선(import+setEndpoint)만 휩쓸어 커밋하고 `tts_service.dart`(setEndpoint 정의)는 누락 → **origin/main이 빌드 깨진 상태였음**. 본 커밋이 tts_service 새버전으로 복구. (main.dart는 이미 origin이라 본 커밋서 제외, google-services.json도 제외.)

**비용:** 사전생성 1회 ~38K자 무료티어 0원. 동적 무료 100만자/월. egress 미미.

**Git:** Jin 명시 요청으로 커밋·푸쉬.

---

### 2026-06-05 (학습 화면 UI/UX 폴리시 — 완료 축하화면·Grammar·플래시카드) — 미커밋

**범위:** Jin 실기기 피드백 — "Lernpfad 끝냈는데 호랑이·까치 이미지 + 화면 UI 퀄리티가 떨어진다. 축하 화면인데 두 마스코트가 각각 떨어져 떠 있어 뭐 하는 건지 모르겠다." Q&A로 스코프 확정(약한 학습 화면 전체 + 완료 축하화면 UI/UX 재설계). plan: `lernpfad-foamy-quill.md`.

**진단(실측·§0):**
- 🔴 **완료 축하 시퀀스 깨짐(버그)**: [vocab_pack_result_screen.dart](lib/screens/vocab_pack_result_screen.dart) `_CelebrationSequence._playSequence` — 주석 "1.5s"인데 `Duration(seconds: 1500)`(=25분) 오타 → phase0(`_MascotsApplaud`: 호랑이 `left:0`+까치 `right:0` 양끝에 떨어져 떠 있음)만 영원히 보이고 의도된 phase1(단청 도장 리빌=보상)은 절대 안 나옴. `_ctrl`은 duration 없이 생성만 된 死코드.
- 🔴 **Grammar 빈 카드**: `_Front`가 `SoriCard>SingleChildScrollView>Center>Column(min)` → SingleChildScrollView가 Center 무력화 → 콘텐츠 상단 쏠림+여백. `exampleKorean`/`German`은 모델에 있는데 뒷면에만.
- 🔴 **버튼 위계 역전**: Zufällig(랜덤=부수)가 큰 filled-orange primary, Weiter는 밋밋한 outlined.
- 마스코트 아트 자체는 정상(Faceted Minhwa 의도대로) — 불만은 배치/연출.

**Update:**
1. **완료 축하화면 재설계** — 1500초 버그 픽스. `_MascotsApplaud` 삭제 → 단일 `AnimationController(1100ms)`가 글로우→도장(중앙 주인공)→호랑이(좌104)→까치(우80)를 한 박자로 elasticOut 등장. 셋이 단청 도장을 **함께 둘러쌈**. 도장 착지(~55%) 시 `SoriCelebration.burst` 1회. 바닥 RadialGradient 글로우로 그라운딩(떠 있음 제거). XP를 `_XpPayoffLine`(카운트업+gold 바)으로. "Geschafft!" 헤드라인(신규 l10n `vocabPackResultGeschafft`). stats·CTA `SoriEntrance` stagger. reduce-motion/재클리어는 최종 정지 프레임+burst 억제.
2. **공유 위젯 2 신규** — `lib/widgets/sori/study_card_face.dart`(`StudyCardFace`: LayoutBuilder+ConstrainedBox(minHeight)+IntrinsicHeight+Column → void 버그 근본 해결, 오버플로만 스크롤) + `study_action_bar.dart`(`StudyActionBar`/`StudyAction`: primary filled·secondary outlined·tertiary ghost 위계 강제).
3. **Grammar** — `_Front` StudyCardFace+예문 미리보기로 채움, `_Back` StudyCardFace. 하단 `StudyActionBar`(Weiter=primary·Hören/Zurück=secondary·Zufällig=ghost). 3중 칩 → 슬림 `SoriProgressBar`+카운터. 카드·바 `SoriEntrance`. 하드코딩 'Tippen für Erklärung'→`t.hintTapForExplanation`.
4. **Legacy Vocab** — `_Front`/`_Back` StudyCardFace(Stack loose 제약으로 콘텐츠 높이 상단정렬되던 걸 채움+중앙정렬+스크롤안전). Hören 롱프레스(느린 TTS) 보존. 하드코딩→`t.hintTapToFlip`.
5. **Wordle·Chosung** — HanokHeader 배너만 `SoriEntrance`(일관성). **게임판·입력·FocusNode·autofocus·IME 무변경**(의도적 최소 터치 — 이미 양호).

**검증:** `flutter analyze lib` **0 issues** · `flutter test` **323 통과** · `flutter gen-l10n` OK · `dart format` 적용(포매터가 펼친 기존 한 줄 if에 중괄호 보강). **⚠️ 시각/애니메이션 미검증** — `initialRoute:'/intro'`+온보딩+CanvasKit 헤드리스라 자동 시각검증 비현실, 완료화면은 Navigator args(보스통계) 필요해 도달 불가 → **Jin `flutter run` 육안**(축하 cleared/미클리어/재클리어·reduce-motion·Grammar 빈여백 해소·버튼 위계·360px).

**변경 파일:** screens: vocab_pack_result·grammar·legacy_vocab·wordle·chosung_quiz / widgets/sori: study_card_face(신규)·study_action_bar(신규) / l10n: app_de·app_en(+generated) +1키.

**Git push:** 미수행 (Jin 확인 후).

### 2026-06-05 (스티커/계 백엔드 검증 + 배포 실측 + 문서 정정) — 미커밋(문서만)

**범위:** Jin "스티커 코드 미구현이 무슨 뜻? 우리 스티커 코드 아무것도 없는 거야?" → 스티커/계(契) 백엔드 실태 전수 검증 + 문서 최종 업데이트.

**스티커 오해 해소(§0, 실코드 Read):** "코드 미구현"은 **틀린 표현**. 스티커는 **완전 구현**됨 — `lib/data/sticker_catalog.dart`(30종=6카테고리×5: 호랑이·까치·단청·한글·음식·도장), `lib/widgets/sori/sticker_picker.dart`(6탭 그리드 `StickerPicker`), `GyeService.sendSticker`([gye_service.dart:341](lib/services/gye_service.dart) 실제 Firestore `feed` append + 분당10 인메모리 레이트), `gye_screen.dart` FAB 진입, `gye_feed.dart` 스티커 이미지 렌더. **단 독립기능 아님 — 계(契) 그룹 안에서만 동작**(계 만들기/입장 → 마당 FAB → 전송 → 피드). 옛 메모("stickers 19 전송 기능 없음")가 같은 날 Tier 3d 구현으로 뒤집힌 걸 표가 못 따라잡은 stale.

**계(契) 백엔드 코드(✅ 전부 구현·커밋·푸시 — `git status` clean, 로컬 main == origin/main):**
- 클라: `gye_service.dart`(CRUD·6자리코드·욕설·스티커·신고·나가기)·`models/gye.dart`·screens 6(create/join/gye/members + 홈 chooser)·`age_gate_service.dart`(GDPR-K 16세).
- 보안: `firestore.rules` gye 블록(멤버/계장/active/admin 게이트·reports collectionGroup·append-only) + `firestore.indexes.json`(reports.createdAt collectionGroup).
- CF: **`functions/gye/index.js`(v2/2nd gen, region europe-west3 고정, node22)** — 3함수(on_pack_cleared·weekly_goal_rollover·on_report_created) + pruneFeed·pushToGyeMembers. `firebase.json` codebase `gye-firebase-functions` 등록. (옛 `main.py`는 Node 전환 완료 — 커밋 d0acb9c·baf3de1. `functions/gye/__pycache__`만 잔재.)
- FCM: `push_service.dart` + `main.dart:103` init + `firebase_messaging ^15.1.3`. admin: `tools/admin/index.html`+README. 테스트: `gye_service_test`(7)·`age_gate_test`(7) — 순수 로직만.

**🟢 배포(`firebase functions:list --project ko-lernen-app`, 2026-06-05):**
> 본 세션 1차 실측(이른 시점)엔 `on_pack_cleared`·`on_report_created` 미배포 + `weekly_goal_rollover` 구버전(v1/node20)만 떠있었음 → **Jin이 그 직후 `cd functions/gye && firebase deploy --only functions` 실행** → 재확인 결과 **4종 전부 v2·nodejs22·europe-west3·ACTIVE**:

| 함수 | Trigger | 상태 |
|---|---|---|
| `analyze_korean_text` | https | ✅ v2/python312 — 책 한 컷 번역·단어추출 LIVE |
| `on_pack_cleared` | firestore.written | ✅ v2/node22 — 팩클리어→계 주간목표 집계 LIVE |
| `on_report_created` | firestore.created | ✅ v2/node22 — 신고 3명→자동정지 LIVE |
| `weekly_goal_rollover` | scheduled | ✅ v2/node22 (Cloud Scheduler ENABLED) |

> **계 자동집계·자동정지·주간 롤오버가 프로덕션에서 실제 작동.** 스티커 질문에서 출발했지만 검증 중 발견한 계 CF 배포 갭(트리거 2함수 누락·rollover 구버전)을 Jin이 즉시 재배포로 해소한 게 본 세션 실익.

**여전히 미검증(코드/CLI 판정 불가 — Jin/콘솔/실기기 §0):** ① rules 최신본 배포 여부(1d74d0b 이후 `isAdmin`/`isActiveGyeMember` 추가 → 재배포 권장) ② 2계정 Firestore 실동작(생성·입장·집계·신고 suspend) ③ rules 에뮬레이터 ④ FCM 실도달(iOS APNs enable) ⑤ admin custom claim + collectionGroup 인덱스 실배포 ⑥ age-gate 시각.

**문서 정정:** 본 항목 추가 + 파일맵 §계 "Tier 3a 토대만/UI 미구현" → "클라 완성·CF 4종 배포 완료" + `docs/ROADMAP_TO_LAUNCH_2026-06-04.md`·`IMPLEMENTATION_AUDIT_2026-06-04.md` 배포완료 반영(Jin 동시 편집 포함, 내가 놓친 AUDIT line 19·139 보강). 직전 2026-06-04 항목 "미커밋"도 stale 정정.

**Git push:** 미수행 (문서만 변경 — Jin 확인 후).

### 2026-06-04 (구현 감사 + Phase 7·8·9 구현 + FCM + admin) — 커밋·푸시 완료(~baf3de1)

**범위:** Jin "stately-rising-jongga 플랜 전부 구현됐는지 + 모든 md ↔ 코드 1:1 감사 파일 + 상용화 방향" → 이후 "phase 7부터 step by step" → "FCM·admin·커밋·로그 전부".

**A. 감사·로드맵 (신규 2 SSoT):**
- `docs/IMPLEMENTATION_AUDIT_2026-06-04.md` — 70개 md ↔ 코드 1:1(Phase 1~9 Deliverable 체크박스, ~~취소선~~✅/❌/⚠️/🔧). **정정한 stale**: Phase4 quest_catalog는 17퀘 정확 구현(에이전트 "batchim_drop 렌더" 오판 — 그건 scenario_player의 별개 미니게임) · CF는 kiwipiepy(konlpy 아님) · deleteAccount gye cascade 구현됨 · 번역 Firestore 캐시는 rules만 있고 CF는 lru_cache.
- `docs/ROADMAP_TO_LAUNCH_2026-06-04.md` — 상용화 15필수·P0·시나리오 A/B/C·백로그·방향.

**B. Phase 7 (계 공동마당, `functions/gye/index.js` + 클라):**
- `weekly_goal_rollover` 보상: 100%→`lifetimeGoalsAchieved`+1(영구)+`goal_achieved` 피드 · 70%+→`xpBoostActive`. 피드 100 prune.
- `GyeMeta`에 `lifetimeGoalsAchieved`/`xpBoostActive` + `GyeFeedType.goalAchieved`(wire `goal_achieved`) + `gye_feed` 렌더 + DE/EN l10n.
- **`gye_hanok` 영구 unlock 전환**(`lifetimeGoalsAchieved`) — 주간 리셋 시 공동한옥 축소되던 버그 수정.

**C. Phase 8 (모더레이션+GDPR):**
- CF `on_report_created` — 서로 다른 신고자 3명+ → `members/{uid}.status='suspended'` + 신고 reviewed/auto.
- `firestore.rules`: 본인 `status` self-write 금지(정지 회피) + `isActiveGyeMember`(정지자 feed/sticker 전송 차단) + **`isAdmin()`**(custom claim) admin 접근.
- **age-gate**: `age_gate_service.dart`(GDPR-K 16세, 로컬 `Storage.birthYear`) + `gye_service` createGye/joinGye backstop(`GyeError.ageRestricted`) + `age_gate_prompt.dart`(생년 다이얼로그) + `home_screen.showGyeChooser` 가드 + `gye_error_text`/l10n. `test/age_gate_test.dart` 7.

**D. FCM (Phase 7 잔여, 정책 전환 — Jin 승인):**
- `firebase_messaging ^15.1.3`(해석 15.2.10) + `push_service.dart`(권한·토큰→`users/{uid}.fcmTokens`·포그라운드→`NotificationService.showNow` 신규) + `main.dart` init 배선 + CF `pushToGyeMembers`(rollover 목표달성 시 멀티캐스트) + `data-safety.md` FCM 토큰 반영. **⚠️ iOS APNs·FCM enable = Jin. 포그라운드 push는 goal_achieved만(스팸 방지).**

**E. admin 패널 (Phase 8, `tools/admin/`):** 단일 `index.html`(Firebase v9 compat) — 신고 큐(collectionGroup, suspend/dismiss) + 계 조회(멤버 suspend/엔서스펜드·닉변·해체). `README.md`(custom claim 설정·인덱스·배포). **⚠️ custom claim·collectionGroup 인덱스·실동작 = Jin.**

**검증:** `flutter analyze lib` **0** · `flutter test` **310 통과**(+7 age_gate) · CF `node --check` OK · l10n parity 734=734. **⚠️ 미검증(§0)**: CF/rules 실배포·에뮬레이터, age-gate/admin 시각·실동작(Firebase/실기기 필요) → Jin.

**동시 세션 주의:** 본 세션 내내 다른 세션이 35→69 파일 responsive 리팩토링(Scaffold 래핑) 진행 → test 중간중간 transient 컴파일 에러(내 변경 무관, 이동하는 에러로 확인). Jin 선택으로 1회 대기 후 재개. **내 전용 파일만 커밋 권장**(공유: main.dart·home_screen은 내 변경만 들었으나 동시세션 트리에 섞임).

**Git:** 미커밋(Jin 확인) — 또는 본 세션 전용 파일 선택 커밋.

### 2026-06-03 (계정 듀오링고화) — 상용화 진단 + 프로필 허브(Tier 1) + 출시 차단요소(Tier 0) · 커밋 dc291a6

**범위:** Jin "회원계정·가입·로그인·계정삭제·개인정보·회원관리 상용화 단계인지 전수검사 + 듀오링고화 계획 md + 진행". 진단 → md → Tier 1(프로필+온보딩 유도) 구현.

**진단(실제 코드, §0 — 과거 세션로그 일부 stale 정정):**
- 익명우선(`ensureSignedIn`) + Google 단일 링크. 이메일/Apple 로그인 0.
- **`deleteAccount()` 이미 구현+UI 연결**(`auth_service.dart:125`·`settings_screen.dart:499` 위험영역) — 과거 "계정삭제 미구현" 메모는 stale.
- 전용 로그인/회원가입/프로필 화면 0(전부 settings 내부). 온보딩 약관/계정 단계 0.
- privacy.html 충실(EN/DE/KO·GDPR·COPPA·account-deletion.html). 단 settings는 privacy URL **복사만**(url_launcher 미사용).
- 🔴 iOS 폴더 존재인데 Apple Sign-In 없음 → App Store 4.8 리젝 리스크.
- 🔴 RevenueCat `Purchases.configure`만, **`logIn(uid)` 없음**(`premium_service.dart:56`) → 구독↔Firebase계정 분리(복원·크로스기기 불안정).
- CloudSync 수동·부분(`cloud_sync.dart` vok/chosung/wordle/grammar/app만; packs·bookshelf·custom 누락).
- 판정: **안드로이드 출시 가능**(계정삭제·GDPR·rules 충족), iOS·유료구독·리텐션은 미완.

**산출물:** `docs/ACCOUNT_SYSTEM_AUDIT_2026-06-03.md` — 진단표·스토어별 신호등·듀오링고 갭·Tier0~4 로드맵·즉시진행 항목.

**Update(Tier 1 — 계정 1급화):**
1. **`lib/screens/profile_screen.dart` 신규** route `/profile` — 아바타+이름(게스트/Google photoUrl), 계정상태 카드(게스트=Google저장 CTA·연결=로그아웃), 요약 3타일(streak/level/단어), "전체 통계"→/stats. 깊은 통계는 /stats 위임.
2. **`lib/widgets/sori/account_nudge.dart` 신규** `showAccountNudgeSheet` — 온보딩 직후 soft 유도 바텀시트(익명만 노출·가드 내장, 항상 "나중에"). Google 연결 성공 시 `CloudSync.backup`.
3. **진입점**: 홈 `_TopBar` 사람 아이콘 → /profile. 온보딩 `_select`/`_skip`이 레벨 저장 후 시트 → 홈.
4. l10n `navProfile`/`profile*`/`accountNudge*` 16키(de=en parity). 연결 CTA·에러·이름은 기존 `settingsCloud*` 재활용.

**Update(Tier 0 — 출시 차단요소, Jin "전부 진행" 요청):**
5. **Apple Sign-In** — `auth_service.linkWithApple`+`_reauthenticateWithApple`+`deleteAccount` Apple 분기+nonce(crypto sha256, rawNonce→Firebase·해시→Apple). `appleSignInAvailable`(iOS/macOS만). profile·settings·account_nudge에 Apple 버튼(iOS만 노출). ⚠️ Xcode "Sign in with Apple" capability = Jin.
6. **RevenueCat `logIn(uid)`** — `premium_service._bindFirebaseIdentity`: `FirebaseAuth.userChanges()` 구독 → uid 변경 시 `Purchases.logIn`(`_boundUid` 가드). 구독이 익명 RC ID 대신 Firebase 계정 추적(기기변경·재설치·계정전환). main race 무관(리스너 방식).
7. **첫 실행 동의 게이트** — `lib/screens/consent_screen.dart` + `Storage.consentAccepted`. intro `_finish`가 미동의 시 ConsentScreen→(레벨/홈). privacy 링크 launchUrl.
8. **privacy/삭제 URL 브라우저 열기** — 신규 `lib/widgets/sori/external_link.dart`(`openExternalUrl`: launchUrl externalApplication, 실패 시 클립보드 fallback). settings `_copyUrl` 교체. deps `sign_in_with_apple ^8.1.0`/`url_launcher ^6.3.2`/`crypto`. l10n `authAppleSignIn`+`consent*` 6키.

**검증:** `flutter gen-l10n` OK · `flutter analyze`(lib+test) **0** · `flutter test` **257 통과**(신규 `profile_screen_test`: profile·consent 게스트 빌드 스모크 2). ⚠️ Apple 실플로우·Google 링크·구독 logIn·시각은 Firebase/스토어/실기기 필요 → **Jin 검증**(특히 iOS Apple capability·실결제). 동의게이트는 기존 사용자도 1회 표시(정당).

**남음:** Tier 1 자동동기화+범위완성(packs·bookshelf·custom·streak) · Tier 2 이메일/비번 로그인 · iOS Apple capability(Jin). `docs/ACCOUNT_SYSTEM_AUDIT_2026-06-03.md` 로드맵.

**Git push:** 미수행 — **커밋 dc291a6**(내 21파일만; 동시세션 `functions/gye` Node 전환·`firebase.json`은 미포함, Jin 별도).

### 2026-06-03 (Tier 3f+3e) — 신고 UI + 계 나가기 + Cloud Function 스켈레톤 (커밋 be884f6)

**Update:**
1. **3f 신고/멤버** — `lib/screens/gye_members_screen.dart`(route `/gye/members`, GyeScreen ⋮ 진입): `membersStream` 멤버 목록 + 본인 외 신고(사유 4 + 노트→`reports/`). `GyeService.reportMember`/`membersStream`/`currentUid` 추가. 계 나가기는 3c에서 완료.
2. **3e CF 스켈레톤** — `functions/gye/main.py`(firebase_functions SDK): `on_pack_cleared`(Firestore 트리거 → 계 weeklyGoalProgress·contributed 증가 + pack_cleared 피드) + `weekly_goal_rollover`(월 0시 KST 리셋). **미검증 — 배포·검증·FCM·보상로직 = Jin.** 기존 analyze_korean_text(functions_framework)와 별도 source.
3. l10n `gyeMembers*`/`gyeReport*` 11키(parity).

**검증:** `flutter analyze lib/` **0** · `flutter test` **255** · CF `py_compile` OK. ⚠️ Firestore 멀티유저·rules 에뮬·gye_hanok 좌표 시각·CF 배포는 Jin.

**이로써 Tier 3 클라이언트 전부 완료** — 계 생성/입장/마당/공동한옥/스티커/멤버/신고/나가기. 남은 건 **Jin 백엔드/운영**: 3e CF 배포 + FCM, 자동 suspend, 계정삭제 시 gye 멤버십 정리(GDPR), gye_hanok 좌표 육안 튜닝.

> ⚠️ 위 "Tier 3c+3d" 항목의 "남음(3f 신고 UI)"은 본 항목에서 해소됨.

### 2026-06-03 (Tier 3c+3d) — 계 마당 + 공동 한옥 + 스티커 (모든 자산 표시 완료)

**범위:** 계 UI 본체 + 스티커. **이로써 "누락이미지" 미연결 자산 전부 화면 노출**(책5·도장8·gye8·스티커30).

**Update:**
1. **3c 계 마당** — `lib/screens/gye_screen.dart`(meta·feed Firestore stream): 상단 멤버수+`weekly_goal_bar.dart`, 중간 `gye_hanok.dart`, 하단 `gye_feed.dart`, FAB 스티커, ⋮나가기. `gye_hanok.dart`=`MadangBackground`(jongga)+**gye_* 8장** `Positioned` 분수좌표 합성(잠금=ghost 0.22라 8장 모두 노출). unlock=placeholder(`weeklyGoalProgress~/3`, 3e CF가 합산으로 대체). 좌표 시안값=Jin 육안 튜닝.
2. **3d 스티커** — `lib/data/sticker_catalog.dart`(30종 코드↔자산) + `lib/widgets/sori/sticker_picker.dart`(6탭 그리드). `GyeService.sendSticker`(분당10 인메모리 레이트 + feed에 type:sticker append). `gye_feed.dart`가 sticker 이벤트를 **스티커 이미지**로 렌더.
3. **계 나가기** — gye_screen ⋮ → 확인 → `leaveGye` → 홈. `GyeService` 추가: `metaStream`·`feedStream`·`myGyeMetas`·`sendSticker`.
4. 라우트 `/gye`(args gyeId), 생성/입장 성공→`/gye`, 홈 chooser가 내 계 목록 표시. l10n `gye*` 화면/피드/스티커 ~28키(parity).

**검증:** `flutter gen-l10n` · `flutter analyze lib/` **0** · `flutter test` **255**. ⚠️ **Firestore 실데이터/멀티유저/시각 미검증**(Jin: 2계정). 피드·주간목표 자동집계는 **3e CF 대기**(현재 stickers·placeholder만).

**남음(Jin 백엔드/정책 도메인):** **3e** Cloud Functions(`functions_framework` gen2 — `onPackCleared` Firestore 트리거로 weeklyGoalProgress 합산+pack_cleared 피드, `weeklyGoalRollover` 스케줄) + FCM. **3f** 신고 UI(모델·rules는 준비됨)·자동 suspend·계정삭제 시 gye 멤버십 정리(GDPR)·약관. 내가 배포·정책 불가라 spec 제공.

**Git push:** 미수행.

### 2026-06-03 (Tier 3b) — 계(契) 생성·입장 화면 + 홈 진입

**범위:** Tier 3a 토대 위 UI. Rules는 Jin이 클라우드 배포 완료(커밋 `1d74d0b`).

**Update:**
1. `lib/screens/gye_create_screen.dart` — 이름·닉네임 입력 → `GyeService.createGye` → 6자리 코드 hero + 공유(`Share.share`)/복사/닫기. busy 시 progress.
2. `lib/screens/gye_join_screen.dart` — 코드(대문자)+닉네임 → `GyeService.joinGye` → 성공 스낵바+pop(true). (계 마당은 3c — 여기선 가입 확인까지.)
3. `lib/l10n/gye_error_text.dart` — `GyeError`→현지화 메시지 공유 헬퍼.
4. routes `/gye/create`·`/gye/join` + 홈 둘러보기 빈 슬롯에 "Lern-Gye" 카드 → `showGyeChooser` 바텀시트(만들기/입장).
5. l10n `gye*` ~30키(de=en parity, `@gyeShareMessage`/`@gyeJoinedSnack` placeholders 양쪽).

**검증:** `flutter gen-l10n` OK · `flutter analyze lib/` **0** · `flutter test` **255 통과**. ⚠️ **계 생성/입장 실제 플로우는 Firestore 필요 → 미검증**(Jin: 2계정 실기기 + rules 배포됨). 화면 시각도 Jin. 순수 로직(코드·검증)은 3a 단위테스트 커버.

**남음:** 3c 계 마당+공동한옥(gye 8 표시) · 3d 스티커(30 표시) · 3e CF+FCM · 3f 모더레이션/GDPR.

**Git push:** 미수행 (3b 미커밋 — Jin 확인 후).

### 2026-06-03 (Tier 3a) — 계(契) 백엔드 토대 (모델·서비스·rules·욕설필터)

**범위:** 미연결 자산 기능화 plan의 **Tier 3a**(계+스티커 풀백엔드의 데이터/서비스/보안 토대). UI(3b~)·CF(3e)·모더레이션(3f)은 후속. Tier 1+2는 직전 커밋 `5efc994`에 포함.

**Update:**
1. `lib/models/gye.dart` — `GyeMeta`/`GyeMember`/`GyeFeedEvent`/`GyeSticker`/`GyeReport` + enums(role/status/feedType wire/reportReason), fromDoc/toCreateJson (§7.2 스키마).
2. `lib/services/gye_service.dart` — `SharedPackService` 패턴 mirror: nullable `_db`, 6자리 bearer 코드(혼동글자 제외)+충돌 재시도, `createGye`/`joinGye`/`fetchGye`/`leaveGye`/`myGyeIds`. 한도 계10명·유저3계, 이름/닉 길이+욕설 검증. 멤버십 인덱스=`users/{uid}.gyeIds`(collectionGroup 회피).
3. `lib/data/profanity_denylist.dart` — KO/DE/EN 스타터 deny-list + `containsProfanity`(정규화 시 **한글 보존**: 공백/구분기호만 제거).
4. `firestore.rules` `gye/{gyeId}` 활성화: 메타 read=인증(bearer 코드, 가입 전 미리보기)·create=본인 owner·update=계장 전체 or memberCount 단일필드·members/feed/stickers/reports=멤버/계장 게이트·feed/sticker append-only. helper `isGyeMember`/`isGyeOwner`. ⚠️ 인원상한·memberCount 정밀화는 3e CF에서 강화.

**검증:** `flutter analyze lib/` **0** · `flutter test` **255 통과**(신규 `gye_service_test` 7: 코드 생성/포맷·이름검증·욕설 KO/DE/EN). Firestore CRUD·rules는 **에뮬레이터/실기기 미검증**(Jin: `firebase emulators` rules 테스트 + 2계정). UI 없어 앱 동작 변화 0.

**Git push:** 미수행 (Tier 3a 미커밋 — Jin 확인 후).

### 2026-06-03 (Tier 1+2) — 책 상태 일러스트 연결 + 도장 PNG + 도장첩 화면

**범위:** 미연결 자산 기능화 plan(enchanted-percolating-turtle) 중 **Tier 1(책 상태)·Tier 2(도장)** 구현. (Tier 3 계+스티커는 별도 대규모 백엔드 트랙으로 후속.)

**Update:**
1. **책 상태 5장 전부 연결** — `AppLoading`·`AppError`에 옵션 `asset` 추가(없으면 기존 로고/아이콘, 회귀 0). book_result 로딩=book_analyzing·에러=book_error·성공(N단어)=book_success, book_capture idle=book_camera_guide, 책장 빈 상태=book_empty_shelf. 모두 `errorBuilder`→마스코트 fallback.
2. **도장 PNG 교체** — `dancheong_stamp.dart`: 절차적 `_StampPainter` 대신 `stamps/stamp_{motif}.png`(`_assetSlug`, errorBuilder→CustomPainter fallback). 결과화면 도장이 PNG로. `motifForPackId` 유지.
3. **도장 획득 영속** — `Storage.earnedStamps`/`addEarnedStamp`(`kl_stamps_earned`). `vocab_pack_screen._finish`에서 `justCleared` 시 `motifForPackId(pack.id).name` 추가.
4. **도장첩 화면 신규** — `dojangcheop_screen.dart` + route `/dojangcheop`(VocabPacksScreen AppBar 진입). 8 motif 그리드(획득=PNG·미획득=흐림+자물쇠)+진행도+빈상태. l10n `dojang*` 4키(parity, `@dojangProgress` placeholders 양쪽).

**검증:** `flutter gen-l10n` OK · `flutter analyze lib/` **0** · `flutter test` **248 통과**(신규 `earned_stamps_test`). 시각은 Jin(책 플로우·결과화면 도장·도장첩).

**남음:** Tier 3 계(契)+스티커 풀 백엔드(Firestore 그룹·gye_service·4화면·Cloud Functions·FCM·모더레이션·GDPR) — gye 8 + 스티커 30 자산 표시는 이 트랙. plan 참조.

**Git push:** 미수행.

### 2026-06-03 (투명 후속) — 통합 스크립트가 놓친 흰배경 14장 키잉

**범위:** Jin "새 자산 중 배경 투명 안 된 것 찾아 깨지지 않게 투명화" 요청. 신규/변경 PNG 111장 전수 alpha 검사(§0 — 추측 금지, PIL `convert("RGBA")` 실측) → **14장이 P-mode 불투명(흰배경)**. 직전 "에셋 대량 통합"의 `integrate_jongga_assets.py` 목록 **밖** 자산: `mascot/tiger_idle·neutral·smile`, `stickers/food_hotteok·kimbap·sikhye·tea·tteok`, `stickers/dancheong_cloud·flower·hanji·star`, `stickers/hangul_fighting·hh`. 나머지 97장은 이미 투명(무수정).

**Update:**
- **키잉 방식(이진 흰색 + 모서리 flood)**: per-pixel min-channel≥238로 흰색 이진 마스크(한지 종이질감 변동 흡수) → 4코너 `floodfill(thresh=0)`로 테두리 연결 배경만 제거. 안쪽 흰색(동공·밥알·찻잔·흰떡·글자 흰면)은 어두운 윤곽에 막혀 **자동 보존**. `MaxFilter(3)` 헤일로 1px + `GaussianBlur(0.7)` feather. RGBA→`quantize(FASTOCTREE,256,dither0)` P+alpha 재압축.
- **진단 정정(§0)**: 단순 floodfill `thresh` 단일값 실패 2모드 — (a) 낮으면 종이질감으로 배경조차 못 먹음(thresh15→0.1%) (b) 높으면 검은 눈테 안티앨리어싱 틈으로 동공 누수(thresh100). 이진 흰색 마스크가 둘 다 해결. **썸네일서 hangul_hh 동공을 투명으로 오인**했으나 픽셀 실측(동공 alpha=255, 크림합성 RGB=흰색 254≠크림 250)으로 보존 확정.

**검증:** 14/14 `alpha[0,255]`·%trans 47~72(형제 파일과 일치). 크림 합성 그리드 14장 + food_tteok/tea 확대 **육안 클린**(헤일로 0·안쪽 흰색 보존·양자화 색손실 미미). 용량 13.1MB(RGBA중간)→**2.5MB**(P+alpha, 흰배경 원본 5.4MB보다 작음). ⚠️ Flutter 빌드/시각은 미실행 — 이미지 콘텐츠 교체(동일 경로·파일명)라 Dart 컴파일·`data_integrity_test`(경로 존재만 검사) 무관. Jin `flutter run` 육안 권장.

**백업:** `.asset_keying_backup/`(gitignored) 원본 14장 — 롤백 가능.
**Git push:** 미수행.

### 2026-06-03 (에셋 대량 통합) — "누락이미지" 52장 적재적소 배치 + 키잉 + 일부 wiring

**범위:** Jin이 `~/Downloads/누락이미지-압축`에 jongga-assets.md 명세 이미지 52장 제작 → "각각 적재적소 + 같은 이름 교체" 요청.

**Update:**
1. **전부 P-mode 불투명** 확인(§0 alpha 검사) → `tool/integrate_jongga_assets.py`: 모서리 floodfill 키잉(테두리 근백색만 투명, 안쪽 보존) + P+transparency 재압축 + 명세대로 폴더 배치. 크림 합성 8장 육안 클린.
2. **배치(52 소스 → 54 placements):**
   - **mascot/ 교체+추가**: tiger_blink·celebrate·sad·sleepy·surprised + magpie celebrate·perched·perched_alt·wingdown·wingup·worry (Jongga Guardian 스타일).
   - **tiger_anim/ +9**: stretch 3·roar 6 (ambient special).
   - **stickers/ +19**: tiger cheer·clap·love·sad·surprised, magpie dance·wave·sleep·sing·encourage, hangul good·best·kk, dancheong_lantern, stamp_sticker cheer·love·happy·well_done·fighting.
   - **stamps/ +2**: mountain·plum. ⚠️ **소스 두 파일 내용 swap돼 content 기준 교정**(plum 파일=산 그림이었음).
   - **gye/(신규) 8 · book/(신규) 5** + pubspec 등록.
3. **wiring(consumer 있는 것만 "사용"):**
   - mascot 교체분 = `Mascot` 위젯 이미 참조 → 즉시 라이브.
   - **`tiger_surprised`** → `MascotEmotion.surprised` 연결(기존 tiger_happy 대역 제거 → `_tigerHappy` const 삭제). 초성/워들 결과 등 사용.
   - **stretch/roar** → `TigerStage` ambient 신규 행동(`_doStretch`/`_doRoar`, turn_right 진입·복귀, 확률 idle45/pace23/sit12/stretch11/roar9). `_allFrames` 추가(precache). `_Phase.special`.
   - **`book_empty_shelf`** → 책장 빈 상태(`SoriEmptyState.asset`).
4. **미연결(배치만, consumer 없음)**: stickers 19(전송 기능 없음) · gye 8(계 기능 없음) · book 4(camera_guide/analyzing/success/error — book_capture/result wiring 후속) · stamps(현재 CustomPainter라 PNG 미로드). → 배치 완료, "표시"는 각 기능 제작 시.

**검증:** `flutter analyze lib/` **0** · `flutter test` **247 통과**(data_integrity가 tiger_surprised·book_empty_shelf 실존 확인). 키잉은 대표 8장 육안. **⚠️ 앱 내 실제 표시 미검증**(Jin 실기기). ⚠️ tiger_celebrate는 paw-up(만세) 포즈 — 명세 §5.0A는 celebrate 만세 지양 권고였으나 Jin 제작본 그대로 배치.

**Git push:** 미수행.

### 2026-06-03 (flaky 픽스) — `generateId` 충돌 방지 (Rive 세션 별도 태스크 해소)

**범위:** Rive 세션이 남긴 별도 태스크 — `book_page_test`의 `generateId` flaky(전체 `flutter test`에서 간헐 실패). 진단 정정: 원인은 "타임스탬프 단독"이 아니라 **이미 있던 4자 random tail(36⁴≈1.68M)의 birthday-collision** — 같은 ms에 50개 생성 시 ~0.07%/run 충돌(드물어 격리 실행은 통과, 전체 런에서 간헐). 프로덕션에서도 같은 ms 2팩 생성 시 id 중복 잠복 버그.

**Update:**
- `bookshelf_service.dart`·`custom_pack_service.dart` 양쪽 `generateId`에 **프로세스 monotonic 카운터 `_seq`** 추가 → `p_${ts}_${seq}_$tail` / `cp_${ts}_${seq}_$tail`. 카운터가 isolate 내 유일성을 **보장**(확률→불가능), ts는 정렬·프로세스간 유일성, random tail은 멀티-isolate 방어. `p_`/`cp_` prefix·정렬성 유지.
- ID 구조 파싱처 점검: `split('_')` 사용처(`vocab_pack_service`·`dancheong_stamp`)는 vocab pack id(`food_a1`) 전용·끝자리 숫자만 추출 → `p_`/`cp_` id 무관(새 tail은 비숫자라 통과해도 무해).

**검증:** `flutter analyze` (2파일) **0 issues** · 타깃 2파일 **10회 연속 통과** · 전체 `flutter test` **247 통과**. 카운터 결정성으로 50회 루프 테스트는 구조적으로 충돌 불가.

**Git push:** 미수행 (Jin 확인 후).

### 2026-06-03 (Rive 전환) — 프레임 끊김 → Rive 리깅 경로 turnkey

**범위:** Jin 피드백 — 투명은 됐으나 **프레임 전환이 끊겨 부자연스러움**. 프레임 방식 한계(인트로 7·걷기 6장). 1차: 프레임판 스무딩(상시 호흡 스케일 + 걷기 하드컷→짧은 크로스페이드 46ms + 걷기 상하 bob + easeInOut). Jin이 "베타로 못 냄 → 진짜 부드럽게(Rive)" 결정. **결론: 프레임/AI보간으로는 한계·떨림 → Rive 리깅이 유일하게 확실.**

**Update:**
1. **Rive 통합 turnkey** — `rive ^0.14.7` 추가. 신규 `lib/widgets/sori/tiger_stage_rive.dart`(0.14 신 API: `RiveWidgetBuilder`+`FileLoader.fromAsset`+`Factory.flutter`+`RiveWidget(fit:contain)`). `main.dart`에 `RiveNative.init()` best-effort(성공 시 `TigerStageRive.riveReady=true`). 홈 `_TigerHero`가 `TigerStageRive` 사용. **폴백 체인:** 미초기화/`.riv` 없음/로드 실패/reduce-motion → 프레임 `TigerStage`. → `.riv` 넣으면 코드 0변경으로 매끄러운 버전 가동.
2. **`assets/rive/`** 폴더+pubspec 등록(+`.gitkeep`). `data_integrity_test`에 pending 자산 allowlist(`tiger.riv`).
3. **리깅 명세** `docs/TIGER_RIVE_RIG_SPEC.md` — 아트보드/본·메시/타임라인(Sit·Notice·Smile·Rise·IdleStand·WalkL/R)/default 자동재생 상태머신/익스포트/DIY·외주 경로. 기존 PNG 재사용.

**⚠️ 남은 단 하나 = `.riv` 리그 제작(Rive 에디터 GUI 작업).** 이건 코드로 생성 불가 — Jin DIY 또는 외주. 그때까지 홈은 프레임 폴백으로 정상 동작.

**검증:** `flutter analyze lib/` **0**(rive 0.14 신 API 컴파일 확인 — 설치 패키지 소스 직접 대조 후 작성) · `flutter test` **247 통과**(home은 `riveReady=false`라 프레임 폴백 경로). **⚠️ Rive 실제 렌더는 `.riv` 부재로 미검증**(불가피). 프레임 스무딩 시각도 미검증 — Jin 육안. **flaky 발견:** `book_page_test` `generateId`(타임스탬프 ID 충돌, 본 작업 무관 — 별도 태스크).

**Git push:** 미수행.

### 2026-06-03 (살아있는 호랑이) — TigerStage 애니메이션 + 홈 밴드 (plan: enchanted-percolating-turtle)

**범위:** Jin이 호랑이 프레임 PNG 세트(직접 제작·압축)를 `~/Downloads/호랑이-인트로 호랑이완성/`에 넣고 "이미지 더 만들기 전에 애니메이션 구조 스펙 먼저 확정" 요청. Q&A로 **풀스코프(스펙+에셋+홈 위젯)** + **홈 상단 와이드 밴드** 확정.

**Update:**
1. **에셋 정리** — 최적화 39장 중 35장을 `assets/illustrations/tiger_anim/`로 import+canonical rename(.png.png ×3·한글명 ×2·숫자접두 제거). **중복/예비 4장은 픽셀 확인 후 드롭**(`turn_right_threeq`/`step_out_threeq_right`/`turn_right_front_prep` 비접두 중복 + `b-1…side_left_a`). pubspec 폴더 등록. (md5로 중복 의심쌍 비교 → 다 다름 → 8장 육안 확인해 우측 lead-in이 `turn_3q→step_out→walk_start` 별개 프레임임을 확정.)
2. **`tiger_stage.dart` 신규** — `TigerStage` 위젯. 토큰 가드 재귀 Future 시퀀서, 150ms 크로스디졸브(걷기 하드컷), pacing there-and-back(±span→0, span=폭×0.17 clamp 28–80), ambient 스케줄러(55% idle/30% pace/15% sit), reduce-motion 정지 프레임, 프레임별 errorBuilder→`Mascot.tiger` 2층 degradation, `WidgetsBindingObserver` 백그라운드 일시정지. **intro는 launch당 1회(in-memory static — `Storage.introSeen` 게이트용이라 사용 금지).**
3. **홈 통합** — `_TigerHero` 리팩토링: greeting/subline 텍스트(상단) + `TigerStage` 밴드(콘텐츠 폭, height 150/168) + 말풍선 오버레이. 인라인 `Mascot.tiger` 제거. (⚠️ edge-to-edge 풀블리드는 미적용 — clamp 308px 튜닝 회귀 위험. 현재 콘텐츠 폭 와이드 밴드.)
4. **스펙 문서** `docs/TIGER_ANIMATION_SPEC.md` — 핸드오프용(상태머신·프레임맵·rename 이력·타이밍·구현·영문 블록·후속).

5. **⚠️ 투명 배경 복원(Jin 실기기 피드백)** — 첫 import 후 홈에 **호랑이 뒤 흰 사각형** 노출. 원인: **소스 프레임 전부 알파 없음**(비압축=RGB 흰배경, 최적화=P). 내가 첫 Read 때 체커보드를 투명으로 오인(§0 — alpha 미검증). 수정: 비압축 RGB 원본에서 모서리 `floodfill(thresh46)` 키잉(테두리 연결 근백색만 투명, 안쪽 흰색 보존)→`P+transparency`(255색, dither0) 재압축. 35/35 투명, 10MB. 크림 합성 육안 6장 클린(흰박스·구멍·헤일로 0). `rise_prep`만 비압축 부재로 최적화본 키잉. 상세: SPEC §3-2.

**검증:** `flutter analyze lib/` **0 issues** · `flutter test` **247 통과**(신규 `test/tiger_stage_test.dart` 2: reduce-motion 정지·무타이머, 라이브 빌드+dispose). 에셋 35/35 **투명 확인**. responsive_test가 home을 308/360/800/1280px에서 빌드(오버플로 0) → 히어로 리팩토링 회귀 없음. **⚠️ 시각/애니메이션 재생은 미검증** — `initialRoute:'/intro'` + 신규세션 온보딩 + CanvasKit 헤드리스 클릭 불안정 → 자동 시각검증 비현실. **Jin이 `flutter run -d chrome`로 육안 확인 필요**(진입 인사 1회→idle→좌우 pacing, 308/360/430/768/1200px 밴드·말풍선·오버플로, OS reduce-motion 정지).

**Git push:** 미수행 (Jin 확인 후).

### 2026-06-03 (반응형) — 듀오링고식 콘텐츠 폭 클램프 (배경:콘텐츠 비율 최적화)

**범위:** Jin 피드백 — 앱 모드 배경:콘텐츠 비율 비효율(넓은 화면 풀폭 스트레치 + 좁은 폰 308px 히어로 압축). plan `~/.claude/plans/flutter-lazy-conway.md`. 결정: 홈+리스트 화면 일괄, content maxWidth **480**(그리드 600).

**Update:**
1. **Foundation** — `lib/widgets/sori/tokens.dart`에 `SoriBreakpoints`(content=480, grid=600) + **신규 `lib/widgets/sori/responsive.dart`**: `soriClampPadding(width, {maxWidth, base})`(폰 무변화·넓은 화면만 잉여폭 좌우 분배) + `SoriContentClamp`(LayoutBuilder 래퍼). **배경 풀블리드 유지, 콘텐츠 padding만 클램프**.
2. **Home** (`home_screen.dart`) — (a) `SingleChildScrollView`를 `SoriContentClamp`로 래핑(RefreshIndicator는 풀폭 유지) (b) `_TigerHero` `MediaQuery`→`LayoutBuilder` 3구간 반응형(<330: tiger104·height138·greeting21 / <400:124 / ≥400:140), `_SpeechBubble`에 `maxWidth` 파라미터 (c) `_StatChipRow` 큰 글씨 안전 — `_MiniStat` 텍스트 `Flexible`+ellipsis + Row만 `MediaQuery.withClampedTextScaling(1.3)`.
3. **리스트 5화면** — `scenarios_list`·`settings`·`quests`·`stats`는 `ListView.padding`을 `soriClampPadding(MediaQuery.sizeOf(context).width, base: 기존)`으로 교체(닫는 괄호 매칭 리스크 0). `vocab_packs`(CustomScrollView)는 바깥 Padding에 `maxWidth: SoriBreakpoints.grid`로 적용.
4. **버그 픽스(좁은 폰 잠복 2건, 클램프 무관)** — (a) `_TopBar` 브랜드명 `Text+Spacer`가 320px서 4.7px 오버플로 → `Expanded(…ellipsis)`. (b) `_TodayScenarioCard` 메타행(레벨칩+`'5–7 min · +XP'`)이 308px서 ~1px 오버플로(**Jin 실기기 Chrome 포착**, async 로드 상태) → 듀레이션 `Text`를 `Flexible(…ellipsis)`. 둘 다 넓은 화면 룩 동일·좁을 때만 말줄임. (나머지 데이터 의존 카드 `_Review/_Path/_HardWords/_DailyChar`는 텍스트가 Expanded 컬럼 안=세로 줄바꿈이라 안전, `_CourseTitle`은 이미 Flexible.)

**검증:** `flutter analyze` **0 issues** · `flutter test` **245 통과**(신규 `test/responsive_test.dart` 26개: `soriClampPadding` 수학 5 + `SoriContentClamp` 위젯 1 + 5화면 ×**308**/360/800/1280px 오버플로0 20). ⚠️ **시각 픽셀 검증 미완** — 앱이 `initialRoute:'/intro'` 하드코딩이라 URL로 화면 직행 불가 + Flutter CanvasKit 헤드리스 클릭 불안정 → 자동 시각 검증 비현실적. **Jin이 `flutter run -d chrome`로 308/360/430/768/1200px 육안 확인 필요**(특히 넓은 화면 480 중앙 컬럼, 308px 히어로·_TopBar).

**Git push:** 미수행 (Jin 확인 후).

### 2026-06-03 — 시나리오 버그 + 단어장 전역 통합 + 학습화면 5종 + 크래시 픽스 (commits `bf7ca2f`, `daa883a`)

**범위:** Jin 실사용 피드백 다수 처리. 동시 세션 종료 후 전수 재검증 → 커밋·푸시.

**Update:**
1. **초성/마스코트 크래시** (`bf7ca2f`) — `stroke_canvas.dart`가 `SingleTickerProviderStateMixin`인데 `didUpdateWidget`이 AnimationController 재생성 → **한글 화면 글자 전환 시 레드스크린**(assert, debug/web만). 컨트롤러 재사용(duration 갱신+reset/forward)으로 수정. `mascot.dart`도 같은 잠복 버그(`animate` 토글 시 재생성) → `TickerProviderStateMixin`. 회귀 테스트 `test/stroke_canvas_test.dart`·`test/mascot_ticker_test.dart`.
2. **시나리오 안 뜸 (regression)** — 콘텐츠 공장이 추가한 신규 12개 시나리오의 `culturalNote`가 `{title,body}` 대신 `{ko,de,en}` → `CulturalNote.fromJson` throw → **전체 시나리오 리스트가 빔**. (a) 데이터: 12개 `culturalNote`를 `{title,body}`로 교정 (b) 코드: `CulturalNote/GrammarBlock.fromJsonOrNull` null-safe + `ScenarioLoader`가 시나리오별 try/catch(1개 깨져도 전체 안 죽음) + `Scenario.title/intro`도 null-safe. `test/scenario_loader_test.dart`. 33개 정상 로드.
3. **단어장 전역 통합** — (a) `CustomPackService.quickAdd`(고정 id `cp_quick_v1` "⭐ 빠른 저장" find-or-create + 한국어 dedup, enum `WordbookAddResult`) (b) 신규 `lib/widgets/sori/wordbook_add.dart`(`addToWordbook()` + `AddToWordbookButton`) → **review·chosung·wordle·vocab_pack·smalltalk·scenario_player** 6개 화면에 "＋단어장" (c) 신규 `lib/screens/wordbook_search_screen.dart` route **`/wordbook/search`**: 모든 저장 단어 통합 + 텍스트 검색 + 품사(카테고리) 필터, 책장 AppBar 🔍 진입. l10n `wb*` +~12키. `test/wordbook_quick_add_test.dart`. (단어장으로 게임·카드는 기존 `custom_pack` play/quiz/matching/typing로 이미 가능.)
4. **학습화면 5종 개선:**
   - **초성 재설계** `chosung_quiz_screen.dart`: 뜻 **항상 표시**(hint 게이트 제거) + 플랫 "ㅇㅏㅃㅏ" → **음절 스캐폴드**(초성/중성/종성 슬롯, 점선 박스+`모음`/`받침` 라벨; `_jongsungTable` 추가, `_SyllableScaffold`/`_Slot`/`_DashedBoxPainter`). 쉬움=중성 채움·받침 점선 / 어려움=중성·받침 점선(받침 없는 단어도 정답 비노출). `_hint` 필드 완전 제거.
   - **Wordle 힌트** `wordle_screen.dart`: 품사 칩 + 뜻 + 독일어 예문(`_targetVocab`). ⚠️ 동의어/반의어는 **데이터 부재로 미구현**(§0 — 추후 콘텐츠 공장).
   - **Grammar 분할** `grammar_screen.dart`: 상시 레벨 칩 + 첫 진입 시 사용자 레벨 자동 스코프(CSV 표기 일치 시).
   - **퀘스트 상세** `quests_screen.dart`: 전체 요약 카드(완료/전체+진행바+진행중) + 퀘스트별 보상 장식 썸네일(`_RewardThumb`) + %.
   - **TTS** `tts_service.dart`: 웹 한국어 voice 자동 선택 + `awaitSpeakCompletion`. ⚠️ **한계: OS에 ko 음성 없으면 코드로 불가(웹). 실기기(Android) 확인 필요.**

**검증:** `flutter analyze` **0** · `flutter test` **218 통과** · l10n de=en=600 parity · `scenarios.json` parse-throw 0 · `.env.example`는 placeholder만(실제 키 미추적·gitignored). **시각/오디오는 미검증**(샌드박스 한계). Jin 실기기 확인 항목: 초성 스캐폴드·점선 박스, Grammar 레벨 칩, 퀘스트 썸네일, ＋단어장 흐름, **TTS 실발화**.

**Git push:** `bf7ca2f`(크래시) → `daa883a`(나머지 25파일, +1567/−170) → `origin/main` 완료.

### 2026-06-02 (Cowork) — 이미지 교체 + 다크모드 폐지 + API키 반영 + 출시 문서

**범위:** 내부 테스터 모집 직전. Jin 요청으로 (1) 압축 이미지 교체, (2) 다크모드 폐지, (3) DeepL·우리말샘 키 반영, (4) 출시 문서 3종.

**Update(이 Cowork 세션):**
1. **이미지 48장 교체/추가** — `~/Downloads/종가이미지 압축`의 `_optimized` PNG를 앱 에셋 경로로 매핑·복사.
   - hanok_stages 10(light) — **`stage_beams_light.png` 신규**(.en 변형, 841×1870 규격 일치 / .de는 off-size라 스킵).
   - decorations 10 · stamps 6 · stickers 11(`assets/stickers/`, `hangul_hh` 신규) · hanok gate 5 · mascot 6(`tiger_idle2` 신규=코드 미연결).
2. **다크모드 폐지** — `main.dart` `themeMode: ThemeMode.light` 고정 + `darkTheme`를 light로 미러 + `themeModeNotifier`를 merge에서 제거. `settings_screen.dart` 테마 선택 UI 삭제. 양쪽 `theme_service.dart` import 제거(미사용 경고 0 확인). → **다크용 PNG 제작 불필요**.
3. **콘텐츠 버그 수정** — `scenarios.json` `cafe_starbucks_basic` 독일어 문법 설명 오류(햄버거=모음인데 Konsonant-Ende로 오기 + 무의미 반복) 수정 · `One iced americano, tall please.`→`One iced Americano, tall, please.` · `listing-en.md` "Anlaut Quiz"→"Initial-Consonant Quiz". (JSON 파싱 OK)
4. **버전** `1.0.1+2`→`2.0.0+3` (`pubspec.yaml`).
5. **API 키 반영(보안)** — `functions/analyze_korean_text/.env`에 `DEEPL_API_KEY`(:fx) + `URIMALSAEM_API_KEY` 저장(.gitignore `.env*` 처리 확인, git status 미노출). `.env.example` 커밋용 템플릿. `main.py`에 `.env` 로더 + **우리말샘(opendict) 뜻풀이 enrichment**(urllib stdlib, 키 없으면/실패 시 빈 문자열, 최대 20단어) 추가 → 응답에 `definitionKo`. 클라 연결: `ExtractedWord.definitionKo`(옵션 필드) + `book_analysis_service` 파싱 + `book_result_screen` 단어카드 "📖 뜻풀이" 표시. (`py_compile` OK. 우리말샘 실호출은 샌드박스 403으로 미검증 → 배포 후 확인)
6. **책 한 컷 프롬프트 완성** — `jongga-assets.md` §7: 기존엔 7.1만 완전 프롬프트, 7.2~7.5는 구도 설명만 → **7.2~7.5 완전 영문 프롬프트 작성**(템플릿+상황 layer, center-blank 지시 포함). 이제 5장 전부 복붙 가능.
7. **출시 문서 3종** — `docs/LAUNCH_READINESS_2026-06-02.md`(준비도 진단·계획), `docs/JIN_VERIFY_CHECKLIST.md`(Jin 직접 검증 항목), `docs/IMAGES_TO_CREATE.md`(제작할 이미지 light-only).
8. **웹사이트 v2.0 갱신** — `docs/index.html`: 히어로에 사진 기능 문구 + "베타 신청" CTA 메일 연결, 📷 책 한 컷 플래그십 카드 + 한옥 건축 + 퀘스트 카드(3개국어), 단어장 카드 "61팩" 메시지, 스크린샷 라벨·메타 갱신. (태그 균형 검증) — **라이브 반영은 docs/ 커밋·푸시 필요**.
9. **"나만의 단어장"(수동 커스텀 단어장) 신규** — 기존 CustomPack 인프라 확장:
   - 모델: `CustomPack.manual()`+`copyWith()`+`isManual`, `ExtractedWord.manual()`.
   - 서비스: `createEmpty/addWord/updateWord/deleteWord/rename` + `BookAnalysisService.autoFill()`(단어 1개 번역·뜻풀이 자동채우기, Cloud Function 필요).
   - 화면 신규: `custom_pack_edit_screen.dart`(단어 직접 추가·편집·삭제, 자동채우기, TTS), `custom_pack_quiz_screen.dart`(4지선다 퀴즈, ≥4단어).
   - 진입: 책장 화면 ＋버튼(생성)·편집 아이콘, 빈 상태 보조 CTA. 라우트 `/custom_pack/edit`·`/custom_pack/quiz`.
   - l10n: DE/EN +30키(`wb*`/`quiz*`/`createWordbook*`), 591키 parity OK. **`flutter gen-l10n` 재실행 필수**(생성 파일 stale).
10. **나만의 단어장 3종 확장 (홈카드·CSV·사진)** — 무오류·고품질, 새 네이티브 의존성 0:
   - **홈 카드**: 홈 모듈 그리드의 빈 셀(퀘스트 옆)에 "나만의 단어장" 카드 → `/bookshelf` (레이아웃 변경 없음). `homeWordbookCard*` l10n.
   - **CSV 가져오기**: 편집 화면 액션 → 붙여넣기 다이얼로그 → 기존 `csv` 패키지로 파싱(한국어,뜻,예문) → `CustomPackService.addWords()` 일괄. 파일선택기(file_picker) 미사용=권한0. `csvImport*` l10n.
   - **사진 첨부**: `ExtractedWord.imagePath` 필드 추가 + 신규 `WordImageService`(image_picker 촬영/갤러리 → **path_provider로 앱 문서 폴더 영구 복사**) + 편집 시트 사진 버튼/썸네일 + 단어 타일 썸네일 + 플립카드 앞면 이미지. 모두 `Image.file(errorBuilder)`로 누락 안전. `wbPhoto*` l10n.
   - **pubspec**: `path_provider: ^2.1.5` 직접 의존성 추가(이미 lockfile transitive라 resolve 안전). 카메라/사진 권한은 책 한 컷이 이미 선언(Android CAMERA/READ_MEDIA_IMAGES, iOS NSCamera/PhotoLibrary).
   - l10n 양쪽 602키 parity OK. CSV 일괄·파일import는 백로그.

**⚠️ 빌드:** 신규 l10n 키 + path_provider 때문에 **반드시 `flutter pub get` → `flutter gen-l10n` → `flutter analyze` → `flutter test`** 1회. 정적 검증(브레이스 균형·키 parity·JSON·기존 위젯 API 대조)만 했고 컴파일은 Jin 로컬에서.

11. **"나만의 단어장 = 암기 엔진" (A1·A2·A3)** — 단순 저장소 → SRS 통합 학습 엔진:
   - **A1 메인 SRS 편입**: 신규 `ReviewDeckService.allReviewable()`(CSV+커스텀팩+책장 단어 통합, 한국어 dedup) → `review_session_screen`("오늘의 복습")·홈 dueCount가 이걸 사용. 커스텀팩 카드/퀴즈/받아쓰기에서 `Storage.srsReview()` 호출 → 직접 모은 단어가 매일 복습에 흐름.
   - **A2 어려운 단어(leech)**: `Storage.hardIds()`(reviewCount≥3 & (ease≤1.8 ‖ interval≤1)) + 신규 `hard_words_screen.dart`(목록+집중복습) + 홈 카드(`_HardWordscard`, hardCount>0일 때만) + 라우트 `/hard_words`.
   - **A3 학습 모드 확장**: 신규 `custom_pack_matching_screen.dart`(짝맞추기) + `custom_pack_typing_screen.dart`(받아쓰기, SRS연동) + 퀴즈에 사진 노출(A4). 편집화면 4모드 버튼(카드·짝맞추기·받아쓰기·퀴즈). 라우트 `/custom_pack/matching`·`/custom_pack/typing`.
   - l10n +21키(hardWords*·wbMatching*·wbTyping*), DE/EN parity(내 키 전부 일치; `@homeReviewDue`는 템플릿(DE) 전용 메타로 정상). 11개 파일 브레이스 균형 OK.
   - **빌드: `flutter gen-l10n` 필수**(신규 키). 웹사이트엔 "나만의 단어장" 카드 추가됨(라이브는 푸시 필요).

**검증:** Jin 로컬 빌드 통과 확인("전부 문제없이 빌드됐어"). 이후 추가된 `definitionKo` 관련 Dart 3파일은 `flutter analyze` 1회 재확인 권장. 함수 배포·AAB·실기기·Play Console·우리말샘 실호출 = Jin.

**⚠️ API 키:** DeepL·우리말샘 키가 대화에 노출됨 → 셋업 후 **DeepL 키 재발급** 권장.

**Git push:** 미수행 (Jin 확인 후).

### 2026-06-02 — 출시 준비도 전수 진단 + 6종 작업 (plan: deepl-api…eager-puppy)

**범위:** 내부 테스터 모집 직전 전수 진단 → 진단문서 작성 + CLAUDE.md 갱신 + 공유 기능·Cloud Function 보정·홈 skill-path.

**핵심 진단(정정):**
- Cloud Function `functions/analyze_korean_text/main.py` = **kiwipiepy(순수 Python, Java 없음) + DeepL + 우리말샘(NIKL)** 이미 구현 → 배포만 남음(Jin, gcloud gen2 권장 europe-west3). 1차 audit의 "konlpy/Java"는 환각.
- 버전 `2.0.0+3`, privacy.html account-deletion 링크, 홈 v4 재설계 — 모두 이미 반영(동시 세션).
- 로컬라이제이션: 독일어 완벽 / 영어 UI 완벽이나 **학습 콘텐츠는 독일어 전용**(`korean_vocab.csv` `german` · `grammar.csv` `_de` 컬럼). 독일어권 타깃엔 OK.
- 에셋: 코드 cross-ref → missing 전부 fallback, 테스터에 깨진 이미지 0. hanok_stages **dark 0/12**가 다크모드 시각손실 최대.
- 공유 기능: 코드 0건 → 신규 개발.

**Update(이 세션):**
- A. `docs/release-readiness-2026-06-02.md` 신규 (영역별 상태·에셋 실측·P0~P3·Play Console 폼값).
- B. CLAUDE.md 파일맵·라우트·현재작업·세션로그 v2.0 갱신.
- 2. 공유(친구코드+OS공유): `share_plus` · `shared_pack_service.dart` · firestore.rules `shared_packs/{code}` · UI(공유시트·코드 가져오기) · l10n.
- 3. Cloud Function 클라 보정: `targetLang` locale화 · 기본 endpoint 주입 · EN translation. `.env`에 두 키(gitignored). 배포 런북.
- 4. 홈 skill-path 레일.

**검증:** `flutter analyze` 0 유지 + `gen-l10n` + `test`. 함수 배포·AAB·실기기·Play Console = Jin.

**⚠️ API 키:** DeepL·우리말샘 키가 대화에 노출됨 → 셋업 후 **DeepL 키 재발급** 권장.

**Git push:** 미수행 (Jin 확인 후).

### 2026-05-21 — 코드베이스 audit + 마스코트/퀘스트/홈 긴급 수정

**Audit (전수 조사):**
- 🔴 마스코트가 앱 전역에서 깨져 있었음 — `mascot.dart`가 존재하지 않는 `tiger_magpie.png` 참조. 체크리스트엔 완료(`[x]`)로 잘못 표기돼 있었음. 홈 아바타·시나리오 대화·결과 화면·퀘스트 정답 팝업 전부 깨진 이미지로 표시
- 🟡 퀘스트 엔진 5종이 레거시 `AppColors`(다크 하드코딩) 사용 → 라이트모드에서 깨짐
- 🟡 `/scenarios` 리스트 화면은 완성됐으나 홈에서 진입 동선 없음
- 🟡 `madang(light).png` 미사용 (라이트모드 홈 배경 없음)
- 🟡 analyzer 경고 23건
- 콘텐츠: 시나리오 13개(B2 0개), `docs/content` 4트랙 전부 미실행

**Review:** Sori 디자인 시스템·8개 일러스트는 성숙·고품질. 핵심 결함은 마스코트 깨짐 + 라이트모드 미완성 + 콘텐츠 진입 동선 부재.

**Update (실행·검증 완료):**
1. mascot v5 — `welcome-hero.png` 기반 재작성, 호흡 애니메이션, errorBuilder fallback
2. 퀘스트 5종 → `SoriSurfaces` 라이트/다크 대응
3. 홈 Szenarien 카드 신설 (`/scenarios` 진입로)
4. 홈 라이트모드 `madang(light).png` 배경
5. analyzer 23→8
6. 검증: `flutter analyze` 0 errors · APK 디버그 빌드 성공 · 웹에서 시나리오 전체 흐름(온보딩→홈→리스트→퀘스트 3종→결과) 시각 확인

**Git push:** `f748073` (+ 동시 세션 `0afbd66`) → `origin/main` 푸시 완료

### 2026-05-21 (2차) — 발견 이슈 수정 + 역동적 애니메이션

**발견 이슈 수정 (Review→Fix):**
- 웹 settings 진입/리로드 시 `FirebaseException` JS-interop 레드스크린 — `auth_service`의 `_auth`를 nullable getter로, 모든 읽기 getter를 예외 안전하게. 웹 전용 이슈(안드로이드 무관)
- 시나리오 완료 후 홈 복귀 시 XP·streak 미갱신 — Today 카드 네비게이션에 `.then()` refresh 추가

**역동적 애니메이션 (Update):**
- `widgets/sori/motion.dart` 신규 — `SoriEntrance`(진입 fade+slide+scale), `SoriKenBurns`(배경 느린 줌)
- `widgets/sori/ambient_particles.dart` 신규 — 라이트: 매화 꽃잎 / 다크: 불씨 입자 (CustomPainter, seamless 무한 루프)
- `widgets/sori/flying_magpie.dart` 신규 — 갓 쓴 까치가 홈 상단을 주기적으로 비행 (날갯짓·뱅킹)
- 홈: Ken Burns 배경 + 매화 입자 + 비행 까치 + 카드 stagger 진입
- 온보딩: 매화 입자 + 대문 "열리듯" 등장 + 레벨 카드 stagger

**검증:** `flutter analyze` 0 issues · APK 디버그 빌드 성공. ⚠️ **시각(픽셀) 검증 미완** — Chrome 확장 연결 끊김 + 화면 접근 권한 시간 초과로 애니메이션 실물 확인 못 함. 코드는 컴파일·빌드만 검증됨 → 첫 `flutter run` 시 까치/입자 모양 점검 권장.

**동시 세션 작업 (같은 커밋에 포함):** 다른 세션이 솟을대문 인트로(`screens/intro_gate_screen.dart`) + 라우트 전환(`lib/motion/transitions.dart`) + `flutter_animate` 패키지 + 스플래시 색(teal→cream)을 작업. 본 커밋에 함께 포함됨. ⚠️ entrance 애니메이션이 `SoriEntrance`(이 세션)와 `flutter_animate`(동시 세션) 두 방식 공존 — 추후 일원화 검토 필요.

**Git push:** 본 커밋 → `origin/main`

### 2026-05-25 — v1.0.0 출시 plan + Track A·C 완료 (plan: snappy-conjuring-lemur)

**범위:** 2주 출시 준비 종합 점검. 자산 점검 + 컨셉 일관성 진단 + plan 작성 + Track A(자산 정리) + Track C(코드 구현) 동일 세션에서 완료.

**진단 (3 Explore agent 병렬):**
- 자산: hanok/에 마스코트 7장이 mascot/와 md5 동일 중복 (~16MB), + 미참조 5장 (gate.png, welcome-hero.png 등). intro_gate_screen.dart는 CustomPainter (HanokGateArt) 사용, PNG 미사용 검증.
- 콘텐츠: 시나리오 13개 중 B2 = 0개. /listening은 PlaceholderScreen, 끝말잇기 화면 없음 (풀 JSON만 있음).
- 디자인: Intro/Home/Stats 강함 ⭐⭐⭐, Vocab/Grammar/Wordle 약함 ⭐ (순수 텍스트).

**Plan (`snappy-conjuring-lemur.md`):** 5 트랙 (A:정리·B:PNG·C:코드·D:콘텐츠·E:검증) + 부록 A에 18장 PNG 상세 스펙 (Faceted Minhwa 스타일 가이드 기반 영문 프롬프트 그대로 복붙용).

**Update (Track A·C 완료):**
1. 자산: hanok/ 14개 삭제·이동 (~17MB 절감), scenes/empty/error 폴더 + .gitkeep + pubspec 등록
2. Mascot v6: emotion enum에 thinking 추가 + magpie worry/sleepy 매핑 + 신규 PNG 미존재 시 자동 fallback
3. ListeningScreen 신규 — TTS dialog 재생, 자막 4모드, 속도 3단계, sidekick 마스코트, 완료 시 XP+8 per line
4. KkeunmariScreen + KkeunmariEngine 신규 — 호랑이↔사용자 턴제, 30s 타이머, dead_end 처리, chain length × 10 XP
5. 홈 카드: 게임 4종 (Chosung/Wordle/Kkeunmari/Listening) 2×2 grid
6. Wordle 단청 frame Container + 4코너 단청 dot + 결과 카드 mascot (까치 celebrate / 호랑이 worry)
7. Chosung 라운드 종료 → 정확도별 mascot (≥80% celebrate + SoriCelebration.burst / 50-79% surprised / <50% worry)
8. Vocab/Grammar banner path → 신규 `study_classroom.png`/`study_scholar.png` (errorBuilder로 study.png fallback)
9. DE/EN ARB +37 키 (listening 18 + kkeunmari 19) — `flutter gen-l10n` 성공

**검증:** `flutter analyze` = **0 issues** · `flutter build apk --debug` = **success** (exit 0). 시각 검증은 Jin 실기기에서.

**미수행 (Jin 영역):** Track B PNG 18장 (plan 부록 A), Track D B2 시나리오 3-5개 (plan §7.1.2), Track E 실기기 검증·Data Safety·스크린샷.

**Git push:** 미수행 (Jin이 확인 후 명시적 요청 시 push).

### 2026-05-27 — Track D 콘텐츠 완료 (시나리오 13→21)

**범위:** B2 시나리오 3개 DE/EN 원어민 교열 + scenarios.json append + 일상 시나리오 5개 신규 작성.

**Update:**
1. **B2 시나리오 DE/EN 전면 교열** — 이전 세션 초안의 번역체·문법 오류 전수 수정:
   - `business_meeting_intro` title de: "Im Geschäftsmeeting vorstellen" → "Vorstellung beim Geschäftsmeeting" (sich 누락 수정)
   - `doctor_consultation` grammarBlock de: "Ich hoffe, ich werde bald besser" → "Ich hoffe, es geht mir bald besser"
   - 이전 세션 수정 사항 포함 (Ich hätte gerne / Es tut mir wirklich leid / stressbedingter Erschöpfung 등)
2. **scenarios.json append** — B2 3개 + 신규 5개 → 총 21개
3. **신규 시나리오 5개** (원어민 DE/EN으로 초안부터 작성):
   - `taxi_street` [A2] — 일반 택시, 길 지시, 요금 정산. Grammar: -(아/어) 주세요
   - `plans_with_friend` [A2, casual] — 금요일 약속 잡기. Grammar: -(으)ㄹ래?/ㄹ까?
   - `running_late` [A2, casual] — 30분 지각 카톡, ㅋㅋ 문화. Grammar: -고 있어 + -(으)ㄹ 것 같아
   - `postpone_plans` [B1, casual] — 하루 전 미루기. Grammar: -게 됐어
   - `cancel_plans` [B1, casual] — 당일 몸 안 좋아서 취소. Grammar: -아/어서 + 못 -(으)ㄹ 것 같아

**검증:** `python3` JSON 파싱 + 전 필드 검사 통과. 오류 0건.

**파일:**
- `assets/data/scenarios.json` (+8 시나리오)
- `docs/store/b2_scenarios_draft.json` (최종본)
- `docs/store/backdrop_prompts_day1.md` (백드롭 5장 이미지 생성 프롬프트 — Jin 사용)

**Git push:** Jin 요청으로 커밋 완료 → `origin/main`

---

### 2026-05-22 — 출시 폴리시 Week 1–4 (plan: hangul-sori-temporal-wombat)

**범위:** 4주 폴리시 — 접근성·모션 일원화·빈상태·모듈 폴리시·스토어 자료. 코드만 작업 (PNG는 Jin이 별도 생성).

**Update:**
- **Week 1**: Semantics 6개 위젯 + `primaryOnLight` 토큰 + `SoriMotion.reduceMotion` + `SoriTextTheme` + `flutter_animate` 제거 + `_BreathingTransform` 인라인 위젯 (`app_error.dart` 재작성)
- **Week 2**: `SoriEmptyState`·`HanokHeader` 신규 + 5개 빈/오류 상태 통일 + Settings/Stats 헤더 슬롯 + ARB 10키
- **Week 3**: Chosung 라운드(10문제) 요약 카드 + Wordle Focus/Enter 단축키 + 시나리오 backdrop opacity 0.08
- **Week 4**: `docs/store/` 6개 문서 (README, listing-de, listing-en, data-safety, screenshot-shotlist, release-notes-v1)

**검증:** `flutter analyze` = 0 issues · debug APK 빌드 통과. 시각 검증은 Jin 실기기에서.

**미해결 (위 체크리스트 참조):** Hangul IoU 정확도(deferred), Data Safety 답변 확정(Crashlytics/Analytics/AdMob 확인 필요), PNG 자산 8종 생성.

**Git push:** 본 커밋 → `origin/main`

### 2026-05-27 — 출시 직전 더블 크로스체크 + Play Console 일관성 픽스

**범위:** 동시 세션이 푸시한 `84bad36` (Crashlytics/Analytics 연동) 직후 점검. Play Console 등록 직전 *문서 ↔ 코드 ↔ 매니페스트* 정합성을 다시 본 결과 모두 작은 불일치들이 남아 있었음. 빌드 차원의 결함 0건, 출시 정합성 결함 4건 수정.

**Audit 결과:**
- ✅ `firebase_crashlytics ^4.3.10` + Gradle plugin `3.0.1` + `main.dart::_initFirebase` Hook (`FlutterError.onError` + `PlatformDispatcher.onError`) — 정확히 권장 패턴
- ✅ `firebase_analytics ^11.6.0` pubspec 등록 — SDK 링크만으로 auto-collection 활성 (custom event 미사용)
- ✅ `google-services` 4.4.2, `firebase.crashlytics` 3.0.1 — settings.gradle.kts에 정확히 등록
- ✅ `android/app/build.gradle.kts` — `isMinifyEnabled = true`, `isShrinkResources = true`, ProGuard rules 적용. R8 난독화 ON
- ✅ `proguard-rules.pro` — Firebase + Flutter + flutter_tts + Parcelable 보존 규칙 모두 포함
- ✅ `flutter_animate` 패키지 코드/pubspec에서 완전 제거 (한 줄 주석만 잔존)
- ✅ `print()` 잔존 0건. `debugPrint` 2건 (main.dart의 Firebase init fail + palette_service의 RC fetch fail) — 모두 best-effort 로깅. 민감 정보 노출 없음
- 🔴 `AndroidManifest.xml` — AdMob `APPLICATION_ID` meta-data가 **test ID**로 남아 있음. `google_mobile_ads`는 pubspec에서 주석 처리됐고 `ad_service.dart`는 stub → manifest 잔재가 "no ads" Data-Safety 주장을 흐림
- 🔴 `assets/illustrations/error/offline_lantern.png.png` — 더블 확장자 (.png.png)
- 🔴 `assets/illustrations/empty/studyroom_wating.png` — 오타 (`wating` → `waiting`)
- 🔴 Jin이 새로 만든 5장 PNG (empty/error)이 코드에 wire-up 안 됨 — 화면들이 여전히 mascot 이미지를 사용
- 🔴 `docs/store/data-safety.md` 끝의 "Open questions" 3개 (Crashlytics/Analytics/AdMob) 미해결 → Play Console form 작성 불가
- 🟡 In-app account deletion 미구현 (Play 5월 2024 정책 위반 가능성) — v1.0.1 후보로 메모

**Update (모두 이 세션에서 수정):**
1. **AdMob 매니페스트 잔재 제거** — `AndroidManifest.xml`의 `com.google.android.gms.ads.APPLICATION_ID` meta-data 삭제 + "AdMob 재활성화 시 어떻게 되돌리는지" 주석 남김
2. **PNG 파일명 수정** — `offline_lantern.png.png` → `offline_lantern.png`, `studyroom_wating.png` → `studyroom_waiting.png`
3. **5장 PNG 코드 wire-up**:
   - 시나리오 로드 실패 (`scenarios_list_screen.dart:81`) → `error/lost_magpie.png`
   - 시나리오 B2 잠금 (`_EmptyLevelCard` Image.asset) → `locked ? empty/sleeping_tiger_b2.png : mascot/tiger_blink.png` 분기
   - 단어장 due 완료 (`vocab_screen.dart:229`) → `empty/celebrate_complete.png`
   - 설정 오프라인 (`settings_screen.dart:340`) → `error/offline_lantern.png`
   - 통계 첫 진입 (`stats_screen.dart:50`) → `empty/studyroom_waiting.png`
   - 모두 `errorBuilder` 아이콘 fallback이 있어 PNG 로드 실패 시 자동 폴백
4. **data-safety.md 전면 보강** — SDK Audit 표 추가, "Open questions" 모두 ✅로 해결, "Account Deletion (Play-Policy)" 섹션 추가. Play Console form 그대로 옮길 수 있는 상태로 정리

**Play Console 입력값 (확정):**
- Privacy URL: `https://hangul-sori.com/privacy.html`
- App Access: "All functionality is available without special access" (익명 Firebase Auth로 모든 기능 접근 가능 — 검토용 계정 불필요)
- Data Safety: `docs/store/data-safety.md` 표 그대로
  - **수집 데이터**: Email + Display Name (Google opt-in), User ID (Firebase UID, 자동), App Activity (XP/Streak/Progress + Analytics auto-events), Crash logs, Diagnostics, Device/other IDs (Firebase Installation ID + Advertising ID via Analytics)
  - **공유**: 없음. **판매**: 없음. **암호화 in transit**: Yes (TLS).
- Category: Education (Bildung)
- Content rating: IARC 13+
- Target audience: 13+ (DE+EN)
- Support email: `hello@hangul-sori.com`

**검증:**
- 정적 분석 (코드 검토): ✅ 모든 변경이 기존 패턴과 일관. 추가된 PNG 경로 모두 `errorBuilder` 안전망 있음. 컴파일 이슈 없음.
- 빌드 검증: 샌드박스에 flutter 미설치 → Jin 로컬에서 `flutter analyze && flutter test && flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols` 1회 실행 필요. 동일 패키지 셋업으로 직전 커밋(`84bad36`)이 통과했으므로 회귀 가능성 낮음.

**Jin 로컬 env 액션 (이전 세션 미완 — 그대로 유효):**
1. Android Studio → SDK Manager → SDK Tools → "Android SDK Command-line Tools (latest)" 설치
2. `flutter doctor --android-licenses` 실행 → 모두 `y`
3. 프로젝트 루트에서:
   ```bash
   flutter clean
   flutter pub get
   flutter analyze
   flutter test
   flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
   ```
4. 결과 AAB: `build/app/outputs/bundle/release/app-release.aab` → Play Console Closed Testing 트랙 업로드
5. 동시에 `build/app/outputs/symbols/` 의 native debug symbols를 Play Console "App bundle explorer → Native debug symbols" 에 업로드 (난독화 스택 trace 복원용)

**미수행 (v1.0.1 후보 또는 Jin 영역):**
- 🟡 In-app account deletion (`AuthService.deleteAccount()` + Firestore doc 삭제) — Play 2024년 5월 정책 권장사항. 출시 후 14일 내 patch
- 🟡 Track B 남은 PNG (마스코트 추가 포즈, hero PNGs 등) — Jin 작업, errorBuilder fallback으로 빌드는 정상
- 🟡 실기기 시각 검증 (특히 새로 wire-up한 5장 PNG가 의도대로 보이는지)
- 🟡 Track D B2 시나리오 — 동시 세션 `6898646`에서 B2×3 추가됨 (확인 필요)
- 🟡 Crashlytics + Analytics console에서 실제 데이터 수신 확인 (release build 한 번 실행 후)

**Git push:** 미수행 (Jin 확인 후 명시 요청 시 commit & push).
**변경 파일:** `AndroidManifest.xml`, `data-safety.md`, `scenarios_list_screen.dart`, `vocab_screen.dart`, `settings_screen.dart`, `stats_screen.dart`, `CLAUDE.md` + PNG 2장 rename + 3장 staging (`lost_magpie.png`, `offline_lantern.png`, `studyroom_waiting.png`).

### 2026-05-27 (3차) — AAB 크기 최적화 (97MB → 예상 ~55MB)

**범위:** 1차 빌드가 97MB AAB로 나옴 → Jin이 줄이고 싶다고 함 → 자산 분석 + 무손실 PNG 압축 + Gradle 설정 정리.

**진단:**
- AAB 97MB 중 자산 PNG가 ~46MB (mascot 21 + scenes 11 + empty 6.4 + error 4 + hanok 3.4)
- 모든 일러스트 PNG가 1024-1254px, RGB/RGBA 무압축으로 저장됨 (각 ~2MB)
- Faceted Minhwa 스타일 = 단청 면 분할 = 평면 색상 → palette 양자화에 이상적

**Update (2단계 최적화):**
1. **Gradle 설정** (`android/app/build.gradle.kts`):
   - `buildTypes.release { ndk { debugSymbolLevel = "NONE" } }` 추가
   - native debug symbols를 AAB에 packing 안 함 → 5-15MB 절감
   - 심볼은 이미 `build/app/outputs/symbols/`에 있어 Play Console에 따로 업로드 가능

2. **PNG 양자화 압축** (Pillow Image.quantize, palette 256색):
   - RGBA → FASTOCTREE, RGB → MEDIANCUT
   - 백업은 `assets/illustrations/.backup_uncompressed/`에 자동 저장 (`.gitignore`에 추가)
   - 원본을 in-place로 압축 (코드 경로 변경 불필요)

**결과:**
| 폴더 | Before | After | 절감 |
|---|---|---|---|
| mascot/ | 21 MB | 1.6 MB | -93% |
| scenes/ | 11 MB | 4.5 MB | -59% |
| empty/ | 6.4 MB | 4.1 MB | -36% |
| error/ | 4.0 MB | 2.0 MB | -50% |
| hanok/ | 3.4 MB | 3.0 MB | -12% |
| **TOTAL** | **45.9 MB** | **13.9 MB** | **-70% (30.5 MB 절감)** |

- `madang(light/dark).png` 2장은 사진풍 그라데이션이라 양자화가 오히려 크게 만들어 → 원본 복구
- `calligraphy/porch/study/welcome-hero/gate.png` 5장은 이미 어느정도 최적화 상태 → 1% 정도만 줄어듦
- 시각 검증: tiger_idle / cafe / celebrate_complete / magpie_perched 4장 spot check → 육안으로 원본과 구분 불가능

**예상 AAB 크기:** 97 MB → **~55 MB** (자산 30 MB + symbols 5-15 MB 절감)
**예상 사용자 다운로드:** ABI split 후 **15-25 MB** (이전 30-40 MB → 절반)

**다음 단계 — Jin이 재빌드:**
```bash
flutter clean
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
ls -lh build/app/outputs/bundle/release/app-release.aab
```

**롤백 방법** (압축 결과가 마음에 안 들면):
```bash
cp -r assets/illustrations/.backup_uncompressed/* assets/illustrations/
```
백업 폴더는 `.gitignore` 처리됨 → repo 크기 영향 없음.

**변경 파일:** `android/app/build.gradle.kts` (ndk debugSymbolLevel), `.gitignore` (backup 폴더 제외), `assets/illustrations/{mascot,scenes,empty,error,hanok}/*.png` (압축).
**Git push:** 미수행.

### 2026-05-27 — Play Console 타겟 연령 결정 + iOS AdMob 잔재 정리

**범위:** Play Console "앱 타겟층 및 콘텐츠" 5단계 답변 확정 + 향후 광고 도입 시 정책 위반 0 로드맵 정리 + iOS AdMob 잔재 제거.

**Audit:**
- Android-Manifest, pubspec.yaml, ad_service.dart 모두 "no ads" 일관 ✅
- 🔴 iOS Info.plist에 `GADApplicationIdentifier` (test ID) + `SKAdNetworkItems` 잔존 — Android와 비대칭, Data-Safety "no ads" 답변과 불일치 우려

**Update:**
1. `ios/Runner/Info.plist` — `GADApplicationIdentifier` + `SKAdNetworkItems` 제거, Android-Manifest와 동일 패턴의 복원 안내 주석 추가
2. `docs/store/data-safety.md` SDK-Audit 표에 iOS 정리 반영
3. `docs/store/target-audience-and-ads.md` 신규 — Play Console 5단계 답변 가이드 + 광고 도입 시 정책 위반 0 체크리스트 (SDK, 코드 복원, 슬롯 설계, Disruptive Ads 9개 항목, Data Safety 업데이트, ATT, 직접 광고주 영업)

**핵심 결정 — 대상 연령대 = 13+ (13–15세 + 16–17세 + 18세 이상 3개 체크):**
- 콘텐츠는 G-rated이지만 K-pop/K-drama 영향 청소년+성인이 시장 현실
- 13세 미만 포함 시 COPPA + GDPR-K (독일 16세) + Google Families Programme 부담 폭발
- 기존 문서(IARC 13+, Apple App-Privacy) 일관성 유지

**검증:** 정적만 — 빌드는 Jin 로컬. 변경된 Dart 코드 0줄이라 회귀 가능성 0.

**Git push:** 미수행.

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
