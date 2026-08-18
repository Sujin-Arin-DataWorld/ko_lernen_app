#!/usr/bin/env python3
"""Batch 14 씬 스크립트 공용 헬퍼 — 축별 모듈이 함께 쓴다."""

from __future__ import annotations

from typing import Any


def quest(scene_id: str, suffix: str, kind: str, concepts: list[str],
          data: dict[str, Any]) -> dict[str, Any]:
    """퀘스트 id·conceptIds 규약을 한 곳에서 지킨다.

    id 는 quest_{scene}_{suffix}, conceptIds 는 씬의 것과 같아야 한다
    (test_build_batch_14_scenarios 가 그 둘을 검사한다).
    """

    return {
        "id": f"quest_{scene_id}_{suffix}",
        "type": kind,
        "conceptIds": list(concepts),
        "data": data,
    }
