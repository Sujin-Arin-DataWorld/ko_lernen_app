# C2b-2 (2026-09-15) — A2 DE/EN translation refinement + A2 KO grammar
# refinement rewrite table. Applied by apply_c2b2_a2_fixes.py to
# korean_vocab.csv and propagated to cloze.json/satz_sentences.json
# mirrors by matching the OLD example_korean/fullKo/targetKo text.
#
# Two categories:
#  - "grammar": KO rewritten to remove nikl grade>=3 grammar (see
#    docs/data/grammar_scan_a2_2026-09-15.md); DE/EN re-derived to match.
#  - "translation": DE/EN/KO content-accuracy fixes found during the
#    manual read pass (see docs/data/c2b2_a2_translation_changes.csv).

REWRITES = {
    # --- grammar cluster: quotative/reported-speech, -자마자, -다 보면,
    # 이라도, 고 해서, 면 되다, 잖아요, -(으)래요 (reported contraction) ---
    "vocab_a1_0239": dict(
        category="grammar", rule="grade3 quotative -라고 하셨어요 removed",
        ko="윗목이 서늘해서 아래로 앉았어요.",
        de="Der obere Teil des Zimmers war kühl, deshalb setzte ich mich weiter unten hin.",
        en="The upper part of the room was cool, so I sat down further below.",
    ),
    "vocab_a1_0242": dict(
        category="grammar", rule="grade3 quotative -다고 했어요 removed",
        ko="방석을 밀어 주셔서 감사했어요.",
        de="Sie schoben mir ein Sitzkissen zu, und ich war dankbar.",
        en="They pushed a floor cushion over, and I was thankful.",
    ),
    "vocab_a1_0243": dict(
        category="grammar", rule="grade3 bare-quote 하셔서 removed",
        ko="물 드세요. 두 손으로 컵을 받았어요.",
        de="Trinken Sie etwas Wasser. Ich nahm das Glas mit beiden Händen.",
        en="Please have some water. I took the glass with both hands.",
    ),
    "vocab_a1_0276": dict(
        category="grammar", rule="grade3 quotative -으라고 하셨어요 removed",
        ko="성묘 갈 때는 편한 신발을 신었어요.",
        de="Für den Grabbesuch zog ich bequeme Schuhe an.",
        en="I wore comfortable shoes for the grave visit.",
    ),
    "vocab_a1_0299": dict(
        category="grammar", rule="grade3 quotative -라고 했어요 removed",
        ko="나갈 때 인사했어요. 잘 다녀오겠습니다!",
        de="Beim Rausgehen habe ich mich verabschiedet. Ich mache mich dann auf den Weg!",
        en="I said goodbye as I left. I'll be heading out now!",
    ),
    "vocab_a1_0301": dict(
        category="grammar", rule="grade3 bare-quote 하셔서 removed",
        ko="다음에 또 오세요. 그 말을 듣고 신발을 거꾸로 신었어요.",
        de="Kommen Sie bald wieder. Ich hörte das und zog aus Eile die Schuhe verkehrt herum an.",
        en="Please come again. I heard that and put my shoes on backwards in my hurry.",
    ),
    "vocab_a1_0366": dict(
        category="grammar", rule="grade3 -다 보면 replaced with plain -으면",
        ko="중요한 문장을 빨리 필기하면 손이 아파요.",
        de="Wenn ich wichtige Sätze schnell mitschreibe, tut mir die Hand weh.",
        en="If I take notes on important sentences quickly, my hand hurts.",
    ),
    "vocab_a2_0106": dict(
        category="grammar", rule="grade3 -면 되다 replaced with plain imperative",
        ko="여기서 곧장 가세요.",
        de="Gehen Sie von hier einfach geradeaus.",
        en="Just go straight from here.",
    ),
    "vocab_a2_0115": dict(
        category="grammar", rule="grade3 -잖아요 removed",
        ko="깜짝 놀랐어요!",
        de="Ich bin total erschrocken!",
        en="I was so startled!",
    ),
    "vocab_a2_0160": dict(
        category="grammar", rule="grade3 -이라도 removed",
        ko="매달 조금씩 저축하려고 해요.",
        de="Ich versuche, jeden Monat ein wenig zu sparen.",
        en="I try to save a little every month.",
    ),
    "vocab_a2_0269": dict(
        category="grammar", rule="grade3 -길래/-라고 했어요 removed, direct Q&A",
        ko="어디서 오셨어요? 독일 베를린이에요.",
        de="Woher kommen Sie? Aus Berlin in Deutschland.",
        en="Where are you from? Berlin, Germany.",
    ),
    "vocab_a2_0272": dict(
        category="grammar", rule="grade3 -길래/-라고 했어요 removed, direct Q&A",
        ko="언제 왔어요? 재작년에 왔어요.",
        de="Wann sind Sie gekommen? Vorletztes Jahr.",
        en="When did you come? The year before last.",
    ),
    "vocab_a2_0274": dict(
        category="grammar", rule="grade3 -다고 했어요 removed",
        ko="소개팅이 아니라 동아리에서 만났어요.",
        de="Wir haben uns nicht über ein Date, sondern im Verein kennengelernt.",
        en="We met in a club, not on a set-up date.",
    ),
    "vocab_a2_0279": dict(
        category="grammar", rule="grade3 -길래/-다고 했어요 removed",
        ko="제 음식 취향을 물어봤어요. 매운 건 조금만 먹어요.",
        de="Sie fragten nach meinen Essensvorlieben. Scharfes esse ich nur wenig.",
        en="They asked about my food preferences. I only eat a little spicy food.",
    ),
    "vocab_a2_0282": dict(
        category="grammar", rule="grade3 -다 보면/-는다는 removed, plain -으면",
        ko="떡국을 먹으면 나이를 한 살 더 먹어요.",
        de="Wenn man die Reiskuchensuppe isst, wird man ein Jahr älter.",
        en="If you eat the rice-cake soup, you turn one year older.",
    ),
    "vocab_a2_0288": dict(
        category="grammar", rule="grade4 reported contraction -으래요 removed",
        ko="세배 영상은 가족 앨범에만 둬요.",
        de="Das Video kommt nur ins Familienalbum.",
        en="The bowing video only goes in the family album.",
    ),
    "vocab_a2_0292": dict(
        category="grammar", rule="grade3 -길래/-라고 했어요 removed",
        ko="제 새해 목표는 한국어 일기예요.",
        de="Mein Neujahrsvorsatz ist ein koreanisches Tagebuch.",
        en="My new year's goal is a Korean diary.",
    ),
    "vocab_a2_0295": dict(
        category="grammar", rule="grade4 reported contraction -래요 removed",
        ko="보름달을 보면서 소원을 말해요.",
        de="Beim Vollmond macht man einen Wunsch.",
        en="You make a wish while looking at the full moon.",
    ),
    "vocab_a2_0320": dict(
        category="grammar", rule="grade3 -자마자 replaced with -아서",
        ko="아침 인사는 일어나서 바로 크게 했어요.",
        de="Den Morgengruß habe ich gleich nach dem Aufstehen laut gesagt.",
        en="I said my morning greeting loudly right after getting up.",
    ),
    "vocab_a2_0345": dict(
        category="grammar", rule="grade4 -고 해서/-다고 removed",
        ko="김치는 짐으로 부칠 수 없어서 무릎 위에 올렸어요.",
        de="Das Kimchi durfte ich nicht als Gepäck aufgeben, also kam es auf meine Knie.",
        en="I couldn't check the kimchi as luggage, so it rode on my lap.",
    ),
    "vocab_a2_0349": dict(
        category="grammar", rule="grade3 quotative -으라고 하셨어요 removed",
        ko="집 마당에 개가 있어서 그냥 앉아 있었어요.",
        de="Im Hof war ein Hund, also blieb ich einfach sitzen.",
        en="There was a dog in the yard, so I just stayed seated.",
    ),
    "vocab_a2_0350": dict(
        category="grammar", rule="grade3 -다고 했어요 removed",
        ko="밤참으로 과일만 부탁했는데 라면이 나왔어요.",
        de="Als Spätimbiss bat ich nur um Obst, aber es kam Ramyeon.",
        en="I asked for only fruit as a late snack, but ramyeon came out.",
    ),
    "vocab_a2_0352": dict(
        category="grammar", rule="grade3 -자마자 replaced with -아서",
        ko="서울에 도착해서 바로 안부 전화를 드렸어요.",
        de="Ich bin in Seoul angekommen und habe sofort angerufen, dass wir gut angekommen sind.",
        en="I arrived in Seoul and called right away to say we'd arrived safely.",
    ),
    # --- KO grammar bug (bare -다 before 해요) ---
    "vocab_a1_0391": dict(
        category="grammar", rule="bare -다 stem before 해요 (conjugation bug)",
        ko="일교차가 클 때는 옷을 겹쳐 입어요.",
        de=None, en=None,
    ),
    # --- translation-accuracy fixes (example didn't demonstrate headword /
    # content mismatch across KO-DE-EN) ---
    "vocab_a2_0089": dict(
        category="translation", rule="example never used headword 추천하다",
        ko="여기서 뭐 추천해요?",
        de="Was empfehlen Sie hier?",
        en="What do you recommend here?",
    ),
    "vocab_a2_0159": dict(
        category="translation",
        rule="example/DE/EN all mismatched (payment vs currency-fact) and never used headword 통화",
        ko="한국의 통화는 원이에요.",
        de="Die Währung in Korea ist der Won.",
        en="Korea's currency is the won.",
    ),
}
