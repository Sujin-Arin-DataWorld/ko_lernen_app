import 'package:flutter/material.dart';
import 'practice_character_clip.dart';

/// Approved silent fan gesture, with a matching full-body end pose.
class PracticeScholarClip extends StatelessWidget {
  const PracticeScholarClip({
    super.key,
    this.play = false,
    this.explaining = false,
    this.onRequested,
    this.onFinished,
  });
  static const videoAsset = 'assets/video/practice/hahoe_scholar_fan_hanji.mp4';
  static const startAsset = 'assets/video/practice/hahoe_scholar_fan_start.png';
  static const endAsset = 'assets/video/practice/hahoe_scholar_fan_end.png';
  final bool play, explaining;
  final VoidCallback? onRequested, onFinished;
  @override
  Widget build(BuildContext context) => PracticeCharacterClip(
    play: play,
    explaining: explaining,
    onRequested: onRequested,
    onFinished: onFinished,
    videoAsset: videoAsset,
    startAsset: startAsset,
    endAsset: endAsset,
  );
}
