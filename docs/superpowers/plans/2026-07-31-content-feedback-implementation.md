# Tester Passport Feedback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (\`- [ ]\`) syntax for tracking.

**Goal:** 모든 실제 학습 완료 화면에서 테스터가 버그, 콘텐츠 난이도·품질, 기타 의견을 짧게 보낼 수 있게 하고, 제출 성공 시에만 테스트용 Beta Tester Passport 도장과 다음 Beta Mission 안내를 제공한다.

**Architecture:** 완료 이벤트가 안정적인 completionId와 명시적인 ContentFeedbackContext를 한 번만 만든다. 공통 Flutter 카드/시트는 그 context를 받아 로컬 안전 저장 outbox에 먼저 저장하고 Callable Function으로 전송한다. Function은 인증 UID, App Check, 허용된 payload/mission만 검증하여 서버가 소유한 feedback 문서와 passport 상태를 한 Firestore transaction으로 갱신한다. Firestore 직접 쓰기는 금지한다.

**Tech Stack:** Flutter/Dart, Firebase Auth/App Check/Functions/Firestore, flutter_secure_storage, package_info_plus, uuid, Cloud Functions for Firebase (Node 22), Firestore Emulator rules tests.

## Global Constraints

- 기준은 origin/main c5d1415 및 이 worktree의 설계 커밋 bdc1c7d다. 현재 사용자 변경이나 TTS cache 작업을 이 작업에 섞지 않는다.
- 사용자에게 노출되는 모든 새 문구, 도움말, 오류, passport mission 이름은 독일어와 영어로만 제공한다. 한국어는 구현 협업 문서에만 쓸 수 있으며 앱 locale/ARB에 추가하지 않는다.
- ENABLE_TESTER_FEEDBACK은 기본 false다. 현재 production feature gate는 이 define과 Android platform 둘 다 만족할 때만 true가 된다. Flutter widget test에서는 주입 가능한 feature gate를 사용한다.
- 내부 Android beta AAB는 반드시 ENABLE_TESTER_FEEDBACK=true 및 BETA_UNLOCK_ALL=true를 함께 명시한다. 정식 Android/iOS 빌드는 ENABLE_TESTER_FEEDBACK을 생략하고 BETA_UNLOCK_ALL=false를 반드시 명시한다. 이번 작업에서 PremiumService의 기존 기본값은 변경하지 않는다.
- 현재 iOS Firebase 구성이 없으므로 이 기능의 실제 device beta 검증/배포 대상은 Android다. iOS Firebase 등록과 GoogleService-Info.plist, App Privacy 검토 전에는 iOS 지원을 주장하지 않는다.
- “다음 단계”는 Beta Mission 추천 경로일 뿐 premium entitlement, 실제 CEFR 잠금, 기존 다음/완료 버튼을 막거나 해제하지 않는다. 피드백을 보내지 않아도 학습은 계속된다.
- 전역 NavigatorObserver로 완료를 추론하지 않는다. 완료 화면의 실제 종료 이벤트에서만 context를 전달한다. build 안에서 UUID를 만들지 않는다.
- 원문 답, 목표 단어, 이메일/연락처, 기기 모델, FCM/광고 ID, 스크린샷, 전체 학습 이력은 전송하지 않는다. scoreSummary는 “7/10”, “win; guesses:4” 같은 짧은 집계만 허용한다.
- 자유 입력은 최대 1,000자다. bug/other는 비어 있으면 제출할 수 없고 content는 signal/focus만으로도 제출할 수 있다.
- outbox는 전용 flutter_secure_storage key에 최대 20개를 저장한다. 같은 live Firebase UID의 항목만 drain하고 UID가 바뀌면 폐기한다. 계정 삭제 시작 전에는 drain을 차단하고 outbox를 폐기한다.
- Firestore의 넓은 user-subcollection fallback allow는 explicit deny를 덮어쓸 수 있다. tester_feedback/tester_passport는 fallback에서 반드시 제외한다.
- 적용 대상은 실제 학습 결과 화면이다: scenario, vocab pack, listening, review, custom pack play, 실제 due 학습을 끝낸 legacy vocab, daily char, chosung, Wordle, Kkeunmari, 그리고 GameOverCard를 쓰는 Cloze/daily challenge/Satz Arcade/Speed Match/custom pack quiz·matching·typing, 명시적으로 마친 grammar/hangul session.
- 적용 제외: 초기 빈 due 상태, all/favorites 무한 순환 vocab, Smalltalk, bookshelf, OCR/book analysis, onboarding, quests/metagame achievement, billing/settings/account deletion이다. quests의 celebration은 학습 콘텐츠 결과가 아니라 메타 진행이므로 제외한다.

---

## Task 1: Freeze the feedback contract, flags, catalog, and localization

**Files:**
- Modify: pubspec.yaml
- Create: lib/config/tester_feedback_feature.dart
- Create: lib/models/content_feedback.dart
- Create: lib/data/beta_mission_catalog.dart
- Modify: lib/l10n/app_de.arb
- Modify: lib/l10n/app_en.arb
- Modify generated: lib/l10n/generated/*
- Create: test/content_feedback_test.dart

- [ ] Add direct dependencies package_info_plus and uuid. Run flutter pub get only after the dependency edit; do not use transitive packages as imports.
- [ ] Define pure, JSON-safe model types in content_feedback.dart:

      enum FeedbackCategory { bug, content, other }
      enum FeedbackIssueArea { ui, answer, audio, translation, navigation, other }
      enum FeedbackContentSignal { tooEasy, right, tooHard, unclear }
      enum FeedbackContentFocus { explanation, examples, questions, pace, translation, other }

      class ContentFeedbackContext {
        final String completionId;
        final String contentType;
        final String contentId;
        final String contentLabel;
        final String? level;
        final String scoreSummary;
      }

  Add bounded validation and a toWire() serializer for the submitted draft. Keep feedbackId distinct from completionId: feedbackId is a retry token, completionId is the server document identity.
- [ ] Add an injectable TesterFeedbackFeatureGate with a production default backed by bool.fromEnvironment('ENABLE_TESTER_FEEDBACK', defaultValue: false) and the Android platform check. Its constructor/factory must allow tests to set enabled without Dart defines.
- [ ] Define a locally versioned BetaMission catalog. The five first missions must have stable IDs and allowed content types:

      beta_scenario       -> scenario
      beta_word_work      -> vocab_pack, review, custom_wordbook, custom_wordbook_game, legacy_vocab
      beta_listening      -> listening
      beta_games          -> game
      beta_language_form  -> grammar_session, hangul_cards, hangul_writing, daily_hangul

  Provide nextMission(completedMissionIds, context) and missionFor(context). Do not use server-returned free text as UI instructions.
- [ ] Add native German primary copy and English fallback copy for the compact card, each category choice, validation, submission states, five passport mission labels, privacy reminder, and explicit grammar/hangul/daily-char completion actions. Do not add Korean app strings or literal UI copy in widgets.
- [ ] Test model validation, 1,000-character bounds, no required raw answer field, default-off gate, catalog mapping, and “first incomplete matching mission” selection.

**Commit:** feat(feedback): add feedback contract and beta mission catalog

## Task 2: Build the client submission boundary and secure outbox

**Files:**
- Create: lib/services/content_feedback_service.dart
- Create: lib/services/content_feedback_outbox.dart
- Create: lib/services/content_feedback_client.dart
- Create: lib/services/content_feedback_version_provider.dart
- Create: test/content_feedback_outbox_test.dart
- Modify: lib/services/app_startup_coordinator.dart
- Modify: test/services/app_startup_coordinator_test.dart

- [ ] Create a dedicated FeedbackOutboxStore interface plus SecureFeedbackOutboxStore. Use one new, namespaced secure-storage key such as kl_tester_feedback_outbox_v1; do not reuse TransitionSecretStore or Storage.resetAllStrict().
- [ ] The persisted item contains only validated payload, createdAt, ownerUid, retry metadata, and a local status. It must be decoded defensively; malformed records are discarded rather than sent.
- [ ] Add an injectable ContentFeedbackCallableClient using FirebaseFunctions.instanceFor(region: 'europe-west3') and HttpsCallableOptions(limitedUseAppCheckToken: true). It invokes submitTesterFeedback and exposes only safe, user-facing error categories; it never logs free text, UID, or tokens.
- [ ] ContentFeedbackService.submit(context, draft) must:
  1. validate the context/draft;
  2. read the current authenticated UID and package version/build;
  3. allocate feedbackId exactly once;
  4. append to secure outbox before any network attempt;
  5. attempt delivery;
  6. remove on accepted or duplicate-completion acknowledgement;
  7. retain a safe pending state on transient failure.
- [ ] ContentFeedbackService.resumePending() must only run after Firebase, App Check, anonymous authentication, and ready-session synchronization. It must refuse to drain while a deletion checkpoint/intent is active and discard entries belonging to a different UID.
- [ ] Add closeAndDiscard() that atomically prevents further drain and erases the secure outbox. This is the API that account deletion will own.
- [ ] Extend AppStartupCoordinator with an injected resumeFeedbackOutbox callback after ensureSignedIn and synchronizeReadySession. The normal production callback is no-op when the feature flag is off.
- [ ] Test persistence-before-network, retry using the same feedbackId, max-20 behavior without silent deletion, current-UID-only drain, malformed-record disposal, delete/close behavior, duplicate acknowledgement, and startup ordering.

**Commit:** feat(feedback): add secure feedback outbox and callable client

## Task 3: Add the reusable card, sheet, and passport presentation

**Files:**
- Create: lib/widgets/sori/content_feedback_card.dart
- Create: lib/widgets/sori/content_feedback_sheet.dart
- Modify: lib/widgets/sori/game_reward.dart
- Modify: test/sori_sheet_test.dart
- Create: test/content_feedback_widget_test.dart

- [ ] ContentFeedbackCard accepts ContentFeedbackContext, a feature gate, and a service/controller seam. Return SizedBox.shrink when disabled; it must never auto-open a sheet.
- [ ] Render it as an optional compact result-screen card: tiger/magpie asset via existing Mascot, optional static SoriCelebration stamp reaction, compact passport progress, and “send a note to the tiger” action. Do not add XP, coins, premium unlocks, or blocking dialogs.
- [ ] Open ContentFeedbackSheet through showSoriSheet so keyboard insets, text scaling, safe area, and reduce-motion behavior remain consistent.
- [ ] Sheet flow: choose bug/content/other; show only corresponding structured fields; ask a content-specific prompt from the context type; enforce required message for bug/other; show the privacy reminder; submit/cancel. Success changes the originating card to delivered/pending state and shows next Beta Mission if server accepted its stamp.
- [ ] Extend GameOverCard with nullable ContentFeedbackContext? feedbackContext and put ContentFeedbackCard in its existing scrollable center below result details, before normal actions. Existing callers with null context must be visually/functionally unchanged.
- [ ] Widget test: disabled gate renders nothing; card does not auto-open; all three categories validate; content can submit structured feedback with blank message; keyboard/sheet uses existing Sori sheet semantics; reduce motion has no required animation; GameOverCard renders feedback only when context supplied.

**Commit:** feat(feedback): add optional tester feedback card and sheet

## Task 4: Implement the protected server-side feedback callable

**Files:**
- Create: functions/gye/tester_feedback_runtime.js
- Create: functions/gye/tester_feedback_runtime.test.js
- Modify: functions/gye/index.js
- Modify: functions/gye/package.json

- [ ] Keep validation, persistence, and Callable construction in tester_feedback_runtime.js; index.js only composes/imports/exports it.
- [ ] Use fixed Callable options:

      {
        region: 'europe-west3',
        enforceAppCheck: true,
        consumeAppCheckToken: true,
      }

  Require request.auth.uid. Anonymous Firebase accounts are allowed because the application creates them during startup. Reject missing App Check/appId or already-consumed tokens consistently with existing protected callable conventions.
- [ ] Validate an allowlisted schema only: schemaVersion, feedbackId, completionId, category-specific fields, bounded context strings, allowed locale/platform, appVersion, and optional betaMissionId. Reject unknown fields, payload UID, invalid enum/value combinations, and oversize text. Never echo user text into errors/logs.
- [ ] Treat users/{uid}/tester_feedback/{completionId} as the authoritative completion sentinel. In one Firestore transaction:
  - no existing document: write the feedback document including feedbackId, server timestamp, immutable context, and status;
  - existing document with same feedbackId: return idempotent accepted response;
  - existing document with a different feedbackId: return a safe duplicate-completion result and never create another document/stamp;
  - a valid, not-yet-completed betaMissionId whose catalog entry matches contentType: update users/{uid}/tester_passport/state with completed mission IDs and server timestamp.
- [ ] The server owns the mission allowlist; Dart's compile-time flag is not a security boundary. Return only accepted/duplicate, passport completed IDs, and next allowed mission ID/label key—not client-controlled prose.
- [ ] Add the new Node test file to the explicitly enumerated npm test script. Cover callable options, auth/App Check failures, unknown fields, forged UID, enum/length/category validation, retry idempotency, completion collision, mission mismatch, one-stamp-only behavior, server timestamps, and no extra paths.

**Commit:** feat(functions): accept verified tester feedback

## Task 5: Lock down Firestore and disclose collection accurately

**Files:**
- Modify: firestore.rules
- Modify: functions/gye/firestore.rules.test.js
- Modify: docs/privacy.html

- [ ] Add explicit rules under users/{uid}:
  - tester_feedback and every document below it: read/create/update/delete false;
  - tester_passport/state: owner get only; list/create/update/delete false.
- [ ] Amend the broad generic user-subcollection fallback to exclude tester_feedback and tester_passport. Preserve existing access for unrelated user collections and write a regression rule test for it.
- [ ] Update all privacy-language variants in docs/privacy.html: optional tester feedback purpose, free-text/user-ID linkage, minimal automatic metadata, no use of raw answers/device identifiers, secure Firebase processing, and feedback removal as part of account deletion.
- [ ] Add Emulator coverage that an owner cannot read/write feedback, cannot list/write passport state, may get only their own state, and normal legacy user subcollections still obey their pre-existing permissions.

**Commit:** feat(privacy): protect tester feedback records

## Task 6: Make account deletion and startup safe for secure feedback

**Files:**
- Modify: lib/screens/settings_screen.dart
- Modify: lib/services/app_startup_coordinator.dart
- Modify relevant account deletion tests under test/services/account/ and test/screens/

- [ ] Inject FeedbackOutbox into AccountDeletionWorkflow rather than reaching for a singleton.
- [ ] Immediately before deleteRemoteAccount() begins, call closeAndDiscard(). If discarding fails, fail safely before remote deletion rather than leave user free text queued for a later account.
- [ ] Ensure any deletion-in-progress/checkpoint state prevents resumePending() from sending. Verify a post-delete/restart cannot attribute an old anonymous account's feedback to a new anonymous UID.
- [ ] Test call ordering (close/discard before remote deletion), failure behavior, restart during deletion, and that existing account deletion behavior remains intact.

**Commit:** fix(account): discard tester feedback before deletion

## Task 7: Wire every shared GameOverCard result with stable context

**Files:**
- Modify: lib/screens/cloze_game_screen.dart
- Modify: lib/screens/daily_challenge_screen.dart
- Modify: lib/screens/satz_arcade_screen.dart
- Modify: lib/screens/speed_match_screen.dart
- Modify: lib/screens/custom_pack_quiz_screen.dart
- Modify: lib/screens/custom_pack_matching_screen.dart
- Modify: lib/screens/custom_pack_typing_screen.dart
- Create/modify focused tests for these screens or pure context factories

- [ ] Introduce a small FeedbackCompletion factory/UUID seam. Each screen creates one completionId at its actual finish event, stores it in State, passes it to GameOverCard, and resets it only when a new round/replay begins.
- [ ] Use safe aggregate contexts:
  - cloze: game/cloze, selected level, correct/total percent;
  - daily challenge: game/daily_challenge:local-ISO-date, counts/percent;
  - Satz Arcade: game/satz_arcade, selected level, passed/total;
  - Speed Match: game/speed_match, selected level, score plus 60-second round;
  - custom pack games: custom_wordbook_game/custom_pack:<packId>:quiz|matching|typing, display name, correct/total or pairs/misses.
- [ ] For custom matching, allocate the completion ID synchronously before its async finish work begins so a rebuild cannot render an IDless/changed result.
- [ ] Test exact contentType/contentId/summary values and stable ID across rebuild, plus ID reset on replay.

**Commit:** feat(feedback): cover shared game result screens

## Task 8: Wire dedicated result screens and preserve their existing semantics

**Files:**
- Modify: lib/screens/scenario_player_screen.dart
- Modify: lib/screens/vocab_pack_screen.dart
- Modify: lib/screens/vocab_pack_result_screen.dart
- Modify: lib/screens/listening_screen.dart
- Modify: lib/screens/review_session_screen.dart
- Modify: lib/screens/custom_pack_play_screen.dart
- Modify: lib/screens/legacy_vocab_screen.dart
- Modify their focused tests

- [ ] Scenario: create completionId when entering the result state, not in build and not in _persistResult. Put the card above next/complete CTA. Keep _complete/_openNext persistence behavior and ensure feedback cannot double-award completion XP.
- [ ] Vocab pack: generate completionId and known level in vocab_pack_screen _finish, pass both through result-screen constructor/route args, and render that stable context in the otherwise stateless result screen.
- [ ] Listening: own completionId in State at _finish, reset on pick/restart, and include selected scenario ID/title/level plus safe line-count/rate summary.
- [ ] Review: create completionId on transition to done. Add optional feedbackContentId/feedbackContentLabel constructor fields so today review, hard words, and personalized-course callers remain distinguishable without sending word lists. Level only when the deck has one unambiguous level.
- [ ] Custom pack play: assign ID when _advance crosses the final item and reset it on Again. Use custom_wordbook/custom_pack:<id>:play with learned/total.
- [ ] Legacy vocab: add session-only due processed counts. Show a result/card only after due mode has processed at least one card and reaches zero; do not show one for initially empty due, all, or favorites. Never send the existing lifetime _correct/_wrong counters as a session score.
- [ ] Test scenario persistence is unchanged, vocab route retains ID/level, listening restart resets ID, review caller context, custom replay resets ID, and legacy initial-empty state is excluded.

**Commit:** feat(feedback): cover dedicated learning results

## Task 9: Add honest completion endpoints to circular activities

**Files:**
- Modify: lib/screens/daily_char_sheet.dart
- Modify: lib/screens/chosung_quiz_screen.dart
- Modify: lib/screens/wordle_screen.dart
- Modify: lib/screens/kkeunmari_screen.dart
- Modify: lib/screens/grammar_screen.dart
- Modify: lib/screens/hangul_screen.dart
- Modify the PracticeCanvas implementation that owns stroke-complete callbacks
- Modify/create focused widget tests

- [ ] Daily char: replace the 1.5-second auto-pop with a visible done state, optional feedback card, and explicit Close. Use daily_hangul/daily-char:local-ISO-date with character/stroke-count aggregate only.
- [ ] Chosung: create on completed round, reset on new round, and pass game/chosung with level, roundCorrect/10, average time.
- [ ] Wordle: create in _submit when a win/loss is determined and reset in _load. Use game/wordle_daily or game/wordle_random; never include _target or the answer in contentId, label, or score summary.
- [ ] Kkeunmari: create at _endGame and reset in _start. Use chain length/end reason aggregate.
- [ ] Grammar: track meaningful flip/easy/hard interactions only. Add localized “finish this study session”; keep it disabled until at least one meaningful interaction, then show a result/card with grammar_session/grammar:<level>:<type>:<difficulty> and seen count.
- [ ] Hangul: remove const where needed so both Cards and Writing tabs receive a parent finish callback. Track Cards views/flips and PracticeCanvas.onStrokeEnd; finish is disabled until a real interaction. Each tab opens a result sheet/card with hangul_cards or hangul_writing and a safe count, never fake CEFR level.
- [ ] Test daily char remains open, no card for untouched grammar/hangul, all valid completion paths display the card, Wordle payload lacks its answer, and each new session gets a new completion ID.

**Commit:** feat(feedback): add completion feedback to practice sessions

## Task 10: Run exhaustive automated verification and release-safe manual checks

**Files:**
- Modify any test files needed by failures only
- Update this plan checklist with completed checks and recorded limitations

- [x] Regenerate localization and run the formatting audit:

      flutter gen-l10n
      dart format --output=none --set-exit-if-changed lib test
      flutter analyze --no-pub

  `flutter gen-l10n` and the analyzer passed. The read-only whole-tree
  formatter audit ran and reported 78 pre-existing formatting candidates; no
  unrelated files were rewritten. The Task 10 test delta passes its targeted
  formatter check.

- [x] Run focused Flutter suite before full suite:

      flutter test --no-pub test/content_feedback_test.dart test/content_feedback_outbox_test.dart test/content_feedback_widget_test.dart test/services/app_startup_coordinator_test.dart

  Result: 63/63 passed.

- [x] Restore Functions dependencies from the lockfile if missing, then run:

      npm.cmd --prefix functions/gye ci
      npm.cmd --prefix functions/gye test
      npm.cmd --prefix functions/gye run test:rules

  Results: `npm ci` passed, Functions 241/241 passed, and Firestore rules
  emulator 40/40 passed using the Android Studio JBR for this process only.
  Local Node is v24 while the declared Functions engine is Node 22; the
  lockfile audit also reports 10 moderate vulnerabilities.

  Record pre-existing failures separately; do not mask them with this feature.
- [x] Run full Flutter test suite:

      flutter test --no-pub

  Result: 1,319/1,319 passed.

- [ ] Manual Android beta test matrix: feedback skip/send/retry on at least scenario, game, vocab/review, listening, grammar, hangul; airplane-mode queue then reconnect; app restart; account deletion with a pending item; large font/screen reader/reduce motion; badge/missions never gate existing next actions.

  Not run: this requires a physical Android beta device and signed build.
- [ ] Deploy prerequisites before the beta AAB: Functions + Firestore rules; verify App Check from a real Android device and one feedback document/passport update in Firebase Console. Build:

      flutter build appbundle --release --dart-define=ENABLE_TESTER_FEEDBACK=true --dart-define=BETA_UNLOCK_ALL=true

  For production build validation use:

      flutter build appbundle --release --dart-define=BETA_UNLOCK_ALL=false

  Not deployed or built as an AAB. Current-worktree `android/key.properties`
  is absent, so the enforced release-signing guard blocks both signed beta and
  production AABs. No signing material was copied or bypassed. A
  signing-independent release-mode Flutter bundle compile passed with
  `BETA_UNLOCK_ALL=false` and `ENABLE_TESTER_FEEDBACK` omitted; it is not a
  distributable Android artifact. The Android Gradle wrapper script is also
  absent in this worktree, so a direct Gradle dry run could not start.

- [ ] Before completion, inspect git diff/status, ensure no credentials/key.properties/Google service secrets are tracked, and obtain an independent code review of changed Flutter, Functions, rules, and release docs.

  Diff/status and credential-name audits completed. No key.properties,
  keystore, or private-key/client-secret marker is tracked; the repository
  does retain its two pre-existing Firebase Android client configuration JSON
  files. Independent review completed and found release blockers: the feedback
  callable does not transactionally fence account deletion, server-side rate
  limiting is absent, passport progress is not restored globally across
  navigation/restart, and the Korean privacy variant omits feedback disclosure.
  A minor Grammar filter/session-coherence issue also remains. These production
  and privacy fixes are outside Task 10's test-only change scope.

**Commit:** test(feedback): verify tester feedback release path

## Plan Review Checklist

- [x] Every included actual result screen has an explicit stable context source and an ID creation/reset point.
- [x] Every excluded completion-like view is named and intentionally out of scope.
- [ ] Contract types agree across Dart, Node validation, Firestore paths/rules, and privacy disclosure. Korean disclosure remains incomplete.
- [x] CompletionId is the server document identity; feedbackId is only an idempotency token.
- [ ] Secure-storage lifecycle includes UID separation, startup ordering, retry, account deletion, and closed-outbox behavior. The server transaction still needs an account-deletion fence.
- [x] Beta flags are explicit for both tester and production builds; passport cannot alter premium/real progression.
- [x] No task contains an unresolved implementation placeholder or assumes unverified iOS Firebase support.

---

## Task 11: Close production audit blockers before release handoff

**Files:**
- Modify: functions/gye/tester_feedback_runtime.js
- Modify: functions/gye/tester_feedback_runtime.test.js
- Modify: firestore.rules
- Modify: functions/gye/firestore.rules.test.js
- Modify: lib/services/content_feedback_client.dart
- Modify: lib/services/content_feedback_service.dart
- Modify: lib/widgets/sori/content_feedback_card.dart
- Modify: lib/main.dart
- Modify: lib/screens/grammar_screen.dart
- Modify: docs/privacy.html
- Modify/create focused Dart and Node tests

- [ ] Add a server-owned account-deletion guard to the feedback transaction. Read the existing deletion-operation document for the authenticated UID inside the same Firestore transaction before any new feedback/passport write. If an account-deletion intent/checkpoint exists, reject new feedback with a safe failed-precondition code and no user text. The transaction read must make a previously started feedback request retry/observe a concurrent deletion marker rather than commit after it.
- [ ] Add a server-enforced, per-UID and per-verified-App-Check-appId feedback quota. Store only a bounded counter/window in a private user-subcollection document; do not use client time or client-provided UID/app ID. A new completion consumes one slot; same-feedback retry and duplicate-completion acknowledgement do not. Add the new private collection to Firestore deny/fallback exclusions and Emulator tests. Select/document a tester-friendly constant (20 submissions per rolling 24-hour window) and return a safe resource-exhausted response on limit.
- [ ] Restore passport progress after navigation/restart without client writes. Add an injectable read-only passport-state reader that fetches only the authenticated user's permitted tester_passport/state document, validates known mission IDs, and provides it to ContentFeedbackCard through the existing controller scope. Treat missing/malformed/foreign state as an empty set; do not expose UID/errors/free text. Keep a delivered response's authoritative state as the immediate UI source, then refresh safely on a new card/session.
- [ ] Make every existing privacy-language section internally consistent. Update the retained Korean privacy section with the same feedback collection/recipient/deletion facts as EN/DE, but do not add Korean app UI localization.
- [ ] Reset Grammar's explicit study session (interaction set and completion slot) whenever level/type/difficulty filters alter the current study set. A finish after a filter change must report only interactions from that current filter context.
- [ ] Add deterministic regression tests for:
  - a feedback transaction racing with account-deletion intent;
  - quota increments only for new accepted completion and rejects a 21st new completion without leaking data;
  - client read-only passport restoration and malformed/foreign-state fallback;
  - Korean privacy disclosure parity;
  - grammar interaction reset after a filter change.
- [ ] Re-run Functions, Firestore Emulator, focused Flutter, full Flutter, and analyzer gates. Review the entire final diff again before creating a beta AAB or deploying.

**Commit:** fix(feedback): close release audit blockers
