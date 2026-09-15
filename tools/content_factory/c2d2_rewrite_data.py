# -*- coding: utf-8 -*-
"""C2d-2 rewrite content table (2026-09-16) -- hand-authored replacements
for the 38 DOCUMENTED_EXCEPTIONS rows left open by C2d (PR #339) plus
vocab_a1_0402 (and its cloze/satz mirrors cloze_a1_0290/satz_a1_0254,
found by exact-text match, not originally listed by id but the same
'-아/어 주셔서' family). Jin's 2026-09-16 ruling (option a): rewrite the
'-아/어 주세요' benefactive-REQUEST family with 1급 -으세요 (honorific
imperative) or, where a bare imperative reads awkwardly without the
benefactive nuance, soften into a first-person '-을 수 있어요?' question
(both in docs/CONTENT_LEVEL_BIBLE.md §B.1's 45-item table).

Round 2 (2026-09-16, same day, after Jin sampled the round-1 rewrite):
bare -으세요 reads too blunt when the LEARNER is the one asking a
STRANGER for something. Fable's authority rule -- -으세요 imperatives stay
fine when the SPEAKER has situational authority / gives instructions
(clerk, teacher, postal-form instructions: 넣으세요/적으세요/대답하세요/
기다리세요); a learner->stranger REQUEST instead uses either the soft 1급
"-을 수 있어요?/-을 수 있을까요?" question, or one of exactly 3 closed-list
lexicalized A1 request formulas (see scan_a1_grammar.py's
A1_REQUEST_FORMULAS): "말해 주세요" (with 다시/천천히/한번/조금 modifiers),
"도와주세요", "적어 주세요". Productive -아/어 주다 otherwise stays A2.
This reverts 3 rows (vocab_a1_0409/satz_a1_0316, cloze_a1_0319,
satz_a1_0321) back to their pre-C2d-2 "-아/어 주세요" text verbatim (now
F9-approved, not a violation) and rewrites the rest that were genuine
learner->stranger requests without a closed-list verb into the soft
question form. vocab_a1_0141 (천 원만 빌려주세요) is REMOVED entirely per
Jin's "아예 쓰지 말자" -- see c2d2_delete_vocab_a1_0141.py.

Noun + lexical 주다 ("물 주세요") is out of scope -- 주다 is itself a 1급
main verb; none of these rows are that shape.

vocab_a1_0410 (headword "적어 주다") and vocab_a1_0508 (headword
"도와주다") are EXCLUDED here -- the headword itself embeds -아/어 주다, so
each example is kept verbatim (see scan_a1_grammar.py's
HEADWORD_EMBEDDED_GRAMMAR and docs/data/a1_grammar_scan_2026-09-15.md's
relevel-to-A2 candidates section). Their satz/cloze mirrors are excluded
for the same reason.
"""

VOCAB_REWRITES = {
    # id: (new_example_korean, new_example_german, new_example_english)
    # NOTE: vocab_a1_0141 (천 원만 빌려주세요) is REMOVED, not rewritten --
    # see c2d2_delete_vocab_a1_0141.py. No entry here on purpose.
    "vocab_a1_0202": (
        # 기다리세요 is on Fable's authority-fine list (postal/service-desk
        # "please wait" instruction) -- kept as -으세요, unchanged from
        # round 1.
        "잠깐만 여기서 기다리세요.",
        "Warten Sie bitte hier einen Moment.",
        "Please wait here for a moment.",
    ),
    "vocab_a1_0203": (
        # Round 2: learner asking a STRANGER to slow down is a REQUEST, not
        # an authority instruction -- bare -으세요 was too blunt (Jin
        # sample feedback). Closed-list formula "말해 주세요" (다시/천천히
        # variants combined) plus an apologetic opener (Jin's exact text;
        # 서투르다 is not grade 1, so 잘 못해요 instead).
        "한국어를 잘 못해요. 다시 천천히 말해 주세요.",
        "Ich spreche noch nicht gut Koreanisch. Bitte sprechen Sie noch einmal langsam.",
        "I don't speak Korean well yet. Please speak slowly once more.",
    ),
    "vocab_b1_0196": (
        # 대답하세요 is on Fable's authority-fine list (teacher/quiz
        # instruction) -- kept as -으세요, unchanged from round 1.
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
        # 넣으세요 is on Fable's authority-fine list (postal-form
        # instruction) -- kept as -으세요, unchanged from round 1.
        "편지는 아래 우편함에 넣으세요.",
        "Bitte legen Sie den Brief in den Briefkasten unten.",
        "Please put the letter in the mailbox downstairs.",
    ),
    "vocab_a1_0316": (
        # 적으세요 is on Fable's authority-fine list (postal-form
        # instruction, this exact sentence) -- kept as -으세요, unchanged
        # from round 1.
        "받는 사람 전화번호를 적으세요.",
        "Bitte notieren Sie die Telefonnummer des Empfängers.",
        "Please write the recipient's phone number.",
    ),
    "vocab_a1_0408": (
        # Already the soft -을 수 있어요? question form (learner asking to
        # hear the pronunciation again) -- 들려주다 is not on the 3-item
        # closed list, so this stays a soft question, unchanged from
        # round 1.
        "이 단어 발음을 다시 들을 수 있어요?",
        "Kann ich die Aussprache dieses Wortes noch einmal hören?",
        "Can I hear the pronunciation of this word again?",
    ),
    "vocab_a1_0409": (
        # Round 2 REVERT: this is a learner asking someone (a tutor/native
        # speaker) to write an example sentence -- "적어 주세요" is one of
        # the 3 closed-list F9 formulas, so the original pre-C2d-2 text is
        # restored verbatim rather than rewritten to -으세요.
        "짧은 예문을 하나 적어 주세요.",
        "Bitte schreiben Sie einen kurzen Beispielsatz auf.",
        "Please write down one short example sentence.",
    ),
    "vocab_a1_0438": (
        # Round 2: learner asking a STRANGER for their phone number is a
        # REQUEST, not on the closed list (알려주다 is a lexicalized
        # compound, but NOT one of the 3 approved formulas) -- soften into
        # the -을 수 있을까요? question. Jin's exact text used 핸드폰 번호,
        # but 핸드폰 is not in nikl_kiiq_2017_vocab.csv grade 1 at all
        # (checked; 전화번호 is grade 1) -- substituted 전화번호, matching
        # this row's own headword.
        "실례지만 전화번호를 알 수 있을까요?",
        "Entschuldigung, könnte ich Ihre Telefonnummer erfahren?",
        "Excuse me, could I get your phone number?",
    ),
    "vocab_a1_0456": (
        # Round 2 REVERT: learner asking a stranger to repeat themselves --
        # "말해 주세요" (다시 한번 variant) is one of the 3 closed-list F9
        # formulas, so the original pre-C2d-2 text is restored verbatim.
        "다시 한번 말해 주세요.",
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
        "answer": "천천히", "sentenceKo": "한국어를 잘 못해요. 다시 ＿＿＿ 말해 주세요.",
        "fullKo": "한국어를 잘 못해요. 다시 천천히 말해 주세요.",
        "de": "Ich spreche noch nicht gut Koreanisch. Bitte sprechen Sie noch einmal langsam.",
        "en": "I don't speak Korean well yet. Please speak slowly once more.",
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
        # particle after the blank changed 가->를 (전화번호 is vowel-final,
        # both are grammatical, but the new sentence's object position
        # takes 를: "전화번호를 알 수 있을까요?").
        "answer": "전화번호", "sentenceKo": "실례지만 ＿＿＿를 알 수 있을까요?",
        "fullKo": "실례지만 전화번호를 알 수 있을까요?",
        "de": "Entschuldigung, könnte ich Ihre Telefonnummer erfahren?",
        "en": "Excuse me, could I get your phone number?",
    },
    "cloze_a1_0390": {
        # Round 2 REVERT.
        "answer": "다시", "sentenceKo": "＿＿＿ 한번 말해 주세요.",
        "fullKo": "다시 한번 말해 주세요.",
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
        # Round 2: closed-list formula "말해 주세요" (다시 변형). Text
        # reverts to exactly C2c's own pre-C2d-2-round-1 fullKo (415d426e)
        # -- restore C2c's already-correct D3-passing re-pick
        # (['보다','팔다','에서'], PREDICATE_SLOT_WAIVER shape: 2
        # dictionary-form verbs + 1 bare particle) rather than the stale
        # pre-C2c set ['빨리','조용히','먼저'] my round-1 draft carried
        # over, which fails audit_cloze_distractors.py's D3 check (both
        # 조용히/먼저 are POS-unresolved against answer "다시"=Adverb).
        "sentenceKo": "죄송하지만 ＿＿＿ 말해 주세요.", "answer": "다시",
        "fullKo": "죄송하지만 다시 말해 주세요.",
        "de": "Entschuldigung, bitte sagen Sie es noch einmal.",
        "en": "Sorry, please say that again.",
        "distractors": ["보다", "팔다", "에서"],
    },
    "cloze_a1_0317": {
        # Round 2: closed-list formula "말해 주세요" (천천히 variant).
        "sentenceKo": "조금 ＿＿＿ 말해 주세요.", "answer": "천천히",
        "fullKo": "조금 천천히 말해 주세요.",
        "de": "Bitte sprechen Sie etwas langsamer.",
        "en": "Please speak a little more slowly.",
        "distractors": ["같이", "아직", "자주"],
    },
    "cloze_a1_0319": {
        # Round 2 REVERT: closed-list formula "적어 주세요" -- answer and
        # distractors restored to their pre-C2d-2 shape (other "-아/어
        # 주세요" verb forms, not -(으)세요).
        "sentenceKo": "이름을 ＿＿＿.", "answer": "적어 주세요",
        "fullKo": "이름을 적어 주세요.",
        "de": "Bitte schreiben Sie den Namen auf.",
        "en": "Please write the name down.",
        "distractors": ["읽어 주세요", "들어 주세요", "열어 주세요"],
    },
    "cloze_a1_0320": {
        # 보여주다 ("show") has no bare-imperative substitute without
        # 주다 and is not on the 3-item closed list -- stays the soft
        # -을 수 있어요? question, unchanged from round 1.
        "sentenceKo": "짧은 ＿＿＿을 하나 볼 수 있어요?", "answer": "예문",
        "fullKo": "짧은 예문을 하나 볼 수 있어요?",
        "de": "Kann ich einen kurzen Beispielsatz sehen?",
        "en": "Can I see one short example sentence?",
    },
    "cloze_a1_0324": {
        # Round 2: 다시 묻기 (clarify/repair) topic -- learner asking a
        # clerk to double-check, not authority-instruction; 확인하다 is not
        # on the closed list, so softened into -을 수 있어요?.
        "sentenceKo": "주소를 한 번 더 ＿＿＿?", "answer": "확인할 수 있어요",
        "fullKo": "주소를 한 번 더 확인할 수 있어요?",
        "de": "Können Sie die Adresse noch einmal überprüfen?",
        "en": "Can you check the address once more?",
        "distractors": ["주문할 수 있어요", "출발할 수 있어요", "닫을 수 있어요"],
    },
    "cloze_a1_0331": {
        # Round 2: 결제와 배달 (payment/delivery) topic -- customer asking a
        # delivery driver, not authority-instruction; 놓다 is not on the
        # closed list, so softened into -을 수 있어요?.
        "sentenceKo": "＿＿＿ 놓을 수 있어요?", "answer": "문 앞에",
        "fullKo": "문 앞에 놓을 수 있어요?",
        "de": "Können Sie es vor die Tür stellen?",
        "en": "Can you leave it at the door?",
    },
    "cloze_a1_0332": {
        # Round 2: closed-list formula "말해 주세요" (다시 variant).
        "sentenceKo": "＿＿＿를 다시 말해 주세요.", "answer": "주문 번호",
        "fullKo": "주문 번호를 다시 말해 주세요.",
        "de": "Bitte sagen Sie die Bestellnummer noch einmal.",
        "en": "Please say the order number again.",
    },
}

# satz ids that mirror a VOCAB_REWRITES row 1:1.
SATZ_MIRROR_REWRITES = {
    # NOTE: satz_a1_0028 (mirrors deleted vocab_a1_0141) is REMOVED, not
    # rewritten -- see c2d2_delete_vocab_a1_0141.py. No entry here.
    "satz_a1_0059": ("한국어를 잘 못해요. 다시 천천히 말해 주세요.", "Ich spreche noch nicht gut Koreanisch. Bitte sprechen Sie noch einmal langsam.", "I don't speak Korean well yet. Please speak slowly once more."),
    "satz_a1_0069": ("시어머니께서 저를 보고 웃으셨어요.", "Meine Schwiegermutter hat mich angesehen und gelächelt.", "My mother-in-law looked at me and smiled."),
    "satz_a1_0163": ("편지는 아래 우편함에 넣으세요.", "Bitte legen Sie den Brief in den Briefkasten unten.", "Please put the letter in the mailbox downstairs."),
    "satz_a1_0168": ("받는 사람 전화번호를 적으세요.", "Bitte notieren Sie die Telefonnummer des Empfängers.", "Please write the recipient's phone number."),
    "satz_a1_0300": ("잠깐만 여기서 기다리세요.", "Warten Sie bitte hier einen Moment.", "Please wait here for a moment."),
    "satz_b1_0407": ("이 질문에 대답하세요.", "Bitte antworten Sie auf diese Frage.", "Please answer this question."),
    "satz_a1_0315": ("이 단어 발음을 다시 들을 수 있어요?", "Kann ich die Aussprache dieses Wortes noch einmal hören?", "Can I hear the pronunciation of this word again?"),
    "satz_a1_0316": ("짧은 예문을 하나 적어 주세요.", "Bitte schreiben Sie einen kurzen Beispielsatz auf.", "Please write one short example sentence."),  # round 2 revert
    "satz_a1_0353": ("실례지만 전화번호를 알 수 있을까요?", "Entschuldigung, könnte ich Ihre Telefonnummer erfahren?", "Excuse me, could I get your phone number?"),
    "satz_a1_0371": ("다시 한번 말해 주세요.", "Bitte sagen Sie es noch einmal.", "Please say it once more."),  # round 2 revert
    "satz_a1_0254": ("자리를 양보하셔서 정말 감사해요.", "Vielen Dank, dass Sie den Platz überlassen haben.", "Thank you so much for giving up the seat."),
}

# satz items with no vocab/cloze source.
SATZ_ONLY_REWRITES = {
    "satz_a1_0321": (
        # Round 2 REVERT: vocabKo field on this row is literally "적어
        # 주다" and courseUnitId is a1_08_clarify_repair -- closed-list
        # formula, original pre-C2d-2 text restored verbatim.
        "이름을 종이에 적어 주세요.",
        "Bitte schreiben Sie den Namen auf das Papier.",
        "Please write the name on the paper.",
    ),
}
