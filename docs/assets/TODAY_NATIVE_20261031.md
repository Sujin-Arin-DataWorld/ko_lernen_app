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
collection. After the 2026-11-02 user review, the Hanok tile is a crafted gate
entrance rather than a completed-estate preview. Its native count reflects
confirmed ownership and opens the existing R16 destination without awarding a stage.
Quick play selects the existing Games tab. The 60dp image navigation preserves
its 48dp targets and OS insets. Day details retain guide, chosen goals, quests,
drafts, wallet, weekly progress and statistics; the brand opens Profile.

`TODAY_APPROVED_ASSETS_20261031.json` records production art hashes and
provenance. Standalone scene/prop atlases contain art and Korean learning
content, while localized interface text is native. After the 2026-11-02
approved hierarchy revision, DE Belgrano and EN Chubbo are reserved for the
short Today page heading. Functional Today titles, body, metadata and actions
use existing bundled Supreme roles, with the explicit Korean fallback. Other
screens retain their locale typography.
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

The same day's user review identified the portrait's exposed cut edge above
the first card. The unchanged canonical Baekho/Magpie art now aligns to the
bottom of its slot and extends behind the following opaque paper card. This
preserves text, target geometry and the card's original top position. The
viewport/state matrix checks the image-to-card contact in both languages and
at both text scales; native captures verify that the card masks the cut edge.

The user also requested an asset-based Hanok selection box instead of showing
the finished Sarangchae on Today, then rejected a separate dark frame because
its apparent scale did not match Quick play. The replacement `hanok-entrance.png`
is a standalone RGBA illustration generated with the built-in image tool:
an inviting open jade courtyard gate, dark ceramic roof, warm timber threshold,
small plum blossom and folded hanji map, without UI text or a completed estate.
Both entries now use the identical `CPaperPanel`-based discovery component,
allocated height, padding, title row, radius and shadow. The matrix checks equal
outer width, height, top and bottom at every tested viewport/scale. The owned
count and localized title remain native; the whole card announces full localized
progress and opens `/hanok`. Detailed owned R16 construction stays in existing
day-details and Hanok routes. The rejected frame's original is preserved outside
the app bundle; its receipt is marked superseded.

## Today hierarchy revision approved 2026-11-02

The user authorized the concrete hierarchy proposal after reviewing the previous
render. Brand, confirmed wallet and settings share one trailing-aligned toolbar;
quiet wallet presentation and a 28dp settings illustration retain 48dp targets.
The header is 120dp at ordinary text sizes, with an unchanged canonical portrait
grounded behind the first paper card. Duplicate left floral art is removed and
the existing scene fades out behind navigation controls.

Functional text uses shared taskTitle/taskBody/taskLabel/taskCaption roles
(Supreme, actual bundled weights). The task title is 22dp bold; metadata is 13dp
regular and sentence case. Level and available duration occupy a tight trailing
slot aligned to the card content edge. The subject image uses the shared 10dp
detail radius. The gold learning action remains the sole primary action.

Finds is one quiet, tactile paper row with chest, localized title, real pending
count or collection action, and a chevron. Its redundant full-width green action
is removed. Finds and the equal Hanok/Quick play cards use shallow paper depth
and a finite 1dp contact translation; reduced motion and cancellation retain
the same state and navigation. Large text moves Hanok progress below the title
instead of squeezing both into a narrow row. No content, reward or construction
ownership calculation changes.

Official design sources checked 2026-11-02:

- Google expressive hierarchy: https://design.google/library/expressive-material-design-google-research
- Apple layout and alignment: https://developer.apple.com/design/human-interface-guidelines/layout
- Apple functional material layers: https://developer.apple.com/design/human-interface-guidelines/materials

The implementation interprets emphasis, containment and clear control/content
separation using the approved hanji, jade and gold materials. It does not add
glass layers to every card or animate reading content continuously.

Verification receipts and native captures are in native/hierarchy-20261102 and
native/hierarchy-evidence-receipt-20261102.json under the external artifact root.
The state/viewport matrix checks DE/EN, real bundled content and fonts, both
companions, confirmed money, reward routing, title/metadata alignment, equal
discovery-card bounds, 48dp primary targets, contact cancellation and 100/200%
text. Ordinary 390x844 captures fit all dashboard cards without vertical travel;
320px/short windows and large text retain readable scrolling. This evidence is
local Flutter rendering, not Android/iPhone installation or store deployment.
