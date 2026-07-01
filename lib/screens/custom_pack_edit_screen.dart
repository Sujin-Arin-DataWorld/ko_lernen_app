import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/book_page.dart';
import '../models/custom_pack.dart';
import '../services/book_analysis_service.dart';
import '../services/custom_pack_service.dart';
import '../services/tts_service.dart';
import '../services/word_image_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/spotlight_coach.dart';
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

class _CustomPackEditScreenState extends State<CustomPackEditScreen>
    with ScreenCoachMixin<CustomPackEditScreen> {
  CustomPack? _pack;

  // ── 코치마크 타겟 ──
  final GlobalKey _fabKey = GlobalKey();
  final GlobalKey _modeRowKey = GlobalKey();

  @override
  String get coachId => 'cpEdit';

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _fabKey,
        title: t.coachCpEditStep1Title,
        body: t.coachCpEditStep1Body,
        icon: Icons.add_rounded,
      ),
      SpotlightStep(
        targetKey: _modeRowKey,
        title: t.coachCpEditStep2Title,
        body: t.coachCpEditStep2Body,
        icon: Icons.grid_view_rounded,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _pack = CustomPackService.getById(widget.packId);
    scheduleCoach();
  }

  void _reload() {
    setState(() => _pack = CustomPackService.getById(widget.packId));
  }

  Future<void> _addOrEdit({int? index}) async {
    final pack = _pack;
    if (pack == null) return;
    final existing = index != null ? pack.words[index] : null;
    final result = await showSoriSheet<ExtractedWord>(
      context: context,
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

  /// CSV 붙여넣기 → 파싱 → 일괄 추가. 한 줄: 한국어,뜻,예문(옵션).
  Future<void> _importCsv() async {
    final pack = _pack;
    if (pack == null) return;
    final t = AppL10n.of(context);
    final controller = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.csvImportTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.csvImportHint,
              style: const TextStyle(fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 4,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: '안녕하세요, Hallo, 안녕하세요!\n사과, Apfel',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.btnCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(t.csvImportButton),
          ),
        ],
      ),
    );
    if (raw == null || raw.trim().isEmpty) return;

    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n'));

    final words = <ExtractedWord>[];
    for (final row in rows) {
      if (row.isEmpty) continue;
      final korean = row[0].toString().trim();
      if (korean.isEmpty) continue;
      final meaning = row.length > 1 ? row[1].toString().trim() : '';
      final example = row.length > 2 ? row[2].toString().trim() : '';
      words.add(
        ExtractedWord.manual(
          korean: korean,
          translationDe: meaning,
          exampleKorean: example,
        ),
      );
    }

    if (!mounted) return;
    if (words.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.csvImportEmpty)));
      return;
    }
    await CustomPackService.addWords(pack.id, words);
    _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.csvImportResult(words.length))));
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
        title: Text(
          pack.displayName(),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: t.csvImportTitle,
            onPressed: _importCsv,
          ),
          IconButton(
            icon: const Icon(Icons.drive_file_rename_outline),
            tooltip: t.wbRenameTitle,
            onPressed: _rename,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: _fabKey,
        onPressed: () => _addOrEdit(),
        backgroundColor: SoriColors.primary,
        icon: const Icon(Icons.add),
        label: Text(t.wbAddWord),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            children: [
              // 학습 모드 4종: 카드 · 짝맞추기 · 받아쓰기 · 퀴즈
              KeyedSubtree(
                key: _modeRowKey,
                child: Padding(
                  padding: soriClampPadding(
                    constraints.maxWidth,
                    base: const EdgeInsets.fromLTRB(
                      Spacing.lg,
                      Spacing.md,
                      Spacing.lg,
                      Spacing.xs,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
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
                              label: t.wbMatching,
                              icon: Icons.grid_view_rounded,
                              variant: SoriButtonVariant.outlined,
                              accent: SoriColors.primary,
                              onTap: words.length < 2
                                  ? null
                                  : () => Navigator.of(context).pushNamed(
                                      '/custom_pack/matching',
                                      arguments: pack.id,
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: SoriButton(
                              label: t.wbTyping,
                              icon: Icons.keyboard_alt_outlined,
                              variant: SoriButtonVariant.outlined,
                              accent: SoriColors.accent,
                              onTap: words.isEmpty
                                  ? null
                                  : () => Navigator.of(context).pushNamed(
                                      '/custom_pack/typing',
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
                    ],
                  ),
                ),
              ), // KeyedSubtree _modeRowKey
              if (words.length < 4)
                Padding(
                  padding: soriClampPadding(
                    constraints.maxWidth,
                    base: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  ),
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
                        padding: soriClampPadding(
                          constraints.maxWidth,
                          base: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                        ),
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
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: s.border),
            borderRadius: BorderRadius.circular(SoriRadius.md),
          ),
          child: Row(
            children: [
              if (word.imagePath.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(SoriRadius.sm),
                  child: Image.file(
                    File(word.imagePath),
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.image_not_supported_outlined,
                      size: 22,
                      color: s.textDim,
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.korean,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
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
  String _imagePath = '';
  bool _autoLoading = false;
  bool _photoBusy = false;
  String? _autoNote;

  @override
  void initState() {
    super.initState();
    _korean = TextEditingController(text: widget.existing?.korean ?? '');
    _meaning = TextEditingController(
      text: widget.existing?.translationDe ?? '',
    );
    _example = TextEditingController(
      text: widget.existing?.exampleKorean ?? '',
    );
    _definitionKo = widget.existing?.definitionKo ?? '';
    _imagePath = widget.existing?.imagePath ?? '';
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_photoBusy) return;
    setState(() => _photoBusy = true);
    final path = await WordImageService.pickAndSave(source);
    if (!mounted) return;
    setState(() {
      _photoBusy = false;
      if (path != null) {
        _imagePath = path;
      }
    });
  }

  void _removeImage() {
    setState(() => _imagePath = '');
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
      imagePath: _imagePath,
    );
    Navigator.of(context).pop(word);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);

    // 시트 외형(둥근 상단·handle·키보드 inset·maxHeight·스크롤)은 SoriSheet 담당.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              icon: Icon(Icons.volume_up_rounded, color: SoriColors.primary),
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
          Text(
            _definitionKo,
            style: TextStyle(fontSize: 12, color: s.textMuted),
          ),
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
        const SizedBox(height: 14),
        // ── 사진 첨부 ──
        Row(
          children: [
            if (_imagePath.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(SoriRadius.sm),
                child: Image.file(
                  File(_imagePath),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.image_not_supported_outlined,
                    color: s.textDim,
                  ),
                ),
              )
            else
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: s.border.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(SoriRadius.sm),
                ),
                child: Icon(Icons.image_outlined, color: s.textDim),
              ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  TextButton.icon(
                    onPressed: _photoBusy
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: Text(t.wbPhotoCamera),
                  ),
                  TextButton.icon(
                    onPressed: _photoBusy
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: Text(t.wbPhotoGallery),
                  ),
                  if (_imagePath.isNotEmpty)
                    TextButton.icon(
                      onPressed: _removeImage,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(t.wbPhotoRemove),
                    ),
                ],
              ),
            ),
          ],
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
    );
  }
}
