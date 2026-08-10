import 'package:cloud_firestore/cloud_firestore.dart';

/// 계(契) 데이터 모델 — `docs/plans/stately-rising-jongga.md` §7.2 스키마.
///
/// Firestore: `gye/{gyeId}` (gyeId == 입장 코드) + 하위
///   `members/{uid}` · `feed/{eventId}` · `stickers/{id}` · `reports/{id}`.

enum GyeRole { owner, member }

enum GyeMemberStatus { active, reported, suspended }

enum GyeFeedType {
  packCleared,
  questCompleted,
  levelUp,
  goalAchieved,
  allInChallenge, // 전원 기여 챌린지 달성 (D-4)
  sticker,
  cheer,
}

enum GyeReportReason { spam, inappropriate, harassment, other }

/// snake_case wire 값 ↔ enum (Firestore 저장값).
extension GyeFeedTypeWire on GyeFeedType {
  String get wire => switch (this) {
    GyeFeedType.packCleared => 'pack_cleared',
    GyeFeedType.questCompleted => 'quest_completed',
    GyeFeedType.levelUp => 'level_up',
    GyeFeedType.goalAchieved => 'goal_achieved',
    GyeFeedType.allInChallenge => 'all_in',
    GyeFeedType.sticker => 'sticker',
    GyeFeedType.cheer => 'cheer',
  };
  static GyeFeedType fromWire(String? s) => switch (s) {
    'pack_cleared' => GyeFeedType.packCleared,
    'quest_completed' => GyeFeedType.questCompleted,
    'level_up' => GyeFeedType.levelUp,
    'goal_achieved' => GyeFeedType.goalAchieved,
    'all_in' => GyeFeedType.allInChallenge,
    'cheer' => GyeFeedType.cheer,
    _ => GyeFeedType.sticker,
  };
}

DateTime? _ts(Object? v) =>
    v is Timestamp ? v.toDate() : (v is String ? DateTime.tryParse(v) : null);

/// The immutable identity of one membership generation.
///
/// A [DateTime] cannot carry Firestore's nanosecond component, so mutations
/// that must distinguish a leave/rejoin generation keep the authoritative
/// timestamp as its original seconds/nanoseconds pair instead.
class GyeMembershipEpoch {
  factory GyeMembershipEpoch({required int seconds, required int nanoseconds}) {
    if (!isValidParts(seconds, nanoseconds)) {
      throw ArgumentError.value(
        (seconds: seconds, nanoseconds: nanoseconds),
        'GyeMembershipEpoch',
        'must be a server-compatible Firestore timestamp pair',
      );
    }
    return GyeMembershipEpoch._(seconds, nanoseconds);
  }

  const GyeMembershipEpoch._(this.seconds, this.nanoseconds);

  /// JavaScript callable payloads require exact safe integers. The Firestore
  /// [Timestamp] parser below is stricter still, but this protects each
  /// primitive-payload boundary too.
  static const int _maxSafeInteger = 9007199254740991;

  final int seconds;
  final int nanoseconds;

  static bool isValidParts(int seconds, int nanoseconds) =>
      seconds >= 0 &&
      seconds <= _maxSafeInteger &&
      nanoseconds >= 0 &&
      nanoseconds < 1000000000;

  /// Accepts only a Firestore [Timestamp], never a lossy [DateTime] or wire
  /// string. Missing/legacy timestamps deliberately have no usable epoch.
  static GyeMembershipEpoch? tryParse(Object? value) {
    if (value is! Timestamp ||
        !isValidParts(value.seconds, value.nanoseconds)) {
      return null;
    }
    return GyeMembershipEpoch._(value.seconds, value.nanoseconds);
  }

  /// Rehydrates the exact primitive representation used in callable payloads
  /// and public dedication documents without accepting numeric coercion.
  static GyeMembershipEpoch? tryFromParts(
    Object? seconds,
    Object? nanoseconds,
  ) {
    if (seconds is! int ||
        nanoseconds is! int ||
        !isValidParts(seconds, nanoseconds)) {
      return null;
    }
    return GyeMembershipEpoch._(seconds, nanoseconds);
  }

  @override
  bool operator ==(Object other) =>
      other is GyeMembershipEpoch &&
      other.seconds == seconds &&
      other.nanoseconds == nanoseconds;

  @override
  int get hashCode => Object.hash(seconds, nanoseconds);
}

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final e in values) {
    if (e.name == name) {
      return e;
    }
  }
  return fallback;
}

/// `gye/{gyeId}` 메타 문서.
class GyeMeta {
  final String id; // == code (doc id)
  final String name;
  final String code;
  final String ownerId;
  final int memberCount;
  final DateTime? createdAt;
  final int weeklyGoalPacks;
  final DateTime? weeklyGoalEndAt;
  final int weeklyGoalProgress;

  /// A v1 life-situation promise. Legacy groups leave [weeklyPromiseId] empty
  /// and retain their existing pack-goal presentation unchanged.
  final int weeklyPromiseSchemaVersion;
  final String weeklyPromiseId;
  final int weeklyPromiseTarget;
  final int weeklyPromiseProgress;
  final String weeklyPromiseWeekKey;

  /// 누적 달성한 주간 목표 수 (영구). 공동 한옥 영구 unlock 구동.
  /// `weekly_goal_rollover` CF가 100% 달성 시 +1. 주간 리셋과 무관.
  final int lifetimeGoalsAchieved;

  /// 지난 주 70%+ 달성 → 이번 주 XP 부스트 활성 (클라 소비, best-effort).
  final bool xpBoostActive;

  /// 지난주 최다 기여자 (축하 카드용 — `weekly_goal_rollover` CF가 기록).
  /// 경쟁 리더보드가 아니라 1명만, 축하 톤으로 표시한다.
  final String lastWeekMvp;
  final String lastWeekMvpUid;
  final int lastWeekMvpPacks;

  const GyeMeta({
    required this.id,
    required this.name,
    required this.code,
    required this.ownerId,
    this.memberCount = 1,
    this.createdAt,
    this.weeklyGoalPacks = 0,
    this.weeklyGoalEndAt,
    this.weeklyGoalProgress = 0,
    this.weeklyPromiseSchemaVersion = 0,
    this.weeklyPromiseId = '',
    this.weeklyPromiseTarget = 0,
    this.weeklyPromiseProgress = 0,
    this.weeklyPromiseWeekKey = '',
    this.lifetimeGoalsAchieved = 0,
    this.xpBoostActive = false,
    this.lastWeekMvp = '',
    this.lastWeekMvpUid = '',
    this.lastWeekMvpPacks = 0,
  });

  factory GyeMeta.fromDoc(String id, Map<String, dynamic> d) => GyeMeta(
    id: id,
    name: d['name'] as String? ?? '',
    code: d['code'] as String? ?? id,
    ownerId: d['ownerId'] as String? ?? '',
    memberCount: (d['memberCount'] as num?)?.toInt() ?? 1,
    createdAt: _ts(d['createdAt']),
    weeklyGoalPacks: (d['weeklyGoalPacks'] as num?)?.toInt() ?? 0,
    weeklyGoalEndAt: _ts(d['weeklyGoalEndAt']),
    weeklyGoalProgress: (d['weeklyGoalProgress'] as num?)?.toInt() ?? 0,
    weeklyPromiseSchemaVersion:
        (d['weeklyPromiseSchemaVersion'] as num?)?.toInt() ?? 0,
    weeklyPromiseId: d['weeklyPromiseId'] as String? ?? '',
    weeklyPromiseTarget: (d['weeklyPromiseTarget'] as num?)?.toInt() ?? 0,
    weeklyPromiseProgress: (d['weeklyPromiseProgress'] as num?)?.toInt() ?? 0,
    weeklyPromiseWeekKey: d['weeklyPromiseWeekKey'] as String? ?? '',
    lifetimeGoalsAchieved: (d['lifetimeGoalsAchieved'] as num?)?.toInt() ?? 0,
    xpBoostActive: d['xpBoostActive'] as bool? ?? false,
    lastWeekMvp: d['lastWeekMvp'] as String? ?? '',
    lastWeekMvpUid: d['lastWeekMvpUid'] as String? ?? '',
    lastWeekMvpPacks: (d['lastWeekMvpPacks'] as num?)?.toInt() ?? 0,
  );

  /// 생성 시 Firestore에 쓰는 맵 (createdAt 서버 타임스탬프).
  Map<String, dynamic> toCreateJson() => {
    'name': name,
    'code': code,
    'ownerId': ownerId,
    'memberCount': memberCount,
    'lifecycleState': 'active',
    'createdAt': FieldValue.serverTimestamp(),
    'weeklyGoalPacks': weeklyGoalPacks,
    'weeklyGoalProgress': weeklyGoalProgress,
    if (weeklyPromiseSchemaVersion > 0 && weeklyPromiseId.isNotEmpty) ...{
      'weeklyPromiseSchemaVersion': weeklyPromiseSchemaVersion,
      'weeklyPromiseId': weeklyPromiseId,
      'weeklyPromiseTarget': weeklyPromiseTarget,
      'weeklyPromiseProgress': weeklyPromiseProgress,
      'weeklyPromiseWeekKey': weeklyPromiseWeekKey,
    },
    'lifetimeGoalsAchieved': lifetimeGoalsAchieved,
    'xpBoostActive': xpBoostActive,
    if (weeklyGoalEndAt != null)
      'weeklyGoalEndAt': Timestamp.fromDate(weeklyGoalEndAt!),
  };
}

/// `gye/{gyeId}/members/{uid}`.
class GyeMember {
  final String uid;
  final String membershipId;
  final String nickname;
  final DateTime? joinedAt;

  /// Exact Firestore join instant used to bind mutation requests to one
  /// membership generation. A missing value means the member is legacy and
  /// cannot authorize generation-sensitive actions.
  final GyeMembershipEpoch? joinedAtEpoch;
  final GyeRole role;
  final int weeklyPacksContributed;
  final GyeMemberStatus status;

  /// 프로필 카드용 denormalize — 본인 클라가 갱신(GyeService.syncMyMemberStats).
  final int level;
  final int streakDays;

  const GyeMember({
    required this.uid,
    required this.nickname,
    this.membershipId = 'legacy',
    this.joinedAt,
    this.joinedAtEpoch,
    this.role = GyeRole.member,
    this.weeklyPacksContributed = 0,
    this.status = GyeMemberStatus.active,
    this.level = 0,
    this.streakDays = 0,
  });

  factory GyeMember.fromDoc(String uid, Map<String, dynamic> d) => GyeMember(
    uid: uid,
    membershipId: d['membershipId'] as String? ?? 'legacy',
    nickname: d['nickname'] as String? ?? '',
    joinedAt: _ts(d['joinedAt']),
    joinedAtEpoch: GyeMembershipEpoch.tryParse(d['joinedAt']),
    role: _enumByName(GyeRole.values, d['role'], GyeRole.member),
    weeklyPacksContributed: (d['weeklyPacksContributed'] as num?)?.toInt() ?? 0,
    status: _enumByName(
      GyeMemberStatus.values,
      d['status'],
      GyeMemberStatus.active,
    ),
    level: (d['level'] as num?)?.toInt() ?? 0,
    streakDays: (d['streakDays'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toCreateJson() => {
    'uid': uid,
    'membershipId': membershipId,
    'nickname': nickname,
    'joinedAt': FieldValue.serverTimestamp(),
    'role': role.name,
    'weeklyPacksContributed': weeklyPacksContributed,
    'status': status.name,
    'level': level,
    'streakDays': streakDays,
  };
}

/// `gye/{gyeId}/feed/{eventId}` — 도장 획득·승급 등 이벤트.
class GyeFeedEvent {
  final String id;
  final GyeFeedType type;
  final String actorUid;
  final String actorNickname;
  final Map<String, dynamic> payload;
  final DateTime? createdAt;

  const GyeFeedEvent({
    required this.id,
    required this.type,
    required this.actorUid,
    required this.actorNickname,
    this.payload = const {},
    this.createdAt,
  });

  factory GyeFeedEvent.fromDoc(String id, Map<String, dynamic> d) =>
      GyeFeedEvent(
        id: id,
        type: GyeFeedTypeWire.fromWire(d['type'] as String?),
        actorUid: d['actorUid'] as String? ?? '',
        actorNickname: d['actorNickname'] as String? ?? '',
        payload: (d['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
        createdAt: _ts(d['createdAt']),
      );

  Map<String, dynamic> toCreateJson() => {
    'type': type.wire,
    'actorUid': actorUid,
    'actorNickname': actorNickname,
    'payload': payload,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

/// `gye/{gyeId}/stickers/{id}` — 스티커 메시지 (stickerCode 1~30).
class GyeSticker {
  final String id;
  final String senderUid;
  final String senderNickname;
  final int stickerCode;
  final String? targetEventId;
  final DateTime? createdAt;

  const GyeSticker({
    required this.id,
    required this.senderUid,
    required this.senderNickname,
    required this.stickerCode,
    this.targetEventId,
    this.createdAt,
  });

  factory GyeSticker.fromDoc(String id, Map<String, dynamic> d) => GyeSticker(
    id: id,
    senderUid: d['senderUid'] as String? ?? '',
    senderNickname: d['senderNickname'] as String? ?? '',
    stickerCode: (d['stickerCode'] as num?)?.toInt() ?? 1,
    targetEventId: d['targetEventId'] as String?,
    createdAt: _ts(d['createdAt']),
  );

  Map<String, dynamic> toCreateJson() => {
    'senderUid': senderUid,
    'senderNickname': senderNickname,
    'stickerCode': stickerCode,
    'targetEventId': targetEventId,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

/// `gye/{gyeId}/reports/{id}` — 신고.
class GyeReport {
  final String id;
  final String reporterUid;
  final String targetUid;
  final GyeReportReason reason;
  final String note;
  final DateTime? createdAt;
  final String status; // pending | reviewed | dismissed

  const GyeReport({
    required this.id,
    required this.reporterUid,
    required this.targetUid,
    required this.reason,
    this.note = '',
    this.createdAt,
    this.status = 'pending',
  });

  /// One report per membership pair bounds server moderation reads. The report
  /// is deleted when either member leaves, so a later membership can start a
  /// fresh moderation generation.
  static String documentIdFor({
    required String targetUid,
    required String reporterUid,
  }) => '${targetUid}_$reporterUid';

  factory GyeReport.fromDoc(String id, Map<String, dynamic> d) => GyeReport(
    id: id,
    reporterUid: d['reporterUid'] as String? ?? '',
    targetUid: d['targetUid'] as String? ?? '',
    reason: _enumByName(
      GyeReportReason.values,
      d['reason'],
      GyeReportReason.other,
    ),
    note: d['note'] as String? ?? '',
    createdAt: _ts(d['createdAt']),
    status: d['status'] as String? ?? 'pending',
  );

  Map<String, dynamic> toCreateJson() => {
    'reporterUid': reporterUid,
    'targetUid': targetUid,
    'reason': reason.name,
    'note': note,
    'createdAt': FieldValue.serverTimestamp(),
    'status': status,
    'reviewedBy': null,
    'actionTaken': null,
  };
}
