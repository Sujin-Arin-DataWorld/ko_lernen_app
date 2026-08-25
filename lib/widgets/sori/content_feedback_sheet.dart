import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/content_feedback.dart';
import '../../services/content_feedback_service.dart';
import 'button.dart';
import 'chip.dart';
import 'sheet.dart';
import 'tokens.dart';

typedef ContentFeedbackSubmitter =
    Future<ContentFeedbackSubmitResult> Function(
      ContentFeedbackContext context,
      ContentFeedbackDraft draft,
    );

Future<ContentFeedbackDraft?> showContentFeedbackSheet({
  required BuildContext context,
  required ContentFeedbackContext feedbackContext,
}) {
  return showSoriSheet<ContentFeedbackDraft>(
    context: context,
    builder: (_) => ContentFeedbackSheet(feedbackContext: feedbackContext),
  );
}

class ContentFeedbackSheet extends StatefulWidget {
  const ContentFeedbackSheet({super.key, required this.feedbackContext});

  final ContentFeedbackContext feedbackContext;

  @override
  State<ContentFeedbackSheet> createState() => _ContentFeedbackSheetState();
}

class _ContentFeedbackSheetState extends State<ContentFeedbackSheet> {
  FeedbackCategory _category = FeedbackCategory.content;
  FeedbackIssueArea? _issueArea;
  FeedbackContentSignal? _contentSignal;
  FeedbackContentFocus? _contentFocus;
  FeedbackBugFrequency? _bugFrequency;
  FeedbackBugImpact? _bugImpact;
  FeedbackExperienceSignal? _experienceSignal;
  FeedbackExperienceFocus? _experienceFocus;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _expectedOutcomeController =
      TextEditingController();
  final TextEditingController _actualOutcomeController =
      TextEditingController();
  String? _validationError;

  bool get _isBookAnalysisContext =>
      widget.feedbackContext.contentType == 'book_analysis';

  bool get _isQuestRewardContext =>
      widget.feedbackContext.contentType == 'quest_reward';

  bool get _isMilestoneContext =>
      widget.feedbackContext.contentType == 'milestone';

  bool get _isLearningContext =>
      !_isBookAnalysisContext && !_isQuestRewardContext && !_isMilestoneContext;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_handleTextChanged);
    _expectedOutcomeController.addListener(_handleTextChanged);
    _actualOutcomeController.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(ContentFeedbackSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldContext = oldWidget.feedbackContext;
    final currentContext = widget.feedbackContext;
    if (oldContext.contentType == currentContext.contentType &&
        oldContext.completionId == currentContext.completionId) {
      return;
    }
    _category = FeedbackCategory.content;
    _issueArea = null;
    _contentSignal = null;
    _contentFocus = null;
    _bugFrequency = null;
    _bugImpact = null;
    _experienceSignal = null;
    _experienceFocus = null;
    _validationError = null;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _expectedOutcomeController.dispose();
    _actualOutcomeController.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    if (!mounted) {
      return;
    }
    setState(() => _validationError = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.testerFeedbackCardTitle,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          _contentPrompt(l10n),
          key: const Key('feedback-content-prompt'),
          style: TextStyle(
            color: SoriSurfaces.of(context).textMuted,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: Spacing.lg),
        if (_category == FeedbackCategory.content) ...[
          _pulseSignalFields(l10n),
          if (_hasPulseSignal) ...[
            const SizedBox(height: Spacing.md),
            _pulseFocusFields(l10n),
          ],
          const SizedBox(height: Spacing.md),
          _messageField(l10n),
          const SizedBox(height: Spacing.sm),
          _alternateRoutes(l10n),
        ] else if (_category == FeedbackCategory.bug) ...[
          _bugFields(l10n),
          const SizedBox(height: Spacing.md),
          _messageField(l10n),
        ] else ...[
          _messageField(l10n, requiredForOther: true),
        ],
        if (_validationError != null) ...[
          const SizedBox(height: Spacing.sm),
          Text(
            _validationError!,
            key: const Key('feedback-validation-error'),
            style: const TextStyle(
              color: SoriColors.danger,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: Spacing.md),
        _privacyReminder(l10n),
        const SizedBox(height: Spacing.lg),
        SoriButton.filled(
          key: const Key('feedback-submit'),
          label: l10n.testerFeedbackSubmit,
          fullWidth: true,
          onTap: _canSubmit ? _submit : null,
        ),
        const SizedBox(height: Spacing.xs),
        SoriButton.ghost(
          key: const Key('feedback-cancel'),
          label: _category == FeedbackCategory.content
              ? l10n.testerFeedbackCancel
              : l10n.testerFeedbackBack,
          fullWidth: true,
          onTap: _backOrCancel,
        ),
      ],
    );
  }

  bool get _hasPulseSignal =>
      _isLearningContext ? _contentSignal != null : _experienceSignal != null;

  bool get _canSubmit => switch (_category) {
    FeedbackCategory.content =>
      _isLearningContext
          ? _contentSignal != null && _contentFocus != null
          : _experienceSignal != null &&
                _experienceFocus != null &&
                _experienceFocuses.contains(_experienceFocus),
    FeedbackCategory.bug =>
      _issueArea != null &&
          _expectedOutcomeController.text.trim().isNotEmpty &&
          _actualOutcomeController.text.trim().isNotEmpty &&
          _expectedOutcomeController.text.length <= 500 &&
          _actualOutcomeController.text.length <= 500 &&
          _bugFrequency != null &&
          _bugImpact != null,
    FeedbackCategory.other => _messageController.text.trim().isNotEmpty,
  };

  Widget _pulseSignalFields(AppL10n l10n) {
    if (_isLearningContext) {
      return Column(
        key: const Key('pulse-signal-fields'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: FeedbackContentSignal.values
                .map(
                  (signal) => SoriChip(
                    key: Key('pulse-signal-${signal.name}'),
                    label: _contentSignalLabel(l10n, signal),
                    selected: _contentSignal == signal,
                    variant: SoriChipVariant.outlined,
                    minInteractiveHeight: 44,
                    onTap: () {
                      setState(() {
                        _contentSignal = signal;
                        _validationError = null;
                      });
                    },
                  ),
                )
                .toList(growable: false),
          ),
        ],
      );
    }

    return Column(
      key: const Key('pulse-experience-fields'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: FeedbackExperienceSignal.values
              .map(
                (signal) => SoriChip(
                  key: Key('pulse-experience-${signal.name}'),
                  label: _experienceSignalLabel(l10n, signal),
                  selected: _experienceSignal == signal,
                  variant: SoriChipVariant.outlined,
                  minInteractiveHeight: 44,
                  onTap: () {
                    setState(() {
                      _experienceSignal = signal;
                      _validationError = null;
                    });
                  },
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _pulseFocusFields(AppL10n l10n) {
    if (_isLearningContext) {
      const focuses = <FeedbackContentFocus>[
        FeedbackContentFocus.explanation,
        FeedbackContentFocus.examples,
        FeedbackContentFocus.questions,
        FeedbackContentFocus.pace,
        FeedbackContentFocus.audio,
        FeedbackContentFocus.translation,
      ];
      final label = _contentSignal == FeedbackContentSignal.right
          ? l10n.testerFeedbackPulsePositiveReasonPrompt
          : l10n.testerFeedbackPulseReasonPrompt;
      return Column(
        key: const Key('pulse-focus-fields'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label),
          const SizedBox(height: Spacing.sm),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: focuses
                .map(
                  (focus) => SoriChip(
                    key: Key('pulse-focus-${focus.name}'),
                    label: _contentFocusLabel(l10n, focus),
                    selected: _contentFocus == focus,
                    variant: SoriChipVariant.outlined,
                    minInteractiveHeight: 44,
                    onTap: () {
                      setState(() {
                        _contentFocus = focus;
                        _validationError = null;
                      });
                    },
                  ),
                )
                .toList(growable: false),
          ),
        ],
      );
    }

    final focuses = _experienceFocuses;
    return Column(
      key: const Key('pulse-experience-focus-fields'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(l10n.testerFeedbackExperienceReasonPrompt),
        const SizedBox(height: Spacing.sm),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: focuses
              .map(
                (focus) => SoriChip(
                  key: Key('pulse-experience-focus-${focus.name}'),
                  label: _experienceFocusLabel(l10n, focus),
                  selected: _experienceFocus == focus,
                  variant: SoriChipVariant.outlined,
                  minInteractiveHeight: 44,
                  onTap: () {
                    setState(() {
                      _experienceFocus = focus;
                      _validationError = null;
                    });
                  },
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  List<FeedbackExperienceFocus> get _experienceFocuses {
    if (_isBookAnalysisContext) {
      return const [
        FeedbackExperienceFocus.koreanText,
        FeedbackExperienceFocus.wordMeanings,
        FeedbackExperienceFocus.grammar,
        FeedbackExperienceFocus.translation,
        FeedbackExperienceFocus.resultMissing,
      ];
    }
    if (_isQuestRewardContext) {
      return const [
        FeedbackExperienceFocus.goal,
        FeedbackExperienceFocus.difficulty,
        FeedbackExperienceFocus.reward,
        FeedbackExperienceFocus.instructions,
        FeedbackExperienceFocus.length,
      ];
    }
    return const [
      FeedbackExperienceFocus.timing,
      FeedbackExperienceFocus.visuals,
      FeedbackExperienceFocus.reward,
      FeedbackExperienceFocus.message,
      FeedbackExperienceFocus.frequency,
    ];
  }

  Widget _bugFields(AppL10n l10n) {
    return Column(
      key: const Key('bug-fields'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _issueAreaFields(l10n),
        const SizedBox(height: Spacing.md),
        _textArea(
          key: const Key('bug-expected-outcome'),
          controller: _expectedOutcomeController,
          label: l10n.testerFeedbackBugExpectedLabel,
          hint: l10n.testerFeedbackBugExpectedHint,
          maxLength: 500,
        ),
        const SizedBox(height: Spacing.sm),
        _textArea(
          key: const Key('bug-actual-outcome'),
          controller: _actualOutcomeController,
          label: l10n.testerFeedbackBugActualLabel,
          hint: l10n.testerFeedbackBugActualHint,
          maxLength: 500,
        ),
        const SizedBox(height: Spacing.md),
        _fieldLabel(l10n.testerFeedbackBugFrequencyLabel),
        const SizedBox(height: Spacing.sm),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: FeedbackBugFrequency.values
              .map(
                (frequency) => SoriChip(
                  key: Key('bug-frequency-${frequency.name}'),
                  label: _bugFrequencyLabel(l10n, frequency),
                  selected: _bugFrequency == frequency,
                  variant: SoriChipVariant.outlined,
                  minInteractiveHeight: 44,
                  onTap: () {
                    setState(() {
                      _bugFrequency = frequency;
                      _validationError = null;
                    });
                  },
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: Spacing.md),
        _fieldLabel(l10n.testerFeedbackBugImpactLabel),
        const SizedBox(height: Spacing.sm),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: FeedbackBugImpact.values
              .map(
                (impact) => SoriChip(
                  key: Key('bug-impact-${impact.name}'),
                  label: _bugImpactLabel(l10n, impact),
                  selected: _bugImpact == impact,
                  variant: SoriChipVariant.outlined,
                  minInteractiveHeight: 44,
                  onTap: () {
                    setState(() {
                      _bugImpact = impact;
                      _validationError = null;
                    });
                  },
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _issueAreaFields(AppL10n l10n) {
    return Column(
      key: const Key('feedback-issue-area-fields'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(l10n.testerFeedbackIssueAreaLabel),
        const SizedBox(height: Spacing.sm),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: FeedbackIssueArea.values
              .map(
                (area) => SoriChip(
                  key: Key('feedback-issue-${area.name}'),
                  label: _issueAreaLabel(l10n, area),
                  selected: _issueArea == area,
                  variant: SoriChipVariant.outlined,
                  minInteractiveHeight: 44,
                  onTap: () {
                    setState(() {
                      _issueArea = area;
                      _validationError = null;
                    });
                  },
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _messageField(AppL10n l10n, {bool requiredForOther = false}) {
    return _textArea(
      key: const Key('feedback-message'),
      controller: _messageController,
      label: requiredForOther
          ? l10n.testerFeedbackOtherMessageLabel
          : l10n.testerFeedbackMessageLabel,
      hint: requiredForOther
          ? l10n.testerFeedbackOtherMessageHint
          : l10n.testerFeedbackMessageHint,
      maxLength: contentFeedbackMaxMessageLength,
    );
  }

  Widget _textArea({
    required Key key,
    required TextEditingController controller,
    required String label,
    required String hint,
    required int maxLength,
  }) {
    return TextField(
      key: key,
      controller: controller,
      minLines: 3,
      maxLines: 5,
      maxLength: maxLength,
      textInputAction: TextInputAction.newline,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Widget _alternateRoutes(AppL10n l10n) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: Spacing.sm,
      runSpacing: Spacing.xs,
      children: [
        SoriButton.ghost(
          key: const Key('feedback-category-bug'),
          label: l10n.testerFeedbackCategoryBug,
          size: SoriButtonSize.md,
          onTap: () => _selectCategory(FeedbackCategory.bug),
        ),
        SoriButton.ghost(
          key: const Key('feedback-category-other'),
          label: l10n.testerFeedbackCategoryOther,
          size: SoriButtonSize.md,
          onTap: () => _selectCategory(FeedbackCategory.other),
        ),
      ],
    );
  }

  Widget _privacyReminder(AppL10n l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.privacy_tip_outlined,
          size: 18,
          color: SoriSurfaces.of(context).textMuted,
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(
            l10n.testerFeedbackPrivacyReminder,
            key: const Key('feedback-privacy-reminder'),
            style: TextStyle(
              color: SoriSurfaces.of(context).textMuted,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String label) => Text(
    label,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
  );

  void _selectCategory(FeedbackCategory category) {
    setState(() {
      _category = category;
      _validationError = null;
    });
  }

  void _backOrCancel() {
    if (_category == FeedbackCategory.content) {
      Navigator.of(context).pop();
      return;
    }
    _messageController.clear();
    _expectedOutcomeController.clear();
    _actualOutcomeController.clear();
    setState(() {
      _category = FeedbackCategory.content;
      _issueArea = null;
      _bugFrequency = null;
      _bugImpact = null;
      _validationError = null;
    });
  }

  void _submit() {
    if (!_canSubmit) {
      return;
    }
    final draft = ContentFeedbackDraft(
      category: _category,
      message: _messageController.text,
      issueArea: _category == FeedbackCategory.bug ? _issueArea : null,
      contentSignal: _category == FeedbackCategory.content && _isLearningContext
          ? _contentSignal
          : null,
      contentFocus: _category == FeedbackCategory.content && _isLearningContext
          ? _contentFocus
          : null,
      // 비어 있으면 null — '' 를 넘기면 draft 는 통과해도 서버가
      // optionalString(minLength 1) 로 페이로드 전체를 거부한다.
      expectedOutcome:
          _category == FeedbackCategory.bug &&
              _expectedOutcomeController.text.trim().isNotEmpty
          ? _expectedOutcomeController.text
          : null,
      actualOutcome:
          _category == FeedbackCategory.bug &&
              _actualOutcomeController.text.trim().isNotEmpty
          ? _actualOutcomeController.text
          : null,
      bugFrequency: _category == FeedbackCategory.bug ? _bugFrequency : null,
      bugImpact: _category == FeedbackCategory.bug ? _bugImpact : null,
      experienceSignal:
          _category == FeedbackCategory.content && !_isLearningContext
          ? _experienceSignal
          : null,
      experienceFocus:
          _category == FeedbackCategory.content && !_isLearningContext
          ? _experienceFocus
          : null,
    );
    final validation = draft.validate();
    if (!validation.isValid) {
      final l10n = AppL10n.of(context);
      setState(() {
        if (validation.errors.contains('message')) {
          _validationError = l10n.testerFeedbackMessageTooLong;
        } else if (validation.errors.contains('structuredBug')) {
          _validationError = l10n.testerFeedbackBugRequired;
        } else if (validation.errors.contains('contentFeedbackRequired') ||
            validation.errors.contains('experienceFields')) {
          _validationError = l10n.testerFeedbackContentFeedbackRequired;
        } else {
          _validationError = l10n.testerFeedbackMessageRequired;
        }
      });
      return;
    }

    Navigator.of(context).pop(draft);
  }

  String _contentPrompt(AppL10n l10n) {
    if (_isBookAnalysisContext) {
      return l10n.testerFeedbackPulseBookPrompt;
    }
    if (_isQuestRewardContext) {
      return l10n.testerFeedbackPulseQuestPrompt;
    }
    if (_isMilestoneContext) {
      return l10n.testerFeedbackPulseMilestonePrompt;
    }
    return l10n.testerFeedbackPulseLearningPrompt;
  }

  String _issueAreaLabel(AppL10n l10n, FeedbackIssueArea area) =>
      switch (area) {
        FeedbackIssueArea.ui => l10n.testerFeedbackIssueAreaUi,
        FeedbackIssueArea.answer => l10n.testerFeedbackIssueAreaAnswer,
        FeedbackIssueArea.audio => l10n.testerFeedbackIssueAreaAudio,
        FeedbackIssueArea.translation =>
          l10n.testerFeedbackIssueAreaTranslation,
        FeedbackIssueArea.navigation => l10n.testerFeedbackIssueAreaNavigation,
        FeedbackIssueArea.other => l10n.testerFeedbackIssueAreaOther,
      };

  String _contentSignalLabel(
    AppL10n l10n,
    FeedbackContentSignal signal,
  ) => switch (signal) {
    FeedbackContentSignal.tooEasy => l10n.testerFeedbackContentSignalTooEasy,
    FeedbackContentSignal.right => l10n.testerFeedbackContentSignalRight,
    FeedbackContentSignal.tooHard => l10n.testerFeedbackContentSignalTooHard,
    FeedbackContentSignal.unclear => l10n.testerFeedbackContentSignalUnclear,
  };

  String _contentFocusLabel(
    AppL10n l10n,
    FeedbackContentFocus focus,
  ) => switch (focus) {
    FeedbackContentFocus.explanation =>
      l10n.testerFeedbackContentFocusExplanation,
    FeedbackContentFocus.examples => l10n.testerFeedbackContentFocusExamples,
    FeedbackContentFocus.questions => l10n.testerFeedbackContentFocusQuestions,
    FeedbackContentFocus.pace => l10n.testerFeedbackContentFocusPace,
    FeedbackContentFocus.audio => l10n.testerFeedbackContentFocusAudio,
    FeedbackContentFocus.translation =>
      l10n.testerFeedbackContentFocusTranslation,
    FeedbackContentFocus.other => l10n.testerFeedbackContentFocusOther,
  };

  String _experienceSignalLabel(AppL10n l10n, FeedbackExperienceSignal signal) {
    if (_isBookAnalysisContext) {
      return switch (signal) {
        FeedbackExperienceSignal.positive =>
          l10n.testerFeedbackBookSignalPositive,
        FeedbackExperienceSignal.mixed => l10n.testerFeedbackBookSignalMixed,
        FeedbackExperienceSignal.negative =>
          l10n.testerFeedbackBookSignalNegative,
        FeedbackExperienceSignal.unsure => l10n.testerFeedbackBookSignalUnsure,
      };
    }
    if (_isQuestRewardContext) {
      return switch (signal) {
        FeedbackExperienceSignal.positive =>
          l10n.testerFeedbackQuestSignalPositive,
        FeedbackExperienceSignal.mixed => l10n.testerFeedbackQuestSignalMixed,
        FeedbackExperienceSignal.negative =>
          l10n.testerFeedbackQuestSignalNegative,
        FeedbackExperienceSignal.unsure => l10n.testerFeedbackQuestSignalUnsure,
      };
    }
    return switch (signal) {
      FeedbackExperienceSignal.positive =>
        l10n.testerFeedbackMilestoneSignalPositive,
      FeedbackExperienceSignal.mixed => l10n.testerFeedbackMilestoneSignalMixed,
      FeedbackExperienceSignal.negative =>
        l10n.testerFeedbackMilestoneSignalNegative,
      FeedbackExperienceSignal.unsure =>
        l10n.testerFeedbackMilestoneSignalUnsure,
    };
  }

  String _experienceFocusLabel(
    AppL10n l10n,
    FeedbackExperienceFocus focus,
  ) => switch (focus) {
    FeedbackExperienceFocus.koreanText =>
      l10n.testerFeedbackExperienceFocusKoreanText,
    FeedbackExperienceFocus.wordMeanings =>
      l10n.testerFeedbackExperienceFocusWordMeanings,
    FeedbackExperienceFocus.grammar =>
      l10n.testerFeedbackExperienceFocusGrammar,
    FeedbackExperienceFocus.translation =>
      l10n.testerFeedbackExperienceFocusTranslation,
    FeedbackExperienceFocus.resultMissing =>
      l10n.testerFeedbackExperienceFocusResultMissing,
    FeedbackExperienceFocus.goal => l10n.testerFeedbackExperienceFocusGoal,
    FeedbackExperienceFocus.difficulty =>
      l10n.testerFeedbackExperienceFocusDifficulty,
    FeedbackExperienceFocus.reward => l10n.testerFeedbackExperienceFocusReward,
    FeedbackExperienceFocus.instructions =>
      l10n.testerFeedbackExperienceFocusInstructions,
    FeedbackExperienceFocus.length => l10n.testerFeedbackExperienceFocusLength,
    FeedbackExperienceFocus.timing => l10n.testerFeedbackExperienceFocusTiming,
    FeedbackExperienceFocus.visuals =>
      l10n.testerFeedbackExperienceFocusVisuals,
    FeedbackExperienceFocus.message =>
      l10n.testerFeedbackExperienceFocusMessage,
    FeedbackExperienceFocus.frequency =>
      l10n.testerFeedbackExperienceFocusFrequency,
    FeedbackExperienceFocus.other => l10n.testerFeedbackExperienceFocusOther,
  };

  String _bugFrequencyLabel(
    AppL10n l10n,
    FeedbackBugFrequency frequency,
  ) => switch (frequency) {
    FeedbackBugFrequency.everyTime => l10n.testerFeedbackBugFrequencyEveryTime,
    FeedbackBugFrequency.sometimes => l10n.testerFeedbackBugFrequencySometimes,
    FeedbackBugFrequency.once => l10n.testerFeedbackBugFrequencyOnce,
  };

  String _bugImpactLabel(AppL10n l10n, FeedbackBugImpact impact) =>
      switch (impact) {
        FeedbackBugImpact.canContinue =>
          l10n.testerFeedbackBugImpactCanContinue,
        FeedbackBugImpact.slowsLearning =>
          l10n.testerFeedbackBugImpactSlowsLearning,
        FeedbackBugImpact.blocksLearning =>
          l10n.testerFeedbackBugImpactBlocksLearning,
      };
}
