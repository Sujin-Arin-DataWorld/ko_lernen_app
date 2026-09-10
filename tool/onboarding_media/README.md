# Onboarding companion media

## Bundled choose gestures

The onboarding currently uses the original `tiger_choose.mp4` and
`magpie_choose.mp4` gestures, including Joy's front-facing greeting. These H.264
sources have an opaque white stage. `prepare_choose_videos.py` is a separate,
source-specific video preparation tool: it isolates their silhouettes, retains
white fur and feathers, removes white spill only at translucent edges, and
encodes the complete gestures as one-shot Animated WebP. It does not modify the
source MP4 files or accept generated still images.

```powershell
python tool/onboarding_media/prepare_choose_videos.py --review-dir C:\path\to\choose-review
```

This command requires NumPy, SciPy, Pillow, and ffmpeg. The output directory is
`assets/illustrations/onboarding/companions`. Both clips use a fixed 640px square
canvas at 15 fps, preserving framing across all frames. Taego's clip lasts about
4.9 seconds and Joy's about 7.1 seconds. Each animation must stay below 3 MB;
`choose_manifest.json` records source/output hashes, dimensions, duration, alpha
ranges for every frame, and memory estimates. The idle PNGs are extracted from
these same prepared gestures. Selection and confirmation each play the choose
gesture once; idle, reduced motion, background state, and media errors display
the PNG. No multiply blend is applied by the app.

After regenerating, inspect the contacts on light and dark backgrounds under
`--review-dir` before accepting new outputs. This matte is specific to the two
authored videos and is not a general replacement for author-supplied alpha.

## Import author-supplied alpha media

This tool accepts final artwork that already has real transparency. It converts
an alpha MOV or a numbered PNG sequence into an animated WebP and extracts a
PNG poster. It never removes a background, keys a color, adds a matte, applies a
blend mode, or edits the artwork's colors.

## Input

- Alpha MOV: pass the file path to `--input`.
- PNG sequence: pass a directory containing at least two contiguous,
  zero-padded files such as `frame_0001.png`, `frame_0002.png`.
- The source must contain both visible and transparent pixels. An opaque RGB
  render, including a checkerboard baked into the pixels, is rejected. A file
  extension or alpha-capable pixel format alone does not pass; every frame is
  decoded to RGBA and its alpha samples are inspected.
- At least one pixel must have alpha 0 and at least one must have alpha above 0.
  Every frame must stay inside one fixed canvas and contain visible pixels;
  fully transparent padding frames are rejected.
  The report records the union alpha bounds so framing can be reviewed.

The current concept files are RGB/checkerboard previews, so they are intentionally
unsupported inputs. Export clean alpha from the authoring source before import.

The scripts require Python 3, `ffmpeg`, `ffprobe`, and Pillow. ffmpeg performs
source decoding, scaling, poster extraction, and WebP encoding. Pillow validates
the animated WebP because ffmpeg's WebP demuxer does not expose ANMF frames.

## Import command

Run from the repository root:

```powershell
python tool/onboarding_media/optimize_onboarding_media.py `
  --input C:\path\to\taego_idle_alpha.mov `
  --output-dir assets/illustrations/onboarding/companions `
  --basename taego_idle `
  --report C:\path\to\receipts\taego_idle.json
```

For a PNG sequence, use its directory as `--input`. Valid basenames are
`taego_idle`, `taego_select`, `taego_confirm`, `joy_idle`, `joy_select`, and
`joy_confirm`. The output is `<basename>.webp`. Importing an `idle` clip also
creates the shared `<character>_idle.png` poster. A `select` or `confirm` import
requires that idle poster to exist, validates it, and leaves it byte-identical.
Existing animation files are preserved unless `--overwrite` is explicitly
supplied. Import each character's approved idle clip first.

Defaults are 15 fps, maximum side 960 px, WebP quality 82, animation size
1,500,000 bytes, poster size 600,000 bytes, and a 16 MiB two-frame resident
estimate. Duration limits are 3000 ms for idle, 1200 ms for select, and 1800 ms
for confirm. All limits can be tightened with CLI flags. Scaling uses Lanczos,
preserves aspect ratio, and never enlarges the source.

The JSON report includes dimensions, decoded frame count, duration, alpha range,
alpha content bounds, encoded bytes, one-frame RGBA bytes, two-frame resident
estimate, and the hypothetical cost of holding every decoded frame. The Flutter
widget holds only the current frame and codec; it does not predecode the whole
animation.

## Validate an existing file

```powershell
python tool/onboarding_media/validate_onboarding_media.py `
  assets/illustrations/onboarding/companions/taego_idle.webp

python tool/onboarding_media/validate_onboarding_media.py `
  assets/illustrations/onboarding/companions/taego_idle.png --poster `
  --max-bytes 600000
```

Validation fails for opaque media, empty media, a one-frame animation, dimensions,
duration, encoded bytes, or estimated resident memory above the selected limits.

## Tool tests

```powershell
python -m unittest discover -s tool/onboarding_media -p "test_*.py"
```
