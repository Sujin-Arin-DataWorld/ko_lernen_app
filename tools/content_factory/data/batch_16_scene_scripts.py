#!/usr/bin/env python3
"""Batch 16 — C2 기능 확장 6칸의 첫 재고 (칸당 4편, 24편) — 서재의 마지막 빈 칸.

ethics · history · aesthetic · limitation · jurisdiction · representation.
축별 모듈을 여기서 한 줄로 합친다 — 빌더는 이 SCENES 하나만 본다.

C2 는 이 코스의 최상급이다. C1(판단의 조건을 드러내는 층위)의 연속으로,
결론이 아니라 전제를 짚고 예외를 걸고 양보하되 물러서지 않는 말로 썼다.
"""

from __future__ import annotations

from typing import Any

from .batch_16_c2_ethics import SCENES as _ETHICS
from .batch_16_c2_history import SCENES as _HISTORY
from .batch_16_c2_aesthetic import SCENES as _AESTHETIC
from .batch_16_c2_limitation import SCENES as _LIMITATION
from .batch_16_c2_jurisdiction import SCENES as _JURISDICTION
from .batch_16_c2_representation import SCENES as _REPRESENTATION

SCENES: list[dict[str, Any]] = [
    *_ETHICS, *_HISTORY, *_AESTHETIC, *_LIMITATION, *_JURISDICTION, *_REPRESENTATION,
]
