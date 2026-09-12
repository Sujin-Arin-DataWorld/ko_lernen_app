"""KP09 remembered experience, intimate response and interview sources."""
from phase_task_authoring import choice, free_text, grammar_task, loc, packet, task, write_source
from author_phase_a1_production import production


def kp09():
    rows=[
      ('G3:-는다',loc('동사의 -ㄴ다·-는다는 여기서 독백·서술의 평서형이에요. 미래 약속이나 청유로 바꾸지 않아요. 가까운 사이에서도 모든 상황에 쓰는 말끝은 아니에요.', 'Here, verb endings -ㄴ다/-는다 mark a statement in narration or self-talk, not a promise or suggestion. They are not appropriate in every close relationship or situation.', 'Hier kennzeichnen -ㄴ다/-는다 bei Verben eine Aussage in Erzählung oder Selbstgespräch, keine Zusage oder Aufforderung. Sie passen auch unter Vertrauten nicht in jede Situation.'),('나는 지금 옛 사진을 본다.','화자는 지금 사진을 보는 일을 서술해요.','화자가 상대에게 사진을 보라고 명령해요.'),('나는 이제 집에 간다.','화자는 자기의 현재 행동을 서술해요.','화자가 상대에게 같이 가자고 제안해요.')),
      ('G3:-니2',loc('여기의 -니는 친밀한 상대에게 묻는 의문 말끝이에요. 이유 연결 -니와 구별하고 합의된 관계에서 사용해요.', 'Here, -니 ends a question to a familiar person. Distinguish it from a causal connective and use it only in the stated relationship.', 'Hier beendet -니 eine Frage an eine vertraute Person. Unterscheide es von einer kausalen Verbindung und beachte die vorgegebene Beziehung.'),('반말에 합의한 친구에게: 그때 어디에 살았니?','그때 살던 곳을 물어요.','거기에 살았기 때문에라는 이유를 말해요.'),('반말에 합의한 친구에게: 요즘 무엇을 준비하니?','현재 준비하는 일을 물어요.','준비가 끝났다고 단정해요.')),
      ('G3:-자3',loc('문장 끝의 -자는 함께할 행동을 제안해요. 이때 행동 주체는 듣는 사람만이 아니에요. 시간 연결 -자와 구별해요.', 'Sentence-final -자 proposes a shared action. It is not an order only to the listener and differs from the temporal connective -자.', 'Am Satzende schlägt -자 eine gemeinsame Handlung vor. Es ist keine Anweisung nur an die zuhörende Person und unterscheidet sich von der zeitlichen Verbindung -자.'),('친한 친구에게: 옛 사진을 같이 보자.','화자와 친구가 함께 사진을 보자는 제안이에요.','친구 혼자 사진을 보라는 지시예요.'),('친한 친구에게: 조금 쉬었다가 다시 하자.','함께 쉰 뒤 다시 하자는 제안이에요.','상대만 쉬고 화자는 계속하겠다는 뜻이에요.')),
      ('G3:-는구나',loc('-는구나·-구나는 새로 알거나 느낀 사실에 대한 반응이에요. 질문이 아니며, 친구가 말하지 않은 감정을 마음대로 만들어 넣지 않아요.', '-는구나/-구나 responds to a new realization. It is not a question and does not license inventing feelings the other person never expressed.', '-는구나/-구나 reagiert auf eine neue Erkenntnis. Es ist keine Frage und erlaubt nicht, der anderen Person ungenannte Gefühle zuzuschreiben.'),('가: 그때 혼자라서 많이 외로웠어.\n나: 많이 외로웠구나.','친구가 말한 외로움을 받아들이는 반응이에요.','친구가 외롭지 않았다고 반박해요.'),('가: 요즘 새 일을 배우느라 바빠.\n나: 새 일을 배우는구나.','지금 하는 일을 새로 알고 반응해요.','일을 이미 다 배웠다고 말해요.')),
      ('G3:-던-',loc('-던은 경험하거나 반복하던 대상을 회상해 꾸며요. 문맥 없이 항상 완료·미완료 한쪽으로만 정하지 않아요. 이 과제에서는 예전에 반복한 경험을 확인해요.', '-던 recalls an experienced or repeated situation. It does not always mark only completion or non-completion. These examples establish a repeated past experience explicitly.', '-던 erinnert an Erlebtes oder Wiederholtes. Es kennzeichnet nicht immer nur Abschluss oder Unvollständigkeit. In diesen Beispielen ist eine wiederholte frühere Erfahrung ausdrücklich angegeben.'),('학생 때 매일 가던 카페를 다시 찾았다.','예전에 반복해서 갔던 카페예요.','내일 처음 갈 카페예요.'),('어릴 때 살던 집을 찾아갔다.','어린 시절 살았던 집을 회상해요.','앞으로 처음 살 집을 소개해요.')),
      ('G3:-던데2',loc('여기서는 자신이 직접 경험한 일에 대한 감탄·인상을 문장 끝 -던데(요)로 회상해요. 전해 들은 소문과 구별하며 모든 -던데 용법을 같은 감탄으로 보지 않아요.', 'Here, sentence-final -던데(요) recalls an impression from direct experience. Distinguish it from hearsay; not every use of -던데 has this exclamatory function.', 'Hier erinnert -던데(요) am Satzende an einen Eindruck aus eigener Erfahrung. Unterscheide ihn vom Hörensagen; nicht jede Verwendung von -던데 ist eine solche Ausrufefunktion.'),('어제 직접 가 봤어요. 그 식당 음식이 정말 맛있던데요!','직접 먹어 본 인상을 회상해요.','먹어 보지 않고 소문만 전해요.'),('지난주에 직접 봤어. 그 공연 정말 멋있던데!','직접 본 공연의 인상을 말해요.','아직 보지 않은 공연의 결과를 확정해요.')),
      ('G3:아1',loc('이름 뒤 -아·-야는 가까운 상대를 부르는 호격 조사예요. 받침 뒤에는 아, 모음 뒤에는 야를 써요. 감탄사 아와 구별하고 처음 만난 사람에게 임의로 쓰지 않아요.', 'After a name, -아/-야 addresses a familiar person: 아 after a final consonant, 야 after a vowel. This is not the interjection 아, and familiarity must be established.', 'Nach einem Namen spricht -아/-야 eine vertraute Person an: 아 nach Endkonsonant, 야 nach Vokal. Das ist nicht der Ausruf 아; die Vertrautheit muss feststehen.'),('지민아, 그 사진 기억나?','지민을 직접 불러 말을 걸어요.','지민의 말을 다른 사람에게 인용해요.'),('민수야, 잠깐 이야기할까?','민수를 직접 부르는 말이에요.','민수라는 장소로 가자는 말이에요.')),
      ('G3:요1',loc('조사 요는 저요·어제요처럼 짧은 응답에도 공손함을 더해요. 누구인지·언제인지 같은 정보는 요가 아니라 앞말에서 읽어요.', 'The particle 요 adds politeness to short replies such as 저요 or 어제요. The preceding word supplies the person or time information.', 'Die Partikel 요 macht auch kurze Antworten wie 저요 oder 어제요 höflich. Wer oder wann gemeint ist, steht im Wort davor.'),('교사: 누가 먼저 말할래요?\n학생: 저요.','학생이 자신을 가리키며 공손하게 답해요.','학생이 교사를 가리켜 명령해요.'),('진행자: 언제 도착했어요?\n참가자: 어제요.','도착 시각 정보는 어제이고 요는 공손함을 더해요.','요가 내일이라는 시간을 뜻해요.')),
      ('G3:-었었-',loc('-았/었었-은 현재와 달라진 이전 상황을 회상하거나 더 이전의 과거를 드러낼 수 있어요. 여기서는 지금의 상태를 문맥에 따로 제시해 대비해요. 영어 과거완료와 자동으로 같다고 보지 않아요.', '-았/었었- can recall an earlier situation that has changed or mark a more remote past. These examples state the current contrast explicitly; it is not automatically equivalent to English past perfect.', '-았/었었- kann an eine inzwischen veränderte Lage erinnern oder eine weiter zurückliegende Vergangenheit markieren. Der heutige Gegensatz steht hier ausdrücklich im Kontext; es ist nicht automatisch das Plusquamperfekt.'),('예전에는 이 동네에 살았었어. 지금은 다른 도시에서 살아.','예전 거주지와 현재 거주지가 달라요.','지금도 같은 동네에 산다고 확정해요.'),('한때 주말마다 수영했었어. 요즘은 걷기만 해.','과거의 수영 습관과 현재의 걷기를 대비해요.','현재도 주말마다 수영한다고 말해요.')),
      ('G3:-는 중이다',loc('-는 중이다는 기준 시점에 과정이 진행 중임을 나타내요. 시작할 희망이나 완료 결과로 바꾸지 않아요.', '-는 중이다 marks a process in progress at the reference time, not a wish to start or a completed result.', '-는 중이다 bezeichnet einen zum Bezugszeitpunkt laufenden Vorgang, keinen bloßen Wunsch und kein abgeschlossenes Ergebnis.'),('지금 이사 준비를 하는 중이야.','이사 준비가 지금 진행 중이에요.','이사를 이미 끝냈어요.'),('지금 발표 자료를 고치는 중이야.','자료 수정이 지금 진행 중이에요.','발표가 이미 끝났어요.')),
      ('G3:-고 싶어 하다',loc('-고 싶어 하다는 다른 사람의 바람을 관찰·전달할 때 써요. 원하는 행동을 이미 했다고 바꾸지 않고, 화자 자신의 바람과 구별해요.', '-고 싶어 하다 reports another person’s wish. A wish is not a completed action and must not be reassigned to the speaker.', '-고 싶어 하다 gibt den Wunsch einer anderen Person wieder. Ein Wunsch ist keine vollendete Handlung und darf nicht der sprechenden Person zugeschrieben werden.'),('동생은 제주도에 가고 싶어 해. 아직 간 적은 없어.','제주도 여행은 동생의 아직 실현되지 않은 바람이에요.','화자가 이미 제주도에 다녀왔어요.'),('친구는 그 공연을 보고 싶어 해. 표는 아직 없어.','친구가 공연 관람을 원하지만 확정되지 않았어요.','친구가 공연을 이미 봤어요.')),
    ]
    tasks=[grammar_task('KP09',i,key,teaching,p,a) for i,(key,teaching,p,a) in enumerate(rows,1)]
    production_rows=[
      ('G3:-는다',('독백의 평서문: 나는 / 지금 / 옛 사진을 보다 / -ㄴ다·-는다','나는 지금 옛 사진을 본다.','옛 사진을 같이 보자.'),('독백의 평서문: 나는 / 이제 / 집에 가다 / -ㄴ다·-는다','나는 이제 집에 간다.','집에 같이 가자.')),
      ('G3:-니2',('반말에 합의한 친구에게 질문: 그때 / 어디에 살다 / 과거형 -니?','그때 어디에 살았니?','그때 거기에 살았으니.'),('반말에 합의한 친구에게 질문: 요즘 / 무엇을 준비하다 / -니?','요즘 무엇을 준비하니?','요즘 그것을 준비하자.')),
      ('G3:-자3',('친한 동료와 공동 제안: 옛 사진을 같이 보다 / -자','옛 사진을 같이 보자.','옛 사진을 혼자 봐.'),('친한 동료와 공동 제안: 조금 쉬었다가 다시 하다 / -자','조금 쉬었다가 다시 하자.','너만 쉬었다가 다시 해.')),
      ('G3:-는구나',('친구가 그때 많이 외로웠다고 말했음 / 많이 외롭다 / 과거형 -구나로 호응','많이 외로웠구나.','많이 외롭지 않았구나.'),('친구가 요즘 새 일을 배운다고 말했음 / 새 일을 배우다 / -는구나로 호응','새 일을 배우는구나.','새 일을 다 배웠구나.')),
      ('G3:-던-',('과거 반복 회상: 학생 때 매일 가다 / 카페 / 다시 찾다 / -던 / 과거 해요체','학생 때 매일 가던 카페를 다시 찾았어요.','내일 처음 갈 카페를 찾았어요.'),('과거 거주 회상: 어릴 때 살다 / 집 / 찾아가다 / -던 / 과거 해요체','어릴 때 살던 집을 찾아갔어요.','앞으로 살 집을 찾아갔어요.')),
      ('G3:-던데2',('직접 먹어 본 긍정적 인상 회상 / 그 식당 음식 / 정말 맛있다 / 문장 끝 -던데요!','그 식당 음식이 정말 맛있던데요!','그 식당 음식이 맛있다는 소문만 들었어요.'),('직접 본 긍정적 인상 회상 / 그 공연 / 정말 멋있다 / 문장 끝 -던데요!','그 공연이 정말 멋있던데요!','그 공연이 멋있다는 소문만 들었어요.')),
      ('G3:아1',('가까운 친구 지민을 이름으로 부른 뒤 잠깐 이야기할까? / 호격 조사','지민아, 잠깐 이야기할까?','지민야, 잠깐 이야기할까?'),('가까운 친구 민수를 이름으로 부른 뒤 잠깐 이야기할까? / 호격 조사','민수야, 잠깐 이야기할까?','민수아, 잠깐 이야기할까?')),
      ('G3:요1',('교사의 누가 할래요?에 나라고 짧고 공손하게 답하기 / 저 + 요','저요.','너요.'),('진행자의 언제 도착했어요?에 어제라고 짧고 공손하게 답하기 / 어제 + 요','어제요.','내일요.')),
      ('G3:-었었-',('지금은 다른 도시에 삶 / 예전에는 이 동네에 살다 / -았었- / 해요체','예전에는 이 동네에 살았었어요.','지금도 이 동네에 살아요.'),('지금은 걷기만 함 / 예전에는 주말마다 수영하다 / -였었- / 해요체','예전에는 주말마다 수영했었어요.','지금도 주말마다 수영해요.')),
      ('G3:-는 중이다',('기준 시점: 지금 / 이사 준비를 하다 / -는 중이다 / 해요체','지금 이사 준비를 하는 중이에요.','이사 준비를 다 끝냈어요.'),('기준 시점: 지금 / 발표 자료를 고치다 / -는 중이다 / 해요체','지금 발표 자료를 고치는 중이에요.','발표 자료를 다 고쳤어요.')),
      ('G3:-고 싶어 하다',('다른 사람의 아직 실현되지 않은 바람 / 동생 / 제주도에 가다 / -고 싶어 하다 / 해요체','동생은 제주도에 가고 싶어 해요.','동생은 제주도에 갔어요.'),('다른 사람의 아직 실현되지 않은 바람 / 친구 / 그 공연을 보다 / -고 싶어 하다 / 해요체','친구는 그 공연을 보고 싶어 해요.','친구는 그 공연을 봤어요.')),
    ]
    tasks += production('KP09',tasks,production_rows)
    teaching=loc('누가 직접 겪었는지, 예전과 지금이 어떻게 다른지 확인하세요. 진행 중인 일과 아직 실현되지 않은 바람을 나눠 들어요. 친구가 말한 감정에 호응하되 말하지 않은 감정을 단정하지 마세요. 회상 어미를 과장하지 않고 의미 단위로 쉬어 들어 보세요.',
        'Check who experienced the event and how past and present differ. Separate an ongoing activity from an unrealised wish. Respond to the feeling the friend actually expressed. Listen for pauses between meaning units without overemphasising retrospective endings.',
        'Prüfe, wer etwas selbst erlebt hat und was früher anders war als heute. Unterscheide laufende Handlung und noch unerfüllten Wunsch. Gehe auf das tatsächlich genannte Gefühl ein. Achte auf Pausen zwischen Sinneinheiten, ohne die Erinnerungsendungen übermäßig zu betonen.')
    def dialogue(name,old,current,activity,wish):
        return packet(f'가: {name}, 그때 어디에 살았니?\n나: 예전에는 {old}에 살았었어. 지금은 {current}에서 살아. 그때 매일 가던 도서관이 생각나. 혼자 지낼 때는 좀 외로웠어.\n가: 많이 외로웠구나. 지금은 어때?\n나: 여기서는 친구들과 자주 만나. 지금은 {activity} 중이야. 동생은 {wish} 싶어 해. 아직 한 적은 없어.\n가: 그렇구나. 준비가 끝나면 같이 사진을 보자.',[
            choice('past',loc('예전에 살던 곳은?', 'Where did the speaker live before?', 'Wo wohnte die Person früher?'),[old,current],teaching),
            choice('ongoing',loc('지금 진행 중인 일은?', 'What is happening now?', 'Was läuft gerade?'),[activity+' 중','동생의 바람이 이미 실현됨'],teaching),
            choice('wish',loc('동생에 대해 확인된 내용은?', 'What is established about the sibling?', 'Was steht über das Geschwister fest?'),[wish+' 싶어 하지만 아직 경험하지 않음','원하던 일을 이미 여러 번 함'],teaching),
            choice('response',loc('가가 외로웠구나라고 한 근거는?', 'What supports the response about loneliness?', 'Worauf beruht die Reaktion auf die Einsamkeit?'),['나가 혼자 지낼 때 외로웠다고 말함','가가 현재 상황을 보고 임의로 단정함'],teaching),
        ],'audio')
    tasks.append(task('KP09','listening:01','listening',loc('옛집의 기억과 지금의 생활','A former home and life now','Früheres Zuhause und heutiger Alltag'),teaching,
        dialogue('지민아','부산','서울','이사 준비를 하는','제주도에 가고'),dialogue('민수야','대구','인천','발표 자료를 고치는','도예를 배우고')))
    lecture_help=loc('회고 강연의 시간 순서를 정리하고 화자의 직접 경험과 다른 사람의 바람을 구별하세요. 인용된 말이 누구의 말인지 맥락에서 확인해요.',
        'Reconstruct the timeline of the retrospective talk. Distinguish the speaker’s experience from another person’s wish and identify who said the quoted words.',
        'Ordne den Rückblick zeitlich. Unterscheide eigene Erlebnisse der sprechenden Person vom Wunsch einer anderen und prüfe, von wem zitierte Worte stammen.')
    def talk(year,place,work):
        return packet(f'새 회원을 위한 짧은 경험 발표입니다. 저는 {year}년에 {place}에서 {work}을 처음 시작했었습니다. 그때 매주 만나던 동료가 지금도 기억납니다. 처음에는 서툴러서 속상했습니다. 동료가 괜찮아요, 천천히 해요라고 말해 주었습니다. 그 말 덕분에 마음이 놓였습니다. 지금은 그곳을 떠나 새 회원 교육 자료를 만드는 중입니다. 제 친구도 같은 활동을 하고 싶어 하지만 아직 신청하지는 않았습니다.',[
            choice('sequence',loc('시간 순서에 맞는 것은?', 'Which sequence matches the talk?', 'Welche zeitliche Reihenfolge stimmt?'),[f'{place}에서 활동 시작 → 지금 교육 자료 제작','교육 자료 완성 → 내년에 첫 활동 시작'],lecture_help),
            choice('source',loc('천천히 해요라고 말한 사람은?', 'Who said to take it slowly?', 'Wer sagte, man solle sich Zeit lassen?'),['그때 함께 활동하던 동료','아직 신청하지 않은 친구'],lecture_help),
            choice('emotion',loc('마음이 놓인 계기는?', 'What brought relief?', 'Was sorgte für Erleichterung?'),['동료의 격려','친구의 신청 완료'],lecture_help),
            choice('limit',loc('친구에 대해 말할 수 있는 것은?', 'What can be said about the friend?', 'Was lässt sich über die befreundete Person sagen?'),['활동을 원하지만 아직 신청하지 않음','이미 활동 교육을 마침'],lecture_help),
        ],'audio')
    tasks.append(task('KP09','listening:02','listening',loc('첫 활동을 돌아보는 짧은 강연','A short talk about a first activity','Ein kurzer Vortrag über den ersten Einsatz'),lecture_help,
        talk('2022','마을 도서관','책 정리 활동'),talk('2023','동네 문화센터','공연 안내 활동')))
    reading_help=loc('게시글 본문과 댓글의 화자를 구별하세요. 직접 겪은 일, 인용한 말, 현재의 일과 희망을 따로 요약해요. 공감의 댓글을 본문의 모든 주장에 대한 동의로 바꾸지 마세요.',
        'Separate the author of the post from the commenters. Summarise experience, quoted words, present activity and wishes separately. An empathetic comment does not endorse every claim in the post.',
        'Unterscheide Beitrag und Kommentar nach ihren Verfassern. Fasse Erlebnis, Zitat, laufende Tätigkeit und Wunsch getrennt zusammen. Ein mitfühlender Kommentar bestätigt nicht jede Aussage im Beitrag.')
    def post(author,activity,place):
        return packet(f'공개 회고 게시글 — {author}\n처음 {activity}을 할 때 나는 {place}에 살았었다. 매주 가던 모임에서 실수를 하면 얼굴이 빨개졌다. 동료가 누구나 처음은 있어요라고 말해 주었다. 지금 나는 그 경험을 글로 정리하는 중이다. 친구는 다음 모임에 오고 싶어 한다. 아직 참석 여부는 정하지 않았다.\n댓글 — 수아: 실수해서 당황했던 마음은 이해해요. 모임 운영 방식은 제가 잘 몰라서 판단하기 어려워요.',[
            choice('quote',loc('누구나 처음은 있어요의 출처는?', 'Who said that everyone has a first time?', 'Von wem stammt der Satz, dass jeder einmal anfängt?'),['활동 당시 동료','댓글 작성자 수아'],reading_help),
            choice('now',loc('글쓴이가 현재 하는 일은?', 'What is the author doing now?', 'Was macht die schreibende Person gerade?'),['경험을 글로 정리하는 중','친구의 참석을 확정하는 중'],reading_help),
            choice('comment',loc('댓글의 태도는?', 'What is the commenter’s position?', 'Welche Haltung zeigt der Kommentar?'),['감정에는 공감하지만 운영 방식 판단은 유보','모임 운영 방식 전부에 찬성'],reading_help),
            choice('wish',loc('친구의 상태를 정확히 요약하면?', 'Which summary accurately describes the friend?', 'Welche Zusammenfassung beschreibt die befreundete Person richtig?'),['참석하고 싶지만 결정 전','참석을 확정했고 이미 다녀옴'],reading_help),
        ])
    tasks.append(task('KP09','reading:01','reading',loc('회고 게시글과 공감 댓글','A retrospective post and an empathetic comment','Rückblick und mitfühlender Kommentar'),reading_help,
        post('도윤','독서 모임 활동','대전'),post('하린','사진 모임 활동','광주')))
    writing_rubric=loc('가상 인물의 사건을 시간 순서에 맞춰 서사문으로 쓰세요. 당시 감정과 그 근거, 다른 사람이 실제로 한 말, 지금 달라진 점을 포함하세요. 본문은 서술체로, 직접 인용은 제공된 말투로 구별하고 희망을 확정 사실로 쓰지 마세요. 쓴 글을 근거와 대조해 고쳐 쓰세요. 전체 글의 의미와 문체는 미채점입니다.',
        'Write a narrative from the fictional facts in chronological order. Include the past feeling and its cause, what another person actually said and the change today. Use narrative style for the text and the supplied register for quotations. Keep wishes tentative. Compare and revise; the full text’s meaning and style remain unscored.',
        'Schreibe anhand der fiktiven Angaben eine zeitlich geordnete Erzählung. Nenne das damalige Gefühl samt Grund, tatsächlich Gesagtes und die heutige Veränderung. Trenne Erzählstil und vorgegebenen Stil direkter Zitate. Stelle Wünsche nicht als Tatsachen dar. Vergleiche und überarbeite; Inhalt und Stil des Gesamttextes bleiben unbewertet.')
    def story(year,place,activity,quote,current,wish):
        return packet(f'가상 인물의 1인칭 회고\n{year}년: {place} 거주. 매주 {activity}. 첫날 실수해서 당황함. 가까운 친구가 반말로 {quote}라고 말해 마음이 놓임.\n현재: 다른 도시 거주. {current}. 친구는 {wish} 싶어 하지만 아직 결정 전.\n제공된 사건을 서술체 본문과 직접 인용으로 구별해 한 편의 이야기로 쓰세요.',[
            free_text('narrative',loc('회고문을 쓰고 근거와 대조해 고치세요.','Write and revise the narrative against the facts.','Schreibe den Rückblick und überarbeite ihn anhand der Angaben.'),writing_rubric)],'form')
    tasks.append(task('KP09','writing:01','writing',loc('그때와 지금을 잇는 회고문','A narrative connecting then and now','Ein Rückblick von damals bis heute'),writing_rubric,
        story('2021','전주','합창 연습','천천히 같이 하자','새 모임을 찾는 중','노래를 배우고'),
        story('2022','춘천','연극 연습','괜찮아, 다시 해 보자','옛 사진을 정리하는 중','연극을 보고')))
    speaking_rubric=loc('오래된 가까운 친구와 사적으로 이야기하며 반말을 쓰기로 한 장면입니다. 과거·현재·친구의 희망을 구별하고, 말해 준 감정에 호응한 뒤 기억을 되물으세요. 이어 새 회원에게 같은 사실을 해요체로 전달하세요. 녹음을 듣고 회상 어미와 의미 단위의 휴지를 고쳐 재녹음하세요. 의미·관계 적합성·억양은 미채점입니다.',
        'In this private conversation, long-standing close friends have agreed to use casual speech. Separate past, present and the friend’s wish; acknowledge the stated feeling and ask about the memory. Then relay the same facts politely to a new member. Replay and revise endings and pauses. Meaning, relationship fit and intonation remain unscored.',
        'In diesem privaten Gespräch sprechen langjährige enge Freunde vereinbart vertraulich. Trenne Vergangenheit, Gegenwart und den Wunsch der anderen Person; greife das genannte Gefühl auf und frage nach der Erinnerung. Gib dieselben Fakten danach einem neuen Mitglied höflich weiter. Höre die Aufnahme an und verbessere Endungen und Pausen. Inhalt, Angemessenheit und Intonation bleiben unbewertet.')
    tasks.append(task('KP09','speaking:01','speaking',loc('친구의 기억에 호응하고 되묻기','Respond to a friend’s memory and ask back','Auf die Erinnerung eines Freundes eingehen und nachfragen'),speaking_rubric,
        packet('내 역할: 예전에는 부산에 살았고 매일 도서관에 갔음. 지금은 서울에서 이사 준비 중. 동생은 제주도에 가고 싶지만 아직 안 감.\n가까운 친구 지민: 그때 혼자라서 외로웠어.\n지민을 이름으로 부르고 감정에 호응한 뒤 당시 함께 가던 장소를 질문. 이어 새 회원에게 해요체로 확인된 사실만 전달.',[]),
        packet('내 역할: 예전에는 대구에 살았고 매주 문화센터에 갔음. 지금은 인천에서 발표 준비 중. 동생은 도예를 배우고 싶지만 아직 안 배움.\n가까운 친구 민수: 그때 실수해서 당황했어.\n민수를 이름으로 부르고 감정에 호응한 뒤 당시 함께 하던 활동을 질문. 이어 새 회원에게 해요체로 확인된 사실만 전달.',[])))
    interview_rubric=loc('취업 면접의 가상 지원자 역할입니다. 제공된 경험·기간·역할·현재 준비만 말하고 자격증이나 성과를 만들지 마세요. 면접관에게 공손한 해요체 또는 격식체로 사건과 배운 점을 구별해 답하세요. 녹음을 듣고 말투와 휴지를 고쳐 재녹음하세요. 경력의 진실성·의미·말투 평가는 자동 채점하지 않습니다.',
        'Play the fictional job applicant. Use only the supplied experience, duration, role and current preparation; invent no qualifications or achievements. Answer the interviewer politely or formally, separating events from lessons learned. Replay and revise register and pauses. Truth of experience, meaning and register are not automatically scored.',
        'Übernimm die Rolle einer fiktiven Bewerbungsperson. Verwende nur die vorgegebenen Erfahrungen, Zeiträume, Aufgaben und aktuellen Vorbereitungen; erfinde keine Abschlüsse oder Erfolge. Antworte der interviewenden Person höflich oder förmlich und trenne Ereignis und daraus Gelerntes. Höre zu und verbessere Sprachstil und Pausen. Wahrheitsgehalt, Inhalt und Sprachstil werden nicht automatisch bewertet.')
    tasks.append(task('KP09','speaking:02','speaking',loc('가상 지원자의 경험 면접','An experience interview with a fictional applicant','Vorstellungsgespräch mit fiktiven Erfahrungen'),interview_rubric,
        packet('가상 지원 분야: 도서관 안내 보조. 과거: 두 달 동안 주 1회 도서 정리 봉사. 역할: 직원이 정한 분류표에 맞춰 책 정리, 대출 결정 권한 없음. 처음 표지를 잘못 읽었지만 직원에게 확인해 수정. 배운 점: 모르는 내용은 확인하고 처리. 현재: 안내 표현을 공부하는 중.\n면접관 질문: 어떤 경험을 하셨나요? 실수했을 때 어떻게 하셨나요? 지금 무엇을 준비하시나요?',[]),
        packet('가상 지원 분야: 문화센터 안내 보조. 과거: 세 달 동안 주 1회 행사 안내 봉사. 역할: 직원이 정한 좌석표를 안내, 좌석 변경 결정 권한 없음. 처음 번호를 잘못 읽었지만 직원에게 확인해 수정. 배운 점: 모르는 내용은 확인하고 처리. 현재: 시설 안내 자료를 읽는 중.\n면접관 질문: 어떤 경험을 하셨나요? 실수했을 때 어떻게 하셨나요? 지금 무엇을 준비하시나요?',[])))
    return tasks


if __name__=='__main__':
    write_source('KP09',kp09())
