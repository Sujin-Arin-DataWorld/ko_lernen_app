"""KP28 reported instructions, evaluative naming and conversational repair."""
from phase_task_authoring import choice, free_text, grammar_task, loc, packet, task, write_source
from author_phase_a1_production import production


def kp28():
    rows=[
      ('G6:이라고2',loc('이 문맥의 이라고는 이름과 실제 효과를 대비하며 낮추어 평가합니다. 단순 인용 표지와 구별해요.','Here naming contrasts with actual effects to convey disparagement; distinguish a neutral quotation marker.','Hier kontrastiert die Benennung mit der tatsächlichen Wirkung und wertet ab; unterscheide eine neutrale Zitatmarkierung.'),('도움이라고 내민 것이 오히려 짐이 되었다. 화자는 그 도움을 낮추어 평가했다.','도움이라는 명칭과 짐이 된 효과 대비','도움의 효과를 전적으로 칭찬'),('조언이라고 한 말이 설명도 없이 명령뿐이었다. 화자는 그 말을 비판했다.','조언 명칭에 대한 비판적 평가','조언이라는 단어를 중립적으로 인용만 함')),
      ('G6:이라고는',loc('그 범주에 속하는 것을 최소한으로 한정하며 불만이 섞일 수 있어요. 무엇이 있는지는 없다는 말과 다릅니다.','Restrict what counts in a category to a minimum, possibly with dissatisfaction. Something limited is not nothing.','Beschränke eine Kategorie auf ein Minimum, möglicherweise mit Unmut. Etwas Begrenztes ist nicht nichts.'),('대답이라고는 짧은 한마디뿐이었다. 더 자세한 설명은 없었다.','한마디는 있었으나 설명이 부족함','대답이 전혀 없었음'),('근거라고는 출처 없는 메모 하나뿐이었다.','메모 하나 존재, 근거의 빈약함 평가','출처 있는 여러 독립 자료 존재')),
      ('G6:깨나',loc('양이나 정도가 상당하다는 평가입니다. 칭찬·비꼼은 앞뒤 말로 구별하며 항상 비꼼으로 읽지 않아요.','Evaluate a considerable amount or degree. Context distinguishes praise from sarcasm; sarcasm is not automatic.','Bewerte eine beträchtliche Menge oder einen Grad. Lob und Spott unterscheiden sich durch den Kontext; Spott ist nicht automatisch gegeben.'),('시간깨나 들였네요. 꼼꼼히 확인해 주셔서 도움이 됐어요.','상당한 시간과 명시적 감사','깨나만으로 비난 확정'),('시간깨나 들였네요. 그런데 확인한 항목이 없어요. 이 말은 칭찬이 아니에요.','상당한 시간과 명시적인 비판','시간을 전혀 쓰지 않았다는 사실')),
      ('G6:을랑',loc('특정 화제를 한정해 당부해요. 이 표현은 일상 기본형보다 표시적인 말투이며 범위를 다른 의무까지 넓히지 않습니다.','Mark off a topic for an injunction or request. This is a marked style rather than the everyday default; do not expand its scope to other duties.','Grenze ein Thema für eine Bitte oder Aufforderung ab. Die Form ist stilistisch markiert und kein Alltagsstandard; erweitere ihren Umfang nicht auf andere Pflichten.'),('그 걱정을랑 잠시 잊어 두세요. 점검 약속은 그대로입니다.','걱정 잠시 내려놓기, 점검 유지','점검 약속까지 모두 취소'),('그 일정을랑 먼저 확인하세요. 비용 결정은 나중입니다.','일정 먼저 확인, 비용 결정은 별개','일정 확인으로 비용 승인 완료')),
      ('G6:이라면',loc('여기서는 어떤 대상에 관한 강한 성향·반응을 강조합니다. 단순 자격 조건이나 의무와 구별해요.','Here the form highlights a strong disposition toward a topic, not mere eligibility or duty.','Hier hebt die Form eine starke Neigung zu einem Thema hervor, nicht bloße Berechtigung oder Pflicht.'),('책이라면 밤을 새워서라도 읽는 사람이다.','책에 관한 강한 독서 성향','누구나 밤새 읽어야 할 의무'),('기록이라면 작은 메모도 모아 두는 사람이다.','기록에 관한 강한 수집 성향','모든 메모의 사실성을 검증 완료')),
      ('G6:-자면2',loc('누군가가 권유할 경우라는 인용 조건입니다. 권유의 내용과 아직 제시 여부가 미정인 조건을 함께 보존해요.','A condition about someone making a suggestion. Preserve both its content and the fact that it has not necessarily been made.','Eine Bedingung für den Fall eines Vorschlags. Erhalte dessen Inhalt und dass er noch nicht tatsächlich gemacht sein muss.'),('민서가 함께 검토하자면 어떻게 답하겠어요? 아직 그런 권유는 없었어요.','민서가 함께 검토하자고 권할 경우의 반응','민서가 이미 검토를 명령함'),('지수가 내일 만나자면 일정을 확인할게요. 아직 제안은 안 했어요.','지수가 내일 만나자고 할 경우 확인','내일 만남 이미 확정')),
      ('G6:-던가1',loc('상대가 직접 경험한 과거를 돌아보며 묻습니다. 답이 나오기 전에는 그 상태를 확정하지 않아요.','Ask about the listener’s past direct experience; do not assert the state before their answer.','Frage nach eigener vergangener Erfahrung des Gegenübers; stelle den Zustand vor der Antwort nicht als Tatsache dar.'),('직접 가 보니 그곳은 조용하던가요? 저는 가 보지 않았어요.','방문한 상대의 경험에 관한 질문','질문자가 직접 조용함 확인'),('직접 읽어 보니 설명은 자세하던가요? 저는 아직 못 읽었어요.','읽은 상대에게 자세함을 질문','질문자가 자세함을 검증 완료')),
      ('G6:-는다던가1',loc('이 항목의 지시 인용 변형 하라던가는 전달된 명령의 내용을 기억에서 확인하는 질문입니다. 사실 진술이나 새 명령과 구별해요.','The instruction-reporting variant 하라던가 here asks for recall of a reported command, not a fact or a new order.','Die Anweisungsvariante 하라던가 fragt hier nach dem erinnerten Inhalt eines berichteten Befehls, nicht nach einer Tatsache oder einem neuen Befehl.'),('자료를 누구에게 제출하라던가요? 전달받은 지시의 수신자를 묻습니다.','전달된 제출 지시의 수신자 확인','자료가 이미 제출됐다고 확정'),('요약을 어디에 올리라던가요? 전해 들은 지시를 확인합니다.','전달된 게시 지시의 장소 확인','지금 화자가 새 게시 명령')),
      ('G6:-던2',loc('서로 반말하는 친밀한 관계에서 상대의 과거 경험을 되물어요. 회고 관형형이나 선택의 든과 구별합니다.','Ask about past experience in an agreed close casual relationship; distinguish an attributive recollection form or alternative 든.','Frage in vereinbart vertrauter Beziehung nach vergangener Erfahrung; unterscheide attributives 던 und alternatives 든.'),('[반말에 합의한 친구] 그 사람이 어제 뭐라고 하던?','상대가 들은 어제 말을 친밀하게 질문','화자가 어제 발언을 확정 보고'),('[반말에 합의한 친구] 직접 가 보니 사람은 많던?','상대의 방문 경험을 친밀하게 질문','질문자가 인원 수를 직접 검증')),
      ('G6:-으래서야',loc('전달된 요구의 타당성을 반문합니다. 요구를 정당화하거나 그대로 새로 명령하는 말로 읽지 않아요.','Challenge the validity of a reported demand, without endorsing or reissuing it.','Stelle die Angemessenheit einer berichteten Forderung infrage, ohne sie zu rechtfertigen oder neu zu erteilen.'),('확인할 시간도 없이 결정하래서야 되겠습니까?','확인 시간 없는 결정 요구에 이의','즉시 결정하라는 새 명령'),('출처도 모른 채 동의하래서야 되겠습니까?','미상 출처 상태의 동의 요구에 이의','출처 무관하게 동의 의무 승인')),
      ('G3:이라고1',loc('명칭을 인용하는 표지입니다. 같은 표기의 평가적 용례와 달리 이 문맥에는 폄하 근거가 없습니다.','Quote a label. Unlike evaluative uses with the same spelling, this context provides no grounds for disparagement.','Zitiere eine Bezeichnung. Anders als gleich geschriebene wertende Verwendungen bietet dieser Kontext keinen Beleg für Abwertung.'),('작성자는 이를 잠정 결론이라고 불렀다. 그 명칭을 그대로 옮긴다.','작성자 명칭 인용','잠정 결론을 반드시 조롱'),('진행자는 이 문서를 검토 메모라고 소개했다. 명칭만 기록한다.','진행자의 문서 명칭 인용','문서를 가치 없다고 폄하')),
    ]
    tasks=[grammar_task('KP28',i,*r) for i,r in enumerate(rows,1)]
    prod=[
      ('G6:이라고2',('도움 명칭 비판 / 내민 것이 오히려 짐 / 도움이라고','도움이라고 내민 것이 오히려 짐이 되었다.','그 도움은 전적으로 유익했다.'),('조언 명칭 비판 / 한 말이 설명 없이 명령뿐 / 조언이라고','조언이라고 한 말이 설명도 없이 명령뿐이었다.','그 조언에는 자세한 설명이 있었다.')),
      ('G6:이라고는',('대답 / 짧은 한마디뿐 / 이라고는','대답이라고는 짧은 한마디뿐이었다.','대답이 전혀 없었다.'),('근거 / 출처 없는 메모 하나뿐 / 라고는','근거라고는 출처 없는 메모 하나뿐이었다.','출처가 다른 근거가 여러 개 있었다.')),
      ('G6:깨나',('상당한 시간 / 깨나 / 뒤에 꼼꼼한 확인 감사','시간깨나 들였네요. 꼼꼼히 확인해 주셔서 도움이 됐어요.','시간을 전혀 쓰지 않았네요.'),('상당한 시간 / 깨나 / 확인 항목 없음 명시 / 칭찬 아님','시간깨나 들였네요. 그런데 확인한 항목이 없어요. 이 말은 칭찬이 아니에요.','시간을 전혀 들이지 않았다는 뜻이에요.')),
      ('G6:을랑',('표시적 당부 인용 / 그 걱정 잠시 잊기 / 걱정을랑 / 점검 약속 유지','그 걱정을랑 잠시 잊어 두세요. 점검 약속은 그대로입니다.','점검 약속을 모두 취소하세요.'),('표시적 당부 인용 / 그 일정 먼저 확인 / 일정을랑 / 비용 나중','그 일정을랑 먼저 확인하세요. 비용 결정은 나중입니다.','일정 확인으로 비용 결정도 끝났습니다.')),
      ('G6:이라면',('그 사람의 책에 관한 강한 성향 / 책이라면 밤을 새워서라도 읽는 사람이다','책이라면 밤을 새워서라도 읽는 사람이다.','누구나 밤새 책을 읽어야 한다.'),('그 사람의 기록 수집 성향 / 기록이라면 작은 메모도 모아 두는 사람이다','기록이라면 작은 메모도 모아 두는 사람이다.','그 사람은 모든 메모의 사실성을 검증했다.')),
      ('G6:-자면2',('민서가 함께 검토하자고 권할 경우 / 반응 질문 / 검토하자면','민서가 함께 검토하자면 어떻게 답하겠어요?','민서가 이미 함께 검토하라고 명령했어요.'),('지수가 내일 만나자고 제안할 경우 / 내 일정 확인 약속 / 만나자면','지수가 내일 만나자면 일정을 확인할게요.','지수와 내일 만나기로 확정했어요.')),
      ('G6:-던가1',('방문한 상대에게 / 그곳 조용했는지 / 직접 가 보니 / 조용하던가요','직접 가 보니 그곳은 조용하던가요?','제가 직접 가서 그곳이 조용함을 확인했어요.'),('읽은 상대에게 / 설명 자세했는지 / 직접 읽어 보니 / 자세하던가요','직접 읽어 보니 설명은 자세하던가요?','제가 읽어서 설명이 자세함을 검증했어요.')),
      ('G6:-는다던가1',('전달된 명령의 수신자 확인 질문 / 자료 누구에게 제출 / 제출하라던가요','자료를 누구에게 제출하라던가요?','자료를 이미 제출했습니다.'),('전달된 명령의 장소 확인 질문 / 요약 어디에 올리다 / 올리라던가요','요약을 어디에 올리라던가요?','요약을 지금 여기 올리세요.')),
      ('G6:-던2',('반말 합의 친구에게 어제 들은 발언 질문 / 그 사람 어제 무엇이라고 말했는지 / 뭐라고 하던','그 사람이 어제 뭐라고 하던?','그 사람이 어제 동의했다고 확정한다.'),('반말 합의 친구의 직접 방문 경험 질문 / 사람 많았는지 / 많던','직접 가 보니 사람은 많던?','내가 직접 인원을 확인했어.')),
      ('G6:-으래서야',('시간 없이 결정하라는 전달 요구 비판 / 결정하래서야, 격식 반문','확인할 시간도 없이 결정하래서야 되겠습니까?','확인 없이 지금 결정하십시오.'),('출처 모른 채 동의하라는 전달 요구 비판 / 동의하래서야, 격식 반문','출처도 모른 채 동의하래서야 되겠습니까?','출처와 관계없이 동의해야 합니다.')),
      ('G3:이라고1',('작성자가 사용한 명칭 / 잠정 결론 / 불렀다 / 인용이라고','작성자는 이를 잠정 결론이라고 불렀다.','작성자는 이를 확정 결론이라고 불렀다.'),('진행자 문서 명칭 소개 / 검토 메모 / 인용라고','진행자는 이 문서를 검토 메모라고 소개했다.','진행자는 이 문서를 최종 승인서라고 소개했다.')),
    ]
    tasks+=production('KP28',tasks,prod)
    h=loc('명칭·문자 내용·평가·인용 출처·확인 질문을 분리하세요. 답변 흐름으로 질문과 이의를 구별하며 남은 모호성은 표시합니다. 같은 말끝만으로 비꼼이나 동기를 확정하지 않아요.','Separate naming, literal content, evaluation, quotation source and checking questions. Use responses to distinguish questions from challenges, retaining ambiguity. An ending alone establishes neither irony nor motive.','Trenne Benennung, Wortinhalt, Wertung, Zitatherkunft und Rückfrage. Unterscheide Fragen und Einwände anhand der Antworten und erhalte Mehrdeutigkeit. Ein Satzende belegt weder Ironie noch Motiv.')
    p=('가람기록모임','민서','준호',6,'목요일')
    a=('솔빛자료모임','지수','도하',9,'토요일')
    def interview(args):
        name,first,second,count,day=args
        return f'''[가상 {name} 인터뷰와 회의 전사. 참여자는 동등한 성인이다.]
면담자: 자료를 누구에게 제출하라던가요?
{first}: 제가 전달받은 문장에는 자료 담당자에게 제출하라고 적혀 있었어요. 처음 그 지시를 만든 사람은 이 기록에 없어요. 제출을 마쳤다는 말은 아닙니다.
면담자: 담당자가 함께 검토하자면 어떻게 답하겠어요?
{first}: 아직 그런 제안은 없었어요. 제안이 오면 제 일정을 확인한 뒤 답하겠어요. {day}에 제가 무조건 참석한다는 뜻은 아닙니다.
면담자: 직접 가 보니 작업실은 조용하던가요?
{second}: 제가 방문한 때에는 조용했어요. 다른 날은 모릅니다. 이 질문은 제 경험을 실제로 묻는 것이었어요.
면담자: 확인할 시간도 없이 결정하래서야 되겠습니까?
{first}: 지금은 동의하기 어렵다는 이의로 들려요. 원래 요구의 정확한 문장과 확인 시간을 다시 요청할 수 있을까요?
면담자: 맞습니다. 새로 결정하라는 명령을 내린 것이 아닙니다.
장면 A. {second}: 시간깨나 들였네요. 확인한 {count}개 항목이 깔끔하게 정리됐어요. 도움이 됐어요.
{first}: 고맙습니다. 이 표는 잠정 결론이라고 이름 붙였어요. 정확도가 검증됐다는 뜻은 아니에요.
장면 B. 다른 상황에서 같은 말. {second}: 시간깨나 들였네요. 그런데 확인한 항목이 없어요. 이 말은 칭찬이 아니에요. 대답이라고는 한마디뿐이었고요.
{first}: 제 노력을 낮추는 말로 들려 불편했어요. 실제로 부족하다고 보는 항목을 설명해 주시겠어요?
{second}: 확인 항목과 설명이 빠졌다는 뜻이었습니다. 당신의 모든 능력을 판단하려는 말은 아니었어요. 아까 도움이라고 내민 것이 오히려 짐이 되었다고 말한 것도 제안의 효과에 관한 평가였습니다.
중재자: 확인된 항목이 있는 A와 없는 B를 같은 사건으로 합치지 않겠습니다. 발언권을 다시 {first}에게 드리겠습니다. 그 걱정을랑 잠시 잊어 두시되 확인 약속은 유지하자는 문장은 걱정만 화제로 한정합니다. 새 의무를 만들지는 않습니다. {day}은 재확인 제안 날짜이며 합의된 참석 일정은 아직 없습니다.'''
    def listen(args):
        return packet(interview(args),[
          choice('command',loc('첫 질문에서 확인하는 것은?','What does the first question check?','Was prüft die erste Frage?'),['전달된 지시의 제출 수신자','이미 완료된 제출의 성공 여부'],h),
          choice('source',loc('출처에서 미상인 것은?','Which source is unknown?','Welche Quelle bleibt unbekannt?'),['원래 지시를 만든 사람','지시에 적힌 자료 담당자 수신자'],h),
          choice('conditional',loc('함께 검토하자면이 유지해야 할 것은?','What must the conditional suggestion preserve?','Was muss der bedingte Vorschlag erhalten?'),['담당자의 권유가 올 경우와 일정 확인 후 응답','이미 참석 약속 완료'],h),
          choice('question',loc('조용하던가요의 답이 보증하는 범위는?','What scope does the quietness answer establish?','Welchen Umfang belegt die Antwort zur Ruhe?'),['응답자가 방문한 때만','모든 날과 질문자의 직접 확인'],h),
          choice('challenge',loc('결정하래서야의 기능은?','What function does the decision challenge have?','Welche Funktion hat die Entscheidungsgegenfrage?'),['시간 없는 결정 요구에 이의','새 즉시 결정 명령'],h),
          choice('irony',loc('깨나의 두 장면을 가르는 근거는?','What distinguishes the two 깨나 scenes?','Was unterscheidet die beiden 깨나-Szenen?'),['A의 도움 감사와 B의 명시적 비칭찬','깨나 형태만으로 둘 다 비난'],h),
          choice('scope',loc('불편과 의도에 관해 구별할 것은?','What distinction matters for discomfort and intent?','Was ist bei Unbehagen und Absicht zu trennen?'),['청자의 불편과 화자의 설명, 전체 능력 판단 미확정','불편했으므로 상대의 악의 입증'],h),
        ],'audio')
    tasks.append(task('KP28','listening:01','listening',loc('인용된 지시와 두 가지 반문','Reported instructions and two question functions','Berichtete Anweisungen und zwei Fragefunktionen'),h,listen(p),listen(a)))
    def article(args):
        name,first,second,count,day=args
        return f'''[가상 기사: {name}의 초안 확인 논의]
기자는 회의에서 {first}가 표를 잠정 결론이라고 소개하는 말을 들었다고 썼다. 잠정 결론은 명칭의 직접 인용이다. 기사에는 실제 정확도 측정이나 최종 승인을 확인한 자료가 없다. {second}의 발언 가운데 “도움이라고 내민 것이 오히려 짐이 되었다”라는 문장을 인용하면서, 도움이라는 이름과 실제 부담의 대비가 제안에 대한 비판을 드러낸다고 해석했다. 이 해석의 주체는 기자이며 특정인의 인격 전체를 평가하는 사실은 아니다.
기자는 면담자의 “자료를 누구에게 제출하라던가요?”와 {first}의 응답을 함께 실었다. 지시에는 자료 담당자에게 내라고 적혀 있었으나 최초 작성자는 미상이라고 했다. 면담자→{first}가 전달받은 문장→원래 지시자라는 층위를 구별해야 한다. 여러 사람이 이 같은 전달문을 되풀이해도 독립된 여러 출처가 생기지는 않는다.
{second}는 방문한 때 작업실이 조용했다고 말했다. 기자는 직접 그 작업실을 방문했다고 쓰지 않았다. 한편 {first}는 담당자가 함께 검토하자면 일정을 확인하겠다고 답했다. 아직 권유가 없었으므로 {day} 참석 약속으로 보도할 수 없다.
[부정확한 축약]
여러 독립 출처가 {first}의 자료 제출 완료와 {day} 참석을 확인했다.
[정정]
전달 지시의 수신자와 조건부 반응이 확인되었을 뿐이다. 제출 완료, 최초 지시자, 참석 합의는 이 기사에서 확인되지 않았다.'''
    def news(args):
        return packet(article(args),[
          choice('naming',loc('잠정 결론이라고의 기능은?','What is the function of the quoted label?','Welche Funktion hat die zitierte Bezeichnung?'),['명칭 인용, 폄하 자동 확정 아님','최종 승인 사실 확인'],h),
          choice('evaluation',loc('도움이라고의 비판 범위는?','What is the scope of the criticism of help?','Worauf bezieht sich die Kritik an Hilfe?'),['이름과 부담 효과의 대비, 인격 전체 아님','그 인물의 모든 능력이 없음'],h),
          choice('chain',loc('같은 전달문 반복의 출처 수는?','What does repeating the same report mean for sources?','Was bedeutet die Wiederholung derselben Mitteilung für Quellen?'),['반복만으로 독립 출처가 늘지 않음','발언자 수만큼 독립 검증 완료'],h),
          choice('witness',loc('조용함의 직접 경험자는?','Who directly experienced the quietness?','Wer hat die Ruhe unmittelbar erlebt?'),[args[2],'기자와 면담자 모두'],h),
          choice('correction',loc('축약에서 삭제해야 할 과잉은?','What overstatement must the summary lose?','Welche Übertreibung muss die Kurzfassung verlieren?'),['제출 완료·참석 합의·독립 검증 확정','수신자가 자료 담당자라는 전달 내용'],h),
        ])
    tasks.append(task('KP28','reading:01','reading',loc('명칭·평가·중첩 출처의 기사','Article on naming, evaluation and nested sources','Artikel über Benennung, Wertung und Quellenebenen'),h,news(p),news(a)))
    def literary(args):
        name,first,second,count,day=args
        return f'''[같은 가상 인물의 문학적 재서술: 말의 무게]
{first}는 표의 모서리에 손을 얹었다. 책이라면 밤을 새워서라도 읽는 사람이었지만, 오늘 표에 관해서는 그 성향만으로 정확도를 말할 수 없었다. {second}가 “시간깨나 들였네”라고 말했다. 그 문장 뒤에는 아직 감사도 항의도 없었다. {first}는 언중유골인가 생각했지만, 그 생각은 청자의 추측이었다.
두 사람은 서로 반말하기로 합의한 가까운 성인 친구였다. “그 사람이 어제 뭐라고 하던?” {first}가 물었다. {second}는 어제 들은 문장을 정확히 기억하지 못한다고 답했다. 말을 기억하지 못한다는 응답이 원래 발언이 없었다는 증거는 아니다. “대답이라고는 한마디뿐이네”라는 말은 응답이 짧다는 평가였다. 한마디가 있었다는 사실까지 지워서는 안 된다.
“그 걱정을랑 잠시 잊어 둬. 확인 약속은 그대로야.” {second}가 말을 이었다. 화제 한정은 걱정에 걸렸고 확인 약속을 취소하지 않았다. 이 표시적인 말투를 모든 동료에게 쓰는 평범한 업무 언어라고 권할 수는 없다. {first}는 “말꼬리를 잡으려는 게 아니라, 누구 말인지 확인하고 싶어”라고 응답했다. 호칭 선택과 청자 대우는 대인 거리를 바꾸지만 없는 출처를 만들 수는 없다.
“그 사람이 함께 검토하자면 그때 답하자.” {second}가 말머리를 돌렸다. 누가 아직 하지 않은 권유를 할 경우라는 조건이 남았다. 두 사람은 질문을 더 듣기로 했지만 참석 날짜나 역할을 정하지 않았다. 서술자는 그들의 모든 속마음을 알린 것이 아니라 드러난 말과 {first}의 일부 생각을 서술했다.
[기사와 대비]
기사의 잠정 결론이라는 명칭과 문학의 책이라면이라는 성향 묘사는 서로 다른 정보다. 성향을 붙였다고 정확도가 검증되거나 기사에 없는 성격 결함이 사실이 되지는 않는다. 닫히지 않은 깨나의 해석과 원래 지시자의 미상 상태를 남겨 두는 것이 이 재서술의 범위다.'''
    def literature(args):
        return packet(literary(args),[
          choice('open',loc('뒤 맥락 없는 시간깨나 들였네는?','What about the remark without follow-up context?','Was gilt für die Bemerkung ohne Folgekontext?'),['칭찬·비꼼을 아직 확정하지 않음','반드시 비꼼이라고 확정'],h),
          choice('memory',loc('기억 못 한다는 응답은?','What does failure to remember establish?','Was belegt fehlende Erinnerung?'),['내용 미상, 원래 발언 부재 입증 아님','원래 발언이 전혀 없었음'],h),
          choice('minimal',loc('이라고는에서 보존할 사실은?','What fact must the minimising expression retain?','Welche Tatsache muss die Minimierung erhalten?'),['한마디는 있었다','아무 응답도 없었다'],h),
          choice('topic',loc('을랑의 범위는?','What is the scope of 을랑?','Welchen Umfang hat 을랑?'),['걱정 잠시 내려놓기, 확인 약속 유지','모든 확인 책임 소멸'],h),
          choice('portrait',loc('책에 관한 성향 묘사가 입증하지 않는 것은?','What does the reading disposition fail to prove?','Was belegt die Leseneigung nicht?'),['표의 정확도와 모든 내면','서술된 책에 관한 성향 자체'],h),
        ])
    tasks.append(task('KP28','reading:02','reading',loc('같은 인물의 문학적 명명과 여백','Literary naming and ambiguity around the same person','Literarische Benennung und Offenheit derselben Figur'),h,literature(p),literature(a)))
    rubric=loc('회의 기록과 중첩 인용의 해명문을 각각 완결된 글로 쓰세요. 기록에는 A와 B를 다른 장면으로 두고 문자 내용·화자의 평가·청자의 불편·화자가 나중에 설명한 범위를 나눕니다. 확인한 사실, 이견, 아직 미상인 출처·참석·역할을 표시하세요. 해명문에는 누가 누구에게 전달받은 지시인지 층위를 그리고 수신자를 묻는 질문을 제출 완료로 바꾸지 마세요. 담당자가 함께 검토하자고 권할 경우 일정 확인 뒤 응답하겠다는 조건문을 정보 손실 없이 풀어 씁니다. 누구·어디·어떤 자료·어느 제안을 확인해야 하는지 질문으로 바꾸되 원문에 없는 답을 채우지 않습니다. 기사와 문학의 이라고 기능과 깨나 해석 가능성을 비교하고 과장 축약을 고칩니다. 원문·응답 흐름을 다시 대조해 평가를 사실로 만든 문장을 수정하세요. 자유 의미·중개는 미채점입니다.',
      'Write complete meeting notes and a separate explanation of nested reporting. Keep A and B as distinct scenes; separate literal content, speaker evaluation, listener discomfort and the speaker’s later stated scope. Mark facts, disagreement and unknown sources, attendance and roles. Map who received whose instruction and do not turn a recipient question into completed submission. Unpack the conditional promise to check a schedule and respond if the coordinator suggests reviewing together. Form precise questions about who, where, which material and which proposal, without inventing answers. Compare quoting versus evaluative 이라고 and possible 깨나 readings in article and literature, correcting the exaggerated summary. Revise against the text and response sequence wherever evaluation became fact. Free meaning and mediation remain unscored.',
      'Schreibe vollständige Sitzungsnotizen und eine getrennte Erklärung verschachtelter Rede. Halte A und B als verschiedene Szenen auseinander; trenne Wortinhalt, Sprecherwertung, Unbehagen des Gegenübers und später erklärten Umfang. Markiere Fakten, Dissens und unbekannte Quellen, Teilnahme und Rollen. Zeichne nach, wer wessen Anweisung empfing, und mache die Empfängerfrage nicht zur erledigten Einreichung. Entfalte die Bedingung, bei einem gemeinsamen Prüfvorschlag erst den Terminplan zu prüfen und dann zu antworten. Formuliere präzise Fragen nach wer, wo, welchen Unterlagen und welchem Vorschlag, ohne Antworten zu erfinden. Vergleiche zitierendes und wertendes 이라고 sowie offene 깨나-Lesarten in Artikel und Literatur und korrigiere die übertriebene Kurzfassung. Überarbeite anhand von Text und Antwortfolge Stellen, an denen Wertung zur Tatsache wurde. Freier Inhalt und Sprachmittlung bleiben unbewertet.')
    def writing(args):
        return packet(interview(args)+'\n'+article(args)+'\n'+literary(args),[
          free_text('minutes',loc('사실·이견·미결을 보존한 회의 기록','Meeting notes preserving facts and disagreement','Sitzungsnotizen mit Fakten, Dissens und offenen Punkten'),rubric),
          free_text('clarification',loc('인용 조건 해명과 구체적 확인 질문','Explain the quoted condition and ask precise questions','Zitatbedingung erklären und präzise rückfragen'),rubric),
        ],'form')
    tasks.append(task('KP28','writing:01','writing',loc('모호한 인용을 풀어 쓰는 회의 기록','Meeting notes unpacking ambiguous reports','Sitzungsnotizen zur Entfaltung mehrdeutiger Rede'),rubric,writing(p),writing(a)))
    speech=loc('가까운 친구 둘의 합의된 반말 대화를 중개한 뒤 동료에게 해요체로 확인하고 공개 청중에게 합쇼체로 요점·근거·한계를 발표하세요. 시간깨나라는 말이 불편하게 들린 경험과 상대의 확정 의도를 나누고, 무엇이 부족하다는 뜻인지 물어 발언권을 돌려줍니다. 지시의 수신자, 원래 출처, 아직 오지 않은 권유의 조건을 구별하세요. 확인 없는 결정 요구에 대한 이의를 새 명령으로 바꾸지 말고, 모르는 질문은 확인 과제로 남깁니다. 회의 요약에는 합의와 미합의, 미정 역할을 함께 말하세요. 한국어로 인용 명칭을 폄하로 바꾸는 오류와 한마디뿐을 무응답으로 바꾸는 오류를 모어가 다른 동료에게 설명합니다. 문자·반어 해석의 근거를 대조하며 녹음·재생하고, 말의 무게와 선택권이 바뀌는 휴지·억양을 고쳐 다시 말하세요. 의미·억양·내적 의도는 미채점입니다.',
      'Mediate the close friends’ agreed casual exchange, clarify politely with a colleague and give a formal public briefing with points, grounds and limits. Separate discomfort at 시간깨나 from established intent; ask what is missing and return the floor. Distinguish instruction recipient, original source and the condition of a suggestion not yet made. Keep a challenge to a rushed decision from becoming a new order; leave unknown answers for checking. Summarise agreement, disagreement and open roles. In Korean explain to a colleague with another first language errors that turn a quoted label into disparagement and one brief reply into no reply. Compare evidence for literal and ironic readings, record and replay, and revise pauses or intonation changing force or choice. Meaning, prosody and inner intent remain unscored.',
      'Vermittle den vereinbart informellen Austausch vertrauter Freunde, kläre höflich mit einer weiteren Person und gib öffentlich eine förmliche Zusammenfassung mit Kernpunkten, Belegen und Grenzen. Trenne Unbehagen über 시간깨나 von belegter Absicht; frage nach dem Fehlenden und gib das Wort zurück. Trenne Anweisungsempfänger, ursprüngliche Quelle und Bedingung eines noch nicht gemachten Vorschlags. Mache den Einwand gegen eine überstürzte Entscheidung nicht zum neuen Befehl; lasse unbekannte Antworten zur Prüfung offen. Fasse Einigung, Dissens und offene Rollen zusammen. Erkläre einer Person anderer Erstsprache auf Koreanisch Fehler, die Zitatbenennung zur Abwertung und eine knappe Antwort zur Nichtantwort machen. Vergleiche Belege wörtlicher und ironischer Lesart, nimm auf, höre zu und verbessere Pausen oder Intonation, die Nachdruck oder Wahlfreiheit ändern. Inhalt, Prosodie und innere Absicht bleiben unbewertet.')
    tasks.append(task('KP28','speaking:01','speaking',loc('인용을 확인하고 발언권을 돌려주는 중개','Clarify reports and return the floor','Berichtete Rede klären und das Wort zurückgeben'),speech,packet(interview(p)+'\n'+literary(p),[]),packet(interview(a)+'\n'+literary(a),[])))
    return tasks


if __name__=='__main__':
    write_source('KP28',kp28())
