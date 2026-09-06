# App Store Connect Review Access — Hangul Sori 2.0.8

This handoff closes the access-information issue reported for TestFlight build
`2.0.7 (242)`. It prepares copy and verification gates; it does not by itself
prove that a new archive was uploaded, attached to groups, or approved.

## What changed

- No username or password is required. The full app continues to support a
  guest path.
- The first consent screen now offers `View demo` / `App ansehen` beneath the
  normal `Continue` / `Weiter` action.
- The demo exposes 15 representative production surfaces with deterministic
  sample progress: onboarding, companion choice, Today, mission briefing,
  listening, role-play, Hanok map, Sarangbang, practice, culture discovery,
  learning path, Gye, profile, offline state, and the complete journey.
- Demo actions use the existing preview seams. Named production routes are
  intercepted inside a nested navigator, and the demo must not grant consent
  or change account or learning progress.
- Closing the demo returns to the untouched consent screen. Selecting
  `Continue` starts the normal guest journey.

## Beta App Review Information

Use these values only after repeating the clean-install path on the exact
signed archive selected for external TestFlight review.

| Field | Value |
|---|---|
| Sign-in required | **No** — the app has no required username/password login |
| Contact first name | `Sujin` |
| Contact last name | `Park` |
| Contact email | **Release owner must enter and verify** |
| Contact phone | **Release owner must enter and verify** |

Paste this into **Beta App Review Information → Additional Information**:

> No account or sign-in is required to review Hangul Sori.
>
> READ-ONLY DEMO: On the first Welcome/Privacy screen, tap "View demo"
> (German: "App ansehen"). This opens representative sample states for the
> onboarding, companion selection, daily learning, listening, role-play,
> personal Hanok, Sarangbang, practice, culture discovery, learning path,
> study group, profile, offline mode, and complete learning journey. The demo
> does not change consent, account data, or learning progress. Use the back
> button to return to the tour and the X button to close it.
>
> FULL GUEST FLOW: Close the demo and tap "Continue" (German: "Weiter"). No
> username or password is requested. Choose a goal, starting level, and
> learning companion, then complete the introductory learning scene. The
> personal Hanok and the rest of the app are available from the main
> navigation. Camera/photo and account linking are optional and are not
> required for core learning.

Do not enable **Sign-in required** or invent demo credentials unless a future
archive introduces a mandatory account gate. Apple should be told explicitly
that review access is guest-based.

## Reply to App Review

Send this only after the replacement build is processed and selected for the
same external testing group:

> Hello App Review,
>
> Thank you for the clarification. Build 2.0.7 (242) did not include
> sufficiently clear review-access instructions. Hangul Sori does not require
> a user account or username/password login.
>
> We have submitted a replacement build with a read-only demo available on the
> first Welcome/Privacy screen via "View demo" (German: "App ansehen"). It
> provides representative sample states across the app without changing
> consent, account data, or learning progress. The full app is also available
> as a guest by closing the demo and tapping "Continue" (German: "Weiter").
>
> We have added the exact navigation steps to Beta App Review Information.
> Please review the newly selected build. Thank you.

Replace `replacement build` with the exact processed version/build if the
review thread UI allows it. Never claim a build is available before processing
and group attachment are visible in App Store Connect.

## Final archive and TestFlight gates

1. Install the exact release candidate on a clean iPhone and iPad.
2. Before accepting consent, open the demo and visit at least Today, listening,
   role-play, Hanok, Gye, profile, and offline sample states.
3. Confirm the X button returns to consent and that consent, level, XP, account,
   and progress remain unchanged.
4. Tap `Continue`, finish the normal guest onboarding, and verify the Hanok and
   main navigation are reachable without account linking.
5. Confirm the processed build is attached to both the intended internal and
   external TestFlight groups. Internal availability and external Beta App
   Review are separate states.
6. Enter a real monitored review-contact email and phone number.
7. Save Beta App Review Information, reply to the review thread, and resubmit
   the replacement build.

## Build-number note

The repository version is whatever `pubspec.yaml` line 4 says at archive time
(current release candidate: `2.0.8+249`). A manual archive therefore uses
`2.0.8 (249)` because `ios/ExportOptions.plist` disables automatic increments.
Xcode Cloud also assigns its own incrementing build number to distributed cloud
builds; the next processed build must be greater than the existing TestFlight
build 248. Verify the processed version/build shown in TestFlight rather than
assuming either value.

Apple references:

- <https://developer.apple.com/documentation/xcode/setting-the-next-build-number-for-xcode-cloud-builds/>
- <https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds>
