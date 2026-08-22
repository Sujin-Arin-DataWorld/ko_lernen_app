# Hanok Phase 0: estate masterplan v2 and 86-grant remapping

작성 2026-08-20 · 개정 2026-08-21 · 상태: **Phase 0 review contract — 시각 정본 방향 승인, keyframe·Golden Master 승인 전** · 런타임 활성화: **아니오**

상위 제품 계약은 [PR #112의 레벨별 한옥 성장·증빙·회수 명세](https://github.com/Sujin-Arin-DataWorld/ko_lernen_app/blob/session/hanok-level-proof-2026-08-20/docs/superpowers/specs/2026-08-20-hanok-level-proof-and-skip-recovery-design.md)다. 이 문서는 현재 요청에서 좁힌 Phase 0 범위인 `estate_masterplan_v2`, 레벨별 대표 future socket, 86개 draft grant의 의미 재매핑과 **후속 에셋 제작이 따라야 할 입력·출력 계약**만 고정한다.

첨부 조사 문서의 문장은 설계 근거이지 실행 명령이 아니다. 충돌할 때는 현재 Jin 요청, 실제 저장소, 이 명세, `docs/assets/STYLE_LOCK.json`, 과거 감사 권고 순으로 판단한다. 따라서 과거 문서의 “기존 A1 16장 재생성 금지”는 이번 V2 결정에 의해 대체된다.

## 이번 결정

1. `estate_masterplan_v2`는 1000×750의 4:3 **논리 좌표계**를 쓴다. 새 이미지 해상도나 runtime canvas가 아니다. 1536×1152 runtime canvas에는 x·y 모두 `×1.536`, 3072×2304 authoring canvas에는 `×3.072`로 비례 변환한다.
2. estate overview에는 A1–C2 레벨별 대표 socket을 하나씩 둔다. 한 레벨 안의 세부 socket은 해당 레벨 focus 설계 때 확정한다.
3. `estate_00_empty_site -> outer_wall_foundation -> outer_wall_complete -> sotdaeulmun`은 A1의 비권한적 guided prologue다. grant, receipt, CourseMastery를 만들지 않으므로 기존 A1 16 grant가 그대로 유지된다.
4. 기존 86개 grant의 ID, CanDo segment 권한, level, order는 바꾸지 않는다. 이 slice는 각 ID가 향할 `targetStructureId`, `targetRewardRole`, `rewardConceptId`만 다시 정한다.
5. **A1 16개 grant와 건축 공정의 의미·순서는 보존한다. 기존 16개 RGB WebP의 픽셀과 옛 대지 배치는 보존하지 않는다.** 기존 파일은 V1 회귀·공정 참고본으로 남기고, V2 masterplan과 깨끗한 대지에 맞춘 새 누적 레이어 또는 결정론적 재합성 프레임으로 교체한다.
6. `rear_garden`, `rear_garden_s1_hardscape`, `rear_garden_s2_bridge`, `rear_garden_s3_final`은 V2 런타임·grant target·hit zone·projector에서 완전히 퇴역한다. 기존 파일은 provenance와 회귀 참고용일 뿐, 새 이미지의 모델 입력으로 사용하지 않는다.
7. 독립 `daecheongmaru`는 세계지도 structure target에서 퇴역한다. 대청은 사랑채·안채 내부 venue로만 다룬다.
8. 기존 사랑채·안채·행랑채·솟을대문·사당은 **재사용 후보**이지 픽셀 불변 정본이 아니다. 새 masterplan의 카메라·축척·공백을 통과할 때만 기하 또는 재질 참고로 재사용한다.
9. Gye, Firebase, CourseMastery, SRS에는 새 read/write 경로를 만들지 않는다.
10. 건축 배치의 권위는 운조루에서 검증된 공간 문법이다. 전면 줄행랑과 솟을대문을 한 경계로 통합하고, 비대칭 사랑 영역, 口자에 가까운 안채와 안마당, 안채에 붙은 부엌·서비스마당, 후면의 별도 사당, 전면→사랑→안채·사당의 세 높이 단계를 사용한다. 특정 문화재를 복원하거나 평면을 복사하지 않는다.
11. 화풍 DNA의 권위는 `hanok_compound`와 웹 `hanok-gate.png` 계보다. 전자는 각진 기와·따뜻한 목재·석재·회벽의 형태 언어를, 후자는 한글소리의 교차 채널 분위기를 제공한다. 기존 PNG를 그대로 합성하거나 runtime bundle에 되살리지 않는다.
12. 향후 픽셀·카메라·원점의 유일한 권위는 승인된 `hanok_visual_keyframe_01`에서 이어지는 한 장의 `estate_v2_golden_master_01`이다. 건물별 독립 생성물을 조합해 Golden Master를 만들지 않는다.

## 에셋 판정: 무엇을 보존하고 무엇을 교체하는가

| 대상 | V2 판정 | 이유 |
|---|---|---|
| Faceted Minhwa, 좌상단 광원, north-up에 가까운 elevated 4:3 camera | 보존 | 제품 정체성과 하나의 Golden Master 계보 |
| A1 터잡기→입택 16단계의 의미와 grant 연결 | 보존 | 학습·건축 서사의 유효한 골격 |
| 현재 `a1/states/*.webp` 16장 | 참고·회귀 전용 | 모두 옛 담·식생·길이 구워진 1536×1152 RGB full frame이라 한 장만 교체할 수 없음 |
| 현재 `site_base_light.png`와 `map/structures/*` | provenance·기술 계약 참고 후 교체 | full-canvas 합성 계약은 유효하지만 정면 건물과 사선 대지의 카메라가 일치하지 않고 빈 마당을 막음 |
| `hanok_compound/site_base.png`와 건물 6장 | **화풍 DNA 정본, 픽셀 재사용 금지** | 한글소리다운 면분할·기와·목재·석재는 보존하되 혼합 캔버스·서로 다른 yaw 때문에 직접 합성하지 않음 |
| 웹 `hangul-sori-site-local/public/hanok-gate.png` | 교차 채널 분위기 참고 | 산·한지·색채의 한글소리 정체성만 참고하며 장식 밀도나 배치는 지도에 복사하지 않음 |
| 3072×2304 넓은 종가 trial | 공간 proof 전용 | 넓은 마당과 운조루형 전면 경계는 유효하지만 하단 crop, 과대한 C2 터, 오른쪽 밀집을 그대로 채택하지 않음 |
| 현재 `rear_garden*` | 완전 퇴역 | 후원 메가 레이어를 새 빈 터에 다시 끌고 오지 않음 |
| 기존 완성 건물 5채 | 의미·기능 참고 | 독립 픽셀은 새 Golden Master에 붙이지 않고 동일 원본에서 다시 파생 |
| 외담·내담·사당담·중문·문 접속부 | 신규 모듈 | 공간 위계를 만들고 단계적으로 확장하기 위해 필요 |
| 후면/좌상단 빈 영역 | `transmission_expansion`으로 예약 | 완성 정원이 아니라 C2 서고/별당 중 하나를 위한 구조 소켓 |

`rear_garden`을 제거한 뒤 같은 자리에 연못·정자·꽃·괴석을 다시 그려 넣는 것도 금지다. 선택형 정원은 이 core V2 밖의 후속 기능이며, 그때도 새 빈 소켓에서 별도 계약으로 시작한다.

## Estate layout

좌표 원점은 좌상단이다. 운조루의 평면을 복제하지 않고 **전면 줄행랑+솟을대문, 비대칭 사랑 영역, 口자 안채, 부착형 서비스마당, 후면 사당, 세 높이 단계**라는 공간 문법만 사용한다. 3072×2304 넓은 trial에서도 **낮은 밀도, 크고 연속된 중앙 마당, 읽히는 영역 위계**만 가져온다.

```text
y=0
┌──────────────────────────────────────────────────────────────┐
│ C2 전승 확장 터        口자 안채 · 안마당          별도 사당 영역 │
│ 서고/별당 중 하나 ?    중앙 비움                   사당담·일각문 │
│                                                              │
│                  부엌·서비스마당 ┐   내담 + 중문              │
│                                                              │
│              비대칭 사랑채·작은 누마루                       │
│                 하나로 이어진 넓은 사랑마당                   │
├──────── 전면 줄행랑 ──── 솟을대문 ──── 전면 줄행랑 ──────────┤
│                         바깥길                               │
└──────────────────────────────────────────────────────────────┘
                                                               y=750
```

### 고정 zone

| Zone | 논리 rect `x,y,w,h` | 1536×1152 환산 rect | 역할 |
|---|---:|---:|---|
| `zone_outer_approach` | `0,660,1000,90` | `0,1014,1536,138` | 바깥길과 첫 진입 여백 |
| `zone_front_haengrang_boundary` | `50,590,900,70` | `77,906,1382,108` | 전면 줄행랑과 중앙 솟을대문의 통합 경계축 |
| `zone_sarang_court` | `260,360,480,230` | `399,553,737,353` | 하나로 이어진 큰 사랑마당 |
| `zone_sarang_complex` | `310,275,370,100` | `476,422,568,154` | 비대칭 큰사랑·작은사랑·누마루 영역 |
| `zone_inner_threshold` | `440,230,120,55` | `676,353,184,84` | 내담·중문 |
| `zone_anchae_courtyard` | `300,55,400,200` | `461,84,614,307` | 口자 안채·안마당 |
| `zone_attached_kitchen_service` | `680,245,240,260` | `1044,376,369,399` | 안채에 붙은 부엌·작업마당·우물·곳간 |
| `zone_rear_shrine` | `750,45,170,170` | `1152,69,261,261` | 후면의 별도 사당·의례 영역 |
| `zone_transmission_expansion` | `80,55,190,200` | `123,84,292,307` | C2 서고/별당 중 하나의 빈 구조 소켓 |

zone은 건물 외곽선이 아니라 예약 영역이다. 생성 모델이 숫자를 정확히 따르지 못하므로 첫 trial에서는 이 표를 시각 비율 가이드로 쓰고, 승인본을 1000×750 좌표에 다시 측정해 최종 bbox를 manifest에 고정한다.

### Visual budget와 합격 기준

- 건축·담: 전체의 **최대 35%**
- 의도적으로 빈 마당: 전체의 **최소 40%**
- 통로·future socket: 약 15%
- 수목·생활 소품: **최대 10%**
- 사랑마당 zone 내부: 최소 **60%가 하나로 이어진 무장애 흙면**
- 안마당 중앙: 최소 60% 비움
- 사랑마당 중앙에는 나무, 돌 군락, 꽃, 장독, 우물, 석등, 징검돌 길을 놓지 않음
- 수목은 외곽 프레임에만 0–2군락. 큰 나무가 건물·future socket을 가리지 않음
- 전체 건물을 다 놓은 최종 구조 trial에서도 마당이 “건물 사이 남은 틈”이 아니라 독립 공간으로 먼저 읽혀야 함

## 시각 진행 트랙

estate setup과 A1 grant 번호를 섞지 않는다.

```text
estate_00_empty_site                 # 기본 무대, grant 없음
boundary_01_outer_wall_foundation    # guided prologue
boundary_02_outer_wall_complete      # guided prologue
boundary_03_sotdaeulmun              # guided prologue

a1_01_site_setout
a1_02_plan_layout
a1_03_foundation_gidan
a1_04_cornerstones_choseok
a1_05_timber_preparation
a1_06_columns
a1_07_beams_changbang
a1_08_purlins_sangnyang
a1_09_rafters_roof_frame
a1_10_roof_base
a1_11_giwa_roof
a1_12_wall_frame_sujang
a1_13_earth_walls
a1_14_ondol_maru
a1_15_changho_finish
a1_16_landscape_move_in
```

`a1_16_landscape_move_in`의 landscape는 정원 완성이 아니다. 사랑채 사용 흔적 1–2개와 가장자리 수목 최대 한 군락만 허용한다.

## 에셋 제작 계약

### 제작 순서

실제 첫 제작물은 `estate_00_empty_site`도 완성 estate도 아닌 **전면 경계·사랑마당·사랑채 일부를 담은 `hanok_visual_keyframe_01` 한 장**이다. 이 한 장으로 compound 계보의 화풍, 최종 카메라, 전면 공간 문법, 건물 축척과 빈 마당을 먼저 승인한다. 미승인 화풍으로 전체 estate나 10장 batch를 만들지 않는다.

1. `hanok_visual_keyframe_01` 한 장으로 화풍·카메라·전면 통합 경계·사랑마당 공백을 승인한다.
2. 승인 keyframe을 유일한 실제 이미지 reference로 사용해 `estate_v2_golden_master_01` 한 장을 만든다.
3. Golden Master에서 건물 bbox와 마당 polygon을 실측해 masterplan을 한 번 갱신한다.
4. Golden Master와 같은 카메라·원점으로 `estate_00_empty_site`를 파생한다.
5. 전면 경계 기단, 전면 벽체, 솟을대문 3장을 누적 파생한다. B1 행랑 보상은 이 경계의 양옆이 줄행랑으로 살아나는 후속 층이다.
6. 승인된 Golden Master의 사랑채 최종형에서 A1 16단계를 역분해한다. 각 단계를 독립 장면으로 다시 생성하지 않는다.
7. B1/B2 건물도 Golden Master의 최종형에서 기단→골조→지붕→완성으로 역분해한다.

### 캔버스와 파일

| 용도 | 규격 | mode/format | 비고 |
|---|---|---|---|
| 시각 keyframe authoring | 3072×2304, 4:3 | 8-bit sRGB RGB PNG | 전면 경계·사랑마당·사랑채 일부만 검증, runtime 아님 |
| 구조 master authoring | 3072×2304, 4:3 | 8-bit sRGB RGB PNG | 압축보다 편집·측정 우선 |
| 구조 master runtime preview | 1536×1152 | 8-bit sRGB RGB PNG/WebP | 왜곡 없이 LANCZOS downsample |
| 깨끗한 대지 | 3072×2304 source | opaque RGB PNG | 담·건물·future silhouette 없음 |
| 건물·담·단계 source | 3072×2304 full canvas | true RGBA PNG | 같은 원점·카메라, 투명 밖 픽셀 RGB=0 권장 |
| A1 runtime composite | 1536×1152 | RGB WebP quality 82, method 6 | 최종 구현 시 hard max 350,000 bytes 목표 |

생성 도구가 정확한 4:3을 주지 않으면 **늘이거나 찌그러뜨리지 않는다.** 중앙 crop으로 정확한 4:3을 만든 뒤 3072×2304로 LANCZOS 리사이즈한다. 첫 trial은 알파 없는 full-scene RGB다. source layer와 runtime composite를 같은 파일로 취급하지 않는다.

### 스타일·수치 게이트

- 이 pending-review keyframe에 한해 Jin의 2026-08-21 승인으로 `hanok_compound`의 **화풍 DNA 참조 금지**를 제한적으로 해제한다. raw PNG의 runtime 재사용·bundle 재등록·직접 합성은 계속 금지다.
- keyframe 승인 전 정본 우선순위: 이 명세의 시각 정본 결정 > `hanok_compound`의 형태·재질 DNA > 웹 `hanok-gate.png`의 교차 채널 분위기 > 기존 F-C 수치 게이트. 현재 V2 `site_base_light`와 정면 구조물은 미적 앵커가 아니다.
- keyframe 승인 후 정본 우선순위: 승인 `hanok_visual_keyframe_01` > 승인 `estate_v2_golden_master_01` > 새로 측정할 V2 family gate. 전역 `STYLE_LOCK.json`은 승인본이 생기기 전에는 수정하지 않는다.
- 카메라: north-up에 가까운 isometric-ish elevated view, 4:3 전체 대지, 좌상단 부드러운 광원
- Faceted Minhwa: hard-edged 면분할, 무광, 얇은 한지 그레인, 검은 외곽선 없음, glossy 3D·photoreal·수채 wash 금지
- 첫 trial F-C-estate 측정 범위: saturation mean `0.24–0.65`, value mean `0.34–0.70`, neon fraction 최대 `0.030`
- 기존 F-C-a1states의 매우 좁은 `sat 0.34–0.40`, `value 0.55–0.63`, `neon <=0.005`는 V1 16장의 실측값이다. V2 첫 trial을 이 값에 억지로 맞추지 않고, 승인된 V2 master를 재측정해 V2 family gate를 새로 고정한다.
- A1 누적 상태의 구조 연속성 목표: 이전 상태 recall 최소 `0.97`, 고정 모서리 drift 최대 `2px` at 1536×1152

### Work 세션이 읽을 것과 생성 호출에 첨부할 것

**텍스트로 읽을 파일**

1. 이 명세
2. `AGENTS.md`
3. `docs/P2A_HANOK_COMPOUND_ASSET_SHEET.md`
4. `docs/assets/STYLE_LOCK.json`의 `generationFacts`, `F-C-estate`, `F-C-a1states`
5. `docs/HANOK_ASSET_INVENTORY_2026-08-17.md`의 F-C·F-F 항목. F-F의 과거 입력 금지는 이 pending-review keyframe에만 명시적으로 예외 처리하며 runtime 재사용 금지는 유지한다.

**육안으로만 볼 이미지**

- `assets/illustrations/hanok_compound/site_base.png`: 흙·석재·회벽·한지와 elevated camera DNA. 옛 구획·연못 자리는 기각
- `assets/illustrations/hanok_compound/sotdaeulmun.png`: 각진 기와·목재·석재와 작은 단청 accent 참고. 독립 아이콘 구도는 기각
- `assets/illustrations/hanok_compound/haengrangchae.png`: 낮고 절제된 주거 행랑의 비례 참고
- `assets/illustrations/hanok_compound/sarangchae.png` (`1402×1122 RGBA`, `sha256 1da81a60019b341d7581264aebf0a292b72e0951aaaab0c0e97ce25b229137db`): **첫 keyframe의 실제 style reference**. 기와 면분할, 따뜻한 목재, 회벽, 석재, 선명한 실루엣 참고
- `assets/illustrations/hanok_compound/anchae.png`: 여러 동을 한 카메라로 읽히게 하는 지붕 리듬 참고. 그대로 복사하지 않음
- `hangul-sori-site-local/public/hanok-gate.png` (`1024×1536`, `sha256 3c6b195a031df448f5fc23e6bf2ba201440d17560650f78050d44a616d9a98e6`): 한지·산·색채의 교차 채널 한글소리 분위기만 참고. 호랑이·까치·꽃·장식 밀도는 지도에 복사하지 않음
- 기존 `personal_hanok_v2/map/site_base_light.png`와 `map/structures/sarangchae.png`: provenance와 실패 비교용. 새 keyframe의 카메라·색·건물 형태 앵커로 사용하지 않음
- 넓은 구조 proof `C:/dev/hangulsori/ko_lernen_app_worktrees/estate-v2-trial01-codex/assets_unused/pending_review/personal_hanok_v2/estate_v2_trials/estate_v2_complete_structure_trial_01.png` (`sha256 282e08fd15565654b59dd7717da4ee1fbc4ee741068e3c711771a7888412fa1b`): **파일이 존재할 때만 선택적으로 육안 확인**하여 전면 통합 경계, 연속 마당, 전체 축척만 참고한다. 없으면 이 명세의 zone·비율·prompt만으로 진행하며 생성 호출에는 어느 경우에도 첨부하지 않는다.

**첫 생성 호출에 실제 이미지 reference로 첨부할 것은 정확히 한 장**이다.

`assets/illustrations/hanok_compound/sarangchae.png`

Work 에이전트는 나머지 이미지를 먼저 육안 분석해 화풍·공간 제약을 텍스트 prompt로 옮기되 생성 모델에는 두 번째 이미지로 첨부하지 않는다. 첫 출력은 legacy PNG 복사본이 아니라 새 카메라의 opaque full-scene keyframe이어야 한다. `rear_garden`, Gye, 레거시 `hanok_stages`는 읽거나 첨부하지 않는다.

### 첫 1장 trial용 Work 요청문

아래 블록은 새 Work 세션에 그대로 전달할 수 있다.

```text
AGENTS.md와 아래 Phase 0 명세를 먼저 읽고, 새 격리 worktree에서 작업해줘.
이 명세는 아직 미커밋 review 문서이므로 현재 Phase 0 worktree의 아래 절대 경로를
읽기 전용으로 참조하고 네 worktree에서 수정하지 마.
C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-level-phase0/docs/superpowers/specs/2026-08-20-hanok-phase0-estate-masterplan-v2.md

이번 작업은 코드 구현이나 완성 estate 제작이 아니라 personal Hanok V2의
시각 정본 keyframe 1장 제작이야. 10장 batch를 만들지 말고 정확히 후보 1개만
만들어. runtime asset, pubspec, catalog, STYLE_LOCK, provenance ledger는 바꾸지 말고 결과는
assets_unused/pending_review/personal_hanok_v2/estate_v2_trials/
hanok_visual_keyframe_01.png 로 둬.

생성 전에 다음을 육안 확인해:
- assets/illustrations/hanok_compound/의 site_base, sotdaeulmun, haengrangchae,
  sarangchae, anchae: 한글소리 기존 Faceted Minhwa의 화풍 DNA
- hangul-sori-site-local/public/hanok-gate.png: 한지·산·색채의 교차 채널 분위기만 참고
- 넓은 3072x2304 구조 proof: 전면 줄행랑+솟을대문, 넓은 사랑마당,
  상대적으로 작은 건물의 공간 비율만 참고
- 현재 personal_hanok_v2의 site_base_light와 sarangchae는 provenance/실패 비교용

하지만 이미지 생성 호출에는
assets/illustrations/hanok_compound/sarangchae.png
한 장만 style reference로 첨부해. 다른 이미지는 생성 모델에 첨부하지 말고
네가 관찰한 화풍·공간 제약을 prompt에 번역해. legacy PNG의 실루엣·픽셀·검은/투명
배경을 복사하지 마. rear_garden, Gye, legacy hanok_stages는 참조하지 마.

목표는 최종 estate 카메라에서 본 전면 공간 keyframe이야. 완성 estate 전체를 넣지 마.
- 화면 아래를 가로지르는 낮고 긴 전면 줄행랑
- 줄행랑 중앙과 구조적으로 연결된 솟을대문
- 대문 안쪽부터 화면 중앙까지 하나로 이어진 넓고 평평한 사랑마당
- 마당 북쪽 가장자리의 비대칭 사랑채 일부와 작은 누마루 한 칸
- 사랑채 뒤쪽에 중문 방향만 살짝 암시하고 안채·사당·C2 건물은 아직 그리지 않음

이 keyframe에서 건물·담은 최대 35%, 의도적인 빈 마당은 최소 45%,
수목·생활소품은 최대 5%여야 해. 사랑마당 안쪽 최소 65%는 하나로 연결된
평평한 흙면이어야 해. 중앙에는 나무, 꽃, 괴석, 장독, 우물, 석등,
징검돌 길을 놓지 마. 연못, 다리, 정자, 완성 후원은 전부 금지야.

카메라는 fixed 4:3, north-up에 가까운 elevated isometric-ish view,
좌상단 부드러운 광원. 줄행랑·솟을대문·사랑채가 하나의 camera/yaw/scale을
공유해야 해. 건물을 화면을 채우는 영웅 아이콘처럼 키우지 마.

화풍은 현재 V2의 창백하고 매끈한 정면 sprite가 아니라 hanok_compound 계보다.
기와 한 장 한 장의 각진 면분할, 따뜻한 호박빛 무광 목재, 크림 회벽, 밝은 석재,
얇은 한지 결, 선명하지만 검은 외곽선 없는 실루엣을 유지해. 단청은 솟을대문 처마 아래
청록·황토·주홍의 작은 accent만 허용하고 궁궐·사찰처럼 화려하게 만들지 마.
no glossy 3D, no photorealism, no watercolor wash, no anime/cartoon,
no Chinese palace roof, no Japanese garden, no people, no animals, no text.

2K 이상 4:3으로 생성하고, 결과가 정확한 4:3이 아니면 늘이지 말고 center-crop한 뒤
LANCZOS로 3072x2304 sRGB RGB PNG로 정규화해. 후보는 하나만 남겨.
완료 보고에는 생성 도구/모델, 실제 첨부 reference 1장, 원본 출력 크기,
최종 mode/크기, sha256, visual budget 육안 판정과 STYLE_LOCK F-C-estate
sat/value/neon 측정값을 포함해. commit, push, PR은 하지 마.
```

생성 모델에 넣을 핵심 영문 scene prompt는 다음이다. Work 에이전트가 사용하는 도구의 reference/edit 형식에 맞게 감싸되 의미를 줄이지 않는다.

```text
Create ONE NEW visual-canon keyframe for Hangul Sori's spacious personal Korean
jongga estate. This is not the complete estate and not a reconstruction of a
named heritage house. Use the attached legacy Hangul Sori sarangchae ONLY as
style DNA for faceted black roof tiles, warm matte amber wood, cream plaster,
light faceted stone, crisp silhouette, and subtle hanji grain. Do not copy its
pixels, isolated icon composition, transparent background, or exact silhouette.

Use one coherent north-up-ish elevated isometric camera. Across the lower edge,
show a long, low residential haengrang row with a centered sotdaeulmun built into
the same front boundary. Immediately inside it, show a very broad continuous
sarang courtyard of clean compacted earth. Along the north edge of the visible
courtyard, show only enough of an asymmetrical sarang complex and one modest
numaru bay to prove depth, shared yaw and scale. Hint at the later jungmun axis,
but do not show the anchae, shrine, transmission building, or finished estate.

SPACE IS THE HERO. Architecture and walls occupy no more than 35 percent of the
canvas. Intentionally empty courtyard occupies at least 45 percent. At least 65
percent of the sarang courtyard is one connected, unobstructed plane of clean
compacted earth. Do not enlarge any building into an isolated hero icon.

Keep the courtyard alive through subtle earth facets, wear variation and soft
eave shadows, not through decorative objects. Vegetation and life props together
occupy no more than 5 percent and stay at the outer frame only. No central tree,
no flower beds, no rock garden, no stepping-stone
trail through the central yard, no jars, no well, no lanterns, no pond, no
bridge, no pavilion, no completed rear garden.

Style: the lively original Hangul Sori hanok_compound visual DNA, refined into a
premium Faceted Minhwa scene: clearly visible hard-edged geometric planes on each
roof tile, warm matte amber wood, cream plaster, pale faceted stone, restrained
charcoal roofs, and thin aged-hanji grain. Use tiny teal, ochre and muted red
dancheong accents only under the sotdaeulmun eaves; never temple or palace
ornament. No drawn black outlines. Soft upper-left light. Every structure shares
one camera, yaw, scale and shadow system.

ABSOLUTELY AVOID: copying legacy pixels, a black or transparent background,
current-V2 pale frontal sprite language, detached gate icons, a gate disconnected
from the haengrang row, crowded landscaping, fantasy or resort garden, giant
rocks, dense flowers, decorative clutter, rear garden, isolated icon-like or
oversized buildings, modern objects, people, animals, readable text, labels,
Chinese palace architecture, Japanese garden language, pagoda roofs, glossy 3D
render, photorealism, watercolor wash, anime, cartoon, black outlines, sepia wash,
or fog hiding empty space.
```

### 첫 trial 합격·반려 기준

한 장을 만든 뒤 아래 항목을 Jin이 육안 승인하기 전에는 완성 estate나 10장 batch로 넘어가지 않는다.

- 100px thumbnail에서도 전면 줄행랑+솟을대문→사랑마당→사랑채의 깊이가 읽힘
- 솟을대문이 양옆 줄행랑과 한 구조·기단·camera에 속하며 독립 gate icon처럼 보이지 않음
- 사랑마당이 화면에서 가장 먼저 보이는 하나의 연속 면임
- `hanok_compound`의 각진 기와·따뜻한 목재·회벽·석재 DNA가 읽히되 legacy 픽셀 복사나 검은 배경이 없음
- 현재 V2의 정면·창백한 sprite나 건물별 sticker collage로 돌아가지 않음
- `rear_garden`의 연못·다리·정자·꽃·괴석·장독 계보가 0개
- 모든 건물이 같은 camera·yaw·축척·광원에 속함
- F-C-estate sat/value/neon 범위 통과
- 한지 그레인이 있으나 누런 wash나 흐릿한 수채화가 아님

### 10장 batch 사용 시점

keyframe 승인 전에는 Golden Master나 batch를 만들지 않는다. 승인 뒤에도 독립적인 full-scene 10장을 한꺼번에 생성하지 않는다.

1. 승인 시각 keyframe 1장
2. keyframe을 유일한 actual reference로 쓴 Golden Master 1장
3. Golden Master에서 파생한 깨끗한 빈 대지 1장
4. 전면 경계 guided prologue 3장
5. Golden Master에서 파생한 사랑채 final과 투명 construction kit 고정
6. 그 뒤 A1 `01–10` 결정론적 합성 batch
7. 연속성 검사 후 A1 `11–16` batch

batch의 10장은 “서로 다른 장면 10개”가 아니라 **같은 base·같은 origin·같은 승인 부품을 쌓은 누적 상태 10개**여야 한다.

## Level sockets and camera reveal

| Level | Overview socket | Center | 첫 camera reveal | 허용 target |
|---|---|---:|---|---|
| A1 | `hanok_socket_a1_sarangchae_build` | 500,470 | 바깥길·전면 줄행랑 경계·대문·사랑마당 | 사랑채 |
| A2 | `hanok_socket_a2_sarangbang_life` | 490,325 | 비대칭 사랑 영역·사랑방 focus | 사랑방, 사랑채 생활 흔적 |
| B1 | `hanok_socket_b1_inner_connection` | 500,255 | 전면 행랑·내담·중문·안채 연결 | 내담, 중문, 행랑채, 작업마당, 안채, 안방 |
| B2 | `hanok_socket_b2_household_ritual` | 790,275 | 안채 부착 서비스마당과 후면 사당 | 서비스마당, 장독대, 곳간, 우물, 생활 경계, 사당 |
| C1 | `hanok_socket_c1_estate_stewardship` | 500,155 | 사랑 영역부터 안채·사당까지 집 전체 | 집 전체 유지보수 |
| C2 | `hanok_socket_c2_transmission` | 175,170 | 전체 estate와 축소된 전승 확장 터 | 기록 보관, 서고, 별당, 문집, 방문객 해설 |

모든 socket은 최소 48 logical hit target을 예약한다. A2–C2 overview 기본 표현은 실제 후보 그림이나 실루엣이 아닌 `futureQuestionMark`다. 이 계약은 위치와 의미만 고정하며 색, 컴포넌트, semantic label 구현은 Phase 1과 읽기 전용 future socket slice에서 맡는다.

## Grant remapping

원본은 `tools/content_factory/drafts/hanok_grants.json`의 unpublished 86개다.

| Level | Count | V2 meaning |
|---|---:|---|
| A1 | 16 | 사랑채 건축 공정 16단계 의미 보존, V2 시각 프레임은 신규 합성 |
| A2 | 16 | 사랑방 가구·생활 흔적·사랑채 온기 |
| B1 | 18 | 내담·중문·행랑채·작업마당·안채 연결 |
| B2 | 20 | 곳간·장독대·우물·생활 경계·사당 |
| C1 | 8 | 기와·배수·마당·창호 보수와 계절 관리 |
| C2 | 8 | 서고·별당·문집·현판·방문객 해설 |

level policy에서 A1은 `rebuildFromApprovedGoldenMaster`다. 이는 기존 16개 grant의 의미·순서를 보존하되 현재 RGB WebP 픽셀을 유지한다는 뜻이 아니며, 승인된 Golden Master에서 새 누적 상태를 파생한다는 뜻이다. A2–C2는 모두 `futureSocketOnly`이고 Phase 0에서 실제 asset ID를 배정하지 않는다.

`rewardConceptId`는 학습 의미를 추적하기 위한 semantic label이지 현대 소품의 literal art brief가 아니다. `schedule_board`, `banner`, `record`, `plaque`처럼 이름에 현대 물건이나 글이 암시되어도 estate overview에는 가독 텍스트·현대 표지판을 그리지 않고, 향후 focus 설계에서 목재 칸막이·등불·보관 구획·문서함처럼 시대에 맞는 재질과 기능으로 번역한다. 이 정책은 `representationPolicy`의 `conceptIdsAreSemanticLabels: true`, `literalModernPropTransfer: false`, `readableTextInEstateOverview: false`, `periodAppropriateMaterialTranslation: true`로 고정한다.

전체 86행은 `tools/content_factory/drafts/hanok_grant_remapping_v2.json`에 있다. 특히 충돌하던 기존 매핑은 다음처럼 바뀐다.

| Existing grant ID | 이전 reveal 의미 | V2 target concept |
|---|---|---|
| `hanok_a2_lost_phone` | 솟을대문 기단 | 사랑방 아궁이 온기 |
| `hanok_a2_ktx_ticket` | 솟을대문 골조·지붕 | 사랑방 등불 |
| `hanok_a2_rent_bank_transfer` | 솟을대문 완성 | 사랑채 굴뚝 연기 |
| `hanok_b2_public_wording_revision` | 독립 대청 기단 | 곳간 기단 |
| `hanok_b2_collaborative_feedback` | 독립 대청 골조 | 곳간 골조 |
| `hanok_b2_digital_source_judgment` | 독립 대청 완성 | 곳간 완성 |
| `hanok_c1_evidence_validity` | 후원 hardscape | 기와 점검 |
| `hanok_c1_evidence_limits_conclusion` | 후원 다리 | 배수로 정비 |
| `hanok_c1_risk_uncertainty` | 후원 완성 | 마당 표면 보수 |

기존 C1 별당 4단계 후보도 C1에 건물을 새로 세우지 않도록 봄·여름·가을·겨울 관리 round로 이동한다. 별당은 C2 전승 영역의 future concept 하나로만 남고, 승인된 runtime asset으로 간주하지 않는다. Core V2 overview에는 서고와 별당을 동시에 독립 건물로 그리지 않고 `transmission_expansion`의 선택 가능한 typology로 예약한다.

## Machine-readable gates

`tools/content_factory/build_hanok_grants.py --check`가 기존 86-grant source/append-only ledger 검사와 함께 다음을 fail closed로 확인한다.

- 6레벨에 대표 socket과 camera reveal이 정확히 하나씩 있고 A1→C2 순서다.
- `architecturalGrammar`가 전면 통합 행랑·비대칭 사랑·口자 안채·부착형 서비스마당·후면 사당·세 높이 단계를 정확히 고정한다.
- `visualCanon`이 compound visual DNA와 single Golden Master 계보를 고정하고 legacy pixel 직접 재사용과 runtime 승격을 막는다.
- zone ID 집합이 승인된 9개 영역과 정확히 일치하고 옛 분리형 `zone_work_service`·`zone_outer_boundary`가 없다.
- socket 좌표·viewport가 4:3 논리 canvas 안에 있고 48dp target이 예약된다.
- guided boundary prologue는 grant ID가 없고 `presentationOnly`다.
- remap 86행이 원본 grant ID 집합과 순서를 정확히 보존한다.
- A1 asset policy는 `rebuildFromApprovedGoldenMaster`, A2–C2는 `futureSocketOnly`다.
- concept ID는 semantic label이며 현대 소품·가독 텍스트를 estate overview에 literal하게 옮기지 않는다.
- 각 target structure가 해당 level socket의 allowlist 안에 있다.
- A2 솟을대문 3행, B2 독립 대청 3행, C1 후원 3행의 새 의미가 정확하다.
- C1 8행 전부가 estate stewardship이며 퇴역 structure가 target에 없다.
- JSON은 `phase0Review`, `runtimeEnabled: false`이고 image asset 경로나 Firebase 설정을 포함하지 않는다.

검증 명령:

```bash
python tools/content_factory/build_hanok_grants.py --check --verify-git-history --base-revision HEAD
python -m unittest tools.content_factory.test_build_hanok_grants tools.content_factory.test_hanok_phase0_contract
python tool/check_style_lock_docs.py
git diff --check
```

## 이번 PR 밖

- 이미지 생성·편집·승격, pubspec 또는 runtime asset catalog 변경
- 기존 runtime A1 16장 교체와 renderer의 base+RGBA layer 구현
- `SoriHanokFutureSocket` Flutter 구현, route 연결, feature flag
- 외부 증빙 issuer allowlist, native level 정책, 보존·삭제·이의제기 정책
- Firebase Storage, Firestore, Rules, callable, reviewer surface
- CourseMastery, SRS, XP, Gye 상태 변경

따라서 이 slice의 승인 대상은 논리 배치, level socket 대표 위치, camera reveal 순서, 86개 의미 매핑과 에셋 제작 계약이다. Work 세션의 `hanok_visual_keyframe_01`과 후속 Golden Master는 이 계약을 검증하는 pending-review 입력이며, 별도 승인·검증·승격 전에는 runtime asset이 아니다.
