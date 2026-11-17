# 기능 보존과 워크트리 정리 정본

이 문서는 모든 세션의 공통 운영 지침이다. 기능을 보존하는 것과 예전 체크아웃을 유지하는 것을 구분한다.

## 원격 보관 위치

- 비공개 저장소: [https://github.com/Sujin-Arin-DataWorld/hangulsori-archive](https://github.com/Sujin-Arin-DataWorld/hangulsori-archive)
- 보관 브랜치: `archive/preserved-learning-rewards-20261023-192613`
- 검증 기록 포함 원격 커밋: `ee571ef9f1521dca9fabcbba490d500914f78708`
- 원본 스냅샷 커밋: `ede3ed8ffb3066d3186936ea74394713a1ca3e75`
- 기준 Git 이력: 같은 저장소의 `preserved-bases/<variant>` 브랜치. 정확한 SHA는 feature_preservation.json 참조.
- 큰 파일은 40MiB 조각과 전체 SHA-256을 기록하며 같은 내용은 공통 Git 객체를 공유한다.
- GitHub에서 두 ref와 SHA를 다시 확인해야 삭제 근거가 된다. 로컬 보관만으로 원격 백업 완료라고 보고하지 않는다.

## 보존된 범위

하회탈/탈선비, 보자기·일반 보상, 엽전, 보물·보석상자/자개함, 도깨비 Silben, 붓 한글·음절의 14개 출처 버전을 보존했다. 기준 커밋, 최종 코드·테스트·에셋, 미추적·ignored 원본, 삭제 경로, staged 변경과 연결 대상을 기록한다.
전체 15,114개 고유 콘텐츠 객체의 SHA-256과 큰 파일 조각 결합을 검증했고, 붓 한글·음절 버전 9,832개 파일의 실제 추출·복원을 검증했다. 이는 해당 버전의 컴파일·기기 동작·승인·배포 검증이 아니다.

## 복원 절차

1. 이 저장소에 보관 remote를 추가하고 해당 보관 ref와 `preserved-bases/<variant>`를 fetch한다. 기존 remote를 임의로 변경하지 않는다.
2. 보관 `manifest.json`에서 작업 버전과 baseCommit을 선택한다. 새 전체 앱 워크트리는 이 기준 커밋으로 만든다.
3. `python tool/restore_feature.py <기존 저장소> <보관 ref 또는 커밋> <variant> <새 추출 폴더>`를 실행한다. 추출 폴더는 존재하지 않아야 하며 기존 앱을 덮어쓰지 않는다.
4. 추출한 파일을 새 기준 워크트리에 적용한다. ARCHIVE_RESTORE_METADATA.json의 absent 경로, staged 변경, 원래 연결도 확인한다. 절대경로 연결은 현재 검증된 위치로 전환한다.
5. 필요한 기능 버전만 선택해서 현재 앱에 통합하고 분석·관련 테스트·실제 조작을 별도로 검증한다. 여러 스냅샷을 일괄 병합하거나 원본 상태를 승인 정본으로 자동 승격하지 않는다.

## 삭제 조건과 유지할 의존성

원격 보관과 기준 이력을 확인한 뒤 실제 파일 내용이 보관본과 일치해야 한다. 새 변경·고유 ignored 원본은 추가 보관 후 제거한다. 기준 HEAD가 main에 포함됐거나 오래됐다는 이유만으로 삭제하지 않는다. 실행 중인 세션/프로세스, 파일 잠금, 안쪽 저장소, 외부 연결을 검사하고 정확한 등록 경로만 git worktree remove로 제거한다. 브랜치·stash·기본 체크아웃·다른 세션 WIP는 유지한다.
현재 Lernen의 assets는 c-app-integration-20261012를 연결 대상으로 사용한다. Blender/R12는 hanok-hwalju-20260928의 외부 텍스처 7개와 hanok-warm-stone-20260923의 도구를 참조한다. 이 경로들은 검증된 독립 위치로 복사·참조 전환하기 전까지 삭제하지 않는다.

## 정리 기록

이 문서 작성 전에는 17개 워크트리를 단계적으로 제거했고, 그중 마지막 승인 8개는 Git 등록 45→37, 당시 C: 관측 여유 공간 약 12.5GiB 증가를 확인했다. 보관물과 파일별 삭제 영수증은 로컬 `_codex_artifacts/worktree-retirement-20261023`에 있다. 이전 삭제 전체가 본 기능 아카이브의 14개 버전과 동일한 범위라는 뜻은 아니다. 이번 추가 삭제 결과는 worktree_cleanup_20261023.json에 기록한다.

## 원격 검증 및 이번 삭제 결과

- 기능 보관 ref 원격 SHA 확인: 완료.
- 기준 이력 18개 원격 SHA 확인: 완료.
- 추가 4개 출처 WIP/Graphify 보관: `archive/cleanup-overlays-20261023` / `60393ab8816a782aa1219ccf9b9886664855b195`. 원격 확인 완료.
- 이번에 실제 제거한 워크트리: 10개, 논리 파일 합계 57.46GiB. 정확한 경로·HEAD·보관 근거·공간 관측치는 [worktree_cleanup_20261023.json](worktree_cleanup_20261023.json)에 기록한다.
- 이 변경은 다른 세션의 630개 staged 변경을 포함하지 않는다. 로컬 기본 체크아웃의 HEAD와 index를 보존하면서 원격 main에 운영 문서를 발행한다. 기존 워크트리는 최신 원격 운영 문서를 읽고, 없어진 경로를 자동 재생성하지 않는다.
- 발행 검증에서 Playwright·에셋 파이프라인은 통과했다. 콘텐츠 테스트 1,361개(20개 skip)는 통과했지만 setup-python의 마지막 pip 캐시 저장이 `/home/runner/.cache/pip` 부재로 실패했다. 전체 CI를 성공으로 간주하지 않으며 이 정리에서 CI 설정이나 앱 소스를 수정하지 않았다. 실행 URL과 상태는 삭제 기록 JSON에 보존한다.
- stagedPatch의 각 SHA는 보관 manifest.objects에 있는 Git 경로를 가리킨다. 해당 경로를 보관 ref에서 `git show`로 읽고 배열 순서대로 결합하면 원래 staged diff를 얻는다. 최종 파일 추출과 index 상태 복원은 구분해서 검증한다.

## 한옥 구버전 추가 정리

[한옥 V1·V2 및 초기 V3 확인](HANOK_LEGACY_RETIREMENT_20261023.md)에서 남은 V2 사본 2개 워크트리·거절 이미지 1개의 보관과 삭제, 현재 V3 자산·현재 Blender 의존성 유지 근거를 확인한다. 구버전 폴더를 다시 만들지 않는다.

## 일두고택 R16 제작 정본

2026-10-29 사용자가 R16 전체의 제작 정본 승격과 main 발행을 명시적으로 요청했다. [R16 정본 등록](../hanok_r16/CANONICAL_PROMOTION_R16.json)은 11동·128공정 이미지와 텍스처를 내장한 Blender 22개의 정확한 해시를 기록한다. [ARCHIVE.json](../hanok_r16/ARCHIVE.json)의 고정 비공개 원격 커밋과 [복원 도구](../../tool/hanok_scene/restore_ildu_r16.py)로 해당 원본, 현재 협문 6개 사본, 필요한 입력·도면·제작 도구와 이전 R12 자료를 각각 복원한다.

계속 편집할 로컬 패키지는 `C:/dev/hangulsori/_codex_artifacts/ildu-r16-publication-20261028`이다. 예전 40.88GiB R12 artifact 폴더는 전체 원격 바이트 대조·독립 복원·원래 경로 부재 상태의 재열기 검증 이후에만 정리한다. 별도 R12 Git worktree, hwalju/warm-stone과 다른 세션의 의존성 삭제는 이 지시에 포함되지 않는다. 정본 승격은 제작 아트의 승인 상태이며 Flutter의 현재 에셋 선택·공정 정책·진도·보상·기기·배포 완료를 변경하지 않는다.
