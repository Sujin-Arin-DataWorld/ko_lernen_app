# test_check_card_style.py

> 20 nodes · cohesion 0.12

## Key Concepts

- **test_check_card_style.py** (8 connections) — `tool/test_check_card_style.py`
- **NegativeGateTest** (7 connections) — `tool/test_check_card_style.py`
- **_hsv_to_rgb()** (4 connections) — `tool/test_check_card_style.py`
- **_rgb_to_hsv()** (4 connections) — `tool/test_check_card_style.py`
- **SweepTest** (3 connections) — `tool/test_check_card_style.py`
- **UnregisteredImportTest** (3 connections) — `tool/test_check_card_style.py`
- **.test_saturation_drifted_canon_is_rejected()** (3 connections) — `tool/test_check_card_style.py`
- **ndarray** (2 connections)
- **.setUp()** (1 connections) — `tool/test_check_card_style.py`
- **.tearDown()** (1 connections) — `tool/test_check_card_style.py`
- **.test_degrained_canon_is_rejected()** (1 connections) — `tool/test_check_card_style.py`
- **.test_solid_gray_synthetic_is_rejected()** (1 connections) — `tool/test_check_card_style.py`
- **.test_all_registered_members_pass_with_sha256()** (1 connections) — `tool/test_check_card_style.py`
- **.test_unregistered_webp_in_family_dir_fails_the_sweep()** (1 connections) — `tool/test_check_card_style.py`
- **Calibration-discipline tests for tool/check_card_style.py (F-E-cards).…** (1 connections) — `tool/test_check_card_style.py`
- **Rule 3: 명부 밖 파일이 가족 디렉터리에 들어오면 --all 이 실패한다.** (1 connections) — `tool/test_check_card_style.py`
- **Vectorized RGB[0..1] -> HSV[0..1], same convention as colorsys.** (1 connections) — `tool/test_check_card_style.py`
- **Vectorized HSV[0..1] -> RGB[0..1], same convention as colorsys.** (1 connections) — `tool/test_check_card_style.py`
- **Rule 1: 등록된 전 멤버 + sha256 + 미등록 반입 없음 = 0 실패.** (1 connections) — `tool/test_check_card_style.py`
- **Rule 2: 한 번도 실패하지 않는 게이트는 게이트가 아니다.** (1 connections) — `tool/test_check_card_style.py`

## Relationships

- [check_card_style.py](check_card_style.py.md) (1 shared connections)
- [style_lock.py](style_lock.py.md) (1 shared connections)

## Source Files

- `tool/test_check_card_style.py`

## Audit Trail

- EXTRACTED: 24 (100%)
- INFERRED: 0 (0%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*