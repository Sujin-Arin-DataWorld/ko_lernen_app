---
name: beyond-humanizer
description: Use when translating, interpreting, editing, or reviewing Hangul Sori Korean, English, or German learner content where naturalness, discourse, social relations, culture, and learning accuracy must survive across languages.
---

# Beyond Humanizer

단어 모양이 아니라 **같은 의사소통 사건**을 세 언어에서 재구성한다. 정확성·화용·관계·문화·학습 목표를 보존한 뒤 자연스럽게 만든다. 유창한 오역은 실패다.

## 참고자료

작업 전에 해당 문서를 끝까지 읽는다.

- 항상: [language-lenses.md](references/language-lenses.md), [evidentiality-modal-force-presupposition.md](references/evidentiality-modal-force-presupposition.md)
- 방향·생략·직시·시상: [directionality-and-underspecification.md](references/directionality-and-underspecification.md)
- 통역: [interpreting-mode.md](references/interpreting-mode.md)
- 문화·CEFR·문항: [culture-pedagogy.md](references/culture-pedagogy.md)
- 데이터: [data-contracts.md](references/data-contracts.md)
- QA·근거: [examples-rubric.md](references/examples-rubric.md), [evidence-and-corpus.md](references/evidence-and-corpus.md), [research-basis.md](references/research-basis.md)

## 보존 계약

먼저 잠근다.

- 사실·시간·극성·인과·행위자·대상·지시대상
- 화행·양태 강도·정보 출처·화자 확신·전제·척도 대안
- 감정·친밀도·위계·높임·직시·관점·시제/상
- 문화·학습 목표·용어·ID·key·placeholder·schema

없는 정보는 `unknown`이다. 사람·성별·관계·직책·절차·원인·감정·평가를 만들지 않는다.

## 절차

1. 파일이면 Unicode, key/ID, placeholder, schema와 원문 권위 `canonical | editable | generated | unknown`을 확인한다.
2. Brief를 적는다.

```text
mode; source→target/locale; L1/CEFR; scene/channel/purpose
speaker/addressee/relationship; speech act/register/emotion
referents/deixis/time/aspect; evidence/source-chain/commitment
modal force; presupposition/scalar alternatives; terms/schema/authority
```

3. 목표어가 요구하지만 원문이 특정하지 않은 값을 `SOURCE-SPECIFIED | TARGET-REQUIRED | CONTEXT-SUPPORTED | UNRESOLVED`로 분리한다. unresolved는 중립 표현·조건별 안·`FLAG`로 닫는다.
4. PIVOT을 만든다.

```text
PROPOSITION | SPEECH_ACT | STANCE_AFFECT | RELATIONSHIP
EVIDENTIALITY | MODAL_FORCE | PRESUPPOSITION
INFORMATION | CULTURE | PEDAGOGY | FORBIDDEN
```

5. 한국어 원문과 학습 목표를 판정한 뒤 EN·DE를 같은 PIVOT에서 **독립** 재구성한다. 한 목표어를 중간 정본으로 쓰지 않는다.
6. 문화는 `PRESERVE | FUNCTIONAL_EQUIVALENT | MINIMAL_EXPLICITATION | CULTURE_NOTE | FLAG` 중 고르고, 이 장면의 기능과 변이 범위만 설명한다.
7. CEFR는 수행 기능으로 판정한다. Cloze는 정답 하나, 오답은 형태상 가능하지만 문맥상 틀려야 한다.
8. 원문 대조 정확성 감사와 target-only 자연성 감사를 분리한다. 세 언어면 쌍별 삼각 감사도 한다.

## 감사와 추론 한도

오류 코드는 `ACC | PRAG | REL | REF | INDEX | DEIX | TAM | EVID | FORCE | PRESUP | CULT | NAT | TERM | CEFR | ITEM | INT | DATA`다.

- `GREEN`: 목표어 문법에 필요하며 의미를 특정하지 않음.
- `YELLOW`: 문맥이 허가한 최소 명시화. 삼각 감사 필수.
- `RED`: 새 지시대상·관계·출처·확신·의무·허가·전제·평가. 금지.

형식 지정이 없으면 `판정 → 최종안 하나 → 오류 코드 이유 최대 4개 → 문화·불확실성 메모 → 검증` 순서다. 데이터 요청은 원래 schema만 반환한다.

critical `ACC/REL/REF/INDEX/DEIX/TAM/EVID/FORCE/PRESUP/CULT/ITEM/INT/DATA`가 0이고 세 언어가 같은 장면을 말할 때 통과다. 원어민·한국어교육·통역 전문가 판단은 인간 검수 gate다.
