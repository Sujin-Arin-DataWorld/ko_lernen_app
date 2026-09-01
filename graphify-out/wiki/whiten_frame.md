# whiten_frame

> 28 nodes · cohesion 0.13

## Key Concepts

- **whiten_frame()** (18 connections) — `tool/whiten_clip_matte.py`
- **protected_body()** (11 connections) — `tool/whiten_clip_matte.py`
- **synthetic()** (9 connections) — `tool/test_whiten_clip_matte.py`
- **ProtectsTheCharacter** (8 connections) — `tool/test_whiten_clip_matte.py`
- **ndarray** (8 connections)
- **.test_nothing_changes_next_to_the_character_outline()** (7 connections) — `tool/test_whiten_clip_matte.py`
- **_core_of()** (6 connections) — `tool/whiten_clip_matte.py`
- **RealFrameIfAvailable** (5 connections) — `tool/test_whiten_clip_matte.py`
- **dilate_n()** (5 connections) — `tool/whiten_clip_matte.py`
- **_ground_rows()** (5 connections) — `tool/whiten_clip_matte.py`
- **.test_nothing_inside_protected_body_changes()** (4 connections) — `tool/test_whiten_clip_matte.py`
- **.test_shadow_is_removed()** (4 connections) — `tool/test_whiten_clip_matte.py`
- **.test_protected_body_untouched_across_poses()** (4 connections) — `tool/test_whiten_clip_matte.py`
- **_span_fill()** (4 connections) — `tool/whiten_clip_matte.py`
- **.test_enclosed_marking_is_protected()** (3 connections) — `tool/test_whiten_clip_matte.py`
- **.test_ground_shadow_is_not_protected()** (3 connections) — `tool/test_whiten_clip_matte.py`
- **.test_marking_keeps_its_value()** (3 connections) — `tool/test_whiten_clip_matte.py`
- **.test_matte_stays_pure_white()** (3 connections) — `tool/test_whiten_clip_matte.py`
- **Path** (3 connections)
- **.test_rejects_bad_input()** (2 connections) — `tool/test_whiten_clip_matte.py`
- **.setUp()** (2 connections) — `tool/test_whiten_clip_matte.py`
- **실제 클립이 있으면 합성 프레임이 못 잡는 포즈까지 확인한다. CI 의 `asset-gates` 잡은 pillow·numpy 만 깔고…** (1 connections) — `tool/test_whiten_clip_matte.py`
- **실루엣 가장자리 잠식 회귀 (2026-08-25). 보호대가 없던 판본은 외곽선에 붙은 옅은 무늬를 흰색으로 먹었다. `magpie_bob2`…** (1 connections) — `tool/test_whiten_clip_matte.py`
- **White matte · dark body · enclosed pale marking · soft ground shadow.** (1 connections) — `tool/test_whiten_clip_matte.py`
- **행·열 양쪽에서 코어 사이에 낀 영역.** (1 connections) — `tool/whiten_clip_matte.py`
- *... and 3 more nodes in this community*

## Relationships

- [whiten_clip_matte.py](whiten_clip_matte.py.md) (10 shared connections)
- [test_whiten_clip_matte.py](test_whiten_clip_matte.py.md) (6 shared connections)
- [find_ffprobe](find_ffprobe.md) (3 shared connections)
- [compose_home_hero_hanji.py](compose_home_hero_hanji.py.md) (3 shared connections)

## Source Files

- `tool/test_whiten_clip_matte.py`
- `tool/whiten_clip_matte.py`

## Audit Trail

- EXTRACTED: 54 (74%)
- INFERRED: 19 (26%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*
