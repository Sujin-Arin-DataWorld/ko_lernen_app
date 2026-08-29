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

정답 유일성을 만들려고 stem에서 오답의 행동을 하나씩 열거하거나 부정하지 않는다. “농담은 하지 않았고, 박수도 치지 않았다”처럼 선택지를 미리 제거하는 설명은 정답이 하나여도 `NAT/ITEM` 약점이다. 실제 장면에서 필요한 정보와 행동을 짧게 보여 주고, 오답은 별도의 전체 문장 대입 감사에서 걸러 낸다.

양태 표지만 비교해서 유일성을 판정하지 않는다. 예를 들어 “오늘 꼭 보내야 해요?”에 “아니요. 마감이 내일로 바뀌었으니 오늘은 보낼 수 있어요.”는 `가능`을 나타내더라도 충분히 자연스러운 답이다. 목표 정답 `보내지 않아도 돼요`와 FORCE가 다르다는 이유만으로 `보낼 수 있어요`를 안전한 오답으로 분류하면 안 된다. 모든 후보를 완성 문장으로 대입하고, 문맥상 가능한 읽기가 하나라도 있으면 교체한다.

## Semantic Diff

후보가 유창해 보여도 다음 형식으로 비교한다.

```text
PRESERVED   유지된 사실·화행·관계
IMPROVED    번역투·연어·명확성 개선
INTRODUCED  새로 생긴 사람·절차·감정·평가
LOST        약해지거나 사라진 modality·인과·문화·학습 목표
SHIFTED     정보 출처·화자 확신·화행 강도가 다른 범주로 이동
PRESUPPOSED 원문이 깔지 않은 이전 상태·계획·척도 대안을 새로 전제
VERDICT     accept | minimal repair | reject | flag
```

## 독립 2단계 감사

1. **Bilingual adequacy:** 원문과 PIVOT을 보며 추가·누락·관계·지시대상·직시·시제/상을 판정한다.
2. **Target-only naturalness:** 원문을 숨기고 실제 목표어 장면에서 번역투·연어·정보 흐름을 판정한다.

세 언어 세트는 마지막에 쌍별로 비교하되 영어를 독일어의 중간 정본으로 쓰지 않는다.

## AUTHOR+AUDIT 장면 사례

```text
동료: 이 정도는 그냥 넘어가도 되지 않을까요? 괜히 일만 커질 것 같은데요.
KO: 그냥 넘기기에는 나중에 더 커질 수도 있을 것 같아요. 지금 공유하는 게 낫지 않을까요?
```

- `REL`: 동등한 동료의 상호 대화라는 Scene Lock이 해요체와 공동 판단형을 지지한다.
- `FORCE`: 사실 공유를 제안할 뿐 특정 상사·신고 절차·의무를 만들지 않는다.
- `CULT`: `백세청풍`은 대사 속 구호가 아니라 불편함보다 정직을 택한 행동의 성찰로 둔다.
- `ITEM`: 열린 생산이면 같은 선택·화행을 보존하는 여러 semantic 변형을 인정한다.

```text
친구: 왜 답이 없어? 화났어?
KO: 지금 답하면 내가 너무 감정적으로 말할 것 같아서. 조금만 생각하고 연락할게.
```

친한 친구라는 관계가 반말을 허가한다. `내가 말을 너무 막 할 것 같아서`와 `말이 너무 세게 나갈 것 같아서`는 같은 자기 조절 화행의 semantic 변형이 될 수 있다. `감정적으로 말할 것 같다`는 발화 방식의 위험이지 실제 분노의 확정이 아니다. `화가 안 났다`거나 이미 심한 말을 했다는 사실은 만들지 않는다. 같은 문장이 직장·서비스 관계면 해요체와 다른 부담 조절이 필요하다.

### 업무 자료 확인 요청

`자료`가 파일·보고서·참고자료·데이터 중 무엇인지, 상대가 상사·동료·외부 관계자인지 따로 잠근다. 관계 이름만 보고 한 문장을 고정하지 않는다.

```text
상사에게 보고서의 내용 검토 요청: 보내 드린 보고서 검토 부탁드립니다.
동료에게 공유 파일 확인 요청: 아까 공유한 파일 한번 확인해 주세요.
외부 관계자에게 첨부물 확인 요청: 첨부해 드린 자료 확인 부탁드립니다.
배포물에 대한 공식 안내: 배포해 드린 자료 확인 부탁드리겠습니다.
```

`자료 확인 부탁드리겠습니다`를 모든 전문 장면의 정답으로 승격하지 않는다. `-겠습니다`는 발표·안내에서 화자의 진행 의지나 정중한 공식을 더할 수 있다. 실질적인 내용 판단이면 `확인`보다 `검토`가 맞을 수 있다. EN과 DE도 `materials/Unterlagen`을 자동 고정하지 말고 `file/Datei`, `report/Bericht`, `reference material/Informationsmaterial`, `data/Daten`를 지시대상에서 직접 고른다.

### 가족의 문 잠그기 알림

```text
나갈 때 문 꼭 잠가 줘.                         부탁
나갈 때 문 잠그는 거 잊으면 안 되는 거 알지?   공유 규칙을 전제한 상기
나갈 때 문 꼭 잠그고 나가 줘. 알겠지?          준수 확인을 더한 단호한 부탁
```

세 문장은 같은 표면적 행동을 말해도 FORCE와 PRESUP이 같지 않다. `알지?`는 이미 합의된 규칙을, `알겠지?`는 상대의 확인·준수를 더 요구한다. 장면에 그 배경이 없으면 단순한 순화형으로 승인하지 않는다. 표준 활용은 `잠가`다.

AUTHOR 계열의 모델 판정은 `MODEL_QA_PASS | FLAG | EVIDENCE_REQUIRED`만 쓴다. 아래 MQM 점수와 critical 0은 인간·원어민·교육자 승인을 뜻하지 않는다.

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
| EVID | 정보 출처·보고 연쇄·화자 보증 | 전언을 직접 확인 사실로 바꾸거나 보고자를 창작 |
| FORCE | 요청·제안·허가·의무·약속의 상호작용 강도 | 선택적 제안을 권한자의 허가나 명령으로 이동 |
| PRESUP | 이전 상태·계획·반복·척도 대안 | `still`에 없는 이동 진행이나 `예정대로`를 추가 |
| INT | 통역 생략·예측·수리 | 문말 술어 전 철회/승인을 확정 |

최종 판정:

```text
critical error > 0  → reject 또는 flag
critical error = 0  → 자연성·교육 품질을 최소 수정으로 개선
```
