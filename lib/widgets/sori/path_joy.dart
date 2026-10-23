import 'package:flutter/material.dart';

/// Exact originals from the user's 까치정본 folder. The caller may show the
/// resolved pose only after the episode receipt has been durably saved.
class PathJoy extends StatelessWidget {
  const PathJoy({super.key, this.resolved = false});
  final bool resolved;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Image.asset(
      resolved
          ? 'assets/illustrations/lernpfad/joy_resolved.png'
          : 'assets/illustrations/lernpfad/joy_guide.png',
      height: 112,
      width: 112,
      cacheWidth: (112 * MediaQuery.devicePixelRatioOf(context)).ceil(),
      fit: BoxFit.contain,
      semanticLabel: 'Joy',
      errorBuilder: (_, __, ___) => const Text('Joy'),
    ),
  );
}
