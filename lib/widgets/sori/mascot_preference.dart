import 'package:flutter/foundation.dart';

import '../../services/storage_service.dart';
import 'mascot.dart';

/// **선택된 캐릭터 — 앱 전역 단일 진입점.**
///
/// 2026-07-31 이전에는 `Storage.preferredMascot`(문자열)을 읽는 곳이 앱 전체에
/// 3곳(profile / scenario_player / milestone_celebration)뿐이었고 **홈은 그중에
/// 없었다** → 까치를 골라도 홈·게임결과·레슨완료는 전부 호랑이가 나왔다.
/// 화면마다 문자열을 비교하는 대신 여기 하나만 보게 한다.
///
/// [kind]는 [ValueNotifier]다. static getter만 두면 설정에서 캐릭터를 바꿔도
/// 이미 빌드된 위젯이 리빌드되지 않아 앱을 껐다 켜야 반영된다 —
/// 위젯은 반드시 [ValueListenableBuilder]로 [kind]를 구독할 것.
class MascotPreference {
  MascotPreference._();

  /// 사용자가 선택할 수 있는 현재 캐릭터.
  static const List<MascotKind> selectableKinds = [
    MascotKind.tiger,
    MascotKind.magpie,
  ];

  /// 현재 캐릭터. 구독해서 쓴다.
  static final ValueNotifier<MascotKind> kind =
      ValueNotifier<MascotKind>(MascotKind.tiger);

  /// 저장 문자열 → enum. 미설정/알 수 없는 값은 호랑이(기존 기본값 유지).
  static MascotKind parse(String raw) =>
      raw == 'magpie' ? MascotKind.magpie : MascotKind.tiger;

  static String encode(MascotKind value) =>
      value == MascotKind.magpie ? 'magpie' : 'tiger';

  /// `main()` 부팅 시 1회 — `Storage.init()` **이후**에 호출할 것.
  static void load() => kind.value = parse(Storage.preferredMascot);

  /// 선택 저장 + 전역 통지. 캐릭터 선택 화면과 설정 화면이 둘 다 이걸 쓴다.
  static Future<void> set(MascotKind value) async {
    final canonical = parse(encode(value));
    kind.value = canonical;
    await Storage.setPreferredMascot(encode(canonical));
  }

  /// 리빌드가 필요 없는 곳(콜백 내부 1회 조회 등)에서만.
  /// 위젯 build 안에서는 쓰지 말 것 — 변경이 반영되지 않는다.
  static MascotKind get current => kind.value;

  /// 반대 캐릭터 — 설정 토글·미리보기용.
  static MascotKind other(MascotKind value) =>
      value == MascotKind.tiger ? MascotKind.magpie : MascotKind.tiger;
}
