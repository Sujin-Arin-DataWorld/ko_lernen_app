import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/age_gate_service.dart';
import 'dialog.dart';
import 'privacy_choice_feedback.dart';
import 'button.dart';
import '../../services/storage_service.dart';

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
    if (!context.mounted || !AgeGateService.isGyeAllowed) {
      if (context.mounted && AgeGateService.isUnderMinAge) {
        await _showBlocked(context);
      }
      return false;
    }
    if (AgeGateService.isUnderMinAge) {
      if (context.mounted) {
        await _showBlocked(context);
      }
      return false;
    }
  }
  return context.mounted && AgeGateService.isGyeAllowed;
}

Future<void> _showBlocked(BuildContext context) async {
  final t = AppL10n.of(context);
  await showSoriDialog<void>(
    context: context,
    builder: (ctx) => SoriDialog(
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
  return showSoriDialog<int>(
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
  bool _saving = false;
  bool _saveFailed = false;
  int _epoch = PrivacyChoiceStorage.epoch;
  int _revision = 0;
  int? _requestedYear;

  @override
  void initState() {
    super.initState();
    PrivacyChoiceStorage.changes.addListener(_changed);
  }

  void _changed() {
    if (!mounted) {
      return;
    }
    if (_epoch != PrivacyChoiceStorage.epoch) {
      _epoch = PrivacyChoiceStorage.epoch;
      _revision++;
      _saving = false;
      _saveFailed = false;
      _requestedYear = null;
    } else if (_requestedYear != null && Storage.birthYear == _requestedYear) {
      // The editable draft does not own the submitted request's native outcome.
      _saveFailed = false;
    }
    setState(() {});
  }

  Future<void> _save() async {
    if (_saving || ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    final y = int.tryParse(_controller.text.trim());
    if (y == null || !AgeGateService.isPlausibleYear(y)) {
      setState(() => _error = AppL10n.of(context).gyeAgeYearHint);
      return;
    }
    final epoch = PrivacyChoiceStorage.epoch;
    _epoch = epoch;
    final revision = ++_revision;
    _requestedYear = y;
    setState(() {
      _saving = true;
      _saveFailed = false;
      _error = null;
    });
    final saved = await AgeGateService.saveBirthYear(y);
    if (!mounted ||
        epoch != PrivacyChoiceStorage.epoch ||
        revision != _revision ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    if (saved) {
      Navigator.of(context).pop(y);
    } else {
      setState(() {
        _saving = false;
        _saveFailed = Storage.birthYear != y;
      });
    }
  }

  @override
  void dispose() {
    PrivacyChoiceStorage.changes.removeListener(_changed);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriDialog(
      title: Text(t.gyeAgeYearTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.gyeAgeYearBody),
          const SizedBox(height: 12),
          if (_saving || _saveFailed)
            PrivacyChoiceFeedback(
              pending: _saving,
              withdrawal: false,
              onRetry: _save,
            ),
          TextField(
            enabled: !_saving,
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
        SoriButton.filled(
          label: t.btnConfirm,
          size: SoriButtonSize.md,
          onTap: _saving ? null : _save,
        ),
      ],
    );
  }
}
