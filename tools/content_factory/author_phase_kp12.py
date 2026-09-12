"""KP12 conditions and responsibilities; source generation is unsigned."""
from phase_task_authoring import choice, free_text, grammar_task, loc, packet, task, write_source
from author_phase_a1_production import production


def kp12():
    rows=[
      ('G3:-거든1',loc('여기서는 뒤 요청이 실행될 조건을 앞에 제시해요. 문장 끝에서 이유를 설명하는 거든요와 구별해요.','Here, the first clause sets a condition for the request, unlike sentence-final explanatory 거든요.','Hier nennt der erste Satzteil eine Bedingung für die Bitte; das ist nicht das erklärende 거든요 am Satzende.'),
       ('시간이 나거든 연락해 주세요.','시간이 나는 경우 연락을 요청함','시간과 상관없이 즉시 연락하라고 명령함'),
       ('자료가 준비되거든 알려 주세요.','자료 준비가 된 경우 알림 요청','자료 준비가 끝났다고 이미 확인함')),
      ('G3:-어야',loc('결과에 필요한 조건을 나타내요. 필요한 조건 하나를 채웠다고 다른 조건도 모두 충족했다고 보지 않아요.','State a necessary condition. Meeting one requirement does not imply that every other condition is met.','Nenne eine notwendige Bedingung. Eine erfüllte Voraussetzung bedeutet nicht, dass alle übrigen erfüllt sind.'),
       ('예약을 해야 들어갈 수 있어요.','입장에 예약이 필요함','예약 없이도 반드시 입장 가능'),
       ('허가를 받아야 자료를 공개할 수 있어요.','공개에 허가가 필요함','허가를 이미 받았다고 확정함')),
      ('G3:-어야지1',loc('필수 조건을 강조하며 뒤 결과와 연결해요. 여기서는 혼잣말의 결심만을 나타내는 용법과 구별해요.','Emphasise a necessary condition linked to a result; this is not merely a self-directed resolution.','Betone eine notwendige Bedingung für das Folgende; hier handelt es sich nicht bloß um einen selbstbezogenen Vorsatz.'),
       ('서로 믿어야지 함께 일할 수 있어요.','함께 일하기 위한 신뢰의 필요성 강조','이미 모두 서로 믿는다고 확인'),
       ('역할을 정해야지 일을 나눌 수 있어요.','업무 배분에 역할 결정이 필요함','역할을 정하지 않아야 업무 배분 가능')),
      ('G3:-어야겠-',loc('필요를 깨닫고 화자가 자기 결심을 말해요. 다른 사람에게 의무를 넘기거나 이미 실행했다고 바꾸지 않아요.','The speaker recognises a need and resolves to act; do not transfer the obligation or claim completion.','Die sprechende Person erkennt eine Notwendigkeit und fasst einen Vorsatz; übertrage die Pflicht nicht und behaupte keinen Abschluss.'),
       ('이번에는 제가 미리 준비해야겠어요.','화자가 준비 필요를 깨닫고 결심함','동료가 이미 준비를 끝냈다고 말함'),
       ('제가 먼저 담당자에게 확인해야겠어요.','화자가 먼저 확인하기로 생각함','담당자가 화자의 일을 대신하기로 확정함')),
      ('G3:-으려면',loc('하려는 목적을 실현하는 데 필요한 조건을 제시해요. 의도가 있다고 해서 이미 허가나 결과가 생긴 것은 아니에요.','State a condition needed to achieve an intended goal. Intention itself is not permission or a completed result.','Nenne eine Voraussetzung zum Erreichen eines beabsichtigten Ziels. Die Absicht allein ist weder Erlaubnis noch Ergebnis.'),
       ('이 공간을 쓰려면 먼저 예약해야 해요.','공간 사용 의도에 필요한 예약 조건','예약하지 않아야 사용할 수 있음'),
       ('함께 발표하려면 역할을 나누어야 해요.','공동 발표에 필요한 역할 분담','발표가 이미 끝났다는 확인')),
      ('G3:-도록',loc('뒤 행동이 겨냥하는 목적이나 결과를 말해요. 목적을 세웠다는 사실만으로 실제 달성을 보증하지 않아요.','State the purpose or intended result of an action. An aim is not proof that it was achieved.','Nenne Zweck oder angestrebtes Ergebnis einer Handlung. Eine Absicht beweist nicht ihre Verwirklichung.'),
       ('모두 참여할 수 있도록 시간을 바꿨어요.','모두의 참여 가능성을 위한 시간 변경','모두 실제로 참석했다고 확정함'),
       ('잘 들리도록 문을 닫았어요.','잘 듣게 하려는 목적의 행동','모든 사람이 실제로 이해했다는 보증')),
      ('G3:-기 위해',loc('행동의 목적을 명시해요. 목적은 동기이지 그 결과가 이미 달성됐다는 증거가 아니에요.','Name the purpose of an action; a purpose is not evidence that the desired outcome is already achieved.','Nenne den Zweck einer Handlung; der Zweck belegt nicht, dass das gewünschte Ergebnis schon erreicht wurde.'),
       ('기록을 남기기 위해 사진을 찍었어요.','기록 보존이 촬영 목적','촬영했으므로 공개 허가도 받음'),
       ('혼란을 줄이기 위해 안내문을 썼어요.','혼란 감소를 목적으로 작성함','혼란이 완전히 사라졌다고 확인')),
      ('G3:-게 하다',loc('누군가가 다른 사람의 행동을 유발하거나 허용해요. 문맥에서 지시와 허용을 구별하고 실제 권한을 추가하지 않아요.','Someone causes or allows another person to act. Distinguish instruction from permission in context and invent no authority.','Eine Person veranlasst oder erlaubt die Handlung einer anderen. Unterscheide Anweisung und Erlaubnis im Kontext und erfinde keine Befugnis.'),
       ('교사는 학생들이 주제를 직접 고르게 했어요. 학생들에게 선택을 맡긴 거예요.','교사가 학생의 직접 선택을 허용함','교사가 학생 대신 모든 주제를 정함'),
       ('담당자는 참가자들이 먼저 질문하게 했어요. 질문 시간을 준 거예요.','참가자에게 먼저 질문할 기회를 줌','참가자의 질문을 금지함')),
      ('G3:-어 드리다',loc('높이는 상대를 위해 하는 행동을 나타내요. 이 예에서는 화자가 행동해요. 주체와 수혜자를 바꾸거나 화자 자신을 높이지 않아요.','In these examples, the speaker acts for a respected recipient. Preserve actor and beneficiary; the form does not honour the speaker.','In diesen Beispielen handelt die sprechende Person zugunsten einer respektierten Person. Erhalte Handelnden und Begünstigten; die Form erhöht nicht die sprechende Person selbst.'),
       ('제가 선생님께 자료를 보내 드렸어요.','화자가 선생님을 위해 보냄','선생님이 화자에게 보내 줌'),
       ('제가 담당자께 일정을 알려 드렸어요.','화자가 담당자에게 알림','담당자가 화자에게 알림')),
      ('G3:-으면 안 되다',loc('행동을 하면 안 된다는 금지·불가예요. 하지 않아도 된다는 의무 없음과 구별해요.','Express prohibition, not absence of obligation. Must not differs from need not.','Drücke ein Verbot aus, nicht das Fehlen einer Pflicht. Nicht dürfen ist etwas anderes als nicht müssen.'),
       ('허가 없이 사진을 공개하면 안 돼요.','허가 없는 공개가 금지됨','공개는 선택이라 허가가 없어도 됨'),
       ('여기에 물건을 놓으면 안 돼요.','해당 장소에 물건 두기 금지','반드시 여기에 물건을 두어야 함')),
      ('G3:-으면 좋겠다',loc('원하는 상황을 완곡하게 말해요. 희망을 상대의 의무나 이미 정한 약속으로 바꾸지 않아요.','Express a wish gently; a wish is neither another person’s obligation nor an agreed commitment.','Äußere einen Wunsch zurückhaltend; er ist weder Pflicht der anderen Person noch vereinbarte Zusage.'),
       ('모두 함께할 수 있으면 좋겠어요.','모두 함께하기를 바람','모두 참석을 이미 확정함'),
       ('이번 주에 답을 받을 수 있으면 좋겠어요.','이번 주 회신을 희망함','상대가 이번 주 회신을 약속함')),
      ('G3:-을 테니',loc('화자의 의지나 예상을 바탕으로 뒤 요청을 연결해요. 여기서는 화자의 약속과 청자에게 하는 부탁을 따로 확인해요.','A speaker’s intention or expectation grounds a request. Here, separate the speaker’s commitment from the request to the listener.','Absicht oder Erwartung der sprechenden Person begründet eine Bitte. Trenne hier ihre Zusage von der Bitte an die zuhörende Person.'),
       ('제가 확인할 테니 잠시 기다려 주세요.','화자가 확인하고 청자에게 기다림 요청','청자가 확인하고 화자가 기다리기로 함'),
       ('제가 정리할 테니 번호를 알려 주세요.','화자는 정리, 청자에게 번호 알림 요청','화자가 이미 정리를 끝냈다는 뜻')),
      ('G3:만 아니면',loc('하나의 방해 조건을 제외해 가정해요. 본문에 다른 조건이 있다면 그 조건까지 사라지는 것은 아니에요.','Suppose one obstacle is absent. Other conditions stated in the text still apply.','Nimm an, ein Hindernis entfällt. Andere im Text genannte Bedingungen gelten weiterhin.'),
       ('비만 아니면 밖에서 할 수 있어요. 장소 예약은 따로 필요해요.','비가 아니어도 예약 조건은 남음','비만 안 오면 예약도 자동 면제'),
       ('월요일만 아니면 시간을 낼 수 있어요. 최종 일정은 서로 확인해야 해요.','월요일 외 날짜도 상호 일정 확인 필요','월요일 외 날짜는 모두 이미 확정')), 
    ]
    tasks=[grammar_task('KP12',i,key,h,p,a) for i,(key,h,p,a) in enumerate(rows,1)]
    prod=[
      ('G3:-거든1',('조건부 부탁 / 시간이 나다 → 연락해 주다 / -거든 / -세요','시간이 나거든 연락해 주세요.','시간이 없어도 지금 연락하세요.'),('조건부 부탁 / 자료가 준비되다 → 알려 주다 / -거든 / -세요','자료가 준비되거든 알려 주세요.','자료가 준비되지 않아도 완료라고 알려 주세요.')),
      ('G3:-어야',('필수 조건 / 예약을 하다 → 들어갈 수 있다 / -어야 / 해요체','예약을 해야 들어갈 수 있어요.','예약을 하지 않아야 들어갈 수 있어요.'),('필수 조건 / 허가를 받다 → 자료를 공개할 수 있다 / -아야 / 해요체','허가를 받아야 자료를 공개할 수 있어요.','허가를 받지 않아도 자료를 공개할 수 있어요.')),
      ('G3:-어야지1',('필수 조건 강조 / 서로 믿다 → 함께 일할 수 있다 / -어야지 / 해요체','서로 믿어야지 함께 일할 수 있어요.','서로 믿지 않아야 함께 일할 수 있어요.'),('필수 조건 강조 / 역할을 정하다 → 일을 나눌 수 있다 / -어야지 / 해요체','역할을 정해야지 일을 나눌 수 있어요.','역할을 정하지 않아야 일을 나눌 수 있어요.')),
      ('G3:-어야겠-',('내 결심 / 이번에는 제가 미리 준비하다 / -어야겠- / 해요체','이번에는 제가 미리 준비해야겠어요.','이번에는 동료가 이미 준비를 끝냈어요.'),('내 결심 / 제가 먼저 담당자에게 확인하다 / -어야겠- / 해요체','제가 먼저 담당자에게 확인해야겠어요.','담당자가 제 일을 대신하기로 했어요.')),
      ('G3:-으려면',('의도 실현 조건 / 이 공간을 쓰다 → 먼저 예약해야 하다 / -려면 / 해요체','이 공간을 쓰려면 먼저 예약해야 해요.','이 공간을 쓰려면 예약하지 않아야 해요.'),('의도 실현 조건 / 함께 발표하다 → 역할을 나누어야 하다 / -려면 / 해요체','함께 발표하려면 역할을 나누어야 해요.','함께 발표하려면 역할을 나누면 안 돼요.')),
      ('G3:-도록',('목적 / 모두 참여할 수 있다 → 시간을 바꾸다 / -도록 / 과거 해요체','모두 참여할 수 있도록 시간을 바꾸었어요.','시간을 바꾸어서 모두 참석한 것이 확정됐어요.'),('목적 / 잘 들리다 → 문을 닫다 / -도록 / 과거 해요체','잘 들리도록 문을 닫았어요.','문을 닫아서 모두 이해한 것이 확정됐어요.')),
      ('G3:-기 위해',('목적 / 기록을 남기다 → 사진을 찍다 / -기 위해 / 과거 해요체','기록을 남기기 위해 사진을 찍었어요.','사진을 찍어서 공개 허가를 받았어요.'),('목적 / 혼란을 줄이다 → 안내문을 쓰다 / -기 위해 / 과거 해요체','혼란을 줄이기 위해 안내문을 썼어요.','안내문을 써서 혼란이 완전히 사라졌어요.')),
      ('G3:-게 하다',('교사의 허용 / 교사는 학생들이 주제를 직접 고르다 / -게 하다 / 과거 해요체','교사는 학생들이 주제를 직접 고르게 했어요.','교사는 학생들 대신 주제를 모두 정했어요.'),('담당자의 허용 / 담당자는 참가자들이 먼저 질문하다 / -게 하다 / 과거 해요체','담당자는 참가자들이 먼저 질문하게 했어요.','담당자는 참가자들이 질문하지 못하게 했어요.')),
      ('G3:-어 드리다',('행동 주체는 나, 수혜자는 선생님 / 제가 선생님께 자료를 보내다 / -어 드리다 / 과거 해요체','제가 선생님께 자료를 보내 드렸어요.','선생님이 저에게 자료를 보내 주셨어요.'),('행동 주체는 나, 수혜자는 담당자 / 제가 담당자께 일정을 알리다 / -어 드리다 / 과거 해요체','제가 담당자께 일정을 알려 드렸어요.','담당자가 저에게 일정을 알려 주셨어요.')),
      ('G3:-으면 안 되다',('금지 / 허가 없이 사진을 공개하다 / -하면 안 되다 / 해요체','허가 없이 사진을 공개하면 안 돼요.','허가 없이 사진을 공개해도 돼요.'),('금지 / 여기에 물건을 놓다 / -으면 안 되다 / 해요체','여기에 물건을 놓으면 안 돼요.','여기에 물건을 놓아야 해요.')),
      ('G3:-으면 좋겠다',('희망, 확정 아님 / 모두 함께할 수 있다 / -으면 좋겠다 / 해요체','모두 함께할 수 있으면 좋겠어요.','모두 함께하기로 확정했어요.'),('희망, 확정 아님 / 이번 주에 답을 받을 수 있다 / -으면 좋겠다 / 해요체','이번 주에 답을 받을 수 있으면 좋겠어요.','상대가 이번 주에 답하기로 약속했어요.')),
      ('G3:-을 테니',('내 약속과 상대 부탁 / 제가 확인하다 → 잠시 기다려 주다 / -할 테니 / -세요','제가 확인할 테니 잠시 기다려 주세요.','상대가 확인할 테니 제가 기다릴게요.'),('내 약속과 상대 부탁 / 제가 정리하다 → 번호를 알려 주다 / -할 테니 / -세요','제가 정리할 테니 번호를 알려 주세요.','제가 정리를 이미 다 끝냈어요.')),
      ('G3:만 아니면',('방해 조건 하나 제외 / 비 / 만 아니면 / 밖에서 할 수 있다 / 해요체','비만 아니면 밖에서 할 수 있어요.','비가 와야만 밖에서 할 수 있어요.'),('방해 조건 하나 제외 / 월요일 / 만 아니면 / 시간을 낼 수 있다 / 해요체','월요일만 아니면 시간을 낼 수 있어요.','월요일에만 시간을 낼 수 있어요.')),
    ]
    tasks+=production('KP12',tasks,prod)
    h=loc('조건·금지·희망·약속의 주체를 따로 확인하세요. 도와주겠다는 말이 승인 권한을 뜻하지는 않아요. 공손한 요청도 청자에게 부담을 주므로 기한과 가능한 대안을 구별해요.',
      'Identify who is responsible for each condition, prohibition, wish and commitment. Offering help does not confer approval authority. Even a polite request creates work; distinguish the deadline from feasible alternatives.',
      'Prüfe, wer für Bedingung, Verbot, Wunsch und Zusage zuständig ist. Hilfsbereitschaft verleiht keine Genehmigungsbefugnis. Auch eine höfliche Bitte verursacht Aufwand; unterscheide Frist und machbare Alternativen.')
    def discussion(name,day,other,minutes):
        return packet(f'공동 발표를 준비하는 동등한 동료입니다.\n가: {name} 씨, {day}까지 자료를 선생님께 보내 드릴 수 있어요? 장소가 바뀌었다는 안내가 늦어서 제가 당황했어요. 교통편도 다시 확인해야 해요.\n나: {day}에는 다른 업무가 있어서 전체 검토는 어려워요. {other}이라면 {minutes}분 동안 제목과 번호를 확인해 드릴 수 있어요. 선생님께 자료를 보내는 일은 맡아 주실래요?\n가: 네, 제가 선생님께 보내 드릴게요. 전체 검토는 담당자에게 따로 요청하겠어요.\n나: 담당자 허가를 받아야 자료를 공개할 수 있어요. 허가 없이 사진을 올리면 안 돼요. 모두 함께할 수 있으면 좋겠지만 참석은 아직 확인 전이에요.\n가: 알겠어요. 제가 장소를 확인할 테니 잠시 기다려 주세요.',[
          choice('boundary',loc('나가 수락한 범위는?', 'What has the second colleague accepted?', 'Welchen Umfang hat die zweite Person zugesagt?'),[f'{other}에 {minutes}분 동안 제목과 번호 확인',f'{day}까지 전체 검토와 공개 승인'],h),
          choice('sender',loc('선생님께 자료를 보낼 사람은?', 'Who will send the material to the teacher?', 'Wer sendet der Lehrperson das Material?'),['가','선생님 자신'],h),
          choice('condition',loc('자료 공개에 필요한 것은?', 'What is required before publication?', 'Was ist vor Veröffentlichung erforderlich?'),['담당자 허가','동료의 희망만으로 충분'],h),
          choice('wish',loc('모두 참석하기는 어떤 상태예요?', 'What is the status of everyone attending?', 'Welchen Stand hat die Teilnahme aller?'),['희망이며 참석 확인 전','모두의 확정 약속'],h),
          choice('complaint',loc('가가 당황한 이유로 말한 것은?', 'What reason does the first colleague give for being unsettled?', 'Warum war die erste Person nach eigener Aussage verunsichert?'),['장소 변경 안내가 늦음','나가 이미 전체 검토를 완료함'],h),
        ],'audio')
    tasks.append(task('KP12','listening:01','listening',loc('협의에서 조건과 약속 구분','Conditions and commitments in negotiation','Bedingungen und Zusagen in einer Absprache'),h,
      discussion('지민','월요일','화요일','20'),discussion('민수','수요일','목요일','30')))
    email_help=loc('메일의 발신자·수신자·수혜자와 요청한 행동을 표시하세요. 가능한 범위를 묻는 부탁이지 능력을 시험하는 질문이 아니에요. 접수·확인·승인을 구별하고 불편 사실과 원하는 조치를 나눠 읽어요.',
      'Identify sender, recipient, beneficiary and requested action. Asking what is feasible is a request, not an ability test. Separate receipt, checking and approval, and distinguish the problem from the requested remedy.',
      'Bestimme Absender, Empfänger, Begünstigte und gewünschte Handlung. Die Frage nach dem Machbaren ist eine Bitte, kein Fähigkeitstest. Trenne Eingang, Prüfung und Genehmigung sowie Problem und erbetene Abhilfe.')
    def email(sender,recipient,day,other):
        return packet(f'학습용 가상 이메일\n받는 사람: {recipient} 담당자\n보낸 사람: {sender}, 발표 준비 모임\n제목: 장소 변경 확인과 자료 검토 요청\n안녕하세요. 장소 변경 안내를 오늘 받아 교통편을 다시 알아봐야 합니다. 정확한 장소와 이용 조건을 확인해 주실 수 있습니까?\n자료를 {day}에 보내 드리겠습니다. 가능하시다면 {other}까지 전체 검토를 부탁드립니다. 어려우시면 가능한 날짜와 검토 범위를 알려 주시면 감사하겠습니다.\n검토한 자료는 선생님께 전달하려고 합니다. 접수되었다는 알림만으로 공개 허가를 받은 것으로 처리하지 않겠습니다. 확인 후 안내해 주시면 계획을 조정하겠습니다. 감사합니다.',[
          choice('request',loc('담당자에게 요청한 것은?', 'What is requested of the staff member?', 'Was wird von der zuständigen Person erbeten?'),['장소·이용 조건 확인과 가능한 자료 검토','발신자의 모든 일을 즉시 대신하기'],email_help),
          choice('deadline',loc('검토 기한은 어떤 요청이에요?', 'How is the review deadline presented?', 'Wie wird die Prüfungsfrist formuliert?'),[f'가능하다면 {other}까지, 어려우면 대안 요청','상대가 이미 확정한 의무'],email_help),
          choice('beneficiary',loc('검토 후 자료를 전달받을 사람은?', 'Who is intended to receive the reviewed material?', 'Wer soll das geprüfte Material erhalten?'),['선생님',sender+'의 개인 고객이라고 명시됨'],email_help),
          choice('permission',loc('접수 알림이 공개 허가예요?', 'Does receipt notification grant publication permission?', 'Erlaubt die Eingangsbestätigung die Veröffentlichung?'),['아니요. 별도 허가 확인 필요','네. 접수 즉시 자동 승인'],email_help),
        ])
    tasks.append(task('KP12','reading:01','reading',loc('공식 요청 메일의 부담과 대안','Burden and alternatives in a formal request','Aufwand und Alternativen in einer förmlichen Bitte'),email_help,
      email('하린','한빛센터','월요일','수요일'),email('도윤','새봄센터','화요일','목요일')))
    process_help=loc('절차의 단계와 목적, 각 역할의 권한을 구분하세요. 도와주는 사람의 확인과 승인자의 허가는 다른 단계예요. 자료에 없는 자동 승인이나 기한 연장을 만들지 마세요.',
      'Separate procedural steps, purposes and each role’s authority. A helper’s check and an approver’s permission are different stages. Invent no automatic approval or deadline extension.',
      'Trenne Verfahrensschritte, Zwecke und Befugnisse der einzelnen Rollen. Die Prüfung durch eine helfende Person und die Genehmigung sind verschiedene Schritte. Erfinde keine automatische Zustimmung oder Fristverlängerung.')
    def procedure(item,role):
        return packet(f'가상 모임의 {item} 처리 절차\n1. 신청자가 자료를 준비하면 동료가 제목과 번호를 확인합니다. 잘못된 파일을 보내지 않도록 하는 점검입니다.\n2. 동료 확인을 마친 다음 신청자가 {role}에게 허가를 요청합니다. 동료에게는 공개 승인 권한이 없습니다.\n3. {role}의 허가를 받아야 공개할 수 있습니다. 답변이 없으면 미승인 상태입니다.\n4. 기한에 맞추기 어려우면 사유와 가능한 대안을 알려 협의합니다. 어려움을 알렸다는 것만으로 기한이 연장되지는 않습니다.',[
          choice('purpose',loc('동료 점검의 목적은?', 'What is the peer check for?', 'Wozu dient die Prüfung durch ein anderes Mitglied?'),['잘못된 파일 전송 방지','공개 승인 권한 이전'],process_help),
          choice('authority',loc('공개를 허가하는 역할은?', 'Which role grants publication permission?', 'Welche Rolle genehmigt die Veröffentlichung?'),[role,'제목만 확인한 동료'],process_help),
          choice('silence',loc('답변이 없을 때 상태는?', 'What is the status without a response?', 'Welcher Status gilt ohne Antwort?'),['미승인','자동 승인'],process_help),
          choice('extension',loc('기한 연장이 확정되는 근거는?', 'What would establish an extended deadline?', 'Was würde eine verlängerte Frist bestätigen?'),['추가 협의·확인이 필요함','사유를 한 번 알리면 이미 연장됨'],process_help),
        ])
    tasks.append(task('KP12','reading:02','reading',loc('도움과 승인 권한이 다른 절차','A procedure separating help from approval','Ein Verfahren mit getrennter Hilfe und Genehmigung'),process_help,
      procedure('사진','게시 담당자'),procedure('발표 영상','영상 담당자')))
    rubric=loc('가상 역할 카드의 요청과 조건부 수락을 격식 메일로 쓰세요. 문제 사실·영향·요청 조치, 내가 맡는 범위·기한과 상대 확인이 필요한 부분을 구별하세요. 수혜자와 발신자를 바꾸지 말고 스스로를 높이지 마세요. 사유가 기한 연장이나 공개 허가가 되지는 않아요. 읽고 고쳐 쓰며 전체 의미·공손함은 미채점입니다.',
      'Write a formal email with the request and conditional acceptance in the fictional role card. Separate problem, impact and remedy, your scope and deadline, and matters awaiting confirmation. Preserve sender and beneficiary; do not honour yourself. A reason does not grant an extension or permission. Read and revise; full meaning and politeness remain unscored.',
      'Schreibe eine förmliche E-Mail mit Bitte und bedingter Zusage aus der fiktiven Rollenkarte. Trenne Problem, Auswirkung und Abhilfe, eigenen Umfang und Termin sowie noch zu bestätigende Punkte. Erhalte Absender und Begünstigte; erhöhe dich nicht selbst. Ein Grund gewährt weder Verlängerung noch Erlaubnis. Lies und überarbeite; Gesamtinhalt und Höflichkeit bleiben unbewertet.')
    def card(day,other,minutes,role):
        return f'가상 준비 모임에서 나는 자료 정리 담당, {role}는 승인 담당. 장소 변경 안내가 늦어 교통편을 다시 확인해야 함. 정확한 장소 확인 요청 필요.\n나는 {day}에 다른 업무 때문에 전체 검토 불가. {other}라면 {minutes}분 동안 제목·번호 확인 가능. 선생님께 자료를 보내는 것은 다른 동료가 맡음. 전체 검토와 공개 승인은 {role}의 확인 필요. 회신 희망은 이번 주이며 약속받지는 않음.\n담당자에게 문제·영향·요청을 말하고, 내가 가능한 일과 기한을 조건부로 수락하는 메일을 쓰세요. 승인이나 기한 연장을 대신 약속하지 마세요.'
    p=card('월요일','화요일','20','게시 담당자')
    a=card('수요일','목요일','30','영상 담당자')
    tasks.append(task('KP12','writing:01','writing',loc('도움을 요청하고 범위를 정해 수락','Request help and accept within limits','Um Hilfe bitten und begrenzt zusagen'),rubric,
      packet(p,[free_text('email',loc('수신자·요청·조건을 갖춘 메일을 쓰세요.','Write the email with recipient, request and conditions.','Schreibe die E-Mail mit Empfänger, Bitte und Bedingungen.'),rubric)],'form'),
      packet(a,[free_text('email',loc('수신자·요청·조건을 갖춘 메일을 쓰세요.','Write the email with recipient, request and conditions.','Schreibe die E-Mail mit Empfänger, Bitte und Bedingungen.'),rubric)],'form')))
    speak_help=loc('첫 장면은 동등한 동료와 해요체로 협의해요. 못 하는 이유·가능한 대안·실행 조건을 말하고 도움과 승인을 구별하세요. 두 번째는 오래된 가까운 친구와 사적인 대화로, 서로 반말에 합의했고 개인적인 걱정을 나눠요. 친구의 걱정에 공감하되 권한 없는 약속은 하지 마세요. 녹음을 듣고 조건 뒤 휴지와 부탁의 말끝을 고쳐요. 의미·친밀함·억양은 미채점입니다.',
      'First negotiate politely with a peer: give a reason, feasible alternative and condition, separating help from approval. Then speak privately with a long-standing close friend who has agreed to casual speech and shared a personal worry. Respond with care without promising beyond your authority. Replay and revise pauses and request endings. Meaning, intimacy and intonation remain unscored.',
      'Verhandle zuerst höflich mit einer gleichgestellten Person: nenne Grund, machbare Alternative und Bedingung und trenne Hilfe von Genehmigung. Sprich danach privat mit einer langjährig engen befreundeten Person, mit vereinbarter vertraulicher Anrede und persönlicher Sorge. Reagiere einfühlsam, ohne unbefugt etwas zu versprechen. Höre zu und verbessere Pausen und Bitten. Inhalt, Vertrautheit und Intonation bleiben unbewertet.')
    tasks.append(task('KP12','speaking:01','speaking',loc('부탁의 부담을 협의하고 친구에게 공감','Negotiate a request and respond to a friend','Eine Bitte abstimmen und auf eine Sorge eingehen'),speak_help,
      packet(p+'\n별도 사적 장면: 가까운 친구가 이번 준비 때문에 걱정되고 지쳤다고 말함. 오늘 잠깐 이야기를 들어 줄 수 있지만 담당자 승인이나 전체 준비 완료를 대신 약속할 권한은 없음.',[]),
      packet(a+'\n별도 사적 장면: 가까운 친구가 일정 변경 때문에 당황하고 불안하다고 말함. 내일 잠깐 이야기를 들어 줄 수 있지만 담당자 승인이나 기한 연장을 대신 약속할 권한은 없음.',[])))
    interview=loc('가상 취업 면접에서 지원자 역할로 주어진 경험·가능 시간·권한의 한계를 공손하고 격식 있게 설명하세요. 감당할 수 없는 조건에는 대안을 제시하고 실제로 없는 경력이나 승인을 만들지 마세요. 녹음을 듣고 문체와 의미 단위의 휴지를 고쳐요. 발화 의미와 면접 적합성은 미채점입니다.',
      'In the fictional job interview, explain the supplied experience, availability and authority limits politely and formally. Offer an alternative to an unmanageable condition; invent no experience or permission. Replay and revise register and meaning-unit pauses. Speech meaning and interview suitability remain unscored.',
      'Erkläre im fiktiven Vorstellungsgespräch vorgegebene Erfahrung, Verfügbarkeit und Befugnisgrenzen höflich und förmlich. Biete bei untragbaren Bedingungen eine Alternative und erfinde weder Erfahrung noch Genehmigung. Höre zu und verbessere Sprachstil und Pausen. Inhalt und Eignung für das Gespräch bleiben unbewertet.')
    tasks.append(task('KP12','speaking:02','speaking',loc('면접에서 가능한 조건 설명','Explain feasible conditions in an interview','Machbare Bedingungen im Vorstellungsgespräch erklären'),interview,
      packet('가상 지원자: 안내 보조 업무 지원. 지난 두 달 주 1회 자료 정리 봉사. 접수 내용 입력만 담당했으며 승인 권한 없음. 월요일 근무는 수업 때문에 불가, 화요일 오후 가능. 면접관은 월요일 전체 업무를 맡을 수 있는지, 공개 승인을 해 본 적이 있는지 질문. 경력·한계·대안을 사실대로 답하고 최종 일정은 확인 요청.',[]),
      packet('가상 지원자: 행사 보조 업무 지원. 지난 세 달 주 1회 좌석 안내 봉사. 직원이 정한 좌석표 안내만 담당했으며 변경 승인 권한 없음. 수요일 근무는 수업 때문에 불가, 목요일 오전 가능. 면접관은 수요일 전체 업무를 맡을 수 있는지, 좌석 변경 승인을 해 본 적이 있는지 질문. 경력·한계·대안을 사실대로 답하고 최종 일정은 확인 요청.',[])))
    return tasks


if __name__=='__main__':
    write_source('KP12',kp12())
