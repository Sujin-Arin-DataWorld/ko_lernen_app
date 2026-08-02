/// Lightweight, no-recording placement check. It offers a useful starting
/// point but never locks a learner out of choosing another mission.
enum PlacementDiagnosticSkill {
  listening,
  meaning,
  particle,
  wordOrder,
  speechStyle,
}

class PlacementDiagnosticQuestion {
  const PlacementDiagnosticQuestion({
    required this.skill,
    required this.promptDe,
    required this.promptEn,
    this.korean = '',
    required this.choicesDe,
    required this.choicesEn,
    required this.correctIndex,
  });

  final PlacementDiagnosticSkill skill;
  final String promptDe;
  final String promptEn;
  final String korean;
  final List<String> choicesDe;
  final List<String> choicesEn;
  final int correctIndex;

  String prompt(String languageCode) =>
      languageCode == 'en' ? promptEn : promptDe;

  List<String> choices(String languageCode) =>
      languageCode == 'en' ? choicesEn : choicesDe;
}

const placementDiagnosticQuestions = <PlacementDiagnosticQuestion>[
  PlacementDiagnosticQuestion(
    skill: PlacementDiagnosticSkill.listening,
    promptDe: 'Hör zu und wähle die Bedeutung.',
    promptEn: 'Listen and choose the meaning.',
    korean: '안녕하세요',
    choicesDe: ['Hallo', 'Danke', 'Entschuldigung', 'Bis später'],
    choicesEn: ['Hello', 'Thank you', 'Sorry', 'See you later'],
    correctIndex: 0,
  ),
  PlacementDiagnosticQuestion(
    skill: PlacementDiagnosticSkill.particle,
    promptDe: 'Wähle die passende Partikel.',
    promptEn: 'Choose the correct particle.',
    korean: '저__ 학생입니다.',
    choicesDe: ['는', '를', '가', '에'],
    choicesEn: ['는', '를', '가', '에'],
    correctIndex: 0,
  ),
  PlacementDiagnosticQuestion(
    skill: PlacementDiagnosticSkill.particle,
    promptDe: 'Wähle die passende Partikel.',
    promptEn: 'Choose the correct particle.',
    korean: '커피__ 주세요.',
    choicesDe: ['를', '은', '이', '와'],
    choicesEn: ['를', '은', '이', '와'],
    correctIndex: 0,
  ),
  PlacementDiagnosticQuestion(
    skill: PlacementDiagnosticSkill.wordOrder,
    promptDe: 'Welche koreanische Satzreihenfolge ist natürlich?',
    promptEn: 'Which Korean word order is natural?',
    choicesDe: [
      '저는 한국어를 공부합니다.',
      '저는 공부합니다 한국어를.',
      '한국어를 저는 합니다 공부.',
      '공부합니다 저는 한국어를.',
    ],
    choicesEn: [
      '저는 한국어를 공부합니다.',
      '저는 공부합니다 한국어를.',
      '한국어를 저는 합니다 공부.',
      '공부합니다 저는 한국어를.',
    ],
    correctIndex: 0,
  ),
  PlacementDiagnosticQuestion(
    skill: PlacementDiagnosticSkill.meaning,
    promptDe: 'Was bedeutet diese freundliche Einladung?',
    promptEn: 'What does this friendly invitation mean?',
    korean: '같이 갈까요?',
    choicesDe: [
      'Sollen wir zusammen gehen?',
      'Ich bin schon gegangen.',
      'Bitte gehen Sie allein.',
      'Wann sind Sie gegangen?',
    ],
    choicesEn: [
      'Shall we go together?',
      'I already went.',
      'Please go alone.',
      'When did you go?',
    ],
    correctIndex: 0,
  ),
  PlacementDiagnosticQuestion(
    skill: PlacementDiagnosticSkill.speechStyle,
    promptDe: 'Welche Form passt sicher zu einer unbekannten Person im Café?',
    promptEn: 'Which form is safe with an unfamiliar person in a café?',
    choicesDe: ['아메리카노 주세요.', '너 커피 줘.', '커피 줘.', '너 뭐 마셔?'],
    choicesEn: ['아메리카노 주세요.', '너 커피 줘.', '커피 줘.', '너 뭐 마셔?'],
    correctIndex: 0,
  ),
  PlacementDiagnosticQuestion(
    skill: PlacementDiagnosticSkill.meaning,
    promptDe: 'Was wird berichtet?',
    promptEn: 'What is being reported?',
    korean: '민수 씨가 늦는다고 했어요.',
    choicesDe: [
      'Minsu sagte, dass er zu spät kommt.',
      'Minsu kommt immer früh.',
      'Ich sagte Minsu, er soll warten.',
      'Minsu arbeitet heute nicht.',
    ],
    choicesEn: [
      'Minsu said that he will be late.',
      'Minsu always arrives early.',
      'I told Minsu to wait.',
      'Minsu is not working today.',
    ],
    correctIndex: 0,
  ),
  PlacementDiagnosticQuestion(
    skill: PlacementDiagnosticSkill.speechStyle,
    promptDe: 'Welche Antwort passt in eine formelle berufliche Nachricht?',
    promptEn: 'Which response fits a formal work message?',
    choicesDe: ['확인 후 다시 연락드리겠습니다.', '응, 알겠어.', '나중에 보자.', '그거 몰라.'],
    choicesEn: ['확인 후 다시 연락드리겠습니다.', '응, 알겠어.', '나중에 보자.', '그거 몰라.'],
    correctIndex: 0,
  ),
];

String recommendPlacement(int correctAnswers) {
  if (correctAnswers <= 3) return 'a1';
  if (correctAnswers <= 5) return 'a2';
  if (correctAnswers <= 7) return 'b1';
  return 'b2';
}
