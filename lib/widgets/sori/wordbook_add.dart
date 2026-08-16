import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/book_page.dart';
import '../../services/analytics_service.dart';
import '../../services/custom_pack_service.dart';
import '../../services/storage_service.dart';
import 'spotlight_coach.dart';
import 'tokens.dart';

/// Globaler "Zur Wortliste hinzufügen"-Flow (v2.0). Überall im Lern-Flow
/// nutzbar (Vokabel-Pack, Wiederholung, Anlaut-Quiz, Wordle, Small Talk,
/// Szenario): legt das Wort in den Schnellspeicher-Pack und zeigt eine
/// SnackBar (hinzugefügt / schon vorhanden) mit "Ansehen" → /bookshelf.
Future<void> addToWordbook(
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
  // Vor dem await einsammeln — kein BuildContext-Zugriff nach await.
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

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

  final msg = switch (res) {
    WordbookAddResult.added => t.wbAdded(korean),
    WordbookAddResult.alreadyExists => t.wbAlreadyAdded(korean),
    WordbookAddResult.failed => t.wbAddFailed,
  };
  messenger.showSnackBar(
    SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      action: res == WordbookAddResult.failed
          ? null
          : SnackBarAction(
              label: t.wbViewAction,
              onPressed: () => navigator.pushNamed('/bookshelf'),
            ),
    ),
  );
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

  void _add(BuildContext context) => addToWordbook(
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
    if (widget.compact) {
      return IconButton(
        key: _coachKey,
        tooltip: t.wbAddTooltip,
        icon: const Icon(Icons.bookmark_add_outlined),
        color: SoriColors.primary,
        onPressed: enabled ? () => _add(context) : null,
      );
    }
    return TextButton.icon(
      key: _coachKey,
      onPressed: enabled ? () => _add(context) : null,
      icon: const Icon(Icons.bookmark_add_outlined, size: 18),
      label: Text(t.wbAddTooltip),
      style: TextButton.styleFrom(foregroundColor: SoriColors.primary),
    );
  }
}
