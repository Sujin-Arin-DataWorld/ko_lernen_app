// reward_chest_screen.dart
//
// 퀘스트 완료 후 보여주는 4초 보상 연출 화면 (조선 자개함 컨셉).
// 영상 없이 Flutter 애니메이션과 CustomPainter로 전부 그립니다.
//
// 타임라인 (초)
//  0.00~1.00  자개빛이 숨 쉬며 빛점이 모임, 상자의 절제된 떨림과 부상
//  1.00~1.35  떨림이 멎고 열린 상자로 전환, 금빛·오로라 버스트
//  1.12~2.42  아이템이 상자 안에서 최종 hero 위치까지 한 궤적으로 이동
//  1.60~2.08  상자가 사라짐, 효과의 잔광도 기존보다 0.30초 일찍 정리
//  2.18~2.88  영어/독일어 보상 설명과 현재 XP 상태가 겹쳐 진입

import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/card.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

import 'reward_chest_prelude.dart';
import 'reward_chest_guide.dart';

// Keep the opening peak and reward flight intact; only bring the exit forward.
const _exitLeadSeconds = 0.30;

double _seg(double s, double a, double b, [Curve curve = Curves.linear]) {
  return curve.transform(((s - a) / (b - a)).clamp(0.0, 1.0));
}

Color _a(Color c, double alpha) =>
    c.withAlpha((alpha.clamp(0.0, 1.0) * 255).round());

class RewardChestScreen extends StatefulWidget {
  const RewardChestScreen({
    super.key,
    required this.itemAsset,
    required this.itemName,
    required this.onContinue,
    this.subtitle,
    this.rewardTypeLabel,
    this.itemDescription,
    this.totalXp,
    this.xpLevel,
    this.xpToNext,
    this.learnMoreLabel,
    this.onLearnMore,
    this.continueLabel,
    this.enableAudio = true,
    this.previewSecond,
    this.showBlueMagic = false,
  });

  /// 배경이 투명한 PNG 경로 (예: assets/items/norigae.png)
  final String itemAsset;
  final String itemName;
  final String? subtitle;
  final String? rewardTypeLabel;
  final String? itemDescription;
  final int? totalXp;
  final int? xpLevel;
  final int? xpToNext;
  final String? learnMoreLabel;
  final VoidCallback? onLearnMore;
  final String? continueLabel;
  final VoidCallback onContinue;
  final bool enableAudio;
  final double? previewSecond;

  /// Enables the approved blue accent and raised-paper receipt, without a mascot.
  final bool showBlueMagic;

  @override
  State<RewardChestScreen> createState() => _RewardChestScreenState();
}

class _RewardChestScreenState extends State<RewardChestScreen>
    with TickerProviderStateMixin {
  // ---- 에셋 경로 (pubspec.yaml에 등록 필요) ----
  static const _closedAsset =
      'assets/illustrations/reward/najeon_chest_closed.png';
  static const _openAsset = 'assets/illustrations/reward/najeon_chest_open.png';
  // audioplayers의 AssetSource는 assets/ 아래 경로를 씁니다.
  static const _sfxWood = 'sfx/chest_open.mp3';
  static const _sfxGaya = 'sfx/gayageum_gliss.mp3';
  static const _sfxBell = 'sfx/pungyeong.mp3';

  // ---- 눈으로 맞추는 값 (이미지 교체 시 여기만 조절) ----
  /// 열린 상자 이미지를 닫힌 상자 대비 얼마나 키울지 (몸통 너비 맞춤)
  static const _openScale = 1.055;

  /// 열린 상자 이미지 높이/너비 비율 (1278 / 1230)
  static const _openAspect = 1278 / 1230;

  /// 두 PNG의 투명 여백 차이로 생기는 바닥선 점프를 보정한다.
  static const _openBaselineShiftRatio = 0.052;

  /// 열린 상자 아래에서 입구(빛이 나오는 지점)까지의 높이 비율
  static const _mouthFromBottom = 0.46;

  /// 부상 높이 (상자 높이 대비)
  static const _liftRatio = 0.11;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4000),
  );

  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  AudioPlayer? _pWood;
  AudioPlayer? _pGaya;
  AudioPlayer? _pBell;

  bool _firedWood = false;
  bool _firedGaya = false;
  bool _firedBell = false;
  bool _reduceMotion = false;
  bool _skipped = false;

  @override
  void initState() {
    super.initState();
    if (widget.enableAudio) {
      _pWood = AudioPlayer();
      _pGaya = AudioPlayer();
      _pBell = AudioPlayer();
    }
    final previewSecond = widget.previewSecond;
    if (previewSecond != null) {
      _c.value = (previewSecond / 4.0).clamp(0.0, 1.0);
      _float.value = 0.5;
      return;
    }
    _c.addListener(_onTick);
    _float.repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.previewSecond != null || _reduceMotion) {
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _reduceMotion = true;
      _firedWood = _firedGaya = _firedBell = true;
      _float.stop();
      _float.value = 0.5;
      _c.value = 1.0;
    }
  }

  Future<void> _safe(Future<void> f) => f.catchError((_) {});

  Future<void> _start() async {
    await Future.wait([
      precacheImage(const AssetImage(_closedAsset), context),
      precacheImage(const AssetImage(_openAsset), context),
      precacheImage(AssetImage(widget.itemAsset), context),
      if (widget.enableAudio) ...[
        _safe(_pWood!.setSource(AssetSource(_sfxWood))),
        _safe(_pGaya!.setSource(AssetSource(_sfxGaya))),
        _safe(_pBell!.setSource(AssetSource(_sfxBell))),
      ],
    ]);
    if (!mounted || _reduceMotion || _skipped) {
      return;
    }
    _c.forward();
  }

  void _onTick() {
    final s = _c.value * 4.0;
    if (!_firedWood && s >= 1.00) {
      _firedWood = true;
      if (widget.enableAudio) {
        _play(_pWood!);
      }
      HapticFeedback.mediumImpact();
    }
    if (!_firedGaya && s >= 1.12) {
      _firedGaya = true;
      if (widget.enableAudio) {
        _play(_pGaya!);
      }
    }
    if (!_firedBell && s >= 1.56) {
      _firedBell = true;
      if (widget.enableAudio) {
        _play(_pBell!);
      }
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _play(AudioPlayer p) async {
    try {
      await p.seek(Duration.zero);
      await p.resume();
    } catch (_) {
      // 효과음 파일이 없어도 연출은 계속 진행
    }
  }

  void _skip() {
    if (_c.value * 4.0 >= 2.88) {
      return;
    }
    _skipped = true;
    _firedWood = _firedGaya = _firedBell = true;
    _pWood?.stop();
    _pGaya?.stop();
    _pBell?.stop();
    _c.value = 1.0;
  }

  @override
  void dispose() {
    _c.dispose();
    _float.dispose();
    _pWood?.dispose();
    _pGaya?.dispose();
    _pBell?.dispose();
    super.dispose();
  }

  // 상자가 떠 있는 정도 0~1. 점프가 아니라 천천히 부상했다가 착지한다.
  double _lift(double s) {
    if (s < 0.08) {
      return 0;
    }
    if (s < 0.78) {
      return Curves.easeOutCubic.transform((s - 0.08) / 0.70);
    }
    if (s < 1.0) {
      return 1;
    }
    if (s < 1.7) {
      return 1 - Curves.easeInOutCubic.transform((s - 1.0) / 0.70);
    }
    return 0;
  }

  double _shiverEnvelope(double s) =>
      _seg(s, 0.06, 0.28, Curves.easeOut) *
      (1 - _seg(s, 0.78, 1.0, Curves.easeIn));

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final surfaces = SoriSurfaces.of(context);
    return Scaffold(
      backgroundColor: surfaces.bg,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skip,
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            final h = box.maxHeight;
            final contentW = math.min(w, SoriBreakpoints.content);
            final chestW = math.min(contentW * 0.80, h * 0.46);
            final openW = chestW * _openScale;
            final openH = openW * _openAspect;
            final bottomY = h * 0.83;
            final origin = Offset(w / 2, bottomY - openH * _mouthFromBottom);
            final landscapeReceipt =
                widget.showBlueMagic && w >= 520 && h < 600;
            final itemSize = landscapeReceipt
                ? math.min(w * 0.36, h * 0.60)
                : math.min(contentW * 0.88, h * 0.38);
            final finalItemCenter = landscapeReceipt
                ? Offset(w * 0.24, h * 0.48)
                : Offset(w / 2, h * 0.21);
            final receiptTop = landscapeReceipt
                ? math.max(56.0, MediaQuery.paddingOf(context).top)
                : math.max(h * 0.405, finalItemCenter.dy + itemSize * 0.53);

            return AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final s = _c.value * 4.0;

                // ---- 상자: 부상 + 미세 떨림 + 부드러운 열림 ----
                final lift = _lift(s);
                final shiver = _shiverEnvelope(s);
                final shiverDx = math.sin(s * math.pi * 20) * 2.2 * shiver;
                final shiverAngle = math.sin(s * math.pi * 17) * 0.006 * shiver;
                final liftDy = -lift * openH * _liftRatio;
                final effectOrigin = origin.translate(shiverDx, liftDy);
                final chestExit = _seg(
                  s,
                  1.90 - _exitLeadSeconds,
                  2.38 - _exitLeadSeconds,
                  Curves.easeInOutCubic,
                );
                final chestOpacity = _seg(s, 0.0, 0.18) * (1 - chestExit);
                // 두 완성 PNG를 오래 겹치면 닫힌 뚜껑이 잔상처럼 남는다.
                // 열림 버스트가 정점인 1.04초에 닫힌 이미지를 완전히 제거한 뒤
                // 열린 이미지를 올려, 원본 무늬는 보존하면서 이중상을 막는다.
                final closedOp = 1 - _seg(s, 0.96, 1.04, Curves.easeIn);
                final openOp = _seg(s, 1.04, 1.30, Curves.easeOutCubic);
                // A single decelerating flight avoids stopping between the
                // chest reveal and the receipt. Scale follows the same clock.
                final launchStart = origin.translate(0, itemSize * 0.20);
                final flight = _seg(s, 1.12, 2.42, Curves.easeOutCubic);
                final itemCenter = Offset.lerp(
                  launchStart,
                  finalItemCenter,
                  flight,
                )!;
                final itemScale = 0.18 + 0.82 * flight;
                final itemOpacity = _seg(s, 1.12, 1.26, Curves.easeOut);
                final floatAmp = 1.5 * _seg(s, 2.70, 3.02);

                return Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: surfaces.bg)),

                    // Pearl anticipation shares the reveal clock and follows
                    // the chest's lift. It stays behind the original artwork.
                    if (s > 0 && s < 1.42)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              key: const Key('reward-chest-prelude'),
                              painter: RewardChestPreludePainter(
                                second: s,
                                origin: effectOrigin,
                                floor: Offset(w / 2, bottomY - chestW * 0.052),
                                chestWidth: chestW,
                                lift: lift,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // 모든 광원은 상자 뒤와 위에서만 그린다.
                    if (widget.showBlueMagic && s > 0.42 && s < 1.46)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              key: const Key('reward-blue-light'),
                              painter: RewardChestBlueLightPainter(
                                second: s,
                                origin: effectOrigin,
                                chestWidth: chestW,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: _BackFxPainter(
                              s: s,
                              origin: effectOrigin,
                              itemCenter: itemCenter,
                              itemSize: itemSize,
                              chestW: chestW,
                              clearTextY: receiptTop,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 상자 뒷면/뚜껑. 열린 PNG를 입구선에서 둘로 나눠
                    // 아이템이 실제로 몸통 뒤에서 솟아오르는 깊이를 만든다.
                    if (chestOpacity > 0)
                      _ChestArtwork(
                        bottom: h - bottomY,
                        openW: openW,
                        openH: openH,
                        chestW: chestW,
                        shiverDx: shiverDx,
                        dy: liftDy + 18 * chestExit,
                        angle: shiverAngle,
                        opacity: chestOpacity,
                        closedOpacity: closedOp,
                        openOpacity: openOp,
                        baselineShift: chestW * _openBaselineShiftRatio,
                        frontOnly: false,
                      ),

                    // 보상 아이템은 상자가 열린 직후부터 입구에서 올라온다.
                    if (s >= 1.10)
                      Positioned(
                        left: itemCenter.dx - itemSize / 2,
                        top: itemCenter.dy - itemSize / 2,
                        width: itemSize,
                        height: itemSize,
                        child: Opacity(
                          opacity: itemOpacity,
                          child: Transform.scale(
                            scale: itemScale,
                            child: AnimatedBuilder(
                              animation: _float,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(
                                  0,
                                  (Curves.easeInOut.transform(_float.value) *
                                              2 -
                                          1) *
                                      floatAmp,
                                ),
                                child: child,
                              ),
                              child: RepaintBoundary(
                                child: Semantics(
                                  image: true,
                                  label: widget.itemName,
                                  child: Image.asset(
                                    key: const Key('reward-item'),
                                    widget.itemAsset,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // 열린 상자의 앞 몸통을 아이템 위에 다시 그려 입구 가림을
                    // 만든다. 완성 PNG를 둘로 자르므로 닫힌 이미지 잔상은 없다.
                    if (chestOpacity > 0)
                      _ChestArtwork(
                        bottom: h - bottomY,
                        openW: openW,
                        openH: openH,
                        chestW: chestW,
                        shiverDx: shiverDx,
                        dy: liftDy + 18 * chestExit,
                        angle: shiverAngle,
                        opacity: chestOpacity,
                        closedOpacity: 0,
                        openOpacity: openOp,
                        baselineShift: chestW * _openBaselineShiftRatio,
                        frontOnly: true,
                      ),

                    // 아이템이 hero 자리에 닿기 직전 영수증이 뒤따라 올라온다.
                    if (s > 2.18)
                      Positioned(
                        left: landscapeReceipt
                            ? w * 0.46 + 12
                            : (w - contentW) / 2 + 20,
                        right: landscapeReceipt ? 16 : (w - contentW) / 2 + 20,
                        top: receiptTop,
                        bottom: math.max(
                          12,
                          MediaQuery.paddingOf(context).bottom,
                        ),
                        child: IgnorePointer(
                          ignoring: s < 2.84,
                          child: _ReceiptViewport(
                            comparison: widget.showBlueMagic,
                            child: _RewardReceipt(
                              itemName: widget.itemName,
                              showBlueMagic: widget.showBlueMagic,
                              second: s,
                              itemTerm: widget.subtitle,
                              rewardTypeLabel:
                                  widget.rewardTypeLabel ??
                                  t.rewardChestNewDecoration,
                              itemDescription: widget.itemDescription,
                              totalXp: widget.totalXp,
                              xpLevel: widget.xpLevel,
                              xpToNext: widget.xpToNext,
                              learnMoreLabel:
                                  widget.learnMoreLabel ??
                                  t.rewardChestCulturalStory,
                              onLearnMore: widget.onLearnMore,
                              continueLabel:
                                  widget.continueLabel ??
                                  t.soriStageReceiptContinue,
                              onContinue: s >= 2.84 ? widget.onContinue : null,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ChestArtwork extends StatelessWidget {
  const _ChestArtwork({
    required this.bottom,
    required this.openW,
    required this.openH,
    required this.chestW,
    required this.shiverDx,
    required this.dy,
    required this.angle,
    required this.opacity,
    required this.closedOpacity,
    required this.openOpacity,
    required this.baselineShift,
    required this.frontOnly,
  });

  final double bottom;
  final double openW;
  final double openH;
  final double chestW;
  final double shiverDx;
  final double dy;
  final double angle;
  final double opacity;
  final double closedOpacity;
  final double openOpacity;
  final double baselineShift;
  final bool frontOnly;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 0,
    right: 0,
    bottom: bottom,
    child: Center(
      child: Transform.translate(
        offset: Offset(shiverDx, dy),
        child: Transform.rotate(
          angle: angle,
          alignment: Alignment.bottomCenter,
          child: Opacity(
            opacity: opacity,
            child: SizedBox(
              width: openW,
              height: openH,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  if (!frontOnly && closedOpacity > 0)
                    Opacity(
                      opacity: closedOpacity,
                      child: SizedBox(
                        width: chestW,
                        child: Image.asset(
                          key: const Key('reward-chest-closed'),
                          _RewardChestScreenState._closedAsset,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                  if (openOpacity > 0)
                    Positioned(
                      top: -baselineShift,
                      bottom: baselineShift,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: openOpacity,
                        child: ClipRect(
                          clipper: _ChestSliceClipper(front: frontOnly),
                          child: Image.asset(
                            key: const Key('reward-chest-open'),
                            _RewardChestScreenState._openAsset,
                            width: openW,
                            height: openH,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ),
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

class _ChestSliceClipper extends CustomClipper<Rect> {
  const _ChestSliceClipper({required this.front});

  final bool front;

  @override
  Rect getClip(Size size) {
    const cut = 1 - _RewardChestScreenState._mouthFromBottom;
    return front
        ? Rect.fromLTRB(0, size.height * cut, size.width, size.height)
        : Rect.fromLTRB(0, 0, size.width, size.height * cut);
  }

  @override
  bool shouldReclip(covariant _ChestSliceClipper oldClipper) =>
      oldClipper.front != front;
}

class _RewardReceipt extends StatelessWidget {
  const _RewardReceipt({
    required this.second,
    required this.itemName,
    required this.itemTerm,
    required this.rewardTypeLabel,
    required this.itemDescription,
    required this.totalXp,
    required this.xpLevel,
    required this.xpToNext,
    required this.learnMoreLabel,
    required this.onLearnMore,
    required this.continueLabel,
    required this.onContinue,
    this.showBlueMagic = false,
  });

  final double second;
  final String itemName;
  final String? itemTerm;
  final String rewardTypeLabel;
  final String? itemDescription;
  final int? totalXp;
  final int? xpLevel;
  final int? xpToNext;
  final String learnMoreLabel;
  final VoidCallback? onLearnMore;
  final String continueLabel;
  final VoidCallback? onContinue;
  final bool showBlueMagic;

  @override
  Widget build(BuildContext context) {
    if (showBlueMagic) {
      return RewardGuideReceipt(
        second: second,
        itemName: itemName,
        itemTerm: itemTerm,
        rewardTypeLabel: rewardTypeLabel,
        description: itemDescription,
        totalXp: totalXp,
        level: xpLevel,
        xpToNext: xpToNext,
        storyLabel: learnMoreLabel,
        onStory: onLearnMore,
        actionLabel: continueLabel,
        onAction: onContinue,
      );
    }
    final t = AppL10n.of(context);
    final surfaces = SoriSurfaces.of(context);
    final text = SoriTextTheme.of(context);
    final showXp = totalXp != null && xpLevel != null && xpToNext != null;
    final xpInLevel = showXp ? 100 - xpToNext! : 0;
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          rewardTypeLabel,
          style: text.eyebrow.copyWith(color: SoriColors.goldOnLight),
        ),
        const SizedBox(height: Spacing.xs),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(itemName, style: text.h1),
        ),
        const SizedBox(height: Spacing.xs),
        if (itemTerm != null)
          Text(
            itemTerm!,
            style: text.meta.copyWith(color: SoriColors.goldOnLight),
          ),
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReceiptReveal(second: second, start: 2.18, child: heading),
        if (itemDescription != null) ...[
          const SizedBox(height: Spacing.md),
          _ReceiptReveal(
            second: second,
            start: 2.30,
            child: Text(itemDescription!, style: text.bodySmall),
          ),
        ],
        if (onLearnMore != null) ...[
          const SizedBox(height: Spacing.xs),
          _ReceiptReveal(
            second: second,
            start: 2.38,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SoriButton.ghost(
                label: learnMoreLabel,
                icon: Icons.auto_stories_outlined,
                size: SoriButtonSize.sm,
                onTap: onLearnMore,
              ),
            ),
          ),
        ],
        if (showXp) ...[
          const SizedBox(height: Spacing.sm),
          _ReceiptReveal(
            second: second,
            start: 2.42,
            child: SoriCard(
              variant: SoriCardVariant.compact,
              accent: SoriColors.gold,
              tinted: true,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 20,
                        color: SoriColors.goldOnLight,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Text(
                          t.rewardChestLearningXp,
                          style: text.label.copyWith(color: surfaces.textMuted),
                        ),
                      ),
                      Text(
                        '${NumberFormat.decimalPattern(t.localeName).format(totalXp)} ${t.statsXp}',
                        style: text.h3.copyWith(
                          color: SoriColors.goldOnLight,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.md),
                  ClipRRect(
                    borderRadius: SoriRadius.brSm,
                    child: LinearProgressIndicator(
                      value: (xpInLevel / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      color: SoriColors.gold,
                      backgroundColor: surfaces.surfaceAlt,
                      semanticsLabel: t.rewardChestLearningXp,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Row(
                    children: [
                      Text(
                        t.statsLevelLabel(xpLevel!),
                        style: text.meta.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          t.statsToNextLevel(xpToNext!, xpLevel! + 1),
                          textAlign: TextAlign.end,
                          style: text.meta,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: Spacing.lg),
        _ReceiptReveal(
          second: second,
          start: 2.56,
          child: SoriButton(
            label: continueLabel,
            trailingIcon: Icons.arrow_forward_rounded,
            onTap: onContinue,
            fullWidth: true,
          ),
        ),
      ],
    );
  }
}

class _ReceiptViewport extends StatelessWidget {
  const _ReceiptViewport({required this.comparison, required this.child});
  final bool comparison;
  final Widget child;

  @override
  Widget build(BuildContext context) => comparison
      ? child
      : SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: child,
        );
}

class _ReceiptReveal extends StatelessWidget {
  const _ReceiptReveal({
    required this.second,
    required this.start,
    required this.child,
  });

  final double second;
  final double start;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final progress = _seg(second, start, start + 0.30, Curves.easeOutCubic);
    return ExcludeSemantics(
      excluding: progress < 1,
      child: Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - progress)),
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 이펙트 페인터
// ---------------------------------------------------------------------------

class _Dust {
  _Dust(math.Random random)
    : birth = 1.05 + random.nextDouble() * 1.0,
      life = 0.9 + random.nextDouble() * 0.55,
      dx = (random.nextDouble() * 2 - 1) * 0.30,
      rise = 0.20 + random.nextDouble() * 0.42,
      size = 0.45 + random.nextDouble() * 0.75,
      phase = random.nextDouble() * math.pi * 2;

  final double birth;
  final double life;
  final double dx;
  final double rise;
  final double size;
  final double phase;
}

class _Firefly {
  const _Firefly({
    required this.birth,
    required this.life,
    required this.dx,
    required this.rise,
    required this.color,
  });

  final double birth;
  final double life;
  final double dx;
  final double rise;
  final Color color;
}

// Seed once, not on every animation frame. The first wave leaves the mouth;
// the second is released at its crown, then drifts down with drag and gravity.
class _FxParticle {
  _FxParticle(math.Random random, {required bool petal})
    : crown = random.nextDouble() < 0.65,
      birth = 1.04 + random.nextDouble() * 0.46,
      life =
          (petal ? 1.50 : 1.32) + random.nextDouble() * 0.40 - _exitLeadSeconds,
      spawnX = (random.nextDouble() * 2 - 1) * 0.34,
      spawnY = -0.32 - random.nextDouble() * 0.32,
      vx = (random.nextDouble() * 2 - 1) * 0.68,
      vy = -0.20 - random.nextDouble() * 0.48,
      spin = (random.nextDouble() * 2 - 1) * 1.2,
      phase = random.nextDouble() * math.pi * 2,
      length = petal
          ? 0.022 + random.nextDouble() * 0.016
          : 0.005 + random.nextDouble() * 0.013,
      colorIndex = random.nextInt(4);

  final bool crown;
  final double birth, life, spawnX, spawnY, vx, vy, spin, phase, length;
  final int colorIndex;

  Offset position(Offset origin, double width, double age) {
    final travel = (1 - math.exp(-1.8 * age)) / 1.8;
    return origin +
        Offset(
              (crown ? spawnX : spawnX * 0.20) +
                  vx * travel +
                  math.sin(age * 3 + phase) * 0.030 * age,
              (crown ? spawnY : 0) +
                  (crown ? vy : vy * 1.65) * travel +
                  0.24 * age * age,
            ) *
            width;
  }
}

class _BackFxPainter extends CustomPainter {
  _BackFxPainter({
    required this.s,
    required this.origin,
    required this.itemCenter,
    required this.itemSize,
    required this.chestW,
    required this.clearTextY,
  });

  final double s;
  final Offset origin;
  final Offset itemCenter;
  final double itemSize;
  final double chestW;
  final double clearTextY;

  static const _gold = Color(0xFFE2B157);
  static const _fireflies = <_Firefly>[
    _Firefly(
      birth: 1.68,
      life: 0.92,
      dx: -0.24,
      rise: 0.46,
      color: Color(0xFFFFD98A),
    ),
    _Firefly(
      birth: 1.82,
      life: 0.96,
      dx: 0.20,
      rise: 0.54,
      color: Color(0xFFFFB6E1),
    ),
    _Firefly(
      birth: 1.98,
      life: 0.94,
      dx: -0.08,
      rise: 0.63,
      color: Color(0xFFC3A6FF),
    ),
    _Firefly(
      birth: 2.14,
      life: 0.88,
      dx: 0.08,
      rise: 0.48,
      color: Color(0xFF8CF2E4),
    ),
    _Firefly(
      birth: 2.28,
      life: 0.82,
      dx: 0.28,
      rise: 0.58,
      color: Color(0xFFEAF2FF),
    ),
  ];
  static final _dust = List<_Dust>.generate(
    42,
    (index) => _Dust(math.Random(index * 7919 + 13)),
  );
  static final _petals = List<_FxParticle>.generate(
    30,
    (index) => _FxParticle(math.Random(7001 + index * 101), petal: true),
  );
  static final _shards = List<_FxParticle>.generate(
    60,
    (index) => _FxParticle(math.Random(41 + index * 313), petal: false),
  );

  @override
  void paint(Canvas canvas, Size size) {
    _ambientGlow(canvas);
    _preOpenCharge(canvas);
    _lightPillar(canvas);
    _aurora(canvas);
    _openingBurst(canvas);
    _auroraPetals(canvas);
    _goldShards(canvas);
    _fireflyLayer(canvas);
    _dustLayer(canvas);
    _rewardBloom(canvas, size);
    _itemHalo(canvas);
  }

  void _ambientGlow(Canvas canvas) {
    final inPhase = _seg(s, 0.08, 1.0, Curves.easeOut);
    final settle =
        1 -
        0.72 *
            _seg(
              s,
              2.05 - _exitLeadSeconds,
              3.0 - _exitLeadSeconds,
              Curves.easeInOut,
            );
    final chestOut =
        1 - _seg(s, 1.95 - _exitLeadSeconds, 2.48 - _exitLeadSeconds);
    // Let cool mother-of-pearl light lead; retain the original opening peak.
    final warmHandoff = _seg(s, 0.74, 1.0, Curves.easeInOutCubic);
    final alpha = inPhase * settle * chestOut * warmHandoff;
    if (alpha <= 0) {
      return;
    }
    final center = origin.translate(0, -chestW * 0.10);
    final radius = chestW * 0.70;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..blendMode = BlendMode.srcOver
        ..shader = RadialGradient(
          colors: [_a(_gold, 0.36 * alpha), _a(_gold, 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  void _preOpenCharge(Canvas canvas) {
    final grow = _seg(s, 0.74, 1.02, Curves.easeInCubic);
    final fade = 1 - _seg(s, 1.04, 1.30, Curves.easeOut);
    final alpha = grow * fade;
    if (alpha <= 0) {
      return;
    }

    final center = origin.translate(0, -chestW * 0.03);
    final radius = chestW * (0.28 + 0.30 * grow);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..blendMode = BlendMode.srcOver
        ..shader = RadialGradient(
          colors: [
            _a(const Color(0xFFFFE6A6), 0.64 * alpha),
            _a(_gold, 0.32 * alpha),
            _a(_gold, 0),
          ],
          stops: const [0, 0.34, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  void _lightPillar(Canvas canvas) {
    final alpha =
        _seg(s, 1.0, 1.28, Curves.easeOut) *
        (1 -
            _seg(
              s,
              1.88 - _exitLeadSeconds,
              2.40 - _exitLeadSeconds,
              Curves.easeIn,
            ));
    if (alpha <= 0) {
      return;
    }
    // Elliptical light has no ruler-straight cone edges.
    canvas.save();
    canvas.translate(origin.dx - chestW * 0.04, origin.dy - chestW * 0.36);
    canvas.scale(1.08, 1.32);
    final radius = chestW * 0.40;
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [_a(_gold, 0.34 * alpha), _a(_gold, 0)],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius)),
    );
    canvas.restore();
  }

  void _aurora(Canvas canvas) {
    final alpha =
        _seg(s, 0.30, 1.30, Curves.easeOut) *
        _seg(s, 0.78, 1.02, Curves.easeInOutCubic) *
        (1 -
            _seg(
              s,
              1.88 - _exitLeadSeconds,
              2.42 - _exitLeadSeconds,
              Curves.easeIn,
            ));
    if (alpha <= 0) {
      return;
    }
    const colors = [
      Color(0xFFFFB6E1),
      Color(0xFFC3A6FF),
      Color(0xFF8CF2E4),
      Color(0xFFEAF2FF),
      Color(0xFFFFD98A),
    ];
    for (var i = 0; i < colors.length; i++) {
      final center = Offset(
        origin.dx + (i - 2) * chestW * 0.105,
        origin.dy - chestW * (0.20 + (i.isEven ? 0.05 : 0.10)),
      );
      final radius = chestW * 0.13;
      final rect = Rect.fromCircle(center: Offset.zero, radius: radius);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(1.0, 1.75);
      canvas.drawCircle(
        Offset.zero,
        radius,
        Paint()
          ..blendMode = BlendMode.srcOver
          ..shader = RadialGradient(
            colors: [_a(colors[i], 0.13 * alpha), _a(colors[i], 0)],
          ).createShader(rect),
      );
      canvas.restore();
    }
  }

  void _openingBurst(Canvas canvas) {
    // Uneven filaments rise to a broad crown, curl outwards, then cascade.
    // Travelling sections avoid both straight rays and a uniform radial star.
    const ends = <Offset>[
      Offset(-0.72, -0.10),
      Offset(-0.58, -0.30),
      Offset(-0.37, -0.45),
      Offset(-0.15, -0.48),
      Offset(0.14, -0.40),
      Offset(0.38, -0.35),
      Offset(0.62, -0.20),
      Offset(0.76, -0.04),
      Offset(-0.80, 0.08),
    ];
    for (var i = 0; i < ends.length; i++) {
      final p = _seg(s, 1.00 + i * 0.018, 1.98 + i * 0.022);
      if (p <= 0 || p >= 1) {
        continue;
      }
      final end = ends[i] * chestW;
      final path = Path()
        ..moveTo(origin.dx, origin.dy)
        ..cubicTo(
          origin.dx + end.dx * 0.12,
          origin.dy - chestW * (0.70 + (i % 3) * 0.06),
          origin.dx + end.dx * 0.90,
          origin.dy - chestW * (0.76 + (i % 2) * 0.10),
          origin.dx + end.dx,
          origin.dy + end.dy,
        );
      final metric = path.computeMetrics().first;
      final head = Curves.easeOutCubic.transform(p);
      final tail = math.max(0.0, head - 0.28 * math.sin(p * math.pi));
      final section = metric.extractPath(
        metric.length * tail,
        metric.length * head,
      );
      final alpha = math.sin(p * math.pi) * 0.76;
      canvas.drawPath(
        section,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 5
          ..color = _a(_gold, alpha * 0.40)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawPath(
        section,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = i.isEven ? 1.1 : 0.7
          ..shader = LinearGradient(
            colors: [
              _a(_gold, 0),
              _a(const Color(0xFFC89A3B), alpha),
              _a(_gold, 0),
            ],
            stops: const [0, 0.55, 1],
          ).createShader(path.getBounds()),
      );
    }
    for (var i = 0; i < 2; i++) {
      final p = _seg(s, 1.0 + i * 0.08, 1.78 + i * 0.12);
      if (p <= 0 || p >= 1) {
        continue;
      }
      final radius = chestW * (0.12 + 0.60 * Curves.easeOutCubic.transform(p));
      canvas.drawArc(
        Rect.fromCenter(
          center: origin.translate(i == 0 ? -10 : 12, -chestW * 0.08),
          width: radius * 2,
          height: radius * 1.08,
        ),
        i == 0 ? -math.pi * 0.91 : -math.pi * 0.26,
        math.pi * (i == 0 ? 0.64 : 0.42),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = _a(_gold, math.sin(p * math.pi) * 0.42)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
      );
    }
  }

  void _auroraPetals(Canvas canvas) {
    const colors = <Color>[
      Color(0xFFDB98A7),
      Color(0xFFB7A8CF),
      Color(0xFF8DB8AD),
      Color(0xFFF3DDB9),
    ];
    for (final petal in _petals) {
      final age = s - petal.birth;
      final p = age / petal.life;
      if (p <= 0 || p >= 1) {
        continue;
      }
      final position = petal.position(origin, chestW * 1.32, age);
      final length = chestW * petal.length;
      final alpha =
          _seg(p, 0, 0.10, Curves.easeOut) *
          (1 - _seg(p, 0.72, 1, Curves.easeInOut)) *
          _textClearance(position) *
          0.88;
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(petal.phase + petal.spin * age);
      canvas.scale(0.58 + 0.42 * math.cos(age * 3 + petal.phase).abs(), 1);
      // Curled, asymmetric petal based on the user's storyboard. One side
      // folds inward; the cream edge catches light as the petal tumbles.
      final path = Path()
        ..moveTo(-length * 0.86, length * 0.25)
        ..cubicTo(
          -length * 0.42,
          -length * 0.85,
          length * 0.58,
          -length * 0.80,
          length * 0.95,
          -length * 0.24,
        )
        ..cubicTo(
          length * 0.38,
          length * 0.12,
          length * 0.26,
          length * 0.90,
          -length * 0.86,
          length * 0.25,
        )
        ..close();
      final rect = Rect.fromLTWH(-length, -length, length * 2, length * 2);
      canvas.drawPath(
        path,
        Paint()
          ..color = _a(colors[petal.colorIndex], alpha * 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _a(const Color(0xFFFFF1D3), alpha),
              _a(colors[petal.colorIndex], alpha),
              _a(const Color(0xFFF1D6AE), alpha * 0.75),
            ],
            stops: const [0, 0.48, 1],
          ).createShader(rect),
      );
      final fold = Path()
        ..moveTo(-length * 0.64, length * 0.18)
        ..quadraticBezierTo(0, -length * 0.28, length * 0.70, -length * 0.16);
      canvas.drawPath(
        fold,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6
          ..color = _a(const Color(0xFFFFF3DA), alpha * 0.72),
      );
      canvas.restore();
    }
  }

  void _goldShards(Canvas canvas) {
    for (final shard in _shards) {
      final age = s - shard.birth;
      final p = age / shard.life;
      if (p <= 0 || p >= 1) {
        continue;
      }
      final position = shard.position(origin, chestW * 1.38, age);
      final length = chestW * shard.length;
      final alpha =
          _seg(p, 0, 0.08, Curves.easeOut) *
          (1 - _seg(p, 0.68, 1, Curves.easeInOut)) *
          _textClearance(position) *
          0.86;
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(shard.phase + shard.spin * age);
      final shape = Path()
        ..moveTo(-length * 0.32, -length * 0.50)
        ..lineTo(length * 0.24, -length * 0.34)
        ..lineTo(length * 0.14, length * 0.62)
        ..lineTo(-length * 0.22, length * 0.36)
        ..close();
      canvas.drawPath(
        shape,
        Paint()
          ..shader =
              LinearGradient(
                colors: [
                  _a(const Color(0xFFFFEDB8), alpha),
                  _a(const Color(0xFFBE8D32), alpha),
                ],
              ).createShader(
                Rect.fromLTWH(-length, -length, length * 2, length * 2),
              ),
      );
      canvas.restore();
    }
  }

  void _rewardBloom(Canvas canvas, Size size) {
    final p = _seg(s, 1.00, 1.60, Curves.easeOutCubic);
    final alpha =
        p *
        (1 -
            _seg(
              s,
              1.90 - _exitLeadSeconds,
              2.62 - _exitLeadSeconds,
              Curves.easeInOut,
            ));
    if (alpha <= 0) {
      return;
    }
    final maxRadius = chestW * 1.20;
    final radius = math.max(1.0, maxRadius * p);
    final center = origin.translate(0, -chestW * 0.34 * p);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..blendMode = BlendMode.srcOver
        ..shader = RadialGradient(
          colors: [
            _a(const Color(0xFFFFEBC3), 0.46 * alpha),
            _a(_gold, 0.22 * alpha),
            _a(_gold, 0),
          ],
          stops: const [0, 0.26, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  // Let the cascade finish above the hero while softly clearing the reading
  // area. A spatial fade, rather than killing every particle on the same beat.
  double _textClearance(Offset position) =>
      1 -
      _seg(
            s,
            2.18 - _exitLeadSeconds,
            2.60 - _exitLeadSeconds,
            Curves.easeInOut,
          ) *
          _seg(position.dy, clearTextY - 40, clearTextY + 32);

  void _fireflyLayer(Canvas canvas) {
    for (var i = 0; i < _fireflies.length; i++) {
      final firefly = _fireflies[i];
      final p = ((s - (firefly.birth - _exitLeadSeconds)) / firefly.life).clamp(
        0.0,
        1.0,
      );
      if (p <= 0 || p >= 1) {
        continue;
      }
      final eased = Curves.easeOutCubic.transform(p);
      final position = Offset(
        origin.dx + firefly.dx * chestW + math.sin(p * math.pi * 2 + i) * 3.5,
        origin.dy - chestW * (0.05 + firefly.rise * eased),
      );
      final alpha =
          math.sin(p * math.pi) *
          0.78 *
          (1 - _seg(s, 2.12 - _exitLeadSeconds, 2.58 - _exitLeadSeconds));
      canvas.drawCircle(
        position,
        7,
        Paint()
          ..blendMode = BlendMode.srcOver
          ..color = _a(firefly.color, alpha * 0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        position,
        1.4,
        Paint()
          ..blendMode = BlendMode.srcOver
          ..color = _a(firefly.color, alpha),
      );
    }
  }

  void _dustLayer(Canvas canvas) {
    for (final dust in _dust) {
      final p = ((s - dust.birth) / dust.life).clamp(0.0, 1.0);
      if (p <= 0 || p >= 1) {
        continue;
      }
      final eased = Curves.easeOutCubic.transform(p);
      final position = Offset(
        origin.dx + dust.dx * chestW + math.sin(p * 4 + dust.phase) * 2.2,
        origin.dy - dust.rise * chestW * eased,
      );
      final alpha =
          math.sin(p * math.pi) *
          0.56 *
          (1 - _seg(s, 2.12 - _exitLeadSeconds, 2.58 - _exitLeadSeconds));
      canvas.drawCircle(
        position,
        dust.size,
        Paint()
          ..blendMode = BlendMode.srcOver
          ..color = _a(_gold, alpha),
      );
    }
  }

  void _itemHalo(Canvas canvas) {
    final alpha =
        _seg(s, 1.12, 1.46, Curves.easeOut) *
        (1 -
            0.80 *
                _seg(
                  s,
                  1.88 - _exitLeadSeconds,
                  2.70 - _exitLeadSeconds,
                  Curves.easeInOut,
                ));
    if (alpha <= 0) {
      return;
    }
    final radius = itemSize * 0.60;
    canvas.drawCircle(
      itemCenter,
      radius,
      Paint()
        ..blendMode = BlendMode.srcOver
        ..shader = RadialGradient(
          colors: [_a(_gold, 0.20 * alpha), _a(_gold, 0)],
        ).createShader(Rect.fromCircle(center: itemCenter, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant _BackFxPainter oldDelegate) =>
      oldDelegate.s != s ||
      oldDelegate.origin != origin ||
      oldDelegate.itemCenter != itemCenter ||
      oldDelegate.itemSize != itemSize ||
      oldDelegate.chestW != chestW ||
      oldDelegate.clearTextY != clearTextY;
}
