# 문법 선택지 8행·24개 의미 검토

상태: MODEL_QA_PASS / 사람 검수 pending. 실제 문항은 DE/EN 예문과 강조 구절을 보고 한국어 패턴을 선택한다. 아래 설명은 모델 검토 근거이며 사람 승인 기록이 아니다.

원본 승격·relevel 전후 해시: [검증 원장](../../../tools/content_factory/review/grammar_quiz_reconciliation_20260916.json). 라이브 교정은 7행이며 1행은 현재 표현을 유지하고 과거 변경 근거만 복원했다.

## grammar_b2_include_total_scope

정답 패턴 (B2): **N까지 포함해서 보면**

- KO: 난방비까지 포함해서 보면 이 집이 더 비쌉니다.
- DE: Wenn man **auch die Heizkosten einbezieht**, ist diese Wohnung teurer.
- EN: Once **heating costs are included**, this apartment is more expensive.

난방비를 추가 항목으로 포함해 비교한다. 비롯해/비롯한처럼 포함을 뜻하는 형태를 경쟁 정답으로 쓰지 않는다.

| 오답 패턴 | 이 문항의 의미와 다른 이유 |
|---|---|
| V-는 바람에 | 예상하지 못한 부정적 원인은 비용 포함 조건과 다르다. |
| V-건 말건 | 대안의 무관함은 난방비를 합산하는 것과 다르다. |
| A/V-(으)ㄴ/는 듯하다 | 불확실한 인상은 포함 조건에 따른 비교 단정과 다르다. |

## grammar_b2_instead_supplement

정답 패턴 (B2): **V-는 대신 N을/를 보완하다**

- KO: 조회수만 세는 대신 지역 행사 참여 자료를 보완합시다.
- DE: **Statt nur Aufrufe zu zählen**, ergänzen wir Daten zur Teilnahme an lokalen Veranstaltungen.
- EN: **Instead of counting views alone**, let's add data on participation in local events.

조회수만 세는 행동을 다른 자료의 보완으로 대체한다. 목표에 그대로 포함된 -는 대신을 오답으로 쓰지 않는다.

| 오답 패턴 | 이 문항의 의미와 다른 이유 |
|---|---|
| V-다고/냐고/라고/자고 하다 | 인용이나 전언이 아니라 직접 제안한다. |
| V-건 말건 | 기존 행동의 시행 여부가 무관하다는 뜻이 아니라 행동을 대체한다. |
| N을/를 비롯한 | 명사 집합에 대표 구성원을 포함하는 뜻이 아니다. |

## grammar_b2_not_by_one_metric

정답 패턴 (B2): **N만으로 판단하기 어렵다**

- KO: 취업률만으로 정착이 잘됐다고 판단하기 어렵습니다.
- DE: Anhand der Beschäftigungsquote **allein lässt sich** gelungene Integration schwer beurteilen.
- EN: From the employment rate **alone, it is hard to judge** whether people have settled in well.

취업률 하나만으로 정착 성공을 판단하기 어렵다는 뜻이다. 같은 결론을 부정하는 -다고 해서 ... 것은 아니다와 경쟁시키지 않는다. EN의 cannot를 KO/DE의 어려움으로 맞춘다.

| 오답 패턴 | 이 문항의 의미와 다른 이유 |
|---|---|
| V-다고/냐고/라고/자고 하다 | 다른 사람의 말을 인용하지 않는다. |
| V-는 바람에 | 예상하지 못한 사건 때문에 생긴 결과를 말하지 않는다. |
| N을/를 계기로 | 새 활동의 계기가 된 사건을 말하지 않는다. |

## grammar_b2_verify_human_review

정답 패턴 (B2): **V-는지 다시 확인하다**

- KO: 탈락한 지원서를 사람이 보는지 다시 확인해야 합니다.
- DE: Wir müssen **erneut prüfen, ob** ein Mensch die aussortierten Bewerbungen ansieht.
- EN: We need to **check again whether** a person reviews the rejected applications.

사람이 지원서를 보는지 확인하는 행위를 다시 한다. 다시가 보는지에 붙어 있던 KO를 패턴과 DE/EN의 재확인 범위에 맞춘다.

| 오답 패턴 | 이 문항의 의미와 다른 이유 |
|---|---|
| V-는 바람에 | 뜻밖의 원인이 아니라 사실 여부를 재확인한다. |
| V-건 말건 | 보건 말건 무관하다는 뜻이 아니라 보는지 확인한다. |
| N을/를 계기로 | 계기가 된 사건을 말하지 않는다. |

## grammar_a2_permission_check_batch20

정답 패턴 (A2): **V-아/어도 괜찮아요?**

- KO: 계약서를 사진으로 찍어도 괜찮아요?
- DE: **Ist es in Ordnung**, wenn ich den Vertrag fotografiere?
- EN: **Is it okay** if I photograph the contract?

계약서 촬영의 허락을 묻는다. 같은 허가 질문인 -아/어도 되다를 오답으로 쓰지 않는다.

| 오답 패턴 | 이 문항의 의미와 다른 이유 |
|---|---|
| V-(으)면 안 되다 | 금지의 조건은 허가를 묻는 Is it okay / Ist es in Ordnung과 다르다. |
| V-아/어 보다 | 직접 시도해 보기는 허가 여부 확인과 다르다. |
| V-거나 | 두 행동의 선택을 말하지 않는다. |

## grammar_a2_preference_soft_batch20

정답 패턴 (A2): **V-(으)면 좋겠어요**

- KO: 관리비가 계약서에 따로 적혀 있으면 좋겠어요.
- DE: **Ich fände es gut**, wenn die Nebenkosten im Vertrag getrennt aufgeführt wären.
- EN: **I would prefer** the maintenance fee to be listed separately in the contract.

계약서에 관리비가 따로 기재되기를 바라는 희망이다. 희망과 가까운 의향 -을래요를 경쟁시키지 않는다.

| 오답 패턴 | 이 문항의 의미와 다른 이유 |
|---|---|
| V-(으)ㄴ/는 것 같다 | 이미 그렇게 보인다는 추측이 아니라 바라는 조건이다. |
| V-(으)면 안 되다 | 금지하지 않고 희망을 말한다. |
| V-거나 | 두 행동의 대안을 나열하지 않는다. |

## grammar_b1_conceded_context_batch20

정답 패턴 (B1): **A/V-기는 한데**

- KO: 근무지는 가깝기는 한데 출근 시간이 너무 빨라요.
- DE: Der Arbeitsort **ist zwar nah, aber** der Arbeitsbeginn ist sehr früh.
- EN: The workplace is close, **but** the start time is very early.

근무지가 가깝다는 점을 인정하면서 이른 출근 시간을 단점으로 덧붙인다. 같은 양보 대조인 -기는 하지만을 오답으로 쓰지 않는다.

| 오답 패턴 | 이 문항의 의미와 다른 이유 |
|---|---|
| V-아/어 놓다 | 미리 해 놓은 결과 상태가 아니다. |
| V-다 보면 | 계속 행동하면 나올 미래 결과를 말하지 않는다. |
| V-다 보니 | 반복하다가 알게 된 결과가 아니다. |

## grammar_b1_tentative_plan_batch20

정답 패턴 (B1): **V-(으)ㄹ까 하다**

- KO: 조건을 더 확인한 뒤에 지원할까 합니다.
- DE: **Ich denke darüber nach**, mich nach Klärung der Bedingungen zu bewerben.
- EN: **I'm thinking of** applying after clarifying the conditions.

조건 확인 후 지원할지를 생각 중인 잠정 계획이다. 기존 세 오답은 유지한다.

| 오답 패턴 | 이 문항의 의미와 다른 이유 |
|---|---|
| A/V-(으)ㄴ/는 편이다 | 반복되는 성향이 아니라 아직 확정하지 않은 지원 계획이다. |
| V-(으)ㄴ 김에 | 이미 다른 일을 하는 기회에 덧붙이는 행동이 아니다. |
| V-는 데 걸리다/들다 | 지원에 소요되는 시간이나 비용을 말하지 않는다. |
