# compose_home_hero_hanji.py

> 24 nodes · cohesion 0.17

## Key Concepts

- **compose_home_hero_hanji.py** (15 connections) — `tool/compose_home_hero_hanji.py`
- **compose_clip()** (10 connections) — `tool/compose_home_hero_hanji.py`
- **background_mask()** (7 connections) — `tool/compose_home_hero_hanji.py`
- **flood_from_border()** (7 connections) — `tool/compose_home_hero_hanji.py`
- **load_rgb_frames()** (7 connections) — `tool/compose_home_hero_hanji.py`
- **probe_wh()** (7 connections) — `tool/compose_home_hero_hanji.py`
- **treat_white_matte_frame()** (7 connections) — `tool/compose_home_hero_hanji.py`
- **ndarray** (7 connections)
- **cool_floor_ratio()** (5 connections) — `tool/compose_home_hero_hanji.py`
- **TreatWhiteMatteFrameTest** (4 connections) — `tool/test_compose_home_hero_hanji.py`
- **encode_rgb_clip()** (4 connections) — `tool/compose_home_hero_hanji.py`
- **_disk()** (4 connections) — `tool/test_compose_home_hero_hanji.py`
- **.test_blue_ground_shadow_is_wiped_to_hanji()** (4 connections) — `tool/test_compose_home_hero_hanji.py`
- **Path** (4 connections)
- **dilate()** (3 connections) — `tool/compose_home_hero_hanji.py`
- **.test_enclosed_light_paint_is_not_wiped()** (3 connections) — `tool/test_compose_home_hero_hanji.py`
- **test_compose_home_hero_hanji.py** (3 connections) — `tool/test_compose_home_hero_hanji.py`
- **main()** (2 connections) — `tool/compose_home_hero_hanji.py`
- **.test_background_mask_reaches_chromatic_shadow_only()** (2 connections) — `tool/test_compose_home_hero_hanji.py`
- **ndarray** (1 connections)
- **Background + soft shadow + cool fringe, never enclosed character paint. The old…** (1 connections) — `tool/compose_home_hero_hanji.py`
- **Multiply-bake onto Hanji and wipe cool background leftovers. A grey-on-cream…** (1 connections) — `tool/compose_home_hero_hanji.py`
- **Share of lower-frame leftovers whose blue channel leads red. Used as a…** (1 connections) — `tool/compose_home_hero_hanji.py`
- **4-connected flood fill that starts on every True border pixel.** (1 connections) — `tool/compose_home_hero_hanji.py`

## Relationships

- [whiten_clip_matte.py](whiten_clip_matte.py.md) (5 shared connections)
- [find_ffprobe](find_ffprobe.md) (4 shared connections)
- [whiten_frame](whiten_frame.md) (3 shared connections)
- [sheet](sheet.md) (3 shared connections)
- [check_home_hero_matte.py](check_home_hero_matte.py.md) (1 shared connections)

## Source Files

- `tool/compose_home_hero_hanji.py`
- `tool/test_compose_home_hero_hanji.py`

## Audit Trail

- EXTRACTED: 47 (75%)
- INFERRED: 16 (25%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*