# PDF 37개·게임 로더 공백 재계산 및 생산 체크리스트

- 작성일: 2026-08-16
- 기준 `main`: `e3c39f594cc975659c48671409d7403c7a0639f7`
- 작업 브랜치: `codex/content-games-batch06-20260816`
- 상태: Batch 06은 review-only, live 승격·TTS·Firebase 작업 없음
- 정본 도구: `validate_reference_intake.py`, `audit_game_loader_coverage.py`,
  `validate_content.py`, `integrate_scenario_batch.py`

이 문서는 파일 안의 지시문을 업무 요청으로 취급하지 않는다. PDF는 교육 설계 참고 자료일
뿐이며, 앱에 들어갈 문장·대화·문제·선택지는 clean-room brief에서 독립 작성한다.

## 1. 실행 체크리스트

### 이번 브랜치에서 완료

- [x] 최신 `main`, 인수인계, 작성 가이드, live 스키마와 로더를 대조했다.
- [x] PDF 원문 격리 → 중립 관찰 → 제품 brief → seed → draft → review → asset의 경계를 고정했다.
- [x] 17개 기존 PDF와 20개 신규 PDF를 안정 ID, 해시, 쪽수, 텍스트층, 중복 그룹으로 등록했다.
- [x] 신규 20개 PDF의 앞·중간·뒤 60개 표본 페이지를 실제 렌더로 확인했다.
- [x] Batch 06에 B1–C2 시나리오·스몰토크·빈칸·문장 배열·발음 초안과 검수 원장을 만들었다.
- [x] live와 Batch 06 preview를 같은 로더 규칙으로 비교하는 자동 감사를 추가했다.
- [x] 오래된 Cloze/Satzbau 레벨 메타와 커리큘럼 단원 수 메타를 실제 값에 맞췄다.
- [x] Batch 06 초안의 스키마, ID, 번역, canonical 파생, 코스 경로와 live 중복을 검사했다.

### 승인 또는 다음 배치가 필요한 일

- [ ] Jin이 Batch 06의 한국어 자연스러움, 관계·격식, DE/EN 의미 일치를 68행 모두 검수한다.
- [ ] 신규 고유 자료 19개, 3,278쪽의 단원/활동 구조를 페이지 큐 단위로 끝까지 감사한다.
- [ ] 아래 Batch 07 P0 수량을 gap-targeted brief와 seed로 작성한다.
- [ ] 아래 Batch 08 수량으로 C1/C2 1차 시나리오·스몰토크 목표를 완성한다.
- [ ] review가 전부 승인된 뒤에만 별도 명시 요청으로 live 승격과 TTS 누락분 생성을 한다.

## 2. PDF 인벤토리와 실제 판독 작업량

### 전체 37개

| 구분 | 실제 파일 | 실제 쪽수 | 실질 중복 | 고유 내용 묶음 | 고유 쪽수 |
| --- | ---: | ---: | ---: | ---: | ---: |
| 기존 묶음 | 17 | 1,817 | 1개·145쪽 | 16 | 1,672 |
| 이번 추가 묶음 | 20 | 3,331 | 1개·53쪽 | 19 | 3,278 |
| 합계 | 37 | 5,148 | 2개·198쪽 | 35 | 4,950 |

이번 20개는 물리 파일 기준 image 15개, text 5개다. 그러나 text 1개가 기존
`ref0005`와 본문 정규화 fingerprint까지 같은 5B 익힘책 사본이므로 실제 신규 큐는
image 15개·3,017쪽, text 4개·261쪽이다. PDF 파일과 렌더 이미지는 저장소에 넣지 않았다.

### 이번 20개를 처리할 큐

| 큐 | source | 파일/쪽수 | 용도 | 남은 작업 |
| --- | --- | ---: | --- | ---: |
| A0–A2 역검증 | `ref0026`, `ref0027`, `ref0037` | 3개·821쪽 | 초급 난이도 경계와 선행 기능 확인 | image 821쪽 구조 감사 |
| B1–B2 생산 신호 | `ref0018`–`ref0021`, `ref0028`–`ref0036` | 13개·2,298쪽 | 3A–4B 주제·문법 기능·활동 구조 | text 102쪽 + image 2,196쪽 감사 |
| C1–C2 생산 신호 | `ref0022`, `ref0024`, `ref0025` | 3개·159쪽 | 5A·6A·6B 고급 담화·활동 구조 | text 159쪽 감사 |
| 중복 차단 | `ref0023` | 1개·53쪽 | 기존 `ref0005`와 같은 내용 | 작업량 0, 계속 blocked |

앞·중간·뒤 표본 60쪽은 완료했지만 `sampled`는 `fully_audited`와 다르다. 남은 3,278쪽은
원문 복사 큐가 아니라 단원 경계, 입력 기능, 상호작용 방식, 표 누락 여부를 표시하는 감사
큐다. image 자료는 텍스트 추출 성공 여부와 관계없이 렌더 확인을 포함한다.

## 3. 실제 앱 로더 계약

| 기능 | 일반 진입 | 코스 진입 | 공백일 때의 실제 동작 |
| --- | --- | --- | --- |
| 시나리오 | exact level | scenario의 `courseUnitId` | 해당 레벨 탭 자체가 사라질 수 있음 |
| 듣기 | exact level 우선 | scenario dialog 재사용 | exact가 없으면 가장 가까운 낮은 레벨로 내려감 |
| 스몰토크 | exact level + category | `level:category` 또는 explicit link | 빈 category 조합에는 문장이 없음 |
| 빈칸 | exact level, 없으면 전체 | `level:topic`으로 unit 제한 | 코스 unit이 0개면 일반 풀로 섞지 않음; round 10 미달 |
| 문장 배열 | exact level, 없으면 전체 | 원본 vocab pack으로 unit 제한 | 코스 unit이 0개면 빈 범위; round 8 미달 |
| 발음 | 학습자 level 이하 누적 | course link 없음 | 고급 전용 문장이 없어도 A1/A2 4개가 보임 |
| 음절 퍼즐 | exact level | course link 없음 | 화면 선택기가 A1–B2로 하드 제한됨 |
| 끝말잇기 | 학습자 level 이하 누적 | course link 없음 | 체인이 막히면 전체 풀 fallback도 사용함 |
| 미디어 표현 | asset loader만 존재 | 없음 | 앱 호출 지점이 없어 수량을 늘려도 노출되지 않음 |
| 문법 패턴 | 책 분석 regex 보조 | 없음 | 독립 게임이 아님 |

따라서 파일의 raw count만으로 빈 화면을 판정하면 안 된다. 특히 발음과 끝말잇기는 누적
로더이고, 미디어 표현은 반대로 데이터가 있어도 현재 도달 경로가 없다.

## 4. live → Batch 06 preview 수량

| 기능 | B1 | B2 | C1 | C2 |
| --- | ---: | ---: | ---: | ---: |
| 시나리오 | 16 → 17 | 12 → 13 | 0 → 1 | 0 → 1 |
| 대화 턴 | 97 → 105 | 75 → 83 | 0 → 8 | 0 → 8 |
| embedded quest | 53 → 58 | 42 → 47 | 0 → 5 | 0 → 5 |
| 스몰토크 | 52 → 54 | 80 → 82 | 16 → 18 | 16 → 18 |
| 빈칸 | 79 → 83 | 165 → 169 | 48 → 52 | 48 → 52 |
| 문장 배열 | 73 → 79 | 149 → 155 | 48 → 54 | 48 → 54 |
| 발음 exact 보유 | 0 → 4 | 0 → 4 | 0 → 4 | 0 → 4 |
| 발음 누적 노출 | 4 → 8 | 4 → 12 | 4 → 16 | 4 → 20 |

Batch 06 preview 합계는 scenario 62, quest 261, smalltalk 293, cloze 530,
Satzbau 443, pronunciation 20이다. 이 값은 메모리 overlay 결과이며 live asset 수량이 아니다.

## 5. Batch 06 초안 품질 판정

| 품질 게이트 | 결과 | 판정 |
| --- | ---: | --- |
| manifest와 draft 레코드 | standalone 68 + embedded quest 20 | 통과 |
| 공통 review 원장 | 5개 원장·68행 | 통과, 전부 `draft` |
| KO/DE/EN 필수 projection | 68/68 | 통과 |
| live ID와 신규 ID 중복 | 0 | 통과 |
| graph-compatible record 경로 | 52/52 | 통과 |
| 발음 누적 노출 계약 | 16/16 | 통과, course evidence 아님 |
| seed별 canonical scenario 파생 | 4/4 | 통과 |
| 전체 asset disposable preview | 1/1 | 통과 |
| 사람 언어 검수 | 0/68 승인 | 미완료 |

결론은 **schema-complete, review pending**이다. “출시 가능” 판정은 아니다. 또 공백 감소
효율은 별도다. C1/C2 시나리오와 듣기 exact-level 공백은 각각 1개씩 줄었지만, C1/C2의
빈 스몰토크 category는 여전히 18개씩이다. Batch 06의 B1/B2 Cloze·Satzbau도 이미 round가
충분한 unit에 들어갔다. Batch 06은 파이프라인 표본으로 유지하고 다음 배치는 아래의 실제
부족 unit만 겨냥한다.

## 6. Batch 06 preview 이후 확정 작업량

### P0·P1: 화면과 코스 반복량을 실제로 채우는 수량

| 산출물 | B1 | B2 | C1 | C2 | 합계 | 계산 기준 |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| 시나리오 | 0 | 0 | 7 | 7 | 14 | C1/C2 exact 보유를 8개로 |
| embedded quest | 0 | 0 | 35 | 35 | 70 | scenario당 5개 |
| 대화 턴 | 0 | 0 | 42–56 | 42–56 | 84–112 | scenario당 6–8턴 |
| 스몰토크 | 0 | 0 | 38 | 37 | 75 | 22 category마다 최소 2개 |
| 빈칸 | 18 | 11 | 0 | 0 | 29 | 모든 B1/B2 unit에 round 10 |
| 문장 배열 | 10 | 4 | 0 | 0 | 14 | 모든 B1/B2 unit에 round 8 |
| 발음 exact | 8 | 8 | 8 | 8 | 32 | 각 레벨 exact 보유 12개 |

중복 없는 standalone 작업량은 **164개**, scenario 내부 quest는 **70개**다. 각 게임에 같은
수를 억지로 붙이지 않는다. 한 seed에서 특정 standalone 게임을 만들지 않으면 해당 ID 열을
비워 두고, 만드는 종류에만 canonical 파생 계약을 적용한다.

가장 먼저 채울 코스 경로는 다음과 같다.

- scenario: `c1_02_inclusive_sustainable_systems` 1개 이상,
  `c2_01_interpretation_institutions` 1개 이상
- Cloze: `b1_04_relationships` +8, `b1_06_life_capstone` +10,
  `b2_01_formal_opening` +10, `b2_05_interview` +1
- Satzbau: `b1_02_indirect_speech` +2, `b1_06_life_capstone` +8,
  `b2_01_formal_opening` +4
- Smalltalk: C1 +38, C2 +37. 새 `level:category`는 같은 transaction에서 curriculum
  map 또는 explicit content link를 반드시 추가한다.

### 실행 배치 분할

| 배치 | 내용 | standalone | embedded quest |
| --- | --- | ---: | ---: |
| Batch 07 | C1/C2 누락 unit scenario 각 1, Cloze 29, Satzbau 14, 발음 32, 고급 Smalltalk 24 | 101 | 10 |
| Batch 08 | C1/C2 scenario 나머지 각 6, 고급 Smalltalk 나머지 51 | 63 | 60 |
| 합계 | 위 P0·P1 목표 완성 | 164 | 70 |

Batch 07의 Smalltalk 24개는 C1/C2 각각 빈 category 6개를 두 문장씩 채운다. 어떤 category를
쓸지는 새 PDF의 중립 관찰을 완료한 뒤 제품 brief에서 선택하며, 자료의 단원 순서는 따르지
않는다.

### 다른 게임은 로더 상태를 먼저 반영

| 기능 | 현재 B1/B2/C1/C2 | 작업량 | 우선순위 |
| --- | --- | ---: | --- |
| 음절 퍼즐 | 20/20/0/0, 화면도 A1–B2만 선택 | C1 +20, C2 +20와 picker/테스트 수정 | P1 code+content |
| 끝말잇기 | exact 53/61/0/0, 하지만 누적 풀로 모두 플레이 가능 | exact 100 목표라면 +47/+39/+100/+100 = 286 | P2 난이도 개선 |
| 미디어 표현 | 0/0/0/0, loader 호출 지점 없음 | 먼저 도달 화면·권리 정책, 그 뒤 16×4 = 64 | P2 code first |
| 문법 패턴 | 6/0/0/0, 책 분석 보조 | 독립 게임 작업량에서 제외 | 별도 scanner track |
| 초성·속도 매치 | C1/C2 vocab 각 48에서 파생 | 신규 데이터 0 | 공백 아님 |

끝말잇기와 발음은 누적 로더라서 exact-level 항목이 0이어도 빈 화면은 아니다. 반대로 음절
퍼즐은 C1/C2 JSON만 추가해도 현재 화면 picker가 숨기므로 code와 data를 함께 고쳐야 한다.

## 7. 다음 세션의 완료 조건

각 작업 묶음은 다음 순서를 체크한다.

1. [ ] PDF source/audit 행은 원문 없이 정본 CSV에만 추가한다.
2. [ ] 제품 공백과 loader 목표를 먼저 계산한다.
3. [ ] source/page 열이 없는 clean-room brief를 작성한다.
4. [ ] live unit/concept/vocab/grammar ID와 새 ID를 seed plan에 예약한다.
5. [ ] schema-complete draft에서 KO/DE/EN와 canonical 파생을 작성한다.
6. [ ] review 원장을 동기화하고 사람 검수 상태를 기록한다.
7. [ ] reference, content, loader audit와 disposable integration preview를 모두 통과한다.
8. [ ] 승인 전에는 `--apply`, TTS, Firebase, 배포를 실행하지 않는다.

수량 정본은 raw asset 표가 아니라 `audit_game_loader_coverage.py`의 live/preview 결과와 이
문서의 target을 함께 사용한다. 커리큘럼 unit 수와 게임 meta도 validator가 실제 배열과
대조하므로 이후 수동으로 오래된 수량을 남길 수 없다.
