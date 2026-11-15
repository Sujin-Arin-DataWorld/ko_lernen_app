"""One-time C1.1 source, mediation and independent-task corrections."""
from pathlib import Path
B=Path(__file__).resolve().parents[2]/'manuscripts'
GUARD='''**KO** 답과 해설을 모든 언어에서 가리고 문제와 자료만 보고 먼저 답해요. 답이나 도움을 본 뒤의 시도는 지원 연습으로 남겨요.

**EN** Hide answers and explanations in every language, and answer from the prompt and materials first. Record attempts after viewing answers or help as supported practice.

**DE** Decke Antworten und Erklärungen in allen Sprachen ab und antworte zuerst nur anhand von Aufgabe und Material. Versuche nach dem Ansehen von Antwort oder Hilfe gelten als unterstützte Übung.

'''
DETAIL='<details>\n<summary>응답 후 검토용 답안 / Review after responding / Erst nach der Antwort prüfen</summary>\n\n'
tasks={
1:('''**독립 자료:** 재생 210회(반복 포함). 등록자 80명 중 32명이 응답했고 그중 24명이 자막을 썼다. 인터뷰 3명은 그 32명에 포함되며 모두 자막이 도움 됐다고 말했다. 성과 측정은 없다. 비율과 인터뷰의 범위를 두 문장으로 설명한다.

**EN** There were 210 plays, including repeats. Of 80 registrants, 32 responded and 24 of those used captions. Three interviewees belong to those 32 respondents and all found captions helpful. No learning outcomes were measured. Explain the scope of the percentage and interviews in two sentences.

**DE** Es gab 210 Wiedergaben einschließlich Wiederholungen. Von 80 Angemeldeten antworteten 32; 24 davon nutzten Untertitel. Die drei Interviewten gehören zu diesen 32 und fanden alle die Untertitel hilfreich. Lernerfolg wurde nicht gemessen. Erläutere den Geltungsbereich von Anteil und Interviews in zwei Sätzen.

''','''**가능한 답:** 75%는 응답자 32명 가운데 자막을 쓴 24명의 비율이며 등록자 전체나 재생 수를 기준으로 하지 않습니다. 인터뷰의 세 사람도 그 응답자에 포함되므로 표본에 더할 수 없고, 도움 됐다는 의견은 학습 성과를 입증하지 않습니다.

**EN** The 75% refers to the 24 caption users among 32 respondents, not to all registrants or plays. The three interviewees are already among those respondents, so they cannot be added to the sample, and their reports of helpfulness do not establish a learning gain.

**DE** Die 75 Prozent beziehen sich auf die 24 Untertitelnutzenden unter den 32 Antwortenden, nicht auf alle Angemeldeten oder Wiedergaben. Die drei Interviewten gehören bereits zu diesen Antwortenden und vergrößern die Stichprobe daher nicht; ihre Einschätzung der Hilfe belegt keinen Lernerfolg.
'''),
2:('''**독립 자료:** 금요일 17시 수진이 안내를 게시했다. 현아: “제 초안에는 토요일 시간이 있었어요. 최종본은 못 봤어요.” 마야는 게시본에 토요일 시간이 없음을 보았지만 삭제 이유는 모른다. ‘수진이 실수로 토요일 시간을 삭제했다’를 고쳐 세 문장으로 보고한다.

**EN** Sujin posted the notice Friday at 17:00. Hyuna says her draft included Saturday hours but she has not seen the final version. Maya sees that the posted notice lacks those hours; the reason is unknown. Correct the claim that Sujin accidentally deleted them in a three-sentence report.

**DE** Sujin veröffentlichte den Hinweis am Freitag um 17 Uhr. Hyuna sagt, ihr Entwurf habe Samstagszeiten enthalten; die Endfassung hat sie nicht gesehen. Maya sieht, dass diese Zeiten im Aushang fehlen, kennt aber den Grund nicht. Berichtige die Behauptung, Sujin habe sie versehentlich gelöscht, in einem Bericht mit drei Sätzen.

''','''수진은 금요일 17시에 안내를 게시했다. 현아는 자신의 초안에 토요일 시간이 있었다고 했으며, 마야가 본 게시본에는 그 시간이 없다. 누가 어떤 이유로 뺐는지는 확인되지 않았다.

Sujin posted the notice on Friday at 17:00. Hyuna says her draft contained Saturday hours, whereas the posted version Maya saw does not. Who removed them and why remain unconfirmed.

Sujin veröffentlichte den Hinweis am Freitag um 17 Uhr. Laut Hyuna enthielt ihr Entwurf Samstagszeiten, während sie in der von Maya gesehenen veröffentlichten Fassung fehlen. Wer sie aus welchem Grund entfernte, ist ungeklärt.
'''),
3:('''**독립 자료·과제:** 안내를 읽은 응답자 12명 중 10명이 절차가 명확하다고 했다. 비독자와의 비교와 예약 성공 측정은 없다. 강한 주장 “예약 성공을 높였다”와 약한 주장 “아무 정보도 없다”를 각각 고친다.

**EN** Ten of twelve respondents who read the instructions found the procedure clear. There was no comparison with non-readers or measurement of booking success. Correct both “It increased booking success” and “We know nothing.”

**DE** Zehn von zwölf Antwortenden fanden den Ablauf nach der Lektüre klar. Es gab weder einen Vergleich mit Nichtlesenden noch eine Messung erfolgreicher Buchungen. Berichtige sowohl „Es erhöhte den Buchungserfolg“ als auch „Wir wissen nichts“.

''','''응답자 10명이 절차가 명확하다고 평가했다. 실제 예약 성공 증가 여부는 측정하지 않았다. / Ten respondents found the procedure clear. Whether actual booking success increased was not measured. / Zehn Antwortende fanden den Ablauf klar. Ob tatsächlich mehr Buchungen erfolgreich waren, wurde nicht gemessen.
'''),
4:('''**독립 자료:** 응답자 40명 중 26명이 18시 강좌를 선호했고 60명은 응답하지 않았다. 강사는 18–19시 가능하며 장소는 다음 달 첫 수요일만 가능하다. 반복 예약은 미확인이다. 운영자에게 첫 시험안을 세 문장으로 쓴다.

**EN** Of 40 respondents, 26 prefer a 6 p.m. class; 60 people did not respond. The instructor can teach from six to seven, and the venue is available only on the first Wednesday of next month. A recurring booking has not been checked. Write a three-sentence trial proposal for the operator.

**DE** 26 von 40 Antwortenden bevorzugen einen Kurs um 18 Uhr; 60 Personen antworteten nicht. Die Kursleitung kann von 18 bis 19 Uhr, der Raum ist im nächsten Monat nur am ersten Mittwoch frei. Weitere Termine wurden noch nicht geprüft. Schreibe der Betriebsleitung einen Vorschlag in drei Sätzen.

''','''다음 달 첫 수요일 18시부터 19시까지 한 번 시험 운영을 제안합니다. 18시를 선호한 사람은 응답자 40명 가운데 26명입니다. 정기 개최는 장소의 반복 이용 가능성을 확인한 뒤 논의하겠습니다.

Let’s run one trial from six to seven on the first Wednesday next month. Twenty-six of the forty respondents chose six. Let’s check recurring venue availability before discussing regular sessions.

Testen wir den Kurs einmal am ersten Mittwoch des nächsten Monats von 18 bis 19 Uhr. 26 der 40 Antwortenden haben 18 Uhr gewählt. Bevor wir regelmäßige Termine besprechen, müssen wir die wiederholte Verfügbarkeit des Raums klären.
'''),
5:('''**독립 자료:** 이 가상 수리 공방의 ‘접수 완료’는 물건을 받고 신청 내용을 등록한 상태다. ‘수리 완료’는 약속한 수리와 확인을 끝낸 상태다. 오늘 접수표만 발급됐고 점검 전이다. “수리 완료”라는 문자를 고치고 질문 하나를 쓴다.

**EN** In this fictional repair shop, “Received” means the item and request were logged. “Repaired” means the agreed work and final check are complete. Today only a receipt was issued; the initial inspection is pending. Correct the “Repaired” text and add one question.

**DE** In dieser fiktiven Werkstatt bedeutet „Annahme abgeschlossen“, dass Gegenstand und Auftrag erfasst wurden. „Reparatur abgeschlossen“ setzt die vereinbarte Reparatur und Abschlussprüfung voraus. Heute wurde nur ein Annahmebeleg ausgestellt; die Erstprüfung steht noch aus. Berichtige die Nachricht „Reparatur abgeschlossen“ und ergänze eine Frage.

''','''접수는 완료됐지만 점검과 수리는 아직입니다. 점검 결과는 언제 알려 주시나요? / You have received the item, but inspection and repair are still pending. When will you tell me what the inspection found? / Der Gegenstand ist erfasst, aber Prüfung und Reparatur stehen noch aus. Wann erfahre ich das Ergebnis der Prüfung?
'''),
6:('''**독립 자료:** 현장 질문은 첫날 10건에서 둘째 날 4건으로, 온라인 질문은 2건에서 9건으로 바뀌었다. 방문자 수와 중복 질문자는 미상이다. 이 자료에는 이해도 결과가 없다. “새 안내로 이해가 좋아진 거죠?”라는 질문에 답한다.

**EN** On-site questions fell from ten on day one to four on day two; online questions rose from two to nine. Visitor counts and repeat questioners are unknown, and the record provides no comprehension results. Answer “So the new notice helped people understand?”

**DE** Vor Ort sank die Zahl der Fragen vom ersten zum zweiten Tag von zehn auf vier; online stieg sie von zwei auf neun. Besucherzahlen und Mehrfachanfragen sind unbekannt, Ergebnisse zum Verständnis fehlen in den Unterlagen. Antworte auf „Der neue Hinweis hat also das Verständnis verbessert?“.

''','''현장 질문은 줄었지만 온라인 질문은 늘었습니다. 이 자료에는 방문자 수와 이해도 측정 결과가 없어 이해 향상을 확정할 수 없습니다. 같은 기준으로 질문 유형을 기록하고 이해 확인을 추가하자고 제안합니다.

On-site questions fell and online questions rose. The record provides neither visitor counts nor comprehension results, so we cannot establish improved understanding. I suggest recording question types consistently and checking understanding separately next time.

Vor Ort gab es weniger, online mehr Fragen. Die Unterlagen enthalten weder Besucherzahlen noch Ergebnisse zum Verständnis; eine Verbesserung lässt sich daraus nicht feststellen. Ich schlage vor, die Fragearten künftig einheitlich zu erfassen und das Verständnis gesondert zu prüfen.
''')}
def rep(s,a,z):
 assert s.count(a)==1,(a[:100],s.count(a))
 return s.replace(a,z)
for n,(task,key) in tasks.items():
 p=B/f'C1.1-{n:02}.md';s=p.read_text(encoding='utf-8');start=s.index('**독립 자료');end=s.index('**전이 자료',start)
 s=s[:start]+GUARD+task+DETAIL+key+'\n</details>\n\n'+s[end:]
 if n==1:
  s=rep(s,'진행자가 첫 사진을 가리켰다.','진행자가 사진을 가리켰다.')
  s=rep(s,'the presenter points to the first photo','the presenter points to the photo')
  s=rep(s,'sofort auf das erste Foto','sofort auf das Foto')
  s=rep(s,'Wir brauchen Kennungen, die jede Annahme dem abgeschlossenen Auftrag zuordnen.','Wir brauchen Kennungen, die Einreichungen und fertiggestellte Gegenstände miteinander verknüpfen.')
 if n==3:
  s=rep(s,'He says, “Hope is mine to hold.','Dokkaebi says, “Hope is mine to hold.')
  s=rep(s,'Questions are natural at first, so time should be set aside; none are recorded yet.','The facilitator said that questions naturally arise with a new task and suggested setting aside time for them. No actual questions have been asked yet.')
  s=rep(s,'Vor einer neuen Aufgabe soll Fragezeit eingeplant werden. → „Anfangs entstehen gewöhnlich Fragen; tatsächlich wurde noch keine gestellt.“','Vor Beginn einer neuen Aufgabe rät die Kursleitung, Zeit für die erwarteten Fragen einzuplanen. → „Die Kursleitung sagte, bei einer neuen Aufgabe entstünden gewöhnlich Fragen, und schlug Zeit dafür vor. Tatsächlich wurde noch keine Frage gestellt.“')
  s=rep(s,'Dieser Entwurf lohnt weitere Prüfung.','Es lohnt sich, diesen Entwurf weiter zu prüfen.')
 if n==4:
  s=rep(s,'Die zuständige Prüfung steht noch aus.','Die Prüfung durch die zuständige Person steht noch aus.')
  s=rep(s,'Bitte geben Sie vorher zurück.','Bitte geben Sie die ausgeliehenen Gegenstände vorher zurück.')
  s=rep(s,'Beside the ground-level desk marked 1층. Ask there which device is working.','Beside the information desk on the ground floor (1층). Ask at the desk whether the device you want to use is working.')
  s=rep(s,'Neben der Information im Erdgeschoss, mit 1층 beschriftet. Fragen Sie dort nach einem funktionierenden Gerät.','Neben der Information im Erdgeschoss, das hier 1층 heißt. Fragen Sie dort zuerst, ob das Gerät, das Sie benutzen möchten, funktioniert.')
  s=rep(s,"Seven of eighteen people asked about the tool names. Let's get a photo guide ready for the workshop and have it checked tomorrow. We can reconsider the video afterwards.", 'Let’s prioritise a photo guide for the workshop in two days. Seven of eighteen participants asked about the tool names. We can distribute it after an accuracy check tomorrow and consider the video later.')
  s=rep(s,'Schreibe drei Sätze für den Vorschlag und einen Hinweis für die Teilnehmenden.','Schreibe drei Sätze für den Vorschlag und einen Satz als Hinweis für die Teilnehmenden.')
  s=rep(s,'Sieben von 18 Personen fragten nach den Werkzeugnamen. Erstellen wir für den Workshop eine Bildtafel und lassen sie morgen prüfen. Das Video können wir danach erneut besprechen.','Bereiten wir für den Workshop übermorgen zuerst eine Bildtafel vor. Sieben von 18 Personen fragten nach den Werkzeugnamen. Nach der Genauigkeitsprüfung morgen können wir die Tafel verteilen und das Video später prüfen.')
  s=rep(s,'Die Werkzeugnamen stehen auf der Bildtafel. Bei Fragen hilft die Kursleitung.','Schauen Sie die Werkzeugnamen auf der Bildtafel nach und fragen Sie bei Unklarheiten die Kursleitung.')
 t=p.with_suffix('.md.tmp');t.write_text(s,encoding='utf-8',newline='');assert t.read_text(encoding='utf-8')==s;t.replace(p);print(p.name)
