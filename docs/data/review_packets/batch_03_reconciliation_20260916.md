# Batch 03: 문법·smalltalk 이력과 표현 교정

MODEL_QA_PASS · 사람 문구 검수 pending. 원본 draft와 기존 사람 승인·권리 기록은 유지한다. 현재 콘텐츠 변경은 문법 2행과 smalltalk 1행이며, 6행의 과거 변경과 문법 연결 2건을 정확한 해시로 대조했다.

정확한 전환: [검증 원장](../../../tools/content_factory/review/batch_03_reconciliation_20260916.json). 원장의 actualAfterSha256은 현재 행, comparisonAfterSha256은 원장으로 설명되는 레벨만 원본 값으로 돌린 비교용 행이다. 내용 변경은 여전히 별도 정확한 해시 검사를 받는다.

형태 확인 참고: [국립국어원 한국어기초사전 나름](https://krdict.korean.go.kr/eng/dicSearch/SearchView?ParaWordNo=38833). 예문은 자체 작성했으며 이 링크로 레벨을 새로 판정하지 않았다.

## grammar_b2_method_dependent

실천 방식에 따라 결과가 달라지는 뜻과 -기 나름이다를 자연스럽게 결합한다. 의문사를 앞에 놓도록 권장하던 note도 고친다.

정답: **V-기 나름이다** (C1)

- KO: 같은 원칙이라도 실제 생활에서 어떤 결과가 나올지는 실천하기 나름이에요.
- DE: Auch beim selben Prinzip fällt das Ergebnis im Alltag unterschiedlich aus, **je nachdem**, wie man es umsetzt.
- EN: Even with the same principle, the outcome in everyday life varies **depending on how** you put it into practice.

기존 오답 3개 유지: V-기 마련이다, V-다가는, N에 관하여.

## grammar_b2_impression_appearance

인상·추정을 나타내는 예문과 세 오답은 유지하며 기존 relevel의 선택지 변경만 정확히 기록한다.

정답: **A/V-(으)ㄴ/는 듯하다** (B2)

- KO: 이 글은 담담한 듯하지만 마지막 문장에 깊은 아쉬움이 남아 있어요.
- DE: Dieser Text **wirkt nüchtern**, doch im letzten Satz bleibt eine tiefe Wehmut zurück.
- EN: This text **seems restrained**, yet the final sentence leaves a deep sense of regret.

기존 오답 3개 유지: A/V-기로서니, N에 비추어 볼 때, V-아/어 봤자.

## grammar_b2_topic_debate

논의의 대상을 나타내는 예문과 세 오답은 유지하며 기존 relevel의 선택지 변경만 정확히 기록한다.

정답: **N을/를 둘러싸고** (B2)

- KO: 새 표현의 사용을 둘러싸고 세대마다 의견이 다를 수 있어요.
- DE: **Rund um die Verwendung** neuer Ausdrücke können die Meinungen zwischen den Generationen auseinandergehen.
- EN: Generations can **disagree over** the use of new expressions.

기존 오답 3개 유지: V-(으)ㄴ/는 셈이다, N을/를 계기로, A/V-다는 점에서.

## grammar_b2_negative_consequence

DE 강조를 판단 근거 명사구에서 부정적 결과를 경고하는 조건절로 맞춘다.

정답: **V-다가는** (C1)

- KO: 상대의 말투만 보고 의도를 단정하다가는 오해가 커질 수 있어요.
- DE: **Wenn man die Absicht nur aus dem Tonfall ableitet**, können Missverständnisse größer werden.
- EN: **If you keep assuming** intent from tone alone, misunderstandings can grow.

기존 오답 3개 유지: V-기 나름이다, N이/가 누구에게 돌아가는지 따져보다, V-기 마련이다.

## smalltalk_b2_0057

대답을 권하는 KO의 초대를 DE/EN에도 유지한다. 후속 반응은 다시 생각한다는 뜻이며 관점을 바꿨다고 단정하지 않는다.

- KO: 이 글에서 읽고 난 뒤에도 가장 오래 남은 부분은 무엇이었어요?
- DE: Welcher Teil dieses Textes ist Ihnen nach dem Lesen am längsten nachgegangen?
- EN: Which part of this text stayed with you the longest after reading?

답변을 권하는 질문

- KO: 그 부분이 어떤 감정을 남겼는지 말해 볼래요?
- DE: Möchten Sie beschreiben, welches Gefühl dieser Teil bei Ihnen hinterlassen hat?
- EN: Would you like to describe the feeling that part left you with?

후속 반응

- KO: 저는 그 여운 때문에 글 전체를 다시 생각하게 됐어요.
- DE: Dieser Nachklang hat mich dazu gebracht, noch einmal über den ganzen Text nachzudenken.
- EN: That lingering impression made me think about the whole text again.

## smalltalk_b2_0062

KO의 말투·어감에 따른 수용 차이를 현재 DE가 보존하므로 현 문장을 유지하고 실제 교정 커밋을 기록한다.

- KO: 온라인에서는 같은 말도 말투와 어감에 따라 전혀 다르게 받아들여질 수 있어요.
- DE: Online kann dieselbe Aussage je nach Tonfall und Nuance ganz unterschiedlich ankommen.
- EN: Online, the same words can be received very differently depending on tone and connotation.

## can-do와 사람 검수

smalltalk_b2_0057의 기존 의미 연결·semanticStatus·reviewRevision 3은 보존한다. 바뀐 문구의 해시와 교정 이전 해시를 남기고 copyReviewStatus는 nativeReviewRequired로 설정했다. 기존 의미 연결의 승인과 새 번역의 사람 검수 완료는 같은 주장이 아니다.

Batch 03의 실제 승격 검증은 126행을 통과했다. 전체 과거 배치는 10/24 통과이며 나머지 14개는 별도 미해결이다.
