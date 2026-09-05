import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// cloze 절단 어간(dangling stem) 답 전용 래칫 — 지시서 2.8.
//
// 배경: 일부 cloze 정답이 "-하다/-되다" 동사의 어간만 잘려 들어가 있다
// (예: 표제어가 "충돌하다" 인데 answer 가 "충돌하"). 판정 규칙은
// tool/audit_content_naturalness.py 의 check_dangling_stem 을 그대로
// Dart 로 이식한 것이다:
//   answer 를 trim 하고, "하" 또는 "되" 로 끝나며,
//   (answer + "다") 가 korean_vocab.csv 의 "korean" 열(표제어 전체 집합)에
//   존재하면 절단으로 판정한다.
//
// 이 가드는 **데이터를 고치지 않는다** — 히트가 새로 늘지 않게만 막는다.
// 상한은 내려갈 수만 있다. 2026-09-05: tool/fix_dangling_stems.py 로 종전
// 16건 전부 해소(빈칸 뒤 어미를 answer/distractors 로 편입) — 상한 0으로
// 하향. 절대 올리지 마라.

const int knownDanglingStemCap = 0; // 2026-09-05 실측 고정. 내리는 것만 허용.

const Set<String> knownDanglingStemIds = {};

/// tool/audit_content_naturalness.py::check_dangling_stem 의 Dart 이식.
/// 규칙을 벗어난 임의 완화(예: 앞뒤 공백 무시 이상의 정규화)는 하지 않는다.
bool checkDanglingStem(String answer, Set<String> vocabHeadwords) {
  final trimmed = answer.trim();
  if (!(trimmed.endsWith('하') || trimmed.endsWith('되'))) return false;
  return vocabHeadwords.contains('$trimmed다');
}

List<List<String>> parseCsv(String text) {
  final rows = <List<String>>[];
  var field = StringBuffer(), row = <String>[], inQuotes = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(c);
      }
    } else if (c == '"') {
      inQuotes = true;
    } else if (c == ',') {
      row.add(field.toString());
      field = StringBuffer();
    } else if (c == '\n') {
      row.add(field.toString().replaceAll('\r', ''));
      rows.add(row);
      row = <String>[];
      field = StringBuffer();
    } else {
      field.write(c);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}

void main() {
  final cloze =
      jsonDecode(File('assets/data/cloze.json').readAsStringSync())
          as Map<String, dynamic>;
  final items = (cloze['items'] as List).cast<Map<String, dynamic>>();

  final csvRows = parseCsv(
    File('assets/data/korean_vocab.csv').readAsStringSync(),
  );
  final header = csvRows.first;
  final iKorean = header.indexOf('korean');
  final vocabHeadwords = <String>{
    for (final r in csvRows.skip(1))
      if (r.length > iKorean && r[iKorean].trim().isNotEmpty) r[iKorean].trim(),
  };

  test('cloze 절단 어간(dangling stem) 답 — 신규 발생분은 없다, 상한은 내려갈 수만 있다', () {
    final hitIds = <String>[];
    for (final it in items) {
      final id = it['id'] as String;
      final answer = (it['answer'] as String?) ?? '';
      if (checkDanglingStem(answer, vocabHeadwords)) {
        hitIds.add(id);
      }
    }

    final newHits =
        hitIds.where((id) => !knownDanglingStemIds.contains(id)).toList();
    expect(
      newHits,
      isEmpty,
      reason: '신규 절단 어간 답 발생 — id: ${newHits.join(', ')}',
    );

    // 상한은 실측치에 고정 — 데이터가 고쳐져 히트가 줄면 이 캡도 낮춰야 한다.
    expect(hitIds.length, lessThanOrEqualTo(knownDanglingStemCap));
  });
}
