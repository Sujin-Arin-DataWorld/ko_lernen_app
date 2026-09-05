# Vocab Level Review — Jin 결정 대기 (2026-09-05)

> 생성 경위: brief_x_content T2(d). `tool/audit_vocab_levels.py` 재실행 기준
> (시아버지 A1→B1 재분류 반영 후) `tool/vocab_level_suspects.csv` 358행 중
> blocked(=satz_ref, 레벨을 그냥 옮기면 참조가 끊어짐) 323행이 "남은 의심
> 항목"이다. 이 문서는 그중 **콘텐츠를 수정하지 않고** Jin이 검토할 목록만
> 정리한다. 원본 전체 목록은 `tool/vocab_level_suspects.csv`.
>
> 표시 규칙: "제안 레벨"은 `audit_vocab_levels.py`의 topic 최빈 레벨
> 휴리스틱(`topic_mode[topic]`)이 제안하는 값 — **기계적 통계치일 뿐 사람이
> 검증한 값이 아니다.** below 두 구조적 오탐 그룹에서 보듯, 하나의 topic
> 라벨이 A1~C2 전 레벨에 걸쳐 재사용되는 이 앱의 콘텐츠 구조상 이 휴리스틱은
> 특히 "스토리라인형" topic(같은 인물/서사가 레벨별로 이어지는 팩 묶음)에서 오탐률이 매우 높다.

## 1. 최우선 결정 필요 — 층간소음 (brief 지목)

`vocab_a1_0351` 층간소음(`a1_neighbors_hall_1`, topic `Nachbarschaft`) —
sino3_low 로 플래그, blocked=satz_ref(`satz_a1_0203`). B1 에 동일 topic
(`Nachbarschaft`) 팩이 없어 `tool/relevel_vocab.py` 로 기계적 이동이
불가능하다(임의 팩 생성·타 topic 이동은 브리프 금지 규칙 위반).

**후보 topic 3개** (B1에 이미 존재하는 topic 중, 아파트/이웃 생활 갈등이라는
의미상 가장 근접한 것):

| 후보 topic | B1 기존 팩 | 비고 |
|---|---|---|
| `Wohnen & Vertrag` | `b1_housing_contract_1` (12단어) | 주거·계약 어휘 — 아파트 생활 문제로 자연스럽게 이어짐 |
| `WG-Gespräch` | (동거/룸메이트 대화 팩) | 이웃/동거인과의 생활 소음 갈등이라는 상황이 가장 가까움 |
| `Gesellschaft` | `b1_tech_society_1`/`b1_tech_society_2` | 사회 문제로 넓게 묶는 경우 — 다만 다소 포괄적 |

**Jin 결정**: [ ] 위 3개 중 하나로 topic 을 바꿔 B1 신규/기존 팩에 배치
[ ] `Nachbarschaft` topic 을 B1 에도 신설(다른 이웃 관련 단어가 추가로
필요한지 함께 검토) [ ] 현재 A1 유지(보류)

---

## 2. 구조적 오탐 그룹 — 개별 재검토 불필요 (총 245건)

### 2a. `Partnerschaft & koreanische Familie` 스토리라인 topic (90건 + 별도 문서화된 65건 = 155건)

이 topic 은 A1→C2 전 레벨에 걸쳐 만남·선물·집들이·상차림·설날·추석·형제자매
호칭·사진/인사 등 **의도적으로 레벨별 서사가 이어지는 구조**다(레벨별 8개
팩 × 12단어 등 균등 설계). `topic_mode()` 휴리스틱은 "이 topic 단어 대부분이
어느 레벨에 있는가"만 보므로, 서사 후반(B1 이후)에 단어 수가 많아지면 A1/A2
회차의 정상 어휘가 전부 `below_topic`/`sino3_low`로 오탐된다. `vocab_a1_0216`
(시아버지) 재분류가 정확히 이 tie 를 깨뜨려 65건이 신규로 잡혔고
(`tool/test_audit_vocab_levels.py::KNOWN_TOPIC_TIE_SUSPECT_IDS` 문서화됨),
같은 topic 의 기존 90건(core_blocked, 이번 세션 이전부터 존재)도 동일 원인
이다. **권고: 개별 이동 대신, 이 topic 을 레벨별로 분리된 topic 라벨(예:
`Partnerschaft·A1`, `Partnerschaft·B1`)로 재설계할지 여부를 먼저 결정 —
그 전까지는 이 클러스터 전체를 audit 의심에서 제외하는 것이 합리적.**

### 2b. 그 외 topic, `topic_mode == 현재 레벨` (152건)

레벨 재분류가 필요 없는 경우(제안 레벨이 곧 현재 레벨) — `sino3_low`(3음절
이상 순한글/한자어 명사) 휴리스틱 자체가 원래 프록시일 뿐이라 이 152건은
대부분 정상 분류다. 전체 목록은 `tool/vocab_level_suspects.csv`에서
`blocked=satz_ref` 이고 목록 1(층간소음)·2a(Partnerschaft)·3(아래 표)에
속하지 않는 행.

---

## 3. 개별 검토 후보 (16건) — Jin 체크

`Partnerschaft` 클러스터 밖에서 `topic_mode != 현재 레벨`인 항목. 위 그룹과
같은 이유(범용 topic 라벨의 레벨 간 재사용)로 오탐일 가능성이 높은 것도
섞여 있으니(예: 쉽다/새/다른/같은 — a1_descriptions 팩의 기초 형용사,
전화/문자/인터넷/컴퓨터 — 기초 통신/기기 어휘) 자동이동 대상이 아니라
**Jin 판단이 필요한 항목**으로만 남긴다.

| id | 단어 | 현재→제안 레벨 | blocked 사유 | satz 참조 id | Jin 체크 |
|---|---|---|---|---|---|
| vocab_a1_0071 | 도서관 | A1 → A2 | satz_ref | satz_a1_0331 | [ ] |
| vocab_a1_0126 | 쉽다 | A1 → B1 | satz_ref | satz_a1_0022 | [ ] |
| vocab_a1_0176 | 화이팅 | A1 → B1 | satz_ref | satz_a1_0299 | [ ] |
| vocab_a1_0197 | 새 | A1 → B1 | satz_ref | satz_a1_0055 | [ ] |
| vocab_a1_0198 | 다른 | A1 → B1 | satz_ref | satz_a1_0056 | [ ] |
| vocab_a1_0199 | 같은 | A1 → B1 | satz_ref | satz_a1_0057 | [ ] |
| vocab_a2_0028 | 전화 | A2 → B2 | satz_ref | satz_a2_0255 | [ ] |
| vocab_a2_0029 | 문자 | A2 → B2 | satz_ref | satz_a2_0256 | [ ] |
| vocab_a2_0030 | 인터넷 | A2 → B1 | satz_ref | satz_a2_0257 | [ ] |
| vocab_a2_0031 | 컴퓨터 | A2 → B1 | satz_ref | satz_a2_0258 | [ ] |
| vocab_a2_0043 | 전화하다 | A2 → B2 | satz_ref | satz_a2_0268 | [ ] |
| vocab_a2_0053 | 보내다 | A2 → B2 | satz_ref | satz_a2_0278 | [ ] |
| vocab_a2_0088 | 메뉴판 | A2 → A1 | satz_ref | satz_a2_0010 | [ ] |
| vocab_a2_0136 | 분홍색 | A2 → A1 | satz_ref | satz_a2_0332 | [ ] |
| vocab_a2_0137 | 보라색 | A2 → A1 | satz_ref | satz_a2_0333 | [ ] |
| vocab_a2_0140 | 주황색 | A2 → A1 | satz_ref | satz_a2_0034 | [ ] |

**참고**: 분홍색/보라색/주황색(A2→A1)은 다른 항목들과 달리 "더 쉬운 레벨로
내려가자"는 제안 — Farben(색깔) topic 이 A1 위주라서 나온 결과. 나머지는
전부 "더 어려운 레벨로 올리자"는 제안이며, 위에서 설명한 범용-topic-재사용
오탐 패턴과 구분이 쉽지 않으니 word-by-word 로 판단 필요.
