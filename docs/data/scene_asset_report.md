# 시나리오 씬 에셋 감사 리포트

`python -X utf8 tool/audit_scene_assets.py`로 결정적으로 생성한다. 직접 편집하지 않는다.

전용 포스터는 시나리오 ID와 같은 파일명, 1536×1024 PNG, RGB/RGBA, 고유
바이트를 요구한다. 카테고리 포스터 15장도 같은 기술 규격과 승인된
SHA-256 바이트를 요구하며 런타임 폴백으로 사용한다.

## 요약

- canonical 시나리오: **178개**
- 전용 포스터: **0개**
- 카테고리 폴백: **178개**
- 누락/깨진 폴백: **0개**
- 엄격 이슈: **0건**

## 엄격 이슈

0건.

## 샤드별 시나리오

- scenarios_a1.json: 29개
- scenarios_a2.json: 29개
- scenarios_b1.json: 30개
- scenarios_b2.json: 30개
- scenarios_c1.json: 30개
- scenarios_c2.json: 30개

## 카테고리 런타임 폴백

- airport: 2개
- bank: 1개
- cafe: 16개
- convenience: 1개
- directions: 7개
- home: 56개
- hotel: 1개
- market: 7개
- office: 57개
- pharmacy: 3개
- restaurant: 8개
- salon: 1개
- station: 9개
- taxi: 3개
- theme_park: 6개

## 기존 비디오 루프 참조 상태 (감사 전용)

- scene_*.mp4: 0개
- 규약 밖 루프 파일: 5개
- 전용 루프 해석: 0개
- 카테고리 루프 해석: 0개
- 루프 없는 안전 폴백: 178개
- backdrop 없는 루프 없음: 0개
- 고아 scene 루프: 0개

## 생성 근거 SHA-256

- `assets/data/scenarios_a1.json`: `34ac5a548855408e96638db6281a9f083455bbc1f0541f64fb0105df7ed6266e`
- `assets/data/scenarios_a2.json`: `37644e042e0ca8f3893b8b15809cbab42a21e2230cc5b656c598e12d5ef3dfac`
- `assets/data/scenarios_b1.json`: `71adb4450215737899892cda550231f169c717c12e3be55c77c7d0a1a03c7af2`
- `assets/data/scenarios_b2.json`: `93ce4f6bfa4d66f87dd63904839c1ed0583176605d5d0830caab513a8ad6d409`
- `assets/data/scenarios_c1.json`: `9b46888c14017bc19c06ca0d57101c1364bd92de43756a8485730554234c0a31`
- `assets/data/scenarios_c2.json`: `764307bf0c6d740e62cfd0779a86a1737721a0e90aafebe71e584ddbb30f0144`
- `docs/data/scene_category_poster_lock.json`: `1036664f6008281cfcd8f969cad46953c0ed291e5047b1ad48a02555ec1432db`
- `lib/services/scene_asset_resolver.dart`: `7f5a940853c25aaf4fbb81e8ccb7c1fcd951ea1570559c658b61d9e77aa185be`

## 시나리오별 해석

| 샤드 | ID | 레벨 | backdrop | 상태 | 해석 경로 | 크기/모드 | SHA-256 | runtimeEligible |
|---|---|---|---|---|---|---|---|---|
| scenarios_a1.json | a1_theme_park_date_choices | a1 | theme_park | fallback | assets/illustrations/scenes/theme_park.png | 1536×1024 RGB | 95b947d5f5631997eb4b777aee5791d9b9ceed9c86cbbaf74e5645bef0d1a434 | true |
| scenarios_a1.json | a1_w10_eat | a1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_a1.json | a1_w10_fandom | a1 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_a1.json | a1_w10_numbers | a1 | salon | fallback | assets/illustrations/scenes/salon.png | 1536×1024 RGB | 0c78d6e50434ae7e3ee566997c18936976731608b436919d72a623ab1c0858d9 | true |
| scenarios_a1.json | a1_w10_partner | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | a1_w10_phone | a1 | restaurant | fallback | assets/illustrations/scenes/restaurant.png | 1536×1024 RGB | 61e4aa4e94e01df9cb51e40438ce41c3a260e4b92437608d97a165bf208f61f8 | true |
| scenarios_a1.json | a1_w10_repeat | a1 | pharmacy | fallback | assets/illustrations/scenes/pharmacy.png | 1536×1024 RGB | 62771ecbe9cfcdc9653ad24c509200edf728ae5aad194a8209da6e3367055a92 | true |
| scenarios_a1.json | a1_w10_taxi_stay | a1 | taxi | fallback | assets/illustrations/scenes/taxi.png | 1536×1024 RGB | 0267b90eb07bb40a3141023c21943e643e64295296462bf7736f3534105fe356 | true |
| scenarios_a1.json | a1_w10_wayfinding | a1 | directions | fallback | assets/illustrations/scenes/directions.png | 1536×1024 RGB | f2500c600eada342bc1a4102996d83d5cfdf068814f5d4247f230bebb66dde9c | true |
| scenarios_a1.json | airport_arrival | a1 | airport | fallback | assets/illustrations/scenes/airport.png | 1536×1024 RGB | 2233a48b88afd5a0474f4e49298aa5592d6bf50b09aa110b8742d45af24f6eff | true |
| scenarios_a1.json | bakery_payment_bag | a1 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_a1.json | bakery_queue | a1 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_a1.json | break_glass_apology | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | bunshik_tteokbokki | a1 | restaurant | fallback | assets/illustrations/scenes/restaurant.png | 1536×1024 RGB | 61e4aa4e94e01df9cb51e40438ce41c3a260e4b92437608d97a165bf208f61f8 | true |
| scenarios_a1.json | cafe_dessert_sold_out | a1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_a1.json | clarify_repeat | a1 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a1.json | dance_class_register | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | favorite_korean_music | a1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_a1.json | first_class_meeting | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | home_morning_routine | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | introduce_yourself | a1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_a1.json | kakao_contact_after_class | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | korea_stay_smalltalk | a1 | restaurant | fallback | assets/illustrations/scenes/restaurant.png | 1536×1024 RGB | 61e4aa4e94e01df9cb51e40438ce41c3a260e4b92437608d97a165bf208f61f8 | true |
| scenarios_a1.json | mart_grocery | a1 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_a1.json | meeting_time | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | subway_step_apology | a1 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a1.json | survival_day_capstone | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | taxi_kakao | a1 | taxi | fallback | assets/illustrations/scenes/taxi.png | 1536×1024 RGB | 0267b90eb07bb40a3141023c21943e643e64295296462bf7736f3534105fe356 | true |
| scenarios_a1.json | umbrella_weather | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | a2_theme_park_date_break | a2 | theme_park | fallback | assets/illustrations/scenes/theme_park.png | 1536×1024 RGB | 95b947d5f5631997eb4b777aee5791d9b9ceed9c86cbbaf74e5645bef0d1a434 | true |
| scenarios_a2.json | a2_w10_apt | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | a2_w10_booking | a2 | restaurant | fallback | assets/illustrations/scenes/restaurant.png | 1536×1024 RGB | 61e4aa4e94e01df9cb51e40438ce41c3a260e4b92437608d97a165bf208f61f8 | true |
| scenarios_a2.json | a2_w10_buy | a2 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_a2.json | a2_w10_enrolment | a2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_a2.json | a2_w10_fandom | a2 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_a2.json | a2_w10_friends | a2 | restaurant | fallback | assets/illustrations/scenes/restaurant.png | 1536×1024 RGB | 61e4aa4e94e01df9cb51e40438ce41c3a260e4b92437608d97a165bf208f61f8 | true |
| scenarios_a2.json | a2_w10_money | a2 | bank | fallback | assets/illustrations/scenes/bank.png | 1536×1024 RGB | 45dd189bc46130295355e001d61962fa6488701440161e8e664e83ca643e4dbf | true |
| scenarios_a2.json | a2_w10_partner | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | clothing_refund_size | a2 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_a2.json | convenience_parcel_pickup | a2 | convenience | fallback | assets/illustrations/scenes/convenience.png | 1536×1024 RGB | 917585b44e4d10b9cd5223baae804d6b7b961767574679771df347215f0307d2 | true |
| scenarios_a2.json | delivery_dinner_spicy | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | email_attachment_twice | a2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_a2.json | favorite_drama_chat | a2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_a2.json | forgot_house_key | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | forgot_presentation_cable | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | friend_cancelled_plan | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | group_chat_photo_permission | a2 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_a2.json | gym_class_cancel | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | jeju_bus_missed | a2 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a2.json | library_card_problem | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | package_wrong_door | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | pharmacy_cold_medicine | a2 | pharmacy | fallback | assets/illustrations/scenes/pharmacy.png | 1536×1024 RGB | 62771ecbe9cfcdc9653ad24c509200edf728ae5aad194a8209da6e3367055a92 | true |
| scenarios_a2.json | plans_with_friend | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | running_late | a2 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a2.json | samgyeopsal_first_time | a2 | restaurant | fallback | assets/illustrations/scenes/restaurant.png | 1536×1024 RGB | 61e4aa4e94e01df9cb51e40438ce41c3a260e4b92437608d97a165bf208f61f8 | true |
| scenarios_a2.json | shared_document_old_version | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | taxi_slow_down | a2 | taxi | fallback | assets/illustrations/scenes/taxi.png | 1536×1024 RGB | 0267b90eb07bb40a3141023c21943e643e64295296462bf7736f3534105fe356 | true |
| scenarios_a2.json | train_seat_swap | a2 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_b1.json | ai_summary_wrong_fact | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | apartment_recycling_mixup | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | b1_theme_park_date_thrill | b1 | theme_park | fallback | assets/illustrations/scenes/theme_park.png | 1536×1024 RGB | 95b947d5f5631997eb4b777aee5791d9b9ceed9c86cbbaf74e5645bef0d1a434 | true |
| scenarios_b1.json | b1_w10_bill | b1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_b1.json | b1_w10_cancellation | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_w10_fandom | b1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_b1.json | b1_w10_form | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_w10_friends | b1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_b1.json | b1_w10_incident | b1 | directions | fallback | assets/illustrations/scenes/directions.png | 1536×1024 RGB | f2500c600eada342bc1a4102996d83d5cfdf068814f5d4247f230bebb66dde9c | true |
| scenarios_b1.json | b1_w10_insurance | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | b1_w10_partner | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | b1_w10_repair | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | birthday_expectation_gap | b1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_b1.json | cancelled_trip_hurt_feelings | b1 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_b1.json | community_festival_shift | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | company_instagram_wrong_account | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | date_or_friendly_coffee | b1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_b1.json | food_delivery_wrong_order | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | jeju_rain_plan_change | b1 | hotel | fallback | assets/illustrations/scenes/hotel.png | 1536×1024 RGB | ff69b18019a2e59ca2f78dbefb6ddc4faad8702d369710e9e6df7c363daff3cb | true |
| scenarios_b1.json | ktx_sold_out_alternative | b1 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_b1.json | noisy_neighbor_evening | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | park_pet_manners | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | reel_caption_misunderstanding | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | running_injury_training_plan | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | secondhand_hidden_defect | b1 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_b1.json | shared_cup_recycling | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | speech_level_after_friendship | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | subscription_cancel_charge | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | team_update_indirect_speech | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | work_message_too_direct | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | accessible_festival_route | b2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b2.json | ai_image_disclosure | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_theme_park_date_safety | b2 | theme_park | fallback | assets/illustrations/scenes/theme_park.png | 1536×1024 RGB | 95b947d5f5631997eb4b777aee5791d9b9ceed9c86cbbaf74e5645bef0d1a434 | true |
| scenarios_b2.json | b2_w10_authorities | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_w10_fandom | b2 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_b2.json | b2_w10_health | b2 | pharmacy | fallback | assets/illustrations/scenes/pharmacy.png | 1536×1024 RGB | 62771ecbe9cfcdc9653ad24c509200edf728ae5aad194a8209da6e3367055a92 | true |
| scenarios_b2.json | b2_w10_hiring | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_w10_negotiate | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_w10_notice | b2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b2.json | b2_w10_partner | b2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b2.json | b2_w10_privacy | b2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b2.json | b2_w10_travel | b2 | airport | fallback | assets/illustrations/scenes/airport.png | 1536×1024 RGB | 2233a48b88afd5a0474f4e49298aa5592d6bf50b09aa110b8742d45af24f6eff | true |
| scenarios_b2.json | brand_private_account_boundary | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | community_event_compromise | b2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b2.json | delivery_refund_evidence | b2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b2.json | direct_feedback_misread | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | feedback_specific_example | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | filming_permission | b2 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_b2.json | freelance_scope_change | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | fremdschaemen_live | b2 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_b2.json | library_quiet_zone_conflict | b2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b2.json | meeting_disagreement_evidence | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | meeting_opening_context | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | neighborhood_filming_notice | b2 | directions | fallback | assets/illustrations/scenes/directions.png | 1536×1024 RGB | f2500c600eada342bc1a4102996d83d5cfdf068814f5d4247f230bebb66dde9c | true |
| scenarios_b2.json | partner_family_titles | b2 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_b2.json | portfolio_interview_gap | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | recycling_policy_pilot | b2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b2.json | rental_repair_deposit | b2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b2.json | train_delay_connection | b2 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_b2.json | wedding_invitation_expectation | b2 | restaurant | fallback | assets/illustrations/scenes/restaurant.png | 1536×1024 RGB | 61e4aa4e94e01df9cb51e40438ce41c3a260e4b92437608d97a165bf208f61f8 | true |
| scenarios_c1.json | after_hours_messages | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | ai_interview_screening_transparency | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | ai_translation_voice_loss | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | anonymous_survey_trust | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_theme_park_date_next_time | c1 | theme_park | fallback | assets/illustrations/scenes/theme_park.png | 1536×1024 RGB | 95b947d5f5631997eb4b777aee5791d9b9ceed9c86cbbaf74e5645bef0d1a434 | true |
| scenarios_c1.json | c1_w10_access | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_w10_clinical | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_w10_conflict_interest | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_w10_facework | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_w10_fandom | c1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_c1.json | c1_w10_friends | c1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_c1.json | c1_w10_labor | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_w10_methodology | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_w10_uncertainty | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | deepfake_verification | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | delivery_rider_safety_tradeoff | c1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_c1.json | fan_translation_credit | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | gentrification_storefront | c1 | directions | fallback | assets/illustrations/scenes/directions.png | 1536×1024 RGB | f2500c600eada342bc1a4102996d83d5cfdf068814f5d4247f230bebb66dde9c | true |
| scenarios_c1.json | heatwave_shelter_access | c1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_c1.json | kiosk_generation_access | c1 | restaurant | fallback | assets/illustrations/scenes/restaurant.png | 1536×1024 RGB | 61e4aa4e94e01df9cb51e40438ce41c3a260e4b92437608d97a165bf208f61f8 | true |
| scenarios_c1.json | museum_label_multiple_views | c1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_c1.json | nightlife_noise_balance | c1 | directions | fallback | assets/illustrations/scenes/directions.png | 1536×1024 RGB | f2500c600eada342bc1a4102996d83d5cfdf068814f5d4247f230bebb66dde9c | true |
| scenarios_c1.json | platform_moderation_appeal | c1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_c1.json | public_consultation_access | c1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_c1.json | research_limits_presentation | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | school_phone_rule | c1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_c1.json | tradition_reinterpreted_stage | c1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_c1.json | training_data_copyright | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | workload_allocation_hidden_labor | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | youth_housing_plain_language | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | ai_hiring_appeal | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | automated_benefit_denial | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | autonomous_delivery_liability | c2 | directions | fallback | assets/illustrations/scenes/directions.png | 1536×1024 RGB | f2500c600eada342bc1a4102996d83d5cfdf068814f5d4247f230bebb66dde9c | true |
| scenarios_c2.json | c2_theme_park_date_reflection | c2 | theme_park | fallback | assets/illustrations/scenes/theme_park.png | 1536×1024 RGB | 95b947d5f5631997eb4b777aee5791d9b9ceed9c86cbbaf74e5645bef0d1a434 | true |
| scenarios_c2.json | c2_w10_aesthetic | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_w10_fandom | c2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_c2.json | c2_w10_friends | c2 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_c2.json | c2_w10_history | c2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_c2.json | c2_w10_impact | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_w10_jurisdiction | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_w10_limitation | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_w10_mandate | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_w10_record | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | causal_claim_headline | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | central_local_disaster_responsibility | c2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_c2.json | climate_model_local_decision | c2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_c2.json | diaspora_name_identity | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | emergency_price_controls | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | fact_check_label_power | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | family_memory_conflict | c2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_c2.json | hidden_gem_local_impact | c2 | directions | fallback | assets/illustrations/scenes/directions.png | 1536×1024 RGB | f2500c600eada342bc1a4102996d83d5cfdf068814f5d4247f230bebb66dde9c | true |
| scenarios_c2.json | housing_tax_intergenerational | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | medical_uncertainty_consent | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | passive_voice_accountability | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | poll_question_framing | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | protest_order_and_rights | c2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_c2.json | relationship_story_reframing | c2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_c2.json | replication_failure_response | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | we_translation_identity | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | welfare_fraud_presumption | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
