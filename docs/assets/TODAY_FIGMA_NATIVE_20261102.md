# Today: editable Figma and native contract

The editable source is the [Heute/Today page](https://www.figma.com/design/rVlcMLvngw07BYJ7nRT87C?node-id=338-2).
The 32 frames cover DE/EN course examples, review, resuming a started unit,
the selected Magpie, empty reward queues, reduced motion, compact viewports,
and the three actual reward choices and their item-specific receipts.
Reusable paper, gold action and five-image navigation components keep text
and layout editable. Original art is an image fill; an entire UI screenshot
is never the Flutter implementation.

Representative frames:

- [A2 DE](https://www.figma.com/design/rVlcMLvngw07BYJ7nRT87C?node-id=350-145)
- [A2 EN](https://www.figma.com/design/rVlcMLvngw07BYJ7nRT87C?node-id=350-205)
- [320 x 640](https://www.figma.com/design/rVlcMLvngw07BYJ7nRT87C?node-id=365-316)
- [Real reward choices DE](https://www.figma.com/design/rVlcMLvngw07BYJ7nRT87C?node-id=372-329)
- [Real reward choices EN](https://www.figma.com/design/rVlcMLvngw07BYJ7nRT87C?node-id=372-394)

## State and source ownership

`LearningFocusController`, the captured course links and `CourseMissionBrief`
select the actual next activity. Course-unit identity selects editorial copy;
all other units keep their actual localized title and objective. Continue is
shown only when that unit has saved evidence. Due review and Hangul retain
their own destinations. Changing a label never changes assessment, progress
or reward credit.

`today-topic-art.json` records exact source bytes, semantic coverage and
the remaining neutral-book fallbacks. CEFR prefixes and translated titles
never guess an illustration. A captured vocabulary link can specialize art
only through validated vocabulary membership in its real pack.

The Baekho and Magpie use the user's supplied four-by-two expression sheets
from `01a184bb-ba11-7021-8541-686ef9aae8c8`. Contact selects an existing frame;
characters are not redrawn. The exact approved cloud and live wallet are
retained. The Hanok tile is an entrance with confirmed ownership, not an
unearned finished estate.

Today and the reward route use the supplied closed/open Najeon originals.
The reward service still owns the queue, candidate selection, persistence,
recovery and exactly-once claim. Opening the chest grants nothing. A receipt
appears only after a successful save. The old cloth reveal API remains for
existing onboarding callers; this is a presentation change, not feature removal.

## Layout, type and motion

DE uses bundled Belgrano and Encode Sans Condensed; EN uses bundled Chubbo
and Supreme. Figma's font inventory lacks Chubbo and Supreme, so EN Figma
uses Lora and Source Sans 3 as documented substitutes. Figma and native are
not claimed to have pixel-identical English typography.

Native text is measured at its actual size. In short viewports, art yields
space before text and 48dp actions. The normal-text course/Hangul/review
matrix fits 320x640, 375x667, 390x844, 393x873 and 430x932 without scrolling.
At 130 percent and above, natural text flow and scrolling are retained.
Safe areas and the five navigation destinations remain native.

Material press depth, finite chest opening and source-frame contact responses
communicate an action or state. They do not repeatedly move reading content.
Reduced motion, route TickerMode and app background state preserve the same
results while stopping or replacing motion.

Official references checked 2026-11-02:

- [Google: expressive design research](https://design.google/library/expressive-material-design-google-research)
  informed one prominent action, related-content grouping and distinct material
  shapes. These principles are interpreted through jade, hanji, wood and brass.
- [Apple: reduced motion criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria)
  informed reduced-motion parity and avoiding automatic repeating effects.

## Verification boundary

`today_approved_dashboard_test`, `today_subject_art_test`,
`course_mission_brief_test`, the existing adaptive/accessibility tests and
the reward screen/reveal tests exercise source identity, content routing,
saved state, reachability, semantics and motion ownership. Widget captures
use real bundled fonts/content with explicitly seeded account state.

Android's exact-set manifests register the 24 Today and two Najeon artwork
files for managed delivery. Expression sheets remain in the base bundle.
Local manifest/source checks do not prove an uploaded AAB, download size,
physical-device behavior, TestFlight availability or a public release.
Those remain separate exact-commit CI and store gates.
