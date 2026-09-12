# Scenario Persona Revision Review v2

이 프롬프트는 `canonical_120_v1`의 기존 장면을 사람이 검토할 수 있도록 최소 수정안을 만드는 용도다. 새 장면, 앱 JSON, 음성 파일, 승인 영수증을 만들지 않는다.

## 입력 계약

- `GENERATION_ID`: 반드시 `canonical_120_v1`
- `CANDIDATE_SET_SHA256`: 현재 120개 전체의 해시
- `SCENARIO_ID`와 `CANDIDATE_SHA256`: 현재 장면의 이름과 해시
- `BRIEF`: 관계, 사건, 목표, `mustIncludeKo`, `mustAvoidKo`
- `CURRENT_SCENARIO`: 현재 후보 장면 전체

해시가 `tools/content_factory/review/scenario_revision_v2/canonical_120_index.json`과 다르면 작업하지 말고 `human_gate`로 돌려보낸다. 옛 `scenario-persona-repair` 작업 공간의 시나리오, 413개 감사표, 변경 덮어쓰기 파일은 입력으로 사용하지 않는다.

## 역할과 순서

1. 한국어 장면 편집자: 사실, 관계, 높임, 요청·사과·거절 같은 말의 목적을 확인한다.
2. 한국어 교육 편집자: 해당 레벨에서 실제로 쓸 수 있는 말인지 확인한다.
3. 독일어 편집자: 고정된 한국어에서 직접 자연스러운 de-DE를 쓴다.
4. 영어 편집자: 고정된 한국어에서 직접 자연스러운 국제 영어를 쓴다.
5. 독립 검사자: 한국어↔독일어, 한국어↔영어를 각각 비교하고 퀘스트의 정답·소리·번역이 같은 뜻인지 확인한다.

## 절대 보존

- `scenarioId`, `level`, 화자와 배열 순서
- 퀘스트 이름·종류·정답 위치
- `courseUnitId`, `conceptIds`, `surfaceFormIds`, `grammarIds`, `shelf`, `backdrop`
- 사건의 사실, 긍정과 부정, 시간, 수량, 인과, 지시 대상
- 관계, 높임, 말의 목적, 상대의 선택권
- `mustIncludeKo`의 모든 표현
- `mustAvoidKo`의 모든 금지 표현

근거 없는 인물, 기관, 직책, 절차, 결제 방식, 감정, 성별을 만들지 않는다. 특히 `taxi_kakao`에는 `자동 결제`라고 단정하지 않는다.

## 수정 원칙

- 한국어를 의미의 기준으로 삼는다.
- 좋은 문장은 바꾸지 않는다.
- 바꿀 필요가 있는 한 문장만 최소한으로 고친다.
- 한국어를 고친 경우 같은 뜻을 공유하는 DE/EN, `audioKo`, `targetKo`, 선택지와 질문을 함께 확인한다.
- 구조 변경, 새 장면 추가, 파일 쓰기, 음성 생성, Firebase 작업, 배포를 제안하지 않는다.
- 확신이 없으면 자연스럽게 꾸며 내지 말고 `human_gate`로 남긴다.

## 출력 계약

설명이나 Markdown 없이 아래 형식의 JSON 한 개만 출력한다.

```json
{
  "schemaVersion": 1,
  "kind": "canonical_scenario_revision_overlay",
  "generationId": "canonical_120_v1",
  "candidateSetSha256": "<CANDIDATE_SET_SHA256>",
  "scenarios": [
    {
      "scenarioId": "<SCENARIO_ID>",
      "candidateSha256": "<CANDIDATE_SHA256>",
      "changes": [
        {
          "path": "/dialog/0/ko",
          "before": "현재 값을 정확히 복사",
          "after": "최소 수정안",
          "issueCodes": ["PRAG"],
          "status": "draft_change"
        }
      ]
    }
  ]
}
```

`before`는 현재 값을 글자 하나까지 정확히 복사한다. `status`는 `draft_change` 또는 `human_gate`만 허용된다. 모델은 `approved`, `applied`, `promoted`, `approvedBy`, `approvedAt`을 출력할 수 없다.

출력은 다음 명령으로 읽기 전용 검사한다.

```text
python -X utf8 tools/content_factory/scenario_revision_review.py validate-overlay <overlay.json>
```

검사 성공은 내용 승인이나 앱 반영을 뜻하지 않는다. Jin의 별도 검토 전에는 후보 파일과 런타임 파일을 수정하지 않는다.
