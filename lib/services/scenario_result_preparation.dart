import '../models/scenario_can_do_result.dart';
import 'course_mastery_service.dart';

/// Prepares one screen attempt before the player writes completion rewards.
/// A successful checkpoint is retained when result projection needs a retry.
/// Unlinked free practice may legitimately have no course update.
final class ScenarioResultPreparation {
  ScenarioResultPreparation({
    required this.requiresCheckpoint,
    required this.recordCheckpoint,
    required this.buildResult,
  });

  final bool requiresCheckpoint;
  final Future<CourseUpdate?> Function() recordCheckpoint;
  final Future<ScenarioCanDoResult?> Function(CourseUpdate) buildResult;

  bool _checkpointRecorded = false;
  CourseUpdate? _checkpoint;
  bool _prepared = false;
  ScenarioCanDoResult? _result;
  Future<ScenarioCanDoResult?>? _inFlight;

  Future<ScenarioCanDoResult?> prepare() {
    final running = _inFlight;
    if (running != null) {
      return running;
    }
    late final Future<ScenarioCanDoResult?> pending;
    pending = _resume().whenComplete(() {
      if (identical(_inFlight, pending)) {
        _inFlight = null;
      }
    });
    _inFlight = pending;
    return pending;
  }

  Future<ScenarioCanDoResult?> _resume() async {
    if (_prepared) {
      return _result;
    }
    if (!_checkpointRecorded) {
      final checkpoint = await recordCheckpoint();
      if (requiresCheckpoint && checkpoint == null) {
        throw StateError('The course checkpoint has not been persisted.');
      }
      _checkpoint = checkpoint;
      _checkpointRecorded = true;
    }
    final checkpoint = _checkpoint;
    _result = checkpoint == null ? null : await buildResult(checkpoint);
    _prepared = true;
    return _result;
  }
}
