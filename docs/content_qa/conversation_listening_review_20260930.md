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
| `smalltalk_a1_0004` | KO `주말에 뭐 해요?` / DE 단일 주말 / EN 반복 습관 `on weekends`가 다르다. 답 `보통 집에서 쉬어요`와 맞추려면 KO `주말에 보통 뭐 해요?`, DE `Was machst du normalerweise am Wochenende?`, EN 유지가 자연스럽다. KO TTS 갱신 필요. |
| `smalltalk_a2_0032` | KO `자소서`는 지원자의 자기소개서, DE `Anschreiben`·EN `cover letter`와 문서 유형이 다르다. 한국 취업 맥락을 유지한다면 `personal statement`와 독일어 설명적 표현을 검토하고 문화 메모를 붙인다. |
| `smalltalk_b1_0001` | KO `딱 좋죠`는 동의를 청하지만 번역은 단정. DE `..., oder?`, EN `..., isn't it?`처럼 화행을 맞춘다. |
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

## 적용 순서

1. 정본 시나리오·페르소나와 단어장 표제어/예문을 먼저 확정한다. 연결된 듣기 정답·해설, smalltalk lesson, Satz·Cloze, 발음·미디어를 같은 의미로 갱신한다.
2. 한국어 발화가 바뀐 행만 TTS manifest를 다시 생성해 새 v3 키의 MP3를 합성·다운로드하고 누락 0을 확인한다. 키 완전성은 실제 발음·억양 청취와 별개다.
3. `vocab_example_review_20260930.md`의 승인 지문 실패는 2026-10-01에 초안 복구와 후속 카피 리비전 기록으로 해소했다. 시나리오·스몰토크의 위 후보를 **아직 런타임에 일괄 적용하지는 않았다.** 장면별 의미를 확정한 수정에 대해 승격 검증과 앱 테스트를 다시 실행한다. 사람 승인 원장은 모델 판단으로 덮지 않는다.
