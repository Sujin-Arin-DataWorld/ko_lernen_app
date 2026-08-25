import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'chaekgado/scroll_palette.dart';
import 'dancheong_stamp.dart';
import 'hanok/hanji_texture.dart';
import 'tokens.dart';

/// Bible §13 A — 9:16 한지 두루마리 공유 이미지. 검정 외곽선 없음, UI 크롬 없음.
///
/// **두루마리 자체는 그림이 아니라 에셋이다.** 종이·축·팔각 금 마구리·단청
/// 마름모는 전부 `assets/illustrations/share/share_scroll.png` 한 장이다
/// (BBANANA · GPT Image 2 · `docs/assets/recipes/cutout-fd-share-scroll.json`,
/// STYLE_LOCK.json family `F-D-share`). 코드가 그리는 건 그 위에 얹는
/// **매번 달라지는 글자**뿐이다 — 한국어·뜻·도장·꼬리말. 배경 PNG 한 장에
/// 글씨까지 구우면 긴 문장이 종이 밖으로 넘치거나 잘리니, 글자만은 캔버스에
/// 그려 길이에 맞춰 줄인다.
///
/// **무엇과 통일돼 있는가**
/// - 두루마리 = 실제 에셋(위). 앱 안 [ChaekgadoScroll]과는 같은 물건이 아니지만
///   같은 화풍("Faceted Minhwa") — 참조가 `chaekgado_prop_scroll.png`.
/// - 도장 = [paintDancheongStamp] — 도장첩에 찍히는 [DancheongStamp]와 같은 페인터.
/// - 벽 종이결 = [paintHanjiInto] — 화면의 [HanjiTexture]와 같은 페인터.
///
/// 에셋 로드가 실패하면(테스트 환경, 손상된 파일) [_ProceduralScroll]로
/// 내려간다 — 이 앱 모든 한옥 에셋의 공통 규약(`HanjiTexture`·`_RodFallback` 등).
///
/// **왜 라이트 톤 고정인가**: 공유 이미지는 남의 피드에 박제되는 인쇄물이다.
/// 보내는 사람의 다크모드 설정이 받는 사람 화면의 그림을 바꾸면 안 된다.
class ShareSlipRenderer {
  /// Instagram/카카오 스토리 규격.
  static const Size storySize = Size(1080, 1920);

  static const String _scrollAssetPath =
      'assets/illustrations/share/share_scroll.png';

  /// 두루마리 PNG — 세션 동안 한 번만 디코드해 둔다. 실패하면 null 로 남고
  /// [ShareSlipPainter]가 절차형 폴백을 그린다.
  static ui.Image? _scrollImage;
  static Future<ui.Image?>? _scrollImageLoad;

  static Future<ui.Image?> _loadScrollImage() {
    final cached = _scrollImage;
    if (cached != null) return Future.value(cached);
    return _scrollImageLoad ??= Future<ui.Image?>(() async {
      final data = await rootBundle.load(_scrollAssetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      _scrollImage = frame.image;
      return frame.image;
    }).catchError((Object _, StackTrace __) => null);
  }

  static Future<Uint8List> renderPng({
    required String korean,
    required String gloss,
    Size size = storySize,
    DancheongMotif motif = DancheongMotif.lotus,
  }) async {
    final scrollImage = await _loadScrollImage();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Offset.zero & size);
    ShareSlipPainter(
      korean: korean,
      gloss: gloss,
      motif: motif,
      scrollImage: scrollImage,
    ).paint(canvas, size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.round(),
      size.height.round(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();
    return bytes!.buffer.asUint8List();
  }
}

/// 두루마리 꼬리말. 브랜드명과 도메인이라 DE/EN/KO 가 같은 글자다 — 이 파일이
/// ARB 를 안 거치는 유일한 문자열이고, 도메인이 바뀔 때만 바뀐다.
const String _wordmark = '한글소리 · hangul-sori.com';

/// 두루마리의 기하 — 글이 앉는 칸과 실제 에셋을 그릴 자리.
///
/// 페인터와 테스트가 **같은 수**를 본다. 이 값들이 페인터 안에 리터럴로
/// 흩어져 있으면 "종이가 화면 끝에 닿지 않는다" 같은 검사가 상수를 베껴
/// 써야 하고, 구도를 손볼 때마다 조용히 어긋난다.
@immutable
class ShareSlipLayout {
  const ShareSlipLayout._({
    required this.unit,
    required this.paper,
    required this.contentArea,
    required this.wordmarkBand,
    required this.scrollImageRect,
  });

  /// 두루마리 PNG 의 종횡비 — `assets/illustrations/share/share_scroll.png`
  /// 785×1330. 이 비율을 안 지키고 그리면 축이 늘어나 다른 물건이 된다.
  static const double _scrollAspect = 785 / 1330;

  /// 그 PNG 안에서 **상아색 종이 칸**이 차지하는 자리(전체 이미지 대비 비율).
  /// 실측 2026-08-25 (현행 785×1330 PNG 기준):
  /// - 가로: 행 스캔에서 밝은(휘도>0.72) 픽셀이 과반인 열 x 91~694.
  /// - 세로 top: 중앙 열의 밝기 전이(짙은 축·배접 → 밝은 종이) y 212.
  /// - 세로 bottom: 밝은 행 과반 경계 y 1222.
  /// 이전 값(top 0.0872 등)은 재생성 전 PNG 실측이라 상단이 짙은 축 위로
  /// 올라가 있었다 — 그 상태로는 마진·꼬리말 픽셀 테스트가 전부 깨진다.
  ///
  /// 두루마리 PNG 를 다시 생성하면 이 네 값과 [_scrollAspect] 를 다시 재야
  /// 한다. 재는 법은 `docs/assets/recipes/cutout-fd-share-scroll.json` 참고.
  static const double _paperFracLeft = 0.1159;
  static const double _paperFracRight = 0.8841;
  static const double _paperFracTop = 0.1594;
  static const double _paperFracBottom = 0.9188;

  /// 그림 전체가 1080 폭 기준으로 잡혀 있다. 다른 크기로 렌더해도 같은 비율이
  /// 나오도록 모든 상수에 이 값을 곱한다.
  factory ShareSlipLayout.of(Size size) {
    final u = size.width / ShareSlipRenderer.storySize.width;

    // 두루마리를 **비율 그대로** 화면에 앉힌다. 위아래 7% 를 벽으로 남기고,
    // 그 높이에서 나오는 폭이 화면을 넘으면 폭에 맞춘다. 종이가 화면 끝에
    // 닿으면 두루마리가 아니라 그냥 배경이 된다 — 걸려 있다는 게 이 그림의
    // 전부다.
    var scrollH = size.height * 0.86;
    var scrollW = scrollH * _scrollAspect;
    final maxW = size.width * 0.92;
    if (scrollW > maxW) {
      scrollW = maxW;
      scrollH = scrollW / _scrollAspect;
    }
    final scrollImageRect = Rect.fromLTWH(
      (size.width - scrollW) / 2,
      (size.height - scrollH) / 2,
      scrollW,
      scrollH,
    );

    // 종이 칸은 그 그림 **안에서** 나온다 — 반대로 하면(종이를 먼저 정하고
    // 그림을 늘리면) 가로세로가 따로 놀아 축이 늘어난다.
    final paper = Rect.fromLTRB(
      scrollImageRect.left + scrollW * _paperFracLeft,
      scrollImageRect.top + scrollH * _paperFracTop,
      scrollImageRect.left + scrollW * _paperFracRight,
      scrollImageRect.top + scrollH * _paperFracBottom,
    );

    // 종이 칸 아래쪽은 꼬리말 몫으로 뗀다 — 실제 에셋은 종이와 그 아래 배접이
    // 색이 이어져 있어(폴백과 달리 층이 안 갈린다) 꼬리말도 종이 칸 **안**에
    // 앉혀야 한다. 안 그러면 바로 아래 짙은 축 위에 글자가 얹혀 안 읽힌다.
    final wordmarkBand = Rect.fromLTRB(
      paper.left,
      paper.bottom - 66 * u,
      paper.right,
      paper.bottom - 14 * u,
    );
    final contentArea = Rect.fromLTRB(
      paper.left,
      paper.top,
      paper.right,
      wordmarkBand.top - 18 * u,
    );

    return ShareSlipLayout._(
      unit: u,
      paper: paper,
      contentArea: contentArea,
      wordmarkBand: wordmarkBand,
      scrollImageRect: scrollImageRect,
    );
  }

  final double unit;

  /// 종이 칸 전체(꼬리말 포함) — 마진 검사·"종이 밖으로 안 넘친다" 테스트가
  /// 보는 바깥 경계.
  final Rect paper;

  /// 한국어·뜻·도장이 앉는 칸 — [paper]에서 [wordmarkBand]를 뗀 나머지.
  final Rect contentArea;

  /// 꼬리말이 앉는 종이 칸 아래쪽 좁은 띠.
  final Rect wordmarkBand;

  /// 두루마리 PNG 를 그릴 목적지 사각형 — 축·마구리까지 포함해 [paper]보다
  /// 넓고 크다.
  final Rect scrollImageRect;

  /// 글이 앉는 칸 — 종이에서 좌우 여백을 뺀 폭. 한국어도 뜻도 이 밖으로
  /// 나가지 않는다(뜻은 여기서 한 번 더 안쪽).
  Rect get textColumn => paper.deflate(76 * unit);
}

class ShareSlipPainter extends CustomPainter {
  const ShareSlipPainter({
    required this.korean,
    required this.gloss,
    this.motif = DancheongMotif.lotus,
    this.scrollImage,
  });

  final String korean;
  final String gloss;

  /// 도장 문양. 팩을 깨고 공유하면 그 팩의 문양(`motifForPackId`)을 넘겨
  /// 도장첩에 찍힌 것과 같은 도장이 나온다.
  final DancheongMotif motif;

  /// 미리 디코드해 둔 두루마리 PNG. null 이면 절차형 폴백을 그린다.
  final ui.Image? scrollImage;

  @override
  void paint(Canvas canvas, Size size) {
    final l = ShareSlipLayout.of(size);
    final u = l.unit;
    // 같은 단어는 언제 렌더해도 같은 종이결이 나온다 — 두 번 공유했을 때
    // 종이가 달라 보이면 다른 앱에서 만든 이미지처럼 읽힌다.
    final seed = korean.hashCode;

    _paintWall(canvas, size, seed);

    final image = scrollImage;
    if (image != null) {
      canvas.drawRect(
        l.scrollImageRect.shift(Offset(0, 10 * u)),
        Paint()
          ..color = const Color(0x2E3B271B)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 26 * u),
      );
      final src = Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );
      canvas.drawImageRect(
        image,
        src,
        l.scrollImageRect,
        Paint()..filterQuality = FilterQuality.high,
      );
    } else {
      _ProceduralScroll(korean: korean).paint(canvas, l, seed, u);
    }

    _paintContent(canvas, l, u);
    _paintWordmark(canvas, l.wordmarkBand, u);
  }

  // ────────────────────────────────────────────────────────────────────
  // 벽
  // ────────────────────────────────────────────────────────────────────

  void _paintWall(Canvas canvas, Size size, int seed) {
    // 값 사다리: 벽 < 종이. 둘이 같은 밝기면 족자가 배경에 녹아 그냥
    // 크림색 화면이 된다 — 이 그림이 물건으로 읽히는 건 이 순서 덕이다.
    paintHanjiInto(
      canvas,
      size,
      baseColor: SoriColors.lightSurface,
      noiseAlpha: 0.07,
      seed: seed ^ 0x1f7a6b,
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x8FC9BB96), Color(0xC2C9BB96)],
        ).createShader(Offset.zero & size),
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // 글 — 한국어 + 뜻 + 도장
  // ────────────────────────────────────────────────────────────────────

  /// 글과 도장을 **한 덩어리**로 묶어 [contentArea] 한가운데 앉힌다.
  ///
  /// 도장을 종이 오른쪽 아래 구석에 따로 박으면 글 아래로 빈 칸이 크게 뜨고,
  /// 그림이 위로 쏠려 미완성으로 읽힌다. 족자에서도 낙관은 구석이 아니라
  /// **마지막 줄 뒤**에 따라온다 — 그렇게 묶으면 여백이 위아래로 고르게 남아
  /// 비어 있는 게 의도로 보인다.
  void _paintContent(Canvas canvas, ShareSlipLayout l, double u) {
    final area = l.contentArea;
    final sealSide = 128 * u;
    final koLines = _fit(
      korean,
      maxWidth: l.textColumn.width,
      maxHeight: area.height * 0.50,
      maxFontSize: 170 * u,
      minFontSize: 44 * u,
      weight: FontWeight.w700,
      lineHeight: 1.18,
      color: SoriColors.lightText,
    );

    final hasGloss = gloss.trim().isNotEmpty;
    final glossLines = hasGloss
        ? _fit(
            gloss,
            maxWidth: l.textColumn.width - 32 * u,
            maxHeight: area.height * 0.19,
            maxFontSize: 42 * u,
            minFontSize: 24 * u,
            weight: FontWeight.w500,
            lineHeight: 1.34,
            // 먹 78% — 실측한 실제 종이 톤(약 RGB 230,190,122, 순백이 아니라
            // 따뜻한 아이보리) 위에서 4.9:1(AA). 72% 는 이 톤 위에서 4.89:1로
            // 문턱에 바짝 붙어 종이결 밝은 쪽에서 새는 지점이 생겼다.
            color: SoriColors.lightText.withValues(alpha: 0.78),
          )
        : const _FittedText.empty();

    final glossGap = hasGloss ? 36 * u : 0.0;
    final sealGap = 44 * u;
    final total =
        koLines.height + glossGap + glossLines.height + sealGap + sealSide;

    var y = area.center.dy - total / 2;
    koLines.paint(canvas, area.center.dx, y);
    y += koLines.height;

    if (hasGloss) {
      y += glossGap;
      glossLines.paint(canvas, area.center.dx, y);
      y += glossLines.height;
    }

    y += sealGap;
    canvas.save();
    canvas.translate(area.right - sealSide - 84 * u, y);
    paintDancheongStamp(
      canvas,
      Size(sealSide, sealSide),
      motif: motif,
      intensity: 0.92,
    );
    canvas.restore();
  }

  /// 한국어를 **어절 단위로만** 접고, 접어도 안 들어가면 글자를 줄인다.
  ///
  /// Flutter 기본 줄바꿈은 한글을 음절로 쪼개서 `포기하지` 가 `포기하` / `지`
  /// 로 갈린다(`SoriPhraseWrap` 이 화면에서 푸는 것과 같은 문제). 캔버스엔
  /// 위젯을 못 세우니 같은 규칙을 여기서 다시 세운다.
  _FittedText _fit(
    String text, {
    required double maxWidth,
    required double maxHeight,
    required double maxFontSize,
    required double minFontSize,
    required FontWeight weight,
    required double lineHeight,
    required Color color,
  }) {
    final tokens = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) return const _FittedText.empty();

    var lo = minFontSize;
    var hi = maxFontSize;
    var best = _layout(
      tokens,
      minFontSize,
      weight,
      lineHeight,
      color,
      maxWidth,
    );
    // 12 번이면 44~170pt 구간이 0.04pt 아래로 좁혀진다.
    for (var i = 0; i < 12; i++) {
      final mid = (lo + hi) / 2;
      final candidate = _layout(
        tokens,
        mid,
        weight,
        lineHeight,
        color,
        maxWidth,
      );
      // `brokeToken` 을 실패로 세는 게 이 탐색의 핵심이다. 어절 안을 끊는 것도
      // "들어간다"로 쳐 주면 `안녕하세요` 를 `안녕하`/`세요` 로 쪼개 놓고
      // 글씨를 더 키우는 쪽이 이겨 버린다 — 먼저 글씨를 줄여야 한다.
      if (!candidate.brokeToken &&
          candidate.width <= maxWidth &&
          candidate.height <= maxHeight) {
        best = candidate;
        lo = mid;
      } else {
        hi = mid;
      }
    }
    // 제일 작은 글씨로도 칸에 안 들어가는 길이가 올 수 있다(붙여넣은 문단 등).
    // 그때 [best] 는 넘치는 배치다 — 그대로 그리면 글이 종이를 벗어나 배접
    // 위로 흘러나간다. 줄을 잘라 말줄임으로 끝내는 게 그림이 깨지는 것보다 낫다.
    return best.height > maxHeight ? best.clampedTo(maxHeight) : best;
  }

  _FittedText _layout(
    List<String> tokens,
    double fontSize,
    FontWeight weight,
    double lineHeight,
    Color color,
    double maxWidth,
  ) {
    final style = TextStyle(
      fontFamily: SoriFonts.sans,
      fontSize: fontSize,
      fontWeight: weight,
      height: lineHeight,
      letterSpacing: -0.02 * fontSize,
      color: color,
    );

    // 자 하나를 돌려 쓴다. 크기를 이분 탐색하느라 이 함수가 13 번 돌고 매번
    // 어절마다 재니, 잴 때마다 [TextPainter] 를 새로 만들면 한 장 그리는 데
    // 네이티브 Paragraph 가 수백 개 뜬다 — 전부 GC 될 때까지 안 풀린다.
    final scratch = TextPainter(textDirection: TextDirection.ltr, maxLines: 1);
    Size measure(String s) {
      scratch
        ..text = TextSpan(text: s, style: style)
        ..layout();
      return scratch.size;
    }

    final lines = <String>[];
    var brokeToken = false;
    var current = '';
    for (final token in tokens) {
      // 어절 하나가 칸보다 넓으면 그 어절 **안**에서 끊는다 — 마지막 수단.
      // `한국어능력시험준비반수강생모집안내문` 이나 독일어 합성명사
      // (`Rindfleischetikettierungs…`) 는 글자를 줄여도 한 줄에 안 들어간다.
      // 안 끊으면 글이 종이를 넘어 배접 위로 나간다.
      if (measure(token).width > maxWidth) {
        brokeToken = true;
        if (current.isNotEmpty) {
          lines.add(current);
          current = '';
        }
        final pieces = _breakToken(token, measure, maxWidth);
        lines.addAll(pieces.take(pieces.length - 1));
        // 마지막 조각엔 다음 어절이 붙을 수 있다.
        current = pieces.last;
        continue;
      }
      final candidate = current.isEmpty ? token : '$current $token';
      if (measure(candidate).width <= maxWidth) {
        current = candidate;
      } else {
        lines.add(current);
        current = token;
      }
    }
    if (current.isNotEmpty) lines.add(current);

    var width = 0.0;
    var height = 0.0;
    for (final line in lines) {
      final size = measure(line);
      if (size.width > width) width = size.width;
      height += size.height;
    }
    scratch.dispose();
    return _FittedText(
      lines: lines,
      style: style,
      width: width,
      height: height,
      brokeToken: brokeToken,
    );
  }

  /// 칸보다 넓은 어절 하나를 글자 단위로 나눈다. 코드포인트로 도니 한글
  /// 음절과 서러게이트 쌍이 반토막 나지 않는다.
  List<String> _breakToken(
    String token,
    Size Function(String) measure,
    double maxWidth,
  ) {
    final pieces = <String>[];
    var buffer = StringBuffer();
    for (final rune in token.runes) {
      final char = String.fromCharCode(rune);
      if (buffer.isNotEmpty && measure('$buffer$char').width > maxWidth) {
        pieces.add(buffer.toString());
        buffer = StringBuffer(char);
      } else {
        buffer.write(char);
      }
    }
    if (buffer.isNotEmpty) pieces.add(buffer.toString());
    // 글자 하나가 칸보다 넓은 극단(아주 큰 글씨)에서도 빈 목록을 돌려주지 않는다
    // — 부르는 쪽이 `pieces.last` 를 본다.
    return pieces.isEmpty ? [token] : pieces;
  }

  // ────────────────────────────────────────────────────────────────────
  // 꼬리말
  // ────────────────────────────────────────────────────────────────────

  void _paintWordmark(Canvas canvas, Rect band, double u) {
    // 종이 칸 **안** 맨 아래 — 잘라 다시 올려도 출처가 같이 남는다.
    final painter = TextPainter(
      text: TextSpan(
        text: _wordmark,
        style: TextStyle(
          fontFamily: SoriFonts.sans,
          fontSize: 27 * u,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6 * u,
          // 먹 78% — 실측 종이 톤 위에서 5.5:1(AA 여유). _paintContent 의
          // 뜻 줄과 같은 이유로 같은 값을 쓴다.
          color: SoriColors.lightText.withValues(alpha: 0.78),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        band.center.dx - painter.width / 2,
        band.center.dy - painter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant ShareSlipPainter oldDelegate) {
    return oldDelegate.korean != korean ||
        oldDelegate.gloss != gloss ||
        oldDelegate.motif != motif ||
        oldDelegate.scrollImage != scrollImage;
  }
}

/// 두루마리 PNG 를 못 읽었을 때만 쓰는 절차형 폴백 — 이 앱 모든 한옥 에셋의
/// 공통 규약(`HanjiTexture`·`_RodFallback` 등)을 여기서도 지킨다.
/// 색은 [SoriScrollPalette] — 앱 안 [ChaekgadoScroll]과 같은 소스.
class _ProceduralScroll {
  const _ProceduralScroll({required this.korean});

  final String korean;

  void paint(Canvas canvas, ShareSlipLayout l, int seed, double u) {
    final rodH = 46 * u;
    final topRod = Rect.fromLTWH(
      l.scrollImageRect.left,
      l.scrollImageRect.top,
      l.scrollImageRect.width,
      rodH,
    );
    final bottomRod = Rect.fromLTWH(
      l.scrollImageRect.left,
      l.scrollImageRect.bottom - rodH,
      l.scrollImageRect.width,
      rodH,
    );
    final mount = Rect.fromLTRB(
      l.scrollImageRect.left,
      topRod.bottom,
      l.scrollImageRect.right,
      bottomRod.top,
    );

    canvas.drawRect(mount, Paint()..color = SoriColors.lightSurfaceAlt);
    canvas.drawRect(
      mount,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * u
        ..color = SoriColors.lightBorder,
    );

    canvas.save();
    canvas.clipRect(l.paper);
    canvas.translate(l.paper.left, l.paper.top);
    paintHanjiInto(
      canvas,
      l.paper.size,
      baseColor: SoriScrollPalette.paper,
      noiseAlpha: 0.16,
      seed: seed,
    );
    canvas.restore();
    canvas.drawRect(
      l.paper,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * u
        ..color = SoriColors.lightBorderStrong.withValues(alpha: 0.55),
    );

    _paintDancheongBand(canvas, Offset(mount.center.dx, mount.top + 40 * u), u);
    _paintRod(canvas, topRod, u, seed);
    _paintRod(canvas, bottomRod, u, seed ^ 0x5bf03635);
  }

  void _paintDancheongBand(Canvas canvas, Offset center, double u) {
    const count = 7;
    final step = 56 * u;
    final halfW = 15 * u;
    final halfH = 19 * u;
    final teal = Paint()..color = SoriScrollPalette.dancheongTeal;
    final gold = Paint()..color = SoriScrollPalette.dancheongGold;
    final brick = Paint()..color = SoriScrollPalette.dancheongBrick;
    for (var i = 0; i < count; i++) {
      final cx = center.dx + (i - (count - 1) / 2) * step;
      canvas.drawPath(_diamond(Offset(cx, center.dy), halfW, halfH), teal);
      canvas.drawPath(
        _diamond(Offset(cx, center.dy), halfW * 0.52, halfH * 0.52),
        i == count ~/ 2 ? brick : gold,
      );
    }
  }

  Path _diamond(Offset c, double halfW, double halfH) => Path()
    ..moveTo(c.dx, c.dy - halfH)
    ..lineTo(c.dx + halfW, c.dy)
    ..lineTo(c.dx, c.dy + halfH)
    ..lineTo(c.dx - halfW, c.dy)
    ..close();

  void _paintRod(Canvas canvas, Rect rod, double u, int seed) {
    final radius = Radius.circular(rod.height / 2);
    final body = RRect.fromRectAndRadius(rod, radius);
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            SoriScrollPalette.rodTop,
            SoriScrollPalette.rodMid,
            SoriScrollPalette.rodBottom,
          ],
          stops: [0, 0.34, 1],
        ).createShader(rod),
    );

    canvas.save();
    canvas.clipRRect(body);
    final rng = math.Random(seed);
    final facets = (rod.width / (34 * u)).round().clamp(6, 40);
    final step = rod.width / facets;
    final facet = Paint();
    for (var i = 0; i < facets; i++) {
      final x = rod.left + i * step;
      final up = i.isEven;
      facet.color = (up ? Colors.white : Colors.black).withValues(
        alpha: up
            ? 0.03 + rng.nextDouble() * 0.03
            : 0.07 + rng.nextDouble() * 0.07,
      );
      canvas.drawPath(
        Path()
          ..moveTo(x, up ? rod.top : rod.bottom)
          ..lineTo(x + step, up ? rod.top : rod.bottom)
          ..lineTo(x + step / 2, up ? rod.bottom : rod.top)
          ..close(),
        facet,
      );
    }
    canvas.restore();

    _paintRodCap(canvas, rod, u, atLeft: true);
    _paintRodCap(canvas, rod, u, atLeft: false);
  }

  void _paintRodCap(Canvas canvas, Rect rod, double u, {required bool atLeft}) {
    final rect = Rect.fromCenter(
      center: Offset(atLeft ? rod.left : rod.right, rod.center.dy),
      width: 38 * u,
      height: rod.height + 16 * u,
    );
    final cut = math.min(rect.width, rect.height) * 0.36;
    final path = Path()
      ..moveTo(rect.left + cut, rect.top)
      ..lineTo(rect.right - cut, rect.top)
      ..lineTo(rect.right, rect.top + cut)
      ..lineTo(rect.right, rect.bottom - cut)
      ..lineTo(rect.right - cut, rect.bottom)
      ..lineTo(rect.left + cut, rect.bottom)
      ..lineTo(rect.left, rect.bottom - cut)
      ..lineTo(rect.left, rect.top + cut)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SoriScrollPalette.capTop, SoriScrollPalette.capBottom],
        ).createShader(rect),
    );
    canvas.drawLine(
      Offset(atLeft ? rect.right : rect.left, rod.top + 2 * u),
      Offset(atLeft ? rect.right : rect.left, rod.bottom - 2 * u),
      Paint()
        ..strokeWidth = 2 * u
        ..color = SoriScrollPalette.rodMid.withValues(alpha: 0.55),
    );
  }
}

/// 어절 단위로 접힌 여러 줄 — 폭/높이를 먼저 재고 나중에 그린다.
///
/// 줄을 [TextPainter] 가 아니라 **글자와 크기**로 들고 있는다. 크기 이분
/// 탐색이 후보 배치를 12 개 버리는데, 후보마다 페인터를 쥐고 있으면 버려진
/// 배치의 네이티브 Paragraph 까지 전부 살아 있게 된다.
class _FittedText {
  const _FittedText({
    required this.lines,
    required this.style,
    required this.width,
    required this.height,
    this.brokeToken = false,
  });

  const _FittedText.empty()
    : lines = const [],
      style = null,
      width = 0,
      height = 0,
      brokeToken = false;

  final List<String> lines;
  final TextStyle? style;
  final double width;
  final double height;

  /// 어절 **안**을 끊어야 했다는 표시. 크기 탐색이 이걸 실패로 세서, 낱말을
  /// 쪼개기 전에 글씨를 먼저 줄인다.
  final bool brokeToken;

  /// [maxHeight] 에 들어가는 줄까지만 남기고 말줄임으로 끝낸다.
  ///
  /// 마지막 줄의 끝 글자를 하나 빼고 `…` 를 넣으므로 줄이 더 넓어지지 않는다
  /// — 세로를 맞추려다 가로로 넘치면 고친 게 아니다.
  _FittedText clampedTo(double maxHeight) {
    if (lines.isEmpty || height <= maxHeight) return this;
    final lineHeight = height / lines.length;
    final keep = (maxHeight / lineHeight).floor().clamp(1, lines.length);
    if (keep == lines.length) return this;

    final kept = lines.take(keep).toList();
    final last = kept.last;
    final runes = last.runes.toList();
    kept[keep - 1] =
        '${String.fromCharCodes(runes.take(runes.length > 1 ? runes.length - 1 : 1))}…';
    return _FittedText(
      lines: kept,
      style: style,
      width: width,
      height: lineHeight * keep,
      brokeToken: brokeToken,
    );
  }

  void paint(Canvas canvas, double centerX, double top) {
    var y = top;
    for (final line in lines) {
      final painter = TextPainter(
        text: TextSpan(text: line, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      painter.paint(canvas, Offset(centerX - painter.width / 2, y));
      y += painter.height;
      painter.dispose();
    }
  }
}
