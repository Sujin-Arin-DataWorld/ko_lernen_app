# A1-C2 콘텐츠 텍스트 전체 감사 및 정합화 보고서

## 결과 요약

앱이 번들에서 읽는 `assets/data` 22개 파일을 명시적으로 분류하고, 15,189개
레코드의 학습자 표시 텍스트 73,880개를 leaf 단위로 감사했다. 분류되지 않은 파일,
누락 파일, 해결되지 않은 marker, 부분 번역 triplet은 모두 0이다.

“전체 업데이트”는 올바른 문장까지 전부 다른 표현으로 바꾸는 뜻으로 사용하지 않았다.
모든 leaf를 감사 범위에 넣되 결함이 확인된 문구만 수정하고, 나머지는 ID·레벨·학습
목표·정답 계약을 보존했다.

## 실제 변경

### 레벨 선택

- `DailyChallengeScreen`: 사용자 레벨이 있으면 같은 레벨의 Cloze만 고른다.
- `ReviewDeckService`와 `PersonalizedLessonService`: 신규와 due 복습을 모두 정확한
  레벨로 제한한다.
- 결과적으로 C1/C2 오늘의 단어·복습에 A1 `안녕하세요`가 오래된 due 항목이라는
  이유만으로 섞이지 않는다.

### 시나리오 A1-C2

- Batch 10 시나리오 174개(A1 45, A2 45, B1 32, B2 36, C1 8, C2 8)의
  공통 임시 문법 설명을 레벨별 기능 설명으로 교체했다.
- 듣기·번역·빈칸·문장 만들기의 전역 임시 오답을 같은 장면의 대화와 어휘에서 만든
  오답으로 교체했다.
- 듣기 DE/EN 오답은 같은 대화 턴의 번역쌍으로 고정해 의미가 어긋나지 않게 했다.
- 다음 고급 시나리오 7개의 직역투 또는 의미 누락을 source → draft → runtime에
  함께 반영했다: `c1_kpop_fan_labor`, `c1_policy_sunset_clause`,
  `c1_critique_anonymous_limits`, `c1_attribution_reuse_without_credit`,
  `c2_history_merging_conflicting_testimonies`,
  `c2_aesthetic_poem_rhythm_meaning_loss`,
  `c2_representation_spokesperson_handover_concession`.
- 재생성 시 기존 `shelf`·`backdrop`을 지우던 빌더 회귀를 수정하고 174개 모두에
  보존 검사를 추가했다.

### Smalltalk A1-C2

60개 레코드의 DE/EN 104개 필드를 수정했다. 레벨별 필드 수는 A1 19, A2 26,
B1 12, B2 13, C1 17, C2 17이다. 수정 원인은 naturalness 54, grammar 15,
meaning 14, dialogue 6, culture 5, relationship 5, clarity 2, context 2,
typography 1이다.

대표 수정은 다음과 같다.

- A1: `좋은 꿈 꿔요`의 누락 번역 복원, 쓰레기 배출·사진 촬영·교통카드 응답의
  직역투 제거, 가족 장면의 명령조 완화.
- A2: 독일어 의문문과 굴절 오류 수정, 국제전화 질문에 전화카드 판매 답변이 붙던
  대화 불일치 수정, 호칭과 관계 거리 조정.
- B1-B2: 문장 파편과 기계 번역 표현을 실제 대화·업무 문맥으로 정리하고 Jeon,
  취업비자, 피드백 같은 의미를 구체화.
- C1-C2: 표본·근거·자동 심사·이의제기·호칭·철회 같은 고급 주제에서 의미 범위와
  제도 용어를 정확하게 조정.

과거 승인 CSV를 소급 수정하지 않았다. 현재 수정은
`tools/content_factory/review/content_humanization_20260821.json`에 before/after,
레벨, 필드, 결함 분류로 기록했다. `humanReviewStatus`는
`required_before_native-quality-claim`이며, 이는 원어민 또는 한국어교육 전문가의
최종 승인을 꾸며 내지 않기 위한 명시적 gate다.

A1-B2에서 수정된 42개 Smalltalk 레코드는
`can_do_content_authorities.json`의 현재·직전 문구 fingerprint를 함께 갱신했다.
기존 의미 경로와 의미 검토 revision은 보존하고, `copyReviewStatus`를
`nativeReviewRequired`로 분리해 Beyond Humanizer 적용을 사람의 문구 승인으로
오인하지 않게 했다.

## 보존한 데이터

- 어휘·문법·Cloze·Satz·발음·문화·관계·보조게임은 구조, 다국어 완전성, 금칙
  표현, 반복 진단을 통과했고 이번 감사에서 확정적 문구 결함이 새로 진단되지 않아
  cosmetic rewrite를 하지 않았다.
- Smalltalk의 `그렇군요 / Ach so. / I see.`와 안전 대체 질문 반복은 장면 본문이
  아니라 관계 안전 fallback metadata이므로 일괄 치환하지 않았다.
- ID, level, courseUnitId, conceptIds, 정답 index, 시나리오 순서, TTS용 대화
  `audioKo`는 바꾸지 않았다.

## 자동 검증 경계

자동 검증은 전수 범위, 스키마, Unicode, 번역 필드 완전성, exact-level 선택,
시나리오 연결과 회귀를 증명한다. 73,880개 문구 모두에 대한 원어민·한국어교육
전문가의 수동 승인까지 증명하지는 않는다. 해당 주장은 별도 사람 검수 뒤에만 할 수
있다. 실제 TTS 합성·Storage 업로드·Firebase 배포도 이 작업 범위가 아니다.

## 최종 작업 브랜치 검증

- Beyond Humanizer Unicode 및 금칙 표현 검사: 통과.
- 22개 런타임 파일 감사: 15,189개 레코드, 73,880개 텍스트 leaf, 누락·미분류·
  미해결 marker·부분 다국어 triplet 각각 0.
- `validate_content.py` 및 humanization overlay check: 통과.
- 콘텐츠 감사 단위 테스트: 8개 통과.
- Batch 10 장면·문법·오답 품질 테스트: 3개 통과.
- exact-level 및 핵심 loader Flutter 테스트: 100개 통과.
- 전체 `flutter analyze`: 문제 0.
- 전체 Flutter 테스트: 최초 4,430개 통과, 14개 skip, 3개 실패를 확인했다. 대시,
  Smalltalk fingerprint, Batch 10 라우팅 덮어쓰기의 세 원인을 모두 수정했고 관련
  집중 테스트 13개가 통과했다. 특히 127개 시나리오의 unit·concept·정답·audio
  계약을 복원한 뒤 `course_unit_balance_test`도 통과했다.
- 전체 content-factory 테스트: 199개 실행, 3 failures / 20 errors. 변경 전 clean
  `origin/main`의 4 failures / 20 errors보다 실패 하나가 줄었고, 나머지는 Batch 06,
  published-history, 오래된 review overlay, pack source, reference intake의 기존 부채다.
- TTS dry-run: 11,439개 dedup 발화, 149,257자. 인증·합성·로컬 write·upload는 0이며,
  변경된 audio 경로도 0건이다.

## 재현 명령

```powershell
python tools/content_factory/apply_content_humanization.py --check
python tools/content_factory/audit_content_text.py --check
python tools/content_factory/validate_content.py
python -m unittest discover -s tools/content_factory -p "test_audit_content_text.py" -v
python -m unittest tools.content_factory.test_level_content_4x.Batch10KoreanQualityTest -v
python tool/generate_tts.py --dry-run
```

통합 head의 최종 검증 및 GitHub Actions 결과는 세션 handoff에 기록한다.
