# 담장 R3 표면 설계 — 2026-10-21

현재 상태는 Python 패치 작성·정적 검사다. Blender 실행, 저장, 렌더와 사용자 승인은 부모 통합 단계에서 별도로 확인한다.

`wall-after.png` 실제 픽셀과 R1 `build_surfaces.py`, `material_patch.py`, `material-changes.json`, `REVIEW.md`, `MATERIAL_COUNCIL-20261021.md`를 읽었다. 현재 벽은 기존 아이보리·회색·황토색을 유지하지만 비슷한 잔입자와 돌의 수평 단이 규칙적으로 이어진다. 형상을 바꾸지 않는 범위에서는 반복되는 실루엣을 없앨 수 없다.

기존 돌색의 shader 연결을 그대로 이어받는다. 비주기 world 좌표의 35cm~1m 광물 몸체를 0.91~1.05 명도로만 변조하고, 기존 stone island별 명도 차이는 0.965~1.035에 제한한다. 색상 랜덤화와 새 팔레트는 없다. 줄눈·흙바탕의 기존 색은 유지하며 어두운 경계선을 더하지 않는다.

표면은 3~8cm 광물면과 별도의 미세 grit, normal 전용 잔결로 나눈다. 큰 군집 마스크가 grit의 반응을 나눠 조용한 돌면을 남긴다. 이전 이미지 normal의 전면 분말감을 복사 재질에서 70%로 낮춘다. stone의 meso bump distance 10mm × strength 0.16~0.55, fine grit 2.5mm × 0.18~0.62이며 실제 displacement는 없다. 거친 부분의 분포와 화면 크기에서 보이는 정도는 새 렌더로 판정해야 한다.

접지에는 R1 마당 두 mesh를 한 번씩 읽은 world BVH만 쓴다. 담장 하단의 실제 기존 vertex와 마당의 높이 차이가 -8~26cm인 곳만 후보로 삼고, 최소 4m 간격의 최대 24개 국소 접점을 고른다. 대체로 1.9m 이내의 짧은 폭과 약 19cm 높이 안에서 부드럽게 끊기는 반응이다. 특정 높이의 전역 띠, moss, 검은 때, 돌 둘레선은 없다. shader에는 숫자 좌표만 저장하며 외부 object 참조가 없다. terrain 밖에서 접점을 찾지 못하면 해당 곳의 접지 효과를 생략한다.

범위는 R1 `material-changes.json`의 role `stone`, `mortar`, `earthwall` **207개 exact object/slot**이다. 이름 prefix로 새 대상을 늘리지 않는다. 따라서 이미 wall로 명시된 `GyeCraft.main gate right wall bonded end stones v30`과 wall basal fieldstones는 포함하지만 문 자체의 foundation, 계단, 건물 기단, 포석, 지붕은 추가 선택하지 않는다. 새 세 문도 대상이 아니다.

## 부모 통합 인터페이스

```python
from wall_patch import patch_walls, wall_bindings
material_map = patch_walls(scene)  # {직전 R1 material name: copied bpy Material}
report = patch_walls.last_report   # changes / exact slot count / numeric anchors
whitelist = wall_bindings()       # 원본 inventory의 exact 207행
```

R1 native 후보를 연 상태에서 호출한다. 전체 대상 binding이 R1의 `new` 이름과 일치하는지 먼저 검사한 뒤에만 복사·배정한다. 이 함수는 렌더·저장·operator 호출을 하지 않고 object material slot을 `OBJECT` link로 배정한다. geometry/UV/transform/material index/attribute를 쓰지 않는다. 중복 적용은 거부한다. 부모는 baseline과 geometry/UV/transforms 및 whitelist 밖 bindings 동등성을 다시 검증한다.

Blender 상태 검사 스킬의 구조화 상태 우선 원칙을 적용해 대상 slot을 207개 exact whitelist로 묶고 접점을 실제 geometry read로 계산했다. 이는 모션 검증이나 전체 상태 동등성 검사를 완료했다는 뜻이 아니다.

렌더 검수에서는 담장 가까이에서 grit이 느껴지는지, 477px 전체 크기에서 점박이·도드라진 crack·벽보다 먼저 읽히는 접점이 생기는지 확인한다. 원래 돌색과 단·모서리·기와 윤곽은 같은 뷰에서 비교한다. 규칙적인 수평 단은 geometry를 보존한 한계로 명시한다.

## 실제 A/B 독립 시각 검수 — 2026-10-21

부모가 저장한 `wall-A.png`, `wall-B.png`의 원본 1280×960 두 장을 직접 열어 비교했다. 이번 검수에서는 코드를 수정하거나 추가 렌더하지 않았다.

돌면 개선은 두 곳 이상에서 읽힌다. 중앙 긴 담장의 중간 회색 돌 군집(대략 x490~730 / y425~545)은 B에서 미세한 균일 분말보다 크기가 다른 얕은 광물면의 명암이 조금 더 읽힌다. 우측 꺾임 직전의 밝은 돌과 하단 회색 돌(대략 x880~1010 / y485~650)에서도 B의 입자가 약간 더 거칠고 돌면 내부에 덜 균일한 반응이 보인다. 이는 새 돌색이나 줄눈 변화보다 표면 normal과 원래 돌색 위의 제한된 명도 변화로 읽힌다. 조용한 밝은 돌면도 남아 있으며 큰 점박이·검은 균열선·깎인 돌 윤곽은 관찰되지 않는다.

원래 아이보리·회색·황토의 돌 구분, 줄눈 폭·그늘, 수평 단, 모서리, 기와 실루엣은 시각적으로 유지된다. 줄눈 자체의 개선은 이 두 이미지에서 별도 성과로 주장하기 어렵다. 하단 접점도 새로운 연속 오염띠나 진한 테두리는 보이지 않지만, 접지 패치가 사용자가 알아볼 만큼 좋아졌다는 근거는 약하다. B의 마당 자체가 달라졌으므로 주변 흙면의 색·질감 차이는 담장 개선으로 계산하지 않았다.

판정은 **근접 원본에서 표면 개선이 보이는 절제된 후보**다. 작은 전체 화면에서는 차이가 매우 작을 수 있으며, 이 두 원본만으로 477px 실효성이나 강한 모래 촉감을 검증했다고 말하지 않는다. 사용자가 원하는 거친 느낌을 더 명확하게 해야 한다면 다음 조정은 하나만 권한다: 현재 sparse cluster의 3~8cm 광물면 bump distance를 10mm에서 약 14mm로 올려 큰 입자면의 빛 반응을 강화한다. 전면 fine noise·줄눈 대비·색차는 더 올리지 않는다. 이는 제안이며 현재 패치에는 적용하지 않았다.
