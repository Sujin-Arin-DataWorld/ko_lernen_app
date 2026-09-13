"""KP25 institutional scope and source-bound definitions; unsigned source."""
from phase_task_authoring import choice, free_text, grammar_task, loc, packet, task, write_source
from author_phase_a1_production import production


def kp25():
    rows=[
      ('G6:-는다는',loc('인용된 명제가 뒤의 주장·설명을 꾸며요. 주장이 있다는 사실과 그 명제의 참을 구별합니다.','A quoted proposition modifies a claim or explanation. Distinguish the existence of a claim from its truth.','Eine zitierte Aussage bestimmt eine Behauptung oder Erklärung näher. Trenne das Vorliegen der Behauptung von ihrer Wahrheit.'),('오차가 모두 사라진다는 주장은 아직 검증되지 않았다.','오차 소멸은 미검증 주장','모든 오차 소멸이 검증됨'),('비용이 절반으로 줄어든다는 설명에는 계산 근거가 없다.','비용 감소 설명에 계산 근거 없음','비용 절반 감소가 확정 사실')),
      ('G6:-이라야',loc('뒤의 자격에 필요한 조건을 한정해요. 필요조건을 충족했다고 다른 조건까지 충족한 것은 아닙니다.','Restrict a necessary eligibility condition. Meeting it does not establish every other condition.','Grenze eine notwendige Voraussetzung ein. Ihre Erfüllung belegt nicht automatisch alle weiteren Voraussetzungen.'),('등록 연구원이라야 신청할 수 있다. 신청 후 별도 심사를 받는다.','등록은 신청 필요조건, 승인 보장 아님','등록만 하면 승인 확정'),('지정 검토자라야 원본을 열람할 수 있다. 보안 교육도 마쳐야 한다.','지정 외에 교육 이수도 필요','지정만으로 교육 면제')),
      ('G6:-되',loc('앞 조치를 인정하면서 적용 단서를 붙입니다. 단서를 지우거나 앞 조치를 전면 금지로 뒤집지 않아요.','Accept the main action while attaching a proviso. Neither omit it nor reverse the action into a complete ban.','Lass die Haupthandlung gelten und füge einen Vorbehalt an. Streiche ihn nicht und kehre die Handlung nicht in ein Totalverbot um.'),('요약은 공개하되 식별 정보는 제외한다.','요약 공개와 식별 정보 제외를 함께 적용','식별 정보까지 모두 공개'),('사본은 제공하되 원본은 반출하지 않는다.','사본 제공, 원본 반출 불가','사본 제공도 전면 금지')),
      ('G6:를 막론하고',loc('명시한 범주의 차이를 적용에서 제외합니다. 다른 자격 요건까지 모두 없애는 표현은 아니에요.','Disregard differences in the named category, not every other eligibility condition.','Lass Unterschiede der genannten Kategorie außer Betracht, nicht sämtliche weiteren Voraussetzungen.'),('전공을 막론하고 등록 연구원은 신청할 수 있다.','전공 무관, 등록 요건 유지','등록 여부까지 무관'),('소속을 막론하고 교육 이수자는 설명회에 참석할 수 있다.','소속 무관, 교육 요건 유지','교육 미이수자도 반드시 참석 가능')),
      ('G6:는 마당에',loc('이미 성립한 상황을 뒤 판단의 전제로 제시해요. 단순한 미래 가정이나 보편 규칙과 구별합니다.','Present an established situation as the premise of a judgement, distinct from a future supposition or universal rule.','Nenne eine bereits bestehende Lage als Prämisse einer Bewertung, im Unterschied zu Zukunftsannahme oder allgemeiner Regel.'),('정의부터 서로 다른 마당에 결과를 한데 묶을 수는 없다.','이미 다른 정의가 통합 유보의 전제','정의 차이가 전혀 없다는 전제'),('근거가 빠진 마당에 결론을 확정하기는 어렵다.','현재 근거 누락을 판단 전제로 삼음','앞으로 근거가 빠지면 무조건 폐기')),
      ('G6:-느니만큼',loc('명시한 사정에 상응하는 판단을 제시합니다. 말끝 자체가 제도적 권한을 부여하지는 않아요.','Relate a judgement to the stated circumstances. The ending itself grants no institutional authority.','Beziehe eine Bewertung auf die genannten Umstände. Das Satzende verleiht keine institutionelle Befugnis.'),('여러 기관이 함께 쓰느니만큼 용어의 경계를 명시해야 한다.','공동 사용에 상응하는 명확화 요구','화자가 모든 기관의 규정을 변경함'),('영향이 큰 사안이니만큼 적용 범위를 확인해야 한다.','영향에 상응하는 범위 확인 요구','영향이 크므로 모든 예외 삭제')),
      ('G6:-건대',loc('문어적 틀로 바람이나 판단을 밝힙니다. 화자의 바람을 확정 결정이나 타인의 의무로 바꾸지 않아요.','Frame a wish or judgement in a literary written form. Do not turn a wish into a decision or another person’s duty.','Rahme einen Wunsch oder ein Urteil in gehobener Schriftsprache. Mache einen Wunsch nicht zum Beschluss oder zur Pflicht anderer.'),('내가 바라건대 검토가 여기서 멈추지 않았으면 한다.','화자가 검토 지속을 희망','위원회가 지속을 의결함'),('내가 보건대 이 요약에는 단서가 빠져 있다.','화자가 단서 누락을 판단','법원이 요약 무효를 선고함')),
      ('G2:-기',loc('명사화한 행동을 풀어 쓰면서 누가 행동하는지 보존해요. 원문에서 행위자를 밝히지 않으면 새로 지정하지 않습니다.','Unpack nominalised actions while preserving who acts. If the source leaves an actor unknown, do not assign one.','Löse nominalisierte Handlungen auf und erhalte die handelnde Person. Fehlt sie im Ausgangstext, erfinde keine Zuständigkeit.'),('기록팀은 제출 날짜 확인하기를 맡았다. 승인 주체는 적혀 있지 않다.','날짜 확인은 기록팀, 승인 주체 미상','기록팀이 승인도 담당'),('연구팀은 결과 재현하기를 목표로 삼았다. 배포 결정자는 명시되지 않았다.','재현 목표는 연구팀, 배포 결정자 미상','연구팀이 배포 권한도 보유')),
    ]
    tasks=[grammar_task('KP25',i,*r) for i,r in enumerate(rows,1)]
    prod=[
      ('G6:-는다는',('미검증 주장 / 오차 모두 사라지다 / -는다는 주장은 아직 검증되지 않았다','오차가 모두 사라진다는 주장은 아직 검증되지 않았다.','오차가 모두 사라졌음이 검증되었다.'),('계산 근거 없는 설명 / 비용 절반 줄어들다 / -는다는 설명에는 계산 근거가 없다','비용이 절반으로 줄어든다는 설명에는 계산 근거가 없다.','비용이 절반으로 줄었음이 입증되었다.')),
      ('G6:-이라야',('등록 연구원 / 신청 가능의 필요조건만 / -이라야','등록 연구원이라야 신청할 수 있다.','등록 연구원이면 반드시 승인된다.'),('지정 검토자 / 원본 열람의 필요조건만 / -라야','지정 검토자라야 원본을 열람할 수 있다.','지정 검토자는 교육을 받지 않아도 된다.')),
      ('G6:-되',('요약 공개 / 식별 정보 제외 / -하되, 문어','요약은 공개하되 식별 정보는 제외한다.','요약과 식별 정보를 모두 공개한다.'),('사본 제공 / 원본 반출 불가 / -하되, 문어','사본은 제공하되 원본은 반출하지 않는다.','사본과 원본을 모두 반출한다.')),
      ('G6:를 막론하고',('전공 무관 / 등록 연구원 신청 가능 / 막론하고','전공을 막론하고 등록 연구원은 신청할 수 있다.','등록 여부를 막론하고 누구나 신청할 수 있다.'),('소속 무관 / 교육 이수자 설명회 참석 가능 / 막론하고','소속을 막론하고 교육 이수자는 설명회에 참석할 수 있다.','교육 여부를 막론하고 누구나 참석할 수 있다.')),
      ('G6:는 마당에',('이미 정의가 서로 다름 / 결과 통합 불가 / 마당에','정의부터 서로 다른 마당에 결과를 한데 묶을 수는 없다.','정의가 모두 같으므로 결과를 통합한다.'),('현재 근거 누락 / 결론 확정 어려움 / 마당에','근거가 빠진 마당에 결론을 확정하기는 어렵다.','근거가 충분하므로 결론을 확정한다.')),
      ('G6:-느니만큼',('여러 기관 공동 사용 / 용어 경계 명시 필요 / 쓰느니만큼','여러 기관이 함께 쓰느니만큼 용어의 경계를 명시해야 한다.','여러 기관이 쓰므로 모든 기준을 없애야 한다.'),('영향 큰 사안 / 적용 범위 확인 필요 / 사안이니만큼','영향이 큰 사안이니만큼 적용 범위를 확인해야 한다.','영향이 큰 사안이므로 모든 예외를 삭제한다.')),
      ('G6:-건대',('나의 검토 지속 희망 / 내가 바라건대 / -았으면 한다','내가 바라건대 검토가 여기서 멈추지 않았으면 한다.','위원회는 검토를 지속하기로 의결했다.'),('나의 요약 단서 누락 판단 / 내가 보건대','내가 보건대 이 요약에는 단서가 빠져 있다.','법원은 이 요약의 무효를 선고했다.')),
      ('G2:-기',('기록팀 / 제출 날짜 확인하기를 맡았다 / 승인 주체 미상은 별도 문장','기록팀은 제출 날짜 확인하기를 맡았다. 승인 주체는 적혀 있지 않다.','기록팀은 날짜 확인과 승인을 담당한다.'),('연구팀 / 결과 재현하기를 목표로 삼았다 / 배포 결정자 미상은 별도 문장','연구팀은 결과 재현하기를 목표로 삼았다. 배포 결정자는 명시되지 않았다.','연구팀은 재현과 배포 결정을 맡는다.')),
    ]
    tasks+=production('KP25',tasks,prod)
    h=loc('제시된 가상 문서 안에서 정의의 외연·필요조건·충분조건·단서를 나누세요. 무관한 범주는 명시된 범주뿐입니다. 인용된 주장은 사실과 다르고, 미상 행위자와 결정은 미상으로 남깁니다.','Within these fictional documents, separate definitional extension, necessary conditions, sufficient conditions and provisos. Only the named category is irrelevant. A quoted claim is not a fact; keep unknown actors and decisions unknown.','Trenne innerhalb der fiktiven Unterlagen Begriffsumfang, notwendige und hinreichende Bedingungen sowie Vorbehalte. Nur die genannte Kategorie ist unerheblich. Zitierte Behauptungen sind keine Tatsachen; lasse unbekannte Zuständige und Entscheidungen offen.')
    p=('가람자료원',12,3,9,'수요일')
    a=('솔빛연구관',16,4,12,'금요일')
    def lecture(args):
        name,total,excluded,valid,day=args
        return f'''[가상 {name} 문서 검토 발표. 발표자: 문서 검토자. 청자: 비전문 동료. 실제 법령이나 계약에 관한 자문이 아니다.]
먼저 적용 범위를 한정하겠습니다. 이 자료에서 등록 연구원이란 이 자료원의 등록 명부에 이름이 있는 사람을 뜻합니다. 전공을 막론하고 등록 연구원은 신청할 수 있습니다. 전공이 무관하다는 말은 등록도 필요 없다는 뜻이 아닙니다. 등록 연구원이라야 원본 열람을 신청할 수 있지만, 등록은 승인에 충분한 조건이 아닙니다.
다음으로 접수와 승인을 나누겠습니다. 이 연습 규정은 신청서와 교육 이수 확인서 두 문서가 모두 있으면 형식 접수 요건을 충족한다고 정의합니다. 두 문서는 형식 접수에 각각 필요하고 함께 있으면 형식 접수에 충분합니다. 내용 심사는 별도이며 심사 기준 전체와 최종 승인자는 제공된 발췌문에 없습니다. 교육 확인서가 빠진 경계 사례는 형식 접수 요건을 충족하지 못합니다. 전공이 다른 등록 연구원이 두 문서를 냈다면 형식 요건은 충족합니다. 그렇다고 열람 승인까지 확정된 것은 아닙니다.
공개 범위도 다릅니다. 요약은 공개하되 식별 정보는 제외합니다. 원본 열람 신청과 요약 공개는 서로 다른 행위입니다. 요약의 공개 담당자는 명시되지 않았습니다. 목소리를 낮추어 단서를 말하더라도 식별 정보 제외를 덜 중요한 정보로 버려서는 안 됩니다.
이제 연구 결과의 경계를 보겠습니다. 시험 기록 {total}건 중 중복 식별자 기록 {excluded}건을 제외한 {valid}건을 분석했습니다. 기록팀이 식별자를 대조했습니다. 정확도가 개선되었다는 주장은 요약 초안에 있지만 이 자료에는 정확도 측정값이 없습니다. 중복 제외는 분석 건수의 변화이며 정확도 개선이나 인과관계의 증거가 아닙니다.
끝으로 조건 변화입니다. 수정안은 교육 확인서를 권고로 바꾸자는 제안입니다. 아직 채택되지 않았으므로 현행 접수 조건은 같습니다. 만약 이 수정안만 채택된다면 확인서가 없는 등록 연구원의 신청도 형식 접수 요건을 충족할 수 있습니다. 원본 승인이나 식별 정보 제외 조건이 함께 바뀌는 것은 아닙니다. 검토 일정은 {day}이며 의결일로 확정한 적은 없습니다. 여러 기관이 함께 쓰느니만큼 용어의 경계를 명시해야 합니다. 내가 바라건대 빠진 판단 주체를 확인하는 논의가 이어졌으면 합니다.'''
    def listen(args):
        return packet(lecture(args),[
          choice('scope',loc('전공 무관의 범위는?','What is the scope of regardless of specialism?','Worauf bezieht sich unabhängig vom Fachgebiet?'),['전공만 무관, 등록 요건 유지','모든 자격 요건 소멸'],h),
          choice('necessary',loc('등록의 논리적 지위는?','What is the logical status of registration?','Welchen logischen Status hat die Registrierung?'),['신청 필요조건, 승인 충분조건 아님','승인 필요충분조건'],h),
          choice('sufficient',loc('두 문서의 공동 충족이 보장하는 것은?','What does providing both documents establish?','Was belegt das Vorliegen beider Unterlagen?'),['형식 접수 요건만 충족','내용 심사와 원본 공개 완료'],h),
          choice('proviso',loc('요약 공개의 단서는?','What proviso restricts summary publication?','Welcher Vorbehalt begrenzt die Veröffentlichung?'),['식별 정보 제외','식별 정보를 원본과 함께 공개'],h),
          choice('claim',loc('중복 제외 수치가 입증하지 못하는 것은?','What do duplicate-removal counts fail to prove?','Was belegen die Zahlen zur Dublettenentfernung nicht?'),['정확도 개선과 인과관계','분석 건수의 감소'],h),
          choice('change',loc('수정안 채택 가정에서 바뀌는 것은?','What changes under the adoption hypothesis?','Was ändert sich bei hypothetischer Annahme des Entwurfs?'),['확인서의 형식 접수 필요성만, 승인 보장 아님','현행 규정이 이미 모두 폐지됨'],h),
          choice('actor',loc('명시되지 않은 책임은?','Which responsibility is unspecified?','Welche Zuständigkeit bleibt ungenannt?'),['최종 승인과 요약 공개 담당','식별자 대조 담당'],h),
        ],'audio')
    tasks.append(task('KP25','listening:01','listening',loc('정의·필요조건·단서 복원','Reconstruct definitions, conditions and provisos','Definitionen, Bedingungen und Vorbehalte rekonstruieren'),h,listen(p),listen(a)))
    def terms(args):
        name,total,excluded,valid,day=args
        return f'''[가상 {name} 학습용 이용 약정 발췌. 실제 계약으로 사용할 문서가 아니다.]
제1조 정의. 등록 연구원이란 이 자료원의 등록 명부에 이름이 있는 사람이다. 여기서 열람은 지정된 공간에서 원본을 보는 행위이며 복제·반출·외부 공개를 포함하지 않는다. 등록 연구원의 전공은 신청 자격에서 구별하지 않는다.
제2조 신청과 형식 접수. 등록 연구원이라야 원본 열람을 신청할 수 있다. 신청서와 교육 이수 확인서를 모두 제출하면 형식 접수 요건을 충족한다. 둘 중 하나라도 빠지면 그 요건을 충족하지 못한다. 내용 심사 및 승인 절차는 별도 문서에 따른다. 그 문서와 최종 승인자 이름은 이 발췌문에 없다.
제3조 권리와 의무. 열람 승인을 받은 이용자는 지정 공간에서 승인된 자료를 볼 수 있으며 원본을 반출하지 않을 의무가 있다. 요약은 공개하되 식별 정보는 제외한다. 이 조문은 원본의 외부 공개권을 주지 않는다. 요약 공개를 실행할 담당자는 이 발췌문에서 정하지 않는다.
제4조 조건부 예외. 교육 이수 확인서의 제출이 전산 장애 때문에 불가능하고 접수 담당자가 별도 교육 기록에서 이수를 확인한 경우에만 확인서 제출을 갈음한다. 교육 자체를 면제하는 예외가 아니다. 장애도 별도 확인도 없는 미제출자에게 이 예외를 확대할 수 없다.
[수정 제안서]
확인서 제출을 권고로 바꾸자는 안이다. 제안의 채택 여부는 미정이고 {day}은 검토 일정이다. 예외 조항을 먼저 넓혀 현행 규정인 것처럼 적용하자는 뜻이 아니다.
[문제 요약 A]
전공을 막론하고 누구나 원본을 외부에 공개할 수 있다. 교육은 면제되었으며 {day}에 승인이 끝난다.
[대조 요약 B]
등록 연구원은 전공에 관계없이 열람을 신청할 수 있다. 형식 접수와 승인은 다르며 원본 반출은 허용되지 않는다. 교육 확인서 제출 대체에는 전산 장애와 별도 이수 확인이 모두 필요하다. 수정안은 미채택 상태다.
[검토 메모]
A는 등록과 지정 공간이라는 지시 범위를 지우고 열람을 외부 공개로 넓혔다. 요약의 식별 정보 제외 단서도 빠져 있다. 예외는 확인서 제출을 갈음할 뿐 교육을 면제하지 않는다. 같은 단어가 반복되더라도 개념의 외연과 의무가 유지되었는지 별도로 확인해야 한다.'''
    def read_terms(args):
        return packet(terms(args),[
          choice('definition',loc('열람의 정의가 제외한 행위는?','Which actions are outside the definition of inspection?','Welche Handlungen liegen außerhalb der Einsichtsdefinition?'),['복제·반출·외부 공개','지정 공간에서 원본 보기'],h),
          choice('exception',loc('예외에 필요한 두 조건은?','Which two conditions does the exception require?','Welche zwei Bedingungen verlangt die Ausnahme?'),['전산 장애와 별도 교육 이수 확인','신청자의 미제출 의사만'],h),
          choice('boundary',loc('교육을 받지 않은 사람의 미제출은?','What about a missing certificate from an untrained person?','Was gilt bei fehlendem Nachweis ohne Schulung?'),['예외의 별도 이수 확인 조건 충족 불가','전공 무관이므로 자동 면제'],h),
          choice('right',loc('승인된 열람자의 권리와 의무는?','What right and duty does an approved reader have?','Welches Recht und welche Pflicht hat eine zugelassene Person?'),['지정 공간 열람과 원본 반출 금지','외부 공개권과 교육 면제'],h),
          choice('summary',loc('A의 핵심 의미 변화는?','What key meaning change occurs in A?','Welche zentrale Bedeutungsänderung enthält A?'),['등록·장소·단서를 지우고 열람을 공개로 확대','문장 길이만 줄임'],h),
          choice('revision',loc('검토 일정과 수정안의 상태는?','What are the status of the review date and revision?','Welchen Status haben Prüftermin und Änderung?'),['검토 예정, 채택 미정','승인 완료와 즉시 효력 확정'],h),
        ])
    tasks.append(task('KP25','reading:01','reading',loc('학습용 약정과 요약의 적용 범위','Scope in fictional terms and their summaries','Geltungsbereich fiktiver Bedingungen und Zusammenfassungen'),h,read_terms(p),read_terms(a)))
    def academic(args):
        name,total,excluded,valid,day=args
        return f'''[가상 전문 검토문: {name} 기록 정제와 재현의 경계]
이 글의 목적은 기록 정제 후 남은 자료의 범위를 설명하고 재현 가능성 주장에 필요한 추가 정보를 구별하는 데 있다. 여기서 중복은 값이 비슷하다는 뜻이 아니라 동일한 식별자가 두 번 이상 기록된 경우를 뜻한다. 식별자가 서로 다르고 값만 같다면 이 정의의 중복에는 포함되지 않는다. 정의부터 서로 다른 마당에 두 기관의 정제율을 한데 묶을 수는 없다.
기록팀은 시험 기록 {total}건의 식별자를 대조해 중복 {excluded}건을 제외했고 {valid}건을 분석 대상으로 남겼다. 이 절차는 그 시험 자료에 적용되었다. 모집단 대표성이나 다른 기관에도 같은 비율이 나올지는 이 자료로 판단하지 못한다. 기록팀은 식별자 대조하기를 맡았으며 내용 오류 판정이나 공개 승인까지 맡았다고 적혀 있지는 않다.
요약 초안에는 정제하면 모든 오차가 사라진다는 주장이 있다. 그러나 중복 식별자 제거는 측정 오차·누락·분류 오류 전체의 제거와 같지 않다. 정확도 측정값과 대조 조건이 없으므로 정제의 인과 효과를 산출할 수 없다. 재현은 동일한 자료와 절차로 결과를 다시 얻는다는 뜻으로 한정한다. 높은 정확도와 동의어로 쓰지 않는다.
연구팀은 정제 절차 재현하기를 목표로 삼았다. 이는 목표 진술이며 재현 성공 보고가 아니다. 절차 공개 검토라는 명사 연쇄는 누가 무엇을 검토하는지 스스로 밝히지 않는다. 제공 자료에는 공개 결정자와 검토 책임자가 없다. 연구팀이라는 이름이 가까이 등장한다고 그 권한까지 배정해서는 안 된다.
내가 보건대 현재 초안에는 단서가 빠져 있다. 권고는 동일 식별자 기준을 명시하고 남은 {valid}건의 범위를 설명하며, 정확도 주장에 필요한 측정 자료를 별도로 요청하자는 것이다. 이 평가는 검토자의 제안으로, 현행 약정의 권리와 의무를 바꾸는 새 규범이 아니다. 영향이 큰 사안이니만큼 범위를 확인해야 한다는 판단 역시 새 승인 권한을 만드는 말은 아니다.'''
    def read_academic(args):
        return packet(academic(args),[
          choice('boundary',loc('값이 같고 식별자가 다른 기록은?','What about equal values with different identifiers?','Was gilt bei gleichen Werten mit verschiedenen Kennungen?'),['제시된 중복 정의에 포함되지 않음','반드시 중복으로 제거'],h),
          choice('count',loc('분석 대상과 수치의 범위는?','What is the analysis set and numerical scope?','Was sind Analysemenge und Geltungsbereich der Zahlen?'),[f'{args[3]}건, 해당 시험 자료에 한정','모든 기관의 정확도 개선율'],h),
          choice('causation',loc('인과 효과를 주장할 수 없는 이유는?','Why is a causal effect not established?','Warum ist ein kausaler Effekt nicht belegt?'),['정확도 측정값과 대조 조건 없음','중복은 반드시 모든 오류와 같음'],h),
          choice('nominal',loc('명사 연쇄에서 남겨야 할 미상 정보는?','What must remain unknown in the noun chain?','Was muss in der Nominalkette offenbleiben?'),['공개 결정자와 검토 책임자','식별자 대조를 한 기록팀'],h),
          choice('norm',loc('검토자의 권고가 아닌 것은?','What does the reviewer’s recommendation not establish?','Was begründet die Empfehlung nicht?'),['현행 약정 변경과 새 승인 권한','추가 측정 자료 요청 제안'],h),
        ])
    tasks.append(task('KP25','reading:02','reading',loc('전문 정의·재현·인과의 경계','Boundaries of definition, reproduction and causation','Grenzen von Definition, Reproduktion und Kausalität'),h,read_academic(p),read_academic(a)))
    rubric=loc('완결된 전문 요약문과 검토 보고서를 각각 쓰세요. 요약에는 목적·중복의 조작적 정의·식별자 대조 방법·원래 건수·제외 건수·남은 건수·측정 한계를 보존합니다. 재현 목표를 성공으로, 중복 제거를 정확도 인과 효과로 바꾸지 않아요. 보고서에는 약정의 적용 대상·권리·의무·단서·예외를 원문 구절과 대조하고 A의 확장을 고칩니다. 필요조건과 충분조건을 신청·형식 접수·승인별로 구별하세요. 교육 확인서가 없는 경계 사례를 현행과 수정안 채택 가정으로 각각 분석하되 전산 장애 예외의 두 조건을 지킵니다. 명사 연쇄를 문장으로 풀고 확인되지 않은 승인·검토 주체는 미상으로 표시하세요. 마지막에 사실·해석·규범·권고를 구별해 추가 확인과 실행 조건을 쓰고 원문과 다시 대조해 고칩니다. 자유 의미와 논증은 미채점입니다.',
      'Write a complete specialist summary and a separate review report. Preserve purpose, operational definition of duplicates, identifier-comparison method, original, excluded and remaining counts, and measurement limits. Do not turn a reproduction goal into success or duplicate removal into a causal accuracy effect. In the report compare applicability, rights, duties, provisos and exceptions with quoted clauses and repair A’s expansions. Separate necessary and sufficient conditions for application, formal receipt and approval. Analyse missing-certificate boundary cases under current rules and hypothetical adoption, retaining both outage-exception conditions. Unpack noun chains and mark unknown approval and review actors. End by separating fact, interpretation, rule and recommendation, stating needed checks and implementation conditions; revise against the sources. Free meaning and argument remain unscored.',
      'Schreibe eine vollständige fachliche Zusammenfassung und einen getrennten Prüfbericht. Erhalte Zweck, operationale Dublettendefinition, Kennungsvergleich, Ausgangs-, Ausschluss- und Restzahlen sowie Messgrenzen. Mache ein Reproduktionsziel nicht zum Erfolg und Dublettenentfernung nicht zur kausalen Genauigkeitswirkung. Vergleiche im Bericht Geltungsbereich, Rechte, Pflichten, Vorbehalte und Ausnahmen anhand zitierter Klauseln und korrigiere die Erweiterungen in A. Trenne notwendige und hinreichende Bedingungen für Antrag, formalen Eingang und Genehmigung. Analysiere Grenzfälle ohne Nachweis nach geltender Regel und bei hypothetischer Annahme; erhalte beide Bedingungen der Störungsausnahme. Löse Nominalketten auf und kennzeichne unbekannte Genehmigungs- und Prüfzuständige. Trenne abschließend Tatsache, Deutung, Regel und Empfehlung, nenne weitere Prüfungen und Ausführungsbedingungen und überarbeite am Ausgangstext. Freier Inhalt und Argumentation bleiben unbewertet.')
    def writing(args):
        return packet(terms(args)+'\n'+academic(args),[
          free_text('summary',loc('완결된 전문 요약문','Complete specialist summary','Vollständige fachliche Zusammenfassung'),rubric),
          free_text('report',loc('범위·경계 사례·책임 검토 보고서','Review of scope, boundary cases and responsibility','Prüfbericht zu Geltungsbereich, Grenzfällen und Verantwortung'),rubric),
        ],'form')
    tasks.append(task('KP25','writing:01','writing',loc('전문 요약과 제도 검토 보고서','Specialist summary and institutional review','Fachliche Zusammenfassung und institutioneller Prüfbericht'),rubric,writing(p),writing(a)))
    speech=loc('비전문 동료에게 먼저 해요체로 열람·공개·접수·승인을 경계 사례로 설명하고, 같은 내용을 합쇼체 발표로 다시 말하세요. 전공이 다른 등록자, 교육 확인서 미제출자, 전산 장애와 별도 이수 확인이 있는 사람을 구별합니다. 동료가 “전공 무관이면 등록도 없어도 되죠?”라고 물으면 선택권을 남긴 확인 질문과 원문으로 범위를 수리하세요. 수정안 채택 가정에서 바뀌는 조건 하나와 그대로인 조건을 나눕니다. 모어가 다른 동료에게 한국어로 인용 명제가 참으로 바뀌는 오류와 필요조건이 승인 보장으로 바뀌는 오류를 설명하세요. 긴 정의·단서·예외를 의미 단위로 끊어 녹음하고 재생합니다. 낮은 음량의 단서도 생략하지 않으며 모어 강세를 한국어 필수 규칙으로 단정하지 않습니다. 미상 책임자·선택권·원문 범위를 보존해 다시 말하세요. 의미·억양·중개는 미채점입니다.',
      'Explain inspection, publication, receipt and approval to a non-specialist politely using boundary cases, then give a formal version. Distinguish a registered person from another specialism, a missing-certificate case and an outage with separately verified training. Repair the inference that specialism-independent means registration-free by checking understanding and citing scope, preserving the colleague’s choice. Separate the one condition changed by hypothetical adoption from unchanged conditions. In Korean explain two transfer errors to a colleague with another first language: a quoted proposition becomes true, and a necessary condition becomes guaranteed approval. Record and replay long definitions, provisos and exceptions in meaning units. Retain quiet provisos and do not impose first-language stress as a mandatory Korean rule. Rephrase with unknown actors, choice and source scope intact. Meaning, prosody and mediation remain unscored.',
      'Erkläre einer fachfremden Person höflich Einsicht, Veröffentlichung, Eingang und Genehmigung anhand von Grenzfällen; sprich danach eine förmliche Version. Trenne registrierte Personen anderer Fachgebiete, fehlende Nachweise und Störung mit gesondert bestätigter Schulung. Korrigiere den Schluss fachunabhängig bedeute registrierungsfrei mit Verständnisfrage und Quellenbeleg, ohne Wahlmöglichkeiten zu nehmen. Trenne die bei hypothetischer Annahme geänderte Bedingung von unveränderten Bedingungen. Erkläre einer Person anderer Erstsprache auf Koreanisch zwei Übertragungsfehler: zitierte Aussage wird Wahrheit, notwendige Bedingung garantierte Genehmigung. Nimm lange Definitionen, Vorbehalte und Ausnahmen in Sinneinheiten auf und höre sie an. Erhalte leise Vorbehalte und erkläre erstsprachliche Betonung nicht zur zwingenden koreanischen Regel. Formuliere mit offenen Zuständigen, Wahlfreiheit und Quellenumfang erneut. Inhalt, Prosodie und Sprachmittlung bleiben unbewertet.')
    tasks.append(task('KP25','speaking:01','speaking',loc('비전문 동료에게 조건과 예외 설명','Explain conditions and exceptions to a peer','Bedingungen und Ausnahmen verständlich erklären'),speech,packet(terms(p)+'\n'+academic(p),[]),packet(terms(a)+'\n'+academic(a),[])))
    return tasks


if __name__=='__main__':
    write_source('KP25',kp25())
