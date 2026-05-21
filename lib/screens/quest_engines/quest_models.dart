/// Gemeinsame Datenmodelle für alle Quest-Engines.
library;

class QuestResult {
  final bool passed;
  final bool firstTry; // für 3-Stern-Bewertung
  const QuestResult({required this.passed, required this.firstTry});
}
