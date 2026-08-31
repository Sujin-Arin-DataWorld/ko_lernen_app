# whiten_frame

> 23 nodes

## Key Concepts

- **whiten_frame()** (18 connections) — `tool/whiten_clip_matte.py`
- **protected_body()** (11 connections) — `tool/whiten_clip_matte.py`
- **synthetic()** (9 connections) — `tool/test_whiten_clip_matte.py`
- **ProtectsTheCharacter** (8 connections) — `tool/test_whiten_clip_matte.py`
- **ndarray** (8 connections)
- **.test_nothing_changes_next_to_the_character_outline()** (7 connections) — `tool/test_whiten_clip_matte.py`
- **_core_of()** (6 connections) — `tool/whiten_clip_matte.py`
- **dilate_n()** (5 connections) — `tool/whiten_clip_matte.py`
- **_ground_rows()** (5 connections) — `tool/whiten_clip_matte.py`
- **.test_nothing_inside_protected_body_changes()** (4 connections) — `tool/test_whiten_clip_matte.py`
- **.test_shadow_is_removed()** (4 connections) — `tool/test_whiten_clip_matte.py`
- **_span_fill()** (4 connections) — `tool/whiten_clip_matte.py`
- **.test_enclosed_marking_is_protected()** (3 connections) — `tool/test_whiten_clip_matte.py`
- **.test_ground_shadow_is_not_protected()** (3 connections) — `tool/test_whiten_clip_matte.py`
- **.test_marking_keeps_its_value()** (3 connections) — `tool/test_whiten_clip_matte.py`
- **.test_matte_stays_pure_white()** (3 connections) — `tool/test_whiten_clip_matte.py`
- **.test_rejects_bad_input()** (2 connections) — `tool/test_whiten_clip_matte.py`
- **실루엣 가장자리 잠식 회귀 (2026-08-25). 보호대가 없던 판본은 외곽선에 붙은 옅은 무늬를 흰색으로 먹었다. `magpie_bob2`…** (1 connections) — `tool/test_whiten_clip_matte.py`
- **White matte · dark body · enclosed pale marking · soft ground shadow.** (1 connections) — `tool/test_whiten_clip_matte.py`
- **행·열 양쪽에서 코어 사이에 낀 영역.** (1 connections) — `tool/whiten_clip_matte.py`
- **행별로 "여기에 진짜 접지 그림자가 있다" 판정. 진짜 바닥 그림자는 몸통 가로 폭 **바깥**으로 삐져나온다. 다리 사이로 보이는 옅은…** (1 connections) — `tool/whiten_clip_matte.py`
- **The whitener must not modify a single pixel in here.…** (1 connections) — `tool/whiten_clip_matte.py`
- **Paint background-connected shadow and haze pure white. Two invariants, both…** (1 connections) — `tool/whiten_clip_matte.py`

## Relationships

- [load_frames](load_frames.md) (10 shared connections)
- [whiten_clip_matte.py](whiten_clip_matte.py.md) (10 shared connections)
- [compose_home_hero_hanji.py](compose_home_hero_hanji.py.md) (3 shared connections)

## Source Files

- `tool/test_whiten_clip_matte.py`
- `tool/whiten_clip_matte.py`

## Audit Trail

- EXTRACTED: 47 (71%)
- INFERRED: 19 (29%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*