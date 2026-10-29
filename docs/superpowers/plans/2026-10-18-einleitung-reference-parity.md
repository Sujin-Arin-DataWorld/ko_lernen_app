# Einleitung 원본 일치 및 메인 통합 검증 계획

현재 상태: **로컬 Flutter 구현·브라우저 검증 완료.** 최종 배율 수정, 오디오 안내 오류 수정과 실제 완료/재진입을 검증했다. 전달 여부는 이 정적 문서 대신 해당 PR의 정확한 커밋·병합 기록과 CI 결과로 판단한다.

## 현재 체크아웃과 보존 근거

- 작업 위치: `C:/dev/hangulsori/ko_lernen_app_worktrees/einleitung-settings-parity-20261018`.
- 현재 브랜치: `session/einleitung-reviewed-main-20261018`.
- 메인 통합 기준 HEAD: `44727c1921b4b7f40748ac0d210d0ca62a094028`. 아직 최종 변경 커밋을 뜻하지 않는다.
- 원래 작업 브랜치 `session/einleitung-settings-parity-20261018`, HEAD `2d68784d3b642a14fe174de26d55b0c82209a694`의 WIP는 root가 stash `f66e8f1a70da76af2a98a3870605b8f1be70d086`에 보존했다.
- 현재 사용자 지시에 따라 구현과 검증을 계속한다. 기존의 “계획만 수립, 실행하지 않음” 상태는 종료되었다. 추가 사용자 승인 질문 없이 이미 허용된 범위로 진행한다.

## 정본과 범위

정본은 `C:/Users/vjinn/.codex/generated_images/einleitung_setting_rats확정/`의 Welcome, 01, 레벨 선택창, 02–06 및 07 Joy/Taego이다. 측정 규격은 `tool/einleitung_reference_spec.json`이다. 폰 하드웨어·주변 배경은 앱 영역에서 제외하고 같은 뷰포트·언어·100% 글자 크기로 비교한다.

독립 생성한 전체 에셋을 사용한다. 원본 목업을 잘라 런타임 그림으로 사용하지 않는다. 장면 정체성·얼굴·주요 소품 수·배치·재료감을 검수하되, 생성 그림의 세부 질감·얼굴 디테일·잎·랜드마크 및 글자 안티앨리어싱 차이가 남으므로 픽셀 100% 일치를 주장하지 않는다.

**Vorschau 목적 화면은 전부 제외한다.** 사용자가 지정한 “Spiele 앱 구현 계획 세우기” 채팅 소유다. 이 작업은 기존 진입 hook과 최소 48dp 터치 영역만 보존한다. 목적 화면의 옛 캡처나 목록을 이번 작업의 구현·승인 근거로 쓰지 않는다.

현재 메인의 IntroGate, FirstRunCoordinator, durable journal, gate lifecycle, 저장·완료·재진입 계약을 유지한다. 이전 원본 브랜치 조사에 있던 gate retirement 및 AppShell 직행 제안은 폐기되어 이번 통합에 적용하지 않는다. A1–C2·입문·관심사/스토리 ID·동의·TTS/영상·보상 소유권·원본 학습 내용도 보존한다.

## 완료된 범위의 근거

- [x] 원본 화면별 측정표, 아트 구성, 제목·본문·CTA·뒤로 좌표를 정리했다.
- [x] 01과 레벨 선택창의 공통 컴포넌트를 세 디자이너 관점으로 검수한 뒤 다른 화면으로 확장했다.
- [x] Welcome, 02–06, 07 정지 Figma와 필요한 선택·다음/뒤로 흐름을 검수했다.
- [x] native Flutter 텍스트·컨트롤·선택 상태로 옮기고, 현재 메인의 wrapper와 진입/상태 계약을 보존했다.
- [x] 기록된 402×934·100% 캡처를 원본/Figma와 비교했다. 402×874 및 좁은 화면·200%는 별도 QA로 구분했다.
- [x] 07 선택 시 스크롤·포커스·CTA 높이·저장 실패 복구를 전용 widget 검사로 확인했다.
- [x] 현재 manifest의 **32 PNG, 57,771,539 bytes**를 직접 읽어 모든 SHA-256이 일치함을 재검증했다.
- [x] 기록된 빌드에서 32개 에셋의 실제 HTTP 전달 검사가 통과했다. 이는 최종 브라우저 UI/흐름 검증과 별도다.

Figma 파일은 `rVlcMLvngw07BYJ7nRT87C`, 페이지는 `77:2`다. Welcome `85:32`, 01 `80:336`, 레벨 `80:569`, 02–06 `80:380/406/433/455/480`, 07 정지 기준 `80:505/537`, 비교판 `108:35`를 유지한다. 목적 화면 `89:32`는 범위 밖이다.

검수 근거:
- `tool/einleitung_generated_assets.json`: 32개 전체 파일과 출처/SHA.
- `tool/einleitung_http_verification.json`: 기록된 빌드의 HTTP 전달 결과.
- `tool/einleitung_story_art_review.json`: 02–07의 기록된 Figma/native 캡처와 범위를 한정한 시각 승인.
- `tool/einleitung_companion_ux_review.json`: 07 선택/스크롤/저장 회귀 결과.
- `docs/screenshots/einleitung-parity-review-20261018/`, `docs/screenshots/einleitung-generated-20261018/`: 버전별 Figma 및 native 증거. 과거 중간 캡처는 최종 브라우저 검증을 대체하지 않는다.

## 검사 상태와 남은 작업

Root가 보고한 직전 통과 그룹은 new UI 54, entry/state 55, 기존 wrapper 84, typography 10, ARB/asset 12, locale 5다. 중복 제거된 전체 테스트 수로 합산하지 않는다. 이 결과는 진행 중인 마지막 typography 수정 전 근거이며, 영향을 받는 검사는 수정 후 다시 실행한다.

고정 pane 배율 수정 후 관련 75개 검사, 실제 최상위 오디오 안내 오류 수정 후 22개 검사가 통과했다. 각 분석 결과는 No issues found다.

- [x] fixed pane의 실제 너비로 comfort 배율만 재합성하고 OS/custom 확대를 보존했다.
- [x] 최종 release web 빌드 및 32 PNG HTTP/SHA 검사를 통과했다.
- [x] 실제 1280×720 브라우저의 402px 소개 영역에서 Welcome, 01/레벨, 02–07을 확인하고 캡처했다.
- [x] 레벨 취소/적용, 관심사, 다음/뒤로, 음성 실패 안내 닫기, 동반자 반복 선택, 완료 및 재시작을 확인했다. 최종 검사 구간 콘솔 오류/경고는 없었다.
- [x] 100%·130%·200% 및 비선형 확대, 동작 줄이기 관련 회귀 검사를 통과했다. 작은 화면 캡처는 별도 QA다.

- [ ] 최종 소스/증거를 커밋하고 push한다.
- [ ] 정확한 push 커밋의 CI 성공을 확인한 후 허용된 메인 병합을 수행한다.
- [ ] 정확한 병합 메인의 필수 CI와 고유 파일 보존을 확인한 후, 작업공간 정리 규칙에 따라 안전 여부를 판단한다.

기기 설치/조작과 스토어 배포는 미검증이다. 정지 캡처, widget 검사, HTTP 전달, 실제 브라우저, 물리 기기, CI/병합을 서로 대체하지 않는다. 실제 TTS 성공 재생은 기존의 서비스 불가 처리 검사만으로 입증되지 않는다.

## 증거 정리

Root는 아래 네 개의 오래된 증거를 stash `f66e8f1a70da76af2a98a3870605b8f1be70d086^3`의 동일 바이트로 확인한 뒤 pending delivery에서 제외했다.

- `docs/screenshots/einleitung-parity-review-20261018/level-figma-v2.png` — 0바이트 중간 파일.
- `docs/screenshots/einleitung-generated-20261018/live-complete-heute-402-934.png`.
- `docs/screenshots/einleitung-generated-20261018/live-hanok-402-934.png`.
- `docs/screenshots/einleitung-generated-20261018/live-welcome-desktop.png`.

현재 Einleitung screenshot inventory의 0바이트 PNG는 0개다. 나머지 버전별 Figma 중간 결과는 역사적 증거로 남긴다. 최종 실제 브라우저 캡처는 `web-final-*.png`이며, 검사 범위와 파일 SHA는 `tool/einleitung_verification.json`에 기록했다.

전달 상태의 기준 파일은 `tool/einleitung_verification.json`, 메인 통합 계약은 `tool/einleitung_main_integration_review.json`, 후속 범위는 `tool/einleitung_followup_scope.json`이다. 이 문서 정리 자체는 런타임 수정, Git 조작, 삭제, 최종 완료 판정을 수행하지 않는다.
