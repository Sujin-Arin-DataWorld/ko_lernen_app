# test_check_style_conformance.py

> 22 nodes · cohesion 0.13

## Key Concepts

- **test_check_style_conformance.py** (10 connections) — `tool/test_check_style_conformance.py`
- **_drift_saturation_value()** (8 connections) — `tool/test_check_style_conformance.py`
- **_closed_temp_png_path()** (5 connections) — `tool/test_check_style_conformance.py`
- **_hsv_to_rgb()** (5 connections) — `tool/test_check_style_conformance.py`
- **_rgb_to_hsv()** (5 connections) — `tool/test_check_style_conformance.py`
- **SyntheticDriftTest** (4 connections) — `tool/test_check_style_conformance.py`
- **.test_a_wildly_off_palette_still_only_warns()** (4 connections) — `tool/test_check_style_conformance.py`
- **PaletteDistanceIsWarningOnlyTest** (3 connections) — `tool/test_check_style_conformance.py`
- **ShippedBaselineTest** (3 connections) — `tool/test_check_style_conformance.py`
- **.test_estate_family_drift_is_also_rejected()** (2 connections) — `tool/test_check_style_conformance.py`
- **.test_saturation_and_value_drift_is_rejected()** (2 connections) — `tool/test_check_style_conformance.py`
- **ndarray** (2 connections)
- **Path** (2 connections)
- **.test_every_family_member_passes()** (1 connections) — `tool/test_check_style_conformance.py`
- **Calibration-discipline tests for tool/check_style_conformance.py. Phase 2-2 of…** (1 connections) — `tool/test_check_style_conformance.py`
- **Rule 1: every shipped family member passes the gate it's measured under.** (1 connections) — `tool/test_check_style_conformance.py`
- **Rule 2: a gate that never fails anything isn't a gate.** (1 connections) — `tool/test_check_style_conformance.py`
- **Rule 4: paletteDistance has no shipped precedent yet, so it must never fail a…** (1 connections) — `tool/test_check_style_conformance.py`
- **Reserve a temp PNG path without leaking an open Windows file handle.** (1 connections) — `tool/test_check_style_conformance.py`
- **Vectorized RGB[0..1] -> HSV[0..1], same convention as colorsys.** (1 connections) — `tool/test_check_style_conformance.py`
- **Vectorized HSV[0..1] -> RGB[0..1], same convention as colorsys.** (1 connections) — `tool/test_check_style_conformance.py`
- **Write a copy of `path` with every visible pixel's HSV S and V scaled.** (1 connections) — `tool/test_check_style_conformance.py`

## Relationships

- [check_style_conformance.py](check_style_conformance.py.md) (1 shared connections)
- [style_lock.py](style_lock.py.md) (1 shared connections)

## Source Files

- `tool/test_check_style_conformance.py`

## Audit Trail

- EXTRACTED: 33 (100%)
- INFERRED: 0 (0%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*
