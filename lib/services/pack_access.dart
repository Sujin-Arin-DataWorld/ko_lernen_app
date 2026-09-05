import 'package:flutter/widgets.dart';

/// 모든 레벨의 팩을 구독이나 결제 없이 연다.
/// 기존 호출부의 비동기 계약을 유지해 학습 내비게이션 변경을 최소화한다.
Future<bool> ensurePackAccess(BuildContext context, {required String level}) {
  return Future.value(true);
}
