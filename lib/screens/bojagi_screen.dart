import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/decoration_reward_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/cultural_help.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/motion.dart';
import '../widgets/sori/placed_decoration.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/sori_term.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';

const String kBojagiClosed =
    'assets/illustrations/reward/reward_bojagi_closed.png';
const String kBojagiOpen = 'assets/illustrations/reward/reward_bojagi_open.png';

/// 보자기 꾸러미 개봉 — 퀘스트 보상으로 받은 꾸러미를 열어 장식 하나를 고른다.
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

  /// 매듭을 풀었는가. 후보를 바로 보여주지 않는 이유는 ADR-002 개정 그대로 —
  /// 싸여 있다는 것 자체가 물음표라 여는 동작이 보상의 일부다.
  bool _untied = false;

  /// 방금 수령한 장식. 있으면 축하 화면.
  String? _claimed;

  /// 수령 직후 확인한 다음 꾸러미. 선택 가능하거나 전체 수집 보관이 필요한 경우에만
  /// "다음 꾸러미"를 띄운다.
  bool _hasNext = false;

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
    setState(() {
      _loading = true;
      _loadFailed = false;
      _claimed = null;
      _untied = false;
      _hasNext = false;
    });
    try {
      final offer = await _loadOffer();
      if (!mounted) {
        return;
      }
      setState(() {
        _offer = offer;
        _loading = false;
      });
    } on Object {
      _showLoadFailure();
    }
  }

  Future<void> _claim(String slug) async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    late final DecorationRewardClaimResult result;
    try {
      result = await DecorationRewardService.claimNextBox(slug);
    } on Object {
      _showLoadFailure();
      return;
    }
    if (!mounted) {
      return;
    }
    if (result != DecorationRewardClaimResult.claimed) {
      // 성공이 아니면 상태를 추측하지 않는다 — 서비스에서 다시 읽는다.
      // (다른 기기에서 이미 열었거나 큐가 바뀐 경우가 여기로 온다.)
      await _load();
      return;
    }

    // 수령 성공은 먼저 보존한다. 다음 꾸러미 확인이 실패하더라도 이미 받은 장식을
    // 오류 화면 뒤에 숨기거나 다시 고르게 하지 않는다.
    try {
      final next = await _loadOffer();
      if (!mounted) {
        return;
      }
      setState(() {
        _claimed = slug;
        _offer = next;
        _hasNext =
            next.state == DecorationRewardOfferState.ready ||
            next.state == DecorationRewardOfferState.collectionComplete;
        _loading = false;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _claimed = slug;
        _hasNext = false;
        _loading = false;
      });
    }
  }

  Future<void> _archiveCompleteCollection() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final result =
          await DecorationRewardService.archiveCompleteCollectionBox();
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
      appBarTitle: t.bojagiTitle,
      maxWidth: SoriMaxWidth.prose,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.md,
      ),
      actions: const [CulturalHelpButton(termId: 'bojagi')],
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
              child: Center(child: _body(t)),
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
        label: t.bojagiLoading,
        excludeSemantics: true,
        child: AppLoading(message: t.bojagiLoading),
      );
    }
    final claimed = _claimed;
    if (claimed != null) {
      return _ClaimedView(slug: claimed, hasNext: _hasNext, onNext: _load);
    }

    final offer = _offer;
    if (_loadFailed || offer == null) {
      return AppError(
        message: t.bojagiProblemBody,
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
        asset: kBojagiClosed,
        icon: Icons.card_giftcard_rounded,
        title: t.bojagiEmptyTitle,
        body: t.bojagiEmptyBody,
      ),
      DecorationRewardOfferState.noEligibleCandidates => SoriEmptyState(
        asset: kBojagiOpen,
        icon: Icons.inventory_2_outlined,
        title: t.bojagiAllOwnedTitle,
        body: t.bojagiAllOwnedBody,
      ),
      DecorationRewardOfferState.collectionComplete => SoriEmptyState(
        asset: kBojagiOpen,
        icon: Icons.collections_bookmark_outlined,
        title: t.bojagiCollectionCompleteTitle,
        body: t.bojagiCollectionCompleteBody,
        ctaLabel: t.bojagiArchiveComplete,
        onCta: _archiveCompleteCollection,
      ),
      DecorationRewardOfferState.unknownQuest ||
      DecorationRewardOfferState.recoveryConflict => SoriEmptyState(
        icon: Icons.refresh_rounded,
        title: t.bojagiProblemTitle,
        body: t.bojagiProblemBody,
        ctaLabel: t.bojagiRetry,
        onCta: _load,
      ),
    };
  }
}

/// 매듭이 묶인 상태 — 탭 하나로 연다. 물음표를 그릴 필요가 없다,
/// 싸여 있다는 것 자체가 물음표다 (ADR-002 개정).
class _KnotView extends StatelessWidget {
  final VoidCallback onUntie;

  const _KnotView({required this.onUntie});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    return SoriEntrance(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            container: true,
            button: true,
            enabled: true,
            label: t.bojagiOpenHint,
            onTap: onUntie,
            excludeSemantics: true,
            child: SoriPressable(
              // 테스트에서 매듭만 정확히 누르기 위한 앵커.
              key: const Key('bojagi_knot'),
              onTap: onUntie,
              haptic: SoriHaptic.medium,
              child: SizedBox(
                width: 220,
                height: 220,
                child: Image.asset(
                  kBojagiClosed,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.card_giftcard_rounded,
                    size: 120,
                    color: SoriColors.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.xl),
          ExcludeSemantics(
            child: Text(
              t.bojagiOpenHint,
              textAlign: TextAlign.center,
              style: text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// 매듭이 풀린 뒤 — 후보 카드. 안 고른 것은 사라지지 않는다는 안내가
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
            kBojagiOpen,
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
          t.bojagiPickBody,
          textAlign: TextAlign.center,
          style: text.bodySmall,
        ),
        const SizedBox(height: Spacing.xl),
        CulturalGlossaryBuilder(
          builder: (context, glossary) {
            final shownTermIds = <String>{};
            final cards = <Widget>[];
            for (var i = 0; i < candidates.length; i++) {
              final slug = candidates[i];
              final termId = glossary?.termIdForDecoration(slug);
              cards.add(
                SoriEntrance(
                  delay: Duration(milliseconds: 90 * i),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.md),
                    child: _CandidateCard(
                      slug: slug,
                      culturalTermId: termId,
                      showCulturalHelp:
                          termId != null && shownTermIds.add(termId),
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
  final String? culturalTermId;

  const _CandidateCard({
    required this.slug,
    required this.onTap,
    required this.showCulturalHelp,
    this.culturalTermId,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final text = SoriTextTheme.of(context);
    final name = decorName(t, slug);
    final term = decorTerm(t, slug);
    final termId = culturalTermId;
    // §W-C C3: the inline term line sits OUTSIDE the pick-tap Semantics/
    // SoriPressable below, as a sibling — same reason the "?" help button
    // is a sibling rather than nested inside it. Two independent
    // GestureDetectors sharing one tap point would both fire, so a tap
    // meant for "open the glossary" would also silently pick the candidate.
    final showTerm = termId != null && term != name;
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
                        Spacing.lg,
                        Spacing.lg,
                        showCulturalHelp ? Spacing.sm : Spacing.lg,
                        showTerm ? Spacing.xs : Spacing.lg,
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
                          const SizedBox(width: Spacing.lg),
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
                  child: CulturalDecorationHelpButton(decorationSlug: slug),
                ),
            ],
          ),
          if (showTerm)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 64 + Spacing.lg + Spacing.lg,
                end: Spacing.lg,
                bottom: Spacing.sm,
              ),
              child: SoriTerm(
                termId: termId,
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

  const _ClaimedView({
    required this.slug,
    required this.hasNext,
    required this.onNext,
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
            SizedBox(
              height: 180,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SoriDecorationImage(slug: slug, size: 170),
              ),
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
              onTap: () =>
                  Navigator.of(context).pushNamed('/sarangbang/furnish'),
            ),
            if (hasNext) ...[
              const SizedBox(height: Spacing.sm),
              SoriButton(
                label: t.bojagiNext,
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
