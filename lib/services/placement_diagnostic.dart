/// A short recommendation of where to start, not a certified proficiency test.
/// Three independently scored items per band prevent beginner-only success
/// from being relabelled as C1/C2. Productive speaking/writing are not measured.
enum PlacementDiagnosticSkill {
  listening,
  meaning,
  particle,
  wordOrder,
  speechStyle,
  inference,
}

class PlacementDiagnosticQuestion {
  const PlacementDiagnosticQuestion({
    required this.level,
    required this.skill,
    required this.promptDe,
    required this.promptEn,
    this.korean = '',
    required this.choicesDe,
    required this.choicesEn,
    required this.correctIndex,
  });
  final String level;
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
    level: 'a1',
    skill: PlacementDiagnosticSkill.listening,
    promptDe: 'Hör zu und wähle die Bedeutung.',
    promptEn: 'Listen and choose the meaning.',
    korean: '안녕하세요',
    choicesDe: ['Hallo', 'Danke', 'Entschuldigung', 'Bis später'],
    choicesEn: ['Hello', 'Thank you', 'Sorry', 'See you later'],
    correctIndex: 0,
  ),
  PlacementDiagnosticQuestion(
    level: 'a1',
    skill: PlacementDiagnosticSkill.particle,
    promptDe: 'Du sagst, wo du lernst. Welche Partikel passt?',
    promptEn: 'You are saying where you study. Which particle fits?',
    korean: '저는 도서관__ 공부해요.',
    choicesDe: ['까지', '에서', '에게', '부터'],
    choicesEn: ['까지', '에서', '에게', '부터'],
    correctIndex: 1,
  ),
  PlacementDiagnosticQuestion(
    level: 'a1',
    skill: PlacementDiagnosticSkill.meaning,
    promptDe: 'Was bestellt die Person?',
    promptEn: 'What is the person ordering?',
    korean: '물 두 잔 주세요.',
    choicesDe: [
      'Eine Flasche Wasser',
      'Zwei Tassen Kaffee',
      'Zwei Gläser Wasser',
      'Ein Glas Wasser',
    ],
    choicesEn: [
      'One bottle of water',
      'Two cups of coffee',
      'Two glasses of water',
      'One glass of water',
    ],
    correctIndex: 2,
  ),
  PlacementDiagnosticQuestion(
    level: 'a2',
    skill: PlacementDiagnosticSkill.meaning,
    promptDe: 'Was macht die Person zuerst?',
    promptEn: 'What will the person do first?',
    korean: '은행에 들렀다가 친구를 만나러 갈 거예요.',
    choicesDe: [
      'Zu Hause warten',
      'Mit einem Freund zur Bank gehen',
      'Einen Freund treffen',
      'Bei der Bank vorbeigehen',
    ],
    choicesEn: [
      'Wait at home',
      'Go to the bank with a friend',
      'Meet a friend',
      'Stop at the bank',
    ],
    correctIndex: 3,
  ),
  PlacementDiagnosticQuestion(
    level: 'a2',
    skill: PlacementDiagnosticSkill.meaning,
    promptDe: 'Was erlaubt dieser Hinweis?',
    promptEn: 'What does this notice allow?',
    korean: '사진은 찍어도 되지만 플래시는 사용하면 안 돼요.',
    choicesDe: [
      'Fotos ohne Blitz',
      'Nur Fotos mit Blitz',
      'Filmen, aber keine Fotos',
      'Überhaupt keine Fotos',
    ],
    choicesEn: [
      'Photos without flash',
      'Only photos with flash',
      'Filming but no photos',
      'No photos at all',
    ],
    correctIndex: 0,
  ),
  PlacementDiagnosticQuestion(
    level: 'a2',
    skill: PlacementDiagnosticSkill.meaning,
    promptDe: 'Welche Aussage stimmt?',
    promptEn: 'Which statement is correct?',
    korean: '버스보다 지하철이 빠르지만 버스가 더 싸요.',
    choicesDe: [
      'Der Bus ist schneller und teurer.',
      'Die U-Bahn ist schneller, der Bus günstiger.',
      'Beide kosten gleich viel.',
      'Die U-Bahn ist langsamer und günstiger.',
    ],
    choicesEn: [
      'The bus is faster and more expensive.',
      'The subway is faster, the bus is cheaper.',
      'They cost the same.',
      'The subway is slower and cheaper.',
    ],
    correctIndex: 1,
  ),
  PlacementDiagnosticQuestion(
    level: 'b1',
    skill: PlacementDiagnosticSkill.meaning,
    promptDe: 'Welche Information gibt Mina weiter?',
    promptEn: 'What information is Mina passing on?',
    korean: '미나: 준호 씨한테 연락이 왔어요. 기차가 늦어서 회의에 조금 늦겠대요.',
    choicesDe: [
      "Mina kommt wegen einer Zugverspätung später.",
      "Junho sagt die Sitzung wegen der Zugverspätung ab.",
      "Junho erwartet, wegen der Zugverspätung später zu kommen.",
      "Mina bittet Junho, den Beginn der Sitzung zu verschieben.",
    ],
    choicesEn: [
      "Mina will arrive late because her train is delayed.",
      "Junho cancels the meeting because of the train delay.",
      "Junho expects to arrive late because his train is delayed.",
      "Mina asks Junho to move the start of the meeting.",
    ],
    correctIndex: 2,
  ),
  PlacementDiagnosticQuestion(
    level: 'b1',
    skill: PlacementDiagnosticSkill.meaning,
    promptDe: 'Was ist tatsächlich passiert?',
    promptEn: 'What actually happened?',
    korean: '길이 막힐 줄 알았으면 좀 더 일찍 나왔을 텐데요. 결국 약속 시간에 늦었어요.',
    choicesDe: [
      "Die Person fuhr früher los, kam aber dennoch zu spät.",
      "Die Person sagte den Termin wegen des Staus noch rechtzeitig ab.",
      "Die Person hatte mit dem Stau gerechnet und plante ihn ein.",
      "Die Person kam zu spät und hätte lieber früher losfahren sollen.",
    ],
    choicesEn: [
      "The person left earlier but still arrived late.",
      "The person cancelled the appointment in time because of the traffic.",
      "The person had expected the traffic and planned for it.",
      "The person arrived late and wishes they had left earlier.",
    ],
    correctIndex: 3,
  ),
  PlacementDiagnosticQuestion(
    level: 'b1',
    skill: PlacementDiagnosticSkill.speechStyle,
    promptDe: 'Wie reagiert B auf die Einladung?',
    promptEn: 'How does B respond to the invitation?',
    korean: '가: 오늘 저녁에 같이 밥 먹을까요?\n나: 그러고 싶은데 오늘은 선약이 있어요. 다음 주는 어때요?',
    choicesDe: [
      "B lehnt heute ab und schlägt nächste Woche vor.",
      "B sagt für heute zu und möchte auch nächste Woche essen gehen.",
      "B verschiebt eine andere Verabredung, um heute mitzukommen.",
      "B sagt für nächste Woche ab und schlägt stattdessen heute vor.",
    ],
    choicesEn: [
      "B declines today and suggests next week.",
      "B accepts today and wants to eat together next week too.",
      "B moves another appointment so they can join today.",
      "B declines next week and suggests meeting today instead.",
    ],
    correctIndex: 0,
  ),
  PlacementDiagnosticQuestion(
    level: 'b2',
    skill: PlacementDiagnosticSkill.inference,
    promptDe: 'Welche Schlussfolgerung lässt der Bericht zu?',
    promptEn: 'Which conclusion does the report support?',
    korean:
        '새 제도 도입 후 민원은 줄었지만, 같은 기간 이용자 수도 감소했다. 따라서 민원 건수만으로 서비스가 개선됐다고 단정하기는 어렵다.',
    choicesDe: [
      "Die Verbesserung ist durch die Zahlen belegt.",
      "Auch die gesunkene Nutzerzahl muss in die Bewertung einfließen.",
      "Weniger Nutzer zeigen, dass die Servicequalität gesunken sein muss.",
      "Die Beschwerdequote pro Nutzer ist nachweislich zurückgegangen.",
    ],
    choicesEn: [
      "The figures establish an improvement.",
      "The fall in user numbers must also inform the assessment.",
      "Fewer users show that service quality must have deteriorated.",
      "The complaint rate per user has been shown to fall.",
    ],
    correctIndex: 1,
  ),
  PlacementDiagnosticQuestion(
    level: 'b2',
    skill: PlacementDiagnosticSkill.meaning,
    promptDe: 'Welche Erwartung wurde nicht erfüllt?',
    promptEn: 'Which expectation was not met?',
    korean: '가격을 낮추면 판매량이 늘어날 줄 알았는데, 오히려 품질을 의심하는 고객이 많아졌다.',
    choicesDe: [
      "Ein niedrigerer Preis würde Zweifel an der Qualität hervorrufen.",
      "Ein höherer Preis würde den Rückgang der Verkäufe verhindern.",
      "Ein niedrigerer Preis würde zu mehr Verkäufen führen.",
      "Unveränderte Preise würden das Vertrauen der Kunden stärken.",
    ],
    choicesEn: [
      "A lower price would raise doubts about quality.",
      "A higher price would prevent sales from falling.",
      "A lower price would lead to more sales.",
      "Unchanged prices would strengthen customer confidence.",
    ],
    correctIndex: 2,
  ),
  PlacementDiagnosticQuestion(
    level: 'b2',
    skill: PlacementDiagnosticSkill.speechStyle,
    promptDe: 'Welche Antwort fasst die Position zusammen?',
    promptEn: 'Which answer summarizes the position?',
    korean:
        '가: 비용을 줄이려면 교육 시간을 줄여야 하지 않을까요?\n나: 비용도 중요하죠. 다만 교육을 줄였다가 실수가 늘면 오히려 비용이 더 들 수도 있어요.',
    choicesDe: [
      "B hält höhere Kosten für sicher und lehnt jede Kürzung ab.",
      "B erwartet weniger Fehler und befürwortet deshalb die Kürzung.",
      "B stimmt der Kürzung zu, falls die Kosten danach weiter steigen.",
      "B sieht das Kostenziel, warnt aber vor möglichen Folgekosten.",
    ],
    choicesEn: [
      "B considers higher costs certain and rejects any reduction.",
      "B expects fewer mistakes and therefore supports the reduction.",
      "B agrees to the reduction if costs continue to rise afterwards.",
      "B recognizes the cost goal but warns of possible later costs.",
    ],
    correctIndex: 3,
  ),
  PlacementDiagnosticQuestion(
    level: 'c1',
    skill: PlacementDiagnosticSkill.inference,
    promptDe: 'Welche Zusammenfassung bewahrt Quelle und Unsicherheit?',
    promptEn: 'Which summary preserves the source and uncertainty?',
    korean:
        '담당자는 일정이 앞당겨질 수도 있다고 전했다. 다만 이는 협의 중인 안 가운데 하나일 뿐, 결정된 사항은 아니라고 덧붙였다.',
    choicesDe: [
      "Laut der zuständigen Person ist ein früherer Termin eine noch unbeschlossene Option.",
      "Der frühere Termin ist laut der zuständigen Person bereits beschlossen.",
      "Laut der zuständigen Person steht der frühere Termin fest; nur die Bekanntgabe wird noch besprochen.",
      "Die zuständige Person hat einen früheren Termin vorgeschlagen, den die anderen inzwischen ausgeschlossen haben.",
    ],
    choicesEn: [
      "According to the person responsible, an earlier date is an option not yet decided.",
      "The earlier date has been decided, according to the person responsible.",
      "According to the person responsible, the earlier date is settled; only its announcement is under discussion.",
      "The person responsible proposed an earlier date which the others have since ruled out.",
    ],
    correctIndex: 0,
  ),
  PlacementDiagnosticQuestion(
    level: 'c1',
    skill: PlacementDiagnosticSkill.inference,
    promptDe: 'Welche Unterscheidung macht der Text?',
    promptEn: 'What distinction does the passage make?',
    korean:
        '위원들은 자료 공개의 필요성에는 뜻을 같이했다. 그러나 공개 범위까지 합의한 것은 아니었다. 이를 전면 공개에 대한 동의로 해석해서는 곤란하다.',
    choicesDe: [
      "Der Umfang steht fest; nur die Notwendigkeit der Veröffentlichung ist noch umstritten.",
      "Die Veröffentlichung wird für nötig gehalten; ihr Umfang ist noch offen.",
      "Die Beteiligten lehnen eine vollständige Veröffentlichung ab und haben sich auf einen Teil geeinigt.",
      "Die Einigkeit über die Notwendigkeit gilt auch für die vollständige Veröffentlichung aller Unterlagen.",
    ],
    choicesEn: [
      "The scope is settled; only the need for disclosure remains disputed.",
      "Disclosure is considered necessary; its scope remains open.",
      "The participants reject full disclosure and have agreed to release only part.",
      "Agreement on the need for disclosure also covers full disclosure of every document.",
    ],
    correctIndex: 1,
  ),
  PlacementDiagnosticQuestion(
    level: 'c1',
    skill: PlacementDiagnosticSkill.inference,
    promptDe: 'Welche Aussage über die Begründung trifft zu?',
    promptEn: 'Which statement about the reasoning is correct?',
    korean:
        '재택근무를 하는 직원들의 만족도가 높다는 조사 결과가 나왔다. 다만 자발적으로 재택근무를 선택한 직원만 조사했으므로, 근무 방식 자체가 만족도를 높였다고 보기는 어렵다.',
    choicesDe: [
      "Die freiwillige Auswahl belegt die ursächliche Wirkung.",
      "Die Auswahl erlaubt Aussagen über alle Beschäftigten, solange deren Zufriedenheit hoch ist.",
      "Die Auswahl der Befragten begrenzt die Aussage über Ursache und Wirkung.",
      "Die Auswahl macht die Antworten ungültig, sodass auch die berichtete Zufriedenheit als widerlegt gilt.",
    ],
    choicesEn: [
      "Voluntary selection establishes the causal effect.",
      "The selection supports claims about all employees provided satisfaction is high.",
      "The selection of respondents limits the claim about cause and effect.",
      "The selection invalidates the answers, disproving even the reported satisfaction.",
    ],
    correctIndex: 2,
  ),
  PlacementDiagnosticQuestion(
    level: 'c2',
    skill: PlacementDiagnosticSkill.inference,
    promptDe: 'Worauf zielt die Kritik, trotz der eingeräumten Stärke?',
    promptEn:
        'What does the criticism target despite the acknowledged strength?',
    korean:
        '이 보고서가 내세운 수치가 틀렸다는 뜻은 아니다. 오히려 각각의 수치는 정확할 수 있다. 문제는 무엇을 세었느냐보다 무엇을 세지 않기로 했느냐에 있다. 수치의 정확성이 곧 설명의 충분함을 보장하지는 않는다.',
    choicesDe: [
      "Die Auswahl müsse unverändert bleiben, bis die Genauigkeit sämtlicher erhobener Zahlen durch unabhängige Prüfungen widerlegt worden sei.",
      "Die Erklärung scheitert an Rechenfehlern.",
      "Die Auswahl sei unerheblich, sofern die Genauigkeit jeder einzelnen Zahl nachgewiesen werde.",
      "Korrekte Zahlen könnten durch die Auswahl des Gemessenen ein unvollständiges Bild ergeben.",
    ],
    choicesEn: [
      "The selection must remain unchanged until independent checks have disproved the accuracy of all the figures collected.",
      "Calculation errors undermine the explanation.",
      "The selection is irrelevant provided every individual figure is shown to be accurate.",
      "Accurate figures may give an incomplete picture because of what was selected for measurement.",
    ],
    correctIndex: 3,
  ),
  PlacementDiagnosticQuestion(
    level: 'c2',
    skill: PlacementDiagnosticSkill.inference,
    promptDe: 'Welche Lesart erfasst den ironischen Abstand?',
    promptEn: 'Which reading captures the ironic distance?',
    korean:
        '회의에서는 누구나 자유롭게 의견을 내도 된다고 했다. 정작 반대 의견이 나오자 “그 문제는 이미 충분히 논의했다”는 말로 발언을 끊었다. 참으로 열린 토론이었다.',
    choicesDe: [
      "Der Schlusssatz kritisiert ironisch die nur behauptete Offenheit.",
      "Der Schlusssatz lobt die Offenheit, weil bereits früher alle Gegenargumente erörtert worden seien.",
      "Der Schlusssatz kritisiert die Gegenmeinung als unangebracht, nachdem alle Beteiligten zugestimmt hätten.",
      "Der Schlusssatz lobt die Moderation dafür, eine vereinbarte Redezeit für alle gleichermaßen durchzusetzen.",
    ],
    choicesEn: [
      "The final sentence ironically criticizes openness that was merely claimed.",
      "The final sentence praises the openness because all objections had supposedly been discussed earlier.",
      "The final sentence criticizes the dissent as inappropriate after everyone had supposedly agreed.",
      "The final sentence praises the chair for enforcing an agreed speaking time equally for everyone.",
    ],
    correctIndex: 0,
  ),
  PlacementDiagnosticQuestion(
    level: 'c2',
    skill: PlacementDiagnosticSkill.inference,
    promptDe: 'Welche Wiedergabe bewahrt die doppelte Einschränkung?',
    promptEn: 'Which paraphrase preserves both qualifications?',
    korean:
        '정책을 비판하는 이들조차 그 취지까지 부정하는 것은 아니다. 그렇다고 취지에 공감한다는 이유만으로 현재의 수단을 용인해야 한다는 결론이 따라오는 것도 아니다. 목적에 대한 동의와 수단에 대한 평가는 구별되어야 한다.',
    choicesDe: [
      "Die Kritik an den Mitteln bestreitet auch den Zweck.",
      "Man kann den Zweck teilen und die Mittel dennoch ablehnen.",
      "Die Zustimmung zum Zweck rechtfertigt die Mittel vorläufig, bis ein anderer Zweck vereinbart worden ist.",
      "Die Bewertung der Mittel muss ausgesetzt werden, solange Kritiker den Zweck nicht ausdrücklich zurückweisen.",
    ],
    choicesEn: [
      "Criticizing the means also rejects the aim.",
      "One can share the aim yet reject the means.",
      "Agreement with the aim provisionally justifies the means until a different aim is agreed.",
      "Assessment of the means must be suspended unless critics explicitly reject the aim.",
    ],
    correctIndex: 1,
  ),
];

/// Requires at least two of three answers in every band up to the recommendation.
/// Skips, incomplete answers, and malformed indices never contribute evidence.
String recommendPlacement(List<int> answers) {
  var recommendation = 'a1';
  for (final level in const ['a1', 'a2', 'b1', 'b2', 'c1', 'c2']) {
    var correct = 0;
    for (var i = 0; i < placementDiagnosticQuestions.length; i++) {
      final question = placementDiagnosticQuestions[i];
      if (question.level == level &&
          i < answers.length &&
          answers[i] == question.correctIndex) {
        correct++;
      }
    }
    if (correct < 2) {
      break;
    }
    recommendation = level;
  }
  return recommendation;
}
