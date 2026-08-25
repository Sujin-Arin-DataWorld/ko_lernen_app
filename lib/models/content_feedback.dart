const int contentFeedbackSchemaVersion = 1;
const int contentFeedbackMaxMessageLength = 1000;

enum FeedbackCategory { bug, content, other }

enum FeedbackIssueArea { ui, answer, audio, translation, navigation, other }

enum FeedbackContentSignal { tooEasy, right, tooHard, unclear }

enum FeedbackContentFocus {
  explanation,
  examples,
  questions,
  pace,
  audio,
  translation,
  other,
}

enum FeedbackBugFrequency { everyTime, sometimes, once }

enum FeedbackBugImpact { canContinue, slowsLearning, blocksLearning }

enum FeedbackExperienceSignal { positive, mixed, negative, unsure }

enum FeedbackExperienceFocus {
  koreanText,
  wordMeanings,
  grammar,
  translation,
  resultMissing,
  goal,
  difficulty,
  reward,
  instructions,
  length,
  timing,
  visuals,
  message,
  frequency,
  other,
}

extension FeedbackCategoryWire on FeedbackCategory {
  String get wireName => name;
}

extension FeedbackIssueAreaWire on FeedbackIssueArea {
  String get wireName => name;
}

extension FeedbackContentSignalWire on FeedbackContentSignal {
  String get wireName => switch (this) {
    FeedbackContentSignal.tooEasy => 'too_easy',
    FeedbackContentSignal.right => 'right',
    FeedbackContentSignal.tooHard => 'too_hard',
    FeedbackContentSignal.unclear => 'unclear',
  };
}

extension FeedbackContentFocusWire on FeedbackContentFocus {
  String get wireName => name;
}

extension FeedbackBugFrequencyWire on FeedbackBugFrequency {
  String get wireName => switch (this) {
    FeedbackBugFrequency.everyTime => 'every_time',
    FeedbackBugFrequency.sometimes => 'sometimes',
    FeedbackBugFrequency.once => 'once',
  };
}

extension FeedbackBugImpactWire on FeedbackBugImpact {
  String get wireName => switch (this) {
    FeedbackBugImpact.canContinue => 'can_continue',
    FeedbackBugImpact.slowsLearning => 'slows_learning',
    FeedbackBugImpact.blocksLearning => 'blocks_learning',
  };
}

extension FeedbackExperienceSignalWire on FeedbackExperienceSignal {
  String get wireName => name;
}

extension FeedbackExperienceFocusWire on FeedbackExperienceFocus {
  String get wireName => switch (this) {
    FeedbackExperienceFocus.koreanText => 'korean_text',
    FeedbackExperienceFocus.wordMeanings => 'word_meanings',
    FeedbackExperienceFocus.grammar => 'grammar',
    FeedbackExperienceFocus.translation => 'translation',
    FeedbackExperienceFocus.resultMissing => 'result_missing',
    FeedbackExperienceFocus.goal => 'goal',
    FeedbackExperienceFocus.difficulty => 'difficulty',
    FeedbackExperienceFocus.reward => 'reward',
    FeedbackExperienceFocus.instructions => 'instructions',
    FeedbackExperienceFocus.length => 'length',
    FeedbackExperienceFocus.timing => 'timing',
    FeedbackExperienceFocus.visuals => 'visuals',
    FeedbackExperienceFocus.message => 'message',
    FeedbackExperienceFocus.frequency => 'frequency',
    FeedbackExperienceFocus.other => 'other',
  };
}

class ContentFeedbackValidationResult {
  const ContentFeedbackValidationResult(this.errors);

  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

class ContentFeedbackContext {
  const ContentFeedbackContext({
    required this.completionId,
    required this.contentType,
    required this.contentId,
    required this.contentLabel,
    this.level,
    required this.scoreSummary,
  });

  final String completionId;
  final String contentType;
  final String contentId;
  final String contentLabel;
  final String? level;
  final String scoreSummary;

  ContentFeedbackValidationResult validate() {
    final errors = <String>[];
    if (_isBlank(completionId) ||
        completionId.length > 64 ||
        completionId.contains('/') ||
        completionId == '.' ||
        completionId == '..') {
      errors.add('completionId');
    }
    if (_isBlank(contentType) || contentType.length > 48) {
      errors.add('contentType');
    }
    if (_isBlank(contentId) || contentId.length > 128) {
      errors.add('contentId');
    }
    if (contentLabel.length > 120) errors.add('contentLabel');
    if (level != null &&
        !const {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'}.contains(level)) {
      errors.add('level');
    }
    if (scoreSummary.length > 64) errors.add('scoreSummary');
    return ContentFeedbackValidationResult(List.unmodifiable(errors));
  }

  Map<String, Object?> toWire() => {
    'completionId': completionId,
    'contentType': contentType,
    'contentId': contentId,
    'contentLabel': contentLabel,
    if (level != null) 'level': level,
    'scoreSummary': scoreSummary,
  };
}

class ContentFeedbackDraft {
  const ContentFeedbackDraft({
    required this.category,
    this.message = '',
    this.issueArea,
    this.contentSignal,
    this.contentFocus,
    this.expectedOutcome,
    this.actualOutcome,
    this.bugFrequency,
    this.bugImpact,
    this.experienceSignal,
    this.experienceFocus,
  });

  final FeedbackCategory category;
  final String message;
  final FeedbackIssueArea? issueArea;
  final FeedbackContentSignal? contentSignal;
  final FeedbackContentFocus? contentFocus;
  final String? expectedOutcome;
  final String? actualOutcome;
  final FeedbackBugFrequency? bugFrequency;
  final FeedbackBugImpact? bugImpact;
  final FeedbackExperienceSignal? experienceSignal;
  final FeedbackExperienceFocus? experienceFocus;

  ContentFeedbackValidationResult validate() {
    final errors = <String>[];
    if (message.length > contentFeedbackMaxMessageLength) {
      errors.add('message');
    }

    final hasStructuredBugField =
        (expectedOutcome?.isNotEmpty ?? false) ||
        (actualOutcome?.isNotEmpty ?? false) ||
        bugFrequency != null ||
        bugImpact != null;
    final hasLearningField = contentSignal != null || contentFocus != null;
    final hasExperienceField =
        experienceSignal != null || experienceFocus != null;

    switch (category) {
      case FeedbackCategory.bug:
        if (!hasStructuredBugField && _isBlank(message)) {
          errors.add('messageRequired');
        }
        if (hasStructuredBugField &&
            (issueArea == null ||
                expectedOutcome == null ||
                _isBlank(expectedOutcome!) ||
                actualOutcome == null ||
                _isBlank(actualOutcome!) ||
                bugFrequency == null ||
                bugImpact == null ||
                expectedOutcome!.length > 500 ||
                actualOutcome!.length > 500)) {
          errors.add('structuredBug');
        }
        if (hasLearningField) errors.add('contentFields');
        if (hasExperienceField) errors.add('experienceFields');
      case FeedbackCategory.other:
        if (_isBlank(message)) errors.add('messageRequired');
        if (issueArea != null ||
            expectedOutcome != null ||
            actualOutcome != null ||
            bugFrequency != null ||
            bugImpact != null) {
          errors.add('bugFields');
        }
        if (hasLearningField) errors.add('contentFields');
        if (hasExperienceField) errors.add('experienceFields');
      case FeedbackCategory.content:
        if (issueArea != null) {
          errors.add('issueArea');
        }
        if (expectedOutcome != null ||
            actualOutcome != null ||
            bugFrequency != null ||
            bugImpact != null) {
          errors.add('bugFields');
        }
        if (hasLearningField && hasExperienceField) {
          errors.add('mixedFeedbackFields');
        }
        if ((experienceSignal == null) != (experienceFocus == null)) {
          errors.add('experienceFields');
        }
        if (!hasLearningField && !hasExperienceField && _isBlank(message)) {
          errors.add('contentFeedbackRequired');
        }
    }

    return ContentFeedbackValidationResult(List.unmodifiable(errors));
  }

  Map<String, Object?> toWire() => {
    'category': category.wireName,
    'message': message,
    if (issueArea != null) 'issueArea': issueArea!.wireName,
    if (contentSignal != null) 'contentSignal': contentSignal!.wireName,
    if (contentFocus != null) 'contentFocus': contentFocus!.wireName,
    // 빈 문자열은 필드 자체를 생략한다 — 서버 optionalString 은 minLength 1
    // 이라, 시트가 안 채운 컨트롤러의 '' 를 그대로 실으면 페이로드 전체가
    // invalid-argument 로 거부된다 (2026-08-25 테스터 제출 실패의 원인).
    if (expectedOutcome != null && expectedOutcome!.trim().isNotEmpty)
      'expectedOutcome': expectedOutcome,
    if (actualOutcome != null && actualOutcome!.trim().isNotEmpty)
      'actualOutcome': actualOutcome,
    if (bugFrequency != null) 'bugFrequency': bugFrequency!.wireName,
    if (bugImpact != null) 'bugImpact': bugImpact!.wireName,
    if (experienceSignal != null)
      'experienceSignal': experienceSignal!.wireName,
    if (experienceFocus != null) 'experienceFocus': experienceFocus!.wireName,
  };
}

class ContentFeedbackSubmission {
  const ContentFeedbackSubmission({
    required this.feedbackId,
    required this.context,
    required this.draft,
    required this.appVersion,
    required this.platform,
    required this.locale,
    this.betaMissionId,
  });

  final String feedbackId;
  final ContentFeedbackContext context;
  final ContentFeedbackDraft draft;
  final String appVersion;
  final String platform;
  final String locale;
  final String? betaMissionId;

  ContentFeedbackValidationResult validate() {
    final errors = <String>[
      ...context.validate().errors,
      ...draft.validate().errors,
    ];
    if (_isBlank(feedbackId) || feedbackId.length > 64) {
      errors.add('feedbackId');
    }
    if (_isBlank(appVersion) || appVersion.length > 64) {
      errors.add('appVersion');
    }
    if (!const {'android', 'ios'}.contains(platform)) {
      errors.add('platform');
    }
    if (!const {'de', 'en'}.contains(locale)) {
      errors.add('locale');
    }
    if (betaMissionId != null &&
        (_isBlank(betaMissionId!) || betaMissionId!.length > 64)) {
      errors.add('betaMissionId');
    }
    return ContentFeedbackValidationResult(List.unmodifiable(errors));
  }

  Map<String, Object?> toWire() => {
    'schemaVersion': contentFeedbackSchemaVersion,
    'feedbackId': feedbackId,
    ...context.toWire(),
    ...draft.toWire(),
    'appVersion': appVersion,
    'platform': platform,
    'locale': locale,
    if (betaMissionId != null) 'betaMissionId': betaMissionId,
  };
}

bool _isBlank(String value) => value.trim().isEmpty;
