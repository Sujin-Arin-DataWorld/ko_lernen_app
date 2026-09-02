# C1 listening source originals

This directory preserves the 11 supplied C1 PNG source files outside the
Flutter asset bundle. The app's canonical runtime files remain
`assets/illustrations/listening/C1*.webp`; do not add this directory to
`pubspec.yaml` and do not copy these PNGs back into
`assets/illustrations/packs/`.

`MANIFEST.json` locks each source PNG to its current runtime WebP by path,
SHA-256, byte count, and dimensions. `C1Briefing.webp` is a runtime card but
was not part of this 11-file source drop.

This package records source provenance; it does not define the generation
rules for future cards. The `historicalDerivativeFacts` in the manifest
describe the already-registered `C1-source-original` derivatives. New or
regenerated cards must follow the current authority order:
`docs/LISTENING_CARD_RECIPE.md`, then `docs/assets/STYLE_LOCK.json` for locked
numeric values. Validate the resulting card set with:

```powershell
python tool/check_card_style.py --all
```
