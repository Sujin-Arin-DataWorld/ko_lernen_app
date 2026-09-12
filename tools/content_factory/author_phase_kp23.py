"""KP23 reporting chains, quotation scope and correction; unsigned source."""
from phase_task_authoring import choice, free_text, grammar_task, loc, packet, task, write_source
from author_phase_a1_production import production


def kp23():
    rows=[
      ('G5:-는다기에',loc('다른 사람에게 들은 내용을 자신의 행동 이유로 제시해요. 들은 명제가 독립적으로 검증됐다는 뜻은 아니에요.','Give something heard from another person as the reason for your action. The reported proposition has not thereby been independently verified.','Nenne eine gehörte Aussage als Grund für dein Handeln. Ihr Inhalt ist dadurch nicht unabhängig bestätigt.'),('동료가 추가 설명이 필요하다기에 자료를 보냈습니다.','동료의 필요하다는 말을 이유로 전송','화자가 직접 필요성을 조사해 확정'),('담당자가 장소가 바뀐다기에 새 안내를 확인했습니다.','장소 변경 전언을 이유로 안내 확인','화자가 현장에서 변경을 직접 목격')),
      ('G5:-는다니1',loc('여기서는 전달된 지시의 내용을 묻는 -으라니 변이예요. 친한 동료 사이에서 누구에게·무엇을과 함께 지시의 빈칸을 확인해요. 자신이 새 명령을 내리거나 들은 말에 감탄하는 용례와 구별합니다.','Here the -으라니 variant asks about a reported instruction. Among close peers, who or what asks for missing content. Distinguish issuing your own command and reacting with surprise.','Hier fragt die Variante -으라니 nach dem Inhalt einer übermittelten Anweisung. Unter vertrauten Gleichgestellten klärt wer oder was eine Lücke. Unterscheide eigene Befehle und überraschte Reaktionen.'),('담당자가 자료를 누구에게 제출하라니? 받는 사람을 못 들었어.','전달받은 제출 지시의 수신자 질문','화자가 직접 새 제출 명령'),('진행자가 내일까지 무엇을 준비하라니? 준비물을 못 들었어.','전달받은 준비 지시의 대상 질문','준비가 끝났다는 사실 확인')),
      ('G5:-자기에',loc('다른 사람이 한 공동 제안을 자신의 행동 이유로 제시해요. 제안을 명령으로 강화하거나 행동의 주체를 바꾸지 않아요.','Use another person’s joint proposal as the reason for your action. Do not strengthen it into an order or swap the actor.','Nenne den gemeinsamen Vorschlag einer anderen Person als Grund für dein Handeln. Verstärke ihn nicht zum Befehl und vertausche die handelnde Person nicht.'),('동료가 함께 검토하자기에 회의에 참석했습니다.','동료의 공동 검토 제안 때문에 화자가 참석','화자가 동료에게 참석을 명령'),('민서가 같이 비교하자기에 두 표를 가져왔어요.','민서의 공동 비교 제안 때문에 화자가 준비','민서가 혼자 비교하라고 명령')),
      ('G5:-더라고',loc('화자가 직접 살피거나 경험하고 알게 된 일을 전달하는 용례예요. 무엇을 직접 비교했는지 밝히고 전언과 나누어요.','Report something the speaker learned through direct inspection or experience. State what was inspected and distinguish hearsay.','Berichte, was die sprechende Person durch eigenes Prüfen oder Erleben erfahren hat. Benenne die eigene Prüfung und trenne Hörensagen.'),('제가 두 표를 직접 비교해 보니 기준이 다르더라고요.','화자가 직접 비교해 알게 된 기준 차이','제삼자 말만 전달한 기준 차이'),('제가 어제 원고를 읽어 보니 인용이 빠져 있더라고요.','화자가 직접 읽고 발견한 인용 누락','원고를 읽지 않고 들은 이야기')),
      ('G5:-데',loc('직접 경험한 과거를 회상하는 종결 -데·-데요예요. 다른 사람에게 들었다는 -대·-대요와 한 글자 차이지만 출처가 달라요. 이 말투를 읽고 더 널리 쓰는 -더라고요로도 풀어 말해요.','Sentence-final -데/-데요 recalls direct past experience. The similar-looking hearsay -대/-대요 has a different source. Recognise this register and also paraphrase with common -더라고요.','Das Satzende -데/-데요 erinnert an eigenes vergangenes Erleben. Das ähnlich geschriebene Hörensagen -대/-대요 hat eine andere Quelle. Erkenne diese Sprechweise und formuliere auch mit gebräuchlichem -더라고요 um.'),('어제 직접 가 보니 전시실이 꽤 조용하데요.','화자가 방문해 경험한 조용함','누군가에게 들은 조용함만 전달'),('어제 직접 들어 보니 설명이 또렷하데요.','화자가 직접 들은 설명의 또렷함','듣지 않고 제삼자의 평가만 전달')),
      ('G5:-다니1',loc('들은 내용에 대한 감탄이나 평가를 드러내요. 감탄은 전달자가 원 사건을 직접 확인한 증거가 아니에요. 빈칸을 묻는 의문 용례와 구별해요.','Express surprise or evaluation about something heard. The reaction is not evidence that the reporter personally verified the event. Distinguish a question asking for missing information.','Zeige Erstaunen oder Bewertung über Gehörtes. Die Reaktion belegt keine eigene Prüfung des Ereignisses. Unterscheide die Frage nach fehlender Information.'),('그 많은 일을 혼자 감당했다니 놀라워요! 저는 그 말을 전해 들었어요.','전해 들은 내용에 대한 화자의 놀람','화자가 모든 작업을 직접 지켜본 확인'),('벌써 기록을 다 정리했다니 대단해요! 동료에게 들었어요.','정리 완료 전언에 대한 감탄','화자가 직접 기록 전수를 검사했다는 보고')),
      ('G5:-는다는 것이',loc('하려던 의도와 실제 결과가 어긋났음을 말해요. 의도를 실제 성과로 기록하지 않아요.','Mark a mismatch between intended action and actual outcome. Do not record the intention as an achieved result.','Kennzeichne eine Abweichung zwischen Absicht und tatsächlichem Ergebnis. Erfasse die Absicht nicht als erreichte Wirkung.'),('도와준다는 것이 오히려 일을 늘리고 말았어요.','돕는 의도와 일 증가 결과의 어긋남','도우려던 의도대로 일이 줄어듦'),('분명하게 설명한다는 것이 오히려 혼란을 키웠어요.','명확한 설명 의도와 혼란 증가 결과','처음부터 혼란을 키우려는 목적')),
      ('G5:를 가지고',loc('주어진 말이나 자료를 판단의 재료로 삼는 용례예요. 물리적으로 들고 이동하는 뜻과 구별하고 자료의 보증 범위를 넘지 않아요.','Here use a statement or data as grounds for judgement. Distinguish physically carrying it and do not exceed its evidential scope.','Verwende hier eine Aussage oder Daten als Urteilsgrundlage. Unterscheide das körperliche Mitnehmen und überschreite die Belegkraft nicht.'),('그 한마디를 가지고 의도를 단정할 수는 없어요.','한 발언만으로 의도를 확정할 근거 부족','그 말을 손에 들고 이동할 수 없음'),('그 기사만을 가지고 합의가 있었다고 말하기는 어려워요.','한 기사만으로 합의를 확정하기 어려움','기사를 운반하는 방법 설명')),
    ]
    tasks=[grammar_task('KP23',i,*r) for i,r in enumerate(rows,1)]
    prod=[
      ('G5:-는다기에',('동료가 추가 설명 필요하다고 말함 → 내가 자료 보냄 / -다기에, 합쇼체','동료가 추가 설명이 필요하다기에 자료를 보냈습니다.','제가 직접 필요성을 조사해서 확정했습니다.'),('담당자가 장소 바뀐다고 말함 → 내가 새 안내 확인 / -다기에, 합쇼체','담당자가 장소가 바뀐다기에 새 안내를 확인했습니다.','제가 장소 변경을 직접 목격했습니다.')),
      ('G5:-는다니1',('친한 동료에게 전해진 지시의 수신자 묻기 / 담당자 / 자료 / 누구에게 / 제출하라니?','담당자가 자료를 누구에게 제출하라니?','자료를 지금 제출해.'),('친한 동료에게 전해진 지시의 준비물 묻기 / 진행자 / 내일까지 / 무엇을 / 준비하라니?','진행자가 내일까지 무엇을 준비하라니?','준비가 이미 끝났어.')),
      ('G5:-자기에',('동료가 함께 검토하자고 제안 → 내가 회의 참석 / -자기에, 합쇼체','동료가 함께 검토하자기에 회의에 참석했습니다.','제가 동료에게 회의 참석을 명령했습니다.'),('민서가 같이 비교하자고 제안 → 내가 두 표 가져옴 / -자기에, 해요체','민서가 같이 비교하자기에 두 표를 가져왔어요.','민서가 혼자 비교하라고 명령했어요.')),
      ('G5:-더라고',('내 직접 경험 / 제가 두 표를 직접 비교해 보다 / 기준 다르다 / -더라고요','제가 두 표를 직접 비교해 보니 기준이 다르더라고요.','직접 보지는 않았고 기준이 다르다고 들었어요.'),('내 직접 경험 / 제가 어제 원고 읽어 보다 / 인용 빠져 있다 / -더라고요','제가 어제 원고를 읽어 보니 인용이 빠져 있더라고요.','읽지는 않았고 인용이 빠졌다고 들었어요.')),
      ('G5:-데',('직접 방문 회상 / 어제 직접 가 보다 / 전시실 꽤 조용하다 / -데요','어제 직접 가 보니 전시실이 꽤 조용하데요.','전시실이 조용하다고 전해 들었어요.'),('직접 청취 회상 / 어제 직접 들어 보다 / 설명 또렷하다 / -데요','어제 직접 들어 보니 설명이 또렷하데요.','설명이 또렷하다고 전해 들었어요.')),
      ('G5:-다니1',('전해 들은 일에 감탄 / 그 많은 일을 혼자 감당하다 / -다니 놀라워요!','그 많은 일을 혼자 감당했다니 놀라워요!','제가 모든 작업을 직접 지켜봤어요.'),('전해 들은 완료에 감탄 / 벌써 기록을 다 정리하다 / -다니 대단해요!','벌써 기록을 다 정리했다니 대단해요!','제가 모든 기록을 직접 검사했어요.')),
      ('G5:-는다는 것이',('의도는 돕기 / 결과는 오히려 일 늘림 / 도와주다 / -는다는 것이, 해요체','도와준다는 것이 오히려 일을 늘리고 말았어요.','도와주려던 의도대로 일이 줄었어요.'),('의도는 분명한 설명 / 결과는 오히려 혼란 키움 / 설명하다 / -는다는 것이, 해요체','분명하게 설명한다는 것이 오히려 혼란을 키웠어요.','처음부터 혼란을 키우려고 했어요.')),
      ('G5:를 가지고',('판단 재료는 한마디뿐 / 그 한마디 / 의도 단정 불가 / 를 가지고, 해요체','그 한마디를 가지고 의도를 단정할 수는 없어요.','그 한마디만으로 의도를 확정했어요.'),('판단 재료는 기사 하나 / 그 기사만 / 합의 있었다고 말하기 어려움 / 을 가지고, 해요체','그 기사만을 가지고 합의가 있었다고 말하기는 어려워요.','그 기사만으로 합의를 확정했어요.')),
    ]
    tasks+=production('KP23',tasks,prod)
    h=loc('원 발언자→전달자→현재 화자의 연쇄를 복원하고, 같은 원문을 여러 번 옮긴 것을 독립 출처로 세지 않아요. 질문·권유·명령·감탄을 구별하며 인용 범위 밖의 평가를 분리합니다. 공개처럼 같은 단어도 집단별 정의를 확인해요.','Reconstruct original speaker → intermediary → current speaker. Repeated copies of one original are not independent sources. Separate questions, proposals, orders and reactions, and identify evaluations outside quotation scope. Check each group’s meaning of shared terms such as disclosure.','Rekonstruiere ursprüngliche Stimme → vermittelnde Person → heutige Stimme. Wiederholungen eines Originals sind keine unabhängigen Quellen. Trenne Fragen, Vorschläge, Anweisungen und Reaktionen sowie Bewertungen außerhalb des Zitats. Prüfe die gruppenspezifische Bedeutung gemeinsamer Wörter wie Veröffentlichung.')
    p=('가람전시관','윤서','민서','준호',8,'월요일')
    a=('솔빛기록관','서하','지수','도윤',11,'화요일')
    def chain(name,origin,middle,last,count,day):
        return f'''[가상 {name} 자료 협의의 세 녹음. 세 사람은 업무를 조율하는 동료다. 원 발언자는 내부 검토 절차만 안내할 권한이 있고 외부 공개는 위원회가 결정한다.]
녹음 1. {origin}: {day}까지 초안 {count}건을 내부 검토함에 올려 주세요. 외부 공개 여부는 위원회에 물어보세요. 저는 외부 공개를 승인한 것이 아닙니다.
녹음 2. {middle}: 제가 방금 {origin}의 녹음 1을 들었어요. {origin}가 내부 검토함에 올리라고 했고, 외부에 공개해도 되는지는 위원회에 물어보라고 했어요. 저는 질문을 대신 전달하겠어요. 함께 검토하자기에 동료들과 자리에 모였습니다. 모였다는 사실과 위원회 승인은 다릅니다.
녹음 3. {last}: 저는 {middle}에게만 들었어요. “외부 공개는 위원회에 물어보라”고 전해 들었는데, 처음에는 공개하라는 지시로 잘못 옮겼습니다. {origin}의 원 녹음은 직접 듣지 않았어요. 누군가 “공개가 확정됐다”고도 말했지만 누가 처음 말했는지, 앞의 전언과 같은 출처인지는 모릅니다. 이 말을 독립 확인으로 적으면 안 되겠어요.
확인 대화. {middle}: 여기서 운영팀의 공개는 내부 검토함 공유를 뜻하고, 전시팀의 공개는 관람객에게 보여 주는 것을 뜻해요. 같은 단어라고 같은 범위는 아니에요.
{last}: 담당자가 자료를 누구에게 제출하라니?라고 친한 동료에게 물었던 것은 받는 사람을 확인하는 질문이었지 새 제출 명령은 아니었어요. 지금은 공손하게 “어느 검토함에 올리라는 지시인지 확인해 주시겠어요?”라고 되묻겠습니다.
{middle}: 원문은 내부 검토함이라고만 해요. 구체적인 계정과 접근 명단은 이 녹음에 없으니 확인 과제로 남겨요. 세 녹음은 전언 연쇄이지 세 차례의 독립 승인이 아닙니다.'''
    def listen(args):
        return packet(chain(*args),[
          choice('chain',loc('녹음 3의 확인된 전언 경로는?', 'What is recording 3’s confirmed reporting chain?', 'Welche Übermittlungskette ist für Aufnahme 3 belegt?'),[f'{args[1]} → {args[2]} → {args[3]}',f'{args[3]}가 위원회에서 직접 승인 확인'],h),
          choice('act',loc('원문이 외부 공개에 관해 지시한 행동은?', 'What action does the original require about external disclosure?', 'Welche Handlung verlangt das Original zur externen Veröffentlichung?'),['위원회에 허용 여부 질문','외부 공개 즉시 실행'],h),
          choice('independent',loc('세 녹음을 세 독립 승인으로 셀 수 있나요?', 'Are the three recordings three independent approvals?', 'Sind die drei Aufnahmen drei unabhängige Genehmigungen?'),['같은 지시의 재전달이므로 아님','발언자가 셋이므로 독립 승인 셋'],h),
          choice('unknown',loc('누군가의 확정 전언은 어떻게 기록하나요?', 'How should the anonymous confirmation report be recorded?', 'Wie wird die anonyme Bestätigungsaussage erfasst?'),['원 출처와 앞 전언과의 동일성 미상','위원회에서 나온 별도 직접 증거'],h),
          choice('definition',loc('두 집단의 공개 정의는?', 'How do the groups define disclosure?', 'Wie definieren die Gruppen Veröffentlichung?'),['운영팀 내부 공유, 전시팀 관람객 공개','두 집단 모두 외부 공개로 합의'],h),
          choice('clarify',loc('아직 정확히 되물을 내용은?', 'What still needs precise clarification?', 'Was muss noch genau nachgefragt werden?'),['구체 검토함 계정과 접근 명단','녹음에 이미 나온 초안 건수 자체'],h),
        ],'audio')
    tasks.append(task('KP23','listening:01','listening',loc('세 전언에서 지시가 달라진 곳','A changed instruction across three reports','Eine veränderte Anweisung in drei Übermittlungen'),h,listen(p),listen(a)))
    def lecture(args):
        return f'''[가상 강연: 인용과 검증 가능성]
{args[0]} 사례의 출처를 먼저 살펴보겠습니다. {args[1]}의 원 녹음은 {args[4]}건을 내부에 올리고 외부 공개 여부를 위원회에 물으라는 내용입니다. {args[2]}는 이 녹음을 들었지만 {args[3]}는 {args[2]}의 말만 들었습니다. 원 발언자가 다시 언급된다고 새 출처가 생기는 것은 아닙니다.
이제 화행을 보겠습니다. 질문하라는 지시에서 질문 내용만 떼어 평서문으로 만들면 공개 여부라는 미결 명제가 공개 확정으로 바뀝니다. 전달자가 질문을 맡겠다는 약속 역시 승인 권한과 다릅니다. 상대가 일을 다 마쳤다니 대단하다고 반응해도 그것은 감탄이지 작업 전수 확인은 아닙니다.
다음은 용어의 인용 범위입니다. 운영팀의 공개는 내부 공유이고 전시팀의 공개는 관람객 접근입니다. 뜻을 조율하려면 각 정의를 보존한 채 구체적인 지시 대상을 물어야 합니다. 누가 무슨 의미로 썼는지 확인하지 않고 공통 정의를 만들면 말을 옮기면서 사실을 보태게 됩니다.
마지막으로 정정의 범위를 보겠습니다. 오류를 고친다고 반대 사실을 새로 단정할 수는 없습니다. 공개가 승인됐다는 근거가 없다는 말은 영구히 금지됐다는 뜻이 아닙니다. 서로 다른 발화 주체를 추적하고, 교차 검증이 가능한지 출처 확인을 거쳐야 합니다. 지금 확인 가능한 결론은 내부 업로드 지시와 외부 공개 질문이 있었고 외부 승인 결과는 자료에 없다는 것입니다.'''
    def monologue(args):
        return packet(lecture(args),[
          choice('structure',loc('강연의 전개 순서는?', 'What is the lecture’s order?', 'Wie ist der Vortrag aufgebaut?'),['출처 연쇄 → 화행 → 용어 범위 → 정정 한계','승인 확정 → 공개 실행 → 성과 인증'],h),
          choice('reaction',loc('대단하다는 반응의 보증 수준은?', 'What does the admiring reaction verify?', 'Was bestätigt die bewundernde Reaktion?'),['감탄 자체이며 작업 전수 검증 아님','화자의 직접 작업 검사 완료'],h),
          choice('correction',loc('근거 없는 승인을 정정할 때 올바른 결론은?', 'What correction follows an unsupported approval claim?', 'Welche Korrektur folgt aus einer unbelegten Genehmigung?'),['승인 결과 미상','영구 공개 금지 확정'],h),
        ],'audio')
    tasks.append(task('KP23','listening:02','listening',loc('인용 범위와 정정의 한계 강연','Lecture on quotation scope and correction limits','Vortrag über Zitatumfang und Korrekturgrenzen'),h,monologue(p),monologue(a)))
    def sources(args):
        name,origin,middle,last,count,day=args
        return f'''[가상 기사 제목] “{name}, 초안 {count}건 외부 공개한다”
[기사 본문] 기자는 {last}에게 들은 이야기를 바탕으로 외부 공개가 결정됐다고 해석했다. 위원회 의결문은 확인하지 않았다. “외부에 공개해도 되는지는 위원회에 물어보라”는 전언을 인용했지만, 제목에서는 허용 여부라는 질문을 확정 진술로 바꿨다.
[인터뷰 전사 1: {middle}]
질문: 무엇을 직접 확인했나요?
답: 제가 직접 들은 것은 {origin}의 녹음입니다. {day}까지 초안 {count}건을 내부 검토함에 올리라는 말과 외부 공개는 위원회에 물으라는 말이 있었어요. 제가 초안 두 개를 직접 비교해 보니 한쪽에는 인용이 빠져 있더라고요. 이것은 제가 본 두 초안의 차이지 모든 자료가 잘못됐다는 뜻은 아니에요. {origin}가 추가 설명이 필요하다기에 비교 메모를 보냈습니다.
질문: 운영팀이 말한 공개는 무엇인가요?
답: 내부 검토함에 공유한다는 뜻이에요. 관람객에게 보여 준다는 뜻으로 쓴 것은 아니에요.
[인터뷰 전사 2: {last}]
질문: 원 녹음과 위원회 의결문을 보셨나요?
답: 아니요. {middle}에게만 들었어요. 기사와 제 전언이 서로 다른 독립 출처인 것처럼 보이면 안 돼요. 누군가 이미 정리했다는 말을 듣고 “그 많은 일을 혼자 감당했다니 놀라워요”라고 했지만 제가 확인한 일은 아닙니다. 전시팀에서 공개는 관람객에게 보여 주는 것을 뜻해요. 운영팀과 같은 뜻으로 합의한 적은 없습니다.
질문: 직접 경험한 일은 있나요?
답: 어제 직접 가 보니 전시실이 꽤 조용하데요. 방문 당시 분위기에 관한 회상입니다. 외부 공개 승인 여부를 확인했다는 뜻은 아니에요. 분명하게 설명한다는 것이 오히려 혼란을 키웠어요. 제가 비교 메모에서 물음표를 빼고 보낸 일이 있었거든요. 물음표를 뺀 사실은 인정하지만 처음부터 오해를 만들려던 것은 아닙니다.
[편집 검토 메모]
제목과 본문의 화행이 앞뒤가 맞는지, 인용 범위 밖의 기자 해석을 사실처럼 썼는지 확인한다. 그 기사만을 가지고 합의가 있었다고 말하기는 어렵다. 내부 업로드 지시, 외부 허용 질문, 두 초안의 직접 비교, 전언에 대한 감탄, 방문 회고, 전달 의도와 혼란 결과를 별도 명제로 기록한다. 구체 계정·접근 명단·익명 전언의 최초 출처·위원회 답변은 미상이다.'''
    def read(args):
        return packet(sources(args),[
          choice('headline',loc('제목에서 바뀐 화행은?', 'Which speech act changes in the headline?', 'Welcher Sprechakt ändert sich in der Überschrift?'),['허용 여부 질문이 공개 확정 진술로 바뀜','확정 승인을 그대로 인용'],h),
          choice('witness',loc('직접 비교한 명제의 범위는?', 'What is the scope of the directly compared finding?', 'Welchen Umfang hat der direkt verglichene Befund?'),['두 초안 중 한쪽 인용 누락','모든 자료의 인용 오류 전수 확인'],h),
          choice('source',loc('기사와 마지막 전달자의 관계는?', 'How are the article and last intermediary related?', 'Wie hängen Artikel und letzte vermittelnde Person zusammen?'),['기사가 그 전언을 재사용해 독립 확인 아님','별도 의결문을 각각 직접 확인'],h),
          choice('reaction',loc('혼자 감당했다니의 감탄은?', 'What does the exclamation about working alone establish?', 'Was belegt der Ausruf über allein bewältigte Arbeit?'),['들은 일에 대한 반응, 직접 확인 아님','작업 과정을 직접 본 증언'],h),
          choice('recollection',loc('조용하데요의 근거는?', 'What supports the recalled quietness?', 'Worauf beruht die erinnerte Ruhe?'),['화자의 전날 직접 방문','익명 전언만 전달'],h),
          choice('intention',loc('설명한다는 것이의 어긋남은?', 'What mismatch is expressed by intending to explain?', 'Welche Abweichung beschreibt die beabsichtigte Erklärung?'),['명확히 전달하려던 의도와 혼란 결과','처음부터 오해를 만들려는 목적'],h),
          choice('unknown',loc('미상으로 남겨야 할 것은?', 'What must remain unknown?', 'Was muss unbekannt bleiben?'),['위원회의 외부 공개 답변','내부 업로드 지시의 존재'],h),
        ])
    tasks.append(task('KP23','reading:01','reading',loc('기사 제목·인터뷰·검토 메모의 출처','Sources across headline, interviews and editorial note','Quellen in Überschrift, Interviews und Redaktionsnotiz'),h,read(p),read(a)))
    rubric=loc('첫째 완전한 브리핑 보고서를 써서 목적·명제별 출처·전언 연쇄·직접 경험 범위·현재 이견·미상 정보·확인 담당과 후속 질문을 나누세요. 같은 원문 재전달을 독립 교차 검증으로 세지 않고, 제안할 확인 절차와 이미 한 확인을 구별합니다. 운영팀과 전시팀의 공개 정의를 각각 보존하세요. 둘째 정정문에서 기사의 제목이 질문을 확정 진술로 바꾼 구절을 바로잡되 영구 금지라는 반대 사실을 만들지 마세요. 원 발언자·전달자·지시 수행자, 감탄과 검증, 의도와 결과를 분리합니다. 빠진 계정과 위원회 답변은 미상으로 남겨요. 원문과 대조해 누락된 인용 경계와 출처를 보완하여 재작성합니다. 자유 의미·논증은 미채점입니다.',
      'First write a complete briefing report separating purpose, sources for each proposition, reporting chain, direct-experience scope, disagreement, unknowns, proposed checking roles and follow-up questions. Do not count repeated originals as independent cross-checks; distinguish proposed verification from completed checks. Preserve both groups’ meanings of disclosure. Then write a correction identifying the headline’s shift from question to confirmed statement without inventing permanent prohibition. Separate original speaker, intermediary and instructed actor, admiration and verification, intention and outcome. Leave missing account details and committee response unknown. Compare source passages and rewrite missing quotation boundaries and attribution. Free meaning and argument remain unscored.',
      'Schreibe zuerst einen vollständigen Briefingbericht mit Zweck, Quellen je Aussage, Übermittlungskette, Umfang eigener Erfahrung, Dissens, Unbekanntem, vorgeschlagenen Prüfzuständigkeiten und Folgefragen. Zähle wiederholte Originale nicht als unabhängige Gegenprüfung; trenne vorgeschlagene von erfolgter Prüfung. Erhalte beide gruppenspezifischen Bedeutungen von Veröffentlichung. Schreibe dann eine Richtigstellung zum Wechsel von Frage zu sicherer Aussage in der Überschrift, ohne ein dauerhaftes Verbot zu erfinden. Trenne ursprüngliche Stimme, vermittelnde und angewiesene Person, Bewunderung und Prüfung sowie Absicht und Ergebnis. Fehlende Kontodetails und Ausschussantwort bleiben unbekannt. Vergleiche Belegstellen und überarbeite fehlende Zitatgrenzen und Zuschreibungen. Inhalt und Argumentation bleiben unbewertet.')
    def writing(args):
        return packet(chain(*args)+'\n'+sources(args),[free_text('briefing',loc('출처별 브리핑 보고서','Briefing report by source','Briefingbericht nach Quellen'),rubric),free_text('correction',loc('검증 범위를 보존한 정정문','Correction preserving verification limits','Richtigstellung mit erhaltenen Prüfgrenzen'),rubric)],'form')
    tasks.append(task('KP23','writing:01','writing',loc('보고 연쇄가 복원되는 기록과 정정','Recoverable reporting chains and corrections','Nachvollziehbare Übermittlungsketten und Korrekturen'),rubric,writing(p),writing(a)))
    speech=loc('발언을 중개하는 동료로서 해요체로 두 집단의 공개 정의를 각각 확인하고, 어떤 자료를 누구에게 어떤 권한으로 전달하라는 것인지 되물으세요. 자료에 없는 계정·접근 명단·위원회 답변은 확인 과제로 남기며 합의한 공통 정의를 만들지 않습니다. 이어 합쇼체 브리핑으로 요점·출처 연쇄·한계 순으로 발표하고 개인 평가를 인용 밖에서 밝힙니다. 모어가 다른 동료에게 한국어로 질문→명령과 전언→직접 경험이라는 두 전이 오류를 짚어 주세요. 같은 출처가 두 번 등장해도 한 원문임을 보존하고, -데요 회고를 -더라고요로 풀어도 출처를 유지하세요. 녹음을 듣고 발화자 전환·인용 경계의 휴지를 표시해 다시 말합니다. 의미·억양은 미채점입니다.',
      'As a mediating colleague, politely confirm each group’s definition of disclosure and ask which material should go to whom under whose authority. Leave missing accounts, access lists and committee response as checking tasks; invent no agreed common definition. Then give a formal briefing in point–reporting chain–limits order, keeping personal evaluation outside quotations. Explain in Korean two transfer errors to a colleague with another first language: question becomes command and hearsay becomes direct experience. Preserve one original even when its source is mentioned twice; retain the source when paraphrasing recalled 데요 with 더라고요. Replay, mark pauses at speaker changes and quotation boundaries, and revise. Meaning and intonation remain unscored.',
      'Bestätige als vermittelnde Person höflich die jeweilige Definition von Veröffentlichung. Frage nach Material, Empfänger und Befugnis. Fehlende Konten, Zugangslisten und Ausschussantwort bleiben Prüfaufträge; erfinde keine vereinbarte gemeinsame Definition. Halte danach ein förmliches Briefing in der Reihenfolge Kernpunkt–Übermittlungskette–Grenzen und kennzeichne eigene Bewertung außerhalb von Zitaten. Erkläre einer Person anderer Erstsprache auf Koreanisch zwei Übertragungsfehler: Frage wird Befehl und Hörensagen eigenes Erleben. Bewahre ein einziges Original auch bei zweimaliger Quellennennung; erhalte die Quelle beim Umformulieren von erinnerndem 데요 mit 더라고요. Höre zu, markiere Pausen bei Sprecherwechsel und Zitatgrenzen und überarbeite. Inhalt und Intonation bleiben unbewertet.')
    tasks.append(task('KP23','speaking:01','speaking',loc('출처와 같은 단어의 다른 뜻을 중개하기','Mediate sources and different meanings of one term','Quellen und verschiedene Bedeutungen eines Wortes vermitteln'),speech,packet(chain(*p)+'\n'+sources(p),[]),packet(chain(*a)+'\n'+sources(a),[])))
    return tasks


if __name__=='__main__':
    write_source('KP23',kp23())
