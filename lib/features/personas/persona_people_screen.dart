import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/persona_presentation.dart';
import '../../models/scenario.dart';
import '../../motion/transitions.dart';
import '../../services/scenario_loader.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/persona_card_motion.dart';
import '../../widgets/sori/persona_portrait.dart';
import '../../widgets/sori/standard_page.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/window_class.dart';
import '../content_learning/content_learning_catalog.dart';
import '../content_learning/content_learning_models.dart';
import 'persona_dialogue_index.dart';
import 'persona_profile_sheet.dart';

class PersonaPeopleEntry extends StatelessWidget {
  const PersonaPeopleEntry({
    super.key,
    this.loadScenarios,
    this.compact = false,
  });

  final Future<List<Scenario>> Function()? loadScenarios;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriPersonaCardMotion(
      interactive: true,
      child: SoriCard(
        key: const ValueKey('persona-people-entry'),
        onTap: () => Navigator.of(context).push(
          SoriTransitions.page<void>(
            (_) => PersonaPeopleScreen(loadScenarios: loadScenarios),
            settings: const RouteSettings(name: '/scenarios/people'),
          ),
        ),
        semanticLabel: t.personaMeetPeopleTitle,
        child: Row(
          children: [
            SizedBox(
              width: compact ? 44 : 64,
              child: SoriPersonaPortrait(
                characterId: 'sujin',
                height: compact ? 72 : 96,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.personaMeetPeopleTitle,
                    style: SoriTextTheme.of(context).h3,
                  ),
                  SizedBox(height: compact ? Spacing.xs : Spacing.sm),
                  Text(
                    compact
                        ? t.personaMeetPeopleCompactSubtitle
                        : t.personaMeetPeopleSubtitle,
                    style: compact
                        ? SoriTextTheme.of(context).caption
                        : SoriTextTheme.of(context).bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class PersonaPeopleScreen extends StatefulWidget {
  const PersonaPeopleScreen({
    super.key,
    this.loadScenarios,
    this.preferredLevel,
  });

  final Future<List<Scenario>> Function()? loadScenarios;
  final LearnerLevel? preferredLevel;

  @override
  State<PersonaPeopleScreen> createState() => _PersonaPeopleScreenState();
}

class _PersonaPeopleScreenState extends State<PersonaPeopleScreen> {
  late Future<PersonaDialogueIndex> _index;

  @override
  void initState() {
    super.initState();
    _index = _loadIndex();
  }

  Future<PersonaDialogueIndex> _loadIndex() async {
    final scenes =
        await (widget.loadScenarios?.call() ?? ScenarioLoader.load());
    if (widget.loadScenarios == null && ScenarioLoader.lastError != null) {
      throw StateError('Scenario source unavailable');
    }
    final lessons = await ContentLearningCatalog.load(
      LearningContentKind.listening,
    );
    return PersonaDialogueIndex.fromCorpus(
      scenes,
      listeningSourceIds: lessons.expand((lesson) => lesson.contentIds),
    );
  }

  Future<PersonaDialogueIndex> _retry() {
    ScenarioLoader.reset();
    ContentLearningCatalog.reset();
    final next = _loadIndex();
    setState(() => _index = next);
    return next;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    return SoriStandardFrame(
      appBarTitle: t.personaMeetPeopleTitle,
      maxWidth: SoriMaxWidth.hub,
      padding: const EdgeInsets.all(Spacing.lg),
      builder: (context, padding) => LayoutBuilder(
        builder: (context, bounds) {
          final available = math.max(1.0, bounds.maxWidth - padding.horizontal);
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final columns = scale > 1.3 || available < 300
              ? 1
              : available >= 600
              ? 3
              : 2;
          final width = (available - Spacing.md * (columns - 1)) / columns;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: padding.copyWith(bottom: Spacing.lg),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.personaMeetPeopleTitle, style: text.h1),
                      const SizedBox(height: Spacing.sm),
                      Text(t.personaMeetPeopleSubtitle, style: text.body),
                      FutureBuilder<PersonaDialogueIndex>(
                        future: _index,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: Spacing.md),
                                Text(
                                  t.scenariosLoadFailedTitle,
                                  style: text.body,
                                ),
                                SoriButton.outlined(
                                  label: t.btnRetry,
                                  onTap: _retry,
                                ),
                              ],
                            );
                          }
                          return snapshot.hasData
                              ? const SizedBox.shrink()
                              : const Padding(
                                  padding: EdgeInsets.only(top: Spacing.md),
                                  child: AppLoading(),
                                );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: padding.copyWith(top: 0),
                sliver: SliverGrid.builder(
                  itemCount: PersonaPresentationCatalog.people.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent: _cardHeight(context, width),
                    crossAxisSpacing: Spacing.md,
                    mainAxisSpacing: Spacing.md,
                  ),
                  itemBuilder: (context, i) {
                    final person = PersonaPresentationCatalog.people[i];
                    final lang = Localizations.localeOf(context).languageCode;
                    return SoriPersonaCardMotion(
                      index: i,
                      interactive: true,
                      child: SoriCard(
                        key: ValueKey('persona-card-${person.characterId}'),
                        padding: const EdgeInsets.all(Spacing.md),
                        onTap: () => showPersonaProfile(
                          context: context,
                          person: person,
                          dialogues: _index,
                          reload: _retry,
                          preferredLevel:
                              widget.preferredLevel ??
                              LearnerLevel.fromCode(Storage.userLevelCode),
                        ),
                        semanticLabel: t.personaOpenProfile(
                          person.identity.nameFor(lang),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: SoriPersonaPortrait(
                                characterId: person.characterId,
                              ),
                            ),
                            const SizedBox(height: Spacing.md),
                            Text(person.identity.nameFor(lang), style: text.h3),
                            const SizedBox(height: Spacing.sm),
                            Text(
                              person.practiceSummary.pick(lang),
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _cardHeight(BuildContext context, double width) {
    final text = SoriTextTheme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    double measured(String value, TextStyle style) => (TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: math.max(1.0, width - Spacing.md * 2))).height;
    final copyHeight = PersonaPresentationCatalog.people
        .map(
          (p) =>
              measured(p.identity.nameFor(lang), text.h3) +
              measured(p.practiceSummary.pick(lang), text.bodySmall),
        )
        .reduce(math.max);
    return 180 + Spacing.md * 3 + Spacing.sm + copyHeight + 4;
  }
}
