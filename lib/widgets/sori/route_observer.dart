import 'package:flutter/widgets.dart';

/// 앱 전역 라우트 옵저버 — `MaterialApp.navigatorObservers` 에 등록한다.
///
/// 목적은 **하드웨어 비디오 디코더 회수(reclaim) 방지**다.
/// Jin 실기기(M2101K6G / SD678 / MIUI)는 동시 H.264 디코더 2개를 못 버틴다 —
/// 나중에 뜬 영상이 먼저 뜬 것의 디코더를 회수하고, 먼저 뜬 영상은 조용히
/// 검게 죽는다 (`logcat`: `keep callback message for reclaim`).
///
/// 홈의 [TigerStageVideo]는 `/path` 등을 push 해도 라우트 스택에 남아
/// 컨트롤러가 살아 있었다. [RouteAware]로 "내 화면 위에 다른 화면이 올라왔다"를
/// 감지해 그때 디코더를 놓고, 돌아오면 다시 잡는다.
final RouteObserver<ModalRoute<dynamic>> soriRouteObserver =
    RouteObserver<ModalRoute<dynamic>>();
