import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/guide_contract.dart';
import '../../services/analytics_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/sori/toast.dart';
import 'guide_progress_service.dart';
import 'guide_runtime.dart';
import 'today_guide_checklist_card.dart';

/// Self-contained optional Today surface. Closing it changes presentation
/// only; the permanent `/guide` hub and per-topic completion remain intact.
class TodayGuideChecklistSection extends StatefulWidget {
  const TodayGuideChecklistSection({super.key, this.progressService});

  final GuideProgressService? progressService;

  @override
  State<TodayGuideChecklistSection> createState() =>
      _TodayGuideChecklistSectionState();
}

class _TodayGuideChecklistSectionState
    extends State<TodayGuideChecklistSection> {
  GuideProgressSnapshot? _snapshot;
  final Set<GuideTopicId> _openingTopics = {};
  bool _dismissInFlight = false;
  String? _dismissedStatus;

  GuideProgressService get _service =>
      widget.progressService ?? GuideRuntime.progress;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final snapshot = await _service.load();
      if (mounted) {
        setState(() => _snapshot = snapshot);
      }
    } catch (_) {
      // A guide preference failure must never block Today's learning mission.
    }
  }

  Future<void> _dismiss() async {
    if (_dismissInFlight) {
      return;
    }
    _dismissInFlight = true;
    try {
      // The close control disappears after persistence. Move focus while its
      // traversal context is unquestionably still mounted; awaiting storage
      // first can cross a frame boundary and strand focus on the route scope.
      await _moveFocusPastSection();
      await _service.dismissTodayCard();
      unawaited(Analytics.guideTodayCardAction(GuideTodayCardAction.dismissed));
      if (mounted) {
        _dismissedStatus = AppL10n.of(context).todayGuideDismissedStatus;
      }
      await _load();
    } catch (_) {
      // A presentation preference failure must leave the guide available and
      // must not escape from the unawaited UI callback as an app-level error.
      if (mounted) {
        soriNotice(context, AppL10n.of(context).guidePreferenceWriteFailed);
      }
    } finally {
      _dismissInFlight = false;
    }
  }

  Future<void> _moveFocusPastSection() async {
    var focused = FocusManager.instance.primaryFocus;
    if (!_isInsideSection(focused)) {
      return;
    }
    for (var attempt = 0; attempt < 32; attempt++) {
      if (!(focused?.nextFocus() ?? false)) {
        return;
      }
      // requestFocus is committed in a microtask. Yield before reading the
      // primary node again; otherwise this loop repeatedly advances from the
      // same close control and only the first queued move wins.
      await Future<void>.delayed(Duration.zero);
      if (!mounted) {
        return;
      }
      focused = FocusManager.instance.primaryFocus;
      if (!_isInsideSection(focused)) {
        return;
      }
    }
  }

  bool _isInsideSection(FocusNode? node) {
    final candidate = node?.context;
    if (candidate == null) {
      return false;
    }
    if (identical(candidate, context)) {
      return true;
    }
    var found = false;
    candidate.visitAncestorElements((ancestor) {
      if (identical(ancestor, context)) {
        found = true;
        return false;
      }
      return true;
    });
    return found;
  }

  Future<void> _openHub() async {
    await Navigator.of(context).pushNamed('/guide');
    if (mounted) {
      await _load();
    }
  }

  Future<void> _openTopic(GuideTopicSpec topic) async {
    if (!_openingTopics.add(topic.id)) {
      return;
    }
    try {
      await openGuideTopicModule(
        context,
        topic: topic,
        progressService: _service,
        entrySurface: GuideEntryAnalyticsSurface.todayChecklist,
      );
      if (mounted) {
        await _load();
      }
    } finally {
      _openingTopics.remove(topic.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    if (snapshot == null || snapshot.isTodayCardDismissed) {
      final status = _dismissedStatus;
      if (status == null) {
        return const SizedBox.shrink();
      }
      return Semantics(
        key: const ValueKey('today-guide-dismissed-status'),
        container: true,
        liveRegion: true,
        label: status,
        child: const SizedBox(height: 1),
      );
    }
    final specs = purposeOrderedGuideTopics(Storage.motivation);
    final completed = specs
        .where((topic) => snapshot.isComplete(topic.id))
        .length;
    final t = AppL10n.of(context);
    return TodayGuideChecklistCard(
      copy: todayGuideChecklistCopy(
        t,
        completed: completed,
        total: specs.length,
      ),
      topics: guideTopicViewModels(t, snapshot, topics: specs),
      onOpenGuide: () => unawaited(_openHub()),
      onDismiss: () => unawaited(_dismiss()),
      onDestinationRequested: (topic) => unawaited(_openTopic(topic)),
      onNonLiveTopicRequested: (topic) => unawaited(_openTopic(topic)),
    );
  }
}
