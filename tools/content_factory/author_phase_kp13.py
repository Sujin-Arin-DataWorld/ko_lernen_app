"""KP13 sources, quotation and inference; generated material is unsigned."""
from phase_task_authoring import choice, free_text, grammar_task, loc, packet, task, write_source
from author_phase_a1_production import production


def kp13():
    rows=[
      ('G3:이라고1',loc('따옴표 안의 실제 말을 직접 인용해요. 인용한 화자와 말한 내용을 보존하고 전달자가 직접 경험한 사실로 바꾸지 않아요.','Quote the supplied words directly, preserving speaker and wording. Reporting them does not turn them into the reporter’s own observation.','Zitiere die vorgegebenen Worte direkt und erhalte Person und Wortlaut. Die Wiedergabe macht sie nicht zur eigenen Beobachtung der berichtenden Person.'),
       ('지민은 "괜찮아요"라고 말했어요.','괜찮아요는 지민이 한 말','전달자가 직접 괜찮음을 확인한 사실'),
       ('민수는 "다시 확인할게요"라고 말했어요.','민수가 다시 확인하겠다고 말함','전달자가 이미 확인을 끝냈음')),
      ('G3:-는다고3',loc('평서 내용을 간접 인용해요. 원래 말한 사람과 시점, 긍정·부정을 유지해요. 전언은 전달자의 직접 확인과 달라요.','Report a statement indirectly, preserving speaker, time and polarity. Hearsay differs from direct verification.','Gib eine Aussage indirekt wieder und erhalte Person, Zeitpunkt und Bejahung oder Verneinung. Mitgeteiltes ist nicht selbst Überprüftes.'),
       ('친구가 내일 온다고 했어요.','내일 온다는 말을 한 사람은 친구','화자가 친구의 도착을 이미 직접 봄'),
       ('담당자가 오늘은 열지 않는다고 했어요.','담당자의 말은 오늘 운영하지 않는다는 내용','오늘 운영한다는 긍정 내용')),
      ('G3:-는다고1',loc('인용된 사정을 뒤 행동의 이유로 제시해요. -다고 뒤의 술어까지 읽고 단순히 말했다로 끝나는 전언과 구별해요. 이유로 들었다는 것과 사실 검증은 별개예요.','A reported circumstance is used as the reason for the following action. Read the final predicate to distinguish this from a simple report ending in said. A cited reason is not independent verification.','Ein angeführter Umstand dient als Grund für die folgende Handlung. Lies bis zum letzten Prädikat, um dies von bloßem sagte zu unterscheiden. Ein angegebener Grund ist kein unabhängiger Nachweis.'),
       ('아이가 아프다고 아버지가 먼저 돌아갔어요.','아이의 아픔을 이유로 아버지가 먼저 돌아감','아버지가 아이에게 먼저 돌아가라고 명령함'),
       ('길이 막힌다고 동료가 일찍 출발했어요.','길이 막힌다는 사정을 이유로 일찍 출발함','동료가 늦게 출발했다고만 전함')),
      ('G3:-는다거나1',loc('여러 발언 내용을 예로 나열해요. 각각의 말을 모두가 똑같이 했다고 합치거나 한 사람의 사실로 바꾸지 않아요.','List examples of reported statements. Do not attribute every statement to everyone or turn the list into one person’s verified facts.','Zähle Beispiele berichteter Aussagen auf. Schreibe nicht jede Aussage allen zu und mache daraus keine bestätigten Tatsachen über eine einzige Person.'),
       ('친구들은 바쁘다거나 피곤하다고 했어요.','바쁘다는 말과 피곤하다는 말이 예로 나열됨','모든 친구가 두 말을 모두 했다고 확정'),
       ('참가자들은 시간이 없다거나 길을 모른다고 했어요.','서로 다른 발언 내용을 예로 열거함','참가자가 모두 이미 도착했다는 뜻')),
      ('G3:보고',loc('구어에서 누구에게 말하거나 요청했는지 나타내는 조사예요. 보는 동작의 보고와 구별하고 요청받는 사람을 바꾸지 않아요.','This colloquial particle marks the addressee of speech or a request, not the action of looking. Preserve the addressee.','Diese umgangssprachliche Partikel bezeichnet die angesprochene Person einer Äußerung oder Bitte, nicht die Handlung des Sehens. Erhalte den Adressaten.'),
       ('선생님이 저보고 발표하라고 하셨어요.','발표를 요청받은 사람은 화자','선생님이 직접 발표하겠다는 말'),
       ('담당자가 동료보고 번호를 확인하라고 했어요.','번호 확인을 요청받은 사람은 동료','동료가 담당자에게 번호 확인을 지시함')),
      ('G3:으로부터',loc('정보나 물건이 온 출처를 표시해요. 받는 사람과 보내는 출처를 바꾸지 않아요.','Mark the source of information or an item. Do not reverse source and recipient.','Kennzeichne die Herkunft von Information oder Gegenstand. Vertausche Quelle und Empfänger nicht.'),
       ('학교로부터 안내를 받았어요.','안내의 출처는 학교','안내를 학교에 보냈다는 뜻'),
       ('회사로부터 답변을 받았어요.','답변의 출처는 회사','회사가 화자에게 답변을 요청했다는 뜻')),
      ('G3:-거든2',loc('문장 끝 거든요는 상대가 모르는 배경 이유를 보충해요. 조건 연결 거든과 구별해요. 말한 이유의 출처는 화자예요.','Sentence-final 거든요 supplies background the listener may not know. Distinguish it from conditional 거든; the speaker is the source of the stated reason.','거든요 am Satzende ergänzt einen möglicherweise unbekannten Hintergrund. Unterscheide es vom bedingenden 거든; der Grund stammt von der sprechenden Person.'),
       ('오늘은 일찍 가야 해요. 약속이 있거든요.','일찍 가야 하는 배경 이유를 보충함','약속이 생기면 그때만 연락하라는 조건'),
       ('지금은 답하기 어려워요. 확인할 자료가 없거든요.','답하기 어려운 이유는 확인 자료가 없음','이미 모든 자료를 확인했다는 뜻')),
      ('G3:-잖아',loc('상대와 공유한다고 여기는 사실을 환기해요. 실제 공유 맥락이 있는지 확인하고 처음 듣는 사람에게 알고 있다고 강요하지 않아요.','Recall a fact treated as shared. Verify the shared context rather than insisting that a new listener already knows.','Erinnere an als gemeinsam bekannt dargestellte Fakten. Prüfe den gemeinsamen Kontext, statt neuen Zuhörenden Wissen zu unterstellen.'),
       ('같이 방문했던 친구에게: 우리 전에 여기 왔잖아요.','실제로 함께 방문한 기억을 환기함','처음 온 사람에게 과거 방문을 강요함'),
       ('어제 함께 읽은 동료에게: 공지에 적혀 있었잖아요.','함께 읽은 공지 내용을 환기함','아직 읽지 않은 내용을 새 사실로 확인함')),
      ('G3:-나 보다',loc('정황에서 얻은 추측을 나타내요. 근거가 있어도 확인된 사실로 바꾸지 않아요.','Express an inference from circumstances; evidence for a guess does not make it a verified fact.','Drücke eine Vermutung aus Umständen aus; ein Anhaltspunkt macht sie nicht zur bestätigten Tatsache.'),
       ('불이 꺼진 것을 보니 모두 나갔나 봐요.','꺼진 불을 근거로 추측함','사람들이 나가는 것을 직접 확인함'),
       ('가방이 없는 것을 보니 먼저 갔나 봐요.','가방 부재에 근거한 추측','떠나는 장면을 직접 봤다는 사실')),
      ('G3:-는가 보다',loc('관찰한 정황을 바탕으로 조심스럽게 추측해요. 어미 모양이 다르다고 확정 사실이 되는 것은 아니에요.','Make a cautious inference from observed circumstances; the ending does not confer certainty.','Vermute vorsichtig anhand beobachteter Umstände; die Endung verleiht keine Gewissheit.'),
       ('답장이 없는 것을 보니 바쁜가 봐요.','답장 부재를 바쁨으로 추측함','상대가 바쁘다고 직접 답함'),
       ('사람들이 나오는 것을 보니 회의가 끝났는가 봐요.','나오는 모습을 보고 종료를 추측함','회의 종료 공지를 직접 읽음')),
      ('G3:-는 모양이다',loc('눈앞의 정황을 근거로 판단해요. 모양이라는 표현만 보고 단순 외형 묘사로 읽지 않고, 근거와 추측을 따로 말해요.','Infer from an observed situation. This is not merely describing a shape; separate the clue from the inference.','Schließe aus einer beobachteten Situation. Es geht nicht bloß um eine Formbeschreibung; trenne Anzeichen und Vermutung.'),
       ('사람들이 모이는 것을 보니 행사가 시작된 모양이에요.','모이는 모습을 근거로 시작을 추측함','행사 시작을 담당자가 확인해 준 사실'),
       ('모두 우산을 펴는 것을 보니 비가 오는 모양이에요.','우산을 펴는 정황에서 비를 추측함','기상 관측 기록을 직접 검증함')),
      ('G3:-을 텐데',loc('예상되는 사정을 배경으로 뒤 제안을 해요. 예상과 확인 사실, 제안과 확정 약속을 구별해요.','Use an expected circumstance as background for a suggestion. Keep expectation separate from observation and proposal from commitment.','Nenne einen erwarteten Umstand als Hintergrund für einen Vorschlag. Trenne Erwartung und Beobachtung sowie Vorschlag und Zusage.'),
       ('오늘은 길이 막힐 텐데 일찍 출발할까요?','정체를 예상해 이른 출발을 제안함','이미 정체를 확인했고 출발도 완료함'),
       ('회의가 길어질 텐데 물을 준비할까요?','긴 회의를 예상해 준비를 제안함','회의가 끝나 물을 모두 치웠다는 뜻')),
      ('G3:-으니2',loc('판단에 사용하는 이유를 앞에 제시해요. 이유의 주체와 뒤 제안의 강도를 보존해요.','Give the reason used for a judgement, preserving its source and the force of the following suggestion.','Nenne den Grund einer Einschätzung und erhalte Quelle und Verbindlichkeit des folgenden Vorschlags.'),
       ('시간이 늦었으니 오늘은 여기까지 하죠.','늦은 시간을 이유로 마무리를 제안함','늦지 않았으니 계속하라는 뜻'),
       ('자료가 없으니 확인한 뒤에 답하죠.','자료 부재를 이유로 확인 후 답변을 제안함','자료가 없어도 확정 답변을 바로 하자는 뜻')),
    ]
    tasks=[grammar_task('KP13',i,key,h,p,a) for i,(key,h,p,a) in enumerate(rows,1)]
    prod=[
      ('G3:이라고1',('직접 인용 / 지민은 / 괜찮아요 / 라고 말하다 / 과거 해요체 / 따옴표 보존','지민은 "괜찮아요"라고 말했어요.','제가 괜찮다고 직접 확인했어요.'),('직접 인용 / 민수는 / 다시 확인할게요 / 라고 말하다 / 과거 해요체 / 따옴표 보존','민수는 "다시 확인할게요"라고 말했어요.','제가 이미 확인을 끝냈어요.')),
      ('G3:-는다고3',('간접 평서 인용 / 친구가 내일 오다 / -ㄴ다고 하다 / 과거 해요체','친구가 내일 온다고 했어요.','친구가 어제 왔다고 했어요.'),('간접 평서 인용 / 담당자가 오늘은 열지 않다 / -는다고 하다 / 과거 해요체','담당자가 오늘은 열지 않는다고 했어요.','담당자가 오늘은 연다고 했어요.')),
      ('G3:-는다고1',('인용 사정을 이유로 / 아이가 아프다 → 아버지가 먼저 돌아가다 / -다고 / 과거 해요체','아이가 아프다고 아버지가 먼저 돌아갔어요.','아버지가 아이에게 먼저 돌아가라고 했어요.'),('인용 사정을 이유로 / 길이 막히다 → 동료가 일찍 출발하다 / -ㄴ다고 / 과거 해요체','길이 막힌다고 동료가 일찍 출발했어요.','동료가 늦게 출발한다고 말했어요.')),
      ('G3:-는다거나1',('발언 예시 열거 / 친구들은 바쁘다 또는 피곤하다 / -다거나 / -다고 하다 / 과거 해요체','친구들은 바쁘다거나 피곤하다고 했어요.','모든 친구가 바쁘고 피곤하다고 각각 확인했어요.'),('발언 예시 열거 / 참가자들은 시간이 없다 또는 길을 모르다 / -다거나 / -ㄴ다고 하다 / 과거 해요체','참가자들은 시간이 없다거나 길을 모른다고 했어요.','모든 참가자가 도착을 완료했다고 했어요.')),
      ('G3:보고',('요청 상대는 나 / 선생님이 저 + 보고 / 발표하라고 하다 / 주체 높임 과거 해요체','선생님이 저보고 발표하라고 하셨어요.','제가 선생님보고 발표하라고 했어요.'),('요청 상대는 동료 / 담당자가 동료 + 보고 / 번호를 확인하라고 하다 / 과거 해요체','담당자가 동료보고 번호를 확인하라고 했어요.','동료가 담당자보고 번호를 확인하라고 했어요.')),
      ('G3:으로부터',('출처는 학교 / 학교 + 로부터 / 안내를 받다 / 과거 해요체','학교로부터 안내를 받았어요.','학교에 안내를 보냈어요.'),('출처는 회사 / 회사 + 로부터 / 답변을 받다 / 과거 해요체','회사로부터 답변을 받았어요.','회사에 답변을 보냈어요.')),
      ('G3:-거든2',('일찍 가야 하는 배경 이유 보충 / 약속이 있다 / 문장 끝 -거든요','약속이 있거든요.','약속이 있거든 연락해 주세요.'),('지금 답하기 어려운 배경 이유 보충 / 확인할 자료가 없다 / 문장 끝 -거든요','확인할 자료가 없거든요.','확인할 자료가 있거든 보내 주세요.')),
      ('G3:-잖아',('실제로 함께 방문한 친구에게 공유 기억 환기 / 우리 전에 여기 오다 / 과거 -잖아요','우리 전에 여기 왔잖아요.','우리는 전에 여기 오지 않았잖아요.'),('실제로 함께 공지를 읽은 동료에게 공유 기억 환기 / 공지에 적혀 있다 / 과거 -잖아요','공지에 적혀 있었잖아요.','공지에는 아무것도 없었잖아요.')),
      ('G3:-나 보다',('불이 꺼진 정황, 직접 보지 않음 / 모두 나가다 / 과거 -나 보다 / 해요체','모두 나갔나 봐요.','모두 나간 것을 직접 확인했어요.'),('가방이 없는 정황, 직접 보지 않음 / 먼저 가다 / 과거 -나 보다 / 해요체','먼저 갔나 봐요.','먼저 가는 것을 직접 봤어요.')),
      ('G3:-는가 보다',('답장이 없는 정황의 추측 / 바쁘다 / -ㄴ가 보다 / 해요체','바쁜가 봐요.','바쁘다고 직접 답장을 받았어요.'),('사람들이 나오는 정황의 추측 / 회의가 끝나다 / 과거 -는가 보다 / 해요체','회의가 끝났는가 봐요.','회의 종료 공지를 직접 확인했어요.')),
      ('G3:-는 모양이다',('사람들이 모이는 정황의 추측 / 행사가 시작되다 / -ㄴ 모양이다 / 해요체','행사가 시작된 모양이에요.','담당자가 행사 시작을 확인해 주었어요.'),('사람들이 우산을 펴는 정황의 추측 / 비가 오다 / -는 모양이다 / 해요체','비가 오는 모양이에요.','기상 관측 기록을 직접 확인했어요.')),
      ('G3:-을 텐데',('예상 배경 뒤 제안 / 오늘은 길이 막히다 → 일찍 출발할까요? / -ㄹ 텐데','오늘은 길이 막힐 텐데 일찍 출발할까요?','길이 막힌 것을 확인했고 이미 출발했어요.'),('예상 배경 뒤 제안 / 회의가 길어지다 → 물을 준비할까요? / -ㄹ 텐데','회의가 길어질 텐데 물을 준비할까요?','회의가 끝나 물을 모두 치웠어요.')),
      ('G3:-으니2',('이유 뒤 제안 / 시간이 늦다 → 오늘은 여기까지 하죠 / 과거 -으니','시간이 늦었으니 오늘은 여기까지 하죠.','시간이 늦지 않았으니 계속하죠.'),('이유 뒤 제안 / 자료가 없다 → 확인한 뒤에 답하죠 / -으니','자료가 없으니 확인한 뒤에 답하죠.','자료가 없으니 확정 답변을 바로 하죠.')),
    ]
    tasks+=production('KP13',tasks,prod)
    h=loc('발언자·전달자·직접 관찰을 나눠 기록하세요. 같은 화면을 봐도 원인이나 이후 결과는 추측일 수 있어요. 상대가 함께 확인하지 않은 내용을 -잖아요로 공유 사실처럼 만들지 마세요.',
      'Record the original speaker, messenger and direct observation separately. Even a shared screen observation may leave its cause or outcome uncertain. Do not use -잖아요 to imply shared knowledge that was never established.',
      'Notiere ursprüngliche sprechende Person, übermittelnde Person und eigene Beobachtung getrennt. Auch bei gemeinsam gesehener Bildschirmanzeige können Ursache und Folge ungewiss bleiben. Stelle mit -잖아요 kein gemeinsames Wissen her, das nicht belegt ist.')
    def dialogue(name,place,day,nextday):
        return packet(f'오늘은 {day}이라고 정한 가상 장면입니다.\n가: {place}로부터 안내를 받았어요. 담당자는 내일 접수 화면을 연다고 했어요.\n나: 저는 {name} 씨에게서 들었어요. {name} 씨는 "다시 확인할게요"라고 말했어요. 아직 확인 결과는 못 받았어요.\n가: 지금 화면이 비어 있네요. 점검하는 모양이에요. 원인은 아직 모릅니다.\n나: 화면이 비어 있는 것은 저도 봤어요. 하지만 점검인지 오류인지는 확인해야 해요. 우리 어제 같이 공지를 읽었잖아요. 거기에는 내일, 그러니까 {nextday}이라고 적혀 있었어요.\n가: 제가 담당자에게 확인해 볼게요. 누군가 비용도 바뀐다고 했다는데, 누가 한 말인지는 모르겠어요.',[
          choice('origin',loc('접수 예정 안내의 원래 출처는?', 'What is the original source of the planned opening?', 'Von wem stammt die ursprüngliche Ankündigung?'),[place+' 담당자',name+'의 확인 결과'],h),
          choice('commitment',loc('다시 확인하겠다고 말한 사람은?', 'Who said they would check again?', 'Wer sagte eine erneute Prüfung zu?'),[name,'나가 이미 확인을 끝냈다고 함'],h),
          choice('observation',loc('두 사람이 직접 본 것은?', 'What did both people directly observe?', 'Was haben beide selbst beobachtet?'),['화면이 비어 있음','점검이 오류 원인이라는 사실'],h),
          choice('time',loc('안내의 내일은 언제예요?', 'Which day does tomorrow in the notice mean?', 'Welcher Tag ist mit morgen im Hinweis gemeint?'),[nextday,day],h),
          choice('unknown',loc('비용 변경 발언의 출처는?', 'Who originated the cost-change statement?', 'Von wem stammt die Aussage zur Kostenänderung?'),['미상',place+' 담당자로 확정'],h),
        ],'audio')
    tasks.append(task('KP13','listening:01','listening',loc('두 출처의 소식과 화면 관찰','Two news sources and a screen observation','Zwei Nachrichtenquellen und eine Bildschirmbeobachtung'),h,
      dialogue('지민','학교','월요일','화요일'),dialogue('민수','문화센터','수요일','목요일')))
    source_help=loc('기사의 직접 인용·간접 인용·기자의 판단을 분리하세요. 예정은 완료가 아니며, 관찰한 이용자 수나 댓글만으로 제도 효과나 전체 소비 행동을 확정하지 않아요.',
      'Separate direct quotation, reported speech and the reporter’s judgement. Plans are not completed actions; user counts or comments alone do not establish a scheme’s effects or everyone’s spending behaviour.',
      'Trenne direktes Zitat, indirekte Rede und journalistische Einschätzung. Planung ist kein Abschluss; Nutzerzahlen oder Kommentare allein beweisen weder die Wirkung einer Regelung noch das Konsumverhalten aller.')
    def article(place,day,count):
        return packet(f'학습용 가상 기사 | {place} 새 접수 화면 안내\n담당자는 "{day}에 새 화면을 열 예정입니다"라고 말했다. 모임 진행자는 참가자들이 접속 방법을 궁금해한다고 전했다. 기자가 오늘 직접 본 안내 창구에는 {count}명이 기다리고 있었다. 기자는 새 제도에 관심이 높아진 모양이라고 해석했지만, 대기 이유는 조사하지 않았다. 비용 변경을 주장한 온라인 댓글의 작성자와 근거는 확인하지 못했다. 담당자는 현재 요금이 그대로이며 향후 변경 여부는 정해지지 않았다고 답했다.',[
          choice('direct',loc('담당자의 직접 인용 내용은?', 'What is directly quoted from the staff member?', 'Welche Aussage der zuständigen Person wird direkt zitiert?'),[day+'에 새 화면을 열 예정','이미 새 화면을 열고 운영 완료'],source_help),
          choice('reported',loc('참가자의 궁금증을 전한 사람은?', 'Who relayed participants’ questions?', 'Wer gab die Fragen der Teilnehmenden weiter?'),['모임 진행자','기자가 모든 참가자를 직접 면담함'],source_help),
          choice('inference',loc('제도에 관심이 높아졌다는 판단의 한계는?', 'What limits the claim of increased interest?', 'Was begrenzt die Aussage über gestiegenes Interesse?'),['대기 이유를 조사하지 않은 기자의 해석','모든 대기자가 이유를 직접 확인해 줌'],source_help),
          choice('cost',loc('요금에 대해 보존할 내용은?', 'What should be preserved about the fee?', 'Welche Angaben zur Gebühr müssen erhalten bleiben?'),['현재 그대로, 향후 변경 미정','댓글 때문에 인상이 이미 확정'],source_help),
        ])
    tasks.append(task('KP13','reading:01','reading',loc('기사의 인용과 작성자 판단','Quotation and judgement in a news article','Zitat und Einschätzung in einer Nachricht'),source_help,
      article('한빛센터','화요일','네'),article('새봄도서관','목요일','여섯')))
    mail_help=loc('전달 메일에서 원문 작성자와 전달자를 구분하세요. 원문의 요청을 전달자의 새 명령으로 바꾸지 말고, 기한·자료 수신자·미확인 항목을 보존해요.',
      'Distinguish the author of the forwarded message from its sender. Do not turn the original request into a new command from the messenger; preserve deadline, recipient and unresolved points.',
      'Unterscheide Verfasser der Ursprungsnachricht und weiterleitende Person. Mache aus der ursprünglichen Bitte keinen neuen Befehl der übermittelnden Person; erhalte Frist, Empfänger und offene Punkte.')
    def mail(sender,day,number):
        return packet(f'학습용 가상 전달 이메일\n보낸 사람: {sender}, 모임 진행자\n받는 사람: 준비 모임 동료\n제목: 담당자 요청 전달 및 확인 필요 사항\n아래는 안내 담당자로부터 받은 원문입니다.\n[원문 시작] {day}까지 신청 번호 {number}와 자료 제목을 담당자 메일로 보내 주시기 바랍니다. 파일 비밀번호는 이 메일에 포함하지 마십시오. 공개 허가는 검토 후 별도로 안내하겠습니다. [원문 끝]\n저는 원문을 전달하며 제출을 도울 예정입니다. 화면이 비어 있어 점검 중인가 싶지만 직접 확인하지 못했습니다. 요금이 바뀐다는 댓글은 출처가 불분명합니다. 모르는 부분은 담당자에게 확인한 뒤 다시 알려 드리겠습니다.',[
          choice('original',loc('번호 제출 요청의 원문 작성자는?', 'Who authored the request for the number?', 'Wer verfasste die ursprüngliche Bitte um die Nummer?'),['안내 담당자',sender],mail_help),
          choice('recipient',loc('번호와 제목을 어디로 보내야 해요?', 'Where should the number and title be sent?', 'Wohin sollen Nummer und Titel gesendet werden?'),['담당자 메일',sender+'의 공개 댓글'],mail_help),
          choice('exclude',loc('메일에 포함하지 말아야 할 것은?', 'What must not be included in the email?', 'Was darf nicht in die E-Mail aufgenommen werden?'),['파일 비밀번호','자료 제목'],mail_help),
          choice('uncertain',loc('점검 중이라는 말은?', 'What is the status of the maintenance statement?', 'Welchen Status hat die Aussage über Wartung?'),['전달자의 미확인 추측','담당자가 확인한 직접 인용'],mail_help),
        ])
    tasks.append(task('KP13','reading:02','reading',loc('전달 메일의 원문과 덧붙인 추측','An original email and an added inference','Ursprungsmail und ergänzte Vermutung'),mail_help,
      mail('하린','화요일','A-17'),mail('도윤','목요일','B-24')))
    rubric=loc('두 출처를 밝힌 짧은 요약을 쓰세요. 직접 인용과 간접 인용, 작성자의 관찰·추측을 구별하고 시간 기준을 유지하세요. 출처 미상이나 결정 전인 부분은 남겨 두세요. 이어 새 동료에게 확인 절차를 연결된 설명문으로 써 주세요. 전언을 직접 확인으로 바꾸지 않고 고쳐 쓰세요. 자유 의미·요약의 충실성은 미채점입니다.',
      'Write a short summary naming both sources. Separate direct and indirect quotation from your observation and inference, preserving the time reference. Retain unknown sources and undecided matters. Then write a connected explanation of how a new colleague should verify them. Revise without turning hearsay into observation. Free meaning and summary fidelity remain unscored.',
      'Schreibe eine kurze Zusammenfassung mit beiden Quellen. Trenne direktes und indirektes Zitat von eigener Beobachtung und Vermutung und erhalte den Zeitbezug. Lasse unbekannte Quellen und offene Entscheidungen erkennbar. Erkläre danach zusammenhängend, wie ein neues Mitglied die Angaben prüfen soll. Überarbeite, ohne Hörensagen zu Beobachtung zu machen. Freier Inhalt und Zusammenfassungsqualität bleiben unbewertet.')
    def facts(place,name,today,tomorrow,number):
        return f'가상 자료: 오늘은 {today}. 출처 1: {place} 담당자는 내일({tomorrow}) 접수 화면을 열 예정이라고 말함. 현재 요금 그대로, 향후 변경 미정. 출처 2: {name}은 "다시 확인할게요"라고 말함. 아직 확인 결과 없음.\n나와 동료가 직접 본 것: 지금 빈 화면. 점검 원인은 추측일 뿐. 출처 모르는 댓글에 요금 변경 주장. 우리 둘은 어제 원문 공지를 같이 읽었지만 새 회원은 읽지 않음.\n담당자 요청: {tomorrow}까지 번호 {number}와 제목을 담당자 메일로 보내기. 비밀번호는 포함하지 않기. 공개 허가는 별도 검토 후. 확인 절차: 원문과 출처 구분 → 담당자에게 미상 정보 문의 → 확인된 답만 출처와 함께 전달.'
    p=facts('학교','지민','월요일','화요일','A-17')
    a=facts('문화센터','민수','수요일','목요일','B-24')
    tasks.append(task('KP13','writing:01','writing',loc('두 출처 요약과 확인 절차 설명','Summarise two sources and explain verification','Zwei Quellen zusammenfassen und die Prüfung erklären'),rubric,
      packet(p,[free_text('summary',loc('출처와 미확인 부분을 남긴 요약을 쓰세요.','Summarise while retaining sources and uncertainty.','Fasse mit Quellen und offenen Punkten zusammen.'),rubric),free_text('explanation',loc('새 동료를 위한 확인 절차 설명문을 쓰세요.','Explain the verification process to a new colleague.','Erkläre einem neuen Mitglied den Prüfablauf.'),rubric)],'form'),
      packet(a,[free_text('summary',loc('출처와 미확인 부분을 남긴 요약을 쓰세요.','Summarise while retaining sources and uncertainty.','Fasse mit Quellen und offenen Punkten zusammen.'),rubric),free_text('explanation',loc('새 동료를 위한 확인 절차 설명문을 쓰세요.','Explain the verification process to a new colleague.','Erkläre einem neuen Mitglied den Prüfablauf.'),rubric)],'form')))
    speech=loc('동료에게 해요체로 두 출처의 소식을 전달하고 직접 본 사실과 추측을 나누세요. 이어 반말에 합의한 친구에게 같은 정보를 다시 말하세요. 간다고 했어요와 간다고 서둘렀어요의 후행 술어까지 구별하고, 함께 확인하지 않은 새 회원에게 -잖아로 공유 지식을 강요하지 마세요. 녹음을 듣고 인용절·이유절 휴지를 고쳐요. 의미·억양은 미채점입니다.',
      'Relay both sources politely to a colleague, separating observation and inference. Then restate the same facts to a friend with agreed casual speech. Distinguish 간다고 했어요 from 간다고 서둘렀어요 through the final predicate; do not impose shared knowledge with -잖아 on a new member. Replay and revise quotation and reason-clause pauses. Meaning and intonation remain unscored.',
      'Gib beide Quellen einer gleichgestellten Person höflich wieder und trenne Beobachtung von Vermutung. Formuliere dieselben Fakten danach für eine befreundete Person mit vereinbarter vertraulicher Anrede um. Unterscheide 간다고 했어요 und 간다고 서둘렀어요 anhand des letzten Prädikats; unterstelle einem neuen Mitglied mit -잖아 kein gemeinsames Wissen. Höre zu und verbessere Pausen bei Zitaten und Gründen. Inhalt und Intonation bleiben unbewertet.')
    tasks.append(task('KP13','speaking:01','speaking',loc('출처와 확신을 보존해 전달','Relay information with sources and uncertainty intact','Information mit Quellen und Ungewissheit weitergeben'),speech,
      packet(p+'\n발음·구조 비교: 지민이 간다고 했어요. / 지민은 길이 막힌다고 서둘렀어요. 각 문장의 인용 내용과 뒤 행동을 구별해 설명하세요.',[]),
      packet(a+'\n발음·구조 비교: 민수가 간다고 했어요. / 민수는 길이 막힌다고 서둘렀어요. 각 문장의 인용 내용과 뒤 행동을 구별해 설명하세요.',[])))
    briefing=loc('격식 있는 짧은 발표로 요점·출처별 근거·관찰·한계를 정리하세요. 요금이나 제도 효과를 묻는 청중에게 확인된 내용만 말하고 미정·미상은 확인 과제로 남겨요. 같은 정보를 짧게 다시 말한 뒤 녹음을 들어 출처 경계와 말끝을 고치세요. 전체 의미와 발표 능력은 미채점입니다.',
      'Give a short formal briefing with main point, source-specific evidence, observation and limits. Answer questions about fees or the scheme’s effects using only confirmed information; leave undecided and unknown matters for verification. Restate briefly, replay and revise source boundaries and endings. Full meaning and presentation ability remain unscored.',
      'Gib ein kurzes förmliches Briefing mit Hauptaussage, Belegen je Quelle, Beobachtung und Grenzen. Beantworte Fragen zu Gebühren oder zur Wirkung der Regelung nur mit bestätigten Angaben; lasse Unentschiedenes und Unbekanntes zur Prüfung offen. Fasse kürzer zusammen, höre zu und verbessere Quellengrenzen und Endungen. Gesamtinhalt und Präsentationsfähigkeit bleiben unbewertet.')
    tasks.append(task('KP13','speaking:02','speaking',loc('출처별 소식을 청중에게 요약 발표','Brief an audience on source-specific news','Nachrichten nach Quellen geordnet vortragen'),briefing,
      packet(p+'\n청중 질문: 요금이 인상됐습니까? 빈 화면이 새 제도의 효과를 보여 줍니까? 지민이 이미 확인했습니까?',[]),
      packet(a+'\n청중 질문: 요금이 인상됐습니까? 빈 화면이 새 제도의 효과를 보여 줍니까? 민수가 이미 확인했습니까?',[])))
    return tasks


if __name__=='__main__':
    write_source('KP13',kp13())
