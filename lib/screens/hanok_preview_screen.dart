import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/sarangchae_construction.dart';
import '../models/sori_stage_progression.dart';
import '../motion/transitions.dart';
import '../services/sori_stage_progression_service.dart';
import '../widgets/sori/app_bar.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/hanok_v3_preview.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/tokens.dart';

Route<dynamic>? buildHanokPreviewRoute(RouteSettings settings) {
  if (settings.name != '/hanok' &&
      settings.name != '/hanok/anbang' &&
      settings.name != '/hanok/daecheong') {
    return null;
  }
  return SoriTransitions.page(
    (_) => const HanokPreviewScreen(),
    settings: settings,
  );
}

class HanokPreviewScreen extends StatefulWidget {
  const HanokPreviewScreen({
    super.key,
    this.loadSnapshot,
    this.loadConstruction,
  });

  final Future<SoriStageProgressionSnapshot> Function()? loadSnapshot;
  final Future<SarangchaeConstruction> Function()? loadConstruction;

  @override
  State<HanokPreviewScreen> createState() => _HanokPreviewScreenState();
}

class _HanokPreviewScreenState extends State<HanokPreviewScreen> {
  late Future<SoriStageProgressionSnapshot> _snapshotFuture;
  late Future<SarangchaeConstruction> _constructionFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant HanokPreviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadSnapshot != widget.loadSnapshot ||
        oldWidget.loadConstruction != widget.loadConstruction) {
      _load();
    }
  }

  void _load() {
    _snapshotFuture =
        (widget.loadSnapshot ?? SoriStageProgressionService.load)();
    _constructionFuture =
        (widget.loadConstruction ?? SarangchaeConstruction.load)();
  }

  void _retry() => setState(_load);

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Scaffold(
      appBar: SoriAppBar(
        title: t.soriStageNavHanok,
        textScale: MediaQuery.textScalerOf(context).scale(1),
        viewportWidth: MediaQuery.sizeOf(context).width,
      ),
      body: SoriScreenBackground(
        child: SafeArea(
          child: FutureBuilder<SarangchaeConstruction>(
            future: _constructionFuture,
            builder: (context, constructionSnapshot) =>
                FutureBuilder<SoriStageProgressionSnapshot>(
                  future: _snapshotFuture,
                  builder: (context, progressionSnapshot) {
                    if (constructionSnapshot.hasError ||
                        progressionSnapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(Spacing.xl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                t.loadErrorTryAgain,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: Spacing.lg),
                              SoriButton(label: t.btnRetry, onTap: _retry),
                            ],
                          ),
                        ),
                      );
                    }
                    if (!constructionSnapshot.hasData ||
                        !progressionSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        Spacing.xl,
                        Spacing.lg,
                        Spacing.xl,
                        Spacing.xxxl,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: SarangchaeConstructionExperience(
                            construction: constructionSnapshot.data!,
                            earnedStageCount: progressionSnapshot
                                .data!
                                .hanokCompetence
                                .sarangchaeConstructionStage,
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ),
      ),
    );
  }
}
