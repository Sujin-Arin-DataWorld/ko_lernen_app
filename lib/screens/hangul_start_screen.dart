import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/analytics_service.dart';
import '../services/hangul_foundation_catalog.dart';
import '../services/hangul_start_progress.dart';
import '../services/hangul_util.dart';
import '../services/korean_romanization.dart';
import '../services/learning_phase_catalog.dart';
import '../services/tts_recorded_jamo.dart';
import '../services/tts_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/hangul_start_material.dart';
import '../widgets/sori/route_observer.dart';
import '../widgets/sori/speakable.dart';
import '../widgets/sori/tokens.dart';
import 'learning_phases_screen.dart';

enum _View { map, lesson, lessonResult, testIntro, test, testResult }

/// Opens the real first A1 phase without changing its progress or placement.
Future<void> openHangulStartA11(BuildContext context) async {
  final phases = await LearningPhaseCatalog.load();
  if (!context.mounted) return;
  final phase = phases.where((phase) => phase.id == 'KP01').firstOrNull;
  await Navigator.of(context).pushNamed(
    phase == null ? '/course/phases' : '/course/phase',
    arguments: phase == null ? null : HangulStartPhaseDestination(phase),
  );
}

class HangulStartScreen extends StatefulWidget {
  const HangulStartScreen({
    super.key,
    this.entry = HangulStartEntry.map,
    this.loadCatalog,
    this.playAudio,
  });
  final HangulStartEntry entry;
  final Future<HangulFoundation> Function()? loadCatalog;
  final Future<bool> Function(String text, double? speed)? playAudio;

  @override
  State<HangulStartScreen> createState() => _HangulStartScreenState();
}

class _HangulStartScreenState extends State<HangulStartScreen>
    with WidgetsBindingObserver, RouteAware {
  late HangulStartProgressStore _store;
  HangulFoundation? _catalog;
  HangulStartProgress _progress = const HangulStartProgress();
  FoundationLesson? _lesson;
  ModalRoute<dynamic>? _route;
  _View _view = _View.map;
  int _stage = 0;
  int _item = 0;
  final _placed = <String>[];
  final _testAnswers = <bool>[];
  String? _selected;
  bool? _correct;
  int _plays = 0;
  bool _hint = false;
  bool _loading = true;
  bool _loadFailed = false;
  bool _saving = false;
  bool _saveFailed = false;
  bool _playing = false;
  bool _audioFailed = false;
  int _audioRevision = 0;
  int? _speechRequest;

  AppL10n get t => AppL10n.of(context);
  String get language => Localizations.localeOf(context).languageCode;
  HangulStartHome get home => HangulStartHome(_catalog!, _progress);
  bool get _testPassed =>
      _testAnswers.where((answer) => answer).length >=
      _catalog!.kurztest.passAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      soriRouteObserver.unsubscribe(this);
      _route = route;
      if (route != null) soriRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() => _interruptAudio();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _interruptAudio();
  }

  @override
  void dispose() {
    _stopAudio();
    soriRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    _store = HangulStartProgressStore();
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final catalog =
          await (widget.loadCatalog ?? HangulFoundationCatalog.load)();
      final progress = await _store.load();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _progress = progress;
        _loading = false;
        if (widget.entry == HangulStartEntry.quiz) _view = _View.testIntro;
      });
      final next = home.nextLesson;
      if (widget.entry == HangulStartEntry.resume &&
          !home.finished &&
          next != null) {
        await _openLesson(next);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
      }
    }
  }

  void _stopAudio() {
    _audioRevision++;
    final owned = _speechRequest;
    _speechRequest = null;
    if (owned != null) unawaited(SoriSpeech.stopIfRequestCurrent(owned));
  }

  void _interruptAudio() {
    if (!_playing) return;
    _stopAudio();
    if (mounted) setState(() => _playing = false);
  }

  Future<void> _listen(
    String text, {
    double? rate,
    bool count = false,
    int? limit,
  }) async {
    if (_playing || (limit != null && _plays >= limit)) return;
    final revision = ++_audioRevision;
    setState(() {
      _playing = true;
      _audioFailed = false;
    });
    bool played;
    try {
      final override = widget.playAudio;
      final request = override == null
          ? SoriSpeech.speak(
              text,
              voice: TtsRecordedJamo.hasCarrier(text)
                  ? TtsRecordedJamo.voiceTag
                  : 'auto',
              rateMultiplier: rate == null ? 1 : rate / SoriSpeech.speed.value,
            )
          : override(text, rate);
      if (override == null) _speechRequest = SoriSpeech.speechRequestGeneration;
      played = await request;
    } catch (_) {
      played = false;
    }
    if (!mounted || revision != _audioRevision) return;
    _speechRequest = null;
    setState(() {
      _playing = false;
      _audioFailed = !played;
      if (played && count) _plays++;
    });
  }

  Future<bool> _save(Future<HangulStartProgress> Function() write) async {
    if (_saving) return false;
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      final progress = await write();
      if (!mounted) return false;
      setState(() => _progress = progress);
      return true;
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _resetExercise() {
    _stopAudio();
    _placed.clear();
    _selected = null;
    _correct = null;
    _plays = 0;
    _hint = false;
    _playing = false;
    _audioFailed = false;
    _saveFailed = false;
  }

  void _show(_View view) {
    setState(() {
      _resetExercise();
      _view = view;
    });
  }

  void _back() {
    if (_saving) return;
    if (_view == _View.lesson || _view == _View.lessonResult) {
      _show(_View.map);
      return;
    }
    if (_view == _View.test || _view == _View.testResult) {
      _show(_View.testIntro);
      return;
    }
    if (_view == _View.testIntro && widget.entry != HangulStartEntry.quiz) {
      _show(_View.map);
      return;
    }
    _stopAudio();
    Navigator.of(context).pop();
  }

  Future<void> _openA11() async {
    if (_saving) return;
    _interruptAudio();
    try {
      await openHangulStartA11(context);
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  int _items(FoundationLesson lesson, int stage) => switch (stage) {
    1 => lesson.teach.length + (lesson.reading.isEmpty ? 0 : 1),
    2 => lesson.build.length,
    3 => lesson.listen.length,
    _ => 1,
  };

  Future<void> _openLesson(
    FoundationLesson lesson, {
    bool resume = true,
  }) async {
    final saved = _progress.cursor;
    final useSaved = resume && saved?.lessonId == lesson.id;
    final stage = useSaved ? saved!.stage : 0;
    final item = useSaved && saved!.item < _items(lesson, stage)
        ? saved.item
        : 0;
    if (!await _save(
      () => _store.setCursor(HangulStartCursor(lesson.id, stage, item)),
    )) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _resetExercise();
      _lesson = lesson;
      _stage = stage;
      _item = item;
      _view = _View.lesson;
    });
    unawaited(
      Analytics.lessonStarted(lessonType: 'hangul_start', lessonId: lesson.id),
    );
  }

  Future<void> _advanceLesson() async {
    final lesson = _lesson!;
    if (_stage == 6) {
      final firstTime = !_progress.completed.contains(lesson.id);
      if (await _save(() => _store.complete(lesson.id)) && mounted) {
        unawaited(
          Analytics.lessonCompleted(
            lessonType: 'hangul_start',
            lessonId: lesson.id,
            firstTime: firstTime,
          ),
        );
        _show(_View.lessonResult);
      }
      return;
    }
    final sameStage = _item + 1 < _items(lesson, _stage);
    final stage = sameStage ? _stage : _stage + 1;
    final item = sameStage ? _item + 1 : 0;
    if (!await _save(
      () => _store.setCursor(HangulStartCursor(lesson.id, stage, item)),
    )) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _resetExercise();
      _stage = stage;
      _item = item;
    });
  }

  void _beginTest() {
    _testAnswers.clear();
    _show(_View.test);
  }

  Future<void> _gradeTest() async {
    if (_selected == null || _plays == 0 || _playing || _saving) return;
    final test = _catalog!.kurztest;
    final index = _testAnswers.length;
    final correct = _selected == test.items[index].answer;
    if (index + 1 < test.items.length) {
      setState(() {
        _testAnswers.add(correct);
        _resetExercise();
      });
      return;
    }
    final score =
        _testAnswers.where((answer) => answer).length + (correct ? 1 : 0);
    final passed = score >= test.passAt;
    if (passed && !await _save(_store.pass)) return;
    unawaited(
      Analytics.lessonCompleted(
        lessonType: 'hangul_kurztest',
        lessonId: passed ? 'pass' : 'fail',
      ),
    );
    if (!mounted) return;
    _testAnswers.add(correct);
    _show(_View.testResult);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _loadFailed || _catalog == null) {
      return HangulStartScaffold(
        title: t.hangulStartTitle,
        onBack: _back,
        body: _loading
            ? const Center(
                child: SoriLoadingIndicator(color: HangulStartStyle.deep),
              )
            : Text(
                t.hangulStartLoadError,
                style: HangulStartStyle.body(context, 16),
              ),
        footer: _loading ? null : _primary(t.hangulStartRetry, _load),
      );
    }
    return switch (_view) {
      _View.map => _map(),
      _View.lesson => _lessonScreen(),
      _View.lessonResult => _lessonResult(),
      _View.testIntro => _testIntro(),
      _View.test => _testScreen(),
      _View.testResult => _testResult(),
    };
  }

  Widget _frame({
    required String title,
    required List<Widget> children,
    required Widget footer,
    String? progress,
    String keySuffix = '',
    double? spacing,
  }) => PopScope(
    canPop:
        !_saving &&
        (_view == _View.map ||
            (_view == _View.testIntro &&
                widget.entry == HangulStartEntry.quiz)),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _back();
    },
    child: HangulStartScaffold(
      title: title,
      onBack: _back,
      progress: progress,
      showNavigation: false,
      bodyKey: ValueKey('hangul-start-body-${_view.name}-$keySuffix'),
      onLeave: _stopAudio,
      canLeave: () => !_saving,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing ?? _gap,
        children: [
          ...children,
          if (_audioFailed) _notice(t.hangulStartAudioError),
          if (_saveFailed) _notice(t.hangulStartSaveError),
        ],
      ),
      footer: footer,
    ),
  );

  double get _gap => HangulStartStyle.compact(context) ? 11 : 16;
  Widget _title(String text) => Text(
    text,
    style: HangulStartStyle.heading(
      context,
      HangulStartStyle.compact(context) ? 23 : 27,
    ),
  );
  Widget _body(String text) => Text(
    text,
    style: HangulStartStyle.body(
      context,
      HangulStartStyle.compact(context) ? 17 : 20,
    ),
  );
  Widget _small(String text) => Text(
    text,
    style: HangulStartStyle.body(context, 13, color: HangulStartStyle.muted),
  );
  Widget _primary(String title, VoidCallback? fn) =>
      HangulStartAction(label: title, onTap: _saving ? null : fn);
  Widget _link(String title, VoidCallback fn) => HangulStartAction(
    label: title,
    onTap: _saving ? null : fn,
    kind: HangulStartActionKind.link,
  );
  Widget _footer(String title, VoidCallback? fn, [Widget? secondary]) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [_primary(title, fn), ?secondary],
  );

  Widget _map() {
    final catalog = _catalog!;
    final total = catalog.lessons.length;
    final next = home.nextLesson;
    final complete = <int>{
      for (final lesson in catalog.lessons)
        if (_progress.completed.contains(lesson.id)) lesson.order - 1,
    };
    return _frame(
      title: t.hangulStartTitle,
      progress: '${home.completedCount} / $total',
      spacing: HangulStartStyle.compact(context) ? 6 : 10,
      children: [
        _body(t.hangulStartMapSummary),
        HangulStartProgressMarks(
          length: total,
          caption: t.hangulStartDoneCount(home.completedCount, total),
          complete: complete,
          current: next == null ? null : next.order - 1,
        ),
        for (final (index, band) in catalog.bands.indexed)
          _band(index, band, next),
      ],
      footer: _primary(
        next == null
            ? t.hangulStartContinueA11
            : _progress.started
            ? t.hangulStartResume
            : t.todayStartHangul,
        next == null ? _openA11 : () => _openLesson(next),
      ),
    );
  }

  Widget _band(
    int index,
    FoundationBand band,
    FoundationLesson? next,
  ) => HangulStartPanel(
    padding: const EdgeInsets.fromLTRB(
      Spacing.sm,
      4,
      Spacing.sm,
      Spacing.dense,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 3,
      children: [
        Row(
          children: [
            const Icon(Icons.bookmark, color: HangulStartStyle.wrong, size: 12),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                t.hangulStartBandTitle(index + 1, band.title.pick(language)),
                style: HangulStartStyle.heading(context, 14),
              ),
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, size) {
            final count = HangulStartStyle.largeText(context) ? 2 : 4;
            final width = (size.maxWidth - (count - 1) * 5) / count;
            return Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final id in band.lessonIds)
                  if (_catalog!.lessonById(id) case final lesson?)
                    SizedBox(
                      width: lesson.order == 7 || lesson.order == 14
                          ? width * 2 + 5
                          : width,
                      child: HangulStartTile(
                        selected: _progress.completed.contains(id),
                        current: id == next?.id,
                        label:
                            '${t.hangulStartLessonNoun} ${lesson.order} · ${lesson.title.pick(language)}${_progress.completed.contains(id) ? ' · ${t.hangulStartLessonDone}' : ''}',
                        onTap: _saving ? null : () => _openLesson(lesson),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _small(
                              '${lesson.order}${_progress.completed.contains(id) ? ' ✓' : ''}',
                            ),
                            Text(
                              _preview(lesson),
                              textAlign: TextAlign.center,
                              style: HangulStartStyle.korean(
                                HangulStartStyle.compact(context) ? 12 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      ],
    ),
  );

  String _preview(FoundationLesson lesson) => switch (lesson.order) {
    1 => 'ㅇ+ㅏ ㅓ',
    7 => '나무·모자·바다·다리',
    8 => '가/카/까',
    9 => '다/타/따',
    14 => '문이·밥이',
    _ =>
      (lesson.newJamo.isEmpty ? lesson.newFinals : lesson.newJamo)
          .take(4)
          .join(' '),
  };

  Widget _lessonScreen() {
    final lesson = _lesson!;
    final listening = _stage >= 3;
    final item = _stage == 3
        ? lesson.listen[_item]
        : _stage > 3
        ? lesson.check[_stage - 4]
        : null;
    final wantsCheck = listening && _correct == null;
    final canAdvance = switch (_stage) {
      2 => _matches(lesson.build[_item]),
      >= 3 => !wantsCheck || (_plays > 0 && _selected != null),
      _ => true,
    };
    final children = switch (_stage) {
      0 => [
        _title(t.hangulStartGoal),
        _body(lesson.title.pick(language)),
        _hero(const HangulStartArt('study-tiles', height: 112, onPaper: true)),
      ],
      1 => _teaching(lesson),
      2 => _assembly(lesson.build[_item]),
      _ => _listenExercise(item!, practice: _stage == 3),
    };
    return _frame(
      title: '${t.hangulStartLessonNoun} ${lesson.order}',
      progress: '${_stage + 1} / 7',
      children: [
        HangulStartProgressMarks(
          length: 7,
          current: _stage,
          complete: {for (var i = 0; i < _stage; i++) i},
          caption: '${_stage + 1} / 7',
        ),
        const Align(
          alignment: AlignmentDirectional.centerEnd,
          child: _SpeedChip(),
        ),
        ...children,
      ],
      keySuffix: '${lesson.id}-$_stage-$_item',
      footer: _primary(
        _stage == 0
            ? t.hangulStartBeginLesson
            : wantsCheck
            ? t.hangulStartCheckAnswer
            : t.hangulStartNext,
        _playing || !canAdvance
            ? null
            : wantsCheck
            ? () => setState(() => _correct = _selected == item!.answer)
            : _advanceLesson,
      ),
    );
  }

  List<Widget> _teaching(FoundationLesson lesson) {
    if (_item == lesson.teach.length) {
      return [
        _title(t.hangulStartFinalTitle),
        for (final item in lesson.reading) _reading(item),
      ];
    }
    final card = lesson.teach[_item];
    final first = card.target == '아' && lesson.order == 1;
    final words = lesson.words.where((word) => word.ko == card.target);
    return [
      _title(first ? t.todayFirstSyllable : lesson.title.pick(language)),
      Padding(
        padding: EdgeInsets.only(
          top: HangulStartStyle.compact(context) ? 0 : 10,
        ),
        child: _hero(
          Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 3,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  // l10n: exempt — the Korean teaching formula is identical in both locales.
                  if (first)
                    Text('ㅇ + ㅏ = ', style: HangulStartStyle.korean(32)),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (first)
                        Text(card.target, style: HangulStartStyle.korean(36))
                      else
                        HangulStartPanel(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 14,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                card.target,
                                textAlign: TextAlign.center,
                                style: HangulStartStyle.korean(
                                  card.target.length == 1
                                      ? 86
                                      : card.target.length <= 3
                                      ? 48
                                      : 32,
                                ),
                              ),
                              Text(
                                romanizeKorean(card.target),
                                style: HangulStartStyle.body(
                                  context,
                                  20,
                                  strong: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (first) _small(romanizeKorean(card.target)),
                    ],
                  ),
                ],
              ),
              if (first)
                HangulStartArt(
                  'celadon-a',
                  height: HangulStartStyle.compact(context) ? 69 : 108,
                  onPaper: true,
                ),
            ],
          ),
        ),
      ),
      HangulStartPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [
            _body(
              first
                  ? t.hangulStartFirstSyllableExplanation
                  : card.explain.pick(language),
            ),
            for (final word in words) _body(word.pick(language)),
          ],
        ),
      ),
      SizedBox(
        width: double.infinity,
        child: _listenAction(
          t.hangulStartListenSound,
          () => _listen(card.target),
        ),
      ),
    ];
  }

  Widget _hero(Widget child) => HangulStartPanel(
    wood: true,
    padding: HangulStartStyle.compact(context)
        ? const EdgeInsets.symmetric(
            horizontal: Spacing.control,
            vertical: Spacing.compact,
          )
        : const EdgeInsets.all(12),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: HangulStartStyle.compact(context) ? 130 : 161,
      ),
      child: Center(child: child),
    ),
  );

  Widget _reading(FoundationReading item) => HangulStartPanel(
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.text, style: HangulStartStyle.korean(30)),
              Text(
                '[${item.sound}]',
                style: HangulStartStyle.korean(
                  16,
                  color: HangulStartStyle.muted,
                ),
              ),
              _small(romanizeKorean(item.text)),
            ],
          ),
        ),
        IconButton(
          onPressed: _playing ? null : () => _listen(item.text),
          tooltip: '${t.hangulStartListenWord}: ${item.text}',
          icon: const HangulStartArt('speaker', height: 30, width: 36),
        ),
      ],
    ),
  );

  List<String> _letters(String text) => [
    for (final rune in text.runes)
      if (decomposeHangulSyllable(rune) case (final a, final b, final c)) ...[
        a,
        b,
        if (c.isNotEmpty) c,
      ],
  ];

  bool _matches(String target) {
    final letters = _letters(target);
    return _placed.length == letters.length &&
        _placed.indexed.every((entry) => entry.$2 == letters[entry.$1]);
  }

  List<Widget> _assembly(String target) {
    final letters = _letters(target);
    final options = letters.reversed.toSet();
    final done = _matches(target);
    final full = _placed.length == letters.length;
    return [
      _title(t.hangulStartAssemblyTitle),
      _body(t.hangulStartAssemblyBody),
      _hero(
        Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < letters.length; i++)
                  SizedBox(
                    width: 48,
                    child: HangulStartTile(
                      onTap: i < _placed.length
                          ? () => setState(
                              () => _placed.removeRange(i, _placed.length),
                            )
                          : null,
                      label:
                          '${i + 1}: ${i < _placed.length ? _placed[i] : '–'}',
                      child: Text(
                        i < _placed.length ? _placed[i] : '·',
                        style: HangulStartStyle.korean(25),
                      ),
                    ),
                  ),
              ],
            ),
            if (done || _hint) Text(target, style: HangulStartStyle.korean(34)),
            if (done || _hint) _small(romanizeKorean(target)),
          ],
        ),
      ),
      Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final letter in options)
              SizedBox(
                width: 66,
                child: HangulStartTile(
                  onTap: full
                      ? null
                      : () => setState(() => _placed.add(letter)),
                  child: Text(letter, style: HangulStartStyle.korean(29)),
                ),
              ),
          ],
        ),
      ),
      if (full && !done) _notice(t.hangulStartTryParts),
      _pair(
        HangulStartAction(
          label: t.hangulStartAssemblyReset,
          onTap: () => setState(_placed.clear),
          kind: HangulStartActionKind.quiet,
        ),
        HangulStartAction(
          label: t.hangulStartAssemblyHint,
          onTap: () => setState(() => _hint = true),
          kind: HangulStartActionKind.quiet,
        ),
      ),
    ];
  }

  List<Widget> _listenExercise(
    FoundationChoice item, {
    required bool practice,
  }) => [
    _title(t.hangulStartContrastTitle),
    _gong(
      practice && _plays > 0
          ? t.hangulStartReplaySlow
          : t.hangulStartTestListen,
      () => _listen(
        item.audio,
        rate: practice && _plays > 0 ? .75 : null,
        count: true,
      ),
      small: _correct != null,
    ),
    _choices(item, assisted: practice),
    if (_correct case final correct?)
      _feedback(item, correct, assisted: practice),
  ];

  Widget _gong(String label, VoidCallback? onTap, {bool small = false}) =>
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            HangulStartArt(
              'speaker',
              height: HangulStartStyle.compact(context)
                  ? (small ? 62 : 88)
                  : (small ? 102 : 144),
            ),
            HangulStartAction(
              label: label,
              onTap: _playing ? null : onTap,
              kind: HangulStartActionKind.jade,
            ),
          ],
        ),
      );

  Widget _listenAction(String label, VoidCallback? onTap) => HangulStartAction(
    label: _playing ? t.hangulStartAudioBusy : label,
    onTap: _playing ? null : onTap,
    kind: HangulStartActionKind.jade,
    icon: Icons.play_circle_fill,
  );

  Widget _choices(
    FoundationChoice item, {
    bool assisted = false,
    bool quiz = false,
  }) {
    return LayoutBuilder(
      builder: (context, bounds) {
        final columns = quiz
            ? 2
            : HangulStartStyle.largeText(context)
            ? 1
            : item.options.length <= 3
            ? item.options.length
            : 2;
        final width = (bounds.maxWidth - (columns - 1) * 8) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in item.options)
              SizedBox(
                width: width,
                child: HangulStartTile(
                  selected: _selected == value && _correct != false,
                  incorrect: _selected == value && _correct == false,
                  wood: quiz,
                  minHeight: quiz
                      ? HangulStartStyle.compact(context)
                            ? 66
                            : 91
                      : HangulStartStyle.compact(context)
                      ? 58
                      : 90,
                  onTap: _correct == null
                      ? () => setState(() => _selected = value)
                      : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value,
                        textAlign: TextAlign.center,
                        style: HangulStartStyle.korean(
                          value.length > 2 ? 24 : 32,
                          color: HangulStartStyle.ink,
                        ),
                      ),
                      if (assisted) _small(_assist(value)),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _assist(String value) {
    final hint = switch (value) {
      '가' => t.hangulStartSoundPlain,
      '카' => t.hangulStartSoundAspirated,
      '까' => t.hangulStartSoundTense,
      _ => null,
    };
    final romanization = romanizeKorean(value);
    return hint == null ? romanization : '$romanization · $hint';
  }

  Widget _feedback(
    FoundationChoice item,
    bool correct, {
    required bool assisted,
  }) => _notice(
    correct ? '${t.hangulStartCorrect} ${item.answer}' : t.hangulStartIncorrect,
    correct: correct,
    details: correct
        ? (assisted && item.answer == '카'
              ? _body(t.hangulStartAspiratedFeedback)
              : null)
        : _pair(
            HangulStartAction(
              label: '${t.hangulStartReplayHeard} ${item.answer}',
              onTap: _playing ? null : () => _listen(item.audio),
              kind: HangulStartActionKind.quiet,
            ),
            HangulStartAction(
              label: '${t.hangulStartReplaySelected} $_selected',
              onTap: _playing ? null : () => _listen(_selected!),
              kind: HangulStartActionKind.quiet,
            ),
          ),
  );

  Widget _pair(Widget first, Widget second) =>
      HangulStartStyle.largeText(context)
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [first, second],
        )
      : Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: Spacing.compact),
            Expanded(child: second),
          ],
        );

  Widget _notice(String message, {bool correct = false, Widget? details}) {
    final tint = correct ? HangulStartStyle.jade : HangulStartStyle.wrong;
    final animate =
        TickerMode.valuesOf(context).enabled &&
        (WidgetsBinding.instance.lifecycleState == null ||
            WidgetsBinding.instance.lifecycleState ==
                AppLifecycleState.resumed);
    return Semantics(
      liveRegion: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SoriRadius.xs),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: correct ? HangulStartStyle.mist : HangulStartStyle.rose,
            border: Border(left: BorderSide(color: tint, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 5,
              children: [
                Row(
                  children: [
                    TweenAnimationBuilder<double>(
                      key: ValueKey(message),
                      tween: Tween(begin: .94, end: 1),
                      duration: animate
                          ? SoriMotion.respect(context, HangulStartStyle.settle)
                          : Duration.zero,
                      curve: HangulStartStyle.curve,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: correct
                          ? const HangulStartArt(
                              'correct-check',
                              width: 32,
                              height: 32,
                            )
                          : Icon(Icons.cancel, size: 20, color: tint),
                    ),
                    const SizedBox(width: Spacing.tight),
                    Expanded(
                      child: Text(
                        message,
                        style: HangulStartStyle.body(context, 16, strong: true),
                      ),
                    ),
                  ],
                ),
                ?details,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _testIntro() => _frame(
    title: t.hangulStartTestTitle,
    children: [
      _title(t.hangulStartTestLead),
      _hero(
        const HangulStartArt(
          'test-tiles',
          width: 150,
          height: 106,
          onPaper: true,
        ),
      ),
      HangulStartPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            _body(t.hangulStartTestCount),
            _body(t.hangulStartTestNoRomanization),
            _body(t.hangulStartTestPassing),
          ],
        ),
      ),
    ],
    footer: _footer(
      t.hangulStartTestAction,
      _beginTest,
      _link(t.hangulStartPreferLessons, () => _show(_View.map)),
    ),
  );

  Widget _testScreen() {
    final test = _catalog!.kurztest;
    final index = _testAnswers.length;
    final item = test.items[index];
    final count = '${index + 1} / ${test.items.length}';
    final used = t.hangulStartPlaysLeft(test.maxPlays - _plays, test.maxPlays);
    return _frame(
      title: t.hangulStartTestTitle,
      progress: count,
      keySuffix: '$index',
      children: [
        HangulStartProgressMarks(
          length: test.items.length,
          caption: count,
          current: index,
          dots: true,
          complete: {
            for (final (i, passed) in _testAnswers.indexed)
              if (passed) i,
          },
          failed: {
            for (final (i, passed) in _testAnswers.indexed)
              if (!passed) i,
          },
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 275),
            child: _title(t.hangulStartTestPrompt),
          ),
        ),
        _gong(
          t.hangulStartTestListen,
          _plays >= test.maxPlays
              ? null
              : () => _listen(item.audio, count: true, limit: test.maxPlays),
        ),
        Center(
          child: Text(
            used,
            style: HangulStartStyle.body(
              context,
              HangulStartStyle.compact(context) ? 15 : 19,
              strong: true,
            ),
          ),
        ),
        _choices(item, quiz: true),
      ],
      footer: _primary(
        t.hangulStartCheckAnswer,
        _selected != null && _plays > 0 && !_playing ? _gradeTest : null,
      ),
    );
  }

  FoundationLesson _recommendation() {
    final catalog = _catalog!;
    final missed = [
      for (final (i, correct) in _testAnswers.indexed)
        if (!correct) catalog.kurztest.items[i],
    ];
    final weights = <String, int>{};
    for (final item in missed) {
      final last = decomposeHangulSyllable(item.answer.runes.last);
      final coda = last?.$3;
      final sameOnsetAndVowel =
          item.options.where((value) {
            final other = decomposeHangulSyllable(value.runes.last);
            return last?.$1 == other?.$1 && last?.$2 == other?.$2;
          }).length >=
          2;
      final match = coda != null && coda.isNotEmpty && sameOnsetAndVowel
          ? catalog.lessons
                .where(
                  (lesson) =>
                      lesson.newFinals.contains(coda) ||
                      lesson.reading.any(
                        (reading) => reading.text == item.answer,
                      ),
                )
                .firstOrNull
          : catalog.lessons
                .where(
                  (lesson) =>
                      lesson.teach.any((entry) => entry.target == item.answer),
                )
                .firstOrNull;
      if (match != null) {
        weights.update(match.id, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    final ordered = catalog.lessons.toList()
      ..sort((a, b) {
        final delta = (weights[b.id] ?? 0).compareTo(weights[a.id] ?? 0);
        return delta == 0 ? a.order.compareTo(b.order) : delta;
      });
    return weights.isEmpty ? home.nextLesson ?? ordered.first : ordered.first;
  }

  Widget _testResult() {
    final passed = _testPassed;
    final recommendation = _recommendation();
    final score = _testAnswers.where((answer) => answer).length;
    return _frame(
      title: t.hangulStartTestTitle,
      children: [
        _title(passed ? t.hangulStartTestPassed : t.hangulStartTestPractice),
        _hero(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HangulStartArt(
                passed ? 'celadon-a' : 'study-tiles',
                height: HangulStartStyle.compact(context) ? 75 : 106,
                onPaper: true,
              ),
              Text(
                '$score / ${_testAnswers.length}',
                style: HangulStartStyle.heading(context, 45),
              ),
            ],
          ),
        ),
        if (score < _testAnswers.length)
          _notice(
            '${t.hangulStartReviewTopic}: ${recommendation.title.pick(language)}',
            correct: passed,
          ),
      ],
      footer: _footer(
        passed
            ? t.hangulStartContinueA11
            : '${t.hangulStartLessonNoun} ${recommendation.order}',
        passed ? _openA11 : () => _openLesson(recommendation, resume: false),
        passed ? null : _link(t.hangulStartSkipToA11, _openA11),
      ),
    );
  }

  Widget _lessonResult() => _frame(
    title: t.hangulStartTitle,
    children: [
      _title(home.finished ? t.hangulStartAllDone : t.hangulStartLessonDone),
      _hero(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (home.finished)
              const HangulStartArt('completion-seal', height: 146)
            else
              const HangulStartArt('celadon-a', height: 94, onPaper: true),
            Text(
              '${home.completedCount} / ${_catalog!.lessons.length}',
              style: HangulStartStyle.heading(context, 36),
            ),
          ],
        ),
      ),
    ],
    footer: _footer(
      home.finished ? t.hangulStartContinueA11 : t.hangulStartGoMap,
      home.finished ? _openA11 : () => _show(_View.map),
      _link(
        t.hangulStartReplayLesson,
        () => _openLesson(_lesson!, resume: false),
      ),
    ),
  );
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip();

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: SoriSpeech.speed,
    builder: (context, speed, _) {
      final de = Localizations.localeOf(context).languageCode == 'de';
      String rate(double value) {
        final printed = value == 1 ? '1' : '$value';
        return '${de ? printed.replaceAll('.', ',') : printed}×';
      }

      return PopupMenuButton<double>(
        initialValue: speed,
        onSelected: (value) => unawaited(TtsService.setSpeed(value)),
        itemBuilder: (context) => [
          for (final value in TtsService.speedPresets)
            PopupMenuItem(value: value, child: Text(rate(value))),
        ],
        child: Container(
          constraints: BoxConstraints(
            minHeight: 48,
            minWidth: 48,
            maxWidth: HangulStartStyle.largeText(context) ? 84 : 49,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.dense),
          decoration: BoxDecoration(
            color: HangulStartStyle.paper,
            borderRadius: BorderRadius.circular(SoriRadius.xs),
            border: Border.all(color: HangulStartStyle.seam),
          ),
          child: Text(
            rate(speed),
            style: HangulStartStyle.body(context, 15, strong: true),
          ),
        ),
      );
    },
  );
}
