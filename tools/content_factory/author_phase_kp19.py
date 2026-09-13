"""KP19 specialist process, agency and retained states. Source stays unsigned."""
from phase_task_authoring import choice, free_text, grammar_task, loc, packet, task, write_source
from author_phase_a1_production import production


def kp19():
    rows=[
      ('G5:-다4',loc('신문·보고서의 서술체예요. 객관적으로 기술하려는 문체와 내용의 사실성은 별개이며, 독자에게 반말로 명령하는 것도 아니에요.','Use the declarative style of news and reports. Its impersonal presentation does not itself establish truth or issue a casual command to the reader.','Nutze den Aussagestil von Nachrichten und Berichten. Sachliche Darstellung beweist keine Wahrheit und ist kein vertraulicher Befehl an Lesende.'),
       ('조사 보고서: 이 연구는 두 지역의 이용 기록을 비교한다.','연구 범위를 설명하는 문어 서술','독자에게 두 지역을 비교하라는 반말 명령'),
       ('조사 보고서: 이번 분석은 중복 응답을 제외한다.','분석 기준을 밝히는 문어 서술','모든 분석이 반드시 같은 기준을 쓴다는 증명')),
      ('G5:-기에 앞서(서)',loc('본 행동보다 먼저 할 준비나 검토를 명시해요. 이후 행동을 이미 완료했다고 바꾸지 않아요.','Specify preparation or review before the main action without claiming the later action is complete.','Nenne Vorbereitung oder Prüfung vor der Haupthandlung, ohne deren Abschluss zu behaupten.'),
       ('자료를 공개하기에 앞서 이용 조건을 확인했다.','조건 확인이 자료 공개보다 먼저','자료 공개를 마친 뒤에만 조건 확인'),
       ('결론을 내리기에 앞서 빠진 기록을 검토한다.','결론 전 누락 기록 검토','결론을 확정한 뒤 검토를 생략')),
      ('G5:-는 가운데',loc('큰 상황이 진행되는 배경 속에서 다른 일이 일어나요. 동시적 배경이 원인이나 동의의 근거는 아니에요.','Place an event within an ongoing situation. A simultaneous background is not proof of causation or consent.','Ordne ein Ereignis in eine laufende Situation ein. Gleichzeitiger Hintergrund belegt weder Ursache noch Zustimmung.'),
       ('논의가 계속되는 가운데 새 자료가 공개됐다.','논의가 진행 중일 때 자료 공개','논의가 끝난 뒤에만 자료 공개'),
       ('점검이 진행되는 가운데 일부 장비가 교체됐다.','점검 진행 중 일부 장비 교체','모든 장비의 점검과 교체가 완료됨')),
      ('G5:-는 동시에',loc('동시에 작동하는 두 기능이나 행동을 나란히 제시해요. 하나가 끝나야 다음이 시작된다는 순서와 구별해요.','Present two concurrent functions or actions, not a sequence where one must finish first.','Nenne zwei gleichzeitig wirkende Funktionen oder Handlungen, keine Abfolge nach Abschluss der ersten.'),
       ('이 장치는 기록을 남기는 동시에 접근을 제한한다.','기록과 접근 제한 기능이 함께 작동','기록 기능을 중단한 뒤에만 접근 제한'),
       ('연구팀은 오류를 찾는 동시에 분류 기준을 기록했다.','오류 탐색과 기준 기록이 함께 진행','오류 탐색 완료 후에만 기준 기록 시작')),
      ('G5:-은 채로',loc('한 상태를 바꾸지 않고 다른 일이 진행됨을 표시해요. 미해결 상태로 회의를 마쳤다면 회의 종료와 문제 해결은 별개예요.','Maintain one state while another event occurs. Ending a meeting with a problem unresolved does not solve the problem.','Erhalte einen Zustand während eines anderen Ereignisses. Eine Sitzung mit ungelöstem Problem zu beenden löst das Problem nicht.'),
       ('원인을 확인하지 못한 채 회의가 끝났다.','원인이 미확인인 상태로 회의 종료','회의 종료 전에 원인을 확인함'),
       ('장비를 켠 채로 설정을 점검했다.','장비가 켜진 상태를 유지하며 점검','장비를 끈 뒤에만 점검')),
      ('G5:-고는',loc('앞 행동 뒤의 반응을 부각해요. 여기서는 한 번 보고 느낀 반응이며 반복 습관의 -고는 하다와 구별해요.','Highlight a reaction after an action. Here it is a single response, distinct from habitual -고는 하다.','Hebe eine Reaktion nach einer Handlung hervor. Hier ist sie einmalig, anders als gewohnheitsmäßiges -고는 하다.'),
       ('연구원은 표를 읽고는 잠시 말을 멈췄다.','표를 읽은 뒤 나타난 반응','언제나 표를 읽지 않는 습관'),
       ('담당자는 기록을 확인하고는 설명을 고쳤다.','기록 확인 뒤 설명 수정','기록을 확인하기 전 설명 수정 완료')),
      ('G5:-기가 바쁘게',loc('앞 사건 직후 매우 빠르게 뒤 사건이 이어져요. 바쁜 사람의 일정 자체를 설명하는 표현은 아니에요.','Emphasise that the next event follows immediately, rather than describing a person’s busy schedule.','Betone die unmittelbare Folge eines Ereignisses, statt den vollen Terminkalender einer Person zu beschreiben.'),
       ('발표가 끝나기가 바쁘게 질문이 이어졌다.','발표 직후 곧바로 질문 시작','질문 때문에 발표가 시작되지 않음'),
       ('자료가 도착하기가 바쁘게 연구팀이 검토를 시작했다.','자료 도착 직후 검토 시작','자료 도착 이전에 검토 완료')),
      ('G5:-었던',loc('완료된 과거 경험을 돌아보며 명사를 수식해요. 과거의 상태를 현재에도 유지한다고 보증하지 않아요.','Modify a noun by recalling a completed past experience without guaranteeing it still holds now.','Bestimme ein Nomen durch eine abgeschlossene frühere Erfahrung, ohne ihren Fortbestand zu garantieren.'),
       ('작년에 폐쇄됐던 공간을 이번 달에 다시 열었다.','과거 폐쇄된 공간이 이번 달 재개방','공간이 계속 폐쇄돼 지금도 열리지 않음'),
       ('한때 주목받았던 제안을 다시 검토했다.','과거 관심을 받았던 제안을 재검토','현재 제안이 이미 승인돼 시행 중')),
      ('G5:에 관하여',loc('전문적인 설명이나 논의의 대상을 명시해요. 이용 조건을 설명하는 것과 이용을 허가하는 것은 달라요.','Specify the subject of specialist explanation or discussion. Explaining use conditions does not grant permission.','Benenne den Gegenstand fachlicher Erläuterung oder Diskussion. Nutzungsbedingungen zu erklären erteilt keine Erlaubnis.'),
       ('자료의 이용 조건에 관하여 설명하겠습니다.','설명 대상은 자료 이용 조건','모든 자료의 무제한 이용을 승인'),
       ('기록의 보존 기간에 관하여 질문을 받았다.','질문의 대상은 기록 보존 기간','기록 삭제가 이미 완료됨')),
      ('G5:-어 내다',loc('어려움이나 노력을 거쳐 결과를 달성했음을 부각해요. 찾아낸 것이 일부 오류라면 모든 문제가 해결됐다고 확대하지 않아요.','Highlight an outcome achieved through difficulty or effort. Finding some errors does not solve every problem.','Hebe ein durch Mühe oder Schwierigkeiten erreichtes Ergebnis hervor. Einige Fehler zu finden löst nicht alle Probleme.'),
       ('연구팀은 여러 번 대조한 끝에 중복 기록을 찾아냈다.','노력 끝에 중복 기록 발견','중복 기록을 앞으로 찾겠다는 계획만 있음'),
       ('동료들은 긴 논의 끝에 공동 초안을 만들어 냈다.','논의를 거쳐 공동 초안 완성','초안을 이미 최종 규정으로 승인')),
      ('G2:-어 있다',loc('행동 뒤에 남은 결과 상태를 말해요. 문이 닫혀 있었다는 상태와 누군가 문을 닫고 있었다는 진행 동작을 구별해요.','Describe a resulting state. A door being closed differs from someone being in the process of closing it.','Beschreibe einen Ergebniszustand. Eine geschlossene Tür unterscheidet sich vom laufenden Schließen durch eine Person.'),
       ('실험이 끝난 뒤에도 문이 닫혀 있었다.','실험 뒤 지속된 닫힌 상태','실험 뒤 누군가 문을 닫는 중이라는 관찰'),
       ('점검이 끝난 뒤에도 화면이 켜져 있었다.','점검 뒤 지속된 켜진 상태','점검 뒤 화면을 켜는 동작이 진행 중')),
    ]
    tasks=[grammar_task('KP19',i,*r) for i,r in enumerate(rows,1)]
    prod=[
      ('G5:-다4',('보고서 문어체 / 이 연구는 두 지역의 기록을 비교하다 / -다 평서문','이 연구는 두 지역의 기록을 비교한다.','두 지역을 비교해라.'),('보고서 문어체 / 이번 분석은 중복 응답을 제외하다 / -다 평서문','이번 분석은 중복 응답을 제외한다.','중복 응답을 제외합니까?')),
      ('G5:-기에 앞서(서)',('순서: 조건 확인 → 자료 공개 / 자료를 공개하다 + -기에 앞서 / 이용 조건을 확인하다 / 과거 문어체','자료를 공개하기에 앞서 이용 조건을 확인했다.','자료를 공개한 뒤에 이용 조건을 확인했다.'),('순서: 누락 검토 → 결론 / 결론을 내리다 + -기에 앞서 / 빠진 기록을 검토하다 / 현재 문어체','결론을 내리기에 앞서 빠진 기록을 검토한다.','결론을 내린 뒤 누락 검토를 생략한다.')),
      ('G5:-는 가운데',('진행 중 배경 / 논의가 계속되다 → 새 자료가 공개되다 / -는 가운데, 과거 문어체','논의가 계속되는 가운데 새 자료가 공개됐다.','논의가 끝난 뒤에야 자료가 공개됐다.'),('진행 중 배경 / 점검이 진행되다 → 일부 장비가 교체되다 / -는 가운데, 과거 문어체','점검이 진행되는 가운데 일부 장비가 교체됐다.','모든 점검과 장비 교체가 완료됐다.')),
      ('G5:-는 동시에',('동시 기능 / 이 장치는 기록을 남기다 + 접근을 제한하다 / -는 동시에, 현재 문어체','이 장치는 기록을 남기는 동시에 접근을 제한한다.','기록을 중단해야만 접근을 제한한다.'),('동시 작업 / 연구팀은 오류를 찾다 + 분류 기준을 기록하다 / -는 동시에, 과거 문어체','연구팀은 오류를 찾는 동시에 분류 기준을 기록했다.','오류를 모두 찾은 뒤에만 기준 기록을 시작했다.')),
      ('G5:-은 채로',('유지 상태 / 원인을 확인하지 못하다 → 회의가 끝나다 / -은 채, 과거 문어체','원인을 확인하지 못한 채 회의가 끝났다.','원인을 확인한 뒤 회의가 끝났다.'),('유지 상태 / 장비를 켜다 → 설정을 점검하다 / -은 채로, 과거 문어체','장비를 켠 채로 설정을 점검했다.','장비를 끈 뒤 설정을 점검했다.')),
      ('G5:-고는',('행동 뒤 반응 / 연구원은 표를 읽다 → 잠시 말을 멈추다 / -고는, 과거 문어체','연구원은 표를 읽고는 잠시 말을 멈췄다.','연구원은 표를 읽기 전부터 계속 말하지 않았다.'),('행동 뒤 반응 / 담당자는 기록을 확인하다 → 설명을 고치다 / -고는, 과거 문어체','담당자는 기록을 확인하고는 설명을 고쳤다.','담당자는 기록 확인 전에 설명 수정을 마쳤다.')),
      ('G5:-기가 바쁘게',('직후 / 발표가 끝나다 → 질문이 이어지다 / -기가 바쁘게, 과거 문어체','발표가 끝나기가 바쁘게 질문이 이어졌다.','질문이 끝난 뒤 발표를 시작했다.'),('직후 / 자료가 도착하다 → 연구팀이 검토를 시작하다 / -기가 바쁘게, 과거 문어체','자료가 도착하기가 바쁘게 연구팀이 검토를 시작했다.','자료 도착 전에 검토를 마쳤다.')),
      ('G5:-었던',('과거 수식 / 작년에 폐쇄되다 + 공간 / 이번 달에 다시 열다 / -었던, 과거 문어체','작년에 폐쇄됐던 공간을 이번 달에 다시 열었다.','그 공간은 지금도 계속 폐쇄돼 있다.'),('과거 수식 / 한때 주목받다 + 제안 / 다시 검토하다 / -었던, 과거 문어체','한때 주목받았던 제안을 다시 검토했다.','그 제안을 이미 최종 승인했다.')),
      ('G5:에 관하여',('설명 범위 / 자료의 이용 조건 / 설명하다 / 에 관하여, -겠습니다','자료의 이용 조건에 관하여 설명하겠습니다.','자료의 무제한 이용을 승인하겠습니다.'),('질문 범위 / 기록의 보존 기간 / 질문을 받다 / 에 관하여, 과거 문어체','기록의 보존 기간에 관하여 질문을 받았다.','기록 삭제를 마쳤다.')),
      ('G5:-어 내다',('노력 끝 성과 / 연구팀은 여러 번 대조한 끝에 중복 기록을 찾다 / -어 내다, 과거 문어체','연구팀은 여러 번 대조한 끝에 중복 기록을 찾아냈다.','연구팀은 중복 기록을 찾을 계획이다.'),('노력 끝 성과 / 동료들은 긴 논의 끝에 공동 초안을 만들다 / -어 내다, 과거 문어체','동료들은 긴 논의 끝에 공동 초안을 만들어 냈다.','동료들은 초안을 최종 규정으로 승인했다.')),
      ('G2:-어 있다',('지속 결과 / 실험이 끝난 뒤에도 / 문이 닫히다 / -어 있다, 과거 문어체','실험이 끝난 뒤에도 문이 닫혀 있었다.','실험이 끝난 뒤에 문을 닫고 있었다.'),('지속 결과 / 점검이 끝난 뒤에도 / 화면이 켜지다 / -어 있다, 과거 문어체','점검이 끝난 뒤에도 화면이 켜져 있었다.','점검이 끝난 뒤 화면을 켜고 있었다.')),
    ]
    tasks+=production('KP19',tasks,prod)
    h=loc('먼저 자료가 정의한 용어와 포함·제외 범위를 확인하세요. 주장·부연·전후·동시·유지 상태를 나누고 누가 무엇을 했는지 표시해요. 같은 시각에 일어난 일이 원인이라는 추론은 별도 근거가 필요해요. 명사화로 주체가 생략되면 미상으로 남기고 보고서의 -다를 독자에게 반말하는 기능과 혼동하지 마세요.',
      'First check the source’s terms and inclusion rules. Separate claim, elaboration, sequence, simultaneity and maintained state; identify who did what. A causal inference from events at the same time needs separate evidence. If nominalisation omits the actor, leave them unknown. Report-style -다 is not casual speech directed at the reader.',
      'Prüfe zuerst Begriffe und Ein- und Ausschlussregeln der Quelle. Trenne These, Erläuterung, Abfolge, Gleichzeitigkeit und fortbestehenden Zustand und benenne die Handelnden. Gleichzeitigkeit belegt keine Ursache. Fehlt durch Nominalisierung das Subjekt, bleibt es unbekannt. Das -다 eines Berichts ist keine vertrauliche Anrede der Lesenden.')
    def academic(site,initial,duplicates,window):
        return f'''학습용 창작 학술 설명
제목: {site}의 기록 정리 절차와 분석 범위
이 설명에서 원기록은 센서가 남긴 항목 하나를 말한다. 분석 기록은 항목 식별자를 대조해 중복을 제외한 집합이다. 분석 기록이라는 명칭은 측정값이 참이라는 보증이 아니다. 같은 항목 식별자가 반복된 경우만 중복으로 분류하며, 값이 같아도 식별자가 다르면 임의로 지우지 않는다.
연구팀은 자료를 분석하기에 앞서 이 검토 기준을 문서화했다. 식별자를 대조하는 동시에 각 제외 사유를 기록했다. 누락 원인에 관한 논의가 계속되는 가운데 추가 기록이 도착했다. 담당자는 추가 기록을 읽고는 분석 범위를 첫 수집분으로 한정했다. 추가 자료의 타당성 검토가 끝나지 않았기 때문이다.
첫 수집분 {initial}개에서 중복 {duplicates}개를 제외한 {initial-duplicates}개가 분석 대상이다. 수집 기간은 {window}이며 다른 기간의 대표성을 주장하지 않는다. 연구팀은 반복 대조 끝에 중복을 찾아냈지만 측정 오차의 원인은 확인하지 못했다. 검토가 끝난 뒤에도 원자료 보관함은 잠겨 있었다. 잠긴 상태의 관찰만으로 누가 잠갔는지는 알 수 없다.
따라서 이 절차는 기록 선택의 재현 가능성을 설명한다. 측정값의 정확성이나 장치의 우수성을 입증하지 않는다. 원인을 확인하지 못한 채 절차 검토를 마쳤으며, 추가 검증은 별도 계획이다. 이처럼 과정의 완료, 결과 상태, 연구 성과의 범위를 나누어 기술해야 논거의 설명력을 과장하지 않는다.'''
    def report(site,initial,duplicates,window):
        return f'''학습용 창작 업무 보고서 — {site}
목적: {window}의 첫 수집 기록 {initial}개에 적용한 정리 절차를 설명한다.
업무 분장: 연구팀이 식별자 중복 {duplicates}개를 확인했다. 자료 담당자가 제외 사유를 기록했다. 외부 공개 여부의 최종 결정 주체는 이 자료에 명시되지 않았다.
시행 절차: 기준 문서화 후 대조를 시작했다. 대조와 제외 사유 기록은 동시에 진행됐다. 회의 중 추가 자료가 도착했지만 분석에는 넣지 않았다. 원인을 확인하지 못한 채 회의를 마쳤다.
결과: 분석 대상은 {initial-duplicates}개다. 보관함은 회의 후에도 잠겨 있었다. 이 상태를 유지한 사람이나 잠근 시각은 기록되지 않았다.
제안: 추가 자료를 검토한 뒤 범위 확대 여부를 논의한다. 공개 승인이나 장치 교체를 지시한 보고가 아니다.

같은 절차를 줄인 요약 A
중복 확인 및 제외 사유 기록의 수행이 완료되었다. 공개 보류가 결정되었다.

요약 B — 확인 가능한 주체만 복원한 문장
연구팀이 중복을 확인했고 자료 담당자가 제외 사유를 기록했다. 공개 보류가 결정되었으나 결정 주체와 근거는 이 요약에 제시되지 않았다.

비교 메모: A는 명사화와 피동으로 행위 주체를 가린다. B의 첫 문장은 업무 분장에서 확인한 주체를 복원한다. 둘째 문장의 미상 결정자를 연구팀이라고 채워 넣어서는 안 된다. 공개 보류 결정이라는 A의 새 주장도 본 보고서의 제안만으로 입증되지 않으므로 원문 확인이 필요하다.'''
    def lecture(site,initial,duplicates,window):
        text=f'''가상 전문 발표입니다. 발표자와 자료 담당자는 동등한 동료입니다.
발표자: 오늘의 핵심 주장은 {site}의 정리 절차를 따라 분석 범위를 재현할 수 있다는 것입니다. 측정값의 정확성을 검증했다는 뜻은 아닙니다. 먼저 용어를 정의하겠습니다. 원기록은 센서 항목 하나이며 분석 기록은 식별자 중복을 제외한 집합입니다. 숫자가 같은 측정값을 모두 지웠다는 뜻이 아닙니다.
다음은 시간 순서입니다. {window}에 모은 첫 기록 {initial}개를 대조하기에 앞서 기준을 문서화했습니다. 연구팀이 중복 {duplicates}개를 찾는 동시에 자료 담당자는 제외 사유를 기록했습니다. 추가 자료는 논의가 계속되는 가운데 도착했으나 검토 전이므로 이번 범위에서 뺐습니다.
여기서 상태와 성과를 나누겠습니다. 연구팀은 반복 대조 끝에 중복을 찾아냈지만 오차 원인은 확인하지 못했습니다. 보관함은 회의 후에도 잠겨 있었습니다. 누가 언제 잠갔는지는 모릅니다. 검토 완료와 원인 규명, 보관함 상태는 별개입니다.
자료 담당자: 추가 자료가 도착하기가 바쁘게 범위를 넓힌 것은 아니군요.
발표자: 맞습니다. 이제 공개에 관하여 말씀드리겠습니다. 분석 대상 {initial-duplicates}개라는 사실과 외부 공개 승인을 구별해야 합니다. 요약에는 공개 보류가 결정되었다고 쓰여 있지만 결정 주체와 근거가 없으므로 담당자를 추정하지 않겠습니다. 보류 결정 자체도 원문 확인이 필요합니다.
자료 담당자: 장치 교체도 검토하는 건가요?
발표자: 그 질문은 지금 자료로 답할 수 없습니다. 제가 분석 범위를 설명한 뒤 공개로 주제를 바꿨다는 것만으로 두 사안의 인과관계가 성립하지는 않습니다. 핵심을 짚으면 첫 수집분의 정리 절차만 설명했으며 확대 분석과 공개 여부는 추가 확인 사항입니다.'''
        return packet(text,[
          choice('claim',loc('핵심 주장과 부연을 구별하면?', 'Which is the central claim rather than an unsupported extension?', 'Was ist die Hauptaussage statt einer unbelegten Erweiterung?'),['정리 절차로 분석 범위 재현 가능','측정값 정확성과 장치 우수성 입증'],h),
          choice('before',loc('대조 전에 완료한 것은?', 'What was done before comparison?', 'Was wurde vor dem Abgleich erledigt?'),['검토 기준 문서화','외부 공개 승인'],h),
          choice('simultaneous',loc('동시에 진행한 두 작업은?', 'Which two tasks ran concurrently?', 'Welche zwei Arbeiten liefen gleichzeitig?'),['연구팀의 중복 탐색과 자료 담당자의 사유 기록','회의 종료와 원인 규명 완료'],h),
          choice('additional',loc('회의 중 도착한 자료의 처리는?', 'What happened to the material arriving during discussion?', 'Was geschah mit dem während der Diskussion eingetroffenen Material?'),['검토 전이라 이번 분석에서 제외','도착 즉시 전체 분석 범위에 포함'],h),
          choice('state',loc('보관함에 관해 확인한 것은?', 'What was established about the cabinet?', 'Was wurde über den Schrank festgestellt?'),['회의 뒤 잠긴 상태, 행위자와 시각 미상','연구팀이 회의 뒤 직접 잠갔다는 관찰'],h),
          choice('transition',loc('분석에서 공개로 전환한 발화가 증명하지 않는 것은?', 'What does the shift from analysis to disclosure not establish?', 'Was belegt der Wechsel von Analyse zu Freigabe nicht?'),['분석 결과가 공개 보류 결정의 원인이라는 관계','발표자가 공개 문제를 별도로 다루기 시작함'],h),
          choice('actor',loc('요약의 공개 보류 문장은?', 'How should the disclosure-hold statement in the abstract be treated?', 'Wie ist die Aussage zum Freigabeaufschub in der Zusammenfassung zu behandeln?'),['주체·근거·결정 사실을 원문으로 추가 확인','자료 담당자가 결정했다고 확정'],h),
        ],'audio')
    p=('가람관측실',24,3,'첫째 주')
    a=('솔빛기록실',35,5,'둘째 주')
    tasks.append(task('KP19','listening:01','listening',loc('전문 발표의 순서와 논점 복원','Reconstruct sequence and topic shifts in a specialist talk','Abfolge und Themenwechsel im Fachvortrag rekonstruieren'),h,lecture(*p),lecture(*a)))
    def read_academic(args):
        return packet(academic(*args),[
          choice('definition',loc('분석 기록의 정의는?', 'What defines an analysis record here?', 'Was kennzeichnet hier einen Analysedatensatz?'),['항목 식별자 중복을 제외한 집합','값이 같은 모든 측정을 지운 참값 집합'],h),
          choice('time',loc('시간 관계를 올바르게 복원하면?', 'Which temporal reconstruction is correct?', 'Welche zeitliche Rekonstruktion stimmt?'),['기준 문서화 뒤 대조·사유 기록 동시 진행','대조 완료 뒤에만 사유 기록 시작'],h),
          choice('outcome',loc('확인한 성과의 한계는?', 'What is the limit of the achieved result?', 'Wo liegt die Grenze des erreichten Ergebnisses?'),['중복은 발견했지만 오차 원인은 미확인','중복을 찾아 모든 오차 원인도 규명'],h),
          choice('style',loc('이 절차는 … 설명한다의 -다는?', 'What does -다 do in 이 절차는 … 설명한다?', 'Welche Funktion hat -다 in 이 절차는 … 설명한다?'),['학술 문어의 서술 종결','독자에게 반말로 설명을 명령'],h),
          choice('limit',loc('자료가 지지하는 결론은?', 'Which conclusion is supported?', 'Welche Folgerung ist gestützt?'),['첫 수집분 선택 절차의 재현 가능성','다른 기간에도 장치가 더 우수함'],h),
        ])
    tasks.append(task('KP19','reading:01','reading',loc('학술 설명의 정의와 결과 상태','Definitions and resulting states in academic prose','Definitionen und Ergebniszustände im Fachtext'),h,read_academic(p),read_academic(a)))
    def read_report(args):
        return packet(report(*args),[
          choice('count',loc('이번 분석 대상 수는?', 'How many records belong to this analysis?', 'Wie viele Datensätze gehören zu dieser Analyse?'),[str(args[1]-args[2])+'개',str(args[1])+'개'],h),
          choice('agency',loc('두 요약에서 복원할 수 있는 행위자는?', 'Which actors can be recovered in the summaries?', 'Welche Handelnden lassen sich in den Zusammenfassungen rekonstruieren?'),['중복 확인은 연구팀, 제외 사유 기록은 자료 담당자','공개 보류 결정도 자료 담당자'],h),
          choice('nominal',loc('수행이 완료되었다의 정보 손실은?', 'What information is lost in 수행이 완료되었다?', 'Welche Information geht in 수행이 완료되었다 verloren?'),['누가 어떤 작업을 했는지 명사화가 가림','작업이 미완료라고 명확히 표현함'],h),
          choice('unsupported',loc('요약에서 새로 생긴 미확인 주장은?', 'Which unverified claim was added in the summary?', 'Welche ungeprüfte Behauptung ergänzt die Zusammenfassung?'),['공개 보류가 결정됐다는 주장','연구팀이 중복을 확인했다는 기록'],h),
          choice('proposal',loc('보고서의 제안과 조건은?', 'What does the report propose, with what condition?', 'Was schlägt der Bericht unter welcher Bedingung vor?'),['추가 자료 검토 후 범위 확대 논의','검토 없이 공개와 장치 교체를 즉시 지시'],h),
        ])
    tasks.append(task('KP19','reading:02','reading',loc('명사화 뒤의 책임 주체 확인','Recover agency behind nominalisation','Handelnde hinter Nominalisierungen erkennen'),h,read_report(p),read_report(a)))
    rubric=loc('제공된 학술 설명과 보고서를 바탕으로 첫 글은 목적·정의·방법·결과·한계·후속 확인의 소제목을 가진 보고서로, 둘째 글은 짧은 전문 요약문으로 쓰세요. 수집분·중복 수·분석 수를 보존하고 전후·동시·유지 상태를 구별하세요. 연구팀과 자료 담당자의 역할을 명시하며 공개 결정자를 추정하지 마세요. 요약 A의 공개 보류 주장은 원문 검증이 필요하다고 표시하세요. -다 서술체로 성과와 제안을 나누고 문어체가 사실성을 보증하지 않음을 점검하세요. 원문 대조 후 고쳐 쓰며 전체 의미는 미채점입니다.',
      'Using the academic explanation and report, first write a report with headings for purpose, definition, method, result, limits and follow-up. Then write a short specialist abstract. Preserve initial, duplicate and analysis counts and distinguish sequence, simultaneity and maintained state. Name the research and data staff’s roles without guessing the disclosure decision-maker. Mark summary A’s hold decision as requiring source verification. Use report-style -다 and separate achievement from proposal; the style itself does not verify truth. Compare and revise; full meaning remains unscored.',
      'Verfasse anhand von Fachtext und Bericht zuerst einen Bericht mit Überschriften für Zweck, Definition, Methode, Ergebnis, Grenzen und weitere Prüfung, danach eine kurze Fachzusammenfassung. Erhalte Ausgangs-, Dubletten- und Analysezahlen und trenne Abfolge, Gleichzeitigkeit und fortbestehenden Zustand. Benenne die Rollen von Forschungsteam und Datenverantwortlichen, ohne die Freigabeentscheidung zuzuordnen. Markiere den Aufschub in Zusammenfassung A als prüfbedürftig. Nutze -다 und trenne Ergebnis und Vorschlag; der Stil beweist keine Wahrheit. Gleiche ab und überarbeite; Gesamtinhalt bleibt unbewertet.')
    def writing(args):
        return packet(academic(*args)+'\n\n'+report(*args),[
          free_text('report',loc('소제목으로 과정을 조직한 보고서를 쓰세요.','Write a report organising the process under headings.','Ordne den Ablauf in einem Bericht mit Überschriften.'),rubric),
          free_text('abstract',loc('핵심 주장·방법·한계를 전문 요약문으로 쓰세요.','Write a specialist abstract of the claim, method and limits.','Fasse These, Methode und Grenzen fachlich zusammen.'),rubric),
        ],'form')
    tasks.append(task('KP19','writing:01','writing',loc('과정 보고서와 전문 요약문','A process report and specialist abstract','Prozessbericht und Fachzusammenfassung'),rubric,writing(p),writing(a)))
    rewrite=loc('보고서의 시행 절차와 결과를 동료 안내문으로 바꾸세요. 독자가 먼저 해야 할 확인을 앞에 두되 대상·순서·동시 작업·결과를 보존하세요. 명사화로 가려진 확인 가능한 주체만 복원하고 미상 주체는 미상으로 남기세요. 해요체로 설명한 뒤 정보 배열을 바꾼 이유를 별도 문단에 적으세요. 다시 원문과 대조해 권고를 명령이나 승인으로 바꾸지 않았는지 고쳐 쓰세요. 전체 의미는 미채점입니다.',
      'Recast the procedure and results as a note to colleagues. Put the reader’s first checking step early while preserving scope, sequence, concurrent work and results. Recover only evidenced actors hidden by nominalisation; leave unknown actors unknown. Explain politely and add a paragraph justifying the information order. Compare with the source and revise any recommendation turned into a command or approval. Full meaning remains unscored.',
      'Formuliere Verfahren und Ergebnisse als Hinweis für Kolleginnen und Kollegen um. Stelle deren ersten Prüfschritt voran und erhalte Umfang, Reihenfolge, gleichzeitige Arbeit und Ergebnisse. Rekonstruiere nur belegte Handelnde hinter Nominalisierungen; Unbekannte bleiben unbekannt. Erkläre höflich und begründe die Informationsreihenfolge in einem eigenen Absatz. Prüfe, ob eine Empfehlung zur Anweisung oder Genehmigung geworden ist, und überarbeite. Gesamtinhalt bleibt unbewertet.')
    def note(args):
        return packet(report(*args),[free_text('note',loc('동료 안내문과 정보 배열의 이유를 쓰세요.','Write the colleague note and explain its order.','Schreibe den Hinweis und begründe seine Reihenfolge.'),rewrite)],'form')
    tasks.append(task('KP19','writing:02','writing',loc('보고서를 동료 안내문으로 바꾸기','Recast a report for colleagues','Einen Bericht für Kolleginnen und Kollegen umformulieren'),rewrite,note(p),note(a)))
    speech=loc('먼저 동등한 동료에게 해요체로 원기록·중복·분석 기록을 풀어 설명하세요. 동료가 “값이 같은 기록을 모두 없앤 건가요?”라고 물으면 식별자라는 기준을 보존해 답하세요. 공개 브리핑에서는 합쇼체로 주장·부연·시간 관계·성과와 한계를 재구성하세요. 요약의 공개 보류를 확인 사실로 바꾸지 마세요. 이어 모어가 다른 동료에게 두 지점, 곧 명사화로 사라진 주체와 동시성의 인과 오해를 한국어로 짚으세요. “핵심을 짚으면” 같은 전환 뒤에도 미상 값을 남겨요. 녹음을 듣고 긴 명사구를 의미 단위로 나누어 휴지·말끝을 고쳐 다시 말하세요. 의미·억양은 미채점입니다.',
      'First explain original records, duplicates and analysis records politely to an equal colleague. If asked whether every identical value was removed, preserve the identifier criterion. Recast the claim, elaboration, temporal relations, results and limits as a formal public briefing. Do not turn the summary’s hold claim into a verified fact. Explain in Korean two transfer risks to a colleague with another first language: agency hidden by nominalisation and mistaking simultaneity for cause. Keep unknowns even after a transition such as 핵심을 짚으면. Replay, divide long noun phrases into meaning units and revise pauses and endings. Meaning and intonation remain unscored.',
      'Erkläre einer gleichgestellten Person zunächst höflich Rohdatensätze, Dubletten und Analysedatensätze. Bewahre bei der Frage, ob alle gleichen Werte entfernt wurden, das Kriterium der Kennung. Ordne These, Erläuterung, Zeitbeziehungen, Ergebnisse und Grenzen für ein förmliches öffentliches Briefing. Mache den behaupteten Aufschub nicht zum bestätigten Fakt. Erkläre einer Person anderer Erstsprache auf Koreanisch zwei Übertragungsrisiken: durch Nominalisierung verdeckte Handelnde und die Verwechslung von Gleichzeitigkeit mit Ursache. Erhalte Unbekanntes auch nach einem Übergang wie 핵심을 짚으면. Höre zu, gliedere lange Nominalgruppen in Sinneinheiten und verbessere Pausen und Endungen. Inhalt und Intonation bleiben unbewertet.')
    tasks.append(task('KP19','speaking:01','speaking',loc('전문 용어를 풀고 공개 브리핑으로 전환','Explain terms, then give a public briefing','Fachbegriffe erklären und öffentlich berichten'),speech,
      packet(academic(*p)+'\n\n'+report(*p),[]),packet(academic(*a)+'\n\n'+report(*a),[])))
    return tasks


if __name__=='__main__':
    write_source('KP19',kp19())
