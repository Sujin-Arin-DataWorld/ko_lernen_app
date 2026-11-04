import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/approved_chrome_assets.dart';
import 'listening_figma_materials.dart';
import 'listening_object_art.dart';

/// Figma 56:35 / 56:74 / 56:113. Only presentation; callers own persistence.
class ListeningPaperPanel extends StatelessWidget {
  const ListeningPaperPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(color: Color(0xffb39a73), offset: Offset(0, 3)),
        BoxShadow(
          color: Color(0x3000211b),
          offset: Offset(0, 5),
          blurRadius: 6,
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: ListeningFigma.paper)),
          const Positioned.fill(child: ListeningPaperTexture()),
          Padding(
            padding: padding,
            child: DefaultTextStyle(
              style: const TextStyle(
                fontFamily: ListeningFigma.font,
                fontSize: 16,
                height: 1.4,
                color: ListeningFigma.ink,
              ),
              child: child,
            ),
          ),
        ],
      ),
    ),
  );
}

class ListeningStateTitle extends StatelessWidget {
  const ListeningStateTitle(this.title, {super.key, this.topicId});
  final String title;
  final String? topicId;
  @override
  Widget build(BuildContext context) => ListeningPaperPanel(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
    child: SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          if (topicId != null) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 54,
              height: 54,
              child: ListeningObjectArt(topicId!),
            ),
          ],
        ],
      ),
    ),
  );
}

class ListeningOutcomePanel extends StatelessWidget {
  const ListeningOutcomePanel({
    super.key,
    required this.topicId,
    required this.correct,
    required this.total,
    this.saving = false,
    this.failed = false,
    this.onRetry,
    this.onStay,
    this.review = false,
  });
  final String topicId;
  final int correct, total;
  final bool saving, failed, review;
  final VoidCallback? onRetry, onStay;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final recovery = saving || failed;
    final title = saving
        ? t.listeningRecoverySaving
        : failed
        ? t.listeningRecoverySaveFailed
        : review
        ? t.contentLearningReviewDone
        : t.listeningRecoveryDone;
    return ListeningPaperPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: saving
                      ? Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              value: MediaQuery.disableAnimationsOf(context)
                                  ? .75
                                  : null,
                              strokeWidth: 2,
                              color: const Color(0xffa9802f),
                            ),
                          ),
                        )
                      : Icon(
                          failed
                              ? Icons.priority_high_rounded
                              : Icons.check_rounded,
                          size: 42,
                          color: const Color(0xffa9802f),
                        ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 148,
                height: 140,
                child: ListeningObjectArt(topicId),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              title,
              key: const ValueKey('listening-outcome-title'),
              style: const TextStyle(
                fontSize: 24,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            saving
                ? t.listeningRecoverySavingBody
                : failed
                ? t.listeningRecoverySaveBody
                : t.listeningRecoverySaved,
          ),
          const Divider(height: 24, color: Color(0xffdcc8a3)),
          Text(
            t.listeningRecoveryAnswers,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            t.listeningRecoveryScore(correct, total),
            key: const ValueKey('listening-outcome-score'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          if (recovery) ...[
            const SizedBox(height: 12),
            Opacity(
              opacity: saving ? .55 : 1,
              child: ListeningFigmaPrimary(
                key: const ValueKey('listening-save-retry'),
                label: saving
                    ? t.listeningRecoverySaving
                    : t.listeningRecoverySaveRetry,
                onTap: saving ? null : onRetry,
              ),
            ),
            const SizedBox(height: 4),
            ListeningTextAction(
              key: const ValueKey('listening-save-stay'),
              label: saving ? t.listeningRecoveryWait : t.listeningRecoveryStay,
              onTap: saving ? null : onStay,
            ),
          ],
        ],
      ),
    );
  }
}

class ListeningTextAction extends StatelessWidget {
  const ListeningTextAction({
    super.key,
    required this.label,
    required this.onTap,
    this.onJade = false,
  });
  final String label;
  final VoidCallback? onTap;
  final bool onJade;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      minimumSize: const Size(48, 48),
      foregroundColor: onJade ? ListeningFigma.paper : ListeningFigma.jade,
      disabledForegroundColor: onJade
          ? ListeningFigma.paper
          : ListeningFigma.jade,
      textStyle: const TextStyle(
        fontFamily: ListeningFigma.font,
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
    ),
    child: Text(label, textAlign: TextAlign.center),
  );
}

class ListeningResultPanel extends StatelessWidget {
  const ListeningResultPanel({
    super.key,
    required this.title,
    required this.topicId,
    required this.correct,
    required this.total,
    required this.needsReview,
    this.review = false,
    this.earned = 0,
    this.remaining = 0,
  });
  final String title, topicId;
  final int correct, total;
  final int earned, remaining;
  final bool needsReview, review;
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return ListeningPaperPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 108,
                height: 100,
                child: ListeningObjectArt(topicId),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              review ? t.contentLearningReviewDone : t.listeningRecoveryDone,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.listeningRecoveryScore(correct, total),
            key: const ValueKey('listening-outcome-score'),
            style: const TextStyle(
              fontSize: 24,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.check_rounded,
                size: 18,
                color: ListeningFigma.jade,
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(t.listeningRecoverySaved)),
            ],
          ),
          if (needsReview) ...[
            const Divider(height: 16, color: Color(0xffdcc8a3)),
            Text(
              t.listeningRecoveryRemaining(remaining),
              style: const TextStyle(fontSize: 14),
            ),
          ],
          if (earned > 0) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  const ApprovedChromeImage(
                    asset: ApprovedChromeAssets.coinFront,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.yeopjeonEarned(earned),
                      key: const ValueKey('content-yeopjeon-earned'),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Remains alongside the authored dialogue. Retrying never invents completion.
class ListeningAudioRecovery extends StatelessWidget {
  const ListeningAudioRecovery({
    super.key,
    required this.onRetry,
    required this.onRead,
  });
  final VoidCallback? onRetry;
  final VoidCallback onRead;
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListeningPaperPanel(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          child: Semantics(
            liveRegion: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.listeningRecoveryAudioFailed,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.listeningRecoveryAudioBody,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        ListeningFigmaPrimary(
          key: const ValueKey('listening-audio-retry'),
          label: t.listeningRecoveryAudioRetry,
          onTap: onRetry,
        ),
        const SizedBox(height: 4),
        ListeningTextAction(
          key: const ValueKey('listening-audio-read'),
          label: t.listeningRecoveryRead,
          onTap: onRead,
          onJade: true,
        ),
      ],
    );
  }
}
