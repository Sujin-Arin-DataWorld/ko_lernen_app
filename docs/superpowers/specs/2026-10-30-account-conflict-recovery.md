# Existing-account progress recovery

## Problem and observed boundary

The Play-installed 2.0.9 (8033), source `5e778d6b5b34f37947f21325170de28fe2252c77`, passes the legacy cloud-document read repaired in PR460 but still defers reconciliation with five conflicts of kinds `courseMasteryPlacement` and `documentField`. This persists after a cold process restart. Manual backup requires a ready write session, so it retains the previous backup date and displays only a short retry message. It cannot resolve the pending switch.

The user explicitly reset device progress only and wants existing cloud history preserved. Current device UI shows 0 XP, level 1, A2 learning goal and Magpie. The actual normalized cloud placement and XP have not been assumed. A learning goal, a chosen course starting point and proven learning are distinct.

## Required behavior

- Preserve normal strict reconciliation and all owner, reset, deletion, session, operation and compare-and-swap fences.
- Merge independently validated legacy fields according to their actual domain semantics. Never apply a generic JSON union, numeric maximum or remote-wins policy to every field.
- Keep the device's already-selected valid learning goal, consistent with existing restore behavior; it is not course placement or earned mastery.
- Merge study-log histories without losing either side, and ensure local application actually converges with the committed merged result. Reject invalid or over-limit records.
- Preserve grammar-plan settings from the current device while retaining compatible served-history extensions. Reject divergent ordered histories instead of skipping unseen exercises.
- Reuse the existing wallet dominance/pristine-zero policy. Divergent reward ledgers remain blocked; balance maxima and unconditional claim unions are forbidden.
- Only an explicit course starting-point choice may resolve two different valid placements. Preserve every actual completion, evidence, checkpoint, Phase, productive and archived proof. Recompute unearned bypass state for the selected starting point without converting bypass into completion or issuing rewards.
- Evaluate each choice independently. If a lower starting point would invalidate retained higher-level completions under the existing prerequisite model, that choice stays unavailable. Do not invent historical-baseline provenance or weaken progression validation. At least one admissible candidate is required for a ready preview.
- Preview reads both latest snapshots and writes nothing. Confirmation accepts only one of the two presented placements and is bound to the exact account, operation, session, catalog and snapshot fingerprints. Any drift requires a new preview.
- Persist sufficient typed consent in the transition journal to resume after interruption at root, pack or local-write checkpoints. Consent never authorizes a different account, new source snapshots or unsupported data.
- The app must never use reset, logout, reinitialization or an existing placement picker as a recovery shortcut.

## UI and diagnostics

Use the existing pending-operation panel and `showSoriSheet` after a user action, preserving C materials and existing navigation. Present device/cloud labels, their actual normalized CEFR starting points and actual completed-unit counts. Disable an inadmissible choice with a plain explanation that it conflicts with retained completions. Do not preselect a side, even when only one is admissible. Confirmation is disabled until selection; cancel/back has no data or journal effects. Keep important recovery failures visible with a retry action.

Use DE/EN AppL10n strings, 48dp controls, focus containment/restoration, 4.5:1 text contrast, safe areas and actual text scaling. Verify at 320/390dp and 100%/200%, plus a wide window and reduced motion. The sheet must preserve the user's text scaling rather than inherit the default 1.3 cap.

Diagnostics contain only fixed field buckets, normalized CEFR enums, validity enums and numeric proof counts. No UID, operation ID, content ID, hashes, raw JSON, user text, credentials, SDK messages or private paths. Crashlytics continues to require the existing consent; diagnostics failures never alter account behavior.

## Fixed boundaries

Flutter 3.44.0 / Dart ^3.12.0, existing dependencies and catalogs; A1/A2/B1/B2/C1/C2 remain. Cloud pronunciation scoring stays off; recording/replay and current content, voices, characters and reward ownership remain. No direct production data repair or synthetic production deletion.

The existing Android 8033 / iOS 263 testing candidates do not contain these follow-up repairs. Finish and verify the assembled account repair before another client testing release. Source, CI, upload, review, tester availability and physical QA are separate gates.

## Design sources checked 2026-10-30

- [Flutter accessibility](https://docs.flutter.dev/ui/accessibility): meaningful actions, intelligible semantics, 48px targets and large text.
- [Flutter Dialog](https://api.flutter.dev/flutter/material/Dialog-class.html): bounded width on large windows; use the existing app sheet instead of introducing a different visual style.
- [Apple Alerts](https://developer.apple.com/design/human-interface-guidelines/alerts): user-initiated choices belong in a sheet, clear action labels, no automatic startup alert.

Implementation uses the pinned local Flutter API; current online API additions are not dependency-upgrade authority.
