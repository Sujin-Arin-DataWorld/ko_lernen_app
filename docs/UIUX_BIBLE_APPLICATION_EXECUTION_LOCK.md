# UI/UX Bible Application — Execution Lock

- **Version:** 1.66
- **Created:** 2026-08-21
- **Branch:** `session/uiux-bible-4b-vocab-nuance-2026-08-22`
- **Base:** `origin/main@f0e751ba3330a7ea504a280cddf37630a688c552`
- **State:** the isolated `/vocab_notebook/nuance` outer-UI unit is locally
  final-verified on app commit `43164fd591f1fd3468679740a00241a34d15b4d8`
- **Next action:** push the clean branch head containing that app commit and
  this exact lock, open one PR, use only automatic exact-head CI, and merge only
  after every required check is green

## Current State Summary

The isolated nuance worktree is based exactly on the practice merge
`f0e751ba3330a7ea504a280cddf37630a688c552`. App commit
`43164fd591f1fd3468679740a00241a34d15b4d8` replaces the route's four manual
Scaffold boundaries with `SoriStudyFrame`, keeps long question feedback and
completion content scroll-reachable, and announces feedback and final results
as live regions. Nuance alone opts into the shared `QuizChoice` idle-border and
app-owned semantic-tap parameters; their defaults preserve every other
consumer's previous visual and semantics contract. Active choices expose an
executable semantic tap and at least 3:1 boundary contrast, while revealed
choices remove the tap action. DE/EN missing, empty, question, feedback, and
completion states pass the locked five-viewport matrix, including normal and
reduced motion, exact button/selected/enabled/tap semantics, 48dp actions,
single-pick blocking, literal question order, exact scoring, and a second-round
0/3 reset proof. Six focused tests, 121 direct related/consumer tests, 835 broad
responsive/accessibility/platform tests, and the full local 4,455 tests with 14
conditional skips are green; analyze, format, and diff check are clean. Final
Specification/Protection and Standards/Accessibility reviews both report zero
remaining findings. Exact-base ratchets are raw screen `TextStyle` 214->214,
raw screen `Scaffold` 39->35, and test files 457->457; the nuance screen has zero
raw Scaffold calls. No asset, localization, token, secret, or TODO change was
added. Pack lookup, optional words override, DE/EN selection, service/lexicon
question data and ordering, option labels, correct-answer comparison,
single-pick gate, sound and haptic branches, exact score increment,
continue/index/reset behavior, route arguments, storage, SDK/platform behavior,
and approved assets remain unchanged. Studio internals are a separate later
unit. No deployment, build, signing, or store upload is authorized or claimed.

## Important Context

Start with only `AGENTS.md` and this file. Preserve authentication, account
linking, pending-operation journals, cloud backup/deletion, learning-placement
and export writes, routes, and approved assets. No deployment, store upload,
production mutation, asset generation, new token, or navigation/state rewrite
is authorized. Settings, purchase, notification, and platform-owned behavior
remain separate high-risk units.

## Immediate Next Steps

1. Push the clean current branch head and open one PR without adding a manual
   duplicate run; wait for automatic CI on the exact PR head.
2. Merge only when every required check is green, verify the Signed AAB/Play
   path ran zero steps, cancel any post-main release-capable run immediately,
   and record the exact PR, CI jobs, merge SHA, and zero-release evidence in the
   next isolated `/vocab_notebook/studio` unit.

## 1. Purpose

This is the sole restart document for applying the approved UI/UX Bible across
the app. A later session starts with only:

1. `AGENTS.md`
2. this file

The approved Bible, `docs/HANDOFF_UI_OVERHAUL_2_2026-08-14.md`, and native/game
boundary contract, `docs/UIUX_NATIVE_GAME_PHASE2_EXECUTION_LOCK.md`, remain
authority references, not startup reading. Historical handoffs are never
startup reading. Open a reference only when a disputed fact is absent from this
file and current code/tests, then add the resolved fact here before continuing.

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
| `lib/widgets/sori` Dart files | 126 | Existing system; no parallel system permitted |
| Test files | 456 | Reuse focused suites plus shared matrices |
| Raw screen `TextStyle` | 218 lexical; clean-code guard ≤217 | Must not increase; migrate by touched surface |
| Raw screen `fontSize` | 227 (guards ≤80 at w800, ≤28 at w900) | Reduce through tokens, never raise ratchets |
| Screen `BorderRadius.circular` | 87 total; 14 numeric literals (global guard ≤24) | Touched code uses radius tokens |
| Raw screen `Scaffold` calls | 43 | Many are intentional shell/immersive owners; classify before changing |
| Screen `TextOverflow.ellipsis` | 0 | Locked at zero |
| Common-appbar ellipsis | 0 | Phase 1A removed both without hiding text |
| Screen text fields | 20 | Recall and reassessment inputs use `SoriTextField`; guard locked at ≤22 |
| Raw screen progress indicators | 17 | Replace only where not canvas/inline progress |
| `AppLoading` uses | 35 | Retain as the standard full-state loader |

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
motion is disabled. Phase 3C keeps `AppError` centered when short and makes its
complete retry state scroll-reachable at 320×420 with 200% text. Their public
import locations remain stable; no duplicate replacements are allowed.

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
| 3B Listening browsing UI | merged | PR #138; main merge `63aaf130ef233c80b20ca9f79b8df5741383579c`; PR current-head CI run 32441547719 green; `/listening` now presents the scenario section before its start instruction, uses the existing Sori section hierarchy, exposes an always-visible localized level label, and gives every A1–C2 filter a 48dp target; DE/EN 320×640 at 200% plus 360×400, 390×844, 720×1024, and 1280×900 covered with SafeArea insets; analyze clean; 199 shelf/route/TTS/standard-state/responsive/accessibility/smoke/typography tests green; raw screen TextStyle remains 302; scenario inventory, 15-compartment shelf mapping, scroll sheet, `/listening/play` route, and TTS availability untouched; post-merge main run 32441770710 cancelled during path selection and its Signed AAB/Play job had zero steps, so no upload ran |
| 3B Listening player outer UI | merged | PR #140; main merge `c5a71670f834e90dc6ddf0e2e0afad65e5f56d3a`; PR current-head CI run 32442826058 green; `/listening/play` gives both visible replay targets explicit localized button semantics and a 48dp minimum target while retaining the existing Sori study frame/feed hierarchy; DE/EN completion state covered at 320×640 at 200%, 360×400, 390×844, 720×1024, and 1280×900 with SafeArea insets; completion still persists the scenario id and 40 XP; analyze clean; 221 shelf/route/TTS/feedback/study-responsive/accessibility/smoke/typography tests green; raw screen TextStyle remains 302; route arguments, dialog order, next/previous/flip/like/bookmark/share, TTS voice/speed, completion calculation, feedback, and transcript reachability unchanged; post-merge main run 32443029469 cancelled during path selection and its Signed AAB/Play job had zero steps, so no upload ran |
| 3B Hangul outer UI | merged | PR #142; main merge `d4ca641fdc5573ce017871f3788383be19ccc7c9`; PR current-head CI run 32444911268 green; `/hangul` overview uses the existing semantic Sori section hierarchy; syllable composition remains unchanged while narrow/200% layouts wrap without clipping; card modes keep complete DE/EN labels, 48dp targets, and short-height scroll reachability; single-character deck previews scale within both card axes; card counter uses the existing meta role; raw screen TextStyle 302→301; DE/EN 320×640 at 200%, 360×400, 390×844, 720×1024, and 1280×900 covered; analyze clean; 305 Hangul composition/data/locale/gesture/prefetch/stroke/writing/feedback/responsive/accessibility/smoke/typography tests green; composition, item pools/order, card judgments, writing canvas geometry, stroke matching/order, text prefetch, audio/pronunciation, completion gates, XP, assets, and routes unchanged; post-merge main run 32445233372 cancelled during checkout and its Signed AAB/Play job had zero steps, so no upload ran |
| 3B Cloze outer UI | merged | PR #144; main merge `c3fc9fbe7cc5a82dc493458c3cf6cd95989d90a1`; PR exact-current-head CI run 32447455346 green with 4,321 tests passed and 2 skipped; `/cloze` now names the level filter in DE/EN, gives all level choices and the localized pronunciation action 48dp targets, and renders Korean/gloss text through the existing Sori type roles; long production prompts scroll inside their owned area instead of overflowing while choices remain reachable; the shared prompt's `/daily` companion layout received the same overflow boundary; DE/EN 320×640 at 200%, 360×400, 390×844, 720×1024, and 1280×900 covered; analyze clean; 263 focused Cloze/data/retry/first-attempt score/course evidence/feedback/shared daily/responsive/accessibility/smoke/typography/localization tests green; full CI exposed one previously merged Hangul width literal, replaced with the existing `SoriAdaptiveWidth.criticalActionRow` constant without changing its 280dp threshold, with the width guard plus Cloze and study-responsive battery 117/117 green; raw screen TextStyle remains 301; item data/order, answer checking, retry timing, first-attempt scoring, SRS, course evidence, completion, XP/rewards, daily seed, routes, and approved assets unchanged; post-merge main run 32447991802 cancelled during comparison-history fetch and its Signed AAB/Play job had zero steps, so no upload ran |
| 3B Daily outer UI | merged | PR #146; main merge `75cf6b9dc41757ad51a852416b08cee5ba934fc9`; PR exact-current-head CI run 32449029136 green with 990 tests passed and the asset pipeline gate green; `/daily` now carries round progress and score in the shared Study eyebrow instead of two decorative chips, presents already-completed practice mode as a complete semantic Sori card, routes empty content to the shared Sori empty state instead of a misleading 0/0 result, gives the localized close action an explicit 48dp target, and uses the existing meta type role for its instruction; DE/EN 320×640 at 200%, 360×400, 390×844, 720×1024, and 1280×900 covered; raw screen TextStyle 301→300; analyze clean; 962 focused Daily seed/level-cap/streak/retry/first-attempt score/one-time bonus/feedback/shared prompt/study-responsive/short-height/accessibility/smoke/typography tests green; date seed, level cap, item/order/options, answer checking, retry timing, SRS, already-done detection, completion, XP/streak/best/feedback writes, routes, and approved assets unchanged; post-merge main run 32449292843 cancelled during checkout and its Signed AAB/Play job had zero steps, so no upload ran |
| 3B Calligraphy route outer UI | merged | PR #148; main merge `4e4fffef9cd9f4a91c19e71a63396b0ad456bc5e`; PR exact-current-head CI run 32450221928 green with 1,367 tests passed and the asset pipeline gate green; `/calligraphy` now uses the shared Standard-page category, headline, and localized guide description while Home/Hanok keep the same self-owned Sori sheet intro; route and sheet share the same resolved daily character and learning widget; all six screen-local TextStyle constructors moved to the existing Sori UI/Korean-content roles; reduced motion now unlocks the guide completion action after the build frame instead of issuing a parent setState during build; DE/EN 320×640 at 200%, 360×400, 390×844, 720×1024, and 1280×900 plus fallback content covered; raw screen TextStyle 300→294 and `daily_char_sheet.dart` now has zero raw constructors; analyze clean; 1,083 Calligraphy route/storage/feedback/StrokeCanvas/Hangul writing and swipe/Hanok sheet/standard-page/responsive/short-height/accessibility/smoke/typography tests green; daily character selection, stroke data/geometry/order/replay, TTS, finish gate, feedback completion, calligraphy date persistence/export, sheet ownership, routes, and approved assets unchanged; post-merge main run 32450505667 cancelled during checkout and its Signed AAB/Play job had zero steps, so no upload ran |
| 3B Pronunciation outer UI | merged | PR #150; main merge `392bbd7294f2ee25090bc3c7d45de447b584caca`; PR exact-current-head CI run 32451600340 green with 4,360 tests passed, 2 skipped, and the asset pipeline gate green; `/pronunciation` now uses the existing Standard-page header and Sori Korean/body/meta/label/numeral type roles; capture and assessment expose distinct localized states with an app-owned live score panel; DE/EN 320×640 at 200%, 360×400, 390×844, 720×1024, and 1280×900 with safe insets covered; raw screen TextStyle 294→287; analyze clean; 884 focused/local shared tests green; phrase loading and cumulative level selection, consent before OS permission, microphone SDK ownership, PCM limits and 10-second capture, assessment identity/reference, 80-point pass threshold, duplicate prevention, progress writes, TTS, routes, and approved assets unchanged; post-merge main run 32452244705 cancelled during path classification and its Signed AAB/Play job had zero steps, so no upload ran |
| 3B Satz outer UI | merged | PR #152; main merge `3afc85b57886ba20e397ec393cc7db811907835b`; PR exact-current-head CI run 32453622116 green with 1,236 tests passed and the asset pipeline gate green; `/satz_arcade` carries round progress plus score in the shared Study eyebrow, exposes a localized 48dp close action and a visible localized level-filter name, gives every level chip a 48dp complete-text contract, and routes instructions and inline diagnostics through existing Sori type roles; the existing `SoriWordTile` 48dp contract is restored at 320dp by retaining the 3/4-column grid and applying a minimum row extent; DE/EN 320×640 at 200%, 360×400, 390×844, 720×1024, and 1280×900 covered; analyze clean; 106 focused Satz/data/order/diagnosis/mission/evidence/feedback tests and 924 shared responsive/short-height/accessibility/smoke/typography/localization tests green; raw screen TextStyle 287→285; course-scoped catalog filtering, initial mission item, tile identity/order and tap gestures, punctuation/order/particle/count diagnosis, retry/reveal timing, SRS, exact activity evidence, score/XP/best, feedback completion, TTS, routes, and approved assets unchanged; post-merge main run 32453946754 cancelled before any job step and its Signed AAB/Play job had zero steps, so no build, signing, or upload ran |
| 3C Path outer UI | merged | PR #154; main merge `f9bad3458a0b0b27735f32557dd741d8b4384ad9`; PR exact-current-head CI run 32456183621 green with 4,388 tests passed, 2 skipped, and the asset pipeline gate green; `/path` disables its jump action when no legacy target exists, reveals a hidden legacy target before jump/route-focus scrolling, and anchors the first-visit coach to the canonical current course step when present; existing Sori roles replace four local TextStyle constructors and one local radius; the DE/EN coach copy now names the highlighted current step; DE/EN 320×640 at 200%, 360×400, 390×844, 720×1024, and 1280×900 covered; 15 new path hierarchy/route/coach/type tests, 118 focused course graph/exact evidence/read-only/76-pack tap/Hanok tests, and 825 shared responsive/short-height/accessibility/smoke/typography/localization tests green locally; analyze and diff check clean; exact-base ratchets raw screen TextStyle 285→281 and screen BorderRadius.circular 95→94; added assets, TODO markers, and secret patterns zero; course graph, unlock rules, selected/visible level derivation, course/pack progress, evidence writes, mission/pack navigation, route arguments, and approved assets unchanged; post-merge main run 32456860907 cancelled during checkout and its Signed AAB/Play job had zero steps, so no build, signing, or upload ran |
| 3C Course mission outer UI | merged | PR #156; main merge `4ae8d9933d302fc5d4220a7e46f30b3bdd74501a`; PR exact-current-head CI run 32458331827 green with 4,390 tests passed, 2 skipped, and the asset pipeline gate green; `/course/mission` uses the canonical Sori page header and one primary action, while canonically completed historical missions use a localized read-only standard completion state; active graph-derived step order and completion/evidence behavior are unchanged; DE/EN 320×640 at 200% with safe insets, 360×400, 390×844, 720×1024, and 1280×900 covered; 26 focused and 807 shared tests green locally; analyze and diff check clean; exact-base ratchets raw screen TextStyle 281→281 and screen BorderRadius.circular 94→94; added assets, TODO markers, and secret patterns zero; mission plan, routes and arguments, current/read-only state, evidence writes, and approved assets unchanged; post-merge main run 32459083742 cancelled while queued and its Signed AAB/Play job had zero steps, so no build, signing, or upload ran |
| 3C Course reassessment outer UI | merged | PR #158; main merge `a7be4e6387db9a2d482d27b56fc5719eb85b6c91`; PR exact-current-head CI run 32462887664 green with 902 selected tests passed and the asset pipeline gate green; `/course/reassessment` now uses the canonical Standard-page header, 600dp form clamp, Sori type hierarchy, progress bar, and shared text fields; loading and error states use the same width contract and remain scroll-reachable at 320×400 with 200% text; project review, structured inputs, prerequisite, oral fail-closed, result, and completion states have direct narrow/200% coverage; DE/EN 320×640 at 200%, 360×400, 390×844, 720×1024, and 1280×900 covered; 14 focused tests, full local 4,382 tests with 14 conditional skips, analyze, format, and diff check green; exact-base ratchets raw screen TextStyle 281→255, raw screen TextField 22→20, and raw screen LinearProgressIndicator 9→8; added assets, TODO markers, and secret patterns zero; typed arguments, exact productive-evidence eligibility and completion, mastery and current course position, writes, navigation, read-only behavior, and approved assets unchanged; post-merge main run 32463213316 cancelled during checkout and its Signed AAB/Play job had zero steps, so no build, signing, or upload ran |
| 3C Scenarios list outer UI | merged | PR #160; main merge `189c515089dc775f54c8477353ac060818c9813e`; PR exact-current-head CI run 32465921674 green with 4,403 tests passed, 2 skipped, and the asset pipeline gate green; `/scenarios` keeps its approved 16:9 shelf art while residual local card/type styling moves to existing Sori roles, open and locked cards expose explicit localized button semantics, and the open card uses the existing route callback; DE/EN 320×640 at 200%, 360×400, 390×844 at 130%, 720×1024 at 130%, and 1280×900 at 130% covered; 65 focused related tests, full local 4,391 tests with 14 conditional skips, analyze, format, and diff check green; Standards and Specification review axes both reported zero remaining findings after three review fixes; exact-base ratchets raw screen TextStyle 255→246 and `scenarios_list_screen.dart` raw TextStyle 10→1; added assets, TODO markers, and secret patterns zero; all six A1–C2 shards and 392 scenarios, availability/level locks, stars, recommendation, `madang(light).png`, `hanok_jongga.mp4`, route arguments, player flow, scenario evidence, audio, quest rules, writes, and approved assets unchanged; post-merge main run 32466724845 cancelled during checkout and its Signed AAB/Play job 96724843027 had zero steps, so no build, signing, or upload ran |
| 3C Scenario player outer UI | merged | PR #162; main merge `f9575c1a9492bffdd2a5ac7cdbd1d5b9915d3518`; PR exact-current-head CI run 32471398286 green with 1,550 selected tests passed and the asset pipeline gate green; `/scenario` loading, error, same-id retry, and close states use the canonical `SoriStudyFrame`, `AppLoading`, and scroll-reachable `AppError`; compact wordbook and vocabulary/dialog audio actions keep localized semantics and 48dp targets; delayed loads cannot start `Analytics.lessonStarted` or `QuestAbandonTracker` after exit and tracking is admitted at most once per player instance; existing `textMuted` and Sori type roles are used with no new token; DE/EN changed states are covered directly at 320×640 at 200%, 360×400, 390×844 at 130%, 720×1024 at 130%, and 1280×900 at 130%; 150 focused scenario/accessibility/onboarding/SRS tests, full local 4,405 tests with 14 conditional skips, analyze, format, and diff check green; Standards and Specification final review axes both reported zero remaining findings after closing pending-load SDK, duplicate-tracking, token, brace, and matrix gaps; exact-base ratchets raw screen TextStyle 246→243 and `scenario_player_screen.dart` raw TextStyle 3→0; added assets, TODO markers, and secret patterns zero; scenario id and route arguments, roleplay/quest canvas and dialog order, audio/TTS behavior, score, stars, XP, feedback, exact course evidence and writes, onboarding five-quest completion, quest rules, premium gates, SDK boundaries, and approved assets unchanged; post-merge main run 32471858735 cancelled during checkout and its Signed AAB/Play job 96740168745 had zero steps, so no build, signing, or upload ran |
| 3C Smalltalk outer UI | merged | PR #164; main merge `8368aad8af7c3a41b2225d61f46d76056ff7501e`; PR exact-current-head CI run 32474977534 green and asset pipeline gate green; `/smalltalk` loading, retryable error, empty, category, prompt, guide, reply, and audio states use the existing Sori study/state/type/control system; category and level actions keep complete labels and 48dp targets, the selected category has a check cue, zero-count categories expose explicit disabled visual and semantic states, and inline speech actions have localized labels and 48dp targets; DE/EN 320×640 at 200%, 360×400, 390×844 at 130%, 720×1024 at 130%, and 1280×900 at 130% covered; 537 focused Smalltalk/course/TTS/wordbook/responsive tests and full local 4,409 tests with 14 conditional skips green; analyze, format, and diff check clean; Standards and Specification final review axes both reported zero remaining findings after resolving selector action semantics and disabled-category cues; exact-base ratchets raw screen TextStyle 243→235, `smalltalk_screen.dart` raw TextStyle 8→0, and `FontWeight.w800` 86→85; added assets, TODO markers, and secret patterns zero; direct browsing remains history-only, course eligibility remains bound to an active typed mission and exact `assess` evidence, and phrase/reply data, CEFR/category behavior, speech-style checks, TTS/content behavior, writes, SDK boundaries, route arguments, and approved assets remain unchanged; post-merge main run 32475305857 was cancelled during checkout and its Signed AAB/Play job 96750336901 had zero steps, so no build, signing, or upload ran |
| 3D Practice hub outer UI | merged | PR #166; main merge `05d536bfd9964532c56fdfd2c927746607eb25d5`; PR exact-current-head CI run 32478194125 green with Analyze & Build plus asset pipeline gates green; `/practice` now presents review as its only `FeaturedModuleCard` and uses the existing actionable empty-review ARB copy when nothing is due, while every expanded activity remains a secondary `ModuleCard`; narrow or 200% layouts stack complete activity cards and wide layouts retain the established paired grid; purpose sheets use existing Sori type roles, chevrons, and a local transparent Material ink owner; DE/EN 320×640 at 200%, 360×400, 390×844 at 130%, 720×1024 at 130%, and 1280×900 at 130% covered; six focused Practice tests and 889 shared route/catalog/evidence/responsive/accessibility/localization tests green locally; full local 4,413 tests with 14 conditional skips, analyze, format, and diff check green; Standards and Specification final review axes both reported zero remaining findings after resolving the expanded multi-primary hierarchy; exact-base ratchets raw screen TextStyle 235→235 and `FontWeight.w800` 85→85; added assets, TODO markers, and secret patterns zero; all 21 activity destinations keep their order, routes, arguments, and navigation, while course/reward evidence, writes, SDK/native/game boundaries, and approved assets remain unchanged; post-merge main run 32478523812 was cancelled during required-check selection and its Signed AAB/Play job 96759858191 had zero steps, so no build, signing, or upload ran |
| 3D Quests outer UI | merged | App commits `8d4039fa85686b7ce43d5fe402e3f12b7c5a35fb`, `888861ec367ef227a96c0866f65cd2c57d0ca176`, and `b5833ef47fa2df44dca6fe4ca08af0c69078449f`; PR #168; main merge `3de9cb10ce2d46be9c7d33be19b317da7592f981`; PR exact-current-head CI run 32483615356 green with 4,429 tests passed, 2 skipped, release web build and asset pipeline gate green; `/quests` uses the shared Sori progress bar for quest and summary progress, existing Sori type roles in locked/completion states, localized DE/EN plural progress summaries, and actual localized decoration names for reward semantics; loading, retry, empty, progress/reward semantics, and the completion dialog are directly covered; DE/EN 320×640 at 200%, 360×400, 390×844 at 130%, 720×1024 at 130%, and 1280×900 at 130% covered; final-head analyze, format, diff check, and seven changed-path regression tests green, with 146 focused quest/localization/semantics/game-boundary tests green after the first review fix; the pre-final-review local full suite had 4,416 passes and 14 conditional skips, while exact-final-head full proof is the CI result above; Standards and Specification final review axes both reported zero remaining findings; exact-base ratchets raw screen TextStyle 235→232, raw progress indicators 19→17, and `FontWeight.w800` 50→49; test files 452→453; added assets, TODO markers, and secret patterns zero; quest tracking, reward/evidence writes, routes and arguments, six game-owned engines, timing, hitboxes, canvas geometry, SDK/native boundaries, and approved assets unchanged; post-merge main run 32484539000 was cancelled during checkout and its Signed AAB/Play job 96778071109 had zero steps, so no build, signing, or upload ran |
| 3D Word-web outer UI | merged | App commit `f458d1f17b369cb5cab1665f87f3499ef6fdf52f`; PR #170; main merge `29e08680129fcd2ee9377e8859f8627246605a5d`; PR exact-current-head CI run 32488135405 green with Analyze & Build and asset pipeline gates green; `/word_web` learned/level filters now use the existing Sori choice contract with complete labels, 48dp targets, button/selected semantics, and a visible check cue, while hub, neighbor, expression, and example pronunciation actions use localized labels and 48dp targets; DE/EN 320×640 at 200%, 360×400, 390×844 at 130%, 720×1024 at 130%, and 1280×900 at 130% covered; 472 focused/shared responsive/accessibility/typography tests and full local 4,419 tests with 14 conditional skips green; analyze, format, and diff check clean; Standards and Specification final review axes both reported zero findings; exact-base ratchets raw screen TextStyle 232→232, raw progress indicators 17→17, `FontWeight.w800` 49→49, and test files 453→454; added assets, TODO markers, and secret patterns zero; word-relation data, learned/course filtering, study/quiz transitions and scoring, routes and arguments, learning/evidence behavior, SDK/native boundaries, and approved assets unchanged; post-merge main run 32488456766 cancelled after path selection and its Signed AAB/Play job 96790423784 had zero steps, so no build, signing, or upload ran |
| 3D Sarangbang outer UI | merged | App commits `d3233b7f875572f8ff124719c2cd210cd21e89d4` and `661fba6600dc12beac9cfe37a9cc8b4152a54eaa`; PR #172; main merge `c6c864f3fb14ed3dfaaffd7caf12fedb2791ca2e`; PR exact-current-head CI run 32491286517 green with Analyze & Build and asset pipeline gates green; `/sarangbang` loading and full-read failure use the shared app states, partial Today data keeps the saved room and receipt visible while stale recommendations fail closed, and an existing saved `/review` remains the only safe learning action beside retry; unavailable copy distinguishes offline, remote-service, and local-data reasons using existing localized Sori contracts; DE/EN 320×640 at 200%, 360×400, 390×844 at 130%, 720×1024 at 130%, and 1280×900 at 130% directly cover the changed unavailable card and actions; 12 focused Sarangbang tests, 397 shared Today/responsive/accessibility/typography/smoke tests, and full local 4,423 tests with 14 conditional skips green; analyze, format, and diff check clean; Standards and Specification final review axes both reported zero remaining findings after preserving saved review and extending the unavailable-state matrix; exact-base ratchets raw screen TextStyle 232→232, raw screen LinearProgressIndicator 6→6, `FontWeight.w800` 49→49, and test files 454→454; added assets, TODO markers, and secret patterns zero; custom-room composition, room/canvas geometry, `/sarangbang/furnish`, recommendations/course evidence, receipt and reward writes, routes and arguments, SDK/native/game boundaries, and approved assets unchanged; post-merge main run 32491635244 cancelled during checkout and its Signed AAB/Play job 96800525143 had zero steps, so no build, signing, or upload ran |
| 4A Stats outer UI | merged | App commit `56be6108607d412c64c3bde8b9cf23228b415e8a`; PR #174; main merge `70df05a5ec0a7de2b2fb9ed8a62bd9626fbd6a26`; PR exact-current-head CI run 32506434904 green with 4,440 tests passed, 2 skipped, and the asset pipeline gate green; `/stats` keeps its existing empty/populated hierarchy and exact aggregation/chart-completion mapping while weekday labels, today mapping, and per-day semantics are localized in DE/EN; the empty CTA still routes to `/scenarios`; protected XP, level, streak, scenario, Vocab, Chosung, and Wordle values are asserted exactly and rendering is proven storage-read-only; DE/EN 320×640 at 200%, 360×400, 390×844 at 130%, 720×1024 at 130%, and 1280×900 at 130% covered; 5 focused tests and full local 4,428 tests with 14 conditional skips green; analyze and format clean; Standards and Specification final review axes both reported zero findings; raw screen TextStyle remains 232 and test files 454→455; no new assets, tokens, secrets, or TODO markers; routes, writes, progress/stat aggregation, chart data, learning/score/evidence behavior, SDK/native/game boundaries, and approved assets unchanged; post-merge main run 32507386111 was cancelled during checkout and its Signed AAB/Play job had zero steps, so no build, signing, or upload ran |
| 4A Profile outer UI | merged | App commit `9d43621a2d49ce44c27e5f3ccb97f421d599172b`; PR #175; main merge `3d9ad7200a0c2fa97711c5acf333b4735fe19352`; PR exact-current-head CI run 32509856558 green with 933 selected tests and the asset pipeline gate green; `/profile` keeps its existing identity, editable-learning, learner-space, durable-account, and progress hierarchy while the app-bar settings action exposes the existing localized DE/EN label and an explicit 48dp target instead of the measured 40dp target; the action still routes exactly to `/settings`; DE/EN 320×640 at 200%, 360×400, 390×844 at 130%, 720×1024 at 130%, and 1280×900 at 130% covered; 62 focused Profile/account-transition/account-hardening tests, 64 typography/accessibility guards, the shared Profile 200% test, and full local 4,430 tests with 14 conditional skips green; analyze, format, and diff check clean; Standards and Specification final review axes reported zero remaining findings after correcting the lock's exact next action; raw screen TextStyle remained 232, `profile_screen.dart` had zero raw TextStyle and BorderRadius constructors, and test files remained 455; no new assets, localization keys, tokens, secrets, or TODO markers; authentication, provider state, account-link confirmation, pending-operation journals, cloud backup/deletion locks, sign-out, placement/export writes, routes, SDK/platform behavior, and approved assets unchanged; post-merge main run 32510668938 was cancelled during checkout and its Signed AAB/Play job 96860818426 had zero steps, so no build, signing, or upload ran |
| 4A Settings outer UI | merged | App commit `ddc1d7b970595cd5a5a5405b76bb552a654b6891`; PR #176; main merge `2f1c183e035cff6d29b622dbaf0ecbdc6ebb9ac5`; `/settings` keeps every existing account, pending-journal, cloud backup/deletion, consent, notification, locale, audio, companion, reset, and platform operation while its 14 local TextStyle constructors and five local numeric radii converge on existing `SoriTextTheme` and `SoriRadius` roles; data-source card headers and license notes reflow without truncation, and the full Settings list plus opened data-source sheet, long DeepL license, and close action are directly locked in both DE and EN at every 320×640 at 200%, 360×400, 390×844 at 130%, 720×1024 at 130%, and 1280×900 at 130% viewport; first exact-head CI run 32516080404 passed path selection, analyze, 1,121 tests, and the asset gate but exposed only three Settings Linux-golden diffs: compact 0.43%, medium 0.22%, and expanded 0.12%; downloaded expected, actual, isolated-diff, and masked-diff artifacts showed only four section-hairline caps changed after removing `BorderRadius.circular(1)`, so the corrected diff preserves the existing pixels with `SoriRadius.brPill` instead of changing golden baselines; corrected exact-head CI run 32518721442 passed Analyze & Build, 1,124 tests, and the asset pipeline gate, while its Signed AAB/Play job 96889450602 was skipped with zero steps; the correction had 582 combined changed-path/shared tests and exact-diff full local 4,431 tests with 14 conditional skips green, with analyze, format, and diff check clean; first-review findings for sheet reflow, the 10-combination matrix, card-title weight, and commit-state accuracy remain resolved, and final exact corrected-head Standards and Specification reviews both reported zero remaining findings; cumulative guard ratchets `FontWeight.w800` 85→80, clean-code raw screen TextStyle 235→217, and numeric-literal BorderRadius 33→24; `settings_screen.dart` has zero raw TextStyle and BorderRadius.circular constructors and test files remain 455; no new assets, localization keys, tokens, secrets, or TODO markers; routes, writes, account and purchase behavior, notification scheduling and permissions, consent, locale, SDK/platform boundaries, and approved assets unchanged; post-merge main run 32519899612 was cancelled during checkout and its Signed AAB/Play job 96889736168 had zero steps, so no build, signing, or upload ran |
| 4A Paywall outer UI | merged | App commits `710cf7ea3a775be4a9ca18fdf0be095ebbda06e4` and `941433efb809968493f923f8e38005d154ba08fd`; documentation commit `143e34ab458587498b4390ffcf083ca87fd367d8`; PR #177; main merge `462b84dd6f1a04932312b70c806c0dd88d3de85a`; PR exact-current-head CI run 32522867344 green for Analyze & Build and the asset pipeline gate, while Signed AAB/Play job 96899365718 was skipped with zero steps; `/paywall` disables its purchase action until the Offering resolves instead of surfacing a premature unavailable error, converts a load failure to the existing localized unavailable state, keeps restore independent and usable during Offering loading, and disables purchase, restore, and close together during a store operation; the price loader and close action expose existing localized semantics, close keeps an explicit 48dp target, and its icon uses distinct enabled/disabled foreground colors; ordinary layouts retain fixed actions, while short-height or large-text layouts put the full offer in one scroll surface; DE/EN 320×640 at 200%, 360×400, 390×844 at 130%, 720×1024 at 130%, and 1280×900 at 130% directly cover complete, hit-testable actions; six focused Paywall tests, 830 combined focused purchase/restore/SDK-boundary/responsive/short-height/accessibility/typography/smoke tests, and full local 4,437 tests with 14 conditional skips green on the exact corrected app head; final Standards and Specification review axes reported zero remaining findings; analyze, format, and diff check clean; exact-base ratchets raw screen TextStyle 218→218, numeric-literal BorderRadius 14→14, raw screen progress indicators 17→17, and test files 455→456; `paywall_screen.dart` has zero raw TextStyle and BorderRadius.circular constructors; no new assets, localization keys, tokens, secrets, or TODO markers; RevenueCat service calls, purchase, restore, entitlement, analytics, routes and arguments, SDK/platform boundaries, and approved assets unchanged; post-merge main run 32523230826 was cancelled during checkout and its Signed AAB/Play job 96899861885 had zero steps, so no build, signing, or upload ran |
| 4B Book/notebook capture outer UI | merged | App commit `aa096a2b17d834c1d3d4f74d33fec4871aa72b3b`; PR #178; main merge `4754f84605a89a8ec740b87b852ef341b41b20bd`; automatic exact-head CI run 32525701965 green for Analyze & Build job 96907250581 and asset pipeline job 96907250511; Signed AAB/Play job 96907746345 skipped with zero steps; shared `/book` and `/vocab_notebook` hero and error presentation use existing Sori type/state roles, the gallery action keeps the default outlined contrast path beside one primary camera action, and inline capture failure is announced as a live region; DE/EN in both modes directly cover 320x640 at 200%, 360x400, 390x844 at 130%, 720x1024 at 130%, and 1280x900 at 130% with scroll reachability, hit testing, and button semantics; six focused tests, 146 book/recovery/platform tests, 819 shared responsive/accessibility/typography/smoke tests, and full local 4,438 tests with 14 conditional skips green; analyze, format, and diff check clean; final Specification/Protection and Standards/Accessibility reviews both reported zero remaining findings; exact-base ratchets raw screen `TextStyle` 218->215, numeric-literal screen radii 14->14, raw screen progress indicators 17->17, and test files 456->456; no new assets, localization keys, tokens, secrets, or TODO markers; camera permission, picker/crop recovery, media leases, image quality, OCR, quota, preview arguments, routes, storage, privacy, SDK/platform behavior, and approved assets unchanged; post-main run 32526140385 cancelled before any job was created, so no build, signing, or upload ran |
| 4B Vocab-notebook result outer UI | merged | App commit `316bf4147dccbdbecbfab334155ba8d9cdc4b218`; documentation commit `28bb2d434970cf94aac6ce35d3844119d0ff32b8`; PR #179; main merge `00060aef6b501e5a3c1e7cc3dee139f2c22ee375`; automatic exact-head CI run 32528928325 green for Analyze & Build job 96916922496 and asset pipeline job 96916922497; Signed AAB/Play job 96918302998 skipped with zero steps; empty and populated results use `SoriStandardFrame`, the pack-name field uses `SoriTextField`, result count is a live region, short/large-text actions remain scroll-reachable, and each 48dp keep/drop control exposes localized button, selected, and executable tap semantics with its non-color cue; Hanja text uses the existing light-surface contrast token; DE/EN locked viewport matrix covered; five focused tests, 69 protection tests, and full local 4,445 tests with 14 conditional skips green; analyze, format, and diff check clean; final Specification/Protection and Standards/Accessibility reviews both reported zero findings; exact-base ratchets raw screen `TextStyle` 215->214, raw screen `Scaffold` 43->41, and test files 456->456; no new assets, localization keys, tokens, secrets, or TODO markers; OCR parsing, pair/Hanja/nuance data, decisions, custom-pack behavior, routes and arguments, storage, SDK/platform behavior, and approved assets unchanged; post-main run 32529466374 cancelled while pending and completed with no jobs, so no build, signing, or upload ran |
| 4B Vocab-notebook practice outer UI | merged | App commit `211ebec0ef7b98b99afa70aeec17e63dc27fb55e`; documentation commits `656fb88df9e683aea3201ac6fc04abc2189207f2`, `797567d91666e99b6b31f01905696736775221ff`, and `08a05264ff66a14afbe8e141e543a9acda111273`; PR #180; main merge `f0e751ba3330a7ea504a280cddf37630a688c552`; automatic exact-head CI run 32531327324 green for Analyze & Build job 96923826143 and asset pipeline job 96923826253; Signed AAB/Play job 96924265065 skipped with zero steps; missing and populated states use the standard frame/page, keep one filled primary and the existing outlined/ghost hierarchy, and use the default contrast-safe outlined path for Typing and Quiz; DE/EN locked viewport matrix directly covers scroll reachability, 48dp targets, variants, and actual label/button/enabled semantics; five focused tests lock missing packs, exact 0/1/2/3/4-word and nuance enablement, all eight routes and arguments, and post-return refresh; 68 related protection tests, 834 broad tests, and full local 4,450 tests with 14 conditional skips green; analyze, format, and diff check clean; final Specification/Protection and Standards/Accessibility reviews both zero; exact-base ratchets raw screen `TextStyle` 214->214, raw screen `Scaffold` 41->39, and test files 456->457; no new assets, localization keys, tokens, secrets, or TODO markers; lookup, counts, routes/arguments, refresh, writes, study/game logic, scores/evidence, SDK/platform behavior, and approved assets unchanged; post-main run 32531620540 cancelled immediately and every release-capable job, including Signed AAB/Play 96924655782, had zero steps, so no build, signing, deployment, or upload ran |
| 4B Vocab-notebook nuance outer UI | locally final-verified | App commit `43164fd591f1fd3468679740a00241a34d15b4d8` from exact base `f0e751ba3330a7ea504a280cddf37630a688c552`; four raw Scaffolds replaced by the shared study frame; only nuance opts into the shared choice's 3:1 idle boundary and executable app-owned semantic tap while defaults for other consumers remain unchanged; missing, empty, question, feedback, and completion states are scroll-reachable and directly locked in DE/EN at 320x640 at 200%, 360x400, 390x844 at 130%, 720x1024 at 130%, and 1280x900 at 130%; live feedback/result semantics, active/revealed tap actions, 48dp actions, normal/reduced motion, literal service question order, other-option blocking, exact score, and second-round reset are covered; six focused, 121 direct related/consumer, 835 broad, and full local 4,455 tests with 14 conditional skips green; analyze, format, and diff check clean; both final review axes zero; raw screen TextStyle 214->214, Scaffold 39->35, test files 457->457, added assets/localization/tokens/secrets/TODO zero; pack/words source, language selection, service/lexicon questions and order, labels, answers, one-pick gate, score, effects, continue/reset, arguments, storage, SDK/platform behavior, and approved assets protected; PR/CI/merge not yet claimed |
| 4B remaining notebook/bookshelf/custom-pack editing | pending | split nuance from studio, preview/analysis, bookshelf, and local editing |
| 4C tools/community | pending | split platform/community writes from presentation |
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
