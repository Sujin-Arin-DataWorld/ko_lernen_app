# 콘텐츠 자연성 프리필터 후보 리포트

`python tool/audit_content_naturalness.py` 로 생성 — 직접 편집 금지, 스크립트 재실행으로 갱신한다.

마커는 전부 결정적 규칙(정규식/문자열 포함/받침 유무) 기반이다. 여기 실리는 항목은 "후보"이며, 실제 어색함 여부는 Task 12 의 사람/LLM 심사가 판단한다.

## cloze.json

57건.

| id | 마커 | 문장 |
|---|---|---|
| cloze_a1_0003 | josa_dup | 나이가 몇 살이에요? |
| cloze_a1_0013 | particle_mismatch | ＿＿＿이 있어요? (distractor: 타다, 마시다, 으로) |
| cloze_a1_0031 | particle_mismatch | ＿＿＿을 좋아해요. (distractor: 모르다, 가다, 에게) |
| cloze_a1_0038 | particle_mismatch | ＿＿＿을 좋아해요? (distractor: 다니다, 고르다, 한테) |
| cloze_a1_0040 | particle_mismatch | ＿＿＿이 맛있어요. (distractor: 끝나다, 고르다, 에서) |
| cloze_a1_0066 | particle_mismatch | ＿＿＿이 없어요. (distractor: 끝나다, 빌리다, 에서) |
| cloze_a1_0070 | particle_mismatch | ＿＿＿이 좋아요. (distractor: 타다, 고르다, 과) |
| cloze_a1_0077 | formality_mix | 실례합니다 잠깐만요. |
| cloze_a1_0115 | particle_mismatch | 큰돈 말고 ＿＿＿이면 충분해요. (distractor: 끝나다, 타다, 한테) |
| cloze_a1_0135 | particle_mismatch | ＿＿＿을 간단히 확인했어요. (distractor: 모르다, 가다, 에게) |
| cloze_a1_0174 | josa_dup | 시누이가 옷걸이를 찾아 줬어요. |
| cloze_a1_0179 | josa_dup | 맏이가 자리 배치를 조용히 정했어요. |
| cloze_a1_0187 | formality_mix | 나갈 때 인사했어요. 잘 다녀오겠습니다! |
| cloze_a1_0188 | formality_mix | 식사 후에 잘 먹었습니다 하고 인사했어요. |
| cloze_a1_0195 | particle_mismatch | ＿＿＿은 따뜻했다고만 적었어요. (distractor: 모르다, 타다) |
| cloze_a1_0211 | particle_mismatch | ＿＿＿을 종이에 적어 주세요. (distractor: 보다, 팔다, 에서) |
| cloze_a1_0228 | particle_mismatch | ＿＿＿이 있어요? (distractor: 다니다, 자다, 에서) |
| cloze_a1_0241 | particle_mismatch | 엘리베이터에 ＿＿＿이 있어요. (distractor: 마시다, 타다, 와) |
| cloze_a1_0267 | particle_mismatch | ＿＿＿은 오른쪽이에요. (distractor: 돕다, 쓰다, 에게) |
| cloze_a1_0294 | formality_mix | 처음 만나요. 처음 뵙겠습니다. |
| cloze_a1_0299 | formality_mix | 도움을 받았어요. 감사합니다. |
| cloze_a1_0327 | particle_mismatch | ＿＿＿을 주세요. (distractor: 오다, 다니다, 와) |
| cloze_a1_0542 | josa_dup | 아이가 운동장에서 놀아요. |
| cloze_a1_0563 | josa_dup | 고양이가 몇 마리예요? |
| cloze_a1_0581 | formality_mix | 실례합니다. 화장실이 어디예요? |
| cloze_a1_0602 | josa_dup | 아이가 그림을 그려요. |
| cloze_a1_0668 | josa_dup | 아이가 많이 울어요. |
| cloze_a1_0749 | josa_dup | 저는 고양이가 두 마리 있어요. |
| cloze_a2_0005 | particle_mismatch | 어떤 ＿＿＿을 좋아해요? (distractor: 먹다, 돕다, 와) |
| cloze_a2_0018 | particle_mismatch | 내일 ＿＿＿이 있어요. (distractor: 자다, 모르다, 와) |
| cloze_a2_0020 | particle_mismatch | ＿＿＿이 좋아요. (distractor: 읽다, 오다, 에게) |
| cloze_a2_0030 | particle_mismatch | ＿＿＿이 없어요. (distractor: 고르다, 입다, 으로) |
| cloze_a2_0032 | particle_mismatch | ＿＿＿이 있어요? (distractor: 빌리다, 읽다, 에게) |
| cloze_a2_0034 | particle_mismatch | ＿＿＿이 있어요? (distractor: 오다, 읽다, 에게) |
| cloze_a2_0056 | particle_mismatch | 내일 ＿＿＿이 있어요. (distractor: 읽다, 팔다, 과) |
| cloze_a2_0057 | particle_mismatch | ＿＿＿이 예뻐요. (distractor: 자다, 모르다, 과) |
| cloze_a2_0058 | particle_mismatch | ＿＿＿을 좋아해요. (distractor: 알다, 보다, 에게) |
| cloze_a2_0069 | particle_mismatch | ＿＿＿을 냈어요. (distractor: 고르다, 마시다, 한테) |
| cloze_a2_0174 | particle_mismatch | 주말에는 데이터가 ＿＿＿이에요. (distractor: 모르다, 끝나다, 과) |
| cloze_a2_0193 | particle_mismatch | ＿＿＿이 네 시라서 서둘렀어요. (distractor: 쓰다, 자다) |
| cloze_a2_0327 | josa_dup | 강아지가 아파서 아이가 많이 슬퍼했어요. |
| cloze_b1_0007 | particle_mismatch | 좋은 ＿＿＿이 있어요? (distractor: 먹다, 빌리다, 와) |
| cloze_b1_0008 | particle_mismatch | ＿＿＿가 있어요? (distractor: 랑) |
| cloze_b1_0020 | particle_mismatch | ＿＿＿가 좋아요. (distractor: 랑) |
| cloze_b1_0050 | josa_dup | 두 나라의 차이가 커요. |
| cloze_b1_0052 | particle_mismatch | ＿＿＿이 있어요. (distractor: 빌리다, 가다) |
| cloze_b1_0198 | particle_mismatch | ＿＿＿를 표로 붙여 두었어요. (distractor: 랑) |
| cloze_b2_0002 | particle_mismatch | 다양한 ＿＿＿이 있어요. (distractor: 팔다, 타다, 에게) |
| cloze_b2_0034 | particle_mismatch | 어떤 ＿＿＿이 있어요? (distractor: 빌리다, 끝나다, 와) |
| cloze_b2_0040 | particle_mismatch | ＿＿＿이 뭐예요? (distractor: 쓰다, 보다, 와) |
| cloze_b2_0270 | particle_mismatch | ＿＿＿을 할 때는 '꼼꼼하다'는 말보다 실제로 문제를 해결한 사례를 제시했어요. (distractor: 알다, 팔다, 과) |
| cloze_b2_0292 | particle_mismatch | ＿＿＿가 있는지 확인해 광고와 일반 기사를 구분했다. (distractor: 랑) |
| cloze_c1_0024 | josa_dup | 인터뷰 내용과 실제 이용 기록을 대조하니 기억과 행동 사이에 차이가 보였습니다. |
| cloze_c1_0084 | josa_dup | 두 값의 차이가 측정 오차보다 작다면 실제 차이라고 단정하기 어렵다. |
| cloze_c1_0249 | josa_dup | 설명 가능성은 기술 문서의 길이가 아니라 이의 제기에 쓸 수 있는 정보로 평가해야 합니다. |
| cloze_c2_0223 | josa_dup | 소득 구간별 부담의 분포를 공개해야 평균이 가리는 차이가 드러납니다. |
| cloze_c2_0253 | josa_dup | 같은 높임 표현도 용례를 비교하면 쓰이는 상황의 차이가 보인다. |

## grammar.csv

1건.

| id | 마커 | 문장 |
|---|---|---|
| grammar_a2_toward_person#0 | josa_dup | 아이가 엄마에게로 걸어갔습니다. |

## korean_vocab.csv

19건.

| id | 마커 | 문장 |
|---|---|---|
| vocab_a1_0011 | josa_dup | 나이가 어떻게 되세요? |
| vocab_a1_0286 | josa_dup | 시누이가 옷걸이를 찾아 줬어요. |
| vocab_a1_0291 | josa_dup | 맏이가 자리 배치를 조용히 정했어요. |
| vocab_a1_0299 | formality_mix | 나갈 때 인사했어요. 잘 다녀오겠습니다! |
| vocab_a1_0300 | formality_mix | 식사 후에 잘 먹었습니다 하고 인사했어요. |
| vocab_a1_0608 | josa_dup | 아이가 운동장에서 놀아요. |
| vocab_a1_0629 | josa_dup | 고양이가 몇 마리예요? |
| vocab_a1_0647 | formality_mix | 실례합니다. 화장실이 어디예요? |
| vocab_a1_0668 | josa_dup | 아이가 그림을 그려요. |
| vocab_a1_0734 | josa_dup | 아이가 많이 울어요. |
| vocab_a1_0815 | josa_dup | 저는 고양이가 두 마리 있어요. |
| vocab_a2_0171 | josa_dup | 파란 넥타이가 잘 어울려요. |
| vocab_a2_0244 | josa_dup | 아이가 공주 그림을 그렸어요. |
| vocab_a2_0520 | josa_dup | 강아지가 아파서 아이가 많이 슬퍼했어요. |
| vocab_b1_0086 | josa_dup | 한국이랑 독일 문화 차이가 진짜 커요. |
| vocab_c1_0024 | josa_dup | 인터뷰 내용과 실제 이용 기록을 대조하니 기억과 행동 사이에 차이가 보였습니다. |
| vocab_c1_0080 | josa_dup | 두 값의 차이가 측정 오차보다 작다면 실제 차이라고 단정하기 어렵다. |
| vocab_c1_0233 | josa_dup | 설명 가능성은 기술 문서의 길이가 아니라 이의 제기에 쓸 수 있는 정보로 평가해야 합니다. |
| vocab_c2_0243 | josa_dup | 같은 높임 표현도 용례를 비교하면 쓰이는 상황의 차이가 보인다. |

## satz_sentences.json

19건.

| id | 마커 | 문장 |
|---|---|---|
| satz_a1_0002 | josa_dup | 나이가 몇 살이에요? |
| satz_a1_0138 | josa_dup | 시누이가 옷걸이를 찾아 줬어요. |
| satz_a1_0143 | josa_dup | 맏이가 자리 배치를 조용히 정했어요. |
| satz_a1_0151 | formality_mix | 나갈 때 인사했어요. 잘 다녀오겠습니다! |
| satz_a1_0152 | formality_mix | 식사 후에 잘 먹었습니다 하고 인사했어요. |
| satz_a1_0523 | josa_dup | 아이가 운동장에서 놀아요. |
| satz_a1_0544 | josa_dup | 고양이가 몇 마리예요? |
| satz_a1_0562 | formality_mix | 실례합니다. 화장실이 어디예요? |
| satz_a1_0583 | josa_dup | 아이가 그림을 그려요. |
| satz_a1_0649 | josa_dup | 아이가 많이 울어요. |
| satz_a1_0730 | josa_dup | 저는 고양이가 두 마리 있어요. |
| satz_a2_0362 | josa_dup | 파란 넥타이가 잘 어울려요. |
| satz_a2_0432 | josa_dup | 아이가 공주 그림을 그렸어요. |
| satz_a2_0512 | josa_dup | 강아지가 아파서 아이가 많이 슬퍼했어요. |
| satz_b1_0042 | josa_dup | 두 나라의 차이가 커요. |
| satz_c1_0024 | josa_dup | 인터뷰 내용과 실제 이용 기록을 대조하니 기억과 행동 사이에 차이가 보였습니다. |
| satz_c1_0086 | josa_dup | 두 값의 차이가 측정 오차보다 작다면 실제 차이라고 단정하기 어렵다. |
| satz_c2_0225 | josa_dup | 소득 구간별 부담의 분포를 공개해야 평균이 가리는 차이가 드러납니다. |
| satz_c2_0255 | josa_dup | 같은 높임 표현도 용례를 비교하면 쓰이는 상황의 차이가 보인다. |

## scenarios_*.json

61건.

| id | 마커 | 문장 |
|---|---|---|
| a2_dongsun_christian_suspicious_delivery_text#dialog[00] | level_length | 크리스티안, 이것 좀 봐줄래요? 택배 주소가 틀렸다고 문자가 왔네요. 빨리 이 링크로 다시 확인하라고 써 있어요. |
| a2_dongsun_christian_suspicious_delivery_text#quest_a2_dongsun_christian_suspicious_delivery_text_02.options[1].ko | level_length | 크리스티안, 이것 좀 봐줄래요? 택배 주소가 틀렸다고 문자가 왔네요. 빨리 이 링크로 다시 확인하라고 써 있어요. |
| anonymous_survey_trust#dialog[05] | formality_mix | 맞아요. 식별 가능한 사례를 쓰지 말라는 안내와 실제 보고 방식을 함께 설명해야 신뢰를 얻습니다. |
| anonymous_survey_trust#quest_anonymous_survey_trust_03.targetKo | formality_mix | 맞아요. 식별 가능한 사례를 쓰지 말라는 안내와 실제 보고 방식을 함께 설명해야 신뢰를 얻습니다. |
| b1_byeongcheol_hwaseong_memory_check#dialog[04] | formality_mix | 좋습니다. 내가 본 것과 역사 자료는 같은 게 아니니까요. |
| b1_byeongcheol_hwaseong_memory_check#dialog[05] | formality_mix | 맞아요. 수원화성 설명은 공식 자료를 기준으로 하고, 선생님 이야기는 생활 기억이라고 따로 적겠습니다. |
| b1_byeongcheol_hwaseong_memory_check#quest_b1_byeongcheol_hwaseong_memory_check_02.options[2].ko | formality_mix | 좋습니다. 내가 본 것과 역사 자료는 같은 게 아니니까요. |
| b1_byeongcheol_hwaseong_memory_check#quest_b1_byeongcheol_hwaseong_memory_check_03.targetKo | formality_mix | 맞아요. 수원화성 설명은 공식 자료를 기준으로 하고, 선생님 이야기는 생활 기억이라고 따로 적겠습니다. |
| b1_dongsun_maya_price_notice#dialog[02] | formality_mix | ‘일부 수선 가격이 조정됩니다.’ 이 정도면 괜찮아요? |
| b1_dongsun_maya_price_notice#quest_b1_dongsun_maya_price_notice_02.options[2].ko | formality_mix | ‘일부 수선 가격이 조정됩니다.’ 이 정도면 괜찮아요? |
| b1_dongsun_norigae_shop_post#dialog[04] | formality_mix | 알겠어요. ‘동선 사장님이 직접 만든 노리개’라는 설명은 빼겠습니다. |
| b1_dongsun_norigae_shop_post#quest_b1_dongsun_norigae_shop_post_02.options[0].ko | formality_mix | 알겠어요. ‘동선 사장님이 직접 만든 노리개’라는 설명은 빼겠습니다. |
| b2_hyuna_andrea_work_family_choices#dialog[03] | josa_dup | 저도 아이가 있지만 제 경험을 정답처럼 말하면 바로 틀릴 것 같아요. |
| b2_sujin_minho_shorter_hours_tradeoff#dialog[01] | formality_mix | 회의요. 회의 하나 줄이면 다들 표정이 먼저 좋아졌을 겁니다. |
| b2_sujin_minho_shorter_hours_tradeoff#quest_b2_sujin_minho_shorter_hours_tradeoff_01.audioKo | formality_mix | 회의요. 회의 하나 줄이면 다들 표정이 먼저 좋아졌을 겁니다. |
| b2_w10_authorities#dialog[04] | formality_mix | 기한과 절차는 관련 안내문이나 공식 웹사이트에서 다시 확인하셔야 합니다. 가능한 빨리 신청 가능 여부를 확인해 보세요. |
| b2_w10_authorities#quest_b2_w10_authorities_hear.audioKo | formality_mix | 기한과 절차는 관련 안내문이나 공식 웹사이트에서 다시 확인하셔야 합니다. 가능한 빨리 신청 가능 여부를 확인해 보세요. |
| b2_w10_health#dialog[00] | formality_mix | 처방전은 확인했습니다. 이 약은 졸릴 수 있으니, 복용 시간이나 다른 선택지는 처방 내용과 현재 상태를 확인한 뒤 안내해 드릴게요. |
| b2_w10_health#dialog[02] | formality_mix | 졸릴 수 있는 약이 있습니다. 다만 복용 시간을 바꾸거나 다른 약으로 바꾸기 전에는 처방 내용과 현재 상태를 먼저 확인해야 해요. |
| b2_w10_health#dialog[04] | formality_mix | 가능한 복용 방법이나 대체 약이 있는지 처방의와 확인해 보겠습니다. 확인하기 전까지는 처방대로 복용해 주세요. |
| b2_w10_health#dialog[07] | formality_mix | 알겠습니다. 확인된 내용을 알려 주세요. |
| b2_w10_health#quest_b2_w10_health_build.targetKo | formality_mix | 알겠습니다. 확인된 내용을 알려 주세요. |
| b2_w10_health#quest_b2_w10_health_hear.audioKo | formality_mix | 가능한 복용 방법이나 대체 약이 있는지 처방의와 확인해 보겠습니다. 확인하기 전까지는 처방대로 복용해 주세요. |
| b2_w10_health#quest_b2_w10_health_hear.options[1].ko | formality_mix | 처방전은 확인했습니다. 이 약은 졸릴 수 있으니, 복용 시간이나 다른 선택지는 처방 내용과 현재 상태를 확인한 뒤 안내해 드릴게요. |
| b2_w10_health#quest_b2_w10_health_hear.options[2].ko | formality_mix | 졸릴 수 있는 약이 있습니다. 다만 복용 시간을 바꾸거나 다른 약으로 바꾸기 전에는 처방 내용과 현재 상태를 먼저 확인해야 해요. |
| b2_w10_travel#dialog[07] | formality_mix | 날씨에 따라 오늘 비행이 어려울 수 있다는 건 이해합니다. 다른 항공사나 다른 경로가 가능한지 확인해 주실 수 있을까요? |
| b2_w10_travel#quest_b2_w10_travel_hear.audioKo | formality_mix | 날씨에 따라 오늘 비행이 어려울 수 있다는 건 이해합니다. 다른 항공사나 다른 경로가 가능한지 확인해 주실 수 있을까요? |
| bakery_queue#dialog[02] | formality_mix | 아, 죄송합니다. 줄 서 계신지 몰랐어요. |
| bakery_queue#quest_bakery_queue_02.options[2].ko | formality_mix | 아, 죄송합니다. 줄 서 계신지 몰랐어요. |
| c1_w10_facework#dialog[08] | formality_mix | 다음 제출 전에는 표의 원자료를 한 번 더 대조해 보세요. 필요하면 제가 같이 보겠습니다. |
| c1_w10_facework#quest_c1_w10_facework_build.targetKo | formality_mix | 다음 제출 전에는 표의 원자료를 한 번 더 대조해 보세요. 필요하면 제가 같이 보겠습니다. |
| c2_w10_jurisdiction#dialog[05] | formality_mix | 감사합니다. 확인 결과와 다음 절차를 알려주실 수 있을까요? |
| community_festival_shift#dialog[00] | formality_mix | 축제 봉사 담당입니다. 무슨 일이세요? |
| community_festival_shift#quest_community_festival_shift_01.audioKo | formality_mix | 축제 봉사 담당입니다. 무슨 일이세요? |
| community_festival_shift#quest_community_festival_shift_02.options[1].ko | formality_mix | 축제 봉사 담당입니다. 무슨 일이세요? |
| convenience_parcel_pickup#dialog[06] | formality_mix | 확인됐어요. 여기 있습니다. |
| delivery_refund_evidence#dialog[00] | formality_mix | 불편을 드려 죄송합니다. 음식은 모두 그대로 있나요? |
| delivery_refund_evidence#quest_delivery_refund_evidence_01.audioKo | formality_mix | 불편을 드려 죄송합니다. 음식은 모두 그대로 있나요? |
| delivery_refund_evidence#quest_delivery_refund_evidence_02.options[1].ko | formality_mix | 불편을 드려 죄송합니다. 음식은 모두 그대로 있나요? |
| food_delivery_wrong_order#dialog[00] | formality_mix | 고객센터입니다. 어떤 문제가 있으세요? |
| food_delivery_wrong_order#quest_food_delivery_wrong_order_01.audioKo | formality_mix | 고객센터입니다. 어떤 문제가 있으세요? |
| food_delivery_wrong_order#quest_food_delivery_wrong_order_02.options[1].ko | formality_mix | 고객센터입니다. 어떤 문제가 있으세요? |
| library_quiet_zone_conflict#dialog[03] | formality_mix | 알려 주셔서 감사합니다. 바로 옮길게요. |
| library_quiet_zone_conflict#quest_library_quiet_zone_conflict_02.options[3].ko | formality_mix | 알려 주셔서 감사합니다. 바로 옮길게요. |
| meeting_opening_context#dialog[05] | formality_mix | 알겠습니다. 오늘 결정할 범위부터 메모할게요. |
| meeting_opening_context#quest_meeting_opening_context_03.targetKo | formality_mix | 알겠습니다. 오늘 결정할 범위부터 메모할게요. |
| noisy_neighbor_evening#dialog[05] | formality_mix | 감사합니다. 늦은 시간만 조심해 주세요. |
| noisy_neighbor_evening#quest_noisy_neighbor_evening_03.targetKo | formality_mix | 감사합니다. 늦은 시간만 조심해 주세요. |
| poll_question_framing#dialog[05] | formality_mix | 맞아요. 문항 순서 효과도 확인할 수 있도록 순서를 바꾼 표본을 두는 게 좋습니다. |
| poll_question_framing#quest_poll_question_framing_03.targetKo | formality_mix | 맞아요. 문항 순서 효과도 확인할 수 있도록 순서를 바꾼 표본을 두는 게 좋습니다. |
| rental_repair_deposit#dialog[05] | formality_mix | 좋습니다. 두 사진의 날짜도 함께 보내 드릴게요. |
| rental_repair_deposit#quest_rental_repair_deposit_03.targetKo | formality_mix | 좋습니다. 두 사진의 날짜도 함께 보내 드릴게요. |
| secondhand_hidden_defect#dialog[06] | formality_mix | 알겠습니다. 설명이 부족했네요. |
| subscription_cancel_charge#dialog[00] | formality_mix | 고객센터입니다. 무엇을 확인해 드릴까요? |
| subscription_cancel_charge#quest_subscription_cancel_charge_01.audioKo | formality_mix | 고객센터입니다. 무엇을 확인해 드릴까요? |
| subscription_cancel_charge#quest_subscription_cancel_charge_02.options[1].ko | formality_mix | 고객센터입니다. 무엇을 확인해 드릴까요? |
| taxi_slow_down#dialog[03] | formality_mix | 알겠습니다. 천천히 갈게요. |
| taxi_slow_down#quest_taxi_slow_down_02.options[3].ko | formality_mix | 알겠습니다. 천천히 갈게요. |
| train_seat_swap#dialog[05] | formality_mix | 알려 주셔서 감사합니다. 바로 옮길게요. |
| train_seat_swap#quest_train_seat_swap_03.targetKo | formality_mix | 알려 주셔서 감사합니다. 바로 옮길게요. |
| workload_allocation_hidden_labor#dialog[05] | formality_mix | 좋아요. 다음 회의록은 제가 맡겠습니다. |

## silben_puzzles.json

3건.

| id | 마커 | 문장 |
|---|---|---|
| skz_a2_006#v00 | josa_dup | 아이가 공주 그림을 그렸어요. |
| skz_a2_019#h20 | josa_dup | 파란 넥타이가 잘 어울려요. |
| skz_b1_006#h21 | josa_dup | 한국이랑 독일 문화 차이가 진짜 커요. |

## smalltalk.json

9건.

| id | 마커 | 문장 |
|---|---|---|
| smalltalk_b1_0043#followUp | formality_mix | 알겠습니다. 바로 가 볼게요. |
| smalltalk_b1_0045#followUp | formality_mix | 확인해 주셔서 감사합니다. 일정에 반영할게요. |
| smalltalk_b1_0051#followUp | formality_mix | 감사합니다. 인원을 확정하는 데 도움이 될 거예요. |
| smalltalk_b2_0024 | josa_dup | 나이가 드니까 조금만 무리해도 몸에 바로 티가 나더라고요. |
| smalltalk_b2_0095 | josa_dup | 선을 긋고도 사이가 나빠지지 않으려면 어떻게 말해야 할까요? |
| smalltalk_b2_0115#reply | formality_mix | 수요 변화와 규제, 지역별 소득도 함께 검토해야 합니다. |
| smalltalk_b2_0123#followUp | formality_mix | 네, 감사합니다. 여기서 기다릴게요. |
| smalltalk_b2_0123#reply | formality_mix | 확인해 보겠습니다. 잠시만 기다려 주세요. |
| smalltalk_c1_0063#reply | josa_dup | 평균 하나로는 긴급도와 지역 차이가 가려져요. |

## 요약

- 총 후보: **169건** (대상 파일 7개 전부 스캔, 후보 있는 파일 7개)

### 파일별 건수

- cloze.json: 57건
- grammar.csv: 1건
- korean_vocab.csv: 19건
- satz_sentences.json: 19건
- scenarios_*.json: 61건
- silben_puzzles.json: 3건
- smalltalk.json: 9건

### 마커별 건수

- dangling_stem: 0건
- particle_mismatch: 36건
- passive_pileup: 0건
- e_daehae: 0건
- josa_dup: 55건
- formality_mix: 76건
- level_length: 2건
- answer_repeat: 0건

### 시드 5건 회고 노트 (Task 2 에서 교정 완료, 교정 전 상태 기준)

Task 2(커밋 `55b703cc`/`1a2c67eb`/`2a235db5`)가 이미 고친 시드 5건은 이제
코퍼스에 없으므로 아래 표에는 나타나지 않는다. 어떤 마커가 교정 *전* 형태를
잡았을지 회고:

- **절하 (cloze_a1_0154)**: 교정 전 answer `절하` (완결 어절 아님, "절하다"
  절단) → **dangling_stem** 이 잡았을 것 (`절하` 가 `하` 로 끝나고
  `절하다` 가 CSV 표제어로 존재). 부수적으로 당시 distractor `성함을 묻`
  (조각, "묻"=받침 있음)도 당시 sentenceKo 조사 `는`(받침 없음 요구)과
  불합치해 **particle_mismatch** 가 함께 잡았을 것 — 다만 이건 "조각 오답"
  이라는 진짜 결함과는 별개의 우연한 포착.
- **이모티콘 (cloze_a1_0192)**: 교정 전 distractor `형부`(모음 끝) vs
  sentenceKo `＿＿＿은`(받침 필요) → **particle_mismatch** 가 잡았을 것.
  이후 1차 교정에서 대체 후보로 잘못 고른 `소포`(역시 모음 끝, 리뷰
  라운드 1에서 재수정됨)도 같은 이유로 **particle_mismatch** 가 잡았을
  것 — 이 마커가 리뷰에서 발견된 재발 결함까지 커버함을 보여준다.
- **층간소음 (cloze_a1_0239)**: 교정 전 distractor `복도`(모음 끝) vs
  sentenceKo `＿＿＿을`(받침 필요) → **particle_mismatch** 가 잡았을 것.
- **시아버지 (cloze_a1_0104)**: 교정 전 결함은 두 가지 — (a) 문맥 없이는
  어떤 웃어른도 답이 되는 **모호성**, (b) "현관까지 나오셨어요"라는 서술의
  **어투 이질감**(지시서 항목 7). 둘 다 이번 8개 마커 중 어느 것도 잡지
  못한다 — 결정적 패턴/받침 규칙으로는 검출 불가능한 의미·화용 층위의
  결함이라 Task 12 LLM 심사가 필요한 전형적 사례로 남겨둔다.
- **일정 충돌 (cloze_b1_0172)**: 교정 전 "충돌이 나자"→"충돌이 생겨서"
  (어색한 연어), "전화했어요"→"전화드렸어요"(존대 일관성 — `습니다`/`요`
  혼재가 아니라 같은 `-요` 등급 안에서의 압존법 불일치)는 둘 다 8개 마커
  범위 밖이다. formality_mix 는 `습니다`/`ㅂ니다` 계열 vs `요` **종결형
  혼재**만 잡도록 설계돼 있어 이 사례처럼 같은 종결형(`-요`) 안에서 존대
  대상이 달라지는 결함은 검출하지 못한다 — 마찬가지로 Task 12 심사 대상.
  **다만 이 항목은 이번 스캔이 별도로 살아있는 결함 1건을 새로 찾아냈다**:
  당시 distractor `방문 순서`(받침 없는 "서"로 끝남)가 빈칸 뒤 조사
  `이`(받침 필요)와 불합치 — Task 2 는 이 세 distractor 를 "형태 가능·
  문맥 불가 충족"으로 판단해 그대로 뒀지만 받침 정합은 별도로 검토되지
  않았었다. 즉 이 마커는 "교정 전" 회고용일 뿐 아니라 **Task 2 가 놓친
  결함**도 실제로 찾아냈다 — 이 리포트 최초 발행 직후 커밋 `319db213`
  (`fix(content): cloze_b1_0172 distractor 조사 정합 — 방문 순서 교체`,
  Task 3 가 아닌 별도 세션이 이 리포트를 보고 바로 반영)으로 이미 교정돼
  `방문 순서`→`명절 당번`(받침 있음)이 됐다 — 그래서 이 코퍼스를 다시
  스캔하면 더는 particle_mismatch 로 잡히지 않는다. 프리필터→즉시 수정
  이라는 의도된 순환이 실제로 작동한 사례로 남겨둔다.

결론: 8개 마커 중 정량적(받침·문자열·길이) 판정이 가능한 절하·이모티콘·
층간소음 3건은 재현 가능하게 잡히고(그리고 일정충돌도 별도 결함으로
잡힌다), 의미·화용 판단이 필요한 시아버지·일정충돌의 존대/연어 이슈는
설계상 이 프리필터의 범위 밖이다 — 이는 결함이 아니라 "결정적 프리필터 +
LLM 심사"라는 2단 구조가 의도한 분업이다.

### 마커 정밀도에 대한 정직한 경고 (오탐 상시 발생, 의도된 설계)

- **josa_dup**: `을를`·`이가`·`은는` 은 단순 부분 문자열 검사라, "이"로
  끝나는 명사(나이·아이·차이·넥타이…) 뒤에 주격 조사 `가` 가 붙으면
  (`나이가`·`아이가`·`차이가`) 오타 없이도 문자열 `이가` 가 그대로
  나타난다 — 브리프가 지정한 규칙 자체가 이런 합성어형 오탐을 걸러내지
  않는 단순 문자열 매칭이라, 아래 "마커별 건수"의 josa_dup 후보 중
  상당수가 이 유형이다. 의도적으로 필터링하지 않았다(정밀도를 높이려 예외 사전을
  만들면 결정성은 유지되지만 "간단한 규칙"이라는 브리프 취지를 벗어나고,
  진짜 오타도 우연히 걸러낼 위험이 있다) — Task 12 심사에서 대부분
  기각될 것으로 예상한다.
- **formality_mix**: `잘 먹었습니다`·`처음 뵙겠습니다`·`감사합니다` 같은
  고정 인사/관용구가 캐주얼한 서술 문장 안에 삽입 인용된 경우
  (`"...하고 인사했어요"` 류) 도 이 마커에 걸린다 — 화자가 실제로 발화한
  formal 문장을 casual 서술이 감싸는 구조는 한국어에서 완전히 자연스러우므로
  이런 경우는 대개 오탐이다. 반대로 한 화자의 연속된 두 문장이 문맥 전환
  없이 formal→casual 로 튀는 경우(예: `smalltalk_b1_0043#followUp`
  `알겠습니다. 바로 가 볼게요.`)는 진짜 후보로 보인다 — 두 패턴이 문자열
  수준에서는 구분 불가능해 마커 하나로 합쳐 냈다.

### 알려진 커버리지 공백 (리뷰 라운드 1 Minor)

- **particle_mismatch 가 시나리오 `luecken` 퀘스트의 fill-in 옵션까지
  확장되지 않는다.** `luecken` 퀘스트(`data.sentence`+`data.options`)는
  cloze 와 거의 동형이다 — 빈칸 뒤 조사와 각 옵션의 받침 유무를 대조하는
  게 원리상 가능하지만, 이번 스캔은 `sentence` 필드를 공통 5종 마커로만
  검사하고 `options`(정답+오답 조사/어미 후보)는 검사하지 않는다. 마커
  8종 중 가장 값진 발견을 낸 것이 particle_mismatch(835건, cloze 항목의
  46%)라는 점을 감안하면, 같은 구조의 `luecken` 도 비슷한 비율로 결함을
  숨기고 있을 가능성이 있다 — Task 12/13 에서 우선순위 있게 다룰 후보로
  남겨둔다(이번 태스크 범위 밖, 별도 확장 필요).

