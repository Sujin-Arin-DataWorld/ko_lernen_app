"""KP14 definitions, roles, methods and comparisons. Source is unsigned."""
from phase_task_authoring import choice, free_text, grammar_task, loc, packet, task, write_source
from author_phase_a1_production import production


def kp14():
    rows=[
      ('G4:-는지',loc('문장 안에서 무엇을 확인하거나 모르는지 나타내요. 확인할 변수가 남아 있으므로 검토 요청을 이미 나온 결론으로 바꾸지 않아요.','Embed an unresolved question within a sentence. A request to examine a variable is not a conclusion about it.','Bette eine offene Frage in einen Satz ein. Die Bitte, eine Variable zu prüfen, ist noch kein Ergebnis.'),
       ('어떤 방법이 적절한지 함께 검토합시다.','적절한 방법을 함께 검토하자는 제안','특정 방법의 적절성이 이미 확정됨'),
       ('자료에 누가 포함되는지 확인해 주세요.','포함 대상이 확인할 정보','모든 주민이 포함됐다는 확정')),
      ('G4:-듯이',loc('앞에서 설명한 내용과 같이 뒤 절차를 적용한다고 연결해요. 비슷함이나 준거를 나타내는 것이지 모든 결과가 같다는 보증은 아니에요.','Relate the next step to an earlier explanation. Similarity or a reference point does not guarantee identical results.','Beziehe den nächsten Schritt auf eine frühere Erklärung. Ähnlichkeit oder Bezugspunkt garantieren keine identischen Ergebnisse.'),
       ('앞에서 설명했듯이 조건을 먼저 확인해야 합니다.','앞의 설명을 다시 근거로 삼아 조건 확인을 말함','조건 확인은 생략하라는 뜻'),
       ('예시에서 보았듯이 출처를 따로 표시합니다.','예시에 나온 방식대로 출처를 구분함','예시와 반대로 출처를 없앰')),
      ('G4:-으며',loc('서술어에 붙여 두 성질이나 사실을 연결해요. 무료라는 사실과 이용 가능 범위를 따로 보존하고 자동 인과 관계를 만들지 않아요.','Attach to a predicate to connect properties or facts. Preserve cost and access scope separately without inventing causation.','Verbinde Eigenschaften oder Tatsachen am Prädikat. Erhalte Kosten und Zugangsbereich getrennt, ohne Kausalität hinzuzufügen.'),
       ('이 자료는 무료이며 등록 회원이 이용할 수 있습니다.','무료이고 이용 대상은 등록 회원','무료이므로 모든 비회원도 이용 가능'),
       ('이 표는 익명이며 연구팀 안에서만 공유합니다.','익명인 표를 연구팀 내부에만 공유함','익명이므로 외부에 모두 공개 가능')),
      ('G4:이며',loc('명사 뒤에서 같은 목록에 속하는 대상을 열거해요. 두 집단을 한 사람의 두 자격으로 합치지 않아요.','After a noun, enumerate members of a list. Do not collapse two groups into two roles of one person.','Zähle nach einem Nomen Gruppen einer Liste auf. Mache aus zwei Gruppen nicht zwei Rollen derselben Person.'),
       ('학생이며 교사며 여러 사람이 회의에 왔습니다.','학생과 교사 등 여러 사람이 옴','한 사람이 학생 겸 교사라고만 설명함'),
       ('책이며 노트며 여러 물건을 정리했습니다.','책과 노트 등 여러 물건을 정리함','책만 정리하고 노트는 제외함')),
      ('G4:으로서',loc('사람이 어떤 자격이나 역할로 행동하는지 표시해요. 그 역할이 승인 권한까지 준다는 정보는 따로 확인해야 해요. 수단을 나타내는 으로써와 구별해요.','Mark the capacity in which someone acts. A role does not by itself grant approval authority. Distinguish it from means marked by 으로써.','Kennzeichne die Rolle, in der jemand handelt. Eine Rolle verleiht nicht automatisch Genehmigungsbefugnis. Unterscheide sie vom Mittel mit 으로써.'),
       ('조사 담당자로서 수집 방법을 설명하겠습니다.','조사 담당자 자격으로 설명함','담당자라는 도구를 사용한다는 뜻'),
       ('참가자 대표로서 질문을 전달하겠습니다.','대표의 역할로 질문을 전달함','대표가 모든 요청을 승인했다는 뜻')),
      ('G4:으로써',loc('어떤 수단으로 행동하거나 결과에 접근하는지 표시해요. 사람의 자격을 뜻하는 으로서와 바꾸지 않아요. 수단을 썼다는 말만으로 효과 크기를 확정하지 않아요.','Mark the means used for an action, not a person’s capacity. Using a method alone does not establish its effect size.','Kennzeichne das verwendete Mittel, nicht die Rolle einer Person. Der Einsatz einer Methode allein bestimmt keine Wirkungsgröße.'),
       ('설문으로써 이용자의 의견을 모았습니다.','설문이 의견 수집 수단','설문이 조사 담당자의 직책'),
       ('대화로써 서로의 요구를 확인했습니다.','대화가 요구 확인 수단','대화 참여자에게 승인 권한이 생김')),
      ('G4:이란',loc('지금 논의할 용어의 정의를 제시해요. 이 자료 안의 정의가 일상어 전체나 다른 계약에도 같다고 넓히지 않아요.','Introduce a term’s definition in the current discussion. Do not extend a local definition to all everyday use or other agreements.','Führe die Definition eines Begriffs in dieser Diskussion ein. Übertrage eine lokale Definition nicht auf jeden Alltagsgebrauch oder andere Vereinbarungen.'),
       ('이 보고서에서 참여란 설문 제출을 뜻합니다.','이 보고서의 참여 기준은 설문 제출','모임에 잠깐 온 사람도 모두 설문 참여로 집계'),
       ('이 약관에서 회원이란 등록을 마친 사람을 뜻합니다.','이 약관의 회원은 등록 완료자','등록 전 방문자도 모두 회원')),
      ('G4:에 따라',loc('분류 기준이나 조건에 맞추어 달라짐을 나타내요. 인원에 따른 장소 선택은 인원이 장소 변화를 직접 일으킨다는 과학적 결론이 아니에요.','Mark variation by a criterion or condition. Choosing a room by group size is a rule, not a scientific causal finding.','Kennzeichne Unterschiede nach Kriterium oder Bedingung. Die Raumauswahl nach Gruppengröße ist eine Regel, kein wissenschaftlicher Kausalbefund.'),
       ('참가 인원에 따라 장소를 정합니다.','장소 선택 기준은 참가 인원','장소와 참가 인원은 무관하다는 뜻'),
       ('신청 유형에 따라 필요한 자료가 다릅니다.','자료 요구가 신청 유형별로 다름','모든 유형에서 자료가 반드시 같음')),
      ('G4:에 비하여',loc('명시한 기준과 비교해 차이를 말해요. 비교한 수와 분모, 기간을 유지하고 증가 이유는 따로 확인해요.','Compare with a stated reference. Preserve quantities, denominator and period; investigate the cause separately.','Vergleiche mit einer genannten Bezugsgröße. Erhalte Zahlen, Bezugsmenge und Zeitraum; prüfe Ursachen gesondert.'),
       ('응답자는 지난해에 비하여 열 명 늘었습니다.','지난해 응답자 수보다 열 명 많음','응답률이 십 퍼센트포인트 늘었다는 뜻'),
       ('이번 조사에서는 지난 조사에 비하여 두 명 적게 응답했습니다.','응답자 수가 지난 조사보다 두 명 적음','조사 대상 전체가 두 명 줄었다는 확정')),
      ('G4:-을수록',loc('한 정도가 변할 때 다른 정도가 함께 변하는 관계를 말해요. 같은 시각에 두 사건이 일어났다는 말과 다르며, 이 표현만으로 인과가 입증되지는 않아요.','Describe how one degree varies with another. This is more than simultaneity, but the construction alone does not prove causation.','Beschreibe, wie sich zwei Ausprägungen miteinander verändern. Das ist mehr als Gleichzeitigkeit, beweist aber allein keine Kausalität.'),
       ('이 표에서는 이용 시간이 길수록 만족 점수가 높았습니다.','표 안에서 이용 시간과 점수 사이에 방향 있는 관계가 보임','이용 시간을 늘리면 누구나 반드시 만족한다는 실험 결과'),
       ('이 자료에서는 연습 횟수가 많을수록 실수 수가 적었습니다.','자료 안에서 횟수가 많을 때 실수 수가 적은 경향','같은 날 연습과 실수가 있었다는 말만 함')),
    ]
    tasks=[grammar_task('KP14',i,*row) for i,row in enumerate(rows,1)]
    prod=[
      ('G4:-는지',('내포 의문 / 어떤 방법이 적절하다 → 함께 검토합시다 / -ㄴ지','어떤 방법이 적절한지 함께 검토합시다.','어떤 방법이든 이미 적절하다고 확정했습니다.'),('내포 의문 / 자료에 누가 포함되다 → 확인해 주세요 / -는지','자료에 누가 포함되는지 확인해 주세요.','모든 주민이 포함됐다고 확인했습니다.')),
      ('G4:-듯이',('앞의 설명 참조 / 앞에서 설명하다 → 조건을 먼저 확인해야 합니다 / 과거 -듯이','앞에서 설명했듯이 조건을 먼저 확인해야 합니다.','앞의 설명과 달리 조건 확인은 생략합니다.'),('예시의 방식 참조 / 예시에서 보다 → 출처를 따로 표시합니다 / 과거 -듯이','예시에서 보았듯이 출처를 따로 표시합니다.','예시와 달리 출처를 모두 없앱니다.')),
      ('G4:-으며',('두 서술 연결 / 이 자료는 무료이다 + 등록 회원이 이용할 수 있다 / -며 / 합쇼체','이 자료는 무료이며 등록 회원이 이용할 수 있습니다.','이 자료는 무료이므로 모든 비회원도 이용할 수 있습니다.'),('두 서술 연결 / 이 표는 익명이다 + 연구팀 안에서만 공유하다 / -며 / 합쇼체','이 표는 익명이며 연구팀 안에서만 공유합니다.','이 표는 익명이므로 외부에도 자유롭게 공개합니다.')),
      ('G4:이며',('명사 목록 / 학생 + 교사 + 여러 사람이 회의에 오다 / 이며, 며 / 과거 합쇼체','학생이며 교사며 여러 사람이 회의에 왔습니다.','학생만 회의에 왔습니다.'),('명사 목록 / 책 + 노트 + 여러 물건을 정리하다 / 이며, 며 / 과거 합쇼체','책이며 노트며 여러 물건을 정리했습니다.','책만 정리하고 노트는 제외했습니다.')),
      ('G4:으로서',('자격 / 조사 담당자 + 로서 / 수집 방법을 설명하겠다 / 합쇼체','조사 담당자로서 수집 방법을 설명하겠습니다.','조사 담당자로써 수집 방법을 설명하겠습니다.'),('자격 / 참가자 대표 + 로서 / 질문을 전달하겠다 / 합쇼체','참가자 대표로서 질문을 전달하겠습니다.','참가자 대표로써 질문을 전달하겠습니다.')),
      ('G4:으로써',('수단 / 설문 + 으로써 / 이용자의 의견을 모으다 / 과거 합쇼체','설문으로써 이용자의 의견을 모았습니다.','설문으로서 이용자의 의견을 모았습니다.'),('수단 / 대화 + 로써 / 서로의 요구를 확인하다 / 과거 합쇼체','대화로써 서로의 요구를 확인했습니다.','대화로서 서로의 요구를 확인했습니다.')),
      ('G4:이란',('자료 안의 정의 / 이 보고서에서 참여 + 란 / 설문 제출을 뜻하다 / 합쇼체','이 보고서에서 참여란 설문 제출을 뜻합니다.','어떤 보고서에서도 참여란 잠깐 방문한 사람을 뜻합니다.'),('자료 안의 정의 / 이 약관에서 회원 + 이란 / 등록을 마친 사람을 뜻하다 / 합쇼체','이 약관에서 회원이란 등록을 마친 사람을 뜻합니다.','이 약관에서 회원이란 등록하지 않은 모든 방문자를 뜻합니다.')),
      ('G4:에 따라',('선택 기준 / 참가 인원 + 에 따라 / 장소를 정하다 / 합쇼체','참가 인원에 따라 장소를 정합니다.','참가 인원과 무관하게 장소를 정합니다.'),('요구 기준 / 신청 유형 + 에 따라 / 필요한 자료가 다르다 / 합쇼체','신청 유형에 따라 필요한 자료가 다릅니다.','신청 유형과 관계없이 필요한 자료는 같습니다.')),
      ('G4:에 비하여',('비교 / 응답자는 지난해 + 에 비하여 / 열 명 늘다 / 과거 합쇼체','응답자는 지난해에 비하여 열 명 늘었습니다.','응답률은 지난해에 비하여 십 퍼센트포인트 늘었습니다.'),('비교 / 이번 조사에서는 지난 조사 + 에 비하여 / 두 명 적게 응답하다 / 과거 합쇼체','이번 조사에서는 지난 조사에 비하여 두 명 적게 응답했습니다.','이번 조사 대상 전체가 두 명 줄었습니다.')),
      ('G4:-을수록',('표 안의 경향 / 이 표에서는 이용 시간이 길다 → 만족 점수가 높다 / -ㄹ수록 / 과거 합쇼체','이 표에서는 이용 시간이 길수록 만족 점수가 높았습니다.','이용 시간을 늘리면 누구나 반드시 만족합니다.'),('자료 안의 경향 / 이 자료에서는 연습 횟수가 많다 → 실수 수가 적다 / -을수록 / 과거 합쇼체','이 자료에서는 연습 횟수가 많을수록 실수 수가 적었습니다.','연습과 실수는 같은 날 일어났을 뿐입니다.')),
    ]
    tasks+=production('KP14',tasks,prod)
    h=loc('용어의 포함·제외 기준, 설명자의 역할, 수집 수단을 나누세요. 비교 기준과 분모를 보존하고 함께 변한 수치를 원인·효과로 단정하지 마세요. 요청은 검토의 여지를 남겨요.',
      'Separate inclusion and exclusion rules, the speaker’s role and the collection method. Preserve comparison bases and denominators; co-varying numbers do not establish cause and effect. Leave room to respond to requests.',
      'Trenne Ein- und Ausschlusskriterien, Rolle der erklärenden Person und Erhebungsmethode. Erhalte Vergleichsmaßstab und Bezugsmenge; gemeinsame Veränderungen beweisen keine Ursache und Wirkung. Lasse bei Bitten Raum für eine Antwort.')
    def lecture(place,first,second):
        return packet(f'가상 자료 설명입니다. 저는 {place}의 조사 담당자로서 표의 기준을 설명하겠습니다. 여기서 참여란 설문 제출을 뜻하며, 단순 방문은 포함하지 않습니다. 설문으로써 의견을 모았고 이름은 받지 않았습니다. 지난 조사에서는 {first}명, 이번에는 {second}명이 응답했습니다. 전체 방문자 수는 기록하지 않아 응답률은 계산할 수 없습니다. 표 안에서는 이용 시간이 길수록 만족 점수가 높았지만, 다른 조건은 통제하지 않았으므로 이용 시간이 만족의 원인이라고 확정할 수 없습니다. 같은 날 새 안내판을 설치했다는 사실은 별도의 사건입니다. 앞에서 설명했듯이 숫자를 비교할 때 정의가 같은지 먼저 확인해야 합니다. 다음에는 방문자 수를 따로 셀 수 있는지 검토해 주시겠습니까? 지금 실행을 확정해 달라는 요청은 아닙니다.',[
          choice('definition',loc('참여에 포함되는 것은?', 'What counts as participation?', 'Was zählt als Teilnahme?'),['설문 제출','설문을 내지 않은 단순 방문'],h),
          choice('role',loc('으로서가 표시한 것은?', 'What does 으로서 mark?', 'Was kennzeichnet 으로서?'),['조사 담당자의 자격','설문이라는 수집 수단'],h),
          choice('means',loc('의견 수집 수단은?', 'How were opinions collected?', 'Wie wurden Meinungen erhoben?'),['설문','담당자라는 직책'],h),
          choice('denominator',loc('응답률을 구할 수 없는 이유는?', 'Why can no response rate be calculated?', 'Warum lässt sich keine Antwortquote berechnen?'),['전체 방문자 수 미기록','이번 응답자 수가 전혀 없음'],h),
          choice('relation',loc('정도 간 변화 관계로 제시한 것은?', 'Which statement describes co-variation?', 'Welche Aussage beschreibt einen Zusammenhang zwischen Ausprägungen?'),['이용 시간이 길수록 만족 점수가 높음','같은 날 안내판이 설치됨'],h),
          choice('causal',loc('인과 판단의 한계는?', 'What limits the causal claim?', 'Was begrenzt eine kausale Aussage?'),['다른 조건을 통제하지 않음','모든 다른 조건을 통제한 실험임'],h),
          choice('request',loc('마지막 요청의 범위는?', 'What is the scope of the final request?', 'Worauf bezieht sich die letzte Bitte?'),['방문자 수 집계 가능성 검토','즉시 집계 시행 확정'],h),
        ],'audio')
    tasks.append(task('KP14','listening:01','listening',loc('자료 설명의 정의·자격·수단','Definitions, capacity and means in a data talk','Definition, Rolle und Mittel in einer Datenerklärung'),h,
      lecture('한빛학습관','스무','서른'),lecture('새봄교육관','서른','마흔')))
    def report(place,old,new):
        return packet(f'학습용 가상 보고서 | {place} 안내 제도 개선 검토\n1. 목적과 정의\n여기서 참여자란 설문을 제출한 사람입니다. 방문했지만 제출하지 않은 사람은 제외합니다. 이번 목적은 안내의 이해도를 조사하는 것이며 고용·소비 효과의 측정이 아닙니다.\n2. 방법과 표\n조사 담당자로서 연구팀이 설문으로써 응답을 모았습니다. 이름은 받지 않았습니다.\n기간 | 설문 응답자 수\n지난 조사 | {old}명\n이번 조사 | {new}명\n전체 방문자 수는 두 기간 모두 미기록입니다.\n3. 결과와 한계\n같은 참여 정의로 응답자 수를 비교했습니다. 온라인 화면을 이용하기 어려운 방문자는 표에서 빠질 수 있어 접근 격차가 반론으로 제기되었습니다. 이 한계 때문에 모든 방문자의 만족이나 제도의 고용 효과를 결론으로 삼지 않습니다.\n4. 대안과 제안\n온라인만 유지하는 안과 종이 설문도 함께 제공하는 안을 비교합니다. 화면 이용이 어려운 사람이 응답할 기회라는 기준에서는 종이를 함께 제공하는 안이 대안이 될 수 있습니다. 두 안의 비용과 필요한 인력은 아직 비교하지 못했습니다. 실제 응답 증가 효과도 측정 전입니다. 다음 조사에서 종이 설문도 제공하자는 권고는 비용과 담당 인력의 확인 후 실행 여부를 논의해야 하며 아직 승인되지 않았습니다.',[
          choice('count',loc('응답자 수 비교에서 확인되는 것은?', 'What does the count comparison establish?', 'Was ergibt der Vergleich der Antwortzahlen?'),[f'{old}명에서 {new}명으로 변화','전체 방문자의 응답률이 같은 비율로 변화'],h),
          choice('limit',loc('표가 직접 보여 주지 못하는 것은?', 'What does the table not directly show?', 'Was zeigt die Tabelle nicht unmittelbar?'),['전체 방문자의 만족과 제도 효과','두 기간의 설문 응답자 수'],h),
          choice('counterpoint',loc('접근 격차 반론은 무엇을 지적해요?', 'What does the access-gap objection identify?', 'Worauf weist der Einwand zur Zugangslücke hin?'),['온라인 이용이 어려운 사람의 누락 가능성','모든 방문자가 조사에 포함됐다는 증명'],h),
          choice('proposal',loc('종이 설문 제공의 현재 상태는?', 'What is the status of paper questionnaires?', 'Welchen Status haben Papierfragebögen?'),['비용·인력 확인을 전제로 논의할 권고','이미 승인되고 효과도 확인된 제도'],h),
        ])
    tasks.append(task('KP14','reading:01','reading',loc('보고서의 표와 실행 조건','A report’s table and implementation conditions','Tabelle und Umsetzungsbedingungen eines Berichts'),h,
      report('한빛학습관',20,30),report('새봄교육관',30,40)))
    terms_help=loc('학습용 약관 안의 정의만 적용하세요. 권리·책임·담당자의 권한·예외·요청 기한을 해당 조항으로 확인하고 새로운 법적 결론을 만들지 않아요.',
      'Apply the definitions inside these fictional learning terms. Locate rights, responsibilities, staff authority, exceptions and request deadlines in the clauses without adding legal conclusions.',
      'Wende die Definitionen dieser fiktiven Lernbedingungen an. Belege Rechte, Verantwortlichkeiten, Befugnisse, Ausnahmen und Antragsfristen mit den Klauseln, ohne rechtliche Schlussfolgerungen hinzuzufügen.')
    def terms(place,day):
        return packet(f'학습용 가상 이용 약관 | {place}\n제1조 정의: 회원이란 등록을 마친 사람이며, 방문자란 등록 여부와 무관하게 안내 공간을 찾은 사람입니다. 이 문서에서 자료란 내부 교육 파일을 뜻하며 개인이 가져온 파일은 제외합니다.\n제2조 이용: 회원은 자료를 열람할 수 있습니다. 외부 전달은 금지합니다. 다만 공개용으로 별도 표시된 요약본은 전달할 수 있습니다.\n제3조 역할과 수단: 안내 담당자는 담당자로서 요청을 접수하고 메일로써 접수 번호를 알립니다. 담당자에게 외부 공개를 승인할 권한은 없습니다.\n제4조 정정: 회원은 잘못된 접수 번호의 정정을 요청할 수 있으며 담당자는 원문을 확인해 답변할 책임이 있습니다. {day}까지 번호와 자료 제목을 보내 주시기 바랍니다. 요청 접수는 정정 완료를 뜻하지 않습니다.',[
          choice('scope',loc('여기서 자료에 포함되지 않는 것은?', 'What falls outside the defined materials?', 'Was fällt nicht unter die definierten Materialien?'),['개인이 가져온 파일','내부 교육 파일'],terms_help),
          choice('exception',loc('외부 전달이 허용되는 예외는?', 'Which exception permits forwarding?', 'Welche Ausnahme erlaubt eine Weitergabe?'),['공개용으로 별도 표시된 요약본','담당자가 접수한 모든 파일'],terms_help),
          choice('authority',loc('안내 담당자의 권한은?', 'What is the desk staff authorised to do?', 'Wozu ist das Auskunftspersonal befugt?'),['요청 접수, 공개 승인은 불가','접수와 모든 외부 공개 승인'],terms_help),
          choice('means',loc('접수 번호를 알리는 수단은?', 'How is the receipt number communicated?', 'Wie wird die Eingangsnummer mitgeteilt?'),['메일','담당자라는 자격'],terms_help),
          choice('responsibility',loc('정정 요청 후 담당자의 책임은?', 'What must staff do after a correction request?', 'Was muss die zuständige Person nach einer Korrekturanfrage tun?'),['원문을 확인해 답변','확인 없이 이미 정정됐다고 선언'],terms_help),
        ])
    tasks.append(task('KP14','reading:02','reading',loc('약관의 정의·예외·책임','Definitions, exceptions and responsibility in terms','Definitionen, Ausnahmen und Verantwortung in Bedingungen'),terms_help,
      terms('한빛학습관','화요일'),terms('새봄교육관','목요일')))
    def facts(place,old,new,day):
        return report(place,old,new)['sourceKo']+'\n\n'+terms(place,day)['sourceKo']
    p=facts('한빛학습관',20,30,'화요일');a=facts('새봄교육관',30,40,'목요일')
    writing=loc('목적·정의·수집 방법·비교 결과·한계·제안의 소제목으로 보고서를 쓰세요. 표의 수를 인용하고 응답률과 인과를 계산하거나 만들어 내지 마세요. 온라인 접근 격차라는 반론을 두 대안의 비교와 연결하되 효과를 확정하지 않아요. 약관의 자료 범위·담당자 권한·공개 예외를 설명하는 문단도 쓰세요. 이어 담당자에게 비용·인력 확인을 부탁하고 답할 여지를 남겨요. 자유 의미·논증은 미채점이며 읽고 고쳐 씁니다.',
      'Write a report under purpose, definitions, method, comparison, limits and proposal headings. Cite table counts without inventing response rates or causation. Relate the access-gap objection to both alternatives without promising effects. Include a paragraph explaining the terms’ material scope, staff authority and disclosure exception. Then ask staff to check cost and staffing, leaving room to respond. Free meaning and argumentation remain unscored; review and revise.',
      'Schreibe einen Bericht mit den Überschriften Zweck, Definitionen, Methode, Vergleich, Grenzen und Vorschlag. Nenne Tabellenzahlen, ohne Antwortquoten oder Kausalität zu erfinden. Verbinde den Einwand zur Zugangslücke mit beiden Alternativen, ohne Wirkungen zu versprechen. Erkläre in einem Absatz den Materialumfang, die Befugnisse und die Ausnahme zur Weitergabe aus den Bedingungen. Bitte danach um Prüfung von Kosten und Personal und lasse Antwortspielraum. Freier Inhalt und Argumentation bleiben unbewertet; prüfe und überarbeite.')
    tasks.append(task('KP14','writing:01','writing',loc('자료를 정의하고 제안하는 보고서','A report defining data and proposing a next step','Ein Bericht mit Datendefinition und Vorschlag'),writing,
      packet(p,[free_text('report',loc('소제목을 포함한 보고서와 확인 요청을 쓰세요.','Write the headed report and verification request.','Schreibe den Bericht mit Überschriften und Prüfbitte.'),writing)],'form'),
      packet(a,[free_text('report',loc('소제목을 포함한 보고서와 확인 요청을 쓰세요.','Write the headed report and verification request.','Schreibe den Bericht mit Überschriften und Prüfbitte.'),writing)],'form')))
    speech=loc('가상 조사 담당자로서 비전문 청중에게 합쇼체로 정의→방법→표의 비교→한계→제안을 설명하세요. 자격은 으로서, 수단은 으로써로 구별해요. 같은 내용을 동료에게 해요체로 다시 설명하고 비용·인력의 미상 정보를 질문하세요. A란/…이며/…에 따라의 정보 단위에서 쉬되 논항과 술어를 끊지 않아요. 녹음을 듣고 수정하세요. 의미·억양은 미채점입니다.',
      'As the fictional survey staff member, formally explain definition, method, table comparison, limits and proposal to a non-specialist audience. Distinguish capacity with 으로서 and means with 으로써. Restate politely to a colleague and ask about unknown costs and staffing. Pause at information units in A란/…이며/…에 따라 without separating arguments from predicates. Replay and revise. Meaning and intonation remain unscored.',
      'Erkläre als fiktive zuständige Person einem Laienpublikum förmlich Definition, Methode, Tabellenvergleich, Grenzen und Vorschlag. Trenne Rolle mit 으로서 und Mittel mit 으로써. Erkläre dasselbe einer gleichgestellten Person mit 해요체 und frage nach unbekannten Kosten und Personal. Setze Pausen an Informationseinheiten in A란/…이며/…에 따라, ohne Argument und Prädikat zu trennen. Höre zu und verbessere. Inhalt und Intonation bleiben unbewertet.')
    tasks.append(task('KP14','speaking:01','speaking',loc('표를 설명하고 모르는 기준 묻기','Explain a table and ask about missing criteria','Eine Tabelle erklären und offene Kriterien erfragen'),speech,
      packet(p+'\n청중 질문: 응답률이 얼마나 올랐습니까? 종이 설문은 이미 승인됐습니까?',[]),
      packet(a+'\n청중 질문: 만족이 오른 원인은 무엇입니까? 고용 효과도 확인됐습니까?',[])))
    return tasks


if __name__=='__main__':
    write_source('KP14',kp14())
