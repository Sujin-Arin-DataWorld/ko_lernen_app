import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/korean_proofreading_service.dart';
import '../../services/scenario_writing_check_service.dart';
import 'button.dart';
import 'card.dart';
import 'mascot.dart';
import 'mascot_preference.dart';
import 'tokens.dart';

/// Optional, unscored writing practice shown after a role-play is complete.
///
/// The learner's text is never replaced. On-device proofreading is started
/// only by an explicit button press, and a downloadable model is downloaded
/// only by a second, separately labelled action.
class ScenarioWriteAfterRoleplayCard extends StatefulWidget {
  const ScenarioWriteAfterRoleplayCard({
    super.key,
    required this.evidence,
    this.service,
    this.previewCompanion,
  });

  final ScenarioWritingEvidence evidence;

  /// Test/integration seam. An injected service remains owned by the caller.
  final ScenarioWritingCheckService? service;

  /// Storage-free companion seam used by widget tests and the UX gallery.
  final CompanionPreference? previewCompanion;

  @override
  State<ScenarioWriteAfterRoleplayCard> createState() =>
      _ScenarioWriteAfterRoleplayCardState();
}

class _ScenarioWriteAfterRoleplayCardState
    extends State<ScenarioWriteAfterRoleplayCard> {
  late final TextEditingController _controller;
  late final ScenarioWritingCheckService _service;
  late final bool _ownsService;

  ScenarioWritingCheckOutcome? _outcome;
  bool _checking = false;
  bool _downloading = false;
  bool _showCompanion = false;

  bool get _busy => _checking || _downloading;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_onInputChanged);
    _ownsService = widget.service == null;
    _service = widget.service ?? ScenarioWritingCheckService();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onInputChanged)
      ..dispose();
    if (_ownsService) {
      unawaited(_service.close());
    }
    super.dispose();
  }

  void _onInputChanged() {
    if (_outcome == null && !_showCompanion) {
      setState(() {});
      return;
    }
    setState(() {
      _outcome = null;
      _showCompanion = false;
    });
  }

  Future<void> _check() async {
    if (_busy || _controller.text.trim().isEmpty) {
      return;
    }
    setState(() {
      _checking = true;
      _outcome = null;
      _showCompanion = false;
    });
    final outcome = await _service.check(
      input: _controller.text,
      evidence: widget.evidence,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _checking = false;
      _outcome = outcome;
    });
  }

  Future<void> _download() async {
    final outcome = _outcome;
    if (_busy ||
        outcome?.status != KoreanProofreadingStatus.downloadable ||
        _controller.text.trim().isEmpty) {
      return;
    }
    setState(() {
      _downloading = true;
      _showCompanion = false;
    });
    final downloaded = await _service.download(
      input: _controller.text,
      evidence: widget.evidence,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _downloading = false;
      _outcome = downloaded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final outcome = _outcome;
    final canCheck = !_busy && _controller.text.trim().isNotEmpty;

    return SoriCard(
      key: const ValueKey<String>('scenario-write-after-roleplay-card'),
      accent: SoriColors.highlight,
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            t.scenarioWriteAfterRoleplayTitle,
            style: SoriTextTheme.of(context).h3,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            t.scenarioWriteAfterRoleplayBody,
            style: SoriTextTheme.of(
              context,
            ).bodySmall.copyWith(color: s.textMuted),
          ),
          const SizedBox(height: Spacing.md),
          TextField(
            key: const ValueKey<String>('scenario-write-input'),
            controller: _controller,
            enabled: !_busy,
            minLines: 2,
            maxLines: 4,
            maxLength: KoreanProofreadingService.maxInputCodePoints,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: t.scenarioWriteAfterRoleplayInputLabel,
              hintText: t.scenarioWriteAfterRoleplayInputHint,
              alignLabelWithHint: true,
            ),
            onSubmitted: canCheck ? (_) => _check() : null,
          ),
          const SizedBox(height: Spacing.md),
          SoriButton.filled(
            key: const ValueKey<String>('scenario-write-check'),
            label: _checking
                ? t.scenarioWriteAfterRoleplayChecking
                : t.scenarioWriteAfterRoleplayCheck,
            icon: Icons.spellcheck_rounded,
            onTap: canCheck ? _check : null,
            size: SoriButtonSize.md,
            fullWidth: true,
          ),
          if (outcome != null) ...<Widget>[
            const SizedBox(height: Spacing.lg),
            _OutcomeContent(outcome: outcome),
            if (outcome.status == KoreanProofreadingStatus.downloadable) ...[
              const SizedBox(height: Spacing.md),
              SoriButton.outlined(
                key: const ValueKey<String>('scenario-write-download'),
                label: _downloading
                    ? t.scenarioWriteAfterRoleplayDownloading
                    : t.scenarioWriteAfterRoleplayDownload,
                icon: Icons.download_rounded,
                onTap: _downloading ? null : _download,
                fullWidth: true,
                maxLines: 2,
              ),
            ],
            if (outcome.facts.evidence.grammar != null) ...<Widget>[
              const SizedBox(height: Spacing.md),
              SoriButton.ghost(
                key: const ValueKey<String>('scenario-write-ask-companion'),
                label: t.scenarioWriteAfterRoleplayAskCompanion,
                icon: Icons.question_answer_outlined,
                onTap: () => setState(() {
                  _showCompanion = !_showCompanion;
                }),
                fullWidth: true,
                maxLines: 2,
              ),
              if (_showCompanion) ...<Widget>[
                const SizedBox(height: Spacing.sm),
                _CompanionExplanation(
                  facts: outcome.facts,
                  previewPreference: widget.previewCompanion,
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _OutcomeContent extends StatelessWidget {
  const _OutcomeContent({required this.outcome});

  final ScenarioWritingCheckOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return switch (outcome.kind) {
      ScenarioWritingCheckKind.suggestion => _SuggestionComparison(
        facts: outcome.facts,
      ),
      ScenarioWritingCheckKind.noChanges => _FeedbackNotice(
        key: const ValueKey<String>('scenario-write-no-changes'),
        icon: Icons.check_circle_outline_rounded,
        body: t.scenarioWriteAfterRoleplayNoChanges,
      ),
      ScenarioWritingCheckKind.downloadRequired => _FeedbackNotice(
        key: const ValueKey<String>('scenario-write-download-required'),
        icon: Icons.download_for_offline_outlined,
        body: outcome.status == KoreanProofreadingStatus.downloading
            ? t.scenarioWriteAfterRoleplayDownloading
            : t.scenarioWriteAfterRoleplayDownloadRequired,
      ),
      ScenarioWritingCheckKind.ready => _FeedbackNotice(
        key: const ValueKey<String>('scenario-write-ready'),
        icon: Icons.download_done_rounded,
        body: t.scenarioWriteAfterRoleplayReady,
      ),
      ScenarioWritingCheckKind.fallback => _GroundedFallback(
        facts: outcome.facts,
      ),
    };
  }
}

class _SuggestionComparison extends StatelessWidget {
  const _SuggestionComparison({required this.facts});

  final ScenarioWritingFeedbackFacts facts;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Column(
      key: const ValueKey<String>('scenario-write-comparison'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LayoutBuilder(
          builder: (context, constraints) {
            final useVerticalLayout =
                constraints.maxWidth < SoriBreakpoints.narrowPhone ||
                MediaQuery.textScalerOf(context).scale(1) > 1.3;
            final original = _TextPanel(
              label: t.scenarioWriteAfterRoleplayOriginalLabel,
              text: facts.originalText,
            );
            final suggestion = _TextPanel(
              label: t.scenarioWriteAfterRoleplaySuggestionLabel,
              text: facts.suggestion ?? facts.originalText,
              accent: SoriColors.success,
            );
            if (useVerticalLayout) {
              return Column(
                key: const ValueKey<String>(
                  'scenario-write-comparison-vertical',
                ),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  original,
                  const SizedBox(height: Spacing.sm),
                  suggestion,
                ],
              );
            }
            return Row(
              key: const ValueKey<String>(
                'scenario-write-comparison-horizontal',
              ),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: original),
                const SizedBox(width: Spacing.sm),
                Expanded(child: suggestion),
              ],
            );
          },
        ),
        if (facts.changes.isNotEmpty) ...<Widget>[
          const SizedBox(height: Spacing.md),
          _ValidatedChanges(changes: facts.changes),
          const SizedBox(height: Spacing.sm),
          Text(
            t.scenarioWriteAfterRoleplayChangeReasonUnavailable,
            key: const ValueKey<String>(
              'scenario-write-change-reason-boundary',
            ),
            style: SoriTextTheme.of(context).bodySmall.copyWith(
              color: SoriSurfaces.of(context).textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

class _ValidatedChanges extends StatelessWidget {
  const _ValidatedChanges({required this.changes});

  final List<KoreanProofreadingChange> changes;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    return Container(
      key: const ValueKey<String>('scenario-write-changes'),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: SoriSurfaces.of(context).surface,
        borderRadius: BorderRadius.circular(SoriRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            t.scenarioWriteAfterRoleplayChangesLabel,
            style: tt.caption.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: Spacing.sm),
          for (var index = 0; index < changes.length; index++) ...<Widget>[
            _ValidatedChangeRow(
              key: ValueKey<String>('scenario-write-change-$index'),
              change: changes[index],
            ),
            if (index + 1 < changes.length) const SizedBox(height: Spacing.sm),
          ],
        ],
      ),
    );
  }
}

class _ValidatedChangeRow extends StatelessWidget {
  const _ValidatedChangeRow({super.key, required this.change});

  final KoreanProofreadingChange change;

  String get _original =>
      change.originalText.isEmpty ? '∅' : change.originalText;

  String get _replacement =>
      change.replacementText.isEmpty ? '∅' : change.replacementText;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$_original → $_replacement',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: _ChangeToken(
                key: const ValueKey<String>('scenario-write-change-original'),
                text: _original,
                color: SoriColors.highlight,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Spacing.sm),
              child: Text('→'),
            ),
            Expanded(
              child: _ChangeToken(
                key: const ValueKey<String>(
                  'scenario-write-change-replacement',
                ),
                text: _replacement,
                color: SoriColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeToken extends StatelessWidget {
  const _ChangeToken({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(SoriRadius.xs),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      alignment: Alignment.center,
      child: SelectableText(
        text,
        textAlign: TextAlign.center,
        style: SoriTextTheme.of(
          context,
        ).bodySmall.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _TextPanel extends StatelessWidget {
  const _TextPanel({required this.label, required this.text, this.accent});

  final String label;
  final String text;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final color = accent ?? SoriColors.highlight;
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.08), s.surface),
        borderRadius: BorderRadius.circular(SoriRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: SoriTextTheme.of(
              context,
            ).caption.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: Spacing.xs),
          SelectableText(text, style: SoriTextTheme.of(context).body),
        ],
      ),
    );
  }
}

class _FeedbackNotice extends StatelessWidget {
  const _FeedbackNotice({super.key, required this.icon, required this.body});

  final IconData icon;
  final String body;

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(SoriRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: SoriColors.highlight),
          const SizedBox(width: Spacing.sm),
          Expanded(child: Text(body, style: SoriTextTheme.of(context).body)),
        ],
      ),
    );
  }
}

class _GroundedFallback extends StatelessWidget {
  const _GroundedFallback({required this.facts});

  final ScenarioWritingFeedbackFacts facts;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    return Container(
      key: const ValueKey<String>('scenario-write-fallback'),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: SoriSurfaces.of(context).surface,
        borderRadius: BorderRadius.circular(SoriRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(t.scenarioWriteAfterRoleplayFallbackTitle, style: tt.h3),
          const SizedBox(height: Spacing.xs),
          Text(t.scenarioWriteAfterRoleplayFallbackBody, style: tt.bodySmall),
          if (facts.evidence.references.isNotEmpty) ...<Widget>[
            const SizedBox(height: Spacing.md),
            for (final reference in facts.evidence.references)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.xs),
                child: Text(
                  reference.localizedMeaning.isEmpty
                      ? '• ${reference.korean}'
                      : '• ${reference.korean} — ${reference.localizedMeaning}',
                  style: tt.bodySmall,
                ),
              ),
          ],
          if (facts.evidence.grammar case final grammar?) ...<Widget>[
            const SizedBox(height: Spacing.md),
            _DeclaredGrammar(grammar: grammar),
          ],
        ],
      ),
    );
  }
}

class _DeclaredGrammar extends StatelessWidget {
  const _DeclaredGrammar({required this.grammar});

  final ScenarioWritingDeclaredGrammar grammar;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    return Column(
      key: const ValueKey<String>('scenario-write-declared-grammar'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          t.scenarioWriteAfterRoleplaySceneGrammarReference,
          style: tt.caption.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          grammar.title,
          style: tt.body.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: Spacing.xs),
        Text(grammar.explanation, style: tt.bodySmall),
      ],
    );
  }
}

class _CompanionExplanation extends StatelessWidget {
  const _CompanionExplanation({
    required this.facts,
    required this.previewPreference,
  });

  final ScenarioWritingFeedbackFacts facts;
  final CompanionPreference? previewPreference;

  @override
  Widget build(BuildContext context) => CompanionBuilder(
    previewPreference: previewPreference,
    builder: (context, kind) =>
        _CompanionExplanationContent(facts: facts, kind: kind),
    noneBuilder: (context) => _CompanionExplanationContent(facts: facts),
  );
}

class _CompanionExplanationContent extends StatelessWidget {
  const _CompanionExplanationContent({required this.facts, this.kind});

  final ScenarioWritingFeedbackFacts facts;
  final MascotKind? kind;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final intro = switch (kind) {
      MascotKind.tiger => t.bookStudyTaegoIntro,
      MascotKind.magpie => t.bookStudyJoyIntro,
      _ => t.bookStudyGenericIntro,
    };
    final name = switch (kind) {
      MascotKind.tiger => t.characterRomanTiger,
      MascotKind.magpie => t.characterRomanMagpie,
      _ => null,
    };
    return Container(
      key: const ValueKey<String>('scenario-write-companion-answer'),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: SoriSurfaces.of(context).surface,
        borderRadius: BorderRadius.circular(SoriRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (kind != null) ...<Widget>[
                Mascot(kind: kind!, emotion: MascotEmotion.thinking, size: 48),
                const SizedBox(width: Spacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name == null
                          ? t.scenarioWriteAfterRoleplayCompanionTitle
                          : '$name · ${t.scenarioWriteAfterRoleplayCompanionTitle}',
                      style: SoriTextTheme.of(context).h3,
                    ),
                    const SizedBox(height: 2),
                    Text(intro, style: SoriTextTheme.of(context).bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          // Character-neutral fact rendering: both companions receive and
          // display the exact same immutable fact DTO.
          _CompanionFacts(facts: facts),
        ],
      ),
    );
  }
}

class _CompanionFacts extends StatelessWidget {
  const _CompanionFacts({required this.facts});

  final ScenarioWritingFeedbackFacts facts;

  @override
  Widget build(BuildContext context) {
    final grammar = facts.evidence.grammar;
    if (grammar == null) {
      return const SizedBox.shrink();
    }
    return _DeclaredGrammar(grammar: grammar);
  }
}
