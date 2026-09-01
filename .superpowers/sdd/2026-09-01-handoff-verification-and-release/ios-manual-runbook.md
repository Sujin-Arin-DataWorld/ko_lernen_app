# iOS TestFlight/App Store 수동 런북 (Jin 전용, 2026-09-01)

> 이 세션(리눅스 컨테이너)에서는 iOS 빌드·업로드가 불가능하다: GitHub Actions의 iOS 배포는
> `.github/scripts/test_play_internal_workflow.py::test_ci_never_deploys_ios_or_closed_testing`
> 계약 테스트가 금지하고, 아카이브는 Xcode Cloud 또는 Mac에서만 된다. 아래는 Jin이 Mac에서
> 수행할 정확한 잔여 절차다. 근거 문서: `docs/store/app-store-connect-v2.0.8-review-access.md`,
> `docs/store/APPSTORE_UPLOAD_KO.md`, `docs/store/ios-external-setup.md`.

## 배경
- 2.0.7 (242)는 App Review에서 "리뷰 접근 정보 부족"으로 거절됨.
- 대응은 이미 main에 랜딩: 동의 화면의 read-only 데모(`View demo`/`App ansehen`, 15개
  미리보기 표면, 변이 없음) + Beta App Review 회신 텍스트 (`00cbd1d0`).
- 릴리스 PR 병합 후 pubspec은 `2.0.8+30` — iOS CFBundleVersion은 이 `+30`
  (`CURRENT_PROJECT_VERSION = $(FLUTTER_BUILD_NUMBER)`), 단 Xcode Cloud는 자체 증가
  빌드번호를 쓸 수 있으므로 TestFlight에 처리된 값 기준으로 확인.

## 절차 (순서대로)
1. **최신 main 아카이브** — Mac에서 main 병합 SHA를 체크아웃하고 Xcode Cloud 아카이브
   실행(또는 로컬: `scripts/build_ios_ipa.sh` — `ASC_*` 3변수 설정 시 자동 업로드).
   Flutter 3.44.0 (`ios/ci_scripts/ci_post_clone.sh` 핀과 동일).
2. **클린 설치 검증** — 후보 빌드를 깨끗한 iPhone + iPad에 설치, 게스트 온보딩과
   `View demo`→동의 상태 무변경 검증(문서의 Final archive and TestFlight gates 절).
3. **TestFlight 그룹 부착** — 처리된 빌드를 내부 그룹 + 외부 그룹 **둘 다**에 부착.
4. **Beta App Review Information 입력** — 실제 모니터링되는 리뷰 연락 이메일·전화번호
   입력(문서에 "Release owner must enter and verify"로 지정된 항목) 후 저장.
5. **거절 스레드 회신** — `app-store-connect-v2.0.8-review-access.md`에 준비된 회신
   텍스트로 기존 App Review 스레드에 답장.
6. **재제출** — 교체 빌드로 재제출.
7. **App Store 제출 잔여** (TestFlight 통과 후): live `support.html`/`privacy.html`/
   `account-deletion` URL 확인, App Privacy 설문(최종 아카이브 기준), 연령 등급,
   실기기 iPhone+iPad 스크린샷, 수출 규정 답변(`ITSAppUsesNonExemptEncryption`은
   의도적으로 미설정 — Jin이 직접 판단, `APPSTORE_UPLOAD_KO.md`).

## 하지 말 것
- GitHub Actions에 iOS 배포 잡 추가(계약 테스트가 막고, 정책상 금지).
- TestFlight 처리 전 버전값 추정 보고(처리된 값으로만).
