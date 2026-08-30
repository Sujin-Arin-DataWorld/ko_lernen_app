# 사랑채 건설 화면 인수인계

이 폴더는 다음 건물의 단계별 건설 화면을 설계할 때 참고할 사랑채 승인 자료의 **선별 스냅샷**이다. 현재 `main`에 그대로 복사해 실행하는 런타임 패키지가 아니다.

## 읽는 순서

1. `specs/2026-08-28-ildu-v3-blueprint-led-eight-stage-assets-design.md`
2. `specs/2026-08-29-ildu-variable-construction-cultural-lernpath-design.md`
3. `visual_reviews/revision_20260829_all_stages_sand.jpg`
4. `visual_reviews/sarangchae_12_stage_review.png`
5. 앱 구현이 필요할 때만 `specs/2026-08-29-ildu-sarangchae-variable-construction-app.md`
6. 현재 코드와 비교할 때만 `implementation_snapshot/`

## 무엇이 승인된 방향인가

- 하나의 마스터 좌표계와 누적 레이어를 사용한다.
- 완성 단계는 지정 V3 원본을 그대로 사용한다.
- 도면이 칸수, 기둥열, 기단, 지붕, 창호와 숨은 구조를 결정한다.
- 중간 단계도 원본의 돌·목재·기와·회벽 재질 정체성을 유지한다.
- 기둥은 얇은 선이 아니라 최종 폭과 입체 재질을 가진 부재다.
- 건물의 기능과 실제 공법에 따라 단계 수가 달라진다.
- 공정은 학습 모듈과 연결할 수 있지만 건축 편의를 위해 공정을 왜곡하지 않는다.

## 8단계에서 가변 단계로 바뀐 이유

초기 8단계는 사랑채 시범과 누적 연속성을 검증하는 좋은 기준이었다. 이후 승인된 설계는 작은 협문과 큰 사랑채에 같은 단계 수를 강요하지 않는다. 런타임은 배열 인덱스가 아니라 안정적인 `stageId`, `processTags`, `planVersion`으로 저장해야 한다.

## 구현 스냅샷 주의

`implementation_snapshot/`의 Dart, 테스트, JSON은 당시 시범을 이해하기 위한 자료다. 다음 세션은 먼저 최신 `main`의 동일 기능 존재 여부와 저장 계약을 검색해야 한다. 파일을 그대로 덮어쓰거나 현재 런타임 권위라고 가정하지 않는다.

## 전체 원본 패키지의 역사적 위치

전체 PNG 단계와 QA 자료는 작성 당시 아래 작업 트리에 있었다.

`C:\dev\hangulsori\ko_lernen_app_worktrees\ildu-sarangchae-pilot-20260828`

이 경로는 장기 권위가 아니다. 이 폴더에 복사한 문서·리뷰 시트·매니페스트·코드 스냅샷이 최소 인수인계 세트다.
