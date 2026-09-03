import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/app_shell.dart';
import 'package:ko_lernen_app/screens/character_selection_screen.dart';
import 'package:ko_lernen_app/screens/first_voice_success_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';
import 'package:ko_lernen_app/widgets/sori/tiger_video.dart';

void main() {
  setUp(() async {
    TigerStageVideo.videoReady = false;
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    MascotPreference.load();
  });

  testWidgets('01C shows the persisted ability and can continue solo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const FirstVoiceSuccessScreen(
          canDo: 'Ich kann jemanden begrüßen.',
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text('Du hast dein erstes Koreanisch verstanden.'),
      findsOneWidget,
    );
    expect(find.text('Ich kann jemanden begrüßen.'), findsOneWidget);
    expect(find.text('Direkt zu Heute'), findsOneWidget);

    await tester.tap(find.text('Direkt zu Heute'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(Storage.introPreviewSeen, isTrue);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('kl_preferred_mascot'), 'none');
    expect(MascotPreference.selectedKind, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('eligible 01C opens 01D, saves Joy, and reaches Today', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const FirstVoiceSuccessScreen(
          canDo: 'Ich kann jemanden begr\u00fc\u00dfen.',
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Lernfreund w\u00e4hlen'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(CharacterSelectionScreen), findsOneWidget);
    expect(find.textContaining('Taego', findRichText: true), findsWidgets);
    expect(find.textContaining('Joy', findRichText: true), findsWidgets);
    expect(find.text('Jetzt nicht'), findsOneWidget);

    // §W-A2 재조사(실측): 토큰 확대로 캐릭터 카드가 커져 400×900 뷰포트
    // 아래쪽(y≈805.5)에서 탭이 조용히 빗나갔다(hit test 경고로 확인) —
    // ensureVisible 로 자리를 잡은 뒤 탭한다.
    final magpieOption = find.byKey(const ValueKey('companion-option-magpie'));
    await tester.ensureVisible(magpieOption);
    await tester.pump();
    await tester.tap(magpieOption);
    await tester.pump(const Duration(milliseconds: 100));
    var preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('kl_preferred_mascot'), isFalse);

    final continueButton = find.byKey(
      const ValueKey('companion-selection-continue'),
    );
    final continueAction = tester.widget<SoriButton>(continueButton).onTap;
    expect(continueAction, isNotNull);
    continueAction!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(Storage.introPreviewSeen, isTrue);
    preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('kl_preferred_mascot'), 'magpie');
    expect(find.byType(CharacterSelectionScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('01C preview renders the scene phrase without storage writes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    bool? finishedWithoutCompanion;
    var chooseCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: FirstVoiceSuccessScreen(
          canDo: 'Ich kann jemanden freundlich begr\u00fc\u00dfen.',
          phrase: '\uc548\ub155\ud558\uc138\uc694.',
          finishOverride: (withoutCompanion) async {
            finishedWithoutCompanion = withoutCompanion;
          },
          chooseCompanionOverride: () async => chooseCalls++,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text(
        '\uc548\ub155\ud558\uc138\uc694. \u00b7 ein Satz, den du jetzt h\u00f6ren und erwidern kannst.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Lernfreund w\u00e4hlen'));
    await tester.pump();
    expect(chooseCalls, 1);
    await tester.tap(find.text('Direkt zu Heute'));
    await tester.pump();
    expect(finishedWithoutCompanion, isTrue);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('kl_preferred_mascot'), isFalse);
    expect(Storage.introPreviewSeen, isFalse);
  });
}
