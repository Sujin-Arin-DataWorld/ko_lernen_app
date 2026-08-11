import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/mascot.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';
import 'package:ko_lernen_app/widgets/sori/tiger_video.dart';

void main() {
  // 테스트 불변식: videoReady=false(기본)면 비디오 플러그인 채널을 절대 건드리지
  // 않고 정적 Mascot 폴백으로 렌더된다.
  // 2026-08-06: 프레임 시퀀스(TigerStage)·Rive 폴백(TigerStageRive) 폐지 →
  // 기대값만 TigerStage → Mascot 으로 바뀌었고, 지키는 불변식은 동일하다.

  testWidgets('videoReady=false → Mascot 폴백', (tester) async {
    expect(TigerStageVideo.videoReady, isFalse);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TigerStageVideo(height: 160))),
    );
    await tester.pump();
    expect(find.byType(Mascot), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); // unmount → dispose 깨끗한지
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('reduce-motion → Mascot 폴백 (타이머 0)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: TigerStageVideo(height: 160),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Mascot), findsOneWidget);
  });

  testWidgets('TigerGreetClip: videoReady=false → Mascot 폴백', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TigerGreetClip(size: 200))),
    );
    await tester.pump();
    expect(find.byType(Mascot), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('explicit none hides preference-driven stage and greet clips', (
    tester,
  ) async {
    final original = MascotPreference.preference.value;
    MascotPreference.preference.value = CompanionPreference.none;
    addTearDown(() => MascotPreference.preference.value = original);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(children: [TigerStageVideo(), TigerGreetClip()]),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Mascot), findsNothing);
    expect(find.byKey(const ValueKey('tiger-stage-no-companion')), findsOne);
    expect(find.byKey(const ValueKey('tiger-greet-no-companion')), findsOne);
  });
}
