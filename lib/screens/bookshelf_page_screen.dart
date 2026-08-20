import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/book_page.dart';
import '../services/bookshelf_service.dart';
import '../services/custom_pack_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/dialog.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/toast.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';
import '../widgets/sori/window_class.dart';

/// Phase 5.1 (stately-rising-jongga) — 책장 페이지 상세.
///
/// 받는 args: `String pageId`.
/// Action:
///   - 단어/문법/문장 모두 표시 (TTS 재생 가능)
///   - "이 페이지로 커스텀 팩 만들기" → 이름 입력 → CustomPack 생성
///   - 페이지 삭제
class BookshelfPageScreen extends StatefulWidget {
  final String pageId;
  const BookshelfPageScreen({super.key, required this.pageId});

  @override
  State<BookshelfPageScreen> createState() => _BookshelfPageScreenState();
}

class _BookshelfPageScreenState extends State<BookshelfPageScreen> {
  BookPage? _page;

  @override
  void initState() {
    super.initState();
    _page = BookshelfService.getById(widget.pageId);
  }

  Future<void> _delete() async {
    final t = AppL10n.of(context);
    final ok = await showSoriDialog<bool>(
      context: context,
      builder: (ctx) => SoriDialog(
        title: Text(t.bookshelfDeletePageTitle),
        content: Text(t.bookshelfDeletePageBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.btnCancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.btnDelete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await BookshelfService.delete(widget.pageId);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _createCustomPack() async {
    final page = _page;
    if (page == null) return;
    final t = AppL10n.of(context);
    final controller = TextEditingController(
      text: page.note.isNotEmpty
          ? page.note
          : 'Pack ${page.capturedAtIso.length >= 10 ? page.capturedAtIso.substring(0, 10) : ''}',
    );
    final name = await showSoriDialog<String>(
      context: context,
      builder: (ctx) => SoriDialog(
        title: Text(t.bookshelfCreatePackTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: t.bookshelfCreatePackName,
            hintText: t.bookshelfCreatePackNameHint,
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
    final pack = await CustomPackService.createFromPage(page: page, name: name);
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

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_page == null) {
      return SoriStandardPage(
        appBarTitle: t.bookshelfPageTitle,
        maxWidth: SoriMaxWidth.prose,
        children: [
          SoriEmptyState(
            asset: 'assets/illustrations/mascot/tiger_sitting2.png',
            icon: Icons.help_outline,
            title: t.bookshelfPageNotFoundTitle,
            body: t.bookshelfPageNotFoundBody,
          ),
        ],
      );
    }

    final page = _page!;
    final s = SoriSurfaces.of(context);
    final hasWords = page.words.isNotEmpty;

    return SoriStandardPage(
      appBarTitle: t.bookshelfPageTitle,
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: t.btnDelete,
          onPressed: _delete,
        ),
        const TtsSpeedAction(),
      ],
      maxWidth: SoriMaxWidth.prose,
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.sm,
        Spacing.lg,
        Spacing.xxl,
      ),
      children: [
        // 추출 원문 미리보기
        Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: SoriColors.info.withValues(alpha: 0.06),
            borderRadius: SoriRadius.brMd,
            border: Border.all(color: SoriColors.info.withValues(alpha: 0.20)),
          ),
          child: Text(
            page.extractedText,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        const SizedBox(height: Spacing.lg),

        if (hasWords) ...[
          SoriButton(
            label: t.bookshelfCreatePackCta,
            icon: Icons.style_outlined,
            variant: SoriButtonVariant.filled,
            accent: SoriColors.primary,
            fullWidth: true,
            onTap: _createCustomPack,
          ),
          const SizedBox(height: Spacing.lg),
        ],

        if (page.words.isNotEmpty) ...[
          _SectionLabel(label: t.bookResultSectionWords),
          ...page.words.map((w) => _MiniWordRow(word: w, s: s)),
          const SizedBox(height: Spacing.lg),
        ],

        if (page.grammar.isNotEmpty) ...[
          _SectionLabel(label: t.bookResultSectionGrammar),
          ...page.grammar.map((g) => _MiniGrammarRow(hit: g, s: s)),
          const SizedBox(height: Spacing.lg),
        ],

        if (page.sentences.isNotEmpty) ...[
          _SectionLabel(label: t.bookResultSectionSentences),
          ...page.sentences
              .take(10)
              .map((sent) => _MiniSentenceRow(sentence: sent, s: s)),
        ],
      ],
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
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _MiniWordRow extends StatelessWidget {
  final ExtractedWord word;
  final SoriSurfaces s;
  const _MiniWordRow({required this.word, required this.s});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: s.text),
                children: [
                  TextSpan(
                    text: word.korean,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (word.translationDe.isNotEmpty)
                    TextSpan(
                      text: '  ${word.translationDe}',
                      style: TextStyle(color: s.textMuted),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.volume_up_rounded, size: 18),
            onPressed: () {
              // ignore: discarded_futures
              TtsService.speak(word.korean);
            },
          ),
        ],
      ),
    );
  }
}

class _MiniGrammarRow extends StatelessWidget {
  final GrammarHit hit;
  final SoriSurfaces s;
  const _MiniGrammarRow({required this.hit, required this.s});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hit.nameDe,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          if (hit.matchedText.isNotEmpty)
            Text(
              '"${hit.matchedText}"',
              style: TextStyle(
                fontSize: 12,
                color: s.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniSentenceRow extends StatelessWidget {
  final TranslatedSentence sentence;
  final SoriSurfaces s;
  const _MiniSentenceRow({required this.sentence, required this.s});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sentence.korean,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sentence.translationDe.isNotEmpty)
                  Text(
                    sentence.translationDe,
                    style: TextStyle(
                      fontSize: 12,
                      color: s.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
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
    );
  }
}
