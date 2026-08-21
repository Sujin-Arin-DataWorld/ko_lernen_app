# UI/UX Bible Application — Execution Lock

- **Version:** 1.18
- **Created:** 2026-08-21
- **Branch:** `session/uiux-bible-learning-3b-listening-2026-08-21`
- **Base:** `origin/main@1c149cfebe7e1f060a5d1c6e8a9cc64bd33beecc`
- **State:** Phase 3B Listening browsing UI locally green; awaiting
  PR/current-head CI
- **Next action:** commit the Listening browsing unit, open its app PR, require
  green CI for the exact current head, merge, and cancel only that merge's
  deploy-capable `main` run before recording final evidence in a docs-only
  closeout

## 1. Purpose

This is the sole restart document for applying the approved UI/UX Bible across
the app. A later session starts with only:

1. `AGENTS.md`
2. `docs/HANDOFF_UI_OVERHAUL_2_2026-08-14.md`
3. `docs/UIUX_NATIVE_GAME_PHASE2_EXECUTION_LOCK.md`
4. this file

Historical handoffs are not startup reading. Open one only when a disputed fact
is absent from all four sources above, and add the resolved fact here before
continuing.

This file is a state lock, not a new design system. It records what exists,
what remains, the permitted boundaries, and the next independently mergeable
change.

## 2. Authority and resolved supersessions

Authority order is:

1. the current `AGENTS.md`;
2. the approved Bible, `docs/HANDOFF_UI_OVERHAUL_2_2026-08-14.md`;
3. the merged native/game boundary contract in
   `docs/UIUX_NATIVE_GAME_PHASE2_EXECUTION_LOCK.md`;
4. current code and executable tests;
5. this file for execution state and phase order.

Resolved stale instructions:

- `AGENTS.md` now forbids `docs/SESSION_LOG.md` edits, so the Bible's older
  SESSION_LOG requirement does not apply.
- The Bible's old dirty-worktree warning is historical. This work uses a clean,
  Windows-native worktree from the current merged main.
- The Bible's P1–P5 Deck/Today/Catalog/Gye/Hanok work is already present on
  main. It is the approved baseline, not a request to rebuild those phases.
- No asset generation follows from this task. Approved assets remain unchanged;
  any new or regenerated art still needs a separate visual approval gate.
- The app is intentionally light-only: `ThemeMode.light`, with the light theme
  also supplied as the defensive dark-theme fallback.

If a new conflict cannot be resolved by this order, write the exact options,
impact, and recommendation here and stop that phase before implementation.

## 3. Fixed scope and invariants

### In scope

- Apply the Bible's Sori Deck / risograph hanji visual language consistently.
- Use the existing `lib/widgets/sori` tokens and components; improve them in
  place before touching repeated screen implementations.
- Make hierarchy, spacing, states, forms, responsiveness, text scaling,
  semantics, and reduced motion consistent across every user-facing surface.
- Keep phases small, testable, reviewable, and independently mergeable.

### Protected behavior

- Routes and route arguments.
- Learning content, scoring, SRS, mastery, course evidence, and unlock rules.
- Authentication, account deletion/recovery, purchase, restore, and entitlement
  behavior.
- Firebase, Cloudflare, RevenueCat, notification, camera, microphone, OCR, and
  platform ownership boundaries.
- Game rules, timing semantics, gestures, hitboxes, and canvas geometry.
- Sori Stage five-tab information architecture and approved assets.
- Phase 2 rule: app-owned UI uses Sori surfaces; OS/SDK-owned UI stays native;
  game canvas remains game-owned inside the shared Sori frame.

### Out of scope

- Deployment, store upload, production configuration, Firebase/Cloudflare
  mutation, paid-service use, asset generation, and deletion.
- New navigation architecture, state-management rewrite, data migration, new
  tokens, a parallel component library, or speculative feature work.
- Hiding content with `TextOverflow.ellipsis`.

## 4. Bible contract applied to the whole app

- One primary message and one clear next action per surface.
- Sori Stage five-tab shell is the only app shell.
- Hanji ground, raised white-hanji cards, dancheong accents, and illustration
  language remain the visual grammar. Generic iOS pill styling is not added.
- Use `SoriTypeScale`, `SoriTextTheme`, `Spacing`, `SoriRadius`,
  `SoriStandardPage` / `SoriStandardFrame`, `SoriStudyFrame`, and the existing
  responsive clamps before adding local layout values.
- Complete text must remain reachable at large text scale; wrap, scroll,
  reflow, or scale down bounded chrome instead of truncating meaning.
- Text measured to size a catalog cell must use the same `SoriTextTheme` token
  as the rendered text. `PackCard` locked hints and `VocabPacksScreen` grid
  measurement are locked to `caption` so 200% text cannot outgrow stale math.
- Every interactive target keeps a meaningful accessibility label and at least
  48 dp intent-sized affordance unless a tested game-canvas exception owns its
  hitbox.
- Color is never the only state cue. Reduced-motion users receive a stable
  state, not a removed result.
- Loading, empty, error, disabled, offline, success, and retry states use the
  shared Sori language.
- All user-facing copy remains paired DE/EN ARB. No hardcoded replacement copy.
- Tiger and magpie pixels are never AI-generated. Existing approved character
  assets may only be composed through their current contracts.

## 5. Measured baseline and current ratchets

The inventory began at Phase 0; rows updated by completed phases show their
current ratchet:

| Measure | Current state | Locked interpretation |
|---|---:|---|
| Registered route cases | 68 | Every case is inventoried below |
| `lib/screens` Dart files | 96 | Includes route, embedded, preview, and quest surfaces |
| `lib/widgets/sori` Dart files | 125 | Existing system; no parallel system permitted |
| Test files | 440 | Reuse focused suites plus shared matrices |
| Raw screen `TextStyle` | 302 (guard ≤302) | Must not increase; migrate by touched surface |
| Raw screen `fontSize` | 277 (guards ≤95 at w800, ≤28 at w900) | Reduce through tokens, never raise ratchets |
| Numeric screen `BorderRadius.circular` | 97 (guard ≤33) | Touched code uses radius tokens |
| Raw screen `Scaffold` calls | 52 | Many are intentional shell/immersive owners; classify before changing |
| Screen `TextOverflow.ellipsis` | 0 | Locked at zero |
| Common-appbar ellipsis | 0 | Phase 1A removed both without hiding text |
| Screen text fields | 22 | Recall input now uses `SoriTextField`; guard locked at ≤22 |
| Raw screen progress indicators | 12 | Replace only where not canvas/inline progress |
| `AppLoading` uses | 34 | Retain as the standard full-state loader |

Current shared coverage includes `screen_smoke_test`, `responsive_test`,
`responsive_short_height_test`, `standard_surface_responsive_test`,
`study_activity_responsive_test`, `sori_standard_page_test`,
`accessibility_guideline_test`, `typography_guard_test`, and Linux screen
goldens. A shared suite is not proof of every state variant; the route audit
names the focused dependency that must remain green.

### Audit shorthand

- **Std**: `SoriStandardPage` or `SoriStandardFrame` owns the surface.
- **Study**: `SoriStudyFrame` owns the focus activity.
- **Custom**: raw scaffold/embedded layout with a justified shell, cinematic,
  room, or game owner; it is not automatically a defect.
- **R/S/G/D**: shared responsive, smoke, golden, or dedicated focused tests.
- Risk **H** means logic/platform/evidence or dense interactive geometry is
  adjacent; **M** means stateful layout or many variants; **L** means isolated
  presentation.

## 6. Route-by-route audit

The target column describes the allowed UI work, not permission to change the
listed dependency.

| Route | Screen / current owner | Bible target | Protected dependency | Verification | Risk / phase |
|---|---|---|---|---|---|
| `/splash` | `SplashScreen` / Custom | Keep cinematic entry; only scale/safe-area polish | startup timing and routing | D onboarding flow | M / 5C |
| `/quick_onboarding` | `QuickOnboardingScreen` / embedded flow | Keep short single-action sequence; unify type/actions | onboarding service/storage | D quick onboarding | H / 5C |
| `/character_selection` | `CharacterSelectionScreen` / Custom | Keep approved character composition; normalize cards/actions | companion persistence, no character generation | R/S/D character | H / 5C |
| `/intro` | `IntroGateScreen` / Custom | Keep gate cinematic and complete labels | startup/onboarding route decision | S/D onboarding | H / 5C |
| `/` | `AppShell` → `SoriStageShell` / Custom | Preserve five tabs; verify adaptive rail/bottom chrome | tab state, reselect, route observer | R/S/G/D stage shell | H / 2A |
| `/onboarding` | `OnboardingLevelScreen` / Custom | Keep immersive composition; align hierarchy and large text | placement/onboarding decisions | R/S/D onboarding | H / 5C |
| `/onboarding/start` | `OnboardingStartScreen` / Custom | Normalize step actions and scroll reachability | onboarding flow state | R/D onboarding start | M / 5C |
| `/vocab` | `VocabPacksScreen` / Custom | Retain approved 4:3 catalog; move residual chrome to shared rules | course context, pack loading/premium | R/S/G/D vocab packs | H / 3A |
| `/vocab/pack` | `VocabPackScreen` / Study | Preserve Deck geometry/gestures; token polish only | SRS ledger, learn queue, flip gate | R/D deck battery | H / 3A |
| `/vocab/result` | `VocabPackResultScreen` / Study | Standard result hierarchy and reduced-motion reward | result/clear evidence | D vocab result | H / 3A |
| `/vocab/recall` | `VocabPackRecallScreen` / Custom | Move outer chrome/states to study conventions, not card logic | recall session and ordering | D recall | H / 3A |
| `/vocab/legacy` | `LegacyVocabScreen` / mixed | Preserve rollback route; remove only residual visual divergence | legacy SRS and flip gate | R/S/D legacy deck | H / 3A |
| `/grammar` | `GrammarScreen` / Study | Replace residual raw type/radius with existing study tokens | grammar loaders/course context | R/S/D grammar | H / 3B |
| `/listening` | `ListeningScreen` / Std | Standard browsing hierarchy/states | scenario shelf and TTS availability | R/S/D listening | M / 3B |
| `/listening/play` | `ListeningPlayScreen` / Study | Keep player controls and transcript reachability | audio/TTS and scenario dialog | R/D study activity | H / 3B |
| `/kkeunmari` | `KkeunmariScreen` / Study | Tokenize dense play surface without geometry/rule change | dictionary engine and timers | R/S/D game engine | H / 5A |
| `/hangul` | `HangulScreen` / Custom | Normalize type/actions around owned composer/canvas | composition, strokes, writing gates | R/S/D Hangul battery | H / 3B |
| `/chosung` | `ChosungQuizScreen` / Study | Preserve hitboxes; unify hints, input, results | quiz rules and hint plan | R/S/D game tests | H / 5A |
| `/wordle` | `SilbenKreuzScreen` / Study | Preserve grid geometry; unify outer frame/status cues | puzzle generation and cell rules | R/S/D Silben tests | H / 5A |
| `/cloze` | `ClozeGameScreen` / Study | Shared prompt/choice/result hierarchy | course evidence and cloze loader | R/D cloze | H / 3B |
| `/speed_match` | `SpeedMatchScreen` / Study | Preserve active-time clock/hitboxes; unify states | timer/pause and scoring | R/D Phase 2 game | H / 5A |
| `/daily` | `DailyChallengeScreen` / Study | Use shared study/result patterns | challenge content and completion | R/D daily | H / 3B |
| `/calligraphy` | `DailyCalligraphyRouteScreen` / Std | Keep writing sheet ownership; standard page chrome | calligraphy data/export | focused + standard page | M / 3B |
| `/practice` | `PracticeHubScreen` / Std | Clear module hierarchy and one primary next action | activity routes | R/S/D practice hub | M / 3D |
| `/pronunciation` | `PronunciationStudioScreen` / Std | Normalize capture states and feedback hierarchy | microphone consent/SDK boundary | R/D pronunciation | H / 3B |
| `/satz_arcade` | `SatzArcadeScreen` / Study | Preserve tile geometry/evidence; shared study chrome | course context and scoring | R/D Satz | H / 3B |
| `/settings` | `SettingsScreen` / Std | Tokenize dense sections/forms without changing operations | account, consent, notification, locale | R/S/G/D settings | H / 4A |
| `/stats` | `StatsScreen` / Std | Standardize cards, empty state, chart semantics | progress/stat aggregation | R/S/D stats | M / 4A |
| `/profile` | `ProfileScreen` / Std | Standardize identity/action hierarchy | auth, sync, account linking | R/D profile | H / 4A |
| `/paywall` | `PaywallScreen` / Custom | Keep branded offer; normalize action/error/accessibility states | RevenueCat and entitlement | R/D purchase contracts | H / 4A |
| `/review` | `ReviewSessionScreen` / Study | Preserve approved Deck and SRS evidence | SRS order/ledger/flip gate | R/D deck battery | H / 3A |
| `/smalltalk` | `SmalltalkScreen` / Study | Shared prompt/feedback hierarchy | course evidence and speech/content | R/D smalltalk | H / 3C |
| `/scenarios` | `ScenariosListScreen` / Std | Preserve shelf art; reduce residual local type/card styles | scenario availability/catalog | R/S/D scenario shelf | M / 3C |
| `/quests` | `QuestsScreen` / Std | Shared reward/empty/progress language | quest tracker, reward evidence | R/D quest battery | H / 3D |
| `/book` | `BookCaptureScreen` / Std | Standard capture states and one clear next action | camera/OCR/privacy boundary | D book flow/security | H / 4B |
| `/vocab_notebook` | `BookCaptureScreen` / Std | Same capture UI with notebook mode preserved | capture mode and target pack | D notebook/book flow | H / 4B |
| `/vocab_notebook/result` | `VocabNotebookResultScreen` / Custom | Adopt standard frame/form/state primitives | parser and saved-word decisions | D notebook result | H / 4B |
| `/vocab_notebook/practice` | `VocabNotebookPracticeScreen` / Custom | Adopt study frame while preserving item flow | notebook pack contents | focused empty/responsive | M / 4B |
| `/vocab_notebook/nuance` | `VocabNuanceScreen` / Custom | Adopt standard/study states and complete text | nuance service/output | D nuance | M / 4B |
| `/vocab_notebook/studio` | `VocabNotebookStudioScreen` / Custom | Standard frame/forms/loading | notebook studio service | D studio | H / 4B |
| `/book/preview` | `BookPreviewScreen` / Std | Standard form/editor hierarchy | OCR document and locale | D book preview | H / 4B |
| `/book/result` | `BookResultScreen` / Std | Standard results/error/save actions | analysis and pack creation | D book result | H / 4B |
| `/bookshelf` | `BookshelfScreen` / Std | Retain approved shelf; unify dialogs/fields/state | bookshelf sync/generation | R/G/D bookshelf | H / 4B |
| `/bookshelf/page` | `BookshelfPageScreen` / Std | Standard detail hierarchy and edit dialog | stored page and sync | R/D bookshelf | M / 4B |
| `/custom_pack/play` | `CustomPackPlayScreen` / Study | Preserve Deck/flip gate; shared states | pack contents and SRS | R/D custom deck | H / 3A |
| `/custom_pack/edit` | `CustomPackEditScreen` / Std | Shared field/dialog/state primitives | import, persistence, language | R/D custom pack | H / 4B |
| `/custom_pack/quiz` | `CustomPackQuizScreen` / Study | Shared study/result language | pack quiz scoring | R/D study activity | H / 5B |
| `/custom_pack/matching` | `CustomPackMatchingScreen` / Study | Preserve matching geometry; shared states | matching rules | R/D study activity | H / 5B |
| `/custom_pack/typing` | `CustomPackTypingScreen` / Study | Shared input/status, preserve answer logic | typing evaluation | R/D study activity | H / 5B |
| `/wordbook/search` | `WordbookSearchScreen` / Std | Shared field/empty/result language | wordbook service | R/D wordbook | M / 4C |
| `/hard_words` | `HardWordsScreen` / Std | Standard list/empty/action hierarchy | wrong-count data | R/D hard words | M / 4C |
| `/word_web` | `WordWebScreen` / Custom | Standard outer state; preserve study/quiz transition | word relation data | D word web | H / 3D |
| `/dojangcheop` | `DojangcheopScreen` / Std | Preserve reward room; standard empty/CTA | achievement data | R/D room CTA | M / 4C |
| `/hanok` | `HanokWorldScreen` / Custom | Preserve world/map ownership and approved assets | grant/evidence projection | R/S/G/D Hanok battery | H / 2D |
| `/hanok/anbang` | `PersonalRoomFurnishScreen` / Custom | Preserve room canvas; normalize overlays/actions | personal room inventory | R/S/D furnish | H / 4C |
| `/hanok/daecheong` | `PersonalRoomFurnishScreen` / Custom | Same contract with surface argument preserved | personal room inventory | R/S/D furnish | H / 4C |
| `/sarangbang` | `SarangbangStudyScreen` / Custom | Preserve room composition; standard states/actions | recommendations/course evidence | R/S/D Sarangbang | H / 3D |
| `/sarangbang/furnish` | `SarangbangFurnishScreen` / embedded owner | Preserve room canvas and picker hitboxes | room inventory/placement | R/S/D picker | H / 4C |
| `/bojagi` | `BojagiScreen` / Std | Keep reward offer semantics; standard loading/empty | decoration grant eligibility | D Bojagi | H / 4C |
| `/gye/create` | `GyeCreateScreen` / Std | Shared fields, validation, actions | membership creation/write gate | focused Gye tests | H / 4C |
| `/gye/join` | `GyeJoinScreen` / Std | Shared code fields and states | join/membership epoch | focused Gye tests | H / 4C |
| `/gye/hub` | `GyeTabScreen` / Custom | Retain approved compact landing | membership stream/chooser | R/D Gye landing | H / 2C |
| `/gye` | `GyeScreen` / mixed | Preserve nested/member state; standard outer chrome | feed, promise, dedication | R/D Gye screen | H / 4C |
| `/gye/members` | `GyeMembersScreen` / Std | Shared moderation form/dialog patterns | member roles/report service | D Gye members | H / 4C |
| `/path` | `LearningPathScreen` / Std | Preserve evidence path; token/semantics polish | course graph and unlock rules | R/S/D learning path | H / 3C |
| `/course/mission` | `CourseMissionScreen` / Std | One mission brief/action; standard states | mission plan and completion evidence | R/D course battery | H / 3C |
| `/course/reassessment` | `CourseReassessmentScreen` / Custom | Standard outer frame/forms without changing evidence | reassessment arguments/mastery | D reassessment | H / 3C |
| `/scenario` | `ScenarioPlayerScreen` / Custom | Preserve roleplay/quest canvas; normalize outer states | scenario evidence, audio, quest rules | S/D scenario battery | H / 3C |

## 7. Embedded and indirect screen audit

These surfaces are not independent route cases but are user-visible and must
not disappear from phase review.

| Surface | Current state | Target / dependency | Tests | Phase |
|---|---|---|---|---|
| `SoriStageTodayScreen` | approved custom tab + golden | Preserve Today v2; shared chrome/state checks only | R/G/D Today | 2B |
| `SoriStageCatalogScreen` | approved custom tab | Preserve 4:3 catalog and reward flow | R/D catalog | 2B |
| `SoriStageGyeScreen` | safe viewport + embedded Gye | Preserve chooser/membership behavior | R/D Gye | 2C |
| `SoriStageHanokScreen` | safe viewport + shortcut tiles | Preserve approved shortcuts/assets/evidence | R/D Hanok shortcuts | 2D |
| reward receipt sheet | Sori sheet + semantics | Keep evidence/result hierarchy | dedicated receipt | 2D |
| `DiscoverScreen` | Std supporting catalog | Keep dormant/supporting surface aligned; do not add a route | R/D discover | 2B |
| onboarding preview / placement diagnostic | custom + Std | Align step hierarchy; preserve placement decisions | R/D onboarding/placement | 5C |
| consent / first voice success | custom | Shared action/state patterns; preserve consent/evidence | R/D consent/voice | 5C |
| course mission path overview | embedded | Preserve graph/evidence; token polish | dedicated overview | 3C |
| grammar/hard choice quizzes | Study | Shared result/choice language; preserve scoring | R/D choice quizzes | 5B |
| word-web study / quiz | custom + Study | Standard outer state; preserve relation logic | D word web | 3D/5B |
| six quest engines + `QuestLayout` | game-owned canvas/frame | No rule/hitbox change; semantics/non-color/reduced motion | D quest + Phase 2 guards | 5B |
| Sori Stage preview/gallery screens | diagnostic-only | Keep deterministic and aligned with production tokens | D UX preview | 6 |

## 8. Common-component audit

Every file under `lib/widgets/sori` is covered by one family below. “Retain”
means it is already part of the canonical system; touched implementations must
use it rather than reproduce it locally.

| Family | Files | Audit decision |
|---|---|---|
| Foundations and frames | `tokens`, `type_scale`, `window_class`, `responsive`, `screen_background`, `standard_page`, `study_frame`, `app_bar`, `adaptive_navigation`, `page_header`, `section_header`, `scroll_if_needed`, `motion`, `pressable` | Retain. Phase 1A removes appbar truncation and strengthens frame/reduced-motion tests. No new token layer. |
| Core controls and overlays | `button`, `card`, `chip`, `badge`, `progress`, `dialog`, `sheet`, `toast`, `sori_icon`, `illustrated_card`, `sticker_image`, `sticker_picker`, `room_slot_picker` | Retain. Touched screens migrate raw equivalents; labels remain complete and semantic. |
| State, account, and guidance | `empty_state`, `text_field`, `account_nudge`, `account_operation_ui`, `age_gate_prompt`, `consent_invite_sheet`, `external_link`, `feature_coach`, `screen_coach`, `spotlight_coach`, `diagnostics_route_observer`, `route_observer`, `tab_reselect` | Retain. `SoriTextField` is the canonical app-owned input wrapper; screens migrate incrementally without changing validation, persistence, or submit behavior. |
| Study and evidence | `can_do_result_card`, `chosung_hint`, `cloze_prompt`, `content_feed`, `content_feedback_card`, `content_feedback_sheet`, `course_mission_brief`, `course_progress_evidence_note`, `culture_note_card`, `deck_action_bar`, `deck_coach`, `game_layout`, `game_reward`, `hub_progress_header`, `level_chip`, `mission_context_bar`, `mission_hero_card`, `module_card`, `pack_card`, `path_preview_row`, `path_trail`, `quiz_choice`, `scenario_write_after_roleplay_card`, `score_pop`, `share_slip`, `stats_top_bar`, `study_action_bar`, `study_card_face`, `swipe_card`, `swipe_rails`, `tts_speed_control`, `tts_unavailable_banner`, `week_progress`, `week_sheet`, `wordbook_add`, `ko_wrap` | Protected. Visual adoption must not bypass the evidence, flip-gate, SRS, timer, or route contracts these components encode. |
| Rewards, art, and media | `activity_illustration`, `activity_sheet`, `ambient_particles`, `celebration`, `character_clip`, `cultural_help`, `dancheong_burst`, `dancheong_stamp`, `decoration_layer`, `home_hero`, `like_burst`, `localized_copy`, `mascot`, `mascot_pop`, `mascot_preference`, `milestone_celebration`, `motivation_sheet`, `pending_reward_card`, `placed_decoration`, `reward_icon`, `reward_thumb`, `tiger_video`, `video_lease` | Retain approved assets and decoder ownership. No generation or silent asset swap. Reduced motion must keep a readable outcome. |
| Hanok and rooms | `a1_hanok_construction_map`, `free_room_layer`, `hanok_build_narrative_line`, `hanok_cinematic`, `hanok_header`, `hanok_stage_names`, `hanok_tokens`, `madang_background`, `personal_hanok_map`, `personal_hanok_unlock_reveal`, `personal_hanok_venue_sheet`, `personal_room_scene`, `room_layer`, `world_map_viewport`, `hanok/eaves_corner`, `hanok/gate_art`, `hanok/giwa_pattern`, `hanok/hanji_texture`, `chaekgado/scroll_palette`, `chaekgado/scroll_sheet`, `chaekgado/shelf_case` | Protected visual/evidence system. UI phases may adjust surrounding chrome only unless a dedicated Hanok test proves map/room geometry unchanged. |
| Gye and community | `dure_board`, `gye_dedication_action`, `gye_dedication_layer`, `gye_dedication_picker`, `gye_feed`, `gye_hanok` | Protected membership, write-gate, and dedication behavior. Use shared fields/dialogs only at app-owned boundaries. |

Two non-Sori state widgets, `lib/widgets/app_loading.dart` and
`lib/widgets/app_error.dart`, are canonical compatibility surfaces used across
the app. Phase 1A fixes `AppError` so its animation controller does not run when
motion is disabled. Phase 1B decides whether their public import location can
be consolidated without churn; no duplicate replacements are allowed.

## 9. Phased delivery lock

Each row is a separate branch/PR from the latest merged main unless a row is
verified as no-code. The execution-lock status is updated in the same PR.

| Phase | Small mergeable unit | Required proof |
|---|---|---|
| 0 | This audit and sole restart document | source links, 68 routes, 96 screens, 125 Sori files, clean diff |
| 1A | Common chrome and motion: remove appbar ellipsis; stop reduced-motion error controller | focused component tests, standard-page matrix, accessibility, guards, analyze |
| 1B | Add one Sori field primitive and state usage contract; migrate only a small representative set | new field tests at DE/EN and 200%; no validation/submit changes; guards |
| 2A | Five-tab shell/adaptive navigation audit fixes | shell/adaptive tests at compact/medium/expanded |
| 2B | Today + catalog residual adoption | Today/catalog suites and Linux goldens if pixels change |
| 2C | Gye tab residual adoption | chooser/membership tests, responsive/accessibility |
| 2D | Hanok tab/world boundary residual adoption | shortcut/map/evidence tests; approved assets unchanged |
| 3A | Vocab/review/custom Deck outer UI | full Deck geometry/gesture/flip/SRS battery |
| 3B | Grammar/listening/Hangul/cloze/daily/pronunciation/Satz | split by at most two related surfaces per PR; focused evidence tests |
| 3C | Path/course/reassessment/scenario/smalltalk | split by evidence boundary; course/scenario full focused battery |
| 3D | Practice/quests/word-web/Sarangbang | focused route/reward/evidence tests |
| 4A | Settings/profile/stats/paywall | split account/purchase from presentation; platform guards |
| 4B | Book/notebook/bookshelf/custom-pack editing | split capture/OCR from local editing; book security + responsive tests |
| 4C | Wordbook/hard words/dojang/rooms/Bojagi/Gye management | split community writes from local tools; focused service tests |
| 5A | Standalone games: Kkeunmari/Chosung/Silben/Speed Match | Phase 2 frame/timer/semantics/hitbox tests |
| 5B | Quiz and quest-engine supporting surfaces | game frame, active-time, reduced-motion, non-color, semantics tests |
| 5C | Splash/intro/onboarding/consent/supporting entry | startup routing, onboarding persistence, 320×640@200% |
| 6 | Full-app closeout | full analyze, full test, diff check, current-head CI; no deployment |

No phase earns work merely because it is listed. Start with code measurement;
if the surface already meets the contract, record it as verified and advance.

## 10. Verification and merge protocol

For every code phase:

1. Confirm a clean worktree and latest `origin/main`; create a new task branch.
2. Update this file's base, state, completed evidence, and exact next action.
3. Run formatter check, `flutter analyze`, `typography_guard_test`, the focused
   suites named above, and the applicable shared responsive/accessibility suite.
4. Exercise DE and EN. For layout-sensitive work cover 320×640 at 200%,
   360×400 short height, 390×844, 720×1024, and 1280×900 as applicable.
5. Generate or update goldens only on Linux and only when the approved pixel
   contract intentionally changes.
6. Run `git diff --check`; stage only task-owned files.
7. Commit and push the phase, open one PR, and inspect the automatic CI run for
   that exact head. Do not create a duplicate exact-head manual run.
8. Merge only after required current-head checks are green. Re-read latest main
   ancestry after merge before creating the next worktree.
9. An app-changing merge to main can automatically schedule Google Play
   Internal Testing when `PLAY_INTERNAL_RELEASE_ENABLED` is true. If the task
   has no store-release authority, cancel that main-push run immediately and
   verify that `Upload to Google Play Internal Testing` is skipped. The green
   PR current-head run remains the delivery proof; do not replace it with a
   release-capable main run.

Local green is local proof. Device behavior, store upload, SDK consoles,
production, and deployment remain unclaimed and out of scope.

## 11. Phase state ledger

| Phase | State | Evidence / next action |
|---|---|---|
| Phase 2 native/game precursor | merged | PR #116; main merge `63b62e10fc923aa91d55642c68d67dae66161178`; CI green; local analyze clean; 4,250 tests passed, 14 conditional skips |
| 0 audit + execution lock | merged | PR #118; main merge `151c08b28a75bf909aa873996b9d495d0bf91f8b`; docs-only CI path filter correctly scheduled no run |
| 1A common chrome/motion | merged | PR #120; main merge `6c631f088d999f25aec1fc7157fac5b34f010435`; CI run 32429108058 green; appbar ellipsis 2→0; reduced-motion error ticker stops |
| 1B common field/state | merged | PR #121; main merge `f6077152e94ef3fa60ec9b240cecaf5068cd9a9c`; CI run 32429999764 green; `SoriTextField` added; screen raw TextField ratchet 25→23 |
| 2A shell/adaptive navigation | merged | PR #122; main merge `22e7a38e4435972c634519fa62efe1eddb6f3ed1`; CI run 32430662420 green; five-tab shell verified unchanged; rail ellipsis 1→0 |
| 2B Today + catalog | merged | PR #123; main merge `afebdd0a2a767d69e7e09e61159ed9c9ecc24b4c`; CI run 32431541123 green; 320×640 at 200% text added to Today long-copy and catalog matrices; approved runtime pixels unchanged |
| 2C Gye tab | merged | PR #124; main merge `abe2be2bb278a257e776e0e4c2a043b2e4ed4c6f`; CI run 32432348610 green; Gye member-count and feed-title typography connected to the Sori label token; screen raw TextStyle 319→317 and w800 99→98 |
| 2D Hanok tab/world boundary | merged | PR #125; main merge `e104ae213b813edd20777f0f063acf6bc9c2088c`; CI run 32433115213 green; German 320×640 at 200% Stage shortcut matrix added; approved runtime, grants, reveals, rewards, evidence, and assets unchanged |
| Phase 2 closeout | merged | PR #126; main merge `ba6036e4c11e5affbbde758534a1be33c7f88ecc`; docs-only CI path filter correctly scheduled no run |
| 3A Vocab catalog caption | merged | PR #127; main merge `1dc2172070be9b4d26f8dd166dc8cfacd384b7eb`; PR CI run 32434385023 green; locked hint renderer and grid measurement share the 12.5dp `caption` token; German 320×640 at 200% contract added; raw screen TextStyle 317→316; 130 local Deck geometry/gesture/flip/order/SRS tests green; Linux golden generation run 32434187771 changed only the medium/expanded Vocab baselines; post-merge run 32434973864 was cancelled before jobs and older main run 32433364094 was force-cancelled during bundle build with its Play upload step confirmed skipped |
| 3A Vocab recall outer UI | merged | PR #130; main merge `5159ad64fdef37faecaed2360d3e79f9716b0564`; PR current-head CI run 32436071838 green; `/vocab/recall` loading/error/empty/prompt/result share `SoriStudyFrame`; recall input uses `SoriTextField` while its editable-field key remains stable; DE/EN 320×640 at 200% input-to-result flow green; raw screen TextField 23→22; analyze clean; 144 Deck geometry/gesture/flip/order/SRS tests and 13 shared responsive tests green; post-merge main run 32436306821 cancelled before jobs, so no Play upload job was created or run |
| 3A Vocab result hierarchy | merged | PR #132; main merge `a36c63f251c86acb4c58cfd97b6bc6b5f5834de5`; PR current-head CI run 32437316213 green; `/vocab/result` pack title, result heading, metrics, and XP use the existing Sori type hierarchy; metric and animated XP visuals expose stable combined semantics; DE/EN 320×640 at 200% keep stacked stats and the final CTA reachable; raw screen TextStyle 316→310 and w800 98→95; analyze clean; 183 Deck/result/feedback/responsive tests green; post-merge main run 32437547774 cancelled during path selection and its Play job had no steps, so no upload ran |
| 3A Legacy outer UI | merged | PR #134; main merge `51409da37256cb1503474e0b1e03b720483360c3`; PR current-head CI run 32438682010 green; `/vocab/legacy` slow-play hint and listen label use existing Sori type roles; filter controls use always-visible localized form labels and Material ink ownership; DE/EN 320×640 at 200% covered; raw screen TextStyle 310→307; analyze clean; 189 Deck/result/feedback/responsive tests green; rollback route, Deck geometry, flip gate, ordering, and SRS untouched; post-merge main run 32438908214 cancelled during path selection and its Signed AAB/Play job had no steps, so no upload ran |
| 3B Grammar outer UI | merged | PR #136; main merge `8fb7b26f0909576d6e5184e0baeed442fc6c0763`; PR current-head CI run 32439883635 green; `/grammar` checkpoint and progress copy use existing Sori type roles; filter controls have always-visible localized level/type/difficulty labels and localized DE/EN difficulty choices while stored filter values remain unchanged; DE/EN 320×640 at 200% covered; raw screen TextStyle 307→302; analyze clean; 527 Grammar/course/choice/feedback/localization/accessibility/smoke/responsive/visual-layout tests green; loaders, course context, answer/scoring logic, flip/card gestures, SRS, and activity geometry untouched; post-merge main run 32440461105 cancelled during path selection and its Signed AAB/Play job had zero steps, so no upload ran |
| 3B Listening browsing UI | local green | `/listening` now presents the scenario section before its start instruction, uses the existing Sori section hierarchy, exposes an always-visible localized level label, and gives every A1–C2 filter a 48dp target; DE/EN 320×640 at 200% plus 360×400, 390×844, 720×1024, and 1280×900 covered with SafeArea insets; analyze clean; 199 shelf/route/TTS/standard-state/responsive/accessibility/smoke/typography tests green; raw screen TextStyle remains 302; scenario inventory, 15-compartment shelf mapping, scroll sheet, `/listening/play` route, and TTS availability untouched; awaiting PR/current-head CI |
| 3B–3D remaining learning flows | pending | after the Listening browsing app PR and docs closeout merge, create a fresh worktree from latest `origin/main` and audit `/listening/play` outer study hierarchy/states only; preserve player controls, audio/TTS availability, scenario dialog, and transcript reachability |
| 4A–4C tools/settings | pending | split platform/community writes from presentation |
| 5A–5C games/supporting | pending | preserve Phase 2 canvas and native boundaries |
| 6 full closeout | pending | no deployment |

## 12. Update rule

After every merge, edit this file in the next phase PR so it contains:

- the new `origin/main` base and branch;
- the phase just completed and its PR/merge/CI evidence;
- any contract decision learned from code or tests;
- the exact next small action.

Do not append narrative session history. Replace stale execution state so this
document remains short enough to be the only continuity source.
