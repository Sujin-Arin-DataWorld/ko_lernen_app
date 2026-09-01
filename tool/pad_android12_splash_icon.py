#!/usr/bin/env python3
"""Android 12+ 스플래시 아이콘 세이프존 패딩.

OS 가 android:windowSplashScreenAnimatedIcon 에 강제하는 세이프존은 전체
캔버스 대비 약 2/3 지름의 원형/사각 마스크다(공식 권장: 콘텐츠를 캔버스의
약 55~60% 폭 안에 배치). 이 스크립트는 기존 풀-블리드 아이콘을 투명
패딩으로 감싸 1152x1152 캔버스 중앙에, 콘텐츠 폭이 캔버스의 CONTENT_RATIO
만큼만 차지하도록 다시 그린다.

실행: python tool/pad_android12_splash_icon.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

SOURCE = Path("assets/icons/HanLogo.png")
# native_splash_src/ 는 pubspec.yaml 의 `assets:` 목록(assets/icons/, 비재귀)에
# 없는 하위 폴더다 — 이 파일은 flutter_native_splash:create 의 입력일 뿐 Flutter
# 런타임이 로드하지 않으므로, assets/icons/ 바로 아래 두면
# test/asset_orphan_guard_test.dart("번들에 들어가는 모든 에셋을 lib/ 가 부른다")
# 가 lib/ 미참조 고아로 잡아 AAB 에 불필요하게 번들된다. 같은 이유로
# tool/art_sources/ 에 SVG 소스를 두는 기존 관행과 동일한 패턴이다.
OUTPUT = Path("assets/icons/native_splash_src/HanLogo_android12_safe.png")
CANVAS_SIZE = 1152
# 세이프존 안쪽으로 여유를 두기 위해 55% — 구글 권장 상한(~66%)보다
# 보수적으로 잡아 2회 회귀 재발을 방지한다.
CONTENT_RATIO = 0.55


def build_safe_icon() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    content_side = int(CANVAS_SIZE * CONTENT_RATIO)
    resized = source.resize((content_side, content_side), Image.LANCZOS)

    canvas = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    offset = ((CANVAS_SIZE - content_side) // 2, (CANVAS_SIZE - content_side) // 2)
    canvas.paste(resized, offset, resized)
    # 추적된 산출물이 지워진 새 클론에서도 바로 돌도록 부모 디렉터리를 보장한다.
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(OUTPUT)

    bbox = canvas.getchannel("A").getbbox()
    assert bbox is not None, "패딩 후 콘텐츠가 사라졌다"
    content_w = bbox[2] - bbox[0]
    fraction = content_w / CANVAS_SIZE
    print(f"{OUTPUT}: {canvas.size}, content fraction of width = {fraction:.3f}")
    assert fraction <= 0.6, (
        f"콘텐츠가 세이프존을 넘을 수 있다(fraction={fraction:.3f} > 0.6) — "
        "CONTENT_RATIO 를 낮춰라."
    )


if __name__ == "__main__":
    build_safe_icon()
