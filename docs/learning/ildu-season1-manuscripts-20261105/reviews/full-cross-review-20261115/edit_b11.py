"""One-time B1.1 editorial corrections after all three initial reads."""
from pathlib import Path
B=Path(__file__).resolve().parents[2]/'manuscripts'
def rep(s,a,z):
 assert s.count(a)==1,(a[:100],s.count(a))
 return s.replace(a,z)
def save(n,s):
 p=B/f'B1.1-{n:02}.md';t=p.with_suffix('.md.tmp');t.write_text(s,encoding='utf-8',newline='');assert t.read_text(encoding='utf-8')==s;t.replace(p);print(p.name)
s=(B/'B1.1-02.md').read_text(encoding='utf-8')
s=rep(s,'Sie hat die geplante Kiste noch nicht zugebunden.','Sie hat die Kiste noch nicht zugebunden, obwohl sie das vorhatte.')
save(2,s)
s=(B/'B1.1-03.md').read_text(encoding='utf-8')
s=rep(s,'I was sorting photos and missed the call.','I couldn’t answer the call because I was busy sorting photos.')
s=rep(s,'I missed your call while sorting the notices.','I couldn’t answer your call because I was busy sorting the notices.')
s=rep(s,'Two sheets got wet.','Unfortunately, two sheets ended up getting wet.')
s=rep(s,'While cleaning a windowsill','While cleaning a shelf by the window')
s=rep(s,'Beim Putzen der Fensterbank','Beim Abwischen des Regals am Fenster')
save(3,s)
s=(B/'B1.1-05.md').read_text(encoding='utf-8')
s=rep(s,'Soll ich große Karten schreiben, damit man die Sachen leichter findet?','Soll ich die Angaben auf große Karten schreiben, damit man die Sachen leichter findet?')
save(5,s)
s=(B/'B1.1-06.md').read_text(encoding='utf-8')
s=rep(s,'답을 가리고 **-으려면**과 **-어야**로 출발 마감 시각을 설명해요.','답을 가리고 ① **-으려면**으로 만남을 위한 출발 시각을 말해요. ② 같은 사실을 **-어야** 뒤에 가능한 결과를 이어서 말해요.')
s=rep(s,'Cover the model and use -으려면 and -어야 to state the latest departure time.','Cover the models. First use -으려면 to state when to leave for the meeting. Then express the same facts using -어야 followed by the result that becomes possible.')
s=rep(s,'Decke das Muster ab und nenne mit -으려면 und -어야 die späteste Abfahrtszeit.','Decke die Muster ab. Nenne zuerst mit -으려면 die nötige Abfahrtszeit. Drücke danach dieselben Angaben mit -어야 und dem dadurch möglichen Ergebnis aus.')
old='**가능한 답 / Possible answer / Mögliche Antwort:** 내일 열두 시에 만나려면 늦어도 열한 시 이십 분에는 출발해야 해요. / To meet at noon tomorrow, I have to leave by eleven twenty at the latest. / Damit wir uns morgen um zwölf treffen können, muss ich spätestens um elf Uhr zwanzig losgehen.'
s=rep(s,old,'''<details>
<summary>응답 후 검토용 답안 / Review after responding / Erst nach der Antwort prüfen</summary>

**① 가능한 답 / Possible answer / Mögliche Antwort:** 내일 열두 시에 만나려면 늦어도 열한 시 이십 분에는 출발해야 해요. / To meet at noon tomorrow, I have to leave by eleven twenty at the latest. / Damit wir uns morgen um zwölf treffen können, muss ich spätestens um elf Uhr zwanzig losgehen.

**② 가능한 답 / Possible answer / Mögliche Antwort:** 늦어도 열한 시 이십 분에는 출발해야 열두 시에 역에 도착할 수 있어요. / I need to leave by eleven twenty at the latest to be able to reach the station at noon. / Nur wenn ich spätestens um elf Uhr zwanzig losfahre, kann ich um zwölf am Bahnhof sein.

①의 `출발해야 해요`는 의무를 나타내는 유효한 계획이에요. 새 연결 표현 `-어야` 뒤에 결과를 붙이는지는 ②에서 따로 확인해요. / The obligation in answer 1 states a valid plan. Check the new condition-to-result connection separately in answer 2. / Die Pflichtform in Antwort 1 ergibt einen passenden Plan. Die neue Verbindung von Voraussetzung und Ergebnis wird gesondert in Antwort 2 geprüft.

</details>''')
save(6,s)
