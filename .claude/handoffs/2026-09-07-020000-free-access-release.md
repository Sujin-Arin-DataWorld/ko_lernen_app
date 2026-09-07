# 2026-09-07 결제·구독 해제 병합 + 최종 Play 비공개 릴리스 인수인계

> Jin 지시(2026-09-06~07): "이 세션 작업 전부 main 확인 → 후속작업 마감 → 최종 앱스토어·안드로이드 배포", 이어서 "결제 해제 브랜치도 같이 넣어줘", 실행은 Sonnet·지시/검수는 Fable.
> 이전 인수인계 `2026-09-06-203000-account-followups-release.md`(계정 후속 3건)를 잇는다.

## 지금 상태 (한 줄)
main `acf694ed`에 계정 근본 수정(#275)·후속(#276)·W10 PR-C(#274)·PR-S(#272)·결제 해제(#277)가 전부 들어갔고, Android 비공개 테스트에 두 번 올라갔다(761d53b0 계정분, acf694ed 최종). iOS는 맥에서 빌드해야 한다.

## main 병합 이력 (2026-09-06~07)
| PR | 내용 | main |
|---|---|---|
| #274 | W10 PR-C Hören 카드 그리드 | `3ce134be` |
| #276 | 계정 후속 3건(세션 재획득·워커 Apple 스킵·펜스 재조준) | `761d53b0` |
| #272 | W10 PR-S 시나리오 52편(다른 세션 병합) | `74285012` |
| #277 | 결제·구독 해제(무료 출시) 마감 | `acf694ed` |

## #277에서 Fable이 마감한 것 (다른 세션 `codex/free-access-20260905` 3a4bc9bc 이어받음)
- l10n `personalRoomLockedTitle/Body/ReturnToMap` 복원(analyze 6→0), `ildu_world_projection_adapter_test` main 복원.
- `open_access_default_test` 하녹 단언을 Jin 결정(하녹은 CEFR 진척 보상, 개방 대상 아님)을 고정하는 단언으로 교체.
- UIUX 실행 잠금 문서 `/paywall` 행 제거, 라우트 75→74, 인벤토리 테스트 75→74·110→109.
- `cta_vocabulary_guard`: arb에서 사라진 onboarding CTA 2건 고아 제거 + `grammarBrowseAllCta` 등재 + `wordWebBrowseLevelCta` 문구 변경 등재 → 53건, 하향 전용 상한 54→53(어휘 확장·상한 인상 없음).
- 하녹 진척 테스트 6건(5파일) main 복원, `deck_vertical_gesture` 평가 전환 단언을 RNG 무관(`8 / 8` 카운터 부재)으로.
- 골든 `screen_vocab_packs_{compact,medium,expanded}` CI 리눅스 재생성(run 34066762199) — 프리미엄 게이트·잠금 UI 제거 반영. 나머지 베이스라인 sha256 동일.
- 검증: analyze 0, gye 385/0, 전체 스위트 6,042/19스킵/0, PR CI 14/14. Fable이 47파일 앱 코드 diff 직독 승인.
- 사소한 후속 후보: `scenarios_list_screen` 경로 진행 문구가 항상 전체/전체로 표시; `vocab_packs_screen` 카드 높이 측정이 고정 스타일(13.5/w600)로 잼.

## 배포 상태
- Firestore rules + gye 계정 함수 11종: 2026-09-06 22:16 UTC 배포본.
- `getAccessSnapshot`·`getUniversalAccessSnapshot`: 2026-09-07 00:24 UTC **최초 배포**(create). 클라이언트는 실패해도 학습 콘텐츠를 막지 않는 best-effort.
- 구 replacement 콜러블 5종(08-12 배포본)은 코드에서 제거됐지만 배포 삭제 보류(Jin 결정).
- Apple 제공자: **여전히 없음**(REST 실측 `google.com`만). 런북 `docs/store/apple-sign-in-setup.md`.
- `PLAY_INTERNAL_RELEASE_ENABLED=false`(원복 완료).

## Android 릴리스
| sha | 트랙 | run |
|---|---|---|
| `761d53b0` (계정분) | 비공개(alpha) | 34065895708 success |
| `acf694ed` (최종, 결제 해제 포함) | 비공개(alpha) | 34071971389 — https://github.com/Sujin-Arin-DataWorld/ko_lernen_app/actions/runs/34071971389 |
프로덕션 승격은 Play Console에서 Jin이 한다(GH 워크플로 없음). versionCode는 `git rev-list --count`로 자동 증가.

## iOS (맥 전용 — Jin)
`docs/store/APPSTORE_UPLOAD_KO.md`: `FREE_LAUNCH=1 bash scripts/build_ios_ipa.sh` → Transporter → TestFlight → 심사. **Apple 제공자 설정 전에는 Sign in with Apple이 "미설정"이라 심사(4.8) 위험 — 제출 전 설정 권장.**

## 교훈
- CI `test` 잡은 변경 범위 기반 부분 실행이라 전체 스위트를 대신하지 못한다. 병합 전 로컬 전체 스위트 1회 필수.
- 골든 베이스라인은 리눅스 CI 정본 — 화면 변경 시 `task=regenerate-goldens` dispatch → 아티팩트 sha 대조 → 변경 파일만 커밋.
- 평가 순서 RNG처럼 시드 없는 무작위에 기대는 단언은 금지(1/8 플레이크 실사례).

## Jin이 해야 할 것
1. Apple Developer·Firebase Apple 제공자 설정 → `.env.ko-lernen-app`·GitHub variables → `completeAppleRevocation`·`appleOAuthCallback` 재배포.
2. 실기기 검증(계정: Google 연동·재연동·삭제·오프라인 삭제 재시도; 결제 해제: 전 레벨 팩 접근·하녹 진척 잠금 유지).
3. 결정: 익명 자동 삭제(권장 철회), 구 replacement 함수 5종 삭제, Play 프로덕션 승격, iOS 제출.
