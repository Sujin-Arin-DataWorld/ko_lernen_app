# 일두고택 담장 외곽선·축척 — 다음 세션 인수인계

상태: **WIP map composition 반려, 재작업 대기.** 공정 아트 승인과 지도 합성 승인을 분리한다. 이 문서는 후속 구현 진입점이며 현재 맵 구현 완료를 뜻하지 않는다.

## 확정 경계

- 터6·돌담8·솟을대문12·화장실12·곳간12의 공정 그림50개는 승인됐다. 정본 파일·크기·hash는 `docs/assets/ildu_settlement_construction_20260915/construction_catalog.json`에서 확인한다.
- 새 PNG는 `assets/illustrations/personal_hanok_v3/construction/{site,wall,toilet,gokgan}/`의 38개다. 솟을대문12는 main의 기존 바이트를 유지한다.
- 공정 그림 승인은 지도 위 담장 외곽선·축척·건물 배치·진도 또는 앱 경로 승인이 아니다.
- 기존 main의 일두고택 world map 전체는 철회하지 않는다. 반려 대상은 아래 WIP clipper와 그 prototype composition뿐이다.
- 149 stage→unit 배정의 assessment mapping은 149개 모두 미검수다. 지도 재작업은 학습 권리나 progression을 만들지 않는다.

## 반려한 WIP와 이유

보존 위치: `C:/dev/hangulsori/ko_lernen_app_worktrees/toilet-store-wall-plan-20260914`.

`lib/widgets/ildu_settlement_map.dart`는 8개 담장 구간을 normalized 수기 점으로 정의하고(lines 128–148), 원본 픽셀의 실제 폭 대신 화면 폭의 `0.023`을 담장 반폭으로 사용한다(lines 151–175). 원본 masterplan과 지면도 각각 `BoxFit.fill`로 늘린다(lines 54–77). `test/ildu_settlement_construction_test.dart`의 지도 검증은 샘플 점 포함 여부만 확인한다(lines 163–195). 따라서 정본 담장 외곽선, 실제 두께, 축척 또는 입구 정렬의 증거가 아니다.

같은 prototype은 다음 이유로도 이번 통합에서 제외한다.

- `lib/screens/ildu_settlement_screen.dart`: drag/tap만으로 local bookmark를 증가시키며, 지도 지면은 site-05에서 clamp되어 site-06을 쓰지 않는다. 완성 직전 공정 프레임을 열린 문처럼 바꾸는 prototype 동작도 있다.
- `lib/services/ildu_settlement_bookmark.dart`: 정규 학습 권리와 무관한 독립 진행 저장이다.
- `lib/models/ildu_settlement_construction.dart`: prototype runtime catalog reader다. asset-only 승인을 위해 필요하지 않다.
- `tool/build_ildu_settlement_catalog.py`: `/hanok/settlement`, local bookmark, `worldWalls` clipper 메타데이터를 다시 생성하므로 현재 상태로 재사용하지 않는다.
- `tool/preview_ildu_settlement.dart`, `test/ildu_settlement_construction_test.dart`, `main.dart`, route/l10n, `pubspec.yaml`, UIUX inventory 변경도 함께 제외한다.

WIP의 `assets/data/ildu_settlement_construction_v1.json`에 있는 `runtimeConsumer`, `progression`, `composition.worldWalls`는 승인 메타데이터가 아니다. 새 canonical 문서 카탈로그가 아트 정본이며 runtime map을 선언하지 않는다.

## 새 작업의 원본과 좌표 계약

1. 최신 main과 `AGENTS.md`를 먼저 읽고 별도 worktree에서 시작한다. 승인 asset commit, 새 canonical 문서 카탈로그, 활성 Hanok/CP S5 작업의 파일 소유를 확인한다.
2. 현재 main의 비교 기준은 `assets/data/ildu_world_manifest_v1.json`의 **2412×2622** canvas와 `assets/illustrations/personal_hanok_v3/world/ildu-wall-masterplan-v1.png`다. 이는 새로 승인된 정확한 지도 형상이 아니다. 두 파일의 현재 hash·크기·승인 상태를 새 작업 시작 시 다시 기록한다.
3. 좌표 계약을 고정하기 전에 현재 main 기준과 실제 원하는 masterplan/reference의 형상·축척·건물 배치를 대조한다. 현재 masterplan도 맞지 않으면 차이를 기록하고 올바른 canvas와 등록 기준부터 다시 확정한다.
4. 담장 reveal용 fresh source는 검증해 채택한 reference canvas에서 만든다. 수기 중심선+임의 stroke 폭으로 재구성하지 않는다. 원하는 최종 담장 픽셀의 alpha/mask 또는 그 reference에 정확히 등록된 vector outline을 사용한다.
5. 모든 ground, wall, gate, building layer는 검증해 채택한 같은 원점·aspect ratio·camera transform을 공유한다. 개별 `BoxFit.fill`이나 화면 폭 기준 두께로 모양을 바꾸지 않는다. 8개 진행 mask는 최종 담장 mask의 누적 부분집합이며, 마지막 합집합은 승인 후보의 외곽선·기와 상부·석축 면·접지부와 일치하고 대문/협문 통로를 침범하지 않아야 한다.

## 깊이·출입·카메라 수용 기준

- 대문은 바깥길 → 문턱 → 안쪽 마당의 세 지점이 같은 통로로 이어져 보여야 한다. 닫힌 정본을 공정 직전 프레임으로 가짜 개방하지 않는다.
- 담장과 대문이 만나는 양쪽 끝은 틈·겹침·굵기 급변이 없어야 하며, 사람의 통과 폭과 문짝 회전 공간을 유지한다.
- 캐릭터/건물의 ground footpoint를 기준으로 뒤쪽 담장은 뒤에, 전경 담장은 앞에 그린다. 단순 `y` 정렬만으로 지붕·기둥·문을 잘라내지 않는다.
- `main-gate`, `toilet-north`, `toilet-south`, `gokgan`은 현재 manifest anchor를 비교 출발점으로 삼되, 실제 reference sprite의 alpha bounds·footpoint·rotation과 대조한다. 한 화장실 공정 그림을 두 anchor에 쓰는 근거가 불명확하면 이를 미결 제품 결정으로 기록해 지도 최종 승인 때 해소한다.
- 현재 main의 north-up elevated oblique 카메라도 비교 기준으로 재검증한다. 확대/축소와 폰·태블릿 layout이 채택한 world geometry의 종횡비·건물 상대 크기를 바꾸지 않아야 한다.

## 검증과 승인 증거

- 검증해 채택한 native canvas에서 원하는 masterplan/reference 위에 새 최종 mask를 50% overlay한 이미지와 차이 이미지를 만든다. 현재 비교 기준을 유지한다면 canvas는 2412×2622다. 의도한 reveal 경계 외의 이동·스케일 변화는 반려한다.
- stage 0, 각 1–8 reveal, gate 결합, 완성 상태를 같은 카메라/viewport에서 캡처한다. 마지막 상태는 채택한 담장 reference와 직접 비교한다.
- 대문 양 접합부, 전경 담장 가림, 뒤쪽 담장, 두 화장실 anchor, 곳간 anchor를 확대 캡처한다.
- 좁은 폰, 기준 폰, 태블릿에서 전체 estate와 입구 확대를 확인한다. 큰 글자·motion off에서도 지도 geometry가 달라지지 않아야 한다.
- 좌표/마스크 단위 테스트와 Flutter 테스트 외에 실제 렌더 overlay와 기기 캡처를 필수로 남긴다. 테스트 green만으로 시각 승인을 선언하지 않는다.
- Jin이 담장 형태·축척·입구·건물 상대 크기를 실제 캡처로 승인하기 전 `mapCompositingReady`, runtime route 또는 progression을 true로 바꾸지 않는다.

## 완료 시 보존할 것

- fresh-source 파일과 생성 절차, canvas/hash manifest, 8개 reveal mask, overlay/diff, 폰·태블릿 캡처.
- 승인받은 정확한 후보와 반려 후보를 구분한 경로.
- 기존 main world map 유지 여부와 새 composition의 runtime 소비자를 별도로 기록한다.
- WIP worktree는 고유 파일 보존을 다시 감사하기 전 삭제하지 않는다.

## 다음 세션 시작 문장

> `docs/superpowers/plans/2026-09-15-ildu-wall-outline-handoff.md`를 읽고, 최신 main과 승인된 `docs/assets/ildu_settlement_construction_20260915/construction_catalog.json`을 확인한 뒤 일두고택 담장 지도 합성을 새 원본 대조부터 진행해줘. 기존 main world map 전체는 유지하고, `toilet-store-wall-plan-20260914`의 `IlDuSettlementWallClipper`·화면·bookmark·route·pubspec 변경은 가져오지 마. 현재 main의 2412×2622 masterplan은 비교 출발점일 뿐 새 형상 승인으로 간주하지 말고, 실제 원하는 reference와 형상·축척·건물 배치를 대조해 필요하면 좌표 계약부터 고쳐. 검증한 reference에서 fresh wall mask/outline을 만들고 대문 입구, 담장 두께, 앞뒤 가림, 건물 footpoint·상대 축척을 overlay와 폰/태블릿 캡처로 검증해. Jin의 실제 캡처 승인 전 runtime 통합이나 progression 완료를 선언하지 마.
