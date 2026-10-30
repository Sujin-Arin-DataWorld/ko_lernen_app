# R16 정본과 현재 라이브 5탭 연결

사용자 요청: 현재 책 학습 목업을 기록·저장·커밋한 뒤, 현재 라이브 앱의 하단 5탭과 R16 일두고택 완성본을 Gye 및 관련 콘텐츠에 연결하고 검증 후 배포한다.

선행 목업은 비공개 hangulsori-archive의 archive/hanok-first-sound-20261030, dc0e7333a7a90e2a06c333032e1c1c37e90f77ae에 보존했다. 정지 목업과 새 이야기 학습의 런타임 적용은 별도다.

## 확인된 현재 상태

- 작업 기준 origin/main 5e778d6b5b34f37947f21325170de28fe2252c77. 별도 codex/ildu-r16-live-gye-20261030 브랜치를 사용한다. main 630개 WIP 및 기존 R12 worktree 133개 WIP를 건드리지 않는다.
- 현재 SoriStageShell의 Today/Lernen/Spiele/Hanok/Gye 다섯 목적지를 유지한다. 새 하단 아이콘의 Lernen 매핑은 이전 기록에서 미확정이므로 임의 교체하지 않는다.
- R16 제작 정본은 11동/128공정이다. 현재 실제 지갑은 Sarangchae16과 B2 34공정의 별도 소유 트랙이다. 기존 9개 건축 학습 시리즈에는 협문/사당문이 포함되고, 곶간·측간 공정은 R16과 수가 다르다. 이들을 같은 인덱스라고 간주해 덮어쓰지 않는다.
- Gye는 여전히 kHanokWorldUpdating 안내를 사용하며 실제 공동 진행은 8개 요소의 서버 상태다. 개인 소유와 공동 목표는 별도다.
- 별도 라이브 오류 세션이 계정/백업 복구와 Android/TestFlight 배포를 진행 중이다. 빌드 번호를 임의로 재사용하거나 그 WIP를 포함하지 않는다.

## 독립적으로 진행할 에셋 연결 기반

1. 원래 contract/roof policy SHA와 128개의 processId를 그대로 보존한다. 사랑채/중문간채는 온전한 단독 지붕 렌더를 시공 상세에 사용하고 최종 고택은 원래 연결형 렌더를 보존한다.
2. 픽셀·캔버스를 바꾸지 않는 lossless WebP로 패키징해 전후 RGBA와 원본/출력 SHA를 검증한다. 같은 원본은 같은 객체를 공유한다. 기존 원본과 기존 학습 내용을 삭제하지 않는다.
3. presentation-only catalog를 만들고 11/128·중복·순서·경로·지붕·실제 파일 검증을 수행한다. 이 catalog를 로드해도 소유·엽전·진도가 변하지 않는다.

## 정책 선택 후의 화면 연결

사용자는 ‘R16 정본과 5탭·Gye·관련 콘텐츠 연결 먼저, 기존 진도 유지’를 명시적으로 선택했다. 기존 50공정 소유를 128공정 소유로 바꾸는 임의 환산, 협문을 측간으로 바꾸는 매핑은 하지 않는다. 현재 앱의 건축 학습 자료실은 기존 동작을 유지하며, 새 이야기의 공정 공개 정책으로 전환하지 않는다.

실행 범위는 기존 ID가 정확히 일치하는 99개 이미지의 표시를 R16으로 전환하고, 별도 문 14개 이미지는 기존 정본을 유지한다. 나머지 R16 29개는 정확한 ID와 함께 에셋으로 보존하지만 새 공식 학습 단원이나 소유 트랙을 만들지 않는다. 전체 고택 11동은 Gye에 이미 존재하던 완성 예시의 새 아트와 별도 문화/건축 참고 화면에 연결한다. 개인 진행 화면과 참고 화면은 명확히 구분한다.

Gye의 8개 공동 목표는 그대로다. 그 기존 8개 요소를 모두 완료한 공동 마당의 완성 그림만 R16으로 전환하며, 그 이전의 기존 요소별 상태와 전시물은 보존한다. Gye 소개는 완성 예시임을 표시한다. Hanok/Gye 탭과 한옥·사랑채·안채·사당·Gye 문화 설명에서 같은 참고 화면으로 진입하고 기존 건축 학습/복습으로 돌아올 수 있게 연결한다.

선택한 정책에 맞는 권한/진도 계약이 정해지면 Hanok 진입·Gye의 관련 진입·기존 문화/학습 콘텐츠와 연결한다. 390/320·100/200%·image failure/retry/back·개인/공동 분리·기존 탭/학습 재진입을 검증한 뒤 PR 정확한 head CI와 병합 main CI를 확인한다. 기존 테스트 배포 경로와 exact-main SHA를 사용한다. 이미지 준비·CI·스토어 업로드·검토·실제 설치는 각각 별도 증거로 보고한다.

## 근거

- docs/hanok_r16/{APP_INTEGRATION.md,APP_ASSET_CONTRACT.json,ROOF_VARIANT_POLICY.json}.
- lib/models/yeopjeon_wallet.dart, ildu_construction_art.dart; lib/screens/sori_stage/sori_stage_shell.dart; lib/widgets/sori/gye_hanok.dart.
- Flutter 3.44.8/Dart3.12.2(로컬), CI Flutter3.44.0. [공식 asset bundle 문서](https://docs.flutter.dev/ui/assets/assets-and-images) 확인일 2026-10-30. 정확한 명시 asset 경로와 AssetBundle seam을 사용한다.
