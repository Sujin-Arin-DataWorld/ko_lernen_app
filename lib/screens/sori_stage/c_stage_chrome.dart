import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/sori/c_gallery/c_materials.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/top_chrome.dart';

TextStyle cStageTitle(BuildContext context) =>
    SoriTextTheme.of(context).h1.copyWith(
      fontSize: 30,
      height: 1.12,
      color: CPalette.paper,
      shadows: const [Shadow(color: Color(0x66051914), offset: Offset(0, 1.2))],
    );
TextStyle cStageCardTitle(BuildContext context) => SoriTextTheme.of(
  context,
).h2.copyWith(fontSize: 22, height: 1.2, color: CPalette.ink);
TextStyle cStageBody(BuildContext context) => SoriTextTheme.of(
  context,
).body.copyWith(fontSize: 16, height: 1.35, color: CPalette.ink);

/// The approved jade surface extends behind the real OS status bar.
class CStageBackground extends StatelessWidget {
  const CStageBackground({super.key, required this.child, this.shelf = false});
  final Widget child;
  final bool shelf;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: shelf ? const Color(0xff00483d) : CPalette.jade),
        CTexture(CMaterial.jade, opacity: shelf ? .18 : .48),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: shelf ? Alignment.topCenter : Alignment.topLeft,
              end: shelf ? Alignment.bottomCenter : Alignment.bottomRight,
              colors: shelf
                  ? const [Color(0x09034f42), Color(0xc20a190f)]
                  : const [Color(0x111e7965), Color(0x33102924)],
            ),
          ),
        ),
        child,
      ],
    ),
  );
}

/// Reuses the shell's confirmed wallet and latest cloud/gear assets.
/// Source balance arguments never create a second wallet or a preview amount.
class CStageHeader extends StatelessWidget {
  const CStageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.balance,
    this.onWalletReturned,
    this.artwork,
    this.trailing,
    this.onProfile,
    this.titleMaxWidth,
    this.leading,
    this.extraAction,
    this.shelf = false,
    this.compactHero = false,
  });
  final String title;
  final String? subtitle;
  final double? titleMaxWidth;
  final int? balance;
  final VoidCallback? onWalletReturned, onProfile;
  final Widget? artwork, trailing, leading, extraAction;
  final bool shelf, compactHero;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final large = MediaQuery.textScalerOf(context).scale(16) > 22.4;
      final art = artwork;
      final titleBlock = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoriTopChrome(
            width: bounds.maxWidth,
            foreground: CPalette.paper,
            onWalletReturned: onWalletReturned,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) leading!,
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: cStageTitle(context)),
                ),
              ),
              if (trailing != null) trailing!,
              if (extraAction != null) extraAction!,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: cStageBody(
                context,
              ).copyWith(color: CPalette.paper, fontSize: 18),
            ),
          ],
        ],
      );
      if (art == null) {
        return titleBlock;
      }
      if (large) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            titleBlock,
            SizedBox(height: compactHero ? 96 : 136, child: art),
          ],
        );
      }
      return Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: compactHero ? 78 : 100),
            child: titleBlock,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            width: compactHero ? 124 : 150,
            height: compactHero ? 96 : 136,
            child: art,
          ),
        ],
      );
    },
  );
}
