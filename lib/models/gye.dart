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

  /// 누적 달성한 주간 목표 수 (영구). 공동 한옥 영구 unlock 구동.
  /// `weekly_goal_rollover` CF가 100% 달성 시 +1. 주간 리셋과 무관.
  final int lifetimeGoalsAchieved;

  /// 지난 주 70%+ 달성 → 이번 주 XP 부스트 활성 (클라 소비, best-effort).
  final bool xpBoostActive;

  /// 지난주 최다 기여자 (축하 카드용 — `weekly_goal_rollover` CF가 기록).
  /// 경쟁 리더보드가 아니라 1명만, 축하 톤으로 표시한다.
  final String lastWeekMvp;
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
    this.lifetimeGoalsAchieved = 0,
    this.xpBoostActive = false,
    this.lastWeekMvp = '',
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
    lifetimeGoalsAchieved: (d['lifetimeGoalsAchieved'] as num?)?.toInt() ?? 0,
    xpBoostActive: d['xpBoostActive'] as bool? ?? false,
    lastWeekMvp: d['lastWeekMvp'] as String? ?? '',
    lastWeekMvpPacks: (d['lastWeekMvpPacks'] as num?)?.toInt() ?? 0,
  );

  /// 생성 시 Firestore에 쓰는 맵 (createdAt 서버 타임스탬프).
  Map<String, dynamic> toCreateJson() => {
    'name': name,
    'code': code,
    'ownerId': ownerId,
    'memberCount': memberCount,
    'createdAt': FieldValue.serverTimestamp(),
    'weeklyGoalPacks': weeklyGoalPacks,
    'weeklyGoalProgress': weeklyGoalProgress,
    'lifetimeGoalsAchieved': lifetimeGoalsAchieved,
    'xpBoostActive': xpBoostActive,
    if (weeklyGoalEndAt != null)
      'weeklyGoalEndAt': Timestamp.fromDate(weeklyGoalEndAt!),
  };
}

/// `gye/{gyeId}/members/{uid}`.
class GyeMember {
  final String uid;
  final String nickname;
  final DateTime? joinedAt;
  final GyeRole role;
  final int weeklyPacksContributed;
  final GyeMemberStatus status;

  /// 프로필 카드용 denormalize — 본인 클라가 갱신(GyeService.syncMyMemberStats).
  final int level;
  final int streakDays;

  const GyeMember({
    required this.uid,
    required this.nickname,
    this.joinedAt,
    this.role = GyeRole.member,
    this.weeklyPacksContributed = 0,
    this.status = GyeMemberStatus.active,
    this.level = 0,
    this.streakDays = 0,
  });

  factory GyeMember.fromDoc(String uid, Map<String, dynamic> d) => GyeMember(
    uid: uid,
    nickname: d['nickname'] as String? ?? '',
    joinedAt: _ts(d['joinedAt']),
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
