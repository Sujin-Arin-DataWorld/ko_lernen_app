# R12 담장·흙마당 재질 후보

2026-10-21 재개·보정. 상태: native 재질 후보 저장·동일성 재검증·전후 6장 검수·packed patch 재적용 검증 완료. 원본 승격·앱 적용·사용자 승인 없음.

## 기준과 범위

- 정본: `canonical/native/ildu-estate-r12-packed.blend`, SHA-256 `b3b51dec9f2d4a7629912326bb224e8cf5595c2a874a1c3c85075a5f742af434`.
- 이 폴더만 생성·수정했다. 새 워크트리를 만들지 않았다. 기존 건물·담장·지형 메시, 좌표, 토폴로지, UV, 계단과 식재 배치는 유지한다.
- 기존 `WALL_SCOPE.json` 163개 목록에만 의존하지 않고 canonical source를 직접 열어 ConnectionGarden, V27/V30 협문 연결 경계, ConnectionLeft 하부 담장, GyeCraft 담장 접지석, North.site 경계를 확인했다. 건물 자체의 벽, 목재, 지붕과 장독대·디딤돌·굴뚝은 재질 변경에서 제외했다.
- 새로운 세 문을 R12에 합치지 않았다. 이 후보 안에는 R12의 기존 문이 그대로 남아 있다.

## 실제 변경

### 흙마당

`Illustrated lived courtyard earth`는 두 지형 메시에서 UV 기반 `Quiet courtyard earth pigment`와 normal image를 반복하고, vertex colour를 혼합했다. 새 재질은 UV를 읽지 않고 world Position을 metre 단위로 사용한다. 넓은 색 변화, 중간 규모의 흙 변화, 비주기 domain warp를 조합해 타일 경계를 만들지 않는다.

기존 복합 디딤돌 메시의 실제 connected island 중심과 작은 접근 돌의 위치를 추출해, 23개 실제 위치 주변만 넓고 약하게 다져진 흙색·반사 차이로 연결했다. 발자국, 바퀴 자국, 새로운 길 형상은 추가하지 않았다. 첫 근접은 너무 평활해 부모 디자이너와 함께 반려했고, 넓은 변화 위에 30~50cm 규모의 낮은 대비 흙색 변화, 약 1.6mm 유효 normal(4mm distance × .4 strength), 미세 쓸림을 추가했다. 거친 모래·자갈·균열 이미지를 사용하지 않았다. 밭 2곳도 같은 비반복 흙색 계열로 바꾸며 원래 이랑 메시를 유지한다.

### 담장

첫 전체 after에서 연속적인 새 돌색이 돌 구분을 없애 콘크리트처럼 보이는 것을 직접 확인해 자체 반려했다. `full-after-initial-rejected.png`, `initial-rejected-render-manifest.json`, 로컬 `initial-rejected-estate.blend`에 남겼다.

보정본의 돌은 원본 BaseColor에 연결된 실제 돌색·돌 구분과 원본 normal의 세부를 유지한다. 원래 texture normal 강도를 65%로 낮춰 과한 미세 대비를 줄이고, 2.2mm의 얕은 shader bump와 .70~.87 roughness를 더했다. 줄눈은 더 건조하고 거친 황토 석회 반사, 흙 바탕은 별도 표면 반응을 사용한다. 기존 개별 돌과 줄눈의 구조는 실제 원본 메시로 남는다. 담장 기와·기와 끝·덮개는 유지한다. 베벨·디스플레이스·새 돌을 추가하지 않았다.

## 검증 방식

Blender 상태 검사 스킬의 구조화된 상태 우선 원칙을 적용했다. 전체 6,135 objects의 타입, 부모, world matrix와 mesh 좌표·edge/loop·polygon topology·material index·UV·modifier 상태를 저장했다. 모든 material slot의 binding도 저장해 비대상 바인딩이 동일한지 검증한다.

`geometry-before.json`, `geometry-after.json`, `bindings-before.json`, `bindings-after.json`, `material-changes.json`, `manifest.json`이 실제 검증 근거다. 첫 비교는 Python tuple과 JSON list의 타입 차이 때문에 중단되었으며 파일로 저장된 두 지문은 동일했다. 직렬화 정규화 후 전체 검증을 통과했다. 두 geometry 파일의 SHA도 `9450885722b8b3c3a3f4d815a2eaf7ffd00cf89e6d08170742777cbe40e516fe`로 동일하다. 6,043 meshes를 포함한 총 6,135 objects, 비대상 13,046 material slots가 유지된다. 대상은 211 slots(돌 152, 줄눈 42, 흙바탕 13, 흙마당 2, 밭 2)다.

같은 카메라·빛·색 관리에서 before/after를 렌더한다. 전체 구도와 마당·담장 근접을 각각 비교한다. 리뷰 렌더 설정은 Cycles CPU, 24 samples, 1280×960이다. 최초 전체 before는 4 threads였고, 보정본은 8 threads와 persistent_data로 렌더한다. 원본 전체 before의 이미지·SHA를 재사용하며 재렌더하지 않는다. 해상도를 줄인 검토 렌더이며 최종 앱 에셋으로 간주하지 않는다.

## 재현

Blender 5.2.2에 canonical R12를 열고 `audit_source.py` → `build_surfaces.py`를 실행한다. 저장 후보 `ildu-estate-yard-wall-r1.blend`를 열어 `render_compare.py`를 실행한다. 각 명령은 `rtk proxy`로 실행하며 `-t 4`를 사용한다.

### 작은 패치로 재구성

대형 후보는 로컬에 보존한다. 공유·커밋용은 `yard-wall-materials.blend`, `material-patch.json`, `material_patch.py`, `audit_source.py`, manifest와 작은 proof JSON이다. `material-patch.json`은 원본 SHA, 라이브러리 SHA, 실제 렌더에 연결된 셰이더 signature, 전체 geometry signature, 전체 candidate binding signature와 211 object/slot 매핑을 담는다. 새 재질에서 렌더에 연결되지 않은 기존 이미지 노드를 제거해 원본 텍스처 복제 의존성을 줄였다.

정확한 canonical을 연 Blender에서 `--python material_patch.py -- apply`를 실행하면 메모리 안에 재적용하고 실제 상태를 검증한다. 원본은 절대 경로가 달라도 정확한 SHA가 같으면 허용한다. `--output <다른 경로.blend>`를 주면 검증한 후보를 저장한다. 연 원본과 같은 출력 경로는 거부한다. 이 재구성 검증은 대형 geometry/binding JSON에 의존하지 않는다. 대형 감사 파일을 다시 만들려면 canonical에서 `audit_source.py`를 실행한다. `material-changes.json`을 포함한 전체 후보를 다시 만들려면 이어서 `build_surfaces.py`를 실행한다.

대형 `.blend`와 `.blend1`은 이 로컬 폴더에 보존한다. 최초 연속 돌색 시안과 너무 평활했던 흙 시안은 `rejected` 이름의 근거로 보존하고 공유·게시 후보에서 제외한다. 리뷰 렌더를 재사용할 때 각 이미지의 실제 `native_sha256`를 `render-manifest.json`에 남긴다. 담장 근접 after는 돌 보정본 `a9c1d12060a0d2b8f4dd36ac51f2691699e5b2518e66f1573fa1ee2269d5c68c`에서 나왔으며, 최종본에서는 해당 담장 셰이더를 변경하지 않았다. 그 근접의 바닥은 흙 보강 전 상태다.

## 시각 판정과 한계

2026-10-21 부모 디자이너가 담장 전후 및 흙 보강 후 마당을 직접 확인했고, 독립 검수 `/root/gate_construction`도 마당·담장 전후 4장을 직접 확인했다(추가 수정·렌더 없음). 차단 결함은 발견하지 않았다.

- 마당: 이전의 반복되는 밝은 얼룩과 첫 수정의 매끈한 갈색 면이 개선됐다. 새 자갈·물결·발자국·유광 플라스틱 반사는 관찰되지 않았고, 중간 크기 흙 변화가 읽히는 따뜻한 관리된 무광 흙색으로 판정했다.
- 담장: 돌의 위치·줄눈·모서리·기와 윤곽과 돌별 아이보리·회색·황토색이 유지된다. 첫 시안의 콘크리트 같은 연속 색면은 해소됐다.
- 범위: 실제 비교 렌더의 전체 구도, 마당, 담장 코너 한 곳에 대한 검수다. 모든 담장 양면을 개별로 렌더했다는 뜻은 아니다.

최종 전체 after를 직접 확인했다. 넓은 흙면에 반복 타일 경계가 보이지 않고, 초안에서 사라졌던 담장 돌의 색 구분이 전체 구도에서도 복원됐다. 원본 3장, 담장 보정 after 1장, 최종 흙 보강 후보의 마당/전체 after 2장으로 전후 6장을 완성했다. 각 파일 SHA를 다시 확인했고 최종 full-after SHA는 `b60ab6780ed8`로 시작한다. 완전한 SHA와 실제 source native SHA는 `render-manifest.json`에 있다.

최종 native 후보 SHA는 `586b8a5328e7c0deaeff5f340639708c927ea224a429aca70dc313adadddff68`이다. 작은 library는 `yard-wall-materials.blend`, 33,212,388 bytes, SHA `0bc9eb89d7eb4810aae1c6cfa7e5a532fd9b7acb99ecef395c9a8cc90902b0cf`다. 104 materials·10 images를 담고 있으며 meshes/objects는 0개다.

`patch-reconstruction-verification.json`은 `passed=true`다. 정확한 원본에서 library를 다시 읽고 211 slots를 적용해 6,135 objects의 geometry/UV/transforms, 비대상 bindings, 전체 candidate bindings, 렌더에 연결된 shader signatures가 동일함을 확인했다. 대형 후보를 새로 복제 저장하지 않고 메모리에서 검증했다. source SHA도 검증 후 동일하다.

원본 형상 유지와 재질 품질, 사용자 승인, 앱 통합은 별도 상태다. 현재 shader는 native Blender 검토용으로, 앱용 texture bake / glTF material 변환은 하지 않았다. 사용자 최종 승인·정본 승격·새 세 문 결합·앱 통합을 완료했다고 주장하지 않는다.
