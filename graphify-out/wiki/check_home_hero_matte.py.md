# check_home_hero_matte.py

> 16 nodes

## Key Concepts

- **find_ffprobe()** (11 connections) — `tool/check_home_hero_matte.py`
- **check_home_hero_matte.py** (11 connections) — `tool/check_home_hero_matte.py`
- **check()** (6 connections) — `tool/check_home_hero_matte.py`
- **main()** (5 connections) — `tool/check_home_hero_matte.py`
- **corners_yuv444()** (4 connections) — `tool/check_home_hero_matte.py`
- **main()** (4 connections) — `tool/verify_staged_clips.py`
- **verify_staged_clips.py** (4 connections) — `tool/verify_staged_clips.py`
- **bt709_limited()** (3 connections) — `tool/check_home_hero_matte.py`
- **color_tags()** (3 connections) — `tool/check_home_hero_matte.py`
- **probe()** (3 connections) — `tool/verify_staged_clips.py`
- **Path** (3 connections)
- **compare()** (2 connections) — `tool/verify_staged_clips.py`
- **Path** (1 connections)
- **ITU-R BT.709 limited-range (studio swing) YCbCr → RGB, 정확 계산. swscale 의 고정소수점…** (1 connections) — `tool/check_home_hero_matte.py`
- **GRID×GRID yuv444p 프레임의 네 모서리를 RGB 로.** (1 connections) — `tool/check_home_hero_matte.py`
- **ffmpeg 옆의 ffprobe. 태그 검증은 선택이 아니라 계약이라 없으면 죽는다.** (1 connections) — `tool/check_home_hero_matte.py`

## Relationships

- [check_clip_matte.py](check_clip_matte.py.md) (5 shared connections)
- [compose_home_hero_hanji.py](compose_home_hero_hanji.py.md) (2 shared connections)
- [sheet](sheet.md) (2 shared connections)
- [whiten_clip_matte.py](whiten_clip_matte.py.md) (2 shared connections)
- [Counter](Counter.md) (1 shared connections)
- [load_frames](load_frames.md) (1 shared connections)

## Source Files

- `tool/check_home_hero_matte.py`
- `tool/verify_staged_clips.py`

## Audit Trail

- EXTRACTED: 28 (74%)
- INFERRED: 10 (26%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*