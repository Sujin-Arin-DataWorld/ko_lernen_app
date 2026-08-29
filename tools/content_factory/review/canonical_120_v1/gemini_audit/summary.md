# Gemini 정본 120개 다국어·레벨 감사

> 이 결과는 자동 승인이나 런타임 승격 근거가 아닙니다. Jin의 120개 전체 검토가 필요합니다.

- 모델: `gemini-3.5-flash` (`low` thinking)
- API 요금 모드: `free`
- 무료 프로젝트: `gen-lang-client-0858328849` (billing disabled 확인)
- API 키 UID: `6455b51d-bd1f-43a4-9cfb-4abfcca72842`
- 후보 해시: `8f9e37b4951fdc969b965ac8214d74baee874b579dab7c56918e6260a0e2614b`
- API 호출: 6회
- 입력 토큰: 274,782
- 출력 토큰: 18,915
- 사고 토큰: 4,884
- 추정 실제 비용: $0.0000
- 판정: pass 116, review 4, reject 0
- findings: critical 0, major 2, minor 2

## 레벨별 결과

| 레벨 | pass | review | reject | critical | major | minor | 비용(추정) |
|---|---:|---:|---:|---:|---:|---:|---:|
| A1 | 20 | 0 | 0 | 0 | 0 | 0 | $0.0000 |
| A2 | 18 | 2 | 0 | 0 | 2 | 0 | $0.0000 |
| B1 | 19 | 1 | 0 | 0 | 0 | 1 | $0.0000 |
| B2 | 20 | 0 | 0 | 0 | 0 | 0 | $0.0000 |
| C1 | 20 | 0 | 0 | 0 | 0 | 0 | $0.0000 |
| C2 | 19 | 1 | 0 | 0 | 0 | 1 | $0.0000 |

## 다음 게이트

- 모델 findings를 Jin이 원문과 대조한다.
- 수정할 후보만 별도 편집하고 DE/EN·퀘스트·TTS 해시를 함께 갱신한다.
- 후보가 바뀌면 기존 TTS readiness 영수증은 다시 생성한다.
- 자동 감사만으로 approval 또는 runtime promotion을 실행하지 않는다.
