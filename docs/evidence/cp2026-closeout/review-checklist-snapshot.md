# Read-only review checklist snapshot — 2026-09-29

Copied C01–C09 / D01–D08 / L01–L03 and current review instructions. This is a historical snapshot, not an editable source of new approvals. Windows paths inside it identify archive-only candidate files; transfer and verify those files before content review. Device procedures can be read on any host. No unchecked item becomes complete by copying this file.

## 1. 지금 Jin이 확인할 것

- [ ] **J01 — 기기·앱 정보:** iPhone은 iPhone16 / iOS26.6.1로 이미 확인했습니다. Android 기종·OS와 업데이트 후 실제 표시되는 앱 빌드 번호를 기록해 주세요. 소스 SHA 연결은 제가 합니다.

- [ ] **J02 — iPhone 책 스캔:** 개인정보 없는 짧은 한국어 문장 2~3개를 스캔해 결과 또는 오류 문구·발생 시각을 기록합니다. 서버 앱 ID 허용 목록은 반영됐고 실제 iPhone 성공은 아직 미확인입니다. 새 카드 진입은 254에서 확인합니다.

- [x] **J03 — Cookiebot 관리자 로그인 완료:** 다시 로그인할 필요 없습니다. 일반 방문·페이지 이동·앱 측정 검증은 제가 이어갑니다.

- [ ] **J04 — 오늘/한옥 오류가 계속된다면:** 화면·문구·발생 시각·Wi-Fi/모바일 데이터 여부를 기록합니다. 기존 계정이나 앱 데이터를 초기화하지 않습니다.

- [x] **J05 — App Store Connect 로그인 완료:** 기존 Hangul Sori / 6798293722 / com.sujinarin.koLernenApp을 확인했습니다. 9월24일 내부254 제공을 확인했습니다.

- [x] **J06 — Cloudflare 로그인 완료:** 기존 계정과 hangul-sori-redesign 운영 서비스를 직접 확인했습니다. 재로그인 요청 없이 배포·측정 복구를 이어갑니다.

- [x] **J07 — Apple 연결 복구 확인:** 9월24일 로그인 유지와 기존 앱 Cloud254 성공·내부 제공을 직접 확인했습니다. 추가 로그인 요청은 없습니다.

기록 예: `J02 / 앱 버전+빌드 / 성공 또는 오류 문구 / 현지 시각`

## 2. 지금 열어 볼 콘텐츠 — 가능하면 위에서부터

모델 검사와 사람 검수는 별개입니다. **한국어 의미·말투·상황이 자연스러운지**를 먼저 봐 주세요. 독일어·영어는 자신 있게 판단할 수 있는 언어만 확인하고, 나머지는 `미판정`으로 남기면 됩니다. 원어민·교육과정 수준 판정이 필요한 부분은 별도 검수로 남깁니다.

| 체크 | 열어 볼 자료 | 확인할 것 |
|---|---|---|
| [ ] C01 | [이번 안정화의 짧은 카피·전화 상황](C:/dev/hangulsori/_codex_artifacts/cp2026-release-stabilization-20260922/jin-review/STABILIZATION_CONTENT.md) | 전화 응대 맥락, 인사·자기소개, KO 기준 DE/EN 의미, 문제의 정답·오답 |
| [ ] C02 | [문법 C4-G1 12항목 전체](C:/dev/hangulsori/_codex_artifacts/cp2026-release-stabilization-20260922/jin-review/c4_g1_grammar_jin_sample.md) | 설명·두 예문·번역·퀴즈가 같은 의미와 용법인지 |
| [ ] C03 | [Batch 32·33 및 C9 통합 검수](C:/dev/hangulsori/_codex_artifacts/cp2026-release-stabilization-20260922/jin-review/cp2026_pending_jin_review.md) | A2 7+7어와 사용법 노트 10건. 표제어 뜻·실제 장면·말투·번역·오답 적합성 |
| [ ] C04 | [Batch 34 A2 표본 7어](C:/dev/hangulsori/_codex_artifacts/cp2026-release-stabilization-20260922/jin-review/batch_34_a2_jin_sample.md) | 문장의 자연스러움과 제시된 번역에 맞는 정답이 하나인지 |
| [ ] C05 | [기존 예문 9건의 의미·문맥 확인](C:/dev/hangulsori/_codex_artifacts/cp2026-release-stabilization-20260922/jin-review/C05_SOURCE_TRIAD_REPAIRS.md) | v2 수정안의 뜻·생략된 행위자·권한 범위·팀 수 확인. 27레코드 수정 미리보기만 준비했으며 앱 미반영·사람 승인 전 |
| [ ] C06 | [관련어 공란 12묶음·24개 관계 설명](C:/dev/hangulsori/_codex_artifacts/cp2026-release-stabilization-20260922/jin-review/wordweb_related_20260923_jin.md) | 한국어 관계와 DE/EN 설명 확인. 앱 미반영이며, 이 설명 승인은 별도 퀴즈 보기의 정답 유일성 승인이 아닙니다. |
| [ ] C07 | [B1 기존 문법 3항목의 보완 후보·6개 새 장면](C:/dev/hangulsori/_codex_artifacts/cp2026-release-stabilization-20260922/b1-grammar-draft-g2/REVIEW.md) | -고 싶어 하다 / -(으)려면 / -아/어 두다의 설명·KO 예문·DE/EN 의미 확인. 기존 Phase에도 같은 세 문법 과제가 있으므로 새 누락 3항목 충족으로 집계하지 않고 비교용 보완 후보로 보존합니다. 독립 모델 검토 두 축 지적 0. [선택형 3문항·직접 표현 3문항](C:/dev/hangulsori/_codex_artifacts/cp2026-release-stabilization-20260922/b1-grammar-draft-g2/ASSESSMENT_REVIEW.md)도 준비했으며 앱 미반영·퀴즈 미승격·사람 승인 대기. |
| [ ] C08 | [A1 말다: 뜻·대화 2개·평가 2개](C:/dev/hangulsori/_codex_artifacts/cp2026-release-stabilization-20260922/a1-malda-draft/REVIEW.md) | 잊지 말다의 보조 동사 뜻만 다룹니다. 독립 모델 검토 두 축 지적 0, 실제 CSV 소비 확인. A1 설명 난이도·팩 배치·사람 검수·TTS·앱 반영은 남습니다. |
| [ ] C09 | [B1 카드 후보 2개·기존 예문 4개](C:/dev/hangulsori/_codex_artifacts/cp2026-release-stabilization-20260922/b1-card-reuse-g3/REVIEW.md) | -고 말다 / -아·어 보이다의 설명과 DE/EN 번역, [선택형 문항 2개](C:/dev/hangulsori/_codex_artifacts/cp2026-release-stabilization-20260922/b1-card-reuse-g3/ASSESSMENT_REVIEW.md)를 검수합니다. 기존 Phase 한국어 원문은 동일하며 모델 두축0·실제 소비코드 검사를 완료했습니다. 사람 승인·앵커·TTS·앱 반영은 미완, 새 문법 커버리지 추가 인정0. |

응답 예: `C02 / grammar ID / 한국어 승인 / DE 미판정 / EN 수정 / 제안 문장…`

`승인·수정·보류`를 항목 ID와 함께 알려 주세요. 표본 7건 승인을 전체 64건 승인으로 넓히지 않습니다. 이 목록을 확인해도 과거 Batch01/02 권리·카피, Batch07/12 이력, 나머지 콘텐츠의 사람 검수 부채가 모두 해소되는 것은 아닙니다. 제가 이력을 정리해 실제로 판정 가능한 묶음으로 추가 제공하겠습니다.

자료는 현재 소스에서 별도 보관한 복사본입니다. Batch32/33의 예전 해시는 CRLF 줄바꿈, 현재 CSV는 LF여서 다르며 텍스트 변경은 아니었습니다. 원본 검수 이력은 덮어쓰지 않았습니다. [추출·해시 근거](C:/dev/hangulsori/_codex_artifacts/cp2026-release-stabilization-20260922/jin-review/source-proof.json)

## 3. 테스트 빌드에서 검수할 화면

**현재 제공 확인 기준은 Android 공개7680과 기존 iOS 내부254입니다.** 새 Android 공개 빌드 제공 후에는 해당 버전 번호를 기록하고 D01~D08을 실행합니다. 책 스캔 카드·새 이미지의 기존 빌드 검사와 새 통합분 검사를 구분합니다. 기존 계정에 업데이트하고 학습 계정/데이터를 삭제·초기화하지 않습니다. 두 빌드 모두 받침·최소 시나리오·책 분석·측정 동의 후속을 포함하며, iOS254에는 OCR405·406도 포함됩니다. 실제 설치와 기기 검수는 미확인입니다.

각 항목을 `통과 / 문제 / 미실행`으로 기록해 주세요. 보유하지 않은 기기·언어·보조기술은 미실행으로 남깁니다. DE/EN, 휴대폰/태블릿, 보통/큰 글자 자동 검사는 제가 맡습니다.

- [ ] **D01 — 업데이트 후 오늘·한옥:** 기존 계정에 업데이트 → 오늘과 한옥 열기. 진행도·XP·건물이 이전과 같고 정상 표시되는지 확인합니다. 오류 때 재시도할 수 있어야 하며 초기화되거나 건축 단계가 추가되면 안 됩니다.

- [ ] **D02 — 캐릭터 선택:** 조이 선택 → Lernen·Spielen·Hanok·Gye 상단이 즉시 조이로 바뀌는지 → 앱 완전 종료·재실행 후 유지되는지. 태고도 확인합니다. 캐릭터 숨김은 일반 프로필 아이콘이어야 하고, 조이는 합의한 기존 정면 그림이어야 합니다.

- [ ] **D03 — Hören 첫 안내:** 안내의 강조 영역이 실제 카드에 맞는지. 스크롤·기기 회전 후에도 어긋나거나 안내 상자가 화면 밖으로 나가지 않는지 확인합니다. 안내를 다시 여는 테스트 경로는 제가 함께 제공합니다.

- [ ] **D04 — 긴 상황 제목:** 긴 제목의 상황 열기 → 작은 화면·큰 글자로 확인. 제목을 모두 읽고 뒤로 가기·재생 속도·학습 시작을 누를 수 있어야 합니다.

- [ ] **D05 — 오프라인·재연결:** 학습 저장 후 앱 재실행, 비행기 모드, 연결 복구를 확인합니다. 기존 진행도 유지, 필요한 오류·재시도 안내, 정상 복구를 봅니다. XP나 보상이 중복 지급되면 문제입니다. 저장 실패 강제 주입 검사는 제가 합니다.

- [ ] **D06 — 새 사용자·온보딩:** 별도 테스트 계정·기기에서 태고·조이 선택과 계속 버튼에 접근할 수 있는지, 큰 글자·가로 화면에서 잘리지 않는지. 새 사용자의 빈 진행 상태는 로딩 오류처럼 표시되면 안 됩니다.

- [ ] **D07 — 책 스캔·음성:** iOS/Android의 실제 새 빌드로 짧은 문장 스캔 → 결과 → 단어·문장 음성 재생. 오류·무음·잘못된 결과를 기록합니다.

- [ ] **D08 — 측정 동의:** 제가 검증 시간을 지정하면 동의 거절 상태와 허용 상태에서 정해진 학습 행동을 한 번씩 실행합니다. 이벤트 전송·중복·GA 스트림 수신·개인정보 여부는 제가 확인합니다.

문제 기록 예: `D04 / Android 기종 / OS / 빌드 / DE / 큰 글자 / 제목은 보이지만 시작 버튼 접근 불가 / 시각`

## 4. 나중에 별도 빌드·절차를 드릴 실기기 검수

- [ ] **L01 — 한옥 다운로드 #367:** 다운로드 동의, Wi-Fi·모바일 데이터, 오프라인 재실행, 팩 삭제 후 진행도 유지, 다시 다운로드. 원본 화질 비교와 실제 설치 용량 측정은 제가 준비·분석합니다. 지금은 HOLD이며 자동 병합하지 않습니다.

- 분리 전 최신 기준: Android7680 참조 기기 다운로드483MB, iOS253 iPhone16 예상 다운로드500MB/설치620MB. 실제 기기 설치 실측이나 #367 합격 증거는 아닙니다.

- [ ] **L02 — 접근성:** 실제 TalkBack/VoiceOver, 큰 글자에서 주요 화면 이동·버튼 이름·순서. 자동 접근성 검사만으로 완료 처리하지 않습니다.

- [ ] **L03 — 저사양 기기·운영 관측:** 지정한 기기로 시작 시간 측정에 협조. 14일 동안 모든 화면을 매일 수동 검수할 필요는 없습니다. 동의한 사용자 집단의 크래시·ANR·진행도 보존·성능 지표는 제가 집계하고 증거를 제시합니다.
