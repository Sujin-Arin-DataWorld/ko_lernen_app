import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/book_page.dart';
import '../models/custom_pack.dart';
import '../services/bookshelf_service.dart';
import '../services/custom_pack_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/tokens.dart';

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

class _BookshelfScreenState extends State<BookshelfScreen> {
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
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_pages.isEmpty && _packs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(t.bookshelfTitle)),
        body: Center(
          child: SoriEmptyState(
            icon: Icons.menu_book_outlined,
            title: t.bookshelfEmptyTitle,
            body: t.bookshelfEmptyBody,
            ctaLabel: t.bookshelfEmptyCta,
            onCta: () => Navigator.of(context)
                .pushNamed('/book')
                .then((_) => _reload()),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.bookshelfTitle,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined),
            tooltip: t.bookshelfAddPage,
            onPressed: () => Navigator.of(context)
                .pushNamed('/book')
                .then((_) => _reload()),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          color: SoriColors.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
            children: [
              const HanokHeader(
                asset: 'assets/illustrations/hanok/calligraphy.png',
                fallbackIcon: Icons.menu_book_outlined,
              ),
              const SizedBox(height: Spacing.md),
              if (_packs.isNotEmpty) ...[
                _SectionHeader(label: t.bookshelfSectionCustomPacks),
                ..._packs.map((p) => _CustomPackTile(
                      pack: p,
                      onTap: () => Navigator.of(context).pushNamed(
                        '/custom_pack/play',
                        arguments: p.id,
                      ),
                      onDelete: () async {
                        await CustomPackService.delete(p.id);
                        _reload();
                      },
                    )),
                const SizedBox(height: Spacing.lg),
              ],
              if (_pages.isNotEmpty) ...[
                _SectionHeader(label: t.bookshelfSectionPages),
                ..._pages.map((p) => _PageTile(
                      page: p,
                      onTap: () => Navigator.of(context)
                          .pushNamed('/bookshelf/page', arguments: p.id)
                          .then((_) => _reload()),
                    )),
              ],
            ],
          ),
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
            fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.4),
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
            border:
                Border.all(color: SoriColors.info.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(SoriRadius.md),
          ),
          child: Row(
            children: [
              Icon(Icons.article_outlined,
                  size: 22, color: SoriColors.info),
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
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.bookshelfTileMeta(
                          page.words.length, page.grammar.length, dateLabel),
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
  final VoidCallback onDelete;
  const _CustomPackTile({
    required this.pack,
    required this.onTap,
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
            border: Border.all(color: SoriColors.primary.withValues(alpha: 0.35)),
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
                          fontWeight: FontWeight.w800, fontSize: 14),
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
