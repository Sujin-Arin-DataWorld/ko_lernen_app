# 콘텐츠 자연성 프리필터 후보 리포트

`python tool/audit_content_naturalness.py` 로 생성 — 직접 편집 금지, 스크립트 재실행으로 갱신한다.

마커는 전부 결정적 규칙(정규식/문자열 포함/받침 유무) 기반이다. 여기 실리는 항목은 "후보"이며, 실제 어색함 여부는 Task 12 의 사람/LLM 심사가 판단한다.

## cloze.json

311건.

| id | 마커 | 문장 |
|---|---|---|
| cloze_a1_0003 | josa_dup | 나이가 몇 살이에요? |
| cloze_a1_0077 | formality_mix | 실례합니다 잠깐만요. |
| cloze_a1_0114 | particle_mismatch | ＿＿＿은 부담이 된다고 현우가 말했어요. (distractor: 세배 드리다, 송편 빚다, 송편 찌다) |
| cloze_a1_0115 | particle_mismatch | 큰돈 말고 ＿＿＿이면 충분해요. (distractor: 송편 찌다, 수저 놓다, 앉으세요) |
| cloze_a1_0135 | particle_mismatch | ＿＿＿은 현우가 차에서 알려 줬어요. (distractor: 송편 찌다, 수저 놓다, 앉으세요) |
| cloze_a1_0162 | particle_mismatch | ＿＿＿가 만두처럼 커졌어요. (distractor: 작은 정성) |
| cloze_a1_0166 | particle_mismatch | ＿＿＿는 김이 올라서 부엌이 뿌예졌어요. (distractor: 수저 놓) |
| cloze_a1_0174 | josa_dup | 시누이가 옷걸이를 찾아 줬어요. |
| cloze_a1_0179 | josa_dup | 맏이가 자리 배치를 조용히 정했어요. |
| cloze_a1_0188 | formality_mix | 상을 물릴 때 잘 먹었습니다 하고 크게 인사했어요. |
| cloze_a1_0195 | particle_mismatch | ＿＿＿은 따뜻했다고만 적었어요. (distractor: 촬영 금지, 다음에 또 오세요) |
| cloze_a1_0211 | particle_mismatch | ＿＿＿을 종이에 적어 주세요. (distractor: 연고, 마스크, 계산대) |
| cloze_a1_0221 | particle_mismatch | ＿＿＿을 세 시로 바꿀까요? (distractor: 약속 장소, 취소하다) |
| cloze_a1_0222 | particle_mismatch | ＿＿＿는 역 앞이에요. (distractor: 늦잠, 약속 시간) |
| cloze_a1_0228 | particle_mismatch | ＿＿＿을 같이 세워 봐요. (distractor: 약속 장소) |
| cloze_a1_0243 | particle_mismatch | 아침에 ＿＿＿를 했어요. (distractor: 초인종, 이웃집) |
| cloze_a1_0265 | particle_mismatch | ＿＿＿가 나오면 일어나요. (distractor: 환승, 승강장) |
| cloze_a1_0266 | particle_mismatch | ＿＿＿이 부족해서 충전이 필요해요. (distractor: 출구) |
| cloze_a1_0267 | particle_mismatch | ＿＿＿은 오른쪽이에요. (distractor: 출구) |
| cloze_a1_0272 | particle_mismatch | 낮에는 ＿＿＿이 편해요. (distractor: 미세먼지, 일기예보) |
| cloze_a1_0273 | particle_mismatch | 밤에는 ＿＿＿이 필요해요. (distractor: 미세먼지, 일기예보) |
| cloze_a1_0327 | particle_mismatch | ＿＿＿을 주세요. (distractor: 메뉴, 주소) |
| cloze_a1_0332 | particle_mismatch | ＿＿＿를 다시 말해 주세요. (distractor: 도착 시간, 카드 이름) |
| cloze_a1_0333 | particle_mismatch | 이 ＿＿＿을 사용할 수 있어요? (distractor: 주소, 봉투) |
| cloze_a1_0344 | particle_mismatch | 시험 전에 친구가 ＿＿＿이라고 말해요. (distractor: 안녕히, 죄송해, 어서 와) |
| cloze_a2_0069 | particle_mismatch | ＿＿＿을 냈어요. (distractor: 전화, 교수) |
| cloze_a2_0087 | particle_mismatch | ＿＿＿이 안 되면 현우 얼굴을 봐요. (distractor: 국물 새다, 떡국 먹다) |
| cloze_a2_0090 | particle_mismatch | 어른인데 ＿＿＿을 두 번 하고 받았어요. (distractor: 편하게 말해요, 한국어 잘하시네요, 가방이 무겁다) |
| cloze_a2_0118 | particle_mismatch | ＿＿＿을 현우가 못 보면 그냥 웃어요. (distractor: 국물 새다, 떡국 먹다) |
| cloze_a2_0120 | particle_mismatch | ＿＿＿을 들면 현우가 눈을 흘겨요. (distractor: 반말 실수) |
| cloze_a2_0161 | particle_mismatch | 부모님 앞에서는 ＿＿＿를 약속했어요. (distractor: 동생 편) |
| cloze_a2_0169 | particle_mismatch | ＿＿＿는 현우가 눈짓으로 도와줬어요. (distractor: 비밀 보장, 세뱃돈 사양) |
| cloze_a2_0174 | particle_mismatch | 주말에는 데이터가 ＿＿＿이에요. (distractor: 요금제) |
| cloze_a2_0183 | particle_mismatch | 부족하면 ＿＿＿을 추가로 사요. (distractor: 요금제) |
| cloze_a2_0192 | particle_mismatch | ＿＿＿을 위해 신분증을 보여 줬어요. (distractor: 이체하다, 인증서, 보안카드) |
| cloze_a2_0193 | particle_mismatch | ＿＿＿이 네 시라서 서둘렀어요. (distractor: 이체하다, 인증서, 보안카드) |
| cloze_a2_0223 | particle_mismatch | ＿＿＿는 지정된 통에만 넣어요. (distractor: 입주민) |
| cloze_a2_0243 | particle_mismatch | ＿＿＿를 문자로 받았어요. (distractor: 시급, 야간수당) |
| cloze_a2_0277 | particle_mismatch | 이번 주가 어려우면 ＿＿＿는 어때요? (distractor: 매일) |
| cloze_b1_0050 | josa_dup | 두 나라의 차이가 커요. |
| cloze_b1_0120 | particle_mismatch | ＿＿＿을 때 두 손으로 하니 삼촌이 고개를 끄덕이셨어요. (distractor: 대충 하, 먼저 따르) |
| cloze_b1_0121 | particle_mismatch | ＿＿＿를 때 병목을 가리니 현우가 잘했다고 했어요. (distractor: 다시 확인) |
| cloze_b1_0151 | particle_mismatch | ＿＿＿을 현우가 해 주니 덜 아팠어요. (distractor: 올해는 못 가요, 요약해서 전하다, 웃고 넘기다) |
| cloze_b1_0182 | particle_mismatch | ＿＿＿을 금요일 낮으로 적었어요. (distractor: 참조, 숨은참조) |
| cloze_b1_0183 | particle_mismatch | ＿＿＿이 있어서 바로 다시 보냈어요. (distractor: 참조, 숨은참조) |
| cloze_b1_0186 | particle_mismatch | 급한 요청에만 ＿＿＿을 켜요. (distractor: 참조, 숨은참조) |
| cloze_b1_0188 | particle_mismatch | 답장이 없어서 ＿＿＿을 짧게 보냈어요. (distractor: 참조, 숨은참조) |
| cloze_b1_0191 | particle_mismatch | ＿＿＿이 떠서 다시 보내지 않았어요. (distractor: 참조, 숨은참조) |
| cloze_b1_0198 | particle_mismatch | ＿＿＿를 표로 붙여 두었어요. (distractor: 공용 선반, 청소 당번, 공과금 정산) |
| cloze_b1_0199 | particle_mismatch | ＿＿＿가 떨어지면 같이 사요. (distractor: 공용 선반, 청소 당번, 공과금 정산) |
| cloze_b1_0204 | particle_mismatch | ＿＿＿를 당일 오후에 했어요. (distractor: 자기부담금) |
| cloze_b1_0205 | particle_mismatch | ＿＿＿를 약관 삼 쪽에서 확인해요. (distractor: 자기부담금) |
| cloze_b1_0210 | particle_mismatch | ＿＿＿가 하나 빠져서 보완했어요. (distractor: 자기부담금) |
| cloze_b1_0212 | particle_mismatch | ＿＿＿가 이번 주까지라고 들었어요. (distractor: 자기부담금) |
| cloze_b1_0213 | particle_mismatch | ＿＿＿를 시간 순으로 적었어요. (distractor: 자기부담금) |
| cloze_b1_0215 | particle_mismatch | 사진이 흐려서 ＿＿＿가 됐어요. (distractor: 자기부담금) |
| cloze_b1_0219 | particle_mismatch | ＿＿＿이 이 주라고 안내받았어요. (distractor: 구비 서류) |
| cloze_b1_0220 | particle_mismatch | 전입 신고는 ＿＿＿가 따로 있어요. (distractor: 민원실, 접수증) |
| cloze_b1_0224 | particle_mismatch | ＿＿＿는 카드만 된다고 했어요. (distractor: 민원실, 접수증) |
| cloze_b1_0226 | particle_mismatch | 전화로 ＿＿＿을 두 번 요청했어요. (distractor: 구비 서류) |
| cloze_b1_0228 | particle_mismatch | 이번 달 ＿＿＿을 표에 적어요. (distractor: 배정표, 안전 조끼) |
| cloze_b1_0230 | particle_mismatch | ＿＿＿을 들어야 부스를 맡을 수 있어요. (distractor: 배정표, 안전 조끼) |
| cloze_b1_0231 | particle_mismatch | 도로 안내는 ＿＿＿를 입고 해요. (distractor: 봉사 시간, 사전 교육) |
| cloze_b1_0232 | particle_mismatch | 다음 조를 위해 ＿＿＿를 남겼어요. (distractor: 봉사 시간, 사전 교육) |
| cloze_b1_0236 | particle_mismatch | 시작 전에 ＿＿＿을 둘이서 해요. (distractor: 배정표) |
| cloze_b1_0239 | particle_mismatch | 학기말에 ＿＿＿를 받아요. (distractor: 봉사 시간, 사전 교육) |
| cloze_b1_0240 | particle_mismatch | ＿＿＿을 수요일 저녁으로 잡았어요. (distractor: 학습 태도) |
| cloze_b1_0242 | particle_mismatch | ＿＿＿이 십오 분이라 질문을 미리 적어요. (distractor: 학습 태도) |
| cloze_b1_0243 | particle_mismatch | ＿＿＿는 좋아졌지만 숙제 속도가 느려요. (distractor: 학부모 면담, 알림장, 상담 시간) |
| cloze_b1_0252 | particle_mismatch | ＿＿＿를 사진으로 세 장 찍었어요. (distractor: 무상 기간) |
| cloze_b1_0254 | particle_mismatch | ＿＿＿는 오전 방문만 가능하대요. (distractor: 무상 기간) |
| cloze_b1_0255 | particle_mismatch | ＿＿＿이 일주일 남아 있어요. (distractor: 고장 부위, 부품 교체, 출장 수리) |
| cloze_b1_0259 | particle_mismatch | ＿＿＿이 있으면 먼저 전화해 달라고 했어요. (distractor: 고장 부위, 부품 교체, 출장 수리) |
| cloze_b1_0262 | particle_mismatch | ＿＿＿을 받아야 보증이 이어져요. (distractor: 고장 부위, 부품 교체, 출장 수리) |
| cloze_b1_0264 | particle_mismatch | 태풍 때문에 ＿＿＿을 요청했어요. (distractor: 수수료 면제, 대체 열차) |
| cloze_b1_0265 | particle_mismatch | ＿＿＿을 예약 확인서에서 다시 읽어요. (distractor: 수수료 면제, 대체 열차) |
| cloze_b1_0266 | particle_mismatch | 천재지변이면 ＿＿＿가 가능하대요. (distractor: 일정 변경, 환불 규정) |
| cloze_b1_0268 | particle_mismatch | ＿＿＿이 되는지 저녁에 답변 달래요. (distractor: 수수료 면제) |
| cloze_b1_0273 | particle_mismatch | ＿＿＿이 한 시간을 넘으면 안내가 나와요. (distractor: 수수료 면제) |
| cloze_b1_0274 | particle_mismatch | ＿＿＿를 카드로 바로 냈어요. (distractor: 일정 변경, 환불 규정) |
| cloze_b2_0040 | particle_mismatch | ＿＿＿이 뭐예요? (distractor: 봉투, 인기) |
| cloze_b2_0174 | particle_mismatch | ＿＿＿를 보느라 선물을 두 세트로 샀어요. (distractor: 각자 계산) |
| cloze_b2_0196 | particle_mismatch | 동생을 ＿＿＿가 현우가 기침으로 막아 줬어요. (distractor: 한쪽에만, 각자 계산) |
| cloze_b2_0204 | particle_mismatch | 헷갈리면 ＿＿＿는 게 침묵보다 나았어요. (distractor: 선을 긋) |
| cloze_b2_0227 | particle_mismatch | ＿＿＿은 가족 식사에서 서운해 보일 수 있어요. (distractor: 예를 갖추다, 오늘은 여기까지, 용돈 드리다) |
| cloze_b2_0229 | particle_mismatch | ＿＿＿이라고 하니 더 묻지 않으셨어요. (distractor: 어른 앞에서, 예를 갖추다, 오늘은 여기까지) |
| cloze_b2_0232 | particle_mismatch | ＿＿＿는 말을 듣고 현우가 일부러 일어났어요. (distractor: 액수는 비밀) |
| cloze_b2_0239 | particle_mismatch | ＿＿＿를 큰 소리로 하니 자리가 열렸어요. (distractor: 밖에서 예의를) |
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
| cloze_b2_0307 | particle_mismatch | ＿＿＿는 감정 대신 비용으로 말해요. (distractor: 주민 의견, 발언권) |
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
| cloze_b2_0364 | particle_mismatch | 계약 전에 ＿＿＿을 서면으로 확인해 주세요. (distractor: 입주 날짜, 가구 배치) |
| cloze_b2_0366 | particle_mismatch | 정형화된 항목 밖의 경험은 ＿＿＿을 함께 설명해야 합니다. (distractor: 점수와 순위, 학력과 나이, 사진과 주소) |
| cloze_b2_0369 | particle_mismatch | 주택 부족과 정착 지원은 서로 연결되지만 ＿＿＿는 아닙니다. (distractor: 같은 사람, 같은 직업) |
| cloze_b2_0370 | particle_mismatch | ＿＿＿를 알면 경력에 맞는 일자리를 찾기 쉬워집니다. (distractor: 주택 계약 기간, 세대별 취향) |
| cloze_b2_0372 | particle_mismatch | 짧은 영상의 조회수가 ＿＿＿를 자동으로 보장하지는 않아요. (distractor: 노래의 후렴, 자막의 색) |
| cloze_b2_0373 | particle_mismatch | 팬 자원봉사자의 ＿＿＿을 미리 나눠야 활동이 지속됩니다. (distractor: 조회수와 순위) |
| cloze_c1_0024 | josa_dup | 인터뷰 내용과 실제 이용 기록을 대조하니 기억과 행동 사이에 차이가 보였습니다. |
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
| cloze_c1_0111 | particle_mismatch | ＿＿＿을 높이면 지역 분석이 어려워져요. (distractor: 문항 유도, 무응답 처리, 가중치 부여) |
| cloze_c1_0114 | particle_mismatch | ＿＿＿를 옆에 두면 공포가 줄어들어요. (distractor: 상대 위험, 잔여 위험) |
| cloze_c1_0115 | particle_mismatch | ＿＿＿을 0으로 약속하지 않아요. (distractor: 절대 건수, 조기 경보) |
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
| cloze_c1_0222 | particle_mismatch | 같은 월세라도 에너지 비용에 따라 ＿＿＿은 달라집니다. (distractor: 입주 순서) |
| cloze_c1_0223 | particle_mismatch | 지원 효과와 신청 과정의 ＿＿＿을 함께 평가해야 합니다. (distractor: 홍보 문구, 통근 거리, 가구 배치) |
| cloze_c1_0226 | particle_mismatch | 재검토가 ＿＿＿을 공개해야 절차를 평가할 수 있습니다. (distractor: 지원자의 나이, 면접실 위치, 공고의 길이) |
| cloze_c1_0228 | particle_mismatch | 자격 인정과 주거 지원이 늦으면 ＿＿＿을 활용하기 어렵습니다. (distractor: 입국 통계, 광고 문구) |
| cloze_c1_0229 | particle_mismatch | 지역별 일자리와 ＿＿＿을 함께 봐야 정착 계획이 현실적입니다. (distractor: 공연 순서, 월세 광고, 면접 점수) |
| cloze_c1_0231 | particle_mismatch | 팬의 자막 기여를 무료 홍보로만 계산하면 ＿＿＿이 보이지 않습니다. (distractor: 조회수와 순위) |
| cloze_c1_0232 | particle_mismatch | 확산의 크기와 지속 가능한 참여는 ＿＿＿가 필요합니다. (distractor: 같은 자막, 짧은 후렴) |
| cloze_c1_0249 | josa_dup | 설명 가능성은 기술 문서의 길이가 아니라 이의 제기에 쓸 수 있는 정보로 평가해야 합니다. |
| cloze_c2_0077 | particle_mismatch | ＿＿＿를 드러내지 않으면 선택이 자연스러워 보여요. (distractor: 주어 선택) |
| cloze_c2_0078 | particle_mismatch | ＿＿＿가 '전쟁'이면 타협이 패배처럼 들려요. (distractor: 주어 선택) |
| cloze_c2_0079 | particle_mismatch | ＿＿＿을 바꾸면 책임이 다른 자리에 놓여요. (distractor: 담론 전제, 은유 체계, 수동 은폐) |
| cloze_c2_0080 | particle_mismatch | ＿＿＿는 행위자를 지워 절차만 남기어요. (distractor: 주어 선택) |
| cloze_c2_0082 | particle_mismatch | ＿＿＿을 한 주로 줄이면 구조 문제는 사라져요. (distractor: 담론 전제, 은유 체계) |
| cloze_c2_0083 | particle_mismatch | ＿＿＿을 '안전 대 자유'로만 두면 중간이 없어져요. (distractor: 담론 전제, 은유 체계) |
| cloze_c2_0084 | particle_mismatch | ＿＿＿가 직함만이면 근거를 다시 물어요. (distractor: 주어 선택) |
| cloze_c2_0085 | particle_mismatch | ＿＿＿을 표로 만들면 빠진 집단이 보여요. (distractor: 담론 전제, 은유 체계) |
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
| cloze_c2_0135 | particle_mismatch | ＿＿＿가 법률문이면 이의 경로가 닫혀요. (distractor: 결정 요약, 자동 결정, 인간 재심) |
| cloze_c2_0136 | particle_mismatch | ＿＿＿를 템플릿 한 줄로 끝내지 않아요. (distractor: 자동 결정, 인간 재심) |
| cloze_c2_0145 | particle_mismatch | ＿＿＿를 탐지하는 서명을 같이 설계해요. (distractor: 추적 가능성, 변경 이력, 접근 기록) |
| cloze_c2_0147 | particle_mismatch | ＿＿＿가 우편뿐이면 기한을 맞추기 어려워요. (distractor: 추적 가능성, 변경 이력, 접근 기록) |
| cloze_c2_0149 | particle_mismatch | ＿＿＿이 설정 깊숙이 있으면 사실상 없어요. (distractor: 동의 철회, 파생 데이터, 복원 금지) |
| cloze_c2_0152 | particle_mismatch | ＿＿＿를 백업 정책에 명시해야 철회가 완성돼요. (distractor: 철회권) |
| cloze_c2_0153 | particle_mismatch | ＿＿＿가 이의 기간에 자동으로 걸려야 해요. (distractor: 철회권) |
| cloze_c2_0154 | particle_mismatch | ＿＿＿가 수집 쪽이면 철회가 계속 싸움이 돼요. (distractor: 철회권) |
| cloze_c2_0155 | particle_mismatch | ＿＿＿을 가입 뒤로 미루면 동의가 형식만 남아요. (distractor: 동의 철회, 파생 데이터) |
| cloze_c2_0158 | particle_mismatch | ＿＿＿을 기능 잠금으로 하면 자유가 아니에요. (distractor: 동의 철회, 파생 데이터) |
| cloze_c2_0159 | particle_mismatch | ＿＿＿를 넓게 쓰면 철회권이 구멍 나요. (distractor: 고지 시점) |
| cloze_c2_0160 | particle_mismatch | ＿＿＿가 전화뿐이면 시간대에 따라 권리가 달라져요. (distractor: 철회권) |
| cloze_c2_0161 | particle_mismatch | ＿＿＿을 평균 정확도 뒤에 숨기지 않아요. (distractor: 대리 변수) |
| cloze_c2_0162 | particle_mismatch | ＿＿＿이 한쪽 집단에만 모이면 모델을 멈춰요. (distractor: 대리 변수) |
| cloze_c2_0164 | particle_mismatch | ＿＿＿가 주소를 쓰면 차별이 우회해요. (distractor: 차등 영향, 오류 비용, 피드백 왜곡) |
| cloze_c2_0167 | particle_mismatch | ＿＿＿가 쿠폰이면 권리를 값으로 바꾼 거예요. (distractor: 차등 영향, 오류 비용, 피드백 왜곡) |
| cloze_c2_0168 | particle_mismatch | ＿＿＿를 취약 지역부터 시작하면 실험이 전가돼요. (distractor: 차등 영향, 오류 비용, 피드백 왜곡) |
| cloze_c2_0171 | particle_mismatch | ＿＿＿를 버전 업으로 위장하지 않아요. (distractor: 차등 영향, 오류 비용, 피드백 왜곡) |
| cloze_c2_0223 | josa_dup | 소득 구간별 부담의 분포를 공개해야 평균이 가리는 차이가 드러납니다. |
| cloze_c2_0223 | particle_mismatch | 소득 구간별 ＿＿＿를 공개해야 평균이 가리는 차이가 드러납니다. (distractor: 광고의 색상, 계약의 글꼴) |
| cloze_c2_0225 | particle_mismatch | 회사와 공급업체의 분업이 ＿＿＿이 되어서는 안 됩니다. (distractor: 광고의 효과, 면접의 순서) |
| cloze_c2_0226 | particle_mismatch | 사람의 검토자는 자동 결과를 ＿＿＿를 기록해야 합니다. (distractor: 공고의 제목) |

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

33건.

| id | 마커 | 문장 |
|---|---|---|
| anonymous_survey_trust#dialog[05] | formality_mix | 맞아요. 식별 가능한 사례를 쓰지 말라는 안내와 실제 보고 방식을 함께 설명해야 신뢰를 얻습니다. |
| anonymous_survey_trust#quest_anonymous_survey_trust_03.targetKo | formality_mix | 맞아요. 식별 가능한 사례를 쓰지 말라는 안내와 실제 보고 방식을 함께 설명해야 신뢰를 얻습니다. |
| bakery_queue#dialog[02] | formality_mix | 아, 죄송합니다. 줄 서 계신지 몰랐어요. |
| bakery_queue#quest_bakery_queue_02.options[2].ko | formality_mix | 아, 죄송합니다. 줄 서 계신지 몰랐어요. |
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

8건.

| id | 마커 | 문장 |
|---|---|---|
| smalltalk_b1_0043#followUp | formality_mix | 알겠습니다. 바로 가 볼게요. |
| smalltalk_b1_0045#followUp | formality_mix | 확인해 주셔서 감사합니다. 일정에 반영할게요. |
| smalltalk_b1_0051#followUp | formality_mix | 감사합니다. 인원을 확정하는 데 도움이 될 거예요. |
| smalltalk_b2_0095 | josa_dup | 선을 긋고도 사이가 나빠지지 않으려면 어떻게 말해야 할까요? |
| smalltalk_b2_0115#reply | formality_mix | 수요 변화와 규제, 지역별 소득도 함께 검토해야 합니다. |
| smalltalk_b2_0123#followUp | formality_mix | 확인해 보겠습니다. 잠시만 기다려 주세요. |
| smalltalk_b2_0123#reply | formality_mix | 확인해 보겠습니다. 잠시만 기다려 주세요. |
| smalltalk_c1_0063#reply | josa_dup | 평균 하나로는 긴급도와 지역 차이가 가려져요. |

## 요약

- 총 후보: **375건** (대상 파일 7개 전부 스캔, 후보 있는 파일 6개)

### 파일별 건수

- cloze.json: 311건
- grammar.csv: 0건
- korean_vocab.csv: 10건
- satz_sentences.json: 10건
- scenarios_*.json: 33건
- silben_puzzles.json: 3건
- smalltalk.json: 8건

### 마커별 건수

- dangling_stem: 0건
- particle_mismatch: 302건
- passive_pileup: 0건
- e_daehae: 0건
- josa_dup: 28건
- formality_mix: 45건
- level_length: 0건
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

