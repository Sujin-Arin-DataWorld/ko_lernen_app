# PR-L2a T2.2 -- 번들 이동 목록 (초안)

> 생성: Sonnet 분석 스크립트(수작업 아님) -- 입력 `tool/content_level_suspects.csv`, `tool/content_level_summary.json`, `tool/audit_content_levels.py`(직접 import해 전체 `pack_stats` 재계산 -- 마크다운 리포트의 A1/A2 팩 순위표는 `_top_packs_section`이 레벨을 a1/a2로 필터링해 b1+ 팩은 애초에 안 보임), `tools/content_factory/shelf_assignment.py`, `assets/data/curriculum_manifest.json`, `assets/data/korean_vocab.csv`, `cloze.json`, `satz_sentences.json`, `smalltalk.json`, `assets/data/can_do_content_authorities.json`, batch manifests(07_4x/09_4x/07_partner_family/20).
> 계획: `C:\Users\vjinn\.claude\plans\c-users-vjinn-elibrary-downloads-1-1-pd-cheeky-eclipse.md` §4.3(JSON 형태), §14.2(선반 배정 원칙). 룰링: 브리프 R-A/R-B/R-C/R-D.

이동 목록 JSON: `tools/content_factory/relevel/relevel_bundle_L2a.json` (17건, `batch="L2a"`).

## 이동 목록 (17건: R-C 고정 룰링 16 + auditor_added 1)

| pack | from→to | newPackId | unit | shelf | n words | cloze n | satz n | smalltalk n | scenario_candidates | cando refs | reason |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `a1_neighbors_hall_1` | a1→b1 | `b1_neighbors_hall_1` | `b1_06_life_capstone` | `b1_neighbor` | 12 | 12 | 12 | 0 | none | 1 | median Δ=2.5, share=80%, n_hm=10 |
| `a1_partner_chuseok_basic_1` | a1→a2 | `a2_partner_chuseok_basic_1` | `a2_03_chat_relationships` | `a2_partner` | 12 | 12 | 12 | 0 | none | 1 | median Δ=1, share=43%, n_hm=7 |
| `a1_partner_first_gift_1` | a1→b1 | `b1_partner_first_gift_1` | `b1_04_relationships` | `b1_partner` | 12 | 12 | 12 | 0 | none | 1 | median Δ=2.5, share=60%, n_hm=10 |
| `a1_partner_house_entry_1` | a1→a2 | `a2_partner_house_entry_1` | `a2_03_chat_relationships` | `a2_partner` | 12 | 12 | 12 | 0 | none | 1 | median Δ=1, share=44%, n_hm=9 |
| `a1_partner_photo_thanks_1` | a1→a2 | `a2_partner_photo_thanks_1` | `a2_03_chat_relationships` | `a2_partner` | 12 | 12 | 12 | 0 | none | 1 | median Δ=1.5, share=50%, n_hm=8 |
| `a1_partner_siblings_hello_1` | a1→b1 | `b1_partner_siblings_hello_1` | `b1_04_relationships` | `b1_partner` | 12 | 12 | 12 | 0 | none | 1 | median Δ=2, share=71%, n_hm=7 |
| `a1_pharmacy_ask_1` | a1→a2 | `a2_pharmacy_ask_1` | `a2_04_feelings_health` | `a2_body` | 12 | 12 | 12 | 0 | none | 1 | median Δ=2, share=100%, n_hm=7 (raw target b1 capped to a2) |
| `a1_school_supplies_1` | a1→a2 | `a2_school_supplies_1` | `a2_06_study_work` | `a2_enrolment` | 12 | 12 | 12 | 0 | none | 1 | median Δ=1, share=44%, n_hm=9 |
| `a1_subway_card_1` | a1→a2 | `a2_subway_card_1` | `a2_07_travel_repair` | `a2_move` | 12 | 12 | 12 | 0 | none | 1 | median Δ=2, share=67%, n_hm=9 (raw target b1 capped to a2) |
| `a1_weather_layer_1` | a1→a2 | `a2_weather_layer_1` | `a2_04_feelings_health` | `a2_friends` | 12 | 12 | 12 | 0 | none | 1 | median Δ=2, share=64%, n_hm=11 (raw target b1 capped to a2) |
| `a2_bank_counter_1` | a2→b1 | `b1_bank_counter_1` | `b1_05_complaint_resolution` | `b1_bill` | 12 | 12 | 12 | 0 | none | 1 | median Δ=2, share=80%, n_hm=10 (raw target b2 capped to b1) |
| `a2_housing_search_2026_1` | a2→b1 | `b1_housing_search_2026_1` | `b1_05_complaint_resolution` | `b1_form` | 12 | 6 | 6 | 0 | none | 1 | median Δ=3, share=62%, n_hm=8 (raw target c1 capped to b1) |
| `a2_part_time_1` | a2→b1 | `b1_part_time_1` | `b1_03_work_softening` | `b1_team` | 12 | 12 | 12 | 0 | none | 1 | median Δ=2.5, share=83%, n_hm=6 (raw target b2 capped to b1) |
| `a2_partner_banmal_switch_1` | a2→b1 | `b1_partner_banmal_switch_1` | `b1_04_relationships` | `b1_partner` | 12 | 12 | 12 | 0 | none | 1 | median Δ=3, share=73%, n_hm=11 (raw target c1 capped to b1) |
| `a2_partner_sibling_tease_1` | a2→b1 | `b1_partner_sibling_tease_1` | `b1_04_relationships` | `b1_partner` | 12 | 12 | 12 | 0 | none | 1 | median Δ=2, share=55%, n_hm=11 (raw target b2 capped to b1) |
| `a2_phone_plan_1` | a2→b1 | `b1_phone_plan_1` | `b1_05_complaint_resolution` | `b1_bill` | 12 | 12 | 12 | 0 | none | 1 | median Δ=3, share=83%, n_hm=6 (raw target c1 capped to b1) |
| `b1_public_office_1` | b1→b2 | `b2_public_office_1` | `b2_04_complaint_resolution` | `b2_authorities` | 12 | 12 | 12 | 0 | none | 1 | median Δ=2, share=56%, n_hm=9 (raw target c1 capped to b2) -- auditor_added, flag for Fable review |

범례: cloze n/satz n = R-D `auto` 규칙(같은 pack의 현재 레벨 `example_korean`/단어와 `fullKo`/`vocabKo`가 일치하는 행 수)으로 자동 매칭되는 행 수. smalltalk n = 0(4개 배치 manifest의 `vocabPacks`·`contentLinks`·`smalltalkCategoryMappings`를 모두 확인했으나 이 17개 팩을 개별 smalltalk id에 연결한 항목이 없음 -- 스몰토크는 카테고리→유닛 단위로만 연결돼 있어 R-D대로 빈 리스트). scenario_candidates = 현재 레벨 샤드(scenarios_<from>.json) 안에서 courseUnitId가 새 unit과 이미 일치하는 시나리오 중 대사에 그 팩 단어 ≥3개가 나타나는 것(전부 0건 -- 아래 공개 질문 참고). cando refs = `can_do_content_authorities.json`의 `contentReferences`에서 `kind="vocabPack", id=<pack_id>` 자기 등록 1건뿐(이동될 cloze/satz id는 이 레지스트리에 하나도 걸려 있지 않음 -- 확인함).

### 팩별 현재(이동 전) 유닛 -- 참고용

`can_do_content_authorities.json`(`kind="vocabPack"`)과 `curriculum_manifest.json` `vocabPackUnitMap`(키는 트레일링 `_1` 없는 베이스 이름)이 정확히 일치해 교차 확인함.

| pack | current courseUnitId |
|---|---|
| `a1_neighbors_hall_1` | `a1_11_titles_relationships` |
| `a1_partner_chuseok_basic_1` | `a1_11_titles_relationships` |
| `a1_partner_first_gift_1` | `a1_11_titles_relationships` |
| `a1_partner_house_entry_1` | `a1_11_titles_relationships` |
| `a1_partner_photo_thanks_1` | `a1_11_titles_relationships` |
| `a1_partner_siblings_hello_1` | `a1_11_titles_relationships` |
| `a1_pharmacy_ask_1` | `a1_10_health_safety` |
| `a1_school_supplies_1` | `a1_15_first_class_work` |
| `a1_subway_card_1` | `a1_06_transport_directions` |
| `a1_weather_layer_1` | `a1_09_home_daily_life` |
| `a2_bank_counter_1` | `a2_08_home_money` |
| `a2_housing_search_2026_1` | `a2_08_home_money` |
| `a2_part_time_1` | `a2_06_study_work` |
| `a2_partner_banmal_switch_1` | `a2_03_chat_relationships` |
| `a2_partner_sibling_tease_1` | `a2_03_chat_relationships` |
| `a2_phone_plan_1` | `a2_05_delivery_services` |
| `b1_public_office_1` | `b1_05_complaint_resolution` |

### 레벨 이동 폭(raw vs 최종)

R-A 공식(`current + round-half-down(median Δ)`)의 raw 목표와 R-C 최종 룰링(선반 유무로 하향)이 다른 항목만 표시. 나머지 10건은 raw == 최종.

| pack | median Δ | raw target | final (R-C) | capped by |
|---|---|---|---|---|
| `a1_pharmacy_ask_1` | 2 | b1 | a2 | 1 level(s) |
| `a1_subway_card_1` | 2 | b1 | a2 | 1 level(s) |
| `a1_weather_layer_1` | 2 | b1 | a2 | 1 level(s) |
| `a2_bank_counter_1` | 2 | b2 | b1 | 1 level(s) |
| `a2_housing_search_2026_1` | 3 | c1 | b1 | 2 level(s) |
| `a2_part_time_1` | 2.5 | b2 | b1 | 1 level(s) |
| `a2_partner_banmal_switch_1` | 3 | c1 | b1 | 2 level(s) |
| `a2_partner_sibling_tease_1` | 2 | b2 | b1 | 1 level(s) |
| `a2_phone_plan_1` | 3 | c1 | b1 | 2 level(s) |
| `b1_public_office_1` | 2 | c1 | b2 | 1 level(s) |

모두 §14.2 원칙(목적 레벨에 맞는 선반이 없으면 하향) 또는 브리프 R-C 고정 룰링을 그대로 따른 결과 -- 재계산으로 새로 발견한 문제는 아님. `a2_phone_plan_1`/`a2_housing_search_2026_1`/`a2_partner_banmal_switch_1`/`a2_partner_sibling_tease_1`은 raw가 c1(2단계 하향)까지 나오는데, `partner`/`bill`/`form` 선반이 b2에도 있어 "한 단계만" 하향 원칙과는 다르게 b1까지 두 단계 내려간 것 -- Fable이 이미 확정한 고정 룰링이라 그대로 적용했지만 아래 공개 질문에도 다시 적어 둠.

## 이동하지 않는 팩 (R-C 명시)

| pack | level | reason |
|---|---|---|
| `a2_festival_booth_1` | a2 | word-level swaps later (median=1.5, share=50%, n_hm=8) |
| `a2_lost_found_1` | a2 | word-level swaps later (median=1, share=44%, n_hm=9) |
| `a2_salon_visit_1` | a2 | word-level swaps later (median=1, share=40%, n_hm=10) |
| `a2_apt_rules_1` | a2 | word-level swaps later (median=1, share=33%, n_hm=9) |
| `a1_repair_language_1` | a1 | word-level swaps later (median=1.5, share=50%, n_hm=4) |

이 5팩은 감사기 수치상으로는 `a2_festival_booth_1`(share 50%, n_hm 8)·`a2_lost_found_1`(44%, n_hm 9)처럼 R-A 기준(share≥40%·n_hm≥6)을 충족하는 것도 있지만, 브리프 R-C가 "단어 단위 교체는 나중에(T2.5)"로 명시적으로 유보한 목록이라 번들 이동 대상에서 제외함.

## 표본 부족 팩 (insufficient_sample)

R-A 기준(share≥40% AND n_hm≥6이면 이동, n_hm<6이면 insufficient_sample)을 전체 223개 라이브 팩에 대해 재계산한 결과, **현재 이 기준을 충족하는 팩은 없음** -- 즉 "share≥40%인데 n_hm<6이라 이동 보류"에 해당하는 팩이 0건이다. 유일하게 근접한 사례는 `a1_repair_language_1`(share 50%, n_hm **4** < 6)이지만, 이 팩은 위 '이동하지 않는 팩' 표에 R-C 고정 룰링으로 이미 올라 있어 여기 별도로 다시 넣지 않음(중복 방지).

## auditor_added 후보 (R-C 목록 밖, 감사기가 자체적으로 bundle_move로 표시)

전체 223개 라이브 팩의 `pack_stats`를 직접 계산해 확인한 결과, R-C의 21개 팩(이동 16 + 이동 보류 5) 밖에서 감사기 자체 판정(median Δ≥2 AND n_hm≥6, `_pack_action`)이 `bundle_move`인 팩은 **`b1_public_office_1`(median Δ=2, share=56%, n_hm=9) 1건뿐**이다. 위 이동 목록에 17번째 항목으로 포함하고 `reason`에 `auditor_added`로 표시함. share≥40%·n_hm≥6이지만 감사기 자체 판정은 `step_up_or_swap`/`keep`인 (즉 median Δ<2인) 팩 8개(`a1_post_office_1`, `b1_insurance_claim_1`, `b1_partner_group_chat_1`, `b1_partner_job_visa_1`, `b1_travel_change_1`, `b1_work_coordination_1`, `b2_formal_complaint_1`, `b2_housing_dispute_1`)는 번들 이동이 아니라 단어 단위 교체 쪽(T2.5)이 맞다고 보고 이번 목록에서는 제외함 -- median Δ가 1 이하라 통째로 옮기기엔 근거가 약함.

## 공개 질문 (Fable 확인 필요)

1. **`b1_public_office_1`(auditor_added)** -- R-C 원래 목록에 없던 팩. raw 목표는 c1인데 c1 15슬롯(briefing/uncertainty/access/labor/conflict_interest/policy/clinical/critique/mediation + methodology/facework/attribution + friends/dating/fandom) 중 '관공서 방문' 에 맞는 게 없어 §14.2 원칙대로 b2로 한 단계 내렸다. b2는 `public`(기능)·`authorities`(확장) 선반이 있어 표면 주제는 맞지만, b2 6개 유닛 중 이 팩(민원실·구비 서류·접수증·처리 기한·대리 신청·수수료 납부 등 순수 행정 절차 어휘)의 canDo를 정확히 대표하는 것은 없다 -- 가장 가까운 `b2_04_complaint_resolution`(근거로 책임 범위 협의)도 '불만 제기'가 아니라 '절차 진행'이 핵심이라 완벽하진 않다. 현재(이동 전) 등록 유닛이 이미 `b1_05_complaint_resolution`이라 그 계열을 따라 b2_04로 이었는데, Fable이 이 유닛/선반 판단과 b2 하향 자체(혹은 c1 잔류)를 확인해 주길 요청함.
2. **2단계 하향 4건** -- `a2_phone_plan_1`·`a2_housing_search_2026_1`·`a2_partner_banmal_switch_1`·`a2_partner_sibling_tease_1`은 median Δ=3(raw target c1)인데 브리프 R-C가 b1로 확정했다(§14.2 '한 단계 하향' 원칙보다 큰 폭). b1의 `bill`/`form`/`partner` 선반이 이유가 되는 것으로 보이지만, b2에도 `contract`(폰 약정)·`partner` 선반이 있어 b2를 완전히 배제한 근거를 리포트에 남겨 두는 게 맞는지 재확인 요청.
3. **`a1_weather_layer_1`의 유닛 선택** -- `a2_04_feelings_health`(증상↔건강)과 `a2_08_home_money`(집 문제) 중 전자를 골랐다(습하다/쌀쌀하다=신체 감각 형용사, 미세먼지=마스크 착용 건강 행동). 둘 다 완벽한 canDo 일치는 아니라 Fable 확인 요청.
4. **`a2_bank_counter_1`의 유닛 선택** -- `b1_05_complaint_resolution`과 `b1_06_life_capstone` 중 전자를 골랐다(b1_06의 체크포인트 시나리오 `apartment_recycling_mixup`은 `a1_neighbors_hall_1`과 훨씬 잘 맞아 b1_06을 그쪽에 남겨 둠). 확인 요청.
5. **`a2_housing_search_2026_1`의 cloze/satz auto 매칭이 6/6뿐**(다른 16개 팩은 전부 12/12) -- 이 팩 자체는 12단어인데 절반만 같은 레벨에서 파생된 cloze/satz가 있다. batch_20 (2026 신규 팩)이 원래 cloze/satz를 절반만 생성했을 가능성이 높아 보이나, 이동 자체와는 무관하니 별도 확인만 요청(이동 시 `auto`가 실제로 6개만 옮기는 게 맞는지).
6. **smalltalk=[] 전부** -- 4개 배치 manifest(`vocabPacks`, `smalltalkCategoryMappings`, `contentLinks`)를 다 확인했지만 이 17팩을 개별 smalltalk id에 연결한 데이터가 없다(스몰토크는 카테고리→코스유닛 단위로만 연결됨). R-D 규칙대로 빈 리스트로 두었는데, 이게 맞는 해석인지 확인 요청.
7. **scenario_candidates=0 전부** -- "현재 레벨 샤드에 있으면서 새 unit과 courseUnitId가 이미 일치하는 시나리오"만 후보로 세었다(즉 이미 스스로 잘못된 레벨에 있는 시나리오만 잡아내는 좁은 규칙). 이 해석이 맞다면 0건은 '현재 이런 표류 시나리오가 없다'는 정상적인 결과다. 대안 해석(예: 현재 unit이 같은 시나리오, 혹은 단어 겹침만으로 폭넓게 찾기)을 원하면 재계산 가능.

## 방법 노트

- R-A 계산은 `tool/audit_content_levels.py`의 `run_audit()`을 직접 import해 얻은 `AuditResult.pack_stats`(전체 223팩)를 그대로 썼다 -- `docs/data/content_level_report.md`의 'A1/A2 팩 순위' 표는 `_top_packs_section`이 `level in (a1,a2)`로 필터링해서 b1+ 팩(예: `b1_public_office_1`)이 애초에 안 나온다. `tool/content_level_summary.json`의 `packs.a1/a2.share_ge_plus2_top10`도 레벨당 상위 10개로 잘려 있어 전수 확인에는 부족했다 -- 그래서 CSV를 직접 파싱하는 대신 감사기 함수를 그대로 재사용해 전체 팩을 재계산했다(같은 코드 경로이므로 `content_level_suspects.csv`/`content_level_summary.json`과 수치가 100% 일치함, `n_hm`/`n_low`/`median_delta`/`share_ge_plus2`).
- `content_level_suspects.csv`는 vocab 행에 `confidence`(high/medium/low) 열이 없고, reason 텍스트만으로는 low-confidence인 `over1`/`under2` 행을 high-confidence 행과 구분할 수 없어(`over2`만 `fallback_over2`로 별도 표시됨) CSV 텍스트를 직접 재파싱하지 않고 위 방법을 썼다.
- `conceptIds`는 대상 유닛 9개(`b1_06_life_capstone`, `a2_04_feelings_health`, `a2_07_travel_repair`, `b1_04_relationships`, `a2_03_chat_relationships`, `a2_06_study_work`, `b1_03_work_softening`, `b1_05_complaint_resolution`, `b2_04_complaint_resolution`) 전부 `requiredConceptIds`가 정확히 1개라 '선택'의 여지가 없었다 -- 그대로 그 1개를 넣음.
- `newPackId`·전체 17개 새 pack_id는 `assets/data/korean_vocab.csv`의 현재 223개 라이브 `pack_id`와 충돌 없음(전수 대조).

## 실행 결과

모드: --apply (실제 반영됨)

| pack | words | cloze | satz | cando cluster (from -> to) | segment | note |
|---|---|---|---|---|---|---|
| `a1_neighbors_hall_1`->`b1_neighbors_hall_1` | 12 | 12 | 12 | `cluster_a1_11_titles_relationships_v1` -> `cluster_b1_move_in_handover_v1` | `segment_b1_move_in_handover` | explicit (Fable ruling) |
| `a1_partner_house_entry_1`->`a2_partner_house_entry_1` | 12 | 12 | 12 | `cluster_a1_11_titles_relationships_v1` -> `cluster_a2_running_late_v1` | `segment_a2_running_late` | explicit (Fable ruling) |
| `a1_partner_chuseok_basic_1`->`a2_partner_chuseok_basic_1` | 12 | 12 | 12 | `cluster_a1_11_titles_relationships_v1` -> `cluster_a2_running_late_v1` | `segment_a2_running_late` | explicit (Fable ruling) |
| `a1_partner_photo_thanks_1`->`a2_partner_photo_thanks_1` | 12 | 12 | 12 | `cluster_a1_11_titles_relationships_v1` -> `cluster_a2_running_late_v1` | `segment_a2_running_late` | explicit (Fable ruling) |
| `a1_partner_first_gift_1`->`b1_partner_first_gift_1` | 12 | 12 | 12 | `cluster_a1_11_titles_relationships_v1` -> `cluster_b1_intimate_feelings_v1` | `segment_b1_intimate_feelings` | explicit (Fable ruling) |
| `a1_partner_siblings_hello_1`->`b1_partner_siblings_hello_1` | 12 | 12 | 12 | `cluster_a1_11_titles_relationships_v1` -> `cluster_b1_intimate_feelings_v1` | `segment_b1_intimate_feelings` | explicit (Fable ruling) |
| `a2_partner_sibling_tease_1`->`b1_partner_sibling_tease_1` | 12 | 12 | 12 | `cluster_a2_running_late_v1` -> `cluster_b1_intimate_feelings_v1` | `segment_b1_intimate_feelings` | explicit (Fable ruling) |
| `a2_partner_banmal_switch_1`->`b1_partner_banmal_switch_1` | 12 | 12 | 12 | `cluster_a2_running_late_v1` -> `cluster_b1_intimate_feelings_v1` | `segment_b1_intimate_feelings` | explicit (Fable ruling) |
| `a1_pharmacy_ask_1`->`a2_pharmacy_ask_1` | 12 | 12 | 12 | `cluster_a1_10_health_safety_v1` -> `cluster_a2_pharmacy_headache_v1` | `segment_a2_pharmacy_headache` | explicit (Fable ruling) |
| `a1_school_supplies_1`->`a2_school_supplies_1` | 12 | 12 | 12 | `cluster_a1_15_first_class_work_v1` -> `cluster_a2_cafe_study_v1` | `segment_a2_cafe_study` | explicit (Fable ruling) |
| `a1_subway_card_1`->`a2_subway_card_1` | 12 | 12 | 12 | `cluster_a1_06_transport_directions_v1` -> `cluster_a2_subway_transfer_v1` | `segment_a2_subway_transfer` | explicit (Fable ruling) |
| `a1_weather_layer_1`->`a2_weather_layer_1` | 12 | 12 | 12 | `cluster_a1_09_home_daily_life_v1` -> `cluster_a2_feeling_sick_v1` | `segment_a2_feeling_sick` | explicit (Fable ruling) |
| `a2_bank_counter_1`->`b1_bank_counter_1` | 12 | 12 | 12 | `cluster_a2_rent_bank_transfer_v1` -> `cluster_b1_delivery_resolution_v1` | `segment_b1_delivery_resolution` | explicit (Fable ruling) |
| `a2_housing_search_2026_1`->`b1_housing_search_2026_1` | 12 | 6 | 6 | `cluster_a2_rent_bank_transfer_v1` -> `cluster_b1_housing_contract_v1` | `segment_b1_housing_contract` | explicit (Fable ruling) |
| `a2_part_time_1`->`b1_part_time_1` | 12 | 12 | 12 | `cluster_a2_cafe_study_v1` -> `cluster_b1_team_role_coordination_v1` | `segment_b1_team_role_coordination` | explicit (Fable ruling) |
| `a2_phone_plan_1`->`b1_phone_plan_1` | 12 | 12 | 12 | `cluster_a2_cafe_starbucks_basic_v1` -> `cluster_b1_delivery_resolution_v1` | `segment_b1_delivery_resolution` | explicit (Fable ruling) |
| `b1_public_office_1`->`b2_public_office_1` | 12 | 12 | 12 | `cluster_b1_delivery_resolution_v1` -> `cluster_b2_remedy_and_appeal_v1` | `segment_b2_remedy_and_appeal` | explicit (Fable ruling) |

vocabPackUnitMap 개명 17건, clozeTopicUnitMap +10/-10, contentLinks 재작성 0건.

Dart 편집:
- `packDisplayMap` 개명: [('a1_neighbors_hall', 'b1_neighbors_hall'), ('a1_partner_house_entry', 'a2_partner_house_entry'), ('a1_partner_chuseok_basic', 'a2_partner_chuseok_basic'), ('a1_partner_photo_thanks', 'a2_partner_photo_thanks'), ('a1_partner_first_gift', 'b1_partner_first_gift'), ('a1_partner_siblings_hello', 'b1_partner_siblings_hello'), ('a2_partner_sibling_tease', 'b1_partner_sibling_tease'), ('a2_partner_banmal_switch', 'b1_partner_banmal_switch'), ('a1_pharmacy_ask', 'a2_pharmacy_ask'), ('a1_school_supplies', 'a2_school_supplies'), ('a1_subway_card', 'a2_subway_card'), ('a1_weather_layer', 'a2_weather_layer'), ('a2_bank_counter', 'b1_bank_counter'), ('a2_housing_search_2026', 'b1_housing_search_2026'), ('a2_part_time', 'b1_part_time'), ('a2_phone_plan', 'b1_phone_plan'), ('b1_public_office', 'b2_public_office')]
- `packOrderInLevel` 개명(새 순번): [('a1_neighbors_hall', 'b1_neighbors_hall', 42), ('a1_partner_house_entry', 'a2_partner_house_entry', 33), ('a1_partner_chuseok_basic', 'a2_partner_chuseok_basic', 36), ('a1_partner_photo_thanks', 'a2_partner_photo_thanks', 38), ('a1_partner_first_gift', 'b1_partner_first_gift', 21), ('a1_partner_siblings_hello', 'b1_partner_siblings_hello', 22), ('a2_partner_sibling_tease', 'b1_partner_sibling_tease', 31), ('a2_partner_banmal_switch', 'b1_partner_banmal_switch', 32), ('a1_pharmacy_ask', 'a2_pharmacy_ask', 53), ('a1_school_supplies', 'a2_school_supplies', 54), ('a1_subway_card', 'a2_subway_card', 55), ('a1_weather_layer', 'a2_weather_layer', 56), ('a2_bank_counter', 'b1_bank_counter', 43), ('a2_housing_search_2026', 'b1_housing_search_2026', 44), ('a2_part_time', 'b1_part_time', 45), ('a2_phone_plan', 'b1_phone_plan', 46), ('b1_public_office', 'b2_public_office', 48)]
- `dedicatedPackIds` 개명 + 아트워크 파일 rename: [('a1_neighbors_hall_1', 'b1_neighbors_hall_1'), ('a1_partner_chuseok_basic_1', 'a2_partner_chuseok_basic_1'), ('a1_partner_photo_thanks_1', 'a2_partner_photo_thanks_1'), ('a1_partner_siblings_hello_1', 'b1_partner_siblings_hello_1'), ('a2_partner_sibling_tease_1', 'b1_partner_sibling_tease_1'), ('a2_partner_banmal_switch_1', 'b1_partner_banmal_switch_1'), ('a1_subway_card_1', 'a2_subway_card_1'), ('a1_weather_layer_1', 'a2_weather_layer_1'), ('a2_bank_counter_1', 'b1_bank_counter_1'), ('a2_housing_search_2026_1', 'b1_housing_search_2026_1'), ('a2_part_time_1', 'b1_part_time_1'), ('a2_phone_plan_1', 'b1_phone_plan_1')]
- `kPackProgressAliases` 추가: [('b1_neighbors_hall_1', 'a1_neighbors_hall_1'), ('a2_partner_house_entry_1', 'a1_partner_house_entry_1'), ('a2_partner_chuseok_basic_1', 'a1_partner_chuseok_basic_1'), ('a2_partner_photo_thanks_1', 'a1_partner_photo_thanks_1'), ('b1_partner_first_gift_1', 'a1_partner_first_gift_1'), ('b1_partner_siblings_hello_1', 'a1_partner_siblings_hello_1'), ('b1_partner_sibling_tease_1', 'a2_partner_sibling_tease_1'), ('b1_partner_banmal_switch_1', 'a2_partner_banmal_switch_1'), ('a2_pharmacy_ask_1', 'a1_pharmacy_ask_1'), ('a2_school_supplies_1', 'a1_school_supplies_1'), ('a2_subway_card_1', 'a1_subway_card_1'), ('a2_weather_layer_1', 'a1_weather_layer_1'), ('b1_bank_counter_1', 'a2_bank_counter_1'), ('b1_housing_search_2026_1', 'a2_housing_search_2026_1'), ('b1_part_time_1', 'a2_part_time_1'), ('b1_phone_plan_1', 'a2_phone_plan_1'), ('b2_public_office_1', 'b1_public_office_1')]

`test/`·`tools/content_factory/`에서 옛 pack id를 참조하는 파일 (Fable 확인 필요):
- `a2_housing_search_2026_1`: ['tools/content_factory/test_relevel_bundle.py']

## 실행 결과 (L2a2)

모드: --apply (실제 반영됨)

| scenario | from->to | unit | shelf | contentLinks | can-do | shelf_assignment.py | AB_SPECS |
|---|---|---|---|---|---|---|---|
| `shared_document_old_version` | a2->b1 | `b1_03_work_softening` | `b1_team` | 1 | no can-do references | not tracked in shelf_assignment.py ASSIGNMENT -- no update | removed key='a2_cafe_study' (from-level 'a2'); NOTE: 'a2_cafe_study' is still referenced elsewhere in this file (e.g. UNIT_DEFAULT_ROUTE/PACK_ROUTES) -- harmless while the generator is frozen, worth a look if it is ever unfrozen; added key='b1_shared_document_old_version' after anchor='b1_schedule_softening' |


vocabPackUnitMap 개명 0건, clozeTopicUnitMap +0/-0, contentLinks 재작성 0건.

Dart 편집:
- `packDisplayMap` 개명: []
- `packOrderInLevel` 개명(새 순번): []
- `dedicatedPackIds` 개명 + 아트워크 파일 rename: []
- `kPackProgressAliases` 추가: []

`test/`·`tools/content_factory/`에서 옛 pack id를 참조하는 파일 (Fable 확인 필요):
- (없음)

시나리오 이동이 적용됨 -- 다음 후속 명령을 실행할 것:
```
python tool/generate_tts.py --write-first-line-manifest assets/data/tts_first_line_manifest.json
python tool/generate_tts.py --check-first-line-manifest assets/data/tts_first_line_manifest.json
python functions/tts/build_canonical_manifest.py
python functions/tts/build_canonical_manifest.py --check
```

## 실행 결과 (L2a3)

모드: --apply (실제 반영됨)

| pack | words | cloze | satz | cando cluster (from -> to) | segment | note |
|---|---|---|---|---|---|---|
| `a2_lost_found_1`->`b1_lost_found_1` | 12 | 12 | 12 | `cluster_a2_subway_directions_v1` -> `cluster_b1_delivery_resolution_v1` | `segment_b1_delivery_resolution` | explicit (Fable ruling) |
| `a2_festival_booth_1`->`b1_festival_booth_1` | 12 | 12 | 12 | `cluster_a2_running_late_v1` -> `cluster_b1_life_course_narrative_v1` | `segment_b1_life_course_narrative` | explicit (Fable ruling) |
| `a2_apt_rules_1`->`b1_apt_rules_1` | 12 | 12 | 12 | `cluster_a2_rent_bank_transfer_v1` -> `cluster_b1_move_in_handover_v1` | `segment_b1_move_in_handover` | explicit (Fable ruling) |
| `a2_partner_leftover_bags_1`->`b1_partner_leftover_bags_1` | 12 | 12 | 12 | `cluster_a2_running_late_v1` -> `cluster_b1_intimate_feelings_v1` | `segment_b1_intimate_feelings` | explicit (Fable ruling) |

vocabPackUnitMap 개명 4건, clozeTopicUnitMap +3/-3, contentLinks 재작성 0건.

Dart 편집:
- `packDisplayMap` 개명: [('a2_lost_found', 'b1_lost_found'), ('a2_festival_booth', 'b1_festival_booth'), ('a2_apt_rules', 'b1_apt_rules'), ('a2_partner_leftover_bags', 'b1_partner_leftover_bags')]
- `packOrderInLevel` 개명(새 순번): [('a2_lost_found', 'b1_lost_found', 48), ('a2_festival_booth', 'b1_festival_booth', 49), ('a2_apt_rules', 'b1_apt_rules', 50), ('a2_partner_leftover_bags', 'b1_partner_leftover_bags', 29)]
- `dedicatedPackIds` 개명 + 아트워크 파일 rename: [('a2_lost_found_1', 'b1_lost_found_1'), ('a2_festival_booth_1', 'b1_festival_booth_1'), ('a2_apt_rules_1', 'b1_apt_rules_1'), ('a2_partner_leftover_bags_1', 'b1_partner_leftover_bags_1')]
- `kPackProgressAliases` 추가: [('b1_lost_found_1', 'a2_lost_found_1'), ('b1_festival_booth_1', 'a2_festival_booth_1'), ('b1_apt_rules_1', 'a2_apt_rules_1'), ('b1_partner_leftover_bags_1', 'a2_partner_leftover_bags_1')]

`test/`·`tools/content_factory/`에서 옛 pack id를 참조하는 파일 (Fable 확인 필요):
- (없음)

