import 'package:ko_lernen_app/models/scenario.dart';

Scenario scene(
  int id, {
  LearnerLevel level = LearnerLevel.a1,
  List<QuestSpec>? quests,
}) => Scenario(
  id: '${level.code}_$id',
  level: level,
  emoji: '',
  register: Register.polite,
  title: const LocalizedText(ko: '', de: '', en: ''),
  intro: const LocalizedText(ko: '', de: '', en: ''),
  vocab: const [],
  grammarIds: const [],
  dialog: const [],
  quests: quests ?? [question(id)],
);

QuestSpec question(int id, {QuestType type = QuestType.satzBauen}) =>
    QuestSpec(id: 'q$id', type: type, data: {'targetKo': '저는 $id 번을 골라요.'});

/// Complete test inventory for route tests whose subject is persistence,
/// layout or recovery. It does not change the scenario under test or authorize
/// malformed inputs. Threshold boundary tests supply their own sparse corpus.
List<Scenario> stockedScenarioCorpus(Scenario subject) => [
  subject,
  scene(9000, level: subject.level, quests: stockQuestions),
];

/// Five distinct prompts per rendered engine, confined to test data.
List<QuestSpec> get stockQuestions => [
  for (final word in ['책', '밥', '물', '집', '방']) ...[
    QuestSpec(
      type: QuestType.hoerverstehen,
      data: {
        'audioKo': '$word 주세요.',
        'correctIndex': 0,
        'options': [
          {'de': word, 'en': word},
          {'de': 'Nein', 'en': 'No'},
        ],
      },
    ),
    QuestSpec(
      type: QuestType.uebersetzen,
      data: {
        'promptDe': word,
        'promptEn': word,
        'correctIndex': 0,
        'options': [
          {'ko': word},
          {'ko': '아니요'},
        ],
      },
    ),
    QuestSpec(type: QuestType.satzBauen, data: {'targetKo': '$word 주세요.'}),
    QuestSpec(type: QuestType.diktat, data: {'targetKo': '$word 주세요.'}),
    QuestSpec(
      type: QuestType.luecken,
      data: {
        'sentence': '${word}___ 주세요.',
        'options': ['을', '에'],
        'correctIndex': 0,
      },
    ),
    QuestSpec(
      type: QuestType.particlePop,
      data: {
        'prefix': word,
        'suffix': ' 주세요.',
        'options': ['을', '에'],
        'correctIndex': 0,
      },
    ),
    QuestSpec(
      type: QuestType.batchimDrop,
      data: {
        'audioKo': word,
        'targetWord': word,
        'targetSyllableIndex': 0,
        'options': [
          {'책': 'ㄱ', '밥': 'ㅂ', '물': 'ㄹ', '집': 'ㅂ', '방': 'ㅇ'}[word],
          'ㄴ',
        ],
        'correctIndex': 0,
      },
    ),
  ],
];

/// Catalog fixtures originally modeled only metadata. Give those lessons
/// renderable stock while preserving IDs, labels and the scenario count.
Scenario stockedCatalogLesson(Scenario s) => Scenario(
  id: s.id,
  level: s.level,
  emoji: s.emoji,
  register: s.register,
  title: s.title,
  intro: s.intro,
  vocab: s.vocab,
  grammarIds: s.grammarIds,
  dialog: s.dialog,
  quests: [...s.quests, ...stockQuestions],
  courseUnitId: s.courseUnitId,
  speechStyle: s.speechStyle,
  relationshipContext: s.relationshipContext,
  intent: s.intent,
  playerCharacterId: s.playerCharacterId,
  participantIds: s.participantIds,
  shelf: s.shelf,
  backdrop: s.backdrop,
  conceptIds: s.conceptIds,
  surfaceFormIds: s.surfaceFormIds,
  grammarBlock: s.grammarBlock,
  culturalNote: s.culturalNote,
  xpReward: s.xpReward,
  sidekick: s.sidekick,
  preferredVoice: s.preferredVoice,
);
