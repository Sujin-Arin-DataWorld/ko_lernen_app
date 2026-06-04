# v2.0 출시 QA 검증 보고서 (실기기)

> 플랜 §10.2/§10.4 Deliverable. **Jin이 실기기에서 직접 채우는 체크리스트.**
> Android 1대 + iOS 1대, light 모드(다크 폐지). 각 항목 `[x]` + 비고.
> 코드는 `flutter analyze` 0 · `flutter test` 310 통과(2026-06-04). 여기선 **실기기 시각·동작**만 검증.

날짜: ____  ·  Android 기기: ____  ·  iOS 기기: ____  ·  빌드: `2.0.0+3`

---

## 0. 사전 (운영 — 코드 아님)

- [ ] Firestore rules 배포 (`firebase deploy --only firestore:rules`)
- [ ] CF 배포 `analyze_korean_text`(Python) + 키 주입(DeepL 재발급본·우리말샘)
- [ ] CF 배포 `gye`(Node) `on_pack_cleared`·`weekly_goal_rollover`·`on_report_created` + Cloud Scheduler
- [ ] 앱 `Storage.bookAnalysisEndpoint` = 배포 URL

## 1. 신규 사용자 흐름

- [ ] 인트로(솟을대문) → **동의 게이트** → 레벨 선택 → 홈
- [ ] 첫 팩 Learn→Quiz→Boss → 결과 **도장** 시네마틱
- [ ] 한옥 단계 변화 시네마틱(까치 + cross-fade)
- [ ] 홈 호랑이 hero(프레임 폴백 — `.riv` 미제작) 정상

## 2. 책 한 컷 (CF 배포 후)

- [ ] 카메라/갤러리 → 자르기 → OCR 텍스트
- [ ] "분석" → **번역·단어·문법·뜻풀이** 표시(CF 실작동)
- [ ] 단어 → 단어장 저장 → SRS 편입
- [ ] CF 장애 시 graceful(문법패턴만 폴백)

## 3. 계(契) — Phase 6·7 (CF 배포 후, 2계정)

- [ ] 생성 → 6자리 코드 공유 → 다른 기기 입장
- [ ] 팩 클리어 → 상대 계 피드에 `pack_cleared` + 주간목표 바 증가(`on_pack_cleared`)
- [ ] 스티커 전송 → 피드에 스티커 이미지 렌더
- [ ] **공동 한옥**: 주간목표 100% 달성 → 다음 월요일 `weekly_goal_rollover` 후 **요소 +1 영구**(리셋해도 안 줄어듦) + `goal_achieved` 피드 🎉
- [ ] 70%+ → `xpBoostActive` 플래그
- [ ] 피드 100개 초과분 prune(장기)
- [ ] gye_hanok 8요소 좌표 **육안 튜닝**(시안값)

## 4. 모더레이션 + GDPR — Phase 8 (NEW)

- [ ] **연령 게이트**: 계 진입 시 생년 미상 → 입력 다이얼로그. **2010년 등 16세 미만 입력 → 차단 메시지**("Gye ist ab 16…")
- [ ] 16세 이상 입력 → 정상 진입. 재진입 시 재질문 없음(로컬 저장)
- [ ] 신고: 멤버 ⋮ → 사유 선택 → 접수
- [ ] **자동정지**: 서로 다른 3계정이 같은 멤버 신고 → `on_report_created` → 대상 `status=suspended`
- [ ] 정지된 멤버: 피드/스티커 **전송 불가**(rules `isActiveGyeMember`)
- [ ] 정지 회피 불가: 본인이 `status` 직접 변경 시도 → rules 거부
- [ ] **계정 삭제**(Settings): Firebase 계정 + `users/{uid}/*` + **모든 계 멤버십** 제거(cascade)

## 5. 게임·학습 (회귀)

- [ ] 초성 음절 스캐폴드 · Wordle 단청 frame · 끝말잇기 30s · 듣기 자막
- [ ] 커스텀 단어장 4모드(플립·퀴즈·짝맞추기·받아쓰기) + 사진 첨부
- [ ] 도장첩 · 어려운 단어 · 통합 검색
- [ ] **TTS 실발화**(ko 음성 — OS 의존, 실기기 필수)

## 6. 계정·구독

- [ ] 게스트 → Google 링크 → 클라우드 백업
- [ ] iOS: **Apple Sign-In**(Xcode capability 필요)
- [ ] (유료 시) RevenueCat 결제·복원 — 대시보드/상품/키 설정 후

## 7. 반응형·접근성

- [ ] 308/360/430px 폰 오버플로 0 · 넓은 화면 480 중앙 클램프
- [ ] OS reduce-motion → 애니메이션 정지
- [ ] 큰 글씨(textScale) 깨짐 없음

---

## 결과 요약

| 영역 | Pass/Fail | 비고 |
|---|---|---|
| 1 신규 흐름 | | |
| 2 책 한 컷 | | |
| 3 계 | | |
| 4 모더레이션/GDPR | | |
| 5 게임·학습 | | |
| 6 계정·구독 | | |
| 7 반응형 | | |

발견 이슈: ____
출시 판정(Closed Testing Go/No-Go): ____
