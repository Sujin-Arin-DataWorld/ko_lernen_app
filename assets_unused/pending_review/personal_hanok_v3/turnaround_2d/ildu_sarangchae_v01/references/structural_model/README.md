# 일두고택 사랑채 Blender 원형

상태: **검토 전용 blockout v01 + detail v02 + original-projection final v03**
런타임·카탈로그·Firebase·에셋 원장에는 연결하지 않는다.

## 목적

한 방향 PNG를 AI로 다시 그려 회전시키는 대신, 한 개의 실측 기반 3D 원형에서
정면·측면·배면을 일관되게 렌더한다. v01은 구조 검증본이고, v02는 도면과 현장사진에
근거한 첫 건축 상세·V3 색조 검토본이다. 둘은 별도 파일로 유지한다.

## 이번 버전에서 고정한 구조

- 비대칭 `ㄱ`자 평면
- 정면 6칸: `2595 / 2675 / 2645 / 2660 / 1985 / 1985 mm`
- 정면 총길이 `14.545 m`
- 몸채 깊이 `3.985 m`
- 우측면 총깊이 `7.980 m`, 전출 날개 깊이 `3.995 m`
- 누마루 날개 폭 `3.970 m`(각 `1.985 m` 두 칸)
- 처마 내밀기 `1.380 m`
- 정면 GL 기준 용마루 약 `7.080 m`
- 정면 약 `1.200 m`, 배면 약 `0.245 m` 노출 기단을 경사지 대지 프록시와 함께 유지
- 누마루 상부 원주와 하부 팔각 누하주를 별도 부재로 유지
- 전면 활주 2개는 석주초와 처마 귀에 모두 접촉
- 전면·우측·배면의 창호 패턴을 서로 다르게 구성

## detail v02에서 추가한 것

- 독립된 뒤쪽 팔작처럼 닫히던 누마루 지붕을 몸채 용마루까지 연결
- 내부 회첨골을 지붕 접합부에 별도 곡선 부재로 표시
- 세 겹 용마루, 막새 128개, 노출 서까래 끝 74개와 절제된 합각 환기살
- 정면 난간을 두 개의 큰 X가 아니라 도면처럼 작은 X 여섯 칸으로 분할
- 측면 난간을 정면 X 복제가 아닌 안상형 곡선 여덟 칸으로 구분
- 정면 창호를 `4짝 / 4짝 / 2짝 / 2짝` 리듬으로 나누고 머름·문고리 추가
- 누마루 앞 창호의 두 짝 분할, 머름, 문고리 추가
- 단일 단계 처마 받침팔과 V3 계열의 짙은 기와·호두색 목재·묵은 한지 색조 적용

## 파일

- `scripts/build_ildu_sarangchae.py` — Blender 5.2 재생성 스크립트
- `source/ildu_sarangchae_blockout_v01.blend` — 편집 원본
- `source/ildu_sarangchae_detail_v02.blend` — v01을 덮어쓰지 않는 상세 편집 원본
- `exports/ildu_sarangchae_blockout_v01.glb` — 지형·카메라·조명을 뺀 휴대용 건물 모델
- `exports/ildu_sarangchae_detail_v02.glb` — 상세 휴대용 건물 모델
- `renders/blockout_v01/*.png` — 고정 카메라 8방향 RGBA 렌더
- `renders/detail_v02/*.png` — 동일 카메라의 v02 8방향 RGBA 렌더
- `renders/detail_v02/ildu_sarangchae_detail_v02_turnaround_sheet.png` — 한지색 바탕 8방향 검토 시트
- `blockout_v01_manifest.json` — 치수·불변조건·의도적 단순화 기록
- `detail_v02_manifest.json` — 상세 개수 검증과 추가 근거자료 기록

Blender의 `05_GRADE_PROXY` 컬렉션은 앞마당에서 배면으로 올라가는 지형을 설명하기 위한
검토용 형상이다. 건물을 실제 맵 지형에 배치할 때는 이 컬렉션을 끄고, 동일한 높이차를
게임 지형에서 재현한다.

## 재생성

PowerShell에서 저장소 작업트리 루트를 기준으로 실행한다.

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' `
  --background --factory-startup `
  --python 'assets_unused\pending_review\personal_hanok_v3\blender\ildu_sarangchae\scripts\build_ildu_sarangchae.py'
```

렌더 없이 `.blend`와 `.glb`만 다시 만들려면 마지막에 `-- --skip-renders`를 붙인다.

v02를 재생성하려면 스크립트 뒤에 `-- --detail-v02`를 붙인다.

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' `
  --background --factory-startup `
  --python 'assets_unused\pending_review\personal_hanok_v3\blender\ildu_sarangchae\scripts\build_ildu_sarangchae.py' `
  -- --detail-v02
```

원본 `sarangchae_try07_edit.png`를 실제 3D 표면에 투영하고 같은 모델에서 8방향을
생성하는 최종 v03은 다음처럼 재생성한다. 투영 캔버스는 원본 픽셀을 투명 캔버스에
그대로 배치하는 파생본일 뿐 새 건물을 생성하지 않는다.

```powershell
python 'assets_unused\pending_review\personal_hanok_v3\blender\ildu_sarangchae\scripts\prepare_ildu_sarangchae_projection.py'

& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' `
  --background --factory-startup `
  --python 'assets_unused\pending_review\personal_hanok_v3\blender\ildu_sarangchae\scripts\build_ildu_sarangchae.py' `
  -- --final-v03 --resolution-x 2736 --resolution-y 1536

python 'assets_unused\pending_review\personal_hanok_v3\blender\ildu_sarangchae\scripts\finalize_ildu_sarangchae_sprites.py'
```

앱 후보 파일은 `final_sprite_v03/`의 8개 PNG다. 모두 같은 실측 `ㄱ`자 모델을
45도씩 회전해 만들며, `.blend` 안에는 변경하지 않은 원본 PNG와 투영 UV가 패킹된다.

## 도면 근거

- `docs/data/heritage_houses/_sprite_spec_2026-08-24.md`
- `docs/data/heritage_houses/ildu_gotaek_measured.json`
- 사랑채 지붕 평면도
- 사랑채 천정 평면도
- 사랑채 정면도·우측면도
- 사랑채 난간·기둥·대량·안허리 상세도
- 현장 전경·좌측·우측·배면 사진
- V3 정본 스프라이트 `sarangchae_try07_edit.png`

## 다음 승인 뒤 패스

1. v02 8방향에서 `ㄱ`자 깊이·누마루 위치·배면 실루엣 승인
2. 시각적 회첨골 덮개를 단일한 방수 지붕 토폴로지로 정리
3. 기둥 위치별 실측 높이·배흘림과 난간 5형식 전체 키플랜 적용
4. 기와·목재·회벽·석축 UV 및 손그림 텍스처 베이크
5. 게임 성능 예산에 맞춘 병합·LOD·콜라이더 제작
6. 동일 카메라로 앱용 스프라이트 시트 출력

v02도 보고서의 서까래 173개와 모든 내부 결구를 전부 복원한 최종 BIM이 아니다.
회첨골은 현재 두 지붕 체적 위의 깨끗한 시각 덮개이고, Blender 절차 재질은 GLB용으로
아직 베이크하지 않았다. 따라서 `.blend`가 현재 편집·렌더 기준 원본이며 `.glb`는
방향·배치 검토용이다.
