import 'scenario.dart' show LocalizedText;
import 'practice_history.dart';

class SmalltalkContextScene {
  const SmalltalkContextScene({
    required this.characterId,
    required this.context,
    required this.prompt,
    this.requiredIntentId,
    this.acceptedExpressionIds = const [],
  });
  final String characterId;

  /// Explicit relationship, familiarity, setting and channel in all languages.
  final LocalizedText context;
  final LocalizedText prompt;
  final String? requiredIntentId;
  final List<String> acceptedExpressionIds;
  factory SmalltalkContextScene.fromJson(Map<String, dynamic> j) =>
      SmalltalkContextScene(
        characterId: j['characterId'] as String,
        context: LocalizedText.fromJson(j['context']),
        prompt: LocalizedText.fromJson(j['prompt']),
        requiredIntentId: j['requiredIntentId'] as String?,
        acceptedExpressionIds: (j['acceptedExpressionIds'] as List? ?? [])
            .cast<String>(),
      );
}

class SmalltalkContextExpression {
  const SmalltalkContextExpression({
    required this.id,
    required this.text,
    required this.effect,
    required this.partnerReply,
    required this.followUp,
    required this.grammarValid,
  });
  final String id;
  final LocalizedText text;
  final LocalizedText effect;
  final LocalizedText partnerReply;
  final LocalizedText followUp;
  final bool grammarValid;
  List<String> get followUpTokens => followUp.ko.split(' ');
  factory SmalltalkContextExpression.fromJson(Map<String, dynamic> j) =>
      SmalltalkContextExpression(
        id: j['id'] as String,
        text: LocalizedText.fromJson(j['text']),
        effect: LocalizedText.fromJson(j['effect']),
        partnerReply: LocalizedText.fromJson(j['partnerReply']),
        followUp: LocalizedText.fromJson(j['followUp']),
        grammarValid: j['grammarValid'] as bool,
      );
}

class SmalltalkContextIntent {
  const SmalltalkContextIntent({
    required this.id,
    required this.label,
    required this.expressions,
  });
  final String id;
  final LocalizedText label;
  final List<SmalltalkContextExpression> expressions;
  factory SmalltalkContextIntent.fromJson(Map<String, dynamic> j) =>
      SmalltalkContextIntent(
        id: j['id'] as String,
        label: LocalizedText.fromJson(j['label']),
        expressions: [
          for (final e in j['expressions'])
            SmalltalkContextExpression.fromJson(e),
        ],
      );
}

class SmalltalkContextCase {
  const SmalltalkContextCase({
    required this.id,
    required this.level,
    required this.topic,
    required this.title,
    required this.base,
    required this.transfer,
    required this.intents,
    this.sourcePhraseIds = const [],
    this.revision = 1,
  });
  final String id;
  final String level;
  final String topic;
  final LocalizedText title;
  final SmalltalkContextScene base;
  final SmalltalkContextScene transfer;
  final List<SmalltalkContextIntent> intents;
  final List<String> sourcePhraseIds;
  final int revision;
  PracticeSource get source => PracticeSource(
    kind: PracticeKind.smalltalk,
    id: id,
    level: level,
    revision: revision,
  );
  factory SmalltalkContextCase.fromJson(Map<String, dynamic> j) =>
      SmalltalkContextCase(
        id: j['id'] as String,
        level: j['level'] as String,
        topic: j['topic'] as String,
        title: LocalizedText.fromJson(j['title']),
        base: SmalltalkContextScene.fromJson(j['base']),
        transfer: SmalltalkContextScene.fromJson(j['transfer']),
        intents: [
          for (final i in j['intents']) SmalltalkContextIntent.fromJson(i),
        ],
        sourcePhraseIds: (j['sourcePhraseIds'] as List? ?? []).cast<String>(),
        revision: j['revision'] as int,
      );
}

class SmalltalkContextRequest {
  const SmalltalkContextRequest({
    this.caseId,
    this.transfer = false,
    this.level,
  });
  final String? caseId;
  final bool transfer;
  final String? level;
}
