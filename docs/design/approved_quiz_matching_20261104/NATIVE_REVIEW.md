# Native review boundary — 2026-11-04

The production Quiz/Matching routes compile into an Android application. A separate QA host was used to avoid replacing the installed user's app or altering its learning data.

- Host package: `com.hangulsori.review.hangulsori_game_review`.
- Device observed: Xiaomi `M2101K6G` (`sweet_eea`), ADB serial `9053622f`; physical1080×2400, density440.
- Host has six production-widget presentation fixtures plus the real `CustomPackQuizScreen` and `CustomPackMatchingScreen` with a local, explicitly constructed six-word QA pack.
- Host dependency lock was copied from this checkout. The first unconstrained host resolution exposed an unrelated Firebase enum API change; it was corrected by using the existing lock, without changing production service code.
- APK build passed with the real assets/fonts and existing plugins. Debug build size1462673514bytes; SHA-256 `9b0fd86837f066b4bd530d13ae335b9a0754f4b4bd07d62acf76f355365b5ae4`.
- Installation was rejected by the device: `INSTALL_FAILED_USER_RESTRICTED: Install canceled by user`. No security setting was bypassed; the production app and its storage were not replaced or cleared.

**No physical-device screenshot, tap journey, haptic, TTS playback, performance or full-shell return acceptance is claimed.** Figma comparison and widget behavior tests are separate evidence. The user was asked asynchronously whether to permit a new device installation attempt; independent implementation and mockup work continued.

The APK above predates the final bounded SafeArea spacing adaptation and is retained only as build-attempt evidence, not a final distributable. Rebuild from the final commit before a later device acceptance run. The final code is validated with full-frame SafeArea widget tests; those tests are not represented as a physical-device result.

The preserved APK is `C:/dev/hangulsori/_codex_artifacts/spiele-quiz-matching-native-20261104/native-firstbuild.apk`. After hash verification, only this task's generated Android QA build directory was removed to recover disk space. Source assets, device data, other worktrees and their build outputs were untouched.

Local diagnostics and QA host: `C:/dev/hangulsori/_codex_artifacts/spiele-quiz-matching-native-20261104/`. No Play Console, TestFlight, production deployment or iOS device operation occurred.
