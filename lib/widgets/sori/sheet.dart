import 'package:flutter/material.dart';

import 'tokens.dart';

/// **SoriSheet** — 모든 바텀시트의 단일 진입점.
///
/// 잘림(클리핑)을 구조적으로 차단한다:
/// 1. `useSafeArea: true` + 내부 `SafeArea(bottom)` — edge-to-edge 모드
///    (main.dart `SystemUiMode.edgeToEdge`)에서 시스템 상태바/네비바/컷아웃에
///    콘텐츠가 가려지지 않음.
/// 2. `maxHeight = 화면높이 × 0.88` 클램프 + 내용이 그보다 크면 자동 스크롤
///    — 어떤 기기/폰트 스케일에서도 "화면보다 큰 박스" 불가능.
/// 3. 시트 내부 텍스트 스케일 1.3 클램프 — 접근성 큰 글씨에서 버튼/제목이
///    시트 밖으로 터지지 않음 (본문 학습 콘텐츠가 아닌 UI 표면이므로 정당).
/// 4. 키보드(viewInsets) 시 내용이 키보드 위로 올라옴.
///
/// 기존의 `Container + 둥근 상단 + grab handle + Column(min)` 복붙 패턴을
/// 흡수한다. 사용:
/// ```dart
/// await showSoriSheet<void>(
///   context: context,
///   builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [...]),
/// );
/// ```
Future<T?> showSoriSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool showHandle = true,

  /// false = 내용이 자체 스크롤러(GridView/ListView/DraggableScrollable)를
  /// 가질 때. 이때도 maxHeight 클램프는 유지된다.
  bool scrollable = true,
  double maxHeightFactor = 0.88,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SoriSheetShell(
      showHandle: showHandle,
      scrollable: scrollable,
      maxHeightFactor: maxHeightFactor,
      child: Builder(builder: builder),
    ),
  );
}

/// 시트 외형 + 잘림 방어 셸. 직접 쓸 일은 드물고 [showSoriSheet]를 쓴다.
class SoriSheetShell extends StatelessWidget {
  final Widget child;
  final bool showHandle;
  final bool scrollable;
  final double maxHeightFactor;

  const SoriSheetShell({
    super.key,
    required this.child,
    this.showHandle = true,
    this.scrollable = true,
    this.maxHeightFactor = 0.88,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * maxHeightFactor;

    Widget body = child;
    if (scrollable) {
      body = SingleChildScrollView(child: body);
    }

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: s.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(SoriRadius.xl),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          Spacing.xl,
          Spacing.sm + 4,
          Spacing.xl,
          // 키보드가 올라오면 그 위로, 아니면 시스템 네비바 위로.
          Spacing.lg + media.viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showHandle)
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: Spacing.lg),
                  decoration: BoxDecoration(
                    color: s.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              Flexible(child: body),
            ],
          ),
        ),
      ),
    );
  }
}
