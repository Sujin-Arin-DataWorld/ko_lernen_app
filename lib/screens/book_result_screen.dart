import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/book_page.dart';
import '../services/book_analysis_service.dart';
import '../services/bookshelf_service.dart';
import '../services/custom_pack_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/tokens.dart';

/// Phase 5 (stately-rising-jongga) — Analysis-Result Screen.
///
/// Args: `{ text: String, imagePath: String? }`.
/// Lädt `BookAnalysisService.analyze(text)` und zeigt Wörter, Grammatik,
/// Sätze. "Speichern" → BookshelfService + Quota-Increment.
class BookResultScreen extends StatefulWidget {
  final Map<String, dynamic> args;
  const BookResultScreen({super.key, required this.args});

  @override
  State<BookResultScreen> createState() => _BookResultScreenState();
}

class _BookResultScreenState extends State<BookResultScreen> {
  bool _loading = true;
  String? _error;
  BookAnalysisResult? _result;
  bool _saved = false;

  String get _text => widget.args['text'] as String? ?? '';
  String? get _imagePath => widget.args['imagePath'] as String?;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Quota erst nach erfolgreichem Aufruf erhöhen — Fehler zählen nicht.
      final res = await BookAnalysisService.analyze(text: _text);
      if (!mounted) return;
      setState(() {
        _result = res;
        _loading = false;
      });
      if (!res.warnings.contains('offline_stub')) {
        await Storage.incBookSnapCountToday();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _save() async {
    final res = _result;
    if (res == null) return;
    final page = BookPage(
      id: BookshelfService.generateId(),
      localThumbnailPath: _imagePath,
      extractedText: _text,
      note: '',
      words: res.words,
      grammar: res.grammar,
      sentences: res.sentences,
      capturedAtIso: DateTime.now().toUtc().toIso8601String(),
      customPackId: null,
    );
    await BookshelfService.save(page);
    if (!mounted) return;
    setState(() => _saved = true);
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
      return Scaffold(
        appBar: AppBar(title: Text(t.bookResultTitle)),
        body: AppLoading(message: t.bookResultAnalyzing),
      );
    }
    if (_error != null || _result == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.bookResultTitle)),
        body: AppError(message: _error ?? 'unknown', onRetry: _analyze),
      );
    }

    final r = _result!;
    final s = SoriSurfaces.of(context);
    final offlineStub = r.warnings.contains('offline_stub');

    return Scaffold(
      appBar: AppBar(
        title: Text(t.bookResultTitle,
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Center(
              child: Mascot(
                kind: MascotKind.tiger,
                emotion: r.words.isNotEmpty
                    ? MascotEmotion.celebrate
                    : MascotEmotion.thinking,
                size: 96,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Center(
              child: Text(
                t.bookResultFoundN(r.words.length),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800),
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
                    const Icon(Icons.cloud_off_outlined,
                        color: SoriColors.warning, size: 18),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        t.bookResultOfflineNotice,
                        style: TextStyle(fontSize: 12, color: s.textMuted),
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
              ...r.sentences.take(8).map((s) => _SentenceCard(sentence: s)),
              const SizedBox(height: Spacing.lg),
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
    );
  }

  Future<void> _createCustomPack(AppL10n t) async {
    final res = _result;
    if (res == null || res.words.isEmpty) return;
    final controller = TextEditingController(
      text:
          'Pack ${DateTime.now().toIso8601String().substring(0, 10)}',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.bookshelfCreatePackTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: t.bookshelfCreatePackName,
          ),
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
    if (name == null || name.isEmpty) return;
    // 임시 BookPage 빌드 — 저장 안 됐을 수도 있으니 ephemeral.
    final tempPage = BookPage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      localThumbnailPath: _imagePath,
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
          onPressed: () => Navigator.of(context).pushNamed(
            '/custom_pack/play',
            arguments: pack.id,
          ),
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
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.4),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final ExtractedWord word;
  const _WordCard({required this.word});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(SoriRadius.md),
        border: Border.all(color: SoriColors.info.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  word.korean,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800),
                ),
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
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: s.textMuted,
              ),
            ),
          if (word.translationDe.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              word.translationDe,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
          if (word.posDe.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              word.posDe,
              style: TextStyle(fontSize: 11, color: s.textMuted),
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
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (word.exampleDe.isNotEmpty)
                    Text(
                      word.exampleDe,
                      style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: s.textMuted),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GrammarCard extends StatelessWidget {
  final GrammarHit hit;
  const _GrammarCard({required this.hit});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(SoriRadius.md),
        border: Border.all(color: SoriColors.warning.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hit.nameDe,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
              SoriChip(label: hit.level, accent: SoriColors.warning),
            ],
          ),
          if (hit.matchedText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '"${hit.matchedText}"',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: s.textMuted,
              ),
            ),
          ],
          if (hit.explanationDe.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              hit.explanationDe,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ],
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
        border: Border.all(
            color: SoriColors.primary.withValues(alpha: 0.18)),
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
                      fontSize: 14, fontWeight: FontWeight.w600),
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
