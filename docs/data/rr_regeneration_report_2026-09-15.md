# RR romanization regeneration report (2026-09-15, task C2a)

- Total vocab rows: 2499
- Rows with a changed `romanization` value: 392
- Rows flagged for manual review (ambiguous liaison/n-insertion): 146
- Rows flagged for manual review (체언 ㅎ-aspiration heuristic applies): 69

## Changes by rule

### aspiration_merge (49 rows)

| id | korean | before | after | rule |
|---|---|---|---|---|
| vocab_a2_0044 | 도착하다 | dochakhada | dochakada | aspiration_merge |
| vocab_a2_0052 | 예약하다 | yeyakhada | yeyakada | aspiration_merge |
| vocab_a2_0063 | 행복하다 | haengbokhada | haengbokada | aspiration_merge |
| vocab_b1_0035 | 노력하다 | noryeokhada | noryeokada | aspiration_merge |
| vocab_b1_0037 | 선택하다 | seontaekhada | seontaekada | aspiration_merge |
| vocab_b1_0040 | 극복하다 | geukbokhada | geukbokada | aspiration_merge |
| vocab_b1_0046 | 복잡하다 | bokjaphada | bokjapada | aspiration_merge |
| vocab_b1_0048 | 정확하다 | jeonghwakhada | jeonghwakada | aspiration_merge |
| vocab_b2_0023 | 인식하다 | insikhada | insikada | aspiration_merge |
| vocab_b2_0024 | 해석하다 | haeseokhada | haeseokada | aspiration_merge |
| vocab_b2_0025 | 반박하다 | banbakhada | banbakada | aspiration_merge |
| vocab_b2_0028 | 지속하다 | jisokhada | jisokada | aspiration_merge |
| vocab_b1_0064 | 검색하다 | geomsaekhada | geomsaekada | aspiration_merge |
| vocab_b1_0067 | 협력하다 | hyeoryeokhada | hyeomnyeokada | aspiration_merge, nasalization |
| vocab_b1_0091 | 솔직하다 | soljikhada | soljikada | aspiration_merge |
| vocab_b1_0101 | 약속하다 | yaksokhada | yaksokada | aspiration_merge |
| vocab_b2_0070 | 명확하다 | myeonghwakhada | myeonghwakada | aspiration_merge |
| vocab_a2_0160 | 저축하다 | jeochukhada | jeochukada | aspiration_merge |
| vocab_b1_0166 | 취직하다 | chwijikhada | chwijikada | aspiration_merge |
| vocab_b1_0173 | 합격하다 | hapgyeokhada | hapgyeokada | aspiration_merge |
| vocab_b1_0174 | 모집하다 | mojiphada | mojipada | aspiration_merge |
| vocab_b1_0175 | 지각하다 | jigakhada | jigakada | aspiration_merge |
| vocab_b1_0185 | 참석하다 | chamseokhada | chamseokada | aspiration_merge |
| vocab_b1_0193 | 번역하다 | beonyeokhada | beonyeokada | aspiration_merge, liaison |
| vocab_b1_0196 | 대답하다 | daedaphada | daedapada | aspiration_merge |
| vocab_b1_0208 | 섭섭하다 | seopseophada | seopseopada | aspiration_merge |
| vocab_b1_0209 | 심각하다 | simgakhada | simgakada | aspiration_merge |
| vocab_b1_0242 | 졸업하다 | joreophada | joreopada | aspiration_merge, liaison |
| vocab_b1_0243 | 입학하다 | iphakhada | ipakada | aspiration_merge |
| vocab_b2_0090 | 독립하다 | dongniphada | dongnipada | aspiration_merge, nasalization |
| vocab_b2_0184 | 간직하다 | ganjikhada | ganjikada | aspiration_merge |
| vocab_b2_0229 | 타협하다 | tahyeophada | tahyeopada | aspiration_merge |
| vocab_b2_0259 | 완곡하다 | wangokhada | wangokada | aspiration_merge |
| vocab_b2_0262 | 오해를 낳다 | ohaereul natda | ohaereul nata | aspiration_merge |
| vocab_b2_0267 | 의견을 좁히다 | uigyeoneul jophida | uigyeoneul jopida | aspiration_merge, liaison |
| vocab_b2_0271 | 마감이 촉박하다 | magami chokbakhada | magami chokbakada | aspiration_merge, liaison |
| vocab_b2_0275 | 의견을 완곡하게 전하다 | uigyeoneul wangokhage jeonhada | uigyeoneul wangokage jeonhada | aspiration_merge, liaison |
| vocab_c1_0016 | 상관관계를 인과로 해석하다 | sanggwangwangyereul ingwaro haeseokhada | sanggwangwangyereul ingwaro haeseokada | aspiration_merge |
| vocab_c2_0017 | 암시를 포착하다 | amsireul pochakhada | amsireul pochakada | aspiration_merge |
| vocab_c2_0018 | 맥락을 전복하다 | maengnageul jeonbokhada | maengnageul jeonbokada | aspiration_merge, liaison, nasalization |
| vocab_c2_0021 | 인물에 이입하다 | inmure iiphada | inmure iipada | aspiration_merge, liaison |
| vocab_b2_0307 | 기분을 솔직히 말하다 | gibuneul soljikhi malhada | gibuneul soljiki malhada | aspiration_merge, liaison |
| vocab_b2_0308 | 답장을 재촉하지 않다 | dapjangeul jaechokhaji anta | dapjangeul jaechokaji anda | aspiration_merge |
| vocab_c2_0037 | 결정 과정을 추적하다 | gyeoljeong gwajeongeul chujeokhada | gyeoljeong gwajeongeul chujeokada | aspiration_merge |
| vocab_c2_0040 | 편향을 증폭하다 | pyeonhyangeul jeungpokhada | pyeonhyangeul jeungpokada | aspiration_merge |
| vocab_a1_0387 | 습하다 | seuphada | seupada | aspiration_merge |
| vocab_a1_0396 | 부탁하다 | butakhada | butakada | aspiration_merge |
| vocab_a2_0438 | 습득하다 | seupdeukhada | seupdeukada | aspiration_merge |
| vocab_a1_0444 | 시작하다 | sijakhada | sijakada | aspiration_merge |

### base_letter_correction (142 rows)

| id | korean | before | after | rule |
|---|---|---|---|---|
| vocab_a1_0053 | 빨간색 | ppalgan saek | ppalgansaek | base_letter_correction |
| vocab_a1_0054 | 파란색 | paran saek | paransaek | base_letter_correction |
| vocab_a1_0055 | 초록색 | chorok saek | choroksaek | base_letter_correction |
| vocab_a1_0056 | 노란색 | noran saek | noransaek | base_letter_correction |
| vocab_a1_0057 | 흰색 | hinsaek | huinsaek | base_letter_correction |
| vocab_a1_0064 | 김치 | kimchi | gimchi | base_letter_correction |
| vocab_a1_0118 | 많다 | manta | manda | base_letter_correction |
| vocab_a1_0127 | 배고프다 | baegopuda | baegopeuda | base_letter_correction |
| vocab_a2_0067 | 무섭다 | museobda | museopda | base_letter_correction |
| vocab_a2_0075 | 좁다 | jobda | jopda | base_letter_correction |
| vocab_a2_0079 | 외롭다 | oeroepda | oeropda | base_letter_correction |
| vocab_b1_0015 | 스트레스 | seuteuleseu | seuteureseu | base_letter_correction |
| vocab_b1_0028 | 결정하다 | gyeoljeongada | gyeoljeonghada | base_letter_correction |
| vocab_b1_0030 | 비교하다 | bigohada | bigyohada | base_letter_correction |
| vocab_b1_0038 | 실패하다 | silpaekhada | silpaehada | base_letter_correction |
| vocab_b1_0044 | 중요하다 | jungnyohada | jungyohada | base_letter_correction |
| vocab_b1_0054 | 특히 | teuki | teukhi | base_letter_correction |
| vocab_b2_0015 | 주장하다 | jujangada | jujanghada | base_letter_correction |
| vocab_a2_0109 | 교차로 | gyochalo | gyocharo | base_letter_correction |
| vocab_a2_0131 | 화장하다 | hwajangada | hwajanghada | base_letter_correction |
| vocab_b1_0259 | 이삿짐 | isatjjim | isatjim | base_letter_correction |
| vocab_b2_0211 | 효력 | hyeoryeok | hyoryeok | base_letter_correction |
| vocab_b2_0403 | 가치를 추구하다 | gachireul chuguhhada | gachireul chuguhada | base_letter_correction |
| vocab_b2_0409 | 우선시하다 | useonsikhada | useonsihada | base_letter_correction |
| vocab_c1_0015 | 결과를 재현하다 | gyeolgwahreul jaehyeonhada | gyeolgwareul jaehyeonhada | base_letter_correction |
| vocab_c1_0017 | 전제를 밝히다 | jeonjereul balkida | jeonjereul bakhida | base_letter_correction |
| vocab_c2_0001 | 이해관계가 얽히다 | ihaegwangyega eolkhida | ihaegwangyega eokhida | base_letter_correction |
| vocab_c2_0003 | 절차적 정당성 | jeolchaejjeok jeongdangseong | jeolchajeok jeongdangseong | base_letter_correction |
| vocab_b2_0305 | 무리해서 맞추다 | murhaeseo matchuda | murihaeseo matchuda | base_letter_correction |
| vocab_c2_0046 | 예외 사례를 처리하다 | yeoe sarereul cheorihada | yeoe saryereul cheorihada | base_letter_correction |
| vocab_a1_0225 | 건강식품 | geongangsigpum | geongangsikpum | base_letter_correction |
| vocab_a1_0232 | 백화점 상품권 | baeghwajeom sangpumgwon | baekhwajeom sangpumgwon | base_letter_correction |
| vocab_a1_0233 | 꽃다발 | kkochdabal | kkotdabal | base_letter_correction |
| vocab_a1_0242 | 방석 | bangseog | bangseok | base_letter_correction |
| vocab_a1_0244 | 손 씻기 | son ssisgi | son ssitgi | base_letter_correction |
| vocab_a1_0254 | 집밥 | jibbab | jipbap | base_letter_correction |
| vocab_a1_0256 | 젓가락질 | jeosgaragjil | jeotgarakjil | base_letter_correction |
| vocab_a1_0257 | 앞접시 | apjeobsi | apjeopsi | base_letter_correction |
| vocab_a1_0258 | 수저 놓다 | sujeo nohda | sujeo notda | base_letter_correction |
| vocab_a1_0262 | 떡국 | tteoggug | tteokguk | base_letter_correction |
| vocab_a1_0263 | 세뱃돈 | sebaesdon | sebaetdon | base_letter_correction |
| vocab_a1_0264 | 한복 | hanbog | hanbok | base_letter_correction |
| vocab_a1_0268 | 덕담 | deogdam | deokdam | base_letter_correction |
| vocab_a1_0270 | 세뱃돈 봉투 | sebaesdon bongtu | sebaetdon bongtu | base_letter_correction |
| vocab_a1_0272 | 추석 | chuseog | chuseok | base_letter_correction |
| vocab_a1_0274 | 송편 빚다 | songpyeon bijda | songpyeon bitda | base_letter_correction |
| vocab_a1_0279 | 햇과일 | haesgwail | haetgwail | base_letter_correction |
| vocab_a1_0296 | 인증샷 | injeungsyas | injeungsyat | base_letter_correction |
| vocab_a1_0297 | 가족 앨범 | gajog aelbeom | gajok aelbeom | base_letter_correction |
| vocab_a1_0303 | 카톡 | katog | katok | base_letter_correction |
| vocab_a2_0276 | 통역 부탁 | tongyeog butag | tongyeok butak | base_letter_correction |
| vocab_a2_0279 | 음식 취향 | eumsig chwihyang | eumsik chwihyang | base_letter_correction |
| vocab_a2_0282 | 떡국 먹다 | tteoggug meogda | tteokguk meokda | base_letter_correction |
| vocab_a2_0283 | 세뱃돈 사양 | sebaesdon sayang | sebaetdon sayang | base_letter_correction |
| vocab_a2_0284 | 한복 대여 | hanbog daeyeo | hanbok daeyeo | base_letter_correction |
| vocab_a2_0286 | 복주머니 | bogjumeoni | bokjumeoni | base_letter_correction |
| vocab_a2_0289 | 명절 음식 | myeongjeol eumsig | myeongjeol eumsik | base_letter_correction |
| vocab_a2_0291 | 세배 연습 | sebae yeonseub | sebae yeonseup | base_letter_correction |
| vocab_a2_0292 | 새해 목표 | saehae mogpyo | saehae mokpyo | base_letter_correction |
| vocab_a2_0294 | 송편 맛 | songpyeon mas | songpyeon mat | base_letter_correction |
| vocab_a2_0296 | 성묘 옷 | seongmyo os | seongmyo ot | base_letter_correction |
| vocab_a2_0297 | 벌초 장갑 | beolcho janggab | beolcho janggap | base_letter_correction |
| vocab_a2_0298 | 차례 음식 | charye eumsig | charye eumsik | base_letter_correction |
| vocab_a2_0301 | 고향집 | gohyangjib | gohyangjip | base_letter_correction |
| vocab_a2_0302 | 친척 방문 | chincheog bangmun | chincheok bangmun | base_letter_correction |
| vocab_a2_0304 | 추석 연휴 | chuseog yeonhyu | chuseok yeonhyu | base_letter_correction |
| vocab_a2_0310 | 맞장구 | majjanggu | matjanggu | base_letter_correction |
| vocab_a2_0311 | 통역 눈짓 | tongyeog nunjis | tongyeok nunjit | base_letter_correction |
| vocab_a2_0314 | 단톡방 | dantogbang | dantokbang | base_letter_correction |
| vocab_a2_0325 | 아침밥 | achimbab | achimbap | base_letter_correction |
| vocab_a2_0327 | 문 닫기 | mun dadgi | mun datgi | base_letter_correction |
| vocab_a2_0337 | 집까지 | jibkkaji | jipkkaji | base_letter_correction |
| vocab_a2_0338 | 가방이 무겁다 | gabangi mugeobda | gabangi mugeopda | base_letter_correction |
| vocab_a2_0341 | 고속버스 | gosogbeoseu | gosokbeoseu | base_letter_correction |
| vocab_a2_0344 | 좌석 배정 | jwaseog baejeong | jwaseok baejeong | base_letter_correction |
| vocab_a2_0346 | 도착 인사 | dochag insa | dochak insa | base_letter_correction |
| vocab_a2_0347 | 친척 집 | chincheog jib | chincheok jip | base_letter_correction |
| vocab_a2_0349 | 집 마당 | jib madang | jip madang | base_letter_correction |
| vocab_a2_0356 | 호칭 연습 | hoching yeonseub | hoching yeonseup | base_letter_correction |
| vocab_a2_0358 | 아직 어색해요 | ajig eosaeghaeyo | ajik eosaekhaeyo | base_letter_correction |
| vocab_a2_0362 | 말투 맞추기 | maltu majchugi | maltu matchugi | base_letter_correction |
| vocab_a2_0364 | 반말 연습 | banmal yeonseub | banmal yeonseup | base_letter_correction |
| vocab_b1_0272 | 결혼 계획 | gyeolhon gyehoeg | gyeolhon gyehoek | base_letter_correction |
| vocab_b1_0274 | 월급 이야기 | wolgeub iyagi | wolgeup iyagi | base_letter_correction |
| vocab_b1_0277 | 국적 문제 | gugjeog munje | gukjeok munje | base_letter_correction |
| vocab_b1_0278 | 부모 허락 | bumo heorag | bumo heorak | base_letter_correction |
| vocab_b1_0281 | 웃고 넘기다 | usgo neomgida | utgo neomgida | base_letter_correction |
| vocab_b1_0282 | 솔직한 선 | soljighan seon | soljikhan seon | base_letter_correction |
| vocab_b1_0284 | 취업 비자 | chwieob bija | chwieop bija | base_letter_correction |
| vocab_b1_0285 | 계약직 | gyeyagjig | gyeyakjik | base_letter_correction |
| vocab_b1_0286 | 원격 근무 | wongyeog geunmu | wongyeok geunmu | base_letter_correction |
| vocab_b1_0287 | 이직 생각 | ijig saenggag | ijik saenggak | base_letter_correction |
| vocab_b1_0297 | 요약해서 전하다 | yoyaghaeseo jeonhada | yoyakhaeseo jeonhada | base_letter_correction |
| vocab_b1_0298 | 그대로 옮기다 | geudaero olmgida | geudaero omgida | base_letter_correction |
| vocab_b1_0304 | 오역 | oyeog | oyeok | base_letter_correction |
| vocab_b1_0307 | 직접 대답하다 | jigjeob daedabhada | jikjeop daedaphada | base_letter_correction |
| vocab_b1_0338 | 가족 단톡 | gajog dantog | gajok dantok | base_letter_correction |
| vocab_b1_0339 | 잔소리 해석 | jansori haeseog | jansori haeseok | base_letter_correction |
| vocab_b1_0340 | 칭찬 기억 | chingchan gieog | chingchan gieok | base_letter_correction |
| vocab_b1_0344 | 단톡 입장 | dantog ibjang | dantok ipjang | base_letter_correction |
| vocab_b1_0345 | 읽씹 | ilgssib | ikssip | base_letter_correction |
| vocab_b1_0352 | 새벽 메시지 | saebyeog mesiji | saebyeok mesiji | base_letter_correction |
| vocab_b1_0356 | 양쪽 집 | yangjjog jib | yangjjok jip | base_letter_correction |
| vocab_b1_0367 | 올해는 못 가요 | olhaeneun mos gayo | olhaeneun mot gayo | base_letter_correction |
| vocab_b2_0431 | 시댁 | sidaeg | sidaek | base_letter_correction |
| vocab_b2_0433 | 며느리 역할 | myeoneuri yeoghal | myeoneuri yeokhal | base_letter_correction |
| vocab_b2_0444 | 예식 날짜 | yesig naljja | yesik naljja | base_letter_correction |
| vocab_b2_0448 | 결혼식 규모 | gyeolhonsig gyumo | gyeolhonsik gyumo | base_letter_correction |
| vocab_b2_0449 | 하객 명단 | hagaeg myeongdan | hagaek myeongdan | base_letter_correction |
| vocab_b2_0451 | 결혼 압박 | gyeolhon abbag | gyeolhon apbak | base_letter_correction |
| vocab_b2_0452 | 서로의 속도 | seoroui sogdo | seoroui sokdo | base_letter_correction |
| vocab_b2_0453 | 아직 아니에요 | ajig anieyo | ajik anieyo | base_letter_correction |
| vocab_b2_0457 | 낮춰 부르다 | najchwo bureuda | natchwo bureuda | base_letter_correction |
| vocab_b2_0459 | 호칭을 바로잡다 | hochingeul barojabda | hochingeul barojapda | base_letter_correction |
| vocab_b2_0461 | 사적 호칭 | sajeog hoching | sajeok hoching | base_letter_correction |
| vocab_b2_0472 | 음복 | eumbog | eumbok | base_letter_correction |
| vocab_b2_0478 | 예를 갖추다 | yereul gajchuda | yereul gatchuda | base_letter_correction |
| vocab_b2_0484 | 빚 이야기 | bij iyagi | bit iyagi | base_letter_correction |
| vocab_b2_0485 | 집 장만 | jib jangman | jip jangman | base_letter_correction |
| vocab_b2_0488 | 각자 계산 | gagja gyesan | gakja gyesan | base_letter_correction |
| vocab_b2_0490 | 액수는 비밀 | aegsuneun bimil | aeksuneun bimil | base_letter_correction |
| vocab_b2_0495 | 손님 대접 | sonnim daejeob | sonnim daejeop | base_letter_correction |
| vocab_b2_0496 | 휴식 교대 | hyusig gyodae | hyusik gyodae | base_letter_correction |
| vocab_b2_0497 | 음식 나르기 | eumsig nareugi | eumsik nareugi | base_letter_correction |
| vocab_b2_0509 | 가족 기대 | gajog gidae | gajok gidae | base_letter_correction |
| vocab_b2_0511 | 반복 요구 | banbog yogu | banbok yogu | base_letter_correction |
| vocab_b2_0515 | 공식 소개 | gongsig sogae | gongsik sogae | base_letter_correction |
| vocab_b2_0519 | 모임 지각 | moim jigag | moim jigak | base_letter_correction |
| vocab_c1_0051 | 소속 프레임 | sosog peureim | sosok peureim | base_letter_correction |
| vocab_c1_0053 | 포용적 호칭 | poyongjeog hoching | poyongjeok hoching | base_letter_correction |
| vocab_c1_0055 | 가족 서사 | gajog seosa | gajok seosa | base_letter_correction |
| vocab_c1_0060 | 자리를 재협상하다 | jarireul jaehyeobsanghada | jarireul jaehyeopsanghada | base_letter_correction |
| vocab_c1_0061 | 보이지 않는 일 | boiji anhneun il | boiji anneun il | base_letter_correction |
| vocab_c1_0065 | 전통의 선택 | jeontongui seontaeg | jeontongui seontaek | base_letter_correction |
| vocab_c1_0067 | 휴식권 | hyusiggwon | hyusikgwon | base_letter_correction |
| vocab_c2_0056 | 동의의 형식 | donguiui hyeongsig | donguiui hyeongsik | base_letter_correction |
| vocab_c2_0066 | 기록 주체 | girog juche | girok juche | base_letter_correction |
| vocab_c2_0068 | 공동 기억 | gongdong gieog | gongdong gieok | base_letter_correction |
| vocab_b1_0449 | A/S 센터 | / senteo | A/S senteo | base_letter_correction |
| vocab_b2_0618 | 도표 읽기 | dopyo ilggi | dopyo ikgi | base_letter_correction |
| vocab_c2_0150 | 기본값 설계 | gibongaps seolgye | gibongap seolgye | base_letter_correction |
| vocab_c1_0188 | 역효과 | yeokyogwa | yeokhyogwa | base_letter_correction |

### liaison (110 rows)

| id | korean | before | after | rule |
|---|---|---|---|---|
| vocab_a1_0058 | 검은색 | geomeun saek | geomeunsaek | liaison |
| vocab_a1_0069 | 편의점 | pyeonijeom | pyeonuijeom | liaison |
| vocab_a1_0100 | 싫어하다 | sireohada | sileohada | liaison |
| vocab_a2_0036 | 할인 | halin | harin | liaison |
| vocab_a2_0054 | 잃어버리다 | ireobeorida | ileobeorida | liaison |
| vocab_b2_0029 | 추상적이다 | chusangjeoida | chusangjeogida | liaison |
| vocab_b2_0030 | 구체적이다 | gucheijeoida | guchejeogida | liaison |
| vocab_b2_0031 | 객관적이다 | gaekgwanjeoida | gaekgwanjeogida | liaison |
| vocab_b2_0032 | 주관적이다 | jugwanjeoida | jugwanjeogida | liaison |
| vocab_a1_0173 | 별말씀을요 | byeolmalsseumeurueyo | byeolmalsseumeuryo | liaison |
| vocab_a1_0209 | 맛없다 | masseopda | maseopda | liaison |
| vocab_b1_0193 | 번역하다 | beonyeokhada | beonyeokada | aspiration_merge, liaison |
| vocab_b1_0242 | 졸업하다 | joreophada | joreopada | aspiration_merge, liaison |
| vocab_b2_0189 | 섞이다 | seokkida | seogida | liaison |
| vocab_b2_0214 | 합의서 | hapyiseo | habuiseo | liaison |
| vocab_b2_0240 | 되돌아보다 | doedolaboda | doedoraboda | liaison |
| vocab_b2_0258 | 비속어 | bisoge | bisogeo | liaison |
| vocab_b2_0267 | 의견을 좁히다 | uigyeoneul jophida | uigyeoneul jopida | aspiration_merge, liaison |
| vocab_b2_0271 | 마감이 촉박하다 | magami chokbakhada | magami chokbakada | aspiration_merge, liaison |
| vocab_b2_0275 | 의견을 완곡하게 전하다 | uigyeoneul wangokhage jeonhada | uigyeoneul wangokage jeonhada | aspiration_merge, liaison |
| vocab_c2_0011 | 부작용을 상쇄하다 | bujagyong-eul sangswaehada | bujagyongeul sangswaehada | liaison |
| vocab_c2_0018 | 맥락을 전복하다 | maengnageul jeonbokhada | maengnageul jeonbokada | aspiration_merge, liaison, nasalization |
| vocab_c2_0021 | 인물에 이입하다 | inmure iiphada | inmure iipada | aspiration_merge, liaison |
| vocab_b2_0299 | 뒷사람을 위해 정리하다 | dwitsarameul wihae jeongrihada | dwitsarameul wihae jeongnihada | liaison, nasalization |
| vocab_b2_0307 | 기분을 솔직히 말하다 | gibuneul soljikhi malhada | gibuneul soljiki malhada | aspiration_merge, liaison |
| vocab_c1_0026 | 위험을 과소평가하다 | wiheomeul gwasonpyeonggahada | wiheomeul gwasopyeonggahada | liaison |
| vocab_c1_0028 | 가능성과 확률을 구분하다 | ganeungseonggwa hwakryureul gubunhada | ganeungseonggwa hwangnyureul gubunhada | liaison, nasalization |
| vocab_c1_0042 | 선택의 폭을 넓히다 | seontaegui pogeul neolpida | seontaegui pogeul neolhida | liaison |
| vocab_c1_0048 | 지역 여건에 맞추다 | jiyeok yeogone matchuda | jiyeok yeogeone matchuda | liaison |
| vocab_c2_0035 | 모호함을 전략적으로 남기다 | mohameul jeollyakjeogeuro namgida | mohohameul jeollyakjeogeuro namgida | liaison, ll_assimilation |
| vocab_c2_0042 | 인간의 판단을 대체하다 | inganeui pandaneul daechehada | inganui pandaneul daechehada | liaison |
| vocab_a1_0220 | 성함을 묻다 | seonghameul mudda | seonghameul mutda | liaison |
| vocab_a1_0221 | 몇 살이세요 | myeoch saliseyo | myeot sariseyo | liaison |
| vocab_a1_0265 | 새해 복 많이 받으세요 | saehae bog manhi badeuseyo | saehae bok mani badeuseyo | liaison |
| vocab_a1_0281 | 솔잎 | sollip | sorip | liaison |
| vocab_a1_0298 | 촬영 금지 | chwalyeong geumji | chwaryeong geumji | liaison |
| vocab_a1_0300 | 잘 먹었습니다 | jal meogeossseubnida | jal meogeotseumnida | liaison, nasalization |
| vocab_a2_0280 | 분위기 파악 | bunwigi paag | bunwigi paak | liaison |
| vocab_a2_0321 | 일찍 일어나다 | iljjig ileonada | iljjik ireonada | liaison |
| vocab_a2_0323 | 잠옷 | jamos | jamot | liaison |
| vocab_a2_0324 | 코골이 | kogoli | kogori | liaison |
| vocab_a2_0351 | 돌아가는 길 | dolaganeun gil | doraganeun gil | liaison |
| vocab_b1_0289 | 한국어 능력 | hangugeo neungryeog | hangugeo neungnyeok | liaison, nasalization |
| vocab_b1_0293 | 직장 분위기 | jigjang bunwigi | jikjang bunwigi | liaison |
| vocab_b1_0294 | 통역 없이 | tongyeog eopsi | tongyeok eopsi | liaison |
| vocab_b1_0308 | 잔을 받다 | janeul badda | janeul batda | liaison |
| vocab_b1_0315 | 분위기 맞추다 | bunwigi majchuda | bunwigi matchuda | liaison |
| vocab_b1_0322 | 문 열어 두다 | mun yeoleo duda | mun yeoreo duda | liaison |
| vocab_b1_0325 | 코골이 사과 | kogoli sagwa | kogori sagwa | liaison |
| vocab_b1_0329 | 잠옷 대신 | jamos daesin | jamot daesin | liaison |
| vocab_b1_0348 | 읽음 표시 | ilgeum pyosi | ikgeum pyosi | liaison |
| vocab_b1_0355 | 읽은 척 | ilgeun cheog | ikgeun cheok | liaison |
| vocab_b2_0437 | 처가살이 | cheogasali | cheogasari | liaison |
| vocab_b2_0503 | 선을 긋다 | seoneul geusda | seoneul geutda | liaison |
| vocab_b2_0513 | 오늘은 여기까지 | oneuleun yeogikkaji | oneureun yeogikkaji | liaison |
| vocab_b2_0526 | 밖에서 예의를 | bakkeseo yeuireul | bageseo yeuireul | liaison |
| vocab_c1_0052 | 역할 언어 | yeoghal eoneo | yeokhal eoneo | liaison |
| vocab_c1_0057 | 말의 자리 | malui jari | marui jari | liaison |
| vocab_c1_0062 | 성별 분업 | seongbyeol buneob | seongbyeol buneop | liaison |
| vocab_c2_0055 | 말의 위계 | malui wigye | marui wigye | liaison |
| vocab_c2_0058 | 권력을 호명하다 | gwonryeogeul homyeonghada | gwonnyeogeul homyeonghada | liaison, nasalization |
| vocab_c2_0062 | 기억의 편집 | gieogui pyeonjib | gieogui pyeonjip | liaison |
| vocab_c2_0069 | 말의 유산 | malui yusan | marui yusan | liaison |
| vocab_c2_0070 | 이름을 되찾다 | ireumeul doechajda | ireumeul doechatda | liaison |
| vocab_a1_0323 | 복용 시간 | bokyong sigan | bogyong sigan | liaison |
| vocab_a1_0326 | 가글액 | gageulaek | gageuraek | liaison |
| vocab_a1_0341 | 늦을 것 같다 | neuteul geot gatda | neujeul geot gatda | liaison |
| vocab_a1_0360 | 색연필 | saekyeonpil | saegyeonpil | liaison |
| vocab_a1_0389 | 맑음 | malgeum | makgeum | liaison |
| vocab_a2_0382 | 창구직원 | changgujikwon | changgujigwon | liaison |
| vocab_a2_0387 | 입금 확인 | ipgeum hwakin | ipgeum hwagin | liaison |
| vocab_a2_0420 | 재활용실 | jaehwalyongsil | jaehwaryongsil | liaison |
| vocab_a2_0441 | 찾아가다 | chatagada | chajagada | liaison |
| vocab_a2_0448 | 확인서 | hwakinseo | hwaginseo | liaison |
| vocab_b1_0374 | 읽음 확인 | ilgeum hwakin | ikgeum hwagin | liaison |
| vocab_b1_0375 | 제목을 고치다 | jemokeul gochida | jemogeul gochida | liaison |
| vocab_b1_0378 | 공손한 맺음 | gongsonhan maeteum | gongsonhan maejeum | liaison |
| vocab_b1_0379 | 수신 확인 | susin hwakin | susin hwagin | liaison |
| vocab_b1_0402 | 특약 | teukyak | teugyak | liaison |
| vocab_b1_0421 | 결원 | gyeolwon | gyeorwon | liaison |
| vocab_b1_0426 | 현장 책임자 | hyeonjang chaekimja | hyeonjang chaegimja | liaison |
| vocab_b1_0427 | 봉사 확인서 | bongsa hwakinseo | bongsa hwaginseo | liaison |
| vocab_b2_0538 | 합의된 다음 단계 | hapuidoen daeum dangye | habuidoen daeum dangye | liaison |
| vocab_b2_0550 | 합의서 초안 | hapuiseo choan | habuiseo choan | liaison |
| vocab_b2_0555 | 인용 맥락 | inyong maekrak | inyong maengnak | liaison, nasalization |
| vocab_b2_0559 | 사실 확인 | sasil hwakin | sasil hwagin | liaison |
| vocab_b2_0565 | 발언권 | baleongwon | bareongwon | liaison |
| vocab_b2_0573 | 공개 질의 | gonggae jilui | gonggae jirui | liaison |
| vocab_b2_0582 | 이해 확인 | ihae hwakin | ihae hwagin | liaison |
| vocab_b2_0586 | 합의 문장 | hapui munjang | habui munjang | liaison |
| vocab_b2_0601 | 약속 불이행 | yaksok bulihaeng | yaksok burihaeng | liaison |
| vocab_b2_0607 | 책임 소재 | chaekim sojae | chaegim sojae | liaison |
| vocab_b2_0608 | 현장 확인 | hyeonjang hwakin | hyeonjang hwagin | liaison |
| vocab_b2_0609 | 합의 조건 | hapui jogeon | habui jogeon | liaison |
| vocab_b2_0610 | 종결 확인 | jonggyeol hwakin | jonggyeol hwagin | liaison |
| vocab_b2_0614 | 교차 확인 | gyocha hwakin | gyocha hwagin | liaison |
| vocab_c1_0088 | 질의 시간 | jilui sigan | jirui sigan | liaison |
| vocab_c1_0096 | 발언 기록 | baleon girok | bareon girok | liaison |
| vocab_c1_0127 | 대기 불이익 | daegi buliik | daegi buriik | liaison |
| vocab_c1_0134 | 발언 할당 | baleon haldang | bareon haldang | liaison |
| vocab_c1_0157 | 운영 인력 | unyeong inryeok | unyeong innyeok | liaison, nasalization |
| vocab_c2_0093 | 책임 분산 | chaekim bunsan | chaegim bunsan | liaison |
| vocab_c2_0102 | 침묵의 세대 | chimmukui sedae | chimmugui sedae | liaison |
| vocab_c2_0144 | 책임 매핑 | chaekim maeping | chaegim maeping | liaison |
| vocab_c2_0148 | 복원 금지 | bokwon geumji | bogwon geumji | liaison |
| vocab_c2_0152 | 철회 확인서 | cheolhoe hwakinseo | cheolhoe hwaginseo | liaison |
| vocab_c2_0223 | 인력의 도구화 | illyeogui doguhwa | innyeogui doguhwa | liaison, nasalization |
| vocab_a1_0419 | 지하철역 | jihacheol-lyeok | jihacheoryeok | liaison |
| vocab_a1_0421 | 교통카드 잔액 | gyotong kadeu janaek | gyotongkadeu janaek | liaison |
| vocab_a2_0483 | 끓이다 | kkeurida | kkeulida | liaison |

### ll_assimilation (39 rows)

| id | korean | before | after | rule |
|---|---|---|---|---|
| vocab_a1_0207 | 별로 | byeolro | byeollo | ll_assimilation |
| vocab_b1_0061 | 팔로워 | palloweo | pallowo | ll_assimilation |
| vocab_b1_0248 | 관리비 | gwanribi | gwallibi | ll_assimilation |
| vocab_c2_0022 | 서사가 맞물리다 | seosaga matmullida | seosaga manmullida | ll_assimilation, nasalization |
| vocab_c2_0035 | 모호함을 전략적으로 남기다 | mohameul jeollyakjeogeuro namgida | mohohameul jeollyakjeogeuro namgida | liaison, ll_assimilation |
| vocab_c2_0048 | 철회할 권리를 보장하다 | cheolhoeh al gwonrireul bojanghada | cheolhoehal gwollireul bojanghada | ll_assimilation |
| vocab_a1_0237 | 손님 슬리퍼 | sonnim seulripeo | sonnim seullipeo | ll_assimilation |
| vocab_a1_0252 | 배불러요 | baebulreoyo | baebulleoyo | ll_assimilation |
| vocab_a1_0260 | 설날 | seolnal | seollal | ll_assimilation |
| vocab_a1_0302 | 연락드릴게요 | yeonragdeurilgeyo | yeollakdeurilgeyo | ll_assimilation |
| vocab_a2_0287 | 설날 인사말 | seolnal insamal | seollal insamal | ll_assimilation |
| vocab_a2_0305 | 놀리다 | nolrida | nollida | ll_assimilation |
| vocab_b1_0279 | 돌려 말하기 | dolryeo malhagi | dollyeo malhagi | ll_assimilation |
| vocab_b1_0280 | 화제 돌리기 | hwaje dolrigi | hwaje dolligi | ll_assimilation |
| vocab_b1_0313 | 술잔 돌리기 | suljan dolrigi | suljan dolligi | ll_assimilation |
| vocab_b1_0318 | 물로 받다 | mulro badda | mullo batda | ll_assimilation |
| vocab_b1_0347 | 사진 올리기 | sajin olrigi | sajin olligi | ll_assimilation |
| vocab_b2_0469 | 술잔 올리기 | suljan olrigi | suljan olligi | ll_assimilation |
| vocab_b2_0505 | 연락 빈도 | yeonrag bindo | yeollak bindo | ll_assimilation |
| vocab_a1_0328 | 알레르기 | alrereugi | allereugi | ll_assimilation |
| vocab_a1_0336 | 미리 연락 | miri yeonrak | miri yeollak | ll_assimilation |
| vocab_a1_0348 | 분리배출 | bunribaechul | bullibaechul | ll_assimilation |
| vocab_a1_0394 | 실례하다 | silryehada | sillyehada | ll_assimilation |
| vocab_a2_0407 | 스타일리스트 | seutailriseuteu | seutailliseuteu | ll_assimilation |
| vocab_a2_0413 | 관리사무소 | gwanrisamuso | gwallisamuso | ll_assimilation |
| vocab_b1_0384 | 손님 사전 알림 | sonnim sajeon alrim | sonnim sajeon allim | ll_assimilation |
| vocab_b1_0386 | 빨래 순서 | ppalrae sunseo | ppallae sunseo | ll_assimilation |
| vocab_b1_0410 | 열람 | yeolram | yeollam | ll_assimilation |
| vocab_b1_0423 | 비상 연락망 | bisang yeonrakmang | bisang yeollangmang | ll_assimilation, nasalization |
| vocab_b1_0429 | 알림장 | alrimjang | allimjang | ll_assimilation |
| vocab_b2_0542 | 관리단 | gwanridan | gwallidan | ll_assimilation |
| vocab_b2_0604 | 감정 분리 | gamjeong bunri | gamjeong bulli | ll_assimilation |
| vocab_c1_0076 | 신뢰 구간 | sinroe gugan | silloe gugan | ll_assimilation |
| vocab_c1_0084 | 잠정 결론 | jamjeong gyeolron | jamjeong gyeollon | ll_assimilation |
| vocab_c1_0143 | 결정 환류 | gyeoljeong hwanryu | gyeoljeong hwallyu | ll_assimilation |
| vocab_c2_0125 | 증거 제출란 | jeunggeo jechulran | jeunggeo jechullan | ll_assimilation |
| vocab_c2_0143 | 열람 창구 | yeolram changgu | yeollam changgu | ll_assimilation |
| vocab_c2_0228 | 플랫폼 권력 | peullaetpom gwollyeok | peullaetpom gwonnyeok | ll_assimilation, nasalization |
| vocab_a2_0467 | 관리비 내역 | gwanribi naeyeok | gwallibi naeyeok | ll_assimilation |

### nasalization (71 rows)

| id | korean | before | after | rule |
|---|---|---|---|---|
| vocab_a1_0169 | 처음 뵙겠습니다 | cheoeum boepgesseumnida | cheoeum boepgetseumnida | nasalization |
| vocab_a2_0121 | 동료 | dongryo | dongnyo | nasalization |
| vocab_b1_0063 | 업로드하다 | eoprodeuhada | eomnodeuhada | nasalization |
| vocab_b1_0065 | 다운로드 | daunrodeu | daunnodeu | nasalization |
| vocab_b1_0067 | 협력하다 | hyeoryeokhada | hyeomnyeokada | aspiration_merge, nasalization |
| vocab_b2_0090 | 독립하다 | dongniphada | dongnipada | aspiration_merge, nasalization |
| vocab_b2_0402 | 감정을 억누르다 | gamjeongeul eongneureuda | gamjeongeul eongnureuda | nasalization |
| vocab_b2_0412 | 심란하다 | simranhada | simnanhada | nasalization |
| vocab_b2_0425 | 범람하다 | beomramhada | beomnamhada | nasalization |
| vocab_c1_0021 | 반례를 들다 | ballyereul deulda | bannyereul deulda | nasalization |
| vocab_c2_0018 | 맥락을 전복하다 | maengnageul jeonbokhada | maengnageul jeonbokada | aspiration_merge, liaison, nasalization |
| vocab_c2_0022 | 서사가 맞물리다 | seosaga matmullida | seosaga manmullida | ll_assimilation, nasalization |
| vocab_b2_0299 | 뒷사람을 위해 정리하다 | dwitsarameul wihae jeongrihada | dwitsarameul wihae jeongnihada | liaison, nasalization |
| vocab_c1_0028 | 가능성과 확률을 구분하다 | ganeungseonggwa hwakryureul gubunhada | ganeungseonggwa hwangnyureul gubunhada | liaison, nasalization |
| vocab_c1_0037 | 일회성 행사로 끝나다 | ilhoeseong haengsaro kkeutnada | ilhoeseong haengsaro kkeunnada | nasalization |
| vocab_a1_0212 | 인사드리겠습니다 | insadeurigessseubnida | insadeurigetseumnida | nasalization |
| vocab_a1_0222 | 잘 부탁드립니다 | jal butagdeuribnida | jal butakdeurimnida | nasalization |
| vocab_a1_0234 | 답례 | dabrye | damnye | nasalization |
| vocab_a1_0239 | 윗목 | wismog | winmok | nasalization |
| vocab_a1_0240 | 아랫목 | araesmog | araenmok | nasalization |
| vocab_a1_0255 | 국물 | gugmul | gungmul | nasalization |
| vocab_a1_0290 | 막내 | magnae | mangnae | nasalization |
| vocab_a1_0299 | 잘 다녀오겠습니다 | jal danyeoogessseubnida | jal danyeoogetseumnida | nasalization |
| vocab_a1_0300 | 잘 먹었습니다 | jal meogeossseubnida | jal meogeotseumnida | liaison, nasalization |
| vocab_a2_0331 | 김치 국물 | gimchi gugmul | gimchi gungmul | nasalization |
| vocab_a2_0339 | 국물 새다 | gugmul saeda | gungmul saeda | nasalization |
| vocab_a2_0354 | 존댓말 유지 | jondaesmal yuji | jondaenmal yuji | nasalization |
| vocab_a2_0359 | 존댓말 버릇 | jondaesmal beoreus | jondaenmal beoreut | nasalization |
| vocab_a2_0361 | 서로 존댓말 | seoro jondaesmal | seoro jondaenmal | nasalization |
| vocab_a2_0363 | 존댓말 실수 | jondaesmal silsu | jondaenmal silsu | nasalization |
| vocab_b1_0289 | 한국어 능력 | hangugeo neungryeog | hangugeo neungnyeok | liaison, nasalization |
| vocab_b1_0333 | 실수 목록 | silsu mogrog | silsu mongnok | nasalization |
| vocab_b1_0337 | 감정 정리 | gamjeong jeongri | gamjeong jeongni | nasalization |
| vocab_b1_0351 | 존댓말 채팅 | jondaesmal chaeting | jondaenmal chaeting | nasalization |
| vocab_b1_0353 | 공백만 보내다 | gongbaegman bonaeda | gongbaengman bonaeda | nasalization |
| vocab_b2_0443 | 상견례 | sanggyeonrye | sanggyeonnye | nasalization |
| vocab_b2_0471 | 축문 | chugmun | chungmun | nasalization |
| vocab_b2_0500 | 도와드리겠습니다 | dowadeurigessseubnida | dowadeurigetseumnida | nasalization |
| vocab_c2_0050 | 침묵 압력 | chimmug abryeog | chimmuk amnyeok | nasalization |
| vocab_c2_0058 | 권력을 호명하다 | gwonryeogeul homyeonghada | gwonnyeogeul homyeonghada | liaison, nasalization |
| vocab_a1_0316 | 받는 사람 | batneun saram | banneun saram | nasalization |
| vocab_a1_0367 | 준비됐나요 | junbidwaetnayo | junbidwaennayo | nasalization |
| vocab_a2_0383 | 통장정리 | tongjangjeongri | tongjangjeongni | nasalization |
| vocab_a2_0399 | 근력 | geunryeok | geunnyeok | nasalization |
| vocab_a2_0405 | 앞머리 | apmeori | ammeori | nasalization |
| vocab_a2_0411 | 옆머리 | yeopmeori | yeommeori | nasalization |
| vocab_a2_0416 | 음식물 봉투 | eumsikmul bongtu | eumsingmul bongtu | nasalization |
| vocab_a2_0432 | 근로계약 | geunrogyeyak | geunnogyeyak | nasalization |
| vocab_b1_0415 | 처리 완료 | cheori wanryo | cheori wannyo | nasalization |
| vocab_b1_0423 | 비상 연락망 | bisang yeonrakmang | bisang yeollangmang | ll_assimilation, nasalization |
| vocab_b1_0450 | 수리 완료증 | suri wanryojeung | suri wannyojeung | nasalization |
| vocab_b2_0531 | 역량 기술 | yeokryang gisul | yeongnyang gisul | nasalization |
| vocab_b2_0555 | 인용 맥락 | inyong maekrak | inyong maengnak | liaison, nasalization |
| vocab_b2_0557 | 익명 제보 | ikmyeong jebo | ingmyeong jebo | nasalization |
| vocab_b2_0566 | 회의 기록문 | hoeui girokmun | hoeui girongmun | nasalization |
| vocab_b2_0619 | 반례 찾기 | banrye chatgi | bannye chatgi | nasalization |
| vocab_b2_0622 | 출처 목록 | chulcheo mokrok | chulcheo mongnok | nasalization |
| vocab_c1_0107 | 익명화 수준 | ikmyeonghwa sujun | ingmyeonghwa sujun | nasalization |
| vocab_c1_0124 | 우회 경로 | uhoe gyeongro | uhoe gyeongno | nasalization |
| vocab_c1_0125 | 보조 인력 | bojo inryeok | bojo innyeok | nasalization |
| vocab_c1_0157 | 운영 인력 | unyeong inryeok | unyeong innyeok | liaison, nasalization |
| vocab_c2_0073 | 담론 전제 | damron jeonje | damnon jeonje | nasalization |
| vocab_c2_0109 | 명령형 공지 | myeongryeonghyeong gongji | myeongnyeonghyeong gongji | nasalization |
| vocab_c2_0121 | 이의 경로 | iui gyeongro | iui gyeongno | nasalization |
| vocab_c2_0139 | 입력 스냅샷 | ipryeok seunaepsyat | imnyeok seunaepsyat | nasalization |
| vocab_c2_0140 | 감사 독립 | gamsa dokrip | gamsa dongnip | nasalization |
| vocab_c2_0156 | 종료 경로 | jongryo gyeongro | jongnyo gyeongno | nasalization |
| vocab_b2_0631 | 인력 부족 | illyeok bujok | innyeok bujok | nasalization |
| vocab_c2_0223 | 인력의 도구화 | illyeogui doguhwa | innyeogui doguhwa | liaison, nasalization |
| vocab_c2_0228 | 플랫폼 권력 | peullaetpom gwollyeok | peullaetpom gwonnyeok | ll_assimilation, nasalization |
| vocab_c2_0240 | 권력 비대칭 | gwollyeok bidaeching | gwonnyeok bidaeching | nasalization |

### palatalization (4 rows)

| id | korean | before | after | rule |
|---|---|---|---|---|
| vocab_a1_0291 | 맏이 | madi | maji | palatalization |
| vocab_a2_0312 | 같이 웃다 | gati usda | gachi utda | palatalization |
| vocab_b1_0331 | 같이 자면 | gati jamyeon | gachi jamyeon | palatalization |
| vocab_a1_0342 | 같이 걷다 | gati geotda | gachi geotda | palatalization |

## Manual review needed

### Ambiguous liaison vs. ㄴ-insertion (146 rows)

A coda sits directly before an unlinked y-glide/이 syllable. This module defaults to plain liaison (matches 특약 -> teugyak); a native compound reading (like 알약 -> allyak) would need a lexical override. Jin: please confirm each word's reading.

| id | korean | flagged word(s) |
|---|---|---|
| vocab_a1_0121 | 맛있다 | 맛있다 |
| vocab_a2_0036 | 할인 | 할인 |
| vocab_a2_0083 | 많이 | 많이 |
| vocab_a2_0085 | 같이 | 같이 |
| vocab_b1_0020 | 원인 | 원인 |
| vocab_b1_0036 | 참여하다 | 참여하다 |
| vocab_b1_0049 | 효율적이다 | 효율적이다 |
| vocab_b2_0026 | 적용하다 | 적용하다 |
| vocab_b2_0029 | 추상적이다 | 추상적이다 |
| vocab_b2_0030 | 구체적이다 | 구체적이다 |
| vocab_b2_0031 | 객관적이다 | 객관적이다 |
| vocab_b2_0032 | 주관적이다 | 주관적이다 |
| vocab_a1_0158 | 월요일 | 월요일 |
| vocab_a1_0161 | 목요일 | 목요일 |
| vocab_a1_0162 | 금요일 | 금요일 |
| vocab_a1_0164 | 일요일 | 일요일 |
| vocab_a1_0173 | 별말씀을요 | 별말씀을요 |
| vocab_a1_0175 | 잠시만요 | 잠시만요 |
| vocab_b1_0068 | 책임지다 | 책임지다 |
| vocab_b1_0090 | 책임 | 책임 |
| vocab_b1_0096 | 적극적이다 | 적극적이다 |
| vocab_b1_0097 | 소극적이다 | 소극적이다 |
| vocab_b1_0098 | 책임감 | 책임감 |
| vocab_b2_0059 | 분야 | 분야 |
| vocab_b2_0064 | 인용하다 | 인용하다 |
| vocab_b2_0068 | 본질적이다 | 본질적이다 |
| vocab_b2_0072 | 합리적이다 | 합리적이다 |
| vocab_b2_0076 | 재활용 | 재활용 |
| vocab_b1_0121 | 놀이공원 | 놀이공원 |
| vocab_b1_0130 | 환율 | 환율 |
| vocab_b1_0139 | 신용카드 | 신용카드 |
| vocab_b1_0162 | 안약 | 안약 |
| vocab_b1_0167 | 신입사원 | 신입사원 |
| vocab_b1_0178 | 집들이 | 집들이 |
| vocab_b1_0182 | 결혼기념일 | 결혼기념일 |
| vocab_b1_0183 | 신혼여행 | 신혼여행 |
| vocab_b1_0193 | 번역하다 | 번역하다 |
| vocab_b2_0103 | 출입 | 출입 |
| vocab_b2_0173 | 윷놀이 | 윷놀이 |
| vocab_b2_0189 | 섞이다 | 섞이다 |
| vocab_a2_0170 | 귀걸이 | 귀걸이 |
| vocab_a2_0208 | 옷걸이 | 옷걸이 |
| vocab_a2_0236 | 군인 | 군인 |
| vocab_b1_0267 | 마감일 | 마감일 |
| vocab_b2_0256 | 관용어 | 관용어 |
| vocab_b2_0411 | 서정적이다 | 서정적이다 |
| vocab_b2_0269 | 피드백을 반영하다 | 반영하다 |
| vocab_b2_0271 | 마감이 촉박하다 | 마감이 |
| vocab_b2_0273 | 수정을 책임지다 | 책임지다 |
| vocab_b2_0278 | 출처를 확인하다 | 확인하다 |
| vocab_b2_0279 | 맥락이 빠지다 | 맥락이 |
| vocab_b2_0284 | 기록이 남다 | 기록이 |
| vocab_b2_0288 | 교차 확인하다 | 확인하다 |
| vocab_c1_0005 | 기준을 일괄 적용하다 | 적용하다 |
| vocab_c1_0012 | 참여 장벽을 낮추다 | 참여 |
| vocab_c1_0013 | 표본이 치우치다 | 표본이 |
| vocab_c1_0020 | 해석이 엇갈리다 | 해석이 |
| vocab_c2_0004 | 책임 소재를 가리다 | 책임 |
| vocab_c2_0011 | 부작용을 상쇄하다 | 부작용을 |
| vocab_c2_0012 | 시행착오를 줄이다 | 줄이다 |
| vocab_b2_0292 | 소음이 복도까지 들리다 | 소음이 |
| vocab_b2_0296 | 안내문을 눈에 띄게 붙이다 | 붙이다 |
| vocab_b2_0298 | 이용 규칙을 다시 확인하다 | 확인하다 |
| vocab_b2_0301 | 연락이 뜸해지다 | 연락이 |
| vocab_b2_0302 | 혼자 있을 시간이 필요하다 | 시간이, 필요하다 |
| vocab_c1_0036 | 책임 있게 정정하다 | 책임 |
| vocab_c1_0043 | 장기적인 효과를 따지다 | 장기적인 |
| vocab_c1_0044 | 기존 시설을 활용하다 | 활용하다 |
| vocab_c1_0046 | 참여를 꾸준히 끌어내다 | 참여를 |
| vocab_c2_0027 | 책임을 개인에게 돌리다 | 책임을 |
| vocab_c2_0031 | 이름을 붙일 권한을 갖다 | 붙일 |
| vocab_c2_0044 | 책임을 시스템 탓으로 돌리다 | 책임을 |
| vocab_a1_0219 | 높임말 | 높임말 |
| vocab_a1_0221 | 몇 살이세요 | 살이세요 |
| vocab_a1_0253 | 맛있어요 | 맛있어요 |
| vocab_a1_0265 | 새해 복 많이 받으세요 | 많이 |
| vocab_a1_0281 | 솔잎 | 솔잎 |
| vocab_a1_0291 | 맏이 | 맏이 |
| vocab_a1_0298 | 촬영 금지 | 촬영 |
| vocab_a2_0271 | 직업이 뭐예요 | 직업이 |
| vocab_a2_0312 | 같이 웃다 | 같이 |
| vocab_a2_0324 | 코골이 | 코골이 |
| vocab_a2_0360 | 나이 확인 | 확인 |
| vocab_b1_0294 | 통역 없이 | 없이 |
| vocab_b1_0303 | 다시 확인하다 | 확인하다 |
| vocab_b1_0325 | 코골이 사과 | 코골이 |
| vocab_b1_0326 | 발소리를 죽이다 | 죽이다 |
| vocab_b1_0331 | 같이 자면 | 같이 |
| vocab_b1_0346 | 공지 확인 | 확인 |
| vocab_b2_0437 | 처가살이 | 처가살이 |
| vocab_b2_0458 | 높여 부르다 | 높여 |
| vocab_a1_0323 | 복용 시간 | 복용 |
| vocab_a1_0342 | 같이 걷다 | 같이 |
| vocab_a1_0360 | 색연필 | 색연필 |
| vocab_a1_0399 | 잠깐만요 | 잠깐만요 |
| vocab_a2_0387 | 입금 확인 | 확인 |
| vocab_a2_0420 | 재활용실 | 재활용실 |
| vocab_a2_0448 | 확인서 | 확인서 |
| vocab_a2_0457 | 운영시간 | 운영시간 |
| vocab_b1_0374 | 읽음 확인 | 확인 |
| vocab_b1_0379 | 수신 확인 | 확인 |
| vocab_b1_0402 | 특약 | 특약 |
| vocab_b1_0426 | 현장 책임자 | 책임자 |
| vocab_b1_0427 | 봉사 확인서 | 확인서 |
| vocab_b1_0438 | 담임 선생님 | 담임 |
| vocab_b2_0548 | 전입 날짜 | 전입 |
| vocab_b2_0555 | 인용 맥락 | 인용 |
| vocab_b2_0559 | 사실 확인 | 확인 |
| vocab_b2_0582 | 이해 확인 | 확인 |
| vocab_b2_0601 | 약속 불이행 | 불이행 |
| vocab_b2_0607 | 책임 소재 | 책임 |
| vocab_b2_0608 | 현장 확인 | 확인 |
| vocab_b2_0610 | 종결 확인 | 확인 |
| vocab_b2_0614 | 교차 확인 | 확인 |
| vocab_b2_0616 | 인용 형식 | 인용 |
| vocab_c1_0111 | 잔여 위험 | 잔여 |
| vocab_c1_0127 | 대기 불이익 | 불이익 |
| vocab_c1_0133 | 참여 장벽 | 참여 |
| vocab_c1_0135 | 대리 참여 | 참여 |
| vocab_c1_0142 | 참여 피로 | 참여 |
| vocab_c1_0152 | 공유 편익 | 편익 |
| vocab_c1_0157 | 운영 인력 | 운영 |
| vocab_c2_0074 | 은유 체계 | 은유 |
| vocab_c2_0080 | 인용 권위 | 인용 |
| vocab_c2_0092 | 관행 인용 | 인용 |
| vocab_c2_0093 | 책임 분산 | 책임 |
| vocab_c2_0114 | 권위 인용 | 인용 |
| vocab_c2_0144 | 책임 매핑 | 책임 |
| vocab_c2_0152 | 철회 확인서 | 확인서 |
| vocab_c1_0180 | 인용 | 인용 |
| vocab_c1_0183 | 부작용 | 부작용 |
| vocab_c2_0208 | 낙인 | 낙인 |
| vocab_b2_0633 | 팬 번역 | 번역 |
| vocab_b2_0634 | 참여 방식 | 참여 |
| vocab_c1_0228 | 맥락 번역 | 번역 |
| vocab_c2_0218 | 책임 귀속 | 책임 |
| vocab_a1_0414 | 주소를 확인하다 | 확인하다 |
| vocab_a2_0463 | 시간이 되다 | 시간이 |
| vocab_a1_0419 | 지하철역 | 지하철역 |
| vocab_a1_0422 | 영수증 확인 | 확인 |
| vocab_c1_0238 | 번역 노동 | 번역 |
| vocab_c2_0235 | 책임 주체 | 책임 |
| vocab_a1_0429 | 독일 | 독일 |
| vocab_a1_0431 | 외국인 | 외국인 |
| vocab_a1_0433 | 독일어 | 독일어 |
| vocab_a2_0483 | 끓이다 | 끓이다 |

### 체언 ㅎ-aspiration heuristic applies (69 rows)

A stop+ㅎ or ㅎ+stop syllable boundary exists; the POS-based `is_cheoneon_pos` heuristic (Nomen/Ausdruck/Pronomen/Phrase/Adverb -> keep ㅎ, Verb/Verbphrase/Adjektiv -> merge) decided the outcome below. Flagged regardless of whether the row's romanization changed, since a wrong POS classification would silently produce the wrong reading either way.

| id | korean | pos_de | flagged word(s) | current romanization |
|---|---|---|---|---|
| vocab_a1_0115 | 좋다 | Adjektiv | 좋다 | jota |
| vocab_a2_0044 | 도착하다 | Verb | 도착하다 | dochakada |
| vocab_a2_0046 | 기억하다 | Verb | 기억하다 | gieokada |
| vocab_a2_0052 | 예약하다 | Verb | 예약하다 | yeyakada |
| vocab_a2_0063 | 행복하다 | Adjektiv | 행복하다 | haengbokada |
| vocab_b1_0035 | 노력하다 | Verb | 노력하다 | noryeokada |
| vocab_b1_0037 | 선택하다 | Verb | 선택하다 | seontaekada |
| vocab_b1_0040 | 극복하다 | Verb | 극복하다 | geukbokada |
| vocab_b1_0046 | 복잡하다 | Adjektiv | 복잡하다 | bokjapada |
| vocab_b1_0048 | 정확하다 | Adjektiv | 정확하다 | jeonghwakada |
| vocab_b1_0054 | 특히 | Adverb | 특히 | teukhi |
| vocab_b2_0016 | 분석하다 | Verb | 분석하다 | bunseokada |
| vocab_b2_0023 | 인식하다 | Verb | 인식하다 | insikada |
| vocab_b2_0024 | 해석하다 | Verb | 해석하다 | haeseokada |
| vocab_b2_0025 | 반박하다 | Verb | 반박하다 | banbakada |
| vocab_b2_0028 | 지속하다 | Verb | 지속하다 | jisokada |
| vocab_a2_0117 | 답답하다 | Adjektiv | 답답하다 | dapdapada |
| vocab_b1_0064 | 검색하다 | Verb | 검색하다 | geomsaekada |
| vocab_b1_0067 | 협력하다 | Verb | 협력하다 | hyeomnyeokada |
| vocab_b1_0091 | 솔직하다 | Adjektiv | 솔직하다 | soljikada |
| vocab_b1_0101 | 약속하다 | Verb | 약속하다 | yaksokada |
| vocab_b2_0050 | 양극화 | Nomen | 양극화 | yanggeukhwa |
| vocab_b2_0070 | 명확하다 | Adjektiv | 명확하다 | myeonghwakada |
| vocab_a2_0160 | 저축하다 | Verb | 저축하다 | jeochukada |
| vocab_b1_0166 | 취직하다 | Verb | 취직하다 | chwijikada |
| vocab_b1_0173 | 합격하다 | Verb | 합격하다 | hapgyeokada |
| vocab_b1_0174 | 모집하다 | Verb | 모집하다 | mojipada |
| vocab_b1_0175 | 지각하다 | Verb | 지각하다 | jigakada |
| vocab_b1_0185 | 참석하다 | Verb | 참석하다 | chamseokada |
| vocab_b1_0193 | 번역하다 | Verb | 번역하다 | beonyeokada |
| vocab_b1_0196 | 대답하다 | Verb | 대답하다 | daedapada |
| vocab_b1_0208 | 섭섭하다 | Adjektiv | 섭섭하다 | seopseopada |
| vocab_b1_0209 | 심각하다 | Adjektiv | 심각하다 | simgakada |
| vocab_b1_0242 | 졸업하다 | Verb | 졸업하다 | joreopada |
| vocab_b1_0243 | 입학하다 | Verb | 입학하다 | ipakada |
| vocab_b2_0090 | 독립하다 | Verb | 독립하다 | dongnipada |
| vocab_b2_0184 | 간직하다 | Verb | 간직하다 | ganjikada |
| vocab_a2_0258 | 닫히다 | Verb | 닫히다 | dachida |
| vocab_b2_0229 | 타협하다 | Verb | 타협하다 | tahyeopada |
| vocab_b2_0259 | 완곡하다 | Adjektiv | 완곡하다 | wangokada |
| vocab_b2_0261 | 정착하다 | Verb | 정착하다 | jeongchakada |
| vocab_b2_0262 | 오해를 낳다 | Verbphrase | 낳다 | ohaereul nata |
| vocab_b2_0267 | 의견을 좁히다 | Verb | 좁히다 | uigyeoneul jopida |
| vocab_b2_0270 | 역할을 나누다 | Verb | 역할을 | yeokareul nanuda |
| vocab_b2_0271 | 마감이 촉박하다 | Adjektiv | 촉박하다 | magami chokbakada |
| vocab_b2_0275 | 의견을 완곡하게 전하다 | Verb | 완곡하게 | uigyeoneul wangokage jeonhada |
| vocab_c1_0016 | 상관관계를 인과로 해석하다 | Verb | 해석하다 | sanggwangwangyereul ingwaro haeseokada |
| vocab_c2_0017 | 암시를 포착하다 | Verb | 포착하다 | amsireul pochakada |
| vocab_c2_0018 | 맥락을 전복하다 | Verb | 전복하다 | maengnageul jeonbokada |
| vocab_c2_0021 | 인물에 이입하다 | Verb | 이입하다 | inmure iipada |
| vocab_b2_0307 | 기분을 솔직히 말하다 | Verb | 솔직히 | gibuneul soljiki malhada |
| vocab_b2_0308 | 답장을 재촉하지 않다 | Verb | 재촉하지 | dapjangeul jaechokaji anda |
| vocab_c2_0037 | 결정 과정을 추적하다 | Verb | 추적하다 | gyeoljeong gwajeongeul chujeokada |
| vocab_c2_0040 | 편향을 증폭하다 | Verb | 증폭하다 | pyeonhyangeul jeungpokada |
| vocab_a1_0232 | 백화점 상품권 | Nomen | 백화점 | baekhwajeom sangpumgwon |
| vocab_a1_0258 | 수저 놓다 | Ausdruck | 놓다 | sujeo notda |
| vocab_a2_0358 | 아직 어색해요 | Ausdruck | 어색해요 | ajik eosaekhaeyo |
| vocab_b1_0282 | 솔직한 선 | Nomen | 솔직한 | soljikhan seon |
| vocab_b1_0297 | 요약해서 전하다 | Ausdruck | 요약해서 | yoyakhaeseo jeonhada |
| vocab_b1_0307 | 직접 대답하다 | Ausdruck | 대답하다 | jikjeop daedaphada |
| vocab_b2_0433 | 며느리 역할 | Nomen | 역할 | myeoneuri yeokhal |
| vocab_c1_0052 | 역할 언어 | Nomen | 역할 | yeokhal eoneo |
| vocab_a1_0387 | 습하다 | Adjektiv | 습하다 | seupada |
| vocab_a1_0396 | 부탁하다 | Verb | 부탁하다 | butakada |
| vocab_a2_0438 | 습득하다 | Verb | 습득하다 | seupdeukada |
| vocab_b1_0388 | 문 닫힘 | Nomen | 닫힘 | mun dathim |
| vocab_c2_0101 | 집합 기억 | Ausdruck | 집합 | jiphap gieok |
| vocab_c1_0188 | 역효과 | Nomen | 역효과 | yeokhyogwa |
| vocab_a1_0444 | 시작하다 | Verb | 시작하다 | sijakada |

