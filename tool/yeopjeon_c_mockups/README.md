# Hangul Sori · C-design learning rewards

The German/English HTML prototype and actual Flutter widgets share jade, paper and brass materials, a complete Dokkaebi movie, wallet-local credit motion and tactile actions. The design contract is [C_STYLE_CONTRACT.md](C_STYLE_CONTRACT.md); actual verification and its limits are in [QA.md](QA.md).

## Open the screens

- [German HTML reward](http://127.0.0.1:8793/refined.html?solo=1&view=reward&lang=de)
- [English HTML reward](http://127.0.0.1:8793/refined.html?solo=1&view=reward&lang=en)
- [German HTML house](http://127.0.0.1:8793/refined.html?solo=1&view=estate&lang=de)
- [German native Flutter reward](http://127.0.0.1:8795/?lang=de&safe=1)
- [English native Flutter reward](http://127.0.0.1:8795/?lang=en&safe=1)
- [Flutter large-text QA](http://127.0.0.1:8795/?lang=en&safe=1&text=2)

Normal review is100% text at402×874. Standalone HTML fixes the full phone canvas at those dimensions; it does not resize its internal layout to the desktop window. Review-only safe=1 reserves 62/34px system space; production Flutter uses actual platform SafeArea. Large-text review preserves genuine enlarged text and reachable actions through scrolling, with an explicit QA label. The synthetic default receipt is 70 → 90, +20, with an earned construction entitlement. It never seeds an account ledger.

## Run locally

From this folder:

    rtk proxy python -X utf8 server.py

From the worktree root:

    rtk proxy C:/Users/vjinn/flutter/bin/flutter.bat run --no-pub -d web-server --web-port 8795 --web-hostname 127.0.0.1 -t tool/yeopjeon_c_mockups/native_preview.dart

The first completed lesson plays the complete movie on the left once. At3.583s the earned amount on the right counts +0→the confirmed amount on the wallet's840ms clock. No replay/motion row is shown in production. HTML playback QA lives in Review; native ?reviewControls=1 exposes labelled QA-only controls. Replay is cosmetic. Touching the coin changes its light and depth; building uses a cost confirmation and a durable production callback. Review controls expose DE/EN, seven receipt states, real text enlargement and reduced motion. play=0 freezes the HTML review; the normal experience retains playback.

## Media and source ownership

The original MP4 and supplied CTA/coin/material PNGs are preserved. The movie matte changes alpha only. Native lossless animated WebP is made directly from original decoded MP4 RGB plus alpha: all 121 visible frames compare exactly to those decoded original colors. HTML VP9 compression can introduce encoding differences; no grading, saturation filter or spill-color correction is applied. Both renderers contain the entire 960×960 canvas.

Media evidence: [video-alpha-report.json](media-review/video-alpha-report.json), [flutter-media-report.json](media-review/flutter-media-report.json), [asset-provenance.json](asset-provenance.json).

Current reward capture authority is review-proof/proof-final-native-de.jpg, proof-final-native-en.jpg, proof-final-html-de.jpg and proof-final-html-en.jpg (each402×874), plus proof-final-html-200-en.jpg (402×1241, explicit large-text QA). Native CTA normal/pressed/expanded captures and normal house-flow captures remain valid for their unchanged components. Earlier playing, vertical-layout, proof-native-*, proof-iphone-* and rejected boards document history and are not current reward-layout authority. The portable package includes the audit inventory, contact sheets and selected original reference boards. The audit reviewed 596 files / 555 unique images through 24 sheets and selected full-resolution references; it did not inspect every image at full resolution.

The Hanok catalogue has zero approved replacement assets. Future construction forms remain secret, with no old Hanok preview or fixed Sarangchae title. New canonical art needs separate approval before connection.

## Implementation and verification

[NATIVE_IMPLEMENTATION.md](NATIVE_IMPLEMENTATION.md) maps the widgets and production connections. [INTEGRATION_CONTRACT.md](INTEGRATION_CONTRACT.md) defines wallet/state ownership; [MOTION_SPEC.md](MOTION_SPEC.md) defines choreography. Copy the entire package to keep local media/fonts/provenance intact. Historical generation scripts must not overwrite the current contract.

    rtk proxy node --check refined.js
    rtk proxy python -X utf8 verify_package.py
    rtk proxy python -X utf8 verify_hanok_assets.py

PACKAGE_MANIFEST.json records portable file hashes. Server logs are volatile and excluded. Physical-device frame pacing, memory, audio synchronization, haptics, VoiceOver/TalkBack and install QA remain separate from browser and widget validation.
