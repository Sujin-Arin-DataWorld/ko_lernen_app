import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/silben_puzzle.dart';

/// silben_puzzles.json 계약 — tool/gen_silben_puzzles.py 산출물이 손으로
/// 편집되거나 재생성이 깨졌을 때 잡아낸다 (data_integrity_test 관례:
/// File 직접 읽기, 플러그인 불필요).
void main() {
  late Map<String, dynamic> json;

  setUpAll(() {
    final raw = File('assets/data/silben_puzzles.json').readAsStringSync();
    json = jsonDecode(raw) as Map<String, dynamic>;
  });

  test('레벨 4개 × 퍼즐 20개, id 전역 유일', () {
    final levels = json['levels'] as Map<String, dynamic>;
    expect(levels.keys.toSet(), {'A1', 'A2', 'B1', 'B2'});
    final ids = <String>{};
    for (final entry in levels.entries) {
      final list = entry.value as List;
      expect(list, hasLength(20), reason: '레벨 ${entry.key}');
      for (final item in list) {
        final id = (item as Map<String, dynamic>)['id'] as String;
        expect(ids.add(id), isTrue, reason: '중복 id $id');
      }
    }
  });

  test('모든 퍼즐: 좌표 정합·연결성·풀 충분성·힌트 완비', () {
    final levels = json['levels'] as Map<String, dynamic>;
    for (final entry in levels.entries) {
      for (final item in entry.value as List) {
        final p = SilbenPuzzle.fromJson(item as Map<String, dynamic>);
        expect(p.words.length, inInclusiveRange(3, 4), reason: p.id);

        // 좌표 정합: 교차 칸은 같은 음절, 격자 범위 안.
        final cells = <(int, int), String>{};
        for (final w in p.words) {
          expect(w.german, isNotEmpty, reason: '${p.id} ${w.answer}');
          expect(w.exampleDe, isNotEmpty, reason: '${p.id} ${w.answer}');
          expect(w.exampleKo, isNotEmpty, reason: '${p.id} ${w.answer}');
          final cs = w.cells;
          for (var j = 0; j < cs.length; j++) {
            final (r, c) = cs[j];
            expect(r, inInclusiveRange(0, p.rows - 1), reason: p.id);
            expect(c, inInclusiveRange(0, p.cols - 1), reason: p.id);
            final prev = cells[cs[j]];
            if (prev != null) {
              expect(prev, w.answer[j], reason: '${p.id} 교차 충돌');
            }
            cells[cs[j]] = w.answer[j];
          }
        }

        // 연결성: 단어 그래프(교차 칸 공유)가 하나로 이어진다.
        final adjacency = <int, Set<int>>{};
        for (var i = 0; i < p.words.length; i++) {
          adjacency[i] = {};
          for (var j = 0; j < p.words.length; j++) {
            if (i != j &&
                p.words[i].cells
                    .toSet()
                    .intersection(p.words[j].cells.toSet())
                    .isNotEmpty) {
              adjacency[i]!.add(j);
            }
          }
        }
        final visited = <int>{0};
        final queue = [0];
        while (queue.isNotEmpty) {
          for (final n in adjacency[queue.removeLast()]!) {
            if (visited.add(n)) {
              queue.add(n);
            }
          }
        }
        expect(visited.length, p.words.length, reason: '${p.id} 비연결');

        // 풀 충분성: 해답 칸 음절 멀티셋 ⊆ 풀.
        final pool = [...p.pool];
        for (final syl in cells.values) {
          expect(pool.remove(syl), isTrue, reason: '${p.id} 풀 누락 $syl');
        }
      }
    }
  });
}
