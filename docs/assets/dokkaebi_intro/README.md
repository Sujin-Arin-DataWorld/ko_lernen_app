# Approved Dokkaebi introduction

The 16 transparent flame phases surround the existing one-shot transformation clip. The carved frame always samples phase A, while the blue fire blends between phases and receives a small flowing shader displacement. The aperture uses `BoxFit.contain` to retain the full video inside the frame.

The app's existing `PracticeDokkaebiFireAction` opens `PracticeDokkaebiIntroduction`, which now starts this introduction automatically. Its Tales, Home & luck, and Learning pal topics, form toggle, learning explanation, and return action remain intact. The replay button starts a fresh one-shot. The frame fits the actual scroll viewport in landscape and keeps its 2:3 proportions; it does not move when the pose changes.

Use `DokkaebiIntro(onFinished: ...)` inside a width constraint; it owns a 2:3 frame. A new widget key replays the introduction. `staticOnly: true`, the app's reduced-motion setting, and the system's reduced-motion setting display the final artwork and call completion once. Decoder failure also shows the final artwork. Playback is muted, does not loop, and uses the shared native video lease. Only the frame flames continue after playback.

The supplied clip is 8.041667 seconds; playback at 1.04 speed lasts approximately 7.73 seconds. The original video bytes are preserved. `final.webp` is its last frame. Source PNGs retain their original alpha and resolution; decoded flame images use 768-pixel width and are disposed on exit. Shader failure retains a Canvas phase animation with the rim pinned.

The contained clip lives under `assets/video/introductions/`: unlike the white-matte character clips, its opaque background is kept inside the decorative aperture and uses no multiply blend. If playback is interrupted by backgrounding or another video, it settles on the final artwork once. Visible decoder contention uses the shared one-shot completion watchdog.

`manifest.json` records the approved frame hashes and phase order. The prompt JSON files preserve generation provenance. Rejected pose and rig experiments are excluded from runtime assets.

The development fixture `tool/dokkaebi_intro_preview.dart` opens the same application sheet, rather than a separate introduction UI. Tests cover application-sheet decoder allocation/release, landscape, dark mode, large text, cultural controls, video completion and failure, reduced motion, frame sequencing, and actual shader pixels: `flutter test test/dokkaebi_intro_test.dart test/practice_dokkaebi_introduction_test.dart`.

The local browser and shader pixel checks verify appearance and stationary frame geometry. Physical-device performance still needs measurement.
