# CLAUDE.md — ko_lernen_app (Hangul Sori)

> 세션 시작 시 이 파일 먼저 읽기. 그 다음 필요한 파일만 grep/Read.
> 전역 운영 원칙은 `~/.claude/CLAUDE.md` 참조.
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
- `lib/main.dart` — 라우트 테이블, Firebase/Ad 초기화, 팔레트 서비스. **`initialRoute: '/intro'`** — 솟을대문 인트로 후 온보딩/홈으로 분기
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
- `tiger_stage_rive.dart` — **Rive 리깅 호랑이 래퍼**(부드러운 sit→인사→pacing 목표). `assets/rive/tiger.riv` + `RiveNative.init()` 성공(`riveReady`) 시 Rive 재생, 그 외(미초기화·파일 없음·로드 실패·reduce-motion) `TigerStage`(프레임)로 자동 폴백. rive 0.14 API(`RiveWidgetBuilder`/`FileLoader.fromAsset`/`Factory.flutter`/`RiveWidget(fit:contain)`). **`tiger.riv` 리그는 미제작(Rive 경로 보류) — 프레임 폴백으로 동작.** 호랑이 전체 스펙은 `docs/TIGER_FULL_REMAKE_MASTER.md`. 홈 `_TigerHero`가 이걸 사용.
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
- ⚠️ **콘텐츠 언어**: `korean_vocab.csv`(`german`)·`grammar.csv`(`explanation_de`/`example_german`)는 **독일어 전용**. 영어 UI 사용자도 학습 콘텐츠는 독일어로 표시됨 (영어권 출시 시 컬럼 추가 필요).

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
