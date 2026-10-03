import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_models.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_screens.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_store.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/theme.dart';
import '../support/real_fonts.dart';

const capture = bool.fromEnvironment('CAPTURE_DANCHEONG_UI');
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadSoriRealFonts);
  for (final language in ['de', 'en']) {
    testWidgets('capture native Dancheong editor $language', skip: !capture, (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var raw = '';
      final store = DancheongStore(
        readRaw: () => raw,
        writeRaw: (value, guard) async {
          guard();
          raw = value;
        },
        sessions: CloudWriteSessionController()..acquire('visual-fixture'),
        readOwned: () => {'lotus'},
      );
      await store.saveDraft(
        DancheongDraft(
          id: '00000000-0000-4000-8000-000000000010',
          composition: DancheongComposition(
            template: DancheongTemplate.flower,
            format: DancheongFormat.portrait,
            motifSlugs: ['lotus'],
            koreanText: '안녕',
            translation: language == 'de'
                ? 'Mein erstes koreanisches Wort'
                : 'My first Korean word',
            translationLocale: language,
          ),
          updatedAt: DateTime.utc(2026),
        ),
      );
      final boundary = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: Locale(language),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: RepaintBoundary(
            key: boundary,
            child: DancheongEditorScreen(
              store: store,
              owned: () => {'lotus'},
              arguments: const DancheongEditorArgs(
                draftId: '00000000-0000-4000-8000-000000000010',
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        for (
          var i = 0;
          i < 40 &&
              find
                  .byWidgetPredicate(
                    (w) => w is Image && w.image is MemoryImage,
                  )
                  .evaluate()
                  .isEmpty;
          i++
        ) {
          await tester.pump();
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      });
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(find.byType(Image), findsWidgets);
      final b =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await b.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        final directory = Directory(
          '.superpowers/sdd/2026-10-03-dancheong-app-connection/ui-evidence',
        )..createSync(recursive: true);
        await File(
          '${directory.path}/editor-$language-390.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
      });
      await tester.pumpWidget(const SizedBox());
    });
  }
}
