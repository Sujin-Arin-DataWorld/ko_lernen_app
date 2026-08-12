/// 한 팩의 사용자 진행도. Firestore `users/{uid}/packs/{packId}` 문서 모델.
///
/// **로컬 SoT 원칙**: `Storage` (SharedPreferences) 가 학습 중 source of truth,
/// `FirestoreProgressService` 가 백업·복원 채널이다. PackProgress 객체는
/// 두 채널 모두에서 사용 가능한 plain DTO.
enum PackStatus {
  /// 아직 잠금. 직전 팩 클리어 시 unlock.
  locked,

  /// 잠금 해제됨. 한 번도 시작 안 함.
  available,

  /// 시작했지만 미완료 (보스 단어 정답률 70% 미만 또는 아직 도전 안 함).
  inProgress,

  /// 보스 단어 정답률 ≥ 70% — 클리어 도장 획득.
  cleared;

  String toJsonValue() => name; // enum → string
  static PackStatus fromJsonValue(String? v) {
    if (v == null) return PackStatus.locked;
    return PackStatus.values.firstWhere(
      (s) => s.name == v,
      orElse: () => PackStatus.locked,
    );
  }
}

class PackProgress {
  final String packId;
  final String level; // 'A1' / 'A2' / 'B1' / 'B2'
  final PackStatus status;

  /// 학습 완료한 단어 수 (학습 1회 = "본 단어"). 0..wordsTotal.
  final int wordsLearned;

  /// 팩 내 총 단어 수 (캐싱용 — pack 정의에서 다시 lookup 가능).
  final int wordsTotal;

  /// 마지막 보스 라운드 정답률 0.0..1.0. 미도전 = 0.0.
  final double bossAccuracy;

  /// 보스 라운드 도전 횟수.
  final int attempts;

  /// 처음 클리어한 시각 (ISO-8601, 'YYYY-MM-DDTHH:MM:SS' UTC). null = 미클리어.
  final String? clearedAtIso;

  const PackProgress({
    required this.packId,
    required this.level,
    required this.status,
    required this.wordsLearned,
    required this.wordsTotal,
    required this.bossAccuracy,
    required this.attempts,
    required this.clearedAtIso,
  });

  /// 신규 팩 (잠금 해제됨, 미시작).
  factory PackProgress.fresh({
    required String packId,
    required String level,
    required int wordsTotal,
    PackStatus status = PackStatus.available,
  }) => PackProgress(
    packId: packId,
    level: level,
    status: status,
    wordsLearned: 0,
    wordsTotal: wordsTotal,
    bossAccuracy: 0.0,
    attempts: 0,
    clearedAtIso: null,
  );

  PackProgress copyWith({
    PackStatus? status,
    int? wordsLearned,
    int? wordsTotal,
    double? bossAccuracy,
    int? attempts,
    String? clearedAtIso,
    bool clearClearedAt = false,
  }) => PackProgress(
    packId: packId,
    level: level,
    status: status ?? this.status,
    wordsLearned: wordsLearned ?? this.wordsLearned,
    wordsTotal: wordsTotal ?? this.wordsTotal,
    bossAccuracy: bossAccuracy ?? this.bossAccuracy,
    attempts: attempts ?? this.attempts,
    clearedAtIso: clearClearedAt ? null : (clearedAtIso ?? this.clearedAtIso),
  );

  Map<String, dynamic> toJson() => {
    'level': level,
    'status': status.toJsonValue(),
    'wordsLearned': wordsLearned,
    'wordsTotal': wordsTotal,
    'bossAccuracy': bossAccuracy,
    'attempts': attempts,
    'clearedAt': clearedAtIso,
  };

  factory PackProgress.fromJson(String packId, Map<String, dynamic> j) =>
      PackProgress(
        packId: packId,
        level: (j['level'] as String?) ?? '',
        status: PackStatus.fromJsonValue(j['status'] as String?),
        wordsLearned: (j['wordsLearned'] as num?)?.toInt() ?? 0,
        wordsTotal: (j['wordsTotal'] as num?)?.toInt() ?? 0,
        bossAccuracy: (j['bossAccuracy'] as num?)?.toDouble() ?? 0.0,
        attempts: (j['attempts'] as num?)?.toInt() ?? 0,
        clearedAtIso: j['clearedAt'] as String?,
      );

  bool get isCleared => status == PackStatus.cleared;
  bool get isUnlocked => status != PackStatus.locked;
  double get progressFraction =>
      wordsTotal == 0 ? 0.0 : (wordsLearned / wordsTotal).clamp(0.0, 1.0);
}
