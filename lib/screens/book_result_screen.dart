import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/book_page.dart';
import '../models/feedback_completion.dart';
import '../services/analytics_service.dart';
import '../services/book_analysis_service.dart';
import '../services/book_analysis_text.dart';
import '../services/book_image_service.dart';
import '../services/book_ocr_document.dart';
import '../services/grounded_book_study_service.dart';
import '../services/bookshelf_service.dart';
import '../services/custom_pack_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/grounded_book_study_card.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/mascot_preference.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/dialog.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/text_field.dart';
import '../widgets/sori/toast.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';
import '../widgets/sori/window_class.dart';
import '../widgets/sori/wordbook_add.dart';

/// Phase 5 (stately-rising-jongga) — Analysis-Result Screen.
///
/// Args: `{ text: String, imagePath: String? }`.
/// Lädt `BookAnalysisService.analyze(text)` und zeigt Wörter, Grammatik,
/// Sätze. "Speichern" → BookshelfService + Quota-Increment.
typedef BookAnalyzer =
    Future<BookAnalysisResult> Function({
      required String text,
      required String targetLang,
    });

typedef BookPageSaver =
    Future<void> Function(BookPage page, PendingMediaLease? imageLease);

enum _BookResultSaveState { idle, saving, saved, unresolved }

BookAnalysisFeedbackSource _feedbackSourceFor(BookAnalysisResult result) {
  if (result.warnings.contains('offline_stub')) {
    return BookAnalysisFeedbackSource.offline;
  }
  if (result.warnings.contains('server_rate_limited')) {
    return BookAnalysisFeedbackSource.rateLimited;
  }
  return BookAnalysisFeedbackSource.online;
}

class BookResultSaveIntent {
  BookResultSaveIntent({required this.pageId, required this.capturedAtIso});

  final String pageId;
  final String capturedAtIso;
  _BookResultSaveState _state = _BookResultSaveState.idle;

  bool get canStart => _state == _BookResultSaveState.idle;
  bool get isSaving => _state == _BookResultSaveState.saving;
  bool get isSaved => _state == _BookResultSaveState.saved;
  bool get isUnresolved => _state == _BookResultSaveState.unresolved;
  bool get shouldDiscardLease => _state == _BookResultSaveState.idle;

  Future<T> run<T>(
    Future<T> Function(String pageId, String capturedAtIso) operation,
  ) async {
    if (!canStart) {
      throw StateError('This book save intent cannot be retried.');
    }
    _state = _BookResultSaveState.saving;
    try {
      final result = await operation(pageId, capturedAtIso);
      _state = _BookResultSaveState.saved;
      return result;
    } on PreferenceOutcomeUnknownException {
      _state = _BookResultSaveState.unresolved;
      rethrow;
    } on Object {
      _state = _BookResultSaveState.idle;
      rethrow;
    }
  }
}

class BookResultScreen extends StatefulWidget {
  final Map<String, dynamic> args;
  final BookAnalyzer? analyzer;
  final BookPageSaver? pageSaver;

  const BookResultScreen({
    super.key,
    required this.args,
    this.analyzer,
    this.pageSaver,
  });

  @override
  State<BookResultScreen> createState() => _BookResultScreenState();
}

class _BookResultScreenState extends State<BookResultScreen> {
  bool _loading = true;
  String? _error;
  BookAnalysisResult? _result;
  late final BookResultSaveIntent _saveIntent;
  String? _analysisLanguage;
  int _analysisGeneration = 0;
  final FeedbackCompletionSlot _feedbackCompletion = FeedbackCompletionSlot();

  bool get _saved => _saveIntent.isSaved;
  bool get _saving => _saveIntent.isSaving;
  bool get _saveUnresolved => _saveIntent.isUnresolved;
  String get _text => widget.args['text'] as String? ?? '';
  String get _safeText => BookAnalysisTextPreprocessor.prepare(_text).text;
  String? get _imageLease => widget.args['imageLease'] as String?;
  List<String> get _captureQualityWarnings => <String>{
    ...?((widget.args['qualityWarnings'] as List?)?.whereType<String>()),
    ...?((widget.args['textQualityWarnings'] as List?)?.whereType<String>()),
  }.toList(growable: false);
  bool get _qualityOverrideByTextEdit =>
      widget.args['qualityOverrideByTextEdit'] == true;
  String get _ocrQuality {
    if (_qualityOverrideByTextEdit) {
      return 'severe_override';
    }
    final ocr = widget.args['ocrQuality'];
    if (ocr is Map && ocr['confidenceUnavailable'] == true) {
      return 'unmeasured';
    }
    return _captureQualityWarnings.isEmpty ? 'clean' : 'warning';
  }

  String _resultStatusFor(BookAnalysisResult result) {
    if (result.warnings.contains('invalid_response_schema')) {
      return 'blocked_schema';
    }
    if (result.warnings.contains('wrong_analysis_language')) {
      return 'blocked_language';
    }
    if (result.warnings.contains('invalid_response_filtered')) {
      return 'blocked_content';
    }
    if (result.warnings.contains('no_korean_text')) {
      return 'blocked_no_korean';
    }
    if (!result.hasMeaningfulResult) {
      return 'blocked_empty';
    }
    if (result.warnings.contains('translation_unavailable')) {
      return 'partial_translation';
    }
    if (result.warnings.contains('offline_stub')) {
      return 'offline';
    }
    if (_qualityOverrideByTextEdit) {
      return 'success_capture_override';
    }
    return 'success';
  }

  String _warningBucketFor(BookAnalysisResult result) {
    if (result.warnings.contains('invalid_response_schema')) {
      return 'schema';
    }
    if (result.warnings.contains('wrong_analysis_language')) {
      return 'language';
    }
    if (result.warnings.contains('invalid_response_filtered')) {
      return 'content';
    }
    if (result.warnings.contains('no_korean_text')) {
      return 'no_korean';
    }
    if (result.warnings.contains('translation_unavailable')) {
      return 'translation';
    }
    if (result.warnings.any(
      const {
        'image_blur_warning',
        'image_low_contrast_warning',
        'ocr_confidence_unavailable',
        'ocr_low_confidence',
        'unexpected_script_filtered',
      }.contains,
    )) {
      return 'capture_quality';
    }
    if (result.warnings.contains('offline_stub')) {
      return 'remote';
    }
    if (_captureQualityWarnings.isNotEmpty) {
      return 'capture_quality';
    }
    return 'none';
  }

  @override
  void initState() {
    super.initState();
    _saveIntent = BookResultSaveIntent(
      pageId: BookshelfService.generateId(),
      capturedAtIso: DateTime.now().toUtc().toIso8601String(),
    );
  }

  @override
  void dispose() {
    if (_saveIntent.shouldDiscardLease) {
      unawaited(
        BookImageService.discardEncoded(_imageLease).catchError((Object _) {}),
      );
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = BookAnalysisService.normalizeTargetLanguage(
      Localizations.localeOf(context).languageCode,
    );
    if (_analysisLanguage == language) {
      return;
    }
    _analysisLanguage = language;
    _analyze(language);
  }

  Future<void> _analyze(String targetLang) async {
    _feedbackCompletion.reset();
    final generation = ++_analysisGeneration;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Quota erst nach erfolgreichem Aufruf erhöhen — Fehler zählen nicht.
      final customAnalyzer = widget.analyzer;
      final res = customAnalyzer != null
          ? await customAnalyzer(text: _text, targetLang: targetLang)
          : await BookAnalysisService.analyze(
              text: _text,
              targetLang: targetLang,
              document: widget.args['ocrDocument'] is BookOcrDocument
                  ? widget.args['ocrDocument'] as BookOcrDocument
                  : null,
            );
      if (!res.warnings.contains('offline_stub') &&
          !res.warnings.contains('no_korean_text')) {
        await Storage.incBookSnapCountToday();
      }
      unawaited(
        Analytics.bookCaptureAnalyzed(
          targetLang: targetLang,
          words: res.words.length,
          grammar: res.grammar.length,
          sentences: res.sentences.length,
          offline: res.warnings.contains('offline_stub'),
          resultStatus: _resultStatusFor(res),
          warningBucket: _warningBucketFor(res),
          ocrQuality: _ocrQuality,
        ),
      );
      if (!mounted || generation != _analysisGeneration) {
        return;
      }
      setState(() {
        _result = res;
        _loading = false;
        _feedbackCompletion.complete(
          () => FeedbackCompletion.bookAnalysis(
            words: res.words.length,
            grammar: res.grammar.length,
            sentences: res.sentences.length,
            source: _feedbackSourceFor(res),
          ),
        );
      });
    } catch (_) {
      if (!mounted || generation != _analysisGeneration) {
        return;
      }
      setState(() {
        _loading = false;
        _error = AppL10n.of(context).loadErrorTryAgain;
      });
    }
  }

  Future<void> _save() async {
    final res = _result;
    if (res == null || !res.isSaveable || !_saveIntent.canStart) {
      return;
    }
    final operation = _saveIntent.run((pageId, capturedAtIso) async {
      final page = BookPage(
        id: pageId,
        localThumbnailPath: null,
        extractedText: _safeText,
        note: '',
        words: res.words,
        grammar: res.grammar,
        sentences: res.sentences,
        expressions: res.expressions,
        capturedAtIso: capturedAtIso,
        customPackId: null,
        analysisLanguage: res.analysisLanguage,
      );
      final lease = PendingMediaLease.tryParse(_imageLease);
      final pageSaver = widget.pageSaver;
      if (pageSaver != null) {
        await pageSaver(page, lease);
      } else if (lease == null) {
        await BookshelfService.save(page);
      } else {
        await BookshelfService.saveWithPendingImage(page, lease);
      }
    });
    setState(() {});
    try {
      await operation;
      if (!mounted) return;
      setState(() {});
    } on PreferenceOutcomeUnknownException {
      if (!mounted) return;
      final t = AppL10n.of(context);
      soriToast(context, t.bookCaptureErrorUnknown);
      return;
    } on Object {
      if (!mounted) return;
      final t = AppL10n.of(context);
      soriToast(context, '${t.bookCaptureErrorUnknown} ${t.btnRetry}');
      return;
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
    if (!mounted) return;
    soriNotice(
      context,
      AppL10n.of(context).bookResultSaved,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_loading) {
      return _guard(
        SoriStandardFrame(
          appBarTitle: t.bookResultTitle,
          maxWidth: SoriMaxWidth.prose,
          builder: (context, padding) => Padding(
            padding: padding,
            child: AppLoading(
              message: t.bookResultAnalyzing,
              asset: 'assets/illustrations/book/book_analyzing.png',
            ),
          ),
        ),
      );
    }
    if (_error != null || _result == null) {
      return _guard(
        SoriStandardFrame(
          appBarTitle: t.bookResultTitle,
          maxWidth: SoriMaxWidth.prose,
          builder: (context, padding) => Padding(
            padding: padding,
            child: AppError(
              message: _error ?? 'unknown',
              messageLiveRegion: true,
              onRetry: () => _analyze(_analysisLanguage ?? 'de'),
              asset: 'assets/illustrations/book/book_error.png',
            ),
          ),
        ),
      );
    }

    final r = _result!;
    final feedbackCompletion = _feedbackCompletion.current;
    final feedbackScope = ContentFeedbackControllerScope.maybeOf(context);
    final offlineStub = r.warnings.contains('offline_stub');
    final rateLimited = r.warnings.contains('server_rate_limited');
    final credentialsUnavailable = r.warnings.contains(
      'remote_credentials_unavailable',
    );
    final noKoreanText = r.warnings.contains('no_korean_text');
    final translationUnavailable = r.warnings.contains(
      'translation_unavailable',
    );
    final qualityFiltered =
        r.warnings.any(
          const {
            'unexpected_script_filtered',
            'invalid_response_filtered',
            'text_truncated',
            'translation_unavailable',
          }.contains,
        ) ||
        _captureQualityWarnings.isNotEmpty;
    final blockedResult = !r.isSaveable;

    return _guard(
      SoriStandardFrame(
        appBarTitle: t.bookResultTitle,
        actions: r.isSaveable ? const [TtsSpeedAction()] : const [],
        maxWidth: SoriMaxWidth.prose,
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.sm,
          Spacing.lg,
          Spacing.xxl,
        ),
        builder: (context, padding) => SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: r.words.isNotEmpty
                    ? Image.asset(
                        'assets/illustrations/book/book_success.png',
                        height: 150,
                        fit: BoxFit.contain,
                        // Fixed book artwork is brand decoration, not the
                        // learner's selected companion.
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.auto_stories_rounded,
                          size: 96,
                          color: SoriColors.primary,
                        ),
                      )
                    : CompanionBuilder(
                        builder: (context, kind) => Mascot(
                          kind: kind,
                          emotion: MascotEmotion.thinking,
                          size: 96,
                        ),
                        noneBuilder: (context) => const Icon(
                          Icons.auto_stories_rounded,
                          size: 96,
                          color: SoriColors.primary,
                        ),
                      ),
              ),
              const SizedBox(height: Spacing.sm),
              Center(
                child: Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(
                    t.bookResultFoundN(r.words.length),
                    style: SoriTextTheme.of(context).h3,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.lg),
              if (offlineStub) ...[
                _ResultNotice(
                  icon: Icons.cloud_off_outlined,
                  message: rateLimited
                      ? t.bookResultRateLimited
                      : credentialsUnavailable
                      ? t.bookResultCredentialsNotice
                      : t.bookResultOfflineNotice,
                ),
                const SizedBox(height: Spacing.md),
              ],
              if (noKoreanText || qualityFiltered || blockedResult) ...[
                _ResultNotice(
                  icon: Icons.fact_check_outlined,
                  message: noKoreanText
                      ? t.bookResultNoKoreanNotice
                      : translationUnavailable
                      ? t.bookResultTranslationUnavailable
                      : t.bookResultQualityNotice,
                ),
                const SizedBox(height: Spacing.md),
              ],
              // 단어 카드
              if (r.words.isNotEmpty) ...[
                _SectionLabel(label: t.bookResultSectionWords),
                ...r.words.map(
                  (w) =>
                      _WordCard(word: w, result: r, allowActions: r.isSaveable),
                ),
                const SizedBox(height: Spacing.lg),
              ],
              if (r.expressions.isNotEmpty) ...[
                _SectionLabel(label: t.bookResultSectionExpressions),
                ...r.expressions.map(
                  (expression) => _ExpressionCard(
                    expression: expression,
                    result: r,
                    allowTts: r.isSaveable,
                  ),
                ),
                const SizedBox(height: Spacing.lg),
              ],
              // 문법 패턴
              if (r.grammar.isNotEmpty) ...[
                _SectionLabel(label: t.bookResultSectionGrammar),
                ...r.grammar.map((g) => _GrammarCard(hit: g, result: r)),
                const SizedBox(height: Spacing.lg),
              ],
              // 문장
              if (r.sentences.isNotEmpty) ...[
                _SectionLabel(label: t.bookResultSectionSentences),
                ...r.sentences.map(
                  (s) => _SentenceCard(
                    sentence: s,
                    result: r,
                    allowTts: r.isSaveable,
                  ),
                ),
                const SizedBox(height: Spacing.lg),
              ],
              if (feedbackCompletion != null &&
                  feedbackScope != null &&
                  feedbackScope.featureGate.isEnabled) ...[
                ContentFeedbackCard(
                  feedbackContext: feedbackCompletion.context,
                  featureGate: feedbackScope.featureGate,
                  submitFeedback: feedbackScope.submitFeedback,
                ),
                const SizedBox(height: Spacing.md),
              ],
              const SizedBox(height: Spacing.md),
              if (blockedResult) ...[
                if (!noKoreanText) ...[
                  SoriButton(
                    label: t.btnRetry,
                    icon: Icons.refresh_rounded,
                    variant: SoriButtonVariant.filled,
                    accent: SoriColors.primary,
                    fullWidth: true,
                    onTap: () => _analyze(_analysisLanguage ?? 'de'),
                  ),
                  const SizedBox(height: Spacing.sm),
                ],
                SoriButton(
                  label: t.bookPreviewRetake,
                  icon: Icons.replay_outlined,
                  variant: SoriButtonVariant.outlined,
                  fullWidth: true,
                  onTap: () => Navigator.of(context).popUntil(
                    (route) => route.settings.name == '/book' || route.isFirst,
                  ),
                ),
              ] else if (_saveUnresolved) ...[
                _ResultNotice(
                  icon: Icons.sync_problem_rounded,
                  message: t.bookResultSaveUnresolvedBody,
                ),
                const SizedBox(height: Spacing.sm),
                SoriButton(
                  label: t.bookResultSaveUnresolved,
                  icon: Icons.sync_problem_rounded,
                  variant: SoriButtonVariant.outlined,
                  fullWidth: true,
                  onTap: null,
                ),
              ] else if (!_saved)
                _saving
                    ? Semantics(
                        container: true,
                        liveRegion: true,
                        label: t.bookResultSaving,
                        button: true,
                        enabled: false,
                        excludeSemantics: true,
                        child: SoriButton(
                          label: t.bookResultSaving,
                          icon: Icons.bookmark_add_outlined,
                          variant: SoriButtonVariant.filled,
                          accent: SoriColors.primary,
                          fullWidth: true,
                          onTap: null,
                        ),
                      )
                    : SoriButton(
                        label: t.bookResultSave,
                        icon: Icons.bookmark_add_outlined,
                        variant: SoriButtonVariant.filled,
                        accent: SoriColors.primary,
                        fullWidth: true,
                        onTap: _saveIntent.canStart ? _save : null,
                      )
              else ...[
                if (r.words.isNotEmpty) ...[
                  SoriButton(
                    label: t.bookshelfCreatePackCta,
                    icon: Icons.style_outlined,
                    variant: SoriButtonVariant.filled,
                    accent: SoriColors.primary,
                    fullWidth: true,
                    onTap: () => _createCustomPack(t),
                  ),
                  const SizedBox(height: Spacing.sm),
                ],
                SoriButton(
                  label: t.bookResultBackToCapture,
                  icon: Icons.add_a_photo_outlined,
                  variant: SoriButtonVariant.outlined,
                  fullWidth: true,
                  onTap: () => Navigator.of(
                    context,
                  ).popUntil((r) => r.settings.name == '/book' || r.isFirst),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _guard(Widget child) => PopScope(canPop: !_saving, child: child);

  Future<void> _createCustomPack(AppL10n t) async {
    final res = _result;
    if (res == null || !res.isSaveable || res.words.isEmpty) {
      return;
    }
    final defaultName =
        'Pack ${DateTime.now().toIso8601String().substring(0, 10)}';
    final name = await showSoriDialog<String>(
      context: context,
      builder: (_) => _CreatePackNameDialog(initialName: defaultName),
    );
    if (name == null || name.isEmpty) return;
    // 임시 BookPage 빌드 — 저장 안 됐을 수도 있으니 ephemeral.
    final tempPage = BookPage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      localThumbnailPath: null,
      extractedText: _safeText,
      note: '',
      words: res.words,
      grammar: res.grammar,
      sentences: res.sentences,
      expressions: res.expressions,
      capturedAtIso: DateTime.now().toUtc().toIso8601String(),
      customPackId: null,
      analysisLanguage: res.analysisLanguage,
    );
    final pack = await CustomPackService.createFromPage(
      page: tempPage,
      name: name,
    );
    if (!mounted) return;
    await showSoriActionNotice(
      context: context,
      message: t.bookshelfCreatePackSaved,
      dismissLabel: t.btnClose,
      actionLabel: t.btnPlay,
      onAction: () => Navigator.of(
        context,
      ).pushNamed('/custom_pack/play', arguments: pack.id),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, Spacing.sm, 4, Spacing.sm),
      child: Semantics(
        header: true,
        child: Text(label, style: SoriTextTheme.of(context).label),
      ),
    );
  }
}

class _ResultNotice extends StatelessWidget {
  const _ResultNotice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: ExcludeSemantics(
        child: SoriCard(
          variant: SoriCardVariant.compact,
          accent: SoriColors.warning,
          tinted: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: SoriColors.warning, size: 18),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: SoriTextTheme.of(context).bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookResultListenButton extends StatelessWidget {
  const _BookResultListenButton({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final label = '${AppL10n.of(context).ttsListen}: $text';
    void play() {
      // ignore: discarded_futures
      TtsService.speak(text);
    }

    return Semantics(
      button: true,
      enabled: true,
      label: label,
      onTap: play,
      excludeSemantics: true,
      child: IconButton(
        tooltip: label,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        icon: const Icon(
          Icons.volume_up_rounded,
          size: 22,
          color: SoriColors.primary,
        ),
        onPressed: play,
      ),
    );
  }
}

class _CreatePackNameDialog extends StatefulWidget {
  const _CreatePackNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_CreatePackNameDialog> createState() => _CreatePackNameDialogState();
}

class _CreatePackNameDialogState extends State<_CreatePackNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriDialog(
      title: Text(t.bookshelfCreatePackTitle),
      content: SoriTextField(
        controller: _controller,
        autofocus: true,
        labelText: t.bookshelfCreatePackName,
        hintText: t.bookshelfCreatePackNameHint,
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(t.btnCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(t.btnConfirm),
        ),
      ],
    );
  }
}

class _ExpressionCard extends StatelessWidget {
  const _ExpressionCard({
    required this.expression,
    required this.result,
    required this.allowTts,
  });

  final ExtractedExpression expression;
  final BookAnalysisResult result;
  final bool allowTts;

  @override
  Widget build(BuildContext context) {
    final meaning =
        expression.translationLanguage == 'en' &&
            expression.translationEn.isNotEmpty
        ? expression.translationEn
        : expression.translationDe;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: SoriCard(
        variant: SoriCardVariant.compact,
        accent: SoriColors.success,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(expression.korean, style: SoriTextTheme.of(context).h3),
                  if (meaning.isNotEmpty) ...<Widget>[
                    const SizedBox(height: Spacing.xs),
                    Text(meaning, style: SoriTextTheme.of(context).bodySmall),
                  ],
                ],
              ),
            ),
            GroundedBookAskButton(
              result: result,
              target: GroundedBookTarget.forExpression(expression),
            ),
            if (allowTts) _BookResultListenButton(text: expression.korean),
          ],
        ),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final ExtractedWord word;
  final BookAnalysisResult result;
  final bool allowActions;
  const _WordCard({
    required this.word,
    required this.result,
    required this.allowActions,
  });

  @override
  Widget build(BuildContext context) {
    final meaning =
        word.translationLanguage == 'en' && word.translationEn.isNotEmpty
        ? word.translationEn
        : word.translationDe;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: SoriCard(
        variant: SoriCardVariant.compact,
        accent: SoriColors.info,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(word.korean, style: SoriTextTheme.of(context).h2),
                ),
                if (allowActions) ...[
                  GroundedBookAskButton(
                    result: result,
                    target: GroundedBookTarget.forWord(word),
                  ),
                  AddToWordbookButton(
                    korean: word.korean,
                    translationDe: word.translationDe,
                    translationEn: word.translationEn,
                    translationLanguage: word.translationLanguage,
                    romanization: word.romanization,
                    posDe: word.posDe,
                    exampleKorean: word.exampleKorean,
                    exampleDe: word.exampleDe,
                    compact: true,
                  ),
                  _BookResultListenButton(text: word.korean),
                ],
              ],
            ),
            if (word.romanization.isNotEmpty)
              Text(
                '[${word.romanization}]',
                style: SoriTextTheme.of(
                  context,
                ).caption.copyWith(fontStyle: FontStyle.italic),
              ),
            if (meaning.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                meaning,
                style: SoriTextTheme.of(
                  context,
                ).bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
            if (word.posDe.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(word.posDe, style: SoriTextTheme.of(context).cardSubtitle),
            ],
            if (word.definitionKo.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                word.definitionKo,
                style: SoriTextTheme.of(context).caption.copyWith(height: 1.35),
              ),
            ],
            if (word.exampleKorean.isNotEmpty) ...[
              const SizedBox(height: Spacing.sm),
              Container(
                padding: const EdgeInsets.all(Spacing.sm),
                decoration: BoxDecoration(
                  color: SoriColors.primary.withValues(alpha: 0.06),
                  borderRadius: SoriRadius.brSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.exampleKorean,
                      style: SoriTextTheme.of(context).bodySmall,
                    ),
                    if (word.exampleDe.isNotEmpty)
                      Text(
                        word.exampleDe,
                        style: SoriTextTheme.of(
                          context,
                        ).caption.copyWith(fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GrammarCard extends StatelessWidget {
  final GrammarHit hit;
  final BookAnalysisResult result;
  const _GrammarCard({required this.hit, required this.result});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: SoriCard(
        variant: SoriCardVariant.compact,
        accent: SoriColors.warning,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    hit.nameDe,
                    style: SoriTextTheme.of(context).cardTitle,
                  ),
                ),
                GroundedBookAskButton(
                  result: result,
                  target: GroundedBookTarget.forGrammar(hit),
                ),
                SoriChip(label: hit.level, accent: SoriColors.warning),
              ],
            ),
            if (hit.matchedText.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '"${hit.matchedText}"',
                style: SoriTextTheme.of(
                  context,
                ).bodySmall.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
            if (hit.explanationDe.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(hit.explanationDe, style: SoriTextTheme.of(context).caption),
            ],
          ],
        ),
      ),
    );
  }
}

class _SentenceCard extends StatelessWidget {
  final TranslatedSentence sentence;
  final BookAnalysisResult result;
  final bool allowTts;
  const _SentenceCard({
    required this.sentence,
    required this.result,
    required this.allowTts,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: SoriCard(
        variant: SoriCardVariant.compact,
        accent: SoriColors.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    sentence.korean,
                    style: SoriTextTheme.of(context).h3,
                  ),
                ),
                GroundedBookAskButton(
                  result: result,
                  target: GroundedBookTarget.forSentence(sentence),
                ),
                if (allowTts) _BookResultListenButton(text: sentence.korean),
              ],
            ),
            if (sentence.translationDe.isNotEmpty)
              Text(
                sentence.translationDe,
                style: SoriTextTheme.of(
                  context,
                ).bodySmall.copyWith(fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }
}
