"""KP11 comparison and evidence-based review, unsigned until individual review."""
from phase_task_authoring import choice, free_text, grammar_task, loc, packet, task, write_source
from author_phase_a1_production import production


def kp11():
    rows=[
      ('G3:만큼',loc('명사 뒤 만큼은 정도·양의 비교 기준을 나타내요. 무엇을 얼마나 비교하는지 유지하고 모든 면이 같다고 확대하지 않아요.','After a noun, 만큼 supplies a degree or quantity benchmark. Preserve the comparison axis; it does not mean equality in every respect.','Nach einem Nomen nennt 만큼 einen Maßstab für Grad oder Menge. Behalte das Vergleichskriterium bei; es bedeutet keine Gleichheit in jeder Hinsicht.'),
       ('저도 친구만큼 연습했어요.','연습 정도를 친구와 비교함','친구와 성격이 모두 같음'),
       ('이 방도 저 방만큼 넓어요.','방의 넓이를 비교함','두 방의 가격과 위치도 모두 같음')),
      ('G3:-는 만큼',loc('절 뒤 만큼은 앞 절의 정도와 뒤 결과를 연결해요. 이 예에서는 정도의 비례를 보며 과학적 수치 관계를 새로 만들지 않아요.','After a clause, 만큼 relates its degree to the result. These examples express proportionality without establishing a measured scientific formula.','Nach einem Satzteil verbindet 만큼 dessen Ausmaß mit dem Ergebnis. Hier geht es um eine proportionale Beziehung, nicht um eine belegte naturwissenschaftliche Formel.'),
       ('연습한 만큼 자신감이 생겼어요.','연습 정도에 따른 자신감 변화를 말함','연습과 자신감이 전혀 관계없다고 말함'),
       ('준비한 만큼 발표가 수월했어요.','준비 정도와 발표의 수월함을 연결함','준비를 전혀 하지 않았다고 말함')),
      ('G3:같이',loc('여기서는 명사 뒤 같이가 비교 대상과 비슷함을 나타내요. 저같이는 나처럼이지 반드시 나와 같은 장소에서 함께한다는 뜻은 아니에요.','Here, 같이 after a noun marks similarity. 저같이 means like me, not necessarily together with me in the same place.','Hier bezeichnet 같이 nach einem Nomen Ähnlichkeit. 저같이 bedeutet wie ich, nicht zwingend gemeinsam mit mir am selben Ort.'),
       ('동생도 저같이 매운 음식을 좋아해요.','동생과 화자의 음식 선호가 비슷함','두 사람이 반드시 지금 함께 식사 중'),
       ('친구도 저같이 조용한 영화를 좋아해요.','친구와 화자의 영화 선호가 비슷함','친구가 화자와 모든 의견에 동의함')),
      ('G3:대로',loc('명사 뒤 대로는 제시된 기준·방식을 따름을 나타내요. 뒤 행동을 했다는 이유로 기준을 마음대로 바꾸지 않아요.','After a noun, 대로 means following the stated standard or method; preserve that standard.','Nach einem Nomen bedeutet 대로, nach dem genannten Maßstab oder Verfahren zu handeln; ändere diesen nicht.'),
       ('안내문대로 신청서를 썼어요.','안내문의 방법을 따름','안내문과 반대로 작성함'),
       ('계획대로 예산을 나누었어요.','정해진 계획에 따라 배분함','계획을 무시하고 배분함')),
      ('G3:뿐',loc('명사 뒤 뿐은 범위를 그것으로 제한해요. 이것뿐은 이것도 있다는 단순 추가와 달라요.','After a noun, 뿐 limits the range to that item; only this is different from this too.','Nach einem Nomen beschränkt 뿐 den Umfang auf dieses Element; nur dies ist etwas anderes als auch dies.'),
       ('남은 표는 한 장뿐이에요.','남은 표가 한 장으로 한정됨','한 장 외에도 많이 남음'),
       ('지금 확인된 것은 가격뿐이에요.','확인된 정보가 가격으로 제한됨','품질과 효과도 모두 확인됨')),
      ('G3:이고',loc('A이고 B이고의 나열은 이 문맥에서 대상을 가리지 않고 포함해요. 단순 서술격 연결과 구별하고 본문에 없는 집단까지 임의로 추가하지 않아요.','In this context, A이고 B이고 includes the named alternatives regardless of category. Distinguish this from simple copular linking and do not invent additional groups.','In diesem Kontext schließt A이고 B이고 die genannten Gruppen unabhängig von der Kategorie ein. Unterscheide dies von einer einfachen Kopulaverbindung und ergänze keine ungenannten Gruppen.'),
       ('아이이고 어른이고 모두 참여했어요.','아이와 어른을 가리지 않고 참여함','아이만 참여하고 어른은 제외됨'),
       ('평일이고 주말이고 모두 문을 열어요.','평일과 주말을 가리지 않고 운영함','주말에만 운영함')),
      ('G3:-어도',loc('앞 조건을 인정해도 뒤 결론이 유지돼요. 양보된 조건을 행사 취소 같은 반대 결과로 바꾸지 않아요.','The conclusion holds even when the first condition is conceded; preserve its polarity.','Die Schlussaussage gilt auch bei zugestandener Bedingung; erhalte ihre Bejahung oder Verneinung.'),
       ('비가 와도 행사는 열려요.','비가 오는 경우에도 개최함','비가 오면 취소함'),
       ('가격이 싸도 저는 사지 않을 거예요.','싼 경우에도 구매하지 않음','싸면 반드시 구매함')),
      ('G3:-으나',loc('격식 있는 글에서 대조되는 두 사실을 연결해요. 앞 장점이 뒤 한계를 없애는 것은 아니에요.','Link contrasting facts in formal writing; a positive point does not erase the limitation.','Verbinde gegensätzliche Tatsachen in förmlicher Sprache; ein Vorteil hebt die Einschränkung nicht auf.'),
       ('가격은 비싸나 품질은 좋아요.','가격의 단점과 품질의 장점을 대조함','가격이 싸고 품질도 나쁨'),
       ('공간은 작으나 교통은 편리합니다.','작은 공간과 편리한 교통을 대조함','공간이 크지만 교통이 불편함')),
      ('G3:-는 대신에',loc('앞 행동을 대체하거나 조건부로 보상하는 관계를 나타내요. 이 과제에서는 누가 무엇을 대신 맡는지 보존해요.','Express replacement or compensation. Preserve who takes which task in these examples.','Drücke Ersatz oder Ausgleich aus. Behalte bei diesen Aufgaben bei, wer welche Handlung übernimmt.'),
       ('오늘 제가 정리하는 대신에 내일은 동료가 정리해요.','오늘 화자, 내일 동료가 역할을 나눔','오늘과 내일 모두 동료만 정리함'),
       ('택시를 타는 대신에 버스를 탔어요.','택시 대신 버스를 선택함','택시와 버스를 둘 다 탔다고 확정함')),
      ('G3:-는 반면',loc('같은 기준에서 드러나는 두 대상이나 한 대상의 다른 면을 대조해요. 대체 행동이나 교환 조건으로 바꾸지 않아요.','Contrast two options or two aspects of one option. This does not itself mean replacement or an exchange condition.','Stelle zwei Möglichkeiten oder zwei Seiten derselben Möglichkeit gegenüber. Das bedeutet nicht automatisch Ersatz oder eine Tauschbedingung.'),
       ('이 집은 넓은 반면에 교통이 불편해요.','넓이의 장점과 교통의 단점을 대조함','넓이 대신 교통을 구매함'),
       ('이 영화는 짧은 반면에 설명이 부족해요.','길이와 설명의 충실도를 대조함','설명 대신 영화를 취소함')),
      ('G3:-는 편이다',loc('절대적 단정 대신 상대적인 경향을 말해요. 가끔의 예외를 허용하며 항상으로 바꾸지 않아요.','Express a relative tendency rather than an absolute claim; exceptions remain possible.','Drücke eine relative Tendenz statt einer absoluten Aussage aus; Ausnahmen bleiben möglich.'),
       ('저는 아침에 일찍 일어나는 편이에요.','대체로 일찍 일어나는 경향','예외 없이 매일 같은 시각에 일어남'),
       ('이곳은 다른 곳보다 조용한 편이에요.','비교적 조용하다는 평가','소리가 전혀 없다는 보증')),
      ('G3:-어 보이다',loc('겉으로 관찰되는 인상이지 내면이나 성능을 확인한 사실은 아니에요. 사람의 건강·성격을 외관만으로 단정하지 않아요.','Describe an outward impression, not verified internal state or performance. Appearance does not establish health or character.','Beschreibe einen äußeren Eindruck, keinen bestätigten inneren Zustand oder Leistungsnachweis. Aussehen beweist weder Gesundheit noch Charakter.'),
       ('이 의자는 편안해 보여요. 아직 앉아 보지는 않았어요.','겉모습으로 편안하다고 느낀 인상','앉아 보고 편안함을 확인함'),
       ('이 가방은 가벼워 보여요. 무게는 아직 몰라요.','외관상 인상이며 실제 무게 미확인','무게를 재어 가볍다고 확인함')),
      ('G3:-기는',loc('일부를 인정한 뒤 유보나 다른 면을 덧붙일 수 있어요. 뒤 반론을 지워 전면 동의로 바꾸지 않아요.','Concede one point before adding a reservation; do not erase the reservation and claim full agreement.','Gestehe einen Punkt zu und ergänze einen Vorbehalt; mache daraus keine uneingeschränkte Zustimmung.'),
       ('좋기는 하지만 너무 비싸요.','좋다는 점은 인정하나 가격은 유보함','가격까지 전부 만족함'),
       ('편리하기는 하지만 설명이 부족해요.','편리함을 인정하면서 설명의 한계를 지적함','아무 장점도 없다고 말함')),
      ('G3:에 대하여',loc('다루는 주제를 명시해요. 주제라고 해서 곧바로 찬성하거나 인과 관계가 성립하는 것은 아니에요.','State the topic under discussion; naming it does not imply approval or causation.','Nenne das behandelte Thema; seine Nennung bedeutet weder Zustimmung noch einen Kausalzusammenhang.'),
       ('음식 문화에 대하여 이야기했어요.','대화의 주제는 음식 문화','모든 음식 문화에 찬성한다고 보증함'),
       ('대중교통 요금에 대하여 의견을 나누었어요.','논의 주제는 대중교통 요금','요금 인상을 결정했다고 확정함')),
    ]
    tasks=[grammar_task('KP11',i,key,h,p,a) for i,(key,h,p,a) in enumerate(rows,1)]
    prod=[
      ('G3:만큼',('연습 정도 비교 / 저도 / 친구 / 만큼 / 연습하다 / 과거 해요체','저도 친구만큼 연습했어요.','저는 친구보다 전혀 연습하지 않았어요.'),('넓이 비교 / 이 방도 / 저 방 / 만큼 / 넓다 / 해요체','이 방도 저 방만큼 넓어요.','이 방은 저 방보다 좁아요.')),
      ('G3:-는 만큼',('비례한 정도 / 연습하다 → 자신감이 생기다 / -한 만큼 / 과거 해요체','연습한 만큼 자신감이 생겼어요.','연습한 만큼 자신감이 전혀 생기지 않았어요.'),('비례한 정도 / 준비하다 → 발표가 수월하다 / -한 만큼 / 과거 해요체','준비한 만큼 발표가 수월했어요.','준비하지 않아서 발표가 수월했어요.')),
      ('G3:같이',('음식 선호의 유사성 / 동생도 / 저 + 같이 / 매운 음식을 좋아하다 / 해요체','동생도 저같이 매운 음식을 좋아해요.','동생은 저와 달리 매운 음식을 싫어해요.'),('영화 선호의 유사성 / 친구도 / 저 + 같이 / 조용한 영화를 좋아하다 / 해요체','친구도 저같이 조용한 영화를 좋아해요.','친구는 저와 달리 조용한 영화를 싫어해요.')),
      ('G3:대로',('제시된 기준 따름 / 안내문 + 대로 / 신청서를 쓰다 / 과거 해요체','안내문대로 신청서를 썼어요.','안내문과 반대로 신청서를 썼어요.'),('제시된 기준 따름 / 계획 + 대로 / 예산을 나누다 / 과거 해요체','계획대로 예산을 나누었어요.','계획을 무시하고 예산을 나누었어요.')),
      ('G3:뿐',('한정 / 남은 표는 / 한 장 + 뿐 / 이다 / 해요체','남은 표는 한 장뿐이에요.','남은 표는 두 장이에요.'),('한정 / 지금 확인된 것은 / 가격 + 뿐 / 이다 / 해요체','지금 확인된 것은 가격뿐이에요.','지금 가격과 품질이 모두 확인됐어요.')),
      ('G3:이고',('집단을 가리지 않음 / 아이 / 어른 / A이고 B이고 모두 참여하다 / 과거 해요체','아이이고 어른이고 모두 참여했어요.','아이만 참여했어요.'),('날을 가리지 않음 / 평일 / 주말 / A이고 B이고 모두 문을 열다 / 해요체','평일이고 주말이고 모두 문을 열어요.','주말에만 문을 열어요.')),
      ('G3:-어도',('양보 뒤 긍정 유지 / 비가 오다 → 행사는 열리다 / -아도 / 해요체','비가 와도 행사는 열려요.','비가 오면 행사는 취소돼요.'),('양보 뒤 부정 유지 / 가격이 싸다 → 저는 사지 않을 것이다 / -아도 / 해요체','가격이 싸도 저는 사지 않을 거예요.','가격이 싸면 저는 반드시 살 거예요.')),
      ('G3:-으나',('격식 대조 / 가격은 비싸다 / 품질은 좋다 / -으나 / -습니다','가격은 비싸나 품질은 좋습니다.','가격은 싸나 품질은 나쁩니다.'),('격식 대조 / 공간은 작다 / 교통은 편리하다 / -으나 / -습니다','공간은 작으나 교통은 편리합니다.','공간은 크나 교통은 불편합니다.')),
      ('G3:-는 대신에',('역할 교환 / 오늘 제가 정리하다 / 내일은 동료가 정리하다 / -는 대신에 / 해요체','오늘 제가 정리하는 대신에 내일은 동료가 정리해요.','오늘과 내일 모두 동료가 정리해요.'),('대체 선택 / 택시를 타다 대신 버스를 타다 / -는 대신에 / 과거 해요체','택시를 타는 대신에 버스를 탔어요.','택시와 버스를 모두 탔어요.')),
      ('G3:-는 반면',('장단점 대조 / 이 집은 넓다 / 교통이 불편하다 / -은 반면에 / 해요체','이 집은 넓은 반면에 교통이 불편해요.','이 집은 좁고 교통도 불편해요.'),('두 평가 축 대조 / 이 영화는 짧다 / 설명이 부족하다 / -은 반면에 / 해요체','이 영화는 짧은 반면에 설명이 부족해요.','이 영화는 길고 설명이 충분해요.')),
      ('G3:-는 편이다',('상대적 경향 / 저는 아침에 일찍 일어나다 / -는 편이다 / 해요체','저는 아침에 일찍 일어나는 편이에요.','저는 예외 없이 매일 같은 시각에 일어나요.'),('상대적 평가 / 이곳은 다른 곳보다 조용하다 / -은 편이다 / 해요체','이곳은 다른 곳보다 조용한 편이에요.','이곳에는 소리가 전혀 없어요.')),
      ('G3:-어 보이다',('외관상 인상만 / 이 의자는 편안하다 / -어 보이다 / 해요체','이 의자는 편안해 보여요.','이 의자에 앉아 편안함을 확인했어요.'),('외관상 인상만 / 이 가방은 가볍다 / -어 보이다 / 해요체','이 가방은 가벼워 보여요.','이 가방의 무게를 재어 확인했어요.')),
      ('G3:-기는',('일부 인정 뒤 유보 / 좋다 / 너무 비싸다 / -기는 하지만 / 해요체','좋기는 하지만 너무 비싸요.','가격까지 모두 만족해요.'),('일부 인정 뒤 유보 / 편리하다 / 설명이 부족하다 / -기는 하지만 / 해요체','편리하기는 하지만 설명이 부족해요.','편리한 점도 전혀 없어요.')),
      ('G3:에 대하여',('주제 명시 / 음식 문화 / 에 대하여 / 이야기하다 / 과거 해요체','음식 문화에 대하여 이야기했어요.','모든 음식 문화에 찬성했어요.'),('주제 명시 / 대중교통 요금 / 에 대하여 / 의견을 나누다 / 과거 해요체','대중교통 요금에 대하여 의견을 나누었어요.','대중교통 요금 인상을 결정했어요.')),
    ]
    tasks+=production('KP11',tasks,prod)
    h=loc('같은 기준으로 대안을 비교하세요. 가격·길이 같은 제시된 수치, 이용한 사람의 평가, 겉으로 보이는 인상을 나누세요. 일부 장점에 동의해도 한계를 지우지 않고, 취향으로 사람의 성격을 평가하지 않아요.',
      'Compare the options using the same criteria. Separate supplied prices and durations, a user’s evaluation and an outward impression. Agreeing with one advantage does not remove a limitation; preferences do not establish someone’s character.',
      'Vergleiche die Möglichkeiten nach denselben Kriterien. Trenne angegebene Preise und Laufzeiten, Nutzerurteil und äußeren Eindruck. Zustimmung zu einem Vorteil beseitigt keine Einschränkung; Vorlieben beweisen keinen Charakterzug.')
    def comparison(first,second,price1,price2,time1,time2,budget):
        return packet(f'동등한 모임 동료들의 가상 문화 프로그램 선택입니다. 우리는 한 사람당 {budget}원 이내라는 기준을 정했어요. {first}은 {price1}원이고 {time1}분입니다. {second}은 {price2}원이고 {time2}분입니다. 저는 {first}을 봤는데 짧고 편리하기는 하지만 마지막 설명이 부족했어요. {second}은 설명이 자세해 보이지만 아직 보지 않아서 확인할 수 없어요. 포스터에는 해설 시간이 있다고 적혀 있을 뿐이에요. 동료는 자세한 해설을 원하지만 예산을 넘길 수는 없다고 했어요. 저는 이번에는 {first}을 보고, 자세한 해설은 다음 모임에서 무료 글 자료를 함께 읽으며 보완하자고 제안했어요. 아직 모두 동의한 것은 아닙니다.',[
          choice('criterion',loc('공통으로 정한 제한은?', 'What limit did the group agree on?', 'Welche Grenze hat die Gruppe vereinbart?'),[f'한 사람당 {budget}원 이내','길이와 상관없이 비싼 것 선택'],h),
          choice('observed',loc('직접 관람에 근거한 평가는?', 'Which evaluation comes from actual viewing?', 'Welches Urteil beruht auf eigener Betrachtung?'),[first+'의 마지막 설명이 부족했다는 평가',second+'의 설명이 확실히 자세하다는 평가'],h),
          choice('appearance',loc('아직 확인하지 못한 것은?', 'What has not yet been verified?', 'Was wurde noch nicht überprüft?'),[second+'의 실제 설명 충실도',first+'의 제시 가격'],h),
          choice('decision',loc('무료 자료를 함께 읽기는 어떤 상태예요?', 'What is the status of reading the free material together?', 'Welchen Stand hat der Vorschlag zur kostenlosen Lektüre?'),['제안이며 전원 동의 전','전원이 이미 확정한 약속'],h),
        ],'audio')
    tasks.append(task('KP11','listening:01','listening',loc('모임의 문화 프로그램 비교','Compare cultural programmes for a group','Kulturangebote für eine Gruppe vergleichen'),h,
      comparison('달빛 프로그램','바람 프로그램','5000','8000','20','35','6000'),comparison('숲길 프로그램','물결 프로그램','4000','7000','25','40','5000')))
    review_help=loc('리뷰의 기준과 실제 이용 경험을 찾고, 비교하지 않은 대안을 표시하세요. 장점·단점은 서로 다른 기준일 수 있어요. 글쓴이가 좋아했다는 평가를 모두에게 좋은 선택으로 일반화하지 않아요.',
      'Identify the review’s criteria and actual use, then note options not compared. Advantages and disadvantages may concern different criteria. One reviewer’s preference does not establish the best choice for everyone.',
      'Finde Bewertungskriterien und tatsächliche Nutzung und markiere nicht verglichene Alternativen. Vor- und Nachteile können unterschiedliche Kriterien betreffen. Die Vorliebe einer Person ist keine allgemeingültig beste Wahl.')
    def review(item,fee,time):
        return packet(f'가상 문화 프로그램 이용 리뷰\n나는 어제 {item}을 직접 봤다. 표에 적힌 요금은 {fee}원, 실제 상영 시간은 {time}분이었다. 이동 시간이 짧아 마음에 들었고, 화면 글씨도 읽기 쉬운 편이었다. 짧은 반면에 마지막 장면의 배경 설명은 부족했다. 진행자는 해설이 필요하면 무료 글 자료를 읽을 수 있다고 말했다. 나는 아직 그 자료를 읽지 않았다. 자세한 설명이 중요한 사람이라면 다른 프로그램도 비교할 필요가 있다. 이번 글에서는 그 다른 프로그램의 가격이나 내용은 확인하지 못했다.',[
          choice('basis',loc('글쓴이의 직접 경험은?', 'What did the reviewer experience directly?', 'Was hat die schreibende Person selbst erlebt?'),[item+' 관람','무료 글 자료 전체 검토'],review_help),
          choice('limit',loc('직접 지적한 한계는?', 'Which limitation did the reviewer identify?', 'Welche Grenze nennt die Rezension aus eigener Erfahrung?'),['마지막 장면의 배경 설명 부족','모든 프로그램의 가격이 비쌈'],review_help),
          choice('alternative',loc('비교에 빠진 정보는?', 'What information is missing from the comparison?', 'Welche Angaben fehlen für den Vergleich?'),['다른 프로그램의 가격과 내용','이번 프로그램의 제시 요금'],review_help),
          choice('source',loc('무료 자료 안내의 출처는?', 'Who mentioned the free material?', 'Wer wies auf das kostenlose Material hin?'),['진행자','글쓴이가 읽고 확인한 경험'],review_help),
        ])
    tasks.append(task('KP11','reading:01','reading',loc('리뷰의 근거와 빠진 대안','Evidence and missing alternatives in a review','Belege und fehlende Alternativen in einer Rezension'),review_help,
      review('달빛 프로그램','5000','20'),review('숲길 프로그램','4000','25')))
    article_help=loc('기사의 수치·인용·해석을 구별하세요. 일부 참가자의 말로 모든 사람의 소비나 문화 참여를 단정하지 않아요. 제도의 존재와 실제 효과도 나눠 읽어요.',
      'Separate figures, quotations and interpretation. A few participants’ statements do not establish everyone’s spending or cultural access. Distinguish a scheme’s existence from evidence of its effects.',
      'Trenne Zahlen, Zitate und Deutung. Aussagen weniger Teilnehmender belegen weder das Konsumverhalten noch den Kulturzugang aller. Unterscheide das Bestehen einer Regelung vom Nachweis ihrer Wirkung.')
    def news(place,count):
        return packet(f'학습용 가상 기사 | {place} 문화 참여 지원 시범 운영\n센터는 이번 달부터 무료 해설 자료를 제공하는 시범 제도를 시작했다. 기자가 만난 참가자 {count}명은 비용 부담이 줄면 더 자주 참여하고 싶다고 말했다. 센터 담당자는 "무료 자료를 제공하지만 유료 프로그램의 요금은 그대로입니다"라고 설명했다. 기자는 비용에 따른 참여 격차를 줄일 가능성이 있다고 해석했다. 다만 참가 횟수 변화는 아직 조사하지 않았다. 이 기사는 전체 지역 주민의 소비 금액을 조사한 결과가 아니다.',[
          choice('fact',loc('확인된 제도 내용은?', 'What does the scheme actually provide?', 'Was bietet die Regelung tatsächlich?'),['무료 해설 자료 제공','모든 유료 프로그램 무료 전환'],article_help),
          choice('quote',loc('더 자주 참여하고 싶다는 말의 출처는?', 'Who expressed the wish to attend more often?', 'Wer äußerte den Wunsch nach häufigerer Teilnahme?'),[f'기자가 만난 참가자 {count}명','지역 주민 전체'],article_help),
          choice('effect',loc('참여 격차 감소는 입증됐어요?', 'Has a reduction in the participation gap been demonstrated?', 'Ist eine Verringerung der Teilhabeunterschiede belegt?'),['아니요. 가능성에 대한 해석이며 횟수 변화는 미조사','네. 모든 주민의 참여 증가가 확인됨'],article_help),
        ])
    tasks.append(task('KP11','reading:02','reading',loc('문화 참여 기사: 제도와 효과','Cultural access: a scheme and its effects','Kulturelle Teilhabe: Regelung und Wirkung'),article_help,
      news('한빛센터','네'),news('새봄센터','여섯')))
    def social(title,criterion):
        return packet(f'가상 SNS 게시글 — 민아\n{title}은 제 마음에 들었어요. {criterion}다는 점이 특히 좋았어요. 다만 자세한 배경 설명은 부족했어요. 다른 선택도 있을 수 있어요.\n댓글 — 도윤: 그 장점에는 동의해요. 저는 자세한 해설을 더 중요하게 생각해서 다른 프로그램을 확인해 볼래요. 아직 보지 않았으니 더 좋다고 단정하지는 않을게요.\n댓글 — 수아: 다른 프로그램을 고르는 사람은 성격도 나쁠 거예요.\n민아의 답: 선택 기준이 다를 수 있어요. 프로그램 취향만으로 사람을 평가하지 않았으면 해요.',[
          choice('scope',loc('도윤이 동의한 범위는?', 'What does Doyun agree with?', 'Worauf beschränkt sich Doyuns Zustimmung?'),['민아가 말한 특정 장점','프로그램에 대한 전면 동의'],h),
          choice('unknown',loc('도윤의 다른 프로그램 평가는?', 'What is Doyun’s assessment of the other programme?', 'Wie bewertet Doyun das andere Angebot?'),['관람 전이어서 판단 유보','이미 더 좋다고 확인'],h),
          choice('person',loc('수아의 댓글이 근거를 넘는 이유는?', 'Why does Sua’s comment exceed the evidence?', 'Warum geht Suas Kommentar über die Belege hinaus?'),['프로그램 취향을 사람의 성격으로 확대함','제시 가격을 정확하게 비교함'],h),
        ])
    tasks.append(task('KP11','reading:03','reading',loc('부분 동의와 사람 평가 구별','Partial agreement versus judging a person','Teilweise Zustimmung und Personenurteil unterscheiden'),h,
      social('달빛 프로그램','시간이 짧'),social('숲길 프로그램','이동이 편리하')))
    rubric=loc('가상 관람자의 정보로 기준·주장·구체적 근거·한계·대안을 연결한 리뷰를 쓰세요. 실제 경험과 포스터 인상을 구별하고 반론에 답하되 모르는 대안은 확인할 항목으로 남기세요. 소비 취향을 성격으로 확대하지 마세요. 근거와 비교해 고쳐 쓰며 전체 글의 의미·논증은 미채점입니다.',
      'Write a review linking criteria, claim, concrete evidence, limitation and an alternative from the fictional viewer’s facts. Separate experience from a poster impression; address a counterpoint while leaving unknown alternatives to be checked. Do not turn taste into a character judgement. Compare and revise; full meaning and argument quality remain unscored.',
      'Schreibe aus den Angaben der fiktiven betrachtenden Person eine Rezension mit Kriterien, Aussage, konkretem Beleg, Grenze und Alternative. Trenne Erlebnis und Plakateindruck; gehe auf einen Einwand ein und lasse unbekannte Alternativen zur Prüfung offen. Mache aus Vorlieben kein Charakterurteil. Vergleiche und überarbeite; Gesamtinhalt und Argumentation bleiben unbewertet.')
    def facts(a,b,fee1,fee2,time1,time2,budget):
        return f'가상 모임 자료. 공통 예산: 1인 {budget}원 이내. {a}: {fee1}원, {time1}분, 직접 관람함. 짧고 편리하지만 마지막 설명 부족. {b}: {fee2}원, {time2}분, 아직 관람하지 않음. 포스터에 해설 시간 표시. 무료 해설 글 자료는 아직 읽지 않음.\n동료의 반론: 자세한 설명이 더 중요함. 나의 제안: 예산 안의 프로그램을 먼저 보고 무료 해설 자료를 확인. 아직 전원 합의 전. 비용에 따른 문화 참여 격차를 줄일 수 있을지는 이 자료만으로 모름.'
    p=facts('달빛 프로그램','바람 프로그램','5000','8000','20','35','6000')
    a=facts('숲길 프로그램','물결 프로그램','4000','7000','25','40','5000')
    tasks.append(task('KP11','writing:01','writing',loc('근거와 대안을 갖춘 문화 리뷰','A cultural review with evidence and alternatives','Kulturrezension mit Belegen und Alternativen'),rubric,
      packet(p,[free_text('review',loc('장점·한계·대안을 연결한 리뷰를 쓰세요.','Write a review connecting advantages, limits and an alternative.','Verbinde Vorteile, Grenzen und eine Alternative in einer Rezension.'),rubric)],'form'),
      packet(a,[free_text('review',loc('장점·한계·대안을 연결한 리뷰를 쓰세요.','Write a review connecting advantages, limits and an alternative.','Verbinde Vorteile, Grenzen und eine Alternative in einer Rezension.'),rubric)],'form')))
    speech=loc('동등한 모임 동료에게 해요체로 같은 기준의 장단점을 비교하고 선택을 제안하세요. 자세한 설명이 중요하다는 반론에 응답하고 대체 제안을 대조 문장과 구별해요. 비교 초점·양보 뒤 한계가 들리도록 녹음을 듣고 휴지와 말끝을 고쳐요. 의미·설득력·억양은 미채점입니다.',
      'Compare advantages and disadvantages using the same criteria and propose a choice politely to peers. Respond to the need for detail and distinguish replacement from contrast. Replay and revise pauses and endings so the comparison focus and reservation remain clear. Meaning, persuasiveness and intonation remain unscored.',
      'Vergleiche Vor- und Nachteile nach denselben Kriterien und schlage Gleichgestellten höflich eine Wahl vor. Gehe auf den Wunsch nach Details ein und unterscheide Ersatzvorschlag und Gegenüberstellung. Höre zu und verbessere Pausen und Endungen, damit Vergleich und Vorbehalt erkennbar bleiben. Inhalt, Überzeugungskraft und Intonation bleiben unbewertet.')
    tasks.append(task('KP11','speaking:01','speaking',loc('공통 기준으로 선택 제안하기','Propose a choice using shared criteria','Eine Wahl nach gemeinsamen Kriterien vorschlagen'),speech,packet(p,[]),packet(a,[])))
    briefing=loc('가상 모임의 발표자로 격식체를 사용해 요점·비교 근거·반론·한계 순서로 발표하세요. 자료의 수치와 출처를 유지하고 더 좋은지, 참여 격차를 줄이는지 묻는 질문에는 미확인 범위를 밝히세요. 녹음을 듣고 명확한 의미 단위로 다시 발표해요. 전체 발표의 의미·문체는 미채점입니다.',
      'As the fictional group’s presenter, speak formally in the order of main point, comparison evidence, counterpoint and limitations. Preserve figures and sources; disclose uncertainty when asked whether an option is better or reduces access gaps. Replay and present again in clear meaning units. Full meaning and register remain unscored.',
      'Trage als präsentierende Person der fiktiven Gruppe förmlich Hauptaussage, Vergleichsbelege, Einwand und Grenzen vor. Erhalte Zahlen und Quellen und benenne Ungewissheit bei Fragen zur besseren Wahl oder zu Teilhabeunterschieden. Höre zu und präsentiere erneut in klaren Sinneinheiten. Gesamtinhalt und Sprachstil bleiben unbewertet.')
    tasks.append(task('KP11','speaking:02','speaking',loc('비교 결과를 청중에게 발표','Present the comparison to an audience','Den Vergleich vor einem Publikum präsentieren'),briefing,
      packet(p+'\n청중 질문: 바람 프로그램이 확실히 더 좋습니까? 이 선택이 참여 격차를 줄입니까?',[]),
      packet(a+'\n청중 질문: 물결 프로그램이 확실히 더 좋습니까? 이 선택이 참여 격차를 줄입니까?',[])))
    return tasks


if __name__=='__main__':
    write_source('KP11',kp11())
