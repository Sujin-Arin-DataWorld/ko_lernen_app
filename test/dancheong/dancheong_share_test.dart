import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_share_service.dart';

void main() {
  test('share result describes handoff and cancellation honestly', () {
    expect(
      mapDancheongShareStatus(ShareResultStatus.success),
      DancheongShareOutcome.handedOff,
    );
    expect(
      mapDancheongShareStatus(ShareResultStatus.dismissed),
      DancheongShareOutcome.dismissed,
    );
    expect(
      mapDancheongShareStatus(ShareResultStatus.unavailable),
      DancheongShareOutcome.unavailable,
    );
  });
}
