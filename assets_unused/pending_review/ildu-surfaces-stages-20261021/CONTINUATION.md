# 세 문 도면 재제작 — 이어가기

## 최신 상태 · 2026-10-21 · 아래 과거 상태보다 우선

- 사용자 지시로 같은 폴더에서 이어서 작업 중이며 새 워크트리를 만들지 않았다. 앱 저장소의 새 브랜치에 커밋·푸시할 권한을 받았다. 앱 작업 공간의 충돌·다른 변경은 건드리지 않는다.
- 세 문 R6c 재질과 21장 렌더 완료. 기존 형상 지문과 일치하며 2026-10-21 재검증에서 선택 검사 22/21/22, packed sample 출처·native/render SHA 검증 통과. 조용한 판석 표면을 사용하고 자갈처럼 읽힌 샘플은 제외했다.
- 개선된 모델의 건설 공정 6/6/8 = 20단계 완료. 기존 ID·단원 연결을 보존하며 부재 누락·겹침·단계 누적·최종 원본 일치·다른 경로에서 재검증을 통과했다. construction/verification.json 및 portability-verification.json 참조.
- 전체 마당·담장 재질 후보와 전체/마당/담장 전후 6장 완료. 6,043개 메시의 형상·UV·변환과 비대상 13,046개 재질 슬롯 보존 검사 통과. 마당은 월드 좌표의 비주기 흙 무늬와 기존 동선 주변의 낮은 대비 다짐, 담장은 돌별 원래 색·결을 보존하도록 수정했다. 부모 및 독립 디자이너의 근접 전후 검수에서 차단 결함이 없었다.
- 최종 estate native SHA는 `586b8a5328e7c0deaeff5f340639708c927ea224a429aca70dc313adadddff68`. packed library 104재질·211바인딩을 canonical에 재적용해 geometry/UV/transform·비대상 및 전체 candidate binding·연결 shader signature 동일성을 검증했다. `estate-yard-wall-r1/patch-reconstruction-verification.json` 참조. 대형 전체 estate 파일은 로컬에 보존하고, 원본 SHA가 고정된 작은 재질 패치와 검증 기록을 공개 패키지에 넣는다.
- 앱 게시 경로는 `assets_unused/pending_review/ildu-surfaces-stages-20261021`, 새 브랜치는 `codex/ildu-courtyard-gate-stages-20261021`. 기존 앱 checkout을 바꾸지 않고 ROOT의 `.git/publication.git` 메타데이터와 `.git/publication-work` 패키징 폴더에서 커밋한다. 최종 푸시 SHA는 로컬 `PUBLICATION.json`에 기록한다.
- 결과는 검토용 에셋이며 Flutter 앱 통합·배포·새 재질의 사용자 승인을 의미하지 않는다.

## 현재 우선 상태 · R6b 사당문 표면 보강 · 2026-10-19
- 같은 `drawing-r4` 로컬 Git에서 작업했다. 형상 기준 커밋은 `bbe88e7`, 재질 수정은 미커밋 검토 후보. 새 워크트리·앱 통합 없음.
- R5와 같은 카메라의 지붕 ROI 비교에서 첫 R6 사당문은 밝기 −12.8%, 미세 대비 −4.2%로 여전히 매끈했다. 연속 점토색의 셰이더 명암 범위를 넓힌 R6b는 밝기 −9.7%, 미세 대비 +10.9%다. 두 협문도 각각 미세 대비 +16.3%/+19.2%. 네모난 색 아틀라스 무늬를 보인 시험은 채택하지 않았다.
- 최종 렌더 21장·저장 `.blend` 3개. `surface-package-verification.json` `passed=true`; 도면 선택 검사 21/20/21 통과, 형상 지문 세 문 모두 승인 기준과 동일. `index.html`의 R5 비교와 `SURFACE_REVIEW.md`의 측정 조건을 확인한다.
- 사당 본채 참고 이미지는 카메라·조명이 달라 직접 색차나 1:1 재질 일치를 주장하지 않는다. 사당문은 적갈색 도장·녹색 부재·청먹 기와의 계열로 정리했다. 표면 사용자 승인은 아직 받지 않았다.

## 현재 우선 상태 · R5 표면 검토 후보 · 2026-10-18
- 사용자 형상 승인 직후 `drawing-r4` 독립 로컬 Git에 기준 커밋 `bbe88e7` 생성. 이 폴더는 앱 Git 저장소 밖이다. 새 워크트리는 만들지 않았다.
- 목재 장변·단면 및 점토 샘플을 일두고택 정본 `.blend`에서 추출해 현재 세 `.blend`의 재질 노드에 포장했다. 새 재질 수정과 렌더는 아직 **미커밋 검토 후보**이며, 사용자 표면 승인·앱 통합은 없다.
- 최종 완전 해상도 렌더 21장과 원본 3개, 선택 검사 21/20/21개가 모두 일치한다. `verify_surface_package.py` 및 `surface-package-verification.json`은 저장 `.blend` SHA·렌더 SHA·기준 대비 메시 지문·샘플 출처 SHA를 검증했고 `passed=true`다. `index.html`의 원도면/승인 당시 표면 전환을 로컬 브라우저에서 세 문 모두 확인했다.
- 디자이너의 표면 교차 검수에서 나온 굵은 반복 나이테와 처마 접합 색 차이를 조정했다. 처마에 보이는 30mm 목재 개판 앞끝은 형상 승인본의 실제 부재라 그대로 남는다. 상세는 `SURFACE_REVIEW.md`.
- 아래 R4 기록은 당시 형상 검증 단계의 기록이다. 최신 산출물은 위 R5 상태와 `manifest.json`을 기준으로 한다.

## 사용자 승인 및 로컬 커밋 방침 · 2026-10-18
사용자가 현재 세 문의 디자인을 “통과”로 승인하고, 재질 수정 전 커밋을 명시적으로 요청했다. `drawing-r4`는 앱 Git 저장소 밖이므로 여기서 독립된 로컬 Git 기록을 시작한다. 앱 작업 공간의 다른 미완성 변경은 커밋하지 않는다. 현재 형상 승인과 새 재질 승인, 100% 도면 일치, 앱 통합은 서로 다른 판정이다.

## 2026-10-18 최종 로컬 상태 (아래 이전 체크리스트보다 우선)
- 새 워크트리 없이 이 폴더에서 세 `.blend` 파일을 다시 생성했다. 원본 Blender 메쉬와 최종 21장 렌더가 `manifest.json`에 기록됐다. `final-render-r4.log`는 Blender 정상 종료를 기록한다.
- `validate_drawings.py`를 최종 `.blend`에 실행해 왼쪽 20개, 안채 연결 19개, 사당문 20개 검사 모두 통과했다. 원본 파일 SHA, 렌더의 원본 SHA, 검증 SHA가 세 문 모두 일치한다. 렌더 21장은 모두 `draft=false`다.
- 실제 수정: 세 지붕의 부채꼴 모서리, 오른쪽 개판의 용마루 분할, 사당문 도리 원메쉬 치수 판정, 왼쪽·사당문 문턱 받침, 사당문 배면 빗장걸이, 처마 접합과 재질 무늬. `index.html`의 세 문 비교판을 로컬 브라우저에서 열고 모두 현재 원본·검사 일치 표시를 확인했다.
- 두 디자이너의 독립 판독은 모서리 인입 160–190mm를 도면 축척 해석으로 수용했지만 인쇄 치수가 아니라고 지적했다. 안채 연결 협문 092의 단면 폭 2320과 093의 평면 폭 2360 등 원도면 간 충돌이 남아 있다. 따라서 전체 도면 100% 일치·사용자 승인·앱 통합은 주장하지 않는다.
- 이전 `지금 이어서 수정할 항목` 1–8은 이 빌드에서 처리한 역사적 작업 목록이다. 이후 시각 검수는 `index.html`의 도면별 장면에서 진행한다.

2026-10-18. 사용자 작업 계속 지시. 중지 요청 없음. ecc:strategic-compact 적용: 작업 상태를 이 파일과 산출물에 저장하며 Claude용 hook/설정을 설치하지 않는다.

## 범위와 기준
- 사랑채 왼쪽 협문 / 안채 연결 협문 / 사당문, 도면 전체 100% 일치 목표. 완성·100% 판정은 아직 아니다.
- 다른 승인 11동·담장 정본 변경/승격/앱통합/삭제/커밋 금지.
- 실제 Blender 신규 메쉬. 재질 통일; 재채색/밝기 변경만으로 완료하지 않는다.
- latest user: “계획대로 디자이너들과 같이 작업해줘”. 읽기전용 디자인 에이전트 2명 완료: /root/gate_drawing_review, /root/gate_material_review.

## 핵심 발견 — 재검색 금지
국가유산포털 공식 목록 https://www.heritage.go.kr/DATA1/heritage/hub_img/html/cul_1483801860000.html 에서 누락됐던 도면 10장 확보.
sources/left080~083.jpg = 2007 중문 평면·창호·단면·천정·지붕·사방입면. left019/020.jpg는 1992 비교용.
sources/right089,091,092,093.jpg + ../sources/right090.jpg = 안사랑채 협문 전체.
../sources/shrine086/087/088.jpg = 사당문 전체.
sources/source-index.json = 원본 URL·SHA. fetch_drawing_sources.py = 원본 다운로드 재현 스크립트.
기존 021만 가진 채 왼쪽 단면 없다고 했던 문제 해결됨. 사용자에게 더 경로 묻지 않는다.

## 작업 파일과 실행
현재 폴더 drawing-r4. build_gates.py + measured_assemblies.py가 실제 native builder.
validate_drawings.py가 새 독립 검증. validate_repair.py는 R3에서 복사된 오래된 검사로 사용하지 않는다.
Blender: C:/dev/_tools/blender-5.2.2/blender-5.2.2-windows-x64/blender.exe
명령: rtk proxy <Blender> -b -t 8 --python build_gates.py -- left right shrine --views hero,front,side,back,plan,eaves,underside
메쉬 저장 뒤 렌더. 21개 최종샘플 렌더 완료 final-render.log(약12분CPU). session13241 종료 확인 필요.
검증: rtk proxy <Blender> -b -t 2 --python validate_drawings.py -- left right shrine

## 구현 내용
left: 축2080, 기둥155, 문1790/THK25/8판, 원형서까래10개(몸120/끝100), 4기울어진팔각105보조기둥, 60x60 X버팀4개, 낮은자연석+215x155신방목, 용마루5단.
right: 축1460, 기둥180, 각연80x100 7개, 도리180x230, 신방목210x210x1400, 5계단 높이200/150/150/130/120·길이330/360/380/180/600. 4문판THK30. 문폭1140은 띠장570×2에서 판독, 문높이1680은 축척판독.
shrine: 축1350, 원주170, Y방향82x150도리2줄, 서까래1800×폭2178, 문1020x1500x30·8판, 둔테외곽1600. 문코너철물 추가.
원도면 충돌: right092 단면폭2320 vs093 평면2360, upperdunte1250 vs1280, 빗장089와092단면 차이. 명시하고100%라고하지않는다.

## 지금 이어서 수정할 항목
1. right 가운데 개판이 용마루 정점 y0를 가로질러 평면으로 되어 서까래12mm침범. 개판그리드에 y0 추가(수정예정).
2. shrine dori1800 길이 검증은 bevel 때문에 evaluated1799.285. 원메쉬길이1800와절삭면을 따로 판정(임의모델늘리지않기).
3. 디자이너지적: 세지붕 plan 직각모서리를 082/093/086 둥근 부채꼴 전환으로 수정. 기존외접치수보존.
4. left문턱아래지형, shrine문턱돌 높이 보강(문틀낮추지않기).
5. shrine뒤빗장걸이 현재40x70x90 → 도면축척 약60x70x350, 빗장오른쪽돌출비대칭.
6. 처마 검은연속틈을 thin tile bedding 앞끝·높이·실제접합으로 수정. 기와입구의고유빈공간은유지.
7. 목재faceRings=.27규칙무늬축소, clay미세도기표면. 박공은실측외곽유지하고겹침조각정리.
8. 변경후 해당렌더재생성 + validate_drawings + 실제확인 + 새index.html 비교판/브라우저검증.

## 운영
PowerShell은 rtk proxy python 사용. Get-Content를 rtk proxy에 직접넘기면실패(내장cmdlet).
임의새이미지생성불필요. 검토판은 http://127.0.0.1:8866/surface-redesign-20261018/gate-rebuild/drawing-r4/index.html 로열기(현재없음).
Memory참조 최종필요: MEMORY.md:18-19, rollout01a1287c-97ad-7cd0-b094-371020cdc70e.
