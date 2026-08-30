#!/usr/bin/env python3
"""리소 카드 일러스트(F-E-cards) 기계 게이트 — packs/listening/activities.

tool/check_style_conformance.py 의 형제 도구다. 그쪽은 컷아웃(알파) 가족의
satMean/valMean/neon 을 재고, 이쪽은 800x600 풀프레임 WebP 카드 가족의
상아 지면·종이 그레인·팔레트 존재·색 다양성을 잰다. 임계값은 전부
docs/assets/STYLE_LOCK.json families.F-E-cards.gates 에서 읽는다 — 이 파일에
숫자를 하드코딩하지 않는다(측정 공식 상수는 예외: 그건 임계값이 아니라
grainFormulaVersion=1 의 정의다).

정본 명부(멤버십 원장)는 docs/assets/CARD_STYLE_BASELINE.json 사이드카다:
  --all       사이드카에 등록된 전 멤버를 검사 + sha256 대조(정본 변조 감지)
              + 가족 디렉터리에 있으나 미등록인 *.webp 는 하드 실패(미등록 반입)
  --baseline  현재 가족 이미지를 전량 실측해 사이드카를 새로 쓰고, 제안
              게이트 블록을 출력한다(STYLE_LOCK.json 은 절대 다시 쓰지 않는다
              — 밴드 숫자는 사람이 검토해 수동으로 붙여넣는다)
  --register FILE  후보 검사를 통과하면 사이드카에 sha256+실측을 추가하고
              STYLE_LOCK.json 의 members 배열에 stem 을 추가한다(라운드트립
              안정성 검사 실패 시 수동 붙여넣기 줄을 출력)
  FILE ...    후보 검사만(스타일 검사, 경로 무관)

고정 좌표 색면 프로브는 쓰지 않는다 — packs/wave(적색면 0.001),
listening/A1Counter(청록 0.0) 같은 정본이 통과 못 한다. 대신 색상(hue)
존재 OR 게이트를 쓴다. 테두리 링 템플릿 상관도 기각됐다(정본 산포가
회색 대조군과 겹침).

Exit code = 실패한 파일 수 (형제 도구와 같은 관례).
"""

from __future__ import annotations

import argparse
import datetime as _dt
import hashlib
import json
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parent))

import style_lock  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
FAMILY = "F-E-cards"
BASELINE_PATH = ROOT / "docs" / "assets" / "CARD_STYLE_BASELINE.json"

# ---- 측정 공식 상수 (grainFormulaVersion=1) --------------------------------
# 임계값이 아니라 측정 방법 자체다. 바꾸면 사이드카 전체를 --baseline 으로
# 재실측하고 grainFormulaVersion 을 올려야 한다.
GRAIN_FORMULA_VERSION = 1
PATCH_SIZE = 64                 # 평탄 상아 패치 한 변
PATCH_YS = (0, 24, 48)          # 상단 밴드 후보 y
PATCH_X_MIN, PATCH_X_MAX = 64, 720  # 후보 x 범위(패치 좌상단 기준 64~656)
PATCH_X_STEP = 8
FLATNESS_BLUR_RADIUS = 8        # "가장 평탄한" 판정용 블러
FINE_BLUR_RADIUS = 2            # fine 그레인: 휘도 - GaussianBlur(2)
FINE_TRIM = 2                   # 블러 경계 효과 제거
COARSE_DOWNSCALE = 6            # coarse: 1/6 BILINEAR 축소 후 동일 공식
COARSE_TRIM = 1

FAILURE_FOOTER = """이 가족(F-E-cards)의 정본:
  · 생성 레시피/앵커/프롬프트  -> docs/LISTENING_CARD_RECIPE.md
  · 수치 계약(밴드의 근거 실측) -> docs/assets/STYLE_LOCK.json families.F-E-cards + docs/assets/CARD_STYLE_BASELINE.json
고치는 법: RECIPE 대로 재생성 -> scripts/finish_listening_card.sh 로 후처리하면 게이트를 자동 통과한다.
재생성해도 실패하면 밴드를 절대 넓히지 말고 Jin 에게 물어라 — 밴드는 승인된 실측이다."""


def _family(lock: dict) -> dict:
    return lock["families"][FAMILY]


def _luminance(rgb: np.ndarray) -> np.ndarray:
    r = rgb[..., 0].astype(np.float32)
    g = rgb[..., 1].astype(np.float32)
    b = rgb[..., 2].astype(np.float32)
    return 0.299 * r + 0.587 * g + 0.114 * b


def _blur(gray: np.ndarray, radius: float) -> np.ndarray:
    im = Image.fromarray(np.clip(gray, 0, 255).astype(np.uint8))
    return np.asarray(im.filter(ImageFilter.GaussianBlur(radius)), dtype=np.float32)


def find_ivory_patch(arr: np.ndarray, gates: dict) -> tuple[int, int] | None:
    """상단 밴드에서 가장 평탄한 상아색 64x64 패치의 (x, y).

    후보 판정은 ivoryBody ± 2*ivoryTol(느슨) — 하드 게이트인
    ivoryPatchWindow 판정은 check() 쪽에서 한다.
    """
    body = np.array(gates["ivoryBody"], dtype=np.float32)
    loose = 2 * float(gates["ivoryTol"])
    best: tuple[float, int, int] | None = None
    for y in PATCH_YS:
        for x in range(PATCH_X_MIN, PATCH_X_MAX - PATCH_SIZE + 1, PATCH_X_STEP):
            patch = arr[y:y + PATCH_SIZE, x:x + PATCH_SIZE]
            mean = patch.reshape(-1, 3).mean(axis=0)
            if np.any(np.abs(mean - body) > loose):
                continue
            flatness = float(_blur(_luminance(patch), FLATNESS_BLUR_RADIUS).std())
            if best is None or flatness < best[0]:
                best = (flatness, x, y)
    return None if best is None else (best[1], best[2])


def fine_grain_sd(arr: np.ndarray, x: int, y: int) -> float:
    lum = _luminance(arr[y:y + PATCH_SIZE, x:x + PATCH_SIZE])
    resid = lum - _blur(lum, FINE_BLUR_RADIUS)
    t = FINE_TRIM
    return float(resid[t:-t, t:-t].std())


def coarse_grain_sd(arr: np.ndarray, x: int, y: int) -> float:
    lum = _luminance(arr[y:y + PATCH_SIZE, x:x + PATCH_SIZE])
    side = max(PATCH_SIZE // COARSE_DOWNSCALE, 1)
    small = np.asarray(
        Image.fromarray(np.clip(lum, 0, 255).astype(np.uint8)).resize(
            (side, side), Image.BILINEAR
        ),
        dtype=np.float32,
    )
    resid = small - _blur(small, FINE_BLUR_RADIUS)
    t = COARSE_TRIM
    return float(resid[t:-t, t:-t].std())


def _hsv(arr: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """RGB uint8 -> (hue[0..360), sat[0..1], val[0..1]) — 전 픽셀 벡터화."""
    rgb = arr.astype(np.float32) / 255.0
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    maxc = rgb.max(axis=-1)
    minc = rgb.min(axis=-1)
    delta = maxc - minc
    safe = np.where(delta > 0, delta, 1.0)
    hue = np.select(
        [maxc == r, maxc == g],
        [((g - b) / safe) % 6.0, (b - r) / safe + 2.0],
        default=(r - g) / safe + 4.0,
    ) * 60.0
    hue = np.where(delta == 0, 0.0, hue) % 360.0
    sat = np.where(maxc > 0, delta / np.where(maxc > 0, maxc, 1.0), 0.0)
    return hue, sat, maxc


def _hue_window_fraction(
    hue: np.ndarray, sat: np.ndarray, val: np.ndarray, window: dict
) -> float:
    h_lo, h_hi = window["hueDeg"]
    s_lo, s_hi = window["sat"]
    v_lo, v_hi = window["val"]
    if h_lo <= h_hi:
        in_hue = (hue >= h_lo) & (hue <= h_hi)
    else:  # wrap (예: 적색대 340~20)
        in_hue = (hue >= h_lo) | (hue <= h_hi)
    mask = in_hue & (sat >= s_lo) & (sat <= s_hi) & (val >= v_lo) & (val <= v_hi)
    return float(mask.mean())


def unique_colors(arr: np.ndarray) -> int:
    packed = (
        arr[..., 0].astype(np.uint32) << 16
    ) | (arr[..., 1].astype(np.uint32) << 8) | arr[..., 2].astype(np.uint32)
    return int(np.unique(packed).size)


def top8_quant_coverage(arr: np.ndarray) -> float:
    q = (arr >> 4).astype(np.uint32)
    bins = (q[..., 0] << 8) | (q[..., 1] << 4) | q[..., 2]
    counts = np.bincount(bins.ravel(), minlength=4096)
    top8 = np.sort(counts)[-8:].sum()
    return float(top8 / bins.size)


def sha256_of(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check(path: Path, lock: dict) -> dict:
    """후보 스타일 검사 — 경로 무관, 등록 여부와 독립."""
    try:
        label = path.resolve().relative_to(ROOT).as_posix()
    except ValueError:
        label = str(path)
    result: dict = {"path": label, "failures": [], "warnings": []}
    if not path.exists():
        result["failures"].append("file does not exist")
        result["ok"] = False
        return result

    family = _family(lock)
    gates = style_lock.gates_for_family(lock, FAMILY)
    canvas = family["camera"]["canvas"]

    kb = path.stat().st_size / 1024.0
    result["kb"] = round(kb, 1)

    with Image.open(path) as im:
        fmt = im.format
        size = im.size
        mode = im.mode
        arr = np.asarray(im.convert("RGB"))

    # (a) 컨테이너 계약: WebP · 정확히 800x600 · RGB(알파 없음)
    if fmt != "WEBP":
        result["failures"].append(f"format {fmt} != WEBP")
    if size != (canvas["width"], canvas["height"]):
        result["failures"].append(
            f"size {size[0]}x{size[1]} != {canvas['width']}x{canvas['height']}"
        )
    if mode != "RGB":
        result["failures"].append(f"mode {mode} != RGB (알파/팔레트 금지)")

    # (b) 파일 크기 하드 밴드
    kb_lo, kb_hi = gates["fileKB"]
    if not (kb_lo <= kb <= kb_hi):
        result["failures"].append(f"fileKB {kb:.1f} outside [{kb_lo}, {kb_hi}]")
    # WARN: 문서 계약 밴드(85~105) — 하드 밴드보다 좁다
    doc_lo, doc_hi = gates["docContractKB"]
    if not (doc_lo <= kb <= doc_hi):
        result["warnings"].append(
            f"fileKB {kb:.1f} outside doc-contract [{doc_lo}, {doc_hi}] (warn-only)"
        )

    # (c) 상아 지면 비율
    body = np.array(gates["ivoryBody"], dtype=np.int16)
    tol = int(gates["ivoryTol"])
    ivory_mask = np.all(np.abs(arr.astype(np.int16) - body) <= tol, axis=-1)
    ivory_frac = float(ivory_mask.mean())
    result["ivoryFrac"] = round(ivory_frac, 4)
    if ivory_frac < gates["ivoryFracMin"]:
        result["failures"].append(
            f"ivoryFrac {ivory_frac:.3f} < min {gates['ivoryFracMin']}"
        )

    # (d) 상단 밴드 평탄 상아 패치 + (e)(f) 그레인
    patch_xy = find_ivory_patch(arr, gates)
    result["patchXY"] = list(patch_xy) if patch_xy else None
    if patch_xy is None:
        result["failures"].append(
            "no flat ivory patch in the top band (그레인 측정 불가 — 상아 지면 없음?)"
        )
        result["fine"] = None
        result["coarse"] = None
    else:
        x, y = patch_xy
        patch_mean = arr[y:y + PATCH_SIZE, x:x + PATCH_SIZE].reshape(-1, 3).mean(axis=0)
        result["patchMean"] = [round(float(c), 1) for c in patch_mean]
        window = gates["ivoryPatchWindow"]
        for channel, name in zip(patch_mean, ("r", "g", "b")):
            lo, hi = window[name]
            if not (lo <= channel <= hi):
                result["failures"].append(
                    f"ivory patch {name} mean {channel:.1f} outside [{lo}, {hi}]"
                )
        if not (patch_mean[0] > patch_mean[1] > patch_mean[2]):
            result["failures"].append(
                f"ivory patch not warm (R>G>B expected, got {result['patchMean']})"
            )

        fine = fine_grain_sd(arr, x, y)
        coarse = coarse_grain_sd(arr, x, y)
        result["fine"] = round(fine, 3)
        result["coarse"] = round(coarse, 3)
        f_lo, f_hi = gates["fineGrainSD"]
        if not (f_lo <= fine <= f_hi):
            result["failures"].append(
                f"fine grain SD {fine:.2f} outside [{f_lo}, {f_hi}] — 그레인 파이프라인 누락/이중 적용?"
            )
        c_lo, c_hi = gates["coarseGrainSD"]
        if not (c_lo <= coarse <= c_hi):
            result["failures"].append(
                f"coarse grain SD {coarse:.2f} outside [{c_lo}, {c_hi}]"
            )

    # (g) 색 다양성
    uniq = unique_colors(arr)
    result["uniqueColors"] = uniq
    if uniq < gates["uniqueColorsMin"]:
        result["failures"].append(
            f"uniqueColors {uniq} < min {gates['uniqueColorsMin']} (플랫/포스터라이즈 의심)"
        )

    # (h) 색상 존재 OR 게이트 — 고정 좌표 프로브는 정본(wave·A1Counter)이 못
    # 지나가므로 쓰지 않는다.
    presence = gates["palettePresence"]
    hue, sat, val = _hsv(arr)
    brick = _hue_window_fraction(hue, sat, val, presence["warmBrick"])
    teal = _hue_window_fraction(hue, sat, val, presence["mutedTeal"])
    result["warmBrickFrac"] = round(brick, 4)
    result["mutedTealFrac"] = round(teal, 4)
    min_either = presence["minEitherFrac"]
    if max(brick, teal) < min_either:
        result["failures"].append(
            f"palette presence: warmBrick {brick:.3f} AND mutedTeal {teal:.3f} both < {min_either}"
        )

    # WARN/하드: top-8 양자화 빈 커버리지 (>>4)
    top8 = top8_quant_coverage(arr)
    result["top8"] = round(top8, 4)
    if top8 > gates["top8QuantMax"]:
        result["failures"].append(
            f"top8 quant coverage {top8:.3f} > hard max {gates['top8QuantMax']} (색면 붕괴)"
        )
    elif top8 > gates["top8QuantWarn"]:
        result["warnings"].append(
            f"top8 quant coverage {top8:.3f} > warn {gates['top8QuantWarn']}"
        )

    result["ok"] = not result["failures"]
    return result


# ---- 사이드카(정본 명부) ----------------------------------------------------

def load_baseline() -> dict:
    return json.loads(BASELINE_PATH.read_text(encoding="utf-8"))


def _write_baseline(data: dict) -> None:
    BASELINE_PATH.write_text(
        json.dumps(data, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
        newline="\n",  # Windows 에서 CRLF 오염 방지
    )


def _family_dir_webps(lock: dict) -> list[Path]:
    files: list[Path] = []
    for directory in _family(lock)["dirs"]:
        d = ROOT / directory
        if d.is_dir():
            files.extend(sorted(d.glob("*.webp")))
    return files


def _stats_entry(path: Path, result: dict) -> dict:
    return {
        "sha256": sha256_of(path),
        "kb": result["kb"],
        "ivoryFrac": result["ivoryFrac"],
        "fine": result["fine"],
        "coarse": result["coarse"],
        "uniqueColors": result["uniqueColors"],
        "top8": result["top8"],
        "patchXY": result["patchXY"],
    }


def run_baseline(lock: dict) -> int:
    """전 가족 이미지 실측 -> 사이드카 작성 + 제안 게이트 블록 출력.

    STYLE_LOCK.json 은 절대 다시 쓰지 않는다 — 제안 숫자는 사람이 검토해
    수동으로 붙여넣는다(밴드는 승인된 실측이라는 원칙).
    """
    files = _family_dir_webps(lock)
    if not files:
        print("no *.webp found in family dirs")
        return 1
    entries: dict[str, dict] = {}
    rows: list[dict] = []
    for path in files:
        result = check(path, lock)
        rows.append(result)
        rel = path.resolve().relative_to(ROOT).as_posix()
        entries[rel] = _stats_entry(path, result)
        print(
            f"[measured] {rel}: kb={result['kb']} ivory={result.get('ivoryFrac')} "
            f"fine={result.get('fine')} coarse={result.get('coarse')} "
            f"uniq={result.get('uniqueColors')} top8={result.get('top8')}"
        )
    data = {
        "schema": 1,
        "measuredAt": _dt.date.today().isoformat(),
        "grainFormulaVersion": GRAIN_FORMULA_VERSION,
        "files": dict(sorted(entries.items())),  # --register 와 같은 정렬 규칙
    }
    _write_baseline(data)
    print(f"\nwrote {BASELINE_PATH.relative_to(ROOT).as_posix()} ({len(entries)} files)")

    # 제안 게이트 — 마진 정책은 2026-08-30 캘리브레이션 세션의 결정값.
    measured = [r for r in rows if r.get("fine") is not None]
    kbs = [r["kb"] for r in rows]
    fines = [r["fine"] for r in measured]
    coarses = [r["coarse"] for r in measured]
    ivories = [r["ivoryFrac"] for r in rows]
    uniqs = [r["uniqueColors"] for r in rows]
    top8s = [r["top8"] for r in rows]
    patch_means = [r["patchMean"] for r in measured if r.get("patchMean")]
    window = {
        name: [
            round(min(m[i] for m in patch_means) - 5, 1),
            round(max(m[i] for m in patch_means) + 5, 1),
        ]
        for i, name in enumerate(("r", "g", "b"))
    } if patch_means else None
    proposal = {
        "fileKB": [math.floor(min(kbs) - 5), math.ceil(max(kbs) + 8)],
        "fineGrainSD": [round(min(fines) - 0.9, 2), round(max(fines) + 1.5, 2)],
        "coarseGrainSD": [round(min(coarses) - 0.19, 2), round(max(coarses) + 0.5, 2)],
        "ivoryFracMin": round(min(ivories) - 0.08, 3),
        "ivoryPatchWindow": window,
        "observed": {
            "fileKB": [round(min(kbs), 1), round(max(kbs), 1)],
            "fineGrainSD": [round(min(fines), 3), round(max(fines), 3)],
            "coarseGrainSD": [round(min(coarses), 3), round(max(coarses), 3)],
            "ivoryFrac": [round(min(ivories), 3), round(max(ivories), 3)],
            "uniqueColors": [min(uniqs), max(uniqs)],
            "top8": [round(min(top8s), 3), round(max(top8s), 3)],
        },
    }
    print("\n제안 게이트(수동으로 STYLE_LOCK.json families.F-E-cards.gates 에 붙여넣기):")
    print(json.dumps(proposal, indent=2, ensure_ascii=False))
    members = sorted(Path(rel).stem for rel in entries)
    print("\nmembers (stems):")
    print(json.dumps(members, indent=2, ensure_ascii=False))
    return 0


def run_all(lock: dict) -> tuple[list[dict], int]:
    """등록 멤버 전수 검사 + sha256 대조 + 미등록 반입 검사 — 실제 잠금."""
    results: list[dict] = []
    failures = 0
    if not BASELINE_PATH.exists():
        print(f"[fail] {BASELINE_PATH} 이 없다 — 먼저 --baseline 을 돌려라")
        return results, 1
    baseline = load_baseline()
    registered = baseline.get("files", {})
    for rel, entry in registered.items():
        path = ROOT / rel
        if not path.exists():
            result = {"path": rel, "failures": ["registered file is missing"],
                      "warnings": [], "ok": False}
        else:
            result = check(path, lock)
            if sha256_of(path) != entry["sha256"]:
                result["failures"].append(
                    "sha256 mismatch — 정본 변조(사이드카와 다른 바이트). "
                    "의도된 재생성이면 --baseline/--register 로 명부를 갱신하라"
                )
                result["ok"] = False
        results.append(result)
    # 미등록 반입: 가족 디렉터리에 있으나 명부에 없는 *.webp
    for path in _family_dir_webps(lock):
        rel = path.resolve().relative_to(ROOT).as_posix()
        if rel not in registered:
            results.append({
                "path": rel,
                "failures": [
                    "미등록 반입 — 가족 디렉터리에 있으나 CARD_STYLE_BASELINE.json 명부에 없다. "
                    "정식 경로: scripts/finish_listening_card.sh (게이트 통과 시 자동 --register)"
                ],
                "warnings": [],
                "ok": False,
            })
    failures = sum(1 for r in results if not r.get("ok"))
    return results, failures


def run_register(lock: dict, target: Path) -> tuple[list[dict], int]:
    result = check(target, lock)
    if not result["ok"]:
        print(f"[fail] {result['path']}: 게이트 실패 — 등록 거부")
        return [result], 1
    try:
        rel = target.resolve().relative_to(ROOT).as_posix()
    except ValueError:
        result["failures"].append("등록 대상은 저장소 안에 있어야 한다")
        result["ok"] = False
        return [result], 1
    family_dirs = [d.rstrip("/") for d in _family(lock)["dirs"]]
    if str(Path(rel).parent.as_posix()) not in family_dirs:
        result["failures"].append(
            f"등록 대상이 가족 디렉터리 밖이다: {rel} (dirs: {family_dirs})"
        )
        result["ok"] = False
        return [result], 1

    baseline = load_baseline() if BASELINE_PATH.exists() else {
        "schema": 1,
        "measuredAt": _dt.date.today().isoformat(),
        "grainFormulaVersion": GRAIN_FORMULA_VERSION,
        "files": {},
    }
    baseline["files"][rel] = _stats_entry(target, result)
    baseline["files"] = dict(sorted(baseline["files"].items()))
    _write_baseline(baseline)
    print(f"[registered] {rel} -> {BASELINE_PATH.relative_to(ROOT).as_posix()}")

    # STYLE_LOCK.json members 배열 갱신 — 라운드트립 안정성 가드.
    stem = Path(rel).stem
    lock_path = style_lock.STYLE_LOCK_PATH
    original = lock_path.read_text(encoding="utf-8")
    data = json.loads(original)
    members = data["families"][FAMILY]["members"]
    if stem in members:
        print(f"[ok] {stem} 은 이미 members 에 있다")
        return [result], 0
    rendered = json.dumps(json.loads(original), indent=2, ensure_ascii=False) + "\n"
    if rendered != original:
        print(
            "[warn] STYLE_LOCK.json 이 json.dumps(indent=2) 라운드트립과 다르다 — "
            "무관한 바이트 변경을 피하려고 자동 쓰기를 생략한다. 아래 줄을 "
            f"families.{FAMILY}.members 에 수동으로 추가하라:"
        )
        print(f'        "{stem}",')
        return [result], 0
    members.append(stem)
    members.sort()
    lock_path.write_text(
        json.dumps(data, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
        newline="\n",  # Windows 에서 CRLF 오염 방지
    )
    print(f"[registered] {stem} -> STYLE_LOCK.json families.{FAMILY}.members")
    return [result], 0


def main(argv: list[str] | None = None) -> int:
    # Windows 콘솔(cp949)은 U+2014 등을 못 찍는다 — CI(utf-8)와 동일하게 맞춘다.
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(errors="replace")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("targets", nargs="*", help="후보 파일 경로(스타일 검사만)")
    parser.add_argument("--all", action="store_true",
                        help="등록 멤버 전수 + sha256 + 미등록 반입 검사")
    parser.add_argument("--baseline", action="store_true",
                        help="전량 실측 -> 사이드카 작성 + 제안 게이트 출력")
    parser.add_argument("--register", type=Path, metavar="FILE",
                        help="후보 검사 통과 시 사이드카+members 에 등록")
    parser.add_argument("--report", type=Path, help="전체 JSON 결과를 여기에 쓴다")
    args = parser.parse_args(argv)

    lock = style_lock.load_style_lock()
    if FAMILY not in lock["families"]:
        print(f"STYLE_LOCK.json 에 {FAMILY} 가족이 없다")
        return 1

    if args.baseline:
        return run_baseline(lock)

    if args.all:
        results, failures = run_all(lock)
    elif args.register:
        results, failures = run_register(lock, args.register)
    else:
        if not args.targets:
            parser.error("pass FILE targets, --all, --baseline or --register FILE")
        results = [check(ROOT / t if not Path(t).is_absolute() else Path(t), lock)
                   for t in args.targets]
        failures = sum(1 for r in results if not r.get("ok"))

    for result in results:
        status = "ok" if result.get("ok") else "fail"
        print(f"[{status}] {result['path']} kb={result.get('kb')} "
              f"ivory={result.get('ivoryFrac')} fine={result.get('fine')} "
              f"coarse={result.get('coarse')} uniq={result.get('uniqueColors')} "
              f"brick={result.get('warmBrickFrac')} teal={result.get('mutedTealFrac')} "
              f"top8={result.get('top8')}")
        for failure in result.get("failures", []):
            print(f"    FAIL: {failure}")
        for warning in result.get("warnings", []):
            print(f"    warn: {warning}")

    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(
            json.dumps(results, indent=2, ensure_ascii=False), encoding="utf-8"
        )

    print(f"\n{len(results) - failures}/{len(results)} passed")
    if failures:
        print(FAILURE_FOOTER)
    return failures


if __name__ == "__main__":
    raise SystemExit(main())
