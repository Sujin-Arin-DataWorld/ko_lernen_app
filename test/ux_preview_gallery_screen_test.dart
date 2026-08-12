import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/ux_preview_catalog.dart';
import 'package:ko_lernen_app/screens/ux_preview_gallery_screen.dart';

void main() {
  testWidgets('gallery opens the first and last production preview panel', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UxPreviewGalleryScreen(
          buildPanel: (panel) => Scaffold(
            body: Center(
              child: Text(
                'preview-${panel.id}',
                key: ValueKey('preview-${panel.id}'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('ux-preview-panel-01A')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('ux-preview-panel-01A')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('preview-01A')), findsOneWidget);

    Navigator.of(tester.element(find.byType(Scaffold))).pop();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('ux-preview-panel-06C')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('ux-preview-panel-06C')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('preview-06C')), findsOneWidget);
  });

  testWidgets('gallery exposes every catalog id to accessibility', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: UxPreviewGalleryScreen(
          buildPanel: (_) => const SizedBox.shrink(),
        ),
      ),
    );

    for (final panel in uxPreviewPanels) {
      expect(
        tester.getSemantics(
          find.byKey(ValueKey('ux-preview-panel-${panel.id}')),
        ),
        matchesSemantics(
          label: '${panel.id} ${panel.title}',
          isButton: true,
          hasTapAction: true,
        ),
      );
    }
    semantics.dispose();
  });
}
