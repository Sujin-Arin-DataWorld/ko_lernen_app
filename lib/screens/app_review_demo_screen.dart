import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/ux_preview_catalog.dart';
import 'ux_preview_app.dart';
import 'ux_preview_gallery_screen.dart';

/// A deterministic, read-only tour of representative production surfaces.
///
/// The tour is deliberately available before legal consent and runs entirely
/// through the UX preview seams. Those seams inject sample state and replace
/// progress/account callbacks with no-ops, so exploration never grants
/// consent or changes learner progress. A nested navigator also intercepts
/// named production routes before they can escape into the live app.
class AppReviewDemoScreen extends StatefulWidget {
  const AppReviewDemoScreen({
    super.key,
    this.registry = const UxPreviewRegistry(),
  });

  final UxPreviewRegistry registry;

  @override
  State<AppReviewDemoScreen> createState() => _AppReviewDemoScreenState();
}

class _AppReviewDemoScreenState extends State<AppReviewDemoScreen> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) => NavigatorPopHandler<void>(
    onPopWithResult: (_) => _navigatorKey.currentState?.pop(),
    child: Navigator(
      key: _navigatorKey,
      onGenerateInitialRoutes: (_, _) => [
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/review_demo'),
          builder: _buildGallery,
        ),
      ],
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => UxPreviewNavigationBoundary(routeName: settings.name),
      ),
    ),
  );

  Widget _buildGallery(BuildContext nestedContext) {
    final t = AppL10n.of(nestedContext);
    return UxPreviewGalleryScreen(
      buildPanel: widget.registry.buildPanel,
      panels: _reviewDemoPanels,
      appBarTitle: t.reviewDemoAppBarTitle,
      automaticallyImplyLeading: false,
      leading: IconButton(
        key: const ValueKey('app-review-demo-close'),
        tooltip: t.btnClose,
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.close_rounded),
      ),
      eyebrow: t.reviewDemoEyebrow,
      headline: t.reviewDemoTitle,
      description: t.reviewDemoBody,
      panelKeyPrefix: 'app-review-demo-panel',
      showPanelIds: false,
      sectionLabelBuilder: (section) => _sectionLabel(t, section),
      panelTitleBuilder: (panel) => _panelTitle(t, panel.id),
    );
  }
}

const _reviewDemoPanelIds = <String>[
  '01D',
  '02A',
  '02B',
  '02E',
  '02J',
  '03B',
  '03C',
  '04A',
  '04B',
  '04C',
  '05B',
  '06A',
  '06B',
  '07D',
];

// Every id above must exist in `uxPreviewPanels` (lib/models/ux_preview_catalog.dart);
// `singleWhere` throws a StateError otherwise, so retired catalog ids must be
// removed from this list in the same change.
final _reviewDemoPanels = List<UxPreviewPanel>.unmodifiable(
  _reviewDemoPanelIds.map(
    (id) => uxPreviewPanels.singleWhere((panel) => panel.id == id),
  ),
);

String _sectionLabel(AppL10n t, UxPreviewSection section) => switch (section) {
  UxPreviewSection.onboarding => t.reviewDemoSectionStart,
  UxPreviewSection.daily => t.reviewDemoSectionLearn,
  UxPreviewSection.hanok => t.reviewDemoSectionHanok,
  UxPreviewSection.explore => t.reviewDemoSectionExplore,
  UxPreviewSection.gye ||
  UxPreviewSection.account => t.reviewDemoSectionCommunity,
  UxPreviewSection.soriStage => t.reviewDemoSectionJourney,
};

String _panelTitle(AppL10n t, String id) => switch (id) {
  '01D' => t.reviewDemoPanelCompanion,
  '02A' => t.reviewDemoPanelToday,
  '02B' => t.reviewDemoPanelMission,
  '02E' => t.reviewDemoPanelListening,
  '02J' => t.reviewDemoPanelRoleplay,
  '03B' => t.reviewDemoPanelHanok,
  '03C' => t.reviewDemoPanelSarangbang,
  '04A' => t.reviewDemoPanelPractice,
  '04B' => t.reviewDemoPanelDiscover,
  '04C' => t.reviewDemoPanelPath,
  '05B' => t.reviewDemoPanelGye,
  '06A' => t.reviewDemoPanelProfile,
  '06B' => t.reviewDemoPanelOffline,
  '07D' => t.reviewDemoPanelJourney,
  _ => throw ArgumentError.value(id, 'id', 'Unknown review demo panel'),
};
