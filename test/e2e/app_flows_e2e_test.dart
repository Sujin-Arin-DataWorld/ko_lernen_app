import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/main.dart';
import 'package:ko_lernen_app/features/onboarding_v2/first_run_runtime.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/screens/app_shell.dart';
import 'package:ko_lernen_app/screens/consent_screen.dart';
import 'package:ko_lernen_app/screens/splash_screen.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/data_migration_service.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/window_class.dart';

/// 핵심 사용자 흐름 E2E — **CI 에서 매번 도는** 전체 앱 테스트.
///
/// `integration_test/app_flows_test.dart` 는 실기기/에뮬레이터에서만 돌아 CI 회귀
/// 그물에 들어가지 않는다. 그래서 같은 흐름을 전체 앱 위젯 테스트로도 고정한다 —
/// `KoLernenApp` 을 통째로 pump 하고 스플래시 분기를 실제로 통과시킨다.
///
/// Firebase 는 여기서 초기화되지 않는다. 그게 오히려 이 테스트의 가치다:
/// **클라우드가 전혀 없는 기기에서도 앱이 뜨고 학습 진도가 남아야 한다**는
/// 오프라인 우선 계약을 그대로 검증한다.
///
/// ## ⚠️ 전체 앱 pump 횟수 상한 (건드리기 전에 읽을 것)
///
/// 한 테스트 **파일** 안에서 `KoLernenApp` 을 여러 번 pump 하면, 대략 12회를
/// 넘어가는 순간 테스트 프로세스가 **종료되지 않는다** (flutter_tools 가
/// `Bad state: Cannot add event while adding stream` 으로 죽고 러너가 매달린다).
/// 개별 테스트는 전부 통과하는데 스위트 전체가 멈추므로, CI 에 넣으면 잡 하나가
/// 통째로 타임아웃된다 — 2026-08-06 에 실측으로 확인했다.
///
/// 그래서 [launch] 호출은 **6회로 묶어 둔다**. 앱이 실제로 떠야만 알 수 있는
/// 성질(스플래시 분기, 손상 데이터로도 부팅, 폭별 배치)에만 쓰고, 저장소 계약은
/// 앱을 띄우지 않고 검증한다. 새 테스트를 더할 때 [launch] 를 쓰려면 기존 것을
/// 하나 줄이거나, 앱 없이 같은 성질을 볼 수 있는지 먼저 따져 볼 것.
///
/// (근본 원인인 자원 누수는 별도 트랙이다. 상한을 늘리기 전에 그걸 먼저 고친다.)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const viewports = <String, Size>{
    'compact': Size(360, 800),
    'medium': Size(800, 1280),
    'expanded': Size(1280, 800),
  };

  /// 앱을 "설치 직후 + 주어진 로컬 상태" 로 되돌린다.
  Future<void> freshInstall([Map<String, Object> seed = const {}]) async {
    Storage.resetForTesting();
    DataMigrationService.resetForTesting();
    Storage.unlockLearningWrites();
    SharedPreferences.setMockInitialValues(seed);
    // ⚠️ setMockInitialValues 만으로는 부족하다 — 이미 만들어진
    // SharedPreferences 인스턴스가 자기 메모리 캐시를 들고 있어서 앞 테스트가 쓴
    // 값이 그대로 보인다(실제로 단어장 중복 테스트가 그렇게 깨졌다).
    // reload() 가 플랫폼(= 새 mock)에서 전부 다시 읽어 온다.
    await Storage.init();
    await (await SharedPreferences.getInstance()).reload();
    Storage.resetCachesAfterExternalWrite();
    DataLoader.reset();
    ScenarioLoader.reset();
  }

  /// 단어장 저장에 쓰는 최소 단어. 실제 `addToWordbook` 이 넘기는 모양과 같다.
  ExtractedWord word(String korean, String translation) => ExtractedWord(
    korean: korean,
    romanization: '',
    posDe: 'Nomen',
    translationDe: translation,
    translationEn: translation,
    exampleKorean: '',
    exampleDe: '',
    definitionKo: '',
    imagePath: '',
    savedToPackId: null,
  );

  /// 앱을 띄우고 테스트 전용 0초 스플래시를 통과시킨다.
  /// **호출 총량은 위 상한을 지킬 것.**
  Future<void> launch(WidgetTester tester, {required Size size}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      KoLernenApp(
        splashDisplayDuration: Duration.zero,
        firstRunCoordinator: FirstRunRuntime.createCoordinator(),
      ),
    );
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);

    for (
      var frame = 0;
      frame < 20 && find.byType(SplashScreen).evaluate().isNotEmpty;
      frame++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> teardownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  // ── 전체 앱 pump 를 쓰는 테스트 (6회) ─────────────────────────────────────

  group('앱 시작 분기', () {
    testWidgets('신규 사용자는 온보딩으로 간다 [launch 1/6]', (tester) async {
      await freshInstall();
      await launch(tester, size: viewports['compact']!);

      expect(find.byType(ConsentScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await teardownApp(tester);
    });

    for (final viewport in viewports.entries) {
      testWidgets('기존 사용자는 홈까지 도달한다 @ ${viewport.key} [launch 2-4/6]', (
        tester,
      ) async {
        // Firebase 는 이 테스트에서 초기화되지 않는다 = "클라우드 미구성 기기".
        await freshInstall({
          'kl_consent_accepted': true,
          'kl_onboarding_completed': true,
          'kl_session_count': 5,
          'kl_user_level': 'a1',
        });
        await launch(tester, size: viewport.value);

        expect(
          find.byType(AppShell),
          findsOneWidget,
          reason: '클라우드 부재가 앱 시작을 막으면 안 된다',
        );
        expect(tester.takeException(), isNull);

        // 앱 전체가 같은 창 분류를 본다 — 화면마다 다른 기준을 쓰면 여기서 깨진다.
        expect(
          appWindowClassOf(tester.element(find.byType(AppShell))),
          AppWindowClass.values.byName(viewport.key),
        );
        await teardownApp(tester);
      });
    }
  });

  group('손상된 로컬 데이터로 시작해도 앱이 뜬다', () {
    testWidgets('SRS blob 이 깨져 있어도 홈까지 간다 [launch 5/6]', (tester) async {
      await freshInstall({
        'kl_consent_accepted': true,
        'kl_onboarding_completed': true,
        'kl_session_count': 5,
        'kl_srs_v1': '{"사과": {"e": 2.5,',
      });
      await launch(tester, size: viewports['compact']!);

      expect(find.byType(AppShell), findsOneWidget);
      expect(tester.takeException(), isNull);
      await teardownApp(tester);
    });

    testWidgets('팩 진행도가 깨져 있어도 홈까지 간다 [launch 6/6]', (tester) async {
      await freshInstall({
        'kl_consent_accepted': true,
        'kl_onboarding_completed': true,
        'kl_session_count': 5,
        'kl_pack_progress_v1': 'not json at all',
      });
      await launch(tester, size: viewports['compact']!);

      expect(find.byType(AppShell), findsOneWidget);
      expect(tester.takeException(), isNull);
      await teardownApp(tester);
    });
  });

  // ── 앱을 띄우지 않고 검증하는 저장소 계약 ────────────────────────────────
  // 전체 앱 pump 가 필요 없는 성질들. 위 상한을 지키려고 여기로 분리했다.

  group('앱 재시작 후 진도 유지', () {
    test('학습 진도가 디스크에 남고 재시작이 그대로 읽는다', () async {
      await freshInstall({'kl_onboarding_completed': true});

      await Storage.srsReview('학교', gotIt: true);
      await Storage.srsReview('사과', gotIt: false);
      await Storage.addXp(25);

      final persisted = <String, Object>{
        'kl_onboarding_completed': true,
        'kl_srs_v1': Storage.srsRawJson,
        'kl_xp': Storage.xp,
      };
      expect(persisted['kl_srs_v1'], isNot(isEmpty));

      // 재시작 — 디스크에 남은 값으로 다시 부팅한다.
      await freshInstall(persisted);

      expect(Storage.xp, persisted['kl_xp']);
      expect(Storage.srsRawJson, persisted['kl_srs_v1']);
      expect(
        Storage.vocabMastery('학교'),
        isNot(MasteryState.fresh),
        reason: '재시작에서 학습 이력이 사라지면 사용자는 앱을 신뢰하지 않는다',
      );
    });

    test('저장한 단어가 재시작 뒤에도 있다', () async {
      await freshInstall({'kl_onboarding_completed': true});

      final added = await CustomPackService.quickAdd(
        defaultPackName: '⭐',
        word: word('사과', 'Apfel'),
      );
      expect(added, WordbookAddResult.added);
      final saved = Storage.customPacksRawJson;
      expect(saved, contains('사과'));

      await freshInstall({
        'kl_onboarding_completed': true,
        'kl_custom_packs_v1': saved,
      });

      final packs = CustomPackService.getAll();
      expect(packs.any((p) => p.words.any((w) => w.korean == '사과')), isTrue);
    });

    test('같은 단어를 다시 저장해도 중복되지 않는다', () async {
      await freshInstall({'kl_onboarding_completed': true});

      await CustomPackService.quickAdd(
        defaultPackName: '⭐',
        word: word('사과', 'Apfel'),
      );
      final again = await CustomPackService.quickAdd(
        defaultPackName: '⭐',
        word: word('사과', 'Apfel'),
      );

      expect(again, isNot(WordbookAddResult.added));
    });
  });

  group('전체 데이터 초기화', () {
    test('초기화 뒤에는 학습 데이터가 남지 않는다', () async {
      await freshInstall({'kl_onboarding_completed': true});

      await Storage.srsReview('사과', gotIt: true);
      await Storage.addXp(40);
      expect(Storage.srsRawJson, isNot(isEmpty));

      await Storage.resetAll();

      expect(Storage.srsRawJson, isEmpty);
      expect(Storage.xp, 0);
    });
  });

  group('스키마 마이그레이션', () {
    test('기존 설치가 baseline 도장을 받는다', () async {
      await freshInstall({
        'kl_onboarding_completed': true,
        'kl_srs_v1': jsonEncode({
          '사과': {'e': 2.5, 'i': 3, 'n': '2026-01-01', 'r': 2},
        }),
      });
      final prefs = await SharedPreferences.getInstance();
      final result = await DataMigrationService.run(preferences: prefs);

      expect(result.fromVersion, 1);
      expect(result.writesAllowed, isTrue);
    });

    test('다운그레이드는 읽기를 살리고 쓰기만 잠근다', () async {
      await freshInstall({
        'kl_onboarding_completed': true,
        DataMigrationService.versionPreferenceKey: 99,
        'kl_srs_v1': jsonEncode({
          '사과': {'e': 2.5, 'i': 3, 'n': '2026-01-01', 'r': 2},
        }),
      });
      final prefs = await SharedPreferences.getInstance();
      await DataMigrationService.run(preferences: prefs, targetVersion: 1);

      expect(
        Storage.vocabMastery('사과'),
        isNot(MasteryState.fresh),
        reason: '쓰기만 잠그고 읽기는 살려야 사용자가 자기 데이터를 볼 수 있다',
      );

      final before = Storage.srsRawJson;
      await Storage.srsReview('바다', gotIt: true);
      expect(Storage.srsRawJson, before);

      Storage.unlockLearningWrites();
    });
  });
}
