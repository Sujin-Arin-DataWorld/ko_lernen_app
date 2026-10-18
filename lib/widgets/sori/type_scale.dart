import 'package:flutter/widgets.dart';
import 'tokens.dart';

/// 앱의 **유일한** 글자 배율 권한. `MaterialApp.builder` 에 한 번 설치한다.
///
/// OS 접근성 배율 × [soriComfortScale](폭 600→720dp 에서 1.0→1.10). 예전에는
/// `SoriTextTheme._base` 가 fontSize·letterSpacing 에 comfort 를 직접 곱하고,
/// `SoriStudyScale` 이 학습 카드에 ×1.35 를 또 곱해 태블릿에서 세 배율이
/// 곱해졌다(15 × 1.10 × 1.35 × 2.0 = 44.5px). 이제 여기서 한 번만 곱하고,
/// Material TextTheme 텍스트도 같이 스케일되며 letterSpacing 은 배율을 안 탄다.
class SoriTypeScale extends StatelessWidget {
  const SoriTypeScale({super.key, required this.child});
  final Widget child;

  /// Replaces only our window-width comfort factor for a constrained pane.
  /// The original OS/custom scaler is retained, including nonlinear scaling.
  static TextScaler forViewport(TextScaler ambient, double viewportWidth) {
    var base = ambient;
    while (base is SoriComfortTextScaler) {
      base = base._base;
    }
    final comfort = soriComfortScale(viewportWidth);
    return comfort <= 1 ? base : SoriComfortTextScaler(base, comfort);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final comfort = soriComfortScale(mq.size.width);
    if (comfort <= 1.0) {
      return child;
    }
    return MediaQuery(
      data: mq.copyWith(
        textScaler: SoriComfortTextScaler(mq.textScaler, comfort),
      ),
      child: child,
    );
  }
}

/// Use inside a width-constrained surface, including a modal route whose
/// inherited MediaQuery still describes the full app window.
/// Ordinary screens keep the app-level [SoriTypeScale] unchanged.
class SoriViewportTypeScale extends StatelessWidget {
  const SoriViewportTypeScale({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final media = MediaQuery.of(context);
      final width = constraints.hasBoundedWidth
          ? constraints.maxWidth
          : media.size.width;
      return MediaQuery(
        data: media.copyWith(
          textScaler: SoriTypeScale.forViewport(media.textScaler, width),
        ),
        child: child,
      );
    },
  );
}

/// ambient [TextScaler] 에 상수 배율을 곱한다(OS 배율과 합성, 대체 아님).
class SoriComfortTextScaler extends TextScaler {
  const SoriComfortTextScaler(this._base, this._factor);
  final TextScaler _base;
  final double _factor;

  @override
  double scale(double fontSize) => _base.scale(fontSize) * _factor;

  @override
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) =>
      other is SoriComfortTextScaler &&
      other._base == _base &&
      other._factor == _factor;

  @override
  int get hashCode => Object.hash(_base, _factor);
}
