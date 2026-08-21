---
name: beyond-humanizer
description: Use when translating, interpreting, editing, or reviewing Hangul Sori Korean, English, or German learner content where native naturalness, discourse context, social relations, culture, and learning accuracy must survive across languages.
---

# Beyond Humanizer

세 언어에 단어 모양을 복제하지 말고 **같은 의사소통 사건**을 재구성한다. 정확성·화용·관계·문화·학습 목표를 보존한 뒤 자연스럽게 만든다. 유창한 오역은 실패다.

## 참고자료

작업 전에 해당 문서를 끝까지 읽는다.

- 모든 다국어 작업: [language-lenses.md](references/language-lenses.md)
- 번역 방향·생략·대명사·직시·시제/상 판단: [directionality-and-underspecification.md](references/directionality-and-underspecification.md)
- 순차·동시·대화통역: [interpreting-mode.md](references/interpreting-mode.md)
- 문화, CEFR, Cloze·Satz·시나리오: [culture-pedagogy.md](references/culture-pedagogy.md)
- ARB·JSON·CSV·factory 수정: [data-contracts.md](references/data-contracts.md)
- 후보 비교와 QA: [examples-rubric.md](references/examples-rubric.md)
- 근거·corpus·인간 검수 설계: [evidence-and-corpus.md](references/evidence-and-corpus.md), [research-basis.md](references/research-basis.md)

## 보존 계약

다음을 먼저 잠근다.

- 사실·시간·극성·modality·인과와 행위자·대상·수혜자·지시대상
- 화행, 감정 온도, 친밀도, 위계, 역할, 높임
- 직시 중심, 관점, 시제·상, 수·성별·한정성 중 원문이 실제로 특정한 값
- 문화·용어·학습 목표와 ID·key·placeholder·ICU·schema

정보가 없으면 `unknown`이다. 진단한 unknown을 최종안에서 구체적 하위 범주로 바꾸지 않는다. 사람, 직책, 절차, 감정, 원인, 평가를 만들지 않는다.

## 절차

### 1. 구조와 권위 확인

파일이면 Unicode, 중복 key·ID, placeholder와 schema를 먼저 검사한다. 손상 문자열은 추측하지 않는다. 원문 권위를 `canonical | editable | generated | unknown`으로 표시한다.

### 2. Translation Brief 작성

```text
mode; source→target/locale; L1/CEFR; scene/channel/purpose
speaker/addressee/relationship; speech act/register/emotion
referents; deictic center; temporal reference; continuing/completed
protected terms; learning target; schema; source authority
```

핵심 맥락이 없으면 파일에서는 `FLAG`, 짧은 요청에서는 역할 중립 표현을 쓴다.

### 3. 미명시 정보 분리

목표어가 선택을 요구하는 값을 원문 사실로 착각하지 않는다. `SOURCE-SPECIFIED | TARGET-REQUIRED | CONTEXT-SUPPORTED | UNRESOLVED`로 분리한다. `UNRESOLVED`는 중립 표현, 맥락별 복수안, `FLAG` 중 하나로 처리한다.

### 4. 의미·화용 PIVOT 만들기

```text
PROPOSITION | SPEECH_ACT | STANCE_AFFECT | RELATIONSHIP
INFORMATION | CULTURE | PEDAGOGY | FORBIDDEN
```

### 5. 한국어 판정

`canonical`은 유지, `editable/generated`는 학습 목표를 잠근 뒤 최소 수정, `unknown`은 의미 변화 가능성이 있으면 flag한다. 한국어가 어색한 채로 DE/EN만 세련되게 만들지 않는다.

### 6. EN과 DE를 독립 재구성

한 언어를 거쳐 다른 언어를 만들지 않는다. 같은 PIVOT과 방향별 참조 문서를 쓴다. 번역문은 자연스럽게 두고 문화·문법 설명은 학습 메모로 분리한다.

### 7. 문화 중개 전략 선택

`PRESERVE | FUNCTIONAL_EQUIVALENT | MINIMAL_EXPLICITATION | CULTURE_NOTE | FLAG` 중 하나를 고른다. 집단 일반화 대신 이 장면의 관계와 관습을 설명한다.

### 8. 학습 항목 검증

CEFR는 수행 가능한 의사소통 기능으로 판정한다. Cloze 정답은 하나여야 한다. 오답은 형태상 그럴듯하지만 문맥상 틀려야 한다.

### 9. 독립 감사와 최소 수정

원문 대조 정확성 감사와 목표어만 보는 자연성 감사를 분리한다. 세 언어 작업은 `KO↔DE`, `KO↔EN`, `DE↔EN`도 비교한다. `ACC | PRAG | REL | REF | INDEX | DEIX | TAM | CULT | NAT | TERM | CEFR | ITEM | INT | DATA`로 진단한 범위만 고친다.

## 추론 한도

- `GREEN`: 목표어 문법에 필요하며 의미를 새로 특정하지 않는 형식 선택.
- `YELLOW`: 문맥이 허가한 최소 명시화. 삼각 감사 필수.
- `RED`: 지시대상·성별·관계·직책·절차·원인·감정·평가 창작. 금지.

## 출력과 완료

형식 지정이 없으면 `판정 → 최종안 하나 → 오류 코드가 붙은 이유 최대 4개 → 필요한 문화·불확실성 메모 → 검증 결과` 순서다. 데이터 요청은 원래 schema만 반환한다.

critical `ACC/REL/REF/INDEX/DEIX/TAM/CULT/ITEM/INT/DATA`가 없고, 세 언어가 같은 장면을 말하며, 목표어가 자연스럽고, L1별 오해를 다룰 때 통과다. 원어민·한국어교육·통역 전문가 판단은 인간 검수 gate로 남긴다.
