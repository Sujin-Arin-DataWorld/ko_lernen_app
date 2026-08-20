import 'package:flutter/material.dart';

import 'tokens.dart';

/// Opens an app-owned dialog with one route contract.
///
/// The route stays inside the safe area, traps keyboard traversal, and requests
/// focus when it opens. Platform permission dialogs, OAuth browsers, and store
/// billing sheets do not use this API because the app does not own them.
Future<T?> showSoriDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String? barrierLabel,
  Color? barrierColor,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    barrierColor: barrierColor,
    useSafeArea: true,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
    requestFocus: true,
    builder: (dialogContext) => FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: Builder(builder: builder),
    ),
  );
}

/// Opens a custom animated app-owned dialog while preserving the shared route
/// ownership and focus contract.
Future<T?> showSoriGeneralDialog<T>({
  required BuildContext context,
  required RoutePageBuilder pageBuilder,
  bool barrierDismissible = false,
  String? barrierLabel,
  Color barrierColor = const Color(0x80000000),
  Duration transitionDuration = const Duration(milliseconds: 200),
  RouteTransitionsBuilder? transitionBuilder,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  return showGeneralDialog<T>(
    context: context,
    pageBuilder: pageBuilder,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    barrierColor: barrierColor,
    transitionDuration: transitionDuration,
    transitionBuilder: transitionBuilder,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    requestFocus: true,
  );
}

/// Sori-styled alert surface for confirmations, explanations, and errors.
///
/// [AlertDialog.scrollable] is always enabled so 200% text remains reachable.
/// Its action overflow bar stacks buttons when they no longer fit in a row.
class SoriDialog extends StatelessWidget {
  const SoriDialog({
    super.key,
    this.icon,
    this.title,
    this.content,
    this.actions,
    this.semanticLabel,
    this.backgroundColor,
    this.insetPadding,
    this.contentPadding,
    this.actionsPadding,
  });

  final Widget? icon;
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final String? semanticLabel;
  final Color? backgroundColor;
  final EdgeInsets? insetPadding;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? actionsPadding;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    final text = SoriTextTheme.of(context);

    return AlertDialog(
      icon: icon,
      title: title,
      content: content,
      actions: actions,
      semanticLabel: semanticLabel,
      scrollable: true,
      insetPadding:
          insetPadding ??
          const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 24),
      contentPadding: contentPadding,
      actionsPadding:
          actionsPadding ??
          const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.sm,
            Spacing.lg,
            Spacing.lg,
          ),
      backgroundColor: backgroundColor ?? surfaces.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: SoriRadius.brLg),
      titleTextStyle: text.h2,
      contentTextStyle: text.body,
      constraints: const BoxConstraints(maxWidth: SoriBreakpoints.content),
    );
  }
}

/// Sori-styled choice dialog for short option lists.
class SoriSimpleDialog extends StatelessWidget {
  const SoriSimpleDialog({
    super.key,
    this.title,
    this.children,
    this.semanticLabel,
    this.insetPadding,
    this.titlePadding,
    this.contentPadding,
  });

  final Widget? title;
  final List<Widget>? children;
  final String? semanticLabel;
  final EdgeInsets? insetPadding;
  final EdgeInsetsGeometry? titlePadding;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    final text = SoriTextTheme.of(context);
    return SimpleDialog(
      title: title,
      semanticLabel: semanticLabel,
      insetPadding:
          insetPadding ??
          const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 24),
      titlePadding:
          titlePadding ??
          const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.lg,
            Spacing.lg,
            Spacing.sm,
          ),
      contentPadding:
          contentPadding ??
          const EdgeInsets.fromLTRB(0, Spacing.sm, 0, Spacing.md),
      backgroundColor: surfaces.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: SoriRadius.brLg),
      titleTextStyle: text.h2,
      children: children,
    );
  }
}

/// Sori surface for bespoke dialog bodies such as progress and celebrations.
class SoriDialogFrame extends StatelessWidget {
  const SoriDialogFrame({
    super.key,
    required this.child,
    this.backgroundColor,
    this.insetPadding,
    this.shape,
    this.alignment,
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final Color? backgroundColor;
  final EdgeInsets? insetPadding;
  final ShapeBorder? shape;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    return Dialog(
      backgroundColor: backgroundColor ?? surfaces.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding:
          insetPadding ??
          const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 24),
      shape:
          shape ?? const RoundedRectangleBorder(borderRadius: SoriRadius.brLg),
      alignment: alignment,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}
