import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/onboarding_v2/curriculum_evidence_projector.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/learner_level.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/sori/dialog.dart';
import '../../widgets/sori/external_link.dart';
import '../../widgets/sori/pressable.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/window_class.dart';
import 'onboarding_v2_shell.dart';
import 'onboarding_v3_demo_support.dart';

/// A short heading leaves the learning surface and footer their own space.
class JourneyHeading extends StatelessWidget {
  const JourneyHeading({
    super.key,
    required this.title,
    this.shortTitle,
    this.titleKey,
    this.illustration,
  });
  final String title;
  final String? illustration;
  final Key? titleKey;
  final String? shortTitle;
  @override
  Widget build(BuildContext context) {
    final short = MediaQuery.sizeOf(context).height < 700;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              key: titleKey,
              style: SoriTextTheme.of(
                context,
              ).h2.copyWith(fontSize: short ? 22 : 28, height: 1.12),
            ),
          ),
        ),
        if (illustration != null) ...[
          const SizedBox(width: Spacing.sm),
          Image.asset(
            illustration!,
            width: 80,
            height: 80,
            fit: BoxFit.contain,
            cacheWidth: (80 * MediaQuery.devicePixelRatioOf(context)).ceil(),
            excludeFromSemantics: true,
          ),
        ],
      ],
    );
  }
}

class JourneyChoice extends StatelessWidget {
  const JourneyChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.detail,
    this.art,
  });
  final String label;
  final String? detail;
  final String? art;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final surfaces = SoriSurfaces.of(context);
    return Semantics(
      selected: selected,
      label: [
        if (art != null) art!,
        label,
        if (detail != null) detail!,
      ].join('. '),
      excludeSemantics: true,
      button: true,
      onTap: onTap,
      child: Material(
        color: selected ? surfaces.surfaceAlt : surfaces.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SoriRadius.md),
          side: BorderSide(
            color: selected ? c.primary : surfaces.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: SoriPressable(
          onTap: onTap,
          pressScale: .99,
          surfaceDepth: 4,
          surfaceEdgeColor: surfaces.border,
          surfaceRadius: SoriRadius.md,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (art != null) ...[
                  Text(
                    art!,
                    locale: const Locale('ko'),
                    textAlign: TextAlign.center,
                    style: SoriTextTheme.of(
                      context,
                    ).h1.copyWith(fontSize: 28, color: c.primary),
                  ),
                  const SizedBox(height: Spacing.sm),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: SoriTextTheme.of(context).cardTitle,
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(width: Spacing.sm),
                      Icon(
                        Icons.check_circle_rounded,
                        size: 22,
                        color: c.primary,
                      ),
                    ],
                  ],
                ),
                if (detail != null) ...[
                  const SizedBox(height: Spacing.sm),
                  Text(
                    detail!,
                    textAlign: TextAlign.center,
                    style: SoriTextTheme.of(context).bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class JourneyPanel extends StatelessWidget {
  const JourneyPanel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          SoriColors.gold.withValues(alpha: .14),
          surfaces.bg,
        ),
        borderRadius: BorderRadius.circular(SoriRadius.lg),
        border: Border.all(color: SoriColors.gold.withValues(alpha: .65)),
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}

class JourneyReading extends StatelessWidget {
  const JourneyReading({super.key, required this.text, required this.korean});
  final String text;
  final bool korean;
  @override
  Widget build(BuildContext context) {
    return DemoPagedText(
      text: text,
      korean: korean,
      fontSize: _journeyReadingSize(context, text, korean: korean),
    );
  }
}

double _journeyReadingSize(
  BuildContext context,
  String text, {
  required bool korean,
}) {
  // The example is the focal point of the path card. Keep the compact phone
  // size while making short Korean examples legible on a Pad.
  final tablet = appWindowClassOf(context).isAtLeastMedium;
  if (!korean) {
    return tablet ? 23 : 16;
  }
  if (!tablet) {
    return 28;
  }
  return text.runes.length <= 12 ? 52 : 40;
}

class OnboardingPathScene extends StatefulWidget {
  const OnboardingPathScene({
    super.key,
    required this.level,
    this.beginner = false,
    this.evidence,
  });
  final LearnerLevel level;
  final bool beginner;
  final OnboardingCurriculumEvidenceProjection? evidence;
  @override
  State<OnboardingPathScene> createState() => _OnboardingPathSceneState();
}

class _OnboardingPathSceneState extends State<OnboardingPathScene> {
  final _data = rootBundle
      .loadString('assets/data/onboarding_journey_paths.json', cache: false)
      .then((v) => jsonDecode(v) as Map<String, dynamic>);
  int _selected = 0;
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _data,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text(t.onboardingDemoUnavailable));
        }
        if (!snap.hasData) {
          return const AppLoading(assetSize: 48);
        }
        final paths =
            snap.data![widget.beginner ? 'new' : widget.level.display] as List;
        final path = paths[_selected] as Map<String, dynamic>;
        final example = path['example'] as Map<String, dynamic>;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.beginner ? 'Hangeul → A1' : widget.level.display,
              style: SoriTextTheme.of(context).cardTitle,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 640,
                    maxHeight: 440,
                  ),
                  child: JourneyPanel(
                    child: LayoutBuilder(
                      builder: (context, bounds) {
                        if (bounds.maxHeight < 280 ||
                            MediaQuery.textScalerOf(context).scale(16) > 24) {
                          final korean = example['ko'] as String;
                          return SingleChildScrollView(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${(_selected + 1).toString().padLeft(2, '0')} · ${demoMeaning(context, path)}',
                                    textAlign: TextAlign.center,
                                    style: SoriTextTheme.of(context).cardTitle,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    korean,
                                    locale: const Locale('ko'),
                                    textAlign: TextAlign.center,
                                    style: SoriTextTheme.of(context).koDisplay
                                        .copyWith(
                                          fontSize: _journeyReadingSize(
                                            context,
                                            korean,
                                            korean: true,
                                          ),
                                          fontWeight: FontWeight.w600,
                                          height: 1.25,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    demoMeaning(context, example),
                                    textAlign: TextAlign.center,
                                    style: SoriTextTheme.of(context).gloss
                                        .copyWith(
                                          fontSize: _journeyReadingSize(
                                            context,
                                            korean,
                                            korean: false,
                                          ),
                                          height: 1.35,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: [
                            Text(
                              '${(_selected + 1).toString().padLeft(2, '0')} · ${demoMeaning(context, path)}',
                              textAlign: TextAlign.center,
                              style: SoriTextTheme.of(context).cardTitle,
                            ),
                            Expanded(
                              flex: 3,
                              child: JourneyReading(
                                text: example['ko'] as String,
                                korean: true,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: JourneyReading(
                                text: demoMeaning(context, example),
                                korean: false,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            DemoChoiceRow(
              children: [
                for (
                  var i = _selected < 3 ? 0 : paths.length - 3;
                  i < (_selected < 3 ? 3 : paths.length);
                  i++
                )
                  DemoChoice(
                    key: ValueKey('onboarding-v3-path-$i'),
                    label: '${i + 1}'.padLeft(2, '0'),
                    selected: _selected == i,
                    onTap: () => setState(() => _selected = i),
                  ),
                if (paths.length > 3)
                  IconButton(
                    tooltip: t.onboardingDemoNext,
                    onPressed: () =>
                        setState(() => _selected = _selected < 3 ? 3 : 0),
                    icon: Icon(
                      _selected < 3 ? Icons.chevron_right : Icons.chevron_left,
                    ),
                  ),
              ],
            ),
            OnboardingV2DetailsButton(
              key: const ValueKey('onboarding-v3-path-details'),
              label: t.onboardingJourneyMethod,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.evidence == null
                        ? t.onboardingJourneyReturningHint
                        : t.onboardingJourneyMethodBody,
                  ),
                  if (widget.evidence != null) ...[
                    const SizedBox(height: 12),
                    for (final reference in widget.evidence!.references)
                      TextButton(
                        onPressed: () =>
                            openExternalUrl(context, reference.url.toString()),
                        child: Text(reference.documentName),
                      ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// An explicitly labelled sample. No permission, upload, or learner write occurs.
class OnboardingBookScene extends StatefulWidget {
  const OnboardingBookScene({super.key, required this.level});
  final LearnerLevel level;
  @override
  State<OnboardingBookScene> createState() => _OnboardingBookSceneState();
}

class _OnboardingBookSceneState
    extends OnboardingDemoSpeechState<OnboardingBookScene> {
  bool _captured = false;
  bool _saved = false;
  bool _meaning = false;

  void _photoAgain() {
    demoStop();
    setState(() {
      _captured = false;
      _saved = false;
      _meaning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return LayoutBuilder(
      builder: (context, bounds) {
        final compact =
            bounds.maxHeight < 420 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.5;
        return OnboardingDemoContent(
          level: widget.level,
          builder: (data) {
            final example = data['course'] as Map<String, dynamic>;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      _captured
                          ? Icons.auto_stories_outlined
                          : Icons.photo_camera_outlined,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _captured
                            ? t.onboardingJourneyFromBook
                            : t.onboardingJourneySamplePage,
                        style: const TextStyle(fontSize: 13, height: 1.15),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('onboarding-v3-book-replay'),
                      tooltip: _captured
                          ? t.onboardingJourneyPhotoAgain
                          : t.onboardingJourneySampleOnly,
                      onPressed: _captured
                          ? _photoAgain
                          : () {
                              showSoriDialog<void>(
                                context: context,
                                builder: (context) => SoriDialog(
                                  content: Text(t.onboardingJourneySampleOnly),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(t.onboardingDemoPrevious),
                                    ),
                                  ],
                                ),
                              );
                            },
                      icon: Icon(_captured ? Icons.replay : Icons.info_outline),
                    ),
                  ],
                ),
                Expanded(
                  child: JourneyPanel(
                    child: _captured
                        ? Column(
                            children: [
                              if (!compact)
                                Expanded(
                                  flex: 2,
                                  child: Image.asset(
                                    'assets/illustrations/onboarding/book_extract.webp',
                                    fit: BoxFit.contain,
                                    semanticLabel: t.onboardingJourneyFromBook,
                                  ),
                                ),
                              Expanded(
                                flex: 3,
                                child: JourneyReading(
                                  text: compact && _meaning
                                      ? demoMeaning(context, example)
                                      : example['ko'] as String,
                                  korean: !(compact && _meaning),
                                ),
                              ),
                              if (!compact && _meaning)
                                Expanded(
                                  flex: 2,
                                  child: JourneyReading(
                                    text: demoMeaning(context, example),
                                    korean: false,
                                  ),
                                ),
                            ],
                          )
                        : Image.asset(
                            'assets/illustrations/onboarding/book_scan.png',
                            key: const ValueKey('onboarding-v3-book-photo'),
                            fit: BoxFit.contain,
                            semanticLabel: t.onboardingJourneySamplePage,
                          ),
                  ),
                ),
                if (_captured)
                  SizedBox(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          key: const ValueKey('onboarding-v3-book-audio'),
                          tooltip: demoAudioFailed
                              ? t.onboardingDemoAudioUnavailable
                              : t.onboardingJourneyListen,
                          onPressed: () => demoSpeak(example['ko'] as String),
                          icon: Icon(
                            demoAudioFailed
                                ? Icons.volume_off_outlined
                                : demoPlaying
                                ? Icons.stop
                                : Icons.volume_up_outlined,
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('onboarding-v3-book-meaning'),
                          tooltip: t.onboardingJourneyMeaning,
                          isSelected: _meaning,
                          onPressed: () => setState(() => _meaning = !_meaning),
                          icon: const Icon(Icons.translate),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                DemoChoice(
                  key: const ValueKey('onboarding-v3-book-action'),
                  label: _captured
                      ? (_saved
                            ? (compact
                                  ? t.onboardingJourneyBookSavedShort
                                  : t.onboardingJourneySaved)
                            : (compact
                                  ? t.onboardingJourneyBookCardShort
                                  : t.onboardingJourneySave))
                      : (compact
                            ? t.onboardingJourneyBookCaptureShort
                            : t.onboardingJourneyTakePhoto),
                  icon: _captured
                      ? (_saved ? Icons.check : Icons.bookmark_outline)
                      : Icons.camera_alt,
                  selected: _saved && _captured,
                  onTap: () => setState(() {
                    if (_captured) {
                      _saved = !_saved;
                    } else {
                      _captured = true;
                    }
                  }),
                ),
                if (!compact)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      t.onboardingJourneySampleOnly,
                      textAlign: TextAlign.center,
                      style: SoriTextTheme.of(context).meta,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class OnboardingHanokScene extends StatefulWidget {
  const OnboardingHanokScene({super.key});
  @override
  State<OnboardingHanokScene> createState() => _OnboardingHanokSceneState();
}

class _OnboardingHanokSceneState extends State<OnboardingHanokScene> {
  bool _growth = false;
  bool _gate = false;
  int _stage = 0;
  int? _place;
  static const _house =
      'assets/illustrations/onboarding/sarangchae_canonical.webp';
  static const _construction = [
    [
      'assets/illustrations/onboarding/sarangchae-01-alpha.webp',
      'assets/illustrations/onboarding/sarangchae-02-alpha.webp',
    ],
    [
      'assets/illustrations/onboarding/gate-01-alpha.webp',
      'assets/illustrations/onboarding/gate-02-alpha.webp',
    ],
  ];
  static const _places = [
    Rect.fromLTRB(.29, .38, .45, .62),
    Rect.fromLTRB(.69, .48, .93, .68),
    Rect.fromLTRB(.12, .36, .28, .58),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final meanings = [
      t.onboardingJourneyDoor,
      t.onboardingJourneyVeranda,
      t.onboardingJourneyRoom,
    ];
    final labels = meanings;
    Widget houseImage() =>
        Image.asset(_house, fit: BoxFit.contain, semanticLabel: '사랑채');
    return LayoutBuilder(
      builder: (context, bounds) {
        final compact =
            bounds.maxHeight < 420 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.5;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DemoChoiceRow(
              children: [
                DemoChoice(
                  key: const ValueKey('onboarding-v3-hanok-places'),
                  label: compact
                      ? t.onboardingJourneyHanokPlacesShort
                      : t.onboardingJourneyPlace,
                  icon: compact ? null : Icons.home_outlined,
                  selected: !_growth,
                  onTap: () => setState(() => _growth = false),
                ),
                DemoChoice(
                  key: const ValueKey('onboarding-v3-hanok-growth'),
                  label: compact
                      ? t.onboardingJourneyHanokGrowthShort
                      : t.onboardingJourneyGrowth,
                  icon: compact ? null : Icons.layers_outlined,
                  selected: _growth,
                  onTap: () => setState(() => _growth = true),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_growth) ...[
              DemoChoiceRow(
                children: [
                  DemoChoice(
                    key: const ValueKey('onboarding-v3-hanok-house'),
                    label: compact
                        ? t.onboardingJourneyHanokHouseShort
                        : 'Sarangchae · 16',
                    selected: !_gate,
                    onTap: () => setState(() {
                      _gate = false;
                      _stage = 0;
                    }),
                  ),
                  DemoChoice(
                    key: const ValueKey('onboarding-v3-hanok-gate'),
                    label: compact
                        ? t.onboardingJourneyHanokGateShort
                        : 'Sotdaeulmun · 12',
                    selected: _gate,
                    onTap: () => setState(() {
                      _gate = true;
                      _stage = 0;
                    }),
                  ),
                ],
              ),
              Expanded(
                child: Image.asset(
                  _construction[_gate ? 1 : 0][_stage],
                  key: ValueKey('onboarding-v3-growth-art-$_gate-$_stage'),
                  fit: BoxFit.contain,
                  semanticLabel: '${_gate ? '솟을대문' : '사랑채'} · ${_stage + 1}',
                ),
              ),
              DemoChoiceRow(
                children: [
                  for (var i = 0; i < 2; i++)
                    DemoChoice(
                      key: ValueKey('onboarding-v3-growth-$i'),
                      label: '0${i + 1}',
                      selected: _stage == i,
                      onTap: () => setState(() => _stage = i),
                    ),
                  Tooltip(
                    message: t.onboardingJourneyFutureStages,
                    child: Semantics(
                      label: t.onboardingJourneyFutureStages,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_outline, size: 18),
                            Text(
                              ' … ${_gate ? 12 : 16}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(SoriRadius.lg),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ImageFiltered(
                            imageFilter: ui.ImageFilter.blur(
                              sigmaX: 5,
                              sigmaY: 5,
                            ),
                            child: Opacity(opacity: .8, child: houseImage()),
                          ),
                          if (_place != null)
                            ClipPath(
                              clipper: _HanokWindow(_places[_place!]),
                              child: houseImage(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              DemoChoiceRow(
                children: [
                  for (var i = 0; i < 3; i++)
                    DemoChoice(
                      key: ValueKey('onboarding-v3-place-$i'),
                      label: labels[i],
                      korean: false,
                      dense: compact,
                      selected: _place == i,
                      onTap: () => setState(() => _place = i),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _place == null
                      ? (compact
                            ? t.onboardingJourneyHanokPickPlace
                            : t.onboardingJourneyPeek)
                      : meanings[_place!],
                  key: const ValueKey('onboarding-v3-place-meaning'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: compact ? 12 : 14, height: 1.2),
                ),
              ),
            ],
            if (!compact) ...[
              const SizedBox(height: 8),
              Text(
                t.onboardingJourneyGrowthLink,
                textAlign: TextAlign.center,
                style: SoriTextTheme.of(context).bodySmall,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _HanokWindow extends CustomClipper<Path> {
  const _HanokWindow(this.rect);
  final Rect rect;
  @override
  Path getClip(Size s) => Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          rect.left * s.width,
          rect.top * s.height,
          rect.right * s.width,
          rect.bottom * s.height,
        ),
        const Radius.circular(8),
      ),
    );
  @override
  bool shouldReclip(_HanokWindow oldClipper) => rect != oldClipper.rect;
}
