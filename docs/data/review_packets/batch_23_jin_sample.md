# Batch 23 (PR-L3a) — Jin 10% 표본 패킷

> 생성 2026-09-08 · 대상: A1 보강 Batch 23의 교체·신규·이동 15건 전부(Fable 전수 직독 완료).
> F8 D-4 절차: 새 문안 12건 중 **표본** 2건(무작위, seed 23)을 우선 보고 ok/반려를 적는다. 이동 3건은 문안이 바뀌지 않았다(레벨·팩만 이동).
> 나머지는 참고용 전체 목록. 반려 항목은 해당 ID만 재작업 → Fable 재검사 → 표본 재발췌.

판정 3항목(F8): ① 한국인이 봐도 자연스러운가 ② DE·EN이 같은 사건인가(정답 누설 없음) ③ 레벨 안인가(A1 = 국제통용 1급 어휘·문법, 문화어 1개 예외).

| 표본 | 구분 | ID | 표제어 | 팩 | KO | DE | EN | Jin 판정 |
|---|---|---|---|---|---|---|---|---|
|  | 교체(동일 ID, 새 문안) | `vocab_a1_0395` | 양해 → 잘못 | `a1_sorry_thanks_1` | 죄송해요, 제 잘못이에요. | Entschuldigung, das war mein Fehler. | Sorry, that was my mistake. |  |
| **표본** | 교체(동일 ID, 새 문안) | `vocab_a1_0310` | 등기 → 편지 | `a1_post_office_1` | 이 편지를 독일로 보내 주세요. | Bitte schicken Sie diesen Brief nach Deutschland. | Please send this letter to Germany. |  |
|  | 교체(동일 ID, 새 문안) | `vocab_a1_0317` | 도착 문자 → 며칠 | `a1_post_office_1` | 독일까지 며칠 걸려요? | Wie viele Tage dauert es bis Deutschland? | How many days does it take to Germany? |  |
|  | 교체(동일 ID, 새 문안) | `vocab_a1_0318` | 포장지 → 값 | `a1_post_office_1` | 우표 값이 얼마예요? | Was kostet die Briefmarke? | How much is the stamp? |  |
| **표본** | 신규(새 문안) | `vocab_a1_0428` | 한국 | `a1_particles_in_use_1` | 한국은 지금 가을이에요. | In Korea ist jetzt Herbst. | It's autumn in Korea now. |  |
|  | 신규(새 문안) | `vocab_a1_0429` | 독일 | `a1_particles_in_use_1` | 독일에서 한국까지 비행기로 열 시간 걸려요. | Von Deutschland nach Korea dauert es zehn Stunden mit dem Flugzeug. | From Germany to Korea it takes ten hours by plane. |  |
|  | 신규(새 문안) | `vocab_a1_0430` | 사람 | `a1_particles_in_use_1` | 한국 사람이 정말 친절해요. | Die Menschen in Korea sind wirklich freundlich. | People in Korea are really friendly. |  |
|  | 신규(새 문안) | `vocab_a1_0431` | 외국인 | `a1_particles_in_use_1` | 이 학교에는 외국인이 많아요. | An dieser Schule gibt es viele Ausländer. | There are many foreigners at this school. |  |
|  | 신규(새 문안) | `vocab_a1_0432` | 한국어 | `a1_particles_in_use_1` | 한국어는 어렵지만 재미있어요. | Koreanisch ist schwer, aber es macht Spaß. | Korean is hard, but it's fun. |  |
|  | 신규(새 문안) | `vocab_a1_0433` | 독일어 | `a1_particles_in_use_1` | 선생님도 독일어를 하세요? | Sprechen Sie auch Deutsch? | Do you speak German too? |  |
|  | 신규(새 문안) | `vocab_a1_0434` | 영어 | `a1_particles_in_use_1` | 영어는 조금만 해요. | Englisch spreche ich nur ein bisschen. | I only speak a little English. |  |
|  | 신규(새 문안) | `vocab_a1_0435` | 살다 | `a1_particles_in_use_1` | 부모님은 독일에 사세요. | Meine Eltern leben in Deutschland. | My parents live in Germany. |  |
|  | 하향 이동 B1→A1(문안 불변) | `vocab_b1_0190` | 문장 | `a1_repair_language_1` | 이 문장은 조금 어려워요. | Dieser Satz ist etwas schwierig. | This sentence is a bit difficult. |  |
|  | 하향 이동 B1→A1(문안 불변) | `vocab_b1_0188` | 표현 | `a1_repair_language_1` | 이 표현은 자주 써요. | Diesen Ausdruck benutzt man oft. | This expression is used often. |  |
|  | 하향 이동 B1→A1(문안 불변) | `vocab_b1_0196` | 대답하다 | `a1_repair_language_1` | 질문에 대답해 주세요. | Antworten Sie bitte auf die Frage. | Please answer the question. |  |

## 함께 바뀐 파생 항목

- 교체 4건의 cloze(`cloze_a1_0198`·`0205`·`0206`·`0283`)와 satz(`satz_a1_0162`·`0169`·`0170`·`0247`)는 같은 문장·DE/EN으로 갱신, 배분어는 빈칸 뒤 조사(받침) 정합 기준으로 재선정.
- 옛 표제어(등기·양해 등)를 배분어로 쓰던 cloze 12건·satz 3건은 새 표제어로 치환.
- 신규 8건의 cloze(`cloze_a1_0351`~`0358`)·satz(`satz_a1_0339`~`0346`)는 예문 재사용(TTS 키 공유). `tools/content_factory/drafts/c*_batch23_*`·`review/c*_batch23_*.csv` 참고.
- 이동 3건의 satz(`satz_b1_0401`·`0403`·`0407`)는 레벨만 a1로 이동(원장 `relevel_batch_004`).

## TTS

- 새 발화 키 18건(표제어·예문)은 맥에서 `python3 tool/generate_tts.py --missing-from-storage --workers 8` 로 합성·업로드 후 `--verify-storage` missing 0 확인(이 컨테이너에는 GCP 자격 증명 없음).
