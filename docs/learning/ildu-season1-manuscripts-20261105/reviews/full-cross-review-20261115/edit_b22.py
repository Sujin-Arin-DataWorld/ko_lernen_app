"""One-time B2.2 source attribution, relationship and task corrections."""
from pathlib import Path
B=Path(__file__).resolve().parents[2]/'manuscripts'
GUARD='''**KO** 모범답과 해설을 모든 언어에서 가리고 먼저 답해요. 답이나 도움을 본 뒤의 시도는 지원 연습으로 남겨요.

**EN** Hide the model and explanations in every language before answering. Record an attempt after seeing an answer or help as supported practice.

**DE** Decke Musterantwort und Erklärungen in allen Sprachen ab, bevor du antwortest. Ein Versuch nach dem Ansehen von Antwort oder Hilfe gilt als unterstützte Übung.

'''
DETAIL='<details>\n<summary>응답 후 검토용 답안 / Review after responding / Erst nach der Antwort prüfen</summary>\n\n'
def rep(s,a,z):
 assert s.count(a)==1,(a[:100],s.count(a))
 return s.replace(a,z)
def block(s,a,z,new):
 i=s.index(a);j=s.index(z,i+len(a));return s[:i]+new+s[j:]
def save(n,s):
 p=B/f'B2.2-{n:02}.md';t=p.with_suffix('.md.tmp');t.write_text(s,encoding='utf-8',newline='');assert t.read_text(encoding='utf-8')==s;t.replace(p);print(p.name)

s=(B/'B2.2-01.md').read_text(encoding='utf-8')
s=rep(s,'Mit der Notiz kann ich schon vorbereiten','Mit der Notiz kann ich mich schon vorbereiten')
s=rep(s,'친구는 짧은 메모로나마 배치를 도와주겠다고 했어요.','친구는 짧은 메모로나마 배치를 도와줄 수 있어요.')
s=rep(s,'My friend offered to help with a brief layout note, limited though it is.','My friend can help with the layout, even if only through a brief note.')
s=rep(s,'Mein Freund bot an, zumindest mit einer kurzen Notiz bei der Anordnung zu helfen.','Eine befreundete Person kann bei der Anordnung helfen, wenn auch nur mit einer kurzen Notiz.')
h='## 8. 독립 확인 — 가능한 시간이 겹치는 곳\n\n';s=rep(s,h,h+GUARD)
s=rep(s,'답 B. A는 레나의 시작 시간,',DETAIL+'답 B. A는 레나의 시작 시간,')
s=rep(s,'## 9. 생활 전이 — 벽 한 면과 작품 사진','</details>\n\n## 9. 생활 전이 — 벽 한 면과 작품 사진')
save(1,s)

s=(B/'B2.2-02.md').read_text(encoding='utf-8')
s=rep(s,'Christians geliehenes Stativ muss unabhängig vom Ausflug am Freitag zurück.','Das Stativ, das Daniel sich von Christian geliehen hat, muss unabhängig vom Ausflug am Freitag zurückgegeben werden.')
s=rep(s,'여행 취소와 반환을 구별하는 한 문장을 쓴다.','카메라를 빌린 친구의 입장에서, 소유자인 당신에게 여행 취소 가능성과 반환 약속을 구별하는 한 문장을 쓴다.')
s=rep(s,'A friend cancels a weekend trip but promised to return your camera Monday. Separate the two:','Your friend has promised to return your camera on Monday even if the weekend trip is cancelled. Write one sentence from your friend’s perspective separating possible cancellation from the return commitment. Model:')
s=rep(s,'Eine Freundin sagt die Wochenendreise ab, hat aber die Kamerarückgabe für Montag zugesagt.','Eine befreundete Person hat dir die Rückgabe deiner Kamera für Montag zugesagt, auch wenn die Wochenendreise abgesagt wird. Schreibe aus ihrer Rolle an dich als Eigentümer oder Eigentümerin und trenne mögliche Absage und zugesagte Rückgabe. Modell:')
s=rep(s,'Joy tilts his head:','Joy tilts their head:')
s=rep(s,'## 8. 독립 확인과 생활 전이\n\n','## 8. 독립 확인과 생활 전이\n\n'+GUARD)
s=block(s,'**독립 확인:** 다음 중 자료에 맞는 문장은?','**전이 과제:**', '''**독립 확인:** 다음 중 자료에 맞는 문장은? / Which statement fits the material? / Welche Aussage passt zu den Angaben?

- A. 요리를 취소한다면 반환도 취소된다. / Cancelling the cooking also cancels the return. / Wird das Kochen abgesagt, entfällt auch die Rückgabe.
- B. 요리를 취소하더라도 냄비는 약속대로 돌려준다. / Even if the cooking is cancelled, the pot will be returned as agreed. / Auch bei einer Absage des Kochens wird der Topf wie vereinbart zurückgegeben.
- C. 주인이 집에 없는 한 현관 밖에 둔다. / Leave it outside as long as the owner is not home. / Solange die besitzende Person nicht zu Hause ist, den Topf vor der Tür abstellen.

'''+DETAIL+'''답 B. A는 서로 다른 약속을 합치고, C는 소유자가 명시한 요청에 어긋난다. / Answer B. A combines two separate commitments; C conflicts with the owner’s explicit request. / Antwort B. A vermischt zwei getrennte Zusagen; C widerspricht dem ausdrücklichen Wunsch der besitzenden Person.

</details>

''')
save(2,s)

s=(B/'B2.2-03.md').read_text(encoding='utf-8')
s=rep(s,'Ich habe die Zeit verpasst','Ich habe die Uhrzeit nicht mitbekommen')
s=rep(s,'I missed the time','I didn’t catch the time')
s=rep(s,'Sie fragte nach dem Grund fürs Hinaustragen, nicht nach einer Absage.','Sie fragte nur, warum er mit der Tasche hinausgehen wollte; sie forderte ihn nicht auf, abzusagen.')
s=rep(s,'Morgen wäre einfach eine kurze Tasse Tee zusammen schön.','Morgen wäre es einfach schön, kurz zusammen eine Tasse Tee zu trinken.')
s=rep(s,'모델 두 문장:','모델 세 문장:')
s=rep(s,'### 나. 상대의 의도를 확인하기', '### 나. 상대의 의도를 확인하기') if '### 나. 상대의 의도를 확인하기' in s else s
# Insert a distinct confirmation-function turn before the next expression group.
i=s.index('### 나.',s.index('### 가.'))
extra='''**새 확인 질문 한 차례:** 위 민호의 문자를 바탕으로, `-는다니`를 써서 전달받은 내용이 뜻하는 바를 확인하는 질문을 한 문장 더 쓴다. 놀라움이나 추궁보다 정확한 뜻 확인에 초점을 두고, 먼저 답을 가린다.

**EN** Add one question with `-는다니` to check what Minho’s message above means. Focus on clarification rather than surprise or accusation; hide the model first.

**DE** Ergänze eine Frage mit `-는다니`, um zu klären, was Minhos Nachricht bedeutet. Im Vordergrund steht die Klärung, nicht Überraschung oder Vorwurf. Decke das Muster zuerst ab.

'''+DETAIL+'''금요일에는 못 만난다니, 토요일 오후에는 만날 수 있다는 말인가요? / You say Friday does not work; does that mean we can meet on Saturday afternoon? / Du sagst, Freitag geht nicht; heißt das, dass wir uns am Samstagnachmittag treffen können?

민호의 실제 답을 기다린다. 이 질문 자체를 새 시각에 대한 합의로 기록하지 않는다. / Wait for Minho’s answer; the question itself is not an agreement to a new time. / Warte auf Minhos Antwort; die Frage selbst ist noch keine Vereinbarung eines neuen Termins.

</details>

'''
s=s[:i]+extra+s[i:]
h='## 8. 새 자료로 독립 확인과 전이\n\n';s=rep(s,h,h+GUARD)
s=block(s,'**독립 확인:** 공연 시작을 2시 30분이라고','열린 기준:', '''**독립 확인:** 공연 시작을 2시 30분이라고 요약해도 되는가? / May you report a 2:30 show start? / Darfst du halb drei als Beginn der Vorstellung angeben?

'''+DETAIL+'''아니요. 3시가 공연 시작이며 2시 30분은 현아가 기다리기 시작할 시각이다. 준의 전달과 원래 메시지를 대조해 행동을 구별한다. / No. The show starts at three; Hyuna will start waiting at two thirty. Compare Jun’s relay with the original message and keep the actions separate. / Nein. Die Vorstellung beginnt um drei; Hyuna wird ab halb drei warten. Vergleiche Juns Wiedergabe mit der ursprünglichen Nachricht und trenne die Handlungen.

</details>

**전이:** 현아에게 3–4문장의 확인 메시지를 쓴다. 준에게 들은 내용, 원래 메시지, 직접 본 입구, 필요한 질문을 구별한다. / Write Hyuna three or four sentences distinguishing Jun’s report, the original message, your observation and the question. / Schreibe Hyuna drei bis vier Sätze und trenne Juns Bericht, die ursprüngliche Nachricht, deine Beobachtung und die Frage.

'''+DETAIL+'''**모델:** “준에게 두 시 반에 오신다고 들었는데, 원래 메시지에는 그때부터 입구에서 기다리신다고 되어 있네요. 공연은 세 시에 시작하는 거죠? 제가 어제 가 보니 입구가 두 개더군요. 어느 입구에서 만날까요?”

**EN** “Jun told me you were coming at two thirty, but your original message says you will be waiting at the entrance from then. The show starts at three, right? I visited yesterday and noticed two entrances. Which entrance shall we meet at?”

**DE** „Jun sagte mir, du kommst um halb drei; in deiner ursprünglichen Nachricht steht aber, dass du ab dann am Eingang wartest. Die Vorstellung beginnt um drei, richtig? Gestern habe ich dort zwei Eingänge gesehen. An welchem treffen wir uns?“

</details>

''')
save(3,s)

s=(B/'B2.2-04.md').read_text(encoding='utf-8')
s=rep(s,'Ich dachte, Jun organisiert die Veranstaltung. Laut Einladung ist es Hyuna. Ich habe das falsch weitergegeben und werde es auch bei meiner befreundeten Person berichtigen.','Ich dachte, Jun organisiere die Veranstaltung, doch laut Einladung ist es Hyuna. Ich habe das falsch weitererzählt und werde es gegenüber der Person, der ich davon erzählt habe, richtigstellen.')
s=rep(s,'**독립 확인 / Independent check / Ohne Hilfe:**',GUARD+'**독립 확인 / Independent check / Ohne Hilfe:**')
s=rep(s,'**답안 예:**',DETAIL+'**답안 예:**')
s=rep(s,'**생활 전이:** 실제 개인 정보 대신','</details>\n\n**생활 전이:** 실제 개인 정보 대신')
save(4,s)

s=(B/'B2.2-05.md').read_text(encoding='utf-8')
s=rep(s,'Heute ist nur eure Durchsicht zu zweit erlaubt.','Heute ist nur Ihre Durchsicht zu zweit erlaubt.')
s=rep(s,'Ich schicke die Fassung mit Datum und Ort und warte vor dem Posten auf Ihre Antwort.','Ich schicke dir die Fassung mit Datum und Ort und warte vor dem Posten auf deine Antwort.')
s=rep(s,'Die Originalaufnahme dürfen Sie weiterhin privat aufbewahren.','Die Originalaufnahme darfst du weiterhin privat aufbewahren.')
s=rep(s,'Danke für den Hinweis. Vielleicht fiel es Ihnen schwer, die Meinung zu ändern.','Danke, dass du es mir gesagt hast. Vielleicht war es nicht leicht für dich, das noch einmal anzusprechen.')
s=rep(s,'Thank you for telling me; changing your mind may have felt difficult.','Thank you for telling me; it may have been difficult to bring it up again.')
save(5,s)

s=(B/'B2.2-06.md').read_text(encoding='utf-8')
s=rep(s,'Intern: „Wer sie zuerst benutzt hat, ist noch offen. Maya prüft am Freitag die früheren Ausleihunterlagen.“','Intern: „Wer sie zuerst benutzt hat, ist noch offen; Maya prüft am Freitag die früheren Ausleihunterlagen.“')
s=rep(s,'Bitte halten Sie auch fest, dass ich keine öffentliche Weitergabe möchte.','Bitte halte auch fest, dass ich keine öffentliche Weitergabe möchte.')
s=block(s,'**독립 자료:** 모임 시작 19시만 합의했다.','**전이 자료:**',GUARD+'''**독립 자료:** 모임 시작 19시만 합의했다. 마야는 30분, 레나는 20분을 원한다. 내일 각자 가능한 종료 시각을 보내기로 했다. “19시부터 30분”이라는 공지를 바로잡는다.

**EN** The only agreement is a 19:00 start. Maya wants 30 minutes; Lena wants 20. Both will message tomorrow with an end time that works for them. Correct “30 minutes from 19:00.”

**DE** Vereinbart ist nur der Beginn um 19 Uhr. Maya möchte 30 Minuten, Lena 20. Beide teilen morgen mit, bis wann sie Zeit haben. Berichtige „Ab 19 Uhr, 30 Minuten“.

'''+DETAIL+'''“시작은 19시입니다. 모임 길이는 아직 정하지 않았어요. 두 사람이 내일 가능한 종료 시각을 보내기로 했어요.” / “We’ll start at 19:00. We haven’t agreed how long to meet. Both will message tomorrow with an end time that works for them.” / „Wir beginnen um 19 Uhr. Wie lange das Treffen dauert, ist noch offen. Beide teilen morgen mit, bis wann sie Zeit haben.“

</details>

''')
save(6,s)
