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
        ko: '공연·콘텐츠 기획과 표현 조율',
        de: 'Kulturinhalte planen und verantwortungsvoll darstellen',
        en: 'Planning culture content and handling representation',
      ),
      intro: LocalizedText(
        ko: '마야는 K-pop·문화콘텐츠 마케팅 일을 해요. 공연과 지역문화를 소개할 때 무엇을 기록한 것이고 무엇을 새롭게 해석했는지 함께 조율해 봐요.',
        de: 'Maya arbeitet im K-Pop- und Kulturmarketing. Kläre mit ihr, was bei Aufführungen und lokalen Kulturthemen dokumentiert und was neu interpretiert wurde.',
        en: 'Maya works in K-pop and culture marketing. Work with her to distinguish what was documented from what was newly interpreted in performances and local culture.',
      ),
      interests: [
        LocalizedText(ko: '공연', de: 'Aufführungen', en: 'Performances'),
        LocalizedText(
          ko: '콘텐츠 기획',
          de: 'Content-Konzeption',
          en: 'Content planning',
        ),
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
        PersonaRelation(
          'hyuna',
          LocalizedText(
            ko: '문화콘텐츠의 맥락을 함께 점검하는 지인',
            de: 'Gesprächspartnerin für kulturellen Kontext',
            en: 'Someone she checks cultural context with',
          ),
        ),
        PersonaRelation(
          'dongsun',
          LocalizedText(
            ko: '가게 홍보를 함께 의논하는 사장님',
            de: 'Ladeninhaberin, mit der sie Werbung plant',
            en: 'A shop owner she works with on promotion',
          ),
        ),
      ],
    ),
    PersonaPresentation(
      characterId: 'hyuna',
      assetPath: 'assets/illustrations/personas/v3/hyuna.png',
      practiceSummary: LocalizedText(
        ko: '지역문화·기억·자료 구분하기',
        de: 'Lokale Kultur, Erinnerung und Quellen unterscheiden',
        en: 'Separating local culture, memory and sources',
      ),
      intro: LocalizedText(
        ko: '현아는 도시의 기억·지역문화·생활유산을 연구해요. 사람의 기억과 확인된 자료를 구분하고, 전통이 지금 어떻게 이어지고 바뀌는지 함께 살펴봐요.',
        de: 'Hyuna erforscht Stadterinnerungen, lokale Kultur und gelebtes Kulturerbe. Mit ihr unterscheidest du persönliche Erinnerung von belegten Quellen und schaust, wie Traditionen heute weiterleben und sich verändern.',
        en: 'Hyuna researches urban memory, local culture and living heritage. With her, separate personal memory from verified sources and explore how traditions continue and change today.',
      ),
      interests: [
        LocalizedText(
          ko: '동네 산책',
          de: 'Spaziergänge im Viertel',
          en: 'Neighbourhood walks',
        ),
        LocalizedText(
          ko: '생활유산·지역 기록',
          de: 'Alltagskultur und lokale Dokumentation',
          en: 'Living heritage and local records',
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
        PersonaRelation(
          'daniel',
          LocalizedText(
            ko: '지역 촬영 방식을 함께 의논하는 지인',
            de: 'Gesprächspartner für lokale Drehs',
            en: 'Someone she discusses local filming with',
          ),
        ),
        PersonaRelation(
          'byeongcheol',
          LocalizedText(
            ko: '지역 답사를 함께하는 지인',
            de: 'Bekannter für lokale Erkundungen',
            en: 'A local field-walk acquaintance',
          ),
        ),
        PersonaRelation(
          'maya',
          LocalizedText(
            ko: '문화콘텐츠의 맥락을 함께 점검하는 지인',
            de: 'Gesprächspartnerin für kulturellen Kontext',
            en: 'Someone she checks cultural context with',
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
        ko: '촬영 범위와 공개 조건 조율',
        de: 'Drehumfang und Veröffentlichung abstimmen',
        en: 'Agreeing filming and publication boundaries',
      ),
      intro: LocalizedText(
        ko: '다니엘은 프리랜서 다큐·브랜드 영상 제작자예요. 공방·공연·지역 공간을 찍을 때 촬영 허락과 공개 범위를 따로 확인하고 현장에서 대안을 찾아봐요.',
        de: 'Daniel produziert freiberuflich Dokumentar- und Markenvideos. Bei Drehs in Werkstätten, bei Aufführungen oder an lokalen Orten klärt er Aufnahme- und Veröffentlichungsrechte getrennt und findet vor Ort Alternativen.',
        en: 'Daniel is a freelance documentary and brand video producer. When filming workshops, performances or local places, he separates filming consent from publication scope and works out alternatives on location.',
      ),
      interests: [
        LocalizedText(ko: '영상 촬영', de: 'Filmen', en: 'Filming'),
        LocalizedText(
          ko: '공예·공연 기록',
          de: 'Handwerk und Aufführungen dokumentieren',
          en: 'Documenting craft and performance',
        ),
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
        ko: '가게 홍보·수선·손님 배려',
        de: 'Ladenwerbung, Reparaturen und Rücksicht auf Kunden',
        en: 'Shop promotion, repairs and customer care',
      ),
      intro: LocalizedText(
        ko: '동선은 수진의 어머니이고 수원 남문 근처에서 주얼리·수선 가게를 운영해요. 노리개나 매듭 장식 소품도 일부 다루지만, 직접 만든 것과 들여온 상품은 분명히 구분해요.',
        de: 'Dongsun ist Sujins Mutter und führt nahe dem Suwoner Nammun ein Schmuck- und Reparaturgeschäft. Sie verkauft auch einige Stücke mit Norigae- oder Knotendekor und trennt klar zwischen eigener Arbeit und zugekaufter Ware.',
        en: 'Dongsun is Sujin’s mother and runs a jewellery and repair shop near Nammun in Suwon. She also carries some items with norigae or knot decoration and clearly distinguishes her own work from sourced products.',
      ),
      interests: [
        LocalizedText(
          ko: '장신구·수선',
          de: 'Schmuck und Reparaturen',
          en: 'Jewellery and repairs',
        ),
        LocalizedText(
          ko: '시장과 선물',
          de: 'Märkte und Geschenke',
          en: 'Markets and gifts',
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
        PersonaRelation(
          'maya',
          LocalizedText(
            ko: '가게 홍보를 함께 의논하는 지인',
            de: 'Beraterin für Ladenwerbung',
            en: 'Someone she discusses shop promotion with',
          ),
        ),
      ],
    ),
    PersonaPresentation(
      characterId: 'byeongcheol',
      assetPath: 'assets/illustrations/personas/v3/byeongcheol.png',
      practiceSummary: LocalizedText(
        ko: '지역 답사에서 기억과 사실 구분',
        de: 'Erinnerung und Fakten bei lokalen Rundgängen trennen',
        en: 'Separating memory from facts on local walks',
      ),
      intro: LocalizedText(
        ko: '병철은 수진의 아버지이자 전기기술사예요. 수원화성과 지역 답사를 좋아하지만 역사 전문가는 아니어서, 직접 본 기억과 확인된 자료를 구분해 이야기해요.',
        de: 'Byeongcheol ist Sujins Vater und Fachingenieur für Elektrotechnik. Er interessiert sich für Hwaseong und lokale Rundgänge, ist aber kein Historiker und trennt eigene Erinnerungen von belegten Quellen.',
        en: 'Byeongcheol is Sujin’s father and an electrical engineering specialist. He enjoys Hwaseong and local field walks, but he is not a historian and separates personal memory from verified sources.',
      ),
      interests: [
        LocalizedText(
          ko: '수원화성·지역 답사',
          de: 'Hwaseong und lokale Erkundungen',
          en: 'Hwaseong and local field walks',
        ),
        LocalizedText(
          ko: '생활 수리·구조',
          de: 'Alltagsreparaturen und Konstruktion',
          en: 'Practical repairs and structure',
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
        PersonaRelation(
          'hyuna',
          LocalizedText(
            ko: '지역 답사를 함께하는 지인',
            de: 'Bekannte für lokale Erkundungen',
            en: 'A local field-walk acquaintance',
          ),
        ),
      ],
    ),
    PersonaPresentation(
      characterId: 'jun',
      assetPath: 'assets/illustrations/personas/v3/jun-16.png',
      practiceSummary: LocalizedText(
        ko: '학교 발표·게임·시간 조정',
        de: 'Schulpräsentationen, Gaming und Zeitplanung',
        en: 'School presentations, gaming and scheduling',
      ),
      intro: LocalizedText(
        ko: '준은 16세 고등학교 1학년 학생이에요. 게임과 코딩을 좋아하고, 학교 발표에서는 사진과 출처를 직접 정리해요. 약속이 겹치거나 자료가 확실하지 않을 때 이유와 대안을 말해 봐요.',
        de: 'Jun ist 16 und im ersten Jahr der koreanischen Oberschule. Er mag Gaming und Programmieren und bereitet für Schulpräsentationen Fotos und Quellen selbst auf. Übe mit ihm, Gründe und Alternativen zu nennen, wenn Pläne kollidieren oder Informationen noch nicht sicher sind.',
        en: 'Jun is 16 and in his first year of Korean high school. He likes gaming and coding and organises photos and sources for school presentations himself. Practise giving reasons and alternatives when plans clash or information is not yet certain.',
      ),
      interests: [
        LocalizedText(
          ko: '게임과 코딩',
          de: 'Spiele und Programmieren',
          en: 'Gaming and coding',
        ),
        LocalizedText(
          ko: '발표와 디지털 제작',
          de: 'Präsentationen und digitale Projekte',
          en: 'Presentations and digital projects',
        ),
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
        PersonaRelation(
          'christian',
          LocalizedText(
            ko: '코딩과 게임 이야기를 나누는 가족 지인',
            de: 'Familienbekannter für Coding und Gaming',
            en: 'A family acquaintance he talks coding and gaming with',
          ),
        ),
      ],
    ),
  ];
}
