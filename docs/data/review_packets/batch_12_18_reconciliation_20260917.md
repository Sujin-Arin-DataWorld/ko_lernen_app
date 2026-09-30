# Batch12 문장 교정과 Batch18 연결 이력 검토

판정: **MODEL_QA_REVIEWED / 사람·CEFR 검토 pending**. 문장 및 변경 이력의 검토 범위만 기록한다.

## 실제 변경

- Batch12 smalltalk 7행·26필드 교정. 한국어 3필드, 독일어·영어 23필드.
- 기존 10행의 draft/review/live 이력을 기록하고, 분류 문제가 없는 8행만 정확한 before/after 해시로 원장에 등록한다.
- Batch18은 기존 `c2:job_hunting` 연습 연결 변경 1건만 기록한다. 콘텐츠나 공개 can-do 학습 기록의 소유권은 변경하지 않는다.

## Batch12에서 계속 열린 문제

- `smalltalk_c2_0025`, `smalltalk_c2_0026`: frozen draft는 `daily`, 최초 승격 결과부터 `phone`이다. UI의 phone은 전화 채널을 뜻한다. 새 단원의 의미 적합성은 확인했지만 채널 변경 근거는 확인하지 못해 원장 등록을 보류했다.
- 8개 단원·8개 개념이 frozen manifest와 다르다. 이번에는 이 차이를 기록했으며 해당 학습 목표의 변경 연혁·수준 검토는 마치지 않았다.
- manifest의 provenance/설계 날짜는 2026-08-17이나 기록된 승인·병합 날짜는 2026-08-15다. 어느 콘텐츠를 누가 언제 승인했는지 이번 기록으로 확정할 수 없다.
- 관련 어휘 CSV의 과거 snapshot 3개는 파싱할 수 없었다. 아래 선택 10행의 smalltalk/cloze/satz 이력은 파싱됐지만, 전체 배치의 이력이 완전하다고 주장하지 않는다.
- 따라서 **실제 Batch12 strict validator는 여전히 실패해야 한다**. 최초로 드러나는 실패는 위 phone 분류가 포함된 `smalltalk_c2_0025`다.

## 문장별 교정

### smalltalk_c1_0025

표본 수를 묻는 한국어 주어·부사어를 바로잡고, 결론이 강조됐다는 말을 과도한 일반화라는 평가로 바꾸지 않는다.

- `ko`: 그 영상에 표본이 몇 명이었는지 나와 있었어요?
- `reply.de`: Es wurden keine Zahlen genannt; nur die Schlussfolgerung wurde hervorgehoben.
- `reply.en`: No figures were given; only the conclusion was highlighted.

### smalltalk_c2_0026

경험적 발견을 복원한다. 통계가 없다는 사실에서 실제 구제도 없다는 결론을 내리지 않는다. phone 채널 분류는 별도 미해결이다.

- `de`: Ich habe festgestellt, dass eine Anlaufstelle noch keine wirksame Abhilfe garantiert.
- `en`: I've found that having an appeals channel doesn't necessarily mean you get redress.
- `followUp.ko`: 그 숫자가 없으면 실제로 구제가 되는지 판단하기 어렵죠.
- `followUp.de`: Ohne diese Zahl lässt sich schwer beurteilen, ob tatsächlich Abhilfe geschaffen wird.
- `followUp.en`: Without that figure, it's hard to judge whether people actually get redress.

### smalltalk_c1_0027

줄어든 것이 게임 시간임을 분명히 하고, 연령대에 따른 결론 변화를 확정하지 않고 추론으로 남긴다.

- `reply.en`: I saw a table showing that gaming time had fallen, but there was no change in sleep.
- `followUp.de`: Bei einer anderen Altersgruppe dürfte die Schlussfolgerung auch anders ausfallen.
- `followUp.en`: With a different age group, the conclusion would probably differ too.

### smalltalk_c2_0027

이의 제기 기한을 안내받지 못한 상황과 기한 자체가 없는 상황을 구분한다.

- `followUp.ko`: 기한을 모르면 다투기가 훨씬 어렵죠.
- `followUp.de`: Wenn man die Frist nicht kennt, ist es deutlich schwerer, die Sperre anzufechten.
- `followUp.en`: If you don't know the deadline, it's much harder to challenge the suspension.

### smalltalk_c1_0029

교대 번역, 예상되는 업무 집중과 걱정을 보존한다. 친근한 또래 말투를 현지화 선택으로 사용하되 peer가 du를 입증한다고 주장하지 않는다.

- `de`: Wie viele von euch wechseln sich bei den Übersetzungen für diesen Account ab?
- `safeAlternativeQuestions.0.de`: Holt ihr während eines Comebacks noch mehr Leute dazu?
- `followUp.de`: Gerade dann dürfte am meisten Arbeit anfallen. Das macht mir Sorgen.
- `followUp.en`: That's probably when the workload is heaviest, so I'm worried.

### smalltalk_c1_0030

업무량 제한의 지속 가능성을 경험에서 얻었다는 말투와 시험 기간에 대한 전망을 보존한다. 시간 질문에 개인·팀을 새로 특정하지 않는다.

- `de`: Ich habe gemerkt, dass auch Arbeit, die man gern macht, auf Dauer nur mit einem begrenzten Pensum machbar ist.
- `en`: I've found that even work you enjoy is only sustainable if the workload is capped.
- `safeAlternativeQuestions.0.de`: Wie viele Stunden pro Woche sind dafür fest eingeplant?
- `followUp.de`: So dürfte auch die Prüfungszeit zu schaffen sein.

### smalltalk_c2_0029

관점에 대한 의견 요청과 말이 다듬어진 것을 발견한 경험을 복원하고 close_friend 관계에서 du를 사용한다.

- `de`: Aus wessen Perspektive wird die Geschichte deiner Meinung nach inzwischen erzählt?
- `reply.de`: Mir ist aufgefallen, dass nur meine Version mehrfach überarbeitet wurde.
- `reply.en`: I realized that only my side of the story had been polished several times.
- `safeAlternativeQuestions.0.de`: Hast du auch die Darstellung der anderen Seite gehört?

## 기존 비난 문항 검토

`cloze_c2_0219`와 `satz_c2_0221`의 정답·예문은 그대로 유지한다. 현재 `vocab_c2_0215`의 한국어·독일어·영어 예문과 일치한다.

한국어: 논점보다 특정 개인에 대한 **비난**이 앞서기 시작하면 생산적인 대화가 어려워집니다.

DE: Wenn persönliche Vorwürfe gegen eine bestimmte Person die sachliche Auseinandersetzung verdrängen, wird ein produktives Gespräch schwierig.

EN: When criticism of a specific individual begins to overshadow the issue itself, productive discussion becomes difficult.

검수용 오답 치환이며 학습용 정답 예문이 아니다. 번역이 요구하는 개인에 대한 비난 의미와 대조했다.

- `결집`: 논점보다 특정 개인에 대한 결집이 앞서기 시작하면 생산적인 대화가 어려워집니다.
- `시정`: 논점보다 특정 개인에 대한 시정이 앞서기 시작하면 생산적인 대화가 어려워집니다.
- `소급`: 논점보다 특정 개인에 대한 소급이 앞서기 시작하면 생산적인 대화가 어려워집니다.

세 선택지(결집·시정·소급)는 개인에 대한 비난을 뜻하지 않는다. Satz 오답 타일 `위계가`, `잣대를`도 현재 번역에 맞는 다른 정답을 만들지 않는다. 이 판단은 모델 검토이며 사람의 난도·학습 품질 승인이 아니다.

## Batch18 이력

- 최초 승격: `b8c9dec9ea32da44da8c42f83df3bd6eccf0f129`.
- 실제 연결 변경: `fc0489b65da0e9c11631a37eabd57f22e9e6e3e8`.
- `c2:job_hunting`: `c2_02_technology_public_ethics / concept_c2_accountable_systems`에서 `c2_03_automation_redress / concept_c2_automation_redress`로 변경됐다.
- 현재 구성원 `smalltalk_c2_0042`, `smalltalk_c2_0061`은 이의 제기·검토 권한·재심을 다룬다. 새 단원 연습 연결과 의미가 맞는다.
- 공개된 can-do content reference와 cluster는 기존 소유권을 유지한다. category practice 링크와 별개라는 실제 resolver/Batch19 계약에 따른다.
- 최초 승격·변경 직전·직후·현재 값의 대조다. 모든 중간 이력이나 새로운 사람 승인을 증명하는 기록은 아니다.

## 검증 근거

- [Batch12 exact receipt](../../../tools/content_factory/review/batch_12_reconciliation_20260917.json): 선택 10행의 3개 이력, 최초 승격 차이, 8개 원장 등록, 2개 분류 보류, frozen 11파일 해시, 16개 curriculum 차이.
- [Batch18 exact receipt](../../../tools/content_factory/review/batch_18_routing_reconciliation_20260917.json): 연결 1건, 구성원 2개 및 기존 소유권, frozen 11파일 해시.
- [Batch12 회귀 테스트](../../../tools/content_factory/test_batch12_reconciliation.py): 의미 퇴행, 미등록 행 거부, 등록된 해시에서 벗어난 후속 변경 거부, frozen/미해결 게이트 보존.
- [Batch18 회귀 테스트](../../../tools/content_factory/test_batch18_routing_reconciliation.py): 실제 132행 검증, 다른 연결 거부, 기존 소유권 및 frozen 파일 보존.
