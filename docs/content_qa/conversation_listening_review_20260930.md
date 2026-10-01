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
3. `vocab_example_review_20260930.md`의 승인 지문 실패는 2026-10-01에 초안 복구와 후속 카피 리비전 기록으로 해소했다. 시나리오·스몰토크의 위 후보를 **아직 런타임에 일괄 적용하지는 않았다.** 장면별 의미를 확정한 수정에 대해 승격 검증과 앱 테스트를 다시 실행한다. 사람 승인 원장은 모델 판단으로 덮지 않는다.
