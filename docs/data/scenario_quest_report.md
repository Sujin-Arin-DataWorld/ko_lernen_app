# 시나리오 퀘스트 중복 감사 리포트

`python tool/audit_scenario_quests.py` 로 생성 — 직접 편집 금지, 스크립트 재실행으로 갱신한다.

`Hangul Sori 앱 점검 후 개선 사항 지시서.md` §4.15("시나리오공부쪽에 Bau satz 중복되는거 있는지 확인해줘")에 대한 답. **같은 시나리오 안**에서 같은 `type` + 같은 prompt/정답 payload 를 가진 퀘스트가 2개 이상이면 중복으로 본다(정답 payload = `options[correctIndex]`, 오답 순서·설명 텍스트는 비교 제외). 수정은 이 스크립트 범위 밖(W4) — 여기선 검출·리포트만 한다.

## 판정 키 (타입별)

| 퀘스트 타입 | payload |
|---|---|
| hoerverstehen | audioKo + 정답 선택지 |
| luecken | sentence + 정답 선택지 |
| uebersetzen | promptDe + promptEn + 정답 선택지(ko) |
| satzBauen | targetKo (§4.15 가 지목한 Bau-satz 본체) |
| diktat | targetKo |
| particlePop | prefix + suffix + 정답 선택지 |
| batchimDrop | audioKo + targetWord + targetSyllableIndex + 정답 선택지 |

## scenarios_a1.json

0건 — 스캔했으나 중복 없음.

## scenarios_a2.json

0건 — 스캔했으나 중복 없음.

## scenarios_b1.json

0건 — 스캔했으나 중복 없음.

## scenarios_b2.json

0건 — 스캔했으나 중복 없음.

## scenarios_c1.json

0건 — 스캔했으나 중복 없음.

## scenarios_c2.json

0건 — 스캔했으나 중복 없음.

## 미지원 퀘스트 타입

0건 — 스캔된 모든 퀘스트 타입이 지원 목록(batchimDrop, diktat, hoerverstehen, luecken, particlePop, satzBauen, uebersetzen) 안에 있음.

## 데이터 결함 (broken payload)

payload 필드가 하나라도 비어 있어(`None`/`""` — 예: `sentence` 는 있는데 `correctIndex` 가 선택지 범위 밖이라 정답 선택지를 못 뽑음) 중복 비교에서 제외된 퀘스트. 중복과는 별개의 데이터 결함이지만, 판정 불가(None) 인 성분끼리 우연히 뭉쳐 가짜 중복으로 오탐되는 걸 막으려면 애초에 비교 풀에서 빼야 해서 여기 개별로 남긴다(집계만 하고 묻지 않음 — 조용한 누락 방지).

0건.

## 요약

- 스캔한 시나리오: **419개** (샤드 6개: scenarios_a1.json, scenarios_a2.json, scenarios_b1.json, scenarios_b2.json, scenarios_c1.json, scenarios_c2.json)
- 스캔한 퀘스트: **1765개**
- 데이터 결함(payload 필드 누락)으로 비교 제외된 퀘스트: **0개** (아래 "데이터 결함" 절에 개별 나열)
- 미지원 퀘스트 타입으로 제외된 퀘스트: **0개**
- 중복 그룹: **0개** (중복 퀘스트 인스턴스 합계 0개)

### 샤드별 중복 그룹 수

- scenarios_a1.json: 0개
- scenarios_a2.json: 0개
- scenarios_b1.json: 0개
- scenarios_b2.json: 0개
- scenarios_c1.json: 0개
- scenarios_c2.json: 0개

### 퀘스트 타입별 중복 그룹 수

- batchimDrop: 0개
- diktat: 0개
- hoerverstehen: 0개
- luecken: 0개
- particlePop: 0개
- satzBauen: 0개
- uebersetzen: 0개

### §4.15 결론

이번 스캔에서는 `satzBauen`(Bau-satz) 을 포함해 7개 퀘스트 타입 전부 시나리오 내 중복이 **0건**이었다 — §4.15 가 우려한 상황은 이 콘텐츠 스냅샷 시점에는 재현되지 않는다. 판정 키가 정답 payload 만 보고 오답/설명 텍스트를 무시하므로, 오답만 바꿔 복붙한 위장 중복도 여기 포함되면 잡혔을 것이다.

