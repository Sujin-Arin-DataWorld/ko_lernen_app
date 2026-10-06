import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/foundation_progress.dart';
import '../widgets/sori/c_gallery/c_materials.dart';

String foundationStepTitle(AppL10n t, FoundationStep step) => switch (step) {
  FoundationStep.sounds => t.foundationSoundsTitle,
  FoundationStep.syllables => t.foundationSyllablesTitle,
  FoundationStep.tracing => t.foundationTraceTitle,
  FoundationStep.firstWords => t.foundationWordsTitle,
};

String foundationStepBody(AppL10n t, FoundationStep step) => switch (step) {
  FoundationStep.sounds => t.foundationSoundsBody,
  FoundationStep.syllables => t.foundationSyllablesBody,
  FoundationStep.tracing => t.foundationTraceBody,
  FoundationStep.firstWords => t.foundationWordsBody,
};

const foundationBodyStyle = TextStyle(
  fontFamily: 'Paperlogy',
  fontSize: 16,
  height: 1.45,
  color: CPalette.ink,
);

/// The entire page scrolls, including its title and actions. Large text and a
/// short landscape viewport cannot hide a fixed footer or clip an app bar.
class FoundationPage extends StatelessWidget {
  const FoundationPage({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: CPalette.paper,
    body: Stack(
      children: [
        const Positioned.fill(child: CTexture(CMaterial.paper, opacity: .4)),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: CPalette.jade,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Semantics(
                            container: true,
                            header: true,
                            child: Text(
                              title,
                              style: foundationBodyStyle.copyWith(
                                fontSize: 23,
                                height: 1.25,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class FoundationError extends StatelessWidget {
  const FoundationError({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => CPaperPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(message, style: foundationBodyStyle),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          CMaterialAction(
            label: AppL10n.of(context).btnRetry,
            onTap: onRetry,
            gold: false,
            compact: true,
          ),
        ],
      ],
    ),
  );
}

class FoundationPracticeProgress extends StatelessWidget {
  const FoundationPracticeProgress({
    super.key,
    required this.done,
    required this.total,
  });
  final int done, total;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        AppL10n.of(context).foundationProgress(done, total),
        style: foundationBodyStyle.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : done / total,
            color: CPalette.jade,
            backgroundColor: CPalette.fineEdge.withValues(alpha: .45),
            minHeight: 6,
          ),
        ),
      ),
    ],
  );
}
