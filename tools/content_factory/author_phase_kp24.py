"""KP24 literary stance, relationship and register repair; unsigned source."""
from phase_task_authoring import choice, free_text, grammar_task, loc, packet, task, write_source
from author_phase_a1_production import production


def kp24():
    rows=[
      ('G5:-거라',loc('친밀도와 위계가 명시된 장면의 명령을 읽어요. 여기서는 연극 속 보호자가 아이에게 하는 말입니다. 동등한 성인에게 기본 공손 표현으로 쓰지 않아요.','Read a command in an explicitly marked relationship and hierarchy. Here it is a guardian addressing a child in a play, not a default polite form for equal adults.','Lies einen Befehl in einer ausdrücklich bezeichneten Beziehung und Hierarchie. Hier spricht eine Betreuungsperson im Theaterstück zu einem Kind; es ist keine höfliche Standardform unter gleichgestellten Erwachsenen.'),('[연극 대사: 보호자가 아이에게] 먼저 들어가거라.','보호자가 아이에게 들어가라고 명령','동등한 성인에게 선택을 묻는 공손한 질문'),('[연극 대사: 보호자가 아이에게] 여기 앉거라.','보호자가 아이에게 앉으라고 명령','화자가 자기가 앉겠다고 약속')),
      ('G5:-고말고',loc('상대 말에 강하게 긍정하거나 동의해요. 어떤 명제에 동의하는지 문맥으로 제한하며 실행 약속까지 넓히지 않아요.','Strongly affirm or agree, limited to the proposition in context. Do not extend agreement into a promise to act.','Bejahe oder stimme nachdrücklich zu, begrenzt auf die Aussage im Kontext. Erweitere die Zustimmung nicht zur Handlungszusage.'),('그 사정은 이해하고말고요. 다만 대신 맡겠다는 약속은 아니에요.','사정 이해에 강한 긍정','대신 업무를 맡겠다고 확약'),('수고한 건 알고말고요. 결과에 동의하는지는 별개예요.','노고를 안다는 강한 긍정','모든 결과를 승인')),
      ('G5:-네2',loc('새롭게 알아차린 사실에 평가가 섞이는 감탄이에요. 기쁨·놀람·냉소 중 무엇인지는 말끝 하나로 결정하지 않아요.','Express noticing with evaluation. The ending alone does not determine joy, surprise or sarcasm.','Drücke ein Bemerken mit Bewertung aus. Das Satzende allein bestimmt weder Freude noch Überraschung oder Sarkasmus.'),('생각보다 꼼꼼하게 준비했네. 이 표 덕분에 확인하기 편하겠어.','도움이 된다는 뒷말이 긍정 해석을 뒷받침','네만으로 언제나 냉소 확정'),('또 일정을 바꿨네. 나는 이번 변경 이유를 아직 몰라.','변경을 알아차렸지만 감정은 미확정','네만으로 기쁨을 확정')),
      ('G5:-는걸',loc('새로 알게 된 사실로 앞의 기대를 가볍게 반박하거나 정정해요. 종결 용례이며 목적어를 나타내는 것을의 준말과 구별해요.','Lightly correct an expectation with newly noticed information. This is sentence-final, not the object contraction of 것을.','Korrigiere eine Erwartung leicht anhand neu bemerkter Information. Dies ist ein Satzende, nicht die Objektverkürzung von 것을.'),('쉽다고 했지만 직접 해 보니 생각보다 어려운걸.','쉽다는 기대를 경험으로 정정','쉽다는 말에 그대로 동의'),('자리 없다고? 안쪽에는 아직 남아 있는걸.','자리가 없다는 말을 관찰로 정정','자리가 전혀 없다는 재확인')),
      ('G5:-으려고2',loc('상대 의도를 되묻는 종결 표현이에요. 일을 감당할 수 있을지 걱정하거나 의심할 수 있지만 능력 비난으로 단정하지 않아요.','A sentence-final question checks another person’s intention. It may convey concern or doubt about feasibility without necessarily attacking ability.','Eine abschließende Frage prüft die Absicht des Gegenübers. Sie kann Sorge oder Zweifel an der Machbarkeit ausdrücken, ohne zwingend Fähigkeiten anzugreifen.'),('그 많은 일을 혼자 다 하려고? 힘들면 나눠도 돼.','혼자 하려는 의도 확인과 부담 우려','상대가 무능하다고 확정'),('지금 혼자 출발하려고? 길을 아는지 먼저 물어본 거야.','혼자 출발할 의도와 정보 확인','상대에게 출발을 반드시 금지')),
      ('G5:-게 생겼다',loc('현재 정황에서 닥칠 결과를 평가해요. 예측을 이미 일어난 사실이나 확정 운명으로 바꾸지 않아요.','Assess an impending outcome from current circumstances. Do not turn a prediction into an accomplished fact or inevitable fate.','Bewerte eine drohende Folge aus der aktuellen Lage. Mache eine Prognose nicht zur eingetretenen Tatsache oder unabwendbaren Gewissheit.'),('이대로라면 약속을 못 지키게 생겼어요. 일정을 다시 확인해요.','현재 조건 지속 시 약속 불이행 우려','약속을 이미 어긴 사실'),('비가 계속 오면 행사를 미루게 생겼어요. 아직 결정은 없어요.','비 지속에 따른 연기 가능성','행사 연기 이미 확정')),
      ('G5:-는 척하다',loc('실제와 다르게 보이도록 행동한다고 서술해요. 여기서는 서술자가 실제 앎을 명시합니다. 고개를 끄덕였다는 관찰만으로 속내를 단정하면 안 돼요.','Describe behaviour presented as contrary to reality. Here the narrator explicitly states actual knowledge. A nod alone cannot establish inner intent.','Beschreibe Verhalten als Gegensatz zur Wirklichkeit. Hier nennt die Erzählinstanz das tatsächliche Wissen ausdrücklich. Ein Nicken allein belegt keine innere Absicht.'),('그는 내용을 이미 알았지만 모르는 척했다. 서술자가 그의 앎을 밝힌다.','실제로 알면서 모르는 듯 행동','실제로 전혀 몰랐음'),('그는 지루했지만 흥미롭게 듣는 척했다. 서술자가 지루함을 밝힌다.','실제 지루함과 흥미로운 듯한 행동 차이','실제로 깊은 흥미를 느꼈음')),
      ('G5:-기만 하다',loc('다른 변화 없이 그 행동이나 상태만 이어짐을 제한해 평가해요. 불만의 가능성은 문맥에서 확인합니다.','Restrict the description to one continuing action without another change. Check context for possible dissatisfaction.','Beschränke die Beschreibung auf eine fortgesetzte Handlung ohne weitere Änderung. Prüfe möglichen Unmut im Kontext.'),('논의가 반복되기만 하고 결정은 나지 않았다.','반복 논의만 있고 결정 없음','반복 논의 뒤 결정 완료'),('설명을 듣기만 했고 동의한다는 말은 하지 않았다.','청취는 했지만 명시 동의는 없음','들었으므로 동의도 확정')),
      ('G5:따라',loc('오늘따라처럼 특정 때가 유독 두드러진다는 조사예요. 사람을 따라가거나 기준에 따른다는 뜻과 구별해요.','As in today in particular, this particle singles out an occasion. Distinguish following a person or acting according to a criterion.','Wie in gerade heute hebt diese Partikel einen Zeitpunkt hervor. Unterscheide das Folgen einer Person oder eines Maßstabs.'),('오늘따라 말이 잘 안 나오네요. 평소에는 이렇지 않아요.','유독 오늘의 두드러진 상태','항상 같은 상태라고 설명'),('그날따라 질문이 많았어요. 평소보다 오래 걸렸어요.','그날 특히 많았던 질문','누군가를 따라 질문함')),
      ('G5:이라든가',loc('가능한 대상을 몇 가지 예로 들어요. 예시를 닫힌 전체 목록이나 반드시 모두 제출할 조건으로 읽지 않아요.','Give examples of possible items. Do not read examples as an exhaustive list or a requirement to submit every item.','Nenne Beispiele möglicher Gegenstände. Lies sie nicht als abgeschlossene Liste oder Pflicht, alles einzureichen.'),('문서라든가 녹음처럼 확인할 수 있는 자료가 필요해요. 다른 자료도 괜찮아요.','문서와 녹음은 가능한 예시','문서와 녹음을 모두 내야만 함'),('회의록이라든가 메모로 확인해 볼까요? 다른 근거도 살펴봐요.','회의록과 메모를 확인 자료로 예시','회의록과 메모 외의 자료는 금지')),
      ('G5:-길래',loc('자신이 관찰하거나 알게 된 상황을 반응의 계기로 제시해요. 계기를 상대의 숨은 의도나 보편 원인으로 확대하지 않아요.','Present an observed or learned situation as the trigger for your reaction. Do not expand it into hidden intent or universal causation.','Nenne eine beobachtete oder erfahrene Lage als Anlass deiner Reaktion. Erweitere sie nicht zu verborgener Absicht oder allgemeiner Ursache.'),('아무도 답하지 않길래 다시 물었어요. 왜 침묵했는지는 몰라요.','무응답을 계기로 화자가 재질문','상대의 거절 의도를 확인 완료'),('표정이 굳어 있길래 괜찮은지 물었어요. 속마음은 아직 몰라요.','표정을 보고 상태를 질문','표정만으로 적대감 확정')),
      ('G1:-으시-',loc('듣는 사람과 친하게 말해도 제삼자인 선생님을 높이는 주체 높임을 유지해요. 상대 공손성과 주체 높임은 별개이며 전언의 출처도 유지합니다.','Keep subject honorification for the teacher even while speaking casually to a friend. Addressee politeness and subject honorification are separate; retain hearsay attribution too.','Erhalte die Subjekthonorifikation für die Lehrperson auch im vertrauten Gespräch. Höflichkeit gegenüber dem Gegenüber und Subjekthonorifikation sind getrennt; bewahre auch die Quellenangabe.'),('선생님은 내일 오신대. 그때 다시 여쭤보자.','친구에게 반말하면서 선생님은 높임, 전언 유지','친구에게 반말하므로 선생님 높임도 제거'),('선생님은 회의실에서 기다리신대. 먼저 인사드리자.','친구와의 친밀체 안에서 제삼자 높임 유지','화자가 선생님의 기다림을 직접 확인했다고 단정')),
    ]
    tasks=[grammar_task('KP24',i,*r) for i,r in enumerate(rows,1)]
    prod=[
      ('G5:-거라',('연극 속 보호자의 아이에게 하는 대사만 쓰기 / 먼저 들어가다 / -거라','먼저 들어가거라.','제가 먼저 들어가겠습니다.'),('연극 속 보호자의 아이에게 하는 대사만 쓰기 / 여기 앉다 / -거라','여기 앉거라.','제가 여기 앉겠습니다.')),
      ('G5:-고말고',('사정을 이해한다는 강한 긍정만 / 그 사정은 이해하다 / -고말고요','그 사정은 이해하고말고요.','그 일을 대신 맡겠습니다.'),('노고를 안다는 강한 긍정만 / 수고한 건 알다 / -고말고요','수고한 건 알고말고요.','모든 결과를 승인합니다.')),
      ('G5:-네2',('친밀한 친구 사이 / 생각보다 꼼꼼하게 준비함 알아차림 / -네','생각보다 꼼꼼하게 준비했네.','전혀 준비하지 않았네.'),('친밀한 친구 사이 / 또 일정 변경 알아차림 / -네','또 일정을 바꿨네.','일정이 그대로네.')),
      ('G5:-는걸',('쉽다는 앞말 정정 / 직접 해 보니 생각보다 어렵다 / -은걸','직접 해 보니 생각보다 어려운걸.','직접 해 보니 생각대로 쉬운걸.'),('자리가 없다는 앞말 정정 / 안쪽에는 아직 남아 있다 / -는걸','안쪽에는 아직 남아 있는걸.','안쪽에도 전혀 자리가 없는걸.')),
      ('G5:-으려고2',('친한 친구의 의도 묻기 / 그 많은 일을 혼자 다 하다 / -려고?','그 많은 일을 혼자 다 하려고?','그 많은 일을 반드시 혼자 다 해.'),('친한 친구의 의도 묻기 / 지금 혼자 출발하다 / -려고?','지금 혼자 출발하려고?','지금 혼자 출발하지 마.')),
      ('G5:-게 생겼다',('현재 조건의 예상 / 이대로라면 약속을 못 지키다 / -게 생겼다, 해요체','이대로라면 약속을 못 지키게 생겼어요.','약속을 이미 어겼어요.'),('조건부 예상 / 비가 계속 오면 행사 미루다 / -게 생겼다, 해요체','비가 계속 오면 행사를 미루게 생겼어요.','행사를 이미 미뤘어요.')),
      ('G5:-는 척하다',('서술자가 실제 앎을 확인 / 그 / 내용 이미 알지만 모르는 듯 행동 / -는 척했다','그는 내용을 이미 알았지만 모르는 척했다.','그는 내용을 전혀 몰랐다.'),('서술자가 실제 지루함을 확인 / 그 / 지루했지만 흥미롭게 듣는 듯 행동 / -는 척했다','그는 지루했지만 흥미롭게 듣는 척했다.','그는 실제로 깊은 흥미를 느꼈다.')),
      ('G5:-기만 하다',('논의 반복만 / 결정 없음 / -기만 하고, 문어','논의가 반복되기만 하고 결정은 나지 않았다.','논의가 반복된 뒤 결정이 났다.'),('설명 청취만 / 동의 발언 없음 / -기만 했고, 문어','설명을 듣기만 했고 동의한다는 말은 하지 않았다.','설명을 듣고 동의한다고 말했다.')),
      ('G5:따라',('유독 오늘 / 말이 잘 안 나오다 / 오늘따라, -네요','오늘따라 말이 잘 안 나오네요.','항상 말이 잘 안 나오네요.'),('유독 그날 / 질문 많다 / 그날따라, 해요체','그날따라 질문이 많았어요.','항상 질문이 많았어요.')),
      ('G5:이라든가',('가능한 예시 / 문서 또는 녹음 같은 확인 자료 / 라든가, 해요체','문서라든가 녹음처럼 확인할 수 있는 자료가 필요해요.','문서와 녹음을 반드시 모두 내야 해요.'),('가능한 예시 / 회의록 또는 메모로 확인 제안 / 이라든가, -볼까요','회의록이라든가 메모로 확인해 볼까요?','회의록과 메모 이외의 자료는 금지예요.')),
      ('G5:-길래',('관찰: 아무도 답하지 않음 / 내 반응: 다시 질문 / -길래, 해요체','아무도 답하지 않길래 다시 물었어요.','아무도 답하지 않아서 거절 의도를 확정했어요.'),('관찰: 표정 굳어 있음 / 내 반응: 괜찮은지 질문 / -길래, 해요체','표정이 굳어 있길래 괜찮은지 물었어요.','표정만으로 적대감을 확정했어요.')),
      ('G1:-으시-',('친구에게 친밀체 전언 / 선생님 내일 오다 / 주체 높임 유지 / -신대','선생님은 내일 오신대.','선생님은 내일 온대.'),('친구에게 친밀체 전언 / 선생님 회의실에서 기다리다 / 주체 높임 유지 / -신대','선생님은 회의실에서 기다리신대.','선생님은 회의실에서 기다린대.')),
    ]
    tasks+=production('KP24',tasks,prod)
    h=loc('같은 말끝도 앞뒤 발화와 관계에 따라 다르게 읽힙니다. 제시 음성의 억양만으로 실제 속마음을 확정하지 마세요. 명시된 사실·서술자의 앎·등장인물의 추측·비평가의 해석을 나누고 다른 가능한 읽기를 남겨요. 동의·공손함·행동 약속도 별개입니다.','The same ending can be read differently depending on context and relationship. Do not infer actual inner feelings from the presented voice alone. Separate explicit facts, narrator knowledge, character inference and critical interpretation; retain alternative readings. Agreement, politeness and action commitments are separate.','Dasselbe Satzende kann je nach Kontext und Beziehung anders gelesen werden. Leite tatsächliche Gefühle nicht allein aus der vorliegenden Stimme ab. Trenne Fakten, Erzählerwissen, Figurenvermutung und kritische Deutung; erhalte Alternativlesarten. Zustimmung, Höflichkeit und Handlungszusagen sind getrennt.')
    p=('가람극회','민서','준호',6,'목요일')
    a=('솔빛낭독회','지수','도하',9,'금요일')
    def conversations(name,first,second,count,day):
        return f'''[가상 {name} 대화. 두 친구는 서로 반말하기로 합의한 동등한 성인이다. 공개 모임에서는 다른 참석자에게 해요체와 합쇼체를 쓴다.]
장면 A. {first}: 이번에는 빠진 항목 없이 {count}개를 점검했어.
{second}: 생각보다 꼼꼼하게 준비했네. 네 표 덕분에 확인하기 편하겠어. 고마워.
{first}: 도움이 된다니 다행이야. 쉬울 줄 알았는데 직접 해 보니 생각보다 어려운걸.
장면 B. 같은 말의 다른 문맥. {first}: 사실 이번에도 확인하기 전에 표부터 보냈어. 빠진 항목이 있어.
{second}: 생각보다 꼼꼼하게 준비했네. 아니, 표에 빈칸이 그대로잖아. 이 말은 칭찬으로 한 게 아니야.
{first}: 비꼼으로 들려서 속상했어. 무엇이 빠졌는지 직접 말해 줄래?
{second}: 미안해. 네 능력을 단정하려던 건 아니야. 빈칸부터 같이 확인하자는 뜻이었어. 그 많은 일을 혼자 다 하려고? 부담되면 나눠도 돼.
장면 C. 공개 모임. {second}: 사정을 이해하고말고요. 하지만 대신 맡겠다는 약속은 아닙니다. 빈칸의 내용과 역할 배분을 {day}에 함께 확인하자는 제안입니다. 선생님은 그날 오신다고 들었습니다. 참석을 제가 직접 확인한 것은 아닙니다.
진행자: 두 분은 확인 필요성에 동의했고 담당 배분은 아직 정하지 않았습니다. 고개를 끄덕이는 행동만으로 전원 동의를 기록하지 않겠습니다. 문서라든가 녹음처럼 확인할 자료가 있으면 함께 살펴보겠습니다.
후기. {first}: 아무도 답하지 않길래 다시 물었어요. 침묵의 이유는 아직 몰라요. 오늘따라 말이 잘 안 나오네요. 말끝보다 앞뒤 사정을 봐 주셨으면 해요.'''
    def listen(args):
        return packet(conversations(*args),[
          choice('support',loc('A에서 긍정 해석을 뒷받침하는 것은?', 'What supports a positive reading in A?', 'Was stützt eine positive Lesart in A?'),['표가 도움이 된다는 말과 감사','네라는 말끝 하나뿐'],h),
          choice('sarcasm',loc('B에서 비꼼 해석의 근거는?', 'What supports the sarcastic reading in B?', 'Was stützt die spöttische Lesart in B?'),['빈칸 지적과 칭찬이 아니었다는 명시','모든 네 발화는 본래 비꼼'],h),
          choice('suspicion',loc('혼자 다 하려고의 뒤 발화가 보태는 뜻은?', 'What does the follow-up add to the intention question?', 'Was ergänzt die Folgeäußerung zur Absichtsfrage?'),['부담을 나누려는 여지, 능력 단정 아님','상대의 무능을 확정 선언'],h),
          choice('agreement',loc('공개 발언의 이해하고말고요는?', 'What does the emphatic understanding cover publicly?', 'Was umfasst das nachdrückliche Verständnis öffentlich?'),['사정 이해, 업무 인수 약속 아님','업무 인수까지 확정'],h),
          choice('surface',loc('끄덕임·침묵으로 확정할 수 없는 것은?', 'What cannot be established from nodding or silence alone?', 'Was lässt sich aus Nicken oder Schweigen allein nicht feststellen?'),['전원 동의와 침묵의 이유','다시 질문한 화자의 행동 자체'],h),
          choice('register',loc('선생님 참석을 공적으로 옮긴 발언은?', 'How is the teacher’s attendance publicly reported?', 'Wie wird die Teilnahme der Lehrperson öffentlich wiedergegeben?'),['주체 높임과 전언 유지, 직접 확인 아님','친밀체를 바꾸며 참석 보증으로 강화'],h),
        ],'audio')
    tasks.append(task('KP24','listening:01','listening',loc('같은 감탄의 다른 문맥','Different contexts for the same exclamation','Verschiedene Kontexte desselben Ausrufs'),h,listen(p),listen(a)))
    def lecture(args):
        return f'''[가상 문학·화용 강연]
{args[0]}의 두 장면에는 “생각보다 꼼꼼하게 준비했네”라는 같은 문장이 나옵니다. 첫 장면의 감사와 유용성 평가는 지지의 읽기를 뒷받침합니다. 두 번째 장면에서는 빈칸 지적과 칭찬이 아니었다는 자기 설명이 반어의 읽기를 뒷받침합니다. 두 장면을 같은 감정으로 읽는다면 문학적 관습과 공유 전제를 놓칩니다.
여기서 억양의 한계도 짚겠습니다. 같은 단어라도 실제 대화의 강세·휴지와 청자의 반응을 함께 살펴야 합니다. 이 자료에서 확인하는 것은 문맥이 뒷받침하는 해석이며, 말끝 하나나 제시된 목소리만으로 모든 속내를 판정하는 규칙은 아닙니다. 반어는 겉말과 의도의 대비를, 냉소는 비판적 거리감을 가리키지만 둘이 언제나 같은 것은 아닙니다.
이제 서술자를 보겠습니다. 서술자가 실제 앎을 밝히며 모르는 척했다고 쓰면 겉행동과 내적 상태의 차이가 텍스트에 제시됩니다. 반면 등장인물이 표정만 보고 그런가 보다 생각한 경우는 추측입니다. 비평은 이 차이를 근거로 작품 해석을 논증해야 하며 인물을 진단해서는 안 됩니다.
마지막으로 관계와 문체입니다. 친구 둘은 반말에 합의했지만 모임의 모든 사람에게 같은 말투를 쓸 권한이 생긴 것은 아닙니다. 친밀체를 공적 문체로 바꿔도 {args[3]}개를 점검했다는 발언의 출처, 빈칸 확인 제안, 미결 역할 배분을 유지해야 합니다. 상대가 비꼼으로 들었다고 말하면 그 해석을 비난하지 말고 무엇을 의도했는지 직접 말하며 수리할 수 있습니다.'''
    def monologue(args):
        return packet(lecture(args),[
          choice('structure',loc('강연의 전개는?', 'How does the lecture develop?', 'Wie entwickelt sich der Vortrag?'),['문맥 대비 → 억양 한계 → 서술 관점 → 관계와 수리','말끝 규칙만으로 모든 감정을 확정'],h),
          choice('narrator',loc('서술자의 앎과 인물의 추측 차이는?', 'How do narrator knowledge and character inference differ?', 'Wie unterscheiden sich Erzählerwissen und Figurenvermutung?'),['실제 상태를 명시한 서술과 표정 해석은 보증 수준이 다름','표정 해석은 항상 전지적 사실'],h),
          choice('repair',loc('비꼼으로 들렸다는 말에 할 수 있는 수리는?', 'What repair addresses a perceived sarcastic remark?', 'Welche Reparatur reagiert auf wahrgenommenen Spott?'),['해석을 비난하지 않고 의도와 확인 대상을 직접 설명','상대가 예민하다고 단정해 논의를 끝냄'],h),
        ],'audio')
    tasks.append(task('KP24','listening:02','listening',loc('문맥·서술자·문체의 효과 강연','Lecture on context, narrator and register','Vortrag über Kontext, Erzählinstanz und Register'),h,monologue(p),monologue(a)))
    def literature(args):
        name,first,second,count,day=args
        en_day={'목요일':'Thursday','금요일':'Friday'}[day]
        de_day={'목요일':'Donnerstag','금요일':'Freitag'}[day]
        return f'''[창작 단편: 비어 있는 칸 — {name} 장면]
탁자 위에는 빈칸이 남은 표가 놓여 있었다. {first}와 {second}는 오래 알고 지낸 친구였고 서로 반말하기로 합의했다. “생각보다 꼼꼼하게 준비했네.” {second}가 표의 모서리를 눌렀다. 그 말이 칭찬인지 핀잔인지 {first}는 알 수 없었다. 아직 감사도 항의도 뒤따르지 않았다.
{first}는 빈칸의 이유를 이미 알고 있었다. 그러나 모르는 척하며 표를 뒤집었다. 이 문장은 서술자가 실제 앎을 밝히는 대목이다. {second}는 그 행동을 보고 말을 한 귀로 흘리는 것 같다고 생각했다. 그 생각까지 객관적 사실인 것은 아니었다.
“그 많은 일을 혼자 다 하려고?” {second}가 다시 말문을 열었다. “힘들면 나누자는 뜻이야.” {first}는 처음에는 자신의 능력을 의심하는 말이라고 느꼈지만, 뒤의 제안을 듣고 부담을 걱정하는 읽기도 가능하다고 생각했다. 말에 뼈가 있는지는 아직 단정하지 않았다. 논의가 반복되기만 하고 역할 결정은 나지 않았다.
“선생님은 {day}에 오신대. 그때 다시 여쭤보자.” {first}가 말했다. 이것은 친구에게 전해 들은 참석 소식을 옮기는 말이다. {second}가 끄덕였지만 그 행동만으로 의견 전부에 동의했는지 알 수는 없다. 두 사람은 표를 다시 보았다. 서술자는 그들의 다음 결정을 적지 않았다.
[비평 A]
첫 감탄을 냉소로 읽을 가능성은 빈칸과 표를 누르는 행동에서 나온다. 그러나 말끝 -네 자체가 냉소를 증명하지는 않는다. 감사나 명시적 비난이 없는 상태에서는 놀람이라는 대안도 남는다. 작품 해석은 이 여백을 지우지 않아야 한다. -는 척하다의 앎은 서술자가 명시했지만 친구가 떠올린 무시의 판단은 그 인물의 평가다.
[비평 B]
혼자 다 하려고라는 질문만 떼면 불신으로 읽기 쉽다. 뒤의 나누자는 제안은 걱정과 협력의 읽기를 지지한다. 처음부터 순수한 호의였다고까지 보증할 수는 없다. 화자 태도는 속내를 드러내는 말과 청자 반응을 함께 보아야 한다. 친밀한 문체를 쓰는 것이 모든 책임까지 공유한다는 뜻도 아니다.
[영어 번역 A / 독일어 번역 A — 검토 대상]
“The teacher is definitely coming on {en_day},” said the friend who had confirmed it personally.
„Die Lehrperson kommt am {de_day} ganz bestimmt“, sagte die Person, die dies selbst bestätigt hatte.
[영어 번역 B / 독일어 번역 B — 검토 대상]
“I hear the teacher is coming on {en_day}. Let’s ask again then.”
„Die Lehrperson kommt, wie ich gehört habe, am {de_day}. Fragen wir dann noch einmal nach.“
[번역 비교 메모]
A는 원문에 없는 확신과 직접 확인을 더했다. B는 전언을 유지하지만 한국어 주체 높임과 친구 사이의 친밀체를 영어·독일어 말끝만으로 모두 옮기지는 못한다. 높임의 관계를 필요하면 주석하고, 그런 차이를 새 사건이나 성격 평가로 메우지 않는다.'''
    def read(args):
        return packet(literature(args),[
          choice('ambiguity',loc('단편 첫 감탄에서 남겨야 할 읽기는?', 'Which readings remain possible for the story’s opening exclamation?', 'Welche Lesarten bleiben für den ersten Ausruf möglich?'),['냉소 가능성과 놀람 가능성 모두 문맥으로 검토','네만으로 확정된 기쁨'],h),
          choice('pretence',loc('모르는 척했다의 실제 앎은 누가 밝히나요?', 'Who establishes actual knowledge behind the pretence?', 'Wer stellt das tatsächliche Wissen hinter dem Verstellen fest?'),['서술자','표정을 본 친구의 추측만'],h),
          choice('perspective',loc('한 귀로 흘린다는 생각의 지위는?', 'What is the status of the thought that the remark was ignored?', 'Welchen Status hat die Vermutung des Überhörens?'),['등장인물의 평가, 객관적 확정 아님','서술자가 검증한 모든 속마음'],h),
          choice('alternative',loc('의도 질문의 협력적 읽기를 지지하는 구절은?', 'Which passage supports a cooperative reading of the intention question?', 'Welche Stelle stützt eine kooperative Lesart der Absichtsfrage?'),['힘들면 나누자는 뜻이야','그 많은 일을 혼자 다 하려고만 고립'],h),
          choice('translation',loc('번역 A가 추가한 것은?', 'What does translation A add?', 'Was fügt Übersetzung A hinzu?'),['확신과 직접 확인','원문의 전언만 그대로 유지'],h),
          choice('honorific',loc('B가 유지한 것과 추가 설명이 필요한 것은?', 'What does B preserve and what may need explanation?', 'Was erhält B und was bedarf eventuell einer Erklärung?'),['전언 유지, 주체 높임과 친밀체 관계는 주석 가능','확신 강화, 친구와 선생님의 관계 삭제 필수'],h),
          choice('ending',loc('단편 끝에서 확정되지 않은 것은?', 'What remains unconfirmed at the end?', 'Was bleibt am Ende unbestätigt?'),['역할 결정과 전원 동의','표에 빈칸이 있었던 사실'],h),
        ])
    tasks.append(task('KP24','reading:01','reading',loc('문학의 여백과 번역이 더한 확신','Literary ambiguity and certainty added in translation','Literarische Offenheit und hinzugefügte Gewissheit'),h,read(p),read(a)))
    rubric=loc('첫째 친한 친구에게 성찰문을 쓰세요. 서로 반말하기로 합의한 관계를 근거로 하되, 무시나 속내를 사실로 단정하지 말고 당신의 해석과 근거를 나누어요. 둘째 같은 사건을 공개 모임 독자에게 해요체 또는 공적 문어로 다시 쓰고 제삼자 선생님 높임·전언·미결 책임을 유지하세요. 두 문체의 거리 효과를 구체 문장에 주석합니다. 셋째 두 비평 중 하나를 선택해 근거와 가장 강한 반론, 다른 가능한 읽기를 포함한 짧은 논설문을 씁니다. 감탄·의심·겉행동의 해석마다 구절을 대고, 서술자·인물·비평가를 구별하세요. 번역 A의 과잉 확신을 고치되 인물의 의도를 반대로 단정하지 않습니다. 원문과 대조해 장식적 완곡어 대신 실제 빠진 출처·조건을 고쳐요. 자유 의미·문체 효과는 미채점입니다.',
      'First write a reflection to the close friend. Ground casual style in their agreement, but separate your interpretation and evidence instead of stating disregard or hidden intent as fact. Recast the same event for public readers in polite or formal written style, preserving teacher honorification, hearsay and unresolved responsibility. Annotate specific sentences for changes in interpersonal distance. Third choose one critical reading and write a short argument with evidence, its strongest objection and another possible reading. Cite passages for surprise, suspicion and performed behaviour; distinguish narrator, character and critic. Correct translation A’s added certainty without asserting the opposite intention. Compare sources and repair missing attribution or conditions instead of decorative hedging. Free meaning and stylistic effects remain unscored.',
      'Schreibe zuerst eine Reflexion an die vertraute Person. Begründe vertrauten Stil mit der Vereinbarung, aber trenne eigene Deutung und Belege, statt Missachtung oder verborgene Absicht als Tatsache zu setzen. Formuliere dasselbe Ereignis für öffentliche Leser höflich oder förmlich schriftlich um und erhalte Lehrpersonen-Honorifikation, Hörensagen und offene Verantwortung. Kommentiere konkrete Sätze hinsichtlich veränderter Distanz. Wähle drittens eine kritische Lesart und schreibe eine kurze Argumentation mit Belegen, stärkstem Einwand und anderer möglicher Deutung. Belege Überraschung, Zweifel und gespieltes Verhalten; trenne Erzählinstanz, Figur und Kritik. Korrigiere die zusätzliche Gewissheit in Übersetzung A, ohne die gegenteilige Absicht zu behaupten. Vergleiche Quellen und repariere fehlende Zuschreibung oder Bedingungen statt dekorativer Abschwächung. Inhalt und Stilwirkung bleiben unbewertet.')
    def writing(args):
        return packet(literature(args),[
          free_text('friend',loc('친한 독자에게 쓰는 성찰문','Reflection for a close reader','Reflexion für eine vertraute Person'),rubric),
          free_text('public',loc('공개 독자용 성찰문과 거리 효과 주석','Public reflection and notes on distance','Öffentliche Reflexion mit Distanzkommentar'),rubric),
          free_text('criticism',loc('다른 읽기를 포함한 비평 의견문','Critical argument with an alternative reading','Kritische Argumentation mit Alternativlesart'),rubric),
        ],'form')
    tasks.append(task('KP24','writing:01','writing',loc('친밀한 성찰·공개 성찰·비평','Private reflection, public reflection and criticism','Vertraute Reflexion, öffentliche Reflexion und Kritik'),rubric,writing(p),writing(a)))
    speech=loc('반말에 합의한 친구에게 친밀체로 빈칸·부담·확인 제안을 말하세요. 친구가 “그 말 비꼬는 것 같아”라고 하면 해석을 탓하지 말고 의도와 사실을 직접 설명해 수리합니다. 같은 -네·-는걸 문장을 지지 문맥과 정정 문맥에서 각각 녹음해 휴지·강조가 어떻게 들리는지 비교하되 실제 속마음을 자동 확정하지 마세요. 이어 다른 동료에게 해요체, 공개 모임에 합쇼체로 같은 문제를 설명합니다. 제삼자 선생님 높임·전언·역할 미결을 지키고 이해·동의·업무 인수 약속을 분리하세요. 모어가 다른 동료에게 한국어로 감탄을 확정 감정으로, 전언을 직접 보증으로 바꾼 두 오류를 짚습니다. 연극 속 -거라를 동등한 성인에게 새 명령으로 쓰지 않아요. 재생해 출처와 의미 단위를 유지하도록 다시 말합니다. 의미·억양·화자 태도는 미채점입니다.',
      'Use the mutually agreed casual register with the friend to discuss blanks, burden and a checking proposal. If they hear sarcasm, explain intent and facts directly without blaming their interpretation. Record the same 네/는걸 sentence in supportive and corrective contexts; compare pauses and emphasis without claiming automatic access to inner feelings. Recast the issue politely to another colleague and formally to the public meeting. Preserve teacher honorification, hearsay and unresolved roles; distinguish understanding, agreement and taking over work. Explain in Korean two transfer errors to a colleague with another first language: exclamation becomes a certain emotion, hearsay becomes direct assurance. Do not use the play’s 거라 as a new command to an equal adult. Replay and revise while preserving attribution and meaning units. Meaning, intonation and stance remain unscored.',
      'Sprich mit der vertrauten Person im gemeinsam vereinbarten informellen Register über Lücken, Belastung und einen Prüfvorschlag. Hört sie Spott, erkläre Absicht und Fakten direkt, ohne ihre Deutung abzuwerten. Nimm denselben 네/는걸-Satz in unterstützendem und korrigierendem Kontext auf; vergleiche Pausen und Betonung, ohne innere Gefühle automatisch festzustellen. Erkläre das Thema danach einer weiteren Person höflich und der öffentlichen Sitzung förmlich. Erhalte Lehrpersonen-Honorifikation, Hörensagen und offene Rollen; trenne Verständnis, Zustimmung und Arbeitsübernahme. Erkläre einer Person anderer Erstsprache auf Koreanisch zwei Übertragungsfehler: Ausruf wird sichere Emotion, Hörensagen direkte Zusicherung. Verwende das 거라 aus dem Stück nicht als neuen Befehl an gleichgestellte Erwachsene. Höre zu und überarbeite mit erhaltenen Quellen und Sinneinheiten. Inhalt, Intonation und Haltung bleiben unbewertet.')
    tasks.append(task('KP24','speaking:01','speaking',loc('비꼼으로 들린 말을 수리하고 문체 바꾸기','Repair perceived sarcasm and change register','Wahrgenommenen Spott reparieren und Register wechseln'),speech,packet(conversations(*p)+'\n'+literature(p),[]),packet(conversations(*a)+'\n'+literature(a),[])))
    return tasks


if __name__=='__main__':
    write_source('KP24',kp24())
