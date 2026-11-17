import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/grammar_plan_service.dart';
import 'package:ko_lernen_app/models/grammar_study_plan.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/chrome_row.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'support/sori_speech_stubs.dart';

class _DifficultyPlatform extends SharedPreferencesStorePlatform {
  final values = <String, Object>{
    'flutter.kl_tut_grammar': true,
    'flutter.kl_tut_soriDeck': true,
  };
  bool reject = true;
  Completer<bool>? pending;
  int difficultyWrites = 0;
  @override
  Future<Map<String, Object>> getAll() async => {...values};
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key == 'flutter.kl_gram_hard') {
      difficultyWrites++;
      final accepted = pending == null ? !reject : await pending!.future;
      if (!accepted) return false;
    }
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
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
  late _DifficultyPlatform native;
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    native = _DifficultyPlatform();
    SharedPreferencesStorePlatform.instance = native;
    await Storage.init();
    await DataLoader.loadGrammar();
    stubSoriSpeech();
  });
  tearDown(() {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = originalPlatform;
  });

  testWidgets(
    'rejected judgment retains card and first choice until explicit retry succeeds',
    (tester) async {
      await _pump(tester);
      final position = find.textContaining(RegExp(r'^\d+ / \d+$'));
      final before = tester.widget<Text>(position).data;
      tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onHard!();
      await _settle(tester);
      expect(tester.takeException(), isNull);
      expect(tester.widget<Text>(position).data, before);
      expect(Storage.grammarHard, isEmpty);
      expect(find.byKey(const Key('grammar-judgment-retry')), findsOneWidget);
      native.reject = false;
      // A stale opposite callback cannot change the retained original judgment.
      tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onNext!();
      await _settle(tester);
      expect(Storage.grammarHard, contains('V-고 싶다'));
      expect(tester.widget<Text>(position).data, isNot(before));
      expect(native.difficultyWrites, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'pending judgment rejects duplicate taps and preserves card until confirmation',
    (tester) async {
      native.pending = Completer<bool>();
      await _pump(tester);
      final position = find.textContaining(RegExp(r'^\d+ / \d+$'));
      final before = tester.widget<Text>(position).data;
      final feed = tester.widget<SoriContentFeed>(find.byType(SoriContentFeed));
      feed.onHard!();
      feed.onNext!();
      await _settle(tester);
      expect(tester.widget<Text>(position).data, before);
      expect(native.difficultyWrites, 1);
      native.pending!.complete(true);
      await _settle(tester);
      expect(Storage.grammarHard, contains('V-고 싶다'));
      expect(tester.widget<Text>(position).data, isNot(before));
      expect(native.difficultyWrites, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pending judgment cannot open filters or switch plan to browse', (
    tester,
  ) async {
    await Storage.setGrammarPlanRawJson(
      GrammarPlanService.encodePlans({
        'a1': const GrammarStudyPlan(
          level: 'a1',
          itemsPerDay: 3,
          servedIdsByDate: {},
        ),
      }),
    );
    native.pending = Completer<bool>();
    await _pump(tester, const GrammarScreen());
    final browse = tester.widget<SoriButton>(
      find.byKey(const Key('grammar-browse-all-button')),
    );
    final before = tester
        .widget<Text>(find.textContaining(RegExp(r'^\d+ / \d+$')))
        .data;
    tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onHard!();
    await _settle(tester);
    browse.onTap!();
    await _settle(tester);
    expect(find.byKey(const Key('grammar-plan-day-header')), findsOneWidget);
    expect(
      tester.widget<Text>(find.textContaining(RegExp(r'^\d+ / \d+$'))).data,
      before,
    );
    native.pending!.complete(true);
    await _settle(tester);
    expect(find.byKey(const Key('grammar-judgment-retry')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pending judgment blocks both filter entry points before mutation',
    (tester) async {
      native.pending = Completer<bool>();
      await _pump(tester);
      final chrome = tester.widget<SoriChromeRow>(
        find.byKey(const Key('grammar-filter-row')),
      );
      final filter = tester.widget<IconButton>(
        find.byWidgetPredicate(
          (widget) => widget is IconButton && widget.tooltip == 'Filter',
        ),
      );
      tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onHard!();
      await _settle(tester);
      chrome.onFilterTap!();
      filter.onPressed!();
      await _settle(tester);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('A1 · 55'), findsOneWidget);
      native.pending!.complete(true);
      await _settle(tester);
      expect(find.text('A1 · 55'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'browsing after a rejected judgment retires the old card and desired value',
    (tester) async {
      await Storage.setGrammarPlanRawJson(
        GrammarPlanService.encodePlans({
          'a1': const GrammarStudyPlan(
            level: 'a1',
            itemsPerDay: 3,
            servedIdsByDate: {},
          ),
        }),
      );
      await _pump(tester, const GrammarScreen());
      tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onHard!();
      await _settle(tester);
      expect(find.byKey(const Key('grammar-judgment-retry')), findsOneWidget);
      tester
          .widget<SoriButton>(
            find.byKey(const Key('grammar-browse-all-button')),
          )
          .onTap!();
      await _settle(tester);
      expect(find.byKey(const Key('grammar-judgment-retry')), findsNothing);
      native.reject = false;
      tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onNext!();
      await _settle(tester);
      expect(
        Storage.grammarHard,
        isEmpty,
        reason: 'The new Easy choice cannot inherit the previous Hard intent',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reset retires delayed judgment without advancing or leaving a spinner',
    (tester) async {
      native.pending = Completer<bool>();
      await _pump(tester);
      final before = tester
          .widget<Text>(find.textContaining(RegExp(r'^\d+ / \d+$')))
          .data;
      tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onHard!();
      await _settle(tester);
      LocalDataLifetime.invalidate();
      await tester.pump();
      native.pending!.complete(true);
      await _settle(tester);
      expect(find.byKey(const Key('grammar-judgment-retry')), findsNothing);
      expect(
        tester.widget<Text>(find.textContaining(RegExp(r'^\d+ / \d+$'))).data,
        before,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pump(WidgetTester tester, [Widget? screen]) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: screen ?? const GrammarScreen(initialGrammarId: 'grammar_a1_want'),
    ),
  );
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
