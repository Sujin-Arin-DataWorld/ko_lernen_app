"""One-time B2.1 meaning, allocation and independent-check corrections."""
from pathlib import Path
B=Path(__file__).resolve().parents[2]/'manuscripts'
GUARD='''**KO** 먼저 답과 해설을 모든 언어에서 가리고 A–C 중 하나를 고른 뒤 자료에서 근거를 찾아요. 답을 본 뒤의 시도는 지원 연습이에요.

**EN** Hide the answer and explanations in every language before choosing A–C and finding evidence in the material. An attempt after seeing the answer is supported practice.

**DE** Decke Antwort und Erklärungen in allen Sprachen ab, bevor du A–C auswählst und den Beleg im Material suchst. Nach dem Ansehen der Antwort gilt der Versuch als unterstützte Übung.

'''
DETAIL='<details>\n<summary>선택 후 답과 근거 / Answer and evidence after choosing / Antwort und Beleg nach der Auswahl</summary>\n\n'
def rep(s,a,z):
 assert s.count(a)==1,(a[:100],s.count(a))
 return s.replace(a,z)
for n in range(1,7):
 p=B/f'B2.1-{n:02}.md';s=p.read_text(encoding='utf-8')
 a=s.index('## 8.');h=s.index('\n\n',a)+2;z=s.index('\n## 9.',h)
 part=s[h:z]
 key=next(x for x in ('답은 **B**.','답 B.','**답 B:**','답 C.') if x in part)
 i=part.index(key); ending=part.find('\n\n**생활',i)
 if ending<0: ending=len(part)
 part=GUARD+part[:i]+DETAIL+part[i:ending].rstrip()+'\n\n</details>\n\n'+part[ending:].lstrip('\n')
 s=s[:h]+part.rstrip()+'\n'+s[z:]
 if n==1:
  s=rep(s,'Prüfe vor einem Anteil, wer zur Gesamtgruppe gehört.','Prüfe, wer zur Gesamtgruppe gehört, bevor du einen Anteil interpretierst.')
 if n==2:
  s=rep(s,'Bei der Vorbereitung des nächsten Treffens fragen wir freiwillig nach den Gründen für die Nichtteilnahme und geben an, wer geantwortet hat.','Bei der Vorbereitung des nächsten Treffens bitten wir um freiwillige Angaben zu den Gründen für die Nichtteilnahme und nennen den Kreis der Antwortenden.')
  s=rep(s,'Die Antworten werden nicht automatisch bewertet.','Die Antworten werden nicht benotet; die Muster zeigen mögliche Lösungen, keine abschließende Liste zulässiger Antworten.')
 if n==3:
  s=rep(s,'Immerhin bin ich erleichtert, die aufgeschobene Geräteordnung endlich erledigt zu haben.','Immerhin bin ich erleichtert, dass ich die Ausrüstung nach langem Aufschieben endlich aufgeräumt habe.')
  s=rep(s,'② 주소 확인만 끝났는데 발송·작성까지 묶었다(첫 두 발화).','② 주소 확인 완료를 발송 완료로 넓혔다(마야 첫·세 번째 발화). 새 주소 작성은 아직 진행 중이다.')
  s=rep(s,'(2) Only checking was complete, not writing or dispatch.','(2) She treated completion of the address check as completion of dispatch. The new address is still being written.')
  s=rep(s,'(2) Nur die Prüfung war abgeschlossen.','(2) Sie setzte die abgeschlossene Adressprüfung mit einem erledigten Versand gleich. Die neue Adresse wird noch geschrieben.')
 if n==4:
  s=rep(s,'freie Antworten werden nicht automatisch bewertet.','freie Antworten werden nicht benotet.')
  s=rep(s,'Antwort: „Du kannst ohne Antwort teilnehmen und die Größe vor Ort wählen.“','Antwort: „Du kannst auch ohne vorherige Antwort teilnehmen. Die Papiergröße kannst du vor Ort wählen.“')
  s=rep(s,'Belege zu zeigen ist etwas anderes, als Gefühle zu drängen.','Belege zu zeigen ist etwas anderes, als jemanden unter Druck zu setzen.')
  s=rep(s,'### 나. 출처와 결론의 이유 — 에 의하면 / -으므로 (217·218)','### 나. 규정에 따른 실행·출처·결론의 이유 — 에 의하여 / 에 의하면 / -으므로 (217·218)')
  s=rep(s,'이번 새 예의 생산 목표는 출처를 밝히는 에 의하면이며, 에 의하여는 이 대조 문맥에서 이해한다.','에 의하여로 규정에 따라 하는 행동을 직접 설명한다. 에 의하면은 정보 출처를 나타내는 대조 표현으로 함께 살펴본다.')
  s=rep(s,'The new productive task uses 에 의하면; 에 의하여 is recognised in this contrast.','The productive target is action under an explicit rule with 에 의하여. 에 의하면 is a contrasting way to identify an information source.')
  s=rep(s,'Die neue Produktionsaufgabe verwendet 에 의하면; 에 의하여 wird im Kontrast verstanden.','Mit 에 의하여 beschreibst du selbst eine Handlung nach einer ausdrücklich genannten Regel. 에 의하면 wird dazu als Ausdruck für eine Informationsquelle abgegrenzt.')
  marker='**지원:** “신청자가 30명이므로 한 번만 안내한다”'
  addition='''**규정 표현 지원:** 위의 “운영 규정에 의하여 신청 순서대로 자리를 배정한다”에서 근거 규정과 실행을 나누어 표시한다. / **Supported rule practice:** In the seating example above, mark the governing rule and the action separately. / **Übung zur Regel mit Hilfe:** Markiere im Beispiel zur Platzvergabe die zugrunde liegende Regel und die Handlung getrennt.

지원 답: 근거는 운영 규정, 실행은 신청 순서대로 자리 배정. / Supported answer: operating rules; allocating seats in application order. / Lösung mit Hilfe: die Regelung; die Platzvergabe in Anmeldereihenfolge.

**규정 표현 새 과제:** 가상 모임의 대여 규정에는 장비를 반납하기 전에 상태를 확인한다고 적혀 있다. 답을 가리고, 이 규정에 따라 하는 행동을 **에 의하여**로 한 문장 쓴다.

**EN** The fictional group’s borrowing rules require equipment to be checked before return. Hide the answer and describe that rule-based action in one Korean sentence using **에 의하여**.

**DE** Nach der Ausleihregel der fiktiven Gruppe wird der Zustand der Geräte vor der Rückgabe geprüft. Decke die Antwort ab und beschreibe diese Handlung nach der Regel in einem koreanischen Satz mit **에 의하여**.

<details>
<summary>작성 후 모델 / Model after writing / Muster nach dem Schreiben</summary>

대여 규정에 의하여 반납 전에 장비 상태를 확인합니다. / Under the borrowing rules, the equipment’s condition is checked before it is returned. / Gemäß der Ausleihregel wird der Zustand der Geräte vor der Rückgabe geprüft.

주어를 밝혀 쓴 문장도 규정과 행동을 보존하면 가능하다. 자연스러운 `에 따라`도 뜻을 전달하지만, 이번 목표인 `에 의하여`를 사용한 근거와는 구별한다. / An explicit subject is welcome if the rule and action remain intact. Natural `에 따라` also conveys the meaning; record use of the target `에 의하여` separately. / Ein ausdrücklich genanntes Subjekt ist möglich, wenn Regel und Handlung erhalten bleiben. Auch natürliches `에 따라` vermittelt die Bedeutung; halte die Verwendung der Zielform `에 의하여` gesondert fest.

</details>

'''
  s=rep(s,marker,addition+marker)
 if n==5:
  s=rep(s,'You felt pressured questioning; motives are unknown.','You felt the applicant was pressing the issue; their motives are unknown.')
  s=rep(s,'After delaying only because of cost, we applied and received the answer.','After postponing because of the cost, we completed the application and received the coordinator’s reply.')
 if n==6:
  s=rep(s,'Am Montag gibt es zwölf persönliche Anmeldungen und acht Onlinebuchungen. Teilnahme und Überschneidung sind unbekannt.','Für Montag haben sich zwölf Personen für eine Beratung vor Ort angemeldet; acht Personen haben online gebucht. Ob sie tatsächlich teilgenommen haben und ob sich die beiden Gruppen überschneiden, ist unbekannt.')
  s=rep(s,'Für Montag sind zwölf Anmeldungen für Beratung vor Ort und acht Onlinebuchungen verzeichnet. Ohne Klärung von Überschneidungen und tatsächlicher Teilnahme ergeben sich daraus keine zwanzig Teilnehmenden.','Für Montag sind zwölf Personen für eine Beratung vor Ort angemeldet; acht Personen haben online gebucht. Ohne Klärung von Überschneidungen und tatsächlicher Teilnahme lässt sich daraus keine Gesamtzahl von zwanzig Teilnehmenden ableiten.')
 t=p.with_suffix('.md.tmp');t.write_text(s,encoding='utf-8',newline='');assert t.read_text(encoding='utf-8')==s;t.replace(p);print(p.name)
