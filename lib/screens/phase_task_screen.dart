import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/account/cloud_write_session.dart';
import '../services/course_progress_service.dart';
import '../services/phase_task_catalog.dart';
import '../services/phase_task_drafts.dart';
import '../services/pronunciation_recorder.dart';
import '../services/tts_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';

class PhaseTaskRoute {
  const PhaseTaskRoute(this.phaseId, this.taskId, {this.assessment = false});
  final String phaseId, taskId;
  final bool assessment;
}

class PhaseTaskScreen extends StatefulWidget {
  const PhaseTaskScreen({
    super.key,
    required this.arguments,
    this.loader,
    this.saveAttempt,
    this.playAudio,
    this.recorder,
  });
  final PhaseTaskRoute arguments;
  final Future<PhaseTaskCatalog> Function()? loader;
  final Future<void> Function(PhaseTaskResult)? saveAttempt;
  final Future<bool> Function(String)? playAudio;
  final PronunciationRecorder? recorder;
  @override
  State<PhaseTaskScreen> createState() => _PhaseTaskScreenState();
}

class _PhaseTaskScreenState extends State<PhaseTaskScreen>
    with WidgetsBindingObserver {
  PhaseTask? _task;
  PhaseTaskDrafts? _drafts;
  late bool _assessment;
  bool _busy = false,
      _audioBusy = false,
      _recording = false,
      _listened = false,
      _accountChanged = false;
  String? _error;
  final _answers = <String, String>{};
  PhaseTaskResult? _result;
  String _attemptId = const Uuid().v4();
  DateTime? _occurredAt;
  PronunciationRecorder? _recorderInstance;
  PronunciationRecorder get _recorder =>
      _recorderInstance ??= widget.recorder ?? RecordPronunciationRecorder();
  AudioPlayer? _playerInstance;
  AudioPlayer get _player => _playerInstance ??= AudioPlayer();
  StreamSubscription<Uint8List>? _stream;
  Timer? _limit;
  final _chunks = <Uint8List>[];
  int _byteCount = 0;
  Uint8List? _recorded;
  @override
  void initState() {
    super.initState();
    _assessment = widget.arguments.assessment;
    WidgetsBinding.instance.addObserver(this);
    cloudWriteSessionController.changes.addListener(_checkAccount);
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final catalog = await (widget.loader ?? PhaseTaskCatalog.load)();
      final task = catalog.byId(widget.arguments.taskId);
      if (task.phaseId != widget.arguments.phaseId) {
        throw const FormatException('Wrong Phase task route');
      }
      final drafts = PhaseTaskDrafts(task.contentHash);
      final answers = await drafts.load(_assessment);
      if (!mounted) {
        return;
      }
      setState(() {
        _task = task;
        _drafts = drafts;
        _answers.addAll(answers);
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppL10n.of(context).phaseTaskError);
      }
    }
  }

  void _checkAccount() {
    try {
      _drafts?.assertCurrent();
    } catch (_) {
      _answers.clear();
      _chunks.clear();
      _recorded = null;
      unawaited(_stopRecording(discard: true));
      unawaited(_playerInstance?.stop());
      if (mounted) {
        setState(() => _accountChanged = true);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_stopRecording());
    }
  }

  Future<void> _switchMode(bool assessment) async {
    if (_busy || _recording || _audioBusy || _accountChanged) {
      return;
    }
    setState(() => _busy = true);
    try {
      await _drafts!.save(_assessment, _answers);
      final saved = await _drafts!.load(assessment);
      if (!mounted) {
        return;
      }
      setState(() {
        _assessment = assessment;
        _answers
          ..clear()
          ..addAll(saved);
        _result = null;
        _error = null;
        _listened = false;
        _recorded = null;
        _attemptId = const Uuid().v4();
        _occurredAt = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppL10n.of(context).phaseTaskError);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _answer(String id, String value) {
    _answers[id] = value;
    _attemptId = const Uuid().v4();
    _occurredAt = null;
    setState(() => _error = null);
    unawaited(
      _drafts!.save(_assessment, _answers).catchError((Object _) {
        if (mounted) {
          setState(() => _error = AppL10n.of(context).phaseTaskError);
        }
      }),
    );
  }

  Future<void> _listen() async {
    setState(() {
      _audioBusy = true;
      _error = null;
    });
    try {
      _drafts!.assertCurrent();
      final text = (_assessment ? _task!.assessment : _task!.practice).sourceKo;
      final ok =
          await (widget.playAudio ??
              (text) => TtsService.speak(text, voice: 'female'))(text);
      _drafts!.assertCurrent();
      if (!ok) {
        throw StateError('Audio unavailable');
      }
      if (mounted) {
        setState(() => _listened = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppL10n.of(context).phaseTaskError);
      }
    } finally {
      if (mounted) {
        setState(() => _audioBusy = false);
      }
    }
  }

  Future<void> _record() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _drafts!.assertCurrent();
      if (!await _recorder.requestPermission()) {
        throw StateError('Microphone permission denied');
      }
      if (!mounted) {
        return;
      }
      _drafts!.assertCurrent();
      await _playerInstance?.stop();
      _chunks.clear();
      _byteCount = 0;
      _recorded = null;
      final stream = await _recorder.startPcm16Stream();
      if (!mounted) {
        await _recorder.stop();
        return;
      }
      _recording = true;
      _drafts!.assertCurrent();
      setState(() {});
      _stream = stream.listen(
        (chunk) {
          if (_byteCount + chunk.length <= 1920000) {
            _chunks.add(Uint8List.fromList(chunk));
            _byteCount += chunk.length;
          } else {
            unawaited(_stopRecording());
          }
        },
        onError: (Object _) {
          unawaited(_stopRecording(discard: true));
          if (mounted) {
            setState(() => _error = AppL10n.of(context).phaseTaskError);
          }
        },
      );
      _limit = Timer(
        const Duration(seconds: 60),
        () => unawaited(_stopRecording()),
      );
    } catch (_) {
      await _stopRecording(discard: true);
      if (mounted) {
        setState(() => _error = AppL10n.of(context).phaseTaskError);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _stopRecording({bool discard = false}) async {
    _limit?.cancel();
    _limit = null;
    if (!_recording) {
      return;
    }
    _recording = false;
    if (mounted) {
      setState(() => _busy = true);
    }
    try {
      await _recorder.stop();
      await _stream?.cancel();
    } catch (_) {
      discard = true;
    }
    _stream = null;
    if (!discard && !_accountChanged && _byteCount >= 32000) {
      final bytes = Uint8List(44 + _byteCount);
      void ascii(int at, String s) {
        bytes.setRange(at, at + s.length, s.codeUnits);
      }

      ascii(0, 'RIFF');
      ascii(8, 'WAVE');
      ascii(12, 'fmt ');
      ascii(36, 'data');
      final b = ByteData.sublistView(bytes);
      b.setUint32(4, 36 + _byteCount, Endian.little);
      b.setUint32(16, 16, Endian.little);
      b.setUint16(20, 1, Endian.little);
      b.setUint16(22, 1, Endian.little);
      b.setUint32(24, 16000, Endian.little);
      b.setUint32(28, 32000, Endian.little);
      b.setUint16(32, 2, Endian.little);
      b.setUint16(34, 16, Endian.little);
      b.setUint32(40, _byteCount, Endian.little);
      var offset = 44;
      for (final c in _chunks) {
        bytes.setRange(offset, offset + c.length, c);
        offset += c.length;
      }
      _recorded = bytes;
    }
    _chunks.clear();
    _byteCount = 0;
    if (mounted) {
      setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (_busy || _audioBusy || _recording || _accountChanged) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _drafts!.assertCurrent();
      if ((_task!.skill == 'listening' && !_listened) ||
          (_task!.skill == 'speaking' && _recorded == null)) {
        throw StateError('Required audio missing');
      }
      final result = _task!.evaluate(_answers, assessment: _assessment);
      _occurredAt ??= DateTime.now().toUtc();
      if (widget.saveAttempt != null) {
        await widget.saveAttempt!(result);
      } else {
        await CourseProgressService.shared.recordPhaseAttempt(
          result: result,
          attemptId: _attemptId,
          occurredAt: _occurredAt!,
          assertCurrentWrite: _drafts!.assertCurrent,
        );
      }
      _drafts!.assertCurrent();
      if (mounted) {
        setState(() => _result = result);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppL10n.of(context).phaseTaskError);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cloudWriteSessionController.changes.removeListener(_checkAccount);
    _limit?.cancel();
    unawaited(_stream?.cancel());
    unawaited(_recorderInstance?.dispose());
    unawaited(_playerInstance?.dispose());
    if (widget.playAudio == null && _audioBusy) {
      unawaited(TtsService.stop());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context),
        lang = Localizations.localeOf(context).languageCode;
    final task = _task,
        packet = _assessment ? _task?.assessment : _task?.practice;
    return SoriStandardFrame(
      appBarTitle: task?.title.pick(lang) ?? t.phaseTasksTitle,
      maxWidth: 720,
      padding: const EdgeInsets.all(Spacing.lg),
      builder: (context, padding) {
        if (_accountChanged) {
          return Padding(
            padding: padding,
            child: Text(t.phaseTaskAccountChanged),
          );
        }
        if (task == null || packet == null) {
          return _error == null
              ? const AppLoading()
              : Center(
                  child: SoriButton.ghost(
                    key: const ValueKey('phase-task-load-retry'),
                    onTap: () {
                      setState(() => _error = null);
                      unawaited(_load());
                    },
                    label: t.phaseTaskRetry,
                  ),
                );
        }
        final disabled = _busy || _audioBusy || _recording || _result != null;
        return ListView(
          padding: padding,
          children: [
            Text(task.teaching.pick(lang)),
            for (final example in task.examplesKo)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(example),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(t.phaseTaskPractice),
                  selected: !_assessment,
                  onSelected: _busy || _recording || _audioBusy
                      ? null
                      : (_) => _switchMode(false),
                ),
                ChoiceChip(
                  label: Text(t.phaseTaskAssessment),
                  selected: _assessment,
                  onSelected: _busy || _recording || _audioBusy
                      ? null
                      : (_) => _switchMode(true),
                ),
              ],
            ),
            if (packet.sourceKind == 'audio')
              SoriButton.outlined(
                onTap: _audioBusy || _busy ? null : _listen,
                label: t.phaseTaskPlay,
              ),
            if (packet.sourceKind != 'audio' || _result != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(packet.sourceKo),
                ),
              ),
            if (packet.sourceKind == 'audio' && !_listened)
              Text(t.phaseTaskAudioRequired),
            for (final q in packet.questions)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(q.prompt.pick(lang)),
                    if (q.requiredForPass) Text(t.phaseTaskCriterionRequired),
                    if (q.kind == 'choice')
                      RadioGroup<String>(
                        groupValue: _answers[q.id],
                        onChanged: (value) {
                          if (!disabled && value != null) {
                            _answer(q.id, value);
                          }
                        },
                        child: Column(
                          children: [
                            for (final option in q.options.entries)
                              RadioListTile<String>(
                                title: Text(option.value),
                                value: option.key,
                                enabled: !disabled,
                              ),
                          ],
                        ),
                      )
                    else
                      TextFormField(
                        key: ValueKey('${task.id}:$_assessment:${q.id}-field'),
                        initialValue: _answers[q.id] ?? '',
                        enabled: !disabled,
                        decoration: InputDecoration(
                          labelText: q.prompt.pick(lang),
                        ),
                        onChanged: (v) => _answer(q.id, v),
                        minLines: q.kind == 'freeText' ? 4 : 1,
                        maxLines: q.kind == 'freeText' ? 6 : 1,
                        maxLength: q.kind == 'freeText' ? 6000 : 240,
                      ),
                    if (_result != null) ...[
                      Text(
                        q.isUnscored(_answers[q.id] ?? '')
                            ? t.phaseTaskCriterionUnscored
                            : q.accepts(_answers[q.id] ?? '')
                            ? t.phaseTaskCriterionPassed
                            : t.phaseTaskNeedsPractice,
                      ),
                      Text(q.explanation.pick(lang)),
                    ],
                  ],
                ),
              ),
            if (task.skill == 'speaking') ...[
              Text(t.phaseTaskRecordingNotice),
              SoriButton.outlined(
                onTap: _busy || _result != null
                    ? null
                    : (_recording ? _stopRecording : _record),
                label: _recording ? t.phaseTaskStop : t.phaseTaskRecord,
              ),
              if (_recorded != null)
                SoriButton.outlined(
                  onTap: () async {
                    try {
                      await _player.play(
                        BytesSource(_recorded!, mimeType: 'audio/wav'),
                      );
                    } catch (_) {
                      if (mounted) {
                        setState(() => _error = t.phaseTaskError);
                      }
                    }
                  },
                  label: t.phaseTaskReplay,
                ),
            ],
            if (_error != null)
              Semantics(liveRegion: true, child: Text(_error!)),
            if (_result == null)
              SoriButton.filled(
                key: const ValueKey('phase-task-submit'),
                onTap:
                    disabled ||
                        (task.skill == 'speaking' && _recorded == null) ||
                        (task.skill == 'listening' && !_listened)
                    ? null
                    : _submit,
                label: t.phaseTaskSubmit,
              )
            else ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  _result!.score == null
                      ? t.phaseTaskUnscored
                      : !_assessment
                      ? t.phaseTaskPracticeComplete
                      : _result!.passed
                      ? t.phaseTaskPassed
                      : t.phaseTaskNeedsPractice,
                ),
              ),
              if (_result!.score != null)
                Text('${(_result!.score! * 100).round()}%'),
              SoriButton.outlined(
                onTap: () => setState(() {
                  _result = null;
                  _attemptId = const Uuid().v4();
                  _occurredAt = null;
                  _listened = false;
                  _recorded = null;
                }),
                label: t.phaseTaskRetry,
              ),
            ],
          ],
        );
      },
    );
  }
}
