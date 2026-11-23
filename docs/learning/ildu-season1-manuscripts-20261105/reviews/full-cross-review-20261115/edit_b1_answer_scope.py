"""Make the fresh-task help boundary cover the whole B1 exercise section."""
from pathlib import Path
B=Path(__file__).resolve().parents[2]/'manuscripts'
UNITS=('B1.1-01','B1.1-04','B1.2-01','B1.2-02','B1.2-03','B1.2-04','B1.2-05','B1.2-06')
GUARD='''**KO** 앞의 시범과 이 절의 모든 언어 답안을 가리고, 새 자료로 먼저 답해요. 답이나 표현 도움을 열어 본 뒤의 시도는 지원 연습으로 남겨요.

**EN** Hide the earlier models and every answer in this section in all languages. Respond first from the new material. Record attempts after viewing answers or wording help as supported practice.

**DE** Decke die bisherigen Vorbilder und alle Antworten dieses Abschnitts in jeder Sprache ab. Antworte zuerst anhand des neuen Materials. Versuche nach dem Ansehen von Antworten oder Formulierungshilfen gelten als unterstützte Übung.

'''
OPEN='<details>\n<summary>응답 후 검토용 답안 / Review after responding / Erst nach der Antwort prüfen</summary>\n\n'
for uid in UNITS:
    p=B/(uid+'.md')
    raw=p.read_bytes()
    text=raw.decode('utf-8').replace('\r\n','\n')
    start=text.index('## 새 ')
    end=text.index('\n## ',start+4)
    section=text[start:end]
    assert GUARD not in section
    pos=section.index('\n\n')+2
    section=section[:pos]+GUARD+section[pos:]
    section='\n'.join(OPEN+line+'\n\n</details>' if line.startswith('**모범 / Model / Muster:**') else line for line in section.split('\n'))
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
