import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// Runtime state of the optional, on-device Korean proofreading feature.
enum KoreanProofreadingStatus {
  unsupportedPlatform,
  unsupportedAndroidVersion,
  featureModuleMissing,
  unavailable,
  downloadable,
  downloading,
  available,
  checking,
  completed,
  busy,
  quotaExceeded,
  backgroundBlocked,
  failed,
}

/// Stable app-facing failures. Native/ML Kit exception text is never exposed.
enum KoreanProofreadingError {
  none,
  invalidInput,
  inputTooLong,
  missingPlugin,
  featureModuleMissing,
  unavailable,
  downloadFailed,
  busy,
  quotaExceeded,
  backgroundBlocked,
  notEnoughStorage,
  systemUpdateNeeded,
  aicoreIncompatible,
  requestRejected,
  responseRejected,
  irrelevantResponse,
  malformedResponse,
  timeout,
  unknown,
}

@immutable
class KoreanProofreadingAvailability {
  const KoreanProofreadingAvailability({
    required this.status,
    this.error = KoreanProofreadingError.none,
    this.downloadedBytes,
    this.totalBytes,
    this.retryAfter,
  });

  final KoreanProofreadingStatus status;
  final KoreanProofreadingError error;
  final int? downloadedBytes;
  final int? totalBytes;
  final Duration? retryAfter;

  bool get canProofread => status == KoreanProofreadingStatus.available;
  bool get canDownload => status == KoreanProofreadingStatus.downloadable;
}

@immutable
class KoreanProofreadingChange {
  const KoreanProofreadingChange({
    required this.originalText,
    required this.replacementText,
  });

  final String originalText;
  final String replacementText;
}

@immutable
class KoreanProofreadingResult {
  const KoreanProofreadingResult({
    required this.status,
    required this.originalText,
    this.suggestion,
    this.changes = const <KoreanProofreadingChange>[],
    this.error = KoreanProofreadingError.none,
    this.retryAfter,
  });

  final KoreanProofreadingStatus status;

  /// Exactly the string supplied by the caller. It is never normalized or
  /// replaced with an ML-generated value.
  final String originalText;
  final String? suggestion;
  final List<KoreanProofreadingChange> changes;
  final KoreanProofreadingError error;
  final Duration? retryAfter;

  bool get isSuccessful =>
      status == KoreanProofreadingStatus.completed &&
      error == KoreanProofreadingError.none &&
      suggestion != null;
}

/// Optional Android-only ML Kit GenAI proofreading adapter.
///
/// The Android implementation is delivered only to API 26+ devices. All
/// unsupported/missing-feature states are returned as values so iOS, web and
/// older Android devices retain the existing learning flow without crashes.
class KoreanProofreadingService {
  KoreanProofreadingService({
    MethodChannel? channel,
    bool? isAndroidOverride,
    Duration operationTimeout = const Duration(seconds: 45),
    Duration downloadTimeout = const Duration(minutes: 5),
  }) : _channel = channel ?? const MethodChannel(_channelName),
       // ignore: prefer_initializing_formals
       _isAndroidOverride = isAndroidOverride,
       // ignore: prefer_initializing_formals
       _operationTimeout = operationTimeout,
       // ignore: prefer_initializing_formals
       _downloadTimeout = downloadTimeout;

  static const String _channelName =
      'com.sujinarin.ko_lernen_app/korean_proofreading';
  static const int maxInputCodePoints = 240;

  final MethodChannel _channel;
  final bool? _isAndroidOverride;
  final Duration _operationTimeout;
  final Duration _downloadTimeout;
  bool _closed = false;
  bool _proofreading = false;

  bool get _isAndroid =>
      _isAndroidOverride ??
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  Future<KoreanProofreadingAvailability> check() async {
    final fallback = _platformFallback();
    if (fallback != null) {
      return fallback;
    }
    if (_closed) {
      return const KoreanProofreadingAvailability(
        status: KoreanProofreadingStatus.unavailable,
        error: KoreanProofreadingError.unavailable,
      );
    }
    try {
      final response = await _channel
          .invokeMethod<dynamic>('check')
          .timeout(_operationTimeout);
      return _availabilityFromWire(response);
    } on TimeoutException {
      return const KoreanProofreadingAvailability(
        status: KoreanProofreadingStatus.failed,
        error: KoreanProofreadingError.timeout,
      );
    } on MissingPluginException {
      return const KoreanProofreadingAvailability(
        status: KoreanProofreadingStatus.featureModuleMissing,
        error: KoreanProofreadingError.missingPlugin,
      );
    } on PlatformException catch (error) {
      return _availabilityFromPlatformException(error);
    } catch (_) {
      return const KoreanProofreadingAvailability(
        status: KoreanProofreadingStatus.failed,
        error: KoreanProofreadingError.unknown,
      );
    }
  }

  Future<KoreanProofreadingAvailability> download() async {
    final fallback = _platformFallback();
    if (fallback != null) {
      return fallback;
    }
    if (_closed) {
      return const KoreanProofreadingAvailability(
        status: KoreanProofreadingStatus.unavailable,
        error: KoreanProofreadingError.unavailable,
      );
    }
    try {
      final response = await _channel
          .invokeMethod<dynamic>('download')
          .timeout(_downloadTimeout);
      final parsed = _availabilityFromWire(response);
      if (parsed.status == KoreanProofreadingStatus.failed &&
          parsed.error == KoreanProofreadingError.unknown) {
        return const KoreanProofreadingAvailability(
          status: KoreanProofreadingStatus.failed,
          error: KoreanProofreadingError.downloadFailed,
        );
      }
      return parsed;
    } on TimeoutException {
      return const KoreanProofreadingAvailability(
        status: KoreanProofreadingStatus.failed,
        error: KoreanProofreadingError.timeout,
      );
    } on MissingPluginException {
      return const KoreanProofreadingAvailability(
        status: KoreanProofreadingStatus.featureModuleMissing,
        error: KoreanProofreadingError.missingPlugin,
      );
    } on PlatformException catch (error) {
      return _availabilityFromPlatformException(error);
    } catch (_) {
      return const KoreanProofreadingAvailability(
        status: KoreanProofreadingStatus.failed,
        error: KoreanProofreadingError.downloadFailed,
      );
    }
  }

  Future<KoreanProofreadingResult> proofread(String originalText) async {
    if (!_isAndroid) {
      return KoreanProofreadingResult(
        status: KoreanProofreadingStatus.unsupportedPlatform,
        originalText: originalText,
        error: KoreanProofreadingError.unavailable,
      );
    }
    if (_closed) {
      return KoreanProofreadingResult(
        status: KoreanProofreadingStatus.unavailable,
        originalText: originalText,
        error: KoreanProofreadingError.unavailable,
      );
    }
    if (_proofreading) {
      return KoreanProofreadingResult(
        status: KoreanProofreadingStatus.busy,
        originalText: originalText,
        error: KoreanProofreadingError.busy,
      );
    }

    final requestText = unorm.nfc(originalText.trim());
    if (requestText.isEmpty || !_containsHangul(requestText)) {
      return KoreanProofreadingResult(
        status: KoreanProofreadingStatus.failed,
        originalText: originalText,
        error: KoreanProofreadingError.invalidInput,
      );
    }
    if (requestText.runes.length > maxInputCodePoints) {
      return KoreanProofreadingResult(
        status: KoreanProofreadingStatus.failed,
        originalText: originalText,
        error: KoreanProofreadingError.inputTooLong,
      );
    }
    if (_hasUnsupportedCharacters(requestText)) {
      return KoreanProofreadingResult(
        status: KoreanProofreadingStatus.failed,
        originalText: originalText,
        error: KoreanProofreadingError.invalidInput,
      );
    }

    _proofreading = true;
    try {
      final response = await _channel
          .invokeMethod<dynamic>('proofread', <String, Object>{
            'text': requestText,
          })
          .timeout(_operationTimeout);
      return _proofreadingResultFromWire(
        response,
        originalText: originalText,
        requestText: requestText,
      );
    } on TimeoutException {
      return KoreanProofreadingResult(
        status: KoreanProofreadingStatus.failed,
        originalText: originalText,
        error: KoreanProofreadingError.timeout,
      );
    } on MissingPluginException {
      return KoreanProofreadingResult(
        status: KoreanProofreadingStatus.featureModuleMissing,
        originalText: originalText,
        error: KoreanProofreadingError.missingPlugin,
      );
    } on PlatformException catch (error) {
      final parsedError = _errorFromWire(error.code);
      return KoreanProofreadingResult(
        status: _statusForError(parsedError),
        originalText: originalText,
        error: parsedError,
        retryAfter: _retryAfterFromDetails(error.details),
      );
    } catch (_) {
      return KoreanProofreadingResult(
        status: KoreanProofreadingStatus.failed,
        originalText: originalText,
        error: KoreanProofreadingError.unknown,
      );
    } finally {
      _proofreading = false;
    }
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    if (!_isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('close').timeout(_operationTimeout);
    } on TimeoutException {
      // Native teardown is bounded so navigation cannot wait indefinitely.
    } on MissingPluginException {
      // The optional feature is legitimately absent on unsupported platforms.
    } on PlatformException {
      // Closing is best-effort and must never break navigation/lifecycle.
    }
  }

  KoreanProofreadingAvailability? _platformFallback() {
    if (_isAndroid) {
      return null;
    }
    return const KoreanProofreadingAvailability(
      status: KoreanProofreadingStatus.unsupportedPlatform,
      error: KoreanProofreadingError.unavailable,
    );
  }
}

KoreanProofreadingAvailability _availabilityFromWire(Object? value) {
  final map = _stringMap(value);
  if (map == null) {
    return const KoreanProofreadingAvailability(
      status: KoreanProofreadingStatus.failed,
      error: KoreanProofreadingError.malformedResponse,
    );
  }
  final status = _statusFromWire(map['status']);
  if (status == null || status == KoreanProofreadingStatus.completed) {
    return const KoreanProofreadingAvailability(
      status: KoreanProofreadingStatus.failed,
      error: KoreanProofreadingError.malformedResponse,
    );
  }
  final error = _errorFromWire(map['error']);
  return KoreanProofreadingAvailability(
    status: status,
    error: error,
    downloadedBytes: _nonNegativeInt(map['downloadedBytes']),
    totalBytes: _nonNegativeInt(map['totalBytes']),
    retryAfter: _durationFromMilliseconds(map['retryAfterMs']),
  );
}

KoreanProofreadingAvailability _availabilityFromPlatformException(
  PlatformException exception,
) {
  final error = _errorFromWire(exception.code);
  return KoreanProofreadingAvailability(
    status: _statusForError(error),
    error: error,
    retryAfter: _retryAfterFromDetails(exception.details),
  );
}

KoreanProofreadingResult _proofreadingResultFromWire(
  Object? value, {
  required String originalText,
  required String requestText,
}) {
  final map = _stringMap(value);
  if (map == null) {
    return KoreanProofreadingResult(
      status: KoreanProofreadingStatus.failed,
      originalText: originalText,
      error: KoreanProofreadingError.malformedResponse,
    );
  }

  final status = _statusFromWire(map['status']);
  final error = _errorFromWire(map['error']);
  if (status != KoreanProofreadingStatus.completed) {
    return KoreanProofreadingResult(
      status: status ?? KoreanProofreadingStatus.failed,
      originalText: originalText,
      error: error == KoreanProofreadingError.none
          ? KoreanProofreadingError.responseRejected
          : error,
      retryAfter: _durationFromMilliseconds(map['retryAfterMs']),
    );
  }
  if (error != KoreanProofreadingError.none ||
      map['isFinal'] != true ||
      map['sourceText'] != requestText) {
    return KoreanProofreadingResult(
      status: KoreanProofreadingStatus.failed,
      originalText: originalText,
      error: KoreanProofreadingError.responseRejected,
    );
  }

  final rawSuggestions = map['suggestions'];
  if (rawSuggestions is! List<Object?> || rawSuggestions.isEmpty) {
    return KoreanProofreadingResult(
      status: KoreanProofreadingStatus.failed,
      originalText: originalText,
      error: KoreanProofreadingError.malformedResponse,
    );
  }

  String? suggestion;
  var sawIrrelevant = false;
  for (final candidate in rawSuggestions) {
    if (candidate is! String) {
      continue;
    }
    final normalized = unorm.nfc(candidate.trim());
    if (normalized.isEmpty ||
        normalized.runes.length >
            KoreanProofreadingService.maxInputCodePoints ||
        !_containsHangul(normalized) ||
        _hasUnsupportedCharacters(normalized)) {
      continue;
    }
    if (!_isRelevantCorrection(requestText, normalized)) {
      sawIrrelevant = true;
      continue;
    }
    suggestion = normalized;
    break;
  }

  if (suggestion == null) {
    return KoreanProofreadingResult(
      status: KoreanProofreadingStatus.failed,
      originalText: originalText,
      error: sawIrrelevant
          ? KoreanProofreadingError.irrelevantResponse
          : KoreanProofreadingError.responseRejected,
    );
  }

  return KoreanProofreadingResult(
    status: KoreanProofreadingStatus.completed,
    originalText: originalText,
    suggestion: suggestion,
    changes: List<KoreanProofreadingChange>.unmodifiable(
      diffKoreanProofreadingTokens(requestText, suggestion),
    ),
  );
}

Map<String, Object?>? _stringMap(Object? value) {
  if (value is! Map) {
    return null;
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      return null;
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

KoreanProofreadingStatus? _statusFromWire(Object? value) {
  if (value is! String) {
    return null;
  }
  return switch (value) {
    'unsupportedPlatform' => KoreanProofreadingStatus.unsupportedPlatform,
    'unsupportedAndroidVersion' =>
      KoreanProofreadingStatus.unsupportedAndroidVersion,
    'featureModuleMissing' => KoreanProofreadingStatus.featureModuleMissing,
    'unavailable' => KoreanProofreadingStatus.unavailable,
    'downloadable' => KoreanProofreadingStatus.downloadable,
    'downloading' => KoreanProofreadingStatus.downloading,
    'available' => KoreanProofreadingStatus.available,
    'checking' => KoreanProofreadingStatus.checking,
    'completed' => KoreanProofreadingStatus.completed,
    'busy' => KoreanProofreadingStatus.busy,
    'quotaExceeded' => KoreanProofreadingStatus.quotaExceeded,
    'backgroundBlocked' => KoreanProofreadingStatus.backgroundBlocked,
    'failed' => KoreanProofreadingStatus.failed,
    _ => null,
  };
}

KoreanProofreadingError _errorFromWire(Object? value) {
  if (value == null || value == 'none') {
    return KoreanProofreadingError.none;
  }
  if (value is! String) {
    return KoreanProofreadingError.unknown;
  }
  return switch (value) {
    'invalidInput' => KoreanProofreadingError.invalidInput,
    'inputTooLong' => KoreanProofreadingError.inputTooLong,
    'missingPlugin' => KoreanProofreadingError.missingPlugin,
    'featureModuleMissing' => KoreanProofreadingError.featureModuleMissing,
    'unavailable' => KoreanProofreadingError.unavailable,
    'downloadFailed' => KoreanProofreadingError.downloadFailed,
    'busy' => KoreanProofreadingError.busy,
    'quotaExceeded' => KoreanProofreadingError.quotaExceeded,
    'backgroundBlocked' => KoreanProofreadingError.backgroundBlocked,
    'notEnoughStorage' => KoreanProofreadingError.notEnoughStorage,
    'systemUpdateNeeded' => KoreanProofreadingError.systemUpdateNeeded,
    'aicoreIncompatible' => KoreanProofreadingError.aicoreIncompatible,
    'requestRejected' => KoreanProofreadingError.requestRejected,
    'responseRejected' => KoreanProofreadingError.responseRejected,
    'irrelevantResponse' => KoreanProofreadingError.irrelevantResponse,
    'malformedResponse' => KoreanProofreadingError.malformedResponse,
    'timeout' => KoreanProofreadingError.timeout,
    _ => KoreanProofreadingError.unknown,
  };
}

KoreanProofreadingStatus _statusForError(KoreanProofreadingError error) {
  return switch (error) {
    KoreanProofreadingError.none => KoreanProofreadingStatus.failed,
    KoreanProofreadingError.missingPlugin ||
    KoreanProofreadingError.featureModuleMissing =>
      KoreanProofreadingStatus.featureModuleMissing,
    KoreanProofreadingError.unavailable => KoreanProofreadingStatus.unavailable,
    KoreanProofreadingError.busy => KoreanProofreadingStatus.busy,
    KoreanProofreadingError.quotaExceeded =>
      KoreanProofreadingStatus.quotaExceeded,
    KoreanProofreadingError.backgroundBlocked =>
      KoreanProofreadingStatus.backgroundBlocked,
    _ => KoreanProofreadingStatus.failed,
  };
}

Duration? _retryAfterFromDetails(Object? details) {
  final map = _stringMap(details);
  return _durationFromMilliseconds(map?['retryAfterMs']);
}

Duration? _durationFromMilliseconds(Object? value) {
  final milliseconds = _nonNegativeInt(value);
  return milliseconds == null ? null : Duration(milliseconds: milliseconds);
}

int? _nonNegativeInt(Object? value) {
  if (value is! num || !value.isFinite || value < 0) {
    return null;
  }
  return value.toInt();
}

bool _containsHangul(String value) => value.runes.any(
  (rune) =>
      (rune >= 0xAC00 && rune <= 0xD7A3) ||
      (rune >= 0x1100 && rune <= 0x11FF) ||
      (rune >= 0x3130 && rune <= 0x318F),
);

bool _hasUnsupportedCharacters(String value) {
  for (final rune in value.runes) {
    if (!_isSupportedProofreadingRune(rune)) {
      return true;
    }
  }
  return false;
}

bool _isSupportedProofreadingRune(int rune) {
  if (rune == 0x09 || rune == 0x0A || rune == 0x0D || rune == 0x20) {
    return true;
  }
  return (rune >= 0x21 && rune <= 0x7E) ||
      (rune >= 0x00C0 && rune <= 0x024F) ||
      (rune >= 0x0300 && rune <= 0x036F) ||
      (rune >= 0x1100 && rune <= 0x11FF) ||
      (rune >= 0x3130 && rune <= 0x318F) ||
      (rune >= 0xA960 && rune <= 0xA97F) ||
      (rune >= 0xAC00 && rune <= 0xD7A3) ||
      (rune >= 0xD7B0 && rune <= 0xD7FF) ||
      _isSafeGeneralPunctuation(rune);
}

bool _isSafeGeneralPunctuation(int rune) {
  if (rune >= 0x2000 && rune <= 0x206F) {
    return !((rune >= 0x200B && rune <= 0x200F) ||
        (rune >= 0x202A && rune <= 0x202E) ||
        (rune >= 0x2060 && rune <= 0x206F));
  }
  return rune >= 0xFF01 && rune <= 0xFF65;
}

bool _isRelevantCorrection(String source, String candidate) {
  final sourceRunes = source.runes.toList(growable: false);
  final candidateRunes = candidate.runes.toList(growable: false);
  if (sourceRunes.isEmpty || candidateRunes.isEmpty) {
    return false;
  }
  final longest = sourceRunes.length > candidateRunes.length
      ? sourceRunes.length
      : candidateRunes.length;
  final shortest = sourceRunes.length < candidateRunes.length
      ? sourceRunes.length
      : candidateRunes.length;
  if (shortest / longest < 0.7) {
    return false;
  }
  final distance = _editDistance(sourceRunes, candidateRunes);
  final similarity = 1 - (distance / longest);
  if (!_hasSameNumericMarkers(source, candidate) ||
      _hasNegativePolarity(source) != _hasNegativePolarity(candidate)) {
    return false;
  }
  final sourceWords = _semanticContentWords(source);
  final candidateWords = _semanticContentWords(candidate);
  if (sourceWords.length != candidateWords.length) {
    if (_withoutWhitespace(source) != _withoutWhitespace(candidate)) {
      return false;
    }
  } else if (sourceWords.length == 1) {
    if (!_isMorphologicallyPreservedWord(
      sourceWords.single,
      candidateWords.single,
    )) {
      return false;
    }
  } else if (sourceWords.length >= 2) {
    for (var index = 0; index < sourceWords.length; index++) {
      if (!_isMorphologicallyPreservedWord(
        sourceWords[index],
        candidateWords[index],
      )) {
        return false;
      }
    }
  }
  if (longest <= 4) {
    return distance <= 1;
  }
  if (similarity < 0.68) {
    return false;
  }
  return true;
}

String _withoutWhitespace(String value) => value.replaceAll(RegExp(r'\s+'), '');

List<String> _contentWords(String value) => _tokenizeForDiff(value)
    .where((token) => token.text.runes.every(_isDiffWordRune))
    .map((token) => token.text.toLowerCase())
    .toList(growable: false);

List<String> _semanticContentWords(String value) => _contentWords(
  value,
).where((word) => !_isOptionalGrammarWord(word)).toList(growable: false);

bool _isOptionalGrammarWord(String word) =>
    const <String>{'거예요', '거에요', '것이에요', '것입니다'}.contains(word);

bool _isMorphologicallyPreservedWord(String source, String candidate) {
  final sourceKey = _koreanMorphologyKey(source);
  final candidateKey = _koreanMorphologyKey(candidate);
  if (sourceKey == candidateKey) {
    return true;
  }
  if (_knownKoreanOrthographyCorrections[sourceKey] == candidateKey) {
    return true;
  }
  return _isPostBatchimTenseSpellingCorrection(sourceKey, candidateKey);
}

bool _isPostBatchimTenseSpellingCorrection(String source, String candidate) {
  final sourceRunes = source.runes.toList(growable: false);
  final candidateRunes = candidate.runes.toList(growable: false);
  if (sourceRunes.length != candidateRunes.length) {
    return false;
  }
  var changedIndex = -1;
  for (var index = 0; index < sourceRunes.length; index++) {
    if (sourceRunes[index] == candidateRunes[index]) {
      continue;
    }
    if (changedIndex != -1) {
      return false;
    }
    changedIndex = index;
  }
  if (changedIndex <= 0) {
    return false;
  }

  final previousOffset = sourceRunes[changedIndex - 1] - 0xAC00;
  final sourceOffset = sourceRunes[changedIndex] - 0xAC00;
  final candidateOffset = candidateRunes[changedIndex] - 0xAC00;
  if (previousOffset < 0 ||
      previousOffset > 0xD7A3 - 0xAC00 ||
      previousOffset % 28 == 0 ||
      sourceOffset < 0 ||
      sourceOffset > 0xD7A3 - 0xAC00 ||
      candidateOffset < 0 ||
      candidateOffset > 0xD7A3 - 0xAC00) {
    return false;
  }

  final sourceInitial = sourceOffset ~/ 588;
  final candidateInitial = candidateOffset ~/ 588;
  final sourceRemainder = sourceOffset % 588;
  final candidateRemainder = candidateOffset % 588;
  return sourceRemainder == candidateRemainder &&
      _plainInitialForTense[sourceInitial] == candidateInitial;
}

const Map<String, String> _knownKoreanOrthographyCorrections = <String, String>{
  '되요': '돼요',
};

const Map<int, int> _plainInitialForTense = <int, int>{
  1: 0,
  4: 3,
  8: 7,
  10: 9,
  13: 12,
};

String _koreanMorphologyKey(String word) {
  var key = _stripKoreanParticles(word);
  for (final ending in _koreanVerbEndings) {
    if (key.endsWith(ending) && key.runes.length - ending.runes.length >= 1) {
      key = key.substring(0, key.length - ending.length);
      break;
    }
  }
  return _irregularKoreanConjugations[key] ?? key;
}

String _stripKoreanParticles(String word) {
  var key = word;
  var stripped = true;
  while (stripped) {
    stripped = false;
    for (final particle in _koreanParticles) {
      if (key.endsWith(particle) &&
          key.runes.length - particle.runes.length >= 2) {
        key = key.substring(0, key.length - particle.length);
        stripped = true;
        break;
      }
    }
  }
  return key;
}

const List<String> _koreanParticles = <String>[
  '으로부터',
  '에게서',
  '한테서',
  '이라도',
  '으로',
  '에서',
  '에게',
  '한테',
  '부터',
  '까지',
  '처럼',
  '보다',
  '하고',
  '라도',
  '이나',
  '이며',
  '이고',
  '께서',
  '의',
  '을',
  '를',
  '이',
  '가',
  '은',
  '는',
  '에',
  '와',
  '과',
  '도',
  '만',
  '로',
];

const List<String> _koreanVerbEndings = <String>[
  '겠어요',
  '이었어요',
  '였어요',
  '이에요',
  '예요',
  '습니다',
  '었어요',
  '았어요',
  '여요',
  '어요',
  '아요',
  '세요',
  '네요',
  '군요',
  '지요',
  '게요',
  '죠',
];

const Map<String, String> _irregularKoreanConjugations = <String, String>{
  '봐': '보',
  '봤': '보',
  '본': '보',
  '볼': '보',
  '보는': '보',
  '해': '하',
  '했': '하',
  '한': '하',
  '할': '하',
  '돼': '되',
  '됐': '되',
  '된': '되',
  '될': '되',
  '와': '오',
  '왔': '오',
  '온': '오',
  '올': '오',
  '줘': '주',
  '줬': '주',
  '준': '주',
  '줄': '주',
};

bool _hasSameNumericMarkers(String source, String candidate) {
  final numberPattern = RegExp(r'\d+(?:[.,]\d+)?');
  final sourceNumbers = numberPattern
      .allMatches(source)
      .map((match) => match.group(0))
      .toList(growable: false);
  final candidateNumbers = numberPattern
      .allMatches(candidate)
      .map((match) => match.group(0))
      .toList(growable: false);
  return listEquals(sourceNumbers, candidateNumbers) &&
      listEquals(
        _koreanNumericMarkers(source),
        _koreanNumericMarkers(candidate),
      );
}

List<String> _koreanNumericMarkers(String value) {
  final words = _contentWords(value);
  final markers = <String>[];
  for (var index = 0; index < words.length; index++) {
    final word = words[index];
    if (_standaloneKoreanNumbers.contains(word)) {
      markers.add(word);
    }
    if (_koreanNumberWords.contains(word) && index + 1 < words.length) {
      final counter = words[index + 1];
      if (_koreanCounters.contains(counter)) {
        markers.add('$word:$counter');
      }
    }
    for (final counter in _koreanCounters) {
      if (!word.endsWith(counter) || word == counter) {
        continue;
      }
      final number = word.substring(0, word.length - counter.length);
      if (_koreanNumberWords.contains(number)) {
        markers.add('$number:$counter');
        break;
      }
    }
  }
  return markers;
}

const Set<String> _koreanNumberWords = <String>{
  '영',
  '공',
  '일',
  '이',
  '삼',
  '사',
  '오',
  '육',
  '칠',
  '팔',
  '구',
  '십',
  '백',
  '천',
  '만',
  '하나',
  '한',
  '둘',
  '두',
  '셋',
  '세',
  '넷',
  '네',
  '다섯',
  '여섯',
  '일곱',
  '여덟',
  '아홉',
  '열',
  '스물',
  '스무',
  '서른',
  '마흔',
  '쉰',
  '예순',
  '일흔',
  '여든',
  '아흔',
};

const Set<String> _standaloneKoreanNumbers = <String>{
  '하나',
  '둘',
  '셋',
  '넷',
  '다섯',
  '여섯',
  '일곱',
  '여덟',
  '아홉',
  '열',
  '스물',
  '서른',
  '마흔',
  '쉰',
  '예순',
  '일흔',
  '여든',
  '아흔',
  '첫째',
  '둘째',
  '셋째',
};

const Set<String> _koreanCounters = <String>{
  '개',
  '명',
  '번',
  '살',
  '시',
  '분',
  '초',
  '권',
  '잔',
  '병',
  '마리',
  '대',
  '장',
  '층',
  '원',
};

bool _hasNegativePolarity(String value) {
  return _contentWords(value).any(
    (word) =>
        word == '안' ||
        word == '못' ||
        word == '절대' ||
        word == '전혀' ||
        word.startsWith('못') ||
        word.startsWith('없') ||
        word.startsWith('아니') ||
        word.startsWith('안되') ||
        word.startsWith('안돼') ||
        word.contains('않'),
  );
}

int _editDistance(List<int> left, List<int> right) {
  var previous = List<int>.generate(right.length + 1, (index) => index);
  for (var i = 1; i <= left.length; i++) {
    final current = List<int>.filled(right.length + 1, 0)..[0] = i;
    for (var j = 1; j <= right.length; j++) {
      final substitution =
          previous[j - 1] + (left[i - 1] == right[j - 1] ? 0 : 1);
      final insertion = current[j - 1] + 1;
      final deletion = previous[j] + 1;
      current[j] = substitution < insertion
          ? (substitution < deletion ? substitution : deletion)
          : (insertion < deletion ? insertion : deletion);
    }
    previous = current;
  }
  return previous.last;
}

/// Computes deterministic, local token-level replacements for UI highlighting.
/// It never calls ML Kit and does not mutate either input.
List<KoreanProofreadingChange> diffKoreanProofreadingTokens(
  String original,
  String suggestion,
) {
  final left = _tokenizeForDiff(original);
  final right = _tokenizeForDiff(suggestion);
  if (left.isEmpty && right.isEmpty) {
    return const <KoreanProofreadingChange>[];
  }

  final lcs = List<List<int>>.generate(
    left.length + 1,
    (_) => List<int>.filled(right.length + 1, 0),
  );
  for (var i = left.length - 1; i >= 0; i--) {
    for (var j = right.length - 1; j >= 0; j--) {
      lcs[i][j] = left[i].text == right[j].text
          ? lcs[i + 1][j + 1] + 1
          : (lcs[i + 1][j] >= lcs[i][j + 1] ? lcs[i + 1][j] : lcs[i][j + 1]);
    }
  }

  final anchors = <(int, int)>[];
  var i = 0;
  var j = 0;
  while (i < left.length && j < right.length) {
    if (left[i].text == right[j].text) {
      anchors.add((i, j));
      i++;
      j++;
    } else if (lcs[i + 1][j] >= lcs[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }

  final changes = <KoreanProofreadingChange>[];
  var leftStart = 0;
  var rightStart = 0;
  for (final anchor in <(int, int)>[...anchors, (left.length, right.length)]) {
    if (leftStart < anchor.$1 || rightStart < anchor.$2) {
      final oldText = _tokenSlice(original, left, leftStart, anchor.$1);
      final newText = _tokenSlice(suggestion, right, rightStart, anchor.$2);
      if (oldText != newText) {
        changes.add(
          KoreanProofreadingChange(
            originalText: oldText,
            replacementText: newText,
          ),
        );
      }
    }
    leftStart = anchor.$1 + 1;
    rightStart = anchor.$2 + 1;
  }
  return changes;
}

class _DiffToken {
  const _DiffToken(this.text, this.start, this.end);

  final String text;
  final int start;
  final int end;
}

List<_DiffToken> _tokenizeForDiff(String value) {
  final tokens = <_DiffToken>[];
  int? wordStart;
  var offset = 0;

  void flushWord(int end) {
    final start = wordStart;
    if (start == null) {
      return;
    }
    tokens.add(_DiffToken(value.substring(start, end), start, end));
    wordStart = null;
  }

  for (final rune in value.runes) {
    final width = rune > 0xFFFF ? 2 : 1;
    if (_isDiffWordRune(rune)) {
      wordStart ??= offset;
    } else {
      flushWord(offset);
      final character = String.fromCharCode(rune);
      tokens.add(_DiffToken(character, offset, offset + width));
    }
    offset += width;
  }
  flushWord(offset);
  return tokens;
}

bool _isDiffWordRune(int rune) =>
    (rune >= 0x30 && rune <= 0x39) ||
    (rune >= 0x41 && rune <= 0x5A) ||
    (rune >= 0x61 && rune <= 0x7A) ||
    (rune >= 0x00C0 && rune <= 0x024F) ||
    (rune >= 0x1100 && rune <= 0x11FF) ||
    (rune >= 0x3130 && rune <= 0x318F) ||
    (rune >= 0xAC00 && rune <= 0xD7A3);

String _tokenSlice(String source, List<_DiffToken> tokens, int start, int end) {
  if (start >= end) {
    return '';
  }
  return _showWhitespace(
    source.substring(tokens[start].start, tokens[end - 1].end),
  );
}

String _showWhitespace(String value) => value
    .replaceAll('\r\n', '↵')
    .replaceAll('\r', '↵')
    .replaceAll('\n', '↵')
    .replaceAll('\t', '⇥')
    .replaceAll(' ', '␠');
