import 'package:flutter/material.dart';

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

/// Keep the semantic type size while applying the approved C face and ink.
TextStyle cMaterialText(TextStyle style) => style.copyWith(
  fontFamily: 'Paperlogy',
  fontFamilyFallback: const ['NotoSansKR'],
  color: CPalette.ink,
  fontWeight: (style.fontSize ?? 16) >= 18 ? FontWeight.w700 : style.fontWeight,
);
