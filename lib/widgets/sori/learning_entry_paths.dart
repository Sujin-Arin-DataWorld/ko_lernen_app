import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/foundation_progress.dart';
import '../../services/account/cloud_write_session.dart';
import '../../services/foundation_progress_service.dart';
import '../../services/storage_service.dart';
import 'c_gallery/c_materials.dart';

/// Three optional entry paths share existing content and durable progress.
/// They are choices, not a sequence or assessment/unlock condition.
class CLearningEntryPaths extends StatefulWidget {
  const CLearningEntryPaths({
    super.key,
    required this.onFoundation,
    required this.onCourse,
    required this.onFree,
    this.busy = false,
    this.loadFoundation,
  });
  final VoidCallback onFoundation, onCourse, onFree;
  final bool busy;
  final Future<FoundationProgress> Function()? loadFoundation;

  @override
  State<CLearningEntryPaths> createState() => _CLearningEntryPathsState();
}

class _CLearningEntryPathsState extends State<CLearningEntryPaths> {
  late Future<FoundationProgress> _foundation;

  @override
  void initState() {
    super.initState();
    _foundation = _load();
    FoundationProgressStorage.changes.addListener(_refresh);
    cloudWriteSessionController.changes.addListener(_refresh);
  }

  Future<FoundationProgress> _load() =>
      widget.loadFoundation?.call() ?? FoundationProgressService.shared.load();

  void _refresh() {
    if (mounted) {
      setState(() {
        _foundation = _load();
      });
    }
  }

  @override
  void dispose() {
    FoundationProgressStorage.changes.removeListener(_refresh);
    cloudWriteSessionController.changes.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    const heading = TextStyle(
      fontFamily: 'Paperlogy',
      fontSize: 21,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: CPalette.ink,
    );
    const body = TextStyle(
      fontFamily: 'Paperlogy',
      fontSize: 16,
      height: 1.45,
      color: CPalette.ink,
    );
    Widget path(
      String id,
      String title,
      String description,
      String action,
      VoidCallback open, {
      Widget? progress,
    }) => CPaperPanel(
      key: ValueKey('lernen-path-$id'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            header: true,
            child: Text(title, style: heading),
          ),
          const SizedBox(height: 8),
          Text(description, style: body),
          if (progress != null) ...[const SizedBox(height: 8), progress],
          const SizedBox(height: 16),
          CMaterialAction(
            label: action,
            gold: id == 'course',
            onTap: widget.busy ? null : open,
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CSceneArt(CScene.book, height: 140),
        const SizedBox(height: 12),
        Text(t.lernenPathsBody, style: body),
        const SizedBox(height: 16),
        FutureBuilder<FoundationProgress>(
          future: _foundation,
          builder: (context, snapshot) => LayoutBuilder(
            builder: (context, bounds) {
              final settled = snapshot.connectionState == ConnectionState.done;
              final status = settled && snapshot.hasError
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(t.catalogProgressUnavailable, style: body),
                        CMaterialAction(
                          label: t.btnRetry,
                          compact: true,
                          onTap: _refresh,
                        ),
                      ],
                    )
                  : settled && snapshot.hasData
                  ? Text(
                      t.foundationProgress(
                        snapshot.data!.practicedCount,
                        snapshot.data!.totalTasks,
                      ),
                      style: body,
                    )
                  : Semantics(
                      liveRegion: true,
                      label: t.bojagiLoading,
                      child: const LinearProgressIndicator(),
                    );
              final paths = [
                path(
                  'foundation',
                  t.lernenFoundation,
                  t.foundationIntro,
                  t.foundationPracticeAction,
                  widget.onFoundation,
                  progress: status,
                ),
                path(
                  'course',
                  t.lernenCourse,
                  t.lernenCourseBody,
                  t.catalogStartSession,
                  widget.onCourse,
                ),
                path(
                  'free',
                  t.lernenFree,
                  t.lernenFreeBody,
                  t.lernenFreeOpen,
                  widget.onFree,
                ),
              ];
              final across =
                  bounds.maxWidth >= 720 &&
                  MediaQuery.textScalerOf(context).scale(16) <= 20;
              if (across) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < paths.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: paths[i]),
                    ],
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < paths.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    paths[i],
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
