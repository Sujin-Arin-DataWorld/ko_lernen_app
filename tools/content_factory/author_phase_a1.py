"""Authored A1 extensions; publication requires the separate review ledger."""
from phase_task_authoring import choice, grammar_task, loc, packet, sentence, task, write_source


def kp02():
    rows = [
        ('G1:에', loc('에로 시각이나 목적지를 표시해요. 행동이 일어나는 곳은 에서로 나타내요.', '에 marks a time or destination; 에서 marks where an activity happens.', '에 bezeichnet eine Zeit oder ein Ziel; 에서 den Ort einer Tätigkeit.'), ('두 시에 학교에 가요.', '가는 시각은 두 시예요.', '가는 시각은 학교예요.'), ('네 시에 도서관에 가요.', '도서관이 목적지예요.', '네 시가 목적지예요.')),
        ('G1:에서', loc('에서 앞의 장소에서 행동이 일어나요. 도착할 목적지만 나타내는 에와 구별해요.', '에서 locates an activity, rather than only naming its destination.', '에서 zeigt, wo eine Tätigkeit stattfindet, nicht nur ihr Ziel.'), ('집에서 한국어를 공부해요.', '공부하는 곳은 집이에요.', '학교에서 공부해요.'), ('교실에서 친구를 만나요.', '만나는 곳은 교실이에요.', '친구 집에서 만나요.')),
        ('G1:부터', loc('부터는 시작점이에요. 끝점은 까지로 나타내요.', '부터 marks the start; 까지 marks the end.', '부터 bezeichnet den Anfang, 까지 das Ende.'), ('수업은 열 시부터 열두 시까지예요.', '수업은 열 시에 시작해요.', '수업은 열두 시에 시작해요.'), ('도서관은 두 시부터 여섯 시까지 열어요.', '두 시에 문을 열어요.', '여섯 시에 문을 열어요.')),
        ('G1:까지', loc('까지는 끝점이에요. 시작 시각과 끝 시각을 바꾸지 않아요.', '까지 marks an endpoint. Keep the starting and ending times separate.', '까지 bezeichnet den Endpunkt. Verwechsle Anfang und Ende nicht.'), ('오전 아홉 시부터 오후 한 시까지 일해요.', '일이 끝나는 시각은 오후 한 시예요.', '일이 끝나는 시각은 오전 아홉 시예요.'), ('버스는 역에서 학교까지 가요.', '학교가 이 노선의 끝이에요.', '역이 이 노선의 끝이에요.')),
        ('G1:으로', loc('이동 수단에는 (으)로를 붙여요. 버스로, 지하철로처럼 써요. 목적지는 에로 나타내요.', 'Use (으)로 for transport and 에 for a destination.', 'Mit (으)로 nennst du das Verkehrsmittel, mit 에 das Ziel.'), ('학교에 버스로 가요.', '이동 수단은 버스예요.', '이동 수단은 학교예요.'), ('도서관에 지하철로 가요.', '지하철을 타요.', '도서관이라는 버스를 타요.')),
        ('G1:-었-', loc('-았/었-은 과거를 나타내요. 어제 한 일을 지금 하는 일과 구별해요.', '-았/었- marks the past. Distinguish yesterday’s action from an action in progress now.', '-았/었- bezeichnet Vergangenes. Unterscheide eine gestrige Handlung von dem, was gerade geschieht.'), ('어제 친구를 만났어요.', '만난 일은 어제예요.', '친구를 내일 만날 거예요.'), ('지난 토요일에 학교에 갔어요.', '학교에 간 일은 이미 끝났어요.', '지금 학교에 가고 있어요.')),
        ('G1:-고3', loc('-고로 두 행동을 연결해요. 여기서는 말한 순서대로 일어난 행동이에요.', '-고 connects actions. In these examples, the actions happened in the order given.', '-고 verbindet Handlungen. In diesen Beispielen fanden sie in der genannten Reihenfolge statt.'), ('아침을 먹고 학교에 갔어요.', '아침을 먹었고 학교에도 갔어요.', '학교에 가지 않았어요.'), ('책을 읽고 메모를 썼어요.', '책을 읽었고 메모도 썼어요.', '메모만 쓰고 책은 읽지 않았어요.')),
        ('G1:-지 않다', loc('-지 않다는 행동이나 상태를 부정해요. 부정만으로 할 능력이 없다는 뜻이 되지는 않아요.', '-지 않다 negates an action or state; negation alone does not establish inability.', '-지 않다 verneint eine Handlung oder einen Zustand. Daraus folgt allein noch kein Unvermögen.'), ('갈 수 있지만 오늘은 학교에 가지 않아요.', '갈 수 있어도 오늘은 안 가요.', '갈 수 없어서 못 가요.'), ('마실 수 있지만 지금은 커피를 마시지 않아요.', '지금 커피를 안 마셔요.', '커피를 마실 능력이 없어요.')),
        ('G1:-지 못하다', loc('-지 못하다는 능력이나 사정 때문에 할 수 없음을 나타내요. 자발적으로 안 하는 것과 구별해요.', '-지 못하다 expresses inability or a preventing circumstance, rather than a free choice not to act.', '-지 못하다 drückt Unvermögen oder einen hindernden Umstand aus, nicht bloß eine freiwillige Entscheidung.'), ('버스가 없어서 학교에 가지 못했어요.', '버스가 없어서 갈 수 없었어요.', '갈 수 있었지만 그냥 안 갔어요.'), ('아파서 어제 일하지 못했어요.', '몸 상태 때문에 일할 수 없었어요.', '건강했지만 쉬기로 했어요.')),
        ('G1:도', loc('도는 앞서 말한 대상에 같은 정보를 더해요. 저도는 다른 사람과 나에게 모두 해당한다는 뜻이에요.', '도 adds someone or something that shares the preceding property.', '도 fügt jemanden oder etwas hinzu, auf den dieselbe Aussage zutrifft.'), ('유나는 학생이에요. 저도 학생이에요.', '유나와 저는 둘 다 학생이에요.', '저만 학생이에요.'), ('민수는 버스로 가요. 지수도 버스로 가요.', '두 사람 모두 버스를 타요.', '지수만 버스를 타요.')),
        ('G1:만', loc('만은 범위를 제한해요. 물만은 다른 음료를 포함하지 않아요.', '만 limits the scope: 물만 excludes other drinks.', '만 begrenzt den Umfang: 물만 schließt andere Getränke aus.'), ('오늘은 물만 마셨어요.', '오늘 마신 음료는 물뿐이에요.', '물과 주스를 마셨어요.'), ('오늘은 한국어만 공부해요.', '오늘 공부하는 언어는 한국어뿐이에요.', '한국어와 영어를 공부해요.')),
    ]
    tasks = [grammar_task('KP02', i, *row) for i, row in enumerate(rows, 1)]
    def time_questions(start, end, place, transport, class_start, class_end):
        return [
            choice('start', loc('출발 시각은 언제예요?', 'When do they depart?', 'Wann fahren sie ab?'), start, loc(f'출발 시각은 {start[0]}입니다. 끝나는 시각과 구별해요.', f'The stated departure time is {start[0]}.', f'Die genannte Abfahrtszeit ist {start[0]}.')),
            choice('end', loc('학교에 언제 도착해요?', 'When do they arrive at school?', 'Wann kommen sie an der Schule an?'), end, loc(f'학교 도착 시각은 {end[0]}입니다.', f'They arrive at school at {end[0]}.', f'Sie kommen um {end[0]} an der Schule an.')),
            choice('place', loc('어디에서 출발해요?', 'Where do they depart from?', 'Wo fahren sie ab?'), place, loc(f'{place[0]}에서 출발해요. 학교는 목적지예요.', f'They depart from {place[0]}; school is the destination.', f'Sie fahren bei {place[0]} ab; die Schule ist das Ziel.')),
            choice('transport', loc('무엇을 타요?', 'Which transport do they take?', 'Welches Verkehrsmittel nehmen sie?'), transport, loc(f'{transport[0]}로 이동해요.', f'They travel by {transport[0]}.', f'Sie fahren mit {transport[0]}.')),
            choice('class_start', loc('수업은 언제 시작해요?', 'When does class start?', 'Wann beginnt der Unterricht?'), [class_start,class_end], loc(f'{class_start}부터이므로 그때 시작해요.', f'{class_start}부터 marks the start.', f'{class_start}부터 bezeichnet den Beginn.')),
            choice('class_end', loc('수업은 언제 끝나요?', 'When does class end?', 'Wann endet der Unterricht?'), [class_end,class_start], loc(f'{class_end}까지이므로 그때 끝나요.', f'{class_end}까지 marks the end.', f'{class_end}까지 bezeichnet das Ende.')),
        ]
    tasks.append(task('KP02', 'listening:01', 'listening', loc('출발과 도착 안내 듣기', 'Listen for departure and arrival', 'Abfahrt und Ankunft verstehen'),
        loc('출발·도착·수업 시작·수업 종료 시각을 구별하세요. 출발 장소와 교통수단까지 여섯 정보가 모두 맞아야 통과해요.', 'Distinguish departure, arrival, class start and class end. All six facts, including starting place and transport, are required.', 'Unterscheide Abfahrt, Ankunft, Unterrichtsbeginn und Unterrichtsende. Alle sechs Angaben einschließlich Startort und Verkehrsmittel müssen stimmen.'),
        packet('안녕하세요. 내일 아홉 시에 역에서 출발해요. 버스로 학교에 가요. 아홉 시 반에 학교에 도착해요. 수업은 열 시부터 열두 시까지예요.', time_questions(['아홉 시','열 시','열두 시'], ['아홉 시 반','열두 시','열 시'], ['역','학교','도서관'], ['버스','지하철','택시'],'열 시','열두 시'), 'audio'),
        packet('안녕하세요. 토요일 두 시에 도서관에서 출발해요. 지하철로 학교에 가요. 두 시 반에 학교에 도착해요. 수업은 세 시부터 다섯 시까지예요.', time_questions(['두 시','세 시','다섯 시'], ['두 시 반','세 시','다섯 시'], ['도서관','학교','역'], ['지하철','버스','택시'],'세 시','다섯 시'), 'audio')))
    def timetable(opening, closing, cls_start, cls_end, visit, wrong, room):
        text=f'도서관: {opening}–{closing}\n한국어 수업: {cls_start}–{cls_end}, {room}호\n학교와 도서관 사이: 걸어서 5분'
        qs=[choice('visit', loc('수업과 겹치지 않고 도서관이 열린 시각은?', 'Which visit fits class and library opening times?', 'Welcher Bibliotheksbesuch passt zum Unterricht und zu den Öffnungszeiten?'), [visit,wrong], loc(f'{visit}에는 도서관이 열려 있고 수업이 없어요.', f'At {visit}, the library is open and class is not in session.', f'Um {visit} ist die Bibliothek geöffnet und es findet kein Unterricht statt.')),
            choice('classroom', loc('수업은 어디에서 해요?', 'Where is the class?', 'Wo findet der Unterricht statt?'), [f'{room}호','도서관'], loc(f'수업 장소는 {room}호예요.', f'Class is in room {room}.', f'Der Unterricht findet in Raum {room} statt.')),
            choice('end', loc('수업은 언제 끝나요?', 'When does class end?', 'Wann endet der Unterricht?'), [cls_end,cls_start], loc(f'수업은 {cls_end}에 끝나요.', f'Class ends at {cls_end}.', f'Der Unterricht endet um {cls_end}.'))]
        return packet(text,qs,'sign')
    tasks.append(task('KP02','reading:01','reading',loc('시간표로 방문 시간 정하기','Plan a visit from a timetable','Mit dem Stundenplan einen Besuch planen'),
        loc('수업 시각과 도서관 운영 시간을 함께 읽어요. 표에 없는 시각은 만들지 않아요.', 'Use both class times and library hours. Do not invent missing times.', 'Lies Unterrichtszeiten und Öffnungszeiten zusammen. Ergänze keine nicht angegebenen Zeiten.'),
        timetable('09:00','18:00','10:00','12:00','14:00','11:00','201'), timetable('13:00','19:00','15:00','17:00','14:00','16:00','302')))
    def message(place, arrival, act, other):
        return packet(f'가상 상황\n지금 위치: {place}\n학교 도착 예정: {arrival}\n지금 하는 일: {act}\n상대: 같은 반 친구', [
            sentence('location',loc('지금 어디에 있는지 한 문장으로 쓰세요.','Write one sentence giving your current location.','Schreibe einen Satz über deinen aktuellen Aufenthaltsort.'),[f'저는 지금 {place}에 있어요.',f'지금 {place}에 있어요.',f'{place}에 있어요.'],[f'{place}에서 있어요.',f'학교에 있어요.'],loc(f'현재 위치는 {place}에 있어요로 나타내요.',f'Use {place}에 있어요 for the current location.',f'Den Aufenthaltsort gibst du mit {place}에 있어요 an.')),
            sentence('arrival',loc('도착 시각을 한 문장으로 알리세요.','Give your arrival time in one sentence.','Nenne deine Ankunftszeit in einem Satz.'),[f'{arrival}에 학교에 도착해요.',f'학교에 {arrival}에 도착해요.'],[f'{other}에 학교에 도착해요.'],loc(f'예정된 도착 시각은 {arrival}예요.',f'The stated arrival time is {arrival}.',f'Die angegebene Ankunftszeit ist {arrival}.')),
        ],'form')
    tasks.append(task('KP02','writing:01','writing',loc('위치와 도착 시각 문자','Send location and arrival time','Standort und Ankunft mitteilen'),
        loc('가상 인물의 정보로 두 문장을 쓰세요. 위치에는 에 있어요, 도착 시각에는 에 도착해요를 써 보세요. 다른 자연스러운 문장은 자동 채점 범위 밖일 수 있어요.', 'Write two sentences using the fictional facts. Try 에 있어요 for location and 에 도착해요 for arrival. Other natural wording may remain unscored.', 'Schreibe zwei Sätze mit den fiktiven Angaben. Verwende etwa 에 있어요 für den Standort und 에 도착해요 für die Ankunft. Andere natürliche Formulierungen können unbewertet bleiben.'),
        message('역','세 시','버스 기다리기','네 시'),message('도서관','다섯 시','책 반납하기','여섯 시')))
    tasks.append(task('KP02','speaking:01','speaking',loc('어제 한 일과 길 설명','Explain yesterday and a route','Über gestern sprechen und den Weg erklären'),
        loc('가상 정보를 보고 어제 한 일과 못 한 일, 오늘 갈 길을 녹음하세요. 과거·부정, 출발지·목적지·수단을 확인하고 다시 녹음해 보세요. 발화 의미는 자동 채점하지 않아요.', 'Record the fictional past actions and today’s route. Review past/negative forms, start, destination and transport, then re-record. Speech meaning is not automatically scored.', 'Sprich anhand der fiktiven Angaben über gestern und den heutigen Weg. Prüfe Vergangenheit, Verneinung, Start, Ziel und Verkehrsmittel und nimm dich erneut auf. Die Aussage wird nicht automatisch bewertet.'),
        packet('어제: 도서관에서 공부했어요. 비가 와서 운동하지 못했어요.\n오늘: 집 → 버스 → 학교.\n친구에게 세 가지 정보를 말해 보세요.',[]),
        packet('어제: 집에서 책을 읽었어요. 아파서 학교에 가지 못했어요.\n오늘: 도서관 → 지하철 → 학교.\n친구에게 세 가지 정보를 말해 보세요.',[])))
    return tasks


def kp03():
    rows = [
        ('G1:에게',loc('에게는 주거나 보내는 행동의 받는 사람을 표시해요. 이동하는 장소와 구별해요.','에게 marks the person receiving something, not a destination place.','에게 bezeichnet die Person, die etwas erhält, nicht einen Zielort.'),('민수가 유나에게 책을 줘요.','책을 받는 사람은 유나예요.','책을 받는 사람은 민수예요.'),('지수가 선생님에게 메모를 보내요.','메모를 받는 사람은 선생님이에요.','메모를 받는 사람은 지수예요.')),
        ('G1:한테',loc('한테는 대화에서 받는 사람을 나타내요. 그 사람이 반드시 행동의 주체는 아니에요.','In conversation, 한테 marks the recipient, not necessarily the person doing the action.','한테 bezeichnet im Gespräch den Empfänger, nicht unbedingt die handelnde Person.'),('유나가 친구한테 전화해요.','전화하는 사람은 유나예요.','전화하는 사람은 친구예요.'),('민수가 지수한테 사진을 보내요.','사진을 받는 사람은 지수예요.','사진을 받는 사람은 민수예요.')),
        ('G1:-으러',loc('-(으)러 가다/오다는 이동 목적을 나타내요. 목적을 말해도 그 일이 이미 끝났다는 뜻은 아니에요.','-(으)러 가다/오다 gives the purpose of movement, not proof that the intended action is complete.','-(으)러 가다/오다 nennt den Zweck einer Bewegung. Die beabsichtigte Handlung ist damit noch nicht abgeschlossen.'),('책을 사러 서점에 가요.','가는 목적은 책을 사는 거예요.','책을 이미 다 샀어요.'),('친구를 만나러 역에 가요.','역에 가는 목적은 친구를 만나는 거예요.','친구를 이미 만나고 집에 왔어요.')),
        ('G1:-으려고1',loc('-(으)려고는 의도나 목적을 나타내요. 계획이 실제로 이루어졌는지는 따로 확인해요.','-(으)려고 expresses intention or purpose. Whether it happened is a separate question.','-(으)려고 drückt eine Absicht oder einen Zweck aus. Ob die Handlung stattfand, bleibt eine eigene Frage.'),('한국어를 배우려고 수업에 가요.','수업에 가는 목적은 한국어 배우기예요.','한국어를 모두 배웠어요.'),('일찍 가려고 버스를 기다려요.','일찍 가려는 계획이 있어요.','이미 목적지에 도착했어요.')),
        ('G1:-고 싶다',loc('-고 싶다는 화자의 희망이에요. 살 수 있는지, 실제 주문했는지는 희망과 별개예요.','-고 싶다 expresses a wish, separately from availability or a completed order.','-고 싶다 drückt einen Wunsch aus. Verfügbarkeit und eine erfolgte Bestellung sind davon getrennt.'),('저는 주스를 마시고 싶어요. 주스는 없어요.','희망은 주스지만 지금 주문할 수 없어요.','주스를 이미 받았어요.'),('책을 사고 싶어요. 하지만 돈이 없어요.','책을 원하지만 살 돈은 없어요.','책을 이미 샀어요.')),
        ('G1:-고 있다',loc('-고 있다는 여기서 지금 진행 중인 행동을 나타내요. 완료된 과거와 구별해요.','Here -고 있다 marks an ongoing action, rather than a completed past action.','Hier bezeichnet -고 있다 eine laufende Handlung und keine abgeschlossene Vergangenheit.'),('지금 밥을 먹고 있어요.','밥을 먹는 중이에요.','밥을 아직 먹기 시작하지 않았어요.'),('지금 주문을 기다리고 있어요.','기다리는 중이에요.','주문을 받고 가게를 떠났어요.')),
        ('G1:-을 수 있다',loc('-(으)ㄹ 수 있다는 가능이나 능력이에요. 원한다는 뜻이나 이미 했다는 뜻은 아니에요.','-(으)ㄹ 수 있다 marks possibility or ability, not necessarily a wish or completed action.','-(으)ㄹ 수 있다 bezeichnet Möglichkeit oder Fähigkeit, nicht automatisch einen Wunsch oder eine abgeschlossene Handlung.'),('여기에서 카드로 계산할 수 있어요.','카드 결제가 가능해요.','카드로 이미 계산했어요.'),('유나는 한국어 메뉴를 읽을 수 있어요.','유나는 메뉴를 읽는 능력이 있어요.','유나가 지금 주문을 끝냈어요.')),
        ('G1:-겠-',loc('제가 하겠습니다처럼 쓰면 화자가 하겠다는 의지를 약속해요. 여기서는 추측이 아니에요.','With 제가 하겠습니다, the speaker commits to acting. This use is not a guess.','Mit 제가 하겠습니다 verpflichtet sich die sprechende Person zu einer Handlung. Hier geht es nicht um eine Vermutung.'),('제가 내일 전화하겠습니다.','화자가 내일 전화하겠다고 약속해요.','상대에게 전화하라고 명령해요.'),('제가 주문을 확인하겠습니다.','화자가 확인할 의지를 말해요.','확인이 이미 끝났다고 말해요.')),
        ('G1:-으세요',loc('-(으)세요는 여기서 상대에게 행동을 부탁하는 공손한 말끝이에요. 누가 행동해야 하는지 확인해요.','Here -(으)세요 is a polite request for the listener to act. Identify who is asked to act.','Hier ist -(으)세요 eine höfliche Aufforderung an die zuhörende Person. Achte darauf, wer handeln soll.'),('직원: 여기에 이름을 쓰세요.','손님에게 이름을 써 달라고 해요.','직원이 자기 이름을 쓰겠다고 해요.'),('친구: 여기에서 잠시 기다리세요.','상대에게 기다려 달라고 해요.','화자가 이미 기다렸다고 말해요.')),
        ('G1:-으십시오',loc('-(으)십시오는 격식 있는 안내나 요청이에요. 여기서는 직원이 손님에게 행동을 요청해요.','-(으)십시오 is a formal instruction or request. Here staff address customers.','-(으)십시오 ist eine formelle Aufforderung. Hier richtet das Personal sie an die Kundschaft.'),('안내: 문 앞에서 기다리십시오.','문 앞에서 기다려 달라는 안내예요.','기다린 일이 끝났다는 보고예요.'),('안내: 계산대에서 주문하십시오.','손님이 계산대에서 주문하라는 안내예요.','직원이 손님 대신 주문했다는 보고예요.')),
        ('G1:-을까',loc('같이 -(으)ㄹ까요?는 상대의 의향을 묻는 제안이에요. 대답 전에는 약속이 확정되지 않아요.','같이 -(으)ㄹ까요? asks about a shared plan. It is not confirmed before the reply.','같이 -(으)ㄹ까요? fragt nach einem gemeinsamen Vorhaben. Vor der Antwort ist noch nichts vereinbart.'),('토요일에 같이 영화를 볼까요?','함께 보자고 제안하고 있어요.','토요일 약속이 이미 확정됐어요.'),('내일 공원에서 만날까요?','만날 의향을 묻고 있어요.','내일 꼭 오라고 명령하고 있어요.')),
        ('G1:-읍시다',loc('-(으)ㅂ시다는 화자도 참여하는 함께 하자는 제안이에요. 처음 만난 윗사람에게 쓰면 부담스러울 수 있어요.','-(으)ㅂ시다 proposes an action including the speaker. It may sound too directive toward an unfamiliar senior.','-(으)ㅂ시다 schlägt eine gemeinsame Handlung einschließlich der sprechenden Person vor. Gegenüber unbekannten höhergestellten Personen kann es zu bestimmend wirken.'),('같은 반 동료: 내일 같이 공부합시다.','화자와 동료가 함께 공부하자는 말이에요.','동료만 공부하라는 말이에요.'),('동료끼리: 여기에서 같이 기다립시다.','화자도 함께 기다리자는 말이에요.','상대 혼자 기다리라는 말이에요.')),
    ]
    tasks=[grammar_task('KP03',i,*row) for i,row in enumerate(rows,1)]
    def order(want,available,count):
        other='차' if available=='물' else '물'
        text=f'손님: {want} 두 잔을 마시고 싶어요.\n직원: 죄송해요. 오늘은 {want}가 없어요. {available}도 있어요.\n손님: 그러면 {available} {count} 잔 주세요.\n직원: 네, {available} {count} 잔 맞아요.'
        return packet(text,[
            choice('wish',loc('처음에 무엇을 원했어요?','What did the customer first want?','Was wollte die Person zuerst?'),[want,available],loc(f'처음 희망은 {want}예요. 실제 주문과 구별해요.',f'The original wish was {want}; distinguish it from the final order.',f'Der ursprüngliche Wunsch war {want}; unterscheide ihn von der endgültigen Bestellung.')),
            choice('order',loc('마지막 주문은 무엇이에요?','What is the final order?','Was wird am Ende bestellt?'),[f'{available} {count} 잔',f'{want} 두 잔',f'{other} 두 잔'],loc(f'마지막 확인은 {available} {count} 잔이에요.',f'The final confirmation is {available} {count} 잔.',f'Zuletzt wird {available} {count} 잔 bestätigt.')),
            choice('available',loc('오늘 없는 음료는?','Which drink is unavailable today?','Welches Getränk gibt es heute nicht?'),[want,available],loc(f'직원이 오늘 {want}가 없다고 말해요.',f'Staff say {want} is unavailable today.',f'Das Personal sagt, dass es heute kein {want} gibt.')),
        ],'audio')
    tasks.append(task('KP03','listening:01','listening',loc('원하는 것과 주문한 것','Wish versus final order','Wunsch und Bestellung unterscheiden'),
        loc('손님과 직원의 대화를 듣고 희망, 재고, 마지막 주문을 따로 확인하세요.', 'Listen to the customer and staff. Separate the wish, availability and final order.', 'Höre das Gespräch zwischen Kundschaft und Personal. Trenne Wunsch, Verfügbarkeit und endgültige Bestellung.'), order('주스','물','한'),order('우유','차','세')))
    def menu(food,price,drink,drinkprice,budget,count):
        total=price*count+drinkprice
        return packet(f'메뉴\n{food}: {price:,}원\n{drink}: {drinkprice:,}원\n주문 계획: {food} {count}개, {drink} 1잔\n예산: {budget:,}원',[
            choice('quantity',loc('음식은 몇 개 주문해요?','How many food items are planned?','Wie viele Speisen sind geplant?'),[str(count),str(count+1)],loc(f'주문 수량은 {food} {count}개예요.',f'The plan contains {count} portions of {food}.',f'Geplant sind {count} Portionen {food}.')),
            choice('total',loc('모두 얼마예요?','What is the total price?','Wie hoch ist der Gesamtpreis?'),[f'{total:,}원',f'{price+drinkprice:,}원' if count!=1 else f'{total+1000:,}원'],loc(f'{price:,} × {count} + {drinkprice:,} = {total:,}원이에요.',f'{price:,} × {count} + {drinkprice:,} = {total:,} won.',f'{price:,} × {count} + {drinkprice:,} = {total:,} Won.')),
            choice('budget',loc('예산 안에서 살 수 있어요?','Is the order within budget?','Liegt die Bestellung im Budget?'),['네' if total<=budget else '아니요','아니요' if total<=budget else '네'],loc(f'합계 {total:,}원과 예산 {budget:,}원을 비교해요.',f'Compare the total of {total:,} won with the {budget:,}-won budget.',f'Vergleiche insgesamt {total:,} Won mit dem Budget von {budget:,} Won.')),
        ],'sign')
    tasks.append(task('KP03','reading:01','reading',loc('메뉴와 예산 확인','Read a menu and check a budget','Menü und Budget prüfen'),
        loc('품목, 수량, 단가를 읽고 합계를 구하세요. 예산을 넘는 주문은 가능한 것으로 답하지 않아요.', 'Read items, quantities and unit prices. An order over budget is not affordable within that budget.', 'Lies Speisen, Mengen und Einzelpreise. Eine Bestellung über dem Budget passt nicht in dieses Budget.'), menu('김밥',3000,'물',1000,8000,2),menu('만두',4000,'차',2000,9000,2)))
    def proposal(day,time,place,activity,wrong):
        full=f'{day} {time}에 {place}에서 같이 {activity}할까요?'
        return packet(f'상대: 같은 반 동료\n아직 답장을 받지 않았어요.\n제안: {day}, {time}, {place}, {activity}하기',[
            sentence('proposal',loc('상대가 답할 수 있게 만남을 제안하세요.','Suggest the meeting and leave room for a reply.','Schlage das Treffen vor und lass Raum für eine Antwort.'),[full,f'{day} {time}에 {place}에서 {activity}할까요?'],[f'{day} {time}에 {place}에서 꼭 {activity}하세요.',wrong],loc(f'예: {full} 답장을 받기 전에는 확정된 약속이 아니에요.',f'For example: {full} The meeting is not confirmed before a reply.',f'Zum Beispiel: {full} Ohne Antwort ist das Treffen noch nicht vereinbart.')),
        ],'form')
    tasks.append(task('KP03','writing:01','writing',loc('확정하지 않고 제안하기','Suggest without claiming agreement','Vorschlagen, ohne eine Zusage zu behaupten'),
        loc('시간·장소·활동을 담고 -(으)ㄹ까요?로 물어보세요. 자료에 없는 동의나 의무를 만들지 않아요.', 'Include time, place and activity, using -(으)ㄹ까요? Do not invent agreement or an obligation.', 'Nenne Zeit, Ort und Aktivität und frage mit -(으)ㄹ까요? Erfinde weder eine Zusage noch eine Verpflichtung.'),
        proposal('토요일','두 시','공원','산책','만나기로 했어요.'),proposal('일요일','세 시','도서관','공부','약속이 확정됐어요.')))
    tasks.append(task('KP03','speaking:01','speaking',loc('가게에서 부탁하고 동료에게 제안하기','Request and propose','Bitten und Vorschlagen'),
        loc('두 장면을 나누어 말하세요. 직원에게는 물건을 부탁하고, 동료에게는 함께 할 활동을 물어요. 해요체와 상대의 응답 기회를 확인하고 다시 녹음하세요. 의미는 자동 채점하지 않아요.', 'Record the two scenes separately: request an item from staff, then ask a classmate about a shared activity. Review polite endings and room for a response. Meaning remains unscored.', 'Trenne die beiden Situationen: Bitte das Personal um etwas und frage dann ein Kursmitglied nach einer gemeinsamen Aktivität. Prüfe höfliche Endungen und Raum für eine Antwort. Der Inhalt bleibt unbewertet.'),
        packet('가게: 물 한 병을 부탁하세요.\n동료: 토요일 두 시에 공원에서 산책하자고 물어보세요. 아직 동의하지 않았어요.',[]),
        packet('가게: 차 두 잔을 부탁하세요.\n동료: 일요일 세 시에 도서관에서 공부하자고 물어보세요. 아직 동의하지 않았어요.',[])))
    return tasks


def kp04():
    rows=[
        ('G1:-으시-',loc('-시-는 문장의 주체를 높여요. 듣는 사람에게 공손한 -요와 역할이 달라요.','-시- honors the subject; -요 is politeness toward the listener.','-시- ehrt das Subjekt; -요 richtet Höflichkeit an die zuhörende Person.'),('선생님이 오세요.','오는 선생님을 높여 말해요.','듣는 사람만 높이고 선생님은 높이지 않아요.'),('할머니가 쉬세요.','쉬는 할머니를 높여 말해요.','화자가 자기를 높여 말해요.')),
        ('G1:께서',loc('께서는 높이는 사람이 주어임을 나타내요. 행동을 받는 사람을 나타내는 께와 구별해요.','께서 marks an honored subject; distinguish recipient 께.','께서 bezeichnet ein geehrtes Subjekt; 께 dagegen einen Empfänger.'),('선생님께서 오세요.','오는 사람은 선생님이에요.','누군가 선생님께 물건을 줘요.'),('할아버지께서 책을 읽으세요.','책을 읽는 사람은 할아버지예요.','할아버지가 책을 받는다는 뜻이에요.')),
        ('G1:-어서',loc('여기서 -아/어서 앞은 뒤 상황의 이유예요. 원인과 결과를 바꾸지 않아요.','Here the clause before -아/어서 gives the reason for the following situation.','Hier nennt der Satzteil vor -아/어서 den Grund für die folgende Situation.'),('비가 와서 집에 있어요.','비가 오는 것이 집에 있는 이유예요.','집에 있어서 비가 와요.'),('머리가 아파서 쉬어요.','머리가 아픈 것이 쉬는 이유예요.','쉬어서 머리가 아파요.')),
        ('G1:-으니까',loc('-(으)니까로 이유를 말한 뒤 요청이나 제안을 할 수 있어요. 요청의 부담은 관계와 내용도 보고 판단해요.','-(으)니까 can give a reason before a request or suggestion. Its burden also depends on the relationship and content.','Mit -(으)니까 kannst du eine Bitte oder einen Vorschlag begründen. Wie belastend die Bitte ist, hängt auch von Beziehung und Inhalt ab.'),('추우니까 안에 들어가세요.','추운 것이 들어가라는 이유예요.','안에 들어가서 추워졌다는 뜻이에요.'),('비가 오니까 버스를 탈까요?','비 때문에 버스를 타자고 제안해요.','이미 버스를 탔다고 보고해요.')),
        ('G1:-지만',loc('-지만으로 서로 대조되는 정보를 함께 말해요. 앞 정보를 취소하지는 않아요.','-지만 connects contrasting information without cancelling the first statement.','-지만 verbindet gegensätzliche Angaben, ohne die erste Aussage aufzuheben.'),('오늘은 춥지만 날씨가 맑아요.','춥고 맑다는 정보가 모두 맞아요.','맑으니까 춥지 않아요.'),('차는 뜨겁지만 맛있어요.','뜨겁고 맛있는 차예요.','뜨겁다는 말은 취소됐어요.')),
        ('G1:보다',loc('보다 앞은 비교 기준이에요. 어느 쪽이 더 그런지 방향을 확인해요.','The word before 보다 is the comparison standard. Check the direction of the comparison.','Vor 보다 steht der Vergleichsmaßstab. Achte auf die Richtung des Vergleichs.'),('오늘은 어제보다 추워요.','오늘이 더 추워요.','어제가 더 추워요.'),('버스는 택시보다 싸요.','버스 요금이 더 낮아요.','택시 요금이 더 낮아요.')),
        ('G1:-고4',loc('문장 끝의 -고요는 관련 설명을 덧붙여요. 여기서는 새 정보를 앞 정보에 더하는 말이에요.','Sentence-final -고요 adds a related explanation or fact.','Mit -고요 am Satzende ergänzt du eine zusammengehörige Erklärung oder Angabe.'),('이 방은 조용해요. 창문도 크고요.','창문이 크다는 설명을 더해요.','방이 조용하지 않다고 정정해요.'),('가게가 가까워요. 가격도 싸고요.','가격이 싸다는 장점을 더해요.','가격이 싸냐고 질문해요.')),
        ('G1:-기 전에',loc('-기 전에 앞의 행동보다 주절 행동이 먼저예요. 시간 순서가 곧 원인은 아니에요.','With -기 전에, the main action happens before the named action. Order alone is not causation.','Bei -기 전에 geschieht die Haupthandlung vor der genannten Handlung. Reihenfolge allein ist keine Ursache.'),('자기 전에 물을 마셔요.','물을 마신 다음 자요.','잔 다음 물을 마셔요.'),('학교에 가기 전에 아침을 먹어요.','아침을 먹은 다음 학교에 가요.','학교에 간 다음 아침을 먹어요.')),
        ('G1:-은 후에',loc('-(으)ㄴ 후에는 앞 행동이 끝난 다음이에요. 두 사건의 순서를 유지해요.','-(으)ㄴ 후에 means after the preceding action is completed.','-(으)ㄴ 후에 bedeutet nach Abschluss der vorher genannten Handlung.'),('밥을 먹은 후에 약을 먹어요.','밥을 먼저 먹어요.','약을 먼저 먹어요.'),('수업이 끝난 후에 친구를 만나요.','수업이 먼저 끝나요.','친구를 만난 다음 수업이 끝나요.')),
        ('G1:-어야 되다',loc('-아/어야 되다는 여기서 할 필요나 의무예요. 단순한 미래나 이미 한 일을 뜻하지 않아요.','Here -아/어야 되다 expresses a requirement, not simply a future or completed action.','Hier bezeichnet -아/어야 되다 eine Notwendigkeit, nicht bloß Zukunft oder eine abgeschlossene Handlung.'),('내일 아홉 시까지 학교에 가야 돼요.','아홉 시까지 가는 것이 필요해요.','이미 학교에 갔어요.'),('도서관에서는 조용히 해야 돼요.','도서관에서 조용히 할 필요가 있어요.','항상 조용하다고 추측해요.')),
        ('G1:-겠-',loc('춥겠어요처럼 단서를 보고 추측할 수 있어요. 관찰한 사실과 추측을 나누고, 제가 하겠습니다의 의지와 구별해요.','춥겠어요 can infer from a clue. Separate observed facts, guesses and the commitment in 제가 하겠습니다.','춥겠어요 kann eine Vermutung aus einem Hinweis ausdrücken. Trenne Beobachtung, Vermutung und die Absicht in 제가 하겠습니다.'),('바람이 많이 불어요. 밖은 춥겠어요.','바람은 관찰, 추위는 추측이에요.','밖의 온도를 직접 쟀어요.'),('하늘이 어두워요. 비가 오겠어요.','어두운 하늘은 관찰, 비는 추측이에요.','비가 이미 내린다고 확인했어요.')),
    ]
    tasks=[grammar_task('KP04',i,*row) for i,row in enumerate(rows,1)]
    def change(observed,guess,time,wrong):
        return packet(f'유나: {observed} {guess}\n민수: 그러면 밖에서 만나지 말고 도서관에서 만날까요?\n유나: 좋아요. {time}에 만나요.\n민수: 네. 도서관에서 먼저 책을 읽고 카페에 가요.',[
            choice('fact',loc('확인한 정보는 무엇이에요?','Which information is observed?','Welche Information wurde beobachtet?'),[observed,guess],loc(f'직접 말한 관찰은 “{observed}”예요. -겠-은 여기서 추측이에요.',f'“{observed}” is the observation; -겠- marks the inference here.',f'„{observed}“ ist die Beobachtung; -겠- bezeichnet hier die Vermutung.')),
            choice('time',loc('새 약속 시각은?','What is the agreed time?','Welche Uhrzeit wurde vereinbart?'),[time,wrong],loc(f'{time}에 만나자는 말에 동의했어요.',f'They agree to meet at {time}.',f'Sie vereinbaren {time} als Treffzeit.')),
            choice('sequence',loc('어느 순서로 가요?','In which order do they go?','In welcher Reihenfolge gehen sie?'),['도서관 → 카페','카페 → 도서관'],loc('도서관에서 먼저 책을 읽고 카페에 가요.','They read at the library first, then go to the café.','Sie lesen zuerst in der Bibliothek und gehen dann ins Café.')),
        ],'audio')
    tasks.append(task('KP04','listening:01','listening',loc('일정 변경의 이유와 순서','Understand a changed plan','Grund und Reihenfolge einer Planänderung'),
        loc('두 동료의 대화에서 관찰한 정보와 추측을 구별하세요. 합의한 시간과 이동 순서도 확인하세요.', 'Distinguish observation from inference in two classmates’ conversation. Check the agreed time and route order.', 'Unterscheide im Gespräch zweier Kursmitglieder Beobachtung und Vermutung. Prüfe vereinbarte Zeit und Reihenfolge.'),
        change('바람이 많이 불어요.','밖은 춥겠어요.','두 시','세 시'),change('하늘이 어두워요.','비가 오겠어요.','네 시','다섯 시')))
    def lyric(first,second,prior,later,earlier_action,later_action):
        return packet(f'이 과제를 위해 새로 쓴 짧은 노랫말\n{first}\n{second}\n안내 대화\n유나: 언제 {later}?\n민수: {prior} 후에요.',[
            choice('sequence',loc('대화에서 먼저 하는 일은?','What happens first in the dialogue?','Was geschieht im Dialog zuerst?'),[earlier_action,later_action],loc(f'대화에서 “{prior} 후에”라고 했으므로 그 일이 먼저예요.',f'“{prior} 후에” makes that event the earlier one.',f'„{prior} 후에“ kennzeichnet das zuerst stattfindende Ereignis.')),
            choice('meaning',loc('“마음에 봄이 와요”는 무엇을 나타내요?','What does “마음에 봄이 와요” express?','Was drückt „마음에 봄이 와요“ aus?'),['기분이 좋아지는 비유','달력의 계절이 바뀌었다는 확인'],loc('마음의 변화를 봄에 빗댄 표현이에요. 실제 계절이 바뀌었다는 증거는 아니에요.', 'It compares a change of feeling to spring; it does not establish a calendar change.', 'Das Bild des Frühlings beschreibt eine Gefühlsänderung, keinen belegten Wechsel der Jahreszeit.')),
        ])
    tasks.append(task('KP04','reading:01','reading',loc('노랫말과 대화의 전후 관계','Read sequence and figurative language','Reihenfolge und Bildsprache lesen'),
        loc('이 과제의 창작 노랫말과 안내 대화를 읽어요. 시간 순서와 마음을 나타내는 비유를 구별해요.', 'Read the original task lyric and dialogue. Separate event order from figurative feelings.', 'Lies den für diese Aufgabe verfassten Liedtext und Dialog. Trenne zeitliche Reihenfolge von bildhaften Gefühlen.'),
        lyric('친구를 만나기 전에 길은 추워요.','친구를 만난 후에 마음에 봄이 와요.','밥을 먹은','공원에 가요','밥 먹기','공원에 가기'),
        lyric('비가 그치기 전에 우산을 펴요.','네 말을 들은 후에 마음에 봄이 와요.','수업이 끝난','친구를 만나요','수업 끝나기','친구 만나기')))
    def note(reason,old,new,place,other):
        full=f'{reason} {old}에는 만나지 못해요.'
        proposal=f'{new}에 {place}에서 만날까요?'
        return packet(f'가상 상황\n받는 사람: 같은 반 동료\n이유: {reason}\n기존 약속: {old}\n새로 제안할 시각: {new}\n장소: {place}\n아직 동의를 받지 않았어요.',[
            sentence('reason_change',loc('이유와 기존 약속 변경을 쓰세요.','State the reason and change to the old plan.','Nenne Grund und Änderung des bisherigen Plans.'),[full,f'미안해요. {full}'],[f'{reason} {old}에 꼭 오세요.'],loc(f'예: {full} 상대에게 명령할 사유는 주어지지 않았어요.',f'Example: {full} The situation does not authorize an order to the classmate.',f'Beispiel: {full} Die Situation begründet keine Anweisung an das Kursmitglied.')),
            sentence('alternative',loc('대안을 질문으로 제안하세요.','Suggest the alternative as a question.','Schlage die Alternative als Frage vor.'),[proposal,f'그러면 {proposal}'],[f'{other}에 {place}에서 만날까요?',f'{new}에 {place}에서 만나야 돼요.'],loc(f'예: {proposal} 시각을 바꾸거나 의무로 만들지 않아요.',f'Example: {proposal} Keep the time and leave the choice open.',f'Beispiel: {proposal} Behalte die Uhrzeit bei und lass die Entscheidung offen.')),
        ],'form')
    tasks.append(task('KP04','writing:01','writing',loc('이유를 담은 변경 메모','Write a change-of-plan note','Eine Planänderung begründen'),
        loc('이유·변경·대안이 들어간 메모를 두 부분으로 쓰세요. 자유로운 다른 표현은 자동 채점되지 않을 수 있어요.', 'Write the reason, change and alternative in two parts. Other free wording may remain unscored.', 'Schreibe Grund, Änderung und Alternative in zwei Teilen. Andere freie Formulierungen können unbewertet bleiben.'),
        note('머리가 아파서','오늘 두 시','내일 세 시','도서관','내일 네 시'),note('비가 많이 와서','오늘 네 시','내일 두 시','카페','내일 다섯 시')))
    tasks.append(task('KP04','speaking:01','speaking',loc('동료에게 부탁하며 선생님 높이기','Request a change and refer respectfully to a teacher','Um eine Änderung bitten und über die Lehrkraft sprechen'),
        loc('같은 반 동료에게 공손하게 변경을 부탁하고 선생님 도착을 알려 주세요. -시-는 선생님, -요는 듣는 동료에 대한 표현인지 확인하세요. 선생님이 오시니까 / 먼저 준비해요처럼 의미 단위로 쉬어 말한 뒤 다시 녹음하세요. 의미와 억양은 자동 채점하지 않아요.', 'Politely request a change from a classmate and give the teacher’s arrival time. Check subject honorific -시- separately from listener politeness -요. Re-record with pauses that preserve meaning. Meaning and intonation remain unscored.', 'Bitte ein Kursmitglied höflich um eine Änderung und nenne die Ankunftszeit der Lehrkraft. Prüfe -시- für die Lehrkraft getrennt von -요 für die zuhörende Person. Nimm mit sinnvollen Pausen erneut auf. Inhalt und Intonation bleiben unbewertet.'),
        packet('동료에게 말해요.\n기존 약속: 두 시. 새 제안: 한 시 반.\n선생님 도착: 두 시. 먼저 교실 준비가 필요해요.\n제안을 하고 동료가 가능한지도 물어보세요.',[]),
        packet('동료에게 말해요.\n기존 약속: 네 시. 새 제안: 세 시 반.\n선생님 도착: 네 시. 먼저 자료 준비가 필요해요.\n제안을 하고 동료가 가능한지도 물어보세요.',[])))
    return tasks


if __name__ == '__main__':
    import author_phase_a1_genres as genres
    for phase_id, factory in [('KP02',kp02),('KP03',kp03),('KP04',kp04)]:
        extra = getattr(genres, phase_id.lower(), lambda: [])()
        write_source(phase_id, factory() + extra)
