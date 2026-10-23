import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/lernpfad.dart';
import '../services/account/cloud_write_session.dart';
import '../services/course_progress_service.dart';
import '../services/lernpfad_catalog.dart';
import '../services/lernpfad_lease.dart';
import '../services/tts_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/motion.dart';
import '../widgets/sori/path_joy.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/study_frame.dart';

class FoundationLessonScreen extends StatefulWidget {
  const FoundationLessonScreen({
    super.key,
    this.catalog,
    this.lessonId = 'F0.1.sound-signs',
    this.progress,
    this.playAudio,
  });
  final LernpfadCatalog? catalog;
  final String lessonId;
  final CourseProgressService? progress;
  final Future<bool> Function(String)? playAudio;
  @override
  State<FoundationLessonScreen> createState() => _FoundationLessonScreenState();
}

class _FoundationLessonScreenState extends State<FoundationLessonScreen>
    with WidgetsBindingObserver {
  CourseProgressService get _progress =>
      widget.progress ?? CourseProgressService.shared;
  final _lease = LernpfadLease();
  LernpfadCatalog? _catalog;
  FoundationLesson? _lesson;
  FoundationRun? _run, _pending, _savedRun;
  bool _busy = false,
      _error = false,
      _stale = false,
      _audioBusy = false,
      _audioUnavailable = false;
  bool get _unresolved => _error && _pending != null;
  String? _hint, _feedback;
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    cloudWriteSessionController.changes.addListener(_checkAccount);
    unawaited(_load());
  }

  void _checkAccount() {
    try {
      _lease.assertCurrent();
    } catch (_) {
      unawaited(TtsService.stop());
      if (mounted) {
        setState(() {
          _stale = true;
          _run = null;
          _hint = null;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(TtsService.stop());
    }
  }

  Future<void> _load({bool restart = false}) async {
    try {
      final catalog = widget.catalog ?? await LernpfadCatalog.load();
      final lesson = catalog.lessons[widget.lessonId];
      if (lesson == null) {
        throw const FormatException('Unknown foundation lesson');
      }
      final saved = await _progress.readLernpfad(catalog, _lease);
      final previous = saved.active;
      _savedRun = previous;
      final run = !restart && previous?.lessonId == lesson.id
          ? previous!
          : FoundationRun.start(lesson, const Uuid().v4(), DateTime.now());
      _lease.assertCurrent();
      if (!mounted) {
        return;
      }
      setState(() {
        _catalog = catalog;
        _lesson = lesson;
        _run = run;
        _pending = null;
        _error = false;
      });
      if (previous != run) {
        await _save(run);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = true;
          if (error is FoundationCursorConflict) {
            _pending = null;
          }
        });
      }
    }
  }

  Future<void> _save(FoundationRun candidate) async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _pending = candidate;
    });
    try {
      final saved = await _progress.saveFoundationRun(
        _catalog!,
        _lease,
        candidate,
        expected: _savedRun,
      );
      if (!mounted) {
        return;
      }
      final stepChanged = candidate.step != _run?.step;
      setState(() {
        _run = candidate;
        _savedRun = saved.active;
        _pending = null;
        _error = false;
      });
      if (stepChanged && _scroll.hasClients) {
        _scroll.jumpTo(0);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = true;
          if (error is FoundationCursorConflict) {
            _pending = null;
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _answer(String value) async {
    if (_busy || _audioBusy || _unresolved) {
      return;
    }
    final next = _run!.answer(_lesson!, value);
    final incorrect = next.step == _run!.step;
    setState(() {
      _hint = null;
      _feedback = null;
    });
    await _save(next);
    if (mounted && !_error && incorrect) {
      setState(() => _feedback = AppL10n.of(context).pathV2Wrong);
    }
  }

  Future<void> _help() async {
    if (_busy || _unresolved) {
      return;
    }
    final answer = _lesson!.questionAt(_run!.step).answer;
    await _save(_run!.withHelp());
    if (mounted && !_error) {
      setState(() => _hint = AppL10n.of(context).pathV2Hint(answer));
    }
  }

  Future<void> _listen(String text) async {
    if (_audioBusy || _busy) {
      return;
    }
    setState(() {
      _audioBusy = true;
      _audioUnavailable = false;
    });
    try {
      final success =
          await (widget.playAudio ?? (text) => TtsService.speak(text))(text);
      if (mounted) {
        setState(() => _audioUnavailable = !success);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _audioUnavailable = true);
      }
    } finally {
      if (mounted) {
        setState(() => _audioBusy = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cloudWriteSessionController.changes.removeListener(_checkAccount);
    unawaited(TtsService.stop());
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final lesson = _lesson;
    final run = _run;
    final complete = lesson != null && run != null && run.complete(lesson);
    final children = <Widget>[];
    if (_stale) {
      children.addAll([
        Text(l.pathV2Error),
        SoriButton.filled(
          label: l.pathV2Return,
          onTap: () => Navigator.pop(context),
        ),
      ]);
    } else if (lesson == null || run == null) {
      children.add(
        _error
            ? Text(l.pathV2Error)
            : const Center(child: CircularProgressIndicator()),
      );
      if (_error) {
        children.add(SoriButton.filled(label: l.pathV2Retry, onTap: _load));
      }
    } else if (!run.current(lesson)) {
      children.addAll([
        Text(l.pathV2Recheck),
        SoriButton.filled(
          label: l.pathV2Restart,
          onTap: () => _load(restart: true),
        ),
      ]);
    } else if (complete) {
      children.addAll([
        AnimatedScale(
          scale: 1.06,
          duration: SoriMotion.reduceMotion(context)
              ? Duration.zero
              : SoriAnimation.quick,
          child: const PathJoy(resolved: true),
        ),
        Semantics(
          liveRegion: true,
          child: Text(
            run.helped ? l.pathV2ResultSupported : l.pathV2ResultIndependent,
            key: const ValueKey('foundation-result'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 12),
        Text(l.pathV2Scope),
        const SizedBox(height: 8),
        Text(lesson.followup[lang] ?? lesson.followup['en']!),
        const SizedBox(height: 16),
        SoriButton.filled(
          label: l.pathV2Return,
          onTap: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/path/v2');
            }
          },
        ),
      ]);
    } else {
      children.add(
        Text(
          '${run.step + 1} / ${lesson.endStep}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      );
      children.add(const SizedBox(height: 12));
      if (run.step == 0) {
        children.addAll([
          const PathJoy(),
          Text(lesson.story[lang] ?? lesson.story['en']!),
          const SizedBox(height: 12),
          Text(l.pathV2FirstGoal),
        ]);
      } else if (run.step < lesson.questionStart) {
        final teaching = lesson.teaching[run.step - 1];
        final explanation = pathText(teaching['explanation']);
        children.addAll([
          SoriCard(
            raised: true,
            child: Column(
              children: [
                Text(
                  (teaching['parts'] as List).join(' + '),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  teaching['target'] as String,
                  style: Theme.of(context).textTheme.displayLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(explanation[lang] ?? explanation['en']!),
          const SizedBox(height: 12),
          SoriButton.outlined(
            label: l.pathV2Listen,
            icon: Icons.volume_up,
            loading: _audioBusy,
            onTap: _busy ? null : () => _listen(teaching['target'] as String),
          ),
          if (_audioUnavailable) Text(l.pathV2AudioUnavailable),
        ]);
      } else {
        final question = lesson.questionAt(run.step);
        children.addAll([
          Text(
            run.step < lesson.checkStart ? l.pathV2Practice : l.pathV2Check,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(l.pathV2ChooseSign),
          const SizedBox(height: 16),
          SoriCard(
            raised: true,
            child: Center(
              child: Text(
                question.parts.join(' + '),
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final option in question.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SoriButton.outlined(
                key: ValueKey('foundation-answer-$option'),
                label: option,
                fullWidth: true,
                textRole: SoriButtonTextRole.learning,
                onTap: _busy || _unresolved ? null : () => _answer(option),
              ),
            ),
          if (_feedback != null)
            Semantics(liveRegion: true, child: Text(_feedback!)),
          if (_hint != null) Semantics(liveRegion: true, child: Text(_hint!)),
          SoriButton.ghost(
            key: const ValueKey('foundation-help'),
            label: l.pathV2Help,
            onTap: _busy || _unresolved ? null : _help,
          ),
        ]);
      }
      if (run.step < lesson.questionStart) {
        children.addAll([
          const SizedBox(height: 16),
          SoriButton.filled(
            key: const ValueKey('foundation-continue'),
            label: l.pathV2Continue,
            loading: _busy,
            onTap: _audioBusy || _unresolved
                ? null
                : () => _save(run.advance(lesson)),
          ),
        ]);
      }
      if (_error) {
        children.addAll([
          Text(l.pathV2Error),
          SoriButton.outlined(
            label: l.pathV2Retry,
            onTap: () {
              final pending = _pending;
              if (pending != null) {
                unawaited(_save(pending));
              } else {
                unawaited(_load());
              }
            },
          ),
          if (_pending == null)
            SoriButton.ghost(label: l.pathV2Resume, onTap: _load),
        ]);
      }
    }
    return SoriStudyFrame(
      title: lesson?.title[lang] ?? l.pathV2Foundation,
      particles: false,
      padding: EdgeInsets.zero,
      onLeave: () => unawaited(TtsService.stop()),
      child: SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
