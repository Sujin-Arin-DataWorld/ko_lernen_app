# 시즌1 이야기 이미지 — 디자이너 검수 적용

2026-11-04. 현재 상태는 **독립 검수 체계 적용 완료 / R21b 이미지 수정 미완료**다. 학습 화면은 범위에서 제외했다.

## 시작점

- [상위 디자인 작업 지침](../../../AGENTS.md): 다음 작업에서도 생성 담당과 독립된 디자이너를 배정한다.
- [세부 검수 규칙](DESIGN_REVIEW_GATE.md): 외형·사지·수치 관계·시선·소품·서사·출력 판정.
- [범위와 이야기 순서](SCOPE.md): R21b–R27의 이야기 연결, R24 시작/완료 분리, R26 초안과 정본 분리.
- [실제 검수 기록](REVIEW_LOG.md): 단독 후보3종과 생성 전후 독립 검수.
- [R21b V5 반려 결과](R21B_POSTFLIGHT.md): 네 다리 PASS, 크기·얼굴·방향·UI FAIL, 배경 UNVERIFIED.
- [출처와 파일 해시](REVIEW_MANIFEST.json): 로컬 원본은 보존하고 실패 후보를 출고 에셋으로 등록하지 않는다.

## 생성 기록의 구분

- `ANATOMY_PREFLIGHT.json`, `ANATOMY_REVISION_PREFLIGHT.json`, `ANATOMY_PADDING_PREFLIGHT.json`: 단독 후보1~3의 실제 생성 지시.
- `R21B_PREFLIGHT_V5.json`: 검토 전 프롬프트 초안. **생성에 사용한 최종 지시가 아니다.**
- `R21B_PROMPT_V5.json`: 디자이너 수정 지시를 반영해 실제 실행한 최종 프롬프트.

모든 이미지는 기본 내장 image_gen으로 제작했다. 실패 후보의 원본은 generated_images에 남기며 앱 에셋·정본·이번 패키지의 완성 목업으로 추가하지 않았다.

## 다음 실행의 첫 단계

R21b의 **승인 정본으로 고정한 크기·방향·구도 사전 검수**부터 다시 시작한다. 같은 실패 장면을 참조하여 일괄 확대하지 않는다. 현재 전담 역할은 `/root/character_design_guard`; 다른 채팅에서는 역할을 새로 배정해야 한다. 서사 검토 역할은 `/root/story_contract_review`다.

검수 기록에 사용 목적별 PASS/FAIL/UNVERIFIED와 관찰 근거가 모두 있어야 다음 단계로 넘긴다. 사람이 승인한 정본·독립 AI 시각 검수·앱 적용·배포는 구분한다. 이번 작업으로 앱 코드·HTML·Figma·재화/소유 정책·배포를 변경하지 않았다.

## 2026-11-04 최종 목록 정리와 후속 상태 화면

[현재 정본 4장 구분·100장 보존 이동·R22 제작 기록](final-selection/README.md). 이전 generated_images 원본 경로는 같은 기록의 RELOCATION_RECEIPT.json으로 새 위치를 조회한다. 실패 기록과 사용자 승인 상태는 바꾸지 않았다.
