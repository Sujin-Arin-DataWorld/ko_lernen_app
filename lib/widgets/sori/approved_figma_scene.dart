import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/generated/app_localizations.dart';
import '../app_loading.dart';
import 'c_gallery/c_materials.dart';
import 'tokens.dart';
import 'approved_chrome_assets.dart';
import 'image_navigation_bar.dart';

/// Approved Figma layers rendered with original art and native text.
/// Screen owners bind real state and callbacks instead of mockup data.
class ApprovedFigmaScene extends StatelessWidget {
  const ApprovedFigmaScene({
    super.key,
    required this.scene,
    this.top = 0,
    this.bottom = 858,
    this.text = const {},
    this.replacements = const {},
    this.hidden = const {},
    this.actions = const [],
    this.includeBackground = true,
    this.maxHeight,
  });
  final String scene;
  final double top, bottom;
  final Map<String, String> text;
  final Map<String, Widget> replacements;
  final Set<String> hidden;
  final List<FigmaSceneAction> actions;
  final bool includeBackground;

  /// Optional normal-size viewport budget. Only artwork/spacing compress;
  /// native type and 48dp action faces retain their dimensions.
  final double? maxHeight;
  static const root = 'assets/illustrations/concept_c/approved_20261018/';
  static final _cache = <String, Future<Map<String, dynamic>>>{};
  static final _loaded = <String, Map<String, dynamic>>{};
  static Future<Map<String, dynamic>> load(String file) =>
      _cache.putIfAbsent(file, () async {
        final data =
            jsonDecode(await rootBundle.loadString('$root$file'))
                as Map<String, dynamic>;
        _loaded[file] = data;
        return data;
      });

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: Future.wait([load(scene), load('figma-assets.json')]),
    initialData:
        _loaded.containsKey(scene) && _loaded.containsKey('figma-assets.json')
        ? [_loaded[scene]!, _loaded['figma-assets.json']!]
        : null,
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return SizedBox(
          height: maxHeight ?? bottom - top,
          child: snapshot.hasError
              ? Center(
                  child: Text(
                    AppL10n.of(context).catalogImageUnavailable,
                    style: SoriTextTheme.of(context).body,
                  ),
                )
              : const AppLoading(),
        );
      }
      final data = snapshot.data![0];
      final assets = snapshot.data![1];
      final nodes = (data['nodes'] as List).cast<Map<String, dynamic>>();
      // Keep artwork and labels inside their real native button so pressing
      // moves the visible control, not an empty hit target above it.
      FigmaSceneAction? owner(Map<String, dynamic> n) {
        final rect = Rect.fromLTWH(
          (n['x'] as num).toDouble(),
          (n['y'] as num).toDouble(),
          (n['w'] as num).toDouble(),
          (n['h'] as num).toDouble(),
        );
        return actions
            .where(
              (a) =>
                  a.rect.inflate(1).contains(rect.topLeft) &&
                  a.rect.inflate(1).contains(rect.bottomRight),
            )
            .firstOrNull;
      }

      return LayoutBuilder(
        builder: (context, bounds) {
          final width = math.min(bounds.maxWidth, 600.0);
          final scale = width / 402;
          // Artwork follows the Figma grid. Native text keeps its semantic
          // size and expands following rows instead of shrinking at 320dp.
          final textHeights = <String, double>{};
          final naturalHeights = <String, double>{};
          final rowGrowth = <double, double>{};
          for (final n in nodes) {
            final y = (n['y'] as num).toDouble();
            if (n['type'] != 'TEXT' ||
                hidden.contains(n['id']) ||
                y < top ||
                y >= bottom) {
              continue;
            }
            final painter = TextPainter(
              text: TextSpan(
                text: _value(n),
                style: _textStyle(context, n, widthScale: scale),
              ),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
              textAlign: _alignment(n),
            )..layout(maxWidth: math.max(1, (n['w'] as num) * scale));
            naturalHeights[n['id'] as String] = painter.height;
            painter.dispose();
          }
          var verticalScale = scale;
          double shift(double y) => rowGrowth.entries
              .where((row) => row.key <= y)
              .fold(0.0, (sum, row) => sum + row.value);
          double actionHeight(FigmaSceneAction action) => math.max(
            48,
            action.rect.height * verticalScale +
                shift((action.rect.bottom / 4).ceil() * 4.0) -
                shift(action.rect.top),
          );
          double sceneHeight = 0;
          for (var pass = 0; pass < 16; pass++) {
            rowGrowth.clear();
            textHeights.clear();
            for (final n in nodes) {
              final natural = naturalHeights[n['id']];
              if (natural == null) {
                continue;
              }
              final base = (n['h'] as num) * verticalScale;
              textHeights[n['id'] as String] = math.max(base, natural);
              final rowEnd =
                  (((n['y'] as num) + (n['h'] as num)) / 4).ceil() * 4.0;
              rowGrowth[rowEnd] = math.max(
                rowGrowth[rowEnd] ?? 0,
                math.max(0, natural - base),
              );
            }
            for (final action in actions) {
              final rowEnd = (action.rect.bottom / 4).ceil() * 4.0;
              final current =
                  action.rect.height * verticalScale +
                  shift(rowEnd) -
                  shift(action.rect.top);
              if (current < 48) {
                rowGrowth[rowEnd] = (rowGrowth[rowEnd] ?? 0) + 48 - current;
              }
            }
            sceneHeight = (bottom - top) * verticalScale + shift(bottom + 4);
            if (maxHeight == null ||
                sceneHeight <= maxHeight! + .25 ||
                verticalScale <= .05) {
              break;
            }
            verticalScale = math.max(
              .05,
              verticalScale * maxHeight! / sceneHeight,
            );
          }
          final extraHeight = shift(bottom + 4);
          double yFor(num y) =>
              (y.toDouble() - top) * verticalScale + shift(y.toDouble());
          double heightFor(Map<String, dynamic> n) {
            if (n['id'] == data['root']) {
              return (n['h'] as num) * verticalScale + extraHeight;
            }
            final base =
                textHeights[n['id']] ?? (n['h'] as num) * verticalScale;
            final action = owner(n);
            if (n['type'] != 'TEXT' &&
                action != null &&
                ((n['h'] as num) - action.rect.height).abs() < 2 &&
                ((n['y'] as num) - action.rect.top).abs() < 2) {
              return math.max(base, actionHeight(action));
            }
            return base;
          }

          return Center(
            child: SizedBox(
              width: width,
              height: sceneHeight,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  for (final n in nodes)
                    if (!hidden.contains(n['id']) &&
                        owner(n) == null &&
                        ((n['id'] == data['root'] && includeBackground) ||
                            ((n['y'] as num) >= top &&
                                (n['y'] as num) < bottom &&
                                n['id'] != data['root'])))
                      Positioned(
                        left: (n['x'] as num).toDouble() * scale,
                        top: yFor(n['y'] as num),
                        width: (n['w'] as num).toDouble() * scale,
                        height: heightFor(n),
                        child:
                            replacements[n['id']] ??
                            _layer(
                              context,
                              n,
                              assets,
                              scale,
                              compact: verticalScale < scale - .01,
                            ),
                      ),
                  for (final action in actions)
                    Positioned(
                      left: action.rect.left * scale,
                      top: yFor(action.rect.top),
                      width: action.rect.width * scale,
                      height: actionHeight(action),
                      child: CImageTap(
                        key: action.key,
                        label: action.label,
                        onTap: action.onTap,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (final n in nodes)
                              if (!hidden.contains(n['id']) &&
                                  owner(n) == action)
                                Positioned(
                                  left:
                                      ((n['x'] as num) - action.rect.left) *
                                      scale,
                                  top:
                                      yFor(n['y'] as num) -
                                      yFor(action.rect.top),
                                  width: (n['w'] as num) * scale,
                                  height: heightFor(n),
                                  child:
                                      replacements[n['id']] ??
                                      _layer(
                                        context,
                                        n,
                                        assets,
                                        scale,
                                        compact: verticalScale < scale - .01,
                                      ),
                                ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  static bool _isHeading(Map<String, dynamic> node) =>
      (node['name'] as String? ?? '').contains('title');

  String _value(Map<String, dynamic> n) =>
      text[n['id']] ?? (n['name'] == 'balance' ? '—' : n['t'] as String);

  static TextAlign _alignment(Map<String, dynamic> n) => switch (n['align']) {
    'CENTER' => TextAlign.center,
    'RIGHT' => TextAlign.right,
    _ => TextAlign.left,
  };

  TextStyle _textStyle(
    BuildContext context,
    Map<String, dynamic> n, {
    double widthScale = 1,
  }) {
    final fonts = SoriLocaleFonts.of(context);
    final size = math.max(
      _isHeading(n) ? 24.0 : 16.0,
      (n['fs'] as num).toDouble() * widthScale.clamp(.8, 1.0),
    );
    final fills = ((n['f'] as List?) ?? []).cast<Map<String, dynamic>>();
    final solid = fills.where((p) => p['type'] == 'SOLID').firstOrNull;
    final lh = n['lh'] as Map;
    final ls = n['ls'] as Map;
    final letter = (ls['value'] as num).toDouble();
    return TextStyle(
      fontFamily: _isHeading(n) ? fonts.heading : fonts.body,
      fontFamilyFallback: SoriLocaleFonts.fallback,
      fontSize: size,
      fontWeight: _isHeading(n)
          ? fonts.headingWeight
          : fonts.bodyWeight(
              (n['fn'] as Map)['style'] == 'Bold'
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
      color: solid == null ? CPalette.ink : _color(solid),
      height: lh['unit'] == 'PIXELS'
          ? math.max(1.2, (lh['value'] as num) / size)
          : 1.2,
      letterSpacing: ls['unit'] == 'PERCENT' ? letter * size / 100 : letter,
    );
  }

  Widget _layer(
    BuildContext context,
    Map<String, dynamic> n,
    Map<String, dynamic> assets,
    double scale, {
    bool compact = false,
  }) {
    final fills = ((n['f'] as List?) ?? []).cast<Map<String, dynamic>>();
    final solid = fills.where((p) => p['type'] == 'SOLID').firstOrNull;
    final image = fills.where((p) => p['type'] == 'IMAGE').firstOrNull;
    final opacity = (n['o'] as num).toDouble();
    if (n['type'] == 'TEXT') {
      return Opacity(
        opacity: opacity,
        child: Text(
          _value(n),
          textAlign: _alignment(n),
          style: _textStyle(context, n, widthScale: scale),
        ),
      );
    }
    final radius = (n['cr'] as num?)?.toDouble() ?? 0;
    final strokes = (n['st'] as List?) ?? [];
    final fx = (n['fx'] as List?) ?? [];
    Widget? art;
    if (image != null) {
      final path = assets[image['imageHash']] as String;
      final transform = image['imageTransform'] as List?;
      if (image['scaleMode'] == 'CROP' &&
          transform != null &&
          !path.startsWith('assets/icons/')) {
        art = CAtlasArt(
          path: path,
          fit:
              compact &&
                  !(n['name'] as String).contains('board') &&
                  !(n['name'] as String).contains('hanji')
              ? BoxFit.contain
              : BoxFit.fill,
          region: Rect.fromLTWH(
            (transform[0][2] as num).toDouble(),
            (transform[1][2] as num).toDouble(),
            (transform[0][0] as num).toDouble(),
            (transform[1][1] as num).toDouble(),
          ),
        );
      } else {
        art = Image.asset(
          path,
          fit: image['scaleMode'] == 'FIT' ? BoxFit.contain : BoxFit.cover,
        );
      }
    }
    return Opacity(
      opacity: opacity,
      child: Container(
        decoration: BoxDecoration(
          color: solid == null ? null : _color(solid),
          shape: n['type'] == 'ELLIPSE' ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: n['type'] == 'ELLIPSE'
              ? null
              : BorderRadius.circular(radius * scale),
          border: strokes.isEmpty
              ? null
              : Border.all(
                  color: _color(strokes.first as Map),
                  width: ((n['sw'] as num?)?.toDouble() ?? 1) * scale,
                ),
          boxShadow: [
            for (final e in fx)
              if (e['type'] == 'DROP_SHADOW')
                BoxShadow(
                  color: _rgb(e['color'] as Map),
                  offset: Offset(
                    (e['offset']['x'] as num) * scale,
                    (e['offset']['y'] as num) * scale,
                  ),
                  blurRadius: (e['radius'] as num) * scale,
                  spreadRadius: (e['spread'] as num) * scale,
                ),
          ],
        ),
        child: art == null
            ? null
            : ClipRRect(
                borderRadius: BorderRadius.circular(radius * scale),
                child: art,
              ),
      ),
    );
  }

  static Color _color(Map p) => _rgb(
    p['color'] as Map,
  ).withValues(alpha: (p['opacity'] as num?)?.toDouble() ?? 1);
  static Color _rgb(Map c) => Color.from(
    alpha: (c['a'] as num?)?.toDouble() ?? 1,
    red: (c['r'] as num).toDouble(),
    green: (c['g'] as num).toDouble(),
    blue: (c['b'] as num).toDouble(),
  );
}

class FigmaSceneAction {
  const FigmaSceneAction(this.rect, this.label, this.onTap, {this.key});
  final Rect rect;
  final String label;
  final VoidCallback? onTap;
  final Key? key;
}

/// The approved layer's image region, without any baked UI text or geometry.
class ApprovedFigmaArt extends StatelessWidget {
  const ApprovedFigmaArt({
    super.key,
    required this.scene,
    required this.nodeId,
  });
  final String scene, nodeId;

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: Future.wait([
          ApprovedFigmaScene.load(scene),
          ApprovedFigmaScene.load('figma-assets.json'),
        ]),
        initialData:
            ApprovedFigmaScene._loaded.containsKey(scene) &&
                ApprovedFigmaScene._loaded.containsKey('figma-assets.json')
            ? [
                ApprovedFigmaScene._loaded[scene]!,
                ApprovedFigmaScene._loaded['figma-assets.json']!,
              ]
            : null,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.expand();
          }
          final node = (snapshot.data![0]['nodes'] as List)
              .cast<Map<String, dynamic>>()
              .firstWhere((node) => node['id'] == nodeId);
          final fill = (node['f'] as List)
              .cast<Map<String, dynamic>>()
              .firstWhere((fill) => fill['type'] == 'IMAGE');
          final path = snapshot.data![1][fill['imageHash']] as String;
          final transform = fill['imageTransform'] as List?;
          if (fill['scaleMode'] == 'CROP' && transform != null) {
            return CAtlasArt(
              path: path,
              fit: BoxFit.contain,
              region: Rect.fromLTWH(
                (transform[0][2] as num).toDouble(),
                (transform[1][2] as num).toDouble(),
                (transform[0][0] as num).toDouble(),
                (transform[1][1] as num).toDouble(),
              ),
            );
          }
          return Image.asset(
            path,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          );
        },
      );
}

/// Compatibility bridge: the current native five-tab navigator owns state.
class ApprovedFigmaNavigation extends StatelessWidget {
  const ApprovedFigmaNavigation({
    super.key,
    required this.selectedIndex,
    required this.assets,
    required this.labels,
    required this.onSelected,
  });
  final int selectedIndex;
  final List<String> assets, labels;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => SoriImageNavigationBar(
    selectedIndex: selectedIndex,
    onDestinationSelected: onSelected,
    labels: labels,
    assets: const [
      ApprovedChromeAssets.today,
      ApprovedChromeAssets.learn,
      ApprovedChromeAssets.games,
      ApprovedChromeAssets.hanok,
      ApprovedChromeAssets.gye,
    ],
  );
}
