import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';

/// Regression: Eine fehlerhafte Szenario-Definition (z.B. culturalNote im
/// falschen Schema) darf NICHT die ganze Szenarienliste leeren.
/// Genau das war der Bug: 12 neue Szenarien hatten culturalNote als
/// {ko,de,en} statt {title,body} → CulturalNote.fromJson warf → die ganze
/// Liste war leer → der Szenarien-Hub blieb dunkel.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Scenario.fromJson Robustheit', () {
    test('kaputte culturalNote ({ko,de,en}) wirft nicht → null', () {
      final s = Scenario.fromJson({
        'id': 'broken',
        'level': 'a2',
        'title': {'ko': '가', 'de': 'g', 'en': 'g'},
        'intro': {'ko': '', 'de': 'x', 'en': 'x'},
        'culturalNote': {'ko': '', 'de': 'nur body', 'en': 'just body'},
      });
      expect(s.id, 'broken');
      expect(s.culturalNote, isNull);
    });

    test('gültige culturalNote ({title,body}) wird geparst', () {
      final s = Scenario.fromJson({
        'id': 'ok',
        'level': 'a1',
        'title': {'ko': '가', 'de': 'g', 'en': 'g'},
        'intro': {'ko': '', 'de': 'x', 'en': 'x'},
        'culturalNote': {
          'title': {'ko': '제목', 'de': 'Titel', 'en': 'Title'},
          'body': {'ko': '본문', 'de': 'Text', 'en': 'Body'},
        },
      });
      expect(s.culturalNote, isNotNull);
      expect(s.culturalNote!.title.de, 'Titel');
      expect(s.culturalNote!.body.en, 'Body');
    });

    test('fehlender title wirft nicht (leerer LocalizedText)', () {
      final s = Scenario.fromJson({'id': 'notitle', 'level': 'a1'});
      expect(s.id, 'notitle');
      expect(s.title.de, '');
    });
  });

  test(
    'ScenarioLoader lädt das echte Asset ohne Fehler (alle Szenarien)',
    () async {
      ScenarioLoader.reset();
      final list = await ScenarioLoader.load();
      expect(ScenarioLoader.lastError, isNull);
      // 33 im Asset; >=30 als robuste Untergrenze.
      expect(list.length, greaterThanOrEqualTo(30));
      // Die zuvor kaputten Szenarien laden jetzt + haben ihre Notiz.
      final subway = list.where((s) => s.id == 'subway_directions');
      expect(subway, isNotEmpty);
      expect(subway.first.culturalNote, isNotNull);
    },
  );
}
