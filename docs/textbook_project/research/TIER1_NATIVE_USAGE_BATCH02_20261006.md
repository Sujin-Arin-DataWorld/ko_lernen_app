# Tier 1 Native-Usage Research — Batch 02

Date: 2026-10-06

Scope:
- shopping_consumption
- transport_wayfinding
- health_body
- work_career

This batch explicitly adds **multi-genre sampling**. The goal is not only "how native speakers say X", but "how native speakers say X in a service interaction, personal blog, review, community post, or institutional/news context."

## 1. Shopping / returns

### Korean
Naver blog experience writing repeatedly combines:
1. what went wrong;
2. what the user did;
3. what customer service said;
4. what ultimately happened;
5. personal evaluation.

The most reusable learner language is operational:
- 환불하고 싶어요.
- 교환하고 싶어요.
- 사이즈가 안 맞아요.
- 다른 사이즈로 바꿀 수 있을까요?
- 주문한 것과 다른 상품이 왔어요.
- 환불금이 아직 안 들어왔어요.

### English
The important distinction is **return vs exchange vs refund**.
- return = sending/giving the item back;
- exchange = replacing it;
- refund = money coming back.

Natural service frames:
- I'd like to return this.
- Can I exchange this for a different size?
- I still haven't received my refund.
- Could you send me a return label?

### German
The equivalent domain is even more lexically differentiated:
- Rückgabe / zurückgeben
- Retoure / retournieren
- Umtausch / umtauschen
- Rückerstattung
- Rücksendeetikett

A1/A2 should not teach all legal/retail terminology at once. Production should begin with:
- Ich möchte das zurückgeben.
- Kann ich das umtauschen?
- Das passt nicht.

Review-site vocabulary becomes recognition material later.

---

## 2. Transport / wayfinding

### Korean
Naver Map and transport blogs separate **app/UI vocabulary** from actual speech.

UI:
- 길찾기
- 안내 시작
- 승하차 알림
- 환승 정보

Human speech:
- 몇 호선 타야 해요?
- 어디서 갈아타요?
- 몇 번 출구로 나가요?
- 이 버스 ○○ 가요?
- 여기서 내려요.

This distinction belongs directly in the textbook.

### English
Urban transit communities prefer short imperative route chains:
- Take the 7 to Times Square.
- Transfer to the 1.
- Get off at the next stop.
- Follow the signs.

Question frames:
- Which line should I take?
- Where do I transfer?
- Is this the right platform?
- Which exit should I use?

Locale-specific terms such as **uptown/downtown** should be culture/location notes, not universal English.

### German
Everyday transit language is built around:
- nehmen
- umsteigen
- aussteigen
- weiterfahren
- Anschluss
- Bahnsteig / Gleis

But `Anschluss` should not be used as a universal dictionary translation of 환승. It often highlights a connecting service rather than the generic act of changing lines.

---

## 3. Health / symptoms

This topic uses a strict two-source model:

**community / blog**
→ natural symptom wording

**authoritative health source**
→ medically reliable terminology and boundaries

Community language is never used as treatment authority.

### Korean
Everyday:
- 목이 아파요.
- 목이 간질거려요.
- 기침이 나요.
- 코가 막혀요.
- 감기 걸린 것 같아요.
- 며칠째 계속 그래요.

Authoritative terminology from KDCA:
- 콧물
- 코막힘
- 인후통
- 기침
- 발열

Teaching insight:
`인후통` belongs to medical/informational recognition earlier than casual productive speech. A beginner patient is more likely to need `목이 아파요`.

### English
Everyday/clinical bridge:
- I have a sore throat.
- I've got a cough.
- My nose is blocked.
- I have a runny nose.
- I don't have a fever.
- It's been going on for a week.

NHS terminology aligns well with these everyday symptom labels, which makes this domain pedagogically convenient.

### German
Everyday:
- Ich habe Halsschmerzen.
- Ich habe Husten.
- Meine Nase ist zu.
- Ich fühle mich schlapp.
- Mich hat's erwischt.

Authoritative:
- Halsschmerzen
- Husten
- Schnupfen
- Fieber
- laufende/verstopfte Nase

Important distinction:
`grippaler Infekt` is valid institutional/medical language but should not replace ordinary `Erkältung` in casual learner dialogue.

---

## 4. Work / career

### Korean
Interview-review blogs use a recurring discourse order:
1. process stage;
2. what was asked;
3. what I emphasized;
4. atmosphere;
5. what I think helped/hurt;
6. result.

Useful patterns:
- 자기소개를 짧게 준비했어요.
- 지원동기 중심으로 물어봤어요.
- 제가 맡은 업무는 ...
- 실제 경험을 예로 들었어요.
- 이직 이유를 설명했어요.
- 면접 분위기는 생각보다 편했어요.

News/workplace lanes are more institutional:
- 업무 지적
- 직장 내 괴롭힘
- 근무 시작 전 연락
- 육아휴직
- 근무 조건

These must not leak into A1 self-introduction.

### English
Interview English organizes identity around **role + evidence**:
- I'm currently working as ...
- In my current role, I ...
- One example would be ...
- The main challenge was ...

Workplace repair/feedback:
- Could you clarify what you mean?
- I'd appreciate some feedback.
- Could you give me a specific example?
- Let's prioritize this first.

### German
Professional self-presentation:
- Ich arbeite derzeit als ...
- In meiner aktuellen Position ...
- Ich war verantwortlich für ...
- Ein konkretes Beispiel wäre ...

Application/review vocabulary:
- Bewerbung
- Vorstellungsgespräch
- Erstgespräch
- Kennenlernen
- Absage
- Rückmeldung

These are not interchangeable. Book localization should track hiring stage.

---

# Cross-genre discovery

The project now treats **genre as instructional metadata**.

A learner should eventually understand that:

> "환불이 아직 안 됐어요."

can become:

- polite service request;
- personal blog narrative;
- angry review;
- consumer-news issue;

without assuming all four use the same grammar, tone or information structure.

This is also the bridge to future Korean-speaker EN/DE books.

# Broad-pass status

All 4 topics × 3 languages satisfy:
- 3+ source contexts;
- 8+ normalized patterns;
- 2+ register lanes;
- translationese warning;
- speech/display note.

Health additionally has an authoritative terminology source in KO/EN/DE.

Machine-readable:
`TIER1_NATIVE_USAGE_BATCH02_20261006.json`

Validator:
`tools/textbook_project/validate_tier1_native_usage_batch02.py`

Genre map:
`SOURCE_GENRE_DISCOURSE_MAP_KO_EN_DE_20261006.md`

# Next research batch

For **1A publishing readiness**, prioritize:
- personal_identification
- communication_phone_digital
- language_learning_communication_repair
- social_etiquette_customs

These four, combined with Batches 01–02, cover almost all of the communicative spine needed for 1A.
