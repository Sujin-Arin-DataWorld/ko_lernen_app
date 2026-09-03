import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/vocab.dart';
import '../motion/transitions.dart';
import '../services/review_deck_service.dart';
import '../services/storage_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';
import 'review_session_screen.dart';

/// `/review/hub` browses the Task 10 ledger without changing the `/review`
/// player route or its existing Today and practice callers.
class ReviewHubScreen extends StatefulWidget {
  const ReviewHubScreen({super.key, this.reviewableLoader});

  /// Test seam for the already-resolved vocabulary catalog. Production callers
  /// leave this null and use [ReviewDeckService.allReviewable].
  final Future<List<Vocab>> Function()? reviewableLoader;

  @override
  State<ReviewHubScreen> createState() => _ReviewHubScreenState();
}

class _ReviewHubScreenState extends State<ReviewHubScreen> {
  bool _loading = true;
  List<Vocab> _allReviewable = const [];
  List<String> _todayIds = const [];
  final Set<String> _selected = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Retention must never prevent the ledger browser from opening.
      await Storage.pruneStudyLog();
    } on Object catch (error) {
      // Fail soft: a read-only or malformed preference store remains browseable.
      debugPrint('ReviewHub: study-log pruning failed: $error');
    }

    try {
      final all =
          await (widget.reviewableLoader?.call() ??
              ReviewDeckService.allReviewable());
      if (!mounted) {
        return;
      }
      final todayIds = Storage.studyLogIdsFor(Storage.todayIso());
      final visibleIds = ReviewDeckService.deckForIds(
        all,
        todayIds,
      ).map((word) => word.korean).toSet();
      setState(() {
        _allReviewable = all;
        _todayIds = todayIds;
        _selected.removeWhere((id) => !visibleIds.contains(id));
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      debugPrint('ReviewHub: reviewable deck load failed: $error');
      setState(() {
        _allReviewable = const [];
        _todayIds = const [];
        _selected.clear();
        _loading = false;
      });
    }
  }

  List<Vocab> get _todayDeck =>
      ReviewDeckService.deckForIds(_allReviewable, _todayIds);

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) {
        _selected.add(id);
      }
    });
  }

  Future<void> _openDeck(List<Vocab> deck, String title) async {
    await Navigator.of(context).push(
      SoriTransitions.page(
        (_) => ReviewSessionScreen(
          deck: deck,
          title: title,
          feedbackContentId: 'review_hub_session',
        ),
      ),
    );
    if (mounted) {
      await _load();
    }
  }

  Future<void> _openCalendar() async {
    final dates = _calendarDates;
    if (dates.isEmpty) {
      return;
    }
    final dateSet = dates.toSet();
    final initialDate = DateTime.tryParse(dates.last) ?? DateTime.now();
    final firstDate = DateTime.tryParse(dates.first) ?? initialDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now(),
      selectableDayPredicate: (day) =>
          dateSet.contains(Storage.todayIsoFor(day)),
    );
    if (picked == null || !mounted) {
      return;
    }
    final deck = ReviewDeckService.deckForIds(
      _allReviewable,
      Storage.studyLogIdsFor(Storage.todayIsoFor(picked)),
    );
    if (deck.isEmpty) {
      return;
    }
    final t = AppL10n.of(context);
    await _openDeck(deck, t.reviewHubDeckLabel(deck.length));
  }

  /// Calendar browsing is limited to ledger dates that can be selected on the
  /// device today. Future canonical keys can exist after a clock rollback or
  /// restore, but must neither open nor become selectable in this picker.
  List<String> get _calendarDates {
    final today = Storage.todayIso();
    return Storage.studyLogDates()
        .where((dateIso) => dateIso.compareTo(today) <= 0)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final deck = _todayDeck;
    final selectedCount = _selected.isEmpty ? deck.length : _selected.length;
    final canOpenCalendar = !_loading && _calendarDates.isNotEmpty;
    return SoriStandardPage(
      appBarTitle: t.reviewHubTitle,
      headline: t.reviewHubTitle,
      actions: [
        IconButton(
          key: const Key('review-hub-calendar'),
          icon: const Icon(Icons.calendar_month_rounded),
          tooltip: t.reviewHubCalendarTooltip,
          onPressed: canOpenCalendar ? _openCalendar : null,
        ),
      ],
      children: [
        Text(t.reviewHubTodayHeadline, style: SoriTextTheme.of(context).h3),
        const SizedBox(height: Spacing.md),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (deck.isEmpty)
          SoriEmptyState(
            // §E5: ASSET_GAP §3-2 "복습 완료" 배선 — 기존 마스코트 재사용.
            asset: 'assets/illustrations/mascot/magpie_celebrate.png',
            icon: Icons.today_outlined,
            title: t.reviewHubEmptyToday,
          )
        else ...[
          for (final word in deck)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: SoriCard(
                padding: EdgeInsets.zero,
                child: Material(
                  color: Colors.transparent,
                  child: CheckboxListTile(
                    key: Key('review-hub-select-${word.korean}'),
                    value: _selected.contains(word.korean),
                    onChanged: (_) => _toggle(word.korean),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(word.korean),
                    subtitle: Text(word.german),
                  ),
                ),
              ),
            ),
          const SizedBox(height: Spacing.md),
          SoriButton.filled(
            key: const Key('review-hub-start-selected'),
            label: t.reviewHubStartSelected(selectedCount),
            semanticLabel: t.reviewHubStartSelected(selectedCount),
            fullWidth: true,
            onTap: () => _openDeck(
              _selected.isEmpty
                  ? deck
                  : deck
                        .where((word) => _selected.contains(word.korean))
                        .toList(growable: false),
              t.reviewHubTodayHeadline,
            ),
          ),
        ],
      ],
    );
  }
}
