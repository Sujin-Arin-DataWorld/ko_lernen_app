# EN/DE 이미지 문구 검토 · 2026-10-31

사용자의 최신 제작 지시에 따라 PLAN의 S01~S12·A01~A08 **20상태**를 그대로 사용했다. PLAN 머리말의 과거 ‘사용자 미확정’ 표기는 최신 승인 메시지로 갱신된 상태로 판단했으며 PLAN 파일은 수정하지 않았다.

`COPY.json`의 최상위는 20개 객체 배열이다. 모든 상태는 지정된 `id`, `title`, `speaker`, `dialogue`, `primary`, `secondary`, `note`만 갖는다. `speaker`는 고정 이름 문자열이고 A05만 빈 문자열인 시스템 모달이다. `note`의 빈 문자열은 해당 보조 문구를 표시하지 않는다는 뜻이다. 사용자 화면에는 상태 ID·원문 대사 ID를 표시하지 않는다.

## 문구 원칙과 렌더 시 주의

- **Mira는 예시 이름**이다. S01/A01의 sample/Beispielname 문구를 남겨 실제 입력 기능이 있는 화면으로 오인시키지 않는다. 이름 필드에 보여 줄 값도 `Mira`다. 정지 이미지에는 실제 포커스·입력·저장·재생 기능이 없다.
- 기존 첫 단원 DE 대사의 `du`를 유지했다. 관련 작업 루트에서 `.claude/brand-brief.md`·`brand-brief.md`는 발견되지 않았다. 새로운 formal `Sie` 호칭을 만들지 않았다. Sujin/TalSunbi는 Mira를 부르고 초반 Dokkaebi는 Mira를 친밀하게 부르지 않는다.
- UI는 EN/DE이며 JSON 안 한국어는 학습 글자 **ㅇ·ㅏ·아**뿐이다. ㅓ·ㅗ 보기, 발음 점수, 단원 완료, 엽전·진도 지표는 없다. 모든 조립 화면의 완성 모형은 도움 연습에 맞게 유지한다.
- S06의 액션은 실제 입력 구현을 뜻하지 않는다. 놓인 ㅇ과 다음 ㅏ 위치가 그림에서 구별되어야 한다. A03은 모음이 왼쪽에 놓인 U1-F02 대표 상태이며 조각·원래 응답을 지우지 않는다.
- S08의 ‘직접 읽기’는 발화 감지·정답 판정과 연결하지 않는다. 두 경로와 조용히 읽는 경로 모두 S09의 **극중 Mira 낭독**을 거쳐 같은 각성으로 이어진다. S09의 ‘A line from your character / Eine Zeile deiner Figur’는 이 구분을 위한 짧은 문구다. 마이크·녹음 파형·점수 도형을 붙이지 않는다.
- **A04의 secondary는 비활성 표시**다. 본문은 음성을 쓸 수 없는 이유, primary는 자막 경로를 제시한다. 비활성 버튼을 정상 듣기 버튼처럼 꾸미지 않는다.
- A05/A06의 보존·복귀 문구는 승인된 설계 계약이다. 실제 저장·재개를 검증한 결과가 아니다. A06은 ㅇ이 놓이고 ㅏ가 아직 남은 S06의 도움 모형 상태를 전제로 한다.
- A07은 S12까지 재회 대화를 읽은 후 열어 본 기록 화면의 대표 이미지다. 아직 U1-D10을 읽지 않은 시점에서 이를 미리 노출하는 설계가 아니다. 다시보기는 원래 사실만 재생하며 새 단서·반복 각성·보상을 생성하지 않는다.
- S10의 ‘Skip animation’은 움직임만 건너뛰며 첫 대사·재회 대화 순서를 건너뛰지 않는다. A08은 S10과 같은 첫 발화를 정지 장면으로 전달한다.
- title은 작은 장면 표제다. 본문 대사를 압도하지 않는다. 본문은 의미 단위로 2~3줄 조판하고 독일어를 가로 축소하지 않는다. 대사 글자 수와 실제 폰트 줄 수는 다르므로 최종 줄바꿈은 이미지에서 별도 검토한다.

## 이미지 사이에 이어져야 할 대사

한 장에는 한 화자 차례만 담았다. 나머지 원문 턴이 사라진다는 뜻이 아니다. 특히 S11 대표 이미지에서 놀람만 보고 S12 환영으로 바로 뛰면 외로움을 알아보는 핵심 재회가 빠진다. 다음 순서를 연결 대본으로 유지한다. 아래 문구는 설명용 추가 화면 제목이 아니다.

| 위치/원문 | 화자 | EN | DE |
|---|---|---|---|
| S04 직전 · U1-D02 앞부분 | Dokkaebi | A book with all its letters scattered is no good even for kindling! | Ein Buch, dessen Zeichen überall verstreut sind, taugt nicht einmal zum Anfeuern! |
| S04 | Dokkaebi | I seem to remember a noisy nagging voice coming from this book… | Aus dem Buch kam doch früher die Stimme eines lauten Nörglers … |
| S04→S05 · U1-D03 축약 | Sujin | Wait, Mira. I think the letters will return if we put the pieces back. Shall we place ㅏ beside ㅇ? | Warte, Mira. Wenn wir die Teile einsetzen, werden die Zeichen vielleicht wieder lebendig. Legen wir ㅏ neben ㅇ? |
| S05 시작 · U1-D04 | Sujin | I'll try first. Let's listen to the sound too. | Ich mache es zuerst. Hören wir uns auch den Laut an. |
| S05→S09 | Sujin→Mira | T01 example → P01 supported practice → …아! | T01 Beispiel → P01 Übung mit Vorlage → …아! |
| S10 · U1-D06 | TalSunbi | Ha ha! At last, a new learner who understands how the letters work and can read the first sound! | Haha! Endlich ist jemand da, der versteht, wie die Zeichen funktionieren, und den ersten Laut lesen kann! |
| S11 첫 턴 · U1-D07 | Dokkaebi | …TalSunbi? | …TalSunbi? |
| S11 다음 · U1-D08 | TalSunbi | Ha ha, have you still not studied your letters while I've been asleep? | Haha, hast du dich auch während meines Schlafs noch immer nicht mit den Schriftzeichen beschäftigt? |
| S11 다음 · U1-D09 | Dokkaebi | You rascal! You wake up after hundreds of years, and that's the first thing you say! | Du alter Schlingel! Du wachst nach Hunderten von Jahren auf, und das ist das Erste, was du sagst! |
| S11 다음 · U1-D10 | TalSunbi | …The house has grown so old. Were you… here alone the whole time I was asleep? …You must have been very lonely. | …Das Haus ist sehr verfallen. Warst du … die ganze Zeit hier allein, während ich geschlafen habe? …Du musst sehr einsam gewesen sein. |
| S11 다음 · U1-D11 앞부분 | Dokkaebi | Q-quiet! Where would a house-guarding Dokkaebi go, leaving this house behind? | S-sei still! Wo sollte ein Dokkaebi, der dieses Haus bewacht, denn hingehen und es zurücklassen? |
| S11 다음 · U1-D11 뒷부분 축약 | Dokkaebi | Now that you're back, get to work! Teach this new learner so my house can be repaired! | Jetzt bist du wieder da! Bring der neuen Person hier die Schrift bei, damit mein Haus repariert werden kann! |
| S12 · U1-D12 | TalSunbi | Ha ha, sound comes first; letters are the clothes it wears. Now, Mira, let's begin with the first character and take it step by step. | Haha, zuerst kommt der Laut; die Schrift ist sein Gewand. Nun, Mira, sehen wir uns das erste Zeichen Schritt für Schritt an. |

첫 발화와 감정 순서는 **첫 소리→탈선비 귀환→도깨비의 놀람→익숙한 농담→도깨비의 격한 반응→홀로 남았던 외로움을 알아봄→투덜거리며 새 제자 부탁→Mira에게 다음 배움 안내**다. S04 본문·U1-D03·U1-D11 뒷부분은 짧은 이미지 호흡을 위한 의미 보존 축약이며 신규 사실을 넣지 않았다. 그 밖의 주요 재회 대사는 최신 첫 단원의 EN/DE를 유지했다. TalSunbi의 원문 환영은 극중 반응이며 독립 읽기 숙달 인증 문구가 아니다.

## 확인 범위

JSON 정적 검사 결과: 상태 20개와 필드·언어 키 일치, EN/DE 대사 40개 모두 140자 이내, 가장 긴 대사 S12 EN 133자, formal `Sie/Ihnen/Ihr` 호칭 0건, 한국어 문자 종류는 ㅇ·ㅏ·아만 확인했다. 가장 긴 버튼은 A08 DE 26자이므로 작은 화면에서는 두 줄 조판을 허용한다. 이는 실제 폰트의 줄바꿈·터치 영역 검증과 별개다.

`lokalisieren-de`와 CTA reference를 읽고 영문 어순을 그대로 복제하지 않는 짧은 독일어 CTA를 작성했다. `du-sie-check`와 reference에 따라 본문·지시·버튼·소유사를 `du`로 통일했다. 일반 채팅의 ‘Continue / Weiter’는 모호한 구매 CTA가 아니라 현재 대사의 다음 차례를 여는 명확한 동작이므로 유지했다.

근거는 승인된 [PLAN.md](C:/dev/hangulsori/_codex_artifacts/season1-rpg-image-plan-20261031/PLAN.md)와 현재 읽은 [01_FIRST_SOUND.md](C:/dev/hangulsori/ko_lernen_app_worktrees/season1-content-docs-20261030/docs/learning/ildu-season1-content-20261030/manuscripts/foundation-1-v35/01_FIRST_SOUND.md)다. 작성물은 이 두 문구 파일뿐이다. 이미지·앱 코드·HTML·Figma를 만들거나 변경하지 않았다.
