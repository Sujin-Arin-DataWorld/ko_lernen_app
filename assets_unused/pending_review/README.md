# pending_review/ — 격리 보관 (삭제 아님)

번들 폴더에 있었지만 `lib/` 참조가 0 이 된 파일들. `assets_unused/` 는 pubspec 에
없으므로 여기 있는 동안 AAB 에 안 들어간다. 복원은 원경로로 `git mv` 한 줄.

2026-08-07 격리분(3)의 사유·복원조건은 `../README.md` §5 표에 있다.

## 2026-08-23 추가

| 파일 | 원경로 | 용량 | 사유 | 복원 조건 |
|---|---|---:|---|---|
| `listening_hero.png` | `assets/illustrations/hanok/` | 1.3MB | Hören 화면 10:3 히어로 제거(스타일 이질·화면 30% 점유). 유일한 콜사이트였던 `listening_screen.dart` 의 `HanokHeader` 를 삭제해 참조 0 | Jin 결정 |
| `listening_hero.mp4` | `assets/video/loops/` | 0.8MB | 위 png 에서 파일명 규칙으로 자동 유도되던 앰비언트 루프. 포스터가 사라져 재생 경로 없음 (`HanokHeader.kLoopAssets`·`AudioPolicy` 항목도 함께 제거) | Jin 결정 (png 와 한 쌍으로만 의미 있음) |
| `chaekgado_backplate_{top,middle,bottom}.png` | `assets/hangul_sori_chaekgado_asset_pack_v1/bookcase/slices/backplate/` | 0.45MB | 선반을 dp 그리드 + `CustomPainter`(널판·기둥)로 다시 세우면서 배접 PNG 3장의 참조가 0 이 됐다. centerSlice 로도 중앙 기둥을 고정할 수 없고 좌우 투명 여백(163/177px)이 베이크돼 있어 재사용 불가 판정 | 나무를 다시 PNG 로 돌릴 때만 (그럴 계획 없음) |
| `chaekgado_frame_{top,middle,bottom}.png` | `.../bookcase/slices/frame/` | 1.2MB | 위와 같음. `kChaekgadoFrame*` 상수를 `chaekgado_assets.dart` 에서 삭제 | 위와 같음 |
