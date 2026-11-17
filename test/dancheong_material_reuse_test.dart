import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_screens.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_store.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/c_learning_surface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/einleitung_capture_assets.dart';
import 'support/real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  setUp(() async {
    Storage.resetForTesting();
    // Explicit saved-ownership fixture; opening the view never earns a motif.
    SharedPreferences.setMockInitialValues({'kl_stamps_earned': ['lotus']});
    await Storage.init();
  });
  for (final language in ['de', 'en']) {
    for (final configuration in [
      (size: const Size(320, 640), scale: 1.0),
      (size: const Size(392.7, 872.7), scale: 1.0),
      (size: const Size(320, 640), scale: 2.0),
    ]) {
      testWidgets(
        'Dancheong material $language ${configuration.size} ${configuration.scale} keeps real create route and no view write',
        (tester) async {
          tester.view.physicalSize = configuration.size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var raw = '', writes = 0;
          RouteSettings? opened;
          final store = DancheongStore(
            readRaw: () => raw,
            writeRaw: (value, guard) async {
              guard();
              writes++;
              raw = value;
            },
            sessions: CloudWriteSessionController()
              ..acquire('material-fixture'),
          );
          const capture = Key('dancheong-material-capture');
          await tester.pumpWidget(
            RepaintBoundary(
              key: capture,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                locale: Locale(language),
                supportedLocales: AppL10n.supportedLocales,
                localizationsDelegates: AppL10n.localizationsDelegates,
                builder: (context, body) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(configuration.scale),
                    disableAnimations: true,
                  ),
                  child: body!,
                ),
                onGenerateRoute: (settings) {
                  opened = settings;
                  return MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(body: SizedBox()),
                    settings: settings,
                  );
                },
                home: DancheongStudioScreen(store: store),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await settleEinleitungCaptureAssets(tester);
          expect(tester.takeException(), isNull);
          expect(find.byType(SoriCMaterialSurface), findsWidgets);
          final create = find.byKey(const ValueKey('dancheong-create'));
          await tester.ensureVisible(create);
          await tester.pumpAndSettle();
          expect(tester.widget<SoriButton>(create).onTap, isNotNull);
          expect(writes, 0);
          if (const bool.fromEnvironment('CAPTURE_C_HANGUL_EVIDENCE') &&
              configuration.scale == 1) {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(capture),
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              image.dispose();
              final folder = Directory(
                'C:/dev/hangulsori/_codex_artifacts/native-design-review-20261030/atelier-migration/captures',
              )..createSync(recursive: true);
              File(
                '${folder.path}/dancheong-$language-${configuration.size.width == 320 ? '320' : '393'}-100.png',
              ).writeAsBytesSync(bytes!.buffer.asUint8List());
            });
          }
          await tester.tap(create);
          await tester.pumpAndSettle();
          expect(opened?.name, '/dancheong-studio/edit');
          expect(opened?.arguments, isA<DancheongEditorArgs>());
          expect(writes, 0);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
