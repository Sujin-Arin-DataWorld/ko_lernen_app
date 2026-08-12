import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/sound_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/sori/mascot.dart';
import '../../widgets/sori/mascot_pop.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/tokens.dart';
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

  const SatzBauenQuest({
    super.key,
    required this.data,
    required this.onComplete,
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
    HapticFeedback.selectionClick();
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
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        widget.onComplete(QuestResult(passed: true, firstTry: _tries == 0));
      }
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
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      if (mounted) {
        widget.onComplete(QuestResult(passed: false, firstTry: false));
      }
    } else {
      setState(() {
        _wrong = true;
        _mismatchIdx = mismatch;
        _diag = diag;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final s = SoriSurfaces.of(context);

    final revealedOk = _completed && !_wrong;

    // 2026-08-06: 마스코트를 다시 Stack(Clip.none) 오버레이로 뺐다.
    // 3ee6ec1 이 마스코트를 flow 로 옮기면서 MascotPartner(92px) + Spacing.lg(16)
    // = 108px 가 세로 예산에 얹혔고, 이 퀘스트는 스크롤 없는 Expanded 안에 살아서
    // 800x600 기준 411px 자리에 533.5px 가 들어가 122.5px 오버플로가 났다. 그
    // 결과 단어 타일이 hit-test 밖으로 밀려 탭이 배경으로 새고, Prüfen 버튼은
    // 뷰포트 밖(y=676)으로 나갔다. 오버레이는 세로 예산을 0 으로 되돌린다.
    // 스피커 버튼은 아래에서 leading 슬롯으로 옮겨 3ee6ec1 이 고쳤던 겹침이
    // 재발하지 않게 했다(마스코트는 카드 우상단을 쓴다).
    // 2026-08-12: 가운데 정렬을 폐기 — Prüfen 이 화면 중간에 떠서 "배치가
    // 엉성하다"(Jin 실기기). 정보(카드·타일)는 위, 버튼은 Spacer 로 하단
    // 고정(엄지 존). Spacer 는 min 0 이라 낮은 뷰포트(800×600)에서도
    // 3ee6ec1 오버플로 회귀가 없다.
    // Tablet-width scaling can make the fixed prompt/answer/button chrome a
    // few pixels taller than a short landscape viewport, especially during
    // the 300 ms completed-state handoff. Keep the established layout above
    // this threshold and make only the genuinely short case scrollable.
    final content = Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prompt (Bedeutung) + optionaler TTS-Button. The magpie is
            // anchored to this card without consuming vertical layout space.
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  // 24/64/24: 질문카드를 키워 화면을 채운다(2026-08-12 Jin 3차).
                  padding: const EdgeInsets.fromLTRB(24, 26, 64, 26),
                  decoration: BoxDecoration(
                    color: s.surface,
                    borderRadius: BorderRadius.circular(SoriRadius.lg),
                    border: Border.all(color: s.surfaceAlt, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      // 스피커는 leading 슬롯 — trailing 에 두면 우상단 마스코트
                      // 오버레이와 겹친다(3ee6ec1 이 고쳤던 그 문제).
                      if (_audioKo.isNotEmpty) ...[
                        InkWell(
                          borderRadius: BorderRadius.circular(SoriRadius.pill),
                          onTap: _playTts,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: SoriColors.info.withAlpha(26),
                              border: Border.all(
                                color: SoriColors.info,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.volume_up_rounded,
                              color: SoriColors.info,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                      ],
                      Expanded(
                        child: Text(
                          _prompt(langCode),
                          style: TextStyle(
                            color: s.text,
                            fontSize: 22,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 96px + top -78: 새가 카드 윗모서리에 앉되(발끝 ~18px 걸침)
                // 존재감 있게. 72px 는 "너무 조그맣다"(2026-08-12 Jin 실기기).
                // 카드 위쪽은 빈 배경이라 돌출(78px)이 다른 콘텐츠를 가리지
                // 않고, 오버레이(Clip.none)라 세로 예산도 그대로 0.
                // 마스코트는 여기가 아니라 바깥 Stack 에 있다 — f1320ff 가
                // SoriMinHeightScroll 을 도입하면서, 짧은 뷰포트에서 스크롤뷰가
                // 카드 위 돌출(top:-78)을 잘라먹던 문제를 그렇게 해소했다.
                // 버스트 6배 확대는 그 바깥 인스턴스로 이식했다.
              ],
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              t.questSatzBauenInstruction,
              style: TextStyle(color: s.textMuted, fontSize: 14),
            ),
            const SizedBox(height: Spacing.md),

            // Antwort-Bereich (gebaute Reihenfolge).
            Container(
              constraints: const BoxConstraints(minHeight: 96),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: s.surface,
                borderRadius: BorderRadius.circular(SoriRadius.lg),
                border: Border(
                  bottom: BorderSide(
                    color: revealedOk
                        ? SoriColors.success
                        : (_wrong ? SoriColors.danger : SoriColors.primary),
                    width: 2.5,
                  ),
                ),
              ),
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
              height: 24,
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
            const SizedBox(height: Spacing.lg),

            // Wort-Bank.
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                for (final tile in _bank) _buildTile(tile, s, inAnswer: false),
              ],
            ),
            // 남는 세로 공간은 전부 여기로 흡수 — 버튼이 항상 하단에 붙는다.
            const Spacer(),
            const SizedBox(height: Spacing.md),

            // Prüfen-Button.
            Opacity(
              opacity: (_answer.isEmpty || _completed) ? 0.5 : 1.0,
              child: Material(
                color: SoriColors.primary,
                borderRadius: BorderRadius.circular(SoriRadius.lg),
                child: InkWell(
                  borderRadius: BorderRadius.circular(SoriRadius.lg),
                  onTap: (_answer.isEmpty || _completed) ? null : _check,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Center(
                      child: Text(
                        t.questCheckAnswer,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        SoriMinHeightScroll(minHeight: 464, child: content),
        // Keep the deliberate overhang outside the short-height scroll view;
        // otherwise SingleChildScrollView clips the mascot above the card.
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
    SoriSurfaces s, {
    required bool inAnswer,
    bool highlightWrong = false,
    bool highlightOk = false,
  }) {
    Color border = s.surfaceAlt;
    Color bg = inAnswer ? SoriColors.primary.withAlpha(20) : s.surface;
    if (highlightWrong) {
      border = SoriColors.danger;
      bg = SoriColors.danger.withAlpha(38);
    } else if (highlightOk) {
      border = SoriColors.success;
      bg = SoriColors.success.withAlpha(38);
    } else if (inAnswer) {
      border = SoriColors.primary;
    }

    // 태블릿에서 단어 타일이 폰과 똑같이 18pt/18×13 고정이라 "게임창이 너무
    // 작다"가 됐다. 학습 화면 전용 확대 램프를 그대로 쓴다(폰 ≤600dp = 1.0).
    final scale = soriStudyScale(MediaQuery.sizeOf(context).width);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(SoriRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(SoriRadius.sm),
        onTap: () {
          if (inAnswer) {
            _removeTile(tile);
          } else {
            _placeTile(tile);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SoriRadius.sm),
            border: Border.all(color: border, width: 1.5),
          ),
          // 타일 확대(18/13→22/16, 폰트 18→20): "조립판 타일도 크게 화면
          // 가득" (2026-08-12 Jin 3차). 히트영역도 44dp 이상으로 커진다.
          padding: EdgeInsets.symmetric(
            horizontal: 22 * scale,
            vertical: 16 * scale,
          ),
          child: Text(
            tile.text,
            style: TextStyle(
              color: s.text,
              fontSize: 20 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
