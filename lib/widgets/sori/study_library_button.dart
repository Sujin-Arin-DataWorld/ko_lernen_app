import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'pressable.dart';

/// Saved learning materials have their own entrance, separate from My Words.
class SoriStudyLibraryButton extends StatelessWidget {
  const SoriStudyLibraryButton({super.key});

  @override
  Widget build(BuildContext context) {
    final label = AppL10n.of(context).studyLibraryAppBarTitle;
    void open() => Navigator.of(context).pushNamed('/study-library');
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        key: const ValueKey('study-library-entry'),
        container: true,
        button: true,
        label: label,
        child: SoriPressable(
          onTap: open,
          child: const SizedBox.square(
            dimension: 48,
            child: ExcludeSemantics(
              child: Icon(Icons.bookmark_outline_rounded),
            ),
          ),
        ),
      ),
    );
  }
}
