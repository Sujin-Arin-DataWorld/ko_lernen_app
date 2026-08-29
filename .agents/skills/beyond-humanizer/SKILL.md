---
name: beyond-humanizer
description: Use when authoring, localizing, translating, interpreting, editing, or auditing Hangul Sori Korean, English, or German learner content where modern naturalness, discourse, social relations, culture, and learning accuracy must survive across languages.
---

# Beyond Humanizer

단어 모양이 아니라 **같은 의사소통 사건**을 세 언어에서 재구성한다. 정확성·화용·관계·문화·학습 목표를 보존한 뒤 자연스럽게 만든다. 유창한 오역과 장면 없는 교과서 문장은 모두 실패다.

## 모드와 참고자료

작업 전에 해당 문서를 끝까지 읽는다.

- 항상: [language-lenses.md](references/language-lenses.md), [evidentiality-modal-force-presupposition.md](references/evidentiality-modal-force-presupposition.md)
- `AUTHOR | AUDIT | AUTHOR+AUDIT`: [scene-authoring-and-modern-korean.md](references/scene-authoring-and-modern-korean.md), [answer-variants-and-triad-audit.md](references/answer-variants-and-triad-audit.md)
- 방향·생략·직시·시상: [directionality-and-underspecification.md](references/directionality-and-underspecification.md)
- 통역: [interpreting-mode.md](references/interpreting-mode.md)
- 문화·CEFR·문항: [culture-pedagogy.md](references/culture-pedagogy.md)
- 데이터: [data-contracts.md](references/data-contracts.md)
- QA·근거: [examples-rubric.md](references/examples-rubric.md), [evidence-and-corpus.md](references/evidence-and-corpus.md), [research-basis.md](references/research-basis.md)

모드를 잠근다.

- `AUTHOR`: Scene Brief에서 KO 정본과 과제별 허용 변형을 만들고 EN·DE를 독립 현지화한다.
- `AUDIT`: 기존 KO·EN·DE와 변형을 장면·과제 계약에 대조한다.
- `AUTHOR+AUDIT`: 작성 뒤 같은 계약으로 삼언어 감사를 수행한다.
- 번역·통역·편집은 기존 v3 절차를 유지한다.

## 보존 계약

먼저 잠근다.

- 사실·시간·극성·인과·행위자·대상·지시대상
- 화행·양태 강도·정보 출처·화자 확신·전제·척도 대안
- 감정·친밀도·위계·높임·직시·관점·시제/상
- 문화·학습 목표·용어·ID·key·placeholder·schema

없는 정보는 `unknown`이다. 사람·성별·관계·직책·절차·원인·감정·평가를 만들지 않는다.

## 절차

1. 파일이면 Unicode, key/ID, placeholder, schema와 원문 권위 `canonical | editable | generated | unknown`을 확인한다.
2. Scene Brief를 잠근다.

```text
mode; source→target/locale; L1/CEFR; scene/channel/purpose
speaker/addressee/relationship; power/familiarity/speech-style/emotion
pedagogical target/task type; referents/deixis/time/aspect
evidence/source-chain/commitment; modal force; presupposition
terms/schema/authority
```

3. 관계·채널처럼 말투를 바꾸는 값이 없으면 `SOURCE-SPECIFIED | TARGET-REQUIRED | CONTEXT-SUPPORTED | UNRESOLVED`로 분리하고 조건별 안이나 `FLAG`로 닫는다.
4. PIVOT을 만든다.

```text
PROPOSITION | SPEECH_ACT | STANCE_AFFECT | RELATIONSHIP
EVIDENTIALITY | MODAL_FORCE | PRESUPPOSITION
INFORMATION | CULTURE | PEDAGOGY | FORBIDDEN
```

5. AUTHOR 계열은 장면의 상대 발화와 응답 목적에서 자연스러운 KO 정본을 먼저 만든다. 과제에 맞춰 `semantic | construct_preserving | surface` 변형을 분리한다.
6. EN과 `de-DE`를 같은 PIVOT에서 **각각 직접** 재구성한다. 한 목표어를 다른 목표어의 중간 정본으로 쓰지 않는다.
7. 문화는 `PRESERVE | FUNCTIONAL_EQUIVALENT | MINIMAL_EXPLICITATION | CULTURE_NOTE | FLAG` 중 고른다. 현판·고사어는 실제 대사에 억지로 넣지 않는다.
8. 원문 대조 정확성, target-only 자연성, 과제별 변형, 세 언어 쌍별 삼각 감사를 분리한다.
9. 최신성 주장은 위험 기반 근거 gate를 거친다. 근거가 필요하지만 확인되지 않으면 통과가 아니라 `EVIDENCE_REQUIRED`다.

## 감사와 출력

오류 코드는 `ACC | PRAG | REL | REF | INDEX | DEIX | TAM | EVID | FORCE | PRESUP | CULT | NAT | TERM | CEFR | ITEM | INT | DATA`다.

- `GREEN`: 목표어 문법에 필요하며 의미를 특정하지 않음
- `YELLOW`: 문맥이 허가한 최소 명시화; 삼각 감사 필수
- `RED`: 새 지시대상·관계·출처·확신·의무·허가·전제·평가; 금지

채팅 AUTHOR 계열의 기본 출력은 `Scene Lock → KO 정본·변형 → EN → DE → 삼언어 감사 → 근거·검수 상태`다. 데이터 요청은 원래 schema만 반환하고 감사 결과를 sidecar로 분리한다.

critical `ACC/REL/REF/INDEX/DEIX/TAM/EVID/FORCE/PRESUP/CULT/ITEM/INT/DATA`가 0이고 세 언어가 같은 장면과 과제를 말할 때만 `MODEL_QA_PASS`다. 그 밖에는 `FLAG` 또는 `EVIDENCE_REQUIRED`다. 모델은 `HUMAN_APPROVED`, 원어민 승인, 교육자 승인 상태를 만들지 않는다.
