# Compact native and browser structure
The actual C-design render is the authority.

| Order | Confirmed reward | Ildu house |
|---|---|---|
| System space | Review reserves 62 / 34 logical pixels | Same |
| Header | Brand/title left, wallet right; large text uses two rows | Same |
| Earning event | Full 960² movie contained in 220² on the left; 8 gap; 112-wide earned amount on the right | Question before tactile coin; future form hidden |
| Receipt | Standby Reward/Belohnung, then +0 to actual earned amount; reason below the event with 4 gap | Saved build progress after confirmed spending |
| Goal | Actual funds, cost 40 and learning eligibility | Cost and next learning gate |
| Actions | Visit when eligible, continue learning immediately | Explicit before/after confirmation, then service-backed build |
| Review tools | Separate QA panel; absent from the production receipt | Same |

The standalone iPhone16Pro HTML canvas is exactly 402×874 CSS pixels with no zoom or transform. Its width and height do not shrink with the browser window. A smaller desktop window may scroll the external review page; the normal app canvas has no internal scroll. Production Flutter uses actual platform SafeArea.

The normal event is 220 + 8 + 112 = 340 wide. It has a natural height; removing the 48-high media-control row leaves no empty reserved slot. The amount uses a fixed 44sp tabular-number slot, with a 30dp coin above and a 14sp currency label below. The whole source movie remains contained, with no crop or perspective transform.

Primary CTA minimum54, secondary48, gap8. Goal-to-actions10. Latest normal HTML14-state matrix has no main, canvas-horizontal or page overflow at 402×874, minimum target48, and at least19px between the second CTA and the bottom system area. The compact reward uses the space it needs; the rest of the jade canvas remains still.

Flutter measures the non-hero tail and shrinks the complete square on shorter screens. Above130% text, the header stacks and the movie/amount stack. Real200% text is explicitly marked QA and may scroll to preserve readable copy and actions. The fixed-size HTML preview does not simulate a different phone when its browser window is shorter.

Future house stages remain secret. No cloth cover, fixed Sarangchae name, stage total or future gallery is connected. See C_STYLE_CONTRACT.md, MOTION_SPEC.md and QA.md.
