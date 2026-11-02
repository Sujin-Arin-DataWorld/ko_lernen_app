import 'package:flutter/material.dart';
import '../widgets/sori/dialog.dart';
import 'package:url_launcher/link.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/cultural_glossary.dart';
import '../services/decoration_reward_service.dart';
import '../services/haptic_service.dart';
import '../services/learning_journey.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/bojagi_reveal.dart';
import '../widgets/sori/c_gallery/c_materials.dart';
import '../widgets/sori/cultural_help.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/motion.dart';
import '../widgets/sori/placed_decoration.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/sori_term.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';

export '../widgets/sori/bojagi_reveal.dart'
    show kBojagiClosed, kBojagiOpen, kNajeonChestClosed, kNajeonChestOpen;

/// 자개함 개봉 — 기존 보상 큐에서 함을 열어 장식 하나를 고른다.
///
/// **이 화면은 저장소를 직접 건드리지 않는다.** 소유권·큐 소비·journal 복구는
/// 전부 [DecorationRewardService] 가 한다. 화면이 `Storage.addOwnedDecor` 를
/// 직접 부르면 중간에 앱이 죽었을 때 큐와 보유 목록이 어긋난다.
class BojagiScreen extends StatefulWidget {
  const BojagiScreen({super.key, this.offerLoader});

  /// 화면 상태 검증용 주입 지점. 런타임에서는 보상 서비스가 유일한 소유자다.
  final Future<DecorationRewardOffer> Function()? offerLoader;

  @override
  State<BojagiScreen> createState() => _BojagiScreenState();
}

class _BojagiScreenState extends State<BojagiScreen> {
  bool _loading = true;
  bool _loadFailed = false;
  DecorationRewardOffer? _offer;

  /// 함을 열었는가. 개봉은 후보를 보여주며 소유권은 선택 후 서비스가 확정한다.
  bool _untied = false;

  /// 방금 수령한 장식. 있으면 축하 화면.
  String? _claimed;

  /// 수령 직후 확인한 다음 꾸러미. 선택 가능하거나 전체 수집 보관이 필요한 경우에만
  /// "다음 꾸러미"를 띄운다.
  bool _hasNext = false;
  int _offerGeneration = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 중단된 수령 복구까지 [DecorationRewardService.loadNextOffer] 안에서
  /// 처리된다. 그래서 진입·재시도 모두 이 한 번의 호출로 충분하다.
  Future<DecorationRewardOffer> _loadOffer() =>
      widget.offerLoader?.call() ?? DecorationRewardService.loadNextOffer();

  Future<void> _load() async {
    final generation = ++_offerGeneration;
    setState(() {
      _loading = true;
      _loadFailed = false;
      _claimed = null;
      _untied = false;
      _hasNext = false;
    });
    try {
      final offer = await _loadOffer();
      if (!mounted || generation != _offerGeneration) {
        return;
      }
      setState(() {
        _offer = offer;
        _loading = false;
      });
    } on Object {
      if (generation == _offerGeneration) _showLoadFailure();
    }
  }

  Future<void> _claim(String slug) async {
    final offer = _offer;
    if (_loading ||
        _claimed != null ||
        offer?.state != DecorationRewardOfferState.ready ||
        !offer!.candidates.contains(slug)) {
      return;
    }
    final generation = ++_offerGeneration;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    late final DecorationRewardClaimResult result;
    try {
      result = await DecorationRewardService.claimNextBox(
        slug,
        expectedSourceQuestId: offer.sourceQuestId,
      );
    } on Object {
      _showLoadFailure();
      return;
    }
    if (!mounted || generation != _offerGeneration) {
      return;
    }
    if (result != DecorationRewardClaimResult.claimed) {
      // 성공이 아니면 상태를 추측하지 않는다 — 서비스에서 다시 읽는다.
      // (다른 기기에서 이미 열었거나 큐가 바뀐 경우가 여기로 온다.)
      await _load();
      return;
    }

    // Confirmed ownership is shown immediately. A slow next-offer read must
    // never hide the received item behind a spinner or offer it twice.
    setState(() {
      _claimed = slug;
      _hasNext = false;
      _loading = false;
    });
    try {
      final next = await _loadOffer();
      if (!mounted || generation != _offerGeneration) {
        return;
      }
      setState(() {
        _offer = next;
        _hasNext =
            next.state == DecorationRewardOfferState.ready ||
            next.state == DecorationRewardOfferState.collectionComplete;
      });
    } on Object {
      // The successful receipt and room entrance remain available.
    }
  }

  Future<void> _archiveCompleteCollection() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final result = await DecorationRewardService.archiveCompleteCollectionBox(
        expectedSourceQuestId: _offer?.sourceQuestId,
      );
      if (!mounted) {
        return;
      }
      if (result != DecorationRewardClaimResult.collectionArchived) {
        // 큐나 보유 목록이 다른 경로에서 바뀌었을 수 있으므로, 성공 외에는 화면이
        // 상태를 추측하지 않는다.
        await _load();
        return;
      }
      await _load();
    } on Object {
      _showLoadFailure();
    }
  }

  void _showLoadFailure() {
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
      _loadFailed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriStandardFrame(
      appBarTitle: t.najeonChestTitle,
      maxWidth: SoriMaxWidth.prose,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.md,
      ),
      actions: [
        IconButton(
          key: const ValueKey('najeon-chest-help'),
          tooltip: t.culturalHelpSemantics(t.najeonChestHelpTitle),
          onPressed: _showNajeonHelp,
          icon: const Icon(Icons.help_outline_rounded),
        ),
      ],
      builder: (context, resolvedPadding) => LayoutBuilder(
        builder: (context, constraints) {
          final contentHeight =
              (constraints.maxHeight - resolvedPadding.vertical)
                  .clamp(0.0, double.infinity)
                  .toDouble();
          return SingleChildScrollView(
            key: const ValueKey('bojagi-scroll'),
            padding: resolvedPadding,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: contentHeight),
              child: CPaperPanel(
                padding: const EdgeInsets.all(Spacing.lg),
                radius: SoriRadius.lg,
                surfaceTexture: const CTexture(CMaterial.paper),
                child: Theme(
                  // The hanji surface stays light even in the dark app shell.
                  // Keep the inherited font metrics and use readable C ink.
                  data: Theme.of(context).copyWith(
                    brightness: Brightness.light,
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                      brightness: Brightness.light,
                      surface: CPalette.paper,
                      onSurface: CPalette.ink,
                      primary: CPalette.jade,
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (contentHeight - Spacing.lg * 2 - 2)
                          .clamp(0.0, double.infinity)
                          .toDouble(),
                    ),
                    child: Center(child: _body(t)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _body(AppL10n t) {
    if (_loading) {
      return Semantics(
        liveRegion: true,
        label: t.najeonChestLoading,
        excludeSemantics: true,
        child: AppLoading(message: t.najeonChestLoading),
      );
    }
    final claimed = _claimed;
    if (claimed != null) {
      return _ClaimedView(
        slug: claimed,
        hasNext: _hasNext,
        onNext: _load,
        onRoom: _goToRoom,
        onHome: _goHome,
      );
    }

    final offer = _offer;
    if (_loadFailed || offer == null) {
      return AppError(
        message: t.najeonChestProblemBody,
        messageLiveRegion: true,
        retryLabel: t.bojagiRetry,
        onRetry: _load,
      );
    }

    return switch (offer.state) {
      DecorationRewardOfferState.ready =>
        _untied
            ? _PickView(candidates: offer.candidates, onPick: _claim)
            : _KnotView(onUntie: () => setState(() => _untied = true)),
      DecorationRewardOfferState.noPendingBox => SoriEmptyState(
        asset: kNajeonChestClosed,
        icon: Icons.card_giftcard_rounded,
        title: t.najeonChestEmptyTitle,
        body: t.najeonChestEmptyBody,
      ),
      DecorationRewardOfferState.noEligibleCandidates => SoriEmptyState(
        asset: kNajeonChestOpen,
        icon: Icons.inventory_2_outlined,
        title: t.bojagiAllOwnedTitle,
        body: t.najeonChestAllOwnedBody,
      ),
      DecorationRewardOfferState.collectionComplete => SoriEmptyState(
        asset: kNajeonChestOpen,
        icon: Icons.collections_bookmark_outlined,
        title: t.bojagiCollectionCompleteTitle,
        body: t.najeonChestCollectionCompleteBody,
        ctaLabel: t.najeonChestArchive,
        onCta: _archiveCompleteCollection,
      ),
      DecorationRewardOfferState.unknownQuest ||
      DecorationRewardOfferState.recoveryConflict => SoriEmptyState(
        icon: Icons.refresh_rounded,
        title: t.najeonChestProblemTitle,
        body: t.najeonChestProblemBody,
        ctaLabel: t.bojagiRetry,
        onCta: _load,
      ),
    };
  }

  void _goToRoom() {
    final navigator = Navigator.of(context);
    if (ModalRoute.of(context)?.settings.arguments == 'furnish') {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed('/sarangbang/furnish');
    }
  }

  void _showNajeonHelp() {
    showSoriDialog<void>(
      context: context,
      builder: (context) {
        final t = AppL10n.of(context);
        return SoriDialog(
          title: Text(t.najeonChestHelpTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.najeonChestHelpBody),
              const SizedBox(height: Spacing.sm),
              Link(
                uri: Uri.parse(
                  'https://www.museum.go.kr/MUSEUM/contents/'
                  'M0502000000.do?relicId=1334&schM=view&searchId=search',
                ),
                target: LinkTarget.blank,
                builder: (context, followLink) => SoriButton.ghost(
                  onTap: followLink,
                  label: t.practiceDokkaebiMuseumSource,
                ),
              ),
            ],
          ),
          actions: [
            SoriButton.ghost(
              onTap: () => Navigator.of(context).pop(),
              label: t.btnClose,
            ),
          ],
        );
      },
    );
  }

  void _goHome() {
    if (LearningJourneyObserver.forContext(context)?.returnHome(context) ==
        true) {
      return;
    }
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil('/', (route) => false);
  }
}

/// 닫힌 함 — 개봉은 보상 소유권을 변경하지 않는다.
class _KnotView extends StatefulWidget {
  final VoidCallback onUntie;

  const _KnotView({required this.onUntie});

  @override
  State<_KnotView> createState() => _KnotViewState();
}

class _KnotViewState extends State<_KnotView> {
  bool _opening = false;

  void _open() {
    if (_opening) {
      return;
    }
    setState(() => _opening = true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriEntrance(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            container: true,
            button: true,
            enabled: !_opening,
            label: _opening ? t.najeonChestLoading : t.najeonChestOpenHint,
            onTap: _opening ? null : _open,
            excludeSemantics: true,
            child: SoriPressable(
              // 테스트에서 매듭만 정확히 누르기 위한 앵커.
              key: const Key('bojagi_knot'),
              onTap: _opening ? null : _open,
              haptic: SoriHaptic.selection,
              pressScale: .985,
              pressOffsetY: 2,
              releaseCurve: Curves.easeOutCubic,
              child: SoriBojagiReveal(
                opening: _opening,
                najeonChest: true,
                onOpened: widget.onUntie,
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
          SoriButton.filled(
            label: t.najeonChestOpen,
            accent: CPalette.jade,
            illustrationAsset: kNajeonChestClosed,
            trailingIcon: Icons.arrow_forward_rounded,
            onTap: _opening ? null : _open,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

/// 함을 연 뒤 — 후보 카드. 안 고른 것은 사라지지 않는다는 안내가
/// 본문에 있어야 한다. 선택이 벌처럼 느껴지면 수집 동기가 꺾인다.
class _PickView extends StatelessWidget {
  final List<String> candidates;
  final void Function(String slug) onPick;

  const _PickView({required this.candidates, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 92,
          child: Image.asset(
            kNajeonChestOpen,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: Spacing.md),
        Semantics(
          header: true,
          child: Text(
            t.bojagiPickTitle,
            textAlign: TextAlign.center,
            style: text.h2,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          t.najeonChestPickBody,
          textAlign: TextAlign.center,
          style: text.bodySmall,
        ),
        const SizedBox(height: Spacing.md),
        CulturalGlossaryBuilder(
          builder: (context, glossary) {
            final shownTermIds = <String>{};
            final cards = <Widget>[];
            for (var i = 0; i < candidates.length; i++) {
              final slug = candidates[i];
              final termId = glossary?.termIdForDecoration(slug);
              final culturalEntry = termId == null
                  ? null
                  : glossary?.entry(termId);
              cards.add(
                SoriEntrance(
                  delay: Duration(milliseconds: 90 * i),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.md),
                    child: _CandidateCard(
                      slug: slug,
                      culturalEntry: culturalEntry,
                      showCulturalHelp:
                          culturalEntry != null && shownTermIds.add(termId!),
                      onTap: () => onPick(slug),
                    ),
                  ),
                ),
              );
            }
            return Column(children: cards);
          },
        ),
      ],
    );
  }
}

/// 후보 한 장. 카드 톤은 `SoriCard` 규약(면 + 얇은 테두리 + md 라운드)을 따른다.
class _CandidateCard extends StatelessWidget {
  final String slug;
  final VoidCallback onTap;
  final bool showCulturalHelp;
  final CulturalGlossaryEntry? culturalEntry;

  const _CandidateCard({
    required this.slug,
    required this.onTap,
    required this.showCulturalHelp,
    this.culturalEntry,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final text = SoriTextTheme.of(context);
    final name = decorName(t, slug);
    final term = decorTerm(t, slug);
    final entry = culturalEntry;
    // §W-C C3: the inline term line sits OUTSIDE the pick-tap Semantics/
    // SoriPressable below, as a sibling — same reason the "?" help button
    // is a sibling rather than nested inside it. Two independent
    // GestureDetectors sharing one tap point would both fire, so a tap
    // meant for "open the glossary" would also silently pick the candidate.
    final showTerm = entry != null && term != name;
    return Container(
      key: ValueKey('bojagi-candidate-$slug'),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: SoriRadius.brMd,
        border: Border.all(
          color: s.brightness == Brightness.light
              ? SoriColors.lightBorderStrong
              : SoriColors.darkBorderStrong,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  container: true,
                  button: true,
                  enabled: true,
                  label: t.bojagiChooseDecoration(name),
                  onTap: onTap,
                  excludeSemantics: true,
                  child: SoriPressable(
                    onTap: onTap,
                    haptic: SoriHaptic.selection,
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        Spacing.md,
                        Spacing.md,
                        showCulturalHelp ? Spacing.sm : Spacing.md,
                        showTerm ? Spacing.xs : Spacing.md,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 64,
                            height: 64,
                            // 장식마다 세로 비율이 달라 폭만 주면 넘친다 — 시트와 같은 규약.
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: SoriDecorationImage(slug: slug, size: 58),
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Expanded(child: Text(name, style: text.cardTitle)),
                          Icon(Icons.chevron_right_rounded, color: s.textDim),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (showCulturalHelp)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: Spacing.sm),
                  child: CulturalTermHelpButton(entry: entry!),
                ),
            ],
          ),
          if (showTerm)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 64 + Spacing.md + Spacing.sm,
                end: Spacing.md,
                bottom: Spacing.sm,
              ),
              child: SoriTerm(
                termId: entry.termId,
                text: term,
                style: text.meta,
                surface: 'bojagi_candidate',
              ),
            ),
        ],
      ),
    );
  }
}

/// 수령 직후 — **무엇을 받았는지 크게** 보여주고 사랑방으로 보낸다.
///
/// `SoriEmptyState` 를 쓰지 않는 이유: 그건 `asset` 경로를 직접 받는데,
/// 장식은 화이트리스트에 없으면 로드 시도조차 하면 안 된다
/// ([SoriDecorationImage] 가 그 판단을 한다).
class _ClaimedView extends StatelessWidget {
  final String slug;
  final bool hasNext;
  final Future<void> Function() onNext;
  final VoidCallback onRoom;
  final VoidCallback onHome;

  const _ClaimedView({
    required this.slug,
    required this.hasNext,
    required this.onNext,
    required this.onRoom,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final name = decorName(t, slug);

    return SoriEntrance(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.xl,
          vertical: Spacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SoriBojagiReveal(
              key: ValueKey('bojagi-reveal-$slug'),
              rewardSlug: slug,
              najeonChest: true,
              onRewardRevealed: HapticService.lightImpact,
            ),
            const SizedBox(height: Spacing.lg),
            Semantics(
              header: true,
              liveRegion: true,
              label: t.bojagiClaimedAnnouncement(name),
              excludeSemantics: true,
              child: Text(
                t.bojagiClaimedTitle,
                textAlign: TextAlign.center,
                style: text.h2,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ExcludeSemantics(
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: text.bodySmall,
                    ),
                  ),
                ),
                CulturalDecorationHelpButton(decorationSlug: slug),
              ],
            ),
            const SizedBox(height: Spacing.xl),
            SoriButton(
              label: t.bojagiGoToRoom,
              accent: CPalette.jade,
              onTap: onRoom,
            ),
            const SizedBox(height: Spacing.sm),
            SoriButton(
              label: t.homeActionLabel,
              variant: SoriButtonVariant.outlined,
              onTap: onHome,
            ),
            if (hasNext) ...[
              const SizedBox(height: Spacing.sm),
              SoriButton(
                label: t.najeonChestNext,
                variant: SoriButtonVariant.outlined,
                onTap: onNext,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
