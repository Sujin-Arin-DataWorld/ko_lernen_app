import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/mascot.dart';
import 'package:ko_lernen_app/widgets/sori/tiger_stage.dart';
import 'package:ko_lernen_app/widgets/sori/tiger_video.dart';

void main() {
  // 테스트 불변식: videoReady=false(기본)면 비디오 플러그인 채널을 절대 건드리지
  // 않고 프레임/마스코트 폴백으로 렌더된다 (riveReady 패턴과 동일).

  testWidgets('videoReady=false → TigerStage frame fallback', (tester) async {
    expect(TigerStageVideo.videoReady, isFalse);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TigerStageVideo(height: 160))),
    );
    await tester.pump();
    expect(find.byType(TigerStage), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); // unmount → dispose 깨끗한지
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('reduce-motion → fallback (정지 프레임, 타이머 0)', (tester) async {
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
    expect(find.byType(TigerStage), findsOneWidget);
  });

  testWidgets('TigerGreetClip: videoReady=false → Mascot 폴백', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TigerGreetClip(size: 200))),
    );
    await tester.pump();
    expect(find.byType(Mascot), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
