import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/personal_hanok.dart';
import '../services/hanok_stage_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/personal_hanok_map.dart';
import '../widgets/sori/progress.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/tokens.dart';

/// The personal estate is a read-only projection of existing course progress.
///
/// It never awards, migrates, or infers learning state. A completed building
/// is simply a spatial doorway to an established Hangul Sori surface.
class HanokWorldScreen extends StatefulWidget {
  final Future<LevelRatios> Function()? loadRatios;
  final ValueChanged<PersonalHanokZone>? onOpenZone;

  const HanokWorldScreen({super.key, this.loadRatios, this.onOpenZone});

  @override
  State<HanokWorldScreen> createState() => _HanokWorldScreenState();
}

class _HanokWorldScreenState extends State<HanokWorldScreen> {
  PersonalHanokProjection? _projection;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loadRatios = widget.loadRatios ?? HanokStageService.levelRatios;
    try {
      final ratios = await loadRatios();
      if (!mounted) {
        return;
      }
      setState(() => _projection = PersonalHanokProjection.from(ratios));
    } catch (_) {
      // The world is an enhancement of the learning route. If its local
      // progress read fails, show the existing empty courtyard rather than
      // trapping the user in a loading state or writing any recovery value.
      if (!mounted) {
        return;
      }
      setState(
        () => _projection = PersonalHanokProjection.from(
          const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
        ),
      );
    }
  }

  Future<void> _openZone(PersonalHanokZone zone) async {
    final onOpenZone = widget.onOpenZone;
    if (onOpenZone != null) {
      onOpenZone(zone);
      return;
    }
    final route = hanokRouteForZone(zone);
    if (route == null) {
      return;
    }
    await Navigator.pushNamed(context, route);
    if (mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final projection = _projection;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(t.hanokWorldTitle)),
      body: SoriScreenBackground(
        child: SafeArea(
          child: projection == null
              ? const AppLoading()
              : SoriContentClamp(
                  maxWidth: 960,
                  base: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    Spacing.md,
                    Spacing.lg,
                    Spacing.xxxl,
                  ),
                  builder: (context, padding) => RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: padding,
                      children: [
                        _WorldIntroduction(
                          projection: projection,
                          onOpenSarangbang: () =>
                              _openZone(PersonalHanokZone.sarangbang),
                        ),
                        const SizedBox(height: Spacing.lg),
                        if (projection.usesCompoundMap) ...[
                          Text(
                            t.hanokWorldMapHint,
                            style: SoriTextTheme.of(context).bodySmall,
                          ),
                          const SizedBox(height: Spacing.md),
                        ],
                        Semantics(
                          label: t.hanokWorldTitle,
                          child: PersonalHanokMap(
                            projection: projection,
                            zoneLabel: (zone) => _zoneLabel(t, zone),
                            onTapZone: _openZone,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _WorldIntroduction extends StatelessWidget {
  final PersonalHanokProjection projection;
  final VoidCallback onOpenSarangbang;

  const _WorldIntroduction({
    required this.projection,
    required this.onOpenSarangbang,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final hasMap = projection.usesCompoundMap;
    return SoriCard(
      variant: SoriCardVariant.hanji,
      accent: SoriColors.primary,
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasMap ? t.hanokWorldTitle : t.hanokWorldLegacyTitle,
            style: text.h2,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            hasMap ? t.hanokWorldIntro : t.hanokWorldLegacyBody,
            style: text.bodySmall,
          ),
          const SizedBox(height: Spacing.md),
          Semantics(
            label: t.hanokWorldProgress,
            child: SoriProgressBar(
              value: projection.constructionFraction,
              animated: true,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          SoriButton.outlined(
            label: t.hanokWorldOpenSarangbang,
            icon: Icons.menu_book_rounded,
            fullWidth: true,
            onTap: onOpenSarangbang,
          ),
        ],
      ),
    );
  }
}

String? hanokRouteForZone(PersonalHanokZone zone) => switch (zone) {
  PersonalHanokZone.sarangbang => '/sarangbang',
  PersonalHanokZone.daecheongmaru => '/hanok/daecheong',
  PersonalHanokZone.haengrangchae => '/practice',
  PersonalHanokZone.anchae => '/hanok/anbang',
  PersonalHanokZone.huwon => '/daily',
  PersonalHanokZone.sadang => '/dojangcheop',
  PersonalHanokZone.gyeRoad => null,
};

String _zoneLabel(AppL10n t, PersonalHanokZone zone) => switch (zone) {
  PersonalHanokZone.sarangbang => t.hanokZoneSarangbang,
  PersonalHanokZone.daecheongmaru => t.hanokZoneDaecheong,
  PersonalHanokZone.haengrangchae => t.hanokZoneHaengrang,
  PersonalHanokZone.anchae => t.hanokZoneAnchae,
  PersonalHanokZone.huwon => t.hanokZoneHuwon,
  PersonalHanokZone.sadang => t.hanokZoneSadang,
  PersonalHanokZone.gyeRoad => '',
};
