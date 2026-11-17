# R16와 현재 협문 원본 복원

## 현재 로컬 편집

R16: `native/<building>/full.blend`, `stage.blend`(Blender 프레임 1~각 건물의 마지막 공정).
협문: `gates/native/<left|right|shrine>-<structural|material>.blend`.
작업 입력·도면·exporter·공정 연결은 `inputs/r12/`, 현재 결과 재렌더는 `render_r16.py`.

## 고정 원격 보관

비공개 저장소: https://github.com/Sujin-Arin-DataWorld/hangulsori-archive
ref: refs/heads/archive/ildu-r12-retirement-20261029
정확한 commit: 4f016f35b2e7b90a7dc8e976e4cb4986effeee5d

새 저장소와 존재하지 않는 새 추출 폴더를 사용합니다. 기존 앱·원본은 덮어쓰지 않습니다.

```powershell
rtk git init C:/dev/r16-restore-repository
rtk git -C C:/dev/r16-restore-repository remote add origin https://github.com/Sujin-Arin-DataWorld/hangulsori-archive.git
rtk git -C C:/dev/r16-restore-repository fetch --depth=1 --filter=blob:none origin 4f016f35b2e7b90a7dc8e976e4cb4986effeee5d
rtk proxy python -X utf8 tool/hanok_scene/restore_ildu_r16.py C:/dev/r16-restore-repository 4f016f35b2e7b90a7dc8e976e4cb4986effeee5d r16-native C:/dev/r16-restored-native
```

위 복원 명령은 main 저장소의 루트에서 실행합니다. 독립 로컬 보존 패키지에서는 같은 인수를 `portable-tools/restore_retirement_variant.py`에 넘길 수 있습니다.

`r16-native`는 Blender 22개(`sarang/full.blend`, `sarang/stage.blend` 등), `current-gates`는 내장 협문 사본 6개(`native/` 아래), `portable-inputs`는 필요한 입력과 원본 도면(`r12/` 아래), `r16-gallery`는 갤러리, `r16-evidence`는 검증/공정 기록, `portable-tools`는 실행·복원 도구입니다.
과거 자료 전체가 필요할 때만 `r12-source`를 새 폴더로 복원합니다. 내부 `.git`·LFS 원본·index·refs·삭제 당시 파일을 포함합니다. 옛 Git worktree의 절대경로 포인터는 새 위치에 맞춰 별도 복구하며, 퇴역 폴더를 자동 재생성하지 않습니다.
각 파일은 40MiB 이하 조각 SHA-256과 전체 SHA-256으로 검증됩니다. 복원 도구는 변조·누락된 조각과 기존 목적지를 거부합니다.

이 보관은 GLB PBR 베이킹, Flutter 통합, 기기 QA와 배포 완료를 뜻하지 않습니다.

## 온전한 단독 지붕 (2026-10-29)

사랑채·중문간채의 단독 공정/완성본 네 파일과 보완 부재 47MB는 별도 비공개 보관본에 있다. 연결용 22개 원본은 그대로 보존된다.

- ref: `refs/heads/archive/ildu-r16-roofs-20261029`
- commit: `a3ebf0c614ccec1864324f6e2641c9f895ddaf6f`
- manifest SHA-256: `93fad17a506fb324abf3f340db03da98c5ec87acb568ce9fecd6562c8468f840`

같은 복원 도구에 위의 commit과 `roof-native`를 전달하면 `sarang/full.blend`, `sarang/stage.blend`, `jung/full.blend`, `jung/stage.blend`를 새 폴더로 복원한다. `roof-source`는 보완 부재·맵, `roof-tools`는 제작·복원 코드다. 공정 진도나 보상은 새로 생성하지 않는다.

`roof-tools`는 제작 당시 실행한 코드의 보존 기록이다. 다른 경로로 복원해 재렌더링할 때는 main의 `tool/hanok_scene/render_ildu_roof_variants.py`를 사용한다. 이 도구는 검증 기록의 과거 절대경로를 입력으로 사용하지 않고 `--package-root` 아래 `roof-variants/native/<sarang|jung>/<full|stage>.blend`를 해시로 확인한다. 같은 패키지의 갤러리는 `family-r16/`, 보완 부재는 `roof-variants/input/`, 검증 JSON은 `roof-variants/<building>-<kind>-verified.json`에 배치한다. 검증 JSON 안의 `native` 문자열은 출처 기록으로 남긴다.
