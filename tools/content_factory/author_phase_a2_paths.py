"""A2 complaint, social response and register paths; no automatic approval."""
import json
from phase_task_authoring import FOLDER, choice, free_text, loc, packet, task, write_source


def kp05():
    teaching=loc('불편의 사실, 원하는 해결, 직원이 아직 확인할 일을 나눠 읽어요. 요청을 했다는 이유만으로 환불이 약속됐다고 보지 않아요. 가격·옷·몸 상태·도움 요청은 각각 다른 정보예요.',
        'Separate the reported problem, requested solution and facts staff still need to check. A request does not establish a refund promise. Keep prices, clothing, symptoms and help requests distinct.',
        'Unterscheide gemeldetes Problem, gewünschte Lösung und noch zu prüfende Angaben. Eine Bitte ist noch keine Rückerstattungszusage. Halte Preise, Kleidung, Beschwerden und Hilfewünsche auseinander.')
    def complaint(item,tag,receipt,symptom,object_name):
        return packet(f'가상 문화센터 대여 창구\n손님: {item}이 너무 작아요. 다른 크기로 바꿀 수 있어요? 가격표에는 {tag}원인데 영수증에는 {receipt}원이에요. 확인해 주세요.\n직원: 불편을 드려 죄송해요. 다른 크기가 있는지, 계산이 맞는지 먼저 확인할게요. 아직 환불이 정해진 것은 아니에요.\n손님: 네. 그리고 {symptom} {object_name}를 옮기기 어려워요. 도와주세요.',[
            choice('problem',loc('옷에 관한 불편은?', 'What is wrong with the clothing?', 'Was ist das Problem mit dem Kleidungsstück?'),['크기가 너무 작아요.','색이 마음에 들지 않아요.'],teaching),
            choice('prices',loc('가격 확인에 필요한 두 금액은?', 'Which amounts need to be compared?', 'Welche Beträge müssen verglichen werden?'),[f'가격표 {tag}원 / 영수증 {receipt}원',f'가격표 {receipt}원 / 영수증 {tag}원'],teaching),
            choice('refund',loc('환불은 이미 결정됐어요?', 'Has a refund already been decided?', 'Ist eine Rückerstattung bereits beschlossen?'),['아니요. 직원이 먼저 확인해요.','네. 전액 환불을 약속했어요.'],teaching),
            choice('help',loc('이동 도움을 부탁한 이유는?', 'Why was help moving an object requested?', 'Warum wurde um Hilfe beim Tragen gebeten?'),[symptom,'돈이 없어서'],teaching),
        ])
    read=task('KP05','reading:04','reading',loc('대여 창구에서 불편 알리기','Report a problem at a rental counter','Ein Problem am Verleihschalter melden'),teaching,
        complaint('겉옷','3000','4000','팔이 아파서','의자'),complaint('운동복','4000','5000','손목이 아파서','상자'))
    rubric=loc('옷 크기와 가격 차이, 요청할 해결을 분명히 적었나요? 확인 전 환불 약속을 만들지 않았나요? 몸 상태와 필요한 도움만 전하고 없는 진단은 쓰지 않았나요? 담당자에게 하십시오체 문장과 공손한 요청을 사용했나요? 다시 써 보세요. 의미는 미채점이에요.',
        'Did you state the size and price problems and the requested solution? Keep the refund undecided. State only the given symptom and needed help, without inventing a diagnosis. Use formal statements and polite requests to staff. Revise; meaning remains unscored.',
        'Hast du Größen- und Preisproblem sowie die gewünschte Lösung genannt? Lass die Erstattung offen. Nenne nur die angegebene Beschwerde und benötigte Hilfe, ohne eine Diagnose zu erfinden. Verwende förmliche Aussagesätze und höfliche Bitten an das Personal. Überarbeite; der Inhalt bleibt unbewertet.')
    def letter(item,tag,receipt,symptom,object_name):
        return packet(f'가상 문화센터 담당자에게 보내는 문의문\n옷: {item}, 너무 작음. 다른 크기로 교환을 원함. 가격표: {tag}원, 영수증: {receipt}원. 직원 확인 전이며 환불 약속 없음.\n개인적으로 전달할 몸 상태: {symptom}. 필요한 도움: {object_name} 옮기기. 공개 게시판이 아닌 담당자 문의창이에요.\n격식 있는 서술과 공손한 확인 요청으로 전체 문의문을 쓰세요.',[
            free_text('draft',loc('문의 내용과 요청을 완전한 글로 쓰세요.','Write the complete enquiry and request.','Schreibe die vollständige Anfrage mit deiner Bitte.'),rubric)],'form')
    write=task('KP05','writing:03','writing',loc('담당자에게 격식 있게 문의하기','Write a formal enquiry to staff','Eine förmliche Anfrage an das Personal schreiben'),rubric,
        letter('겉옷','3000','4000','팔이 아픔','의자'),letter('운동복','4000','5000','손목이 아픔','상자'))
    travel_teaching=loc('숙소 안내에서 역·버스·객실 가격·식사 포함 여부를 나눠 읽어요. 광고의 편리하다는 말만 보고 요금에 모든 것이 포함됐다고 생각하지 않아요.',
        'Separate the station, bus, room price and meal conditions in a lodging leaflet. A claim of convenience does not mean every service is included in the price.',
        'Unterscheide Bahnhof, Bus, Zimmerpreis und Verpflegung im Unterkunftsflyer. Die Aussage bequem bedeutet nicht, dass alle Leistungen im Preis enthalten sind.')
    def leaflet(station,bus,price):
        return packet(f'학습용 가상 숙소 안내\n역에서 가까운 편리한 숙소!\n{station}역에서 {bus}번 버스로 두 정거장. 숙소 앞에서 내리세요.\n1인실 1박 {price}원. 아침 식사는 별도 요금입니다.\n예약 확인 문자를 받은 뒤 방문하세요.',[
            choice('transport',loc('역에서 무엇을 타요?', 'What transport is used from the station?', 'Was nimmt man ab dem Bahnhof?'),[bus+'번 버스',bus+'번 기차'],travel_teaching),
            choice('price',loc('제시된 가격의 범위는?', 'What does the quoted price cover?', 'Wofür gilt der angegebene Preis?'),['1인실 1박, 아침 식사는 별도','1인실 1박과 모든 식사'],travel_teaching),
            choice('condition',loc('방문 전에 확인할 것은?', 'What must be checked before visiting?', 'Was muss vor der Anreise vorliegen?'),['예약 확인 문자','공연 입장권'],travel_teaching),
        ])
    travel=task('KP05','reading:05','reading',loc('숙소 안내의 교통편과 조건','Transport and conditions in a lodging leaflet','Anreise und Bedingungen im Unterkunftsflyer'),travel_teaching,
        leaflet('한빛','12','50000'),leaflet('새봄','24','60000'))
    return [read,write,travel]


def kp06():
    teaching=loc('상대가 기쁜 일을 말하면 축하하고, 아쉬운 일을 말하면 그 마음을 받아요. 못 온 사람을 이미 온 사람으로 바꾸거나 초대를 강요하지 않아요. 인물과 시점, 감정의 근거를 따로 읽어요.',
        'Congratulate someone on good news and acknowledge disappointment. Do not turn a person who could not attend into a past participant or force an invitation. Separate people, times and reasons for feelings.',
        'Gratuliere zu einer guten Nachricht und gehe auf Enttäuschung ein. Mache aus einer Person, die nicht kommen konnte, keine frühere Teilnehmerin oder keinen früheren Teilnehmer und dränge keine Einladung auf. Unterscheide Personen, Zeiten und Gründe für Gefühle.')
    def news(person,event,day):
        return packet(f'모임 동료의 메시지\n{person}: 어제 처음으로 {event} 정말 기뻐요. 그런데 친구는 일이 있어서 못 왔어요. 친구도 아쉬워했어요.\n나: 축하해요! 친구분은 아쉬우셨겠어요. {day}에 같이 모임에 오실래요? 어려우면 다음에 와도 괜찮아요.\n{person}: 고마워요. 저는 갈 수 있어요. 친구에게는 물어볼게요.',[
            choice('reason',loc('축하한 이유는?', 'Why was congratulations offered?', 'Wozu wurde gratuliert?'),['처음으로 '+event,'친구가 모임에 왔어요.'],teaching),
            choice('absent',loc('어제 오지 못한 사람은?', 'Who could not attend yesterday?', 'Wer konnte gestern nicht kommen?'),[person+'의 친구',person],teaching),
            choice('invitation',loc('초대에 대해 확인된 것은?', 'What is confirmed about the invitation?', 'Was steht zur Einladung fest?'),[person+'만 갈 수 있다고 답했어요.','친구도 오기로 했어요.'],teaching),
        ])
    read=task('KP06','reading:03','reading',loc('축하·공감·초대의 답장','Congratulations, empathy and an invitation','Gratulation, Mitgefühl und Einladung'),teaching,
        news('미나','작품을 완성했어요.','토요일'),news('준호','공연을 마쳤어요.','일요일'))
    speak=task('KP06','speaking:02','speaking',loc('경험을 전하며 축하하고 위로하기','Relay an experience and respond with care','Ein Erlebnis weitergeben und Anteil nehmen'),
        loc('간 사람·가는 사람·갈 사람의 끝소리와 시점을 구별해 말해요. 이어서 제공된 경험을 전하고 축하·공감·초대에 답하세요. 첫 장면은 해요체, 둘째 장면은 반말에 합의한 친구예요. 듣고 휴지와 말끝을 고쳐 재녹음하세요. 의미·억양은 미채점이에요.',
            'Say 간 사람, 가는 사람 and 갈 사람 while preserving their time reference. Then relay the given experience and respond to congratulations, disappointment and an invitation. Use polite speech in the first scene and agreed casual speech in the second. Replay and revise pauses and endings; meaning and intonation remain unscored.',
            'Sprich 간 사람, 가는 사람 und 갈 사람 mit passendem Zeitbezug. Gib dann das vorgegebene Erlebnis weiter und reagiere auf Gratulation, Enttäuschung und Einladung. Sprich in der ersten Szene höflich, in der zweiten mit vereinbarter vertraulicher Anrede. Höre zu und überarbeite Pausen und Endungen; Inhalt und Intonation bleiben unbewertet.'),
        packet('모임 동료에게 해요체: 미나가 어제 첫 작품을 끝냈고 기쁘다고 했어요. 나는 어제 모임에 갔고, 지수는 지금 가며, 민수는 내일 갈 예정이에요. 인물을 바꾸지 말고 전하세요.\n반말에 합의한 친구가 시험에 합격했다고 해요. 축하하세요. 이어서 이번 토요일 모임에 못 와서 아쉽다고 해요. 공감하고 다음 기회를 열어 두세요.',[]),
        packet('모임 동료에게 해요체: 준호가 어제 첫 공연을 끝냈고 기쁘다고 했어요. 나는 어제 모임에 갔고, 민수는 지금 가며, 지수는 내일 갈 예정이에요. 인물을 바꾸지 말고 전하세요.\n반말에 합의한 친구가 작품을 완성했다고 해요. 축하하세요. 이어서 이번 일요일 모임에 못 와서 아쉽다고 해요. 공감하고 다음 기회를 열어 두세요.',[]))
    return [read,speak]


def kp07():
    teaching=loc('의견·이유·조언을 구분하고 부분 동의를 전체 동의로 넓히지 않아요. 공유 파일의 확정 정보와 아직 확인하지 않은 추정을 따로 읽어요.',
        'Distinguish opinions, reasons and advice; partial agreement is not total agreement. Separate confirmed details in the shared file from an unverified inference.',
        'Unterscheide Meinung, Begründung und Rat; teilweise Zustimmung ist keine vollständige Zustimmung. Trenne bestätigte Angaben in der geteilten Datei von einer ungeprüften Vermutung.')
    def exchange(day,other,transport):
        return packet(f'동등한 직장 동료의 메시지\n가: 주말은 잘 보냈어요? 저는 산책해서 기분이 좋아요. 공유 일정표 링크를 보니 모임은 {day}이에요. 저는 온라인 모임이 더 편해요.\n나: 저도 이동이 없다는 점에는 동의해요. 하지만 자료를 같이 보는 것은 직접 만나는 편이 좋아요. {transport} 시간을 먼저 확인해 보세요. 늦을 수도 있으니까요.\n가: 좋아요. 그런데 파일에 {other}도 보이는 것 같아요. 확실하지 않아서 담당자에게 물어볼게요.',[
            choice('agreement',loc('나가 동의한 부분은?', 'Which point does the second speaker agree with?', 'Welchem Punkt stimmt die zweite Person zu?'),['온라인이면 이동이 없어요.','모든 모임을 온라인으로 해야 해요.'],teaching),
            choice('advice',loc('조언은 무엇이에요?', 'What is the advice?', 'Was wird geraten?'),[transport+' 시간을 먼저 확인해 보기','담당자에게 사실을 숨기기'],teaching),
            choice('uncertain',loc('아직 확인되지 않은 것은?', 'What remains unverified?', 'Was ist noch ungeprüft?'),[other+' 표시의 의미',day+'이라는 공유 일정표의 명시 정보'],teaching),
        ])
    read=task('KP07','reading:02','reading',loc('부분 동의와 확인할 조언','Partial agreement and advice to check','Teilweise Zustimmung und ein Hinweis zur Prüfung'),teaching,
        exchange('월요일','화요일','버스'),exchange('수요일','목요일','기차'))
    speak=task('KP07','speaking:02','speaking',loc('의견과 약속을 두 말투로 전달','Give an opinion and commitment in two registers','Meinung und Zusage in zwei Sprachstilen'),
        loc('동료와 가볍게 안부를 나눈 뒤 의견과 이유, 부분 동의와 조언을 말해요. 확정 정보와 추정을 구별하세요. 갈래요는 선택, 갈게요는 내 약속, 갈까 봐요는 아직 정하지 않은 생각으로 비교해 녹음해요. 마지막에 담당자에게 같은 사실을 하십시오체로 전달하세요. 의미·억양은 미채점이에요.',
            'Exchange brief personal news with a peer, then give an opinion, reason, partial agreement and advice. Keep facts separate from inferences. Compare 갈래요 as a choice, 갈게요 as your commitment and 갈까 봐요 as tentative intention. Finally relay the same facts formally to the organiser. Meaning and intonation remain unscored.',
            'Tausche mit einer gleichgestellten Person kurz Neuigkeiten aus und nenne dann Meinung, Grund, teilweise Zustimmung und Rat. Trenne Fakten von Vermutungen. Vergleiche 갈래요 als Wahl, 갈게요 als eigene Zusage und 갈까 봐요 als vorläufige Absicht. Gib dieselben Fakten danach förmlich an die zuständige Person weiter. Inhalt und Intonation bleiben unbewertet.'),
        packet('동료에게 해요체: 주말 산책이 즐거웠음. 온라인 모임은 이동이 없어 좋다는 점에 동의하지만 자료 검토는 직접 만나서 하고 싶음. 공유 파일에 월요일이라고 적혀 있음. 화요일 표시는 미확인.\n내 선택: 버스. 내 약속: 담당자에게 확인하고 내일 알림. 동료에게 교통편을 미리 확인해 보라고 권유.\n담당자에게 하십시오체: 확인된 날짜와 모르는 표시를 구별해 문의.',[]),
        packet('동료에게 해요체: 주말 독서가 즐거웠음. 온라인 모임은 이동이 없어 좋다는 점에 동의하지만 자료 검토는 직접 만나서 하고 싶음. 공유 파일에 수요일이라고 적혀 있음. 목요일 표시는 미확인.\n내 선택: 기차. 내 약속: 담당자에게 확인하고 오늘 오후 알림. 동료에게 교통편을 미리 확인해 보라고 권유.\n담당자에게 하십시오체: 확인된 날짜와 모르는 표시를 구별해 문의.',[]))
    return [read,speak]


def kp08():
    teaching=loc('축하와 공감을 표현해도 담당자가 확인하지 않은 예외를 허가할 수는 없어요. 공지 작성자, 전달자, 수신자와 기한을 따로 확인해요. 게시글의 문의를 곧바로 규칙 변경으로 읽지 않아요.',
        'Congratulations and sympathy do not grant an exception that staff have not approved. Separate author, messenger, recipient and deadline. A question in a post does not change a rule.',
        'Gratulation und Mitgefühl erlauben keine Ausnahme, die die zuständige Person nicht bestätigt hat. Unterscheide Verfasser, übermittelnde Person, Empfänger und Frist. Eine Frage in einem Beitrag ändert keine Regel.')
    def post(name,day,next_day):
        return packet(f'모임 공지 전달\n{name}: 안내 직원에게서 받았어요. 활동 기록은 {day}까지 제출할 것. 제가 전체 회원에게 전달합니다.\n회원: 작품을 완성해서 기쁜데, 제출 화면이 열리지 않아요. {next_day}에 내도 될까요?\n{name}: 완성하신 것을 축하해요! 화면 때문에 불편하시겠어요. 하지만 예외는 제가 허가할 수 없어요. 담당자에게 오류를 알리고 기한을 확인해 볼게요.',[
            choice('source',loc('원래 공지의 출처는?', 'Who issued the original notice?', 'Von wem stammt der ursprüngliche Hinweis?'),['안내 직원',name],teaching),
            choice('problem',loc('회원의 불편은?', 'What problem does the member report?', 'Welches Problem meldet das Mitglied?'),['제출 화면이 열리지 않아요.','작품을 아직 시작하지 않았어요.'],teaching),
            choice('exception',loc('기한은 연장됐어요?', 'Was the deadline extended?', 'Wurde die Frist verlängert?'),['아니요. 담당자 확인 전이에요.',f'네. {next_day}까지로 바뀌었어요.'],teaching),
            choice('response',loc('축하한 이유는?', 'Why was congratulations offered?', 'Wozu wurde gratuliert?'),['작품을 완성했어요.','제출 오류가 해결됐어요.'],teaching),
        ])
    read=task('KP08','reading:02','reading',loc('공지 아래 문의와 공감','A question and a considerate reply below a notice','Nachfrage und Anteilnahme unter einem Hinweis'),teaching,
        post('미나','월요일','화요일'),post('준호','화요일','수요일'))
    speak=task('KP08','speaking:02','speaking',loc('상태·불편·출처를 세 청자에게 말하기','State a problem and its source to three audiences','Zustand, Problem und Quelle drei Personen mitteilen'),
        loc('열려 있어요·열고 있어요와 앉아 있어요·옮기고 있어요를 상태와 진행으로 나눠 말해요. 이어서 친구·새 회원·담당자에게 관계에 맞는 말투로 같은 사실을 전하세요. 축하·공감 뒤에도 기한 연장을 약속하지 마세요. 녹음을 듣고 휴지·말끝을 수정해요. 의미와 발음은 미채점이에요.',
            'Distinguish resulting states from ongoing actions in 열려 있어요/열고 있어요 and 앉아 있어요/옮기고 있어요. Then relay the same facts to a friend, new member and organiser in the appropriate register. Do not promise a deadline extension after congratulations or sympathy. Replay and revise pauses and endings; meaning and pronunciation remain unscored.',
            'Unterscheide Zustand und laufende Handlung bei 열려 있어요/열고 있어요 und 앉아 있어요/옮기고 있어요. Gib dieselben Fakten dann einem Freund oder einer Freundin, einem neuen Mitglied und der zuständigen Person im passenden Sprachstil weiter. Versprich auch nach Gratulation oder Mitgefühl keine Fristverlängerung. Höre zu und überarbeite Pausen und Endungen; Inhalt und Aussprache bleiben unbewertet.'),
        packet('출처: 안내 직원. 공지: 월요일까지 기록 제출. 회원은 작품을 완성했지만 제출 화면이 열리지 않아 불편함. 화요일 제출 가능 여부는 아직 미확인.\n1. 반말에 합의한 친구에게 축하·공감과 사실 전달. 2. 새 회원에게 해요체로 출처·기한·미확인 사항 전달. 3. 담당자에게 하십시오체로 화면 문제와 기한 문의. 개인정보는 추가하지 마세요.',[]),
        packet('출처: 안내 직원. 공지: 화요일까지 기록 제출. 회원은 발표를 마쳤지만 제출 화면이 열리지 않아 불편함. 수요일 제출 가능 여부는 아직 미확인.\n1. 반말에 합의한 친구에게 축하·공감과 사실 전달. 2. 새 회원에게 해요체로 출처·기한·미확인 사항 전달. 3. 담당자에게 하십시오체로 화면 문제와 기한 문의. 개인정보는 추가하지 마세요.',[]))
    intimate_teaching=loc('친밀한 말투는 반말 어미만의 문제가 아니에요. 서로 가까운 관계와 개인적인 대화 맥락을 확인하세요. 같은 말을 처음 만난 사람이나 전체 회원에게 그대로 옮기지 않아요.',
        'Intimacy is not established by a casual ending alone. Check the close relationship and private conversation. Do not transfer the same wording to a stranger or a public group.',
        'Vertrautheit entsteht nicht allein durch eine informelle Endung. Achte auf die enge Beziehung und das persönliche Gespräch. Übertrage dieselben Worte nicht einfach auf Fremde oder eine öffentliche Gruppe.')
    def intimate(event,feeling):
        return packet(f'사적으로 이야기하는 오래된 가까운 친구. 서로 반말을 쓰기로 했고 개인적인 고민을 나누는 사이예요.\n가: {event} 좀 {feeling}.\n나: 그랬구나. 내 앞에서는 괜찮은 척 안 해도 돼. 네 얘기 듣고 싶어.\n가: 고마워. 네가 있어서 마음이 놓여.\n다음은 처음 만난 회원에게 하는 안내예요.\n나: 안녕하세요. 안내가 필요하시면 말씀해 주세요.',[
            choice('relationship',loc('앞부분의 친밀한 말투를 이해할 근거는?', 'What supports the intimate tone in the first part?', 'Was begründet den vertrauten Ton im ersten Teil?'),['오래된 가까운 친구가 사적으로 고민을 나눠요.','반말이면 누구와도 이미 친밀한 사이예요.'],intimate_teaching),
            choice('audience',loc('같은 친밀한 말을 새 회원에게 바로 사용해도 돼요?', 'Can the same intimate wording simply be used with the new member?', 'Kann man diese vertrauten Worte einfach auch an das neue Mitglied richten?'),['아니요. 관계와 상황에 맞게 바꿔요.','네. 가까운 사이인지 확인할 필요가 없어요.'],intimate_teaching),
        ])
    close_read=task('KP08','reading:03','reading',loc('친밀함을 만드는 관계와 맥락','The relationship and context behind intimacy','Beziehung und Kontext vertrauter Sprache'),intimate_teaching,
        intimate('오늘 발표를 마쳤는데','지쳤어'),intimate('오늘 모임에서 실수했는데','속상해'))
    return [read,speak,close_read]


if __name__ == '__main__':
    for phase,factory in [('KP05',kp05),('KP06',kp06),('KP07',kp07),('KP08',kp08)]:
        extras=factory();ids={t['id'] for t in extras}
        source=json.loads((FOLDER/f'{phase.lower()}.json').read_text(encoding='utf-8'))
        write_source(phase,[t for t in source['tasks'] if t['id'] not in ids]+extras)
