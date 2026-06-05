import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/dure_title.dart';
import 'package:ko_lernen_app/models/gye.dart';

void main() {
  final now = DateTime(2026, 6, 5);

  GyeMember mk(String uid, int contrib, {DateTime? joined}) => GyeMember(
        uid: uid,
        nickname: uid,
        weeklyPacksContributed: contrib,
        joinedAt: joined ?? DateTime(2026, 1, 1), // 기본: 오래 전 가입
      );

  test('최다 기여 → 든든이', () {
    final all = [mk('a', 5), mk('b', 3), mk('c', 0)];
    expect(dureTitleFor(all[0], all, now: now), DureTitle.duru);
  });

  test('공동 최다 → 둘 다 든든이 (등수 아님, 비경쟁)', () {
    final all = [mk('a', 5), mk('b', 5), mk('c', 1)];
    expect(dureTitleFor(all[0], all, now: now), DureTitle.duru);
    expect(dureTitleFor(all[1], all, now: now), DureTitle.duru);
  });

  test('일반 기여(최다 아님) → 일꾼', () {
    final all = [mk('a', 5), mk('b', 3)];
    expect(dureTitleFor(all[1], all, now: now), DureTitle.helper);
  });

  test('기여 0 + 오래 가입 → 새싹 (격려)', () {
    final all = [mk('a', 5), mk('b', 0)];
    expect(dureTitleFor(all[1], all, now: now), DureTitle.sprout);
  });

  test('최근 7일 내 가입 → 새내기 (기여 0이어도)', () {
    final all = [mk('a', 5), mk('b', 0, joined: DateTime(2026, 6, 2))];
    expect(dureTitleFor(all[1], all, now: now), DureTitle.newcomer);
  });

  test('새내기여도 최다 기여면 든든이 우선', () {
    final all = [mk('a', 5, joined: DateTime(2026, 6, 4)), mk('b', 2)];
    expect(dureTitleFor(all[0], all, now: now), DureTitle.duru);
  });

  test('모두 기여 0이면 든든이 없음', () {
    final all = [mk('a', 0), mk('b', 0)];
    expect(dureTitleFor(all[0], all, now: now), isNot(DureTitle.duru));
    expect(dureTitleFor(all[1], all, now: now), isNot(DureTitle.duru));
  });
}
