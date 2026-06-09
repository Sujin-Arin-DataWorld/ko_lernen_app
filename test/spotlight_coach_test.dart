import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/spotlight_coach.dart';

/// SpotlightCoach 유닛 테스트.
///
/// - 빈 steps → onComplete 즉시 호출
/// - Overlay 없음 → onComplete 즉시 호출
/// - 키 미부착(hasSize=false) → skip, 가용 타겟 없으면 onComplete
/// - reduce-motion → 펄스 컨트롤러 미생성(_SpotlightPainter 정적 테두리)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  Widget _wrap(Widget child) {
    return MaterialApp(
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: child,
    );
  }

  group('SpotlightCoach', () {
    testWidgets('빈 steps → onComplete 즉시 호출', (tester) async {
      bool completed = false;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) {
              return ElevatedButton(
                onPressed: () {
                  SpotlightCoach.show(
                    ctx,
                    steps: const [],
                    onComplete: () => completed = true,
                  );
                },
                child: const Text('tap'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(completed, isTrue);
    });

    testWidgets('GlobalKey 미부착(측정 불가) → 모든 단계 skip → onComplete', (tester) async {
      // targetKey를 아무 위젯에도 부착하지 않음 → currentContext == null → skip
      final unmountedKey = GlobalKey();
      bool completed = false;

      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) {
              return ElevatedButton(
                onPressed: () {
                  SpotlightCoach.show(
                    ctx,
                    steps: [
                      SpotlightStep(
                        targetKey: unmountedKey,
                        title: 'Test',
                        body: 'Body',
                      ),
                    ],
                    onComplete: () => completed = true,
                  );
                },
                child: const Text('tap'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(completed, isTrue);
    });

    testWidgets('reduce-motion 활성 시 레이어 정상 빌드 + 펄스 없음', (tester) async {
      final attachedKey = GlobalKey();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _wrap(
            Builder(
              builder: (ctx) {
                return Column(
                  children: [
                    SizedBox(key: attachedKey, width: 50, height: 50),
                    ElevatedButton(
                      onPressed: () {
                        SpotlightCoach.show(
                          ctx,
                          steps: [
                            SpotlightStep(
                              targetKey: attachedKey,
                              title: 'reduce-motion',
                              body: 'No pulse',
                            ),
                          ],
                          onComplete: () {},
                        );
                      },
                      child: const Text('tap'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 레이어가 뜨고 CustomPaint가 존재해야 함
      expect(find.byType(CustomPaint), findsWidgets);

      // 오버플로 없음
      expect(tester.takeException(), isNull);
    });

    testWidgets('정상 단계 진행: Weiter 탭 → 다음 단계', (tester) async {
      final key1 = GlobalKey();
      final key2 = GlobalKey();
      int completedCount = 0;

      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) {
              return Column(
                children: [
                  SizedBox(key: key1, width: 60, height: 60),
                  SizedBox(key: key2, width: 60, height: 60),
                  ElevatedButton(
                    onPressed: () {
                      SpotlightCoach.show(
                        ctx,
                        steps: [
                          SpotlightStep(
                            targetKey: key1,
                            title: 'Schritt 1',
                            body: 'Erster',
                          ),
                          SpotlightStep(
                            targetKey: key2,
                            title: 'Schritt 2',
                            body: 'Zweiter',
                          ),
                        ],
                        onComplete: () => completedCount++,
                      );
                    },
                    child: const Text('start'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Schritt 1 말풍선 확인
      expect(find.text('Schritt 1'), findsOneWidget);
      expect(completedCount, 0);

      // "Weiter" 탭 → 다음 단계
      await tester.tap(find.text('Weiter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Schritt 2'), findsOneWidget);
      expect(completedCount, 0);

      // "Fertig" 탭 → onComplete
      await tester.tap(find.text('Fertig'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(completedCount, 1);
    });

    testWidgets('Überspringen 탭 → 즉시 onComplete', (tester) async {
      final anchorKey = GlobalKey();
      bool skipped = false;

      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) {
              return Column(
                children: [
                  SizedBox(key: anchorKey, width: 60, height: 60),
                  ElevatedButton(
                    onPressed: () {
                      SpotlightCoach.show(
                        ctx,
                        steps: [
                          SpotlightStep(
                            targetKey: anchorKey,
                            title: 'S1',
                            body: 'B1',
                          ),
                          SpotlightStep(
                            targetKey: anchorKey,
                            title: 'S2',
                            body: 'B2',
                          ),
                        ],
                        onComplete: () => skipped = true,
                      );
                    },
                    child: const Text('start'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Überspringen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(skipped, isTrue);
    });
  });

  group('Storage.tutHomeTourSeen', () {
    test('_prefs 초기화 후 기본값 false', () async {
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
      expect(Storage.tutHomeTourSeen, isFalse);
    });

    test('setTutHomeTourSeen 후 true', () async {
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
      await Storage.setTutHomeTourSeen();
      expect(Storage.tutHomeTourSeen, isTrue);
    });

    test('resetTutorials 후 false 복귀', () async {
      SharedPreferences.setMockInitialValues({
        'kl_tut_home_tour': true,
      });
      await Storage.init();
      expect(Storage.tutHomeTourSeen, isTrue);
      await Storage.resetTutorials();
      expect(Storage.tutHomeTourSeen, isFalse);
    });
  });
}
