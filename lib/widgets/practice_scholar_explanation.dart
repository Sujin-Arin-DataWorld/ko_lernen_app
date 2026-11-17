import 'package:flutter/material.dart';
import 'practice_magic.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/haptic_service.dart';
import '../services/storage_service.dart';
import 'practice_scholar_clip.dart';
import 'practice_scholar_art.dart';
import 'practice_motion.dart';
import 'sori/button.dart';
import 'sori/card.dart';
import 'sori/tokens.dart';
import 'sori/tiger_video.dart';

/// A user-opened paper surface and the approved, full-body fan gesture.
/// Replaying the silent gesture does not create a learning attempt.
class PracticeScholarExplanation extends StatefulWidget {
  const PracticeScholarExplanation({
    super.key,
    required this.child,
    required this.requestId,
    required this.play,
    this.onRequested,
  });

  final Widget child;
  final int requestId;
  final bool play;
  final VoidCallback? onRequested;

  @override
  State<PracticeScholarExplanation> createState() =>
      _PracticeScholarExplanationState();
}

class _PracticeScholarExplanationState
    extends State<PracticeScholarExplanation> {
  int _replays = 0;
  bool _playing = false;
  late bool _hasPlayed;

  @override
  void initState() {
    super.initState();
    _playing = widget.play;
    _hasPlayed = widget.play;
    HapticService.preferencesChanged.addListener(_preferencesChanged);
  }

  void _preferencesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    HapticService.preferencesChanged.removeListener(_preferencesChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(PracticeScholarExplanation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.requestId != oldWidget.requestId && widget.play) {
      _playing = true;
      _hasPlayed = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final canPlay =
        !Storage.reducedMotion &&
        !MediaQuery.disableAnimationsOf(context) &&
        TigerStageVideo.videoReady &&
        Theme.of(context).brightness == Brightness.light;
    final stage = PracticeViewportGate(
      requireFullVisibility: true,
      child: SizedBox(
        width: 144,
        height: 256,
        child: !_hasPlayed
            ? const PracticeScholarArt(pose: PracticeScholarPose.point)
            : PracticeScholarClip(
                key: ValueKey('fan-${widget.requestId}-$_replays'),
                play: widget.play || _replays > 0,
                explaining: true,
                onRequested: widget.onRequested,
                onFinished: () {
                  if (mounted) {
                    setState(() => _playing = false);
                  }
                },
              ),
      ),
    );
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          container: true,
          header: true,
          child: Text(
            t.practiceEffect,
            style: SoriTextTheme.of(context).menuItem,
          ),
        ),
      ],
    );
    final card = SoriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < SoriBreakpoints.contentActionStack ||
                  MediaQuery.textScalerOf(context).scale(16) > 24) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    heading,
                    Center(child: stage),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  stage,
                  const SizedBox(width: Spacing.md),
                  Expanded(child: heading),
                ],
              );
            },
          ),
          if (canPlay) ...[
            const SizedBox(height: Spacing.lg),
            SoriButton.outlined(
              key: const ValueKey('scholar-replay'),
              label: t.practiceReplayGesture,
              icon: Icons.replay_rounded,
              fullWidth: true,
              onTap: _playing
                  ? null
                  : () => setState(() {
                      _playing = true;
                      _hasPlayed = true;
                      _replays++;
                    }),
            ),
          ],
          const SizedBox(height: Spacing.xl),
          Semantics(container: true, child: widget.child),
        ],
      ),
    );
    return PracticeMotionSurface(
      key: ValueKey(widget.requestId),
      enter: true,
      child: PracticeMagicFrame(pulse: widget.requestId, child: card),
    );
  }
}
