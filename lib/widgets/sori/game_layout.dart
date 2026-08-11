/// 게임 화면의 보기/카드 타일이 **남는 세로 공간을 나눠 갖게** 하는 계산.
///
/// **왜.** 2026-08-07 Jin 태블릿 실측: Blitz-Paare 는 800×1280 에서 화면의
/// **63%**, Satz bauen 은 **57%** 가 빈 공간이었다. 원인은 타일이
/// `minHeight: 52` 같은 **상수**로 고정돼 있고, 스크롤 뷰 안에서 Column 이
/// 자연 높이(min)만 차지한 채 나머지를 그냥 비워 두기 때문이다. 화면이
/// 넓어져도 카드는 폰과 똑같은 크기라 "단어 카드가 너무 작아"가 됐다.
///
/// `SoriStudyScale` 이 붙어 있어도 소용없었다 — 그건 **본문 글씨**만 키우고
/// 버튼 높이에는 걸리지 않는다(실측: 폰·태블릿 모두 타일 52dp 로 동일).
///
/// **폰은 변화 0 이어야 한다.** 폰에서는 타일이 이미 화면을 꽉 채우므로
/// 균등 배분값이 [minimum] 보다 작게 나오고, 그러면 [minimum] 을 그대로
/// 돌려준다 — 즉 남는 공간이 있을 때만 커진다.
double soriFairTileHeight({
  required double available,
  required int count,
  double gap = 8,
  double minimum = 52,
  double maximum = 140,
}) {
  if (count <= 0 || !available.isFinite || available <= 0) {
    return minimum;
  }
  final fair = (available - gap * count) / count;
  if (fair <= minimum) {
    return minimum;
  }
  // 상한이 없으면 카드가 3~4장뿐인 라운드에서 한 장이 화면 절반을 먹는다.
  return fair > maximum ? maximum : fair;
}

/// 짧은 화면 또는 큰 접근성 글자에서 Blitz-Paare의 활성 카드 수를 줄인다.
int soriSpeedMatchSlotCount({
  required double viewportHeight,
  required double textScaleFactor,
  int regular = 5,
  int compact = 4,
  double compactHeight = 700,
  double compactTextScale = 1.3,
}) {
  if (regular <= 0 || compact <= 0) {
    return 0;
  }
  if (viewportHeight < compactHeight || textScaleFactor >= compactTextScale) {
    return compact;
  }
  return regular;
}

/// 타일 높이에 맞춰 글자 크기를 함께 올린다. 카드만 커지고 글씨가 그대로면
/// "큰 빈 상자"가 되어 오히려 더 허전해 보인다.
///
/// [base] 를 기준으로 타일이 [pivot] 보다 커진 만큼만 비례해 키우고,
/// [maxScale] 로 상한을 둔다 — 태블릿에서 보기 글씨가 제목보다 커지지 않게.
double soriTileFontSize({
  required double tileHeight,
  double base = 15,
  double pivot = 52,
  double maxScale = 1.45,
}) {
  if (tileHeight <= pivot) {
    return base;
  }
  final scale = 1 + (tileHeight - pivot) / pivot;
  return base * (scale > maxScale ? maxScale : scale);
}
