"""Apply the editor's individually reviewed A1 manuscript decisions once."""
from pathlib import Path

BOOK = Path(__file__).resolve().parents[2]
GUARD = """**KO** 앞의 시범과 아래 검토용 답안은 가리고, 새 자료와 역할 정보만 보고 먼저 답해요. 도움을 열면 도움받은 수행으로 기록해요.

**EN** Hide the earlier models and the review answers below. Respond first using only the new material and role information. Opening help makes this a supported attempt.

**DE** Decke die bisherigen Vorbilder und die folgenden Antworten zur Kontrolle ab. Antworte zuerst nur anhand des neuen Materials und der Rollenangaben. Mit geöffneter Hilfe zählt der Versuch als gestützt.

"""
SUMMARY = '<details>\n<summary>응답 후 검토용 답안 / Review after responding / Erst nach der Antwort prüfen</summary>\n\n'

def replace(s, old, new):
    assert s.count(old) == 1, (old[:90], s.count(old))
    return s.replace(old, new)

def save(p, s):
    tmp = p.with_suffix('.md.tmp')
    tmp.write_text(s, encoding='utf-8', newline='')
    assert tmp.read_text(encoding='utf-8') == s
    tmp.replace(p)

p = BOOK/'manuscripts/A1.1-03.md'
s = p.read_text(encoding='utf-8')
s = replace(s, '### Kurzes Gespräch und Anwendung / Small talk and transfer / 스몰토크와 전이', '### 스몰토크와 전이 / Small talk and transfer / Kurzes Gespräch und Anwendung')
save(p, s)

headings = {
    1: '## 새 일정과 전이 / A new schedule and transfer / Neuer Plan und Anwendung',
    2: '## 새 지도와 전이 / New map and transfer / Neue Karte und Anwendung',
    3: '## 새 기록과 전이 / New record and transfer / Neue Notizen und Anwendung',
    4: '## 새로운 주문 / A new order / Eine neue Bestellung',
    5: '## 새 선택과 전이 / New choice and transfer / Neue Wahl und Anwendung',
    6: '## 새 충돌을 해결하기 / Resolve a new conflict / Einen neuen Konflikt lösen',
}

for n, heading in headings.items():
    p = BOOK/f'manuscripts/A1.2-{n:02}.md'
    s = p.read_text(encoding='utf-8')
    s = replace(s, heading+'\n\n', heading+'\n\n'+GUARD)
    if n == 2:
        s = replace(s,
            '| 독립 확인: 같은 장소 배치에서 나는 X에서 남쪽을 봐요. 상대는 서쪽 정류장 앞에서 기다려요. “오른쪽으로 가요”가 맞나요? 목적지와 대기 장소를 각각 말해요. | Independent check: You face south at X; your partner waits in front of the western stop. Is “go right” correct? Name destination and waiting place separately. | Selbstständige Aufgabe: Du blickst am X nach Süden; das Gegenüber wartet vor der westlichen Haltestelle. Stimmt „rechts“? Nenne Ziel und Warteort getrennt. |',
            '| 새 지도: 북쪽 정류장, 동쪽 도서관, 남쪽 카페, 서쪽 다리, 중앙 X. | New map: bus stop north, library east, café south, bridge west, X in the centre. | Neue Karte: Haltestelle im Norden, Bibliothek im Osten, Café im Süden, Brücke im Westen, X in der Mitte. |\n| 독립 확인: 나는 X에서 북쪽을 봐요. 상대는 동쪽 도서관 앞에서 기다려요. “오른쪽으로 가요”가 맞나요? 목적지와 대기 장소를 각각 말해요. | Independent check: Face north at X. Your partner waits in front of the eastern library. Is “go right” correct? State the destination and waiting place separately. | Selbstständige Aufgabe: Blicke am X nach Norden. Das Gegenüber wartet vor der östlichen Bibliothek. Stimmt „rechts“? Nenne Ziel und Warteort getrennt. |')
        s = replace(s,
            '| 답 맞음. “정류장에 가요.” “정류장 앞에서 기다려요.” 상대가 카페에 있는 앞 대화와 대상을 바꾸었으므로 새 자료를 봐요. | Answer: Yes. 정류장에 가요 / 정류장 앞에서 기다려요. The destination differs from the café in the previous conversation; use the new material. | Lösung: Ja. 정류장에 가요 / 정류장 앞에서 기다려요. Ziel ist jetzt die Haltestelle; beachte die neuen Angaben. |',
            '| 답 맞음. “도서관에 가요.” “도서관 앞에서 기다려요.” 새 지도의 배치와 내가 보는 방향을 함께 확인해요. | Answer: Yes. 도서관에 가요 / 도서관 앞에서 기다려요. Check both the new layout and the direction you face. | Lösung: Ja. 도서관에 가요 / 도서관 앞에서 기다려요. Prüfe sowohl die neue Anordnung als auch deine Blickrichtung. |')
    if n == 3:
        s = replace(s, '„Das ist ein Foto von gestern. Erzählst du getrennt, was heute ist?“', '„Das ist ein Foto von gestern. Erzählst du mir auch, was du heute machst?“')
    if n == 4:
        s = replace(s,
            '| 독립 확인: 메모의 수량과 받는 사람을 각각 고치고 합계 가격을 말해요. 가능한 답 “두 병이 아니에요. 세 병 주세요. 크리스티안 씨한테 주세요. 삼천 원이에요.” | Independent check: Correct quantity and recipient separately and state the total. Possible answer: “Not two. Three bottles for Christian, please. 3,000 won.” | Selbstständige Aufgabe: Korrigiere Menge und Empfänger getrennt und nenne den Gesamtpreis. Mögliche Antwort: „Nicht zwei. Drei Flaschen für Christian, bitte. 3.000 Won.“ |',
            '| 독립 확인: 메모의 수량과 받는 사람을 각각 고치고 합계 가격을 말해요. | Independent check: Correct the quantity and recipient separately and state the total. | Selbstständige Aufgabe: Korrigiere Menge und Empfänger getrennt und nenne den Gesamtpreis. |\n| 가능한 답 “두 병이 아니에요. 세 병 주세요. 크리스티안 씨한테 주세요. 삼천 원이에요.” | Possible answer: “Not two. Three bottles for Christian, please. 3,000 won.” | Mögliche Antwort: „Nicht zwei. Drei Flaschen für Christian, bitte. 3.000 Won.“ |')
    if n == 6:
        s = replace(s, 'Being late caused a call: 늦어서 연락했어요.', 'If you got in touch because you were running late: 늦어서 연락했어요.')
        # German likewise leaves the communication channel unspecified.
        s = replace(s, 'Verspätung führte zur Nachricht: 늦어서 연락했어요.', 'Weil du dich verspätet hast, hast du dich gemeldet: 늦어서 연락했어요.')
        cue = '## 현대 듣기 — 같은 약속인지 확인하기 / Listening: confirming the same plan / Hören: dieselbe Verabredung bestätigen'
        addition = '''### 새 추측 한 차례 / Make a new prediction / Eine neue Vermutung

'''+GUARD+'''**KO** 새 카드에는 어두운 구름이 보여요. 아직 비는 오지 않아요. 비가 올 것 같다는 추측을 `-겠-`으로 한 문장 말해요. 관찰된 비나 확정 예보로 말하지 않아요.

**EN** The new card shows dark clouds; it is not raining yet. Use `-겠-` to predict rain in one sentence. Present it as a guess, not observed rain or a confirmed forecast.

**DE** Die neue Karte zeigt dunkle Wolken; noch regnet es nicht. Vermute mit `-겠-` in einem Satz, dass Regen kommt. Formuliere es als Vermutung, nicht als beobachteten Regen oder sichere Vorhersage.

'''+SUMMARY+'''가능한 답: “비가 오겠어요.” / Possible answer: “It looks like it will rain.” / Mögliche Antwort: „Es wird wohl regnen.“

이 발화는 날씨 추측이에요. 앞의 “제가 먼저 연락하겠어요”는 내가 하겠다는 의지예요. / This utterance predicts the weather; the earlier “제가 먼저 연락하겠어요” expresses your commitment. / Diese Äußerung ist eine Wettervermutung; das frühere „제가 먼저 연락하겠어요“ drückt deine Zusage aus.

</details>

'''
        s = replace(s, cue, addition+cue)
    # Only the named independent section: leave guided models visible elsewhere.
    start = s.index(heading)
    end = s.index('## ', start+3) if '## ' in s[start+3:] else len(s)
    part = s[start:end]
    lines = part.splitlines(keepends=True)
    indices = [i for i,line in enumerate(lines) if line.startswith('| 가능한 ') or line.startswith('| 답 맞음')]
    assert len(indices) == 1, (p,indices)
    i = indices[0]
    answer = lines[i].rstrip('\n')
    lines[i] = '\n'+SUMMARY+'| KO | EN | DE |\n|---|---|---|\n'+answer+'\n\n</details>\n\n### 스몰토크와 전이 / Small talk and transfer / Small Talk und Anwendung\n\n| KO | EN | DE |\n|---|---|---|\n'
    s = s[:start]+''.join(lines)+s[end:]
    save(p,s)
    print(p.name)
