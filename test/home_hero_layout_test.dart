// 홈 히어로(캐릭터 mp4 밴드) 레이아웃·매트 계약 — 2026-08-06 Jin 실기기 회귀.
//
// 실기기 증상 두 가지를 고정한다:
//  ① 영상이 실제로 재생되기 시작하자 **그보다 먼저 그려지던** 로고·스트릭/레벨
//     칩·설정 아이콘·인사말이 통째로 사라졌다(자리는 비어 있고, 영상 뒤에 그려
//     지는 미션 카드 등은 정상). → 헤더/인사말이 영상보다 **나중에 paint** 되도록
//     `verticalDirection: up` 으로 순서를 역전했다. 배치는 그대로여야 한다.
//  ② 영상 사각형만 배경보다 밝게 떠 "액자"처럼 보였다. 흰 매트의
//     `multiply(흰색, blendColor)` 결과는 **정확히 blendColor 단색**이므로,
//     그 뒤 배경도 같은 평면 단색이어야 이음매가 사라진다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/home_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/character_clip.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

Widget _wrap(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: child,
);

Future<void> _pumpHome(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_wrap(const HomeScreen()));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_streak_days': 3,
      'kl_xp': 40,
    });
    await Storage.init();
    DataLoader.reset();
  });

  for (final kind in MascotKind.values) {
    group('${kind.name} 홈 히어로', () {
      setUp(() {
        MascotPreference.kind.value = kind;
      });
      tearDown(() {
        MascotPreference.kind.value = MascotKind.tiger;
      });

      testWidgets('헤더·인사말은 캐릭터 영상보다 위에 배치된다', (tester) async {
        await _pumpHome(tester);

        final clip = find.byType(CharacterClipPlayer);
        expect(clip, findsOneWidget);

        final clipTop = tester.getTopLeft(clip).dy;
        // 로고/워드마크 · 레벨 칩 · 설정 아이콘 — 셋 다 영상 위에 있어야 한다.
        for (final header in <Finder>[
          find.text('Hangul Sori'),
          find.textContaining('Lv '),
          find.byIcon(Icons.settings_outlined),
        ]) {
          expect(header, findsOneWidget);
          expect(
            tester.getBottomLeft(header).dy,
            lessThanOrEqualTo(clipTop),
            reason: '헤더 요소가 캐릭터 밴드 아래로 내려갔다',
          );
        }
      });

      testWidgets('헤더·인사말은 영상보다 나중에 paint 된다', (tester) async {
        await _pumpHome(tester);

        // 캐릭터 클립을 감싸는 안쪽 두 Column(히어로, 헤더+히어로)은 둘 다
        // paint 순서 역전 상태여야 한다. 이걸 되돌리면 실기기에서 헤더가 사라진다.
        final wrappers = tester
            .widgetList<Column>(
              find.ancestor(
                of: find.byType(CharacterClipPlayer),
                matching: find.byType(Column),
              ),
            )
            .take(2)
            .toList();

        expect(wrappers, hasLength(2));
        for (final column in wrappers) {
          expect(
            column.verticalDirection,
            VerticalDirection.up,
            reason:
                '영상을 먼저 그리기 위한 verticalDirection: up 이 사라졌다 '
                '— 안드로이드에서 헤더/인사말이 영상에 가려진다',
          );
        }
      });

      testWidgets('영상 매트는 히어로 배경과 같은 평면 단색으로 흡수된다', (tester) async {
        await _pumpHome(tester);

        final player = tester.widget<CharacterClipPlayer>(
          find.byType(CharacterClipPlayer),
        );
        expect(
          player.blendColor,
          SoriColors.lightBg,
          reason:
              'blendColor 는 홈 배경 상단 평면 구간과 같은 상수여야 한다 '
              '— 다르면 영상 사각형이 액자처럼 뜬다',
        );
      });

      testWidgets('밴드는 첫 화면 안에 들어오는 크기로 제한된다', (tester) async {
        await _pumpHome(tester);

        final clip = find.byType(CharacterClipPlayer);
        final size = tester.getSize(clip);
        expect(size.height, lessThanOrEqualTo(216.0));
        expect(size.height, size.width); // 정사각 클립 — 왜곡 금지
        expect(
          tester.getBottomLeft(clip).dy,
          lessThan(844.0),
          reason: '캐릭터 밴드가 첫 화면 밖으로 밀려났다',
        );
      });
    });
  }
}
