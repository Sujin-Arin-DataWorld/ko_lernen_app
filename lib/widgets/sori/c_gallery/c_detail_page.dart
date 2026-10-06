import 'package:flutter/material.dart';

import '../../../screens/sori_stage/c_stage_chrome.dart';
import 'c_materials.dart';
import 'c_objects.dart';

class CDetailPage extends StatelessWidget {
  const CDetailPage({
    super.key,
    required this.title,
    required this.child,
    this.leading,
    this.trailing,
    this.titleTrailing,
    this.controller,
    this.maxWidth = 600,
    this.contentPadding = const EdgeInsets.fromLTRB(12, 0, 12, 28),
    this.showBrand = true,
    this.onBack,
  });

  final String title;
  final Widget child;
  final Widget? leading, trailing, titleTrailing;
  final ScrollController? controller;
  final double maxWidth;
  final EdgeInsets contentPadding;
  final bool showBrand;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: CPalette.jade,
    body: CStageBackground(
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              children: [
                _header(context),
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    padding: contentPadding,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _header(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(6, 2, 6, 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            leading ??
                CImageTap(
                  label: MaterialLocalizations.of(context).backButtonTooltip,
                  onTap: onBack ?? () => Navigator.of(context).maybePop(),
                  child: const SizedBox.square(
                    dimension: 48,
                    child: Center(
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: CPalette.paper,
                      ),
                    ),
                  ),
                ),
            if (showBrand)
              const Expanded(child: CBrandWordmark())
            else
              const Spacer(),
            if (trailing != null) trailing! else const SizedBox(width: 48),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: cStageTitle),
                ),
              ),
              if (titleTrailing != null) ...[
                const SizedBox(width: 10),
                titleTrailing!,
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class CDetailPanel extends StatelessWidget {
  const CDetailPanel({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(12, 8, 12, 12),
  });
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => CPaperPanel(
    radius: 14,
    padding: padding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

class CDetailSectionLabel extends StatelessWidget {
  const CDetailSectionLabel(this.label, {super.key, this.top = 12});
  final String label;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(4, top, 4, 7),
    child: Text(
      label,
      style: cStageBody.copyWith(
        fontSize: 13,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: CPalette.mutedInk,
        letterSpacing: .25,
      ),
    ),
  );
}

class CDetailRow extends StatelessWidget {
  const CDetailRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.divider = true,
    this.minHeight = 64,
  });

  final String title;
  final String? subtitle;
  final Widget? leading, trailing;
  final VoidCallback? onTap;
  final bool destructive, divider;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final titleStyle = cStageBody.copyWith(
      fontWeight: FontWeight.w600,
      color: destructive ? const Color(0xff873b2c) : CPalette.ink,
    );
    final body = Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: divider
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0x77ccb69a))),
            )
          : null,
      child: Row(
        children: [
          if (leading != null) ...[
            SizedBox(width: 48, height: 48, child: Center(child: leading)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleStyle),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: cStageBody.copyWith(
                      fontSize: 13,
                      color: CPalette.mutedInk,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: Center(child: trailing),
            )
          else if (onTap != null)
            const SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Icon(Icons.chevron_right_rounded, color: CPalette.jade),
              ),
            ),
        ],
      ),
    );
    if (onTap == null) return body;
    return CImageTap(label: title, onTap: onTap, child: body);
  }
}

class CBrassCheck extends StatelessWidget {
  const CBrassCheck({super.key, this.selected = true});
  final bool selected;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 120),
    width: 30,
    height: 30,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: selected ? CPalette.brass : Colors.transparent,
      border: Border.all(color: CPalette.brass, width: 1.4),
      boxShadow: selected
          ? const [
              BoxShadow(
                color: Color(0x4482522f),
                offset: Offset(0, 2),
                blurRadius: 2,
              ),
            ]
          : null,
    ),
    child: selected
        ? const Icon(Icons.check_rounded, size: 20, color: CPalette.ink)
        : null,
  );
}
