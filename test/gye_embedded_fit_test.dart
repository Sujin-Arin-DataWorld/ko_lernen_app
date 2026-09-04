import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_gye_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

import 'support/real_fonts.dart';

/// §P5-1 완료 조건: 임베디드 Gye 탭이 390×844 에서 **스크롤 없이** CTA 에
/// 도달하고(±1줄), 셸 헤더가 유일한 대형 텍스트다 (임베디드 자체 헤드라인
/// 제거 — 화면당 1메시지).
///
/// §W-G G5.1/G5.5: 탭이 슬리버 구조(`CustomScrollView`)로 바뀐 뒤 이
/// 계약을 지키려면 실서체가 필요해졌다 — `SliverList`는 뷰포트 +
/// cacheExtent 안에 들어오는 자식만 빌드하는데, 테스트 폰트(모든 글리프가
/// 고정 1em 정사각형)는 캡션·칩 카드 3장·프라이버시 카드 텍스트를 실제보다
/// 2~3배 부풀려 CTA를 그 cacheExtent 밖으로 밀어낸다(`find.text`가 0개를
/// 반환 — 오프스크린이 아니라 아예 빌드되지 않은 상태). `loadSoriRealFonts()`
/// (`test/support/real_fonts.dart`, W-F 신설)로 실측 폭을 쓰면 원래 CTA
/// 868 계약의 의도(첫 화면 도달)가 다시 성립한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadSoriRealFonts);

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_tut_gye_tab': true,
    });
    await Storage.init();
  });

  testWidgets('embedded Gye: no duplicate headline, CTA reachable at 390×844', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const SoriStageGyeScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final t = await AppL10n.delegate.load(const Locale('de'));

    // 셸 헤더가 유일한 대형 텍스트 — 임베디드 자체 eyebrow/헤드라인/리드 없음.
    expect(find.text(t.soriStageGyePromise), findsOneWidget);
    expect(
      find.text(t.gyeEmptyHeadline),
      findsNothing,
      reason: '임베디드에서는 자체 헤드라인을 제거한다 (§P5-1-1)',
    );
    expect(find.text(t.gyeVoluntaryEyebrow), findsNothing);

    // CTA 가 스크롤 없이 화면 안에 있다 (±1줄 = 24px 허용).
    final cta = find.text(t.gyeFindOrCreate);
    expect(cta, findsOneWidget, reason: 'CTA 는 첫 화면에서 빌드되어야 한다');
    final rect = tester.getRect(cta);
    expect(
      rect.bottom,
      lessThanOrEqualTo(844 + 24),
      reason: '390×844 에서 스크롤 없이 CTA 도달 (±1줄)',
    );
    expect(tester.takeException(), isNull);
  });
}
