# Hahoe and Dokkaebi practice implementation

> Execute with superpowers:executing-plans. Spec: `docs/superpowers/specs/2026-10-03-hahoe-dokkaebi-practice-design.md`.

Goal: deliver the three approved learning connections, durable personal history and account backup without altering course or game reward policy.

Architecture: typed versioned content, bounded practice snapshots, account-lifetime protected serialized storage, existing Sori screens and routers. Future work remains in the spec backlog.

## Task 1: Durable practice history and cloud contract
- [x] Add failing behavior tests for independent/viewed separation, idempotent attempts, deterministic merge, corrupt version rejection, write failure and expired lease.
- [x] Implement `lib/models/practice_history.dart` and `lib/services/practice_history_store.dart` using StorageService serialized persistence and `LocalDataLifetime`.
- [x] Add `hanok_practice_json` to StorageService reset/restore and `cloud_sync.dart`, `account/account_reconciliation.dart` validation and merge.
- [x] Run history plus cloud/account recovery tests. Expected: durable state, unchanged rewards, old backups accepted.

## Task 2: Context cases and Smalltalk flow
- [x] Add content contract tests for ten cases, five topics, transfer variants, multiple valid expressions, triad and assembly completeness.
- [x] Author `assets/data/smalltalk_context_cases.json`, typed `SmalltalkContextCase` and catalog.
- [x] Implement a SoriStudyFrame context practice screen and Smalltalk entry in the current content hub; preserve the existing course screen. Use existing character names/voice resolver.
- [x] Verify intent/expression effects, follow-up assembly, assistance classification and retry after failed persistence.

## Task 3: Silben help and independent replay
- [x] Add failing grid tests for active word, crossing cells, reveal without placement, shared-word assistance, stable occurrence IDs and replay without XP.
- [x] Implement staged helper beside the actual grid and typed replay arguments in `silben_kreuz_screen.dart`.
- [x] Persist completed assisted words and independent replay results. Preserve normal completion persistence order and stale presentation guards.
- [x] Run grid/game durability regressions. Expected: no automatic tile placement or extra replay rewards.

## Task 4: Sarangbang collection and localization
- [x] Add learning-record collection below the room without changing furnishing or course receipt.
- [x] Link transfer practice and puzzle replay through existing routes; add DE/EN UI strings and generate l10n.
- [x] Use approved original PNGs with SHA proof, 48dp controls, scalable text and reduced motion.
- [x] Verify loaded/viewed/assisted/independent distinctions, loading/error/empty states and account switches.

## Task 5: Verify and show actual UI
- [x] Run appropriate unit/widget and existing regression checks, analysis, content/asset validation and web build.
- [x] Discover actual built UI, rehearse Smalltalk→Sarangbang→Silben routes and record ui-demo.
- [ ] Physical Android/TalkBack: explicitly deferred by the user; no current device result claimed.
- [x] Fresh whole-change review, fix important issues with regression tests, run Graphify update/prune.
- [x] Update spec with implementation paths and concrete validation evidence. Keep future stages waiting.

Global constraints: no commits/pushes without user request; no persona profile/asset changes; no new XP/coin grants; no unbounded free-input history; approved art bytes untouched; local tests do not prove remote CI or physical TalkBack.

## Verification after restoring the learning scope

The completion branch starts at `34f1b0ca51de4f9b69db7d499b74fc17844dd878`. The original video worktree stays intact. Only the approved static PNGs are runtime assets; rejected video candidates and their separate production spec are outside this PR.

- Core unit/widget and real-route DE/EN journeys: 26 tests passed. `test/practice_journey_test.dart` traverses Smalltalk → actual Sarangbang → collection → transfer and normal Silben → Sarangbang → collection → replay. Reload preserves history; replay keeps XP/personal best unchanged.
- Reproduced and repaired the missing normal Silben completion → Sarangbang action and the missing viewed-only Silben history. Opening/reopening records no completion, XP or personal best. Viewed write failure retains a retry surface; stale presentation/account/lifetime checks protect writes.
- Fresh whole-change review and the repository's independent Standards/Spec axes found no remaining blocking code findings. The optional authoring-helper naming comment is a readability follow-up. Hint-label punctuation was corrected and localization regenerated.
- Relevant Dart analysis passes with fatal infos enabled. Whole-repository analysis separately reports three pre-existing infos in two unrelated test files.
- Cloud-backup deletion runtime: 18 tests passed. Context TTS voice/key tests: 2 passed. Content schema validation reports no issues. Release web build passes.
- Context-dialogue speech: 46 unique voice/text keys, 45 new audio files generated through the existing quality gates. All 46 public MP3 requests return HTTP 200. Client/server canonical allowlists include them. Source language review is model review, not human/native-speaker approval.
- Real mobile-width web journeys were explored, rehearsed and recorded. QA artifacts live outside the checkout at `C:/dev/hangulsori/_codex_artifacts/hahoe-dokkaebi-core-completion-20261003` (Smalltalk and Silben journey WebMs, screenshots, actions and stored-state assertions). Browser replay keeps XP at 30; it does not create a second normal-game reward.

The full Flutter run before the viewed-only correction completed with 9,347 successes, five content assertion failures and one unrelated construction-image timeout. The current remote main also has a failing CI run `37057384805`: content_factory reports 16 failures and 7 errors, and Flutter content guards fail. Existing reviewed-copy ledgers, first-dialog bundle and corpus mirrors need reconciliation. These failures are not represented as a green full suite. The final scoped 26-test run covers the viewed-only correction.

PR #445 CI also caught an omitted classification for the new context JSON. Registering it as learner-facing relationship-context practice fixes that regression; all eight content text audit tests pass. The construction-image test passes in isolation. Existing content failures still require separate reconciliation.

The user now authorizes commit, push, main merge and safe worktree cleanup. PR/head and merged-main checks remain live integration gates. Cleanup must wait for verified merged-main checks and preservation of unique ignored evidence.

Backend release remains separate: deploy the updated backup-deletion field contract together with any release that writes `hanok_practice_json`. The checked-in TTS server allowlist is updated; no function/rules deployment or production multi-device restore is claimed. Physical Android/TalkBack remains deferred. Additional games, reward policy and character motion remain in the approved waiting list.
