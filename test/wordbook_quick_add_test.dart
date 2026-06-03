import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

/// Beweist den globalen "Zur Wortliste hinzufügen"-Kern (v2.0):
/// find-or-create des Schnellspeicher-Packs + Dedupe per koreanischem String.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
  });

  ExtractedWord w(String ko, String de) =>
      ExtractedWord.manual(korean: ko, translationDe: de);

  test('quickAdd legt Schnellspeicher an und fügt das Wort hinzu', () async {
    final r = await CustomPackService.quickAdd(
        defaultPackName: '⭐ Schnellspeicher', word: w('사과', 'Apfel'));
    expect(r, WordbookAddResult.added);

    final pack = CustomPackService.getById(CustomPackService.quickPackId);
    expect(pack, isNotNull);
    expect(pack!.name, '⭐ Schnellspeicher');
    expect(pack.words.single.korean, '사과');
    expect(pack.isManual, isTrue);
  });

  test('gleiches Wort zweimal → alreadyExists (kein Duplikat)', () async {
    await CustomPackService.quickAdd(defaultPackName: '⭐', word: w('사과', 'Apfel'));
    final r2 = await CustomPackService.quickAdd(
        defaultPackName: '⭐', word: w('사과', 'Apfel'));
    expect(r2, WordbookAddResult.alreadyExists);
    expect(
      CustomPackService.getById(CustomPackService.quickPackId)!.words.length,
      1,
    );
  });

  test('mehrere verschiedene Wörter landen im selben Pack', () async {
    await CustomPackService.quickAdd(defaultPackName: '⭐', word: w('사과', 'Apfel'));
    await CustomPackService.quickAdd(defaultPackName: '⭐', word: w('물', 'Wasser'));
    await CustomPackService.quickAdd(defaultPackName: '⭐', word: w('책', 'Buch'));
    expect(
      CustomPackService.getById(CustomPackService.quickPackId)!.words.length,
      3,
    );
  });

  test('leeres koreanisches Wort → failed', () async {
    final r = await CustomPackService.quickAdd(
        defaultPackName: '⭐', word: w('   ', 'x'));
    expect(r, WordbookAddResult.failed);
  });
}
