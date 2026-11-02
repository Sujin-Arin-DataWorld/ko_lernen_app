# 일두고택 건물 고정 목록

2026-10-30 작성. 기존 승인 에셋의 정확한 파일을 보존하고 이후 제작에 붙여 쓰는 목록이다. 새 그림·3D·애니메이션·앱 코드를 생성하지 않았으며 원본을 변경하거나 업로드하지 않았다. 별도 참조팩에는 선택 PNG의 바이트 동일 사본만 넣었다.

기준 루트: `C:\dev\hangulsori\_codex_artifacts\ildu-r16-publication-20261028`

전체 절대 경로·바이트 수·SHA-256·검증 결과와 128공정의 기존 ID·순서·이름·학습 단원 연결은 [BUILDING_LOCK.json](BUILDING_LOCK.json)에 있다. 아래 상대 경로는 위 루트 기준이다.

## 유지할 11동·128공정·22개 편집 원본

| 건물 | 키 | 공정 PNG 수 | 완성 PNG | 연결형 packed Blender 두 파일 |
| --- | --- | ---: | --- | --- |
| 사랑채 | `sarang` | 16 | `family-r16/sarang/full.png` | `native/sarang/{full,stage}.blend` |
| 안사랑채 | `ansarang` | 14 | `family-r16/ansarang/full.png` | `native/ansarang/{full,stage}.blend` |
| 안채 | `anchae` | 14 | `family-r16/anchae/full.png` | `native/anchae/{full,stage}.blend` |
| 사당 | `sadang` | 12 | `family-r16/sadang/full.png` | `native/sadang/{full,stage}.blend` |
| 중문간채 | `jung` | 12 | `family-r16/jung/full.png` | `native/jung/{full,stage}.blend` |
| 아랫채 | `arae` | 12 | `family-r16/arae/full.png` | `native/arae/{full,stage}.blend` |
| 곳간채 | `gokgan` | 11 | `family-r16/gokgan/full.png` | `native/gokgan/{full,stage}.blend` |
| 안채곳간채 | `angotgan` | 11 | `family-r16/angotgan/full.png` | `native/angotgan/{full,stage}.blend` |
| 창고 | `changgo` | 8 | `family-r16/changgo/full.png` | `native/changgo/{full,stage}.blend` |
| 북측 측간 | `toilet` | 9 | `family-r16/toilet/full.png` | `native/toilet/{full,stage}.blend` |
| 남측 측간 | `toilet1` | 9 | `family-r16/toilet1/full.png` | `native/toilet1/{full,stage}.blend` |

공정 실제 경로는 `family-r16/{key}/stages/NN.png`이다. 계약의 `review/...`는 과거 별칭이며 현재 실파일 경로가 아니다. 완성 11 PNG + 공정 128 PNG = 139 PNG이다. 각 건물의 `full.blend`와 `stage.blend`를 포함하여 연결형 편집 원본은 22개이다. 큰 Blender 파일을 문서 저장소에 다시 넣지 않는다.

139 PNG와 22 Blender의 현재 바이트를 SHA-256으로 읽어 계약·정본 지정 기록과 비교했으며 모두 일치했다. PNG 헤더의 크기도 JSON에 기록했다. 텍스처 패킹과 객체·UV·계층 보존은 기존 제작 보고서의 기록이다. 이번에는 Blender 재열기·구조 재계수를 실행하지 않았으므로 현재 파일 해시 검증과 구별한다.

## 단독 지붕과 연결형 지붕

사랑채·중문간채의 `roof-variants/native/{sarang|jung}/{full|stage}.blend` 네 파일도 보존한다. 네 파일의 현재 SHA-256·크기가 정책과 일치했다. 단독 건설 보기에는 해당 단계까지 얻은 단독 지붕을, 연결 고택 보기에는 연결형 지붕을 사용한다. 전환 조건은 기존 물리적 연결 상태이며 공정 ID·순서·진도·보상을 새로 만들지 않는다.

단독 완성 이미지는 `estate/standalone/sarang/full.png`, `estate/standalone/jung/full.png`이다. 같은 16/12개 논리 공정을 참조하며 지붕 변화 전 11개 공정 PNG는 기존 `family-r16` 파일을 그대로 재사용한다. 이후는 정책에 지정된 단독 파일을 사용한다. 이 참조들도 현재 해시를 확인했다. 지붕 보완 자료는 기존 소스와 생성기 재구성 범위를 가진다. 보이지 않던 끝단을 새 실측 증거로 주장하지 않는다.

## 협문·사당문은 별도 에셋

`gates/native/left-{structural|material}.blend`, `right-{structural|material}.blend`, `shrine-{structural|material}.blend` 총 6개의 현재 SHA-256·크기는 패키지 seal과 모두 일치했다.

| 키 | 정본 명칭 | 기록된 공정 수 | 구분 |
| --- | --- | ---: | --- |
| left | 왼쪽 협문 | 6 | 솟을대문과 별개 |
| right | 오른쪽 협문 | 6 | 솟을대문과 별개 |
| shrine | 사당문 | 8 | 솟을대문과 별개 |

협문·사당문을 솟을대문으로 바꿔 부르거나 대신 사용하지 않는다. 솟을대문의 독립 정본은 [별도 상징·소품 조사](SYMBOL_STYLE_LOCK.md)에서 2026-09-14 승인 원화로 확인했다. 11동 패키지의 문 native와 합치지 않는다. 6·6·8은 기존 기록 값이며 이번에 문 공정 PNG 전체를 검수했다는 뜻이 아니다.

## 전체 고택의 배치와 완성 화면

배치 원본은 `inputs/r12/surface-redesign-20261018/gate-rebuild/drawing-r4/canonical-review-r1/ildu-estate-r5-three-gates-canonical.blend`이다. SHA-256 `3195809855213946a330048b3b86cd3f75ccddac045dbaf640909cee4de36d48`와 현재 바이트가 일치했다.

현재 완성 화면은 `estate/complete.png`이다. SHA-256 `11a77f254f74242862f2a176f447cbb4a3a677dd2345f868c5b05041f5720f59`와 일치하며 실제 이미지를 열어 확인했다. 담장·마당·동별 배치·연결 좌표는 원본을 보존한다.

R16 승인은 11동 완성 이미지·128공정·22개 packed 원본에 명시되고 단독 지붕 4개는 별도 정책에 기록된다. 전체 화면은 현재 납품 기록에 artReady로 표시되지만 promotion의 배치 시각 검토는 pending을 유지한다. 새 파생 이미지·구도·합성은 자동 정본이 아니다. 전체 화면은 깊이별 레이어 합성으로 자체 그림자는 유지하지만 건물 간 간접광을 단일 장면 패스 트레이싱으로 계산한 결과는 아니다.

## AI에 전달할 건물 고정 프롬프트

아래와 함께 JSON에서 선택한 건물의 정확한 완성/공정 PNG·native 경로와 필요한 배치 이미지를 실제 참조로 첨부한다. 문장만으로 구조 일치를 입증하지 않는다.

> 건물 원본은 첨부한 한글소리 일두고택 R16 정본과 BUILDING_LOCK.json의 정확한 파일이다. 선택한 기존 에셋을 사용한다. 평면·비례·실루엣·지붕선·처마 곡률·지붕 연결부·기둥 수와 간격·보·서까래·기단·계단·문·창호의 위치와 격자를 원본 그대로 고정한다. 객체 이름·수·구성·계층·원점·변환·UV·내장 텍스처·공정별 부재를 보존한다. 마당과 담장, 각 동의 월드 좌표와 연결 관계를 고정한다. PNG에서 수치를 추측해 재설계하지 않는다.
>
> 사랑채·중문간채의 단독 지붕과 연결형 지붕을 혼합하지 않는다. 기존 연결 상태와 같은 공정 번호에 맞는 지정 파일만 선택한다. 아직 얻지 않은 완성 부재·새 공정·가짜 진도·보상은 표현하지 않는다. 왼쪽 협문·오른쪽 협문·사당문은 각자 원본을 사용하며 솟을대문으로 대체하지 않는다. 경첩의 축·원점·열림 방향·동작 범위·문짝 크기를 바꾸지 않는다.
>
> 승인된 C안과 원본의 입체적인 재료감, 따뜻한 목재, 기와·석재·벽체의 구별, 층과 접지감을 유지한다. 건물별 색·재료 차이를 보존하고 같은 장식·팔레트·패턴을 모든 건물에 덧씌우지 않는다. 사랑채 현판 文獻世家·忠孝節義의 글자와 위치를 유지한다. 요청에 명시한 카메라·크기·조명 조정만 수행한다. 구조가 중요한 결과는 잠긴 native를 직접 사용해 렌더한다. 참조가 없는 뒷면·끝단·문 구조를 상상해 보완하지 말고 확인 필요로 표시한다.
>
> 실제 사용한 파일과 SHA-256, 보존 항목·명시적 변경 항목, 같은 조건의 원본 비교를 제출한다. 새 산출물은 별도 검토 대상으로 표시하고 정본·앱 통합·기기·배포 완료로 자동 판단하지 않는다. 퇴역 V1/V2 폴더나 제거된 과거 워크트리를 다시 만들지 않는다.

## 검증 범위

사랑채·안채 완성 PNG와 전체 고택 화면을 실제로 열어 확인했다. 모든 공정의 세부 시각 검토·문 동작·Blender 구조 재검사·Flutter·PBR·기기·배포 검증은 이번 목록 작성에 포함되지 않는다. 기존 계약의 runtimeIntegrated, glbPbrBakeComplete, deviceQaComplete, deployed는 false이다. 완성 그림이 학습 완료·소유·보상을 부여하지 않는다.

위 현재 원본을 유지한다. 이 목록 작성은 삭제·생성·업로드·커밋·푸시·병합·정본 승격을 승인하지 않는다.
