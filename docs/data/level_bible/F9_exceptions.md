# F9 -- 예외표 (앱 고유 문법 · A1 유지 어휘 · 문화어)

> 생성: `python tool/build_level_bible_tables.py` (plan §3.F, T1.4). 직접 편집 금지.
> `사유` 칸이 비어 있는 행은 Fable 룰링 대기.

## 수사 -- 레벨과 무관하게 A1 유지

| 항목 | 결정 | 사유 |
|---|---|---|
| 하나 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 둘 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 셋 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 넷 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 다섯 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 여섯 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 일곱 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 여덟 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 아홉 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 열 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 일 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 이 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 삼 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 사 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 오 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 육 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 칠 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 팔 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 구 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 십 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 백 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 천 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 만 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |

## 감탄·인사 표현 -- 레벨과 무관하게 A1 유지

| 항목 | 결정 | 사유 |
|---|---|---|
| 화이팅 | A1 유지 | 감탄·인사 표현은 사전 등급과 무관하게 A1(plan §3.E) |
| 별말씀을요 | A1 유지 | 감탄·인사 표현은 사전 등급과 무관하게 A1(plan §3.E) |
| 천만에요 | A1 유지 | 감탄·인사 표현은 사전 등급과 무관하게 A1(plan §3.E) |

## 브랜드/고유명사 -- 등급 제외 (grade=None, 미검출로도 안 잡힘)

> T2.4a(B6) 추가, LCP PR-L2a2(2026-09-07)부터 자동 생성 --
> `tool/cefr_lexicon.py`의 `PROPER_NOUN_EXCLUSIONS`가 정본. 인물명
> (`EXTRA_PROPER_NOUNS`)과 동일한 `_match_proper_noun` 메커니즘.

| 항목 | 결정 | 사유 |
|---|---|---|
| 네이버 | 등급 제외 | 브랜드/제품명은 국립국어원 등급표 대상이 아님(plan §3.E 준용) |
| 배민 | 등급 제외 | 브랜드/제품명은 국립국어원 등급표 대상이 아님(plan §3.E 준용) |
| 유튜브 | 등급 제외 | 브랜드/제품명은 국립국어원 등급표 대상이 아님(plan §3.E 준용) |
| 인스타그램 | 등급 제외 | 브랜드/제품명은 국립국어원 등급표 대상이 아님(plan §3.E 준용) |
| 지도앱 | 등급 제외 | 브랜드/제품명은 국립국어원 등급표 대상이 아님(plan §3.E 준용) |
| 카카오톡 | 등급 제외 | 브랜드/제품명은 국립국어원 등급표 대상이 아님(plan §3.E 준용) |
| 카톡 | 등급 제외 | 브랜드/제품명은 국립국어원 등급표 대상이 아님(plan §3.E 준용) |
| 쿠팡 | 등급 제외 | 브랜드/제품명은 국립국어원 등급표 대상이 아님(plan §3.E 준용) |

또한 라틴 문자·숫자가 하나라도 섞인 토큰(예: `QR`)은 고정 목록이 아니라
`cefr_lexicon._is_latin_or_digit_token`으로 일괄 판정 -- 이 표에는 열거하지 않음.

## 레벨 예외표(등급 상한)

> T2.5 추가, LCP PR-L2a(2026-09-07)부터 자동 생성 --
> `tools/content_factory/lexicon/level_exceptions.csv`가 정본, 이 표는 그
> 스냅샷. `tool/cefr_lexicon.py`의 `CefrLexicon._exception_lookup`이
> word_grade/phrase_grade/sentence_profile 전 경로에서 해당 표제어의 등급을
> `상한` 칸까지 낮춘다(카테고리별 사유는 plan §3.E/§14, Fable 룰링
> 2026-09-07 참고).

| 카테고리 | 표제어 | 상한 | 사유 |
|---|---|---|---|
| kinship | 장인어른 | A1 | 혼인 친족 호칭 · Fable 룰링 2026-09-07 · A1 유지 |
| kinship | 장모님 | A1 | 혼인 친족 호칭 · Fable 룰링 2026-09-07 · A1 유지 |
| kinship | 시아버지 | A1 | 혼인 친족 호칭 · Fable 룰링 2026-09-07 · A1 유지 |
| kinship | 시어머니 | A1 | 혼인 친족 호칭 · Fable 룰링 2026-09-07 · A1 유지 |
| kinship | 아버님 | A1 | 혼인 친족 호칭 · Fable 룰링 2026-09-07 · A1 유지 |
| kinship | 어머님 | A1 | 혼인 친족 호칭 · Fable 룰링 2026-09-07 · A1 유지 |
| kinship | 형님 | A1 | 혼인 친족 호칭 · Fable 룰링 2026-09-07 · A1 유지 |
| kinship | 아주버님 | A1 | 혼인 친족 호칭 · Fable 룰링 2026-09-07 · A1 유지 |
| kinship | 도련님 | A1 | 혼인 친족 호칭 · Fable 룰링 2026-09-07 · A1 유지 |
| kinship | 처남 | A1 | 혼인 친족 호칭 · Fable 룰링 2026-09-07 · A1 유지 |
| kinship | 처형 | A1 | 혼인 친족 호칭 · Fable 룰링 2026-09-07 · A1 유지 |
| kinship | 처제 | A1 | 혼인 친족 호칭 · Fable 룰링 2026-09-07 · A1 유지 |
| kinship | 올케 | A1 | 혼인 친족 호칭 · Fable 룰링 2026-09-07 · A1 유지 |
| kinship | 며느리 | A1 | 혼인 친족 호칭 · Fable 룰링 2026-09-07 · A1 유지 |
| kinship | 사위 | A1 | 혼인 친족 호칭 · Fable 룰링 2026-09-07 · A1 유지 |
| kinship | 시댁 | A1 | 혼인 친족 호칭 · Fable 룰링 2026-09-07 · A1 유지 |
| kinship | 처가 | A1 | 혼인 친족 호칭 · Fable 룰링 2026-09-07 · A1 유지 |
| meta | 발음 | A1 | 학습 메타어 · Fable 룰링 2026-09-07 · A1 유지 |
| meta | 예문 | A1 | 학습 메타어 · Fable 룰링 2026-09-07 · A1 유지 |
| meta | 높임말 | A1 | 학습 메타어 · Fable 룰링 2026-09-07 · A1 유지 |
| meta | 호칭 | A1 | 학습 메타어 · Fable 룰링 2026-09-07 · A1 유지 |
| meta | 반말 | A1 | 학습 메타어 · Fable 룰링 2026-09-07 · A1 유지 |
| meta | 존댓말 | A1 | 학습 메타어 · Fable 룰링 2026-09-07 · A1 유지 |
| meta | 문법 | A1 | 학습 메타어 · Fable 룰링 2026-09-07 · A1 유지 |
| meta | 단어 | A1 | 학습 메타어 · Fable 룰링 2026-09-07 · A1 유지 |
| meta | 문장 | A1 | 학습 메타어 · Fable 룰링 2026-09-07 · A1 유지 |
| meta | 뜻 | A1 | 학습 메타어 · Fable 룰링 2026-09-07 · A1 유지 |
| meta | 표현 | A1 | 학습 메타어 · Fable 룰링 2026-09-07 · A1 유지 |
| signage_a1 | 창구 | A1 | 표지판·거래 기초어 · Fable 룰링 2026-09-07 · A1 유지 |
| signage_a1 | 계산대 | A1 | 표지판·거래 기초어 · Fable 룰링 2026-09-07 · A1 유지 |
| signage_a1 | 출구 | A1 | 표지판·거래 기초어 · Fable 룰링 2026-09-07 · A1 유지 |
| signage_a1 | 입구 | A1 | 표지판·거래 기초어 · Fable 룰링 2026-09-07 · A1 유지 |
| signage_a1 | 영수증 | A1 | 표지판·거래 기초어 · Fable 룰링 2026-09-07 · A1 유지 |
| signage_a1 | 현금 | A1 | 표지판·거래 기초어 · Fable 룰링 2026-09-07 · A1 유지 |
| signage_a1 | 결제 | A1 | 표지판·거래 기초어 · Fable 룰링 2026-09-07 · A1 유지 |
| signage_a1 | 결제하다 | A1 | 표지판·거래 기초어 · Fable 룰링 2026-09-07 · A1 유지 |
| signage_a1 | 우편함 | A1 | 표지판·거래 기초어 · Fable 룰링 2026-09-07 · A1 유지 |
| signage_a1 | 계산서 | A1 | 표지판·거래 기초어 · Fable 룰링 2026-09-07 · A1 유지 |
| signage_a2 | 환승 | A2 | 안내문·기기 화면 어휘 · Fable 룰링 2026-09-07 · A2 상한 |
| signage_a2 | 승강장 | A2 | 안내문·기기 화면 어휘 · Fable 룰링 2026-09-07 · A2 상한 |
| signage_a2 | 개찰구 | A2 | 안내문·기기 화면 어휘 · Fable 룰링 2026-09-07 · A2 상한 |
| signage_a2 | 잔액 | A2 | 안내문·기기 화면 어휘 · Fable 룰링 2026-09-07 · A2 상한 |
| signage_a2 | 입금 | A2 | 안내문·기기 화면 어휘 · Fable 룰링 2026-09-07 · A2 상한 |
| signage_a2 | 입금하다 | A2 | 안내문·기기 화면 어휘 · Fable 룰링 2026-09-07 · A2 상한 |
| signage_a2 | 출금 | A2 | 안내문·기기 화면 어휘 · Fable 룰링 2026-09-07 · A2 상한 |
| signage_a2 | 출금하다 | A2 | 안내문·기기 화면 어휘 · Fable 룰링 2026-09-07 · A2 상한 |
| signage_a2 | 송금 | A2 | 안내문·기기 화면 어휘 · Fable 룰링 2026-09-07 · A2 상한 |
| signage_a2 | 송금하다 | A2 | 안내문·기기 화면 어휘 · Fable 룰링 2026-09-07 · A2 상한 |
| signage_a2 | 보관함 | A2 | 안내문·기기 화면 어휘 · Fable 룰링 2026-09-07 · A2 상한 |
| signage_a2 | 안내데스크 | A2 | 안내문·기기 화면 어휘 · Fable 룰링 2026-09-07 · A2 상한 |
| signage_a2 | 운영시간 | A2 | 안내문·기기 화면 어휘 · Fable 룰링 2026-09-07 · A2 상한 |
| signage_a2 | 정기권 | A2 | 안내문·기기 화면 어휘 · Fable 룰링 2026-09-07 · A2 상한 |
| signage_a2 | 미세먼지 | A2 | 안내문·기기 화면 어휘 · Fable 룰링 2026-09-07 · A2 상한 |
| signage_a2 | 일교차 | A2 | 안내문·기기 화면 어휘 · Fable 룰링 2026-09-07 · A2 상한 |
| signage_a2 | 교통카드 | A2 | 안내문·기기 화면 어휘 · Fable 룰링 2026-09-07 · A2 상한 |
| signage_a2 | 휴게소 | A2 | 안내문·기기 화면 어휘 · Fable 룰링 2026-09-07 · A2 상한 |
| loanword | 스트레칭 | A2 | 독일어·영어 화자에게 투명한 외래어 · Fable 룰링 2026-09-07 · A2 상한 |
| loanword | 트레이너 | A2 | 독일어·영어 화자에게 투명한 외래어 · Fable 룰링 2026-09-07 · A2 상한 |
| loanword | 헬스장 | A2 | 독일어·영어 화자에게 투명한 외래어 · Fable 룰링 2026-09-07 · A2 상한 |
| loanword | 스탬프 | A2 | 독일어·영어 화자에게 투명한 외래어 · Fable 룰링 2026-09-07 · A2 상한 |
| loanword | 라벨 | A2 | 독일어·영어 화자에게 투명한 외래어 · Fable 룰링 2026-09-07 · A2 상한 |
| loanword | 커트 | A2 | 독일어·영어 화자에게 투명한 외래어 · Fable 룰링 2026-09-07 · A2 상한 |
| loanword | 스타일리스트 | A2 | 독일어·영어 화자에게 투명한 외래어 · Fable 룰링 2026-09-07 · A2 상한 |
| loanword | 이모티콘 | A2 | 독일어·영어 화자에게 투명한 외래어 · Fable 룰링 2026-09-07 · A2 상한 |
| loanword | 밴드 | A2 | 독일어·영어 화자에게 투명한 외래어 · Fable 룰링 2026-09-07 · A2 상한 |
| loanword | 파일 | A2 | 독일어·영어 화자에게 투명한 외래어 · Fable 룰링 2026-09-07 · A2 상한 |
| loanword | 메일 | A2 | 독일어·영어 화자에게 투명한 외래어 · Fable 룰링 2026-09-07 · A2 상한 |
| loanword | 이메일 | A2 | 독일어·영어 화자에게 투명한 외래어 · Fable 룰링 2026-09-07 · A2 상한 |
| loanword | 코드 | A2 | 독일어·영어 화자에게 투명한 외래어 · Fable 룰링 2026-09-07 · A2 상한 |
| loanword | 앱 | A2 | 독일어·영어 화자에게 투명한 외래어 · Fable 룰링 2026-09-07 · A2 상한 |
| loanword | 카드 | A2 | 독일어·영어 화자에게 투명한 외래어 · Fable 룰링 2026-09-07 · A2 상한 |
| loanword | 샴푸 | A2 | 독일어·영어 화자에게 투명한 외래어 · Fable 룰링 2026-09-07 · A2 상한 |
| loanword | 린스 | A2 | 독일어·영어 화자에게 투명한 외래어 · Fable 룰링 2026-09-07 · A2 상한 |
| loanword | 인터넷 | A2 | 독일어·영어 화자에게 투명한 외래어 · Fable 룰링 2026-09-07 · A2 상한 |
| culture_basic | 송편 | A1 | 명절·음식 문화어 · Fable 룰링 2026-09-07 · A1 유지 |
| culture_basic | 한가위 | A1 | 명절·음식 문화어 · Fable 룰링 2026-09-07 · A1 유지 |
| culture_basic | 세배 | A1 | 명절·음식 문화어 · Fable 룰링 2026-09-07 · A1 유지 |
| culture_basic | 세뱃돈 | A1 | 명절·음식 문화어 · Fable 룰링 2026-09-07 · A1 유지 |
| culture_basic | 덕담 | A1 | 명절·음식 문화어 · Fable 룰링 2026-09-07 · A1 유지 |
| culture_basic | 설빔 | A1 | 명절·음식 문화어 · Fable 룰링 2026-09-07 · A1 유지 |
| culture_basic | 복주머니 | A1 | 명절·음식 문화어 · Fable 룰링 2026-09-07 · A1 유지 |
| culture_basic | 한복 | A1 | 명절·음식 문화어 · Fable 룰링 2026-09-07 · A1 유지 |
| culture_basic | 윷놀이 | A1 | 명절·음식 문화어 · Fable 룰링 2026-09-07 · A1 유지 |
| culture_basic | 떡국 | A1 | 명절·음식 문화어 · Fable 룰링 2026-09-07 · A1 유지 |
| culture_basic | 명절 | A1 | 명절·음식 문화어 · Fable 룰링 2026-09-07 · A1 유지 |
| culture_basic | 추석 | A1 | 명절·음식 문화어 · Fable 룰링 2026-09-07 · A1 유지 |
| culture_basic | 설날 | A1 | 명절·음식 문화어 · Fable 룰링 2026-09-07 · A1 유지 |
| culture_basic | 밑반찬 | A1 | 명절·음식 문화어 · Fable 룰링 2026-09-07 · A1 유지 |
| culture_basic | 반찬 | A1 | 명절·음식 문화어 · Fable 룰링 2026-09-07 · A1 유지 |
| culture_basic | 국물 | A1 | 명절·음식 문화어 · Fable 룰링 2026-09-07 · A1 유지 |
| culture_basic | 김치 | A1 | 명절·음식 문화어 · Fable 룰링 2026-09-07 · A1 유지 |
| culture_basic | 떡볶이 | A1 | 명절·음식 문화어 · Fable 룰링 2026-09-07 · A1 유지 |
| culture_basic | 김밥 | A1 | 명절·음식 문화어 · Fable 룰링 2026-09-07 · A1 유지 |
| culture_basic | 삼겹살 | A1 | 명절·음식 문화어 · Fable 룰링 2026-09-07 · A1 유지 |
| culture_basic | 치킨 | A1 | 명절·음식 문화어 · Fable 룰링 2026-09-07 · A1 유지 |
| culture_advanced | 성묘 | A2 | 명절·제례 문화어 · Fable 룰링 2026-09-07 · A2 상한 |
| culture_advanced | 벌초 | A2 | 명절·제례 문화어 · Fable 룰링 2026-09-07 · A2 상한 |
| culture_advanced | 귀성 | A2 | 명절·제례 문화어 · Fable 룰링 2026-09-07 · A2 상한 |
| culture_advanced | 귀성길 | A2 | 명절·제례 문화어 · Fable 룰링 2026-09-07 · A2 상한 |
| culture_advanced | 차례 | A2 | 명절·제례 문화어 · Fable 룰링 2026-09-07 · A2 상한 |
| culture_advanced | 제사 | A2 | 명절·제례 문화어 · Fable 룰링 2026-09-07 · A2 상한 |
| culture_advanced | 햇과일 | A2 | 명절·제례 문화어 · Fable 룰링 2026-09-07 · A2 상한 |
| culture_advanced | 솔잎 | A2 | 명절·제례 문화어 · Fable 룰링 2026-09-07 · A2 상한 |
| culture_advanced | 보자기 | A2 | 명절·제례 문화어 · Fable 룰링 2026-09-07 · A2 상한 |
| fixed_expression | 배고프다 | A1 | 기초 감각형용사·관용 표현 · Fable 룰링 2026-09-07 · A1 유지 |
| fixed_expression | 배부르다 | A1 | 기초 감각형용사·관용 표현 · Fable 룰링 2026-09-07 · A1 유지 |
| fixed_expression | 졸리다 | A1 | 기초 감각형용사·관용 표현 · Fable 룰링 2026-09-07 · A1 유지 |
| fixed_expression | 새해 복 많이 받으세요 | A1 | 기초 감각형용사·관용 표현 · Fable 룰링 2026-09-07 · A1 유지 |
| fixed_expression | 잘 먹었습니다 | A1 | 기초 감각형용사·관용 표현 · Fable 룰링 2026-09-07 · A1 유지 |
| fixed_expression | 문제없어요 | A1 | 기초 감각형용사·관용 표현 · Fable 룰링 2026-09-07 · A1 유지 |
| culture_advanced | 송편 빚다 | A2 | 송편 만들기 행위 관용구(추석 파트너 팩) — Fable 룰링 2026-09-07 |
| culture_advanced | 빚다 | A2 | 송편·만두를 빚다 — 명절 조리 동사, Fable 룰링 2026-09-07 |
| signage_a2 | 확인 | A2 | 확인/확인하다: 영수증·예약·문자 확인 등 생존 거래어 — Fable 룰링 2026-09-07 |
| signage_a2 | 확인하다 | A2 | 확인/확인하다: 영수증·예약·문자 확인 등 생존 거래어 — Fable 룰링 2026-09-07 |

## 앱 고유 문법(F1 app_only, 95개) -- nikl 국제통용 목록에 대응 없음

> `grammar_a1_service_request`행은 F1 자동 매처가 "을1"(조사) 매칭으로
> `match` 판정하지만, 실질 근거는 2급 `-어 주다`(§4 참고)라 이 표에는
> 손으로 추가했다 -- `tool/build_level_bible_tables.py` 재실행 시
> app_only 헤더 수·목록이 자동 계산값(94개)으로 되돌아가므로 그때마다
> 이 행을 다시 채워 넣어야 한다(Fable 룰링 2026-09-07, F1b §4/§6).

| app id | 사유(Fable) |
|---|---|
| grammar_a1_approx | |
| grammar_a1_cannot_short | |
| grammar_a1_come_purpose | |
| grammar_a1_copula_polite | |
| grammar_a1_degree_question | |
| grammar_a1_duration_span | |
| grammar_a1_formal_question | |
| grammar_a1_in_front | |
| grammar_a1_long_negation | |
| grammar_a1_please_particle | |
| grammar_a1_polite_prohibition | |
| grammar_a1_service_request | 세종 1 '주세요' 요청 관용구 — A1 유지, Fable 룰링 2026-09-07 |
| grammar_a1_short_negation | |
| grammar_a1_which_question | |
| grammar_a2_after_finishing | |
| grammar_a2_among_set | |
| grammar_a2_available_if | |
| grammar_a2_future_intention | |
| grammar_a2_in_progress | |
| grammar_a2_intention_guess | |
| grammar_a2_irregular_bieup | |
| grammar_a2_irregular_digeut | |
| grammar_a2_irregular_eu | |
| grammar_a2_irregular_rieul | |
| grammar_a2_nominalizer_eum | |
| grammar_a2_noun_cause | |
| grammar_a2_permission_check_batch20 | |
| grammar_a2_preference_soft_batch20 | |
| grammar_a2_recommendation | |
| grammar_a2_shall_we_time | |
| grammar_a2_tag_confirmation | |
| grammar_b1_as_kept_doing | |
| grammar_b1_concede_but | |
| grammar_b1_conceded_context_batch20 | |
| grammar_b1_consequence | |
| grammar_b1_indirect_speech | |
| grammar_b1_irregular_hieut | |
| grammar_b1_irregular_reu | |
| grammar_b1_irregular_siot | |
| grammar_b1_planned_future | |
| grammar_b1_reason_context | |
| grammar_b1_scheduled_arrangement | |
| grammar_b1_self_should | |
| grammar_b1_skill | |
| grammar_b1_soft_request | |
| grammar_b1_soft_request_batch19 | |
| grammar_b1_state_while | |
| grammar_b1_takes_time | |
| grammar_b1_tentative_plan_batch20 | |
| grammar_b1_wish | |
| grammar_b2_addition_even | |
| grammar_b2_compared_with | |
| grammar_b2_considering_fact_batch20 | |
| grammar_b2_contrast | |
| grammar_b2_explicit_formal_request | |
| grammar_b2_formal_reference | |
| grammar_b2_formal_written_request | |
| grammar_b2_futility | |
| grammar_b2_indirect_speech | |
| grammar_b2_instead_tradeoff | |
| grammar_b2_not_automatic_conclusion | |
| grammar_b2_not_by_one_metric | |
| grammar_b2_not_only | |
| grammar_b2_only_after | |
| grammar_b2_outcome_depends | |
| grammar_b2_practically | |
| grammar_b2_pretense_contrast | |
| grammar_b2_rather_than_direct | |
| grammar_b2_shared_merit | |
| grammar_b2_summary_judgment | |
| grammar_b2_verify_human_review | |
| grammar_b2_whether_or_not | |
| grammar_b2_worry | |
| grammar_c1_difficult_to_conclude_batch20 | |
| grammar_c1_even_if_doing | |
| grammar_c1_family_framing | |
| grammar_c1_no_exaggeration | |
| grammar_c1_not_necessarily | |
| grammar_c1_rather_than | |
| grammar_c1_room_for | |
| grammar_c1_two_sides | |
| grammar_c1_unless_condition | |
| grammar_c2_as_already_set | |
| grammar_c2_as_if_framing | |
| grammar_c2_even_assuming | |
| grammar_c2_expected_assumption | |
| grammar_c2_fortunate_counterfactual | |
| grammar_c2_if_indeed | |
| grammar_c2_likely_negative | |
| grammar_c2_merely_on_grounds | |
| grammar_c2_no_matter_how | |
| grammar_c2_no_more_than_doing | |
| grammar_c2_premise_review_batch20 | |
| grammar_c2_responsibility_remains | |
| grammar_c2_wishing_to | |
