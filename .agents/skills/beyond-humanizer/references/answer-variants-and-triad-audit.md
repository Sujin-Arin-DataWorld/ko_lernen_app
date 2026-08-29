# 허용 변형과 삼언어 감사

## 1. 과제별 변형 계층

`acceptedVariants`는 “뜻이 비슷해 보이는 문장” 목록이 아니다. 과제가 측정하는 능력에 따라 허용 범위가 달라진다.

### 열린 말하기·작문: `semantic`

다음이 모두 같으면 어휘·구문이 달라도 허용할 수 있다.

- 핵심 명제와 필수 의미 슬롯
- 화행과 상대의 선택권
- 관계·높임·감정 온도
- 증거성·양태 강도·전제
- 문화·학습 목표

사실을 알리기, 문제를 제기하기, 잠시 답을 미루기처럼 같은 관계 행동을 여러 자연스러운 방식으로 인정한다. 새 원인·절차·감정·평가가 생기면 거부한다.

### Cloze: `construct_preserving`

- 목표 문법·어휘·형태 범주와 빈칸 역할을 보존한다.
- 현재 4지선다 UI에는 정본 `answer` 하나만 표시한다.
- 추가 변형은 판정·모호성 감사용 metadata이며 선택지나 distractor가 될 수 없다.
- distractor는 정본과 모든 허용 변형에 대해 문맥상 오답이어야 한다.
- 각 distractor를 빈칸에 실제로 대입해, 장면이 허용하는 모든 합리적 해석에서 오답인지 확인한다. 정본과 화행·양태 범주가 다르다는 사실만으로는 오답이 되지 않는다.
- 문맥 안에서 참이거나 자연스러운 후속 발화가 되는 distractor가 하나라도 있으면 `ITEM` critical로 판정하고 선택지를 고친 뒤에만 통과시킨다.
- 변형 때문에 문장 전체의 의미·화행·CEFR가 달라지면 거부한다.

### 받아쓰기: `surface`

- 들은 한국어의 어휘·형태소 순서를 그대로 보존한다.
- 검수된 띄어쓰기와 문장부호 차이만 추가 변형으로 선언할 수 있다.
- 의미가 같은 의역, 어휘 교체, 더 넓은 시간 표현, 다른 후속 행동은 거부한다.
- 판정은 정본과 선언된 표면형 중 하나와 일치하면 통과하고, 오류 피드백은 가장 가까운 허용형을 기준으로 한다.
- TTS, 정답 공개, 단어 블록은 언제나 정본을 사용한다.

예:

```text
canonical: 지금 바로 답드리기보다는, 내용을 조금 정리해서 다시 말씀드릴게요.
surface candidate: 지금 바로 답드리기 보다는 내용을 조금 정리해서 다시 말씀드릴게요
semantic paraphrase: 조금 생각해 보고 나중에 연락드릴게요.
```

첫 후보는 제품이 명시적으로 검수·등록한 경우에만 받아쓰기 변형이다. 둘째는 열린 말하기에서는 가능해도 받아쓰기에서는 다른 어휘·행동이므로 거부한다.

## 2. 데이터 계약

원래 정본 필드는 유지하고 선택 필드에는 **추가 변형만** 넣는다.

```json
{
  "answer": "정본",
  "acceptedVariants": ["정본을 제외한 추가 허용형"]
}
```

공통 위생:

- 필드가 없으면 기존 동작과 완전히 같아야 한다.
- 값은 trim된 비어 있지 않은 고유 문자열이다.
- 정본을 다시 넣지 않는다.
- Cloze 변형은 distractor와 겹치지 않는다.
- 받아쓰기 변형은 공백과 검수 대상 문장부호를 제거한 뒤 정본과 같은 문자·형태 순서여야 한다.
- 정본만 콘텐츠 ID, SRS key, TTS와 정답 공개의 권위값이다.

기존 생산형 평가의 `ProductiveTextCriterion.acceptedVariants`처럼 consumer가 정본 포함 전체 집합을 요구하면 builder에서 `[canonical, ...additional]`로 투영한다. source의 추가-only 계약을 바꾸지 않는다.

## 3. 삼언어 감사

KO·EN·DE를 같은 PIVOT에 대조하되 영어를 중간 정본으로 삼지 않는다.

각 언어별로 먼저 검사한다.

```text
SCENE       같은 사람·장소·시간·채널인가
ACT         같은 질문·부탁·제안·거절·약속인가
RELATION    거리·권력·호칭·말끝 효과가 맞는가
CONTENT     사실·인과·극성·지시대상이 같은가
STANCE      감정·확신·증거 출처·양태 강도가 같은가
BACKGROUND  전제·척도·이전 계획을 더하거나 잃지 않았는가
PEDAGOGY    같은 수행 기능과 target을 가르치는가
```

그다음 `KO↔EN`, `KO↔DE`, `EN↔DE`를 쌍별 비교한다. 문장 수나 어순 차이는 오류가 아니다. 한 언어만 더 직접적이거나 더 공적이거나 새 절차를 명시하면 오류다.

독일어 `du/Sie`, 영어의 bare imperative, 한국어 반말/해요체/합니다체는 형태 대응이 아니라 관계 효과로 비교한다.

## 4. 출력 계약

형식 지정이 없는 채팅 AUTHOR 계열:

```text
Scene Lock
KO canonical
KO accepted variants + variant policy
EN localization
DE localization
Triad audit
Evidence and review status
```

JSON/CSV 요청:

- 원래 schema와 필드 순서 계약을 보존한다.
- target schema가 허용할 때만 `acceptedVariants`를 넣는다.
- 감사 설명은 별도 sidecar/report로 분리한다.
- 모델 상태는 `MODEL_QA_PASS | FLAG | EVIDENCE_REQUIRED` 중 하나다.
- `HUMAN_APPROVED`, `NATIVE_APPROVED`, `EDUCATOR_APPROVED`를 모델이 생성하지 않는다.

## 5. 감사 실패 예

- 열린 말하기 변형이 사실대로 알리기를 “상사에게 공식 신고”로 구체화함: `ACC/REL/FORCE`
- Cloze 허용 변형이 distractor로 노출됨: `ITEM/DATA`
- 받아쓰기 변형이 `정리해서 다시 말씀드리다`를 `생각하고 연락하다`로 바꿈: `ACC/ITEM`
- 공개 브리핑의 한국어 요청을 독일어 `du`와 영어 `stuff`로 낮춤: `REL/TERM/NAT`
- KO 정본에는 없는 `quick`, `immediately`, `dringend`를 추가함: `FORCE/PRESUP`
