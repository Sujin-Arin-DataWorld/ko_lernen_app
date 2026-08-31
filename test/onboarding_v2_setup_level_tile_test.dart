import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_setup_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_presentation.dart';
import 'package:ko_lernen_app/theme.dart';

// 2026-08-31 실기기: 360dp 2열 레벨 타일(폭 ~90dp)에서 독일어 합성어 라벨
// "Grundkenntnisse"(A2), "Expertenniveau"(C2) 는 줄바꿈 기회가 없어서
// Flutter 가 글자 사이를 끊었다 — "Grundkenntniss/e", "Expertennivea/u".
// `_LevelTile` 라벨을 `lib/widgets/sori/adaptive_navigation.dart` 와 같은
// 관용구로 고쳤다: `FittedBox(fit: BoxFit.scaleDown)` + `maxLines: 1` +
// `softWrap: false` — 줄바꿈/말줄임 대신 전체 단어를 축소한다.
const _levelsUnderTest = <(String code, String label)>[
  ('A2', 'Grundkenntnisse'),
  ('C2', 'Expertenniveau'),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final scale in <double>[1.0, 1.3, 2.0]) {
    testWidgets(
      'German level tile labels stay on one line at 360dp (×$scale)',
      (tester) async {
        await _pump(tester, textScale: scale);

        for (final (code, label) in _levelsUnderTest) {
          final tile = find.byKey(ValueKey('onboarding-v2-level-$code'));
          expect(tile, findsOneWidget, reason: code);

          final labelFinder = find.descendant(
            of: tile,
            matching: find.text(label),
          );
          expect(labelFinder, findsOneWidget, reason: label);

          // 실제로 몇 줄로 그려졌는지 본다 — 예외는 안 나므로
          // "no exception" 회귀만으로는 글자 사이 줄바꿈을 못 잡는다.
          // cardSubtitle 은 fontSize 12 · height 1.35 → 한 줄 ≈16.2px(×scale).
          // 두 줄로 쪼개지면(글자 사이 줄바꿈 포함) 대략 그 2배가 된다.
          expect(
            tester.getSize(labelFinder).height,
            lessThan(16.2 * scale * 1.9),
            reason: '$label wrapped mid-word onto a second line',
          );
          // `maxLines: 1` 인데도 줄이 넘쳐 잘렸다면(= FittedBox 없이 폭이
          // 좁아졌다면) `didExceedMaxLines` 가 true 가 된다.
          final paragraph = tester.renderObject<RenderParagraph>(labelFinder);
          expect(
            paragraph.didExceedMaxLines,
            isFalse,
            reason: '$label was truncated instead of scaled down',
          );

          // `Text` 자체는 `softWrap: false` 라 자연 폭 그대로 레이아웃된다 —
          // 화면이 실제로 내주는 폭은 이를 축소하는 `FittedBox` 쪽이다.
          final fittedBox = find.ancestor(
            of: labelFinder,
            matching: find.byType(FittedBox),
          );
          expect(fittedBox, findsOneWidget, reason: label);
          final fittedRect = tester.getRect(fittedBox);
          final tileRect = tester.getRect(tile);
          expect(
            fittedRect.right,
            lessThanOrEqualTo(tileRect.right + 0.5),
            reason: '$label overflows its level tile',
          );
        }

        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _pump(WidgetTester tester, {required double textScale}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Builder(
        builder: (context) => OnboardingSetupScreen(
          copy: onboardingV2Copy(AppL10n.of(context)),
          selectedPurposeId: OnboardingV2Ids.purposeKContent,
          selectedLevelCode: null,
          onPurposeChanged: (_) {},
          onLevelChanged: (_) {},
          onContinue: (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
}
