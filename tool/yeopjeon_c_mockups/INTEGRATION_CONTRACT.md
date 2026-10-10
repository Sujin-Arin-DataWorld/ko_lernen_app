# Native reward presentation contract

The approved C design is implemented in native Flutter, in C:/dev/hangulsori/ko_lernen_app_worktrees/yeopjeon-c-mockups-20261009, branch session/yeopjeon-c-mockups-20261009, base HEAD 44727c1921b4b7f40748ac0d210d0ca62a094028. Work is uncommitted. HTML remains a separate synthetic prototype. No merge, release or physical-device approval is implied.

## Actual entry points and ownership

| Entry | Actual behavior |
| --- | --- |
| showSoriStageRewardReceipt | Confirmed coin receipts open the full /rewards/yeopjeon Flutter route. Other receipts retain their existing sheet. |
| ContentLessonScreen._finish | Learning saves first. A confirmed grant with an unambiguous claim delta opens the C receipt immediately. Missing measurement or concurrent ambiguity leaves presentation to shell snapshot comparison. |
| LearningJourney.unshown | Subtracts already-visible claim identities and preserves the final wallet and owned construction bounds. |
| YeopjeonWalletBadge | Opens /rewards/ildu-house and refreshes its snapshot owner on return. |
| YeopjeonIlduHouseScreen | Reads saved money, refreshes before confirmation, shows before/after cost, then calls existing YeopjeonService.buildNext. |
| Other rewards | Existing XP, stamp, culture and editor actions remain available. Actual owned bounds survive; replacement Hanok art is withheld in this entry. |

The learning/Yeopjeon services own evidence, claims, allowance, account balance and atomic purchases. Presentation events never grant money. Grant rules and the writer are unchanged. 20 daily coins plus 40 milestone coins can legitimately total 60; labels come from daily:first/second/review and milestone claim identities, never the amount alone.

RewardReceipt now carries optional yeopjeonBalanceBefore and yeopjeonWalletAfter, populated by SoriStageRewardReceiptService.compare. Its receiptId, item identities and owned-stage bounds remain authoritative. canPresentYeopjeon requires positive coin items and a confirmed wallet. canRollYeopjeon also requires before + earned == final balance; missing/mismatched baselines show the confirmed final value immediately.

Account identity and local-data lifetime are captured at entry. YeopjeonSessionGate removes an old-account subtree on identity change. Async media/purchase boundaries reject stale results. Journey presentation deduplication is ephemeral; durable claim deduplication remains owned by the existing service.

## Movie, motion, sound and layout

DokkaebiRewardMovie decodes the approved alpha movie as lossless animated WebP through Flutter: 960x960, 121 frames, 24 fps, 5,041 ms, no crop. Original MP4 and alpha WebM are unchanged. Native playback has no iOS WebM dependency or new VideoPlayerController. Provenance and media hashes are in media-review/flutter-media-report.json.

The widget retains one displayed frame, disposes its predecessor, and draws with BoxFit.contain. It avoids a per-frame Picture.toImage round trip. Codec generations, timers and optional audio are released on finish, skip, route/background loss, reduced motion, stale ownership, failure and disposal. A 9-second fallback is bounded.

The source cue at 3.7 seconds starts seven wallet-local balance steps over 840 ms, four + / ++ pulses and a 200 ms rim response. The final digit width is reserved. Accessibility exposes the confirmed final balance; replay restarts only the movie and skip settles its already-confirmed value. Sound starts muted; optional original audio uses AudioPolicy companion/master settings. Coin taps trigger a finite light response and existing haptics; idle motion pauses when hidden/background/reduced.

Native screens use actual SafeArea, without fabricated clock/island/home indicators. Normal 402x874 DE/EN widget tests reserve 62/34 system space externally, fit both actions without scrolling, and check a 316px square full movie. The progress track is 12px in HTML and Flutter. Secondary/motion actions use 48 logical pixels; primary is at least 54. At 200% real text scale, vertical scrolling preserves readable text and reachable controls.

The whole-house scene has no Sarangchae-specific title, total stage counter, fabric/question placeholder or future silhouette. No replacement Hanok art is connected while approved assets are pending.

## Review boundaries

native_preview.dart runs the actual widgets with synthetic in-memory wallets/purchase callbacks. It never seeds a production ledger. Production defaults use service-backed routes. Review: http://127.0.0.1:8795/?lang=de&safe=1 ; lang=en, view=house, receipt=support and text=2 select cases.

Actual Flutter tests/screenshots are separate from earlier HTML evidence. See NATIVE_IMPLEMENTATION.md and review-proof/. Physical iPhone playback/FPS, audio/haptics, memory, real OS insets and install/device QA remain separate gates. The lossless movie adds approximately 22.6 MB; a smaller replacement needs visual approval.
