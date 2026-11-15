"""One-time final-round support separation and Joy reference corrections."""
from pathlib import Path
B=Path(__file__).resolve().parents[2]/'manuscripts'
GUARD='''**KO** 앞의 시범과 이 절의 모든 언어 답안을 가리고, 새 자료로 먼저 답해요. 답이나 표현 도움을 열어 본 뒤의 시도는 지원 연습으로 남겨요.

**EN** Hide the earlier models and every answer in this section in all languages. Respond first from the new material. Record attempts after viewing answers or wording help as supported practice.

**DE** Decke die bisherigen Vorbilder und alle Antworten dieses Abschnitts in jeder Sprache ab. Antworte zuerst anhand des neuen Materials. Versuche nach dem Ansehen von Antworten oder Formulierungshilfen gelten als unterstützte Übung.

'''
OPEN='<details>\n<summary>응답 후 검토용 답안 / Review after responding / Erst nach der Antwort prüfen</summary>\n\n'
for uid in ('B1.1-05','B1.1-06','A2.1-02'):
    p=B/(uid+'.md')
    raw=p.read_bytes()
    text=raw.decode('utf-8').replace('\r\n','\n')
    if uid=='A2.1-02':
        old='Am Ruheplatz rückt Joy seinen eigenen kleinen Hut zurecht und zeigt auf einen großen Übungshut. Die neuen Lernrequisiten ersetzen weder seinen Hut noch einen alten Gegenstand der Geschichte.'
        new='Am Ruheplatz rückt Joy den eigenen kleinen Hut zurecht und zeigt auf einen großen Übungshut. Die neuen Lernrequisiten ersetzen weder Joys eigenen Hut noch einen alten Gegenstand der Geschichte.'
        assert text.count(old)==1
        text=text.replace(old,new)
    else:
        start=text.index('## 새 ')
        end=text.index('\n## 다음',start)
        section=text[start:end]
        pos=section.index('\n\n')+2
        section=section[:pos]+GUARD+section[pos:]
        if uid=='B1.1-05':
            a=section.index('| 문형·요청')
            z=section.index('\n\n',a)
            rows=section[a:z].splitlines()[2:]
            assert len(rows)==4
            prompts=['| 문형·요청 / Form and request / Form und Aufgabe |','|---|']
            answers=['| 문형 / Form | 가능한 답 KO / EN / DE |','|---|---|']
            for line in rows:
                cells=[s.strip() for s in line.strip('|').split('|')]
                assert len(cells)==2
                prompts.append('| '+cells[0]+' |')
                form=cells[0].split(':',1)[0]
                answers.append('| '+form+' | '+cells[1]+' |')
            replacement='\n'.join(prompts)+'\n\n'+OPEN+'\n'.join(answers)+'\n\n</details>'
            section=section[:a]+replacement+section[z:]
        section='\n'.join(OPEN+line+'\n\n</details>' if line.startswith(('**모범 / Model / Muster:**','**답 / Answers / Lösungen:**')) else line for line in section.split('\n'))
        text=text[:start]+section+text[end:]
    data=text.encode('utf-8')
    if b'\r\n' in raw:
        assert raw.count(b'\n')==raw.count(b'\r\n')
        data=data.replace(b'\n',b'\r\n')
    t=p.with_suffix('.md.tmp')
    t.write_bytes(data)
    assert t.read_bytes()==data
    t.replace(p)
    print(uid)
