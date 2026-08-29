# C1 정본 시나리오 검토

> 자동 검사는 승인 증거가 아닙니다. 아래 20개를 모두 읽은 뒤 Jin이 결정합니다.

## 1. 퇴근 후 연락의 경계를 팀에서 정하기 (`after_hours_messages`)

- 수행 목표: 숨은 기대와 업무상 제약을 드러내며 관계를 해치지 않는 운영 원칙을 협의할 수 있다
- 관계·사건: 팀 리더 안드레아와 팀원 마야 / 퇴근 후 메신저가 반복되지만 누구도 즉시 답하라고 명시하지 않아 기대가 모호하다
- 단원: `c1_06_intimacy_safety_design`

**동료**  
KO: 퇴근 뒤 메시지가 오면 급한 건지 내일 봐도 되는 건지 모르겠어요.  
DE: Bei Nachrichten nach Feierabend weiß ich nie, ob sie dringend sind oder bis morgen warten können.  
EN: When a message comes after work, I can't tell if it's urgent or can wait until tomorrow.

**안드레아**  
KO: 시차가 있는 팀과 일해서 발송 시간을 제한하기는 어렵습니다.  
DE: Wegen der Zusammenarbeit über Zeitzonen hinweg können wir die Sendezeit kaum begrenzen.  
EN: Because we work across time zones, it's hard to restrict when messages are sent.

**마야 (나)**  
KO: 퇴근 후에 연락을 보내는 것과 바로 답해야 한다고 기대하는 것은 구분할 필요가 있어요.  
DE: Wir sollten zwischen dem Senden nach Feierabend und der Erwartung einer sofortigen Antwort unterscheiden.  
EN: We need to distinguish sending a message after work from expecting an immediate response.

**동료**  
KO: 그 기대가 표시되지 않으니 모든 메시지가 급하게 느껴져요.  
DE: Weil diese Erwartung nirgends steht, wirkt jede Nachricht dringend.  
EN: Because that expectation isn't stated, every message feels urgent.

**마야 (나)**  
KO: 급하지 않은 메시지에는 ‘내일 확인해도 됩니다’라고 덧붙이고, 정말 급한 일은 별도 채널로 보내죠.  
DE: Nicht dringende Nachrichten ergänzen wir um „Kann morgen gelesen werden“; echte Notfälle laufen über einen eigenen Kanal.  
EN: Let's add 'This can wait until tomorrow' to non-urgent messages and use a separate channel for actual emergencies.

**안드레아**  
KO: 정리하면, 보내는 시간보다 언제 답해야 한다고 기대하는지가 더 중요합니다.  
DE: Entscheidend ist also weniger die Sendezeit als die Erwartung, wann geantwortet werden soll.  
EN: So what matters more than the send time is when people are expected to respond.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 2. AI 면접 평가를 지원자에게 어떻게 알릴지 (`ai_interview_screening_transparency`)

- 수행 목표: AI 활용 절차에서 정보 공개 범위와 책임을 체계적으로 협의할 수 있다
- 관계·사건: 리더 안드레아와 데이터 분석가 수진 / 영상 면접 분석 도구를 쓰려 하지만 지원자는 어떤 정보가 평가되는지 모른다
- 단원: `c1_03_media_evidence_literacy`

**안드레아**  
KO: 기술 설명을 길게 넣으면 지원자가 더 혼란스러울 수 있어요.  
DE: Eine lange technische Erklärung könnte Bewerber eher verwirren.  
EN: A long technical explanation may confuse applicants further.

**수진 (나)**  
KO: 모델 구조를 전부 공개하지 않더라도 무엇이 평가되고 누가 최종 판단하는지는 알려야 합니다.  
DE: Auch ohne vollständige Offenlegung des Modells müssen wir sagen, was bewertet wird und wer letztlich entscheidet.  
EN: Even without disclosing the full model, we need to say what is evaluated and who makes the final decision.

**안드레아**  
KO: 표정과 목소리도 평가하는지 묻는 지원자가 많습니다.  
DE: Viele Bewerber fragen, ob Mimik und Stimme bewertet werden.  
EN: Many applicants ask whether facial expression and voice are scored.

**수진 (나)**  
KO: 그렇다면 실제 평가 항목과 쓰지 않는 항목을 나눠서 적어야 해요.  
DE: Dann sollten wir klar trennen, welche Merkmale verwendet werden und welche nicht.  
EN: Then we should clearly separate what is used from what isn't.

**안드레아**  
KO: 사람이 다시 검토해 달라고 요청할 수 있는 창구도 넣죠.  
DE: Wir ergänzen außerdem eine Stelle, bei der Bewerbende eine menschliche Überprüfung verlangen können.  
EN: Let's also include a way to request review by a person.

**수진 (나)**  
KO: 좋습니다. 기술 홍보보다 지원자의 선택과 이의 제기에 필요한 정보부터 보여 줍시다.  
DE: Gut. Wir stellen die Informationen für Entscheidung und Rückfrage vor die technische Selbstdarstellung.  
EN: Good. Let's prioritize what applicants need for choice and appeal over technical promotion.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 3. AI 번역이 인터뷰이의 말투를 지웠을 때 (`ai_translation_voice_loss`)

- 수행 목표: 번역에서 정보 출처와 화자 태도가 달라지는 위험을 설명하고 조정할 수 있다
- 관계·사건: 영상 제작자 다니엘과 연구자 현아 / 자동 번역 자막이 인터뷰이의 망설임과 전언 표현을 모두 단정적인 문장으로 바꾼다
- 단원: `c1_03_media_evidence_literacy`

**다니엘 (나)**  
KO: 자동 자막은 짧고 읽기 쉬워졌는데 무엇이 문제야?  
DE: Die automatischen Untertitel sind kürzer und leichter zu lesen. Wo liegt das Problem?  
EN: The automatic subtitles are shorter and easier to read. What's the issue?

**현아**  
KO: 원문은 ‘주민들한테 들었는데 그런 것 같아요’라고 했어요.  
DE: Im Original heißt es: „Ich habe es von Anwohnern gehört und glaube, dass es so sein könnte.“  
EN: The original says, 'I heard it from residents, and I think that may be the case.'

**다니엘 (나)**  
KO: 자막은 ‘그렇습니다’로 끝나 있네.  
DE: Im Untertitel steht nur: „So ist es.“  
EN: The subtitle just says, 'That is the case.'

**현아**  
KO: 문장을 매끄럽게 만든다고 화자가 직접 확인한 사실처럼 바꾸면 안 돼요.  
DE: Glattere Sprache darf aus Hörensagen keine persönlich bestätigte Tatsache machen.  
EN: Smoothing the sentence must not turn reported information into something the speaker verified personally.

**다니엘 (나)**  
KO: 반복은 줄이되 ‘들었다’와 ‘그런 것 같다’는 남겨야겠어.  
DE: Dann kürzen wir Wiederholungen, behalten aber „gehört“ und „scheint so“ bei.  
EN: Then we'll trim repetition but keep 'heard' and 'seems.'

**현아**  
KO: 맞아요. 길이보다 정보의 출처와 확신 정도가 먼저예요.  
DE: Genau. Quelle und Gewissheitsgrad sind wichtiger als maximale Kürze.  
EN: Exactly. Source and degree of certainty matter more than maximum brevity.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 4. 익명 직원 설문이 정말 익명인지 묻기 (`anonymous_survey_trust`)

- 수행 목표: 조직 조사에서 정보 필요성과 참여자 보호를 근거로 조정할 수 있다
- 관계·사건: 재무 리더 안드레아와 데이터 분석가 수진 / 팀 규모가 작아 직급·근속연수를 함께 받으면 응답자를 추정할 수 있다
- 단원: `c1_02_inclusive_sustainable_systems`

**안드레아**  
KO: 이름과 이메일을 받지 않으니 익명 설문이라고 안내해도 되겠죠?  
DE: Da wir weder Namen noch E-Mail-Adressen erheben, können wir die Umfrage als anonym bezeichnen, oder?  
EN: Since we don't collect names or emails, can we call the survey anonymous?

**수진 (나)**  
KO: 이 조합이면 이름을 받지 않아도 누군지 짐작할 수 있습니다.  
DE: Mit dieser Merkmalskombination lässt sich die Person auch ohne Namen erraten.  
EN: With this combination, people can infer who responded even without a name.

**안드레아**  
KO: 직급과 근속연수는 분석에 필요한 정보인데 어떻게 하죠?  
DE: Position und Betriebszugehörigkeit brauchen wir aber für die Auswertung. Wie gehen wir damit um?  
EN: But role and tenure are important for the analysis. What should we do?

**수진 (나)**  
KO: 작은 팀은 여러 팀을 묶어서 보고 근속연수도 넓은 구간으로 바꿀 수 있어요.  
DE: Kleine Teams können zusammengefasst und Dienstzeiten in breitere Kategorien eingeteilt werden.  
EN: We can group small teams together and use broader tenure ranges.

**안드레아**  
KO: 자유 서술에는 본인을 드러낼 내용이 들어갈 수도 있겠네요.  
DE: In Freitextantworten könnten Beschäftigte sich trotzdem selbst identifizierbar machen.  
EN: People might still identify themselves in free-text responses.

**수진 (나)**  
KO: 맞아요. 식별 가능한 사례를 쓰지 말라는 안내와 실제 보고 방식을 함께 설명해야 신뢰를 얻습니다.  
DE: Genau. Vertrauen entsteht erst, wenn wir sowohl vor identifizierenden Details warnen als auch die spätere Darstellung erklären.  
EN: Right. Trust requires both warning against identifying details and explaining how results will be reported.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 5. 딥페이크 의심 영상을 보도하기 전 (`deepfake_verification`)

- 수행 목표: 미디어 자료의 출처와 확정 수준을 구분해 신중한 표현을 선택할 수 있다
- 관계·사건: 편집자와 데이터 분석가 수진 / 공인이 말하는 영상이 빠르게 퍼지지만 원본과 촬영 시점이 확인되지 않았다
- 단원: `c1_03_media_evidence_literacy`

**편집자**  
KO: 영상이 이미 크게 퍼졌으니 발언 내용을 중심으로 기사를 내죠.  
DE: Das Video ist bereits weit verbreitet. Wir sollten über die Aussage berichten.  
EN: The video is already widespread. Let's report on the statement.

**수진 (나)**  
KO: 영상이 퍼지고 있다는 사실과 영상 내용이 사실이라는 판단은 분리해야 합니다.  
DE: Wir müssen zwischen der Verbreitung des Videos und der Wahrheit seines Inhalts unterscheiden.  
EN: We need to separate the fact that the video is spreading from a judgment that its content is true.

**편집자**  
KO: 그렇다고 아무 기사도 내지 않으면 오히려 소문만 커질 수 있어요.  
DE: Wenn wir gar nichts veröffentlichen, könnte das Gerücht noch größer werden.  
EN: If we publish nothing, the rumor may grow even more.

**수진 (나)**  
KO: 확산 현상은 보도하되 발언이 확인됐다고 단정하기는 어렵다고 밝혀야 해요.  
DE: Wir können über die Verbreitung berichten, müssen aber deutlich machen, dass die Aussage nicht verifiziert ist.  
EN: We can report on the spread while clearly saying the statement has not been verified.

**편집자**  
KO: 지금 확인된 정보는 무엇인가요?  
DE: Was ist bislang gesichert?  
EN: What has been confirmed so far?

**수진 (나)**  
KO: 최초 게시 계정과 원본 파일, 촬영 시점을 확인 중이라는 상태까지입니다.  
DE: Gesichert ist nur, dass wir Erstveröffentlichung, Originaldatei und Aufnahmezeit prüfen.  
EN: Only that we're checking the first posting account, original file, and recording date.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 6. 빠른 배달과 라이더 안전을 함께 논의하기 (`delivery_rider_safety_tradeoff`)

- 수행 목표: 개인의 선택과 제도적 유인을 연결해 책임과 대안을 협의할 수 있다
- 관계·사건: 플랫폼 담당자, 라이더, 이용자 대표 현아 / 빠른 배달 배지가 주문을 늘리지만 위험한 운전을 부추길 수 있다는 지적이 나온다
- 단원: `c1_02_inclusive_sustainable_systems`

**담당자**  
KO: ‘빠른 배달’ 배지는 고객이 가게를 빨리 고르게 하고 주문도 늘렸습니다.  
DE: Das Label ‚Schnelle Lieferung‘ hilft Kunden, sich schneller für ein Restaurant zu entscheiden, und hat die Bestellungen erhöht.  
EN: The 'fast delivery' badge helps customers choose a restaurant quickly and has increased orders.

**주민**  
KO: 그 시간 안에 가려다 인도로 올라오는 오토바이를 자주 봤어요.  
DE: Ich sehe häufig Motorräder auf dem Gehweg, offenbar um die Zeitvorgabe zu schaffen.  
EN: I often see motorcycles on the sidewalk, apparently trying to meet the time target.

**현아 (나)**  
KO: 안전 문제를 개인의 주의만으로 설명하면 배달 시간을 압박하는 구조가 보이지 않습니다.  
DE: Wenn wir Sicherheit nur als individuelle Vorsicht behandeln, bleibt der Zeitdruck des Systems unsichtbar.  
EN: If we explain safety only as individual caution, we miss the system that pressures delivery times.

**담당자**  
KO: 배지를 없애면 가게와 고객 모두 불편해질 수 있습니다.  
DE: Ohne das Badge könnten sowohl Geschäfte als auch Kunden Nachteile haben.  
EN: Removing the badge could inconvenience both restaurants and customers.

**현아 (나)**  
KO: 단일 도착 시간을 경쟁시키는 대신 안전 운행을 반영한 예상 범위를 시험해 보죠.  
DE: Statt um eine einzelne Zielzeit zu konkurrieren, könnten wir ein Zeitfenster testen, das sichere Fahrweise berücksichtigt.  
EN: Instead of competing on one arrival time, let's test a range that accounts for safe riding.

**주민**  
KO: 위험 신고와 실제 도착 시간도 함께 봐야 효과를 판단할 수 있어요.  
DE: Zur Bewertung sollten wir Gefahrenmeldungen und tatsächliche Lieferzeiten gemeinsam betrachten.  
EN: To judge the effect, we should track hazard reports alongside actual delivery times.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 7. 팬 번역의 노동과 공로를 어떻게 표시할지 (`fan_translation_credit`)

- 수행 목표: 문화 참여의 자발성, 공로, 지속 가능성을 이해관계별로 협의할 수 있다
- 관계·사건: 마야와 자막 번역 참여자들 / 공식 채널이 팬 번역을 활용하려 하지만 번역자 이름과 수정 권한이 불분명하다
- 단원: `c1_05_fan_labor_sustainability`

**편집자**  
KO: 팬들이 자발적으로 올린 번역이니 공식 자막에 일부 활용해도 되지 않을까요?  
DE: Die Fans haben die Übersetzungen freiwillig veröffentlicht. Könnten wir Teile davon für die offiziellen Untertitel nutzen?  
EN: Fans posted the translations voluntarily. Couldn't we use parts in the official subtitles?

**마야 (나)**  
KO: 자발적으로 참여했다는 이유로 번역 노동이 보이지 않아도 되는 것은 아닙니다.  
DE: Freiwillige Beteiligung bedeutet nicht, dass die Übersetzungsarbeit unsichtbar bleiben darf.  
EN: Voluntary participation doesn't mean the translation work can remain invisible.

**편집자**  
KO: 실명을 공개하고 싶지 않은 사람도 있을 텐데요.  
DE: Einige möchten ihren echten Namen vermutlich nicht veröffentlichen.  
EN: Some contributors may not want their real names published.

**마야 (나)**  
KO: 실명, 활동명, 익명 중에서 고르게 하고, 아예 표기하지 않는 선택도 두면 됩니다.  
DE: Dann lassen wir zwischen echtem Namen, Nutzername und Anonymität wählen, einschließlich keiner Nennung.  
EN: Then let them choose a real name, handle, anonymity, or no credit.

**편집자**  
KO: 공식 문체로 고친 부분은 누가 확인하죠?  
DE: Wer prüft Änderungen, die wir für den offiziellen Stil vornehmen?  
EN: Who reviews changes made for the official style?

**마야 (나)**  
KO: 의미가 달라지는 수정은 게시 전에 번역자에게 확인받는 절차가 필요합니다.  
DE: Änderungen mit Bedeutungsverschiebung sollten vor Veröffentlichung von der übersetzenden Person geprüft werden.  
EN: Meaning-changing edits should be checked with the translator before publication.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 8. 골목이 유명해진 뒤 임대료가 오를 때 (`gentrification_storefront`)

- 수행 목표: 도시 변화의 상반된 효과와 이해관계를 체계적으로 설명할 수 있다
- 관계·사건: 연구자 현아와 가게 운영자, 주민 / 방문객 증가는 매출을 올렸지만 단기 임대와 임대료 상승으로 오래된 가게가 나가고 있다
- 단원: `c1_02_inclusive_sustainable_systems`

**담당자**  
KO: 홍보 이후 방문객과 카드 매출이 모두 늘었습니다.  
DE: Seit der Kampagne sind Besucherzahlen und Kartenumsätze gestiegen.  
EN: Since the promotion, both visitors and card sales have increased.

**주민**  
KO: 매출은 늘었지만 옆 가게는 임대료를 못 견디고 지난달에 나갔어요.  
DE: Der Umsatz stieg, aber das Nachbargeschäft musste letzten Monat wegen der Miete schließen.  
EN: Sales went up, but the shop next door left last month because it couldn't afford the rent.

**현아 (나)**  
KO: 사람이 많이 찾게 된 성과와 오래 있던 가게가 밀려나는 문제는 동시에 일어날 수 있습니다.  
DE: Mehr Besucher und die Verdrängung langjähriger Geschäfte können gleichzeitig stattfinden.  
EN: More visitors and the displacement of long-time shops can happen at the same time.

**담당자**  
KO: 그렇다면 홍보를 줄여야 한다는 뜻인가요?  
DE: Bedeutet das, dass wir die Werbung zurückfahren sollten?  
EN: Does that mean we should scale back promotion?

**현아 (나)**  
KO: 홍보를 중단하느냐로만 좁힐 문제가 아니라 임대 변화와 점포 이탈을 함께 추적해야 합니다.  
DE: Die Frage lässt sich nicht darauf verengen, ob die Werbung gestoppt wird; wir müssen Mietentwicklung und Geschäftsaufgaben mitverfolgen.  
EN: The issue can't be narrowed to whether promotion stops. We need to track rent changes and business turnover together.

**주민**  
KO: 지원책을 만들 때 새로 들어온 가게뿐 아니라 오래 버틴 가게가 무엇을 필요로 하는지도 살펴봐 주세요.  
DE: Wenn Sie Unterstützung planen, berücksichtigen Sie bitte nicht nur neue, sondern auch langjährig ansässige Geschäfte und deren Bedarf.  
EN: When you design support, please look at what long-standing shops need, not only what new businesses need.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 9. 폭염 쉼터가 있어도 이용하기 어려울 때 (`heatwave_shelter_access`)

- 수행 목표: 포용성과 지속 가능성을 실제 이용 조건과 자원 제약으로 조정할 수 있다
- 관계·사건: 현아와 주민, 담당자 / 쉼터 위치는 충분하지만 계단과 짧은 운영 시간 때문에 일부 주민이 이용하지 못한다
- 단원: `c1_02_inclusive_sustainable_systems`

**담당자**  
KO: 이 지역은 기준보다 많은 폭염 쉼터를 운영하고 있습니다.  
DE: In diesem Gebiet gibt es mehr Hitzeschutzräume als vorgeschrieben.  
EN: This area operates more heat shelters than the benchmark requires.

**주민**  
KO: 가까운 곳은 계단뿐이고, 경사로가 있는 곳은 제가 갈 때 이미 닫혀요.  
DE: Der nahe Raum ist nur über Treppen erreichbar, und der barrierefreie schließt, bevor ich dort sein kann.  
EN: The nearby one only has stairs, and the accessible one closes before I can get there.

**현아 (나)**  
KO: 쉼터가 있다는 것과 실제로 이용할 수 있다는 것은 같은 말이 아닙니다.  
DE: Dass ein Schutzraum vorhanden ist, heißt noch nicht, dass er praktisch nutzbar ist.  
EN: Having a shelter is not the same as being able to use it.

**담당자**  
KO: 새 시설을 더 지정하는 방안부터 검토하겠습니다.  
DE: Wir könnten zunächst weitere Einrichtungen ausweisen.  
EN: We could begin by designating more facilities.

**현아 (나)**  
KO: 시설 수에 국한하면 지금 막히는 시간과 이동 경로가 보이지 않습니다.  
DE: Wenn wir uns auf die Anzahl beschränken, bleiben Öffnungszeiten und Zugangswege unsichtbar.  
EN: If we focus only on the number, we miss the hours and routes blocking access.

**주민**  
KO: 운영 시간을 늘리고 경사로가 있는 곳을 먼저 알려 주는 게 더 도움이 됩니다.  
DE: Längere Öffnungszeiten und klare Hinweise auf barrierefreie Orte würden mir mehr helfen.  
EN: Longer hours and clear directions to accessible locations would help more.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 10. 무인 주문기가 세대별로 다르게 어려울 때 (`kiosk_generation_access`)

- 수행 목표: 효율 지표와 세대·접근성 차이를 함께 분석해 개선 실험을 제안할 수 있다
- 관계·사건: 데이터 분석가 수진과 매장 담당자 / 무인 주문 전환 후 평균 대기 시간은 줄었지만 도움 요청과 주문 포기가 늘었다
- 단원: `c1_02_inclusive_sustainable_systems`

**담당자**  
KO: 무인 주문 전환 뒤 평균 대기 시간이 2분 줄었습니다.  
DE: Seit der Umstellung auf Kioske ist die durchschnittliche Wartezeit um zwei Minuten gesunken.  
EN: After switching to kiosks, average wait time dropped by two minutes.

**수진 (나)**  
KO: 평균 대기 시간이 줄었어도 주문을 포기한 사람이 늘었다면 효율이 모두에게 좋아진 것은 아닙니다.  
DE: Wenn mehr Menschen ihre Bestellung abbrechen, bedeutet die kürzere Durchschnittszeit nicht für alle eine Verbesserung.  
EN: If more people abandon their orders, a lower average wait doesn't mean efficiency improved for everyone.

**담당자**  
KO: 도움 요청이 늘어난 건 초기 적응 문제일 수도 있어요.  
DE: Die zusätzlichen Hilfeanfragen könnten ein vorübergehendes Eingewöhnungsproblem sein.  
EN: The increase in help requests could be a temporary adjustment issue.

**수진 (나)**  
KO: 그 가능성은 있지만 연령이나 접근성 문제에 따라 어려움이 달라질 수 있습니다.  
DE: Das ist möglich, doch die Schwierigkeit kann je nach Alter und Barrieren unterschiedlich sein.  
EN: That's possible, but difficulty can vary by age and accessibility barriers.

**담당자**  
KO: 혼잡 시간에 안내 인력을 두고 쉬운 화면도 함께 시험해 보죠.  
DE: Dann testen wir zu Stoßzeiten Unterstützungspersonal und zugleich eine vereinfachte Oberfläche.  
EN: Let's test staffed assistance during busy times along with a simpler interface.

**수진 (나)**  
KO: 좋습니다. 평균 시간뿐 아니라 주문 포기율이 줄어드는지도 보겠습니다.  
DE: Gut. Dann messen wir neben der Wartezeit auch, ob weniger Bestellungen abgebrochen werden.  
EN: Good. We'll measure whether abandonment falls, not just average wait time.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 11. 박물관 설명문에 누구의 관점을 담을지 (`museum_label_multiple_views`)

- 수행 목표: 문화 해설에서 관점 선택과 생략의 효과를 분석해 다층 설명을 구성할 수 있다
- 관계·사건: 현아와 큐레이터 역할의 담당자 / 한 생활 도구를 발전의 상징으로만 설명한 문구가 당시 주민의 강제 이주 경험을 빠뜨린다
- 단원: `c1_05_fan_labor_sustainability`

**담당자**  
KO: 설명문은 짧아야 해서 이 도구가 생활을 편리하게 했다는 점만 남겼습니다.  
DE: Der Text muss kurz sein, deshalb haben wir nur erwähnt, wie das Gerät den Alltag erleichterte.  
EN: The label needs to be short, so we kept only how the tool made life easier.

**현아 (나)**  
KO: 발전의 상징이라는 설명만 남기면 그 과정에서 밀려난 사람들의 경험이 보이지 않습니다.  
DE: Bleibt nur das Fortschrittsnarrativ, verschwinden die Erfahrungen der Menschen, die im Zuge dessen verdrängt wurden.  
EN: If we keep only the symbol-of-progress story, the experiences of those displaced in the process disappear.

**담당자**  
KO: 모든 구술 기록을 본문에 넣을 공간은 없습니다.  
DE: Für sämtliche Zeitzeugenberichte ist auf dem Schild kein Platz.  
EN: There isn't room for every oral history on the label.

**현아 (나)**  
KO: 모두 넣자는 게 아니라 편리함과 강제 이주가 함께 있었다는 긴장을 한 문장으로 밝히자는 겁니다.  
DE: Nicht jeder Bericht muss hinein. Ein Satz sollte aber benennen, dass Komfort und erzwungene Umsiedlung zusammengehörten.  
EN: I'm not suggesting including every account. One sentence should name the tension between convenience and forced relocation.

**담당자**  
KO: 개별 경험은 어떻게 연결하면 좋을까요?  
DE: Wie binden wir die einzelnen Erfahrungen ein?  
EN: How should we connect the individual experiences?

**현아 (나)**  
KO: 본문에서 핵심 긴장을 밝히고 서로 다른 구술 기록은 오디오로 연결할 수 있습니다.  
DE: Der Haupttext nennt die Spannung; unterschiedliche Stimmen können über Audio zugänglich werden.  
EN: The label can state the core tension, with different oral accounts linked as audio.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 12. 야간 상권과 주민 수면권을 함께 다루기 (`nightlife_noise_balance`)

- 수행 목표: 도시 이해관계와 공간적 영향 차이를 근거로 단계적 정책을 협의할 수 있다
- 관계·사건: 현아, 상인, 주민, 담당자 / 야간 영업이 지역 경제를 살리지만 특정 골목에 귀가 소음과 쓰레기가 집중된다
- 단원: `c1_04_play_time_policy`

**담당자**  
KO: 야간 영업 이후 매출과 고용이 늘어 영업시간을 줄이기는 어렵습니다.  
DE: Seit den längeren Öffnungszeiten sind Umsatz und Beschäftigung gestiegen; eine Verkürzung ist daher schwierig.  
EN: Revenue and employment increased after late-night hours, so cutting hours is difficult.

**주민**  
KO: 혜택은 넓게 생기는데 귀가 소음과 쓰레기는 저희 골목에 몰립니다.  
DE: Der Nutzen verteilt sich, aber Heimwegslärm und Müll konzentrieren sich in unserer Gasse.  
EN: The benefits are spread out, but late-night noise and trash concentrate on our alley.

**현아 (나)**  
KO: 영업시간만 줄이면 소음이 다른 골목으로 이동할 가능성도 있습니다.  
DE: Wenn wir nur die Öffnungszeiten kürzen, könnte sich der Lärm lediglich in andere Straßen verlagern.  
EN: If we only reduce business hours, the noise may simply shift to another alley.

**담당자**  
KO: 그럼 어느 지점에서 문제가 생기는지 먼저 봐야겠군요.  
DE: Dann müssen wir zunächst genauer sehen, wo die Probleme entstehen.  
EN: Then we need to identify exactly where the problems occur.

**현아 (나)**  
KO: 혼잡 구간에 안내 인력을 두고 심야 청소 시간을 조정한 뒤 소음 자료를 공개해 보죠.  
DE: Wir testen Personal an Engstellen, passen die nächtliche Reinigung an und veröffentlichen die Lärmdaten.  
EN: Let's test staff at congestion points, adjust late-night cleaning, and publish noise data.

**주민**  
KO: 주민이 체감한 변화도 같은 기간에 받아야 숫자와 비교할 수 있어요.  
DE: Im selben Zeitraum sollten auch Rückmeldungen der Anwohner erfasst werden, damit sie mit den Messwerten vergleichbar sind.  
EN: We should collect residents' experiences over the same period so they can be compared with the data.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 13. 커뮤니티 글이 자동으로 숨겨졌을 때 (`platform_moderation_appeal`)

- 수행 목표: 자동 규칙의 목적, 오판 비용, 구제 절차를 균형 있게 설명할 수 있다
- 관계·사건: 운영자 수진과 주민 이용자 / 사기 경고 글이 공격적 표현 때문에 자동 숨김 처리되어 중요한 정보도 보이지 않게 된다
- 단원: `c1_01_evidence_public_reasoning`

**주민**  
KO: 표현이 거칠었던 건 인정하지만 계좌와 피해 방식까지 전부 가려졌어요.  
DE: Die Wortwahl war hart, aber nun sind auch Kontodaten und Betrugsmethode unsichtbar.  
EN: I admit the wording was harsh, but the account details and scam method were hidden too.

**수진 (나)**  
KO: 필터가 필요한 이유와 잘못 숨겨졌을 때 다시 볼 수 있는 길은 함께 마련돼야 합니다.  
DE: Ein notwendiger Filter braucht zugleich einen Weg zur erneuten Prüfung, wenn er falsch greift.  
EN: A necessary filter also needs a path for review when it hides something incorrectly.

**주민**  
KO: 모든 글을 사람이 보면 처리 속도가 너무 느려지지 않나요?  
DE: Würde eine menschliche Prüfung aller Beiträge nicht zu lange dauern?  
EN: Wouldn't human review of every post take too long?

**수진 (나)**  
KO: 모든 글을 다시 보자는 게 아니라 피해 위험이 큰 경고부터 우선하자는 겁니다.  
DE: Nicht jeder Beitrag muss erneut geprüft werden; Warnungen mit hohem Schadensrisiko sollten Vorrang haben.  
EN: I'm not proposing review for every post, only priority review for high-harm warnings.

**주민**  
KO: 재검토 중이라는 표시라도 있으면 다른 사람이 조심할 수 있어요.  
DE: Schon ein Hinweis auf die laufende Prüfung könnte andere zur Vorsicht mahnen.  
EN: Even a notice that review is pending could help others be cautious.

**수진 (나)**  
KO: 좋아요. 원문 공개와 별개로 검토 상태를 먼저 보여 주는 방안도 넣죠.  
DE: Gut. Dann prüfen wir auch eine Statusanzeige, unabhängig von der späteren Freigabe des Textes.  
EN: Good. Let's include a review-status notice separate from whether the full post is restored.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 14. 주민 의견 수렴이 실제 참여가 되려면 (`public_consultation_access`)

- 수행 목표: 공공 자료의 한계를 짚고 누락된 이해관계를 포함하는 방안을 제시할 수 있다
- 관계·사건: 연구자 현아와 공무원, 주민 / 온라인 설문 참여자는 많았지만 고령 주민과 세입자 의견이 거의 들어오지 않았다
- 단원: `c1_01_evidence_public_reasoning`

**담당자**  
KO: 설문 응답이 천 건을 넘어서 참여는 충분했다고 보고 있습니다.  
DE: Mit mehr als tausend Antworten betrachten wir die Beteiligung als ausreichend.  
EN: With over a thousand responses, we consider participation sufficient.

**현아 (나)**  
KO: 응답 수가 많다는 사실만으로 지역 전체의 의견을 대표한다고 보기는 어렵습니다.  
DE: Allein aus der hohen Zahl lässt sich nicht ableiten, dass die ganze Nachbarschaft vertreten ist.  
EN: A high response count alone does not mean the whole community is represented.

**주민**  
KO: 저희 건물에서는 설문이 있다는 걸 모르는 세입자도 많았어요.  
DE: In unserem Haus wussten viele Mieter nicht einmal von der Umfrage.  
EN: Many tenants in my building didn't even know about the survey.

**담당자**  
KO: 같은 설문을 더 오래 열어 두면 참여가 늘지 않을까요?  
DE: Würde eine längere Laufzeit der Umfrage nicht helfen?  
EN: Wouldn't keeping the survey open longer increase participation?

**현아 (나)**  
KO: 기간만 늘리기보다 현장 간담회와 전화 의견 창구를 함께 열어야 합니다.  
DE: Statt nur die Frist zu verlängern, brauchen wir Vor-Ort-Gespräche und eine telefonische Möglichkeit zur Stellungnahme.  
EN: Rather than only extend the deadline, we should add in-person meetings and a phone option.

**주민**  
KO: 어떤 집단의 응답이 비어 있는지도 결과와 함께 공개해 주세요.  
DE: Bitte weisen Sie bei den Ergebnissen auch aus, welche Gruppen kaum vertreten sind.  
EN: Please publish which groups are missing alongside the results.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 15. 연구 결과의 한계를 발표에서 숨기지 않기 (`research_limits_presentation`)

- 수행 목표: 연구 근거와 주장 범위를 맞추고 한계를 명료하게 설명할 수 있다
- 관계·사건: 현아와 지도 교수 / 소규모 인터뷰 결과가 흥미롭지만 발표 제목은 도시 전체의 변화처럼 넓게 잡혀 있다
- 단원: `c1_01_evidence_public_reasoning`

**교수**  
KO: ‘도시 청년의 주거 인식이 바뀌었다’는 제목이 관심을 끌기는 합니다.  
DE: Der Titel „Wie sich die Wohnwahrnehmung junger Städter verändert“ weckt durchaus Interesse.  
EN: The title 'Young Urban Residents' Housing Views Have Changed' is certainly attention-grabbing.

**현아 (나)**  
KO: 하지만 이 자료로 도시 전체의 변화를 말하기에는 범위가 좁습니다.  
DE: Für eine Aussage über die ganze Stadt ist die Datengrundlage jedoch zu schmal.  
EN: But this dataset is too narrow to describe change across the whole city.

**교수**  
KO: 제목을 너무 좁히면 연구의 의미가 약해 보이지 않을까요?  
DE: Wirkt die Studie nicht weniger relevant, wenn wir den Titel stark eingrenzen?  
EN: Won't the study seem less significant if we narrow the title too much?

**현아 (나)**  
KO: 범위를 넓게 쓴다고 해서 연구의 의미가 커지는 것은 아닙니다.  
DE: Eine breitere Formulierung macht die Studie nicht automatisch bedeutsamer.  
EN: Broader wording doesn't automatically make the study more meaningful.

**현아 (나)**  
KO: ‘특정 지역 청년 세입자의 경험’이라고 쓰면 자료가 실제로 보여 주는 긴장이 드러납니다.  
DE: „Erfahrungen junger Mieter in einem bestimmten Viertel“ zeigt die tatsächliche Spannung im Material.  
EN: 'Experiences of young tenants in one neighborhood' shows the tension the data actually captures.

**교수**  
KO: 좋아요. 제목을 바꾸고 발표 끝에 다른 지역과의 비교가 필요하다고 밝히죠.  
DE: Gut. Wir ändern den Titel und nennen am Ende den Bedarf an Vergleichen mit anderen Vierteln.  
EN: Good. Let's change the title and state that comparison with other areas is needed.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 16. 학교 스마트폰 규제를 설계할 때 (`school_phone_rule`)

- 수행 목표: 규제 목적과 예외, 집행 부담을 연결해 조건부 정책을 설명할 수 있다
- 관계·사건: 교사, 학생 대표, 학부모와 관찰자 현아 / 수업 집중을 위해 휴대폰을 일괄 수거하자는 제안이 나오지만 긴급 연락과 접근성 문제가 제기된다
- 단원: `c1_04_play_time_policy`

**담당자**  
KO: 수업 시작 전에 휴대폰을 모두 걷으면 집중 문제가 줄어들 겁니다.  
DE: Wenn alle Handys vor dem Unterricht abgegeben werden, dürfte die Ablenkung sinken.  
EN: Collecting all phones before class should reduce distractions.

**학생**  
KO: 저는 혈당을 확인하는 앱을 써서 휴대폰이 필요해요.  
DE: Ich brauche mein Handy für eine App zur Blutzuckerkontrolle.  
EN: I need my phone for an app that monitors my blood sugar.

**현아 (나)**  
KO: 집중을 높이겠다는 목적은 타당하지만 일괄 수거가 유일한 방법인지는 따져 봐야 합니다.  
DE: Das Ziel ist nachvollziehbar, aber eine pauschale Abgabe ist nicht zwingend die einzige Lösung.  
EN: The goal of improving focus is valid, but we need to ask whether blanket collection is the only way.

**담당자**  
KO: 예외를 넓게 두면 규칙이 작동하지 않을까 걱정됩니다.  
DE: Wenn wir zu viele Ausnahmen zulassen, könnte die Regel ihre Wirkung verlieren.  
EN: I'm concerned the rule won't work if exceptions are too broad.

**현아 (나)**  
KO: 수업 중 보관을 원칙으로 하되 의료·접근성 필요와 긴급 연락 방식을 명시할 수 있습니다.  
DE: Wir können die Aufbewahrung als Regel festlegen und medizinische, barrierebezogene sowie dringende Kontaktfälle klar benennen.  
EN: We can make storage the default while specifying medical, accessibility, and emergency-contact needs.

**학생**  
KO: 예외를 숨기지 않고 처음부터 안내하면 학생도 이유를 이해할 수 있어요.  
DE: Wenn Ausnahmen von Anfang an transparent sind, verstehen die Schüler auch den Grund.  
EN: If exceptions are transparent from the start, students can understand the reason for them.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 17. 전통 공연을 현대적으로 바꿀 때 (`tradition_reinterpreted_stage`)

- 수행 목표: 문화적 재해석과 원형의 관계를 관객에게 투명하게 설명할 수 있다
- 관계·사건: 기획자 마야와 연구자 현아 / 젊은 관객을 위해 전통 음악을 짧은 댄스 영상으로 바꾸자는 제안이 나온다
- 단원: `c1_05_fan_labor_sustainability`

**마야 (나)**  
KO: 젊은 관객에게 닿으려면 도입부를 줄이고 후렴을 더 강하게 만들면 어떨까요?  
DE: Wie wäre es, wenn wir den Einstieg kürzen und den Refrain verstärken, um ein jüngeres Publikum zu erreichen?  
EN: To reach younger viewers, what if we shorten the intro and make the hook stronger?

**현아**  
KO: 새롭게 해석하는 건 가능하지만 원래 형식처럼 보이게 하면 오해가 생길 수 있어요.  
DE: Eine Neuinterpretation ist möglich, sollte aber nicht wie die überlieferte Form erscheinen.  
EN: Reinterpretation is possible, but presenting it as the original form could mislead people.

**마야 (나)**  
KO: 영상 안에서 설명을 길게 하면 흐름이 끊길 것 같아요.  
DE: Eine lange Erklärung im Video würde den Rhythmus stören.  
EN: A long explanation inside the video may break the flow.

**현아**  
KO: 새롭게 해석한 부분과 전승된 형식을 구분해서 보여 주면 좋겠어요.  
DE: Dann sollten wir klar zwischen unserer Bearbeitung und der überlieferten Form unterscheiden.  
EN: Then we should clearly distinguish our adaptation from the form that was passed down.

**마야 (나)**  
KO: 영상에는 ‘현대적 재해석’이라고 짧게 쓰고 자세한 내용은 소개 페이지로 연결할게요.  
DE: Im Video steht kurz „moderne Neuinterpretation“; ausführliche Informationen verlinken wir auf der Projektseite.  
EN: We'll label it 'modern reinterpretation' in the video and link to more context on the project page.

**현아**  
KO: 그 정도면 관객도 무엇이 바뀌었는지 따라갈 수 있겠어요.  
DE: So kann das Publikum nachvollziehen, was verändert wurde.  
EN: That should let viewers understand what has changed.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 18. AI 학습 데이터의 출처를 설명해야 할 때 (`training_data_copyright`)

- 수행 목표: 출처가 불확실한 기술 결과물의 위험과 임시 대안을 설명할 수 있다
- 관계·사건: 마야, 다니엘, 법무가 아닌 프로젝트 담당자 / 특정 작가의 화풍과 매우 비슷한 생성 이미지가 나왔지만 사용 데이터와 권리 상태를 팀이 모른다
- 단원: `c1_03_media_evidence_literacy`

**담당자**  
KO: 시안 반응이 좋아서 이 이미지를 최종 캠페인에도 쓰고 싶습니다.  
DE: Der Entwurf kommt gut an; wir würden das Bild gern in der finalen Kampagne verwenden.  
EN: The draft is getting a good response, so we'd like to use this image in the final campaign.

**마야 (나)**  
KO: 특정 작가의 최근 작품과 너무 비슷하다는 의견이 있습니다.  
DE: Es gibt Hinweise, dass es den jüngsten Arbeiten einer bestimmten Künstlerin sehr ähnelt.  
EN: There are concerns that it looks very similar to a particular artist's recent work.

**다니엘**  
KO: 사용한 도구의 학습 데이터와 상업 이용 조건을 팀에서 확인했나요?  
DE: Hat das Team Trainingsdaten und kommerzielle Nutzungsbedingungen des Werkzeugs geprüft?  
EN: Has the team checked the tool's training data and commercial-use terms?

**마야 (나)**  
KO: 아직 확인하지 못했습니다. 지금 정보만으로 사용 가능하다고 단정하기는 어렵습니다.  
DE: Noch nicht. Mit den derzeitigen Informationen können wir die Nutzung nicht als unbedenklich einstufen.  
EN: Not yet. With the information we have, it's hard to conclude that we can use it.

**담당자**  
KO: 일정은 지키면서 위험을 줄일 대안이 있나요?  
DE: Gibt es eine Alternative, die das Risiko senkt, ohne den Zeitplan zu gefährden?  
EN: Is there an alternative that reduces risk while keeping the schedule?

**마야 (나)**  
KO: 해당 이미지는 잠시 빼고 권리가 확인된 자체 촬영본으로 교체하겠습니다.  
DE: Wir nehmen das Bild vorerst heraus und ersetzen es durch eigenes Material mit geklärten Rechten.  
EN: We'll remove it for now and replace it with our own footage with verified rights.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 19. 눈에 잘 안 보이는 업무까지 나누기 (`workload_allocation_hidden_labor`)

- 수행 목표: 숨은 업무와 이해관계를 근거로 공정한 분담을 협의할 수 있다
- 관계·사건: 팀 리더 안드레아와 마야, 동료 / 공식 산출물은 고르게 나뉘었지만 회의 정리와 일정 확인이 계속 마야에게 몰렸다
- 단원: `c1_06_intimacy_safety_design`

**안드레아**  
KO: 업무표를 보면 세 사람의 산출물 수는 거의 같습니다.  
DE: Laut Aufgabenliste haben alle drei fast gleich viele Ergebnisse geliefert.  
EN: The task sheet shows that all three people have nearly the same number of deliverables.

**마야 (나)**  
KO: 산출물만 보면 비슷하지만 조정 업무는 계속 한 사람에게 몰렸어요.  
DE: Bei den Ergebnissen stimmt das, aber die Koordination ist immer bei einer Person gelandet.  
EN: The deliverables look even, but the coordination work has kept falling to one person.

**동료**  
KO: 회의록과 일정 확인은 표에 없어서 저도 얼마나 많은지 몰랐어요.  
DE: Protokolle und Terminabsprachen standen nicht in der Liste. Mir war der Umfang nicht klar.  
EN: Meeting notes and scheduling weren't on the sheet, so I didn't realize how much there was.

**안드레아**  
KO: 보이는 결과만으로 업무량을 판단하면 준비와 후속 작업이 빠지겠네요.  
DE: Wenn wir nur sichtbare Ergebnisse zählen, fehlen Vorbereitung und Nacharbeit.  
EN: If we judge workload only by visible outputs, preparation and follow-up disappear.

**마야 (나)**  
KO: 조정 업무도 업무표에 넣고 회의마다 담당을 바꾸면 어떨까요?  
DE: Wie wäre es, die Koordination in die Liste aufzunehmen und die Zuständigkeit pro Meeting zu wechseln?  
EN: How about adding coordination work to the task sheet and rotating it each meeting?

**동료**  
KO: 좋아요. 다음 회의록은 제가 맡겠습니다.  
DE: Gut. Das nächste Protokoll übernehme ich.  
EN: Good. I'll take the next set of meeting notes.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 20. 청년 주거 지원 안내가 너무 어려울 때 (`youth_housing_plain_language`)

- 수행 목표: 복잡한 제도 정보를 정확성과 접근성을 유지하며 재구성할 수 있다
- 관계·사건: 데이터 분석가 수진과 공공기관 담당자 / 신청 자격을 충족하는 사람도 안내문의 행정 용어 때문에 중간에 이탈한다
- 단원: `c1_01_evidence_public_reasoning`

**담당자**  
KO: 조건을 줄이면 정확성이 떨어질 수 있어서 원문을 유지해야 합니다.  
DE: Wenn wir Bedingungen kürzen, leidet möglicherweise die Genauigkeit. Deshalb müssen wir den Originaltext beibehalten.  
EN: Reducing conditions could hurt accuracy, so we need to retain the original text.

**수진 (나)**  
KO: 조건을 삭제하자는 게 아니라 사용자가 판단하는 순서대로 다시 보여 주자는 뜻입니다.  
DE: Ich möchte keine Bedingungen streichen, sondern sie in der Reihenfolge zeigen, in der Nutzer Entscheidungen treffen.  
EN: I'm not suggesting deleting conditions. I'm suggesting showing them in the order users need to decide.

**담당자**  
KO: 예를 들면 어떤 흐름인가요?  
DE: Wie würde eine solche Reihenfolge aussehen?  
EN: What would that flow look like?

**수진 (나)**  
KO: 나이, 거주 상태, 소득처럼 먼저 답할 수 있는 질문으로 대상 여부를 좁힙니다.  
DE: Wir beginnen mit Fragen zu Alter, Wohnsituation und Einkommen, um die grundsätzliche Berechtigung einzugrenzen.  
EN: Start with answerable questions like age, housing status, and income to narrow eligibility.

**담당자**  
KO: 예외 조건과 증빙 기준은 어디에 두죠?  
DE: Wo stehen dann Ausnahmen und Nachweisanforderungen?  
EN: Where do exceptions and documentation rules go?

**수진 (나)**  
KO: 요약 뒤에 상세 원문을 함께 두고 해당 조건으로 바로 연결하면 됩니다.  
DE: Direkt hinter der Zusammenfassung bleibt der vollständige Text, mit Sprungmarken zu den jeweiligen Bedingungen.  
EN: Keep the full text after the summary and link directly to the relevant conditions.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:
