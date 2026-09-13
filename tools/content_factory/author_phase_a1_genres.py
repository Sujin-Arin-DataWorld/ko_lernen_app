"""Additional authored A1 genres, kept separate from publication review."""
from phase_task_authoring import choice, loc, packet, sentence, task


def kp01():
    def signs(room, allowed, forbidden):
        return packet(f'{room}\n가능: {allowed}\n금지: {forbidden}', [
            choice('place', loc('이 표지는 어디에 있어요?', 'Where is this sign?', 'Wo steht dieses Schild?'), [room,'버스 정류장'], loc(f'맨 위에 장소 {room}이 있어요.', f'The heading names {room}.', f'Die Überschrift nennt {room}.')),
            choice('permission', loc('할 수 있는 것은?', 'What is allowed?', 'Was ist erlaubt?'), [allowed,forbidden], loc(f'가능은 {allowed}, 금지는 {forbidden}이에요.', f'{allowed} is allowed; {forbidden} is prohibited.', f'{allowed} ist erlaubt; {forbidden} ist verboten.')),
            choice('prohibition', loc('하면 안 되는 것은?', 'What is prohibited?', 'Was ist verboten?'), [forbidden,allowed], loc('금지 아래의 행동을 확인해요. 장소 이름은 행동이 아니에요.', 'Read the action under 금지. The place name is not an action.', 'Lies die Handlung unter 금지. Der Ortsname ist keine Handlung.')),
        ], 'sign')
    tasks = [task('KP01','reading:02','reading',loc('교실과 도서관 표지', 'Classroom and library signs', 'Schilder im Kursraum und in der Bibliothek'),
        loc('가능은 할 수 있다는 뜻, 금지는 하면 안 된다는 뜻이에요. 장소·허용·금지를 따로 읽어요.', '가능 means allowed and 금지 means prohibited. Separate place, permission and prohibition.', '가능 bedeutet erlaubt, 금지 bedeutet verboten. Trenne Ort, Erlaubnis und Verbot.'),
        signs('한국어 교실','물 마시기','음식 먹기'), signs('학교 도서관','책 읽기','전화하기'))]
    def sounds(words, wrong_order, name, other_name):
        return packet(f'{words.replace(" → ", ". ")}. 제 이름은 {name}이에요.',[
            choice('sounds',loc('처음 세 낱말을 들은 순서대로 고르세요.', 'Choose the first three words in the order heard.', 'Wähle die ersten drei Wörter in der gehörten Reihenfolge.'),[words,wrong_order],loc(f'순서는 {words}예요. ㄷ·ㄸ·ㅌ은 평음·경음·격음의 구별이에요.',f'The order is {words}. ㄷ, ㄸ and ㅌ contrast lax, tense and aspirated consonants.',f'Die Reihenfolge ist {words}. ㄷ, ㄸ und ㅌ unterscheiden ungespannte, gespannte und aspirierte Konsonanten.')),
            choice('name',loc('소개한 이름은?', 'Which name is introduced?', 'Welcher Name wird genannt?'),[name,other_name],loc(f'들은 이름은 {name}이에요. 이름 끝 받침도 들어요.',f'The name is {name}. Listen to its final consonant too.',f'Der Name lautet {name}. Achte auch auf den Endkonsonanten.')),
        ],'audio')
    tasks.append(task('KP01','listening:02','listening',loc('달·딸·탈과 이름의 끝소리', 'Hear 달, 딸, 탈 and name endings', '달, 딸, 탈 und Namensendungen hören'),
        loc('ㄷ·ㄸ·ㅌ의 세 소리를 모어의 유성·무성 둘로만 나누지 않아요. 들은 순서와 이름 받침을 확인하고 소개 문장으로 다시 말해 보세요. 선택 응답만 채점해요.', 'Do not reduce ㄷ, ㄸ and ㅌ to a two-way voiced/unvoiced contrast. Identify the sequence and final consonant, then repeat the introduction. Only the choices are scored.', 'Reduziere ㄷ, ㄸ und ㅌ nicht auf den Gegensatz stimmhaft/stimmlos. Erkenne Reihenfolge und Endkonsonant und sprich die Vorstellung nach. Nur die Auswahlantworten werden bewertet.'),
        sounds('달 → 딸 → 탈','딸 → 달 → 탈','민석','민서'),sounds('탈 → 달 → 딸','달 → 탈 → 딸','지선','지서')))
    def form(name, optional, missing, request):
        return packet(f'학교 등록 서식\n이름: 필수 / 가상 인물 이름: {name}\n{optional}: 선택 / 인물 카드에 없음\n{missing}: 필수 / 인물 카드에 없음\n모르는 필수 정보는 인물에게 물어본 뒤 작성해요.', [
            dict(id='name',kind='field',prompt=loc('주어진 이름을 쓰세요.', 'Enter the provided name.', 'Trage den angegebenen Namen ein.'), required=True,options=[],acceptedAnswers=[name],explanation=loc(f'이름은 {name}입니다.',f'The name is {name}.',f'Der Name ist {name}.')),
            choice('optional',loc(f'모르는 선택 항목 {optional}는 어떻게 해요?', f'What do you do with the unknown optional field {optional}?', f'Was machst du mit dem unbekannten freiwilligen Feld {optional}?'),['비워 두기','다른 사람의 정보 쓰기'],loc('선택 항목은 비워 둘 수 있어요. 다른 사람의 정보를 넣지 않아요.', 'An optional field may be left blank. Do not insert another person’s details.', 'Ein freiwilliges Feld darf leer bleiben. Trage keine fremden Angaben ein.')),
            sentence('ask_required',loc('빠진 필수 정보를 공손하게 물으세요.', 'Politely ask for the missing required information.', 'Frage höflich nach der fehlenden Pflichtangabe.'),[request,f'죄송해요. {request}'],[f'{missing}는 몰라도 괜찮아요.'],loc(f'예: {request} 아직 모르는 필수 정보를 지어내지 않아요.',f'Example: {request} Do not invent a missing required fact.',f'Beispiel: {request} Erfinde keine fehlende Pflichtangabe.')),
        ],'form')
    tasks.append(task('KP01','writing:02','writing',loc('필수·선택·모르는 정보', 'Required, optional and unknown information', 'Pflichtangaben, freiwillige und unbekannte Angaben'),
        loc('제공된 이름은 직접 쓰고, 모르는 선택 칸은 비워 두기로 선택하세요. 모르는 필수 정보는 확인 질문을 쓰세요. 이 과제 통과는 확인 전 서식이 모두 완성됐다는 뜻이 아니에요.', 'Write the provided name, choose to leave the unknown optional field blank, and write a question for the missing required fact. Passing does not mean the form is complete before that fact is confirmed.', 'Schreibe den angegebenen Namen, lasse das unbekannte freiwillige Feld frei und formuliere eine Frage zur fehlenden Pflichtangabe. Ein Bestehen bedeutet nicht, dass das Formular vor dieser Klärung vollständig ist.'),
        form('지수','이메일','전화번호','전화번호가 뭐예요?'),form('민호','전화번호','이메일','이메일 주소가 뭐예요?')))
    return tasks


def kp02():
    def phone(day, old, new, room, wrong_room):
        return packet(f'직원: 안녕하세요. 한국어 학교입니다. 수업 시간을 알려 드리려고 전화했어요.\n학생: {day} {old} 수업이에요?\n직원: 네. {new}로 바뀌었어요. 교실은 {room}호예요.\n학생: 교실 번호를 다시 말씀해 주세요.\n직원: {room}호입니다.\n학생: 네, {day} {new}, {room}호 맞지요?\n직원: 네, 맞아요.', [
            choice('purpose',loc('전화한 이유는?', 'Why did the staff member call?', 'Warum ruft die Person von der Schule an?'),['수업 시간 변경 안내','새 학생 등록'],loc('직원이 수업 시간을 알려 드리려고 전화했다고 말해요.', 'The caller says the call is about the class time.', 'Die anrufende Person nennt die Unterrichtszeit als Anlass.')),
            choice('time',loc('새 수업 시각은?', 'What is the new class time?', 'Wann beginnt der Unterricht jetzt?'),[new,old],loc(f'{old}에서 {new}로 바뀌었어요.', f'The time changes from {old} to {new}.', f'Die Zeit ändert sich von {old} auf {new}.')),
            choice('room',loc('확인된 교실은?', 'Which room is confirmed?', 'Welcher Raum wird bestätigt?'),[f'{room}호',f'{wrong_room}호'],loc(f'다시 물어보고 {room}호라고 확인해요. 못 들은 번호를 추측하지 않아요.', f'The student asks again and confirms room {room}, rather than guessing.', f'Die lernende Person fragt nach und bestätigt Raum {room}, statt zu raten.')),
        ],'audio')
    def note(name, item, place, action, wrong):
        full=f'{name} 씨, {item}은 {place}에 있어요.'
        request=f'{action} 주세요.'
        return packet(f'가상 인물에게 메모를 남겨요.\n받는 사람: {name}\n물건: {item}\n물건 위치: {place}\n다음 행동 요청: {action} 주기',[
            sentence('information',loc('받는 사람과 물건 위치를 쓰세요.', 'Address the recipient and state the item’s location.', 'Sprich die Person an und nenne den Ort des Gegenstands.'),[full,f'{name} 씨, {item}은 지금 {place}에 있어요.'],[f'{name} 씨, {item}은 {wrong}에 있어요.'],loc(f'예: {full} 물건 위치를 다른 장소로 바꾸지 않아요.',f'Example: {full} Keep the item’s location.',f'Beispiel: {full} Behalte den Ort des Gegenstands bei.')),
            sentence('action',loc('다음에 해 줄 행동을 부탁하세요.', 'Request the next action.', 'Bitte um den nächsten Schritt.'),[request,f'그리고 {request}'],[f'{action} 주지 마세요.'],loc(f'예: {request} 부탁을 금지로 바꾸면 뜻이 달라져요.',f'Example: {request} A prohibition would reverse the intended action.',f'Beispiel: {request} Ein Verbot würde die beabsichtigte Handlung umkehren.')),
        ],'form')
    tasks = [
        task('KP02','listening:02','listening',loc('전화로 바뀐 수업 확인하기', 'Confirm a class change by phone', 'Eine Unterrichtsänderung am Telefon bestätigen'),
            loc('전화 목적, 새 시각, 확인한 교실을 들어요. 못 들은 정보는 다시 묻고 기존 시각과 새 시각을 구별해요.', 'Listen for the purpose, new time and confirmed room. Ask again about unclear information and distinguish old and new times.', 'Achte auf Anlass, neue Zeit und bestätigten Raum. Frage bei Unklarheiten nach und trenne bisherige und neue Uhrzeit.'),
            phone('월요일','두 시','세 시','201','210'),phone('목요일','네 시','다섯 시','302','320')),
        task('KP02','writing:02','writing',loc('물건 위치와 다음 행동 메모', 'Leave a location and action note', 'Ort und nächsten Schritt notieren'),
            loc('가상 정보로 짧은 메모를 쓰세요. 받는 사람, 물건 위치, 부탁을 확인해요. 다른 자유 표현의 의미는 자동 채점 범위 밖일 수 있어요.', 'Write a short note using the fictional facts. Check the recipient, location and request. Other free wording may remain unscored.', 'Schreibe eine kurze Notiz mit den fiktiven Angaben. Prüfe Empfänger, Ort und Bitte. Andere freie Formulierungen können unbewertet bleiben.'),
            note('유나','책','교실','학교에 가져다','집'),note('민수','가방','도서관','집에 가져다','역')),
    ]
    def linking(text, place, time, wrong_place, wrong_time):
        return packet(text,[
            choice('place',loc('공부하는 곳은?', 'Where does the speaker study?', 'Wo lernt die Person?'),[place,wrong_place],loc('공부해요 앞의 장소와 에서를 한 의미 단위로 들어요.', 'Hear the place and 에서 as part of the study phrase.', 'Höre Ort und 에서 als Teil der Wortgruppe mit 공부해요.')),
            choice('end',loc('공부가 끝나는 시각은?', 'When does studying end?', 'Wann endet das Lernen?'),[time,wrong_time],loc(f'{time}까지가 끝을 나타내요. 낱말 사이 소리가 이어져도 시각을 바꾸지 않아요.',f'{time}까지 gives the endpoint. Linking between words does not change the time.',f'{time}까지 bezeichnet das Ende. Lautverbindungen ändern die Zeitangabe nicht.')),
        ],'audio')
    tasks.append(task('KP02','listening:03','listening',loc('이어지는 소리 속 장소와 시각', 'Hear places and times in connected speech', 'Ort und Zeit in verbundener Sprache hören'),
        loc('집에·학교에서·아홉 시까지를 낱글자로 끊지 않고 들어요. 받침과 뒤 모음이 이어지는 부분을 들은 뒤 문장 전체를 의미 단위로 다시 말해 보세요. 선택 응답만 채점해요.', 'Listen to 집에, 학교에서 and 아홉 시까지 as connected phrases. Notice final consonants linking to following vowels, then repeat whole meaning groups. Only the choices are scored.', 'Höre 집에, 학교에서 und 아홉 시까지 als zusammenhängende Wortgruppen. Achte auf Endkonsonanten vor folgenden Vokalen und sprich sinnvolle Wortgruppen nach. Nur die Auswahlantworten werden bewertet.'),
        linking('여덟 시에 집에 가요. 집에서 아홉 시까지 공부해요.','집','아홉 시','학교','여덟 시'),
        linking('아홉 시에 학교에 가요. 학교에서 열 시까지 공부해요.','학교','열 시','집','아홉 시')))
    return tasks


def kp03():
    def endings(first, second, request, proposal):
        return packet(f'{first} {second}', [
            choice('request',loc('상대에게 행동을 부탁하는 문장은?', 'Which sentence asks the listener to act?', 'Welcher Satz bittet die zuhörende Person um eine Handlung?'),[request,proposal],loc('-(으)세요로 상대에게 부탁해요. 같이 -(으)ㄹ까요?는 화자도 참여할 제안이에요.', '-(으)세요 requests an action from the listener; 같이 -(으)ㄹ까요? proposes a shared action.', '-(으)세요 bittet die zuhörende Person um eine Handlung; 같이 -(으)ㄹ까요? schlägt eine gemeinsame Handlung vor.')),
            choice('proposal',loc('함께 할지 묻는 문장은?', 'Which sentence asks about acting together?', 'Welcher Satz fragt nach einer gemeinsamen Handlung?'),[proposal,request],loc('말끝과 같이를 함께 들어요. 물음 억양만으로 모든 문장을 같은 제안으로 처리하지 않아요.', 'Listen to both the ending and 같이. A questioning intonation does not make every sentence the same kind of proposal.', 'Achte auf Endung und 같이. Eine Frageintonation macht nicht jeden Satz zum selben Vorschlag.')),
        ],'audio')
    return [task('KP03','listening:02','listening',loc('부탁과 제안의 말끝', 'Hear request and proposal endings', 'Endungen von Bitten und Vorschlägen hören'),
        loc('말끝까지 듣고 누가 행동할지 구별하세요. 들은 두 문장을 녹음 과제에서 다시 말하며 의미가 바뀌는 휴지를 피하세요. 억양 자체의 능력은 자동 채점하지 않아요.', 'Listen through the endings and identify who would act. Repeat the sentences in the recording task with pauses that preserve the meaning. Intonation ability itself is not automatically scored.', 'Höre bis zur Endung und erkenne, wer handeln würde. Wiederhole die Sätze in der Aufnahmeaufgabe mit sinnvollen Pausen. Die Intonationsfähigkeit selbst wird nicht automatisch bewertet.'),
        endings('여기에서 기다리세요.','같이 안으로 들어갈까요?','여기에서 기다리세요.','같이 안으로 들어갈까요?'),
        endings('같이 메뉴를 볼까요?','여기에 이름을 쓰세요.','여기에 이름을 쓰세요.','같이 메뉴를 볼까요?'))]


def kp04():
    def lyric(first, second, event, wrong, feeling):
        return packet(f'{first} {second}',[
            choice('event',loc('노랫말 속 상황은?', 'What situation does the lyric describe?', 'Welche Situation beschreibt der Liedtext?'),[event,wrong],loc(f'들은 구절 “{first}”에서 상황을 확인해요.',f'The phrase “{first}” establishes the situation.',f'Die Zeile „{first}“ beschreibt die Situation.')),
            choice('feeling',loc('화자의 마음은 어떻게 바뀌어요?', 'How does the speaker’s feeling change?', 'Wie verändert sich das Gefühl der sprechenden Person?'),[feeling,'기분 변화 없이 시각만 알려요.'],loc(f'“{second}”는 마음의 변화를 비유해요. 실제 방 온도나 날씨를 확인한 말은 아니에요.',f'“{second}” figuratively describes emotion, not a measured room temperature or weather report.',f'„{second}“ beschreibt bildhaft ein Gefühl, keine gemessene Raumtemperatur und keinen Wetterbericht.')),
        ],'audio')
    return [task('KP04','listening:02','listening',loc('짧은 노랫말의 상황과 마음', 'Hear a lyric’s situation and feeling', 'Situation und Gefühl in kurzen Liedzeilen verstehen'),
        loc('이 과제를 위해 쓴 노랫말을 낭독으로 들어요. 노래의 박자·가창 듣기 평가는 포함하지 않아요. 실제 사건과 마음의 비유를 나눠 보세요.', 'Hear a spoken reading of the original task lyrics. This does not assess comprehension of sung rhythm. Separate events from figurative feelings.', 'Höre die eigens verfassten Liedzeilen als Lesung. Gesang und Rhythmus werden dabei nicht geprüft. Trenne Ereignisse von bildhaften Gefühlen.'),
        lyric('친구를 기다리지만 친구는 아직 안 와요.','내 마음에 찬 바람이 불어요.','친구가 아직 오지 않았어요.','친구와 이미 만났어요.','기다리며 외로워져요.'),
        lyric('문을 열고 네 편지를 읽어요.','내 마음에 따뜻한 햇빛이 들어와요.','편지를 읽고 있어요.','편지를 아직 받지 못했어요.','편지를 읽으며 기분이 좋아져요.'))]
