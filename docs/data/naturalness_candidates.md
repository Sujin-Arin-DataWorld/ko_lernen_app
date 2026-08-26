# 콘텐츠 자연성 프리필터 후보 리포트

`python tool/audit_content_naturalness.py` 로 생성 — 직접 편집 금지, 스크립트 재실행으로 갱신한다.

마커는 전부 결정적 규칙(정규식/문자열 포함/받침 유무) 기반이다. 여기 실리는 항목은 "후보"이며, 실제 어색함 여부는 Task 12 의 사람/LLM 심사가 판단한다.

## cloze.json

860건.

| id | 마커 | 문장 |
|---|---|---|
| cloze_a1_0002 | particle_mismatch | 제 ＿＿＿은 크리스티안이에요. (distractor: 친구, 누나) |
| cloze_a1_0003 | josa_dup | 나이가 몇 살이에요? |
| cloze_a1_0003 | particle_mismatch | ＿＿＿가 몇 살이에요? (distractor: 밤, 가족) |
| cloze_a1_0005 | particle_mismatch | 저는 ＿＿＿이에요. (distractor: 나라) |
| cloze_a1_0008 | particle_mismatch | ＿＿＿가 있어요. (distractor: 시간, 밖, 남동생) |
| cloze_a1_0009 | particle_mismatch | ＿＿＿가 있어요. (distractor: 목요일, 초록색) |
| cloze_a1_0010 | particle_mismatch | ＿＿＿이 몇 명이에요? (distractor: 사) |
| cloze_a1_0013 | particle_mismatch | ＿＿＿이 있어요? (distractor: 침대) |
| cloze_a1_0014 | particle_mismatch | ＿＿＿를 타요. (distractor: 분) |
| cloze_a1_0018 | particle_mismatch | ＿＿＿가 집에 있어요. (distractor: 화요일, 아홉) |
| cloze_a1_0022 | particle_mismatch | ＿＿＿가 멋있어요. (distractor: 칠, 왼쪽) |
| cloze_a1_0023 | particle_mismatch | ＿＿＿가 웃어요. (distractor: 점심, 검은색) |
| cloze_a1_0025 | particle_mismatch | ＿＿＿은 학생이에요. (distractor: 코, 위) |
| cloze_a1_0026 | particle_mismatch | ＿＿＿이 귀여워요. (distractor: 사이) |
| cloze_a1_0027 | particle_mismatch | ＿＿＿이 요리해요. (distractor: 버스) |
| cloze_a1_0028 | particle_mismatch | ＿＿＿가 일해요. (distractor: 주말, 둘) |
| cloze_a1_0029 | particle_mismatch | ＿＿＿가 아파요. (distractor: 과일, 월요일, 손) |
| cloze_a1_0030 | particle_mismatch | ＿＿＿가 길어요. (distractor: 천, 여덟, 일) |
| cloze_a1_0031 | particle_mismatch | ＿＿＿을 좋아해요. (distractor: 오) |
| cloze_a1_0032 | particle_mismatch | 하늘이 ＿＿＿이에요. (distractor: 고기, 사과) |
| cloze_a1_0033 | particle_mismatch | 나뭇잎이 ＿＿＿이에요. (distractor: 언니, 머리) |
| cloze_a1_0034 | particle_mismatch | 바나나가 ＿＿＿이에요. (distractor: 초) |
| cloze_a1_0037 | particle_mismatch | ＿＿＿를 먹어요. (distractor: 금요일, 일곱, 노란색) |
| cloze_a1_0038 | particle_mismatch | ＿＿＿을 좋아해요? (distractor: 하나) |
| cloze_a1_0039 | particle_mismatch | ＿＿＿를 많이 먹어요. (distractor: 팔, 밥, 안) |
| cloze_a1_0040 | particle_mismatch | ＿＿＿이 맛있어요. (distractor: 나이) |
| cloze_a1_0041 | particle_mismatch | ＿＿＿을 끓여요. (distractor: 아내) |
| cloze_a1_0042 | particle_mismatch | ＿＿＿가 매워요. (distractor: 눈) |
| cloze_a1_0043 | particle_mismatch | ＿＿＿를 먹어요. (distractor: 열, 아침) |
| cloze_a1_0044 | particle_mismatch | ＿＿＿을 삶아요. (distractor: 다리) |
| cloze_a1_0045 | particle_mismatch | ＿＿＿이 어디예요? (distractor: 코) |
| cloze_a1_0066 | particle_mismatch | ＿＿＿이 없어요. (distractor: 나이) |
| cloze_a1_0067 | particle_mismatch | 무슨 ＿＿＿이에요? (distractor: 친구, 언니) |
| cloze_a1_0070 | particle_mismatch | ＿＿＿이 좋아요. (distractor: 커피, 채소) |
| cloze_a1_0077 | formality_mix | 실례합니다 잠깐만요. |
| cloze_a1_0080 | particle_mismatch | 우리 ＿＿＿는 좋아요. (distractor: 일곱, 넷, 파란색) |
| cloze_a1_0106 | particle_mismatch | ＿＿＿이 어려워서 현우에게 물어봤어요. (distractor: 한가위) |
| cloze_a1_0112 | particle_mismatch | ＿＿＿를 들고 초인종을 눌렀어요. (distractor: 송편, 송편 잎) |
| cloze_a1_0114 | particle_mismatch | ＿＿＿은 부담이 된다고 현우가 말했어요. (distractor: 세배 드리다, 송편 빚다, 송편 찌다) |
| cloze_a1_0115 | particle_mismatch | 큰돈 말고 ＿＿＿이면 충분해요. (distractor: 송편 찌다, 수저 놓다, 앉으세요) |
| cloze_a1_0116 | particle_mismatch | ＿＿＿이 예쁘면 인사가 쉬워져요. (distractor: 형부) |
| cloze_a1_0120 | particle_mismatch | ＿＿＿은 편하지만 정이 없어 보일 수 있어요. (distractor: 답례) |
| cloze_a1_0121 | particle_mismatch | ＿＿＿은 예쁘지만 버스에서 들고 가기 힘들어요. (distractor: 한가위) |
| cloze_a1_0123 | particle_mismatch | 선물을 받으면 짧게 ＿＿＿를 해요. (distractor: 장인어른, 젓가락질) |
| cloze_a1_0125 | particle_mismatch | ＿＿＿가 한 짝밖에 없었어요. (distractor: 추석, 카톡, 포장) |
| cloze_a1_0127 | particle_mismatch | ＿＿＿이 서늘해서 아래로 오라고 하셨어요. (distractor: 시아버지, 시어머니) |
| cloze_a1_0128 | particle_mismatch | ＿＿＿이 따뜻해서 할머니가 앉으시는 자리예요. (distractor: 안부, 앞접시, 올케) |
| cloze_a1_0129 | particle_mismatch | 바닥에 앉으니 ＿＿＿이 먼저 아팠어요. (distractor: 차례) |
| cloze_a1_0130 | particle_mismatch | ＿＿＿을 밀어 주셔서 감사하다고 했어요. (distractor: 막내, 맏이) |
| cloze_a1_0135 | particle_mismatch | ＿＿＿은 현우가 차에서 알려 줬어요. (distractor: 송편 찌다, 수저 놓다, 앉으세요) |
| cloze_a1_0137 | particle_mismatch | ＿＿＿가 두 벌이라 어느 게 제 것인지 봤어요. (distractor: 백화점 상품권, 빈손) |
| cloze_a1_0138 | particle_mismatch | ＿＿＿이 열 가지나 나와서 놀랐어요. (distractor: 한가위) |
| cloze_a1_0142 | particle_mismatch | ＿＿＿이 식당보다 반찬이 많아요. (distractor: 벌초) |
| cloze_a1_0143 | particle_mismatch | ＿＿＿을 소리 안 나게 떠먹으려고 애썼어요. (distractor: 수저) |
| cloze_a1_0144 | particle_mismatch | ＿＿＿이 서툴러서 콩나물을 놓쳤어요. (distractor: 한가위) |
| cloze_a1_0147 | particle_mismatch | ＿＿＿를 도우려고 일어섰더니 앉으라고 하셨어요. (distractor: 현관, 호칭) |
| cloze_a1_0151 | particle_mismatch | ＿＿＿을 받으니 얼굴이 빨개졌어요. (distractor: 진지, 차례) |
| cloze_a1_0156 | particle_mismatch | ＿＿＿을 들었는데 뭐라고 답할지 몰랐어요. (distractor: 성묘) |
| cloze_a1_0158 | particle_mismatch | ＿＿＿를 두 손으로 받았어요. (distractor: 사진 전송, 설날) |
| cloze_a1_0162 | particle_mismatch | ＿＿＿가 만두처럼 커졌어요. (distractor: 작은 정성) |
| cloze_a1_0165 | particle_mismatch | ＿＿＿는 산에 올라가서 무덤가 풀을 깎는 일이에요. (distractor: 명절 증후군) |
| cloze_a1_0166 | particle_mismatch | ＿＿＿는 김이 올라서 부엌이 뿌예졌어요. (distractor: 수저 놓) |
| cloze_a1_0169 | particle_mismatch | ＿＿＿은 떼고 먹으라고 손짓하셨어요. (distractor: 손 씻기, 손님 슬리퍼) |
| cloze_a1_0170 | particle_mismatch | ＿＿＿은 차 안에서 이미 시작됐어요. (distractor: 답례) |
| cloze_a1_0171 | particle_mismatch | ＿＿＿를 지내기 전에는 웃음소리를 줄였어요. (distractor: 차례상, 처남) |
| cloze_a1_0172 | particle_mismatch | ＿＿＿이 엘리베이터에서 먼저 손을 흔들었어요. (distractor: 설거지) |
| cloze_a1_0173 | particle_mismatch | ＿＿＿가 독일어를 한 마디 해서 분위기가 풀렸어요. (distractor: 송편) |
| cloze_a1_0174 | josa_dup | 시누이가 옷걸이를 찾아 줬어요. |
| cloze_a1_0174 | particle_mismatch | ＿＿＿가 옷걸이를 찾아 줬어요. (distractor: 건강식품) |
| cloze_a1_0175 | particle_mismatch | ＿＿＿이 게임을 하자고 해서 현우가 말렸어요. (distractor: 형부) |
| cloze_a1_0176 | particle_mismatch | ＿＿＿가 맥주를 권해서 반만 받았어요. (distractor: 명절 증후군, 무릎) |
| cloze_a1_0177 | particle_mismatch | ＿＿＿가 주방에서 눈짓으로 물컵을 가리켰어요. (distractor: 국물, 귀성, 꽃다발) |
| cloze_a1_0178 | particle_mismatch | ＿＿＿가 사진을 찍어 주겠다고 뛰어왔어요. (distractor: 건강식품) |
| cloze_a1_0179 | josa_dup | 맏이가 자리 배치를 조용히 정했어요. |
| cloze_a1_0179 | particle_mismatch | ＿＿＿가 자리 배치를 조용히 정했어요. (distractor: 추석, 카톡) |
| cloze_a1_0184 | particle_mismatch | ＿＿＿은 올리지 말라고 현우가 먼저 말했어요. (distractor: 성묘) |
| cloze_a1_0188 | formality_mix | 상을 물릴 때 잘 먹었습니다 하고 크게 인사했어요. |
| cloze_a1_0193 | particle_mismatch | 다음 날 ＿＿＿를 짧게 물었어요. (distractor: 빈손, 사진 전송) |
| cloze_a1_0195 | particle_mismatch | ＿＿＿은 따뜻했다고만 적었어요. (distractor: 촬영 금지, 다음에 또 오세요) |
| cloze_a1_0196 | particle_mismatch | ＿＿＿를 세 장 주세요. (distractor: 우편함) |
| cloze_a1_0197 | particle_mismatch | 이 ＿＿＿를 독일로 보내고 싶어요. (distractor: 우편함) |
| cloze_a1_0208 | particle_mismatch | 이 ＿＿＿를 하루에 두 번 발라요. (distractor: 복용 시간) |
| cloze_a1_0209 | particle_mismatch | 약국에서 ＿＿＿를 한 통 샀어요. (distractor: 복용 시간) |
| cloze_a1_0211 | particle_mismatch | ＿＿＿을 종이에 적어 주세요. (distractor: 연고, 마스크, 계산대) |
| cloze_a1_0214 | particle_mismatch | 목이 아파서 ＿＿＿을 찾고 있어요. (distractor: 연고, 마스크, 계산대) |
| cloze_a1_0220 | particle_mismatch | 일요일에는 ＿＿＿을 자고 싶어요. (distractor: 약속 장소, 취소하다) |
| cloze_a1_0221 | particle_mismatch | ＿＿＿을 세 시로 바꿀까요? (distractor: 약속 장소, 취소하다) |
| cloze_a1_0222 | particle_mismatch | ＿＿＿는 역 앞이에요. (distractor: 늦잠, 약속 시간) |
| cloze_a1_0228 | particle_mismatch | ＿＿＿을 같이 세워 봐요. (distractor: 약속 장소) |
| cloze_a1_0232 | particle_mismatch | ＿＿＿을 두 번 눌렀어요. (distractor: 복도, 층수) |
| cloze_a1_0235 | particle_mismatch | 저희 ＿＿＿는 다섯 층이에요. (distractor: 초인종, 이웃집) |
| cloze_a1_0241 | particle_mismatch | 엘리베이터에 ＿＿＿이 있어요. (distractor: 복도) |
| cloze_a1_0242 | particle_mismatch | 입구 앞 ＿＿＿는 안 돼요. (distractor: 초인종, 이웃집) |
| cloze_a1_0243 | particle_mismatch | 아침에 ＿＿＿를 했어요. (distractor: 초인종, 이웃집) |
| cloze_a1_0250 | particle_mismatch | 내일 수업 ＿＿＿을 가방에 넣어요. (distractor: 지우개, 가위) |
| cloze_a1_0259 | particle_mismatch | 오늘 ＿＿＿는 열두 시예요. (distractor: 환승, 승강장) |
| cloze_a1_0262 | particle_mismatch | 한 달 ＿＿＿을 충전했어요. (distractor: 출구) |
| cloze_a1_0265 | particle_mismatch | ＿＿＿가 나오면 일어나요. (distractor: 환승, 승강장) |
| cloze_a1_0266 | particle_mismatch | ＿＿＿이 부족해서 충전이 필요해요. (distractor: 출구) |
| cloze_a1_0267 | particle_mismatch | ＿＿＿은 오른쪽이에요. (distractor: 출구) |
| cloze_a1_0268 | particle_mismatch | 바람이 불어서 ＿＿＿을 입어요. (distractor: 미세먼지, 일기예보, 우비) |
| cloze_a1_0269 | particle_mismatch | 오늘 ＿＿＿가 많아서 마스크를 써요. (distractor: 겉옷) |
| cloze_a1_0270 | particle_mismatch | ＿＿＿를 보고 옷을 골라요. (distractor: 겉옷) |
| cloze_a1_0271 | particle_mismatch | 소나기가 와서 ＿＿＿를 챙겼어요. (distractor: 겉옷) |
| cloze_a1_0272 | particle_mismatch | 낮에는 ＿＿＿이 편해요. (distractor: 미세먼지, 일기예보) |
| cloze_a1_0273 | particle_mismatch | 밤에는 ＿＿＿이 필요해요. (distractor: 미세먼지, 일기예보) |
| cloze_a1_0274 | particle_mismatch | 봄에는 ＿＿＿가 커서 겉옷이 필요해요. (distractor: 겉옷) |
| cloze_a1_0277 | particle_mismatch | 오후 예보가 ＿＿＿이에요. (distractor: 미세먼지, 일기예보) |
| cloze_a1_0278 | particle_mismatch | ＿＿＿가 금방 지나갈 거예요. (distractor: 겉옷) |
| cloze_a1_0301 | particle_mismatch | 제 ＿＿＿은 수진이에요. (distractor: 나이, 학교, 나라) |
| cloze_a1_0302 | particle_mismatch | 저는 한국어 ＿＿＿이에요. (distractor: 친구, 회사) |
| cloze_a1_0303 | particle_mismatch | 제 ＿＿＿은 독일이에요. (distractor: 모국어) |
| cloze_a1_0304 | particle_mismatch | 제 ＿＿＿는 독일어예요. (distractor: 국적, 이름, 직업) |
| cloze_a1_0305 | particle_mismatch | 제 ＿＿＿은 함부르크예요. (distractor: 나이, 학교) |
| cloze_a1_0320 | particle_mismatch | 짧은 ＿＿＿을 하나 보여 주세요. (distractor: 주소) |
| cloze_a1_0321 | particle_mismatch | 이 ＿＿＿이 맞아요? (distractor: 번호) |
| cloze_a1_0327 | particle_mismatch | ＿＿＿을 주세요. (distractor: 메뉴, 주소) |
| cloze_a1_0328 | particle_mismatch | ＿＿＿는 얼마예요? (distractor: 도착 시간) |
| cloze_a1_0329 | particle_mismatch | 주문 전에 ＿＿＿를 확인해요. (distractor: 가격) |
| cloze_a1_0332 | particle_mismatch | ＿＿＿를 다시 말해 주세요. (distractor: 도착 시간, 카드 이름) |
| cloze_a1_0333 | particle_mismatch | 이 ＿＿＿을 사용할 수 있어요? (distractor: 주소, 봉투) |
| cloze_a1_0344 | particle_mismatch | 시험 전에 친구가 ＿＿＿이라고 말해요. (distractor: 안녕히, 죄송해, 어서 와) |
| cloze_a1_0345 | particle_mismatch | ＿＿＿는 역 앞이에요. (distractor: 약국, 정류장, 지하철역) |
| cloze_a1_0347 | particle_mismatch | 버스 ＿＿＿은 어디예요? (distractor: 환승 안내) |
| cloze_a1_0349 | particle_mismatch | 앱에서 ＿＿＿를 확인해요. (distractor: 교통카드 잔액, 약국) |
| cloze_a1_0350 | particle_mismatch | ＿＿＿은 만 원이에요. (distractor: 우체국 위치) |
| cloze_a2_0002 | particle_mismatch | ＿＿＿이 뭐예요? (distractor: 열쇠, 모기, 교차로) |
| cloze_a2_0003 | particle_mismatch | ＿＿＿가 뭐예요? (distractor: 시장, 군인) |
| cloze_a2_0004 | particle_mismatch | ＿＿＿가 어때요? (distractor: 소금, 컵, 양복) |
| cloze_a2_0005 | particle_mismatch | 어떤 ＿＿＿을 좋아해요? (distractor: 상사, 메뉴) |
| cloze_a2_0006 | particle_mismatch | ＿＿＿은 더워요. (distractor: 아주머니, 자전거) |
| cloze_a2_0008 | particle_mismatch | ＿＿＿은 추워요. (distractor: 쇠고기, 야채) |
| cloze_a2_0013 | particle_mismatch | ＿＿＿을 가요. (distractor: 가수) |
| cloze_a2_0017 | particle_mismatch | ＿＿＿를 봐요. (distractor: 칫솔) |
| cloze_a2_0018 | particle_mismatch | 내일 ＿＿＿이 있어요. (distractor: 월세) |
| cloze_a2_0019 | particle_mismatch | ＿＿＿를 해요. (distractor: 주인, 겨울) |
| cloze_a2_0020 | particle_mismatch | ＿＿＿이 좋아요. (distractor: 배) |
| cloze_a2_0021 | particle_mismatch | ＿＿＿를 즐겨요. (distractor: 가을) |
| cloze_a2_0022 | particle_mismatch | ＿＿＿가 있어요. (distractor: 유학, 우산, 장갑) |
| cloze_a2_0023 | particle_mismatch | ＿＿＿를 타요. (distractor: 왕, 잼) |
| cloze_a2_0025 | particle_mismatch | ＿＿＿를 타요. (distractor: 색깔, 창문) |
| cloze_a2_0026 | particle_mismatch | ＿＿＿가 왔어요. (distractor: 갈색, 대학생) |
| cloze_a2_0027 | particle_mismatch | ＿＿＿를 보냈어요? (distractor: 바람, 월급) |
| cloze_a2_0030 | particle_mismatch | ＿＿＿이 없어요. (distractor: 지구, 대학교) |
| cloze_a2_0031 | particle_mismatch | ＿＿＿를 잃었어요. (distractor: 배달, 유학생, 눈사람) |
| cloze_a2_0032 | particle_mismatch | ＿＿＿이 있어요? (distractor: 원피스, 코트, 물고기) |
| cloze_a2_0034 | particle_mismatch | ＿＿＿이 있어요? (distractor: 변호사, 컴퓨터) |
| cloze_a2_0049 | particle_mismatch | ＿＿＿이 친절했어요. (distractor: 전화, 불고기) |
| cloze_a2_0055 | particle_mismatch | ＿＿＿이 올랐어요. (distractor: 사이즈, 딸기) |
| cloze_a2_0056 | particle_mismatch | 내일 ＿＿＿이 있어요. (distractor: 세탁기, 귀걸이, 목도리) |
| cloze_a2_0057 | particle_mismatch | ＿＿＿이 예뻐요. (distractor: 차림표) |
| cloze_a2_0061 | particle_mismatch | ＿＿＿이 잘 어울려요. (distractor: 넥타이, 계산서, 반지) |
| cloze_a2_0062 | particle_mismatch | ＿＿＿이 넓어요. (distractor: 열쇠, 청소기) |
| cloze_a2_0065 | particle_mismatch | ＿＿＿를 돌려요. (distractor: 할인, 창문) |
| cloze_a2_0067 | particle_mismatch | 새 ＿＿＿를 샀어요. (distractor: 음악, 성적) |
| cloze_a2_0068 | particle_mismatch | ＿＿＿가 비싸요. (distractor: 스타킹, 시험) |
| cloze_a2_0069 | particle_mismatch | ＿＿＿을 냈어요. (distractor: 전화, 교수) |
| cloze_a2_0072 | particle_mismatch | ＿＿＿을 만들었어요. (distractor: 야채, 회의) |
| cloze_a2_0073 | particle_mismatch | ＿＿＿이 부족해요. (distractor: 문자, 치마) |
| cloze_a2_0074 | particle_mismatch | ＿＿＿가 있어요? (distractor: 호텔, 반) |
| cloze_a2_0081 | particle_mismatch | ＿＿＿이 아니라 동아리에서 만났다고 했어요. (distractor: 세면 도구) |
| cloze_a2_0082 | dangling_stem | 유창하지 않아도 천천히 말하면 통해요. (answer="유창하") |
| cloze_a2_0083 | particle_mismatch | 어려운 말은 현우에게 ＿＿＿을 했어요. (distractor: 안부 전화) |
| cloze_a2_0084 | particle_mismatch | ＿＿＿를 세 문장으로 준비해 갔어요. (distractor: 반말 연습, 반말 전환) |
| cloze_a2_0086 | particle_mismatch | ＿＿＿을 묻길래 매운 건 조금 먹는다고 했어요. (distractor: 새해 목표) |
| cloze_a2_0087 | particle_mismatch | ＿＿＿이 안 되면 현우 얼굴을 봐요. (distractor: 국물 새다, 떡국 먹다) |
| cloze_a2_0090 | particle_mismatch | 어른인데 ＿＿＿을 두 번 하고 받았어요. (distractor: 편하게 말해요, 한국어 잘하시네요, 가방이 무겁다) |
| cloze_a2_0092 | particle_mismatch | ＿＿＿는 나이 많은 분부터예요. (distractor: 김치 국물, 나이 확인, 남은 반찬) |
| cloze_a2_0094 | particle_mismatch | ＿＿＿을 종이에 적어 주머니에 넣었어요. (distractor: 문 닫기, 밀폐 용기) |
| cloze_a2_0095 | particle_mismatch | ＿＿＿은 가족 앨범에만 두래요. (distractor: 반찬 봉투) |
| cloze_a2_0096 | particle_mismatch | ＿＿＿은 전 냄새가 먼저 나요. (distractor: 비닐봉지, 새해 목표) |
| cloze_a2_0098 | particle_mismatch | ＿＿＿을 거울 앞에서 열 번 했어요. (distractor: 반찬 봉투) |
| cloze_a2_0099 | particle_mismatch | ＿＿＿를 묻길래 한국어 일기라고 했어요. (distractor: 양손, 음식 취향, 이불) |
| cloze_a2_0101 | particle_mismatch | ＿＿＿이 콩이면 제가 이기고 깨면 현우가 이겨요. (distractor: 자기소개) |
| cloze_a2_0102 | particle_mismatch | ＿＿＿을 보며 소원을 말하래요. (distractor: 송편 만들기) |
| cloze_a2_0103 | particle_mismatch | ＿＿＿은 흰색보다 어두운 색이 편해요. (distractor: 코골이) |
| cloze_a2_0104 | particle_mismatch | ＿＿＿을 끼고 사진만 찍었어요. (distractor: 자기소개) |
| cloze_a2_0105 | particle_mismatch | ＿＿＿은 먹기 전에 먼저 올렸어요. (distractor: 한복 대여) |
| cloze_a2_0106 | particle_mismatch | ＿＿＿를 하면 손끝이 분홍해져요. (distractor: 돌아가는 길) |
| cloze_a2_0107 | particle_mismatch | 카톡 ＿＿＿는 짧게, 하지만 존댓말로 보냈어요. (distractor: 집 마당, 차례 음식) |
| cloze_a2_0109 | particle_mismatch | ＿＿＿이 다섯 집이라 미소를 아껴 썼어요. (distractor: 보자기, 복주머니) |
| cloze_a2_0114 | particle_mismatch | ＿＿＿이 생기기 전에 제가 먼저 하나를 정했어요. (distractor: 아침 인사) |
| cloze_a2_0118 | particle_mismatch | ＿＿＿을 현우가 못 보면 그냥 웃어요. (distractor: 국물 새다, 떡국 먹다) |
| cloze_a2_0120 | particle_mismatch | ＿＿＿을 들면 현우가 눈을 흘겨요. (distractor: 반말 실수) |
| cloze_a2_0125 | particle_mismatch | ＿＿＿을 개다가 현우 엄마가 들어오셨어요. (distractor: 새해 목표) |
| cloze_a2_0126 | particle_mismatch | ＿＿＿를 깜빡해서 새 칫솔을 받았어요. (distractor: 좌석 배정, 집 마당) |
| cloze_a2_0127 | particle_mismatch | ＿＿＿는 일어나자마자 큰 소리로 했어요. (distractor: 세배 영상, 소개팅, 손님 수건) |
| cloze_a2_0129 | particle_mismatch | ＿＿＿이 생겨서 물부터 마셨어요. (distractor: 반찬 봉투) |
| cloze_a2_0132 | particle_mismatch | ＿＿＿이 저녁만큼 많아서 천천히 먹었어요. (distractor: 복주머니, 비닐봉지, 새해 목표) |
| cloze_a2_0133 | particle_mismatch | ＿＿＿이 분홍색이라 현우 거라고 착각했어요. (distractor: 말실수, 맞장구, 명절 기차) |
| cloze_a2_0137 | particle_mismatch | ＿＿＿가 세 개라 버스에서 조심했어요. (distractor: 송편 맛, 송편 점) |
| cloze_a2_0138 | particle_mismatch | ＿＿＿이 샐까 봐 봉지를 두 겹으로 했어요. (distractor: 코골이, 한복 대여) |
| cloze_a2_0141 | particle_mismatch | ＿＿＿가 얇아서 밑에 책을 받쳤어요. (distractor: 성묘 옷) |
| cloze_a2_0143 | particle_mismatch | ＿＿＿이라고 쓴 메모를 뚜껑에 붙였어요. (distractor: 존댓말 실수) |
| cloze_a2_0147 | particle_mismatch | ＿＿＿가 두 개라서 현우와 나눠 들었어요. (distractor: 집 마당, 차례 음식) |
| cloze_a2_0150 | particle_mismatch | ＿＿＿는 서서 가는 칸이 더 떠들썩했어요. (distractor: 밤참, 벌초 장갑) |
| cloze_a2_0151 | particle_mismatch | ＿＿＿이 떨어져서 현우와 쪽지로 이야기했어요. (distractor: 코골이) |
| cloze_a2_0153 | particle_mismatch | ＿＿＿는 현관이 아니라 주차장에서 시작됐어요. (distractor: 남은 반찬, 냉동 보관, 냉동실) |
| cloze_a2_0155 | particle_mismatch | ＿＿＿가 한 대라 시간을 두 번 확인했어요. (distractor: 냉동실, 단톡방) |
| cloze_a2_0159 | particle_mismatch | 서울 도착하자마자 ＿＿＿를 드렸어요. (distractor: 냉동 보관, 냉동실, 단톡방) |
| cloze_a2_0160 | particle_mismatch | ＿＿＿은 동생이 먼저 하자고 했어요. (distractor: 세면 도구, 세배 순서) |
| cloze_a2_0161 | particle_mismatch | 부모님 앞에서는 ＿＿＿를 약속했어요. (distractor: 동생 편) |
| cloze_a2_0163 | particle_mismatch | ＿＿＿을 차에 타기 전에 세 번 했어요. (distractor: 마을 버스, 말실수, 맞장구) |
| cloze_a2_0166 | particle_mismatch | ＿＿＿이 남아서 게임에서도 요를 붙였어요. (distractor: 송편 만들기) |
| cloze_a2_0169 | particle_mismatch | ＿＿＿는 현우가 눈짓으로 도와줬어요. (distractor: 비밀 보장, 세뱃돈 사양) |
| cloze_a2_0170 | particle_mismatch | ＿＿＿를 사과하니 아버지가 괜찮다고 하셨어요. (distractor: 친척 방문, 친척 집) |
| cloze_a2_0171 | particle_mismatch | ＿＿＿은 주차장에서만 하기로 했어요. (distractor: 안부 전화) |
| cloze_a2_0172 | particle_mismatch | 이 ＿＿＿가 데이터량이 더 많아요. (distractor: 데이터량, 무제한, 약정) |
| cloze_a2_0173 | particle_mismatch | 이번 달 ＿＿＿이 벌써 끝났어요. (distractor: 요금제) |
| cloze_a2_0174 | particle_mismatch | 주말에는 데이터가 ＿＿＿이에요. (distractor: 요금제) |
| cloze_a2_0175 | particle_mismatch | ＿＿＿이 올해 십이월에 끝나요. (distractor: 요금제) |
| cloze_a2_0176 | particle_mismatch | 지금 바꾸면 ＿＿＿이 나와요. (distractor: 요금제) |
| cloze_a2_0177 | particle_mismatch | 독일 가기 전에 ＿＿＿을 신청해요. (distractor: 요금제) |
| cloze_a2_0178 | particle_mismatch | 필요 없는 ＿＿＿를 껐어요. (distractor: 데이터량, 무제한) |
| cloze_a2_0179 | particle_mismatch | 이번 달 ＿＿＿가 평소보다 높아요. (distractor: 데이터량, 무제한) |
| cloze_a2_0183 | particle_mismatch | 부족하면 ＿＿＿을 추가로 사요. (distractor: 요금제) |
| cloze_a2_0189 | particle_mismatch | ＿＿＿이 서류를 천천히 설명해요. (distractor: 이체하다, 인증서, 보안카드) |
| cloze_a2_0191 | particle_mismatch | 계좌를 만들 때 ＿＿＿이 필요해요. (distractor: 이체하다, 인증서, 보안카드) |
| cloze_a2_0192 | particle_mismatch | ＿＿＿을 위해 신분증을 보여 줬어요. (distractor: 이체하다, 인증서, 보안카드) |
| cloze_a2_0193 | particle_mismatch | ＿＿＿이 네 시라서 서둘렀어요. (distractor: 이체하다, 인증서, 보안카드) |
| cloze_a2_0200 | particle_mismatch | 이 동작은 ＿＿＿를 열 번으로 해요. (distractor: 헬스장, 운동복, 러닝머신) |
| cloze_a2_0202 | particle_mismatch | ＿＿＿가 자세를 고쳐 줘요. (distractor: 헬스장, 운동복, 러닝머신) |
| cloze_a2_0209 | particle_mismatch | 이번엔 ＿＿＿를 조금만 해 주세요. (distractor: 미용실, 염색, 펌) |
| cloze_a2_0210 | particle_mismatch | ＿＿＿은 너무 어둡지 않게 해 주세요. (distractor: 커트) |
| cloze_a2_0212 | particle_mismatch | ＿＿＿를 눈에 안 들어오게 잘라 주세요. (distractor: 미용실, 염색) |
| cloze_a2_0214 | particle_mismatch | ＿＿＿가 거울로 뒷모습을 보여 줘요. (distractor: 미용실, 염색) |
| cloze_a2_0215 | particle_mismatch | 주말 예약은 ＿＿＿이 있어요. (distractor: 커트) |
| cloze_a2_0217 | particle_mismatch | 끝이 갈라져서 ＿＿＿를 추가했어요. (distractor: 미용실, 염색) |
| cloze_a2_0218 | particle_mismatch | ＿＿＿를 귀에 안 붙게 해 주세요. (distractor: 미용실, 염색) |
| cloze_a2_0222 | particle_mismatch | ＿＿＿를 앞 유리에 붙여요. (distractor: 입주민) |
| cloze_a2_0223 | particle_mismatch | ＿＿＿는 지정된 통에만 넣어요. (distractor: 입주민) |
| cloze_a2_0224 | particle_mismatch | 열 시 이후에는 ＿＿＿을 피해요. (distractor: 관리사무소, 주차스티커) |
| cloze_a2_0225 | particle_mismatch | ＿＿＿이 세게 닫히지 않게 잡아요. (distractor: 관리사무소, 주차스티커) |
| cloze_a2_0226 | particle_mismatch | 손님은 ＿＿＿을 받아 입장해요. (distractor: 관리사무소, 주차스티커) |
| cloze_a2_0229 | particle_mismatch | 밤에 경비 ＿＿＿이 두 번 돌아요. (distractor: 관리사무소, 주차스티커) |
| cloze_a2_0230 | particle_mismatch | 흡연 ＿＿＿이 반복되면 경고가 와요. (distractor: 관리사무소, 주차스티커) |
| cloze_a2_0232 | particle_mismatch | 이번 달부터 ＿＿＿이 올랐어요. (distractor: 근무표) |
| cloze_a2_0233 | particle_mismatch | 다음 주 ＿＿＿가 오늘 올라와요. (distractor: 시급, 야간수당, 휴게시간) |
| cloze_a2_0234 | particle_mismatch | 열 시 이후에는 ＿＿＿이 붙어요. (distractor: 근무표) |
| cloze_a2_0235 | particle_mismatch | 네 시간마다 ＿＿＿이 십오 분이에요. (distractor: 근무표) |
| cloze_a2_0236 | particle_mismatch | 마감 전에 ＿＿＿를 짧게 해요. (distractor: 시급, 야간수당) |
| cloze_a2_0238 | particle_mismatch | 일주일에 십오 시간을 일하면 ＿＿＿이 나와요. (distractor: 근무표) |
| cloze_a2_0239 | particle_mismatch | 첫날에 ＿＿＿을 읽고 서명해요. (distractor: 근무표) |
| cloze_a2_0240 | particle_mismatch | 여섯 시에 ＿＿＿가 있어서 조금 일찍 와요. (distractor: 시급, 야간수당) |
| cloze_a2_0243 | particle_mismatch | ＿＿＿를 문자로 받았어요. (distractor: 시급, 야간수당) |
| cloze_a2_0244 | particle_mismatch | 지하철 ＿＿＿을 역 사무실에 문의했어요. (distractor: 습득하다) |
| cloze_a2_0247 | particle_mismatch | 찾을 때 ＿＿＿을 보여 주세요. (distractor: 습득하다) |
| cloze_a2_0254 | particle_mismatch | ＿＿＿이 지나면 물건을 옮긴대요. (distractor: 습득하다) |
| cloze_a2_0255 | particle_mismatch | 찾을 때 ＿＿＿를 받아서 서명해요. (distractor: 분실물, 보관함) |
| cloze_a2_0260 | particle_mismatch | ＿＿＿이 스탬프 위치를 알려 줘요. (distractor: 축제, 부스, 체험하다) |
| cloze_a2_0261 | particle_mismatch | ＿＿＿은 한 사람당 한 개예요. (distractor: 축제, 부스, 체험하다) |
| cloze_a2_0262 | particle_mismatch | ＿＿＿을 가방에 넣지 말고 다시 봐요. (distractor: 축제, 부스, 체험하다) |
| cloze_a2_0264 | particle_mismatch | 부스 ＿＿＿은 여섯 시까지예요. (distractor: 축제, 부스, 체험하다) |
| cloze_a2_0267 | particle_mismatch | ＿＿＿을 보여 주면 재료를 받아요. (distractor: 축제, 부스, 체험하다) |
| cloze_a2_0277 | particle_mismatch | 이번 주가 어려우면 ＿＿＿는 어때요? (distractor: 매일) |
| cloze_a2_0281 | particle_mismatch | 서명한 뒤에 ＿＿＿을 받아요. (distractor: 부동산 중개) |
| cloze_a2_0283 | particle_mismatch | ＿＿＿를 통해 방 세 개를 봤어요. (distractor: 선납금, 납부일, 관리비 내역) |
| cloze_b1_0001 | particle_mismatch | 새로운 ＿＿＿을 해요. (distractor: 의미, 변화) |
| cloze_b1_0002 | particle_mismatch | 한국 ＿＿＿를 배워요. (distractor: 입장권, 조건, 의견) |
| cloze_b1_0003 | particle_mismatch | 요즘 ＿＿＿가 많이 달라졌어요. (distractor: 결혼식, 기쁨) |
| cloze_b1_0004 | particle_mismatch | ＿＿＿을 보호해야 해요. (distractor: 목표, 문화) |
| cloze_b1_0005 | particle_mismatch | 좋은 ＿＿＿를 유지해요. (distractor: 공과금, 관광) |
| cloze_b1_0006 | particle_mismatch | ＿＿＿를 세워요. (distractor: 균형, 취향, 상황) |
| cloze_b1_0007 | particle_mismatch | 좋은 ＿＿＿이 있어요? (distractor: 진통제, 연휴, 결과) |
| cloze_b1_0008 | particle_mismatch | ＿＿＿가 있어요? (distractor: 과정) |
| cloze_b1_0010 | particle_mismatch | ＿＿＿가 어려워요. (distractor: 대중교통, 거스름돈) |
| cloze_b1_0014 | particle_mismatch | ＿＿＿를 받아요. (distractor: 책방, 처방전) |
| cloze_b1_0015 | particle_mismatch | 나쁜 ＿＿＿을 바꿔요. (distractor: 경제) |
| cloze_b1_0017 | particle_mismatch | 학습 ＿＿＿이 중요해요. (distractor: 광고, 주사) |
| cloze_b1_0020 | particle_mismatch | ＿＿＿가 좋아요. (distractor: 공연, 고민) |
| cloze_b1_0021 | particle_mismatch | 제 ＿＿＿은 달라요. (distractor: 신용카드) |
| cloze_b1_0022 | particle_mismatch | ＿＿＿을 말해 주세요. (distractor: 대화) |
| cloze_b1_0023 | particle_mismatch | ＿＿＿가 뭐예요? (distractor: 면세점, 책임) |
| cloze_b1_0024 | particle_mismatch | ＿＿＿이 맞아요. (distractor: 지폐) |
| cloze_b1_0025 | particle_mismatch | ＿＿＿를 찾아요. (distractor: 신입사원, 공연장) |
| cloze_b1_0035 | particle_mismatch | ＿＿＿을 달았어요. (distractor: 문제, 생활비) |
| cloze_b1_0036 | particle_mismatch | ＿＿＿를 눌렀어요. (distractor: 습관) |
| cloze_b1_0037 | particle_mismatch | ＿＿＿가 늘었어요. (distractor: 환율, 우회전) |
| cloze_b1_0038 | particle_mismatch | ＿＿＿을 올렸어요. (distractor: 팔로워, 식비) |
| cloze_b1_0039 | particle_mismatch | ＿＿＿이 다음 주예요. (distractor: 무대) |
| cloze_b1_0041 | particle_mismatch | ＿＿＿을 작성해요. (distractor: 다이어트, 비상구) |
| cloze_b1_0043 | particle_mismatch | ＿＿＿을 관리해요. (distractor: 어휘) |
| cloze_b1_0044 | particle_mismatch | 일과 삶의 ＿＿＿이 중요해요. (distractor: 상가) |
| cloze_b1_0045 | particle_mismatch | 잠깐 ＿＿＿을 취해요. (distractor: 경찰서) |
| cloze_b1_0046 | particle_mismatch | 사람마다 ＿＿＿이 달라요. (distractor: 열차) |
| cloze_b1_0047 | particle_mismatch | 이 단어의 ＿＿＿가 뭐예요? (distractor: 식단, 휴식) |
| cloze_b1_0048 | particle_mismatch | 큰 ＿＿＿가 있었어요. (distractor: 생각) |
| cloze_b1_0050 | josa_dup | 두 나라의 차이가 커요. |
| cloze_b1_0050 | particle_mismatch | 두 나라의 ＿＿＿가 커요. (distractor: 교육, 뜻) |
| cloze_b1_0051 | particle_mismatch | ＿＿＿이 많아요. (distractor: 정치, 송별회) |
| cloze_b1_0052 | particle_mismatch | ＿＿＿이 있어요. (distractor: 좋아요) |
| cloze_b1_0053 | particle_mismatch | 자신의 ＿＿＿를 알아요. (distractor: 벌금) |
| cloze_b1_0055 | particle_mismatch | ＿＿＿이 강해요. (distractor: 열차) |
| cloze_b1_0058 | particle_mismatch | ＿＿＿가 바뀌면 관리인에게 알려야 해요. (distractor: 중개인, 부동산) |
| cloze_b1_0062 | particle_mismatch | 누수 때문에 ＿＿＿가 예상보다 많이 들었어요. (distractor: 이삿짐) |
| cloze_b1_0063 | particle_mismatch | 천장에서 ＿＿＿가 생겨서 바로 부동산에 연락했어요. (distractor: 난방) |
| cloze_b1_0064 | particle_mismatch | ＿＿＿이 잘 안 돼서 관리실에 문의했어요. (distractor: 누수, 관리비) |
| cloze_b1_0067 | particle_mismatch | ＿＿＿은 오전에 먼저 새 집으로 보냈어요. (distractor: 계약서, 관리비, 수리비) |
| cloze_b1_0069 | particle_mismatch | 회의 ＿＿＿를 오늘 안에 알려 주세요. (distractor: 업무 분담, 마감일) |
| cloze_b1_0070 | particle_mismatch | 마감일이 가까운 업무의 ＿＿＿를 먼저 정했어요. (distractor: 업무 분담, 회의실) |
| cloze_b1_0071 | particle_mismatch | 오후 회의를 위해 3층 ＿＿＿을 예약했어요. (distractor: 참석 여부) |
| cloze_b1_0074 | particle_mismatch | 회의 전에 ＿＿＿을 정해서 각자 맡을 일을 확인했어요. (distractor: 참석 여부, 우선순위) |
| cloze_b1_0075 | particle_mismatch | 이 보고서의 ＿＿＿은 다음 주 금요일이에요. (distractor: 참석 여부, 우선순위) |
| cloze_b1_0080 | particle_mismatch | 가능하면 오늘 안에 방문 시간과 예상 ＿＿＿를 알려 주시면 좋겠어요. (distractor: 거스름돈) |
| cloze_b1_0084 | particle_mismatch | ＿＿＿을 묻길래 아직 천천히 알아가는 중이라고 했어요. (distractor: 원격 근무, 월급 이야기, 이성 친구) |
| cloze_b1_0086 | particle_mismatch | ＿＿＿는 웃으면서 아직 배우는 중이라고 넘겼어요. (distractor: 취중진담, 칭찬 기억) |
| cloze_b1_0089 | particle_mismatch | ＿＿＿는 서류부터 차근차근 하면 된다고 했어요. (distractor: 한국어 능력, 가족 단톡) |
| cloze_b1_0092 | particle_mismatch | ＿＿＿는 날씨보다 음식 칭찬이 안전했어요. (distractor: 야근, 양쪽 집) |
| cloze_b1_0094 | particle_mismatch | ＿＿＿을 정하니 현우도 한결 편해졌어요. (distractor: 선물 감사, 선물 분배, 술잔 돌리기) |
| cloze_b1_0097 | particle_mismatch | ＿＿＿이라고 하니 안정적이냐는 질문이 바로 나왔어요. (distractor: 오해 풀기, 원격 근무, 월급 이야기) |
| cloze_b1_0099 | particle_mismatch | ＿＿＿은 아직 없다고 짧게 했어요. (distractor: 아침 이부자리) |
| cloze_b1_0100 | particle_mismatch | ＿＿＿을 묻길래 내년까지 연장할 계획이라고 했어요. (distractor: 일정표 공유) |
| cloze_b1_0101 | particle_mismatch | ＿＿＿을 시험받는 기분은 회사보다 가족 식탁에서 더 컸어요. (distractor: 선물 감사, 선물 분배) |
| cloze_b1_0104 | particle_mismatch | ＿＿＿는 하지 않고 범위만 말했어요. (distractor: 새벽 화장실) |
| cloze_b1_0105 | particle_mismatch | ＿＿＿를 묻길래 동료가 친절하다고 했어요. (distractor: 결혼 계획, 계약직) |
| cloze_b1_0109 | dangling_stem | 긴 이야기는 요약해서 전하니 핵심만 남았어요. (answer="요약해서 전하") |
| cloze_b1_0111 | particle_mismatch | ＿＿＿가 사라질까 봐 현우가 손짓으로 멈췄어요. (distractor: 공지 확인, 교통 대란) |
| cloze_b1_0116 | particle_mismatch | ＿＿＿을 바로잡으니 아버지가 오히려 고마워하셨어요. (distractor: 감사 메시지, 감정 정리) |
| cloze_b1_0118 | dangling_stem | 대충 하지 말라고 현우가 귓속말로 했어요. (answer="대충 하") |
| cloze_b1_0119 | dangling_stem | 쉬운 질문은 직접 대답하니 표정이 밝아졌어요. (answer="직접 대답하") |
| cloze_b1_0120 | particle_mismatch | ＿＿＿을 때 두 손으로 하니 삼촌이 고개를 끄덕이셨어요. (distractor: 대충 하, 먼저 따르) |
| cloze_b1_0121 | particle_mismatch | ＿＿＿를 때 병목을 가리니 현우가 잘했다고 했어요. (distractor: 다시 확인) |
| cloze_b1_0123 | particle_mismatch | ＿＿＿은 안 한다고 하니 아버지가 물을 밀어 주셨어요. (distractor: 국적 문제, 뉘앙스) |
| cloze_b1_0124 | particle_mismatch | ＿＿＿을 부르니 안심하라는 말이 나왔어요. (distractor: 감사 메시지, 감정 정리) |
| cloze_b1_0125 | particle_mismatch | ＿＿＿는 위생 때문에 웃으며 거절했어요. (distractor: 명절 예산, 방 배정) |
| cloze_b1_0126 | dangling_stem | 취하기 전에 자리에서 일어나 물을 마셨어요. (answer="취하") |
| cloze_b1_0129 | particle_mismatch | ＿＿＿이 나오기 전에 현우가 화제를 바꿨어요. (distractor: 불 끄기, 사진 올리기, 새벽 메시지) |
| cloze_b1_0131 | dangling_stem | 취하신 분 옆에서는 자리 피하는 게 안전했어요. (answer="자리 피하") |
| cloze_b1_0132 | particle_mismatch | ＿＿＿이 따로라서 안도하면서도 서운했어요. (distractor: 감정 정리, 건배) |
| cloze_b1_0137 | particle_mismatch | ＿＿＿는 현우가 대신 했어요. (distractor: 잠자리 예절, 존댓말 채팅) |
| cloze_b1_0139 | particle_mismatch | ＿＿＿는 어른이 먼저 하라고 눈짓하셨어요. (distractor: 이직 생각, 일정 충돌) |
| cloze_b1_0140 | particle_mismatch | ＿＿＿를 치우니 공간이 바로 거실이 됐어요. (distractor: 폭음, 한국어 능력) |
| cloze_b1_0144 | particle_mismatch | 차 안에서 ＿＿＿를 솔직하게 나눴어요. (distractor: 야근, 양쪽 집) |
| cloze_b1_0145 | particle_mismatch | ＿＿＿을 적으니 생각보다 짧아서 안도했어요. (distractor: 연봉 공개, 연휴 근무, 영상 인사) |
| cloze_b1_0146 | particle_mismatch | ＿＿＿는 현우 엄마께 먼저 보냈어요. (distractor: 실수 목록) |
| cloze_b1_0147 | particle_mismatch | 호칭 ＿＿＿는 다음 날 전화로 했어요. (distractor: 다음 방문, 단체 호출, 단톡 입장) |
| cloze_b1_0148 | particle_mismatch | ＿＿＿은 더 짧게 하자고 현우가 먼저 말했어요. (distractor: 아침 이부자리) |
| cloze_b1_0149 | particle_mismatch | ＿＿＿를 하니 긴장보다 따뜻함이 남았어요. (distractor: 야근, 양쪽 집) |
| cloze_b1_0151 | particle_mismatch | ＿＿＿을 현우가 해 주니 덜 아팠어요. (distractor: 올해는 못 가요, 요약해서 전하다, 웃고 넘기다) |
| cloze_b1_0152 | particle_mismatch | ＿＿＿을 적어 두니 다음 방문이 덜 무서웠어요. (distractor: 직장 분위기, 취업 비자) |
| cloze_b1_0153 | dangling_stem | 잠자리 경계 다시 정하니 둘이 편해졌어요. (answer="경계 다시 정하") |
| cloze_b1_0154 | particle_mismatch | ＿＿＿를 빠뜨릴 뻔해서 급히 보냈어요. (distractor: 취중진담, 칭찬 기억) |
| cloze_b1_0157 | particle_mismatch | ＿＿＿이 길어질까 봐 짧게라도 답했어요. (distractor: 코골이 사과, 퇴사) |
| cloze_b1_0158 | particle_mismatch | ＿＿＿을 안 해서 모임 시간을 헷갈렸어요. (distractor: 오해 풀기, 원격 근무, 월급 이야기) |
| cloze_b1_0160 | particle_mismatch | ＿＿＿가 켜져 있어서 바로 답해야 했어요. (distractor: 체류 기간) |
| cloze_b1_0161 | particle_mismatch | ＿＿＿은 급한 공지만 쓰라고 현우가 말렸어요. (distractor: 연봉 공개, 연휴 근무, 영상 인사) |
| cloze_b1_0163 | particle_mismatch | ＿＿＿을 유지하니 이모가 좋아하셨어요. (distractor: 연봉 공개, 연휴 근무, 영상 인사) |
| cloze_b1_0164 | particle_mismatch | ＿＿＿는 보내지 않기로 스스로 정했어요. (distractor: 부모 허락) |
| cloze_b1_0168 | particle_mismatch | ＿＿＿을 하루씩 나누는 표가 필요했어요. (distractor: 불 끄기, 사진 올리기) |
| cloze_b1_0170 | particle_mismatch | ＿＿＿가 끼어서 기차표를 다시 샀어요. (distractor: 실수 목록, 야근) |
| cloze_b1_0171 | particle_mismatch | ＿＿＿는 나이 많은 집부터라고 적혀 있었어요. (distractor: 다음 방문) |
| cloze_b1_0172 | particle_mismatch | ＿＿＿이 생겨서 현우가 어머니께 먼저 전화드렸어요. (distractor: 방문 순서) |
| cloze_b1_0176 | particle_mismatch | ＿＿＿을 넘기지 않으려고 과일만 골랐어요. (distractor: 일정표 공유) |
| cloze_b1_0177 | particle_mismatch | ＿＿＿을 피해 새벽 차를 탔어요. (distractor: 직장 분위기, 취업 비자) |
| cloze_b1_0178 | particle_mismatch | ＿＿＿를 하니 양쪽 잔소리가 줄었어요. (distractor: 종교 질문, 체류 기간) |
| cloze_b1_0182 | particle_mismatch | ＿＿＿을 금요일 낮으로 적었어요. (distractor: 참조, 숨은참조) |
| cloze_b1_0183 | particle_mismatch | ＿＿＿이 있어서 바로 다시 보냈어요. (distractor: 참조, 숨은참조) |
| cloze_b1_0186 | particle_mismatch | 급한 요청에만 ＿＿＿을 켜요. (distractor: 참조, 숨은참조) |
| cloze_b1_0188 | particle_mismatch | 답장이 없어서 ＿＿＿을 짧게 보냈어요. (distractor: 참조, 숨은참조) |
| cloze_b1_0191 | particle_mismatch | ＿＿＿이 떠서 다시 보내지 않았어요. (distractor: 참조, 숨은참조) |
| cloze_b1_0198 | particle_mismatch | ＿＿＿를 표로 붙여 두었어요. (distractor: 공용 선반, 청소 당번, 공과금 정산) |
| cloze_b1_0199 | particle_mismatch | ＿＿＿가 떨어지면 같이 사요. (distractor: 공용 선반, 청소 당번, 공과금 정산) |
| cloze_b1_0204 | particle_mismatch | ＿＿＿를 당일 오후에 했어요. (distractor: 자기부담금) |
| cloze_b1_0205 | particle_mismatch | ＿＿＿를 약관 삼 쪽에서 확인해요. (distractor: 자기부담금) |
| cloze_b1_0206 | particle_mismatch | ＿＿＿이 오만 원이라 수리를 다시 계산해요. (distractor: 사고 접수, 보장 범위, 진단서) |
| cloze_b1_0207 | particle_mismatch | 병원 ＿＿＿를 스캔해서 올렸어요. (distractor: 자기부담금) |
| cloze_b1_0208 | particle_mismatch | ＿＿＿이 언제 입금되는지 물었어요. (distractor: 사고 접수, 보장 범위) |
| cloze_b1_0209 | particle_mismatch | 기존 질환은 ＿＿＿이라고 안내받았어요. (distractor: 사고 접수, 보장 범위) |
| cloze_b1_0210 | particle_mismatch | ＿＿＿가 하나 빠져서 보완했어요. (distractor: 자기부담금) |
| cloze_b1_0212 | particle_mismatch | ＿＿＿가 이번 주까지라고 들었어요. (distractor: 자기부담금) |
| cloze_b1_0213 | particle_mismatch | ＿＿＿를 시간 순으로 적었어요. (distractor: 자기부담금) |
| cloze_b1_0214 | particle_mismatch | 치과 ＿＿＿이 있어야 스케일링이 나가요. (distractor: 사고 접수, 보장 범위) |
| cloze_b1_0215 | particle_mismatch | 사진이 흐려서 ＿＿＿가 됐어요. (distractor: 자기부담금) |
| cloze_b1_0219 | particle_mismatch | ＿＿＿이 이 주라고 안내받았어요. (distractor: 구비 서류) |
| cloze_b1_0220 | particle_mismatch | 전입 신고는 ＿＿＿가 따로 있어요. (distractor: 민원실, 접수증) |
| cloze_b1_0222 | particle_mismatch | 본인만 서류 ＿＿＿이 가능해요. (distractor: 구비 서류) |
| cloze_b1_0224 | particle_mismatch | ＿＿＿는 카드만 된다고 했어요. (distractor: 민원실, 접수증) |
| cloze_b1_0226 | particle_mismatch | 전화로 ＿＿＿을 두 번 요청했어요. (distractor: 구비 서류) |
| cloze_b1_0228 | particle_mismatch | 이번 달 ＿＿＿을 표에 적어요. (distractor: 배정표, 안전 조끼) |
| cloze_b1_0230 | particle_mismatch | ＿＿＿을 들어야 부스를 맡을 수 있어요. (distractor: 배정표, 안전 조끼) |
| cloze_b1_0231 | particle_mismatch | 도로 안내는 ＿＿＿를 입고 해요. (distractor: 봉사 시간, 사전 교육) |
| cloze_b1_0232 | particle_mismatch | 다음 조를 위해 ＿＿＿를 남겼어요. (distractor: 봉사 시간, 사전 교육) |
| cloze_b1_0233 | particle_mismatch | 오전에 ＿＿＿이 나서 제가 한 시간 더 했어요. (distractor: 배정표) |
| cloze_b1_0236 | particle_mismatch | 시작 전에 ＿＿＿을 둘이서 해요. (distractor: 배정표) |
| cloze_b1_0239 | particle_mismatch | 학기말에 ＿＿＿를 받아요. (distractor: 봉사 시간, 사전 교육) |
| cloze_b1_0240 | particle_mismatch | ＿＿＿을 수요일 저녁으로 잡았어요. (distractor: 학습 태도) |
| cloze_b1_0242 | particle_mismatch | ＿＿＿이 십오 분이라 질문을 미리 적어요. (distractor: 학습 태도) |
| cloze_b1_0243 | particle_mismatch | ＿＿＿는 좋아졌지만 숙제 속도가 느려요. (distractor: 학부모 면담, 알림장, 상담 시간) |
| cloze_b1_0251 | particle_mismatch | 사진 촬영 ＿＿＿를 오늘 제출해요. (distractor: 학부모 면담, 알림장, 상담 시간) |
| cloze_b1_0252 | particle_mismatch | ＿＿＿를 사진으로 세 장 찍었어요. (distractor: 무상 기간) |
| cloze_b1_0254 | particle_mismatch | ＿＿＿는 오전 방문만 가능하대요. (distractor: 무상 기간) |
| cloze_b1_0255 | particle_mismatch | ＿＿＿이 일주일 남아 있어요. (distractor: 고장 부위, 부품 교체, 출장 수리) |
| cloze_b1_0257 | particle_mismatch | 부품이 없어서 ＿＿＿을 잡았어요. (distractor: 고장 부위, 부품 교체, 출장 수리) |
| cloze_b1_0259 | particle_mismatch | ＿＿＿이 있으면 먼저 전화해 달라고 했어요. (distractor: 고장 부위, 부품 교체, 출장 수리) |
| cloze_b1_0262 | particle_mismatch | ＿＿＿을 받아야 보증이 이어져요. (distractor: 고장 부위, 부품 교체, 출장 수리) |
| cloze_b1_0264 | particle_mismatch | 태풍 때문에 ＿＿＿을 요청했어요. (distractor: 수수료 면제, 대체 열차) |
| cloze_b1_0265 | particle_mismatch | ＿＿＿을 예약 확인서에서 다시 읽어요. (distractor: 수수료 면제, 대체 열차) |
| cloze_b1_0266 | particle_mismatch | 천재지변이면 ＿＿＿가 가능하대요. (distractor: 일정 변경, 환불 규정) |
| cloze_b1_0268 | particle_mismatch | ＿＿＿이 되는지 저녁에 답변 달래요. (distractor: 수수료 면제) |
| cloze_b1_0270 | particle_mismatch | ＿＿＿이 끊기면 숙박권을 받아요. (distractor: 수수료 면제) |
| cloze_b1_0273 | particle_mismatch | ＿＿＿이 한 시간을 넘으면 안내가 나와요. (distractor: 수수료 면제) |
| cloze_b1_0274 | particle_mismatch | ＿＿＿를 카드로 바로 냈어요. (distractor: 일정 변경, 환불 규정) |
| cloze_b1_0279 | particle_mismatch | ＿＿＿이 바뀌어서 새 시간을 확인했어요. (distractor: 채용 공고) |
| cloze_b1_0280 | particle_mismatch | 계약 전에 급여와 휴가 같은 ＿＿＿을 물었어요. (distractor: 채용 공고) |
| cloze_b2_0001 | particle_mismatch | ＿＿＿을 해결해야 해요. (distractor: 투자, 고지서, 끈기) |
| cloze_b2_0003 | particle_mismatch | 서로 다른 ＿＿＿을 가져요. (distractor: 세계, 제도) |
| cloze_b2_0004 | particle_mismatch | ＿＿＿을 공부해요. (distractor: 자료) |
| cloze_b2_0006 | particle_mismatch | ＿＿＿을 내려요. (distractor: 기계, 현대) |
| cloze_b2_0007 | particle_mismatch | ＿＿＿가 없어요. (distractor: 비상) |
| cloze_b2_0009 | particle_mismatch | ＿＿＿가 틀렸어요. (distractor: 관점, 평등) |
| cloze_b2_0011 | particle_mismatch | 사회 ＿＿＿가 중요해요. (distractor: 맥락, 재활용) |
| cloze_b2_0012 | particle_mismatch | ＿＿＿를 지켜요. (distractor: 뚜껑, 약점) |
| cloze_b2_0014 | particle_mismatch | ＿＿＿이 잘 됐어요. (distractor: 전체) |
| cloze_b2_0015 | particle_mismatch | ＿＿＿을 체결했어요. (distractor: 부부, 몸매) |
| cloze_b2_0016 | particle_mismatch | ＿＿＿가 필요해요. (distractor: 현대인, 비용, 폐기물) |
| cloze_b2_0017 | particle_mismatch | ＿＿＿이 늘었어요. (distractor: 자유) |
| cloze_b2_0018 | particle_mismatch | ＿＿＿이 많이 들어요. (distractor: 복지, 철자) |
| cloze_b2_0019 | particle_mismatch | ＿＿＿을 높여야 해요. (distractor: 근거) |
| cloze_b2_0020 | particle_mismatch | ＿＿＿이 강해요. (distractor: 형용사) |
| cloze_b2_0021 | particle_mismatch | 새 ＿＿＿을 세웠어요. (distractor: 평소) |
| cloze_b2_0022 | particle_mismatch | ＿＿＿를 극복했어요. (distractor: 자음, 사회생활, 촛불) |
| cloze_b2_0023 | particle_mismatch | 두 회사의 ＿＿＿이 시작됐어요. (distractor: 습도, 연세) |
| cloze_b2_0024 | particle_mismatch | 새 ＿＿＿이 발표됐어요. (distractor: 연구) |
| cloze_b2_0025 | particle_mismatch | 교육 ＿＿＿가 바뀌어요. (distractor: 협업) |
| cloze_b2_0026 | particle_mismatch | ＿＿＿를 다해요. (distractor: 세상, 이론) |
| cloze_b2_0027 | particle_mismatch | ＿＿＿이 중요해요. (distractor: 예의, 주제, 사고) |
| cloze_b2_0028 | particle_mismatch | ＿＿＿이 사라져야 해요. (distractor: 국기) |
| cloze_b2_0030 | particle_mismatch | 사회 ＿＿＿가 심해져요. (distractor: 성함) |
| cloze_b2_0031 | particle_mismatch | 제 ＿＿＿은 끈기예요. (distractor: 위기) |
| cloze_b2_0033 | particle_mismatch | 십 년의 ＿＿＿이 있어요. (distractor: 정도, 논리) |
| cloze_b2_0035 | particle_mismatch | ＿＿＿이 생겼어요. (distractor: 학위, 의무, 주의) |
| cloze_b2_0037 | particle_mismatch | ＿＿＿을 발휘해요. (distractor: 동사) |
| cloze_b2_0038 | particle_mismatch | ＿＿＿가 부족해요. (distractor: 정책) |
| cloze_b2_0040 | particle_mismatch | ＿＿＿이 뭐예요? (distractor: 봉투, 인기) |
| cloze_b2_0041 | particle_mismatch | 박사 ＿＿＿를 받았어요. (distractor: 갈등, 관객) |
| cloze_b2_0042 | particle_mismatch | ＿＿＿을 발표했어요. (distractor: 윷놀이) |
| cloze_b2_0046 | particle_mismatch | 지구 ＿＿＿가 심각해요. (distractor: 경력) |
| cloze_b2_0047 | particle_mismatch | 공기 ＿＿＿이 점점 심해져요. (distractor: 명사, 철자) |
| cloze_b2_0048 | particle_mismatch | 탄소 ＿＿＿을 줄여야 해요. (distractor: 제도) |
| cloze_b2_0049 | particle_mismatch | 저는 항상 ＿＿＿을 해요. (distractor: 정도) |
| cloze_b2_0051 | particle_mismatch | 우리는 ＿＿＿를 보호해야 해요. (distractor: 비상, 협상) |
| cloze_b2_0052 | particle_mismatch | ＿＿＿을 아껴 써야 해요. (distractor: 임산부, 고지서, 오류) |
| cloze_b2_0053 | particle_mismatch | ＿＿＿을 줄이는 게 중요해요. (distractor: 경우) |
| cloze_b2_0055 | particle_mismatch | ＿＿＿가 지구를 데워요. (distractor: 이론, 모음) |
| cloze_b2_0057 | particle_mismatch | ＿＿＿이 아주 중요해요. (distractor: 평소, 쌍둥이) |
| cloze_b2_0058 | particle_mismatch | 계약서의 ＿＿＿을 하나씩 검토해 보겠습니다. (distractor: 합의서) |
| cloze_b2_0063 | particle_mismatch | 모든 ＿＿＿가 서명한 뒤에 절차를 진행하겠습니다. (distractor: 계약, 조항) |
| cloze_b2_0065 | particle_mismatch | 제출 ＿＿＿을 지키기 어려우면 미리 알려 주세요. (distractor: 유예) |
| cloze_b2_0071 | particle_mismatch | 제품의 ＿＿＿이 확인되면 즉시 교환 절차를 안내해 드리겠습니다. (distractor: 오류) |
| cloze_b2_0078 | particle_mismatch | 결과에 대한 ＿＿＿는 안내된 기한 안에 제출해 주시기 바랍니다. (distractor: 서면 답변, 결함) |
| cloze_b2_0079 | particle_mismatch | 검토가 끝나는 대로 ＿＿＿을 보내드리겠습니다. (distractor: 이의 제기) |
| cloze_b2_0080 | particle_mismatch | 확인된 결함에 대해 필요한 ＿＿＿를 이미 취했습니다. (distractor: 민원, 결함, 보상) |
| cloze_b2_0172 | particle_mismatch | ＿＿＿을 기대하는 눈빛을 현우가 먼저 읽었어요. (distractor: 공식 소개, 단체 인사) |
| cloze_b2_0173 | particle_mismatch | ＿＿＿이 과해서 자리가 오히려 불편했어요. (distractor: 공식 소개, 단체 인사) |
| cloze_b2_0174 | particle_mismatch | ＿＿＿를 보느라 선물을 두 세트로 샀어요. (distractor: 각자 계산) |
| cloze_b2_0175 | particle_mismatch | ＿＿＿는 농담 같지만 규칙이 진짜였어요. (distractor: 불공평, 사생활) |
| cloze_b2_0176 | particle_mismatch | ＿＿＿는 며칠만이라고 선을 그었어요. (distractor: 제사 역할) |
| cloze_b2_0177 | particle_mismatch | ＿＿＿을 문서로 적으니 싸움이 줄었어요. (distractor: 지방 쓰기) |
| cloze_b2_0178 | particle_mismatch | ＿＿＿을 평가하지 않고 현우에게만 확인했어요. (distractor: 빚 이야기) |
| cloze_b2_0179 | particle_mismatch | ＿＿＿을 묻는 게 날씨보다 안전한 시작이었어요. (distractor: 반복 요구, 봉투 준비) |
| cloze_b2_0180 | particle_mismatch | ＿＿＿은 시간보다 성의로 보여 주려 했어요. (distractor: 제사 음식 배치) |
| cloze_b2_0183 | particle_mismatch | ＿＿＿를 음력과 양력으로 둘 다 적었어요. (distractor: 예단) |
| cloze_b2_0184 | particle_mismatch | ＿＿＿이 나와서 현우가 바로 화제를 접었어요. (distractor: 처가, 처가살이) |
| cloze_b2_0188 | particle_mismatch | ＿＿＿이 길어지자 우선순위를 다시 매겼어요. (distractor: 연락 빈도, 예식 날짜) |
| cloze_b2_0190 | particle_mismatch | ＿＿＿을 농담으로 넘기지 않고 일정을 말했어요. (distractor: 사진 공개, 상견례) |
| cloze_b2_0191 | particle_mismatch | ＿＿＿를 존중한다고 하니 질문이 줄었어요. (distractor: 축문) |
| cloze_b2_0194 | particle_mismatch | ＿＿＿를 표로 그리니 실수가 줄었어요. (distractor: 돈 농담, 며느리 역할, 명절 노동) |
| cloze_b2_0196 | particle_mismatch | 동생을 ＿＿＿가 현우가 기침으로 막아 줬어요. (distractor: 한쪽에만, 각자 계산) |
| cloze_b2_0198 | particle_mismatch | ＿＿＿은 작게, 그리고 바로 했어요. (distractor: 상견례, 서로의 속도) |
| cloze_b2_0199 | particle_mismatch | ＿＿＿을 빼면 문장이 갑자기 차갑게 들렸어요. (distractor: 호칭 체계, 혼수, 휴식 교대) |
| cloze_b2_0200 | particle_mismatch | ＿＿＿은 집 밖에서만 쓰기로 했어요. (distractor: 호칭 체계, 혼수) |
| cloze_b2_0201 | particle_mismatch | ＿＿＿을 먼저 하니 긴장이 풀렸어요. (distractor: 혼수, 휴식 교대, 가족 기대) |
| cloze_b2_0202 | particle_mismatch | ＿＿＿이라고 부르는 순간 현우 얼굴이 멈췄어요. (distractor: 제사 음식 배치) |
| cloze_b2_0204 | particle_mismatch | 헷갈리면 ＿＿＿는 게 침묵보다 나았어요. (distractor: 선을 긋) |
| cloze_b2_0207 | particle_mismatch | ＿＿＿는 제가 하지 않고 옆에서 종이만 잡았어요. (distractor: 전 부침, 제사 역할) |
| cloze_b2_0210 | particle_mismatch | ＿＿＿은 듣지 못해도 고개를 숙이면 됐어요. (distractor: 설거지 교대, 술잔 올리기) |
| cloze_b2_0212 | particle_mismatch | ＿＿＿은 상 옆이 아니라 끝난 뒤에만이었어요. (distractor: 음식 나르기, 자리 배치) |
| cloze_b2_0213 | particle_mismatch | ＿＿＿이 없으면 조용히 서는 게 도움이었어요. (distractor: 호칭 공개) |
| cloze_b2_0214 | particle_mismatch | ＿＿＿를 종이에 적어 주머니에 넣었어요. (distractor: 부모님 지원) |
| cloze_b2_0216 | particle_mismatch | ＿＿＿를 건드리지 말라고 눈짓하셨어요. (distractor: 제사 역할, 제사상, 조상님) |
| cloze_b2_0219 | particle_mismatch | ＿＿＿가 나와서 제가 밥값을 먼저 냈어요. (distractor: 양가 공평) |
| cloze_b2_0222 | particle_mismatch | ＿＿＿은 가족 앞에서 자세히 말하지 않았어요. (distractor: 시월드) |
| cloze_b2_0223 | particle_mismatch | ＿＿＿는 식탁이 아니라 나중에 둘이 하기로 했어요. (distractor: 예단, 음복) |
| cloze_b2_0226 | particle_mismatch | ＿＿＿이 날카로워서 웃지 않고 물로 넘겼어요. (distractor: 예식 날짜, 음식 나르기) |
| cloze_b2_0227 | particle_mismatch | ＿＿＿은 가족 식사에서 서운해 보일 수 있어요. (distractor: 예를 갖추다, 오늘은 여기까지, 용돈 드리다) |
| cloze_b2_0228 | particle_mismatch | ＿＿＿를 빠뜨릴 뻔해서 편의점에서 샀어요. (distractor: 잘못된 형, 장인어른 건강) |
| cloze_b2_0229 | particle_mismatch | ＿＿＿이라고 하니 더 묻지 않으셨어요. (distractor: 어른 앞에서, 예를 갖추다, 오늘은 여기까지) |
| cloze_b2_0230 | particle_mismatch | ＿＿＿을 도우려다 기름이 손목에 튀었어요. (distractor: 자리 양보) |
| cloze_b2_0231 | particle_mismatch | ＿＿＿를 제안하니 이모가 놀라셨어요. (distractor: 축문, 축의금, 커플 호칭) |
| cloze_b2_0232 | particle_mismatch | ＿＿＿는 말을 듣고 현우가 일부러 일어났어요. (distractor: 액수는 비밀) |
| cloze_b2_0233 | particle_mismatch | ＿＿＿이 한쪽에만 몰려 있어서 표를 그려 봤어요. (distractor: 사진 공개, 상견례) |
| cloze_b2_0234 | particle_mismatch | ＿＿＿은 웃는 일만이 아니라 물컵을 채우는 일이었어요. (distractor: 봉투 준비, 부조) |
| cloze_b2_0235 | particle_mismatch | ＿＿＿를 말하니 처음엔 어색했지만 효과가 있었어요. (distractor: 시어머니 말씀) |
| cloze_b2_0236 | particle_mismatch | ＿＿＿를 제가 맡으니 허리가 먼저 아팠어요. (distractor: 타협안, 하객 명단) |
| cloze_b2_0237 | particle_mismatch | ＿＿＿를 자처하니 형제들이 고마워했어요. (distractor: 집 장만) |
| cloze_b2_0238 | particle_mismatch | ＿＿＿을 바로 지적하지 않고 다음 할 일을 나눴어요. (distractor: 지방 쓰기) |
| cloze_b2_0239 | particle_mismatch | ＿＿＿를 큰 소리로 하니 자리가 열렸어요. (distractor: 밖에서 예의를) |
| cloze_b2_0244 | particle_mismatch | ＿＿＿를 주 일 회로 정하니 부담이 줄었어요. (distractor: 감정 노동, 거절 문장) |
| cloze_b2_0245 | particle_mismatch | ＿＿＿을 미리 외워 두니 목소리가 흔들리지 않았어요. (distractor: 봉투 준비, 부조) |
| cloze_b2_0246 | particle_mismatch | ＿＿＿을 먼저 내니 거절이 덜 차갑게 들렸어요. (distractor: 시월드, 아이 돌보기, 앉아서 기다리기) |
| cloze_b2_0247 | particle_mismatch | ＿＿＿이 몰릴 때는 현우와 교대하기로 했어요. (distractor: 연락 빈도, 예식 날짜) |
| cloze_b2_0248 | particle_mismatch | ＿＿＿를 전부 맞출 수는 없다고 둘이 먼저 합의했어요. (distractor: 제사 역할, 제사상) |
| cloze_b2_0249 | particle_mismatch | ＿＿＿를 유지하니 관계가 오히려 오래 갔어요. (distractor: 전 부침, 제사 역할) |
| cloze_b2_0255 | particle_mismatch | ＿＿＿는 나이 순이라 제가 문을 가까운 쪽에 앉았어요. (distractor: 부모님 지원, 불공평) |
| cloze_b2_0259 | particle_mismatch | ＿＿＿는 큰 소리보다 고개가 중요했어요. (distractor: 돈 농담, 며느리 역할) |
| cloze_b2_0260 | particle_mismatch | ＿＿＿를 하자 삼촌이 괜찮다고 손짓하셨어요. (distractor: 며느리 역할, 명절 노동, 명절 순환) |
| cloze_b2_0262 | particle_mismatch | ＿＿＿을 밖에서 낮추지 않기로 했어요. (distractor: 양가 회의, 연락 빈도) |
| cloze_b2_0264 | dangling_stem | 관계부터 말하니 악수 타이밍이 맞았어요. (answer="관계부터 말하") |
| cloze_b2_0268 | particle_mismatch | ＿＿＿는 한 분기 안에 측정 가능하게 정해요. (distractor: 성과 면담) |
| cloze_b2_0270 | particle_mismatch | ＿＿＿은 형용사보다 사례로 적어요. (distractor: 목표 대비, 개선 과제) |
| cloze_b2_0271 | particle_mismatch | ＿＿＿를 받은 날 바로 정리해요. (distractor: 성과 면담) |
| cloze_b2_0272 | particle_mismatch | ＿＿＿이 공개되지 않아 질문을 준비했어요. (distractor: 목표 대비, 개선 과제) |
| cloze_b2_0273 | particle_mismatch | ＿＿＿을 이틀 안에 공유해 달라고 했어요. (distractor: 목표 대비, 개선 과제) |
| cloze_b2_0274 | particle_mismatch | ＿＿＿은 팀 결과에 연결해서 말해요. (distractor: 목표 대비, 개선 과제) |
| cloze_b2_0276 | particle_mismatch | ＿＿＿가 반기라서 중간 점검을 넣었어요. (distractor: 성과 면담) |
| cloze_b2_0277 | particle_mismatch | ＿＿＿를 달력에 바로 넣어요. (distractor: 성과 면담) |
| cloze_b2_0282 | particle_mismatch | 직접 합의가 안 되어 ＿＿＿을 넣었어요. (distractor: 원상복구, 하자 보수) |
| cloze_b2_0284 | particle_mismatch | 공사 기간 ＿＿＿을 미리 공지해 달라고 했어요. (distractor: 원상복구, 하자 보수) |
| cloze_b2_0289 | particle_mismatch | ＿＿＿을 받기 전에는 공사에 동의하지 않아요. (distractor: 원상복구, 하자 보수) |
| cloze_b2_0290 | particle_mismatch | 제목만 보지 말고 ＿＿＿를 먼저 해요. (distractor: 선택 편집) |
| cloze_b2_0292 | particle_mismatch | ＿＿＿가 없으면 광고인지 의심해요. (distractor: 선택 편집) |
| cloze_b2_0293 | particle_mismatch | 자료마다 ＿＿＿이 다르면 수치만 보고 비교하기 어려워요. (distractor: 출처 표시) |
| cloze_b2_0294 | particle_mismatch | 한 문장만 떼면 ＿＿＿이 사라져요. (distractor: 원문 대조, 후원 표시) |
| cloze_b2_0295 | particle_mismatch | ＿＿＿가 내려도 첫 제목이 더 멀리 퍼져요. (distractor: 선택 편집) |
| cloze_b2_0296 | particle_mismatch | ＿＿＿는 다른 출처와 겹치는지 봐요. (distractor: 선택 편집) |
| cloze_b2_0299 | particle_mismatch | ＿＿＿은 빼고 수치를 있는 그대로 전달해요. (distractor: 원문 대조, 후원 표시) |
| cloze_b2_0300 | particle_mismatch | ＿＿＿이 2차면 1차를 찾아요. (distractor: 원문 대조, 후원 표시) |
| cloze_b2_0301 | particle_mismatch | 화가 날수록 ＿＿＿를 십 분 해요. (distractor: 선택 편집) |
| cloze_b2_0302 | particle_mismatch | ＿＿＿을 삼 분 안에 한 가지로 말해요. (distractor: 안건 순서) |
| cloze_b2_0303 | particle_mismatch | ＿＿＿가 바뀌면 발언 준비를 다시 해요. (distractor: 주민 의견, 발언권, 회의 기록문) |
| cloze_b2_0304 | particle_mismatch | ＿＿＿을 받은 뒤에만 자료를 나눠 줘요. (distractor: 안건 순서) |
| cloze_b2_0306 | particle_mismatch | ＿＿＿를 먼저 밝히고 제안을 말해요. (distractor: 주민 의견, 발언권) |
| cloze_b2_0307 | particle_mismatch | ＿＿＿는 감정 대신 비용으로 말해요. (distractor: 주민 의견, 발언권) |
| cloze_b2_0308 | particle_mismatch | ＿＿＿을 문구 단위로 읽어 달라고 했어요. (distractor: 안건 순서) |
| cloze_b2_0309 | particle_mismatch | ＿＿＿이 거수인지 비밀인지 확인해요. (distractor: 안건 순서) |
| cloze_b2_0311 | particle_mismatch | ＿＿＿이 안 차서 결정을 미뤘어요. (distractor: 안건 순서) |
| cloze_b2_0312 | particle_mismatch | ＿＿＿는 개인 비난 없이 사실만 물어요. (distractor: 주민 의견, 발언권) |
| cloze_b2_0314 | particle_mismatch | ＿＿＿를 미리 적어 두고 회의에 들어가요. (distractor: 핵심 조건, 침묵 구간) |
| cloze_b2_0315 | particle_mismatch | ＿＿＿은 일정이고 나머지는 조정 가능해요. (distractor: 양보 범위, 대안 제시) |
| cloze_b2_0316 | particle_mismatch | 거절만 하지 말고 ＿＿＿를 한 줄 붙어요. (distractor: 핵심 조건, 침묵 구간) |
| cloze_b2_0317 | particle_mismatch | 숫자가 나온 뒤 ＿＿＿을 십 초 둬요. (distractor: 양보 범위, 대안 제시) |
| cloze_b2_0318 | particle_mismatch | ＿＿＿을 화면에 띄우고 문장마다 확인해요. (distractor: 양보 범위, 대안 제시) |
| cloze_b2_0319 | particle_mismatch | ＿＿＿이 없는 안건은 보류한다고 말해요. (distractor: 양보 범위, 대안 제시) |
| cloze_b2_0322 | particle_mismatch | ＿＿＿을 정해야 합의가 흐려지지 않아요. (distractor: 양보 범위, 대안 제시) |
| cloze_b2_0323 | particle_mismatch | ＿＿＿가 자료 부족이면 날짜를 같이 정해요. (distractor: 핵심 조건) |
| cloze_b2_0324 | particle_mismatch | ＿＿＿가 한쪽에만 있으면 다시 말해요. (distractor: 핵심 조건) |
| cloze_b2_0325 | particle_mismatch | ＿＿＿을 채팅에 붙여 확인하고 끝나요. (distractor: 양보 범위, 대안 제시) |
| cloze_b2_0327 | particle_mismatch | ＿＿＿는 비용, 시간, 위험을 같은 순서로 적어요. (distractor: 한 장 요약, 영향 집단) |
| cloze_b2_0328 | particle_mismatch | ＿＿＿를 빼면 숫자가 사실처럼 보여요. (distractor: 한 장 요약, 영향 집단) |
| cloze_b2_0329 | particle_mismatch | ＿＿＿을 먼저 적고 혜택을 나중에 적어요. (distractor: 선택지 비교, 가정 명시) |
| cloze_b2_0330 | particle_mismatch | ＿＿＿는 이번 달에 할 일만 세 개로 줄여요. (distractor: 한 장 요약) |
| cloze_b2_0331 | particle_mismatch | ＿＿＿를 한 단락만 넣어도 설득이 단단해져요. (distractor: 한 장 요약) |
| cloze_b2_0332 | particle_mismatch | ＿＿＿가 모호하면 성공을 나중에 다툴 수 있어요. (distractor: 한 장 요약) |
| cloze_b2_0333 | particle_mismatch | ＿＿＿은 동사로 시작하고 조건을 붙어요. (distractor: 선택지 비교, 가정 명시) |
| cloze_b2_0334 | particle_mismatch | ＿＿＿를 내부와 외부로 나눠 적어요. (distractor: 한 장 요약) |
| cloze_b2_0335 | particle_mismatch | ＿＿＿을 적지 않으면 논의가 늘어져요. (distractor: 선택지 비교, 가정 명시) |
| cloze_b2_0336 | particle_mismatch | ＿＿＿는 링크보다 날짜와 기관을 먼저 적어요. (distractor: 한 장 요약) |
| cloze_b2_0337 | particle_mismatch | ＿＿＿을 숨기지 않고 마지막에 적어요. (distractor: 선택지 비교, 가정 명시) |
| cloze_b2_0339 | particle_mismatch | ＿＿＿를 제목에 넣고 이력을 붙여요. (distractor: 상위 담당, 약속 불이행) |
| cloze_b2_0341 | particle_mismatch | ＿＿＿를 먼저 밝히면 기대가 맞춰져요. (distractor: 상위 담당, 약속 불이행) |
| cloze_b2_0342 | particle_mismatch | ＿＿＿이 세 번이면 점검을 요구해요. (distractor: 사건 번호) |
| cloze_b2_0346 | particle_mismatch | ＿＿＿가 두 부서면 한 사람을 지정해 달라고 해요. (distractor: 상위 담당, 약속 불이행) |
| cloze_b2_0347 | particle_mismatch | 사진만으로 부족하면 ＿＿＿을 요청해요. (distractor: 사건 번호) |
| cloze_b2_0348 | particle_mismatch | ＿＿＿을 구두로만 듣지 않고 글로 받아요. (distractor: 사건 번호) |
| cloze_b2_0349 | particle_mismatch | ＿＿＿이 오기 전에는 사건을 닫지 않아요. (distractor: 사건 번호) |
| cloze_b2_0350 | particle_mismatch | ＿＿＿을 한 문장으로 고정하고 자료를 모아요. (distractor: 표본 크기) |
| cloze_b2_0351 | particle_mismatch | ＿＿＿가 작으면 일반화를 낮춰 말해요. (distractor: 연구 질문, 한계 문장, 교차 확인) |
| cloze_b2_0352 | particle_mismatch | ＿＿＿을 결과보다 먼저 읽게 배치해요. (distractor: 표본 크기) |
| cloze_b2_0354 | particle_mismatch | ＿＿＿를 슬라이드 아래에 작게 적어요. (distractor: 연구 질문, 한계 문장) |
| cloze_b2_0355 | particle_mismatch | ＿＿＿을 팀 안에서 하나로 맞춰요. (distractor: 표본 크기) |
| cloze_b2_0356 | particle_mismatch | ＿＿＿를 '보인다'와 '확인된다'로 나눠요. (distractor: 연구 질문, 한계 문장) |
| cloze_b2_0357 | particle_mismatch | ＿＿＿는 축부터 소리 내어 확인해요. (distractor: 연구 질문, 한계 문장) |
| cloze_b2_0358 | particle_mismatch | ＿＿＿를 다섯 분만 해도 주장이 조심스러워져요. (distractor: 연구 질문, 한계 문장) |
| cloze_b2_0359 | particle_mismatch | ＿＿＿은 새 정보를 넣지 않아요. (distractor: 표본 크기) |
| cloze_b2_0361 | particle_mismatch | ＿＿＿을 날짜순으로 정리해 공유해요. (distractor: 표본 크기) |
| cloze_b2_0363 | particle_mismatch | 월세가 낮아도 난방비를 더하면 ＿＿＿가 높아질 수 있어요. (distractor: 보증금, 통근) |
| cloze_b2_0364 | particle_mismatch | 계약 전에 ＿＿＿을 서면으로 확인해 주세요. (distractor: 입주 날짜, 가구 배치) |
| cloze_b2_0366 | particle_mismatch | 정형화된 항목 밖의 경험은 ＿＿＿을 함께 설명해야 합니다. (distractor: 점수와 순위, 학력과 나이, 사진과 주소) |
| cloze_b2_0367 | particle_mismatch | 지원자는 ＿＿＿를 요청할 수 있어야 합니다. (distractor: 빠른 탈락, 자동 답장) |
| cloze_b2_0369 | particle_mismatch | 주택 부족과 정착 지원은 서로 연결되지만 ＿＿＿는 아닙니다. (distractor: 같은 사람, 같은 직업) |
| cloze_b2_0370 | particle_mismatch | ＿＿＿를 알면 경력에 맞는 일자리를 찾기 쉬워집니다. (distractor: 주택 계약 기간, 세대별 취향) |
| cloze_b2_0372 | particle_mismatch | 짧은 영상의 조회수가 ＿＿＿를 자동으로 보장하지는 않아요. (distractor: 노래의 후렴, 자막의 색) |
| cloze_b2_0373 | particle_mismatch | 팬 자원봉사자의 ＿＿＿을 미리 나눠야 활동이 지속됩니다. (distractor: 조회수와 순위) |
| cloze_b2_0374 | particle_mismatch | 계약서의 월세만 보지 말고 ＿＿＿를 먼저 계산해 봅시다. (distractor: 임대료 인상, 자격 인정) |
| cloze_b2_0378 | particle_mismatch | 회사는 지원자에게 ＿＿＿를 요청할 방법을 알려 줬습니다. (distractor: 채용 기준, 인력 부족, 참여 방식) |
| cloze_b2_0379 | particle_mismatch | ＿＿＿이 공개되어야 지원자도 결과를 이해할 수 있습니다. (distractor: 현지화, 총주거비) |
| cloze_b2_0382 | particle_mismatch | ＿＿＿을 해결하려면 채용뿐 아니라 오래 일할 조건도 마련해야 합니다. (distractor: 현지화, 총주거비) |
| cloze_b2_0383 | particle_mismatch | ＿＿＿는 번역만이 아니라 지역 맥락에 맞게 설명하는 일도 포함합니다. (distractor: 팬 번역, 임대료 인상) |
| cloze_b2_0385 | particle_mismatch | 조회수가 같아도 댓글과 행사 ＿＿＿은 지역마다 다를 수 있습니다. (distractor: 총주거비) |
| cloze_b2_0386 | particle_mismatch | ＿＿＿가 소득에서 차지하는 비중을 따로 살펴봤습니다. (distractor: 실질 소득, 물가 상승) |
| cloze_b2_0389 | particle_mismatch | ＿＿＿이 모든 가구에 같은 부담을 주는 것은 아닙니다. (distractor: 월 생활비, 주거비) |
| cloze_b2_0390 | particle_mismatch | 교통비까지 포함하니 ＿＿＿가 예상보다 컸습니다. (distractor: 임대차 계약) |
| cloze_c1_0024 | josa_dup | 인터뷰 내용과 실제 이용 기록을 대조하니 기억과 행동 사이에 차이가 보였습니다. |
| cloze_c1_0055 | particle_mismatch | ＿＿＿을 누가 말하느냐에 따라 자리가 달라졌어요. (distractor: 말의 자리) |
| cloze_c1_0056 | particle_mismatch | ＿＿＿를 들을 때마다 현우와 나중에 번역하기로 했어요. (distractor: 소속 프레임, 전통의 선택) |
| cloze_c1_0057 | particle_mismatch | ＿＿＿을 제안하니 처음엔 어색했지만 공기가 바뀌었어요. (distractor: 침묵의 동의, 타자화) |
| cloze_c1_0058 | particle_mismatch | ＿＿＿가 웃음을 타고 와서 바로 지적하기 어려웠어요. (distractor: 포용적 호칭) |
| cloze_c1_0060 | particle_mismatch | ＿＿＿가 누구인지 묻자 잠시 조용해졌어요. (distractor: 보이지 않는 일, 분배 기준, 성별 분업) |
| cloze_c1_0061 | particle_mismatch | ＿＿＿가 의자보다 먼저 배치된다는 걸 그날 배웠어요. (distractor: 전통의 선택) |
| cloze_c1_0064 | dangling_stem | 자리를 재협상하자 다음 명절 표가 달라졌어요. (answer="자리를 재협상하") |
| cloze_c1_0065 | particle_mismatch | ＿＿＿이 상을 완성한다는 걸 설거지통에서 봤어요. (distractor: 역할 언어, 침묵의 동의) |
| cloze_c1_0066 | particle_mismatch | ＿＿＿을 전통으로만 설명하면 대화가 멈췄어요. (distractor: 말의 자리) |
| cloze_c1_0068 | particle_mismatch | ＿＿＿을 사진이 아니라 교대표로 남기기로 했어요. (distractor: 역할 언어, 침묵의 동의) |
| cloze_c1_0069 | particle_mismatch | ＿＿＿을 모두 지킬 필요는 없다고 짧게 말했어요. (distractor: 역할 언어, 침묵의 동의, 타자화) |
| cloze_c1_0070 | particle_mismatch | ＿＿＿은 칭찬 한 마디보다 다음 할 일을 나누는 것이었어요. (distractor: 침묵의 동의, 타자화) |
| cloze_c1_0072 | particle_mismatch | ＿＿＿을 나이에서 체력으로 바꾸자 반발이 줄었어요. (distractor: 침묵의 동의, 타자화) |
| cloze_c1_0073 | particle_mismatch | ＿＿＿를 합의로 보지 않기로 둘이 정했어요. (distractor: 분배 기준, 성별 분업, 소속 프레임) |
| cloze_c1_0075 | dangling_stem | 노동을 보이게 하자 감사의 대상이 달라졌어요. (answer="노동을 보이게 하") |
| cloze_c1_0076 | dangling_stem | 공평을 설계하니 감정이 아니라 표가 남았어요. (answer="공평을 설계하") |
| cloze_c1_0077 | particle_mismatch | ＿＿＿을 숨기면 결론이 과해 보여요. (distractor: 과잉 일반화) |
| cloze_c1_0078 | particle_mismatch | ＿＿＿을 인정해야 비교가 정직해져요. (distractor: 과잉 일반화) |
| cloze_c1_0079 | particle_mismatch | ＿＿＿를 피하려고 적용 범위를 좁혀요. (distractor: 불확실성 구간, 표본 편향, 신뢰 구간) |
| cloze_c1_0080 | particle_mismatch | ＿＿＿이 넓으면 순위 주장을 내려요. (distractor: 과잉 일반화) |
| cloze_c1_0081 | particle_mismatch | ＿＿＿을 첫 문단에 두면 오해가 줄어요. (distractor: 과잉 일반화) |
| cloze_c1_0082 | particle_mismatch | ＿＿＿를 자료가 감당하는 만큼만 올려요. (distractor: 불확실성 구간, 표본 편향) |
| cloze_c1_0083 | particle_mismatch | ＿＿＿이 있는 달은 추세를 단정하지 않아요. (distractor: 과잉 일반화) |
| cloze_c1_0084 | particle_mismatch | ＿＿＿를 말하면 작은 차이를 과장하지 않게 돼요. (distractor: 불확실성 구간, 표본 편향) |
| cloze_c1_0085 | particle_mismatch | 상관만 있으면 ＿＿＿을 하지 않아요. (distractor: 과잉 일반화) |
| cloze_c1_0086 | particle_mismatch | ＿＿＿를 확인하기 전에는 정책을 바꾸지 말자고 해요. (distractor: 불확실성 구간, 표본 편향) |
| cloze_c1_0087 | particle_mismatch | ＿＿＿를 줄이려고 실패한 지표도 표에 남겨요. (distractor: 불확실성 구간, 표본 편향) |
| cloze_c1_0088 | particle_mismatch | ＿＿＿이라고 쓰면 청자가 여지를 남겨 둬요. (distractor: 과잉 일반화) |
| cloze_c1_0094 | particle_mismatch | ＿＿＿가 필요할 때는 확인 시각을 밝히고 기다려요. (distractor: 브리핑 문안, 위험 등급, 비전문가 설명) |
| cloze_c1_0095 | particle_mismatch | ＿＿＿는 기관마다 다른 수치를 먼저 맞추어요. (distractor: 브리핑 문안, 위험 등급, 비전문가 설명) |
| cloze_c1_0097 | particle_mismatch | ＿＿＿를 브리핑 끝에 크게 안내해요. (distractor: 브리핑 문안, 위험 등급, 비전문가 설명) |
| cloze_c1_0098 | particle_mismatch | ＿＿＿는 대상과 기한을 빠뜨리지 않아요. (distractor: 브리핑 문안, 위험 등급, 비전문가 설명) |
| cloze_c1_0101 | particle_mismatch | ＿＿＿를 줄이려고 선택지를 대칭으로 만들어요. (distractor: 표집틀) |
| cloze_c1_0102 | particle_mismatch | ＿＿＿를 밝히지 않으면 비율이 부풀어 보여요. (distractor: 표집틀) |
| cloze_c1_0106 | particle_mismatch | ＿＿＿이 길면 뒷부분 품질이 떨어져요. (distractor: 문항 유도, 무응답 처리, 가중치 부여) |
| cloze_c1_0107 | particle_mismatch | ＿＿＿이 고르지 않으면 평균을 쓰지 않아요. (distractor: 문항 유도, 무응답 처리, 가중치 부여) |
| cloze_c1_0109 | particle_mismatch | ＿＿＿이 선거 직후면 해석을 낮춰요. (distractor: 문항 유도, 무응답 처리, 가중치 부여) |
| cloze_c1_0110 | particle_mismatch | 문항이 바뀌면 ＿＿＿을 포기한다고 적어요. (distractor: 문항 유도, 무응답 처리, 가중치 부여) |
| cloze_c1_0111 | particle_mismatch | ＿＿＿을 높이면 지역 분석이 어려워져요. (distractor: 문항 유도, 무응답 처리, 가중치 부여) |
| cloze_c1_0114 | particle_mismatch | ＿＿＿를 옆에 두면 공포가 줄어들어요. (distractor: 상대 위험, 잔여 위험) |
| cloze_c1_0115 | particle_mismatch | ＿＿＿을 0으로 약속하지 않아요. (distractor: 절대 건수, 조기 경보) |
| cloze_c1_0116 | particle_mismatch | ＿＿＿는 오탐 비율을 같이 말해야 해요. (distractor: 상대 위험, 잔여 위험) |
| cloze_c1_0117 | particle_mismatch | ＿＿＿이 높으면 경보를 자주 무시하게 돼요. (distractor: 절대 건수) |
| cloze_c1_0118 | particle_mismatch | ＿＿＿을 빼면 같은 농도도 다르게 들려요. (distractor: 절대 건수) |
| cloze_c1_0119 | particle_mismatch | ＿＿＿을 평균에 묻히지 않고 따로 적어요. (distractor: 절대 건수) |
| cloze_c1_0120 | particle_mismatch | ＿＿＿을 숫자로 정해야 현장 판단이 흔들리지 않아요. (distractor: 절대 건수) |
| cloze_c1_0121 | particle_mismatch | ＿＿＿을 낮추면 사람들이 더 오래 들어요. (distractor: 절대 건수) |
| cloze_c1_0122 | particle_mismatch | ＿＿＿를 밝히면 침묵이 은폐처럼 안 보여요. (distractor: 상대 위험, 잔여 위험) |
| cloze_c1_0123 | particle_mismatch | ＿＿＿을 작년으로 둘지 평년으로 둘지 먼저 정해요. (distractor: 절대 건수) |
| cloze_c1_0124 | particle_mismatch | ＿＿＿를 줄이려고 등급을 세 단계로만 써요. (distractor: 상대 위험, 잔여 위험) |
| cloze_c1_0125 | particle_mismatch | ＿＿＿을 요금만이 아니라 이동 시간으로도 세요. (distractor: 선택권 축소, 우회 경로) |
| cloze_c1_0126 | particle_mismatch | ＿＿＿을 초기 설치비와 따로 적어요. (distractor: 선택권 축소, 우회 경로) |
| cloze_c1_0127 | particle_mismatch | ＿＿＿를 효율로 포장하지 않아요. (distractor: 접근 비용, 유지 부담) |
| cloze_c1_0128 | particle_mismatch | ＿＿＿가 있어야 본 경로 장애를 견딜 수 있어요. (distractor: 접근 비용, 유지 부담) |
| cloze_c1_0130 | particle_mismatch | ＿＿＿이 앱 전용이면 창구 대안을 남겨요. (distractor: 선택권 축소) |
| cloze_c1_0131 | particle_mismatch | ＿＿＿이 특정 시간대에 몰리는지 봐요. (distractor: 선택권 축소) |
| cloze_c1_0132 | particle_mismatch | ＿＿＿이 저사용 가구를 해치는지 계산해요. (distractor: 선택권 축소) |
| cloze_c1_0133 | particle_mismatch | ＿＿＿이 한글만이면 다른 언어 요약을 붙여요. (distractor: 선택권 축소) |
| cloze_c1_0136 | particle_mismatch | ＿＿＿가 이용자에게만 가면 설계를 다시 해요. (distractor: 접근 비용, 유지 부담) |
| cloze_c1_0137 | particle_mismatch | ＿＿＿을 시간, 언어, 이동으로 나눠 적어요. (distractor: 대리 참여) |
| cloze_c1_0138 | particle_mismatch | ＿＿＿을 먼저 온 사람 순으로만 주지 않아요. (distractor: 대리 참여) |
| cloze_c1_0139 | particle_mismatch | ＿＿＿를 허용하면 위임 범위를 짧게 적어요. (distractor: 참여 장벽, 발언 할당, 피드백 순환) |
| cloze_c1_0140 | particle_mismatch | ＿＿＿이 없으면 참여가 일회성으로 끝나요. (distractor: 대리 참여) |
| cloze_c1_0141 | particle_mismatch | ＿＿＿을 주최 측만 가지면 결과가 기울어요. (distractor: 대리 참여) |
| cloze_c1_0142 | particle_mismatch | ＿＿＿을 표 밖에 따로 기록해요. (distractor: 대리 참여) |
| cloze_c1_0143 | particle_mismatch | ＿＿＿를 고르지 못하면 온라인 병행을 열어요. (distractor: 참여 장벽, 발언 할당) |
| cloze_c1_0144 | particle_mismatch | ＿＿＿을 행사 예산의 기본 항목으로 넣어요. (distractor: 대리 참여) |
| cloze_c1_0145 | particle_mismatch | ＿＿＿를 삼 일 전에 보내야 질문이 깊어져요. (distractor: 참여 장벽, 발언 할당) |
| cloze_c1_0146 | particle_mismatch | ＿＿＿를 줄이려고 회의를 겹치지 않게 잡아요. (distractor: 참여 장벽, 발언 할당) |
| cloze_c1_0147 | particle_mismatch | ＿＿＿가 늦으면 다음 참여율이 떨어져요. (distractor: 참여 장벽, 발언 할당) |
| cloze_c1_0148 | particle_mismatch | ＿＿＿는 취향 투표가 아니라 제약 공유에서 시작해요. (distractor: 참여 장벽, 발언 할당) |
| cloze_c1_0149 | particle_mismatch | ＿＿＿을 전국 평균에 맞추면 계획이 빗겨요. (distractor: 야간 소음 한도) |
| cloze_c1_0150 | particle_mismatch | ＿＿＿를 낮추면 배달 시간이 줄어들어요. (distractor: 지역 여건, 녹지 보전, 상권 이전) |
| cloze_c1_0152 | particle_mismatch | ＿＿＿이 골목을 비우면 저녁 안전이 약해져요. (distractor: 야간 소음 한도) |
| cloze_c1_0153 | particle_mismatch | ＿＿＿가 학교 앞을 지나면 시간대를 바꿔요. (distractor: 지역 여건, 녹지 보전) |
| cloze_c1_0154 | particle_mismatch | ＿＿＿을 건물주만으로 두면 세입자가 빠져요. (distractor: 야간 소음 한도) |
| cloze_c1_0156 | particle_mismatch | ＿＿＿이 눈에 보여야 규제를 받아들이기 쉬워요. (distractor: 야간 소음 한도) |
| cloze_c1_0157 | particle_mismatch | ＿＿＿을 단발 지원으로만 보면 실패해요. (distractor: 야간 소음 한도) |
| cloze_c1_0158 | particle_mismatch | ＿＿＿을 높이면 안전은 오르고 수면은 나빠져요. (distractor: 야간 소음 한도) |
| cloze_c1_0159 | particle_mismatch | ＿＿＿를 나누면 한 공간이 두 집단을 받을 수 있어요. (distractor: 지역 여건, 녹지 보전) |
| cloze_c1_0160 | particle_mismatch | ＿＿＿을 한 달만 해도 민원이 구체화돼요. (distractor: 야간 소음 한도) |
| cloze_c1_0161 | particle_mismatch | ＿＿＿을 자원봉사에만 기대면 겨울에 끊겨요. (distractor: 교체 주기, 점검 로그) |
| cloze_c1_0162 | particle_mismatch | ＿＿＿를 숨기면 나중에 한꺼번에 비용이 와요. (distractor: 운영 인력, 예비 부품) |
| cloze_c1_0163 | particle_mismatch | ＿＿＿이 없으면 포용 장비가 바로 멈춰요. (distractor: 교체 주기, 점검 로그) |
| cloze_c1_0164 | particle_mismatch | ＿＿＿를 공개하면 방치 여부를 따질 수 있어요. (distractor: 운영 인력, 예비 부품) |
| cloze_c1_0165 | particle_mismatch | ＿＿＿을 한 사람에게만 맡기면 실수가 늘어요. (distractor: 교체 주기) |
| cloze_c1_0166 | particle_mismatch | ＿＿＿을 빼면 새 절차가 현장에 안 남아요. (distractor: 교체 주기) |
| cloze_c1_0167 | particle_mismatch | ＿＿＿가 길면 대체 수단을 같이 설계해요. (distractor: 운영 인력, 예비 부품) |
| cloze_c1_0168 | particle_mismatch | ＿＿＿이 제한되면 남은 예산을 소진하기 위한 불필요한 지출이 발생할 수 있어요. (distractor: 교체 주기) |
| cloze_c1_0170 | particle_mismatch | ＿＿＿을 낙관하면 교체 기금이 비어요. (distractor: 교체 주기) |
| cloze_c1_0171 | particle_mismatch | ＿＿＿이 높으면 작은 수정도 기다려야 해요. (distractor: 교체 주기) |
| cloze_c1_0172 | particle_mismatch | ＿＿＿를 행사 날에만 쓰면 평일 품질이 떨어져요. (distractor: 운영 인력, 예비 부품) |
| cloze_c1_0173 | particle_mismatch | ＿＿＿이 서른 명뿐이라 결론을 넓히기 어렵습니다. (distractor: 출처) |
| cloze_c1_0174 | particle_mismatch | 성급한 ＿＿＿는 오해를 만듭니다. (distractor: 검증, 반박, 인용) |
| cloze_c1_0176 | particle_mismatch | ＿＿＿를 말하려면 시간 순서가 분명해야 합니다. (distractor: 재현성) |
| cloze_c1_0177 | particle_mismatch | 참가자를 모으는 방식에 ＿＿＿이 있었습니다. (distractor: 출처, 인과) |
| cloze_c1_0178 | particle_mismatch | ＿＿＿를 밝히지 않은 수치는 쓰지 않습니다. (distractor: 표본, 인용, 검증) |
| cloze_c1_0179 | particle_mismatch | ＿＿＿이 확인되기 전에는 결과가 잠정적입니다. (distractor: 인과) |
| cloze_c1_0182 | particle_mismatch | ＿＿＿을 거치지 않은 주장은 권하지 않습니다. (distractor: 일반화) |
| cloze_c1_0184 | particle_mismatch | ＿＿＿을 할 때는 논문 번호를 함께 적습니다. (distractor: 출처) |
| cloze_c1_0185 | particle_mismatch | 이용시간 ＿＿＿가 수면 시간을 늘렸는지 확인해야 합니다. (distractor: 시행) |
| cloze_c1_0187 | particle_mismatch | 규제의 ＿＿＿을 함께 적어야 판단이 공정합니다. (distractor: 역효과) |
| cloze_c1_0188 | particle_mismatch | ＿＿＿을 따지려면 비교 집단이 필요합니다. (distractor: 지표, 규제) |
| cloze_c1_0191 | particle_mismatch | ＿＿＿를 하나만 쓰면 그림이 좁아집니다. (distractor: 산정, 상한, 자율) |
| cloze_c1_0192 | particle_mismatch | 밤에 몰아서 하는 ＿＿＿가 보고됐습니다. (distractor: 부작용) |
| cloze_c1_0193 | particle_mismatch | 부모 계정을 쓰는 ＿＿＿가 흔합니다. (distractor: 자율, 시행) |
| cloze_c1_0198 | particle_mismatch | ＿＿＿을 이유로 부담을 늘리면 안 됩니다. (distractor: 무보수, 착취) |
| cloze_c1_0199 | particle_mismatch | 컴백 주간마다 ＿＿＿을 호소하는 사람이 늘어납니다. (distractor: 과부하) |
| cloze_c1_0203 | particle_mismatch | 행사 직전에 ＿＿＿가 한쪽으로 몰립니다. (distractor: 소진, 동원) |
| cloze_c1_0205 | particle_mismatch | 시험 기간에는 ＿＿＿이 거의 남지 않습니다. (distractor: 과부하) |
| cloze_c1_0208 | particle_mismatch | 투표 기간의 ＿＿＿이 끝나면 사람들이 사라집니다. (distractor: 착취) |
| cloze_c1_0211 | particle_mismatch | 직장 정보의 ＿＿＿은 되돌리기 어렵습니다. (distractor: 경위, 임계치) |
| cloze_c1_0213 | particle_mismatch | 신고서에 ＿＿＿를 시간 순서로 적게 합니다. (distractor: 완충, 익명) |
| cloze_c1_0214 | particle_mismatch | 표현의 ＿＿＿를 단계로 나눠 두면 판단이 빨라집니다. (distractor: 선별) |
| cloze_c1_0216 | particle_mismatch | 자동 ＿＿＿이 놓친 신고는 사람이 다시 봅니다. (distractor: 수위) |
| cloze_c1_0217 | particle_mismatch | ＿＿＿를 낮추면 억울한 정지가 늘어납니다. (distractor: 선별, 완충) |
| cloze_c1_0220 | particle_mismatch | 서로의 ＿＿＿를 먼저 말해 두면 갈등이 줄어듭니다. (distractor: 대면, 노출) |
| cloze_c1_0222 | particle_mismatch | 같은 월세라도 에너지 비용에 따라 ＿＿＿은 달라집니다. (distractor: 입주 순서) |
| cloze_c1_0223 | particle_mismatch | 지원 효과와 신청 과정의 ＿＿＿을 함께 평가해야 합니다. (distractor: 홍보 문구, 통근 거리, 가구 배치) |
| cloze_c1_0226 | particle_mismatch | 재검토가 ＿＿＿을 공개해야 절차를 평가할 수 있습니다. (distractor: 지원자의 나이, 면접실 위치, 공고의 길이) |
| cloze_c1_0228 | particle_mismatch | 자격 인정과 주거 지원이 늦으면 ＿＿＿을 활용하기 어렵습니다. (distractor: 입국 통계, 광고 문구) |
| cloze_c1_0229 | particle_mismatch | 지역별 일자리와 ＿＿＿을 함께 봐야 정착 계획이 현실적입니다. (distractor: 공연 순서, 월세 광고, 면접 점수) |
| cloze_c1_0231 | particle_mismatch | 팬의 자막 기여를 무료 홍보로만 계산하면 ＿＿＿이 보이지 않습니다. (distractor: 조회수와 순위) |
| cloze_c1_0232 | particle_mismatch | 확산의 크기와 지속 가능한 참여는 ＿＿＿가 필요합니다. (distractor: 같은 자막, 짧은 후렴) |
| cloze_c1_0234 | particle_mismatch | 신규 계약이 적게 포함된 ＿＿＿이라면 현재 부담을 낮게 보일 수 있습니다. (distractor: 인과관계) |
| cloze_c1_0235 | particle_mismatch | 두 값이 함께 올랐다는 사실만으로 ＿＿＿를 단정할 수는 없습니다. (distractor: 정착 역량, 추천 편향) |
| cloze_c1_0236 | particle_mismatch | 자동화의 평균 효과보다 집단별 ＿＿＿를 따로 살펴야 합니다. (distractor: 제도 접근성, 무급 노동) |
| cloze_c1_0240 | particle_mismatch | 신청 자격이 있어도 안내가 복잡하면 ＿＿＿이 낮습니다. (distractor: 인과관계) |
| cloze_c1_0241 | particle_mismatch | 교대 근무 가정의 ＿＿＿은 취업 지속성에 직접 영향을 줍니다. (distractor: 지표의 한계, 분배 효과) |
| cloze_c1_0242 | particle_mismatch | ＿＿＿이 크면 조회수가 실제 선호보다 노출 구조를 더 많이 반영합니다. (distractor: 이해관계자) |
| cloze_c1_0244 | particle_mismatch | 말장난은 직역보다 배경을 짧게 덧붙이는 ＿＿＿이 더 정확할 때가 있습니다. (distractor: 지표의 한계, 분배 효과) |
| cloze_c1_0245 | particle_mismatch | ＿＿＿가 실제 이용자의 이해로 이어지는지 점검해야 합니다. (distractor: 알고리즘 편향) |
| cloze_c1_0247 | particle_mismatch | ＿＿＿가 있어도 제작 과정까지 자동으로 설명되지는 않습니다. (distractor: 알고리즘 편향, 설명 가능성, 인간 감독) |
| cloze_c1_0248 | particle_mismatch | ＿＿＿은 학습 데이터와 운영 기준을 함께 봐야 드러납니다. (distractor: 투명성 의무) |
| cloze_c1_0249 | josa_dup | 설명 가능성은 기술 문서의 길이가 아니라 이의 제기에 쓸 수 있는 정보로 평가해야 합니다. |
| cloze_c1_0249 | particle_mismatch | ＿＿＿은 기술 문서의 길이가 아니라 이의 제기에 쓸 수 있는 정보로 평가해야 합니다. (distractor: 투명성 의무, 합성 콘텐츠) |
| cloze_c1_0250 | particle_mismatch | ＿＿＿이 형식적인 확인 절차에 그치지 않도록 권한을 분명히 해야 합니다. (distractor: 투명성 의무, 합성 콘텐츠, 출처 표시) |
| cloze_c2_0053 | particle_mismatch | ＿＿＿이 어디에 있는지 묻자 웃음이 먼저 나왔어요. (distractor: 호칭의 정치, 권한의 출처) |
| cloze_c2_0054 | particle_mismatch | ＿＿＿은 거절보다 오래 남아서 기록을 남겼어요. (distractor: 말의 위계) |
| cloze_c2_0055 | particle_mismatch | ＿＿＿가 제 뜻을 바꾸길래 한 문장을 다시 말했어요. (distractor: 서사의 주인, 순응 연출, 의사결정권) |
| cloze_c2_0057 | particle_mismatch | ＿＿＿을 기대하는 자리에선 침묵이 칭찬이 됐어요. (distractor: 체면 경제) |
| cloze_c2_0058 | particle_mismatch | ＿＿＿를 혈연으로만 두면 외부인은 영원히 손님이에요. (distractor: 공동 기억) |
| cloze_c2_0059 | particle_mismatch | ＿＿＿를 깨지 않고도 질문을 하나 넣을 자리는 있었어요. (distractor: 말의 유산, 망각의 예절, 불복의 비용) |
| cloze_c2_0061 | particle_mismatch | ＿＿＿을 계산하니 그날은 기록만 남기기로 했어요. (distractor: 호명의 거부, 호칭의 정치) |
| cloze_c2_0062 | dangling_stem | 권력을 호명하니 방이 잠시 조용해졌다가 다시 숨이 돌아왔어요. (answer="권력을 호명하") |
| cloze_c2_0063 | dangling_stem | 기분이 아니라 절차를 요구하니 다음 결정이 투명해졌어요. (answer="절차를 요구하") |
| cloze_c2_0064 | dangling_stem | 자리를 문서화하자 기억 싸움이 줄었어요. (answer="자리를 문서화하") |
| cloze_c2_0065 | particle_mismatch | ＿＿＿이 누구에게는 친밀이고 누구에게는 무례였어요. (distractor: 권한의 출처, 기록 주체) |
| cloze_c2_0068 | particle_mismatch | ＿＿＿는 친근함의 가면을 쓰고 경계를 정했어요. (distractor: 순응 연출, 의사결정권, 이름 호명) |
| cloze_c2_0069 | particle_mismatch | ＿＿＿은 아픈 질문을 다시 하지 않는 일이었어요. (distractor: 기록 주체, 대리 발화) |
| cloze_c2_0070 | particle_mismatch | ＿＿＿가 누구인지에 따라 실수의 주인이 달라졌어요. (distractor: 망각의 예절, 불복의 비용, 서사의 주인) |
| cloze_c2_0071 | particle_mismatch | ＿＿＿를 무례가 아니라 자기 보호로 설명해 달라고 했어요. (distractor: 불복의 비용, 서사의 주인, 순응 연출) |
| cloze_c2_0072 | particle_mismatch | ＿＿＿을 한 장의 사진으로 고정하지 않기로 했어요. (distractor: 말의 위계) |
| cloze_c2_0073 | particle_mismatch | ＿＿＿이 다음 명절의 대본이 되지 않게 메모를 고쳤어요. (distractor: 권한의 출처, 기록 주체) |
| cloze_c2_0075 | dangling_stem | 기억을 재배치하자 내가 손님만은 아니게 됐어요. (answer="기억을 재배치하") |
| cloze_c2_0076 | dangling_stem | 서사를 공유하자 한 사람의 농담이 모두의 역사가 되지 않았어요. (answer="서사를 공유하") |
| cloze_c2_0077 | particle_mismatch | ＿＿＿를 드러내지 않으면 선택이 자연스러워 보여요. (distractor: 주어 선택) |
| cloze_c2_0078 | particle_mismatch | ＿＿＿가 '전쟁'이면 타협이 패배처럼 들려요. (distractor: 주어 선택) |
| cloze_c2_0079 | particle_mismatch | ＿＿＿을 바꾸면 책임이 다른 자리에 놓여요. (distractor: 담론 전제, 은유 체계, 수동 은폐) |
| cloze_c2_0080 | particle_mismatch | ＿＿＿는 행위자를 지워 절차만 남기어요. (distractor: 주어 선택) |
| cloze_c2_0082 | particle_mismatch | ＿＿＿을 한 주로 줄이면 구조 문제는 사라져요. (distractor: 담론 전제, 은유 체계) |
| cloze_c2_0083 | particle_mismatch | ＿＿＿을 '안전 대 자유'로만 두면 중간이 없어져요. (distractor: 담론 전제, 은유 체계) |
| cloze_c2_0084 | particle_mismatch | ＿＿＿가 직함만이면 근거를 다시 물어요. (distractor: 주어 선택) |
| cloze_c2_0085 | particle_mismatch | ＿＿＿을 표로 만들면 빠진 집단이 보여요. (distractor: 담론 전제, 은유 체계) |
| cloze_c2_0086 | particle_mismatch | ＿＿＿이 부담을 덜어 주면 누구의 부담인지 물어요. (distractor: 담론 전제, 은유 체계) |
| cloze_c2_0087 | particle_mismatch | ＿＿＿를 '우리'로 묶으면 반대가 외부인처럼 보여요. (distractor: 주어 선택) |
| cloze_c2_0088 | particle_mismatch | ＿＿＿을 하나로 닫지 않고 근거를 나란히 둬요. (distractor: 담론 전제, 은유 체계) |
| cloze_c2_0089 | particle_mismatch | ＿＿＿을 절차 뒤에 숨기지 않고 문장 앞에 둬요. (distractor: 공식 어조, 위임 범위, 기록 의무) |
| cloze_c2_0090 | particle_mismatch | ＿＿＿가 책임을 흐리면 평서문으로 다시 써요. (distractor: 제도적 권한) |
| cloze_c2_0091 | particle_mismatch | ＿＿＿를 넘는 결정을 관행으로 포장하지 않아요. (distractor: 제도적 권한) |
| cloze_c2_0092 | particle_mismatch | ＿＿＿가 약하면 나중에 기억을 고를 수 있어요. (distractor: 제도적 권한) |
| cloze_c2_0093 | particle_mismatch | ＿＿＿을 인정하되 기준표를 같이 공개해요. (distractor: 공식 어조, 위임 범위) |
| cloze_c2_0094 | particle_mismatch | ＿＿＿가 같은 부서면 독립이 아니에요. (distractor: 제도적 권한) |
| cloze_c2_0095 | particle_mismatch | ＿＿＿을 검수로만 설명하지 않고 날짜를 대요. (distractor: 공식 어조, 위임 범위) |
| cloze_c2_0096 | particle_mismatch | ＿＿＿은 근거가 아니라 습관의 이름이에요. (distractor: 공식 어조, 위임 범위) |
| cloze_c2_0097 | particle_mismatch | ＿＿＿이 심하면 서명란을 한 줄로 줄여요. (distractor: 공식 어조, 위임 범위) |
| cloze_c2_0098 | particle_mismatch | ＿＿＿이 대외 문구와 다르면 둘을 같이 보여요. (distractor: 공식 어조, 위임 범위) |
| cloze_c2_0100 | particle_mismatch | ＿＿＿이 사람 한 명에 있으면 퇴사와 함께 사라져요. (distractor: 공식 어조, 위임 범위) |
| cloze_c2_0101 | particle_mismatch | ＿＿＿을 바꾸면 같은 사건도 다른 도덕이 돼요. (distractor: 증언 위치) |
| cloze_c2_0102 | particle_mismatch | ＿＿＿을 기념일로만 고정하면 나머지가 지워져요. (distractor: 증언 위치) |
| cloze_c2_0103 | particle_mismatch | ＿＿＿를 무대 가장자리에 두면 목소리가 작아져요. (distractor: 서술 시점, 선택적 기억, 연대기 절단) |
| cloze_c2_0104 | particle_mismatch | ＿＿＿은 원인보다 결말만 남기어요. (distractor: 증언 위치) |
| cloze_c2_0105 | particle_mismatch | ＿＿＿을 하나로 모으면 소수 서사가 밀려나요. (distractor: 증언 위치) |
| cloze_c2_0106 | particle_mismatch | ＿＿＿를 존중하되 자료는 남기라고 해요. (distractor: 서술 시점, 선택적 기억) |
| cloze_c2_0107 | particle_mismatch | ＿＿＿이 현재 정책을 가리면 다시 써요. (distractor: 증언 위치) |
| cloze_c2_0108 | particle_mismatch | ＿＿＿을 없다고 메우지 않고 빈칸으로 표시해요. (distractor: 증언 위치) |
| cloze_c2_0109 | particle_mismatch | ＿＿＿을 줄이려고 당시 문장을 먼저 읽어요. (distractor: 증언 위치) |
| cloze_c2_0110 | particle_mismatch | ＿＿＿를 나란히 두면 승자 역사가 약해져요. (distractor: 서술 시점, 선택적 기억) |
| cloze_c2_0111 | particle_mismatch | ＿＿＿가 보존 예산 삭감으로 나타나면 이름을 붙여요. (distractor: 서술 시점, 선택적 기억) |
| cloze_c2_0112 | particle_mismatch | ＿＿＿을 후손에게만 미루지 않고 지금 기록해요. (distractor: 증언 위치) |
| cloze_c2_0113 | particle_mismatch | ＿＿＿는 이유를 빼면 반발이 커져요. (distractor: 전문 장벽, 전문가 위임) |
| cloze_c2_0115 | particle_mismatch | ＿＿＿는 대안의 존재를 먼저 지워요. (distractor: 전문 장벽, 전문가 위임) |
| cloze_c2_0116 | particle_mismatch | ＿＿＿이 정치 판단을 대신하면 책임을 물어요. (distractor: 명령형 공지, 불가피 수사) |
| cloze_c2_0117 | particle_mismatch | ＿＿＿을 '팀워크'로 부르지 않아요. (distractor: 명령형 공지, 불가피 수사) |
| cloze_c2_0121 | particle_mismatch | ＿＿＿을 선언하기 전에 철회 경로를 보여요. (distractor: 명령형 공지, 불가피 수사) |
| cloze_c2_0122 | particle_mismatch | ＿＿＿이 취향을 도덕으로 바꾸면 반박해요. (distractor: 명령형 공지, 불가피 수사) |
| cloze_c2_0123 | particle_mismatch | ＿＿＿를 회의에 적용하지 않고 명시 확인을 받아요. (distractor: 전문 장벽) |
| cloze_c2_0124 | particle_mismatch | ＿＿＿가 훈시이면 질문은 뒤로 밀려요. (distractor: 전문 장벽) |
| cloze_c2_0125 | particle_mismatch | ＿＿＿가 챗봇뿐이면 사람이 없는 것과 같아요. (distractor: 자동 결정, 인간 재심) |
| cloze_c2_0127 | particle_mismatch | ＿＿＿이 같은 점수를 다시 누르면 재심이 아니에요. (distractor: 이의 경로, 기한 안내) |
| cloze_c2_0128 | particle_mismatch | ＿＿＿를 거절 화면 하단에만 두지 않아요. (distractor: 자동 결정, 인간 재심) |
| cloze_c2_0129 | particle_mismatch | ＿＿＿이 글자 수만 받으면 사진 소명이 막혀요. (distractor: 이의 경로) |
| cloze_c2_0130 | particle_mismatch | ＿＿＿을 점수 없이 이유 세 줄로 적어요. (distractor: 이의 경로) |
| cloze_c2_0131 | particle_mismatch | ＿＿＿이 시간으로만 커도 포기는 강요예요. (distractor: 이의 경로) |
| cloze_c2_0133 | particle_mismatch | ＿＿＿를 같은 업체가 하면 독립이 아니에요. (distractor: 자동 결정, 인간 재심) |
| cloze_c2_0134 | particle_mismatch | ＿＿＿를 장래에만 두면 지난 피해가 남아요. (distractor: 자동 결정, 인간 재심) |
| cloze_c2_0135 | particle_mismatch | ＿＿＿가 법률문이면 이의 경로가 닫혀요. (distractor: 자동 결정, 인간 재심) |
| cloze_c2_0136 | particle_mismatch | ＿＿＿를 템플릿 한 줄로 끝내지 않아요. (distractor: 자동 결정, 인간 재심) |
| cloze_c2_0145 | particle_mismatch | ＿＿＿를 탐지하는 서명을 같이 설계해요. (distractor: 추적 가능성, 변경 이력, 접근 기록) |
| cloze_c2_0147 | particle_mismatch | ＿＿＿가 우편뿐이면 기한을 맞추기 어려워요. (distractor: 추적 가능성, 변경 이력, 접근 기록) |
| cloze_c2_0149 | particle_mismatch | ＿＿＿이 설정 깊숙이 있으면 사실상 없어요. (distractor: 동의 철회, 파생 데이터, 복원 금지) |
| cloze_c2_0152 | particle_mismatch | ＿＿＿를 백업 정책에 명시해야 철회가 완성돼요. (distractor: 철회권) |
| cloze_c2_0153 | particle_mismatch | ＿＿＿가 이의 기간에 자동으로 걸려야 해요. (distractor: 철회권) |
| cloze_c2_0154 | particle_mismatch | ＿＿＿가 수집 쪽이면 철회가 계속 싸움이 돼요. (distractor: 철회권) |
| cloze_c2_0155 | particle_mismatch | ＿＿＿을 가입 뒤로 미루면 동의가 형식만 남아요. (distractor: 동의 철회, 파생 데이터) |
| cloze_c2_0158 | particle_mismatch | ＿＿＿을 기능 잠금으로 하면 자유가 아니에요. (distractor: 동의 철회, 파생 데이터) |
| cloze_c2_0159 | particle_mismatch | ＿＿＿를 넓게 쓰면 철회권이 구멍 나요. (distractor: 철회권) |
| cloze_c2_0160 | particle_mismatch | ＿＿＿가 전화뿐이면 시간대에 따라 권리가 달라져요. (distractor: 철회권) |
| cloze_c2_0161 | particle_mismatch | ＿＿＿을 평균 정확도 뒤에 숨기지 않아요. (distractor: 대리 변수) |
| cloze_c2_0162 | particle_mismatch | ＿＿＿이 한쪽 집단에만 모이면 모델을 멈춰요. (distractor: 대리 변수) |
| cloze_c2_0164 | particle_mismatch | ＿＿＿가 주소를 쓰면 차별이 우회해요. (distractor: 차등 영향, 오류 비용, 피드백 왜곡) |
| cloze_c2_0167 | particle_mismatch | ＿＿＿가 쿠폰이면 권리를 값으로 바꾼 거예요. (distractor: 차등 영향, 오류 비용, 피드백 왜곡) |
| cloze_c2_0168 | particle_mismatch | ＿＿＿를 취약 지역부터 시작하면 실험이 전가돼요. (distractor: 차등 영향, 오류 비용, 피드백 왜곡) |
| cloze_c2_0171 | particle_mismatch | ＿＿＿를 버전 업으로 위장하지 않아요. (distractor: 차등 영향, 오류 비용, 피드백 왜곡) |
| cloze_c2_0177 | particle_mismatch | 같은 시스템이 ＿＿＿를 맡으면 형식에 불과합니다. (distractor: 소명, 시정) |
| cloze_c2_0178 | particle_mismatch | 결과 ＿＿＿는 3영업일 안에 서면으로 합니다. (distractor: 소명, 처분) |
| cloze_c2_0187 | particle_mismatch | 경미한 위반의 ＿＿＿을 중대한 위반과 같이 다룹니다. (distractor: 해제, 제재) |
| cloze_c2_0190 | particle_mismatch | 같은 행위에 다른 결과가 나오면 ＿＿＿이 깨집니다. (distractor: 비례, 해제) |
| cloze_c2_0192 | particle_mismatch | ＿＿＿을 낼 기한이 너무 짧습니다. (distractor: 제재, 해제) |
| cloze_c2_0196 | particle_mismatch | 운영자 ＿＿＿이 넓을수록 기준을 더 적어야 합니다. (distractor: 비례) |
| cloze_c2_0197 | particle_mismatch | 헤어진 뒤에는 ＿＿＿가 한쪽으로 정리됩니다. (distractor: 각색, 통념, 전형) |
| cloze_c2_0198 | particle_mismatch | 말할 때마다 조금씩 ＿＿＿이 더해집니다. (distractor: 미화) |
| cloze_c2_0199 | particle_mismatch | 지난 관계의 ＿＿＿는 다음 선택을 흐립니다. (distractor: 각색, 왜곡) |
| cloze_c2_0200 | particle_mismatch | ＿＿＿을 근거로 삼으면 예외가 보이지 않습니다. (distractor: 서사, 투사) |
| cloze_c2_0204 | particle_mismatch | 기억의 ＿＿＿은 감정 상태를 따라갑니다. (distractor: 투사) |
| cloze_c2_0205 | particle_mismatch | ＿＿＿가 누구인지에 따라 같은 장면이 달라집니다. (distractor: 전형, 개연성) |
| cloze_c2_0206 | particle_mismatch | 요약하는 과정에서 ＿＿＿이 자주 생깁니다. (distractor: 미화) |
| cloze_c2_0207 | particle_mismatch | 초반의 ＿＿＿가 나중 판단을 어렵게 합니다. (distractor: 전형) |
| cloze_c2_0208 | particle_mismatch | 한 장면만 보고 ＿＿＿을 내리기는 이릅니다. (distractor: 이상화) |
| cloze_c2_0209 | particle_mismatch | 팬덤 안의 ＿＿＿이 바깥 기준을 대신하기도 합니다. (distractor: 위계, 발화) |
| cloze_c2_0210 | particle_mismatch | 비판이 나오면 ＿＿＿이 먼저 일어납니다. (distractor: 배제, 동조, 우세) |
| cloze_c2_0211 | particle_mismatch | 다른 의견을 낸 사람의 ＿＿＿가 빠르게 이뤄집니다. (distractor: 낙인, 결집) |
| cloze_c2_0212 | particle_mismatch | 한 번 붙은 ＿＿＿은 설명으로 잘 지워지지 않습니다. (distractor: 배제, 잣대) |
| cloze_c2_0213 | particle_mismatch | 규모를 근거로 삼는 ＿＿＿는 오래가지 못합니다. (distractor: 호명, 결집) |
| cloze_c2_0215 | particle_mismatch | 반박이 없는 자리에서는 ＿＿＿가 의견처럼 보입니다. (distractor: 결집) |
| cloze_c2_0217 | particle_mismatch | 짧은 문장의 ＿＿＿를 두고 며칠씩 다툽니다. (distractor: 담론) |
| cloze_c2_0218 | particle_mismatch | 안팎에 다른 ＿＿＿를 대면 설득력이 사라집니다. (distractor: 낙인, 호명) |
| cloze_c2_0219 | particle_mismatch | 논점보다 특정 개인에 대한 ＿＿＿이 앞서기 시작하면 생산적인 대화가 어려워집니다. (distractor: 배제, 동조) |
| cloze_c2_0223 | josa_dup | 소득 구간별 부담의 분포를 공개해야 평균이 가리는 차이가 드러납니다. |
| cloze_c2_0223 | particle_mismatch | 소득 구간별 ＿＿＿를 공개해야 평균이 가리는 차이가 드러납니다. (distractor: 광고의 색상, 계약의 글꼴) |
| cloze_c2_0225 | particle_mismatch | 회사와 공급업체의 분업이 ＿＿＿이 되어서는 안 됩니다. (distractor: 광고의 효과, 면접의 순서) |
| cloze_c2_0226 | particle_mismatch | 사람의 검토자는 자동 결과를 ＿＿＿를 기록해야 합니다. (distractor: 공고의 제목) |
| cloze_c2_0234 | particle_mismatch | 주거 정책의 실패를 세입자에게 돌리는 ＿＿＿이 타당한지 따져야 합니다. (distractor: 숨은 전제, 이의 절차) |
| cloze_c2_0235 | particle_mismatch | 감당 가능한 집이라는 표현의 ＿＿＿는 가구마다 다를 수 있습니다. (distractor: 문화적 진정성) |
| cloze_c2_0236 | particle_mismatch | 보조 도구와 자동 결정의 ＿＿＿를 분명히 해야 책임도 나눌 수 있습니다. (distractor: 절차의 정당성, 대표성, 문지기 담론) |
| cloze_c2_0237 | particle_mismatch | 결과가 빨라도 설명과 이의 제기가 막혀 있으면 ＿＿＿이 약합니다. (distractor: 이의 절차) |
| cloze_c2_0238 | particle_mismatch | ＿＿＿가 형식적으로만 존재하는지 실제로 결정을 바꿀 수 있는지 확인해야 합니다. (distractor: 문화적 진정성, 담론 프레임) |
| cloze_c2_0239 | particle_mismatch | 사람을 빈자리를 채울 수단으로만 말하면 ＿＿＿가 일어납니다. (distractor: 대표성, 문지기 담론, 책임 귀속) |
| cloze_c2_0240 | particle_mismatch | 한 단체의 발언을 모든 이주민의 의견으로 읽기 전에 ＿＿＿을 물어야 합니다. (distractor: 숨은 전제) |
| cloze_c2_0241 | particle_mismatch | 난민과 유학생을 같은 정책 대상으로 묶는 ＿＿＿은 권리 차이를 지웁니다. (distractor: 정의의 경계) |
| cloze_c2_0243 | particle_mismatch | 누가 진짜 팬인지 가르는 ＿＿＿은 참여의 위계를 만듭니다. (distractor: 숨은 전제, 이의 절차) |
| cloze_c2_0244 | particle_mismatch | 추천과 수익 배분을 함께 통제하는 ＿＿＿은 문화 유통의 조건을 바꿉니다. (distractor: 정의의 경계, 인력의 도구화) |
| cloze_c2_0246 | particle_mismatch | ＿＿＿을 개인의 선택으로만 환원하면 돌봄과 고용 조건이 사라집니다. (distractor: 정책 효과) |
| cloze_c2_0247 | particle_mismatch | ＿＿＿은 비용뿐 아니라 결정권과 혜택의 시점도 포함합니다. (distractor: 정책 효과, 책임 주체) |
| cloze_c2_0248 | particle_mismatch | ＿＿＿를 말하려면 대상 집단과 비교 기준을 먼저 밝혀야 합니다. (distractor: 인과 추론) |
| cloze_c2_0249 | particle_mismatch | 두 지표가 함께 움직였다는 사실만으로 ＿＿＿을 확정할 수 없습니다. (distractor: 책임 주체, 인구 구조) |
| cloze_c2_0250 | particle_mismatch | 자동화가 개입해도 설계와 운영의 ＿＿＿를 분리해 기록해야 합니다. (distractor: 재생산 부담, 세대 간 형평성) |

## grammar.csv

0건 — 스캔했으나 후보 없음.

## korean_vocab.csv

10건.

| id | 마커 | 문장 |
|---|---|---|
| vocab_a1_0011 | josa_dup | 나이가 어떻게 되세요? |
| vocab_a1_0169 | formality_mix | 처음 뵙겠습니다. 잘 부탁드려요. |
| vocab_a1_0286 | josa_dup | 시누이가 옷걸이를 찾아 줬어요. |
| vocab_a1_0291 | josa_dup | 맏이가 자리 배치를 조용히 정했어요. |
| vocab_a1_0300 | formality_mix | 상을 물릴 때 잘 먹었습니다 하고 크게 인사했어요. |
| vocab_a2_0171 | josa_dup | 파란 넥타이가 잘 어울려요. |
| vocab_a2_0244 | josa_dup | 아이가 공주 그림을 그렸어요. |
| vocab_b1_0086 | josa_dup | 한국이랑 독일 문화 차이가 진짜 커요. |
| vocab_c1_0024 | josa_dup | 인터뷰 내용과 실제 이용 기록을 대조하니 기억과 행동 사이에 차이가 보였습니다. |
| vocab_c1_0233 | josa_dup | 설명 가능성은 기술 문서의 길이가 아니라 이의 제기에 쓸 수 있는 정보로 평가해야 합니다. |

## satz_sentences.json

10건.

| id | 마커 | 문장 |
|---|---|---|
| satz_a1_0002 | josa_dup | 나이가 몇 살이에요? |
| satz_a1_0138 | josa_dup | 시누이가 옷걸이를 찾아 줬어요. |
| satz_a1_0143 | josa_dup | 맏이가 자리 배치를 조용히 정했어요. |
| satz_a1_0152 | formality_mix | 상을 물릴 때 잘 먹었습니다 하고 크게 인사했어요. |
| satz_a1_0294 | formality_mix | 처음 뵙겠습니다. 잘 부탁드려요. |
| satz_a2_0362 | josa_dup | 파란 넥타이가 잘 어울려요. |
| satz_a2_0432 | josa_dup | 아이가 공주 그림을 그렸어요. |
| satz_b1_0042 | josa_dup | 두 나라의 차이가 커요. |
| satz_c1_0024 | josa_dup | 인터뷰 내용과 실제 이용 기록을 대조하니 기억과 행동 사이에 차이가 보였습니다. |
| satz_c2_0225 | josa_dup | 소득 구간별 부담의 분포를 공개해야 평균이 가리는 차이가 드러납니다. |

## scenarios_*.json

233건.

| id | 마커 | 문장 |
|---|---|---|
| a1_airport_cart#dialog[07] | formality_mix | 감사합니다. 수고하세요. |
| a1_card_topup#dialog[07] | formality_mix | 네, 알겠어요. 고맙습니다. |
| a1_city_service_route_batch20#dialog[00] | formality_mix | 실례합니다. 우체국은 어디에 있어요? |
| a1_city_service_route_batch20#quest_a1_city_service_route_batch20_hear.options[0].ko | formality_mix | 실례합니다. 우체국은 어디에 있어요? |
| a1_city_service_route_batch20#quest_a1_city_service_route_batch20_translate.options[0].ko | formality_mix | 실례합니다. 우체국은 어디에 있어요? |
| a1_class_pencil#dialog[07] | formality_mix | 감사합니다. 그럼 그렇게 부탁드려요. |
| a1_dust_mask#dialog[07] | formality_mix | 네, 알겠어요. 고맙습니다. |
| a1_excuse_pass#dialog[01] | formality_mix | 실례합니다. 지나갈게요. |
| a1_excuse_pass#dialog[07] | formality_mix | 네, 알겠어요. 고맙습니다. |
| a1_excuse_pass#quest_a1_excuse_pass_tr.options[0].ko | formality_mix | 실례합니다. 지나갈게요. |
| a1_gate_code#dialog[04] | formality_mix | 알겠습니다. 그렇게 하세요. |
| a1_gate_code#dialog[07] | formality_mix | 네, 알겠어요. 고맙습니다. |
| a1_hall_shoes#dialog[04] | formality_mix | 알겠습니다. 바로 그렇게 할게요. |
| a1_hotel_key#dialog[07] | formality_mix | 감사합니다. 그럼 그렇게 부탁드려요. |
| a1_last_train#dialog[07] | formality_mix | 네, 알겠어요. 고맙습니다. |
| a1_market_bag#dialog[07] | formality_mix | 네, 알겠어요. 고맙습니다. |
| a1_neighbor_box#dialog[07] | formality_mix | 감사합니다. 그럼 그렇게 부탁드려요. |
| a1_numbers_floor_and_room#dialog[06] | formality_mix | 아, 여기 있네요. 고맙습니다. |
| a1_numbers_total_price#dialog[05] | formality_mix | 삼천 원이요. 여기 있습니다. |
| a1_numbers_total_price#dialog[06] | formality_mix | 네, 삼천 원 받았어요. 감사합니다. |
| a1_numbers_total_price#quest_a1_numbers_total_price_hear.audioKo | formality_mix | 삼천 원이요. 여기 있습니다. |
| a1_office_print#dialog[07] | formality_mix | 감사합니다. 수고하세요. |
| a1_parcel_weight#dialog[07] | formality_mix | 감사합니다. 수고하세요. |
| a1_partner_first_door#dialog[00] | formality_mix | 안녕하세요. 처음 뵙겠습니다. 현우의 친구입니다. |
| a1_partner_first_door#quest_a1_partner_first_door_translate.options[0].ko | formality_mix | 안녕하세요. 처음 뵙겠습니다. 현우의 친구입니다. |
| a1_partner_new_year_money#quest_a1_partner_new_year_money_translate.options[2].ko | formality_mix | 안녕하세요. 처음 뵙겠습니다. 현우의 친구입니다. |
| a1_partner_seollal_bow#dialog[04] | formality_mix | 맛있어요. 감사합니다. |
| a1_pharmacy_hours#dialog[07] | formality_mix | 네, 그렇게 할게요. 감사합니다. |
| a1_phone_read_back_address#dialog[06] | formality_mix | 알겠습니다. 십 분 안에 도착해요. |
| a1_phone_read_back_address#dialog[07] | formality_mix | 감사합니다. 기다릴게요. |
| a1_phone_text_instead#dialog[05] | formality_mix | 아, 감사합니다. 지금 들어가요. |
| a1_phone_wrong_number#dialog[04] | formality_mix | 아, 제가 잘못 걸었네요. 죄송합니다. |
| a1_phone_wrong_number#dialog[06] | formality_mix | 다시 걸어 볼게요. 감사합니다. |
| a1_phone_wrong_number#quest_a1_phone_wrong_number_hear.audioKo | formality_mix | 아, 제가 잘못 걸었네요. 죄송합니다. |
| a1_post_queue#dialog[07] | formality_mix | 감사합니다. 수고하세요. |
| a1_rice_shop#dialog[04] | formality_mix | 알겠습니다. 잠시만 기다려 주세요. |
| a1_slow_speech#dialog[07] | formality_mix | 감사합니다. 그럼 그렇게 부탁드려요. |
| a1_stamp_ask#dialog[07] | formality_mix | 네, 그렇게 할게요. 감사합니다. |
| a1_station_rest#dialog[07] | formality_mix | 네, 그렇게 할게요. 감사합니다. |
| a1_subway_exit#dialog[07] | formality_mix | 감사합니다. 그럼 그렇게 부탁드려요. |
| a1_taxi_address#dialog[07] | formality_mix | 네, 그렇게 할게요. 감사합니다. |
| a1_thanks_seat#dialog[07] | formality_mix | 네, 그렇게 할게요. 감사합니다. |
| a1_trash_sort#dialog[04] | formality_mix | 알겠습니다. 그렇게 하세요. |
| a1_trash_sort#dialog[07] | formality_mix | 네, 알겠어요. 고맙습니다. |
| a1_water_shop#dialog[04] | formality_mix | 알겠습니다. 잠시만 기다려 주세요. |
| a1_water_shop#dialog[07] | formality_mix | 감사합니다. 그럼 그렇게 부탁드려요. |
| a1_wayfinding_sign_says#dialog[06] | formality_mix | 고맙습니다. 표지판을 못 봤어요. |
| a1_wayfinding_this_way_right#dialog[00] | formality_mix | 실례합니다. 우체국이 이쪽이 맞아요? |
| a1_youtube_shorts_last_night#dialog[02] | josa_dup | 고양이가 냉장고를 열었어. |
| a1_youtube_shorts_last_night#quest_a1_youtube_shorts_last_night_hear.audioKo | josa_dup | 고양이가 냉장고를 열었어. |
| a1_youtube_shorts_last_night#quest_a1_youtube_shorts_last_night_particle.particlePop | josa_dup | 고양이가 냉장고를 열었어. |
| a2_airport_sim#dialog[07] | formality_mix | 감사합니다. 수고하세요. |
| a2_bank_number#dialog[07] | formality_mix | 네, 알겠어요. 고맙습니다. |
| a2_booth_line#dialog[07] | formality_mix | 감사합니다. 그럼 그렇게 부탁드려요. |
| a2_cafe_plug#dialog[07] | formality_mix | 네, 알겠어요. 고맙습니다. |
| a2_card_balance#dialog[07] | formality_mix | 감사합니다. 그럼 그렇게 부탁드려요. |
| a2_convenience_copy#dialog[04] | formality_mix | 알겠습니다. 잠시만 기다려 주세요. |
| a2_convenience_copy#dialog[07] | formality_mix | 감사합니다. 수고하세요. |
| a2_dye_dark#dialog[04] | formality_mix | 알겠습니다. 잠시만 기다려 주세요. |
| a2_food_bag#dialog[04] | formality_mix | 알겠습니다. 그렇게 하세요. |
| a2_found_umbrella#dialog[04] | formality_mix | 알겠습니다. 잠시만 기다려 주세요. |
| a2_found_umbrella#dialog[07] | formality_mix | 감사합니다. 수고하세요. |
| a2_front_desk#dialog[07] | formality_mix | 감사합니다. 그럼 그렇게 부탁드려요. |
| a2_gaming_cant_connect#quest_a2_gaming_cant_connect_tr.options[3].ko | josa_dup | 와이파이가 아예 안 돼. |
| a2_hair_time#dialog[07] | formality_mix | 네, 알겠어요. 고맙습니다. |
| a2_handover_note#dialog[07] | formality_mix | 네, 그렇게 할게요. 감사합니다. |
| a2_id_pickup#dialog[07] | formality_mix | 네, 알겠어요. 고맙습니다. |
| a2_kpop_concert_queue#dialog[04] | formality_mix | 고맙습니다. 공연은 몇 시에 들어가나요? |
| a2_label_phone#dialog[07] | formality_mix | 감사합니다. 수고하세요. |
| a2_market_change#dialog[07] | formality_mix | 감사합니다. 그럼 그렇게 부탁드려요. |
| a2_night_pay#dialog[07] | formality_mix | 감사합니다. 그럼 그렇게 부탁드려요. |
| a2_office_badge#dialog[07] | formality_mix | 네, 그렇게 할게요. 감사합니다. |
| a2_phone_plan#dialog[07] | formality_mix | 네, 알겠어요. 고맙습니다. |
| a2_quiet_ten#dialog[07] | formality_mix | 네, 그렇게 할게요. 감사합니다. |
| a2_recycle_box#dialog[07] | formality_mix | 감사합니다. 그럼 그렇게 부탁드려요. |
| a2_restaurant_split#dialog[07] | formality_mix | 네, 그렇게 할게요. 감사합니다. |
| a2_salon_cut#dialog[07] | formality_mix | 네, 그렇게 할게요. 감사합니다. |
| a2_shift_table#dialog[07] | formality_mix | 감사합니다. 수고하세요. |
| a2_taxi_wait#dialog[07] | formality_mix | 네, 알겠어요. 고맙습니다. |
| a2_volunteer_vest#dialog[07] | formality_mix | 감사합니다. 수고하세요. |
| airport_arrival#quest_airport_arrival_04.audioKo | formality_mix | 안녕하세요. 처음 뵙겠습니다. |
| airport_arrival#quest_airport_arrival_04.targetKo | formality_mix | 안녕하세요. 처음 뵙겠습니다. |
| b1_bill_split#dialog[07] | formality_mix | 네, 그렇게 할게요. 감사합니다. |
| b1_cafe_invoice#dialog[04] | formality_mix | 알겠습니다. 잠시만 기다려 주세요. |
| b1_case_status#dialog[04] | formality_mix | 알겠습니다. 잠시만 기다려 주세요. |
| b1_civil_ticket#dialog[07] | formality_mix | 네, 그렇게 할게요. 감사합니다. |
| b1_claim_same_day#dialog[07] | formality_mix | 네, 그렇게 할게요. 감사합니다. |
| b1_connecting#dialog[07] | formality_mix | 네, 그렇게 할게요. 감사합니다. |
| b1_contract_appointment#dialog[01] | formality_mix | 네, 맞습니다. 부동산 사무실에서 기다리고 있을게요. |
| b1_contract_appointment#dialog[03] | formality_mix | 미리 확인해 주셔서 좋습니다. 계약서 초안은 읽어 보셨어요? |
| b1_covering_absence#dialog[02] | formality_mix | 감사합니다. 업무 분담은 오늘 오후에 다시 정할까요? |
| b1_extra_paper#dialog[07] | formality_mix | 감사합니다. 그럼 그렇게 부탁드려요. |
| b1_followup_mail#dialog[07] | formality_mix | 네, 알겠어요. 고맙습니다. |
| b1_friends_he_said_that#dialog[00] | josa_dup | 어제 수진이가 너 화났다고 했는데, 진짜야? |
| b1_guest_notice#dialog[07] | formality_mix | 감사합니다. 수고하세요. |
| b1_heating_safety_call#dialog[04] | formality_mix | 알겠습니다. 문제가 있으면 수리비가 생기기 전에 먼저 알려 드릴게요. |
| b1_incident_lost_item_desk#quest_b1_incident_lost_item_desk_tr.options[1].ko | josa_dup | 갈색 가방이고 손잡이가 길어요. |
| b1_incident_lost_item_desk#quest_b1_incident_lost_item_desk_tr.options[3].ko | josa_dup | 파란 우산이고 손잡이가 굽었어요. |
| b1_intranet_form#dialog[07] | formality_mix | 네, 그렇게 할게요. 감사합니다. |
| b1_job_offer_conditions_batch20#dialog[05] | formality_mix | 팀 일정과 맞으면 가능합니다. 가능한 시간을 보내 주세요. |
| b1_kpop_missing_goods#dialog[05] | formality_mix | 재발송하면 배송비는 저희가 냅니다. 3일 걸려요. |
| b1_laundry_turn#dialog[07] | formality_mix | 감사합니다. 수고하세요. |
| b1_leak_report#dialog[01] | formality_mix | 불편을 드려 죄송합니다. 물이 많이 새는 편인가요? |
| b1_leak_report#quest[00].audioKo | formality_mix | 불편을 드려 죄송합니다. 물이 많이 새는 편인가요? |
| b1_mail_cc#dialog[07] | formality_mix | 네, 알겠어요. 고맙습니다. |
| b1_market_claim#dialog[07] | formality_mix | 감사합니다. 그럼 그렇게 부탁드려요. |
| b1_move_in_handover#dialog[03] | formality_mix | 좋습니다. 엘리베이터 사용 시간도 예약해 놓았어요. |
| b1_move_in_handover#dialog[05] | formality_mix | 네, 확인해 두었습니다. 문제가 있으면 입주 후 사흘 안에 알려 주세요. |
| b1_move_in_handover#quest[00].audioKo | formality_mix | 좋습니다. 엘리베이터 사용 시간도 예약해 놓았어요. |
| b1_partner_salary_deflect#quest_b1_partner_salary_deflect_translate.options[0].ko | formality_mix | 안녕하세요. 처음 뵙겠습니다. 현우의 친구입니다. |
| b1_pickup_delay#dialog[07] | formality_mix | 네, 그렇게 할게요. 감사합니다. |
| b1_proxy_form#dialog[07] | formality_mix | 감사합니다. 수고하세요. |
| b1_quote_change#dialog[04] | formality_mix | 알겠습니다. 잠시만 기다려 주세요. |
| b1_refund_rule#dialog[04] | formality_mix | 알겠습니다. 잠시만 기다려 주세요. |
| b1_refund_rule#dialog[07] | formality_mix | 감사합니다. 그럼 그렇게 부탁드려요. |
| b1_repair_photo#dialog[07] | formality_mix | 네, 그렇게 할게요. 감사합니다. |
| b1_reschedule_request#dialog[04] | formality_mix | 협조해 주시면 정말 감사하겠습니다. 회의실도 변경이 가능한지 부탁드려요. |
| b1_reschedule_request#dialog[05] | formality_mix | 알겠습니다. 확정되는 대로 새 일정을 보내 드릴게요. |
| b1_safety_vest#dialog[07] | formality_mix | 감사합니다. 그럼 그렇게 부탁드려요. |
| b1_taxi_receipt#dialog[07] | formality_mix | 감사합니다. 그럼 그렇게 부탁드려요. |
| b1_volunteer_gap#dialog[07] | formality_mix | 감사합니다. 수고하세요. |
| b1_waitlist#dialog[07] | formality_mix | 감사합니다. 수고하세요. |
| b1_work_deadline_soft_request#dialog[07] | formality_mix | 알겠습니다. 위험이 생기면 오늘 안에 다시 공유해 주세요. |
| b2_airport_reseat#dialog[07] | formality_mix | 감사합니다. 그럼 그렇게 부탁드려요. |
| b2_assumption#dialog[07] | formality_mix | 네, 알겠어요. 고맙습니다. |
| b2_case_id#dialog[07] | formality_mix | 감사합니다. 수고하세요. |
| b2_chart_axes#dialog[07] | formality_mix | 감사합니다. 그럼 그렇게 부탁드려요. |
| b2_convenience_scan#dialog[07] | formality_mix | 네, 그렇게 할게요. 감사합니다. |
| b2_counter_offer#dialog[07] | formality_mix | 네, 그렇게 할게요. 감사합니다. |
| b2_cross_check#dialog[07] | formality_mix | 네, 그렇게 할게요. 감사합니다. |
| b2_daily_upstairs_noise#dialog[01] | formality_mix | 위층에 안내문을 붙였습니다. 시간대가 언제였나요? |
| b2_direction_risk#dialog[07] | formality_mix | 네, 알겠어요. 고맙습니다. |
| b2_market_source#dialog[07] | formality_mix | 감사합니다. 수고하세요. |
| b2_metric_clear#dialog[07] | formality_mix | 감사합니다. 수고하세요. |
| b2_next_level#dialog[07] | formality_mix | 감사합니다. 수고하세요. |
| b2_on_site#dialog[07] | formality_mix | 네, 알겠어요. 고맙습니다. |
| b2_one_pager#dialog[07] | formality_mix | 감사합니다. 그럼 그렇게 부탁드려요. |
| b2_pharmacy_claim#dialog[04] | formality_mix | 알겠습니다. 잠시만 기다려 주세요. |
| b2_pharmacy_claim#dialog[07] | formality_mix | 감사합니다. 그럼 그렇게 부탁드려요. |
| b2_privacy_data_scope#dialog[05] | formality_mix | 처리했습니다. 이미 입력된 값은 어떻게 할까요? |
| b2_public_question#dialog[07] | formality_mix | 감사합니다. 그럼 그렇게 부탁드려요. |
| b2_quorum_wait#dialog[07] | formality_mix | 네, 그렇게 할게요. 감사합니다. |
| b2_read_receipt#dialog[07] | formality_mix | 네, 그렇게 할게요. 감사합니다. |
| b2_restaurant_note#dialog[04] | formality_mix | 알겠습니다. 잠시만 기다려 주세요. |
| b2_restaurant_note#dialog[07] | formality_mix | 감사합니다. 수고하세요. |
| b2_restore_scope#dialog[07] | formality_mix | 네, 그렇게 할게요. 감사합니다. |
| b2_selective_edit#dialog[01] | formality_mix | 앞부분만 보여 주면 오해가 납니다. 전체를 써야 해요. |
| b2_selective_edit#quest_b2_selective_edit_tr.options[0].ko | formality_mix | 앞부분만 보여 주면 오해가 납니다. 전체를 써야 해요. |
| b2_self_fail#dialog[07] | formality_mix | 네, 알겠어요. 고맙습니다. |
| b2_source_check#dialog[07] | formality_mix | 감사합니다. 그럼 그렇게 부탁드려요. |
| b2_station_hold#dialog[07] | formality_mix | 감사합니다. 수고하세요. |
| b2_time_box#dialog[07] | formality_mix | 네, 알겠어요. 고맙습니다. |
| b2_youtube_collab_pitch#dialog[00] | formality_mix | 안녕하세요. 채널 협업을 제안하고자 연락드렸습니다. |
| b2_youtube_collab_pitch#dialog[01] | formality_mix | 반갑습니다. 어떤 형태를 생각하고 계신가요? |
| bunshik_tteokbokki#dialog[04] | formality_mix | 네, 알겠습니다. 음료는요? |
| business_meeting_intro#dialog[00] | formality_mix | 어서 오세요. 먼 길 오셨네요. 저는 김은수라고 합니다. 프로젝트 총괄 담당입니다. |
| business_meeting_intro#dialog[01] | formality_mix | 처음 뵙겠습니다. 명함 드려도 될까요? |
| business_meeting_intro#dialog[02] | formality_mix | 감사합니다. 저도 드릴게요. 어떤 분야를 담당하고 계세요? |
| business_meeting_intro#dialog[04] | formality_mix | 좋습니다. 이번 프로젝트 제안서 검토해 보셨나요? |
| business_meeting_intro#dialog[05] | formality_mix | 네, 읽어봤습니다. 몇 가지 말씀드리고 싶은 부분이 있는데, 괜찮으시면 일정을 잡아서 다시 이야기해도 될까요? |
| business_meeting_intro#dialog[06] | formality_mix | 물론이죠. 오늘은 인사 나누는 자리니까요. 앞으로 잘 부탁드립니다. |
| business_meeting_intro#quest_business_meeting_intro_04.options[2].ko | formality_mix | 김레나라고 해요. 해외 마케팅 계획을 이미 출시했습니다. |
| c1_attribution_reuse_without_credit#quest_c1_attribution_reuse_without_credit_tr.options[1].ko | formality_mix | 공개 자료는 출처가 필요 없습니다. |
| c1_briefing_number#dialog[07] | formality_mix | 감사합니다. 수고하세요. |
| c1_clinical_informed_consent#dialog[07] | formality_mix | 언제든 됩니다. 그 문장도 같이 보여 드릴게요. |
| c1_clinical_second_opinion#dialog[01] | formality_mix | 괜찮습니다. 편하게 말씀하세요. |
| c1_clinical_second_opinion#dialog[07] | formality_mix | 그게 서로 편합니다. 일정만 알려 주세요. |
| c1_leading_item#dialog[07] | formality_mix | 감사합니다. 그럼 그렇게 부탁드려요. |
| c1_mediation_restate_position#dialog[03] | formality_mix | 시점이요? 그건 몰랐습니다. |
| c1_question_window#dialog[07] | formality_mix | 네, 알겠어요. 고맙습니다. |
| c1_relative_risk#dialog[07] | formality_mix | 감사합니다. 수고하세요. |
| c1_speaking_slot#dialog[07] | formality_mix | 네, 알겠어요. 고맙습니다. |
| c1_survey_limits_briefing#dialog[00] | formality_mix | 주민 설문 결과가 나왔습니다. 바로 확대 사업안을 발표해도 될까요? |
| c1_youtube_health_claims#dialog[03] | formality_mix | 아니요. 효과가 없다고 단정할 여지도 없습니다. 자료가 부족하다고 써야 합니다. |
| c2_appeal_bot#dialog[07] | formality_mix | 감사합니다. 수고하세요. |
| c2_archive_gap#dialog[01] | formality_mix | 삼 월 기록이 없습니다. 있다고 채우지 말고 공백이라고 쓰세요. |
| c2_archive_gap#quest_c2_archive_gap_tr.options[0].ko | formality_mix | 삼 월 기록이 없습니다. 있다고 채우지 말고 공백이라고 쓰세요. |
| c2_jurisdiction_provisional_ruling_no_authority#dialog[02] | formality_mix | 아니요. 통지서만 보고 그대로 따랐습니다. |
| c2_mandate_edge#dialog[01] | formality_mix | 가격을 정하는 일은 제 위임 밖이에요. 위로 가야 합니다. |
| c2_mandate_edge#dialog[07] | formality_mix | 네, 그렇게 할게요. 감사합니다. |
| c2_mandate_edge#quest_c2_mandate_edge_tr.options[0].ko | formality_mix | 가격을 정하는 일은 제 위임 밖이에요. 위로 가야 합니다. |
| c2_moving_affordability_definition_hearing#quest_c2_moving_affordability_definition_hearing_dict.audioKo | josa_dup | 소득 구간별 부담의 분포를 공개해야 평균이 가리는 차이가 드러납니다. |
| c2_moving_affordability_definition_hearing#quest_c2_moving_affordability_definition_hearing_dict.targetKo | josa_dup | 소득 구간별 부담의 분포를 공개해야 평균이 가리는 차이가 드러납니다. |
| c2_passive_hide#dialog[07] | formality_mix | 네, 알겠어요. 고맙습니다. |
| c2_representation_press_quote_not_official#dialog[01] | formality_mix | 저도 봤습니다. 인용 표시도 없더군요. |
| c2_trace_log#dialog[07] | formality_mix | 네, 알겠어요. 고맙습니다. |
| c2_withdraw_deep#dialog[07] | formality_mix | 감사합니다. 수고하세요. |
| cafe_starbucks_basic#dialog[04] | formality_mix | 4,500원입니다. 카드로 결제하시겠어요? |
| cafe_starbucks_basic#quest_cafe_starbucks_basic_05.options[0].ko | formality_mix | 주문 도와드리겠습니다. / 주문 도와드릴게요. |
| cafe_starbucks_basic#quest_cafe_starbucks_basic_05.options[1].ko | formality_mix | 주문 도와드릴게요. / 주문 도와드리겠습니다. |
| clinic_safety#quest_clinic_safety_06.options[0].ko | level_length | 열이 있고 머리가 많이 아파요. 도움이 필요해요. 의사 선생님을 불러 주세요. |
| company_dinner_hoeshik#dialog[03] | formality_mix | 다음에 꼭 갈게요. 오늘 정말 잘 먹었습니다. |
| complaint_delivery#dialog[00] | formality_mix | 안녕하세요, 고객센터입니다. 어떻게 도와드릴까요? |
| complaint_delivery#dialog[02] | formality_mix | 불편을 드려서 정말 죄송합니다. 주문 번호 확인해 드려도 될까요? |
| complaint_delivery#dialog[04] | formality_mix | 죄송합니다. 확인해 보니 포장 과정에서 오류가 있었네요. 교환과 환불 중 어떻게 해드릴까요? |
| complaint_delivery#dialog[06] | formality_mix | 영업일 기준 2~3일 안에 처리해 드리겠습니다. 지금 바로 접수해 드릴게요. |
| complaint_delivery#quest_complaint_delivery_04.options[3].ko | formality_mix | 상품이 늦었지만 교환은 필요 없습니다. 수거해 주십시오. |
| delivery_address_confirmation#dialog[00] | formality_mix | 안녕하세요. 배달 기사입니다. 주소가 서울시 마포구 성산로 15, 302호 맞으세요? |
| delivery_address_confirmation#dialog[00] | level_length | 안녕하세요. 배달 기사입니다. 주소가 서울시 마포구 성산로 15, 302호 맞으세요? |
| delivery_address_confirmation#dialog[05] | formality_mix | 네, 메시지 확인할게요. 감사합니다. |
| first_class_meeting#dialog[01] | formality_mix | 네, 처음이에요. 저는 레나입니다. |
| first_class_meeting#quest_first_class_meeting_06.options[0].ko | formality_mix | 저는 레나입니다. 한국어 수업 처음이세요? |
| first_class_meeting#quest_first_class_meeting_06.options[3].ko | formality_mix | 레나 씨입니다. 한국어를 가르치세요? |
| food_delivery#dialog[01] | formality_mix | 죄송합니다. 주문 번호를 알려 주시겠어요? |
| food_delivery#quest_food_delivery_01.audioKo | formality_mix | 콜라가 누락됐네요. 바로 보내 드리겠습니다. |
| introduce_yourself#dialog[00] | formality_mix | 안녕하세요. 처음 뵙겠습니다. |
| introduce_yourself#dialog[05] | formality_mix | 저도요. 잘 부탁드립니다. |
| introduce_yourself#quest_introduce_yourself_06.options[0].ko | formality_mix | 연락처를 보내겠습니다. / 연락처를 보낼게요. / 연락처 보낼게. |
| introduce_yourself#quest_introduce_yourself_06.options[1].ko | formality_mix | 연락처를 보낼게요. / 연락처를 보내겠습니다. / 연락처 보낼게. |
| introduce_yourself#quest_introduce_yourself_06.options[2].ko | formality_mix | 연락처 보낼게. / 연락처를 보낼게요. / 연락처를 보내겠습니다. |
| introduce_yourself#quest_introduce_yourself_07.options[0].ko | formality_mix | 저는 레나입니다. / 저는 레나예요. / 나는 레나야. |
| introduce_yourself#quest_introduce_yourself_07.options[1].ko | formality_mix | 저는 레나예요. / 나는 레나야. / 저는 레나입니다. |
| introduce_yourself#quest_introduce_yourself_07.options[2].ko | formality_mix | 나는 레나야. / 저는 레나입니다. / 저는 레나예요. |
| job_interview#quest_job_interview_05.options[0].ko | formality_mix | 검토 시간을 연장해 주시기 바랍니다. / 가능하시다면 검토 시간을 조금 더 주실 수 있을까요? |
| job_interview#quest_job_interview_05.options[1].ko | formality_mix | 검토 시간을 조금 더 주실 수 있을까요? / 검토 시간을 연장해 주시기 바랍니다. |
| job_interview#quest_job_interview_05.options[2].ko | formality_mix | 검토 시간을 연장하겠습니다. / 가능하면 검토를 취소해 주세요. |
| ktx_ticket#dialog[05] | formality_mix | 열 시 출발입니다. 좋은 여행 되세요. |
| myeongdong_shopping#dialog[01] | formality_mix | 그냥 보는 거예요. 감사합니다. |
| phone_messenger_reply#dialog[01] | level_length | 안녕하세요, 현우 씨. 반가워요. 제 전화번호는 010-3764-8291이에요. |
| phone_messenger_reply#dialog[02] | formality_mix | 감사합니다. 카카오톡으로 수업 자료 보내 드릴게요. |
| phone_messenger_reply#dialog[03] | formality_mix | 네, 감사합니다. 제 주소는 서울시 마포구 성산로 15예요. |
| phone_messenger_reply#quest_phone_messenger_reply_06.options[0].ko | level_length | 제 전화번호는 010-3764-8291이고 주소는 성산로 15, 302호예요. 천천히 확인해 주세요. |
| plans_with_friend#quest_plans_with_friend_04.options[3].ko | formality_mix | 같이 식사합시다. / 같이 식사해. / 같이 먹을까요? / 같이 먹겠습니다. |
| survival_day_capstone#dialog[01] | formality_mix | 안녕하세요. 저는 레나입니다. |
| survival_day_capstone#quest_survival_day_capstone_01.audioKo | formality_mix | 안녕하세요. 저는 레나입니다. |
| survival_day_capstone#quest_survival_day_capstone_05.options[0].ko | formality_mix | 안녕하세요. 저는 레나입니다. / 떡볶이 한 인분 주세요. / 지하철역에 어떻게 가요? / 잘 못 알아들었어요. 천천히 다시 말씀해 주세요. |
| survival_day_capstone#quest_survival_day_capstone_05.options[0].ko | level_length | 안녕하세요. 저는 레나입니다. / 떡볶이 한 인분 주세요. / 지하철역에 어떻게 가요? / 잘 못 알아들었어요. 천천히 다시 말씀해 주세요. |
| survival_day_capstone#quest_survival_day_capstone_05.options[1].ko | level_length | 안녕. 나는 레나야. / 떡볶이 먹자. / 지하철역에 가. / 빨리 말해 줘. |
| survival_day_capstone#quest_survival_day_capstone_05.options[2].ko | level_length | 저는 레나예요. / 주문하지 않을게요. / 택시를 탔어요. / 잘 알아들었어요. |
| survival_day_capstone#quest_survival_day_capstone_05.options[3].ko | formality_mix | 처음 뵙겠습니다. / 계산했어요. / 길을 알아요. / 다시 말하지 마세요. |
| survival_day_capstone#quest_survival_day_capstone_05.options[3].ko | level_length | 처음 뵙겠습니다. / 계산했어요. / 길을 알아요. / 다시 말하지 마세요. |
| titles_relationship_distance#dialog[00] | formality_mix | 안녕하세요. 저는 레나입니다. |
| titles_relationship_distance#dialog[05] | formality_mix | 네, 저도 반갑습니다. 다음에 봬요. |

## silben_puzzles.json

3건.

| id | 마커 | 문장 |
|---|---|---|
| skz_a2_006#v00 | josa_dup | 아이가 공주 그림을 그렸어요. |
| skz_a2_019#h20 | josa_dup | 파란 넥타이가 잘 어울려요. |
| skz_b1_006#h21 | josa_dup | 한국이랑 독일 문화 차이가 진짜 커요. |

## smalltalk.json

6건.

| id | 마커 | 문장 |
|---|---|---|
| smalltalk_b1_0043#followUp | formality_mix | 알겠습니다. 바로 가 볼게요. |
| smalltalk_b1_0045#followUp | formality_mix | 확인해 주셔서 감사합니다. 일정에 반영할게요. |
| smalltalk_b1_0051#followUp | formality_mix | 감사합니다. 인원을 확정하는 데 도움이 될 거예요. |
| smalltalk_b2_0095 | josa_dup | 선을 긋고도 사이가 나빠지지 않으려면 어떻게 말해야 할까요? |
| smalltalk_b2_0115#reply | formality_mix | 수요 변화와 규제, 지역별 소득도 함께 검토해야 합니다. |
| smalltalk_c1_0063#reply | josa_dup | 평균 하나로는 긴급도와 지역 차이가 가려져요. |

## 요약

- 총 후보: **1122건** (대상 파일 7개 전부 스캔, 후보 있는 파일 6개)

### 파일별 건수

- cloze.json: 860건
- grammar.csv: 0건
- korean_vocab.csv: 10건
- satz_sentences.json: 10건
- scenarios_*.json: 233건
- silben_puzzles.json: 3건
- smalltalk.json: 6건

### 마커별 건수

- dangling_stem: 16건
- particle_mismatch: 835건
- passive_pileup: 0건
- e_daehae: 0건
- josa_dup: 37건
- formality_mix: 226건
- level_length: 8건
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
  **다만 이 항목은 이번 스캔에서 별도로 여전히 살아있는 결함 1건이 새로
  잡혔다**: distractor `방문 순서`(받침 없는 "서"로 끝남)가 빈칸 뒤 조사
  `이`(받침 필요)와 불합치 — Task 2 는 이 세 distractor 를 "형태 가능·
  문맥 불가 충족"으로 판단해 그대로 뒀지만 받침 정합은 별도로 검토되지
  않았다. 즉 이 마커는 "교정 전" 회고용일 뿐 아니라 **Task 2 가 놓친
  현재진행형 결함**도 실제로 찾아냈다 — 아래 cloze.json 섹션의
  `cloze_b1_0172 | particle_mismatch` 행 참고.

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
  않는 단순 문자열 매칭이라, 실측 36건 후보 중 상당수가 이 유형이다.
  의도적으로 필터링하지 않았다(정밀도를 높이려 예외 사전을
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

