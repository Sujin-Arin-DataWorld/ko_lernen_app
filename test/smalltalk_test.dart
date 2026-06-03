import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/personalized_lesson_service.dart';
import 'package:ko_lernen_app/services/smalltalk_loader.dart';

/// Beweist, dass der Small-talk-Korpus tatsächlich im Code geladen & genutzt
/// wird (nicht "dormant"): lädt die echte assets/data/smalltalk.json über den
/// produktiven Loader und prüft Struktur + Personalisierungs-Pfad.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(SmalltalkLoader.reset);

  test('smalltalk.json wird über den Loader geladen (echtes Asset)', () async {
    await SmalltalkLoader.load();
    expect(SmalltalkLoader.lastError, isNull);
    expect(SmalltalkLoader.categories.length, greaterThanOrEqualTo(12));
    expect(SmalltalkLoader.phrases.length, greaterThanOrEqualTo(100));
  });

  test('jede Frage hat eine Beispielantwort (Catch-ball)', () async {
    await SmalltalkLoader.load();
    final qs = SmalltalkLoader.phrases.where((p) => p.kind == 'question');
    expect(qs, isNotEmpty);
    expect(qs.every((p) => p.reply != null), isTrue);
  });

  test('jede Phrase: ko/de/en gefüllt, gültiges Level + bekannte Kategorie',
      () async {
    await SmalltalkLoader.load();
    final catIds = SmalltalkLoader.categories.map((c) => c.id).toSet();
    const levels = {'a1', 'a2', 'b1', 'b2'};
    for (final p in SmalltalkLoader.phrases) {
      expect(p.ko.isNotEmpty && p.de.isNotEmpty && p.en.isNotEmpty, isTrue,
          reason: 'leeres Feld bei "${p.ko}"');
      expect(levels.contains(p.level), isTrue, reason: 'Level "${p.ko}"');
      expect(catIds.contains(p.category), isTrue, reason: 'Kategorie "${p.ko}"');
    }
  });

  test('filter(category, level) liefert nur passende Phrasen', () async {
    await SmalltalkLoader.load();
    final r = SmalltalkLoader.filter(category: 'travel', level: 'a2');
    expect(r, isNotEmpty);
    expect(r.every((p) => p.category == 'travel' && p.level == 'a2'), isTrue);
  });

  test('Personalisierung nutzt den Korpus: travel-Interesse → travel zuerst',
      () async {
    await SmalltalkLoader.load();
    final got = PersonalizedLessonService.pickSmalltalk(
      SmalltalkLoader.phrases,
      levelCode: 'b2',
      interests: {'travel'},
      count: 3,
    );
    expect(got, isNotEmpty);
    expect(got.first.category, 'travel');
  });
}
