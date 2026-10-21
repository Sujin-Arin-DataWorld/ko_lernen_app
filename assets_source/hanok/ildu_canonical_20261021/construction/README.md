# R6c 세 문 공정 리뷰

이 폴더는 새 도면 모델의 **기존 부재 subset**으로 공정을 보여 주는 독립 검토 패키지다. 원본 `.blend`를 저장하거나 메시·재질·카메라를 변경하지 않는다. Flutter·실기기·진도·보상 연동은 이 패키지의 범위가 아니다.

## 보기

- `index.html`: 문 선택 → 공정 선택 → 이전/다음 → 완성 비교. 기존 hero와 모든 공정의 카메라는 같다.
- `left-contact-sheet.jpg`, `right-contact-sheet.jpg`, `shrine-contact-sheet.jpg`: 전체 공정 이미지.
- `manifest.json`: 원본 SHA, 계약 파일 SHA, 원래 단계 ID·라벨·학습 조건, 누적 부재 및 별도 새 설명.
- `verification.json`: 20개 이미지 파일·해시·해상도, 최종 hero 바이트 동일성 및 독립 부재 분할 검증.
- `*-object-stage-map.json`: 실제 원본 오브젝트의 단일 단계 배정 및 mesh/UV/transform/modifier/material 상태 지문.
- `contracts/`: 상위 catalog·display policy·owner map의 실제 바이트 스냅샷. `bindings`는 이 폴더의 상대경로이며 원래 절대경로와 SHA는 `upstreamBindings`에 출처로 보존한다. 원본·hero 검증 경로는 현재 `construction/`의 부모를 기준으로 계산한다.
- `portability-verification.json`: 별도 임시 경로 복사 후 3개 native subset dry 검증과 20개 이미지 독립 검증. 실제 이미지는 재렌더하지 않으며, 테스트 후 임시 복사본을 정리한다.

## 계약 보존

| 문 | instance gate key | 기존 series | 단계 | 원본 부재 |
| --- | --- | --- | ---: | ---: |
| 사랑채 왼쪽 협문 | `left_changgo` | `hyeopmun` | 6 | 680 |
| 안채 연결 협문 | `right_ansarang` | `hyeopmun` | 6 | 530 |
| 사당문 | `sadangmun` | `sadangmun` | 8 | 445 |

양 협문은 기존 `ildu.hyeopmun-*` process ID를 공유하되, `instanceKey`는 `gateKey:processId`로 구별한다. 사당문 `roof_bed`의 밑줄 등 기존 ID 철자를 그대로 유지한다. 라벨·단계 번호·48개 단원 중 기존 required course unit 목록을 바꾸지 않는다.

기존 lessonEvidence는 원문 증거로 보존한다. 그 원문의 ‘세 단의 계단’은 새 모델에 맞지 않으므로 주 화면에 노출하지 않는다. `displayDescription`은 새 도면 모델 기준이다. 왼쪽은 계단 없는 낮은 바닥, 오른쪽은 아래부터 높이 200·150·150·130·120mm의 다섯 단이며 사당문은 낮은 신방석 기초다. 학습 원문을 실제 앱에서 고치는 작업은 별도다.

## 분류와 검증

- 왼쪽 delta: 20 → 22 → 70 → 16 → 494 → 58개.
- 오른쪽 delta: 29 → 21 → 60 → 16 → 348 → 56개.
- 사당문 delta: 3 → 6 → 9 → 7 → 64 → 295 → 59 → 2개.
- 단계 분할의 누락·중복을 검사하며, 이전 누적 부재가 사라지지 않아야 한다.
- 마지막 누적 부재 집합은 원본의 전체 건축 mesh 집합과 정확히 같다. studio 바닥·광원은 건축 부재 집계에서 제외하고 모든 렌더에서 동일하게 연결한다.
- 모든 단계에서 원본 메시·UV·변환·modifier·재질 슬롯·shader node/입력/연결·packed image 지문을 재확인한다. 원본 파일 SHA도 실행 전후에 같아야 한다.
- 원본 saved hero camera의 위치·scale이 기존 manifest와 일치하고, 같은 카메라 오브젝트를 모든 단계에 연결한다. 단계별 자동 framing은 없다.
- 최종 3장은 기존 hero를 재사용하며 SHA로 바이트 동일성을 검사한다. 중간 17장은 1024×1024, Cycles CPU, 20 samples, `-t 4`로 렌더한다. 기존 hero는 1400×1400, 48 samples다.
- 겹침 검사는 단계 간 부재 중복 배정에 대한 검사다. 원본 메시 자체의 공간 충돌·역사 시공 순서를 새로 인증하는 검사가 아니다.

사당문의 7단계는 문과 철물을, 8단계는 원본 태극 문양 오브젝트 2개를 더한다. 30mm 개판은 지붕 바탕에 배정하며, 협문 3단계에는 서까래와 개판·측면 판재/받침을 함께 배정한다. 기존 ID와 라벨을 유지하면서 새 모델의 실제 부재를 설명하기 위한 표시 정책이다.

## 재실행

작업 위치: `drawing-r4`. 원본과 상위 계약 파일이 바뀌면 기존 검증을 승계하지 않는다.

```powershell
rtk proxy C:\dev\_tools\blender-5.2.2\blender-5.2.2-windows-x64\blender.exe -b -t 4 --python construction/render_construction.py -- --render --width 1024 --samples 20
rtk proxy python -X utf8 construction/build_review.py
```

`build_review.py`가 새 설명과 HTML을 만들고 현재 파일을 독립 재검증한다. `verification.json`의 `passed=true`는 이 산출물의 파일·구성 검증이며 사용자 승인이나 앱 완료 판정이 아니다.

접근성 설계에는 native button과 체크박스, 선택 후 focus 복원, 48px 최소 조작 높이, 상태/이미지 설명, 축소 화면 재배치와 `prefers-reduced-motion`을 적용했다. 완전한 보조기술 검증은 별도다.

실제 Chrome 검증에서 20개 단계 이미지를 모두 불러왔고 이전·다음·완성 비교 및 선택 후 focus를 확인했다. 390×844의 100% 글자와 별도 200% 글자 QA에서 가로 넘침과 단계 버튼 겹침이 없었다. `browser-desktop-qa.json`, `browser-mobile-qa.json`, `browser-text200-qa.json`과 `browser-desktop.png`, `browser-mobile-text200.png`에 근거를 저장했다. Enter 키로 다음 단계 전환 및 focus outline도 확인했다. 200% 캡처에는 QA 상태를 표시했다.

기준 로컬 Git HEAD는 `bbe88e7d22bd1893b762609ed5a8990e1e84db5a`이며, 원본 R6c와 기존 검토 문서에는 사전 WIP가 있었다. 이 담당 작업은 `construction/`에만 추가했다. 커밋·푸시는 상위 담당이 수행한다.
