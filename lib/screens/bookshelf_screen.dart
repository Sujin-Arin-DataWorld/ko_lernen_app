import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/book_page.dart';
import '../models/custom_pack.dart';
import '../services/bookshelf_service.dart';
import '../services/custom_pack_service.dart';
import '../services/shared_pack_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/page_header.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';

/// Phase 5.1 (stately-rising-jongga) — 내 책장 (Bookshelf) 목록.
///
/// 두 섹션:
///  1. 저장된 책 페이지 (BookshelfService.getAllLocal)
///  2. 커스텀 팩 (CustomPackService.getAll)
///
/// 빈 책장 → SoriEmptyState + "사진 찍기" CTA → /book.
class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({super.key});

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen>
    with ScreenCoachMixin<BookshelfScreen> {
  late List<BookPage> _pages;
  late List<CustomPack> _packs;

  // ── 코치마크 타겟 ──
  final GlobalKey _createKey = GlobalKey();
  final GlobalKey _searchKey = GlobalKey();

  @override
  String get coachId => 'bookshelf';

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _createKey,
        title: t.coachBookshelfStep1Title,
        body: t.coachBookshelfStep1Body,
        icon: Icons.playlist_add_rounded,
      ),
      SpotlightStep(
        targetKey: _searchKey,
        title: t.coachBookshelfStep2Title,
        body: t.coachBookshelfStep2Body,
        icon: Icons.search_rounded,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _reload();
    scheduleCoach();
  }

  void _reload() {
    setState(() {
      _pages = BookshelfService.getAllLocal();
      _packs = CustomPackService.getAll();
    });
  }

  /// AppBar 액션 — 친구 코드로 팩 가져오기.
  Widget _redeemAction(AppL10n t) => IconButton(
    icon: const Icon(Icons.download_outlined),
    tooltip: t.redeemTooltip,
    onPressed: _openRedeem,
  );

  /// 커스텀팩 공유 시트 (코드 생성 + 복사 + OS 공유).
  Future<void> _sharePack(CustomPack pack) async {
    await showSoriSheet<void>(
      context: context,
      builder: (_) => _SharePackSheet(pack: pack),
    );
  }

  /// 코드 입력 다이얼로그 → 성공 시 로컬 import + 새로고침.
  Future<void> _openRedeem() async {
    final imported = await showDialog<CustomPack>(
      context: context,
      builder: (_) => const _RedeemDialog(),
    );
    if (imported == null || !mounted) return;
    _reload();
    final t = AppL10n.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          t.redeemSuccess(imported.displayName(), imported.totalWords),
        ),
      ),
    );
  }

  /// 빈 "나만의 단어장" 생성 → 이름 입력 → 편집 화면으로 이동.
  Future<void> _createWordbook() async {
    final t = AppL10n.of(context);
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.createWordbookTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: t.wbRenameLabel,
            hintText: t.createWordbookHint,
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
    if (name == null || name.isEmpty || !mounted) return;
    final pack = await CustomPackService.createEmpty(name: name);
    if (!mounted) return;
    await Navigator.of(
      context,
    ).pushNamed('/custom_pack/edit', arguments: pack.id);
    _reload();
  }

  Widget _createAction(AppL10n t) => IconButton(
    key: _createKey,
    icon: const Icon(Icons.playlist_add_rounded),
    tooltip: t.createWordbookCta,
    onPressed: _createWordbook,
  );

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_pages.isEmpty && _packs.isEmpty) {
      return SoriStandardPage(
        appBarTitle: t.bookshelfTitle,
        headline: t.bookshelfTitle,
        actions: [_createAction(t), _redeemAction(t)],
        maxWidth: SoriMaxWidth.hub,
        children: [
          SoriEmptyState(
            asset: 'assets/illustrations/book/book_empty_shelf.png',
            icon: Icons.menu_book_outlined,
            title: t.bookshelfEmptyTitle,
            body: t.bookshelfEmptyBody,
            ctaLabel: t.bookshelfEmptyCta,
            onCta: () =>
                Navigator.of(context).pushNamed('/book').then((_) => _reload()),
            secondaryLabel: t.createWordbookCta,
            onSecondary: _createWordbook,
          ),
        ],
      );
    }

    return SoriStandardFrame(
      appBarTitle: t.bookshelfTitle,
      actions: [
        IconButton(
          key: _searchKey,
          icon: const Icon(Icons.search_rounded),
          tooltip: t.wbSearchTitle,
          onPressed: () => Navigator.of(context).pushNamed('/wordbook/search'),
        ),
        _createAction(t),
        _redeemAction(t),
        IconButton(
          icon: const Icon(Icons.add_a_photo_outlined),
          tooltip: t.bookshelfAddPage,
          onPressed: () =>
              Navigator.of(context).pushNamed('/book').then((_) => _reload()),
        ),
      ],
      maxWidth: SoriMaxWidth.hub,
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.xs,
        Spacing.md,
        Spacing.xxl,
      ),
      builder: (context, pagePadding) => RefreshIndicator(
        onRefresh: () async => _reload(),
        color: SoriColors.primary,
        child: ListView(
          padding: pagePadding,
          children: [
            SoriPageHeader(title: t.bookshelfTitle),
            const SizedBox(height: Spacing.xl),
            const HanokHeader(
              asset: 'assets/illustrations/hanok/calligraphy.png',
              fallbackIcon: Icons.menu_book_outlined,
            ),
            const SizedBox(height: Spacing.md),
            if (_packs.isNotEmpty) ...[
              _SectionHeader(label: t.bookshelfSectionCustomPacks),
              ..._packs.map(
                (p) => _CustomPackTile(
                  pack: p,
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed('/custom_pack/play', arguments: p.id),
                  onEdit: () => Navigator.of(context)
                      .pushNamed('/custom_pack/edit', arguments: p.id)
                      .then((_) => _reload()),
                  onShare: () => _sharePack(p),
                  onDelete: () async {
                    await CustomPackService.delete(p.id);
                    _reload();
                  },
                ),
              ),
              const SizedBox(height: Spacing.lg),
            ],
            if (_pages.isNotEmpty) ...[
              _SectionHeader(label: t.bookshelfSectionPages),
              ..._pages.map(
                (p) => _PageTile(
                  page: p,
                  onTap: () => Navigator.of(context)
                      .pushNamed('/bookshelf/page', arguments: p.id)
                      .then((_) => _reload()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

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

class _PageTile extends StatelessWidget {
  final BookPage page;
  final VoidCallback onTap;
  const _PageTile({required this.page, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final dateLabel = page.capturedAtIso.length >= 10
        ? page.capturedAtIso.substring(0, 10)
        : '';
    final preview = page.extractedText.length > 60
        ? '${page.extractedText.substring(0, 60)}…'
        : page.extractedText;

    return Material(
      color: s.surface,
      borderRadius: BorderRadius.circular(SoriRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(SoriRadius.md),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: Spacing.sm),
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: SoriColors.info.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(SoriRadius.md),
          ),
          child: Row(
            children: [
              Icon(Icons.article_outlined, size: 22, color: SoriColors.info),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preview.isEmpty ? '(leer)' : preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.bookshelfTileMeta(
                        page.words.length,
                        page.grammar.length,
                        dateLabel,
                      ),
                      style: TextStyle(fontSize: 11, color: s.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: s.textDim),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomPackTile extends StatelessWidget {
  final CustomPack pack;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  const _CustomPackTile({
    required this.pack,
    required this.onTap,
    required this.onEdit,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return Material(
      color: SoriColors.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(SoriRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(SoriRadius.md),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: Spacing.sm),
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: SoriColors.primary.withValues(alpha: 0.35),
            ),
            borderRadius: BorderRadius.circular(SoriRadius.md),
          ),
          child: Row(
            children: [
              Icon(Icons.style_outlined, color: SoriColors.primary),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pack.displayName(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      t.bookshelfPackMeta(pack.totalWords),
                      style: TextStyle(fontSize: 11, color: s.textMuted),
                    ),
                  ],
                ),
              ),
              SoriButton(
                label: t.btnPlay,
                variant: SoriButtonVariant.ghost,
                size: SoriButtonSize.sm,
                accent: SoriColors.primary,
                onTap: onTap,
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, color: SoriColors.primary),
                tooltip: t.wbEditTooltip,
                visualDensity: VisualDensity.compact,
                onPressed: onEdit,
              ),
              IconButton(
                icon: Icon(Icons.ios_share_rounded, color: SoriColors.primary),
                tooltip: t.shareTooltip,
                visualDensity: VisualDensity.compact,
                onPressed: onShare,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: s.textDim),
                tooltip: t.btnDelete,
                visualDensity: VisualDensity.compact,
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final t = AppL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.bookshelfDeletePackTitle),
        content: Text(t.bookshelfDeletePackBody(pack.displayName())),
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
    if (ok == true) onDelete();
  }
}

// ════════════════════════════════════════════════════════════════════════
// 공유 시트 — 코드 생성 + 복사 + OS 공유 (Phase 5.2)
// ════════════════════════════════════════════════════════════════════════
class _SharePackSheet extends StatefulWidget {
  final CustomPack pack;
  const _SharePackSheet({required this.pack});

  @override
  State<_SharePackSheet> createState() => _SharePackSheetState();
}

class _SharePackSheetState extends State<_SharePackSheet> {
  String? _code;
  bool _loading = true;
  SharedPackError? _error;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    try {
      final code = await SharedPackService.sharePack(widget.pack);
      if (!mounted) return;
      setState(() {
        _code = code;
        _loading = false;
      });
    } on SharedPackException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.error;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = SharedPackError.network;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final code = _code;

    Widget body;
    if (_loading) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            const CircularProgressIndicator(color: SoriColors.primary),
            const SizedBox(height: 14),
            Text(
              t.shareGenerating,
              style: TextStyle(fontFamily: SoriFonts.sans, color: s.textMuted),
            ),
          ],
        ),
      );
    } else if (code == null) {
      final msg = _error == SharedPackError.empty ? t.shareEmpty : t.shareError;
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(Icons.cloud_off_outlined, color: s.textMuted, size: 32),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: SoriFonts.sans, color: s.text),
            ),
            const SizedBox(height: 16),
            SoriButton(
              label: t.btnClose,
              variant: SoriButtonVariant.ghost,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.shareCodeLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: SoriFonts.sans,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: s.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: SoriColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(SoriRadius.md),
              border: Border.all(
                color: SoriColors.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              code,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: SoriFonts.sans,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
                color: SoriColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.shareExpiryNote,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: SoriFonts.sans,
              fontSize: 11,
              color: s.textDim,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SoriButton(
                  label: t.shareCopyCode,
                  variant: SoriButtonVariant.ghost,
                  accent: SoriColors.primary,
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await Clipboard.setData(ClipboardData(text: code));
                    messenger.showSnackBar(
                      SnackBar(content: Text(t.shareCodeCopied)),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SoriButton(
                  label: t.shareViaApp,
                  accent: SoriColors.primary,
                  onTap: () async {
                    await SharePlus.instance.share(
                      ShareParams(
                        text: t.sharePackBody(
                          widget.pack.displayName(),
                          widget.pack.totalWords,
                          code,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      );
    }

    // 시트 외형(둥근 상단·handle·키보드 inset·스크롤)은 SoriSheet 담당.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t.shareTitle,
          style: const TextStyle(
            fontFamily: SoriFonts.sans,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.pack.displayName(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: SoriFonts.sans,
            fontSize: 12.5,
            color: s.textMuted,
          ),
        ),
        const SizedBox(height: 18),
        body,
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// 코드 입력 다이얼로그 — 친구 코드로 팩 가져오기 (Phase 5.2)
// ════════════════════════════════════════════════════════════════════════
class _RedeemDialog extends StatefulWidget {
  const _RedeemDialog();

  @override
  State<_RedeemDialog> createState() => _RedeemDialogState();
}

class _RedeemDialogState extends State<_RedeemDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    final t = AppL10n.of(context);
    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      final pack = await SharedPackService.redeem(_controller.text);
      if (!mounted) return;
      Navigator.of(context).pop(pack);
    } on SharedPackException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = switch (e.error) {
          SharedPackError.notFound => t.redeemNotFound,
          SharedPackError.expired => t.redeemExpired,
          _ => t.redeemError,
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = t.redeemError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return AlertDialog(
      title: Text(t.redeemTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.redeemHint,
            style: const TextStyle(fontFamily: SoriFonts.sans, fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            enabled: !_loading,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            style: const TextStyle(
              fontFamily: SoriFonts.sans,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              counterText: '',
              errorText: _errorText,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text(t.btnCancel),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(t.redeemAction),
        ),
      ],
    );
  }
}
