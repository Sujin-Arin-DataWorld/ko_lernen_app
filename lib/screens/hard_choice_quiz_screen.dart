import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/vocab.dart';
import '../services/data_loader.dart';
import '../services/hangul_perturbation.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/quiz_choice.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/tokens.dart';

/// **어려운 철자 퀴즈** — Extra-Lernset(어려운 단어)의 2단계 연습
/// (2026-08-13 테스터 피드백 ③+④).
///
/// 프롬프트 = 뜻(표시 언어), 보기 = 정답 한국어 + 자모 하나만 다른 비단어 3개
/// (하다 → 할다/허다/하가). 같은 뜻인데 철자가 비슷한 보기라 품사 소거법이
/// 통하지 않는다.
///
/// 팩 Quiz/Boss 와 달리 클리어 게이트·코스 증거(`CourseActivityReporter`)에
/// 연결되지 않는 **자유 연습** — 오답은 SRS·오답 카운터에만 반영된다.
class HardChoiceQuizScreen extends StatefulWidget {
  final List<Vocab> deck;
  final String? title;

  /// 테스트용 — 실단어 blocklist 로더 주입 (기본: CSV 전체).
  final Future<List<Vocab>> Function()? vocabLoader;

  const HardChoiceQuizScreen({
    super.key,
    required this.deck,
    this.title,
    this.vocabLoader,
  });

  @override
  State<HardChoiceQuizScreen> createState() => _HardChoiceQuizScreenState();
}

class _HardChoiceQuizScreenState extends State<HardChoiceQuizScreen> {
  final math.Random _rng = math.Random();
  List<Vocab> _round = const [];
  Set<String> _blocklist = const {};
  bool _loading = true;
  int _idx = 0;
  int _score = 0;
  List<String>? _options;
  int _selected = -1;
  bool _locked = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    // ignore: discarded_futures
    _load();
  }

  Future<void> _load() async {
    // 실단어 blocklist — 변이가 우연히 실제 단어(동의어 가능성)를 만들지 않게.
    var blocklist = <String>{for (final v in widget.deck) v.korean};
    try {
      final all = await (widget.vocabLoader ?? DataLoader.loadVocab)();
      blocklist = {...blocklist, for (final v in all) v.korean};
    } catch (_) {
      /* best-effort — 덱 표제어만으로도 동작 */
    }
    if (!mounted) return;
    final round =
        widget.deck
            .where(
              (v) => v.german.trim().isNotEmpty || v.english.trim().isNotEmpty,
            )
            .toList()
          ..shuffle(_rng);
    setState(() {
      _blocklist = blocklist;
      _round = round;
      _loading = false;
    });
    _prepare();
  }

  Vocab? get _current =>
      (_idx >= 0 && _idx < _round.length) ? _round[_idx] : null;

  void _prepare() {
    final cur = _current;
    if (cur == null) {
      setState(() => _done = true);
      return;
    }
    final distractors = nearMissDistractors(
      cur.korean,
      rng: _rng,
      blocklist: _blocklist,
    );
    if (distractors.isEmpty) {
      // 비한글 표제어 등 교란 불가 단어 — 이 라운드에서 건너뛴다.
      setState(() {
        _round = List<Vocab>.of(_round)..removeAt(_idx);
      });
      _prepare();
      return;
    }
    // 교란이 3개 미만이면(외자 단어 등) 덱의 다른 한국어로 패딩.
    if (distractors.length < 3) {
      final pad =
          _round.map((v) => v.korean).where((k) => k != cur.korean).toList()
            ..shuffle(_rng);
      for (final k in pad) {
        if (distractors.length >= 3) break;
        if (!distractors.contains(k)) distractors.add(k);
      }
    }
    final options = <String>[cur.korean, ...distractors];
    options.shuffle(_rng);
    setState(() {
      _options = options;
      _selected = -1;
      _locked = false;
    });
  }

  void _select(int i) {
    final cur = _current;
    final options = _options;
    if (cur == null || options == null || _locked) return;
    final isCorrect = options[i] == cur.korean;
    setState(() {
      _selected = i;
      _locked = true;
    });
    if (isCorrect) {
      _score++;
      HapticFeedback.lightImpact();
      SoundService.correct();
    } else {
      HapticFeedback.mediumImpact();
      SoundService.wrong();
      // ignore: discarded_futures
      Storage.incrementWrongCount(cur.korean);
    }
    // 정답 철자를 소리로 한 번 더 각인.
    // ignore: discarded_futures
    TtsService.speak(cur.korean);
    // ignore: discarded_futures
    Storage.srsReview(cur.korean, gotIt: isCorrect);
    Future.delayed(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      if (_idx + 1 >= _round.length) {
        Storage.addXp(_score * 2);
        setState(() => _done = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) SoriCelebration.burst(context);
        });
        return;
      }
      setState(() => _idx++);
      _prepare();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    return SoriStudyFrame(
      title: widget.title ?? t.hardQuizTitle,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SoriAdaptiveStudyBody(
              minHeight: 380,
              child: _done || _round.isEmpty
                  ? _buildDone(t)
                  : _buildQuestion(t, s, lang),
            ),
    );
  }

  Widget _buildQuestion(AppL10n t, SoriSurfaces s, String lang) {
    final cur = _current!;
    final options = _options ?? const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SoriChip(
              label: '${_idx + 1} / ${_round.length}',
              accent: SoriColors.info,
            ),
            Text(
              t.hardQuizHint,
              style: TextStyle(fontSize: 12, color: s.textMuted),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        SoriCard(
          variant: SoriCardVariant.hero,
          accent: SoriColors.accent,
          tinted: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
            child: Text(
              cur.translationFor(lang),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Expanded(
          child: ListView.separated(
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
            itemBuilder: (_, i) => QuizChoice(
              text: options[i],
              isCorrect: options[i] == cur.korean,
              isSelected: _selected == i,
              revealed: _locked,
              minHeight: 56,
              onSelected: _locked ? null : () => _select(i),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDone(AppL10n t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Mascot.tiger(emotion: MascotEmotion.celebrate, size: 120),
          const SizedBox(height: Spacing.lg),
          Text(
            t.hardQuizDoneTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Spacing.sm),
          Text(t.hardQuizScore(_score, _round.length)),
          const SizedBox(height: Spacing.xl),
          SoriButton(
            label: t.btnClose,
            variant: SoriButtonVariant.filled,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}
