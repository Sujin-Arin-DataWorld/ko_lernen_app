import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/ildu_construction_plan.dart';
import 'package:ko_lernen_app/models/ildu_construction_progress.dart';
import 'package:ko_lernen_app/screens/ildu_learning_module_screen.dart';
import 'package:ko_lernen_app/services/ildu_construction_progress_service.dart';

/// Phase 3 학습 모듈 화면 계약: 섹션 순서(한자→역사→비판적 렌즈→2026 장면→
/// 한국어 행동), 초안 보존, 저작 기준 평가 통과 시에만 완료·pop(true).
void main() {
  late IlDuEstateConstructionPlan plan;

  setUpAll(() async {
    plan = await _loadPlanFromDisk();
  });

  Future<void> pumpModule(
    WidgetTester tester, {
    required String moduleId,
    required MemoryProgressStore store,
    void Function(Object?)? onResult,
  }) async {
    tester.view.physicalSize = const Size(1179, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              key: const ValueKey('open-module'),
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => IlDuLearningModuleScreen(
                      args: IlDuLearningModuleArgs(
                        anchorId: 'sarangchae',
                        buildingId: 'sarangchae',
                        moduleId: moduleId,
                      ),
                      loadPlan: () async => plan,
                      progressStore: store,
                    ),
                  ),
                );
                onResult?.call(result);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-module')));
    await tester.pumpAndSettle();
  }

  testWidgets('keeps the authored section order without a hanja block', (
    tester,
  ) async {
    await pumpModule(
      tester,
      moduleId: 'sarangchae-site-language',
      store: MemoryProgressStore(),
    );

    expect(find.byKey(const ValueKey('ildu-module-hanja')), findsNothing);
    final order = <String>[
      'ildu-module-history',
      'ildu-module-critical-lens',
      'ildu-module-modern-scene',
      'ildu-module-scene-line',
      'ildu-module-action-prompt',
      'ildu-module-input',
      'ildu-module-target-hint',
    ];
    double? previous;
    for (final key in order) {
      final finder = find.byKey(ValueKey(key));
      expect(finder, findsOneWidget, reason: '$key must render.');
      final top = tester.getTopLeft(finder).dy;
      if (previous != null) {
        expect(
          top,
          greaterThan(previous),
          reason: '$key must come after the previous section.',
        );
      }
      previous = top;
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the hanja phrase first when the plaque has hanja', (
    tester,
  ) async {
    await pumpModule(
      tester,
      moduleId: 'baekse-cheongpung-2026',
      store: MemoryProgressStore(),
    );

    final hanja = find.byKey(const ValueKey('ildu-module-hanja'));
    expect(hanja, findsOneWidget);
    expect(tester.widget<Text>(hanja).data, '百世淸風');
    expect(
      tester.getTopLeft(hanja).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('ildu-module-history'))).dy,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('an authored answer completes the module and pops true', (
    tester,
  ) async {
    final store = MemoryProgressStore();
    Object? popped = 'unset';
    await pumpModule(
      tester,
      moduleId: 'sarangchae-site-language',
      store: store,
      onResult: (result) => popped = result,
    );

    await tester.enterText(
      find.byKey(const ValueKey('ildu-module-input')),
      '일단 정리부터 시작하자.',
    );
    await tester.tap(find.byKey(const ValueKey('ildu-module-submit')));
    await tester.pumpAndSettle();

    expect(popped, isTrue);
    final saved = IlDuConstructionProgress.fromJson(jsonDecode(store.value!));
    final anchor = saved.anchorFor('sarangchae')!;
    expect(anchor.completedModuleIds, contains('sarangchae-site-language'));
    expect(anchor.completedStageIds, contains('sarangchae-site'));
    expect(anchor.draftsByModuleId, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a non-matching answer shows the hint and never pops', (
    tester,
  ) async {
    final store = MemoryProgressStore();
    Object? popped = 'unset';
    await pumpModule(
      tester,
      moduleId: 'sarangchae-site-language',
      store: store,
      onResult: (result) => popped = result,
    );

    await tester.enterText(
      find.byKey(const ValueKey('ildu-module-input')),
      '안녕하세요',
    );
    await tester.tap(find.byKey(const ValueKey('ildu-module-submit')));
    await tester.pumpAndSettle();

    expect(popped, 'unset');
    expect(
      find.byKey(const ValueKey('ildu-module-missing-hint')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('ildu-module-input')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drafts persist across a close and restore on reopen', (
    tester,
  ) async {
    final store = MemoryProgressStore();
    await pumpModule(
      tester,
      moduleId: 'sarangchae-site-language',
      store: store,
    );

    await tester.enterText(
      find.byKey(const ValueKey('ildu-module-input')),
      '먼저 자리를',
    );
    await tester.pump(const Duration(milliseconds: 500));

    final saved = IlDuConstructionProgress.fromJson(jsonDecode(store.value!));
    expect(
      saved.anchorFor('sarangchae')!.draftsByModuleId,
      containsPair('sarangchae-site-language', '먼저 자리를'),
    );

    // 화면을 닫았다가 같은 저장소로 다시 연다 → 초안이 복원된다.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-module')));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('ildu-module-input')),
    );
    expect(field.controller!.text, '먼저 자리를');
    expect(tester.takeException(), isNull);
  });
}

Future<IlDuEstateConstructionPlan> _loadPlanFromDisk() async {
  final index = jsonDecode(
    await File(
      'assets/data/ildu_construction/estate_plan_v1.json',
    ).readAsString(),
  );
  final building = jsonDecode(
    await File(
      'assets/data/ildu_construction/sarangchae_v1.json',
    ).readAsString(),
  );
  return IlDuEstateConstructionPlan.fromJson(index, {'sarangchae': building});
}

final class MemoryProgressStore implements IlDuConstructionProgressStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String encoded) async {
    value = encoded;
  }
}
