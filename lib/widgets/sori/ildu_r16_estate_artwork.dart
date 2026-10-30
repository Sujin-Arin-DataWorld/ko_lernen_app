import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'button.dart';

/// A completion reference, never the learner's ownership projection.
const kIlDuR16EstateAsset =
    'assets/illustrations/ildu_r16/ea60e4981210027bf991ce867fe44c3bdf1c2b1f9efe2d8f8009e8b8a3c181cf.webp';

class IlDuR16EstateArtwork extends StatefulWidget {
  const IlDuR16EstateArtwork({super.key, this.semanticLabel});
  final String? semanticLabel;

  @override
  State<IlDuR16EstateArtwork> createState() => _IlDuR16EstateArtworkState();
}

class _IlDuR16EstateArtworkState extends State<IlDuR16EstateArtwork> {
  int _generation = 0;

  @override
  Widget build(BuildContext context) => Image.asset(
    kIlDuR16EstateAsset,
    key: ValueKey('r16-estate-image-$_generation'),
    fit: BoxFit.contain,
    cacheWidth: 960,
    semanticLabel: widget.semanticLabel ?? AppL10n.of(context).ilduR16Reference,
    errorBuilder: (_, _, _) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppL10n.of(context).loadErrorTryAgain),
          TextButton(
            onPressed: () async {
              await const AssetImage(kIlDuR16EstateAsset).evict();
              if (mounted) {
                setState(() => _generation++);
              }
            },
            child: Text(AppL10n.of(context).btnRetry),
          ),
        ],
      ),
    ),
  );
}

class IlDuR16EstateEntry extends StatelessWidget {
  const IlDuR16EstateEntry({super.key});

  @override
  Widget build(BuildContext context) => SoriButton.outlined(
    key: const ValueKey('ildu-r16-estate-entry'),
    label: AppL10n.of(context).ilduR16Explore,
    icon: Icons.account_balance_outlined,
    fullWidth: true,
    onTap: () => Navigator.of(context).pushNamed('/hanok/estate'),
  );
}
