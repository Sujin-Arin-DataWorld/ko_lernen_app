# 52단원 통합 집필 계약

2026-11-02 · 사용자 승인 범위: 입문28+A1.1 6+A1.2 6+A2.1 6+A2.2 6=52단원. 목표15:00 Europe/Berlin. 콘텐츠·연결자료만 작성하며 앱·에셋·HTML·경제·배포는 변경하지 않는다.

## 출처와 지위

기준 main `646c4658e70f594ab234a172679e29122d0f0e66`. `reference/curriculum/FOUNDATION.psv` 및 `UNITS.psv`가 목표·선수·어휘·문법 배정 근거다. `manuscripts/season1-rpg-v35/LEVEL_STORY_100.json`은 서사 연결 근거이며 완전한 평가 문항이 아니다. 기존34단원 전문은 보존하고 새 패킷은 보강/상속 관계를 표시한다. 모든 새 패킷은 `authored_candidate_not_runtime`다.

## 새18단원 JSON 형식

`units/<unit_id>.json`에 다음 필드를 쓴다. 모든 언어 객체는 `ko`, `en`, `de`를 갖는다. `de`는 de-DE이다.

- `schemaVersion`:1, `status`: `authored_candidate_not_runtime`, `unit_id`, `band`.
- `title`, `goal`: 언어 객체. `prerequisites`: 원래 단원 ID 배열.
- `teach_targets`: `{vocab:[{ko,en,de}], grammar:[한국어 형태 문자열]}`. `non_assessed`: 한국어 설명 배열.
- `source`: `{contract_path,contract_sha256,story_path,story_sha256,base_sha}`. 경로는 저장소 상대경로.
- `story`: `{lq_id,building_id,anchor,spoiler_guard}`. 실제 건축 소유나 해금을 선언하지 않는다.
- `dialogue`: `{id,speaker,phase,ko,en,de}` 배열. phase는 entry/request/model/practice/use/result/return/next. 최소6턴으로 필요→시범→행동→결과를 잇는다. 학습자가 선택한 말과 실제 독립 발화를 혼동하지 않는다.
- `items`: `{id,mode,kind,objective,prompt,material,options,accepted_answers,feedback_correct,feedback_wrong,help,scoring,evidence_limit}` 배열. `mode`는 P/I/R/T. `kind`는 choice/short/roleplay. `prompt`·두 feedback·help는 언어 객체. `material`은 상황 및 입력 자료 객체. `options`는 `{id,ko,en,de}` 배열(없으면 빈 배열). accepted_answers는 선택ID/허용문자열 배열. `scoring`은 structured/unscored. 역할 수행·발화 의미를 기계 채점하는 척하지 않는다.
- 최소 P2/I2/R2/T1 문항. 원문 목표가 여러 기능이면 문항을 늘려 각각 준비·연습·점검한다. I는 정답 모형을 감추고, R은 다른 날 새 자극으로 회상한다. 사용 가능성/수행 범위를 evidence_limit에 적는다.
- `responses`: assisted/independent/audio_unavailable/pause/resume/save_failed/revisit 각각 언어 객체. 실제 음성·저장을 구현했다는 뜻이 아니라 제작 카피다.
- `review`: `{delay:'next_day',no_story_lock:true}`.

## 집필 규칙

KO 뜻·화행에서 EN/DE를 각각 자연스럽게 쓴다. 안내는 du, 관계에 따른 대화 격식은 유지한다. 정답·도움 노출 이력은 독립 수행과 분리한다. 새 NPC·새 단서·미래의 진실을 발명하지 않는다. 어려운 극중 대사 전체를 산출 목표로 삼지 않는다. 도움·오답·복습 누락이 본편/건축을 되돌리지 않는다.

게임은 목표·어휘·형태가 맞을 때만 연결한다. 기존 시나리오의 인물/장소를 바꾸지 않는다. R16은 정확한 ID의 맥락 참조이며 소유권·가격·자격·자동 완공을 부여하지 않는다. 첫 집은 준비 전 연습 초안이다. 새 문항 ID가 런타임에도 존재한다고 주장하지 않는다.

## 검수

작성자 외의 검토자가 신규/변경 문구·정답·선수·도움·서사 공개 조건을 검토한다. 모델 검토와 사람 원어민 승인·음성 청취·Flutter/기기 검증은 구분한다. 정적 검사, 검토 소견과 수정 내역을 함께 보존한다. 52단원이 모두 통과하기 전 전체 완료로 보고하지 않는다.
