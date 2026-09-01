# SDD ledger — plan: docs/superpowers/plans/2026-09-01-handoff-verification-and-release.md

Worktree: /home/user/ko_lernen_app_worktrees/handoff-verify (branch claude/handoff-review-verification-199gwi, base origin/main 0dc760fe). 12 tasks.
컨트롤러=Fable(메인 루프), 구현=태스크별 fresh 서브에이전트(하위모델), 검수만 병렬.

## Pre-flight (2026-09-01)
Ruling: Jin 브레인스토밍 4결정(재배포 +30 양트랙 / §0 증거추적 후 강행 / graphify 스코프 재추출 / 저위험 하드닝 포함) + 설계 A안 승인 — spec §3 참고.
Ruling: 병합 순서 고정 — 검수 PR → graphify PR → 릴리스 PR(마지막, squash). play_closed 정확-SHA 게이트 때문.
Ruling: PLAY_INTERNAL_RELEASE_ENABLED 현재 OFF 실측 — Task 11 Step 1에서 Jin에게 ON 요청, 응답 전 진행 금지.
사실: 이 컨테이너 flutter 없음 — 테스트 검증은 PR/main CI로만. unshallow 완료. graphifyy 0.9.53 설치(정본은 0.9.48산 — 스코프 한정 사용).

## Task log

Task 7 사전조사 complete (Explore/sonnet): 후보 7건 중 5(speakable 3자 경합)=FIXED@7a092953(#211), 6(applyPlatformAudioContext)=FIXED@9f55341d(W2, try/finally+callee catch 이중), 7(pressable 주석)=FIXED@3ca70038. 잔존 4건 확정 — ①sori_stage_catalog_reward_flow_test.dart:76-78 고정 3초→폴링(test-only) ②pad_android12_splash_icon.py:36-38 mkdir(tool-only) ③scene_asset_resolver_test.dart:71-77+dancheong_burst_preload_contract_test.dart:39-45 가드 정규식 주석 미제거(test-only) ④main.dart:157-158 stale "2s" 주석(comment-only, 인계서 568줄에서 드리프트). Ruling: 4건 전부 프로덕션 동작 무변경 — Task 7 스코프 승인, 워크플로 종료 후 직렬 구현.

Task 1: complete (commit 09487754). Workflow 팬아웃 56에이전트(검증 52+특수 2+재검증 게이트+비평자) — 최종 반영 50 / 의도적 보류 2 / 불일치 4 / 미반영 0. 불일치는 전부 "인계서가 낡음" 방향(H-45 84건 대기, H-49 versionCode 실측 2174/2186, H-50 #100 게이트 stale, H-53 §8 gitignore 전제 거짓). H-51: §0 플립게이트 실질은 08-15~19 해소(08a77fd6→abf9e3ff→c917d777+01bd8849), 문서만 지연.
Task 2: complete (commit 0017eb76, 이력화 배너). 컨트롤러 직접 검증(문서 전용 — W2 T1 선례).
Task 3: complete (commit 42069c2b, 버전 핀→pubspec 참조).
Task 4: complete (commit 041194f3, 분기 A — 해소 증거 추기, 기존 판정 무삭제, 계약 테스트 앵커 불변 확인).
Task 5: complete (commit cdf4d7a3, tiger_choose 예산 가시화 + #100 게이트 종결 — H-50/H-47 근거).
Task 6: 해당 없음 — 미반영 0건이라 코드 격차 없음.
Task 7: complete (commits a07adb1e/aa4e8e53/aefce834/78aaea30, 구현자 opus + 컨트롤러 diff 전건 검토). ①폴링 상한 3→10s, 조건=후속 단언과 동일 위젯, 파일 내 기존 runAsync+pump 선례 재사용 ②mkdir(OUTPUT은 Path 확인) ③가드 2종 주석 면역 — jamo_speech_test의 기존 stripLineComments 재사용, 구현자가 파이썬 재구현으로 양성/음성 컨트롤 실증(main.dart 211-214 라이브, :// 부재) ④주석 전용(splash_screen.dart 27-28 실측 600/1500ms 대조). 프로덕션 동작 변경 0.
Task 8: complete — H-53(sdd는 gitignore 아님, main이 7월 원장 12파일 추적)에 따라 부록 요약 대신 원장 자체를 커밋(이 커밋). ios-manual-runbook.md 동봉.

Ruling(Jin, 2026-09-01): 필요한 스킬이 세션에 없으면 즉시 설치해 사용한다(상시 지침). superpowers@6.3.0·pr-review-toolkit 설치됨. ecc:* 리뷰 로스터는 공식 마켓플레이스에 없음 — 임의 저장소 추측 설치는 공급망 위험이라 보류, Jin에게 마켓플레이스 출처 확인 요청 항목으로 이월.

Task 9: complete — PR #247 병합(merge commit 01af91a0). PR CI: run 1016/1017/1018 전부 success(마지막 head c3392f87). Codex 봇 P2 2건 접수→수정 커밋 f372ee39(H-05 주장 정정)+c3392f87(블록 주석 스트리핑, 음성 컨트롤 시뮬레이션 통과)→스레드 2건 resolve. 리뷰 대응 포함 총 13커밋.
Task 10 진행: graphify — detect_incremental이 2,159파일 오탐(정본 manifest와 플랫폼/버전 해시 불일치, CRLF 전례와 동형) → Jin 결정의 폴백대로 manifest 경량 갱신 채택. save_manifest 서브셋 API(#917 경로)로 이번 병합 14파일만 스탬프(신규 5 엔트리+기존 9 갱신, kind='ast'). cache/stat-index.json·.graphify_incremental.json은 되돌림(캐시 커밋 금지). wiki 재생성은 스코프 재추출 불가로 보류 — Jin 머신 몫으로 이월.
Ruling(Jin, 19:4x): 릴리스(+30)는 Codex 오디오 수정(c82a7bef 계열, Buchstabe des Tages 무음 등)이 main에 전부 랜딩한 뒤 자른다 — 무음 수정 포함 빌드가 테스터에게 나가도록. graphify PR #248은 선행 병합, main 주기 체크로 안정화 감지 후 릴리스 진행.
Task 10 fix round 1/5 (Codex P2 접수·정당 판정): manifest 스탬프는 신규 파일을 미래 추출에서 영구 배제하는 결함 — 스탬프 전면 철회(manifest=main 판 복원), 기록을 graphify-out/memory/ 노드로 이관(다음 update가 정상 추출). 기록 매체가 오히려 graphify-native로 개선됨.
Task 10 fix round 2/5: task=ci 브랜치 디스패치(문서화된 PR-CI 폴백)가 실패 — dispatch는 비교 SHA env가 비어 build_hanok_grants.py가 merge-base(HEAD, origin/main) 폴백을 타는데 checkout이 depth 1이라 exit 1. 우리 diff 무관의 CI 인프라 잠복 버그 → ci.yml fetch 스텝에 '비교 SHA 부재+shallow일 때만 현재 ref unshallow' 블록 추가(자기 픽스, widening 아님). 검증: 계약 테스트 45/45 로컬 통과 + bash -n 통과.
