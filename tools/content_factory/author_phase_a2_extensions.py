"""A2 remaining manual, phone, diary and audible-state practice."""
from phase_task_authoring import choice, free_text, loc, packet, task


def kp05():
    def manual(first,next_,last,exception):
        return packet(f'체험실 이용 순서\n먼저 {first}. 다음으로 {next_}. 이용 후 {last}.\n다만 {exception} 사람은 직원의 안내를 먼저 받아야 합니다. 이 경우도 이용 후 정리는 해야 합니다.',[
            choice('order',loc('일반 이용자의 순서는?', 'What is the ordinary sequence?', 'Wie ist der normale Ablauf?'),[f'{first} → {next_} → {last}',f'{next_} → {last} → {first}'],loc('먼저·다음·이용 후의 순서를 유지해요.', 'Keep the order of first, next and after use.', 'Erhalte die Abfolge zuerst, danach und nach der Nutzung.')),
            choice('exception',loc('직원의 안내를 먼저 받아야 하는 사람은?', 'Who needs staff guidance first?', 'Wer braucht zuerst die Anleitung des Personals?'),[exception+' 사람','모든 사람에게 예외 없음'],loc('다만 뒤에 특별히 적용되는 대상을 찾으세요.', 'Find the special group introduced after 다만.', 'Finde die mit 다만 eingeführte besondere Gruppe.')),
            choice('remaining_duty',loc('예외에 해당해도 해야 하는 일은?', 'What remains required for that group?', 'Was muss auch diese Gruppe tun?'),['이용 후 정리','아무것도 하지 않아도 됨'],loc('안내를 먼저 받아도 이용 후 정리는 해야 해요.', 'Receiving guidance first does not remove the cleanup requirement.', 'Die vorherige Anleitung hebt die Pflicht zum Aufräumen nicht auf.')),
        ],'sign')
    return [task('KP05','reading:03','reading',loc('사용 순서와 예외 조건', 'Operating steps and exceptions', 'Ablauf und Ausnahmen'),
        loc('예외는 안내 순서에만 적용돼요. 정리 의무까지 없어졌다고 읽지 마세요.', 'The exception changes the guidance sequence, not the duty to tidy up.', 'Die Ausnahme betrifft die Anleitung, nicht die Pflicht zum Aufräumen.'),
        manual('이름을 적으세요','도구를 받으세요','도구를 반납하세요','오늘 처음 온'),manual('예약 번호를 확인하세요','재료를 받으세요','작업대를 닦으세요','기계 사용법을 모르는')),
        task('KP05','speaking:02','speaking',loc('전화로 조건 되묻기', 'Clarify conditions by phone', 'Bedingungen am Telefon nachfragen'),
            loc('직원의 마지막 정보를 되받고 못 들은 것은 다시 물으세요. 허가·금지의 말끝이 달라지지 않게 듣고 다시 녹음해요. 의미와 억양 적합성은 자동 채점하지 않아요.', 'Repeat the staff member’s last information and ask again about what you missed. Review and re-record without changing permission or prohibition. Meaning and intonation appropriateness are not automatically scored.', 'Wiederhole die letzte Auskunft und frage nach nicht Verstandenem. Prüfe und wiederhole die Aufnahme, ohne Erlaubnis oder Verbot zu ändern. Inhalt und angemessene Intonation werden nicht automatisch bewertet.'),
            packet('문화센터에 예약하려고 전화했어요. 직원: 토요일 두 시, 학생증을 가져오세요. 음료는 마셔도 돼요. 사진은 찍지 마세요.\n가격은 못 들었어요. 시간·준비물·허용·금지를 확인하고 가격은 다시 물어보세요.',[]),
            packet('체험실에 예약하려고 전화했어요. 직원: 일요일 세 시, 회원증을 가져오세요. 가방은 가져와도 돼요. 음식은 먹지 마세요.\n호실은 못 들었어요. 시간·준비물·허용·금지를 확인하고 호실은 다시 물어보세요.',[]))]


def kp06():
    prompt=loc('시작·전개·결과가 있는 짧은 일기를 쓰세요.', 'Write a short diary with a beginning, development and outcome.', 'Schreibe einen kurzen Tagebucheintrag mit Beginn, Verlauf und Ergebnis.')
    rubric=loc('정해진 시점에서 시작해 도중 사건과 결과를 순서대로 썼나요? 끝내지 못한 활동을 완성했다고 하지 않았나요? 재미있었다는 느낌은 객관적 사실과 구별했나요? 시간 표현과 주체를 확인하고 다시 써 보세요. 의미는 미채점입니다.', 'Does the diary keep the starting time, intervening event and outcome in order? Does an unfinished activity stay unfinished? Is enjoyment presented as a personal reaction? Check time references and participants, then rewrite. Meaning is unscored.', 'Bleiben Beginn, Zwischenereignis und Ergebnis in der richtigen Reihenfolge? Bleibt die Tätigkeit unvollendet? Wird Freude als persönlicher Eindruck dargestellt? Prüfe Zeitbezüge und Beteiligte und schreibe erneut. Der Inhalt bleibt unbewertet.')
    return [task('KP06','writing:03','writing',loc('미완료 경험을 이야기로 쓰기', 'Narrate an unfinished first experience', 'Von einer unvollendeten ersten Erfahrung erzählen'),
        loc('가상 경험으로 전체 일기를 쓰고 루브릭에 따라 재작성해요. 자동 점수는 부여하지 않아요.', 'Write a complete diary about the fictional experience and revise against the rubric. No automatic score is given.', 'Schreibe einen vollständigen Tagebucheintrag über die fiktive Erfahrung und überarbeite ihn anhand der Kriterien. Es gibt keine automatische Punktzahl.'),
        packet('6월 3일 두 시에 처음 빵 만들기 시작. 삼십 분 뒤 정전. 활동은 재미있었지만 빵은 완성하지 못함. 일기는 그날 저녁에 씀.',[free_text('diary',prompt,rubric)],'form'),
        packet('7월 8일 세 시에 처음 화분 만들기 시작. 한 시간 뒤 수업 종료. 활동은 재미있었지만 화분은 완성하지 못함. 일기는 그날 저녁에 씀.',[free_text('diary',prompt,rubric)],'form'))]


def kp07():
    def endings(preference,promise,unavoidable):
        return packet(f'가: 저는 {preference}.\n나: 알겠어요. 제가 {promise}.\n가: 다른 방법이 없어서 {unavoidable}.',[
            choice('preference',loc('가의 첫 발화는?', 'What is the first speaker’s opening function?', 'Welche Funktion hat der erste Beitrag?'),['개인 의향','상대를 위한 확정 약속'],loc('-을래요는 여기서 개인 의향이에요.', 'Here, -을래요 states a personal preference.', 'Hier nennt -을래요 einen persönlichen Wunsch.')),
            choice('promise',loc('나의 발화는?', 'What does the second speaker do?', 'Was tut die zweite Person sprachlich?'),['자기가 하겠다고 약속함','상대에게 대신 하라고 명령함'],loc('-을게요의 약속 주체는 말하는 사람이에요.', 'The speaker commits themself with -을게요.', 'Mit -을게요 verpflichtet sich die sprechende Person selbst.')),
            choice('necessity',loc('마지막 행동을 고른 이유는?', 'Why is the final action chosen?', 'Warum wird die letzte Handlung gewählt?'),['주어진 상황에서 다른 선택이 없음','항상 가장 좋아하는 활동이기 때문'],loc('수밖에 없다는 제약 속 불가피함이에요.', '수밖에 없다 expresses lack of alternatives under the constraint.', '수밖에 없다 drückt unter der Einschränkung fehlende Alternativen aus.')),
        ],'audio')
    return [task('KP07','listening:03','listening',loc('의향·약속·불가피함의 말끝', 'Endings for preference, promise and necessity', 'Endungen für Wunsch, Zusage und Notwendigkeit'),
        loc('세 가지 말끝이 같은 미래를 뜻하지 않아요. 녹음의 기능을 구별하세요.', 'The three endings do not express the same future meaning. Distinguish their functions.', 'Die drei Endungen haben nicht dieselbe Zukunftsbedeutung. Unterscheide ihre Funktionen.'),
        endings('토요일에 갈래요','시간을 확인할게요','오늘은 기다릴 수밖에 없어요'),endings('기차를 탈래요','표를 알아볼게요','지금은 버스를 탈 수밖에 없어요'))]


def kp08():
    def states(state,progress):
        return packet(f'첫 번째: {state}.\n두 번째: {progress}.',[
            choice('state',loc('첫 번째는 어떤 상황인가요?', 'What does the first sentence describe?', 'Was beschreibt der erste Satz?'),['행동 뒤 상태가 유지됨','그 행동이 지금 진행 중임'],loc('-아/어 있어요는 여기서 결과 상태예요.', '-아/어 있어요 marks the resulting state here.', '-아/어 있어요 bezeichnet hier den Ergebniszustand.')),
            choice('progress',loc('두 번째는 어떤 상황인가요?', 'What does the second sentence describe?', 'Was beschreibt der zweite Satz?'),['행동이 지금 진행 중임','행동이 이미 끝난 상태만 설명함'],loc('-고 있어요는 여기서 진행 동작이에요.', '-고 있어요 marks the action in progress here.', '-고 있어요 bezeichnet hier die laufende Handlung.')),
        ],'audio')
    return [task('KP08','listening:03','listening',loc('남은 상태와 진행 동작 듣기', 'Hear resulting states and ongoing actions', 'Ergebniszustände und laufende Handlungen hören'),
        loc('연결되어 들리는 있어요 앞부분을 주의해서 들으세요. 열려와 열고의 기능을 구별해요.', 'Listen carefully to the sounds before 있어요. Distinguish 열려 from 열고 by function.', 'Höre genau auf den Teil vor 있어요. Unterscheide 열려 und 열고 nach ihrer Funktion.'),
        states('문이 열려 있어요','직원이 문을 열고 있어요'),states('모두 의자에 앉아 있어요','직원이 의자를 옮기고 있어요'))]
