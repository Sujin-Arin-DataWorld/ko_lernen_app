# -*- coding: utf-8 -*-
"""C2d rewrite content table (2026-09-15) -- hand-authored replacements for
every A1 row scan_a1_grammar.py flagged as grade>=2 grammar (docs/data/
a1_grammar_scan_2026-09-15.md). Each keeps the row's headword/meaning as
close as docs/CONTENT_LEVEL_BIBLE.md §B.1's 1급 grammar table allows.
Cloze "answer" is whatever contiguous span of the new `fullKo` is blanked
-- it does not have to equal korean_vocab.csv's `korean` column (the
existing live data already does this, e.g. cloze_a1_0146's answer "수저
놓" is a fragment, not the full headword "수저 놓다").
"""

VOCAB_REWRITES = {
    # id: (new_example_korean, new_example_german, new_example_english)
    # -- cluster A: a1_partner_meet_names_1 / table_basic_1 / seollal_basic_1
    "vocab_a1_0221": (
        "할머니, 몇 살이세요?",
        "Oma, wie alt sind Sie?",
        "Grandma, how old are you?",
    ),
    "vocab_a1_0223": (
        "댁에 처음 와서 신발을 여기에 뒀어요.",
        "Ich bin zum ersten Mal bei Ihnen zu Hause und habe die Schuhe hier hingestellt.",
        "I came to your home for the first time and put my shoes here.",
    ),
    "vocab_a1_0248": (
        "할머니, 진지 드세요.",
        "Oma, essen Sie bitte.",
        "Grandma, please eat.",
    ),
    "vocab_a1_0250": (
        "밑반찬이 열 가지가 나와서 놀랐어요.",
        "Es kamen zehn Beilagen auf den Tisch, das hat mich überrascht.",
        "Ten side dishes came out, which surprised me.",
    ),
    "vocab_a1_0252": (
        # Fable R8-D: tense clash (배불러요=present, 먹었어요=past) fixed --
        # both clauses present tense, 을->은 for the contrastive topic.
        "배불러요. 하지만 과일은 먹어요.",
        "Ich bin satt. Aber ich esse Obst.",
        "I'm full. But I eat fruit.",
    ),
    "vocab_a1_0253": (
        # Fable R8-C: 현우 is not one of the 11 canonical personas
        # (character_profiles.json); this pack is 크리스티안 visiting
        # 수진's parents (동선·병철, 수원) -- swap to 수진.
        "맛있어요. 그래서 수진 씨가 웃었어요.",
        "Es ist lecker. Deshalb musste Sujin lachen.",
        "It's delicious. So Sujin laughed.",
    ),
    "vocab_a1_0258": (
        "이야기를 듣고 수저를 놓았어요.",
        "Ich habe zugehört und das Besteck abgelegt.",
        "I listened, and I put my spoon down.",
    ),
    "vocab_a1_0259": (
        "설거지를 도우려고 일어섰어요.",
        "Ich bin aufgestanden, um beim Abwasch zu helfen.",
        "I stood up to help with the dishes.",
    ),
    "vocab_a1_0264": (
        "한복을 입고 고름을 맸어요.",
        "Ich habe den Hanbok angezogen und die Schleife gebunden.",
        "I put on the hanbok and tied the ribbon.",
    ),
    "vocab_a1_0268": (
        "덕담을 듣고 정말 기뻤어요.",
        "Ich habe die Neujahrswünsche gehört und war sehr froh.",
        "I heard the New Year's blessing, and I was very happy.",
    ),
    "vocab_a1_0269": (
        "차례상 앞에서는 사진을 찍지 않아요.",
        "Vor dem Ahnentisch macht man keine Fotos.",
        "In front of the ancestral table, you don't take pictures.",
    ),
    # -- cluster C: standalone
    "vocab_a1_0009": (
        "아니요, 저는 안 가요.",
        "Nein, ich gehe nicht.",
        "No, I'm not going.",
    ),
    "vocab_a1_0045": (
        "오늘 눈이 좀 피곤해요.",
        "Meine Augen sind heute etwas müde.",
        "My eyes are a bit tired today.",
    ),
    "vocab_a1_0181": (
        "옆에 앉을까요?",
        "Soll ich mich neben dich setzen?",
        "Shall I sit next to you?",
    ),
    # -- cluster D: a1_weekend_promise_1 / a1_sorry_thanks_1 (also fixes the
    # pre-existing broken dictionary-form insertion, e.g. old "취소하다
    # 결정해요" -> a properly conjugated 1급 sentence)
    "vocab_a1_0335": (
        "비가 와서 산책을 취소했어요.",
        "Es hat geregnet, deshalb habe ich den Spaziergang abgesagt.",
        "It rained, so I canceled the walk.",
    ),
    "vocab_a1_0336": (
        "늦기 전에 저한테 미리 연락하세요.",
        "Bitte melde dich vorher bei mir, bevor du zu spät kommst.",
        "Contact me in advance before you're late.",
    ),
    "vocab_a1_0340": (
        "주말 계획을 같이 세울까요?",
        "Sollen wir den Wochenendplan zusammen machen?",
        "Shall we make the weekend plan together?",
    ),
    "vocab_a1_0341": (
        # Fable R8-B: headword "늦을 것 같다" must stay verbatim in its own
        # example -- the headword itself embeds -을 것 같다 (nikl grade 2),
        # a pack-design fact registered in scan_a1_grammar.py's
        # HEADWORD_EMBEDDED_GRAMMAR exception list, not something this
        # example can fix without dropping the headword.
        "버스가 막혀서 늦을 것 같아요.",
        "Der Bus steckt fest, ich komme wahrscheinlich zu spät.",
        "The bus is stuck, so it looks like I'll be late.",
    ),
    "vocab_a1_0343": (
        "저는 먼저 가서 자리를 잡겠어요.",
        "Ich gehe zuerst und sichere die Plätze.",
        "I'll go ahead and grab the seats.",
    ),
    "vocab_a1_0401": (
        "한국어를 천천히 말해서 이해가 돼요.",
        "Weil du langsam Koreanisch sprichst, verstehe ich es.",
        "Because you speak Korean slowly, I understand.",
    ),
}

# cloze ids that mirror a VOCAB_REWRITES row 1:1 (same underlying sentence
# family). Explicit per-row control (answer/sentenceKo/fullKo/distractors)
# since the blanked span is not always the vocab headword verbatim.
CLOZE_MIRROR_REWRITES = {
    "cloze_a1_0109": {
        "answer": "몇 살이세요", "sentenceKo": "할머니, ＿＿＿?",
        "fullKo": "할머니, 몇 살이세요?",
        "de": "Oma, wie alt sind Sie?", "en": "Grandma, how old are you?",
    },  # distractors unchanged (answer unchanged)
    "cloze_a1_0111": {
        "answer": "댁에", "sentenceKo": "＿＿＿ 처음 와서 신발을 여기에 뒀어요.",
        "fullKo": "댁에 처음 와서 신발을 여기에 뒀어요.",
        "de": "Ich bin zum ersten Mal bei Ihnen zu Hause und habe die Schuhe hier hingestellt.",
        "en": "I came to your home for the first time and put my shoes here.",
    },
    "cloze_a1_0136": {
        "answer": "진지", "sentenceKo": "할머니, ＿＿＿ 드세요.",
        "fullKo": "할머니, 진지 드세요.",
        "de": "Oma, essen Sie bitte.", "en": "Grandma, please eat.",
    },
    "cloze_a1_0138": {
        "answer": "밑반찬", "sentenceKo": "＿＿＿이 열 가지가 나와서 놀랐어요.",
        "fullKo": "밑반찬이 열 가지가 나와서 놀랐어요.",
        "de": "Es kamen zehn Beilagen auf den Tisch, das hat mich überrascht.",
        "en": "Ten side dishes came out, which surprised me.",
    },
    "cloze_a1_0140": {
        "answer": "배불러요", "sentenceKo": "＿＿＿. 하지만 과일은 먹어요.",
        "fullKo": "배불러요. 하지만 과일은 먹어요.",
        "de": "Ich bin satt. Aber ich esse Obst.",
        "en": "I'm full. But I eat fruit.",
    },
    "cloze_a1_0141": {
        "answer": "맛있어요", "sentenceKo": "＿＿＿. 그래서 수진 씨가 웃었어요.",
        "fullKo": "맛있어요. 그래서 수진 씨가 웃었어요.",
        "de": "Es ist lecker. Deshalb musste Sujin lachen.",
        "en": "It's delicious. So Sujin laughed.",
    },
    "cloze_a1_0146": {
        "answer": "수저를 놓았어요", "sentenceKo": "이야기를 듣고 ＿＿＿.",
        "fullKo": "이야기를 듣고 수저를 놓았어요.",
        "de": "Ich habe zugehört und das Besteck abgelegt.",
        "en": "I listened, and I put my spoon down.",
        "distractors": ["밥을 더 먹었어요", "자리에서 일어났어요", "문을 열었어요"],
    },
    "cloze_a1_0147": {
        "answer": "설거지", "sentenceKo": "＿＿＿를 도우려고 일어섰어요.",
        "fullKo": "설거지를 도우려고 일어섰어요.",
        "de": "Ich bin aufgestanden, um beim Abwasch zu helfen.",
        "en": "I stood up to help with the dishes.",
    },
    "cloze_a1_0152": {
        "answer": "한복", "sentenceKo": "＿＿＿을 입고 고름을 맸어요.",
        "fullKo": "한복을 입고 고름을 맸어요.",
        "de": "Ich habe den Hanbok angezogen und die Schleife gebunden.",
        "en": "I put on the hanbok and tied the ribbon.",
    },
    "cloze_a1_0156": {
        "answer": "덕담", "sentenceKo": "＿＿＿을 듣고 정말 기뻤어요.",
        "fullKo": "덕담을 듣고 정말 기뻤어요.",
        "de": "Ich habe die Neujahrswünsche gehört und war sehr froh.",
        "en": "I heard the New Year's blessing, and I was very happy.",
    },
    "cloze_a1_0157": {
        "answer": "차례상", "sentenceKo": "＿＿＿ 앞에서는 사진을 찍지 않아요.",
        "fullKo": "차례상 앞에서는 사진을 찍지 않아요.",
        "de": "Vor dem Ahnentisch macht man keine Fotos.",
        "en": "In front of the ancestral table, you don't take pictures.",
    },
    "cloze_a1_0223": {
        "answer": "취소했어요", "sentenceKo": "비가 와서 산책을 ＿＿＿.",
        "fullKo": "비가 와서 산책을 취소했어요.",
        "de": "Es hat geregnet, deshalb habe ich den Spaziergang abgesagt.",
        "en": "It rained, so I canceled the walk.",
        "distractors": ["예약했어요", "연락했어요", "결정했어요"],
    },
    "cloze_a1_0224": {
        "answer": "미리 연락하세요", "sentenceKo": "늦기 전에 저한테 ＿＿＿.",
        "fullKo": "늦기 전에 저한테 미리 연락하세요.",
        "de": "Bitte melde dich vorher bei mir, bevor du zu spät kommst.",
        "en": "Contact me in advance before you're late.",
        "distractors": ["미리 준비하세요", "미리 출발하세요", "미리 확인하세요"],
    },
    "cloze_a1_0228": {
        "answer": "주말 계획", "sentenceKo": "＿＿＿을 같이 세울까요?",
        "fullKo": "주말 계획을 같이 세울까요?",
        "de": "Sollen wir den Wochenendplan zusammen machen?",
        "en": "Shall we make the weekend plan together?",
    },
    "cloze_a1_0229": {
        "answer": "늦을 것 같아요", "sentenceKo": "버스가 막혀서 ＿＿＿.",
        "fullKo": "버스가 막혀서 늦을 것 같아요.",
        "de": "Der Bus steckt fest, ich komme wahrscheinlich zu spät.",
        "en": "The bus is stuck, so it looks like I'll be late.",
        "distractors": ["빠를 것 같아요", "추울 것 같아요", "힘들 것 같아요"],
    },
    "cloze_a1_0231": {
        "answer": "먼저 가서", "sentenceKo": "저는 ＿＿＿ 자리를 잡겠어요.",
        "fullKo": "저는 먼저 가서 자리를 잡겠어요.",
        "de": "Ich gehe zuerst und sichere die Plätze.",
        "en": "I'll go ahead and grab the seats.",
        "distractors": ["나중에 와서", "같이 앉아서", "천천히 걸어서"],
    },
    "cloze_a1_0378": {
        "answer": "피곤해요", "sentenceKo": "오늘 눈이 좀 ＿＿＿.",
        "fullKo": "오늘 눈이 좀 피곤해요.",
        "de": "Meine Augen sind heute etwas müde.",
        "en": "My eyes are a bit tired today.",
    },
    "cloze_a1_0289": {
        "answer": "천천히 말해서", "sentenceKo": "한국어를 ＿＿＿ 이해가 돼요.",
        "fullKo": "한국어를 천천히 말해서 이해가 돼요.",
        "de": "Weil du langsam Koreanisch sprichst, verstehe ich es.",
        "en": "Because you speak Korean slowly, I understand.",
        "distractors": ["빨리 걸어서", "크게 웃어서", "일찍 일어나서"],
    },
}

# satz ids that mirror a VOCAB_REWRITES row 1:1. targetKo/promptDe/promptEn
# only -- distractors are regenerated by the apply script using the exact
# build_satzbauen.py algorithm (2 short real eojeol from other a1
# sentences, not present in the target, crc32-seeded).
SATZ_MIRROR_REWRITES = {
    "satz_a1_0073": ("할머니, 몇 살이세요?", "Oma, wie alt sind Sie?", "Grandma, how old are you?"),
    "satz_a1_0075": (
        "댁에 처음 와서 신발을 여기에 뒀어요.",
        "Ich bin zum ersten Mal bei Ihnen zu Hause und habe die Schuhe hier hingestellt.",
        "I came to your home for the first time and put my shoes here.",
    ),
    "satz_a1_0100": ("할머니, 진지 드세요.", "Oma, essen Sie bitte.", "Grandma, please eat."),
    "satz_a1_0102": (
        "밑반찬이 열 가지가 나와서 놀랐어요.",
        "Es kamen zehn Beilagen auf den Tisch, das hat mich überrascht.",
        "Ten side dishes came out, which surprised me.",
    ),
    "satz_a1_0104": ("배불러요. 하지만 과일은 먹어요.", "Ich bin satt. Aber ich esse Obst.", "I'm full. But I eat fruit."),
    "satz_a1_0105": ("맛있어요. 그래서 수진 씨가 웃었어요.", "Es ist lecker. Deshalb musste Sujin lachen.", "It's delicious. So Sujin laughed."),
    "satz_a1_0110": ("이야기를 듣고 수저를 놓았어요.", "Ich habe zugehört und das Besteck abgelegt.", "I listened, and I put my spoon down."),
    "satz_a1_0111": ("설거지를 도우려고 일어섰어요.", "Ich bin aufgestanden, um beim Abwasch zu helfen.", "I stood up to help with the dishes."),
    "satz_a1_0116": ("한복을 입고 고름을 맸어요.", "Ich habe den Hanbok angezogen und die Schleife gebunden.", "I put on the hanbok and tied the ribbon."),
    "satz_a1_0120": ("덕담을 듣고 정말 기뻤어요.", "Ich habe die Neujahrswünsche gehört und war sehr froh.", "I heard the New Year's blessing, and I was very happy."),
    "satz_a1_0121": ("차례상 앞에서는 사진을 찍지 않아요.", "Vor dem Ahnentisch macht man keine Fotos.", "In front of the ancestral table, you don't take pictures."),
    "satz_a1_0187": ("비가 와서 산책을 취소했어요.", "Es hat geregnet, deshalb habe ich den Spaziergang abgesagt.", "It rained, so I canceled the walk."),
    "satz_a1_0188": ("늦기 전에 저한테 미리 연락하세요.", "Bitte melde dich vorher bei mir, bevor du zu spät kommst.", "Contact me in advance before you're late."),
    "satz_a1_0192": ("주말 계획을 같이 세울까요?", "Sollen wir den Wochenendplan zusammen machen?", "Shall we make the weekend plan together?"),
    "satz_a1_0193": ("버스가 막혀서 늦을 것 같아요.", "Der Bus steckt fest, ich komme wahrscheinlich zu spät.", "The bus is stuck, so it looks like I'll be late."),
    "satz_a1_0195": ("저는 먼저 가서 자리를 잡겠어요.", "Ich gehe zuerst und sichere die Plätze.", "I'll go ahead and grab the seats."),
    "satz_a1_0253": ("한국어를 천천히 말해서 이해가 돼요.", "Weil du langsam Koreanisch sprichst, verstehe ich es.", "Because you speak Korean slowly, I understand."),
    "satz_a1_0046": ("옆에 앉을까요?", "Soll ich mich neben dich setzen?", "Shall I sit next to you?"),
    "satz_a1_0257": ("아니요, 저는 안 가요.", "Nein, ich gehe nicht.", "No, I'm not going."),
    "satz_a1_0265": ("오늘 눈이 좀 피곤해요.", "Meine Augen sind heute etwas müde.", "My eyes are a bit tired today."),
}

# cloze items with no vocab source (brief step 2: "rewrite in place, re-pick
# distractors"). All 9 greeting ones are the a1_01_greetings_hangul unit --
# dropping the "-라고 말해요/해요/인사해요" 인용 wrapper (grade 3, not in
# the 45-item table) in favour of stating the greeting directly, which is
# itself already 1급-legal since every headword here IS a greeting
# expression. distractors re-picked: other polite expressions from the
# SAME unit (already vetted A1 vocabulary), never a word that would also
# fit the blank (nonsense-only).
CLOZE_ONLY_REWRITES = {
    "cloze_a1_0293": {
        "sentenceKo": "친구를 만나서 ＿＿＿.", "answer": "반가워요",
        "fullKo": "친구를 만나서 반가워요.",
        "de": "Ich treffe einen Freund und freue mich.",
        "en": "I meet a friend and I'm glad.",
        "distractors": ["고마워요", "죄송해요", "괜찮아요"],
    },
    "cloze_a1_0294": {
        # Fable R8-A: "만난 분" is 관형사형(-ㄴ)+분 (nikl grade 2, 전성어미)
        # -- switched to the situation+greeting two-sentence pattern
        # (0297/0298's shape); DE/EN rewritten to match literally.
        "sentenceKo": "처음 만나요. ＿＿＿.", "answer": "처음 뵙겠습니다",
        "fullKo": "처음 만나요. 처음 뵙겠습니다.",
        "de": "Ich treffe jemanden zum ersten Mal. Schön, Sie kennenzulernen.",
        "en": "I meet someone for the first time. Nice to meet you.",
        "distractors": ["잘 먹겠습니다", "다녀오겠습니다", "수고했습니다"],
    },
    "cloze_a1_0295": {
        # Fable R8-A: "가는 친구" is 관형사형(-는)+친구 (grade 2).
        "sentenceKo": "친구가 집에 가요. ＿＿＿!", "answer": "잘 가요",
        "fullKo": "친구가 집에 가요. 잘 가요!",
        "de": "Ein Freund geht nach Hause. Mach's gut!",
        "en": "A friend goes home. Take care!",
        "distractors": ["어서 와요", "잘 먹어요", "괜찮아요"],
    },
    "cloze_a1_0296": {
        # Fable R8-A: "나가는 손님" is 관형사형(-는)+손님 (grade 2).
        "sentenceKo": "손님이 나가요. ＿＿＿.", "answer": "안녕히 가세요",
        "fullKo": "손님이 나가요. 안녕히 가세요.",
        "de": "Ein Gast geht hinaus. Auf Wiedersehen!",
        "en": "A guest leaves. Goodbye!",
        "distractors": ["안녕히 계세요", "다녀오세요", "어서 오세요"],
    },
    "cloze_a1_0297": {
        "sentenceKo": "저는 먼저 나가요. ＿＿＿.", "answer": "안녕히 계세요",
        "fullKo": "저는 먼저 나가요. 안녕히 계세요.",
        "de": "Ich gehe zuerst. Ich verabschiede mich von der Person, die bleibt.",
        "en": "I leave first. I say goodbye to the person staying.",
        "distractors": ["안녕히 가세요", "어서 오세요", "잘 다녀오세요"],
    },
    "cloze_a1_0298": {
        "sentenceKo": "손님이 들어와요. ＿＿＿.", "answer": "어서 오세요",
        "fullKo": "손님이 들어와요. 어서 오세요.",
        "de": "Ein Gast kommt herein. Ich heiße ihn willkommen.",
        "en": "A guest comes in. I welcome them.",
        "distractors": ["다녀오세요", "안녕히 계세요", "잘 부탁해요"],
    },
    "cloze_a1_0299": {
        # Fable R8-A: two-sentence pattern for consistency with the rest
        # of the pack (0297/0298/0295/0296) -- "받고" left the sentence
        # register-mixed with the formal 감사합니다.
        "sentenceKo": "도움을 받았어요. ＿＿＿.", "answer": "감사합니다",
        "fullKo": "도움을 받았어요. 감사합니다.",
        "de": "Ich habe Hilfe bekommen. Danke.",
        "en": "I received help. Thank you.",
        "distractors": ["죄송합니다", "괜찮습니다", "축하합니다"],
    },
    "cloze_a1_0300": {
        "sentenceKo": "약속에 늦어서 ＿＿＿.", "answer": "죄송합니다",
        "fullKo": "약속에 늦어서 죄송합니다.",
        "de": "Weil ich zu spät bin, entschuldige ich mich höflich.",
        "en": "Because I'm late, I apologize politely.",
        "distractors": ["감사합니다", "반갑습니다", "축하합니다"],
    },
    "cloze_a1_0344": {
        # Fable R8-A: the headword/answer 화이팅 had vanished from the
        # sentence entirely -- restored, in the situation+greeting
        # two-sentence pattern.
        "sentenceKo": "시험 전에 친구가 말해요. ＿＿＿!", "answer": "화이팅",
        "fullKo": "시험 전에 친구가 말해요. 화이팅!",
        "de": "Vor der Prüfung sagt mir ein Freund: Fighting!",
        "en": "Before the test, a friend says to me: Fighting!",
        "distractors": ["안녕", "축하해", "괜찮아"],
    },
    # standalone -면 되다 (grade 2/3), no vocab source -- 1급 -을까요 asks
    # essentially the same "is it OK if I..." question.
    "cloze_a1_0322": {
        "sentenceKo": "＿＿＿ 기다릴까요?", "answer": "여기에서",
        "fullKo": "여기에서 기다릴까요?",
        "de": "Soll ich hier warten?", "en": "Shall I wait here?",
        "distractors": ["어제부터", "친구하고", "세 개를"],
    },
}

# satz items with no vocab/cloze source (standalone Satzbauen seeds).
SATZ_ONLY_REWRITES = {
    "satz_a1_0320": (
        "예문을 보고 단어 뜻을 알아요.",
        "Ich lese das Beispiel und verstehe die Wortbedeutung.",
        "I read the example and learn the word's meaning.",
    ),
    "satz_a1_0330": (
        "도착 시간이 바뀌어서 저한테 연락하세요.",
        "Weil sich die Ankunftszeit geändert hat, melden Sie sich bei mir.",
        "Since the arrival time changed, contact me.",
    ),
}
