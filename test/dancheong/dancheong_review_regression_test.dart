import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_controller.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_models.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_screens.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_store.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/real_fonts.dart';

const _id = '00000000-0000-4000-8000-000000000001';
DancheongComposition _composition(String text) => DancheongComposition(
  template: DancheongTemplate.flower,
  format: DancheongFormat.portrait,
  motifSlugs: ['lotus'],
  koreanText: text,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadSoriRealFonts);
  late String raw;
  late DancheongStore store;
  setUp(() {
    raw = '';
    store = DancheongStore(
      readRaw: () => raw,
      writeRaw: (value, guard) async {
        guard();
        raw = value;
      },
      sessions: CloudWriteSessionController()..acquire('review-owner'),
      readOwned: () => {'lotus'},
    );
  });
  test(
    'opening and leaving an untouched new editor does not accumulate drafts',
    () async {
      final c = DancheongController(store: store, owned: () => {'lotus'});
      await c.flush();
      expect(store.currentOwner().drafts, isEmpty);
      c.dispose();
    },
  );
  test(
    'full draft capacity rejects new editor admission but keeps resume available',
    () async {
      for (var i = 0; i < 30; i++) {
        await store.saveDraft(
          DancheongDraft(
            id: '00000000-0000-4000-8000-${i.toString().padLeft(12, '0')}',
            composition: _composition('안녕'),
            updatedAt: DateTime.utc(2026),
          ),
        );
      }
      expect(
        () => DancheongController(store: store, owned: () => {'lotus'}),
        throwsA(isA<DancheongStoreFailure>()),
      );
      final resumed = DancheongController(
        store: store,
        owned: () => {'lotus'},
        draftId: _id,
      );
      expect(resumed.composition.koreanText, '안녕');
      resumed.dispose();
    },
  );
  test(
    'many short Hangul lines remain a draft and cannot become unrenderable finished art',
    () async {
      final c = DancheongController(
        store: store,
        owned: () => {'lotus'},
        motifSlug: 'lotus',
      );
      final text = List.filled(20, '가').join('\n');
      c.update(c.composition.copyWith(koreanText: text));
      await expectLater(c.finish(), throwsA(isA<Exception>()));
      expect(store.currentOwner().artworks, isEmpty);
      expect(store.currentOwner().drafts.single.composition.koreanText, text);
      expect(c.error, isNotNull);
      c.dispose();
    },
  );
  testWidgets(
    'an unsavable edited draft can explicitly leave without destroying saved data',
    (tester) async {
      final failing = DancheongStore(
        readRaw: () => '',
        writeRaw: (raw, guard) async => throw StateError('Disk full'),
        sessions: CloudWriteSessionController()..acquire('review-owner'),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DancheongEditorScreen(
                    arguments: const DancheongEditorArgs(),
                    store: failing,
                    owned: () => {},
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('dancheong-korean-text')),
        300,
      );
      await tester.enterText(
        find.byKey(const ValueKey('dancheong-korean-text')),
        '안녕',
      );
      await tester.pump(const Duration(milliseconds: 450));
      final context = tester.element(find.byType(DancheongEditorScreen));
      Navigator.of(context).maybePop();
      await tester.pumpAndSettle();
      expect(find.text('Leave without saving'), findsOneWidget);
      await tester.tap(find.text('Leave without saving'));
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('full studio offers deletion and then admits new artwork', (
    tester,
  ) async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_stamps_earned': <String>['lotus'],
      'kl_tut_dojang': true,
    });
    await Storage.init();
    for (var i = 0; i < 30; i++) {
      await store.saveDraft(
        DancheongDraft(
          id: '00000000-0000-4000-8000-${i.toString().padLeft(12, '0')}',
          composition: _composition('안녕'),
          updatedAt: DateTime.utc(2026),
        ),
      );
    }
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: DancheongStudioScreen(store: store),
      ),
    );
    await tester.pump();
    expect(
      tester
          .widget<SoriButton>(find.byKey(const ValueKey('dancheong-create')))
          .onTap,
      isNull,
    );
    await tester.tap(find.text('Artwork').first);
    await tester.pump();
    final delete = find.byKey(
      const ValueKey('delete-draft-00000000-0000-4000-8000-000000000029'),
    );
    await tester.scrollUntilVisible(delete, 200);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, 'Delete'),
      ),
    );
    await tester.pumpAndSettle();
    expect(store.currentOwner().drafts, hasLength(29));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
