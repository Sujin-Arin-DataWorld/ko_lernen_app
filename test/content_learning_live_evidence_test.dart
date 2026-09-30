import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_catalog.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_hub.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_models.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_service.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/smalltalk_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'support/real_fonts.dart';

const capture = bool.fromEnvironment('CAPTURE_CONTENT_LEARNING_EVIDENCE');
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadSoriRealFonts(materialIcons: true);
    await SmalltalkLoader.load();
    for (final kind in LearningContentKind.values) {
      await ContentLearningCatalog.load(kind);
    }
  });
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });
  for (final kind in LearningContentKind.values) {
    for (final lang in ['de', 'en']) {
      for (final size in [const Size(390, 844), const Size(1024, 1366)]) {
        testWidgets('real ${kind.name} catalog $lang ${size.width}', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });
          await ContentLearningService.setGoal(kind, 'a1', 2);
          final before = Storage.contentLearningRawJson;
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              locale: Locale(lang),
              localizationsDelegates: AppL10n.localizationsDelegates,
              supportedLocales: AppL10n.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
              home: RepaintBoundary(
                key: const ValueKey('real-content'),
                child: ContentLearningHub(kind: kind, initialLevel: 'a1'),
              ),
            ),
          );
          for (var i = 0; i < 15; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          expect(find.byType(CircularProgressIndicator), findsNothing);
          // Decode the real illustrations outside the fake test clock before
          // capture; a fixed number of pumps alone can leave blank image slots.
          final imageWidgets = tester
              .widgetList<Image>(find.byType(Image))
              .toList();
          final imageContext = tester.element(
            find.byKey(const ValueKey('real-content')),
          );
          await tester.runAsync(() async {
            for (final image in imageWidgets) {
              await precacheImage(image.image, imageContext);
            }
          });
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(
            Storage.contentLearningRawJson,
            before,
            reason: 'Rendering must not activate or advance a day',
          );
          if (capture) {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('real-content')),
            );
            await tester.runAsync(() async {
              final rendered = await boundary.toImage(pixelRatio: 1);
              final bytes = await rendered.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final file = File(
                'docs/screenshots/content-learning/content-real-${kind.name}-$lang-${size.width.toInt()}.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              rendered.dispose();
            });
          }
        });
      }
    }
  }
}
