import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/real_fonts.dart';
import 'support/text_paint_evidence.dart';

const _ink = Color(0xff1a1f1d);

class _Paper extends CustomPainter {
  const _Paper();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xfff8f3e7),
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height),
      Paint()..color = const Color(0xfff4efdf),
    );
  }

  @override
  bool shouldRepaint(_Paper oldDelegate) => false;
}

class _ReportedFailure extends AccessibilityGuideline {
  const _ReportedFailure({this.unmapped = false, this.required = 4.5});
  final bool unmapped;
  final double required;

  @override
  String get description => 'Synthetic framework failure for fail-closed tests';

  @override
  Evaluation evaluate(WidgetTester tester) {
    if (unmapped) {
      return const Evaluation.fail('Unexpected framework diagnostic');
    }
    final node = tester.getSemantics(find.byKey(const ValueKey('subject')));
    return Evaluation.fail(
      '$node:\nExpected contrast ratio of at least $required',
    );
  }
}

Future<void> _pump(WidgetTester tester, Widget text) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 360,
            height: 64,
            child: CustomPaint(painter: const _Paper(), child: text),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Text _text({Color color = _ink, double size = 15}) => Text(
  'Profil',
  key: const ValueKey('subject'),
  style: TextStyle(
    color: color,
    fontFamily: 'EncodeSansCondensed',
    fontSize: size,
    fontWeight: FontWeight.w500,
  ),
);

void main() {
  setUpAll(loadSoriRealFonts);
  SemanticsHandle? handle;
  setUp(() => handle = TestWidgetsFlutterBinding.instance.ensureSemantics());
  tearDown(() {
    handle?.dispose();
    handle = null;
  });

  testWidgets('sparse real ink on textured paper passes with paint proof', (
    tester,
  ) async {
    await _pump(tester, _text());
    final native = await textContrastGuideline.evaluate(tester);
    expect(
      native.passed,
      isFalse,
      reason: 'Exercise the paper histogram error',
    );
    expect(native.reason, contains('Expected contrast ratio'));
    final before = tester.binding.clock.now();
    final result = await const PaintedTextContrastGuideline().evaluate(tester);
    expect(result.passed, isTrue, reason: result.reason);
    expect(tester.binding.clock.now(), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('actual low-contrast text still fails at 4.5', (tester) async {
    await _pump(tester, _text(color: const Color(0xffaaaaaa)));
    final result = await const PaintedTextContrastGuideline().evaluate(tester);
    expect(result.passed, isFalse);
    expect(
      result.reason,
      contains('Insufficient actual glyph/background contrast'),
    );
  });

  testWidgets('large text keeps the SDK 3.0 threshold', (tester) async {
    await _pump(tester, _text(color: const Color(0xff808080), size: 18));
    final result = await const PaintedTextContrastGuideline(
      framework: _ReportedFailure(required: 3.0),
      evidenceName: 'large-native-3',
    ).evaluate(tester);
    expect(result.passed, isTrue, reason: result.reason);
  });

  testWidgets('native 4.5 remains required for a large text style', (
    tester,
  ) async {
    await _pump(tester, _text(color: const Color(0xff808080), size: 18));
    final result = await const PaintedTextContrastGuideline(
      framework: _ReportedFailure(required: 4.5),
      evidenceName: 'large-native-4_5',
    ).evaluate(tester);
    expect(result.passed, isFalse);
    expect(
      result.reason,
      contains('Insufficient actual glyph/background contrast'),
    );
    expect(result.reason, contains('nativeRequiredContrast: 4.5'));
    expect(result.reason, contains('styleRequiredContrast: 3.0'));
    expect(result.reason, contains('requiredContrast: 4.5'));
  });

  testWidgets('unpainted semantic text cannot pass', (tester) async {
    await _pump(
      tester,
      Opacity(opacity: 0, alwaysIncludeSemantics: true, child: _text()),
    );
    final result = await const PaintedTextContrastGuideline(
      framework: _ReportedFailure(),
    ).evaluate(tester);
    expect(result.passed, isFalse);
    expect(result.reason, contains('No actual opaque ink core pixels'));
  });

  testWidgets('translucent ink is unsupported and retains the failure', (
    tester,
  ) async {
    await _pump(tester, _text(color: _ink.withValues(alpha: .5)));
    final result = await const PaintedTextContrastGuideline(
      framework: _ReportedFailure(),
    ).evaluate(tester);
    expect(result.passed, isFalse);
    expect(result.reason, contains('Unsupported, mixed or translucent'));
  });

  testWidgets('mixed paragraph styles retain the native failure', (
    tester,
  ) async {
    await _pump(
      tester,
      const Text.rich(
        key: ValueKey('subject'),
        TextSpan(
          style: TextStyle(fontFamily: 'EncodeSansCondensed', fontSize: 15),
          children: [
            TextSpan(
              text: 'Pro',
              style: TextStyle(color: _ink),
            ),
            TextSpan(
              text: 'fil',
              style: TextStyle(color: Color(0xff5c6660)),
            ),
          ],
        ),
      ),
    );
    final result = await const PaintedTextContrastGuideline(
      framework: _ReportedFailure(),
    ).evaluate(tester);
    expect(result.passed, isFalse);
    expect(result.reason, contains('Unsupported, mixed or translucent'));
  });

  testWidgets('unknown framework diagnostics cannot be swallowed', (
    tester,
  ) async {
    await _pump(tester, _text());
    final result = await const PaintedTextContrastGuideline(
      framework: _ReportedFailure(unmapped: true),
    ).evaluate(tester);
    expect(result.passed, isFalse);
    expect(result.reason, contains('Unexpected framework diagnostic'));
    expect(result.reason, contains('Unmapped framework failure'));
  });
}
