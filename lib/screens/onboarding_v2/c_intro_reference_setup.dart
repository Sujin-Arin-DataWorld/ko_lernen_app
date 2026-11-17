import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/intro_motion.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/window_class.dart';
import 'c_intro_art.dart';
import 'onboarding_v2_presentation.dart';

/// Native controls that use the height allocated by the onboarding frame.
/// Unbounded reference previews retain the reviewed 402 x 934 coordinates.
/// Large text uses the flowing layout in COnboardingSetup instead.
class IntroReferenceSetup extends StatelessWidget {
  const IntroReferenceSetup({
    super.key,
    required this.copy,
    required this.selectedPurposeId,
    required this.selectedLevelCode,
    required this.beginnerSelected,
    required this.onPurposeChanged,
    required this.onChooseLevel,
  });
  final OnboardingV2Copy copy;
  final String? selectedPurposeId;
  final String? selectedLevelCode;
  final bool beginnerSelected;
  final ValueChanged<String> onPurposeChanged;
  final VoidCallback onChooseLevel;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final s = bounds.maxWidth / 402;
      final t = AppL10n.of(context);
      final level = copy.setup.levels
          .where(
            (l) => l.code.toLowerCase() == selectedLevelCode?.toLowerCase(),
          )
          .firstOrNull;
      final label = beginnerSelected
          ? t.onboardingCStartLevel
          : level?.code ?? copy.setup.selectLevelPrompt;
      if (bounds.hasBoundedHeight) {
        return _boundedSetup(context, level, label, bounds);
      }
      Widget at(double x, double y, double w, double h, Widget child) =>
          Positioned(
            left: x * s,
            top: y * s,
            width: w * s,
            height: h * s,
            child: child,
          );
      Widget words(
        String text,
        double size, {
        bool bold = false,
        bool center = false,
        Color color = IntroPalette.ink,
      }) => Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: IntroTypography.localized(
          context,
          IntroTypography.setupWords(size, s, bold, color),
        ),
      );
      return SizedBox(
        height: 504 * s,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            at(
              21,
              12,
              360,
              34,
              words(
                beginnerSelected
                    ? t.onboardingJourneyStartWhere
                    : t.onboardingCStartLevel,
                26.2,
                bold: true,
              ),
            ),
            at(
              16,
              52,
              370,
              74,
              Semantics(
                label: '$label. ${t.onboardingCChange}',
                button: true,
                onTap: onChooseLevel,
                child: IntroPressable(
                  key: const ValueKey('c-onboarding-change-level'),
                  onTap: onChooseLevel,
                  pressScale: .995,
                  surfaceDepth: 0,
                  child: ExcludeSemantics(
                    child: Container(
                      decoration: BoxDecoration(
                        color: IntroPalette.paper,
                        borderRadius: BorderRadius.circular(
                          IntroGeometry.levelField * s,
                        ),
                        border: Border.all(
                          color: beginnerSelected
                              ? IntroPalette.brass
                              : IntroPalette.jade,
                          width: (beginnerSelected ? 1 : 3) * s,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x402f1c0a),
                            offset: Offset(0, 3),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          at(
                            18,
                            6,
                            56,
                            56,
                            IntroMedal(
                              beginnerSelected ? '가' : level?.code ?? '–',
                              size: 56 * s,
                            ),
                          ),
                          at(
                            91,
                            level == null && !beginnerSelected ? 4 : 8,
                            beginnerSelected ? 232 : 166,
                            60,
                            level == null && !beginnerSelected
                                ? words(label, 16, bold: true)
                                : words(
                                    label,
                                    beginnerSelected ? 24 : 29,
                                    bold: true,
                                  ),
                          ),
                          if (beginnerSelected || level != null)
                            at(
                              91,
                              40,
                              190,
                              23,
                              words(
                                beginnerSelected
                                    ? t.onboardingJourneyBeginnerHint
                                    : level!.code == 'A2'
                                    ? t.introA2Hint
                                    : level.name,
                                14.5,
                                color: IntroPalette.mutedInk,
                              ),
                            ),
                          if (!beginnerSelected)
                            at(
                              264,
                              10,
                              98,
                              48,
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    IntroGeometry.levelAction * s,
                                  ),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xff0b6553),
                                      Color(0xff034a3d),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: IntroPalette.brass,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: words(
                                          t.onboardingCChange,
                                          16,
                                          color: IntroPalette.white,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 20 * s,
                                      color: IntroPalette.brass,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            at(
                              328,
                              21,
                              24,
                              24,
                              Icon(
                                Icons.chevron_right,
                                size: 24 * s,
                                color: IntroPalette.brass,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            at(
              16,
              134,
              370,
              22,
              words(
                t.onboardingCLevelRange,
                16,
                center: true,
                color: IntroPalette.mutedInk,
              ),
            ),
            at(
              21,
              161,
              360,
              29,
              words(t.onboardingCInterest, 22.3, bold: true),
            ),
            for (var i = 0; i < copy.setup.purposes.length; i++)
              at(
                i.isEven ? 16 : 207,
                i < 2 ? 197 : 329,
                180,
                i < 2 ? 125 : 120,
                _InterestCard(
                  id: copy.setup.purposes[i].id,
                  title: copy.setup.purposes[i].title,
                  selected: copy.setup.purposes[i].id == selectedPurposeId,
                  index: i,
                  scale: s,
                  onTap: () => onPurposeChanged(copy.setup.purposes[i].id),
                ),
              ),
            at(
              20,
              457,
              362,
              23,
              words(
                t.onboardingCLater,
                16,
                center: true,
                color: IntroPalette.mutedInk,
              ),
            ),
            at(
              20,
              478,
              362,
              22,
              words(
                t.introNextPath,
                13.5,
                bold: true,
                center: true,
                color: IntroPalette.emphasisInk,
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _boundedSetup(
    BuildContext context,
    OnboardingLevelSpec? level,
    String label,
    BoxConstraints bounds,
  ) {
    final t = AppL10n.of(context);
    final compact =
        bounds.maxWidth < SoriAdaptiveWidth.onboardingCompactBody &&
        bounds.maxHeight < 440;
    Widget words(
      String text,
      double size, {
      bool bold = false,
      bool center = false,
      Color color = IntroPalette.ink,
      int? maxLines,
    }) => Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      maxLines: maxLines,
      style: IntroTypography.localized(
        context,
        IntroTypography.setupWords(size, 1, bold, color),
      ).copyWith(height: 1.15),
    );
    final hint = beginnerSelected
        ? t.onboardingJourneyBeginnerHint
        : level == null
        ? copy.setup.selectLevelPrompt
        : level.code == 'A2'
        ? t.introA2Hint
        : level.name;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          words(
            beginnerSelected
                ? t.onboardingJourneyStartWhere
                : t.onboardingCStartLevel,
            compact ? 18 : 22,
            bold: true,
          ),
          const SizedBox(height: 4),
          Semantics(
            label: '$label. ${t.onboardingCChange}',
            button: true,
            onTap: onChooseLevel,
            child: IntroPressable(
              key: const ValueKey('c-onboarding-change-level'),
              onTap: onChooseLevel,
              pressScale: .995,
              surfaceDepth: 0,
              child: ExcludeSemantics(
                child: Container(
                  height: compact ? 68 : 72,
                  padding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: compact ? 2 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: IntroPalette.paper,
                    borderRadius: BorderRadius.circular(
                      IntroGeometry.levelField,
                    ),
                    border: Border.all(
                      color: beginnerSelected
                          ? IntroPalette.brass
                          : IntroPalette.jade,
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x402f1c0a),
                        offset: Offset(0, 3),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (beginnerSelected || level != null) ...[
                        IntroMedal(
                          beginnerSelected ? '가' : level!.code,
                          size: 44,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            words(
                              level == null ? t.onboardingCStartLevel : label,
                              18,
                              bold: true,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 2),
                            words(
                              hint,
                              16,
                              color: IntroPalette.mutedInk,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!beginnerSelected && level != null)
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              IntroGeometry.levelAction,
                            ),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xff0b6553), Color(0xff034a3d)],
                            ),
                            border: Border.all(
                              color: IntroPalette.brass,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              words(
                                t.onboardingCChange,
                                16,
                                color: IntroPalette.white,
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 20,
                                color: IntroPalette.brass,
                              ),
                            ],
                          ),
                        )
                      else
                        const Icon(
                          Icons.chevron_right,
                          size: 24,
                          color: IntroPalette.brass,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          words(
            t.onboardingCLevelRange,
            16,
            center: true,
            color: IntroPalette.mutedInk,
          ),
          const SizedBox(height: 4),
          words(t.onboardingCInterest, compact ? 18 : 20, bold: true),
          const SizedBox(height: 6),
          Expanded(
            child: Column(
              children: [
                for (var row = 0; row < 2; row++) ...[
                  if (row > 0) const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var column = 0; column < 2; column++) ...[
                          if (column > 0) const SizedBox(width: 8),
                          Expanded(
                            child: _InterestCard(
                              id: copy.setup.purposes[row * 2 + column].id,
                              title:
                                  copy.setup.purposes[row * 2 + column].title,
                              selected:
                                  copy.setup.purposes[row * 2 + column].id ==
                                  selectedPurposeId,
                              index: row * 2 + column,
                              scale: 1,
                              compact: true,
                              onTap: () => onPurposeChanged(
                                copy.setup.purposes[row * 2 + column].id,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          words(
            t.onboardingCLater,
            16,
            center: true,
            color: IntroPalette.mutedInk,
          ),
          const SizedBox(height: 4),
          words(
            t.introNextPath,
            16,
            bold: true,
            center: true,
            color: IntroPalette.emphasisInk,
          ),
        ],
      ),
    );
  }
}

class _InterestCard extends StatelessWidget {
  const _InterestCard({
    required this.id,
    required this.title,
    required this.selected,
    required this.index,
    required this.scale,
    required this.onTap,
    this.compact = false,
  });
  final String id;
  final String title;
  final bool selected;
  final int index;
  final double scale;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _compactCard(context);
    }
    final s = scale;
    final artHeight = (index < 2 ? 96.0 : 91.0) * s;
    final zoom = switch (index) {
      0 => 1.08,
      1 || 3 => 1.09,
      _ => 1.0,
    };
    return Semantics(
      label: title,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      onTap: onTap,
      child: IntroPressable(
        key: ValueKey('onboarding-purpose-$id'),
        onTap: onTap,
        pressScale: .995,
        surfaceDepth: 0,
        child: ExcludeSemantics(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xfffff5e8),
                    borderRadius: BorderRadius.circular(
                      IntroGeometry.interest * s,
                    ),
                    border: Border.all(
                      color: const Color(0xffd2b991),
                      width: s,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x603d2b12),
                        offset: Offset(0, 2),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: s,
                top: s,
                right: s,
                height: artHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(IntroGeometry.interestArt * s),
                  ),
                  child: Transform.translate(
                    offset: index == 0 ? Offset(5 * s, 4 * s) : Offset.zero,
                    child: Transform.scale(
                      scale: zoom,
                      child: CIntroArt(
                        [
                          'interest-travel',
                          'interest-culture',
                          'interest-study',
                          'interest-kcontent',
                        ][index],
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 2 * s,
                right: 2 * s,
                top: artHeight + 3 * s,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: IntroTypography.localized(
                    context,
                    IntroTypography.interestLabel(s),
                  ),
                ),
              ),
              if (selected) ...[
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          IntroGeometry.interest * s,
                        ),
                        border: Border.all(
                          color: IntroPalette.jade,
                          width: 4 * s,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              Positioned(
                top: 6 * s,
                right: 6 * s,
                child: IntroSelectionMotion(
                  selected: selected,
                  child: IntroMedal('✓', size: 34 * s),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _compactCard(BuildContext context) => Semantics(
    label: title,
    selected: selected,
    inMutuallyExclusiveGroup: true,
    button: true,
    onTap: onTap,
    child: IntroPressable(
      key: ValueKey('onboarding-purpose-$id'),
      onTap: onTap,
      pressScale: .995,
      surfaceDepth: 0,
      child: ExcludeSemantics(
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xfffff5e8),
                borderRadius: BorderRadius.circular(IntroGeometry.interest),
                border: Border.all(color: const Color(0xffd2b991)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x603d2b12),
                    offset: Offset(0, 2),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(2),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(IntroGeometry.interestArt),
                      ),
                      child: LayoutBuilder(
                        builder: (context, bounds) => Stack(
                          fit: StackFit.expand,
                          children: [
                            CIntroArt(
                              [
                                'interest-travel',
                                'interest-culture',
                                'interest-study',
                                'interest-kcontent',
                              ][index],
                              fit: BoxFit.contain,
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: IntroSelectionMotion(
                                selected: selected,
                                child: IntroMedal(
                                  '✓',
                                  size: (bounds.maxHeight - 4).clamp(0, 28),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 40,
                    child: Center(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: IntroTypography.localized(
                          context,
                          IntroTypography.interestLabel(1),
                        ).copyWith(fontSize: 16, height: 1.15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(IntroGeometry.interest),
                    border: Border.all(color: IntroPalette.jade, width: 4),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class IntroReferenceLevelSheet extends StatelessWidget {
  const IntroReferenceLevelSheet({
    super.key,
    required this.copy,
    required this.draft,
    required this.beginner,
    required this.onSelect,
    required this.onClose,
    required this.apply,
  });
  final OnboardingV2Copy copy;
  final String? draft;
  final bool beginner;
  final void Function(String, bool) onSelect;
  final VoidCallback onClose;
  final Widget apply;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final s = bounds.maxWidth / 402;
      final t = AppL10n.of(context);
      Widget at(double x, double y, double w, double h, Widget child) =>
          Positioned(
            left: x * s,
            top: y * s,
            width: w * s,
            height: h * s,
            child: child,
          );
      Widget words(
        String text,
        double size, {
        bool bold = false,
        bool serif = false,
        Color color = IntroPalette.ink,
      }) => Text(
        text,
        textAlign: TextAlign.center,
        style: IntroTypography.localized(
          context,
          IntroTypography.levelWords(size, s, serif, bold, color),
        ),
      );
      Widget option(
        String code,
        String hint,
        bool isBeginner,
        bool selected,
      ) => Semantics(
        label: '$code. $hint',
        selected: selected,
        inMutuallyExclusiveGroup: true,
        button: true,
        onTap: () => onSelect(isBeginner ? 'A1' : code, isBeginner),
        child: IntroPressable(
          key: ValueKey(
            isBeginner ? 'onboarding-v3-new' : 'onboarding-v2-level-$code',
          ),
          onTap: () => onSelect(isBeginner ? 'A1' : code, isBeginner),
          pressScale: .995,
          surfaceDepth: 0,
          child: ExcludeSemantics(
            child: Container(
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xfff5f0db)
                    : const Color(0xfffff8ec),
                image: DecorationImage(
                  image: const AssetImage(
                    '${CIntroArt.directory}/intro-paper-footer.png',
                  ),
                  fit: BoxFit.cover,
                  opacity: selected ? .55 : .85,
                ),
                borderRadius: BorderRadius.circular(IntroGeometry.interest * s),
                border: Border.all(
                  color: selected ? IntroPalette.jade : const Color(0xffcfa25f),
                  width: (selected ? 4 : 1) * s,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66ac8048),
                    offset: Offset(0, 1.5),
                    blurRadius: 1,
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (selected)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              IntroGeometry.selectionInset * s,
                            ),
                            border: Border.all(
                              color: IntroPalette.brass,
                              width: .8 * s,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (isBeginner)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        words(code, 24, bold: true),
                        words(hint, 14, color: IntroPalette.mutedInk),
                      ],
                    )
                  else
                    words(code, 35, serif: true, bold: true),
                  Positioned(
                    top: 11 * s,
                    right: 11 * s,
                    child: IntroSelectionMotion(
                      selected: selected,
                      child: IntroMedal('✓', size: 34 * s),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      return SizedBox(
        height: 520 * s + MediaQuery.paddingOf(context).bottom,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(IntroGeometry.levelSheet * s),
          ),
          child: Stack(
            children: [
              at(
                0,
                -184,
                402,
                704,
                const CIntroArt('paper-footer', fit: BoxFit.fill),
              ),
              at(
                169,
                0,
                64,
                48,
                Semantics(
                  button: true,
                  label: t.btnClose,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onClose,
                    child: Align(
                      alignment: const Alignment(0, -.30),
                      child: Container(
                        width: 46 * s,
                        height: 5 * s,
                        decoration: BoxDecoration(
                          color: const Color(0xffbda783),
                          borderRadius: BorderRadius.circular(
                            IntroGeometry.handle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              at(
                16,
                33,
                300,
                36,
                Align(
                  alignment: Alignment.centerLeft,
                  child: Semantics(
                    header: true,
                    child: words(t.introChooseLevel, 28.7, bold: true),
                  ),
                ),
              ),
              Positioned(
                left: 307 * s,
                top: 50 * s - 24,
                width: 79 * s,
                height: 48,
                child: SoriTextAction(
                  key: const ValueKey('c-onboarding-sheet-close'),
                  label: t.btnClose,
                  onPressed: onClose,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerRight,
                  ),
                  maxLines: 1,
                  softWrap: false,
                  textStyle: IntroTypography.localized(
                    context,
                    IntroTypography.sheetClose(s),
                  ),
                ),
              ),
              at(
                16,
                80,
                370,
                66,
                option(t.introNew, t.introNewHint, true, beginner),
              ),
              for (var i = 0; i < copy.setup.levels.length; i++)
                at(
                  i.isEven ? 16 : 207,
                  161 + 76 * (i ~/ 2).toDouble(),
                  180,
                  64,
                  option(
                    copy.setup.levels[i].code,
                    copy.setup.levels[i].name,
                    false,
                    !beginner &&
                        draft?.toLowerCase() ==
                            copy.setup.levels[i].code.toLowerCase(),
                  ),
                ),
              at(
                16,
                392,
                370,
                23,
                words(t.introLevelLater, 15.5, color: IntroPalette.mutedInk),
              ),
              at(16, 429, 370, 58, apply),
            ],
          ),
        ),
      );
    },
  );
}
