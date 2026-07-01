import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/services/culture_notes_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    CultureNotesService.resetForTesting();
  });

  test('culture_notes.json 로드 + 필드 무결성', () async {
    await CultureNotesService.load();
    final all = CultureNotesService.all;
    expect(all.isNotEmpty, isTrue);
    const kinds = {'kpop', 'drama', 'culture', 'film'};
    for (final n in all.values) {
      expect(n.ko.trim(), isNotEmpty);
      expect(n.de.trim(), isNotEmpty, reason: '${n.ko} DE 비어있음');
      expect(n.en.trim(), isNotEmpty, reason: '${n.ko} EN 비어있음');
      expect(
        kinds.contains(n.kind),
        isTrue,
        reason: '${n.ko} 잘못된 kind ${n.kind}',
      );
    }
  });

  test('noteFor 조회 + text(lang) 폴백', () async {
    await CultureNotesService.load();
    final note = CultureNotesService.noteFor('화이팅');
    expect(note, isNotNull);
    expect(note!.text('en'), note.en);
    expect(note.text('de'), note.de);
    expect(note.text('xx'), note.de); // 미지원 → 독일어 폴백
    expect(CultureNotesService.noteFor('존재안함단어'), isNull);
  });

  test('모든 시드 ko가 단어장 CSV에 존재(노출 보장)', () async {
    await CultureNotesService.load();
    final csv = await rootBundle.loadString('assets/data/korean_vocab.csv');
    final vocabKo = csv
        .split('\n')
        .skip(1)
        .where((l) => l.trim().isNotEmpty)
        .map((l) => l.split(',').first.trim())
        .toSet();
    for (final n in CultureNotesService.all.values) {
      expect(
        vocabKo.contains(n.ko),
        isTrue,
        reason: '${n.ko} 가 korean_vocab.csv에 없음 → 노출 안 됨',
      );
    }
  });
}
