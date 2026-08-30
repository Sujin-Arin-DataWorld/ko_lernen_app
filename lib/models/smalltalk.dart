import 'content_id.dart';

/// Small-talk corpus models (assets/data/smalltalk.json).
class SmalltalkCategory {
  final String id;
  final String emoji;
  final Map<String, String> label; // ko / de / en

  const SmalltalkCategory({
    required this.id,
    required this.emoji,
    required this.label,
  });

  factory SmalltalkCategory.fromJson(Map<String, dynamic> j) =>
      SmalltalkCategory(
        id: j['id'] as String? ?? '',
        emoji: j['emoji'] as String? ?? '💬',
        label: ((j['label'] as Map?) ?? const {}).map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ),
      );

  String labelFor(String lang) =>
      label[lang] ?? label['de'] ?? label['en'] ?? id;
}

/// The social relationship in which a small-talk line is safe to use.
///
/// The JSON uses stable snake-case codes so content can be audited without
/// depending on enum names.
enum SmalltalkRelationshipContext {
  peer,
  classmate,
  coworker,
  closeFriend,
  romanticPartner,
  family,
  service,
}

extension SmalltalkRelationshipContextCode on SmalltalkRelationshipContext {
  String get code {
    switch (this) {
      case SmalltalkRelationshipContext.peer:
        return 'peer';
      case SmalltalkRelationshipContext.classmate:
        return 'classmate';
      case SmalltalkRelationshipContext.coworker:
        return 'coworker';
      case SmalltalkRelationshipContext.closeFriend:
        return 'close_friend';
      case SmalltalkRelationshipContext.romanticPartner:
        return 'romantic_partner';
      case SmalltalkRelationshipContext.family:
        return 'family';
      case SmalltalkRelationshipContext.service:
        return 'service';
    }
  }

  /// Localized, learner-facing relationship cue used before practising a line.
  /// A context is deliberately shown as guidance, not as a rule that a learner
  /// must use informal speech with everyone in that group.
  String labelFor(String lang) {
    final german = lang == 'de';
    switch (this) {
      case SmalltalkRelationshipContext.peer:
        return german ? 'gleichaltrige Bekanntschaft' : 'peer';
      case SmalltalkRelationshipContext.classmate:
        return german ? 'Kursbekanntschaft' : 'classmate';
      case SmalltalkRelationshipContext.coworker:
        return german ? 'Kollegin oder Kollege' : 'coworker';
      case SmalltalkRelationshipContext.closeFriend:
        return german ? 'enge Freundschaft' : 'close friend';
      case SmalltalkRelationshipContext.romanticPartner:
        return german ? 'feste Partnerschaft' : 'romantic partner';
      case SmalltalkRelationshipContext.family:
        return german ? 'Familie' : 'family';
      case SmalltalkRelationshipContext.service:
        return german ? 'Service-Situation' : 'service situation';
    }
  }
}

/// A turn's purpose after the learner has used a small-talk phrase.
enum SmalltalkTurnKind { question, response, reaction }

/// A multilingual continuation turn used for safe alternatives and follow-ups.
class SmalltalkTurn {
  final SmalltalkTurnKind turnKind;
  final String ko;
  final String de;
  final String en;

  const SmalltalkTurn({
    required this.turnKind,
    required this.ko,
    required this.de,
    required this.en,
  });

  bool get isComplete =>
      ko.trim().isNotEmpty && de.trim().isNotEmpty && en.trim().isNotEmpty;

  factory SmalltalkTurn.fromJson(Map<String, dynamic> j) => SmalltalkTurn(
    turnKind: _turnKindFromCode(j['turnKind']) ?? SmalltalkTurnKind.reaction,
    ko: j['ko']?.toString() ?? '',
    de: j['de']?.toString() ?? '',
    en: j['en']?.toString() ?? '',
  );

  /// Returns null for malformed metadata rather than introducing an unsafe or
  /// incomplete turn into the learner-facing graph.
  static SmalltalkTurn? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final turnKind = _turnKindFromCode(raw['turnKind']);
    if (turnKind == null) return null;
    final turn = SmalltalkTurn(
      turnKind: turnKind,
      ko: raw['ko']?.toString() ?? '',
      de: raw['de']?.toString() ?? '',
      en: raw['en']?.toString() ?? '',
    );
    return turn.isComplete ? turn : null;
  }

  String translation(String lang) => lang == 'de' ? de : en;
}

const _peerAlternative = SmalltalkTurn(
  turnKind: SmalltalkTurnKind.question,
  ko: '요즘 어떻게 지내세요?',
  de: "Wie läuft's bei dir so?",
  en: "How've you been?",
);

const _peerFollowUp = SmalltalkTurn(
  turnKind: SmalltalkTurnKind.reaction,
  ko: '그렇군요.',
  de: 'Ach so.',
  en: 'I see.',
);

/// A corpus phrase with its safe relationship context and a next conversation
/// turn. `reply` remains the legacy catch-ball answer for question activities.
class SmalltalkPhrase {
  /// Immutable source identity from `assets/data/smalltalk.json`.
  final String _sourceId;
  final String category;
  final String level; // a1 / a2 / b1 / b2
  final String kind; // opener / question / reaction
  final String ko;
  final String de;
  final String en;

  /// Example answer for the catch-ball exercise (question → answer). Only set
  /// for questions; otherwise null.
  final SmalltalkReply? reply;

  /// Relationship context required to choose a socially safe expression.
  final SmalltalkRelationshipContext relationshipContext;

  /// Safer ways to open the same interaction before using the primary line.
  final List<SmalltalkTurn> safeAlternativeQuestions;

  /// The learner's next useful response or reaction after the primary line.
  final SmalltalkTurn followUp;

  const SmalltalkPhrase({
    String id = '',
    required this.category,
    required this.level,
    required this.kind,
    required this.ko,
    required this.de,
    required this.en,
    this.reply,
    this.relationshipContext = SmalltalkRelationshipContext.peer,
    this.safeAlternativeQuestions = const <SmalltalkTurn>[_peerAlternative],
    this.followUp = _peerFollowUp,
  }) : _sourceId = id;

  /// Source identity stays fixed when educational copy changes. The fallback
  /// supports only old test fixtures that have no `id` field.
  String get id => hasExplicitId
      ? _sourceId.trim()
      : stableContentId('smalltalk_legacy', [category, level, kind, ko]);

  bool get hasExplicitId => _sourceId.trim().isNotEmpty;

  factory SmalltalkPhrase.fromJson(Map<String, dynamic> j) {
    final category = j['category'] as String? ?? '';
    final relationshipContext =
        _relationshipContextFromCode(j['relationshipContext']) ??
        _defaultRelationshipContext(category);
    final alternatives = _safeAlternativeQuestions(
      j['safeAlternativeQuestions'],
      relationshipContext,
    );
    final followUp =
        SmalltalkTurn.tryFromJson(j['followUp']) ??
        _defaultFollowUp(relationshipContext);

    return SmalltalkPhrase(
      id: j['id']?.toString() ?? '',
      category: category,
      level: j['level'] as String? ?? 'a1',
      kind: j['kind'] as String? ?? 'opener',
      ko: j['ko'] as String? ?? '',
      de: j['de'] as String? ?? '',
      en: j['en'] as String? ?? '',
      reply: j['reply'] is Map<String, dynamic>
          ? SmalltalkReply.fromJson(j['reply'] as Map<String, dynamic>)
          : null,
      relationshipContext: relationshipContext,
      safeAlternativeQuestions: alternatives,
      followUp: followUp,
    );
  }

  /// Translation for the UI language ('de' means German; all other values use
  /// the English fallback).
  String translation(String lang) => lang == 'de' ? de : en;
}

List<SmalltalkTurn> _safeAlternativeQuestions(
  Object? raw,
  SmalltalkRelationshipContext relationshipContext,
) {
  if (raw is List) {
    final alternatives = raw
        .map(SmalltalkTurn.tryFromJson)
        .whereType<SmalltalkTurn>()
        .where((turn) => turn.turnKind == SmalltalkTurnKind.question)
        .toList(growable: false);
    if (alternatives.isNotEmpty) return alternatives;
  }
  return <SmalltalkTurn>[_defaultAlternative(relationshipContext)];
}

SmalltalkRelationshipContext _defaultRelationshipContext(String category) {
  switch (category) {
    case 'work_study':
      return SmalltalkRelationshipContext.coworker;
    case 'family':
      return SmalltalkRelationshipContext.family;
    case 'hospital':
      return SmalltalkRelationshipContext.service;
    case 'dating':
      return SmalltalkRelationshipContext.closeFriend;
    case 'theme_park_date':
      return SmalltalkRelationshipContext.romanticPartner;
    default:
      return SmalltalkRelationshipContext.peer;
  }
}

SmalltalkRelationshipContext? _relationshipContextFromCode(Object? raw) {
  switch (raw?.toString()) {
    case 'peer':
      return SmalltalkRelationshipContext.peer;
    case 'classmate':
      return SmalltalkRelationshipContext.classmate;
    case 'coworker':
      return SmalltalkRelationshipContext.coworker;
    case 'close_friend':
      return SmalltalkRelationshipContext.closeFriend;
    case 'romantic_partner':
      return SmalltalkRelationshipContext.romanticPartner;
    case 'family':
      return SmalltalkRelationshipContext.family;
    case 'service':
      return SmalltalkRelationshipContext.service;
    default:
      return null;
  }
}

SmalltalkTurnKind? _turnKindFromCode(Object? raw) {
  switch (raw?.toString()) {
    case 'question':
      return SmalltalkTurnKind.question;
    case 'response':
      return SmalltalkTurnKind.response;
    case 'reaction':
      return SmalltalkTurnKind.reaction;
    default:
      return null;
  }
}

SmalltalkTurn _defaultAlternative(
  SmalltalkRelationshipContext relationshipContext,
) {
  switch (relationshipContext) {
    case SmalltalkRelationshipContext.peer:
      return _peerAlternative;
    case SmalltalkRelationshipContext.classmate:
      return const SmalltalkTurn(
        turnKind: SmalltalkTurnKind.question,
        ko: '수업은 어때요?',
        de: 'Wie läuft der Kurs?',
        en: 'How is the class going?',
      );
    case SmalltalkRelationshipContext.coworker:
      return const SmalltalkTurn(
        turnKind: SmalltalkTurnKind.question,
        ko: '요즘 일은 어때요?',
        de: 'Wie läuft die Arbeit gerade?',
        en: "How's work been?",
      );
    case SmalltalkRelationshipContext.closeFriend:
      return const SmalltalkTurn(
        turnKind: SmalltalkTurnKind.question,
        ko: '요즘 어떻게 지내?',
        de: "Wie läuft's bei dir so?",
        en: "How've you been?",
      );
    case SmalltalkRelationshipContext.romanticPartner:
      return const SmalltalkTurn(
        turnKind: SmalltalkTurnKind.question,
        ko: '우리 뭐부터 할까?',
        de: 'Womit wollen wir anfangen?',
        en: 'What should we do first?',
      );
    case SmalltalkRelationshipContext.family:
      return const SmalltalkTurn(
        turnKind: SmalltalkTurnKind.question,
        ko: '요즘 잘 지내?',
        de: "Läuft's bei dir?",
        en: 'You doing alright?',
      );
    case SmalltalkRelationshipContext.service:
      return const SmalltalkTurn(
        turnKind: SmalltalkTurnKind.question,
        ko: '필요하신 점이 있으세요?',
        de: 'Kann ich Ihnen bei etwas helfen?',
        en: 'Is there anything I can help you with?',
      );
  }
}

SmalltalkTurn _defaultFollowUp(
  SmalltalkRelationshipContext relationshipContext,
) {
  switch (relationshipContext) {
    case SmalltalkRelationshipContext.peer:
    case SmalltalkRelationshipContext.classmate:
    case SmalltalkRelationshipContext.coworker:
      return _peerFollowUp;
    case SmalltalkRelationshipContext.closeFriend:
    case SmalltalkRelationshipContext.romanticPartner:
    case SmalltalkRelationshipContext.family:
      return const SmalltalkTurn(
        turnKind: SmalltalkTurnKind.reaction,
        ko: '아, 그렇구나.',
        de: 'Ach so.',
        en: 'Oh, I see.',
      );
    case SmalltalkRelationshipContext.service:
      return const SmalltalkTurn(
        turnKind: SmalltalkTurnKind.response,
        ko: '네, 알겠습니다.',
        de: 'Ja, verstanden.',
        en: 'Yes, I understand.',
      );
  }
}

/// Example answer for the catch-ball exercise (question → answer).
class SmalltalkReply {
  final String ko;
  final String de;
  final String en;
  const SmalltalkReply({required this.ko, required this.de, required this.en});

  factory SmalltalkReply.fromJson(Map<String, dynamic> j) => SmalltalkReply(
    ko: j['ko'] as String? ?? '',
    de: j['de'] as String? ?? '',
    en: j['en'] as String? ?? '',
  );

  String translation(String lang) => lang == 'de' ? de : en;
}
