// Phase 5.1 (stately-rising-jongga) — CustomPack + CustomPackService tests.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

BookPage _samplePage({String id = 'src_page_1'}) => BookPage(
  id: id,
  localThumbnailPath: '/tmp/img.jpg',
  extractedText: '한국어 공부 중',
  note: 'Lektion 5',
  words: const [
    ExtractedWord(
      korean: '공부',
      romanization: 'gongbu',
      posDe: 'Nomen',
      translationDe: 'Studium',
      translationEn: 'study',
      exampleKorean: '한국어 공부 중',
      exampleDe: 'Mitten im Koreanisch-Lernen',
      savedToPackId: null,
    ),
    ExtractedWord(
      korean: '학교',
      romanization: 'hakgyo',
      posDe: 'Nomen',
      translationDe: 'Schule',
      translationEn: 'school',
      exampleKorean: '',
      exampleDe: '',
      savedToPackId: null,
    ),
  ],
  grammar: const [],
  sentences: const [],
  capturedAtIso: '2026-05-31T12:00:00Z',
  customPackId: null,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  group('CustomPack model round-trip', () {
    test('toJson / fromJson preserves all fields', () {
      final p = CustomPack.fromBookPage(
        id: 'cp_abc',
        name: 'Lektion 5',
        page: _samplePage(),
        createdAt: DateTime.utc(2026, 5, 31, 12),
      );
      final j = p.toJson();
      final p2 = CustomPack.fromJson('cp_abc', j);
      expect(p2.id, p.id);
      expect(p2.name, p.name);
      expect(p2.sourcePageId, p.sourcePageId);
      expect(p2.words.length, p.words.length);
      expect(p2.words[0].korean, '공부');
      expect(p2.createdAtIso, '2026-05-31T12:00:00.000Z');
    });

    test('displayName falls back to date if name empty', () {
      final p = CustomPack(
        id: 'cp_x',
        name: '',
        sourcePageId: 'p',
        words: const [],
        createdAtIso: '2026-01-15T00:00:00Z',
      );
      expect(p.displayName(), '2026-01-15');
    });

    test('displayName uses name when provided', () {
      final p = CustomPack(
        id: 'cp_x',
        name: '  Schritte  ',
        sourcePageId: 'p',
        words: const [],
        createdAtIso: '2026-01-15T00:00:00Z',
      );
      expect(p.displayName(), '  Schritte  ');
    });

    test('fromJson with missing fields uses safe defaults', () {
      final p = CustomPack.fromJson('cp_e', const <String, dynamic>{});
      expect(p.id, 'cp_e');
      expect(p.name, '');
      expect(p.sourcePageId, '');
      expect(p.words, isEmpty);
      expect(p.createdAtIso, '');
    });
  });

  group('CustomPackService CRUD', () {
    test('createFromPage saves to storage', () async {
      final pack = await CustomPackService.createFromPage(
        page: _samplePage(),
        name: 'Test pack',
      );
      expect(pack.id.startsWith('cp_'), isTrue);
      expect(pack.words.length, 2);

      final fetched = CustomPackService.getById(pack.id);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Test pack');
    });

    test('getAll returns most recent first', () async {
      final p1 = await CustomPackService.createFromPage(
        page: _samplePage(),
        name: 'Older',
      );
      // ensure ordering by capturedAtIso (CustomPack uses createdAt)
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final p2 = await CustomPackService.createFromPage(
        page: _samplePage(),
        name: 'Newer',
      );
      final all = CustomPackService.getAll();
      expect(all.length, 2);
      expect(all.first.id, p2.id);
      expect(all.last.id, p1.id);
    });

    test('delete removes the pack', () async {
      final pack = await CustomPackService.createFromPage(
        page: _samplePage(),
        name: 'Will be gone',
      );
      await CustomPackService.delete(pack.id);
      expect(CustomPackService.getById(pack.id), isNull);
    });

    test('generateId returns unique values + cp_ prefix', () {
      final ids = <String>{};
      for (var i = 0; i < 50; i++) {
        ids.add(CustomPackService.generateId());
      }
      expect(ids.length, 50);
      for (final id in ids) {
        expect(id.startsWith('cp_'), isTrue);
      }
    });
  });
}
