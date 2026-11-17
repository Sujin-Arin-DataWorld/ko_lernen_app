# R16 transparent presentation assets

[SARANGCHAE_TRANSPARENT_V1.json](SARANGCHAE_TRANSPARENT_V1.json) identifies the native-derived Sarangchae construction images: the existing 16 process IDs in their canonical order, plus the standalone full exterior. It records the foreground and shadow paths, SHA-256, dimensions and byte counts in a fixed private archive commit. This keeps large float32 preservation data outside the mobile app bundle and avoids restoring the retired 40 GB R12 workspace.

The integration baseline is main `eb64f24f37fb6a04dd7bf66de75f7876c87472f5`. Preserve its ancestry and existing account/backup, pronunciation blocking, recording protection and character corrections when adding the presentation. A release built from that baseline alone does not include subsequent presentation integration. Publish the final combined main only after its exact-SHA checks; verify the final uploaded AAB retains the original 135 R16 WebP hashes and catalog. Runtime packaging and store availability are separate from this source contract.

## Provenance and restoration

- Repository: private `Sujin-Arin-DataWorld/hangulsori-archive`.
- Derivative archive: `b0e267a2ed48f589c9f487c180a2eb30ce4ed2a2`, ref `archive/ildu-r16-live-gye-20261030`.
- Complete delivery manifest: `native-derivatives/DELIVERY.json`, SHA-256 `8d9ac12234f6e294422e8e9e35056ae58a707c3022ad1e20bd62ce851e35ee01`.
- File inventory: `PRESERVATION_MANIFEST.json` in the same fixed commit. Every payload's Git path, bytes, SHA-256 and blob ID are recorded.
- Native source archive: `a3ebf0c614ccec1864324f6e2641c9f895ddaf6f`, ref `archive/ildu-r16-roofs-20261029`. Source `.blend` hashes are recorded per row in the contract. Use the existing R16 roof restore tools for those inputs.

Fetch the named archive ref using the existing private remote and access controls. Read payload bytes with `git show <fixed-commit>:<archivePath>` through a binary-safe subprocess or Git library. Check the contract's SHA-256 and byte count before writing into a new extraction directory; never overwrite the current app catalog or canonical source. Archive paths are relative and do not depend on a developer's local drive.

The archive includes the verified foreground PNGs, exact flat shadow EXRs, bounded Raw PNG companions, native render/extraction scripts, scene inspection and verification receipts. Noisy multipart EXRs and isolated Python dependencies are regenerable local intermediates, not app delivery assets. The exact float32 channel copies are preserved even though the app may use only foreground PNGs or reviewed, encoded derivatives.

## Composition requirements

Both layers retain the complete **1800 × 1200** canvas. Use the same contain rectangle and alignment; do not trim either layer independently. Geometry, UVs, materials, camera, lights, native files and the complete standalone roof are preserved. The non-canonical studio plane remains physically present for illumination and becomes a shadow catcher; actual stone platforms, stairs and floors remain foreground architecture.

The foreground RGBA PNG already includes the native AgX / Medium High Contrast / +0.2 exposure display conversion. Do not tint it with another paper background or apply another tone map. All 17 foregrounds passed alpha/hash checks, and all 17 flat shadow EXRs preserve the native R/G/B float32 channel bytes exactly. Native stage 1 has zero architectural meshes and an entirely transparent foreground. For owned 0/1, retain the existing lock/progress message and omit its studio-only shadow; do not invent a ruin, stake or future building.

The shadow EXR is **scene-linear float32 numeric data**. Its Raw RGB16 PNG companion cannot retain values above 1 or below 0; each row records the clipped-pixel count and RGB ranges. Ordinary sRGB Canvas multiplication is a visual approximation, not HDR or scene-linear equivalence. Do not draw the multiplier as an opaque image. At locked-state opacity `o`, preserve neutral white with `1 + o * (M - 1)` and multiply foreground alpha by `o`; scaling all shadow RGB values by opacity darkens the whole canvas.

The source-preserving derivative checks do not approve Flutter composition, decoder precision, visual parity, physical-device behavior or a new story/economic policy. A runtime integration must retain the original 135 WebP bytes/catalog and existing learning, ownership, wallet and Gye state, maintain a separate reviewed derivative manifest, and verify actual renders including empty, middle and completed states. No ready approved transparent whole-estate image was found among the published canonical estate outputs; this contract does not substitute a newly generated estate.
