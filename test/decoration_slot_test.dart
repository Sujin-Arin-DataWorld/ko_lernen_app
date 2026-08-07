import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/placed_decoration.dart';

/// ADR-002 — 장식 슬롯 모델의 불변식.
///
/// 슬롯은 개별 아이템이 아니라 **카테고리**를 받는다. 그래서 지켜야 할 것이 둘:
///  1. 모든 슬롯 카테고리에 놓을 수 있는 장식이 최소 하나 있는가
///     (없으면 그 슬롯은 영원히 비어 있고 유저는 이유를 모른다)
///  2. `kAvailableDecorations` 가 실제 파일과 일치하는가
///     (이 셋은 웹 404 방지용 화이트리스트라 어긋나면 조용히 placeholder 가 뜬다)
void main() {
  const decorDir = 'assets/illustrations/decorations';

  group('슬롯 ↔ 카테고리 무결성', () {
    test('모든 슬롯 카테고리를 채울 장식이 최소 1개 있다', () {
      final byCategory = <DecorCategory, List<String>>{};
      kDecorCategory.forEach((slug, cat) {
        byCategory.putIfAbsent(cat, () => []).add(slug);
      });

      for (final slot in kSarangbangSlots) {
        expect(
          byCategory[slot.accepts],
          isNotEmpty,
          reason: '슬롯 ${slot.id} 는 ${slot.accepts.name} 를 받는데 '
              '그 카테고리의 장식이 하나도 없습니다 — 영원히 비는 슬롯이 됩니다',
        );
      }
    });

    test('슬롯 id 가 중복되지 않는다', () {
      final ids = kSarangbangSlots.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length, reason: '중복된 슬롯 id');
    });

    test('슬롯 좌표가 화면 안에 있다', () {
      for (final s in kSarangbangSlots) {
        expect(s.leftFrac, inInclusiveRange(0.0, 1.0), reason: s.id);
        expect(s.bottomFrac, inInclusiveRange(0.0, 1.0), reason: s.id);
        expect(s.widthFrac, greaterThan(0.0), reason: s.id);
        expect(s.leftFrac + s.widthFrac, lessThanOrEqualTo(1.0),
            reason: '${s.id} 가 오른쪽으로 넘칩니다');
      }
    });

    test('상대 크기가 0 초과 1 이하다', () {
      kDecorScale.forEach((slug, scale) {
        expect(scale, greaterThan(0.0), reason: slug);
        expect(scale, lessThanOrEqualTo(1.0),
            reason: '$slug 의 scale 이 1 을 넘으면 슬롯 밖으로 나갑니다');
      });
    });

    test('한 슬롯에 들어갈 아이템들의 크기가 서로 구분된다', () {
      // 같은 카테고리 아이템이 전부 같은 scale 이면 슬롯 폭 하나 쓰는 것과
      // 다를 게 없다 — 소반과 문갑이 같은 크기로 그려지는 사고를 막는다.
      final byCat = <DecorCategory, Set<double>>{};
      kDecorCategory.forEach((slug, cat) {
        byCat.putIfAbsent(cat, () => {}).add(decorScale(slug));
      });
      for (final slot in kSarangbangSlots) {
        final count = kDecorCategory.values.where((c) => c == slot.accepts).length;
        if (count < 2) continue; // 후보가 하나면 비교할 게 없다
        expect(
          byCat[slot.accepts]!.length,
          greaterThan(1),
          reason: '${slot.accepts.name} 아이템이 $count 개인데 크기가 전부 같습니다 '
              '— kDecorScale 에 실제 크기 차이를 반영하세요',
        );
      }
    });

    test('center 앵커 슬롯은 heightFrac 이 있고, bottom 앵커는 0 이다', () {
      // center 정렬은 박스 높이를 알아야 성립한다. 0 이면 RoomLayer 가
      // 바닥 앵커 경로로 떨어져 조용히 아래로 처진다.
      for (final s in kSarangbangSlots) {
        if (s.anchor == DecorAnchor.center) {
          expect(s.heightFrac, greaterThan(0.0),
              reason: '${s.id} 는 center 앵커인데 heightFrac 이 0 입니다');
          expect(s.bottomFrac + s.heightFrac, lessThanOrEqualTo(1.0),
              reason: '${s.id} 가 위로 넘칩니다');
        } else {
          expect(s.heightFrac, 0.0,
              reason: '${s.id} 는 bottom 앵커라 높이를 고정하면 안 됩니다 '
                  '(마당과 같은 규약: 폭만 고정)');
        }
      }
    });

    test('벽 슬롯은 center, 바닥 슬롯은 bottom 앵커다', () {
      for (final s in kSarangbangSlots) {
        if (s.accepts == DecorCategory.wall || s.accepts == DecorCategory.peg) {
          expect(s.anchor, DecorAnchor.center,
              reason: '${s.id} — 걸리는 것은 높이가 제각각이라 바닥을 맞추면 처집니다');
        } else {
          expect(s.anchor, DecorAnchor.bottom, reason: s.id);
        }
      }
    });

    test('실내 카테고리는 마당 전용(outdoor)으로 새지 않는다', () {
      const indoor = {
        'decoration_chaekgado',
        'decoration_seoan',
        'decoration_soban',
        'decoration_jagae_mungap',
        'decoration_munbangsau',
        'decoration_gat_buchae',
      };
      for (final slug in indoor) {
        expect(
          decorCategoryOf(slug),
          isNot(DecorCategory.outdoor),
          reason: '$slug 이 kDecorCategory 에 없어 실외로 분류됩니다',
        );
      }
    });
  });

  group('kAvailableDecorations ↔ 실제 파일', () {
    test('화이트리스트의 모든 슬러그에 PNG 가 있다', () {
      for (final slug in kAvailableDecorations) {
        expect(
          File('$decorDir/$slug.png').existsSync(),
          isTrue,
          reason: '$decorDir/$slug.png 없음 — 화이트리스트에만 있고 파일이 없으면 '
              '조용히 placeholder 가 뜹니다',
        );
      }
    });

    test('파일은 있는데 화이트리스트에 빠진 장식을 알려준다', () {
      final dir = Directory(decorDir);
      if (!dir.existsSync()) return;
      final onDisk = dir
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .where((n) => n.endsWith('.png'))
          // 2026-08-07: `.where((n) => n.startsWith('decoration_'))` 필터를
          // 제거했다. 이 필터 때문에 `dokkaebi_fire.png` 786KB 가 화이트리스트
          // 밖에 있으면서도 이 가드를 그냥 통과했다 — 검사 대상을 이름 규약으로
          // 좁히면 규약을 안 지킨 파일이 정확히 안 걸린다.
          .map((n) => n.substring(0, n.length - 4))
          .toSet();

      expect(
        onDisk.difference(kAvailableDecorations),
        isEmpty,
        reason: '이 장식들은 파일이 있는데 kAvailableDecorations 에 없어 '
            '화면에 placeholder 로 뜹니다 — 셋에 추가하세요',
      );
    });
  });
}
