import '../models/gye.dart';

/// 두레 칭호 — 위계 없는 역할 인정. 두레판(契) 차별화 핵심.
///
/// 듀오링고식 1·2·3등 숫자와 정반대: 등수가 아니라 **각자의 역할**을 부여.
/// "꼴등" 낙인 대신 새싹(격려)·일꾼(인정)을 줘 강등·수치심을 없앤다.
enum DureTitle {
  duru, // 든든이 — 이번 주 최다 기여 (여럿 가능)
  newcomer, // 새내기 — 최근 합류
  sprout, // 새싹 — 아직 시작 전 (격려)
  helper, // 일꾼 — 함께 기여 중
}

/// 멤버의 두레 칭호 (비경쟁).
///
/// 우선순위: 든든이 > 새내기 > 새싹 > 일꾼.
/// - **든든이**는 최다 기여가 **공동이면 여럿** 모두 받는다 (등수가 아니므로).
/// - [now]는 새내기(가입 7일 이내) 판정용 — 테스트에서 주입.
DureTitle dureTitleFor(
  GyeMember m,
  List<GyeMember> all, {
  required DateTime now,
}) {
  final maxContrib = all.fold<int>(
    0,
    (mx, x) => x.weeklyPacksContributed > mx ? x.weeklyPacksContributed : mx,
  );

  // 든든이 — 이번 주 최다 기여 (>0). 공동 최다도 모두 든든이.
  if (m.weeklyPacksContributed > 0 && m.weeklyPacksContributed == maxContrib) {
    return DureTitle.duru;
  }
  // 새내기 — 가입 7일 이내 (환영)
  final joined = m.joinedAt;
  if (joined != null && now.difference(joined).inDays < 7) {
    return DureTitle.newcomer;
  }
  // 새싹 — 아직 기여 0 (격려, 낙인 아님)
  if (m.weeklyPacksContributed == 0) {
    return DureTitle.sprout;
  }
  // 일꾼 — 함께 기여 중
  return DureTitle.helper;
}
