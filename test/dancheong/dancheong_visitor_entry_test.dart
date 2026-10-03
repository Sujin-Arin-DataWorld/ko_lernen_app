import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/features/onboarding_v2/first_run_coordinator.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_screens.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_visitor_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final completed in [false, true]) {
    testWidgets(
      'visitor entry ${completed ? "opens completed editor" : "keeps consent in front"} without learning credit',
      (tester) async {
        Storage.resetForTesting();
        SharedPreferences.setMockInitialValues({
          'kl_xp': 137,
          'kl_earned_stamps': <String>[],
        });
        await Storage.init();
        final preferences = await SharedPreferences.getInstance();
        final before = {
          for (final key in preferences.getKeys()) key: preferences.get(key),
        };
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            routes: {
              '/splash': (_) => const Scaffold(body: Text('consent-gate')),
            },
            home: DancheongVisitorGate(
              entry: DancheongVisitorEntry.parse(
                Uri.parse('/dancheong-entry?template=letter'),
              ),
              coordinator: _EntryCoordinator(completed),
            ),
          ),
        );
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          completed
              ? find.byType(DancheongEditorScreen)
              : find.text('consent-gate'),
          findsOneWidget,
        );
        expect({
          for (final key in preferences.getKeys())
            if (key != Storage.dancheongEntryPreferenceKey)
              key: preferences.get(key),
        }, before);
        expect(DancheongVisitorEntry.pending()!.template.name, 'letter');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  test(
    'entry carries only template and opaque reference, never owner text or reward inputs',
    () {
      final entry = DancheongVisitorEntry.parse(
        Uri.parse('/dancheong-entry?template=letter&shareId=${'A' * 32}'),
      )!;
      expect(entry.template.name, 'letter');
      expect(
        entry.toJson().keys,
        unorderedEquals(['version', 'template', 'shareId']),
      );
      for (final value in [
        '/dancheong-entry?template=unknown',
        '/dancheong-entry?template=flower&template=letter',
        '/dancheong-entry?template=flower&ownerUid=alice',
        '/dancheong-entry?template=flower&koreanText=private',
        'https://evil.example/dancheong-entry?template=flower',
        '/dancheong-entry?template=flower&shareId=../users/alice',
      ]) {
        expect(
          DancheongVisitorEntry.parse(Uri.parse(value)),
          isNull,
          reason: value,
        );
      }
    },
  );
}

class _EntryCoordinator implements FirstRunCoordinator {
  _EntryCoordinator(this.completed);
  final bool completed;
  @override
  Future<FirstRunResolution> resolveEntry() async => FirstRunResolution(
    entry: completed ? FirstRunEntry.appShell : FirstRunEntry.consent,
    state: null,
    migratedLegacyState: false,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
