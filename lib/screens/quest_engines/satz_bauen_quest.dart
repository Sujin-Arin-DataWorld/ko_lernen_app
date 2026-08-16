import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/sound_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/sori/mascot.dart';
import '../../widgets/sori/mascot_pop.dart';
import '../../widgets/sori/pressable.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/tts_speed_control.dart';
import 'quest_flow.dart';
import 'quest_models.dart';

/// Art des Fehlers beim Zusammensetzen — steuert das gezielte Feedback.
enum SatzError { none, order, particle, tooMany, tooFew, word }

/// Satz-bauen-Quest (문장 짓기): aus durcheinandergewürfelten Wort-Kacheln
/// den koreanischen Satz **selbst zusammensetzen** — produktives Üben statt
/// Erkennen. Die Zielsätze stammen aus den echten `speaker:"user"`-Zeilen der
/// Szenarien (KO/DE/EN bereits muttersprachlich vorhanden).
///
/// data-Schema:
/// ```json
/// {
///   "targetKo": "아이스 아메리카노 톨 사이즈로 주세요.",
///   "promptDe": "Einen Iced Americano in Tall, bitte.",
///   "promptEn": "One iced Americano, tall, please.",
///   "distractors": ["주문", "포장", "아메리카노"],
///   "audioKo": "아이스 아메리카노 톨 사이즈로 주세요."   // optional
/// }
/// ```
class SatzBauenQuest extends StatefulWidget {
  final Map<String, dynamic> data;
  final void Function(QuestResult) onComplete;
  final VoidCallback? onContinue;
  final bool isLast;
  final bool showMascot;
  final bool compact;
  final bool showSpeedControl;
  final bool allowDontKnow;

  const SatzBauenQuest({
    super.key,
    required this.data,
    required this.onComplete,
    this.onContinue,
    this.isLast = false,
    this.showMascot = true,
    this.compact = false,
    this.showSpeedControl = true,
    this.allowDontKnow = false,
  });

  @override
  State<SatzBauenQuest> createState() => _SatzBauenQuestState();

  // ── Reine Logik (testbar, keine UI) ──────────────────────────────────

  /// Entfernt führende/abschließende Satzzeichen und trimmt einen Token.
  static String normalizeToken(String t) {
    return t.replaceAll(RegExp(r'^[\s.,!?…·"”’]+|[\s.,!?…·"”’]+$'), '').trim();
  }

  /// Zerlegt einen koreanischen Satz in vergleichbare Wort-Tokens (어절).
  static List<String> tokenize(String sentence) {
    return sentence
        .trim()
        .split(RegExp(r'\s+'))
        .map(normalizeToken)
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// Returns the terminal question/exclamation mark taught as its own tile.
  static String? terminalPunctuation(String sentence) {
    return RegExp(r'([?!])\s*$').firstMatch(sentence.trim())?.group(1);
  }

  /// The punctuation tile is required exactly once and only at the end.
  static bool hasCorrectTerminalPunctuation(
    List<String> assembled,
    String targetKo,
  ) {
    final expected = terminalPunctuation(targetKo);
    final punctuationCount = assembled
        .where((token) => token == '?' || token == '!')
        .length;
    if (expected == null) {
      return punctuationCount == 0;
    }
    return punctuationCount == 1 &&
        assembled.isNotEmpty &&
        assembled.last == expected;
  }

  /// True, wenn die zusammengesetzten Tokens (in Reihenfolge) dem Ziel
  /// entsprechen. Satzzeichen/Leerraum werden ignoriert.
  static bool isCorrectOrder(List<String> assembled, String targetKo) {
    final target = tokenize(targetKo);
    final got = assembled
        .map(normalizeToken)
        .where((t) => t.isNotEmpty)
        .toList();
    if (got.length != target.length) {
      return false;
    }
    for (var i = 0; i < target.length; i++) {
      if (got[i] != target[i]) {
        return false;
      }
    }
    return true;
  }

  /// Index der ersten falschen/fehlenden Position (für Fehler-Hinweis),
  /// oder -1 wenn alles korrekt.
  static int firstMismatch(List<String> assembled, String targetKo) {
    final target = tokenize(targetKo);
    final got = assembled.map(normalizeToken).toList();
    for (var i = 0; i < target.length; i++) {
      if (i >= got.length || got[i] != target[i]) {
        return i;
      }
    }
    return got.length > target.length ? target.length : -1;
  }

  /// Bekannte Partikel (조사) — längste zuerst, für die Stamm-Extraktion.
  static const List<String> josaSuffixes = [
    '에서',
    '까지',
    '부터',
    '으로',
    '이랑',
    '한테',
    '에게',
    '처럼',
    '보다',
    '마다',
    '밖에',
    '조차',
    '마저',
    '이나',
    '이요',
    '은',
    '는',
    '이',
    '가',
    '을',
    '를',
    '에',
    '도',
    '만',
    '의',
    '랑',
    '과',
    '와',
    '로',
    '나',
    '요',
  ];

  /// Entfernt eine abschließende Partikel (조사) → Wortstamm.
  static String stripJosa(String token) {
    for (final p in josaSuffixes) {
      if (token.length > p.length && token.endsWith(p)) {
        return token.substring(0, token.length - p.length);
      }
    }
    return token;
  }

  /// Diagnostiziert die ART des Fehlers für gezieltes Feedback.
  /// Korrekte Eingaben liefern immer [SatzError.none] (keine Falsch-Diagnose).
  static SatzError diagnose(List<String> assembled, String targetKo) {
    if (isCorrectOrder(assembled, targetKo)) {
      return SatzError.none;
    }
    final target = tokenize(targetKo);
    final got = assembled
        .map(normalizeToken)
        .where((t) => t.isNotEmpty)
        .toList();
    if (got.length > target.length) {
      return SatzError.tooMany;
    }
    if (got.length < target.length) {
      return SatzError.tooFew;
    }
    // Gleiche Länge: Reihenfolge, Partikel oder falsches Wort?
    final sortedGot = [...got]..sort();
    final sortedTarget = [...target]..sort();
    var sameMultiset = true;
    for (var i = 0; i < sortedGot.length; i++) {
      if (sortedGot[i] != sortedTarget[i]) {
        sameMultiset = false;
        break;
      }
    }
    if (sameMultiset) {
      return SatzError.order;
    }
    final diffs = <int>[];
    for (var i = 0; i < target.length; i++) {
      if (got[i] != target[i]) {
        diffs.add(i);
      }
    }
    if (diffs.length == 1) {
      final stemGot = stripJosa(got[diffs.first]);
      final stemTarget = stripJosa(target[diffs.first]);
      if (stemGot.isNotEmpty && stemGot == stemTarget) {
        return SatzError.particle;
      }
    }
    return SatzError.word;
  }
}

/// Eine Kachel mit stabiler Identität (erlaubt doppelte Wörter).
class _Tile {
  final int id;
  final String text;
  const _Tile(this.id, this.text);
}

class _SatzBauenQuestState extends State<SatzBauenQuest> {
  final List<_Tile> _bank = [];
  final List<_Tile> _answer = [];

  int _tries = 0;
  String? _punct;
  bool _completed = false;
  bool _celebrated = false;
  bool _wrong = false; // letzte Prüfung war falsch → Hinweis anzeigen
  int _mismatchIdx = -1;
  SatzError _diag = SatzError.none;

  String get _targetKo => (widget.data['targetKo'] as String?) ?? '';
  String get _promptDe => (widget.data['promptDe'] as String?) ?? '';
  String get _promptEn => (widget.data['promptEn'] as String?) ?? '';
  String get _audioKo => (widget.data['audioKo'] as String?) ?? '';

  @override
  void initState() {
    super.initState();
    final tokens = SatzBauenQuest.tokenize(_targetKo);
    final distractors = ((widget.data['distractors'] as List?) ?? const [])
        .map((e) => SatzBauenQuest.normalizeToken(e.toString()))
        .where((t) => t.isNotEmpty)
        .toList();

    _punct = SatzBauenQuest.terminalPunctuation(_targetKo);
    final all = <String>[
      ...tokens,
      ...distractors,
      if (_punct != null) _punct!,
    ];
    // Deterministisch mischen (stabil pro Quest, variiert je Satz).
    final rng = math.Random(_targetKo.hashCode);
    for (var i = all.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = all[i];
      all[i] = all[j];
      all[j] = tmp;
    }
    for (var i = 0; i < all.length; i++) {
      _bank.add(_Tile(i, all[i]));
    }

    // 듣고 푸는 문항인데 스피커를 매번 눌러야 해서 불편하다는 피드백(Jin,
    // 2026-08-12 실기기). 첫 프레임 뒤에 한 번 자동 재생하고, 다시 듣기 버튼은
    // 그대로 둔다 — 자동 재생은 놓치기 쉬우므로 대체가 아니라 추가다.
    //
    // initState 로 충분한 이유: 호스트가 문항마다 State 를 새로 만든다
    // (satz_arcade_screen.dart:260 `ValueKey('satz_${_roundId}_$_idx')`).
    // 여기에 걸면 문항 전환도 함께 커버되므로 didUpdateWidget 은 필요 없다.
    //
    // _playTts 가 아니라 speak 를 직접 부르는 것도 의도다 — 사용자가 누르지
    // 않았는데 햅틱이 울리면 오작동처럼 느껴진다.
    if (_audioKo.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          TtsService.speak(_audioKo);
        }
      });
    }
  }

  String _prompt(String langCode) {
    if (langCode == 'en' && _promptEn.isNotEmpty) {
      return _promptEn;
    }
    return _promptDe.isNotEmpty ? _promptDe : _promptEn;
  }

  String _diagText(AppL10n t) {
    switch (_diag) {
      case SatzError.order:
        return t.questDiagOrder;
      case SatzError.particle:
        return t.questDiagParticle;
      case SatzError.tooMany:
      case SatzError.tooFew:
        return t.questDiagCount;
      case SatzError.word:
      case SatzError.none:
        return t.questDiagWord;
    }
  }

  Future<void> _playTts() async {
    await TtsService.speak(_audioKo);
  }

  void _placeTile(_Tile t) {
    if (_completed) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _bank.remove(t);
      _answer.add(t);
      _wrong = false;
      _mismatchIdx = -1;
      _diag = SatzError.none;
    });
  }

  void _removeTile(_Tile t) {
    if (_completed) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _answer.remove(t);
      _bank.add(t);
      _wrong = false;
      _mismatchIdx = -1;
      _diag = SatzError.none;
    });
  }

  Future<void> _check() async {
    if (_completed || _answer.isEmpty) {
      return;
    }
    final assembled = _answer.map((t) => t.text).toList();
    final punctuationOk = SatzBauenQuest.hasCorrectTerminalPunctuation(
      assembled,
      _targetKo,
    );

    if (punctuationOk && SatzBauenQuest.isCorrectOrder(assembled, _targetKo)) {
      HapticFeedback.lightImpact();
      setState(() {
        _completed = true;
        _celebrated = true;
        _wrong = false;
        _mismatchIdx = -1;
      });
      widget.onComplete(QuestResult(passed: true, firstTry: _tries == 0));
      return;
    }

    // Falsch.
    HapticFeedback.mediumImpact();
    SoundService.wrong();
    _tries++;
    final punctuationIndex = assembled.indexWhere(
      (token) => token == '?' || token == '!',
    );
    final mismatch = punctuationOk
        ? SatzBauenQuest.firstMismatch(assembled, _targetKo)
        : (punctuationIndex >= 0 ? punctuationIndex : assembled.length);
    final diag = punctuationOk
        ? SatzBauenQuest.diagnose(assembled, _targetKo)
        : SatzError.order;

    if (_tries >= 2) {
      // Richtige Lösung aufzeigen.
      final target = SatzBauenQuest.tokenize(_targetKo);
      setState(() {
        _answer
          ..clear()
          ..addAll([
            for (var i = 0; i < target.length; i++) _Tile(-1 - i, target[i]),
            if (_punct != null) _Tile(-1000, _punct!),
          ]);
        _bank.clear();
        _completed = true;
        _wrong = true;
        _mismatchIdx = -1;
      });
      widget.onComplete(const QuestResult(passed: false, firstTry: false));
    } else {
      setState(() {
        _wrong = true;
        _mismatchIdx = mismatch;
        _diag = diag;
      });
    }
  }

  void _revealAnswer() {
    if (_completed) return;
    HapticFeedback.selectionClick();
    final target = SatzBauenQuest.tokenize(_targetKo);
    setState(() {
      _answer
        ..clear()
        ..addAll([
          for (var i = 0; i < target.length; i++) _Tile(-1 - i, target[i]),
          if (_punct != null) _Tile(-1000, _punct!),
        ]);
      _bank.clear();
      _completed = true;
      _wrong = true;
      _mismatchIdx = -1;
      _diag = SatzError.none;
    });
    widget.onComplete(const QuestResult(passed: false, firstTry: false));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final s = SoriSurfaces.of(context);

    final revealedOk = _completed && !_wrong;

    // 유한 높이에서는 문제 내용만 내부 스크롤하고 CTA는 엄지 영역에 고정한다.
    // 무한 높이 부모에서는 flex를 쓰지 않고 자연 높이로 흘려 기존 임베드 호출도
    // 안전하게 유지한다. 역할극은 마스코트를 끄고 compact 모드를 사용한다.
    final promptStyle = SoriTextTheme.of(context).body.copyWith(
      fontSize: widget.compact ? 16 : 18,
      fontWeight: FontWeight.w600,
      height: 1.35,
    );
    final sectionGap = widget.compact ? Spacing.sm : Spacing.md;

    final exerciseBody = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Prompt and audio tools form one compact, readable block. The
        // speed chip is intentionally inline: learners should never have
        // to leave the exercise for Settings just to slow the sentence.
        Semantics(
          button: _audioKo.isNotEmpty,
          label: _audioKo.isNotEmpty ? t.vocabPackBossReplayAudio : null,
          child: SoriPressable(
            onTap: _audioKo.isEmpty ? null : _playTts,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(widget.compact ? 14 : 18),
              decoration: BoxDecoration(
                color: s.surface,
                borderRadius: BorderRadius.circular(SoriRadius.lg),
                border: Border.all(
                  color: _audioKo.isEmpty
                      ? s.border
                      : SoriColors.primary.withValues(alpha: 0.55),
                  width: _audioKo.isEmpty ? 1 : 1.5,
                ),
                boxShadow: _audioKo.isEmpty
                    ? null
                    : [
                        BoxShadow(
                          color: SoriColors.primary.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_prompt(langCode), style: promptStyle),
                  if (_audioKo.isNotEmpty) ...[
                    const SizedBox(height: Spacing.sm),
                    Row(
                      children: [
                        const Icon(
                          Icons.volume_up_rounded,
                          color: SoriColors.primary,
                          size: 19,
                        ),
                        const SizedBox(width: Spacing.xs),
                        Expanded(
                          child: Text(
                            t.vocabPackBossReplayAudio,
                            style: SoriTextTheme.of(context).caption.copyWith(
                              color: SoriColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.touch_app_rounded,
                          color: SoriColors.primary,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (_audioKo.isNotEmpty && widget.showSpeedControl) ...[
          const SizedBox(height: Spacing.xs),
          const Align(
            alignment: Alignment.centerRight,
            child: TtsSpeedControl(),
          ),
        ],
        SizedBox(height: sectionGap),
        Text(
          t.questSatzBauenInstruction,
          style: TextStyle(color: s.textMuted, fontSize: 14),
        ),
        SizedBox(height: sectionGap),

        // Antwort-Bereich (gebaute Reihenfolge).
        SoriAnswerTray(
          minHeight: widget.compact ? 72 : 96,
          accent: revealedOk
              ? SoriColors.success
              : (_wrong ? SoriColors.danger : SoriColors.primary),
          child: _answer.isEmpty
              ? Center(
                  child: Text(
                    '…',
                    style: TextStyle(color: s.textDim, fontSize: 22),
                  ),
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < _answer.length; i++)
                      _buildTile(
                        _answer[i],
                        s,
                        inAnswer: true,
                        highlightWrong: _wrong && i == _mismatchIdx,
                        highlightOk: revealedOk,
                      ),
                  ],
                ),
        ),
        // Diagnose-Feedback (warum falsch).
        SizedBox(
          height: widget.compact ? 20 : 24,
          child: (_wrong && !_completed && _diag != SatzError.none)
              ? Text(
                  _diagText(t),
                  style: const TextStyle(
                    color: SoriColors.danger,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        SizedBox(height: sectionGap),

        // Wort-Bank.
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            for (final tile in _bank) _buildTile(tile, s, inAnswer: false),
          ],
        ),
      ],
    );
    final action = ScenarioQuestAction(
      canSubmit: _answer.isNotEmpty,
      onSubmit: _check,
      resolved: _completed ? !_wrong : null,
      onContinue: widget.onContinue,
      isLast: widget.isLast,
      pendingHint: _tries == 1 ? _diagText(t) : null,
      onDontKnow: widget.allowDontKnow ? _revealAnswer : null,
    );

    // Keep the primary action anchored while the content above it scrolls only
    // when it genuinely exceeds the available height. On normal phones the
    // compact roleplay body fits without scrolling; long B2 turns and 200%
    // text no longer push the button off-screen or overflow the viewport.
    Widget content({required bool pinBottom}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pinBottom)
          Expanded(child: SingleChildScrollView(child: exerciseBody))
        else
          exerciseBody,
        SizedBox(height: sectionGap),
        action,
      ],
    );

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        LayoutBuilder(
          builder: (_, c) => content(pinBottom: c.maxHeight.isFinite),
        ),
        // Keep the deliberate overhang outside the short-height scroll view;
        // otherwise SingleChildScrollView clips the mascot above the card.
        if (widget.showMascot)
          Positioned(
            top: -78,
            right: 12,
            child: MascotPartner(
              celebrating: _celebrated,
              size: 96,
              kind: MascotKind.magpie,
              // 기존 viewport-fit 결과를 화면 정중앙에서 정확히 6배 확대.
              burstScale: 6,
              burstOrigin: Alignment.center,
            ),
          ),
      ],
    );
  }

  Widget _buildTile(
    _Tile tile,
    SoriSurfaces _, {
    required bool inAnswer,
    bool highlightWrong = false,
    bool highlightOk = false,
  }) {
    // 태블릿에서 단어 타일이 폰과 똑같이 18pt/18×13 고정이라 "게임창이 너무
    // 작다"가 됐다. 학습 화면 전용 확대 램프를 그대로 쓴다(폰 ≤600dp = 1.0).
    final scale = soriStudyScale(MediaQuery.sizeOf(context).width);

    return SoriWordTile(
      label: tile.text,
      scale: scale,
      compact: widget.compact,
      state: highlightWrong
          ? SoriWordTileState.wrong
          : highlightOk
          ? SoriWordTileState.correct
          : inAnswer
          ? SoriWordTileState.selected
          : SoriWordTileState.idle,
      onTap: () {
        if (inAnswer) {
          _removeTile(tile);
        } else {
          _placeTile(tile);
        }
      },
    );
  }
}
