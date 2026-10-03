import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/persona_presentation.dart';
import '../../models/scenario.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/persona_card_motion.dart';
import '../../widgets/sori/persona_portrait.dart';
import '../../widgets/sori/tokens.dart';
import 'persona_dialogue_index.dart';

Future<void> showPersonaProfile({
  required BuildContext context,
  required PersonaPresentation person,
  required Future<PersonaDialogueIndex> dialogues,
  required Future<PersonaDialogueIndex> Function() reload,
  LearnerLevel? preferredLevel,
}) async {
  final navigator = Navigator.of(context);
  final result = await showModalBottomSheet<({Scenario scene, bool listening})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => PersonaProfileSheet(
      person: person,
      dialogues: dialogues,
      reload: reload,
      preferredLevel: preferredLevel,
    ),
  );
  if (result == null || !context.mounted) {
    return;
  }
  await navigator.pushNamed(
    result.listening ? '/listening/play' : '/scenario',
    arguments: result.listening ? result.scene : result.scene.id,
  );
}

class PersonaProfileSheet extends StatefulWidget {
  const PersonaProfileSheet({
    super.key,
    required this.person,
    required this.dialogues,
    required this.reload,
    this.preferredLevel,
  });

  final PersonaPresentation person;
  final Future<PersonaDialogueIndex> dialogues;
  final Future<PersonaDialogueIndex> Function() reload;
  final LearnerLevel? preferredLevel;

  @override
  State<PersonaProfileSheet> createState() => _PersonaProfileSheetState();
}

class _PersonaProfileSheetState extends State<PersonaProfileSheet> {
  late Future<PersonaDialogueIndex> _dialogues;
  Scenario? _selected;

  @override
  void initState() {
    super.initState();
    _dialogues = widget.dialogues;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final person = widget.person;
    final name = person.identity.nameFor(lang);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .88,
      child: SingleChildScrollView(
        key: const ValueKey('persona-profile-scroll'),
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          0,
          Spacing.lg,
          Spacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: SoriPersonaPortrait(
                characterId: person.characterId,
                variant: SoriPersonaPortraitVariant.profile,
              ),
            ),
            const SizedBox(height: Spacing.md),
            Text(name, style: text.h2),
            const SizedBox(height: Spacing.md),
            Text(person.intro.pick(lang), style: text.body),
            const SizedBox(height: Spacing.lg),
            Text(t.personaInterests, style: text.h3),
            Text(
              person.interests.map((i) => i.pick(lang)).join(' · '),
              style: text.body,
            ),
            const SizedBox(height: Spacing.lg),
            Text(t.personaConnections, style: text.h3),
            for (final relation in person.relations)
              Text(
                '${PersonaPresentationCatalog.presentationFor(relation.characterId)!.identity.nameFor(lang)} · ${relation.description.pick(lang)}',
                style: text.bodySmall,
              ),
            const SizedBox(height: Spacing.lg),
            FutureBuilder<PersonaDialogueIndex>(
              future: _dialogues,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Column(
                    children: [
                      Text(t.scenariosLoadFailedTitle, style: text.body),
                      SoriButton.outlined(
                        label: t.btnRetry,
                        onTap: () =>
                            setState(() => _dialogues = widget.reload()),
                      ),
                    ],
                  );
                }
                final index = snapshot.data;
                if (index == null) {
                  return const AppLoading();
                }
                final conversations = index.conversationsFor(
                  person.characterId,
                  preferredLevel: widget.preferredLevel,
                );
                final roles = index.rolesFor(
                  person.characterId,
                  preferredLevel: widget.preferredLevel,
                );
                final selected = _selected ?? conversations.firstOrNull;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (selected != null) ...[
                      Text(
                        '${selected.level.code.toUpperCase()} · ${selected.title.pick(lang)}',
                        style: text.h3,
                      ),
                      const SizedBox(height: Spacing.sm),
                      Text(selected.intro.pick(lang), style: text.bodySmall),
                      if (selected.playerCharacterId.isNotEmpty)
                        Text(
                          t.personaYourRole(
                            selected.playerRoleDisplayName(
                              languageCode: Localizations.localeOf(
                                context,
                              ).languageCode,
                              fallbackYou: t.listeningSpeakerYou,
                            ),
                          ),
                          style: text.caption,
                        ),
                      const SizedBox(height: Spacing.md),
                      SoriButton.filled(
                        key: const ValueKey('persona-talk'),
                        label: selected.playerCharacterId == person.characterId
                            ? t.personaPlayRole(name)
                            : t.personaTalkWith(name),
                        onTap: () => Navigator.pop(context, (
                          scene: selected,
                          listening: false,
                        )),
                      ),
                      const SizedBox(height: Spacing.sm),
                      SoriButton.outlined(
                        key: const ValueKey('persona-listen'),
                        label: t.personaListen,
                        onTap: index.hasListeningLesson(selected)
                            ? () => Navigator.pop(context, (
                                scene: selected,
                                listening: true,
                              ))
                            : null,
                      ),
                      if (!index.hasListeningLesson(selected))
                        Text(
                          t.personaListeningUnavailable,
                          style: text.caption,
                        ),
                      const SizedBox(height: Spacing.lg),
                    ],
                    Text(t.personaConversationsWith(name), style: text.h3),
                    if (conversations.isEmpty)
                      Text(t.personaNoConversations, style: text.bodySmall),
                    for (final scene in conversations)
                      _sceneCard(context, scene, selected),
                    if (roles.isNotEmpty) ...[
                      const SizedBox(height: Spacing.lg),
                      Text(t.personaLearnerRoles(name), style: text.h3),
                      Text(t.personaLearnerRolesHint, style: text.bodySmall),
                      for (final scene in roles)
                        _sceneCard(context, scene, selected),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sceneCard(BuildContext context, Scenario scene, Scenario? selected) {
    final lang = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: SoriPersonaCardMotion(
        interactive: true,
        index: 6,
        child: SoriCard(
          key: ValueKey(
            'persona-scene-${scene.id}-${scene.playerCharacterId == widget.person.characterId ? 'role' : 'partner'}',
          ),
          selectable: true,
          selected: selected?.id == scene.id,
          onTap: () => setState(() => _selected = scene),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${scene.level.code.toUpperCase()} · ${scene.title.pick(lang)}',
                  style: SoriTextTheme.of(context).bodySmall,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              AnimatedSwitcher(
                duration: SoriMotion.respect(context, SoriMotion.fast),
                child: selected?.id == scene.id
                    ? const ExcludeSemantics(
                        child: Icon(
                          Icons.check_circle_outline,
                          color: SoriColors.primary,
                        ),
                      )
                    : const SizedBox(width: 24, height: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
