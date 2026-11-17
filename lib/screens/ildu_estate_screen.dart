import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/ildu_r16_art.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/app_bar.dart';
import '../widgets/sori/dialog.dart';
import '../widgets/sori/cultural_help.dart';
import '../widgets/sori/ildu_r16_estate_artwork.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/tokens.dart';

/// Read-only architecture reference, as in the existing Gye completion example.
/// It neither consumes a wallet nor writes learning, group or ownership state.
class IlDuEstateScreen extends StatefulWidget {
  const IlDuEstateScreen({super.key, this.loader});
  final Future<IlDuR16ArtCatalog> Function()? loader;

  @override
  State<IlDuEstateScreen> createState() => _IlDuEstateScreenState();
}

class _IlDuEstateScreenState extends State<IlDuEstateScreen> {
  late Future<IlDuR16ArtCatalog> _catalog;
  String _selected = 'sarangchae';
  int _imageGeneration = 0;

  @override
  void initState() {
    super.initState();
    _catalog = _load();
  }

  Future<IlDuR16ArtCatalog> _load() =>
      (widget.loader ?? IlDuR16ArtCatalog.load)();

  String _name(AppL10n t, String id) => switch (id) {
    'sarangchae' => t.ilduR16Sarangchae,
    'changgo' => t.ilduR16Changgo,
    'jungmunganchae' => t.ilduR16Jungmunganchae,
    'araechae' => t.ilduR16Araechae,
    'toilet-south' => t.ilduR16SouthToilet,
    'anchae' => t.ilduR16Anchae,
    'anchae-store' => t.ilduR16AnchaeStore,
    'toilet-north' => t.ilduR16NorthToilet,
    'gokgan' => t.ilduR16Gokgan,
    'ansarang' => t.ilduR16Ansarang,
    'sadang' => t.ilduR16Sadang,
    _ => t.ilduR16Title,
  };

  String get _cultureTerm => switch (_selected) {
    'sarangchae' => 'sarangchae',
    'anchae' || 'anchae-store' => 'anchae',
    'sadang' => 'sadang',
    _ => 'hanok',
  };

  Future<void> _chooseBuilding(IlDuR16ArtCatalog catalog) async {
    final selected = await showSoriSheet<String>(
      context: context,
      maxTextScaleFactor: MediaQuery.textScalerOf(context).scale(1),
      builder: (context) => Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final building in catalog.buildings)
              ListTile(
                key: ValueKey('r16-building-${building.id}'),
                selected: building.id == _selected,
                title: Text(_name(AppL10n.of(context), building.id)),
                onTap: () => Navigator.of(context).pop(building.id),
              ),
          ],
        ),
      ),
    );
    if (mounted && selected != null) {
      setState(() => _selected = selected);
    }
  }

  Future<void> _enlarge() => showSoriDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      child: Scaffold(
        appBar: SoriAppBar(
          leading: const CloseButton(),
          title: AppL10n.of(context).ilduR16Title,
          textScale: MediaQuery.textScalerOf(context).scale(1),
          viewportWidth: MediaQuery.sizeOf(context).width,
        ),
        body: SafeArea(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: const Center(child: IlDuR16EstateArtwork()),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final type = SoriTextTheme.of(context);
    return SoriStandardFrame(
      appBarTitle: t.ilduR16Title,
      padding: const EdgeInsets.all(Spacing.lg),
      builder: (context, padding) => FutureBuilder<IlDuR16ArtCatalog>(
        future: _catalog,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AppError(
              message: t.loadErrorTryAgain,
              onRetry: () => setState(() {
                _catalog = _load();
              }),
            );
          }
          if (!snapshot.hasData) {
            return const AppLoading();
          }
          final catalog = snapshot.requireData;
          final selected = catalog.buildings.firstWhere(
            (b) => b.id == _selected,
          );
          return ListView(
            key: const PageStorageKey('ildu-r16-estate-reference'),
            padding: padding,
            children: [
              Text(t.ilduR16Reference, style: type.cardTitle),
              const SizedBox(height: Spacing.sm),
              Text(t.ilduR16ReferenceBody, style: type.body),
              const SizedBox(height: Spacing.md),
              const AspectRatio(
                aspectRatio: 1600 / 1700,
                child: IlDuR16EstateArtwork(),
              ),
              SoriButton.outlined(
                key: const ValueKey('ildu-r16-estate-enlarge'),
                label: t.ilduR16Enlarge,
                fullWidth: true,
                onTap: _enlarge,
              ),
              const SizedBox(height: Spacing.lg),
              SoriButton.outlined(
                key: const ValueKey('ildu-r16-building-picker'),
                label: '${t.ilduR16Building}: ${_name(t, _selected)}',
                fullWidth: true,
                maxLines: null,
                onTap: () => _chooseBuilding(catalog),
              ),
              const SizedBox(height: Spacing.md),
              Text(selected.nameKo, style: type.h2),
              const SizedBox(height: Spacing.sm),
              AspectRatio(
                aspectRatio: selected.full.width / selected.full.height,
                child: Image.asset(
                  selected.full.asset,
                  key: ValueKey('r16-reference-$_selected-$_imageGeneration'),
                  fit: BoxFit.contain,
                  cacheWidth: 960,
                  semanticLabel: _name(t, _selected),
                  errorBuilder: (_, _, _) => Center(
                    child: SoriButton.ghost(
                      onTap: () async {
                        await AssetImage(selected.full.asset).evict();
                        if (mounted) {
                          setState(() => _imageGeneration++);
                        }
                      },
                      label: t.btnRetry,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),
              ExpansionTile(
                key: PageStorageKey('r16-culture-$_cultureTerm'),
                tilePadding: EdgeInsets.zero,
                title: Text(t.ilduR16AboutSpace),
                children: [CulturalTermContent(termId: _cultureTerm)],
              ),
              const SizedBox(height: Spacing.md),
              SoriButton.filled(
                label: t.ilduConstructionTitle,
                fullWidth: true,
                onTap: () =>
                    Navigator.of(context).pushNamed('/hanok/construction'),
              ),
              const SizedBox(height: Spacing.sm),
              SoriButton.outlined(
                label: t.ilduR16Practice,
                fullWidth: true,
                onTap: () => Navigator.of(context).pushNamed('/hanok/practice'),
              ),
              const SizedBox(height: Spacing.xl),
            ],
          );
        },
      ),
    );
  }
}
