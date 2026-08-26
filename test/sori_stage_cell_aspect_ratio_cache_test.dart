import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_catalog_screen.dart'
    show cellAspectRatioCacheKey;

void main() {
  test('같은 입력은 같은 캐시 키를 만든다', () {
    final a = cellAspectRatioCacheKey(
      cellWidth: 160.0,
      textScale: 1.0,
      locale: 'en',
      titles: const ['Course', 'Hangul'],
      footerLabels: const ['Ready'],
    );
    final b = cellAspectRatioCacheKey(
      cellWidth: 160.0,
      textScale: 1.0,
      locale: 'en',
      titles: const ['Course', 'Hangul'],
      footerLabels: const ['Ready'],
    );
    expect(a, b);
  });

  test('cellWidth 가 다르면 캐시 키도 다르다', () {
    final a = cellAspectRatioCacheKey(
      cellWidth: 160.0,
      textScale: 1.0,
      locale: 'en',
      titles: const ['Course'],
      footerLabels: const [],
    );
    final b = cellAspectRatioCacheKey(
      cellWidth: 180.0,
      textScale: 1.0,
      locale: 'en',
      titles: const ['Course'],
      footerLabels: const [],
    );
    expect(a, isNot(b));
  });

  test('titles 순서가 다르면 캐시 키도 다르다', () {
    final a = cellAspectRatioCacheKey(
      cellWidth: 160.0,
      textScale: 1.0,
      locale: 'en',
      titles: const ['Course', 'Hangul'],
      footerLabels: const [],
    );
    final b = cellAspectRatioCacheKey(
      cellWidth: 160.0,
      textScale: 1.0,
      locale: 'en',
      titles: const ['Hangul', 'Course'],
      footerLabels: const [],
    );
    expect(a, isNot(b));
  });
}
