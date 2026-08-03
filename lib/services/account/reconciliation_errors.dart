/// Raised when a serialized reconciliation write observes newer local state.
class LocalReconciliationGenerationConflict implements Exception {
  const LocalReconciliationGenerationConflict();
}
