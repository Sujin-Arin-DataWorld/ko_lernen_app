import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'pressable.dart';
import 'approved_chrome_assets.dart';
import 'tokens.dart';

/// Tactile settings entry. The existing SettingsScreen owns every setting.
class SoriSettingsButton extends StatelessWidget {
  const SoriSettingsButton({super.key});

  static const asset = ApprovedChromeAssets.settings;

  @override
  Widget build(BuildContext context) {
    final label = AppL10n.of(context).settingsTitle;
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: label,
        child: SoriPressable(
          pressOffsetY: 2,
          releaseCurve: SoriMotion.gentle,
          tactileTilt: true,
          onTap: () => Navigator.of(context).pushNamed('/settings'),
          child: SizedBox.square(
            dimension: 48,
            child: Center(
              child: ExcludeSemantics(
                child: const ApprovedChromeImage(asset: asset, size: 36),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
