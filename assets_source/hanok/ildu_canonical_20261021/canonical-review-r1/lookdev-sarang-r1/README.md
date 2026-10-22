# 사랑채 native 재질 후보 R1 — 미승인

2026-10-22. 사용자 신규 스타일 참고자료의 따뜻한 목재·차분한 기와·촉감 있는 표면 방향을 기존 사랑채에 적용한 **한 개의 실제 native 3D 후보**다. 구조·기둥·지붕·창호·현판 형상을 바꾸지 않았다. 새 장식, 단청, 금테, 성곽, 소품을 추가하지 않았다.

## 현재 볼 파일

- `index.html`: 대조군/후보 전체와 정면 상세 비교.
- `original-control-hero.png`, `candidate-hero.png`: 1200×900, 약18° 전체 시점. **같은 카메라·조명·노출**.
- `original-control-front.png`, `candidate-front.png`: 1200×750, 같은 눈높이 상세 시점. **원래 두 현판 글자가 실제 native에서 식별된다**.
- `sarang-lookdev-candidate.blend`: 현재 후보 native. 정본/앱 전달 파일이 아니다.

원본 재질 대조군도 새 비교 조명에서 렌더했다. 이 대조군을 과거 사용자 승인 이미지라고 부르지 않는다. 후보와 대조군의 공통 조명은 큰 area light 세 개와 열린 world fill, AgX Medium Low Contrast다. 크림 배경은 camera-ray에만 적용하므로 건물의 조명은 바꾸지 않는다. source reference와 100% 일치한다는 주장도 하지 않는다.

## 재질 판단과 실제 반영

사용자의 대표 참고 세 장을 직접 확인하고 원래 바이트를 `reference-*.png`로 보존했다. 경로·SHA는 `references.json`에 있다. 참고 건축이나 소품은 가져오지 않았다.

첫 probe의 넓은 단색 혼합은 목재의 나뭇결 대비와 기와의 표면 변화가 약해져 평평하고 창백하게 보였다. 그 probe는 `pale-probe/`에 비교 증거로 남겼고 현재 후보에서 제외했다.

현재 후보는 목재와 기와에 **단색 혼합을 사용하지 않는다**. 원본 image/procedural Base Color 신호 뒤에 HSV grade를 연결하므로 결·색 변화가 그대로 전달된다. 원본 normal/bump 링크도 유지한다.

| 재료 | 현재 후보 적용 | 보존 |
|---|---|---|
| 목재 | source saturation1.10, value0.92. 좀 더 깊은 밤색 방향 | 원본 장목 결, 판재별 톤, procedural/image 입력 |
| 기와 | source saturation0.75, value0.70. 차분한 숯빛 방향 | 원본 기와의 명암·표면 변화·모서리·normal/bump |
| 석재 | 따뜻한 석회석 방향을8%만 혼합 | 원래 돌 결·표면 대비 |
| 회벽 | 아이보리 방향20%혼합 | 원래 벽체 relief |
| 종이 | 따뜻한 종이 방향10%혼합 | 원래 이미지/표면·opacity |
| 현판 네 부재 | **변경 없음** | 원문 image·UV·재질·형상·위치 |

`palette.json`의 hex는 검토 방향을 설명하는 색 기준이다. HSV 재질의 고정색 대체 값이나 렌더 픽셀의 정확한 hex라는 뜻이 아니다. roughness floor는 번들거리는 플라스틱 인상을 피하도록 유지했다. 현재 후보 재질은 복사본131개이며, 원본 material datablock은 변경하지 않았다. 전체 변경 내역은 `material-changes.json`에 있다.

## 원본과 검증

원본 native:

`C:\dev\hangulsori\_codex_artifacts\ildu-r12-app-integration-20261015\surface-redesign-20261018\gate-rebuild\drawing-r4\estate-yard-wall-r1\ildu-estate-yard-wall-r1.blend`

SHA-256 `586b8a5328e7c0deaeff5f340639708c927ea224a429aca70dc313adadddff68`.

현재 연결형 `models/sarang.glb`의 정확한710개 sourceObject만 append했다. 새 장면에 연결하고 view layer를 갱신하여 원래 변환을 평가했다. 전체 estate를 렌더하지 않았다.

`geometry-before.json` / `geometry-after.json`은710개 부재의 vertex·edge·loop·face topology·material face index·모든 UV·world matrix·parent·hidden state·modifier 설정을 비교한다. 동일성 검사가 통과했다. 원본 material graph signature와 현판 material binding도 동일하다.

저장한 후보를 새 Blender 프로세스에서 다시 열고 `verify_saved.py`로 동일 검사를 반복했다. **`saved-native-verification.json`: passed:true**. 현판의 packed `master-sarangchae.png.001` SHA는 원본과 같은 `f917724120d4080d7c004b65dc51a9c336fcfbccdb9997e830de06ead1bcfc1a`다. 원본 native SHA도 다시 확인했다. source file을 저장하거나 덮어쓰지 않았다.

`render-manifest.json`은 현재 네 이미지의 SHA, 동일 카메라 좌표와 해상도, 후보 native SHA를 기록한다. Cycles CPU12samples/denoise를 사용했고 프로세스는 모두 종료됐다.

## 현판과 시점의 한계

전체18°시점에서도 앞 처마가 현판을 가린다. 이를 해결하려고 구조나 현판을 옮기지 않았다. 별도 눈높이 정면 상세에서 어두운 현판과 넓은 밝은 현판의 원문을 확인했다. 현판 앞 일부 기둥 가림도 기존 구조 그대로다.

이는 정지 native 재질 검토와 원본 보존 검증이다. 앱용 GLB 변환·360°검수·공정별 재질 연결·기기 성능·배포·정본 승격·사용자 승인은 아직 성립하지 않는다. 거절된 구형 PBR receipt를 복구하지 않았다.

## 적용한 검토 근거

Blender의 structured-state inspection 원칙을 적용하여 렌더 인상만으로 보존을 판단하지 않고, 변경 전후 geometry/UV/transform/material state와 저장 후 재열기를 기록했다. 시각 검토에서는 평평한 단색 혼합 probe를 제외하고 source grain의 대비와 현판 가독성을 다시 확인했다.

2026-10-22에 확인한 공식 자료:

- [Blender Principled BSDF](https://docs.blender.org/manual/en/latest/render/shader_nodes/shader/principled.html): Base Color 입력과 roughness의 표면 반응을 기준으로 source texture 신호를 유지했다.
- [Blender Color Management](https://docs.blender.org/manual/en/4.4/render/color_management.html): AgX와 공통 노출을 사용하여 대조군/후보의 광원·명암 조건을 통일했다.

실행 코드: `render_lookdev.py`. 저장 후 검증: `verify_saved.py`. 렌더 로그와 공식자료 적용 판단, 실제 출력·검증 결과를 함께 보존했다.
