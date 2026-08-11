import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/config/ux_preview_feature.dart';

void main() {
  test('UX preview is disabled by default', () {
    expect(const UxPreviewFeatureGate().isEnabled, isFalse);
  });

  test('UX preview exposes an explicit test seam', () {
    expect(const UxPreviewFeatureGate(enabled: true).isEnabled, isTrue);
    expect(const UxPreviewFeatureGate(enabled: false).isEnabled, isFalse);
  });
}
