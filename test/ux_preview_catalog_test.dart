import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/ux_preview_catalog.dart';

void main() {
  test('catalog contains every 01A-06C mockup exactly once', () {
    const expected = <String>{
      '01A',
      '01B',
      '01C',
      '01D',
      '02A',
      '02B',
      '02C',
      '02D',
      '03A',
      '03B',
      '03C',
      '04A',
      '04B',
      '04C',
      '05A',
      '05B',
      '05C',
      '06A',
      '06B',
      '06C',
    };

    expect(uxPreviewPanels, hasLength(20));
    expect(uxPreviewPanels.map((panel) => panel.id).toSet(), expected);
  });

  test('catalog keeps each section contiguous and non-empty', () {
    final seen = <UxPreviewSection>[];
    for (final panel in uxPreviewPanels) {
      if (seen.isEmpty || seen.last != panel.section) {
        expect(seen, isNot(contains(panel.section)));
        seen.add(panel.section);
      }
    }

    expect(seen, UxPreviewSection.values);
  });
}
