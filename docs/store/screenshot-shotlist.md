# iOS and iPad Screenshot Shot List

Use this as the capture brief for the final signed iOS build. Screenshot
directories are reserved as
`docs/store/captures/app-store-ios/<locale>/<device>/`; they become valid
submission material only when populated with actual iOS captures.

## Non-negotiable capture rules

- Use a real iOS simulator or device capture from the final candidate build.
- Screenshots captured from non-iOS app builds, web pages, or AI mockups cannot be submitted to App Store Connect.
- Submit 1–10 PNGs per device family, with no alpha channel.
- Capture English and German states separately when both localizations are
  submitted.
- Do not burn marketing copy into the app image. Any optional framing must
  preserve the original alpha-free iOS screenshot and comply with the current
  App Store Connect rules.

## Required 13-inch iPad set

Capture the landscape map first. It is the clearest proof that Hangul Sori is
a learning world rather than a static course list.

| Order | Required size | App state | Suggested caption (DE / EN) |
|---|---:|---|---|
| 1 | 2752 × 2064 landscape | Interactive personal Hanok map; several places visible and a place can be opened | `Dein Hanok wächst mit dir` / `Your hanok grows with you` |
| 2 | 2064 × 2752 portrait | Sarangbang with today's recommended study and a clear start action | `Heute im Sarangbang lernen` / `Study in the Sarangbang today` |
| 3 | 2752 × 2064 landscape | Room furnishing with a real owned decoration and picker state | `Richte deinen Lernort ein` / `Furnish your learning place` |
| 4 | 2064 × 2752 portrait | A themed vocabulary pack or real-life scenario in progress | `Koreanisch für den Alltag` / `Korean for everyday life` |
| 5 | 2752 × 2064 landscape | Progress surface with Hanok growth and a completed quest reward | `Lernen wird sichtbar` / `Make learning visible` |

The first iPad capture is therefore the interactive personal Hanok map in
landscape at 2752 × 2064. Capture both orientations before choosing the final
set, even if App Store Connect ultimately needs fewer images.

## Required 6.9-inch iPhone set

Use the current 6.9-inch iPhone simulator size, `1290 × 2796` portrait or
`2796 × 1290` landscape, from the same final build. Prepare 4–6 distinct
screens from this set:

1. Personal Hanok map, with a clearly reachable place.
2. Sarangbang, showing today's recommended study.
3. Hangul learning or a themed vocabulary pack.
4. A real-life scenario in progress.
5. Bojagi reward or room furnishing.
6. Progress or a completed special quest.

## Before you capture

1. Use a review-safe guest account or a freshly reset simulator state.
2. Verify that the chosen state contains no private test data, placeholder
   images, debug labels, or unfinished translations.
3. Capture only an appearance supported by the final candidate; do not add
   near-duplicate screenshots simply to fill slots.
4. Validate the finished folders with
   `python tool/check_app_store_screenshots.py --target ipad-13 <folder>` or
   `python tool/check_app_store_screenshots.py --target iphone-6.9 <folder>`.
5. Recheck the current Apple screenshot rules in App Store Connect immediately
   before upload.
