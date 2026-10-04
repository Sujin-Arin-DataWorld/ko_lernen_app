import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/practice_history.dart';
import '../models/scenario.dart' show LocalizedText;
import '../models/scenario_character.dart';
import '../models/smalltalk_context_case.dart';
import '../services/practice_history_store.dart';
import '../services/smalltalk_context_catalog.dart';
import '../services/storage_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/practice_guide.dart';
import '../widgets/practice_dokkaebi_art.dart';
import '../widgets/practice_scholar_art.dart';
import '../widgets/practice_motion.dart';
import '../widgets/practice_layout.dart';
import '../widgets/practice_scholar_explanation.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/speakable.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';

class SmalltalkContextScreen extends StatefulWidget {
  const SmalltalkContextScreen({
    super.key,
    this.request = const SmalltalkContextRequest(),
    this.loadCases,
    this.saveAttempt,
  });
  final SmalltalkContextRequest request;
  final Future<List<SmalltalkContextCase>> Function()? loadCases;
  final Future<void> Function(
    PracticeSource,
    PracticeAttempt,
    PracticeHistorySession,
  )?
  saveAttempt;
  @override
  State<SmalltalkContextScreen> createState() => _SmalltalkContextScreenState();
}

class _SmalltalkContextScreenState extends State<SmalltalkContextScreen> {
  final _session = PracticeHistoryStore.session();
  List<SmalltalkContextCase> _cases = [];
  SmalltalkContextCase? _case;
  SmalltalkContextIntent? _intent;
  SmalltalkContextExpression? _expression;
  List<String> _pool = [];
  final List<int> _selected = [];
  bool _loading = true,
      _busy = false,
      _transfer = false,
      _help = false,
      _complete = false;
  String? _feedback;
  Future<void> Function()? _retry;
  PracticeAttempt? _attempt;
  bool _effectVisible = false;
  bool _playScholar = false;
  int _scholarGesture = 0;
  final _effectAnchor = GlobalKey();
  final _answerKey = GlobalKey();
  final _completionAnchor = GlobalKey();
  final _scroll = ScrollController();
  final Map<int, GlobalKey> _tokenKeys = {};
  final Set<OverlayEntry> _flights = {};
  int _flightEpoch = 0;
  bool get _locked =>
      _busy ||
      _complete ||
      !_session.isCurrent ||
      (_retry != null && _attempt != null);
  void _edit(VoidCallback action) {
    if (_locked) {
      return;
    }
    setState(action);
  }

  String get _lang => Localizations.localeOf(context).languageCode;
  SmalltalkContextScene get _scene => _transfer ? _case!.transfer : _case!.base;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cases =
          await (widget.loadCases?.call() ?? SmalltalkContextCatalog.load());
      if (!mounted || !_session.isCurrent) {
        return;
      }
      setState(() {
        _cases = cases;
        _loading = false;
      });
      if (widget.request.caseId != null) {
        final requested = cases
            .where((c) => c.id == widget.request.caseId)
            .firstOrNull;
        if (requested == null) {
          setState(() => _feedback = AppL10n.of(context).practiceUnavailable);
        } else {
          await _open(requested, widget.request.transfer);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _feedback = AppL10n.of(context).practiceReadError;
          _retry = _load;
        });
      }
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy || !_session.isCurrent) {
      return;
    }
    setState(() {
      _busy = true;
      _retry = null;
      _feedback = null;
    });
    try {
      _session.assertCurrent();
      await action();
    } catch (_) {
      if (mounted) {
        setState(() {
          _feedback = AppL10n.of(context).practiceSaveFailed;
          _retry = action;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _open(SmalltalkContextCase value, bool transfer) => _run(
    () async {
      await PracticeHistoryStore.recordViewed(value.source, session: _session);
      if (!mounted || !_session.isCurrent) {
        return;
      }
      setState(() {
        _clearFlights();
        _case = value;
        _transfer = transfer;
        _intent = null;
        _expression = null;
        _effectVisible = false;
        _playScholar = false;
        _scholarGesture = 0;
        _selected.clear();
        _complete = false;
        _help = !transfer;
        _attempt = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
      });
    },
  );
  void _pickExpression(SmalltalkContextExpression expression) {
    if (_locked) {
      return;
    }
    final tokens = expression.followUpTokens.toList();
    _clearFlights();
    _tokenKeys.clear();
    // Stable presentation preserves duplicate token occurrences and retries.
    if (tokens.length > 1) {
      final first = tokens[0];
      tokens[0] = tokens[1];
      tokens[1] = first;
    }
    setState(() {
      _expression = expression;
      _effectVisible = false;
      _playScholar = false;
      _scholarGesture = 0;
      _pool = tokens;
      _selected.clear();
      _attempt = null;
      _feedback = null;
      _retry = null;
    });
  }

  void _showEffect() {
    if (_locked) {
      return;
    }
    final expression = _expression;
    _edit(() {
      _help = true;
      _effectVisible = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final anchor = _effectAnchor.currentContext;
      if (!mounted || _locked || anchor == null || _expression != expression) {
        return;
      }
      await Scrollable.ensureVisible(
        anchor,
        alignment: 0.08,
        duration: Storage.reducedMotion
            ? Duration.zero
            : SoriMotion.respect(context, SoriMotion.medium),
      );
      if (mounted && !_locked && _expression == expression) {
        setState(() {
          _scholarGesture++;
          _playScholar = true;
        });
      }
    });
  }

  void _clearFlights() {
    _flightEpoch++;
    for (final entry in _flights) {
      entry.remove();
      entry.dispose();
    }
    _flights.clear();
  }

  void _chooseToken(int index) {
    if (_locked || _selected.contains(index)) return;
    final render = _tokenKeys[index]?.currentContext?.findRenderObject();
    final from = render is RenderBox && render.hasSize
        ? render.localToGlobal(Offset.zero) & render.size
        : null;
    final epoch = _flightEpoch;
    _edit(() => _selected.add(index));
    if (from == null ||
        Storage.reducedMotion ||
        MediaQuery.disableAnimationsOf(context)) {
      return;
    }
    final position = _selected.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _locked ||
          epoch != _flightEpoch ||
          position != _selected.length) {
        return;
      }
      final paragraph = _answerKey.currentContext?.findRenderObject();
      if (paragraph is! RenderParagraph || !paragraph.hasSize) return;
      final answer = _selected.map((i) => _pool[i]).join(' ');
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(
          baseOffset: answer.length - _pool[index].length,
          extentOffset: answer.length,
        ),
      );
      if (boxes.isEmpty) return;
      final to = boxes.last.toRect().shift(
        paragraph.localToGlobal(Offset.zero),
      );
      final overlay = Overlay.of(context);
      final overlayBox = overlay.context.findRenderObject() as RenderBox;
      final offset = overlayBox.localToGlobal(Offset.zero);
      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (context) => PracticeTokenFlight(
          from: from.shift(-offset),
          to: to.shift(-offset),
          text: _pool[index],
          style: SoriTextTheme.of(context).body,
          visible: () =>
              mounted &&
              (ModalRoute.of(this.context)?.isCurrent ?? true) &&
              TickerMode.valuesOf(this.context).enabled &&
              (WidgetsBinding.instance.lifecycleState == null ||
                  WidgetsBinding.instance.lifecycleState ==
                      AppLifecycleState.resumed) &&
              !Storage.reducedMotion &&
              !MediaQuery.disableAnimationsOf(this.context),
          onFinished: () {
            if (_flights.remove(entry)) {
              entry.remove();
              entry.dispose();
            }
          },
        ),
      );
      _flights.add(entry);
      overlay.insert(entry);
    });
  }

  Future<void> _check() async {
    final t = AppL10n.of(context);
    if (_locked) {
      return;
    }
    if (_transfer &&
        _intent!.id != _scene.requiredIntentId &&
        !_scene.acceptedExpressionIds.contains(_expression!.id)) {
      setState(() => _feedback = t.practiceIntentRetry);
      return;
    }
    if (_selected.map((index) => _pool[index]).join(' ') !=
        _expression!.followUp.ko) {
      setState(() => _feedback = t.practiceOrderRetry);
      return;
    }
    final at = DateTime.now().toUtc();
    _attempt ??= PracticeAttempt(
      id: 'context:${at.microsecondsSinceEpoch}',
      at: at,
      variant: _transfer ? 'transfer' : 'base',
      completed: true,
      expressionId: _expression!.id,
      hints: _help ? {'expression': 1} : const {},
    );
    final source = _case!.source;
    final attempt = _attempt!;
    await _run(() async {
      if (widget.saveAttempt case final save?) {
        await save(source, attempt, _session);
      } else {
        await PracticeHistoryStore.recordAttempt(
          source,
          attempt,
          session: _session,
        );
      }
      if (mounted && _session.isCurrent) {
        _clearFlights();
        setState(() => _complete = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final anchor = _completionAnchor.currentContext;
          if (mounted && _complete && anchor != null) {
            unawaited(
              Scrollable.ensureVisible(
                anchor,
                alignment: .1,
                duration: Storage.reducedMotion
                    ? Duration.zero
                    : SoriMotion.respect(context, SoriMotion.slow),
              ),
            );
          }
        });
      }
    });
  }

  Widget _text(LocalizedText value, {bool korean = false}) => Text(
    korean ? value.ko : value.pick(_lang),
    style: SoriTextTheme.of(context).body,
  );
  Widget _dialog(LocalizedText value) {
    final profile = ScenarioCharacterCatalog.profileFor(_scene.characterId);
    return PracticeMotionSurface(
      key: ValueKey('dialog-${_scene.characterId}-${value.ko}'),
      enter: true,
      child: PracticeDialogueBubble(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              profile?.nameFor(_lang) ?? _scene.characterId,
              style: SoriTextTheme.of(context).eyebrow,
            ),
            const SizedBox(height: Spacing.sm),
            Text(value.ko, style: SoriTextTheme.of(context).h3),
            const SizedBox(height: Spacing.sm),
            _text(value),
            const SizedBox(height: Spacing.lg),
            SoriButton.ghost(
              label: AppL10n.of(context).contentLearningAudio,
              icon: Icons.volume_up_outlined,
              onTap: () =>
                  SoriSpeech.speak(value.ko, voice: profile?.voice ?? 'female'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _effect(AppL10n t) => Padding(
    key: _effectAnchor,
    padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
    child: PracticeScholarExplanation(
      key: ValueKey('scholar-effect-${_expression!.id}-$_complete'),
      requestId: _scholarGesture,
      play: _playScholar && !_complete,
      onRequested: () {
        if (mounted && _playScholar) {
          setState(() => _playScholar = false);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _expression!.grammarValid
                ? t.practiceGrammarCorrect
                : _expression!.effect.pick(_lang),
            style: SoriTextTheme.of(context).meta,
          ),
          const SizedBox(height: Spacing.sm),
          _text(_expression!.effect),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriStudyFrame(
      title: t.practiceToneTitle,
      homeEscape: SoriHomeEscape(
        confirmWhen: !_complete && (_expression != null || _busy),
      ),
      onLeave: () {
        _clearFlights();
        unawaited(SoriSpeech.stop());
      },
      bottomNavigationBar: _actionFooter(t),
      child: _loading
          ? const AppLoading()
          : NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification &&
                        notification.dragDetails != null ||
                    notification is UserScrollNotification &&
                        notification.direction != ScrollDirection.idle) {
                  _clearFlights();
                }
                return false;
              },
              child: ListView(
                controller: _scroll,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_feedback != null &&
                          (_case == null || _expression == null || _complete))
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _feedback!,
                            style: SoriTextTheme.of(context).body,
                          ),
                        ),
                      if (_retry != null)
                        PracticeRaisedAction(
                          child: SoriButton.outlined(
                            label: t.practiceRetrySave,
                            onTap: _busy
                                ? null
                                : () {
                                    final retry = _retry;
                                    if (_busy ||
                                        retry == null ||
                                        !_session.isCurrent) {
                                      return;
                                    }
                                    if (_case == null && _cases.isEmpty) {
                                      setState(() {
                                        _loading = true;
                                        _retry = null;
                                      });
                                      unawaited(_load());
                                    } else {
                                      unawaited(_run(retry));
                                    }
                                  },
                          ),
                        ),
                      if (!_session.isCurrent) Text(t.practiceUnavailable),
                      if (_case == null) ...[
                        PracticeGuide(
                          dokkaebi: false,
                          scholarPose: PracticeScholarPose.welcome,
                          child: Text(
                            t.practiceToneTitle,
                            style: SoriTextTheme.of(context).h2,
                          ),
                        ),
                        const SizedBox(height: Spacing.lg),
                        for (final c in _cases.where(
                          (c) =>
                              widget.request.level == null ||
                              c.level == widget.request.level,
                        ))
                          Padding(
                            padding: const EdgeInsets.only(bottom: Spacing.md),
                            child: PracticeMotionSurface(
                              enter: true,
                              child: SoriCard(
                                key: ValueKey('context-case-${c.id}'),
                                onTap: _busy ? null : () => _open(c, false),
                                semanticLabel: c.title.pick(_lang),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      c.level.toUpperCase(),
                                      style: SoriTextTheme.of(context).eyebrow,
                                    ),
                                    Text(
                                      c.title.pick(_lang),
                                      style: SoriTextTheme.of(context).h3,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ] else ...[
                        PracticeGuide(
                          dokkaebi: false,
                          scholarPose: _complete
                              ? PracticeScholarPose.calm
                              : _expression != null
                              ? PracticeScholarPose.point
                              : _intent != null
                              ? PracticeScholarPose.thinking
                              : PracticeScholarPose.inviting,
                          child: Text(
                            _case!.title.pick(_lang),
                            style: SoriTextTheme.of(context).h2,
                          ),
                        ),
                        const SizedBox(height: Spacing.lg),
                        if (_expression == null) ...[
                          Text(
                            t.practiceSituation,
                            style: SoriTextTheme.of(context).eyebrow,
                          ),
                          const SizedBox(height: Spacing.sm),
                          _text(_scene.context),
                          const SizedBox(height: Spacing.xl),
                          _dialog(_scene.prompt),
                        ] else
                          ExpansionTile(
                            key: ValueKey(
                              'context-situation-${_scene.characterId}-${_scene.prompt.ko}',
                            ),
                            tilePadding: EdgeInsets.zero,
                            title: Text(
                              t.practiceSituation,
                              style: SoriTextTheme.of(context).meta,
                            ),
                            children: [
                              _text(_scene.context),
                              const SizedBox(height: Spacing.lg),
                              _dialog(_scene.prompt),
                            ],
                          ),
                        const SizedBox(height: Spacing.xxl),
                        if (_complete) ...[
                          PracticeMotionSurface(
                            key: _completionAnchor,
                            enter: true,
                            interactive: false,
                            child: PracticeGuide(
                              dokkaebi: true,
                              dokkaebiPose: PracticeDokkaebiPose.celebrate,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      t.practiceSaved,
                                      key: const ValueKey('context-complete'),
                                      style: SoriTextTheme.of(context).h2,
                                    ),
                                  ),
                                  const SizedBox(height: Spacing.md),
                                  Text(
                                    _help
                                        ? t.practiceAssisted
                                        : t.practiceIndependent,
                                    style: SoriTextTheme.of(context).body,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: Spacing.md),
                          _effect(t),
                          PracticeActionArea(
                            children: [
                              SoriButton.ghost(
                                label: t.practiceBackCases,
                                onTap: () => setState(() => _case = null),
                              ),
                            ],
                          ),
                        ] else if (_intent == null) ...[
                          Text(
                            t.practiceIntent,
                            style: SoriTextTheme.of(context).h3,
                          ),
                          for (final intent in _case!.intents)
                            Padding(
                              padding: const EdgeInsets.only(top: Spacing.lg),
                              child: PracticeRaisedAction(
                                child: SoriButton.outlined(
                                  key: ValueKey('context-intent-${intent.id}'),
                                  label: intent.label.pick(_lang),
                                  fullWidth: true,
                                  onTap: _busy || !_session.isCurrent
                                      ? null
                                      : () => _edit(() => _intent = intent),
                                ),
                              ),
                            ),
                        ] else if (_expression == null) ...[
                          Text(
                            t.practiceExpression,
                            style: SoriTextTheme.of(context).h3,
                          ),
                          for (final e in _intent!.expressions)
                            Padding(
                              padding: const EdgeInsets.only(top: Spacing.lg),
                              child: PracticeRaisedAction(
                                child: SoriButton.outlined(
                                  key: ValueKey('context-expression-${e.id}'),
                                  label: '${e.text.ko}\n${e.text.pick(_lang)}',
                                  fullWidth: true,
                                  onTap: () => _pickExpression(e),
                                ),
                              ),
                            ),
                          SoriButton.ghost(
                            label: t.practiceChooseAgain,
                            onTap: () => _edit(() => _intent = null),
                          ),
                        ] else ...[
                          Text(
                            _expression!.text.ko,
                            style: SoriTextTheme.of(context).h3,
                          ),
                          const SizedBox(height: Spacing.xl),
                          if (_effectVisible)
                            _effect(t)
                          else
                            PracticeRaisedAction(
                              child: SoriButton.outlined(
                                key: const ValueKey('context-help'),
                                label: t.practiceShowEffect,
                                onTap: _locked ? null : _showEffect,
                              ),
                            ),
                          const SizedBox(height: Spacing.xl),
                          _dialog(_expression!.partnerReply),
                          const SizedBox(height: Spacing.xxl),
                          Text(
                            t.practiceAssemble,
                            style: SoriTextTheme.of(context).h3,
                          ),
                          const SizedBox(height: Spacing.sm),
                          _text(_expression!.followUp),
                          const SizedBox(height: Spacing.xl),
                          SoriCard(
                            selectable: true,
                            selected: _selected.isNotEmpty,
                            padding: const EdgeInsets.all(Spacing.xl),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 48),
                              child: Semantics(
                                liveRegion: true,
                                child: Text(
                                  key: _answerKey,
                                  _selected.map((i) => _pool[i]).join(' '),
                                  style: SoriTextTheme.of(context).h2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: Spacing.xl),
                          Wrap(
                            spacing: Spacing.sm,
                            runSpacing: Spacing.sm,
                            children: [
                              for (var index = 0; index < _pool.length; index++)
                                KeyedSubtree(
                                  key: _tokenKeys.putIfAbsent(
                                    index,
                                    GlobalKey.new,
                                  ),
                                  child: IntrinsicWidth(
                                    child: PracticeRaisedAction(
                                      child: SoriButton.outlined(
                                        key: ValueKey('context-token-$index'),
                                        label: _pool[index],
                                        onTap:
                                            _locked || _selected.contains(index)
                                            ? null
                                            : () => _chooseToken(index),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          PracticeActionArea(
                            children: [
                              SoriButton.ghost(
                                label: t.practiceReset,
                                onTap: _locked
                                    ? null
                                    : () {
                                        _clearFlights();
                                        _edit(() => _selected.clear());
                                      },
                              ),
                              SoriButton.ghost(
                                label: t.practiceChooseAgain,
                                onTap: _locked
                                    ? null
                                    : () => _edit(() {
                                        _intent = null;
                                        _expression = null;
                                        _attempt = null;
                                        _feedback = null;
                                      }),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget? _actionFooter(AppL10n t) {
    if (_loading || _case == null || _expression == null) return null;
    return SafeArea(
      top: false,
      child: Container(
        color: SoriCard.resolvedBackground(context),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: soriStudyContentMaxWidth(
                MediaQuery.sizeOf(context).width - 32,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_complete && _feedback != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _feedback!,
                      style: SoriTextTheme.of(context).body,
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                ],
                PracticeRaisedAction(
                  primary: true,
                  child: SoriButton.filled(
                    key: _complete ? null : const ValueKey('context-check'),
                    label: _complete ? t.practiceTransfer : t.practiceCheck,
                    loading: _busy,
                    fullWidth: true,
                    onTap: _complete
                        ? (_busy ? null : () => _open(_case!, true))
                        : (_locked || _selected.length != _pool.length
                              ? null
                              : _check),
                  ),
                ),
                if (_complete) ...[
                  const SizedBox(height: Spacing.md),
                  PracticeRaisedAction(
                    child: SoriButton.outlined(
                      label: t.practiceToSarangbang,
                      fullWidth: true,
                      onTap: () =>
                          Navigator.of(context).pushNamed('/sarangbang'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _clearFlights();
    _scroll.dispose();
    unawaited(SoriSpeech.stop());
    super.dispose();
  }
}
