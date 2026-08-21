import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/book_page.dart';
import '../../services/analytics_service.dart';
import '../../services/custom_pack_service.dart';
import '../../services/storage_service.dart';
import 'spotlight_coach.dart';
import 'toast.dart';
import 'tokens.dart';

/// 전역 "단어장에 담기" 흐름. 단어를 빠른저장 팩에 넣는다.
///
/// **성공은 알리지 않는다.** 아이콘이 차오르는 것이 곧 확인이다 — 하트와
/// 같은 방식이다. 예전에는 성공마다 스낵바를 띄웠는데 그게 안 사라졌다:
/// `hideCurrentSnackBar()` 는 ~250ms 역방향 애니메이션을 시작할 뿐이고
/// 항목은 dismissed 에서야 큐에서 빠지므로, 곧이어 부른 `showSnackBar` 는
/// 교체가 아니라 **큐잉**이 된다. 연타하면 사슬처럼 쌓이고, 모달 시트가
/// 떠 있으면 자동 소멸 타이머가 아예 안 걸려 영영 남는다
/// (Jin 2026-08-19: "added ...to your word list가 안사라져").
///
/// 실패만 [soriToast] 로 한 번 말한다 — 조용히 삼키면 담긴 줄 알게 된다.
Future<WordbookAddResult> addToWordbook(
  BuildContext context, {
  required String korean,
  required String translationDe,
  String translationEn = '',
  String translationLanguage = 'de',
  String romanization = '',
  String posDe = '',
  String exampleKorean = '',
  String exampleDe = '',
  String definitionKo = '',
  String source = 'manual',
}) async {
  final t = AppL10n.of(context);

  final res = await CustomPackService.quickAdd(
    defaultPackName: t.wbQuickPackName,
    word: ExtractedWord.manual(
      korean: korean.trim(),
      translationDe: translationDe.trim(),
      translationEn: translationEn.trim(),
      translationLanguage: translationLanguage,
      romanization: romanization.trim(),
      posDe: posDe.trim(),
      exampleKorean: exampleKorean.trim(),
      exampleDe: exampleDe.trim(),
      definitionKo: definitionKo.trim(),
    ),
  );

  if (res == WordbookAddResult.added) {
    Analytics.wordbookAdded(source: source);
  }

  if (res == WordbookAddResult.failed && context.mounted) {
    soriToast(context, t.wbAddFailed);
  }
  return res;
}

/// Wiederverwendbarer "Zur Wortliste"-Button (Lesezeichen-Icon).
/// [compact] → reine Icon-Variante (AppBar/Kartenecke).
///
/// 첫 노출 시(세션 1회·`tutWordbookSeen` false) 자기 위치에 스포트라이트
/// 코치마크를 띄워 "북마크로 저장→복습→내 단어카드"를 안내한다. 6개 학습
/// 화면(review·chosung·wordle·vocab_pack·smalltalk·scenario_player) 무수정.
class AddToWordbookButton extends StatefulWidget {
  final String korean;
  final String translationDe;
  final String translationEn;
  final String translationLanguage;
  final String romanization;
  final String posDe;
  final String exampleKorean;
  final String exampleDe;
  final bool compact;
  final bool coachEnabled;

  const AddToWordbookButton({
    super.key,
    required this.korean,
    required this.translationDe,
    this.translationEn = '',
    this.translationLanguage = 'de',
    this.romanization = '',
    this.posDe = '',
    this.exampleKorean = '',
    this.exampleDe = '',
    this.compact = false,
    this.coachEnabled = true,
  });

  @override
  State<AddToWordbookButton> createState() => _AddToWordbookButtonState();
}

class _AddToWordbookButtonState extends State<AddToWordbookButton> {
  // 세션 내 1회만 — 한 화면에 버튼이 여럿이거나 화면을 옮겨도 첫 1개만 안내.
  static bool _coachShownThisSession = false;
  static int _tutorialResetRevision = Storage.tutorialResetRevision;
  final GlobalKey _coachKey = GlobalKey();

  void _syncTutorialReset() {
    final revision = Storage.tutorialResetRevision;
    if (_tutorialResetRevision != revision) {
      _tutorialResetRevision = revision;
      _coachShownThisSession = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _scheduleCoach();
  }

  @override
  void didUpdateWidget(covariant AddToWordbookButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((!oldWidget.coachEnabled && widget.coachEnabled) ||
        (oldWidget.korean.trim().isEmpty && widget.korean.trim().isNotEmpty)) {
      _scheduleCoach();
    }
  }

  void _scheduleCoach() {
    _syncTutorialReset();
    if (!widget.coachEnabled ||
        _coachShownThisSession ||
        Storage.tutWordbookSeen) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncTutorialReset();
      if (!mounted ||
          !widget.coachEnabled ||
          _coachShownThisSession ||
          Storage.tutWordbookSeen ||
          widget.korean.trim().isEmpty) {
        return;
      }
      _coachShownThisSession = true;
      final t = AppL10n.of(context);
      SpotlightCoach.show(
        context,
        steps: [
          SpotlightStep(
            targetKey: _coachKey,
            title: t.wbCoachTitle,
            body: t.wbCoachBody,
            icon: Icons.bookmark_add_outlined,
            cutoutPadding: const EdgeInsets.all(8),
            cutoutRadius: 22,
            shape: ShapeKind.circle,
          ),
        ],
        onComplete: () => Storage.setTutWordbookSeen(),
      );
    });
  }

  Future<void> _add(BuildContext context) => addToWordbook(
    context,
    korean: widget.korean,
    translationDe: widget.translationDe,
    translationEn: widget.translationEn,
    translationLanguage: widget.translationLanguage,
    romanization: widget.romanization,
    posDe: widget.posDe,
    exampleKorean: widget.exampleKorean,
    exampleDe: widget.exampleDe,
  );

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final enabled = widget.korean.trim().isNotEmpty;
    // 담긴 상태를 아이콘이 직접 말한다. 성공 알림을 없앤 자리를 이게 채운다.
    return ValueListenableBuilder<int>(
      valueListenable: CustomPackService.revision,
      builder: (context, _, __) {
        final saved = CustomPackService.containsKorean(widget.korean);
        final icon = saved
            ? Icons.bookmark_rounded
            : Icons.bookmark_add_outlined;
        final color = saved ? SoriColors.like : SoriColors.primary;
        if (widget.compact) {
          return IconButton(
            key: _coachKey,
            tooltip: t.wbAddTooltip,
            icon: Icon(icon),
            color: color,
            constraints: const BoxConstraints.tightFor(
              width: Spacing.xxxl,
              height: Spacing.xxxl,
            ),
            onPressed: enabled ? () => unawaited(_add(context)) : null,
          );
        }
        return TextButton.icon(
          key: _coachKey,
          onPressed: enabled ? () => unawaited(_add(context)) : null,
          icon: Icon(icon, size: 18),
          label: Text(t.wbAddTooltip),
          style: TextButton.styleFrom(foregroundColor: color),
        );
      },
    );
  }
}
