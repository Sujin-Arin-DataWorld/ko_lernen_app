import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/screens/learning_path_screen.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/path_trail.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

import 'support/real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadSoriRealFonts);

  setUp(() async {
    await _seed({'kl_tut_learningPath': true});
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    rootBundle.clear();
    DataLoader.reset();
    VocabPackService.reset();
    CurriculumCatalog.reset();
  });

  for (final locale in const [Locale('de'), Locale('en')]) {
    for (final brightness in Brightness.values) {
      testWidgets('visible pack retry rereads the corpus in ${locale.languageCode} '
          '${brightness.name} at 320dp and 200 percent text', (tester) async {
        _configureView(tester, const Size(320, 640));
        final catalog = await _prewarmCatalog(tester);
        VocabPackService.reset();
        DataLoader.resetVocab();

        const vocabAsset = 'assets/data/korean_vocab.csv';
        var failVocab = true;
        var vocabReads = 0;
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMessageHandler('flutter/assets', (message) async {
          final path = const StringCodec().decodeMessage(message)!;
          if (path == vocabAsset) {
            vocabReads++;
            if (failVocab) {
              return null;
            }
          }
          final bytes = File(path).readAsBytesSync();
          return ByteData.sublistView(Uint8List.fromList(bytes));
        });

        await tester.pumpWidget(
          _host(
            locale: locale,
            brightness: brightness,
            child: LearningPathScreen(
              courseSnapshotLoader: () async => _snapshot,
            ),
          ),
        );
        await _pumpUntilVisible(
          tester,
          find.byKey(const ValueKey('path-legacy-load-error')),
        );

        expect(
          find.byKey(const ValueKey('path-course-row-$_courseUnitId')),
          findsOneWidget,
        );
        expect(find.textContaining('0/0'), findsNothing);
        expect(vocabReads, 1);

        failVocab = false;
        final retry = find.descendant(
          of: find.byKey(const ValueKey('path-legacy-load-error')),
          matching: find.byType(SoriButton),
        );
        await tester.scrollUntilVisible(
          retry,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(retry);
        await tester.pump();
        await tester.tap(retry);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 500)),
        );
        await tester.pump();
        for (var attempt = 0; attempt < 100; attempt++) {
          if (find
              .byKey(const ValueKey('path-legacy-practice-toggle'))
              .evaluate()
              .isNotEmpty) {
            break;
          }
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(vocabReads, 2);
        if (find
            .byKey(const ValueKey('path-legacy-practice-toggle'))
            .evaluate()
            .isEmpty) {
          final texts = tester
              .widgetList<Text>(find.byType(Text, skipOffstage: false))
              .map((widget) => widget.data)
              .whereType<String>()
              .toList();
          throw TestFailure(
            'Retry did not resolve: legacyError='
            '${find.byKey(const ValueKey('path-legacy-load-error')).evaluate().length}, '
            'legacyLoading='
            '${find.byKey(const ValueKey('path-legacy-loading')).evaluate().length}, '
            'texts=$texts, exception=${tester.takeException()}',
          );
        }
        expect(
          find.byKey(const ValueKey('path-legacy-practice-toggle')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('path-legacy-load-error')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        expect(catalog.courseUnits, isNotEmpty);
      });
    }
  }

  testWidgets(
    'a screen retry reuses vocabulary recovered by another consumer',
    (tester) async {
      _configureView(tester, const Size(390, 844));
      await _prewarmCatalog(tester);
      VocabPackService.reset();
      DataLoader.resetVocab();

      const vocabAsset = 'assets/data/korean_vocab.csv';
      var failVocab = true;
      var vocabReads = 0;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMessageHandler('flutter/assets', (message) async {
        final path = const StringCodec().decodeMessage(message)!;
        if (path == vocabAsset) {
          vocabReads++;
          if (failVocab) {
            return null;
          }
        }
        final bytes = File(path).readAsBytesSync();
        return ByteData.sublistView(Uint8List.fromList(bytes));
      });

      await tester.pumpWidget(
        _host(
          locale: const Locale('en'),
          brightness: Brightness.light,
          textScale: 1,
          child: LearningPathScreen(
            courseSnapshotLoader: () async => _snapshot,
          ),
        ),
      );
      await _pumpUntilVisible(
        tester,
        find.byKey(const ValueKey('path-legacy-load-error')),
      );
      expect(vocabReads, 1);

      failVocab = false;
      DataLoader.resetVocab();
      final recovered = await tester.runAsync(DataLoader.loadVocab);
      expect(recovered, isNotEmpty);
      expect(DataLoader.vocabError, isNull);
      expect(vocabReads, 2);

      final retry = find.descendant(
        of: find.byKey(const ValueKey('path-legacy-load-error')),
        matching: find.byType(SoriButton),
      );
      await tester.scrollUntilVisible(
        retry,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(retry);
      await tester.pump();
      await tester.tap(retry);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pump();
      await _pumpUntilVisible(
        tester,
        find.byKey(const ValueKey('path-legacy-practice-toggle')),
      );

      expect(vocabReads, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a course read failure keeps usable legacy practice', (
    tester,
  ) async {
    _configureView(tester, const Size(390, 844));
    await _prewarmCatalog(tester);
    await tester.runAsync(VocabPackService.loadAll);
    var failCourse = true;
    var courseReads = 0;

    await tester.pumpWidget(
      _host(
        locale: const Locale('en'),
        brightness: Brightness.light,
        textScale: 1,
        child: LearningPathScreen(
          courseSnapshotLoader: () async {
            courseReads++;
            if (failCourse) {
              throw StateError('private course canary');
            }
            return _snapshot;
          },
        ),
      ),
    );
    await _pumpUntilVisible(
      tester,
      find.byKey(const ValueKey('path-course-load-error')),
    );
    await _pumpUntilVisible(
      tester,
      find.byKey(const ValueKey('path-legacy-practice-toggle')),
    );
    expect(find.textContaining('private course canary'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('path-legacy-practice-toggle')));
    await tester.pump();
    expect(find.byType(SoriPathTrail), findsOneWidget);

    failCourse = false;
    final retry = find.descendant(
      of: find.byKey(const ValueKey('path-course-load-error')),
      matching: find.byType(SoriButton),
    );
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await _pumpUntilVisible(
      tester,
      find.byKey(const ValueKey('path-course-row-$_courseUnitId')),
    );
    expect(courseReads, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a pending course target keeps legacy practice collapsed for the coach',
    (tester) async {
      _configureView(tester, const Size(390, 844));
      await _seed(const {});
      await _prewarmCatalog(tester);
      await tester.runAsync(VocabPackService.loadAll);
      final pendingCourse = Completer<CourseMasterySnapshot?>();

      await tester.pumpWidget(
        _host(
          locale: const Locale('en'),
          brightness: Brightness.light,
          textScale: 1,
          child: LearningPathScreen(
            courseSnapshotLoader: () => pendingCourse.future,
          ),
        ),
      );
      await _pumpUntilVisible(
        tester,
        find.byKey(const ValueKey('path-legacy-practice-toggle')),
      );

      expect(
        find.byKey(const ValueKey('path-legacy-practice-content')),
        findsNothing,
      );
      pendingCourse.complete(_snapshot);
      await _pumpUntilVisible(
        tester,
        find.byKey(const ValueKey('path-course-row-$_courseUnitId')),
      );
      expect(
        find.byKey(const ValueKey('path-legacy-practice-content')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'course completion revealing legacy practice scrolls to its target',
    (tester) async {
      _configureView(tester, const Size(390, 420));
      await _seed(const {});
      await _prewarmCatalog(tester);
      await tester.runAsync(VocabPackService.loadAll);
      final pendingCourse = Completer<CourseMasterySnapshot?>();

      await tester.pumpWidget(
        _host(
          locale: const Locale('en'),
          brightness: Brightness.light,
          textScale: 1,
          child: LearningPathScreen(
            courseSnapshotLoader: () => pendingCourse.future,
          ),
        ),
      );
      await _pumpUntilVisible(
        tester,
        find.byKey(const ValueKey('path-legacy-practice-toggle')),
      );
      expect(
        find.byKey(const ValueKey('path-legacy-practice-content')),
        findsNothing,
      );

      pendingCourse.complete(const CourseMasterySnapshot(placementLevel: 'a1'));
      await _pumpUntilVisible(
        tester,
        find.byKey(const ValueKey('path-legacy-practice-content')),
      );
      await tester.pump(const Duration(milliseconds: 600));

      final pathScrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(RefreshIndicator),
          matching: find.byType(Scrollable),
        ),
      );
      expect(pathScrollable.position.pixels, greaterThan(0));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('an older course refresh cannot replace a newer result', (
    tester,
  ) async {
    _configureView(tester, const Size(390, 844));
    await _prewarmCatalog(tester);
    await tester.runAsync(VocabPackService.loadAll);
    final olderCourse = Completer<CourseMasterySnapshot?>();
    final newerCourse = Completer<CourseMasterySnapshot?>();
    var courseReads = 0;

    await tester.pumpWidget(
      _host(
        locale: const Locale('en'),
        brightness: Brightness.light,
        textScale: 1,
        child: LearningPathScreen(
          courseSnapshotLoader: () {
            courseReads++;
            return courseReads == 1 ? olderCourse.future : newerCourse.future;
          },
        ),
      ),
    );
    await _pumpUntilVisible(
      tester,
      find.byKey(const ValueKey('path-legacy-practice-toggle')),
    );
    expect(courseReads, 1);

    tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show();
    for (var attempt = 0; attempt < 20 && courseReads < 2; attempt++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(courseReads, 2);

    newerCourse.complete(_snapshot);
    await _pumpUntilVisible(
      tester,
      find.byKey(const ValueKey('path-course-row-$_courseUnitId')),
    );
    olderCourse.complete(const CourseMasterySnapshot(placementLevel: 'c2'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('path-course-row-$_courseUnitId')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pending course completion is ignored after dispose', (
    tester,
  ) async {
    _configureView(tester, const Size(390, 844));
    await _prewarmCatalog(tester);
    await tester.runAsync(VocabPackService.loadAll);
    final pendingCourse = Completer<CourseMasterySnapshot?>();
    var courseReads = 0;

    await tester.pumpWidget(
      _host(
        locale: const Locale('en'),
        brightness: Brightness.light,
        textScale: 1,
        child: LearningPathScreen(
          courseSnapshotLoader: () {
            courseReads++;
            return pendingCourse.future;
          },
        ),
      ),
    );
    for (var attempt = 0; attempt < 20 && courseReads < 1; attempt++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(courseReads, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    pendingCourse.complete(_snapshot);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('a malformed legacy store cannot hide a usable course', (
    tester,
  ) async {
    _configureView(tester, const Size(390, 844));
    const corruptRaw = '{"a1_greetings_1":{"level":7,"status":"started"}}';
    await _seed({
      'kl_tut_learningPath': true,
      'kl_pack_progress_v1': corruptRaw,
    });
    await _prewarmCatalog(tester);

    await tester.pumpWidget(
      _host(
        locale: const Locale('de'),
        brightness: Brightness.dark,
        textScale: 1,
        child: LearningPathScreen(courseSnapshotLoader: () async => _snapshot),
        routeArguments: 'a1_greetings_1',
      ),
    );
    await _pumpUntilVisible(
      tester,
      find.byKey(const ValueKey('path-legacy-load-error')),
    );

    expect(
      find.byKey(const ValueKey('path-course-row-$_courseUnitId')),
      findsOneWidget,
    );
    expect(Storage.packProgressJsonRaw, corruptRaw);

    final retry = find.descendant(
      of: find.byKey(const ValueKey('path-legacy-load-error')),
      matching: find.byType(SoriButton),
    );
    await tester.scrollUntilVisible(
      retry,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(retry);
    await tester.pump();

    final pendingRetry = Completer<ByteData?>();
    VocabPackService.reset();
    DataLoader.resetVocab();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) {
          expect(
            const StringCodec().decodeMessage(message),
            'assets/data/korean_vocab.csv',
          );
          return pendingRetry.future;
        });
    await tester.tap(retry);
    await tester.pump();
    final context = tester.element(find.byType(LearningPathScreen));
    expect(find.text(AppL10n.of(context).pathLevelPacks(0, 0)), findsNothing);
    expect(find.byKey(const ValueKey('path-legacy-loading')), findsOneWidget);
    pendingRetry.complete(ByteData.sublistView(Uint8List(0)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(Storage.packProgressJsonRaw, corruptRaw);
    expect(
      find.byKey(const ValueKey('path-legacy-load-error')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

const _courseUnitId = 'a1_01_greetings_hangul';
const _snapshot = CourseMasterySnapshot(
  placementLevel: 'a1',
  currentCourseUnitId: _courseUnitId,
);

Future<CurriculumCatalog> _prewarmCatalog(WidgetTester tester) async {
  final catalog = await tester.runAsync(CurriculumCatalog.load);
  return catalog!;
}

Future<void> _seed(Map<String, Object> values) async {
  rootBundle.clear();
  Storage.resetForTesting();
  Storage.resetCourseMasteryForTesting();
  SharedPreferences.setMockInitialValues(values);
  await Storage.init();
  DataLoader.reset();
  VocabPackService.reset();
  CurriculumCatalog.reset();
}

void _configureView(WidgetTester tester, Size size) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
}

Future<void> _pumpUntilVisible(
  WidgetTester tester,
  Finder finder, {
  int attempts = 100,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  throw TestFailure(
    'Expected $finder after ${attempts * 100}ms. '
    'Exception: ${tester.takeException()}',
  );
}

Widget _host({
  required Locale locale,
  required Brightness brightness,
  required Widget child,
  double textScale = 2,
  Object? routeArguments,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
  themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
  locale: locale,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  onGenerateInitialRoutes: (_) => [
    MaterialPageRoute<void>(
      settings: RouteSettings(name: '/path', arguments: routeArguments),
      builder: (_) => child,
    ),
  ],
  onGenerateRoute: (settings) => MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => const Scaffold(body: SizedBox.shrink()),
  ),
  builder: (context, appChild) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: SoriTypeScale(child: appChild!),
    );
  },
);
