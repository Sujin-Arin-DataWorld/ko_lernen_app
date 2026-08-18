# 한옥·장식 에셋 전수 인벤토리 (2026-08-17)

**이 문서가 정본이다.** 한옥·장식·카드 계열 이미지가 지금 저장소에 **무엇이 있고 / 어디에 쓰이고 / 무엇이 없는지**를
파일 실측으로 적는다. 문서를 믿지 말고 파일을 믿는다 — 아래 §7 전수표는 도구가 만든다.

```bash
/usr/local/bin/python3.12 tool/asset_inventory.py            # §7 표 재생성 (markdown)
/usr/local/bin/python3.12 tool/asset_inventory.py --json     # 기계 판독
```

측정 기준 · HEAD `f071d44d` · Pillow 10.4.0(`/usr/local/bin/python3.12`) · alpha% = alpha>8 픽셀 비율 ·
"lib 참조" = 파일명 또는 확장자 뺀 이름이 `lib/**/*.dart` 어딘가에 문자열로 존재.

---

## 0. 한 장 요약

| 항목 | 값 |
|---|---|
| 이미지 총계 | **443개 · 174.6 MB** (디렉터리 41개, `assets/` + `assets_unused/` + `docs/assets/`) |
| 번들(pubspec 선언 폴더) | 이미지 268개 — Flutter는 선언 폴더를 **비재귀**로 담으므로 leaf마다 한 줄이 필요하다 |
| 번들 밖 | `assets_unused/**` 174개(QA·원본·격리) · `docs/assets/**` 22개 · `hanok_compound/` 7개(동결) |
| lib 미참조인데 번들에 들어가는 것 | `hanok_stages/` 11 · `stamps/` 13 — 둘 다 **런타임 경로 조립**이라 `asset_orphan_guard_test`의 `dynamicDirs` 면제 대상(정상) |
| 진행 중(다른 세션) | `assets/illustrations/listening/` **50개**, 아직 untracked·pubspec 미등록 — **이번 작업에서 건드리지 않는다** |

**한옥 관련 핵심 8개 위치** (자세한 파일 목록은 §7)

| 위치 | 개수 | 규격 | 역할 | 상태 |
|---|---:|---|---|---|
| `personal_hanok_v2/a1/states/` | 16 | 1536×1152 RGB WebP 255–279KB | A1 짓다 16단계 | ✅ 승격 완료 |
| `personal_hanok_v2/map/` | 8 | 1536×1152, base는 RGB·나머지 풀캔버스 RGBA | estate 대지 + 건물 6 + 후원 | ✅ **B1/B2 완성형이 이미 있다** |
| `personal_hanok_v2/interiors/` | 2 | 1086×1448 RGB | 안방·대청 배경 | ✅ |
| `hanok/` | 15 | 배너·게이트·배경 | 사랑방 배경(`sarangbang_empty.png` 1086×1448)이 여기 있다 | ✅ |
| `decorations/` | 24 | RGBA/팔레트, 긴 변 568–1330 | 실내 6 + 마당·절기 18 | ✅ 화이트리스트 24 = 디스크 24 |
| `hanok_stages/` | 12 | 841×1870 | 레거시 12단계 | ⚠️ `_dark` 0장 |
| `hanok_compound/` | 7 | 혼합 캔버스 | 동결 프로토타입 | 💀 번들 제외·lib 참조 0 |
| `gye/` | 9 | 혼합 | 계 공동 한옥 | ⛔ 개인 한옥 재사용·모델 입력 금지(provenance) |

---

## 1. 스타일 가족 — 새 자산은 반드시 한 가족에 속하고, 그 가족의 앵커를 참조한다

2026-08-17 A2 실패의 원인은 가족을 섞은 것이다. 복구한 옛 프롬프트(`gvi_1785839371699_kh2ia` 등)는
*"soft watercolour-and-gouache … museum catalogue plate … pure white background"* 수채 규약인데,
**실제 번들 파일은 Faceted Minhwa 로우폴리 컷아웃**이다. `f63b5174`(2026-08-04)가 그 수채본을
"watercolour outlines, white canvases … violate the visual contract"로 **명시 기각**하고 다시 만든 것이 지금 파일이다.
⇒ **기준은 번들 PNG 자체이지, 복구된 프롬프트가 아니다.**

| 가족 | 무엇 | 앵커(참조로 쓸 파일) | 규약 |
|---|---|---|---|
| **F-A** 사랑방 실내 컷아웃 | `decorations/` 실내 6 + 사군자 4·편액 | `decoration_seoan/soban/munbangsau/jagae_mungap.png` | 로우폴리 면분할·한지 그레인·매트·윤곽선 없음·**바닥 그림자 없음**·3/4 약간 위·좌상단 광원·RGBA 컷아웃 |
| **F-B** 마당 장식 | `decorations/` 마당 8·절기 4 | `decoration_jangdokdae/maehwa/sonamu` | BIBLE §3.5(마당 규약) · 팔레트 양자화 다수 |
| **F-C** estate 지도 | `personal_hanok_v2/**` + A1 키트 부품 | **allowlist** `map/structures/sarangchae.png`(sha `f523e93f…`) | 1536×1152 풀캔버스·북향·좌상단 광원·고밀도 회화체 면분할 |
| **F-D** 방 배경 | `hanok/sarangbang_empty.png`, `interiors/anbang·daecheong_empty.png` | 자기 자신 | 1086×1448 불투명 3:4 실내 장면 |
| **F-E** 카드/포스터 | `packs` 14 · `activities` 24 · `scenes` 14 · `listening` 50 | `packs/plum.webp` | 한지 아이보리 면 + 단청 모서리 삼각 + 점 마커 |
| **F-F** 레거시 | `hanok_stages` · `hanok_compound` · `gye` | — | **신규 작업의 참조·모델 입력 금지** |
| **F-G** 도장·스티커 | `stamps` 14 · `stickers` 30 | — | 런타임 조립 |
| **F-H** 마스코트 | `mascot` 15 | — | 캐릭터 정본 |

---

## 2. 필요 vs 보유 — 1:1 대조 (핵심)

계획서가 "새로 만든다"고 적었던 것들 중 **상당수가 이미 있다.** 아래가 실제 갭이다.

### 2.1 A2 살다 — 사랑방 가구 12

| 원안 | 이미 있나 | 판정 |
|---|---|---|
| 찻상 소반 | `decoration_soban.png` ✅ | **폐기**(중복) |
| 경상 | `decoration_seoan.png` ✅ | **폐기** |
| 연상(벼루함) | `decoration_munbangsau.png` ✅ | **폐기** |
| 머릿장 | `decoration_jagae_mungap.png` ✅ | **폐기** |
| 서가 | `decoration_chaekgado.png` ✅ | **폐기** |
| 사방탁자·보료세트·방석2·반닫이·화로·등잔대·거문고·바둑·목침·소병풍·고비·향로 | 없음 | **신규 12장** |

### 2.2 A2 외관 흔적 4 — 신규는 사실상 1장

| 항목 | 이미 있나 | 방법 |
|---|---|---|
| 굴뚝 연기 | 굴뚝 자체는 `a1_kit/generated/props/prop_chimney.png` ✅ | 연기만 신규(시트에 포함) |
| 처마 등롱 켜짐 | `prop_lantern.png` ✅(꺼진 상태) | **재색+halo 프로그램 = 0cr** |
| 용마루 까치 | `mascot/magpie_*.png` ✅ · `decoration_kkachi_nest.png` ✅ | estate 축척 sprite 필요(시트에 포함) |
| 장독 첫 항아리 2 | `decoration_jangdokdae.png` ✅(항아리 6 + 석축) | **크롭·축소 = 0cr** 가능 |

### 2.3 B1 잇다 18

| 항목 | 이미 있나 | 방법 |
|---|---|---|
| 솟을대문·행랑채·안채 완성형 | `map/structures/{sotdaeulmun,haengrangchae,anchae}.png` ✅ | **단계는 역분해**(골조만 모델 1회) |
| 석등 | `decoration_seokdeung.png` ✅ | 재사용 |
| 소나무 | `decoration_sonamu.png` ✅ | 재사용 |
| 매화 개화 | `decoration_maehwa.png` ✅ | 재사용 |
| 장독대 채움 | `decoration_jangdokdae.png` ✅ | 재사용 |
| 대문 열림 | `sotdaeulmun.png` 문짝 영역 ✅ | crop/변형 0cr |
| 빨랫줄·바구니 | 없음 | 신규 1 |
| 안방 개방(venue) | `interiors/anbang_empty.png` ✅ | 자산 불필요 |

### 2.4 B2 나누다 20 · C1 8 · C2 8

| 항목 | 이미 있나 | 방법 |
|---|---|---|
| 대청·사당 완성형 | `daecheongmaru.png` · `sadang.png` ✅ | 역분해 |
| 후원 | `landscape/rear_garden.png` ✅ | alpha 3분할 0cr |
| 담장 장식 | `decoration_doldam.png` ✅ | 재사용 |
| 연못 | `decoration_pond.png` ✅ | 재사용 |
| 우물 | 없음 | 신규 1 |
| 대청 개방(venue) | `interiors/daecheong_empty.png` ✅ | 자산 불필요 |
| C1 봄/여름/가을 | 매화·연못·국화(`sagunja_guk`) ✅ | 재사용·재배치 |
| C1 겨울(눈)·돌봄(이끼/낙엽) | 없음 | 신규 2~3 |
| C2 문집 8 | `decoration_chaekgado.png` 책 더미 ✅ | crop 색변형 0cr |
| 증표 인장 15 | `stamps/` 14 + `dancheong_stamp.dart` 페인터 ✅ | 코드 |

**결론:** 남은 신규 생성은 **A2 가구 12 + 소품 시트 1~2장 + 겨울/돌봄 2~3 + 우물·빨랫줄 2 + 건물 골조 3~5**
≈ **20~25장**(당초 계획 45장에서 절반). 나머지는 기존 자산의 crop·재색·역분해로 **0크레딧**이다.

---

## 3. 결함 (실측)

1. **다크 배경 전멸** — `madang_background.dart:38-39`가 `stage_{slug}_dark.png`(12장)와 `madang(dark).png`를 부르는데
   디스크에 `dark` 이름 파일이 **0개**. 다크모드는 항상 그라데이션 폴백. `madang(dark).png`는 `assets_unused/`에 있다.
2. **`hanok_compound/` 7장 9.7MB 완전 사망** — lib 참조 0, pubspec 주석 처리. 참조 금지.
3. **`decorations/_raw/` 없음** — `tool/decoration_normalize.py`의 입력 폴더. gitignore(`.gitignore:139`)라 새로 만들어야 한다(생성 완료).
4. **`a1_kit_overrides.json`의 `confirmedBy`가 아직 "pending Jin visual confirmation"** — 키트 기하 확정 전.
5. **`parts.json`의 생성 부품 11개가 `pending_jin_review`인데 원장은 approved** — 두 기록이 어긋난다.
6. **양자화 불균일** — `gye_jeongja.png` 1005KB(형제 7장은 78–304KB), `stage_jongga/_sidebuilding` 2.0–2.5MB(형제 10장 437–671KB).
7. **`ASSET_INVENTORY_2026-08-06.md`가 stale** — A1 16장 승격·`gye_showcase`·`dokkaebi_fire` 누락, `hanok_compound`를 "사용 중"으로 표기.
8. **옛 사랑방 프롬프트 계보 오인** — §1 참조. 인수인계 §6.3을 그대로 따르면 실패를 반복한다.
9. **실패한 A2 2건 프롬프트는 복구 불가** — `list_my_generations` 최대 50건을 오늘 듣기카드 배치가 다 채웠고, ID는 `663d7694…`·`4db5dd10…`로 잘려 있다.

---

## 4. 실측 스타일 값 (F-A 사랑방 실내 6종)

프롬프트에는 BIBLE §1.3의 명목값이 아니라 **아래 실측값**을 쓴다.

- 목재 `#A2663A #8F5130 #844A2D #A76D39 #B8804C` · 면 그림자 `#633720 #5A3623 #3B271B`
- 칠흑 `#2C221D #281E18 #211914` · 물건 위 한지 아이보리 `#DBBC8D #DCCAA0 #C6AE8B`
- 단청 청 `#274A3F #2C4539 #203B35`(명목 `#3D9A7F`는 **너무 밝다**) · 적 `#703329 #6A2316`(명목 `#C24A45` 너무 밝다) · 금 `#BD924C #C08C43`
- 카메라: 정면에서 살짝 왼쪽, 눈높이보다 25–40° 위 · 광원 좌상단 · **6종 모두 바닥 그림자 없음**
- 알파: 100% RGBA8, 반투명 림 2.5–5.7%(jagae 11.9%), 네 모서리 alpha 0, 긴 변 568–1330(고정 규칙 없음)
- **크로마 안전성 실측**: 6종의 최대 greenness(G−max(R,B))는 23이고 55 초과 픽셀은 **0개** →
  `#00FF00` 키잉이 이 팔레트를 갉지 않는다(`cut_prop_sheet.py` 임계 15→55).

---

## 5. 문서 신선도

| 문서 | 상태 |
|---|---|
| **이 문서** | 한옥·장식 자산의 정본 |
| `ASSET_INVENTORY_2026-08-06.md` | stale(§3-7) — 한옥·장식은 이 문서로 대체 |
| `PERSONAL_HANOK_CANONICAL_ASSET_CONTRACT.md` | map 8장 계약은 유효, a1/states 16장 미기재 |
| `ASSET_GENERATION_BIBLE.md` | §3.5는 **마당** 규약(실내에 쓰면 어긋남), §1.3 명목 팔레트는 실측과 다름 |
| `HANDOFF_LIVING_HANOK_V1_2026-08-17.md` | §6.3 프롬프트 복구 지시가 잘못된 계보를 가리킴 |
| `HANOK_V1_SOURCE_REGISTRY.md` | 유효(출처 3곳은 사실 색인 전용, 이미지 입력·crop 금지) |

---

## 6. 생성 규약 요약 (실측)

- 모델·요금: Seedream V4.5 **1cr**(2K/4K, 참조 ≤13) · GPT Image 2 3cr(1K)/4cr(2K) · Nano Banana Pro **4cr**(1K·2K) — **참조 3장이면 24cr**(실측) → 참조 0~1장 · Recraft Remove BG 0.3cr
- `generate_image(model, prompt, image_urls[], aspect_ratio, resolution)` — **resolution 기본값 1K**, 2K는 명시해야 한다
- `upload_image`는 무료(≤10MB) · `get_status(taskId)`로 과거 프롬프트 원문 회수 가능(무료, 최근 50건 한정)
- 잔액 788.7cr (2026-08-17 측정)

---

## 7. 전수표 (도구 생성)

총 443개 이미지 · 174.6 MB · 디렉터리 41개


### `assets/icons/` — 2개 · 0.2 MB · 번들 O · lib 미참조 0개

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `HanLogo.png` | 1024×1024 | RGBA | 96.7 | 205 | `685e66b6452b` | O |
| `icon-192.png` | 192×192 | RGBA | 96.8 | 34 | `5f6773061a54` | O |

### `assets/illustrations/activities/` — 24개 · 2.1 MB · 번들 O · lib 미참조 0개

가족 **F-E** · 카드 세트

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `book_capture.webp` | 800×600 | RGB |  | 88 | `43e4cf3c9fa3` | O |
| `bookshelf.webp` | 800×600 | RGB |  | 89 | `21c775be5d9c` | O |
| `calligraphy.webp` | 800×600 | RGB |  | 70 | `152ebcf5bbeb` | O |
| `chosung.webp` | 800×600 | RGB |  | 86 | `49aa02c02279` | O |
| `cloze.webp` | 800×600 | RGB |  | 85 | `d9c35878b0c7` | O |
| `course.webp` | 800×600 | RGB |  | 86 | `40b3cb119289` | O |
| `custom_matching.webp` | 800×600 | RGB |  | 93 | `2da3c678c109` | O |
| `custom_quiz.webp` | 800×600 | RGB |  | 88 | `95a789f432fd` | O |
| `custom_typing.webp` | 800×600 | RGB |  | 87 | `9fc43c973d60` | O |
| `daily_game.webp` | 800×600 | RGB |  | 86 | `01a7b80d9699` | O |
| `grammar.webp` | 800×600 | RGB |  | 88 | `330c7b9ef18e` | O |
| `hangul.webp` | 800×600 | RGB |  | 87 | `77cb04dde970` | O |
| `hard_words.webp` | 800×600 | RGB |  | 88 | `2b4b54c4ad17` | O |
| `kkeunmari.webp` | 800×600 | RGB |  | 87 | `1653ca7f9980` | O |
| `listening.webp` | 800×600 | RGB |  | 88 | `7ff8742bba87` | O |
| `pronunciation.webp` | 800×600 | RGB |  | 92 | `fb6d9be0f7f0` | O |
| `scenarios.webp` | 800×600 | RGB |  | 89 | `fa8df13eff1d` | O |
| `sentence_arcade.webp` | 800×600 | RGB |  | 83 | `83ea42125bf1` | O |
| `smalltalk.webp` | 800×600 | RGB |  | 85 | `bad8279ccf16` | O |
| `speed_match.webp` | 800×600 | RGB |  | 84 | `bb84e5c15aa9` | O |
| `srs.webp` | 800×600 | RGB |  | 101 | `7627d4088a91` | O |
| `syllable_cross.webp` | 800×600 | RGB |  | 100 | `688bca9d7684` | O |
| `vocab_packs.webp` | 800×600 | RGB |  | 83 | `1facf8ff344c` | O |
| `word_search.webp` | 800×600 | RGB |  | 88 | `fee3b57d0bd4` | O |

### `assets/illustrations/book/` — 5개 · 0.9 MB · 번들 O · lib 미참조 0개

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `book_analyzing.png` | 1254×940 | P | 40.0 | 185 | `05404887e8af` | O |
| `book_camera_guide.png` | 1254×940 | P | 32.0 | 139 | `c194fb66adff` | O |
| `book_empty_shelf.png` | 1254×940 | P | 44.1 | 141 | `4a9e05807944` | O |
| `book_error.png` | 1254×940 | P | 50.3 | 229 | `0a9452f261ea` | O |
| `book_success.png` | 1254×940 | P | 49.0 | 247 | `26a30035a30e` | O |

### `assets/illustrations/burst/` — 2개 · 0.3 MB · 번들 O · lib 미참조 0개

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `burst_coins.png` | 900×600 | RGBA | 8.3 | 160 | `fbc5c4e395a5` | O |
| `burst_pouches.png` | 900×600 | RGBA | 7.3 | 131 | `899d72e31969` | O |

### `assets/illustrations/decorations/` — 24개 · 8.2 MB · 번들 O · lib 미참조 0개

가족 **F-A/F-B** · 사랑방 실내 컷아웃 6 + 마당 장식 18 (앵커: seoan·soban·munbangsau·jagae_mungap)

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `decoration_chaekgado.png` | 495×568 | RGBA | 88.5 | 354 | `36f68cf3280b` | O |
| `decoration_chuseok_moon.png` | 627×627 | RGBA | 29.3 | 429 | `071d01342e47` | O |
| `decoration_dokkaebi_fire.png` | 1254×1254 | RGBA | 24.2 | 748 | `9848a7c6fa2c` | O |
| `decoration_doldam.png` | 1200×200 | RGBA | 48.4 | 219 | `b559f2bd6d91` | O |
| `decoration_gat_buchae.png` | 584×1330 | RGBA | 23.3 | 382 | `fb361641de66` | O |
| `decoration_hangeulday_plaque.png` | 627×418 | RGBA | 62.9 | 356 | `a188a43f9e7b` | O |
| `decoration_jagae_mungap.png` | 664×356 | RGBA | 66.5 | 283 | `f51394525529` | O |
| `decoration_jangdokdae.png` | 1254×836 | P | 42.0 | 150 | `f2b5ad4d7a7b` | O |
| `decoration_kite.png` | 627×627 | RGBA | 24.1 | 449 | `63499f65b730` | O |
| `decoration_kkachi_nest.png` | 1254×1004 | P | 45.1 | 248 | `35a038575219` | O |
| `decoration_maehwa.png` | 992×1586 | P | 23.2 | 181 | `2ad12d72b415` | O |
| `decoration_munbangsau.png` | 1128×663 | RGBA | 47.8 | 699 | `c426659dd574` | O |
| `decoration_pond.png` | 1254×878 | P | 49.3 | 166 | `e164a2553cda` | O |
| `decoration_punggyeong.png` | 821×1916 | P | 16.7 | 80 | `cbad24faa2ef` | O |
| `decoration_pyeonaek.png` | 1254×376 | P | 70.3 | 50 | `cc986ec7ca9c` | O |
| `decoration_sagunja_guk.png` | 405×971 | RGBA | 74.1 | 548 | `6045ff96a9eb` | O |
| `decoration_sagunja_juk.png` | 809×1942 | P | 73.4 | 285 | `a8b9c205b057` | O |
| `decoration_sagunja_maehwa.png` | 809×1942 | P | 74.5 | 288 | `cc7a17ce798b` | O |
| `decoration_sagunja_nan.png` | 809×1942 | P | 74.6 | 235 | `51a1c6588cb2` | O |
| `decoration_seoan.png` | 1330×490 | RGBA | 48.3 | 484 | `59e488f8cf21` | O |
| `decoration_seokdeung.png` | 300×650 | RGBA | 44.8 | 187 | `3995afbf1d45` | O |
| `decoration_seollal_flag.png` | 1254×470 | RGBA | 20.7 | 576 | `b709b5a9f0eb` | O |
| `decoration_soban.png` | 974×667 | RGBA | 56.0 | 655 | `b58b85ae4eec` | O |
| `decoration_sonamu.png` | 1024×1536 | P | 40.8 | 298 | `ce32bb25a8ec` | O |

### `assets/illustrations/empty/` — 2개 · 1.3 MB · 번들 O · lib 미참조 0개

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `celebrate_complete.png` | 1254×1254 | RGB |  | 1266 | `dbb3ea1f8b8d` | O |
| `studyroom_waiting.png` | 1254×1254 | P | 41.6 | 89 | `d37f8ab6c5f2` | O |

### `assets/illustrations/error/` — 2개 · 0.2 MB · 번들 O · lib 미참조 0개

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `lost_magpie.png` | 1254×1254 | P | 50.5 | 128 | `9f9df6104d44` | O |
| `offline_lantern.png` | 1254×1254 | P |  | 109 | `2beb55906d42` | O |

### `assets/illustrations/gye/` — 9개 · 2.6 MB · 번들 O · lib 미참조 0개

가족 **F-F** · 계 공동 한옥 — 개인 한옥 재사용/모델 입력 금지

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `gye_bridge.png` | 1254×940 | P | 23.3 | 77 | `453bb715e33a` | O |
| `gye_byeoldang.png` | 1254×1129 | P | 46.3 | 202 | `b00cc3047791` | O |
| `gye_garden.png` | 1254×975 | P | 42.2 | 303 | `cb69e8240554` | O |
| `gye_gate_grand.png` | 1254×975 | P | 68.2 | 268 | `68b4aef09bb7` | O |
| `gye_haenglangchae.png` | 1254×896 | P | 48.9 | 176 | `b25686185d37` | O |
| `gye_jangmyeongdeung_pair.png` | 1086×1448 | P | 33.5 | 235 | `e4a0ab977be9` | O |
| `gye_jeongja.png` | 1254×1045 | RGBA | 41.3 | 1004 | `7a1333b3efd0` | O |
| `gye_pond_large.png` | 1254×784 | P | 48.7 | 192 | `c1b0dfb4168d` | O |
| `gye_showcase_courtyard.webp` | 1280×720 | RGB |  | 187 | `43f785286de0` | O |

### `assets/illustrations/hanok/` — 15개 · 11.6 MB · 번들 O · lib 미참조 0개

가족 **F-D** · 방 배경·배너·게이트 (sarangbang_empty 1086×1448)

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `achievements.png` | 1254×608 | P |  | 376 | `e9a7523e5ab0` | O |
| `calligraphy.png` | 1254×372 | P |  | 203 | `2829d9876c4a` | O |
| `gate_door_left.png` | 737×2135 | P | 87.6 | 218 | `d24d077b4534` | O |
| `gate_door_right.png` | 737×2135 | P | 87.5 | 207 | `00b40566e3b4` | O |
| `gate_final.png` | 1024×1536 | P |  | 648 | `3e80ac618b97` | O |
| `gate_frame.png` | 941×1672 | P | 34.5 | 104 | `87402f40b075` | O |
| `kkeunmari_hero.png` | 1254×700 | RGB |  | 1321 | `e7095ab2d222` | O |
| `listening_hero.png` | 1254×700 | RGB |  | 1288 | `8be64f03d567` | O |
| `madang(light).png` | 848×1854 | P |  | 322 | `c6ff21c079f6` | O |
| `porch.png` | 1254×700 | RGB |  | 1335 | `cf508d9499fe` | O |
| `sarangbang_empty.png` | 1086×1448 | RGB |  | 2495 | `e9eb5e8de810` | O |
| `study_classroom.png` | 1254×601 | P |  | 457 | `efc5e6113436` | O |
| `study_scholar.png` | 1254×680 | P |  | 408 | `13c56f3c675d` | O |
| `taego-joy-duo.png` | 1280×720 | P |  | 424 | `2324f8efd846` | O |
| `welcome-hero.png` | 1254×1254 | RGB |  | 2111 | `4497138241f1` | O |

### `assets/illustrations/hanok_compound/` — 7개 · 9.7 MB · 번들 X · lib 미참조 0개

가족 **F-F** · 동결 프로토타입 — 번들 제외·참조 금지

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `anchae.png` | 1302×1208 | RGBA | 39.9 | 1204 | `c1901e196412` | O |
| `daecheongmaru.png` | 1402×1122 | RGBA | 45.9 | 1366 | `7ed5b494bcb3` | O |
| `haengrangchae.png` | 1448×1086 | RGBA | 33.4 | 1070 | `00c5e6b4346d` | O |
| `sadang.png` | 1536×1024 | RGBA | 48.3 | 1491 | `f05af0940f67` | O |
| `sarangchae.png` | 1402×1122 | RGBA | 36.0 | 1152 | `1da81a60019b` | O |
| `site_base.png` | 1536×1152 | RGB |  | 2621 | `f39881814ce8` | O |
| `sotdaeulmun.png` | 1448×1086 | RGBA | 32.7 | 1042 | `8d452faedf61` | O |

### `assets/illustrations/hanok_stages/` — 12개 · 9.7 MB · 번들 O · lib 미참조 11개

가족 **F-F** · 레거시 12단계 배경 — 신규 참조 금지

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `stage_beams_light.png` | 841×1870 | P |  | 670 | `a14bca77c5d0` | **X** |
| `stage_dancheong_light.png` | 841×1870 | P |  | 562 | `43474a93a829` | **X** |
| `stage_empty_light.png` | 841×1870 | P |  | 443 | `a7c32b056fc4` | **X** |
| `stage_foundation_light.png` | 841×1870 | P |  | 446 | `8ba5e1cdf8da` | **X** |
| `stage_gate_light.png` | 841×1870 | P |  | 568 | `32fcada68662` | **X** |
| `stage_jongga_light.png` | 841×1870 | RGB |  | 2472 | `e8d8c2827ee6` | **X** |
| `stage_pillars_light.png` | 841×1870 | P |  | 437 | `03c06b8d0726` | **X** |
| `stage_sidebuilding_light.png` | 841×1870 | RGB |  | 2016 | `53dfe340118c` | O |
| `stage_thatch_light.png` | 841×1870 | P |  | 548 | `b33b59ce5536` | **X** |
| `stage_tile_complete_light.png` | 841×1870 | P |  | 561 | `5d18a6117c4e` | **X** |
| `stage_tile_partial_light.png` | 841×1870 | P |  | 547 | `b4f5c46d9305` | **X** |
| `stage_windows_light.png` | 841×1870 | P |  | 606 | `c1bdb8838809` | **X** |

### `assets/illustrations/listening/` — 50개 · 4.2 MB · 번들 X · lib 미참조 50개

가족 **F-E** · 듣기 카드 (다른 세션 진행 중)

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `A1Arrival.webp` | 800×600 | RGB |  | 87 | `8f9f2a3539b2` | **X** |
| `A1Cafe.webp` | 800×600 | RGB |  | 86 | `b77ee53174f4` | **X** |
| `A1Counter.webp` | 800×600 | RGB |  | 89 | `e7e028c655e3` | **X** |
| `A1Family.webp` | 800×600 | RGB |  | 91 | `f32391c0f8b1` | **X** |
| `A1Greeting.webp` | 800×600 | RGB |  | 89 | `8d36d6dca5ad` | **X** |
| `A1Health.webp` | 800×600 | RGB |  | 85 | `d7128c91ad1e` | **X** |
| `A1Home.webp` | 800×600 | RGB |  | 89 | `27cdf5790c2b` | **X** |
| `A1Numbers.webp` | 800×600 | RGB |  | 102 | `f6935160d8a9` | **X** |
| `A1Phone.webp` | 800×600 | RGB |  | 82 | `f0c2a56e66b3` | **X** |
| `A1Repair.webp` | 800×600 | RGB |  | 88 | `e75c6cf41f7f` | **X** |
| `A1Transit.webp` | 800×600 | RGB |  | 88 | `18fe9e4930c7` | **X** |
| `A1Wayfinding.webp` | 800×600 | RGB |  | 85 | `2ab514b2d83e` | **X** |
| `A2Bank.webp` | 800×600 | RGB |  | 85 | `6d2831dd6561` | **X** |
| `A2Body.webp` | 800×600 | RGB |  | 87 | `3c79b9e80f55` | **X** |
| `A2Booking.webp` | 800×600 | RGB |  | 85 | `0f1bd2c3910b` | **X** |
| `A2Cafe.webp` | 800×600 | RGB |  | 84 | `6ed7d8a3ddd1` | **X** |
| `A2Delivery.webp` | 800×600 | RGB |  | 85 | `76c6a3cd7851` | **X** |
| `A2Enrolment.webp` | 800×600 | RGB |  | 86 | `f3f8ee9a76ef` | **X** |
| `A2Family.webp` | 800×600 | RGB |  | 87 | `fc47f61a18a7` | **X** |
| `A2Neighbourhood.webp` | 800×600 | RGB |  | 86 | `56b975eb0806` | **X** |
| `A2Plans.webp` | 800×600 | RGB |  | 86 | `53fff73fd828` | **X** |
| `A2Shopping.webp` | 800×600 | RGB |  | 97 | `a66e7dca2b9f` | **X** |
| `A2Travel.webp` | 800×600 | RGB |  | 88 | `a43938e35cb0` | **X** |
| `A2Work.webp` | 800×600 | RGB |  | 92 | `e92a862432b8` | **X** |
| `B1Cancellation.webp` | 800×600 | RGB |  | 77 | `8738b058b38a` | **X** |
| `B1Delay.webp` | 800×600 | RGB |  | 91 | `d2cddd096593` | **X** |
| `B1Feelings.webp` | 800×600 | RGB |  | 83 | `75ab0c280367` | **X** |
| `B1Incident.webp` | 800×600 | RGB |  | 83 | `7b5b40dace0c` | **X** |
| `B1Insurance.webp` | 800×600 | RGB |  | 86 | `50ae202e0e3b` | **X** |
| `B1Neighbours.webp` | 800×600 | RGB |  | 84 | `1dae3e6e01ee` | **X** |
| `B1Paperwork.webp` | 800×600 | RGB |  | 86 | `2ea2cc319a0c` | **X** |
| `B1Receipts.webp` | 800×600 | RGB |  | 83 | `b03cd357415b` | **X** |
| `B1Refund.webp` | 800×600 | RGB |  | 84 | `2e10624b4b49` | **X** |
| `B1Repairs.webp` | 800×600 | RGB |  | 87 | `6dce54f29b6d` | **X** |
| `B1Team.webp` | 800×600 | RGB |  | 86 | `e307aee2e33a` | **X** |
| `B2Authorities.webp` | 800×600 | RGB |  | 85 | `a09ce07ba2ad` | **X** |
| `B2Contracts.webp` | 800×600 | RGB |  | 79 | `c4536bdc8a8f` | **X** |
| `B2Escalation.webp` | 800×600 | RGB |  | 84 | `f0e47ffcc765` | **X** |
| `B2Evidence.webp` | 800×600 | RGB |  | 86 | `2af9162dd6ab` | **X** |
| `B2Family.webp` | 800×600 | RGB |  | 81 | `bd53f67ec8cd` | **X** |
| `B2Hiring.webp` | 800×600 | RGB |  | 85 | `a90d4433c086` | **X** |
| `B2Medical.webp` | 800×600 | RGB |  | 86 | `457e9cce4a54` | **X** |
| `B2Meetings.webp` | 800×600 | RGB |  | 84 | `aa3072850af0` | **X** |
| `B2Negotiation.webp` | 800×600 | RGB |  | 84 | `c276ed16e070` | **X** |
| `B2Notices.webp` | 800×600 | RGB |  | 84 | `63e09a0fb197` | **X** |
| `B2Privacy.webp` | 800×600 | RGB |  | 83 | `ade88a74cf2d` | **X** |
| `B2Public.webp` | 800×600 | RGB |  | 86 | `acc3a580b8cb` | **X** |
| `SocialDating.webp` | 800×600 | RGB |  | 86 | `15b86d078322` | **X** |
| `SocialFandom.webp` | 800×600 | RGB |  | 87 | `8ba47e3119bc` | **X** |
| `SocialFriends.webp` | 800×600 | RGB |  | 86 | `dce570ea9059` | **X** |

### `assets/illustrations/mascot/` — 15개 · 2.1 MB · 번들 O · lib 미참조 0개

가족 **F-H** · 마스코트 포즈

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `bok.png` | 1254×836 | P | 7.2 | 51 | `d5bdb6f959c4` | O |
| `magpie_celebrate.png` | 1254×1254 | P | 31.5 | 199 | `c64e65c7ca6f` | O |
| `magpie_dance.png` | 1254×1254 | P | 25.3 | 145 | `8f16f5b15d32` | O |
| `magpie_encourage.png` | 1254×1254 | P | 31.9 | 189 | `586cc0d13876` | O |
| `magpie_front.png` | 1254×1254 | P | 23.0 | 57 | `b39a6af56250` | O |
| `magpie_perched.png` | 1254×1254 | P | 20.1 | 89 | `bda81a2e9bce` | O |
| `magpie_sing.png` | 1254×1254 | P | 27.4 | 172 | `609e3f1a2119` | O |
| `magpie_sleep.png` | 1254×1254 | P | 30.8 | 181 | `bccfe65b18b1` | O |
| `magpie_tiger_together.png` | 1254×1254 | P | 38.5 | 131 | `405efa8df3cb` | O |
| `magpie_wave.png` | 1254×1254 | P | 27.2 | 144 | `b6e0beef4345` | O |
| `magpie_wingdown.png` | 1254×1254 | P | 22.9 | 147 | `f2162c9b1933` | O |
| `magpie_wingup.png` | 1254×1254 | P | 29.5 | 258 | `807a15a809f2` | O |
| `magpie_worry.png` | 1254×1254 | P | 21.0 | 110 | `d1abd834db4d` | O |
| `tiger_sitting2.png` | 640×640 | RGBA | 36.7 | 238 | `468ce156a689` | O |
| `yupjeon.png` | 1254×836 | P | 8.2 | 82 | `4a1a7f8066e7` | O |

### `assets/illustrations/onboarding/` — 2개 · 1.1 MB · 번들 O · lib 미참조 0개

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `book_scan.png` | 941×1672 | P |  | 478 | `2f8c767fb61d` | O |
| `tiger_crystal.png` | 567×760 | RGBA | 45.4 | 623 | `ab01d8184a33` | O |

### `assets/illustrations/packs/` — 14개 · 1.2 MB · 번들 O · lib 미참조 0개

가족 **F-E** · 카드 세트 (스타일 앵커: plum.webp)

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `bamboo.webp` | 800×600 | RGB |  | 90 | `807afdbea0af` | O |
| `chilbo.webp` | 800×600 | RGB |  | 84 | `0175f4874664` | O |
| `chrysanthemum.webp` | 800×600 | RGB |  | 88 | `2ccc6d924a6e` | O |
| `cloud.webp` | 800×600 | RGB |  | 82 | `e6457666fd5c` | O |
| `gwigap.webp` | 800×600 | RGB |  | 87 | `f763dafde98d` | O |
| `lotus.webp` | 800×600 | RGB |  | 86 | `ae3ff1034e46` | O |
| `manja.webp` | 800×600 | RGB |  | 86 | `f9b47d8c7ed5` | O |
| `mountain.webp` | 800×600 | RGB |  | 87 | `6bfd3f78f41f` | O |
| `octagon.webp` | 800×600 | RGB |  | 89 | `f5bfbe5d3f12` | O |
| `peony.webp` | 800×600 | RGB |  | 90 | `538575cd3d84` | O |
| `plum.webp` | 800×600 | RGB |  | 86 | `2cfed8051d3b` | O |
| `taegeuk.webp` | 800×600 | RGB |  | 85 | `134b57e57d59` | O |
| `vine.webp` | 800×600 | RGB |  | 94 | `7e1327c786c3` | O |
| `wave.webp` | 800×600 | RGB |  | 82 | `6a9cf0f7e397` | O |

### `assets/illustrations/personal_hanok_v2/a1/states/` — 16개 · 4.2 MB · 번들 O · lib 미참조 0개

가족 **F-C** · 개인 한옥 estate 1536×1152 (앵커: map/structures/sarangchae.png)

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `01_site_setout.webp` | 1536×1152 | RGB |  | 256 | `339a2ee30c78` | O |
| `02_plan_layout.webp` | 1536×1152 | RGB |  | 258 | `e222a5114c24` | O |
| `03_foundation_gidan.webp` | 1536×1152 | RGB |  | 257 | `3c83d6ca993d` | O |
| `04_cornerstones_choseok.webp` | 1536×1152 | RGB |  | 257 | `ad8e5511091f` | O |
| `05_timber_preparation.webp` | 1536×1152 | RGB |  | 261 | `29bbed9ce9a1` | O |
| `06_columns.webp` | 1536×1152 | RGB |  | 268 | `7fe24612f803` | O |
| `07_beams_changbang.webp` | 1536×1152 | RGB |  | 268 | `2f74901c1553` | O |
| `08_purlins_sangnyang.webp` | 1536×1152 | RGB |  | 268 | `6461b498cca8` | O |
| `09_rafters_roof_frame.webp` | 1536×1152 | RGB |  | 278 | `078f995d3dc3` | O |
| `10_roof_base.webp` | 1536×1152 | RGB |  | 255 | `aed5780107db` | O |
| `11_giwa_roof.webp` | 1536×1152 | RGB |  | 270 | `13f075b19c64` | O |
| `12_wall_frame_sujang.webp` | 1536×1152 | RGB |  | 271 | `f674630806ce` | O |
| `13_earth_walls.webp` | 1536×1152 | RGB |  | 272 | `4d9743c84286` | O |
| `14_ondol_maru.webp` | 1536×1152 | RGB |  | 273 | `424effedfb60` | O |
| `15_changho_finish.webp` | 1536×1152 | RGB |  | 274 | `58e75fd6720e` | O |
| `16_landscape_move_in.webp` | 1536×1152 | RGB |  | 273 | `2e460f1e3243` | O |

### `assets/illustrations/personal_hanok_v2/interiors/` — 2개 · 4.4 MB · 번들 O · lib 미참조 0개

가족 **F-C** · 개인 한옥 estate 1536×1152 (앵커: map/structures/sarangchae.png)

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `anbang_empty.png` | 1086×1448 | RGB |  | 2169 | `78709c26eede` | O |
| `daecheong_empty.png` | 1086×1448 | RGB |  | 2324 | `521f386eae48` | O |

### `assets/illustrations/personal_hanok_v2/map/` — 1개 · 2.8 MB · 번들 O · lib 미참조 0개

가족 **F-C** · 개인 한옥 estate 1536×1152 (앵커: map/structures/sarangchae.png)

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `site_base_light.png` | 1536×1152 | RGB |  | 2825 | `5d197bc17feb` | O |

### `assets/illustrations/personal_hanok_v2/map/landscape/` — 1개 · 1.2 MB · 번들 O · lib 미참조 0개

가족 **F-C** · 개인 한옥 estate 1536×1152 (앵커: map/structures/sarangchae.png)

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `rear_garden.png` | 1536×1152 | RGBA | 25.4 | 1228 | `fd95dbebcc6f` | O |

### `assets/illustrations/personal_hanok_v2/map/structures/` — 6개 · 1.1 MB · 번들 O · lib 미참조 0개

가족 **F-C** · 개인 한옥 estate 1536×1152 (앵커: map/structures/sarangchae.png)

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `anchae.png` | 1536×1152 | RGBA | 7.7 | 340 | `93cc25cbe797` | O |
| `daecheongmaru.png` | 1536×1152 | RGBA | 1.1 | 54 | `6d42d042cfe4` | O |
| `haengrangchae.png` | 1536×1152 | RGBA | 3.5 | 142 | `3ff376e182d4` | O |
| `sadang.png` | 1536×1152 | RGBA | 2.0 | 93 | `3f5cf5246a76` | O |
| `sarangchae.png` | 1536×1152 | RGBA | 12.1 | 393 | `f523e93ff700` | O |
| `sotdaeulmun.png` | 1536×1152 | RGBA | 2.8 | 112 | `33a9400b699c` | O |

### `assets/illustrations/reward/` — 3개 · 2.5 MB · 번들 O · lib 미참조 0개

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `paywall_hero.webp` | 1200×674 | RGB |  | 178 | `70cc70333ebc` | O |
| `reward_bojagi_closed.png` | 1254×1254 | RGBA | 32.4 | 1203 | `d6dbc4121a5b` | O |
| `reward_bojagi_open.png` | 1254×1254 | RGBA | 35.7 | 1224 | `9fac814f411c` | O |

### `assets/illustrations/scenes/` — 14개 · 8.5 MB · 번들 O · lib 미참조 0개

가족 **F-E** · 시나리오 배경 포스터 1086×1448

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `airport.png` | 1086×1448 | P |  | 725 | `ed5edf41748b` | O |
| `bank.png` | 1086×1448 | P |  | 706 | `a6493944665f` | O |
| `cafe.png` | 1086×1448 | P |  | 464 | `ab25496166fa` | O |
| `convenience.png` | 1086×1448 | P |  | 578 | `c040d3eccfb8` | O |
| `directions.png` | 1086×1448 | P |  | 559 | `82a971fc1c1a` | O |
| `home.png` | 1086×1448 | P |  | 611 | `282d14d65653` | O |
| `hotel.png` | 1086×1448 | P |  | 688 | `98b722507bf7` | O |
| `market.png` | 1086×1448 | P |  | 453 | `168c6f9eb38c` | O |
| `office.png` | 1086×1448 | P |  | 535 | `9f850f7a7356` | O |
| `pharmacy.png` | 896×1200 | RGB |  | 1186 | `74b7a2013b99` | O |
| `restaurant.png` | 1086×1448 | P |  | 553 | `c8320debf800` | O |
| `salon.png` | 1086×1448 | P |  | 702 | `66c06b83e8d1` | O |
| `station.png` | 1086×1448 | P |  | 471 | `1099430b7b3c` | O |
| `taxi.png` | 1086×1448 | P |  | 497 | `f2c8c37cc8e3` | O |

### `assets/illustrations/stamps/` — 14개 · 3.1 MB · 번들 O · lib 미참조 13개

가족 **F-G** · 단청 도장 14 (런타임 조립)

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `stamp_bamboo.png` | 1254×1254 | P | 75.2 | 265 | `f4407c5b681a` | **X** |
| `stamp_chilbo.png` | 512×512 | P | 73.9 | 152 | `09dc9b12e00c` | **X** |
| `stamp_chrysanthemum.png` | 1254×1254 | P | 76.8 | 329 | `f8749e8e7ce2` | **X** |
| `stamp_cloud.png` | 1254×1254 | P | 73.8 | 268 | `8ddc0590ae12` | **X** |
| `stamp_gwigap.png` | 512×512 | P | 73.1 | 138 | `d0923e08b253` | **X** |
| `stamp_lotus.png` | 1254×1254 | P | 69.6 | 242 | `26d0e46d2aab` | O |
| `stamp_manja.png` | 1254×1254 | P | 74.7 | 242 | `be9de678dcdf` | **X** |
| `stamp_mountain.png` | 1254×1254 | P | 76.1 | 385 | `2fe5a579805a` | **X** |
| `stamp_octagon.png` | 1254×1254 | P | 74.8 | 263 | `58df01d1da60` | **X** |
| `stamp_peony.png` | 512×512 | P | 73.5 | 130 | `d54a0a6b9f96` | **X** |
| `stamp_plum.png` | 1254×1254 | P | 74.1 | 323 | `12386cf8fe50` | **X** |
| `stamp_taegeuk.png` | 512×512 | P | 73.7 | 135 | `c3175164761a` | **X** |
| `stamp_vine.png` | 512×512 | P | 74.3 | 149 | `12eb2abc9312` | **X** |
| `stamp_wave.png` | 512×512 | P | 73.4 | 137 | `3027698badbf` | **X** |

### `assets/stickers/` — 30개 · 8.2 MB · 번들 O · lib 미참조 0개

가족 **F-G** · 스티커 30 (계 피드·방 꾸미기)

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `dancheong_cloud.png` | 1254×1254 | P | 40.0 | 136 | `0ab0a3050b3a` | O |
| `dancheong_flower.png` | 1254×1254 | P | 52.0 | 201 | `ac8badb6ef32` | O |
| `dancheong_hanji.png` | 1254×1254 | P | 43.9 | 118 | `153c54ca9247` | O |
| `dancheong_lantern.png` | 1254×1254 | P | 21.0 | 121 | `a3fd854ee6f3` | O |
| `dancheong_star.png` | 1254×1254 | P | 36.5 | 136 | `baedc05c6f28` | O |
| `food_hotteok.png` | 1254×1254 | P | 51.1 | 288 | `c4517cf4166e` | O |
| `food_kimbap.png` | 1254×1254 | P | 39.5 | 178 | `b948ccd5ad82` | O |
| `food_sikhye.png` | 1254×1254 | P | 48.3 | 163 | `ff07c29618dd` | O |
| `food_tea.png` | 1254×1254 | P | 33.5 | 139 | `d217a4fa54c8` | O |
| `food_tteok.png` | 1254×1254 | P | 53.1 | 198 | `394ee7e61eb3` | O |
| `hangul_best.png` | 1254×1254 | P | 28.0 | 133 | `ee938b2613d0` | O |
| `hangul_fighting.png` | 1254×1254 | P | 32.5 | 134 | `aa2d25dca83f` | O |
| `hangul_good.png` | 1254×1254 | P | 25.0 | 119 | `5d05adea2c48` | O |
| `hangul_hh.png` | 1254×1254 | P | 28.0 | 106 | `43245c70a1d0` | O |
| `hangul_kk.png` | 1254×1254 | P | 20.2 | 90 | `6297383d4d85` | O |
| `magpie_dance.png` | 1254×1254 | P | 25.4 | 141 | `872abf6b25ca` | O |
| `magpie_encourage.png` | 1254×1254 | P | 31.9 | 189 | `d73f3e51cd7e` | O |
| `magpie_sing.png` | 1254×1254 | P | 27.4 | 168 | `91bc3514bbf6` | O |
| `magpie_sleep.png` | 1254×1254 | P | 30.8 | 179 | `7fbea409c277` | O |
| `magpie_wave.png` | 1254×1254 | P | 27.2 | 141 | `cb6643c1724e` | O |
| `stamp_sticker_cheer.png` | 1254×1254 | P | 69.6 | 384 | `5a39b66017da` | O |
| `stamp_sticker_fighting.png` | 1254×1254 | RGBA | 68.6 | 1630 | `22b313b34fde` | O |
| `stamp_sticker_happy.png` | 1254×1254 | P | 68.2 | 348 | `827988879932` | O |
| `stamp_sticker_love.png` | 1254×1254 | P | 66.1 | 333 | `c6ca604d1fc2` | O |
| `stamp_sticker_well_done.png` | 1254×1254 | P | 68.2 | 731 | `95ea5ab1f5de` | O |
| `tiger_cheer.png` | 1254×1254 | P | 37.1 | 230 | `c610a953c9e6` | O |
| `tiger_clap.png` | 1254×1254 | P | 41.7 | 258 | `a70da2018b8c` | O |
| `tiger_love.png` | 1254×1254 | P | 40.8 | 212 | `6a1f7df2e555` | O |
| `tiger_sad.png` | 1254×1254 | RGBA | 38.0 | 963 | `451eed88ebfd` | O |
| `tiger_surprised.png` | 1254×1254 | P | 36.7 | 165 | `79f9b8550eb4` | O |

### `assets_unused/illustrations/gye/` — 1개 · 0.1 MB · 번들 X · lib 미참조 1개

가족 **—** · 번들 제외 (QA·원본·격리)

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `gye_showcase_courtyard_static_20260815.webp` | 1280×720 | RGB |  | 107 | `57667cb18c69` | **X** |

### `assets_unused/illustrations/hanok/` — 3개 · 1.1 MB · 번들 X · lib 미참조 2개

가족 **—** · 번들 제외 (QA·원본·격리)

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `dancheong_frame.png` | 1024×1024 | P | 41.4 | 112 | `237738cf9d5b` | **X** |
| `gate.png` | 1024×1536 | P |  | 814 | `736bec2120f0` | O |
| `madang(dark).png` | 852×1846 | P |  | 202 | `ed8971f148c7` | **X** |

### `assets_unused/pending_review/` — 1개 · 3.1 MB · 번들 X · lib 미참조 1개

가족 **—** · 번들 제외 (QA·원본·격리)

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `reference_full_estate.png` | 1536×1152 | RGB |  | 3172 | `43f96d141576` | **X** |

### `assets_unused/pending_review/a1_kit/derived/` — 29개 · 0.5 MB · 번들 X · lib 미참조 27개

가족 **—** · 번들 제외 (QA·원본·격리)

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `band_changbang.png` | 854×309 | RGBA | 2.9 | 21 | `57c70603132d` | **X** |
| `band_habang.png` | 854×309 | RGBA | 2.3 | 13 | `f2a34b22d493` | **X** |
| `band_rafter_ends.png` | 854×309 | RGBA | 0.1 | 2 | `8ee103dfb385` | **X** |
| `choseok_1.png` | 854×309 | RGBA | 0.1 | 1 | `455714aa2b82` | **X** |
| `choseok_2.png` | 854×309 | RGBA | 0.1 | 2 | `62386058f486` | **X** |
| `choseok_3.png` | 854×309 | RGBA | 0.1 | 2 | `1880c9a5f67d` | **X** |
| `choseok_4.png` | 854×309 | RGBA | 0.1 | 1 | `8bc9b9454913` | **X** |
| `choseok_5.png` | 854×309 | RGBA | 0.1 | 2 | `ff99bf9be735` | **X** |
| `choseok_6.png` | 854×309 | RGBA | 0.1 | 2 | `baf6f04c401a` | **X** |
| `choseok_7.png` | 854×309 | RGBA | 0.1 | 2 | `aa12980b7b14` | **X** |
| `choseok_8.png` | 854×309 | RGBA | 0.1 | 1 | `c6f858260283` | **X** |
| `panel_1.png` | 854×309 | RGBA | 2.5 | 16 | `2b528db1364c` | **X** |
| `panel_2.png` | 854×309 | RGBA | 2.5 | 16 | `1cccc3071378` | **X** |
| `panel_3.png` | 854×309 | RGBA | 1.7 | 12 | `bb9f1b6d7591` | **X** |
| `panel_4.png` | 854×309 | RGBA | 2.8 | 19 | `eeeb4ed8b9a1` | **X** |
| `panel_5.png` | 854×309 | RGBA | 1.7 | 12 | `3df99d50d222` | **X** |
| `panel_6.png` | 854×309 | RGBA | 2.5 | 16 | `5bc440acb000` | **X** |
| `panel_7.png` | 854×309 | RGBA | 2.5 | 16 | `56ce30c8a523` | **X** |
| `pillar_1.png` | 854×309 | RGBA | 0.6 | 4 | `0d838c9c652c` | **X** |
| `pillar_2.png` | 854×309 | RGBA | 0.7 | 5 | `eb409a2a6eae` | **X** |
| `pillar_3.png` | 854×309 | RGBA | 0.6 | 5 | `c6cabde6cf81` | **X** |
| `pillar_4.png` | 854×309 | RGBA | 0.6 | 5 | `4aa791b321bb` | **X** |
| `pillar_5.png` | 854×309 | RGBA | 0.7 | 5 | `748a20ca8853` | **X** |
| `pillar_6.png` | 854×309 | RGBA | 0.6 | 5 | `5b5b9407791a` | **X** |
| `pillar_7.png` | 854×309 | RGBA | 0.7 | 5 | `8436d3726454` | **X** |
| `pillar_8.png` | 854×309 | RGBA | 0.6 | 4 | `b9e309f2f42c` | **X** |
| `platform.png` | 854×309 | RGBA | 20.5 | 94 | `56b3fe60b3bb` | O |
| `roof.png` | 854×309 | RGBA | 37.7 | 189 | `ba4e0b766f46` | O |
| `wall_shadow.png` | 854×309 | RGBA | 2.7 | 16 | `951e311802fc` | **X** |

### `assets_unused/pending_review/a1_kit/generated/` — 14개 · 1.7 MB · 번들 X · lib 미참조 14개

가족 **—** · 번들 제외 (QA·원본·격리)

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `07_frame.png` | 854×309 | RGBA | 6.7 | 185 | `afeb194bfbd7` | **X** |
| `07_frame_aligned.png` | 854×309 | RGBA | 10.3 | 185 | `dc378ede04bf` | **X** |
| `07_frame_beams.png` | 854×309 | RGBA | 6.8 | 216 | `4ab47b3d76c8` | **X** |
| `08_frame_purlins.png` | 854×309 | RGBA | 13.5 | 216 | `8968ce9f8b59` | **X** |
| `09_frame_rafters.png` | 854×309 | RGBA | 23.4 | 318 | `8b2888611183` | **X** |
| `10_frame_roofbase.png` | 854×309 | RGBA | 27.2 | 305 | `4408f118d1de` | **X** |
| `frame_full.png` | 854×309 | RGBA | 13.5 | 216 | `7f1cf2cfc144` | **X** |
| `parts_12_sujang.png` | 854×309 | RGBA | 5.7 | 21 | `45287b89df3d` | **X** |
| `parts_13_earthwall.png` | 854×309 | RGBA | 4.7 | 30 | `89a9e2c74d1d` | **X** |
| `props_01_setout.png` | 854×309 | RGBA | 0.8 | 3 | `c1f3e73bc884` | **X** |
| `props_02_layout.png` | 854×309 | RGBA | 1.8 | 10 | `cc0a3089567d` | **X** |
| `props_05_timber.png` | 854×309 | RGBA | 1.9 | 19 | `fa9ee8fed64c` | **X** |
| `props_14_ondol.png` | 854×309 | RGBA | 0.5 | 6 | `e1ec699d1ca8` | **X** |
| `props_16_movein.png` | 854×309 | RGBA | 1.3 | 13 | `c685820f3ffb` | **X** |

### `assets_unused/pending_review/a1_kit/generated/props/` — 16개 · 0.1 MB · 번들 X · lib 미참조 16개

가족 **—** · 번들 제외 (QA·원본·격리)

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `prop_bamboo_blind.png` | 40×50 | RGBA | 77.5 | 4 | `a087a6891487` | **X** |
| `prop_brace.png` | 40×47 | RGBA | 35.9 | 2 | `00f8ee60e3f2` | **X** |
| `prop_capital_block.png` | 22×26 | RGBA | 79.2 | 1 | `ce4f82641fcb` | **X** |
| `prop_chimney.png` | 24×38 | RGBA | 80.7 | 2 | `12620a92d0cd` | **X** |
| `prop_drawing_board.png` | 60×59 | RGBA | 59.2 | 7 | `a19a69eca5e9` | **X** |
| `prop_firebox.png` | 29×27 | RGBA | 78.7 | 2 | `d86403cfeb98` | **X** |
| `prop_flower_pots.png` | 30×34 | RGBA | 58.1 | 2 | `eda1a731a303` | **X** |
| `prop_king_post.png` | 18×42 | RGBA | 92.6 | 2 | `29c538033c51` | **X** |
| `prop_lantern.png` | 16×31 | RGBA | 77.4 | 1 | `7470aafbcf09` | **X** |
| `prop_sawhorse.png` | 52×56 | RGBA | 55.5 | 6 | `c23651c0b77c` | **X** |
| `prop_stake.png` | 10×28 | RGBA | 43.9 | 0 | `d3453bc58c6d` | **X** |
| `prop_stepping_stone_shoes.png` | 46×29 | RGBA | 68.7 | 3 | `d668729d7783` | **X** |
| `prop_survey_stakes.png` | 150×136 | RGBA | 20.0 | 16 | `08a5a1fb5d7f` | **X** |
| `prop_tile_pile.png` | 34×29 | RGBA | 76.0 | 2 | `bbeb27be66e0` | **X** |
| `prop_timber_logs.png` | 58×49 | RGBA | 58.9 | 5 | `d478908e1b79` | **X** |
| `prop_timber_squared.png` | 60×48 | RGBA | 63.6 | 6 | `a1bda2f7dcdb` | **X** |

### `assets_unused/pending_review/a1_kit/model_inputs/` — 5개 · 0.5 MB · 번들 X · lib 미참조 5개

가족 **—** · 번들 제외 (QA·원본·격리)

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `06_base_4x3_q75.jpg` | 854×640 | RGB |  | 23 | `7c25e5ab1eae` | **X** |
| `06_base_4x3_q82.jpg` | 854×640 | RGB |  | 26 | `118397ba0159` | **X** |
| `06_base_4x3_q88.jpg` | 854×640 | RGB |  | 31 | `ac4ee55f40ec` | **X** |
| `06_kit_on_green_21x9_2x.jpg` | 1708×732 | RGB |  | 90 | `e16a5d8bad38` | **X** |
| `06_kit_on_green_21x9_2x.png` | 1708×732 | RGB |  | 333 | `f951e9ac5424` | **X** |

### `assets_unused/pending_review/a1_kit/qa/` — 33개 · 12.1 MB · 번들 X · lib 미참조 17개

가족 **—** · 번들 제외 (QA·원본·격리)

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `01.webp` | 1536×1152 | RGB |  | 256 | `339a2ee30c78` | O |
| `01_layer.png` | 854×309 | RGBA | 0.8 | 3 | `c1f3e73bc884` | **X** |
| `02.webp` | 1536×1152 | RGB |  | 258 | `e222a5114c24` | O |
| `02_layer.png` | 854×309 | RGBA | 1.8 | 10 | `cc0a3089567d` | **X** |
| `03.webp` | 1536×1152 | RGB |  | 257 | `3c83d6ca993d` | O |
| `03_layer.png` | 854×309 | RGBA | 20.5 | 94 | `56b3fe60b3bb` | **X** |
| `04.webp` | 1536×1152 | RGB |  | 257 | `ad8e5511091f` | O |
| `04_layer.png` | 854×309 | RGBA | 20.5 | 96 | `f67e4318bbdc` | **X** |
| `05.webp` | 1536×1152 | RGB |  | 261 | `29bbed9ce9a1` | O |
| `05_layer.png` | 854×309 | RGBA | 21.1 | 106 | `dfe698db0196` | **X** |
| `06.webp` | 1536×1152 | RGB |  | 268 | `7fe24612f803` | O |
| `06_layer.png` | 854×309 | RGBA | 27.1 | 130 | `8197f9a08b49` | **X** |
| `07.webp` | 1536×1152 | RGB |  | 268 | `2f74901c1553` | O |
| `07_layer.png` | 854×309 | RGBA | 33.5 | 161 | `d9d6bb596530` | **X** |
| `08.webp` | 1536×1152 | RGB |  | 268 | `6461b498cca8` | O |
| `08_layer.png` | 854×309 | RGBA | 40.3 | 194 | `f430a7f82db1` | **X** |
| `09.webp` | 1536×1152 | RGB |  | 278 | `078f995d3dc3` | O |
| `09_layer.png` | 854×309 | RGBA | 50.0 | 273 | `acc237a3f948` | **X** |
| `10.webp` | 1536×1152 | RGB |  | 255 | `aed5780107db` | O |
| `10_layer.png` | 854×309 | RGBA | 55.4 | 253 | `698da00a8905` | **X** |
| `11.webp` | 1536×1152 | RGB |  | 270 | `13f075b19c64` | O |
| `11_layer.png` | 854×309 | RGBA | 66.9 | 325 | `bb3881ea8e34` | **X** |
| `12.webp` | 1536×1152 | RGB |  | 271 | `f674630806ce` | O |
| `12_layer.png` | 854×309 | RGBA | 71.5 | 339 | `81b0cec61c27` | **X** |
| `13.webp` | 1536×1152 | RGB |  | 272 | `4d9743c84286` | O |
| `13_layer.png` | 854×309 | RGBA | 75.5 | 359 | `c7849b30bd80` | **X** |
| `14.webp` | 1536×1152 | RGB |  | 273 | `424effedfb60` | O |
| `14_layer.png` | 854×309 | RGBA | 75.7 | 362 | `718d8202c36d` | **X** |
| `15.webp` | 1536×1152 | RGB |  | 274 | `58e75fd6720e` | O |
| `15_layer.png` | 854×309 | RGBA | 81.7 | 399 | `344f3656f6ca` | **X** |
| `16.webp` | 1536×1152 | RGB |  | 273 | `2e460f1e3243` | O |
| `16_layer.png` | 854×309 | RGBA | 81.8 | 403 | `bdfebdba036c` | **X** |
| `contact_sheet_a1_16.png` | 1950×1542 | RGB |  | 4618 | `d9a3a2ad2a99` | **X** |

### `assets_unused/pending_review/a1_kit/raw/` — 6개 · 26.5 MB · 번들 X · lib 미참조 6개

가족 **—** · 번들 제외 (QA·원본·격리)

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `07_frame_bbanana_260fb037.jpg` | 2400×1792 | RGB |  | 1807 | `c9fc5289bb35` | **X** |
| `07_frame_v2_p9hh9hpg.png` | 3168×1344 | RGB |  | 4604 | `c1aaef0bb8e0` | **X** |
| `09_rafters_gvi46an1e.png` | 3168×1344 | RGB |  | 5018 | `d8878ab17c5b` | **X** |
| `10_roofbase_35cc4126.png` | 2752×1536 | RGBA | 100.0 | 5884 | `afc9f530cafd` | **X** |
| `13_earthwall_texture_bce56a89.png` | 2400×1792 | RGBA | 100.0 | 8135 | `e49e54f0c9ee` | **X** |
| `props_sheet_5baedfca.jpg` | 2400×1792 | RGB |  | 1634 | `73e539a955bf` | **X** |

### `assets_unused/pending_review/a1_layers/` — 6개 · 1.5 MB · 번들 X · lib 미참조 6개

가족 **—** · 번들 제외 (QA·원본·격리)

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `05_timber_preparation_layer.png` | 854×309 | RGBA | 27.5 | 174 | `aa9bca77204f` | **X** |
| `06_columns_layer.png` | 854×309 | RGBA | 32.0 | 206 | `37a4f3554ac7` | **X** |
| `07_beams_changbang_layer.png` | 854×309 | RGBA | 35.8 | 223 | `17f5b7010422` | **X** |
| `08_purlins_sangnyang_layer.png` | 854×309 | RGBA | 41.9 | 258 | `55cacd7ce2e8` | **X** |
| `09_rafters_roof_frame_layer.png` | 854×309 | RGBA | 48.2 | 326 | `302e56c988e4` | **X** |
| `10_roof_base_layer.png` | 854×309 | RGBA | 51.5 | 323 | `1ac3706b14c6` | **X** |

### `assets_unused/pending_review/a1_layers/raw/` — 6개 · 8.6 MB · 번들 X · lib 미참조 6개

가족 **—** · 번들 제외 (QA·원본·격리)

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `05_timber_preparation_imagegen_20260817.png` | 2160×728 | RGBA | 25.3 | 782 | `8e7ed71d53e9` | **X** |
| `06_columns_imagegen_20260817.png` | 2172×724 | RGBA | 27.9 | 940 | `e4c4c6874bde` | **X** |
| `07_beams_changbang_semantic_recraft_20260817.png` | 2172×724 | RGBA | 34.1 | 1521 | `7d5bafe5720a` | **X** |
| `08_purlins_sangnyang_recraft_20260817.png` | 2172×724 | RGBA | 40.3 | 1664 | `e7937f32ebc9` | **X** |
| `09_rafters_roof_frame_recraft_20260817.png` | 2172×724 | RGBA | 47.6 | 1902 | `89661c1d1c2d` | **X** |
| `10_roof_base_recraft_20260817.png` | 2172×724 | RGBA | 51.5 | 1962 | `25c0dfd28424` | **X** |

### `assets_unused/pending_review/a1_layers/rejected/` — 11개 · 13.9 MB · 번들 X · lib 미참조 11개

가족 **—** · 번들 제외 (QA·원본·격리)

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `05_timber_preparation_baked_checkerboard_imagegen_20260817.png` | 2149×732 | RGB |  | 1192 | `a79e34e512d3` | **X** |
| `07_beams_changbang_alpha_edit_still_rgb_imagegen_20260817.png` | 2172×724 | RGB |  | 1580 | `c6c957b56d86` | **X** |
| `07_beams_changbang_baked_checkerboard_geometry_drift_imagegen_20260817.png` | 1802×873 | RGB |  | 1467 | `17f61d8502f5` | **X** |
| `07_beams_changbang_baked_checkerboard_wide_imagegen_20260817.png` | 2172×724 | RGB |  | 1501 | `4877d172013d` | **X** |
| `07_beams_changbang_midrails_composite_20260817.webp` | 1536×1152 | RGB |  | 279 | `4b8d657d90dc` | **X** |
| `07_beams_changbang_midrails_layer_20260817.png` | 854×309 | RGBA | 40.4 | 251 | `b097e9807bce` | **X** |
| `07_beams_changbang_midrails_recraft_20260817.png` | 2172×724 | RGBA | 38.7 | 1684 | `85a53d16e13b` | **X** |
| `07_beams_changbang_semantic_baked_checkerboard_imagegen_20260817.png` | 2172×724 | RGB |  | 1355 | `62e869ee9f49` | **X** |
| `08_purlins_sangnyang_baked_checkerboard_imagegen_20260817.png` | 2172×724 | RGB |  | 1479 | `4f1d8dc0d096` | **X** |
| `09_rafters_roof_frame_baked_checkerboard_imagegen_20260817.png` | 2172×724 | RGB |  | 1665 | `b0bd94cdbab6` | **X** |
| `10_roof_base_baked_checkerboard_imagegen_20260817.png` | 2172×724 | RGB |  | 1748 | `e948b861ffbc` | **X** |

### `assets_unused/pending_review/a1_states/` — 16개 · 4.2 MB · 번들 X · lib 미참조 0개

가족 **—** · 번들 제외 (QA·원본·격리)

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `01_site_setout.webp` | 1536×1152 | RGB |  | 256 | `339a2ee30c78` | O |
| `02_plan_layout.webp` | 1536×1152 | RGB |  | 258 | `e222a5114c24` | O |
| `03_foundation_gidan.webp` | 1536×1152 | RGB |  | 257 | `3c83d6ca993d` | O |
| `04_cornerstones_choseok.webp` | 1536×1152 | RGB |  | 257 | `ad8e5511091f` | O |
| `05_timber_preparation.webp` | 1536×1152 | RGB |  | 261 | `29bbed9ce9a1` | O |
| `06_columns.webp` | 1536×1152 | RGB |  | 268 | `7fe24612f803` | O |
| `07_beams_changbang.webp` | 1536×1152 | RGB |  | 268 | `2f74901c1553` | O |
| `08_purlins_sangnyang.webp` | 1536×1152 | RGB |  | 268 | `6461b498cca8` | O |
| `09_rafters_roof_frame.webp` | 1536×1152 | RGB |  | 278 | `078f995d3dc3` | O |
| `10_roof_base.webp` | 1536×1152 | RGB |  | 255 | `aed5780107db` | O |
| `11_giwa_roof.webp` | 1536×1152 | RGB |  | 270 | `13f075b19c64` | O |
| `12_wall_frame_sujang.webp` | 1536×1152 | RGB |  | 271 | `f674630806ce` | O |
| `13_earth_walls.webp` | 1536×1152 | RGB |  | 272 | `4d9743c84286` | O |
| `14_ondol_maru.webp` | 1536×1152 | RGB |  | 273 | `424effedfb60` | O |
| `15_changho_finish.webp` | 1536×1152 | RGB |  | 274 | `58e75fd6720e` | O |
| `16_landscape_move_in.webp` | 1536×1152 | RGB |  | 273 | `2e460f1e3243` | O |

### `assets_unused/pending_review/a2_furnishing/model_inputs/` — 2개 · 1.6 MB · 번들 X · lib 미참조 2개

가족 **—** · 번들 제외 (QA·원본·격리)

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `a2_style_ref_sheet_v1.png` | 2048×1536 | RGB |  | 1523 | `23443df0bdc7` | **X** |
| `a2_style_ref_sheet_v1_1024.webp` | 1024×768 | RGB |  | 70 | `357cd84a8e43` | **X** |

### `docs/assets/` — 7개 · 5.4 MB · 번들 X · lib 미참조 1개

가족 **—** · 문서·홈페이지·프롬프트 자료

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `favicon.png` | 200×200 | RGB |  | 33 | `e0236353a40d` | **X** |
| `gate.png` | 1024×1536 | P |  | 814 | `736bec2120f0` | O |
| `logo.png` | 600×600 | RGB |  | 277 | `8fdc95f2b08e` | O |
| `magpie.png` | 1536×2752 | RGB |  | 1631 | `4923d16154c4` | O |
| `tiger.png` | 1254×1254 | P | 38.0 | 167 | `6b10d18b9b4e` | O |
| `tiger_celebrate.png` | 1254×1254 | P | 41.7 | 299 | `dbcc547f2687` | O |
| `welcome-hero.png` | 1254×1254 | RGB |  | 2275 | `904fa57e11c2` | O |

### `docs/assets/refs/` — 9개 · 1.9 MB · 번들 X · lib 미참조 2개

가족 **—** · 문서·홈페이지·프롬프트 자료

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `magpie_wingdown.png` | 1254×1254 | P | 22.9 | 159 | `5b7b1f340ab2` | O |
| `magpie_wingup.png` | 1254×1254 | P | 29.5 | 176 | `e029db9d9bb1` | O |
| `scene_cafe.png` | 1086×1448 | P | 61.4 | 165 | `64e63cec4896` | O |
| `scene_directions.png` | 1086×1448 | P | 39.3 | 155 | `a3ff5cf1aa83` | O |
| `scene_hotel.png` | 1086×1448 | P | 60.3 | 151 | `d88e38a90d41` | O |
| `scene_market.png` | 1086×1448 | P | 59.1 | 145 | `cddd5632cb0c` | O |
| `scene_restaurant.png` | 1086×1448 | P | 60.9 | 166 | `766b27463a37` | O |
| `stage_tile_complete_light.png` | 841×1870 | P |  | 604 | `dcd3faf83f8f` | **X** |
| `tiger_happy.png` | 1254×1254 | P | 41.4 | 178 | `6851f94795d3` | **X** |

### `docs/assets/riso_samples_2026-08-14/` — 6개 · 0.7 MB · 번들 X · lib 미참조 6개

가족 **—** · 문서·홈페이지·프롬프트 자료

| 파일 | 크기 | mode | alpha% | KB | sha256[:12] | lib 참조 |
|---|---|---|---:|---:|---|:--:|
| `bamboo.before.webp` | 800×600 | RGB |  | 91 | `17618cf79860` | **X** |
| `bamboo.riso_v2.webp` | 800×600 | RGB |  | 92 | `bd2ee9229644` | **X** |
| `listening.before.webp` | 800×600 | RGB |  | 89 | `8535225dbc10` | **X** |
| `listening.riso_v2.webp` | 800×600 | RGB |  | 90 | `3cda06b8e30c` | **X** |
| `paywall_hero.before.webp` | 1200×674 | RGB |  | 176 | `1e4a298559fe` | **X** |
| `paywall_hero.riso_v2.webp` | 1200×674 | RGB |  | 170 | `9593048211f0` | **X** |
