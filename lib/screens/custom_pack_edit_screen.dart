import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/book_page.dart';
import '../models/custom_pack.dart';
import '../services/book_analysis_service.dart';
import '../services/custom_pack_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/tokens.dart';

/// "나만의 단어장" 편집 화면 — 단어를 직접 추가·수정·삭제하고, 학습/퀴즈로 이동.
///
/// 참고 앱(VoCat·Quizlet·클래스카드)처럼:
///  - 한국어 + 뜻 직접 입력
///  - "자동 채우기" (Cloud Function 번역 + 우리말샘 뜻풀이)
///  - TTS 발음 미리듣기
///  - 카드 학습(/custom_pack/play) + 객관식 퀴즈(/custom_pack/quiz)
class CustomPackEditScreen extends StatefulWidget {
  final String packId;
  const CustomPackEditScreen({super.key, required this.packId});

  @override
  State<CustomPackEditScreen> createState() => _CustomPackEditScreenState();
}

class _CustomPackEditScreenState extends State<CustomPackEditScreen> {
  CustomPack? _pack;

  @override
  void initState() {
    super.initState();
    _pack = CustomPackService.getById(widget.packId);
  }

  void _reload() {
    setState(() => _pack = CustomPackService.getById(widget.packId));
  }

  Future<void> _addOrEdit({int? index}) async {
    final pack = _pack;
    if (pack == null) return;
    final existing = index != null ? pack.words[index] : null;
    final result = await showModalBottomSheet<ExtractedWord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WordEditorSheet(existing: existing),
    );
    if (result == null) return;
    if (index != null) {
      await CustomPackService.updateWord(pack.id, index, result);
    } else {
      await CustomPackService.addWord(pack.id, result);
    }
    _reload();
  }

  Future<void> _deleteWord(int index) async {
    final pack = _pack;
    if (pack == null) return;
    final t = AppL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.wbDeleteWordTitle),
        content: Text(t.wbDeleteWordBody),
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
      await CustomPackService.deleteWord(pack.id, index);
      _reload();
    }
  }

  Future<void> _rename() async {
    final pack = _pack;
    if (pack == null) return;
    final t = AppL10n.of(context);
    final controller = TextEditingController(text: pack.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.wbRenameTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: t.wbRenameLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.btnCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(t.btnConfirm),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await CustomPackService.rename(pack.id, name);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final pack = _pack;

    if (pack == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.wbEditTitle)),
        body: Center(
          child: SoriEmptyState(
            icon: Icons.help_outline,
            title: t.customPackNotFoundTitle,
            body: t.customPackNotFoundBody,
          ),
        ),
      );
    }

    final words = pack.words;

    return Scaffold(
      appBar: AppBar(
        title: Text(pack.displayName(),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.drive_file_rename_outline),
            tooltip: t.wbRenameTitle,
            onPressed: _rename,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(),
        backgroundColor: SoriColors.primary,
        icon: const Icon(Icons.add),
        label: Text(t.wbAddWord),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 학습 / 퀴즈 진입
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.lg, Spacing.md, Spacing.lg, Spacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: SoriButton(
                      label: t.wbStudyCards,
                      icon: Icons.style_outlined,
                      variant: SoriButtonVariant.filled,
                      accent: SoriColors.primary,
                      onTap: words.isEmpty
                          ? null
                          : () => Navigator.of(context).pushNamed(
                                '/custom_pack/play',
                                arguments: pack.id,
                              ),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: SoriButton(
                      label: t.wbQuiz,
                      icon: Icons.quiz_outlined,
                      variant: SoriButtonVariant.outlined,
                      accent: SoriColors.accent,
                      onTap: words.length < 4
                          ? null
                          : () => Navigator.of(context).pushNamed(
                                '/custom_pack/quiz',
                                arguments: pack.id,
                              ),
                    ),
                  ),
                ],
              ),
            ),
            if (words.length < 4)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    t.quizNeedMore,
                    style: TextStyle(fontSize: 11, color: s.textDim),
                  ),
                ),
              ),
            const SizedBox(height: Spacing.sm),
            Expanded(
              child: words.isEmpty
                  ? Center(
                      child: SoriEmptyState(
                        icon: Icons.playlist_add,
                        title: t.wbEmptyTitle,
                        body: t.wbEmptyBody,
                        ctaLabel: t.wbAddWord,
                        onCta: () => _addOrEdit(),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                      itemCount: words.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: Spacing.xs),
                      itemBuilder: (_, i) {
                        final w = words[i];
                        return _WordTile(
                          word: w,
                          onTap: () => _addOrEdit(index: i),
                          onSpeak: () => TtsService.speak(w.korean),
                          onDelete: () => _deleteWord(i),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordTile extends StatelessWidget {
  final ExtractedWord word;
  final VoidCallback onTap;
  final VoidCallback onSpeak;
  final VoidCallback onDelete;
  const _WordTile({
    required this.word,
    required this.onTap,
    required this.onSpeak,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Material(
      color: s.surface,
      borderRadius: BorderRadius.circular(SoriRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(SoriRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md, vertical: Spacing.sm),
          decoration: BoxDecoration(
            border: Border.all(color: s.border),
            borderRadius: BorderRadius.circular(SoriRadius.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.korean,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    if (word.translationDe.isNotEmpty)
                      Text(
                        word.translationDe,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: s.textMuted),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.volume_up_rounded, color: SoriColors.primary),
                visualDensity: VisualDensity.compact,
                onPressed: onSpeak,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: s.textDim),
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// 단어 추가/편집 시트 — 한국어 + 뜻 + 예문 + 자동 채우기 + TTS
// ════════════════════════════════════════════════════════════════════════
class _WordEditorSheet extends StatefulWidget {
  final ExtractedWord? existing;
  const _WordEditorSheet({this.existing});

  @override
  State<_WordEditorSheet> createState() => _WordEditorSheetState();
}

class _WordEditorSheetState extends State<_WordEditorSheet> {
  late final TextEditingController _korean;
  late final TextEditingController _meaning;
  late final TextEditingController _example;
  String _definitionKo = '';
  bool _autoLoading = false;
  String? _autoNote;

  @override
  void initState() {
    super.initState();
    _korean = TextEditingController(text: widget.existing?.korean ?? '');
    _meaning = TextEditingController(text: widget.existing?.translationDe ?? '');
    _example =
        TextEditingController(text: widget.existing?.exampleKorean ?? '');
    _definitionKo = widget.existing?.definitionKo ?? '';
  }

  @override
  void dispose() {
    _korean.dispose();
    _meaning.dispose();
    _example.dispose();
    super.dispose();
  }

  Future<void> _autoFill() async {
    final word = _korean.text.trim();
    final t = AppL10n.of(context);
    if (word.isEmpty) {
      setState(() => _autoNote = t.wbNeedKorean);
      return;
    }
    setState(() {
      _autoLoading = true;
      _autoNote = null;
    });
    final lang = Localizations.localeOf(context).languageCode == 'en'
        ? 'en'
        : 'de';
    final result = await BookAnalysisService.autoFill(word, targetLang: lang);
    if (!mounted) return;
    setState(() {
      _autoLoading = false;
      if (result == null) {
        _autoNote = t.wbAutoFillOffline;
      } else {
        if (result.translationDe.isNotEmpty) {
          _meaning.text = result.translationDe;
        }
        if (result.exampleKorean.isNotEmpty && _example.text.trim().isEmpty) {
          _example.text = result.exampleKorean;
        }
        _definitionKo = result.definitionKo;
        _autoNote = null;
      }
    });
  }

  void _save() {
    final t = AppL10n.of(context);
    final korean = _korean.text.trim();
    if (korean.isEmpty) {
      setState(() => _autoNote = t.wbNeedKorean);
      return;
    }
    final word = ExtractedWord.manual(
      korean: korean,
      translationDe: _meaning.text.trim(),
      exampleKorean: _example.text.trim(),
      definitionKo: _definitionKo,
    );
    Navigator.of(context).pop(word);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                    color: s.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(
              widget.existing == null ? t.wbAddWord : t.wbEditWordTitle,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _korean,
              autofocus: widget.existing == null,
              decoration: InputDecoration(
                labelText: t.wbFieldKorean,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon:
                      Icon(Icons.volume_up_rounded, color: SoriColors.primary),
                  onPressed: () => TtsService.speak(_korean.text.trim()),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 자동 채우기 버튼
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _autoLoading ? null : _autoFill,
                icon: _autoLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(_autoLoading ? t.wbAutoFillRunning : t.wbAutoFill),
              ),
            ),
            if (_autoNote != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  _autoNote!,
                  style: TextStyle(fontSize: 12, color: SoriColors.accent),
                ),
              ),
            const SizedBox(height: 4),
            TextField(
              controller: _meaning,
              decoration: InputDecoration(
                labelText: t.wbFieldMeaning,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_definitionKo.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('📖 $_definitionKo',
                  style: TextStyle(fontSize: 12, color: s.textMuted)),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _example,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: t.wbFieldExample,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            SoriButton(
              label: t.wbSaveWord,
              variant: SoriButtonVariant.filled,
              accent: SoriColors.primary,
              fullWidth: true,
              onTap: _save,
            ),
            const SizedBox(height: 6),
            SoriButton(
              label: t.btnCancel,
              variant: SoriButtonVariant.ghost,
              fullWidth: true,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
