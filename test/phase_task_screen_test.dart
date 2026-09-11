import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/phase_task_screen.dart';
import 'package:ko_lernen_app/services/phase_task_catalog.dart';
import 'package:ko_lernen_app/services/pronunciation_recorder.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

class FakeRecorder implements PronunciationRecorder {
  bool allowed = false;
  int stops = 0;
  final controller = StreamController<Uint8List>();
  @override
  Future<bool> requestPermission() async => allowed;
  @override
  Future<Stream<Uint8List>> startPcm16Stream() async => controller.stream;
  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> dispose() async {
    await controller.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PhaseTaskCatalog catalog;
  setUpAll(() async {
    catalog = await PhaseTaskCatalog.load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  Widget host(Widget child, {String locale = 'en', double scale = 1}) =>
      MaterialApp(
        theme: AppTheme.dark,
        locale: Locale(locale),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: child,
      );
  Future<void> tap(WidgetTester tester, Finder finder) async {
    if (find.byType(Scrollable).evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(
        finder,
        300,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'form drafts survive reopen, failed save cannot display success, retry persists evaluated result',
    (tester) async {
      var writes = 0;
      PhaseTaskResult? saved;
      Widget screen() => PhaseTaskScreen(
        arguments: const PhaseTaskRoute(
          'KP01',
          'KP01:writing:01',
          assessment: true,
        ),
        loader: () async => catalog,
        saveAttempt: (result) async {
          writes++;
          if (writes == 1) {
            throw StateError('disk failure');
          }
          saved = result;
        },
      );
      await tester.pumpWidget(host(screen()));
      await tester.pumpAndSettle();
      final name = find.byKey(
        const ValueKey('KP01:writing:01:true:name-field'),
      );
      final country = find.byKey(
        const ValueKey('KP01:writing:01:true:country-field'),
      );
      await tester.ensureVisible(name);
      await tester.enterText(name, '유나');
      await tester.pumpAndSettle();
      await tester.ensureVisible(country);
      await tester.enterText(country, '한국');
      for (final entry in {
        'occupation': '선생님',
        'introduction': '저는 선생님이에요.',
        'contrast': '저는 학생이 아니에요.',
      }.entries) {
        final field = find.byKey(
          ValueKey('KP01:writing:01:true:${entry.key}-field'),
        );
        await tester.scrollUntilVisible(
          field,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(field, entry.value);
        await tester.pumpAndSettle();
      }
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.pumpWidget(host(screen()));
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(name).initialValue, '유나');
      await tap(tester, find.byKey(const ValueKey('phase-task-submit')));
      expect(saved, isNull);
      expect(find.text('100%'), findsNothing);
      await tap(tester, find.byKey(const ValueKey('phase-task-submit')));
      expect(saved!.passed, isTrue);
      await tester.scrollUntilVisible(
        find.text('100%'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('100%'), findsOneWidget);
      expect(
        saved!.evidence('id', DateTime.utc(2026)).toJson().toString(),
        isNot(contains('유나')),
      );
    },
  );
  testWidgets(
    'missing audio disables submission and transcript stays hidden until evaluated',
    (tester) async {
      var plays = 0, writes = 0;
      await tester.pumpWidget(
        host(
          PhaseTaskScreen(
            arguments: const PhaseTaskRoute(
              'KP01',
              'KP01:listening:01',
              assessment: true,
            ),
            loader: () async => catalog,
            playAudio: (_) async => ++plays > 1,
            saveAttempt: (_) async {
              writes++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final submit = find.byKey(const ValueKey('phase-task-submit'));
      await tester.scrollUntilVisible(
        submit,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.widget<SoriButton>(submit).onTap, isNull);
      final transcript = catalog.byId('KP01:listening:01').assessment.sourceKo;
      expect(find.text(transcript), findsNothing);
      await tester.drag(find.byType(ListView), const Offset(0, 3000));
      await tester.pumpAndSettle();
      await tap(tester, find.widgetWithIcon(SoriButton, Icons.volume_up));
      await tester.scrollUntilVisible(
        submit,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.widget<SoriButton>(submit).onTap, isNull);
      expect(writes, 0);
      await tester.drag(find.byType(ListView), const Offset(0, 3000));
      await tester.pumpAndSettle();
      await tap(tester, find.widgetWithIcon(SoriButton, Icons.volume_up));
      await tester.scrollUntilVisible(
        submit,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.widget<SoriButton>(submit).onTap, isNotNull);
      await tap(tester, submit);
      expect(writes, 1);
      await tester.drag(find.byType(ListView), const Offset(0, 3000));
      await tester.pumpAndSettle();
      expect(find.text(transcript), findsOneWidget);
    },
  );
  testWidgets('microphone denial allows retry, short speech remains unscored', (
    tester,
  ) async {
    final recorder = FakeRecorder();
    PhaseTaskResult? saved;
    await tester.pumpWidget(
      host(
        PhaseTaskScreen(
          arguments: const PhaseTaskRoute(
            'KP01',
            'KP01:speaking:01',
            assessment: true,
          ),
          loader: () async => catalog,
          recorder: recorder,
          saveAttempt: (result) async {
            saved = result;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tap(tester, find.widgetWithIcon(SoriButton, Icons.mic));
    expect(
      tester
          .widget<SoriButton>(find.byKey(const ValueKey('phase-task-submit')))
          .onTap,
      isNull,
    );
    recorder.allowed = true;
    await tap(tester, find.widgetWithIcon(SoriButton, Icons.mic));
    recorder.controller.add(Uint8List(40000));
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithIcon(SoriButton, Icons.stop));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(recorder.stops, 1);
    expect(
      tester
          .widget<SoriButton>(find.byKey(const ValueKey('phase-task-submit')))
          .onTap,
      isNotNull,
      reason: tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .join(' | '),
    );
    await tap(tester, find.byKey(const ValueKey('phase-task-submit')));
    expect(saved!.score, isNull);
    expect(saved!.passed, isFalse);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets('invalid route exposes working retry without saving', (
    tester,
  ) async {
    var loads = 0;
    await tester.pumpWidget(
      host(
        PhaseTaskScreen(
          arguments: const PhaseTaskRoute('KP02', 'KP01:writing:01'),
          loader: () async {
            loads++;
            return catalog;
          },
          saveAttempt: (_) async {
            fail('invalid route saved');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('phase-task-submit')), findsNothing);
    await tap(tester, find.byKey(const ValueKey('phase-task-load-retry')));
    expect(loads, 2);
  });
  testWidgets(
    'German task input remains usable at 320 pixels with 200 percent text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        host(
          PhaseTaskScreen(
            arguments: const PhaseTaskRoute('KP01', 'KP01:writing:01'),
            loader: () async => catalog,
            saveAttempt: (_) async {},
          ),
          locale: 'de',
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('phase-task-submit')),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
