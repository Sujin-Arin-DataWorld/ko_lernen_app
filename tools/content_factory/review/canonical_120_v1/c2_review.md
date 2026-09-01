# C2 정본 시나리오 검토

> 자동 검사는 승인 증거가 아닙니다. 아래 20개를 모두 읽은 뒤 Jin이 결정합니다.

## 1. AI 채용 탈락에 이의를 제기할 권리 (`ai_hiring_appeal`)

- 수행 목표: 자동 판단의 투명성과 현실적 구제 절차를 권리·비용·오류 위험으로 설계할 수 있다
- 관계·사건: 재무 리더 안드레아와 데이터 분석가 수진, 지원자 대표 / 자동 평가에서 탈락한 지원자가 어떤 항목이 결정적이었는지 알 수 없고 사람의 검토도 요청할 수 없다
- 단원: `c2_03_automation_redress`

**주민**  
KO: 영상 업로드 오류가 있었는데 결과에는 점수만 나오고 설명은 없었습니다.  
DE: Beim Video-Upload trat ein Fehler auf, aber im Ergebnis stand nur eine Punktzahl ohne Erklärung.  
EN: There was a video upload error, but the result only showed a score with no explanation.

**안드레아 (나)**  
KO: 모든 탈락 사례를 다시 심사하면 채용 일정과 비용을 감당하기 어렵습니다.  
DE: Eine erneute Prüfung jeder Absage wäre zeitlich und finanziell kaum tragbar.  
EN: Rechecking every rejection would be difficult to sustain in cost and time.

**수진**  
KO: 그렇다고 오류 가능성을 다툴 통로가 전혀 없어도 된다는 결론은 나오지 않습니다.  
DE: Daraus folgt jedoch nicht, dass es überhaupt keinen Weg geben darf, einen möglichen Fehler anzufechten.  
EN: That doesn't mean there should be no way to challenge a possible error.

**안드레아 (나)**  
KO: 어떤 경우를 우선 재검토 대상으로 삼을 수 있을까요?  
DE: Welche Fälle sollten vorrangig überprüft werden?  
EN: Which cases should receive priority review?

**수진**  
KO: 데이터 오류, 접근성 문제, 기준점 근처 사례부터 열면 범위와 비용을 함께 관리할 수 있습니다.  
DE: Wir könnten mit Datenfehlern, Barriereproblemen und Grenzfällen beginnen und so Umfang und Kosten begrenzen.  
EN: Starting with data errors, accessibility issues, and borderline cases would control both scope and cost.

**안드레아 (나)**  
KO: 그렇다면 모든 결정을 다시 하지 않으면서도 다툴 수 있는 기준이 필요하겠군요.  
DE: Dann brauchen wir Kriterien für eine Anfechtung, ohne jede Entscheidung neu aufzurollen.  
EN: Then we need criteria for an appeal without reopening every decision.

**주민**  
KO: 최소한 제 오류가 평가에 반영됐는지는 확인할 수 있겠네요.  
DE: Dann könnte ich zumindest klären lassen, ob der technische Fehler meine Bewertung beeinflusst hat.  
EN: Then I could at least find out whether the error affected my evaluation.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 2. 복지 신청이 자동으로 거절됐을 때 책임을 묻기 (`automated_benefit_denial`)

- 수행 목표: 자동화의 효율, 오류 비용, 설명, 이의 제기, 최종 책임을 제도적으로 논증할 수 있다
- 관계·사건: 분석가 수진과 기관 담당자, 당사자 대표 / 소득 자료의 일시적 불일치로 신청이 자동 거절됐지만 통지문에는 구체적 이유가 없다
- 단원: `c2_02_technology_public_ethics`

**주민**  
KO: 통지에는 ‘기준 미충족’이라고만 쓰여 있어서 어떤 자료가 문제인지 알 수 없었습니다.  
DE: Im Bescheid stand nur „Voraussetzungen nicht erfüllt“. Ich konnte nicht erkennen, welche Angabe problematisch war.  
EN: The notice only said 'criteria not met,' so I couldn't tell which data was the problem.

**담당자**  
KO: 자동 선별 덕분에 처리 기간이 크게 줄어든 것은 사실입니다.  
DE: Die automatisierte Vorprüfung hat die Bearbeitungszeit deutlich verkürzt.  
EN: Automated screening has significantly reduced processing time.

**수진 (나)**  
KO: 처리 속도가 빨라졌다는 성과가 잘못 거절된 사람의 구제 책임을 없애지는 않습니다.  
DE: Kürzere Bearbeitungszeiten beseitigen nicht die Verantwortung, fehlerhaft abgelehnte Personen wirksam zu schützen.  
EN: Faster processing does not remove responsibility for remedying wrongful denials.

**담당자**  
KO: 모든 자동 결과를 사람이 다시 보면 효율이 사라질 수 있습니다.  
DE: Wenn jede automatische Entscheidung erneut von Menschen geprüft wird, geht der Effizienzgewinn verloren.  
EN: If a person rechecks every automated result, the efficiency gain may disappear.

**수진 (나)**  
KO: 모든 건을 반복 심사하자는 게 아니라 불이익을 확정하기 전에 오류 신호가 있는 건을 검토하자는 겁니다.  
DE: Nicht jeder Fall soll doppelt geprüft werden. Bei erkennbaren Widersprüchen sollte jedoch vor einer belastenden Entscheidung ein Mensch prüfen.  
EN: I'm not proposing duplicate review of every case. Cases with error signals should get human review before an adverse decision is finalized.

**주민**  
KO: 어떤 자료가 달랐는지 알 수 있다면 저도 바로 고칠 수 있었어요.  
DE: Wenn ich gewusst hätte, welche Daten abweichen, hätte ich sie sofort berichtigen können.  
EN: If I'd known which data differed, I could have corrected it immediately.

**수진 (나)**  
KO: 그렇기 때문에 이해 가능한 사유 통지와 이의 제기 통로를 효율 평가에 포함해야 합니다.  
DE: Darum gehören eine verständliche Begründung und ein zugänglicher Widerspruchsweg in die Effizienzbewertung.  
EN: That's why understandable reasons and an appeal path must be part of how efficiency is evaluated.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 3. 자율 배송 사고의 책임을 한 사람에게 돌릴 수 있는가 (`autonomous_delivery_liability`)

- 수행 목표: 복합 자동화 사고에서 보상 책임과 원인 책임을 구분해 설득할 수 있다
- 관계·사건: 플랫폼 담당자, 운영사, 시민 대표 현아 / 로봇이 보행자를 피하다 상점 물품을 파손했고 소프트웨어·센서 관리·현장 배치 결정이 모두 관련돼 있다
- 단원: `c2_04_sanction_accountability`

**주민**  
KO: 가게 입장에서는 로봇 회사든 운영 업체든 한 곳에서 빨리 보상받고 싶습니다.  
DE: Als Geschäftsinhaber möchte ich schnell entschädigt werden, unabhängig davon, welches Unternehmen intern verantwortlich ist.  
EN: As the shop owner, I want prompt compensation from one place, regardless of who is responsible internally.

**담당자**  
KO: 현장 배치 담당자의 판단 실수로 정리하면 책임자가 명확해집니다.  
DE: Wenn wir den Fall als Fehlentscheidung beim Einsatz einordnen, hätten wir einen klaren Verantwortlichen.  
EN: If we classify this as a deployment error, we'd have a clear responsible party.

**현아 (나)**  
KO: 피해 구제 창구를 하나로 두는 것과 원인 책임을 한 주체에게 몰아주는 것은 다른 문제입니다.  
DE: Eine zentrale Entschädigungsstelle ist etwas anderes als die gesamte Ursachenverantwortung einer Stelle zuzuschreiben.  
EN: Having one compensation channel is different from assigning all causal responsibility to one actor.

**담당자**  
KO: 원인을 여러 층으로 나누면 오히려 아무도 책임지지 않는 결과가 되지 않을까요?  
DE: Führt eine mehrschichtige Ursachenanalyse nicht dazu, dass am Ende niemand verantwortlich ist?  
EN: Wouldn't a multi-layered cause analysis leave no one responsible?

**현아 (나)**  
KO: 대외 보상 책임은 단일화하되 센서 관리, 소프트웨어 판단, 배치 기준은 각각 추적할 수 있습니다.  
DE: Die Entschädigung nach außen kann gebündelt werden, während Sensorwartung, Softwareentscheidung und Einsatzkriterien getrennt untersucht werden.  
EN: External compensation can be centralized while sensor maintenance, software decisions, and deployment criteria are traced separately.

**주민**  
KO: 보상 절차 때문에 원인 조사가 늦어지지도 않았으면 합니다.  
DE: Die Ursachenklärung sollte aber auch nicht die Entschädigung verzögern.  
EN: I also don't want the investigation to delay compensation.

**현아 (나)**  
KO: 그래서 구제와 재발 방지를 병렬로 진행하고 서로의 완료 조건으로 묶지 않는 설계가 필요합니다.  
DE: Darum sollten Entschädigung und Prävention parallel laufen, ohne einander zur Vorbedingung zu machen.  
EN: That's why remedy and prevention should proceed in parallel rather than making one a precondition for the other.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 4. 상관관계를 원인처럼 쓴 기사 제목 (`causal_claim_headline`)

- 수행 목표: 연구 설계, 인과 주장, 대중적 프레이밍 사이의 의미 이동을 정밀하게 설명할 수 있다
- 관계·사건: 데이터 분석가 수진과 편집자 / 운동 앱 사용자와 건강 지표의 상관관계를 앱이 건강을 개선한다는 제목으로 바꾸려 한다
- 단원: `c2_02_technology_public_ethics`

**편집자**  
KO: ‘이 앱이 건강을 개선한다’고 써야 독자가 연구 의미를 바로 이해합니다.  
DE: Mit „Diese App verbessert die Gesundheit“ verstehen Leser die Bedeutung der Studie sofort.  
EN: Readers will immediately understand the study if we say, 'This app improves health.'

**수진 (나)**  
KO: 함께 나타났다는 결과를 앱이 개선했다는 원인 주장으로 바꾸면 연구 범위를 넘어섭니다.  
DE: Eine beobachtete Gemeinsamkeit zur Ursache durch die App umzudeuten, überschreitet die Studie.  
EN: Turning co-occurrence into a claim that the app caused improvement goes beyond the study.

**편집자**  
KO: 제목에 모든 방법론을 넣을 수는 없잖아요.  
DE: Wir können nicht die gesamte Methodik in die Überschrift packen.  
EN: We can't put the entire methodology in the headline.

**수진 (나)**  
KO: 방법론 전체가 아니라 인과를 확인하지 않았다는 경계만 지키면 됩니다.  
DE: Wir müssen nicht alles erklären, sondern nur die Grenze wahren, dass keine Kausalität nachgewiesen wurde.  
EN: We don't need every method detail. We only need to preserve the boundary that causation wasn't established.

**편집자**  
KO: 그럼 ‘운동 앱 사용자에게서 더 좋은 건강 지표 관찰’은 어떨까요?  
DE: Wie wäre es mit „Bessere Gesundheitswerte bei Nutzern einer Fitness-App beobachtet“?  
EN: How about, 'Better health indicators observed among fitness-app users'?

**수진 (나)**  
KO: 좋습니다. 본문에서는 자기선택과 다른 생활 습관이 영향을 줬을 가능성도 설명하죠.  
DE: Gut. Im Text erklären wir zusätzlich mögliche Selbstselektion und andere Lebensgewohnheiten.  
EN: Good. In the article, let's explain possible self-selection and other lifestyle differences.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 5. 재난 대응 실패의 중앙·지방 책임을 나누기 (`central_local_disaster_responsibility`)

- 수행 목표: 다층 제도에서 정보, 결정 권한, 실행 책임의 인과를 분리해 추론할 수 있다
- 관계·사건: 중앙·지방 담당자와 시민 대표 현아 / 경보는 중앙 시스템에서 늦었고 현장 대피 결정도 지연되어 서로 책임을 떠넘긴다
- 단원: `c2_04_sanction_accountability`

**담당자**  
KO: 중앙 경보가 늦게 내려와 현장에서는 판단할 정보가 부족했습니다.  
DE: Die zentrale Warnung kam spät; vor Ort fehlte die Grundlage für eine Entscheidung.  
EN: The central alert came late, leaving the local team without enough information.

**주민**  
KO: 그런데 경보가 온 뒤에도 대피 안내는 한참 나오지 않았습니다.  
DE: Aber auch nach Eingang der Warnung dauerte es lange bis zur Evakuierungsanweisung.  
EN: But even after the alert arrived, the evacuation notice was delayed.

**현아 (나)**  
KO: 경보가 늦은 문제와 경보 이후 대피 결정이 지연된 문제를 한 책임으로 뭉뚱그릴 수는 없습니다.  
DE: Die verspätete Warnung und die verzögerte Entscheidung danach dürfen nicht zu einer einzigen Verantwortungsfrage vermischt werden.  
EN: We cannot collapse the late alert and the delayed evacuation decision after it into one responsibility.

**담당자**  
KO: 책임을 나누다 보면 서로 상대 결정만 기다리는 문제가 반복될 수 있습니다.  
DE: Wenn Zuständigkeiten getrennt werden, könnten Stellen erneut nur aufeinander warten.  
EN: Dividing responsibility could lead agencies to wait for one another again.

**현아 (나)**  
KO: 그래서 책임 배분과 별개로 어떤 정보가 오면 누가 언제 행동하는지 공통 기준을 정해야 합니다.  
DE: Darum brauchen wir unabhängig von der späteren Verantwortungszuordnung gemeinsame Auslöser: welche Information führt wann zu welcher Handlung durch wen?  
EN: That's why, separate from assigning blame, we need common triggers for who acts when specific information arrives.

**주민**  
KO: 다음에는 경보가 완벽하지 않아도 현장이 움직일 수 있는 조건을 공개해 주세요.  
DE: Bitte machen Sie öffentlich, unter welchen Bedingungen vor Ort auch bei unvollständiger Warnlage gehandelt wird.  
EN: Please publish the conditions under which local teams can act even when an alert is incomplete.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 6. 기후 모델의 불확실성을 지역 결정에 쓰기 (`climate_model_local_decision`)

- 수행 목표: 모델 불확실성과 되돌리기 어려운 정책 결정을 시나리오 기반으로 연결할 수 있다
- 관계·사건: 연구자 현아와 도시 담당자 / 여러 모델의 침수 범위가 다르지만 제방 투자 결정은 지금 내려야 한다
- 단원: `c2_02_technology_public_ethics`

**담당자**  
KO: 모델마다 침수 지도가 달라서 어느 결과를 기준으로 삼아야 할지 모르겠습니다.  
DE: Die Überflutungskarten unterscheiden sich je nach Modell. Uns fehlt eine eindeutige Grundlage.  
EN: The flood maps differ by model, so we don't know which result to use.

**현아 (나)**  
KO: 예측 범위가 다르다는 사실이 아무 결정도 하지 말아야 한다는 뜻은 아닙니다.  
DE: Unterschiedliche Prognosespannen bedeuten nicht, dass wir gar nicht entscheiden können.  
EN: Different prediction ranges do not mean we should make no decision.

**담당자**  
KO: 가장 큰 침수 범위를 기준으로 하면 과잉 투자가 될 가능성도 있습니다.  
DE: Wenn wir die größte Fläche zugrunde legen, riskieren wir Überinvestitionen.  
EN: Using the largest flood range could lead to overinvestment.

**현아 (나)**  
KO: 반대로 평균만 택하면 되돌리기 어려운 피해를 과소평가할 수 있습니다.  
DE: Ein bloßer Mittelwert könnte hingegen schwer umkehrbare Schäden unterschätzen.  
EN: Using only the average could underestimate harm that is hard to reverse.

**담당자**  
KO: 그럼 불확실한 상태에서 우선순위를 어떻게 정해야 할까요?  
DE: Wie setzen wir unter dieser Unsicherheit Prioritäten?  
EN: How should we set priorities under that uncertainty?

**현아 (나)**  
KO: 여러 모델이 공통으로 위험하다고 보는 구간은 먼저 보강하고, 나머지는 되돌릴 수 있는 조치부터 시작해 새 자료에 맞춰 조정하죠.  
DE: Wir verstärken zuerst Abschnitte, die alle Modelle als gefährdet zeigen. In den übrigen Bereichen beginnen wir mit umkehrbaren Maßnahmen und passen sie an neue Daten an.  
EN: Let's reinforce the zones all models identify as high risk first. Elsewhere, we can start with reversible measures and adjust them as new evidence comes in.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 7. 이름의 발음과 소속감을 스스로 정할 권리 (`diaspora_name_identity`)

- 수행 목표: 다언어 이름 표기에서 행정 편의, 발음, 자기 정체성의 우선순위를 조정할 수 있다
- 관계·사건: 기획자 마야와 참가자 대표 / 운영 편의를 위해 모든 한국 이름을 영어식 표기로 통일하려 하지만 일부 참가자는 다른 발음과 표기를 쓴다
- 단원: `c2_05_relationship_narratives`

**주민**  
KO: 등록 시스템에서는 제 이름을 ‘June’으로 바꾸면 검색이 쉽다고 합니다.  
DE: Das Registrierungssystem schlägt „June“ vor, weil mein Name dann leichter zu suchen sei.  
EN: The registration system suggests changing my name to 'June' because it's easier to search.

**마야 (나)**  
KO: 평소에도 그 이름으로 불리길 원하세요?  
DE: Möchten Sie im Alltag auch so genannt werden?
EN: Do you want people to call you that in everyday life too?

**주민**  
KO: 아니요. 본문에는 ‘준희’를 쓰고, 발음이 어려우면 도움말만 붙이고 싶어요.  
DE: Nein. Im Haupttext soll „Junhee“ stehen; bei Bedarf möchte ich nur eine Aussprachehilfe ergänzen.  
EN: No. I want 'Junhee' in the main text, with a pronunciation guide if needed.

**마야 (나)**  
KO: 검색을 쉽게 만드는 표기와 당사자가 불리고 싶은 이름을 같은 칸에 억지로 맞출 필요는 없습니다.  
DE: Die suchfreundliche Schreibweise und der Name, mit dem jemand angesprochen werden möchte, müssen nicht in dasselbe Feld gezwungen werden.  
EN: We don't need to force a search-friendly spelling and the name someone wants to be called into the same field.

**주민**  
KO: 검색용 표기가 화면에서 제 이름보다 더 크게 보이지만 않았으면 합니다.  
DE: Die Suchform sollte auf dem Bildschirm nur nicht prominenter erscheinen als mein Name.  
EN: I just don't want the search spelling displayed more prominently than my name.

**마야 (나)**  
KO: 선호 이름을 본문에 두고 발음 도움말과 검색용 표기는 별도 정보로 설계하겠습니다.  
DE: Dann steht der bevorzugte Name im Vordergrund; Aussprachehilfe und Suchform werden separate Metadaten.  
EN: We'll keep the preferred name primary and treat pronunciation help and search spelling as separate metadata.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 8. 재난 시 생필품 가격 제한의 역효과를 논의하기 (`emergency_price_controls`)

- 수행 목표: 긴급 정책의 직접 효과와 역효과를 비교해 조건·기간·보완책을 설계할 수 있다
- 관계·사건: 재무 전문가 안드레아와 공공 담당자 / 폭우 뒤 생수 가격 급등을 막기 위한 상한제가 제안되지만 공급 감소와 사재기 우려가 있다
- 단원: `c2_04_sanction_accountability`

**담당자**  
KO: 재난 중 생수 가격이 급등하지 않도록 즉시 상한을 두어야 합니다.  
DE: Wir brauchen sofort eine Preisobergrenze, damit Wasser in der Katastrophe nicht unbezahlbar wird.  
EN: We need an immediate cap to prevent water prices from soaring during the emergency.

**안드레아 (나)**  
KO: 가격만 묶어 두면 필요한 곳에 물건이 도착하지 않는 역효과가 생길 수 있습니다.  
DE: Wenn wir nur den Preis deckeln, könnte weniger Ware dort ankommen, wo sie gebraucht wird.  
EN: If we cap only the price, less supply may reach the places that need it.

**담당자**  
KO: 그렇다고 급등을 그대로 두면 구매력이 낮은 사람이 먼저 배제됩니다.  
DE: Ohne Eingriff werden jedoch Menschen mit geringer Kaufkraft zuerst ausgeschlossen.  
EN: But without intervention, people with less purchasing power will be excluded first.

**안드레아 (나)**  
KO: 상한 자체보다 그것만으로 충분하다는 전제가 문제입니다.  
DE: Nicht die Obergrenze an sich ist das Problem, sondern die Annahme, sie reiche allein aus.  
EN: The problem isn't the cap itself, but the premise that it is sufficient on its own.

**담당자**  
KO: 그럼 상한과 함께 어떤 대책을 묶어야 할까요?  
DE: Welche Maßnahmen sollten wir dann mit der Obergrenze verbinden?  
EN: What measures should we pair with the cap, then?

**안드레아 (나)**  
KO: 단기 상한에 구매 수량 제한과 추가 운송비 지원을 묶고 종료 조건도 정해야 합니다.  
DE: Wir sollten eine befristete Obergrenze mit Mengenbegrenzung und Unterstützung zusätzlicher Transportkosten verbinden und ein Ende definieren.  
EN: We should pair a temporary cap with purchase limits and transport-cost support, and define when it ends.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 9. 팩트체크 라벨이 논쟁을 끝내는 권력이 될 때 (`fact_check_label_power`)

- 수행 목표: 지식 판정의 범위와 플랫폼 권력이 담론에 미치는 효과를 메타적으로 논증할 수 있다
- 관계·사건: 연구자 현아와 플랫폼 담당자 / 복잡한 정책 주장에 거짓 라벨이 붙어 사실 오류와 가치 판단이 한데 섞인다
- 단원: `c2_06_fandom_discourse_power`

**담당자**  
KO: 숫자 하나가 틀렸으니 전체 주장에 ‘거짓’ 라벨을 붙이는 편이 명확합니다.  
DE: Da eine Zahl falsch ist, wäre ein „Falsch“-Label für die gesamte Aussage am eindeutigsten.  
EN: Because one number is wrong, labeling the entire claim 'false' is clearest.

**현아 (나)**  
KO: 검증 가능한 사실과 정책에 대한 가치 판단을 같은 거짓 라벨로 묶어서는 안 됩니다.  
DE: Überprüfbare Tatsachen und normative Politikurteile dürfen nicht unter demselben „Falsch“-Label verschwinden.  
EN: Verifiable facts and value judgments about policy should not be bundled under one false label.

**담당자**  
KO: 라벨을 세분화하면 이용자가 결론을 이해하기 어려워질 수 있습니다.  
DE: Eine differenziertere Kennzeichnung könnte für Nutzer schwerer verständlich sein.  
EN: A more detailed label may be harder for users to understand.

**현아 (나)**  
KO: 단순함을 위해 판정 범위를 넓히면 플랫폼이 논쟁 가능한 부분까지 끝내는 권력을 갖게 됩니다.  
DE: Wenn wir für Einfachheit den Prüfbereich ausweiten, erhält die Plattform die Macht, auch legitime Streitfragen zu beenden.  
EN: Expanding the judgment for simplicity gives the platform power to close off legitimately debatable parts.

**담당자**  
KO: 그러면 오류가 있는 문장과 확인되지 않은 부분을 따로 표시하자는 건가요?  
DE: Sollen wir also den fehlerhaften Satz und die ungesicherten Teile getrennt markieren?  
EN: So should we separately mark the erroneous sentence and the uncertain parts?

**현아 (나)**  
KO: 네. 무엇을 검증했고 무엇은 가치 판단으로 남는지 보여 줘야 라벨의 권한도 드러납니다.  
DE: Ja. Sichtbar sein muss, was geprüft wurde und was als Werturteil offenbleibt; so wird auch die Reichweite des Labels transparent.  
EN: Yes. Show what was checked and what remains a value judgment, making the label's authority visible too.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 10. 가족이 같은 과거를 다르게 기억할 때 (`family_memory_conflict`)

- 수행 목표: 충돌하는 기억의 사실, 관점, 감정, 서사 권력을 구분해 관계를 조정할 수 있다
- 관계·사건: 연인 크리스티안과 수진 / 수진 가족은 한 이사를 새로운 시작으로 말하지만 한 사람에게는 강요된 상실로 기억된다
- 단원: `c2_05_relationship_narratives`

**수진**  
KO: 가족 사진 밑에 ‘모두가 기다리던 새 출발’이라고 쓰려고 했어요.  
DE: Unter das Familienfoto wollte ich schreiben: „Der Neuanfang, auf den wir alle gewartet hatten.“  
EN: I was going to caption the family photo, 'The fresh start we'd all been waiting for.'

**크리스티안 (나)**  
KO: 그런데 이모는 그때 친구와 집을 한꺼번에 잃었다고 했죠?  
DE: Deine Tante sagte aber, sie habe damals gleichzeitig ihr Zuhause und ihre Freunde verloren, oder?  
EN: But your aunt said she lost her home and her friends at the same time, right?

**수진**  
KO: 네. 우리에게 좋은 일이었다고 쓰면 이모의 기억을 틀렸다고 만드는 것 같아요.  
DE: Ja. Wenn ich es als gute Zeit für uns alle bezeichne, klingt ihre Erinnerung falsch.  
EN: Yes. If I call it good for all of us, it makes her memory sound wrong.

**크리스티안 (나)**  
KO: 같은 일을 기억해도 누구에게 선택권이 있었는지에 따라 이야기가 달라질 수 있겠네요.  
DE: Auch dieselbe Erfahrung kann anders erzählt werden, je nachdem, wer eine Wahl hatte.  
EN: Even the same event can become a different story depending on who had a choice.

**수진**  
KO: 그럼 하나로 합치지 말고 ‘부모님에게는 새 출발, 이모에게는 떠나야 했던 날’이라고 쓸까요?  
DE: Wie wäre es dann mit: „Für meine Eltern ein Neuanfang, für meine Tante der Tag, an dem sie gehen musste“?  
EN: Then instead of merging them, how about: 'A fresh start for my parents; the day my aunt had to leave'?

**크리스티안 (나)**  
KO: 좋아요. 같은 사진에 서로 다른 기억이 있다는 게 더 솔직해 보여요.  
DE: Das ist ehrlicher: ein Foto, aber verschiedene Erinnerungen.  
EN: That feels more honest: one photo, but different memories.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 11. ‘숨은 명소’ 영상이 지역을 바꾼 뒤 (`hidden_gem_local_impact`)

- 수행 목표: 미디어 프레이밍, 플랫폼 확산, 지역 이해관계, 창작자의 후속 책임을 정교하게 논증할 수 있다
- 관계·사건: 영상 제작자 다니엘, 연구자 현아, 주민 / 다니엘의 숨은 명소 영상이 크게 퍼져 가게 매출은 늘었지만 사유지 침입·소음·임대료 우려도 커졌다
- 단원: `c2_06_fandom_discourse_power`

**다니엘 (나)**  
KO: 영상 덕분에 가게 매출이 늘었다는 연락을 받아서 처음에는 좋은 일이라고만 생각했습니다.  
DE: Als die Geschäfte von höheren Umsätzen berichteten, hielt ich die Wirkung zunächst nur für positiv.  
EN: When shops told me sales had risen, I initially saw the impact as entirely positive.

**주민**  
KO: 하지만 영상에 나온 돌계단은 사유지인데 사람들이 사진을 찍으러 계속 들어옵니다.  
DE: Die Steintreppe im Video ist jedoch Privatgrund; ständig kommen Menschen für Fotos hinein.  
EN: But the stone steps in the video are private property, and people keep entering to take photos.

**현아**  
KO: 숨은 명소라는 표현이 장소를 발견해야 할 대상으로 만들면서 실제 생활 공간이라는 점을 가렸어요.  
DE: Der Ausdruck „Geheimtipp“ rahmt den Ort als zu entdeckendes Ziel und verdeckt, dass Menschen dort leben.  
EN: The phrase 'hidden gem' frames the place as something to discover and obscures that it is a living space.

**다니엘 (나)**  
KO: 좋은 의도로 만든 영상이라는 설명만으로 이후의 영향을 지울 수는 없습니다.  
DE: Die gute Absicht hinter dem Video macht seine späteren Folgen nicht ungeschehen.  
EN: Saying the video was well-intentioned cannot erase what happened afterward.

**주민**  
KO: 지역을 통째로 숨겨 달라는 게 아니라 집 앞까지 찾아오는 동선은 막아 달라는 겁니다.  
DE: Wir verlangen nicht, den ganzen Ort zu verbergen, sondern den Weg direkt zu unseren Häusern nicht weiterzuverbreiten.  
EN: We're not asking you to hide the whole area, only to stop directing people to our doorsteps.

**다니엘 (나)**  
KO: 정확한 위치는 지우고 방문 예절과 혼잡 시간을 넣겠습니다. 수익 환원 방식도 지역과 다시 논의하겠습니다.  
DE: Ich entferne den genauen Standort, ergänze Besuchshinweise und Stoßzeiten und bespreche mit der Nachbarschaft erneut eine Beteiligung an den Einnahmen.  
EN: I'll remove the exact location, add visitor guidance and busy times, and discuss revenue sharing with the community again.

**현아**  
KO: 영상을 고치는 데 그치지 않고, 수정 뒤 유입과 민원이 어떻게 달라지는지도 함께 확인해야 합니다.  
DE: Wir sollten uns nicht auf die Änderung des Videos beschränken, sondern auch verfolgen, wie sich Besucherzahlen und Beschwerden danach entwickeln.  
EN: We shouldn't stop at editing the video; we also need to track how visitor flow and complaints change afterward.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 12. 주택 보유세 논쟁의 세대 프레임 (`housing_tax_intergenerational`)

- 수행 목표: 정책 논쟁의 프레임이 어떤 차이를 보이거나 숨기는지 분석하고 대안을 제시할 수 있다
- 관계·사건: 진행자와 연구자 현아 / 보유세 논쟁이 청년 대 노년의 갈등으로만 편집되며 자산 규모·소득·거주 목적 차이가 사라진다
- 단원: `c2_01_interpretation_institutions`

**진행자**  
KO: 오늘 토론은 집 없는 청년과 집 가진 노년의 갈등을 중심으로 보겠습니다.  
DE: Heute betrachten wir den Konflikt zwischen jungen Menschen ohne Wohneigentum und älteren Eigentümern.  
EN: Today's debate will focus on young people without homes versus older homeowners.

**현아 (나)**  
KO: 세대라는 구분이 설명력을 갖는 부분은 있지만 자산과 소득의 차이까지 대신 설명하지는 못합니다.  
DE: Die Generationenkategorie erklärt einen Teil des Konflikts, ersetzt aber nicht die Unterschiede bei Vermögen und Einkommen.  
EN: Generational categories explain part of the conflict, but cannot stand in for differences in wealth and income.

**진행자**  
KO: 그래도 시청자가 이해하기에는 세대 구도가 가장 분명하지 않나요?  
DE: Ist der Generationenrahmen für das Publikum nicht am verständlichsten?  
EN: Isn't the generational frame clearest for viewers?

**현아 (나)**  
KO: 도입에는 쓸 수 있지만 사례까지 그 틀에 맞추면 저소득 고령자와 다주택 청년 같은 집단이 지워집니다.  
DE: Als Einstieg mag er funktionieren, doch bei den Fällen verschwinden dann etwa einkommensarme Ältere und junge Mehrfacheigentümer.  
EN: It may work as an opening, but applying it to every case erases groups like low-income seniors and young multiple-property owners.

**진행자**  
KO: 그럼 어떤 기준을 교차해서 보여 주면 좋을까요?  
DE: Welche Merkmale sollten wir zusätzlich kreuzen?  
EN: What dimensions should we show alongside generation?

**현아 (나)**  
KO: 연령은 유지하되 자산 규모, 현재 소득, 실거주 여부를 함께 보여 주면 프레임의 한계도 드러납니다.  
DE: Wir können das Alter beibehalten, aber Vermögenshöhe, laufendes Einkommen und Eigennutzung mitzeigen.  
EN: Keep age, but also show asset size, current income, and whether the home is owner-occupied.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 13. 불확실한 치료 효과를 동의 과정에서 설명하기 (`medical_uncertainty_consent`)

- 수행 목표: 전문적 불확실성과 선택권을 정확하면서도 이해 가능한 방식으로 중개할 수 있다
- 관계·사건: 연구자와 참여자 대표 수진 / 초기 연구에서 가능성이 보였지만 이익과 부작용의 크기가 아직 불확실하다
- 단원: `c2_02_technology_public_ethics`

**연구자**  
KO: 초기 연구에서 위험이 절반으로 줄었다고 설명하면 핵심이 잘 전달될 겁니다.  
DE: Wenn wir sagen, das Risiko habe sich in der ersten Studie halbiert, ist der Nutzen leicht verständlich.  
EN: Saying the early study cut risk in half would communicate the benefit clearly.

**수진 (나)**  
KO: 효과가 있을 가능성과 아직 모르는 범위를 같은 무게로 설명해야 합니다.  
DE: Die mögliche Wirkung und das Ausmaß unseres Nichtwissens müssen gleichgewichtig erklärt werden.  
EN: The possibility of benefit and the extent of what remains unknown need equal weight.

**연구자**  
KO: 불확실성을 너무 강조하면 참여를 막는 방향으로 기울지 않을까요?  
DE: Könnte eine starke Betonung der Unsicherheit Menschen nicht unnötig von der Teilnahme abhalten?  
EN: Could emphasizing uncertainty too much push people away from participating?

**수진 (나)**  
KO: 참여를 늘리거나 줄이는 게 목적이 아니라 스스로 판단할 수 있게 하는 게 목적입니다.  
DE: Ziel ist weder mehr noch weniger Teilnahme, sondern eine selbstbestimmte Entscheidung.  
EN: The goal isn't to increase or decrease participation. It's to enable an informed choice.

**연구자**  
KO: 그렇다면 어떤 정보를 나눠서 보여 줘야 할까요?  
DE: Welche Informationen sollten wir dann getrennt darstellen?  
EN: Which information should we separate, then?

**수진 (나)**  
KO: 상대위험, 예상되는 실제 범위, 알려진 부작용, 아직 모르는 점과 중단할 선택권을 나눠서 보여 주죠.  
DE: Wir zeigen relatives Risiko, erwartete absolute Größen, bekannte Nebenwirkungen, offene Fragen und das Recht auf Abbruch getrennt.  
EN: Let's separate relative risk, expected absolute ranges, known side effects, what remains unknown, and the option to withdraw.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 14. 보도자료의 수동태가 책임 주체를 지울 때 (`passive_voice_accountability`)

- 수행 목표: 문법적 프레이밍이 책임과 행위자를 어떻게 보이거나 숨기는지 분석해 문체를 전환할 수 있다
- 관계·사건: 편집자와 담당자, 분석가 수진 / 자료 유출이 발생했다는 문장만 있고 누가 어떤 결정을 했는지는 계속 빠져 있다
- 단원: `c2_06_fandom_discourse_power`

**담당자**  
KO: 아직 개인 책임자를 확정하지 못했으니 ‘자료 유출이 발생했다’고 쓰는 게 안전합니다.  
DE: Da noch keine Einzelperson verantwortlich gemacht werden kann, ist „Es kam zu einem Datenleck“ die sicherste Formulierung.  
EN: Since no individual has been identified, 'a data leak occurred' is the safest wording.

**편집자**  
KO: 하지만 무엇을 했고 무엇을 하지 않았는지도 전부 빠져 있습니다.  
DE: Damit verschwinden jedoch auch sämtliche Handlungen und Unterlassungen.  
EN: But that also removes everything the institution did or failed to do.

**수진 (나)**  
KO: 행위자를 확정할 수 없다는 것과 기관이 아무 행동 주체도 아닌 것처럼 쓰는 것은 다릅니다.  
DE: Eine einzelne handelnde Person nicht benennen zu können, ist etwas anderes, als die Institution sprachlich ganz ohne Handlungsmacht darzustellen.  
EN: Not being able to identify an individual actor is different from writing as if the institution were not an actor at all.

**담당자**  
KO: 확인되지 않은 책임을 암시하지 않으면서 어떻게 바꿀 수 있습니까?  
DE: Wie formulieren wir das, ohne unbestätigte Verantwortung anzudeuten?  
EN: How can we revise it without implying unconfirmed responsibility?

**수진 (나)**  
KO: ‘기관은 유출을 확인했고 접근을 차단했다’처럼 확인된 조치는 능동태로 쓰면 됩니다.  
DE: Bestätigte Handlungen können aktiv stehen: „Die Institution bestätigte den Vorfall und sperrte den Zugang.“  
EN: State confirmed actions actively: 'The institution confirmed the leak and blocked access.'

**편집자**  
KO: 원인과 개인 책임은 조사 중이라고 별도로 표시하겠습니다.  
DE: Ursache und individuelle Verantwortung kennzeichnen wir getrennt als Gegenstand der laufenden Untersuchung.  
EN: We'll separately state that the cause and individual responsibility remain under investigation.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 15. 여론조사 질문이 원하는 답을 만들 때 (`poll_question_framing`)

- 수행 목표: 조사 문항의 전제·척도·프레이밍이 결과 해석에 미치는 영향을 정밀하게 설명할 수 있다
- 관계·사건: 분석가 수진과 편집자 / 세금 낭비를 막기 위한 규제라는 질문 문구가 정책에 대한 부정적 전제를 깔고 있다
- 단원: `c2_01_interpretation_institutions`

**편집자**  
KO: ‘세금 낭비를 막기 위한 규제에 찬성하십니까?’면 목적과 쟁점이 한눈에 들어옵니다.  
DE: „Befürworten Sie Regulierung gegen Steuerverschwendung?“ macht Zweck und Streitpunkt sofort klar.  
EN: 'Do you support regulation to prevent tax waste?' makes the purpose and issue obvious.

**수진 (나)**  
KO: 질문 안에 이미 낭비라는 평가를 넣으면 응답은 정책보다 그 전제에 반응할 수 있습니다.  
DE: Wenn die Frage bereits von „Verschwendung“ spricht, reagieren Befragte möglicherweise auf diese Wertung statt auf die Maßnahme.  
EN: If the question already says 'waste,' respondents may react to that premise rather than the policy.

**편집자**  
KO: 그 단어를 빼면 왜 규제가 제안됐는지 맥락이 사라집니다.  
DE: Ohne das Wort fehlt der Kontext, warum die Maßnahme vorgeschlagen wurde.  
EN: Without that word, we lose why the regulation was proposed.

**수진 (나)**  
KO: 목적 설명과 비용 평가를 한 문장에 묶지 말고 각각 물으면 됩니다.  
DE: Dann fragen wir Ziel und Kostenbewertung getrennt, statt beides in einen Satz zu laden.  
EN: Ask about the objective and the cost judgment separately instead of loading both into one sentence.

**편집자**  
KO: 첫 문항은 규제 찬반, 다음 문항은 현재 지출을 낭비라고 보는지 묻는 방식이군요.  
DE: Also zunächst Zustimmung zur Maßnahme und danach die Einschätzung, ob die aktuellen Ausgaben Verschwendung sind.  
EN: So first ask support for the policy, then whether respondents view current spending as waste.

**수진 (나)**  
KO: 맞아요. 문항 순서 효과도 확인할 수 있도록 순서를 바꾼 표본을 두는 게 좋습니다.  
DE: Genau. Zusätzlich sollten wir die Reihenfolge in Teilstichproben variieren, um Reihenfolgeeffekte zu prüfen.  
EN: Right. We should also vary the order across samples to detect order effects.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 16. 집회 질서와 표현의 자유를 같은 틀에서 논증하기 (`protest_order_and_rights`)

- 수행 목표: 권리 충돌을 단순 찬반이 아닌 원칙, 비례성, 대안의 구조로 설득할 수 있다
- 관계·사건: 연구자 현아와 정책 담당자, 시민 / 도심 집회가 교통을 방해했다는 이유로 광범위한 사전 제한을 두자는 제안이 나온다
- 단원: `c2_01_interpretation_institutions`

**담당자**  
KO: 지난 집회 때 도로가 오래 막혔으니 앞으로는 도심 집회를 더 엄격하게 제한해야 합니다.  
DE: Nach der langen Verkehrsblockade bei der letzten Demonstration brauchen wir strengere Beschränkungen für Kundgebungen in der Innenstadt.  
EN: After the last protest blocked roads for hours, we need tighter restrictions on downtown demonstrations.

**주민**  
KO: 출근길뿐 아니라 응급 차량 통행도 늦어질까 걱정됩니다.  
DE: Ich sorge mich nicht nur um den Berufsverkehr, sondern auch um Rettungswege.  
EN: I'm concerned not only about commuters but also emergency access.

**현아 (나)**  
KO: 불편이 발생했다는 사실만으로 표현의 자유를 광범위하게 제한할 근거가 곧바로 생기는 것은 아닙니다.  
DE: Dass Beeinträchtigungen entstanden sind, rechtfertigt nicht automatisch weitreichende Einschränkungen der Meinungs- und Versammlungsfreiheit.  
EN: The fact that disruption occurred does not automatically justify broad restrictions on freedom of expression.

**담당자**  
KO: 그렇다면 같은 문제가 반복되지 않도록 어떤 조정이 가능합니까?  
DE: Welche Anpassung verhindert dann eine Wiederholung?  
EN: What adjustment could prevent the same problem from recurring?

**현아 (나)**  
KO: 집회 허용 여부와 구체적인 시간·동선·응급 통로를 어떻게 조정할지는 분리해서 봐야 합니다.  
DE: Wir müssen die grundsätzliche Zulässigkeit der Versammlung von konkreten Auflagen zu Zeit, Route und Rettungswegen trennen.  
EN: We should separate whether the protest may occur from how its timing, route, and emergency access are managed.

**주민**  
KO: 그럼 응급 통로를 보장하면서 제한 범위는 실제 위험이 있는 구간에만 두자는 건가요?  
DE: Also sichern wir Rettungswege und begrenzen Auflagen auf Abschnitte mit einem konkreten Risiko?  
EN: So we'd preserve emergency access and limit restrictions to areas with a concrete risk?

**현아 (나)**  
KO: 네. 목적에 필요한 만큼만 제한하고, 집회 뒤 실제 효과와 침해를 함께 검토해야 합니다.  
DE: Ja. Eingriffe sollten auf das Erforderliche begrenzt und anschließend hinsichtlich Wirkung und Grundrechtseingriff überprüft werden.  
EN: Yes. Restrictions should go only as far as needed, followed by a review of both effectiveness and rights impact.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 17. 연애의 시작을 서로 다르게 말할 때 (`relationship_story_reframing`)

- 수행 목표: 관계 서사의 프레이밍과 함축을 읽고 관점 차이를 섬세하게 조정할 수 있다
- 관계·사건: 연인 크리스티안과 수진 / 친구들 앞에서 크리스티안은 첫눈에 시작됐다고 농담했지만 수진은 천천히 신뢰가 쌓인 과정을 지운 말처럼 느낀다
- 단원: `c2_05_relationship_narratives`

**수진**  
KO: 아까 친구들 앞에서 첫눈에 반했다고 말한 거, 저는 조금 불편했어요.  
DE: Dein Spruch vorhin, du hättest dich auf den ersten Blick verliebt, war mir etwas unangenehm.  
EN: I felt a little uncomfortable when you told our friends it was love at first sight.

**크리스티안 (나)**  
KO: 그냥 이야기를 짧고 재미있게 하려고 한 말이었어요.  
DE: Ich wollte die Geschichte nur kurz und lustig erzählen.  
EN: I was just trying to make the story short and funny.

**수진**  
KO: 저한테는 처음보다 그 뒤에 천천히 믿게 된 시간이 더 중요해요.  
DE: Für mich ist die Zeit danach wichtiger, in der Vertrauen langsam gewachsen ist.  
EN: To me, the time afterward, when trust grew slowly, matters more than the first moment.

**크리스티안 (나)**  
KO: 첫눈에 시작됐다는 말이 우리 사이에 쌓인 시간을 지우는 것처럼 들렸구나.  
DE: „Liebe auf den ersten Blick“ klang also, als würde es die Zeit auslöschen, die wir miteinander aufgebaut haben.  
EN: Saying it began at first sight sounded like it erased all the time we built together.

**수진**  
KO: 네. 그 기억이 틀렸다는 게 아니라 그게 전부인 것처럼 말하지 않았으면 해요.  
DE: Ja. Deine Erinnerung ist nicht falsch; ich möchte nur nicht, dass sie als die ganze Geschichte gilt.  
EN: Yes. Your memory isn't wrong. I just don't want it told as the whole story.

**크리스티안 (나)**  
KO: 다음에는 저는 처음의 설렘을, 수진은 그 뒤의 신뢰를 중요하게 기억한다고 말할게요.  
DE: Dann sage ich künftig: Für mich war die erste Aufregung wichtig, für dich das Vertrauen, das danach entstand.  
EN: Next time I'll say I remember the early spark, while you value the trust that came afterward.

**수진**  
KO: 그렇게 서로 다른 시작을 같이 말하면 우리 이야기 같아요.  
DE: Wenn beide Anfänge Platz haben, klingt es wirklich nach unserer Geschichte.  
EN: When both beginnings have a place, it feels like our story.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 18. 연구 재현에 실패했을 때 원 논문을 평가하기 (`replication_failure_response`)

- 수행 목표: 상충하는 연구 결과의 증거 가치를 조건과 방법에 따라 추론할 수 있다
- 관계·사건: 연구자 현아와 교수, 동료 / 유명 연구를 같은 방식으로 반복했지만 효과가 나타나지 않았다
- 단원: `c2_01_interpretation_institutions`

**연구자**  
KO: 같은 절차를 썼는데 효과가 없었으니 원 연구는 틀렸다고 발표해야 합니다.  
DE: Wir haben dasselbe Verfahren genutzt und keinen Effekt gefunden. Also sollten wir die ursprüngliche Studie als falsch bezeichnen.  
EN: We used the same procedure and found no effect, so we should say the original study was wrong.

**교수**  
KO: 반대로 이번 표본에만 특수한 문제가 있었다고 넘기는 것도 설득력이 없습니다.  
DE: Umgekehrt wäre es ebenso wenig überzeugend, das Ergebnis nur unserer Stichprobe zuzuschreiben.  
EN: Conversely, dismissing it as a quirk of our sample isn't persuasive either.

**현아 (나)**  
KO: 재현되지 않았다는 결과는 중요하지만 그것만으로 원 연구의 모든 주장이 거짓이라고 결론 내릴 수는 없습니다.  
DE: Die fehlende Replikation ist wichtig, erlaubt aber nicht, sämtliche Aussagen der ursprünglichen Studie für falsch zu erklären.  
EN: The failed replication matters, but it doesn't let us conclude that every claim in the original study was false.

**연구자**  
KO: 그럼 이번 결과의 의미를 어떻게 분명하게 말하죠?  
DE: Wie formulieren wir dann klar, was unser Ergebnis bedeutet?  
EN: Then how do we clearly state what our result means?

**현아 (나)**  
KO: 이 조건과 표본에서는 같은 효과가 확인되지 않았다고 쓰고, 결과가 달라질 수 있는 조건을 비교해야 합니다.  
DE: Wir schreiben, dass sich der Effekt unter diesen Bedingungen und in dieser Stichprobe nicht zeigte, und vergleichen mögliche Moderatoren.  
EN: State that the effect wasn't found in this sample under these conditions, then compare what conditions may account for the difference.

**교수**  
KO: 측정 방식과 표본 구성 차이를 후속 연구의 가설로 명시합시다.  
DE: Dann benennen wir Messverfahren und Stichprobenzusammensetzung als Hypothesen für die Folgestudie.  
EN: Let's name measurement and sample composition as hypotheses for follow-up research.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 19. ‘우리’가 포함하고 배제하는 사람을 번역하기 (`we_translation_identity`)

- 수행 목표: 미명시된 집단 경계와 정체성 효과를 근거 없이 확정하지 않고 번역할 수 있다
- 관계·사건: 서로 편하게 말하는 현아와 다니엘 / 마을 인터뷰의 우리가 주민 전체, 오래 산 사람, 인터뷰 팀을 오가는데 영어와 독일어 자막이 한 집단으로 고정한다
- 단원: `c2_05_relationship_narratives`

**다니엘**  
KO: 영어 자막에서는 우리를 계속 ‘we residents’로 통일했어. 더 자연스럽지 않아?  
DE: Im englischen Untertitel habe ich 우리 durchgehend als „we residents“ wiedergegeben. Klingt das nicht natürlicher?  
EN: I translated 우리 as 'we residents' throughout. Isn't that more natural?

**현아 (나)**  
KO: 여기서 우리는 앞 문장의 주민 전체와 같은 범위가 아니야.  
DE: An dieser Stelle umfasst 우리 nicht dieselbe Gruppe wie die Bewohner im vorherigen Satz.  
EN: Here, 우리 does not refer to the same group as all residents in the previous sentence.

**다니엘**  
KO: 이 문장에서는 누구를 가리키는 거야?  
DE: Wer ist hier dann gemeint?  
EN: Who does it mean in this sentence?

**현아 (나)**  
KO: ‘우리가 이 골목을 기록했다’의 우리는 인터뷰이와 제작진이고, 다음 문장에서는 오래 산 주민들이야.  
DE: In „Wir haben diese Gasse dokumentiert“ meint es die interviewte Person und das Filmteam; im nächsten Satz die langjährigen Bewohner.  
EN: In 'we documented this alley,' it means the interviewee and crew; in the next sentence, long-time residents.

**다니엘**  
KO: 대명사를 그대로 두면 영어와 독일어에서는 그 전환이 더 안 보이겠네.  
DE: Wenn die Pronomen unverändert bleiben, wird der Wechsel auf Deutsch und Englisch noch unsichtbarer.  
EN: If we keep the pronoun unchanged, the shift will be even less visible in English and German.

**현아 (나)**  
KO: 전환 지점에서 집단을 한 번만 명시하고 그 뒤에는 자연스러운 대명사로 이어 가자.  
DE: Benennen wir die Gruppe jeweils beim Wechsel einmal ausdrücklich und verwenden danach wieder natürliche Pronomen.  
EN: Let's name the group once at each shift, then return to natural pronouns.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 20. 부정 수급 방지 담론이 신청자를 의심하게 만들 때 (`welfare_fraud_presumption`)

- 수행 목표: 정책 문구의 전제와 행동 효과를 분석해 정확성과 존중을 함께 설계할 수 있다
- 관계·사건: 기관 담당자와 시민 대표 수진 / 부정 수급을 줄이기 위한 강한 경고 문구가 모든 신청자를 잠재적 위반자로 취급한다는 지적이 나온다
- 단원: `c2_01_interpretation_institutions`

**담당자**  
KO: 허위 신청을 줄이려면 첫 화면부터 처벌 가능성을 강하게 알려야 합니다.  
DE: Um falsche Angaben zu verhindern, sollten mögliche Sanktionen gleich auf der ersten Seite deutlich hervorgehoben werden.  
EN: To deter false claims, possible penalties should be strongly emphasized on the first screen.

**수진 (나)**  
KO: 위반 가능성을 알리는 것과 신청자 전체를 의심하는 문체는 구분해야 합니다.  
DE: Über mögliche Verstöße zu informieren ist etwas anderes, als alle Antragsteller sprachlich unter Verdacht zu stellen.  
EN: Informing people about violations is different from writing as if every applicant is suspect.

**담당자**  
KO: 경고를 부드럽게 만들면 책임을 가볍게 받아들이지 않을까요?  
DE: Wird die Pflicht nicht verharmlost, wenn wir den Hinweis abschwächen?  
EN: Would softer wording make people take their responsibility less seriously?

**수진 (나)**  
KO: 의무와 처벌은 정확히 쓰되 실수 수정과 도움 요청도 같은 화면에서 안내할 수 있습니다.  
DE: Pflichten und Sanktionen können präzise bleiben, während Korrektur- und Hilfswege auf derselben Seite stehen.  
EN: Duties and penalties can remain precise while correction and help options appear on the same screen.

**담당자**  
KO: 그렇게 하면 고의와 단순 오류를 처음부터 구분할 수 있겠군요.  
DE: So könnten wir vorsätzliche Täuschung und einfache Fehler von Anfang an unterscheiden.  
EN: That would distinguish intentional fraud from simple mistakes from the outset.

**수진 (나)**  
KO: 네. 존중하는 문체를 쓴다고 해서 통제를 포기하는 것은 아니니까요.  
DE: Genau. Respektvolle Sprache bedeutet nicht, dass Kontrolle aufgegeben wird.  
EN: Exactly. Using respectful language doesn't mean giving up enforcement.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:
