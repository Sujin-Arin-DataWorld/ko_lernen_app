import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// 트리아지 결과 (2026-08-26 첫 실행 실측). cloze.json 은
// tools/content_factory/build_cloze.py 배치 생성기 산출물이며, 이 3종 가드는
// Task 2(시드 5건 수기 교정) 이후 재실측을 통해 캡을 낮춰가는 래칫이다.
// 늘리기 금지.

// 가드②(fullKo ↔ CSV example_korean 동기+레벨 일치) 기존 실패 318건.
// 315건은 fullKo 가 CSV example_korean 컬럼에 아예 없음(배치 생성기가
// CSV 예문을 그대로 복사하지 않고 변형한 파생 문장), 3건은 CSV 쪽
// example_korean 은 일치하지만 level 컬럼이 cloze 항목의 level 과 다름.
const Set<String> knownUnsyncedIds = {
  'cloze_a1_0001',
  'cloze_a1_0003',
  'cloze_a1_0006',
  'cloze_a1_0007',
  'cloze_a1_0010',
  'cloze_a1_0022',
  'cloze_a1_0023',
  'cloze_a1_0026',
  'cloze_a1_0027',
  'cloze_a1_0028',
  'cloze_a1_0031',
  'cloze_a1_0032',
  'cloze_a1_0033',
  'cloze_a1_0034',
  'cloze_a1_0041',
  'cloze_a1_0043',
  'cloze_a1_0044',
  'cloze_a1_0056',
  'cloze_a1_0057',
  'cloze_a1_0059',
  'cloze_a1_0068',
  'cloze_a1_0070',
  'cloze_a1_0071',
  'cloze_a1_0074',
  'cloze_a1_0077',
  'cloze_a1_0078',
  'cloze_a1_0090',
  'cloze_a1_0093',
  'cloze_a1_0097',
  'cloze_a1_0292',
  'cloze_a1_0293',
  'cloze_a1_0294',
  'cloze_a1_0295',
  'cloze_a1_0296',
  'cloze_a1_0297',
  'cloze_a1_0298',
  'cloze_a1_0299',
  'cloze_a1_0300',
  'cloze_a1_0301',
  'cloze_a1_0302',
  'cloze_a1_0305',
  'cloze_a1_0307',
  'cloze_a1_0308',
  'cloze_a1_0309',
  'cloze_a1_0310',
  'cloze_a1_0311',
  'cloze_a1_0312',
  'cloze_a1_0313',
  'cloze_a1_0314',
  'cloze_a1_0315',
  'cloze_a1_0316',
  'cloze_a1_0317',
  'cloze_a1_0318',
  'cloze_a1_0319',
  'cloze_a1_0320',
  'cloze_a1_0321',
  'cloze_a1_0322',
  'cloze_a1_0323',
  'cloze_a1_0324',
  'cloze_a1_0326',
  'cloze_a1_0327',
  'cloze_a1_0328',
  'cloze_a1_0331',
  'cloze_a1_0332',
  'cloze_a1_0333',
  'cloze_a1_0334',
  'cloze_a1_0335',
  'cloze_a1_0336',
  'cloze_a1_0337',
  'cloze_a1_0338',
  'cloze_a1_0339',
  'cloze_a1_0340',
  'cloze_a1_0341',
  'cloze_a1_0342',
  'cloze_a1_0343',
  'cloze_a1_0344',
  'cloze_a2_0001',
  'cloze_a2_0002',
  'cloze_a2_0003',
  'cloze_a2_0004',
  'cloze_a2_0006',
  'cloze_a2_0007',
  'cloze_a2_0008',
  'cloze_a2_0009',
  'cloze_a2_0010',
  'cloze_a2_0011',
  'cloze_a2_0012',
  'cloze_a2_0013',
  'cloze_a2_0014',
  'cloze_a2_0015',
  'cloze_a2_0016',
  'cloze_a2_0017',
  'cloze_a2_0018',
  'cloze_a2_0019',
  'cloze_a2_0020',
  'cloze_a2_0021',
  'cloze_a2_0022',
  'cloze_a2_0023',
  'cloze_a2_0024',
  'cloze_a2_0025',
  'cloze_a2_0026',
  'cloze_a2_0027',
  'cloze_a2_0028',
  'cloze_a2_0029',
  'cloze_a2_0030',
  'cloze_a2_0031',
  'cloze_a2_0032',
  'cloze_a2_0033',
  'cloze_a2_0034',
  'cloze_a2_0035',
  'cloze_a2_0036',
  'cloze_a2_0037',
  'cloze_a2_0038',
  'cloze_a2_0039',
  'cloze_a2_0040',
  'cloze_a2_0041',
  'cloze_a2_0042',
  'cloze_a2_0044',
  'cloze_a2_0045',
  'cloze_a2_0047',
  'cloze_a2_0048',
  'cloze_a2_0049',
  'cloze_a2_0050',
  'cloze_a2_0051',
  'cloze_a2_0052',
  'cloze_a2_0053',
  'cloze_a2_0054',
  'cloze_a2_0055',
  'cloze_a2_0056',
  'cloze_a2_0057',
  'cloze_a2_0058',
  'cloze_a2_0059',
  'cloze_a2_0060',
  'cloze_a2_0061',
  'cloze_a2_0062',
  'cloze_a2_0063',
  'cloze_a2_0064',
  'cloze_a2_0065',
  'cloze_a2_0066',
  'cloze_a2_0067',
  'cloze_a2_0068',
  'cloze_a2_0069',
  'cloze_a2_0070',
  'cloze_a2_0071',
  'cloze_a2_0072',
  'cloze_a2_0073',
  'cloze_a2_0074',
  'cloze_a2_0075',
  'cloze_a2_0268',
  'cloze_a2_0273',
  'cloze_a2_0274',
  'cloze_a2_0275',
  'cloze_a2_0276',
  'cloze_a2_0277',
  'cloze_b1_0001',
  'cloze_b1_0002',
  'cloze_b1_0003',
  'cloze_b1_0004',
  'cloze_b1_0005',
  'cloze_b1_0006',
  'cloze_b1_0007',
  'cloze_b1_0008',
  'cloze_b1_0009',
  'cloze_b1_0010',
  'cloze_b1_0011',
  'cloze_b1_0012',
  'cloze_b1_0013',
  'cloze_b1_0014',
  'cloze_b1_0015',
  'cloze_b1_0016',
  'cloze_b1_0017',
  'cloze_b1_0018',
  'cloze_b1_0019',
  'cloze_b1_0020',
  'cloze_b1_0021',
  'cloze_b1_0022',
  'cloze_b1_0023',
  'cloze_b1_0024',
  'cloze_b1_0025',
  'cloze_b1_0026',
  'cloze_b1_0027',
  'cloze_b1_0028',
  'cloze_b1_0029',
  'cloze_b1_0030',
  'cloze_b1_0031',
  'cloze_b1_0032',
  'cloze_b1_0033',
  'cloze_b1_0034',
  'cloze_b1_0035',
  'cloze_b1_0036',
  'cloze_b1_0037',
  'cloze_b1_0038',
  'cloze_b1_0039',
  'cloze_b1_0040',
  'cloze_b1_0041',
  'cloze_b1_0042',
  'cloze_b1_0043',
  'cloze_b1_0044',
  'cloze_b1_0045',
  'cloze_b1_0046',
  'cloze_b1_0047',
  'cloze_b1_0048',
  'cloze_b1_0049',
  'cloze_b1_0050',
  'cloze_b1_0051',
  'cloze_b1_0052',
  'cloze_b1_0053',
  'cloze_b1_0054',
  'cloze_b1_0055',
  'cloze_b1_0080',
  'cloze_b1_0081',
  'cloze_b1_0082',
  'cloze_b1_0083',
  'cloze_b2_0001',
  'cloze_b2_0002',
  'cloze_b2_0003',
  'cloze_b2_0004',
  'cloze_b2_0005',
  'cloze_b2_0006',
  'cloze_b2_0007',
  'cloze_b2_0008',
  'cloze_b2_0009',
  'cloze_b2_0010',
  'cloze_b2_0011',
  'cloze_b2_0012',
  'cloze_b2_0013',
  'cloze_b2_0014',
  'cloze_b2_0015',
  'cloze_b2_0016',
  'cloze_b2_0017',
  'cloze_b2_0018',
  'cloze_b2_0019',
  'cloze_b2_0020',
  'cloze_b2_0021',
  'cloze_b2_0022',
  'cloze_b2_0023',
  'cloze_b2_0024',
  'cloze_b2_0025',
  'cloze_b2_0026',
  'cloze_b2_0027',
  'cloze_b2_0028',
  'cloze_b2_0029',
  'cloze_b2_0030',
  'cloze_b2_0031',
  'cloze_b2_0032',
  'cloze_b2_0033',
  'cloze_b2_0034',
  'cloze_b2_0035',
  'cloze_b2_0036',
  'cloze_b2_0037',
  'cloze_b2_0038',
  'cloze_b2_0039',
  'cloze_b2_0040',
  'cloze_b2_0041',
  'cloze_b2_0042',
  'cloze_b2_0043',
  'cloze_b2_0044',
  'cloze_b2_0045',
  'cloze_b2_0046',
  'cloze_b2_0047',
  'cloze_b2_0048',
  'cloze_b2_0049',
  'cloze_b2_0050',
  'cloze_b2_0051',
  'cloze_b2_0052',
  'cloze_b2_0053',
  'cloze_b2_0054',
  'cloze_b2_0055',
  'cloze_b2_0056',
  'cloze_b2_0057',
  'cloze_b2_0166',
  'cloze_b2_0167',
  'cloze_b2_0168',
  'cloze_b2_0169',
  'cloze_b2_0362',
  'cloze_b2_0363',
  'cloze_b2_0364',
  'cloze_b2_0365',
  'cloze_b2_0366',
  'cloze_b2_0367',
  'cloze_b2_0368',
  'cloze_b2_0369',
  'cloze_b2_0370',
  'cloze_b2_0371',
  'cloze_b2_0372',
  'cloze_b2_0373',
  'cloze_c1_0049',
  'cloze_c1_0050',
  'cloze_c1_0051',
  'cloze_c1_0052',
  'cloze_c1_0221',
  'cloze_c1_0222',
  'cloze_c1_0223',
  'cloze_c1_0224',
  'cloze_c1_0225',
  'cloze_c1_0226',
  'cloze_c1_0227',
  'cloze_c1_0228',
  'cloze_c1_0229',
  'cloze_c1_0230',
  'cloze_c1_0231',
  'cloze_c1_0232',
  'cloze_c2_0049',
  'cloze_c2_0050',
  'cloze_c2_0051',
  'cloze_c2_0052',
  'cloze_c2_0221',
  'cloze_c2_0222',
  'cloze_c2_0223',
  'cloze_c2_0224',
  'cloze_c2_0225',
  'cloze_c2_0226',
  'cloze_c2_0227',
  'cloze_c2_0228',
  'cloze_c2_0229',
  'cloze_c2_0230',
  'cloze_c2_0231',
  'cloze_c2_0232',
};
const int knownUnsyncedCap = 318; // 2026-08-26 실측 고정

// 가드③(distractor 위생) 기존 실패 17건 — 전부 오답 후보 문자열이 원 문장
// (sentenceKo, 빈칸 채워지기 전) 부분 문자열로 그대로 노출됨(EXPOSED_IN_SENTENCE).
// cloze_a1_0104(현관)는 Task 2 시드 5건 중 하나로, Task 2에서 distractor를
// 교체(현관→장모님)해 이 allowlist 에서 제거하고 캡을 16으로 낮췄다.
const Set<String> knownDistractorIds = {
  'cloze_a1_0159',
  'cloze_a1_0200',
  'cloze_a1_0244',
  'cloze_a1_0274',
  'cloze_a2_0122',
  'cloze_a2_0172',
  'cloze_a2_0213',
  'cloze_a2_0250',
  'cloze_a2_0259',
  'cloze_a2_0264',
  'cloze_b1_0272',
  'cloze_b2_0067',
  'cloze_b2_0080',
  'cloze_c1_0113',
  'cloze_c2_0135',
  'cloze_c2_0159',
};
const int knownDistractorCap = 16; // 2026-08-26 실측 고정 (Task 2: cloze_a1_0104 제거)

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
  final iKo = header.indexOf('example_korean');
  final iLevel = header.indexOf('level');
  final exampleLevel = <String, String>{
    for (final r in csvRows.skip(1))
      if (r.length > iKo) r[iKo]: r[iLevel],
  };

  test('빈칸 복원: sentenceKo(＿＿＿→answer) == fullKo', () {
    for (final it in items) {
      final rebuilt = (it['sentenceKo'] as String)
          .replaceFirst('＿＿＿', it['answer'] as String);
      expect(rebuilt, it['fullKo'], reason: it['id'] as String);
    }
  });

  test('fullKo 는 CSV example_korean 에 존재하고 레벨이 일치한다', () {
    final unsynced = <String>[];
    for (final it in items) {
      final id = it['id'] as String;
      final level = exampleLevel[it['fullKo'] as String];
      if (level == null || level.toLowerCase() != it['level']) {
        if (!knownUnsyncedIds.contains(id)) unsynced.add(id);
      }
    }
    expect(unsynced, isEmpty,
        reason: '신규 비동기 항목 — CSV/cloze 3파일 동기 규칙 위반');
    expect(knownUnsyncedIds.length, lessThanOrEqualTo(knownUnsyncedCap));
  });

  test('distractor 위생: 정답과 다르고, 문장 잔여부에 노출되지 않는다', () {
    final newExposed = <String>[];
    for (final it in items) {
      final id = it['id'] as String;
      final answer = it['answer'] as String;
      final sentence = it['sentenceKo'] as String;
      for (final d in (it['distractors'] as List).cast<String>()) {
        expect(d.trim(), isNotEmpty, reason: id);
        expect(d, isNot(answer), reason: id);
        if (sentence.contains(d) && !knownDistractorIds.contains(id)) {
          newExposed.add(id);
        }
      }
    }
    expect(newExposed, isEmpty,
        reason: '신규 distractor 노출 항목 — 문장에 오답 후보가 그대로 드러남');
    expect(knownDistractorIds.length, lessThanOrEqualTo(knownDistractorCap));
  });
}
