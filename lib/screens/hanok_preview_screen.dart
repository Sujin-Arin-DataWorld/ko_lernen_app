import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../motion/transitions.dart';
import '../widgets/sori/app_bar.dart';
import '../widgets/sori/hanok_v3_preview.dart';
import '../widgets/sori/screen_background.dart';

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

class HanokPreviewScreen extends StatelessWidget {
  const HanokPreviewScreen({super.key});

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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: HanokV3Preview(message: t.soriStageHanokUpdating),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
