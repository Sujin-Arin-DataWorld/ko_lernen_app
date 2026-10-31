import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../services/locale_service.dart';
import '../tokens.dart';

abstract final class CPalette {
  static const jade = Color(0xff1c5148);
  static const deepJade = Color(0xff123e37);
  static const paper = Color(0xfff6ede0);
  static const ink = Color(0xff1c2520);
  static const mutedInk = Color(0xff4b5148);
  static const brass = Color(0xffd59f58);
  static const oakEdge = Color(0xff82522f);
  static const fineEdge = Color(0xffccb69a);
}

/// Applies C ink and the actual locale face without reducing semantic size.
TextStyle cMaterialText(
  TextStyle style, {
  BuildContext? context,
  bool? heading,
}) {
  final locale = basicLocaleListResolution(
    localeNotifier.value == null
        ? WidgetsBinding.instance.platformDispatcher.locales
        : [localeNotifier.value!],
    AppL10n.supportedLocales,
  );
  final fonts = context == null
      ? SoriLocaleFonts.forLocale(locale)
      : SoriLocaleFonts.of(context);
  final isHeading = heading ?? (style.fontSize ?? 16) >= 18;
  return style.copyWith(
    fontFamily: isHeading ? fonts.heading : fonts.body,
    fontFamilyFallback: SoriLocaleFonts.fallback,
    color: CPalette.ink,
    fontWeight: isHeading
        ? fonts.headingWeight
        : fonts.bodyWeight(style.fontWeight ?? FontWeight.w400),
  );
}
