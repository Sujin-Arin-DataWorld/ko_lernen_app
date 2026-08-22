# 근거·코퍼스·인간 검수

자연스러움은 한 사람의 직감이나 병렬 번역 한 줄로 확정하지 않는다.

## 근거 사다리

1. 확정된 원문·장면·메타데이터·제품 용어집
2. 국립국어원 규범·사전·한국어 모국어/학습자 말뭉치
3. 목표어 단일언어 말뭉치와 장르가 맞는 실제 용례
4. 대조·번역·습득 연구와 검증된 병렬 자료
5. 한국어 권위 검수자, EN/DE 원어민, 한국어교육 또는 전문 통역 검수

상위 단계가 답하지 않은 의미를 하위 단계의 빈도로 창작하지 않는다.

## 코퍼스 절차

1. 질문을 먼저 고정한다: 의미, 연어, 장르, 관계, 지역 변이 중 무엇을 확인하는가.
2. `parallel | comparable | monolingual | learner`를 표시한다.
3. 대화·뉴스·문학·UI 등 목표 장르와 `en-US/en-GB`, `de-DE/de-AT/de-CH` 범위를 맞춘다.
4. 한 예문보다 여러 화자·문서의 분포와 반례를 본다.
5. 빈도는 후보 검증에만 쓰고 화행·함축·지시대상 판정은 문맥으로 다시 확인한다.

국립국어원 모두의 말뭉치와 학습자 말뭉치는 한국어 후보·학습자 오류 확인에, IDS Mannheim DeReKo/KorAP은 독일어 장르·연어 확인에 쓴다. 영어는 명시한 목표 지역과 장르의 단일언어 corpus를 선택한다.

말뭉치 이용약관과 재배포 조건을 확인한다. 검색 결과 문장·ID·단원 순서를 앱 학습 데이터로 복제하지 않는다.

## 독립 인간 검수

역할을 섞지 않는다.

- **KO authority:** 원문 의미, 높임 대상, 문화·학습 목표
- **EN native:** 목표 locale의 실제 자연성, 담화 흐름
- **DE native:** 목표 locale, `du/Sie`, 격·관사·V2·양태조사
- **Korean educator:** L1별 오해, CEFR 기능, 문항 유일성
- **Interpreter:** 시간축, 생략, 예측, 복구 가능성

한 검수자가 세 역할을 맡았다는 이유로 독립성이 생기지 않는다. 중요한 세트는 두 명 이상이 blind 판정하고 불일치를 기록·조정한다.

## 평가 설계

최소 회귀 매트릭스는 네 방향 `KO→EN | EN→KO | KO→DE | DE→KO`에서 다음을 교차한다.

```text
REFERENCE | INDEXICAL_HONORIFICS | SPEECH_ACT
DEIXIS | TENSE_ASPECT_MODALITY | INFORMATION_STRUCTURE
EVIDENTIAL_SOURCE_CHAIN | SPEAKER_COMMITMENT | MODAL_FORCE
PRESUPPOSITION | SCALAR_ALTERNATIVES | CULTURAL_RANGE
```

추가로 동시·순차·대화통역에서 부정, 숫자, 늦은 술어, 화자 교대를 시험한다. 원문을 보는 정확성 평가와 목표어만 보는 자연성 평가는 별도 판정자가 수행한다.

각 case는 최소한 다음을 명시한다.

```text
directions; phenomena; query; expected_behavior
forbidden_implications; accepted_variants; unresolved_fields
severity_if_failed; baseline_observation; green_observation
```

`accepted_variants`는 한 문장만 정답으로 만들기 위한 목록이 아니다. 기능상 같은 자연스러운 범위를 보여 준다. `forbidden_implications`는 특정 단어 금지 목록이 아니라 그 case에서 새로 생기면 안 되는 의미다.

## RED→GREEN 평가 절차

1. 기존 스킬로 시간 압박·단일 최종안·짧은 self-audit 조건에서 반복 실행한다.
2. 정확한 출력과 self-audit이 놓친 함의를 함께 baseline으로 기록한다.
3. 새 규칙을 적용한 fresh-context 실행에서 critical 금지 함의가 0인지 본다.
4. 같은 출력에 대해 bilingual adequacy와 target-only naturalness를 분리한다.
5. 기존 회귀 case와 네 방향 coverage를 자동 검증한다.

모델 self-audit은 독립 판정이 아니다. 같은 모델이 만든 번역을 스스로 통과시킨 결과는 failure discovery 자료로 쓰되, GREEN 근거는 별도 fresh-context 검토와 가능한 인간 gate를 요구한다. 자동 통과를 “언어학자 검증 완료”로 표현하지 않는다.
