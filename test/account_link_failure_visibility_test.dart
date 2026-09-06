import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/account/account_switch_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_ui_operations.dart';
import 'package:ko_lernen_app/widgets/sori/account_operation_ui.dart';

/// "아무 일도 일어나지 않는 버튼" 회귀.
///
/// Google 연동은 세 가지 이유로 끝날 수 있는데 예전에는 **셋이 전부 같은 결과**
/// 였다 — `AuthService.linkWithGoogle()` 이 Firebase 미초기화와 사용자 취소를
/// 둘 다 `null` 로 반환했고, UI 가 `null → Cancelled` 로 뭉개 아무 메시지도
/// 띄우지 않았다. 사용자에게는 눌러도 반응 없는 버튼이었다.
///
/// 이제 세 갈래가 **화면에서 서로 구별돼야 한다**:
/// - 사용자 취소 → 조용히 닫힘 (의도된 무반응)
/// - 시스템 불가 → 원인 안내, 재시도 버튼 없음(같은 실패가 반복될 뿐)
/// - 실제 실패 → 원인별 안내 + 재시도
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var runCount = 0;

  /// 연동 버튼을 눌러 확인 다이얼로그까지 통과시킨다.
  Future<void> startLink(
    WidgetTester tester,
    AccountUiLinkResult result,
  ) async {
    runCount++;
    // ⚠️ ProductionAccountUiOperations 를 쓰지 않는다. 그쪽은 링크를 실제
    // AuthService 의 durable admission 레인에 넣어 Firebase/Storage 를 건드리고,
    // 이 테스트의 주제(= UI 가 결과를 어떻게 화면으로 옮기는지)와 무관하게 멈춘다.
    final operations = _FixedResultOperations(result);

    await tester.pumpWidget(
      MaterialApp(
        // 같은 tester 안에서 여러 번 호출될 때 Navigator 가 갱신이 아니라
        // **교체**되도록 강제한다. 키가 같으면 앞 케이스의 다이얼로그가 라우트
        // 스택에 남아 다음 케이스 판정을 오염시킨다.
        key: ValueKey<String>('link-harness-${result.runtimeType}-$runCount'),
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => runConfirmedAccountLink(
                context,
                operations: operations,
                provider: AccountLinkProvider.google,
              ),
              child: const Text('connect'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('connect'));
    await tester.pumpAndSettle();

    // 안전 연결 확인 다이얼로그의 확인 버튼.
    final t = AppL10n.of(tester.element(find.text('connect')));
    await tester.tap(find.text(t.accountSafeConnectConfirm));

    // ⚠️ pumpAndSettle 을 쓰면 안 된다 — 진행 다이얼로그의
    // CircularProgressIndicator 가 영원히 도는 애니메이션이라 settle 되지 않는다.
    // 다이얼로그 전환이 끝날 만큼만 프레임을 진행시킨다.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  AppL10n l10n(WidgetTester tester) =>
      AppL10n.of(tester.element(find.text('connect')));

  testWidgets('사용자 취소는 조용히 닫힌다', (tester) async {
    await startLink(tester, const AccountUiLinkCancelled());

    final t = l10n(tester);
    expect(find.text(t.accountLinkUnavailableBody), findsNothing);
    expect(find.text(t.accountLinkFailedBody), findsNothing);
    expect(find.text(t.accountLinkOfflineBody), findsNothing);
    // 진행 표시도 닫혀 있어야 한다 — 남아 있으면 앱이 멈춘 것처럼 보인다.
    expect(find.text(t.accountOperationInProgress), findsNothing);
  });

  testWidgets('🔴 Firebase 불가는 취소로 뭉개지지 않고 원인을 보여 준다', (tester) async {
    await startLink(tester, const AccountUiLinkUnavailable());

    final t = l10n(tester);
    expect(find.text(t.accountLinkUnavailableTitle), findsOneWidget);
    expect(find.text(t.accountLinkUnavailableBody), findsOneWidget);
  });

  testWidgets('시스템 불가에는 재시도 버튼을 주지 않는다', (tester) async {
    await startLink(tester, const AccountUiLinkUnavailable());

    final t = l10n(tester);
    expect(
      find.text(t.btnRetry),
      findsNothing,
      reason: '같은 실패가 반복될 버튼을 주면 또 다른 "아무 일도 없는 버튼"이 된다',
    );
    expect(find.text(t.btnClose), findsOneWidget);
  });

  testWidgets('오프라인은 오프라인 문구를 보여 준다', (tester) async {
    await startLink(
      tester,
      const AccountUiLinkFailed(AccountUiLinkFailureReason.offline),
    );

    final t = l10n(tester);
    expect(find.text(t.accountLinkOfflineTitle), findsOneWidget);
    expect(find.text(t.accountLinkOfflineBody), findsOneWidget);
    expect(find.text(t.accountLinkUnavailableBody), findsNothing);
  });

  testWidgets('서버 오류는 재시도를 제공한다', (tester) async {
    await startLink(
      tester,
      const AccountUiLinkFailed(AccountUiLinkFailureReason.serverError),
    );

    final t = l10n(tester);
    expect(find.text(t.accountLinkFailedTitle), findsOneWidget);
    expect(find.text(t.btnRetry), findsOneWidget);
  });

  testWidgets('세 갈래가 서로 다른 화면을 낸다', (tester) async {
    // 같은 화면이 나오면 사용자는 원인을 구별할 수 없다.
    final shown = <String, bool>{};

    for (final entry in <String, AccountUiLinkResult>{
      'cancelled': const AccountUiLinkCancelled(),
      'unavailable': const AccountUiLinkUnavailable(),
      'offline': const AccountUiLinkFailed(AccountUiLinkFailureReason.offline),
    }.entries) {
      await startLink(tester, entry.value);
      final t = l10n(tester);
      shown['${entry.key}:unavailable'] = find
          .text(t.accountLinkUnavailableTitle)
          .evaluate()
          .isNotEmpty;
      shown['${entry.key}:offline'] = find
          .text(t.accountLinkOfflineTitle)
          .evaluate()
          .isNotEmpty;
    }

    expect(shown['cancelled:unavailable'], isFalse);
    expect(shown['cancelled:offline'], isFalse);
    expect(shown['unavailable:unavailable'], isTrue);
    expect(shown['unavailable:offline'], isFalse);
    expect(shown['offline:unavailable'], isFalse);
    expect(shown['offline:offline'], isTrue);
  });

  group('AccountLinkUnavailable 예외', () {
    test('취소(null)와 구별되는 타입이다', () {
      // AuthService 가 던지는 계약. 이 타입이 사라지면 UI 계층이 다시
      // null 하나로 두 상황을 판단하게 된다.
      const unavailable = AccountLinkUnavailable();
      expect(unavailable, isA<Exception>());
      expect(unavailable.toString(), contains('unavailable'));
    });
  });
}

/// 정해진 결과만 돌려주는 최소 fake. 이 테스트의 주제는 결과 → 화면 매핑이다.
class _FixedResultOperations implements AccountUiOperations {
  _FixedResultOperations(this.result);

  final AccountUiLinkResult result;

  @override
  bool get appleSignInAvailable => false;

  @override
  Future<AccountUiLinkResult> link(AccountLinkProvider provider) async => result;

  @override
  Future<AccountSwitchResult> switchToExisting(
    ExistingAccountLinkConflict conflict,
  ) async => const AccountSwitchResult(AccountSwitchStatus.failed);
}
