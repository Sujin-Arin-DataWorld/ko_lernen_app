# iOS and iPad Screenshot Shot List

Use this as the capture brief for the exact green-main iOS simulator build. Screenshot
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

Capture five current learning surfaces in portrait at 2064 × 2752. The
automated capture uses a newly created iPad Pro 13-inch (M4) simulator and the
same app binary as the iPhone set.

| Order | Required size | App state | Suggested caption (DE / EN) |
|---|---:|---|---|
| 1 | 2064 × 2752 portrait | Learn catalog with current activity choices | `Dein Koreanisch, dein Weg` / `Learn Korean your way` |
| 2 | 2064 × 2752 portrait | A1 learning phases from the bundled catalog | `Klare Ziele von A1 bis C2` / `Clear goals from A1 to C2` |
| 3 | 2064 × 2752 portrait | A real Phase reading task and its teaching material | `Verstehen und direkt üben` / `Understand, then practise` |
| 4 | 2064 × 2752 portrait | The current themed vocabulary catalog | `Wortschatz für deinen Alltag` / `Vocabulary for everyday life` |
| 5 | 2064 × 2752 portrait | Airport real-life scenario introduction | `Übe echte Situationen` / `Practise real situations` |

## Required 6.9-inch iPhone set

Use the iPhone 16 Pro Max simulator at `1320 × 2868` portrait from the same
exact app binary. Capture the same five learning surfaces in DE and EN so the
device sets remain truthful and directly comparable. No earned reward,
furnishing, paywall, or unfinished Hanok image belongs in this release set.

## Before you capture

1. Use the workflow's freshly created simulator and local returning-guest state.
2. Verify that the chosen state contains no private test data, placeholder
   images, debug labels, or unfinished translations.
3. Capture only an appearance supported by the final candidate; do not add
   near-duplicate screenshots simply to fill slots.
4. Validate the finished folders with
   `python tool/check_app_store_screenshots.py --target ipad-13 <folder>` or
   `python tool/check_app_store_screenshots.py --target iphone-6.9 <folder>`.
5. Recheck the current Apple screenshot rules in App Store Connect immediately
   before upload.

The manual `.github/workflows/app_store_screenshots.yml` workflow accepts only
a full SHA on `main` with successful exact-SHA push CI. Its receipt records the
source, Xcode and simulator versions, device identities, locale, dimensions,
RGB PNG hashes, validator result, and driver logs.
