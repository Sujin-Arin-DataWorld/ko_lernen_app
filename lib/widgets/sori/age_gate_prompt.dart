import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/age_gate_service.dart';

/// Gye/Community 진입 전 **연령 게이트** (GDPR-K, 16세 — DSGVO Art. 8).
///
/// - 이미 16세 미만으로 확인 → 차단 다이얼로그 후 `false`.
/// - 생년 미상 → 생년 입력 다이얼로그(취소 시 `false` = 확인 불가).
///   입력 후 16세 미만이면 차단. 그 외 통과.
/// - 생년이 16세 이상으로 알려짐 → 즉시 `true`.
///
/// [GyeService]가 서비스 레이어에서도 동일하게 강제(backstop)하므로, 이 UI는
/// "회색/안내" 사용자 경험을 담당하고 우회는 서비스가 막는다.
Future<bool> ensureGyeAgeAllowed(BuildContext context) async {
  if (AgeGateService.isUnderMinAge) {
    await _showBlocked(context);
    return false;
  }
  if (AgeGateService.needsBirthYear) {
    final year = await _askBirthYear(context);
    if (year == null) {
      return false; // 취소 → 연령 미확인 → 진입 불가
    }
    await AgeGateService.saveBirthYear(year);
    if (AgeGateService.isUnderMinAge) {
      if (context.mounted) {
        await _showBlocked(context);
      }
      return false;
    }
  }
  return true;
}

Future<void> _showBlocked(BuildContext context) async {
  final t = AppL10n.of(context);
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.lock_outline_rounded),
      content: Text(t.gyeErrAgeRestricted),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(t.btnConfirm),
        ),
      ],
    ),
  );
}

Future<int?> _askBirthYear(BuildContext context) {
  // ⚠️ 컨트롤러를 이 함수에서 만들고 `await showDialog` 직후 dispose하면 안 된다:
  // pop 후에도 다이얼로그 퇴장 애니메이션 동안 TextField가 리빌드되며
  // "used after being disposed" → framework `_dependents.isEmpty` 레드스크린
  // (Jin 실기기 gye 크래시의 근본 원인, 2026-06-12 웹 재현으로 확정).
  // → State가 컨트롤러를 소유해 route 트리 파괴 후 dispose되게 한다.
  return showDialog<int>(
    context: context,
    builder: (_) => const _BirthYearDialog(),
  );
}

class _BirthYearDialog extends StatefulWidget {
  const _BirthYearDialog();

  @override
  State<_BirthYearDialog> createState() => _BirthYearDialogState();
}

class _BirthYearDialogState extends State<_BirthYearDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return AlertDialog(
      title: Text(t.gyeAgeYearTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.gyeAgeYearBody),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            maxLength: 4,
            autofocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: t.gyeAgeYearHint,
              counterText: '',
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.btnCancel),
        ),
        TextButton(
          onPressed: () {
            final y = int.tryParse(_controller.text.trim());
            if (y == null || !AgeGateService.isPlausibleYear(y)) {
              setState(() => _error = t.gyeAgeYearHint);
              return;
            }
            Navigator.of(context).pop(y);
          },
          child: Text(t.btnConfirm),
        ),
      ],
    );
  }
}
