"""Apply the agreed A2.2 source, access-route and task corrections once."""
from pathlib import Path
B=Path(__file__).resolve().parents[2]/'manuscripts'
GUARD='''**KO** 앞의 시범과 아래 KO·EN·DE 답안은 가려요. 새 자료와 과제만 보고 먼저 답해요. 도움을 열면 도움받은 수행으로 기록해요.

**EN** Hide the earlier models and all KO/EN/DE answers below. Answer first from the new material and prompts only; record use of help as supported performance.

**DE** Decke die bisherigen Vorbilder und alle folgenden KO/EN/DE-Antworten ab. Antworte zuerst nur anhand des neuen Materials und der Aufgaben; mit Hilfe zählt der Versuch als gestützt.

'''
DETAIL='<details>\n<summary>응답 후 검토용 답안 / Review after responding / Erst nach der Antwort prüfen</summary>\n\n'
def rep(s,a,z):
 assert s.count(a)==1,(a[:90],s.count(a))
 return s.replace(a,z)
def save(n,s):
 p=B/f'A2.2-{n:02}.md'; t=p.with_suffix('.md.tmp'); t.write_text(s,encoding='utf-8',newline=''); assert t.read_text(encoding='utf-8')==s; t.replace(p); print(p.name)
def route(topic):
 return f'본편 조건 전에는 앞뒤 고택 장면만 건너뛰어요. ‘{topic}’부터 단어와 시범을 먼저 익힌 뒤 현대 듣기와 새 과제로 이어가요.'
EN='Before the story condition is met, skip only the opening and closing house passages. Start with the vocabulary section, learn the models, then continue to the modern conversation and new task.'
DE='Überspringe vor Erfüllung der Erzählvoraussetzung nur die Hausszenen am Anfang und Ende. Beginne beim Wortschatz, lerne die Vorbilder und gehe dann zum heutigen Gespräch und zur neuen Aufgabe weiter.'

s=(B/'A2.2-02.md').read_text(encoding='utf-8')
s=rep(s,'아직 본편에서 이 기억을 만나지 않았다면 아래 현대 열쇠 이야기부터 공부해요.',route('움직임과 변화의 단어'))
s=rep(s,'**Read after S1-E06.middle; otherwise begin with the modern key story below.** / **Lies die Hausszene nach S1-E06.middle; beginne sonst mit der heutigen Schlüsselgeschichte.**','**EN** '+EN+'\n\n**DE** '+DE)
s=rep(s,'## 새 분실 상황으로 독립 확인\n\n','## 새 분실 상황으로 독립 확인\n\n'+GUARD)
s=rep(s,'**가능한 답:** 물을 마시면서','**추가 확인:** 다른 사람이 안내문을 가져갔다고 말할 수 있나요? / Can we say someone else took the notice? / Können wir sagen, jemand anderes habe den Hinweis weggenommen?\n\n'+DETAIL+'**가능한 답:** 물을 마시면서')
s=rep(s,'**추가 확인:** 다른 사람이 안내문을 가져갔다고 말할 수 있나요? **아니요. 자기 가방에서 찾았다는 사실만 있어요.** / Can we say someone else took it? **No. We only know he found it in his own bag.** / Können wir sagen, jemand anderes habe es weggenommen? **Nein. Bekannt ist nur, dass er es in der eigenen Tasche fand.**','**추가 확인 답:** 아니요. 자기 가방에서 찾았다는 사실만 있어요. / **Answer:** No. We only know he found it in his own bag. / **Antwort:** Nein. Bekannt ist nur, dass er es in der eigenen Tasche fand.\n\n</details>')
save(2,s)

s=(B/'A2.2-03.md').read_text(encoding='utf-8')
s=rep(s,'본편에서 이 기억을 보기 전에는 아래 현대 듣기부터 시작해요. / Before this memory appears in the main story, begin with the modern conversation below. / Beginne vor dieser Erinnerung in der Haupthandlung mit dem heutigen Gespräch weiter unten.',route('마음과 대화의 단어')+' / '+EN+' / '+DE)
s=rep(s,'„Sie sind so, weil Sie jemanden hassen, oder?“','„Sie schweigen, weil Sie jemanden nicht leiden können, oder?“')
heading='## 새 자료로 확인하고 생활에 쓰기 / New material and transfer / Neues Material und Alltag\n\n'
s=rep(s,heading,heading+GUARD)
s=rep(s,'② 확인된 걱정 이유를 전달해요.', '② 잠깐 현아 역할로 바꾸어, 확인된 걱정 이유를 직접 말해요. ③부터는 다시 현아의 친구 역할이에요.')
s=rep(s,'report the stated reason for worry;', 'briefly take Hyuna’s role and state the known reason for your worry directly, then return to the friend’s role for steps 3 and 4;')
s=rep(s,'gib den genannten Grund der Sorge wieder;', 'nenne kurz in Hyunas Rolle den bekannten Grund deiner Sorge direkt und wechsle für Schritt 3 und 4 wieder in die Rolle der befreundeten Person;')
s=rep(s,'**가능한 답 / Possible answer / Mögliche Antwort:**',DETAIL+'**가능한 답 / Possible answer / Mögliche Antwort:**')
s=rep(s,'파일이 열리지 않기 때문에 걱정된다고 했어요.', '파일이 열리지 않기 때문에 걱정돼요.')
s=rep(s,'She said she was worried because the file would not open.', 'I’m worried because the file will not open.')
s=rep(s,'Sie sagte, sie mache sich Sorgen, weil die Datei nicht aufgehe.', 'Ich mache mir Sorgen, weil sich die Datei nicht öffnen lässt.')
s=rep(s,'**KO** 마지막 질문의 답은 자료에 없어요.', '</details>\n\n**KO** 마지막 질문의 답은 자료에 없어요.')
save(3,s)

s=(B/'A2.2-04.md').read_text(encoding='utf-8')
s=rep(s,'‘내일 12시, 레나 연락’','‘내일 12시까지, 레나 시간 확인 후 연락’')
s=rep(s,'“Lena’s message, noon tomorrow”','“By noon tomorrow: Lena checks her schedule and gets in touch”')
s=rep(s,'„Lenas Nachricht, morgen Mittag“','„Bis morgen Mittag: Lena prüft ihren Zeitplan und meldet sich“')
save(4,s)

s=(B/'A2.2-05.md').read_text(encoding='utf-8')
s=rep(s,'이 조건 전에는 아래 고택 장면과 마지막 고택 문단을 건너뛰고 현대 장면부터 읽어요. / Before this point, skip the house opening and ending and begin with the modern scene. / Vor diesem Erzählpunkt überspringst du Anfang und Schluss im Haus und beginnst mit der heutigen Szene.',route('상태를 말하는 단어')+' / '+EN+' / '+DE)
s=rep(s,'„Kann ich vor dem Anfang kurz etwas Wasser trinken?“','„Kann ich noch kurz etwas Wasser trinken, bevor wir anfangen?“')
s=rep(s,'도움을 보고 답한 뒤에는 다른 사진으로 혼자 다시 해 봐요.', '도움을 보고 답한 뒤에는 아래 새 카드 B로 혼자 다시 해 봐요. 카드 설명만으로 풀 수 있어요.')
s=rep(s,'After using help, try a different picture independently.', 'After using help, try new card B below independently; the written description supplies all necessary information.')
s=rep(s,'Probiere nach einer Hilfestellung ein anderes Bild allein.', 'Probiere nach einer Hilfestellung die neue Karte B unten allein; die Beschreibung enthält alle nötigen Angaben.')
s=rep(s,'## 이야기 뒤 / After the story / Nach der Geschichte','''### 혼자 확인할 새 카드 B / New independent card B / Neue Karte B zum selbstständigen Üben

'''+GUARD+'''**KO** 카페 문은 닫혀 있고 창문은 열려 있어요. 안쪽은 보이지 않아요. 직원의 설명은 아직 못 들었어요. 두 상태, 아직 확인하지 않은 추측 하나, 직원에게 할 질문을 말해요.

**EN** The café door is closed and its window is open. You cannot see inside and have not heard from staff. State both observed states, one unverified inference and a question for staff.

**DE** Die Cafétür ist geschlossen, das Fenster offen. Du kannst nicht hineinsehen und hast noch keine Auskunft des Personals. Nenne beide Zustände, eine unbestätigte Vermutung und eine Frage an das Personal.

'''+DETAIL+'''**가능한 답 / Possible answer / Mögliche Antwort:** 문이 닫혀 있어요. 창문이 열려 있어요. 아무도 없는 것 같아요. 안에 누구 계세요? / The door is closed. The window is open. It seems nobody is there. Is anyone inside? / Die Tür ist geschlossen. Das Fenster ist offen. Es scheint niemand da zu sein. Ist jemand drinnen?

아무도 없다는 것은 이 자료만으로 확정할 수 없어요. 다른 그럴듯한 추측도 미확인임을 드러내면 가능하고, “지금 들어가도 돼요?”처럼 이용 허가를 물어도 돼요. / The material does not establish that nobody is there. Accept other plausible, explicitly tentative readings and questions such as “May I come in now?” / Die Angaben belegen nicht, dass niemand da ist. Andere plausible, ausdrücklich vorläufige Vermutungen und Fragen wie „Darf ich jetzt hineinkommen?“ sind ebenfalls möglich.

</details>

## 이야기 뒤 / After the story / Nach der Geschichte''')
save(5,s)

s=(B/'A2.2-06.md').read_text(encoding='utf-8')
h='## 독립 확인과 생활 전이 / Independent task and transfer / Selbstständige Aufgabe und Alltag\n\n'
s=rep(s,h,h+GUARD)
s=rep(s,'**모범 / Model / Muster:** 제 가방이 아니에요.',DETAIL+'**모범 / Model / Muster:** 제 가방이 아니에요.')
s=rep(s,'**KO** ‘내일까지 기다릴 수밖에 없어요’', '</details>\n\n**KO** ‘내일까지 기다릴 수밖에 없어요’')
s=rep(s,'**새 상황 / New situation / Neue Situation:** 오늘 현장 접수는 끝났어요.', '''### 부탁을 거절하는 차례 / Decline a request / Eine Bitte ablehnen

**KO** 친구가 “이 가방을 오늘 써도 돼요?”라고 물어요. 마야는 다른 사람에게 빌려줘도 된다고 말하지 않았고, 나는 오늘 가방을 돌려줘야 해요. 이유를 짧게 말하며 부탁을 거절해요. 위 가방의 주인이나 반환 시간은 바뀌지 않아요.

**EN** A friend asks, “May I use this bag today?” Maya has not given permission to lend it to someone else, and you must return it today. Decline with a brief reason. The bag’s owner and return appointment remain the same.

**DE** Eine befreundete Person fragt: „Darf ich die Tasche heute benutzen?“ Maya hat keine Erlaubnis zum Weiterverleihen gegeben, und du musst sie heute zurückgeben. Lehne mit einer kurzen Begründung ab. Eigentümerin und Rückgabetermin bleiben gleich.

'''+DETAIL+'''미안해요. 제 가방이 아니어서 빌려줄 수 없어요. 오늘 마야 씨에게 돌려줘야 해요. / Sorry, it isn’t my bag, so I can’t lend it to you. I have to return it to Maya today. / Tut mir leid, die Tasche gehört mir nicht, deshalb kann ich sie dir nicht leihen. Ich muss sie Maya heute zurückgeben.

같은 뜻의 더 짧은 공손한 거절도 받아들여요. / Accept a shorter polite refusal with the same meaning. / Eine kürzere höfliche Absage mit derselben Bedeutung ist ebenfalls möglich.

</details>

**새 상황 / New situation / Neue Situation:** 오늘 현장 접수는 끝났어요.''')
save(6,s)
