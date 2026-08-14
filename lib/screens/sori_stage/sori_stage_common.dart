import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/page_header.dart';

// §C-1-10: 정본은 widgets/sori/activity_illustration.dart 에 있다.
export '../../widgets/sori/activity_illustration.dart'
    show soriActivityColor, soriActivityIcon;

// §C-3c P0-1: 정본은 widgets/sori/localized_copy.dart.
export '../../widgets/sori/localized_copy.dart' show localCopy;

/// SoriStage 루트 탭 공용 헤더 — 2026-08-13 부터 [SoriPageHeader] 에 위임.
/// (eyebrow/hero 위계는 토큰화된 공용판이 소유하고, 여기는 프로필 진입
/// 아이콘과 대문자화 정책만 담당한다.)
class SoriStageRootHeader extends StatelessWidget {
  const SoriStageRootHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.body,
  });

  final String eyebrow;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriPageHeader(
      eyebrow: eyebrow.toUpperCase(),
      title: title,
      body: body,
      trailing: SizedBox.square(
        dimension: 48,
        child: IconButton(
          tooltip: t.soriStageProfileTooltip,
          onPressed: () => Navigator.of(context).pushNamed('/profile'),
          icon: const Icon(Icons.person_outline_rounded),
        ),
      ),
    );
  }
}
