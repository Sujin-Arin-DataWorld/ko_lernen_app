import 'dart:async';
import 'package:flutter/material.dart';

import '../models/learner_level.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/vocab.dart';
import '../motion/transitions.dart';
import '../services/review_deck_service.dart';
import '../services/storage_service.dart';
import '../services/vocab_pack_service.dart';
import '../services/word_relation_service.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/viewport_pages.dart';
import '../widgets/sori/app_bar.dart';
import '../widgets/sori/approved_chrome_assets.dart';
import '../widgets/sori/c_learning_surface.dart';
import '../widgets/sori/learning_stage_navigation.dart';
import '../widgets/sori/lernen_generated_art.dart';
import '../widgets/sori/speakable.dart';
import '../widgets/sori/button.dart';
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
  bool _failed = false;
  bool _archive = false;
  bool _ownWords = false;
  LearnerLevel _level = LearnerLevel.a1;
  String _query = '';
  final Set<String> _expandedTopics = <String>{};
  List<Vocab> _allReviewable = const [];
  List<String> _todayIds = const [];
  final Set<String> _selected = <String>{};
  final ContentSpeechController _speech = ContentSpeechController();
  bool _speechSubscribed = false;

  void _playWord(String word) {
    final route = ModalRoute.of(context);
    if (!_speechSubscribed && route != null) {
      _speech.subscribe(route);
      _speechSubscribed = true;
    }
    unawaited(SoriSpeech.speak(word));
  }

  @override
  void deactivate() {
    if (_speechSubscribed) {
      _speech.deactivate();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _speech.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
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
              ReviewDeckService.allReviewable(strict: true));
      if (!mounted) {
        return;
      }
      final todayIds = Storage.studyLogIdsFor(Storage.todayIso());
      final visibleIds = _learnedIds;
      setState(() {
        _allReviewable = all;
        _todayIds = todayIds;
        _selected.removeWhere((id) => !visibleIds.contains(id));
        _loading = false;
        _failed = false;
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
        _failed = true;
      });
    }
  }

  List<Vocab> get _todayDeck =>
      ReviewDeckService.deckForIds(_allReviewable, _todayIds);

  Set<String> get _learnedIds => {
    ...WordRelationService.learnedKorean(),
    ...Storage.studyLogDates().expand(Storage.studyLogIdsFor),
  };

  List<Vocab> get _learnedDeck {
    final ids = _learnedIds;
    return _allReviewable.where((word) => ids.contains(word.korean)).toList();
  }

  String _topicFor(Vocab word, String language, AppL10n t) {
    final packId = word.packId.trim();
    if (packId.isNotEmpty &&
        VocabPackService.packDisplayMap.containsKey(
          VocabPackService.topicId(packId),
        )) {
      return VocabPackService.topicLabel(packId, lang: language);
    }
    return word.topic.trim().isEmpty ? t.reviewNoTopic : word.topic;
  }

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
    final learned = _learnedDeck;
    final selectedCount = deck
        .where((word) => _selected.contains(word.korean))
        .length;
    final canOpenCalendar = !_loading && _calendarDates.isNotEmpty;
    final language = Localizations.localeOf(context).languageCode;
    final filtered = learned.where((word) {
      final own = word.level == ReviewDeckService.customLevelTag;
      if (_ownWords
          ? !own
          : own || LearnerLevel.fromCode(word.level) != _level) {
        return false;
      }
      final q = _query.trim().toLowerCase();
      return q.isEmpty ||
          word.korean.toLowerCase().contains(q) ||
          word.translationFor(language).toLowerCase().contains(q) ||
          word.topic.toLowerCase().contains(q) ||
          _topicFor(word, language, t).toLowerCase().contains(q);
    }).toList();
    final topics = <String, List<Vocab>>{};
    for (final word in filtered) {
      final topic = _topicFor(word, language, t);
      topics.putIfAbsent(topic, () => []).add(word);
    }
    final actionDeck = _archive
        ? filtered
              .where(
                (word) =>
                    _expandedTopics.contains(_topicFor(word, language, t)),
              )
              .toList()
        : deck;
    final selectedTopics = {
      for (final word in actionDeck)
        if (_selected.contains(word.korean)) _topicFor(word, language, t),
    };
    final selectionNote =
        !_archive && !_compactArtwork && selectedTopics.length == 1
        ? t.reviewSelectedTopic(selectedTopics.single)
        : null;
    return SoriStudyFrame(
      title: t.reviewHubTitle,
      padding: EdgeInsets.zero,
      homeContent: const SizedBox(
        width: 48,
        child: Center(
          child: ApprovedChromeImage(
            asset: 'design_assets/hoeren/home-c-v1.png',
            size: 42,
          ),
        ),
      ),
      headerBuilder: (context, leading, actions) => SoriAppBar(
        title: t.reviewHubTitle,
        textScale: MediaQuery.textScalerOf(context).scale(1),
        viewportWidth: MediaQuery.sizeOf(context).width,
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
        actions: actions,
        appearance: SoriAppBarAppearance(
          toolbarHeight: MediaQuery.textScalerOf(context).scale(23) <= 32
              ? 55
              : 78,
          foregroundColor: const Color(0xfffff7ec),
          titleStyle: TextStyle(
            fontFamily: SoriLocaleFonts.of(context).heading,
            fontSize: 27,
            color: Color(0xfffff7ec),
          ),
          background: const SoriCMaterialSurface(
            material: SoriCMaterial.jade,
            raised: false,
            borderRadius: BorderRadius.zero,
            child: SizedBox.expand(),
          ),
        ),
      ),
      backgroundBuilder: (context, body) =>
          Theme.of(context).brightness == Brightness.dark
          ? SoriCMaterialSurface(
              raised: false,
              borderRadius: BorderRadius.zero,
              child: body,
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    LernenGeneratedArt.assetPath('hanji-refined'),
                  ),
                  fit: BoxFit.fill,
                ),
              ),
              child: body,
            ),
      bottomNavigationBar: const SoriLearningStageNavigation(
        expandedArtwork: true,
        learningStyle: SoriLearningNavStyle.review,
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                _compactArtwork ? 12 : 37,
                16,
                _archive ? 4 : 8,
              ),
              child: SoriViewportPages(
                key: ValueKey((_archive, _level, _ownWords)),
                sections: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0x33d3b382),
                      borderRadius: BorderRadius.circular(SoriRadius.sm),
                      border: Border.all(color: const Color(0xffb7894a)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _tab(
                            t.reviewHubTodayHeadline,
                            !_archive,
                            () => setState(() => _archive = false),
                          ),
                        ),
                        Expanded(
                          child: _tab(
                            t.reviewArchiveTab,
                            _archive,
                            () => setState(() => _archive = true),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _archive
                                  ? t.reviewArchiveTitle
                                  : t.reviewHubTodayHeadline,
                              style: SoriTextTheme.of(context).body.copyWith(
                                fontFamily: language == 'de'
                                    ? SoriFonts.korean
                                    : SoriLocaleFonts.of(context).body,
                                fontWeight: FontWeight.w700,
                                fontSize: _archive ? 30 : 33,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              _archive
                                  ? t.reviewArchiveSubtitle
                                  : '${t.reviewHubDeckLabel(deck.length)} · ${t.reviewSelectedCount(selectedCount)}',
                              style: SoriTextTheme.of(
                                context,
                              ).body.copyWith(fontSize: 17, height: 1.2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: _compactArtwork ? 74 : 110,
                        height: _compactArtwork ? 74 : (_archive ? 78 : 100),
                        child: const LernenGeneratedArt(name: 'review-drawer'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_failed) ...[
                    Text(t.reviewLoadError),
                    SoriButton.ghost(label: t.reviewRetry, onTap: _load),
                  ] else if (_archive) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final level in LearnerLevel.values)
                            SizedBox(
                              width: _compactArtwork
                                  ? null
                                  : (MediaQuery.sizeOf(
                                              context,
                                            ).width.clamp(0, 460) -
                                            36) /
                                        6,
                              child: ChoiceChip(
                                key: Key('review-level-${level.display}'),
                                showCheckmark: false,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.padded,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    SoriRadius.c5Tile,
                                  ),
                                ),
                                label: Text(
                                  level.display,
                                  style: SoriTextTheme.of(context).body
                                      .copyWith(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: !_ownWords && _level == level
                                            ? Colors.white
                                            : null,
                                      ),
                                ),
                                selectedColor: const Color(0xff075444),
                                side: BorderSide(
                                  color: !_ownWords && _level == level
                                      ? const Color(0xffb7894a)
                                      : const Color(0xffd5c7b2),
                                ),
                                backgroundColor: const Color(0xfff8f0e1),
                                selected: !_ownWords && _level == level,
                                onSelected: (_) => setState(() {
                                  _level = level;
                                  _ownWords = false;
                                }),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      key: const Key('review-archive-search'),
                      style: SoriTextTheme.of(
                        context,
                      ).body.copyWith(fontSize: 17),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, size: 21),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 41,
                          minHeight: 38,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 9,
                        ),
                        fillColor: const Color(0x55fffbf3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(SoriRadius.ctrl),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(SoriRadius.ctrl),
                          borderSide: const BorderSide(
                            color: Color(0xffc9bca7),
                          ),
                        ),
                        hintText: _ownWords
                            ? t.reviewSearchHint
                            : t.wortpaketeSearchLevel(_level.display),
                      ),
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: Spacing.md),
                    if (topics.isEmpty) Text(t.reviewArchiveEmpty),
                    for (final entry in topics.entries) ...[
                      SoriCard(
                        padding: EdgeInsets.zero,
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                            dense: true,
                            key: Key('review-topic-${entry.key}'),
                            title: Text(
                              entry.key,
                              style: SoriTextTheme.of(context).body.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            minTileHeight: 52,
                            leading: const SizedBox(
                              width: 9,
                              height: 34,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xffaac3ae),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                            trailing: Icon(
                              _expandedTopics.contains(entry.key)
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                            onTap: () => setState(() {
                              if (!_expandedTopics.remove(entry.key)) {
                                _expandedTopics.add(entry.key);
                              }
                            }),
                          ),
                        ),
                      ),
                      if (_expandedTopics.contains(entry.key))
                        ..._wordTrayPages(entry.value, language, t),
                      const SizedBox(height: 4),
                    ],
                    SoriCard(
                      padding: EdgeInsets.zero,
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          dense: true,
                          key: const Key('review-own-words'),
                          title: Text(
                            t.reviewOwnWords,
                            style: SoriTextTheme.of(context).body.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          minTileHeight: 42,
                          leading: const SizedBox(
                            width: 38,
                            height: 34,
                            child: LernenGeneratedArt(name: 'jade-book'),
                          ),
                          selected: _ownWords,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => setState(() => _ownWords = true),
                        ),
                      ),
                    ),
                  ] else ...[
                    if (deck.isEmpty)
                      Text(t.reviewHubEmptyToday)
                    else ...[
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: () => setState(
                              () => _selected.addAll(deck.map((w) => w.korean)),
                            ),
                            icon: const Icon(
                              Icons.check_box_outlined,
                              size: 24,
                            ),
                            label: Text(
                              t.reviewSelectAll,
                              style: _reviewControlLabel,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => setState(_selected.clear),
                            icon: const Icon(Icons.restart_alt, size: 24),
                            label: Text(
                              t.reviewClearSelection,
                              style: _reviewControlLabel,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.dense),
                      ..._wordTrayPages(deck, language, t),
                      const SizedBox(height: Spacing.control),
                      Text(
                        t.reviewSelectHint,
                        style: SoriTextTheme.of(
                          context,
                        ).body.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: Spacing.md),
                    ],
                    if (!_loading && !_failed) ...[
                      SoriButton.outlined(
                        key: const Key('review-hub-calendar'),
                        label: t.reviewByDay,
                        semanticLabel: t.reviewHubCalendarTooltip,
                        illustrationAsset: 'assets/icons/navigation/today.png',
                        trailingIcon: Icons.chevron_right,
                        fullWidth: true,
                        accent: const Color(0xff075444),
                        textStyle: _reviewControlLabel.copyWith(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                        onTap: canOpenCalendar ? _openCalendar : null,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          if (!_loading && !_failed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                4,
                16,
                _compactArtwork
                    ? 10
                    : (_archive ? 30 : (selectionNote == null ? 57 : 32)),
              ),
              child: Column(
                children: [
                  _startButton(actionDeck, t),
                  if (selectionNote != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      selectionNote,
                      textAlign: TextAlign.center,
                      style: _reviewControlLabel.copyWith(height: 1.25),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool get _compactArtwork =>
      MediaQuery.sizeOf(context).height < 850 ||
      MediaQuery.textScalerOf(context).scale(1) > 1.15;

  TextStyle get _reviewControlLabel =>
      SoriTextTheme.of(context).body.copyWith(fontSize: 16);

  Widget _tab(String label, bool active, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.all(1),
    child: ChoiceChip(
      label: Text(
        label,
        textAlign: TextAlign.center,
        style: SoriTextTheme.of(context).body.copyWith(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: active ? const Color(0xfffff7ec) : null,
        ),
      ),
      showCheckmark: false,
      selected: active,
      selectedColor: const Color(0xff075444),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SoriRadius.ctrl),
      ),
      side: active
          ? const BorderSide(color: Color(0xffb7894a))
          : BorderSide.none,
      onSelected: (_) => onTap(),
    ),
  );

  Iterable<Widget> _wordTrayPages(
    List<Vocab> words,
    String language,
    AppL10n t,
  ) sync* {
    final viewport = MediaQuery.sizeOf(context);
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.15;
    final perTray = largeText || viewport.height < 650
        ? 1
        : (_compactArtwork ? 2 : 3);
    for (var start = 0; start < words.length; start += perTray) {
      yield _wordTray(words.skip(start).take(perTray).toList(), language, t);
    }
  }

  Widget _wordTray(List<Vocab> words, String language, AppL10n t) => Stack(
    children: [
      const Positioned.fill(
        child: LernenGeneratedArt(name: 'review-tray', fit: BoxFit.fill),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          12,
          12,
          _archive || _compactArtwork ? 12 : 25,
        ),
        child: Column(
          children: [
            for (final word in words)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.hairline),
                child: Stack(
                  children: [
                    Material(
                      color: const Color(0xfff8f0e2),
                      shadowColor: const Color(0xff4f3014),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          SoriRadius.c5DetailAction,
                        ),
                        side: const BorderSide(color: Color(0xffdbc8ad)),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: _archive ? 61 : 82,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                dense: true,
                                visualDensity: _archive
                                    ? const VisualDensity(vertical: -4)
                                    : VisualDensity.comfortable,
                                contentPadding:
                                    const EdgeInsetsDirectional.only(
                                      start: 20,
                                      end: 4,
                                    ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                key: Key('review-hub-select-${word.korean}'),
                                value: _selected.contains(word.korean),
                                activeColor: const Color(0xff0d5a48),
                                checkboxShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    SoriRadius.xxs,
                                  ),
                                ),
                                onChanged: (_) => _toggle(word.korean),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(
                                  word.korean,
                                  style: const TextStyle(
                                    fontFamily: SoriFonts.korean,
                                    height: 1.12,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  word.translationFor(language),
                                  style: SoriTextTheme.of(
                                    context,
                                  ).body.copyWith(fontSize: 16, height: 1.15),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                end: 16,
                              ),
                              child: IconButton(
                                tooltip: t.reviewPlayAudio,
                                onPressed: () => _playWord(word.korean),
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xfff8eedc),
                                  side: const BorderSide(
                                    color: Color(0xffd5bd9e),
                                  ),
                                  foregroundColor: const Color(0xff17312c),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      SoriRadius.c5Tile,
                                    ),
                                  ),
                                  minimumSize: const Size(48, 48),
                                ),
                                icon: const Icon(Icons.volume_up, size: 22),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 67,
                      top: 17,
                      bottom: 17,
                      width: 1,
                      child: IgnorePointer(
                        child: ColoredBox(color: Color(0xffdcc2a1)),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 17,
                      bottom: 17,
                      width: 7,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _selected.contains(word.korean)
                                ? const Color(0xff0d5a48)
                                : const Color(0xff739f85),
                            borderRadius: BorderRadius.circular(
                              SoriRadius.hairline,
                            ),
                            border: Border.all(color: const Color(0xff346a54)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ],
  );

  Widget _startButton(List<Vocab> source, AppL10n t) {
    final chosen = source
        .where((word) => _selected.contains(word.korean))
        .toList();
    return SizedBox(
      height: 49 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.7),
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const LernenGeneratedArt(name: 'brass-alignment', fit: BoxFit.fill),
          SoriButton.ghost(
            key: const Key('review-hub-start-selected'),
            label: t.missionHeroReviewTitle(chosen.length),
            accent: const Color(0xff111915),
            onTap: chosen.isEmpty
                ? null
                : () => _openDeck(chosen, t.reviewHubTodayHeadline),
            textStyle: SoriTextTheme.of(context).body.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 23,
              fontFamily: Localizations.localeOf(context).languageCode == 'de'
                  ? SoriFonts.korean
                  : SoriLocaleFonts.of(context).body,
              color: chosen.isEmpty ? Colors.black45 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
