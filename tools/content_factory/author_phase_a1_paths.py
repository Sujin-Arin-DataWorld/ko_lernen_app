"""A1 interaction, announcement and repair paths; unsigned until reviewed."""
import json
from phase_task_authoring import FOLDER, choice, free_text, loc, packet, task, write_source


def kp01():
    teaching = loc(
        '처음 만난 사람의 질문과 답을 연결하세요. 못 들은 이름은 다시 묻고, 도움에는 감사해요. 죄송해요에 괜찮아요로 답할 수 있어요. 가족 관계와 직업은 인물마다 따로 확인해요. 질문 말끝과 상대가 응답하기 전의 휴지도 들어 보세요.',
        'Match each question to its reply in a first meeting. Ask again for a name you missed, thank someone for help, and acknowledge an apology. Keep each person’s family relationship and job separate. Listen to question endings and the pause before the reply.',
        'Ordne bei einer ersten Begegnung Fragen und Antworten einander zu. Frage nach einem überhörten Namen, bedanke dich für Hilfe und reagiere auf eine Entschuldigung. Halte Familienbeziehungen und Berufe der Personen auseinander. Achte auf Frageendungen und die Pause vor der Antwort.')
    def dialogue(name, sibling, job, room):
        job_copula = "이에요" if (ord(job[-1]) - 0xAC00) % 28 else "예요"
        return packet(f'학생: 안녕하세요. 저는 {name}예요.\n동료: 안녕하세요. 죄송해요. 이름을 다시 말씀해 주세요.\n학생: 괜찮아요. {name}예요.\n동료: 네, {name} 씨. 저는 민수예요. 저 사람은 누구예요?\n학생: 제 {sibling}이에요. 직업은 {job}{job_copula}.\n동료: 한국어 수업은 어디예요?\n학생: {room}호예요.\n동료: {room}호 맞아요?\n학생: 네, 맞아요.\n동료: 감사합니다. 도움이 됐어요.\n학생: 아니에요. 같이 가요.', [
            choice('repair', loc('동료가 다시 물은 것은?', 'What did the classmate ask to hear again?', 'Was wollte die andere Person noch einmal hören?'), ['이름', '직업'], teaching),
            choice('relationship', loc('소개한 가족은 누구예요?', 'Which relative was introduced?', 'Welches Familienmitglied wurde vorgestellt?'), [sibling, '부모님'], teaching),
            choice('job', loc('가족의 직업은?', 'What is the relative’s job?', 'Welchen Beruf hat das Familienmitglied?'), [job, '학생'], teaching),
            choice('confirmation', loc('끝에 확인한 정보는?', 'Which detail was confirmed at the end?', 'Welche Angabe wurde zum Schluss bestätigt?'), [f'수업 교실은 {room}호', f'수업은 {room}시에 시작'], teaching),
            choice('thanks', loc('도움을 받은 뒤 한 말은?', 'What was said after receiving help?', 'Was wurde nach der Hilfe gesagt?'), ['감사합니다. 도움이 됐어요.', '안녕히 주무세요.'], teaching),
            choice('apology', loc('못 들어서 죄송하다는 말에 어떻게 답했어요?', 'How was the apology for not hearing acknowledged?', 'Wie wurde auf die Entschuldigung wegen des Überhörens reagiert?'), ['괜찮아요.', '처음 뵙겠습니다.'], teaching),
        ], 'audio')
    listen = task('KP01', 'listening:03', 'listening', loc('첫 만남에서 다시 묻고 확인하기', 'Clarify and confirm at a first meeting', 'Beim Kennenlernen nachfragen und bestätigen'), teaching,
        dialogue('미나', '동생', '의사', '201'), dialogue('유나', '동생', '회사원', '302'))
    speak = task('KP01', 'speaking:02', 'speaking', loc('이름 소리와 소개 대화', 'Name sounds and an introduction dialogue', 'Namenslaute und eine Vorstellung im Kurs'),
        loc('달·딸·탈을 각각 말하고 이름의 받침을 끝까지 발음해요. 인사→소개→못 들은 이름 다시 묻기→교실 확인→감사 순서로 녹음하세요. 상대의 사과에는 괜찮아요로 응답해요. 다시 듣고 말끝과 쉬는 위치를 고쳐 재녹음하세요. 발음·억양·의미는 미채점이에요.',
            'Say 달, 딸 and 탈 separately, then pronounce the final consonant of the name. Record a greeting, introduction, request to repeat a name, room confirmation and thanks. Respond to an apology. Replay and revise endings and pauses; pronunciation, intonation and meaning remain unscored.',
            'Sprich 달, 딸 und 탈 einzeln und danach den Namen mit seinem Endkonsonanten. Nimm Begrüßung, Vorstellung, Bitte um Wiederholung des Namens, Bestätigung des Raums und Dank auf. Reagiere auf eine Entschuldigung. Höre zu und überarbeite Endungen und Pausen; Aussprache, Intonation und Inhalt bleiben unbewertet.'),
        packet('가상 인물: 지민 / 학생. 가족: 동생은 의사. 처음 만난 동료에게 해요체로 자기와 가족을 소개해요.\n동료의 이름을 못 들었어요.\n동료가 다시 말해요: 저는 민수예요. 수업은 201호예요. 늦어서 죄송해요.\n이름을 다시 묻는 말부터 확인·감사·사과에 대한 응답까지 말해 보세요. 교실 안내가 도움이 됐다고도 전하세요.', []),
        packet('가상 인물: 지선 / 회사원. 가족: 동생은 학생. 처음 만난 동료에게 해요체로 자기와 가족을 소개해요.\n동료의 이름을 못 들었어요.\n동료가 다시 말해요: 저는 유나예요. 수업은 302호예요. 늦어서 죄송해요.\n이름을 다시 묻는 말부터 확인·감사·사과에 대한 응답까지 말해 보세요. 교실 안내가 도움이 됐다고도 전하세요.', []))
    return [listen, speak]


def kp02():
    teaching = loc('방송은 여러 사람에게 알리는 안내예요. 바뀐 교실·수업 시간·도움받을 곳을 구별하고 들리지 않은 정보는 확인해요. 집에처럼 받침 뒤 모음이 이어지는 말과 시각을 낱글자로 끊지 않아요.',
        'An announcement addresses a group. Separate the changed room, class time and place to ask for help. Listen to connected sounds and times as meaningful phrases, not isolated letters.',
        'Eine Durchsage richtet sich an mehrere Personen. Unterscheide geänderten Raum, Unterrichtszeit und Anlaufstelle für Fragen. Höre verbundene Laute und Uhrzeiten als Sinneinheiten statt als einzelne Buchstaben.')
    def announcement(old, new, start, end):
        return packet(f'한국어 학교에서 알려 드립니다. 오늘 수업은 {old}호에서 {new}호로 바뀌었습니다. 수업은 {start}부터 {end}까지입니다. 수업이 끝나면 집에 갑니다. 질문이 있으면 안내 데스크에 와 주세요.', [
            choice('room', loc('오늘 수업 교실은?', 'Which room is used today?', 'In welchem Raum ist der Unterricht heute?'), [new+'호', old+'호'], teaching),
            choice('time', loc('수업 시간은?', 'When does class run?', 'Von wann bis wann ist Unterricht?'), [start+'부터 '+end+'까지', end+'부터 '+start+'까지'], teaching),
            choice('help', loc('질문은 어디에서 해요?', 'Where can you ask a question?', 'Wo kannst du nachfragen?'), ['안내 데스크', '집'], teaching),
        ], 'audio')
    listen = task('KP02','listening:04','listening',loc('교실 변경 안내 방송','A classroom-change announcement','Durchsage zum Raumwechsel'),teaching,
        announcement('101','201','아홉 시','열한 시'), announcement('202','302','두 시','네 시'))
    read_teaching = loc('집 안의 물건 위치와 어제 한 일을 구별해요. 소파 옆과 책상 위는 다른 위치예요. 이미 끝낸 일과 오늘 할 일도 나눠 읽어요.',
        'Separate the positions of objects at home from yesterday’s events. Beside the sofa differs from on the desk; completed events differ from today’s plans.',
        'Unterscheide die Lage von Gegenständen zu Hause von gestrigen Ereignissen. Neben dem Sofa ist etwas anderes als auf dem Schreibtisch; Vergangenes ist kein Plan für heute.')
    def note(person, object_name, position, past):
        return packet(f'{person} 씨에게\n{object_name}은 {position}에 있어요. 방은 작지만 조용해요. 어제 {past}. 오늘은 집에서 공부해요. 물건을 못 찾으면 저한테 전화해 주세요.', [
            choice('location',loc('물건이 있는 곳은?', 'Where is the object?', 'Wo liegt der Gegenstand?'),[position,'침대 밑'],read_teaching),
            choice('past',loc('이미 한 일은?', 'Which action is already completed?', 'Was ist bereits geschehen?'),[past,'오늘 집에서 공부했어요'],read_teaching),
            choice('repair',loc('물건을 못 찾으면 어떻게 해요?', 'What should you do if you cannot find it?', 'Was sollst du tun, wenn du den Gegenstand nicht findest?'),['메모를 쓴 사람에게 전화해요.','물건을 버려요.'],read_teaching),
        ])
    read = task('KP02','reading:02','reading',loc('집 안 물건과 어제의 일','Objects at home and yesterday’s events','Gegenstände zu Hause und gestrige Ereignisse'),read_teaching,
        note('미나','공책','책상 위','도서관에서 책을 빌렸어요'), note('민수','가방','소파 옆','가게에서 물을 샀어요'))
    speak = task('KP02','speaking:02','speaking',loc('위치·일과를 확인하는 음성 메시지','A voice message confirming location and routine','Sprachnachricht zu Ort und Tagesablauf'),
        loc('물건 위치, 어제 한 일, 오늘 교통편과 시각을 말한 뒤 상대에게 확인 질문을 하세요. 집에·학교에서를 이어 말하고 의미 단위 사이에서 쉬어요. 녹음을 다시 듣고 수정해요. 의미와 발음은 미채점이에요.',
            'State the object’s location, yesterday’s action, today’s transport and times, then ask for confirmation. Connect the sounds in 집에 and 학교에서 and pause between meaningful units. Replay and revise; meaning and pronunciation remain unscored.',
            'Nenne Gegenstandsort, gestrige Tätigkeit sowie heutiges Verkehrsmittel und Uhrzeiten und frage dann nach. Verbinde die Laute in 집에 und 학교에서 und mache Pausen zwischen Sinneinheiten. Höre zu und überarbeite; Inhalt und Aussprache bleiben unbewertet.'),
        packet('같은 반 동료에게 해요체로 말해요.\n가방: 책상 위. 방: 작고 조용함. 어제: 집에서 쉼. 오늘: 버스로 학교에 감. 학교에서 아홉 시부터 열한 시까지 공부한 뒤 집에 감.\n상대도 열한 시에 끝나는지 아직 몰라요. 확인하세요.',[]),
        packet('같은 반 동료에게 해요체로 말해요.\n공책: 소파 옆. 방: 크고 밝음. 어제: 집에서 책을 읽음. 오늘: 지하철로 학교에 감. 학교에서 두 시부터 네 시까지 공부한 뒤 집에 감.\n상대도 네 시에 끝나는지 아직 몰라요. 확인하세요.',[]))
    return [listen,read,speak]


def kp03():
    teaching = loc('창구 대화에서 선호·예산·시간을 함께 확인해요. 처음 희망과 마지막 구매가 다를 수 있어요. 직원에게 부탁하는 말과 동료에게 함께 하자고 묻는 말을 구별해요.',
        'At a ticket counter, check preference, budget and time together. The final purchase may differ from the first wish. Distinguish a request to staff from a shared proposal to a peer.',
        'Prüfe am Schalter Vorliebe, Budget und Zeit gemeinsam. Der endgültige Kauf kann vom ersten Wunsch abweichen. Unterscheide eine Bitte an das Personal von einem gemeinsamen Vorschlag an eine gleichgestellte Person.')
    def passage(first, final, time, price, budget):
        return packet(f'여행 창구\n손님: 저는 {first} 여행을 더 좋아해요. 오늘 갈 수 있어요?\n직원: 오늘은 {first} 표가 없어요. {final} 표는 있어요. {time}에 출발하고 {price}원이에요.\n손님: 예산은 {budget}원이에요. 그러면 {final} 표 한 장 주세요.\n직원: 네, {time} 출발 표 한 장입니다.\n손님: 감사합니다. 도움이 됐어요.',[
            choice('preference',loc('처음 선호한 것은?', 'What was the original preference?', 'Was wurde zuerst bevorzugt?'),[first,final],teaching),
            choice('purchase',loc('마지막에 산 것은?', 'What was finally purchased?', 'Was wurde schließlich gekauft?'),[final+' 표 한 장',first+' 표 한 장'],teaching),
            choice('budget',loc('예산 안에서 살 수 있어요?', 'Does the ticket fit the budget?', 'Liegt die Fahrkarte im Budget?'),['네, 표 값이 예산보다 적어요.','아니요, 표 값이 예산보다 많아요.'],teaching),
        ])
    read = task('KP03','reading:02','reading',loc('여행 창구에서 표 사기','Buy a ticket at a travel counter','Eine Fahrkarte am Schalter kaufen'),teaching,
        passage('기차','버스','세 시','8000','10000'),passage('버스','기차','네 시','9000','12000'))
    speak = task('KP03','speaking:02','speaking',loc('선호·구매·공동 제안 말하기','Express preference, buy and propose','Vorliebe, Kauf und Vorschlag ausdrücken'),
        loc('직원에게 선호와 구매를 말하고 확인·감사하세요. 동료에게는 바뀐 시간과 공동 활동을 질문으로 제안하세요. 주세요·갈까요·갑시다를 말해 보고 누가 행동하는지 확인해요. 모든 질문을 같은 상승 억양으로 말할 필요는 없어요. 재생 후 재녹음하며 의미·억양은 미채점이에요.',
            'Tell staff your preference and purchase, then confirm and thank them. Suggest a new time and shared activity to a peer as a question. Say 주세요, 갈까요 and 갑시다 and check who should act. Questions need not all have the same rising intonation. Replay and re-record; meaning and intonation remain unscored.',
            'Nenne dem Personal Vorliebe und Kaufwunsch, bestätige und bedanke dich. Schlage einer gleichgestellten Person eine neue Zeit und gemeinsame Tätigkeit als Frage vor. Sprich 주세요, 갈까요 und 갑시다 und prüfe, wer handeln soll. Nicht jede Frage braucht dieselbe steigende Intonation. Höre zu und nimm erneut auf; Inhalt und Intonation bleiben unbewertet.'),
        packet('창구 직원에게 해요체: 기차를 더 좋아하지만 오늘 기차 표 없음. 버스 표 한 장 구매. 출발 세 시·8000원 확인.\n동료에게 해요체: 두 시 약속을 네 시로 바꾸자고 묻기. 도착 후 같이 차 마시기 제안. 아직 상대 답은 없음.',[]),
        packet('창구 직원에게 해요체: 버스를 더 좋아하지만 오늘 버스 표 없음. 기차 표 한 장 구매. 출발 네 시·9000원 확인.\n동료에게 해요체: 세 시 약속을 다섯 시로 바꾸자고 묻기. 도착 후 같이 저녁 먹기 제안. 아직 상대 답은 없음.',[]))
    chat_teaching=loc('기존 약속과 새로 제안한 시각을 구별해요. 상대가 장소를 아직 답하지 않았다면 합의로 만들지 않아요.',
        'Distinguish the old appointment from the newly proposed time. Do not treat an unanswered question about the place as agreement.',
        'Unterscheide bisherigen Termin und neu vorgeschlagene Uhrzeit. Eine unbeantwortete Ortsfrage ist keine Zustimmung.')
    def chat(old,new,place):
        return packet(f'같은 반 동료의 채팅\n미나: 우리 약속은 {old}예요. 저는 {new}에 만나고 싶어요. 시간을 바꿀 수 있어요?\n준호: 네, {new}에 만나요.\n미나: 고마워요. {place}에서 만날까요?\n아직 다음 답장은 없어요.',[
            choice('old',loc('기존 약속 시각은?', 'What was the original time?', 'Welche Uhrzeit war ursprünglich vereinbart?'),[old,new],chat_teaching),
            choice('new',loc('합의한 새 시각은?', 'Which new time was agreed?', 'Welche neue Uhrzeit wurde vereinbart?'),[new,old],chat_teaching),
            choice('place',loc('장소까지 합의했어요?', 'Was the place agreed too?', 'Wurde auch der Ort vereinbart?'),['아직 아니에요. 장소 질문에 답이 없어요.','네. 장소도 확정됐어요.'],chat_teaching),
        ])
    reading_chat=task('KP03','reading:03','reading',loc('시간 변경과 미확정 장소','A changed time and an unconfirmed place','Neue Uhrzeit und noch offener Ort'),chat_teaching,
        chat('토요일 두 시','토요일 세 시','도서관'),chat('일요일 세 시','일요일 다섯 시','카페'))
    return [read,speak,reading_chat]


def kp04():
    teaching = loc('공손한 말끝과 높이는 주체를 따로 확인해요. 친한 사이의 반말은 관계가 합의된 장면에서만 사용해요. 같은 정보라도 말투를 바꿀 수 있지만 사실·의무·확신은 바꾸지 않아요.',
        'Check listener politeness separately from respect for the subject. Casual speech here is restricted to an explicitly agreed close relationship. Changing register must not change facts, obligation or certainty.',
        'Prüfe Höflichkeit gegenüber Zuhörenden getrennt von der Ehrung des Subjekts. Vertrauliche Sprache ist hier auf eine ausdrücklich vereinbarte enge Beziehung begrenzt. Ein Stilwechsel darf Fakten, Verpflichtung oder Gewissheit nicht verändern.')
    def styles(place, time, weather):
        return packet(f'학교 안내: 선생님께서 {time}에 오십니다.\n학습 동료에게: {weather} 밖에서 만나지 못해요. {place}에서 만날까요?\n서로 반말을 쓰기로 한 친한 친구에게: {weather} 밖에서 못 만나. {place}에서 만날까?',[
            choice('formal',loc('격식 있는 안내의 말끝은?', 'Which ending belongs to the formal announcement?', 'Welche Endung gehört zur förmlichen Mitteilung?'),['오십니다','못 만나'],teaching),
            choice('casual',loc('반말 장면의 관계는?', 'What relationship allows casual speech here?', 'Welche Beziehung erlaubt hier vertrauliche Sprache?'),['서로 반말을 쓰기로 한 친한 친구','처음 만난 모든 사람'],teaching),
            choice('certainty',loc('만남 장소는 이미 합의됐어요?', 'Has the meeting place already been agreed?', 'Ist der Treffpunkt bereits vereinbart?'),['아니요. 질문으로 제안해요.','네. 명령으로 확정했어요.'],teaching),
        ])
    read = task('KP04','reading:02','reading',loc('같은 정보와 다른 말투','The same information in different registers','Gleiche Information in verschiedenen Sprachstilen'),teaching,
        styles('도서관','두 시','비가 와서'),styles('카페','네 시','눈이 와서'))
    sound_teaching = loc('오시니까에는 주체 높임 -시-와 이유 연결 -(으)니까가 있어요. 선생님이 오시니까 / 먼저 준비해요처럼 이유와 다음 행동의 경계를 들어요. 평서·요청을 말끝까지 듣고 구별해요. 억양 능력 전체를 평가하는 과제는 아니에요.',
        'In 오시니까, -시- honors the subject and -(으)니까 gives a reason. Listen for the boundary between the reason and next action, and distinguish a statement from a request by its ending. This does not assess overall intonation ability.',
        'In 오시니까 ehrt -시- das Subjekt, während -(으)니까 einen Grund nennt. Höre die Grenze zwischen Begründung und nächster Handlung und unterscheide Aussage und Bitte an der Endung. Die gesamte Intonationsfähigkeit wird damit nicht bewertet.')
    def sound(person, action):
        return packet(f'{person}이 오시니까 먼저 {action}. {person}은 지금 학교에 오세요.',[
            choice('reason',loc('먼저 행동하는 이유는?', 'Why should the action happen first?', 'Warum soll zuerst gehandelt werden?'),[person+'이 오시니까','선생님이 떠나셨으니까'],sound_teaching),
            choice('ending',loc('첫 문장 끝은 무엇을 해요?', 'What does the first sentence ending do?', 'Was bewirkt die Endung des ersten Satzes?'),['상대에게 행동을 부탁해요.','이미 끝낸 일을 보고해요.'],sound_teaching),
        ],'audio')
    listen=task('KP04','listening:03','listening',loc('높임과 이유절의 경계 듣기','Hear honorifics and a reason-clause boundary','Höflichkeitsform und Begründung hören'),sound_teaching,
        sound('선생님','자료를 준비하세요'),sound('선생님','교실을 정리하세요'))
    speak=task('KP04','speaking:02','speaking',loc('기분·몸 상태·일정 변경 설명','Explain feelings, symptoms and a changed plan','Gefühle, Beschwerden und Planänderung erklären'),
        loc('가상 정보만 사용해 기분·증상·날씨를 말하고 사과와 대안을 전하세요. 물건의 색·상태, 안내문의 순서와 의무를 빠뜨리지 마세요. 친절함을 이유로 상대의 동의를 만들지 않아요. 해요체와 의미 단위 휴지를 확인하고 재녹음해요. 의미·발음은 미채점이에요.',
            'Use only the fictional facts to state feelings, symptoms and weather, apologize and propose an alternative. Include the object’s color and condition, the stated order and requirement. Do not invent agreement. Check polite endings and meaningful pauses and re-record; meaning and pronunciation remain unscored.',
            'Nenne anhand der fiktiven Angaben Gefühle, Beschwerden und Wetter, entschuldige dich und schlage eine Alternative vor. Behalte Farbe und Zustand des Gegenstands sowie Reihenfolge und Pflicht aus dem Hinweis bei. Erfinde keine Zustimmung. Prüfe höfliche Endungen und sinnvolle Pausen und nimm erneut auf; Inhalt und Aussprache bleiben unbewertet.'),
        packet('같은 반 동료에게 해요체로 말해요. 가상 상황이에요.\n기분: 속상함. 증상: 머리가 아픔. 날씨: 비. 파란 우산: 젖어 있음.\n오늘 두 시 약속을 취소해 사과하고 내일 세 시를 제안해요.\n교실 안내: 들어오기 전에 우산을 접어야 해요. 들어온 후에 의자에 앉아요. 상대의 답은 아직 없어요.',[]),
        packet('같은 반 동료에게 해요체로 말해요. 가상 상황이에요.\n기분: 아쉬움. 증상: 목이 아픔. 날씨: 눈. 빨간 가방: 젖어 있음.\n오늘 네 시 약속을 취소해 사과하고 내일 두 시를 제안해요.\n교실 안내: 들어오기 전에 가방을 닦아야 해요. 들어온 후에 책상에 놓아요. 상대의 답은 아직 없어요.',[]))
    message_teaching=loc('메시지의 기분·증상·물건 상태·다음 행동을 구별해요. 사과와 약속 변경이 들어 있어도 새로운 약속의 동의까지 주어진 것은 아니에요.',
        'Separate feelings, symptoms, the object’s condition and the next action. An apology and a proposed change do not imply agreement to a new appointment.',
        'Unterscheide Gefühle, Beschwerden, Zustand des Gegenstands und nächste Handlung. Eine Entschuldigung mit Änderungsvorschlag bedeutet noch keine Zustimmung zum neuen Termin.')
    def message(symptom, feeling, weather, color, item, old, new, action):
        return packet(f'동료에게 보낸 메시지\n오늘은 {symptom}. 그래서 {feeling}. {weather} {color} {item}도 젖었어요. {old} 약속에 가지 못해서 미안해요. {new}에 만날까요?\n교실 안내에는 들어가기 전에 {item}을 {action} 한다고 써 있어요. 들어간 후에 의자에 앉아요.',[
            choice('feeling',loc('화자의 기분은?', 'How does the sender feel?', 'Wie fühlt sich die schreibende Person?'),[feeling,'기뻐요'],message_teaching),
            choice('symptom',loc('몸 상태는?', 'What symptom is reported?', 'Welche Beschwerde wird genannt?'),[symptom,'배가 아파요'],message_teaching),
            choice('object',loc('물건의 상태는?', 'What is the object’s condition?', 'In welchem Zustand ist der Gegenstand?'),[f'{color} {item}이 젖었어요.',f'{color} {item}이 말랐어요.'],message_teaching),
            choice('before',loc('들어가기 전에 해야 하는 것은?', 'What must happen before entering?', 'Was muss vor dem Eintreten geschehen?'),[f'{item}을 {action} 해요.','의자에 앉아요.'],message_teaching),
            choice('agreement',loc('새 약속은 확정됐어요?', 'Is the new appointment confirmed?', 'Ist der neue Termin bestätigt?'),['아직 몰라요. 상대의 답이 없어요.','네. 상대가 동의했어요.'],message_teaching),
        ])
    reading_message=task('KP04','reading:03','reading',loc('몸 상태와 약속 변경 메시지','A message about symptoms and a changed plan','Nachricht zu Beschwerden und einer Planänderung'),message_teaching,
        message('머리가 아파요','속상해요','비가 와서','파란','우산','오늘 두 시','내일 세 시','접어야'),
        message('목이 아파요','아쉬워요','눈이 와서','빨간','가방','오늘 네 시','내일 두 시','닦아야'))
    return [read,listen,speak,reading_message]


if __name__ == '__main__':
    for phase, factory in [('KP01',kp01),('KP02',kp02),('KP03',kp03),('KP04',kp04)]:
        extras=factory()
        ids={t['id'] for t in extras}
        source=json.loads((FOLDER/f'{phase.lower()}.json').read_text(encoding='utf-8'))
        write_source(phase,[t for t in source['tasks'] if t['id'] not in ids]+extras)
