"""One-time C2.1 evidence scope, natural phrasing and hidden-answer edits."""
from pathlib import Path
B=Path(__file__).resolve().parents[2]/'manuscripts'
R=Path(__file__).resolve().parent
assert all((R/role/'C2.1.json').exists() for role in ('ko-en','ko-de','curriculum'))
GUARD='''**KO** 답과 해설을 모든 언어에서 가리고 문제와 자료만 보고 먼저 답해요. 답이나 도움을 본 뒤의 시도는 지원 연습으로 남겨요.

**EN** Hide answers and explanations in every language, and answer from the prompt and materials first. Record attempts after viewing answers or help as supported practice.

**DE** Decke Antworten und Erklärungen in allen Sprachen ab und antworte zuerst nur anhand von Aufgabe und Material. Versuche nach dem Ansehen von Antwort oder Hilfe gelten als unterstützte Übung.

'''
OPEN='<details>\n<summary>응답 후 검토용 답안 / Review after responding / Erst nach der Antwort prüfen</summary>\n\n'
pairs={
1:[
('“Barely one page” shows that the speaker considers a page too little.', '“Only one page” shows that the speaker regards one page as a small amount.'),
('Erst durch den nächsten Satz verstand ich, wie der Scherz gemeint sein könnte.', 'Erst durch den nächsten Satz verstand ich den Zusammenhang des Scherzes.'),
('집필 메모. LEVEL_STORY_100 C2.1-01, STORY_V3_5 본편 B, 원배정 320–324 수용. 회상의 세 대사와 도깨비의 현재 첫 대사는 기존 출처. 나머지는 학습용 추가 집필. 독립 검토 대기.', '집필 메모. LEVEL_STORY_100 C2.1-01, STORY_V3_5 §06 안채 완공 요약 및 본편 B, 원배정 320–324 수용. 회상의 세 대사는 §06 완공 요약의 문구이며, 연이의 웃는 기억도 그 요약에 근거한다. 본편 B의 더 긴 도깨비 발화와 축약 요약을 같은 원문으로 표기하지 않는다. 도깨비의 현재 첫 대사는 LEVEL_STORY_100의 학습용 대사다. 나머지는 학습용 추가 집필. 본편의 공개 조건은 바뀌지 않는다. 독립 검토 대기.'),
],
2:[
('안내를 이미 받아 본 사람이 18명이고 원본 확인을 마친 사람은 5명이다.', '안내를 이미 받아 본 사람은 18명이고, 원본 열람에 필요한 담당자의 확인을 받은 사람은 5명이다. 실제로 원본을 열람한 사람 수는 이 자료에 없다.'),
('Eighteen people have received guidance, and five are cleared to consult an original.', 'Eighteen people have received guidance, and five have received the staff confirmation required to consult an original. The material does not say how many actually consulted one.'),
('18 Personen haben den Hinweis erhalten, 5 haben eine Bestätigung für die Originaleinsicht.', '18 Personen haben den Hinweis erhalten, 5 die erforderliche Bestätigung des Personals für die Originaleinsicht. Wie viele tatsächlich ein Original eingesehen haben, steht in diesen Angaben nicht.'),
],
3:[
('Recollection: “I sent it at last. Afterwards waiting felt lighter.”', 'Recollection: “I sent the reply. Afterwards, waiting felt lighter.”'),
('Someone never returned', 'Someone did not return'),
('Time and absence are unexplained.', 'When the photo was taken and why no one is there are unknown.'),
('Nun hatte ich es schon abgeschlossen, bevor die verabredete Person da war.', 'Ich war schon fertig. Dabei war die Person, mit der ich es gemeinsam durchsehen wollte, noch gar nicht da.'),
("I'd gone and finished it, before the person I was to review it with had arrived.", "I'd gone and finished it. The person I was meant to review it with still wasn't there."),
("Sent 14:00; speaker's relief; receipt or reply unknown.", "Sent at 14:00; the speaker's relief; whether the recipient has read it or replied is unknown."),
],
4:[
("Each of this week's three comparisons was interrupted by a new version", 'At each of this week’s three comparisons, a new revised version arrived'),
('Nein, ich meinte meine Zeit. Ihre kann ich nicht festlegen.', 'Nein, ich meinte meine eigene Zeit. Über die Zeit der anderen kann ich nicht entscheiden.'),
("No. I meant my own time; I can't set yours.", "No. I meant my own time; I can't decide other people's schedules."),
('Streichen verliert Belege, Behalten überschreitet die Länge.', 'Wenn wir den Text streichen, gehen Belege verloren; lassen wir ihn stehen, wird er zu lang.'),
('Selbst wenn ich neu vorbereiten muss, kläre ich die zitierte Person.', 'Selbst wenn ich meine Vorbereitung wiederholen muss, kläre ich, von wem die zitierte Aussage stammt.'),
('**답:** 지연 감수 제안이며 실제 지연 결정은 아니다. / A proposal to accept delay, not a settled schedule. / Vorschlag, Verzögerung hinzunehmen, keine beschlossene Verschiebung.', '**답:** 미확인 수치를 쓰지 않기 위해 발표 지연까지 감수하자는 제안입니다. 실제 일정 변경은 아직 합의되지 않았습니다. / It proposes accepting a delay rather than using unchecked figures. No actual change of schedule has been agreed. / Es wird vorgeschlagen, lieber eine Verzögerung hinzunehmen als ungeprüfte Zahlen zu verwenden. Eine tatsächliche Terminänderung ist noch nicht vereinbart.'),
],
6:[
('Paraphrase prediction, self-question and statement.', 'Paraphrase the prediction, self-question and statement in three sentences in modern Korean.'),
('Umschreibe Vorhersage, Selbstfrage und Aussage.', 'Gib Vorhersage, Selbstfrage und Aussage in drei Sätzen in heutigem Koreanisch wieder.'),
('Sie vermitteln eine schwer vergessene Leerstelle, keinen tatsächlichen Vermisstenfall.', 'Sie vermitteln den Eindruck einer Leerstelle, die sich nicht leicht vergessen lässt, und schildern keinen tatsächlichen Vermisstenfall.'),
('Die rhetorische Frage betont das schwere Vergessen, statt Auskunft zu verlangen.', 'Die rhetorische Frage betont, dass die Leerstelle schwer zu vergessen ist, statt um Auskunft zu bitten.'),
('von zwölf auf acht Wortgruppen', 'von zwölf auf acht durch Leerzeichen getrennte Einheiten'),
('A modern exhibition pairs an empty box with', 'A modern exhibition pairs a photograph of an empty box with'),
('Moderne Ausstellung: leere Kiste und', 'Moderne Ausstellung: Foto einer leeren Kiste und'),
],
}
for n in range(1,7):
    p=B/f'C2.1-{n:02d}.md'
    raw=p.read_bytes()
    text=raw.decode('utf-8').replace('\r\n','\n')
    for old,new in pairs.get(n,[]):
        assert text.count(old)==(2 if old=='Someone never returned' else 1),(p.name,old,text.count(old))
        text=text.replace(old,new)
    if n>=3:
        start=text.index('**독립 자료·과제:**')
        end=text.index('\n## ',start)
        section=text[start:end].replace(' **답:**','\n\n**답:**')
        section='\n'.join(OPEN+line+'\n\n</details>' if line.startswith(('**답:**','**모델:**')) else line for line in section.split('\n'))
        text=text[:start]+GUARD+section+text[end:]
    data=text.encode('utf-8')
    if b'\r\n' in raw:
        assert raw.count(b'\n')==raw.count(b'\r\n')
        data=data.replace(b'\n',b'\r\n')
    t=p.with_suffix('.md.tmp')
    t.write_bytes(data)
    assert t.read_bytes()==data
    t.replace(p)
    print(p.name)
