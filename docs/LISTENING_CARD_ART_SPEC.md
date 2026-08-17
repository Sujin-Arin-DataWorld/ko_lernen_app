# 듣기 카테고리 카드 아트 명세 — 72장

**정본** `lib/data/scenario_shelf.dart`(키·이모지) + `lib/l10n/app_de.arb`(표시명). 6레벨 × 12칸.
**규격** 4:3 · Nano Banana Pro 2K · 참고본 `hangulsori_styleref_packs_plum_400px.webp` · 장당 4크레딧.
**경로** `assets/illustrations/listening/{key}.webp` — 키는 아래 표 그대로(대소문자 유지). ARB 키 `listeningShelf<Key>` 와 짝.

## 공통 프롬프트 골격 (모든 장 동일)

기존 `packs/`·`activities/` 카드와 같은 세트로 보이게 하는 뼈대. 소재만 갈아끼운다.

> **⚠️ 아래 값은 기존 38장(packs 14 + activities 24)을 실측해 교정한 것이다.**
> 바이블 §1.3 의 명목 hex 를 그대로 쓰면 배경이 희고 청록이 튄다 — 실제 번들은 더 따뜻하고 탁하다.

- **배경** 한지 아이보리 **`#F4E8D0`** 단일 면, **네 변까지 꽉** — 안쪽 프레임·여백·드롭섀도 금지 (파일럿에서 2회 재발한 결함이라 프롬프트에 명시적으로 못 박을 것).
  실측 중앙값 `#F7ECD3` · 38장 중 37장이 크림(`#FAF6EC`)이 아니라 아이보리 쪽이다.
- **모서리** 우상단 적 삼각(36/38) / 좌변 적 삼각(35/38) / 우하단 **탁한 청** 삼각(35/38) / 하단 중앙 금·아이보리 대각 면.
  - 적 **`#B94B32`** — 실측. 명목 `#C24A45` 보다 어둡고 벽돌빛.
  - 청 **`#5F9A93`** — 실측. 명목 `#3D9A7F` 은 **너무 진하고 채도가 높다**(색거리 39). 그대로 쓰면 신규 72장만 청록이 튄다.
- **점 마커** 좌상단 4점 세로열(적·금·청·청) + 작은 금색 점 격자 / 우측 중상단 미러 점군.
- **소재** **화면 세로 중앙**, 폭의 35~40%를 차지하는 덩어리로. 가는 선 금지(파일럿 2번 실패 원인). 밑에 짧은 그림자.
- **표면** 한지 닥섬유가 면 **안에** 박혀 보이게 · 손으로 찍은 리소 인쇄 · 면 경계 잉크 고임 · 매트.
- **금지** 윤곽선 · 면내 그라데이션 · 인물/동물/손 · 문자·숫자·간판 · 말풍선 · 세피아 · 광택.
- **팔레트** `#F4E8D0 #FAF6EC #FFFCF2 #8E6646 #5C4028 #2A3340 #DFA951 #B94B32 #5F9A93 #8B8478` (+ 칸별 추가 1~2색 허용).

### 🔴 세이프 영역 — 상하 각 8.3%는 화면에서 잘린다

`SoriIllustratedCard` 가 이미지를 **16:10 · `BoxFit.cover`** 로 표시한다
(`lib/widgets/sori/illustrated_card.dart:44`, `:153`, `:233`). 소스는 4:3 이므로 세로가 넘쳐
**위 8.3% · 아래 8.3%가 잘려 나간다**(가시 구간 = 세로 8.3%~91.7%).

- 주제 사물·그림자·점 마커는 전부 **세로 12%~88% 안**에 둘 것.
- **"중앙 하단"에 놓지 말 것** — 기존 `packs/plum` 은 화병 바닥과 그림자가 이미 잘리기 직전이고,
  파일럿 `A1Transit` 은 교통카드 아랫부분이 실제로 잘렸다.
- 모서리 삼각은 잘려도 무방하다(면이라 잘린 티가 안 난다). 잘리면 안 되는 건 **사물과 점 마커**뿐.

**소리 파문 규약** — 듣기 앱이지만 남발하면 72장이 다 똑같아 보인다. 청취가 핵심인 칸에만, **레벨당 1~2장까지.**
얇은 동심호, 평면·기하, 발광 금지. 청 `#3D9A7F` = 들어오는 말 / 적 `#C24A45` = 내가 되묻는 말.

---

## A1 — 듣고 반응해서 하루를 넘기기

| 키 | 표시명 (DE) | 그림 소재 |
|---|---|---|
| 🚇 `A1Transit` | Einsteigen & aussteigen | 지하철 손잡이 2개(호두목·금 링) + 교통카드 비스듬히 + **청 파문** — ✅파일럿 통과 |
| 🚕 `A1Arrival` | Taxi, Flughafen & Unterkunft | 여행가방 + 열쇠고리 달린 방 열쇠 + 접힌 주소 쪽지 |
| 🏪 `A1Counter` | Läden & Schalter | 저울 접시 + 종이봉투 + 동전 세 닢 |
| ☕ `A1Cafe` | Café & Imbiss | 종이컵 + 머그 나란히(여기/포장 이분) + 김 한 줄기 |
| 🏠 `A1Home` | Zuhause & Haustür | 현관문 손잡이 + 도어락 키패드 면(숫자 없이 격자만) + 신발 한 켤레 |
| 🙇 `A1Greeting` | Begrüßung & Anrede | 마주 놓인 방석 둘 + 두 손 모은 형태의 인사 매듭 |
| 🙋 `A1Repair` | Ich hab's nicht verstanden | 두툼한 한지 한 장 + 붓 한 자루 + **청 파문 ↔ 적 파문** — ⚠️재생성 필요 |
| 💊 `A1Health` | Apotheke, Wetter & Sicherheit | 약봉지 + 알약 두 알 + 우산 손잡이 |
| 🏡 `A1Family` | Erster Besuch bei der Partnerfamilie | 보자기 싼 선물 상자 + 댓돌 위 신발 + 매화 가지 |
| 🔢 `A1Numbers` | Zahlen & Uhrzeit hören | 주판 알 + 해시계 판(숫자 없이 눈금만) |
| 📱 `A1Phone` | Anrufe & Nachrichten | 엎어놓은 스마트폰 + **청 파문** + 접힌 쪽지 |
| 🧭 `A1Wayfinding` | Wege & Schilder | 나무 방향 표지 기둥(글자 없는 화살 3개) + 돌 이정표 |

## A2 — 절차를 끝까지 밟기

| 키 | 표시명 (DE) | 그림 소재 |
|---|---|---|
| 🚉 `A2Travel` | Unterwegs, Unterkunft & Fundsachen | 분실물 보관함 서랍 반쯤 열림 + 잃어버린 장갑 한 짝 |
| 🏦 `A2Bank` | Bank, Mobilfunk & Gebühren | 통장 + 인장 + 유심 크기 작은 판 |
| 🛍️ `A2Shopping` | Kaufen & abrechnen | 장바구니 + 거스름돈 접시 + 교환을 뜻하는 화살 두 개 |
| ☕ `A2Cafe` | Café & Restaurant | 찻주전자 + 잔 둘 + 반으로 나뉜 계산서 판 |
| 💇 `A2Body` | Körper, Arzt & Sport | 가위 + 빗 + 눈금 있는 자 — 원하는 '정도'를 말하는 칸 |
| 🏢 `A2Neighbourhood` | Wohnanlage & Nachbarn | 분리수거 스티커 붙은 통 + 공동현관 벨 패널 |
| 💼 `A2Work` | Erste Schritte im Job | 인수인계 노트 + 만년필 + 근무표 격자 판 |
| 🗓️ `A2Plans` | Verabredungen & Kontakt | 접이식 달력 + 시간 조정 화살 + 우산 |
| 🏡 `A2Family` | Partnerfamilie & Feiertage | 명절 소반 + 송편 세 개 + 색동 매듭 |
| 📦 `A2Delivery` | Lieferung & Annahme | 끈 묶인 소포 + 문 앞 댓돌 + 인장 |
| 🏫 `A2Enrolment` | Anmeldung & Unterricht | 서안 위 펼친 교재 + 붓통 + 등록 서류 한 장 |
| 🧳 `A2Booking` | Buchen & Umbuchen | 여행가방 + 표 두 장 겹침 + 바뀐 날짜를 뜻하는 화살 |

## B1 — 문제가 생긴 뒤를 처리하기

| 키 | 표시명 (DE) | 그림 소재 |
|---|---|---|
| 🔧 `B1Repairs` | Reparaturen & Mängel | **어긋나 떨어진 기와 한 장** + 망치 + 사다리 발치 |
| 💸 `B1Refund` | Rückerstattung & Garantie | 되돌아가는 화살 + 영수증 + 봉인된 보증 인장 |
| 🧾 `B1Receipts` | Belege & Abrechnung | 길게 늘어진 영수증 + 항목을 가르는 붉은 선 + 주판 |
| 🚆 `B1Delay` | Terminänderung & Verspätung | 멈춘 해시계 그림자 + 대기 번호표(숫자 없이) + 갈라지는 두 갈래 길 |
| 📋 `B1Paperwork` | Unterlagen & Vollmacht | 서류 묶음 + 위임 인장 + 스캔 빛줄기 한 줄 |
| 💼 `B1Team` | Team & Übergabe | 건네지는 두루마리 + 비어 있는 방석 하나 |
| 🤝 `B1Neighbours` | Nachbarn & Gemeinschaftsräume | 공용 마당 빨랫줄 + 순번용 빈 나무패 + 빗자루 |
| ❤️ `B1Feelings` | Gefühle & Beziehung | 반쯤 풀린 매듭 + 찻잔 둘 + 매화 한 송이 |
| 🏡 `B1Family` | Nähe & Distanz in der Partnerfamilie | 반쯤 접힌 병풍 두 폭 + 사이의 빈 공간 + 찻잔 하나 |
| 🩺 `B1Insurance` | Behandlung & Versicherung | 약봉지 + 진료 카드 + 인장 찍힌 서류 |
| 🚨 `B1Incident` | Unfälle & Anzeigen | 깨진 그릇 조각 + 신고 서류 + 붉은 경고 삼각 |
| 📵 `B1Cancellation` | Kündigen & Umziehen | 끊어진 매듭 + 포장된 이삿짐 상자 + 반납 열쇠 |

## B2 — 근거로 협상하고 문서로 남기기

| 키 | 표시명 (DE) | 그림 소재 |
|---|---|---|
| 🗂️ `B2Meetings` | Besprechungen leiten | 회의 소반 + 안건 두루마리 + 모래시계 |
| 📊 `B2Evidence` | Belege & Zahlen | 주판 + 높이 다른 눈금 막대 세 개 + 출처 인장 |
| 🤝 `B2Negotiation` | Verhandeln & Bedingungen | 양팔 저울 — 한쪽에 인장, 다른 쪽에 두루마리 |
| 📄 `B2Contracts` | Verträge & Unterschrift | 펼친 계약 두루마리 + 붓 + 인주와 인장 |
| 📮 `B2Notices` | Formelle Schreiben & Widerspruch | 봉인된 서찰 + 붉은 봉인 + 되돌아오는 화살 |
| 🛄 `B2Escalation` | Eskalation unterwegs | 여행가방 + 위로 오르는 계단 세 단 + 붉은 경고 삼각 |
| 🏥 `B2Medical` | Medizin & Abrechnung | 약절구 + 청구서 + 항목을 짚는 붓 |
| 🗣️ `B2Public` | Öffentlich sprechen & schreiben | 단상 + 놋 확성 나팔 + **적 파문** + 원고 한 장 |
| 🏡 `B2Family` | Grenzen in der Partnerfamilie | 낮은 담장 한 줄 + 그 위 찻잔 하나 + 접힌 부채 |
| 👥 `B2Hiring` | Einstellung & Beurteilung | 방석 셋(하나는 비어 있음) + 서류 묶음 + 저울 |
| 🏛️ `B2Authorities` | Behörden & Genehmigungen | 관청 대문 기둥 둘 + 인장 찍힌 허가 서찰 |
| 🔒 `B2Privacy` | Daten & Einwilligung | 자물쇠 달린 나무함 + 열쇠 + 봉인된 서류 |

## C1 — 한계를 명시하며 말하기

| 키 | 표시명 (DE) | 그림 소재 |
|---|---|---|
| 🎤 `C1Briefing` | Briefing & Rederecht | 단상 + 발언 순서용 나무패 세 개 + 모래시계 |
| 📉 `C1Uncertainty` | Unsicherheit & Stichproben | 곡식 담긴 되(枡) + 흘러넘친 낱알 몇 + 눈금 |
| 🔐 `C1Access` | Zugriffsrechte & Fristen | 열쇠 꾸러미 + 모래시계 + 잠긴 함 |
| 🏡 `C1InvisibleLabor` | Unsichtbare Arbeit in der Familie | 빗자루·행주·물동이 셋 + 그 위 **표식 없는 빈 편액** |
| ⚖️ `C1Conflict` | Interessenkonflikt & Befangenheit | 한쪽으로 기운 양팔 저울 + 물러나 앉은 방석 하나 |
| 🧭 `C1Policy` | Auslegung & Ermessen | 갈래 셋으로 나뉜 길 + 나침반 판 + 규정 두루마리 |
| 🩺 `C1Consent` | Aufklärung & Einwilligung | 약절구 + 펼친 설명 서찰 + **아직 안 찍힌** 인장 |
| 🎭 `C1Critique` | Kultur- & Kunstkritik | 탈 하나 + 부채 + 펼친 화첩 |
| 🌐 `C1Mediation` | Interkulturelle Vermittlung | 마주 놓인 방석 둘 + 사이의 찻상 + **청·적 파문 교차** |
| 🧪 `C1Methodology` | Methodik & Reproduzierbarkeit | 같은 되(枡) 두 개 나란히 + 같은 양의 낱알 + 눈금자 |
| 💬 `C1Facework` | Widerspruch ohne Gesichtsverlust | 반쯤 편 부채(가림) + 그 뒤 찻잔 + 낮은 담 |
| 📚 `C1Attribution` | Zitieren & Quellenverantwortung | 쌓인 서책 + 끼워진 서표 세 개 + 인장 |

## C2 — 제도의 빈틈을 언어로 짚기

| 키 | 표시명 (DE) | 그림 소재 |
|---|---|---|
| 🤖 `C2Automation` | Automatisierte Entscheidungen | 톱니 물린 나무 기계 + 밖으로 나온 판정 패 + 되돌아오는 화살 |
| 🗄️ `C2Records` | Lücken in der Aktenlage | 서가 한 칸에 **빠진 서책 자리**(빈 틈) + 남은 서책들 |
| 🗣️ `C2Discourse` | Vorannahmen im Diskurs | 입을 가린 접힌 부채 + 그 아래 감춰진 인장 + **적 파문** |
| ⚖️ `C2Authority` | Grenzen & Widerruf von Vollmacht | 반으로 잘린 위임 두루마리 + 인장 + 되돌아가는 화살 |
| 📊 `C2Impact` | Ungleiche Auswirkungen | 높이가 크게 다른 곡식 되 세 개 + 같은 눈금자 |
| 🏡 `C2Memory` | Orte & Namen erinnern | **글자가 비워진 편액** + 이 빠진 돌담 + 앞의 작은 돌무지 |
| 🧬 `C2Ethics` | Forschungsethik & Einwilligung | 유리 약병 셋 + 봉인된 동의 서찰 + 아직 안 찍힌 인장 |
| 🕊️ `C2History` | Geschichtsschreibung & Versöhnung | 두 갈래로 갈라진 두루마리 + 사이에 놓인 흰 꽃 한 송이 |
| 💠 `C2Translation` | Ästhetik & Unübersetzbarkeit | 물에 비쳐 어긋난 달 + 옆의 실제 달항아리 + 잔물결 |
| ⏳ `C2Limitation` | Fristen & Verjährung | 모래가 거의 다 내린 모래시계 + 봉인된 서찰 + 마른 잎 |
| 🌍 `C2Jurisdiction` | Zuständigkeit & Grenzen | 두 영역을 가르는 돌담 + 양쪽에 하나씩 놓인 인장 |
| 🪞 `C2Representation` | Wer spricht für wen | 마주 세운 거울 면 둘 + 사이의 방석 하나 + **적 파문** |

---

## 소재 배분 점검 (72장이 서로 달라 보이는가)

| 반복 소재 | 등장 | 판정 |
|---|---|---|
| 인장·인주 | 12 | 레벨이 오를수록 늘어나는 게 의도 — 문서·권한의 축. 같은 각도로 그리지 말 것 |
| 두루마리·서찰 | 11 | 같은 축. 봉인/반절/펼침으로 형태를 갈라야 함 |
| 소리 파문 | 8 | 레벨당 1~2로 억제됨 ✅ |
| 찻잔 | 6 | 관계·가족 축의 표식으로 일관 ✅ |
| 저울 | 4 | 협상·이해충돌 축 ✅ |
| 모래시계 | 4 | 시간·기한 축 ✅ |
| 되(枡)·낱알 | 4 | C1/C2 표본·영향 축 ✅ |

**주의 — `🏡` 가족 칸 6개가 서로 가장 헷갈린다.** 소재를 의도적으로 갈라 뒀고, 거리가 멀어지는 서사가 소재로 읽히게 한 것이므로 **이 순서를 지킬 것**:

A1 보자기 선물 → A2 명절 소반 → B1 병풍 사이 빈 공간 → B2 낮은 담장 → C1 빈 편액 아래 살림 도구 → C2 이 빠진 돌담.

## 진행 상태

- ⚠️ `A1Transit` — 구도·질감은 통과했으나 **교통카드가 16:10 크롭에 잘린다** → 사물을 위로 올려 재생성
- ⚠️ `A1Repair` — 재생성 필요 (안쪽 흰 프레임 발생 · 붓/한지가 선처럼 가늘어 안 읽힘)
- ⬜ 나머지 70장

두 파일럿 모두 **교정 전 명세**로 뽑은 것이라, 배경·청록·세이프영역 교정을 반영해 다시 뽑아야 한다.

**크레딧** 잔액 856.7 · 72장 × 4 = 288 · 재시도 30% 포함해도 여유.

## 폐기된 접근 (되풀이하지 말 것)

- **책가도 선반 UI** — Jin 기각. 카드 그리드(Spiele 화면과 동일 구조)로 확정.
- **선반 목재 타일 / 칸 소품 12종** — 위 기각에 따라 함께 폐기.
- **`scripts/apply_riso_v2.py` 후처리** — 샘플 3장 검증 결과 육안 차이가 거의 없고 3장 모두 70KB 릴리스 한도 초과(92·90·170KB). 거칠기는 후처리가 아니라 **생성 단계 프롬프트**에서 얻는다.

---

# 인수인계 — 다음 세션이 그대로 이어받는 실행 계획

## 지금 어디까지 왔나

**결정된 것**
- 듣기 화면은 **책가도 선반이 아니라 카드 그리드**다. Spiele 탭(`SoriIllustratedCard`)과 같은 구조.
- 카테고리 72개(6레벨 × 12칸)에 **카드 일러스트 1장씩**. 정본은 위 표.
- 생성기는 **bbanana / Nano Banana Pro 2K**, 4:3, 장당 4크레딧.
- 스타일 참고본은 이미 업로드돼 있다:
  `https://uyncfjzfumputmyodmlr.supabase.co/storage/v1/object/public/public-assets/user-e15b6641-5d77-480c-85aa-0c1061b9c2cd/upload-storage/mcp-d97c841afe4a11c71c21c3757fc30658.webp`
  (= `packs/plum.webp` 400px 축소본. 매 생성 `image_urls` 에 붙인다.)

**검증으로 확정된 것** — 기존 38장(packs 14 + activities 24) 실측
- 모서리 규약 확인: 우상단 적 36/38 · 우하단 청 35/38 · 좌변 적 35/38
- 배경은 크림이 아니라 **아이보리**(37/38)
- 청 삼각의 명목 hex 는 실제보다 **너무 진하다**(색거리 39)
- 카드는 **16:10 `BoxFit.cover`** → 상하 각 8.3% 잘림

**아직 안 한 것** — 72장 전부. 파일럿 2장은 교정 전 명세로 뽑아 폐기.

## 실행 순서

### 1. 파일럿 재생성 (2장, 8크레딧)

`A1Transit` · `A1Repair` 를 **교정된 값**으로 다시 뽑는다. 교정 전 파일럿에서 재발한 결함 3종을
프롬프트에 명시적으로 못 박을 것:

1. 안쪽 흰 프레임 — `the artwork must bleed to all four edges; do NOT draw a lighter inset
   rectangle, border, paper margin or drop shadow inside the canvas`
2. 사물이 선처럼 가늘어짐 — `the subject must be a solid mass occupying 35-40% of the frame
   width, with visible volume; NOT thin lines`
3. 바닥 잘림 — `place the subject in the VERTICAL CENTRE of the frame; the top 12% and bottom
   12% must contain nothing but background and corner planes`

합격 판정: 기존 `packs/plum` · `activities/chosung` 과 나란히 놓고 (a) 배경 톤이 같은가
(b) 청 삼각이 튀지 않는가 (c) 16:10 크롭 후 사물이 온전한가. 세 개 다 통과해야 다음 단계.

### 2. 레벨 단위 배치 (12장씩 × 6, 288크레딧)

A1 → A2 → B1 → B2 → C1 → C2 순. 한 레벨 끝날 때마다 12장을 한 장으로 합쳐 Jin 검수.
레벨 안에서 서로 구분되는지, `🏡` 가족 칸이 앞 레벨과 겹치지 않는지가 판정 기준.

### 3. 후처리

- 2K PNG → **800×600 WebP q88**, 장당 70KB 이하 (기존 번들과 같은 계약)
- 저장 경로 `assets/illustrations/listening/{key}.webp` — 키는 위 표 그대로 대소문자 유지

### 4. 코드 배선

작업은 worktree `.claude/worktrees/claude+chaekgado-listening` (브랜치 `claude/chaekgado-listening`,
아직 커밋 없음)에서 한다. 72칸 taxonomy·서랍·진행도·테스트 18케이스는 이미 있고 그대로 쓴다.

| 파일 | 변경 |
|---|---|
| `lib/widgets/sori/chaekgado/chaekgado_shelf_grid.dart` | 선반 그리드 → **`SoriIllustratedCard` 그리드**로 교체 (또는 새 위젯으로 대체하고 이 파일 삭제) |
| `lib/screens/listening_library_view.dart` | 그리드 위젯 교체. 레벨 탭·상태 필터·서랍 연결은 유지 |
| `pubspec.yaml` | `- assets/illustrations/listening/` 등록 |
| `test/asset_orphan_guard_test.dart` | `dynamicDirs` 에 `'assets/illustrations/listening/': 'illustrations/listening/'` + 조립 근거 주석 (런타임 조립이라 stem 검사에 안 걸린다) |

이미지에는 `errorBuilder` 를 단다 — 자산이 없어도 폴백으로 화면이 뜨게. `PackCard`(단청 도장 폴백)가
쓰는 것과 같은 규약.

### 5. 함께 정리할 것

- `chaekgado_shelf_grid.dart` 주석의 **"54칸"이 틀렸다**(14행·118행). 실제 72칸.
- 긴 독일어 카테고리명(`Erster Besuch bei der Partnerfamilie` 등)이 카드 제목 2줄에서 잘린다.
  카드 레이아웃 확정 시 같이 정할 것.

## 크레딧

잔액 856.7 · 파일럿 8 + 본편 288 = 296 · 재시도 30% 잡아도 여유.
