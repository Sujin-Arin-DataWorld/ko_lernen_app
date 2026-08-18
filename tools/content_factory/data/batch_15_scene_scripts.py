#!/usr/bin/env python3
"""Batch 15 — C1 기능 확장 7칸의 첫 재고 (칸당 4편, 28편).

conflict_interest · policy · clinical · critique · mediation · facework · attribution.
축별 모듈을 여기서 한 줄로 합친다 — 빌더는 이 SCENES 하나만 본다.

C1 의 과제는 **판단의 조건을 드러내는 것**이다. 무엇을 아는가가 아니라 그 앎이
어디까지 유효하고 누가 이득을 보는지를 말로 표시한다. 그래서 장면들이 결론이
아니라 유보와 조건으로 끝난다.
"""

from __future__ import annotations

from typing import Any

from .batch_15_c1a import SCENES as _A
from .batch_15_c1b import SCENES as _B
from .batch_15_c1c import SCENES as _C

SCENES: list[dict[str, Any]] = [*_A, *_B, *_C]
