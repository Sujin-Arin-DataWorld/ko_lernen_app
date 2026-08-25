import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/book_page.dart';
import '../models/custom_pack.dart';
import '../services/book_analysis_service.dart';
import '../services/book_image_service.dart';
import '../services/custom_pack_service.dart';
import '../services/custom_pack_import_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../services/word_image_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/dialog.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/text_field.dart';
import '../widgets/sori/toast.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';
import '../widgets/managed_media_image.dart';

/// "나만의 단어장" 편집 화면 — 단어를 직접 추가·수정·삭제하고, 학습/퀴즈로 이동.
///
/// 참고 앱(VoCat·Quizlet·클래스카드)처럼:
///  - 한국어 + 뜻 직접 입력
///  - "자동 채우기" (Cloud Function 번역 + 우리말샘 뜻풀이)
///  - TTS 발음 미리듣기
///  - 카드 학습(/custom_pack/play) + 객관식 퀴즈(/custom_pack/quiz)
typedef WordImagePicker =
    Future<PendingMediaLease?> Function(
      ImageSource source, {
      required String workflowId,
    });

class CustomPackEditScreen extends StatefulWidget {
  final String packId;
  final WordImagePicker? wordImagePicker;
  const CustomPackEditScreen({
    super.key,
    required this.packId,
    this.wordImagePicker,
  });

  @override
  State<CustomPackEditScreen> createState() => _CustomPackEditScreenState();
}

class _CustomPackEditScreenState extends State<CustomPackEditScreen>
    with ScreenCoachMixin<CustomPackEditScreen> {
  CustomPack? _pack;
  bool _wordDeleteInFlight = false;

  // ── 코치마크 타겟 ──
  final GlobalKey _addWordKey = GlobalKey();
  final GlobalKey _modeRowKey = GlobalKey();

  @override
  String get coachId => 'cpEdit';

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _addWordKey,
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
    if (!mounted) {
      return;
    }
    setState(() => _pack = CustomPackService.getById(widget.packId));
  }

  void _speakKorean(String value) {
    final safe = sanitizeCustomPackKoreanWord(value);
    if (safe.isNotEmpty) {
      TtsService.speak(safe);
    }
  }

  Future<void> _addOrEdit({int? index}) async {
    if (_wordDeleteInFlight) return;
    final pack = _pack;
    if (pack == null) return;
    final existing = index != null ? pack.words[index] : null;
    final result = await showSoriSheet<_WordEditorResult>(
      context: context,
      builder: (_) => _WordEditorSheet(
        existing: existing,
        workflowId: CustomPackService.mediaWorkflowId(pack.id, index, existing),
        imagePicker: widget.wordImagePicker,
      ),
    );
    if (result == null) return;
    if (!mounted) {
      final pending = result.pendingLease;
      if (pending != null) {
        await (await BookImageService.store).discard(pending);
      }
      return;
    }
    try {
      if (index != null) {
        await CustomPackService.updateWordWithMedia(
          packId: pack.id,
          index: index,
          expectedOriginal: existing!,
          word: result.word,
          pendingLease: result.pendingLease,
          removePhoto: result.removePhoto,
        );
      } else if (result.pendingLease != null) {
        await CustomPackService.addWordWithPendingImage(
          pack.id,
          result.word,
          result.pendingLease!,
        );
      } else {
        await CustomPackService.addWord(pack.id, result.word);
      }
      _reload();
    } on Object {
      if (mounted) {
        soriToast(context, AppL10n.of(context).bookCaptureErrorUnknown);
      }
    }
  }

  Future<void> _deleteWord(int index) async {
    if (_wordDeleteInFlight) return;
    final pack = _pack;
    if (pack == null || index < 0 || index >= pack.words.length) return;
    final expectedOriginal = pack.words[index];
    _wordDeleteInFlight = true;
    try {
      final t = AppL10n.of(context);
      final ok = await showSoriDialog<bool>(
        context: context,
        builder: (ctx) => SoriDialog(
          title: Text(t.wbDeleteWordTitle),
          content: Text(t.wbDeleteWordBody),
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
        try {
          await CustomPackService.deleteWord(
            pack.id,
            index,
            expectedOriginal: expectedOriginal,
          );
          _reload();
        } on Object {
          if (mounted) {
            soriToast(context, AppL10n.of(context).bookCaptureErrorUnknown);
          }
        }
      }
    } finally {
      _wordDeleteInFlight = false;
    }
  }

  Future<void> _rename() async {
    if (_wordDeleteInFlight) return;
    final pack = _pack;
    if (pack == null) return;
    final name = await showSoriDialog<String>(
      context: context,
      builder: (_) => _RenamePackDialog(initialName: pack.name),
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
    final language = Localizations.localeOf(context).languageCode == 'en'
        ? 'en'
        : 'de';
    final raw = await showSoriDialog<String>(
      context: context,
      builder: (_) => const _ImportCsvDialog(),
    );
    if (raw == null || raw.trim().isEmpty) return;

    final words = parseCustomPackCsvWords(raw, translationLanguage: language);

    if (!mounted) return;
    if (words.isEmpty) {
      soriToast(context, t.csvImportEmpty);
      return;
    }
    await CustomPackService.addWords(pack.id, words);
    _reload();
    if (!mounted) return;
    soriNotice(context, t.csvImportResult(words.length));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final pack = _pack;

    if (pack == null) {
      return SoriStandardFrame(
        appBarTitle: t.wbEditTitle,
        maxWidth: SoriMaxWidth.form,
        padding: const EdgeInsets.all(Spacing.lg),
        builder: (context, resolvedPadding) => Padding(
          padding: resolvedPadding,
          child: Center(
            child: SoriEmptyState(
              asset: 'assets/illustrations/mascot/tiger_front.png',
              icon: Icons.help_outline,
              title: t.customPackNotFoundTitle,
              body: t.customPackNotFoundBody,
            ),
          ),
        ),
      );
    }

    final words = pack.words;

    return SoriStandardFrame(
      appBarTitle: pack.displayName(),
      maxWidth: SoriMaxWidth.prose,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
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
      builder: (context, resolvedPadding) => ListView(
        padding: EdgeInsets.zero,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          // 학습 모드 4종: 카드 · 짝맞추기 · 받아쓰기 · 퀴즈
          KeyedSubtree(
            key: _modeRowKey,
            child: Padding(
              padding: resolvedPadding.copyWith(
                top: Spacing.md,
                bottom: Spacing.xs,
              ),
              child: Column(
                children: [
                  SoriButton(
                    key: _addWordKey,
                    label: t.wbAddWord,
                    icon: Icons.add,
                    fullWidth: true,
                    onTap: () => _addOrEdit(),
                  ),
                  const SizedBox(height: Spacing.sm),
                  LayoutBuilder(
                    builder: (context, modeConstraints) {
                      final textScale = MediaQuery.textScalerOf(
                        context,
                      ).scale(1);
                      final stack =
                          textScale >= 1.6 ||
                          modeConstraints.maxWidth <
                              SoriAdaptiveWidth.shortcutRow;
                      final itemWidth = stack
                          ? modeConstraints.maxWidth
                          : (modeConstraints.maxWidth - Spacing.md) / 2;
                      return Wrap(
                        spacing: Spacing.md,
                        runSpacing: Spacing.sm,
                        children: [
                          SizedBox(
                            width: itemWidth,
                            child: SoriButton(
                              label: t.wbStudyCards,
                              variant: SoriButtonVariant.outlined,
                              onTap: words.isEmpty
                                  ? null
                                  : () => Navigator.of(context).pushNamed(
                                      '/custom_pack/play',
                                      arguments: pack.id,
                                    ),
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: SoriButton(
                              label: t.wbMatching,
                              variant: SoriButtonVariant.outlined,
                              onTap: words.length < 2
                                  ? null
                                  : () => Navigator.of(context).pushNamed(
                                      '/custom_pack/matching',
                                      arguments: pack.id,
                                    ),
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: SoriButton(
                              label: t.wbTyping,
                              variant: SoriButtonVariant.outlined,
                              onTap: words.isEmpty
                                  ? null
                                  : () => Navigator.of(context).pushNamed(
                                      '/custom_pack/typing',
                                      arguments: pack.id,
                                    ),
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: SoriButton(
                              label: t.wbQuiz,
                              variant: SoriButtonVariant.outlined,
                              onTap: words.length < 4
                                  ? null
                                  : () => Navigator.of(context).pushNamed(
                                      '/custom_pack/quiz',
                                      arguments: pack.id,
                                    ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: Spacing.sm),
                  SoriButton(
                    label: t.vocabNotebookNuanceCta,
                    variant: SoriButtonVariant.outlined,
                    fullWidth: true,
                    onTap: words.length < 2
                        ? null
                        : () => Navigator.of(context).pushNamed(
                            '/vocab_notebook/nuance',
                            arguments: pack.id,
                          ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  SoriButton(
                    label: t.vocabNotebookStudioCta,
                    variant: SoriButtonVariant.outlined,
                    fullWidth: true,
                    onTap: words.isEmpty
                        ? null
                        : () => Navigator.of(context).pushNamed(
                            '/vocab_notebook/studio',
                            arguments: pack.id,
                          ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  SoriButton(
                    label: t.vocabNotebookAddPhoto,
                    variant: SoriButtonVariant.ghost,
                    fullWidth: true,
                    onTap: () => Navigator.of(context).pushNamed(
                      '/vocab_notebook',
                      arguments: <String, dynamic>{'existingPackId': pack.id},
                    ),
                  ),
                ],
              ),
            ),
          ), // KeyedSubtree _modeRowKey
          if (words.length < 4)
            Padding(
              padding: resolvedPadding,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t.quizNeedMore,
                  style: SoriTextTheme.of(context).meta,
                ),
              ),
            ),
          const SizedBox(height: Spacing.sm),
          if (words.isEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 240),
              child: Center(
                child: SoriEmptyState(
                  asset: 'assets/illustrations/mascot/magpie_wave.png',
                  icon: Icons.playlist_add,
                  title: t.wbEmptyTitle,
                  body: t.wbEmptyBody,
                  ctaLabel: t.wbAddWord,
                  onCta: () => _addOrEdit(),
                ),
              ),
            )
          else
            for (var i = 0; i < words.length; i += 1)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  resolvedPadding.left,
                  0,
                  resolvedPadding.right,
                  Spacing.xs,
                ),
                child: _WordTile(
                  word: words[i],
                  meaning: words[i].translationDe,
                  onTap: () => _addOrEdit(index: i),
                  onSpeak: () => _speakKorean(words[i].korean),
                  onDelete: () => _deleteWord(i),
                ),
              ),
          const SizedBox(height: Spacing.xl),
        ],
      ),
    );
  }
}

class _WordTile extends StatelessWidget {
  final ExtractedWord word;
  final String meaning;
  final VoidCallback onTap;
  final VoidCallback onSpeak;
  final VoidCallback onDelete;
  const _WordTile({
    required this.word,
    required this.meaning,
    required this.onTap,
    required this.onSpeak,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final editLabel = '${t.wbEditWordTitle}: ${word.korean}';
    final deleteLabel = '${t.btnDelete}: ${word.korean}';
    return SoriCard(
      variant: SoriCardVariant.compact,
      accent: SoriColors.primary,
      child: Row(
        children: [
          if (word.imagePath.isNotEmpty) ...[
            ManagedMediaImage(
              reference: word.imagePath,
              width: 44,
              height: 44,
              borderRadius: SoriRadius.brSm,
            ),
            const SizedBox(width: Spacing.md),
          ],
          Expanded(
            child: Semantics(
              container: true,
              label: meaning.isEmpty ? word.korean : '${word.korean}. $meaning',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(word.korean, style: SoriTextTheme.of(context).cardTitle),
                  if (meaning.isNotEmpty)
                    Text(meaning, style: SoriTextTheme.of(context).bodySmall),
                ],
              ),
            ),
          ),
          Semantics(
            container: true,
            button: true,
            enabled: true,
            label: editLabel,
            onTap: onTap,
            excludeSemantics: true,
            child: IconButton(
              tooltip: editLabel,
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              icon: Icon(Icons.edit_outlined, color: SoriColors.primary),
              onPressed: onTap,
            ),
          ),
          _CustomPackListenButton(text: word.korean, onSpeak: onSpeak),
          Semantics(
            container: true,
            button: true,
            enabled: true,
            label: deleteLabel,
            onTap: onDelete,
            excludeSemantics: true,
            child: IconButton(
              tooltip: deleteLabel,
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              icon: Icon(Icons.delete_outline, color: s.textDim),
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomPackListenButton extends StatelessWidget {
  const _CustomPackListenButton({required this.text, required this.onSpeak});

  final String text;
  final VoidCallback? onSpeak;

  @override
  Widget build(BuildContext context) {
    final listen = AppL10n.of(context).ttsListen;
    final label = text.isEmpty ? listen : '$listen: $text';
    final enabled = onSpeak != null;
    final s = SoriSurfaces.of(context);
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: label,
      onTap: onSpeak,
      excludeSemantics: true,
      child: IconButton(
        tooltip: label,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        icon: const Icon(Icons.volume_up_rounded, size: 22),
        color: enabled ? SoriColors.primary : s.textDim,
        onPressed: onSpeak,
      ),
    );
  }
}

class _RenamePackDialog extends StatefulWidget {
  const _RenamePackDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenamePackDialog> createState() => _RenamePackDialogState();
}

class _RenamePackDialogState extends State<_RenamePackDialog> {
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
      title: Text(t.wbRenameTitle),
      content: SoriTextField(
        controller: _controller,
        autofocus: true,
        labelText: t.wbRenameLabel,
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => Navigator.of(context).pop(),
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

class _ImportCsvDialog extends StatefulWidget {
  const _ImportCsvDialog();

  @override
  State<_ImportCsvDialog> createState() => _ImportCsvDialogState();
}

class _ImportCsvDialogState extends State<_ImportCsvDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriDialog(
      title: Text(t.csvImportTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.csvImportHint, style: SoriTextTheme.of(context).bodySmall),
          const SizedBox(height: Spacing.sm),
          SoriTextField(
            controller: _controller,
            autofocus: true,
            minLines: 4,
            maxLines: 10,
            hintText: t.customPackCsvHint,
          ),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.btnCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(t.csvImportButton),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// 단어 추가/편집 시트 — 한국어 + 뜻 + 예문 + 자동 채우기 + TTS
// ════════════════════════════════════════════════════════════════════════
class _WordEditorResult {
  const _WordEditorResult({
    required this.word,
    required this.pendingLease,
    required this.removePhoto,
  });

  final ExtractedWord word;
  final PendingMediaLease? pendingLease;
  final bool removePhoto;
}

class _WordEditorSheet extends StatefulWidget {
  final ExtractedWord? existing;
  final String workflowId;
  final WordImagePicker? imagePicker;
  const _WordEditorSheet({
    this.existing,
    required this.workflowId,
    this.imagePicker,
  });

  @override
  State<_WordEditorSheet> createState() => _WordEditorSheetState();
}

class _WordEditorSheetState extends State<_WordEditorSheet> {
  late final TextEditingController _korean;
  late final TextEditingController _meaning;
  late final TextEditingController _example;
  String _definitionKo = '';
  String? _translationLanguage;
  String _translationEn = '';
  String _imagePath = '';
  PendingMediaLease? _pendingLease;
  File? _pendingPreview;
  bool _removePhotoRequested = false;
  bool _submitted = false;
  String get _workflowId => widget.workflowId;
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
    _translationLanguage = widget.existing?.translationLanguage;
    _translationEn = widget.existing?.translationEn ?? '';
    _imagePath = widget.existing?.imagePath ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ignore: discarded_futures
      _consumeRecoveredWord();
    });
  }

  Future<void> _consumeRecoveredWord() async {
    if (!mounted) {
      return;
    }
    PendingMediaLease? claimedLease;
    try {
      await Storage.refreshRecoveredMediaRecords();
      final claim = await Storage.claimRecoveredWordLease(_workflowId);
      for (final encoded in claim.discardedLeases) {
        try {
          await BookImageService.discardEncoded(encoded);
        } on Object {
          // Pending TTL reconciliation retries cleanup.
        }
      }
      final recovered = claim.record;
      if (recovered == null) {
        return;
      }
      final decoded = jsonDecode(recovered);
      if (decoded is! Map || decoded['lease'] is! String) {
        return;
      }
      final lease = PendingMediaLease.tryParse(decoded['lease']);
      if (lease == null || lease.kind != ManagedMediaKind.word) {
        return;
      }
      claimedLease = lease;
      final mediaStore = await BookImageService.store;
      final recoveredFile = await mediaStore.resolvePending(lease);
      if (recoveredFile == null) {
        return;
      }
      if (!mounted) {
        await mediaStore.discard(lease);
        claimedLease = null;
        return;
      }
      setState(() {
        _pendingLease = lease;
        _pendingPreview = recoveredFile;
        _removePhotoRequested = false;
      });
      claimedLease = null;
    } on Object {
      // A failed strict claim leaves the record and pending file untouched.
    } finally {
      if (claimedLease != null) {
        try {
          await (await BookImageService.store).discard(claimedLease);
        } on Object {
          // Pending TTL reconciliation retries cleanup.
        }
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_photoBusy) return;
    setState(() => _photoBusy = true);
    try {
      final lease =
          await (widget.imagePicker?.call(source, workflowId: _workflowId) ??
              WordImageService.pickPending(source, workflowId: _workflowId));
      if (lease == null) {
        return;
      }
      final previous = _pendingLease;
      if (previous != null) {
        try {
          await (await BookImageService.store).discard(previous);
        } on Object {
          // The new lease remains durably recoverable for a later editor.
          rethrow;
        }
      }
      if (!mounted) {
        return;
      }
      final mediaStore = await BookImageService.store;
      setState(() {
        _pendingLease = lease;
        _pendingPreview = mediaStore.pendingFile(lease);
        _removePhotoRequested = false;
      });
      try {
        await Storage.claimRecoveredWordLease(_workflowId);
      } on Object {
        // The editor owns the lease; a duplicate durable recovery record is
        // safe and will be ignored after the pending file is finalized.
      }
    } on CameraPermissionDeniedException {
      if (mounted) {
        setState(
          () => _autoNote = AppL10n.of(context).bookCaptureErrorPermission,
        );
      }
    } on Object {
      if (mounted) {
        setState(() => _autoNote = AppL10n.of(context).bookCaptureErrorUnknown);
      }
    } finally {
      if (mounted) {
        setState(() => _photoBusy = false);
      }
    }
  }

  Future<void> _removeImage() async {
    final pending = _pendingLease;
    if (pending != null) {
      await (await BookImageService.store).discard(pending);
    }
    if (mounted) {
      setState(() {
        _pendingLease = null;
        _pendingPreview = null;
        _imagePath = '';
        _removePhotoRequested = true;
      });
    }
  }

  @override
  void dispose() {
    final pending = _pendingLease;
    if (!_submitted && pending != null) {
      // ignore: discarded_futures
      BookImageService.store
          .then<void>((store) => store.discard(pending))
          .catchError((Object _) {});
    }
    _korean.dispose();
    _meaning.dispose();
    _example.dispose();
    super.dispose();
  }

  Future<void> _autoFill() async {
    final word = sanitizeCustomPackKoreanWord(_korean.text);
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
        _translationLanguage = result.translationLanguage;
        _translationEn = result.translationEn;
        _autoNote = null;
      }
    });
  }

  void _save() {
    final t = AppL10n.of(context);
    final existing = widget.existing;
    final korean = sanitizeCustomPackKoreanWord(_korean.text);
    final language =
        _translationLanguage ??
        (Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'de');
    final meaning = _meaning.text.trim();
    final word = buildCustomPackEditedWord(
      existing: existing,
      korean: korean,
      meaning: meaning,
      translationEn: _translationEn,
      translationLanguage: language,
      exampleKorean: _example.text.trim(),
      definitionKo: _definitionKo,
    );
    if (word.korean.isEmpty) {
      setState(() => _autoNote = t.wbNeedKorean);
      return;
    }
    _submitted = true;
    Navigator.of(context).pop(
      _WordEditorResult(
        word: word,
        pendingLease: _pendingLease,
        removePhoto: _removePhotoRequested,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final koreanForSpeech = sanitizeCustomPackKoreanWord(_korean.text);

    // 시트 외형(둥근 상단·handle·키보드 inset·maxHeight·스크롤)은 SoriSheet 담당.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.existing == null ? t.wbAddWord : t.wbEditWordTitle,
          style: SoriTextTheme.of(context).h3,
        ),
        const SizedBox(height: 16),
        SoriTextField(
          controller: _korean,
          autofocus: widget.existing == null,
          labelText: t.wbFieldKorean,
          onChanged: (_) => setState(() {}),
          suffixIcon: _CustomPackListenButton(
            text: koreanForSpeech,
            onSpeak: koreanForSpeech.isEmpty
                ? null
                : () {
                    // ignore: discarded_futures
                    TtsService.speak(koreanForSpeech);
                  },
          ),
        ),
        const SizedBox(height: 8),
        // 자동 채우기 버튼
        Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
            liveRegion: _autoLoading,
            child: SoriButton(
              label: _autoLoading ? t.wbAutoFillRunning : t.wbAutoFill,
              icon: _autoLoading ? null : Icons.auto_awesome,
              variant: SoriButtonVariant.ghost,
              size: SoriButtonSize.md,
              onTap: _autoLoading ? null : _autoFill,
            ),
          ),
        ),
        if (_autoNote != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: SoriColors.danger,
                  ),
                  const SizedBox(width: Spacing.xs),
                  Expanded(
                    child: Text(
                      _autoNote!,
                      style: SoriTextTheme.of(
                        context,
                      ).bodySmall.copyWith(color: SoriColors.danger),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 4),
        SoriTextField(controller: _meaning, labelText: t.wbFieldMeaning),
        if (_definitionKo.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(_definitionKo, style: SoriTextTheme.of(context).bodySmall),
        ],
        const SizedBox(height: 12),
        SoriTextField(
          controller: _example,
          minLines: 1,
          maxLines: 3,
          labelText: t.wbFieldExample,
        ),
        const SizedBox(height: 14),
        // ── 사진 첨부 ──
        Row(
          children: [
            if (_pendingPreview != null)
              ClipRRect(
                borderRadius: SoriRadius.brSm,
                child: Image.file(
                  _pendingPreview!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.image_not_supported_outlined,
                    color: s.textDim,
                  ),
                ),
              )
            else if (_imagePath.isNotEmpty)
              ManagedMediaImage(
                reference: _imagePath,
                width: 56,
                height: 56,
                borderRadius: SoriRadius.brSm,
              )
            else
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: s.border.withValues(alpha: 0.4),
                  borderRadius: SoriRadius.brSm,
                ),
                child: Icon(Icons.image_outlined, color: s.textDim),
              ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  SoriButton(
                    label: t.wbPhotoCamera,
                    icon: Icons.photo_camera_outlined,
                    variant: SoriButtonVariant.ghost,
                    size: SoriButtonSize.md,
                    onTap: _photoBusy
                        ? null
                        : () => _pickImage(ImageSource.camera),
                  ),
                  SoriButton(
                    label: t.wbPhotoGallery,
                    icon: Icons.photo_library_outlined,
                    variant: SoriButtonVariant.ghost,
                    size: SoriButtonSize.md,
                    onTap: _photoBusy
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                  ),
                  if (_imagePath.isNotEmpty || _pendingPreview != null)
                    SoriButton(
                      label: t.wbPhotoRemove,
                      icon: Icons.delete_outline,
                      variant: SoriButtonVariant.ghost,
                      size: SoriButtonSize.md,
                      destructive: true,
                      onTap: _removeImage,
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
