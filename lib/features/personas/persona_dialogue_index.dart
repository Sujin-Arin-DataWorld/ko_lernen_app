import '../../models/persona_presentation.dart';
import '../../models/scenario.dart';
import '../scenarios/scenario_quest_stock.dart';

/// One full-corpus assessment decision, then separate interlocutor/learner views.
final class PersonaDialogueIndex {
  PersonaDialogueIndex._(this._playable, this._listeningSourceIds);

  factory PersonaDialogueIndex.fromCorpus(
    Iterable<Scenario> corpus, {
    Iterable<String> listeningSourceIds = const [],
  }) {
    final all = corpus.toList(growable: false);
    final stock = ScenarioQuestStock.fromCorpus(all);
    return PersonaDialogueIndex._(
      List.unmodifiable(all.where(stock.allowsScenario)),
      Set.unmodifiable(listeningSourceIds),
    );
  }

  final List<Scenario> _playable;
  final Set<String> _listeningSourceIds;

  bool hasListeningLesson(Scenario scene) =>
      _listeningSourceIds.contains(scene.id);

  static List<String> interlocutorIds(Scenario scene) {
    final ids = <String>{};
    for (final line in scene.dialog) {
      final speaker = line.speaker.trim().toLowerCase();
      if (speaker == 'user' || speaker == 'narrator') {
        continue;
      }
      final id = scene.resolvedCharacterIdForSpeaker(speaker);
      if (PersonaPresentationCatalog.presentationFor(id) != null) {
        ids.add(id);
      }
    }
    return List.unmodifiable(ids);
  }

  List<Scenario> conversationsFor(String id, {LearnerLevel? preferredLevel}) =>
      _sorted(
        _playable.where((scene) => interlocutorIds(scene).contains(id)),
        preferredLevel,
      );

  List<Scenario> rolesFor(String id, {LearnerLevel? preferredLevel}) => _sorted(
    _playable.where((scene) => scene.playerCharacterId == id),
    preferredLevel,
  );

  List<Scenario> _sorted(Iterable<Scenario> matches, LearnerLevel? preferred) {
    final positions = {
      for (var i = 0; i < _playable.length; i++) _playable[i].id: i,
    };
    final result = matches.toList();
    result.sort((a, b) {
      if (preferred != null) {
        final distance = (a.level.index - preferred.index).abs().compareTo(
          (b.level.index - preferred.index).abs(),
        );
        if (distance != 0) {
          return distance;
        }
      }
      return positions[a.id]!.compareTo(positions[b.id]!);
    });
    return List.unmodifiable(result);
  }
}
