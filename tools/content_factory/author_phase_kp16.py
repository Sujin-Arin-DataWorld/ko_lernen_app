"""KP16 scope of hypothetical conditions, concessions and alternatives."""
from phase_task_authoring import choice, free_text, grammar_task, loc, packet, task, write_source
from author_phase_a1_production import production


def kp16():
    rows=[
      ('G4:-는다면1',loc('조건을 가정해 뒤 가능성을 검토해요. 형태만으로 현실성이나 실현 여부가 정해지지 않으므로 자료에 적힌 실제 조건과 상상을 구별해요.','Consider a possibility under an assumed condition. The form alone does not determine whether it is realistic or fulfilled; use the stated context.','Prüfe eine Möglichkeit unter einer angenommenen Bedingung. Die Form allein bestimmt weder Realitätsnähe noch Erfüllung; beachte den angegebenen Kontext.'),
       ('아직 미정인 지원이 늘어난다면 더 많은 사람이 참여할 수 있어요.','지원 증가를 가정한 가능성, 아직 미정','지원 증가와 전원 참여가 이미 확정됨'),
       ('현재 추가 공간은 없습니다. 방이 하나 더 있다면 따로 모일 수 있어요.','현재 없는 추가 공간을 가정함','추가 방이 이미 예약돼 있음')),
      ('G4:만 같아도',loc('비교 대상을 최소한의 만족 기준으로 삼아요. 지난번과 같기만 해도 좋겠다는 바람을 이번 결과의 확정으로 바꾸지 않아요.','Treat the comparison as a sufficient minimum. A wish to match last time is not a confirmed current result.','Setze den Vergleich als ausreichendes Mindestmaß an. Der Wunsch nach einem Ergebnis wie beim letzten Mal ist kein bestätigtes Ergebnis.'),
       ('지난번만 같아도 충분히 만족하겠어요.','지난번 수준이면 만족할 것이라는 기준','지난번보다 반드시 두 배 좋아야만 만족'),
       ('이 예시만 같아도 도움이 되겠어요.','예시 수준만 되어도 도움이 될 것이라는 기대','이번 결과가 이미 예시와 같다고 확인')),
      ('G4:-더라도',loc('앞 조건을 양보해도 뒤 결론을 유지해요. 시간이 더 걸려도 확인하겠다는 말은 지연 자체를 원한다거나 모든 요청을 수락한다는 뜻이 아니에요.','Maintain the conclusion even after conceding a condition. Checking despite extra time does not mean wanting delay or accepting every request.','Halte an der Folgerung trotz zugestandener Bedingung fest. Eine Prüfung trotz Mehrzeit bedeutet weder gewünschten Aufschub noch Zustimmung zu jeder Bitte.'),
       ('시간이 더 걸리더라도 정확히 확인하겠습니다.','시간이 늘어도 정확한 확인은 유지','시간이 늘면 확인을 생략'),
       ('비용이 줄더라도 안전 확인은 생략하지 않겠습니다.','비용 감소와 무관하게 안전 확인 유지','비용이 줄면 확인 의무도 없어짐')),
      ('G4:-을래야',loc('구어의 도울래야는 이 과제에서 알아듣기만 연습해요. 표준형 도우려야로 고쳐 쓰며, 하려 해도 여건 때문에 못 한다는 뜻을 유지해요.','Practise recognising colloquial 도울래야 here. For production use the standard 도우려야, retaining inability despite trying or intending to act.','Übe hier das Verstehen des umgangssprachlichen 도울래야. Verwende beim Schreiben die Standardform 도우려야 und erhalte das Nichtkönnen trotz Absicht oder Versuch.'),
       ('구어: 시간이 없어서 도울래야 도울 수가 없었어요. 표준형: 시간이 없어서 도우려야 도울 수가 없었어요.','돕고 싶어도 시간 때문에 돕지 못함','도울 시간이 충분해 이미 도움을 마침'),
       ('구어: 화면이 꺼져서 읽을래야 읽을 수가 없었어요. 표준형: 화면이 꺼져서 읽으려야 읽을 수가 없었어요.','읽으려 해도 꺼진 화면 때문에 읽지 못함','화면 내용을 이미 모두 읽고 확인함')),
      ('G4:-든지2',loc('행동의 대안을 제시해 상대가 선택하게 해요. 던지의 회상과 구별하고 두 일을 반드시 모두 해야 한다고 늘리지 않아요.','Offer alternative actions for the listener to choose. Distinguish this from retrospective 던지; do not require both actions.','Biete Handlungsalternativen zur Wahl. Unterscheide sie vom rückblickenden 던지 und verlange nicht beide Handlungen.'),
       ('메일을 보내든지 직접 전화해 주세요.','메일이나 전화 중 방법 선택','메일과 전화를 반드시 모두 해야 함'),
       ('여기서 기다리든지 내일 다시 와 주세요.','기다리기와 내일 방문 중 선택','지금 기다리고 내일도 반드시 방문')),
      ('G4:이든',loc('어느 대상을 고르더라도 뒤 요구는 유지돼요. 방식 선택이 자유롭다는 말이 다른 조건까지 없앤다는 뜻은 아니에요.','Keep the following requirement whichever option is chosen. Freedom of method does not remove other conditions.','Erhalte die folgende Anforderung unabhängig von der gewählten Option. Methodenfreiheit hebt andere Bedingungen nicht auf.'),
       ('어떤 방식이든 먼저 이야기해 봅시다.','방식에 관계없이 먼저 논의','방식을 고르면 논의 없이 바로 시행'),
       ('어느 장소이든 출입 조건은 확인해야 합니다.','어느 장소를 골라도 출입 조건 확인','장소를 정하면 모든 출입 조건 면제')),
      ('G4:이나마',loc('충분하지 않더라도 있는 도움이나 시간을 긍정적으로 인정해요. 제한된 양을 충분한 전체 지원이나 무제한 약속으로 바꾸지 않아요.','Value the help or time available even if limited. Do not turn a modest contribution into full support or an unlimited promise.','Würdige verfügbare Hilfe oder Zeit trotz Begrenzung. Mache aus einem kleinen Beitrag keine vollständige Unterstützung oder unbegrenzte Zusage.'),
       ('작은 도움이나마 보태고 싶어요.','작더라도 도움이 되고 싶은 바람','필요한 지원 전체를 이미 제공함'),
       ('짧은 시간이나마 의견을 나눌 수 있어 다행이에요.','짧은 시간의 대화 기회를 긍정함','무제한으로 대화 시간을 보장함')),
      ('G4:이라도',loc('더 좋은 선택이 어렵다면 차선책도 받아들여요. 내일도 괜찮다는 수용은 상대가 내일로 확정했다는 뜻은 아니에요.','Accept a fallback when the preferred option is difficult. Acceptability tomorrow does not mean the other person has confirmed it.','Akzeptiere eine Ausweichlösung, wenn die bevorzugte Wahl schwierig ist. Morgen wäre möglich heißt nicht, dass die andere Person zugesagt hat.'),
       ('오늘이 어렵다면 내일이라도 괜찮아요.','오늘 대신 내일도 수용 가능','상대가 내일로 이미 확정함'),
       ('원본이 없다면 사본이라도 먼저 볼게요.','원본 대신 사본을 우선 보는 차선책','사본이 원본과 같은 효력이라고 확정')),
      ('G4:이면',loc('특정 범주의 때나 대상을 지정해 일반적인 경향을 말해요. 주말의 경향을 오늘이 주말이라는 사실이나 예외 없는 법칙으로 바꾸지 않아요.','Specify a category of time or entity for a general tendency. A weekend pattern does not establish that today is a weekend or that there are no exceptions.','Bezeichne eine Zeit- oder Personenkategorie für eine allgemeine Tendenz. Ein Wochenendmuster beweist weder, dass heute Wochenende ist, noch dass es keine Ausnahmen gibt.'),
       ('주말이면 이곳은 사람들로 붐벼요.','주말이라는 때에 보이는 일반적 경향','오늘이 반드시 주말이라고 확인'),
       ('방학이면 이 방을 찾는 학생이 많아요.','방학이라는 기간의 일반적 경향','모든 방학의 모든 학생이 반드시 방문')),
      ('G4:치고',loc('범주에 대한 기대와 실제 결과를 비교해 평가해요. 첫 시도치고 좋다는 말은 전체 작품 중 최고라는 뜻이 아니에요.','Evaluate the result against expectations for its category. Good for a first attempt does not mean best among all works.','Bewerte ein Ergebnis anhand der Erwartung an seine Kategorie. Gut für einen ersten Versuch bedeutet nicht das Beste unter allen Werken.'),
       ('처음 만든 것치고 꽤 잘했어요.','첫 시도에 대한 기대보다 좋은 평가','모든 전문가의 작품보다 우수하다고 확정'),
       ('짧은 안내문치고 내용이 자세해요.','짧은 안내문이라는 범주에 비해 자세함','모든 필요한 정보가 빠짐없이 있다는 보증')),
      ('G4:-는 한',loc('앞 조건이 유지되는 범위 안에서 뒤 결론도 유지돼요. 조건이 사라지면 같은 결론을 자동 적용하지 않아요.','Maintain a conclusion for as long as the stated condition holds. Do not apply it automatically once the condition no longer holds.','Halte die Schlussfolgerung aufrecht, solange die genannte Bedingung gilt. Wende sie nach Wegfall der Bedingung nicht automatisch weiter an.'),
       ('자료가 부족한 한 단정할 수 없습니다.','자료 부족이 계속되는 범위에서는 단정 불가','자료가 충분해져도 영원히 단정 불가'),
       ('허가가 없는 한 외부에 전달할 수 없습니다.','허가가 없는 동안에는 외부 전달 불가','허가를 받으면 다른 조건 없이 무제한 공개')),
      ('G4:-는다거나2',loc('가능한 행동을 예로 열거해요. 모든 선택지를 빠짐없이 제시한 목록이나 이미 누가 했다는 인용이 아니에요.','List examples of possible actions, not an exhaustive list or a quotation of what someone already did.','Nenne Beispiele möglicher Handlungen, keine vollständige Liste und kein Zitat bereits ausgeführter Handlungen.'),
       ('직접 만난다거나 전화로 이야기하는 방법이 있어요.','만남과 전화는 가능한 방법의 예','두 방법을 모두 이미 실행했다고 보고'),
       ('요약을 쓴다거나 표로 정리하는 방법을 생각해 보세요.','요약과 표는 검토할 방법의 예','요약문과 표 제출이 모두 확정 의무')), 
    ]
    tasks=[grammar_task('KP16',i,*r) for i,r in enumerate(rows,1)]
    prod=[
      ('G4:-는다면1',('미정인 조건 / 아직 미정인 지원이 늘어나다 → 더 많은 사람이 참여할 수 있다 / -ㄴ다면 / 해요체','아직 미정인 지원이 늘어난다면 더 많은 사람이 참여할 수 있어요.','지원 증가와 전원 참여가 이미 확정됐어요.'),('현재 추가 공간은 없음 / 방이 하나 더 있다 → 따로 모일 수 있다 / -다면 / 해요체','방이 하나 더 있다면 따로 모일 수 있어요.','추가 방이 이미 예약돼 있어요.')),
      ('G4:만 같아도',('최소 만족 기준 / 지난번 + 만 같아도 / 충분히 만족하겠다 / 해요체','지난번만 같아도 충분히 만족하겠어요.','지난번보다 반드시 두 배 좋아야 만족하겠어요.'),('최소 도움 기준 / 이 예시 + 만 같아도 / 도움이 되겠다 / 해요체','이 예시만 같아도 도움이 되겠어요.','이번 결과는 이미 예시와 같아요.')),
      ('G4:-더라도',('양보 뒤 결론 유지 / 시간이 더 걸리다 → 정확히 확인하겠다 / -더라도 / 합쇼체','시간이 더 걸리더라도 정확히 확인하겠습니다.','시간이 더 걸리면 확인을 생략하겠습니다.'),('양보 뒤 결론 유지 / 비용이 줄다 → 안전 확인은 생략하지 않겠다 / -더라도 / 합쇼체','비용이 줄더라도 안전 확인은 생략하지 않겠습니다.','비용이 줄면 안전 확인을 생략하겠습니다.')),
      ('G4:-을래야',('구어 도울래야를 표준형으로 / 시간이 없어서 / 돕다 + -으려야 / 도울 수가 없다 / 과거 해요체','시간이 없어서 도우려야 도울 수가 없었어요.','시간이 충분해서 이미 도움을 마쳤어요.'),('구어 읽을래야를 표준형으로 / 화면이 꺼져서 / 읽다 + -으려야 / 읽을 수가 없다 / 과거 해요체','화면이 꺼져서 읽으려야 읽을 수가 없었어요.','화면을 모두 읽고 확인했어요.')),
      ('G4:-든지2',('두 행동 중 선택 / 메일을 보내다 → 직접 전화해 주세요 / -든지','메일을 보내든지 직접 전화해 주세요.','메일도 보내고 전화도 반드시 해 주세요.'),('두 행동 중 선택 / 여기서 기다리다 → 내일 다시 와 주세요 / -든지','여기서 기다리든지 내일 다시 와 주세요.','여기서 기다리고 내일도 반드시 다시 와 주세요.')),
      ('G4:이든',('자유 선택에도 논의 유지 / 어떤 방식 + 이든 / 먼저 이야기해 봅시다','어떤 방식이든 먼저 이야기해 봅시다.','방식을 고르면 논의 없이 바로 시행합시다.'),('자유 선택에도 조건 확인 유지 / 어느 장소 + 이든 / 출입 조건은 확인해야 합니다','어느 장소이든 출입 조건은 확인해야 합니다.','장소를 정하면 출입 조건을 모두 면제합니다.')),
      ('G4:이나마',('제한된 도움 긍정 / 작은 도움 + 이나마 / 보태고 싶다 / 해요체','작은 도움이나마 보태고 싶어요.','필요한 지원 전체를 이미 제공했어요.'),('제한된 시간 긍정 / 짧은 시간 + 이나마 / 의견을 나눌 수 있어 다행이다 / 해요체','짧은 시간이나마 의견을 나눌 수 있어 다행이에요.','무제한으로 이야기할 시간을 보장해요.')),
      ('G4:이라도',('차선 수용 / 오늘이 어렵다면 / 내일 + 이라도 / 괜찮다 / 해요체','오늘이 어렵다면 내일이라도 괜찮아요.','상대가 내일로 이미 확정했어요.'),('차선 수용 / 원본이 없다면 / 사본 + 이라도 / 먼저 볼게요','원본이 없다면 사본이라도 먼저 볼게요.','사본은 원본과 같은 효력이 확정됐어요.')),
      ('G4:이면',('때 범주의 경향 / 주말 + 이면 / 이곳은 사람들로 붐비다 / 해요체','주말이면 이곳은 사람들로 붐벼요.','오늘은 반드시 주말이에요.'),('때 범주의 경향 / 방학 + 이면 / 이 방을 찾는 학생이 많다 / 해요체','방학이면 이 방을 찾는 학생이 많아요.','모든 학생이 모든 방학에 반드시 방문해요.')),
      ('G4:치고',('범주 기대와 비교 / 처음 만든 것 + 치고 / 꽤 잘하다 / 과거 해요체','처음 만든 것치고 꽤 잘했어요.','모든 전문가의 작품보다 우수해요.'),('범주 기대와 비교 / 짧은 안내문 + 치고 / 내용이 자세하다 / 해요체','짧은 안내문치고 내용이 자세해요.','필요한 모든 정보가 빠짐없이 있어요.')),
      ('G4:-는 한',('조건 범위 / 자료가 부족하다 → 단정할 수 없습니다 / -ㄴ 한','자료가 부족한 한 단정할 수 없습니다.','자료가 충분해져도 영원히 단정할 수 없습니다.'),('조건 범위 / 허가가 없다 → 외부에 전달할 수 없습니다 / -는 한','허가가 없는 한 외부에 전달할 수 없습니다.','허가만 받으면 모든 자료를 무제한 공개할 수 있습니다.')),
      ('G4:-는다거나2',('행동 예시 / 직접 만나다 → 전화로 이야기하는 방법이 있어요 / -ㄴ다거나','직접 만난다거나 전화로 이야기하는 방법이 있어요.','두 방법을 이미 모두 실행했어요.'),('행동 예시 / 요약을 쓰다 → 표로 정리하는 방법을 생각해 보세요 / -ㄴ다거나','요약을 쓴다거나 표로 정리하는 방법을 생각해 보세요.','요약과 표는 모두 반드시 제출해야 합니다.')),
    ]
    tasks+=production('KP16',tasks,prod)
    h=loc('실제로 가능한 조건, 현재 사실과 다른 가정, 양보해도 유지되는 결론, 차선책을 구분하세요. 검토·제안·잠정 수용을 최종 합의로 바꾸지 않아요. 원문에 남은 예외와 상대의 선택권을 보존하세요.',
      'Separate feasible conditions, counterfactual assumptions, conclusions maintained despite concessions and fallbacks. Review, proposals and provisional acceptance are not final agreement. Preserve exceptions and the other person’s choice.',
      'Trenne tatsächlich mögliche Bedingungen, Annahmen entgegen dem aktuellen Stand, trotz Zugeständnissen geltende Folgerungen und Ausweichlösungen. Prüfung, Vorschlag und vorläufige Zustimmung sind keine endgültige Einigung. Erhalte Ausnahmen und Wahlfreiheit.')
    def discussion(day,nextday,limit):
        return packet(f'가상 준비 모임의 협의입니다. 두 사람은 동등한 동료이며 장소를 최종 승인할 권한은 없습니다.\n가: 현재 {day}에 쓸 수 있는 방은 하나이고 정원은 {limit}명이에요. 저는 시간 약속을 지키는 것이 중요해요.\n나: 저는 더 많은 사람이 의견을 나누는 것이 중요해요. 방이 하나 더 있다면 두 모임으로 나눌 수 있겠지만 지금 추가 방은 없어요.\n가: 시간이 더 걸리더라도 안전 확인은 생략하지 않을게요. 정원을 지키는 한 이 방을 신청하는 데는 동의할 수 있어요.\n나: 작은 모임이나마 먼저 열면 도움이 되겠어요. {day}이 어렵다면 {nextday}이라도 검토해 볼 수 있어요. 다만 그날 방이 있는지는 아직 몰라요.\n가: 직접 만난다거나 온라인으로 의견을 듣는 방법도 있겠네요. 어느 방식이든 기록 공개는 별도 동의가 필요해요.\n나: 맞아요. 요약만 공개하더라도 동의는 받아야 해요. 동의가 없는 한 공개할 수 없어요. 제가 장소 담당자에게 메일을 보내든지 전화해서 가능한 시간을 확인할게요. 지금 장소나 공개를 확정한 것은 아니에요.',[
          choice('counterfactual',loc('현재 사실과 다른 가정은?', 'Which assumption differs from current facts?', 'Welche Annahme widerspricht dem aktuellen Stand?'),['추가 방이 하나 더 있다는 가정','현재 방 한 개가 있다는 정보'],h),
          choice('condition',loc('가의 방 신청 수락 조건은?', 'Under what condition does A accept applying?', 'Unter welcher Bedingung stimmt A dem Antrag zu?'),['정원 준수','참가 인원 무제한'],h),
          choice('concession',loc('시간이 늘어도 유지할 것은?', 'What remains required despite extra time?', 'Was bleibt trotz zusätzlicher Zeit erforderlich?'),['안전 확인','안전 확인 생략'],h),
          choice('fallback',loc('차선 날짜의 상태는?', 'What is the status of the fallback date?', 'Welchen Status hat der Ausweichtermin?'),[nextday+' 검토 가능, 방 유무 미확인',nextday+' 장소 최종 승인 완료'],h),
          choice('disclosure',loc('요약만 공개할 때도 필요한 것은?', 'What is still needed for a summary alone?', 'Was wird auch für eine bloße Zusammenfassung benötigt?'),['별도 동의','아무 조건 없이 자동 공개'],h),
          choice('contact',loc('메일이나 전화는 어떤 관계예요?', 'How are email and phone related?', 'In welchem Verhältnis stehen E-Mail und Telefon?'),['선택 가능한 확인 수단','둘 다 이미 수행 완료'],h),
          choice('decision',loc('두 사람의 권한과 합의 상태는?', 'What authority and agreement do they have?', 'Welche Befugnis und Einigung haben beide?'),['최종 승인 권한 없음, 확인 후 협의 필요','장소와 공개를 모두 최종 승인함'],h),
        ],'audio')
    tasks.append(task('KP16','listening:01','listening',loc('정원·시간·공개 조건의 협의','Negotiate capacity, time and disclosure conditions','Kapazität, Zeit und Weitergabe aushandeln'),h,
      discussion('금요일','월요일','스무'),discussion('화요일','목요일','열다섯')))
    def sources(day,nextday,limit):
        return f'학습용 가상 약관\n제1조: 등록 모임은 {day}의 방 하나를 신청할 수 있다. 정원은 {limit}명이다. 정원을 지키는 한 신청을 검토한다. 신청 접수는 승인이나 이용 보장을 뜻하지 않는다.\n제2조: 일정이 늦어지더라도 안전 확인은 생략할 수 없다.\n제3조: 참석자의 발언 기록은 별도 동의가 없는 한 공개할 수 없다. 다만 이름과 개인 발언이 전혀 없는 모임 날짜·장소 안내는 공개할 수 있다. 요약본이라도 개인 발언을 포함하면 동의를 받아야 한다.\n제4조: 장소 담당자는 가능한 시간을 확인해 답할 책임이 있으며 최종 승인은 운영팀이 한다. {nextday}의 빈방 여부는 아직 미상이다.\n\n가상 의견문 — 작은 모임부터 시작하자는 제안\n나는 현재 가능한 작은 모임을 먼저 검토하자고 제안한다. 시간이 정해져 있으면 약속을 지키는 데 도움이 되고, 작은 모임이나마 서로 의견을 나눌 기회가 생기기 때문이다. 더 많은 사람이 참여해야 한다는 반론은 타당하다. 그러나 지금 추가 방은 없으므로 방이 두 개라는 가정을 현재 대안처럼 제시해서는 안 된다.\n현장 소규모 모임과 온라인 의견 수렴을 비교하면 이동 부담은 온라인이 적지만 화면 이용이 어려운 사람은 참여하기 어렵다. 현장 모임은 정원의 제한이 있다. 어느 방식이 모든 사람에게 나은지는 자료가 부족하다. 현장 신청이 어렵다면 {nextday}이라도 확인하거나 온라인 의견 수렴을 검토하자. 요약 공개가 마음에 들더라도 개인 발언 동의 조건은 유지해야 한다. 날짜·장소만 알리는 예외와 개인 발언 요약을 혼동해서는 안 된다. 이 글은 제안이며 운영팀의 승인을 대신하지 않는다.'
    def reading(day,nextday,limit):
        return packet(sources(day,nextday,limit),[
          choice('necessary',loc('정원 준수가 보장하는 범위는?', 'What does respecting capacity allow?', 'Was ermöglicht die Einhaltung der Kapazität?'),['신청 검토 대상이 됨, 승인 보장은 아님','신청 없이 이용이 자동 보장됨'],h),
          choice('conclusion',loc('일정이 늦어질 때 유지되는 결론은?', 'What still holds if the schedule slips?', 'Was gilt bei einer Terminverschiebung weiterhin?'),['안전 확인은 생략 불가','늦어진 만큼 안전 확인 면제'],h),
          choice('exception',loc('동의 없이 공개 가능한 예외는?', 'What exception permits publication without consent?', 'Welche Ausnahme erlaubt eine Veröffentlichung ohne Zustimmung?'),['이름·개인 발언이 없는 날짜·장소 안내','개인 발언을 포함한 모든 요약본'],h),
          choice('counterpoint',loc('더 많은 참여가 필요하다는 반론에 대한 응답은?', 'How does the essay respond to the broader-participation objection?', 'Wie antwortet der Text auf den Einwand breiterer Teilnahme?'),['필요를 인정하되 현재 없는 추가 방을 현실 대안으로 삼지 않음','참여 확대가 전혀 가치 없다고 주장'],h),
          choice('comparison',loc('온라인 대안에도 남는 한계는?', 'What limitation remains for the online option?', 'Welche Grenze bleibt bei der Online-Alternative?'),['화면 이용이 어려운 사람의 참여 어려움','누구나 동일하게 참여할 수 있다는 보장'],h),
          choice('authority',loc('최종 승인 권한은 누구에게 있어요?', 'Who has final approval authority?', 'Wer hat die endgültige Genehmigungsbefugnis?'),['운영팀','의견문 작성자'],h),
        ])
    tasks.append(task('KP16','reading:01','reading',loc('약관의 제한과 의견문의 양보','Limits in terms and concessions in an opinion essay','Grenzen in Bedingungen und Zugeständnisse im Meinungstext'),h,
      reading('금요일','월요일',20),reading('화요일','목요일',15)))
    p=sources('금요일','월요일',20);a=sources('화요일','목요일',15)
    rubric=loc('현재 가능한 현장 모임과 온라인 의견 수렴을 같은 기준으로 비교해 의견문을 쓰세요. 주장·근거·참여 확대 반론·응답·차선책을 연결하고 이동 부담과 접근성의 한계를 함께 밝히세요. 정원·안전 확인·동의 조건과 공개 예외를 정확히 유지해요. 없는 추가 방이나 미확인 날짜를 확정하지 말고, 운영팀의 승인과 자신의 제안을 구별하세요. 상대 입장을 약화한 곳과 모순된 조건을 찾아 고쳐 쓰세요. 전체 의미·논증은 미채점입니다.',
      'Write an opinion essay comparing the available in-person meeting and online consultation on common criteria. Connect claim, evidence, broader-participation objection, response and fallback, including travel and access limits. Preserve capacity, safety, consent and the disclosure exception. Do not confirm an unavailable extra room or unknown date; distinguish your proposal from approval. Revise weakened counterarguments or inconsistent conditions. Full meaning and argumentation remain unscored.',
      'Vergleiche im Meinungstext das verfügbare Präsenztreffen und die Online-Beteiligung nach gemeinsamen Kriterien. Verbinde These, Belege, Einwand breiterer Teilnahme, Antwort und Ausweichlösung samt Anreise- und Zugangsgrenzen. Erhalte Kapazität, Sicherheit, Zustimmung und Ausnahme zur Weitergabe. Bestätige weder einen nicht verfügbaren Zusatzraum noch einen unbekannten Termin; trenne Vorschlag und Genehmigung. Korrigiere abgeschwächte Gegenargumente und widersprüchliche Bedingungen. Gesamtinhalt und Argumentation bleiben unbewertet.')
    prompt=loc('조건과 반론을 보존한 의견문을 쓰세요.','Write an opinion essay preserving conditions and counterarguments.','Schreibe einen Meinungstext mit unveränderten Bedingungen und Gegenargumenten.')
    tasks.append(task('KP16','writing:01','writing',loc('조건을 바꿔도 모순 없는 의견문','An opinion essay with consistent conditions','Ein Meinungstext mit widerspruchsfreien Bedingungen'),rubric,
      packet(p,[free_text('essay',prompt,rubric)],'form'),packet(a,[free_text('essay',prompt,rubric)],'form')))
    speech=loc('동등한 동료 A는 시간 약속, B는 참여 확대를 중시해요. 두 역할을 나눠 해요체로 조건·양보·거절·차선책을 협의하세요. 없는 추가 방을 가정할 수는 있지만 실제 이용 가능하다고 말하지 마세요. 이어 합쇼체 회의 정리에서 결정한 확인 업무, 잠정 수용, 미합의점, 운영팀의 승인 권한을 구별하세요. -더라도 뒤에도 유지되는 결론과 -든지의 선택을 따로 끊어 말하고 녹음을 고쳐요. 의미·억양·협상 능력은 미채점입니다.',
      'Equal colleague A prioritises keeping the time commitment; B prioritises wider participation. Voice both roles politely to negotiate conditions, concessions, refusal and fallback. An extra room may be imagined but is not available. Then formally summarise agreed verification work, provisional acceptance, unresolved points and the team’s approval authority. Keep the conclusion after -더라도 distinct from alternatives with -든지; replay and revise. Meaning, intonation and negotiation ability remain unscored.',
      'Gleichgestellte Person A legt Wert auf Termineinhaltung, B auf breitere Teilnahme. Sprich beide Rollen höflich und verhandle Bedingungen, Zugeständnisse, Ablehnung und Ausweichlösung. Ein Zusatzraum darf vorgestellt, aber nicht als verfügbar behauptet werden. Fasse danach förmlich vereinbarte Prüfaufgaben, vorläufige Zustimmung, offene Punkte und Genehmigungsbefugnis zusammen. Trenne die trotz -더라도 geltende Folgerung von Alternativen mit -든지; höre zu und verbessere. Inhalt, Intonation und Verhandlungskompetenz bleiben unbewertet.')
    tasks.append(task('KP16','speaking:01','speaking',loc('상충하는 조건의 협의와 회의 정리','Negotiate conflicting interests and summarise the meeting','Gegensätzliche Bedingungen verhandeln und das Gespräch zusammenfassen'),speech,
      packet(p+'\nA와 B가 합의한 일: B가 장소 담당자에게 가능한 시간 확인. 아직 장소·일정·기록 공개는 미합의.',[]),
      packet(a+'\nA와 B가 합의한 일: B가 장소 담당자에게 가능한 시간 확인. 아직 장소·일정·기록 공개는 미합의.',[])))
    return tasks


if __name__=='__main__':
    write_source('KP16',kp16())
