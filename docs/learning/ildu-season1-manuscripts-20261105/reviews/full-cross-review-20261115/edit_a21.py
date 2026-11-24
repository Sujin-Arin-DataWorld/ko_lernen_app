"""One-time, source-checked A2.1 editorial corrections (no runtime writes)."""
from pathlib import Path

B = Path(__file__).resolve().parents[2]/'manuscripts'
GUARD = '''**KO** 앞의 시범과 아래 KO·EN·DE 답안·번역은 가려요. 새 자료와 과제만 보고 먼저 답해요. 도움을 열면 도움받은 수행으로 기록해요.

**EN** Hide the earlier models and the KO/EN/DE answers and translations below. Respond first using only the new material and prompts. Opening help makes this a supported attempt.

**DE** Decke die bisherigen Vorbilder sowie die folgenden KO/EN/DE-Antworten und Übersetzungen ab. Antworte zuerst nur anhand des neuen Materials und der Aufgaben. Mit geöffneter Hilfe zählt der Versuch als gestützt.

'''
DETAIL = '<details>\n<summary>응답 후 검토용 답안 / Review after responding / Erst nach der Antwort prüfen</summary>\n\n'

def rep(s,a,z):
    assert s.count(a)==1,(a[:100],s.count(a))
    return s.replace(a,z)

def section(s,a,z,new):
    i=s.index(a); j=s.index(z,i+len(a))
    return s[:i]+new+s[j:]

def save(n,s):
    p=B/f'A2.1-{n:02}.md'; t=p.with_suffix('.md.tmp')
    t.write_text(s,encoding='utf-8',newline='')
    assert t.read_text(encoding='utf-8')==s
    t.replace(p); print(p.name)

s=(B/'A2.1-01.md').read_text(encoding='utf-8')
s=rep(s,'## 모형을 덮고 확인하기 · 생활로 옮기기\n\n','## 모형을 덮고 확인하기 · 생활로 옮기기\n\n'+GUARD)
s=section(s,'1. `-(으)면`으로 조건을 말해요.','생활 전이에서는', '''**추가 자료 / Additional fact / Weitere Angabe:** 변경 문의는 직접 방문하거나 전화로 할 수 있어요. / You can enquire about a change in person or by phone. / Eine Änderung kannst du persönlich oder telefonisch anfragen.

1. `-(으)면`으로 일요일 오전으로 바꾸고 싶은 조건을 말해요. / Use `-(으)면` to state your conditional wish to change to Sunday morning. / Formuliere deinen Wunsch nach Sonntagvormittag als Bedingung mit `-(으)면`.
2. 담당자가 제시한 두 날짜를 `(이)나`로 묶어 말해요. 가능한 시간대가 다른 점을 확인해요. / Link the two offered days with `(이)나`; note their different available times. / Verbinde die beiden angebotenen Tage mit `(이)나`; beachte die unterschiedlichen Tageszeiten.
3. 변경을 문의할 두 방법을 `-거나`로 말해요. / Use `-거나` to name the two ways to enquire about changing the booking. / Nenne die beiden Möglichkeiten für die Änderungsanfrage mit `-거나`.
4. 마지막 확인 뒤 `-기로 하다`로 정리해요. / After confirmation, use `-기로 하다` to report the agreement. / Fasse nach der Bestätigung mit `-기로 하다` zusammen, was vereinbart wurde.

'''+DETAIL+'''1. 일요일 오전에 자리가 있으면 바꾸고 싶어요. / If a place is available on Sunday morning, I’d like to change it. / Wenn am Sonntagvormittag ein Platz frei ist, möchte ich verschieben.
2. 일요일이나 월요일. 단, 가능한 시간대는 서로 달라요. / Sunday or Monday; the available times differ. / Sonntag oder Montag; die freien Tageszeiten unterscheiden sich.
3. 직접 가거나 전화로 물어볼 수 있어요. / I can ask in person or by phone. / Ich kann persönlich oder telefonisch nachfragen.
4. 일요일 오전 열한 시로 바꾸기로 했어요. / We agreed to change it to Sunday at eleven. / Wir haben vereinbart, auf Sonntag um elf zu verschieben.

금요일 오후와 월요일 오후는 내 오전 가능 조건에 맞지 않아요. 위 답과 뜻이 같은 자연스러운 표현도 받아들여요. / Friday and Monday afternoon do not fit your morning-only availability. Accept natural wording with the same meaning. / Freitag- und Montagnachmittag passen nicht zu deiner Verfügbarkeit am Vormittag. Andere natürliche Formulierungen mit derselben Bedeutung sind ebenfalls möglich.

</details>

''')
save(1,s)

s=(B/'A2.1-02.md').read_text(encoding='utf-8')
s=rep(s,'Joy straightens his own little hat','Joy adjusts the little hat')
s=rep(s,'do not replace his hat','do not replace Joy’s own hat')
save(2,s)

s=(B/'A2.1-03.md').read_text(encoding='utf-8')
old='**지원 연습:** 15:00·15:20·15:40에 출발해요. 민호가 표를 줬어요. 두 정보를 말해요.'
s=rep(s,old,old+'''

**EN — Supported practice:** Departures are at 15:00, 15:20 and 15:40. Minho gave you the timetable. State both the interval and who gave it to you.

**DE — Übung mit Hilfe:** Die Abfahrten sind um 15:00, 15:20 und 15:40 Uhr. Minho hat dir den Fahrplan gegeben. Nenne den Zeitabstand und die Person, von der du den Plan bekommen hast.''')
s=rep(s,'## 새 시간표로 독립 확인\n\n','''### 새 숫자 준비 / Prepare the new numbers / Neue Zahlen vorbereiten

**KO** 40분은 사십 분, 45분은 사십오 분이에요. 1:45 시계를 보고 “한 시 사십오 분”이라고 말해 봐요. 이 도움을 확인한 뒤 새 시간표로 가요. 이 준비를 건너뛰었다면 숫자를 짚어 시간 이해를 확인할 수 있어요. 사십오를 말하지 못한 것만으로 `마다`나 출처 표현을 틀렸다고 보지는 않아요.

**EN** 40 minutes is 사십 분; 45 minutes is 사십오 분. Practise 1:45 as “한 시 사십오 분”, then move to the new timetable. If you skip this preparation, point to the time to show understanding; difficulty saying 사십오 alone is not a failure of `마다` or the source expression.

**DE** 40 Minuten heißen 사십 분, 45 Minuten 사십오 분. Übe 1:45 als „한 시 사십오 분“ und gehe danach zum neuen Fahrplan. Überspringst du die Vorbereitung, kannst du dein Zeitverständnis durch Zeigen prüfen lassen. Schwierigkeiten mit 사십오 allein bedeuten keinen Fehler bei `마다` oder der Quellenangabe.

## 새 시간표로 독립 확인

'''+GUARD)
old='**과제:** 다음 출발·도착을 말하고, 간격에는 `마다`, 전달자에는 `한테서`를 써요. 이어 같은 출처를 `에게서`로도 말해 봐요.'
s=rep(s,old,old+'''

**EN — Task:** State the next departure and arrival. Use `마다` for the interval and `한테서` for the person who gave you the timetable. Then name the same source again using `에게서`.

**DE — Aufgabe:** Nenne die nächste Abfahrt und die dazugehörige Ankunft. Verwende für den Abstand `마다` und für die Person, die dir den Plan gegeben hat, `한테서`. Formuliere die letzte Angabe anschließend auch mit `에게서`.

**수용 확인:** “박물관 입구에서 민호에게로 가세요”의 만날 사람과 “도서관에서부터 박물관까지”의 출발점을 각각 찾아요. 두 형태를 외워 말할 필요는 없어요.

**EN — Recognition:** Identify whom to meet in “박물관 입구에서 민호에게로 가세요” and the starting point in “도서관에서부터 박물관까지”. You do not have to reproduce these forms.

**DE — Verstehen:** Finde in „박물관 입구에서 민호에게로 가세요“ die Person, die du treffen sollst, und in „도서관에서부터 박물관까지“ den Ausgangspunkt. Du musst diese Formen nicht selbst bilden.

'''+DETAIL)
s=section(s,'**수용 확인:** “박물관 입구에서 민호에게로 가세요”의 만날 사람은','**생활 전이:**', '''**수용 답 / Recognition answers / Lösungen zum Verstehen:** 민호 / 도서관. — Meet Minho; start at the library. — Zu Minho gehen; Ausgangspunkt ist die Bibliothek.

</details>

''')
s=rep(s,'say you will check and call back.','say you will check and get back to them.')
save(3,s)

s=(B/'A2.1-04.md').read_text(encoding='utf-8')
s=rep(s,'몰래 곶감을 먹은 뒤','몰래 홍시를 먹은 뒤')
s=rep(s,'after sneaking some dried persimmons','after secretly eating a soft ripe persimmon')
s=rep(s,'heimlich getrocknete Kakis gegessen','heimlich eine weiche, reife Kaki gegessen')
s=rep(s,'## 새 장소에서 독립 확인\n\n','## 새 장소에서 독립 확인\n\n'+GUARD)
s=rep(s,'**가능한 답:** 대기실에서 쉬어도 돼요.', '''**추가 차례 — 도움 요청 / One more turn: ask for help / Noch ein Gesprächsschritt: um Hilfe bitten**

이번 역할은 앞치마를 입을 때 도움이 필요해요. 직원에게 도움을 요청하고 답을 기다려요. / In this role, you need help putting on the apron. Ask a staff member for help and wait for the response. / In dieser Rolle brauchst du Hilfe beim Anziehen der Schürze. Bitte das Personal um Hilfe und warte auf die Antwort.

'''+DETAIL+'**가능한 답:** 대기실에서 쉬어도 돼요.')
s=rep(s,'**생활 전이:** 새로운 장소에서', '''**도움 요청 예 / Help-request example / Beispiel für die Bitte:** “도움이 필요해요.” — “I need help.” — „Ich brauche Hilfe.“ 직원은 “네, 도와드릴게요”로 응답하고 앞치마 착용을 도와줘요. / The staff member responds, “Yes, I’ll help you,” and helps with the apron. / Die angesprochene Person antwortet: „Ja, ich helfe Ihnen“, und hilft beim Anziehen der Schürze.

“도와주세요” 같은 자연스러운 요청도 받아들여요. 필요하면 한 덩어리로 도움을 제공하고, 아직 배우지 않은 `돕다` 활용을 따로 평가하지 않아요. / Accept natural alternatives such as “도와주세요”. Offer the phrase as support if needed; do not assess an untaught conjugation of `돕다`. / Auch natürliche Bitten wie „도와주세요“ sind möglich. Biete die Wendung bei Bedarf als Hilfe an; prüfe keine noch nicht gelernte Konjugation von `돕다`.

</details>

**생활 전이:** 새로운 장소에서''')
save(4,s)

s=(B/'A2.1-05.md').read_text(encoding='utf-8')
s=rep(s,'## 다른 자료로 혼자 확인하기\n\n','''### 새 형태 준비 / Prepare a new form / Eine neue Form vorbereiten

**KO** `만들다`의 지난 행동 수식은 `만든`이에요. ㄹ은 ㄴ 앞에서 빠져요. `만든 모형`으로 연습한 뒤 새 포스터 과제로 가요. 이 도움을 새 과제 중 다시 보면 도움받은 수행으로 기록해요. ㄹ 탈락만으로 지난 일과 예정한 일을 구별하지 못했다고 판정하지 않아요.

**EN** The past-action modifier of `만들다` is `만든`: ㄹ drops before ㄴ. Practise `만든 모형` (“a model someone made”) before the new poster task. Reopening this help during the task makes the attempt supported. Difficulty with ㄹ deletion alone does not show failure to distinguish past and planned actions.

**DE** Das Attribut für eine vergangene Handlung von `만들다` lautet `만든`: ㄹ entfällt vor ㄴ. Übe `만든 모형` („ein angefertigtes Modell“) vor der neuen Plakataufgabe. Öffnest du diese Hilfe während der Aufgabe erneut, zählt der Versuch als gestützt. Schwierigkeiten allein mit dem Wegfall von ㄹ zeigen nicht, dass du vergangene und geplante Handlungen verwechselst.

## 다른 자료로 혼자 확인하기

'''+GUARD)
save(5,s)

s=(B/'A2.1-06.md').read_text(encoding='utf-8')
s=rep(s,'In Hinweisen erkennst du `께서`, `-(으)ㅁ` und `-(으)ㄹ 것` als Aufforderung.', 'In Hinweisen sollst du `께서`, `-(으)ㅁ` und die auffordernde Verwendung von `-(으)ㄹ 것` verstehen.')
s=rep(s,'Ich habe aufmerksam zugehört, was die Lehrperson gesagt hat.', 'Ich habe mir aufmerksam angehört, was die Lehrperson gesagt hat.')
s=rep(s,'## 다른 사람과 다른 공지로 확인하기\n\n','## 다른 사람과 다른 공지로 확인하기\n\n'+GUARD)
s=section(s,'1. 친구에게 선생님의 행동을 `-(으)시-`로 말해요.','**생활 전이:**', '''1. 친구에게 선생님의 행동을 `-(으)시-`로 말해요. 친구에게 자연스러운 해요체로 말해도 돼요. / Tell your friend what the teacher is doing, using `-(으)시-`. Natural polite 해요 speech to a friend is also acceptable. / Sage deiner Freundin mit `-(으)시-`, was die Lehrperson tut. Auch natürliches höfliches Sprechen im 해요-Stil ist hier möglich.
2. 직원에게 받는 사람을 `께`로 말하며 편지를 전해 달라고 부탁해요. / Ask the staff member to pass on the letter, naming the recipient with `께`. / Bitte das Personal um Weitergabe des Briefs und nenne die empfangende Person mit `께`.
3. 두 문장의 상대가 바뀌었는데, 높이는 제3자도 바뀌었나요? / Has the respected third person changed along with the listener? / Hat sich mit der angesprochenen Person auch die respektierte dritte Person geändert?

**새 공지 / New notice / Neuer Hinweis:** “담당 선생님께서 자료를 확인하십니다. 모임 시각이 3시로 바뀌었음. 들어가기 전에 이름을 적을 것.”

누가 확인하는지, 이미 바뀐 것이 무엇인지, 입장 전에 할 일은 무엇인지 답해요. 공지 문체를 외워 재현하지 않아도 돼요. / Identify the person, the completed change and the required action. You do not have to reproduce the notice style. / Nenne Person, erfolgte Änderung und verlangte Handlung. Den Hinweisstil musst du nicht selbst bilden.

<details>
<summary>공지 뜻 도움 — 열면 지원받은 읽기 / Notice translation — supported reading / Übersetzung — Lesen mit Hilfe</summary>

**EN** The responsible teacher checks the materials. The meeting time has changed to three. Write your name before entering.

**DE** Die zuständige Lehrperson prüft die Unterlagen. Die Beginnzeit wurde auf drei Uhr geändert. Vor dem Eintreten den Namen eintragen.

</details>

'''+DETAIL+'''1. 선생님이 표를 확인하세요. 친구와 반말을 쓰는 관계라면 “선생님이 표를 확인하셔”도 가능해요. / The teacher is checking the table. The familiar ending is also valid if that is how you and your friend speak. / Die Lehrperson prüft die Tabelle. Die vertraute Endung ist ebenfalls möglich, wenn ihr so miteinander sprecht.
2. 이 편지를 선생님께 전해 주세요. / Please pass this letter on to the teacher. / Geben Sie diesen Brief bitte an die Lehrperson weiter.
3. 아니요. 둘 다 선생님이에요. / No; the respected third person is still the teacher. / Nein; die respektierte dritte Person bleibt dieselbe Lehrperson.

**공지 답 / Notice answers / Antworten zum Hinweis:** 담당 선생님 / 모임 시각: 3시 / 이름 적기. — The responsible teacher / meeting time: three / write your name. — Zuständige Lehrperson / Beginn: drei Uhr / Namen eintragen.

</details>

''')
save(6,s)
