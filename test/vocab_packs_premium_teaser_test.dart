import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/vocab_packs_screen.dart';
import 'package:ko_lernen_app/widgets/sori/pack_card.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/premium_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';
import 'package:ko_lernen_app/theme.dart';

import 'support/access_sdk_harness.dart';

/// §H 프리미엄 티저 (2026-08-14) — 파괴-복원 센서.
///
/// A2+ 레벨의 프리미엄 잠금은 기존엔 **탭 후 인터스티셜에서만** 드러났다
/// (카드는 일반 카드처럼 보임 → 전환 기회 유실). 이 테스트는 세 가지를 고정한다:
/// 1. A2 브라우즈 + 비프리미엄 → 카드에 골드 왕관 칩(premium 상태)이 보인다.
/// 2. A1(무료 레벨)에는 왕관 칩이 없다.
/// 3. 알림값만으로 권한을 얻지 않으며, 서버 검증된 권한 갱신 뒤 칩이 사라진다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final access = AccessSdkHarness();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await access.initialize();
  });
  tearDownAll(access.dispose);

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_user_level': 'a1'});
    await Storage.init();
    DataLoader.reset();
    await access.setPremium(false);
  });

  tearDown(() {
    premiumNotifier.value = false;
  });

  Future<void> pumpPacks(WidgetTester tester) async {
    // CSV rootBundle 로드는 fake-async 안에서 안 풀린다 — 실비동기(runAsync)로
    // 서비스 캐시를 먼저 데운 뒤 화면을 올린다.
    await tester.runAsync(() => VocabPackService.loadAll());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const VocabPacksScreen(),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (tester.widgetList(find.byType(PackCard)).isNotEmpty) {
        break;
      }
    }
  }

  // _PremiumChip 의 아이콘. 앱바 도장첩 액션은 outlined 변형이라 겹치지 않는다.
  final crown = find.byIcon(Icons.workspace_premium_rounded);

  testWidgets('A2 비프리미엄 → 팩 카드에 골드 왕관 칩이 보인다', (tester) async {
    await Storage.setBrowseLevelCode('a2');
    await pumpPacks(tester);

    // 가드: 칩 부재가 "티저 회귀"인지 "팩 로드 실패"인지 구분한다.
    expect(find.byType(PackCard), findsWidgets);
    // 선행 잠금(자물쇠)이 왕관보다 우선하므로 — 해금된 첫 팩(들)에만 왕관.
    expect(crown, findsWidgets);
  });

  testWidgets('A1(무료 레벨)에는 왕관 칩이 없다', (tester) async {
    await Storage.setBrowseLevelCode('a1');
    await pumpPacks(tester);

    expect(crown, findsNothing);
  });

  testWidgets('알림값은 권한이 아니며 서버 검증 후 왕관 칩이 사라진다', (tester) async {
    await Storage.setBrowseLevelCode('a2');
    await pumpPacks(tester);
    expect(crown, findsWidgets);

    premiumNotifier.value = true;
    await tester.pump();
    expect(PremiumService.hasContentAccess, isFalse);
    expect(crown, findsWidgets);

    // Return the notification to the real current state, then exercise the
    // production SDK -> controller -> notifier update rather than minting access.
    await access.setPremium(false);
    await access.setPremium(true);
    await tester.pump();

    expect(PremiumService.isPremium, isTrue);
    expect(crown, findsNothing);
  });
}
