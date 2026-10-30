# Preserved previous book illustration

`book_extract.webp` was moved unchanged from
`assets/illustrations/onboarding/book_extract.webp` after the approved capture
and study book previews replaced its production consumer. No production Dart
source referred to the old image immediately before the move.

The file matched the tracked original at
`8841f12cbbfc9f82dc26efea860d62038ad6eeed`. Its SHA-256 is
`fcc8d3c0d95493b6e8a596c45bf4197dfca9beb046ce3ed84a65e8dbe6a915e8`.
The original decoded-pixel preservation test still checks this file from its
new location; its expected dimensions and RGBA pixel digest are unchanged.

To restore it, verify the SHA-256, then move it back to the previous path only
when an actual production consumer needs it. That folder remains registered
in pubspec. See `docs/assets/PRESERVED_BOOK_20261030.json` for byte-copy and
recovery evidence. No user source image or current approved book was changed.
