# 단어·예문 삼언어 검수: 2026-09-30

## 검수 기준과 범위

단어 하나를 `표제어 → 한국어 예문 → 영어·독일어 예문 → Satz·Cloze 파생 문항 → 발음·TTS`의 묶음으로 본다. 한국어를 먼저 실제 장면에서 말할 법한 문장인지 판단하고, EN·DE는 같은 행위자·관계·화행·사실·확신 정도를 전달하는지 각각 대조한다. C1·C2에서 어려운 명사를 만드는 대신 실제 공적·학술적 표현과 근거의 한계를 우선한다. 아래 제안은 **모델의 편집 후보**이며 Jin·원어민·한국어교육 전문가의 승인 기록이 아니다.

런타임 단어장 `korean_vocab.csv`의 2,944개 행(A1 735, A2 519, B1 650, B2 560, C1 240, C2 240)은 모두 KO·EN·DE 예문 칸이 채워져 있다. 레벨을 나눠 **표제어와 삼언어 예문 2,944개 묶음을 행별로 1차 읽기 검수**했고, 우선 수정 후보와 장면 확인 항목을 아래에 기록했다. 이는 모델의 첫 편집 선별이며 **사람 언어 검수·원어민 승인이나 무오류 판정이 아니다**. 한국어 예문으로 Satz와 Cloze를 연결하면 1,924개 단어 행에 두 게임 문항이 모두 연결된다. 연결되지 않은 1,020개가 곧 누락 오류라는 뜻은 아니다. 같은 한국어 문장에 다른 번역이 붙은 사례는 Satz 6개·Cloze 6개였고, 동의 표현과 페르소나 차이가 섞여 있어 일괄 덮어쓰지 않는다.

## 바로 고칠 수 있는 묶음

각 행의 `KO / EN / DE`는 **제안문**이다. 게임 정답이 되는 표제어는 유지하거나 함께 교체한다. 괄호 속 ID는 `vocab → Satz → Cloze` 순서다.

| 레벨·ID | 문제 | KO / EN / DE 제안 |
| --- | --- | --- |
| A1 `0319` / `0171` / `0207` | 번호 `3번`을 `삼 번`으로 띄어 적음. 표제어 `창구` 유지. | `3번 창구에서 기다리세요.` / `Please wait at counter number three.` / `Bitte warten Sie an Schalter drei.` |
| A1 `0782` / `0697` / `0716` | 한 명인 민호에게 독일어 `lasst uns`(복수 청자)라고 말함. 표제어 `그러면` 유지. | `민호 씨, 배가 고파요? 그러면 같이 밥을 먹어요.` / `Minho, are you hungry? Then let's eat together.` / `Minho, hast du Hunger? Dann essen wir zusammen.` |
| A2 `0393` / `0163` / `0200` | `횟수를 열 번으로 해요`는 실제 한국어로 부자연스럽고 EN·DE는 화자를 새로 지정함. 표제어 `횟수` 유지. | `이 동작의 반복 횟수는 열 번이에요.` / `This move calls for ten repetitions.` / `Diese Übung wird zehnmal wiederholt.` |
| B1 `0388` / `0196` / `0200` | `문 닫힘을 더 조용히 해요`는 비문에 가깝고 표제어 `문 닫힘`도 학습할 만한 명사로 부자연스러움. | 표제어 `문을 조용히 닫다`; 예문 `밤에는 문을 조용히 닫아요.` / `I close the door quietly at night.` / `Nachts schließe ich die Tür leise.` 다만 표제어의 품사·게임 정답도 함께 변경해야 함. |
| B2 `0500` / `0225` / `0239` | `도와드리겠습니다를` 인용 조사 오류, DE 비문, `자리가 열렸다`의 뜻 불명. 결과절을 임의로 만들지 않음. | `제가 “도와드리겠습니다”라고 큰 소리로 말했어요.` / `I said aloud, “I'll help.”` / `Ich sagte laut: „Ich helfe Ihnen.“` 표제어 `도와드리겠습니다` 유지. |
| B2 `0458` / `0183` / `0197` | DE 비문, EN은 원문에 없는 형제자매 관계를 추가함. | `같은 나이인데 높여 부르니 오히려 거리가 생겼어요.` / `Although we're the same age, addressing them so formally made us feel more distant.` / `Obwohl wir gleich alt sind, wirkte die betont höfliche Anrede eher distanzierend.` |
| C1 `0131` / `0137` / `0135` | `지속 가능 조건`·`Dauerbedingung`·`condition for staying viable`는 세 언어 모두 억지 명사화. 서비스 중단은 단정하지 않음. | 표제어 `지속 운영 조건`; `지속 운영 조건에 인력 교대 계획이 빠지면 서비스가 중단될 수 있어요.` / `If staff rotation is left out of the conditions for keeping the service running, the service may be interrupted.` / `Fehlt ein Plan für den Personalwechsel in den Bedingungen für einen dauerhaften Betrieb, kann der Dienst ausfallen.` |
| C2 `0093` / `0099` / `0097` | 책임 분산과 서명란 길이가 논리적으로 연결되지 않음. | `책임 분산이 심하면 최종 책임자를 서명란에 명시해요.` / `If responsibility is widely dispersed, I name the person ultimately responsible in the signature field.` / `Wenn die Verantwortung stark verteilt ist, halte ich im Unterschriftsfeld fest, wer letztlich verantwortlich ist.` 표제어 `책임 분산` 유지. |
| C2 `0095` / `0101` / `0099` | 위임장 부재가 자동으로 결정 취소 가능성을 만든다는 법적 단정은 근거 없음. | `권한 위임장 없이 대행하면 그 결정의 권한 근거가 불분명해질 수 있어요.` / `Without a written delegation of authority, the basis for that decision may be unclear.` / `Ohne schriftliche Übertragung der Befugnis kann unklar bleiben, auf welcher Grundlage diese Entscheidung getroffen wurde.` 실제 법적 효력 설명으로 사용하지 않음. |

### 적용된 단어·게임 번역 교정 (2026-10-01)

A1 `vocab_a1_0826`의 한국어 예문은 **자전거** 가격을 묻는데 영어만
`watch`라고 했다. 영어를 `This bicycle costs one million won.`으로 고치고
연결된 `satz_a1_0741`·`cloze_a1_0760`의 영어 문제도 같은 뜻으로 맞췄다.
기존 승인 초안은 보존하고 `promoted_copy_revisions_20260822.json`에
세 행의 변경 필드와 전후 지문을 후속 카피 수정으로 기록했다.
`validate_promoted_batch.py --manifest ...batch_30_a1_reinforcement_manifest.json`
검증은 186개 레코드에 대해 통과했다. 한국어 발화는 바뀌지 않아 새 TTS
키가 필요하지 않다.

같은 기준으로 세 묶음의 번역을 더 교정했다. A1 `vocab_a1_0331`의
`속이 쓰려서`는 독일어에서 메스꺼움이 아니라 속쓰림으로 옮기고
`satz_a1_0183`·`cloze_a1_0219`에도 반영했다. A1 `vocab_a1_0781`의
`빨리 가요`는 함께 출발하자는 문맥을 독일어에도 살려 `satz_a1_0696`·
`cloze_a1_0715`와 일치시켰다. B2 `vocab_b2_0171`의 음력 1월 1일은
달력 전체의 첫날이 아니라 음력 첫 달의 첫날이므로 EN·DE 예문과
`satz_b2_0458`·`skz_b2_007`, 원본 생성 스크립트를 함께 고쳤다.
Batch 09·30의 승인 초안은 보존하고 변경된 여섯 행의 후속 카피 지문을
리비전 원장에 기록했다. 한국어 발화는 바뀌지 않아 TTS 키는 그대로다.

B1 `vocab_b1_0430`은 학부모 상담 팩의 `상담 시간`을 영어
`office hour`로 오해하게 하던 부분을 고쳤다. 단어 뜻과 EN·DE 예문을
학부모 상담으로 구체화하고 `satz_b1_0238`·`cloze_b1_0242`의
번역도 맞췄다. Batch 09의 승인 초안과 기존 정답·오답은 보존하고 후속
카피 지문만 기록했다. 한국어 문장과 TTS 키는 그대로다.

**A1 두 번째 수정 묶음:** `vocab_a1_0054`는 실제 표제어 `파란색`을
예문에 넣고, `0069`·`0694`는 편의점을 독일의 `Spätkauf`나
`Supermarkt`로 바꾸지 않도록 했다. `0319`의 `삼 번`은 `3번`으로,
`0400`의 거친 명령형은 `다시 말해 주세요`로, `0802`의 부자연스러운
감탄 의문은 `이 가방 안에는 무엇이 있어요?`로 고쳤다. 마지막 문장은
Satz 조립 게임의 최소 세 어절 조건도 충족한다. `0782`의 독일어 복수
청유형도 한 명의 민호에게 맞게 고쳤다. 해당 Satz·Cloze·Silben·끝말잇기 단서와 기존 승인
초안 대비 후속 카피 지문을 동기화했다. 한국어가 바뀐 발화의 v3 TTS를
합성·Storage에 업로드한 뒤 정본 12,646개 기준 누락 0개를 확인했다.
음성의 발음·억양에 대한 사람 청취 평가는 아직 없다.

`vocab_a1_0775`의 `주일`을 `매주`로 바꾸는 안은 적용하지 않았다.
현 등급 사전에서 `매주`가 2등급이며 A1 팩에 그대로 치환하면 레벨
근거가 달라진다. 레벨 이동이나 A1 대체 어휘를 별도로 결정해야 한다.

**A2 후속 수정 묶음:** `vocab_a2_0393`의 어색한 횟수 표현은
`이 동작의 반복 횟수는 열 번이에요.`로, `0090`의 `맛이 진짜예요`는
`맛이 정말 좋아요`로, `0399`의 `주 이 번`은 `일주일에 두 번`으로
고쳤다. `0522`의 독일어는 동생의 성별을 추정하지 않도록
`jüngeres Geschwisterkind`로 바꾸고 영어도 자연스러운 문장으로
다듬었다. 연결된 Satz·Cloze의 문제·정답·번역을 함께 갱신하고
승인 초안 대비 후속 카피 지문을 기록했다. 앞서 수정한 A2
`vocab_a1_0331`의 `속이 쓰리다` 번역도 이 범위에 포함된다.
한국어가 새로 바뀐 세 발화의 TTS를 합성·Storage에 업로드하고
정본 12,646개 기준 누락 0개를 확인했다. 음성의 자연스러움에 대한
사람 청취 평가는 아직 없다.

## 장면·표제어를 먼저 잠가야 하는 묶음

| 레벨·ID (`vocab → Satz → Cloze`) | 확인한 문제와 다음 판단 |
| --- | --- |
| A2 `0296 → 0066 → 0103` | `성묘 옷`, `옷은 ... 색이 편해요`, `clothes for the grave visit` 모두 어색하다. `성묘할 때 입을 옷`처럼 바꾸고 색 선택을 말하려는 원래 의도인지 장면에서 확인한다. |
| B1 `0456 → 0264 → 0268` | `숙소 이월` / `stay shift`는 자연스럽지 않다. 한국어는 **상대가 답을 요구**, EN·DE는 **상대가 답할 예정**이라 방향이 반대다. 예약 변경 주체·날짜를 확인한 뒤 `숙소 예약 변경`을 중심으로 삼언어를 다시 쓴다. 관련 시나리오 초안에도 같은 표현과 조사 오류가 반복된다. |
| B1 `0344 → 0114 → 0151` | 실제 레벨은 B1이나 ID 접두사는 A2다. `좌석 배정이 떨어져서`가 어색하고 쪽지를 주고받는 장면이 불명확하다. 문자 메시지로 바꾸려면 매체까지 삼언어에서 함께 바꾼다. |
| B2 `0485 → 0210 → 0224` | `범위만 말하고 숫자를 피했어요`는 범위 자체가 숫자를 포함할 수 있어 모순처럼 읽힌다. 실제로 금액을 완전히 피했는지, 대략적인 범위만 제시했는지 확인한다. |
| C1 `0122 → 0128 → 0126` | `유지 부담` / `Folgelast` / `upkeep burden`은 비용 비교 문맥에서 어색하다. `유지·관리 비용`처럼 비용 항목을 명시할지 확인한다. |
| C1 `0143 → 0149 → 0147` | `결정 환류` / `Beschlussrückgabe` / `decision return`은 삼언어 모두 명사 직역이다. 참여자에게 **결정 결과를 알려주는 일**인지, 의견이 결정에 **반영되는 일**인지 먼저 구분한다. |
| C1 `0163 → 0169 → 0167` | `고장 대기` / `Störwartezeit` / `outage wait`은 대기 주체와 기간이 불명확하다. 수리 대기 시간인지 서비스 복구 시간인지 구분한다. |
| C2 `0060 → 0066 → 0064` | `자리를 문서화하다` / `den Platz dokumentieren`은 가족 내 역할·위치 중 무엇인지 불명확하다. 구체적 합의 기록이라면 그 사실을 예문에 적는다. |
| C2 `0100 → 0106 → 0104` | `연대기 절단` / `Chronikbruch` / `cut in the timeline`은 조어처럼 들리고 `남기어요`도 부자연스럽다. 사건의 앞뒤 맥락을 **의도적으로 생략**한다는 뜻인지 잠근 뒤 C2 담화 표현으로 다시 쓴다. |
| C2 `0117 → 0123 → 0121` | `결정 불가역` / `Vor der Unumkehrbarkeit`와 `철회 경로`의 관계가 불명확하다. 실제 취소 가능성에 관한 제도적 주장은 근거 확인 전 만들지 않는다. |
| C2 `0166 → 0172 → 0170` | `집단 소송점` / `Sammelpunkt` / `collective claim point`는 뜻을 특정하기 어렵다. 집단소송을 제기할 경로인지, 함께 이의를 제기할 창구인지 먼저 정한다. |

## C1·C2 전수 1차 재검토에서 추가로 확인한 항목

C1 240행·C2 240행의 표제어와 세 언어 예문을 행별로 다시 읽었다. 아래는 위 표와 겹치지 않는 우선 항목이다. `→` 뒤 두 ID는 Satz·Cloze다. 법·정책·기술 절차의 현실 사실은 외부 근거로 검증하지 않았으므로 제도적 단정으로 승격하지 않는다.

| 묶음 | 판단과 교정 방향 |
| --- | --- |
| C1 `0055 → 0061 → 0059` | `가족 서사에 제가 갑자기 주인공이 되어 부담됐어요`는 `가족 서사에서 제가 갑자기 주인공이 되자 부담스러웠어요`가 자연스럽다. DE `... druckte`는 오용이므로 `Plötzlich die Hauptfigur in der Familiengeschichte zu sein, setzte mich unter Druck.` EN `It felt overwhelming to suddenly become the main character in the family’s story.` |
| C1 `0090 → 0096 → 0094` | `속보 절제/Eilzurückhaltung` 조어를 피한다. 표제어 `속보를 자제하다`; KO `확인 전에는 속보를 자제하고 다음 확인 시각을 알려요.` / EN `I hold off on a breaking update until it is checked and say when the next check is due.` / DE `Vor der Prüfung halte ich eine Eilmeldung zurück und nenne den Zeitpunkt der nächsten Überprüfung.` 정답 품사·TTS도 함께 변경. |
| C1 `0154 → 0160 → 0158` | `야간 조명을 높이면 안전은 오르고 수면은 나빠져요`는 두 결과를 조건 없이 확정한다. KO `야간 조명을 늘릴 때는 보행 안전과 주변 주민의 수면에 미칠 영향을 함께 살펴요.` / EN `When adding night lighting, we consider both pedestrian safety and possible effects on nearby residents’ sleep.` / DE `Bei zusätzlicher Nachtbeleuchtung prüfen wir sowohl die Sicherheit von Fußgängern als auch mögliche Auswirkungen auf den Schlaf der Anwohnenden.` |
| C1 `0188 → 0194 → 0192` | `밤에 몰아서 하는 역효과가 보고됐습니다`는 무엇을 몰아서 하는지 빠졌고 출처 없는 보고 주장이다. KO `밤에 이용이 몰리는 역효과가 나타났는지 확인해야 합니다.` / EN `We need to check whether use shifted into the night as an unintended effect.` / DE `Wir müssen prüfen, ob sich die Nutzung als unerwünschter Effekt in die Nacht verlagert hat.` 실제 보고서가 있다면 출처를 살린 안으로 다시 쓴다. |
| C2 `0115 → 0121 → 0119` | `완곡 금지/Euphemismusstopp`는 조어. `완곡어법`을 가르치려면 KO `해고를 '정리'라고만 표현하면 실제로 일자리를 잃는 사람이 가려져요.` / EN `Describing a dismissal only with a euphemism can obscure the fact that someone is losing their job.` / DE `Wenn eine Entlassung nur beschönigend umschrieben wird, gerät aus dem Blick, dass jemand seine Stelle verliert.` |
| C2 `0141 → 0147 → 0145` | `로그 변조를 탐지하는 서명/ co-signature`는 검증 방식이 없는 기술적 암시다. KO `로그 변조를 탐지하려면 로그의 무결성을 검증할 방법이 필요해요.` / EN `To detect log tampering, we need a way to verify the integrity of the logs.` / DE `Um Manipulationen an Protokollen zu erkennen, brauchen wir eine Möglichkeit, ihre Integrität zu prüfen.` |
| C2 `0149 → 0155 → 0153` | 이의 기간 중 자동 `처리 정지`를 보편적 의무처럼 단정한다. 특정 제도 근거가 없으면 KO `이의 제기 기간에 처리 정지를 자동으로 적용할지 검토해야 해요.` / EN `We need to consider whether processing should pause automatically during the appeal period.` / DE `Wir müssen prüfen, ob die Bearbeitung während der Einspruchsfrist automatisch ausgesetzt werden soll.` |
| C2 `0159 → 0165 → 0163` | `피드백 왜곡/Rückkopplungskrümmung/feedback warp`의 직역을 고친다. KO `피드백 왜곡이 생기면 과거의 거절이 이후 판단에도 반복해서 반영될 수 있어요.` / EN `If a feedback loop is distorted, past rejections can keep influencing later decisions.` / DE `Wenn Rückkopplungen verzerrt sind, können frühere Ablehnungen spätere Entscheidungen erneut beeinflussen.` |
| C2 `0187 → 0193 → 0191` | `처벌의 무게가 비례에 맞는지`는 비교 대상이 빠진 결합 오류. KO `처벌의 무게가 위반의 정도에 비례하는지 따로 봅니다.` / EN `We separately examine whether the severity of the penalty is proportionate to the violation.` / DE `Wir prüfen gesondert, ob die Schwere der Sanktion im Verhältnis zum Verstoß steht.` |

장면 확인이 먼저 필요한 추가 묶음: C1 `0052 → 0058 → 0056`(`역할 언어`), `0057 → 0063 → 0061`(`말의 자리`), `0065 → 0071 → 0069`(`전통의 선택`), `0085 → 0091 → 0089`(근거 없는 브리핑 문안 규칙), `0088 → 0094 → 0092`(`질의 시간 공개`의 대상); C2 `0052 → 0058 → 0056`(`체면 경제`), `0120 → 0126 → 0124`(`발화의 자리`), `0174 → 0180 → 0178`(근거 불명 3영업일 기한). 이들은 표제어만 기계적으로 바꾸면 문항 목표 자체가 달라진다.

## A1·A2 전수 1차 재검토에서 추가로 확인한 항목

A1 735행·A2 519행을 표제어와 KO/EN/DE 예문 단위로 읽었다. 아래는 앞 표와 겹치지 않는 고확신 수정 후보이며, 원문이 특정하지 않은 인물·관계·도구는 새로 만들지 않는다. `→` 뒤 ID는 연결된 Satz·Cloze이며 `—`는 해당 게임에 정확히 같은 예문이 없음을 뜻한다.

| 묶음 | 판단과 교정 방향 |
| --- | --- |
| A1 `0069 → — → 0046` | `편의점`을 DE `Spätkauf`(독일의 특정 야간점포)로 바꾸면 장소가 달라진다. `Ich kaufe es im Minimarkt.`처럼 가게 유형을 유지. |
| A1 `0219 → 0071 → 0107` | `부모님`에 EN/DE `his/seinen`으로 남성 소유자를 추가했고 DE `Höflichkeitsform`은 한국어 높임말을 단순 Sie 대응처럼 만든다. EN `I use honorific speech around parents.` / DE `Im Gespräch mit Eltern verwende ich respektvolle Sprache.` 장면에서 누구의 부모인지 미정. |
| A1 `0256 → 0108 → 0144` | 젓가락이 서툰 게 아니라 **젓가락질**이 서툴다. DE `Weil ich mit Stäbchen noch ungeschickt bin, sind mir die Sojasprossen heruntergefallen.` EN의 `chopstick skills`도 `I'm still clumsy with chopsticks, so I dropped the bean sprouts.`가 자연스럽다. |
| A1 `0281 → 0133 → 0169` | 표제어 `솔잎`이 현 예문 `이건 잎을 떼고 먹어요`에는 없고 Cloze는 `잎을`을 정답으로 삼는다. KO `송편에 붙은 솔잎을 떼고 먹어요.` / EN `I remove the pine needles from the songpyeon before eating it.` / DE `Vor dem Essen entferne ich die Kiefernnadeln vom Songpyeon.` 문항 정답·TTS 변경. |
| A1 `0331 → 0183 → 0219` | `속이 쓰려서`는 EN heartburn인데 DE `Mir ist übel`(메스꺼움). DE `Ich habe Sodbrennen, deshalb habe ich ein Antazidum gekauft.` |
| A1 `0387 → 0239 → 0275` | `습하다 느껴져서` 활용 오류. 습한 바깥 공기 때문에 창문을 연다는 인과도 어색하다. KO `오늘은 공기가 습하게 느껴져요.` / EN `The air feels humid today.` / DE `Die Luft fühlt sich heute feucht an.` Cloze 정답 표면형과 TTS 변경. |
| A1 `0388 → 0240 → 0276` | `아침이 쌀쌀하다 해서`는 현재 장면에서 어색하고 번역의 현재형이 한국어 과거형과 어긋난다. KO `아침이 쌀쌀해서 목을 가렸어요.` / EN `It was chilly this morning, so I covered my neck.` / DE `Weil es heute Morgen kühl war, habe ich meinen Hals bedeckt.` 목도리 같은 소품은 새로 만들지 않는다. |
| A1 `0400 → 0252 → 0288` | 모르는 사람에게 `다시 말하세요`는 번역의 공손한 요청보다 거칠다. KO `잘 못 들었어요. 다시 말해 주시겠어요?` / EN `I didn't catch that. Could you say it again?` / DE `Ich habe Sie nicht gut verstanden. Könnten Sie das bitte noch einmal sagen?` Cloze 정답 재설계 필요. |
| A1 `0694 → 0609 → 0628` | `편의점`이 DE `Supermarkt`가 됐다. `Ich jobbe in einem Convenience-Store.`처럼 한국식 점포 개념 유지. |
| A1 `0781 → 0696 → 0715` | KO `빨리 가요`는 함께 가자는 제안, DE `gehe ich schnell`은 혼자 간다는 진술. DE `Ich habe keine Zeit. Deswegen sollten wir schnell los.` |
| A1 `0802 → 0717 → 0736` | `이것은 정말 무엇이에요?`는 감탄·의문 결합이 어색하다. KO `이게 도대체 무엇인가요?` / EN `What on earth is this?` / DE `Was ist das denn?` Cloze 정답·TTS 확인. |
| A1 `0826 → 0741 → 0760` | KO/DE는 **자전거**, EN은 **시계**. EN `This bicycle costs one million won.` |
| A2 `0090 → 0309 → —` | `이 집 김치찌개 맛이 진짜예요`는 자연스럽지 않고 번역도 과장한다. KO `이 집 김치찌개는 맛이 정말 좋아요.` / EN `The kimchi stew here tastes really good.` / DE `Der Kimchi-Eintopf hier schmeckt wirklich gut.` |
| A2 `0399 → 0169 → 0206` | `근력 운동은 주 이 번만 해요`의 횟수 표현 오류. KO `근력 운동은 일주일에 두 번만 해요.` EN·DE 현 문장은 의미상 유지 가능. TTS 변경. |
| A2 `0497 → 0489 → 0304` | KO `시간표를 보고 시간을 정해요`는 단수 주체의 진술인데 EN `Let's`, DE `Wir`는 함께 하자는 제안. EN `I check the timetable and decide on a time.` / DE `Ich schaue auf den Stundenplan und lege dann eine Uhrzeit fest.` |
| A2 `0522 → 0514 → 0329` | `동생`은 성별 미상인데 DE `Schwester`가 여동생을 만든다. EN `My younger sibling is really kind.` / DE `Mein jüngeres Geschwisterkind ist wirklich lieb.` 한국어는 유지. |

장면·표제어를 먼저 확인할 항목: A1 `0054 → 0268 → —`(표제어 `파란색`인데 예문은 형용사 `파래요`만 사용), `0336 → 0188 → 0224`(`미리 연락`의 관계에 따른 du/Sie·Cloze 정답), `0541 → — → 0475`(`일본을 찍다`의 대상), `0775 → 0690 → 0709`(현대 한국어에서 `이번 주일`이 `이번 주`인지 일요일인지); A2 `0251 → — → —`(`동생` 성별을 EN brother로 지정), `0271 → 0041 → 0078`(화자 성별 미상인데 DE Designerin), `0345 → 0115 → 0152`(김치 수하물 규칙과 무릎 보관의 장면 근거).

추가로 A1 `0543 → — → 0477`의 `영국에서 오셨어요?`를 EN `England`, DE `England`로 좁힌 것은 오류다. EN `Are you from the UK?`, DE `Kommen Sie aus dem Vereinigten Königreich?`가 범위를 보존한다.

## B1·B2 전수 1차 재검토에서 추가로 확인한 항목

B1 650행·B2 560행의 표제어와 삼언어 예문을 행별로 읽었다. 아래는 앞 표와 겹치지 않는 우선 후보이며, `→` 뒤 ID는 연결된 Satz·Cloze다. 정확히 같은 예문이 없는 게임은 `—`로 표시한다.

| 묶음 | 판단과 교정 방향 |
| --- | --- |
| B1 `0065 → 0306 → —` | KO `앱 다운로드부터 받으셔야 해요`는 `다운로드를 받다`의 중복. KO `먼저 앱을 다운로드하셔야 해요.` / EN `You need to download the app first.` / DE `Sie müssen zuerst die App herunterladen.` |
| B1 `0283 → 0091 → 0095` | `다음에 말씀드릴게요 하고`는 인용 구문 오류, DE 직접화법도 성립하지 않는다. KO `“다음에 말씀드릴게요”라고 하니 시간을 벌면서도 분위기를 해치지 않았어요.` / EN `Saying “I'll tell you another time” bought me time without spoiling the mood.` / DE `Mit „Ich erzähle es Ihnen ein andermal“ gewann ich Zeit, ohne die Stimmung zu verderben.` |
| B1 `0294 → 0102 → 0106` | `통역 없이`는 통역사 없이 **직접 말하기**인데 EN/DE는 통역 행위를 하지 않는 것으로 읽힌다. KO `통역 없이 직접 말할 문장 세 개만 준비해 갔어요.` / EN `I prepared just three sentences to say myself, without an interpreter.` / DE `Ich hatte nur drei Sätze vorbereitet, die ich ohne Dolmetscher selbst sagen wollte.` |
| B1 `0430 → 0238 → 0242` | 학부모 상담 팩의 `상담 시간`을 EN `office hour`로 바꾸면 제도·장면이 달라진다. EN `The parent consultation is fifteen minutes long, so I write down my questions beforehand.` / DE `Das Elterngespräch dauert fünfzehn Minuten, deshalb notiere ich meine Fragen vorher.` KO 유지. |
| B1 `0470 → — → 0278` | `자기소개서`를 영미 `cover letter`, DE `Anschreiben`으로 치환했다. 한국 지원 문서가 정본이면 EN `application statement`, DE `schriftliche Selbstvorstellung für die Bewerbung`로 풀어 쓰고 문화 메모를 검토. |
| B2 `0061 → — → —` | KO `석사 학위까지 마치셨더라고요`는 뒤늦게 알았다는 화자 관점이 있고 성별은 미상이다. EN `I learned that they had even completed a master's degree.` / DE `Wie ich erfahren habe, hat die Person sogar einen Masterabschluss gemacht.` |
| B2 `0105 → 0407 → —` | `사회생활`을 DE `Berufsleben`으로 직장생활에 한정했다. EN `Manners matter when dealing with others.` / DE `Im Umgang mit anderen Menschen ist Höflichkeit wichtig.` |
| B2 `0135 → 0427 → —` | KO는 **에어컨 온도**를 조절했는데 EN/DE는 에어컨 자체를 조절한 것으로 흐려졌다. EN `I adjusted the temperature setting on the air conditioner.` / DE `Ich habe die Temperatur an der Klimaanlage eingestellt.` |
| B2 `0171 → 0458 → —` | `음력 1월 1일`은 달력의 첫날이 아니라 음력 **첫 달의 첫날**. EN `Seollal falls on the first day of the first lunar month.` / DE `Seollal fällt auf den ersten Tag des ersten Monats im Mondkalender.` |
| B2 `0195 → 0482 → —` | 한국어 높임 `성함`을 DE `werter Name`이라는 고풍스러운 표현으로 옮겼다. DE 질문은 `Wie heißen Sie?`가 자연스럽다. |
| B2 `0253 → 0090 → 0106` | `부탁`·`요구`의 어감은 음향 `Klangwirkung`보다 화용적 느낌이다. DE `Auch wenn „부탁“ und „요구“ Ähnliches bedeuten, unterscheiden sie sich in ihrer Wirkung.` |
| B2 `0288 → 0125 → 0141` | KO `서로 다른 두 출처`는 DE `zwei voneinander unabhängigen Quellen`처럼 **독립성**을 보증하지 않는다. DE `zwei verschiedenen Quellen`. |
| B2 `0595 → 0320 → 0334` | 공개의 **내부·외부 범위**를 DE `Öffnungsgrad`로 옮기면 공개 정도로 뜻이 바뀐다. EN `I record the scope of internal and external disclosure separately.` / DE `Ich halte den Umfang der internen und externen Veröffentlichung getrennt fest.` |
| B2 `0602 → 0327 → 0341` | `보상 한도`를 goodwill/Kulanz로 옮겨 보상이 호의적이라는 속성을 덧붙였다. KO `보상 한도를 먼저 밝히면 기대치를 맞출 수 있어요.` / EN `Stating the compensation limit up front helps set expectations.` / DE `Wenn man die Obergrenze der Entschädigung gleich nennt, lassen sich Erwartungen besser abstimmen.` |

**B1 후속 수정 묶음:** `vocab_b1_0065`의 중복된 `다운로드를
받다`를 자연스러운 동사형으로 바꾸고, `0283`의 인용 구문과
독일어 직접화법을 바로잡았다. `0294`는 통역 행위를 하지 않는다는
뜻 대신 통역사 없이 직접 말할 문장을 준비했다는 뜻으로 세 언어를
맞췄다. `0430`의 학부모 상담 시간과 `0470`의 한국식 자기소개서도
영미·독일 제도 문서에 성급히 등치하지 않도록 고쳤다. `0457`의
탑승 마감 예문은 체크인 카운터가 아니라 탑승구에 도착하는 상황으로
수정했다. 연결된 Satz·Cloze와 승인 초안 대비 후속 카피 지문을
갱신했다. 한국어가 바뀐 네 발화의 TTS를 합성·Storage에
업로드한 뒤 정본 12,646개 기준 누락 0개를 확인했다. 실제 발음과
억양의 사람 청취 평가는 아직 없다.

장면·제도 확인 우선: B1 `0179 → 0392 → —`(`조카`를 niece/Nichte로 성별 지정), `0200 → 0411 → —`(`동생`을 여동생으로 지정), `0318 → 0126 → 0130`(`술을 물로 받다`의 대체·희석·동시 제공 불명), `0378 → 0186 → 0190`(이메일 끝인사의 실제 화행), `0457 → 0265 → 0269`(`탑승 마감`인데 카운터/체크인 마감으로 번역); B2 `0406 → 0495 → —`(장애 자체를 `이겨 냈다`고 단정), `0539 → 0264 → 0278`(한국 내용증명과 독일 제도 오등치), `0547 → 0272 → 0286`(근거 없는 법정 퇴거 기한), `0581 → 0306 → 0320`(`시간 상자` 조어·품사 재설계). B2 `0485`와 `0500`은 위의 장면 확인 표에도 있다.

## 파생·정답·음성 게이트

- 같은 한국어 예문이 Satz와 Cloze에 나타나면 `targetKo/fullKo/sentenceKo`, DE·EN 프롬프트, Cloze 정답·오답을 함께 확인한다. 표제어가 바뀌면 초성·음절 퍼즐·끝말잇기 노출도 확인한다. A1 `0319`와 A2 `0393`처럼 한국어 발화가 바뀌는 경우에는 v3 TTS 캐시 키도 다시 생성한다.
- 현재 단어장과 게임의 동일 한국어 예문 간 번역 차이는 Satz 6개·Cloze 6개다. 예: `vocab_a1_0013`의 `Ich bin Student.`와 `cloze_a1_0306`의 `Ich bin Studentin.`은 한국어 `저는 학생이에요.`만으로 성별을 확정할 수 없다. 무조건 어느 한쪽으로 통일하지 않고 인물 설정을 확인한다.
- 읽기 전용 구조 검사에서 178개 듣기 lesson의 `audioKo`·`evidenceKo`는 시나리오 대사와 일치했다. 이것은 정답 의미·사람의 실제 청취 평가를 대신하지 않는다. `python3 tool/generate_tts.py --download-first-line-bundle` 결과는 유니크 176개 중 신규 다운로드 0개였다. 이미 로컬 `assets/tts/v3/`에 있는 음원 키를 확인한 결과다.
- **승격 지문 복구(2026-10-01):** Batch 09의 `cloze_b2_0304` 지문 실패는 승인 당시 초안이 수정된 것이 원인이었다. Batch 09·18의 고정 초안을 승인 원본으로 돌리고 후속 카피 지문을 별도 리비전 원장에 기록해 두 배치 검증을 통과시켰다(1,764건·132건). 승인 기록 CSV는 그대로다. 이 검증은 위의 새 교정 *제안* 70여 건이 앱에 적용됐거나 사람 승인을 받았다는 뜻이 아니다. 미승인·미병합 manifest를 일괄 검증 대상으로 취급하지 않는다.
