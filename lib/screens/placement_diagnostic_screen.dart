import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/placement_diagnostic.dart';
import '../services/tts_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/tokens.dart';

/// An optional practical placement check. It deliberately has no microphone
/// and exposes the final level choice, so its result is a recommendation only.
class PlacementDiagnosticScreen extends StatefulWidget {
  const PlacementDiagnosticScreen({super.key, required this.onChooseLevel});

  final Future<void> Function(String levelCode) onChooseLevel;

  @override
  State<PlacementDiagnosticScreen> createState() =>
      _PlacementDiagnosticScreenState();
}

class _PlacementDiagnosticScreenState extends State<PlacementDiagnosticScreen> {
  int _index = 0;
  final List<int> _answers = [];
  int? _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeSpeakPrompt());
  }

  /// 청취 유형 문제("Hör zu und wähle die Bedeutung")는 등장 시 자동 발음 재생 —
  /// 앱 전체 "듣고 고르기"와 통일. 다른 유형(문법·어순·의미 읽기)은 읽기
  /// 문제라 무음을 유지한다.
  void _maybeSpeakPrompt() {
    if (!mounted || _done) {
      return;
    }
    final question = placementDiagnosticQuestions[_index];
    if (question.skill == PlacementDiagnosticSkill.listening &&
        question.korean.isNotEmpty) {
      // ignore: discarded_futures
      TtsService.speak(question.korean);
    }
  }

  String get _lang => Localizations.localeOf(context).languageCode;
  bool get _done => _index >= placementDiagnosticQuestions.length;
  int get _correct => List<int>.generate(_answers.length, (index) => index)
      .where(
        (index) =>
            _answers[index] == placementDiagnosticQuestions[index].correctIndex,
      )
      .length;

  void _next() {
    final selected = _selected;
    if (selected == null) return;
    // 배치고사는 진단이지 게임이 아니다 — 정답음/오답음을 넣으면 이 화면이 의도적으로
    // 감추는 "이 문항 틀렸다"가 소리로 새어나가고, 남은 문항 수행에도 영향을 준다.
    // 그래서 정오와 무관한 중립 확정 피드백만 준다.
    HapticFeedback.selectionClick();
    setState(() {
      _answers.add(selected);
      _selected = null;
      _index++;
    });
    // 다음 문제가 청취 유형이면 자동 발음 재생.
    _maybeSpeakPrompt();
  }

  Future<void> _choose(String levelCode) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onChooseLevel(levelCode);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.placementTitle)),
      body: SoriScreenBackground(
        child: SafeArea(
          child: SoriCenterClamp(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
              child: _done ? _result(t) : _question(t),
            ),
          ),
        ),
      ),
    );
  }

  Widget _question(AppL10n t) {
    final question = placementDiagnosticQuestions[_index];
    final choices = question.choices(_lang);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.placementProgress(_index + 1, placementDiagnosticQuestions.length),
          style: SoriTextTheme.of(
            context,
          ).label.copyWith(color: SoriColors.primary),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          t.placementNoRecording,
          style: SoriTextTheme.of(context).bodySmall,
        ),
        const SizedBox(height: Spacing.xl),
        SoriCard(
          variant: SoriCardVariant.hero,
          accent: SoriColors.primary,
          tinted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(question.prompt(_lang), style: SoriTextTheme.of(context).h3),
              if (question.korean.isNotEmpty) ...[
                const SizedBox(height: Spacing.lg),
                Text(question.korean, style: SoriTextTheme.of(context).display),
              ],
              // 청취 문제는 다시 듣기 버튼 제공(등장 시 자동 재생 + 재생 반복).
              if (question.skill == PlacementDiagnosticSkill.listening &&
                  question.korean.isNotEmpty) ...[
                const SizedBox(height: Spacing.md),
                SoriButton.outlined(
                  label: t.vocabPackBossReplayAudio,
                  icon: Icons.volume_up_rounded,
                  onTap: () {
                    // ignore: discarded_futures
                    TtsService.speak(question.korean);
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),
        for (var index = 0; index < choices.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: SoriCard(
              variant: SoriCardVariant.base,
              // 표면 v2 (§10.3): 선택지는 경계=정보 → selectable 테두리 문법.
              // 선택 상태 = primary 2px + 옅은 primary 채움(tinted).
              selectable: true,
              selected: _selected == index,
              tinted: _selected == index,
              onTap: () => setState(() => _selected = index),
              child: Row(
                children: [
                  Icon(
                    _selected == index
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: _selected == index
                        ? SoriColors.primary
                        : SoriSurfaces.of(context).textMuted,
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Text(
                      choices[index],
                      style: SoriTextTheme.of(context).body,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const Spacer(),
        SoriButton.filled(
          label: _index + 1 == placementDiagnosticQuestions.length
              ? t.placementSeeRecommendation
              : t.btnNext,
          fullWidth: true,
          onTap: _selected == null ? null : _next,
        ),
      ],
    );
  }

  Widget _result(AppL10n t) {
    final recommendation = recommendPlacement(_correct);
    return ListView(
      children: [
        SoriCard(
          variant: SoriCardVariant.hero,
          accent: SoriColors.success,
          tinted: true,
          eaves: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.placementRecommendedStart,
                style: SoriTextTheme.of(
                  context,
                ).label.copyWith(color: SoriColors.success),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                recommendation.toUpperCase(),
                style: SoriTextTheme.of(context).display,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                t.placementScoreSummary(
                  _correct,
                  placementDiagnosticQuestions.length,
                ),
                style: SoriTextTheme.of(context).body,
              ),
              const SizedBox(height: Spacing.lg),
              SoriButton.filled(
                label: t.placementStartAt(recommendation.toUpperCase()),
                fullWidth: true,
                onTap: _saving ? null : () => _choose(recommendation),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.xl),
        Text(t.placementChooseYourself, style: SoriTextTheme.of(context).h3),
        const SizedBox(height: Spacing.sm),
        for (final level in const ['a1', 'a2', 'b1', 'b2'])
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: SoriButton.outlined(
              label: level.toUpperCase(),
              fullWidth: true,
              onTap: _saving ? null : () => _choose(level),
            ),
          ),
      ],
    );
  }
}
