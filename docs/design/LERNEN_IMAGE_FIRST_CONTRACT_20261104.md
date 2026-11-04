# Lernen image-first implementation contract

This release carries the approved Hören, Grammatik, Nuancen and Alltagsszenen designs into editable Figma and native Flutter. Original generated mockups remain the visual authority; screenshots in this directory are implementation evidence. Existing lesson data, A1–C2 levels, persisted progress and rewards retain their current owners.

## Figma

File: https://www.figma.com/design/zhJY0ZY4gl4VNg8vaaNIXw/

| Content | Editable section | Original/reference section |
| --- | --- | --- |
| Hören | recovery frames 56:35, 56:74, 56:113, 56:152 and existing player frames | 56:196 original asset inventory |
| Grammatik | 102:160 | approved image-first references retained in file |
| Nuancen | 111:192 | approved knot-and-word relationship boards retained in file |
| Alltagsszenen | 129:311 | 140:585, including three approved original boards |
| Next content candidates | image review only | 140:586: Wortpakete 139:590, Wiederholen 139:591 |

Alltagsszenen includes entry, dialogue, vocabulary, grammar, roleplay, optional writing, listening, sentence construction, dictation, saving, save failure, completion, filtered catalogue, translation, cloze and topic picker, plus a separate first-turn unanswered roleplay frame (167:606). Body content is scrollable; long source content is never truncated to fit a screenshot. Editable original PNG layers, text and controls remain separate. The Hanok completion action is implemented by native routing; the incorrect Figma Lernen destination was removed.

## Visual and interaction rules

- Baseline: 402×874, German, 100% text, no OS inset in comparison fixtures. Small-screen and enlarged text are separate QA cases, not alternate visual authority. Short/enlarged roleplay must use the actual available body constraints and keep a whole tile, answer tray and action scrollable into view.
- Canonical cloud/settings/coin/home and five navigation icons are the original PNGs. The cloud drawn inside generated mockups is not a replacement asset. Five tabs have no visible labels and at least 48dp targets.
- Shared navigation has a 68dp content-and-bottom-padding specification; the native paper border adds its decoration inset, plus device safe area. Footer keeps at least 16dp after the full CTA/shadow before navigation. Scroll content is clipped above the fixed footer; large text remains scrollable.
- Folded hanji uses the original 2206×713 material with a fixed nine-slice bevel: source cuts x=132/2076, y=102/564, scale8 (scale16 for small tiles). No stretched thick border or repeated nested card. Roleplay and sentence construction use independent gold-rim ivory word tiles and a muted jade answer tray; optional writing uses its independent oak-and-hanji board. Speaker names use the original jade/brass plaque. These materials come from the approved roleplay/writing image, not a reused generic paper card.
- Original kitchen material is only used for a2_minho_weekend_cooking_plan. Minho and Andrea are original independent persona PNGs, layered behind the counter. Other scenes retain their actual persona/content mapping.
- Topic cards use ListeningObjectArt with the real topic ID, Lora18, Manrope14 and 96dp object art. The filtered A2 first six counts are 4/1/1/3/2/1; raw source inventory counts must not be presented as playable counts.
- Nuancen keeps original frames and knots; the central cord and coral/indigo branches express relation types. The source word, its four relations, examples, audio and speed remain native and editable.

## Preserved source contracts

The cooking scene contains eight turns, four learner turns, six quests and six source vocabulary tokens. The grammar preview resolves grammar_a2_promise from the existing CSV (V-(으)ㄹ게요). All supported question renderers retain their inputs, distractors, grading and feedback; unanswered listening and dictation do not expose the hidden Korean answer. Shared quest presentation changes are opt-in through ScenarioCTheme, preserving other callers.

Optional writing uses the last authored learner turn and its authored translation. Checking is unscored. Check, explicit model download, unavailable fallback and skip follow actual service state; no mocked grading or silent download.

Saving uses the existing typed course context, evidence and persistence. Pending disables duplicate actions; failure retains the work and exposes an immediately tappable retry. Ordinary practice and active course checkpoint completion remain distinct. Home, close, confirmed tab exit, route changes and app background retain audio and navigation ownership. An embedded onExit callback is exclusive.

## Motion sources and application

Official sources checked 2026-11-04:

- https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria/
- https://github.com/material-components/material-components-android/blob/master/docs/theming/Motion.md

Alltag playback controls use a minimum 72×48 folded-paper speed button and a 48dp ivory/brass replay disc. The shared TTS notifier, preset sheet and callbacks remain the sole owners; the decorative disc adds no second replay handler.

Use brief state-driven press depth and selection changes through existing Sori motion components. Feedback follows actual selection, playback and save state. Decorative movement does not shake lesson text/input. Reduced motion retains the same final state and actions; route/background transitions stop owned speech. Semantic motion durations are preferred over unrelated per-screen timings. No continuous decorative animation was added.

## Evidence boundaries

ALLTAG_MATERIALS_20261104.json maps exact source image hashes and Figma nodes. ALLTAG_VERIFICATION_20261104.json records final tests/review and render evidence. The earlier LERNEN_VERIFICATION_20261104.json belongs to the previous 722dac7 source snapshot; its APK is not proof of this later source.

Image identity, measured geometry, functional tests and Figma/Flutter renders are separate evidence. Literal 100% pixel identity, physical-device QA and App Store/Play publication are not asserted. New Wortpakete and Wiederholen boards remain review candidates; their native screens are not replaced by unapproved designs.
