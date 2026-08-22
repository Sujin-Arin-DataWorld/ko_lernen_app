import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/screens/gye_create_screen.dart';
import 'package:ko_lernen_app/screens/gye_join_screen.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/gye_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/text_field.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

const _safeInsets = EdgeInsets.only(top: 44, bottom: 34);
const _ready = CloudWriteSession(
  uid: 'fixture-user',
  epoch: 1,
  mode: CloudWriteMode.ready,
);
const _matrix = <({Size size, double textScale})>[
  (size: Size(320, 640), textScale: 2),
  (size: Size(360, 400), textScale: 1),
  (size: Size(390, 844), textScale: 1.3),
  (size: Size(720, 1024), textScale: 1.3),
  (size: Size(1280, 900), textScale: 1.3),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gye entry forms reflow in the locked DE/EN matrix', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    _resetViewAfterTest(tester);
    final sessions = ValueNotifier<CloudWriteSession?>(_ready);
    addTearDown(sessions.dispose);

    for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
      final t = lookupAppL10n(locale);
      for (final testCase in _matrix) {
        await _pumpEntry(
          tester,
          GyeCreateScreen(accountSessions: sessions),
          locale: locale,
          size: testCase.size,
          textScale: testCase.textScale,
        );

        expect(find.byType(SoriTextField), findsNWidgets(2));
        expect(find.text(t.gyeNameLabel), findsOneWidget);
        expect(find.text(t.gyeNicknameLabel), findsOneWidget);
        expect(find.text(t.gyePromisePickerLabel), findsOneWidget);
        await _expectReachableAction(tester, t.gyeCreateCta);
        expect(tester.takeException(), isNull);

        await _pumpEntry(
          tester,
          GyeJoinScreen(accountSessions: sessions),
          locale: locale,
          size: testCase.size,
          textScale: testCase.textScale,
        );

        expect(find.byType(SoriTextField), findsNWidgets(2));
        expect(find.text(t.gyeCodeInputLabel), findsOneWidget);
        expect(find.text(t.gyeNicknameLabel), findsOneWidget);
        await _expectReachableAction(tester, t.gyeJoinCta);
        expect(tester.takeException(), isNull);
      }
    }
    semantics.dispose();
  });

  testWidgets(
    'account transitions are announced and entry writes fail closed',
    (tester) async {
      final semantics = tester.ensureSemantics();
      _resetViewAfterTest(tester);
      final sessions = ValueNotifier<CloudWriteSession?>(null);
      addTearDown(sessions.dispose);

      for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
        final t = lookupAppL10n(locale);
        for (final screen in <Widget>[
          GyeCreateScreen(accountSessions: sessions),
          GyeJoinScreen(accountSessions: sessions),
        ]) {
          final actionLabel = screen is GyeCreateScreen
              ? t.gyeCreateCta
              : t.gyeJoinCta;
          await _pumpEntry(
            tester,
            screen,
            locale: locale,
            size: const Size(320, 640),
            textScale: 2,
          );

          final paused = tester
              .getSemantics(find.bySemanticsLabel(t.gyeAccountTransitionPaused))
              .getSemanticsData();
          expect(paused.label, t.gyeAccountTransitionPaused);
          expect(paused.flagsCollection.isLiveRegion, isTrue);

          final action = find.widgetWithText(SoriButton, actionLabel);
          await tester.scrollUntilVisible(
            action,
            100,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pump();
          final actionData = tester
              .getSemantics(_soriButtonSemantics(action))
              .getSemanticsData();
          expect(actionData.flagsCollection.isButton, isTrue);
          expect(actionData.flagsCollection.isEnabled, ui.Tristate.isFalse);
          expect(actionData.hasAction(ui.SemanticsAction.tap), isFalse);
          expect(tester.takeException(), isNull);
        }
      }
      semantics.dispose();
    },
  );

  testWidgets('created result remains actionable in the locked DE/EN matrix', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    _resetViewAfterTest(tester);
    final sessions = ValueNotifier<CloudWriteSession?>(_ready);
    addTearDown(sessions.dispose);

    for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
      final t = lookupAppL10n(locale);
      for (final testCase in _matrix) {
        await _pumpEntry(
          tester,
          GyeCreateScreen(
            accountSessions: sessions,
            createGye:
                ({
                  required name,
                  required nickname,
                  required weeklyPromiseId,
                }) => Future<GyeMeta>.value(
                  const GyeMeta(
                    id: 'ABC234',
                    name: 'Morning Tigers',
                    code: 'ABC234',
                    ownerId: 'fixture-user',
                  ),
                ),
          ),
          locale: locale,
          size: testCase.size,
          textScale: testCase.textScale,
        );
        await tester.enterText(find.byType(TextField).at(0), 'Morning Tigers');
        await tester.enterText(find.byType(TextField).at(1), 'Mina');
        await _tapAction(tester, t.gyeCreateCta);
        await tester.pumpAndSettle();

        final announcementLabel = t.gyeCreatedAnnouncement(
          'Morning Tigers',
          'ABC234',
        );
        final announcement = tester
            .getSemantics(find.bySemanticsLabel(announcementLabel))
            .getSemanticsData();
        expect(announcement.label, announcementLabel);
        expect(announcement.flagsCollection.isLiveRegion, isTrue);

        for (final label in <String>[
          t.gyeShareCode,
          t.gyeCopyCode,
          t.gyeOpenCta,
          t.btnClose,
        ]) {
          await _expectReachableAction(tester, label);
        }
        _expectOutlinedBoundary(tester, t.gyeCopyCode);
        _expectOutlinedBoundary(tester, t.gyeOpenCta);
        expect(tester.takeException(), isNull);
      }
    }
    semantics.dispose();
  });

  testWidgets(
    'create announces loading, preserves input on failure, and exposes the result',
    (tester) async {
      final semantics = tester.ensureSemantics();
      _resetViewAfterTest(tester);
      final sessions = ValueNotifier<CloudWriteSession?>(_ready);
      addTearDown(sessions.dispose);

      for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
        final t = lookupAppL10n(locale);
        final firstAttempt = Completer<GyeMeta>();
        var attempts = 0;

        Future<GyeMeta> createGye({
          required String name,
          required String nickname,
          required String weeklyPromiseId,
        }) {
          attempts += 1;
          if (attempts == 1) {
            return firstAttempt.future;
          }
          return Future<GyeMeta>.value(
            const GyeMeta(
              id: 'ABC234',
              name: 'Morning Tigers',
              code: 'ABC234',
              ownerId: 'fixture-user',
            ),
          );
        }

        await _pumpEntry(
          tester,
          GyeCreateScreen(accountSessions: sessions, createGye: createGye),
          locale: locale,
          size: const Size(390, 844),
          textScale: 1.3,
        );
        await tester.enterText(find.byType(TextField).at(0), 'Morning Tigers');
        await tester.enterText(find.byType(TextField).at(1), 'Mina');
        await _tapAction(tester, t.gyeCreateCta);
        await tester.pump();

        expect(find.byType(AppLoading), findsOneWidget);
        final loading = tester
            .getSemantics(find.bySemanticsLabel(t.gyeCreatingLoading))
            .getSemanticsData();
        expect(loading.label, t.gyeCreatingLoading);
        expect(loading.flagsCollection.isLiveRegion, isTrue);
        _expectFieldValues(tester, const <String>['Morning Tigers', 'Mina']);

        firstAttempt.completeError(const GyeException(GyeError.network));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(AppLoading), findsNothing);
        expect(find.text(t.gyeErrNetwork), findsOneWidget);
        _expectFieldValues(tester, const <String>['Morning Tigers', 'Mina']);

        await _tapAction(tester, t.gyeCreateCta);
        await tester.pumpAndSettle();

        final announcementLabel = t.gyeCreatedAnnouncement(
          'Morning Tigers',
          'ABC234',
        );
        final announcement = tester
            .getSemantics(find.bySemanticsLabel(announcementLabel))
            .getSemanticsData();
        expect(announcement.label, announcementLabel);
        expect(announcement.flagsCollection.isLiveRegion, isTrue);
        expect(attempts, 2);
        for (final label in <String>[
          t.gyeShareCode,
          t.gyeCopyCode,
          t.gyeOpenCta,
          t.btnClose,
        ]) {
          await _expectReachableAction(tester, label);
        }

        await _tapAction(tester, t.gyeOpenCta);
        await tester.pumpAndSettle();
        expect(find.text('gye-destination:ABC234'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      semantics.dispose();
    },
  );

  testWidgets('join announces loading, preserves input, and keeps route args', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    _resetViewAfterTest(tester);
    final sessions = ValueNotifier<CloudWriteSession?>(_ready);
    addTearDown(sessions.dispose);

    for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
      final t = lookupAppL10n(locale);
      final joined = Completer<GyeMeta>();
      await _pumpEntry(
        tester,
        GyeJoinScreen(
          accountSessions: sessions,
          joinGye: ({required code, required nickname}) => joined.future,
        ),
        locale: locale,
        size: const Size(390, 844),
        textScale: 1.3,
      );
      await tester.enterText(find.byType(TextField).at(0), 'ABC234');
      await tester.enterText(find.byType(TextField).at(1), 'Mina');
      await _tapAction(tester, t.gyeJoinCta);
      await tester.pump();

      expect(find.byType(AppLoading), findsOneWidget);
      final loading = tester
          .getSemantics(find.bySemanticsLabel(t.gyeJoiningLoading))
          .getSemanticsData();
      expect(loading.label, t.gyeJoiningLoading);
      expect(loading.flagsCollection.isLiveRegion, isTrue);
      _expectFieldValues(tester, const <String>['ABC234', 'Mina']);

      joined.complete(
        const GyeMeta(
          id: 'ABC234',
          name: 'Morning Tigers',
          code: 'ABC234',
          ownerId: 'fixture-owner',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('gye-destination:ABC234'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    semantics.dispose();
  });
}

Future<void> _expectReachableAction(WidgetTester tester, String label) async {
  final button = find.widgetWithText(SoriButton, label);
  await tester.scrollUntilVisible(
    button,
    100,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
  expect(button.hitTestable(), findsOneWidget);
  expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
  final data = tester
      .getSemantics(_soriButtonSemantics(button))
      .getSemanticsData();
  expect(data.label, label);
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.flagsCollection.isEnabled, ui.Tristate.isTrue);
  expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
}

void _expectOutlinedBoundary(WidgetTester tester, String label) {
  final button = find.widgetWithText(SoriButton, label);
  final decorated = find.descendant(
    of: button,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).border != null,
    ),
  );
  final container = tester.widgetList<Container>(decorated).single;
  final border = (container.decoration! as BoxDecoration).border! as Border;
  final renderedBorder = Color.alphaBlend(border.top.color, SoriColors.lightBg);
  expect(
    SoriColors.contrastRatio(renderedBorder, SoriColors.lightBg),
    greaterThanOrEqualTo(3),
  );
}

Future<void> _tapAction(WidgetTester tester, String label) async {
  final button = find.widgetWithText(SoriButton, label);
  await tester.scrollUntilVisible(
    button,
    100,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
  await tester.tap(_soriButtonSemantics(button));
}

Finder _soriButtonSemantics(Finder button) =>
    find.descendant(of: button, matching: find.byType(Semantics)).first;

void _expectFieldValues(WidgetTester tester, List<String> expected) {
  final fields = tester
      .widgetList<EditableText>(find.byType(EditableText))
      .toList(growable: false);
  expect(fields.map((field) => field.controller.text), expected);
}

Future<void> _pumpEntry(
  WidgetTester tester,
  Widget screen, {
  required Locale locale,
  required Size size,
  required double textScale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      routes: <String, WidgetBuilder>{
        '/gye': (context) => Scaffold(
          body: Center(
            child: Text(
              'gye-destination:${ModalRoute.of(context)?.settings.arguments}',
            ),
          ),
        ),
      },
      builder: (context, appChild) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            padding: _safeInsets,
            viewPadding: _safeInsets,
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: SoriTypeScale(child: appChild!),
        );
      },
      home: screen,
    ),
  );
}

void _resetViewAfterTest(WidgetTester tester) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
