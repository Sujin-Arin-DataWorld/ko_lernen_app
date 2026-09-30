# Batch 07 문법 교정: 친족 관계와 높임 퀴즈

상태: MODEL_QA_REVIEWED (7개 카드·21개 오답, Standards/Spec 독립 검토). 사람·원어민 검수는 pending이다. 기존 승인, 권리 기록, frozen draft/review는 수정하지 않는다.

기준 소스는 `099f234ca4ef74335a398eb4016214d7385b378c`이다. Batch 07 문법 여섯 행과 그 문항에서 경쟁 정답이 된 기존 `-시-` 한 행을 교정한다. 전체 Batch 07 검증은 다른 미해명 행 때문에 계속 실패해야 한다. 이번 교정을 Batch 07 전체의 언어 검수나 승인으로 해석하지 않는다.

## 실제 문항 계약

`lib/screens/grammar_choice_quiz_screen.dart`는 먼저 DE/EN 예문과 강조 구간을 보여 주고 한국어 문법 네 개 중 하나를 고르게 한다. 한국어 정본과 설명은 답을 고른 뒤 나타난다. 따라서 오답은 강조된 의미를 구현하는 다른 정답이 될 수 없어야 한다. 아래 검토는 한국어 단어를 문장에 무작위로 치환하는 검사가 아니다.

## 교정된 정본과 현지화

| 현재 레벨 · 패턴 | KO | DE | EN |
|---|---|---|---|
| A2 · N께 | 장인어른께 과일을 드렸어요. | Ich habe dem Vater meiner Frau Obst gegeben. | I gave fruit to my wife's father. |
| A2 · V-아/어 드리다 | 할머니께 물을 따라 드렸어요. | Ich habe meiner Großmutter Wasser eingeschenkt. | I poured water for my grandmother. |
| A1 · N께서 | 시어머니께서 먼저 앉으셨어요. | Die Mutter meines Mannes hat sich zuerst gesetzt. | My husband's mother sat down first. |
| B2 · V-기보다 | 바로 거절하기보다 “다음에 말씀드릴게요.”라고 했어요. | Statt direkt abzulehnen, sagte ich: „Ich sage es Ihnen beim nächsten Mal.“ | Rather than directly refusing, I said, “I'll tell you next time.” |
| A1 · V-(으)시- | 할머니께서 신문을 읽으세요. | Meine Großmutter liest Zeitung. | My grandmother is reading the newspaper. |
| C1 · N(이)라는 점에서 | “우리 며느리”라는 말이 환영의 표현이라는 점에서 반갑지만, 제 역할까지 정하는 것 같아 부담스럽기도 해요. | Die Bezeichnung „unsere Schwiegertochter“ freut mich als Ausdruck des Willkommens, setzt mich aber auch unter Druck, weil es so klingt, als würde damit meine Rolle festgelegt. | Being called “our daughter-in-law” pleases me as an expression of welcome, but it also puts pressure on me because it seems to define my role. |
| C2 · N와/과 무관하게 | 혈연과 무관하게 절차를 문서화하자고 했어요. | Unabhängig von der Blutsverwandtschaft schlug ich vor, das Verfahren zu dokumentieren. | Regardless of blood ties, I suggested documenting the procedure. |

장인어른·시어머니의 배우자 쪽 관계와 할머니 관계를 DE/EN에 유지한다. 드리다 설명은 보조 동사의 쓰임을 다루며 행동 주체를 화자로 제한하거나 연장자에게 주다를 무조건 금지하지 않는다. `-시-` 설명에서는 주체 높임과 `에게→께`의 받는 사람 높임을 섞지 않는다. `-기보다`의 일반적인 행동 비교와 이 예문의 완곡한 답변을 구별하고, 말씀드리다를 설명하다로 바꾸지 않는다.

추가 독립 검토에서 C1의 `the frame says`가 불명확한 행위자를 만들고 C2의 `불문하고`가 실제 대체 정답임을 확인했다. C1은 어떤 호칭에 대한 감정인지 명시하고, 환영과 역할 기대의 양가적인 반응을 삼언어에 유지한다. C2는 혈연과 절차의 독립 관계를 유지하면서 `하자고 했어요`의 제안을 복원한다. 기존 레벨을 재승인하거나 CEFR 적합성을 확정하는 변경은 아니다.

## 선택지 21개 의미 검토

이유는 강조된 의미와 비교한 모델의 판단이며 사람 검수를 대체하지 않는다. ID의 과거 레벨 접두어보다 CSV의 현재 `level`을 따른다.

| 정답 · 강조 | 오답 패턴 | 오답인 이유 |
|---|---|---|
| 께 · dem Vater meiner Frau / to my wife's father | V-(으)ㄹ N | 미래에 할 행동으로 명사를 꾸미는 뜻이 아니라 과일을 받은 사람이다. |
| 께 · 동일 | N(이)나 | 받는 사람을 대안 중 하나로 고르거나 나열하지 않는다. |
| 께 · 동일 | V-(으)ㄴ N | 과거 행동을 한 사람을 수식하는 관형절이 아니라 받는 사람을 나타낸다. |
| 드리다 · meiner Großmutter Wasser eingeschenkt / poured water for my grandmother | A-(으)ㄴ가요? / V-나요? | 질문이 아니라 완료한 행동을 진술한다. |
| 드리다 · 동일 | N 중 / V-는 중 | 물을 따르는 도중이라는 뜻이 아니다. |
| 드리다 · 동일 | V-(으)ㄹ 거예요 | 앞으로 할 의도가 아니라 이미 물을 따라 준 행동이다. |
| 께서 · Die Mutter meines Mannes / My husband's mother | V-(으)ㄴ 후에 | 앉은 주체를 가리키며 다른 행동 뒤의 시간 관계가 아니다. |
| 께서 · 동일 | V-(으)려고 | 앉는 목적이나 의도를 나타내지 않는다. |
| 께서 · 동일 | V-기 전에 | 다른 행동 전의 시점을 나타내지 않는다. 먼저는 여기서 앉는 순서이며 강조된 명사구는 주체다. |
| 기보다 · Statt direkt abzulehnen / Rather than directly refusing | -대요/-(이)래요/-냬요/-재요 | 뒤에 인용문이 있어도 강조된 부분은 거절과 다른 답변의 비교이다. 그 부분은 전언의 축약형이 아니다. |
| 기보다 · 동일 | A/V-기에 | 직접 거절했기 때문이라는 원인이 아니라 거절하는 대신 택한 답변이다. |
| 기보다 · 동일 | V-는데도 V-는 척하다 | 실제와 반대되는 행동을 하는 척한다고 말하지 않는다. 답변을 미룬 사실만으로 가장을 단정하지 않는다. |
| 시 · Meine Großmutter / My grandmother | V-기 전에 | 신문 읽기의 주체이며 다른 행동 전의 시간 관계가 아니다. |
| 시 · 동일 | V-(으)려고 | 신문을 읽으려는 목적·의도가 아니라 읽고 있는 사실이다. |
| 시 · 동일 | V-(으)ㄴ 후에 | 다른 행동 뒤의 시간 관계가 아니다. |
| 라는 점에서 · als Ausdruck des Willkommens / as an expression of welcome | V-지 않는 한 | 필요한 조건의 부정형이 아니라 환영의 표현이라는 평가 근거를 제시한다. |
| 라는 점에서 · 동일 | A/V-(으)ㄴ/는 한편 | 문장 전체에는 양가적인 반응이 있지만 강조된 부분은 두 측면의 병존을 잇는 연결이 아니다. |
| 라는 점에서 · 동일 | V-(으)ㄹ 바에야 | 불리한 두 대안 중 다른 행동을 선택하는 뜻이 아니다. |
| 무관하게 · Unabhängig von der Blutsverwandtschaft / Regardless of blood ties | V-(으)리라 여겨지다 | 무엇이 일어날 것이라는 예상이 아니라 혈연과 절차를 분리한다. |
| 무관하게 · 동일 | A/V-(으)ㄴ/는다고 치더라도 | 어떤 사건이 참이라고 가정한 뒤 양보하는 뜻이 아니다. |
| 무관하게 · 동일 | N에 불과하다 | 혈연이 한정된 지위에 지나지 않는다고 평가하지 않는다. 절차와의 독립 관계다. |

`께서`와 `-시-`가 같은 문장의 주체를 높이므로 두 문항 모두에서 상대 형태를 오답에서 뺀다. DE/EN은 문법 설명을 예문 속에 삽입하지 않으므로 한국어 높임 형태를 일대일로 드러내지는 않는다. 선택지의 유일성은 이 네 개 선택지와 강조 구간의 범위에서 판단한다.

C1의 `감안하면`은 같은 평가 근거를 구현할 수 있어 `-지 않는 한`으로 교체한다. C2의 `불문하고`도 `혈연을 불문하고`로 같은 뜻이 되므로 제외한다. C2의 반대쪽 `grammar_c2_regardless_of` 문항에는 `무관하게`가 오답으로 들어 있지 않음을 함께 확인했다.

## 이력의 범위

`tools/content_factory/review/batch_07_grammar_reconciliation_20260916.json`은 최초 승격, 이후 draft/review/live 세 경로의 변경, 이번 변경 전후 해시를 보존한다. 현재 frozen draft에서 현재 live까지 정확히 설명한 문법 여섯 행만 기존 copy revision ledger에 추가한다. `-시-`는 Batch 07 원본 행이 아니므로 관련 교정으로 따로 기록한다.

기존 Batch 07 역사 감사의 827개 미해명 행은 교정 전 기준이다. 기존 네 개 문법 차이의 reconciliation 후 미해명 행은 823개다. C1·C2 두 행은 이번 교정 전에는 draft와 live가 일치했으며, 새 교정만 원장에 추가한다. 역사 manifest 전체는 24개 중 10개 통과·14개 실패다. 권리나 사람 승인 이력이 부족한 행을 baseline 예외로 처리하지 않는다.

문법 정규식 `grammar_patterns.json`은 `g_*` ID의 별도 수작업 자산이며 이 예문 CSV에서 생성되는 파일이 아니다. 두 배포 경로의 일치 검사는 유지한다. 바뀐 한국어 직접 인용 예문의 TTS 키는 현재 corpus와 Storage를 비교해 누락분만 생성한다.

근거: 국립국어원 한국어기초사전 [장인·장인어른](https://krdict.korean.go.kr/eng/dicSearch/SearchView?ParaWordNo=24887&nation=eng), [시어머니](https://krdict.korean.go.kr/eng/dicSearch/SearchView?ParaWordNo=65293&nation=eng), [보조 동사 드리다](https://krdict.korean.go.kr/eng/dicSearch/SearchView?ParaWordNo=59252&nation=eng&nationCode=6). 인용된 사전은 친족 관계·높임 해석의 근거이며 새 문장과 선택지의 사람 승인을 뜻하지 않는다.
