# R16 정본 발행과 전체 고택 화면 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Native execution in the existing publication worktree; user already authorized publication, push and merge.

**Goal:** R16 11동·128공정·22개 native를 main 제작 정본으로 등록하고 실제 R16 전체 고택과 연결된 화면 시안을 만든다.

**Architecture:** 큰 원본은 고정된 비공개 아카이브에 보존하고 main에는 해시·계약·갤러리·제작 도구를 등록한다. 전체 고택은 기존 배치와 R16 원본을 같은 카메라/조명으로 분할 렌더하고 깊이 기반 Blender 합성으로 만든다. 정지 아트·브라우저 시안·Flutter·배포 상태를 분리한다.

**Tech Stack:** Blender 5.2.2, Python 3.13, 정적 HTML/CSS/JS, Superdesign, Figma.

**Spec:** [ESTATE_SCREEN_DESIGN.md](ESTATE_SCREEN_DESIGN.md)

## Global Constraints

- 고택이 중심, 캐릭터·문양은 보조 장식.
- 형상·비율·창호·난간·기와·UV·계층·공정 ID·순서 유지.
- 완성 아트를 학습 완료·소유·보상으로 저장하지 않는다.
- 기본 390×844·100%, 별도 320px·200%·동작 줄이기 검수.
- 48×48px 조작, 조작 사이 8px, 본문 16px.
- 기본 체크아웃의 630개 WIP와 다른 세션·브랜치·stash 보존.
- 새 네비게이션 에셋은 사용자 후속 전달/매핑을 반영하며 기존 탭 의미를 추정해 변경하지 않는다.

## Review Focus

- 분할 렌더의 건물/담장 앞뒤가 바뀌지 않아야 한다: 깊이 합성과 실제 렌더 이음새를 확인한다.
- 선택점이 지붕·마당의 잘못된 위치를 가리키지 않아야 한다: 같은 카메라로 실제 부재의 경계를 투영한다.
- 작은 건물도 48px 컨트롤이 겹치지 않아야 한다: 건물 목록으로 동등한 선택 경로를 제공한다.
- 이미지 실패·뒤로·확대 닫기에서 선택과 포커스를 잃지 않아야 한다: 브라우저에서 실패/복귀를 확인한다.
- 아카이브 ref 이동/변조와 경로 탈출을 허용하지 않는다: 고정 SHA·조각 및 전체 해시·새 목적지 복원 검사로 확인한다.

## Task 1: 제작 정본과 main 등록

**Files:** docs/hanok_r16/{CANONICAL_PROMOTION_R16,APP_ASSET_CONTRACT,ARCHIVE}.json, README.md, RESTORE.md, review/**, process-evidence/**; tool/hanok_scene/{restore_ildu_r16,validate_ildu_r16}.py, r16/**.

**Interface:** APP_ASSET_CONTRACT의 11 building keys·128 process IDs·22 native SHA를 정본 등록과 archive variant/path에 연결한다.

- [x] 과거 승인 전 감사 기록을 유지하고 현재 사용자 승인을 별도 등록한다.
- [x] 실제 Git binary chunk 복원·기존 목적지 거부·경로 탈출 거부 검증을 통과한다.
- [ ] 아카이브 최종 고정 SHA와 독립 원격 검증/복원 영수증을 연결한다.
- [ ] validate_ildu_r16.py를 실행해 11/128/22와 고정 아카이브 일치를 확인한다.
- [ ] 관련 검증 후 본 세션 파일만 커밋/푸시하고 PR의 정확한 head CI를 확인해 main에 병합한다. 병합 main SHA의 필수 검사 결과를 확인한다.

## Task 2: 실제 전체 고택 렌더

**Files:** tool/hanok_scene/render_ildu_estate_layer.py, compose_ildu_estate.py; docs/hanok_r16/estate/{complete.png,RENDER_MANIFEST.json}.

**Interface:** --package-root는 native/<key>/full.blend, family-r16/<key>/stage-selection.json, inputs/r12의 기존 배치·담장·마당과 gates/native를 읽는다. --key는 context/11 building keys/left/right/shrine. 층별 EXR(Combined+Depth)·투영 경계 JSON을 출력한다. 합성기는 같은 카메라/조명 지문을 확인하고 complete.png를 출력한다.

- [x] 기존 원본의 SHA와 44개 기준 부재 위치·회전 동일성을 확인한다. 전체 부재 검증으로 과장하지 않는다.
- [ ] 사랑채 한 층을 실제 렌더해 카메라·색·Z/alpha를 검수한다.
- [ ] 나머지 건물·현재 문·담장·마당을 순차 렌더해 메모리를 제한한다.
- [ ] Blender Z Combine으로 합성하고 건물 수·문 연결·지붕/담장 겹침·크롭을 육안 검수한다. 원래 파일 해시가 그대로인지 확인한다.

## Task 3: 화면 시안과 검수

**Files:** docs/hanok_r16/estate/{index.html,viewer.js,style.css,assets/MANIFEST.json,SCREEN_VERIFICATION.json,*.svg}; .superdesign/{design-system.md,resume.json}.

**Interface:** 실제 complete.png와 projected anchors, APP_ASSET_CONTRACT를 읽어 건물 선택·128공정·복귀·확대를 연결한다. 학습 저장/보상 API는 호출하지 않는다.

- [x] 실제 C안 Figma Hanok 프레임과 main 색상/서체/간격 토큰을 확인한다. 새 사용자 에셋 12개는 같은 바이트로 보존했다.
- [ ] 실제 렌더와 선택한 에셋을 Superdesign에 용도별 업로드해 한 개 화면 방향을 만든다. 결과 HTML·공식 캔버스 URL을 보존한다.
- [ ] 같은 방향을 실제 선택·공정·닫기/복귀가 되는 로컬 시안으로 연결하고 편집 가능한 SVG/Figma 레이어를 제공한다.
- [ ] 390×844 100%에서 선택·공정·확대·뒤로·실패, 별도 320px/200%/동작 줄이기에서 겹침·잘림·포커스를 검수한다.
- [ ] 실제 캡처와 SHA/URL을 기록하고 정지 시안·Flutter/실기기·배포 상태를 구분해 보고한다.

원래 R12 정리 계획은 병행한다. 원격 전체 보존과 실제 복원 검증이 끝난 뒤에만 정확한 40.88GiB 원본 폴더를 격리·재열기 검사·삭제한다. 기존 별도 R12 Git worktree와 hwalju/warm-stone은 이번 삭제 대상이 아니다.
