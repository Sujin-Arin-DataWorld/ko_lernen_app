import 'package:flutter/material.dart';

import '../../data/sori_activity_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/sori_stage_progression.dart';
import '../../services/account/cloud_write_session.dart';
import '../../services/local_data_lifetime.dart';
import '../../services/storage_service.dart';
import '../../services/vocab_pack_service.dart';
import '../../widgets/sori/activity_illustration.dart';
import '../../widgets/sori/activity_sheet.dart';
import '../../widgets/sori/adaptive_navigation.dart';
import '../../widgets/sori/c_gallery/c_free_learning_art.dart';
import '../../widgets/sori/c_gallery/c_materials.dart';
import '../../widgets/sori/learning_stage_navigation.dart';
import '../../widgets/sori/level_filter_bar.dart';
import '../../widgets/sori/localized_copy.dart';
import '../../widgets/sori/media_phrase_link.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/sheet.dart';
import '../../widgets/sori/study_library_button.dart';
import '../../widgets/sori/toast.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/window_class.dart';
import 'c_stage_chrome.dart' show CStageBackground, CStageHeader;

class SoriFreeLearningScreen extends StatefulWidget {
  const SoriFreeLearningScreen({
    super.key,
    required this.loadSnapshot,
    required this.onOpen,
  });

  final Future<SoriStageProgressionSnapshot> Function() loadSnapshot;
  final Future<void> Function(BuildContext, ActivityCatalogEntry) onOpen;

  @override
  State<SoriFreeLearningScreen> createState() => _SoriFreeLearningScreenState();
}

class _SoriFreeLearningScreenState extends State<SoriFreeLearningScreen> {
  static const _toolIds = [
    'vocab_packs',
    'grammar',
    'book_capture',
    'word_web',
    'pronunciation',
    'listening',
    'scenarios',
    'smalltalk',
    'hangul',
    'calligraphy',
    'srs',
    'my_words',
  ];
  final _entries = [
    for (final id in _toolIds)
      soriActivityCatalog.firstWhere((entry) => entry.id == id),
  ];
  late var _progress = widget.loadSnapshot();
  late final _packs = VocabPackService.loadForDisplay();
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    cloudWriteSessionController.changes.addListener(_reload);
  }

  @override
  void dispose() {
    cloudWriteSessionController.changes.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    final progress = widget.loadSnapshot();
    setState(() {
      _progress = progress;
    });
  }

  Future<void> _open(ActivityCatalogEntry entry) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await widget.onOpen(context, entry);
    } finally {
      if (mounted) {
        _opening = false;
        _reload();
      }
    }
  }

  Future<void> _chooseLevel() async {
    final lifetime = LocalDataLifetime.capture();
    final picked = await showSoriSheet<String>(
      context: context,
      maxTextScaleFactor: double.infinity,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppL10n.of(sheetContext).settingsBrowseLevelTitle,
            style: SoriTextTheme.of(sheetContext).h2,
          ),
          const SizedBox(height: Spacing.sm),
          Text(AppL10n.of(sheetContext).settingsBrowseLevelDescription),
          const SizedBox(height: Spacing.md),
          SoriLevelFilterBar(
            selected: SoriLevelFilterBar.resolveStartLevel(),
            onChanged: (value) => Navigator.of(sheetContext).pop(value),
          ),
        ],
      ),
    );
    if (!mounted || picked == null || !lifetime.isCurrent) return;
    try {
      await Storage.setBrowseLevelCodeStrict(picked);
      if (mounted && lifetime.isCurrent) setState(() {});
    } catch (_) {
      if (mounted && lifetime.isCurrent) {
        soriToast(context, AppL10n.of(context).loadErrorTryAgain);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final level = SoriLevelFilterBar.resolveStartLevel();
    final usesRail = SoriAdaptiveNavigation.usesRailForWidth(
      MediaQuery.sizeOf(context).width,
    );
    final content = SoriContentClamp(
      maxWidth: 600,
      base: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      builder: (context, padding) => FutureBuilder<SoriStageProgressionSnapshot>(
        future: _progress,
        builder: (context, snapshot) {
          final progress = snapshot.data?.activityProgress;
          void details(ActivityCatalogEntry entry) => showSoriActivitySheet(
            context,
            entry: entry,
            progress: progress?[entry.id],
            onStart: () => _open(entry),
          );

          return SingleChildScrollView(
            key: const ValueKey('c-free-learning-scroll'),
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CStageHeader(
                  title: t.c5AllLearningActivities,
                  shelf: true,
                  leading: BackButton(
                    color: CPalette.paper,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  extraAction: const IconTheme(
                    data: IconThemeData(color: CPalette.paper),
                    child: SoriStudyLibraryButton(),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: CMaterialAction(
                    key: const ValueKey('c-learn-level-filter'),
                    gold: false,
                    compact: true,
                    label:
                        '${t.settingsBrowseLevelTitle} · ${level.toUpperCase()}',
                    onTap: _opening ? null : _chooseLevel,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                _featured(context, level),
                const SizedBox(height: Spacing.md),
                LayoutBuilder(
                  builder: (context, bounds) {
                    final scale = MediaQuery.textScalerOf(context).scale(16);
                    final narrow =
                        bounds.maxWidth <
                        SoriAdaptiveWidth.freeLearningShelfThreeColumns;
                    final columns = scale >= 26
                        ? 1
                        : narrow || scale >= 21
                        ? 2
                        : 3;
                    final width =
                        (bounds.maxWidth - (columns - 1) * Spacing.sm) /
                        columns;
                    return Wrap(
                      spacing: Spacing.sm,
                      runSpacing: Spacing.sm,
                      children: [
                        for (final entry in _entries)
                          SizedBox(
                            width: width,
                            child: CImageTap(
                              key: ValueKey('free-learning-tile-${entry.id}'),
                              label: localCopy(context, entry.title),
                              onTap: _opening
                                  ? null
                                  : () {
                                      if (isActivityLocked(
                                        entry,
                                        progress?[entry.id],
                                      )) {
                                        details(entry);
                                      } else {
                                        _open(entry);
                                      }
                                    },
                              onLongPress: _opening
                                  ? null
                                  : () => details(entry),
                              child: CFreeLearningArt(
                                entry.id,
                                label: localCopy(context, entry.title),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: Spacing.md),
                const SoriMediaPhraseLink(),
                if (snapshot.hasError) ...[
                  const SizedBox(height: Spacing.md),
                  CPaperPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(t.catalogProgressUnavailable),
                        TextButton(onPressed: _reload, child: Text(t.btnRetry)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
    return Scaffold(
      key: const ValueKey('c-free-learning-screen'),
      bottomNavigationBar: usesRail
          ? null
          : const SoriLearningStageNavigation(),
      body: CStageBackground(
        shelf: true,
        child: SafeArea(
          child: usesRail
              ? Row(
                  children: [
                    const SoriLearningStageNavigation(rail: true),
                    Expanded(child: content),
                  ],
                )
              : content,
        ),
      ),
    );
  }

  Widget _featured(BuildContext context, String level) =>
      FutureBuilder<VocabPackLoadResult>(
        future: _packs,
        builder: (context, snapshot) {
          final pack = snapshot.data?.packs
              .where((pack) => pack.level.toLowerCase() == level)
              .firstOrNull;
          final entry = _entries.first;
          final label = pack == null
              ? localCopy(context, entry.title)
              : VocabPackService.packDisplayMap.containsKey(pack.baseId)
              ? VocabPackService.displayLabel(
                  pack.baseId,
                  lang: Localizations.localeOf(context).languageCode,
                )
              : pack.fallbackLabel;
          return CPaperPanel(
            padding: const EdgeInsets.all(Spacing.sm),
            child: Row(
              children: [
                const SizedBox(
                  width: 68,
                  height: 60,
                  child: CFreeLearningArt('grammar'),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: CMaterialAction(
                    key: const ValueKey('free-learning-featured-open'),
                    label: label,
                    compact: true,
                    onTap: _opening
                        ? null
                        : () => _open(
                            pack == null
                                ? entry
                                : ActivityCatalogEntry(
                                    id: entry.id,
                                    tab: entry.tab,
                                    title: entry.title,
                                    description: entry.description,
                                    route: '/vocab/pack',
                                    arguments: pack.id,
                                    minutes: entry.minutes,
                                    colorRole: entry.colorRole,
                                    iconName: entry.iconName,
                                    reward: entry.reward,
                                    unlock: entry.unlock,
                                    ownsRoute: false,
                                    learnSection: entry.learnSection,
                                  ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}
