# 사랑채 가변 공정 파일럿 — 생성 원장

- 상태: pending_review
- 생성일: 2026-08-29
- 정본 건물: ../sarangchae_try07_edit.png
- 정본 SHA-256: f2c01142f465b9353e0b9546a00f167891753039d9c910620d83cd924a077212
- 공통 등록: RGBA 2512×1680, 중심 X=1250.0, 접지선 Y=1421
- 범위: 사랑채 검토용. 런타임·Firebase·카탈로그 승격 금지

## 공통 불변 조건

모든 생성에서 V3 사랑채의 긴 6칸 몸채, 오른쪽 누마루 날개, 세벌대 기단,
중앙 계단, 전후 기둥, 팔작 홑처마 두 지붕의 비대칭 결구, 카메라와 접지선을
보존한다. 일반 한옥으로 재해석하거나 건물 폭·높이·칸 수를 바꾸지 않는다.
사람·글자·배경·풍경은 넣지 않는다.

## 7단계 — 기와

- 원시 파일: raw/stage_07_roof_tiles_source.png
- 생성 원본: exec-f394a5f3-e955-4f73-b0fe-872f33e8c996.png
- SHA-256: 91ddc90116824f73077b05ebc2411a8782c733a517392c6207a2bd49ee000a38
- 입력: V3 완성본, 등록된 5단계, 교정된 6단계

프롬프트 핵심:

> Preserve the exact V3 Sarangchae silhouette, six-bay rhythm, right numaru roof,
> foundation, posts, beams, purlins, rafters, common camera, and ground contact.
> Add complete dark grey clay tiles, ridge tiles, descending ridges, hip ridges,
> and eave-end tiles to both roof masses. Keep every wall bay and changho
> opening empty. Do not add plaster, doors, paper windows, floor boards,
> railings, signboards, people, tools, labels, scenery, ground plane, or
> background. Single isolated transparent/checkerboard-ready sprite, fully
> uncropped.

## 8단계 — 마루·누마루

- 원시 파일: raw/stage_08_floor_numaru_source.png
- 생성 원본: exec-ed2c3ecc-1a5a-4aaa-bdcf-c96879fc3cd7.png
- SHA-256: e625133403725284e3c46379e0402a2a4264be7554e5d758bbd991c078aac2cf
- 입력: 7단계 원시 파일 한 장

프롬프트 핵심:

> Keep all stage-7 structure and finished roof pixels in the same coordinates.
> Add the timber floor, central stair landing connection, raised right numaru
> deck, its supports, and the V3-specific railing. Keep wall infill, plaster,
> doors, changho, hanji, and signboards absent. Do not change the roof,
> foundation, post count, camera, framing, silhouette, or ground line.

## 9단계 — 벽체

- 원시 파일: raw/stage_09_wall_infill_source.png
- 생성 원본: exec-6f799564-0d72-45bb-b539-f408742c1012.png
- SHA-256: 4fce163baea743c6998e4dea0a6f186ad94f6568c1b7c0ad610bbfc8b9a438e3
- 입력: 8단계 원시 파일 한 장

프롬프트 핵심:

> Keep all prior pixels registered. Add only the V3 wall infill, restrained
> plaster and board-wall areas, and fixed door/window frames. Leave changho
> leaves visibly uninstalled: openings remain empty, dark/open, or show bare
> frames, with no complete hanji-papered lattice set. Keep the right numaru and
> railing complete. Do not add signboards, work props, people, labels, scenery,
> ground plane, or background.

## 기존 승인 후보

| 용도 | 보존 원시 파일 | 생성 파일 | SHA-256 |
|---|---|---|---|
| 6단계 지붕바탕 | raw/stage_06_roof_bed_source.png | exec-0c562b6f-c2c0-4714-9b71-bc1df48949fe.png | 5fc945ccee4087f532cbf0fe5a70925ed0f5693c10f6c31ac7fef21444067376 |
| 10단계 창호 설치 중 | raw/stage_10_changho_source.png | exec-220e2ba1-5bb9-4cd9-8707-3f62edf6412e.png | fec2b5244d8776769001e7c67b9b95e0ff3cd0686d2cfb65fd024d7e69e76d77 |
| 10단계 작업 소품 | raw/stage_10_work_props_source.png | exec-398380fb-31a7-42ec-925d-0e24ab09190b.png | 307d54e1690a52c40445f5a739ce696523bf9161456c4ccc43f62c502b301e44 |

작업 소품은 건물 이미지에 굽지 않는다. 결정론적으로 알파를 복원한 뒤
높이 430px, 중심 X=1840, 접지선 Y=1421의 독립 오버레이로 둔다.

## 후처리

1. SHA-256이 원장과 다르면 즉시 중단한다.
2. 밝은 중립 체크무늬만 결정론적으로 알파로 복원한다.
3. 공통 스케일을 적용해 2512×1680 캔버스의 동일 중심·접지선에 등록한다.
4. 알파 8 이하의 리샘플링 꼬리를 제거한다.
5. 완성본 베이스는 V3 정본 파일을 바이트 그대로 복사한다.
