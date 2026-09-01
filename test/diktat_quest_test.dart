import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/quest_engines/diktat_quest.dart';
import 'package:ko_lernen_app/screens/quest_engines/quest_models.dart';
import 'package:ko_lernen_app/theme.dart';

import 'support/scenario_json.dart';

/// Tests für die produktive "Diktat"-Quest (Hör + Schreib):
/// - reine Vergleichslogik (normalize / isExact / isSpacingOnly)
/// - Daten-Integrität der geseedeten Szenarien
void main() {
  group('DiktatQuest.normalize', () {
    test('trimmt, kollabiert Leerraum, entfernt Endzeichen', () {
      expect(DiktatQuest.normalize('  강남역까지   가주세요.  '), '강남역까지 가주세요');
    });
  });

  group('DiktatQuest.isExact', () {
    const target = '강남역까지 가주세요.';

    test('identisch (mit/ohne Punkt) → true', () {
      expect(DiktatQuest.isExact('강남역까지 가주세요', target), isTrue);
      expect(DiktatQuest.isExact('강남역까지 가주세요.', target), isTrue);
    });

    test('falscher Inhalt → false', () {
      expect(DiktatQuest.isExact('강남역까지 가요', target), isFalse);
    });

    test('fehlendes Leerzeichen ist NICHT exakt', () {
      expect(DiktatQuest.isExact('강남역까지가주세요', target), isFalse);
    });
  });

  group('DiktatQuest.isSpacingOnly', () {
    const target = '강남역까지 가주세요.';

    test('nur Wortabstand falsch → true', () {
      expect(DiktatQuest.isSpacingOnly('강남역까지가주세요', target), isTrue);
      expect(DiktatQuest.isSpacingOnly('강남역 까지 가주세요', target), isTrue);
    });

    test('exakt → false (kein Spacing-Hinweis)', () {
      expect(DiktatQuest.isSpacingOnly('강남역까지 가주세요', target), isFalse);
    });

    test('inhaltlich falsch → false', () {
      expect(DiktatQuest.isSpacingOnly('강남역까지 가요', target), isFalse);
    });

    test('leere Eingabe → false', () {
      expect(DiktatQuest.isSpacingOnly('', target), isFalse);
    });
  });

  group('DiktatQuest.decomposeJamo', () {
    test('Silbe ohne Endkonsonant → 2 Jamo, mit → 3', () {
      expect(DiktatQuest.decomposeJamo('가'), hasLength(2)); // ㄱ+ㅏ
      expect(DiktatQuest.decomposeJamo('각'), hasLength(3)); // ㄱ+ㅏ+ㄱ
    });
    test('Nicht-Silben-Zeichen bleibt ein Element', () {
      expect(DiktatQuest.decomposeJamo('A'), hasLength(1));
    });
  });

  group('DiktatQuest.jamoEditDistance', () {
    test('identisch → 0', () {
      expect(DiktatQuest.jamoEditDistance('가주세요', '가주세요'), 0);
    });
    test('ein Jamo-Unterschied → 1', () {
      expect(DiktatQuest.jamoEditDistance('가', '카'), 1); // ㄱ↔ㅋ
      expect(DiktatQuest.jamoEditDistance('있어요', '잇어요'), 1); // ㅆ↔ㅅ
    });
    test('völlig anders → > 2', () {
      expect(DiktatQuest.jamoEditDistance('안녕', '강남역까지'), greaterThan(2));
    });
  });

  group('DiktatQuest.diagnose', () {
    const target = '강남역까지 가주세요';

    test('nur Wortabstand → spacing', () {
      expect(DiktatQuest.diagnose('강남역까지가주세요', target), DiktatError.spacing);
    });

    test('Rechtschreib-Nähe (1 Jamo) → spelling', () {
      expect(DiktatQuest.diagnose('강남역까지 가조세요', target), DiktatError.spelling);
    });

    test('klar daneben → wrong', () {
      expect(DiktatQuest.diagnose('안녕하세요', target), DiktatError.wrong);
    });
  });

  group('DiktatQuest accepted targets', () {
    const canonical = '지금 바로 답드리기보다는, 내용을 조금 정리해서 다시 말씀드릴게요.';
    const spacingAndPunctuationVariant = '지금 바로 답드리기 보다는 내용을 조금 정리해서 다시 말씀드릴게요';
    const semanticParaphrase = '조금 생각해 보고 나중에 연락드릴게요.';
    const targets = [canonical, spacingAndPunctuationVariant];

    test('accepts the canonical and explicitly declared surface variants', () {
      expect(DiktatQuest.isAccepted(canonical, targets), isTrue);
      expect(
        DiktatQuest.isAccepted(spacingAndPunctuationVariant, targets),
        isTrue,
      );
    });

    test('does not accept an undeclared semantic paraphrase', () {
      expect(DiktatQuest.isAccepted(semanticParaphrase, targets), isFalse);
    });

    test('diagnoses against the closest accepted target', () {
      expect(
        DiktatQuest.diagnoseAgainstAccepted(
          '지금 바로 답드리기 보다는 내용을 조금 정리해서 다시 말씀드릴께요',
          targets,
        ),
        DiktatError.spelling,
      );
    });

    test('legacy single-target helpers keep their behavior', () {
      expect(DiktatQuest.isExact('안녕하세요!', '안녕하세요.'), isTrue);
      expect(DiktatQuest.diagnose('안녕 하세요', '안녕하세요'), DiktatError.spacing);
    });
  });

  group('DiktatQuest canonical Korean review', () {
    const reviewKey = ValueKey('diktat-korean-review');
    const target = '안녕 하세요.';

    for (final passed in const [true, false]) {
      testWidgets('targetKo stays hidden before judgment and appears after '
          '${passed ? 'success' : 'the second miss'}', (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          final results = <QuestResult>[];
          await tester.pumpWidget(
            _host(
              DiktatQuest(
                data: const {
                  'targetKo': target,
                  'audioKo': target,
                  'promptDe': 'Hallo.',
                  'promptEn': 'Hello.',
                },
                onComplete: results.add,
              ),
            ),
          );
          await tester.pump();

          expect(find.byKey(reviewKey), findsNothing);
          expect(find.bySemanticsLabel(target), findsNothing);

          await tester.enterText(
            find.byKey(const ValueKey('diktat-answer-field')),
            passed ? target : '틀린 답',
          );
          await tester.pump();
          await tester.tap(find.byKey(const ValueKey('quest-submit')));
          await tester.pump();
          if (!passed) {
            expect(find.byKey(reviewKey), findsNothing);
            await tester.tap(find.byKey(const ValueKey('quest-submit')));
            await tester.pump();
          }

          final review = find.byKey(reviewKey);
          expect(review, findsOneWidget);
          expect(
            find.descendant(of: review, matching: find.text(target)),
            findsOneWidget,
          );
          expect(tester.getSemantics(review).getSemanticsData().label, target);
          expect(results, hasLength(1));
          expect(results.single.passed, passed);
        } finally {
          semantics.dispose();
        }
      });
    }

    for (final data in const <Map<String, dynamic>>[
      {},
      {'targetKo': '   '},
    ]) {
      testWidgets(
        'null or empty targetKo never creates a review block: $data',
        (tester) async {
          await tester.pumpWidget(
            _host(
              DiktatQuest(data: data, onComplete: (_) {}, allowDontKnow: true),
            ),
          );
          await tester.pump();

          expect(find.byKey(reviewKey), findsNothing);
          await tester.tap(find.byKey(const ValueKey('quest-dont-know')));
          await tester.pump();
          expect(find.byKey(reviewKey), findsNothing);
          await tester.pump(const Duration(milliseconds: 250));
        },
      );
    }
  });

  group('canonical 120 core — Diktat remains an engine, not a seed', () {
    const themeParkScenarioIds = {
      'a1_theme_park_date_choices',
      'a2_theme_park_date_break',
      'b1_theme_park_date_thrill',
      'b2_theme_park_date_safety',
      'c1_theme_park_date_next_time',
      'c2_theme_park_date_reflection',
    };

    late List<Map<String, dynamic>> coreDiktatQuests;
    late List<Map<String, dynamic>> themeParkDiktatQuests;
    late List<Scenario> scenarios;
    late List<Scenario> coreScenarios;
    late List<Scenario> themeParkScenarios;

    setUpAll(() {
      final root = allScenarioRoot();
      final list = (root['scenarios'] as List).cast<Map<String, dynamic>>();
      scenarios = list.map(Scenario.fromJson).toList();
      coreScenarios = scenarios
          .where((scenario) => !themeParkScenarioIds.contains(scenario.id))
          .toList();
      themeParkScenarios = scenarios
          .where((scenario) => themeParkScenarioIds.contains(scenario.id))
          .toList();
      coreDiktatQuests = [
        for (final sc in list)
          if (!themeParkScenarioIds.contains(sc['id']))
            for (final q in (sc['quests'] as List? ?? const []))
              if ((q as Map<String, dynamic>)['type'] == 'diktat') q,
      ];
      themeParkDiktatQuests = [
        for (final sc in list)
          if (themeParkScenarioIds.contains(sc['id']))
            for (final q in (sc['quests'] as List? ?? const []))
              if ((q as Map<String, dynamic>)['type'] == 'diktat') q,
      ];
    });

    test('the 120-scene core contains no legacy Diktat seed', () {
      expect(scenarios, hasLength(126));
      expect(coreScenarios, hasLength(120));
      expect(themeParkScenarios, hasLength(6));
      expect(coreDiktatQuests, isEmpty);
      expect(
        coreScenarios
            .expand((scenario) => scenario.quests)
            .where((quest) => quest.type == QuestType.satzBauen),
        hasLength(120),
      );
    });

    test(
      'the reviewed theme-park supplement keeps one valid Diktat per level',
      () {
        expect(themeParkDiktatQuests, hasLength(6));
        for (final q in themeParkDiktatQuests) {
          final data = q['data'] as Map<String, dynamic>;
          expect((data['targetKo'] as String? ?? '').trim(), isNotEmpty);
          expect((data['promptDe'] as String? ?? '').trim(), isNotEmpty);
          expect((data['promptEn'] as String? ?? '').trim(), isNotEmpty);
        }
      },
    );

    test('only the six reviewed supplement scenarios parse a Diktat seed', () {
      var found = 0;
      for (final sc in scenarios) {
        for (final q in sc.quests) {
          if (q.type == QuestType.diktat) {
            found++;
            expect(themeParkScenarioIds, contains(sc.id));
            final keys = q.targetVocabKeys();
            expect(keys, hasLength(1));
            expect(keys.first.trim(), isNotEmpty);
          }
        }
      }
      expect(found, 6);
    });
  });
}

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, app) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(disableAnimations: true),
      child: app!,
    );
  },
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);
