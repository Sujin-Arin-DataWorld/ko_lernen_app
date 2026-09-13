"""KP27 concession, intention and negotiated boundaries; unsigned source."""
from phase_task_authoring import choice, free_text, grammar_task, loc, packet, task, write_source
from author_phase_a1_production import production


def kp27():
    rows=[
      ('G6:-은들',loc('극단적 가정도 뒤 결과를 바꾸지 못한다는 수사예요. 질문 형태를 정보 요청으로만 읽지 않습니다.','A rhetorical concession says even an extreme assumption cannot change the result; the question need not request information.','Eine rhetorische Einräumung erklärt, dass selbst eine extreme Annahme das Ergebnis nicht ändert; die Frage verlangt nicht zwingend Information.'),('이제 와서 후회한들 이미 버린 자료가 돌아오겠습니까?','후회해도 이미 버린 자료는 돌아오지 않는다는 수사','후회하면 자료 복구를 보장'),('사람이 더 모인들 근거 없는 주장이 사실이 되겠습니까?','참여자 증가가 주장의 참을 입증하지 않음','참여자가 많으면 주장이 반드시 참')),
      ('G6:-을망정',loc('불리한 결과를 감수해도 원칙을 유지해요. 감수는 화자 자신의 선택이며 다른 사람의 의무가 아닙니다.','Maintain a principle while accepting an adverse outcome as your choice, not another person’s duty.','Halte an einem Prinzip trotz nachteiliger Folgen als eigener Wahl fest, nicht als Pflicht anderer.'),('손해를 볼망정 확인한 사실만 말하겠습니다.','화자가 손해 감수와 사실 진술을 선택','모든 동료에게 손해를 강제'),('일정이 늦어질망정 동의 없이 자료를 쓰지는 않겠습니다.','지연 감수, 무동의 사용 거절','지연이 나면 동의 조건 삭제')),
      ('G6:-는 한이 있어도',loc('극단적 대가까지 감수하는 결심을 밝혀요. 실제 수락 조건과 다른 사람에게 전가할 수 없는 자기 결의를 구별합니다.','State commitment despite an extreme cost, distinguishing personal resolve from actual acceptance conditions or duties imposed on others.','Äußere Entschlossenheit trotz extremer Kosten und trenne sie von tatsächlichen Annahmebedingungen und Pflichten anderer.'),('시간이 더 드는 한이 있어도 근거를 확인하겠습니다. 제 시간에 관한 결심입니다.','자기 시간 감수와 확인 결심','동료 전원에게 무제한 연장 의무'),('다시 쓰는 한이 있어도 출처를 바로잡겠습니다. 다른 사람에게 강요하지 않습니다.','자기 재작성 감수','남에게 재작성 명령')),
      ('G6:-기로서니',loc('앞 사정을 인정해도 뒤 행동은 정당화되지 않는다는 질책이에요. 동등한 동료에게는 강도가 부담이 될 수 있어 행동 근거를 직접 설명하며 수리합니다.','Reproach an action as unjustified despite conceding the circumstances. With an equal peer, repair excessive force by explaining the action and grounds directly.','Weise eine Handlung trotz zugestandener Umstände als ungerechtfertigt zurück. Gegenüber Gleichgestellten repariere übermäßige Schärfe durch konkrete Handlung und Begründung.'),('아무리 바쁘기로서니 확인도 없이 단정해서야 되겠습니까?','바쁨 인정, 미확인 단정 정당화 거절','바쁘면 확인 생략 허용'),('아무리 비용이 들기로서니 동의를 생략해서야 되겠습니까?','비용 인정, 동의 생략 정당화 거절','비용이 들면 동의 자동 면제')),
      ('G6:-는다고1',loc('이 용례는 하려던 목적과 뜻밖의 결과를 대비합니다. 인용·이유 용법과 문맥으로 구별해요.','Here the form contrasts an intended purpose with an unintended result. Use context to distinguish quotation or reason uses.','Hier kontrastiert die Form beabsichtigten Zweck und unbeabsichtigtes Ergebnis. Unterscheide anhand des Kontexts Zitat- oder Grundverwendung.'),('분위기를 풀어 준다고 한 말이 도리어 상처가 되었다. 화자는 위로할 의도였다고 밝혔다.','위로 의도와 상처 결과의 차이','상처를 주려는 의도를 확인'),('부담을 덜어 준다고 일을 대신 정한 것이 선택권을 줄였다. 돕는 것이 목적이었다.','도움 목적과 선택권 축소 결과','선택권 축소가 원래 명시된 목적')),
      ('G6:-자면1',loc('의도한 행동을 실행하는 데 필요한 조건을 제시해요. 이미 그 행동을 완료했다는 뜻은 아닙니다.','State a condition needed to carry out an intended action, not that it is already completed.','Nenne eine Voraussetzung für eine beabsichtigte Handlung, nicht ihren bereits erfolgten Abschluss.'),('차이를 제대로 설명하자면 맥락부터 살펴야 합니다.','설명을 위한 맥락 확인 필요','설명을 이미 모두 끝냄'),('접점을 찾자면 각자의 거절 이유를 먼저 들어야 합니다.','접점 탐색에 필요한 경청','모두의 거절 이유가 같다고 확정')),
      ('G6:-자니3',loc('고려 중인 선택이 낳는 난처함을 드러내요. 선택을 이미 실행한 사실이나 확정 결과와 구별합니다.','Express difficulty associated with a contemplated choice, not an executed action or certain outcome.','Zeige die Schwierigkeit einer erwogenen Wahl, nicht eine ausgeführte Handlung oder sichere Folge.'),('그대로 두자니 문제가 커질 것 같았습니다. 아직 정하지 않았습니다.','유지 선택의 예상 부담, 미결','이미 방치해 문제가 커졌음'),('지금 취소하자니 신청자에게 불편을 줄까 걱정됩니다.','취소 선택의 우려','취소 이미 확정')),
      ('G6:-으려도',loc('하려는 의도에도 장애 때문에 실행할 수 없음을 말해요. 의도 부재나 자발적 거절로 바꾸지 않아요.','An obstacle prevents an intended action; do not turn this into lack of intent or voluntary refusal.','Ein Hindernis verhindert beabsichtigtes Handeln; mache daraus weder fehlende Absicht noch freiwillige Weigerung.'),('다시 설명하려도 발언 기회가 주어지지 않았습니다.','설명 의도 있으나 기회 없음','설명하기 싫어 자발적 거절'),('자료를 확인하려도 원본에 접근할 수 없었습니다.','확인 의도 있으나 접근 장애','원본을 모두 확인 완료')),
      ('G6:-을라치면',loc('어떤 행동을 시작하려 할 때 생기는 반복적 방해를 서술해요. 서술된 장면의 경향을 모든 미래 사건으로 확대하지 않습니다.','Describe recurrent interruption when an action is about to begin, without generalising the narrated pattern to all future events.','Beschreibe wiederkehrende Störungen beim Handlungsansatz, ohne das erzählte Muster auf jede Zukunftssituation zu übertragen.'),('그날 설명을 시작할라치면 누군가 말을 끊었습니다.','그날 시작 시 반복된 방해','모든 미래 설명도 반드시 중단'),('그날 질문을 꺼낼라치면 시간이 끝났다는 말이 나왔습니다.','그날 질문 시도마다 시간 종료 반응','질문에 충분히 답변 완료')),
      ('G6:-을 바에',loc('피하고 싶은 선택과 비교해 대안을 택해요. 화자 선택을 청자의 강제 의무로 바꾸지 않습니다.','Choose an alternative over an unwanted option without turning your choice into a duty for the listener.','Wähle eine Alternative gegenüber einer unerwünschten Option, ohne die eigene Wahl zur Pflicht des Gegenübers zu machen.'),('이대로 포기할 바에 차라리 다시 확인하겠습니다.','포기보다 재확인을 화자가 선택','청자에게 포기 명령'),('출처를 지울 바에 차라리 문장을 줄이겠습니다.','출처 삭제보다 분량 축소 선택','출처를 반드시 삭제하겠다고 약속')),
      ('G4:-더라도',loc('조건이 달라져도 유지되는 결론을 제시합니다. 표현만으로 고정 강도를 매기지 말고 감수 대상과 후행 결론을 비교해요.','Maintain a conclusion under changed conditions. Compare costs and conclusions instead of ranking force by the ending alone.','Erhalte einen Schluss bei geänderten Bedingungen. Vergleiche Kosten und Folgerung statt die Stärke allein nach dem Satzende zu ordnen.'),('결과가 달라지더라도 확인한 근거는 공개하겠습니다. 식별 정보는 제외합니다.','결과 변화에도 공개, 식별 정보 제외 유지','결과가 달라지면 개인정보도 모두 공개'),('일정이 늦어지더라도 자료 사용 동의는 확인하겠습니다.','지연에도 동의 확인 유지','지연되면 동의 확인 생략')),
    ]
    tasks=[grammar_task('KP27',i,*r) for i,r in enumerate(rows,1)]
    prod=[
      ('G6:-은들',('이미 버린 자료 / 지금 후회해도 돌아오지 않음의 수사 / 후회한들, 격식 질문','이제 와서 후회한들 이미 버린 자료가 돌아오겠습니까?','지금 후회하면 자료가 반드시 돌아옵니다.'),('사람 더 모여도 근거 없는 주장은 참 아님 / 모인들, 격식 질문','사람이 더 모인들 근거 없는 주장이 사실이 되겠습니까?','사람이 많으므로 근거 없는 주장도 사실입니다.')),
      ('G6:-을망정',('화자 손해 감수 / 확인 사실만 진술 / 볼망정','손해를 볼망정 확인한 사실만 말하겠습니다.','손해를 보더라도 모두가 제 말을 따라야 합니다.'),('지연 감수 / 무동의 자료 사용 거절 / 늦어질망정','일정이 늦어질망정 동의 없이 자료를 쓰지는 않겠습니다.','일정이 늦어지면 동의 없이 자료를 쓰겠습니다.')),
      ('G6:-는 한이 있어도',('화자의 추가 시간 감수 / 근거 확인 / 더 드는 한이 있어도','시간이 더 드는 한이 있어도 근거를 확인하겠습니다.','모든 동료는 무제한으로 시간을 더 써야 합니다.'),('화자의 재작성 감수 / 출처 정정 / 다시 쓰는 한이 있어도','다시 쓰는 한이 있어도 출처를 바로잡겠습니다.','다른 사람이 반드시 다시 써야 합니다.')),
      ('G6:-기로서니',('인용된 질책 재현 / 아무리 바쁘다 / 미확인 단정 정당화 거절 / 바쁘기로서니','아무리 바쁘기로서니 확인도 없이 단정해서야 되겠습니까?','바쁘면 확인 없이 단정해도 됩니다.'),('인용된 질책 재현 / 아무리 비용 들다 / 동의 생략 정당화 거절 / 들기로서니','아무리 비용이 들기로서니 동의를 생략해서야 되겠습니까?','비용이 들면 동의를 생략해도 됩니다.')),
      ('G6:-는다고1',('분위기를 풀어 주려는 의도 / 한 말 / 도리어 상처 결과 / 준다고','분위기를 풀어 준다고 한 말이 도리어 상처가 되었다.','상처를 주려고 한 말이 계획대로 상처가 되었다.'),('부담 덜어 주려는 목적 / 일을 대신 정함 / 선택권 축소 / 준다고','부담을 덜어 준다고 일을 대신 정한 것이 선택권을 줄였다.','선택권을 줄이려고 일을 대신 정했다.')),
      ('G6:-자면1',('차이 제대로 설명 목적 / 맥락 먼저 살펴야 / 설명하자면','차이를 제대로 설명하자면 맥락부터 살펴야 합니다.','차이 설명을 모두 마쳤습니다.'),('접점 탐색 목적 / 각자 거절 이유 먼저 들어야 / 찾자면','접점을 찾자면 각자의 거절 이유를 먼저 들어야 합니다.','모두의 거절 이유는 같습니다.')),
      ('G6:-자니3',('유지 고려 / 문제 커질 것 같음 / 그대로 두자니 / 미결','그대로 두자니 문제가 커질 것 같았습니다. 아직 정하지 않았습니다.','그대로 두어 문제가 이미 커졌습니다.'),('지금 취소 고려 / 신청자 불편 우려 / 취소하자니','지금 취소하자니 신청자에게 불편을 줄까 걱정됩니다.','지금 취소하기로 확정했습니다.')),
      ('G6:-으려도',('재설명 의도 / 발언 기회 없음 / 설명하려도','다시 설명하려도 발언 기회가 주어지지 않았습니다.','설명할 기회가 있었지만 하기 싫었습니다.'),('자료 확인 의도 / 원본 접근 불가 / 확인하려도','자료를 확인하려도 원본에 접근할 수 없었습니다.','자료 원본을 모두 확인했습니다.')),
      ('G6:-을라치면',('그날 설명 시작 시 반복 말 끊김 / 시작할라치면','그날 설명을 시작할라치면 누군가 말을 끊었습니다.','앞으로 모든 설명은 반드시 중단됩니다.'),('그날 질문 시도 / 시간 종료 발언 반복 / 꺼낼라치면','그날 질문을 꺼낼라치면 시간이 끝났다는 말이 나왔습니다.','그날 모든 질문에 충분한 답을 받았습니다.')),
      ('G6:-을 바에',('포기보다 재확인 선택 / 포기할 바에 차라리','이대로 포기할 바에 차라리 다시 확인하겠습니다.','지금 그대로 포기하겠습니다.'),('출처 삭제보다 문장 축소 선택 / 지울 바에 차라리','출처를 지울 바에 차라리 문장을 줄이겠습니다.','문장을 유지하고 출처를 지우겠습니다.')),
      ('G4:-더라도',('결과 변화에도 확인 근거 공개 / 식별 정보 제외 / 달라지더라도','결과가 달라지더라도 확인한 근거는 공개하겠습니다. 식별 정보는 제외합니다.','결과가 달라지면 식별 정보까지 공개하겠습니다.'),('일정 지연에도 자료 사용 동의 확인 / 늦어지더라도','일정이 늦어지더라도 자료 사용 동의는 확인하겠습니다.','일정이 늦어지면 동의 확인을 생략하겠습니다.')),
    ]
    tasks+=production('KP27',tasks,prod)
    h=loc('양보의 표현뿐 아니라 누가 어떤 대가를 감수하고 어떤 결론을 유지하는지 보세요. 수사·의도·장애·실제 수락 조건을 나누고 반대자의 거절 이유와 선택권을 보존합니다.','Look beyond the concessive form to who bears which cost and maintains which conclusion. Separate rhetoric, intention, obstacle and actual acceptance conditions; preserve opponents’ reasons and choice.','Prüfe über die Einräumungsform hinaus, wer welche Kosten trägt und an welchem Schluss festhält. Trenne Rhetorik, Absicht, Hindernis und tatsächliche Annahmebedingungen; erhalte Ablehnungsgründe und Wahlfreiheit.')
    p=('가람재사용모임',12,8,'수요일')
    a=('솔빛공유모임',15,9,'금요일')
    def debate(args):
        name,total,available,day=args
        return f'''[가상 {name} 공동체 회의. 동등한 참여자와 중재자. 사업 승인 권한은 이 회의에 위임되지 않았다.]
중재자: 제안은 행사에 일회용 컵 대신 재사용 컵을 시험하는 것입니다. 재고 {total}상자 중 점검이 끝난 것은 {available}상자입니다. 세척 인력의 동의와 확인된 점검 범위가 실제 수락 조건입니다. 환경 효과나 비용의 비교 측정값은 아직 없습니다.
참여자 하나: 시간이 더 드는 한이 있어도 근거를 확인하겠습니다. 제 시간에 관한 결심이지 다른 분의 연장 근무를 요구하는 말은 아닙니다. 손해를 볼망정 확인한 사실만 말하겠습니다. 사람이 더 모인들 근거 없는 주장이 사실이 되겠습니까? 환경에 좋다는 뜻만으로 측정이 생기지는 않습니다.
참여자 둘: 저는 자원봉사자의 추가 시간에 동의가 없어서 지금 전면 시행에는 찬성하지 않습니다. 확인 가능한 수량으로 줄이고 참여 시간을 각자 선택하게 하면 소규모 시험은 검토할 수 있습니다. 비용 때문에 반대한다고 하나로 묶지는 말아 주세요.
참여자 셋: 저는 비용 자료가 없다는 이유로 전면 시행에 반대합니다. 일정 축소만으로 비용 불확실성이 사라지지는 않습니다. 두 분의 거절 이유는 다릅니다. 지금 취소하자니 이미 신청한 사람들에게 불편을 줄까 걱정됩니다. 그렇다고 시행에 동의한 것은 아닙니다.
참여자 하나: 아무리 바쁘기로서니 확인도 없이 단정해서야 되겠습니까? 방금 표현이 질책처럼 들렸다면 행동의 근거를 다시 말하겠습니다. 확인 자료가 없으므로 효과를 확정할 수 없다는 뜻입니다. 상대의 성실성을 판단하려던 말은 아닙니다.
참여자 둘: 분위기를 풀어 준다고 한 말이 도리어 상처가 되었습니다. 위로할 의도였다는 설명은 들었지만 느낀 불편이 없어지는 것은 아닙니다. 다시 설명하려도 앞 회의에서는 기회가 주어지지 않았습니다. 그날 설명을 시작할라치면 누군가 말을 끊었습니다. 누가 매번 끊었는지는 이 기록에 없습니다.
중재자: 접점을 찾자면 각자의 거절 이유를 먼저 들어야 합니다. 출처를 지울 바에 차라리 문장을 줄이자는 제안과, {available}상자 이내로 범위를 줄이자는 중재안을 검토하겠습니다. 일정이 늦어지더라도 자료 사용 동의는 확인하겠습니다. 오늘 결정된 것은 {day}에 자료와 조건을 다시 검토한다는 일정뿐입니다. 소규모 시험의 시행 여부와 담당 배분, 최종 승인자는 미정입니다.'''
    def listen(args):
        return packet(debate(args),[
          choice('resolve',loc('시간 감수 결의의 책임 범위는?','Who bears the stated time commitment?','Wer trägt den erklärten zusätzlichen Zeitaufwand?'),['발언자 자신의 시간, 타인의 의무 아님','모든 참여자의 무제한 추가 노동'],h),
          choice('acceptance',loc('실제 수락 조건은?','What are the actual acceptance conditions?','Was sind die tatsächlichen Annahmebedingungen?'),['인력 동의와 확인된 점검 범위','수사적 결심만 있으면 전면 시행'],h),
          choice('reasons',loc('둘과 셋의 거절 이유는?','How do speakers two and three differ?','Wie unterscheiden sich die Ablehnungsgründe?'),['추가 시간 동의 부재 / 비용 근거 부재','둘 다 비용만 문제 삼음'],h),
          choice('intention',loc('분위기를 풀어 준다고의 대비는?','What contrast is marked by the intended easing?','Welchen Gegensatz markiert die beabsichtigte Auflockerung?'),['위로 의도와 상처 결과','고의적 상처와 계획대로의 성공'],h),
          choice('obstacle',loc('설명하려도와 시작할라치면은?','What do the intended and interrupted explanations show?','Was zeigen Erklärungsabsicht und wiederholte Unterbrechung?'),['의도에도 기회 없음과 당시 반복 방해','자발적 설명 거부와 미래의 확정 중단'],h),
          choice('decision',loc('확정된 것과 미결인 것은?','What is settled and what remains open?','Was steht fest und was bleibt offen?'),['재검토 일정만 확정, 시행·역할·승인 미정','전면 시행과 전원 참여 확정'],h),
        ],'audio')
    tasks.append(task('KP27','listening:01','listening',loc('결의·질책·실제 수락 조건의 회의','Meeting on resolve, reproach and acceptance','Sitzung zu Entschlossenheit, Vorwurf und Zustimmung'),h,listen(p),listen(a)))
    def lecture(args):
        return f'''[가상 논증 강연: {args[0]} 사례의 양보]
오늘은 강한 결의와 수락 조건을 구별하겠습니다. 시간이 더 드는 한이 있어도 확인하겠다는 말은 발언자의 감수 선언입니다. 세척 인력의 동의가 확보되었다는 사실 보고는 아닙니다. 극단적 양보가 타인에게 같은 희생을 요구하는 권한을 주지도 않습니다.
이제 두 논증을 비교하겠습니다. A는 손해를 볼망정 사실만 말하겠다고 하면서 실제 손해의 최대치를 자기 교통비로 제한합니다. B는 결과가 달라지더라도 근거를 공개하겠다고 하면서 직업상 불이익 가능성까지 말합니다. 망정이 더라도보다 언제나 더 강한 희생이라는 고정 순위는 이 문맥을 설명하지 못합니다. 감수 대상과 후행 결론, 실제 가능한 범위를 보아야 합니다. B에서도 식별 정보 제외와 사용 동의 조건은 유지됩니다.
다음은 질책과 의도입니다. 바쁘기로서니 확인 없이 단정해서야 되겠느냐는 말은 바쁨을 인정하면서 정당화를 거부합니다. 대등한 토론에서 관계를 압박할 수 있으므로 확인 자료가 없다는 행동 근거로 다시 설명할 수 있습니다. 분위기를 풀어 준다고 한 말이라는 구절은 의도 용례입니다. 이 말이 인용된 이유만으로 결과가 생겼다는 다른 문맥과 섞지 않아야 합니다. 의도를 밝혀도 상대가 겪은 불편이 사라지는 것은 아닙니다.
끝으로 실행 한계를 보겠습니다. 점검 완료 {args[2]}상자를 넘지 않는 시험, 참여자의 시간 선택권, 추가 비용 자료 요청은 서로 다른 조건입니다. 하나의 거절 이유를 충족해도 다른 이유까지 자동 소멸하지 않습니다. 핵심은 양보를 끌어내는 표현의 세기가 아니라 공유 사실과 바뀔 수 있는 조건을 확인하는 협의 절차입니다. 재검토 일정이 {args[3]}이라는 사실과 시행 승인을 분리해야 합니다.'''
    def monologue(args):
        return packet(lecture(args),[
          choice('sequence',loc('강연의 전개는?','How does the lecture develop?','Wie entwickelt sich der Vortrag?'),['결의와 조건 → 양보 문맥 비교 → 질책·의도 → 실행 한계','표현의 고정 순위 → 즉시 전면 시행'],h),
          choice('force',loc('A와 B의 비교가 보여 주는 것은?','What does the A/B comparison show?','Was zeigt der Vergleich von A und B?'),['감수 대상과 범위가 강도 판단에 필요','망정이면 언제나 모든 더라도보다 강함'],h),
          choice('repair',loc('질책의 강도를 수리하는 방법은?','How can excessive reproach be repaired?','Wie lässt sich ein zu scharfer Vorwurf reparieren?'),['상대 성격 대신 확인 자료와 행동 근거 설명','상대에게 같은 희생을 강제'],h),
          choice('limit',loc('한 거절 이유를 해소했을 때는?','What follows from resolving one objection?','Was folgt aus der Klärung eines Ablehnungsgrundes?'),['다른 조건의 충족을 별도로 확인','다른 모든 조건도 자동 소멸'],h),
        ],'audio')
    tasks.append(task('KP27','listening:02','listening',loc('양보의 강도와 협의 절차 강연','Lecture on concession and negotiation','Vortrag zu Einräumung und Verständigung'),h,monologue(p),monologue(a)))
    def essays(args):
        return debate(args)+'''\n[논설 A: 확인 가능한 작은 시험]
나는 전면 시행보다 제한된 시험을 지지한다. 평가 기준은 확인 가능한 범위와 참여자의 선택권이다. 환경 효과가 좋을 것이라는 기대와 측정 근거는 다르다. 점검된 상자만 쓰고 세척 인력이 동의한 시간만 포함해야 한다. 손해를 볼망정 사실만 말하겠다는 내 감수 범위는 개인 교통비이며 다른 참여자의 비용이나 노동을 대신 약속하지 않는다.
가장 강한 반론은 작은 시험도 자료가 없는 비용을 만들 수 있다는 것이다. 나는 규모를 줄였으니 비용 문제가 사라진다고 답하지 않는다. 비용 자료를 얻고 그 기준을 다시 협의하기 전까지 시행 여부는 유보한다. 확인에 시간이 걸린다는 이유로 동의를 생략할 수는 없다. 원칙을 유지하는 것과 특정 실행안을 무조건 승인하는 것은 다르다.
[논설 B: 비용 확인 전 시행 유보]
나는 비용을 확인하기 전에는 작은 시험에도 찬성하기 어렵다. 기준은 규모 자체가 아니라 참여자에게 설명할 수 있는 비용 근거다. 결과가 달라지더라도 확인한 근거를 공개하겠다는 입장은 직업상 불이익 가능성을 감수한다는 뜻을 포함한다. 그래도 식별 정보 제외와 자료 사용 동의 조건은 유지한다. 개인적 결의가 공개 권한을 새로 만드는 것은 아니다.
A의 가장 설득력 있는 점은 참여 시간을 각자 정하고 점검 범위를 제한한다는 것이다. 나는 그 점을 인정한다. 그러나 시간 선택권이 비용 측정의 부재를 상쇄하는 효과를 낸다고 볼 근거는 없다. 비용 자료가 마련되고 참여자가 조건에 동의한다면 논의를 다시 할 수 있다. 한 치도 물러서지 않는다는 수사가 영원한 협의 거부를 뜻할 필요는 없다.
[비교]
두 글은 전면 시행에 바로 동의하지 않고 자료 확인을 요구한다는 점을 공유하지만 우선 가치와 재논의 조건은 다르다. 의견이 평행선을 달린다는 요약만으로 거절 이유를 같게 만들어서는 안 된다. 접점을 찾는 중재안은 각자의 조건과 미합의점을 함께 기록해야 한다.'''
    def read(args):
        return packet(essays(args),[
          choice('shared',loc('두 논설의 공유 사실·입장은?','What do the essays share?','Was teilen die beiden Erörterungen?'),['근거 부족과 즉시 전면 시행 유보','작은 시험은 이미 모두 승인'],h),
          choice('counter',loc('A는 비용 반론에 어떻게 답하나요?','How does A answer the cost objection?','Wie antwortet A auf den Kosteneinwand?'),['축소만으로 해결되지 않아 자료 확인 전 시행 유보','축소하면 모든 비용 근거 불필요'],h),
          choice('strength',loc('양보 강도를 비교할 근거는?','What supports comparing concessive force?','Was erlaubt den Stärkevergleich der Einräumungen?'),['개인 교통비와 직업상 불이익이라는 감수 범위','말끝의 고정 서열만'],h),
          choice('authority',loc('B의 공개 결의가 만들지 않는 것은?','What does B’s resolve not create?','Was schafft Bs Entschlossenheit nicht?'),['새 공개 권한이나 동의 면제','확인 근거를 다루려는 개인 입장'],h),
          choice('condition',loc('재논의 조건의 관계는?','How are the reconsideration conditions related?','Wie hängen Bedingungen erneuter Beratung zusammen?'),['시간 선택·점검 범위·비용 근거는 별개로 확인','하나만 충족하면 전부 충족'],h),
          choice('sense',loc('분위기를 풀어 준다고 한 말의 용법은?','Which use occurs in the intended easing remark?','Welche Verwendung liegt bei der beabsichtigten Auflockerung vor?'),['의도와 결과 대비','분위기가 이미 풀렸다는 검증된 인용만'],h),
        ])
    tasks.append(task('KP27','reading:01','reading',loc('양보·반론·실행 유보의 두 논설','Two essays on concession, objection and deferral','Zwei Erörterungen über Zugeständnis, Einwand und Aufschub'),h,read(p),read(a)))
    rubric=loc('먼저 반대 입장을 가장 설득력 있게 제시한 완결된 논설문을 쓰고, 이어 자신의 입장으로 재구성한 논설문을 쓰세요. 공유 사실·확인된 수량·미상 환경 효과·비용 근거와 달라진 가치 판단을 구별합니다. 각각 주장·근거·가장 강한 반론·범위가 맞는 응답·실행 한계를 포함하세요. 극단 조건에서도 유지할 원칙, 감수할 자신의 대가, 타인의 동의가 필요한 경계를 따로 씁니다. -을망정과 -더라도의 힘을 표현 목록이 아니라 개인 교통비와 직업상 불이익 문맥으로 비교하세요. 의도를 결과로, 재검토 일정을 승인으로 바꾸지 말고 조건이 바뀌는 반례와 중재 대안을 덧붙입니다. 원문과 대조해 반대자의 거절 이유를 약화한 곳과 무상쇄 조건을 고쳐 재작성하세요. 자유 논증·의미는 미채점입니다.',
      'First write a complete strongest-case opposing essay, then reconstruct it from your position. Separate shared facts, checked quantities, unknown environmental effects and cost evidence from changed value judgements. Include claim, grounds, strongest objection, a response of matching scope and implementation limits in each. Distinguish principles maintained under extreme conditions, your own accepted costs and boundaries requiring others’ consent. Compare 망정 and 더라도 through personal travel costs and professional disadvantage, not a fixed expression ranking. Do not turn intention into outcome or review dates into approval. Add counterexamples with changed conditions and mediation alternatives. Revise against the sources to repair weakened objections and conditions not offset by others. Free argument and meaning remain unscored.',
      'Schreibe zuerst eine vollständige, möglichst überzeugende Erörterung der Gegenposition und rekonstruiere sie dann aus deiner Position. Trenne gemeinsame Fakten, geprüfte Mengen, unbekannte Umweltwirkungen und Kostengrundlagen von geänderten Wertungen. Beide Texte brauchen These, Begründung, stärksten Einwand, passende Antwort und Umsetzungsgrenzen. Trenne auch unter Extrembedingungen gewahrte Prinzipien, selbst getragene Kosten und zustimmungsbedürftige Grenzen. Vergleiche 망정 und 더라도 anhand privater Fahrtkosten und beruflicher Nachteile statt einer festen Formrangfolge. Mache Absicht nicht zum Ergebnis und Prüftermine nicht zu Genehmigungen. Ergänze Gegenbeispiele bei geänderten Bedingungen und Vermittlungsalternativen. Korrigiere abgeschwächte Gegenargumente und nicht gegenseitig aufgehobene Bedingungen anhand der Quellen. Freie Argumentation und Bedeutung bleiben unbewertet.')
    def writing(args):
        return packet(essays(args),[
          free_text('opposition',loc('반대 입장의 완결된 논설문','Complete opposing-position essay','Vollständige Erörterung der Gegenposition'),rubric),
          free_text('position',loc('자기 입장 논설문·조건 변화·중재안','Own position, changed conditions and mediation','Eigene Position, Bedingungsänderung und Vermittlung'),rubric),
        ],'form')
    tasks.append(task('KP27','writing:01','writing',loc('극단 조건의 원칙과 실행 한계 논증','Argue principles and limits under extreme conditions','Prinzipien und Grenzen bei Extrembedingungen begründen'),rubric,writing(p),writing(a)))
    speech=loc('동등한 참여자에게 해요체로 각자의 거절 이유를 확인한 뒤 합쇼체 회의 요약을 녹음하세요. 자기 결의·타인의 선택권·실제 수락 조건·미합의점을 구별합니다. 시간 선택권을 보장해도 비용 자료가 없다는 다른 거절이 남는 상황을 중재하고, 확인된 범위의 시험과 시행 유보라는 대안을 같은 기준으로 비교하세요. 원칙을 지켜도 타인에게 같은 희생을 명령하지 않습니다. 질책처럼 들린 -기로서니를 인격 판단 대신 확인 자료와 행동의 문제로 수리하세요. 모어가 다른 동료에게 한국어로 수사적 가정을 실제 약속으로, 의도와 결과의 대비를 고의적 상처로 옮기는 오류를 설명합니다. -은들·-을망정·-는 한이 있어도 뒤의 결론을 의미 단위로 녹음·재생해 선택권이 지워지는 휴지와 강조를 고쳐 다시 말하세요. 승인과 역할은 미정으로 남깁니다. 의미·억양·협상 결과는 미채점입니다.',
      'Politely check each equal participant’s reason for refusal, then record a formal meeting summary. Separate personal resolve, others’ choice, actual acceptance conditions and disagreement. Mediate the case where time choice is protected but missing cost evidence remains; compare a limited verified trial and deferral using common criteria. Keeping a principle does not command equal sacrifice from others. Repair reproachful 기로서니 as a source-and-action issue rather than a personality judgement. In Korean explain to a colleague with another first language the errors of turning rhetoric into an actual promise and an intention/outcome contrast into intentional hurt. Record and replay the conclusions following 은들, 망정 and 는 한이 있어도 in meaning units, revising pauses or emphasis that erase choice. Leave approval and roles open. Meaning, prosody and negotiated outcomes remain unscored.',
      'Kläre höflich die Ablehnungsgründe gleichgestellter Beteiligter und nimm danach eine förmliche Sitzungszusammenfassung auf. Trenne eigene Entschlossenheit, Wahlfreiheit anderer, tatsächliche Zustimmungsbedingungen und Dissens. Vermittle, wenn freie Zeiteinteilung gesichert ist, Kostengrundlagen aber fehlen; vergleiche begrenzten geprüften Versuch und Aufschub mit gleichen Kriterien. Prinzipientreue befiehlt anderen kein gleiches Opfer. Repariere vorwurfsvolles 기로서니 als Quellen- und Handlungsfrage statt Persönlichkeitsurteil. Erkläre einer Person anderer Erstsprache auf Koreanisch die Fehler, Rhetorik zur Zusage und Absichts-Ergebnis-Kontrast zur absichtlichen Verletzung zu machen. Nimm Schlüsse nach 은들, 망정 und 는 한이 있어도 in Sinneinheiten auf, höre sie an und verbessere Pausen oder Betonungen, die Wahlfreiheit tilgen. Lasse Genehmigung und Rollen offen. Bedeutung, Prosodie und Verhandlungsergebnisse bleiben unbewertet.')
    tasks.append(task('KP27','speaking:01','speaking',loc('거절 이유를 구별하는 중재 회의','Mediate distinct reasons for refusal','Unterschiedliche Ablehnungsgründe vermitteln'),speech,packet(essays(p),[]),packet(essays(a),[])))
    return tasks


if __name__=='__main__':
    write_source('KP27',kp27())
