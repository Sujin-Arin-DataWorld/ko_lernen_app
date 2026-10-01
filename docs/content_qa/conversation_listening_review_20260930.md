# 대화·스몰토크·듣기 삼언어 검수: 2026-09-30

## 범위와 상태

앱의 시나리오 178개와 대응 듣기 lesson 178개의 텍스트 연결을 검사했다. `audioKo`와 `evidenceKo`는 모두 해당 시나리오 대사에 정확히 존재한다. 이는 정답의 화용적 타당성이나 MP3 청취 품질 보증이 아니다. A1–B1의 뜻·응답 정답은 대사를 직접 재사용하는 편이고, B2–C2는 추론형 답이 있어 문자열 불일치만으로 오답 판정하지 않았다. 아래는 실제 문장을 읽어 찾은 **모델 검수 후보**다. 캐릭터 관계·승인 원장과 대조하지 않은 W10 장면은 특히 사람 승인으로 표시하지 않는다.

## 시나리오와 파생 듣기

| 레벨·시나리오 | 현재 문제 | 제안·파생 범위 |
| --- | --- | --- |
| A1 `a1_w10_eat` 대사 4 | KO `여기서 드시고 가세요, 아니면 포장이세요?`는 명령과 질문이 섞이고, DE `hier essen`은 아직 커피만 주문한 장면에서 음식을 가정한다. | KO `여기서 드시나요, 아니면 포장이세요?`; EN `For here or to go?`; DE `Für hier oder zum Mitnehmen?`. 대사·시나리오 어휘/퀘스트·TTS 영향 확인. |
| A1 `a1_w10_fandom` | 소개문 DE `Du gehst ... und schaut`는 주어·동사 불일치. `Lieblingssänger`는 한국어 `가수`만으로 성별이 정해지지 않는다. | 소개문 `Du gehst mit Maya in einen Fan-Shop und ihr schaut euch Alben eures Lieblingsstars an.` 대사/듣기 뜻·상황 정답/퀘스트의 성별 지칭도 한 묶음으로 확인. |
| A2 `running_late` | 소개문 KO/EN/DE는 지하철이 **멈췄다**고 하지만 대사 첫 줄은 **늦는다**고만 말한다. | KO `지하철이 늦어서 약속에 늦게 됐어요.` / EN `The subway is delayed, so you're running late.` / DE `Die U-Bahn hat Verspätung, deshalb kommst du zu eurer Verabredung zu spät.` 듣기 소개·상황 정답/해설 동기화. 대사 TTS 변경 없음. |
| A2 `a2_w10_enrolment` 대사 7 | 다음 줄의 매월 10만 원은 일회성 `등록비/Anmeldegebühr`보다 수강료다. | KO `다행이에요. 수강료는 얼마예요?` / EN `That's good to know. How much does the class cost?` / DE `Gut zu wissen. Was kostet der Kurs?`. 듣기 문장·오디오 키·문장 만들기 퀘스트 함께 갱신. |
| B1 `park_pet_manners` 대사 3 | EN `he's fine`은 성별 미상인 반려견을 수컷으로 지정한다. | KO·DE 유지, EN `Yes, the dog is fine.` 앞뒤 대사도 성별 가정 점검. |
| B1 `cancelled_trip_hurt_feelings` 대사 4 | 앞의 표 변경과 `원래 표를 취소하기 전에`의 예약 상태가 모순처럼 보인다. | 예약 상태를 저자에게 확인할 **FLAG**. 변경 전에는 듣기 문장/응답·퀘스트·TTS를 임의로 고치지 않는다. |
| B2 `fremdschaemen_live` 대사 3–4 | KO의 `직원`은 성별 미상인데 EN `he`, DE `der Mitarbeiter/er`가 남성을 추가한다. | EN `they/the employee`, DE `die Person vom Personal`처럼 장면에서 허용되는 중립 지시어 사용. 듣기 소개·상황 선택지의 지칭도 확인. |
| B2 `feedback_specific_example` 대사 0·1·4 | 선배 Andrea의 프로필은 DE `Sie`인데 이 장면은 `dir/du`다. KO는 해요/습니다로 이어진다. | DE `Ihnen/Sie`로 장면 전체 통일; 듣기 뜻 선택지·퀘스트에도 반영. 관계 설정이 실제로 친밀한 `du`로 바뀌었다는 근거가 나오면 장면 메타데이터부터 고친다. |
| C1 `heatwave_shelter_access` 대사 0 | KO `기준보다 많다`는 법적 의무를 말하지 않는데 EN `requires`, DE `vorgeschrieben`은 의무를 추가한다. | EN `more heat shelters than the benchmark number`; DE `mehr Hitzeschutzräume, als der Richtwert vorsieht`. 듣기 뜻 정답·퀘스트 반영. 실제 기준 수치는 검증하지 않음. |
| C1 `gentrification_storefront` 대사 1 | KO `옆 가게가 나갔다`는 영업 폐업을 뜻하지 않는데 DE `musste ... schließen`이 폐업으로 만든다. | DE `Das Nachbargeschäft musste wegen der Miete letzten Monat die Räume verlassen.` KO·EN 유지. |
| C2 `automated_benefit_denial` 대사 2 | KO/EN은 잘못된 거절을 **구제**할 책임인데 DE `schützen`은 사전 보호로 바뀐다. | DE `Kürzere Bearbeitungszeiten beseitigen nicht die Verantwortung, fehlerhafte Ablehnungen zu korrigieren.` 법적 의무의 범위는 별도 사실 검증. |
| C2 `autonomous_delivery_liability` 대사 1 | KO는 현장 배치 **담당자의 판단 실수**로 책임을 좁히려는 발화인데 EN/DE는 비인칭 `deployment error`로 만든다. | EN `If we call it a misjudgment by the person in charge of on-site deployment, we'd have a clear responsible party.` / DE `Wenn wir den Fall als Fehlentscheidung der für den Einsatz vor Ort zuständigen Person einordnen, hätten wir eine eindeutig verantwortliche Person.` |

## 스몰토크·미디어·발음의 우선 항목

| ID | 확인한 차이와 조치 |
| --- | --- |
| `smalltalk_a1_0001` | KO `날씨 좋네요.`는 진술, DE·EN은 동의를 구하는 꼬리 질문이다. KO에 `그렇죠?`를 더할지, 번역의 `oder?/huh?`를 뺄지 lesson 목적과 함께 결정. |
| `smalltalk_a1_0004` | KO `주말에 뭐 해요?`는 문맥상 습관 질문으로 읽을 수 있고 답도 `보통 집에서 쉬어요`다. DE 단일 주말 해석을 피하려고 `Was machst du normalerweise am Wochenende?`로 교정했다. KO·EN 및 TTS는 유지. **앱 반영.** |
| `smalltalk_a2_0032` | KO `자소서`는 지원자의 자기소개서, DE `Anschreiben`·EN `cover letter`와 문서 유형이 다르다. 한국 취업 맥락을 유지한다면 `personal statement`와 독일어 설명적 표현을 검토하고 문화 메모를 붙인다. |
| `smalltalk_b1_0001` | KO `딱 좋죠`는 동의를 청하지만 기존 번역은 단정이었다. DE `..., oder?`, EN `..., isn't it?`로 화행을 맞췄다. **앱 반영.** |
| `smalltalk_c2_0029` | `close_friend`인데 DE는 `du`, KO는 질문·대답에 `-세요`/`제`가 섞여 있다. 친한 관계가 정본이면 KO 말투를 장면 전체에서 맞추고 TTS 갱신. |
| `media_001` | `오늘 하루도 수고했어`의 위로·노고 인정이 EN `long day`, DE 문장 조각으로 사라졌다. 위로하는 발화로 다시 쓴다. |
| `media_084` | `확정 대기`는 대기명단 `Warteliste/waitlist`가 아니다. 승인/확정 결과를 기다리는 상태로 DE·EN을 고치고 연결된 B1 어휘·Satz·Cloze를 확인. |
| `media_085` | KO `마감이 늦어지는`은 마감일이 움직이는지 제출이 늦는지 불명확하다. DE는 제출 지연, EN은 기한을 놓침으로 갈린다. B1 어휘·발음 문장과 의도를 먼저 잠근다. |
| `media_096` | KO에는 `댓글과 행사 참여 방식` 두 대상과 **같은** 조회수가 있는데 DE·EN에서 댓글이 빠지고 EN은 `similar`로 약해진다. B2 어휘·Satz·Cloze 동기화. |
| `media_100` | `신청 자격`은 지원할 자격인데 DE `Anspruch`는 수급권으로 강화한다. C1 어휘·Satz·Cloze와 `Berechtigung zur Antragstellung` 같은 뜻을 검토. |
| `media_105` | 일반 `이의 제기`를 DE `Widerspruch`, EN `appeal`로 특정 법적 절차처럼 만들었다. C2 어휘·Satz·Cloze에서 제도 맥락 확인. |
| `pronunciation_b2_0004` | EN은 KO에 없는 `equipment`를 도입. `use must be stopped immediately`처럼 대상을 열어 둔다. |
| `pronunciation_c1_0006` | KO `월세`가 DE `Kaltmiete`·EN `base rent`로 좁아졌다. 해당 시나리오·Satz/Cloze에서 실제 순수 임대료를 뜻하는지 확인. |
| `pronunciation_c2_0003` | KO `인간 검토자`는 한 사람, DE `menschliche Prüfstelle`는 기관이다. `eine menschliche prüfende Person` 또는 문맥에 맞는 `eine Person`으로 바로잡는다. |

## 추가 직접 검수

### A1 시나리오·듣기 직접 검수 1–2차 묶음 (2026-10-01)

승인된 A1 정본 시나리오 20개를 대사별 KO·EN·DE로 읽고 연결된 듣기
80문항의 근거 발화, 정답 선택지와 오답 선택지를 대조했다. 80문항에서
정답 인덱스가 대사의 내용·지정된 응답 과제와 어긋나는 사례는 찾지 못했다.
이는 **이 20개 장면의 모델 검수**이며 나머지 158개 듣기 lesson의 의미
검수나 사람 승인이 아니다. 응답 문항이 첫 대사만 제시하는 경우는 장면의
후속 대사와 별개로 해당 과제에 맞춰 판단했다.

| 장면·대사 | 직접 확인한 차이와 다음 조치 |
| --- | --- |
| A1 `bakery_payment_bag` 2 | KO `빵 두 개`는 빵 종류를 특정하지 않는데 EN `two pastries`, DE `zwei Brötchen`은 각각 페이스트리·브뢰첸으로 좁힌다. 장면에 품목 정보가 없으므로 `That's two, right?` / `Zwei Stück, richtig?`처럼 계산대 문맥에서 중립적으로 말할 수 있다. 듣기 뜻 문항의 이 대사 오답 선택지도 함께 바꿔야 한다. |
| A1 `bakery_payment_bag` 5 | KO `그럼 이건 따로 드릴게요`의 점원이 따로 **건네는** 동작을 EN `I'll keep this one separate`가 보관하는 동작으로 바꾼다. `Then I'll give you this one separately.`가 의미를 보존한다. DE도 점원 발화로 자연스럽게 다듬을 여지가 있다. |
| A1 `favorite_korean_music` 5 | KO `그 노래만 들어요`의 `-만`은 배타적이다. EN `almost all`, DE `fast nur`는 이를 약화한다. EN `Yes, that's the only song I've been listening to lately.` / DE `Ja, zurzeit höre ich nur dieses Lied.`가 발화와 듣기 응답 과제의 뜻에 맞는다. |
| A1 `break_glass_apology` 5 | `큰 것만 모아 주세요`는 깨진 잔 조각을 어떻게 안전하게 치울지 명시하지 않는다. 문항 정답 자체는 앞말에 맞지만 실제 행동 안내처럼 오해될 수 있어 저자에게 도구·처리 방법을 확인할 **FLAG**로 남긴다. |
| A1 `home_morning_routine` 소개·0 | KO `교통카드`와 EN `transit card`는 충전식 교통카드인데 DE `Fahrkarte`는 대개 승차권으로 읽힌다. 소개의 `verschwunden`도 KO `안 보여요`보다 분실을 강하게 시사한다. 독일어에 카드 성격과 찾는 중이라는 상황을 살려, 연결된 듣기 상황 정답·해설도 함께 고친다. |
| A1 `mart_grocery` 1 | KO `냉장고 옆`은 위치 기준이 냉장고인데 EN `refrigerated section`, DE `Kühlregal`은 매장 구역·진열대로 달라진다. 실제 매장 그림/배경의 지시 대상을 확인한 뒤 세 언어의 위치 기준을 통일한다. |
| A1 `subway_step_apology` 4 | KO `제가 못 봤어요`와 EN `I didn't see you`는 상대를 보지 못했다는 사과인데 DE `Ich habe nicht aufgepasst`는 부주의를 인정하는 다른 진술이다. DE `Ich habe Sie nicht gesehen. Ich passe künftig besser auf.`처럼 뜻과 존칭을 함께 유지할 수 있다. |
| A1 `survival_day_capstone` 5 | DE `Wir nehmen meinen zusammen`은 우산을 함께 쓰자는 말로 어색하다. `Wir können meinen Schirm zusammen benutzen.`처럼 완결된 제안으로 다듬는다. 앞서 상대에게 우산이 없다고 들었으므로 화자의 우산을 제안한다는 추론은 장면에 맞는다. |
| A1 `taxi_kakao` 소개 | KO `앱에 찍은 곳 근처에 도착했어요`는 목적지 근처에 이미 도착한 상태다. EN/DE `almost at the destination`/`fast am Ziel angekommen`은 아직 도착 전이다. `You've reached the area near the destination you entered in the app.`와 그에 맞는 DE 표현으로 시점을 맞추고 듣기 상황 정답도 동기화한다. |

이 20개 장면은 승인된 canonical 후보에 속한다. 위 제안은 모델의 카피
교정 후보이며 기존 Jin 승인 해시를 수정하거나 승인된 저작 원본을 덮지 않았다.
실제 문구를 바꾸려면 canonical 카피 변경 이력, 런타임 시나리오, 듣기 선택지,
필요한 경우 TTS 키를 같은 변경으로 검증해야 한다.

### A1 나머지 런타임 장면·듣기 직접 검수 (2026-10-01)

정본 20개 밖에 있는 A1 런타임 장면 9개와 연결된 듣기 36문항도 대사,
정답·오답, 응답 과제를 직접 대조했다. 이로써 A1 런타임 29개와 듣기
116문항을 모두 한 번씩 읽었다. 36문항의 정답 선택지가 대사와 어긋나는
사례는 찾지 못했으며, 기존 표의 `a1_w10_eat`·`a1_w10_fandom` 후보는
그대로 유효하다. 이는 문장 의미와 문항 논리를 살핀 모델 검수이며 실제
음성의 발음·억양 또는 학습자 이해도 검증은 아니다.

| 장면·대사 | 직접 확인한 차이와 다음 조치 |
| --- | --- |
| A1 `a1_w10_repeat` 소개 | KO `잘 못 들어서`와 대사 `잘 못 들었어요`는 청취 실패인데 DE `nicht ganz verstanden`는 말을 들었지만 이해하지 못한 상태일 수 있다. `Du hast die Apothekerin nicht richtig gehört und bittest sie, es langsam zu wiederholen.`처럼 청취 상황을 유지하고 듣기 상황 정답도 같이 고친다. 약사 성별은 캐릭터 설정을 확인한다. |
| A1 `a1_w10_partner` 5–6 | 크리스티안이 처음 뵙는 수진의 어머니께 인사하지만 어머니는 발화하지 않고, 수진이 곧바로 `엄마도 정말 반가워하세요`라며 어머니의 반응을 전달한다. 어머니의 실제 응답·몸짓이 없는 상태라 대화 연결이 부자연스럽다. 캐릭터 관계를 확인한 뒤 어머니의 짧은 응답이나 서술을 넣을지 결정한다. 화자·대사를 바꾸면 TTS도 다시 만든다. |
| A1 `a1_w10_wayfinding` 소개 | KO `지나가는 사람`, EN `passerby`는 성별을 정하지 않는데 DE `einen Passanten`은 남성 보행자를 가정한다. 오답 선택지에서 이미 쓰는 `eine vorbeigehende Person`을 소개와 듣기 상황 정답에도 쓰면 중립성이 맞는다. |

### A2 시나리오·듣기 직접 검수 1차 묶음 (2026-10-01)

`clothing_refund_size`부터 `gym_class_cancel`까지 A2 런타임 장면 10개를
KO·EN·DE 대사별로 읽고 연결된 듣기 40문항의 근거 발화, 정답과 오답,
응답 과제를 대조했다. 정답 선택지가 대사·과제와 어긋난 사례는 없었다.
아래 두 항목은 문장 자체와 수업 운영 의미를 별도로 확인한 결과다.

| 장면·대사 | 직접 확인한 차이와 다음 조치 |
| --- | --- |
| A2 `favorite_drama_chat` 듣기 응답 과제 | KO `자연스러운 대화가 좋은 이유라고 하세요`는 수식 관계가 어색해 학습자에게 무엇을 답하라는지 흐려진다. 저작 원본의 과제를 `보고 있는 드라마를 말하고 대사가 자연스러워서 좋다고 하세요`로 고치고, 생성된 듣기 문제·해설을 갱신했다. DE·EN 과제와 한국어 대사·TTS는 유지. **앱 반영.** |
| A2 `gym_class_cancel` 2 | KO `오늘 수업을 취소할까요?`, EN `cancel today's class`, DE `den heutigen Kurs stornieren`은 강사나 운영자가 전체 수업을 취소하는 말처럼 들린다. 발목이 아픈 학습자 **한 명의 예약**을 옮기는 상황이므로, 예약 취소·변경을 뜻하도록 세 언어를 다듬어야 한다. 수업 자체가 취소된다는 인상을 주는 듣기 번역·선택지도 함께 확인한다. |

### A2 시나리오·듣기 직접 검수 2–3차 묶음 (2026-10-01)

`jeju_bus_missed`부터 `a2_w10_fandom`까지 남은 A2 장면 18개와 듣기
72문항의 KO·EN·DE 대사, 정답·오답, 응답 과제를 대조했다. 이로써 A2
런타임 28개 장면과 듣기 112문항을 모두 한 번씩 직접 읽었다. 정답 인덱스
오류는 발견하지 못했지만 과제 문구 1건을 바로잡았고, 아래의 장면 의미·
연속성 문제를 확인했다. 구조 검사만으로 이 판정을 대체하지 않았다.

| 장면·대사 | 직접 확인한 차이와 다음 조치 |
| --- | --- |
| A2 `running_late` 소개 | 위 첫 표의 후보처럼 소개 KO/EN/DE는 지하철이 **멈췄다**고 하지만 대사는 단지 **지연**이라고 말한다. 세 언어 소개와 듣기 상황 정답에서 멈춤을 단정하지 않도록 고친다. |
| A2 `samgyeopsal_first_time` 2 | KO `이쪽은 괜찮아요?`와 EN `Is this side okay?`는 고기 **이쪽 면**을 가리키는데 DE `Ist dieses Stück fertig?`는 고기 **한 조각 전체**로 대상을 바꾼다. `Ist diese Seite schon durch?`처럼 지시 대상을 보존한다. |
| A2 `a2_theme_park_date_break` 3–4·받아쓰기 | KO `당이 당겨`는 `단 게 당겨`보다 어색하고, 화자가 설탕이 든 단 음료를 원한다고 한 직후 상대가 **제로콜라**를 권한다. KO·EN·DE 대사, `제로콜라` 어휘, 받아쓰기, TTS를 하나의 카피 리비전으로 고쳐야 한다. 이 팩의 2026-08-30 승인 원본을 그대로 새 문구 승인으로 간주하지 않는다. 현재는 런타임 대사와 승인 초안을 수정하지 않았다. |
| A2 `train_seat_swap` 듣기 응답 과제 | KO 과제가 `자리를 잘못 본 것을 인정`하라고 했지만 정답 대사 `알려 주셔서 감사합니다. 바로 옮길게요.`에는 그 인정이 직접 나오지 않는다. 과제를 `자리를 알려 준 사람에게 감사하고 바로 옮기겠다고 하세요`로 바꾸고 듣기 문제·해설을 재생성했다. DE·EN 과제, 대사와 TTS는 유지. **앱 반영.** |
| A2 `a2_w10_buy` 5 | KO `계란 한 판`과 EN `a tray of eggs`는 한 판 단위인데 DE `eine Packung Eier`는 수량이 훨씬 작은 일반 포장으로 읽힐 수 있다. 상품 단위를 확인하고 독일어로 수량을 드러내는 자연스러운 표현을 검토한다. |
| A2 `a2_w10_apt` 소개·2 | KO `분리수거 요일`과 EN `recycling days`는 배출/수거 가능한 날인데 DE `Tage zum Mülltrennen`, `den Müll trennen`은 집에서 쓰레기를 **분류하는 행위**로 읽힌다. 장면은 배출 요일·상자 놓을 곳을 묻는 상황이므로 독일어의 행동을 배출/가져다 놓기로 맞춘다. |
| A2 `a2_w10_partner` 소개 | A1 `a1_w10_partner`에서 크리스티안은 이미 수진 어머니를 처음 만났다. A2 소개의 KO `부모님을 처음 뵙기`, EN `meeting Sujin's parents for the first time`, DE `zum ersten Mal ihre Eltern ... trifft`는 그 연속성과 충돌한다. 첫 만남 단정을 빼고 추석 방문 전에 예절을 묻는 것으로 세 언어를 맞춘다. 연결된 듣기 상황 정답도 동기화한다. |
| A2 `a2_w10_enrolment` 7 | 위 첫 표의 후보처럼 매월 내는 금액은 일회성 등록비보다 **수강료**다. 대사·듣기·문장 만들기·TTS를 함께 고친다. |
| A2 `a2_w10_friends` 5 | KO `근처에 있을 것 같은데`와 EN `I think she's nearby`는 추측인데 DE `Sie ist bestimmt in der Nähe`는 더 강한 확신이다. `Ich glaube, sie ist in der Nähe`처럼 양태 강도를 유지한다. |

**A2 후속 반영:** `samgyeopsal_first_time`의 독일어는 고기의
`한 조각` 대신 `이쪽 면`을 가리키게 고쳤다. `running_late`의
소개는 지하철이 멈췄다고 단정하지 않고 지연이라고 말하도록
KO·EN·DE를 맞췄다. 저작 원본·런타임 장면·듣기 문제를 함께 갱신했다.
두 수정은 한국어 대사를 바꾸지 않아 새 대사 TTS 키가 필요하지 않다.
`gym_class_cancel`의 예약 취소 표현도 수정안을 만들었으나,
시나리오 문구 변경이 기존 can-do 승인 지문과 충돌해 런타임 적용은
보류했다. 승인 이력을 임의로 갱신하지 않고 별도 후속 검토가 필요하다.

이어 A2 `a2_w10_friends`의 독일어 확신을 추측으로 낮추고,
`a2_w10_buy`의 계란 `한 판`을 독일어에서도 30개 포장으로 명시했다.
`a2_w10_apt`의 독일어는 집 안에서 쓰레기를 분류하는 동작 대신
분리한 쓰레기를 내놓는 요일과 행동을 말하게 했다.
`a2_w10_partner`의 소개에서는 이미 만난 수진 어머니와의 관계를
고려해 `첫 만남` 단정을 세 언어에서 뺐다. `a2_w10_enrolment`의
매월 내는 돈은 `등록비`에서 `수강료`로 바로잡고 어휘 단서·대사·
문장 만들기·듣기 문제를 동기화했다. 한국어 대사 변경분의 TTS 키는
합성·Storage에 업로드하고 정본 12,646개 기준 누락 0개를 확인했다.
W10의 기존 승인 초안은 바꾸지 않았다.

Smalltalk `smalltalk_a2_0032`의 `자소서`는 지원자의 자기소개 글이다.
EN `personal statement for the job application`, DE `Selbstvorstellung
für die Bewerbung`으로 옮기고 번역 수정 원장에 기록했다. KO 질문·
대답과 TTS는 유지했다. 두 번역 모두 한국의 지원서 문서 유형을
설명적으로 전달한 모델 검수안이며, 현지 원어민 승인 상태는 아니다.

### B1 시나리오·듣기 직접 검수 1차 묶음 (2026-10-01)

`shared_document_old_version`부터 `jeju_rain_plan_change`까지 B1 장면 10개와
듣기 40문항을 대사·상황·근거·정답·오답·응답 과제별로 읽었다. 정답 인덱스가
다른 선택지를 가리키는 문제는 찾지 못했다. 문항 과제가 실제 정답에 없는
대조를 요구하던 1건은 아래와 같이 고쳤다.

| 장면·대사 | 직접 확인한 차이와 다음 조치 |
| --- | --- |
| B1 `shared_document_old_version` 2 | KO `어제 내려받아서 몰랐어`는 무엇을 몰랐는지, 어제 내려받은 일이 왜 모르는 이유인지 흐리다. EN `I downloaded it yesterday and didn't realize`도 목적어가 빠져 장면 밖에서는 미완결처럼 들린다. 공유 문서라고 착각한 사실을 명시하되 새 원인을 만들지 않는 KO 정본을 먼저 잠근다. 대사·듣기·TTS 동기화 필요. |
| B1 `birthday_expectation_gap` 듣기 응답 과제 | 기존 KO·EN·DE 과제는 큰 모임과 저녁 식사를 **대조해 말하라**고 했지만 정답 대사는 `수진이랑 저녁 먹는 건 정말 좋아요`만 말한다. 세 언어 과제를 수진과 저녁 먹고 싶다고 안심시키는 것으로 좁혀 듣기 문제·해설을 재생성했다. 한국어 대사와 TTS는 유지. **앱 반영.** |
| B1 `cancelled_trip_hurt_feelings` 0·4 | 앞의 승인 후보처럼 `오후 표로 바꿨어`와 `원래 표를 취소하기 전에`가 표의 실제 변경·취소 상태를 충돌시킨다. 예약 상태를 저자에게 확인하기 전에는 사실관계를 임의로 고치지 않는다. |
| B1 `community_festival_shift` 0 | KO `축제 봉사 담당입니다`와 EN `festival volunteer coordinator`는 사람이 자기 역할을 소개하는데 DE `Hier ist die Einsatzplanung für das Fest`는 계획 부서 자체가 전화를 받은 듯하다. 역할을 가진 화자의 자연스러운 독일어 자기소개로 다듬는다. |
| B1 `date_or_friendly_coffee` 소개·0 | KO `친구`와 EN `a friend`는 성별 미상인데 DE `Eine Freundin`이 여성으로 정한다. `Jemand aus eurem Freundeskreis`처럼 불필요한 성별 부여 없이 장면을 유지한다. 듣기 상황 정답도 같은 소개문을 사용한다. |
| B1 `jeju_rain_plan_change` 0 | KO `취소됐대`와 EN `They say ... was canceled`는 전언인데 DE `Die Fähre wurde ... abgesagt`는 직접 확인한 사실처럼 단정한다. 독일어에서도 **들은 소식**이라는 정보 출처를 남기는 구어 표현을 정한다. 듣기 원문 뜻과 근거를 함께 점검한다. |

### B1 시나리오·듣기 직접 검수 2차 묶음 (2026-10-01)

`ktx_sold_out_alternative`부터 `team_update_indirect_speech`까지 B1
장면 10개와 듣기 40문항의 세 언어 대사·정답·오답·응답 과제를 읽었다.
정답 인덱스 오류는 찾지 못했다. 다음은 원문에 없는 속성이나 매체가
번역에 들어간 경우와 학습 목표 표현을 흐리게 한 경우다.

| 장면·대사 | 직접 확인한 차이와 다음 조치 |
| --- | --- |
| B1 `park_pet_manners` 3 | 위 첫 표처럼 KO `네, 괜찮아요`는 강아지 성별을 말하지 않는데 EN `he's fine`은 수컷으로 정한다. EN에서 `The dog is fine`처럼 지시 대상을 성별 없이 유지한다. |
| B1 `secondhand_hidden_defect` 4·6 | KO `촬영 일`은 촬영 업무인데 EN `paid shoots`가 **유급**임을 더한다. 뒤의 KO `설명이 부족했네요`는 판매자가 자기 설명의 부족함을 인정하는데 EN `The listing should have been clearer`와 DE `Die Beschreibung war wohl nicht ausführlich genug`는 책임을 수동적 문서 쪽으로 옮기고 DE는 불확실성까지 더한다. 세 언어에서 업무 목적과 판매자의 인정 정도를 맞춘다. |
| B1 `shared_cup_recycling` 2 | KO `개인 컵`과 DE `eigene Becher`는 각자 자기 컵을 쓰자는 말인데 EN `reusable cups`는 공용 재사용 컵도 포함한다. EN `our own cups`처럼 소유·사용 주체를 유지한다. |
| B1 `speech_level_after_friendship` 0 | KO `말 놓을까?`를 DE `zum Du-Ton auf Koreanisch wechseln`로 설명하면 한국어 높임 전체가 독일어 du/Sie 전환과 같다는 오해를 줄 수 있다. `auf Koreanisch weniger förmlich miteinander sprechen` 같은 독일어 표현을 장면·학습 목표와 대조한다. |
| B1 `subscription_cancel_charge` 1 | KO `해지 완료 화면을 봤는데`는 사용자가 화면에서 본 사실이고, DE `wurde mir die Kündigung bestätigt`는 사업자가 **확인해 줬다**는 더 강한 출처다. 화면에서 무엇을 보았는지로 DE를 맞춘다. |
| B1 `team_update_indirect_speech` 소개·0 | KO `연락했어요`는 연락 수단 미상인데 DE `hat geschrieben`은 문자·이메일로 특정한다. 연락 매체를 만들지 않는 독일어로 쓰고 듣기 상황 정답도 같은 의미로 바꾼다. |

### B1 시나리오·듣기 직접 검수 3차 묶음 (2026-10-01)

`work_message_too_direct`부터 `b1_w10_fandom`까지 남은 B1 장면 11개와
듣기 44문항의 세 언어 대사·근거·정답·오답·응답 과제를 읽었다. 이로써
B1 런타임 31개 장면과 듣기 124문항을 모두 한 번씩 직접 대조했다.
정답 인덱스 오류는 발견하지 못했다. 다음 표현은 자연성 또는 제도적
사실의 근거가 부족해 모델 단독 승인으로 닫지 않는다.

| 장면·대사 | 직접 확인한 차이와 다음 조치 |
| --- | --- |
| B1 `b1_w10_bill` 4 | KO `한 잔 값은 취소`는 중복 **결제 금액**의 취소인데 DE `den zweiten Kaffee stornieren`은 음료 주문 자체를 취소하는 말처럼 읽힌다. `die zweite Berechnung rückgängig machen` 등 결제 정정을 직접 가리키는 독일어를 검토한다. 다음 줄의 환불과 연결한다. |
| B1 `b1_w10_partner` 4 | KO `너랑 있는 시간은 항상 좋아`는 함께 보내는 시간을 즐긴다는 말이다. EN `The time with you is always nice`, DE `Die Zeit mit dir ist immer schön`은 이해는 되지만 번역투다. EN `I always enjoy spending time with you.`, DE `Ich verbringe immer gern Zeit mit dir.`처럼 상대를 안심시키는 자연스러운 말로 다듬는다. |
| B1 `b1_w10_insurance` 3 | KO `진단서랑 영수증만 있으면 대부분 보장돼요`는 특정 검사·상품 확인 전인데 서류 둘만 있으면 보장된다고 단정한다. [손해보험협회 소비자 안내](https://consumer.knia.or.kr/m/consumer/insurance-guide/0202.do)는 청구 유형·금액에 따라 요구 서류가 달라진다고 설명한다. 보장 여부와 제출 서류를 가입 상품·검사 내용에서 확인하는 대화로 다시 써야 하며, 듣기 뜻·응답·TTS도 함께 고친다. 현재 문구의 사실성을 사람/보험 실무 검수 없이 승인하지 않는다. |
| B1 `b1_w10_form` 4–6 | 외국인등록증 주소 변경에서 계약서 사본을 우편·이메일로 나중에 내도 되고 마감이 월말이라는 절차는 장면 안의 임의 규칙인지 실제 행정절차인지 불명확하다. 실제 한국 제도 안내로 읽힐 수 있으므로 관할 기관·절차 근거를 확인하거나 명시적으로 가상 안내 상황으로 재설계한다. |
| B1 `b1_w10_cancellation` 3·5 | 헬스장 해지의 한 달 전 신청과 잔여 기간별 수수료를 모든 계약의 규칙처럼 말한다. 특정 계약 조건을 먼저 잠그고, 듣기 정답이 일반 법적 권리 안내로 읽히지 않게 한다. |
| B1 `b1_w10_fandom` 소개 | EN `fails at concert ticketing`과 DE `scheitert beim Konzert-Ticketing`은 한국어 `티켓팅에 실패해서`를 직역한 느낌이다. 상대 언어에서 콘서트 표를 구하지 못했다는 뜻을 자연스럽게 재구성하고, 용어의 현재 팬덤 용례는 확인 후 반영한다. |

**B1 후속 반영:** `community_festival_shift`의 독일어 전화
자기소개는 축제 봉사 담당자라는 화자를 드러내고,
`date_or_friendly_coffee`의 `친구`는 독일어에서 성별을 추정하지
않도록 했다. `jeju_rain_plan_change`는 독일어에서도 들은 소식임을
남겼다. `park_pet_manners`의 영어 강아지 성별 추정,
`shared_cup_recycling`의 컵 소유 주체, `speech_level_after_friendship`의
한국어 말 놓기를 독일어 du/Sie 전환으로 단순화한 표현을 각각
고쳤다. `subscription_cancel_charge`는 화면에서 본 사실을,
`team_update_indirect_speech`는 수단을 특정하지 않은 연락을
독일어로 보존했다. W10 장면에서는 함께 보내는 시간을 즐긴다는
말, 중복 결제 금액 취소, 콘서트 표를 구하지 못한 상황을 EN·DE에서
자연스럽게 고쳤다. 저작 원본이 있는 장면은 원본·런타임·듣기를
동기화했고, W10의 승인 초안은 보존했다. 한국어 대사는 유지되어
이 묶음만으로 새 대사 TTS 키가 생기지 않았다.

### B2 시나리오·듣기 직접 검수 1차 묶음 (2026-10-01)

`accessible_festival_route`부터 `fremdschaemen_live`까지 B2 장면
10개와 듣기 40문항의 삼언어 대사·상황 추론·정답·오답·응답 교정을
대조했다. B2부터는 상황과 응답이 같은 핵심 추론을 반복할 수 있어,
문자열보다 실제 대사가 그 추론을 허가하는지 확인했다.

| 장면·대사 | 직접 확인한 차이와 다음 조치 |
| --- | --- |
| B2 `community_event_compromise` 3 | KO `주말 하루`, EN `one weekend day`는 토요일·일요일을 열어 두는데 DE `einen Samstag`는 토요일로 좁힌다. `an einem Tag am Wochenende`처럼 선택 범위를 유지하고 관련 듣기 뜻 오답 선택지에도 반영한다. |
| B2 `feedback_specific_example` 전체 | 위 첫 표의 후보처럼 선배 Andrea의 프로필은 DE `Sie`인데 장면 독일어는 `dir/du`를 쓴다. 관계 설정과 호칭을 확인한 뒤 장면·듣기 선택지의 존칭을 통일한다. |
| B2 `fremdschaemen_live` 1–4 | 위 첫 표처럼 KO `직원`의 성별이 미상인데 DE `Mitarbeiter/er`, EN `he`가 남성으로 특정한다. DE 3의 `lächele nur deshalb`도 웃은 이유를 확정적으로 덧붙인다. 사람·행동·확신을 유지하는 중립 표현으로 장면을 다듬는다. |
| B2 `fremdschaemen_live` 듣기 상황·응답 정답 | 기존 정답은 직원의 웃음이 **촬영 요청** 동의를 입증하지 못한다고 했지만, 대사의 쟁점은 직원에게 한 **춤 요청**이었다. `직원의 웃음만으로 춤 요청에 동의했다고 단정할 수 없어요.` / `The employee's smile doesn't mean they agreed to dance.` / `Dass die Person gelächelt hat, heißt nicht, dass sie dem Tanz zugestimmt hat.`로 생성 원본을 고쳐 두 문항의 정답·해설을 갱신했다. 음성 대사는 유지. **앱 반영.** |

### B2 시나리오·듣기 직접 검수 2차 묶음 (2026-10-01)

`library_quiet_zone_conflict`부터 `wedding_invitation_expectation`까지
장면 10개와 듣기 40문항의 KO·DE·EN 대사, 근거, 상황·뜻·문장·응답 과제를
대조했다. 듣기 정답 인덱스 오류는 찾지 못했다. 아래 차이는 승인된 장면
대사와 파생 듣기를 같은 카피 리비전에서 수정해야 한다.

| 장면·대사 | 직접 확인한 차이와 다음 조치 |
| --- | --- |
| B2 `library_quiet_zone_conflict` 소개 | KO는 표지를 놓친 뒤 온라인 회의 도중 항의를 받은 상황인데 DE `weil du ... übersehen hast`는 표지를 놓친 **것이 온라인 회의를 한 이유**인 듯 읽힌다. EN/DE의 `small/kleine`도 KO에는 없는 표지 크기다. 표지를 못 본 채 통화 금지 구역에서 온라인 회의 중이라는 사건 순서로 세 언어를 맞춘다. |
| B2 `meeting_opening_context` 4 | KO `필요한 자료`와 EN `information we need`를 DE `nötigen Zahlen`으로 좁혀 **수치 자료**로 만든다. `Unterlagen` 또는 `Informationen`처럼 회의에 필요한 자료의 열린 범위를 유지한다. |
| B2 `partner_family_titles` 소개·문항 | A1 `a1_w10_partner`에서 크리스티안이 이미 수진의 어머니를 만났으므로, 여기서 다시 **부모님을 처음 만난다**고 하는 소개와 듣기 응답 프롬프트는 연속성에 어긋난다. 수진 아버지와의 첫 만남인지, 부모님과의 새 가족 식사인지 장면 관계를 먼저 정한 뒤 세 언어를 고친다. A2 `a2_w10_partner`도 같은 연속성 문제다. |
| B2 `portfolio_interview_gap` 1 | DE `an freien Kooperationen gearbeitet`는 프리랜서 일/협업을 뜻하기보다 느슨한 협력 형태처럼 들리고, EN `did freelance collaborations`도 번역투다. 실제로 포트폴리오에 넣을 수 있는 협업 프로젝트를 했다는 뜻으로 직업 어휘를 자연스럽게 쓴다. |
| B2 `recycling_policy_pilot` 소개 | KO `새 배출 기기`는 폐기물 종류를 말하지 않는데 DE `Biomüllgerät`, EN `food-waste machine`이 **음식물 쓰레기**로 특정한다. 실제 장면 소품이 음식물 배출 기기인지 확인한 뒤 KO에 명시하거나 번역에서 범주를 열어 둔다. |
| B2 `train_delay_connection` 0·3·듣기 | 첫 대사는 **다음 열차 예약 변경**을 물으나 직원은 KO/EN `좌석 변경`, DE `Umbuchung des Sitzplatzes`만 확인하겠다고 해 같은 일을 가리키는지 불명확하다. KO `보상`/EN `compensation`보다 DE `Erstattung`은 **환불**로 좁다. 예약 번호가 다른 두 표에 대한 직원 권한도 명시되지 않았다. 교통사업자의 실제 권한을 단정하지 않는 대사로 뜻을 먼저 확정하고 듣기 추론을 동기화한다. |
| B2 `wedding_invitation_expectation` 0–1·5·듣기 | KO `동료`는 성별 미상인데 DE `Kollegin`, EN `her wedding/her`가 여성으로 정한다. KO `평소 얼마나 가까워요?`/EN `How close ...?`는 관계의 친밀도를 묻지만 DE `Wie eng arbeitet ihr ... zusammen?`는 **함께 일하는 정도**만 묻는다. 듣기 뜻 문제의 DE 정답과 마지막 독일어 문장도 원문보다 더 좁거나 성별을 추가한다. 성별 미상 표현과 사회적 친밀도 질문으로 되돌린다. |

### B2 시나리오·듣기 직접 검수 3차 묶음 (2026-10-01)

`b2_theme_park_date_safety`부터 `b2_w10_fandom`까지 마지막 B2 장면
10개와 듣기 40문항을 세 언어 대사·뜻·상황 추론·정답·오답·응답 과제별로
대조했다. 이로써 B2 런타임 30개 장면과 듣기 120문항을 모두 직접
읽었다. 정답 인덱스 오류는 발견하지 못했다. 다음은 번역·장면 논리와
제도/건강 정보에 대한 후속 교정 항목이다.

| 장면·대사 | 직접 확인한 차이와 다음 조치 |
| --- | --- |
| B2 `b2_theme_park_date_safety` 5 | KO `아까 커피 마신 자리`와 EN `where we had coffee`는 장소를 넓게 열어 두는데 DE `bei unserem Kaffeeplatz`는 어색하다. `an dem Platz, wo wir vorhin Kaffee getrunken haben`처럼 추측과 장소를 자연스럽게 유지한다. |
| B2 `b2_w10_notice` 2–6 | **같은 사진 근거를 이미 제출**해 기각됐고 직원이 `같은 근거로는 재심사가 어렵다`고 말한 뒤, 다시 **같은 사진과 통화 내용**을 첨부하면 된다고 설명한다. 새로 달라진 근거나 별도의 공식 재심 절차가 없어서 인과가 약하다. 실제 주정차 이의제기 제도를 확인하고, 적법한 절차와 새로운 검토 쟁점을 설정해야 한다. 듣기 정답·TTS까지 연결된 장면이다. |
| B2 `b2_w10_health` 0–6 | 처방약을 `하루 세 번` 먹으라고 한 직후 특정 항히스타민제는 `저녁에만` 복용해도 된다고 단정한다. 약품명·처방 내용을 제시하지 않고 약사가 다른 약으로 바꾸며 `효과는 똑같다`고 보장한다. [식약처 항히스타민제 안내](https://www.mfds.go.kr/webzine/202403/sub03.html)는 졸음과 성분 확인·전문가 상담을 강조한다. 복용량 변경·대체 약의 동등 효과를 학습자에게 일반 지침처럼 들리게 하지 않도록 의약 전문가 검토와 장면 재작성 후 음성·문항을 재생성한다. |
| B2 `b2_w10_authorities` 2·6 | `만료 4개월 전부터`는 [법무부 안내](https://www.immigration.go.kr/bbs/immigration/220/565871/artclView.do)와 부합하지만, `만료일 전까지`는 전자민원과 방문 신청의 마감 차이를 생략한다. 공식 안내는 방문은 만료 당일, 전자민원은 전일까지라고 구분하며 **필요 서류는 체류자격별로 다르다**([법무부 FAQ](https://www.immigration.go.kr/bbs/immigration/47/426384/download.do)). `잔고가 부족하면 등록금 영수증으로 대체`를 모든 유학생에게 적용하는 근거는 확인되지 않았다. 자격·신청 방식·서류를 지정하거나 특정 수치/서류를 제거해야 한다. |
| B2 `b2_w10_privacy` 2–5 | 모든 결제 내역의 완전 삭제와 복구 불가능을 사업자가 바로 약속한다. [개인정보 포털의 정정·삭제 안내](https://www.privacy.go.kr/front/contents/cntntsView.do?contsNo=196)는 다른 법령상 보존 의무 등 예외를 둔다. 서비스 화면에서 지우는 기록과 법정 보존 기록을 구분해 대사·듣기 문항을 다시 써야 한다. |
| B2 `b2_w10_fandom` 소개 | KO `모금액 공개 범위`는 총액 공개 수준을 뜻하나 EN `how much of the donation total`과 DE `wie viel von der Spendensumme`은 총액 중 **얼마만 공개할지**로 읽힐 수 있다. 총액을 정확히 공개할지 범위만 공개할지의 방식 문제로 명확히 쓴다. |

### C1 시나리오·듣기 직접 검수 (2026-10-01)

C1의 `after_hours_messages`부터 `c1_w10_fandom`까지 런타임
30개 장면의 KO·DE·EN 대사를 읽었다. 앞의 20개 장면은 연결된 듣기
80문항의 추론·뜻·문장·응답 문구를, 마지막 10개 장면은 연결된 듣기
40문항의 정답·오답·근거를 대조했다. 정답 인덱스 오류는 찾지 못했다.
C1에서는 학술적 신중함, 수치의 한계, 출처·양태와 이해충돌 뒤의
행동이 문장 자체에 살아 있는지를 우선 봤다. 다음은 확정된 의미 차이와
장면 논리 문제다. 기존 첫 표의 `heatwave_shelter_access`와
`gentrification_storefront` 지적도 이번 직접 읽기에서 다시 확인했다.

| 장면·대사 | 직접 확인한 차이와 다음 조치 |
| --- | --- |
| C1 `ai_interview_screening_transparency` 5 | KO `이의 제기`, EN `appeal`은 평가에 반론을 제기하는 절차인데 DE `Rückfrage`는 단순 **문의**다. `Einwand` 또는 `Widerspruch` 중 장면의 실제 절차에 맞는 말을 택하고 문장 조립 뜻도 동기화한다. |
| C1 `anonymous_survey_trust` 3 | KO `근속연수`와 EN `tenure ranges`는 재직 **연수**인데 DE `Dienstzeiten`은 근무 시간/기간으로도 읽힌다. `Dauer der Betriebszugehörigkeit`를 넓은 구간으로 묶는다고 명시한다. |
| C1 `delivery_rider_safety_tradeoff` 0·3 | KO `가게`는 업종을 한정하지 않는데 DE `Restaurant`, EN `restaurant`가 음식점으로 좁힌다. 배달 플랫폼의 이 장면에서 대상 업종을 정해 KO에 밝히거나 DE/EN의 범주를 열어 둔다. |
| C1 `fan_translation_credit` 3 | `실명`, `활동명`, `익명`, `아예 표기하지 않음`은 마지막 두 선택이 겹친다. 익명을 **익명 표기**(작업 기여는 남김)로 뜻한다면 그 점을 세 언어에 명시하고, 원치 않으면 무표기를 허용한다. 자발적 게시를 공식 이용 허락과 같다고 오해하지 않게 이용 동의도 별도로 설계한다. |
| C1 `nightlife_noise_balance` 0 | KO `야간 영업 이후`와 EN `after late-night hours`는 야간 영업 도입을 말하지만 DE `Seit den längeren Öffnungszeiten`는 **기존 영업시간을 연장했다**는 이력을 추가한다. 시간 연장이 확인되지 않았으므로 `Seit der Öffnung am Abend` 등으로 맞춘다. |
| C1 `research_limits_presentation` 0 | KO `도시 청년의 주거 인식이 바뀌었다`와 EN 제목은 **변화가 있었다고 단정**하는데 DE `Wie sich ... verändert`는 변화의 **방식**을 설명하는 제목이다. 연구가 입증하지 못한 단정형 제목이라는 논점이 세 언어에서 같도록 DE 제목을 고친다. |
| C1 `school_phone_rule` 1 | KO `혈당을 확인하는 앱`은 필요할 때 확인하는 앱인데 EN `monitors my blood sugar`는 **지속 모니터링** 기능까지 암시할 수 있다. 실제 학생의 의료 접근성을 나타내되 기기 기능을 임의로 확장하지 않는다. |
| C1 `training_data_copyright` 소개·1 | KO `특정 작가`/EN `a particular artist`는 성별 미상인데 DE `einer bestimmten Künstlerin`이 여성으로 특정한다. 저작권·학습데이터도 서로 다른 검토 대상이므로 유사성만으로 침해 확정이라는 인상을 피하는 현재 추론은 유지한다. |
| C1 `c1_w10_uncertainty` 0·3·8 | 작은 표본의 예측에서 `오차 범위`가 나온다고 하는데 표집 방식·계산 방법은 없다. 통계적 신뢰구간인지 단순 예측 범위인지 분명히 해야 하며, `그렇게 하면 나중에 문제 될 일도 없겠습니다`는 불확실성을 공개하면 **문제가 전혀 없을 것**이라고 과보장한다. 학술·업무 문체에 맞게 결론의 조건을 남긴다. |
| C1 `c1_w10_labor` 0·5–6 | 장면 목표는 수치에서 빠지는 **감정노동**인데 해결책은 항의 전화 **건수**만 기록한다. 통화량은 노동 강도·소요 시간·사후 업무 영향을 대변하지 못한다. 건수를 출발점으로 두더라도 응대 시간·후속 조치·업무 배분을 함께 검토하는 결말이 필요하다. |
| C1 `c1_w10_conflict_interest` 3–8·듣기 | 현아는 과거 같이 연구한 지원자 심사에서 빠지기로 했고 듣기 정답도 그렇게 설명한다. 그런데 곧바로 `이 지원자는 경력은 짧은 한편 ... 논문의 질은 높습니다`라며 **같은 지원자 평가**에 의견을 보태고 교수는 기록한다. 공개·회피 원칙과 결말이 충돌한다. 마지막 두 대사의 대상을 다른 지원자로 명시하거나, 이해관계 있는 지원자에 대한 평가 발언을 없애고 대화·듣기·TTS를 동기화해야 한다. 또한 성별 미상 KO `지원자/후배`를 DE `Bewerberin`, EN `her`로 특정한다. |
| C1 `c1_w10_clinical` 2·8 | 초기에 관찰한 이상반응을 `가벼운 두통과 어지럼증 정도`로 제한하고, 중단해도 `불이익은 전혀 없습니다`라고 모든 영향을 포괄해 말한다. 구체적 임상시험의 위험·대안·철회 후 통상 진료 권리를 구분해야 한다. [ClinicalTrials.gov에 게시된 실제 동의서 예시](https://cdn.clinicaltrials.gov/large-docs/71/NCT07408271/ICF_001.pdf)는 철회 뒤 일반 진료 권리와 안전상 후속 확인을 따로 설명한다. 이 장면은 임상의/IRB 문구 확인 전까지 의료 안내로 승인하지 않는다. |
| C1 `c1_w10_facework` 2 | KO `첫 단독 보고서라는 점에서 이 정도면 잘한 편`은 상대를 낮춰 보는 듯할 수 있고, DE `richtig gut gelungen`·EN `turned out very well`은 오히려 **강한 칭찬**으로 바뀐다. 실제 잘된 점을 구체적으로 짚고 숫자 오류를 따로 말하는 공손한 피드백으로 재작성한다. |
| C1 `c1_w10_friends` 5·8 | 현아가 식사비를 매번 냈고 형편이 빠듯하다고 털어놓는 장면에서 수진의 `서운한 소리를 듣는 한이 있어도 솔직하게 다 말할게`는 정작 자신의 책임 인정과 연결되지 않는다. 마지막 `해도 과언이 아니야`도 친한 친구의 감정 대화에서 문법표현을 끼워 넣은 듯 딱딱하다. 비용 부담을 알아차린 책임·앞으로의 구체적 제안을 먼저 드러내는 KO 대화를 잠근 뒤 DE/EN을 다시 옮긴다. |

### C2 시나리오·듣기 직접 검수 1차 묶음 (2026-10-01)

`ai_hiring_appeal`부터 `family_memory_conflict`까지 앞의 C2 장면 10개를
세 언어 대사와 듣기 추론·뜻·문장·응답 과제와 맞춰 읽었다. 정답 인덱스
오류는 찾지 못했다. 남은 C2 20개 장면과 단어 예문·게임 연동은 아직
이 단계의 검수를 완료하지 않았다.

| 장면·대사 | 직접 확인한 차이와 다음 조치 |
| --- | --- |
| C2 `autonomous_delivery_liability` 0 | KO `가게 입장`, EN `shop owner`는 성별 미상인데 DE `Geschäftsinhaber`는 남성형이다. 자연스러운 성별 중립 1인칭 `Für unser Geschäft ...`처럼 피해 주체와 책임 분리를 유지한다. |
| C2 `diaspora_name_identity` 소개·2 | KO는 본문에 한글 이름 **`준희`**를 쓰고 싶다는 당사자의 선택인데 DE/EN은 본문 이름을 **`Junhee`**로 바꾼다. 이 장면의 핵심인 선호 표기와 검색용 표기의 구분을 번역이 무너뜨린다. KO 표기를 그대로 보여 주고 필요할 때 별도 발음 도움말을 제공하는 설계를 세 언어에 맞춘다. |
| C2 `emergency_price_controls` 소개 | KO `폭우 뒤`, DE `Nach Starkregen`은 폭우 뒤 상황인데 EN `After severe flooding`은 **실제 침수**가 일어났다고 더한다. `After heavy rain`처럼 확인된 사건 범위를 유지한다. |

### C2 시나리오·듣기 직접 검수 2–3차 묶음 (2026-10-01)

`hidden_gem_local_impact`부터 `c2_w10_fandom`까지 남은 C2 장면
20개와 연결 듣기 80문항의 KO·DE·EN 대사, 정답·오답·응답 과제를
대조했다. 이로써 C2 런타임 30개 장면과 듣기 120문항을 한 차례씩
직접 읽었다. 정답 인덱스 오류는 찾지 못했다. 아래 항목은 뜻을
바꾸는 번역, 실제 법·금융 절차를 만드는 장면, 대화 내부 모순이다.

| 장면·대사 | 직접 확인한 차이와 다음 조치 |
| --- | --- |
| C2 `housing_tax_intergenerational` 0·듣기 뜻 | KO `집 없는 청년`은 이 문맥에서 **주택 미소유**이고 DE `ohne Wohneigentum`은 이를 살렸지만 EN `young people without homes`는 **주거가 없는 사람**으로 읽힌다. KO도 `집을 소유하지 않은 청년`으로 분명히 하고 EN `young people who do not own a home`으로 바꾼다. 듣기 뜻 정답과 음성까지 동기화한다. |
| C2 `protest_order_and_rights` 0·듣기 뜻 | KO `도로가 오래 막혔으니`와 DE `lange Verkehrsblockade`에는 시간 수치가 없는데 EN `blocked roads for hours`는 **몇 시간**이라고 단정한다. `blocked roads for a long time` 등으로 근거 범위를 보존한다. |
| C2 `replication_failure_response` 4·듣기 문장 | KO `결과가 달라질 수 있는 조건`과 EN `conditions ... account for the difference`는 후보 원인을 열어 두는데 DE `mögliche Moderatoren`는 통계적 **조절변수**로 좁힌다. 실제 분석 대상이 조절변수인지 확인하고 아니라면 `mögliche Bedingungen für die Abweichung`처럼 둔다. 재현 실패가 원 논문 전체를 부정하지 않는 현재 추론은 유지한다. |
| C2 `welfare_fraud_presumption` 소개 | KO `잠재적 위반자`, EN `potential offender`는 규정 위반 전반인데 DE `potenzielle Täter`는 범죄의 **가해자**라는 강한 법적·도덕적 틀이다. `potenziell Regelverletzende` 등 실제 신청 안내 문맥에 맞는 강도로 조정한다. |
| C2 `c2_w10_record` 2–6 | 화재로 등기부가 사라진 뒤 구청 기록관 직원이 세금 고지서·이웃 증언으로 소유권을 재구성할 수 있고 입증 책임은 신청인이라고 확정적으로 말한다. 등기 회복·소유권 분쟁인지 행정자료 조회인지 절차가 정해지지 않아 한국의 일반적인 법적 입증 규칙으로 가르치기 어렵다. 관할 절차를 먼저 정하거나 **기록 탐색 가능성**까지만 대화의 목표로 좁힌다. 듣기 정답의 `신청인의 입증이 필요`도 함께 재검토한다. |
| C2 `c2_w10_mandate` 3–8 | 위임장의 범위 확대 질문을 **어머니의 판단 능력이 어려워진 뒤**로 설정하고 은행 직원이 `성년후견 절차를 먼저 밟아야 한다`고 단정한다. 후견 제도는 관할 국가와 법원 판단에 좌우되며, DE `Betreuungsverfahren`도 한국의 성년후견과 그대로 같지 않다. 어머니가 없는 자리에서 은행 직원이 위임장을 `오늘 바로 작성`해 줄 수 있다는 결말도 권한·확인 절차가 빠져 있다. 특정 은행의 서류 안내와 어머니 본인의 의사 확인으로 재설계하고 법률 실무 검수를 받는다. |
| C2 `c2_w10_impact` 0–6 | **출퇴근 지원금**이 평균 통근 시간을 15분 줄였다는 결과와, 야간 근무자는 **통근 자체가 불가능**해졌다는 결론 사이에 정책의 구체적 작동 방식이 없다. 지원금 지급 시간·교통편·대상 조건 중 무엇이 야간 노동자를 제외했는지 먼저 정해야 평균과 소수 집단 비교가 설득력을 갖는다. 듣기 뜻·추론·음성을 함께 수정한다. |
| C2 `c2_w10_limitation` 전체 | 3년 전 사고의 소멸시효가 `이미 지나 청구권 자체가 사라졌다`고 단정한 직후, 언제 알았는지의 `예외 조항`과 진단서 한 장이면 신청 가능하다는 방향으로 바뀐다. 한국 [민법 제766조](https://www.law.go.kr/lsLinkCommonInfo.do?lsJoLnkSeq=1030326785)는 불법행위 손해와 가해자를 **안 날부터 3년**이라는 기산점을 규정하지만, 이 장면은 어떤 청구권·인지 시점·다른 기한인지 설정하지 않았다. 진단서가 그 인지 날짜와 사실을 입증하는지도 불명확하다. 법적 결론을 대사에서 약속하지 말고 사건 유형과 시점을 정한 뒤 법률 검수를 받아야 한다. |
| C2 `c2_w10_friends` 3·6 | 다니엘은 작업실을 **조용히 나가겠다**고 말했는데 현아는 곧 `다음 작품에도 네 이름 크게 넣을게`라고 약속한다. 다음 작품에 다니엘이 참여하는지 정해지지 않아 새 프로젝트 크레딧을 거래처럼 제안하는 결말이 어색하다. 과거 공동 작업의 기여 표기와 지분 정리, 앞으로의 우정을 각각 분리해 말한다. |
| C2 `c2_w10_fandom` 3–8 | 상업적 이용이면 계정 정지라는 규칙을 운영진이 말하므로 **이 특정 커뮤니티의 규정**임을 밝혀야 한다. 마지막에는 이견이 있으면 신고 대신 댓글을 쓰라고 권하는데, 단순한 해석 차이와 실제 규정 위반 신고를 구분하지 않으면 정당한 신고까지 억제할 수 있다. 규정 근거와 신고 기준을 장면 안에서 분명히 한다. |

### 적용된 C2 삼언어 교정 (2026-10-01)

처음 발견한 후보 중 실제 반영 범위와 검증 상태는
[`c2_review_20261001.md`](c2_review_20261001.md)에 기록했다.
`diaspora_name_identity`의 한글 이름 `준희`, `emergency_price_controls`의
폭우, `housing_tax_intergenerational`의 주택 미소유, 그 밖의 대사와
연결 듣기 문항을 동기화했다. 집 소유 관련 KO 대사와
`c2_w10_friends`의 KO 대사도 바뀌어 TTS를 갱신했다.
전문 절차가 불명확한 W10 장면은 반영 완료로 표시하지 않는다.

### 적용된 스몰토크 번역 교정 (2026-10-01)

`smalltalk_a1_0004`의 독일어 질문을 `Was machst du normalerweise am
Wochenende?`로 고쳐 수업 목표와 답변의 **평소 주말 습관**을 드러냈다.
`smalltalk_b1_0001`은 KO `-죠`가 청하는 동의를 DE `oder?`, EN `isn't it?`로
옮겼다. 두 행 모두 한국어 발화와 기존 ID·레벨·관계 설정을 유지했고,
`smalltalk_translation_corrections_20260922.json`에 원문과 변경문을 기록했다.
파생 학습 문항과 코스 지문을 재생성했다. 한국어 TTS 키는 바뀌지 않는다.
`author_smalltalk_lessons_20260922.py --check`, 코스 지문 검사, 콘텐츠 테스트
1,303건(20건 건너뜀), 관련 Flutter 테스트 21건이 통과했다. 듣기 첫 대사
음원 176개는 로컬 `assets/tts/v3/`에 이미 있어 추가 다운로드는 0개였다.

## 다음 적용 순서

1. 정본 시나리오·페르소나와 단어장 표제어/예문을 먼저 확정한다. 연결된 듣기 정답·해설, smalltalk lesson, Satz·Cloze, 발음·미디어를 같은 의미로 갱신한다.
2. 한국어 발화가 바뀐 행만 TTS manifest를 다시 생성해 새 v3 키의 MP3를 합성·다운로드하고 누락 0을 확인한다. 키 완전성은 실제 발음·억양 청취와 별개다.
3. `vocab_example_review_20260930.md`의 승인 지문 실패는 2026-10-01에 초안 복구와 후속 카피 리비전 기록으로 해소했다. 시나리오·스몰토크 후보 중 일부 번역만 개별 검증 후 적용했으며 **나머지는 아직 런타임에 일괄 적용하지 않았다.** 장면별 의미를 확정한 수정에 대해 승격 검증과 앱 테스트를 다시 실행한다. 사람 승인 원장은 모델 판단으로 덮지 않는다.
