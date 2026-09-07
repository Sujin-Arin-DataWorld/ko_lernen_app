# F8 — 검수 체크리스트 · Jin 표본 절차

> 손수 작성(T1.4). 절차의 정본은 plan §4.5(3단 검수)·§5(감독 루프)·D-4(승인 게이트).

## 판정 3항목 (plan §5)

새 콘텐츠·재분류 결과를 직독할 때 아래 3항목만 판정한다 — 그 외 기준(맞춤법,
헤더, ID 형식 등)은 자동 게이트(`validate_content.py`, `audit_content_levels.py`,
`audit_content_naturalness.py`)가 담당한다.

1. **한국인이 봐도 자연스러운가.** 교과서투·번역투(`~에 대해` 남발, 이중 피동,
   `것이다` 남발) 없이, 그 관계·상황에서 실제로 쓰는 문장인가(plan §3.D).
2. **DE·EN이 같은 사건인가.** 세 언어가 같은 의미·화행·존대·정보량을 각자
   자연스럽게 표현하는가(직역 대조가 아니라 역번역 확인). 정답 누설이 없는가.
3. **레벨 안인가.** 문법·어휘가 §B(레벨 프로필)·§C(판정 절차)의 등급을 넘지
   않는가(문화어 1개 예외). "문장만 길게" 만들어 상위 레벨처럼 위장하지 않았는가.

## 3단 검수 파이프라인 (plan §4.5)

1. **자동 게이트** — `plan_pack_assignments.py`(프리플라이트) →
   `validate_review_batch.py --manifest` → `audit_content_levels.py --draft`
   (위반 0) → `audit_content_naturalness.py`(마커 0) →
   `test/learner_copy_scan_test.dart` 패턴 검사.
2. **Sonnet 심사관 2명** — J-KO(자연성·레벨·조사·어미), J-DE·EN(역번역·du/Sie·
   정답 누설). 반려 시 수정 루프(같은 사유 2회 반려 → 브리프 재작성, 5회
   초과 → 태스크 분할, plan Global Constraints).
3. **Fable 직독** — A1은 전수, A2는 30% 층화, 재분류(§3.E) 번들 목록은
   100%. 위 3항목만 판정. 반려 사유는 항목별로 "대상 ID/줄 · 문제 · 이유 ·
   고친 예"로 적어 `F10_review_lessons.md`에 누적한다.

## Jin 10% 표본 절차 (D-4)

- Fable 승인 후 `render_review_packet.py`로 레벨별 10% 무작위 표본 패킷을
  만든다(`docs/data/review_packets/batch_<n>_jin_sample.md`).
- Jin이 표본을 보고 ok/반려를 표시한다. 반려 항목이 있으면 해당 항목만
  Sonnet이 재작업 → Fable 재검사 → 표본 재발췌(그 항목만).
- 심사관(Sonnet 2명) 반려율이 2회 연속 <5%면 다음 배치부터 Jin 표본을
  10% → 50%로 올리지 않고 그대로 10% 유지(현재 정본, plan §5 "심사관
  반려율 2회 연속 <5%면 표본 50%"는 **Fable 직독 표본**(A2)에 적용되는
  규칙이며 Jin 표본 비율(10%)과는 별개 — 혼동 방지를 위해 명시).

## 증거 패키지 (Fable 판정용, R6 방지)

각 배치 리뷰 요청에는 다음 7항목이 있어야 한다(plan §5 브리프 템플릿
"REPORT" 절과 동일):

1. 변경/생성 파일 목록(경로)
2. diff 요약 또는 신규 레코드 수
3. 테스트 명령 + 실행 결과 원문(verbatim tail)
4. `flutter analyze` 또는 해당 파이썬 정적 검사 결과
5. `validate_content.py --json` / `audit_content_levels.py` 출력(이슈 0 또는
   래칫 CAP 이내)
6. 남은 경고·미해결 항목
7. 질문(Fable 룰링이 필요한 판단 지점)

## 반려 코드 (plan §5)

R1 테스트 없음 · R2 계약 위반(ID·수량·헤더) · R3 레벨 위반 · R4 자연성/번역
결함 · R5 범위 초과 · R6 증거 누락 · R7 템플릿 흔적 · R8 후속 4종 누락 ·
R9 Dart 맵 미동기 · R10 CI 미확인.
