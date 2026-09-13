"""KP26 original narrative, recollection and criticism; unsigned source."""
from phase_task_authoring import choice, free_text, grammar_task, loc, packet, task, write_source
from author_phase_a1_production import production


def kp26():
    rows=[
      ('G6:마는',loc('앞 진술을 인정한 채 어긋나는 평가를 덧붙이는 조사예요. 앞 내용 전체를 부정하지 않아요.','This particle adds a contrary evaluation while conceding the first statement, without negating it entirely.','Diese Partikel ergänzt eine gegenläufige Bewertung bei zugestandener erster Aussage, ohne sie vollständig zu verneinen.'),('뜻은 좋다마는 방법에는 동의하기 어렵다.','뜻의 긍정과 방법의 유보 공존','뜻도 방법도 전면 부정'),('설명은 들었다마는 의문은 남아 있다.','청취 사실과 남은 의문','설명을 전혀 듣지 않음')),
      ('G6:-건만',loc('기대와 현실의 어긋남을 문학적으로 드러내요. 결과의 원인이나 다른 인물의 의도까지 말하지는 않아요.','Express a literary mismatch of expectation and outcome, without establishing causes or another character’s intent.','Zeige literarisch die Abweichung zwischen Erwartung und Ergebnis, ohne Ursache oder Figurenabsicht festzustellen.'),('밤새 기다렸건만 아무도 오지 않았다.','기대와 달리 아무도 오지 않음','누군가 고의로 약속을 어겼다고 입증'),('여러 번 읽었건만 뜻은 여전히 모호했다.','반복 독서와 기대에 못 미친 이해','반복 독서로 뜻이 완전히 명확해짐')),
      ('G6:-어 치우다',loc('일을 끝내거나 제거한 완료를 단호하게 표현해요. 후회·분노 여부는 문맥으로 확인합니다.','Express decisive completion or removal. Context determines whether regret or anger is present.','Drücke entschlossenen Abschluss oder Beseitigung aus. Reue oder Ärger ergeben sich erst aus dem Kontext.'),('그는 남은 정리를 한꺼번에 해 치웠다. 후회는 없었다고 말했다.','정리 완료와 명시된 무후회','정리가 미완료이고 후회가 확정'),('그는 쌓인 상자를 모두 치워 버리고 청소까지 해 치웠다.','제거와 청소 완료','청소할 의향만 제시')),
      ('G6:-기 일쑤이다',loc('대체로 좋지 않은 일이 자주 반복됨을 평가해요. 항상·모든 경우라는 전칭 명제는 아닙니다.','Evaluate a frequent, usually undesirable pattern, not a universal claim about every instance.','Bewerte eine häufige, meist unerwünschte Wiederholung, nicht jeden einzelnen Fall ausnahmslos.'),('맥락을 빼면 뜻을 오해하기 일쑤이다. 그렇지 않은 때도 있다.','잦은 오해 경향, 예외 가능','항상 누구나 반드시 오해'),('급히 쓰면 날짜를 빠뜨리기 일쑤이다. 이번에는 적었다.','누락 경향과 이번 예외','이번에도 날짜 누락 확정')),
      ('G6:-기 짝이 없다',loc('평가의 정도를 매우 강하게 강조해요. 평가자의 기준과 사실 보고를 구별합니다.','Strongly intensify an evaluation. Distinguish the evaluator’s standard from factual reporting.','Verstärke eine Bewertung stark. Trenne den Maßstab der wertenden Person vom Tatsachenbericht.'),('확인도 없이 단정한 태도는 무책임하기 짝이 없다고 화자는 적었다.','화자의 매우 강한 태도 평가','법적 책임 확정 판결'),('화자는 빈 의자가 쓸쓸하기 짝이 없었다고 썼다.','화자의 극심한 쓸쓸함 표현','의자 자체가 감정을 느꼈음')),
      ('G6:-디1',loc('형용사 반복으로 정도를 강조하는 문학적 표현입니다. 정도 강조를 사건 횟수나 시간 측정값으로 읽지 않아요.','A literary adjective repetition intensifies degree, not event frequency or a measured duration.','Literarische Adjektivwiederholung verstärkt den Grad, nicht Ereigniszahl oder gemessene Dauer.'),('깊디깊은 침묵이 방 안에 내려앉았다.','침묵의 정도를 문학적으로 강조','침묵이 정확히 두 번 발생'),('길디긴 복도가 눈앞에 놓여 있었다.','길이에 대한 강한 인상','복도 길이의 정확한 수치 제시')),
      ('G6:-노라면',loc('행동이 이어지는 가운데 생기는 경험을 서술해요. 문학적 회고 형식이며 명령이나 완료 보고가 아닙니다.','Describe an experience arising during a continuing action, in literary recollection, not a command or completion report.','Beschreibe literarisch eine Erfahrung während fortgesetzten Handelns, keinen Befehl oder Abschlussbericht.'),('옛길을 걷노라면 잊었던 장면이 떠오른다.','걷는 동안 기억이 떠오르는 경험','옛길을 반드시 걸으라는 명령'),('낡은 기록을 읽노라면 그날의 소리가 떠오른다.','읽는 가운데 소리 기억 환기','그날 소리가 현재 실제로 재생됨')),
      ('G4:-어 버리다',loc('완료한 사건에 대한 정서가 실릴 수 있지만 후회인지 후련함인지는 문맥에서 확인해요.','Completion may carry emotion, but context determines regret or relief.','Abschluss kann emotional gefärbt sein; erst der Kontext zeigt Reue oder Erleichterung.'),('편지를 찢어 버렸다. 화자는 그 일을 후회한다고 말했다.','찢기 완료, 뒤 진술에 명시된 후회','찢기 미완료, 후회 없음'),('초안을 지워 버렸다. 화자는 홀가분했다고 말했다.','삭제 완료, 뒤 진술에 명시된 홀가분함','버리다만으로 반드시 후회')),
    ]
    tasks=[grammar_task('KP26',i,*r) for i,r in enumerate(rows,1)]
    prod=[
      ('G6:마는',('뜻은 긍정 / 방법 동의 유보 / 좋다마는','뜻은 좋다마는 방법에는 동의하기 어렵다.','뜻도 방법도 모두 잘못되었다.'),('설명 청취 사실 / 의문 남음 / 들었다마는','설명은 들었다마는 의문은 남아 있다.','설명은 듣지 못했다.')),
      ('G6:-건만',('밤새 기다림 / 아무도 안 옴 / 기다렸건만','밤새 기다렸건만 아무도 오지 않았다.','밤새 기다렸더니 모두 왔다.'),('여러 번 읽음 / 뜻 여전히 모호 / 읽었건만','여러 번 읽었건만 뜻은 여전히 모호했다.','여러 번 읽어 뜻이 명확해졌다.')),
      ('G6:-어 치우다',('그 / 남은 정리 / 한꺼번에 완료 / 해 치웠다','그는 남은 정리를 한꺼번에 해 치웠다.','그는 남은 정리를 아직 끝내지 못했다.'),('그 / 쌓인 상자 제거 후 청소까지 완료 / 해 치웠다','그는 쌓인 상자를 모두 치워 버리고 청소까지 해 치웠다.','그는 상자를 그대로 두고 청소도 하지 않았다.')),
      ('G6:-기 일쑤이다',('맥락 생략 시 오해 잦음 / 일쑤이다 / 예외도 있음','맥락을 빼면 뜻을 오해하기 일쑤이다. 그렇지 않은 때도 있다.','맥락을 빼면 누구나 항상 오해한다.'),('급히 쓸 때 날짜 누락 잦음 / 일쑤이다 / 이번에는 적음','급히 쓰면 날짜를 빠뜨리기 일쑤이다. 이번에는 적었다.','이번에도 날짜를 빠뜨렸다.')),
      ('G6:-기 짝이 없다',('화자의 글 / 확인 없이 단정한 태도 / 무책임하기 짝이 없다고','확인도 없이 단정한 태도는 무책임하기 짝이 없다고 화자는 적었다.','법원은 그 태도의 위법성을 확정했다.'),('화자의 글 / 빈 의자 / 쓸쓸하기 짝이 없었다고','화자는 빈 의자가 쓸쓸하기 짝이 없었다고 썼다.','빈 의자가 실제로 슬픔을 느꼈다.')),
      ('G6:-디1',('침묵의 정도 강조 / 깊디깊은 / 방 안에 내려앉았다','깊디깊은 침묵이 방 안에 내려앉았다.','침묵이 정확히 두 번 발생했다.'),('복도 길이 인상 강조 / 길디긴 / 눈앞에 놓여 있었다','길디긴 복도가 눈앞에 놓여 있었다.','복도의 길이는 정확히 이 미터였다.')),
      ('G6:-노라면',('옛길 걷는 중 잊었던 장면 환기 / 걷노라면','옛길을 걷노라면 잊었던 장면이 떠오른다.','옛길을 반드시 걸어야 한다.'),('낡은 기록 읽는 중 그날 소리 환기 / 읽노라면','낡은 기록을 읽노라면 그날의 소리가 떠오른다.','그날의 소리가 현재 실제로 재생되고 있다.')),
      ('G4:-어 버리다',('편지 찢기 완료 / 화자가 후회한다고 말함 / 찢어 버렸다','편지를 찢어 버렸다. 화자는 그 일을 후회한다고 말했다.','편지를 찢었지만 화자는 후회하지 않는다고 말했다.'),('초안 삭제 완료 / 화자가 홀가분했다고 말함 / 지워 버렸다','초안을 지워 버렸다. 화자는 홀가분했다고 말했다.','초안을 아직 지우지 않았다.')),
    ]
    tasks+=production('KP26',tasks,prod)
    h=loc('사건·회고 순서·평가를 나누고 근거 구절을 찾으세요. 완료는 감정 자체가 아니며 반복 경향은 항상과 다릅니다. 서술자·인물·기사 작성자·실제 저자를 구별하고 미상 시각과 의도는 남깁니다.','Separate events, narration order and evaluation, citing passages. Completion is not emotion itself and frequency is not always. Distinguish narrator, character, journalist and real author; leave unknown times and intentions open.','Trenne Ereignisse, Erzählfolge und Wertung mit Textbelegen. Abschluss ist nicht selbst ein Gefühl, Häufigkeit nicht immer. Unterscheide Erzählinstanz, Figur, Journalismus und reale Autorschaft; lasse unbekannte Zeiten und Absichten offen.')
    p=('가람독서회','화요일','월요일','수요일',3)
    a=('솔빛문학회','금요일','목요일','토요일',4)
    def story(args):
        name,meeting,previous,after,count=args
        return f'''[창작 단편: 빛이 바랜 봉투 — {name} 읽기 자료]
나는 지금 빈 의자부터 떠올린다. {meeting} 밤새 기다렸건만 아무도 오지 않았다. 깊디깊은 침묵이 방 안에 내려앉았다. 의자가 쓸쓸하기 짝이 없었다고 적은 것은 그때의 나다. 의자의 객관적 성질을 측정한 말은 아니다.
이야기를 {previous}로 돌리자. 그날 오후 나는 모임 날짜가 적힌 편지 {count}장을 받았다. 날짜를 제대로 대조했는지는 지금 기억나지 않는다. 급히 읽으면 날짜를 놓치기 일쑤였지만 이번에도 그랬다고 확정할 자료는 없다. 상대가 일부러 나를 기다리게 했다는 증거도 없다.
{meeting} 밤이 지나고 {after} 아침, 나는 남은 정리를 한꺼번에 해 치웠다. 봉투는 상자에 넣어 두었다. 편지를 찢어 버린 것은 사실이다. 정확히 몇 시였는지는 적지 않았다. 나는 나중에 그 일을 후회한다고 말했다. 정리를 마친 사실과 편지를 찢은 사실은 적었지만 그날 아침 둘 중 무엇을 먼저 했는지는 여기 쓰지 않는다.
지금 옛길을 걷노라면 그 장면이 떠오른다. 뜻은 좋다마는 그때의 내 방법에는 동의하기 어렵다. 이 문장의 나는 과거의 자신을 평가한다. 누군가의 진심까지 안다는 말은 아니다. 편지를 받았다는 사실, 아무도 오지 않았다는 경험, 훗날의 후회가 한 장면처럼 겹쳐 보이지만 서로 다른 시간의 진술이다.
[독자를 위한 열린 질문]
빈 봉투를 상징으로 읽을 수는 있다. 그러나 봉투를 남긴 이유가 화해인지 집착인지는 본문에 없다. 역사적 기억을 재현하는 작품이라는 홍보 문구가 붙더라도 이 허구의 사건이 실제 지역사에서 일어났다고 보증하지 않는다. 행간을 읽는 일은 빈칸을 새 사실로 채우는 일과 다르다.'''
    def recollection(args):
        name,meeting,previous,after,count=args
        return f'''[일상 회고 대화. 서로 반말하기로 합의한 동등한 성인 친구 둘.]
독자 하나: 나는 {previous}에 편지 {count}장을 받았고, {meeting} 밤에 기다렸어. 아무도 안 왔어. 왜 안 왔는지는 아직 몰라. {after} 아침에 정리를 끝냈고 편지도 찢었어. 그 두 일의 순서와 정확한 시각은 안 적었어. 찢은 일은 나중에 후회했어.
독자 둘: 소설에서는 깊디깊다거나 쓸쓸하기 짝이 없다고 하니까 더 강하게 느껴져. 그럼 작가가 모두를 비난한 거야?
독자 하나: 그건 단정하지 말자. 소설 속 나는 자기 방법을 평가해. 실제 저자의 모든 생각은 모르지. 일쑤였다는 말도 매번 그랬다는 기록은 아니야. 문학적 과장이 실제 분노를 증명하는 건 아니고.
독자 둘: 절제해서 읽을 때와 휴지를 길게 두어 읽을 때 여운이 다르겠네. 그렇다고 녹음에 없는 감정을 정답처럼 붙이면 안 되겠어.
독자 하나: 맞아. 목소리와 텍스트를 나란히 보고, 확인한 휴지만 적자. 다른 독자가 다르게 느낄 여지는 남기자.'''
    def listen(args):
        return packet(story(args)+'\n'+recollection(args),[
          choice('chronology',loc('확정할 수 있는 큰 사건 순서는?','Which broad chronology is established?','Welche grobe Ereignisfolge steht fest?'),['편지 수령 → 기다림 → 다음 아침 정리·찢기','빈 의자 회고 → 편지 수령이 실제 사건 순서'],h),
          choice('unknown',loc('미상으로 남는 시간 정보는?','Which timing information remains unknown?','Welche Zeitangabe bleibt unbekannt?'),['다음 아침 두 행동의 순서와 정확한 시각','편지 수령이 기다림보다 앞선 사실'],h),
          choice('evaluation',loc('쓸쓸하기 짝이 없다는 무엇인가요?','What is the extreme loneliness statement?','Was ist die Aussage äußerster Trostlosigkeit?'),['그때의 화자가 남긴 강한 평가','의자의 측정된 객관적 감정'],h),
          choice('habit',loc('일쑤였다가 보장하지 않는 것은?','What does the habitual expression not guarantee?','Was garantiert der Gewohnheitsausdruck nicht?'),['이번에도 날짜를 놓쳤다는 사실','과거의 잦은 경향이라는 평가'],h),
          choice('regret',loc('찢기 후회의 근거는?','What supports regret about tearing?','Was belegt die Reue über das Zerreißen?'),['뒤의 명시적인 후회 진술','버리다 형태만으로 언제나 후회'],h),
          choice('voice',loc('낭독 해석에서 지켜야 할 한계는?','What limit applies to interpreting the reading?','Welche Grenze gilt für die Deutung des Vorlesens?'),['실제 들은 휴지와 텍스트를 대조, 없는 의도 미확정','희귀 말끝만으로 실제 저자의 분노 확정'],h),
        ],'audio')
    tasks.append(task('KP26','listening:01','listening',loc('서사 낭독과 일상 회고 비교','Compare narrative reading and everyday recollection','Erzählvortrag und alltäglichen Rückblick vergleichen'),h,listen(p),listen(a)))
    def criticism(args):
        return story(args)+'''\n[비평 A: 회고의 거리]
이 작품의 장점은 현재의 회고, 기다린 밤, 편지 수령, 다음 아침을 뒤섞으면서도 날짜 표지로 사건의 큰 순서를 복원하게 한다는 데 있다. 평가 기준은 회고의 재현과 사실 추적 가능성의 공존이다. -건만은 기다림의 반기대를, -디는 침묵의 정도를 강화한다. -어 치우다는 정리 완료의 단호함을 보태지만 인물의 성급함 전체를 입증하지는 않는다. 후회는 -어 버리다만으로 정해지는 것이 아니라 뒤 진술에서 확인된다.
[비평 B: 과장의 부담]
쓸쓸하기 짝이 없다는 말은 독자가 슬픔을 강하게 읽도록 이끈다. 그래서 평가를 먼저 받아들이고 시간의 빈칸을 놓칠 위험이 있다. 이것은 표현의 효과에 관한 비판이며 작가가 독자를 고의로 속였다는 혐의는 아니다. 반대 해석도 가능하다. 강한 평가와 정확한 시각의 부재를 나란히 놓은 구성이 기억의 한계를 드러낸다고 볼 수 있다. 색안경을 끼었다는 인물 비난 대신 어느 구절이 어떤 해석을 유도하는지 따져야 한다.
[중립적 사건 기록]
편지를 받은 날은 기다린 밤의 전날이다. 기다린 밤에는 아무도 오지 않았다고 화자가 말한다. 다음 아침 정리 완료와 편지 찢기가 서술되며 둘의 내부 순서는 미상이다. 화자는 훗날 찢기를 후회한다고 말했다. 불참 이유와 편지 발신자의 의도는 제시되지 않았다.
[비교 메모]
중립 기록은 정도 강조와 반기대의 문체 효과를 줄였지만 사건의 극성과 전언 출처를 바꾸지 않았다. 이 손실을 설명할 수는 있어도 중립 기록이 모든 문학적 기능을 완전히 대체한다고 할 수는 없다.'''
    def read(args):
        return packet(criticism(args),[
          choice('order',loc('서술의 첫 초점과 사건의 첫 항목은?','What starts the narration and the event sequence?','Was steht am Anfang von Erzählung und Ereignisfolge?'),['현재 빈 의자 회고 / 이전 날 편지 수령','편지 찢기 / 실제 저자의 분노'],h),
          choice('completion',loc('해 치웠다가 직접 뒷받침하는 것은?','What does decisive finishing directly support?','Was stützt das entschlossene Fertigstellen direkt?'),['정리 완료와 단호한 표현','인물의 모든 행동이 성급함'],h),
          choice('counterreading',loc('B가 남긴 반대 해석은?','Which alternative reading does B retain?','Welche Gegenlesart lässt B offen?'),['강한 평가와 시간 빈칸이 기억 한계를 드러냄','작가의 기만 의도를 입증함'],h),
          choice('neutral',loc('중립 기록에서 유지할 것은?','What must a neutral account retain?','Was muss ein neutraler Bericht erhalten?'),['사건 극성·시간 범위·전언 출처','강조를 없애며 불참 이유를 새로 확정'],h),
          choice('symbol',loc('봉투 상징에 관한 허용 범위는?','What is permissible about envelope symbolism?','Was ist zur Umschlagsymbolik zulässig?'),['해석 가능, 보관 동기는 미상','보관은 반드시 화해 의도의 증거'],h),
        ])
    tasks.append(task('KP26','reading:01','reading',loc('회고 순서·사건 순서·두 비평','Narration order, chronology and two critiques','Erzählfolge, Ereignisfolge und zwei Kritiken'),h,read(p),read(a)))
    def article(args):
        name,meeting,previous,after,count=args
        return f'''[가상 문화 기사: {name}의 창작 단편 토론]
기자는 독서 모임에서 두 비평문을 함께 읽고 참가자들이 해석을 비교하는 장면을 직접 보았다고 썼다. 참석 인원과 토론 날짜는 기사에 없다. 작품 속 편지 {count}장과 {meeting}의 기다림은 허구의 서사이지 기자가 확인한 실제 사건이 아니다.
참가자 하나는 “쓸쓸하기 짝이 없다는 문장이 독자를 한쪽 감정으로 몰아가는 것 같아요”라고 말했다. 참가자 둘은 “강한 말과 빈칸이 함께 있어 기억의 한계를 보게 돼요”라고 답했다. 기사는 이 두 발언을 인용한다. 둘 중 어느 쪽에 모든 참석자가 동의했는지는 보도하지 않았다.
기자는 두 발언의 대비가 작품의 여운을 남기는 방식에 관한 논점을 드러낸다고 해석했다. 이 문장은 기자의 분석이다. 작품이 지역의 역사적 기억을 재현한다는 홍보 표현도 소개했지만 작품의 사건이 실제 역사라는 추가 근거를 제시하지 않았다. 상징의 해석과 역사적 사실 확인은 같은 작업이 아니다.
[검토 대상 제목]
모든 독자가 작가의 고의적 감정 조작을 확인했다.
[정정안]
두 독자가 강한 평가 표현의 효과를 다르게 해석했다. 전원 동의나 작가의 동기는 확인되지 않았다.'''
    def news(args):
        return packet(article(args),[
          choice('witness',loc('기자의 직접 관찰로 보도된 것은?','What is reported as the journalist’s observation?','Was wird als direkte Beobachtung berichtet?'),['모임의 비평 비교 장면','소설 속 편지 찢기 사건'],h),
          choice('quote',loc('감정을 몰아가는 것 같다는 지위는?','What is the status of the emotional-steering comment?','Welchen Status hat die Bemerkung zur Gefühlslenkung?'),['참가자 한 명의 잠정 해석','전원의 동의로 확인된 작가 의도'],h),
          choice('reporter',loc('여운의 논점을 드러낸다는 것은?','What is the point about lingering effects?','Was ist die Aussage zur nachwirkenden Wirkung?'),['기자의 분석','기사에 없는 참석자 전원의 인용'],h),
          choice('headline',loc('제목이 덧붙인 미확인 내용은?','What unverified content does the headline add?','Was fügt die Überschrift unbelegt hinzu?'),['전원 확인과 작가의 고의','두 해석이 다르다는 사실'],h),
        ])
    tasks.append(task('KP26','reading:02','reading',loc('문화 기사의 관찰·인용·해석','Observation, quotation and interpretation in arts reporting','Beobachtung, Zitat und Deutung im Kulturbericht'),h,news(p),news(a)))
    rubric=loc('세 편의 완결된 글을 쓰세요. 첫째 평가 기준·장점·한계와 근거 구절을 갖춘 작품 리뷰입니다. 사건 시간표와 회고 순서를 나란히 표시하고 미상 시간은 남겨 두세요. 둘째 비평 단락을 강한 평가와 절제된 평가의 두 버전으로 쓰고, 어떤 구절이 달라진 함축을 지지하는지 설명합니다. 이어 한 단락을 중립적 사건 보고로 바꾸되 극성·시간·전언 출처를 지키고 빠진 문체 효과를 명시하세요. 셋째 과장이 기억의 한계를 드러내는지 가리는지 논하는 의견문을 쓰고 가장 강한 반론을 공정하게 다룹니다. 빈 봉투의 동기, 실제 작가 의도, 전원 동의를 추가하지 마세요. 기사의 과장 제목도 정정하고 원문과 다시 대조해 재작성하세요. 자유 의미·비평의 설득력은 미채점입니다.',
      'Write three complete responses. First review the work with criteria, strengths, limits and cited passages. Place event chronology beside narration order, retaining unknown times. Second write strong and restrained versions of a critical paragraph and explain source support for changed implications; then recast one paragraph as neutral reporting, preserving polarity, time and hearsay and identifying lost stylistic effects. Third argue whether exaggeration reveals or conceals the limits of memory, treating the strongest objection fairly. Do not add envelope motives, the real author’s intent or unanimous agreement. Correct the article’s exaggerated headline and revise against the sources. Free meaning and critical persuasiveness remain unscored.',
      'Schreibe drei vollständige Antworten. Rezensiere zuerst das Werk mit Kriterien, Stärken, Grenzen und Textbelegen. Stelle Ereignisfolge und Erzählfolge nebeneinander und lasse unbekannte Zeiten offen. Schreibe zweitens einen stark und einen zurückhaltend wertenden kritischen Absatz und erkläre Textbelege für veränderte Implikationen; formuliere danach einen Absatz als neutralen Bericht um, mit erhaltener Polarität, Zeit und Quellenangabe und benannten verlorenen Stileffekten. Erörtere drittens, ob Übertreibung Erinnerungsgrenzen zeigt oder verdeckt, und behandle den stärksten Einwand fair. Ergänze weder Umschlagmotive noch reale Autorenabsicht oder Einstimmigkeit. Korrigiere die übertriebene Überschrift und überarbeite anhand der Quellen. Inhalt und Überzeugungskraft bleiben unbewertet.')
    def writing(args):
        return packet(criticism(args)+'\n'+article(args),[
          free_text('review',loc('근거 있는 작품 리뷰','Evidence-based literary review','Textgestützte Rezension'),rubric),
          free_text('versions',loc('두 평가 버전·중립 재서술·변화 해설','Two evaluations, neutral recasting and commentary','Zwei Wertungen, neutrale Fassung und Kommentar'),rubric),
          free_text('argument',loc('반론을 갖춘 과장 효과 의견문','Argument on exaggeration with a counterargument','Erörterung zur Übertreibung mit Einwand'),rubric),
        ],'form')
    tasks.append(task('KP26','writing:01','writing',loc('문체를 바꾸며 사건을 보존하는 비평','Criticism preserving events across styles','Kritik mit erhaltenen Ereignissen bei Stilwechsel'),rubric,writing(p),writing(a)))
    speech=loc('반말에 합의한 가까운 독자에게 두 비평을 공정하게 소개하고 네 해석의 기준과 구절을 설명하세요. 다른 독자에게는 같은 내용을 해요체로 바꾸되 사건·시간·출처는 유지합니다. 불편한 평가 표현을 인물 전체나 작가의 속마음 판단으로 넓히지 말고 상대에게 다른 읽기를 확인할 기회를 주세요. 같은 단락을 절제된 낭독과 표현적 낭독으로 각각 녹음하고 재생해 실제 들린 휴지·강조와 텍스트의 근거를 나란히 메모합니다. 듣지 못한 감정은 미상이고 표현적 목소리도 실제 분노를 증명하지 않아요. 모어가 다른 동료에게 한국어로 일쑤를 항상으로 바꾸는 오류와 버리다를 무조건 후회로 옮기는 오류를 짚으세요. 원래 화행과 의미 단위를 지켜 다시 말합니다. 자유 해석·낭독 효과는 미채점입니다.',
      'Fairly present both critiques to a close reader with whom casual speech is agreed, giving criteria and passages for your reading. Recast politely for another reader without changing events, time or attribution. Do not extend an uncomfortable evaluation into judgement of the whole character or author’s mind; invite a different reading. Record restrained and expressive readings of the same paragraph, replay and note actually heard pauses and emphasis alongside textual evidence. Unheard emotions remain unknown and expressive delivery does not prove real anger. Explain in Korean to a colleague with another first language why frequent does not mean always and 버리다 does not always mean regret. Rephrase preserving speech act and meaning units. Interpretation and reading effects remain unscored.',
      'Stelle einer vertrauten Person mit vereinbartem informellem Register beide Kritiken fair vor und begründe deine Lesart mit Kriterien und Textstellen. Formuliere für weitere Leser höflich um, ohne Ereignisse, Zeit und Quellen zu verändern. Erweitere unangenehme Wertungen nicht zum Urteil über die ganze Figur oder den Geist des Autors; ermögliche andere Lesarten. Nimm denselben Absatz zurückhaltend und ausdrucksvoll auf, höre ihn an und notiere tatsächlich gehörte Pausen und Betonung neben Textbelegen. Ungehörte Gefühle bleiben offen; ausdrucksvoller Vortrag beweist keinen wirklichen Ärger. Erkläre einer Person anderer Erstsprache auf Koreanisch, warum häufig nicht immer und 버리다 nicht stets Reue bedeutet. Formuliere mit erhaltenem Sprechakt und Sinneinheiten erneut. Deutung und Vortragswirkung bleiben unbewertet.')
    tasks.append(task('KP26','speaking:01','speaking',loc('두 해석과 두 낭독을 비교하는 대화','Discuss two readings and two deliveries','Zwei Lesarten und Vortragsweisen besprechen'),speech,packet(criticism(p),[]),packet(criticism(a),[])))
    return tasks


if __name__=='__main__':
    write_source('KP26',kp26())
