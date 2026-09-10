# Korean learning and Hanok growth implementation plan

> **For agentic workers:** Use superpowers:subagent-driven-development for independently owned tasks and a final whole-branch review. The user has authorized continuous implementation, commit, push and merge; no further execution-choice prompt is required.

**Goal:** Complete the approved seven-screen learning-to-Hanok experience, choose gestures, private Site and verified main integration.

**Architecture:** Keep the current onboarding coordinator and its persisted contracts. Implement the demonstration within presentation widgets, reuse the existing character-media lifecycle boundary, and use the same content/visual thesis in the private Site.

**Tech Stack:** Flutter/Dart, ARB DE/EN, existing image/video assets, animated WebP media where qualified, React/Vinext Sites, widget tests and browser/device verification.

**Spec:** `docs/superpowers/specs/2026-09-10-onboarding-learning-hanok-design.md`

## Global constraints

- Onboarding demonstration writes no XP, items, mastery or permanent Hanok grants.
- Stable phase IDs and purpose/level/companion saving remain unchanged.
- Centered, primary-screen no-scroll layouts and minimum 48dp actions remain.
- Preserve choose-source videos, natural character proportions and white fur/feathers. Do not ship RGB checkerboard or missing-asset placeholders.
- Only root owns the separate Site checkout and all Sites tool calls.
- Scope owners commit no files independently; root integrates the owned changes and verifies CI/merge.

## Task 1: Connected Flutter learning story

**Files:** `lib/screens/onboarding_v2/onboarding_story_screen.dart`, `onboarding_story_practice.dart`, new `onboarding_hanok_growth_preview.dart`, `lib/l10n/app_de.arb`, `app_en.arb`, generated l10n, and directly affected story/viewport regression tests.

**Interface:** `OnboardingHanokGrowthPreview({Key? key, bool complete = false})` renders the approved 14/15 construction states with an aspect-preserving transition. Existing `OnboardingJamoPractice` and `OnboardingRewardPractice(character: Widget)` signatures stay callable. No new persistence interface is introduced.

- [ ] Update the meaningful story test to assert `문`, the three-jamo assembly, the DE/EN door meaning, wrong-answer retry and the growth-before-gift sequence.
- [ ] Change the assembly and speech target together:
  ```dart
  const learnedWord = '문';
  const composition = 'ㅁ + ㅜ + ㄴ → 문';
  await SoriSpeech.speak(learnedWord, voice: 'female');
  ```
- [ ] Render the before/after construction states with `AnimatedSwitcher` and `Image.asset(..., fit: BoxFit.contain)` inside measured constraints. Reduced motion uses an immediate state change.
- [ ] Keep reward state local: `answer != learnedWord` permits retry; a correct answer reveals the growth demo, then enables `_unwrap`; replay resets only local answer/growth/gift state.
- [ ] Update titles/supporting copy and the gate bridge around the same word; keep all remaining information in reachable Details sheets.
- [ ] Run story-practice, runtime-catalog, presentation, accessibility and single-screen tests; preserve 320x640/200% top44/bottom34 coverage and repair only real failures.

## Task 2: Signature choose media

**Files:** `lib/screens/onboarding_v2/onboarding_character_media.dart`, new qualified files in `assets/illustrations/onboarding/companions/`, `tool/onboarding_media/`, media tests, and only the companion portion of `onboarding_v2_stage.dart` if needed.

**Interface:** Existing character IDs remain `tiger` / `magpie`; `select` and `confirm` map to the corresponding choose gesture. Supply valid transparent posters and bounded animated assets when qualification succeeds, with a manifest recording source hashes, dimensions, alpha and derivative provenance.

- [ ] Inspect the two actual source clips, preserve their bytes, and optimize video presentation/derivatives without stretching or multiply darkening. Validate foreground preservation and real alpha rather than accepting a fake checkerboard.
- [ ] Keep selection replay and cleanup explicit:
  ```dart
  final shouldAnimate = active && !reduceMotion && appResumed;
  final chooseAsset = characterId == 'tiger'
      ? 'assets/illustrations/onboarding/companions/taego_choose.webp'
      : 'assets/illustrations/onboarding/companions/joy_choose.webp';
  ```
- [ ] The one-shot ends on a valid poster; rapid taps invalidate the previous decode generation; errors and reduced motion never disable selection or continue.
- [ ] Verify actual bundled paths, source-to-choose mapping, 30 alternating selections, motion reduction, decode failure, lifecycle cleanup and foreground/edge quality. Return final artifact paths to root for Site reuse.

## Task 3: Private Site and cross-surface validation

**Files:** Separate existing Site `app/experience.tsx`, `app/onboarding.css`, `public/media/`; root ownership only.

- [ ] Use the same word and order as Task 1; introduce the shared Hanok preview and growth-before-Bojagi sequence.
- [ ] Replace review checkerboard images with qualified Task 2 posters and replay the corresponding choose motion on selection. Retain Taego-left/Joy-right layout.
- [ ] Preserve the one-screen geometry and existing details/preview dialogs; verify all 240 existing browser states plus growth, choose replay and reduced motion.
- [ ] Build, lint changed Site code, commit the validated source and publish to the existing owner-only Site. Verify terminal deployment status and reuse the user's existing tab.

## Task 4: Review, checks and authorized integration

- [ ] Review all Flutter changes against the spec and code quality. Fix load-bearing findings before integration.
- [ ] Run app regression tests, analyzer, media checks and an Android profile build. Record unavailable device gates honestly and do not bypass installation controls.
- [ ] Update/prune Graphify, check whitespace and stage only owned changes. Incorporate current origin/main while preserving unrelated changes.
- [ ] Push the branch, open/update a clear PR, pass required CI and Playwright at the exact PR SHA, and merge.
- [ ] Verify required main checks at the merge SHA. Audit the worktree's unique, ignored, hidden and active-process state; remove it only if the approved cleanup gate passes.

## Pre-execution consistency review

| Ownership pair | Shared interface | Resolution |
|---|---|---|
| Story / media | `OnboardingRewardPractice(character: Widget)` | Story treats the character as a widget; media changes no story persistence. |
| Story / Site | Korean `문`, local growth then gift | Root mirrors content after the story owner freezes ARB/source. |
| Media / Site | Qualified poster/choose asset paths | Media owner returns artifacts; root alone edits Site. |
| Story / tests | Existing shell and safe-inset contracts | Story owner updates affected tests; final reviewer independently checks geometry evidence. |
| Media / tests | Existing lifecycle and last-generation wins | Media owner owns media tests; old no-choose assertions are replaced with the approved choose requirement. |
| Each task / global scope | No real demo grants, no backend schema change | All tasks remain within the existing presentation and verification boundaries. |

The latest user authorization takes precedence over older commit/merge approval prompts. Existing source media are retained; new still-art generation is not required to replace the explicitly requested choose gestures.
