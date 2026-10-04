# Approved Dokkaebi introduction

The 16 transparent flame phases surround the existing one-shot transformation clip. The carved frame always samples phase A, while the blue fire blends between phases and receives a small flowing shader displacement. The aperture uses `BoxFit.contain` to retain the full video inside the frame.

Use `DokkaebiIntro(onFinished: ...)` inside a width constraint; it owns a 2:3 frame. A new widget key replays the introduction. `staticOnly: true`, the app's reduced-motion setting, and the system's reduced-motion setting display the final artwork and call completion once. Decoder failure also shows the final artwork. Playback is muted, does not loop, and uses the shared native video lease. Only the frame flames continue after playback.

The supplied clip is 8.041667 seconds; playback at 1.04 speed lasts approximately 7.73 seconds. The original video bytes are preserved. `final.webp` is its last frame. Source PNGs retain their original alpha and resolution; decoded flame images use 768-pixel width and are disposed on exit. Shader failure retains a Canvas phase animation with the rim pinned.

The contained clip lives under `assets/video/introductions/`: unlike the white-matte character clips, its opaque background is kept inside the decorative aperture and uses no multiply blend. If playback is interrupted by backgrounding or another video, it settles on the final artwork once. Visible decoder contention uses the shared one-shot completion watchdog.

`manifest.json` records the approved frame hashes and phase order. The prompt JSON files preserve generation provenance. Rejected pose and rig experiments are excluded from runtime assets.

Local fixture: `flutter run -d chrome --target tool/dokkaebi_intro_preview.dart`. Tests cover video completion and failure, reduced motion, frame sequencing, and actual shader pixels: `flutter test test/dokkaebi_intro_test.dart`.

The local browser and shader pixel checks verify appearance and stationary frame geometry. Physical-device performance still needs measurement.
