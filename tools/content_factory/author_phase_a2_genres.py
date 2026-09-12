"""Additional A2 genre/phonology practice, including explicitly unscored writing."""
from phase_task_authoring import choice, free_text, loc, packet, task


def writing(phase, title, instructions, sources, rubric):
    prompt=loc('전체 글을 쓰고 해설의 기준으로 다시 검토하세요.', 'Write the complete text, then review it against the guidance.', 'Schreibe den vollständigen Text und prüfe ihn anschließend anhand der Hinweise.')
    return task(phase, 'writing:02', 'writing', title, instructions,
        packet(sources[0],[free_text('draft',prompt,rubric)],'form'),
        packet(sources[1],[free_text('draft',prompt,rubric)],'form'))


def kp05():
    def flyer(day,price,condition):
        return packet(f'문화센터 도자기 체험\n즐거움이 가득한 최고의 수업!\n{day} 오후 두 시, 재료 포함 {price}원.\n할인 조건: {condition}. 할인은 재료비에는 적용되지 않습니다.\n예약 후 안내 문자를 받은 사람만 참여할 수 있습니다.',[
            choice('fact',loc('확인할 수 있는 수업 정보는?', 'Which is a concrete course detail?', 'Welche Angabe zum Kurs ist konkret?'),[f'{day} 오후 두 시 / {price}원','모든 사람에게 최고의 수업'],loc('최고라는 평가는 홍보 표현이고 시각·가격과 달라요.', '최고 is promotional evaluation, unlike the stated time and price.', '최고 ist eine Werbewertung, anders als Uhrzeit und Preis.')),
            choice('condition',loc('할인 조건은?', 'What is the discount condition?', 'Unter welcher Bedingung gilt der Rabatt?'),[condition,'모든 사람에게 조건 없이 적용'],loc('할인 조건을 지우지 않아요.', 'Do not remove the discount condition.', 'Lass die Rabattbedingung nicht weg.')),
            choice('scope',loc('할인되지 않는 것은?', 'What is excluded from the discount?', 'Was ist vom Rabatt ausgenommen?'),['재료비','모든 비용이 할인됨'],loc('재료비에는 적용되지 않는다고 했어요.', 'Materials are explicitly excluded.', 'Materialkosten sind ausdrücklich ausgenommen.')),
        ],'sign')
    return [task('KP05','reading:02','reading',loc('전단의 사실과 홍보 문구', 'Facts and promotion in a flyer', 'Fakten und Werbung im Flyer'),
        loc('가격·조건과 최고의 같은 평가를 구별하세요.', 'Separate prices and conditions from claims such as “best”.', 'Trenne Preise und Bedingungen von Bewertungen wie „beste“.'),
        flyer('토요일','15000','학생증을 보여 주면 수업료 10% 할인'),flyer('일요일','18000','회원증을 보여 주면 수업료 20% 할인')),
        writing('KP05',loc('예약 확인 채팅과 답장', 'Reservation chat and reply', 'Chat zur Reservierung und Antwort'),
            loc('두 메시지를 쓰세요. 모르는 정보를 지어내지 말고 다시 물으세요. 자유 글은 자동 채점되지 않아요.', 'Write two messages. Ask again rather than inventing missing information. Free writing is not automatically scored.', 'Schreibe zwei Nachrichten. Frage nach, statt fehlende Angaben zu erfinden. Freies Schreiben wird nicht automatisch bewertet.'),
            ['센터 직원에게 해요체로 문의하세요. 토요일 두 명 예약 희망. 재료비 포함 여부는 모름. 직원은 두 명 예약 가능, 재료비 포함이라고 답했어요. 첫 문의와 그 답에 대한 확인 답장을 쓰세요.',
             '숙소 직원에게 해요체로 문의하세요. 금요일 한 명 숙박 희망. 아침 식사 포함 여부는 모름. 직원은 방 예약 가능, 아침 식사는 별도라고 답했어요. 첫 문의와 그 답에 대한 확인 답장을 쓰세요.'],
            loc('날짜·인원과 미확인 조건을 첫 메시지에 적었나요? 답장에서는 직원의 응답만 확인하고 무료 혜택을 만들지 않았나요? 확인되지 않은 객실·가격은 추가하지 마세요. 고친 뒤 다시 제출해도 의미는 미채점입니다.', 'Did the first message state date, party size and the open question? Does the reply preserve the staff response without inventing free benefits? Add no unconfirmed room or price. Rewriting remains unscored.', 'Nennt die erste Nachricht Datum, Personenzahl und offene Frage? Bewahrt die Antwort die Auskunft des Personals, ohne kostenlose Leistungen zu erfinden? Ergänze keine unbestätigten Zimmer- oder Preisangaben. Auch die Überarbeitung bleibt unbewertet.'))]


def kp06():
    def info(activity,first,second,why):
        return packet(f'{activity} 모임 소개\n처음 오는 사람은 먼저 {first}. 그다음 {second}.\n이 순서는 {why} 때문에 정했습니다. 참가자가 모임을 좋아하는 이유는 이 글에 설명하지 않았습니다.',[
            choice('first',loc('처음 오는 사람이 먼저 할 일은?', 'What does a newcomer do first?', 'Was tut eine neue Person zuerst?'),[first,second],loc('먼저와 그다음의 순서를 유지해요.', 'Preserve the order of 먼저 and 그다음.', 'Erhalte die Reihenfolge von 먼저 und 그다음.')),
            choice('cause',loc('설명된 이유는 무엇의 이유인가요?', 'What does the stated reason explain?', 'Was erklärt der genannte Grund?'),['활동 순서를 정한 이유','참가자가 모임을 좋아하는 이유'],loc('글이 설명한 순서의 이유를 개인 선호의 이유로 옮기지 않아요.', 'Do not turn a reason for the sequence into a reason for personal preference.', 'Übertrage die Begründung der Reihenfolge nicht auf persönliche Vorlieben.')),
        ])
    def sound(past,present,future):
        return packet(f'어제 다녀온 사람은 {past}예요. 지금 가는 사람은 {present}예요. 내일 갈 사람은 {future}예요.',[
            choice('past',loc('이미 다녀온 사람은?', 'Who has already been there?', 'Wer war bereits dort?'),[past,present,future],loc('다녀온은 지난 경험을 나타내요.', '다녀온 refers to the completed visit.', '다녀온 bezeichnet den bereits erfolgten Besuch.')),
            choice('future',loc('내일 갈 사람은?', 'Who will go tomorrow?', 'Wer geht morgen hin?'),[future,past,present],loc('갈 사람은 앞으로 갈 사람이에요.', '갈 사람 identifies the future visitor.', '갈 사람 bezeichnet die Person, die künftig hingeht.')),
        ],'audio')
    return [task('KP06','reading:02','reading',loc('모임 설명문의 순서와 이유', 'Sequence and reason in a group description', 'Reihenfolge und Grund in einer Gruppenbeschreibung'),
        loc('나열된 순서와 그 순서의 이유를 찾고 개인의 마음을 새로 만들지 않아요.', 'Find the sequence and its reason without inventing personal motivations.', 'Finde die Reihenfolge und ihre Begründung, ohne persönliche Beweggründe zu erfinden.'),
        info('사진','카메라 사용법을 배웁니다','사진을 찍어 봅니다','처음 온 사람의 안전이 중요하기'),
        info('요리','재료를 확인합니다','함께 요리합니다','알레르기 재료 확인이 필요하기')),
        task('KP06','listening:02','listening',loc('다녀온 사람·가는 사람·갈 사람', 'Past, present and future participants', 'Personen in Vergangenheit, Gegenwart und Zukunft'),
            loc('관형절의 말끝을 듣고 사람과 시점을 연결하세요. 한 음절을 놓치면 시간을 바꿀 수 있어요.', 'Listen to the modifier endings and match people to time. Missing an ending can shift the time reference.', 'Höre die Endungen der Attribute und ordne die Personen zeitlich zu. Eine überhörte Endung kann den Zeitbezug ändern.'),
            sound('유나','민지','소라'),sound('준호','지수','민수')),
        writing('KP06',loc('첫 경험을 전하는 이메일', 'Email about a first experience', 'E-Mail über eine erste Erfahrung'),
            loc('반말에 합의한 친구에게 제목·용건·응답 요청이 있는 이메일을 쓰세요. 자유 글은 루브릭으로 재작성하며 미채점으로 남아요.', 'Write a subject, message and reply request to a friend with agreed casual speech. Review and rewrite using the rubric; free writing remains unscored.', 'Schreibe Betreff, Anliegen und Antwortbitte an eine befreundete Person mit vereinbarter vertraulicher Anrede. Prüfe und überarbeite den Text anhand der Kriterien; er bleibt unbewertet.'),
            ['친구 지수에게 이메일. 6월 3일에 처음 빵 만들기를 시작함. 만들다가 정전되어 끝내지 못함. 재미있었다는 것은 나의 느낌. 다음 주 토요일에 같이 해 볼지 물어보기. 지수의 답은 아직 모름.',
             '친구 은우에게 이메일. 7월 8일에 처음 화분 만들기를 시작함. 수업이 끝나서 완성하지 못함. 다시 해 보고 싶다는 것은 나의 생각. 다음 주 일요일에 같이 해 볼지 물어보기. 은우의 답은 아직 모름.'],
            loc('제목과 수신자가 있나요? 시작 시점, 도중 사건, 미완료를 유지했나요? 감상은 자기 생각으로, 초대는 아직 답을 받지 않은 질문으로 썼나요? 상대가 이미 동의했다고 쓰지 말고 고쳐 보세요.', 'Is there a subject and recipient? Did you preserve start time, interruption and non-completion? Is the reaction your own view and the invitation an unanswered question? Revise any invented acceptance.', 'Gibt es Betreff und Empfänger? Bleiben Beginn, Unterbrechung und fehlender Abschluss erhalten? Ist der Eindruck deine eigene Sicht und die Einladung eine unbeantwortete Frage? Korrigiere jede erfundene Zusage.'))]


def kp07():
    def phone(day,confirmed):
        return packet(f'가: 안녕하세요. 모임 시간을 확인하려고 전화했어요.\n나: {day}에 만나요. 시간은 잠시만요.\n가: 시간을 못 들었어요. 다시 말씀해 주시겠어요?\n나: {confirmed}예요.\n가: 네, {day} {confirmed}, 맞지요?\n나: 네, 맞아요.',[
            choice('purpose',loc('전화를 건 목적은?', 'Why was the call made?', 'Warum wurde angerufen?'),['모임 시간 확인','모임 취소 통보'],loc('시간을 확인하려는 전화예요.', 'The call checks the meeting time.', 'Der Anruf klärt die Uhrzeit des Treffens.')),
            choice('confirmed',loc('되받아서 확인한 정보는?', 'What is repeated and confirmed?', 'Welche Angabe wird wiederholt und bestätigt?'),[f'{day} {confirmed}','시간은 끝까지 확인되지 않음'],loc('다시 묻고 맞아요라는 확인을 받았어요.', 'A clarification question receives explicit confirmation.', 'Auf die Rückfrage folgt eine ausdrückliche Bestätigung.')),
        ],'audio')
    return [task('KP07','listening:02','listening',loc('못 들은 시간을 다시 확인하기', 'Clarify a time you missed', 'Eine nicht verstandene Uhrzeit nachfragen'),
        loc('처음에 안 들린 시각을 추측하지 않고 재질문과 확인 발화를 들어요.', 'Do not guess the initially missing time. Listen for the clarification and confirmation.', 'Rate die zunächst fehlende Uhrzeit nicht. Achte auf Nachfrage und Bestätigung.'),
        phone('화요일','세 시'),phone('목요일','네 시')),
        writing('KP07',loc('일정 오해를 바로잡는 전체 채팅', 'A complete chat repairing a schedule misunderstanding', 'Vollständiger Chat zur Klärung eines Terminmissverständnisses'),
            loc('해요체로 정정·확인 요청·후속 응답을 쓰세요. 자유 글은 자동 채점되지 않아요.', 'Write a polite correction, confirmation request and follow-up response. Free writing is not automatically scored.', 'Schreibe höfliche Berichtigung, Rückfrage und Folgeantwort. Freies Schreiben wird nicht automatisch bewertet.'),
            ['동료에게 금요일이라고 잘못 전달했음. 담당자 원문은 토요일. 시각은 아직 모름. 본인이 담당자에게 물어보고 오늘 저녁 알릴 예정. 동료는 토요일 가능하지만 시각을 알아야 한다고 답함. 정정 메시지와 동료 답에 대한 응답을 쓰세요.',
             '동료에게 2층이라고 잘못 전달했음. 담당자 원문은 3층. 호실은 아직 모름. 본인이 담당자에게 물어보고 내일 오전 알릴 예정. 동료는 3층으로 가겠지만 호실을 알아야 한다고 답함. 정정 메시지와 동료 답에 대한 응답을 쓰세요.'],
            loc('내가 잘못 전달한 정보를 분명히 정정했나요? 원문에 없는 시각·호실을 추측해 쓰지 않았나요? 누가 언제 확인할지와 동료에게 답할 책임을 유지했나요? 상대의 답을 전면 합의로 늘리지 말고 다시 써 보세요.', 'Did you clearly correct your own error? Did you avoid inventing a time or room number? Preserve who checks, when, and who reports back. Rewrite without expanding the colleague’s reply into unrestricted agreement.', 'Hast du deinen eigenen Fehler klar berichtigt? Hast du keine Uhrzeit oder Raumnummer erfunden? Erhalte, wer wann nachfragt und Rückmeldung gibt. Überarbeite den Text, ohne die Antwort als uneingeschränkte Zustimmung darzustellen.'))]


def kp08():
    def drama(item,place):
        topic = '은' if (ord(item[-1])-0xAC00)%28 else '는'
        return packet(f'이 장면의 두 사람은 반말을 쓰기로 한 친구입니다.\n가: {item} 어디 있어?\n나: {place}에 놓여 있어.\n가: 아, 벌써 가져왔구나!\n나: 응. 새 회원에게는 존댓말로 알려 줘.\n가: 네, {item}{topic} {place}에 있어요. 필요하시면 사용하세요.',[
            choice('relation',loc('앞부분에서 반말을 쓴 근거는?', 'Why is casual speech used initially?', 'Warum wird anfangs vertraulich gesprochen?'),['반말에 합의한 친구 사이','처음 만난 모든 사람에게 반말을 씀'],loc('장면이 관계와 합의를 명시해요. 모든 사람에게 일반화하지 않아요.', 'The scene specifies the relationship and agreement; do not generalize it to everyone.', 'Die Szene nennt Beziehung und Vereinbarung. Verallgemeinere das nicht auf alle Personen.')),
            choice('reaction',loc('가져왔구나는 무엇을 나타내나요?', 'What does 가져왔구나 express?', 'Was drückt 가져왔구나 aus?'),['이미 가져온 것을 새로 알아차림','앞으로 가져오라는 명령'],loc('벌써와 -구나는 새로 알아차린 반응이에요.', '벌써 and -구나 signal realization, not an instruction.', '벌써 und -구나 signalisieren eine Erkenntnis, keine Anweisung.')),
            choice('audience',loc('마지막 해요체 안내의 대상은?', 'Who receives the final polite announcement?', 'An wen richtet sich der letzte höfliche Hinweis?'),['새 회원','반말에 합의한 친구만'],loc('새 회원에게 전할 때 말투를 바꿨어요.', 'The register changes for the new member.', 'Für die neue Person wird das Register gewechselt.')),
        ],'audio')
    return [task('KP08','listening:02','listening',loc('짧은 극 대사의 관계와 말투', 'Relationships and register in a short scene', 'Beziehung und Register in einer kurzen Szene'),
        loc('직접 쓴 짧은 장면이에요. 인물 표시는 읽기 안내이며 실제 성별을 추정하지 마세요. 관계, 반응, 청자 변화를 들으세요.', 'This is an original short scene. Role labels are reading cues, not evidence of gender. Listen for relationship, reaction and audience change.', 'Dies ist eine eigens verfasste kurze Szene. Rollenbezeichnungen sind Lesehilfen, keine Geschlechtsangaben. Achte auf Beziehung, Reaktion und Wechsel des Gegenübers.'),
        drama('마이크','책상 위'),drama('공책','입구 선반')),
        writing('KP08',loc('공개 게시글·댓글·친구 이메일', 'Public post, comment and email to a friend', 'Öffentlicher Beitrag, Kommentar und E-Mail'),
            loc('세 독자 상황의 전체 글을 써요. 공개 범위와 출처를 유지하고 루브릭에 맞춰 재작성하세요. 자유 글은 미채점이에요.', 'Write complete texts for three audience situations. Preserve public scope and source, then revise against the rubric. Free writing is unscored.', 'Schreibe vollständige Texte für drei Kommunikationssituationen. Erhalte Öffentlichkeit und Quelle, dann überarbeite anhand der Kriterien. Freies Schreiben bleibt unbewertet.'),
            ['담당 선생님의 안내: 금요일까지 신청서 제출.\n1. 전체 모임 회원에게 공개 게시글. 2. 회원의 토요일에 내도 돼요?라는 댓글에 답변. 예외 허가는 받지 않았고 담당자에게 확인해야 함. 3. 반말에 합의한 친구에게 제목·용건·답장 요청이 있는 이메일. 다른 회원의 개인정보는 쓰지 마세요.',
             '안내 직원의 안내: 화요일까지 활동 기록 제출.\n1. 전체 모임 회원에게 공개 게시글. 2. 회원의 수요일에 내도 돼요?라는 댓글에 답변. 예외 허가는 받지 않았고 담당자에게 확인해야 함. 3. 반말에 합의한 친구에게 제목·용건·답장 요청이 있는 이메일. 다른 회원의 개인정보는 쓰지 마세요.'],
            loc('세 글 모두 출처·기한·제출 의무가 같은가요? 댓글에서 지연 제출을 임의로 허가하지 않았나요? 공개 글은 해요체 안내, 친구 이메일은 합의된 말투로 쓰고 제목·응답 요청을 넣었나요? 개인 답장을 전체 공개하지 말고 고쳐 보세요.', 'Do all three texts preserve source, deadline and required submission? Does the comment avoid granting unauthorized late submission? Check polite public style and the agreed style, subject and reply request in the private email. Revise any exposure of private replies.', 'Bewahren alle drei Texte Quelle, Frist und Abgabepflicht? Erlaubt der Kommentar keine unbefugte verspätete Abgabe? Prüfe höflichen öffentlichen Stil sowie vereinbarte Anrede, Betreff und Antwortbitte in der privaten E-Mail. Korrigiere veröffentlichte private Antworten.'))]
