/// Canonical CEFR boundary shared by storage, bundled content, and UI.
enum LearnerLevel {
  a1,
  a2,
  b1,
  b2,
  c1,
  c2;

  /// Lower-case CEFR code for persistence: `a1` through `c2`.
  String get code => name;

  /// Upper-case display form: `A1` through `C2`.
  String get display => name.toUpperCase();

  /// Stable order for lock, path, and progression comparisons.
  int get rank => index;

  /// The only case-tolerant parser for runtime CEFR codes.
  static LearnerLevel? fromCode(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    for (final level in values) {
      if (level.code == normalized) {
        return level;
      }
    }
    return null;
  }
}
