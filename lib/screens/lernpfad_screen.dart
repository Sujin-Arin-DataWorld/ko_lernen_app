import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/course_mastery.dart';
import '../models/lernpfad.dart';
import '../services/account/cloud_write_session.dart';
import '../services/course_progress_service.dart';
import '../services/lernpfad_catalog.dart';
import '../services/lernpfad_lease.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/path_joy.dart';
import '../widgets/sori/standard_page.dart';
import 'foundation_lesson_screen.dart';
import 'phase_task_screen.dart';

/// Goals first for the learner's chosen band. Catalog opening is read-only;
/// assessment and rewards remain owned by the activity's existing services.
class LernpfadScreen extends StatefulWidget {
  const LernpfadScreen({
    super.key,
    this.loader,
    this.progress,
    this.masteryLoader,
  });
  final Future<LernpfadCatalog> Function()? loader;
  final CourseProgressService? progress;
  final Future<CourseMasterySnapshot?> Function()? masteryLoader;
  @override
  State<LernpfadScreen> createState() => _LernpfadScreenState();
}

class _LernpfadScreenState extends State<LernpfadScreen> {
  CourseProgressService get _progress =>
      widget.progress ?? CourseProgressService.shared;
  LernpfadCatalog? _catalog;
  LernpfadState? _state;
  CourseMasterySnapshot? _mastery;
  late LernpfadLease _lease;
  bool _busy = false, _error = false, _showActivities = false;
  int _generation = 0;
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    cloudWriteSessionController.changes.addListener(_accountChanged);
    unawaited(_load());
  }

  void _accountChanged() {
    if (mounted) {
      setState(() {
        _state = null;
        _mastery = null;
        _catalog = null;
      });
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final lease = LernpfadLease();
    _lease = lease;
    try {
      final catalog = await (widget.loader ?? LernpfadCatalog.load)();
      final state = await _progress.readLernpfad(catalog, lease);
      final mastery =
          await (widget.masteryLoader ?? _progress.readForDisplay)();
      lease.assertCurrent();
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _catalog = catalog;
        _state = state;
        _mastery = mastery;
        _error = false;
      });
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _error = true);
      }
    }
  }

  Future<void> _select(String id) async {
    if (_busy) {
      return;
    }
    final generation = _generation;
    setState(() => _busy = true);
    try {
      final next = await _progress.mutateLernpfad(
        _catalog!,
        _lease,
        (s) => s.selectBand(id, _catalog!),
      );
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _state = next;
        _showActivities = false;
        _error = false;
      });
      if (_scroll.hasClients) {
        _scroll.jumpTo(0);
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _error = true);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _open(LernpfadActivity activity) async {
    if (_busy) {
      return;
    }
    final catalog = _catalog!;
    if (activity.kind == 'foundation') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/path/foundation'),
          builder: (_) => FoundationLessonScreen(
            catalog: catalog,
            lessonId: activity.id,
            progress: _progress,
          ),
        ),
      );
    } else if (activity.kind == 'phaseTask') {
      final l = AppL10n.of(context);
      final lang = Localizations.localeOf(context).languageCode;
      final preparation = catalog.preparationFor(activity, _mastery);
      final hasRelevantProof =
          _mastery?.phaseTaskEvidence.any(
            catalog.phases.byId(activity.taskId!).passedBy,
          ) ??
          false;
      final choice = hasRelevantProof
          ? 'continue'
          : await showModalBottomSheet<String>(
              context: context,
              isScrollControlled: true,
              builder: (ctx) => SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l.pathV2PrepareTitle,
                          style: Theme.of(ctx).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(l.pathV2PrepareBody),
                        for (final id in preparation.take(3))
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              catalog.phases.byId(id).title.pick(lang),
                            ),
                          ),
                        const SizedBox(height: 16),
                        SoriButton.filled(
                          label: preparation.isEmpty
                              ? l.pathV2Prepare
                              : l.pathV2PrepareRelated,
                          onTap: () => Navigator.pop(ctx, 'prepare'),
                        ),
                        const SizedBox(height: 8),
                        SoriButton.outlined(
                          label: l.pathV2Supported,
                          onTap: () => Navigator.pop(ctx, 'continue'),
                        ),
                        SoriButton.ghost(
                          label: l.pathV2Later,
                          onTap: () => Navigator.pop(ctx, 'later'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
      if (!mounted || choice == null) {
        return;
      }
      if (choice == 'prepare') {
        // Preparation never changes the learner's selected target band.
        if (preparation.isEmpty) {
          await Navigator.of(context).pushNamed('/hangul');
        } else {
          final task = catalog.phases.byId(preparation.first);
          await Navigator.of(context).pushNamed(
            '/learning-phase/task',
            arguments: PhaseTaskRoute(task.phaseId, task.id),
          );
        }
      } else {
        final task = catalog.phases.byId(activity.taskId!);
        await Navigator.of(context).pushNamed(
          '/learning-phase/task',
          arguments: PhaseTaskRoute(task.phaseId, task.id),
        );
      }
    }
    if (mounted) {
      await _load();
      if (_scroll.hasClients) {
        _scroll.jumpTo(0);
      }
    }
  }

  @override
  void dispose() {
    cloudWriteSessionController.changes.removeListener(_accountChanged);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final catalog = _catalog;
    final state = _state;
    String bandLabel(LernpfadBand band) => band.level == 'F0'
        ? '${l.pathV2Foundation} ${band.id.split('.').last}'
        : band.id;
    if (catalog == null || state == null) {
      return SoriStandardPage(
        appBarTitle: l.pathV2Title,
        children: [
          if (_error) ...[
            Text(l.pathV2Error),
            SoriButton.filled(label: l.pathV2Retry, onTap: _load),
            SoriButton.ghost(
              label: l.pathV2Legacy,
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/path/legacy'),
            ),
          ] else
            const Center(child: CircularProgressIndicator()),
        ],
      );
    }
    final view = catalog.project(state, _mastery);
    final available = catalog
        .forBand(view.band.id)
        .where((a) => a.kind != 'pending')
        .toList();
    final active = state.active;
    final resume = active == null
        ? null
        : available.where((a) => a.id == active.lessonId).firstOrNull;
    final next = resume ?? view.next;
    final skills = {
      'listening': l.pathV2Listening,
      'speaking': l.pathV2Speaking,
      'reading': l.pathV2Reading,
      'writing': l.pathV2Writing,
    };
    return SoriStandardPage(
      appBarTitle: l.pathV2Title,
      controller: _scroll,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('path-v2-band-${state.selectedBandId}'),
          initialValue: state.selectedBandId,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.pathV2ChooseBand),
          items: [
            for (final b in catalog.bands)
              DropdownMenuItem(
                value: b.id,
                child: Text(bandLabel(b), maxLines: 1),
              ),
          ],
          onChanged: _busy
              ? null
              : (id) {
                  if (id != null) {
                    unawaited(_select(id));
                  }
                },
        ),
        const SizedBox(height: 16),
        SoriCard(
          key: const ValueKey('path-v2-goal'),
          variant: SoriCardVariant.hanji,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.pathV2Goal, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(
                view.band.outcome[lang] ?? view.band.outcome['en']!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(l.pathV2Progress(view.completed, view.requiredCount)),
              const SizedBox(height: 8),
              Text(
                l.pathV2Partial,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final entry in skills.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${entry.value}: ${(view.confirmedSkills[entry.key] ?? 0) == 0 ? l.pathV2Unchecked : l.pathV2Confirmed(view.confirmedSkills[entry.key]!)}',
            ),
          ),
        const SizedBox(height: 16),
        Text(l.pathV2Today, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (next != null)
          SoriCard(
            raised: true,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  next.title[lang] ?? next.title['en']!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (next.kind == 'foundation') ...[
                  const PathJoy(),
                  Text(
                    catalog.lessons[next.id]!.story[lang] ??
                        catalog.lessons[next.id]!.story['en']!,
                  ),
                ] else
                  Text(l.pathV2TaskContext),
                const SizedBox(height: 12),
                SoriButton.filled(
                  key: const ValueKey('path-v2-start'),
                  label: resume != null ? l.pathV2Resume : l.pathV2Start,
                  loading: _busy,
                  onTap: () => _open(next),
                ),
              ],
            ),
          )
        else ...[
          Text(l.pathV2Pending),
          if (available.isNotEmpty)
            SoriButton.outlined(
              label: l.pathV2Review,
              onTap: () => _open(available.first),
            ),
        ],
        if (_error) ...[
          const SizedBox(height: 12),
          Text(l.pathV2Error),
          SoriButton.outlined(label: l.pathV2Retry, onTap: _load),
        ],
        const SizedBox(height: 16),
        ExpansionTile(
          title: Text(l.pathV2Activities),
          onExpansionChanged: (value) =>
              setState(() => _showActivities = value),
          children: [
            if (_showActivities)
              for (final a in available)
                ListTile(
                  title: Text(a.title[lang] ?? a.title['en']!),
                  trailing: view.completedIds.contains(a.id)
                      ? const Icon(Icons.check)
                      : const Icon(Icons.chevron_right),
                  onTap: _busy ? null : () => _open(a),
                ),
          ],
        ),
        ExpansionTile(
          title: Text(l.pathV2All),
          children: [
            for (final b in catalog.bands)
              ListTile(
                title: Text(
                  '${bandLabel(b)} · ${b.title[lang] ?? b.title['en']}',
                ),
                selected: b.id == state.selectedBandId,
                onTap: _busy ? null : () => _select(b.id),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SoriButton.outlined(
          label: l.pathV2Free,
          onTap: () => Navigator.pushNamed(context, '/study-library'),
        ),
        const SizedBox(height: 8),
        SoriButton.outlined(
          label: l.pathV2Hanok,
          onTap: () => Navigator.pushNamed(context, '/hanok'),
        ),
        SoriButton.ghost(
          label: l.pathV2Legacy,
          onTap: () => Navigator.pushReplacementNamed(context, '/path/legacy'),
        ),
        Text(l.pathV2Local, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
