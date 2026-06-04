import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/vocab.dart';
import '../services/review_deck_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/responsive.dart';
import 'review_session_screen.dart';

/// A2 (암기 엔진) — "어려운 단어" 모음.
///
/// 반복해도 안 외워지는 단어(leech)를 SRS 데이터에서 자동 추출해 모아 보여주고,
/// "집중 복습"으로 그 단어들만 묶어 복습 세션을 돌린다. CSV·나만의 단어장·책 한 컷
/// 단어 모두 대상.
class HardWordsScreen extends StatefulWidget {
  const HardWordsScreen({super.key});

  @override
  State<HardWordsScreen> createState() => _HardWordsScreenState();
}

class _HardWordsScreenState extends State<HardWordsScreen> {
  bool _loading = true;
  List<Vocab> _hard = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<Vocab> hard = const [];
    try {
      final all = await ReviewDeckService.allReviewable();
      final ids = Storage.hardIds(all.map((v) => v.korean)).toSet();
      hard = all.where((v) => ids.contains(v.korean)).toList();
    } catch (_) {/* best-effort → empty */}
    if (!mounted) return;
    setState(() {
      _hard = hard;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.hardWordsTitle,
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: _loading
            ? const AppLoading()
            : _hard.isEmpty
                ? Center(
                    child: SoriEmptyState(
                      icon: Icons.emoji_events_outlined,
                      title: t.hardWordsEmptyTitle,
                      body: t.hardWordsEmptyBody,
                      ctaLabel: t.btnClose,
                      onCta: () => Navigator.of(context).maybePop(),
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            Spacing.lg, Spacing.md, Spacing.lg, Spacing.sm),
                        child: Text(
                          t.hardWordsSubtitle(_hard.length),
                          style: TextStyle(fontSize: 13, color: s.textMuted),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: soriClampPadding(MediaQuery.sizeOf(context).width, base: const EdgeInsets.fromLTRB(12, 0, 12, 96)),
                          itemCount: _hard.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: Spacing.xs),
                          itemBuilder: (_, i) {
                            final v = _hard[i];
                            return Material(
                              color: s.surface,
                              borderRadius:
                                  BorderRadius.circular(SoriRadius.md),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Spacing.md,
                                    vertical: Spacing.sm),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: SoriColors.danger
                                          .withValues(alpha: 0.25)),
                                  borderRadius:
                                      BorderRadius.circular(SoriRadius.md),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(v.korean,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 16)),
                                          if (v.german.isNotEmpty)
                                            Text(v.german,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: s.textMuted)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.volume_up_rounded,
                                          color: SoriColors.primary),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () =>
                                          TtsService.speak(v.korean),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
      bottomNavigationBar: _hard.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: SoriButton(
                  label: t.hardWordsStudyCta,
                  icon: Icons.bolt_rounded,
                  variant: SoriButtonVariant.filled,
                  accent: SoriColors.danger,
                  fullWidth: true,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReviewSessionScreen(
                            deck: _hard, title: t.hardWordsTitle),
                      ),
                    );
                    if (mounted) _load();
                  },
                ),
              ),
            ),
    );
  }
}
