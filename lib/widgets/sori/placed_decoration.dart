/// 장식 배치의 공통 부품 — 마당(`DecorationLayer`)과 방(`RoomLayer`)이 함께 쓴다.
///
/// ADR-002: 세 표면(마당·사랑방·공동한옥)의 차이는 **슬롯을 누가 채우느냐**뿐이고,
/// "분수좌표 → Positioned 변환 + PNG 로드 + fallback" 은 전부 같다.
/// 그 공통부를 여기로 뺐다. 마당의 동작은 한 줄도 바뀌지 않는다.
library;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// 장식의 쓰임새 분류. 슬롯은 **개별 아이템이 아니라 이 카테고리를 받는다** —
/// 그래서 장식이 늘어도 슬롯 정의는 그대로고 선택지만 늘어난다(확장 비용 상수).
enum DecorCategory {
  /// 벽에 거는 것 — 병풍·족자·액자·편액
  wall,

  /// 바닥에 놓는 좌식 가구 — 서안·소반·문갑
  floor,

  /// 선반·탁상 위 소품 — 문방사우·항아리
  shelf,

  /// 걸이에 거는 것 — 갓·부채
  peg,

  /// 마당 전용(실외) — 나무·돌·연못 등. 방 슬롯은 받지 않는다.
  outdoor,
}

/// 슬러그 → 카테고리. 여기 없는 슬러그는 [DecorCategory.outdoor] 로 본다.
///
/// 실내 6종은 2026-08-04 신설(사랑방용). 기존 마당 장식 중 사군자 액자와
/// 편액은 본래 실내 그림이라 `wall` 로 잡아 방에서도 쓸 수 있게 했다 —
/// 마당에서도 계속 쓰이므로 양쪽에 노출된다.
const Map<String, DecorCategory> kDecorCategory = {
  // ── 실내 신설 (2026-08-04) ──
  'decoration_chaekgado': DecorCategory.wall,
  'decoration_seoan': DecorCategory.floor,
  'decoration_soban': DecorCategory.floor,
  'decoration_jagae_mungap': DecorCategory.floor,
  'decoration_munbangsau': DecorCategory.shelf,
  'decoration_gat_buchae': DecorCategory.peg,
  // ── 기존 중 실내로도 쓰이는 것 ──
  'decoration_sagunja_maehwa': DecorCategory.wall,
  'decoration_sagunja_nan': DecorCategory.wall,
  'decoration_sagunja_guk': DecorCategory.wall,
  'decoration_sagunja_juk': DecorCategory.wall,
  'decoration_pyeonaek': DecorCategory.wall,
};

/// [slug] 의 카테고리 — 미등록은 실외로 간주.
DecorCategory decorCategoryOf(String slug) =>
    kDecorCategory[slug] ?? DecorCategory.outdoor;

/// 슬롯 폭 대비 이 장식의 **자연스러운 크기**. 미등록은 1.0(슬롯을 꽉 채움).
///
/// 왜 필요한가: 마당은 퀘스트마다 `widthFrac` 을 손으로 잡아 0.08~1.00 까지
/// 제각각이다. 방은 **한 슬롯에 여러 아이템이 번갈아 들어가므로** 슬롯 폭
/// 하나로는 안 된다 — 소반과 문갑을 같은 폭으로 그리면 소반이 괴물이 된다.
/// 실제 렌더 폭 = `slot.widthFrac * decorScale(slug)`.
const Map<String, double> kDecorScale = {
  // floor — 문갑이 가장 길고, 소반이 가장 작다
  'decoration_jagae_mungap': 1.00,
  'decoration_seoan': 0.92,
  'decoration_soban': 0.46,
  // wall — 4폭 병풍이 기준, 한 폭짜리 액자는 절반 이하
  'decoration_chaekgado': 1.00,
  'decoration_pyeonaek': 0.62,
  'decoration_sagunja_maehwa': 0.42,
  'decoration_sagunja_nan': 0.42,
  'decoration_sagunja_guk': 0.42,
  'decoration_sagunja_juk': 0.42,
  // shelf / peg
  'decoration_munbangsau': 1.00,
  'decoration_gat_buchae': 1.00,
};

/// [slug] 의 상대 크기 — 미등록은 1.0.
double decorScale(String slug) => kDecorScale[slug] ?? 1.0;

/// 장식의 표시 이름. `kQuestCatalog` 의 `name: (de:, en:)` 과 같은 방식이다 —
/// 콘텐츠 문구는 ARB 가 아니라 인라인 레코드로 두는 것이 이 레포의 관례고,
/// 그래야 장식을 추가할 때 `flutter gen-l10n` 을 돌릴 필요가 없다.
///
/// 한국어 원어를 괄호로 병기하는 것도 퀘스트 이름과 같은 규칙 —
/// 학습자가 사물의 한국어 이름을 자연스럽게 접하게 한다.
const Map<String, ({String de, String en})> kDecorName = {
  'decoration_munbangsau': (
    de: 'Schreibzeug (문방사우)',
    en: "Scholar's writing set (문방사우)",
  ),
  'decoration_seoan': (de: 'Schreibpult (서안)', en: 'Writing desk (서안)'),
  'decoration_chaekgado': (
    de: 'Bücherwand-Wandschirm (책가도)',
    en: 'Bookshelf screen (책가도)',
  ),
  'decoration_gat_buchae': (
    de: 'Hut und Fächer (갓·부채)',
    en: 'Hat and fan (갓·부채)',
  ),
  'decoration_jagae_mungap': (
    de: 'Perlmutt-Truhe (자개 문갑)',
    en: 'Mother-of-pearl chest (자개 문갑)',
  ),
  'decoration_soban': (de: 'Tabletttisch (소반)', en: 'Tray table (소반)'),
  'decoration_sagunja_maehwa': (
    de: 'Pflaumenblüten-Bild (매화)',
    en: 'Plum blossom scroll (매화)',
  ),
  'decoration_sagunja_nan': (
    de: 'Orchideen-Bild (난초)',
    en: 'Orchid scroll (난초)',
  ),
  'decoration_sagunja_guk': (
    de: 'Chrysanthemen-Bild (국화)',
    en: 'Chrysanthemum scroll (국화)',
  ),
  'decoration_sagunja_juk': (
    de: 'Bambus-Bild (대나무)',
    en: 'Bamboo scroll (대나무)',
  ),
  'decoration_pyeonaek': (de: 'Namenstafel (편액)', en: 'Name plaque (편액)'),
};

/// [slug] 의 표시 이름. 미등록이면 슬러그에서 만든 대체 이름.
String decorName(String slug, {required bool german}) {
  final n = kDecorName[slug];
  if (n != null) return german ? n.de : n.en;
  final base = slug.startsWith('decoration_')
      ? slug.substring('decoration_'.length)
      : slug;
  return base.replaceAll('_', ' ');
}

/// 슬롯 안에서 아이템이 어디에 붙는가.
enum DecorAnchor {
  /// 바닥에 놓이는 것 — 아래 모서리를 슬롯 바닥에 맞춘다(마당과 같은 규약).
  bottom,

  /// 벽에 걸리는 것 — 높이가 제각각이라 바닥을 맞추면 작은 액자가
  /// 벽 아래로 처진다. 슬롯 중심에 맞춘다.
  center,
}

/// 실제로 PNG가 존재하는 장식 슬러그. 여기에 없는 슬러그는 `Image.asset` 을
/// **시도하지 않고** 바로 placeholder 로 보낸다 — 그래야 웹에서 없는 자산에
/// 대한 404 네트워크 에러 스팸이 안 생긴다.
///
/// ⚠️ 새 장식 PNG를 넣으면 여기에도 슬러그를 추가할 것.
/// `test/decoration_slot_test.dart` 가 이 셋과 실제 파일을 대조한다.
const Set<String> kAvailableDecorations = {
  // 사랑방 실내 장식 (P1, 2026-08-04)
  'decoration_chaekgado',
  'decoration_gat_buchae',
  'decoration_jagae_mungap',
  'decoration_munbangsau',
  'decoration_seoan',
  'decoration_soban',
  // 기존 마당/벽 장식
  'decoration_jangdokdae',
  'decoration_kkachi_nest',
  'decoration_maehwa',
  'decoration_pond',
  'decoration_punggyeong',
  'decoration_pyeonaek',
  'decoration_sagunja_juk',
  'decoration_sagunja_maehwa',
  'decoration_sagunja_nan',
  'decoration_sagunja_guk',
  'decoration_sonamu',
  'decoration_seokdeung',
  'decoration_doldam',
  'decoration_seollal_flag',
  'decoration_chuseok_moon',
  'decoration_hangeulday_plaque',
  'decoration_kite',
};

/// 표면 위의 명명된 자리. 좌표는 부모 크기에 대한 분수 —
/// 마당의 `QuestLayout` 과 같은 규약이라 렌더 코드를 공유한다.
typedef SlotDef = ({
  String id,
  double leftFrac,
  double bottomFrac,
  double widthFrac,

  /// [DecorAnchor.center] 슬롯에서만 쓴다. 0 이면 높이 자유(bottom 앵커).
  ///
  /// 왜 필요한가: 가운데 정렬은 아이템 높이를 알아야 하는데 `Image.asset` 은
  /// 로드 전까지 크기를 모른다. 그래서 center 슬롯은 **박스를 먼저 정하고**
  /// 그 안에서 `BoxFit.contain` 으로 맞춘다 — 큰 병풍도 슬롯 밖으로 안 넘친다.
  double heightFrac,
  DecorCategory accepts,
  DecorAnchor anchor,
});

/// 유저 배치 — 슬롯 id → 장식 슬러그. 슬롯당 하나.
typedef RoomPlacement = Map<String, String>;

/// 사랑방 슬롯. 배경 `hanok/sarangbang_empty.png` (3/4 시점, 좌측 벽감) 기준.
///
/// 좌표는 그림의 건축 요소에 맞춘 것이라 배경을 바꾸면 같이 바꿔야 한다.
/// 슬롯 수는 5개로 시작한다 — 아이템이 늘어도 여기는 안 늘린다.
const List<SlotDef> kSarangbangSlots = [
  (
    id: 'wall_back',
    leftFrac: 0.22,
    bottomFrac: 0.30,
    widthFrac: 0.56,
    heightFrac: 0.42,
    accepts: DecorCategory.wall,
    anchor: DecorAnchor.center,
  ),
  (
    id: 'floor_center',
    leftFrac: 0.28,
    bottomFrac: 0.08,
    widthFrac: 0.44,
    heightFrac: 0.0,
    accepts: DecorCategory.floor,
    anchor: DecorAnchor.bottom,
  ),
  (
    id: 'alcove_top',
    leftFrac: 0.02,
    bottomFrac: 0.40,
    widthFrac: 0.14,
    heightFrac: 0.0,
    accepts: DecorCategory.shelf,
    anchor: DecorAnchor.bottom,
  ),
  (
    id: 'alcove_bottom',
    leftFrac: 0.02,
    bottomFrac: 0.20,
    widthFrac: 0.14,
    heightFrac: 0.0,
    accepts: DecorCategory.shelf,
    anchor: DecorAnchor.bottom,
  ),
  (
    id: 'peg_rail',
    leftFrac: 0.03,
    bottomFrac: 0.70,
    widthFrac: 0.13,
    heightFrac: 0.16,
    accepts: DecorCategory.peg,
    anchor: DecorAnchor.center,
  ),
];

/// 장식 PNG 한 장 — 자산이 없으면 식별 가능한 placeholder.
class SoriDecorationImage extends StatelessWidget {
  final String slug;
  final double size;

  const SoriDecorationImage({
    super.key,
    required this.slug,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // 자산이 없는 슬러그는 로드 시도 없이 placeholder (웹 404 방지).
    if (!kAvailableDecorations.contains(slug)) {
      return DecorationFallback(slug: slug, size: size);
    }
    return Image.asset(
      'assets/illustrations/decorations/$slug.png',
      width: size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => DecorationFallback(slug: slug, size: size),
    );
  }
}

/// 자산이 아직 없을 때의 작은 동그란 표식 — 디버그용으로 식별 가능.
class DecorationFallback extends StatelessWidget {
  final String slug;
  final double size;

  const DecorationFallback({super.key, required this.slug, required this.size});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: SoriColors.primary.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(
          color: SoriColors.primary.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _label(slug),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: (size * 0.16).clamp(8.0, 13.0),
          color: s.textMuted,
          height: 1.1,
        ),
      ),
    );
  }

  static String _label(String slug) {
    final base = slug.startsWith('decoration_')
        ? slug.substring('decoration_'.length)
        : slug;
    return base.split('_').first;
  }
}
