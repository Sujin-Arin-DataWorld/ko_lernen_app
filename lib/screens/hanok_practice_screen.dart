import 'package:flutter/material.dart';
import '../widgets/practice_magic.dart';
import 'package:intl/intl.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/practice_history.dart';
import '../models/smalltalk_context_case.dart';
import '../models/silben_puzzle.dart';
import '../models/silben_practice.dart';
import '../services/practice_history_store.dart';
import '../services/smalltalk_context_catalog.dart';
import '../services/silben_puzzle_loader.dart';
import '../widgets/app_loading.dart';
import '../widgets/practice_guide.dart';
import '../widgets/practice_dokkaebi_art.dart';
import '../widgets/practice_scholar_art.dart';
import '../widgets/practice_motion.dart';
import '../widgets/practice_layout.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/tokens.dart';

class HanokPracticeScreen extends StatefulWidget {
  const HanokPracticeScreen({super.key});
  @override
  State<HanokPracticeScreen> createState() => _HanokPracticeScreenState();
}

class _HanokPracticeScreenState extends State<HanokPracticeScreen> {
  final _session = PracticeHistoryStore.session();
  List<SmalltalkContextCase> _cases = [];
  Map<String, List<SilbenPuzzle>> _puzzles = {};
  bool _loading = true, _failed = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted || !_session.isCurrent) {
      return;
    }
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final results = await Future.wait<Object>([
        SmalltalkContextCatalog.load(),
        SilbenPuzzleLoader.load(),
      ]);
      await PracticeHistoryStore.refresh();
      if (!mounted || !_session.isCurrent) {
        return;
      }
      setState(() {
        _cases = results[0] as List<SmalltalkContextCase>;
        _puzzles = results[1] as Map<String, List<SilbenPuzzle>>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  String _date(DateTime at) => DateFormat.yMMMd(
    Localizations.localeOf(context).languageCode,
  ).format(at.toLocal());
  Widget _item(PracticeItem item, AppL10n t) {
    final lang = Localizations.localeOf(context).languageCode;
    final source = item.source;
    final contextCase = _cases
        .where((c) => c.id == source.id && c.revision == source.revision)
        .firstOrNull;
    final puzzle =
        (_puzzles[source.level.toUpperCase()] ?? const <SilbenPuzzle>[])
            .where((p) => p.id == source.id)
            .firstOrNull;
    final isContext = source.kind == PracticeKind.smalltalk;
    final available = isContext
        ? contextCase != null
        : puzzle != null && source.revision == 1;
    final latest =
        [item.assisted, item.independent].whereType<PracticeAttempt>().toList()
          ..sort((a, b) => b.at.compareTo(a.at));
    final expression = isContext && latest.isNotEmpty
        ? contextCase?.intents
              .expand((i) => i.expressions)
              .where((e) => e.id == latest.first.expressionId)
              .firstOrNull
        : null;
    final assistedWords =
        puzzle?.words
            .where(
              (w) =>
                  item.assisted?.hints.containsKey(silbenWordOccurrence(w)) ??
                  false,
            )
            .toList() ??
        const <SilbenWord>[];
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xl),
      child: PracticeMotionSurface(
        enter: true,
        child: PracticeMagicFrame(
          child: SoriCard(
            key: ValueKey('practice-item-${source.key}'),
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PracticeGuide(
                  dokkaebi: !isContext,
                  scholarPose: item.independent != null
                      ? PracticeScholarPose.bow
                      : PracticeScholarPose.calm,
                  dokkaebiPose: item.independent != null
                      ? PracticeDokkaebiPose.celebrate
                      : item.assisted != null
                      ? PracticeDokkaebiPose.review
                      : PracticeDokkaebiPose.ready,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isContext
                            ? (contextCase?.title.pick(lang) ??
                                  t.practiceUnavailable)
                            : t.practiceSilbenLabel,
                        style: SoriTextTheme.of(context).menuItem,
                      ),
                      Text(
                        source.level.toUpperCase(),
                        style: SoriTextTheme.of(context).eyebrow,
                      ),
                      if (expression != null) ...[
                        Text(
                          expression.text.ko,
                          style: SoriTextTheme.of(context).body,
                        ),
                        Text(
                          expression.text.pick(lang),
                          style: SoriTextTheme.of(context).meta,
                        ),
                      ],
                      if (assistedWords.isNotEmpty)
                        Text(
                          assistedWords
                              .map((w) => '${w.answer} · ${w.meaningFor(lang)}')
                              .join('\n'),
                          style: SoriTextTheme.of(context).body,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.md),
                if (item.viewedAt != null)
                  Text(
                    '${t.practiceViewed} · ${_date(item.viewedAt!)}',
                    style: SoriTextTheme.of(context).meta,
                  ),
                if (item.assisted != null)
                  Text(
                    '${t.practiceAssisted} · ${_date(item.assisted!.at)}',
                    style: SoriTextTheme.of(context).body,
                  ),
                if (item.independent != null)
                  Text(
                    '${t.practiceIndependent} · ${_date(item.independent!.at)}',
                    style: SoriTextTheme.of(context).body,
                  ),
                const SizedBox(height: Spacing.xl),
                if (!available)
                  Text(
                    t.practiceUnavailable,
                    style: SoriTextTheme.of(context).body,
                  )
                else
                  PracticeRaisedAction(
                    child: SoriButton.outlined(
                      key: ValueKey('practice-open-${source.key}'),
                      label: isContext
                          ? t.practiceTransfer
                          : t.practicePuzzleReplay,
                      fullWidth: true,
                      onTap: !_session.isCurrent
                          ? null
                          : () => Navigator.of(context).pushNamed(
                              isContext ? '/smalltalk/context' : '/wordle',
                              arguments: isContext
                                  ? SmalltalkContextRequest(
                                      caseId: source.id,
                                      transfer: true,
                                    )
                                  : SilbenReviewRequest(
                                      level: source.level,
                                      puzzleId: source.id,
                                      revision: source.revision,
                                    ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriStudyFrame(
      adaptTitleAtNormalScale: true,
      title: t.practiceHistoryTitle,
      child: _loading
          ? const AppLoading()
          : ValueListenableBuilder<int>(
              valueListenable: PracticeHistoryStore.changes,
              builder: (context, _, __) {
                List<PracticeItem> items = [];
                var failed = _failed;
                try {
                  if (_session.isCurrent) {
                    items = PracticeHistoryStore.load().items;
                  }
                } catch (_) {
                  failed = true;
                }
                return ListView(
                  children: [
                    if (!_session.isCurrent) Text(t.practiceUnavailable),
                    if (failed) ...[
                      Text(t.practiceReadError),
                      PracticeRaisedAction(
                        child: SoriButton.outlined(
                          label: t.btnRetry,
                          onTap: _load,
                        ),
                      ),
                    ] else if (items.isEmpty) ...[
                      Text(
                        t.practiceHistoryEmpty,
                        style: SoriTextTheme.of(context).body,
                      ),
                      PracticeRaisedAction(
                        child: SoriButton.outlined(
                          label: t.practiceHistoryStart,
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed('/smalltalk/context'),
                        ),
                      ),
                    ] else
                      for (final item in items) _item(item, t),
                  ],
                );
              },
            ),
    );
  }
}
