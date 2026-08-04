import '../widgets/sori/placed_decoration.dart';
import 'storage_service.dart';

/// 사랑방 슬롯 배치 요청의 결과.
///
/// 화면은 이 값을 사용해 실패한 요청을 조용히 무시하거나 적절한 안내를 할 수
/// 있다. 잘못된 배치를 저장한 뒤 렌더러에 복구를 맡기지 않는다.
enum RoomPlacementWriteResult {
  placed,
  cleared,
  unknownSlot,
  notOwned,
  incompatible,
}

/// 사랑방 장식의 비시각적 배치 규칙.
///
/// UI는 이 서비스에 "어느 슬롯에 무엇을 놓을지"만 전달한다. 이 클래스가
/// 슬롯 id, 카테고리, 소유권, 장식 중복을 한 경계에서 검증하므로 화면마다
/// `Storage.placeInSlot`을 직접 호출해 서로 다른 규칙을 만들지 않는다.
class RoomPlacementService {
  RoomPlacementService._();

  /// 손상·구버전 저장값을 현재 슬롯 계약으로 정규화한다.
  ///
  /// 슬롯 목록 순서가 중복 장식의 결정론적 우선순위다. 소유 목록은 장치 간
  /// 복원 순서가 달라질 수 있으므로, 여기서 기존 배치를 파괴하는 근거로 쓰지
  /// 않는다. 새 배치를 쓸 때만 별도로 소유권을 확인한다.
  static RoomPlacement sanitize(
    RoomPlacement placement, {
    Iterable<SlotDef> slots = kSarangbangSlots,
  }) {
    final result = <String, String>{};
    final usedSlugs = <String>{};
    for (final slot in slots) {
      final slug = placement[slot.id];
      if (slug == null || decorCategoryOf(slug) != slot.accepts) {
        continue;
      }
      if (!usedSlugs.add(slug)) {
        continue;
      }
      result[slot.id] = slug;
    }
    return result;
  }

  /// [slot]에 새로 놓을 수 있는 보유 장식.
  ///
  /// 현재 슬롯의 장식은 다시 선택할 수 있지만, 다른 슬롯에 놓인 장식은
  /// 중복 배치를 막기 위해 후보에서 뺀다. 입력 순서를 유지해 UI가 안정적으로
  /// 같은 순서의 보관함을 보여 줄 수 있게 한다.
  static List<String> candidatesForSlot(
    SlotDef slot, {
    required Iterable<String> owned,
    required RoomPlacement placement,
    Iterable<SlotDef> slots = kSarangbangSlots,
  }) {
    final normalized = sanitize(placement, slots: slots);
    final usedElsewhere = <String>{
      for (final entry in normalized.entries)
        if (entry.key != slot.id) entry.value,
    };
    final result = <String>[];
    final seen = <String>{};
    for (final slug in owned) {
      if (!seen.add(slug) ||
          decorCategoryOf(slug) != slot.accepts ||
          usedElsewhere.contains(slug)) {
        continue;
      }
      result.add(slug);
    }
    return result;
  }

  /// [slotId]에 [slug]를 놓거나([slug]가 null이면) 비운다.
  ///
  /// 저장 전에 현재 배치도 정규화하므로, 유효한 기존 배치는 보존하면서
  /// unknown slot·카테고리 불일치·중복 슬러그만 정리한다.
  static Future<RoomPlacementWriteResult> placeInSlot(
    String slotId,
    String? slug, {
    Iterable<SlotDef> slots = kSarangbangSlots,
  }) async {
    final slot = _slotForId(slotId, slots);
    if (slot == null) {
      return RoomPlacementWriteResult.unknownSlot;
    }

    final current = sanitize(Storage.roomPlacement, slots: slots);
    if (slug == null) {
      current.remove(slot.id);
      await Storage.setRoomPlacement(current);
      return RoomPlacementWriteResult.cleared;
    }

    if (!Storage.ownedDecor.contains(slug)) {
      return RoomPlacementWriteResult.notOwned;
    }
    if (decorCategoryOf(slug) != slot.accepts) {
      return RoomPlacementWriteResult.incompatible;
    }

    // 같은 장식은 한 슬롯에만 둔다. 이후 같은 카테고리 슬롯이 추가돼도
    // 이 불변식은 변하지 않는다.
    current.removeWhere((_, value) => value == slug);
    current[slot.id] = slug;
    await Storage.setRoomPlacement(current);
    return RoomPlacementWriteResult.placed;
  }

  static SlotDef? _slotForId(String id, Iterable<SlotDef> slots) {
    for (final slot in slots) {
      if (slot.id == id) {
        return slot;
      }
    }
    return null;
  }
}
