# R16 정본·누마루 연구·선택 이미지 구분

## 사용자 결정

- 기존 승인 R16의 건축·공정·편집 원본은 유지한다.
- 누마루 R18→I1 재질·조명 연구는 로컬에서 재개할 수 있게 보존하고 미승인 연구로 별도 커밋·푸시한다.
- 연구 재질을 전체 사랑채에 확대해 본 뒤 사용자가 만족하고 명시적으로 승인해야 정본 교체를 검토할 수 있다. 이번 보존 요청은 미술 채택이 아니다.
- 선택 장면 두 장만 별도 제작 이미지로 남긴다. 다른 후속 lookdev는 활성 작업에서 제외한다.
- Figma는 이번 정리 범위에서 제외한다. 앱 코드·공정·소유·엽전·스토리 연결은 변경하지 않는다.

## 계속 작업할 위치

- 승인 R16: `C:/dev/hangulsori/_codex_artifacts/ildu-r16-publication-20261028`
- 누마루 연구: `C:/dev/hangulsori/_codex_artifacts/r16-lookdev-20261102/numaru-zone`
- 이어갈 native: `environment-v1/directional-sky.blend`
- 비교판: `C:/dev/hangulsori/_codex_artifacts/r16-lookdev-20261102/figma/numaru-zone-work/compact-reference-baseline-I1.png`
- 편집 도구: `C:/dev/hangulsori/ko_lernen_app_worktrees/r16-lookdev-20261102/tool/hanok_scene`
- 선택 이미지: [보존 폴더](../../design/r16-retained-20261115/README.md)

## 검수 상태

I1은 누마루 한 구역의 재질·조명 중간 결과다. 기존 검수 기록은 목재의 불규칙 중간 섬유와 돌의 광물면이 부족하다고 판정했다. 전체 사랑채에 연구 결과를 확대하거나 기존 정본을 교체하지 않았다. Blender에 전체 건물 데이터가 들어 있다는 사실과 새 미술을 전체에 적용·승인했다는 주장은 다르다.

정본 기준은 `CANONICAL_PROMOTION_R16.json`과 `ARCHIVE.json`의 고정된 근거를 따른다. 이번 정리의 파일별 원격 보존·복원·삭제 검증은 동반 `RETENTION_20261115.json`에 연결한다. 원격 푸시는 연구 보존이며 승인이나 배포를 뜻하지 않는다.

## 2026-11-15 실행 결과

- 승인 R16 묶음 2,767개 파일과 보존 자료 299개의 SHA-256이 정리 전후 동일하다. 보존 자료에는 같은 장면의 원본 사본과 재료·도구 의존성이 포함된다. 선택한 장면 아트는 두 종류다.
- 누마루 연구 295개 파일은 비공개 연구 브랜치에서 원격 바이트를 검증했다. 정본 도구를 연구 의존성으로 함께 보관한 것은 기존 정본의 승인 상태를 바꾸지 않는다.
- 후속 연구 이력 1,111개 파일은 원격에서 복원·검증한 뒤 로컬에서 삭제했다. 거절된 생성 원본과 동일 사본 51개는 경로·해시·사유 기록을 남기고 삭제했다.
- 생성 캐시 2,073개와 빈 폴더 209개를 정리했다. 실제 삭제 파일은 총 3,235개, 논리 용량 12,616,120,502바이트다. 다른 채팅도 디스크를 사용했으므로 드라이브 여유 공간의 증가량으로 계산하지 않았다.
- 보존 Blender 9개가 누락 의존성 없이 열렸다. GitHub에서 복원한 I1도 1200×1000으로 렌더됐다. 원본 렌더와 평균 RGB 오차는 0.0006717/255, 최대 3/255이며 픽셀 완전 일치나 미술 합격으로 보고하지 않는다.
- 보존 도구 테스트 10개, 보관 안전성·무손실 분할 테스트 9개가 통과했다.
- 원래 worktree의 HEAD·스테이징과 Graphify 수정 파일 4개는 그대로다. 그 Graphify 자료를 이번 정리의 최신 파일 목록으로 사용하지 않는다.

연구와 폐기 이력은 [hangulsori-archive](https://github.com/Sujin-Arin-DataWorld/hangulsori-archive)의 `research/r16-numaru-material-light-20261115`와 `archive/r16-retired-lookdev-20261115`에 분리했다. 각 브랜치의 README에 복원 명령이 있고, manifest.json에 원본 경로·SHA-256·청크 순서가 있다. 최종 검증 커밋은 [동반 기록](RETENTION_20261115.json)에 고정한다.
