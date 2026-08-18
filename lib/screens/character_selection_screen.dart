import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../motion/transitions.dart';
import '../services/analytics_service.dart';
import '../services/storage_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/character_clip.dart';
import '../widgets/sori/consent_invite_sheet.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/mascot_preference.dart';
import '../widgets/sori/motion.dart';
import '../widgets/sori/page_header.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';
import 'consent_screen.dart';
import 'onboarding_level_screen.dart';

// 일월(日月) 무대 팔레트 — ASSET_GENERATION_BIBLE §1.3 의 일러스트 전용 hex.
// (UI 토큰과 의도적으로 분리 — 카드 안 "무대"는 일러스트 세계의 색을 쓴다.)
// 민화 일월오봉도 도상: 호랑이=해(금, 오른쪽) / 까치=달(백, 왼쪽).
const Color _kTigerStagePanel = Color(0xFFF4E8D0); // Hanji Ivory
const Color _kTigerStageSun = Color(0xFFDFA951); // Dancheong Gold
const Color _kMagpieStagePanel = Color(0xFFD8E5DC); // Sky Celadon
const Color _kMagpieStageMoon = Color(0xFFFFFCF2); // Hanji Light

/// **캐릭터 선택 + 첫 인사**
///
/// 첫 실행 후 호랑이/까치 중 선택 → 선택한 캐릭터가 **말 없이 몸짓으로**
/// 확정을 알린다 (호랑이: 목례 / 까치: 착지).
///
/// 2026-07-29 배치 계획: A0 학습자에게 통문장 한국어 TTS 인사는 소외감을
/// 주어 제거. 이후 homeScreen에서 선택한 캐릭터가 메인 사이드킥이 된다.
class CharacterSelectionScreen extends StatefulWidget {
  const CharacterSelectionScreen({
    super.key,
    this.optional = false,
    this.onOptionalComplete,
  }) : previewMode = false,
       onPreviewComplete = null;

  /// Storage-free 01D fixture. Selection is staged exactly like the optional
  /// production flow, but confirm/skip report to the host instead of changing
  /// the global companion or onboarding flags.
  const CharacterSelectionScreen.preview({
    super.key,
    required this.onPreviewComplete,
  }) : optional = true,
       onOptionalComplete = null,
       previewMode = true;

  /// The first-success route lets a learner defer the choice without changing
  /// their level or course. The legacy direct route keeps its existing flow.
  final bool optional;

  /// Test and embedding seam for the optional route. When omitted, completion
  /// returns to the route that opened the chooser.
  final FutureOr<void> Function()? onOptionalComplete;
  final bool previewMode;
  final FutureOr<void> Function(MascotKind? kind)? onPreviewComplete;

  @override
  State<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  MascotKind? _selected;
  bool _isLoading = false;
  bool _navigated = false;
  bool _showConfirmation = false;
  final ScrollController _scroll = ScrollController();

  // 선택 전 미리보기는 **정적 호흡 마스코트만** 쓴다 (2026-08-02 실기기 검수).
  // 이전에는 3.2초마다 호랑이↔까치 클립을 교대 재생했는데, 이 기기(SD678/
  // Android 12)는 Impeller가 새 비디오 텍스처의 fence 를 기다리지 못해
  // ("ImageTextureEntry can't wait on the fence on Android < 33") 디코더가
  // 교대될 때마다 흰 프레임이 번쩍였고, tiger_rise 루프에 매핑된 인사
  // 효과음이 교대 주기마다 반복 재생됐다. 영상 연출은 선택 확정 후 **단일
  // 시그니처 클립**(디코더 1개·일회성·핸드오프 0)으로만 남긴다 — 구
  // choose→greet 2단 체인은 이 기기에서 텍스처 교대 시 흰 프레임 번쩍 +
  // 완료 미보고 시 멈춤을 유발해 하나로 축약했다(2026-08-05 Jin 실기기).

  @override
  void initState() {
    super.initState();
    if (!widget.previewMode) {
      Analytics.tutorialStep(stepNumber: 4, stepName: 'character_select');
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _handleSelection(MascotKind kind) async {
    if (_isLoading) return;

    // 01D stages the visible choice first. The preference is committed only
    // when the learner chooses the explicit Today CTA, so Back/Not now never
    // leaves a half-confirmed companion behind.
    if (widget.optional) {
      setState(() => _selected = kind);
      return;
    }

    setState(() {
      _selected = kind;
      _isLoading = true;
    });

    // 선택한 캐릭터 저장 + 전역 통지 (설정에서 바꿀 때와 같은 경로).
    await MascotPreference.set(kind);
    if (!mounted) return;
    setState(() => _showConfirmation = true);
  }

  Future<void> _proceed() async {
    if (!mounted || _navigated) return;
    _navigated = true;
    debugPrint(
      '[ONBOARD] Character.proceed -> '
      '${Storage.consentAccepted ? "OnboardingLevelScreen" : "ConsentScreen"} '
      '(consentAccepted=${Storage.consentAccepted} '
      'userLevelCode=${Storage.userLevelCode})',
    );
    // DSGVO Consent-Gate: 퀵 온보딩(첫 실행) 경로는 인트로를 거치지 않아
    // 동의 화면이 한 번도 안 뜨던 갭(2026-06-12 웹 검증에서 발견).
    // 미동의면 동의 화면으로 — 이후 단계(프리뷰/레벨/홈)는 ConsentScreen이 분기.
    if (!Storage.consentAccepted) {
      Navigator.of(context).pushReplacement(
        SoriTransitions.fadeScale((_) => const ConsentScreen()),
      );
      return;
    }
    // 캐릭터 선택 직후 · 온보딩(레벨/배치) 전 → 추적 동의(쿠키배너식) 1회 요청.
    // consentAccepted 이후이므로 여기서 물으면 이후 온보딩 퍼널을 계측할 수 있다.
    await ConsentInviteSheet.maybeShow(context);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      SoriTransitions.fadeScale((_) => const OnboardingLevelScreen()),
    );
  }

  Future<void> _skipOptional() async {
    if (!widget.optional || _isLoading || _navigated) return;
    _navigated = true;
    if (widget.previewMode) {
      await widget.onPreviewComplete?.call(null);
      return;
    }
    await MascotPreference.setNone();
    await Storage.setIntroPreviewSeen();
    if (!mounted) return;
    await _completeOptional();
  }

  Future<void> _confirmOptionalSelection() async {
    if (!widget.optional || _selected == null || _isLoading || _navigated) {
      return;
    }
    setState(() => _isLoading = true);
    if (widget.previewMode) {
      if (!mounted) return;
      setState(() => _showConfirmation = true);
      return;
    }
    await MascotPreference.set(_selected!);
    if (!mounted) return;
    await Storage.setIntroPreviewSeen();
    if (!mounted) return;
    setState(() => _showConfirmation = true);
  }

  /// 선택 전용 원샷이 실제로 끝난 뒤에만 다음 단계로 간다.
  ///
  /// 영상이 불가능하거나 명시적으로 실패한 기기에서는
  /// [CharacterClipPlayer.fallbackCompleteAfter]가 같은 콜백을 전달한다.
  /// 따라서 까치의 7초 클립을 잘라 버리던 고정 2.4초 화면 타이머가 없고,
  /// lifecycle/route 비가시 상태에서는 플레이어의 lease와 함께 완료도 멈춘다.
  Future<void> _finishConfirmedSelection() async {
    if (!mounted || !_showConfirmation || _selected == null || _navigated) {
      return;
    }
    if (!widget.optional) {
      await _proceed();
      return;
    }

    _navigated = true;
    if (widget.previewMode) {
      await widget.onPreviewComplete?.call(_selected);
      return;
    }
    await _completeOptional();
  }

  Future<void> _completeOptional() async {
    final callback = widget.onOptionalComplete;
    if (callback != null) {
      await callback();
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(true);
    }
  }

  Widget _buildConfirmationScreen(BuildContext context, AppL10n t) {
    final selected = _selected!;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 명시적 확정 뒤에는 선택한 캐릭터의 전용 원샷 하나만
                      // 재생한다. 후보 화면을 정적으로 유지했으므로 디코더
                      // handoff도 없고, 완료 콜백이 navigation의 단일 시계다.
                      CharacterClipPlayer(
                        key: ValueKey<String>(
                          'character-confirmation-${selected.name}',
                        ),
                        asset: CharacterClips.chooseFor(selected),
                        size: (constraints.maxWidth - 48)
                            .clamp(260.0, 480.0)
                            .toDouble(),
                        loop: false,
                        blendColor: scaffoldColor,
                        staticFallback: CharacterClipPlayer.videoUnavailable(
                          context,
                        ),
                        fallbackKind: selected,
                        fallbackEmotion: MascotEmotion.celebrate,
                        // 영상 불가/실패만 기존 캡션 노출 시간으로 대체한다.
                        fallbackCompleteAfter: const Duration(
                          milliseconds: 2400,
                        ),
                        onCompleted: () =>
                            unawaited(_finishConfirmedSelection()),
                      ),
                      const SizedBox(height: Spacing.md),
                      Text(
                        selected == MascotKind.magpie
                            ? t.characterSelectedMagpie
                            : t.characterSelectedTiger,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: SoriColors.primary,
                        ),
                      ),
                      if (widget.optional) ...[
                        const SizedBox(height: Spacing.xs),
                        Text(
                          t.onboardingCompanionSelectionBody,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.45,
                            color: SoriColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionalCompanionScreen(BuildContext context, AppL10n t) {
    final text = SoriTextTheme.of(context);
    final surfaces = SoriSurfaces.of(context);

    return Scaffold(
      body: SafeArea(
        child: SoriCenterClamp(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  key: const ValueKey('companion-selection-scroll'),
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    Spacing.sm,
                    Spacing.lg,
                    Spacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          key: const ValueKey('companion-selection-back'),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).backButtonTooltip,
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      // §G 공통 프레임 — 캐릭터 패널·클립·색은 픽셀 불변.
                      SoriPageHeader(
                        eyebrow: t.onboardingCompanionEyebrow,
                        title: t.characterSelectionTitle,
                        body: t.onboardingCompanionPrompt,
                      ),
                      const SizedBox(height: Spacing.lg),
                      _OptionalCharacterCard(
                        key: const ValueKey('companion-option-tiger'),
                        kind: MascotKind.tiger,
                        name:
                            '${t.characterNameTiger} · ${t.characterRomanTiger}',
                        trait: t.characterTraitTiger,
                        description: t.characterDescTiger,
                        panelColor: _kTigerStagePanel,
                        accent: SoriColors.tigerOnLight,
                        selected: _selected == MascotKind.tiger,
                        onTap: _isLoading
                            ? null
                            : () => _handleSelection(MascotKind.tiger),
                      ),
                      const SizedBox(height: Spacing.sm),
                      _OptionalCharacterCard(
                        key: const ValueKey('companion-option-magpie'),
                        kind: MascotKind.magpie,
                        name:
                            '${t.characterNameMagpie} · ${t.characterRomanMagpie}',
                        trait: t.characterTraitMagpie,
                        description: t.characterDescMagpie,
                        panelColor: _kMagpieStagePanel,
                        accent: SoriColors.primary,
                        selected: _selected == MascotKind.magpie,
                        onTap: _isLoading
                            ? null
                            : () => _handleSelection(MascotKind.magpie),
                      ),
                      const SizedBox(height: Spacing.md),
                      AnimatedSwitcher(
                        duration: SoriMotion.respect(
                          context,
                          SoriMotion.medium,
                        ),
                        child: _selected == null
                            ? const SizedBox.shrink()
                            : Container(
                                key: ValueKey<String>(
                                  'companion-selection-${_selected!.name}',
                                ),
                                padding: const EdgeInsets.all(Spacing.md),
                                decoration: BoxDecoration(
                                  color: surfaces.surfaceAlt,
                                  border: Border.all(
                                    color: SoriColors.primary.withValues(
                                      alpha: 0.45,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    SoriRadius.lg,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selected == MascotKind.magpie
                                          ? t.onboardingCompanionSelectedMagpie
                                          : t.onboardingCompanionSelectedTiger,
                                      style: text.cardTitle.copyWith(
                                        color:
                                            surfaces.brightness ==
                                                Brightness.light
                                            ? SoriColors.primaryOnLight
                                            : SoriColors.primaryOnDark,
                                      ),
                                    ),
                                    const SizedBox(height: Spacing.xs),
                                    Text(
                                      t.onboardingCompanionSelectionBody,
                                      style: text.caption,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: surfaces.bg,
                  border: Border(top: BorderSide(color: surfaces.border)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    Spacing.md,
                    Spacing.lg,
                    Spacing.sm,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SoriButton.filled(
                        key: const ValueKey('companion-selection-continue'),
                        label: t.onboardingCompanionContinue,
                        trailingIcon: Icons.arrow_forward_rounded,
                        fullWidth: true,
                        onTap: _selected == null || _isLoading
                            ? null
                            : _confirmOptionalSelection,
                      ),
                      const SizedBox(height: Spacing.xs),
                      TextButton(
                        key: const ValueKey('companion-selection-skip'),
                        onPressed: _isLoading ? null : _skipOptional,
                        child: Text(t.onboardingCompanionSkip),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_showConfirmation && _selected != null) {
      return _buildConfirmationScreen(context, t);
    }
    if (widget.optional) {
      return _buildOptionalCompanionScreen(context, t);
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            controller: _scroll,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    // 후보 화면은 **전부 정지**. 선택 저장이 끝나면 이 트리는
                    // 내려가고, 별도 확정 화면에서 고른 캐릭터의 choose 원샷
                    // 하나만 재생한다.
                    children: [
                      // 상단 듀오는 정적 포스터. 선택 직후 choose 영상이
                      // 유일한 디코더가 되도록 ambient loop를 만들지 않는다.
                      SoriEntrance(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: const HanokHeader(
                            asset:
                                'assets/illustrations/hanok/taego-joy-duo.png',
                            loopAsset: 'assets/video/loops/taego-joy-duo.mp4',
                            aspectRatio: 16 / 9,
                            radius: 16,
                            animate: false,
                            fit: BoxFit.contain,
                            fallbackIcon: Icons.pets,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SoriEntrance(
                        delay: const Duration(milliseconds: 90),
                        child: Column(
                          children: [
                            Text(
                              t.characterSelectionTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1.3,
                              ),
                            ),
                            // 탭 유도 한 줄 (배지/필 금지 → 본문 인라인).
                            const SizedBox(height: 8),
                            Text(
                              t.characterSelectionHint,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: SoriColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 세로 배열 — 위 호랑이 / 아래 까치. 둘 다 정적 호흡
                      // 마스코트. 성격 대비는 일월(日月) 무대로:
                      // 호랑이=해(금빛 아침)·까치=달(청자빛 저녁).
                      SoriEntrance(
                        delay: const Duration(milliseconds: 180),
                        child: _CharacterCard(
                          kind: MascotKind.tiger,
                          name: t.characterNameTiger,
                          roman: t.characterRomanTiger,
                          trait: t.characterTraitTiger,
                          description: t.characterDescTiger,
                          accent: SoriColors.tigerOnLight,
                          panelColor: _kTigerStagePanel,
                          discColor: _kTigerStageSun,
                          discAtRight: true,
                          isSelected: false,
                          onTap: _isLoading
                              ? null
                              : () => _handleSelection(MascotKind.tiger),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SoriEntrance(
                        delay: const Duration(milliseconds: 300),
                        child: _CharacterCard(
                          kind: MascotKind.magpie,
                          name: t.characterNameMagpie,
                          roman: t.characterRomanMagpie,
                          trait: t.characterTraitMagpie,
                          description: t.characterDescMagpie,
                          accent: SoriColors.primary,
                          panelColor: _kMagpieStagePanel,
                          discColor: _kMagpieStageMoon,
                          discAtRight: false,
                          isSelected: false,
                          onTap: _isLoading
                              ? null
                              : () => _handleSelection(MascotKind.magpie),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact 01D option used after the first verified success. It keeps both
/// companions visible while the learner decides, so changing a choice is one
/// direct tap instead of a second confirmation route.
class _OptionalCharacterCard extends StatelessWidget {
  const _OptionalCharacterCard({
    super.key,
    required this.kind,
    required this.name,
    required this.trait,
    required this.description,
    required this.panelColor,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final MascotKind kind;
  final String name;
  final String trait;
  final String description;
  final Color panelColor;
  final Color accent;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    final surfaces = SoriSurfaces.of(context);
    final radius = BorderRadius.circular(SoriRadius.lg);

    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      selected: selected,
      label: '$name. $trait. $description',
      onTap: onTap,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: SoriMotion.respect(context, SoriMotion.medium),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(
                    accent.withValues(alpha: 0.08),
                    surfaces.surface,
                  )
                : surfaces.surface,
            border: Border.all(
              color: selected ? accent : surfaces.border,
              width: selected ? 2 : 1.5,
            ),
            borderRadius: radius,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(Spacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: panelColor,
                        borderRadius: BorderRadius.circular(SoriRadius.md),
                      ),
                      alignment: Alignment.center,
                      child: Mascot(
                        kind: kind,
                        emotion: MascotEmotion.smile,
                        size: 88,
                        animate: false,
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(name, style: text.cardTitle),
                          const SizedBox(height: 2),
                          Text(
                            trait,
                            style: text.label.copyWith(color: accent),
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(description, style: text.caption),
                        ],
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: selected ? accent : surfaces.textDim,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final MascotKind kind;
  final String name;

  /// 로마자 병기 — A0 학습자는 아직 한글 이름을 못 읽는다 (2026-08-03).
  final String roman;
  final String trait;

  /// 캐릭터 소개 2~3줄 — 이름·특성 아래 본문 (2026-08-02 Jin 요청).
  final String description;

  /// 캐릭터 고유 강조색 — 특성 라벨·선택 테두리·글로우.
  /// 호랑이 = [SoriColors.tigerOnLight](크림 위 대비 확보된 주황),
  /// 까치 = [SoriColors.primary](녹청). 성격 대비를 색으로 표현한다.
  final Color accent;

  /// 일월(日月) 무대 — 캐릭터가 흰 허공이 아니라 자기 세계 위에 선다.
  final Color panelColor;
  final Color discColor;

  /// 일월오봉도 배치 관례 — 해는 오른쪽, 달은 왼쪽.
  final bool discAtRight;
  final bool isSelected;
  final VoidCallback? onTap;

  const _CharacterCard({
    required this.kind,
    required this.name,
    required this.roman,
    required this.trait,
    required this.description,
    required this.accent,
    required this.panelColor,
    required this.discColor,
    required this.discAtRight,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              // cream 배경 위 흰 카드 — grey[300](1.2:1)은 사실상 안 보임.
              color: isSelected ? accent : SoriColors.lightBorderStrong,
              width: isSelected ? 3 : 2,
            ),
            borderRadius: BorderRadius.circular(SoriRadius.lg),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: accent.withValues(alpha: 0.22),
                  blurRadius: 14,
                  spreadRadius: 2,
                )
              else
                BoxShadow(
                  color: SoriColors.lightText.withValues(alpha: 0.07),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            children: [
              // 일월 무대 + 정지 마스코트 — 카드 상시 영상은 단일 디코더
              // lease·화이트 플래시 때문에 불가(State 상단 주석), 호흡
              // 애니메이션도 Jin 요청("까딱이는 이미지 삭제", 2026-08-03)으로
              // 제거. 캐릭터의 "살아있음"은 히어로 영상과 선택 순간의
              // roar/perched 클립이 담당한다.
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 172,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: _SunMoonStagePainter(
                          panel: panelColor,
                          disc: discColor,
                          discAtRight: discAtRight,
                        ),
                      ),
                      Center(
                        child: Mascot(
                          kind: kind,
                          emotion: MascotEmotion.smile,
                          size: 148,
                          animate: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  text: name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: SoriColors.lightText,
                  ),
                  children: [
                    TextSpan(
                      text: '  $roman',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: SoriColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                trait,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: accent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.start,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: SoriColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 면분할(faceted) 해/달 원판 + 단청 점 1군집 — BIBLE §1.2(윤곽선 없는 평면
/// 색면)·§1.4(강조는 군집, 흩뿌리기 금지) 준수. 난수 없이 고정 정점 배율만
/// 쓰는 결정적 페인터라 리빌드마다 모양이 흔들리지 않는다.
class _SunMoonStagePainter extends CustomPainter {
  final Color panel;
  final Color disc;
  final bool discAtRight;

  const _SunMoonStagePainter({
    required this.panel,
    required this.disc,
    required this.discAtRight,
  });

  /// 12각 원판의 정점별 반지름 배율 — 살짝 우둘투둘한 "잘라낸 색종이" 느낌.
  static const List<double> _radii = [
    1.0, 0.95, 1.03, 0.96, 1.0, 0.97, 1.04, 0.95, 1.0, 0.98, 1.02, 0.94, //
  ];

  // 단청 점 — BIBLE §1.3 (red/gold/teal).
  static const Color _dotRed = Color(0xFFC24A45);
  static const Color _dotGold = Color(0xFFDFA951);
  static const Color _dotTeal = Color(0xFF3D9A7F);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = panel);

    // 해/달 원판 — 상단에 반쯤 걸치는 배치. 마스코트 머리 뒤 후광처럼 읽힌다.
    final cx = size.width * (discAtRight ? 0.76 : 0.24);
    const cy = 46.0;
    const r = 44.0;
    final path = Path();
    for (var i = 0; i < _radii.length; i++) {
      final a = (i / _radii.length) * 2 * math.pi - math.pi / 2;
      final rr = r * _radii[i];
      final p = Offset(cx + rr * math.cos(a), cy + rr * math.sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = disc);

    // 단청 점 1군집 — 원판 반대편 하단 (양극 균형, §1.4-3).
    final dx = size.width * (discAtRight ? 0.16 : 0.84);
    final dy = size.height - 26.0;
    canvas.drawCircle(Offset(dx, dy), 3.4, Paint()..color = _dotRed);
    canvas.drawCircle(Offset(dx + 12, dy - 7), 2.6, Paint()..color = _dotTeal);
    canvas.drawCircle(Offset(dx - 4, dy - 13), 2.2, Paint()..color = _dotGold);
  }

  @override
  bool shouldRepaint(_SunMoonStagePainter oldDelegate) =>
      oldDelegate.panel != panel ||
      oldDelegate.disc != disc ||
      oldDelegate.discAtRight != discAtRight;
}
