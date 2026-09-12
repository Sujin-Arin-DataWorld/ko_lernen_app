"""KP17 quotation, checking and witnessed evidence. Generated source is unsigned."""
from phase_task_authoring import choice, free_text, grammar_task, loc, packet, task, write_source
from author_phase_a1_production import production


def kp17():
    rows=[
      ('G4:-어라1',loc('직접 명령형이에요. 이 과제에서는 교사가 학생에게 지시하는 가상 극 대사로 읽어요. 대사를 인용한 사람의 새 명령이나 동료에게 쓸 기본 말투로 바꾸지 않아요.','This is a direct imperative, here a fictional teacher’s line to a student. Quoting it is not issuing a new command, and it is not the default style for colleagues.','Dies ist ein direkter Imperativ, hier die fiktive Theaterzeile einer Lehrkraft an ein lernendes Gegenüber. Zitieren ist kein neuer Befehl und nicht die übliche Anrede unter Gleichgestellten.'),
       ('극본에서 교사가 학생에게: 먼저 자료를 읽어라.','극 중 교사의 직접 명령','대사를 읽는 배우가 실제 동료에게 새로 명령함'),
       ('극본에서 교사가 학생에게: 확인한 내용을 적어라.','극 중 교사가 기록하라고 지시함','학생이 교사에게 기록을 부탁함')),
      ('G4:-는대2',loc('들은 말을 -다고 해요 대신 줄여 전해요. 누가 한 말인지와 전달자가 직접 보았는지를 따로 확인해요. 경험 배경의 -던데와 구별해요.','Contract reported speech instead of -다고 해요. Track the source and whether the messenger witnessed it; distinguish experiential -던데.','Verkürze wiedergegebene Rede statt -다고 해요. Beachte Quelle und eigene Beobachtung; unterscheide den Erfahrungshintergrund mit -던데.'),
       ('친구 말로는 오늘 회의가 없대요. 저는 담당자에게 확인하지 않았어요.','친구를 통해 들은 말, 직접 확인 전','담당자의 공지를 직접 읽고 확인 완료'),
       ('동료 말로는 내일 새 공지가 나온대요. 저는 아직 보지 못했어요.','동료에게 들은 새 공지 예정','새 공지를 화자가 이미 직접 읽음')),
      ('G4:-고4',loc('상대 발언과 관련된 질문을 이어 덧붙여요. 여기서는 -고요?로 추가 정보를 묻는 것이지 두 행동이 끝났다고 나열하는 것이 아니에요.','Add a related question to the other person’s statement. Here -고요? requests more information rather than listing completed actions.','Schließe eine zugehörige Frage an die Aussage des Gegenübers an. -고요? fragt hier nach Zusatzinformation, statt abgeschlossene Handlungen aufzuzählen.'),
       ('주말에도 일한다고요? 그럼 쉬는 날은 없고요?','쉬는 날에 관한 관련 질문을 덧붙임','주말 근무와 휴일 부재를 모두 확정 보고'),
       ('회의가 취소됐다고요? 그럼 자료 제출도 없고요?','자료 제출 여부를 추가 확인함','자료 제출 취소까지 이미 확정함')),
      ('G4:-게5',loc('합의된 반말 관계에서 상대 행동의 의도를 물어요. 장소를 정해 주는 명령이나 -게 하다 사동과 구별해요. 공식 문의에는 상황에 맞는 높임 표현을 써요.','Ask about someone’s intended action in an agreed casual relationship. This is neither an instruction assigning a destination nor causative -게 하다. Adapt the style for formal enquiries.','Frage in einer vereinbarten vertraulichen Beziehung nach der Handlungsabsicht. Das ist weder eine Zielanweisung noch das Kausativ -게 하다. Passe die Anrede bei förmlichen Anfragen an.'),
       ('반말에 합의한 친구에게: 이 짐을 어디로 가져가게?','친구가 가져가려는 곳을 물음','화자가 짐의 목적지를 명령함'),
       ('반말에 합의한 친구에게: 그 자료를 누구에게 보여 주게?','자료를 보여 주려는 상대를 물음','모든 사람에게 공개하라는 명령')),
      ('G4:-나3',loc('혼잣말이나 문장 안에서 의문을 제시해요. 잘못 들었나 생각하는 것과 잘못 들었다고 확정하는 것은 달라요.','Express an internal or embedded question. Wondering whether you misheard differs from concluding that you did.','Formuliere eine innere oder eingebettete Frage. Sich ein Verhören zu fragen ist nicht dasselbe wie dessen Feststellung.'),
       ('내가 잘못 들었나 다시 생각했어요.','잘못 들었을 가능성을 스스로 검토함','상대가 거짓말했다고 확정함'),
       ('시간이 바뀌었나 공지를 다시 읽었어요.','시간 변경 여부를 확인하려 공지를 재독함','시간이 바뀐 것이 이미 확정됨')),
      ('G4:-는다니2',loc('전달된 내용을 되묻고 추가 확인을 요청해요. 인용 내용이 실제 결정됐다고 새로 보증하지 않아요. 이 예문은 합의된 반말 장면이에요.','Check reported content and ask for clarification without newly guaranteeing its truth. These examples use agreed casual speech.','Frage zu übermitteltem Inhalt nach, ohne dessen Wahrheit neu zu garantieren. Die Beispiele verwenden vereinbarte vertrauliche Anrede.'),
       ('친구에게: 내일 회의를 한다니? 시간이 바뀐 거야?','내일 회의라는 전언을 되묻고 변경 여부 확인','내일 회의를 새로 확정하는 발표'),
       ('친구에게: 오늘 자료를 낸다니? 마감이 오늘이야?','오늘 제출이라는 전언의 기한을 확인','화자가 오늘 제출을 명령함')),
      ('G4:-는다면서1',loc('이미 들은 내용을 상대에게 확인해요. 확인 질문에 대한 대답이 없으면 사실 확정이나 상대의 약속으로 기록하지 않아요.','Check previously heard information with the other person. Without an answer, do not record the question as a fact or promise.','Prüfe zuvor Gehörtes beim Gegenüber. Ohne Antwort darf die Frage nicht als Tatsache oder Zusage protokolliert werden.'),
       ('다음 달에 이사한다면서요? 아직 답은 듣지 못했어요.','들은 이사 소식을 상대에게 확인하는 중','상대가 이사 날짜를 이미 확정해 줌'),
       ('오늘 발표한다면서요? 담당자에게 확인해 주세요.','들은 발표 일정을 확인 요청','발표가 이미 끝났다는 직접 목격')),
      ('G4:-다니1',loc('뜻밖의 소식에 놀라며 반응해요. 벌써 끝났다는 말이 놀랍다고 해서 완료 사실을 직접 보았다는 뜻은 아니에요.','React with surprise to unexpected news. Surprise that something is already over does not mean you witnessed its completion.','Reagiere überrascht auf unerwartete Nachrichten. Überraschung über einen Abschluss bedeutet nicht, ihn selbst gesehen zu haben.'),
       ('벌써 끝났다니? 정말이에요?','뜻밖의 완료 소식에 놀라 재확인','화자가 완료 현장을 이미 목격'),
       ('신청이 취소됐다니? 다시 확인해 볼게요.','뜻밖의 취소 소식에 반응하며 확인 예정','취소를 화자가 직접 승인함')),
      ('G4:-더군',loc('직접 경험해 새로 알게 된 점을 돌아보며 말해요. 관찰한 거리나 상태의 범위를 넘어 다른 날의 운영까지 단정하지 않아요.','Recall a discovery from direct experience. Do not extend the observed distance or state to unobserved days of operation.','Blicke auf eine Entdeckung aus eigener Erfahrung zurück. Dehne beobachtete Entfernung oder Zustand nicht auf ungeprüfte Öffnungszeiten anderer Tage aus.'),
       ('직접 가 보니 생각보다 멀더군요.','직접 가서 거리를 체감함','타인의 말만 듣고 거리를 추측함'),
       ('직접 읽어 보니 조건이 자세하더군요.','직접 읽고 조건의 상세함을 알게 됨','읽지 않고 다른 사람의 평가만 전달')),
      ('G4:-더라',loc('자신이 경험한 일을 떠올려 전하는 반말이에요. 실제 본 때와 상태를 유지하고 오늘도 그렇다는 보증을 더하지 않아요.','Recall your own experience in casual speech. Preserve when and what you observed without guaranteeing that it remains true today.','Erzähle vertraulich von eigener Erfahrung. Erhalte Zeitpunkt und beobachteten Zustand, ohne Fortbestand für heute zu garantieren.'),
       ('친구에게: 어제 가 보니 문이 닫혀 있더라.','어제 직접 본 닫힌 상태의 회상','오늘 문을 직접 닫았다는 보고'),
       ('친구에게: 아까 보니 복도에 사람이 많더라.','아까 직접 본 사람 많은 상황','내일도 반드시 붐빈다는 확정')),
      ('G4:-던데1',loc('자신의 경험을 배경으로 뒤 질문이나 정보를 덧붙여요. 어제 닫힌 문을 보았다는 근거와 오늘 여는지 묻는 질문을 구분해요.','Use your experience as background for a question or added information. Distinguish yesterday’s observed closure from today’s open-status question.','Nutze eigene Erfahrung als Hintergrund für eine Frage oder Ergänzung. Trenne die gestern beobachtete Schließung von der Frage nach der heutigen Öffnung.'),
       ('어제는 문이 닫혀 있던데 오늘은 여나요?','어제 관찰을 배경으로 오늘 운영 질문','어제와 오늘 운영을 모두 확인 완료'),
       ('지난번에는 설명이 짧던데 이번에는 자료가 있나요?','지난번 경험을 바탕으로 이번 자료 질문','이번 자료가 없다고 이미 확정')),
      ('G4:-는 줄',loc('이 예문에서는 사실과 달랐던 믿음을 바로잡아요. 뒤에 실제 확인한 정보를 함께 두어 과거 믿음과 현재 사실을 구별해요.','In these examples correct a mistaken belief. Use the subsequently confirmed information to distinguish past belief from current fact.','Korrigiere in diesen Beispielen eine falsche Annahme. Unterscheide anhand der anschließend bestätigten Information frühere Annahme und aktuellen Fakt.'),
       ('회의가 내일인 줄 알았어요. 공지를 보니 오늘이었어요.','이전 믿음은 내일, 확인한 일정은 오늘','확인 후에도 내일이라고 결론냄'),
       ('자료가 무료인 줄 알았어요. 가격표를 보니 유료였어요.','이전 믿음은 무료, 확인한 가격은 유료','현재도 무료라고 보증')),
      ('G4:-어야지2',loc('친밀한 관계에서 당위를 강조하는 말끝이에요. 이 장면은 서로 돌보는 친구의 말이며 낯선 동료에게 훈계하는 기본 표현으로 쓰지 않아요.','Emphasise what ought to be done in a close relationship. Here it is mutual care between friends, not a default admonition for unfamiliar colleagues.','Betone in einer engen Beziehung, was getan werden sollte. Hier geht es um gegenseitige Fürsorge, nicht um eine übliche Ermahnung unbekannter Kolleginnen oder Kollegen.'),
       ('서로 돌보는 친구에게: 힘들면 미리 말해야지.','힘들 때 미리 알리라는 친밀한 당위','이미 힘들다고 알렸다는 사실 보고'),
       ('서로 돕기로 한 친구에게: 모르면 같이 물어봐야지.','모를 때 함께 묻자는 친밀한 당위','질문을 금지하는 명령')),
    ]
    tasks=[grammar_task('KP17',i,*r) for i,r in enumerate(rows,1)]
    prod=[
      ('G4:-어라1',('가상 극 대사 속 교사의 직접 명령 / 먼저 자료를 읽다 / -어라','먼저 자료를 읽어라.','자료를 읽어도 된다고 허락했다.'),('가상 극 대사 속 교사의 직접 명령 / 확인한 내용을 적다 / -어라','확인한 내용을 적어라.','확인한 내용을 적을 필요가 없다.')),
      ('G4:-는대2',('축약 전언 / 친구 말로는 오늘 회의가 없다 / -대요','친구 말로는 오늘 회의가 없대요.','담당자 공지를 직접 확인했어요.'),('축약 전언 / 동료 말로는 내일 새 공지가 나오다 / -ㄴ대요','동료 말로는 내일 새 공지가 나온대요.','제가 새 공지를 이미 직접 읽었어요.')),
      ('G4:-고4',('상대의 주말 근무 발언에 덧붙이는 질문 / 그럼 쉬는 날은 없다 / -고요?','그럼 쉬는 날은 없고요?','쉬는 날도 없다고 확정했어요.'),('상대의 회의 취소 발언에 덧붙이는 질문 / 그럼 자료 제출도 없다 / -고요?','그럼 자료 제출도 없고요?','자료 제출 취소도 확정됐어요.')),
      ('G4:-게5',('합의된 반말 친구의 의도 질문 / 이 짐을 어디로 가져가다 / -게?','이 짐을 어디로 가져가게?','이 짐을 그곳으로 반드시 가져가라.'),('합의된 반말 친구의 의도 질문 / 그 자료를 누구에게 보여 주다 / -게?','그 자료를 누구에게 보여 주게?','그 자료를 모두에게 공개하라.')),
      ('G4:-나3',('스스로 의문 검토 / 내가 잘못 듣다 → 다시 생각했어요 / 과거 -나','내가 잘못 들었나 다시 생각했어요.','상대가 거짓말했다고 확정했어요.'),('확인할 의문 / 시간이 바뀌다 → 공지를 다시 읽었어요 / 과거 -나','시간이 바뀌었나 공지를 다시 읽었어요.','시간이 바뀐 것을 이미 확정했어요.')),
      ('G4:-는다니2',('합의된 반말 친구에게 전언 확인 / 내일 회의를 하다 → 시간이 바뀐 거야? / -ㄴ다니?','내일 회의를 한다니? 시간이 바뀐 거야?','내일 회의를 하기로 지금 확정한다.'),('합의된 반말 친구에게 전언 확인 / 오늘 자료를 내다 → 마감이 오늘이야? / -ㄴ다니?','오늘 자료를 낸다니? 마감이 오늘이야?','오늘 자료를 반드시 내라.')),
      ('G4:-는다면서1',('들은 내용 확인 질문 / 다음 달에 이사하다 / -ㄴ다면서요?','다음 달에 이사한다면서요?','상대가 다음 달 이사를 확정해 주었어요.'),('들은 내용 확인 질문 / 오늘 발표하다 / -ㄴ다면서요?','오늘 발표한다면서요?','오늘 발표가 끝나는 것을 직접 보았어요.')),
      ('G4:-다니1',('놀라며 재확인 / 벌써 끝나다 → 정말이에요? / 과거 -다니?','벌써 끝났다니? 정말이에요?','완료 현장을 제가 직접 보았어요.'),('놀란 반응 뒤 확인 계획 / 신청이 취소되다 → 다시 확인해 볼게요 / 과거 -다니?','신청이 취소됐다니? 다시 확인해 볼게요.','제가 취소를 직접 승인했어요.')),
      ('G4:-더군',('직접 경험의 발견 / 직접 가 보니 / 생각보다 멀다 / -더군요','직접 가 보니 생각보다 멀더군요.','가 보지는 않고 다른 사람의 말만 들었어요.'),('직접 경험의 발견 / 직접 읽어 보니 / 조건이 자세하다 / -더군요','직접 읽어 보니 조건이 자세하더군요.','읽지 않고 다른 사람의 평가만 전했어요.')),
      ('G4:-더라',('합의된 반말 친구에게 관찰 회상 / 어제 가 보니 / 문이 닫혀 있다 / -더라','어제 가 보니 문이 닫혀 있더라.','오늘 내가 문을 닫았어.'),('합의된 반말 친구에게 관찰 회상 / 아까 보니 / 복도에 사람이 많다 / -더라','아까 보니 복도에 사람이 많더라.','내일도 반드시 사람이 많을 거야.')),
      ('G4:-던데1',('경험을 배경으로 새 정보 질문 / 어제는 문이 닫혀 있다 → 오늘은 여나요? / -던데','어제는 문이 닫혀 있던데 오늘은 여나요?','오늘 문을 여는 것도 이미 확인했어요.'),('경험을 배경으로 새 정보 질문 / 지난번에는 설명이 짧다 → 이번에는 자료가 있나요? / -던데','지난번에는 설명이 짧던데 이번에는 자료가 있나요?','이번 자료는 없다고 이미 확정했어요.')),
      ('G4:-는 줄',('과거 오해 정정 / 회의가 내일이다 + -ㄴ 줄 알았어요 / 공지를 보니 오늘이었어요','회의가 내일인 줄 알았어요. 공지를 보니 오늘이었어요.','공지 확인 후에도 회의는 내일이에요.'),('과거 오해 정정 / 자료가 무료이다 + -ㄴ 줄 알았어요 / 가격표를 보니 유료였어요','자료가 무료인 줄 알았어요. 가격표를 보니 유료였어요.','가격표 확인 후에도 자료는 무료예요.')),
      ('G4:-어야지2',('서로 돌보는 친구에게 당위 강조 / 힘들면 미리 말하다 / -어야지','힘들면 미리 말해야지.','이미 힘들다고 미리 말했어.'),('서로 돕기로 한 친구에게 당위 강조 / 모르면 같이 물어보다 / -어야지','모르면 같이 물어봐야지.','모르면 절대 질문하지 마.')),
    ]
    tasks+=production('KP17',tasks,prod)
    h=loc('원래 발언자·직접 경험자·확인 질문을 구별하세요. 질문은 답변이 나오기 전까지 결정이 아니며, 극본 인용은 지금의 명령이 아니에요. 관찰한 시간 범위와 미합의점을 유지하고 상대 발언을 끝까지 들으세요.',
      'Distinguish the original speaker, direct witness and checking question. A question is not a decision before an answer, and a script quotation is not a present command. Preserve the observation’s time frame and unresolved points; let others finish.',
      'Trenne ursprüngliche Äußerung, eigene Beobachtung und Rückfrage. Eine unbeantwortete Frage ist keine Entscheidung, ein Drehbuchzitat kein aktueller Befehl. Erhalte Beobachtungszeitraum und offene Punkte; lasse andere ausreden.')
    def meeting(name,other,day):
        return packet(f'가상 극 동아리의 공식 준비 회의입니다. {name} 씨와 {other} 씨는 동등한 동료이며 장소 변경 권한은 없습니다.\n{name}: 친구 말로는 {day} 연습이 없대요. 장소 담당자에게는 아직 확인하지 못했습니다.\n{other}: 저는 어제 직접 갔는데 문이 닫혀 있더군요. 오늘 상태는 모릅니다.\n{name}: {day} 연습이 없다는 뜻인가요?\n진행자: 어제 관찰과 {day} 일정을 나눠 확인합시다. {other} 씨 말씀을 먼저 끝까지 듣겠습니다.\n{other}: 극본에는 교사가 학생에게 "먼저 자료를 읽어라"라고 말합니다. 저는 대사를 인용한 것이며 지금 동료에게 지시하는 것은 아닙니다.\n{name}: 그럼 준비 자료 제출도 없고요?\n진행자: 제출 취소 여부는 아직 모릅니다. 저는 먼저 장소 담당자에게 확인하자는 제안에 찬성합니다. 취소부터 공지하자는 의견에는 아직 근거가 부족하다고 봅니다. 이는 사람에 대한 평가가 아닙니다. 오늘 합의는 담당자에게 일정과 제출 여부를 확인하는 것뿐입니다. 장소나 연습 취소는 결정하지 않았습니다.',[
          choice('report',loc('친구에게 들은 말은?', 'What was heard from a friend?', 'Was wurde von einer befreundeten Person gehört?'),[day+' 연습이 없다는 말','어제 문이 닫힌 직접 경험'],h),
          choice('witness',loc('동료가 직접 확인한 범위는?', 'What did the colleague directly observe?', 'Was hat die andere Person selbst beobachtet?'),['어제 닫힌 문','오늘과 '+day+'의 모든 운영 일정'],h),
          choice('command',loc('먼저 자료를 읽어라의 현재 기능은?', 'What function does 먼저 자료를 읽어라 have here?', 'Welche Funktion hat 먼저 자료를 읽어라 hier?'),['극 중 교사 발언의 인용','동료에게 내리는 새 명령'],h),
          choice('question',loc('제출도 없고요는 무엇인가요?', 'What is 제출도 없고요 doing?', 'Welche Funktion hat 제출도 없고요?'),['제출 여부를 덧붙여 묻는 질문','제출 취소를 보증하는 결정'],h),
          choice('turn',loc('진행자가 조정한 발언 순서는?', 'How does the facilitator manage turns?', 'Wie regelt die moderierende Person die Redereihenfolge?'),[other+'의 설명을 끝까지 듣기','설명을 끊고 취소부터 확정'],h),
          choice('agreement',loc('합의한 내용은?', 'What was agreed?', 'Was wurde vereinbart?'),['담당자에게 일정·제출 여부 확인','연습과 자료 제출 모두 취소'],h),
        ],'audio')
    tasks.append(task('KP17','listening:01','listening',loc('회의의 전언·관찰·결정','Hearsay, observation and decisions in a meeting','Hörensagen, Beobachtung und Beschlüsse im Gespräch'),h,
      meeting('하린','도윤','금요일'),meeting('서연','지후','화요일')))
    def drama(a,b,day):
        return packet(f'창작 극의 짧은 장면입니다. {a}와 {b}는 반말에 합의하고 서로 돌보는 가까운 친구입니다.\n{a}: {day}에 공연을 한다니? 시간이 바뀐 거야?\n{b}: 친구 말로는 그렇대. 나는 아직 공지를 못 봤어.\n{a}: 벌써 정했다니? 내가 잘못 들었나?\n{b}: 어제 가 보니 문이 닫혀 있더라. 오늘은 여는지 몰라.\n{a}: 그 자료를 누구에게 보여 주게?\n{b}: 너에게 원문을 같이 보자고 하려던 거야. 공지를 보면 도움이 되겠지.\n{a}: 모르면 같이 물어봐야지. 네 설명을 먼저 들을게.\n내레이션: 두 친구는 아직 결정을 확인하지 못했다. 놀란 말끝만으로 화가 났다고 단정할 수는 없다.',[
          choice('surprise',loc('벌써 정했다니의 반응은?', 'What response is 벌써 정했다니 expressing?', 'Welche Reaktion drückt 벌써 정했다니 aus?'),['전해 들은 뜻밖의 결정 소식에 놀람','직접 결정권을 행사함'],h),
          choice('source',loc('닫혀 있더라의 근거는?', 'What supports 닫혀 있더라?', 'Worauf beruht 닫혀 있더라?'),['어제 직접 방문','오늘 담당자에게 들은 일정'],h),
          choice('intent',loc('누구에게 보여 주게는?', 'What does 누구에게 보여 주게 ask?', 'Wonach fragt 누구에게 보여 주게?'),['친구의 행동 의도','모든 사람에게 공개하라는 지시'],h),
          choice('stance',loc('놀란 말끝만으로 알 수 없는 것은?', 'What cannot be inferred from surprise alone?', 'Was lässt sich nicht aus Überraschung allein schließen?'),['화가 났는지 여부','확인을 더 해야 한다는 상황'],h),
        ],'audio')
    tasks.append(task('KP17','listening:02','listening',loc('창작 극에서 되묻기와 놀람 듣기','Checking and surprise in an original drama','Rückfrage und Überraschung in einer erfundenen Szene'),h,
      drama('하린','도윤','금요일'),drama('서연','지후','화요일')))
    def literature(a,b,day):
        return f'창작 짧은 이야기 — 접힌 종이\n{a}는 접힌 공지를 손에 쥐고 문 앞에 섰다. {b}가 "{day}에 공연을 한다면서?" 하고 물었다. {a}는 날짜를 잘못 기억한 줄 알았다. 그러나 아직 종이를 펴지는 않았다. "벌써 정했다니?" {a}의 목소리가 높아졌다. {b}는 문을 가리키며 "어제는 닫혀 있던데 오늘은 여나?"라고 말했다. 그 말이 {a}에게는 기다리자는 뜻처럼 들렸다. {b}가 실제로 무엇을 바라는지는 확인하지 않았다. 두 사람은 함께 공지를 펴 보기로 했다. 공지 내용은 이 이야기에서 제시되지 않는다.\n\n별도 공식 회의 기록\n두 발언은 합의된 반말을 쓰는 친구 사이의 대화이며 공식 운영 공지가 아니다. 첫 발언은 들은 공연 일정을 확인하는 질문, 둘째는 어제 관찰을 배경으로 오늘 운영을 묻는 질문이다. 일정 확정과 오늘 운영 상태는 미확인이다. 함께 원문을 확인하기로 한 행동과 공연 일정의 확정을 구별한다. 진행자는 다음 회의에서 원문을 확인한 사람에게 먼저 발언 기회를 주자고 제안했으며 순서는 아직 합의 전이다.'
    def reading(a,b,day):
        return packet(literature(a,b,day),[
          choice('viewpoint',loc('기다리자는 뜻처럼 들렸다는 것은?', 'Whose interpretation is the perceived invitation to wait?', 'Wessen Deutung ist die vermeintliche Aufforderung zu warten?'),[a+'의 해석',b+'의 확인된 의도'],h),
          choice('missing',loc('이야기에서 제시하지 않은 것은?', 'What does the story leave unstated?', 'Was bleibt in der Geschichte ungenannt?'),['공지 원문의 내용','함께 공지를 펴 보기로 한 행동'],h),
          choice('register',loc('친구들의 말끝을 공식 기록으로 옮길 때는?', 'How should the friends’ endings be recorded formally?', 'Wie sollten die Äußerungen förmlich protokolliert werden?'),['확인 질문이라는 화행과 출처 유지','질문을 일정 확정 선언으로 바꾸기'],h),
          choice('tone',loc('높아진 목소리만으로 확정할 수 없는 것은?', 'What cannot be established from the raised voice alone?', 'Was lässt sich aus der angehobenen Stimme allein nicht feststellen?'),['상대를 비난할 의도','소식에 재확인 질문을 했다는 사실'],h),
          choice('turn',loc('다음 회의 발언 순서의 상태는?', 'What is the status of the next meeting’s speaking order?', 'Welchen Status hat die nächste Redereihenfolge?'),['진행자의 제안, 합의 전','이미 모두 합의한 확정 순서'],h),
        ])
    tasks.append(task('KP17','reading:01','reading',loc('문학의 시점과 회의 기록의 거리','Literary viewpoint and the distance of meeting notes','Literarische Perspektive und Distanz im Protokoll'),h,
      reading('하린','도윤','금요일'),reading('서연','지후','화요일')))
    p=meeting('하린','도윤','금요일')['sourceKo']+'\n\n'+literature('하린','도윤','금요일')
    a=meeting('서연','지후','화요일')['sourceKo']+'\n\n'+literature('서연','지후','화요일')
    rubric=loc('첫 글은 공식 회의 기록입니다. 서로 다른 두 발언의 출처·시간·진술/명령/질문 유형을 나누고, 극본의 명령 인용을 새 지시로 바꾸지 마세요. 합의한 확인 업무와 미정인 일정·제출·발언 순서를 구별하고 확인 질문을 덧붙이세요. 둘째 글은 창작 이야기의 리뷰입니다. 시점·높아진 목소리·접힌 공지를 평가 기준으로 삼고 근거 구절, 장점, 한계를 써요. 인물의 해석과 실제 사실을 나누고 다른 독해를 허용하세요. 기록과 비평을 대조해 고쳐 쓰며 전체 의미는 미채점입니다.',
      'First write formal meeting notes. Separate the two accounts by source, time and statement/command/question type; a quoted script command must not become a new instruction. Distinguish agreed verification work from unresolved schedules, submission and speaking order, then add checking questions. Next review the original story using viewpoint, raised voice and folded notice as criteria, citing passages, strengths and limits. Separate character interpretation from fact and allow another reading. Revise notes and review separately; full meaning remains unscored.',
      'Schreibe zuerst ein förmliches Protokoll. Trenne beide Darstellungen nach Quelle, Zeit und Aussage/Befehl/Frage; mache aus einem zitierten Bühnenbefehl keine neue Anweisung. Unterscheide vereinbarte Prüfaufgaben von offenen Terminen, Abgabe und Redereihenfolge und ergänze Rückfragen. Bewerte danach die Geschichte anhand von Perspektive, angehobener Stimme und gefaltetem Hinweis mit Belegstellen, Stärken und Grenzen. Trenne Figurendeutung und Fakt und lasse andere Lesarten zu. Überarbeite Protokoll und Kritik getrennt; Gesamtinhalt bleibt unbewertet.')
    def writing(s):
        return packet(s,[free_text('minutes',loc('두 발언과 확인 질문을 회의 기록으로 쓰세요.','Record both accounts and checking questions in meeting notes.','Protokolliere beide Darstellungen und Rückfragen.'),rubric),free_text('review',loc('창작 이야기의 근거 있는 리뷰를 쓰세요.','Write an evidence-based review of the original story.','Schreibe eine belegte Rezension der Geschichte.'),rubric)],'form')
    tasks.append(task('KP17','writing:01','writing',loc('사실을 기록하고 작품을 따로 평가','Record facts and review the work separately','Fakten protokollieren und das Werk gesondert bewerten'),rubric,writing(p),writing(a)))
    speech=loc('회의 진행자 역할로 각 발언을 합쇼체로 요약하고 진술·인용 명령·추가 질문을 구별하세요. 해요체로 발언을 요청하고 상대가 끝낸 뒤 확인 질문을 하세요. 먼저 확인하자는 제안에 대한 찬성 범위와 취소 공지에 대한 반대 근거를 말하되 사람을 평가하지 마세요. 이어 반말에 합의한 가까운 친구에게 같은 미확인 소식을 다시 말하고 서로 돌보는 말투로 함께 확인하자고 하세요. -는대와 직접 경험 -더라, -다니의 놀람을 풀어 설명하고 녹음의 말끝·휴지를 고쳐요. 의미·억양은 미채점입니다.',
      'As meeting facilitator, formally summarise each account and distinguish statements, quoted commands and added questions. Politely request a turn and ask for clarification after the other person finishes. State the scope of support for checking first and the evidence-based objection to announcing cancellation without judging people. Then restate the same uncertain news to a close friend with agreed casual speech and mutual care. Expand reported -는대, witnessed -더라 and surprise with -다니, replay and revise endings and pauses. Meaning and intonation remain unscored.',
      'Fasse als Moderation jede Darstellung förmlich zusammen und trenne Aussagen, zitierte Befehle und Zusatzfragen. Bitte höflich ums Wort und frage nach, nachdem die andere Person ausgeredet hat. Benenne die begrenzte Zustimmung zur vorherigen Prüfung und den begründeten Einwand gegen eine Absagemeldung, ohne Personen zu bewerten. Gib dieselbe unbestätigte Nachricht danach einer nahestehenden Person mit vereinbarter vertraulicher Anrede und gegenseitiger Fürsorge wieder. Erkläre die Langformen von -는대, beobachtendem -더라 und überraschtem -다니, höre zu und verbessere Endungen und Pausen. Inhalt und Intonation bleiben unbewertet.')
    tasks.append(task('KP17','speaking:01','speaking',loc('두 발언을 중개하고 오해 수리','Mediate two accounts and repair misunderstanding','Zwei Darstellungen vermitteln und Missverständnisse klären'),speech,
      packet(p+'\n가까운 친구 장면: 반말에 합의했고 서로 힘든 일이 있으면 먼저 알리기로 했습니다. 상대의 걱정을 듣고 함께 확인할 수 있는 범위만 제안하세요.',[]),
      packet(a+'\n가까운 친구 장면: 반말에 합의했고 서로 힘든 일이 있으면 먼저 알리기로 했습니다. 상대의 걱정을 듣고 함께 확인할 수 있는 범위만 제안하세요.',[])))
    return tasks


if __name__=='__main__':
    write_source('KP17',kp17())
