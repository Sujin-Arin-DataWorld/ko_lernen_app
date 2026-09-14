import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/learner_level.dart';
import '../../widgets/sori/speakable.dart';
import '../../widgets/sori/tokens.dart';

/// A bounded copy of the approved Sites examples, never learner state.
class OnboardingDemoContent extends StatefulWidget {
  const OnboardingDemoContent({
    super.key,
    required this.level,
    required this.builder,
  });
  final LearnerLevel level;
  final Widget Function(Map<String, dynamic>) builder;
  @override
  State<OnboardingDemoContent> createState() => _OnboardingDemoContentState();
}

class _OnboardingDemoContentState extends State<OnboardingDemoContent> {
  late final Future<Map<String, dynamic>> _content = rootBundle
      .loadString('assets/data/onboarding_v3_demo_content.json', cache: false)
      .then((text) => jsonDecode(text) as Map<String, dynamic>);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _content,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(AppL10n.of(context).onboardingDemoUnavailable),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final levels = snapshot.data!['levels'] as Map<String, dynamic>;
        return widget.builder(
          levels[widget.level.display] as Map<String, dynamic>,
        );
      },
    );
  }
}

String demoMeaning(BuildContext context, Map<String, dynamic> text) =>
    text[Localizations.localeOf(context).languageCode == 'de' ? 'de' : 'en']
        as String;

abstract class OnboardingDemoSpeechState<T extends StatefulWidget>
    extends State<T> {
  bool demoPlaying = false;
  bool demoAudioFailed = false;
  int _audioGeneration = 0;

  Future<void> demoSpeak(String text) async {
    if (demoPlaying) {
      demoStop();
      return;
    }
    final generation = ++_audioGeneration;
    setState(() {
      demoPlaying = true;
      demoAudioFailed = false;
    });
    var played = false;
    try {
      played = await SoriSpeech.speak(text);
    } catch (_) {
      // Optional sound never blocks the demonstration or causes a reward.
    }
    if (mounted && generation == _audioGeneration) {
      setState(() {
        demoPlaying = false;
        demoAudioFailed = !played;
      });
    }
  }

  void demoStop() {
    _audioGeneration++;
    unawaited(SoriSpeech.stop().catchError((Object _) {}));
    if (mounted) {
      setState(() {
        demoPlaying = false;
        demoAudioFailed = false;
      });
    }
  }

  @override
  void dispose() {
    _audioGeneration++;
    unawaited(SoriSpeech.stop().catchError((Object _) {}));
    super.dispose();
  }
}

class DemoChoice extends StatelessWidget {
  const DemoChoice({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.icon,
    this.korean = false,
    this.dense = false,
  });
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final IconData? icon;
  final bool korean;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: EdgeInsets.symmetric(
              horizontal: dense ? 2 : 6,
              vertical: dense ? 2 : 6,
            ),
            backgroundColor: selected ? SoriColors.primaryDark : colors.surface,
            foregroundColor: selected
                ? SoriColors.contentCtaOn
                : colors.onSurface,
            side: BorderSide(
              color: selected ? colors.primary : colors.outlineVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: icon == null
              ? Text(
                  label,
                  textAlign: TextAlign.center,
                  locale: korean ? const Locale('ko') : null,
                  style: TextStyle(
                    fontSize: korean ? (dense ? 17 : 21) : 13,
                    height: 1.15,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, height: 1.15),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class DemoChoiceRow extends StatelessWidget {
  const DemoChoiceRow({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(width: 4),
        Expanded(child: children[i]),
      ],
    ],
  );
}

/// Text is paged by measured space; short surfaces themselves advance the page.
class DemoPagedText extends StatefulWidget {
  const DemoPagedText({
    super.key,
    required this.text,
    this.korean = true,
    this.fontSize = 28,
    this.textKey,
  });
  final String text;
  final bool korean;
  final double fontSize;
  final Key? textKey;
  @override
  State<DemoPagedText> createState() => _DemoPagedTextState();
}

class _DemoPagedTextState extends State<DemoPagedText> {
  int _page = 0;
  @override
  void didUpdateWidget(covariant DemoPagedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _page = 0;
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final t = AppL10n.of(context);
      final style = TextStyle(
        fontSize: math.min(
          widget.fontSize,
          bounds.maxHeight / (1.35 * MediaQuery.textScalerOf(context).scale(1)),
        ),
        height: 1.35,
        fontWeight: widget.korean ? FontWeight.w600 : FontWeight.normal,
        fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
      );
      final painter = TextPainter(
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
      );
      double height(String value) {
        painter.text = TextSpan(text: value, style: style);
        painter.layout(maxWidth: math.max(1, bounds.maxWidth - 24));
        return painter.height;
      }

      final paged = height(widget.text) > bounds.maxHeight;
      final surfacePager = bounds.maxHeight < height('가') + 48;
      final limit = math.max(
        1.0,
        bounds.maxHeight - (paged && !surfacePager ? 48 : 0),
      );
      final pages = <String>[];
      var current = '';
      // Character-safe splitting preserves punctuation and the original order.
      for (final character in widget.text.characters) {
        final candidate = current + character;
        if (current.isNotEmpty && height(candidate) > limit) {
          pages.add(current.trim());
          current = character;
        } else {
          current = candidate;
        }
      }
      if (current.isNotEmpty || pages.isEmpty) {
        pages.add(current.trim());
      }
      painter.dispose();
      final page = _page.clamp(0, pages.length - 1);
      if (surfacePager && pages.length > 1) {
        return Semantics(
          button: true,
          hint: t.onboardingDemoNext,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _page = (page + 1) % pages.length),
            onHorizontalDragEnd: (details) => setState(
              () => _page =
                  (page +
                      (details.primaryVelocity != null &&
                              details.primaryVelocity! > 0
                          ? -1
                          : 1)) %
                  pages.length,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    pages[page],
                    key: widget.textKey,
                    locale: widget.korean ? const Locale('ko') : null,
                    style: style,
                    textAlign: TextAlign.center,
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
        );
      }
      return Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                pages[page],
                key: widget.textKey,
                locale: widget.korean ? const Locale('ko') : null,
                style: style,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (pages.length > 1)
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  IconButton(
                    onPressed: page > 0
                        ? () => setState(() => _page = page - 1)
                        : null,
                    tooltip: t.onboardingDemoPrevious,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      '${page + 1} / ${pages.length}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: page + 1 < pages.length
                        ? () => setState(() => _page = page + 1)
                        : null,
                    tooltip: t.onboardingDemoNext,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      );
    },
  );
}

/// A small local word tray, shared by writing and the sentence game.
class DemoSentenceTiles extends StatefulWidget {
  const DemoSentenceTiles({super.key, required this.sentence});
  final String sentence;
  @override
  State<DemoSentenceTiles> createState() => _DemoSentenceTilesState();
}

class _DemoSentenceTilesState extends State<DemoSentenceTiles> {
  final List<int> _placed = [];
  int _tray = 0;
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final words = widget.sentence.split(' ');
    final perPage = MediaQuery.textScalerOf(context).scale(1) > 1.5 ? 1 : 2;
    final order = List.generate(words.length, (i) => words.length - 1 - i);
    final visible = order.skip(_tray * perPage).take(perPage).toList();
    return Column(
      children: [
        Expanded(
          child: DemoPagedText(
            text: _placed.isEmpty
                ? '···'
                : _placed.map((i) => words[i]).join(' '),
            textKey: const ValueKey('demo-assembled'),
          ),
        ),
        DemoChoiceRow(
          children: [
            for (final i in visible)
              DemoChoice(
                key: ValueKey('demo-word-$i'),
                label: words[i],
                korean: true,
                dense: perPage == 1,
                selected: _placed.contains(i),
                onTap: () => setState(() {
                  if (_placed.contains(i)) {
                    _placed.remove(i);
                  } else {
                    _placed.add(i);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 4),
        DemoChoiceRow(
          children: [
            DemoChoice(
              label: t.onboardingDemoReset,
              icon: Icons.replay,
              onTap: () => setState(_placed.clear),
            ),
            if (words.length > perPage)
              DemoChoice(
                label:
                    '${t.onboardingDemoWords} ${_tray + 1}/${(words.length / perPage).ceil()}',
                icon: Icons.chevron_right,
                onTap: () => setState(
                  () => _tray = (_tray + 1) % (words.length / perPage).ceil(),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
