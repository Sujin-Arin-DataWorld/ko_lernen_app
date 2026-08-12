import 'package:flutter/material.dart';

import '../../services/storage_service.dart';
import 'mascot.dart';

/// The learner's explicit companion decision.
///
/// An empty legacy preference still means Taego so existing installs keep
/// their established guide. Only the canonical `none` value represents a
/// deliberate, fully supported no-companion choice.
enum CompanionPreference { none, tiger, magpie }

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
  static final ValueNotifier<MascotKind> kind = ValueNotifier<MascotKind>(
    MascotKind.tiger,
  );

  /// Explicit companion state. Companion UI must subscribe to this notifier
  /// when it needs to disappear for [CompanionPreference.none].
  static final ValueNotifier<CompanionPreference> preference =
      ValueNotifier<CompanionPreference>(CompanionPreference.tiger);

  static CompanionPreference decode(String raw) => switch (raw) {
    'none' => CompanionPreference.none,
    'magpie' => CompanionPreference.magpie,
    _ => CompanionPreference.tiger,
  };

  static MascotKind? mascotKindFor(CompanionPreference value) =>
      switch (value) {
        CompanionPreference.none => null,
        CompanionPreference.tiger => MascotKind.tiger,
        CompanionPreference.magpie => MascotKind.magpie,
      };

  /// 저장 문자열 → enum. 미설정/알 수 없는 값은 호랑이(기존 기본값 유지).
  static MascotKind parse(String raw) =>
      raw == 'magpie' ? MascotKind.magpie : MascotKind.tiger;

  static String encode(MascotKind value) =>
      value == MascotKind.magpie ? 'magpie' : 'tiger';

  /// `main()` 부팅 시 1회 — `Storage.init()` **이후**에 호출할 것.
  static void load() {
    final stored = decode(Storage.preferredMascot);
    preference.value = stored;
    final selected = mascotKindFor(stored);
    if (selected != null) {
      kind.value = selected;
    }
  }

  /// 선택 저장 + 전역 통지. 캐릭터 선택 화면과 설정 화면이 둘 다 이걸 쓴다.
  static Future<void> set(MascotKind value) async {
    final canonical = parse(encode(value));
    kind.value = canonical;
    preference.value = canonical == MascotKind.magpie
        ? CompanionPreference.magpie
        : CompanionPreference.tiger;
    await Storage.setPreferredMascot(encode(canonical));
  }

  /// Persists an explicit no-companion choice without inventing a replacement
  /// mascot. Learning routes and progress remain unchanged.
  static Future<void> setNone() async {
    preference.value = CompanionPreference.none;
    await Storage.setPreferredMascot('none');
  }

  static MascotKind? get selectedKind => mascotKindFor(preference.value);

  static bool get hasCompanion => selectedKind != null;

  /// 리빌드가 필요 없는 곳(콜백 내부 1회 조회 등)에서만.
  /// 위젯 build 안에서는 쓰지 말 것 — 변경이 반영되지 않는다.
  static MascotKind get current => kind.value;

  /// 반대 캐릭터 — 설정 토글·미리보기용.
  static MascotKind other(MascotKind value) =>
      value == MascotKind.tiger ? MascotKind.magpie : MascotKind.tiger;
}

/// Reactive slot for UI that represents the learner's chosen companion.
///
/// Brand illustrations and game-authored characters should be rendered
/// directly instead. Personal companion surfaces use this widget so the
/// explicit [CompanionPreference.none] state never falls back to stale Tiger.
/// [previewPreference] is a storage-free seam for tests and the UX gallery.
class CompanionBuilder extends StatelessWidget {
  const CompanionBuilder({
    super.key,
    required this.builder,
    this.noneBuilder,
    this.previewPreference,
  });

  final Widget Function(BuildContext context, MascotKind kind) builder;
  final WidgetBuilder? noneBuilder;
  final CompanionPreference? previewPreference;

  Widget _buildPreference(
    BuildContext context,
    CompanionPreference preference,
  ) {
    final kind = MascotPreference.mascotKindFor(preference);
    if (kind == null) {
      return noneBuilder?.call(context) ?? const SizedBox.shrink();
    }
    return builder(context, kind);
  }

  @override
  Widget build(BuildContext context) {
    final preview = previewPreference;
    if (preview != null) {
      return _buildPreference(context, preview);
    }
    return ValueListenableBuilder<CompanionPreference>(
      valueListenable: MascotPreference.preference,
      builder: (context, preference, _) =>
          _buildPreference(context, preference),
    );
  }
}
