# C1/C2 단원·시나리오 수정 후보

상태: **검수용 초안 / 사람 검수 대기 / 런타임 미반영**. 기존 승인 후보와 승인 기록은 보존한다.

이 문서는 단원 목표와 실제 발화·문항의 대응을 검토하기 위한 것이다. 모델 검토와 자동 검사는 원어민 승인, CEFR 수준 판정, 실제 기기 검증을 대신하지 않는다.

## 변경 범위

- C1 쉼터: 시설 수 외에 운영 시간·이동 경로를 다루고, 인력·장소 계약의 제약 → 조건부 우선순위 제안 → 담당자 응답 → 주민 반응을 추가한다.
- C2 자동 거절: 가능성, 과거 반사실, 잘못된 거절의 구제 책임, 일반적인 오류 징후를 세 언어에서 맞춘다.
- 두 후보의 문장 조립 문제는 각각 한 어절인 오답 타일을 쓴다. 기존 문제 ID를 유지하고 C1 제안 산출 문제 하나를 추가한다.
- C2 단원 목표 영어 2건은 한국어의 설득·최종 책임을 더 정확히 드러내는 제안이다.

## 원본과 승인 경계

출발 Git HEAD: `337767428b862255502a9f61a5cc01b38cca0a5f`. 파일 및 후보 집합의 정확한 해시는 [revision_manifest.json](revision_manifest.json)에 있다.

원본 C1/C2 각 20개 집합은 기존 승인을 통과한다. 수정 후보를 하나씩 대입하면 같은 승인으로 실제 승격 검사를 통과하지 못한다. 새 승인이나 음성 업로드는 이 변경에 포함되지 않는다. [tts_pending.json](tts_pending.json)은 현재 문구·캐릭터 음성으로 계산한 대기 목록이다.

## Batch 05의 남은 curriculum 차이

| 기존 unit ID | 현재 연결 시나리오 | 이번 후보 범위 |
|---|---|---|
| c1_01_evidence_public_reasoning | public_consultation_access | 원본 유지 |
| c1_02_inclusive_sustainable_systems | heatwave_shelter_access | 대화·산출 평가·번역 보완 초안 |
| c2_01_interpretation_institutions | protest_order_and_rights | 단원 영어 문구 제안 |
| c2_02_technology_public_ethics | automated_benefit_denial | 대화 번역·단원 영어 문구 제안 |

네 단원의 과거 manifest 대비 title/canDo/checkpoint 차이는 `ca00acad2ff0d1470dc241bfdfb8d15685a7d1a0`에 연결된다. 기존 시나리오 집합의 승인 사실만으로 별도 blueprint 문구의 승인을 추정하지 않는다. 이번 수정 후보 작성은 Batch 05 전체 reconciliation 완료를 뜻하지 않으며, strict validator의 미해결 curriculum 차이를 예외 처리하지 않는다.

## 생성기 수정과 남은 라이브 타일 부채

실제 SatzBauen 엔진은 정답 문장을 어절로 나누지만 오답 문자열 각각은 나누지 않고 한 타일로 표시한다. 기존 생성기는 다른 대화 문장 전체를 오답으로 복사했다. 출발 HEAD의 전체 시나리오 shard를 검사하면 문장 조립 문제 178개 중 134개에서 공백을 포함한 오답 타일이 발견된다. 이 수치는 정본 120장면만의 수치가 아니다.

생성기는 이제 작성한 `sentenceBuild`를 요구한다. `targetKo`는 마지막 중복 제거된 학습자 발화와 정확히 같아야 하며, `distractors`는 중복·정답 토큰 겹침·앞뒤 문장부호·공백이 없는 세 어절이어야 한다. 의미상 오답인지와 대체 정답 가능성은 별도 언어 검수가 필요하다.

```json
{"sentenceBuild": {"targetKo": "이 빵 주세요.", "distractors": ["커피", "마셔요", "어제"]}}
```

기존 authored 원본에는 이 필드가 없으므로 그대로 재생성하면 명확한 오류로 중단된다. 전체 레벨을 검증하고 직렬화한 뒤에만 첫 파일을 쓰므로 뒤쪽 잘못된 입력 때문에 기존 검수 파일 일부만 바뀌지 않는다. 디스크 쓰기 자체의 장애까지 트랜잭션으로 처리하는 기능은 아니다. regression copyFrom은 같은 목표이면 타일을 상속하며, 목표를 바꾸면 sentenceBuild도 명시적으로 바꿔야 한다.

라이브 134개를 자동 교체하지 않았다. 원본별로 의미 있는 어절을 작성하고, 대체 정답·수준·승인·음성 게이트를 거쳐 별도 승격해야 한다. 이번 두 후보만으로 전체 부채가 해소됐다고 주장하지 않는다.

## C1 · 폭염 쉼터가 있어도 이용하기 어려울 때

후보: [JSON](candidates/c1/heatwave_shelter_access.json) · 단원 `c1_02_inclusive_sustainable_systems` · 학습자 역할 `hyuna`

`user`는 학습자가 맡는 발화이며 고정된 사용자 이름이 아니다. 표시 이름과 TTS 음성은 캐릭터 계약을 따른다.

### 전체 대화

1. **official**
   - KO: 이 지역은 기준보다 많은 폭염 쉼터를 운영하고 있습니다.
   - DE: In diesem Gebiet betreiben wir mehr Hitzeschutzräume, als der Richtwert vorsieht.
   - EN: This area operates more heat shelters than the benchmark calls for.

2. **resident**
   - KO: 가까운 곳은 계단뿐이고, 경사로가 있는 곳은 제가 갈 때 이미 닫혀요.
   - DE: Die Einrichtung in der Nähe hat nur Treppen, und die mit einer Rampe ist schon geschlossen, wenn ich dort ankomme.
   - EN: The nearby one only has stairs, and the one with a ramp is already closed when I get there.

3. **user**
   - KO: 쉼터가 있다는 것과 실제로 이용할 수 있다는 것은 같은 말이 아닙니다.
   - DE: Dass ein Schutzraum vorhanden ist, heißt noch nicht, dass er praktisch nutzbar ist.
   - EN: Having a shelter is not the same as being able to use it.

4. **official**
   - KO: 새 시설을 더 지정하는 방안부터 검토하겠습니다.
   - DE: Wir werden zunächst prüfen, ob wir weitere Einrichtungen als Schutzräume ausweisen können.
   - EN: We'll first look into designating more facilities as shelters.

5. **user**
   - KO: 시설 수에 국한하면 운영 시간과 이동 경로의 문제를 놓치게 됩니다.
   - DE: Wenn wir uns auf die Anzahl der Einrichtungen beschränken, übersehen wir Probleme bei den Öffnungszeiten und Zugangswegen.
   - EN: If we focus only on the number of facilities, we overlook problems with opening hours and access routes.

6. **resident**
   - KO: 운영 시간을 늘리고 경사로가 있는 곳을 먼저 알려 주는 게 더 도움이 됩니다.
   - DE: Es wäre hilfreicher, die Öffnungszeiten zu verlängern und zuerst über die Einrichtungen mit einer Rampe zu informieren.
   - EN: It would help more to extend the opening hours and let us know first which shelters have a ramp.

7. **official**
   - KO: 운영 인력이 부족하고, 장소 계약상 일부 쉼터는 저녁에 문을 열 수 없습니다.
   - DE: Uns fehlt Personal, und bei manchen Schutzräumen lassen die Nutzungsverträge keine Abendöffnung zu.
   - EN: We're short of staff, and the agreements for some shelters don't allow evening opening.

8. **user**
   - KO: 새 시설을 늘리기 전에 안내부터 고치고, 계약과 인력 여건이 되는 곳부터 운영 시간을 늘리면 어떨까요?
   - DE: Bevor wir weitere Einrichtungen aufnehmen, könnten wir zuerst die Hinweise verbessern und die Öffnungszeiten dort verlängern, wo es die Verträge und die Personalsituation zulassen.
   - EN: Before adding more facilities, could we improve the information first and extend opening hours where the agreements and staffing allow it?

9. **official**
   - KO: 안내는 먼저 고치겠습니다. 운영 시간을 늘릴 수 있는 곳은 다음 회의에서 말씀드리겠습니다.
   - DE: Wir verbessern zuerst die Hinweise. In der nächsten Sitzung stellen wir vor, wo längere Öffnungszeiten möglich sind.
   - EN: We'll improve the information first. At the next meeting, we'll report which facilities could stay open longer.

10. **resident**
   - KO: 어느 쉼터를 언제 이용할 수 있는지 알면 갈 곳을 정하기가 훨씬 수월하겠네요.
   - DE: Wenn ich weiß, welchen Schutzraum ich wann nutzen kann, fällt es mir viel leichter zu entscheiden, wohin ich gehe.
   - EN: Knowing which shelter I can use and when would make it much easier to decide where to go.

### 전체 문제

**quest_heatwave_shelter_access_01 · hoerverstehen**

- 듣기: 이 지역은 기준보다 많은 폭염 쉼터를 운영하고 있습니다.
- 선택지 1 (정답): DE: In diesem Gebiet betreiben wir mehr Hitzeschutzräume, als der Richtwert vorsieht. / EN: This area operates more heat shelters than the benchmark calls for.
- 선택지 2: DE: Die Einrichtung in der Nähe hat nur Treppen, und die mit einer Rampe ist schon geschlossen, wenn ich dort ankomme. / EN: The nearby one only has stairs, and the one with a ramp is already closed when I get there.
- 선택지 3: DE: Dass ein Schutzraum vorhanden ist, heißt noch nicht, dass er praktisch nutzbar ist. / EN: Having a shelter is not the same as being able to use it.
- 선택지 4: DE: Wir werden zunächst prüfen, ob wir weitere Einrichtungen als Schutzräume ausweisen können. / EN: We'll first look into designating more facilities as shelters.

**quest_heatwave_shelter_access_02 · uebersetzen**

- DE: Dass ein Schutzraum vorhanden ist, heißt noch nicht, dass er praktisch nutzbar ist.
- EN: Having a shelter is not the same as being able to use it.
- 선택지 1 (정답): KO: 쉼터가 있다는 것과 실제로 이용할 수 있다는 것은 같은 말이 아닙니다.
- 선택지 2: KO: 이 지역은 기준보다 많은 폭염 쉼터를 운영하고 있습니다.
- 선택지 3: KO: 가까운 곳은 계단뿐이고, 경사로가 있는 곳은 제가 갈 때 이미 닫혀요.
- 선택지 4: KO: 새 시설을 더 지정하는 방안부터 검토하겠습니다.

**quest_heatwave_shelter_access_03 · satzBauen**

- 정답: 시설 수에 국한하면 운영 시간과 이동 경로의 문제를 놓치게 됩니다.
- DE: Wenn wir uns auf die Anzahl der Einrichtungen beschränken, übersehen wir Probleme bei den Öffnungszeiten und Zugangswegen.
- EN: If we focus only on the number of facilities, we overlook problems with opening hours and access routes.
- 오답 어절: 늘리면 / 계약만 / 충분합니다
- 평가 개념: concept_c1_inclusive_systems

**quest_heatwave_shelter_access_04 · satzBauen**

- 정답: 새 시설을 늘리기 전에 안내부터 고치고, 계약과 인력 여건이 되는 곳부터 운영 시간을 늘리면 어떨까요?
- DE: Bevor wir weitere Einrichtungen aufnehmen, könnten wir zuerst die Hinweise verbessern und die Öffnungszeiten dort verlängern, wo es die Verträge und die Personalsituation zulassen.
- EN: Before adding more facilities, could we improve the information first and extend opening hours where the agreements and staffing allow it?
- 오답 어절: 나중에 / 줄이면 / 불가능한
- 평가 개념: concept_c1_inclusive_systems

## C2 · 복지 신청이 자동으로 거절됐을 때 책임을 묻기

후보: [JSON](candidates/c2/automated_benefit_denial.json) · 단원 `c2_02_technology_public_ethics` · 학습자 역할 `sujin`

`user`는 학습자가 맡는 발화이며 고정된 사용자 이름이 아니다. 표시 이름과 TTS 음성은 캐릭터 계약을 따른다.

### 전체 대화

1. **resident**
   - KO: 통지에는 ‘기준 미충족’이라고만 쓰여 있어서 어떤 자료가 문제인지 알 수 없었습니다.
   - DE: Im Bescheid stand nur „Voraussetzungen nicht erfüllt“. Ich konnte nicht erkennen, welche Angabe problematisch war.
   - EN: The notice only said 'criteria not met,' so I couldn't tell which data was the problem.

2. **official**
   - KO: 자동 선별 덕분에 처리 기간이 크게 줄어든 것은 사실입니다.
   - DE: Die automatisierte Vorprüfung hat die Bearbeitungszeit deutlich verkürzt.
   - EN: Automated screening has significantly reduced processing time.

3. **user**
   - KO: 처리 속도가 빨라졌다는 성과가 잘못 거절된 사람의 구제 책임을 없애지는 않습니다.
   - DE: Kürzere Bearbeitungszeiten entbinden nicht von der Verantwortung, bei fehlerhaften Ablehnungen Abhilfe zu schaffen.
   - EN: Faster processing does not remove responsibility for remedying wrongful denials.

4. **official**
   - KO: 모든 자동 결과를 사람이 다시 보면 효율이 사라질 수 있습니다.
   - DE: Wenn jede automatische Entscheidung erneut von Menschen geprüft wird, könnte der Effizienzgewinn verloren gehen.
   - EN: If a person rechecks every automated result, the efficiency gain may disappear.

5. **user**
   - KO: 모든 건을 반복 심사하자는 게 아니라 불이익을 확정하기 전에 오류 신호가 있는 건을 검토하자는 겁니다.
   - DE: Nicht jeder Fall soll doppelt geprüft werden. Bei Anzeichen für Fehler sollte jedoch vor einer belastenden Entscheidung ein Mensch prüfen.
   - EN: I'm not proposing duplicate review of every case. Cases with error signals should get human review before an adverse decision is finalized.

6. **resident**
   - KO: 어떤 자료가 달랐는지 알았다면 저도 바로 고칠 수 있었어요.
   - DE: Wenn ich gewusst hätte, welche Daten abweichen, hätte ich sie sofort berichtigen können.
   - EN: If I'd known which data differed, I could have corrected it immediately.

7. **user**
   - KO: 그렇기 때문에 이해 가능한 사유 통지와 이의 제기 통로를 효율 평가에 포함해야 합니다.
   - DE: Darum gehören eine verständliche Begründung und ein zugänglicher Widerspruchsweg in die Effizienzbewertung.
   - EN: That's why understandable reasons and an appeal path must be part of how efficiency is evaluated.

### 전체 문제

**quest_automated_benefit_denial_01 · hoerverstehen**

- 듣기: 통지에는 ‘기준 미충족’이라고만 쓰여 있어서 어떤 자료가 문제인지 알 수 없었습니다.
- 선택지 1 (정답): DE: Im Bescheid stand nur „Voraussetzungen nicht erfüllt“. Ich konnte nicht erkennen, welche Angabe problematisch war. / EN: The notice only said 'criteria not met,' so I couldn't tell which data was the problem.
- 선택지 2: DE: Die automatisierte Vorprüfung hat die Bearbeitungszeit deutlich verkürzt. / EN: Automated screening has significantly reduced processing time.
- 선택지 3: DE: Kürzere Bearbeitungszeiten entbinden nicht von der Verantwortung, bei fehlerhaften Ablehnungen Abhilfe zu schaffen. / EN: Faster processing does not remove responsibility for remedying wrongful denials.
- 선택지 4: DE: Wenn jede automatische Entscheidung erneut von Menschen geprüft wird, könnte der Effizienzgewinn verloren gehen. / EN: If a person rechecks every automated result, the efficiency gain may disappear.

**quest_automated_benefit_denial_02 · uebersetzen**

- DE: Kürzere Bearbeitungszeiten entbinden nicht von der Verantwortung, bei fehlerhaften Ablehnungen Abhilfe zu schaffen.
- EN: Faster processing does not remove responsibility for remedying wrongful denials.
- 선택지 1 (정답): KO: 처리 속도가 빨라졌다는 성과가 잘못 거절된 사람의 구제 책임을 없애지는 않습니다.
- 선택지 2: KO: 통지에는 ‘기준 미충족’이라고만 쓰여 있어서 어떤 자료가 문제인지 알 수 없었습니다.
- 선택지 3: KO: 자동 선별 덕분에 처리 기간이 크게 줄어든 것은 사실입니다.
- 선택지 4: KO: 모든 자동 결과를 사람이 다시 보면 효율이 사라질 수 있습니다.

**quest_automated_benefit_denial_03 · satzBauen**

- 정답: 그렇기 때문에 이해 가능한 사유 통지와 이의 제기 통로를 효율 평가에 포함해야 합니다.
- DE: Darum gehören eine verständliche Begründung und ein zugänglicher Widerspruchsweg in die Effizienzbewertung.
- EN: That's why understandable reasons and an appeal path must be part of how efficiency is evaluated.
- 오답 어절: 제외해야 / 처리량만 / 부정확한
- 평가 개념: concept_c2_accountable_systems

## 단원 영어 설명 제안

### c2_01_interpretation_institutions

- KO 정본: 권리 충돌을 필요성·비례성·대안의 구조로 분석하고 설득할 수 있어요.
- DE 정본: Ich kann Grundrechtskonflikte anhand von Erforderlichkeit, Verhältnismäßigkeit und Alternativen analysieren und überzeugend darstellen.
- EN 기존: I can analyze and argue rights conflicts through necessity, proportionality, and alternatives.
- EN 제안: I can analyze conflicts between rights in terms of necessity, proportionality, and alternatives, and make a persuasive case.

### c2_02_technology_public_ethics

- KO 정본: 자동화의 효율, 오류 비용, 설명 의무와 사람의 최종 책임을 정교하게 논증할 수 있어요.
- DE 정본: Ich kann Effizienz, Fehlerkosten, Erklärungspflichten und menschliche Letztverantwortung automatisierter Systeme differenziert erörtern.
- EN 기존: I can precisely argue the efficiency, error costs, duty to explain, and human responsibility of automated systems.
- EN 제안: I can develop nuanced arguments about the efficiency of automation, the costs of errors, the duty to explain, and ultimate human responsibility.

## 검수와 승격의 남은 조건

- 사람이 KO·DE·EN 발화와 오답을 검수하고 수정 후보 해시를 승인해야 한다.
- 수준 적합성은 별도 판단이 필요하다. 구조 검사 통과로 C1/C2 판정을 대신하지 않는다.
- 승인 후 변경된 한국어 음성의 Storage 존재와 캐릭터 음성을 검증하고 후보·단원·런타임을 함께 동기화해야 한다.
- Batch 05 과거 단원 변경의 승인 근거와 copy history를 별도로 정리해야 한다.
