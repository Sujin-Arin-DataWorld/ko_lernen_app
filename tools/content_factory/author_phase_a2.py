"""A2 source authoring. Nothing here signs a publication review."""
from phase_task_authoring import choice, grammar_task, loc, packet, sentence, task, write_source


def kp05():
    rows = [
        ('G2:-으면',loc('-(으)면 앞은 조건이에요. 조건이 주어졌다고 해서 이미 충족된 것은 아니에요.', 'The clause before -(으)면 is a condition, not proof that it has been met.', 'Vor -(으)면 steht eine Bedingung. Damit ist nicht gesagt, dass sie erfüllt ist.'),('학생증이 있으면 할인돼요.','학생증이 있는 경우 할인된다고 해요.','모든 손님이 학생증 없이 할인받아요.'),('예약하면 회의실을 이용할 수 있어요.','예약한 경우 이용할 수 있다고 말해요.','지금 모든 사람이 예약을 끝냈어요.')),
        ('G2:-거나',loc('-거나는 행동·상태의 대안이에요. 두 행동을 모두 해야 한다는 뜻은 아니에요.', '-거나 gives alternative actions or states; it does not require both.', '-거나 nennt alternative Handlungen oder Zustände. Beides ist nicht zwingend erforderlich.'),('기다리는 동안 책을 읽거나 음악을 들으세요.','두 행동 중에서 고를 수 있어요.','두 행동을 반드시 동시에 해야 해요.'),('신청서는 직접 내거나 이메일로 보내세요.','제출 방법을 고를 수 있어요.','직접 낸 다음 반드시 이메일도 보내야 해요.')),
        ('G2:이나',loc('명사에는 (이)나를 붙여 선택지를 이어요. 행동을 잇는 -거나와 구별해요.', '(이)나 links noun alternatives; distinguish action alternatives with -거나.', '(이)나 verbindet alternative Nomen. Für Handlungsalternativen steht -거나.'),('차나 커피를 하나 고르세요.','차와 커피 중 하나를 골라요.','차와 커피를 모두 받아요.'),('신분 확인에는 여권이나 학생증을 보여 주세요.','여권과 학생증 중 하나를 보여 줘요.','두 서류를 모두 보여 줘야 해요.')),
        ('G2:마다',loc('마다의 반복 범위는 앞 명사예요. 월요일마다는 모든 월요일이지 매일이 아니에요.', '마다 repeats over the preceding unit. 월요일마다 means every Monday, not every day.', '마다 bezieht sich auf die genannte Einheit. 월요일마다 heißt jeden Montag, nicht jeden Tag.'),('월요일마다 문을 닫아요.','매주 월요일에 닫아요.','매일 문을 닫아요.'),('수업이 끝날 때마다 창문을 닫아요.','각 수업이 끝날 때 창문을 닫아요.','첫 수업이 끝날 때만 닫아요.')),
        ('G2:밖에',loc('밖에는 여기서 부정과 함께 범위를 제한해요. 두 개밖에 없다는 두 개가 있다는 뜻이에요.', 'With negation, 밖에 limits the amount. 두 개밖에 없다 means there are only two, not zero.', 'Mit einer Verneinung begrenzt 밖에 die Menge. 두 개밖에 없다 bedeutet nur zwei, nicht null.'),('빈자리가 하나밖에 없어요.','빈자리는 한 개예요.','빈자리가 전혀 없어요.'),('충전기가 두 개밖에 없어요.','충전기는 두 개예요.','충전기는 두 개보다 많아요.')),
        ('G2:처럼',loc('처럼은 비슷한 모습이나 방식을 비교해요. 비교한다고 같은 사람이나 물건이 되는 것은 아니에요.', '처럼 compares appearance or manner; it does not make two people or objects identical.', '처럼 vergleicht Aussehen oder Art und Weise. Die verglichenen Personen oder Dinge sind nicht identisch.'),('예시처럼 이름을 크게 써 주세요.','예시의 쓰는 방식을 따라요.','예시에 있는 다른 사람 이름을 그대로 써요.'),('직원처럼 천천히 읽어 보세요.','직원의 읽는 속도를 참고해요.','읽는 사람이 직원으로 바뀌어요.')),
        ('G2:-어도 되다',loc('-아/어도 되다는 허용이에요. 반드시 해야 한다는 의무와 구별해요.', '-아/어도 되다 gives permission, not an obligation.', '-아/어도 되다 drückt eine Erlaubnis aus, keine Pflicht.'),('가방을 여기에 놓아도 돼요.','여기에 놓는 것이 허용돼요.','반드시 여기에 놓아야 해요.'),('이 방에서는 물을 마셔도 돼요.','물을 마시는 것이 허용돼요.','물을 마시면 안 돼요.')),
        ('G2:-지 말다',loc('-지 말다는 행동을 하지 말라는 요청·금지예요. 해도 된다는 말로 바꾸지 않아요.', '-지 말다 asks or instructs someone not to act; it is not permission.', '-지 말다 fordert dazu auf, etwas nicht zu tun. Es ist keine Erlaubnis.'),('이 방에서는 사진을 찍지 마세요.','사진 촬영을 하지 말라는 안내예요.','사진을 찍어도 된다는 안내예요.'),('비상문 앞에 물건을 놓지 마세요.','비상문 앞을 비워 두라는 안내예요.','비상문 앞에 물건을 모으라는 안내예요.')),
        ('G2:-어 주다',loc('-아/어 주다는 다른 사람을 위해 하는 행동이에요. 누가 누구를 돕는지 확인해요.', '-아/어 주다 presents an action done for another person. Identify helper and beneficiary.', '-아/어 주다 bezeichnet eine Handlung für eine andere Person. Achte darauf, wer wem hilft.'),('직원이 손님에게 길을 알려 줘요.','직원이 손님을 도와요.','손님이 직원에게 길을 알려 줘요.'),('친구가 제 신청서를 읽어 줬어요.','친구가 나를 위해 읽었어요.','내가 친구를 위해 읽었어요.')),
    ]
    tasks=[grammar_task('KP05',i,*row) for i,row in enumerate(rows,1)]
    def counter(document,first,price,second,other_price,forbidden,allowed):
        prohibition = {'사진을 찍어': '사진을 찍지', '음식을 먹어': '음식을 먹지'}[forbidden]
        return packet(f'직원: 대여에는 {document}이 필요해요. {document}이 있으면 방을 빌릴 수 있어요. {first}은 한 시간에 {price} 원이고, {second}은 {other_price} 원이에요.\n손님: 방에서 {forbidden}도 돼요?\n직원: 아니요, {prohibition} 마세요. {allowed}도 돼요.\n손님: 네, 알겠습니다.',[
            choice('condition',loc('방을 빌릴 때 필요한 것은?', 'What is required to rent a room?', 'Was braucht man, um einen Raum zu mieten?'),[document,'준비물이 없음'],loc(f'{document}이 이용 조건으로 제시됐어요.',f'{document} is the stated condition.',f'{document} wird als Voraussetzung genannt.')),
            choice('price',loc('더 싼 방과 시간당 가격은?', 'Which room is cheaper, and what is its hourly price?', 'Welcher Raum ist günstiger und was kostet er pro Stunde?'),[f'{first} / {price}원',f'{second} / {price}원',f'{first} / {other_price}원'],loc(f'{first}은 {price}원, {second}은 {other_price}원이에요. 방과 가격을 바꾸지 않아요.',f'{first} costs {price} won and {second} {other_price} won per hour. Keep each price with its room.',f'{first} kostet {price} Won und {second} {other_price} Won pro Stunde. Ordne jeden Preis dem richtigen Raum zu.')),
            choice('permission',loc('직원이 허용한 것은?', 'What does the staff member permit?', 'Was erlaubt die Person vom Personal?'),[allowed+'도 돼요.',forbidden+'도 돼요.'],loc('직원이 아니요라고 한 행동과 허용한 행동을 따로 확인해요.', 'Separate the action refused with 아니요 from the permitted action.', 'Trenne die mit 아니요 abgelehnte Handlung von der erlaubten.')),
        ],'audio')
    tasks.append(task('KP05','listening:01','listening',loc('창구의 조건과 가격', 'Conditions and prices at the counter', 'Bedingungen und Preise am Schalter'),
        loc('이 과제의 가상 시설 안내를 들어요. 조건, 방별 시간당 가격, 허용·금지를 각각 확인하세요.', 'Listen to this fictional facility’s rules. Check the condition, hourly room prices, permission and prohibition separately.', 'Höre die Angaben zur fiktiven Einrichtung. Prüfe Voraussetzung, Stundenpreise sowie Erlaubnis und Verbot getrennt.'),
        counter('학생증','작은 방','오천','큰 방','팔천','사진을 찍어','물을 마셔'),
        counter('회원증','조용한 방','육천','넓은 방','구천','음식을 먹어','차를 마셔')))
    def notice(day,item,count,prohibited,needed):
        topic = '은' if item == '사전' else '는'
        return packet(f'학습실 이용 공지\n입장할 때 {needed}을 보여 주세요.\n{day}마다 청소하므로 오전에는 이용할 수 없습니다.\n빌릴 수 있는 {item}{topic} {count} 개밖에 없습니다.\n{prohibited} 마세요.\n이용 후 의자를 제자리에 놓아 주세요.',[
            choice('preparation',loc('입장할 때 준비할 것은?', 'What must you have when entering?', 'Was muss man beim Eintritt vorzeigen?'),[needed,'공지에 준비물이 없음'],loc(f'{needed}을 보여 달라는 안내예요.',f'The notice asks you to show {needed}.',f'Der Aushang verlangt {needed}.')),
            choice('repeat',loc('오전에 이용할 수 없는 범위는?', 'Which mornings are unavailable?', 'An welchen Vormittagen ist der Raum nicht nutzbar?'),[f'매주 {day}','모든 요일의 오전'],loc(f'{day}마다는 그 요일마다 반복된다는 뜻이에요.',f'{day}마다 repeats on that weekday.',f'{day}마다 bezeichnet eine Wiederholung an diesem Wochentag.')),
            choice('only',loc('빌릴 수 있는 물건 수는?', 'How many items are available to borrow?', 'Wie viele Gegenstände können ausgeliehen werden?'),[count,'영'],loc(f'{count} 개밖에 없다는 {count} 개가 있다는 뜻이에요.',f'{count} 개밖에 없다 means only {count}, not zero.',f'{count} 개밖에 없다 bedeutet nur {count}, nicht null.')),
            choice('prohibition',loc('금지한 행동은?', 'Which action is prohibited?', 'Welche Handlung ist verboten?'),[prohibited+' 마세요.','이용 후 의자를 제자리에 놓지 마세요.'],loc('의자를 제자리에 놓기는 요청한 행동이에요. 금지 행동과 바꾸지 않아요.', 'Putting the chair back is requested. Do not turn it into a prohibition.', 'Den Stuhl zurückzustellen wird verlangt. Mache daraus kein Verbot.')),
        ],'sign')
    tasks.append(task('KP05','reading:01','reading',loc('공지와 간단한 사용법', 'Read a notice and short instructions', 'Aushang und kurze Anleitung lesen'),
        loc('반복 범위와 밖에 뒤 부정을 읽어요. 준비물, 금지, 사용 후 행동을 구별해요.', 'Read the repetition scope and negation after 밖에. Separate requirements, prohibitions and after-use actions.', 'Lies den Wiederholungsbereich und die Verneinung nach 밖에. Trenne Voraussetzungen, Verbote und Schritte nach der Nutzung.'),
        notice('화요일','충전기','두','창문을 열지','학생증'),
        notice('목요일','사전','세','음식을 먹지','회원증')))
    def request(condition,permission,help_text):
        return packet(f'가상 시설에 확인 메시지를 써요. 아직 답을 받지 않았어요.\n확인할 조건: {condition}\n허용 여부를 물을 행동: {permission}\n직원에게 부탁할 도움: {help_text}',[
            sentence('condition',loc('조건을 확인하는 질문을 쓰세요.', 'Write a question checking the condition.', 'Schreibe eine Frage zur Bedingung.'),[condition+'?',condition+'? 확인 부탁드려요.'],['조건 없이 이용할 수 있어요.'],loc(f'예: {condition}? 확인 전 조건을 없애지 않아요.',f'Example: {condition}? Do not remove an unconfirmed condition.',f'Beispiel: {condition}? Streiche keine unbestätigte Voraussetzung.')),
            sentence('permission',loc('허용 여부를 질문하세요.', 'Ask whether the action is permitted.', 'Frage, ob die Handlung erlaubt ist.'),[permission+'?'],[permission+'. 허락받았어요.'],loc(f'예: {permission}? 아직 허가를 받았다는 뜻은 아니에요.',f'Example: {permission}? Asking is not evidence of permission already granted.',f'Beispiel: {permission}? Die Frage belegt keine bereits erteilte Erlaubnis.')),
            sentence('help',loc('도움을 부탁하세요.', 'Request help.', 'Bitte um Hilfe.'),[help_text+'.','죄송하지만 '+help_text+'.'],[help_text.replace('주세요','주지 마세요')+'.'],loc(f'예: {help_text}. 금지가 아니라 도움 요청이에요.',f'Example: {help_text}. It requests help, rather than prohibiting it.',f'Beispiel: {help_text}. Es ist eine Bitte um Hilfe, kein Verbot.')),
        ],'form')
    tasks.append(task('KP05','writing:01','writing',loc('조건·허가·도움 확인 메시지', 'Ask about conditions, permission and help', 'Nach Bedingungen, Erlaubnis und Hilfe fragen'),
        loc('세 화행을 다른 문장으로 쓰세요. 질문을 허가받았다는 확정으로 바꾸지 않아요. 다른 자유 표현은 미채점으로 남을 수 있어요.', 'Use separate sentences for the three functions. A question does not establish granted permission. Other free wording may remain unscored.', 'Schreibe für die drei Funktionen getrennte Sätze. Eine Frage ist keine erteilte Erlaubnis. Andere freie Formulierungen können unbewertet bleiben.'),
        request('학생증이 있으면 방을 빌릴 수 있나요','가방을 여기에 놓아도 되나요','신청서 쓰는 것을 도와주세요'),
        request('회원증이 있으면 사전을 빌릴 수 있나요','여기에서 차를 마셔도 되나요','이용 시간을 알려 주세요')))
    tasks.append(task('KP05','speaking:01','speaking',loc('창구에서 대안 고르기', 'Choose an option at the counter', 'Am Schalter eine Alternative wählen'),
        loc('직원에게 조건을 확인한 뒤 명사 선택과 행동 선택을 말해요. (이)나와 -거나를 구별하고 허용을 의무로 바꾸지 않아요. 녹음을 듣고 다시 말해 보세요. 발화 의미는 자동 채점하지 않아요.', 'Check the condition with staff, then state noun and action alternatives. Distinguish (이)나 from -거나 and permission from obligation. Listen back and re-record. Meaning remains unscored.', 'Kläre die Bedingung mit dem Personal und nenne dann Nomen- und Handlungsalternativen. Trenne (이)나 von -거나 und Erlaubnis von Pflicht. Höre deine Aufnahme an und wiederhole sie. Der Inhalt bleibt unbewertet.'),
        packet('학교 안내 창구. 학생증이 있으면 이용 가능.\n이용 장소: 열람실 또는 회의실 중 하나.\n가능한 활동: 책 읽기 또는 한국어 공부하기.\n조건을 확인하고 장소와 활동을 하나씩 골라 말하세요.',[]),
        packet('문화센터 안내 창구. 회원증이 있으면 이용 가능.\n빌릴 물건: 사전 또는 잡지 중 하나.\n가능한 활동: 안에서 읽기 또는 집에 빌려 가기.\n조건을 확인하고 물건과 활동을 하나씩 골라 말하세요.',[])))
    return tasks


if __name__ == '__main__':
    from author_phase_kp06 import kp06
    from author_phase_kp07 import kp07
    from author_phase_kp08 import kp08
    import author_phase_a2_genres as genres
    import author_phase_a2_extensions as extensions
    for phase, build in [('KP05',kp05),('KP06',kp06),('KP07',kp07),('KP08',kp08)]:
        write_source(phase,build()+getattr(genres,phase.lower())()+getattr(extensions,phase.lower())())
