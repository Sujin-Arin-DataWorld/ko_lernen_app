import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'pressable.dart';

/// Tactile settings entry. The existing SettingsScreen owns every setting.
class SoriSettingsButton extends StatelessWidget {
  const SoriSettingsButton({super.key});

  static const asset = 'assets/icons/tactile_settings.png';

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
          onTap: () => Navigator.of(context).pushNamed('/settings'),
          child: SizedBox.square(
            dimension: 48,
            child: Center(
              child: ExcludeSemantics(
                child: Image.asset(asset, width: 36, height: 36),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
