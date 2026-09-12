"""KP15 causal claims and evaluation. Source generation does not approve it."""
from phase_task_authoring import choice, free_text, grammar_task, loc, packet, task, write_source
from author_phase_a1_production import production


def kp15():
    rows=[
      ('G4:-더니',loc('앞서 관찰한 상태와 뒤의 변화를 연결해요. 여기서는 날씨 변화이며 먼저 일어난 일이 뒤 사건의 원인이라는 뜻은 아니에요.','Connect an observed earlier state with a later change. Here this is weather change, not proof that the earlier event caused the later one.','Verbinde einen zuvor beobachteten Zustand mit einer späteren Veränderung. Hier geht es um Wetteränderung, nicht um einen Kausalnachweis.'),
       ('아침에는 비가 오더니 오후에는 맑아졌어요.','아침 비에서 오후 맑은 날씨로 변함','오후 비가 아침 맑음의 원인이 됨'),
       ('오전에는 조용하더니 점심에는 사람들이 많아졌어요.','오전의 조용함 뒤 점심에 사람이 많아짐','오전부터 계속 사람이 없었다는 뜻')),
      ('G4:-고서',loc('앞 행동을 마친 다음 뒤 행동을 했다고 순서를 분명히 해요. 자료 확인 뒤 의견을 냈다는 말은 그 의견이 반드시 옳다는 보증이 아니에요.','Make the sequence clear: the first action finishes before the next. Checking material before an opinion does not guarantee that the opinion is correct.','Mache die Reihenfolge deutlich: Die erste Handlung endet vor der nächsten. Eine Quellenprüfung garantiert keine richtige Meinung.'),
       ('자료를 확인하고서 의견을 냈어요.','자료 확인 다음 의견 제시','의견을 낸 뒤 처음 자료 확인'),
       ('접수 번호를 적고서 전화를 끊었어요.','번호 기록 다음 통화 종료','번호를 적기 전에 통화 종료')),
      ('G4:-기에',loc('판단이나 행동의 이유를 앞에 제시해요. 격식 있는 문맥에서도 쓰며, 설명 부족이라는 판단과 확인된 수치·사실을 구별해요.','State the reason for a judgement or action, including in formal contexts. Keep an evaluation of insufficient explanation separate from measured facts.','Nenne einen Grund für Einschätzung oder Handlung, auch in förmlichen Kontexten. Trenne die Bewertung einer unzureichenden Erklärung von gemessenen Fakten.'),
       ('설명이 부족하기에 다시 물었습니다.','설명이 부족하다고 보아 재질문함','충분한 설명을 이미 받아 질문을 취소함'),
       ('기록이 서로 다르기에 원문을 확인했습니다.','기록 차이 때문에 원문 확인','원문 확인이 기록 차이를 없앴다고 확정')),
      ('G4:-는 바람에',loc('뜻밖의 일 때문에 뒤 결과가 생긴 맥락이에요. 이 예문에서는 좋지 않은 결과를 말하지만 바람에라는 형태만으로 누군가의 책임을 확정하지 않아요.','Present a consequence of an unexpected event. These examples describe adverse results, but the ending alone does not establish someone’s responsibility.','Stelle eine Folge eines unerwarteten Ereignisses dar. Hier sind die Folgen ungünstig; die Endung allein begründet aber keine Verantwortlichkeit.'),
       ('기차가 늦는 바람에 약속에 늦었어요.','뜻밖의 기차 지연으로 약속에 늦음','기차가 일찍 와서 약속을 앞당김'),
       ('전기가 끊기는 바람에 발표가 멈췄어요.','예상 못 한 정전 때문에 발표 중단','발표자가 계획대로 전기를 끊었다고 확인')),
      ('G4:-는 탓에',loc('원인에 대한 부정적 평가나 탓하는 태도가 담겨요. 화자의 평가를 사실 확인이나 법적 책임 판단으로 옮기지 않아요.','Express a negative evaluation or blame toward a cause. Do not convert that stance into verified fact or a legal allocation of liability.','Drücke eine negative Bewertung oder Schuldzuweisung zur Ursache aus. Mache daraus keine bestätigte Tatsache oder rechtliche Haftungszuweisung.'),
       ('준비가 부족한 탓에 진행이 늦어졌어요.','준비 부족을 부정적으로 평가하며 지연 이유로 듦','준비가 충분했다고 중립적으로 보고함'),
       ('안내가 늦은 탓에 참가자들이 기다렸어요.','늦은 안내를 부정적으로 평가함','참가자가 안내 지연 책임을 인정했다는 뜻')),
      ('G4:-는 통에',loc('여러 일이 겹치거나 어수선한 상황에서 생긴 영향을 말해요. 상황의 혼란을 나타내는 표현과 각 사람의 의도를 구별해요.','Describe an effect arising amid overlapping activity or commotion. Confusion in a situation does not establish each person’s intention.','Beschreibe eine Folge inmitten überlappender Vorgänge oder Unruhe. Die Unübersichtlichkeit belegt nicht die Absicht jeder Person.'),
       ('모두 한꺼번에 말하는 통에 설명을 듣지 못했어요.','겹친 말 때문에 설명을 못 들음','모두 조용히 기다려 설명을 잘 들음'),
       ('사람들이 몰려드는 통에 출입구가 막혔어요.','몰려드는 혼란 속에서 출입구가 막힘','모든 사람이 고의로 출입구를 막았다고 확인')),
      ('G4:으로 인하여',loc('격식 있는 원인·결과 연결이에요. 표현 자체는 탓에처럼 비난을 담지 않지만, 원인 주장이 확인됐는지는 별도로 출처를 살펴요.','Use a formal causal connection. Unlike 탓에 it does not itself encode blame, but the source still matters for whether the cause is established.','Verwende eine förmliche Kausalverbindung. Anders als 탓에 enthält sie an sich keine Schuldzuweisung; ob die Ursache belegt ist, hängt dennoch von der Quelle ab.'),
       ('폭우로 인하여 행사가 연기되었습니다.','폭우를 연기 원인으로 격식 있게 제시','행사 담당자의 잘못을 형태 자체가 확정'),
       ('정전으로 인하여 안내 화면이 꺼졌습니다.','정전을 화면 꺼짐의 원인으로 제시','모든 직원의 고의를 확인했다는 뜻')),
      ('G4:-는 사이에',loc('앞 행동이 진행되는 시간 안에 다른 일이 일어났어요. 시간상 겹쳤다는 정보만으로 책임이나 원인을 더하지 않아요.','Locate one event within the period of another action. Temporal overlap alone does not assign cause or responsibility.','Ordne ein Ereignis dem Zeitraum einer anderen Handlung zu. Zeitliche Überschneidung allein weist weder Ursache noch Verantwortung zu.'),
       ('잠깐 자리를 비우는 사이에 회의가 끝났어요.','자리를 비운 시간 안에 회의 종료','자리를 비운 사람이 회의를 끝내라고 명령함'),
       ('동료가 전화하는 사이에 안내가 바뀌었어요.','통화하는 시간 안에 안내 변경','동료의 전화가 안내 변경 원인이라고 확정')),
      ('G4:-는 김에',loc('이미 하려던 일을 기회로 삼아 다른 일도 해요. 우연히 문제가 생겼다는 뜻이나 원래 계획의 취소와 구별해요.','Use an already planned action as an opportunity for an additional one. Distinguish this from an accidental problem or cancellation.','Nutze eine ohnehin geplante Handlung als Gelegenheit für eine weitere. Unterscheide dies von einer zufälligen Störung oder Absage.'),
       ('시내에 가는 김에 서류도 내고 왔어요.','시내 방문 기회에 서류도 제출함','시내에 가지 못해 서류 제출도 취소'),
       ('사무실에 들르는 김에 기록도 확인했어요.','사무실 방문 기회에 기록도 확인함','기록 확인 때문에 사무실 방문을 하지 않음')),
      ('G4:-어 대다',loc('행동을 되풀이하는 모습을 강조하며 불편한 태도가 담길 수 있어요. 반복했다는 관찰과 악의가 있었다는 판단을 나누세요.','Emphasise repeated activity, potentially with disapproval. Separate observed repetition from a claim of malicious intent.','Betone wiederholtes Handeln, möglicherweise mit Missbilligung. Trenne beobachtete Wiederholung von einer unterstellten bösen Absicht.'),
       ('모두 질문을 해 대서 설명이 끊겼어요.','반복 질문을 불편하게 평가함','질문은 한 번도 없었다는 뜻'),
       ('알림이 울려 대서 통화에 집중하기 어려웠어요.','알림이 반복해서 울리는 상황','알림이 한 번 울리고 바로 조용해짐')),
      ('G4:-어 버리다',loc('행동이 끝났음을 나타내며 후회나 후련함 같은 태도가 문맥에 따라 달라져요. 여기서는 원치 않은 삭제·파손이며 아직 진행 중인 일과 구별해요.','Mark completion, with regret or relief depending on context. These examples concern unwanted deletion or tearing, not an ongoing action.','Kennzeichne einen Abschluss; Bedauern oder Erleichterung hängen vom Kontext ab. Hier geht es um unerwünschtes Löschen oder Zerreißen, nicht um laufende Vorgänge.'),
       ('필요한 메모를 지워 버렸어요.','필요한 메모 삭제가 이미 일어남','메모 삭제를 막아 그대로 남아 있음'),
       ('중요한 쪽지를 찢어 버렸어요.','쪽지를 이미 찢음','쪽지를 찢을까 걱정만 했고 그대로 보관 중')),
      ('G4:-을 뻔하다',loc('일어날 위험에 가까웠지만 그 사건은 실제로 일어나지 않았어요. 거의 넘어진 일을 실제 부상으로 보고하지 않아요.','An event nearly happened but did not occur. Do not report a near fall as an actual injury.','Ein Ereignis wäre beinahe eingetreten, ist aber ausgeblieben. Berichte einen Beinahe-Sturz nicht als tatsächliche Verletzung.'),
       ('길이 미끄러워 넘어질 뻔했지만 난간을 잡았어요.','넘어질 위험이 있었으나 넘어지지는 않음','실제로 넘어져 부상까지 입었다고 확인'),
       ('번호를 잘못 보낼 뻔했지만 전송 전에 고쳤어요.','잘못 보낼 위험을 전송 전에 막음','잘못된 번호를 이미 보내고 나서 고침')),
      ('G4:-어서인지',loc('앞 사정이 이유일 수 있다고 조심스럽게 추측해요. 집중이 어려운 현상과 추정한 이유의 확신을 따로 보존해요.','Tentatively suggest that an earlier circumstance may be the reason. Keep the observed difficulty and the hypothesised cause at different certainty levels.','Vermute vorsichtig einen Grund im vorangehenden Umstand. Trenne beobachtete Schwierigkeit und vermutete Ursache nach ihrem Gewissheitsgrad.'),
       ('밤을 새워서인지 집중이 잘 안 돼요.','집중 어려움의 이유를 밤샘으로 추측함','집중 어려움의 모든 원인이 확정됨'),
       ('안내가 바뀌어서인지 질문이 많아졌어요.','질문 증가 이유를 안내 변경으로 추측함','질문 증가가 안내 변경의 유일한 원인')),
      ('G1:-고 있다',loc('현재 진행하는 동작을 구별해요. 확인 중인 오류를 확인 완료나 해결 완료로 바꾸지 않아요.','Distinguish an ongoing action. Checking an error is neither a completed check nor a completed fix.','Unterscheide eine laufende Handlung. Eine Fehlerprüfung bedeutet weder abgeschlossene Prüfung noch Behebung.'),
       ('담당자가 오류를 확인하고 있어요.','오류 확인 동작이 진행 중','오류 확인과 해결이 모두 끝남'),
       ('동료가 새 안내를 쓰고 있어요.','안내 작성이 진행 중','안내가 이미 승인되고 배포됨')),
      ('G2:-어 있다',loc('동작 뒤의 결과 상태가 유지돼요. 창문이 열린 상태만으로 누가 열었는지 알 수 없으며 현재 여는 동작과 구별해요.','Describe a continuing resultant state. An open window does not identify who opened it, and differs from the act of opening it now.','Beschreibe einen fortbestehenden Ergebniszustand. Ein offenes Fenster verrät nicht, wer es geöffnet hat, und ist vom gerade stattfindenden Öffnen zu unterscheiden.'),
       ('기록에는 창문이 열려 있다고 나와 있어요.','기록은 열린 상태를 나타냄','특정 담당자가 지금 여는 동작을 직접 관찰함'),
       ('확인한 사진에서는 문이 닫혀 있어요.','사진에서 닫힌 결과 상태가 보임','사진으로 문을 닫은 사람의 의도를 확정함')),
    ]
    tasks=[grammar_task('KP15',i,*r) for i,r in enumerate(rows,1)]
    prod=[
      ('G4:-더니',('관찰한 변화 / 아침에는 비가 오다 → 오후에는 맑아지다 / -더니 / 과거 해요체','아침에는 비가 오더니 오후에는 맑아졌어요.','오후에는 비가 와서 아침에 맑아졌어요.'),('관찰한 변화 / 오전에는 조용하다 → 점심에는 사람들이 많아지다 / -더니 / 과거 해요체','오전에는 조용하더니 점심에는 사람들이 많아졌어요.','오전부터 점심까지 사람이 계속 없었어요.')),
      ('G4:-고서',('완료 뒤 순서 / 자료를 확인하다 → 의견을 내다 / -고서 / 과거 해요체','자료를 확인하고서 의견을 냈어요.','의견을 내고서 자료를 확인했어요.'),('완료 뒤 순서 / 접수 번호를 적다 → 전화를 끊다 / -고서 / 과거 해요체','접수 번호를 적고서 전화를 끊었어요.','전화를 끊고서 접수 번호를 적었어요.')),
      ('G4:-기에',('행동 이유 / 설명이 부족하다 → 다시 묻다 / -기에 / 과거 합쇼체','설명이 부족하기에 다시 물었습니다.','설명이 충분하기에 질문을 취소했습니다.'),('행동 이유 / 기록이 서로 다르다 → 원문을 확인하다 / -기에 / 과거 합쇼체','기록이 서로 다르기에 원문을 확인했습니다.','원문을 확인했으므로 모든 기록 차이가 해결되었습니다.')),
      ('G4:-는 바람에',('뜻밖의 원인 / 기차가 늦다 → 약속에 늦다 / -는 바람에 / 과거 해요체','기차가 늦는 바람에 약속에 늦었어요.','기차가 일찍 와서 약속을 앞당겼어요.'),('뜻밖의 원인 / 전기가 끊기다 → 발표가 멈추다 / -는 바람에 / 과거 해요체','전기가 끊기는 바람에 발표가 멈췄어요.','발표자가 계획대로 전기를 끊었어요.')),
      ('G4:-는 탓에',('원인에 대한 부정적 평가 / 준비가 부족하다 → 진행이 늦어지다 / -ㄴ 탓에 / 과거 해요체','준비가 부족한 탓에 진행이 늦어졌어요.','준비는 충분했고 진행도 늦지 않았어요.'),('원인에 대한 부정적 평가 / 안내가 늦다 → 참가자들이 기다리다 / -은 탓에 / 과거 해요체','안내가 늦은 탓에 참가자들이 기다렸어요.','참가자들이 지연 책임을 인정했어요.')),
      ('G4:-는 통에',('어수선한 상황 / 모두 한꺼번에 말하다 → 설명을 듣지 못하다 / -는 통에 / 과거 해요체','모두 한꺼번에 말하는 통에 설명을 듣지 못했어요.','모두 조용해서 설명을 잘 들었어요.'),('어수선한 상황 / 사람들이 몰려들다 → 출입구가 막히다 / -는 통에 / 과거 해요체','사람들이 몰려드는 통에 출입구가 막혔어요.','모든 사람이 고의로 출입구를 막았어요.')),
      ('G4:으로 인하여',('격식 원인 표현 / 폭우 + 로 인하여 / 행사가 연기되다 / 과거 합쇼체','폭우로 인하여 행사가 연기되었습니다.','폭우가 없었고 행사도 연기되지 않았습니다.'),('격식 원인 표현 / 정전 + 으로 인하여 / 안내 화면이 꺼지다 / 과거 합쇼체','정전으로 인하여 안내 화면이 꺼졌습니다.','모든 직원이 고의로 화면을 껐습니다.')),
      ('G4:-는 사이에',('시간 안의 사건 / 잠깐 자리를 비우다 → 회의가 끝나다 / -는 사이에 / 과거 해요체','잠깐 자리를 비우는 사이에 회의가 끝났어요.','제가 회의를 끝내라고 명령했어요.'),('시간 안의 사건 / 동료가 전화하다 → 안내가 바뀌다 / -는 사이에 / 과거 해요체','동료가 전화하는 사이에 안내가 바뀌었어요.','동료의 전화 때문에 안내가 바뀐 것이 확실해요.')),
      ('G4:-는 김에',('추가 행동의 기회 / 시내에 가다 → 서류도 내고 오다 / -는 김에 / 과거 해요체','시내에 가는 김에 서류도 내고 왔어요.','시내에 가지 못해 서류도 내지 못했어요.'),('추가 행동의 기회 / 사무실에 들르다 → 기록도 확인하다 / -는 김에 / 과거 해요체','사무실에 들르는 김에 기록도 확인했어요.','사무실에 들르지 않고 기록도 확인하지 않았어요.')),
      ('G4:-어 대다',('반복 행동과 불편 / 모두 질문을 하다 → 설명이 끊기다 / -어 대서 / 과거 해요체','모두 질문을 해 대서 설명이 끊겼어요.','질문이 한 번도 없어서 설명이 계속됐어요.'),('반복 상황과 불편 / 알림이 울리다 → 통화에 집중하기 어렵다 / -어 대서 / 과거 해요체','알림이 울려 대서 통화에 집중하기 어려웠어요.','알림은 한 번만 울리고 바로 조용해졌어요.')),
      ('G4:-어 버리다',('원치 않은 완료 / 필요한 메모를 지우다 / -어 버리다 / 과거 해요체','필요한 메모를 지워 버렸어요.','메모를 지우려다가 그대로 남겨 두었어요.'),('원치 않은 완료 / 중요한 쪽지를 찢다 / -어 버리다 / 과거 해요체','중요한 쪽지를 찢어 버렸어요.','중요한 쪽지를 그대로 가지고 있어요.')),
      ('G4:-을 뻔하다',('실제로 넘어지지 않음 / 길이 미끄러워 넘어지다 → 하지만 난간을 잡다 / -ㄹ 뻔하다 / 과거 해요체','길이 미끄러워 넘어질 뻔했지만 난간을 잡았어요.','길에서 넘어져 부상을 입었어요.'),('잘못 전송하지 않음 / 번호를 잘못 보내다 → 하지만 전송 전에 고치다 / -ㄹ 뻔하다 / 과거 해요체','번호를 잘못 보낼 뻔했지만 전송 전에 고쳤어요.','번호를 잘못 보낸 뒤에 고쳤어요.')),
      ('G4:-어서인지',('추정 이유 / 밤을 새우다 → 집중이 잘 안 되다 / -어서인지 / 해요체','밤을 새워서인지 집중이 잘 안 돼요.','밤샘이 집중 문제의 유일한 원인으로 확정됐어요.'),('추정 이유 / 안내가 바뀌다 → 질문이 많아지다 / -어서인지 / 과거 해요체','안내가 바뀌어서인지 질문이 많아졌어요.','질문 증가가 안내 변경의 유일한 원인이에요.')),
      ('G1:-고 있다',('진행 중 / 담당자가 오류를 확인하다 / -고 있다 / 해요체','담당자가 오류를 확인하고 있어요.','담당자가 오류 확인과 해결을 모두 끝냈어요.'),('진행 중 / 동료가 새 안내를 쓰다 / -고 있다 / 해요체','동료가 새 안내를 쓰고 있어요.','동료의 안내가 이미 승인되고 배포됐어요.')),
      ('G2:-어 있다',('기록의 결과 상태 / 기록에는 창문이 열리다 + -어 있다 + 고 / 나와 있어요','기록에는 창문이 열려 있다고 나와 있어요.','기록으로 누가 지금 창문을 여는지 직접 보았어요.'),('사진의 결과 상태 / 확인한 사진에서는 문이 닫히다 / -어 있다 / 해요체','확인한 사진에서는 문이 닫혀 있어요.','사진으로 누가 어떤 의도로 문을 닫았는지 확정했어요.')),
    ]
    tasks+=production('KP15',tasks,prod)
    h=loc('사실의 시간 순서, 원인 주장, 평가 태도, 추측을 따로 표시하세요. 탓에·바람에·통에의 문맥과 인하여를 대조하고 말소리의 크기만으로 비난을 판정하지 않아요. 진행·완료·미실현을 바꾸거나 책임자를 만들어 내지 마세요.',
      'Separate chronology, causal claims, evaluative stance and inference. Contrast the contexts of 탓에, 바람에 and 통에 with 인하여; loudness alone does not establish blame. Preserve ongoing, completed and avoided events without inventing a responsible person.',
      'Trenne Ablauf, Kausalbehauptung, Wertung und Vermutung. Vergleiche den Kontext von 탓에, 바람에 und 통에 mit 인하여; Lautstärke allein belegt keine Schuldzuweisung. Erhalte laufende, abgeschlossene und vermiedene Ereignisse, ohne Verantwortliche zu erfinden.')
    def talk(place,time,minutes):
        return packet(f'가상 {place} 업무 보고입니다. 기록을 확인하고서 말씀드립니다. {time}에 폭우가 시작됐고 주최 측은 폭우로 인하여 실외 행사를 연기했다고 공지했습니다. 현장 직원은 전기가 끊기는 바람에 발표가 멈췄다고 설명했습니다. 한 참가자는 준비가 부족한 탓에 기다렸다며 불만을 말했지만 준비 상태에 대한 조사는 아직 없습니다. 모두 한꺼번에 말하는 통에 직원의 설명을 듣기 어려웠다는 증언도 있습니다. 한 직원은 참가자들이 질문을 해 대었다고 평가했으나 실제 질문 횟수는 기록하지 않았습니다. 확인된 지연은 {minutes}분입니다. 저는 미끄러운 곳에서 넘어질 뻔했지만 난간을 잡아 넘어지지 않았습니다. 개인 메모 한 장은 지워 버렸으나 공식 기록은 남아 있습니다. 지금 담당자가 오류를 확인하고 있습니다. 안내가 바뀌어서인지 질문이 늘어난 것 같지만 원인은 확인 전입니다.',[
          choice('neutral',loc('형태 자체가 비난을 담지 않는 격식 원인 표현은?', 'Which formal cause expression does not itself encode blame?', 'Welcher förmliche Kausalausdruck enthält an sich keine Schuldzuweisung?'),['폭우로 인하여','준비가 부족한 탓에'],h),
          choice('evaluation',loc('준비 부족이라는 평가는 누구의 말이에요?', 'Who evaluated preparation as insufficient?', 'Wer bewertete die Vorbereitung als unzureichend?'),['한 참가자','준비 조사를 마친 조사팀의 확정 결론'],h),
          choice('unexpected',loc('뜻밖의 정전 결과를 나타내는 표현은?', 'Which expression presents an unexpected outage consequence?', 'Welcher Ausdruck stellt eine Folge des unerwarteten Stromausfalls dar?'),['끊기는 바람에','기록을 확인하고서'],h),
          choice('overlap',loc('말이 겹친 상황을 나타내는 표현은?', 'Which expression describes overlapping speech?', 'Welcher Ausdruck beschreibt durcheinandergehendes Sprechen?'),['말하는 통에','폭우로 인하여'],h),
          choice('near',loc('화자의 넘어짐은 실제로 일어났나요?', 'Did the speaker actually fall?', 'Ist die sprechende Person tatsächlich gestürzt?'),['아니요, 난간을 잡아 피했음','예, 실제 부상이 확인됨'],h),
          choice('ongoing',loc('오류 확인의 현재 상태는?', 'What is the status of the error check?', 'Welchen Stand hat die Fehlerprüfung?'),['진행 중','해결까지 완료'],h),
          choice('hypothesis',loc('질문 증가의 원인은?', 'What caused the increase in questions?', 'Was verursachte die Zunahme der Fragen?'),['안내 변경이라는 추측, 확인 전','안내 변경이 유일한 원인으로 확인됨'],h),
        ],'audio')
    tasks.append(task('KP15','listening:01','listening',loc('업무 보고의 원인과 불만','Causes and complaints in a work report','Ursachen und Beschwerden in einem Arbeitsbericht'),h,
      talk('한빛센터','오전 열 시','스무'),talk('새봄센터','오후 두 시','서른')))
    def sources(place,time,minutes):
        return f'학습용 가상 자료 A — 기사\n{place} 행사 안내가 {minutes}분 늦어졌다. 한 참가자는 "준비가 부족한 탓에 기다렸어요"라고 말했다. 기자는 안내가 바뀌어서인지 질문이 늘어난 듯하다고 썼으나 질문 횟수와 변경 전 수치는 조사하지 않았다. 주최 측은 폭우로 인하여 실외 행사를 연기했다고 밝혔다.\n\n자료 B — 내부 문제 보고서\n목적: 안내 지연 경위와 확인 과제 정리. 확인 기록: {time} 폭우 시작, 발표 중 정전 발생, 안내 {minutes}분 지연. 개인 메모 한 장 삭제, 공식 기록 보존. 한 직원은 넘어질 뻔했으나 난간을 잡아 넘어지지 않았다고 진술했다. 오류 확인은 진행 중이다.\n원인과 한계: 정전 발생 자체는 확인했으나 고장 원인과 책임자는 미확인이다. 준비 부족 주장은 참가자 평가이며 조사 결과가 아니다. 질문이 반복됐다는 평가와 정확한 횟수는 별개다. 새 안내 제도와 동시에 지연이 발생했지만 제도가 지연을 일으켰는지는 미확인이다. 고용이나 소비에 미친 영향도 측정하지 않았다.\n후속 조치: 회사의 시설 담당자에게 원인 점검과 답변 가능 시점 확인을 요청한다. 추가 장비 구매는 비용 검토 전 제안이며 승인되지 않았다. 책임 확정 없이 참가자에게 지연 사실과 확인 일정을 알릴 필요가 있다.'
    def reading(place,time,minutes):
        return packet(sources(place,time,minutes),[
          choice('shared',loc('두 자료에서 확인되는 공통 지연 시간은?', 'What delay do both sources report?', 'Welche Verzögerung nennen beide Quellen?'),[minutes+'분','지연은 없었음'],h),
          choice('attribution',loc('준비 부족 주장의 근거 수준은?', 'What supports the inadequate-preparation claim?', 'Worauf beruht die Behauptung unzureichender Vorbereitung?'),['기사의 참가자 발언, 보고서에서도 미검증','보고서에서 완료한 원인 조사의 결론'],h),
          choice('system',loc('새 제도와 지연의 관계는?', 'How is the new scheme related to the delay?', 'Wie hängt die neue Regelung mit der Verzögerung zusammen?'),['동시에 있었으나 인과는 미확인','동시 발생이 원인임을 증명'],h),
          choice('record',loc('지워진 기록의 범위는?', 'What was deleted?', 'Was wurde gelöscht?'),['개인 메모 한 장, 공식 기록은 보존','모든 공식 기록과 개인 메모'],h),
          choice('responsibility',loc('책임자에 관한 보고서 내용은?', 'What does the report establish about responsibility?', 'Was stellt der Bericht zur Verantwortlichkeit fest?'),['아직 미확인','시설 담당자의 책임 확정'],h),
          choice('proposal',loc('추가 장비 구매의 상태는?', 'What is the status of buying extra equipment?', 'Welchen Status hat der Kauf zusätzlicher Geräte?'),['비용 검토 전 제안','승인된 구매 완료'],h),
        ])
    tasks.append(task('KP15','reading:01','reading',loc('기사와 보고서의 주장 대조','Compare claims in an article and a report','Aussagen in Nachricht und Bericht vergleichen'),h,
      reading('한빛센터','오전 열 시','스무'),reading('새봄센터','오후 두 시','서른')))
    p=sources('한빛센터','오전 열 시','스무');a=sources('새봄센터','오후 두 시','서른')
    rubric=loc('같은 사실로 두 글을 쓰세요. 보고서는 목적→확인 사실→출처별 주장→한계→후속 조치 순서로, 이메일은 시설 담당자에게 지연 영향과 원인 점검·답변 가능 시점을 부탁하는 격식 문체로 써요. 불만의 근거와 원하는 조치를 분리하고 책임·원인·구매 승인을 만들어 내지 마세요. 미실현 사고와 삭제 범위도 보존하세요. 두 글을 대조해 확신·의무가 강해진 곳을 고쳐요. 전체 의미·문체는 미채점입니다.',
      'Write two texts from the same facts: a report ordered by purpose, verified facts, source-specific claims, limits and follow-up; and a formal email asking facilities staff to investigate the cause and indicate when they can respond. Separate the complaint’s basis from the requested remedy. Do not invent responsibility, cause or purchase approval. Preserve the avoided accident and deletion scope. Compare and revise any increase in certainty or obligation. Full meaning and style remain unscored.',
      'Schreibe zwei Texte mit denselben Fakten: einen Bericht mit Zweck, bestätigten Fakten, Aussagen je Quelle, Grenzen und Folgeschritten sowie eine förmliche E-Mail an die Gebäudeverantwortlichen mit der Bitte um Ursachenprüfung und möglichen Antworttermin. Trenne Beschwerdegrund und gewünschte Maßnahme. Erfinde weder Verantwortung noch Ursache oder Kaufgenehmigung. Erhalte das vermiedene Ereignis und den Löschumfang. Vergleiche und korrigiere verstärkte Gewissheit oder Verpflichtung. Gesamtinhalt und Stil bleiben unbewertet.')
    def writing(s):
        return packet(s,[free_text('report',loc('보고서를 소제목과 함께 쓰세요.','Write the report with headings.','Schreibe den Bericht mit Überschriften.'),rubric),free_text('email',loc('시설 담당자에게 격식 이메일을 쓰세요.','Write a formal email to the facilities contact.','Schreibe eine förmliche E-Mail an die zuständige Person für das Gebäude.'),rubric)],'form')
    tasks.append(task('KP15','writing:01','writing',loc('같은 사실의 보고서와 격식 이메일','The same facts in a report and formal email','Dieselben Fakten in Bericht und förmlicher E-Mail'),rubric,writing(p),writing(a)))
    speech=loc('회사 동료에게 해요체로 지연의 영향과 확인 중인 일을 설명하세요. 반복 질문이라는 평가, 실제 메모 삭제, 피한 넘어짐을 나누고 담당자의 책임을 확정하지 마세요. 다음에는 합쇼체의 짧은 업무 보고로 바꾸되 같은 사실·추측 강도를 유지해요. 탓에를 인하여로 바꿀 때 비난 태도와 원인 주장의 출처를 각각 설명하세요. 녹음을 듣고 원인절과 후속 행동의 휴지를 고쳐요. 의미·억양은 미채점입니다.',
      'Politely explain the delay’s effects and ongoing checks to a colleague. Separate the evaluation of repeated questions, actual memo deletion and avoided fall, without assigning staff responsibility. Restate as a short formal work report with the same facts and uncertainty. When changing 탓에 to 인하여, explain the stance and source of the causal claim separately. Replay and revise pauses between causes and actions. Meaning and intonation remain unscored.',
      'Erkläre einer gleichgestellten Person höflich die Folgen der Verzögerung und laufende Prüfungen. Trenne die Bewertung wiederholter Fragen, tatsächliche Löschung der Notiz und vermiedenen Sturz, ohne Verantwortung zuzuweisen. Formuliere als kurzen förmlichen Arbeitsbericht mit denselben Fakten und Unsicherheiten um. Erkläre beim Wechsel von 탓에 zu 인하여 Haltung und Quelle der Kausalbehauptung getrennt. Höre zu und verbessere Pausen zwischen Grund und Handlung. Inhalt und Intonation bleiben unbewertet.')
    tasks.append(task('KP15','speaking:01','speaking',loc('영향과 미확인 책임을 구분해 보고','Report effects without inventing responsibility','Folgen ohne erfundene Verantwortlichkeit berichten'),speech,packet(p,[]),packet(a,[])))
    return tasks


if __name__=='__main__':
    write_source('KP15',kp15())
