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
  translation,
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
    if (_isBlank(completionId) || completionId.length > 64) {
      errors.add('completionId');
    }
    if (_isBlank(contentType) || contentType.length > 48) {
      errors.add('contentType');
    }
    if (_isBlank(contentId) || contentId.length > 128) {
      errors.add('contentId');
    }
    if (contentLabel.length > 120) errors.add('contentLabel');
    if (level != null && !const {'A1', 'A2', 'B1', 'B2'}.contains(level)) {
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
  });

  final FeedbackCategory category;
  final String message;
  final FeedbackIssueArea? issueArea;
  final FeedbackContentSignal? contentSignal;
  final FeedbackContentFocus? contentFocus;

  ContentFeedbackValidationResult validate() {
    final errors = <String>[];
    if (message.length > contentFeedbackMaxMessageLength) {
      errors.add('message');
    }

    switch (category) {
      case FeedbackCategory.bug:
      case FeedbackCategory.other:
        if (_isBlank(message)) errors.add('messageRequired');
        if (category == FeedbackCategory.other && issueArea != null) {
          errors.add('issueArea');
        }
        if (contentSignal != null || contentFocus != null) {
          errors.add('contentFields');
        }
      case FeedbackCategory.content:
        if (issueArea != null) {
          errors.add('issueArea');
        }
        if (contentSignal == null &&
            contentFocus == null &&
            _isBlank(message)) {
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
