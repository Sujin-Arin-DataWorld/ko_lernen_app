import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/book_page.dart';
import '../services/bookshelf_service.dart';
import '../services/custom_pack_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/dialog.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/text_field.dart';
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
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.btnCancel),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
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
    final date = page.capturedAtIso.length >= 10
        ? page.capturedAtIso.substring(0, 10)
        : '';
    final initialName = page.note.isNotEmpty
        ? page.note
        : t.bookshelfDefaultPackName(date).trim();
    final name = await showSoriDialog<String>(
      context: context,
      builder: (_) => _CreatePagePackDialog(initialName: initialName),
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
    final hasWords = page.words.isNotEmpty;
    final extractedText = page.extractedText.isEmpty
        ? t.bookshelfEmptyPreview
        : page.extractedText;

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
        SoriCard(
          variant: SoriCardVariant.compact,
          accent: SoriColors.info,
          tinted: true,
          child: Text(extractedText, style: SoriTextTheme.of(context).body),
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
          ...page.words.map((w) => _MiniWordRow(word: w)),
          const SizedBox(height: Spacing.lg),
        ],

        if (page.grammar.isNotEmpty) ...[
          _SectionLabel(label: t.bookResultSectionGrammar),
          ...page.grammar.map((g) => _MiniGrammarRow(hit: g)),
          const SizedBox(height: Spacing.lg),
        ],

        if (page.sentences.isNotEmpty) ...[
          _SectionLabel(label: t.bookResultSectionSentences),
          ...page.sentences
              .take(10)
              .map((sent) => _MiniSentenceRow(sentence: sent)),
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
      child: Text(label, style: SoriTextTheme.of(context).label),
    );
  }
}

class _MiniWordRow extends StatelessWidget {
  final ExtractedWord word;
  const _MiniWordRow({required this.word});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(word.korean, style: SoriTextTheme.of(context).cardTitle),
                if (word.translationDe.isNotEmpty)
                  Text(
                    word.translationDe,
                    style: SoriTextTheme.of(context).bodySmall,
                  ),
              ],
            ),
          ),
          _BookshelfListenButton(text: word.korean),
        ],
      ),
    );
  }
}

class _MiniGrammarRow extends StatelessWidget {
  final GrammarHit hit;
  const _MiniGrammarRow({required this.hit});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hit.nameDe, style: SoriTextTheme.of(context).cardTitle),
          if (hit.matchedText.isNotEmpty)
            Text(
              '"${hit.matchedText}"',
              style: SoriTextTheme.of(
                context,
              ).bodySmall.copyWith(fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }
}

class _MiniSentenceRow extends StatelessWidget {
  final TranslatedSentence sentence;
  const _MiniSentenceRow({required this.sentence});
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
                  style: SoriTextTheme.of(context).cardTitle,
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
          _BookshelfListenButton(text: sentence.korean),
        ],
      ),
    );
  }
}

class _BookshelfListenButton extends StatelessWidget {
  const _BookshelfListenButton({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final label = '${AppL10n.of(context).ttsListen}: $text';
    void play() {
      // ignore: discarded_futures
      TtsService.speak(text);
    }

    return Semantics(
      container: true,
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

class _CreatePagePackDialog extends StatefulWidget {
  const _CreatePagePackDialog({required this.initialName});

  final String initialName;

  @override
  State<_CreatePagePackDialog> createState() => _CreatePagePackDialogState();
}

class _CreatePagePackDialogState extends State<_CreatePagePackDialog> {
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
