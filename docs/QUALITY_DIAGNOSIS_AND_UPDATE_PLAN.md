# Hangul Sori Quality Diagnosis and Update Plan

Date: 2026-05-28
Scope: pre-beta tester recruitment readiness check for app quality, illustration quality, app design, content quality, and game quality.

This diagnosis is based only on the current repository state inspected locally. It does not assume unimplemented features.

## Verified Current State

- App framework: Flutter app with Material 3, custom `Sori` design tokens, light/dark themes, Firebase best-effort init, local storage, TTS, localization in German and English.
- Learning surfaces present: Hangul, vocabulary, grammar, scenarios, listening, Wordle-style syllable game, Chosung quiz, Kkeunmari word-chain game, stats, settings, onboarding.
- Scenario content: `assets/data/scenarios.json` contains 21 scenarios: A1 6, A2 7, B1 5, B2 3.
- Scenario structure: every scenario currently has an inline grammar block; 20 scenarios have 3 quests and 1 scenario has 4 quests.
- Vocabulary content: `assets/data/korean_vocab.csv` contains 526 rows: A1 211, A2 140, B1 103, B2 72.
- Grammar content: `assets/data/grammar.csv` contains 88 rows: A1 27, A2 23, B1 22, B2 16.
- Kkeunmari pool: `assets/data/kkeunmari_pool.json` contains 225 words; 114 are marked as dead ends.
- Illustration assets present: hanok backgrounds and module headers, mascot PNGs, scene backdrops for cafe/directions/hotel/market/restaurant, empty/error illustrations.
- Current verification baseline before changes: `flutter analyze` passed with no issues; `flutter test` passed.

## App Quality

### Strengths

- The app is not a prototype shell. It already has multiple real learning modes, persistent progress, SRS-style vocabulary review, stats, onboarding, localization, TTS, and Firebase/Cloud Sync scaffolding.
- The scenario player has a complete learning loop: intro, vocabulary, dialogue, grammar, quests, result, XP, stars, cultural note, and SRS review.
- The app has best-effort behavior around Firebase and ads, which lowers crash risk when optional services are unavailable.
- There is a coherent product direction: Korean learning through hanok/madang atmosphere, mascots, dancheong colors, and real-life scenarios.

### Risks

- Tester first impression can still feel uneven because premium illustrations coexist with emoji-based tiles, emoji badges, and some generic Material surfaces.
- Several modules use different header treatments. Hangul, grammar, listening, Wordle, and Chosung each have their own banner logic. This creates a less unified app feel.
- There is no broad widget/golden/screenshot coverage for major screens. The current test only verifies basic startup.
- AdMob is stubbed out. That is fine for beta if intentional, but store/revenue expectations should not imply production ads are active.
- Some copy is still German-first even in English mode, for example German explanations in vocab/grammar by design. That may be acceptable if the target learner is German-speaking, but should be stated clearly in store listing.

## Illustration Quality

### Strengths

- The app has a stronger visual premise than a generic flashcard app: hanok gates, madang backgrounds, calligraphy, porch, scene backdrops, mascots, empty/error art.
- Mascot states exist for multiple emotions, which supports a Duolingo-like emotional feedback loop.
- Scene backdrops exist for the highest-value scenario categories: cafe, directions, hotel, market, restaurant.

### Risks

- The repository currently shows uncommitted/deleted illustration changes. In particular, `assets/illustrations/hanok/study.png` is deleted while some runtime fallback code still referenced it before this update.
- Some assets are large enough to affect app size and memory if overused. Several hanok/empty illustrations are around 1-2 MB each.
- There is a filename typo-like asset: `studyroom_wating.png`. If it is intentional, keep it; if not, rename carefully and update references.
- The premium illustration direction is strongest where real PNGs are used. It weakens when screens fall back to emoji tiles.

## App Design Quality

### Strengths

- The design system is real: `SoriColors`, `SoriSurfaces`, spacing, radius, elevation, card variants, chips, buttons, progress, motion, and mascot components are centralized.
- The dancheong palette and hanji/dark surfaces give the app a distinctive Korean identity.
- Home screen already has a compelling layered background with madang art, ambient particles, and mascot motion.

### Risks

- Home modules previously used emoji as primary icons. That reads playful, but less premium and less ownable than a consistent icon/illustration system.
- Scenario intro previously led with a large emoji even when a matching scene backdrop existed. That underused one of the app's best differentiators.
- Some UI text had hardcoded German labels, e.g. `Heute`, `Tage`, which can weaken English localization.
- The app still has many rounded card surfaces. That fits the current Sori language, but Duolingo-level polish will require stronger hierarchy: fewer generic cards, more purposeful scenes, better progress rails, and clearer lesson maps.

## Content Quality

### Strengths

- Quantity is beta-worthy: 21 scenarios, 526 vocabulary items, 88 grammar entries.
- Scenario coverage spans travel, food, shopping, transportation, social conversation, business, delivery complaints, and medical consultation.
- Content is level-tagged through B2, so testers can evaluate beginner and intermediate flows.
- Scenario quests create more active recall than passive flashcards.

### Risks

- Content correctness has not been independently linguistically audited in this pass. The files are structured and loadable, but grammar nuance, naturalness, honorific/register consistency, and German translation quality still need human review.
- B2 has only 3 scenarios. That is enough to preview the direction, but not enough to feel deep for advanced testers.
- Scenario scene art is mapped by keyword to 5 available backdrops, so multiple scenarios share the same visual environment.
- The app currently offers a lot of content surfaces, but the progression model is still simple compared with Duolingo's tightly sequenced skill path.

## Game Quality

### Strengths

- Wordle is implemented with Korean syllable validation, daily/random target selection, color feedback, help, result states, haptics, stats, and mascot feedback.
- Chosung quiz has level filters, round tracking, accuracy, average time, recommendations, haptics, and a consonant pad for easier levels.
- Kkeunmari has a generated pool, rules metadata, safe starters, dead-end handling, timer, score, and turn-based loop.
- Scenario quests include several exercise engines, not a single repeated quiz type.

### Risks

- Kkeunmari pool has 225 words and 114 dead ends. That can be fun because Korean word-chain games have dead-end tactics, but it can also feel unfair unless the game teaches the rule and balances starter selection.
- Wordle and Chosung rely on vocabulary pools; they should exclude obscure or overly long items per level to avoid frustration.
- Game screens use repeated header art and some emoji/stat chips. This is serviceable, but not yet at the level of a polished, ownable game suite.
- There are no tests for game rules like duplicate syllables in Wordle, Chosung extraction, or Kkeunmari chain validity.

## Quality Target

The near-term goal should not be "copy Duolingo." The realistic target is:

- Duolingo-level clarity and delight: obvious next action, tight feedback, no dead-looking empty states, smooth progress, emotional mascots.
- Hangul Sori identity: Korean cultural atmosphere, hanok/madang spaces, dancheong palette, Korean real-life scenarios, respectful but warm tone.
- Beta trust: no placeholder-looking primary UI, no broken asset fallbacks, no localization leaks on major screens, no overflow on compact devices.

## Update Plan

### Phase 1: Pre-Beta Polish, Now

- Replace emoji-based home module cards with consistent icon tiles.
- Use localized labels for home section/streak text.
- Use scene backdrops on scenario intro screens instead of leading with a large emoji.
- Remove runtime fallback to deleted `study.png`.
- Make game text/board elements more responsive for compact screens.
- Document factual quality diagnosis and roadmap.
- Re-run `flutter analyze` and `flutter test`.

### Phase 2: Tester Build Hardening

- Add smoke/widget tests for Home, Scenario Player, Wordle, Chosung, Kkeunmari, Vocab, Grammar, and Settings.
- Add data validation scripts for scenario schema, missing assets, quest answer keys, vocab duplicates, and grammar ID references.
- Add a lightweight screenshot checklist for Android small/medium/large and iPhone-like aspect ratios.
- Add a beta feedback route or external form link from Settings.
- Make store copy explicit about target language pairing: Korean for German/English UI users, with German explanations where applicable.

### Phase 3: Duolingo-Level Learning Loop

- Build a visible lesson path instead of only module cards: daily recommendation, next locked/unlocked scenarios, review queue, and games.
- Add mastery states per skill: new, learning, review due, strong.
- Add error-aware review: failed particles/batchim/listening lines should reappear in follow-up practice.
- Add short post-lesson recap: words learned, grammar pattern, mistake focus, next recommendation.
- Add streak protection and gentle return flows.

### Phase 4: Illustration and Brand System

- Create one header/scene component for all learning modules.
- Add scenario-specific or category-specific backdrops beyond the current 5 scene images.
- Replace remaining emoji-as-primary-UI moments with icons, mascot states, or custom spot illustrations.
- Optimize large PNG assets and define max dimensions for runtime use.
- Add an asset registry document: filename, usage, dimensions, target screen, fallback.

### Phase 5: Content Quality Audit

- Human-review all 21 scenarios for natural Korean, level fit, register, cultural nuance, German/English wording, and TTS friendliness.
- Expand B2 from 3 to at least 8-10 scenarios before marketing advanced coverage.
- Add per-scenario learning objectives and prerequisite grammar.
- Add distractor quality rules for quests so wrong answers are plausible but fair.
- Add spaced review generation from scenario mistakes.

## Changes Applied In This Update

- Home module/game cards now use consistent Material icons instead of emoji as the primary visual marker.
- Home "Today" section is localized through ARB/generated localization.
- Streak label now uses the existing localized `statsDays` string.
- Scenario intro now shows the matching scene backdrop when available, with mascot/emoji fallback.
- Grammar and vocabulary header fallbacks now point to existing study illustrations instead of deleted `study.png`.
- Chosung initial-consonant prompt now scales down instead of overflowing with longer words.
- Wordle board cells now compute responsive dimensions and scale syllable text down.

## Phase 2 Hardening Applied

- Added data integrity tests for scenario pack size, scenario IDs, levels, dialogue completeness, grammar blocks, quest schemas, answer indices, CSV headers, duplicate vocabulary/grammar keys, and Kkeunmari syllable metadata.
- Added literal asset reference tests for Dart files so missing `Image.asset(...)` paths fail in tests before testers see them.
- Added Hangul utility and Kkeunmari engine tests for chosung extraction, Hangul input classification, fair starting word selection, chain validation, wrong-start detection, duplicate-word detection, and missing-word detection.
- Added screen smoke tests for Home, Vocab, Grammar, Hangul, Listening, Wordle, Chosung, Kkeunmari, Scenarios List, Scenario Player, Stats, Settings, and Onboarding on a 390x844 phone viewport.
- Fixed missing asset references found by the new tests: settings header now uses `study_scholar.png`, Kkeunmari header uses `porch.png`, and unavailable mascot poses map to existing production assets until dedicated frames exist.
- Fixed a Stats screen mobile overflow found by the new smoke tests.

## Phase 3 Increment Applied — Post-lesson Recap + Next Recommendation

Scenario player result screen now closes the learning loop instead of stopping at stars/XP:

- Added a "What you learned" recap card that summarizes words practiced, first-try quest accuracy, and the grammar focus when the scenario has an inline grammar block.
- Added a "Suggested next" card that links to the next scenario in the same level. Priority: first uncompleted, then completed-but-under-3-stars. If every scenario in the level is mastered, the card collapses to a localized "all done at this level" hint.
- Refactored `_complete` into a shared `_persistResult` step so the new "Open next" CTA reuses the exact save logic (XP, stars, completion list, SRS review) before pushing the next scenario via `pushReplacementNamed('/scenario', ...)`.
- Added DE + EN ARB keys: `scenarioRecapTitle`, `scenarioRecapWordsLine`, `scenarioRecapAccuracyLine`, `scenarioRecapGrammarLine`, `scenarioNextRecommendedTitle`, `scenarioNextRecommendedCta`, `scenarioNextRecommendedAllDone`.

This is one targeted step toward the broader Phase 3 goal (Duolingo-style loop). Remaining Phase 3 items — visible lesson path, mastery states per skill, error-aware review of failed quests, and streak protection — are still open and intentionally not bundled into this increment.

## Phase 3 Increment Applied — Streak Protection (Shields)

Streak no longer collapses on a single off day:

- `Storage.touchStreak` now accepts an injectable `now` (test-only convenience) and tracks two new persisted fields: `kl_streak_freezes` (current shield count, capped at 2) and `kl_streak_freeze_last_used` (date of the most recent auto-shield).
- Reaching every 7-day milestone grants one shield, up to the cap. Skipping exactly one day with at least one shield consumes the shield and keeps the streak alive. Skipping two or more days still resets the streak; shields are kept for the next streak instead of being burned.
- Stats hero card now shows a small `Streak shield × N` pill below the best-streak line when shields are available, with a Semantics label that reads the hint to assistive tech.
- DE + EN ARB gained `statsStreakShield` and `statsStreakShieldHint`.
- Added `Storage.resetForTesting()` (marked `@visibleForTesting`) so per-test SharedPreferences seeds aren't masked by the static `_prefs` cache. New `test/streak_freeze_test.dart` covers ten cases: first-touch, same-day no-op, next-day +1, single-skip reset (no shield), multi-day reset (with shields preserved), 7/14/21-day shield grant + cap, single-skip shielded continuation, and the day-6 + shield → reaches 7 + refill case.

Phase 3 remaining: visible lesson path, mastery states per skill, error-aware review of failed quests.

## Phase 3 Increment Applied — Error-aware Review

Scenario completion now pushes failed quest words back to the front of the SRS queue instead of treating every scenario word the same way:

- Added `QuestSpec.targetVocabKeys()` in [scenario.dart](/Users/sujinpark/Developer/ko_lernen_app/lib/models/scenario.dart) that extracts the Korean key each quest tests — `options[correctIndex]` for hoerverstehen/luecken/uebersetzen, `targetWord` for batchimDrop, empty for grammar-only quests (particlePop, schreiben).
- Scenario player now tracks failed quest indices via `_failedQuestIndices` and replaces the coarse `srsReview(v.korean, gotIt: stars >= 1)` loop with a differentiated pass: missed keys get `gotIt:false` (1-day SRS interval, surfaces tomorrow), other scenario vocab gets `gotIt:true`. Any missed key that isn't in the scenario vocab list is also persisted as `gotIt:false` so cross-scenario carry-over works.
- Added `test/error_aware_srs_test.dart` with 8 cases covering each quest type's target extraction (including out-of-range/empty edge cases) plus an integration check that the SRS interval for a missed key stays at 1 day while a non-missed key advances further.

Phase 3 remaining: visible lesson path, mastery states per skill.

## Phase 3 Increment Applied — Visible Lesson Path + Mastery States

Final Phase 3 increment. The learner now has a single-glance "where am I and what's next" view, and individual vocab cards expose their SRS-derived mastery so progress is felt at the card level too:

- Added `MasteryState` enum (`fresh` / `learning` / `reviewDue` / `strong`) and `Storage.vocabMastery(id, {now})` in [storage_service.dart](/Users/sujinpark/Developer/ko_lernen_app/lib/services/storage_service.dart). Derived purely from existing SRS data — no extra persistence. Thresholds: `reviewCount == 0` → fresh; `intervalDays ≤ 3` → learning; otherwise due-or-not-due based on `nextReviewIso` vs today.
- Vocab front card surfaces the state via a new `_MasteryChip` (icon + color-coded pill) next to the level chip in [vocab_screen.dart](/Users/sujinpark/Developer/ko_lernen_app/lib/screens/vocab_screen.dart). Grammar mastery is intentionally deferred to v1.0.1 since grammar has no SRS persistence yet.
- Scenarios list grew a `_LessonPathHeader` at the top showing overall unlocked count, per-level ★ progress chips (A1/A2/B1/B2 with lock icon on locked levels), and a `_NextRecommended` hero card that picks the first under-3-star scenario at the user's level (falling back to any unlocked scenario under 3 stars). Tapping the hero CTA navigates straight into the scenario player.
- Added 6 mastery boundary tests in `test/vocab_mastery_test.dart` covering fresh / learning (first + second review) / strong / past-due reviewDue / miss-after-strong reset-to-learning.
- ARB keys (DE/EN): `vocabMastery{Fresh,Learning,ReviewDue,Strong}` + `scenariosPath{Title,Progress,NextLabel,StartCta,AllDone,LevelProgress}`.

Verification: `flutter analyze` = 0 issues, `flutter test` = 47/47 passing.

Phase 3 complete. Remaining release-gate work (manual smoke test on real devices, asset console check) is unchanged.

## Phase 4 Applied — Header Unification + Emoji→Mascot Cleanup + Asset Registry

Phase 4 focuses on brand-system uniformity: every module screen now leads with the same banner component, the remaining emoji-as-primary spots get a proper mascot treatment, and there is finally a single source of truth for which PNG fills which slot.

- **HanokHeader migration (6 screens).** Replaced bespoke `ClipRRect(Image.asset(...))` banners — and added banners where none existed — in [vocab_screen.dart](/Users/sujinpark/Developer/ko_lernen_app/lib/screens/vocab_screen.dart), [grammar_screen.dart](/Users/sujinpark/Developer/ko_lernen_app/lib/screens/grammar_screen.dart), [hangul_screen.dart](/Users/sujinpark/Developer/ko_lernen_app/lib/screens/hangul_screen.dart), [wordle_screen.dart](/Users/sujinpark/Developer/ko_lernen_app/lib/screens/wordle_screen.dart), [chosung_quiz_screen.dart](/Users/sujinpark/Developer/ko_lernen_app/lib/screens/chosung_quiz_screen.dart), [scenarios_list_screen.dart](/Users/sujinpark/Developer/ko_lernen_app/lib/screens/scenarios_list_screen.dart). All ten module-level screens (Vocab/Grammar/Hangul/Wordle/Chosung/ScenariosList/Settings/Stats/Kkeunmari/Listening) now share the same 10:3 `HanokHeader` with built-in 단청 gradient fallback. Wordle/Chosung/Kkeunmari temporarily share `porch.png` until Phase 4b commissions unique art.
- **Emoji-as-primary cleanup (4 spots).** Stats streak hero replaced `Text('🔥', size: 36)` with `Icon(local_fire_department_rounded/_outlined)` driven by streak ≥ 1 in [stats_screen.dart](/Users/sujinpark/Developer/ko_lernen_app/lib/screens/stats_screen.dart). Three scenario-player emoji slots — next-scenario card, `_ScenarioIntroArt` outer, and Positioned scene mascot — now use `Mascot.forSpeaker(...) ?? Mascot.tiger(...)` so a guaranteed-non-null mascot widget renders and the bare-emoji fallback was deleted as dead code in [scenario_player_screen.dart](/Users/sujinpark/Developer/ko_lernen_app/lib/screens/scenario_player_screen.dart). Per-scenario list-tile emoji is intentionally kept (scenario identity, Phase 5 work).
- **Asset registry.** Added [docs/assets/REGISTRY.md](/Users/sujinpark/Developer/ko_lernen_app/docs/assets/REGISTRY.md) — one markdown table per illustration folder (`hanok/`, `mascot/`, `scenes/`, `empty/`, `error/`, `icons/`) listing filename, slot purpose, expected dimensions, consumer file:line, and fallback for every PNG referenced from `lib/`. Includes the scenario-keyword → backdrop mapping and a "adding a new asset" playbook so the next session does not have to grep.

Verification: `flutter analyze` = 0 issues, `flutter test` = 47/47 passing. No new user-facing strings (Phase 4 reused existing screen-title keys via Semantics where applicable).

Phase 4 complete. Deferred to Phase 4b/5: unique Wordle/Chosung/Kkeunmari headers, per-scenario scene art beyond the current five backdrops, replacing scenario list-tile emoji with unique illustrations.

## Release Gate

Before inviting external testers, require:

- `flutter analyze` passes.
- `flutter test` passes.
- Manual smoke test on at least one Android device/emulator and one iOS simulator/device if iOS beta is planned.
- Verify first launch, onboarding, home, one scenario completion, vocab review, grammar card, listening playback, all three games, settings language/theme, and stats.
- Confirm no missing asset exceptions in debug console.
- Confirm Play Store listing does not promise ads or cloud features beyond current behavior.
