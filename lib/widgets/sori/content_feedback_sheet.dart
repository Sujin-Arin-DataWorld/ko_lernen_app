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
  FeedbackCategory? _category;
  FeedbackIssueArea? _issueArea;
  FeedbackContentSignal? _contentSignal;
  FeedbackContentFocus? _contentFocus;
  final TextEditingController _messageController = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
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
        _categoryButton(
          key: const Key('feedback-category-bug'),
          label: l10n.testerFeedbackCategoryBug,
          category: FeedbackCategory.bug,
        ),
        const SizedBox(height: Spacing.sm),
        _categoryButton(
          key: const Key('feedback-category-content'),
          label: l10n.testerFeedbackCategoryContent,
          category: FeedbackCategory.content,
        ),
        const SizedBox(height: Spacing.sm),
        _categoryButton(
          key: const Key('feedback-category-other'),
          label: l10n.testerFeedbackCategoryOther,
          category: FeedbackCategory.other,
        ),
        if (_category != null) ...[
          const SizedBox(height: Spacing.lg),
          if (_category == FeedbackCategory.bug) _issueAreaFields(l10n),
          if (_category == FeedbackCategory.content) ...[
            _contentSignalFields(l10n),
            const SizedBox(height: Spacing.md),
            _contentFocusFields(l10n),
          ],
          const SizedBox(height: Spacing.md),
          TextField(
            key: const Key('feedback-message'),
            controller: _messageController,
            minLines: 3,
            maxLines: 5,
            maxLength: contentFeedbackMaxMessageLength,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: l10n.testerFeedbackMessageLabel,
              hintText: l10n.testerFeedbackMessageHint,
            ),
          ),
          if (_validationError != null)
            Text(
              _validationError!,
              key: const Key('feedback-validation-error'),
              style: const TextStyle(
                color: SoriColors.danger,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: Spacing.sm),
          Row(
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
                  style: TextStyle(
                    color: SoriSurfaces.of(context).textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          SoriButton.filled(
            key: const Key('feedback-submit'),
            label: l10n.testerFeedbackSubmit,
            fullWidth: true,
            onTap: _submit,
          ),
          const SizedBox(height: Spacing.xs),
          SoriButton.ghost(
            key: const Key('feedback-cancel'),
            label: l10n.testerFeedbackCancel,
            fullWidth: true,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ],
    );
  }

  Widget _categoryButton({
    required Key key,
    required String label,
    required FeedbackCategory category,
  }) {
    return SoriButton(
      key: key,
      label: label,
      fullWidth: true,
      variant: _category == category
          ? SoriButtonVariant.filled
          : SoriButtonVariant.outlined,
      onTap: () => _selectCategory(category),
    );
  }

  void _selectCategory(FeedbackCategory category) {
    setState(() {
      _category = category;
      _validationError = null;
      if (category != FeedbackCategory.bug) _issueArea = null;
      if (category != FeedbackCategory.content) {
        _contentSignal = null;
        _contentFocus = null;
      }
    });
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
                  onTap: () => setState(() => _issueArea = area),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _contentSignalFields(AppL10n l10n) {
    return Column(
      key: const Key('feedback-content-signal-fields'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(l10n.testerFeedbackContentSignalLabel),
        const SizedBox(height: Spacing.sm),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: FeedbackContentSignal.values
              .map(
                (signal) => SoriChip(
                  key: Key('feedback-signal-${signal.name}'),
                  label: _contentSignalLabel(l10n, signal),
                  selected: _contentSignal == signal,
                  variant: SoriChipVariant.outlined,
                  onTap: () => setState(() => _contentSignal = signal),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _contentFocusFields(AppL10n l10n) {
    return Column(
      key: const Key('feedback-content-focus-fields'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(l10n.testerFeedbackContentFocusLabel),
        const SizedBox(height: Spacing.sm),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: FeedbackContentFocus.values
              .map(
                (focus) => SoriChip(
                  key: Key('feedback-focus-${focus.name}'),
                  label: _contentFocusLabel(l10n, focus),
                  selected: _contentFocus == focus,
                  variant: SoriChipVariant.outlined,
                  onTap: () => setState(() => _contentFocus = focus),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _fieldLabel(String label) => Text(
    label,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
  );

  void _submit() {
    final category = _category;
    if (category == null) return;
    final draft = ContentFeedbackDraft(
      category: category,
      message: _messageController.text,
      issueArea: _issueArea,
      contentSignal: _contentSignal,
      contentFocus: _contentFocus,
    );
    final validation = draft.validate();
    if (!validation.isValid) {
      final l10n = AppL10n.of(context);
      setState(() {
        _validationError = validation.errors.contains('message')
            ? l10n.testerFeedbackMessageTooLong
            : validation.errors.contains('contentFeedbackRequired')
            ? l10n.testerFeedbackContentFeedbackRequired
            : l10n.testerFeedbackMessageRequired;
      });
      return;
    }

    Navigator.of(context).pop(draft);
  }

  String _contentPrompt(AppL10n l10n) =>
      switch (widget.feedbackContext.contentType) {
        'scenario' => l10n.testerFeedbackPromptScenario,
        'vocab_pack' ||
        'review' ||
        'custom_wordbook' ||
        'custom_wordbook_game' ||
        'legacy_vocab' => l10n.testerFeedbackPromptWordWork,
        'grammar_session' => l10n.testerFeedbackPromptGrammar,
        'hangul_cards' ||
        'hangul_writing' ||
        'daily_hangul' => l10n.testerFeedbackPromptHangul,
        'game' => l10n.testerFeedbackPromptGame,
        'listening' => l10n.testerFeedbackPromptListening,
        _ => l10n.testerFeedbackPromptGeneric,
      };

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
    FeedbackContentFocus.translation =>
      l10n.testerFeedbackContentFocusTranslation,
    FeedbackContentFocus.other => l10n.testerFeedbackContentFocusOther,
  };
}
