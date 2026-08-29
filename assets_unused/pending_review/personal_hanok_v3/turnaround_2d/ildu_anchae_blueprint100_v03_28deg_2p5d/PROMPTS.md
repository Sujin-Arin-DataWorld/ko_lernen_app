# V03 28° 8방향 생성 프롬프트 계약

## 생성 방식

- 엔진: Codex 내장 `imagegen`
- 방식: 각 방향별 V02 이미지를 주 형상 기준으로 사용한 참조 이미지 편집/재렌더
- 도면 원본은 생성 모델 입력으로 직접 넣지 않았다.
- 각 결과는 서로 다른 단일 에셋 호출로 생성했다.
- V02는 읽기 전용 기준이며 결과는 V03 형제 폴더에 저장했다.

## 공통 프롬프트

```text
Create one member of a coherent eight-view architectural turnaround for the exact
same Korean hanok Anchae shown in the V02 references. Preserve the building identity,
bay order, proportions, joinery, materials, colors, roof geometry, stone plinth,
physical-left integrated service/kitchen/toilet mass and its lower roof, and the
physical-right end without a lower roof.

CAMERA: exact requested azimuth; elevation exactly 28 degrees ABOVE HORIZONTAL,
looking downward; orthographic/weak-perspective long-lens architectural 2.5D;
level horizon; no roll, fisheye, or wide-angle distortion. Show the full building
and complete stone plinth on a 16:9 landscape canvas with the same baseline,
scale family, focal behavior, and upper-left neutral daylight as every other view.

STYLE: match V02/anchae_final exactly: polished hand-painted 2.5D architectural
game asset, restrained ink-like edges, fine warm dark-brown wood grain, pale warm
plaster, charcoal curved giwa rows, pale gray-beige natural stone, shallow ambient
occlusion, gentle consistent shadows, no hue shift.

PRESERVE: one long straight one-story body; one continuous single-eave paljak main
roof; about eight unequal bays; central two-bay daecheong; maru beside it with rooms
behind; rear maru; operable rear wooden closures only partly open, never a fully
open tunnel; substantial physical-left service volume and no physical-right low roof.

DO NOT: mirror, redesign, add, remove, relocate, or shrink components; do not create
L/U/courtyard/multi-wing/second-story/temple/pavilion forms; do not add extra roofs;
do not crop; do not add scenery, walls, jars, furniture, people, plants, sky, text,
labels, watermark, border, grid, checkerboard, or cast-shadow background.
```

## 방향별 잠금과 참조 조합

| 방위각 | 화면 관계 잠금 | V02 참조 |
|---:|---|---|
| 000° | 정면 중앙축. 물리 좌측=화면 좌측, 물리 우측=화면 우측. 전면 지붕면을 넓게 노출. | `00_front_000_original_exact.png`, `01_front_right_045.png`, `08_aerial_upper_left.png` |
| 045° | 물리 우측 박공이 화면 우측 전경, 정면은 화면 좌측으로 후퇴. 좌측 서비스 지붕은 먼 끝. | `01_front_right_045.png`, `00_front_000_original_exact.png`, `02_right_090.png` |
| 090° | 물리 우측 끝을 정축으로 봄. 낮은 서비스 지붕 금지. 긴 본채는 박공 뒤로 후퇴. | `02_right_090.png`, `01_front_right_045.png`, `03_rear_right_135.png` |
| 135° | 물리 우측 박공이 화면 우측 전경, 배면은 화면 좌측으로 후퇴. 배면 마루·창호 노출. | `03_rear_right_135.png`, `04_rear_180.png`, `02_right_090.png` |
| 180° | 배면 중앙축. 물리 좌측 서비스 공간은 화면 우측에 나타남. 뒤 마루와 살짝 열린 창호 유지. | `04_rear_180.png`, `03_rear_right_135.png`, `05_rear_left_225.png` |
| 225° | 좌측 서비스 공간이 화면 좌측 전경, 배면은 화면 우측으로 후퇴. | `05_rear_left_225.png`, `04_rear_180.png`, `06_left_270.png` |
| 270° | 물리 좌측 끝을 정축으로 봄. 통합 서비스 벽과 낮은 부속지붕이 중심. | `06_left_270.png`, `05_rear_left_225.png`, `07_front_left_315.png` |
| 315° | 좌측 서비스 공간이 화면 좌측 전경, 정면은 화면 우측으로 후퇴. | `07_front_left_315.png`, `00_front_000_original_exact.png`, `06_left_270.png` |

## 실제 출력 제약

모든 프롬프트에서 genuine transparent alpha를 요청했지만 내장 생성기가 이번 호출에서 `RGB` PNG를 반환했다. 결과에는 체크무늬를 그리지 않았으며, 옅은 백색 분리 배경을 유지한 채 pending-review 시안으로 저장했다.
