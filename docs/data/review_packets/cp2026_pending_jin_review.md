# CP-2026 콘텐츠 통합 검수

2026-09-16 현재 파일에서 다시 추출했다. 모든 항목은 **Jin 판정 대기**다. 작업 재개 승인이나 CI 성공을 콘텐츠 승인으로 기록하지 않는다.

**검수 가능본:** Batch 32·33 표본 4건과 C9 노트의 지적사항을 수정하고 독립 모델 재검토를 통과한 통합 소스에서 다시 추출했다. 모델 검토 통과는 Jin의 콘텐츠 승인을 대신하지 않는다.

기준 main: `61f5c819`; C9-1: PR #362의 수정 커밋 `0eeb8937`을 포함한 통합본. 수정 요청은 배치와 표제어 또는 ID로 지정하면 된다. 아래 표는 원문이며, 새 검토에서 결함이 확인되면 수정 후 다시 추출한다.

## 새로 복구한 콘텐츠

- [C4-G1 문법 12개 전체 검수](c4_g1_grammar_jin_sample.md): 신규 9개·기존 3개 확장, 두 예문과 번역·퀴즈·등록 단위를 확인한다.
- [Batch 34 A2 7어 표본 검수](batch_34_a2_jin_sample.md): 64어 초안에서 추출한 표본이며 예문과 세 오답의 적합성을 확인한다.

아래 기존 대기분 24항목과 위 두 패킷 모두 Jin 판정 대기다. 승인 또는 수정 요청은 작업명과 ID를 함께 적으면 된다.

## Batch 32: A2 표본 7어

원본 CSV SHA-256: `33f88789dcd5a026b733a8fbd42ca821741088047bc0cb113fb399d2b801ed0c`

### 어깨 · vocab_a2_0568

뜻: Schulter / shoulder

KO: 가방이 너무 무거워서 어깨가 아파요.

DE: Die Tasche ist zu schwer, deshalb tut meine Schulter weh.

EN: The bag is too heavy, so my shoulder hurts.

빈칸: 가방이 너무 무거워서 ＿＿＿ 아파요.

정답: **어깨가** · 오답: 두부가 / 소고기가 / 오이가

오답을 넣은 문장:

- 가방이 너무 무거워서 두부가 아파요.
- 가방이 너무 무거워서 소고기가 아파요.
- 가방이 너무 무거워서 오이가 아파요.

판정: 미입력

### 목소리 · vocab_a2_0577

뜻: Stimme / voice

KO: 수진 씨, 목소리가 하나도 안 들려요!

DE: Sujin, ich kann Sie überhaupt nicht hören!

EN: Sujin, I can't hear you at all!

빈칸: 수진 씨, ＿＿＿ 하나도 안 들려요!

정답: **목소리가** · 오답: 가방이 / 시장이 / 사진이

오답을 넣은 문장:

- 수진 씨, 가방이 하나도 안 들려요!
- 수진 씨, 시장이 하나도 안 들려요!
- 수진 씨, 사진이 하나도 안 들려요!

판정: 미입력

### 설렁탕 · vocab_a2_0586

뜻: Rinderknochensuppe / seolleongtang (ox bone soup)

KO: 추운 날에는 뜨거운 설렁탕이 최고예요.

DE: An kalten Tagen ist heiße Rinderknochensuppe am besten.

EN: On a cold day, hot seolleongtang is the best.

빈칸: 추운 날에는 뜨거운 ＿＿＿ 최고예요.

정답: **설렁탕이** · 오답: 도서관이 / 생각이 / 회사가

오답을 넣은 문장:

- 추운 날에는 뜨거운 도서관이 최고예요.
- 추운 날에는 뜨거운 생각이 최고예요.
- 추운 날에는 뜨거운 회사가 최고예요.

판정: 미입력

### 속옷 · vocab_a2_0595

뜻: Unterwäsche / underwear

KO: 여행 가방에 속옷부터 넣었어요.

DE: Ich habe zuerst die Unterwäsche in den Koffer gelegt.

EN: I put underwear into the suitcase first.

빈칸: 여행 가방에 ＿＿＿ 넣었어요.

정답: **속옷부터** · 오답: 기분부터 / 도서관부터 / 체육관부터

오답을 넣은 문장:

- 여행 가방에 기분부터 넣었어요.
- 여행 가방에 도서관부터 넣었어요.
- 여행 가방에 체육관부터 넣었어요.

판정: 미입력

### 관광객 · vocab_a2_0604

뜻: Tourist / tourist

KO: 이 거리에는 관광객이 사진을 많이 찍어요.

DE: Auf dieser Straße machen Touristen viele Fotos.

EN: Tourists take a lot of photos on this street.

빈칸: 이 거리에는 ＿＿＿ 사진을 많이 찍어요.

정답: **관광객이** · 오답: 일기가 / 계획이 / 모자가

오답을 넣은 문장:

- 이 거리에는 일기가 사진을 많이 찍어요.
- 이 거리에는 계획이 사진을 많이 찍어요.
- 이 거리에는 모자가 사진을 많이 찍어요.

판정: 미입력

### 항공권 · vocab_a2_0613

뜻: Flugticket / plane ticket

KO: 항공권을 미리 예매했어요.

DE: Ich habe das Flugticket im Voraus gebucht.

EN: I booked the plane ticket in advance.

빈칸: ＿＿＿ 미리 예매했어요.

정답: **항공권을** · 오답: 지갑을 / 그림을 / 소고기를

오답을 넣은 문장:

- 지갑을 미리 예매했어요.
- 그림을 미리 예매했어요.
- 소고기를 미리 예매했어요.

판정: 미입력

### 학원 · vocab_a2_0622

뜻: private Bildungseinrichtung, Akademie / private institute, academy

KO: 저녁마다 태권도 학원에 가요.

DE: Jeden Abend gehe ich zur Taekwondo-Schule.

EN: Every evening, I go to a taekwondo academy.

빈칸: 저녁마다 태권도 ＿＿＿ 가요.

정답: **학원에** · 오답: 은행에 / 식당에 / 카페에

오답을 넣은 문장:

- 저녁마다 태권도 은행에 가요.
- 저녁마다 태권도 식당에 가요.
- 저녁마다 태권도 카페에 가요.

판정: 미입력

## Batch 33: A2 표본 7어

원본 CSV SHA-256: `445227dde4b5a1e5e15025fa78f657b52be6b3dcfd2ea62d08a3f66cf72700f7`

### 놓다 · vocab_a2_0632

뜻: hinlegen, hinstellen / to put, to place

KO: 가방을 의자 위에 놓았어요.

DE: Ich habe die Tasche auf den Stuhl gelegt.

EN: I put the bag on the chair.

빈칸: 가방을 의자 위에 ＿＿＿.

정답: **놓았어요** · 오답: 앉았어요 / 울었어요 / 잤어요

오답을 넣은 문장:

- 가방을 의자 위에 앉았어요.
- 가방을 의자 위에 울었어요.
- 가방을 의자 위에 잤어요.

판정: 미입력

### 콧물 · vocab_a2_0641

뜻: laufende Nase, Nasensekret / runny nose

KO: 콧물이 나서 휴지로 코를 닦았어요.

DE: Meine Nase lief, deshalb habe ich mir mit einem Taschentuch die Nase abgewischt.

EN: My nose was running, so I wiped it with a tissue.

빈칸: ＿＿＿ 나서 휴지로 코를 닦았어요.

정답: **콧물이** · 오답: 정거장이 / 주차장이 / 매표소가

오답을 넣은 문장:

- 정거장이 나서 휴지로 코를 닦았어요.
- 주차장이 나서 휴지로 코를 닦았어요.
- 매표소가 나서 휴지로 코를 닦았어요.

판정: 미입력

### 치과 · vocab_a2_0650

뜻: Zahnarztpraxis / dental clinic

KO: 이가 아파서 치과에 예약을 했어요.

DE: Ich hatte Zahnschmerzen, deshalb habe ich einen Termin beim Zahnarzt gemacht.

EN: I had a toothache, so I made an appointment at the dentist.

빈칸: 이가 아파서 ＿＿＿ 예약을 했어요.

정답: **치과에** · 오답: 눈물에 / 농담에 / 비밀에

오답을 넣은 문장:

- 이가 아파서 눈물에 예약을 했어요.
- 이가 아파서 농담에 예약을 했어요.
- 이가 아파서 비밀에 예약을 했어요.

판정: 미입력

### 웃음 · vocab_a2_0659

뜻: Lachen / laughter

KO: 그 사진을 보면 웃음이 나요.

DE: Wenn ich das Foto sehe, muss ich lachen.

EN: When I see that photo, I laugh.

빈칸: 그 사진을 보면 ＿＿＿ 나요.

정답: **웃음이** · 오답: 선배가 / 후배가 / 우산이

오답을 넣은 문장:

- 그 사진을 보면 선배가 나요.
- 그 사진을 보면 후배가 나요.
- 그 사진을 보면 우산이 나요.

판정: 미입력

### 정거장 · vocab_a2_0668

뜻: Haltestelle / stop (bus/tram)

KO: 다음 정거장에서 내려서 왼쪽으로 가세요.

DE: Steigen Sie an der nächsten Haltestelle aus und gehen Sie nach links.

EN: Get off at the next stop and go left.

빈칸: 다음 ＿＿＿ 내려서 왼쪽으로 가세요.

정답: **정거장에서** · 오답: 칭찬에서 / 긴장에서 / 웃음에서

오답을 넣은 문장:

- 다음 칭찬에서 내려서 왼쪽으로 가세요.
- 다음 긴장에서 내려서 왼쪽으로 가세요.
- 다음 웃음에서 내려서 왼쪽으로 가세요.

판정: 미입력

### 선배 · vocab_a2_0677

뜻: dienstälteres Teammitglied / senior (colleague)

KO: 회사 선배가 점심을 사 줬어요.

DE: Ein Teammitglied, das schon länger in der Firma ist, hat mir das Mittagessen bezahlt.

EN: A senior colleague bought me lunch.

빈칸: 회사 ＿＿＿ 점심을 사 줬어요.

정답: **선배가** · 오답: 새벽이 / 행사가 / 박수가

오답을 넣은 문장:

- 회사 새벽이 점심을 사 줬어요.
- 회사 행사가 점심을 사 줬어요.
- 회사 박수가 점심을 사 줬어요.

판정: 미입력

### 노력 · vocab_a2_0686

뜻: Mühe, Anstrengung / effort

KO: 노력을 많이 하면 한국어가 빨리 늘어요.

DE: Wenn man sich viel Mühe gibt, wird das eigene Koreanisch schnell besser.

EN: If you put in a lot of effort, your Korean improves quickly.

빈칸: ＿＿＿ 많이 하면 한국어가 빨리 늘어요.

정답: **노력을** · 오답: 지하도를 / 사거리를 / 정거장을

오답을 넣은 문장:

- 지하도를 많이 하면 한국어가 빨리 늘어요.
- 사거리를 많이 하면 한국어가 빨리 늘어요.
- 정거장을 많이 하면 한국어가 빨리 늘어요.

판정: 미입력

## C9-1: B1 심화 노트 표본 10어

**현재 상태: 120노트 전체 검토와 지적사항 수정·독립 재검토 완료. 신규 100개 중 92개를 교정했고 파일럿 20개를 보존했다. Jin 판정 대기.**

원본 JSON SHA-256: `fb294223c84ba02e1941a93832e523d6bddefe4debcb1f758a9727abc3f9057f`

뉘앙스와 추가 예문을 세 언어로 싣는다. 상황·문형·연어·대비를 포함한 전체 내용은 [원본 패킷](c9_1_usage_notes_jin_sample.md)에서 확인한다.

### 막내 · vocab_a1_0290

뉘앙스:

KO: 막내는 형제자매나 집단에서 나이가 가장 어린 사람을 가리키며, 다정한 느낌이 드는지는 관계와 문맥에 따라 다르다.

DE: 막내 bezeichnet das jüngste Geschwister oder Gruppenmitglied; ob es liebevoll klingt, hängt von Beziehung und Kontext ab.

EN: 막내 refers to the youngest sibling or group member; whether it sounds affectionate depends on the relationship and context.

예문 1 (formal):

KO: 저희 집 막내는 이제 대학생이 되었습니다.

DE: Unser jüngstes Kind studiert jetzt an der Universität.

EN: Our youngest has now become a university student.

예문 2 (casual):

KO: 막내는 항상 제일 늦게 일어나요.

DE: Das Nesthäkchen wacht immer als Letztes auf.

EN: The youngest always wakes up last.

판정: 미입력

### 해결 · vocab_b1_0009

뉘앙스:

KO: 해결은 문제나 갈등을 풀거나 어려운 일을 처리하는 것을 가리킨다.

DE: 해결 bezeichnet das Lösen eines Problems, das Beilegen eines Konflikts oder das Bewältigen einer Schwierigkeit.

EN: 해결 refers to solving a problem, resolving a conflict, or dealing with a difficulty.

예문 1 (formal):

KO: 이번 회의에서는 소음 문제의 해결 방안을 논의하겠습니다.

DE: In dieser Sitzung werden wir Möglichkeiten zur Lösung des Lärmproblems erörtern.

EN: In this meeting, we will discuss ways to resolve the noise problem.

예문 2 (casual):

KO: 그 일 어떻게 해결했어?

DE: Wie hast du das Problem gelöst?

EN: How did you solve that problem?

판정: 미입력

### 참여하다 · vocab_b1_0036

뉘앙스:

KO: 참여하다는 활동이나 일에 함께하는 것을 가리키며, 참여의 방식이나 적극성은 문맥에 따라 달라진다.

DE: 참여하다 bedeutet, bei einer Tätigkeit mitzumachen; wie und wie intensiv, ergibt sich aus dem Kontext.

EN: 참여하다 means taking part in an activity; the form and degree of involvement depend on context.

예문 1 (written):

KO: 작년에는 세 학교가 공동 연구에 참여했습니다.

DE: Im vergangenen Jahr haben drei Schulen an der gemeinsamen Studie teilgenommen.

EN: Last year, three schools participated in the joint study.

예문 2 (casual):

KO: 이번 봉사 활동에 같이 참여할래?

DE: Machst du bei dieser Freiwilligenarbeit mit?

EN: Want to join in on this volunteer activity together?

판정: 미입력

### 진행하다 · vocab_b1_0070

뉘앙스:

KO: 진행하다는 일을 이어 나가거나 회의와 행사 등을 맡아 이끄는 것을 가리킨다.

DE: 진행하다 bedeutet, eine Sache voranzubringen oder eine Besprechung beziehungsweise Veranstaltung durchzuführen.

EN: 진행하다 means moving work forward or conducting a meeting or event.

예문 1 (formal):

KO: 오늘 설명회는 질문을 먼저 받고 진행하겠습니다.

DE: Bei der heutigen Informationsveranstaltung sammeln wir zunächst Ihre Fragen und fahren dann fort.

EN: At today’s information session, we will take your questions first and then proceed.

예문 2 (casual):

KO: 자료가 아직 없어서 회의를 진행하기가 어렵겠어요.

DE: Ohne die Unterlagen wird es wohl schwierig, die Besprechung durchzuführen.

EN: We don’t have the materials yet, so I think it’ll be hard to run the meeting.

판정: 미입력

### 전통 · vocab_b1_0111

뉘앙스:

KO: 전통은 한 사회나 집단에서 여러 세대에 걸쳐 이어져 내려온 문화나 방식을 가리키며, 명절이나 지역 축제와 관련된 글에서 자주 쓴다.

DE: 전통 bezeichnet eine Kultur oder Weise, die in einer Gesellschaft über mehrere Generationen weitergegeben wurde; man findet es oft in Texten über Feiertage oder lokale Feste.

EN: 전통 refers to a culture or way of doing things passed down over generations within a society; it appears often in writing about holidays or local festivals.

예문 1 (formal):

KO: 전시에서는 지역의 음식 전통을 소개합니다.

DE: Die Ausstellung stellt die kulinarischen Traditionen der Region vor.

EN: The exhibition presents the region’s food traditions.

예문 2 (casual):

KO: 우리 집은 생일마다 편지를 쓰는 전통이 있어요.

DE: Bei uns in der Familie ist es Tradition, zu jedem Geburtstag einen Brief zu schreiben.

EN: Our family has a tradition of writing a letter for every birthday.

판정: 미입력

### 두통약 · vocab_b1_0159

뉘앙스:

KO: 두통약은 머리의 통증을 줄이기 위해 쓰는 약을 일상적으로 이르는 말이다.

DE: 두통약 ist die alltägliche Bezeichnung für ein Mittel gegen Kopfschmerzen.

EN: 두통약 is an everyday term for medicine used to relieve a headache.

예문 1 (formal):

KO: 두통약이 필요하신 분은 약국을 이용해 주세요.

DE: Wer Kopfschmerztabletten benötigt, wende sich bitte an die Apotheke.

EN: Anyone who needs headache medicine, please visit the pharmacy.

예문 2 (casual):

KO: 두통약 어디 뒀는지 기억이 안 나요.

DE: Ich weiß nicht mehr, wo ich das Kopfwehmittel hingelegt habe.

EN: I can’t remember where I put the headache medicine.

판정: 미입력

### 외식 · vocab_b1_0187

뉘앙스:

KO: 외식은 집이 아닌 식당에서 돈을 내고 사 먹는 식사를 가리키며, 외식하다처럼 동사로도 쓰고 외식비, 외식 문화 같은 합성어도 많다.

DE: 외식 bedeutet, außerhalb der eigenen Wohnung im Restaurant zu essen und dafür zu bezahlen; man benutzt es auch als Verb 외식하다 und in Komposita wie 외식비 (Restaurantkosten) oder 외식 문화 (Esskultur außer Haus).

EN: 외식 refers to paying to eat a meal at a restaurant rather than at home; it is also used as the verb 외식하다 and appears in compounds like 외식비 (dining-out expenses) or 외식 문화 (dining-out culture).

예문 1 (formal):

KO: 오늘 저녁은 팀원들과 외식을 하기로 했습니다.

DE: Heute Abend gehen wir mit dem Team auswärts essen.

EN: This evening we've decided to eat out with the team.

예문 2 (casual):

KO: 이번 주에는 벌써 세 번이나 외식했어요.

DE: Diese Woche war ich schon dreimal auswärts essen.

EN: This week I've already eaten out three times.

판정: 미입력

### 부동산 · vocab_b1_0257

뉘앙스:

KO: 부동산은 원래 주택이나 토지 같은 재산 자체를 뜻하지만, 일상에서는 그런 재산의 매매·임대를 중개하는 사무실인 '부동산 중개소'의 줄임말로 더 많이 쓰인다.

DE: 부동산 bedeutet ursprünglich das Eigentum selbst, etwa ein Haus oder ein Grundstück, wird aber im Alltag meist als Kurzform von '부동산 중개소' für das Maklerbüro verwendet, das Kauf, Verkauf oder Vermietung solcher Immobilien vermittelt.

EN: 부동산 originally means the property itself, such as a house or a plot of land, but in everyday use it more often functions as a short form of '부동산 중개소,' the brokerage office that handles buying, selling, or renting such property.

예문 1 (formal):

KO: 자세한 매물 정보는 부동산에 문의해 주십시오.

DE: Nähere Informationen zum Angebot erhalten Sie beim Immobilienbüro.

EN: Please inquire with the real estate agency for detailed listing information.

예문 2 (casual):

KO: 이번 주말에 부동산 몇 군데를 더 둘러볼 거예요.

DE: Dieses Wochenende schaue ich mir noch ein paar weitere Immobilienbüros an.

EN: This weekend I'm going to check out a few more real estate agencies.

판정: 미입력

### 사고 접수 · vocab_b1_0392

뉘앙스:

KO: 사고 접수는 사고 내용을 담당 기관이나 업체에 알리거나 그곳에서 받아 기록하는 일을 가리킨다.

DE: 사고 접수 bezeichnet die Meldung eines Unfalls bei der zuständigen Stelle oder deren Erfassung dieser Meldung.

EN: 사고 접수 means reporting an accident to the responsible organization or that organization receiving and recording the report.

예문 1 (formal):

KO: 사고 접수는 앱을 통해 바로 하실 수 있습니다.

DE: Sie können den Unfall direkt über die App melden.

EN: You can submit an accident report directly through the app.

예문 2 (casual):

KO: 사고 접수를 하려니 서류가 몇 개 더 필요했어요.

DE: Um den Unfall zu melden, brauchte ich noch ein paar weitere Unterlagen.

EN: To submit the accident report, I needed a few more documents.

판정: 미입력

### 면접 일정 · vocab_b1_0471

뉘앙스:

KO: 이 표현은 취업 면접을 보기로 잡아 둔 특정 날짜와 시각을 뜻하며, 잡다·조율하다·변경하다와 자주 어울려 쓰인다.

DE: Dieser Ausdruck bezeichnet das konkrete Datum und die Uhrzeit, die für ein Vorstellungsgespräch festgelegt wurden; er wird oft mit 잡다 (festlegen), 조율하다 (abstimmen) oder 변경하다 (ändern) kombiniert.

EN: This expression refers to the specific date and time set for a job interview; it is often combined with 잡다 (to set), 조율하다 (to coordinate), or 변경하다 (to change).

예문 1 (written):

KO: 면접 일정은 다음 주 화요일 오후로 안내드립니다.

DE: Der Vorstellungstermin ist nächsten Dienstagnachmittag.

EN: We would like to inform you that the interview is scheduled for next Tuesday afternoon.

예문 2 (casual):

KO: 면접 일정 문자를 받고 좀 긴장됐어요.

DE: Als ich die SMS zum Vorstellungstermin bekam, wurde ich etwas nervös.

EN: I got a bit nervous after receiving the text about the interview schedule.

판정: 미입력
