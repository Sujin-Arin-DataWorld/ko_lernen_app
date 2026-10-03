import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/practice_history.dart';
import '../models/scenario.dart' show LocalizedText;
import '../models/scenario_character.dart';
import '../models/smalltalk_context_case.dart';
import '../services/practice_history_store.dart';
import '../services/smalltalk_context_catalog.dart';
import '../widgets/app_loading.dart';
import '../widgets/practice_guide.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/speakable.dart';
import '../widgets/sori/study_frame.dart';
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
        _case = value;
        _transfer = transfer;
        _intent = null;
        _expression = null;
        _selected.clear();
        _complete = false;
        _help = !transfer;
        _attempt = null;
      });
    },
  );
  void _pickExpression(SmalltalkContextExpression expression) {
    if (_locked) {
      return;
    }
    final tokens = expression.followUpTokens.toList();
    // Stable presentation preserves duplicate token occurrences and retries.
    if (tokens.length > 1) {
      final first = tokens[0];
      tokens[0] = tokens[1];
      tokens[1] = first;
    }
    setState(() {
      _expression = expression;
      _pool = tokens;
      _selected.clear();
      _attempt = null;
      _feedback = null;
      _retry = null;
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
        setState(() => _complete = true);
      }
    });
  }

  Widget _text(LocalizedText value, {bool korean = false}) => Text(
    korean ? value.ko : value.pick(_lang),
    style: SoriTextTheme.of(context).body,
  );
  Widget _dialog(LocalizedText value) {
    final profile = ScenarioCharacterCatalog.profileFor(_scene.characterId);
    return SoriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            profile?.nameFor(_lang) ?? _scene.characterId,
            style: SoriTextTheme.of(context).eyebrow,
          ),
          Text(value.ko, style: SoriTextTheme.of(context).h3),
          _text(value),
          SoriButton.ghost(
            label: AppL10n.of(context).contentLearningAudio,
            icon: Icons.volume_up_outlined,
            onTap: () =>
                SoriSpeech.speak(value.ko, voice: profile?.voice ?? 'female'),
          ),
        ],
      ),
    );
  }

  Widget _effect(AppL10n t) => PracticeGuide(
    dokkaebi: false,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.practiceEffect, style: SoriTextTheme.of(context).h3),
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
  );
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriStudyFrame(
      title: t.practiceToneTitle,
      homeEscape: SoriHomeEscape(
        confirmWhen: !_complete && (_expression != null || _busy),
      ),
      onLeave: () => unawaited(SoriSpeech.stop()),
      child: _loading
          ? const AppLoading()
          : ListView(
              children: [
                if (_feedback != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _feedback!,
                      style: SoriTextTheme.of(context).body,
                    ),
                  ),
                if (_retry != null)
                  SoriButton.outlined(
                    label: t.practiceRetrySave,
                    onTap: _busy
                        ? null
                        : () {
                            final retry = _retry;
                            if (_busy || retry == null || !_session.isCurrent) {
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
                if (!_session.isCurrent) Text(t.practiceUnavailable),
                if (_case == null) ...[
                  PracticeGuide(
                    dokkaebi: false,
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
                      child: SoriCard(
                        key: ValueKey('context-case-${c.id}'),
                        onTap: _busy ? null : () => _open(c, false),
                        semanticLabel: c.title.pick(_lang),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                ] else ...[
                  Text(
                    _case!.title.pick(_lang),
                    style: SoriTextTheme.of(context).h2,
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    t.practiceSituation,
                    style: SoriTextTheme.of(context).eyebrow,
                  ),
                  _text(_scene.context),
                  const SizedBox(height: Spacing.md),
                  _dialog(_scene.prompt),
                  const SizedBox(height: Spacing.lg),
                  if (_complete) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        t.practiceSaved,
                        key: const ValueKey('context-complete'),
                        style: SoriTextTheme.of(context).h2,
                      ),
                    ),
                    Text(
                      _help ? t.practiceAssisted : t.practiceIndependent,
                      style: SoriTextTheme.of(context).body,
                    ),
                    const SizedBox(height: Spacing.md),
                    _effect(t),
                    SoriButton.filled(
                      label: t.practiceTransfer,
                      onTap: _busy ? null : () => _open(_case!, true),
                    ),
                    SoriButton.outlined(
                      label: t.practiceToSarangbang,
                      onTap: () =>
                          Navigator.of(context).pushNamed('/sarangbang'),
                    ),
                    SoriButton.ghost(
                      label: t.practiceBackCases,
                      onTap: () => setState(() => _case = null),
                    ),
                  ] else if (_intent == null) ...[
                    Text(t.practiceIntent, style: SoriTextTheme.of(context).h3),
                    for (final intent in _case!.intents)
                      Padding(
                        padding: const EdgeInsets.only(top: Spacing.md),
                        child: SoriButton.outlined(
                          key: ValueKey('context-intent-${intent.id}'),
                          label: intent.label.pick(_lang),
                          fullWidth: true,
                          onTap: _busy || !_session.isCurrent
                              ? null
                              : () => _edit(() => _intent = intent),
                        ),
                      ),
                  ] else if (_expression == null) ...[
                    Text(
                      t.practiceExpression,
                      style: SoriTextTheme.of(context).h3,
                    ),
                    for (final e in _intent!.expressions)
                      Padding(
                        padding: const EdgeInsets.only(top: Spacing.md),
                        child: SoriButton.outlined(
                          key: ValueKey('context-expression-${e.id}'),
                          label: '${e.text.ko}\n${e.text.pick(_lang)}',
                          fullWidth: true,
                          onTap: () => _pickExpression(e),
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
                    if (_help)
                      _effect(t)
                    else
                      SoriButton.outlined(
                        key: const ValueKey('context-help'),
                        label: t.practiceShowEffect,
                        onTap: _locked ? null : () => _edit(() => _help = true),
                      ),
                    const SizedBox(height: Spacing.md),
                    _dialog(_expression!.partnerReply),
                    Text(
                      t.practiceAssemble,
                      style: SoriTextTheme.of(context).h3,
                    ),
                    _text(_expression!.followUp),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _selected.map((i) => _pool[i]).join(' '),
                        style: SoriTextTheme.of(context).h2,
                      ),
                    ),
                    Wrap(
                      spacing: Spacing.sm,
                      runSpacing: Spacing.sm,
                      children: [
                        for (var index = 0; index < _pool.length; index++)
                          SoriButton.outlined(
                            key: ValueKey('context-token-$index'),
                            label: _pool[index],
                            onTap: _locked || _selected.contains(index)
                                ? null
                                : () => _edit(() => _selected.add(index)),
                          ),
                      ],
                    ),
                    const SizedBox(height: Spacing.md),
                    SoriButton.outlined(
                      label: t.practiceReset,
                      onTap: _locked
                          ? null
                          : () => _edit(() => _selected.clear()),
                    ),
                    SoriButton.filled(
                      key: const ValueKey('context-check'),
                      label: t.practiceCheck,
                      loading: _busy,
                      onTap: _locked || _selected.length != _pool.length
                          ? null
                          : _check,
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
                ],
              ],
            ),
    );
  }

  @override
  void dispose() {
    unawaited(SoriSpeech.stop());
    super.dispose();
  }
}
