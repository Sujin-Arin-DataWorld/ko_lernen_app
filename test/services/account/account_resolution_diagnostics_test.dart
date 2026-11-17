import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/account_failure_diagnostics.dart';

void main() {
  tearDown(AccountFailureDiagnostics.resetSinkForTesting);
  test(
    'fixed field buckets and normalized aggregate course summaries are emitted',
    () {
      final lines = <String>[];
      AccountFailureDiagnostics.sink = (line, record) {
        lines.add(line);
      };
      AccountFailureDiagnostics.logSwitchResolution(
        fields: {
          AccountResolutionFieldBucket.studyLog,
          AccountResolutionFieldBucket.grammarPlan,
        },
        devicePlacement: ' A1 ',
        cloudPlacement: 'a2',
        deviceCompletedCount: 2,
        cloudCompletedCount: 4,
      );
      expect(lines, hasLength(1));
      expect(lines.single, contains('studyLog'));
      expect(lines.single, contains('grammarPlan'));
      expect(lines.single, contains('devicePlacement=a1'));
      expect(lines.single, contains('cloudPlacement=a2'));
      expect(lines.single, contains('deviceCompleted=2'));
      expect(lines.single, contains('cloudCompleted=4'));
    },
  );

  test(
    'malformed level text and secret canaries never enter line or record',
    () {
      final output = <String>[];
      AccountFailureDiagnostics.sink = (line, record) {
        output.add(line);
        output.add(record.toString());
      };
      AccountFailureDiagnostics.logSwitchResolution(
        fields: {AccountResolutionFieldBucket.unknown},
        devicePlacement: 'uid-email-token-canary@example.invalid\nraw-text',
        cloudPlacement: 'C:/private/source.json',
        deviceCompletedCount: -1,
        cloudCompletedCount: 999999999,
      );
      expect(output, hasLength(2));
      expect(output.join(), isNot(contains('canary')));
      expect(output.join(), isNot(contains('raw-text')));
      expect(output.join(), isNot(contains('private')));
      expect(output.join(), isNot(contains('999999999')));
      expect(output.first, contains('devicePlacement=unknown'));
      expect(output.first, contains('cloudPlacement=unknown'));
    },
  );

  test('diagnostic sink failure cannot escape into account mutation flow', () {
    AccountFailureDiagnostics.sink = (_, _) {
      throw StateError('sink failure');
    };
    expect(
      () => AccountFailureDiagnostics.logSwitchResolution(
        fields: {},
        devicePlacement: 'a1',
        cloudPlacement: 'a2',
        deviceCompletedCount: 0,
        cloudCompletedCount: 0,
      ),
      returnsNormally,
    );
  });
}
