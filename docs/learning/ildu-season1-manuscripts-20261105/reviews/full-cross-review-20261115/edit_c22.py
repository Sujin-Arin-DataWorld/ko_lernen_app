"""One-time C2.2 translation corrections after all initial reviews."""
from pathlib import Path
R=Path(__file__).resolve().parent
B=R.parents[1]/'manuscripts'
assert all((R/role/'C2.2.json').exists() for role in ('ko-en','ko-de','curriculum'))
pairs={
1:[('When it rained, my friend and I stopped browsing outside.', 'Because of the rain, my friend and I stopped browsing outside.'),
   ('Als es regnete, haben wir draußen nicht weitergestöbert. Ich blieb mit meiner Begleitung noch eine Weile unter dem Zelt, bevor wir gingen.', 'Wegen des Regens haben meine Begleitung und ich aufgehört, draußen zu stöbern. Wir blieben noch eine Weile unter dem Zelt, bevor wir gingen.'),
   ('Next month I will use the same count and ask more users the same question about why they came.', 'Next month I will count entries using the same method and ask more users the same question about why they came.')],
2:[('At 6:30 the clubroom door was open. Hyuna arrived at 6:35 and closed it.', 'At 6:30 p.m. the clubroom door was open. Hyuna arrived at 6:35 p.m. and closed it.'),
   ('The door was open at 6:30 and Hyuna closed it five minutes later.', 'The door was open at 6:30 p.m. and Hyuna closed it five minutes later.'),
   ('잎이 턱에 스치는 문장은 창작으로 남긴다.', '잎이 턱에 스치는 문장은 창작임을 알리는 제목 아래, 장면의 첫 줄에 남긴다.'),
   ('The leaf detail stays in fiction.', 'The leaf-brushing-the-chin detail becomes the opening line of the scene under a heading that identifies it as fiction.'),
   ('Das Blatt am Kinn bleibt in der erfundenen Szene.', 'Die Zeile, in der das Blatt das Kinn streift, steht am Anfang der Szene unter einer Überschrift, die sie als erfunden kennzeichnet.')],
3:[('Passe die Einzelheiten an und halte Zuständigkeit und Gewissheit fest.',
    'Passe die Einzelheiten an und bewahre dabei, wer entscheiden darf und wie sicher die Aussagen sind.'),
   ('As Joy reads the new page, he sets a small piece beside the book for every name.', 'Reading the new page, Joy sets a small piece beside the book for every name.'),
   ('Joy folds his wings and waits to see which part the next visitor opens.', 'Joy folds the wings and waits to see which part the next visitor opens.')],
4:[("We'll share the facts we checked and leave Joy's line in his own name.", "We'll share the facts we checked and label Joy's line as Joy's own words."),
   ('Joys Zeile bleibt als seine eigene Aussage stehen,', 'Joys Zeile kennzeichnen wir als persönliche Aussage von Joy,'),
   ('Joy signs his reflection.', 'Joy signs the reflection.'),
   ('Joy setzt seinen Namen unter seinen Text.', 'Joy setzt den eigenen Namen unter den Text.')],
5:[('Ich habe verwechselt, dass die Tür aufgeht und dass sie benutzt werden soll.',
    'Ich habe die Meldung, dass die Tür wieder aufgeht, mit einer Anweisung verwechselt, diesen Eingang zu benutzen.'),
   ('Zwei Personen aus dem Team haben am Griff geprüft, dass sich die Tür öffnen lässt.',
    'Zwei Personen aus dem Team haben den Türgriff gedreht und bestätigt, dass sich die Tür öffnen lässt.')],
6:[('Ich habe den Satz geteilt, damit Empfang und Versand nicht verwechselt werden.',
    'Ich habe den Satz geteilt, damit die empfangende und die absendende Person nicht verwechselt werden.'),
   ('**예 / Sample / Beispiel** 남길 글 “집 안 수령 기록에서 받은 사람을 확인했다. 보낸 사람은 집 밖의 사본과 집 안 기록을 뒤에 대조해 확인했다.”',
    '**예 / Sample / Beispiel** 밑줄은 처음 읽는 사람에게 새로 소개되는 자료명을 표시합니다. / The underlined terms name sources introduced to a first-time reader. / Unterstrichen sind die Quellenbezeichnungen, die für neue Lesende erstmals eingeführt werden.\n\n맥락 “이 설명은 서로 다른 기록을 차례로 대조해 알게 된 과정을 다룹니다.” 남길 글 “<u>집 안 수령 기록</u>에서 받은 사람을 확인했다. 보낸 사람은 <u>집 밖의 사본</u>과 집 안 기록을 뒤에 대조해 확인했다.”'),
   ('EN: Text: “The house receipt record identified the recipient. We confirmed the sender later by comparing a copy kept outside the house with the records inside.”',
    'EN: Context: “This account explains what was learned by comparing different records in stages.” Text: “The <u>house receipt record</u> identified the recipient. We confirmed the sender later by comparing <u>a copy kept outside the house</u> with the records inside.”'),
   ('DE: Text: „Das Empfangsverzeichnis im Haus nennt die empfangende Person. Wer die Sendung verschickte, klärten wir später im Abgleich einer außerhalb aufbewahrten Abschrift mit den Aufzeichnungen im Haus.“',
    'DE: Kontext: „Diese Erklärung zeigt, was sich durch den schrittweisen Abgleich verschiedener Aufzeichnungen klären ließ.“ Text: „Das <u>Empfangsverzeichnis im Haus</u> nennt die empfangende Person. Wer die Sendung verschickte, klärten wir später im Abgleich <u>einer außerhalb aufbewahrten Abschrift</u> mit den Aufzeichnungen im Haus.“')],
}
for n,changes in pairs.items():
    p=B/f'C2.2-{n:02d}.md'
    raw=p.read_bytes()
    text=raw.decode('utf-8').replace('\r\n','\n')
    for old,new in changes:
        assert text.count(old)==1,(p.name,old,text.count(old))
        text=text.replace(old,new)
    data=text.encode('utf-8')
    if b'\r\n' in raw:
        assert raw.count(b'\n')==raw.count(b'\r\n')
        data=data.replace(b'\n',b'\r\n')
    t=p.with_suffix('.md.tmp')
    t.write_bytes(data)
    assert t.read_bytes()==data
    t.replace(p)
    print(p.name)
