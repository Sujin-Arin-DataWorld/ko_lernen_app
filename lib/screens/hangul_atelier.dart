part of 'hangul_screen.dart';

/// Hangul atelier layout rules approved with the 2026-11-21 mockup: one
/// control height, two button materials (jade primary, flat hanji secondary)
/// and 17/600 labels. Fixed rows keep their height and the artwork area
/// (paper, card, chart) takes what is left, so every state fits one screen.
abstract final class _AtelierUi {
  static const control = CAtelierType.actionHeight;
  static const gap = Spacing.sm;

  /// Control labels follow system text up to this factor; page text beyond
  /// the fixed rows keeps scaling freely.
  static const maxControlScale = 1.3;

  /// Below this height the paper needs the bottom bar's 76dp back.
  static const navMinHeight = 600.0;

  /// From this width the shell's destinations use a side rail.
  static const railMinWidth = 600.0;

  /// Design baseline: iPhone 16 Pro, 402×874pt (Jin, 2026-11-21).
  static const baselineShortSide = 402.0;

  /// Controls and labels follow the phone's short side relative to the
  /// baseline, within 0.9–1.12, so a 360pt Android and a 440pt Pro Max keep
  /// the same proportions as the approved iPhone 16 Pro layout.
  static double scale(BuildContext context) =>
      (MediaQuery.sizeOf(context).shortestSide / baselineShortSide).clamp(
        .9,
        1.12,
      );

  /// Never below the 48dp Material / 44pt Apple touch target.
  static double controlOf(BuildContext context) =>
      math.max(48, control * scale(context));

  static double labelOf(BuildContext context) =>
      CAtelierType.actionLabel * scale(context);
}

/// Portrait phones tall enough to keep the paper show the image tab bar.
bool _atelierBottomNav(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.width < _AtelierUi.railMinWidth &&
      size.height >= _AtelierUi.navMinHeight;
}

/// Landscape phones move the destinations to a side rail.
bool _atelierSideRail(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.width >= _AtelierUi.railMinWidth &&
      size.height < _AtelierUi.navMinHeight;
}

/// One action button of the approved system. [label] is the accessible name
/// and the visible text; pass an empty [text] for an icon-only square.
Widget _atelierAction(
  BuildContext context, {
  Key? key,
  required String label,
  String? text,
  String? semanticLabel,
  IconData? icon,
  Widget? leading,
  VoidCallback? onTap,
  bool primary = false,
  bool? selected,
  double? height,
}) {
  final enabled = onTap != null;
  final color = !enabled
      ? CAtelier.quietDisabledInk
      : primary
      ? CAtelier.paper
      : CAtelier.ink;
  final visible = text ?? label;
  return SizedBox(
    height: height ?? _AtelierUi.controlOf(context),
    child: CAtelierButton(
      key: key,
      label: label,
      semanticLabel: semanticLabel,
      onTap: onTap,
      selected: selected,
      face: primary ? CAtelierFace.jade : CAtelierFace.quiet,
      framed: !primary,
      radius: CAtelierType.actionRadius,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: _AtelierUi.maxControlScale,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ?leading,
              if (leading == null && icon != null)
                Icon(icon, size: 22, color: color),
              if ((leading != null || icon != null) && visible.isNotEmpty)
                const SizedBox(width: CAtelierSpacing.relatedGap),
              if (visible.isNotEmpty)
                Text(
                  visible,
                  style: CAtelier.text(
                    context,
                    _AtelierUi.labelOf(context),
                    bold: true,
                    color: color,
                    height: 1.15,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

// HTML approval: versions/20261010-approved-responsive-settings, revised by
// the 2026-11-21 mockup. Keep the original PNGs and source data owners. Latin
// faces follow the current locale tokens; Korean keeps its learning face.
Widget _atelierScreen(_HangulScreenState state, BuildContext context) {
  final t = AppL10n.of(context);
  final size = MediaQuery.sizeOf(context);
  final bottomNav = _atelierBottomNav(context);
  final sideRail = _atelierSideRail(context);
  final horizontal = size.width >= CAtelier.wideSurface
      ? 24.0
      : size.width < CAtelier.compactSurface
      ? 12.0
      : 16.0;
  final tabs = CAtelierTabs(
    key: state._tabBarKey,
    children: _atelierTabs(state, context, t),
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
    leadingVisual: const SizedBox.square(
      dimension: 48,
      child: Center(
        child: Icon(Icons.chevron_left_rounded, color: CAtelier.paper),
      ),
    ),
    onLeave: state._pause,
    bottomNavigationBar: bottomNav
        ? SoriLearningStageNavigation(
            learningStyle: SoriLearningNavStyle.folio,
            onLeave: state._pause,
          )
        : null,
    homeContent: SizedBox.square(
      dimension: 48,
      child: Center(child: CAtelier.art('cloud', width: 22, height: 22)),
    ),
    child: const SizedBox.shrink(),
    surfaceBuilder: (close, home) {
      // Shared escape widgets must keep their existing route/leave owners.
      final title = Semantics(
        header: true,
        namesRoute: true,
        child: Text(
          t.screenHangulTitle,
          style: CAtelier.text(
            context,
            sideRail ? 22 : 26,
            bold: true,
            color: CAtelier.paper,
            height: 1.2,
          ).copyWith(letterSpacing: -.4),
        ),
      );
      final settings = SizedBox.square(
        dimension: 48,
        child: CAtelierButton(
          key: const Key('hangul-settings'),
          label: t.settingsTitle,
          face: CAtelierFace.jade,
          depth: false,
          bare: true,
          onTap: () => unawaited(state._openSettings()),
          child: CAtelier.art('settings-gear', width: 32, height: 32),
        ),
      );
      final speedLabel = t.ttsSpeedChip(
        Storage.ttsSpeed.toStringAsFixed(Storage.ttsSpeed % 1 == 0 ? 0 : 2),
      );
      final tempo = SizedBox(
        height: 48,
        child: CAtelierButton(
          key: const Key('hangul-tempo'),
          label: speedLabel,
          face: CAtelierFace.jade,
          depth: false,
          radius: 24,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          onTap: () => unawaited(state._openSettings(voice: true)),
          child: Text(
            speedLabel,
            style: CAtelier.text(
              context,
              _AtelierUi.labelOf(context),
              bold: true,
              color: CAtelier.paper,
              height: 1,
            ),
          ),
        ),
      );
      final chrome = CAtelierSurface(
        key: const ValueKey('hangul-atelier-header'),
        face: CAtelierFace.jade,
        radius: 0,
        depth: false,
        framed: false,
        padding: EdgeInsets.fromLTRB(
          Spacing.xs,
          MediaQuery.paddingOf(context).top + Spacing.xs,
          Spacing.sm,
          Spacing.xs,
        ),
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: _AtelierUi.maxControlScale,
          child: Row(
            children: [
              close,
              Expanded(child: title),
              tempo,
              const SizedBox(width: Spacing.xs),
              home,
              settings,
            ],
          ),
        ),
      );
      final content = CAtelierPaper(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            Spacing.md,
            horizontal,
            bottomNav
                ? Spacing.md
                : Spacing.lg + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            children: [
              tabs,
              const SizedBox(height: Spacing.sm),
              Expanded(child: pages),
            ],
          ),
        ),
      );
      final body = Column(
        children: [
          chrome,
          Expanded(child: content),
        ],
      );
      return ColoredBox(
        color: CAtelier.deep,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: SafeArea(
              top: false,
              bottom: false,
              child: sideRail
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: body),
                        SoriLearningStageNavigation(
                          learningStyle: SoriLearningNavStyle.folio,
                          onLeave: state._pause,
                          rail: true,
                        ),
                      ],
                    )
                  : body,
            ),
          ),
        ),
      );
    },
  );
}

List<Widget> _atelierTabs(
  _HangulScreenState state,
  BuildContext context,
  AppL10n t,
) => [
  for (final (index, label) in [
    t.hangulTabOverview,
    t.hangulTabCards,
    t.hangulTabWrite,
  ].indexed)
    Padding(
      padding: EdgeInsets.only(right: index < 2 ? Spacing.xs : 0),
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: CAtelierButton(
          key: ValueKey('hangul-tab-$index'),
          label: label,
          bold: true,
          bare: state._tabIndex != index,
          face: state._tabIndex == index
              ? CAtelierFace.gold
              : CAtelierFace.jade,
          selected: state._tabIndex == index,
          depth: state._tabIndex == index,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: _AtelierUi.maxControlScale,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    const [
                      Icons.grid_view_rounded,
                      Icons.style_outlined,
                      Icons.brush_outlined,
                    ][index],
                    size: 20,
                    color: state._tabIndex == index
                        ? CAtelier.ink
                        : CAtelier.paper,
                  ),
                  const SizedBox(width: CAtelierSpacing.relatedGap),
                  Text(
                    label,
                    style: CAtelier.text(
                      context,
                      _AtelierUi.labelOf(context),
                      bold: true,
                      color: state._tabIndex == index
                          ? CAtelier.ink
                          : CAtelier.paper,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          onTap: () => state._tabs.animateTo(
            index,
            duration: SoriMotion.reduceMotion(state.context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
          ),
        ),
      ),
    ),
];

Future<void> _atelierDialog(
  BuildContext context,
  String title,
  List<Widget> Function(BuildContext, BoxConstraints) sections,
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
    child: SizedBox(
      width: 390,
      height: MediaQuery.sizeOf(dialogContext).height * .82,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: CAtelier.text(dialogContext, 21, bold: true),
                    ),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: CAtelierButton(
                    label: AppL10n.of(dialogContext).btnClose,
                    child: const Icon(Icons.close_rounded),
                    onTap: () => Navigator.pop(dialogContext),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) =>
                    SoriViewportPages(sections: sections(context, box)),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);

double _atelierBodySize(BuildContext context) =>
    Theme.of(context).platform == TargetPlatform.iOS ? 17 : 16;

List<Widget> _atelierTextSections(
  BuildContext context,
  BoxConstraints box,
  String copy, {
  Key? firstSectionKey,
}) {
  final style = CAtelier.text(context, _atelierBodySize(context));
  final pages = soriViewportTextPages(
    context,
    copy,
    style: style,
    width: box.maxWidth,
    height: box.maxHeight - SoriViewportPages.controlsHeight - Spacing.xs * 2,
  );
  return [
    for (final (index, page) in pages.indexed)
      Padding(
        key: index == 0 ? firstSectionKey : null,
        padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
        child: Text(page, style: style),
      ),
  ];
}

List<Widget> _atelierGridRows(
  BoxConstraints box,
  List<Widget> tiles, {
  double tileWidth = 54,
}) {
  const gap = Spacing.sm;
  final columns = math.max(1, (box.maxWidth + gap) ~/ (tileWidth + gap));
  return [
    for (var start = 0; start < tiles.length; start += columns)
      Padding(
        padding: const EdgeInsets.only(bottom: gap),
        child: Wrap(
          spacing: gap,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final tile in tiles.skip(start).take(columns))
              SizedBox(width: tileWidth, child: tile),
          ],
        ),
      ),
  ];
}

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
  int _chartRow = 0;
  double _chartDrag = 0;
  bool _playing = false;
  int _speechGeneration = 0;
  @override
  bool get wantKeepAlive => true;
  @override
  void dispose() {
    _speechGeneration++;
    super.dispose();
  }

  String get _syllable =>
      composeHangulSyllable(consonants[_c].letter, vowels[_v].letter, '')!;
  void _choose(int c, int v, {bool revealConsonant = false}) {
    setState(() {
      _c = c;
      _v = v;
      _group = v ~/ 4;
      if (revealConsonant) {
        _chartRow = _chartOrder.indexOf(c);
      }
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
      (dialogContext, box) => _atelierGridRows(box, [
        for (final entry in chars.indexed)
          CAtelierButton(
            key: ValueKey('hangul-catalog-${entry.$2.letter}'),
            label: entry.$2.letter,
            child: Text(
              entry.$2.letter,
              textScaler: TextScaler.noScaling,
              style: CAtelier.text(context, 24, korean: true),
            ),
            onTap: () {
              Navigator.pop(dialogContext);
              unawaited(_detail(entry.$2, kind, entry.$1));
            },
          ),
      ]),
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
      (dialogContext, box) => [
        Text(
          c.letter,
          textScaler: TextScaler.noScaling,
          textAlign: TextAlign.center,
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
        ..._atelierTextSections(dialogContext, box, c.descriptionFor(lang)),
        if (c.exampleWord.isNotEmpty) ...[
          const SizedBox(height: Spacing.sm),
          Text(c.exampleWord, style: CAtelier.text(context, 28, korean: true)),
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
              _choose(
                kind == 0 ? index : _c,
                kind == 1 ? index : _v,
                revealConsonant: true,
              );
            },
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = AppL10n.of(context);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: _AtelierUi.maxControlScale,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tablet =
              constraints.maxWidth >= SoriBreakpoints.hangulAtelierTablet;
          // Height budgets from the 2026-11-21 mockup: the full stage needs
          // 470dp, the one-row preview 330dp; below that the sections page.
          final full = tablet || constraints.maxHeight >= 470;
          final paged = !tablet && constraints.maxHeight < 330;
          final indices = List.generate(
            math.min(4, vowels.length - _group * 4),
            (i) => _group * 4 + i,
          );
          final header = Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    t.atelierDiscover,
                    style: CAtelier.text(context, 19, bold: true, height: 1.3),
                  ),
                ),
              ),
              Text(
                '19 × 15',
                style: CAtelier.text(context, 15, color: CAtelier.muted),
              ),
            ],
          );
          Widget stage(double maxHeight) => LayoutBuilder(
            builder: (context, box) {
              final width = math.min(box.maxWidth, maxHeight * 1536 / 1024);
              final height = width * 1024 / 1536;
              return Center(
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Stack(
                    children: [
                      Positioned.fill(child: CAtelier.art('composition-stage')),
                      for (final entry in [
                        (consonants[_c].letter, .196, .456, .12),
                        (vowels[_v].letter, .463, .459, .12),
                        (_syllable, .771, .425, .15),
                      ])
                        Positioned(
                          left: width * entry.$2,
                          top: height * entry.$3,
                          child: FractionalTranslation(
                            translation: const Offset(-.5, -.5),
                            child: Text(
                              entry.$1,
                              textScaler: TextScaler.noScaling,
                              style: CAtelier.text(
                                context,
                                (width * entry.$4).clamp(
                                  entry.$4 == .15 ? 20 : 16,
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
              );
            },
          );
          final listen = ValueListenableBuilder<TtsSpeechPhase>(
            valueListenable: SoriSpeech.phase,
            builder: (_, phase, _) => Tooltip(
              message: t.cHangulListen,
              excludeFromSemantics: true,
              child: _atelierAction(
                context,
                key: const Key('hangul-overview-listen'),
                label: t.cHangulListen,
                primary: true,
                leading: CAtelierSpeaker(
                  width: 34,
                  height: 24,
                  playing: _playing && phase == TtsSpeechPhase.speaking,
                ),
                onTap: () => unawaited(_listen()),
              ),
            ),
          );
          final equation = FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${consonants[_c].letter} + ${vowels[_v].letter} = $_syllable',
              style: CAtelier.text(
                context,
                20,
                bold: true,
                korean: true,
                color: CAtelier.jade,
                height: 1.2,
              ),
            ),
          );
          final pronunciation = FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${consonants[_c].letter} [${consonants[_c].romanization}] · ${vowels[_v].letter} [${vowels[_v].romanization}]',
              style: CAtelier.text(context, 15, color: CAtelier.muted),
            ),
          );
          final preview = full
              ? Row(
                  children: [
                    Expanded(child: stage(150)),
                    const SizedBox(width: Spacing.md),
                    SizedBox(
                      width: 132,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          equation,
                          const SizedBox(height: Spacing.xs),
                          pronunciation,
                          const SizedBox(height: Spacing.sm),
                          listen,
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    SizedBox(width: 104, height: 70, child: stage(70)),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [equation, pronunciation],
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    SizedBox(width: 124, child: listen),
                  ],
                );
          Widget cell({
            required Key key,
            required String label,
            required bool on,
            required double fontSize,
            required VoidCallback onTap,
            bool? selected,
          }) => CAtelierButton(
            key: key,
            label: label,
            face: on ? CAtelierFace.jade : CAtelierFace.quiet,
            depth: false,
            radius: 12,
            selected: selected,
            padding: const EdgeInsets.all(CAtelierSpacing.baselineGap),
            onTap: onTap,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textScaler: TextScaler.noScaling,
                style: CAtelier.text(
                  context,
                  fontSize,
                  korean: true,
                  height: 1.1,
                  color: on ? CAtelier.paper : CAtelier.ink,
                ),
              ),
            ),
          );
          final groups = Row(
            children: [
              for (var group = 0; group < 4; group++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: group > 0 ? 6 : 0),
                    child: cell(
                      key: ValueKey('hangul-vowel-group-$group'),
                      label: vowels
                          .skip(group * 4)
                          .take(4)
                          .map((v) => v.letter)
                          .join(' '),
                      on: group == _group,
                      selected: group == _group,
                      fontSize: 18,
                      onTap: () => setState(() => _group = group),
                    ),
                  ),
                ),
            ],
          );
          final chart = LayoutBuilder(
            builder: (context, chartBox) {
              const rowExtent = 52.0, pagerHeight = 48.0;
              // The vowel heading row is shown when two chart rows still fit.
              final showHeading =
                  chartBox.maxHeight >= pagerHeight + rowExtent * 3;
              final rows =
                  ((chartBox.maxHeight -
                              pagerHeight -
                              (showHeading ? rowExtent : 0)) /
                          rowExtent)
                      .floor()
                      .clamp(1, _chartOrder.length);
              final cellHeight =
                  ((chartBox.maxHeight - pagerHeight) /
                              (rows + (showHeading ? 1 : 0)) -
                          Spacing.xs)
                      .clamp(48.0, 64.0);
              final count = (_chartOrder.length / rows).ceil();
              final page = _chartRow ~/ rows;
              final pageRows = _chartOrder.skip(page * rows).take(rows);
              final labels = MaterialLocalizations.of(context);
              void showPage(int index) =>
                  setState(() => _chartRow = index.clamp(0, count - 1) * rows);
              Widget row(Widget lead, List<Widget> cells) => Padding(
                padding: const EdgeInsets.only(bottom: Spacing.xs),
                child: SizedBox(
                  height: cellHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 48, child: lead),
                      for (final c in cells)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: Spacing.xs),
                            child: c,
                          ),
                        ),
                    ],
                  ),
                ),
              );
              return Column(
                children: [
                  if (showHeading)
                    row(const SizedBox.shrink(), [
                      for (final v in indices)
                        cell(
                          key: ValueKey('hangul-vowel-${vowels[v].letter}'),
                          label: vowels[v].letter,
                          on: v == _v,
                          selected: v == _v,
                          fontSize: 22,
                          onTap: () => _choose(_c, v),
                        ),
                    ]),
                  Expanded(
                    child: GestureDetector(
                      key: const Key('hangul-full-syllable-chart'),
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragStart: (_) => _chartDrag = 0,
                      onVerticalDragUpdate: (details) =>
                          _chartDrag += details.delta.dy,
                      onVerticalDragEnd: (_) {
                        if (_chartDrag.abs() >= 24) {
                          final pages = (_chartDrag.abs() / (rows * rowExtent))
                              .round()
                              .clamp(1, count);
                          showPage(page + (_chartDrag < 0 ? pages : -pages));
                        }
                      },
                      child: Column(
                        children: [
                          for (final c in pageRows)
                            row(
                              cell(
                                key: ValueKey(
                                  'hangul-consonant-${consonants[c].letter}',
                                ),
                                label: consonants[c].letter,
                                on: c == _c,
                                fontSize: 22,
                                onTap: () => _choose(c, _v),
                              ),
                              [
                                for (final v in indices)
                                  cell(
                                    key: ValueKey(
                                      'hangul-syllable-${composeHangulSyllable(consonants[c].letter, vowels[v].letter, '')!}',
                                    ),
                                    label: composeHangulSyllable(
                                      consonants[c].letter,
                                      vowels[v].letter,
                                      '',
                                    )!,
                                    on: c == _c && v == _v,
                                    selected: c == _c && v == _v,
                                    fontSize: 24,
                                    onTap: () => _choose(c, v),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: pagerHeight,
                    child: count > 1
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                key: const Key('hangul-chart-previous'),
                                tooltip: labels.previousPageTooltip,
                                onPressed: page > 0
                                    ? () => showPage(page - 1)
                                    : null,
                                icon: const Icon(Icons.chevron_left_rounded),
                              ),
                              SizedBox(
                                width: 64,
                                child: Text(
                                  '${page + 1} / $count',
                                  textAlign: TextAlign.center,
                                  style: CAtelier.text(
                                    context,
                                    16,
                                    bold: true,
                                    color: CAtelier.muted,
                                  ),
                                ),
                              ),
                              IconButton(
                                key: const Key('hangul-chart-next'),
                                tooltip: labels.nextPageTooltip,
                                onPressed: page + 1 < count
                                    ? () => showPage(page + 1)
                                    : null,
                                icon: const Icon(Icons.chevron_right_rounded),
                              ),
                            ],
                          )
                        : null,
                  ),
                ],
              );
            },
          );
          final catalogs = Row(
            children: [
              for (final (index, label) in [
                '${t.hangulChipConsonants} · 19',
                '${t.hangulChipVowels} · 15',
                '${t.atelierStructure} · 16',
              ].indexed) ...[
                if (index > 0) const SizedBox(width: _AtelierUi.gap),
                Expanded(
                  child: Tooltip(
                    message: label,
                    excludeFromSemantics: true,
                    child: _atelierAction(
                      context,
                      label: label,
                      onTap: () => unawaited(_catalog(index)),
                    ),
                  ),
                ),
              ],
            ],
          );
          if (paged) {
            // Short split screens: the reference sections come first, the
            // chart gets its own page at the full remaining height.
            final chartHeight = math.max(
              140.0,
              constraints.maxHeight - SoriViewportPages.controlsHeight - 8,
            );
            return SoriViewportPages(
              sections: [
                header,
                const SizedBox(height: CAtelierSpacing.relatedGap),
                catalogs,
                const SizedBox(height: _AtelierUi.gap),
                preview,
                SizedBox(
                  height: chartHeight,
                  child: Column(
                    children: [
                      groups,
                      const SizedBox(height: CAtelierSpacing.relatedGap),
                      Expanded(child: chart),
                    ],
                  ),
                ),
              ],
            );
          }
          if (tablet) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      const SizedBox(height: CAtelierSpacing.relatedGap),
                      preview,
                      const SizedBox(height: Spacing.md),
                      catalogs,
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.lg),
                Expanded(
                  child: Column(
                    children: [
                      groups,
                      const SizedBox(height: CAtelierSpacing.relatedGap),
                      Expanded(child: chart),
                    ],
                  ),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: CAtelierSpacing.relatedGap),
              preview,
              const SizedBox(height: _AtelierUi.gap),
              groups,
              const SizedBox(height: CAtelierSpacing.relatedGap),
              Expanded(child: chart),
              const SizedBox(height: CAtelierSpacing.relatedGap),
              catalogs,
            ],
          );
        },
      ),
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
  final size = MediaQuery.sizeOf(context);
  final tablet = size.width >= CAtelier.wideSurface;
  final split =
      tablet ||
      (size.width > size.height && size.height < _AtelierUi.navMinHeight);
  final selected = [
    t.hangulChipConsonants,
    t.hangulChipVowels,
    t.hangulChipSyllables,
  ][state._mode];
  final compact = size.height < 760 || large;
  const descriptionKey = Key('hangul-card-description');
  List<Widget> socials(bool compact) => [
    _atelierSocial(
      context,
      t.atelierRemember,
      'social-heart',
      () => unawaited(state._likeLetter(c.letter, generation)),
      liked: liked,
      key: const Key('hangul-card-like'),
      compact: compact,
    ),
    _atelierSocial(
      context,
      t.atelierShare,
      'social-share',
      () => unawaited(state._shareCurrent()),
      compact: compact,
    ),
    _atelierSocial(
      context,
      t.atelierMore,
      'settings-gear',
      () => unawaited(state._showCardModeSheet()),
      compact: compact,
    ),
  ];
  final visual = LayoutBuilder(
    builder: (context, box) {
      // letter-tile.png draws the card across ~80% of its square canvas, so
      // the canvas may pass under the side column while the card fits.
      final width = math.min(
        math.min(box.maxWidth / .8, box.maxHeight),
        tablet ? 560.0 : 480.0,
      );
      return OverflowBox(
        maxWidth: math.max(box.maxWidth, width),
        child: SizedBox(
          width: compact ? box.maxWidth : width,
          height: compact ? box.maxHeight : width,
          child: _AtelierCardGesture(
            key: ValueKey('atelier-feed-${c.letter}'),
            active: state.widget.active,
            onNext: state._next,
            onPrevious: state._prev,
            onFlip: state._onFlip,
            onLike: () => unawaited(
              state._likeLetter(c.letter, generation, addOnly: true),
            ),
            liked: liked,
            child: FlipCard(
              key: ValueKey('hangul-card-${c.letter}'),
              flipped: state._flipped,
              scrollFace: false,
              duration: SoriMotion.reduceMotion(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 320),
              front: Center(
                child: _atelierCardFace(
                  context,
                  c,
                  width,
                  back: false,
                  large: large,
                ),
              ),
              back: compact
                  ? CAtelierSurface(
                      padding: const EdgeInsets.all(Spacing.sm),
                      child: LayoutBuilder(
                        builder: (context, details) => SoriViewportPages(
                          targetSectionKey: descriptionKey,
                          sections: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  c.letter,
                                  style: CAtelier.text(
                                    context,
                                    24,
                                    korean: true,
                                    bold: true,
                                  ),
                                ),
                                const SizedBox(width: Spacing.sm),
                                Flexible(
                                  child: Text(
                                    '[${c.romanization}]',
                                    style: CAtelier.text(context, 16),
                                  ),
                                ),
                              ],
                            ),
                            ..._atelierTextSections(
                              context,
                              details,
                              c.descriptionFor(lang),
                              firstSectionKey: descriptionKey,
                            ),
                            if (c.exampleWord.isNotEmpty)
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${c.exampleWord} · ${c.exampleFor(lang)}',
                                      style: CAtelier.text(
                                        context,
                                        16,
                                        korean: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: Spacing.xs),
                                  CAtelierButton(
                                    label: t.cHangulListenWord,
                                    face: CAtelierFace.quiet,
                                    child: const CAtelierSpeaker(
                                      width: 32,
                                      height: 24,
                                    ),
                                    onTap: () => unawaited(
                                      SoriSpeech.speak(c.exampleWord),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    )
                  : _atelierCardFace(
                      context,
                      c,
                      width,
                      back: true,
                      large: large,
                    ),
            ),
          ),
        ),
      );
    },
  );
  final status = MediaQuery.withClampedTextScaling(
    maxScaleFactor: _AtelierUi.maxControlScale,
    child: Row(
      children: [
        Expanded(
          child: Text(
            t.atelierFlipHint,
            style: CAtelier.text(context, 16, color: CAtelier.muted),
          ),
        ),
        Text(
          '${state._idx % pool.length + 1} / ${pool.length}',
          style: CAtelier.text(context, 16, bold: true),
        ),
      ],
    ),
  );
  final visualPanel = Row(
    children: [
      Expanded(child: visual),
      const SizedBox(width: Spacing.sm),
      SizedBox(
        width: 64,
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: _AtelierUi.maxControlScale,
          child: LayoutBuilder(
            // Labels need ~86dp per action; short cards keep icon targets.
            builder: (context, box) => FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final social in socials(box.maxHeight < 3 * 86)) ...[
                    social,
                    const SizedBox(height: Spacing.xs),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
  void Function()? judge(int action, void Function() run) =>
      state.widget.active && (state._flipped || action == 1)
      ? () {
          if (state.mounted &&
              state.widget.active &&
              generation == state._likeSourceGeneration) {
            run();
          }
        }
      : null;
  final details = state._flipped && !compact
      ? [
          Text(c.descriptionFor(lang), style: CAtelier.text(context, 16)),
          if (c.exampleWord.isNotEmpty) ...[
            const SizedBox(height: Spacing.xs),
            Text(c.exampleFor(lang), style: CAtelier.text(context, 16)),
          ],
          const SizedBox(height: Spacing.md),
        ]
      : const <Widget>[];
  final controls = Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ...details,
      Row(
        children: [
          Expanded(
            child: _atelierAction(
              context,
              label: t.atelierNotYet,
              icon: Icons.close_rounded,
              onTap: judge(0, state._dontKnow),
            ),
          ),
          const SizedBox(width: _AtelierUi.gap),
          Expanded(
            child: _atelierAction(
              context,
              label: t.atelierKnown,
              icon: Icons.check_rounded,
              primary: true,
              onTap: judge(2, state._known),
            ),
          ),
        ],
      ),
      const SizedBox(height: _AtelierUi.gap),
      Row(
        children: [
          Expanded(
            flex: 4,
            child: _atelierAction(
              context,
              label: t.atelierSkip,
              icon: Icons.skip_next_rounded,
              onTap: judge(1, state._next),
            ),
          ),
          const SizedBox(width: _AtelierUi.gap),
          Expanded(
            flex: 3,
            child: _atelierAction(
              context,
              label: t.cHangulListen,
              icon: Icons.volume_up_rounded,
              onTap: state._speakCurrent,
            ),
          ),
          const SizedBox(width: _AtelierUi.gap),
          Expanded(
            flex: 3,
            child: _atelierAction(
              context,
              key: const Key('hangul-finish-cards'),
              label: t.dailyCharFinish,
              icon: Icons.flag_rounded,
              onTap:
                  state.widget.active &&
                      state._lifetime.isCurrent &&
                      state._sessionInteractions > 0
                  ? () => unawaited(state._finish())
                  : null,
            ),
          ),
        ],
      ),
    ],
  );
  final filters = Row(
    children: [
      Expanded(
        flex: 3,
        child: SizedBox(
          height: _AtelierUi.controlOf(context),
          child: CAtelierButton(
            key: const Key('hangul-cards-selection'),
            label: '$selected · ${pool.length}',
            face: CAtelierFace.quiet,
            radius: CAtelierType.actionRadius,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            onTap: () => unawaited(state._showCardModeSheet()),
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: _AtelierUi.maxControlScale,
              child: Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$selected · ${pool.length}',
                        style: CAtelier.text(
                          context,
                          _AtelierUi.labelOf(context),
                          bold: true,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: CAtelier.ink,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: _AtelierUi.gap),
      Expanded(
        flex: 2,
        child: _atelierAction(
          context,
          key: const Key('hangul-cards-filter'),
          label: '${t.atelierDifficult} · ${state._hardPool.length}',
          selected: state._hardOnly && state._hardPool.isNotEmpty,
          onTap: () => unawaited(state._showCardModeSheet()),
        ),
      ),
    ],
  );
  return LayoutBuilder(
    builder: (context, box) {
      if (!split && box.maxHeight < 360) {
        return SoriViewportPages(
          // Mode filter, counter and card share the first page (the card
          // takes the rest of it); the judgments follow on the next page.
          sections: [
            filters,
            status,
            SizedBox(
              height: math.max(
                120.0,
                box.maxHeight -
                    SoriViewportPages.controlsHeight -
                    _AtelierUi.controlOf(context) -
                    48,
              ),
              child: visualPanel,
            ),
            const SizedBox(height: _AtelierUi.gap),
            controls,
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          filters,
          const SizedBox(height: CAtelierSpacing.relatedGap),
          status,
          const SizedBox(height: CAtelierSpacing.relatedGap),
          if (split)
            Expanded(
              child: Row(
                children: [
                  Expanded(child: visualPanel),
                  const SizedBox(width: Spacing.lg),
                  SizedBox(
                    width: tablet ? 380 : 280,
                    child: Center(child: controls),
                  ),
                ],
              ),
            )
          else ...[
            Expanded(child: visualPanel),
            const SizedBox(height: _AtelierUi.gap),
            controls,
          ],
        ],
      );
    },
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
                    (width * .28).clamp(28, 126),
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
                  (width * .15).clamp(18, 42),
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
                    (width * .115).clamp(12, 32),
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
  bool compact = false,
}) => Tooltip(
  message: label,
  excludeFromSemantics: true,
  child: CAtelierTouch(
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
            constraints: BoxConstraints(
              minWidth: 48,
              minHeight: compact ? 48 : 64,
            ),
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
                    if (!compact)
                      Text(
                        label,
                        style: CAtelier.text(
                          context,
                          14,
                          bold: true,
                          height: 1.2,
                        ),
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
  ),
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
  final size = MediaQuery.sizeOf(context);
  final tablet = size.width >= CAtelier.wideSurface;
  // Landscape phones keep the paper on the left and controls on the right.
  final split =
      tablet ||
      (size.width > size.height && size.height < _AtelierUi.navMinHeight);
  final index = state._mode == 0 ? state._idx : consonants.length + state._idx;
  final desk = LayoutBuilder(
    builder: (context, box) {
      const ratio = 1122 / 1402;
      final short = box.maxHeight < 310;
      final width = math.min(
        math.min(box.maxWidth, 420.0),
        box.maxHeight * ratio / (short ? .66 : 1),
      );
      final deskHeight = width / ratio;
      final shownHeight = math.min(deskHeight, box.maxHeight);
      return TickerMode(
        enabled: state.widget.active && !state._toolsOpen,
        child: Center(
          child: SizedBox(
            width: width,
            height: shownHeight,
            child: Stack(
              children: [
                Positioned(
                  top: (shownHeight - deskHeight) * .42,
                  width: width,
                  height: deskHeight,
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
                              child: CustomPaint(
                                painter: _AtelierWritingGrid(),
                              ),
                            ),
                            // One numbered jade guide on every phone size.
                            if (!state._demonstrating)
                              // Same rect as the trace canvas; the guide is
                              // its centred shortest-side square, exactly as
                              // TraceCanvas maps canonical coordinates.
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: SizedBox.expand(
                                    key: const Key('hangul-writing-guide'),
                                    child: Center(
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: StrokeCanvas(
                                          letter: state._current.letter,
                                          color: CAtelier.jade,
                                          strokes: state._targetStrokes,
                                          highlightIndex: state._letterDone
                                              ? null
                                              : state._acceptedStrokes,
                                          paperGuide: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
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
                                  active:
                                      state.widget.active && !state._toolsOpen,
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
                                          state._targetStrokes[state
                                              ._acceptedStrokes],
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
              ],
            ),
          ),
        ),
      );
    },
  );
  // Clearing sits on the paper it clears, out of the action rows.
  final deskArea = Stack(
    children: [
      Positioned.fill(child: desk),
      Positioned(
        top: 0,
        right: 0,
        child: _atelierAction(
          context,
          key: const Key('hangul-clear'),
          label: t.hangulClearBtn,
          icon: Icons.delete_outline_rounded,
          height: 48,
          onTap: state._clearPractice,
        ),
      ),
    ],
  );
  final status = Row(
    children: [
      Expanded(
        child: Text(
          t.hangulStrokeProgress(
            state._acceptedStrokes,
            state._targetStrokes.length,
          ),
          style: CAtelier.text(context, 16, bold: true),
        ),
      ),
      Text(
        '${index + 1} / 34',
        style: CAtelier.text(context, 16, color: CAtelier.muted),
      ),
    ],
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
      const SizedBox(width: Spacing.sm),
      Flexible(
        child: Text(
          state._demonstrating ? t.atelierWatchBrush : state._hintText(t),
          style: CAtelier.text(
            context,
            _AtelierUi.labelOf(context),
            color: state._hintColor(),
            height: 1.25,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );
  Widget square(Key key, String label, IconData icon, VoidCallback? onTap) =>
      SizedBox(
        width: _AtelierUi.controlOf(context),
        child: _atelierAction(
          context,
          key: key,
          label: label,
          text: '',
          icon: icon,
          onTap: onTap,
        ),
      );
  final picker = Row(
    children: [
      square(
        const Key('hangul-writing-previous'),
        t.btnPrev,
        Icons.chevron_left_rounded,
        state._mode == 0 && state._idx == 0 ? null : state._prev,
      ),
      const SizedBox(width: _AtelierUi.gap),
      Expanded(
        child: SizedBox(
          height: _AtelierUi.controlOf(context),
          child: CAtelierButton(
            key: const Key('hangul-writing-selection'),
            label: '${state._current.letter} ▾',
            semanticLabel:
                '${state._current.letter} · ${state._current.romanization}',
            face: CAtelierFace.quiet,
            radius: CAtelierType.actionRadius,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            onTap: () => unawaited(state._showLetters()),
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: _AtelierUi.maxControlScale,
              child: Row(
                children: [
                  Text(
                    state._current.letter,
                    style: CAtelier.text(
                      context,
                      22,
                      bold: true,
                      korean: true,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        state._current.romanization,
                        style: CAtelier.text(
                          context,
                          _AtelierUi.labelOf(context),
                          bold: true,
                          color: CAtelier.muted,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: CAtelier.ink,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: _AtelierUi.gap),
      square(
        const Key('hangul-writing-next'),
        t.btnNext,
        Icons.chevron_right_rounded,
        state._mode == 1 && state._idx == vowels.length - 1
            ? null
            : state._next,
      ),
      const SizedBox(width: _AtelierUi.gap),
      square(
        const Key('hangul-writing-more'),
        t.atelierMore,
        Icons.more_horiz_rounded,
        () => unawaited(state._showWriteSettings()),
      ),
    ],
  );
  final demonstrateLabel = state._demonstrating
      ? SoriMotion.reduceMotion(context)
            ? state._demoStep < state._targetStrokes.length - 1
                  ? t.atelierDemoNext
                  : t.atelierDemoEnd
            : t.atelierDemoRestart
      : t.atelierDemoShort;
  final actions = Row(
    children: [
      Expanded(
        flex: 4,
        child: _atelierAction(
          context,
          key: const Key('hangul-demonstrate'),
          label: demonstrateLabel,
          icon: state._demonstrating
              ? Icons.skip_next_rounded
              : Icons.play_arrow_rounded,
          onTap: state._demonstrateAction,
        ),
      ),
      const SizedBox(width: _AtelierUi.gap),
      Expanded(
        flex: 3,
        child: _atelierAction(
          context,
          key: const Key('hangul-writing-listen'),
          label: t.cHangulListen,
          icon: Icons.volume_up_rounded,
          onTap: state._speakCurrent,
        ),
      ),
      const SizedBox(width: _AtelierUi.gap),
      Expanded(
        flex: 3,
        child: _atelierAction(
          context,
          key: const Key('hangul-finish-writing'),
          label: t.dailyCharFinish,
          icon: Icons.check_rounded,
          primary: true,
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
  final controls = Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      caption,
      const SizedBox(height: _AtelierUi.gap),
      picker,
      const SizedBox(height: _AtelierUi.gap),
      actions,
    ],
  );
  return MediaQuery.withClampedTextScaling(
    maxScaleFactor: _AtelierUi.maxControlScale,
    child: LayoutBuilder(
      builder: (context, box) {
        // Split-screen slivers: the paper gets a whole page instead of
        // being squeezed below a traceable size by the two control rows.
        if (!split && box.maxHeight < 300) {
          return SoriViewportPages(
            sections: [
              status,
              SizedBox(
                height: math.max(
                  120.0,
                  box.maxHeight - SoriViewportPages.controlsHeight - 32,
                ),
                child: deskArea,
              ),
              controls,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            status,
            const SizedBox(height: CAtelierSpacing.relatedGap),
            if (split)
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: deskArea),
                    const SizedBox(width: Spacing.lg),
                    SizedBox(
                      width: tablet ? 380 : 280,
                      child: Center(child: controls),
                    ),
                  ],
                ),
              )
            else ...[
              Expanded(child: deskArea),
              const SizedBox(height: CAtelierSpacing.relatedGap),
              controls,
            ],
          ],
        );
      },
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
  late final AnimationController _clock;

  @override
  void initState() {
    super.initState();
    _clock =
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
