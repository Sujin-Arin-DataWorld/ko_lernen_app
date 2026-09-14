import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/sarangchae_construction.dart';
import 'card.dart';
import 'chip.dart';
import 'progress.dart';
import 'tokens.dart';
import 'updating_scene.dart';

/// Future-state artwork used only by the no-progression onboarding preview.
const String kIlDuV3PreviewAsset =
    'assets/illustrations/hanok/ildu_v3_preview.png';

/// Compatibility preview for surfaces that do not yet own a course mastery
/// snapshot. Production Hanok destinations use [SarangchaeStageArtwork].
class HanokV3Preview extends StatelessWidget {
  const HanokV3Preview({
    super.key,
    required this.message,
    this.fit = BoxFit.contain,
  });

  final String message;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    return SoriUpdatingScene(
      asset: kIlDuV3PreviewAsset,
      message: message,
      alignment: Alignment.center,
      assetFit: fit,
      backdropColor: surfaces.surfaceAlt,
    );
  }
}

class SarangchaeStageArtwork extends StatelessWidget {
  const SarangchaeStageArtwork({
    super.key,
    required this.construction,
    required this.earnedStageCount,
    this.sequence,
  });

  final SarangchaeConstruction construction;
  final int earnedStageCount;
  final int? sequence;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final surfaces = SoriSurfaces.of(context);
    final earned = earnedStageCount
        .clamp(0, SarangchaeConstruction.stageCount)
        .toInt();
    final shown = (sequence ?? (earned == 0 ? 1 : earned))
        .clamp(1, SarangchaeConstruction.stageCount)
        .toInt();
    final stage = construction.stage(shown);
    final unlocked = shown <= earned;
    final image = Image.asset(
      stage.assetPath,
      key: ValueKey('sarangchae-stage-artwork-$shown'),
      fit: BoxFit.contain,
      alignment: Alignment.center,
      excludeFromSemantics: true,
    );
    return Semantics(
      image: true,
      label: unlocked
          ? t.sarangchaeStageUnlocked(shown)
          : t.sarangchaeStageLocked(shown),
      child: ClipRRect(
        borderRadius: SoriRadius.brLg,
        child: ColoredBox(
          color: surfaces.surfaceAlt,
          child: AnimatedSwitcher(
            duration: SoriMotion.reduceMotion(context)
                ? Duration.zero
                : SoriMotion.medium,
            child: Stack(
              key: ValueKey('sarangchae-stage-layer-$shown-$unlocked'),
              fit: StackFit.expand,
              children: [
                if (unlocked) image else Opacity(opacity: .24, child: image),
                if (!unlocked)
                  Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: surfaces.surface.withValues(alpha: .92),
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(Spacing.md),
                        child: Icon(Icons.lock_rounded, size: 30),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The shared live Sarangchae experience for the Stage tab, deep links, and
/// route-return reward receipt. Ownership always comes from completed units.
class SarangchaeConstructionExperience extends StatefulWidget {
  const SarangchaeConstructionExperience({
    super.key,
    required this.construction,
    required this.earnedStageCount,
    this.minimumSelectableStage = 1,
    this.showLockedStages = true,
    this.showArtwork = true,
    this.compact = false,
    this.onStageSelected,
  });

  final SarangchaeConstruction construction;
  final int earnedStageCount;
  final int minimumSelectableStage;
  final bool showLockedStages;
  final bool showArtwork;
  final bool compact;
  final ValueChanged<int>? onStageSelected;

  @override
  State<SarangchaeConstructionExperience> createState() =>
      _SarangchaeConstructionExperienceState();
}

class _SarangchaeConstructionExperienceState
    extends State<SarangchaeConstructionExperience> {
  late int _selectedSequence;
  String? _languageOverride;

  int get _earned => widget.earnedStageCount
      .clamp(0, SarangchaeConstruction.stageCount)
      .toInt();

  @override
  void initState() {
    super.initState();
    _selectedSequence = _earned == 0
        ? 1
        : _earned
              .clamp(
                widget.minimumSelectableStage,
                SarangchaeConstruction.stageCount,
              )
              .toInt();
  }

  @override
  void didUpdateWidget(covariant SarangchaeConstructionExperience oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldEarned = oldWidget.earnedStageCount
        .clamp(0, SarangchaeConstruction.stageCount)
        .toInt();
    if (_earned > oldEarned && _selectedSequence == oldEarned) {
      _selectedSequence = _earned;
    } else if (_selectedSequence > _earned && _earned > 0) {
      _selectedSequence = _earned;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    final appLanguage = Localizations.localeOf(context).languageCode;
    final language = _languageOverride ?? appLanguage;
    final stage = widget.construction.stage(_selectedSequence);
    final first = widget.minimumSelectableStage
        .clamp(1, SarangchaeConstruction.stageCount)
        .toInt();
    final last = widget.showLockedStages
        ? SarangchaeConstruction.stageCount
        : _earned;

    return Column(
      key: const ValueKey('sarangchae-construction-experience'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.sarangchaeConstructionProgress(
            _earned,
            SarangchaeConstruction.stageCount,
          ),
          style: tt.label,
        ),
        const SizedBox(height: Spacing.sm),
        SoriProgressBar(
          value: _earned / SarangchaeConstruction.stageCount,
          thickness: 10,
          color: SoriColors.success,
          animated: true,
        ),
        if (widget.showArtwork) ...[
          const SizedBox(height: Spacing.lg),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: SarangchaeStageArtwork(
              construction: widget.construction,
              earnedStageCount: _earned,
              sequence: _selectedSequence,
            ),
          ),
        ],
        const SizedBox(height: Spacing.lg),
        Text(t.sarangchaeConstructionStages, style: tt.h3),
        const SizedBox(height: Spacing.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: DropdownButtonFormField<String>(
              key: const ValueKey('sarangchae-lesson-language'),
              initialValue: language,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: t.sarangchaeLessonLanguage,
              ),
              items: [
                DropdownMenuItem(
                  value: 'ko',
                  child: Text(t.sarangchaeLanguageKorean),
                ),
                DropdownMenuItem(
                  value: 'de',
                  child: Text(t.sarangchaeLanguageGerman),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(t.sarangchaeLanguageEnglish),
                ),
              ],
              onChanged: (value) => setState(() => _languageOverride = value),
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        if (last >= first)
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              for (var sequence = first; sequence <= last; sequence++)
                SoriChip(
                  key: ValueKey('sarangchae-stage-choice-$sequence'),
                  label: '$sequence',
                  semanticLabel: sequence <= _earned
                      ? t.sarangchaeStageUnlocked(sequence)
                      : t.sarangchaeStageLocked(sequence),
                  icon: sequence <= _earned ? null : Icons.lock_rounded,
                  selected: sequence == _selectedSequence,
                  variant: SoriChipVariant.outlined,
                  minInteractiveHeight: 48,
                  onTap: sequence <= _earned
                      ? () {
                          setState(() => _selectedSequence = sequence);
                          widget.onStageSelected?.call(sequence);
                        }
                      : null,
                ),
            ],
          ),
        if (_earned == 0) ...[
          const SizedBox(height: Spacing.lg),
          Text(t.sarangchaeStartMission),
        ] else ...[
          const SizedBox(height: Spacing.lg),
          SoriCard(
            variant: widget.compact
                ? SoriCardVariant.compact
                : SoriCardVariant.hanji,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stage.term} · ${stage.text('gloss', language)}',
                  style: tt.label.copyWith(color: SoriColors.accent),
                ),
                const SizedBox(height: Spacing.xs),
                Text(stage.text('title', language), style: tt.h3),
                const SizedBox(height: Spacing.sm),
                Text(stage.text('caption', language)),
                if (widget.compact)
                  Material(
                    color: Colors.transparent,
                    child: ExpansionTile(
                      key: ValueKey(
                        'sarangchae-stage-detail-$_selectedSequence',
                      ),
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(
                        bottom: Spacing.sm,
                      ),
                      title: Text(
                        stage.text('question', language),
                        style: tt.label,
                      ),
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(stage.text('body', language)),
                        ),
                      ],
                    ),
                  )
                else ...[
                  const SizedBox(height: Spacing.md),
                  Text(stage.text('question', language), style: tt.label),
                  const SizedBox(height: Spacing.xs),
                  Text(stage.text('body', language)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
