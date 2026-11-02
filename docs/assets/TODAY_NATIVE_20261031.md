# Approved Today composition in Flutter

The 2026-10-31 revision implements the approved course, Hangul-introduction and
review compositions in the existing C5 shell. Native labels, targets and
destinations remain owned by `LearningFocusScope`; no translated-title matching
or coffee default selects Today art. Five audited pack IDs use the user's exact
topic originals. Other content keeps neutral book art. The cloud and selected
Baekho/Magpie retain their original bytes and the hidden-companion preference.

The main card contains the actual next learning title, objective, available
duration, subject scene and action. The separate finds card opens pending Bojagi
when their confirmed count is positive, otherwise the user's furnishing
collection. The Hanok tile opens the existing R16 destination; an unbuilt
estate illustration is explicitly labelled Preview and never awards a stage.
Quick play selects the existing Games tab. The 60dp image navigation preserves
its 48dp targets and OS insets. Day details retain guide, chosen goals, quests,
drafts, wallet, weekly progress and statistics; the brand opens Profile.

`TODAY_APPROVED_ASSETS_20261031.json` records production art hashes and
provenance. Standalone scene/prop atlases contain art and Korean learning
content, while localized interface text is native. DE Belgrano/Encode Sans
Condensed and EN Chubbo/Supreme follow the user's existing typography choice.
Static mockup typography is not claimed to be pixel-identical native text.

The responsive layout measures the allocated viewport and actual font metrics.
The illustration yields space before native text or action targets. Large-text
and short-window layouts keep scrolling available. Confirmed wallet feedback
and finite material press responses use the existing reduced-motion/lifecycle
handling; artwork does not continuously move while the user reads.

Official design references checked 2026-10-31:

- Flutter adaptive measurement: https://docs.flutter.dev/ui/adaptive-responsive/general
- Apple motion entry point: https://developer.apple.com/design/human-interface-guidelines/motion

The Flutter reference supports measuring the app window and local constraints,
not inferring layout from device type. Apple's entry point was reachable but
its Markdown content was unavailable to this tool; no new platform-trend claim
depends on that unavailable content.

Evidence is stored in
`C:/dev/hangulsori/_codex_artifacts/today-hanok-image-mockups-20261031/native/`.
The viewport tests use bundled curriculum, actual locale fonts, seeded accounts
and confirmed wallet ownership. They are native widget renders, not physical
Android/iPhone QA. Their scope, image hashes and logs are in
`validation-summary.json`. Store deployment and physical-device installation
remain separate release gates.

## CI recovery, 2026-11-02

The first integrated Linux run at `9465a8c7b` passed 9,317 tests but failed 33.
The failures included stale Today layout/entry assertions and three outdated
Linux golden images, plus real defects: narrow-header overflow, insufficient
brand contrast, two labels below the 13dp floor, a raw modal entry and two
unregistered Sori component files. They were not treated as a successful release.

The header now measures its actual local width and both localized text heights
before using the fixed composition. Narrow or enlarged text can grow naturally;
the canonical portrait yields width first. Brand text uses the existing light
paper ink on jade, both small labels use 13dp, and day details use `showSoriSheet`
with an owned presentation that retains the user's text scaler. Existing guide,
construction ownership, reward semantics, launch/return and no-duplicate-companion
tests follow the details entrance or the new native learning card; their state
and navigation assertions remain intact. The component inventory includes both
Today card and semantic subject-art mapping.

Flutter's adaptive measurement guidance was checked again on 2026-11-02:
https://docs.flutter.dev/ui/adaptive-responsive/general . The concrete decision
is to measure the parent's constraints and laid-out text, rather than infer the
layout from a phone model. Linux comparison baselines must come from the pinned
CI renderer; Windows captures remain separate review evidence.
