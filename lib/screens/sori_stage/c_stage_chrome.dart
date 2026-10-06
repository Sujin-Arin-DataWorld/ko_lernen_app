import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/c_gallery/c_materials.dart';
import '../../widgets/sori/c_gallery/c_objects.dart';
import '../../widgets/sori/sheet.dart';
import '../../widgets/sori/yeopjeon_wallet_card.dart';

const cStageTitle = TextStyle(
  fontFamily: 'Paperlogy',
  fontFamilyFallback: ['NotoSansKR'],
  fontSize: 30,
  height: 1.12,
  fontWeight: FontWeight.w700,
  color: CPalette.paper,
  shadows: [Shadow(color: Color(0x66051914), offset: Offset(0, 1.2))],
);
const cStageCardTitle = TextStyle(
  fontFamily: 'Paperlogy',
  fontFamilyFallback: ['NotoSansKR'],
  fontSize: 22,
  height: 1.2,
  fontWeight: FontWeight.w700,
  color: CPalette.ink,
);
const cStageBody = TextStyle(
  fontFamily: 'Paperlogy',
  fontFamilyFallback: ['NotoSansKR'],
  fontSize: 16,
  height: 1.35,
  color: CPalette.ink,
);

/// The approved jade surface extends behind the real OS status bar.
class CStageBackground extends StatelessWidget {
  const CStageBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: CPalette.jade),
        const CTexture(CMaterial.jade, opacity: .48),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x111e7965), Color(0x33102924)],
            ),
          ),
        ),
        child,
      ],
    ),
  );
}

/// Real destinations and a confirmed balance share the short C header.
class CStageHeader extends StatelessWidget {
  const CStageHeader({
    super.key,
    required this.title,
    this.balance,
    this.onWalletReturned,
    this.artwork,
    this.trailing,
    this.onProfile,
  });
  final String title;
  final int? balance;
  final VoidCallback? onWalletReturned, onProfile;
  final Widget? artwork, trailing;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final large = MediaQuery.textScalerOf(context).scale(30) > 42;
    final art = artwork;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: art == null ? 108 : 170),
      child: Stack(
        children: [
          if (art != null)
            Positioned(
              right: 0,
              bottom: 0,
              width: 150,
              height: 136,
              child: art,
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              6,
              0,
              6,
              art != null && large ? 138 : 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wallet = balance == null
                        ? null
                        : _wallet(context, balance!);
                    final measure = TextPainter(
                      text: TextSpan(
                        text: '${balance ?? 0}',
                        style: cStageBody.copyWith(fontSize: 14),
                      ),
                      textDirection: Directionality.of(context),
                      textScaler: MediaQuery.textScalerOf(context),
                    )..layout();
                    final wrapWallet =
                        wallet != null &&
                        constraints.maxWidth <
                            48 + 116 + 48 + measure.width + 47;
                    measure.dispose();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Tooltip(
                              message: t.soriStageProfileTooltip,
                              child: CImageTap(
                                label: t.soriStageProfileTooltip,
                                onTap:
                                    onProfile ??
                                    () => Navigator.of(
                                      context,
                                    ).pushNamed('/profile'),
                                child: const SizedBox.square(
                                  dimension: 48,
                                  child: Center(
                                    child: CObjectArt(CObject.cloud, size: 30),
                                  ),
                                ),
                              ),
                            ),
                            const Expanded(child: CBrandWordmark()),
                            if (wallet != null && !wrapWallet) wallet,
                            CImageTap(
                              label: t.settingsTitle,
                              onTap: () =>
                                  Navigator.of(context).pushNamed('/settings'),
                              child: const SizedBox.square(
                                dimension: 48,
                                child: Center(child: CSettingsCog()),
                              ),
                            ),
                          ],
                        ),
                        if (wrapWallet)
                          Align(
                            alignment: Alignment.centerRight,
                            child: wallet,
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Semantics(
                        container: true,
                        header: true,
                        child: Text(title, style: cStageTitle),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _wallet(BuildContext context, int confirmed) {
    final t = AppL10n.of(context);
    return CImageTap(
      label: '${t.yeopjeonTitle}. ${t.yeopjeonBalance(confirmed)}',
      onTap: () async {
        await showSoriSheet<void>(
          context: context,
          maxTextScaleFactor: 2,
          builder: (_) => const YeopjeonWalletCard(conceptC: true),
        );
        if (context.mounted) onWalletReturned?.call();
      },
      child: Container(
        key: const ValueKey('yeopjeon-header-balance'),
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.fromLTRB(2, 2, 10, 2),
          decoration: BoxDecoration(
            color: CPalette.deepJade,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: CPalette.brass),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CObjectArt(CObject.coin, size: 28),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  '$confirmed',
                  style: cStageBody.copyWith(
                    color: CPalette.paper,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
