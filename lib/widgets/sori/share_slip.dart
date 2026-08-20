import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'dancheong_stamp.dart';
import 'hanok/hanji_texture.dart';
import 'tokens.dart';

/// 두루마리 공유 이미지 — Content UI Bible §13 안 A (잠금, 2026-08-19).
///
/// 9:16 세로 "이야기" 이미지. 인스타/카톡 스토리에 그대로 올라가고, 1:1로
/// 잘라 써도 뜻이 살아야 한다. 9:16 프레임을 정중앙 1:1로 크롭하면 세로
/// 22%~78% 만 남는다(`(H-W)/2H` 계산 — `docs/LISTENING_CARD_ART_SPEC.md`의
/// 세이프 영역 규약과 같은 방식) — 한국어·뜻·도장을 전부 그 안에 둔다.
///
/// 새 시각 언어를 만들지 않는다. 이미 배선된 두루마리(`chaekgado/scroll_sheet.dart`
/// 의 `_Rod`/`_RodCap`)와 서재 목재(`chaekgado/shelf_case.dart` 의 `_Pillar`/
/// plank)의 실측 팔레트를 그대로 옮겼다 — "듣기 책가도와 세계가 같다"는 §13
/// 확정 이유가 색이 갈라지면 깨진다. [_SlipPalette] 는 그 두 파일의 private
/// 팔레트를 복제한 것이라, hex 를 바꾸면 세 파일을 함께 맞춰야 한다.
///
/// Theme/Localizations 없이도 그려야 한다 — [renderShareSlipToPng] 가 오프
/// 스크린 렌더 트리(라이브 앱 위젯 트리 밖)에서 이 위젯을 그리기 때문에, 색은
/// 전부 상수이고 폰트는 `SoriFonts.sans` 하드코딩이다.
class ShareSlip extends StatelessWidget {
  const ShareSlip({
    super.key,
    required this.korean,
    required this.gloss,
    this.size = const Size(1080, 1920),
  });

  final String korean;
  final String gloss;

  /// 논리 픽셀이 아니라 목표 산출 픽셀 — [renderShareSlipToPng] 가
  /// `pixelRatio: 1` 로 캡처하므로 여기 값이 곧 PNG 크기다.
  final Size size;

  @override
  Widget build(BuildContext context) {
    final w = size.width;
    final h = size.height;
    final plankHeight = h * 0.085;
    final pillarWidth = w * 0.03;

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          HanjiTexture(
            color: _SlipPalette.paper,
            noiseAlpha: 0.05,
            child: const SizedBox.expand(),
          ),
          CustomPaint(
            painter: _ChaekgadoFramePainter(
              plankHeight: plankHeight,
              pillarWidth: pillarWidth,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.12),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    korean,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: SoriFonts.sans,
                      // koDisplay(28sp)/390dp 화면비를 그대로 옮김 — 앱 안팎에서
                      // "한국어가 히어로"인 비율이 같다(§3 콘텐츠 타이포 역할).
                      fontSize: w * (28 / 390),
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.1,
                      height: 1.25,
                      color: _SlipPalette.ink,
                    ),
                  ),
                  SizedBox(height: h * 0.022),
                  Text(
                    gloss,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: SoriFonts.sans,
                      fontSize: w * (17 / 390), // gloss(17sp)/390dp
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.3,
                      height: 1.4,
                      color: _SlipPalette.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 우측 하단 작은 한글소리 도장 — 세이프 존(세로 78%) 안쪽에 둔다.
          // 팩 주제 모티프가 아니라 앱 자체의 인장이므로 lotus(정본 fallback
          // 모티프)로 고정한다. 호랑이/까치 없음 — §13 "도장만" 규약.
          Positioned(
            right: w * 0.09,
            bottom: h * 0.235,
            child: const DancheongStamp(
              motif: DancheongMotif.lotus,
              size: 92,
              stamped: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// [ShareSlip] 이 쓰는 실측 팔레트. `scroll_sheet.dart` 의 `_ScrollPalette`,
/// `shelf_case.dart` 의 `_ShelfPalette` 와 같은 소스에서 나눠 가진 값이다.
abstract final class _SlipPalette {
  static const Color paper = Color(0xFFFFFDF6);
  static const Color ink = SoriColors.lightText; // 0xFF1A1F1D — 먹
  static const Color inkMuted = SoriColors.lightTextMuted; // 0xFF5C6660
  static const Color rodTop = Color(0xFF7A5636);
  static const Color rodMid = Color(0xFF3E2B1B);
  static const Color rodBottom = Color(0xFF5C4028);
  static const Color capTop = Color(0xFFE8BC6A);
  static const Color capBottom = Color(0xFFB98A34);
  static const Color plank = Color(0xFF8E6646);
  static const Color plankLip = Color(0xFFA87F55);
}

/// 위·아래 널판이 두루마리를 살짝 자르고, 축(軸)이 그 경계에 걸리고, 안쪽으로
/// 말린 자국이 부드럽게 번지는 것 — "책가도 나무 칸이 두루마리 위아래를 살짝
/// 자른다"(§13) 를 그대로 그린다.
class _ChaekgadoFramePainter extends CustomPainter {
  const _ChaekgadoFramePainter({
    required this.plankHeight,
    required this.pillarWidth,
  });

  final double plankHeight;
  final double pillarWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final pillarPaint = Paint()..color = _SlipPalette.plank;
    canvas.drawRect(Rect.fromLTWH(0, 0, pillarWidth, h), pillarPaint);
    canvas.drawRect(
      Rect.fromLTWH(w - pillarWidth, 0, pillarWidth, h),
      pillarPaint,
    );

    final plankPaint = Paint()..color = _SlipPalette.plank;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, plankHeight), plankPaint);
    canvas.drawRect(
      Rect.fromLTWH(0, h - plankHeight, w, plankHeight),
      plankPaint,
    );
    final lipPaint = Paint()
      ..color = _SlipPalette.plankLip
      ..strokeWidth = h * 0.0025;
    canvas.drawLine(Offset(0, plankHeight), Offset(w, plankHeight), lipPaint);
    canvas.drawLine(
      Offset(0, h - plankHeight),
      Offset(w, h - plankHeight),
      lipPaint,
    );

    final rodHeight = h * 0.013;
    _drawRod(
      canvas,
      Rect.fromLTWH(pillarWidth, plankHeight, w - pillarWidth * 2, rodHeight),
    );
    _drawRod(
      canvas,
      Rect.fromLTWH(
        pillarWidth,
        h - plankHeight - rodHeight,
        w - pillarWidth * 2,
        rodHeight,
      ),
    );

    // 말린 자국 — scroll_sheet.dart `_Sheet` 의 "축 아래 그림자"와 같은 계산.
    final curlHeight = h * 0.045;
    _drawCurlShadow(
      canvas,
      Rect.fromLTWH(0, plankHeight + rodHeight, w, curlHeight),
      reversed: false,
    );
    _drawCurlShadow(
      canvas,
      Rect.fromLTWH(
        0,
        h - plankHeight - rodHeight - curlHeight,
        w,
        curlHeight,
      ),
      reversed: true,
    );
  }

  void _drawCurlShadow(Canvas canvas, Rect rect, {required bool reversed}) {
    final begin = reversed ? Alignment.bottomCenter : Alignment.topCenter;
    final end = reversed ? Alignment.topCenter : Alignment.bottomCenter;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: begin,
        end: end,
        colors: const [Color(0x38785F3C), Color(0x00785F3C)],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _drawRod(Canvas canvas, Rect rect) {
    final rodPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _SlipPalette.rodTop,
          _SlipPalette.rodMid,
          _SlipPalette.rodBottom,
        ],
        stops: [0, 0.58, 1],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
      rodPaint,
    );

    final capSize = rect.height * 2.2;
    final capRect = Rect.fromLTWH(
      0,
      rect.top - capSize * 0.42,
      capSize * 0.42,
      capSize,
    );
    final capPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_SlipPalette.capTop, _SlipPalette.capBottom],
      ).createShader(capRect);
    for (final onLeft in [true, false]) {
      final dx = onLeft
          ? rect.left - capRect.width * 0.55
          : rect.right - capRect.width * 0.45;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          capRect.shift(Offset(dx, 0)),
          Radius.circular(capRect.width / 2.4),
        ),
        capPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChaekgadoFramePainter oldDelegate) =>
      oldDelegate.plankHeight != plankHeight ||
      oldDelegate.pillarWidth != pillarWidth;
}

/// [ShareSlip] 을 라이브 위젯 트리 밖에서 렌더링해 PNG 바이트로 캡처한다.
///
/// `RenderView`/`BuildOwner`/`PipelineOwner` 를 직접 만들어 쓰는 것은 앱을
/// 흔들지 않고 화면 밖 렌더 오브젝트를 파이프라인에 태우는 정식 용도다
/// (`PipelineOwner` 문서: "can be created separately from the binding to
/// drive off-screen render objects"). Overlay 에 끼워 넣고 프레임을 기다리는
/// 방식은 실기기 vsync 타이밍에 기대는 데다 `flutter_test`의 수동 pump 와
/// 잘 안 맞아 대신 이 방식을 쓴다 — 레이아웃·페인트를 동기적으로 flush 하므로
/// 위젯 테스트에서도 프레임 하나 기다릴 필요가 없다.
///
/// [context] 를 받지 않는다 — [ShareSlip] 이 Theme/Localizations 에 기대지
/// 않게 설계했기 때문에 완전히 독립적으로 그릴 수 있다.
Future<Uint8List?> renderShareSlipToPng({
  required String korean,
  required String gloss,
  Size size = const Size(1080, 1920),
  double pixelRatio = 1,
}) async {
  if (korean.isEmpty) {
    return null;
  }
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final repaintBoundary = RenderRepaintBoundary();

  final renderView = RenderView(
    view: view,
    configuration: ViewConfiguration(
      logicalConstraints: BoxConstraints.tight(size),
      physicalConstraints: BoxConstraints.tight(size * pixelRatio),
      devicePixelRatio: pixelRatio,
    ),
    child: repaintBoundary,
  );

  final pipelineOwner = PipelineOwner()..rootNode = renderView;
  renderView.prepareInitialFrame();

  final buildOwner = BuildOwner(focusManager: FocusManager());
  final rootElement =
      RenderObjectToWidgetAdapter<RenderBox>(
        container: repaintBoundary,
        debugShortDescription: '[ShareSlip offscreen render]',
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: ShareSlip(korean: korean, gloss: gloss, size: size),
        ),
      ).attachToRenderTree(buildOwner);

  buildOwner
    ..buildScope(rootElement)
    ..finalizeTree();

  pipelineOwner
    ..flushLayout()
    ..flushCompositingBits()
    ..flushPaint();

  final image = await repaintBoundary.toImage(pixelRatio: pixelRatio);
  try {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
