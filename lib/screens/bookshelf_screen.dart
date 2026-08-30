import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/book_page.dart';
import '../models/custom_pack.dart';
import '../services/bookshelf_service.dart';
import '../services/custom_pack_service.dart';
import '../services/shared_pack_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/dialog.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/page_header.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/text_field.dart';
import '../widgets/sori/toast.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';

typedef SharePackCodeGenerator = Future<String> Function(CustomPack pack);
typedef SharedPackRedeemer = Future<CustomPack> Function(String code);

/// Phase 5.1 (stately-rising-jongga) — 내 책장 (Bookshelf) 목록.
///
/// 두 섹션:
///  1. 저장된 책 페이지 (BookshelfService.getAllLocal)
///  2. 커스텀 팩 (CustomPackService.getAll)
///
/// 빈 책장 → SoriEmptyState + "사진 찍기" CTA → /book.
class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({
    super.key,
    this.shareCodeGenerator,
    this.sharedPackRedeemer,
  });

  final SharePackCodeGenerator? shareCodeGenerator;
  final SharedPackRedeemer? sharedPackRedeemer;

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen>
    with ScreenCoachMixin<BookshelfScreen> {
  final _bodyKey = GlobalKey<_BookshelfBodyState>();
  final _createKey = GlobalKey();
  final _searchKey = GlobalKey();
  late bool _empty;

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
    _empty =
        BookshelfService.getAllLocal().isEmpty &&
        CustomPackService.getAll().isEmpty;
    scheduleCoach();
  }

  void _updateEmpty(bool empty) {
    if (!mounted || _empty == empty) {
      return;
    }
    setState(() => _empty = empty);
  }

  Widget _createAction(AppL10n t) => IconButton(
    key: _createKey,
    icon: const Icon(Icons.playlist_add_rounded),
    tooltip: t.createWordbookCta,
    onPressed: () {
      // ignore: discarded_futures
      _bodyKey.currentState?._createWordbook();
    },
  );

  Widget _redeemAction(AppL10n t) => IconButton(
    icon: const Icon(Icons.download_outlined),
    tooltip: t.redeemTooltip,
    onPressed: () {
      // ignore: discarded_futures
      _bodyKey.currentState?._openRedeem();
    },
  );

  Widget _searchAction(AppL10n t) => IconButton(
    key: _searchKey,
    icon: const Icon(Icons.search_rounded),
    tooltip: t.wbSearchTitle,
    onPressed: () => Navigator.of(context).pushNamed('/wordbook/search'),
  );

  Widget _photoAction(AppL10n t) => IconButton(
    icon: const Icon(Icons.add_a_photo_outlined),
    tooltip: t.bookshelfAddPage,
    onPressed: () {
      // ignore: discarded_futures
      _bodyKey.currentState?._addPhoto();
    },
  );

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriStandardFrame(
      appBarTitle: t.bookshelfTitle,
      actions: _empty
          ? [_createAction(t), _redeemAction(t)]
          : [
              _searchAction(t),
              _createAction(t),
              _redeemAction(t),
              _photoAction(t),
            ],
      maxWidth: SoriMaxWidth.hub,
      padding: _empty
          ? const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.md,
              Spacing.lg,
              Spacing.xxxl,
            )
          : const EdgeInsets.fromLTRB(
              Spacing.md,
              Spacing.xs,
              Spacing.md,
              Spacing.xxl,
            ),
      builder: (context, pagePadding) => BookshelfBody(
        key: _bodyKey,
        shareCodeGenerator: widget.shareCodeGenerator,
        sharedPackRedeemer: widget.sharedPackRedeemer,
        padding: pagePadding,
        showEmbeddedActions: false,
        onEmptyChanged: _updateEmpty,
      ),
    );
  }
}

/// Shelf content that can be hosted by a route frame or a tab hub.
class BookshelfBody extends StatefulWidget {
  const BookshelfBody({
    super.key,
    this.shareCodeGenerator,
    this.sharedPackRedeemer,
    this.padding = const EdgeInsets.fromLTRB(
      Spacing.md,
      Spacing.xs,
      Spacing.md,
      Spacing.xxl,
    ),
    this.showEmbeddedActions = true,
    this.showEmbeddedSearchAndPhoto = true,
    this.onEmptyChanged,
  });

  final SharePackCodeGenerator? shareCodeGenerator;
  final SharedPackRedeemer? sharedPackRedeemer;
  final EdgeInsets padding;
  final bool showEmbeddedActions;
  final bool showEmbeddedSearchAndPhoto;
  final ValueChanged<bool>? onEmptyChanged;

  @override
  State<BookshelfBody> createState() => _BookshelfBodyState();
}

class _BookshelfBodyState extends State<BookshelfBody> {
  late List<BookPage> _pages;
  late List<CustomPack> _packs;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _pages = BookshelfService.getAllLocal();
      _packs = CustomPackService.getAll();
    });
    final empty = _pages.isEmpty && _packs.isEmpty;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onEmptyChanged?.call(empty);
      }
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
      builder: (_) =>
          _SharePackSheet(pack: pack, generateCode: widget.shareCodeGenerator),
    );
  }

  /// 코드 입력 다이얼로그 → 성공 시 로컬 import + 새로고침.
  Future<void> _openRedeem() async {
    final imported = await showSoriDialog<CustomPack>(
      context: context,
      builder: (_) => _RedeemDialog(redeem: widget.sharedPackRedeemer),
    );
    if (imported == null || !mounted) return;
    _reload();
    final t = AppL10n.of(context);
    soriNotice(
      context,
      t.redeemSuccess(imported.displayName(), imported.totalWords),
    );
  }

  /// 빈 "나만의 단어장" 생성 → 이름 입력 → 편집 화면으로 이동.
  Future<void> _createWordbook() async {
    final name = await showSoriDialog<String>(
      context: context,
      builder: (_) => const _CreateWordbookDialog(),
    );
    if (name == null || name.isEmpty || !mounted) return;
    final pack = await CustomPackService.createEmpty(name: name);
    if (!mounted) return;
    await Navigator.of(
      context,
    ).pushNamed('/custom_pack/edit', arguments: pack.id);
    _reload();
  }

  Future<void> _addPhoto() async {
    await Navigator.of(context).pushNamed('/book');
    if (mounted) {
      _reload();
    }
  }

  Widget _createAction(AppL10n t) => IconButton(
    icon: const Icon(Icons.playlist_add_rounded),
    tooltip: t.createWordbookCta,
    onPressed: _createWordbook,
  );

  Widget _searchAction(AppL10n t) => IconButton(
    icon: const Icon(Icons.search_rounded),
    tooltip: t.wbSearchTitle,
    onPressed: () => Navigator.of(context).pushNamed('/wordbook/search'),
  );

  Widget _photoAction(AppL10n t) => IconButton(
    icon: const Icon(Icons.add_a_photo_outlined),
    tooltip: t.bookshelfAddPage,
    onPressed: _addPhoto,
  );

  Widget _embeddedActions(AppL10n t) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Wrap(
        spacing: Spacing.xs,
        runSpacing: Spacing.xs,
        children: [
          if (widget.showEmbeddedSearchAndPhoto) _searchAction(t),
          _createAction(t),
          _redeemAction(t),
          if (widget.showEmbeddedSearchAndPhoto) _photoAction(t),
        ],
      ),
    );
  }

  SoriEmptyState _emptyState(AppL10n t) {
    return SoriEmptyState(
      asset: 'assets/illustrations/book/book_empty_shelf.png',
      icon: Icons.menu_book_outlined,
      title: t.bookshelfEmptyTitle,
      body: t.bookshelfEmptyBody,
      ctaLabel: t.bookshelfEmptyCta,
      onCta: () =>
          Navigator.of(context).pushNamed('/book').then((_) => _reload()),
      secondaryLabel: t.createWordbookCta,
      onSecondary: _createWordbook,
    );
  }

  Widget _populatedContent(
    AppL10n t,
    EdgeInsets pagePadding, {
    bool includeEmbeddedActions = false,
  }) {
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      color: SoriColors.primary,
      child: ListView(
        padding: pagePadding,
        children: [
          if (includeEmbeddedActions) ...[
            _embeddedActions(t),
            const SizedBox(height: Spacing.sm),
          ],
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_pages.isEmpty && _packs.isEmpty) {
      return ListView(
        padding: widget.padding,
        children: [
          if (widget.showEmbeddedActions) ...[
            _embeddedActions(t),
            const SizedBox(height: Spacing.sm),
          ],
          SoriPageHeader(title: t.bookshelfTitle),
          const SizedBox(height: Spacing.xl),
          _emptyState(t),
        ],
      );
    }

    return _populatedContent(
      t,
      widget.padding,
      includeEmbeddedActions: widget.showEmbeddedActions,
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
      child: Text(label, style: SoriTextTheme.of(context).label),
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
    final dateLabel = page.capturedAtIso.length >= 10
        ? page.capturedAtIso.substring(0, 10)
        : '';
    final preview = page.extractedText.length > 60
        ? '${page.extractedText.substring(0, 60)}…'
        : page.extractedText;

    final title = preview.isEmpty ? t.bookshelfEmptyPreview : preview;
    final meta = t.bookshelfTileMeta(
      page.words.length,
      page.grammar.length,
      dateLabel,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: SoriCard(
        variant: SoriCardVariant.compact,
        accent: SoriColors.info,
        onTap: onTap,
        semanticLabel: '$title. $meta',
        child: ExcludeSemantics(
          child: Row(
            children: [
              Icon(Icons.article_outlined, size: 22, color: SoriColors.info),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: SoriTextTheme.of(context).cardTitle),
                    const SizedBox(height: 2),
                    Text(meta, style: SoriTextTheme.of(context).cardSubtitle),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: SoriSurfaces.of(context).textDim,
              ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: SoriCard(
        variant: SoriCardVariant.compact,
        accent: SoriColors.primary,
        tinted: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stackActions =
                MediaQuery.textScalerOf(context).scale(1) >= 1.6 ||
                constraints.maxWidth < SoriAdaptiveWidth.labelValueRow;
            final learnedCount = CustomPackService.learnedWordCount(pack);
            final identityLabel =
                '${pack.displayName()}. ${t.bookshelfPackMeta(pack.totalWords)} · '
                '${t.bookshelfPackLearnedMeta(learnedCount, pack.totalWords)}';
            final playLabel = '${t.btnPlay}: ${pack.displayName()}';
            final editLabel = '${t.wbEditTooltip}: ${pack.displayName()}';
            final shareLabel = '${t.shareTooltip}: ${pack.displayName()}';
            final deleteLabel = '${t.btnDelete}: ${pack.displayName()}';
            final identity = Semantics(
              container: true,
              label: identityLabel,
              excludeSemantics: true,
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
                          style: SoriTextTheme.of(context).cardTitle,
                        ),
                        Text(
                          '${t.bookshelfPackMeta(pack.totalWords)} · '
                          '${t.bookshelfPackLearnedMeta(learnedCount, pack.totalWords)}',
                          style: SoriTextTheme.of(context).cardSubtitle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
            final actions = <Widget>[
              Semantics(
                container: true,
                button: true,
                enabled: true,
                label: playLabel,
                onTap: onTap,
                excludeSemantics: true,
                child: SoriButton(
                  label: t.btnPlay,
                  variant: SoriButtonVariant.ghost,
                  size: SoriButtonSize.md,
                  accent: SoriColors.primary,
                  onTap: onTap,
                ),
              ),
              Semantics(
                container: true,
                button: true,
                enabled: true,
                label: editLabel,
                onTap: onEdit,
                excludeSemantics: true,
                child: IconButton(
                  icon: Icon(Icons.edit_outlined, color: SoriColors.primary),
                  tooltip: editLabel,
                  constraints: const BoxConstraints.tightFor(
                    width: 48,
                    height: 48,
                  ),
                  onPressed: onEdit,
                ),
              ),
              Semantics(
                container: true,
                button: true,
                enabled: true,
                label: shareLabel,
                onTap: onShare,
                excludeSemantics: true,
                child: IconButton(
                  icon: Icon(
                    Icons.ios_share_rounded,
                    color: SoriColors.primary,
                  ),
                  tooltip: shareLabel,
                  constraints: const BoxConstraints.tightFor(
                    width: 48,
                    height: 48,
                  ),
                  onPressed: onShare,
                ),
              ),
              Semantics(
                container: true,
                button: true,
                enabled: true,
                label: deleteLabel,
                onTap: () => _confirmDelete(context),
                excludeSemantics: true,
                child: IconButton(
                  icon: Icon(Icons.delete_outline, color: s.textDim),
                  tooltip: deleteLabel,
                  constraints: const BoxConstraints.tightFor(
                    width: 48,
                    height: 48,
                  ),
                  onPressed: () => _confirmDelete(context),
                ),
              ),
            ];
            if (stackActions) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  identity,
                  const SizedBox(height: Spacing.sm),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Wrap(
                      spacing: Spacing.xs,
                      runSpacing: Spacing.xs,
                      alignment: WrapAlignment.end,
                      children: actions,
                    ),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: identity),
                ...actions,
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final t = AppL10n.of(context);
    final ok = await showSoriDialog<bool>(
      context: context,
      builder: (ctx) => SoriDialog(
        title: Text(t.bookshelfDeletePackTitle),
        content: Text(t.bookshelfDeletePackBody(pack.displayName())),
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
    if (ok == true) onDelete();
  }
}

// ════════════════════════════════════════════════════════════════════════
// 공유 시트 — 코드 생성 + 복사 + OS 공유 (Phase 5.2)
// ════════════════════════════════════════════════════════════════════════
class _SharePackSheet extends StatefulWidget {
  final CustomPack pack;
  final SharePackCodeGenerator? generateCode;
  const _SharePackSheet({required this.pack, this.generateCode});

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
    if (!_loading || _error != null) {
      setState(() {
        _code = null;
        _error = null;
        _loading = true;
      });
    }
    try {
      final code =
          await (widget.generateCode?.call(widget.pack) ??
              SharedPackService.sharePack(widget.pack));
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
    final code = _code;

    Widget body;
    if (_loading) {
      body = Semantics(
        liveRegion: true,
        label: t.shareGenerating,
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
          child: AppLoading(message: t.shareGenerating),
        ),
      );
    } else if (code == null) {
      final msg = _error == SharedPackError.empty ? t.shareEmpty : t.shareError;
      body = _error == SharedPackError.empty
          ? Column(
              children: [
                SizedBox(
                  height: 220,
                  child: AppError(
                    message: msg,
                    messageLiveRegion: true,
                    asset: null,
                    icon: Icons.info_outline_rounded,
                  ),
                ),
                SoriButton(
                  label: t.btnClose,
                  variant: SoriButtonVariant.ghost,
                  size: SoriButtonSize.md,
                  fullWidth: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            )
          : SizedBox(
              height: 280,
              child: AppError(
                message: msg,
                messageLiveRegion: true,
                asset: null,
                icon: Icons.cloud_off_outlined,
                onRetry: _generate,
              ),
            );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.shareCodeLabel,
            textAlign: TextAlign.center,
            style: SoriTextTheme.of(context).label,
          ),
          const SizedBox(height: 8),
          Semantics(
            container: true,
            liveRegion: true,
            label: '${t.shareCodeLabel}: $code',
            excludeSemantics: true,
            child: ExcludeSemantics(
              child: SoriCard(
                variant: SoriCardVariant.compact,
                accent: SoriColors.primary,
                tinted: true,
                child: Text(
                  code,
                  textAlign: TextAlign.center,
                  style: SoriTextTheme.of(context).numeral.copyWith(
                    letterSpacing: 8,
                    color: SoriColors.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.shareExpiryNote,
            textAlign: TextAlign.center,
            style: SoriTextTheme.of(context).caption,
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              SoriButton(
                label: t.shareCopyCode,
                icon: Icons.copy_rounded,
                variant: SoriButtonVariant.ghost,
                size: SoriButtonSize.md,
                accent: SoriColors.primary,
                fullWidth: true,
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (context.mounted) {
                    soriNotice(context, t.shareCodeCopied);
                  }
                },
              ),
              const SizedBox(height: Spacing.sm),
              SoriButton(
                label: t.shareViaApp,
                icon: Icons.ios_share_rounded,
                size: SoriButtonSize.md,
                accent: SoriColors.primary,
                fullWidth: true,
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
            ],
          ),
        ],
      );
    }

    // 시트 외형(둥근 상단·handle·키보드 inset·스크롤)은 SoriSheet 담당.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(t.shareTitle, style: SoriTextTheme.of(context).h3),
        const SizedBox(height: 2),
        Text(
          widget.pack.displayName(),
          textAlign: TextAlign.center,
          style: SoriTextTheme.of(context).bodySmall,
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
  const _RedeemDialog({this.redeem});

  final SharedPackRedeemer? redeem;

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
      final pack =
          await (widget.redeem?.call(_controller.text) ??
              SharedPackService.redeem(_controller.text));
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
    return SoriDialog(
      title: Text(t.redeemTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: _errorText != null,
            child: SoriTextField(
              controller: _controller,
              autofocus: true,
              enabled: !_loading,
              labelText: t.redeemHint,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              counterText: '',
              errorText: _errorText,
              style: SoriTextTheme.of(context).h1.copyWith(letterSpacing: 8),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text(t.btnCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: _loading ? null : _submit,
          child: _loading
              ? Semantics(
                  liveRegion: true,
                  label: t.redeemLoading,
                  excludeSemantics: true,
                  child: const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Text(t.redeemAction),
        ),
      ],
    );
  }
}

class _CreateWordbookDialog extends StatefulWidget {
  const _CreateWordbookDialog();

  @override
  State<_CreateWordbookDialog> createState() => _CreateWordbookDialogState();
}

class _CreateWordbookDialogState extends State<_CreateWordbookDialog> {
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
      title: Text(t.createWordbookTitle),
      content: SoriTextField(
        controller: _controller,
        autofocus: true,
        labelText: t.wbRenameLabel,
        hintText: t.createWordbookHint,
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
