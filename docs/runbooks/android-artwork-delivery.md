# Android artwork delivery

Google Play limits the compressed download of each base/feature module to
500 MB. The approved artwork exceeded the base limit when shipped together.
Do not reduce approved image quality or remove learning features to pass this
limit.

## Packaging contract

- Public release AABs put the complete R16 catalog in the `c_artwork` feature.
  It is installed unconditionally with the application, including API 24/25.
  No download, permission, or uninstall flow is added to the app.
- `dist:removable=true` keeps this install-time module separate from base.
  `dist:fusing=true` includes its artwork in bundletool universal APKs.
- The module contains the original files at the same
  `flutter_assets/assets/illustrations/ildu_r16/` keys. The asset index stays in
  base, and Android's package AssetManager sees the already-installed split.
- Ordinary APK builds and Flutter device runs retain the artwork in base.
  A split AAB must be installed as a complete APK set or as its fused universal
  APK; extracting only its base component is not an application installation.
- Unused authoring files and identical material aliases remain preserved in
  Git. Their exact sources and hashes are recorded in
  `docs/assets/APPROVED_BUNDLE_SIZE_20261030.json`.

## Release checks

The public testing workflow checks the actual signed AAB before upload:

1. Every catalog artwork payload must occur exactly once in `c_artwork`, with
   its original SHA-256, and never as a duplicate base payload.
2. The built module manifest must retain unconditional install-time delivery,
   separate-module packaging, universal inclusion, and `hasCode=false`.
3. bundletool measures initial download size across ABIs. This includes all
   mandatory install-time modules even when a base-only selection is requested.
   A conservative base upper bound removes only the smallest mandatory artwork
   contribution from the largest initial download; other installed modules
   remain in the bound. It must not exceed 490 MB, leaving a margin below Play's
   own calculation. The report explicitly identifies this as an upper bound.
   The exact pinned bundletool size API and complete APK table of contents are
   checked by `tool/AndroidArtworkDownloadSize.java`.
4. Inspect/install the complete Play update while preserving account, learning
   progress, purchases and wallet state. Confirm artwork loads offline through
   the existing Hanok/Gye routes. Store acceptance and native device verification
   are separate from a successful local build.

The workflow preserves the AAB identity, module manifest and size evidence.
Its APK set and temporary measurement signing key are local build products and
are never uploaded as the release artifact.

AGP emits a 748-byte generated `c_artwork.R` DEX marker even though the module's
manifest declares `hasCode=false`. Its only constructor calls `Object.<init>`
and returns; it has no fields, interfaces, or application behavior. The verifier
pins its complete reviewed SHA-256 and rejects other DEX/native code. Compiler
changes require inspecting a new marker rather than automatically replacing
the pin. Reports distinguish this resource marker from application code and
do not claim that the feature contains zero DEX files.

Official references checked 2026-10-30:

- [Play app size limits](https://support.google.com/googleplay/android-developer/answer/9859372?hl=en-GB)
- [Install-time feature delivery](https://developer.android.com/guide/playcore/feature-delivery/install-time)
- [App Bundle format and fusing](https://developer.android.com/guide/app-bundle/app-bundle-format)
- [AGP 9 public asset transformation recipe](https://github.com/android/gradle-recipes/tree/agp-9.0/transformDirectory)
- [bundletool download estimates](https://developer.android.com/tools/bundletool)
