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
  intro: LocalizedText(ko: '', de: '', en: ''),
  vocab: [],
  grammarIds: [],
  dialog: [],
  quests: [],
  xpReward: 120,
);
