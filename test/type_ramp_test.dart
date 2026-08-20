import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

void main() {
  test('램프에 w800/w900 이 없고 하한이 12 미만으로 내려가지 않는다', () {
    for (final r in SoriTypeRamp.all) {
      expect(r.weight.index, lessThanOrEqualTo(FontWeight.w700.index), reason: r.name);
      expect(r.size, greaterThanOrEqualTo(12), reason: r.name);
      expect(r.height, greaterThanOrEqualTo(1.1), reason: r.name);
    }
  });
  test('한국어 역할은 height ≥ 1.25, 본문은 1.5', () {
    expect(SoriTypeRamp.koDisplay.height, greaterThanOrEqualTo(1.25));
    expect(SoriTypeRamp.koDisplaySm.height, greaterThanOrEqualTo(1.25));
    expect(SoriTypeRamp.body.height, 1.5);
    expect(SoriTypeRamp.meta.size, 12.5);
    expect(SoriTypeRamp.meta.weight, isNot(SoriTypeRamp.caption.weight));
  });
  test('Material TextTheme 은 램프에서 파생된다', () {
    final tt = AppTheme.light.textTheme;
    expect(tt.displayLarge!.fontSize, SoriTypeRamp.hero.size);
    expect(tt.displayLarge!.fontWeight, FontWeight.w700);
    expect(tt.bodyLarge!.fontSize, SoriTypeRamp.body.size);
    expect(tt.bodyLarge!.height, SoriTypeRamp.body.height);
    expect(tt.labelSmall!.fontSize, greaterThanOrEqualTo(12.5));
    for (final s in [tt.displayLarge, tt.headlineMedium, tt.bodyMedium, tt.labelSmall]) {
      expect(s!.fontFamily, SoriFonts.sans);
    }
  });
  testWidgets('SoriTextTheme 이 램프 값을 그대로 낸다', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: Builder(builder: (c) {
      final t = SoriTextTheme.of(c);
      expect(t.koHero.fontSize, 56);
      expect(t.koDisplaySm.fontSize, 24);
      expect(t.glossSm.fontSize, 15);
      expect(t.h1.fontWeight, FontWeight.w700);
      expect(t.label.fontWeight, FontWeight.w600);
      expect(t.cardSubtitle.fontSize, 12.5);
      return const SizedBox();
    })));
  });
}
