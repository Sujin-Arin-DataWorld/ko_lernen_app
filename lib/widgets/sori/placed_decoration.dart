/// 장식 배치의 공통 부품 — 마당(`DecorationLayer`)과 방(`RoomLayer`)이 함께 쓴다.
///
/// ADR-002: 세 표면(마당·사랑방·공동한옥)의 차이는 **슬롯을 누가 채우느냐**뿐이고,
/// "분수좌표 → Positioned 변환 + PNG 로드 + fallback" 은 전부 같다.
/// 그 공통부를 여기로 뺐다. 마당의 동작은 한 줄도 바뀌지 않는다.
library;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/personal_room.dart';
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
  // ── A2 살다: 사랑방 가구 12 (2026-08-18) ──
  // 원안에 있던 찻상 소반·경상·연상·머릿장·서가는 이미 있는 soban·seoan·
  // munbangsau·jagae_mungap·chaekgado 와 겹쳐 폐기했다.
  'decoration_sabangtakja': DecorCategory.floor,
  'decoration_boryo_set': DecorCategory.floor,
  'decoration_bangseok_pair': DecorCategory.floor,
  'decoration_bandaji': DecorCategory.floor,
  'decoration_hwaro': DecorCategory.floor,
  'decoration_deungjan': DecorCategory.floor,
  'decoration_geomungo': DecorCategory.floor,
  'decoration_baduk': DecorCategory.floor,
  'decoration_mokchim': DecorCategory.floor,
  'decoration_byeongpung_small': DecorCategory.wall,
  'decoration_gobi': DecorCategory.wall,
  'decoration_hyangno': DecorCategory.shelf,
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
  // ── A2 사랑방 가구 12 (2026-08-18) — 실물 크기 비례로 잡았다.
  // 주의: `RoomLayoutService.defaultWidth` 는 floor 를 `.34 * scale` 로 쓰고
  // `.14` 아래를 자르므로, 0.412 미만 값들(화로·등잔대·목침)은 처음 놓일 때
  // 같은 폭으로 나타난다. 학습자가 바로 크기를 바꿀 수 있어 그대로 둔다.
  'decoration_sabangtakja': 1.00,
  'decoration_geomungo': 0.98,
  'decoration_boryo_set': 0.95,
  'decoration_bandaji': 0.88,
  'decoration_baduk': 0.58,
  'decoration_bangseok_pair': 0.50,
  'decoration_hwaro': 0.38,
  'decoration_deungjan': 0.30,
  'decoration_mokchim': 0.22,
  'decoration_byeongpung_small': 0.55,
  'decoration_gobi': 0.26,
  'decoration_hyangno': 0.52,
};

/// [slug] 의 상대 크기 — 미등록은 1.0.
double decorScale(String slug) => kDecorScale[slug] ?? 1.0;

/// Localized, user-facing name for every shipped decoration wire identity.
String decorName(AppL10n t, String slug) => switch (slug) {
  'decoration_munbangsau' => t.decorNameMunbangsau,
  'decoration_seoan' => t.decorNameSeoan,
  'decoration_chaekgado' => t.decorNameChaekgado,
  'decoration_gat_buchae' => t.decorNameGatBuchae,
  'decoration_jagae_mungap' => t.decorNameJagaeMungap,
  'decoration_soban' => t.decorNameSoban,
  'decoration_sagunja_maehwa' => t.decorNameSagunjaMaehwa,
  'decoration_sagunja_nan' => t.decorNameSagunjaNan,
  'decoration_sagunja_guk' => t.decorNameSagunjaGuk,
  'decoration_sagunja_juk' => t.decorNameSagunjaJuk,
  'decoration_pyeonaek' => t.decorNamePyeonaek,
  'decoration_jangdokdae' => t.decorNameJangdokdae,
  'decoration_maehwa' => t.decorNameMaehwa,
  'decoration_sonamu' => t.decorNameSonamu,
  'decoration_pond' => t.decorNamePond,
  'decoration_seokdeung' => t.decorNameSeokdeung,
  'decoration_punggyeong' => t.decorNamePunggyeong,
  'decoration_doldam' => t.decorNameDoldam,
  'decoration_kkachi_nest' => t.decorNameKkachiNest,
  'decoration_dokkaebi_fire' => t.decorNameDokkaebiFire,
  'decoration_seollal_flag' => t.decorNameSeollalFlag,
  'decoration_chuseok_moon' => t.decorNameChuseokMoon,
  'decoration_hangeulday_plaque' => t.decorNameHangeuldayPlaque,
  'decoration_kite' => t.decorNameKite,
  // A2 사랑방 가구 12 (2026-08-18)
  'decoration_sabangtakja' => t.decorNameSabangtakja,
  'decoration_boryo_set' => t.decorNameBoryoSet,
  'decoration_bangseok_pair' => t.decorNameBangseokPair,
  'decoration_bandaji' => t.decorNameBandaji,
  'decoration_hwaro' => t.decorNameHwaro,
  'decoration_deungjan' => t.decorNameDeungjan,
  'decoration_geomungo' => t.decorNameGeomungo,
  'decoration_baduk' => t.decorNameBaduk,
  'decoration_mokchim' => t.decorNameMokchim,
  'decoration_byeongpung_small' => t.decorNameByeongpungSmall,
  'decoration_gobi' => t.decorNameGobi,
  'decoration_hyangno' => t.decorNameHyangno,
  _ => t.decorNameFallback,
};

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
  // 도깨비불 (2026-08-07) — 원래 온보딩 프리뷰 뱃지였으나 크리스탈 호랑이
  // 전환(`1a7dd39`/`2514a84`)으로 참조가 사라져 고아로 남아 있었다.
  // `q_dokkaebi_fire` 상시 퀘스트의 마당 장식으로 다시 배선했다.
  'decoration_dokkaebi_fire',
  // A2 살다 — 사랑방 가구 12 (2026-08-18).
  // 기존 실내 6종을 앵커 참조로 삼아 같은 세트로 생성했다. 생성 원장은
  // `docs/assets/prompts/A2_SARANGBANG_FURNISHING_2026-08-17.md`.
  'decoration_sabangtakja',
  'decoration_boryo_set',
  'decoration_bangseok_pair',
  'decoration_bandaji',
  'decoration_hwaro',
  'decoration_deungjan',
  'decoration_geomungo',
  'decoration_baduk',
  'decoration_mokchim',
  'decoration_byeongpung_small',
  'decoration_gobi',
  'decoration_hyangno',
};

/// 방별 무상 가구 풀 — grant·`Storage.ownedDecor`·`kDecorationRewardPool`
/// (계 봉헌과 집합이 같아야 하는 퀘스트 보상 풀)을 건드리지 않는 별도 계층.
///
/// 정식 소유 경로는 `HanokGrantKind.venue` grant가 방을 열고, 그 방의 풀을
/// 채우는 것은 퀘스트·보자기·팩·계(무제한, grant 아님) — 살아 있는 한옥
/// 계획의 "가구 계층" 결정 참고. 지금은 사랑방 12종만 채워져 있고 나머지
/// 방은 비어 있다 — 그 방 전용 가구가 생기면 여기에 항목을 추가한다.
///
/// 방마다 다른 풀을 두는 이유: 사랑방 12종이 A2 배선 당시 **모든** 방의
/// 피커에 나타나는 버그가 있었다(`furnishedDecorSlugs`가 방을 구분하지
/// 않고 하나의 평평한 집합을 합집합했다) — 이 맵이 그 경계를 만든다.
const Map<PersonalRoomSurface, Set<String>> kRoomFurnishingPool = {
  PersonalRoomSurface.sarangbang: {
    'decoration_sabangtakja',
    'decoration_boryo_set',
    'decoration_bangseok_pair',
    'decoration_bandaji',
    'decoration_hwaro',
    'decoration_deungjan',
    'decoration_geomungo',
    'decoration_baduk',
    'decoration_mokchim',
    'decoration_byeongpung_small',
    'decoration_gobi',
    'decoration_hyangno',
  },
};

/// 방 인벤토리 피커가 실제로 보여줄 장식 slug 집합 — 순수 함수, 저장소에
/// 쓰지 않는다. [owned] 는 언제나 `Storage.ownedDecor`(보자기로 얻은 것),
/// 방을 안 가려 항상 전량 노출된다(계 봉헌·팩 보상은 어느 방에나 놓을 수
/// 있는 것이 맞다). [openedVenues] 는 **화면이 주입**한다 — 이 파일은
/// `hanok_v1_source_guard_test.dart`가 지키는 새 진행 시스템 4개 파일에
/// 들어있지 않으므로 여기서 직접 `HanokExperienceProjection`을 읽지
/// 않고, 호출부가 계산한 결과를 평범한 데이터로만 받는다.
Set<String> furnishedDecorSlugs(
  Iterable<String> owned, {
  required Set<PersonalRoomSurface> openedVenues,
}) => {
  ...owned.where(kAvailableDecorations.contains),
  for (final venue in openedVenues) ...?kRoomFurnishingPool[venue],
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

/// 안채 슬롯. P3의 빈 안방 배경은 사랑방과 같은 3:4 전면 얕은 3/4 카메라와
/// 다섯 개의 비워 둔 건축 영역을 공유한다. 같은 좌표 계약으로 시작하면
/// 수집한 장식이 방마다 놀라운 크기 변화 없이 이동한다.
const List<SlotDef> kAnbangSlots = [
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

/// 대청마루 슬롯. 넓은 마루에도 수집 규칙은 사랑방·안채와 동일하다. 배경이
/// 이 공통 좌표에 맞춰 비워진 영역을 제공하므로, 슬롯마다 별도 UI를 만들지
/// 않아도 된다.
const List<SlotDef> kDaecheongmaruSlots = [
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

/// The stable slot contract for each private interior surface.
List<SlotDef> slotsForPersonalRoom(PersonalRoomSurface surface) =>
    switch (surface) {
      PersonalRoomSurface.sarangbang => kSarangbangSlots,
      PersonalRoomSurface.anbang => kAnbangSlots,
      PersonalRoomSurface.daecheongmaru => kDaecheongmaruSlots,
    };

/// 장식 PNG 한 장 — 자산이 없으면 식별 가능한 placeholder.
class SoriDecorationImage extends StatelessWidget {
  final String slug;
  final double size;
  final String? semantic;

  const SoriDecorationImage({
    super.key,
    required this.slug,
    required this.size,
    this.semantic,
  });

  @override
  Widget build(BuildContext context) {
    final cacheWidth = (size * MediaQuery.devicePixelRatioOf(context))
        .ceil()
        .clamp(1, 1254);
    // 자산이 없는 슬러그는 로드 시도 없이 placeholder (웹 404 방지).
    final visual = kAvailableDecorations.contains(slug)
        ? Image.asset(
            'assets/illustrations/decorations/$slug.png',
            width: size,
            fit: BoxFit.contain,
            cacheWidth: cacheWidth,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
            excludeFromSemantics: true,
            errorBuilder: (_, __, ___) =>
                DecorationFallback(slug: slug, size: size),
          )
        : DecorationFallback(slug: slug, size: size);
    final label = semantic;
    if (label == null) {
      return visual;
    }
    if (label.isEmpty) {
      return ExcludeSemantics(child: visual);
    }
    return Semantics(
      image: true,
      label: label,
      excludeSemantics: true,
      child: visual,
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
