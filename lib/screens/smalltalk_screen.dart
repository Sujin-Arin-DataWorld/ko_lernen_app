import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/smalltalk.dart';
import '../services/personalized_lesson_service.dart';
import '../services/smalltalk_loader.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/wordbook_add.dart';

/// **Small Talk (스몰토크)** — Gesprächseinstiege nach Kategorie × Level.
/// Liest `assets/data/smalltalk.json` (via [SmalltalkLoader]). Tippen auf eine
/// Karte spricht den koreanischen Satz (TTS).
class SmalltalkScreen extends StatefulWidget {
  const SmalltalkScreen({super.key});

  @override
  State<SmalltalkScreen> createState() => _SmalltalkScreenState();
}

class _SmalltalkScreenState extends State<SmalltalkScreen>
    with ScreenCoachMixin<SmalltalkScreen> {
  bool _loading = true;
  String _cat = '';
  String? _level; // null = alle Level

  // ── 코치마크 타겟 ──
  final GlobalKey _categoryKey = GlobalKey();
  final GlobalKey _firstCardKey = GlobalKey();

  @override
  String get coachId => 'smalltalk';

  @override
  bool get coachReady => !_loading && SmalltalkLoader.categories.isNotEmpty;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _categoryKey,
        title: t.coachSmalltalkStep1Title,
        body: t.coachSmalltalkStep1Body,
        icon: Icons.category_outlined,
      ),
      SpotlightStep(
        targetKey: _firstCardKey,
        title: t.coachSmalltalkStep2Title,
        body: t.coachSmalltalkStep2Body,
        icon: Icons.volume_up_rounded,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _load();
    scheduleCoach();
  }

  Future<void> _load() async {
    await SmalltalkLoader.load();
    if (!mounted) return;
    final cats = SmalltalkLoader.categories;
    final catIds = cats.map((c) => c.id).toSet();
    // M5: zuerst eine Kategorie passend zu den Interessen öffnen (관심사 우선).
    final preferred = PersonalizedLessonService.smalltalkCategoriesFor(
      Storage.interests,
    ).firstWhere(catIds.contains, orElse: () => '');
    setState(() {
      _cat = preferred.isNotEmpty
          ? preferred
          : (cats.isNotEmpty ? cats.first.id : '');
      _loading = false;
    });
  }

  static Color _levelColor(String lvl) {
    switch (lvl) {
      case 'a1':
        return SoriColors.success;
      case 'a2':
        return SoriColors.primary;
      case 'b1':
        return SoriColors.warning;
      case 'b2':
        return SoriColors.accent;
      default:
        return SoriColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        title: Text(
          t.smalltalkTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const AppLoading()
            : SmalltalkLoader.categories.isEmpty
            ? SoriEmptyState(
                icon: Icons.chat_bubble_outline_rounded,
                title: t.smalltalkTitle,
                body: SmalltalkLoader.lastError ?? '',
              )
            : _buildBody(t, s, lang),
      ),
    );
  }

  Widget _buildBody(AppL10n t, SoriSurfaces s, String lang) {
    final cats = SmalltalkLoader.categories;
    final current = cats.firstWhere(
      (c) => c.id == _cat,
      orElse: () => cats.first,
    );
    final phrases = SmalltalkLoader.filter(category: _cat, level: _level);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 카테고리 18개 — 가로 스크롤 대신 바텀시트로 선택(발견성 개선).
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.lg, 10, Spacing.lg, 6),
          child: Material(
            key: _categoryKey,
            color: s.surface,
            borderRadius: SoriRadius.brMd,
            child: InkWell(
              onTap: () => _showCategorySheet(t, lang),
              borderRadius: SoriRadius.brMd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: SoriRadius.brMd,
                  border: Border.all(color: s.border),
                ),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${current.emoji} ${current.labelFor(lang)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: s.text,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.expand_more_rounded, color: s.textMuted),
                  ],
                ),
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: Row(
            children: [
              _levelChip(t.filterAll, null),
              const SizedBox(width: 6),
              _levelChip('A1', 'a1'),
              const SizedBox(width: 6),
              _levelChip('A2', 'a2'),
              const SizedBox(width: 6),
              _levelChip('B1', 'b1'),
              const SizedBox(width: 6),
              _levelChip('B2', 'b2'),
            ],
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Expanded(
          child: phrases.isEmpty
              ? Center(
                  child: Text(
                    t.smalltalkEmpty,
                    style: TextStyle(color: s.textMuted),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, c) => ListView.builder(
                    padding: soriClampPadding(
                      c.maxWidth,
                      base: const EdgeInsets.fromLTRB(
                        Spacing.lg,
                        0,
                        Spacing.lg,
                        Spacing.xl,
                      ),
                    ),
                    itemCount: phrases.length,
                    itemBuilder: (_, i) {
                      final card = _PhraseCard(
                        p: phrases[i],
                        lang: lang,
                        levelColor: _levelColor(phrases[i].level),
                      );
                      if (i == 0) {
                        return KeyedSubtree(key: _firstCardKey, child: card);
                      }
                      return card;
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _levelChip(String label, String? lvl) => ChoiceChip(
    label: Text(label),
    selected: _level == lvl,
    onSelected: (_) => setState(() => _level = lvl),
  );

  /// 카테고리 18개 선택 바텀시트 — Wrap 그리드로 한눈에(가로 스크롤 제거).
  void _showCategorySheet(AppL10n t, String lang) {
    final s = SoriSurfaces.of(context);
    final cats = SmalltalkLoader.categories;
    showSoriSheet<void>(
      context: context,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md, left: 4),
            child: Text(
              t.smalltalkPickCategory,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: s.text,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in cats)
                ChoiceChip(
                  label: Text('${c.emoji} ${c.labelFor(lang)}'),
                  selected: c.id == _cat,
                  onSelected: (_) {
                    setState(() => _cat = c.id);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhraseCard extends StatefulWidget {
  final SmalltalkPhrase p;
  final String lang;
  final Color levelColor;
  const _PhraseCard({
    required this.p,
    required this.lang,
    required this.levelColor,
  });

  @override
  State<_PhraseCard> createState() => _PhraseCardState();
}

class _PhraseCardState extends State<_PhraseCard> {
  bool _showReply = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final lang = widget.lang;
    final s = SoriSurfaces.of(context);
    final t = AppL10n.of(context);
    final hasReply = p.reply != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: SoriCard(
        variant: SoriCardVariant.base,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Frage/Satz — tippen spricht Koreanisch.
            InkWell(
              onTap: () => TtsService.speak(p.ko),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.ko,
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: s.text,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.translation(lang),
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 13,
                            color: s.textMuted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: widget.levelColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(SoriRadius.pill),
                        ),
                        child: Text(
                          p.level.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: widget.levelColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        Icons.volume_up_rounded,
                        color: SoriColors.primary.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      const SizedBox(height: 10),
                      // Satz ins eigene Wörterbuch (Satz = Karte).
                      GestureDetector(
                        onTap: () => addToWordbook(
                          context,
                          korean: p.ko,
                          translationDe: p.de,
                          translationEn: p.en,
                        ),
                        child: Icon(
                          Icons.bookmark_add_outlined,
                          color: SoriColors.primary.withValues(alpha: 0.7),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Catch-ball: Beispielantwort (nur bei Fragen).
            if (hasReply) ...[
              const SizedBox(height: Spacing.xs),
              if (!_showReply)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showReply = true),
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                    ),
                    label: Text(t.smalltalkReply),
                  ),
                )
              else
                _ReplyView(reply: p.reply!, lang: lang),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReplyView extends StatelessWidget {
  final SmalltalkReply reply;
  final String lang;
  const _ReplyView({required this.reply, required this.lang});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: SoriColors.primary.withValues(alpha: 0.08),
        borderRadius: SoriRadius.brSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💬 ${reply.ko}',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: SoriColors.primaryOnLight,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reply.translation(lang),
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12.5,
                    color: s.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => TtsService.speak(reply.ko),
            child: Icon(
              Icons.volume_up_rounded,
              color: SoriColors.primary.withValues(alpha: 0.7),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
