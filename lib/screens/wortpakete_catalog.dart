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
  final _search = TextEditingController();
  final _scroll = ScrollController();
  LearnerLevel? _level;
  String? _topicId;
  String? _packId;
  bool _goldPressed = false;

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
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
    if (_scroll.hasClients) {
      _scroll.jumpTo(0);
    }
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
        headerBuilder: (context, leading, actions) => AppBar(
          toolbarHeight: toolbarHeight,
          backgroundColor: Colors.transparent,
          foregroundColor: _paper,
          centerTitle: true,
          scrolledUnderElevation: 0,
          leading: level == null
              ? BackButton(onPressed: () => Navigator.of(context).maybePop())
              : BackButton(onPressed: () => _selectLevel(null)),
          actions: actions,
          flexibleSpace: const SoriCMaterialSurface(
            material: SoriCMaterial.jade,
            raised: false,
            borderRadius: BorderRadius.zero,
            child: SizedBox.expand(),
          ),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: _type(23, color: _paper, heading: true),
          ),
        ),
        backgroundBuilder: (context, body) => SoriCMaterialSurface(
          raised: false,
          borderRadius: BorderRadius.zero,
          tint: const Color(0xb3fff7ec),
          child: body,
        ),
        bottomNavigationBar: const SoriLearningStageNavigation(),
        child: widget.loadError != null
            ? AppError(message: widget.loadError!, onRetry: widget.onRetry)
            : widget.loading && widget.packs.isEmpty
            ? const AppLoading()
            : CustomScrollView(
                controller: _scroll,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      15,
                      level == null
                          ? 15
                          : level.index >= 4
                          ? 8
                          : 18,
                      15,
                      20,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (level == null)
                            _overviewHeader(t)
                          else ...[
                            _levelHeader(t, level, packs),
                            const SizedBox(height: 14),
                            _levelTabs(level),
                          ],
                          SizedBox(height: level == null ? 27 : 2),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _searchField(t, level),
                          ),
                          SizedBox(height: level == null ? 20 : 16),
                          if (query.isEmpty)
                            if (level == null)
                              _levels(t, all)
                            else
                              AnimatedSwitcher(
                                duration: _reduced(context)
                                    ? Duration.zero
                                    : const Duration(milliseconds: 160),
                                layoutBuilder: (current, _) =>
                                    current ?? const SizedBox.shrink(),
                                child: KeyedSubtree(
                                  key: ValueKey(level),
                                  child: _detail(t, level, packs),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                  if (query.isNotEmpty) _searchResults(t, packs, query),
                  if (query.isEmpty && level == null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 148, 16, 16),
                        child: TextButton(
                          onPressed: widget.onDojang,
                          child: Text(t.dojangTitle),
                        ),
                      ),
                    ),
                ],
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
    final words = packs.fold(0, (count, pack) => count + pack.words.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: level.index < 4 ? 43 : 37),
          child: Text(
            t.wortpaketeLevelGoal(level.code),
            style: _type(level.index < 2 ? 36 : 31, heading: true),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${t.wortpaketePacks(packs.length)} · ${t.wortpaketeWords(words)}',
          style: _type(18, color: const Color(0xff2d4e5b)),
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
      prefixIcon: const Icon(Icons.search),
      suffixIcon: _search.text.isEmpty
          ? null
          : IconButton(
              tooltip: t.wortpaketeSearchClear,
              onPressed: () => setState(_search.clear),
              icon: const Icon(Icons.close),
            ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      filled: true,
      fillColor: const Color(0x60fffbf3),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xffc9bca7)),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

  Widget _levels(AppL10n t, Map<LearnerLevel, List<VocabPack>> all) => Column(
    children: [
      for (final level in LearnerLevel.values)
        Semantics(
          button: true,
          selected: widget.browseLevel == level.display,
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: () => _selectLevel(level),
            child: Container(
              constraints: const BoxConstraints(minHeight: 72),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
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
                          t.wortpaketeLevelGoal(level.code),
                          style: _type(17, weight: FontWeight.w700),
                        ),
                        Text(
                          t.wortpaketeLevelHint(level.code),
                          style: _type(13),
                        ),
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
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
    ],
  );

  Widget _badge(String label, bool selected, {double fontSize = 18}) =>
      DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: selected
                ? const [Color(0xff294c3b), Color(0xff183729)]
                : const [Color(0xfffbf1e2), Color(0xfff0dfca)],
          ),
          border: Border.all(
            color: selected ? _brass : const Color(0xfff9efdf),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
          bounds.maxWidth >= 336 &&
          MediaQuery.textScalerOf(context).scale(1) <= 1.35;
      Widget tab(LearnerLevel item) => Semantics(
        button: true,
        selected: item == level,
        child: InkWell(
          key: ValueKey('wortpakete-level-${item.code}'),
          borderRadius: BorderRadius.circular(9),
          onTap: item == level ? null : () => _selectLevel(item),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Align(
              heightFactor: 1,
              child: SizedBox(
                width: fit ? (bounds.maxWidth - 42) / 6 : null,
                child: _badge(item.display, item == level),
              ),
            ),
          ),
        ),
      );
      if (!fit) {
        return Wrap(
          spacing: 6,
          children: LearnerLevel.values.map(tab).toList(),
        );
      }
      return Row(
        children: [
          for (final item in LearnerLevel.values) Expanded(child: tab(item)),
        ],
      );
    },
  );

  Widget _detail(AppL10n t, LearnerLevel level, List<VocabPack> packs) {
    final topics = _topics(packs);
    if (topics.isEmpty) {
      return SoriEmptyState(
        icon: Icons.menu_book_outlined,
        title: t.vocabPacksEmptyTitle,
        body: t.vocabPacksEmptyBody,
      );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.wortpaketeTopics, style: _type(22, weight: FontWeight.w700)),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, box) {
            final columns =
                box.maxWidth >= 355 &&
                    MediaQuery.textScalerOf(context).scale(1) <= 1.1 &&
                    _lang(context) == 'de'
                ? 2
                : 1;
            final width = (box.maxWidth - 10 * (columns - 1)) / columns;
            return Wrap(
              spacing: 10,
              runSpacing: 12,
              children: [
                for (final (topic, index) in featured)
                  SizedBox(
                    width: width,
                    child: _topicCard(
                      t,
                      level,
                      topic,
                      index,
                      selected.id == topic.id,
                      columns == 2,
                    ),
                  ),
              ],
            );
          },
        ),
        ListTile(
          minTileHeight: 48,
          visualDensity: VisualDensity.compact,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          title: Text(t.wortpaketeAllTopics, style: _type(18)),
          trailing: const Icon(Icons.arrow_forward),
          onTap: () => _pickTopic(t, level, topics),
        ),
        const Divider(height: 5, color: _edge),
        const SizedBox(height: 5),
        _preview(t, selected, pack),
        const SizedBox(height: 18),
        _goldAction(t.wortpaketeOpenPack, () => widget.onPack(pack)),
        const SizedBox(height: 16),
      ],
    );
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
    final art = Image.asset(
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
    final cardHeight = level.index >= 4 ? 143.0 : 134.0;
    final cardBody = compact
        ? SizedBox(
            height: cardHeight,
            child: LayoutBuilder(
              builder: (context, bounds) {
                final artBox = feature.art;
                final imageLeft = (artBox.left / 197) * bounds.maxWidth;
                final imageWidth = (artBox.width / 197) * bounds.maxWidth;
                final double goalWidth = (imageLeft - 16).clamp(82, 126);
                final double titleWidth =
                    bounds.maxWidth - (selected ? 42 : 20);
                return Stack(
                  children: [
                    Positioned(
                      left: imageLeft,
                      top: artBox.top,
                      width: imageWidth,
                      height: artBox.height,
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
                      bottom: 11,
                      width: goalWidth + 5,
                      child: Text(
                        shownExamples,
                        style: exampleStyle,
                        maxLines: 2,
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
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: ValueKey('wortpakete-topic-${topic.id}'),
          onTap: () => _selectTopic(topic),
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xfffff6e8), Color(0xfff5e8d3)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? _brass : _edge),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x196a4b27),
                  blurRadius: 3,
                  offset: Offset(0, 1),
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
    'a1_food' ||
    'a1_home_daily' ||
    'a1_transport' ||
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
    final lang = _lang(context);
    final progress = PackProgressService.getAll()[pack.id];
    final title = topic.packs.length > 1
        ? '${_topicName(topic, short: true)} · ${t.wortpaketePackNumber(topic.packs.indexOf(pack) + 1)}'
        : VocabPackService.displayLabel(pack.id, lang: lang);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      constraints: const BoxConstraints(minHeight: 100),
      decoration: BoxDecoration(
        color: const Color(0xadfaefde),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _edge),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1f6a4b27),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 27,
            decoration: BoxDecoration(
              color: _ink,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _type(21, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.wortpaketeWords(pack.words.length),
                            style: _type(16),
                          ),
                          Text(_examples(pack), style: _type(16, korean: true)),
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
                    if (topic.packs.length > 1)
                      IconButton(
                        tooltip: t.wortpaketePacks(topic.packs.length),
                        onPressed: () => _pickPack(t, topic, pack),
                        icon: const Icon(Icons.expand_more),
                      ),
                  ],
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
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xffcd933d),
              Color(0xfff2c772),
              Color(0xfff7d08a),
              Color(0xffc18c3c),
            ],
            stops: [0, .34, .63, 1],
          ),
          boxShadow: _reduced(context)
              ? const [
                  BoxShadow(color: Color(0xff765020), offset: Offset(0, 3)),
                ]
              : null,
          backgroundBlendMode: _goldPressed && _reduced(context)
              ? BlendMode.multiply
              : null,
          color: _goldPressed && _reduced(context)
              ? const Color(0xffe9d6b6)
              : null,
          border: Border.all(color: _brass),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: _type(23, weight: FontWeight.w700),
        ),
      ),
    ),
  );

  SliverPadding _searchResults(AppL10n t, List<VocabPack> packs, String query) {
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
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      sliver: found.isEmpty
          ? SliverToBoxAdapter(
              child: SoriEmptyState(
                icon: Icons.search,
                title: t.wortpaketeNoResults,
              ),
            )
          : SliverList.builder(
              itemCount: found.length,
              itemBuilder: (context, index) {
                final p = found[index];
                final matched = p.words.where(
                  (w) =>
                      w.korean.contains(query) ||
                      w.translationFor(lang).toLowerCase().contains(query),
                );
                return ListTile(
                  key: ValueKey('wortpakete-search-${p.id}'),
                  leading: Text(
                    p.level,
                    style: _type(14, weight: FontWeight.w700),
                  ),
                  title: Text(VocabPackService.displayLabel(p.id, lang: lang)),
                  subtitle: Text(
                    matched.isEmpty
                        ? _examples(p)
                        : matched.take(2).map((w) => w.korean).join(' · '),
                    style: _type(14, korean: true),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    widget.onPack(p);
                  },
                );
              },
            ),
    );
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
      await _pickPack(t, topic, topic.packs.first);
    }
  }

  Future<void> _pickPack(AppL10n t, _PackTopic topic, VocabPack current) async {
    if (topic.packs.length == 1) {
      widget.onPack(current);
      return;
    }
    final pack = await _pick(
      title: _topicName(topic),
      items: topic.packs,
      label: (item) =>
          VocabPackService.displayLabel(item.id, lang: _lang(context)),
      subtitle: (item) {
        final progress = PackProgressService.get(item.id);
        final total = item.words.length;
        if (progress == null) {
          return t.wortpaketeWords(total);
        }
        final count = '${progress.wordsLearned.clamp(0, total)} / $total';
        return progress.isCleared ? '$count · ${t.packStateCleared}' : count;
      },
    );
    if (pack != null && mounted) {
      setState(() => _packId = pack.id);
      widget.onPack(pack);
    }
  }

  Future<T?> _pick<T>({
    required String title,
    required List<T> items,
    required String Function(T) label,
    required String Function(T) subtitle,
    Widget? header,
  }) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: _paper,
    sheetAnimationStyle: _reduced(context)
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
              child: CustomScrollView(
                slivers: [
                  if (header != null)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      sliver: SliverToBoxAdapter(child: header),
                    ),
                  SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        title: Text(label(item)),
                        subtitle: Text(subtitle(item)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(sheetContext).pop(item),
                      );
                    },
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
