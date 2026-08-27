import 'package:flutter/material.dart';

import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/tokens.dart';

/// Opens an onboarding-owned modal and returns keyboard focus to the control
/// that opened it after the route has closed.
Future<T?> showOnboardingV2ModalWithFocusRestore<T>(
  Future<T?> Function() openModal,
) async {
  final openerFocus = FocusManager.instance.primaryFocus;
  final result = await openModal();
  if (openerFocus?.context != null && openerFocus!.canRequestFocus) {
    openerFocus.requestFocus();
  }
  return result;
}

/// Shared first-run frame: the explanatory body can always scroll while the
/// current step's primary action remains reachable above the system inset.
class OnboardingV2PageShell extends StatelessWidget {
  const OnboardingV2PageShell({
    super.key,
    required this.body,
    required this.footer,
    this.bodyKey,
  });

  final Widget body;
  final Widget footer;
  final Key? bodyKey;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    return Scaffold(
      backgroundColor: surfaces.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SoriContentClamp(
                base: const EdgeInsets.fromLTRB(
                  Spacing.xl,
                  Spacing.xl,
                  Spacing.xl,
                  Spacing.xxl,
                ),
                builder: (context, padding) => SingleChildScrollView(
                  key: bodyKey,
                  padding: padding,
                  child: body,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: surfaces.bg,
                border: Border(top: BorderSide(color: surfaces.border)),
              ),
              child: SoriContentClamp(
                base: const EdgeInsets.fromLTRB(
                  Spacing.xl,
                  Spacing.md,
                  Spacing.xl,
                  Spacing.md,
                ),
                builder: (context, padding) =>
                    Padding(padding: padding, child: footer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingV2Heading extends StatelessWidget {
  const OnboardingV2Heading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.body,
    this.titleKey,
    this.announcementLabel,
  });

  final String eyebrow;
  final String title;
  final String body;
  final Key? titleKey;
  final String? announcementLabel;

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow.toUpperCase(), style: text.eyebrow),
        const SizedBox(height: Spacing.sm),
        Focus(
          debugLabel: 'onboarding-v2-heading',
          autofocus: true,
          child: Semantics(
            header: true,
            focusable: true,
            label: announcementLabel ?? title,
            excludeSemantics: true,
            child: Text(key: titleKey, title, style: text.h1),
          ),
        ),
        const SizedBox(height: Spacing.md),
        Text(body, style: text.body),
      ],
    );
  }
}
