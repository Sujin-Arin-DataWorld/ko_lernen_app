import '../models/gye_dedication.dart';

/// A stable visual anchor inside the shared courtyard canvas.
class GyeDedicationSlot {
  const GyeDedicationSlot({
    required this.index,
    required this.left,
    required this.bottom,
    required this.width,
  });

  final int index;
  final double left;
  final double bottom;
  final double width;
}

/// The layer is intentionally modest: exhibits are foreground mementos, not
/// new buildings or progress gates. Slot indexes are server assigned.
const List<GyeDedicationSlot> kGyeDedicationSlots = <GyeDedicationSlot>[
  GyeDedicationSlot(index: 0, left: 0.06, bottom: 0.10, width: 0.13),
  GyeDedicationSlot(index: 1, left: 0.19, bottom: 0.16, width: 0.13),
  GyeDedicationSlot(index: 2, left: 0.36, bottom: 0.10, width: 0.13),
  GyeDedicationSlot(index: 3, left: 0.52, bottom: 0.16, width: 0.13),
  GyeDedicationSlot(index: 4, left: 0.70, bottom: 0.11, width: 0.13),
  GyeDedicationSlot(index: 5, left: 0.84, bottom: 0.18, width: 0.12),
  GyeDedicationSlot(index: 6, left: 0.07, bottom: 0.43, width: 0.12),
  GyeDedicationSlot(index: 7, left: 0.28, bottom: 0.48, width: 0.13),
  GyeDedicationSlot(index: 8, left: 0.49, bottom: 0.43, width: 0.13),
  GyeDedicationSlot(index: 9, left: 0.73, bottom: 0.48, width: 0.12),
];

Set<String> eligibleGyeDedicationSlugs(Iterable<String> owned) =>
    owned.where(kGyeDedicationSlugs.contains).toSet();

/// Firestore normally guarantees one exhibit per slot. A stale/malformed
/// snapshot still must render deterministically instead of piling items up.
List<GyeDedication> normalizeGyeDedications(
  Iterable<GyeDedication> dedications,
) {
  // Tombstones remain available to the screen for compare-and-set, but cannot
  // occupy a visual slot or be rendered by the shared courtyard layer.
  final sorted = dedications.where((dedication) => dedication.isActive).toList()
    ..sort((left, right) {
      final slot = left.slotIndex!.compareTo(right.slotIndex!);
      return slot != 0 ? slot : left.uid.compareTo(right.uid);
    });
  final bySlot = <int, GyeDedication>{};
  for (final dedication in sorted) {
    bySlot.putIfAbsent(dedication.slotIndex!, () => dedication);
  }
  return List<GyeDedication>.unmodifiable(bySlot.values);
}
