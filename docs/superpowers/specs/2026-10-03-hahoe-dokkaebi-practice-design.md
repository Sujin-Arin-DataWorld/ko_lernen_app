# 하회탈·도깨비 첫 적용과 후속 작업

승인된 범위: Smalltalk, Silben-Kreuz, 한옥 사랑방 세 곳. 페르소나 11명의 에셋·프로필·등장 연결은 별도 채팅 소유다. 기존 인물 이름·음성 resolver를 소비한다.

## 첫 버전

1. Smalltalk × 하회탈: 초대·부탁·거절·사과·오해 풀기 두 사례씩, 총 10사례. 상황(관계·친밀도·장소·채널) → 의도 → 표현 선택 → 문법과 상황 효과를 구분한 설명 → 후속 문장 조립. 각 사례에 상대나 장소가 달라지는 전이 연습을 둔다. 가능한 표현을 단일 말투 정답으로 축소하지 않는다.
2. Silben × 도깨비: 현재 선택 단어의 뜻·방향 → 실제 교차 칸 → 한 음절 공개. 음절은 사용자가 직접 타일로 놓는다. 교차 칸의 공개는 해당 칸을 공유하는 단어의 도움으로 기록한다. 기존 퍼즐 완료·XP·개인 기록은 유지하고 복습은 추가 보상을 만들지 않는다.
3. 사랑방: 고정된 학습 기록 진입점에서 표현 전이 연습과 도움받은 퍼즐 재도전을 연다. 열람·도움받은 수행·혼자 수행을 별도로 보존한다. 기록은 기기 저장 및 기존 계정 백업·복원과 연결한다.

공유 인터페이스: `SmalltalkContextCase`, `PracticeHistoryStore`, 백업 필드 `hanok_practice_json`. 콘텐츠와 기록은 버전을 갖는다. 성공 표시는 저장 성공 이후에만 한다. 계정·로컬 데이터 수명 변경 이후의 오래된 비동기 작업은 기록하지 않는다. 저장 재시도는 같은 attempt ID를 사용하고 병합은 결정적이며 중복되지 않는다.

공식 완료 기준: 다양한 표현 인정, 문법/상황 효과 분리, 선택 단어·교차 칸·타일·완료 정확성, 재실행/복원/계정 전환/저장 실패 내구성, DE/EN/큰 글자/모션 감소/TalkBack/Android 학습→사랑방 전이 확인, 실제 UI 리허설·ui-demo 녹화 및 변경 SHA 필수 검사. 로컬 검사와 원격 CI·실기기 접근성 검증은 각각 근거를 남긴다.

## 후속 대기 목록

상태는 **대기 → 진행 → 검증 → 완료**. 착수 시 최신 게임 구현을 다시 확인한다. 완료는 구현과 검증 근거를 모두 요구한다.

| 순서 | 상태 | 작업 | 완료 기준 |
|---|---|---|---|
| 1 | 대기 | 초성 Quiz | 주제·의미 → 답 길이 → 한 음절. 세 문제 정확히 풀기, 도움 후 독립 재도전과 기록. |
| 2 | 대기 | Blitz-Paare | 의미 범주 → 비교 범위 축소 → 한 쌍. 헷갈린 쌍의 재도전과 기록. |
| 3 | 대기 | Satz-Arcade | 문장 시작·핵심 구절 → 단어 위치. 실제 구조에 맞는 시간 도전. |
| 4 | 대기 | Tageschallenge | 실제 문제 유형의 힌트 재사용, 오늘의 짧은 묶음 완료. 시작·도움·완료 반응은 실제 결과와 일치. |
| 5 | 대기 | 문화 카드 | 목재·턱·각도와 놀이 문화 KO/DE/EN. 역사 설명과 앱의 현대 해석 분리. |
| 6 | 대기 | 추가 반응 에셋 | 방망이 부분 움직임·탈 각도 별도 에셋 제작·검수. 승인된 원본 보존. |
| 7 | 대기 | 도깨비 엽전 정책 | 지급 대상·금액·최초/재도전·중복 방지 확정 후 구현. 힌트 무료. |
| 검토 | 대기 | 자유입력·발음 평가 | 다양한 답변의 평가/교정 기준 및 운영 비용 검토. 첫 버전 필수 아님. |

## 구현 판단

- 기준 브랜치는 최신 `origin/main`. 진행 중인 질감 UI PR 전체를 병합하지 않고 승인된 하회탈·도깨비 원본 바이트만 필요한 경로로 사용한다. 나중에 같은 경로의 동일 바이트가 합쳐진다.
- 사랑방 연습 기록은 기존 코스 성취 receipt 및 가구 슬롯과 독립이다. 열람·개인 연습을 코스 mastery, 건축 진척, 엽전으로 승격하지 않는다.
- 신규 한국어 콘텐츠의 검수 상태는 모델 검수로 명시한다. 인간/원어민 승인으로 표시하지 않는다.
- 사용자 요청에 없는 커밋·푸시·병합·배포를 실행하지 않는다.

## Accepted visual correction (2026-10-03)
The user replaced the floating mask presentation with the masked scholar. Restore the original full-body `yangban-performer-v1.png` as `assets/illustrations/tactile/hahoe_scholar.png` (SHA-256 `83aa8e95bac147b57447ae2363e074310e07c970a757aebc602a64ccf8a1c1d7`, 2141069 bytes). No repainting or face-only crop. Use the whole figure in the Smalltalk guide, entry and Sarangbang collection. Preserve the old mask bytes only under `assets_unused/approved_texture_originals/hahoe-mask-object-v1.png`, outside the runtime bundle. Learning behavior and backlog stay the same.

## 구현과 검증 근거

첫 버전의 구현은 `lib/screens/smalltalk_context_screen.dart`, `lib/screens/silben_kreuz_screen.dart`, `lib/screens/hanok_practice_screen.dart`, `lib/services/practice_history_store.dart`에 있다. Smalltalk 허브와 사랑방의 고정 진입점은 기존 라우터로 연결한다. 열람, 도움받은 완료, 독립 완료는 두 학습 모두 별도 기록이며 복습은 추가 보상을 만들지 않는다.

최종 검증 명령·결과와 기존 메인 실패의 경계는 [구현 계획의 검증 절](../plans/2026-10-03-hahoe-dokkaebi-practice.md#verification-after-restoring-the-learning-scope)에 둔다. 사용자 요청으로 Android/TalkBack 실기기 확인은 후속으로 둔다. 기존 영상 작업과 폐기 후보는 원래 영상 작업 공간에 보존하며, 이 첫 버전은 승인된 정적 캐릭터를 사용한다.
