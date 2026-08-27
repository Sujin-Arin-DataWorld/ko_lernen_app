// Task 5 (2026-08-27 W4 progress review) — CustomPackService.learnedWordCount.
//
// PackProgressService.wordsLearnedIn 과 동일 패턴: 별도 카운터 없이
// vokSeenIds 교집합으로 유도된다는 계약을 고정한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test('learnedWordCount 는 vokSeenIds 교집합으로 유도된다', () async {
    final pack = CustomPack(
      id: 'cp1',
      name: 'Test',
      sourcePageId: 'page1',
      words: [
        ExtractedWord.manual(korean: '안녕', translationDe: 'Hallo'),
        ExtractedWord.manual(korean: '감사', translationDe: 'Danke'),
      ],
      createdAtIso: DateTime.now().toUtc().toIso8601String(),
    );
    expect(CustomPackService.learnedWordCount(pack), 0);
    await Storage.addVokSeen('안녕');
    expect(CustomPackService.learnedWordCount(pack), 1);
  });
}
