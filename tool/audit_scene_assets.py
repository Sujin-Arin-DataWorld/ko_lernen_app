"""시나리오 씬 에셋 참조 감사.

`assets/data/scenarios_*.json` 의 각 시나리오가 참조하는 씬 포스터(PNG)/앰비언트
루프(MP4) 를 `lib/services/scene_asset_resolver.dart` (`SceneAssetResolver`) 의
파일명 규약대로 재구성해, 실제 `assets/` 하위 파일과 대조한다. 오타·누락·고아
파일을 `docs/data/scene_asset_report.md` 에 기록한다. 수정은 이 스크립트 범위
밖(W4) — 여기선 검출·리포트만 한다. exit code 는 항상 0(리포트 전용 도구).

리졸버 규약 (lib/services/scene_asset_resolver.dart 요약)
--------------------------------------------------------
포스터 — **dedicated-first, category-fallback**, 폴백 존재 여부를 확인하지
않고 그대로 반환(`SceneAssetResolver.posterAsset`):
  1. `assets/illustrations/scenes/{scenario.id}.png` 가 번들에 있으면 그것.
  2. 아니면 `scenario.backdrop` 이 비어있지 않으면
     `assets/illustrations/scenes/{backdrop}.png` 를 **존재 확인 없이** 반환.
     → `backdrop` 오타/누락 파일이면 앱이 깨진 이미지 경로를 그대로 쓴다.
     이게 이 스크립트가 잡아야 하는 진짜 버그 클래스다.
  3. `backdrop` 도 비어있으면 null(호출측이 마스코트로 대체).

루프 — dedicated-first, category-fallback, 폴백은 **존재를 확인하고** 없으면
null 을 돌려준다(`SceneAssetResolver.loopAsset`) — 그래서 `backdrop` 오타가
있어도 루프 쪽은 깨진 경로를 반환하지 않고 안전하게 포스터로만 대체된다.
카테고리 14종 중 루프 파일이 아직 없는 카테고리가 있는 것 자체는 설계상
정상(주석 참고) — 이 스크립트는 그래도 커버리지 통계로는 보여준다.
  1. `assets/video/loops/scene_{scenario.id}.mp4` 가 번들에 있으면 그것.
  2. 아니면 `backdrop` 이 있고 `assets/video/loops/scene_{backdrop}.mp4` 가
     실제로 있으면 그것.
  3. 그 외에는 null(포스터만 사용, 버그 아님).

`assets/video/loops/` 에는 이 규약과 무관한 비디오(웰컴 히어로, 한옥 건설
타임랩스 등)도 섞여 있다 — 파일명이 `scene_` 로 시작하는 것만 이 규약
안이라고 보고, 그 외는 애초에 대상이 아니므로 고아 판정에서 제외한다.
포스터 디렉터리(`assets/illustrations/scenes/`)는 이 규약 전용이라 안의
`.png` 파일 전부가 대상이다.
"""

from __future__ import annotations

import json
import os
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from typing import Optional

# ---------------------------------------------------------------------------
# 경로
# ---------------------------------------------------------------------------

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(ROOT, "assets", "data")
POSTER_DIR = os.path.join(ROOT, "assets", "illustrations", "scenes")
LOOP_DIR = os.path.join(ROOT, "assets", "video", "loops")
REPORT_PATH = os.path.join(ROOT, "docs", "data", "scene_asset_report.md")

LOOP_SCENE_PREFIX = "scene_"

# ---------------------------------------------------------------------------
# 순수 함수 — 파일명 규약 + 리졸버 로직 재구성. 파일 I/O 없음.
# ---------------------------------------------------------------------------


def dedicated_poster_name(scenario_id: str) -> str:
    return f"{scenario_id}.png"


def category_poster_name(backdrop: str) -> str:
    return f"{backdrop}.png"


def dedicated_loop_name(scenario_id: str) -> str:
    return f"{LOOP_SCENE_PREFIX}{scenario_id}.mp4"


def category_loop_name(backdrop: str) -> str:
    return f"{LOOP_SCENE_PREFIX}{backdrop}.mp4"


def resolve_poster(scenario_id: str, backdrop: str, poster_files: frozenset) -> tuple:
    """`SceneAssetResolver.posterAsset` 재구성.

    돌려주는 `(status, path)`:
      - `("dedicated", path)`   — 전용 포스터 존재
      - `("category", path)`    — 카테고리 포스터 존재(정상 폴백)
      - `("broken_category", path)` — backdrop 비어있지 않은데 그 카테고리
        포스터 파일이 없음. **리졸버는 이 경우에도 이 경로를 그대로 반환한다**
        (존재 확인을 안 함) → 진짜 버그(오타/누락 파일).
      - `("none", None)`        — backdrop 도 비어 있어 포스터 없음(정상, 마스코트 대체)
    """
    dedicated = dedicated_poster_name(scenario_id)
    if dedicated in poster_files:
        return ("dedicated", dedicated)
    if backdrop:
        candidate = category_poster_name(backdrop)
        if candidate in poster_files:
            return ("category", candidate)
        return ("broken_category", candidate)
    return ("none", None)


def resolve_loop(scenario_id: str, backdrop: str, loop_files: frozenset) -> tuple:
    """`SceneAssetResolver.loopAsset` 재구성 — 폴백도 존재를 확인하므로 이
    함수는 "버그" 상태를 돌려주지 않는다(그게 리졸버의 안전장치가 의도한
    바). 돌려주는 `(status, path)`:
      - `("dedicated", path)` — 전용 루프 존재
      - `("category", path)` — 카테고리 루프 존재
      - `("none_fallback", None)` — backdrop 은 있지만 그 카테고리 루프
        파일이 아직 없음(포스터만 사용 — 설계상 정상, 통계용)
      - `("none", None)` — backdrop 도 없음
    """
    dedicated = dedicated_loop_name(scenario_id)
    if dedicated in loop_files:
        return ("dedicated", dedicated)
    if backdrop:
        candidate = category_loop_name(backdrop)
        if candidate in loop_files:
            return ("category", candidate)
        return ("none_fallback", None)
    return ("none", None)


# ---------------------------------------------------------------------------
# 결과 레코드
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class ScenarioRef:
    shard: str
    scenario_id: str
    level: str
    backdrop: str


@dataclass(frozen=True)
class BrokenRef:
    shard: str
    scenario_id: str
    level: str
    backdrop: str
    expected_path: str
    kind: str  # "poster" | "loop"


# ---------------------------------------------------------------------------
# I/O 헬퍼 (스캔 계층 전용 — 순수 함수 아님)
# ---------------------------------------------------------------------------


def _scenario_shard_names() -> list:
    return sorted(
        name
        for name in os.listdir(DATA_DIR)
        if name.startswith("scenarios_") and name.endswith(".json")
    )


def _load_json(path: str):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def _load_scenario_refs() -> list:
    refs = []
    for shard in _scenario_shard_names():
        data = _load_json(os.path.join(DATA_DIR, shard))
        scenarios = data.get("scenarios", []) if isinstance(data, dict) else data
        for sc in scenarios or []:
            refs.append(
                ScenarioRef(
                    shard=shard,
                    scenario_id=(sc.get("id") or "?").strip() or "?",
                    level=sc.get("level") or "?",
                    backdrop=(sc.get("backdrop") or "").strip(),
                )
            )
    refs.sort(key=lambda r: (r.shard, r.scenario_id))
    return refs


def _list_files(directory: str) -> list:
    if not os.path.isdir(directory):
        return []
    return sorted(
        name
        for name in os.listdir(directory)
        if os.path.isfile(os.path.join(directory, name))
    )


# ---------------------------------------------------------------------------
# 스캔
# ---------------------------------------------------------------------------


def scan_all() -> dict:
    """전체 스캔 결과를 dict 로 돌려준다(리포트 렌더링과 분리해 테스트 가능하게).

    키:
      - refs: 스캔한 `ScenarioRef` 리스트(결정적 정렬)
      - poster_files / loop_files: 실제 디렉터리 파일명 리스트(결정적 정렬)
      - non_scene_loop_files: `scene_` 접두사가 아니라 이 규약 밖인 루프
        디렉터리 파일(참고용, 고아 판정 제외)
      - broken_posters / broken_loops: `BrokenRef` 리스트(오타/누락)
      - orphan_posters / orphan_loops: 어떤 시나리오도 참조하지 않는 파일명 리스트
      - dup_scenario_ids: 샤드 전체에서 2회 이상 나오는 시나리오 id (있으면
        이 스크립트의 id 기반 대조 자체가 모호해지므로 별도로 경고)
      - poster_status_counts / loop_status_counts: resolve_* 상태별 시나리오 수
    """
    refs = _load_scenario_refs()
    poster_files = sorted(
        name for name in _list_files(POSTER_DIR) if name.lower().endswith(".png")
    )
    all_loop_files = _list_files(LOOP_DIR)
    loop_files = sorted(
        name
        for name in all_loop_files
        if name.startswith(LOOP_SCENE_PREFIX) and name.lower().endswith(".mp4")
    )
    non_scene_loop_files = sorted(set(all_loop_files) - set(loop_files))

    poster_set = frozenset(poster_files)
    loop_set = frozenset(loop_files)

    id_counts = Counter(r.scenario_id for r in refs)
    dup_scenario_ids = sorted(sid for sid, n in id_counts.items() if n > 1)

    broken_posters = []
    broken_loops = []
    poster_status_counts = Counter()
    loop_status_counts = Counter()
    referenced_ids = set()
    referenced_backdrops = set()

    for r in refs:
        referenced_ids.add(r.scenario_id)
        if r.backdrop:
            referenced_backdrops.add(r.backdrop)

        p_status, p_path = resolve_poster(r.scenario_id, r.backdrop, poster_set)
        poster_status_counts[p_status] += 1
        if p_status == "broken_category":
            broken_posters.append(
                BrokenRef(
                    shard=r.shard,
                    scenario_id=r.scenario_id,
                    level=r.level,
                    backdrop=r.backdrop,
                    expected_path=p_path,
                    kind="poster",
                )
            )

        l_status, l_path = resolve_loop(r.scenario_id, r.backdrop, loop_set)
        loop_status_counts[l_status] += 1
        if l_status == "broken_category":  # resolve_loop 는 이 상태를 내지 않지만 방어적으로 유지
            broken_loops.append(
                BrokenRef(
                    shard=r.shard,
                    scenario_id=r.scenario_id,
                    level=r.level,
                    backdrop=r.backdrop,
                    expected_path=l_path or category_loop_name(r.backdrop),
                    kind="loop",
                )
            )

    orphan_posters = sorted(
        name
        for name in poster_files
        if name[:-4] not in referenced_ids and name[:-4] not in referenced_backdrops
    )
    orphan_loops = sorted(
        name
        for name in loop_files
        if name[len(LOOP_SCENE_PREFIX) : -4] not in referenced_ids
        and name[len(LOOP_SCENE_PREFIX) : -4] not in referenced_backdrops
    )

    return {
        "refs": refs,
        "poster_files": poster_files,
        "loop_files": loop_files,
        "non_scene_loop_files": non_scene_loop_files,
        "broken_posters": broken_posters,
        "broken_loops": broken_loops,
        "orphan_posters": orphan_posters,
        "orphan_loops": orphan_loops,
        "dup_scenario_ids": dup_scenario_ids,
        "poster_status_counts": poster_status_counts,
        "loop_status_counts": loop_status_counts,
    }


# ---------------------------------------------------------------------------
# 리포트 작성
# ---------------------------------------------------------------------------


def _escape_cell(text: str) -> str:
    text = text.replace("|", "\\|")
    text = text.replace("\r\n", " ").replace("\n", " ").replace("\r", " ")
    return text


_POSTER_STATUS_LABELS = {
    "dedicated": "전용 포스터",
    "category": "카테고리 포스터(정상 폴백)",
    "broken_category": "카테고리 포스터 없음(버그)",
    "none": "포스터 없음(backdrop 비어있음, 정상 — 마스코트 대체)",
}
_LOOP_STATUS_LABELS = {
    "dedicated": "전용 루프",
    "category": "카테고리 루프",
    "broken_category": "카테고리 루프 없음(리졸버 로직상 불가능해야 함)",
    "none_fallback": "루프 없음, 포스터만 사용(정상 폴백)",
    "none": "루프 없음(backdrop 비어있음, 정상)",
}


def render_report(result: dict) -> str:
    refs = result["refs"]
    shard_names = _scenario_shard_names()

    lines = []
    lines.append("# 시나리오 씬 에셋 참조 감사 리포트")
    lines.append("")
    lines.append(
        "`python tool/audit_scene_assets.py` 로 생성 — 직접 편집 금지,"
        " 스크립트 재실행으로 갱신한다."
    )
    lines.append("")
    lines.append(
        "시나리오 `id`/`backdrop` 을 `lib/services/scene_asset_resolver.dart`"
        "(`SceneAssetResolver`) 의 파일명 규약대로 포스터(PNG)/루프(MP4) 경로로"
        " 재구성해 실제 `assets/` 파일과 대조한다. 포스터는 카테고리 폴백을"
        " **존재 확인 없이** 반환하는 리졸버 로직 그대로라, `backdrop` 오타나"
        " 누락 파일은 실제로 앱에서 깨진 이미지 경로가 된다 — 이게 이 리포트가"
        " 잡는 핵심 버그 클래스다. 루프는 폴백이 존재를 확인하고 없으면"
        " null 을 돌려주는 안전장치가 있어 오타가 있어도 깨지지 않는다(포스터로"
        " 대체) — 그래도 커버리지 통계는 보여준다. 수정은 이 스크립트 범위"
        " 밖(W4) — 여기선 검출·리포트만 한다."
    )
    lines.append("")

    lines.append("## 오타·누락 포스터 (버그)")
    lines.append("")
    broken_posters = result["broken_posters"]
    if not broken_posters:
        lines.append(
            f"0건 — 스캔한 시나리오 {len(refs)}개 전부 포스터가 전용 파일이거나"
            " 실제로 존재하는 카테고리 파일로 해석됨."
        )
        lines.append("")
    else:
        lines.append(f"{len(broken_posters)}건 — backdrop 값이 실제 포스터 파일과 대조되지 않음.")
        lines.append("")
        lines.append("| 샤드 | 시나리오 id | 레벨 | backdrop | 기대 경로 |")
        lines.append("|---|---|---|---|---|")
        for b in sorted(broken_posters, key=lambda x: (x.shard, x.scenario_id)):
            lines.append(
                f"| {b.shard} | {_escape_cell(b.scenario_id)} | {_escape_cell(b.level)} |"
                f" {_escape_cell(b.backdrop)} |"
                f" `assets/illustrations/scenes/{_escape_cell(b.expected_path)}` |"
            )
        lines.append("")

    lines.append("## 오타·누락 루프")
    lines.append("")
    broken_loops = result["broken_loops"]
    if not broken_loops:
        lines.append(
            "0건 — 루프 폴백은 리졸버가 존재를 확인 후 반환하므로 이 카테고리는"
            " 구조적으로 항상 0건이어야 한다(존재하면 리졸버 로직 자체가 깨진"
            " 것이니 우선 점검할 것)."
        )
        lines.append("")
    else:
        lines.append(f"{len(broken_loops)}건.")
        lines.append("")
        lines.append("| 샤드 | 시나리오 id | 레벨 | backdrop | 기대 경로 |")
        lines.append("|---|---|---|---|---|")
        for b in sorted(broken_loops, key=lambda x: (x.shard, x.scenario_id)):
            lines.append(
                f"| {b.shard} | {_escape_cell(b.scenario_id)} | {_escape_cell(b.level)} |"
                f" {_escape_cell(b.backdrop)} |"
                f" `assets/video/loops/{_escape_cell(b.expected_path)}` |"
            )
        lines.append("")

    lines.append("## 고아 포스터 파일")
    lines.append("")
    orphan_posters = result["orphan_posters"]
    if not orphan_posters:
        lines.append(
            f"0건 — `{os.path.relpath(POSTER_DIR, ROOT).replace(os.sep, '/')}`"
            f" 의 {len(result['poster_files'])}개 파일 전부 어떤 시나리오의"
            " id(전용) 또는 backdrop(카테고리) 로 참조됨."
        )
        lines.append("")
    else:
        lines.append(f"{len(orphan_posters)}건 — 어떤 시나리오도 참조하지 않는 포스터 파일.")
        lines.append("")
        lines.append("| 파일 |")
        lines.append("|---|")
        for name in orphan_posters:
            lines.append(f"| {_escape_cell(name)} |")
        lines.append("")

    lines.append("## 고아 루프 파일")
    lines.append("")
    orphan_loops = result["orphan_loops"]
    if not orphan_loops:
        lines.append(
            f"0건 — `{os.path.relpath(LOOP_DIR, ROOT).replace(os.sep, '/')}`"
            f" 의 `{LOOP_SCENE_PREFIX}*.mp4` 파일 {len(result['loop_files'])}개"
            " 전부 어떤 시나리오의 id 또는 backdrop 으로 참조됨"
            f"({len(result['non_scene_loop_files'])}개는 `{LOOP_SCENE_PREFIX}`"
            " 접두사가 아니라 이 규약 밖이라 대상에서 제외)."
        )
        lines.append("")
    else:
        lines.append(f"{len(orphan_loops)}건.")
        lines.append("")
        lines.append("| 파일 |")
        lines.append("|---|")
        for name in orphan_loops:
            lines.append(f"| {_escape_cell(name)} |")
        lines.append("")

    if result["dup_scenario_ids"]:
        lines.append("## 시나리오 id 중복 (경고)")
        lines.append("")
        lines.append(
            "아래 id 가 여러 샤드/시나리오에서 재사용됨 — 전용 포스터/루프"
            " 파일명이 id 기반이라 id 가 중복이면 이 대조 자체가 모호해진다."
        )
        lines.append("")
        for sid in result["dup_scenario_ids"]:
            lines.append(f"- {_escape_cell(sid)}")
        lines.append("")

    lines.append("## 샤드별 시나리오 수")
    lines.append("")
    by_shard_count = Counter(r.shard for r in refs)
    for shard in shard_names:
        lines.append(f"- {shard}: {by_shard_count.get(shard, 0)}개")
    lines.append("")

    lines.append("## 리소스 커버리지 통계")
    lines.append("")
    lines.append(f"- 포스터 디렉터리 파일 수: {len(result['poster_files'])}")
    lines.append(
        f"- 루프 디렉터리: `{LOOP_SCENE_PREFIX}*.mp4` {len(result['loop_files'])}개"
        f" + 규약 밖 파일 {len(result['non_scene_loop_files'])}개"
    )
    lines.append("")
    lines.append("### 포스터 해석 상태별 시나리오 수")
    lines.append("")
    p_counts = result["poster_status_counts"]
    for status in ("dedicated", "category", "broken_category", "none"):
        lines.append(f"- {_POSTER_STATUS_LABELS[status]}: {p_counts.get(status, 0)}개")
    lines.append("")
    lines.append("### 루프 해석 상태별 시나리오 수")
    lines.append("")
    l_counts = result["loop_status_counts"]
    for status in ("dedicated", "category", "broken_category", "none_fallback", "none"):
        lines.append(f"- {_LOOP_STATUS_LABELS[status]}: {l_counts.get(status, 0)}개")
    lines.append("")

    lines.append("## 요약")
    lines.append("")
    lines.append(f"- 스캔한 시나리오: **{len(refs)}개** (샤드 {len(shard_names)}개)")
    lines.append(f"- 오타·누락 포스터: **{len(broken_posters)}건**")
    lines.append(f"- 오타·누락 루프: **{len(broken_loops)}건**")
    lines.append(f"- 고아 포스터 파일: **{len(orphan_posters)}건**")
    lines.append(f"- 고아 루프 파일: **{len(orphan_loops)}건**")
    lines.append(f"- 시나리오 id 중복: **{len(result['dup_scenario_ids'])}건**")
    lines.append("")

    return "\n".join(lines) + "\n"


def write_report(result: dict, out_path: str = REPORT_PATH) -> str:
    text = render_report(result)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    return text


# ---------------------------------------------------------------------------
# CLI 진입점
# ---------------------------------------------------------------------------


def main(argv=None) -> int:
    result = scan_all()
    write_report(result)
    rel = os.path.relpath(REPORT_PATH, ROOT).replace(os.sep, "/")
    total_issues = (
        len(result["broken_posters"])
        + len(result["broken_loops"])
        + len(result["orphan_posters"])
        + len(result["orphan_loops"])
    )
    print(f"[audit_scene_assets] 이슈 {total_issues}건 -> {rel}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
