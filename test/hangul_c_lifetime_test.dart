import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/guide_contract.dart';
import 'package:ko_lernen_app/screens/hangul_screen.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_atelier_materials.dart';
import 'package:ko_lernen_app/widgets/sori/home_action.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'support/sori_speech_stubs.dart';
import 'support/real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_tut_hangul': true});
    await Storage.init();
    stubSoriSpeech();
  });

  test(
    'confirmed local choices persist, queued hard letters do not lose updates',
    () async {
      expect(Storage.hangulAutoAdvance, isTrue);
      await Storage.setHangulAutoAdvance(false);
      await Storage.setHangulStrictStrokes(false);
      await Future.wait([
        Storage.markHangulHard('ㄱ'),
        Storage.markHangulHard('ㅏ'),
      ]);
      expect(Storage.hangulHard, ['ㄱ', 'ㅏ']);
      Storage.resetForTesting();
      await Storage.init();
      expect(Storage.hangulAutoAdvance, isFalse);
      expect(Storage.hangulStrictStrokes, isFalse);
      expect(Storage.hangulHard, ['ㄱ', 'ㅏ']);
    },
  );

  test(
    'a retired source cannot change local writing preference or hard cards',
    () async {
      final lifetime = LocalDataLifetime.capture();
      LocalDataLifetime.invalidate();
      await expectLater(
        Storage.setHangulAutoAdvance(
          false,
          assertCurrentWrite: lifetime.assertCurrent,
        ),
        throwsA(isA<StaleLocalDataLifetimeException>()),
      );
      await expectLater(
        Storage.markHangulHard('ㄱ', assertCurrentWrite: lifetime.assertCurrent),
        throwsA(isA<StaleLocalDataLifetimeException>()),
      );
      expect(Storage.hangulAutoAdvance, isTrue);
      expect(Storage.hangulHard, isEmpty);
    },
  );

  testWidgets('retained card judgment is retired immediately on data reset', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byType(FlipCard));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    final action = tester
        .widget<CAtelierButton>(
          find.widgetWithText(CAtelierButton, 'Nicht gewusst'),
        )
        .onTap!;
    LocalDataLifetime.invalidate();
    await tester.pumpAndSettle();
    action();
    await tester.pumpAndSettle();
    expect(Storage.hangulHard, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'recovery input lock leaves the frame exits and blocks card grading',
    (tester) async {
      await _pump(tester, locked: true);
      expect(
        tester
            .widget<CAtelierButton>(
              find.widgetWithText(CAtelierButton, 'Nicht gewusst'),
            )
            .onTap,
        isNull,
      );
      expect(find.byType(SoriCloseAction), findsOneWidget);
      expect(find.byType(SoriHomeAction), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pump(WidgetTester tester, {bool locked = false}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: StudyBodyInputLock(
        locked: locked,
        child: const HangulScreen(initialTarget: HangulTarget.cards),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
