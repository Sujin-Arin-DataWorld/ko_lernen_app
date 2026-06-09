import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import 'mascot.dart';
import 'tiger_stage.dart';
import 'tokens.dart';

/// 살아있는 호랑이 — **Rive 리깅 애니메이션** 래퍼 (부드러운 sit→인사→pacing).
///
/// `assets/rive/tiger.riv`가 있고 [riveReady](main에서 `RiveNative.init()` 성공)이면
/// Rive를 재생하고, 그 외 모든 경우(미초기화·파일 없음·로드 실패·reduce-motion)
/// 기존 프레임 기반 [TigerStage]로 **자동 폴백**한다.
///   → `.riv`를 `assets/rive/`에 넣기만 하면 코드 변경 0으로 매끄러운 버전 가동.
///
/// Rive 경로는 현재 보류(`tiger.riv` 미제작) — 프레임 `TigerStage`로 폴백.
/// 호랑이 애니메이션 전체 스펙은 `docs/TIGER_FULL_REMAKE_MASTER.md`(부록 Rive 참조).
class TigerStageRive extends StatefulWidget {
  final double height;
  final MascotEmotion fallbackEmotion;

  const TigerStageRive({
    super.key,
    this.height = 168,
    this.fallbackEmotion = MascotEmotion.smile,
  });

  /// main()에서 `RiveNative.init()` 성공 시 true로 설정. 테스트/미초기화/네이티브
  /// 미지원 환경에서는 false → 프레임 폴백(테스트가 Rive 네이티브에 의존 안 함).
  static bool riveReady = false;

  static const String asset = 'assets/rive/tiger.riv';

  @override
  State<TigerStageRive> createState() => _TigerStageRiveState();
}

class _TigerStageRiveState extends State<TigerStageRive> {
  FileLoader? _loader;

  @override
  void initState() {
    super.initState();
    if (TigerStageRive.riveReady) {
      _loader = FileLoader.fromAsset(
        TigerStageRive.asset,
        riveFactory: Factory.flutter, // Flutter(Skia) 렌더러 — 웹/모바일 호환
      );
    }
  }

  @override
  void dispose() {
    _loader?.dispose();
    super.dispose();
  }

  // 프레임 폴백(= 기존 TigerStage). reduce-motion·정지·누락 모두 TigerStage가 처리.
  Widget _frames() => TigerStage(
        height: widget.height,
        fallbackEmotion: widget.fallbackEmotion,
      );

  @override
  Widget build(BuildContext context) {
    final loader = _loader;
    if (loader == null || SoriMotion.reduceMotion(context)) {
      return _frames();
    }
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: RiveWidgetBuilder(
        fileLoader: loader,
        onFailed: (_, __) {}, // 조용히 폴백(.riv 미존재 등)
        builder: (context, state) => switch (state) {
          RiveLoaded() => RiveWidget(
              controller: state.controller,
              fit: Fit.contain,
            ),
          RiveLoading() => _frames(), // 로컬 에셋이라 순간 — 프레임으로 자연스레
          RiveFailed() => _frames(), // .riv 없음/로드 실패 → 프레임 폴백
        },
      ),
    );
  }
}
