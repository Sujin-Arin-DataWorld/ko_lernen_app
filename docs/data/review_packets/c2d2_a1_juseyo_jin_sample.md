# C2d-2 A1 '-아/어 주세요' Rewrite -- Jin Review Sample (round 2, 2026-09-16)

Deterministic pick: 29 rows changed from the TRUE pre-C2d-2 base (1f8416de) to the current final state, sorted by (kind, id), every 4th row (8 shown). Combines round 1 (Jin option a: -아/어 주세요 -> 1급 -으세요/-을 수 있어요?) and round 2 (Jin's authority-vs-request correction: -으세요 stays only when the speaker has situational authority -- clerk/teacher/postal instructions; a learner asking a stranger uses -을 수 있어요?/-을 수 있을까요? or one of exactly 3 closed-list F9 formulas -- 말해 주세요 (다시/천천히/한번/조금 variants), 도와주세요, 적어 주세요).

vocab_a1_0141 (천 원만 빌려주세요.) is DELETED entirely (Jin: "아예 쓰지 말자", 2026-09-16), with its satz mirror satz_a1_0028 -- not rewritten.

## cloze:cloze_a1_0094

- **Before KO:** 천천히 말해 주세요.
- **Before DE:** Bitte sprechen Sie langsam.
- **Before EN:** Please speak slowly.
- **After KO:** 한국어를 잘 못해요. 다시 천천히 말해 주세요.
- **After DE:** Ich spreche noch nicht gut Koreanisch. Bitte sprechen Sie noch einmal langsam.
- **After EN:** I don't speak Korean well yet. Please speak slowly once more.

Jin 판정: ______

## cloze:cloze_a1_0290

- **Before KO:** 자리를 양보해 주셔서 정말 감사해요.
- **Before DE:** Vielen Dank, dass Sie den Platz überlassen haben.
- **Before EN:** Thank you so much for giving up the seat.
- **After KO:** 자리를 양보하셔서 정말 감사해요.
- **After DE:** Vielen Dank, dass Sie den Platz überlassen haben.
- **After EN:** Thank you so much for giving up the seat.

Jin 판정: ______

## cloze:cloze_a1_0367

- **Before KO:** 전화번호를 알려 주세요.
- **Before DE:** Sagen Sie mir bitte Ihre Telefonnummer.
- **Before EN:** Please tell me your phone number.
- **After KO:** 실례지만 전화번호를 알 수 있을까요?
- **After DE:** Entschuldigung, könnte ich Ihre Telefonnummer erfahren?
- **After EN:** Excuse me, could I get your phone number?

Jin 판정: ______

## satz:satz_a1_0163

- **Before KO:** 편지는 아래 우편함에 넣어 주세요.
- **Before DE:** Bitte legen Sie den Brief in den Briefkasten unten.
- **Before EN:** Please put the letter in the mailbox downstairs.
- **After KO:** 편지는 아래 우편함에 넣으세요.
- **After DE:** Bitte legen Sie den Brief in den Briefkasten unten.
- **After EN:** Please put the letter in the mailbox downstairs.

Jin 판정: ______

## satz:satz_a1_0315

- **Before KO:** 이 단어 발음을 다시 들려주세요.
- **Before DE:** Bitte spielen Sie die Aussprache dieses Wortes noch einmal ab.
- **Before EN:** Please play the pronunciation of this word again.
- **After KO:** 이 단어 발음을 다시 들을 수 있어요?
- **After DE:** Kann ich die Aussprache dieses Wortes noch einmal hören?
- **After EN:** Can I hear the pronunciation of this word again?

Jin 판정: ______

## vocab:vocab_a1_0202

- **Before KO:** 잠깐만 기다려 주세요.
- **Before DE:** Warten Sie bitte einen Moment.
- **Before EN:** Please wait a moment.
- **After KO:** 잠깐만 여기서 기다리세요.
- **After DE:** Warten Sie bitte hier einen Moment.
- **After EN:** Please wait here for a moment.

Jin 판정: ______

## vocab:vocab_a1_0316

- **Before KO:** 받는 사람 전화번호를 적어 주세요.
- **Before DE:** Bitte notieren Sie die Telefonnummer des Empfängers.
- **Before EN:** Please write the recipient's phone number.
- **After KO:** 받는 사람 전화번호를 적으세요.
- **After DE:** Bitte notieren Sie die Telefonnummer des Empfängers.
- **After EN:** Please write the recipient's phone number.

Jin 판정: ______

## vocab:vocab_b1_0196

- **Before KO:** 질문에 대답해 주세요.
- **Before DE:** Antworten Sie bitte auf die Frage.
- **Before EN:** Please answer the question.
- **After KO:** 이 질문에 대답하세요.
- **After DE:** Bitte antworten Sie auf diese Frage.
- **After EN:** Please answer this question.

Jin 판정: ______

---

전체 29건 변경 (vocab_a1_0141 삭제 포함).

## Headword-embedded grammar (NOT rewritten -- relevel-to-A2 candidates)

적어 주다/도와주다가 헤드워드 자체에 내장된 행은 예문을 그대로 유지하고 scan_a1_grammar.py의 HEADWORD_EMBEDDED_GRAMMAR에 등록, LCP §F9 재분류 후보로 표시한다.

| kind | id | note |
|---|---|---|
| cloze | `cloze_a1_0442` | mirrors vocab_a1_0508 |
| satz | `satz_a1_0317` | mirrors vocab_a1_0410 |
| satz | `satz_a1_0423` | mirrors vocab_a1_0508 |
| vocab | `vocab_a1_0410` | 적어 주다 embeds -아/어 주다 (nikl grade 2, 표현); relevel-to-A2 candidate (C2d-2, LCP F9) |
| vocab | `vocab_a1_0508` | 도와주다 embeds -아/어 주다 (nikl grade 2, 표현); relevel-to-A2 candidate (C2d-2, LCP F9) |

