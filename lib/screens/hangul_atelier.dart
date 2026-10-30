part of 'hangul_screen.dart';

// HTML approval: versions/20261010-approved-responsive-settings. Keep the full
// original PNGs, 4/8/12dp rhythm and source data owners. Latin faces follow
// the current locale tokens; Korean keeps its learning face.
Widget _atelierScreen(_HangulScreenState state, BuildContext context) {
  final t = AppL10n.of(context);
  final size = MediaQuery.sizeOf(context);
  final large = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
  final horizontal = size.width >= CAtelier.wideSurface
      ? 24.0
      : size.width < CAtelier.compactSurface
      ? 10.0
      : 14.0;
  final tabs = CAtelierTabs(
    key: state._tabBarKey,
    vertical: large,
    children: _atelierTabs(state, t),
  );
  final locked = StudyBodyInputLock.isLocked(state.context);
  final pages = ExcludeFocus(
    excluding: locked,
    child: AbsorbPointer(
      absorbing: locked,
      child: TabBarView(
        controller: state._tabs,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _AtelierOverview(
            speak: state._speakJamo,
            speakSyllable: state._speakSyllable,
          ),
          _CardsTab(
            key: state._cardsKey,
            active: state._enabled && !locked && state._tabIndex == 1,
            onFinish: state._finishCards,
            random: state.widget.cardsRandom ?? math.Random(),
            speak: state._speakJamo,
            prefetch: state._prefetch,
          ),
          _WriteTab(
            key: state._writingKey,
            active: state._enabled && !locked && state._tabIndex == 2,
            onFinish: state._finishWriting,
            speak: state._speakJamo,
          ),
        ],
      ),
    ),
  );
  return SoriStudyFrame(
    title: t.screenHangulTitle,
    cMaterial: true,
    leadingVisual: SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: Text(
          t.btnPrev,
          style: CAtelier.text(context, 12, color: CAtelier.paper),
        ),
      ),
    ),
    onLeave: state._pause,
    homeContent: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CAtelier.art('cloud', width: 20, height: 20),
        const SizedBox(width: CAtelierSpacing.relatedGap),
        Text(
          'HANGUL SORI',
          textScaler: TextScaler.noScaling,
          style: CAtelier.text(
            context,
            10,
            color: const Color(0xffe2c187),
          ).copyWith(letterSpacing: 2),
        ),
      ],
    ),
    child: const SizedBox.shrink(),
    surfaceBuilder: (close, home) {
      // Shared escape widgets must keep their existing route/leave owners.
      final chrome = Builder(
        builder: (_) => CAtelierSurface(
          key: const ValueKey('hangul-atelier-header'),
          face: CAtelierFace.jade,
          radius: 0,
          depth: false,
          framed: false,
          padding: EdgeInsets.fromLTRB(
            size.width >= CAtelier.wideSurface ? 24 : 16,
            math.max(12, MediaQuery.paddingOf(context).top),
            size.width >= CAtelier.wideSurface ? 24 : 16,
            12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  close,
                  home,
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CAtelierButton(
                      key: const Key('hangul-settings'),
                      label: t.settingsTitle,
                      face: CAtelierFace.jade,
                      depth: false,
                      bare: true,
                      onTap: () => unawaited(state._openSettings()),
                      child: CAtelier.art(
                        'settings-gear',
                        width: 32,
                        height: 32,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          namesRoute: true,
                          child: Text(
                            t.screenHangulTitle,
                            style: CAtelier.text(
                              context,
                              30,
                              bold: true,
                              color: CAtelier.paper,
                              height: 1.2,
                            ).copyWith(letterSpacing: -.6),
                          ),
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          t.atelierSubtitle,
                          style: CAtelier.text(
                            context,
                            12,
                            color: const Color(0xffd4ddce),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  SizedBox(
                    width: 48,
                    child: CAtelierButton(
                      key: const Key('hangul-tempo'),
                      label: t.ttsSpeedChip(
                        Storage.ttsSpeed.toStringAsFixed(
                          Storage.ttsSpeed % 1 == 0 ? 0 : 2,
                        ),
                      ),
                      fontSize: CAtelierType.controlLabel,
                      onTap: () => unawaited(state._openSettings(voice: true)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      final content = CAtelierPaper(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            8,
            horizontal,
            math.max(12, MediaQuery.paddingOf(context).bottom),
          ),
          child: large
              ? pages
              : Column(
                  children: [
                    tabs,
                    const SizedBox(height: Spacing.md),
                    Expanded(child: pages),
                  ],
                ),
        ),
      );
      return ColoredBox(
        color: CAtelier.deep,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: large
                ? NestedScrollView(
                    key: const Key('hangul-accessible-page-scroll'),
                    headerSliverBuilder: (_, _) => [
                      SliverToBoxAdapter(child: chrome),
                      SliverToBoxAdapter(
                        child: CAtelierPaper(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontal,
                              8,
                              horizontal,
                              12,
                            ),
                            child: tabs,
                          ),
                        ),
                      ),
                    ],
                    body: content,
                  )
                : Column(
                    children: [
                      chrome,
                      Expanded(child: content),
                    ],
                  ),
          ),
        ),
      );
    },
  );
}

List<Widget> _atelierTabs(_HangulScreenState state, AppL10n t) => [
  for (final item in [
    t.hangulTabOverview,
    t.hangulTabCards,
    t.hangulTabWrite,
  ].indexed)
    Padding(
      padding: EdgeInsets.only(right: item.$1 < 2 ? 4 : 0),
      child: CAtelierButton(
        key: ValueKey('hangul-tab-${item.$1}'),
        label: item.$2,
        fontSize: 14,
        bold: state._tabIndex == item.$1,
        bare: state._tabIndex != item.$1,
        face: state._tabIndex == item.$1
            ? CAtelierFace.gold
            : CAtelierFace.jade,
        selected: state._tabIndex == item.$1,
        depth: state._tabIndex == item.$1,
        onTap: () => state._tabs.animateTo(
          item.$1,
          duration: SoriMotion.reduceMotion(state.context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
        ),
      ),
    ),
];

Future<void> _atelierDialog(
  BuildContext context,
  String title,
  Widget Function(BuildContext) body,
) => showSoriDialog<void>(
  context: context,
  builder: (dialogContext) => Dialog(
    backgroundColor: CAtelier.paper,
    surfaceTintColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(Spacing.md),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: CAtelier.gold),
    ),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 390,
        maxHeight: MediaQuery.sizeOf(dialogContext).height * .85,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: CAtelier.text(context, 21, bold: true),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: CAtelierButton(
                      label: AppL10n.of(context).btnClose,
                      child: const Text('×', style: TextStyle(fontSize: 26)),
                      onTap: () => Navigator.pop(dialogContext),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              body(dialogContext),
            ],
          ),
        ),
      ),
    ),
  ),
);

class _AtelierOverview extends StatefulWidget {
  const _AtelierOverview({required this.speak, required this.speakSyllable});
  final Future<bool> Function(String) speak, speakSyllable;
  @override
  State<_AtelierOverview> createState() => _AtelierOverviewState();
}

class _AtelierOverviewState extends State<_AtelierOverview>
    with AutomaticKeepAliveClientMixin {
  int _c = 0, _v = 0, _group = 0;
  final _chartOrder = List<int>.generate(consonants.length, (i) => i)
    ..sort((a, b) => consonants[a].letter.compareTo(consonants[b].letter));
  final _rows = ScrollController();
  bool _playing = false;
  int _speechGeneration = 0;
  @override
  bool get wantKeepAlive => true;
  @override
  void dispose() {
    _rows.dispose();
    _speechGeneration++;
    super.dispose();
  }

  String get _syllable =>
      composeHangulSyllable(consonants[_c].letter, vowels[_v].letter, '')!;
  void _choose(int c, int v) {
    setState(() {
      _c = c;
      _v = v;
      _group = v ~/ 4;
    });
    unawaited(_listen());
  }

  Future<void> _listen() async {
    final generation = ++_speechGeneration;
    final result = widget.speakSyllable(_syllable);
    // The pulse follows the actual playback phase, not a synthetic duration.
    setState(() => _playing = true);
    await result;
    if (mounted && generation == _speechGeneration) {
      setState(() => _playing = false);
    }
  }

  Future<void> _catalog(int kind) async {
    final t = AppL10n.of(context);
    final chars = kind == 0
        ? consonants
        : kind == 1
        ? vowels
        : [for (final s in syllables) s.toHangulChar()];
    final title = [
      t.hangulChipConsonants,
      t.hangulChipVowels,
      t.hangulChipSyllables,
    ][kind];
    await _atelierDialog(
      context,
      '$title (${chars.length})',
      (dialogContext) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final entry in chars.indexed)
            SizedBox(
              width: 54,
              child: CAtelierButton(
                key: ValueKey('hangul-catalog-${entry.$2.letter}'),
                label: entry.$2.letter,
                child: Text(
                  entry.$2.letter,
                  style: CAtelier.text(context, 24, korean: true),
                ),
                onTap: () {
                  Navigator.pop(dialogContext);
                  unawaited(_detail(entry.$2, kind, entry.$1));
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _detail(HangulChar c, int kind, int index) async {
    if (!mounted) {
      return;
    }
    final t = AppL10n.of(context),
        lang = Localizations.localeOf(context).languageCode;
    await _atelierDialog(
      context,
      c.letter,
      (dialogContext) => Column(
        children: [
          Text(
            c.letter,
            style: CAtelier.text(
              context,
              60,
              bold: true,
              korean: true,
              color: CAtelier.jade,
            ),
          ),
          Text(c.romanization, style: CAtelier.text(context, 19)),
          const SizedBox(height: Spacing.xs),
          Text(c.descriptionFor(lang), style: CAtelier.text(context, 16)),
          if (c.exampleWord.isNotEmpty) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              c.exampleWord,
              style: CAtelier.text(context, 28, korean: true),
            ),
            Text(c.exampleFor(lang), style: CAtelier.text(context, 16)),
          ],
          const SizedBox(height: Spacing.md),
          CAtelierButton(
            label: t.cHangulListen,
            face: CAtelierFace.jade,
            onTap: () => unawaited(widget.speak(c.letter)),
          ),
          if (kind < 2) ...[
            const SizedBox(height: Spacing.sm),
            CAtelierButton(
              label: t.atelierUseInChart,
              onTap: () {
                Navigator.pop(dialogContext);
                _choose(kind == 0 ? index : _c, kind == 1 ? index : _v);
                if (_rows.hasClients) {
                  _rows.jumpTo(
                    math.min(
                      _rows.position.maxScrollExtent,
                      _chartOrder.indexOf(_c) * 52.0,
                    ),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = AppL10n.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final tablet = MediaQuery.sizeOf(context).width >= CAtelier.wideSurface;
        final large = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
        final visibleRows =
            ((constraints.maxHeight -
                        (large
                            ? 390
                            : tablet
                            ? 160
                            : 278)) /
                    52)
                .floor()
                .clamp(3, tablet ? 12 : 5);
        final indices = List.generate(
          math.min(4, vowels.length - _group * 4),
          (i) => _group * 4 + i,
        );
        final preview = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      t.atelierDiscover,
                      style: CAtelier.text(
                        context,
                        19,
                        bold: true,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
                Text(
                  '19 × 15',
                  style: CAtelier.text(context, 12, color: CAtelier.muted),
                ),
              ],
            ),
            const SizedBox(height: Spacing.xs),
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: LayoutBuilder(
                        builder: (context, box) => SizedBox(
                          height: box.maxWidth * 1024 / 1536 - 47,
                          child: OverflowBox(
                            maxHeight: box.maxWidth * 1024 / 1536,
                            alignment: Alignment.center,
                            child: AspectRatio(
                              aspectRatio: 1536 / 1024,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: CAtelier.art('composition-stage'),
                                  ),
                                  for (final entry in [
                                    (consonants[_c].letter, .196, .456, .12),
                                    (vowels[_v].letter, .463, .459, .12),
                                    (_syllable, .771, .425, .15),
                                  ])
                                    Positioned(
                                      left: box.maxWidth * entry.$2,
                                      top:
                                          box.maxWidth * 1024 / 1536 * entry.$3,
                                      child: FractionalTranslation(
                                        translation: const Offset(-.5, -.5),
                                        child: Text(
                                          entry.$1,
                                          textScaler: TextScaler.noScaling,
                                          style: CAtelier.text(
                                            context,
                                            (box.maxWidth * entry.$4).clamp(
                                              entry.$4 == .15 ? 36 : 30,
                                              entry.$4 == .15 ? 60 : 48,
                                            ),
                                            korean: true,
                                            bold: true,
                                            color: CAtelier.jade,
                                            height: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                SizedBox(
                  width: 72,
                  child: Column(
                    children: [
                      ValueListenableBuilder<TtsSpeechPhase>(
                        valueListenable: SoriSpeech.phase,
                        builder: (_, phase, _) => CAtelierSpeaker(
                          playing: _playing && phase == TtsSpeechPhase.speaking,
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      CAtelierButton(
                        label: t.cHangulListen,
                        face: CAtelierFace.jade,
                        fontSize: CAtelierType.controlLabel,
                        onTap: () => unawaited(_listen()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${consonants[_c].letter} + ${vowels[_v].letter} = $_syllable',
                    style: CAtelier.text(
                      context,
                      18,
                      bold: true,
                      korean: true,
                      color: CAtelier.jade,
                    ),
                  ),
                ),
                Text(
                  '${consonants[_c].letter} [${consonants[_c].romanization}] · ${vowels[_v].letter} [${vowels[_v].romanization}]',
                  style: CAtelier.text(context, 12, color: CAtelier.muted),
                ),
              ],
            ),
          ],
        );
        final matrix = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                for (var group = 0; group < 4; group++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: group > 0 ? 6 : 0),
                      child: CAtelierButton(
                        key: ValueKey('hangul-vowel-group-$group'),
                        label: vowels
                            .skip(group * 4)
                            .take(4)
                            .map((v) => v.letter)
                            .join(' '),
                        face: group == _group
                            ? CAtelierFace.jade
                            : CAtelierFace.paper,
                        selected: group == _group,
                        padding: const EdgeInsets.all(
                          CAtelierSpacing.inlayInset,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var line = 0; line < 2; line++)
                              Text(
                                vowels
                                    .skip(group * 4 + line * 2)
                                    .take(2)
                                    .map((v) => v.letter)
                                    .join(''),
                                textAlign: TextAlign.center,
                                textScaler: TextScaler.noScaling,
                                style: CAtelier.text(
                                  context,
                                  19,
                                  korean: true,
                                  height: 1.1,
                                  color: group == _group
                                      ? CAtelier.paper
                                      : CAtelier.ink,
                                ).copyWith(letterSpacing: 3),
                              ),
                          ],
                        ),
                        onTap: () => setState(() => _group = group),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: CAtelierSpacing.relatedGap),
            Text(t.atelierChartHint, style: CAtelier.text(context, 14)),
            const SizedBox(height: CAtelierSpacing.relatedGap),
            Row(
              children: [
                const SizedBox(width: Spacing.xxxl),
                for (final v in indices)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: Spacing.xs),
                      child: CAtelierButton(
                        label: vowels[v].letter,
                        face: v == _v ? CAtelierFace.jade : CAtelierFace.paper,
                        selected: v == _v,
                        child: Text(
                          vowels[v].letter,
                          style: CAtelier.text(
                            context,
                            23,
                            korean: true,
                            height: 1.1,
                            color: v == _v ? CAtelier.paper : CAtelier.ink,
                          ),
                        ),
                        onTap: () => _choose(_c, v),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Spacing.xs),
            SizedBox(
              height: visibleRows * 52.0 - 4,
              child: Scrollbar(
                controller: _rows,
                thumbVisibility: true,
                child: ListView.separated(
                  key: const Key('hangul-full-syllable-chart'),
                  controller: _rows,
                  itemCount: consonants.length,
                  padding: EdgeInsets.zero,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: Spacing.xs),
                  itemBuilder: (context, row) {
                    final c = _chartOrder[row];
                    return Row(
                      children: [
                        SizedBox(
                          width: 48,
                          child: CAtelierButton(
                            key: ValueKey(
                              'hangul-consonant-${consonants[c].letter}',
                            ),
                            label: consonants[c].letter,
                            face: c == _c
                                ? CAtelierFace.jade
                                : CAtelierFace.paper,
                            child: Text(
                              consonants[c].letter,
                              style: CAtelier.text(
                                context,
                                23,
                                korean: true,
                                height: 1.1,
                                color: c == _c ? CAtelier.paper : CAtelier.ink,
                              ),
                            ),
                            onTap: () => _choose(c, _v),
                          ),
                        ),
                        for (final v in indices)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: Spacing.xs),
                              child: CAtelierButton(
                                key: ValueKey(
                                  'hangul-syllable-${composeHangulSyllable(consonants[c].letter, vowels[v].letter, '')!}',
                                ),
                                label: composeHangulSyllable(
                                  consonants[c].letter,
                                  vowels[v].letter,
                                  '',
                                )!,
                                face: c == _c && v == _v
                                    ? CAtelierFace.jade
                                    : CAtelierFace.paper,
                                selected: c == _c && v == _v,
                                child: Text(
                                  composeHangulSyllable(
                                    consonants[c].letter,
                                    vowels[v].letter,
                                    '',
                                  )!,
                                  style: CAtelier.text(
                                    context,
                                    26,
                                    korean: true,
                                    height: 1.2,
                                    color: c == _c && v == _v
                                        ? CAtelier.paper
                                        : CAtelier.ink,
                                  ),
                                ),
                                onTap: () => _choose(c, v),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
            Row(
              children: [
                for (final label in [
                  '${t.hangulChipConsonants} · 19',
                  '${t.hangulChipVowels} · 15',
                  '${t.atelierStructure} · 16',
                ].indexed)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: label.$1 == 0 ? 0 : 8),
                      child: CAtelierButton(
                        label: label.$2,
                        fontSize: CAtelierType.controlLabel,
                        onTap: () => unawaited(_catalog(label.$1)),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
        return SingleChildScrollView(
          child: CAtelierColumns(
            visual: preview,
            controls: matrix,
            tablet: tablet,
            phoneGap: 6,
          ),
        );
      },
    );
  }
}

Widget _atelierCards(_CardsTabState state, BuildContext context) {
  final t = AppL10n.of(context),
      lang = Localizations.localeOf(context).languageCode;
  final pool = state._pool, c = pool[state._idx % pool.length];
  final liked = LikedContentService.isLiked(
    kind: LikedContentService.hangul,
    id: c.letter,
  );
  final generation = state._likeSourceGeneration;
  final large = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
  final tablet = MediaQuery.sizeOf(context).width >= CAtelier.wideSurface;
  final selected = [
    t.hangulChipConsonants,
    t.hangulChipVowels,
    t.hangulChipSyllables,
  ][state._mode];
  final visual = Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              t.atelierFlipHint,
              style: CAtelier.text(context, 14, color: CAtelier.muted),
            ),
          ),
          Text(
            '${state._idx % pool.length + 1} / ${pool.length}',
            style: CAtelier.text(context, 14),
          ),
        ],
      ),
      const SizedBox(height: CAtelierSpacing.baselineGap),
      Row(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final width = math.min(box.maxWidth, tablet ? 420.0 : 300.0);
                return Center(
                  child: SizedBox(
                    width: width,
                    height: width - 14,
                    child: OverflowBox(
                      maxHeight: width,
                      child: _AtelierCardGesture(
                        key: ValueKey('atelier-feed-${c.letter}'),
                        active: state.widget.active,
                        onNext: state._next,
                        onPrevious: state._prev,
                        onFlip: state._onFlip,
                        onLike: () => unawaited(
                          state._likeLetter(
                            c.letter,
                            generation,
                            addOnly: true,
                          ),
                        ),
                        liked: liked,
                        child: SizedBox.square(
                          dimension: width,
                          child: FlipCard(
                            key: ValueKey('hangul-card-${c.letter}'),
                            flipped: state._flipped,
                            duration: SoriMotion.reduceMotion(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 320),
                            front: _atelierCardFace(
                              context,
                              c,
                              width,
                              back: false,
                              large: large,
                            ),
                            back: _atelierCardFace(
                              context,
                              c,
                              width,
                              back: true,
                              large: large,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: Spacing.sm),
          SizedBox(
            width: 48,
            child: Column(
              children: [
                _atelierSocial(
                  context,
                  t.atelierRemember,
                  'social-heart',
                  () => unawaited(state._likeLetter(c.letter, generation)),
                  liked: liked,
                  key: const Key('hangul-card-like'),
                ),
                const SizedBox(height: Spacing.sm),
                _atelierSocial(
                  context,
                  t.atelierShare,
                  'social-share',
                  () => unawaited(state._shareCurrent()),
                ),
                const SizedBox(height: Spacing.sm),
                _atelierSocial(
                  context,
                  t.atelierMore,
                  'settings-gear',
                  () => unawaited(state._showCardModeSheet()),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );
  final controls = Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: CAtelierSpacing.relatedGap),
      Text(
        t.atelierFeedHint,
        style: CAtelier.text(context, 14, color: CAtelier.muted),
      ),
      const SizedBox(height: Spacing.sm),
      if (state._flipped) ...[
        if (large)
          Text('[${c.romanization}]', style: CAtelier.text(context, 19)),
        Text(c.descriptionFor(lang), style: CAtelier.text(context, 14)),
        if (c.exampleWord.isNotEmpty) ...[
          const SizedBox(height: Spacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  c.exampleFor(lang),
                  style: CAtelier.text(context, 16),
                ),
              ),
              SizedBox(
                width: 64,
                child: CAtelierButton(
                  label: t.cHangulListenWord,
                  onTap: () => unawaited(SoriSpeech.speak(c.exampleWord)),
                  child: const CAtelierSpeaker(width: 42, height: 38),
                ),
              ),
            ],
          ),
        ],
      ],
      const SizedBox(height: Spacing.md),
      Row(
        children: [
          for (final action in [
            (t.atelierNotYet, state._dontKnow),
            (t.atelierSkip, state._next),
            (t.atelierKnown, state._known),
          ].indexed)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: action.$1 == 0 ? 0 : 8),
                child: CAtelierButton(
                  label: action.$2.$1,
                  fontSize: CAtelierType.controlLabel,
                  onTap:
                      state.widget.active && (state._flipped || action.$1 == 1)
                      ? () {
                          if (state.mounted &&
                              state.widget.active &&
                              generation == state._likeSourceGeneration) {
                            action.$2.$2();
                          }
                        }
                      : null,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: Spacing.md),
      _atelierActionPair(
        CAtelierButton(
          label: t.cHangulListen,
          face: CAtelierFace.jade,
          onTap: state._speakCurrent,
        ),
        CAtelierButton(
          key: const Key('hangul-finish-cards'),
          label: t.atelierFinish,
          face: CAtelierFace.gold,
          onTap:
              state.widget.active &&
                  state._lifetime.isCurrent &&
                  state._sessionInteractions > 0
              ? () => unawaited(state._finish())
              : null,
        ),
      ),
    ],
  );
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: CAtelierButton(
                key: const Key('hangul-cards-selection'),
                label: '$selected · ${pool.length}',
                fontSize: 13,
                onTap: () => unawaited(state._showCardModeSheet()),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            SizedBox(
              width: 102,
              child: CAtelierButton(
                key: const Key('hangul-cards-filter'),
                label: '${t.atelierDifficult} · ${state._hardPool.length}',
                selected: state._hardOnly && state._hardPool.isNotEmpty,
                onTap: () => unawaited(state._showCardModeSheet()),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        CAtelierColumns(visual: visual, controls: controls, tablet: tablet),
      ],
    ),
  );
}

Widget _atelierCardFace(
  BuildContext context,
  HangulChar c,
  double width, {
  required bool back,
  required bool large,
}) => SizedBox.square(
  dimension: width,
  child: Stack(
    children: [
      Positioned.fill(child: CAtelier.art('letter-tile')),
      if (!back)
        Positioned(
          left: width * .475,
          top: width * .47,
          child: FractionalTranslation(
            translation: const Offset(-.5, -.5),
            child: Text(
              c.letter,
              textScaler: TextScaler.noScaling,
              style:
                  CAtelier.text(
                    context,
                    (width * .28).clamp(84, 126),
                    bold: true,
                    korean: true,
                    color: CAtelier.jade,
                    height: 1,
                  ).copyWith(
                    shadows: const [
                      Shadow(color: Color(0x60ffffff), offset: Offset(0, -1)),
                      Shadow(
                        color: Color(0x45143328),
                        offset: Offset(0, 2),
                        blurRadius: 1,
                      ),
                    ],
                  ),
            ),
          ),
        )
      else
        Positioned(
          left: width * .20,
          right: width * .25,
          top: width * .19,
          bottom: width * .17,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                c.letter,
                textScaler: TextScaler.noScaling,
                style: CAtelier.text(
                  context,
                  42,
                  korean: true,
                  bold: true,
                  color: CAtelier.jade,
                  height: 1.1,
                ),
              ),
              if (!large) ...[
                const SizedBox(height: CAtelierSpacing.relatedGap),
                Text('[${c.romanization}]', style: CAtelier.text(context, 19)),
              ],
              if (c.exampleWord.isNotEmpty) ...[
                const SizedBox(height: CAtelierSpacing.relatedGap),
                Text(
                  c.exampleWord,
                  textScaler: TextScaler.noScaling,
                  textAlign: TextAlign.center,
                  style: CAtelier.text(
                    context,
                    32,
                    korean: true,
                    color: CAtelier.jade,
                    height: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
    ],
  ),
);

Widget _atelierSocial(
  BuildContext context,
  String label,
  String image,
  VoidCallback onTap, {
  bool liked = false,
  Key? key,
}) => CAtelierTouch(
  key: key,
  onTap: onTap,
  child: Semantics(
    button: true,
    label: label,
    selected: liked,
    onTap: onTap,
    child: ExcludeSemantics(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 64),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                children: [
                  if (image == 'settings-gear')
                    SizedBox.square(
                      dimension: 44,
                      child: Center(
                        child: Text(
                          '⋯',
                          style: CAtelier.text(
                            context,
                            28,
                            bold: true,
                            korean: true,
                          ),
                        ),
                      ),
                    )
                  else
                    CAtelier.art(image, width: 44, height: 44),
                  Text(
                    label,
                    style: CAtelier.text(context, 12, height: 1.2),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              if (liked)
                const Positioned(
                  top: 3,
                  right: 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: CAtelier.gold,
                    ),
                    child: SizedBox.square(dimension: 6),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  ),
);

Widget _atelierActionPair(Widget first, Widget second) => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(flex: 10, child: first),
    const SizedBox(width: Spacing.sm),
    Expanded(flex: 16, child: second),
  ],
);

/// Vertical browsing is separate from self-assessment. Tap and double tap are
/// one recognizer, so a double tap never flips or counts a second interaction.
class _AtelierCardGesture extends StatefulWidget {
  const _AtelierCardGesture({
    super.key,
    required this.child,
    required this.active,
    required this.onNext,
    required this.onPrevious,
    required this.onFlip,
    required this.onLike,
    required this.liked,
  });
  final Widget child;
  final bool active, liked;
  final VoidCallback onNext, onPrevious, onFlip, onLike;
  @override
  State<_AtelierCardGesture> createState() => _AtelierCardGestureState();
}

class _AtelierCardGestureState extends State<_AtelierCardGesture> {
  double _drag = 0;
  bool _focused = false;
  bool _burst = false;
  Timer? _timer;
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _AtelierCardGesture old) {
    super.didUpdateWidget(old);
    if (!widget.active) {
      _timer?.cancel();
      _drag = 0;
      _burst = false;
    }
  }

  void _like() {
    widget.onLike();
    if (SoriMotion.reduceMotion(context)) {
      return;
    }
    setState(() => _burst = true);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 420), () {
      if (mounted) {
        setState(() => _burst = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.arrowDown): () {
        if (widget.active) {
          widget.onNext();
        }
      },
      const SingleActivator(LogicalKeyboardKey.arrowUp): () {
        if (widget.active) {
          widget.onPrevious();
        }
      },
      const SingleActivator(LogicalKeyboardKey.enter): () {
        if (widget.active) {
          widget.onFlip();
        }
      },
      const SingleActivator(LogicalKeyboardKey.space): () {
        if (widget.active) {
          widget.onFlip();
        }
      },
    },
    child: FocusableActionDetector(
      enabled: widget.active,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      child: Semantics(
        button: true,
        label: AppL10n.of(context).atelierFlipHint,
        onTap: widget.active ? widget.onFlip : null,
        customSemanticsActions: {
          CustomSemanticsAction(label: AppL10n.of(context).btnNext):
              widget.onNext,
          CustomSemanticsAction(label: AppL10n.of(context).btnPrev):
              widget.onPrevious,
          CustomSemanticsAction(label: AppL10n.of(context).atelierRemember):
              widget.onLike,
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.active ? widget.onFlip : null,
          onDoubleTap: widget.active ? _like : null,
          onVerticalDragUpdate: widget.active
              ? (d) => setState(() => _drag += d.delta.dy)
              : null,
          onVerticalDragEnd: widget.active
              ? (d) {
                  if (_drag.abs() >= 64 || d.primaryVelocity!.abs() >= 850) {
                    (_drag < 0 || d.primaryVelocity! < -850
                        ? widget.onNext
                        : widget.onPrevious)();
                  }
                  setState(() => _drag = 0);
                }
              : null,
          onVerticalDragCancel: () => setState(() => _drag = 0),
          child: AnimatedContainer(
            duration: SoriMotion.reduceMotion(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            transformAlignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, .0012)
              ..translateByDouble(0, _drag * .24, 0, 1)
              ..rotateX(
                SoriMotion.reduceMotion(context)
                    ? 0
                    : (_drag * -.0005).clamp(-.06, .06),
              ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                widget.child,
                if (_focused)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: CAtelier.gold, width: 2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                if (_burst)
                  IgnorePointer(
                    child: CAtelier.art('social-heart', width: 88, height: 88),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _atelierWriting(_WriteTabState state, BuildContext context) {
  final t = AppL10n.of(context);
  final tablet = MediaQuery.sizeOf(context).width >= CAtelier.wideSurface;
  final large = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
  final index = state._mode == 0 ? state._idx : consonants.length + state._idx;
  final width = tablet && !large
      ? math.min(
          420.0,
          math.max(288.0, (MediaQuery.sizeOf(context).height - 268) * .75),
        )
      : 288.0;
  final desk = TickerMode(
    enabled: state.widget.active && !state._toolsOpen,
    child: Center(
      child: SizedBox(
        width: width,
        child: AspectRatio(
          aspectRatio: 1122 / 1402,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: CAtelier.art('ink-desk')),
              Positioned(
                left: width * .16,
                top: width * 1402 / 1122 * .305,
                width: width * .69,
                height: width * 1402 / 1122 * .49,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned.fill(
                      child: CustomPaint(painter: _AtelierWritingGrid()),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          key: const Key('hangul-writing-guide'),
                          painter: _AtelierPracticeGuide(
                            state._targetStrokes,
                            state._demonstrating
                                ? state._demoStep
                                : state._acceptedStrokes,
                            !state._letterDone,
                            CAtelier.text(context, 11, bold: true),
                          ),
                        ),
                      ),
                    ),
                    if (state._demonstrating)
                      Positioned.fill(
                        child: _AtelierDemonstration(
                          key: ValueKey(
                            'atelier-demo-${state._current.letter}-${state._demoGeneration}',
                          ),
                          strokes: state._targetStrokes,
                          staticStep: state._demoStep,
                          active: state.widget.active && !state._toolsOpen,
                          onComplete: state._demoComplete,
                        ),
                      )
                    else
                      Positioned.fill(
                        child: TraceCanvas(
                          controller: state._practiceController,
                          ghost: state._current.letter,
                          color: CAtelier.jade,
                          errorColor: const Color(0xff855232),
                          enabled:
                              state.widget.active &&
                              !state._toolsOpen &&
                              !state._letterDone,
                          calligraphy: true,
                          canonicalCoordinates: true,
                          brushScale: 2.8,
                          brushAngle: .8,
                          parkedBrush: !state._letterDone
                              ? _atelierPoints(
                                  state._targetStrokes[state._acceptedStrokes],
                                ).first
                              : null,
                          onStrokeEnd: state._onStrokeEnd,
                          semanticLabel: t.hangulTraceTitle,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  final caption = Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        state._current.letter,
        style: CAtelier.text(
          context,
          22,
          bold: true,
          korean: true,
          color: CAtelier.jade,
        ),
      ),
      const SizedBox(width: CAtelierSpacing.relatedGap),
      Flexible(
        child: Text(
          state._demonstrating ? t.atelierWatchBrush : state._hintText(t),
          style: CAtelier.text(context, 13, color: state._hintColor()),
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );
  final controls = Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (tablet && !large) ...[caption, const SizedBox(height: Spacing.md)],
      _atelierActionPair(
        CAtelierButton(
          key: const Key('hangul-demonstrate'),
          label: state._demonstrating
              ? SoriMotion.reduceMotion(context)
                    ? state._demoStep < state._targetStrokes.length - 1
                          ? t.atelierDemoNext
                          : t.atelierDemoEnd
                    : t.atelierDemoRestart
              : t.atelierDemo,
          fontSize: 14,
          onTap: state._demonstrateAction,
        ),
        CAtelierButton(
          key: const Key('hangul-auto-advance'),
          label: state._auto ? t.atelierAutoOn : t.atelierAutoOff,
          face: state._auto ? CAtelierFace.gold : CAtelierFace.paper,
          selected: state._auto,
          onTap: state._toggleAuto,
        ),
      ),
      const SizedBox(height: Spacing.sm),
      Row(
        children: [
          SizedBox(
            width: 48,
            child: CAtelierButton(
              label: t.btnPrev,
              onTap: state._mode == 0 && state._idx == 0 ? null : state._prev,
              child: const Text('‹', style: TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: Spacing.xs),
          Expanded(
            child: CAtelierButton(
              key: const Key('hangul-writing-selection'),
              label: '${state._current.letter} ▾',
              child: Row(
                children: [
                  Text(
                    state._current.letter,
                    style: CAtelier.text(context, 14, korean: true),
                  ),
                  const SizedBox(width: Spacing.xs),
                  Expanded(
                    child: Text(
                      '· ${state._current.romanization}',
                      style: CAtelier.text(context, 14),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: CAtelier.ink,
                  ),
                ],
              ),
              onTap: () => unawaited(state._showLetters()),
            ),
          ),
          const SizedBox(width: Spacing.xs),
          SizedBox(
            width: 48,
            child: CAtelierButton(
              label: t.btnNext,
              onTap: state._mode == 1 && state._idx == vowels.length - 1
                  ? null
                  : state._next,
              child: const Text('›', style: TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: Spacing.xs),
          SizedBox(
            width: 48,
            child: CAtelierButton(
              label: t.hangulClearBtn,
              onTap: state._clearPractice,
              child: const Icon(
                Icons.delete_outline,
                color: Color(0xff8a5b3c),
                size: 23,
              ),
            ),
          ),
          const SizedBox(width: Spacing.xs),
          SizedBox(
            width: 48,
            child: CAtelierButton(
              label: t.atelierMore,
              child: const Text('⋯', style: TextStyle(fontSize: 24)),
              onTap: () => unawaited(state._showWriteSettings()),
            ),
          ),
        ],
      ),
      const SizedBox(height: Spacing.sm),
      _atelierActionPair(
        CAtelierButton(
          label: t.cHangulListen,
          face: CAtelierFace.jade,
          onTap: state._speakCurrent,
        ),
        CAtelierButton(
          key: const Key('hangul-finish-writing'),
          label: t.atelierFinish,
          face: CAtelierFace.gold,
          onTap:
              !state.widget.active ||
                  !state._lifetime.isCurrent ||
                  state._completedLetters == 0
              ? null
              : () => unawaited(state._finish()),
        ),
      ),
    ],
  );
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                state._demonstrating
                    ? t.atelierDemoPhase
                    : state._letterDone
                    ? t.atelierDonePhase
                    : t.atelierPracticePhase,
                style: CAtelier.text(context, 12, color: state._hintColor()),
              ),
            ),
            Text(
              t.hangulStrokeProgress(
                state._acceptedStrokes,
                state._targetStrokes.length,
              ),
              style: CAtelier.text(context, 12),
            ),
            const SizedBox(width: Spacing.md),
            Text('${index + 1} / 34', style: CAtelier.text(context, 12)),
          ],
        ),
        const SizedBox(height: Spacing.xs),
        CAtelierColumns(
          visual: Column(
            children: [
              SizedBox(
                height: width * 1402 / 1122 - 14,
                child: OverflowBox(
                  alignment: Alignment.bottomCenter,
                  maxHeight: width * 1402 / 1122,
                  child: desk,
                ),
              ),
              if (!tablet || large) ...[
                const SizedBox(height: Spacing.xs),
                caption,
                const SizedBox(height: Spacing.sm),
              ],
            ],
          ),
          controls: controls,
          tablet: tablet,
          phoneGap: 0,
        ),
      ],
    ),
  );
}

class _AtelierWritingGrid extends CustomPainter {
  const _AtelierWritingGrid();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x18385748)
      ..strokeWidth = .7;
    for (var d = 0.0; d < size.width; d += 6) {
      canvas.drawLine(
        Offset(d, size.height / 2),
        Offset(d + 2, size.height / 2),
        p,
      );
    }
    for (var d = 0.0; d < size.height; d += 6) {
      canvas.drawLine(
        Offset(size.width / 2, d),
        Offset(size.width / 2, d + 2),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

List<Offset> _atelierPoints(Stroke stroke) {
  if (stroke case CircleStroke(:final center, :final radius)) {
    return List.generate(
      73,
      (i) =>
          center +
          Offset(
                math.cos(-math.pi / 2 + math.pi * 2 * i / 72),
                math.sin(-math.pi / 2 + math.pi * 2 * i / 72),
              ) *
              radius,
    );
  }
  final points = (stroke as LineStroke).points;
  return [
    points.first,
    for (var i = 1; i < points.length; i++)
      for (var j = 1; j <= 24; j++)
        Offset.lerp(points[i - 1], points[i], j / 24)!,
  ];
}

class _AtelierPracticeGuide extends CustomPainter {
  const _AtelierPracticeGuide(
    this.strokes,
    this.next,
    this.showMarker,
    this.labelStyle,
  );
  final List<Stroke> strokes;
  final int next;
  final bool showMarker;
  final TextStyle labelStyle;
  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    canvas.save();
    canvas.translate((size.width - side) / 2, (size.height - side) / 2);
    canvas.scale(side / 220);
    for (final (index, stroke) in strokes.indexed) {
      final points = _atelierPoints(stroke);
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 8
          ..color = CAtelier.jade.withValues(alpha: index == next ? .20 : .085),
      );
    }
    if (showMarker && next < strokes.length) {
      final start = _atelierPoints(strokes[next]).first;
      canvas.drawCircle(start, 9, Paint()..color = CAtelier.gold);
      final label = TextPainter(
        text: TextSpan(text: '${next + 1}', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, start - Offset(label.width / 2, label.height / 2));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AtelierPracticeGuide old) =>
      old.labelStyle != labelStyle ||
      old.strokes != strokes ||
      old.next != next ||
      old.showMarker != showMarker;
}

/// A finite native brush demonstration uses the same pressure/mesh renderer as
/// real input, but never invokes the matcher, attempt counter or reward owner.
class _AtelierDemonstration extends StatefulWidget {
  const _AtelierDemonstration({
    super.key,
    required this.strokes,
    required this.active,
    required this.onComplete,
    required this.staticStep,
  });
  final List<Stroke> strokes;
  final bool active;
  final int staticStep;
  final VoidCallback onComplete;
  @override
  State<_AtelierDemonstration> createState() => _AtelierDemonstrationState();
}

class _AtelierDemonstrationState extends State<_AtelierDemonstration>
    with SingleTickerProviderStateMixin {
  late final List<List<Offset>> _paths = widget.strokes
      .map(_atelierPoints)
      .toList();
  final _ink = <CInkStroke>[];
  int _revision = 0;
  late final AnimationController _clock =
      AnimationController(
          vsync: this,
          duration: Duration(
            milliseconds: _paths.fold<int>(
              0,
              (sum, points) => sum + 400 + points.length * 18,
            ),
          ),
        )
        ..addListener(_sample)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            widget.onComplete();
          }
        });
  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _AtelierDemonstration old) {
    super.didUpdateWidget(old);
    if (SoriMotion.reduceMotion(context)) {
      _clock.stop();
      _staticSample();
    } else if (widget.active) {
      _clock.forward();
    } else {
      _clock.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (SoriMotion.reduceMotion(context)) {
      _clock.stop();
      _staticSample();
    } else if (widget.active) {
      _clock.forward();
    }
  }

  void _staticSample() {
    _ink.clear();
    for (final path in _paths.take(widget.staticStep + 1)) {
      final stroke = CInkStroke(
        CInkPoint(path.first, Duration.zero, .38),
        stylus: false,
      );
      for (final (i, point) in path.skip(1).indexed) {
        stroke.add(CInkPoint(point, Duration(milliseconds: (i + 1) * 18), .42));
      }
      stroke.finish();
      _ink.add(stroke);
    }
    _revision++;
  }

  void _sample() {
    var time = (_clock.value * _clock.duration!.inMilliseconds).round();
    for (var i = 0; i < _paths.length; i++) {
      final path = _paths[i], span = 400 + path.length * 18;
      if (time < 140) {
        break;
      }
      final count = ((time - 140) / 18).floor().clamp(1, path.length);
      if (_ink.length <= i) {
        _ink.add(
          CInkStroke(CInkPoint(path.first, Duration.zero, .38), stylus: false),
        );
      }
      final stroke = _ink[i];
      for (var j = stroke.points.length; j < count; j++) {
        stroke.add(CInkPoint(path[j], Duration(milliseconds: j * 18), .42));
      }
      if (count == path.length) {
        stroke.finish();
      }
      time -= span;
      if (time < 0) {
        break;
      }
    }
    setState(() => _revision++);
  }

  @override
  Widget build(BuildContext context) => CCalligraphyCanvas(
    strokes: _ink,
    revision: _revision,
    canonicalCoordinates: true,
    brushOverflow: true,
    brushScale: 2.8,
    brushAngle: .8,
    parkedBrush: _ink.isEmpty ? _paths.first.first : null,
  );
  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }
}
