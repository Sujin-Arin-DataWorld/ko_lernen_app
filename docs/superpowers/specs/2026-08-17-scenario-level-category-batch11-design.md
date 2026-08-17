# Batch 11 시나리오 설계 — 레벨 6 × 카테고리 6

> **상태:** 설계 승인 완료(2026-08-17, Jin), 집필 전 스펙. review-only 초안만 만든다.
> **브랜치:** `claude/scenario-batch11-20260817` (워크트리)
> **기준 커밋:** `3fe6916e` (Batch 09/10 4× 승격이 반영된 origin/main)

## 1. 목적

젠지부터 3040까지 실제로 쓰는 여섯 생활축(일상·친구수다·데이트·유튜브·게임·덕질)에서
A1–C2 각 레벨에 **정확히 1개씩, 총 36개** 시나리오를 새로 쓴다. 레벨별·카테고리별
개수를 같게 두어 특정 레벨이나 소재로 몰리지 않게 한다.

## 2. 확정된 결정

| 항목 | 결정 |
| --- | --- |
| 총량 | 36개 = 6레벨 × 6카테고리 × 1 |
| 카테고리 | `daily`, `friends`, `dating`, `youtube`, `gaming`, `kpop` |
| 기존 미승인 초안 | **정정:** Batch 10은 `3fe6916e`로 **이미 live 승격**됐다. superseded 처리 불가. Batch 11은 순수 추가다 |
| 카테고리 노출 | 데이터 taxonomy만. `lib/` 코드·l10n·UI 변경 0 |
| 문장 품질 | `humanizer` 적용 + 36개 전문 육안 검수 |

## 3. 현재 재고 (기준 커밋 실측)

| 항목 | A1 | A2 | B1 | B2 | C1 | C2 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| live 시나리오 | 67 | 66 | 55 | 54 | 11 | 11 |
| live 문법 | 37 | 46 | 46 | 51 | 13 | 13 |
| course unit | 16 | 8 | 6 | 6 | 2 | 2 |
| can-do segment | 16 | 16 | 18 | 20 | 8 | 8 |

live 264개 중 취미·관계 소재는 `plans_with_friend`, `friend_birthday` 두 개뿐이다.
유튜브·게임·덕질·데이트 진행은 실제로 공백이며, 이 batch가 그 공백을 채운다.

레벨 총합 불균형(A1 67 : C1 11)은 이 batch로 해소되지 않는다. 36개를 균등 추가하면
A1 73 / C1 17이 된다. 총합 균형은 별도 트랙의 문제로 남기고, 이 batch 안에서의
균등만 계약으로 삼는다.

## 4. 카테고리 정의

| 키 | 이름 | 어휘·상황축 | 기본 관계 |
| --- | --- | --- | --- |
| `daily` | 일상 | 집·끼니·장보기·날씨·생활비·집안일 | 이웃·가족·서비스 |
| `friends` | 친구수다 | 약속·고민상담·모임 정산·잠수·뒷말 | 친구·동기 |
| `dating` | 데이트·연애 | 소개팅·썸·기념일·싸움과 화해·거리두기 | 썸·연인 |
| `youtube` | 유튜브·콘텐츠 | 알고리즘·쇼츠·구독·협업 제안·오정보 | 친구·크리에이터 |
| `gaming` | 게임 | 랭크·듀오·패치·현질·계정 제재 | 친구·팀원·고객센터 |
| `kpop` | 케이팝·덕질 | 최애·입덕·티켓팅·굿즈·팬덤 문화 | 팬·친구·운영진 |

## 5. 36칸 배치

각 칸은 **실존 course unit과 그 unit의 `requiredConceptIds`** 에만 붙는다.
`backdrop`은 기존 12개 key만 재사용한다.

### A1

| 카테고리 | courseUnitId | conceptIds | 상황 | 말투 | backdrop |
| --- | --- | --- | --- | --- | --- |
| daily | `a1_09_home_daily_life` | `concept_a1_home_daily` | 분리수거 날 이웃에게 요일 확인 | polite | home |
| friends | `a1_15_first_class_work` | `concept_a1_first_meeting` | 동기와 이름·전공 묻고 연락처 교환 | polite | cafe |
| dating | `a1_11_titles_relationships` | `concept_a1_titles_relationships` | 뭐라고 불러야 할지 정하기(이름/오빠/씨) | casual | cafe |
| youtube | `a1_12_daily_negation` | `concept_a1_negation` | 그 쇼츠 봤냐/안 봤다 말하기 | casual | home |
| gaming | `a1_04_order_request_object` | `concept_request_polite` | 같이 한 판 하자고 요청하기 | casual | home |
| kpop | `a1_02_self_intro_identity` | `concept_identity_polite` | 최애가 누구인지 소개하기 | polite | cafe |

### A2

| 카테고리 | courseUnitId | conceptIds | 상황 | 말투 | backdrop |
| --- | --- | --- | --- | --- | --- |
| daily | `a2_05_delivery_services` | `concept_a2_services` | 배달이 늦어 문의하고 대안 받기 | polite | convenience |
| friends | `a2_02_plans_proposals` | `concept_proposal_polite` | 주말 약속 시간·장소 조율 | casual | cafe |
| dating | `a2_04_feelings_health` | `concept_a2_feelings` | 답장이 느려 서운했다고 말하기 | casual | restaurant |
| youtube | `a2_03_chat_relationships` | `concept_a2_relationships` | 링크 보내며 왜 웃긴지 설명 | casual | home |
| gaming | `a2_07_travel_repair` | `concept_a2_travel_repair` | 접속이 안 돼 원인 찾아 해결 | casual | home |
| kpop | `a2_01_haeyo_transition` | `concept_action_polite` | 콘서트 줄에서 처음 본 팬과 해요체로 | polite | station |

### B1 — 유닛 6개에 카테고리 6개가 1:1

| 카테고리 | courseUnitId | conceptIds | 상황 | 말투 | backdrop |
| --- | --- | --- | --- | --- | --- |
| daily | `b1_06_life_capstone` | `concept_b1_life` | 자취 생활비 줄이려 계획 세우기 | casual | home |
| friends | `b1_02_indirect_speech` | `concept_b1_indirect_speech` | 친구가 한 말 전하며 오해 풀기 | casual | cafe |
| dating | `b1_04_relationships` | `concept_b1_relationships` | 기념일 기대치가 어긋난 뒤 대화 | intimate | restaurant |
| youtube | `b1_01_experience_reasons` | `concept_b1_reasons_experience` | 알고리즘에 빠져 밤새운 경험과 이유 | casual | home |
| gaming | `b1_03_work_softening` | `concept_b1_softening` | 팀 보이스에서 완곡하게 지적하기 | casual | home |
| kpop | `b1_05_complaint_resolution` | `concept_b1_complaint_resolution` | 굿즈 배송 누락 해결 요청 | polite | market |

### B2 — 유닛 6개에 카테고리 6개가 1:1

| 카테고리 | courseUnitId | conceptIds | 상황 | 말투 | backdrop |
| --- | --- | --- | --- | --- | --- |
| daily | `b2_03_precise_requests` | `concept_b2_precise_requests` | 층간 소음 재발 방지책을 정확히 요청 | polite | home |
| friends | `b2_02_professional_opinion` | `concept_b2_opinion` | 모임 회비 방식을 두고 근거 대며 논쟁 | casual | restaurant |
| dating | `b2_06_advanced_capstone` | `concept_b2_advanced` | 동거·거리 문제를 조건 걸어 협의 | intimate | home |
| youtube | `b2_01_formal_opening` | `concept_b2_formal_opening` | 크리에이터에게 협업 제안 첫 연락 | business | office |
| gaming | `b2_04_complaint_resolution` | `concept_b2_complaint` | 계정 제재에 공식 이의 제기 | business | office |
| kpop | `b2_05_interview` | `concept_b2_interview` | 팬 커뮤니티 운영진 지원 인터뷰 | business | office |

### C1 — 유닛 2개에 3개씩. 소재를 담론 층위로 올린다

| 카테고리 | courseUnitId | conceptIds | 상황 | 말투 | backdrop |
| --- | --- | --- | --- | --- | --- |
| daily | `c1_01_evidence_public_reasoning` | `concept_c1_evidence_reasoning` | 생활 물가 체감과 통계의 간극 설명 | business | office |
| youtube | `c1_01_evidence_public_reasoning` | `concept_c1_evidence_reasoning` | 조회수 높은 건강 정보의 근거 한계 | business | office |
| gaming | `c1_01_evidence_public_reasoning` | `concept_c1_evidence_reasoning` | 청소년 이용시간 자료로 규제 논의 | business | office |
| friends | `c1_02_inclusive_sustainable_systems` | `concept_c1_inclusive_systems` | 모임 장소 접근성 문제 제기 | business | cafe |
| dating | `c1_02_inclusive_sustainable_systems` | `concept_c1_inclusive_systems` | 데이팅앱 안전·차별 신고 절차 설계 | business | office |
| kpop | `c1_02_inclusive_sustainable_systems` | `concept_c1_inclusive_systems` | 팬덤 노동과 지속 가능한 응원 문화 | business | office |

### C2 — 유닛 2개에 3개씩

| 카테고리 | courseUnitId | conceptIds | 상황 | 말투 | backdrop |
| --- | --- | --- | --- | --- | --- |
| youtube | `c2_02_technology_public_ethics` | `concept_c2_accountable_systems` | 추천 알고리즘의 책임 소재 따지기 | business | office |
| gaming | `c2_02_technology_public_ethics` | `concept_c2_accountable_systems` | 확률형 아이템 자동 제재의 책임 | business | office |
| daily | `c2_02_technology_public_ethics` | `concept_c2_accountable_systems` | 생활 자동화 오작동의 구제 절차 | business | office |
| friends | `c2_01_interpretation_institutions` | `concept_c2_discourse_institutions` | 사적 대화가 공적으로 인용될 때 | business | cafe |
| dating | `c2_01_interpretation_institutions` | `concept_c2_discourse_institutions` | 연애 서사가 만드는 관점의 편향 | business | office |
| kpop | `c2_01_interpretation_institutions` | `concept_c2_discourse_institutions` | 팬덤 언어와 담론 권력 | business | office |

## 6. 레벨 계약

| 레벨 | 허용 문법 상한 | 말투 | 신조어 정책 |
| --- | --- | --- | --- |
| A1 | 조사, `-아/어요`, `-았/었어요`, 안/못, `-고 싶다`, `-(으)세요`, 관형형 | 해요체 위주 | `최애`·`쇼츠`까지. 반드시 `vocab.note`로 뜻 제공 |
| A2 | `-(으)ㄹ 거예요`, `-(으)면`, `-아/어서`, `-(으)ㄹ 수 있다`, `-(으)ㄴ/는 것 같다`, 불규칙 | 해요체↔반말 | `입덕`·`듀오`·`현질` |
| B1 | `-는데`, `-거든요`, `-(ㄴ/는)다고 하다`, `-(으)ㄹ수록`, `-았/었으면 좋겠다`, `-(으)ㄴ/는 편이다` | 반말 수다 + 완곡 | `트롤`·`잠수`·`정산` |
| B2 | `-더라도`, `-는 반면에`, `-(으)ㄹ까 봐`, `-대요/-냬요/-재요`, `-는 바람에`, `-다고 해서 -는 것은 아니다` | business/polite | 커뮤니티 용어는 설명과 함께 |
| C1 | `-지 않는 한`, `-(으)ㄹ 여지가 있다`, `-을/를 감안하면`, `-(으)ㄴ/는 한편`, `-라는 점에서` | business | 담론 용어 위주, 은어 최소 |
| C2 | `-을/를 불문하고`, `-(으)ㄴ/는다고 치더라도`, `-기에 망정이지`, `-와/과 무관하게`, `-을/를 전제로` | business | 은어는 메타적 인용만 |

`grammarIds`는 각 칸마다 해당 레벨 live `grammar.csv`에서 1–2개만 고른다. 없는 ID를
만들지 않고, 문법을 새로 추가하지도 않는다.

## 7. 시나리오 1개의 계약

- `dialog` 8턴. 각 턴 `{speaker, ko, de, en}` 전부 nonempty. `speaker`는 `user`와
  sidekick 코드가 교대한다.
- `quests` 5개: `hoerverstehen` 1 + `uebersetzen` 1 + (`luecken` 또는 `particlePop`) 1
  + `satzBauen` 1 + `diktat` 1. 각 quest에 안정 `id`와 `conceptIds`를 둔다.
- `vocab` 6개 이상. 신조어·커뮤니티 용어에는 `note{ko,de,en}`를 붙인다.
- `grammarBlock.title`·`explanation` 삼언어 필수. `intro`·`title`도 삼언어.
- `culturalNote`는 한국 특수 맥락이 있는 칸에만 둔다(티켓팅·회비 정산·호칭 등).
- `register`/`speechStyle`은 `polite`/`casual`/`business`/`intimate`만. legacy `formal` 금지.
- `sidekick`은 `jieun` 또는 `minsu`. 새 코드를 만들지 않는다.
- `xpReward`는 같은 레벨 live 범위 안: A1 110–160, A2 130–160, B1 150–180,
  B2 160–200, C1 160–205, C2 160–220.
- `surfaceFormIds`는 실제 존재하는 값이 없으면 빈 배열로 둔다.

### ID 규칙

| 대상 | 패턴 | 예 |
| --- | --- | --- |
| scenario | `<level>_<category>_<slug>` | `b1_gaming_team_voice` |
| quest | `quest_<level>_<category>_<slug>_<hear\|tr\|gap\|build\|dict>` | `quest_b1_gaming_team_voice_hear` |

live 264개 scenario ID와 모든 live quest ID에 대해 충돌 검사를 통과해야 한다.

## 8. 산출물

```
tools/content_factory/data/batch_11_scene_scripts.py    36개 장면 원문(사람이 쓴 KO/DE/EN)
tools/content_factory/build_batch_11_scenarios.py       schema 조립 + 자체 검사
tools/content_factory/drafts/c1_batch11_scenarios_a1_c2.json
tools/content_factory/drafts/batch_11_manifest.json     status: review_only_draft
tools/content_factory/review/c1_batch11_scenarios.csv   36행, 상태=draft
docs/SESSION_LOG.md                                     최상단 기록
```

Batch 10 관용구(`data/batch_10_scene_scripts.py` + 빌더)를 그대로 따른다. 장면 원문은
사람이 읽고 고칠 수 있는 파이썬 리터럴로 두고, 빌더가 스키마를 조립한다.

manifest `provenance.scope`에는 독립적으로 정한 학습 목적만 쓰고, `field_notes`에
`rights: original`을 남긴다. 외부 교재·PDF의 문장·단원·배열은 쓰지 않는다.

## 9. 검증과 금지

**돌린다**

```bash
python tools/content_factory/build_batch_11_scenarios.py
python tools/content_factory/test_build_batch_11_scenarios.py -v
python tools/content_factory/integrate_scenario_batch.py --manifest tools/content_factory/drafts/batch_11_manifest.json
python tools/content_factory/render_review_packet.py --manifest tools/content_factory/drafts/batch_11_manifest.json --output tools/content_factory/review/batch_11_review_packet.md
python tools/content_factory/validate_content.py
```

시나리오 초안의 정본 검증기는 `integrate_scenario_batch.py`의 **preview 모드**(`--apply` 없이)다.
`validate_review_batch.py`에는 scenario 처리가 없으므로 쓰지 않는다. mac에서는 `python3`을 쓴다.

**하지 않는다**

- `--apply`, `assets/data/` 수정, `curriculum_manifest.json` 편집
- TTS 합성, Firebase Storage 업로드
- `lib/` 코드 변경 (backdrop map 등록은 승인 병합 시 `integrate_scenario_batch.py`가 처리)
- `git commit`/`push` (Jin의 명시 요청 시에만)

## 10. 품질 게이트

수량·ID·스키마 검사만으로 끝내지 않는다. 36개 전문을 읽고 다음을 확인한다.

1. `intent`가 서로 다르고 `confirm_*` 같은 획일 패턴이 아니다.
2. 대화가 셸 문구(`알겠습니다. 지금 바로 확인하겠습니다.` 류)로 채워지지 않았다.
3. KO 원문과 DE/EN이 같은 정보량·같은 존대·같은 화행을 전달한다.
4. 젠지 소재가 교과서투로 굳지 않았고, 레벨 문법 상한을 넘지 않았다.
5. 한 시나리오 안에서 같은 문장이 화자만 바꿔 반복되지 않는다.
6. `humanizer` 기준의 AI 티(과장 수식, 3항 나열, 수동태 남용)가 DE/EN에 없다.

## 11. 위험

| 위험 | 대응 |
| --- | --- |
| C1/C2 유닛이 2개뿐 | 소재를 그 유닛 담론으로 올려 6개를 3+3으로 붙인다. 새 유닛·segment를 만들지 않는다 |
| 병행 세션(`claude/batch10-dialog-lines-20260817` 등)이 시나리오 데이터를 만진다 | live asset을 건드리지 않고 새 파일만 추가해 충돌면을 없앤다 |
| live Batch 10 대화에 KO↔DE/EN 등가가 약한 줄이 있다 | 이 batch 범위 밖. 별도 트랙으로 남긴다 |
| 레벨 총합 불균형 잔존 | 이 batch는 자체 균등만 보장. 총합 조정은 후속 결정 |
