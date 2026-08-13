import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/book_page.dart';
import '../models/feedback_completion.dart';
import '../services/analytics_service.dart';
import '../services/book_analysis_service.dart';
import '../services/book_image_service.dart';
import '../services/bookshelf_service.dart';
import '../services/custom_pack_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/mascot_preference.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';
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

  const BookResultScreen({super.key, required this.args, this.analyzer});

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
  String get _text => widget.args['text'] as String? ?? '';
  String? get _imageLease => widget.args['imageLease'] as String?;

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
      final res = await (widget.analyzer ?? BookAnalysisService.analyze)(
        text: _text,
        targetLang: targetLang,
      );
      if (!res.warnings.contains('offline_stub')) {
        await Storage.incBookSnapCountToday();
      }
      unawaited(
        Analytics.bookCaptureAnalyzed(
          targetLang: targetLang,
          words: res.words.length,
          offline: res.warnings.contains('offline_stub'),
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
    if (res == null || !_saveIntent.canStart) return;
    final operation = _saveIntent.run((pageId, capturedAtIso) async {
      final page = BookPage(
        id: pageId,
        localThumbnailPath: null,
        extractedText: _text,
        note: '',
        words: res.words,
        grammar: res.grammar,
        sentences: res.sentences,
        capturedAtIso: capturedAtIso,
        customPackId: null,
      );
      final lease = PendingMediaLease.tryParse(_imageLease);
      if (lease == null) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.bookCaptureErrorUnknown),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    } on Object {
      if (!mounted) return;
      final t = AppL10n.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${t.bookCaptureErrorUnknown} ${t.btnRetry}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppL10n.of(context).bookResultSaved),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_loading) {
      return _guard(
        Scaffold(
          appBar: AppBar(title: Text(t.bookResultTitle)),
          body: AppLoading(
            message: t.bookResultAnalyzing,
            asset: 'assets/illustrations/book/book_analyzing.png',
          ),
        ),
      );
    }
    if (_error != null || _result == null) {
      return _guard(
        Scaffold(
          appBar: AppBar(title: Text(t.bookResultTitle)),
          body: AppError(
            message: _error ?? 'unknown',
            onRetry: () => _analyze(_analysisLanguage ?? 'de'),
            asset: 'assets/illustrations/book/book_error.png',
          ),
        ),
      );
    }

    final r = _result!;
    final feedbackCompletion = _feedbackCompletion.current;
    final feedbackScope = ContentFeedbackControllerScope.maybeOf(context);
    final s = SoriSurfaces.of(context);
    final offlineStub = r.warnings.contains('offline_stub');
    final rateLimited = r.warnings.contains('server_rate_limited');
    final credentialsUnavailable = r.warnings.contains(
      'remote_credentials_unavailable',
    );

    return _guard(
      Scaffold(
        appBar: AppBar(
          title: Text(
            t.bookResultTitle,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: const [TtsSpeedAction()],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: soriClampPadding(
                constraints.maxWidth,
                base: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              ),
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
                    child: Text(
                      t.bookResultFoundN(r.words.length),
                      style: SoriTextTheme.of(context).h3,
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  if (offlineStub) ...[
                    SoriCard(
                      variant: SoriCardVariant.compact,
                      accent: SoriColors.warning,
                      tinted: true,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cloud_off_outlined,
                            color: SoriColors.warning,
                            size: 18,
                          ),
                          const SizedBox(width: Spacing.sm),
                          Expanded(
                            child: Text(
                              rateLimited
                                  ? t.bookResultRateLimited
                                  : credentialsUnavailable
                                  ? t.bookResultCredentialsNotice
                                  : t.bookResultOfflineNotice,
                              style: TextStyle(
                                fontSize: 12,
                                color: s.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                  ],
                  // 단어 카드
                  if (r.words.isNotEmpty) ...[
                    _SectionLabel(label: t.bookResultSectionWords),
                    ...r.words.map((w) => _WordCard(word: w)),
                    const SizedBox(height: Spacing.lg),
                  ],
                  // 문법 패턴
                  if (r.grammar.isNotEmpty) ...[
                    _SectionLabel(label: t.bookResultSectionGrammar),
                    ...r.grammar.map((g) => _GrammarCard(hit: g)),
                    const SizedBox(height: Spacing.lg),
                  ],
                  // 문장
                  if (r.sentences.isNotEmpty) ...[
                    _SectionLabel(label: t.bookResultSectionSentences),
                    ...r.sentences
                        .take(8)
                        .map((s) => _SentenceCard(sentence: s)),
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
                  if (!_saved)
                    SoriButton(
                      label: t.bookResultSave,
                      icon: Icons.bookmark_add_outlined,
                      variant: SoriButtonVariant.filled,
                      accent: SoriColors.primary,
                      fullWidth: true,
                      onTap: _save,
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
                      accent: SoriColors.info,
                      fullWidth: true,
                      onTap: () => Navigator.of(context).popUntil(
                        (r) => r.settings.name == '/book' || r.isFirst,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _guard(Widget child) => PopScope(canPop: !_saving, child: child);

  Future<void> _createCustomPack(AppL10n t) async {
    final res = _result;
    if (res == null || res.words.isEmpty) return;
    final controller = TextEditingController(
      text: 'Pack ${DateTime.now().toIso8601String().substring(0, 10)}',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.bookshelfCreatePackTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: t.bookshelfCreatePackName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(t.btnCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(t.btnConfirm),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    // 임시 BookPage 빌드 — 저장 안 됐을 수도 있으니 ephemeral.
    final tempPage = BookPage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      localThumbnailPath: null,
      extractedText: _text,
      note: '',
      words: res.words,
      grammar: res.grammar,
      sentences: res.sentences,
      capturedAtIso: DateTime.now().toUtc().toIso8601String(),
      customPackId: null,
    );
    final pack = await CustomPackService.createFromPage(
      page: tempPage,
      name: name,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.bookshelfCreatePackSaved),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: t.btnPlay,
          onPressed: () => Navigator.of(
            context,
          ).pushNamed('/custom_pack/play', arguments: pack.id),
        ),
      ),
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
      child: Text(
        label,
        style: SoriTextTheme.of(
          context,
        ).bodySmall.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.4),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final ExtractedWord word;
  const _WordCard({required this.word});

  @override
  Widget build(BuildContext context) {
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
                AddToWordbookButton(
                  korean: word.korean,
                  translationDe: word.translationDe,
                  translationEn: word.translationEn,
                  romanization: word.romanization,
                  posDe: word.posDe,
                  exampleKorean: word.exampleKorean,
                  exampleDe: word.exampleDe,
                  compact: true,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.volume_up_rounded, size: 22),
                  onPressed: () {
                    // ignore: discarded_futures
                    TtsService.speak(word.korean);
                  },
                ),
              ],
            ),
            if (word.romanization.isNotEmpty)
              Text(
                '[${word.romanization}]',
                style: SoriTextTheme.of(
                  context,
                ).caption.copyWith(fontStyle: FontStyle.italic),
              ),
            if (word.translationDe.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                word.translationDe,
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
                  borderRadius: BorderRadius.circular(SoriRadius.sm),
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
  const _GrammarCard({required this.hit});

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
  const _SentenceCard({required this.sentence});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(SoriRadius.md),
        border: Border.all(color: SoriColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  sentence.korean,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.volume_up_rounded, size: 18),
                onPressed: () {
                  // ignore: discarded_futures
                  TtsService.speak(sentence.korean);
                },
              ),
            ],
          ),
          if (sentence.translationDe.isNotEmpty)
            Text(
              sentence.translationDe,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: s.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}
