import 'package:flutter/material.dart';
import 'tokens.dart';
import 'approved_chrome_assets.dart';
import 'c_learning_surface.dart';

PreferredSizeWidget soriCLernenHeader(
  BuildContext context,
  Widget leading,
  List<Widget> actions,
  String title, {
  PreferredSizeWidget? bottom,
}) {
  final fonts = SoriLocaleFonts.of(context);
  final style = TextStyle(
    fontFamily: fonts.heading,
    fontSize: 22,
    height: 1.2,
    fontWeight: fonts.headingWeight,
    color: SoriCLearningTokens.paper,
  );
  final mediaWidth = MediaQuery.sizeOf(context).width;
  final view = View.of(context);
  final width = mediaWidth > 32
      ? mediaWidth
      : view.physicalSize.width / view.devicePixelRatio;
  final measure = TextPainter(
    text: TextSpan(text: title, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(maxWidth: (width - 32).clamp(1.0, double.infinity));
  final titleHeight = measure.height + 14;
  measure.dispose();
  return PreferredSize(
    preferredSize: Size.fromHeight(
      48 + titleHeight + (bottom?.preferredSize.height ?? 0),
    ),
    child: Theme(
      data: Theme.of(context).copyWith(brightness: Brightness.dark),
      child: AppBar(
        toolbarHeight: 48,
        leading: leading,
        actions: actions,
        backgroundColor: SoriCLearningTokens.jade,
        foregroundColor: SoriCLearningTokens.paper,
        iconTheme: const IconThemeData(color: SoriCLearningTokens.paper),
        actionsIconTheme: const IconThemeData(color: SoriCLearningTokens.paper),
        elevation: 0,
        title: Semantics(
          label: 'Hangul Sori',
          child: ExcludeSemantics(
            child: LayoutBuilder(
              builder: (context, bounds) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    ApprovedChromeAssets.cloud,
                    width: 22,
                    height: 22,
                  ),
                  if (bounds.maxWidth >= 180 &&
                      MediaQuery.textScalerOf(context).scale(12) <= 15) ...[
                    const SizedBox(width: 6),
                    Text(
                      'HANGUL SORI',
                      style: TextStyle(
                        fontFamily: SoriLocaleFonts.of(context).body,
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: SoriCLearningTokens.gold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        centerTitle: true,
        flexibleSpace: const SoriCMaterialSurface(
          material: SoriCMaterial.jade,
          raised: false,
          borderRadius: BorderRadius.zero,
          child: SizedBox.expand(),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            titleHeight + (bottom?.preferredSize.height ?? 0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Semantics(
                  header: true,
                  namesRoute: true,
                  child: Text(title, style: style, textAlign: TextAlign.center),
                ),
              ),
              if (bottom != null) bottom,
            ],
          ),
        ),
      ),
    ),
  );
}
