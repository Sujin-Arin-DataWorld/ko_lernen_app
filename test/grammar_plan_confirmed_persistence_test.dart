import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/grammar_study_plan.dart';
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/grammar_plan_service.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';

enum _NativeWriteOutcome {
  success,
  reject,
  delayedSuccess,
  throwCommittedReloadUnavailable,
  throwUncommittedReloadUnavailable,
}

class _NativeGrammarPlatform extends SharedPreferencesStorePlatform {
  _NativeGrammarPlatform(Map<String, Object> initial) : values = {...initial};

  final Map<String, Object> values;
  final Map<String, List<_NativeWriteOutcome>> outcomes = {};
  final Map<String, int> writes = {};
  final Map<String, Completer<void>> writeStarted = {};
  final Map<String, Completer<void>> releaseWrite = {};
  bool reloadUnavailable = false;

  void enqueue(String key, _NativeWriteOutcome outcome) {
    outcomes.putIfAbsent(key, () => []).add(outcome);
  }

  @override
  Future<Map<String, Object>> getAll() async {
    if (reloadUnavailable) {
      throw StateError('native grammar preferences unavailable');
    }
    return values.map((key, value) => MapEntry('flutter.$key', value));
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    final name = key.substring('flutter.'.length);
    writes[name] = (writes[name] ?? 0) + 1;
    final outcome = outcomes[name]?.isNotEmpty ?? false
        ? outcomes[name]!.removeAt(0)
        : _NativeWriteOutcome.success;
    switch (outcome) {
      case _NativeWriteOutcome.success:
        values[name] = value;
        return true;
      case _NativeWriteOutcome.reject:
        return false;
      case _NativeWriteOutcome.delayedSuccess:
        writeStarted.putIfAbsent(name, Completer<void>.new).complete();
        await releaseWrite.putIfAbsent(name, Completer<void>.new).future;
        values[name] = value;
        return true;
      case _NativeWriteOutcome.throwCommittedReloadUnavailable:
        values[name] = value;
        reloadUnavailable = true;
        throw StateError('native grammar commit reply lost');
      case _NativeWriteOutcome.throwUncommittedReloadUnavailable:
        reloadUnavailable = true;
        throw StateError('native grammar write reply lost');
    }
  }

  @override
  Future<bool> remove(String key) async {
    final name = key.substring('flutter.'.length);
    writes[name] = (writes[name] ?? 0) + 1;
    if (reloadUnavailable) {
      return false;
    }
    final outcome = outcomes[name]?.isNotEmpty ?? false
        ? outcomes[name]!.removeAt(0)
        : _NativeWriteOutcome.success;
    switch (outcome) {
      case _NativeWriteOutcome.success:
        values.remove(name);
        return true;
      case _NativeWriteOutcome.reject:
        return false;
      case _NativeWriteOutcome.delayedSuccess:
        writeStarted.putIfAbsent(name, Completer<void>.new).complete();
        await releaseWrite.putIfAbsent(name, Completer<void>.new).future;
        values.remove(name);
        return true;
      case _NativeWriteOutcome.throwCommittedReloadUnavailable:
        values.remove(name);
        reloadUnavailable = true;
        throw StateError('native grammar removal reply lost');
      case _NativeWriteOutcome.throwUncommittedReloadUnavailable:
        reloadUnavailable = true;
        throw StateError('native grammar removal reply lost');
    }
  }

  @override
  Future<bool> clear() async {
    values.clear();
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalPlatform = SharedPreferencesStorePlatform.instance;

  tearDown(() {
    Storage.resetForTesting();
    DataLoader.reset();
    CurriculumCatalog.reset();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = originalPlatform;
  });

  testWidgets('native false on plan blob keeps onboarding non-authoritative', (
    tester,
  ) async {
    final platform = await _initializeNativeStorage(
      tester,
      originalPlatform: originalPlatform,
    );
    platform.enqueue('kl_gram_plan_v1', _NativeWriteOutcome.reject);
    await _pumpGrammar(tester);

    _tapStart(tester);
    await _boundedPump(tester);

    expect(platform.writes['kl_gram_plan_v1'], 1);
    expect(platform.values.containsKey('kl_gram_plan_v1'), isFalse);
    expect(
      find.byKey(const Key('grammar-plan-onboarding-sheet')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('grammar-plan-save-error')), findsOneWidget);
    expect(find.byKey(const Key('grammar-plan-day-header')), findsNothing);
  });

  testWidgets('native false on selected level keeps partial start retryable', (
    tester,
  ) async {
    final platform = await _initializeNativeStorage(
      tester,
      originalPlatform: originalPlatform,
    );
    platform.enqueue(
      Storage.grammarPlanLevelPreferenceKey,
      _NativeWriteOutcome.reject,
    );
    await _pumpGrammar(tester);

    _tapStart(tester);
    await _boundedPump(tester);

    expect(platform.writes['kl_gram_plan_v1'], 1);
    expect(platform.writes[Storage.grammarPlanLevelPreferenceKey], 1);
    expect(platform.values.containsKey('kl_gram_plan_v1'), isTrue);
    expect(
      platform.values.containsKey(Storage.grammarPlanLevelPreferenceKey),
      isFalse,
    );
    expect(
      find.byKey(const Key('grammar-plan-onboarding-sheet')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('grammar-plan-save-error')), findsOneWidget);
    expect(find.byKey(const Key('grammar-plan-day-header')), findsNothing);
  });

  testWidgets('native false on day record withholds completion output', (
    tester,
  ) async {
    final platform = await _initializeNativeStorage(
      tester,
      originalPlatform: originalPlatform,
    );
    await _pumpGrammar(tester);

    await tester.tap(find.byKey(const Key('grammar-plan-items-3')));
    await tester.pump();
    _tapStart(tester);
    await _boundedPump(tester);
    final raw = platform.values['kl_gram_plan_v1']! as String;
    platform.enqueue('kl_gram_plan_v1', _NativeWriteOutcome.reject);

    final feed = tester.widget<SoriContentFeed>(find.byType(SoriContentFeed));
    feed.onSkip!();
    await tester.pump();
    feed.onSkip!();
    await tester.pump();
    feed.onSkip!();
    await _boundedPump(tester);

    expect(platform.writes['kl_gram_plan_v1'], 2);
    expect(platform.values['kl_gram_plan_v1'], raw);
    expect(
      find.byKey(const Key('grammar-plan-completion-sheet')),
      findsNothing,
    );
    expect(find.byKey(const Key('grammar-plan-day-complete')), findsNothing);
    expect(find.byKey(const Key('grammar-plan-save-error')), findsOneWidget);

    await tester.tap(find.byKey(const Key('grammar-plan-save-retry')));
    await _boundedPump(tester);

    expect(
      find.byKey(const Key('grammar-plan-completion-sheet')),
      findsOneWidget,
    );
    final completed = GrammarPlanService.decodePlans(
      platform.values['kl_gram_plan_v1']! as String,
    )['a1'];
    expect(completed?.servedIdsByDate.length, 1);
    expect(completed?.servedIdsByDate[Storage.todayIso()]?.length, 3);
    expect(platform.writes['kl_gram_plan_v1'], 3);
  });

  for (final committed in [false, true]) {
    testWidgets(
      'unknown plan reply reconciles frozen start without blind replay; '
      'committed=$committed',
      (tester) async {
        final platform = await _initializeNativeStorage(
          tester,
          originalPlatform: originalPlatform,
        );
        platform.enqueue(
          'kl_gram_plan_v1',
          committed
              ? _NativeWriteOutcome.throwCommittedReloadUnavailable
              : _NativeWriteOutcome.throwUncommittedReloadUnavailable,
        );
        await _pumpGrammar(tester);

        await tester.tap(find.byKey(const Key('grammar-plan-items-3')));
        await tester.pump();
        _tapStart(tester);
        await _boundedPump(tester);

        expect(platform.writes['kl_gram_plan_v1'], 1);
        expect(
          platform.values.containsKey('kl_gram_plan_v1'),
          committed,
          reason: 'The native disk state differs across the two lost replies.',
        );
        expect(
          Storage.grammarPlanRawJson,
          isEmpty,
          reason: 'An unresolved optimistic cache must not become a read view.',
        );
        expect(
          find.byKey(const Key('grammar-plan-save-error')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('grammar-plan-day-header')), findsNothing);
        platform.reloadUnavailable = false;

        await tester.tap(find.byKey(const Key('grammar-plan-save-retry')));
        await _boundedPump(tester);

        expect(
          find.byKey(const Key('grammar-plan-onboarding-sheet')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('grammar-plan-day-header')),
          findsOneWidget,
        );
        expect(
          platform.writes['kl_gram_plan_v1'],
          committed ? 1 : 2,
          reason:
              'A durable unknown leg is confirmed; an absent leg is retried.',
        );
        final stored = GrammarPlanService.decodePlans(
          platform.values['kl_gram_plan_v1']! as String,
        )['a1'];
        expect(stored?.itemsPerDay, 3);
        expect(platform.values[Storage.grammarPlanLevelPreferenceKey], 'a1');
      },
    );
  }

  testWidgets('different-level intents serialize and preserve both plans', (
    tester,
  ) async {
    final platform = await _initializeNativeStorage(
      tester,
      originalPlatform: originalPlatform,
      loadGrammar: false,
    );
    final a1 = GrammarPlanWriteOperation.start(
      plan: const GrammarStudyPlan(
        level: 'a1',
        itemsPerDay: 3,
        servedIdsByDate: {},
      ),
    );
    final b1 = GrammarPlanWriteOperation.start(
      plan: const GrammarStudyPlan(
        level: 'b1',
        itemsPerDay: 7,
        servedIdsByDate: {},
      ),
    );

    await Future.wait([a1.save(), b1.save()]);

    final plans = GrammarPlanService.decodePlans(Storage.grammarPlanRawJson);
    expect(plans['a1']?.itemsPerDay, 3);
    expect(plans['b1']?.itemsPerDay, 7);
    expect(Storage.grammarPlanLevel, 'b1');
    expect(platform.writes['kl_gram_plan_v1'], 2);
  });

  for (final committed in [false, true]) {
    testWidgets(
      'null selected level reconciles an unknown removal; committed=$committed',
      (tester) async {
        final platform = await _initializeNativeStorage(
          tester,
          originalPlatform: originalPlatform,
          loadGrammar: false,
        );
        await Storage.setGrammarPlanLevel('b1');
        platform.enqueue(
          Storage.grammarPlanLevelPreferenceKey,
          committed
              ? _NativeWriteOutcome.throwCommittedReloadUnavailable
              : _NativeWriteOutcome.throwUncommittedReloadUnavailable,
        );

        await expectLater(
          Storage.setGrammarPlanLevel(null),
          throwsA(isA<PreferenceOutcomeUnknownException>()),
        );
        expect(Storage.grammarPlanLevel, 'b1');
        expect(
          platform.values.containsKey(Storage.grammarPlanLevelPreferenceKey),
          !committed,
        );
        platform.reloadUnavailable = false;

        await Storage.setGrammarPlanLevel(null);

        expect(Storage.grammarPlanLevel, isNull);
        expect(
          platform.values.containsKey(Storage.grammarPlanLevelPreferenceKey),
          isFalse,
        );
        expect(
          platform.writes[Storage.grammarPlanLevelPreferenceKey],
          committed ? 2 : 3,
        );
      },
    );
  }

  testWidgets('same-target stale intent cannot overwrite a confirmed plan', (
    tester,
  ) async {
    await _initializeNativeStorage(
      tester,
      originalPlatform: originalPlatform,
      loadGrammar: false,
    );
    final first = GrammarPlanWriteOperation.start(
      plan: const GrammarStudyPlan(
        level: 'a1',
        itemsPerDay: 3,
        servedIdsByDate: {},
      ),
    );
    final conflicting = GrammarPlanWriteOperation.start(
      plan: const GrammarStudyPlan(
        level: 'a1',
        itemsPerDay: 7,
        servedIdsByDate: {},
      ),
    );

    await first.save();
    await expectLater(
      conflicting.save(),
      throwsA(isA<GrammarPlanConflictException>()),
    );

    final plan = GrammarPlanService.decodePlans(
      Storage.grammarPlanRawJson,
    )['a1'];
    expect(plan?.itemsPerDay, 3);
  });

  testWidgets('malformed grammar recovery bytes are never overwritten', (
    tester,
  ) async {
    final platform = await _initializeNativeStorage(
      tester,
      originalPlatform: originalPlatform,
      extraInitial: {'kl_gram_plan_v1': '{broken'},
      loadGrammar: false,
    );
    final operation = GrammarPlanWriteOperation.start(
      plan: const GrammarStudyPlan(
        level: 'a1',
        itemsPerDay: 5,
        servedIdsByDate: {},
      ),
    );

    await expectLater(
      operation.save(),
      throwsA(isA<GrammarPlanRecoveryValueException>()),
    );

    expect(platform.values['kl_gram_plan_v1'], '{broken');
    expect(platform.writes['kl_gram_plan_v1'], isNull);
  });

  testWidgets('malformed target record is preserved without a native write', (
    tester,
  ) async {
    const raw = '{"a1":["corrupt"],"future":{"opaque":true}}';
    final platform = await _initializeNativeStorage(
      tester,
      originalPlatform: originalPlatform,
      extraInitial: {'kl_gram_plan_v1': raw},
      loadGrammar: false,
    );
    final operation = GrammarPlanWriteOperation.start(
      plan: const GrammarStudyPlan(
        level: 'a1',
        itemsPerDay: 5,
        servedIdsByDate: {},
      ),
    );

    await expectLater(
      operation.save(),
      throwsA(isA<GrammarPlanRecoveryValueException>()),
    );

    expect(platform.values['kl_gram_plan_v1'], raw);
    expect(platform.writes['kl_gram_plan_v1'], isNull);
  });

  testWidgets(
    'semantic update preserves target and other-level unknown fields',
    (tester) async {
      const raw =
          '{"a1":{"level":"a1","itemsPerDay":5,'
          '"servedIdsByDate":{},"futureMarker":{"v":2}},'
          '"b1":{"opaque":[1,2,3]}}';
      final platform = await _initializeNativeStorage(
        tester,
        originalPlatform: originalPlatform,
        extraInitial: {'kl_gram_plan_v1': raw},
        loadGrammar: false,
      );
      final operation = GrammarPlanWriteOperation.start(
        plan: const GrammarStudyPlan(
          level: 'a1',
          itemsPerDay: 3,
          servedIdsByDate: {},
        ),
      );

      await operation.save();

      final decoded = jsonDecode(Storage.grammarPlanRawJson) as Map;
      expect((decoded['a1'] as Map)['futureMarker'], {'v': 2});
      expect(decoded['b1'], {
        'opaque': [1, 2, 3],
      });
      expect((decoded['a1'] as Map)['itemsPerDay'], 3);
      expect(platform.writes['kl_gram_plan_v1'], 1);
    },
  );

  testWidgets('reset drains an admitted plan write and stops its later leg', (
    tester,
  ) async {
    final platform = await _initializeNativeStorage(
      tester,
      originalPlatform: originalPlatform,
      loadGrammar: false,
    );
    platform.enqueue('kl_gram_plan_v1', _NativeWriteOutcome.delayedSuccess);
    final operation = GrammarPlanWriteOperation.start(
      plan: const GrammarStudyPlan(
        level: 'a1',
        itemsPerDay: 5,
        servedIdsByDate: {},
      ),
    );
    final save = operation.save();
    await tester.pump();
    await platform.writeStarted['kl_gram_plan_v1']!.future;
    addTearDown(() {
      final release = platform.releaseWrite['kl_gram_plan_v1'];
      if (release != null && !release.isCompleted) {
        release.complete();
      }
    });

    final reset = Storage.resetAll();
    platform.releaseWrite['kl_gram_plan_v1']!.complete();

    await expectLater(save, throwsA(isA<StaleLocalDataLifetimeException>()));
    await reset;
    expect(platform.values.containsKey('kl_gram_plan_v1'), isFalse);
    expect(
      platform.writes[Storage.grammarPlanLevelPreferenceKey],
      isNull,
      reason: 'Reset admission prevents the selected-level second leg.',
    );
  });

  testWidgets('dismissed onboarding reopens with the retained pending intent', (
    tester,
  ) async {
    final platform = await _initializeNativeStorage(
      tester,
      originalPlatform: originalPlatform,
    );
    platform.enqueue('kl_gram_plan_v1', _NativeWriteOutcome.delayedSuccess);
    await _pumpGrammar(tester);
    await tester.tap(find.byKey(const Key('grammar-plan-items-3')));
    await tester.pump();
    _tapStart(tester);
    await tester.pump();
    await platform.writeStarted['kl_gram_plan_v1']!.future;
    addTearDown(() {
      final release = platform.releaseWrite['kl_gram_plan_v1'];
      if (release != null && !release.isCompleted) {
        release.complete();
      }
    });
    expect(find.byKey(const Key('grammar-plan-save-pending')), findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await _boundedPump(tester);
    expect(
      find.byKey(const Key('grammar-plan-onboarding-sheet')),
      findsNothing,
    );
    await tester.tap(find.byIcon(Icons.filter_list_rounded));
    await _boundedPump(tester);
    expect(
      find.byKey(const Key('grammar-plan-onboarding-sheet')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('grammar-plan-save-pending')), findsOneWidget);

    platform.releaseWrite['kl_gram_plan_v1']!.complete();
    await _boundedPump(tester);

    expect(
      find.byKey(const Key('grammar-plan-onboarding-sheet')),
      findsNothing,
    );
    expect(find.byKey(const Key('grammar-plan-day-header')), findsOneWidget);
    expect(
      GrammarPlanService.decodePlans(
        Storage.grammarPlanRawJson,
      )['a1']?.itemsPerDay,
      3,
    );
  });

  testWidgets('real parent pop retires a start before its selected-level leg', (
    tester,
  ) async {
    final platform = await _initializeNativeStorage(
      tester,
      originalPlatform: originalPlatform,
    );
    platform.enqueue('kl_gram_plan_v1', _NativeWriteOutcome.delayedSuccess);
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: SoriButton.filled(
              key: const Key('open-grammar'),
              label: 'Open',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const GrammarScreen(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-grammar')));
    await _boundedPump(tester);
    _tapStart(tester);
    await tester.pump();
    await platform.writeStarted['kl_gram_plan_v1']!.future;
    addTearDown(() {
      final release = platform.releaseWrite['kl_gram_plan_v1'];
      if (release != null && !release.isCompleted) {
        release.complete();
      }
    });

    for (
      var attempt = 0;
      attempt < 4 && find.byType(GrammarScreen).evaluate().isNotEmpty;
      attempt++
    ) {
      await tester.binding.handlePopRoute();
      await _boundedPump(tester);
    }
    expect(find.byType(GrammarScreen), findsNothing);
    platform.releaseWrite['kl_gram_plan_v1']!.complete();
    await _boundedPump(tester);

    expect(find.byKey(const Key('open-grammar')), findsOneWidget);
    expect(platform.values.containsKey('kl_gram_plan_v1'), isTrue);
    expect(
      platform.values.containsKey(Storage.grammarPlanLevelPreferenceKey),
      isFalse,
    );
    expect(Storage.grammarPlanRawJson, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'captured chooser callback cannot admit after source replacement',
    (tester) async {
      final platform = await _initializeNativeStorage(
        tester,
        originalPlatform: originalPlatform,
      );
      var courseMode = false;
      late StateSetter setHostState;
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              return GrammarScreen(
                courseContext: courseMode
                    ? const CoursePracticeContext(
                        courseUnitId: 'replacement-unit',
                        contentKind: CurriculumContentKind.grammar,
                        initialContentId: 'replacement-content',
                        contentLinkId: 'replacement-link',
                      )
                    : null,
              );
            },
          ),
        ),
      );
      await _boundedPump(tester);
      final capturedStart = tester
          .widget<SoriButton>(
            find.widgetWithText(
              SoriButton,
              lookupAppL10n(const Locale('en')).grammarPlanStartCta,
            ),
          )
          .onTap!;

      setHostState(() => courseMode = true);
      await tester.pump();
      capturedStart();
      await _boundedPump(tester);

      expect(platform.writes['kl_gram_plan_v1'], isNull);
      expect(platform.writes[Storage.grammarPlanLevelPreferenceKey], isNull);
    },
  );

  testWidgets(
    'review regression: restore skips the durable plan without publishing an optimistic unknown',
    (tester) async {
      final platform = await _initializeNativeStorage(
        tester,
        originalPlatform: originalPlatform,
        loadGrammar: false,
      );
      platform.enqueue(
        'kl_gram_plan_v1',
        _NativeWriteOutcome.throwUncommittedReloadUnavailable,
      );
      final operation = GrammarPlanWriteOperation.start(
        plan: const GrammarStudyPlan(
          level: 'a1',
          itemsPerDay: 3,
          servedIdsByDate: {},
        ),
      );

      await expectLater(
        operation.save(),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );
      expect(platform.writes['kl_gram_plan_v1'], 1);
      expect(platform.values.containsKey('kl_gram_plan_v1'), isFalse);
      expect(
        platform.writes[Storage.grammarPlanLevelPreferenceKey],
        isNull,
        reason: 'An unknown first leg cannot admit the selected-level leg.',
      );
      expect(Storage.grammarPlanRawJson, isEmpty);
      expect(Storage.grammarPlanLevel, isNull);

      const durableRaw =
          '{"b1":{"level":"b1","itemsPerDay":7,'
          '"servedIdsByDate":{}}}';
      platform.reloadUnavailable = false;
      platform.values['kl_gram_plan_v1'] = durableRaw;
      final result = await Storage.setGrammarPlanRawJsonForRestore(
        '{"a2":{"level":"a2","itemsPerDay":5,'
        '"servedIdsByDate":{}}}',
      );

      expect(result, GrammarPlanRestoreResult.skippedExisting);
      expect(platform.writes['kl_gram_plan_v1'], 1);
      expect(platform.values['kl_gram_plan_v1'], durableRaw);
      expect(
        Storage.grammarPlanRawJson,
        durableRaw,
        reason: 'Only the reloaded durable value may enter the confirmed view.',
      );
      expect(Storage.grammarPlanLevel, isNull);
    },
  );

  testWidgets(
    'review regression: restore cannot publish a partial two-leg plan start',
    (tester) async {
      final platform = await _initializeNativeStorage(
        tester,
        originalPlatform: originalPlatform,
        loadGrammar: false,
      );
      platform.enqueue(
        'kl_gram_plan_v1',
        _NativeWriteOutcome.throwCommittedReloadUnavailable,
      );
      final operation = GrammarPlanWriteOperation.start(
        plan: const GrammarStudyPlan(
          level: 'a1',
          itemsPerDay: 3,
          servedIdsByDate: {},
        ),
      );

      await expectLater(
        operation.save(),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );
      expect(platform.writes['kl_gram_plan_v1'], 1);
      expect(platform.writes[Storage.grammarPlanLevelPreferenceKey], isNull);
      expect(platform.values.containsKey('kl_gram_plan_v1'), isTrue);
      expect(
        platform.values.containsKey(Storage.grammarPlanLevelPreferenceKey),
        isFalse,
      );
      expect(Storage.grammarPlanRawJson, isEmpty);
      expect(Storage.grammarPlanLevel, isNull);
      platform.reloadUnavailable = false;

      final result = await Storage.setGrammarPlanRawJsonForRestore(
        '{"b1":{"level":"b1","itemsPerDay":7,'
        '"servedIdsByDate":{}}}',
      );

      expect(result, GrammarPlanRestoreResult.skippedExisting);
      expect(platform.writes['kl_gram_plan_v1'], 1);
      expect(
        Storage.grammarPlanRawJson,
        isEmpty,
        reason: 'A first leg is not authoritative without its selected level.',
      );
      expect(Storage.grammarPlanLevel, isNull);
    },
  );

  testWidgets(
    'review regression: chooser retained across a completed reset cannot admit a fresh plan',
    (tester) async {
      final platform = await _initializeNativeStorage(
        tester,
        originalPlatform: originalPlatform,
      );
      await _pumpGrammar(tester);
      final capturedStart = tester
          .widget<SoriButton>(
            find.widgetWithText(
              SoriButton,
              lookupAppL10n(const Locale('en')).grammarPlanStartCta,
            ),
          )
          .onTap!;

      await Storage.resetAll();
      expect(
        platform.values.keys.where((key) => key.startsWith('kl_')),
        isEmpty,
      );
      capturedStart();
      await _boundedPump(tester);

      expect(platform.writes['kl_gram_plan_v1'], isNull);
      expect(platform.writes[Storage.grammarPlanLevelPreferenceKey], isNull);
      expect(platform.values.containsKey('kl_gram_plan_v1'), isFalse);
      expect(Storage.grammarPlanRawJson, isEmpty);
    },
  );

  testWidgets(
    'review regression: browse all retires a dismissed delayed completion',
    (tester) async {
      final platform = await _initializeNativeStorage(
        tester,
        originalPlatform: originalPlatform,
      );
      await _pumpGrammar(tester);
      await tester.tap(find.byKey(const Key('grammar-plan-items-3')));
      await tester.pump();
      _tapStart(tester);
      await _boundedPump(tester);
      final originalRaw = Storage.grammarPlanRawJson;
      platform.enqueue('kl_gram_plan_v1', _NativeWriteOutcome.delayedSuccess);

      final feed = tester.widget<SoriContentFeed>(find.byType(SoriContentFeed));
      feed.onSkip!();
      await tester.pump();
      feed.onSkip!();
      await tester.pump();
      feed.onSkip!();
      await tester.pump();
      await platform.writeStarted['kl_gram_plan_v1']!.future;
      addTearDown(() {
        final release = platform.releaseWrite['kl_gram_plan_v1'];
        if (release != null && !release.isCompleted) {
          release.complete();
        }
      });
      expect(
        find.byKey(const Key('grammar-plan-save-pending')),
        findsOneWidget,
      );

      tester
          .widget<SoriButton>(
            find.widgetWithText(
              SoriButton,
              lookupAppL10n(const Locale('en')).btnClose,
            ),
          )
          .onTap!();
      await _boundedPump(tester);
      tester
          .widget<SoriButton>(
            find.byKey(const Key('grammar-browse-all-button')),
          )
          .onTap!();
      await tester.pump();
      platform.releaseWrite['kl_gram_plan_v1']!.complete();
      await _boundedPump(tester);

      expect(platform.writes['kl_gram_plan_v1'], 2);
      expect(
        GrammarPlanService.decodePlans(
          platform.values['kl_gram_plan_v1']! as String,
        )['a1']?.servedIdsByDate,
        isNotEmpty,
        reason: 'The already-issued native call is allowed to finish.',
      );
      expect(
        Storage.grammarPlanRawJson,
        originalRaw,
        reason: 'The retired completion cannot publish into browse-all state.',
      );
      expect(
        find.byKey(const Key('grammar-plan-completion-sheet')),
        findsNothing,
      );
      expect(find.byKey(const Key('grammar-plan-day-complete')), findsNothing);
    },
  );

  testWidgets(
    'review regression: parent pop retires before a delayed first leg resumes',
    (tester) async {
      final platform = await _initializeNativeStorage(
        tester,
        originalPlatform: originalPlatform,
      );
      platform.enqueue('kl_gram_plan_v1', _NativeWriteOutcome.delayedSuccess);
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: SoriButton.filled(
                key: const Key('open-grammar-review-pop'),
                label: 'Open',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const GrammarScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open-grammar-review-pop')));
      await _boundedPump(tester);
      _tapStart(tester);
      await tester.pump();
      await platform.writeStarted['kl_gram_plan_v1']!.future;
      addTearDown(() {
        final release = platform.releaseWrite['kl_gram_plan_v1'];
        if (release != null && !release.isCompleted) {
          release.complete();
        }
      });

      await tester.tapAt(const Offset(8, 8));
      await _boundedPump(tester);
      final grammarContext = tester.element(find.byType(GrammarScreen));
      Navigator.of(grammarContext).pop();
      expect(find.byType(GrammarScreen), findsOneWidget);
      platform.releaseWrite['kl_gram_plan_v1']!.complete();
      await tester.pump();

      expect(platform.writes['kl_gram_plan_v1'], 1);
      expect(platform.values.containsKey('kl_gram_plan_v1'), isTrue);
      expect(
        platform.writes[Storage.grammarPlanLevelPreferenceKey],
        isNull,
        reason: 'A reversing parent route must stop the second native leg.',
      );
      await _boundedPump(tester);
      expect(find.byKey(const Key('open-grammar-review-pop')), findsOneWidget);
    },
  );

  testWidgets(
    'review regression: retry payload is frozen against caller and exposed plan mutation',
    (tester) async {
      final platform = await _initializeNativeStorage(
        tester,
        originalPlatform: originalPlatform,
        loadGrammar: false,
      );
      final callerIds = <String>['grammar-original'];
      final callerServed = <String, List<String>>{'2026-09-10': callerIds};
      final operation = GrammarPlanWriteOperation.completeDay(
        plan: GrammarStudyPlan(
          level: 'a1',
          itemsPerDay: 3,
          servedIdsByDate: callerServed,
        ),
      );
      platform.enqueue(
        'kl_gram_plan_v1',
        _NativeWriteOutcome.throwUncommittedReloadUnavailable,
      );

      await expectLater(
        operation.save(),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );
      expect(platform.writes['kl_gram_plan_v1'], 1);
      expect(platform.values.containsKey('kl_gram_plan_v1'), isFalse);
      callerIds.add('grammar-caller-mutation');
      callerServed['2026-09-11'] = <String>['grammar-map-mutation'];
      try {
        operation.plan.servedIdsByDate['2026-09-10']!.add(
          'grammar-operation-mutation',
        );
      } on UnsupportedError {
        // A repaired operation exposes an immutable nested semantic snapshot.
      }
      platform.reloadUnavailable = false;

      await operation.save();

      expect(platform.writes['kl_gram_plan_v1'], 2);
      final stored = GrammarPlanService.decodePlans(
        platform.values['kl_gram_plan_v1']! as String,
      )['a1']!;
      expect(stored.servedIdsByDate, {
        '2026-09-10': ['grammar-original'],
      });
      expect(operation.plan.servedIdsByDate, {
        '2026-09-10': ['grammar-original'],
      });
    },
  );
}

Future<_NativeGrammarPlatform> _initializeNativeStorage(
  WidgetTester tester, {
  required SharedPreferencesStorePlatform originalPlatform,
  Map<String, Object> extraInitial = const {},
  bool loadGrammar = true,
}) async {
  Storage.resetForTesting();
  SharedPreferences.setMockInitialValues({});
  final platform = _NativeGrammarPlatform({
    'kl_user_level': 'a1',
    'kl_tut_grammar': true,
    'kl_tut_soriDeck': true,
    ...extraInitial,
  });
  SharedPreferencesStorePlatform.instance = platform;
  await Storage.init();
  DataLoader.reset();
  CurriculumCatalog.reset();
  if (loadGrammar) {
    await tester.runAsync(DataLoader.loadGrammar);
  }
  return platform;
}

Future<void> _pumpGrammar(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: const GrammarScreen(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _boundedPump(WidgetTester tester) async {
  for (var index = 0; index < 8; index++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void _tapStart(WidgetTester tester) {
  final l10n = lookupAppL10n(const Locale('en'));
  tester
      .widget<SoriButton>(
        find.widgetWithText(SoriButton, l10n.grammarPlanStartCta),
      )
      .onTap!();
}
