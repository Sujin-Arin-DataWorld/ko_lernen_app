import 'package:flutter/material.dart';

Future<void> reselectTabScroll(
  ScrollController controller, {
  required bool reduceMotion,
}) async {
  if (!controller.hasClients || controller.offset <= 0) {
    return;
  }
  if (reduceMotion) {
    controller.jumpTo(0);
    return;
  }
  await controller.animateTo(
    0,
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOutCubic,
  );
}
