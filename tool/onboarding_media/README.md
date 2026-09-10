# Onboarding companion media import

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
