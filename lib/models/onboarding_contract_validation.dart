/// A machine-readable failure produced by an onboarding V2 contract boundary.
///
/// Messages are developer diagnostics and must not be rendered directly in UI.
final class ContractViolation {
  const ContractViolation({
    required this.code,
    required this.field,
    required this.message,
  });

  final String code;
  final String field;
  final String message;

  @override
  String toString() => '$code at $field: $message';
}

/// Immutable result used by manifest and public-claim validators.
final class ContractValidationResult {
  const ContractValidationResult(this.violations);

  const ContractValidationResult.valid() : violations = const [];

  final List<ContractViolation> violations;

  bool get isValid => violations.isEmpty;

  bool hasCode(String code) => violations.any((item) => item.code == code);
}

bool isStableSemanticId(String value) {
  return RegExp(r'^[a-z][a-z0-9]*(?:[._-][a-z0-9]+)*$').hasMatch(value);
}

bool isDartLocalizationKey(String value) {
  return RegExp(r'^[a-z][A-Za-z0-9]*$').hasMatch(value);
}

bool isSecurePublicUrl(Uri value) {
  return value.scheme == 'https' && value.host.isNotEmpty;
}
