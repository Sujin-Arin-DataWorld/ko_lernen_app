# 인수인계 1:1 검수·잔여 정리·릴리스 설계 (2026-09-01)

> 발주: Jin — "인수인계서(`docs/HANDOFF-2026-08-27-waves.md`)에 적힌 내용이 main에 다
> 반영됐는지 철저히 1:1 검수하고, 인수인계 지시대로 잔여 작업을 완주하고, 커밋·푸시·
> main 병합·앱 배포(내부/비공개, Android/App Store)까지, graphify 확인·기록 포함."
> 브레인스토밍 4결정 + 설계 A안을 Jin이 세션 내 승인함(아래 §3).

## 1. 배경 — 사전 조사로 확정된 사실

읽기 전용 조사(병렬 에이전트 3 + 실행역학 검증 1 + GitHub Actions/PR 실측)의 결론:

- **인수인계서는 main 기준으로 이력 문서다.** W4 18/18(PR #209, no-ff 45커밋),
  W3.5 이월 5/5(PR #210), W5 계약 6항목 중 5(PR #211/#217/#218), W6 비영상
  (오디오 게인 #220 · cloze 8그룹 #222 · 감사도구 #219) 전부 main 반영 완료.
  잔여 1건(FeedPhysics.snap 기본 전환)은 "Jin 실기기 승인 전 금지"로 명문화된 게이트.
- 이 저장소 관점의 현행 정본은 `docs/superpowers/specs/2026-08-28-w4-w6-completion-design.md`
  와 그 이후 릴리스 트랙(versionCode 28 내부 #241, 29 비공개 #242)이다.
- 검수를 오도하는 함정 3종: ① 인계서 본문의 stale 서술("T9-18 미착수", "W5 플랜 없음")
  ② W5 a/b/e의 간접 구현(sheet 공용화·`SoriSpeech.*` 정적 API·`SoriStudyFrame` 주입 —
  심볼 사용처 카운트는 거짓 음성) ③ W4 T10/T18의 저장 키는 `Storage.*` 접근자 경유
  (raw 키 grep은 거짓 음성).
- 불일치 발견분: `docs/store/closed-testing-checklist-v2.md` §0 하드스톱(플립게이트
  `ae024af6` 미통과, 2026-08-14 판정)이 열린 채 vC29가 alpha에 업로드됨 /
  `docs/store/app-store-connect-v2.0.8-review-access.md`의 `2.0.8+27` stale /
  tiger_choose 그림자 24.1%는 수리가 아니라 매트 예산 완화(0.06→0.25 그랜드파더)로
  게이트 통과 처리(magpie 2종 동일) / graphify wiki가 그래프보다 1리프레시 뒤짐.
- 배포 인프라: Android 내부 = `ci.yml` `release-internal` 잡(main push 자동 또는
  dispatch, **`vars.PLAY_INTERNAL_RELEASE_ENABLED` 게이트 — 현재 OFF 실측**),
  비공개 = `play_closed.yml`(main tip 정확-SHA + 해당 SHA push CI green 선행).
  iOS는 GitHub Actions 금지(계약 테스트)·Xcode Cloud/Mac 전용 → 이 세션에서 빌드 불가.
- 이 컨테이너: flutter/dart/Android SDK 없음 → 테스트 검증은 PR CI(선택 스위트)와
  main push CI(전체 스위트)로만. Play versionCode는 `git rev-list --count HEAD`
  (pubspec `+N`은 iOS 빌드번호).

## 2. 목표

1. 인수인계서 전 조항의 main 반영 여부를 원자 주장 단위로 판정한 **검수 매트릭스**
   (판정+커밋/파일:줄 근거)를 만들어 저장소에 남긴다.
2. 검수로 확정된 격차·불일치를 수정하고, 이연 minor 중 저비용·저위험 건을 정리한다.
3. 지정 브랜치 → PR → CI green → main 병합.
4. graphify에 검수·병합·배포 결과를 기록(스코프 재추출, manifest 정본 유지).
5. 릴리스: pubspec `2.0.8+30` → Android 내부+비공개 업로드(CI), iOS는 수동 런북 인계.

## 3. Jin 확정 결정 (세션 내 승인)

1. **재배포**: 병합 후 새 빌드(2.0.8+30)를 내부·비공개 두 트랙에 업로드한다.
2. **§0 모순**: 플립게이트 해소 증거를 추적한다. 해소 증거 발견 시 체크리스트 판정을
   갱신하고, 미발견 시 게이트 문서를 조작하지 않고 모순을 기록·보고하되 업로드는
   Jin의 명시 지시를 우선해 진행한다.
3. **graphify**: 전량 재추출 금지(CRLF 드리프트 전례). PR #238 방식 스코프 재추출 +
   manifest 정본 유지. wiki 지연 해소는 스코프 재추출 성공 시에만.
4. **범위**: 검수 + 격차 수정 + 저위험 하드닝. 시나리오 아트 생성(0/126)은 착수하지
   않고 차기 작업으로 목록화만.

## 4. 범위 경계 (하지 않는 것)

- 영상 재생성·교체 전부(tiger_choose 포함 — Jin 제외 지시), FeedPhysics.snap 승격,
  97건 재작성 승격, Firebase/store 프로덕션 배포, App Check enforce, 실기기 게이트,
  시나리오 아트 생성, Play Console 수동 조작(승격·테스터 운영), iOS 빌드/제출.
- 래칫 상향, 가드 allowlist 확장, `docs/assets/**`·매트 예산 코드 수정.
- `.graphify_python`·`graphify-out/cache/**`의 이 컨테이너발 수정.

## 5. 설계

### 5.1 검수 매트릭스
인계서를 ~45개 원자 주장으로 분해(§2 상태표·§3 완료 웨이브 SHA·§4 W4 T1-18·§5 남은 일
전체·§7 계약/래칫·§8 원장·§9 항목 1-10·릴리스 주장). 판정값: `반영` / `의도적 보류(게이트)` /
`미반영` / `불일치` / `검증불가(컨테이너 한계)`. 각 판정에 근거(커밋 SHA, 파일:줄, PR 번호,
가드 테스트명) 필수. 함정 3종 브리프를 검증자에게 명시 전달. `미반영`/`불일치` 1차 판정은
반드시 적대적 재검증(반박 시도) 후 확정. 산출물은
`docs/superpowers/specs/2026-09-01-handoff-verification-matrix.md`로 커밋(SDD 원장은
gitignore라 소실 전례 — 매트릭스는 추적 파일로 남긴다).

### 5.2 격차 수정(확정분) + 조건부 분기
- 인계서 상단 이력화 배너(본문 무수정, 매트릭스 파일 인용).
- `app-store-connect-v2.0.8-review-access.md:101` 버전 핀 제거(pubspec 참조로).
- 체크리스트 §0: §3-2 결정대로 분기. 계약 테스트
  (`test/tester_build_release_contract_test.dart`)가 고정한 문자열 앵커·§2.4 빌드 블록 불변.
- AGENTS.md "현재 진행 중인 작업": 증거로 닫힌 게이트만 정리, tiger_choose 예산 완화
  사실을 UI 실기기 게이트 항목에 1줄 가시화.
- 검수 발견 코드 격차(예상 0~소수): TDD, 래칫 준수, 리뷰 후 커밋.
- 이연 minor 스윕: W2 4건(reward-flow 3초 딜레이, pad mkdir, 가드 정규식, main.dart 주석)
  + W3/W4 원장 deferred 중 미처리분 확인 → 저비용·저위험만 수정, 나머지 목록화.

### 5.3 병합·배포 순서 (고정)
① 검수 PR(draft로 개설 → 완성 후 **ready 전환**(draft는 Build 미실행) → CI green → 병합
→ main push CI green) → ② graphify 기록 PR → ③ **릴리스 PR 마지막**(pubspec 한 줄,
**squash**, 제목 `release: versionCode 30 — Play 비공개테스트`). 릴리스 병합 직전 Jin에게
`PLAY_INTERNAL_RELEASE_ENABLED=true` 요청(변수는 push·dispatch 양경로 게이트, 세션에
설정 권한 없음). 병합 push CI에서 내부 업로드 잡 `success` 확인(skipped=변수 OFF).
→ 그 SHA push CI green + main tip 불변 확인 → `play_closed.yml` dispatch
(`expected_sha`=병합 SHA 40자). → ④ 배포 결과까지 담은 최종 graphify 기록은 closed
디스패치 후 병합. Codex 동시 세션 대비: 각 병합·디스패치 직전 origin/main tip 재확인.

### 5.4 iOS 인계
빌드·업로드 불가(계약 테스트가 CI 자동화 금지 + Linux 컨테이너). 산출: 문서 정정 +
Jin용 수동 런북(2.0.8+30 아카이브 → TestFlight 내부·외부 그룹 부착 → Beta App Review
연락처 입력 → 거절 스레드 회신 → 재제출; 근거: `docs/store/app-store-connect-v2.0.8-review-access.md`,
`APPSTORE_UPLOAD_KO.md`, `ios-external-setup.md`). 불가능을 가능으로 보고하지 않는다.

### 5.5 실행 방식
superpowers SDD: 컨트롤러(이 세션 메인 루프)가 브리프·리뷰 게이트·룰링·최종검증,
태스크별 fresh 서브에이전트가 구현. 검수(읽기 전용)만 병렬 팬아웃 허용, 구현은 엄격
직렬(저장소 규칙). 워크스페이스 `.superpowers/sdd/2026-09-01-handoff-verification-and-release/`
에 `progress.md` 원장 — 종료 전 요약을 매트릭스 문서·PR 본문에 반영(원장 소실 대책).

## 6. 검증

- 문서 수정: PR CI(상시 가드 + 계약 테스트) green, main push CI 전체 스위트 green.
- 코드 수정(있을 시): 신규/갱신 테스트 포함, PR CI 선택 스위트 + main 전체 스위트.
- 배포: run/잡 conclusion 실측(내부 잡 `success`, play_closed run `success`)으로만 보고.
- graphify: 커밋 diff가 의도 범위(graphify-out 중 대상 파일)만 건드렸는지 스테이징 전 검사.

## 7. 리스크

main tip 레이스(릴리스 병합=마지막 병합 + 디스패치 직전 재확인) / 계약 테스트 앵커
파손(편집 전 테스트 재독) / graphify 드리프트(스코프 한정·검사) / 변수 OFF로 내부 업로드
silent skip(잡 conclusion 확인) / Codex 동시 세션(워크트리 격리·본인 파일만 스테이징).
