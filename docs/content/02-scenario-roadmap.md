# 시나리오 양산 로드맵 — 13 → 30 (신규 17개)

> **목적**: 각 신규 시나리오의 Input Block을 사전 정의. Jin은 [`01-llm-scenario-prompt.md`](01-llm-scenario-prompt.md) 메타프롬프트에 아래 표의 한 행을 붙여 LLM에 던지면 됨.
> **순서**: B2 6개 → B1 4개 → A2 4개 → A1 3개. B2는 가장 시급 (현재 0개).
> **페이스**: 주당 4~5개 생성 + Jin 검수. 약 4주에 17개 완료.

## 현황 (verified 2026-05-21)

| Level | 기존 | 신규 | 합계 |
|---|---|---|---|
| A1 | 6 | +3 | 9 |
| A2 | 4 | +4 | 8 |
| B1 | 3 | +4 | 7 |
| B2 | 0 | +6 | 6 |
| **계** | **13** | **+17** | **30** |

기존 13개 ID (중복 회피용):
`cafe_starbucks_basic, airport_arrival, introduce_yourself, warm_encouragement, couple_argument, taxi_kakao, bunshik_tteokbokki, subway_transfer, company_dinner_hoeshik, hotel_checkin, convenience_store, pharmacy_headache, myeongdong_shopping`

---

## 🥇 우선순위 1: B2 콘텐츠 (총 6개)

B2가 현재 0개 → 상급 학습자에게 "이 앱은 여기까지" 신호. 가장 시급.

### B2-1 · `wedding_korean_guest` — 한국 결혼식 하객 인사
- **Emoji**: 💒 | **Register**: polite | **Sidekick**: `magpie` (좋은 소식 = 까치)
- **Title (de)**: Auf einer koreanischen Hochzeit
- **Intro Hook (de)**: "Deine koreanische Schwiegermutter lädt dich ein. Du musst dem Brautpaar gratulieren, dem Vater Respekt zollen, und ein Geschenkumschlag (축의금) übergeben. Wie viel? Welche Worte?"
- **Grammar Focus**: `V-(으)시-` (존댓말 종결), `N답다` (~답게 행동하다), `A/V-기를 바라다`
- **New Vocab**: 축의금, 신랑, 신부, 부케, 폐백, 사돈, 함께하시길, 행복하시길
- **Cultural Angle**: 축의금 금액 (친구 5만원, 친척 10만, 가족 20+만), 폐백 의미, 갈때 인사 ('맛있게 먹고 가요')
- **Quest mix**: hoerverstehen×2 (인사말 듣기), uebersetzen×1 (de→ko 축하 표현), particlePop×1 (~께서), schreiben×0

### B2-2 · `apartment_jeonse_contract` — 전세 계약 상담
- **Emoji**: 🏠 | **Register**: business | **Sidekick**: `jieun`
- **Title (de)**: Jeonse-Mietvertrag mit Makler
- **Intro Hook (de)**: "Du willst 1년 in Seoul wohnen. Vermieter bietet 전세 (Jeonse — Riesenkaution statt Miete). Du musst Kaution-Sicherheit, Vertragslänge, Hausverwalterregeln verhandeln. Mit Vokabular wie 보증금, 월세 nicht zu verwechseln."
- **Grammar Focus**: `A/V-기로 하다` (결정), `V-(으)ㄹ 경우에는` (조건), `N에 비해서` (비교)
- **New Vocab**: 전세, 월세, 보증금, 계약서, 등기부등본, 임대인, 임차인, 갱신
- **Cultural Angle**: 전세 vs Mietvertrag (독): 전세는 보증금 1억+ → 2년 후 전액 환급. 한국 부동산 특유 제도. 사기 위험 있어 등기부 확인 필수.
- **Quest mix**: hoerverstehen×1, luecken×2 (조사·연결어미), uebersetzen×2, particlePop×1

### B2-3 · `health_insurance_signup` — 의료보험 가입 (외국인)
- **Emoji**: 🏥 | **Register**: business | **Sidekick**: `minsu`
- **Title (de)**: Bei der Krankenversicherung anmelden
- **Intro Hook (de)**: "Du hast einen Job in Seoul — direkter Arbeitnehmer-Insurance? Oder noch Freelancer / Student — dann 지역 (lokale) Insurance. Wie unterscheidest du, was kostet, was deckt es?"
- **Grammar Focus**: `N에 가입하다`, `V-기 위해서`, `A-(으)ㄹ 뿐만 아니라`
- **New Vocab**: 국민건강보험, 직장가입자, 지역가입자, 피부양자, 보험료, 가입 신청서, 외국인등록증, 본인부담금
- **Cultural Angle**: 한국 의료보험 등록 의무 (외국인도 6개월 거주 후), 직장보험은 회사가 절반 부담. 응급실에서 무보험 시 100% 본인 부담.
- **Quest mix**: hoerverstehen×2, luecken×2, uebersetzen×1, particlePop×1

### B2-4 · `negotiation_business_meeting` — 비즈니스 가격 협상
- **Emoji**: 💼 | **Register**: business | **Sidekick**: `minsu`
- **Title (de)**: Geschäftliche Preisverhandlung
- **Intro Hook (de)**: "Du arbeitest in einer deutsch-koreanischen Firma. Der koreanische Lieferant will den Preis 8% erhöhen — Energiekosten. Du musst höflich aber bestimmt verhandeln. Format: ~합쇼체."
- **Grammar Focus**: `A/V-(으)ㄴ/는 만큼`, `V-아/어 보겠습니다` (시도), `N에 대해서`
- **New Vocab**: 단가, 인상하다, 인하하다, 발주, 납기, 단가표, 갱신 계약, 우대 조건
- **Cultural Angle**: 한국 비즈니스 미팅 격식 — 단도직입 X, 본론 전 인사·근황 5분 필수. 노 대신 "검토하겠습니다" (= 사실상 거절일 수도). 합의 후 술자리.
- **Quest mix**: hoerverstehen×2, luecken×1, uebersetzen×2, particlePop×1

### B2-5 · `news_discussion_population` — 친구와 한국 사회 뉴스 토론
- **Emoji**: 📰 | **Register**: polite | **Sidekick**: `jieun`
- **Title (de)**: Über Koreas Demografie sprechen
- **Intro Hook (de)**: "Beim Abendessen erwähnt eine Freundin Koreas Geburtenrate (0.7 — niedrigste der Welt). Du willst differenziert antworten: Sympathie + eigene Beobachtung + Frage. Ohne 'Ich find das schade' Plattheit."
- **Grammar Focus**: `A/V-(으)ㄴ 것 같다`, `A/V-기 때문에`, `N에 따라서`
- **New Vocab**: 출산율, 인구 감소, 집값, 육아휴직, 경력 단절, 세대 차이, 노동 시간, 미래
- **Cultural Angle**: 0.7 출산율 = 일본 1.2보다 훨씬 낮음. 원인 = 집값 + 일자리 + 사교육비. 외국인이 한국 사회 이슈에 의견 낼 때의 톤 (관심 표현 + 단정 회피).
- **Quest mix**: hoerverstehen×1, uebersetzen×3 (의견 표현), particlePop×1, luecken×1

### B2-6 · `drink_political_opinion` — 회식 정치 의견 조심스럽게
- **Emoji**: 🍶 | **Register**: polite | **Sidekick**: `minsu`
- **Title (de)**: Im 회식: Politik vorsichtig diskutieren
- **Intro Hook (de)**: "Beim Hoeshik fragt ein Senior nach deiner Meinung zur aktuellen Regierung. In Korea ist Politik beim Trinken... heikel. Du musst Diplomatie + Höflichkeit + eine ehrliche Linie finden."
- **Grammar Focus**: `A/V-(으)ㄴ/는 편이다` (성향), `A/V-(으)ㄹ까 봐` (염려), `N(이)나마`
- **New Vocab**: 정치, 정부, 여당, 야당, 의견, 입장, 조심스럽다, 객관적으로
- **Cultural Angle**: 한국에서 술자리 정치/종교/지역 = 지뢰. 안전한 답: "저는 잘 모르겠지만, ___님 의견은 어떠세요?" — 질문 돌려치기. 외국인 카드 사용법.
- **Quest mix**: hoerverstehen×2, luecken×2, uebersetzen×1, particlePop×1

---

## 🥈 우선순위 2: B1 콘텐츠 (총 4개)

### B1-1 · `friend_breakup_comfort` — 친구 실연 위로
- **Emoji**: 🥺 | **Register**: intimate | **Sidekick**: `magpie` (위로 = 좋은 소식의 일종)
- **Title (de)**: Einen Freund nach Trennung trösten
- **Intro Hook (de)**: "Deine Freundin Jieun schickt eine Nachricht: '나 헤어졌어...'. Du willst trösten — aber NICHT 'Es gibt mehr Fische im Meer' platt. Was sagt man? Was vermeidet man?"
- **Grammar Focus**: `V-(으)ㄹ걸 그랬다` (후회 위로), `A/V-(으)니까` (이유 친근), `N도 N이지만`
- **New Vocab**: 헤어지다, 마음, 힘들다, 시간이 약, 옆에 있다, 들어줄게, 괜찮아질 거야, 충분히
- **Cultural Angle**: 한국식 위로 = 해결책 제시 X. "들어주는 것"이 본질. "Es kommt schon gut" 같은 한 마디는 오히려 부담. 침묵 + 같이 있어주기 + "힘들겠다"가 정답.
- **Quest mix**: hoerverstehen×1, uebersetzen×2 (위로 표현 외워서), luecken×2, particlePop×1

### B1-2 · `interview_visa_first` — 취업 비자 면접 첫인사
- **Emoji**: 💼 | **Register**: business | **Sidekick**: `jieun`
- **Title (de)**: Erster Eindruck im Job-Interview
- **Intro Hook (de)**: "Du hast ein Interview bei einer Seouler Firma für ein E-7 Visum. Die ersten 90 Sekunden bestimmen alles: 자기소개 + warum Korea + warum diese Firma. Format: ~합쇼체."
- **Grammar Focus**: `N에 지원하다`, `V-게 되다`, `A/V-(으)ㄴ/는 계기로`
- **New Vocab**: 자기소개, 지원 동기, 강점, 약점, 입사, 기여하다, 노력하다, 잘 부탁드립니다
- **Cultural Angle**: 한국 면접 첫인사 표준 = "안녕하십니까, ___입니다. 잘 부탁드립니다." 명함 받기 = 두 손, 살펴보기 1초, 책상 위 보관. 노트북에 바로 넣기 = 무례.
- **Quest mix**: hoerverstehen×2, uebersetzen×2, particlePop×1, luecken×1

### B1-3 · `vacation_request_boss` — 직장 휴가 신청
- **Emoji**: 🏖️ | **Register**: polite | **Sidekick**: `minsu`
- **Title (de)**: Urlaub vom Chef erbitten
- **Intro Hook (de)**: "Du arbeitest seit 6 Monaten in Seoul. Du willst 4 Tage Urlaub für eine Hochzeit in Deutschland. Wann fragst du? Wie? In Korea ist Urlaub-Kultur anders als in DE."
- **Grammar Focus**: `V-아/어도 될까요?`, `N 때문에`, `V-(으)려고 합니다`
- **New Vocab**: 휴가, 연차, 휴가 신청서, 일정, 인수인계, 죄송하지만, 양해해 주세요, 가능할까요
- **Cultural Angle**: 한국 직장 휴가 = 독일 식 "내 권리"가 아니라 "팀에 폐 끼치는 것" 톤. 부탁하는 형식. 인수인계 명확. 미리 2-4주 통보.
- **Quest mix**: hoerverstehen×2, luecken×2, uebersetzen×1, particlePop×1

### B1-4 · `parents_video_call` — 한국에 계신 부모님 화상통화
- **Emoji**: 📱 | **Register**: polite | **Sidekick**: `jieun`
- **Title (de)**: Video-Call mit den (Schwieger-)Eltern in Korea
- **Intro Hook (de)**: "Deine koreanische Partnerin schaltet die Schwiegereltern zu KakaoTalk-Video dazu. Sie fragen: 'Hast du gegessen? Wie ist das Wetter in Berlin? Wann kommst du zu Besuch?' Du musst freundlich, formell, aber natürlich antworten."
- **Grammar Focus**: `V-(으)셨어요?` (높임 과거), `N께 안부 전해 주세요`, `A/V-(으)ㄹ까 합니다`
- **New Vocab**: 어머님, 아버님, 인사드리다, 잘 지내다, 안부, 보고 싶다, 건강하다, 댁
- **Cultural Angle**: 한국 부모 세대 첫인사 = "식사하셨어요?" (= Hi). "보고 싶어요" 직설보다 "또 뵙고 싶어요"가 자연. 화상으로 절하기는 X but 시작·끝 인사는 90도 가까이 꾸벅.
- **Quest mix**: hoerverstehen×2, uebersetzen×2, luecken×1, particlePop×1

---

## 🥉 우선순위 3: A2 콘텐츠 (총 4개)

### A2-1 · `hair_salon_cut` — 미용실에서 머리 자르기
- **Emoji**: 💇 | **Register**: polite | **Sidekick**: `jieun`
- **Title (de)**: Beim Friseur in Seoul
- **Intro Hook (de)**: "Du brauchst einen Haarschnitt. Aber 'auf 5mm' vs 'wie heute, aber kürzer' — sehr unterschiedlich. Vokabular: 다듬어주세요, 짧게, 앞머리..."
- **Grammar Focus**: `A-게` (부사화), `V-아/어 주세요`, `N만큼`
- **New Vocab**: 다듬다, 짧게, 길게, 앞머리, 옆머리, 뒤, 살짝, 그대로
- **Cultural Angle**: 한국 미용실 셋팅: 머리 감기·전체 케어 포함 가격 ~3-5만원. 팁 X. 결과 마음에 안 들면 즉시 말하기 — 다 자른 후엔 늦음.
- **Quest mix**: hoerverstehen×2, luecken×1, uebersetzen×1, particlePop×1

### A2-2 · `kakao_chat_friend` — 카카오톡 친구와 약속 잡기
- **Emoji**: 💬 | **Register**: casual | **Sidekick**: `jieun`
- **Title (de)**: Über KakaoTalk Treffen planen
- **Intro Hook (de)**: "Deine Freundin schickt 'ㅋㅋ 시간 돼?' Du willst 토요일에 만나기로 — Cafe in 합정. Wann? Wo? 카톡 줄임말, 이모지, ㅋㅋ/ㅠㅠ도 이해해야."
- **Grammar Focus**: `V-자` (반말 제안), `V-(으)ㄹ까?`, `N에서 만나`
- **New Vocab**: 시간 되다, ㅋㅋ, ㅠㅠ, 헐, 대박, 오케이, 출발, 늦었어
- **Cultural Angle**: 카톡 줄임말: ㅋ=웃음, ㅠ=울음, ㄱㅅ=감사, ㅈㅅ=죄송, ㅇㅋ=ok. 친구간 반말 + 이모지. 답장 빠른게 미덕 but 일하는 시간엔 30분 OK.
- **Quest mix**: hoerverstehen×1, luecken×2, uebersetzen×2, particlePop×1

### A2-3 · `asking_directions_local` — 길 묻기 (한국인에게)
- **Emoji**: 🗺️ | **Register**: polite | **Sidekick**: `minsu`
- **Title (de)**: Nach dem Weg fragen — analog (kein Google)
- **Intro Hook (de)**: "Dein Akku ist leer. Google Maps X. Du musst zur Adresse 강남구 역삼동 7-1. Eine 아주머니 (mittleren Alters Frau) vorbeigeht. Wie fragst du? Wie verstehst du die Antwort?"
- **Grammar Focus**: `N(으)로 가다`, `N에서 N까지`, `V-아/어서 V` (순서)
- **New Vocab**: 직진, 좌회전, 우회전, 사거리, 신호등, 건너편, 모퉁이, 몇 분
- **Cultural Angle**: 한국에서 길 안내 = 손짓 + 자세히. 모르면 "잠시만요" 후 polled by 핸드폰. "고생하세요" 인사 답변 = 길 안내 끝.
- **Quest mix**: hoerverstehen×2, uebersetzen×1, luecken×1, particlePop×1

### A2-4 · `mart_groceries_basic` — 한국 마트에서 장보기
- **Emoji**: 🛒 | **Register**: polite | **Sidekick**: `minsu`
- **Title (de)**: Wochenend-Einkauf bei E-Mart
- **Intro Hook (de)**: "Samstag E-Mart. Du suchst 두부, 라면, 김치, 사과 한 봉지. Wie liest man 1+1 Promo? Was bedeutet 시식 (Probierstand)? Plastiktüte kostet 100원 — Pfand?"
- **Grammar Focus**: `N 하나만`, `N(이)나` (선택), `얼마예요?`
- **New Vocab**: 한 봉지, 한 팩, 시식, 행사 상품, 1+1, 비닐봉투, 영수증, 적립
- **Cultural Angle**: 한국 마트 시식 코너 = 거의 모든 코너에 있음. 사야 할 의무 X. 봉투는 100원 ~ 300원 별도. 멤버십 적립 = 통신사·신용카드 연동 가능.
- **Quest mix**: hoerverstehen×1, luecken×2, uebersetzen×1, particlePop×2

---

## 🏅 우선순위 4: A1 콘텐츠 (총 3개)

### A1-1 · `restaurant_order_basic` — 일반 식당 주문 (분식 외)
- **Emoji**: 🍜 | **Register**: polite | **Sidekick**: `minsu`
- **Title (de)**: Im Restaurant bestellen
- **Intro Hook (de)**: "Hauptmahlzeit-Restaurant — nicht Bunsik. Du bestellst 김치찌개 für 2. Wie bestellt man Wasser? Wie ruft man die Bedienung? '여기요' oder klicken auf den Knopf?"
- **Grammar Focus**: `N 주세요`, `N개`, `N하고 N`
- **New Vocab**: 메뉴, 여기요, 물 한 잔, 공깃밥, 추가, 계산, 카드, 더 주세요
- **Cultural Angle**: 한국 식당 = 무료 반찬 + 무료 물 (셀프). 호출 = 손 들고 "여기요" 또는 식탁 버튼. 계산 = 카운터에서 (테이블 X). 영수증 자동.
- **Quest mix**: hoerverstehen×2, luecken×1, uebersetzen×1, particlePop×1

### A1-2 · `subway_ticket_buy` — 지하철 표 / T-money 충전
- **Emoji**: 🚇 | **Register**: polite | **Sidekick**: `minsu`
- **Title (de)**: T-Money-Karte aufladen
- **Intro Hook (de)**: "Erste U-Bahn-Fahrt in Seoul. Du hast T-money von Convenience Store. Jetzt 10,000원 aufladen am Automaten — Touchscreen + Münzen. Wie navigierst du?"
- **Grammar Focus**: `N을/를 충전하다`, `얼마 충전하시겠어요?`, `1회권`
- **New Vocab**: 교통카드, 충전, 1회권, 보증금, 환승, 영수증, 자동 발매기, 사용
- **Cultural Angle**: T-money = 버스+지하철+택시까지 (Tap). 충전 단위 1,000원. 환승 무료 (30분 내). 1회권은 비효율 — 보증금 500원 환급 시스템.
- **Quest mix**: hoerverstehen×2, luecken×2, uebersetzen×1, particlePop×0

### A1-3 · `gimbap_takeout` — 김밥집에서 포장 (분식 다른 시각)
- **Emoji**: 🍙 | **Register**: polite | **Sidekick**: `minsu`
- **Title (de)**: Gimbap zum Mitnehmen
- **Intro Hook (de)**: "Lunch break. Du willst 1줄 김밥 + 1 라면 zum Mitnehmen. Verschiedene 김밥 Sorten: 참치, 치즈, 야채. Wie wählst du? Wie sagst du 'kalt mitnehmen, ich esse später'?"
- **Grammar Focus**: `N 포장`, `N으로 주세요`, `차갑게 / 따뜻하게`
- **New Vocab**: 김밥, 줄, 참치, 야채, 치즈, 포장, 그릇, 일회용
- **Cultural Angle**: 분식 vs 한식: 분식 = 김밥/떡볶이/라면 (저렴, 빠름, 길거리). 포장 = 비닐봉투 자동. 줄 = 김밥 단위 (cylinder). 김밥천국 = 24시간.
- **Quest mix**: hoerverstehen×1, luecken×2, uebersetzen×1, particlePop×1

---

## 4주 양산 계획 (주 4~5개)

| 주차 | 산출물 |
|---|---|
| **Week 1** | B2-1 (결혼식), B2-2 (전세), B2-3 (의보), B2-4 (협상), B2-5 (사회뉴스) — B2 5개 |
| **Week 2** | B2-6 (정치), B1-1 (실연위로), B1-2 (면접), B1-3 (휴가) — 4개 |
| **Week 3** | B1-4 (부모님), A2-1 (미용실), A2-2 (카톡), A2-3 (길찾기) — 4개 |
| **Week 4** | A2-4 (마트), A1-1 (식당), A1-2 (T-money), A1-3 (김밥) — 4개 |

**검증 게이트**: 매주 끝에 추가된 시나리오 → `flutter analyze` + 에뮬레이터 5개씩 직접 플레이 (5분 × 5 = 25분).

## 끝 후 v1.0.2 릴리스

17개 추가 완료 + Track B 메타 통합 후 v1.0.2 (`pubspec.yaml 1.0.2+3`):
- 시나리오 30개
- B2 첫 도입
- Magpie 첫 등장 (결혼식, 친구 위로)
- 모듈 통합 (Track B)

→ Play Store 업데이트 description: **"콘텐츠 2배 + B2 출시 + 새로운 까치 친구 등장"**
