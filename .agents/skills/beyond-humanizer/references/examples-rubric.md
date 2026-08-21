# 대조 사례와 평가 루브릭

## 좋은 판정은 형태가 아니라 기능을 고정한다

### 권한과 상향 처리

```text
KO  금액이 제 권한을 넘어서 위로 올려야 해요.
```

권한 종류와 절차가 불명확할 때:

```text
DE  Für einen Betrag in dieser Höhe reichen meine Befugnisse nicht aus. Deshalb muss ich die Angelegenheit an die zuständige Stelle weiterleiten.
EN  This amount is beyond what I'm authorized to handle, so I need to escalate it.
```

문맥이 approval을 허가할 때:

```text
DE  Der Betrag liegt außerhalb meiner Entscheidungsbefugnis. Ich muss ihn zur Freigabe weiterleiten.
EN  This amount is beyond my approval authority, so I need to send it up for approval.
```

거절:

- `nach oben / it has to go up`: 공간 은유만 남아 기능이 불명확
- `run it by my manager`: manager와 consultation 창작
- `someone who can sign it off`: 역할과 sign-off 절차 창작
- `darf ich nicht`: 권한 범위를 금지로 이동할 수 있음

승인 문맥이 확실하지 않으면 approval을 단정하지 말고 `zuständige Stelle / appropriate person`처럼 기능 중립적으로 쓰거나 flag한다.

### 문화적 애착

```text
KO  처음에는 어색했지만 자주 만나면서 정이 들었어요.
EN  At first, things felt awkward, but as we kept meeting, I grew fond of them.
DE  Am Anfang war es noch etwas ungewohnt, aber je öfter wir uns trafen, desto mehr wuchsen wir einander ans Herz.
```

`정`을 love, loyalty, Gemeinschaftsgefühl 한 단어로 고정하지 않는다. 이 장면의 시간에 따른 애착 형성을 재구성한다.

### 높임 축 분리

```text
선생님이 지금 오세요.
```

- `-시-`: 문장 속 주체인 선생님을 높임
- `-요`: 청자에게 쓰는 공손한 말끝
- `-시- = Sie/formal`이라고 가르치지 않음

EN 설명은 영어에 두 기능을 가르는 동일한 어미가 없음을 짚고, DE 설명은 `Sie`가 청자 호칭이라 `-시-`와 같지 않음을 짚을 수 있다.

### Cloze 유일성과 품질

```text
현우의 말에 “맞아, 맞아” 하면서 계속 ＿＿＿를 쳤어요.
정답: 맞장구
```

`박수`는 `박수를 치다`가 자연스러워 대체 정답 위험이 있다. `대화`처럼 `치다`와 결합하지 않는 단어만 모으면 너무 쉽게 형태로 푼다. 같은 품사·형태로 보이되 이 문맥 단서에는 맞지 않는 오답을 설계한다.

## Semantic Diff

후보가 유창해 보여도 다음 형식으로 비교한다.

```text
PRESERVED   유지된 사실·화행·관계
IMPROVED    번역투·연어·명확성 개선
INTRODUCED  새로 생긴 사람·절차·감정·평가
LOST        약해지거나 사라진 modality·인과·문화·학습 목표
VERDICT     accept | minimal repair | reject | flag
```

## 독립 2단계 감사

1. **Bilingual adequacy:** 원문과 PIVOT을 보며 추가·누락·관계·지시대상·직시·시제/상을 판정한다.
2. **Target-only naturalness:** 원문을 숨기고 실제 목표어 장면에서 번역투·연어·정보 흐름을 판정한다.

세 언어 세트는 마지막에 쌍별로 비교하되 영어를 독일어의 중간 정본으로 쓰지 않는다.

## MQM 확장 루브릭

각 축을 1–5로 볼 수 있지만 critical error는 평균으로 상쇄하지 않는다.

| 축 | 5 | critical fail 예 |
|---|---|---|
| Accuracy | 사실·극성·modality·인과 완전 보존 | 추가, 누락, 의미 역전 |
| Naturalness | 해당 장면에서 수정 없이 사용 가능 | 심한 번역투·오해 |
| Pragmatics | 같은 화행·함축·감정 온도 | 부탁→명령, 지지→동의 |
| Relationship | 높임·거리·호칭 적합 | 주체/청자 높임 역전 |
| Culture | 개념과 기능을 균형 있게 중개 | 문화 삭제·고정관념 |
| Terminology | 도메인·표제어 정확 | 전문어 일반화·범주 혼동 |
| CEFR | 목표 레벨의 수행 기능에 적합 | 희귀어로만 난도 위장 |
| Item | 목표 선명, 정답 유일, 오답 품질 | 복수 정답·target 소실 |
| Data | schema와 연결 계약 보존 | 중복 key·ID, U+FFFD |

한글소리 확장 오류 코드:

| 코드 | 범위 | critical fail 예 |
|---|---|---|
| REF | 지시대상·성별·수·한정성 | 생략된 주어를 특정 인물로 창작 |
| INDEX | 주체/객체/청자 높임과 사회적 지표성 | `-시-`를 일반 공손 표지로 설명 |
| DEIX | 직시 중심·관점·이동 경로 | `come`을 장면 확인 없이 `오다`로 고정 |
| TAM | 시제·상·양태·사건 경계 | 계속 거주를 종료된 과거로 번역 |
| INT | 통역 생략·예측·수리 | 문말 술어 전 철회/승인을 확정 |

최종 판정:

```text
critical error > 0  → reject 또는 flag
critical error = 0  → 자연성·교육 품질을 최소 수정으로 개선
```
