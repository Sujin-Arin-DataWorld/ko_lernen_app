import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/ildu_construction_art.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/hanok_asset_image.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';

/// Browsing and practice only. This screen never writes construction progress.
class IlDuConstructionScreen extends StatefulWidget {
  const IlDuConstructionScreen({super.key, this.loader});

  final Future<IlDuConstructionArtCatalog> Function()? loader;

  @override
  State<IlDuConstructionScreen> createState() => _IlDuConstructionScreenState();
}

class _IlDuConstructionScreenState extends State<IlDuConstructionScreen> {
  late Future<IlDuConstructionArtCatalog> _catalog;
  final ScrollController _scroll = ScrollController();
  int _building = 0;
  int _step = -1;
  String? _answer;
  String? _languageOverride;

  Future<IlDuConstructionArtCatalog> _load() =>
      (widget.loader ?? IlDuConstructionArtCatalog.load)();

  @override
  void initState() {
    super.initState();
    _catalog = _load();
  }

  void _selectStep(int step) {
    setState(() {
      _step = step;
      _answer = null;
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriStandardFrame(
      appBarTitle: t.ilduConstructionTitle,
      maxWidth: SoriMaxWidth.prose,
      padding: const EdgeInsets.all(Spacing.lg),
      builder: (context, padding) => FutureBuilder<IlDuConstructionArtCatalog>(
        future: _catalog,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AppError(
              message: t.loadErrorTryAgain,
              onRetry: () => setState(() {
                _building = 0;
                _step = -1;
                _answer = null;
                _catalog = _load();
              }),
            );
          }
          if (!snapshot.hasData) {
            return const AppLoading();
          }
          return _content(context, snapshot.data!, padding);
        },
      ),
    );
  }

  Widget _content(
    BuildContext context,
    IlDuConstructionArtCatalog catalog,
    EdgeInsets padding,
  ) {
    final t = AppL10n.of(context);
    final type = SoriTextTheme.of(context);
    final language =
        _languageOverride ?? Localizations.localeOf(context).languageCode;
    final series = catalog.series[_building];
    final stage = _step < 0 ? null : series.stages[_step];
    final observe = stage == null ? null : ilduArtText(stage.observe, language);
    final task = stage == null ? null : ilduArtText(stage.task, language);
    return ListView(
      controller: _scroll,
      key: const ValueKey('ildu-construction-content'),
      padding: padding,
      children: [
        Text(t.ilduConstructionIntro, style: type.body),
        const SizedBox(height: Spacing.md),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: DropdownButtonFormField<String>(
              key: const ValueKey('ildu-construction-language'),
              initialValue: language,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: t.sarangchaeLessonLanguage,
              ),
              items: [
                DropdownMenuItem(
                  value: 'ko',
                  child: Text(t.sarangchaeLanguageKorean),
                ),
                DropdownMenuItem(
                  value: 'de',
                  child: Text(t.sarangchaeLanguageGerman),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(t.sarangchaeLanguageEnglish),
                ),
              ],
              onChanged: (value) => setState(() => _languageOverride = value),
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: [
            for (var i = 0; i < catalog.series.length; i++)
              SoriCard(
                key: ValueKey('ildu-construction-${catalog.series[i].id}'),
                selectable: true,
                selected: _building == i,
                onTap: () {
                  setState(() {
                    _building = i;
                    _step = -1;
                    _answer = null;
                  });
                  _scroll.jumpTo(0);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(catalog.series[i].name['ko']!, style: type.body),
                    if (language != 'ko')
                      Text(
                        ilduArtText(catalog.series[i].name, language),
                        style: type.bodySmall,
                      ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        if (stage == null) ...[
          Text(
            t.ilduConstructionStep(0, series.stages.length),
            style: type.bodySmall,
          ),
          const SizedBox(height: Spacing.md),
          SoriCard(
            key: const ValueKey('ildu-construction-empty'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  const Icon(Icons.landscape_outlined, size: 64),
                  const SizedBox(height: Spacing.md),
                  Text(t.ilduConstructionEmptyTitle, style: type.h2),
                  const SizedBox(height: Spacing.md),
                  Text(t.ilduConstructionEmptyBody, style: type.body),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          SoriButton.filled(
            key: const ValueKey('ildu-construction-start'),
            label: t.ilduConstructionStart,
            onTap: () => _selectStep(0),
          ),
        ] else ...[
          Text(
            t.ilduConstructionStep(stage.sequence, series.stages.length),
            key: const ValueKey('ildu-construction-step'),
            style: type.bodySmall,
          ),
          const SizedBox(height: Spacing.sm),
          Text(stage.title['ko']!, style: type.h2),
          if (language != 'ko')
            Text(ilduArtText(stage.title, language), style: type.body),
          const SizedBox(height: Spacing.md),
          _ConstructionImage(
            key: ValueKey(stage.id),
            stage: stage,
            language: language,
          ),
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.md,
            runSpacing: Spacing.sm,
            children: [
              SoriButton.outlined(
                key: const ValueKey('ildu-construction-previous'),
                label: t.ilduConstructionPrevious,
                onTap: () => _selectStep(_step - 1),
              ),
              SoriButton.filled(
                key: const ValueKey('ildu-construction-next'),
                label: t.ilduConstructionNext,
                onTap: _step == series.stages.length - 1
                    ? null
                    : () => _selectStep(_step + 1),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Text(observe!, style: type.body),
          const SizedBox(height: Spacing.lg),
          SoriCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stage.lessonIllustration case final lesson?) ...[
                  Image.asset(
                    lesson.asset,
                    height: 160,
                    fit: BoxFit.contain,
                    cacheWidth: 480,
                    semanticLabel: ilduArtText(lesson.alt, language),
                    errorBuilder: (context, error, stackTrace) => Text(
                      ilduArtText(lesson.alt, language),
                      style: type.body,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    ilduArtText(lesson.caption, language),
                    style: type.bodySmall,
                  ),
                  const SizedBox(height: Spacing.md),
                ],
                Text(stage.line['ko']!, style: type.h2),
                if (language != 'ko') ...[
                  const SizedBox(height: Spacing.sm),
                  Text(ilduArtText(stage.line, language), style: type.body),
                ],
                if (task != observe) ...[
                  const SizedBox(height: Spacing.md),
                  Text(task!, style: type.body),
                ],
                if (stage.options.isNotEmpty)
                  const SizedBox(height: Spacing.md),
                for (final option in stage.options.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: SoriCard(
                      key: ValueKey('ildu-construction-option-${option.key}'),
                      selectable: true,
                      selected: _answer == option.key,
                      onTap: () => setState(() => _answer = option.key),
                      child: Text(
                        ilduArtText(option.value, language),
                        style: type.body,
                      ),
                    ),
                  ),
                if (_answer != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _answer == stage.correctOptionId
                          ? t.ilduConstructionCorrect
                          : t.ilduConstructionTryAgain,
                      key: const ValueKey('ildu-construction-feedback'),
                      style: type.body,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),
          ExpansionTile(
            title: Text(t.ilduConstructionScene, style: type.body),
            children: [
              Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Text(
                  ilduArtText(stage.scene, language),
                  style: type.body,
                ),
              ),
            ],
          ),
          if (stage.glossary.isNotEmpty)
            ExpansionTile(
              title: Text(t.ilduConstructionTerms, style: type.body),
              children: [
                for (final term in stage.glossary)
                  ListTile(
                    title: Text(ilduArtText(term.label, language)),
                    subtitle: Text(ilduArtText(term.explanation, language)),
                  ),
              ],
            ),
          ExpansionTile(
            title: Text(t.ilduConstructionCulture, style: type.body),
            children: [
              Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Text(
                  ilduArtText(series.culture, language),
                  style: type.body,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ConstructionImage extends StatefulWidget {
  const _ConstructionImage({
    super.key,
    required this.stage,
    required this.language,
  });

  final IlDuConstructionArtStage stage;
  final String language;

  @override
  State<_ConstructionImage> createState() => _ConstructionImageState();
}

class _ConstructionImageState extends State<_ConstructionImage> {
  int _retry = 0;

  @override
  Widget build(BuildContext context) {
    final stage = widget.stage;
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = (constraints.maxWidth * stage.height / stage.width)
            .clamp(200.0, 440.0);
        final width = constraints.maxWidth;
        final decodeWidth = (width * MediaQuery.devicePixelRatioOf(context))
            .ceil()
            .clamp(1, stage.width);
        return SizedBox(
          height: height,
          child: HanokAssetImage(
            stage.asset,
            key: ValueKey('${stage.id}-asset-$_retry'),
            cacheWidth: decodeWidth,
            fit: BoxFit.contain,
            semanticLabel: ilduArtText(stage.observe, widget.language),
            prefetchPack: true,
            errorBuilder: (context, error, stackTrace) => AppError(
              message: AppL10n.of(context).loadErrorTryAgain,
              asset: null,
              onRetry: () async {
                await ResizeImage.resizeIfNeeded(
                  decodeWidth,
                  null,
                  AssetImage(stage.asset),
                ).evict();
                if (mounted) {
                  setState(() => _retry++);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
