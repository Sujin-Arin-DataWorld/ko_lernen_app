# -*- coding: utf-8 -*-
"""C2d-2 rewrite content table (2026-09-16) -- hand-authored replacements
for the 38 DOCUMENTED_EXCEPTIONS rows left open by C2d (PR #339) plus
vocab_a1_0402 (and its cloze/satz mirrors cloze_a1_0290/satz_a1_0254,
found by exact-text match, not originally listed by id but the same
'-아/어 주셔서' family). Jin's 2026-09-16 ruling (option a): rewrite the
'-아/어 주세요' benefactive-REQUEST family with 1급 -으세요 (honorific
imperative) or, where a bare imperative reads awkwardly without the
benefactive nuance, soften into a first-person '-을 수 있어요?' question
(both in docs/CONTENT_LEVEL_BIBLE.md §B.1's 45-item table). Noun + lexical
주다 ("물 주세요") is out of scope -- 주다 is itself a 1급 main verb; none
of these 41 rows are that shape (all carry -아/어 주다/주시다 as an
auxiliary). '-아/어 주다' itself is not introduced until A2.

vocab_a1_0410 (headword "적어 주다") is EXCLUDED here -- the headword
itself embeds -아/어 주다, so its example is kept verbatim (see
scan_a1_grammar.py's HEADWORD_EMBEDDED_GRAMMAR and docs/data/
a1_grammar_scan_2026-09-15.md's relevel-to-A2 candidates section). Its
satz mirror satz_a1_0317 is excluded for the same reason.
"""

VOCAB_REWRITES = {
    # id: (new_example_korean, new_example_german, new_example_english)
    "vocab_a1_0141": (
        # 빌려주다 ("lend") is itself a lexicalized -아/어 주다 compound and
        # the request direction (asking to BE LENT money) has no clean
        # bare-imperative form without it -- reframe from the borrower's
        # own perspective instead: 빌리다 ("borrow") + -을 수 있어요?.
        "천 원만 빌릴 수 있어요?",
        "Kann ich mir nur tausend Won leihen?",
        "Can I just borrow a thousand won?",
    ),
    "vocab_a1_0202": (
        "잠깐만 여기서 기다리세요.",
        "Warten Sie bitte hier einen Moment.",
        "Please wait here for a moment.",
    ),
    "vocab_a1_0203": (
        # Jin's own worked example ("천천히 말해 주세요" -> "천천히
        # 말하세요") is only 2 어절, short of the satz build contract's
        # >=3 토큰 (test_rewritten_satz_meets_the_satz_test_build_contract)
        # -- every mirror (vocab/cloze/satz) needs the same text to keep
        # the derived-copy invariant, so "다시" is added throughout.
        "다시 천천히 말하세요.",
        "Bitte sagen Sie es noch einmal langsam.",
        "Please say it again, slowly.",
    ),
    "vocab_b1_0196": (
        "이 질문에 대답하세요.",
        "Bitte antworten Sie auf diese Frage.",
        "Please answer this question.",
    ),
    "vocab_a1_0217": (
        # Not a request -- past-tense narration ("my mother-in-law smiled
        # at me"). -아/어 주다 here carries a benefactive nuance with no
        # 1급 imperative equivalent; drop the auxiliary, keep the honorific
        # -으시- + past and recover "at me" via 보고 (연결어미 -고, already
        # in the 45-item table) instead of the benefactive marker.
        "시어머니께서 저를 보고 웃으셨어요.",
        "Meine Schwiegermutter hat mich angesehen und gelächelt.",
        "My mother-in-law looked at me and smiled.",
    ),
    "vocab_a1_0311": (
        "편지는 아래 우편함에 넣으세요.",
        "Bitte legen Sie den Brief in den Briefkasten unten.",
        "Please put the letter in the mailbox downstairs.",
    ),
    "vocab_a1_0316": (
        "받는 사람 전화번호를 적으세요.",
        "Bitte notieren Sie die Telefonnummer des Empfängers.",
        "Please write the recipient's phone number.",
    ),
    "vocab_a1_0408": (
        # 들려주다 ("let [someone] hear") is a lexicalized -아/어 주다
        # compound with no bare-imperative substitute (들리다 is
        # intransitive "to be audible") -- reframe as a first-person
        # -을 수 있어요? request instead, mirroring vocab_a1_0141.
        "이 단어 발음을 다시 들을 수 있어요?",
        "Kann ich die Aussprache dieses Wortes noch einmal hören?",
        "Can I hear the pronunciation of this word again?",
    ),
    "vocab_a1_0409": (
        "짧은 예문을 하나 적으세요.",
        "Bitte schreiben Sie einen kurzen Beispielsatz auf.",
        "Please write down one short example sentence.",
    ),
    "vocab_a1_0438": (
        # 알려주다 ("tell/inform") -- same lexicalized-compound problem as
        # 들려주다/보여주다; reframed as a direct question instead of an
        # imperative (실례지만, 1급 명사 실례 + 1급 연결어미 -지만, already
        # used in this exact fused shape by the live cloze_a1_0316
        # "죄송하지만").
        "실례지만 전화번호가 뭐예요?",
        "Entschuldigung, wie ist Ihre Telefonnummer?",
        "Excuse me, what is your phone number?",
    ),
    "vocab_a1_0456": (
        "다시 한번 말하세요.",
        "Bitte sagen Sie es noch einmal.",
        "Please say it once more.",
    ),
    "vocab_a1_0402": (
        # Not a request -- gratitude expression with a reason clause
        # ("thank you for giving up your seat"). Drop 주다, keep the
        # honorific -으시- + -어서 (reason, 1급 연결어미) fused as
        # -셔서 (양보하다+시+어서), same contraction shape as 하셔서/
        # 오셔서/가셔서 already used elsewhere in this corpus.
        "자리를 양보하셔서 정말 감사해요.",
        "Vielen Dank, dass Sie den Platz überlassen haben.",
        "Thank you so much for giving up the seat.",
    ),
}

# cloze ids that mirror a VOCAB_REWRITES row 1:1 (same underlying sentence).
CLOZE_MIRROR_REWRITES = {
    "cloze_a1_0094": {
        "answer": "천천히", "sentenceKo": "다시 ＿＿＿ 말하세요.",
        "fullKo": "다시 천천히 말하세요.",
        "de": "Bitte sagen Sie es noch einmal langsam.",
        "en": "Please say it again, slowly.",
    },
    "cloze_a1_0105": {
        "answer": "시어머니", "sentenceKo": "＿＿＿께서 저를 보고 웃으셨어요.",
        "fullKo": "시어머니께서 저를 보고 웃으셨어요.",
        "de": "Meine Schwiegermutter hat mich angesehen und gelächelt.",
        "en": "My mother-in-law looked at me and smiled.",
    },
    "cloze_a1_0199": {
        "answer": "우편함", "sentenceKo": "편지는 아래 ＿＿＿에 넣으세요.",
        "fullKo": "편지는 아래 우편함에 넣으세요.",
        "de": "Bitte legen Sie den Brief in den Briefkasten unten.",
        "en": "Please put the letter in the mailbox downstairs.",
    },
    "cloze_a1_0204": {
        "answer": "받는 사람", "sentenceKo": "＿＿＿ 전화번호를 적으세요.",
        "fullKo": "받는 사람 전화번호를 적으세요.",
        "de": "Bitte notieren Sie die Telefonnummer des Empfängers.",
        "en": "Please write the recipient's phone number.",
    },
    "cloze_a1_0367": {
        "answer": "전화번호", "sentenceKo": "실례지만 ＿＿＿가 뭐예요?",
        "fullKo": "실례지만 전화번호가 뭐예요?",
        "de": "Entschuldigung, wie ist Ihre Telefonnummer?",
        "en": "Excuse me, what is your phone number?",
    },
    "cloze_a1_0390": {
        "answer": "다시", "sentenceKo": "＿＿＿ 한번 말하세요.",
        "fullKo": "다시 한번 말하세요.",
        "de": "Bitte sagen Sie es noch einmal.",
        "en": "Please say it once more.",
    },
    "cloze_a1_0290": {
        "answer": "정말 감사해요", "sentenceKo": "자리를 양보하셔서 ＿＿＿.",
        "fullKo": "자리를 양보하셔서 정말 감사해요.",
        "de": "Vielen Dank, dass Sie den Platz überlassen haben.",
        "en": "Thank you so much for giving up the seat.",
    },
}

# cloze items with no vocab source -- rewrite in place, re-pick distractors
# only where the blanked span's shape changed.
CLOZE_ONLY_REWRITES = {
    "cloze_a1_0316": {
        "sentenceKo": "죄송하지만 ＿＿＿ 말하세요.", "answer": "다시",
        "fullKo": "죄송하지만 다시 말하세요.",
        "de": "Entschuldigung, bitte sagen Sie es noch einmal.",
        "en": "Sorry, please say that again.",
    },
    "cloze_a1_0317": {
        "sentenceKo": "조금 ＿＿＿ 말하세요.", "answer": "천천히",
        "fullKo": "조금 천천히 말하세요.",
        "de": "Bitte sprechen Sie etwas langsamer.",
        "en": "Please speak a little more slowly.",
    },
    "cloze_a1_0319": {
        # answer WAS the whole flagged ending ("적어 주세요") -- new answer
        # is the -으세요 form; distractors re-shaped to match (other verbs
        # in the SAME -(으)세요 conjugation, mirroring the old 읽다/듣다/
        # 열다 distractor set).
        "sentenceKo": "이름을 ＿＿＿.", "answer": "적으세요",
        "fullKo": "이름을 적으세요.",
        "de": "Bitte schreiben Sie den Namen auf.",
        "en": "Please write the name down.",
        "distractors": ["읽으세요", "들으세요", "여세요"],
    },
    "cloze_a1_0320": {
        # 보여주다 ("show") has no bare-imperative substitute without
        # 주다; reframe as a first-person -을 수 있어요? request (보다,
        # "see") instead of asking someone to "show".
        "sentenceKo": "짧은 ＿＿＿을 하나 볼 수 있어요?", "answer": "예문",
        "fullKo": "짧은 예문을 하나 볼 수 있어요?",
        "de": "Kann ich einen kurzen Beispielsatz sehen?",
        "en": "Can I see one short example sentence?",
    },
    "cloze_a1_0324": {
        "sentenceKo": "주소를 한 번 더 ＿＿＿.", "answer": "확인하세요",
        "fullKo": "주소를 한 번 더 확인하세요.",
        "de": "Bitte prüfen Sie die Adresse noch einmal.",
        "en": "Please check the address once more.",
        "distractors": ["주문하세요", "출발하세요", "닫으세요"],
    },
    "cloze_a1_0331": {
        "sentenceKo": "＿＿＿ 놓으세요.", "answer": "문 앞에",
        "fullKo": "문 앞에 놓으세요.",
        "de": "Bitte stellen Sie es vor die Tür.",
        "en": "Please leave it at the door.",
    },
    "cloze_a1_0332": {
        "sentenceKo": "＿＿＿를 다시 말하세요.", "answer": "주문 번호",
        "fullKo": "주문 번호를 다시 말하세요.",
        "de": "Bitte sagen Sie die Bestellnummer noch einmal.",
        "en": "Please say the order number again.",
    },
}

# satz ids that mirror a VOCAB_REWRITES row 1:1.
SATZ_MIRROR_REWRITES = {
    "satz_a1_0028": ("천 원만 빌릴 수 있어요?", "Kann ich mir nur tausend Won leihen?", "Can I just borrow a thousand won?"),
    "satz_a1_0059": ("다시 천천히 말하세요.", "Bitte sagen Sie es noch einmal langsam.", "Please say it again, slowly."),
    "satz_a1_0069": ("시어머니께서 저를 보고 웃으셨어요.", "Meine Schwiegermutter hat mich angesehen und gelächelt.", "My mother-in-law looked at me and smiled."),
    "satz_a1_0163": ("편지는 아래 우편함에 넣으세요.", "Bitte legen Sie den Brief in den Briefkasten unten.", "Please put the letter in the mailbox downstairs."),
    "satz_a1_0168": ("받는 사람 전화번호를 적으세요.", "Bitte notieren Sie die Telefonnummer des Empfängers.", "Please write the recipient's phone number."),
    "satz_a1_0300": ("잠깐만 여기서 기다리세요.", "Warten Sie bitte hier einen Moment.", "Please wait here for a moment."),
    "satz_b1_0407": ("이 질문에 대답하세요.", "Bitte antworten Sie auf diese Frage.", "Please answer this question."),
    "satz_a1_0315": ("이 단어 발음을 다시 들을 수 있어요?", "Kann ich die Aussprache dieses Wortes noch einmal hören?", "Can I hear the pronunciation of this word again?"),
    "satz_a1_0316": ("짧은 예문을 하나 적으세요.", "Bitte schreiben Sie einen kurzen Beispielsatz auf.", "Please write one short example sentence."),
    "satz_a1_0353": ("실례지만 전화번호가 뭐예요?", "Entschuldigung, wie ist Ihre Telefonnummer?", "Excuse me, what is your phone number?"),
    "satz_a1_0371": ("다시 한번 말하세요.", "Bitte sagen Sie es noch einmal.", "Please say it once more."),
    "satz_a1_0254": ("자리를 양보하셔서 정말 감사해요.", "Vielen Dank, dass Sie den Platz überlassen haben.", "Thank you so much for giving up the seat."),
}

# satz items with no vocab/cloze source.
SATZ_ONLY_REWRITES = {
    "satz_a1_0321": (
        "이름을 종이에 적으세요.",
        "Bitte schreiben Sie den Namen auf das Papier.",
        "Please write the name on the paper.",
    ),
}
