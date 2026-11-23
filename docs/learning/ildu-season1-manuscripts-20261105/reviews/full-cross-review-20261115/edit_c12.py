"""One-time C1.2 meaning, agency and independent-response corrections."""
from pathlib import Path
B = Path(__file__).resolve().parents[2] / 'manuscripts'
GUARD = '''**KO** 답과 해설을 모든 언어에서 가리고 문제와 자료만 보고 먼저 답해요. 답이나 도움을 본 뒤의 시도는 지원 연습으로 남겨요.

**EN** Hide answers and explanations in every language, and answer from the prompt and materials first. Record attempts after viewing answers or help as supported practice.

**DE** Decke Antworten und Erklärungen in allen Sprachen ab und antworte zuerst nur anhand von Aufgabe und Material. Versuche nach dem Ansehen von Antwort oder Hilfe gelten als unterstützte Übung.

'''
OPEN = '<details>\n<summary>응답 후 검토용 답안 / Review after responding / Erst nach der Antwort prüfen</summary>\n\n'
REPLACEMENTS = {
1: [('Nicht öffnen oder entsorgen.', 'Die Kiste muss weder geöffnet noch entsorgt werden.')],
2: [
('Either use only the two approved photos in an internal draft or prepare text only.', 'Either use only photos of the two people who agreed in an internal draft, or prepare text only.'),
('Nur die zwei freigegebenen Fotos im internen Entwurf oder zunächst Text allein.', 'Nur Fotos der beiden Personen, die der internen Nutzung zugestimmt haben, in den internen Entwurf aufnehmen oder zunächst nur Text vorbereiten.'),
('statt die Fotos zu überstürzen', 'statt die Fotos überstürzt einzufügen'),
('A hat weniger Daten und größere Schrift, gleicher Inhalt → „A ist kleiner und hat zudem größere Schrift.“', 'Datei A ist bei gleichem Inhalt kleiner und verwendet eine größere Schrift → „Datei A benötigt weniger Speicherplatz und hat außerdem eine größere Schrift.“'),
('Shall we use only the two approved photos?', 'Shall we use only photos of the two people who have replied?'),
('Nehmen wir nur die zwei freigegebenen Fotos?', 'Verwenden wir nur Fotos der beiden Personen, die geantwortet haben?'),
],
3: [
('New dialogue suggests he may instead want a pause. His story-map line says even “all right” can be queried.', 'Sujin suggests Dokkaebi may instead want a pause. Dokkaebi’s line from the story map says that even “all right” can be queried.'),
('Jun sagte, er habe nichts gehört, aber so getan.', 'Jun sagte, er habe es nicht gehört, aber so getan, als hätte er es gehört.'),
('Ihre Antwort war ungewöhnlich kurz; ich dachte, die Änderung störe Sie.', 'Deine Antwort war ungewöhnlich kurz; ich dachte, die Änderung störe dich.'),
('Ich habe Ihr Gefühl vorschnell vermutet. Gibt es Ergänzungen?', 'Ich habe vorschnell auf deine Gefühle geschlossen. Gibt es noch etwas zu ergänzen?'),
('Prüfen Sie nur den Namen beim letzten Foto; der Rest kann bleiben.', 'Prüf bitte nur den Namen beim letzten Foto; der Rest kann bleiben.'),
('Sprechen wir, wenn es Ihnen passt.', 'Sprechen wir, wenn es dir passt.'),
],
4: [
('I checked the summary with that person.', 'I asked the person concerned whether the summary was accurate.'),
('Ich ließ die Zusammenfassung bestätigen.', 'Ich fragte die beteiligte Person, ob die Zusammenfassung stimmt.'),
("I only heard the organiser's plan, not the room's readiness.", "I only heard the organiser's plan to change rooms. I haven't seen for myself whether the new room is ready."),
('Ich hörte nur den Änderungsplan, nicht den Vorbereitungsstand.', 'Ich habe nur den Änderungsplan der zuständigen Person gehört. Wie weit der neue Raum vorbereitet ist, habe ich nicht selbst gesehen.'),
('Hyuna sah gestern Abend den gesperrten Wasserhahn, Grund unbekannt.', 'Hyuna sah gestern Abend, dass der Wasserhahn zugedreht war; den Grund kennt sie nicht.'),
],
5: [
('‘제목·날짜 확인 완료, 본문은 레나가 내일 검토 예정’이면 되겠네요.', '‘안드레아가 제목·날짜를 확인했고, 본문은 레나가 내일 검토할 예정입니다’라고 쓰면 되겠네요.'),
('Then: “Title/date checked; body review by Lena planned tomorrow.”', 'Then we can write: “Andrea checked the title and date; Lena is scheduled to review the body tomorrow.”'),
('Dann: „Titel und Datum geprüft; Textprüfung durch Lena morgen geplant.“', 'Dann können wir schreiben: „Andrea hat Titel und Datum geprüft; Lena wird den Text morgen prüfen.“'),
('완료 범위? 제목·날짜(2).', '완료 범위와 확인자? 제목·날짜, 안드레아(2·5).'),
('Title/date complete; Lena reviews body tomorrow;', 'Andrea checked the title/date; Lena reviews the body tomorrow;'),
('Titel/Datum fertig; Lena morgen für Text;', 'Andrea hat Titel/Datum geprüft; Lena prüft morgen den Text;'),
('새 입주자 채팅과 주민 게시판에 각각 2문장으로 쓰고 바꾼 점을 설명한다.', '의견을 전한 주민의 입장에서 새 입주자 채팅과 주민 게시판에 각각 2문장으로 쓰고 바꾼 점을 설명한다.'),
("Write two sentences for a new neighbour's chat and two for the noticeboard, then explain the style change.", "Write from the perspective of the resident who passed on the concern: two sentences for a new neighbour's chat and two for the noticeboard. Explain the style change."),
('Schreibe je zwei Sätze für einen neuen Nachbarn im Chat und den Aushang; begründe den Stilwechsel.', 'Schreibe in der Rolle der Person, die den Hinweis weitergegeben hat, je zwei Sätze für einen neuen Nachbarn im Chat und den Aushang; begründe den Stilwechsel.'),
('주민 의견이 관리 담당자에게 전달되었습니다.', '계단이 어둡다는 주민 의견이 관리 담당자에게 전달되었습니다.'),
("I passed on the concern. Management will inspect tomorrow; repairs aren't agreed.", 'I told management that the stairs are dark. They said they would inspect them tomorrow; no repair has been agreed yet.'),
("The resident's concern has been passed to management. Inspection is planned tomorrow; any repair remains undecided.", 'A resident’s concern about the dark stairs has been passed to management. An inspection is planned for tomorrow; any repair remains undecided.'),
('Ich habe den Hinweis weitergegeben. Morgen wird nachgesehen; eine Reparatur ist noch nicht vereinbart.', 'Ich habe der Verwaltung gemeldet, dass die Treppe dunkel ist. Sie will sich die Treppe morgen ansehen; eine Reparatur ist noch nicht vereinbart.'),
('Der Hinweis wurde der Verwaltung übermittelt.', 'Der Hinweis auf die dunkle Treppe wurde der Verwaltung übermittelt.'),
],
6: [
('Drei Nachbarn vereinbaren Samstag 10–11 Uhr Tausch ohne Fotos, Lenas Bedingung wird akzeptiert.', 'Drei Nachbarn vereinbaren, am Samstag von 10 bis 11 Uhr Gegenstände weiterzugeben; dabei werden keine Fotos gemacht. Alle akzeptieren diese Bedingung von Lena.'),
('Sharing runs Saturday 10–11, with no photography.', 'The sharing event runs from 10:00 to 11:00 on Saturday. There will be no photography.'),
('Tausch Samstag 10–11 Uhr, ohne Fotoaufnahmen.', 'Am Samstag geben wir von 10 bis 11 Uhr Gegenstände weiter. Dabei werden keine Fotos gemacht.'),
],
}
for n, pairs in REPLACEMENTS.items():
    p = B / f'C1.2-{n:02d}.md'
    raw = p.read_bytes()
    text = raw.decode('utf-8').replace('\r\n', '\n')
    for old, new in pairs:
        assert text.count(old) == 1, (p.name, old, text.count(old))
        text = text.replace(old, new)
    start = text.index('**독립 자료·과제')
    end = text.index('\n## 다음', start)
    section = text[start:end]
    if n == 1:
        old = '**수용 확인:** KO: “지금 올리려고요?”를 게시 허락으로 옮기면 맞는가? **아니다. 의도 확인이다.** EN: Does “Are you planning to post now?” grant permission? **No, it asks about intention.** DE: Erteilt „Wollen Sie jetzt posten?“ eine Erlaubnis? **Nein, es fragt die Absicht ab.**'
        new = '**수용 확인:** KO: “지금 올리려고요?”를 게시 허락으로 옮기면 맞는가? EN: Does “Are you planning to post now?” grant permission? DE: Erteilt „Wollen Sie jetzt posten?“ eine Erlaubnis?\n\n**모델:** 아니다. 의도 확인이다. / No, it asks about intention. / Nein, es fragt die Absicht ab.'
        assert old in section
        section = section.replace(old, new)
    section = '\n'.join(OPEN + line + '\n\n</details>' if line.startswith(('**모델:**', '**모범 핵심:**')) else line for line in section.split('\n'))
    text = text[:start] + GUARD + section + text[end:]
    data = text.encode('utf-8')
    if b'\r\n' in raw:
        assert raw.count(b'\n') == raw.count(b'\r\n')
        data = data.replace(b'\n', b'\r\n')
    temp = p.with_suffix('.md.tmp')
    temp.write_bytes(data)
    assert temp.read_bytes() == data
    temp.replace(p)
    print(p.name)
