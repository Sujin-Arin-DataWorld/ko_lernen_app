"""KP08 notice mediation and resulting states. Unsigned authored sources."""
from phase_task_authoring import choice, grammar_task, loc, packet, sentence, task, write_source


def object_phrase(noun):
    return noun + ('을' if (ord(noun[-1]) - 0xAC00) % 28 else '를')


def kp08():
    rows = [
        ('G2:-음',loc('공지의 -(으)ㅁ은 사실을 간결하게 적는 명사형이에요. 없음을 있음으로 읽지 않아요.', 'Notices use -(으)ㅁ for concise nominal statements. Do not reverse absence and presence.', 'Aushänge verwenden -(으)ㅁ für knappe nominale Aussagen. Vertausche Fehlen und Vorhandensein nicht.'),('오늘 오후 수업 없음.','오늘 오후에는 수업이 없어요.','오늘 오후에는 수업이 있어요.'),('신청 접수 마감됨.','신청 접수가 끝났어요.','신청 접수가 아직 시작되지 않았어요.')),
        ('G2:께',loc('께는 높이는 받는 사람을 나타내요. 보내는 사람이나 출처와 바꾸지 않아요.', '께 marks an honored recipient, not the sender or source.', '께 markiert eine respektvoll bezeichnete empfangende Person, nicht den Absender oder die Quelle.'),('제가 선생님께 메일을 보냈어요.','받는 사람은 선생님이에요.','보낸 사람은 선생님이에요.'),('학생이 교수님께 질문했어요.','질문을 받은 사람은 교수님이에요.','교수님이 학생에게 질문했어요.')),
        ('G2:에게로',loc('에게로는 사람을 향한 이동 방향이에요. 그 사람에게서 온다는 출처와 구별해요.', '에게로 marks movement toward a person, not movement from that person.', '에게로 bezeichnet Bewegung auf eine Person zu, nicht von ihr weg.'),('아이가 안내원에게로 갔어요.','아이가 안내원을 향해 갔어요.','안내원이 아이에게 왔어요.'),('새 회원이 회장에게로 다가갔어요.','새 회원이 회장을 향해 움직였어요.','회장이 새 회원에게서 멀어졌어요.')),
        ('G2:에게서',loc('에게서는 사람인 출처를 표시해요. 받은 사람과 보낸 사람을 뒤집지 않아요.', '에게서 marks a person as the source. Do not swap sender and recipient.', '에게서 markiert eine Person als Quelle. Vertausche sendende und empfangende Person nicht.'),('유나가 민수에게서 공지를 받았어요.','공지 출처는 민수예요.','공지 출처는 유나예요.'),('제가 친구에게서 사진을 받았어요.','친구가 사진을 보내 줬어요.','제가 친구에게 사진을 보냈어요.')),
        ('G2:한테서',loc('한테서는 구어에서 사람인 출처를 나타내요. 한테와 달리 여기서는 누구에게 받았는지를 말해요.', '한테서 commonly marks a personal source in speech; here it identifies who something came from.', '한테서 bezeichnet mündlich häufig eine Person als Quelle. Hier zeigt es, von wem etwas kommt.'),('지수한테서 문자가 왔어.','지수가 문자 발신자예요.','지수가 문자를 받은 사람이에요.'),('나는 준호한테서 소식을 들었어.','소식을 전한 사람은 준호예요.','내가 준호에게 소식을 전했어요.')),
        ('G2:에다가',loc('에다가는 여기서 물건을 놓거나 넣을 곳을 구체적으로 말해요.', 'Here, 에다가 specifies where an object is to be put or placed.', 'Hier bezeichnet 에다가 konkret den Ort, an den ein Gegenstand gelegt oder gestellt wird.'),('책상에다가 신청서를 놓으세요.','신청서를 놓을 곳은 책상이에요.','책상에서 신청서를 가져오라는 말이에요.'),('상자에다가 안내문을 넣어 주세요.','안내문을 넣을 곳은 상자예요.','상자에서 안내문을 빼라는 말이에요.')),
        ('G2:에서부터(서부터)',loc('에서부터는 이동의 출발 지점을 강조해요. 도착 지점과 바꾸지 않아요.', '에서부터 emphasizes the starting point of movement, not the destination.', '에서부터 betont den Ausgangspunkt einer Bewegung, nicht das Ziel.'),('역에서부터 센터까지 걸었어요.','출발은 역, 도착은 센터예요.','출발은 센터, 도착은 역이에요.'),('학교에서부터 도서관까지 같이 갔어요.','출발은 학교, 도착은 도서관이에요.','출발은 도서관, 도착은 학교예요.')),
        ('G2:-네',loc('-네요는 방금 알아차린 사실에 대한 반응이 될 수 있어요. 여기서는 명령이 아니에요.', '-네요 can react to a newly noticed fact. Here it is not a command.', '-네요 kann auf etwas gerade Bemerktes reagieren. Hier ist es kein Befehl.'),('처음 와 봤는데, 여기가 넓네요!','처음 보고 넓다는 점에 반응해요.','더 넓게 만들라고 명령해요.'),('오, 오늘은 사람이 많네요!','사람이 많다는 사실을 보고 반응해요.','사람을 더 부르라고 지시해요.')),
        ('G2:-는군',loc('-군요/-는군요는 새로 깨달은 점을 드러낼 수 있어요. 감탄을 지시로 해석하지 않아요.', '-군요/-는군요 can express a new realization. Do not interpret this reaction as an instruction.', '-군요/-는군요 kann eine neue Erkenntnis ausdrücken. Lies diese Reaktion nicht als Anweisung.'),('아, 이 문이 출구였군요.','문이 출구라는 점을 새로 알았어요.','문을 출구로 바꾸라고 명령해요.'),('설명을 들으니 이제 알겠어요. 매일 연습하는군요.','매일 연습한다는 것을 새로 알았어요.','매일 연습하라고 명령해요.')),
        ('G2:-는데2',loc('감탄의 말끝 -는데요는 기대와 다른 평가를 드러낼 수 있어요. 이 문맥에서는 이어질 반대 이유가 아니에요.', 'Exclamatory -는데요 can express an unexpected evaluation. In this context it is not an unfinished contrast.', 'Ausrufendes -는데요 kann eine unerwartete Bewertung ausdrücken. Hier ist es kein unvollständiger Gegensatz.'),('생각보다 훨씬 좋네요. 이 공연, 재미있는데요!','공연에 대한 긍정적 놀라움이에요.','공연이 재미없다는 반박이에요.'),('와, 처음인데 잘하시는데요!','처음인데 잘한다는 감탄이에요.','잘하지 못했다는 비판이에요.')),
        ('G2:-지',loc('여기서 -지?는 서로 아는 내용을 확인하는 친근한 물음이에요. 반말은 합의된 가까운 관계에서만 써요.', 'Here, -지? informally checks shared knowledge. Use casual speech only in an agreed close relationship.', 'Hier bestätigt das informelle -지? gemeinsames Wissen. Verwende vertrauliche Sprache nur bei entsprechend vereinbarter Nähe.'),('반말을 쓰기로 한 친구에게: 우리 내일 만나지?','이미 이야기한 약속을 확인해요.','처음 만난 사람에게 새 명령을 해요.'),('반말을 쓰기로 한 동료에게: 모임은 세 시부터지?','공유한 시작 시간을 확인해요.','모임 시간을 다섯 시로 바꾸자고 해요.')),
        ('G2:-어 있다',loc('-아/어 있다는 행동 후 남아 있는 상태예요. 문을 여는 중인 -고 있다와 구별해요.', '-아/어 있다 describes a resulting state, unlike the ongoing action of opening a door.', '-아/어 있다 beschreibt einen fortbestehenden Ergebniszustand, anders als das gerade laufende Öffnen einer Tür.'),('문이 열려 있어요.','문이 열린 상태예요.','문을 여는 동작이 진행 중이에요.'),('모두 의자에 앉아 있어요.','앉은 상태가 유지돼요.','모두 지금 일어서는 중이에요.')),
        ('G2:-을 것1',loc('공지의 -(으)ㄹ 것은 여기서 축약된 지시예요. 미래 예측의 것과 기능이 달라요.', 'In this notice, -(으)ㄹ 것 is a shortened directive, not a forecast.', 'In diesem Aushang ist -(으)ㄹ 것 eine verkürzte Anweisung, keine Vorhersage.'),('신청서는 금요일까지 제출할 것.','금요일까지 내라는 지시예요.','금요일에 낼 것이라는 예측이에요.'),('이용 후 전원을 끌 것.','사용이 끝나면 전원을 끄라는 지시예요.','전원이 저절로 꺼질 것이라는 예측이에요.')),
        ('G1:-고 있다',loc('여기서 -고 있다는 진행 중인 동작이에요. 행동이 끝난 뒤 남는 상태와 구분해요.', 'Here, -고 있다 describes an action in progress, not the state left after it finishes.', 'Hier beschreibt -고 있다 eine laufende Handlung, nicht den Zustand nach ihrem Ende.'),('직원이 창문을 닫고 있어요.','창문을 닫는 동작 중이에요.','창문이 이미 닫혀 있는 상태만 말해요.'),('회원이 의자를 옮기고 있어요.','의자 이동이 진행 중이에요.','의자가 옮겨진 뒤의 상태만 말해요.')),
    ]
    ts=[grammar_task('KP08',i,*r) for i,r in enumerate(rows,1)]
    def relayed(source,recipient,day,object_):
        return packet(f'민지: 안녕하세요. {source}에게서 공지를 받았어요. {day}까지 {object_phrase(object_)} 내라고 하셨어요. 제가 {recipient}께 전달할게요.\n새 회원: 아, 마감이 {day}이군요. 알려 주셔서 감사합니다.',[
            choice('source',loc('민지가 공지를 받은 출처는?', 'Who gave 민지 the notice?', 'Von wem hat 민지 die Mitteilung erhalten?'),[source,recipient],loc('에게서는 받은 출처, 께는 전달할 받는 사람이에요.', '에게서 marks the source; 께 marks the intended recipient.', '에게서 markiert die Quelle, 께 die vorgesehene empfangende Person.')),
            choice('recipient',loc('민지가 전달할 대상은?', 'Who will 민지 relay it to?', 'An wen wird 민지 die Mitteilung weitergeben?'),[recipient,source],loc(f'전달할 대상은 {recipient}이에요.',f'The intended recipient is {recipient}.',f'Die Mitteilung soll an {recipient} weitergegeben werden.')),
            choice('function',loc('새 회원의 군요는 어떤 반응인가요?', 'What does the new member’s 군요 express?', 'Was drückt 군요 bei der neuen Person aus?'),['마감을 새로 알게 됨','다른 사람에게 새 마감을 명령함'],loc('새로 들은 마감을 이해한 반응이며 지시를 새로 만들지 않아요.', 'It acknowledges learning the deadline, not issuing a new directive.', 'Die Reaktion bestätigt den neu erfahrenen Termin, sie erteilt keine neue Anweisung.')),
            choice('deadline',loc('전달해야 할 마감은?', 'Which deadline must be preserved?', 'Welcher Termin muss erhalten bleiben?'),[day,'기한 없음'],loc(f'{day}까지라는 지시를 유지해요.',f'Preserve the deadline {day}.',f'Erhalte die Frist {day}.')),
        ],'audio')
    ts.append(task('KP08','listening:01','listening',loc('공지의 출처와 전달 대상', 'Source and recipient of a notice', 'Quelle und Empfänger einer Mitteilung'),
        loc('듣는 사람과 말하는 사람, 출처와 최종 수신자를 구별해요.', 'Distinguish speaker, listener, original source and final recipient.', 'Unterscheide sprechende und zuhörende Person, ursprüngliche Quelle und endgültigen Empfänger.'),
        relayed('담당 선생님','회장님','금요일','신청서'), relayed('안내 직원','지도 교수님','월요일','명단')))
    def manual(item,place,deadline):
        return packet(f'모임 회원용 {item} 이용 안내\n보관함이 열려 있음.\n1. 먼저 명단에 이름을 적을 것.\n2. {object_phrase(item)} 꺼내서 사용할 것.\n3. 이용 후 {place}에다가 돌려놓을 것.\n{deadline}까지 반납할 것. 체험만 하는 사람도 같은 순서를 지킬 것.',[
            choice('state',loc('현재 남아 있는 상태는?', 'What is the current resulting state?', 'Welcher Zustand besteht gerade?'),['보관함이 열린 상태','직원이 보관함을 여는 중'],loc('열려 있음은 열린 상태이며 여는 동작의 진행이 아니에요.', '열려 있음 means the cabinet is open, not being opened.', '열려 있음 heißt, dass der Schrank offen ist, nicht gerade geöffnet wird.')),
            choice('sequence',loc('물건을 꺼내기 전에 할 일은?', 'What must happen before taking the item?', 'Was muss vor dem Herausnehmen geschehen?'),['명단에 이름 적기',f'{place}에 반납하기'],loc('먼저라는 순서 지시를 유지해요.', 'Preserve the order indicated by 먼저.', 'Erhalte die mit 먼저 angegebene Reihenfolge.')),
            choice('deadline',loc('반납 지시의 뜻은?', 'What does the return instruction mean?', 'Was bedeutet die Rückgabeanweisung?'),[f'{deadline}까지 반납해야 함',f'{deadline}에 누군가 반납할 것이라는 예측'],loc('-할 것은 미래 예측이 아니라 이용자에게 주는 지시예요.', '-할 것 is a directive to the user, not a prediction.', '-할 것 ist eine Anweisung an die nutzende Person, keine Vorhersage.')),
            choice('scope',loc('체험만 하는 사람은?', 'What about trial participants?', 'Was gilt für Personen, die nur probeweise teilnehmen?'),['같은 순서를 지켜야 함','명단 작성을 생략해도 됨'],loc('체험 참가자에게도 같은 순서를 명시했어요.', 'The same sequence is explicitly required for trial participants.', 'Für die Probeteilnahme ist ausdrücklich dieselbe Reihenfolge vorgeschrieben.')),
        ],'sign')
    ts.append(task('KP08','reading:01','reading',loc('공지 속 상태와 사용 순서', 'States and steps in a notice', 'Zustände und Arbeitsschritte im Aushang'),
        loc('적용 대상·순서·기한을 읽고 명사형 상태와 축약 지시를 구별해요.', 'Identify scope, sequence and deadline; distinguish nominal state descriptions from shortened directives.', 'Erkenne Geltungsbereich, Reihenfolge und Frist. Trenne nominale Zustandsangaben von verkürzten Anweisungen.'),
        manual('카메라','오른쪽 선반','오후 여섯 시'), manual('마이크','왼쪽 서랍','오후 다섯 시')))
    def two_audiences(source,deadline,object_):
        formal=f'{source}의 안내에 따라 {deadline}까지 {object_phrase(object_)} 제출해 주세요.'
        casual=f'{source}에게서 공지를 받았어. {deadline}까지 {object_phrase(object_)} 내야 해.'
        return packet(f'원본 공지 작성자: {source}\n내용: {deadline}까지 {object_} 제출.\n공개 게시글 독자: 모임 전체 회원.\n이메일 독자: 이미 반말을 쓰기로 한 친구.\n같은 출처와 기한을 보존하세요.',[
            sentence('public',loc('공개 안내 문장을 쓰세요.', 'Write the public announcement sentence.', 'Schreibe den öffentlichen Hinweis.'),[formal], [formal.replace('제출해 주세요','제출하지 마세요')],loc(f'예: {formal} 공지의 의무를 금지로 바꾸지 않아요.',f'Example: {formal} Do not turn the required action into a prohibition.',f'Beispiel: {formal} Mache aus der geforderten Handlung kein Verbot.')),
            sentence('private',loc('친구에게 출처와 용건을 쓰세요.', 'Write the source and message to your friend.', 'Nenne der befreundeten Person Quelle und Anliegen.'),[casual,casual+' 확인했는지 답장 줘.'],[casual.replace('내야 해','안 내도 돼')],loc(f'예: {casual} 말투를 바꿔도 기한과 의무는 같아요.',f'Example: {casual} A change of register does not change the deadline or obligation.',f'Beispiel: {casual} Ein Registerwechsel ändert weder Frist noch Verpflichtung.')),
        ],'form')
    ts.append(task('KP08','writing:01','writing',loc('같은 공지를 두 독자에게', 'Relay one notice to two audiences', 'Eine Mitteilung an zwei Zielgruppen weitergeben'),
        loc('공개 글과 사적 이메일의 핵심 문장을 써요. 원문 작성자와 전달자를 구별하세요. 자유로운 전체 글은 이 문장 평가만으로 인증하지 않아요.', 'Write the key sentences for a public post and private email. Distinguish author from messenger. These sentence checks do not certify complete free-form texts.', 'Schreibe die Kernsätze für einen öffentlichen Beitrag und eine private E-Mail. Trenne Urheber und übermittelnde Person. Die Satzprüfung bewertet keinen vollständigen freien Text.'),
        two_audiences('담당 선생님','금요일','신청서'),two_audiences('안내 직원','화요일','활동 기록')))
    ts.append(task('KP08','speaking:01','speaking',loc('친구와 새 회원에게 안내하기', 'Relay instructions to a friend and new member', 'Hinweise an eine vertraute und eine neue Person weitergeben'),
        loc('반말에 합의한 친구에게는 친근하게, 처음 만난 회원에게는 해요체로 전해요. 출처·기한·지시 강도와 확인 기회를 보존하세요. 녹음 의미는 미채점이에요.', 'Use agreed casual speech with a friend and polite speech with a new member. Preserve source, deadline, directive strength and a chance to clarify. Recorded meaning is unscored.', 'Nutze vereinbarte vertrauliche Sprache unter Freunden und höfliche Sprache bei der neuen Person. Erhalte Quelle, Frist, Verbindlichkeit und Rückfragemöglichkeit. Der Aufnahmeinhalt bleibt unbewertet.'),
        packet('담당 선생님의 공지: 토요일 세 시까지 회의실에 모일 것.\n친구: 이미 반말에 합의한 가까운 친구.\n새 회원: 오늘 처음 만남.\n각 사람에게 같은 안내를 전달하고 어디로 가면 되나요라는 질문에 답하세요. 회의실은 2층이에요.',[]),
        packet('안내 직원의 공지: 수요일 두 시까지 자료실에 도착할 것.\n친구: 이미 반말에 합의한 가까운 친구.\n새 회원: 오늘 처음 만남.\n각 사람에게 같은 안내를 전달하고 자료실이 어디예요라는 질문에 답하세요. 자료실은 1층이에요.',[])))
    return ts


if __name__ == '__main__':
    write_source('KP08', kp08())
