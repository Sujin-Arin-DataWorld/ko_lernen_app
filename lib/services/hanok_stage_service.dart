import '../models/hanok_stage.dart';
import '../models/pack_progress.dart';
import 'pack_progress_service.dart';
import 'vocab_pack_service.dart';

/// Phase 3 (stately-rising-jongga) — Hanok-Stage Orchestrator.
///
/// Liest pro Level den Pack-Cleared-Anteil und berechnet daraus die
/// aktuelle [HanokStage] via reine Funktion [computeStage].
///
/// **Source of truth**: lokale `Storage.allPackProgressJson()` (via
/// `PackProgressService`). Firestore ist nur Backup; Stage wird lokal
/// abgeleitet, kein Cloud-Roundtrip nötig.
class HanokStageService {
  /// Aktueller Hanok-Stage des Users — synchron berechenbar nach `loadAll`.
  /// Async weil `VocabPackService.packsForLevel` async ist.
  static Future<HanokStage> currentStage() async {
    final ratios = await levelRatios();
    return computeStage(
      a1Ratio: ratios.a1,
      a2Ratio: ratios.a2,
      b1Ratio: ratios.b1,
      b2Ratio: ratios.b2,
    );
  }

  /// Pro-Level cleared-Ratio (cleared / total) für UI-Anzeigen.
  static Future<LevelRatios> levelRatios() async {
    final all = await VocabPackService.loadAll();
    final progressMap = PackProgressService.getAll();
    double ratio(String level) {
      final levelPacks = all.where((p) => p.level == level).toList();
      if (levelPacks.isEmpty) return 0.0;
      final cleared = levelPacks
          .where((p) => progressMap[p.id]?.status == PackStatus.cleared)
          .length;
      return cleared / levelPacks.length;
    }

    return LevelRatios(
      a1: ratio('A1'),
      a2: ratio('A2'),
      b1: ratio('B1'),
      b2: ratio('B2'),
    );
  }
}

/// Reine Werte-Klasse für Level-Cleared-Verhältnisse.
/// (Records wären schöner, aber für Tests + readable API explicit class.)
class LevelRatios {
  final double a1;
  final double a2;
  final double b1;
  final double b2;
  const LevelRatios({
    required this.a1,
    required this.a2,
    required this.b1,
    required this.b2,
  });

  /// Mit-Klausel aller Werte (z.B. für `==` in Tests).
  @override
  bool operator ==(Object other) =>
      other is LevelRatios &&
      other.a1 == a1 &&
      other.a2 == a2 &&
      other.b1 == b1 &&
      other.b2 == b2;

  @override
  int get hashCode => Object.hash(a1, a2, b1, b2);

  @override
  String toString() => 'LevelRatios(a1: $a1, a2: $a2, b1: $b1, b2: $b2)';
}
