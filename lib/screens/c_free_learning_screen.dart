import 'package:flutter/material.dart';

import '../data/sori_activity_catalog.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/sori_stage_progression.dart';
import '../services/locale_service.dart';
import '../widgets/sori/book_capture_choice.dart';
import '../widgets/sori/c_gallery/c_materials.dart';
import '../widgets/sori/c_gallery/c_objects.dart';
import 'sori_stage/c_stage_chrome.dart';

/// Native Concept-C counterpart of docs/design/c_free_learning_mockup_20261005.
///
/// This screen owns presentation only. Every tile opens the existing production
/// route; the destination remains the owner of progress, SRS, rewards, audio,
/// camera permissions and account writes.
class CFreeLearningScreen extends StatelessWidget {
  const CFreeLearningScreen({super.key, this.onOpenEntry});

  final Future<void> Function(ActivityCatalogEntry entry)? onOpenEntry;

  static const _primaryIds = <String>[
    'vocab_packs',
    'srs',
    'grammar',
    'pronunciation',
    'listening',
    'scenarios',
    'word_web',
  ];

  static const _secondaryIds = <String>[
    'hangul',
    'calligraphy',
    'my_words',
    'book_capture',
    'smalltalk',
  ];

  static const _artById = <String, String>{
    'vocab_packs': 'assets/illustrations/activities/vocab_packs.webp',
    'srs': 'assets/illustrations/activities/srs.webp',
    'grammar': 'assets/illustrations/activities/grammar.webp',
    'pronunciation': 'assets/illustrations/activities/pronunciation.webp',
    'listening': 'assets/illustrations/activities/listening.webp',
    'scenarios': 'assets/illustrations/activities/scenarios.webp',
    'word_web': 'assets/illustrations/activities/word_web.webp',
    'hangul': 'assets/illustrations/activities/hangul.webp',
    'calligraphy': 'assets/illustrations/activities/calligraphy.webp',
    'my_words': 'assets/illustrations/activities/my_words.webp',
    'book_capture': 'assets/illustrations/activities/book_capture.webp',
    'smalltalk': 'assets/illustrations/activities/smalltalk.webp',
  };

  List<ActivityCatalogEntry> _entries(Iterable<String> ids) {
    final wanted = ids.toSet();
    return [
      for (final entry in soriActivityCatalog)
        if (entry.tab == SoriStageTab.learn && wanted.contains(entry.id)) entry,
    ]..sort(
      (a, b) =>
          ids.toList().indexOf(a.id).compareTo(ids.toList().indexOf(b.id)),
    );
  }

  String _copy(BuildContext context, SoriLocalizedCopy copy) =>
      Localizations.localeOf(context).languageCode == 'en' ? copy.en : copy.de;

  Future<void> _open(BuildContext context, ActivityCatalogEntry entry) async {
    final injected = onOpenEntry;
    if (injected != null) {
      await injected(entry);
      return;
    }
    if (entry.id == 'book_capture') {
      await showBookCaptureChoice(context);
      return;
    }
    await Navigator.of(
      context,
    ).pushNamed(entry.route, arguments: entry.arguments);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final primary = _entries(_primaryIds);
    final secondary = _entries(_secondaryIds);
    final compact =
        MediaQuery.sizeOf(context).width < 350 ||
        MediaQuery.textScalerOf(context).scale(16) > 21;

    return Scaffold(
      backgroundColor: CPalette.jade,
      body: CStageBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _TopBar(
                onBack: () => Navigator.of(context).maybePop(),
                onToggleLanguage: () async {
                  final current = Localizations.localeOf(context).languageCode;
                  await setLocale(Locale(current == 'en' ? 'de' : 'en'));
                },
              ),
              Expanded(
                child: ListView(
                  key: const ValueKey('c-free-learning-scroll'),
                  padding: EdgeInsets.fromLTRB(
                    12,
                    0,
                    12,
                    20 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.lernenFree, style: cStageTitle),
                              const SizedBox(height: 6),
                              Text(
                                t.lernenFreeBody,
                                style: cStageBody.copyWith(
                                  color: CPalette.paper.withValues(alpha: .9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!compact) ...[
                          const SizedBox(width: 12),
                          const SizedBox(
                            width: 94,
                            height: 72,
                            child: CObjectArt(CObject.book),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    CPaperPanel(
                      radius: 18,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final oneColumn =
                                  compact || constraints.maxWidth < 300;
                              final width = oneColumn
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - 10) / 2;
                              return Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  for (final entry in primary)
                                    SizedBox(
                                      width: width,
                                      child: _ToolTile(
                                        key: ValueKey(
                                          'c-free-primary-${entry.id}',
                                        ),
                                        entry: entry,
                                        title: _copy(context, entry.title),
                                        description: _copy(
                                          context,
                                          entry.description,
                                        ),
                                        asset: _artById[entry.id],
                                        onTap: () => _open(context, entry),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          Divider(
                            color: CPalette.fineEdge.withValues(alpha: .8),
                          ),
                          const SizedBox(height: 6),
                          Text(t.catalogChoosePractice, style: cStageCardTitle),
                          const SizedBox(height: 6),
                          for (final entry in secondary)
                            _MoreToolRow(
                              key: ValueKey('c-free-secondary-${entry.id}'),
                              title: _copy(context, entry.title),
                              description: _copy(context, entry.description),
                              asset: _artById[entry.id],
                              onTap: () => _open(context, entry),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, required this.onToggleLanguage});

  final VoidCallback onBack;
  final VoidCallback onToggleLanguage;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode.toUpperCase();
    final t = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
      child: Row(
        children: [
          CImageTap(
            label: MaterialLocalizations.of(context).backButtonTooltip,
            onTap: onBack,
            child: const SizedBox.square(
              dimension: 48,
              child: Center(
                child: Icon(Icons.arrow_back_rounded, color: CPalette.paper),
              ),
            ),
          ),
          const SizedBox(width: 4),
          const CObjectArt(CObject.cloud, size: 23),
          const SizedBox(width: 8),
          const Expanded(child: CBrandWordmark()),
          CImageTap(
            label: t.settingsLanguage,
            onTap: onToggleLanguage,
            child: Container(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: CPalette.brass.withValues(alpha: .6)),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                language,
                style: cStageBody.copyWith(
                  color: CPalette.paper,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          CImageTap(
            label: t.settingsTitle,
            onTap: () => Navigator.of(context).pushNamed('/settings'),
            child: const SizedBox.square(
              dimension: 48,
              child: Center(child: CSettingsCog()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    super.key,
    required this.entry,
    required this.title,
    required this.description,
    required this.asset,
    required this.onTap,
  });

  final ActivityCatalogEntry entry;
  final String title;
  final String description;
  final String? asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CImageTap(
    label: title,
    onTap: onTap,
    child: CPaperPanel(
      radius: 10,
      padding: const EdgeInsets.all(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 128),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 76,
              width: double.infinity,
              child: asset == null
                  ? const CObjectArt(CObject.book)
                  : Image.asset(
                      asset!,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                      filterQuality: FilterQuality.high,
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: cStageBody.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MoreToolRow extends StatelessWidget {
  const _MoreToolRow({
    super.key,
    required this.title,
    required this.description,
    required this.asset,
    required this.onTap,
  });

  final String title;
  final String description;
  final String? asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CImageTap(
    label: title,
    onTap: onTap,
    child: Container(
      constraints: const BoxConstraints(minHeight: 68),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CPalette.fineEdge)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 52,
            child: asset == null
                ? const CObjectArt(CObject.book)
                : Image.asset(
                    asset!,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                    filterQuality: FilterQuality.high,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: cStageBody.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: cStageBody.copyWith(
                    fontSize: 13,
                    color: CPalette.mutedInk,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const CArrow(dark: true),
        ],
      ),
    ),
  );
}
