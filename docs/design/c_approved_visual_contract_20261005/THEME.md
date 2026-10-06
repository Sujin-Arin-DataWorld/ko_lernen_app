# C · 녹청 한지 원목 황동

사용자가 고른 최종 시안의 테마다. theme-factory의 테마 명세 형식을 사용하며 다른 프리셋을 적용하지 않는다.

## 색상

| 의미 | 값 | 출처 |
|---|---|---|
| 녹청 | #1C5148 | CPalette.jade |
| 깊은 녹청 | #123E37 | CPalette.deepJade |
| 한지 | #F6EDE0 | CPalette.paper |
| 먹색 | #1C2520 | CPalette.ink |
| 보조 글자 | #4B5148 | CPalette.mutedInk |
| 황동 표면 | #D59F58 | CPalette.brass |
| 원목 | #82522F | CPalette.oakEdge |
| 카드 경계 | #CCB69A | CPalette.fineEdge |
| 브랜드·밝은 금 | #E9C98A | CBrandWordmark |

이 값은 현재 소스의 정확한 기준색이다. 원본 이미지는 질감·조명으로 픽셀 색이 달라지므로 전체 PNG의 대표색 하나를 위젯 표면색으로 덮어 칠하지 않는다. 색만으로 선택·정답·오답을 표시하지 않는다.

## 소재와 깊이

`assets/illustrations/concept_c/material_atlas.png`의 네 1/4 영역은 좌상 녹청·우상 한지·좌하 원목·우하 황동이다. 주 색의 정체성과 원래 꽃무늬·종이 섬유·나뭇결을 보존한다. CSS와 Flutter가 같은 원본을 공유한다.

- 한지 카드: 질감 opacity .55, 위쪽 #BBFFFDF4/1.2dp·왼쪽 #88FFFDF4/1dp 하이라이트, 좌상 #55FFFFFF → 우하 #0982522F의 얕은 빛.
- 한지 raised 그림자: #BFA27D, (0,3dp), blur 0 + #330D241C, (0,5dp), blur 8dp. 낮은 카드: 각각 y=2dp와 y=3dp/blur=3dp.
- 황동 CTA: 질감 .85, 경계 #F2D79C/1.3dp, 표면 가장자리 #875620. 녹청 CTA: 질감 .82, 경계 #D4BC80/1.3dp, 가장자리 #0A332C.
- CTA 빛: 위 white .30 → 투명 → 아래 black .18. 그림자 #490E251D, 기본 (0,5dp)/blur5dp, 눌림 (0,1dp)/blur1dp. 표면 깊이는 4dp.
- 녹청 화면: 질감 .48 위에 약한 녹청·깊은 녹청 빛. 꽃무늬가 글자를 방해할 정도로 강조하지 않는다.
- 제목 그림자: #66051914, (0,1.2dp). 브랜드 그림자: #88061912, (0,1dp).

## 글자

동적 인터페이스는 Paperlogy Regular/SemiBold/Bold, 학습 한국어는 Noto Sans KR이다. 파일은 `assets/fonts/Paperlogy/`와 `assets/fonts/NotoSansKR/`를 사용한다. 참조 갤러리의 설명 글자에도 Paperlogy를 사용한다. 이미지에 합쳐진 독일어의 원래 폰트는 판독만으로 확정하지 않는다.

## 그림

전체 원본의 질감·재료·색·비율·인물·동작·꽃·여백을 보존한다. 기존의 보존된 조각을 사용하며 새 원본을 생성하거나 잘라 만들지 않는다. 동적인 라벨·잔액·진행·포커스는 위젯이 담당한다. 원목 바닥 위에 놓인 책·도자기·메달·한옥의 입체감을 평면 아이콘으로 바꾸지 않는다.

메인에서는 짧은 문구와 그림을 같은 한지 면 안에 모은다. Einleitung에서는 페이지별 큰 장면과 아래 설명·CTA의 관계를 유지한다. 승인 장면의 큰 활자를 모든 학습 화면의 기본 글자로 사용하지 않는다.
