# Sori Stage Task Checklist

- [x] Task 1: Worktree and preview foundation
  - Acceptance: semantic colors, rollout flag, activity/reward models, and four
    read-only gallery panels exist.
  - Verify: `flutter test test/ux_preview_catalog_test.dart test/ux_preview_feature_test.dart`

- [ ] Task 2: Five-root production shell
  - Acceptance: Today, Learn, Games, Hanok, and Gye are the five roots; profile
    is available from every root header; legacy shell remains flag-accessible.
  - Verify: focused shell widget tests at 390dp and 720dp.

- [ ] Task 3: Catalog-driven Learn and Games
  - Acceptance: every existing entry is reachable once and shows time, state,
    first-clear reward, and related quest/Hanok effect.
  - Verify: catalog completeness and navigation widget tests.

- [ ] Task 4: Today and Hanok progression
  - Acceptance: Today prioritizes one mission, pending Bojagi, current/next
    structure, three closest quests, and observed reward receipt.
  - Verify: progression and reward-delta unit/widget tests.

- [ ] Task 5: Quest actions and mastery
  - Acceptance: all 18 quests have an exact action or opening date; word quests
    use SRS `strong`; existing completed rewards never regress.
  - Verify: quest catalog/tracker/action resolver tests.

- [ ] Task 6: Gye unique member trigger
  - Acceptance: active UIDs across all Gyes are deduplicated, only the number is
    cached, offline does not create a new completion.
  - Verify: service and quest tracker unit tests.

- [ ] Task 7: Optional pronunciation assessment
  - Acceptance: explicit consent, ten-second PCM16 capture, callable auth/App
    Check/size/rate gates, 80 threshold, idempotent assessment IDs, fallback.
  - Verify: Flutter service/screen tests and Node function tests.

- [ ] Task 8: Privacy, permissions, and data lifecycle
  - Acceptance: DE/EN mic strings, privacy copy, export/delete coverage, consent
    reset, and non-retention claims match code.
  - Verify: platform contract and data export/reset tests.

- [ ] Task 9: Complete verification and handoff
  - Acceptance: focused and full tests, analysis, responsive/a11y screenshots,
    local commits, session log, and clean-main proof are recorded.
  - Verify: repository gates plus read-only main `git status`.
