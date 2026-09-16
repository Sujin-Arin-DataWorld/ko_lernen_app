# V2 콘텐츠 재검토 대기열 (relevel 아님)

> 생성: 2026-09-16, "Bible v2 확정 + relevel 1차" PR. `docs/data/level_bible/
> V2_jin_decisions.md` 결정 6·8의 실행 목록이다. 아래 항목들은 **레벨
> 이동(relevel) 대상이 아니다** — 표제어 자체가 재사용 가능한 어휘 단위가
> 아니거나("서사 조각"), 실제 한국어 표현이 아니라 개념을 옮긴 조어처럼
> 읽히는("발명된 시적 명사구") 콘텐츠 품질 문제이기 때문이다. 이 PR은
> **라이브 행을 건드리지 않는다** — 목록만 등재하고, 실제 재작성/대체는
> 콘텐츠 감수자가 배정하는 별도 세션에서 한다.
>
> 출처: `docs/data/level_bible/V2_relevel_candidates.csv`(레벨당 20,
> Q-C 최악불일치 표본). 이 문서는 그 CSV의 `too_hard_or_survival_review`
> 카테고리(55건, §A) + `too_easy_move_down` 중 구/서사 조각 사유가 붙은
> 45건(§B, `too_easy_move_down`이지만 phrase-artifact 표시가 있어
> 이번 relevel 1차에서 제외한 행들 — `docs/CONTENT_LEVEL_BIBLE.md` §0
> 결정 6 참고) + "발명된 시적 명사구" 패턴(§C, 결정 8)을 하나로 묶는다.

## §A `too_hard_or_survival_review` (55건)

Q-C 최악 불일치 중 "너무 어려운데 낮은 레벨에 있음"(delta 대부분 +2~+4,
NIKL 등급이 현재 레벨보다 높음) 표본. 다수가 순수 신뢰도 낮은
사전 폴백 아티팩트(지역/구어 어휘) 이거나, "진행 중인 서사의 냉동
프레임"(예: `작은 정성`·`시누이`·`시동생`)이지 재사용 가능한 어휘
항목이 아니다. 순수 관용구(`취중진담`, 4자성어)도 있다. 처리: **콘텐츠
감수자 수작업 배정**(Jin 결정 6, 자동 규칙 대신 사람 검토를 택함) —
진짜 고빈도 명사(이동 후보)와 서사 조각/관용구(재작성 대상)를 구분해야
한다.

| id | 표제어 | 현재 레벨 | NIKL 등급 | delta | 신뢰도 |
|---|---|---|---|---|---|
| vocab_a1_0011 | 나이 | A1 | 2 | 1 | high |
| vocab_a1_0026 | 핸드폰 | A1 | 2 | 1 | high |
| vocab_a1_0034 | 아빠 | A1 | 2 | 1 | high |
| vocab_a1_0035 | 엄마 | A1 | 2 | 1 | high |
| vocab_a1_0053 | 빨간색 | A1 | 2 | 1 | high |
| vocab_a1_0054 | 파란색 | A1 | 2 | 1 | high |
| vocab_a1_0055 | 초록색 | A1 | 2 | 1 | high |
| vocab_a1_0056 | 노란색 | A1 | 2 | 1 | high |
| vocab_a1_0057 | 흰색 | A1 | 2 | 1 | high |
| vocab_a1_0058 | 검은색 | A1 | 2 | 1 | high |
| vocab_a1_0060 | 생선 | A1 | 2 | 1 | high |
| vocab_a1_0061 | 채소 | A1 | 2 | 1 | high |
| vocab_a1_0066 | 계란 | A1 | 2 | 1 | high |
| vocab_a1_0067 | 차 | A1 | 2 | 1 | high |
| vocab_a1_0084 | 항상 | A1 | 2 | 1 | high |
| vocab_a1_0085 | 가끔 | A1 | 2 | 1 | high |
| vocab_a1_0110 | 서다 | A1 | 2 | 1 | high |
| vocab_a1_0122 | 귀엽다 | A1 | 2 | 1 | high |
| vocab_a1_0124 | 시끄럽다 | A1 | 2 | 1 | high |
| vocab_a1_0129 | 짧다 | A1 | 2 | 1 | high |
| vocab_a1_0239 | 윗목 | A2 | 6 | 4 | low |
| vocab_a1_0240 | 아랫목 | A2 | 6 | 4 | low |
| vocab_a2_0350 | 밤참 | A2 | 6 | 4 | low |
| vocab_a2_0399 | 근력 | A2 | 6 | 4 | high |
| vocab_a2_0096 | 매콤하다 | A2 | 5 | 3 | high |
| vocab_a2_0243 | 왕자 | A2 | 5 | 3 | high |
| vocab_a1_0306 | 사진 전송 | A2 | 5 | 3 | high |
| vocab_a2_0218 | 땅콩 | A2 | 4 | 2 | high |
| vocab_a1_0324 | 일회용 밴드 | A2 | 4 | 2 | high |
| vocab_a1_0329 | 무처방 | A2 | 4 | 2 | medium |
| vocab_a1_0366 | 필기하다 | A2 | 4 | 2 | medium |
| vocab_a1_0391 | 겹쳐 입다 | A2 | 4 | 2 | high |
| vocab_a2_0400 | 유산소 | A2 | 4 | 2 | medium |
| vocab_a2_0403 | 염색 | A2 | 4 | 2 | high |
| vocab_a2_0412 | 손질 | A2 | 4 | 2 | high |
| vocab_b1_0079 | 식단 | B1 | 6 | 3 | high |
| vocab_b1_0250 | 세입자 | B1 | 6 | 3 | low |
| vocab_b1_0255 | 누수 | B1 | 6 | 3 | low |
| vocab_b1_0262 | 우선순위 | B1 | 6 | 3 | high |
| vocab_b1_0266 | 업무 분담 | B1 | 6 | 3 | high |
| vocab_a1_0227 | 작은 정성 | B1 | 6 | 3 | low |
| vocab_a1_0234 | 답례 | B1 | 6 | 3 | high |
| vocab_a1_0286 | 시누이 | B1 | 6 | 3 | low |
| vocab_a1_0287 | 시동생 | B1 | 6 | 3 | low |
| vocab_a2_0306 | 편들다 | B1 | 6 | 3 | high |
| vocab_a2_0310 | 맞장구 | B1 | 6 | 3 | high |
| vocab_a2_0355 | 말실수 | B1 | 6 | 3 | low |
| vocab_b1_0286 | 원격 근무 | B1 | 6 | 3 | high |
| vocab_b1_0291 | 퇴사 | B1 | 6 | 3 | low |
| vocab_b1_0310 | 건배 | B1 | 6 | 3 | low |
| vocab_b1_0311 | 폭음 | B1 | 6 | 3 | low |
| vocab_b1_0317 | 취중진담 | B1 | 6 | 3 | medium |
| vocab_b1_0350 | 이모티콘 과다 | B1 | 6 | 3 | high |
| vocab_b1_0353 | 공백만 보내다 | B1 | 6 | 3 | high |
| vocab_b1_0363 | 선물 분배 | B1 | 6 | 3 | high |

## §B `too_easy_move_down` 중 구/서사 조각 표시 (45건)

CSV에서는 `too_easy_move_down`(NIKL 등급이 현재 레벨보다 낮음)로
분류됐지만 사유 칸이 "복합구/서사 조각 의심(품사구 등급 판정 한계, Q-C
Part1.1) — 학습 단위 자체를 재검토(단순 이동 아님)"인 45건. 이번 relevel
1차는 **단일 표제어(단어 하나) + 고신뢰 + NIKL 등급 근거**인 9건만
적용했고(`docs/CONTENT_LEVEL_BIBLE.md` §0 결정 4·§B.1/§B.2 참고), 이
45건은 표제어 자체가 다어절 구/절이라 relevel 전에 "이 구가 재사용 가능한
학습 단위인가"부터 사람이 판단해야 한다.

| id | 표제어 | 현재 레벨 | NIKL 등급 | delta | 신뢰도 |
|---|---|---|---|---|---|
| vocab_b2_0302 | 혼자 있을 시간이 필요하다 | B2 | 1 | -3 | high |
| vocab_b2_0434 | 사위 사랑 | B2 | 1 | -3 | high |
| vocab_b2_0439 | 시어머니 말씀 | B2 | 1 | -3 | high |
| vocab_b2_0440 | 장인어른 건강 | B2 | 1 | -3 | high |
| vocab_b2_0453 | 아직 아니에요 | B2 | 1 | -3 | high |
| vocab_b2_0455 | 가족 호칭 | B2 | 1 | -3 | high |
| vocab_b2_0458 | 높여 부르다 | B2 | 1 | -3 | high |
| vocab_b2_0462 | 호칭 질문 | B2 | 1 | -3 | high |
| vocab_c1_0021 | 반례를 들다 | C1 | 1 | -4 | high |
| vocab_c1_0049 | 우리 며느리 | C1 | 1 | -4 | high |
| vocab_c1_0037 | 일회성 행사로 끝나다 | C1 | 2 | -3 | high |
| vocab_c1_0050 | 손님으로 두다 | C1 | 2 | -3 | high |
| vocab_c1_0057 | 말의 자리 | C1 | 2 | -3 | high |
| vocab_c1_0060 | 자리를 재협상하다 | C1 | 2 | -3 | high |
| vocab_c1_0111 | 잔여 위험 | C1 | 2 | -3 | high |
| vocab_c1_0143 | 결정 환류 | C1 | 2 | -3 | high |
| vocab_c1_0032 | 잘못된 안심을 주다 | C1 | 3 | -2 | high |
| vocab_c1_0035 | 상황을 계속 갱신하다 | C1 | 3 | -2 | high |
| vocab_c1_0040 | 효과가 눈에 보이다 | C1 | 3 | -2 | high |
| vocab_c1_0041 | 부담을 고르게 나누다 | C1 | 3 | -2 | high |
| vocab_c1_0052 | 역할 언어 | C1 | 3 | -2 | high |
| vocab_c1_0061 | 보이지 않는 일 | C1 | 3 | -2 | high |
| vocab_c1_0063 | 돌봄 부담 | C1 | 3 | -2 | high |
| vocab_c1_0065 | 전통의 선택 | C1 | 3 | -2 | high |
| vocab_c1_0070 | 구조를 바꾸다 | C1 | 3 | -2 | high |
| vocab_c1_0083 | 선택 보고 | C1 | 3 | -2 | high |
| vocab_c1_0089 | 오해 예방 | C1 | 3 | -2 | high |
| vocab_c2_0055 | 말의 위계 | C2 | 1 | -5 | high |
| vocab_c2_0060 | 자리를 문서화하다 | C2 | 2 | -4 | high |
| vocab_c2_0071 | 기억을 재배치하다 | C2 | 2 | -4 | high |
| vocab_c2_0098 | 선택적 기억 | C2 | 2 | -4 | high |
| vocab_c2_0115 | 완곡 금지 | C2 | 2 | -4 | high |
| vocab_c2_0010 | 기준을 명문화하다 | C2 | 3 | -3 | high |
| vocab_c2_0016 | 여백을 남기다 | C2 | 3 | -3 | low |
| vocab_c2_0064 | 호칭의 정치 | C2 | 3 | -3 | high |
| vocab_c2_0068 | 공동 기억 | C2 | 3 | -3 | high |
| vocab_c2_0070 | 이름을 되찾다 | C2 | 3 | -3 | high |
| vocab_c2_0103 | 기념 문장 | C2 | 3 | -3 | high |
| vocab_c2_0122 | 자동 결정 | C2 | 3 | -3 | high |
| vocab_c2_0129 | 제3자 검토 | C2 | 3 | -3 | high |
| vocab_c2_0138 | 모델 버전 | C2 | 3 | -3 | high |
| vocab_c2_0227 | 문지기 담론 | C2 | 3 | -3 | low |
| vocab_c2_0229 | 인구 구조 | C2 | 3 | -3 | high |
| vocab_c2_0004 | 책임 소재를 가리다 | C2 | 4 | -2 | high |
| vocab_c2_0011 | 부작용을 상쇄하다 | C2 | 4 | -2 | high |

두 처리 방향(레벨 안에서 더 자연스러운 단일어로 교체 vs 구 자체를 삭제)
모두 `tool/relevel_vocab.py`/`relevel_bundle.py`(레벨만 이동)로는 처리할
수 없다 — 표제어 텍스트·예문·번역을 다시 쓰는 콘텐츠 저작 작업이라
`docs/data/level_bible/F10_review_lessons.md` 원장 + 콘텐츠 감수자 배정이
필요하다.

## §C "발명된 시적 명사구" 패턴 (Jin 결정 8)

`말의 자리`(C1, §B 목록에 포함)·`전통의 선택`(C1, §B 목록에 포함)·
`말의 위계`(C2, §B 목록에 포함) — 위 §B 표에 이미 있는 3건과, 이번 CSV
표본 밖에서 Q-C 원 감사가 별도로 지목한 `망각의 예절`(C2, 이번
`V2_relevel_candidates.csv` 120건 표본에는 없음 — 별도 확인 필요)을
합쳐 4건. 실제 한국어 관용구가 아니라 개념을 옮긴 조어처럼 읽히는
패턴으로, §D 작성 규칙("한국어가 원문")과 직접 충돌하는 콘텐츠 품질
이슈다. Jin 결정: 등급 이동이 아니라 **콘텐츠 재작성**(실제 한국어
표현으로 교체) 대상으로 분류하고, 전체 C1/C2 표제어를 대상으로 한 전수
스캔은 사람 검토가 필요해 별도 세션으로 발주한다(자동 규칙으로 "발명된
명사구"를 판별하기 어려움).

## §D 시나리오 문법 레벨 경고 (6건)

시나리오는 자기 레벨보다 높은 `grammarIds`를 참조하면 안 된다
(`relevel_bundle.py`의 `_check_scenario_grammar_regressions`가 dry-run마다
경고로 출력). 아래 6건은 이번 relevel 1차(문법 이동 10건, batch `V2G1`)
+ 그 이전 LCP `L2b` 배치(2026-09-07, A1→A2 grammar 이동 6건 중 2건이
아직 미해결)로 발생한 전량이다 — **relevel이 아니라 시나리오 자체의
레벨 재배치 또는 grammarIds 교체가 필요한 콘텐츠 이슈**라 이 PR에서
고치지 않는다.

### D.1 이번 PR(V2G1, 문법 이동)로 새로 발생 — 4건

| 시나리오 | 레벨 | 참조 grammarId | 새 레벨 | 근거(V2G1) |
|---|---|---|---|---|
| `b1_w10_insurance` | b1 | `grammar_b1_whether` | b2 | `docs/CONTENT_LEVEL_BIBLE.md` §0 결정 3(세종 4A 실물, B1→B2) |
| `b2_w10_travel` | b2 | `grammar_b2_despite` | c1 | §0 결정 2(NIKL 5급 태그, B2→C1) |
| `b2_w10_hiring` | b2 | `grammar_b2_despite` | c1 | §0 결정 2(NIKL 5급 태그, B2→C1) |
| `b2_w10_authorities` | b2 | `grammar_b2_negative_consequence` | c1 | §0 결정 2(세종5+NIKL 이중 근거, B2→C1, `-다가는` 우선) |

### D.2 이전 배치(LCP L2b, 2026-09-07)에서 이미 있던 것 — 2건(이번 PR 무관, 재확인만)

`relevel_ledger.json` batch `L2b`가 `grammar_a1_honorific_kke`·
`grammar_a1_or_particle`를 A1→A2로 이미 옮겼을 때(2026-09-07) 남은
경고다 — 코드 주석(`relevel_ledger.py` 상단)에 "co-move the scenario,
hold this move, or drop the scenario's grammarIds reference" 중 어느 것도
그 시점에 적용되지 않고 그대로 남아 있었다. 이번 V2G1 dry-run 로그에도
동일하게 다시 나타나 여기 함께 기록한다.

| 시나리오 | 레벨 | 참조 grammarId(들) | 실제 레벨 |
|---|---|---|---|
| `a1_w10_partner` | a1 | `grammarIds: ['grammar_a1_honorific_kke', 'grammar_a1_polite_request']` — 첫 항목이 문제 | a2 |
| `a1_w10_fandom` | a1 | `grammarIds: ['grammar_a1_or_particle', 'grammar_a1_also_particle']` — 첫 항목이 문제 | a2 |

처리 방향(감수자 결정 필요): 시나리오 자체를 a2로 올리거나(대사 난이도
재검토 필요), 해당 grammarId를 시나리오 대사에서 실제로 쓰지 않는다면
`grammarIds`에서 제거. 6건 모두 `docs/data/relevel_V2G1_report.md`에도
dry-run 경고 원문이 남아 있다.

## 상태

이 PR은 위 세 목록을 등재만 한다. `korean_vocab.csv`의 해당 행은
**변경하지 않았다.** 다음 단계: (1) 콘텐츠 감수자가 §A·§B를 검토해 단순
relevel/재작성/유지를 항목별로 결정, (2) §C 4건은 대체 표현 초안 작성 후
Jin 승인, (3) 결정된 항목은 `tool/relevel_vocab.py`(레벨만) 또는 콘텐츠
저작 스크립트(텍스트 교체 포함)로 다음 batch에서 반영, (4) §D 6건은
시나리오 감수자가 레벨 재배치 또는 grammarIds 교체를 결정.
