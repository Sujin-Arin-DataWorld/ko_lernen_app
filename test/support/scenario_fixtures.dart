import 'package:ko_lernen_app/models/scenario.dart';

const scenarioAirportArrivalFixture = Scenario(
  id: 'airport_arrival',
  level: LearnerLevel.a1,
  emoji: '✈️',
  register: Register.polite,
  title: LocalizedText(
    ko: '공항 입국',
    de: 'Einreise am Flughafen',
    en: 'Arriving at the airport',
  ),
  intro: LocalizedText(
    ko: '',
    de: 'Du kommst am Flughafen an und beantwortest die ersten Fragen.',
    en: 'You arrive at the airport and answer the first questions.',
  ),
  vocab: [
    VocabRef(
      korean: '여권',
      aliases: ['패스포트'],
      variants: ['여권을'],
      note: LocalizedText(ko: '여권', de: 'Reisepass', en: 'passport'),
    ),
    VocabRef(
      korean: '처음',
      note: LocalizedText(ko: '처음', de: 'zum ersten Mal', en: 'first time'),
    ),
  ],
  grammarIds: [],
  grammarBlock: GrammarBlock(
    title: LocalizedText(
      ko: 'N(이)세요?',
      de: 'Höflich nach einer Person fragen',
      en: 'Ask politely about a person',
    ),
    explanation: LocalizedText(
      ko: '명사 뒤에 이세요 또는 세요를 붙여 공손하게 물어요.',
      de: 'Mit 이세요 oder 세요 fragst du höflich nach einer Person.',
      en: 'Use 이세요 or 세요 to ask politely about a person.',
    ),
  ),
  dialog: [
    DialogLine(
      speaker: 'officer',
      ko: '여권 보여주세요.',
      de: 'Bitte zeigen Sie Ihren Reisepass.',
      en: 'Please show me your passport.',
    ),
    DialogLine(
      speaker: 'user',
      ko: '네, 여기 있어요.',
      de: 'Ja, hier bitte.',
      en: 'Yes, here you go.',
    ),
  ],
  quests: [
    QuestSpec(
      type: QuestType.hoerverstehen,
      data: {
        'audioKo': '한국 처음이세요?',
        'correctIndex': 0,
        'options': [
          {
            'de': 'Sind Sie zum ersten Mal in Korea?',
            'en': 'Is this your first time in Korea?',
          },
          {
            'de': 'Wie lange bleiben Sie in Korea?',
            'en': 'How long are you staying in Korea?',
          },
        ],
      },
    ),
  ],
  xpReward: 120,
);
