import 'package:flutter/widgets.dart';

import '../../services/diagnostics_service.dart';

/// 라우트 이동을 Crashlytics breadcrumb 과 `currentRoute` 키로 남긴다.
///
/// stack trace 만으로는 "어느 화면에서 죽었는지"를 알 수 없다. 이 옵저버가
/// 그 한 줄을 채운다.
///
/// ⛔ **라우트 인자(arguments)는 절대 남기지 않는다** — 팩 id 정도면 무해하지만
/// 책 한 컷의 OCR 텍스트나 사용자 입력이 인자로 지나갈 수 있다. 이름만 남긴다.
/// 이름이 없는 익명 라우트는 `<unnamed>` 로 접는다.
class DiagnosticsRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _record('push', route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _record('pop', previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _record('replace', newRoute);
  }

  void _record(String action, Route<dynamic>? route) {
    final name = _nameOf(route);
    // ignore: discarded_futures, unawaited_futures
    DiagnosticsService.logBreadcrumb('route_$action $name');
    // ignore: discarded_futures, unawaited_futures
    DiagnosticsService.setKey(DiagnosticKey.currentRoute, name);
  }

  static String _nameOf(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null || name.isEmpty) {
      return '<unnamed>';
    }
    return name;
  }
}
