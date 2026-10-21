# 살아 있는 모래마당·담장 R3 — 2026-10-21

상태: 실제 Blender 재질 구현·동일 구도 4시점 전후 8장·재구성/패키지/브라우저 검증 완료. 사용자 승인 전의 로컬 후보다.

## 최종 결과와 한계

- 최종 재질 라이브러리 SHA: `f7bbe968db527719cc160d4bb403b5f1dbd262a0d7b49a307982025968e3012a`.
- `verification.json`, `reconstruction-verification.json`, `package-verification.json` 통과. 6,135개 객체의 형상·UV·변환 보존, 흙 2+담장 207 슬롯만 변경, 재질 라이브러리 재로딩과 실제 8개 PNG SHA·동일 카메라·빛·24 samples·seed 15 연결을 확인했다.
- 실제 브라우저에서 4시점 전환, A/B 단독·반씩 보기, 키보드 경계 50→51을 확인했다. 477px 이미지와 좁은 패널에서 48px 버튼·가로 넘침 없음도 확인했다. `browser-qa.json`, `browser-narrow-qa.json`, `browser-final.png`가 근거다.
- 흙은 실제 477px에서도 두 쓸림 구역과 중앙의 다짐면이 구분된다. 담장은 원본에서 두 군집의 광물면·결 보강이 읽히지만, 477px에서 두 신규 변화가 즉시 읽히는 엄격한 기준은 완전히 통과하지 못했다. 담장 작은 화면 효과를 강하게 주장하지 않는다.
- 전체 생활감 완성이나 현장 흔적 복원으로 판정하지 않는다. 원래 돌의 규칙적인 수평 배열과 일부 넓은 조용한 흙 면은 남는다. 세 디자이너의 실제 검수와 한계는 `VISUAL_REVIEW.md`에 분리해 기록했다. 최종 4시점은 root가 실제 이미지로 확인했다.
- 렌더 프로세스는 정상 종료했다. 새 worktree·정본 승격·앱 통합·커밋·푸시는 하지 않았다. 이전 R2 비교판에는 이 새 결과로 가는 링크를 추가했다.

첫 렌더는 모래 결이 보였지만 전면의 밀도가 비슷해 카펫처럼 읽힐 위험이 있었다. 아트디렉터는 생활감 구분을 미통과로 판정했다. `first-pass-sandy-uniform/`에 실제 이미지·재질·SHA·당시 코드를 보존하고, 차분한 면의 입자 대비를 낮추며 실제 보이는 두 비대칭 쓸림 그룹과 출입구 다짐을 분리한 수정본을 렌더 중이다. 첫 시안의 남은 렌더는 중단했다. 담장 shader는 변경하지 않고 검증된 라이브러리에서 재사용한다.

두 번째 시안에서는 생활 구분이 보였지만 쓸림이 해변 빗질처럼 강하다는 검수 의견이 있었다. `second-pass-swept-strong/`에 보존하고, 최종 조율에서는 쓸림 색 대비와 법선 강도를 낮추고 차분한 면에 약한 모래 결을 남겼다. 두 번째 실행에서 끝난 담장 A는 같은 R1·카메라·빛·24 samples·seed 15의 SHA를 확인해 재사용한다. 눈에 보이는 결과 판정은 최종 `VISUAL_REVIEW.md`를 따른다.

흙을 검수한 세 번째 8장 세트는 `third-pass-soil-accepted-wall-subtle/`에 보존했다. 담장 변화는 확대에서만 미세하게 읽혀 작은 화면의 큰 개선으로 판정하지 않았다. 마지막 담장 보정은 기존 광물면 명도 노드의 입력 `.28–.72` → 배율 `.84–1.12`, 거친 군집에서만 Bump Distance `.010–.014`이다. 색상 계열·미세 grit·줄눈·흙벽·접점·흙 shader는 보존한다. 범위의 중심은 같지만 실제 렌더 평균 명도가 보존된다고 주장하지 않는다.

`refine_wall_library.py`는 빈 Blender에서 검증된 라이브러리의 돌 77개 재질만 조정하고 나머지 shader signature가 같은지 검사한다. 이후 정확한 R1에 `run.py -- apply render ...`로 다시 연결하며 `reconstruction-verification.json`이 실제 형상·UV·대상 외 슬롯 보존을 재검사한다. 최종 라이브러리는 `living-yard-wall-r3-refined.blend`이다. 새로 처음부터 제작할 경우 `wall_patch.py`에도 같은 보정을 반영해 두었다.

## 달라진 설계

R2의 미세 다짐 보정은 실제 변화가 작고 조감도에서 대문 지붕에 가렸다. R3는 마당 전역의 표면을 다시 설계하며, 흙의 색뿐 아니라 모래 응집·짧고 끊기는 쓸림·밟혀 눌린 면의 결을 구분한다. 담장은 기존 광물색을 보존하면서 거친 면과 차분한 면을 나누고 실제 지면과 만나는 일부 구간에만 끊기는 흙 접점을 둔다.

- 흙: 3–12cm 응집 결, 약한 5–8mm grit, 일부 15–55cm 쓸림 묶음. 크기는 shader 설계상의 주파수 범위이지 현장 측정 입도나 실제 돌 크기가 아니다.
- 담장: 큰 광물 몸체, 중간 크기 표면 결, 억제한 미세 grit를 분리한다. 기존 돌별 아이보리·회색·황토색 계열을 유지한다.
- 일러스트의 조용한 큰 면과 건축 위계를 유지한다. 실제 시대의 사용 흔적을 복원했다고 주장하지 않는다.
- 건물·지붕·문·기단·계단·돌 배치·UV·조명은 보존한다. 소품이나 돌 geometry를 추가하지 않는다.

## 디자이너 협업과 소유권

| 담당 | 파일 | 검증 조건 |
| --- | --- | --- |
| soil_designer_r3 | soil_patch.py / SOIL_DESIGN.md | 모래가 읽히고 눌림·쓸림 구별, 반복 타일·전면 자갈 방지 |
| wall_designer_r3 | wall_patch.py / WALL_DESIGN.md | 확인된 담장 207 슬롯, 기존 돌색·돌 배열 보존 |
| art_director_r3 | ART_DIRECTION.md | 실제 이미지와 작은 표시 크기에서 독립 검수 |
| root | run.py / index.html / 검증·렌더 근거 | 두 흙 슬롯+207 담장 슬롯만 변경, 동일 카메라 A/B |

ECC의 역할·파일 범위 분리, Superpowers의 원인 확인·실행 후 검증을 적용했다. Frontend Design Premium은 기존 비교판의 버튼·키보드·포커스·이미지 크기 안정성을 유지하는 데 적용했다. UI UX Designer는 비교판 가독성·색 위계·접근성 범위로 검토하며 3D 재질을 제작하는 커넥터로 취급하지 않는다. 광고·외부 디자인 서비스 가입은 작업에 필요하지 않다.

## 재현

정확한 R1 원본:

`../ildu-estate-yard-wall-r1.blend`

SHA-256: `586b8a5328e7c0deaeff5f340639708c927ea224a429aca70dc313adadddff68`

Blender 5.2.2 LTS에서 새 후보 생성·검증·렌더:

```text
blender -b ../ildu-estate-yard-wall-r1.blend -t 8 --python run.py -- render detail overview wall full
```

검증된 라이브러리만 다시 적용:

```text
blender -b ../ildu-estate-yard-wall-r1.blend --python run.py -- apply
```

필요하면 `apply --output <새 절대 경로.blend>`로 전체 장면을 재구성해 저장한다. 원본 덮어쓰기는 거부한다. 이 폴더의 `.blend`는 실제 Blender 재질 라이브러리이며 geometry는 포함하지 않는다.

## 비교의 의미

A는 R2의 국소 시험 이전인 R1 표면이다. 마당 근접·조감도·고택 전체 A는 검증된 같은 카메라·빛·24 samples·seed 15 원본 PNG를 재사용한다. 담장 A는 R1 장면에서 다시 렌더해 흙까지 같은 상태로 비교한다. B는 R3 재질을 적용한 실제 Blender 렌더다. `render-manifest.json`이 PNG·재질 라이브러리 SHA와 조건을 연결한다.

기술 검사는 시각 성공을 대신하지 않는다. A/B 슬라이더를 반복하지 않아도 B 단독에서 표면의 차이가 읽혀야 한다. 최소 두 위치의 흙·담장 결, 과밀·반복·과도한 명암 여부를 원본과 약 477px 폭에서 확인한다. 건축의 형태·배치 보존 검사와 이 판정은 별개다.

현재 전체 장면에는 기존 R12 문이 남아 있다. 승인된 새 세 문 결합, 공정 이미지 재생성, Flutter 적용, 정본 승격, 커밋·푸시는 이번 후보의 완료 상태에 포함하지 않는다.

## 공식 참고

조회일 2026-10-21. Blender 5.2 LTS [Noise Texture](https://docs.blender.org/manual/de/5.2/render/shader_nodes/textures/noise.html)와 [Principled BSDF](https://docs.blender.org/manual/sr/5.2/render/shader_nodes/shader/principled.html)의 스케일·반사 거칠기 원리를 참고했다. 표면 입자가 빛과 법선에만 의존해 묻히지 않도록 흙의 색에도 제한된 모래 결을 연결했다. 공식 문서는 재질 원리의 근거이며 이 장면의 미적 성공은 실제 렌더 검수로 판단한다.
