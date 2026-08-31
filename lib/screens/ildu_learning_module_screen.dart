import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/ildu_construction_plan.dart';
import '../models/ildu_construction_progress.dart';
import '../services/ildu_construction_plan_repository.dart';
import '../services/ildu_construction_progress_service.dart';
import '../services/ildu_learning_response_evaluator.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/app_bar.dart';
import '../widgets/sori/text_field.dart';
import '../widgets/sori/toast.dart';
import '../widgets/sori/tokens.dart';

/// `/hanok/module` 라우트 인자. 진행도는 anchorId(월드 인스턴스) 단위다 (D9).
class IlDuLearningModuleArgs {
  const IlDuLearningModuleArgs({
    required this.anchorId,
    required this.buildingId,
    required this.moduleId,
  });

  final String anchorId;
  final String buildingId;
  final String moduleId;
}

typedef IlDuModulePlanLoader = Future<IlDuEstateConstructionPlan> Function();

/// 건설 단계 하나에 연결된 학습 모듈 화면 (Phase 3).
///
/// 섹션 순서 (설계 §6~§8): (한자가 실재하면) 문구 → 역사 → 비판적 렌즈 →
/// 2026 장면 → 한국어 행동(입력·힌트·평가). 모듈 콘텐츠는 플랜 JSON 의
/// ko/de/en 을 앱 로케일에 따라 고르고, UI 크롬 문자열만 arb 를 쓴다.
/// 평가는 저작된 언어 증거만 본다 — 입장·가치관은 채점하지 않는다.
class IlDuLearningModuleScreen extends StatefulWidget {
  const IlDuLearningModuleScreen({
    super.key,
    required this.args,
    this.loadPlan,
    this.progressStore = const SharedPreferencesIlDuConstructionProgressStore(),
    this.evaluator = const IlDuLearningResponseEvaluator(),
  });

  final IlDuLearningModuleArgs args;
  final IlDuModulePlanLoader? loadPlan;
  final IlDuConstructionProgressStore progressStore;
  final IlDuLearningResponseEvaluator evaluator;

  @override
  State<IlDuLearningModuleScreen> createState() =>
      _IlDuLearningModuleScreenState();
}

class _IlDuLearningModuleScreenState extends State<IlDuLearningModuleScreen> {
  static const _draftDebounce = Duration(milliseconds: 400);

  final TextEditingController _input = TextEditingController();
  late final IlDuConstructionPlanRepository _repository =
      IlDuConstructionPlanRepository();
  IlDuLearningModule? _module;
  IlDuConstructionProgressService? _progress;
  Object? _loadError;
  Timer? _draftTimer;
  bool _submitting = false;
  bool _completed = false;
  bool _showMissingHint = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    unawaited(_persistDraftNow());
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final plan = await (widget.loadPlan ?? _repository.load)();
      if (!plan.hasModule(widget.args.moduleId) ||
          !plan.hasBuilding(widget.args.buildingId)) {
        throw ArgumentError.value(
          widget.args.moduleId,
          'moduleId',
          'Unknown construction module route',
        );
      }
      final progress = IlDuConstructionProgressService(
        plan: plan,
        store: widget.progressStore,
      );
      await progress.initialize();
      final record = progress.snapshot.anchorFor(widget.args.anchorId);
      final draft = record?.draftsByModuleId[widget.args.moduleId];
      if (!mounted) {
        return;
      }
      setState(() {
        _module = plan.moduleFor(widget.args.moduleId);
        _progress = progress;
        if (draft != null && _input.text.isEmpty) {
          _input.text = draft;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loadError = error);
    }
  }

  void _handleChanged(String _) {
    if (_showMissingHint) {
      setState(() => _showMissingHint = false);
    }
    _draftTimer?.cancel();
    _draftTimer = Timer(_draftDebounce, () => unawaited(_persistDraftNow()));
  }

  /// 초안 저장 실패는 조용히 넘긴다 — 텍스트는 화면 메모리에 그대로 남고,
  /// 다음 변경·제출에서 다시 시도된다 (설계 §14: 답안 보존).
  Future<void> _persistDraftNow() async {
    final progress = _progress;
    if (progress == null || _completed) {
      return;
    }
    try {
      await progress.saveDraft(
        anchorId: widget.args.anchorId,
        buildingId: widget.args.buildingId,
        moduleId: widget.args.moduleId,
        text: _input.text,
      );
    } catch (_) {
      // 답안은 컨트롤러에 보존된다.
    }
  }

  Future<void> _submit() async {
    final module = _module;
    final progress = _progress;
    if (module == null || progress == null || _submitting) {
      return;
    }
    final result = widget.evaluator.evaluate(module, input: _input.text);
    if (!result.taskComplete) {
      setState(() => _showMissingHint = true);
      return;
    }
    setState(() => _submitting = true);
    try {
      await progress.completeModule(
        anchorId: widget.args.anchorId,
        buildingId: widget.args.buildingId,
        moduleId: widget.args.moduleId,
      );
    } on IlDuConstructionProgressWriteException {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      soriToast(context, AppL10n.of(context).ilduModuleSaveError);
      return;
    }
    _completed = true;
    _draftTimer?.cancel();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  IlDuLearningCopy _copyFor(IlDuLearningModule module, String languageCode) =>
      module.copyByLanguage[languageCode] ?? module.copyByLanguage['en']!;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final module = _module;
    final copy = module == null
        ? null
        : _copyFor(module, Localizations.localeOf(context).languageCode);
    return Scaffold(
      appBar: SoriAppBar(
        title: copy?.title ?? '',
        textScale: MediaQuery.textScalerOf(context).scale(1),
        viewportWidth: MediaQuery.sizeOf(context).width,
        adaptTitleAtNormalScale: true,
      ),
      body: module == null || copy == null
          ? _loadError == null
                ? const AppLoading()
                : Center(
                    child: IconButton.filledTonal(
                      key: const ValueKey('ildu-module-load-retry'),
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).refreshIndicatorSemanticLabel,
                    ),
                  )
          : _ModuleBody(
              module: module,
              copy: copy,
              input: _input,
              submitting: _submitting,
              showMissingHint: _showMissingHint,
              onChanged: _handleChanged,
              onSubmit: _submit,
              t: t,
            ),
    );
  }
}

class _ModuleBody extends StatelessWidget {
  const _ModuleBody({
    required this.module,
    required this.copy,
    required this.input,
    required this.submitting,
    required this.showMissingHint,
    required this.onChanged,
    required this.onSubmit,
    required this.t,
  });

  final IlDuLearningModule module;
  final IlDuLearningCopy copy;
  final TextEditingController input;
  final bool submitting;
  final bool showMissingHint;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final AppL10n t;

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    final surfaces = SoriSurfaces.of(context);
    final bodyStyle = text.body.copyWith(height: 1.5);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.md,
          Spacing.lg,
          Spacing.xxl,
        ),
        children: [
          // ① 한자 문구 — 현판·명칭에 실재할 때만 (설계 §6: 억지 한자 금지).
          if (module.hanja.isNotEmpty) ...[
            Text(
              module.hanja.join(),
              key: const ValueKey('ildu-module-hanja'),
              style: text.cultureDisplay,
            ),
            const SizedBox(height: Spacing.lg),
          ],
          // ② 역사.
          Text(t.ilduModuleHistoryHeading, style: text.eyebrow),
          const SizedBox(height: Spacing.xs),
          Text(
            copy.history,
            key: const ValueKey('ildu-module-history'),
            style: bodyStyle,
          ),
          const SizedBox(height: Spacing.lg),
          // ③ 비판적 렌즈.
          Text(t.ilduModuleCriticalHeading, style: text.eyebrow),
          const SizedBox(height: Spacing.xs),
          Text(
            copy.criticalLens,
            key: const ValueKey('ildu-module-critical-lens'),
            style: bodyStyle,
          ),
          const SizedBox(height: Spacing.lg),
          // ④ 2026년 장면.
          Text(t.ilduModuleModernHeading, style: text.eyebrow),
          const SizedBox(height: Spacing.xs),
          Text(
            copy.modernScene,
            key: const ValueKey('ildu-module-modern-scene'),
            style: bodyStyle,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            copy.sceneLine,
            key: const ValueKey('ildu-module-scene-line'),
            style: text.cultureTitle.copyWith(height: 1.4),
          ),
          const SizedBox(height: Spacing.lg),
          // ⑤ 한국어 행동.
          Text(t.ilduModuleActionHeading, style: text.eyebrow),
          const SizedBox(height: Spacing.xs),
          Text(
            copy.actionPrompt,
            key: const ValueKey('ildu-module-action-prompt'),
            style: text.cardTitle.copyWith(height: 1.4),
          ),
          const SizedBox(height: Spacing.sm),
          SoriTextField(
            fieldKey: const ValueKey('ildu-module-input'),
            controller: input,
            labelText: t.ilduModuleInputLabel,
            minLines: 2,
            maxLines: 4,
            maxLength: kIlDuConstructionDraftMaxCodePoints,
            counterText: '',
            textInputAction: TextInputAction.newline,
            onChanged: onChanged,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            t.ilduModuleTargetHint(module.targetExpressions.join(' · ')),
            key: const ValueKey('ildu-module-target-hint'),
            style: text.caption.copyWith(color: surfaces.textMuted),
          ),
          if (showMissingHint) ...[
            const SizedBox(height: Spacing.xs),
            // Jin 영구 규칙: 배지·필 금지 — 강조는 본문 타이포로만.
            Text(
              t.ilduModuleMissingHint,
              key: const ValueKey('ildu-module-missing-hint'),
              style: text.bodySmall.copyWith(
                color: SoriColors.primaryDark,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: Spacing.md),
          SizedBox(
            width: double.infinity,
            height: Spacing.xxxl,
            child: FilledButton(
              key: const ValueKey('ildu-module-submit'),
              onPressed: submitting ? null : onSubmit,
              child: Text(t.ilduModuleSubmit),
            ),
          ),
        ],
      ),
    );
  }
}
