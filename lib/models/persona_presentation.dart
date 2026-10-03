import 'scenario.dart' show LocalizedText;
import 'scenario_character.dart';

/// Public introductions only. Identity and audio remain in the scenario catalog.
class PersonaPresentation {
  const PersonaPresentation({
    required this.characterId,
    required this.assetPath,
    required this.intro,
    required this.practiceSummary,
    required this.interests,
    required this.relations,
  });

  final String characterId;
  final String assetPath;
  final LocalizedText intro, practiceSummary;
  final List<LocalizedText> interests;
  final List<PersonaRelation> relations;
  ScenarioCharacterProfile get identity =>
      ScenarioCharacterCatalog.profileFor(characterId)!;
}

class PersonaRelation {
  const PersonaRelation(this.characterId, this.description);
  final String characterId;
  final LocalizedText description;
}

abstract final class PersonaPresentationCatalog {
  static PersonaPresentation? presentationFor(String id) {
    final normalized = id.trim().toLowerCase();
    for (final person in people) {
      if (person.characterId == normalized) {
        return person;
      }
    }
    return null;
  }

  static const people = <PersonaPresentation>[
    PersonaPresentation(
      characterId: 'sujin',
      assetPath: 'assets/illustrations/personas/v3/sujin.png',
      practiceSummary: LocalizedText(
        ko: '약속과 일상의 작은 실수',
        de: 'Verabredungen und kleine Missgeschicke',
        en: 'Plans and everyday mishaps',
      ),
      intro: LocalizedText(
        ko: '수진은 데이터 분석과 앱 개발을 해요. 함께 약속을 잡고, 작은 실수가 생겼을 때 마음을 전해 봐요.',
        de: 'Sujin arbeitet mit Daten und entwickelt Apps. Verabrede dich mit ihr und übe, nach einem kleinen Missgeschick die richtigen Worte zu finden.',
        en: 'Sujin works with data and develops apps. Make plans with her and practise finding the right words after a small mishap.',
      ),
      interests: [
        LocalizedText(ko: '디저트', de: 'Desserts', en: 'Desserts'),
        LocalizedText(ko: '전시', de: 'Ausstellungen', en: 'Exhibitions'),
      ],
      relations: [
        PersonaRelation(
          'christian',
          LocalizedText(ko: '연인', de: 'Ihr Partner', en: 'Her partner'),
        ),
        PersonaRelation(
          'maya',
          LocalizedText(ko: '친구', de: 'Ihre Freundin', en: 'Her friend'),
        ),
        PersonaRelation(
          'dongsun',
          LocalizedText(ko: '어머니', de: 'Ihre Mutter', en: 'Her mother'),
        ),
        PersonaRelation(
          'byeongcheol',
          LocalizedText(ko: '아버지', de: 'Ihr Vater', en: 'Her father'),
        ),
      ],
    ),
    PersonaPresentation(
      characterId: 'christian',
      assetPath: 'assets/illustrations/personas/v3/christian.png',
      practiceSummary: LocalizedText(
        ko: '함께 계획 정하기와 한국 생활',
        de: 'Gemeinsam planen und in Korea ankommen',
        en: 'Making plans and settling into life in Korea',
      ),
      intro: LocalizedText(
        ko: '크리스티안은 서울에서 공부하는 독일인 교환학생이에요. 수진과 나들이를 계획하고 한국 생활 이야기를 나눠 봐요.',
        de: 'Christian ist als deutscher Austauschstudent in Seoul. Plane mit ihm einen Ausflug mit Sujin oder sprich über den Alltag in Korea.',
        en: 'Christian is a German exchange student in Seoul. Make plans for an outing with him and Sujin, or talk about everyday life in Korea.',
      ),
      interests: [
        LocalizedText(ko: '코딩', de: 'Programmieren', en: 'Coding'),
        LocalizedText(ko: '음악', de: 'Musik', en: 'Music'),
      ],
      relations: [
        PersonaRelation(
          'sujin',
          LocalizedText(ko: '연인', de: 'Seine Partnerin', en: 'His partner'),
        ),
        PersonaRelation(
          'lena',
          LocalizedText(
            ko: '교환학생 친구',
            de: 'Befreundete Austauschstudentin',
            en: 'A fellow exchange student and friend',
          ),
        ),
      ],
    ),
    PersonaPresentation(
      characterId: 'maya',
      assetPath: 'assets/illustrations/personas/v3/maya.png',
      practiceSummary: LocalizedText(
        ko: '음악과 관심사 나누기',
        de: 'Musik und gemeinsame Interessen',
        en: 'Music and shared interests',
      ),
      intro: LocalizedText(
        ko: '마야는 K-pop 마케팅 일을 해요. 좋아하는 음악과 공연 이야기를 나누고, 서로의 취향을 알아가요.',
        de: 'Maya arbeitet im K-Pop-Marketing. Sprich mit ihr über Musik und Konzerte und lerne ihre Vorlieben kennen.',
        en: 'Maya works in K-pop marketing. Talk about music and concerts and get to know each other’s tastes.',
      ),
      interests: [
        LocalizedText(ko: '공연', de: 'Konzerte', en: 'Concerts'),
        LocalizedText(ko: '맛집', de: 'Gutes Essen', en: 'Good food'),
      ],
      relations: [
        PersonaRelation(
          'sujin',
          LocalizedText(ko: '친구', de: 'Ihre Freundin', en: 'Her friend'),
        ),
        PersonaRelation(
          'daniel',
          LocalizedText(
            ko: '함께 프로젝트를 하는 동료',
            de: 'Ihr Projektpartner',
            en: 'Her project partner',
          ),
        ),
      ],
    ),
    PersonaPresentation(
      characterId: 'hyuna',
      assetPath: 'assets/illustrations/personas/v3/hyuna.png',
      practiceSummary: LocalizedText(
        ko: '정보와 의도 확인하기',
        de: 'Informationen und Absichten klären',
        en: 'Clarifying information and intentions',
      ),
      intro: LocalizedText(
        ko: '현아는 도시와 문화를 연구해요. 설명이 모호하거나 정보가 맞지 않을 때, 함께 맥락을 확인하고 뜻을 분명히 해 봐요.',
        de: 'Hyuna forscht zu Stadt und Kultur. Wenn eine Erklärung unklar ist oder eine Information nicht stimmt, kläre mit ihr den Zusammenhang.',
        en: 'Hyuna researches cities and culture. When an explanation is unclear or some information is wrong, work through the context together.',
      ),
      interests: [
        LocalizedText(
          ko: '동네 산책',
          de: 'Spaziergänge im Viertel',
          en: 'Neighbourhood walks',
        ),
        LocalizedText(
          ko: '독립영화',
          de: 'Independent-Filme',
          en: 'Independent films',
        ),
      ],
      relations: [
        PersonaRelation(
          'sujin',
          LocalizedText(ko: '친구', de: 'Ihre Freundin', en: 'Her friend'),
        ),
        PersonaRelation(
          'lena',
          LocalizedText(
            ko: '셰어하우스 이웃',
            de: 'Ihre Mitbewohnerin',
            en: 'Her housemate',
          ),
        ),
      ],
    ),
    PersonaPresentation(
      characterId: 'andrea',
      assetPath: 'assets/illustrations/personas/v3/andrea.png',
      practiceSummary: LocalizedText(
        ko: '업무 요청과 의견 조율',
        de: 'Bitten und Absprachen im Beruf',
        en: 'Requests and agreements at work',
      ),
      intro: LocalizedText(
        ko: '안드레아는 국제 기업에서 재무 업무를 이끌어요. 업무에서는 요청을 분명히 하고, 집에서는 가족과 주말 계획을 세워요.',
        de: 'Andrea leitet den Finanzbereich eines internationalen Unternehmens. Übe mit ihr klare Bitten im Beruf und Wochenendpläne mit der Familie.',
        en: 'Andrea leads a finance team at an international company. Practise clear requests at work and weekend plans with the family.',
      ),
      interests: [
        LocalizedText(ko: '등산', de: 'Wandern', en: 'Hiking'),
        LocalizedText(
          ko: '주말 나들이',
          de: 'Wochenendausflüge',
          en: 'Weekend outings',
        ),
      ],
      relations: [
        PersonaRelation(
          'minho',
          LocalizedText(ko: '남편', de: 'Ihr Mann', en: 'Her husband'),
        ),
        PersonaRelation(
          'jun',
          LocalizedText(ko: '아들', de: 'Ihr Sohn', en: 'Her son'),
        ),
      ],
    ),
    PersonaPresentation(
      characterId: 'lena',
      assetPath: 'assets/illustrations/personas/v3/lena.png',
      practiceSummary: LocalizedText(
        ko: '첫 만남과 생활 이야기',
        de: 'Neue Leute und der Alltag',
        en: 'Meeting people and everyday life',
      ),
      intro: LocalizedText(
        ko: '레나는 한국에 온 독일인 교환학생이에요. 첫 수업에서 말을 걸고, 생활 속 경험과 좋아하는 활동을 나눠 봐요.',
        de: 'Lena ist als deutsche Austauschstudentin in Korea. Komm im ersten Kurs mit ihr ins Gespräch und tausche dich über den Alltag und gemeinsame Aktivitäten aus.',
        en: 'Lena is a German exchange student in Korea. Start a conversation in your first class and share everyday experiences and favourite activities.',
      ),
      interests: [
        LocalizedText(ko: '댄스', de: 'Tanzen', en: 'Dancing'),
        LocalizedText(ko: '여행', de: 'Reisen', en: 'Travel'),
      ],
      relations: [
        PersonaRelation(
          'christian',
          LocalizedText(
            ko: '교환학생 친구',
            de: 'Befreundeter Austauschstudent',
            en: 'A fellow exchange student and friend',
          ),
        ),
        PersonaRelation(
          'hyuna',
          LocalizedText(
            ko: '셰어하우스 이웃',
            de: 'Ihre Mitbewohnerin',
            en: 'Her housemate',
          ),
        ),
      ],
    ),
    PersonaPresentation(
      characterId: 'daniel',
      assetPath: 'assets/illustrations/personas/v3/daniel.png',
      practiceSummary: LocalizedText(
        ko: '여행 계획 바꾸고 대안 찾기',
        de: 'Reisepläne ändern und Alternativen finden',
        en: 'Changing travel plans and finding alternatives',
      ),
      intro: LocalizedText(
        ko: '다니엘은 프리랜서 영상 제작자예요. 여행 중 버스를 놓치거나 비가 올 때, 함께 다음 방법을 찾아봐요.',
        de: 'Daniel produziert freiberuflich Videos. Wenn unterwegs der Bus weg ist oder es regnet, finde mit ihm eine Alternative.',
        en: 'Daniel is a freelance video producer. If you miss a bus or it rains on a trip, work out what to do next together.',
      ),
      interests: [
        LocalizedText(ko: '달리기', de: 'Laufen', en: 'Running'),
        LocalizedText(ko: '영상 촬영', de: 'Filmen', en: 'Filming'),
      ],
      relations: [
        PersonaRelation(
          'maya',
          LocalizedText(
            ko: '함께 프로젝트를 하는 동료',
            de: 'Seine Projektpartnerin',
            en: 'His project partner',
          ),
        ),
        PersonaRelation(
          'hyuna',
          LocalizedText(
            ko: '촬영과 연구 이야기를 나누는 지인',
            de: 'Gesprächspartnerin für Film und Forschung',
            en: 'Someone he discusses filming and research with',
          ),
        ),
      ],
    ),
    PersonaPresentation(
      characterId: 'minho',
      assetPath: 'assets/illustrations/personas/v3/minho.png',
      practiceSummary: LocalizedText(
        ko: '가족과 주말 요리 계획',
        de: 'Kochpläne fürs Familienwochenende',
        en: 'Weekend cooking plans with family',
      ),
      intro: LocalizedText(
        ko: '민호는 IT 회사 팀장이자 안드레아의 남편이에요. 집에서는 요리를 즐겨요. 함께 주말 메뉴와 준비 시간을 정해 봐요.',
        de: 'Minho leitet ein IT-Team und ist Andreas Mann. Zu Hause kocht er gern. Plane mit ihm, was ihr am Wochenende kocht und wann ihr anfangt.',
        en: 'Minho leads an IT team and is Andrea’s husband. He enjoys cooking at home. Decide together what to cook at the weekend and when to start.',
      ),
      interests: [
        LocalizedText(ko: '요리', de: 'Kochen', en: 'Cooking'),
        LocalizedText(ko: '캠핑', de: 'Camping', en: 'Camping'),
      ],
      relations: [
        PersonaRelation(
          'andrea',
          LocalizedText(ko: '아내', de: 'Seine Frau', en: 'His wife'),
        ),
        PersonaRelation(
          'jun',
          LocalizedText(ko: '아들', de: 'Sein Sohn', en: 'His son'),
        ),
      ],
    ),
    PersonaPresentation(
      characterId: 'dongsun',
      assetPath: 'assets/illustrations/personas/v3/dongsun.png',
      practiceSummary: LocalizedText(
        ko: '가족 첫 방문과 선물 인사',
        de: 'Ein erster Familienbesuch mit Geschenk',
        en: 'A first family visit and a gift',
      ),
      intro: LocalizedText(
        ko: '동선은 수진의 어머니이고 주얼리 가게를 운영해요. 첫 방문에서 선물을 건네고 인사를 나누는 장면을 함께 연습해요.',
        de: 'Dongsun ist Sujins Mutter und führt ein Schmuckgeschäft. Übe, sie beim ersten Besuch zu begrüßen und ihr ein Geschenk zu überreichen.',
        en: 'Dongsun is Sujin’s mother and runs a jewellery shop. Practise greeting her and giving her a gift on your first visit.',
      ),
      interests: [
        LocalizedText(ko: '드라마', de: 'Dramen', en: 'TV dramas'),
        LocalizedText(
          ko: '시장 구경',
          de: 'Über Märkte bummeln',
          en: 'Exploring markets',
        ),
      ],
      relations: [
        PersonaRelation(
          'sujin',
          LocalizedText(ko: '딸', de: 'Ihre Tochter', en: 'Her daughter'),
        ),
        PersonaRelation(
          'byeongcheol',
          LocalizedText(ko: '남편', de: 'Ihr Mann', en: 'Her husband'),
        ),
      ],
    ),
    PersonaPresentation(
      characterId: 'byeongcheol',
      assetPath: 'assets/illustrations/personas/v3/byeongcheol.png',
      practiceSummary: LocalizedText(
        ko: '산책하며 필요한 도움 요청',
        de: 'Beim Spaziergang um Hilfe bitten',
        en: 'Asking for help on a walk',
      ),
      intro: LocalizedText(
        ko: '병철은 수진의 아버지이자 전기기술사예요. 함께 산책하며 피곤함을 설명하고 잠깐 쉬자고 말해 봐요.',
        de: 'Byeongcheol ist Sujins Vater und Fachingenieur für Elektrotechnik. Erkläre ihm bei einem Spaziergang, dass du müde bist, und bitte um eine kurze Pause.',
        en: 'Byeongcheol is Sujin’s father and an electrical engineering specialist. On a walk, explain that you are tired and ask for a short break.',
      ),
      interests: [
        LocalizedText(ko: '역사', de: 'Geschichte', en: 'History'),
        LocalizedText(
          ko: '산책과 답사',
          de: 'Spaziergänge und historische Orte',
          en: 'Walks and historic places',
        ),
      ],
      relations: [
        PersonaRelation(
          'sujin',
          LocalizedText(ko: '딸', de: 'Seine Tochter', en: 'His daughter'),
        ),
        PersonaRelation(
          'dongsun',
          LocalizedText(ko: '아내', de: 'Seine Frau', en: 'His wife'),
        ),
      ],
    ),
    PersonaPresentation(
      characterId: 'jun',
      assetPath: 'assets/illustrations/personas/v3/jun-16.png',
      practiceSummary: LocalizedText(
        ko: '게임 약속과 시간 조정',
        de: 'Spielverabredungen und neue Zeiten',
        en: 'Gaming plans and changing times',
      ),
      intro: LocalizedText(
        ko: '준은 16세 고등학교 1학년 학생이에요. 게임과 코딩을 좋아해요. 숙제와 약속이 겹쳤을 때 새 시간을 제안해 봐요.',
        de: 'Jun ist 16 und im ersten Jahr der koreanischen Oberschule. Er mag Spiele und Programmieren. Wenn die Hausaufgaben noch nicht fertig sind, schlage eine neue Zeit zum Spielen vor.',
        en: 'Jun is 16 and in his first year of Korean high school. He enjoys gaming and coding. If homework gets in the way of your plans, suggest a new time to play.',
      ),
      interests: [
        LocalizedText(
          ko: '게임과 코딩',
          de: 'Spiele und Programmieren',
          en: 'Gaming and coding',
        ),
        LocalizedText(ko: '축구', de: 'Fußball', en: 'Football'),
      ],
      relations: [
        PersonaRelation(
          'andrea',
          LocalizedText(ko: '어머니', de: 'Seine Mutter', en: 'His mother'),
        ),
        PersonaRelation(
          'minho',
          LocalizedText(ko: '아버지', de: 'Sein Vater', en: 'His father'),
        ),
      ],
    ),
  ];
}
