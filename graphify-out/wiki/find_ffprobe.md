# find_ffprobe

> 15 nodes · cohesion 0.24

## Key Concepts

- **find_ffprobe()** (11 connections) — `tool/check_home_hero_matte.py`
- **check_clip_matte.py** (10 connections) — `tool/check_clip_matte.py`
- **find_ffmpeg()** (9 connections) — `tool/check_clip_matte.py`
- **load_frames()** (9 connections) — `tool/test_whiten_clip_matte.py`
- **check()** (6 connections) — `tool/check_clip_matte.py`
- **die()** (5 connections) — `tool/check_clip_matte.py`
- **main()** (5 connections) — `tool/check_home_hero_matte.py`
- **floor_grey()** (4 connections) — `tool/check_clip_matte.py`
- **main()** (4 connections) — `tool/check_clip_matte.py`
- **corners()** (3 connections) — `tool/check_clip_matte.py`
- **Path** (2 connections)
- **`GRID`x`GRID` RGB24 프레임의 네 모서리 픽셀.** (1 connections) — `tool/check_clip_matte.py`
- **프레임 하단의 회색 잔여 최대 비율. 구워진 접지 그림자 탐지용.** (1 connections) — `tool/check_clip_matte.py`
- **ffmpeg 옆의 ffprobe. 태그 검증은 선택이 아니라 계약이라 없으면 죽는다.** (1 connections) — `tool/check_home_hero_matte.py`
- **지정한 프레임만 디코드한다. `compose_home_hero_hanji.load_rgb_frames` 는 클립 **전체**를 메모리에…** (1 connections) — `tool/test_whiten_clip_matte.py`

## Relationships

- [check_home_hero_matte.py](check_home_hero_matte.py.md) (6 shared connections)
- [compose_home_hero_hanji.py](compose_home_hero_hanji.py.md) (4 shared connections)
- [sheet](sheet.md) (3 shared connections)
- [whiten_clip_matte.py](whiten_clip_matte.py.md) (3 shared connections)
- [whiten_frame](whiten_frame.md) (3 shared connections)
- [test_whiten_clip_matte.py](test_whiten_clip_matte.py.md) (2 shared connections)
- [Counter](Counter.md) (1 shared connections)

## Source Files

- `tool/check_clip_matte.py`
- `tool/check_home_hero_matte.py`
- `tool/test_whiten_clip_matte.py`

## Audit Trail

- EXTRACTED: 32 (68%)
- INFERRED: 15 (32%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*
