# 시나리오 씬 에셋 감사 리포트

`python -X utf8 tool/audit_scene_assets.py`로 결정적으로 생성한다. 직접 편집하지 않는다.

전용 포스터는 시나리오 ID와 같은 파일명, 1536×1024 PNG, RGB/RGBA, 고유
바이트를 요구한다. 카테고리 포스터 15장도 같은 기술 규격과 승인된
SHA-256 바이트를 요구하며 런타임 폴백으로 사용한다.

## 요약

- canonical 시나리오: **419개**
- 전용 포스터: **0개**
- 카테고리 폴백: **419개**
- 누락/깨진 폴백: **0개**
- 엄격 이슈: **0건**

## 엄격 이슈

0건.

## 샤드별 시나리오

- scenarios_a1.json: 88개
- scenarios_a2.json: 83개
- scenarios_b1.json: 76개
- scenarios_b2.json: 74개
- scenarios_c1.json: 51개
- scenarios_c2.json: 47개

## 카테고리 런타임 폴백

- airport: 5개
- bank: 3개
- cafe: 36개
- convenience: 14개
- directions: 8개
- home: 86개
- hotel: 8개
- market: 22개
- office: 172개
- pharmacy: 9개
- restaurant: 13개
- salon: 3개
- station: 27개
- taxi: 7개
- theme_park: 6개

## 기존 비디오 루프 참조 상태 (감사 전용)

- scene_*.mp4: 5개
- 규약 밖 루프 파일: 8개
- 전용 루프 해석: 0개
- 카테고리 루프 해석: 87개
- 루프 없는 안전 폴백: 332개
- backdrop 없는 루프 없음: 0개
- 고아 scene 루프: 0개

## 생성 근거 SHA-256

- `assets/data/scenarios_a1.json`: `529317a5f2ec02b4f2492b6bef345b67c705fbd8e8079ba72d470901a62606f4`
- `assets/data/scenarios_a2.json`: `ade787acaae2d5f3b6a68a79956bdb142267df90f0228663051d5c1a36ccb55f`
- `assets/data/scenarios_b1.json`: `39493ce38b26e875f9661a8ae1654f2ba27b59092aac0d68be48e57b33d70a2a`
- `assets/data/scenarios_b2.json`: `201d40b1dd9522afc32ef260cf7dd13dc8300bc5052c81b038b5ffd9ac56559d`
- `assets/data/scenarios_c1.json`: `2c5552a01492c70bf8c7bb0ffdf34595fce4c8c5e99720ad5669068136b9c29d`
- `assets/data/scenarios_c2.json`: `8e75de774cb7e6cf58c7a717eceac75aa540c9dc96a0c28493033ecb694c90ca`
- `docs/data/scene_category_poster_lock.json`: `1036664f6008281cfcd8f969cad46953c0ed291e5047b1ad48a02555ec1432db`
- `lib/services/scene_asset_resolver.dart`: `7f5a940853c25aaf4fbb81e8ccb7c1fcd951ea1570559c658b61d9e77aa185be`

## 시나리오별 해석

| 샤드 | ID | 레벨 | backdrop | 상태 | 해석 경로 | 크기/모드 | SHA-256 | runtimeEligible |
|---|---|---|---|---|---|---|---|---|
| scenarios_a1.json | a1_airport_cart | a1 | airport | fallback | assets/illustrations/scenes/airport.png | 1536×1024 RGB | 2233a48b88afd5a0474f4e49298aa5592d6bf50b09aa110b8742d45af24f6eff | true |
| scenarios_a1.json | a1_ask_again | a1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_a1.json | a1_bus_late | a1 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a1.json | a1_cafe_wifi | a1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_a1.json | a1_cancel_walk | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | a1_card_topup | a1 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a1.json | a1_city_service_route_batch20 | a1 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a1.json | a1_class_pencil | a1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_a1.json | a1_daily_recycling_day | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | a1_dating_what_to_call_you | a1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_a1.json | a1_direction_left | a1 | directions | fallback | assets/illustrations/scenes/directions.png | 1536×1024 RGB | f2500c600eada342bc1a4102996d83d5cfdf068814f5d4247f230bebb66dde9c | true |
| scenarios_a1.json | a1_door_bell | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | a1_dust_mask | a1 | convenience | fallback | assets/illustrations/scenes/convenience.png | 1536×1024 RGB | 917585b44e4d10b9cd5223baae804d6b7b961767574679771df347215f0307d2 | true |
| scenarios_a1.json | a1_excuse_pass | a1 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_a1.json | a1_floor_number | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | a1_friends_major_and_number | a1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_a1.json | a1_gaming_one_more_round | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | a1_gate_code | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | a1_hall_shoes | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | a1_home_light | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | a1_hotel_key | a1 | hotel | fallback | assets/illustrations/scenes/hotel.png | 1536×1024 RGB | ff69b18019a2e59ca2f78dbefb6ddc4faad8702d369710e9e6df7c363daff3cb | true |
| scenarios_a1.json | a1_kpop_my_bias | a1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_a1.json | a1_last_train | a1 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a1.json | a1_late_text | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | a1_locker_key | a1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_a1.json | a1_market_bag | a1 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_a1.json | a1_mask_pack | a1 | pharmacy | fallback | assets/illustrations/scenes/pharmacy.png | 1536×1024 RGB | 62771ecbe9cfcdc9653ad24c509200edf728ae5aad194a8209da6e3367055a92 | true |
| scenarios_a1.json | a1_meet_station | a1 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a1.json | a1_neighbor_box | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | a1_numbers_floor_and_room | a1 | hotel | fallback | assets/illustrations/scenes/hotel.png | 1536×1024 RGB | ff69b18019a2e59ca2f78dbefb6ddc4faad8702d369710e9e6df7c363daff3cb | true |
| scenarios_a1.json | a1_numbers_how_many_left | a1 | convenience | fallback | assets/illustrations/scenes/convenience.png | 1536×1024 RGB | 917585b44e4d10b9cd5223baae804d6b7b961767574679771df347215f0307d2 | true |
| scenarios_a1.json | a1_numbers_open_hours | a1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_a1.json | a1_numbers_total_price | a1 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_a1.json | a1_office_print | a1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_a1.json | a1_parcel_weight | a1 | convenience | fallback | assets/illustrations/scenes/convenience.png | 1536×1024 RGB | 917585b44e4d10b9cd5223baae804d6b7b961767574679771df347215f0307d2 | true |
| scenarios_a1.json | a1_partner_first_door | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | a1_partner_gift_too_big | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | a1_partner_more_side_dishes | a1 | restaurant | fallback | assets/illustrations/scenes/restaurant.png | 1536×1024 RGB | 61e4aa4e94e01df9cb51e40438ce41c3a260e4b92437608d97a165bf208f61f8 | true |
| scenarios_a1.json | a1_partner_new_year_money | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | a1_partner_seollal_bow | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | a1_partner_songpyeon_too_big | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | a1_partner_wrong_seat | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | a1_pharmacy_hours | a1 | pharmacy | fallback | assets/illustrations/scenes/pharmacy.png | 1536×1024 RGB | 62771ecbe9cfcdc9653ad24c509200edf728ae5aad194a8209da6e3367055a92 | true |
| scenarios_a1.json | a1_pharmacy_ointment | a1 | pharmacy | fallback | assets/illustrations/scenes/pharmacy.png | 1536×1024 RGB | 62771ecbe9cfcdc9653ad24c509200edf728ae5aad194a8209da6e3367055a92 | true |
| scenarios_a1.json | a1_phone_call_later | a1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_a1.json | a1_phone_read_back_address | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | a1_phone_text_instead | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | a1_phone_wrong_number | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | a1_platform_line | a1 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a1.json | a1_post_queue | a1 | convenience | fallback | assets/illustrations/scenes/convenience.png | 1536×1024 RGB | 917585b44e4d10b9cd5223baae804d6b7b961767574679771df347215f0307d2 | true |
| scenarios_a1.json | a1_rain_jacket | a1 | convenience | fallback | assets/illustrations/scenes/convenience.png | 1536×1024 RGB | 917585b44e4d10b9cd5223baae804d6b7b961767574679771df347215f0307d2 | true |
| scenarios_a1.json | a1_register_first_day_choice | a1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_a1.json | a1_rice_shop | a1 | restaurant | fallback | assets/illustrations/scenes/restaurant.png | 1536×1024 RGB | 61e4aa4e94e01df9cb51e40438ce41c3a260e4b92437608d97a165bf208f61f8 | true |
| scenarios_a1.json | a1_slow_speech | a1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_a1.json | a1_sorry_late | a1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_a1.json | a1_stamp_ask | a1 | convenience | fallback | assets/illustrations/scenes/convenience.png | 1536×1024 RGB | 917585b44e4d10b9cd5223baae804d6b7b961767574679771df347215f0307d2 | true |
| scenarios_a1.json | a1_station_rest | a1 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a1.json | a1_submit_name | a1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_a1.json | a1_subway_exit | a1 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a1.json | a1_taxi_address | a1 | taxi | fallback | assets/illustrations/scenes/taxi.png | 1536×1024 RGB | 0267b90eb07bb40a3141023c21943e643e64295296462bf7736f3534105fe356 | true |
| scenarios_a1.json | a1_tea_order | a1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_a1.json | a1_thanks_seat | a1 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a1.json | a1_theme_park_date_choices | a1 | theme_park | fallback | assets/illustrations/scenes/theme_park.png | 1536×1024 RGB | 95b947d5f5631997eb4b777aee5791d9b9ceed9c86cbbaf74e5645bef0d1a434 | true |
| scenarios_a1.json | a1_trash_sort | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | a1_water_shop | a1 | convenience | fallback | assets/illustrations/scenes/convenience.png | 1536×1024 RGB | 917585b44e4d10b9cd5223baae804d6b7b961767574679771df347215f0307d2 | true |
| scenarios_a1.json | a1_wayfinding_exit_number | a1 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a1.json | a1_wayfinding_how_long_walk | a1 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a1.json | a1_wayfinding_sign_says | a1 | directions | fallback | assets/illustrations/scenes/directions.png | 1536×1024 RGB | f2500c600eada342bc1a4102996d83d5cfdf068814f5d4247f230bebb66dde9c | true |
| scenarios_a1.json | a1_wayfinding_this_way_right | a1 | directions | fallback | assets/illustrations/scenes/directions.png | 1536×1024 RGB | f2500c600eada342bc1a4102996d83d5cfdf068814f5d4247f230bebb66dde9c | true |
| scenarios_a1.json | a1_weather_layer | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | a1_weekend_rain | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | a1_whiteboard_word | a1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_a1.json | a1_youtube_shorts_last_night | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | airport_arrival | a1 | airport | fallback | assets/illustrations/scenes/airport.png | 1536×1024 RGB | 2233a48b88afd5a0474f4e49298aa5592d6bf50b09aa110b8742d45af24f6eff | true |
| scenarios_a1.json | bunshik_tteokbokki | a1 | restaurant | fallback | assets/illustrations/scenes/restaurant.png | 1536×1024 RGB | 61e4aa4e94e01df9cb51e40438ce41c3a260e4b92437608d97a165bf208f61f8 | true |
| scenarios_a1.json | clarify_repeat | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | clinic_safety | a1 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_a1.json | convenience_store | a1 | convenience | fallback | assets/illustrations/scenes/convenience.png | 1536×1024 RGB | 917585b44e4d10b9cd5223baae804d6b7b961767574679771df347215f0307d2 | true |
| scenarios_a1.json | delivery_address_confirmation | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | first_class_meeting | a1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_a1.json | home_morning_routine | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | hotel_checkin | a1 | hotel | fallback | assets/illustrations/scenes/hotel.png | 1536×1024 RGB | ff69b18019a2e59ca2f78dbefb6ddc4faad8702d369710e9e6df7c363daff3cb | true |
| scenarios_a1.json | introduce_yourself | a1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_a1.json | mart_grocery | a1 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_a1.json | phone_messenger_reply | a1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a1.json | survival_day_capstone | a1 | directions | fallback | assets/illustrations/scenes/directions.png | 1536×1024 RGB | f2500c600eada342bc1a4102996d83d5cfdf068814f5d4247f230bebb66dde9c | true |
| scenarios_a1.json | taxi_kakao | a1 | taxi | fallback | assets/illustrations/scenes/taxi.png | 1536×1024 RGB | 0267b90eb07bb40a3141023c21943e643e64295296462bf7736f3534105fe356 | true |
| scenarios_a1.json | titles_relationship_distance | a1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_a2.json | a2_airport_sim | a2 | airport | fallback | assets/illustrations/scenes/airport.png | 1536×1024 RGB | 2233a48b88afd5a0474f4e49298aa5592d6bf50b09aa110b8742d45af24f6eff | true |
| scenarios_a2.json | a2_apt_sticker | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | a2_auto_debit | a2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_a2.json | a2_bank_number | a2 | bank | fallback | assets/illustrations/scenes/bank.png | 1536×1024 RGB | 45dd189bc46130295355e001d61962fa6488701440161e8e664e83ca643e4dbf | true |
| scenarios_a2.json | a2_bill_high | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | a2_booking_change_date | a2 | hotel | fallback | assets/illustrations/scenes/hotel.png | 1536×1024 RGB | ff69b18019a2e59ca2f78dbefb6ddc4faad8702d369710e9e6df7c363daff3cb | true |
| scenarios_a2.json | a2_booking_extra_person | a2 | restaurant | fallback | assets/illustrations/scenes/restaurant.png | 1536×1024 RGB | 61e4aa4e94e01df9cb51e40438ce41c3a260e4b92437608d97a165bf208f61f8 | true |
| scenarios_a2.json | a2_booking_no_show_fee | a2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_a2.json | a2_booking_table_time | a2 | restaurant | fallback | assets/illustrations/scenes/restaurant.png | 1536×1024 RGB | 61e4aa4e94e01df9cb51e40438ce41c3a260e4b92437608d97a165bf208f61f8 | true |
| scenarios_a2.json | a2_booth_line | a2 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_a2.json | a2_cafe_plug | a2 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_a2.json | a2_card_balance | a2 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a2.json | a2_contract_read | a2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_a2.json | a2_convenience_copy | a2 | convenience | fallback | assets/illustrations/scenes/convenience.png | 1536×1024 RGB | 917585b44e4d10b9cd5223baae804d6b7b961767574679771df347215f0307d2 | true |
| scenarios_a2.json | a2_daily_late_delivery | a2 | convenience | fallback | assets/illustrations/scenes/convenience.png | 1536×1024 RGB | 917585b44e4d10b9cd5223baae804d6b7b961767574679771df347215f0307d2 | true |
| scenarios_a2.json | a2_data_roam | a2 | convenience | fallback | assets/illustrations/scenes/convenience.png | 1536×1024 RGB | 917585b44e4d10b9cd5223baae804d6b7b961767574679771df347215f0307d2 | true |
| scenarios_a2.json | a2_dating_slow_replies | a2 | restaurant | fallback | assets/illustrations/scenes/restaurant.png | 1536×1024 RGB | 61e4aa4e94e01df9cb51e40438ce41c3a260e4b92437608d97a165bf208f61f8 | true |
| scenarios_a2.json | a2_direction_bus | a2 | directions | fallback | assets/illustrations/scenes/directions.png | 1536×1024 RGB | f2500c600eada342bc1a4102996d83d5cfdf068814f5d4247f230bebb66dde9c | true |
| scenarios_a2.json | a2_dye_dark | a2 | salon | fallback | assets/illustrations/scenes/salon.png | 1536×1024 RGB | 0c78d6e50434ae7e3ee566997c18936976731608b436919d72a623ab1c0858d9 | true |
| scenarios_a2.json | a2_enrolment_change_class | a2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_a2.json | a2_enrolment_class_signup | a2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_a2.json | a2_enrolment_level_test | a2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_a2.json | a2_enrolment_missing_document | a2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_a2.json | a2_festival_stamp | a2 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_a2.json | a2_flat_viewing_terms_batch20 | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | a2_food_bag | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | a2_found_umbrella | a2 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a2.json | a2_friends_weekend_slot | a2 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_a2.json | a2_front_desk | a2 | hotel | fallback | assets/illustrations/scenes/hotel.png | 1536×1024 RGB | ff69b18019a2e59ca2f78dbefb6ddc4faad8702d369710e9e6df7c363daff3cb | true |
| scenarios_a2.json | a2_gaming_cant_connect | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | a2_guest_pass | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | a2_gym_lock | a2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_a2.json | a2_hair_time | a2 | salon | fallback | assets/illustrations/scenes/salon.png | 1536×1024 RGB | 0c78d6e50434ae7e3ee566997c18936976731608b436919d72a623ab1c0858d9 | true |
| scenarios_a2.json | a2_handover_note | a2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_a2.json | a2_hotel_late | a2 | hotel | fallback | assets/illustrations/scenes/hotel.png | 1536×1024 RGB | ff69b18019a2e59ca2f78dbefb6ddc4faad8702d369710e9e6df7c363daff3cb | true |
| scenarios_a2.json | a2_hours_six | a2 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_a2.json | a2_id_pickup | a2 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a2.json | a2_kpop_concert_queue | a2 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a2.json | a2_label_phone | a2 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a2.json | a2_lost_wallet | a2 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a2.json | a2_manager_leave | a2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_a2.json | a2_market_change | a2 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_a2.json | a2_night_pay | a2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_a2.json | a2_office_badge | a2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_a2.json | a2_partner_banmal_slip | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | a2_partner_group_chat_join | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | a2_partner_hanbok_rental | a2 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_a2.json | a2_partner_holiday_train | a2 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a2.json | a2_partner_leftover_bags | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | a2_partner_morning_greeting | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | a2_phone_plan | a2 | convenience | fallback | assets/illustrations/scenes/convenience.png | 1536×1024 RGB | 917585b44e4d10b9cd5223baae804d6b7b961767574679771df347215f0307d2 | true |
| scenarios_a2.json | a2_plan_weather_change | a2 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_a2.json | a2_quiet_ten | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | a2_rain_cancel | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | a2_recycle_box | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | a2_restaurant_split | a2 | restaurant | fallback | assets/illustrations/scenes/restaurant.png | 1536×1024 RGB | 61e4aa4e94e01df9cb51e40438ce41c3a260e4b92437608d97a165bf208f61f8 | true |
| scenarios_a2.json | a2_salon_cut | a2 | salon | fallback | assets/illustrations/scenes/salon.png | 1536×1024 RGB | 0c78d6e50434ae7e3ee566997c18936976731608b436919d72a623ab1c0858d9 | true |
| scenarios_a2.json | a2_seat_hold | a2 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_a2.json | a2_shift_table | a2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_a2.json | a2_station_lost | a2 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a2.json | a2_stretch_start | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | a2_taxi_wait | a2 | taxi | fallback | assets/illustrations/scenes/taxi.png | 1536×1024 RGB | 0267b90eb07bb40a3141023c21943e643e64295296462bf7736f3534105fe356 | true |
| scenarios_a2.json | a2_tea_taste | a2 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_a2.json | a2_theme_park_date_break | a2 | theme_park | fallback | assets/illustrations/scenes/theme_park.png | 1536×1024 RGB | 95b947d5f5631997eb4b777aee5791d9b9ceed9c86cbbaf74e5645bef0d1a434 | true |
| scenarios_a2.json | a2_transfer_limit | a2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_a2.json | a2_volunteer_vest | a2 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_a2.json | a2_water_set | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | a2_youtube_send_the_link | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | cafe_starbucks_basic | a2 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_a2.json | cafe_study | a2 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_a2.json | feeling_sick | a2 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_a2.json | friend_birthday | a2 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_a2.json | gym_signup | a2 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_a2.json | ktx_ticket | a2 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a2.json | lost_phone | a2 | directions | fallback | assets/illustrations/scenes/directions.png | 1536×1024 RGB | f2500c600eada342bc1a4102996d83d5cfdf068814f5d4247f230bebb66dde9c | true |
| scenarios_a2.json | myeongdong_shopping | a2 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_a2.json | pharmacy_headache | a2 | pharmacy | fallback | assets/illustrations/scenes/pharmacy.png | 1536×1024 RGB | 62771ecbe9cfcdc9653ad24c509200edf728ae5aad194a8209da6e3367055a92 | true |
| scenarios_a2.json | plans_with_friend | a2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_a2.json | rent_bank_transfer | a2 | bank | fallback | assets/illustrations/scenes/bank.png | 1536×1024 RGB | 45dd189bc46130295355e001d61962fa6488701440161e8e664e83ca643e4dbf | true |
| scenarios_a2.json | running_late | a2 | directions | fallback | assets/illustrations/scenes/directions.png | 1536×1024 RGB | f2500c600eada342bc1a4102996d83d5cfdf068814f5d4247f230bebb66dde9c | true |
| scenarios_a2.json | subway_directions | a2 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a2.json | subway_transfer | a2 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_a2.json | taxi_street | a2 | taxi | fallback | assets/illustrations/scenes/taxi.png | 1536×1024 RGB | 0267b90eb07bb40a3141023c21943e643e64295296462bf7736f3534105fe356 | true |
| scenarios_b1.json | b1_attendance_followup | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_bill_split | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | b1_cafe_invoice | b1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_b1.json | b1_cancellation_auto_payment | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | b1_cancellation_early_penalty | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_cancellation_gym_membership | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_cancellation_move_out_notice | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | b1_case_status | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_civil_ticket | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_claim_same_day | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_connecting | b1 | airport | fallback | assets/illustrations/scenes/airport.png | 1536×1024 RGB | 2233a48b88afd5a0474f4e49298aa5592d6bf50b09aa110b8742d45af24f6eff | true |
| scenarios_b1.json | b1_contract_appointment | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_covering_absence | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_daily_cut_the_bills | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | b1_dating_anniversary_gap | b1 | restaurant | fallback | assets/illustrations/scenes/restaurant.png | 1536×1024 RGB | 61e4aa4e94e01df9cb51e40438ce41c3a260e4b92437608d97a165bf208f61f8 | true |
| scenarios_b1.json | b1_deductible | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_extra_paper | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_followup_mail | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_friends_he_said_that | b1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_b1.json | b1_gaming_team_voice | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | b1_guest_notice | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | b1_heating_safety_call | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | b1_hotel_shift | b1 | hotel | fallback | assets/illustrations/scenes/hotel.png | 1536×1024 RGB | ff69b18019a2e59ca2f78dbefb6ddc4faad8702d369710e9e6df7c363daff3cb | true |
| scenarios_b1.json | b1_incident_leak_from_upstairs | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | b1_incident_lost_item_desk | b1 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_b1.json | b1_incident_parking_scratch | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | b1_incident_witness_note | b1 | convenience | fallback | assets/illustrations/scenes/convenience.png | 1536×1024 RGB | 917585b44e4d10b9cd5223baae804d6b7b961767574679771df347215f0307d2 | true |
| scenarios_b1.json | b1_insurance_claim_documents | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_insurance_claim_rejected | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_insurance_deductible_share | b1 | pharmacy | fallback | assets/illustrations/scenes/pharmacy.png | 1536×1024 RGB | 62771ecbe9cfcdc9653ad24c509200edf728ae5aad194a8209da6e3367055a92 | true |
| scenarios_b1.json | b1_insurance_what_is_covered | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_intranet_form | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_job_offer_conditions_batch20 | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_kpop_missing_goods | b1 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_b1.json | b1_laundry_turn | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | b1_leak_report | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | b1_mail_cc | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_market_claim | b1 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_b1.json | b1_missing_file | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_move_in_handover | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_parent_slot | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_partner_drink_table | b1 | restaurant | fallback | assets/illustrations/scenes/restaurant.png | 1536×1024 RGB | 61e4aa4e94e01df9cb51e40438ce41c3a260e4b92437608d97a165bf208f61f8 | true |
| scenarios_b1.json | b1_partner_heavy_bags_home | b1 | taxi | fallback | assets/illustrations/scenes/taxi.png | 1536×1024 RGB | 0267b90eb07bb40a3141023c21943e643e64295296462bf7736f3534105fe356 | true |
| scenarios_b1.json | b1_partner_interpret_skip | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | b1_partner_marriage_question | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | b1_partner_overnight_door | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | b1_partner_salary_deflect | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | b1_pickup_delay | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | b1_proxy_form | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_quiet_exam | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | b1_quote_change | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | b1_refund_rule | b1 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_b1.json | b1_repair_photo | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | b1_repair_visit_followup | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | b1_reschedule_request | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_return_visit | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | b1_safety_vest | b1 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_b1.json | b1_scan_note | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_school_letter | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | b1_taxi_receipt | b1 | taxi | fallback | assets/illustrations/scenes/taxi.png | 1536×1024 RGB | 0267b90eb07bb40a3141023c21943e643e64295296462bf7736f3534105fe356 | true |
| scenarios_b1.json | b1_team_meeting_coordination | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_theme_park_date_thrill | b1 | theme_park | fallback | assets/illustrations/scenes/theme_park.png | 1536×1024 RGB | 95b947d5f5631997eb4b777aee5791d9b9ceed9c86cbbaf74e5645bef0d1a434 | true |
| scenarios_b1.json | b1_typhoon_change | b1 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_b1.json | b1_volunteer_gap | b1 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_b1.json | b1_waitlist | b1 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_b1.json | b1_warranty_week | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_work_deadline_soft_request | b1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b1.json | b1_youtube_up_all_night | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | bank_account | b1 | bank | fallback | assets/illustrations/scenes/bank.png | 1536×1024 RGB | 45dd189bc46130295355e001d61962fa6488701440161e8e664e83ca643e4dbf | true |
| scenarios_b1.json | cancel_plans | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | company_dinner_hoeshik | b1 | restaurant | fallback | assets/illustrations/scenes/restaurant.png | 1536×1024 RGB | 61e4aa4e94e01df9cb51e40438ce41c3a260e4b92437608d97a165bf208f61f8 | true |
| scenarios_b1.json | couple_argument | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | food_delivery | b1 | restaurant | fallback | assets/illustrations/scenes/restaurant.png | 1536×1024 RGB | 61e4aa4e94e01df9cb51e40438ce41c3a260e4b92437608d97a165bf208f61f8 | true |
| scenarios_b1.json | love_confession | b1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_b1.json | postpone_plans | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b1.json | warm_encouragement | b1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b2.json | b2_agenda_swap | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_airport_reseat | b2 | airport | fallback | assets/illustrations/scenes/airport.png | 1536×1024 RGB | 2233a48b88afd5a0474f4e49298aa5592d6bf50b09aa110b8742d45af24f6eff | true |
| scenarios_b2.json | b2_assumption | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_cafe_brief | b2 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_b2.json | b2_case_id | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_certified_mail | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_chart_axes | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_contract_clause_inquiry | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_convenience_scan | b2 | convenience | fallback | assets/illustrations/scenes/convenience.png | 1536×1024 RGB | 917585b44e4d10b9cd5223baae804d6b7b961767574679771df347215f0307d2 | true |
| scenarios_b2.json | b2_counter_offer | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_cross_check | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_daily_migration_neighborhood_meeting | b2 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_b2.json | b2_daily_upstairs_noise | b2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b2.json | b2_dating_moving_in_terms | b2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b2.json | b2_deadline_deferral_request | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_decision_criteria_workshop | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_device_failure_escalation | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_direction_risk | b2 | directions | fallback | assets/illustrations/scenes/directions.png | 1536×1024 RGB | f2500c600eada342bc1a4102996d83d5cfdf068814f5d4247f230bebb66dde9c | true |
| scenarios_b2.json | b2_evidence_date | b2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b2.json | b2_friends_split_the_bill | b2 | restaurant | fallback | assets/illustrations/scenes/restaurant.png | 1536×1024 RGB | 61e4aa4e94e01df9cb51e40438ce41c3a260e4b92437608d97a165bf208f61f8 | true |
| scenarios_b2.json | b2_gaming_ban_appeal | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_hiring_reference_consent | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_hiring_role_scope | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_hiring_salary_band | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_hiring_start_date | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_hold_share | b2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b2.json | b2_hotel_clause | b2 | hotel | fallback | assets/illustrations/scenes/hotel.png | 1536×1024 RGB | ff69b18019a2e59ca2f78dbefb6ddc4faad8702d369710e9e6df7c363daff3cb | true |
| scenarios_b2.json | b2_job_hunting_ai_screening | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_kpop_local_festival_program | b2 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_b2.json | b2_kpop_staff_interview | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_limit_line | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_market_source | b2 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_b2.json | b2_metric_clear | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_minutes_draft | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_moving_rent_heating_budget | b2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b2.json | b2_must_have | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_next_level | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_objection_status_request | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_on_site | b2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b2.json | b2_one_pager | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_partner_dowry_joke | b2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b2.json | b2_partner_holiday_labor_chart | b2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b2.json | b2_partner_inlaw_rotation | b2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b2.json | b2_partner_photo_permission | b2 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_b2.json | b2_partner_public_intro | b2 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_b2.json | b2_pharmacy_claim | b2 | pharmacy | fallback | assets/illustrations/scenes/pharmacy.png | 1536×1024 RGB | 62771ecbe9cfcdc9653ad24c509200edf728ae5aad194a8209da6e3367055a92 | true |
| scenarios_b2.json | b2_privacy_data_scope | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_privacy_delete_request | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_privacy_retention_period | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_privacy_third_party | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_public_question | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_public_wording_feedback | b2 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_b2.json | b2_quorum_wait | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_read_receipt | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_reading_circle_response | b2 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_b2.json | b2_remedy_plan_request | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_rent_increase_meeting_batch20 | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_restaurant_note | b2 | restaurant | fallback | assets/illustrations/scenes/restaurant.png | 1536×1024 RGB | 61e4aa4e94e01df9cb51e40438ce41c3a260e4b92437608d97a165bf208f61f8 | true |
| scenarios_b2.json | b2_restore_scope | b2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b2.json | b2_review_three | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_selective_edit | b2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b2.json | b2_self_fail | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_signature_scope_confirmation | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_source_check | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_station_hold | b2 | station | fallback | assets/illustrations/scenes/station.png | 1536×1024 RGB | bbd8f5b72a1576dde83a000c2608e46b2e3623cdbc2daf426d495ed23a2e158f | true |
| scenarios_b2.json | b2_taxi_escalate | b2 | taxi | fallback | assets/illustrations/scenes/taxi.png | 1536×1024 RGB | 0267b90eb07bb40a3141023c21943e643e64295296462bf7736f3534105fe356 | true |
| scenarios_b2.json | b2_theme_park_date_safety | b2 | theme_park | fallback | assets/illustrations/scenes/theme_park.png | 1536×1024 RGB | 95b947d5f5631997eb4b777aee5791d9b9ceed9c86cbbaf74e5645bef0d1a434 | true |
| scenarios_b2.json | b2_time_box | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | b2_vacate_short | b2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_b2.json | b2_youtube_collab_pitch | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | business_meeting_intro | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_b2.json | complaint_delivery | b2 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_b2.json | doctor_consultation | b2 | market | fallback | assets/illustrations/scenes/market.png | 1536×1024 RGB | 86e36cbee650407d0bff0b4010467290069e78188b2e7194884b09f7f90acf9c | true |
| scenarios_b2.json | job_interview | b2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_access_time | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_ai_labeling_policy_batch20 | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_attribution_author_order | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_attribution_collective_byline | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_attribution_reuse_without_credit | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_attribution_unpaid_translation | c1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_c1.json | c1_briefing_number | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_clinical_data_reuse | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_clinical_informed_consent | c1 | pharmacy | fallback | assets/illustrations/scenes/pharmacy.png | 1536×1024 RGB | 62771ecbe9cfcdc9653ad24c509200edf728ae5aad194a8209da6e3367055a92 | true |
| scenarios_c1.json | c1_clinical_second_opinion | c1 | pharmacy | fallback | assets/illustrations/scenes/pharmacy.png | 1536×1024 RGB | 62771ecbe9cfcdc9653ad24c509200edf728ae5aad194a8209da6e3367055a92 | true |
| scenarios_c1.json | c1_clinical_trial_withdrawal | c1 | pharmacy | fallback | assets/illustrations/scenes/pharmacy.png | 1536×1024 RGB | 62771ecbe9cfcdc9653ad24c509200edf728ae5aad194a8209da6e3367055a92 | true |
| scenarios_c1.json | c1_conflict_interest_disclose_stake | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_conflict_interest_dual_role | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_conflict_interest_recuse_request | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_conflict_interest_sponsored_talk | c1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_c1.json | c1_critique_anonymous_limits | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_critique_metric_gaming | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_critique_public_wording | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_critique_work_not_person | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_daily_migration_demography_policy_forum | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_daily_prices_vs_data | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_dating_app_safety | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_facework_accept_correction | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_facework_correct_in_private | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_facework_decline_without_wound | c1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_c1.json | c1_facework_praise_before_others | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_friends_venue_access | c1 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_c1.json | c1_gaming_playtime_policy | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_kpop_fan_labor | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_kpop_platform_localization_review | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_leading_item | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_mediation_ground_rules | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_mediation_partial_agreement | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_mediation_restate_position | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_mediation_walk_away_line | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_moving_rent_relief_roundtable | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_partner_guest_or_family | c1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_c1.json | c1_partner_invisible_labor | c1 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_c1.json | c1_policy_exemption_edge | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_policy_pilot_before_rollout | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_policy_sunset_clause | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_policy_who_bears_cost | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_question_window | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_relative_risk | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_sample_bias | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_speaking_slot | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_survey_limits_briefing | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_theme_park_date_next_time | c1 | theme_park | fallback | assets/illustrations/scenes/theme_park.png | 1536×1024 RGB | 95b947d5f5631997eb4b777aee5791d9b9ceed9c86cbbaf74e5645bef0d1a434 | true |
| scenarios_c1.json | c1_uncertainty | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_work_ai_hiring_pilot_review | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c1.json | c1_youtube_health_claims | c1 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_aesthetic_dialect_subtitle_flatten | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_aesthetic_poem_rhythm_meaning_loss | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_aesthetic_translator_editor_dispute | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_aesthetic_word_without_equivalent | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_appeal_bot | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_archive_gap | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_automated_decision_appeal | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_automated_redress_record_batch20 | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_daily_automation_redress | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_daily_integration_metric_editorial | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_dating_romance_frames | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_discourse_premise | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_ethics_consent_form_scope_gap | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_ethics_embargo_disclosure_window | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_ethics_misconduct_review_procedure_defined | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_ethics_reviewer_dual_appointment_disclosure | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_friends_quoted_privately | c2 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_c2.json | c2_gaming_auto_sanction | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_history_compile_committee_wording_dispute | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_history_merging_conflicting_testimonies | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_history_monument_inscription_agreement | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_history_sealed_records_disclosure_timing | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_jurisdiction_cross_border_premise | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_jurisdiction_even_if_authorized_escalate | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_jurisdiction_neither_claims_authority | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_jurisdiction_provisional_ruling_no_authority | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_kpop_authenticity_platform_panel | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_kpop_fandom_language | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_limitation_define_accrual_date | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_limitation_ex_officio_review_path | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_limitation_extension_premise_error_proof | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_limitation_notice_delay_appeal_window | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_mandate_edge | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_moving_affordability_definition_hearing | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_partner_document_the_place | c2 | home | fallback | assets/illustrations/scenes/home.png | 1536×1024 RGB | 7857df7599006f6c0ecb7a1f883ff3744f0e5700d2892692954a20b2e6b9036d | true |
| scenarios_c2.json | c2_partner_name_and_memory | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_passive_hide | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_representation_fan_rep_mandate_defined | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_representation_minority_view_regardless | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_representation_press_quote_not_official | c2 | cafe | fallback | assets/illustrations/scenes/cafe.png | 1536×1024 RGB | b68a23266ad4fdbdfd52568ba7e1457d7bf672f1368a0d2ab31c50f5d1e6bfd5 | true |
| scenarios_c2.json | c2_representation_spokesperson_handover_concession | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_theme_park_date_reflection | c2 | theme_park | fallback | assets/illustrations/scenes/theme_park.png | 1536×1024 RGB | 95b947d5f5631997eb4b777aee5791d9b9ceed9c86cbbaf74e5645bef0d1a434 | true |
| scenarios_c2.json | c2_trace_log | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_uneven_impact | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_withdraw_deep | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_work_ai_accountability_board | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
| scenarios_c2.json | c2_youtube_algorithm_duty | c2 | office | fallback | assets/illustrations/scenes/office.png | 1536×1024 RGB | b51a3c6075841a871e6da2e18e57f352ec5861a124a8a3fc4701322e2c2943c4 | true |
