part of 'vocab_packs_screen.dart';

typedef _PackTopic = ({String id, List<VocabPack> packs});

class _FeaturedTopic {
  const _FeaturedTopic(this.id, this.examples, this.art);
  final String id;
  final String examples;
  final Rect art;
}

const _featuredTopics = [
  [
    _FeaturedTopic(
      'a1_greetings',
      '안녕하세요',
      Rect.fromLTWH(102.4, 49.0, 88.7, 72.8),
    ),
    _FeaturedTopic('a1_food', '커피 · 물', Rect.fromLTWH(92.4, 41.3, 97.8, 79.6)),
    _FeaturedTopic(
      'a1_home_daily',
      '샤워 · 청소',
      Rect.fromLTWH(104.7, 35.3, 89.2, 87.8),
    ),
    _FeaturedTopic(
      'a1_transport',
      '버스 · 지하철',
      Rect.fromLTWH(109.7, 57.6, 83.3, 66.4),
    ),
  ],
  [
    _FeaturedTopic('a2_home', '거실 · 부엌', Rect.fromLTWH(99.7, 34.0, 88.7, 90.6)),
    _FeaturedTopic(
      'a2_clothing',
      '코트 · 치마',
      Rect.fromLTWH(101.5, 31.3, 85.5, 94.7),
    ),
    _FeaturedTopic(
      'a2_restaurant',
      '반찬 · 소금',
      Rect.fromLTWH(104.7, 45.3, 87.4, 79.6),
    ),
    _FeaturedTopic(
      'a2_work',
      '휴가 · 회의',
      Rect.fromLTWH(102.0, 36.7, 86.9, 86.9),
    ),
  ],
  [
    _FeaturedTopic(
      'b1_work_career',
      '출장 · 승진',
      Rect.fromLTWH(102.4, 54.0, 91.5, 77.4),
    ),
    _FeaturedTopic(
      'b1_media_culture',
      '광고 · 방송',
      Rect.fromLTWH(101.1, 31.7, 90.6, 101.0),
    ),
    _FeaturedTopic(
      'b1_tech_society',
      '팔로워 · 게시물',
      Rect.fromLTWH(117.0, 33.5, 76.4, 93.7),
    ),
    _FeaturedTopic(
      'b1_city_places',
      '광장 · 시청',
      Rect.fromLTWH(102.9, 34.8, 90.6, 91.5),
    ),
  ],
  [
    _FeaturedTopic(
      'b2_society',
      '갈등 · 가치관',
      Rect.fromLTWH(109.2, 41.8, 82.4, 88.7),
    ),
    _FeaturedTopic(
      'b2_thinking',
      '관점 · 논리',
      Rect.fromLTWH(100.2, 35.4, 91.5, 97.4),
    ),
    _FeaturedTopic(
      'b2_environment',
      '온난화 · 오염',
      Rect.fromLTWH(108.8, 33.5, 85.1, 93.3),
    ),
    _FeaturedTopic(
      'b2_work',
      '협상 · 계약',
      Rect.fromLTWH(100.2, 28.9, 92.4, 96.0),
    ),
  ],
  [
    _FeaturedTopic(
      'c1_evidence_reasoning',
      '변수를 통제하다',
      Rect.fromLTWH(106.9, 40.8, 86.9, 98.3),
    ),
    _FeaturedTopic(
      'c1_accessible_participation',
      '접근성을 확보하다',
      Rect.fromLTWH(97.9, 41.7, 93.7, 101.0),
    ),
    _FeaturedTopic(
      'c1_risk_communication',
      '불확실성을 명시하다',
      Rect.fromLTWH(103.3, 42.2, 89.2, 92.8),
    ),
    _FeaturedTopic(
      'c1_sustainable_tradeoffs',
      '유지 비용을 따지다',
      Rect.fromLTWH(101.1, 34.5, 87.4, 102.4),
    ),
  ],
  [
    _FeaturedTopic(
      'c2_language_framing',
      '논점을 흐리다',
      Rect.fromLTWH(113.3, 41.7, 78.3, 96.5),
    ),
    _FeaturedTopic(
      'c2_narrative_perspective',
      '기억을 재구성하다',
      Rect.fromLTWH(101.1, 47.7, 90.6, 91.0),
    ),
    _FeaturedTopic(
      'c2_institutional_mediation',
      '이해관계가 얽히다',
      Rect.fromLTWH(102.4, 54.5, 89.6, 78.3),
    ),
    _FeaturedTopic(
      'c2_technology_ethics',
      '설명 가능성을 확보하다',
      Rect.fromLTWH(103.8, 47.2, 86.0, 90.1),
    ),
  ],
];

class _WortpaketeCatalog extends StatefulWidget {
  const _WortpaketeCatalog({
    required this.packs,
    required this.browseLevel,
    required this.loading,
    required this.loadError,
    required this.onRetry,
    required this.onLevel,
    required this.onPack,
    required this.onDojang,
  });

  final List<VocabPack> packs;
  final String browseLevel;
  final bool loading;
  final String? loadError;
  final VoidCallback onRetry;
  final ValueChanged<String> onLevel;
  final ValueChanged<VocabPack> onPack;
  final VoidCallback onDojang;

  @override
  State<_WortpaketeCatalog> createState() => _WortpaketeCatalogState();
}

class _WortpaketeCatalogState extends State<_WortpaketeCatalog> {
  static const _paper = Color(0xfffff7ec);
  static const _ink = Color(0xff111917);
  static const _edge = Color(0xffe5d5bc);
  static const _brass = Color(0xffa6783d);
  static const _jade = Color(0xff194637);
  static const _searchRadius = BorderRadius.all(Radius.circular(10));
  static const _levelRowRadius = BorderRadius.all(Radius.circular(13));
  static const _badgeRadius = BorderRadius.all(Radius.circular(9));
  static const _topicRadius = BorderRadius.all(Radius.circular(14));
  // Measured in the approved 430 × 932 artwork.
  static const _levelHeaderGap = 16.0;
  static const _searchInset = 2.0;
  static const _inlineGap = 6.0;
  static const _packActionGap = 11.0;
  bool get _shortViewport => MediaQuery.sizeOf(context).height < 900;
  final _search = TextEditingController();
  LearnerLevel? _level;
  String? _topicId;
  String? _packId;
  bool _goldPressed = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.of(context).accessibleNavigation;

  String _lang(BuildContext context) =>
      Localizations.localeOf(context).languageCode;

  TextStyle _type(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = _ink,
    bool korean = false,
    bool heading = false,
  }) {
    final fonts = SoriLocaleFonts.of(context);
    return TextStyle(
      fontFamily: korean
          ? SoriFonts.korean
          : heading
          ? fonts.heading
          : fonts.body,
      fontFamilyFallback: SoriLocaleFonts.fallback,
      color: color,
      fontWeight: heading ? fonts.headingWeight : fonts.bodyWeight(weight),
      fontSize: size,
      height: 1.2,
    );
  }

  Map<LearnerLevel, List<VocabPack>> _byLevel() {
    final levels = {
      for (final level in LearnerLevel.values) level: <VocabPack>[],
    };
    for (final pack in widget.packs) {
      levels[LearnerLevel.fromCode(pack.level)]?.add(pack);
    }
    return levels;
  }

  List<_PackTopic> _topics(List<VocabPack> packs) {
    final topics = <String, List<VocabPack>>{};
    for (final pack in packs) {
      topics.putIfAbsent(VocabPackService.topicId(pack.id), () => []).add(pack);
    }
    return [
      for (final entry in topics.entries) (id: entry.key, packs: entry.value),
    ];
  }

  String _topicName(_PackTopic topic, {bool short = false}) {
    final label = short
        ? AppL10n.of(context).wortpaketeTopicName(topic.id)
        : '';
    return label.isNotEmpty
        ? label
        : VocabPackService.topicLabel(
            topic.packs.first.id,
            lang: _lang(context),
          );
  }

  void _selectLevel(LearnerLevel? level) {
    FocusScope.of(context).unfocus();
    _search.clear();
    setState(() {
      _level = level;
      _topicId = null;
      _packId = null;
    });
    if (level != null) {
      widget.onLevel(level.display);
    }
  }

  void _selectTopic(_PackTopic topic) {
    setState(() {
      _topicId = topic.id;
      _packId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final title = t.soriStageActivityTitle('vocab_packs');
    final level = _level;
    final all = _byLevel();
    final query = _search.text.trim().toLowerCase();
    final packs = level == null ? widget.packs : all[level]!;
    final normalHeader = MediaQuery.textScalerOf(context).scale(23) <= 32;
    final toolbarHeight = normalHeader ? 48.0 : 78.0;
    return PopScope(
      canPop: level == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && level != null) {
          _selectLevel(null);
        }
      },
      child: SoriStudyFrame(
        title: title,
        padding: EdgeInsets.zero,
        homeContent: const SizedBox(
          width: 48,
          child: Center(
            child: ApprovedChromeImage(
              asset: 'design_assets/hoeren/home-c-v1.png',
              size: 38,
            ),
          ),
        ),
        headerBuilder: (context, leading, actions) => SoriAppBar(
          title: title,
          textScale: MediaQuery.textScalerOf(context).scale(1),
          viewportWidth: MediaQuery.sizeOf(context).width,
          leading: level == null
              ? BackButton(onPressed: () => Navigator.of(context).maybePop())
              : BackButton(onPressed: () => _selectLevel(null)),
          actions: actions,
          appearance: SoriAppBarAppearance(
            toolbarHeight: toolbarHeight,
            foregroundColor: _paper,
            titleStyle: _type(23, color: _paper, heading: true),
            background: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(LernenGeneratedArt.assetPath('jade')),
                  fit: BoxFit.cover,
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        backgroundBuilder: (context, body) =>
            Theme.of(context).brightness == Brightness.dark
            ? SoriCMaterialSurface(
                raised: false,
                borderRadius: BorderRadius.zero,
                tint: const Color(0xb3fff7ec),
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
          learningStyle: SoriLearningNavStyle.vocabulary,
        ),
        child: widget.loadError != null
            ? AppError(message: widget.loadError!, onRetry: widget.onRetry)
            : widget.loading && widget.packs.isEmpty
            ? const AppLoading()
            : Padding(
                padding: EdgeInsets.fromLTRB(
                  15,
                  level == null
                      ? 15
                      : (level.index >= 4 || _shortViewport ? 8 : 18),
                  15,
                  0,
                ),
                child: SoriViewportPages(
                  key: ValueKey(level),
                  sections: [
                    if (MediaQuery.viewInsetsOf(context).bottom == 0)
                      if (level == null)
                        _overviewHeader(t)
                      else ...[
                        _levelHeader(t, level, packs),
                        SizedBox(height: _shortViewport ? 8 : _levelHeaderGap),
                        _levelTabs(level),
                      ],
                    if (MediaQuery.viewInsetsOf(context).bottom == 0)
                      SizedBox(
                        height: level == null ? 27 : (_shortViewport ? 6 : 14),
                      ),
                    Padding(
                      key: const ValueKey('wortpakete-search-section'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: _searchInset,
                      ),
                      child: _searchField(t, level),
                    ),
                    SizedBox(
                      height: level == null ? 20 : (_shortViewport ? 5 : 10),
                    ),
                    if (query.isNotEmpty)
                      ..._searchResults(t, packs, query)
                    else if (level == null) ...[
                      ..._levels(t, all),
                      TextButton(
                        onPressed: widget.onDojang,
                        child: Text(t.dojangTitle),
                      ),
                    ] else
                      ..._detail(t, level, packs),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _overviewHeader(AppL10n t) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.wortpaketeOverview, style: _type(34, heading: true)),
            const SizedBox(height: 4),
            Text(t.wortpaketeChooseLevel, style: _type(20, color: _jade)),
          ],
        ),
      ),
      Image.asset(
        'design_assets/wortpakete/0-0.png',
        width: 84,
        height: 96,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      ),
    ],
  );

  Widget _levelHeader(AppL10n t, LearnerLevel level, List<VocabPack> packs) {
    final topics = _topics(packs).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 35),
          child: Text(
            t.wortpaketeLevelGoal(level),
            style: _type(30, weight: FontWeight.w700).copyWith(
              fontFamily: _lang(context) == 'de' ? SoriFonts.korean : null,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${level.display} · ${t.wortpaketeTopicsCount(topics)} · ${t.wortpaketePacks(packs.length)}',
          style: _type(16, color: const Color(0xff5b6060)),
        ),
      ],
    );
  }

  Widget _searchField(AppL10n t, LearnerLevel? level) => TextField(
    key: const ValueKey('wortpakete-search'),
    controller: _search,
    textInputAction: TextInputAction.search,
    style: _type(17),
    onChanged: (_) => setState(() {}),
    decoration: InputDecoration(
      hintText: level == null
          ? t.wortpaketeSearchAll
          : t.wortpaketeSearchLevel(level.display),
      prefixIcon: const Icon(Icons.search, size: 22),
      prefixIconConstraints: const BoxConstraints(minWidth: 43, minHeight: 37),
      isDense: true,
      suffixIcon: _search.text.isEmpty
          ? null
          : IconButton(
              tooltip: t.wortpaketeSearchClear,
              onPressed: () => setState(_search.clear),
              icon: const Icon(Icons.close),
            ),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      filled: true,
      fillColor: const Color(0x60fffbf3),
      enabledBorder: OutlineInputBorder(
        borderRadius: _searchRadius,
        borderSide: const BorderSide(color: Color(0xffc9bca7)),
      ),
      border: const OutlineInputBorder(borderRadius: _searchRadius),
    ),
  );

  List<Widget> _levels(AppL10n t, Map<LearnerLevel, List<VocabPack>> all) => [
    for (final level in LearnerLevel.values)
      Semantics(
        button: true,
        selected: widget.browseLevel == level.display,
        child: SoriPressable(
          pressScale: 1,
          onTap: () => _selectLevel(level),
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: _levelRowRadius,
              border: Border.all(
                color: widget.browseLevel == level.display
                    ? _brass
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                _badge(level.display, false, fontSize: 23),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.wortpaketeLevelGoal(level),
                        style: _type(17, weight: FontWeight.w700),
                      ),
                      Text(t.wortpaketeLevelHint(level), style: _type(13)),
                      if (MediaQuery.textScalerOf(context).scale(1) > 1.3)
                        Text(
                          t.wortpaketePacks(all[level]!.length),
                          style: _type(13),
                        ),
                    ],
                  ),
                ),
                if (MediaQuery.textScalerOf(context).scale(1) <= 1.3)
                  Text(
                    t.wortpaketePacks(all[level]!.length),
                    style: _type(13, weight: FontWeight.w700),
                  ),
                const SizedBox(width: _inlineGap),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
  ];

  Widget _badge(
    String label,
    bool selected, {
    double fontSize = 18,
  }) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: _badgeRadius,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: selected
            ? const [Color(0xff294c3b), Color(0xff183729)]
            : const [Color(0xfffbf5e9), Color(0xfff6edde)],
      ),
      border: Border.all(color: selected ? _brass : const Color(0xffdacdb7)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x227f6640),
          offset: Offset(0, 2),
          blurRadius: 2,
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 8),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: _type(
          fontSize,
          weight: FontWeight.w700,
          color: selected ? _paper : _ink,
        ),
      ),
    ),
  );

  Widget _levelTabs(LearnerLevel level) => LayoutBuilder(
    builder: (context, bounds) {
      final fit =
          bounds.maxWidth >= SoriAdaptiveWidth.wortpaketeLevelRow &&
          MediaQuery.textScalerOf(context).scale(1) <= 1.35;
      return SoriLevelFilterBar(
        selected: level.code,
        onChanged: (code) => _selectLevel(LearnerLevel.fromCode(code)),
        choiceBuilder: (item, selected) => ConstrainedBox(
          key: ValueKey('wortpakete-level-${item.code}'),
          constraints: const BoxConstraints(
            minWidth: SoriLayout.chromeRowTouchHeight,
            minHeight: SoriLayout.chromeRowTouchHeight,
          ),
          child: Align(
            heightFactor: 1,
            child: SizedBox(
              width: fit
                  ? (bounds.maxWidth - 42) / LearnerLevel.values.length
                  : null,
              child: _badge(item.display, selected),
            ),
          ),
        ),
        choiceLayout: (choices) => fit
            ? Row(
                children: choices
                    .map((choice) => Expanded(child: choice))
                    .toList(),
              )
            : Wrap(spacing: _inlineGap, children: choices),
      );
    },
  );

  List<Widget> _detail(AppL10n t, LearnerLevel level, List<VocabPack> packs) {
    final topics = _topics(packs);
    if (topics.isEmpty) {
      return [
        SoriEmptyState(
          icon: Icons.menu_book_outlined,
          title: t.vocabPacksEmptyTitle,
          body: t.vocabPacksEmptyBody,
        ),
      ];
    }
    final features = _featuredTopics[level.index];
    final featured = <(_PackTopic, int)>[];
    for (final (index, f) in features.indexed) {
      final topic = topics.where((e) => e.id == f.id).firstOrNull;
      if (topic != null) {
        featured.add((topic, index));
      }
    }
    final selected =
        topics.where((e) => e.id == _topicId).firstOrNull ??
        featured.firstOrNull?.$1 ??
        topics.first;
    final pack =
        selected.packs.where((p) => p.id == _packId).firstOrNull ??
        selected.packs.first;
    final columns =
        MediaQuery.sizeOf(context).width - 30 >=
                SoriAdaptiveWidth.wortpaketeTopicGrid &&
            MediaQuery.textScalerOf(context).scale(1) <= 1.1 &&
            _lang(context) == 'de'
        ? 2
        : 1;
    return [
      Row(
        children: [
          Expanded(
            child: Text(
              t.wortpaketeTopics,
              style: _type(24, weight: FontWeight.w700),
            ),
          ),
          TextButton.icon(
            onPressed: () => _pickTopic(t, level, topics),
            label: Text(
              t.wortpaketeAllTopicsCount(topics.length),
              style: _type(16, weight: FontWeight.w700),
            ),
            icon: const Icon(Icons.arrow_forward),
            iconAlignment: IconAlignment.end,
          ),
        ],
      ),
      SizedBox(height: _shortViewport ? 3 : _inlineGap),
      for (var first = 0; first < featured.length; first += columns) ...[
        if (first > 0) const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (offset, feature)
                in featured.skip(first).take(columns).indexed) ...[
              if (offset > 0) const SizedBox(width: 10),
              Expanded(
                child: _topicCard(
                  t,
                  level,
                  feature.$1,
                  feature.$2,
                  selected.id == feature.$1.id,
                  columns == 2,
                ),
              ),
            ],
            if (columns == 2 && featured.length - first == 1) ...[
              const SizedBox(width: 10),
              const Spacer(),
            ],
          ],
        ),
      ],
      SizedBox(height: _shortViewport ? 8 : 16),
      Row(
        children: [
          const SizedBox(
            width: 5,
            height: 23,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _jade,
                borderRadius: BorderRadius.all(Radius.circular(3)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _topicName(selected, short: true),
              style: _type(21, weight: FontWeight.w700),
            ),
          ),
          Text(t.wortpaketePacks(selected.packs.length), style: _type(15)),
        ],
      ),
      const SizedBox(height: 8),
      LayoutBuilder(
        builder: (context, constraints) => Wrap(
          spacing: 2,
          runSpacing: 4,
          children: [
            for (final (index, item) in selected.packs.indexed)
              Semantics(
                selected: item.id == pack.id,
                button: true,
                child: SizedBox(
                  width:
                      selected.packs.length <= 2 &&
                          constraints.maxWidth >=
                              SoriAdaptiveWidth.wortpaketeTopicGrid &&
                          MediaQuery.textScalerOf(context).scale(1) <= 1.15
                      ? (constraints.maxWidth -
                                2 * (selected.packs.length - 1)) /
                            selected.packs.length
                      : null,
                  child: OutlinedButton(
                    key: ValueKey('wortpakete-select-${item.id}'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: item.id == pack.id ? _jade : _paper,
                      foregroundColor: item.id == pack.id ? _paper : _ink,
                      minimumSize: const Size.fromHeight(40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      textStyle: _type(17, weight: FontWeight.w700),
                    ),
                    onPressed: () => setState(() => _packId = item.id),
                    child: Text(
                      '${t.wortpaketePackNumber(index + 1)} · ${t.wortpaketeWords(item.words.length)}',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      SizedBox(height: _shortViewport ? 7 : 12),
      _preview(t, selected, pack),
      SizedBox(height: _shortViewport ? 8 : _packActionGap),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: _goldAction(
          t.wortpaketeOpenNumberedPack(selected.packs.indexOf(pack) + 1),
          () => widget.onPack(pack),
        ),
      ),
    ];
  }

  Widget _topicCard(
    AppL10n t,
    LearnerLevel level,
    _PackTopic topic,
    int index,
    bool selected,
    bool compact,
  ) {
    final feature = _featuredTopics[level.index][index];
    final examples = feature.examples
        .split(' · ')
        .where(
          (example) =>
              topic.packs.any((p) => p.words.any((w) => w.korean == example)),
        )
        .join(' · ');
    final art = level == LearnerLevel.a1
        ? LernenGeneratedArt(
            name: [
              'topic-fan',
              'topic-cup',
              'topic-home',
              'topic-transport',
            ][index],
          )
        : Image.asset(
            'design_assets/wortpakete/${level.index + 1}-$index.png',
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          );
    final name = _topicName(topic, short: true);
    final title = compact ? _cardTitle(topic.id, name) : name;
    final goal = t.wortpaketeTopicGoal(topic.id);
    final shownExamples = compact
        ? _cardExamples(topic.id, examples)
        : examples;
    final titleStyle = _type(18, weight: FontWeight.w700);
    final exampleStyle = _type(15, weight: FontWeight.w700, korean: true);
    final cardHeight = level.index >= 4 ? 150.0 : 123.0;
    final cardBody = compact
        ? SizedBox(
            height: cardHeight,
            child: LayoutBuilder(
              builder: (context, bounds) {
                final artBox = feature.art;
                final imageLeft = (artBox.left / 197) * bounds.maxWidth;
                final imageWidth = (artBox.width / 197) * bounds.maxWidth;
                final double goalWidth = bounds.maxWidth - 24;
                final double titleWidth =
                    bounds.maxWidth - (selected ? 42 : 20);
                return Stack(
                  children: [
                    Positioned(
                      left: imageLeft,
                      top: math.max(70, artBox.top),
                      width: imageWidth,
                      height: math.min(50, artBox.height),
                      child: art,
                    ),
                    Positioned(
                      left: 12,
                      top: 10,
                      width: titleWidth,
                      child: Text(title, style: titleStyle, maxLines: 2),
                    ),
                    Positioned(
                      left: 12,
                      top: _featuredTitleWrap(title, titleWidth, titleStyle)
                          ? 56
                          : 36,
                      width: goalWidth,
                      child: Text(goal, style: _type(13), maxLines: 3),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 29,
                      width: imageLeft - 12,
                      child: Text(
                        shownExamples,
                        style: exampleStyle,
                        maxLines: 2,
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xffe2e8d8),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 1,
                          ),
                          child: Text(
                            t.wortpaketePacks(topic.packs.length),
                            style: _type(12),
                          ),
                        ),
                      ),
                    ),
                    if (selected)
                      const Positioned(
                        top: 10,
                        right: 11,
                        child: Icon(Icons.check, size: 19, color: _jade),
                      ),
                  ],
                );
              },
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(title, style: titleStyle)),
                    if (selected)
                      const Icon(Icons.check, size: 19, color: _jade),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(goal, style: _type(13)),
                          const SizedBox(height: 4),
                          Text(examples, style: exampleStyle),
                          Text(
                            t.wortpaketePacks(topic.packs.length),
                            style: _type(12),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: feature.art.width,
                      height: feature.art.height,
                      child: art,
                    ),
                  ],
                ),
              ],
            ),
          );
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        borderRadius: _topicRadius,
        child: SoriPressable(
          pressScale: 1,
          pressOffsetY: 2,
          pressDuration: const Duration(milliseconds: 90),
          releaseDuration: const Duration(milliseconds: 90),
          key: ValueKey('wortpakete-topic-${topic.id}'),
          onTap: () => _selectTopic(topic),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xfffdf8ee), Color(0xfff4e9d6)],
              ),
              borderRadius: _topicRadius,
              border: Border.all(
                color: selected ? const Color(0xff168169) : _edge,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2e4f3014),
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
                BoxShadow(
                  color: Color(0x99ffffff),
                  blurRadius: 1,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: cardBody,
          ),
        ),
      ),
    );
  }

  String _cardTitle(String id, String name) => switch (id) {
    'a1_greetings' ||
    'b1_work_career' ||
    'b1_media_culture' ||
    'b1_tech_society' ||
    'c1_evidence_reasoning' ||
    'c2_language_framing' => _breakLastWord(name),
    'c1_risk_communication' => name.replaceAll('\u00ad', '-\n'),
    _ => name,
  };

  String _cardExamples(String id, String examples) => switch (id) {
    'c1_accessible_participation' ||
    'c1_risk_communication' ||
    'c1_sustainable_tradeoffs' ||
    'c2_narrative_perspective' ||
    'c2_institutional_mediation' ||
    'c2_technology_ethics' => _breakLastWord(examples),
    _ => examples,
  };

  String _breakLastWord(String text) {
    final index = text.lastIndexOf(' ');
    return index < 0 ? text : text.replaceRange(index, index + 1, '\n');
  }

  bool _featuredTitleWrap(String text, double width, TextStyle style) {
    final measure = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout(maxWidth: width);
    final wraps = measure.didExceedMaxLines;
    measure.dispose();
    return wraps;
  }

  Widget _preview(AppL10n t, _PackTopic topic, VocabPack pack) {
    final progress = PackProgressService.getAll()[pack.id];
    final goal = topic.id == 'a1_greetings'
        ? t.wortpaketeGreetingPackGoal
        : t.wortpaketeTopicGoal(topic.id);
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: _shortViewport ? 92 : 104),
      child: Stack(
        children: [
          const Positioned.fill(
            child: LernenGeneratedArt(name: 'folio-preview', fit: BoxFit.fill),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(50, 13, 13, 19),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _examples(pack),
                        style: _type(23, weight: FontWeight.w700, korean: true),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        goal.isNotEmpty
                            ? goal
                            : t.wortpaketeWords(pack.words.length),
                        style: _type(15),
                      ),
                      if (progress != null && progress.wordsLearned > 0)
                        LinearProgressIndicator(
                          value: (progress.wordsLearned / pack.words.length)
                              .clamp(0.0, 1.0),
                          semanticsLabel: t.wortpaketeWords(
                            progress.wordsLearned,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 76,
                  height: 64,
                  child: LernenGeneratedArt(name: 'jade-book'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _examples(VocabPack pack) =>
      pack.words.take(2).map((word) => word.korean).join(' · ');

  Widget _goldAction(String label, VoidCallback action) => Semantics(
    button: true,
    child: SoriPressable(
      key: const ValueKey('wortpakete-open-pack'),
      pressScale: 1,

      onPressedChanged: (pressed) => setState(() => _goldPressed = pressed),
      pressDuration: const Duration(milliseconds: 90),
      releaseDuration: const Duration(milliseconds: 90),
      surfaceDepth: _reduced(context) ? 0 : 8 / 3,
      surfaceRadius: 13,
      surfaceEdgeColor: const Color(0xff765020),
      onTap: action,
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: _goldPressed ? .8 : 1,
              child: const LernenGeneratedArt(
                name: 'brass-alignment',
                fit: BoxFit.fill,
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: _type(21, weight: FontWeight.w700).copyWith(
                fontFamily: _lang(context) == 'de' ? SoriFonts.korean : null,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  List<Widget> _searchResults(AppL10n t, List<VocabPack> packs, String query) {
    final lang = _lang(context);
    final found = packs.where((p) {
      return VocabPackService.displayLabel(
            p.id,
            lang: lang,
          ).toLowerCase().contains(query) ||
          VocabPackService.topicLabel(
            p.id,
            lang: lang,
          ).toLowerCase().contains(query) ||
          t
              .wortpaketeTopicName(VocabPackService.topicId(p.id))
              .toLowerCase()
              .contains(query) ||
          p.words.any(
            (w) =>
                w.korean.contains(query) ||
                w.translationFor(lang).toLowerCase().contains(query),
          );
    }).toList();
    return [
      if (found.isEmpty)
        SoriEmptyState(icon: Icons.search, title: t.wortpaketeNoResults)
      else
        ...found.map((p) {
          final matched = p.words
              .where(
                (word) =>
                    word.korean.contains(query) ||
                    word.translationFor(lang).toLowerCase().contains(query),
              )
              .take(2)
              .toList();
          return ListTile(
            key: ValueKey('wortpakete-search-${p.id}'),
            leading: Text(p.level, style: _type(14, weight: FontWeight.w700)),
            title: Text(VocabPackService.displayLabel(p.id, lang: lang)),
            subtitle: Text(
              matched.isEmpty
                  ? _examples(p)
                  : matched.map((w) => w.korean).join(' · '),
              style: _type(14, korean: true),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              FocusScope.of(context).unfocus();
              widget.onPack(p);
            },
          );
        }),
    ];
  }

  Future<void> _pickTopic(
    AppL10n t,
    LearnerLevel level,
    List<_PackTopic> topics,
  ) async {
    final packs = topics.expand((topic) => topic.packs);
    final progress = PackProgressService.getAll();
    final topic = await _pick(
      title: t.wortpaketeTopics,
      items: topics,
      label: _topicName,
      subtitle: (item) => t.wortpaketePacks(item.packs.length),
      header: _LevelProgressHeader(
        level: level.display,
        cleared: packs
            .where((pack) => progress[pack.id]?.isCleared == true)
            .length,
        total: packs.length,
      ),
    );
    if (topic != null && mounted) {
      _selectTopic(topic);
    }
  }

  Future<T?> _pick<T>({
    required String title,
    required List<T> items,
    required String Function(T) label,
    required String Function(T) subtitle,
    Widget? header,
  }) => showSoriSheet<T>(
    context: context,
    presentation: const SoriSheetPresentation(backgroundColor: _paper),
    maxHeightFactor: 1,
    animationStyle: _reduced(context)
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: Duration(milliseconds: 220),
            reverseDuration: Duration(milliseconds: 180),
          ),
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: .78,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: _type(22, weight: FontWeight.w700),
                    ),
                  ),
                  const CloseButton(),
                ],
              ),
            ),
            Expanded(
              child: SoriViewportPages(
                sections: [
                  if (header != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: header,
                    ),
                  for (final item in items)
                    ListTile(
                      title: Text(label(item)),
                      subtitle: Text(subtitle(item)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(sheetContext).pop(item),
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

extension _WortpaketeLevelCopy on AppL10n {
  String wortpaketeLevelGoal(LearnerLevel level) => switch (level) {
    LearnerLevel.a1 => wortpaketeLevelGoalA1,
    LearnerLevel.a2 => wortpaketeLevelGoalA2,
    LearnerLevel.b1 => wortpaketeLevelGoalB1,
    LearnerLevel.b2 => wortpaketeLevelGoalB2,
    LearnerLevel.c1 => wortpaketeLevelGoalC1,
    LearnerLevel.c2 => wortpaketeLevelGoalC2,
  };

  String wortpaketeLevelHint(LearnerLevel level) => switch (level) {
    LearnerLevel.a1 => wortpaketeLevelHintA1,
    LearnerLevel.a2 => wortpaketeLevelHintA2,
    LearnerLevel.b1 => wortpaketeLevelHintB1,
    LearnerLevel.b2 => wortpaketeLevelHintB2,
    LearnerLevel.c1 => wortpaketeLevelHintC1,
    LearnerLevel.c2 => wortpaketeLevelHintC2,
  };
}
