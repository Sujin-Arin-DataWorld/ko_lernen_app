"""KP10 authored event sequences; generation does not approve publication."""
from phase_task_authoring import choice, free_text, grammar_task, loc, packet, task, write_source
from author_phase_a1_production import production


def kp10():
    rows=[
      ('G3:-다가1(2)',loc('실제로 하던 행동이 다른 행동으로 바뀌어요. 하려고 생각만 한 것과 구별해요.','An action actually in progress changes to another action; distinguish it from a mere intention.','Eine tatsächlich laufende Handlung geht in eine andere über; unterscheide sie von einer bloßen Absicht.'),
       ('자료를 읽다가 전화를 받았어요.','자료를 실제로 읽던 중 전화 받기로 바뀜','읽으려고 생각했지만 전혀 시작하지 않음'),
       ('보고서를 쓰다가 회의에 갔어요.','보고서를 실제로 쓰던 중 회의에 감','보고서 작성을 시작하기 전에 회의를 끝냄')),
      ('G3:-으려다가',loc('하려던 계획을 바꿔 다른 행동을 했어요. 앞 행동을 실제로 완료했다고 추정하지 않아요.','An intended action is replaced by another; do not infer that the first action was completed.','Eine beabsichtigte Handlung wird durch eine andere ersetzt; nimm nicht an, dass die erste abgeschlossen wurde.'),
       ('버스를 타려다가 걸어갔어요.','버스를 탈 계획을 바꿔 걸음','버스를 끝까지 탄 뒤 걸음'),
       ('이메일을 보내려다가 전화했어요.','이메일 대신 전화를 선택함','이메일을 보냈다는 사실이 확정됨')),
      ('G3:-었더니',loc('앞 행동을 해 본 뒤 발견한 결과를 전해요. 결과를 확인하기 전의 예상과 구별해요.','Report a result discovered after an action, not a prediction made before checking.','Berichte ein nach einer Handlung festgestelltes Ergebnis, keine ungeprüfte Vorhersage.'),
       ('파일을 열었더니 내용이 비어 있었어요.','열어 보고 빈 내용을 발견함','열기 전에 내용이 채워졌다고 예상함'),
       ('담당자에게 물었더니 접수가 끝났다고 했어요.','질문 후 담당자의 답을 들음','질문 전에 접수를 직접 완료함')),
      ('G3:-느라고',loc('이 예에서는 같은 사람이 한 행동에 매여 다른 일을 못했어요. 모든 원인에 쓰거나 서로 다른 행위자를 임의로 묶지 않아요.','Here, the same person is occupied with one action and cannot do another. This is not a general substitute for every causal expression.','Hier ist dieselbe Person mit einer Handlung beschäftigt und kann deshalb etwas anderes nicht tun. Die Form ersetzt nicht jede kausale Verbindung.'),
       ('저는 자료를 찾느라고 전화를 못 받았어요.','자료를 찾은 사람과 전화를 못 받은 사람이 같음','동료가 자료를 찾았다는 사실이 명시됨'),
       ('저는 회의하느라고 점심을 못 먹었어요.','화자가 회의에 매여 식사를 못 함','다른 사람이 회의해서 화자가 식사를 끝냄')),
      ('G3:-어다가',loc('앞 장소에서 얻거나 만든 것을 옮겨 뒤 행동에 써요. 단순히 두 행동이 있었다는 뜻으로만 읽지 않아요.','Something obtained or made in one place is brought to another action; preserve this transfer.','Etwas an einem Ort Geholtes oder Hergestelltes wird für die nächste Handlung mitgebracht; erhalte diesen Ortsbezug.'),
       ('주방에서 물을 떠다가 회의실 화분에 주었어요.','주방에서 뜬 물을 회의실로 가져와 씀','회의실 물을 주방에 버림'),
       ('복사실에서 자료를 복사해다가 참석자에게 나눠 주었어요.','복사한 자료를 가져와 나눔','자료를 복사하기 전에 모두 나눔')),
      ('G3:-자마자',loc('앞 행동 직후 뒤 행동이 이어져요. 순서가 즉각적이라는 것만으로 원인을 증명하지는 않아요.','The second action follows immediately; immediate sequence alone does not prove causation.','Die zweite Handlung folgt unmittelbar; die schnelle Abfolge allein beweist keine Ursache.'),
       ('도착하자마자 담당자에게 전화했어요.','도착 직후 전화함','전화한 뒤에 도착함'),
       ('회의가 끝나자마자 기록을 저장했어요.','회의 종료 직후 저장함','저장한 뒤 회의를 시작함')),
      ('G3:-고 나다',loc('앞 행동의 완료를 기준으로 뒤 상황을 말해요. 진행 중과 구별하며, 완료했다는 사실만으로 성공을 단정하지 않아요.','Use completion of the first action as the reference point. Completion is not ongoing activity and does not automatically mean success.','Der Abschluss der ersten Handlung bildet den Bezugspunkt. Abschluss ist weder laufende Tätigkeit noch automatisch Erfolg.'),
       ('정리를 하고 나니 빈자리가 보였어요.','정리를 마친 뒤 빈자리를 봄','정리를 시작하기 전에만 봄'),
       ('설명을 듣고 나니 절차를 이해했어요.','설명을 들은 뒤 이해함','설명을 전혀 듣지 않음')),
      ('G3:-고 말다',loc('이 문맥에서는 바라지 않던 일이 결국 일어난 결과를 나타내요. 아직 안 일어난 걱정과 구별해요.','In this context an unwanted event finally happens; it is not merely a fear about the future.','In diesem Kontext tritt ein unerwünschtes Ereignis schließlich ein; es ist keine bloße Zukunftssorge.'),
       ('서두르다가 파일을 지우고 말았어요.','원치 않았지만 실제로 삭제함','삭제할까 걱정했지만 삭제하지 않음'),
       ('확인을 늦춰서 기한을 놓치고 말았어요.','결국 실제로 기한을 놓침','기한 전에 확인을 마침')),
      ('G3:-어 가다',loc('현재에서 앞으로 이어지는 변화나 진행을 나타내요. 여기서 가다는 물리적 이동이 아니에요.','A change or process continues forward from the present; 가다 is not physical travel here.','Eine Veränderung setzt sich von der Gegenwart aus fort; 가다 bezeichnet hier keine Ortsbewegung.'),
       ('새 업무에 조금씩 익숙해져 가고 있어요.','익숙해지는 변화가 진행 중','이미 완전히 익숙해져 변화가 끝남'),
       ('공용 공간이 점점 깨끗해져 가고 있어요.','깨끗해지는 변화가 이어짐','공간이 다른 주소로 이동함')),
      ('G3:-어 오다',loc('과거부터 기준 시점까지 이어진 과정을 나타내요. 여기서 오다는 물건을 들고 오는 이동이 아니에요.','A process has continued from the past to the reference point; 오다 is not carrying something here.','Ein Vorgang reicht von früher bis zum Bezugspunkt; 오다 bedeutet hier nicht, etwas herzutragen.'),
       ('우리는 지난달부터 이 문제를 논의해 왔어요.','지난달부터 지금까지 논의가 이어짐','논의를 내년에 처음 시작함'),
       ('저는 삼 년 동안 활동 기록을 모아 왔어요.','과거부터 현재까지 기록을 모음','지금 처음 기록을 버리기 시작함')),
      ('G3:-어 놓다',loc('행동을 한 뒤 그 결과를 유지해요. 준비 목적을 가질 수도 있지만 모든 경우에 특정 목적이 명시된 것은 아니에요.','An action leaves its result in place. It may be preparation, but a particular purpose is not always stated.','Eine Handlung hinterlässt einen fortbestehenden Zustand. Sie kann der Vorbereitung dienen, doch ein bestimmter Zweck ist nicht immer genannt.'),
       ('환기하려고 창문을 열어 놓았어요.','창문을 열고 열린 상태를 유지함','창문을 연 뒤 바로 닫음'),
       ('참석자들이 볼 수 있게 안내문을 붙여 놓았어요.','붙인 안내문이 계속 보이도록 둠','안내문을 떼어서 보이지 않게 함')),
      ('G3:-어 두다',loc('나중에 쓰거나 필요할 때를 대비해 행동해 둬요. 이 예에서는 목적이 명시되어 있어요.','An action prepares for later use or need; these examples state the purpose explicitly.','Eine Handlung bereitet eine spätere Nutzung oder einen Bedarf vor; der Zweck steht hier ausdrücklich dabei.'),
       ('내일 회의를 위해 자료를 미리 찾아 두었어요.','내일 사용할 자료를 준비함','회의가 끝난 후 자료를 모두 버림'),
       ('접수할 때 쓰려고 번호를 적어 두었어요.','나중에 접수할 때 쓸 번호를 보관함','이미 접수를 마쳤다는 뜻만 나타냄')),
      ('G3:-어지다',loc('여기서는 형용사와 결합해 상태 변화를 나타내요. 독일어 werden의 모든 수동·미래 용법과 같지 않아요.','With these adjectives, the form marks a change of state, not every passive or future use of German werden.','Bei diesen Adjektiven bezeichnet die Form eine Zustandsänderung; sie entspricht nicht jeder Passiv- oder Zukunftsverwendung von werden.'),
       ('수리한 뒤 방이 따뜻해졌어요.','방의 온도 상태가 달라짐','방이 다른 곳으로 이동함'),
       ('설명을 듣고 마음이 편해졌어요.','마음 상태가 편안한 쪽으로 바뀜','설명을 듣기 전부터 변화 없이 같음')),
      ('G3:-은 결과',loc('앞 행동을 통해 얻은 결과를 연결해요. 자료에 적힌 결과만 옮기고 추가 원인을 만들지 않아요.','Connect an action to its reported result; add no unsupported cause.','Verbinde eine Handlung mit ihrem angegebenen Ergebnis; erfinde keine zusätzliche Ursache.'),
       ('직원들과 의논한 결과 날짜를 바꾸었어요.','의논을 거쳐 날짜를 바꿈','날짜를 바꾼 뒤 처음 의논함'),
       ('기록을 확인한 결과 중복 결제를 발견했어요.','기록 확인으로 중복 결제를 찾음','확인 없이 환불 완료를 보증함')),
      ('G3:-은 다음에',loc('앞 행동을 마친 뒤 뒤 단계로 넘어가요. 다음이라는 단어만으로 두 사건의 인과를 만들지 않아요.','The next step follows completion of the first; this sequencing does not itself establish a causal claim.','Nach Abschluss der ersten Handlung folgt der nächste Schritt; daraus allein entsteht keine Kausalaussage.'),
       ('신청서를 쓴 다음에 창구에 내세요.','작성 완료 후 제출','제출을 마친 뒤 처음 작성'),
       ('내용을 확인한 다음에 저장하세요.','확인 완료 후 저장','저장한 뒤에만 내용 확인')),
      ('G3:-어 가지고',loc('구어에서 앞 행동이나 이유와 뒤 상황을 연결해요. 여기서는 이유를 나타내며 공적 보고문에서는 관계를 분명히 풀어 쓸 수 있어요.','This colloquial form links an action or reason to what follows. Here it gives a reason; formal reporting can state that relation explicitly.','Diese umgangssprachliche Form verbindet Handlung oder Grund mit dem Folgenden. Hier nennt sie einen Grund; im förmlichen Bericht lässt sich dieser Zusammenhang ausdrücklich formulieren.'),
       ('길이 막혀 가지고 조금 늦었어요.','교통 정체가 늦은 이유로 제시됨','늦어서 길이 막혔다고 말함'),
       ('파일이 커 가지고 전송이 오래 걸렸어요.','파일 크기가 긴 전송 시간의 이유','전송이 오래 걸려 파일이 커짐')),
      ('G2:-어 있다',loc('행동 뒤 남은 상태를 나타내요. 열고 있다는 진행이나 열었다는 동작과 구별하고 행위자가 없으면 임의로 추가하지 않아요.','Describe a resulting state, distinct from an ongoing or completed action. Do not invent an agent when none is given.','Beschreibe einen fortbestehenden Zustand, getrennt von laufender oder abgeschlossener Handlung. Ergänze keine ungenannte handelnde Person.'),
       ('확인해 보니 창문이 열려 있었어요.','확인 당시 열린 상태','화자가 여는 동작을 하고 있었음'),
       ('도착했을 때 문이 닫혀 있었어요.','도착 당시 닫힌 상태','누가 닫았는지까지 명시됨')),
    ]
    tasks=[grammar_task('KP10',i,key,h,p,a) for i,(key,h,p,a) in enumerate(rows,1)]
    # Each condition specifies a new sentence to build, not a source to copy.
    prod=[
      ('G3:-다가1(2)',('실제로 읽던 행동 중단 / 저는 자료를 읽다 → 전화를 받다 / -다가 / 과거 해요체','저는 자료를 읽다가 전화를 받았어요.','저는 자료를 읽으려다가 전화를 받았어요.'),('실제로 쓰던 행동 중단 / 저는 보고서를 쓰다 → 회의에 가다 / -다가 / 과거 해요체','저는 보고서를 쓰다가 회의에 갔어요.','저는 보고서를 쓰려다가 회의에 갔어요.')),
      ('G3:-으려다가',('계획 변경 / 저는 버스를 타다 → 걸어가다 / -려다가 / 과거 해요체','저는 버스를 타려다가 걸어갔어요.','저는 버스를 타고 나서 걸어갔어요.'),('계획 변경 / 저는 이메일을 보내다 → 전화하다 / -려다가 / 과거 해요체','저는 이메일을 보내려다가 전화했어요.','저는 이메일을 보내고 나서 전화했어요.')),
      ('G3:-었더니',('실행 뒤 발견 / 파일을 열다 → 내용이 비어 있다 / -었더니 / 과거 해요체','파일을 열었더니 내용이 비어 있었어요.','파일을 열기 전에 내용이 가득했어요.'),('실행 뒤 발견 / 문을 열다 → 안에 아무도 없다 / -었더니 / 과거 해요체','문을 열었더니 안에 아무도 없었어요.','문을 열었더니 안에 모두 있었어요.')),
      ('G3:-느라고',('같은 행위자 / 저는 자료를 찾다 → 전화를 받지 못하다 / -느라고 / 과거 해요체','저는 자료를 찾느라고 전화를 못 받았어요.','동료는 자료를 찾느라고 저는 전화를 못 받았어요.'),('같은 행위자 / 저는 회의하다 → 점심을 먹지 못하다 / -느라고 / 과거 해요체','저는 회의하느라고 점심을 못 먹었어요.','동료는 회의하느라고 저는 점심을 못 먹었어요.')),
      ('G3:-어다가',('장소 이동 뒤 사용 / 물을 뜨다 → 화분에 주다 / -어다가 / 과거 해요체','물을 떠다가 화분에 주었어요.','물을 버리고 화분을 옮겼어요.'),('장소 이동 뒤 사용 / 자료를 복사하다 → 동료에게 주다 / -어다가 / 과거 해요체','자료를 복사해다가 동료에게 주었어요.','자료를 버리고 동료를 불렀어요.')),
      ('G3:-자마자',('즉시 이어짐 / 저는 도착하다 → 전화하다 / -자마자 / 과거 해요체','저는 도착하자마자 전화했어요.','저는 전화하자마자 도착했어요.'),('즉시 이어짐 / 저는 회의를 마치다 → 기록을 저장하다 / -자마자 / 과거 해요체','저는 회의를 마치자마자 기록을 저장했어요.','저는 기록을 저장하자마자 회의를 시작했어요.')),
      ('G3:-고 나다',('완료 뒤 발견 / 정리를 하다 → 빈자리가 보이다 / -고 나니 / 과거 해요체','정리를 하고 나니 빈자리가 보였어요.','정리를 하기 전에만 빈자리가 보였어요.'),('완료 뒤 변화 / 설명을 듣다 → 절차를 이해하다 / -고 나니 / 과거 해요체','설명을 듣고 나니 절차를 이해했어요.','설명을 듣지 않고 절차를 이해했어요.')),
      ('G3:-고 말다',('원치 않은 실제 결과 / 저는 파일을 지우다 / -고 말다 / 과거 해요체','저는 파일을 지우고 말았어요.','저는 파일을 지우지 않았어요.'),('원치 않은 실제 결과 / 저는 기한을 놓치다 / -고 말다 / 과거 해요체','저는 기한을 놓치고 말았어요.','저는 기한을 놓치지 않았어요.')),
      ('G3:-어 가다',('앞으로 이어지는 변화 / 업무에 조금씩 익숙해지다 / -어 가다 + -고 있다 / 해요체','업무에 조금씩 익숙해져 가고 있어요.','업무에 이미 완전히 익숙해졌어요.'),('앞으로 이어지는 변화 / 공간이 점점 깨끗해지다 / -어 가다 + -고 있다 / 해요체','공간이 점점 깨끗해져 가고 있어요.','공간이 다른 곳으로 가고 있어요.')),
      ('G3:-어 오다',('과거부터 지금 / 우리는 지난달부터 문제를 논의하다 / -어 오다 / 과거 해요체','우리는 지난달부터 문제를 논의해 왔어요.','우리는 내일부터 문제를 논의할 거예요.'),('과거부터 지금 / 저는 삼 년 동안 기록을 모으다 / -어 오다 / 과거 해요체','저는 삼 년 동안 기록을 모아 왔어요.','저는 지금부터 처음 기록을 모을 거예요.')),
      ('G3:-어 놓다',('결과 유지 / 저는 창문을 열다 / -어 놓다 / 과거 해요체','저는 창문을 열어 놓았어요.','저는 창문을 열었다가 닫았어요.'),('결과 유지 / 저는 안내문을 붙이다 / -어 놓다 / 과거 해요체','저는 안내문을 붙여 놓았어요.','저는 안내문을 붙였다가 떼었어요.')),
      ('G3:-어 두다',('나중을 위한 준비 / 저는 자료를 미리 찾다 / -어 두다 / 과거 해요체','저는 자료를 미리 찾아 두었어요.','저는 자료를 모두 버렸어요.'),('나중을 위한 준비 / 저는 번호를 미리 적다 / -어 두다 / 과거 해요체','저는 번호를 미리 적어 두었어요.','저는 번호를 모두 지웠어요.')),
      ('G3:-어지다',('형용사 상태 변화 / 방이 따뜻하다 / -어지다 / 과거 해요체','방이 따뜻해졌어요.','방이 따뜻해지지 않았어요.'),('형용사 상태 변화 / 마음이 편하다 / -어지다 / 과거 해요체','마음이 편해졌어요.','마음이 편해지지 않았어요.')),
      ('G3:-은 결과',('행동을 거친 결과 / 직원들과 의논하다 → 날짜를 바꾸다 / -은 결과 / 과거 해요체','직원들과 의논한 결과 날짜를 바꾸었어요.','날짜를 바꾼 결과 처음 의논했어요.'),('행동을 거친 결과 / 기록을 확인하다 → 중복 결제를 발견하다 / -은 결과 / 과거 해요체','기록을 확인한 결과 중복 결제를 발견했어요.','기록을 확인하지 않고 환불을 보증했어요.')),
      ('G3:-은 다음에',('완료 후 순서 / 신청서를 쓰다 → 창구에 내다 / -은 다음에 / -세요','신청서를 쓴 다음에 창구에 내세요.','창구에 낸 다음에 신청서를 쓰세요.'),('완료 후 순서 / 내용을 확인하다 → 저장하다 / -은 다음에 / -세요','내용을 확인한 다음에 저장하세요.','저장한 다음에만 내용을 확인하세요.')),
      ('G3:-어 가지고',('구어 이유 / 길이 막히다 → 조금 늦다 / -어 가지고 / 과거 해요체','길이 막혀 가지고 조금 늦었어요.','조금 늦어 가지고 길이 막혔어요.'),('구어 이유 / 파일이 크다 → 전송이 오래 걸리다 / -어 가지고 / 과거 해요체','파일이 커 가지고 전송이 오래 걸렸어요.','전송이 오래 걸려 가지고 파일이 커졌어요.')),
      ('G2:-어 있다',('결과 상태 / 창문이 열리다 / -어 있다 / 과거 해요체','창문이 열려 있었어요.','창문을 열고 있었어요.'),('결과 상태 / 문이 닫히다 / -어 있다 / 과거 해요체','문이 닫혀 있었어요.','문을 닫고 있었어요.')),
    ]
    tasks+=production('KP10',tasks,prod)
    h=loc('계획 변경, 실제 중단, 확인 뒤 발견, 미리 준비한 조치를 시간 순서대로 나누세요. 담당자의 말과 직접 확인한 내용을 구별하고, 원인이 확인되지 않으면 미상으로 남겨요.',
      'Separate a changed plan, an actual interruption, a discovery after checking and an earlier precaution. Keep staff statements distinct from direct observations; leave an unconfirmed cause unknown.',
      'Trenne Planänderung, tatsächliche Unterbrechung, Feststellung nach einer Prüfung und frühere Vorbereitung. Unterscheide Aussagen der zuständigen Person von eigener Beobachtung; lasse ungeklärte Ursachen offen.')
    def account(vehicle,destination,work,prepared):
        return packet(f'동료에게 경위를 설명합니다. 처음에는 {vehicle}를 타려다가 {destination}까지 걸어갔어요. 도착하자마자 접수 창구에 전화했어요. 잠시 뒤 담당자가 다시 전화했지만, 저는 {work}느라고 그 전화를 바로 받지 못했어요. 이후 자료를 읽다가 안내 방송을 듣고 읽기를 멈췄어요. 담당자에게 다시 물었더니 접수 화면이 열리지 않는다고 했어요. 담당자는 원인을 아직 확인하는 중이라고 했어요. 저는 나중에 필요할까 봐 {prepared}을 미리 적어 두었어요. 같이 의견을 나눈 결과 오늘은 기록만 남기기로 했어요. 이 기록이 다음 확인에 도움이 될 거라고 생각해요.',[
            choice('plan',loc('계획만 하다가 바꾼 행동은?', 'Which action was planned and replaced?', 'Welche Handlung war geplant und wurde ersetzt?'),[vehicle+' 타기','자료 읽기'],h),
            choice('interrupted',loc('실제로 하다가 중단한 일은?', 'Which action was actually interrupted?', 'Welche tatsächlich begonnene Handlung wurde unterbrochen?'),['자료 읽기',vehicle+' 타기'],h),
            choice('source',loc('화면 오류를 전한 출처는?', 'Who reported the screen problem?', 'Wer meldete das Bildschirmproblem?'),['담당자','이유를 확인하지 않은 다른 동료'],h),
            choice('cause',loc('오류 원인은?', 'What caused the error?', 'Was verursachte den Fehler?'),['아직 확인 중','걸어갔기 때문'],h),
            choice('prepared',loc('미리 해 둔 조치는?', 'What was prepared in advance?', 'Was wurde vorsorglich vorbereitet?'),[prepared+' 기록','접수 승인 완료'],h),
        ],'audio')
    tasks.append(task('KP10','listening:01','listening',loc('접수 문제의 경위와 남긴 기록','An application problem and the record kept','Ablauf eines Anmeldeproblems und die Dokumentation'),h,
      account('버스','문화센터','자료를 찾','문의 번호'),account('택시','도서관','회의하','접수 번호')))
    article_help=loc('기사의 관찰 사실·직접 인용·기자의 해석을 나누세요. 먼저 일어난 사건이 반드시 뒤 사건의 원인은 아니에요. 금액과 승인 여부, 아직 확인 중인 내용을 바꾸지 마세요.',
      'Separate observed facts, quotations and the reporter’s interpretation. An earlier event is not necessarily the cause of a later one. Preserve amounts, approval status and unresolved questions.',
      'Trenne beobachtete Fakten, Zitate und die Deutung der berichtenden Person. Ein früheres Ereignis ist nicht zwangsläufig Ursache eines späteren. Erhalte Beträge, Genehmigungsstand und offene Fragen.')
    def article(place,time,fee):
        return packet(f'학습용 가상 기사 | {place} 접수 화면 일시 중단\n오늘 {time}시 접수 화면이 멈췄고, 십 분 뒤 직원이 수기 접수를 시작했다. 중단 직전 새 안내문이 게시됐지만 두 사건의 관련성은 확인되지 않았다. 담당자는 "원인을 확인하는 중이며, 결제 취소는 아직 승인하지 않았습니다"라고 말했다. 한 신청자는 "{fee}원을 두 번 결제한 기록을 봤습니다"라고 말했다. 기자는 안내가 늦어 혼란이 커졌을 가능성이 있다고 해석했다. 실제 중복 청구 여부와 환불 시점은 조사 중이다.',[
            choice('fact',loc('기사에 관찰 사실로 제시된 것은?', 'Which detail is presented as an observed fact?', 'Was wird als beobachtete Tatsache dargestellt?'),[f'{time}시 화면 중단 후 십 분 뒤 수기 접수 시작','안내문 게시가 오류 원인으로 확정'],article_help),
            choice('quote',loc('두 번 결제 기록을 봤다는 말의 출처는?', 'Who reported seeing two payment records?', 'Wer berichtete von zwei Zahlungseinträgen?'),['신청자','기자 자신의 확인'],article_help),
            choice('interpretation',loc('기자의 해석은?', 'Which statement is the reporter’s interpretation?', 'Welche Aussage ist eine Deutung der berichtenden Person?'),['늦은 안내가 혼란을 키웠을 가능성','결제 취소 승인 완료'],article_help),
            choice('limit',loc('확정되지 않은 것은?', 'What remains unconfirmed?', 'Was ist noch unbestätigt?'),['중복 청구 여부와 환불 시점','수기 접수가 시작됐다는 기사 내용'],article_help),
        ])
    tasks.append(task('KP10','reading:01','reading',loc('접수 중단 기사: 사실과 원인 주장','An outage report: facts and causal claims','Meldung über eine Störung: Fakten und Ursachenbehauptungen'),article_help,
      article('한빛센터','열','5000'),article('새봄도서관','두','8000')))
    process_help=loc('설명문의 대상·단계·이유를 구별하세요. 적어 둔 번호나 복사본은 확인을 돕는 자료이지 승인·환불의 증거가 아니에요. 조치와 결과 상태를 구별해요.',
      'Identify the object, steps and reasons in the explanation. A saved number or copy supports checking; it does not prove approval or refund. Distinguish an action from its resulting state.',
      'Unterscheide Gegenstand, Schritte und Gründe der Erklärung. Eine notierte Nummer oder Kopie hilft bei der Prüfung, beweist aber weder Genehmigung noch Erstattung. Trenne Handlung und fortbestehenden Zustand.')
    def process(document,number):
        return packet(f'가상 센터의 오류 문의 기록 절차\n이 설명은 {document} 처리 오류를 기록하는 방법입니다. 먼저 화면에 보이는 {number}를 적어 둡니다. 나중에 담당자가 기록을 찾는 데 필요하기 때문입니다. 내용을 확인한 다음에 복사본을 저장합니다. 저장하고 나면 목록에서 복사본이 보이는지 확인합니다. 직원에게 기록을 전달하되 오류 원인이나 승인 결과가 미상이라면 그대로 미상이라고 씁니다. 별도로 시설 상태를 기록할 때, "직원이 창문을 열었습니다"는 행동, "창문이 열렸습니다"는 변화, "창문이 열려 있습니다"는 결과 상태를 나타냅니다. 마지막 문장만으로 누가 열었는지는 알 수 없습니다.',[
            choice('purpose',loc('번호를 적는 이유는?', 'Why is the number recorded?', 'Warum wird die Nummer notiert?'),['나중에 담당자가 기록을 찾도록','기록만으로 승인 효력을 만들도록'],process_help),
            choice('order',loc('복사본 저장 전에 하는 일은?', 'What happens before saving a copy?', 'Was geschieht vor dem Speichern einer Kopie?'),['내용 확인','환불 확정'],process_help),
            choice('unknown',loc('원인이 미상이면 어떻게 기록해요?', 'How is an unknown cause recorded?', 'Wie wird eine unbekannte Ursache dokumentiert?'),['미상으로 남김','가능성 하나를 확정 원인으로 씀'],process_help),
            choice('state',loc('창문이 열려 있습니다에서 확인되는 것은?', 'What does 창문이 열려 있습니다 establish?', 'Was besagt 창문이 열려 있습니다?'),['열린 상태이며 행위자는 미상','반드시 문의 담당자가 열었다는 사실'],process_help),
        ])
    tasks.append(task('KP10','reading:02','reading',loc('문의 기록 절차와 결과 상태','Recording an enquiry and identifying resulting states','Eine Anfrage dokumentieren und Zustände erkennen'),process_help,
      process('수강 신청','신청 번호'),process('공간 예약','예약 번호')))
    writing_help=loc('가상 사실을 시간 순서·조치·결과로 연결한 공적 기록을 쓰세요. 비용·번호·출처를 정확히 보존하고 확인되지 않은 원인·승인·환불은 단정하지 마세요. 이어 같은 사건을 1인칭 회고로 쓰되 사실과 감정·해석을 구별하세요. 두 글을 비교해 문체와 누락을 고치세요. 전체 글의 의미는 미채점입니다.',
      'Write a formal record linking the fictional sequence, actions and results. Preserve costs, numbers and sources; do not assert an unconfirmed cause, approval or refund. Then retell the event in the first person, separating facts from feelings and interpretation. Compare and revise both texts; their full meaning remains unscored.',
      'Schreibe einen förmlichen Bericht mit Abfolge, Maßnahmen und Ergebnissen. Erhalte Kosten, Nummern und Quellen; behaupte keine unbestätigte Ursache, Genehmigung oder Erstattung. Erzähle den Vorfall danach in der Ich-Form und trenne Fakten von Gefühlen und Deutungen. Vergleiche und überarbeite beide Texte; ihr Gesamtinhalt bleibt unbewertet.')
    def record(place,fee,number):
        return packet(f'가상 직원 역할의 확인 자료\n{place}에서 오전 열 시 신청 화면 중단. 새 안내문은 그 직전에 게시됐지만 원인 관계 미상. 신청자가 {fee}원 결제 기록 두 개를 제시. 담당자는 중복 청구 여부 확인 중이며 환불 승인 전이라고 답함.\n나의 조치: 처음에는 메일을 보내려다가 전화함. 자료를 읽다가 동료의 안내를 듣고 중단. 나중 확인을 위해 번호 {number}를 적어 둠. 복사본 저장 완료. 현재 오류 기록을 정리하는 중. 나의 감정: 처음 당황했으나 동료의 도움으로 마음이 놓임.\n1. 하십시오체로 경위·조치·남은 확인을 기록. 2. 같은 사실을 1인칭 이야기로 재작성.',[
            free_text('report',loc('공적 기록을 쓰세요.','Write the formal record.','Schreibe den förmlichen Bericht.'),writing_help),
            free_text('story',loc('같은 사건의 회고를 쓰세요.','Write the retrospective narrative.','Schreibe den persönlichen Rückblick.'),writing_help)],'form')
    tasks.append(task('KP10','writing:01','writing',loc('같은 사건을 보고와 회고로 쓰기','One event as a report and a personal account','Ein Ereignis als Bericht und persönlicher Rückblick'),writing_help,
      record('문화센터','5000','A-17'),record('도서관','8000','B-24')))
    explaining=loc('주어진 절차를 번호 나열에 그치지 않는 설명문으로 쓰세요. 기록을 남기는 목적, 확인·저장·전달 순서와 미상 정보 처리 방법을 설명하세요. 나중을 위한 준비와 이미 완료한 일을 구별하고 자료에 없는 규칙은 만들지 마세요. 근거와 대조해 고쳐 쓰며 자유 글의 의미는 미채점입니다.',
      'Write a connected explanation of the procedure, not only a numbered list. Explain why a record is kept, the order of checking, saving and forwarding, and how unknown information is handled. Separate preparation from completion; invent no extra rules. Compare and revise; free-text meaning remains unscored.',
      'Schreibe eine zusammenhängende Erklärung des Verfahrens, nicht nur eine nummerierte Liste. Erkläre Zweck, Reihenfolge von Prüfung, Speicherung und Weitergabe sowie den Umgang mit Unbekanntem. Trenne Vorbereitung von Abschluss und erfinde keine Regeln. Vergleiche und überarbeite; der Inhalt des freien Textes bleibt unbewertet.')
    def explain(item):
        return packet(f'학습용 절차 자료: {item} 문의. 번호를 미리 적어 두기: 나중에 기록을 찾기 위해 필요. 내용 확인 완료 후 복사본 저장. 목록에서 저장 결과 확인 후 담당자에게 전달. 원인과 처리 결과를 모르면 미상으로 표기. 접수는 승인과 다름.\n새 동료에게 목적·순서·결과를 연결한 설명문을 쓰세요.',[free_text('explanation',loc('연결된 설명문을 쓰세요.','Write a connected explanation.','Schreibe eine zusammenhängende Erklärung.'),explaining)],'form')
    tasks.append(task('KP10','writing:02','writing',loc('새 동료를 위한 절차 설명','Explain the process to a new colleague','Das Verfahren für neue Kollegen erklären'),explaining,
      explain('수강 신청'),explain('공간 예약')))
    speaking_help=loc('동등한 동료에게 경위를 해요체로 설명한 뒤 담당자에게 같은 내용을 격식체로 보고하세요. 계획만 바꾼 일과 실제 중단, 같은 행위자의 -느라고 이유를 구별해요. 비용·번호·출처·미상 여부를 보존하고 미리 해 둔 조치를 말하세요. 녹음을 듣고 절 경계와 말끝을 고쳐 다시 말해요. 자유 의미와 억양은 미채점입니다.',
      'Explain the sequence politely to a peer, then formally to the responsible staff member. Distinguish changed intention, actual interruption and the same person’s reason with -느라고. Preserve costs, numbers, sources and uncertainty, and describe prior precautions. Replay and revise clause boundaries and endings. Free meaning and intonation remain unscored.',
      'Erkläre den Ablauf einer gleichgestellten Person höflich und berichte ihn danach der zuständigen Person förmlich. Trenne geänderte Absicht, tatsächliche Unterbrechung und den auf dieselbe Person bezogenen Grund mit -느라고. Erhalte Kosten, Nummern, Quellen und Ungewissheit und beschreibe die Vorbereitung. Höre zu und verbessere Satzgrenzen und Endungen. Freier Inhalt und Intonation bleiben unbewertet.')
    tasks.append(task('KP10','speaking:01','speaking',loc('문제의 경위와 준비 조치 보고','Report the sequence and earlier precautions','Ablauf und vorbereitende Maßnahmen berichten'),speaking_help,
      packet('가상 회사 동료에게 해요체, 이어 담당자에게 격식체. 나는 자료를 찾느라고 전화를 못 받음. 버스를 타려다가 걸어감. 자료를 읽다가 안내 방송으로 중단. 창구 직원: 5000원 중복 청구 여부 확인 중, 환불 미승인. 번호 A-17을 나중 확인용으로 적어 둠. 기록 복사본 저장 완료. 현재 정리 중. 동료와 의견을 나눈 일이 도움이 됨. 확인 기회는 다음 날이며 확정 결과가 아님.',[]),
      packet('가상 회사 동료에게 해요체, 이어 담당자에게 격식체. 나는 회의하느라고 점심을 못 먹음. 이메일을 보내려다가 전화함. 보고서를 쓰다가 직원 안내로 중단. 창구 직원: 8000원 중복 청구 여부 확인 중, 환불 미승인. 번호 B-24를 나중 확인용으로 적어 둠. 기록 복사본 저장 완료. 현재 정리 중. 동료와 의견을 나눈 일이 도움이 됨. 확인 기회는 다음 주이며 확정 결과가 아님.',[])))
    return tasks


if __name__=='__main__':
    write_source('KP10',kp10())
