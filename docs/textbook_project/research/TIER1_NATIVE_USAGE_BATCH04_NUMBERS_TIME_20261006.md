# Tier 1 Native-Usage Research — Batch 04
# Numbers, time and appointments

Date: 2026-10-06

Scope:
- numbers_time_dates

Purpose:
close the remaining dedicated native-usage evidence gap for **1A Unit 05**.

## Main finding

Time language should not be taught as a number chart.

In actual interaction, time appears as a sequence of social actions:

1. ask when the other person is free;
2. propose a time;
3. accept or correct it;
4. repeat important numbers;
5. notify the other person if delayed;
6. give a status or expected arrival.

## Korean

Stable useful patterns:

- 몇 시에 만나요?
- 몇 시에 만날까?
- 오후 1시 어때요?
- 일곱 시에 만나요.
- 여섯 시 아니에요?
- 아니요, 일곱 시예요.
- 10분 정도 늦을 것 같아요.
- 지금 가고 있어요.
- 곧 도착해요.
- 도착하면 바로 연락할게요.

### Genre shift

Neutral/polite meeting:
- 몇 시에 만나요?
- 일곱 시에 만나요.

Friends/chat:
- 몇 시에 만날까?
- 2시 어때?

Delay message:
- 10분 정도 늦을 것 같아요.
- 지금 가고 있어요.
- 도착하면 연락할게요.

A current Korean advice source explicitly recommends communicating the fact of the delay, approximate delay time and apology rather than only writing an ambiguous “좀 늦을 듯.”

## English

Recurring scheduling functions:

- What time works for you?
- What time works best for you?
- What time should we meet?
- How about 2 pm?
- Does 7 work for you?
- Does tomorrow still work for you?
- Friday works for me.
- I can do after 3.
- I'm running about ten minutes late.
- I'm on my way.
- I'll be there soon.

### Important localization point

Korean:
**몇 시에 만나요?**

can map to different English functions:
- What time should we meet?
- What time are we meeting?
- What time works for you?

depending on whether the time is being chosen or confirmed.

Likewise:
**괜찮아요 / 좋아요**

often becomes:
- That works for me.
- Sounds good.

rather than literal *is good / is okay*.

## German

Recurring patterns:

- Wann passt es dir?
- Um wie viel Uhr kannst du?
- Um 14:30 Uhr ginge es.
- Passt dir 19 Uhr?
- Freitag passt mir.
- Treffen wir uns um sieben?
- Ich komme etwa zehn Minuten später.
- Ich verspäte mich ein paar Minuten.
- Ich gebe Bescheid, wenn es knapp wird.
- Ich bin gleich da.

### Important localization point

Korean:
**시간 괜찮아요?**

often maps naturally to:
- Passt dir die Uhrzeit?
- Passt es dir?

not a mechanical:
- Ist die Zeit okay?

Also:
- 약속
- appointment
- Termin
- Treffen
- Verabredung

do not cover identical semantic territory.

## Punctuality warning

German Reddit discussions contain strong opinions about punctuality.

Those discussions are useful evidence for:
- pünktlich
- zu spät
- Bescheid geben
- 5–10 Minuten
- bin gleich da

They are **not** evidence for a universal statement such as:

> Germans always arrive five minutes early.

The textbook must describe contextual language and choices rather than national stereotypes.

## 1A pedagogical decision

Unit 05 should teach:

### Productive core
- 몇 시에 만나요?
- 일곱 시에 만나요.
- 여섯 시 아니에요?
- 아니요, 일곱 시예요.

### High-value later/formulaic recycling
- 10분 정도 늦을 것 같아요.
- 지금 가고 있어요.
- 도착하면 연락할게요.

The delay-message sequence naturally recycles again in Unit 07 messaging.

## Cross-language concept graph

Do not store:

> 괜찮다 = work = passen

Store the scheduling function:

**accept/propose/check time**
- KO: 괜찮아요? / 좋아요 / 어때요?
- EN: work / sound good / how about
- DE: passen / gehen / wie wäre es

This makes the same data reusable later for:
- Korean for EN speakers
- Korean for DE speakers
- English for Korean speakers
- German for Korean speakers

Machine-readable evidence:
`TIER1_NATIVE_USAGE_BATCH04_NUMBERS_TIME_20261006.json`

Validator:
`tools/textbook_project/validate_tier1_native_usage_batch04.py`
