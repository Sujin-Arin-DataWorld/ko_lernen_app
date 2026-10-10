# Native Flutter implementation

This folder includes the approved HTML and native Flutter implementation. Synthetic review balances are not account data.

## Run the actual widgets

Workdir: C:/dev/hangulsori/ko_lernen_app_worktrees/yeopjeon-c-mockups-20261009

    rtk proxy C:/Users/vjinn/flutter/bin/flutter.bat run --no-pub -d web-server --web-port 8795 --web-hostname 127.0.0.1 -t tool/yeopjeon_c_mockups/native_preview.dart

Default is the German first-lesson movie. URLs: ?lang=en&safe=1, ?lang=de&safe=1&receipt=support, ?lang=en&safe=1&view=house. Browser-only safe=1 reserves 62/34 system space without fake OS UI. Production uses actual platform insets. Preview callbacks only change an in-memory fixture; no production ledger is seeded.

Production needs no WebView. The receipt helper selects a full native route after confirmed coins, content lessons open it after a durable grant, and the wallet header opens the house route. Existing learning feedback and other rewards remain intact.

## Source map

| Source | Responsibility |
| --- | --- |
| lib/screens/sori_stage/yeopjeon_reward_screen.dart | Actual claim labels, movie/coin response, confirmed balance and navigation |
| lib/screens/sori_stage/yeopjeon_ildu_house_screen.dart | Whole-house anticipation, saved wallet, explicit confirmation and durable build |
| lib/widgets/sori/yeopjeon_reward_style.dart | Scoped jade/paper/brass materials, 12px bar, responsive geometry and tactile actions |
| lib/widgets/sori/dokkaebi_reward_movie.dart | Full-frame alpha playback, cue, mute/replay/skip and cleanup |
| lib/widgets/sori/yeopjeon_credit_badge.dart | Fixed earned count and shared finite wallet-local symbols/digit rolling; no business writes |
| lib/widgets/sori/yeopjeon_coin_scene.dart | 3D coin interaction with visibility/reduced-motion gates |
| lib/widgets/sori/yeopjeon_session_gate.dart | Removes stale account presentation |
| assets/animations/rewards/ | Approved full-frame alpha movie, opt-in original audio, posters and material/coin assets |

The visual implementation contract is [C_STYLE_CONTRACT.md](C_STYLE_CONTRACT.md). Every CTA height uses one continuous interior, a fixed outer frame with even-odd clipping and a separately clipped cloud ornament on one canvas. Opaque paper control/goal faces prevent the underside shadow from tinting the whole face. Pane/wallet depth is 6dp/3dp; primary/secondary actions use 3dp/1.5dp depth, .988 contact scale, 80ms press and 240ms return through opt-in SoriPressable settings. Defaults of unrelated controls are preserved. Labels remain live 16sp text; the 220² complete movie sits left of the 112-wide amount, with8dp between.
No media-control row is rendered in production. reviewControls defaults false;
?reviewControls=1 opens an explicitly labelled Playback QA preview. HTML puts
replay/skip and optional sound in the separate Review panel. The reason sits4dp
below the event. Production motion follows the existing settings and lifecycle.

Media provenance is in media-review/flutter-media-report.json. Native lossless WebP is generated from original MP4 decoded RGB plus an alpha-only matte, not from the compressed WebM. All 121 visible decoded frames match the original RGB exactly. The original source and material PNGs are unchanged. Future Hanok forms stay secret and pending replacement images remain disconnected.

## Validation

Tests use real fonts and native safe-area constraints. They cover DE/EN viewport fit including QA-only playing DE/EN controls, 220px full square movie, 12px bar, 200% real text, standby-to-zero-to-confirmed count, stable numeric slot, repeated-credit prevention, executable semantics taps, explicit cost, pending/double-tap purchase, unknown result retention, account switch cleanup, other rewards and learning-journey identity subtraction.

Flutter codec tests decode all 121 real frames, checking 960x960 dimensions, first/middle/final alpha corners and 5,041 ms duration. Playback tests cover the real cue, replay/skip, missing media and stale lifetime.

Current command evidence is in review-proof/final-native-analysis.log and final-native-tests.log. The additional tactile test verifies actual held-contact movement, safe cancellation and exactly one activation on release; optional CAPTURE_YEOPJEON_CTA=1 exports real widget rendering for normal, held and expanded states. Current actual browser captures use proof-final-native-* / proof-final-html-*. Older proof-native-* and proof-iphone-* are historical.

Earlier business regression evidence remains in native-reward-regression.log (68 passed), native-focused-tests.log (75 passed, overlapping) and native-owner-regression.log (37 passed). These earlier runs establish their tested changes at that point, not physical-device approval or the latest material pixels.

The app designer's source findings were repaired: semantic taps, stale media cleanup, sound indicators, duplicate visit/retry locks, original owned bounds and video-space budget. Physical iPhone FPS/audio/haptics, real safe areas and install QA remain unverified. Work is uncommitted; main and release remain separate.
