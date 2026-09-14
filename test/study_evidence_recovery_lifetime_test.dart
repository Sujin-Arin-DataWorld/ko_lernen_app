import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/sori/study_evidence_recovery.dart';

void main() {
  for (final rebuild in [false, true]) {
    testWidgets(
      'completed reset retires rendered retry on first action rebuild=$rebuild',
      (tester) async {
        Storage.resetForTesting();
        SharedPreferences.setMockInitialValues({});
        await Storage.init();
        final key = GlobalKey<_EvidenceState>();
        var saves = 0;
        final nav = await _show(tester, key, () async {
          saves++;
          throw StateError('Temporary save failure');
        });
        final original = tester.widget<AppError>(find.byType(AppError));
        final t = AppL10n.of(tester.element(find.byType(AppError)));
        expect(original.retryLabel, t.btnRetry);
        await Storage.resetAllStrict();
        if (rebuild) {
          key.currentState!.rebuild();
          await tester.pump();
          expect(
            tester.widget<AppError>(find.byType(AppError)).retryLabel,
            t.btnClose,
          );
        }
        // Even a callback captured before reset uses current lifetime authority.
        original.onRetry!();
        await tester.pumpAndSettle();
        expect(find.text('root'), findsOneWidget);
        expect(nav.currentState!.canPop(), isFalse);
        expect(saves, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('live evidence error still retries the retained save', (
    tester,
  ) async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    var saves = 0;
    await _show(tester, GlobalKey<_EvidenceState>(), () async {
      if (++saves == 1) {
        throw StateError('Temporary save failure');
      }
      return true;
    });
    tester.widget<AppError>(find.byType(AppError)).onRetry!();
    await tester.pumpAndSettle();
    expect(saves, 2);
    expect(find.byType(AppError), findsNothing);
    expect(find.byType(_EvidenceScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<GlobalKey<NavigatorState>> _show(
  WidgetTester tester,
  GlobalKey<_EvidenceState> key,
  Future<bool> Function() save,
) async {
  final nav = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: nav,
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: const Scaffold(body: Text('root')),
    ),
  );
  unawaited(
    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => _EvidenceScreen(key: key, save: save),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('save'));
  for (
    var index = 0;
    index < 30 && find.byType(AppError).evaluate().isEmpty;
    index++
  ) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(find.byType(AppError), findsOneWidget);
  return nav;
}

class _EvidenceScreen extends StatefulWidget {
  const _EvidenceScreen({super.key, required this.save});
  final Future<bool> Function() save;
  @override
  State<_EvidenceScreen> createState() => _EvidenceState();
}

class _EvidenceState extends State<_EvidenceScreen>
    with StudyEvidenceRecovery<_EvidenceScreen> {
  void rebuild() => setState(() {});
  @override
  Widget build(BuildContext context) => Scaffold(
    body:
        studyEvidenceRecoveryContent() ??
        TextButton(
          onPressed: () => unawaited(saveStudyEvidence(widget.save)),
          child: const Text('save'),
        ),
  );
}
