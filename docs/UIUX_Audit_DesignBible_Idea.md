# 한글소리 UI/UX 심층 진단 및 디자인 바이블 제안

## 먼저 결론

한글소리의 현재 문제를 “예쁘지 않다” 또는 “스크롤이 조금 생긴다”로 정의하면 안 됩니다. 사용자가 설명한 현상은 더 근본적으로 **디자인 시스템이 화면보다 늦게 만들어지고 있는 상태**에 가깝습니다.

즉,

> `화면 → 그때그때 스타일 결정 → 다음 화면 → 또 다른 스타일 결정`

의 구조를

> `브랜드 철학 → Foundation → Semantic Token → Component → Pattern → Page Template → Screen`

순서로 뒤집어야 합니다.

이렇게 바꾸면 CTA의 색, pill 높이, 카드 padding, 제목 크기, 페이지 좌우 여백, tablet 최대 폭, 단청 SVG의 강도까지 **개별 개발자가 결정할 일이 거의 없어집니다.** 화면이 늘어날수록 오히려 통일성이 강해지는 구조가 됩니다.

그리고 두 번째로 중요한 결론은 이것입니다.

**“한 화면 안에 모든 내용을 다 보이게 한다”를 목표로 잡으면 오히려 UI가 망가질 가능성이 큽니다.**

Apple도 현재 HIG에서 중요한 정보의 우선순위를 시각적 위계로 표현하고, 모든 콘텐츠를 한 번에 노출할 수 없는 경우 progressive disclosure를 사용하며, 정렬과 충분한 공간으로 관계를 분명하게 만들 것을 권고합니다. 즉 **스크롤 자체가 문제가 아니라, 사용자가 ‘여기서 무엇을 해야 하는지’가 fold 전후로 애매해지는 것이 문제**입니다. citeturn0search2turn0search7

한글소리는 therefore 앞으로 이렇게 정의하는 것이 가장 좋습니다.

> **“한국어를 배우는 디지털 한옥.”**
>
> 콘텐츠는 조용하고 읽기 쉬워야 하고,  
> 인터랙션은 즉각 이해되어야 하고,  
> 단청은 장식이 아니라 브랜드의 리듬이어야 하며,  
> 모든 화면은 같은 건축 규칙으로 지어진 서로 다른 방이어야 한다.

이 철학이 제일 중요합니다.

---

## 현재 한글소리의 구조적 UI/UX 진단

### GitHub 소스 조사에서 확인한 범위와 한계

연결된 GitHub를 통해 `Sujin-Arin-DataWorld/ko_lernen_app`의 리포지토리 루트와 `lib`, `lib/screens`, `docs` 및 전체 recursive tree까지 조사했고, 사용자가 언급한 deep-research 문서와 `Screenshot_` 계열 파일도 검색 대상으로 넣었습니다.

다만 이번 조사 실행에서는 **리포지토리의 개별 파일 body 전체와 이미지 binary를 최종 응답 전에 전부 렌더링하는 단계까지 완주하지 못했습니다.** 따라서 “특정 Dart 파일 몇 번째 줄에서 padding이 12이고 다른 파일에서 20이다”와 같은 line-by-line code audit이나 Screenshot_ 파일별 visual redline을 완료했다고 주장하지 않겠습니다.

특히 사용자가 요구한 두 개의 deep-research Markdown 문서 역시 경로 탐색과 검색까지는 수행했으나, 그 문서 전체 본문을 이 답변에서 신뢰할 수준으로 완전히 회수하지 못했습니다.

그래서 아래에서는 세 가지를 명확하게 구분합니다.

**확정적으로 말할 수 있는 것**은 사용자가 실제 테스트에서 발견한 문제, 연결된 GitHub에서 확인한 앱/화면/docs 중심의 프로젝트 구조, 2026년 현재 확인된 Apple 플랫폼 가이드입니다.

**소스 레벨에서 추가 확인이 필요한 것**은 특정 screen별 hard-coded 값, 중복 widget 수, 실제 theme 구조, breakpoint 구현, font 설정, Screenshot별 세부 문제입니다.

**아래의 디자인 바이블 수치와 architecture는 제 추천안**입니다. 즉 플랫폼 기본값을 복사한 것이 아니라, 한글소리처럼 모바일·태블릿·웹 및 KO/EN/DE를 동시에 운영할 앱을 위한 **내부 표준**입니다.

이 구분은 중요합니다. 실제로 보지 못한 화면을 본 것처럼 꾸며 설명하는 것보다, 앞으로 개발자가 바로 적용할 수 있는 시스템을 만드는 것이 훨씬 가치 있기 때문입니다.

### 사용자가 설명한 문제는 사실 모두 같은 원인에서 발생한다

현재 보고된 증상을 정리하면 다음과 같습니다.

| 관찰되는 현상 | 표면적인 해결 | 실제로 필요한 해결 |
|---|---|---|
| CTA가 화면마다 다른 색 | 버튼 색 수정 | semantic CTA component |
| pill 크기가 다름 | height 통일 | filter component contract |
| pill 위치가 다름 | padding 수정 | page template 규칙 |
| 카드 간격이 제각각 | margin 조정 | spacing token |
| 한 화면 끝부분이 애매하게 잘림 | 화면 압축 | viewport-aware composition |
| 콘텐츠마다 density가 다름 | individual redesign | content-density rule |
| 태블릿에서 너무 넓어짐 | padding 추가 | max-width + adaptive layout |
| 한/영/독 문구마다 깨짐 | fontsize 축소 | localization-aware layout |
| 단청 색상이 곳곳에서 경쟁 | saturation 낮춤 | brand-color semantics |
| 화면 개발할수록 디자인이 달라짐 | review 강화 | component ownership |

즉 핵심 문제는 **“UI 값이 너무 많다”가 아니라 “UI 결정을 내릴 수 있는 장소가 너무 많다”**는 것입니다.

예를 들어 현재 버튼의 색을 열 개 화면에서 직접 정할 수 있다면, 디자인 리뷰를 아무리 열심히 해도 언젠가는 열한 번째 스타일이 생깁니다.

반대로:

```text
HSPrimaryButton
HSSecondaryButton
HSTertiaryButton
HSDangerButton
```

네 컴포넌트 외에는 CTA를 만들 수 없게 해두면 문제 자체가 사라집니다.

### “조금 스크롤해야 한다” 문제를 다시 정의해야 한다

Apple의 최신 Layout 가이드는 콘텐츠와 컨트롤을 명확히 분리하고, 중요도에 따라 위계를 만들며, 한 번에 모두 보이지 않는 내용에는 progressive disclosure를 활용하라고 설명합니다. 또한 여러 화면 크기와 시스템 환경에 UI가 동적으로 적응해야 한다고 명시합니다. citeturn0search2

따라서 한글소리의 목표는:

**나쁜 목표**

> 390×844 화면에 모든 내용을 무조건 맞춘다.

가 아니라,

**좋은 목표**

> 첫 viewport만 보고도 현재 위치, 학습 목표, 중요한 콘텐츠, 다음 행동을 이해할 수 있다.

여야 합니다.

예를 들어 문제풀이 화면은:

```text
[Progress        3 / 10]

오늘의 질문

"학교에 가요"의 의미는?

[ 선택지 A               ]
[ 선택지 B               ]
[ 선택지 C               ]
[ 선택지 D               ]

       콘텐츠 scroll 가능

┌─────────────────────────┐
│       정답 확인          │  ← 항상 안정적 위치
└─────────────────────────┘
```

이런 구조가 좋습니다.

반면:

```text
제목
설명
긴 설명
배지
힌트
이미지
선택지
문법 설명
버튼
```

전체를 억지로 viewport 안에 압축시키면 글씨가 작아지고 카드가 좁아지고 터치 영역까지 작아지면서 **“스크롤이 없는 대신 학습하기 어려운 화면”**이 됩니다.

Apple 역시 iOS/iPadOS에서 기본적인 custom type의 가독성을 위해 17pt를 기본값으로 제시하며, accessibility에서는 큰 텍스트 확대와 충분한 컨트롤 크기를 강조합니다. citeturn0search0turn0search1

---

## 한글소리만의 디자인 시스템

제가 한글소리에서 가장 강하게 권하는 방향은 **“단청을 UI color palette로 사용하는 것”에서 “한옥의 질서를 UI architecture로 사용하는 것”으로 한 단계 올라가는 것**입니다.

이 차이가 굉장히 큽니다.

단청의 빨강, 파랑, 초록, 노랑을 버튼마다 넣으면 “한국풍 앱”은 되지만 고급스러운 한옥 경험은 되기 어렵습니다.

반대로 한옥에서 가져올 수 있는 것은:

- 반복되는 모듈
- 질서 있는 간격
- 프레임
- 비움
- 중심과 주변의 관계
- 절제된 장식
- 재료의 따뜻함
- 반복되는 문양의 리듬

입니다.

### 디자인 시스템의 계층

한글소리 Design Bible은 아래 여섯 층으로 관리하는 것이 좋습니다.

```text
HANGUL SORI DESIGN SYSTEM

Foundation
├─ Color
├─ Typography
├─ Spacing
├─ Radius
├─ Elevation
├─ Iconography
├─ Motion
└─ Grid

Semantic Tokens
├─ contentPrimary
├─ contentSecondary
├─ actionPrimary
├─ actionSecondary
├─ surface...
└─ feedback...

Components
├─ Buttons
├─ Chips
├─ Cards
├─ Inputs
├─ Progress
├─ Navigation
└─ Feedback

Patterns
├─ Lesson Header
├─ Choice Group
├─ Word Block
├─ Filter Bar
├─ Bottom CTA
└─ Result Summary

Templates
├─ Learning List
├─ Content Detail
├─ Exercise
├─ Vocabulary
├─ Result
└─ Settings

Screens
└─ 실제 콘텐츠만 조립
```

가장 중요한 규칙은:

> **Screen layer에서는 새로운 디자인을 만들지 않는다.**

화면 개발자가 할 일은 컴포넌트를 조립하는 것입니다.

### 한글소리 색상 시스템

단청색을 그대로 semantic state와 연결시키는 것은 피해야 합니다.

특히 브랜드 빨간색을 모든 주요 버튼에도 사용하고 error에도 사용하면 사용자가 색의 의미를 학습할 수 없습니다.

제가 권하는 구조는 다음입니다.

#### Base surfaces

| Token | 역할 | 권장 방향 |
|---|---|---|
| `surfaceCanvas` | 전체 앱 배경 | 따뜻한 한지색 |
| `surfacePrimary` | 카드 | 거의 흰 한지색 |
| `surfaceRaised` | dialog/menu | neutral white |
| `surfaceMuted` | 비활성 영역 | warm gray |
| `borderSubtle` | 카드/구획 | low contrast warm gray |
| `contentPrimary` | 주요 글자 | 먹색에 가까운 dark neutral |
| `contentSecondary` | 보조 정보 | muted dark gray |

완전한 `#000000 / #FFFFFF`보다 브랜드에서는 아주 약간 warm한 surface와 ink 계열을 추천합니다.

#### Dancheong semantic colors

한글소리에서는 대략 이런 역할 분담이 좋습니다.

```text
청록/청색 계열
→ Primary Interaction

단청 적색
→ Brand Accent / important highlight

황토·금색
→ Achievement / premium / cultural accent

초록
→ Success

밝은 한지색
→ Canvas

먹색
→ Typography
```

특히 **Primary CTA는 한 색으로 고정하십시오.**

페이지마다:

- 빨강 버튼
- 초록 버튼
- 파랑 버튼
- 황색 버튼

이 되는 순간 사용자는 각각 다른 의미의 action이라고 느끼게 됩니다.

그래서:

```text
Primary action
→ 항상 actionPrimary

Correct answer
→ semanticSuccess

Wrong answer
→ semanticError

Selected
→ selectionPrimary

Cultural accent
→ brandDancheongRed
```

처럼 사용해야 합니다.

### 단청은 “컬러”보다 “포인트”로 사용한다

제가 강력하게 권하는 브랜드 규칙입니다.

> 한 viewport에서 단청 장식이 시선을 가장 먼저 끄는 영역은 **최대 한 군데**.

예:

**좋음**

```text
단청 motif
   ↓
[ Lesson Complete! ]

깔끔한 white/hanji cards

Primary CTA
```

**나쁨**

```text
단청 appbar
단청 card
빨강 CTA
초록 chips
노랑 badge
단청 divider
단청 background
단청 footer
```

한옥의 아름다움은 “모든 곳이 화려하다”가 아닙니다.

따라서 장식은 다음 위치에서 특히 잘 작동합니다.

- onboarding hero
- course milestone
- lesson completion
- achievement
- empty state illustration
- section opening
- cultural note
- premium content identity

반대로 **긴 한국어 본문, 문법 설명, 선택지 카드의 background에는 단청 pattern을 넣지 않는 것**을 권합니다.

---

### SVG 사용 규칙

사용자가 특별히 언급한 SVG는 한글소리 브랜드에서 굉장히 좋은 선택입니다.

단청 패턴, 창호, 처마 선, 기와 silhouette 같은 시각 요소는 bitmap보다 SVG 자산으로 만들고 디자인 토큰과 연결하는 편이 좋습니다.

한글소리의 SVG는 최소한 다음 규칙을 가져야 합니다.

```text
SVG-01  반드시 viewBox 사용
SVG-02  fixed pixel width/height에 의존하지 않음
SVG-03  aspect ratio 보존
SVG-04  화면마다 새로운 색을 직접 넣지 않음
SVG-05  brand SVG palette token만 사용
SVG-06  decorative SVG는 accessibility tree에서 제외
SVG-07  의미를 전달하는 SVG에는 semantic label 제공
SVG-08  본문 뒤 pattern opacity는 매우 낮게
SVG-09  한 화면에 dominant pattern 1개 원칙
SVG-10  320px에서도 motif가 뭉개지지 않아야 함
```

색상도 SVG 내부에서 임의로:

```xml
fill="#D9382F"
```

를 수십 군데 만드는 방식보다 브랜드 asset 자체를 version 관리하거나, 가능한 구현에서는 semantic color를 주입하는 방향이 좋습니다.

### 둥근 모서리도 통제해야 한다

EdTech 앱들이 모든 것을 pill과 큰 radius로 처리하기 쉽습니다.

하지만 한글소리까지 그렇게 하면 문화적 개성이 없어집니다.

추천:

| Token | 값 |
|---|---:|
| `radiusXs` | 6 |
| `radiusSm` | 8 |
| `radiusMd` | 12 |
| `radiusLg` | 16 |
| `radiusXl` | 20 |
| `radiusPill` | 999 |

그리고 사용 범위:

```text
Filter chip        → Pill
Small badge        → Pill
Input              → 12
Choice card        → 12
Word card          → 16
Large feature card → 16–20
Dialog             → 20
```

**모든 카드가 24–32 radius인 디자인은 한글소리에는 추천하지 않습니다.**

한옥의 구조적인 느낌을 조금 남기기 위해 card geometry는 다른 consumer app보다 약간 단정한 편이 더 어울립니다.

---

## 타이포그래피·간격·반응형 바이블

### 먼저 폰트는 “화면별”이 아니라 “언어 시스템”으로 결정한다

한글소리는 KO/EN/DE를 지원하므로 이 부분을 매우 초기에 확정해야 합니다.

특히 다음을 해서는 안 됩니다.

```text
한국어는 예쁜 한글 폰트
영어는 별도 영어 폰트
독일어는 browser default
```

이렇게 되면 실제 multilingual UI에서 baseline, x-height, weight, line height가 모두 달라져 UI가 흔들립니다.

제가 추천하는 방향은 두 가지입니다.

#### 가장 안정적인 안

**Noto Sans KR 계열을 중심 body family로 두고 Latin도 동일한 visual system 안에 유지.**

Noto 계열은 multilingual product에 적합한 후보입니다.

#### 조금 더 현대적인 한글소리

본문/UI:

> **Pretendard 또는 유사한 현대적 Korean/Latin sans**

문화적 콘텐츠의 제한된 display text:

> 별도의 Korean serif / traditional-feel typeface

즉:

```text
UI / 학습 / 버튼 / 메뉴
→ Sans

문화 설명 제목 / 특별한 Korean culture moment
→ Display Serif

긴 본문을 Serif로 쓰지 않음.
```

Noto Sans KR, Pretendard, SUIT 등은 상업 앱/웹에서 검토 가치가 높은 후보이지만, **이번 조사 실행에서는 각 프로젝트의 2026-08-20 현재 공식 라이선스 파일을 최종 대조하는 단계까지 완료하지 못했으므로 출시용 Design Bible에 “commercial-approved”로 확정 등록하기 전에 반드시 해당 버전의 공식 LICENSE를 저장·검증해야 합니다.**

라이선스는 “폰트 이름이 예전에 무료였다”가 아니라 **실제 빌드에 포함한 font file version의 license**를 기준으로 관리하는 것을 권합니다.

### 제가 권하는 한글소리 type scale

화면마다 `15`, `16`, `17`, `18`을 느낌대로 선택하는 것을 금지합니다.

```text
Display
32 / 40 / 700

Heading XL
28 / 36 / 700

Heading L
24 / 32 / 700

Heading M
20 / 28 / 600~700

Title
18 / 26 / 600

Body L
17 / 26 / 400~500

Body
16 / 24 / 400

Body S
14 / 21 / 400

Label L
16 / 22 / 600

Label
14 / 20 / 600

Caption
12 / 18 / 400~500
```

여기서 앞 숫자는 font size, 뒤는 line height입니다.

Apple의 최신 HIG에서도 iOS/iPadOS의 권장 기본 text size를 17pt로 제시하고 있으며, custom type에서도 지나치게 작은 글자를 피하고 Dynamic Type을 고려하도록 안내합니다. citeturn0search0turn0search1

한글소리에서는 11~12를 **본문용으로 사용하지 않는 것**을 추천합니다.

12는:

- timestamp
- 보조 caption
- 아주 낮은 위계의 metadata

정도만 허용하십시오.

### 한글은 line-height를 아끼지 않는 것이 좋다

한국어는 자모가 한 글자 안에 조밀하게 모이고 학습자는 모국어 사용자가 아닐 수도 있습니다.

따라서 특히 학습 문장:

```text
한국어
romanization
translation
grammar note
```

가 붙는 순간 vertical spacing이 상당히 중요합니다.

예:

```text
학교에 가요.
Body L / SemiBold

hakgyoe gayo.
Body S / Secondary

I go to school.
Body / Primary
```

세 행을 4px 간격으로 붙이는 것이 아니라 의미 단위로 묶어야 합니다.

추천:

```text
Korean → Romanization    6–8
Romanization → Meaning   8
Meaning → Grammar note   12–16
```

Romanization은 항상 보여주는 것도 재검토할 가치가 있습니다. 학습 단계가 올라갈수록 숨기거나 선택적으로 제공하면 한국어 자체를 읽는 연습에 도움이 되는 UI가 됩니다.

### 독일어 때문에 fixed-height UI를 금지한다

예를 들어:

```text
Weiter
```

와

```text
Lernfortschritt zurücksetzen
```

은 필요한 horizontal space가 완전히 다릅니다.

따라서:

```dart
width: 112
height: 40
```

같은 버튼은 multilingual UI에서 문제가 되기 쉽습니다.

한글소리 원칙:

> **Width는 부모 constraint로 결정하고, text는 필요한 만큼 layout한다.**

버튼 높이 역시 label이 두 줄이 될 수 있는 경우 확장 가능한 컴포넌트여야 합니다.

`maxLines: 1 + fontSize 축소`를 기본 해결법으로 삼지 마십시오.

### Text scaling도 처음부터 기준에 들어가야 한다

Apple은 accessibility guidance에서 더 큰 텍스트를 지원하고, 이상적으로 사용자가 상당한 수준까지 텍스트를 확대할 수 있도록 설계하라고 권고합니다. citeturn0search0turn0search3

따라서 한글소리는 QA에서 최소:

```text
100%
130%
160%
200%
```

수준을 테스트하는 것이 좋습니다.

200%에서 화면이 “원래와 똑같이 예쁜 것”이 목표가 아닙니다.

목표는:

- 내용이 잘리지 않고
- 버튼이 사라지지 않고
- 텍스트가 겹치지 않고
- 기능을 완료할 수 있는 것

입니다.

### 모든 spacing을 이 표에 가둔다

한글소리의 가장 강력한 정리 방법 중 하나입니다.

```text
space2   = 2
space4   = 4
space8   = 8
space12  = 12
space16  = 16
space20  = 20
space24  = 24
space32  = 32
space40  = 40
space48  = 48
space64  = 64
```

`13`, `15`, `17`, `19`, `23`, `27` 같은 값은 특별한 이유가 없다면 screen code에 등장하지 않게 합니다.

그리고 의미까지 부여합니다.

| 관계 | 권장 간격 |
|---|---:|
| Icon ↔ label | 8 |
| label ↔ helper | 4–8 |
| 같은 group 안 항목 | 8–12 |
| cards 사이 | 12 |
| card 내부 padding mobile | 16 |
| 중요한 card 내부 padding | 20 |
| section title ↔ content | 12–16 |
| section ↔ section | 32 |
| 큰 semantic 영역 | 40–48 |

핵심은 숫자 그 자체보다 **같은 관계는 같은 간격**이라는 원칙입니다.

### Page gutter

제가 한글소리에 권하는 responsive gutter는:

```text
< 360     → 16
360–599   → 20
600–839   → 24
840–1199  → 32
1200+     → 40–48
```

하지만 내용까지 무한히 넓혀서는 안 됩니다.

### Max-width가 태블릿 품질을 결정한다

태블릿 대응에서 자주 생기는 실수:

```text
phone:
[            card             ]

tablet:
[                         gigantic card                         ]
```

입니다.

한글소리는 container에 max-width를 둬야 합니다.

제가 추천하는 starting values:

```text
Reading / grammar body
→ 680–720

Exercise
→ 640–680

Settings / form
→ 600–640

CTA
→ 480–560

Dashboard
→ 1100–1200

Grid container
→ 1200 전후
```

즉 13-inch tablet에서 단어 하나가 폭 900짜리 카드 안에 덩그러니 들어가서는 안 됩니다.

### 기종을 판단하지 말고 available width를 판단한다

이게 앞으로의 한글소리에서 매우 중요합니다.

하지 말아야 할 것:

```text
if iPhone
if Galaxy S
if iPad
if Pixel Fold
...
```

대신:

```text
available width
available height
text scale
safe area
orientation
input modality
```

를 기준으로 합니다.

Apple 또한 현재 HIG에서 앱이 다양한 화면 크기, resolution, system environment 변화에 적응하도록 설계하고 size class 등의 환경 정보를 활용하도록 안내합니다. 2025년 이후의 HIG에는 iPhone 17 계열과 여러 iPad 크기까지 다수의 규격이 나열되어 있어, 한두 개 device mockup에 맞춘 고정 레이아웃이 현실적으로 충분하지 않다는 점도 분명합니다. citeturn0search2

### 한글소리 내부 breakpoint 제안

이 값은 제가 **한글소리 Design System용으로 추천하는 값**입니다.

```text
Compact
0–599

Medium
600–839

Expanded
840–1199

Large
1200+
```

그리고 화면은 다음처럼 바뀝니다.

| Width | Navigation | Content |
|---|---|---|
| Compact | Bottom Navigation | 1 column |
| Medium | Bottom/compact rail | 1–2 columns |
| Expanded | Navigation Rail | 2-pane 가능 |
| Large | Rail/sidebar | centered multi-column |

### Flutter라면 이런 방향이어야 한다

소스가 Flutter architecture를 사용하고 있다는 전제에서 권장하는 핵심은 `MediaQuery.width`를 각 화면에서 제멋대로 검사하는 것이 아니라 **공통 adaptive primitive**를 만드는 것입니다.

개념적으로:

```dart
enum HSWindowClass {
  compact,
  medium,
  expanded,
  large,
}

HSWindowClass windowClassFor(double width) {
  if (width < 600) return HSWindowClass.compact;
  if (width < 840) return HSWindowClass.medium;
  if (width < 1200) return HSWindowClass.expanded;
  return HSWindowClass.large;
}
```

그리고 모든 화면에서:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final windowClass =
        windowClassFor(constraints.maxWidth);

    return HSResponsivePage(
      windowClass: windowClass,
      child: ...,
    );
  },
);
```

처럼 같은 판단 체계를 사용해야 합니다.

더 중요한 것은 **breakpoint 자체도 token**이라는 점입니다.

Screen A:

```dart
if (width > 700)
```

Screen B:

```dart
if (width > 768)
```

Screen C:

```dart
if (width > 900)
```

이런 코드가 생기면 지금의 UI inconsistency가 그대로 responsive inconsistency로 확대됩니다.

---

## 컴포넌트 바이블과 화면 구성 규칙

여기가 실제 개발에서 가장 중요합니다.

### CTA

한글소리 전체에서 primary CTA specification을 하나로 고정하십시오.

#### Primary CTA

```text
height
52 mobile
52–56 tablet

minimum interactive area
48 × 48 internal standard

horizontal padding
20–24

corner radius
14–16

font
16 / 600

icon-label gap
8

mobile width
available width

tablet/web width
max 520 정도

position
page bottom 또는 flow 내부
screen별 임의 위치 금지
```

Apple은 현재 iOS/iPadOS에서 기본적으로 충분히 큰 control을 사용하도록 권고하며, 일반적인 touch target에 44×44pt를 제시합니다. 요소 사이의 공간 역시 오작동 방지를 위해 중요하다고 설명합니다. citeturn0search0turn0search3turn0search7

따라서 한글소리 내부 규칙을 **최소 48 logical units**로 잡으면 cross-platform component를 운용하기 편합니다.

#### CTA hierarchy

한 화면에는 원칙적으로:

```text
Primary      최대 1
Secondary    0–2
Tertiary     필요할 때
Destructive  semantic action에만
```

Primary CTA가:

```text
다음
계속
확인
시작
저장
```

이라고 해서 각각 다른 색이 되어서는 안 됩니다.

**색은 행동의 이름이 아니라 hierarchy를 표시합니다.**

### Sticky Bottom CTA

특히 lesson/exercise에는 다음 패턴을 추천합니다.

```text
┌──────────────────────────┐
│ App Bar                  │
├──────────────────────────┤
│                          │
│    scrollable content    │
│                          │
│                          │
├──────────────────────────┤
│ [       정답 확인       ] │
│ safe area                │
└──────────────────────────┘
```

이렇게 하면 사용자가 작은 휴대폰에서도 행동을 찾기 위해 화면 아래로 “조금 더” 스크롤할 필요가 없습니다.

단, 모든 페이지에 sticky CTA를 넣어서는 안 됩니다.

추천:

| 화면 | Sticky CTA |
|---|---|
| 문제풀이 | Yes |
| flashcard review | Yes |
| onboarding step | Yes |
| form completion | 대체로 Yes |
| 긴 문법 article | No |
| lesson list | No |
| settings list | No |
| dashboard | No |

### Filter pill

사용자가 지적한 가장 대표적인 inconsistency이므로 즉시 system화할 가치가 있습니다.

**한글소리 Filter Chip**

```text
height             40
horizontal padding 14–16
icon                16
icon gap             6
label               14 / 600
chip gap             8
row gap              8
radius             pill
```

상태:

```text
default
selected
pressed
disabled
focus
```

다섯 개만 허용합니다.

Filter마다 크기를 달리하지 않습니다.

```text
A1
A2
B1
B2
전체
```

이런 level chip은 특히 같은 component를 써야 합니다.

위치 역시 화면마다 바꾸지 말고:

```text
Page title
12–16
Optional description
16
Filter row
24
Content
```

같은 template을 적용하십시오.

### 필터가 많아질 때

모든 pill을 줄바꿈해 3줄씩 보여주는 방법은 권하지 않습니다.

Mobile:

```text
Level
[A1] [A2] [B1] → horizontal scroll
```

또는 중요한 filter만 inline하고 advanced filter는 sheet로 내립니다.

한글소리에서는 **학습 수준을 나타내는 CEFR-like level filter와 content category filter가 하나의 row 안에서 경쟁하지 않도록** category hierarchy를 분리하는 것이 좋습니다.

### 선택지 카드

문제풀이 card는 일반 content card와 다른 component여야 합니다.

권장:

```text
minimum height       56
padding vertical     14–16
padding horizontal   16
radius               12
border               1
choice gap           12
```

상태:

```text
Default
Selected
Correct
Incorrect
Disabled
```

중요한 원칙:

> 색만으로 정답/오답을 표시하지 않는다.

예:

```text
✓ 정답 text/icon + semantic color
! 다시 확인 text/icon + semantic color
```

Apple accessibility guidance 역시 정보를 하나의 감각적 수단에만 의존하지 않는 인터페이스를 권고합니다. citeturn0search0

### 단어 카드

텍스트 중심 단어 카드는 **aspect ratio를 강제하지 않는 것**을 권합니다.

이건 특히 중요합니다.

사용자가 질문한 “단어카드 화면 비율”을 4:3이나 16:9 같은 고정 비율로 설정하면 KO/EN/DE와 text scaling에서 쉽게 깨집니다.

이미지는 aspect ratio를 사용해도 됩니다.

텍스트 카드는:

```text
width       responsive
min-height  only
height      content driven
```

가 더 안정적입니다.

Mobile 예:

```text
┌────────────────────────────┐
│ 학교                       │
│                            │
│ 학교 · hakgyo              │
│ school                     │
│                            │
│ 🔊 발음 듣기     ☆ 저장     │
└────────────────────────────┘
```

Recommended:

```text
padding   16–20
radius    16
internal gap 8 / 12 / 16
card gap  12
```

Tablet에서는 단어 카드가 짧다면 2-column grid를 사용할 수 있습니다.

그러나 긴 문법 설명과 flashcard를 동일 grid component로 취급하지 마십시오.

### Card 종류를 의도적으로 제한한다

제가 추천하는 카드 inventory:

```text
HSContentCard
HSLessonCard
HSVocabularyCard
HSChoiceCard
HSProgressCard
HSCultureCard
HSFeedbackCard
```

이 정도면 충분합니다.

화면 하나 만들 때마다:

```text
Container(
  decoration: BoxDecoration(...)
)
```

를 새로 만드는 습관을 없애는 것이 핵심입니다.

### Header

모든 screen이 임의의 header를 가지면 앱 전체가 흔들립니다.

추천:

```text
HSPageHeader

leading
title
optional subtitle
optional trailing action
optional progress
```

그리고 title 위치를 고정합니다.

Mobile:

```text
←    단어 학습              ⋮
```

Tablet:

```text
단어 학습
오늘 배운 단어를 복습하세요
```

처럼 layout variant만 component 내부에서 처리합니다.

### Navigation

모바일에서는 bottom navigation을 중심으로, 넓은 화면에서는 rail/sidebar로 전환하는 방향이 좋습니다.

중요한 점은 단순히:

```text
bottom nav → 같은 폭으로 확대
```

가 아니라 **navigation model 자체가 window class에 대응해야 한다**는 것입니다.

Tablet에는 넓어진 공간을 이용해:

```text
Lesson List | Lesson Detail
```

처럼 list-detail 2-pane을 적용할 수 있습니다.

이것이 tablet 최적화입니다.

“글씨와 카드를 1.4배 키우는 것”이 tablet 최적화가 아닙니다.

---

### 화면별 개선 방향

실제 Screenshot_ 파일 전체를 이번 실행에서 픽셀 단위로 redline하지 못했기 때문에 아래는 파일명을 가장한 가짜 진단이 아니라, **한글소리의 screen family별 개편 specification**으로 제시합니다.

#### 홈 / 학습 허브

목표는 “많은 것을 보여준다”가 아니라 **오늘 무엇을 하면 되는가**입니다.

추천 hierarchy:

```text
Greeting / Current Level

오늘의 학습
┌────────────────────────┐
│ 계속 학습하기           │
│ Lesson 12 · 7분         │
│ ███████░░ 70%           │
└────────────────────────┘

Quick actions

학습 과정
...

최근 단어
...
```

Home 첫 viewport에 CTA를 세 개 이상 동일한 시각적 무게로 두지 않는 것이 좋습니다.

대표 CTA:

> 학습 계속하기

하나를 primary로 두십시오.

문화·단청 hero를 가장 강하게 넣기 좋은 페이지가 바로 홈입니다.

#### Lesson 목록

페이지 규칙:

```text
Page header
Level / category filters
Section title
Lesson cards
```

필터를 항상 같은 위치에 두고 lesson card 높이를 지나치게 고정하지 않습니다.

Lesson card에는 가능한 정보 hierarchy를 통일합니다.

```text
Lesson 08
학교에서

18개 표현 · 약 8분

████████░░

계속하기 →
```

카드마다 button 위치가 달라지지 않게 합니다.

#### 문법 / 설명 콘텐츠

이 페이지는 “한 화면에 다 들어가야 한다”는 생각을 가장 먼저 버려야 합니다.

Reading width를 제한하고:

```text
Title

One-sentence summary

Example
┌──────────────────────┐
│ 저는 학교에 가요.     │
│ I go to school.      │
└──────────────────────┘

Explanation

Pattern

More examples
```

로 chunking하십시오.

긴 카드 한 개에 설명을 다 넣는 것보다 semantic section으로 분리하는 게 좋습니다.

### Exercise / Quiz

학습 앱에서 가장 일관되어야 하는 화면입니다.

전체 exercise shell을 하나 만드십시오.

```text
HSExerciseScaffold
├ Progress header
├ Instruction
├ Prompt
├ Interaction area
├ Feedback region
└ Bottom CTA
```

문제 유형이:

- 객관식
- 빈칸
- 듣기
- 단어 조합
- 받아쓰기

로 달라져도 **shell은 달라지지 않습니다.**

이것만 잘해도 한글소리의 “화면마다 다른 앱 같은 느낌”이 크게 줄어듭니다.

### 정답 피드백

정답 직후 layout 전체를 밀어버리는 giant banner보다는 bottom CTA와 연결된 feedback area를 추천합니다.

```text
✓ 맞았어요!

가요
→ 동사 '가다'의 해요체예요.

[ 다음 ]
```

오답:

```text
다시 한번 볼까요?

학교에 ___.
정답: 가요

[ 계속 ]
```

색뿐 아니라 icon + wording으로 의미를 전달합니다.

### Vocabulary

단어 목록과 단어 학습은 구분하십시오.

목록:

```text
Search
Level filter
Category filter

학교                🔊
school

학생                🔊
student
```

학습:

```text
large focused word card
audio
meaning
example
known / review controls
```

즉 **관리 화면과 학습 화면의 density가 같으면 안 됩니다.**

### Progress / Result

단청의 화려함을 가장 적극적으로 사용할 수 있는 곳입니다.

평상시 학습화면을 절제할수록 lesson complete 화면의 단청 motif가 훨씬 강한 브랜드 기억을 남깁니다.

```text
      subtle dancheong SVG

        잘했어요!
        Lesson 완료

       8 / 10 정답
       + 24 XP

    [ 다음 학습으로 ]

       결과 보기
```

이런 식입니다.

### Settings / Profile

이쪽은 브랜드 장식보다 system UI clarity를 우선합니다.

Settings가 단청 카드와 여러 색 icon으로 가득 차면 앱 전체가 피곤해집니다.

```text
Account
Language
Learning
Audio
Accessibility
About
```

과 같이 plain grouped list가 좋습니다.

---

## 한옥·단청 브랜드를 유지하면서 현대적인 앱으로 만드는 방법

### 한옥을 “배경 이미지”로 이해하지 않는다

제가 한글소리에서 가장 추천하고 싶은 브랜드 아이디어입니다.

한옥을 시각적으로 이렇게 번역할 수 있습니다.

| 한옥의 개념 | UI로 번역 |
|---|---|
| 마루 | 넉넉한 content plane |
| 기둥 | 강한 vertical alignment |
| 창호 | card/divider grid |
| 처마 | section framing |
| 단청 | accent / milestone |
| 한지 | warm neutral surface |
| 마당 | intentional empty space |
| 문턱 | section transition |
| 방 | page template |

이렇게 하면 “한옥 사진을 붙인 앱”과 완전히 달라집니다.

### 한글소리의 vibe는 “Traditional Minimal”이 좋다

제가 추천하는 위치는:

```text
Generic SaaS ───────────── Hanbok souvenir app
                    ↑
              Hangul Sori
```

어느 끝도 아닙니다.

즉:

> **현대적인 학습 인터페이스 80 + 한국적 문화 정체성 20**

정도를 기본으로 두고,

completion, culture lesson, onboarding 같은 순간에는:

> **현대적 UI 60 + 한국적 표현 40**

까지 올릴 수 있습니다.

항상 50:50으로 섞지 않는 것이 좋습니다.

### 단청 장식의 “예산”을 정한다

Design Bible에 실제로 아래 규칙을 넣는 것을 권합니다.

```text
Decorative Budget

Standard learning screen
→ 0–1 brand motif

Dashboard
→ 1 main motif

Exercise
→ 거의 0

Reading
→ section opening만

Completion
→ 1 strong motif

Culture content
→ 최대 2
```

이렇게 해야 개발자가 “여기 조금 허전한데 단청 넣을까?”를 반복하지 않습니다.

### Shadow도 줄인다

한지와 한옥 느낌에는 Material-style floating cards가 수십 개 겹치는 것보다 낮은 elevation이 잘 어울립니다.

권장:

```text
Level 0
flat

Level 1
subtle card

Level 2
floating menu / sticky CTA

Level 3
modal only
```

카드마다 큰 그림자가 있으면 공간이 무거워집니다.

### Animation

animation 역시 문화 identity와 연결할 수 있습니다.

한글소리에는 튀고 흔들리는 motion보다:

```text
fade
gentle slide
progress fill
stroke reveal
subtle scale
```

이 더 잘 어울립니다.

Apple은 Reduce Motion 설정을 존중하고 과도한 zoom, 반복적인 움직임, 강한 motion을 줄이도록 권고합니다. citeturn0search0

한글소리 내부 motion token은 예를 들어:

```text
fast     120 ms
normal   180 ms
emphasis 240 ms
long     320 ms
```

정도로 제한할 수 있습니다.

---

## 개발팀이 반드시 지키게 해야 할 UI/UX 바이블

디자인 문서만 만들면 몇 달 뒤 다시 무너집니다.

**Design Bible + Code Enforcement + Visual QA** 세 개가 같이 있어야 합니다.

### Design token을 single source of truth로

개념적으로:

```dart
abstract final class HSSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
}
```

Color:

```dart
abstract final class HSColors {
  // 절대 screen에서 직접 사용하지 않음.
}
```

그리고 더 중요한 semantic layer:

```dart
class HSColorScheme {
  final Color actionPrimary;
  final Color actionPrimaryPressed;

  final Color contentPrimary;
  final Color contentSecondary;

  final Color surfaceCanvas;
  final Color surfaceCard;

  final Color borderSubtle;

  final Color feedbackSuccess;
  final Color feedbackError;
  final Color feedbackWarning;
}
```

Screen에서:

```dart
Color(0xFF...)
```

를 직접 쓰는 것을 원칙적으로 금지합니다.

### Raw UI 값 금지

다음은 code review에서 red flag로 지정합니다.

```dart
EdgeInsets.all(17)
BorderRadius.circular(13)
fontSize: 15
Color(0xFF...)
height: 43
```

반드시 설명 가능한 token이어야 합니다.

단, illustration처럼 디자인상 정말 unique한 geometry는 예외입니다.

### Component ownership

새 화면을 만들 때 먼저 묻는 질문:

```text
이 화면에 새로운 component가 필요한가?
        ↓
YES
        ↓
기존 component로 해결할 수 없는 이유는?
        ↓
design-system review
        ↓
공용 component로 추가
```

하지 말아야 할 것:

```text
screen 안에 private custom UI 생성
→ 복사
→ 다른 screen에서 조금 수정
→ 또 복사
```

이것이 디자인 drift의 시작입니다.

### 한글소리에 만들어야 할 core UI package

최소:

```text
hs_ui/
├ foundations/
│ ├ color
│ ├ typography
│ ├ spacing
│ ├ radius
│ ├ elevation
│ ├ motion
│ └ breakpoints
│
├ components/
│ ├ buttons
│ ├ chips
│ ├ cards
│ ├ inputs
│ ├ progress
│ ├ feedback
│ ├ navigation
│ └ audio
│
├ patterns/
│ ├ page_header
│ ├ lesson_header
│ ├ filter_bar
│ ├ choice_group
│ ├ word_block
│ └ bottom_action
│
└ layouts/
  ├ responsive_page
  ├ reading_page
  ├ exercise_page
  └ list_detail_page
```

정도가 좋습니다.

### Page template를 먼저 만들어야 한다

제가 특히 추천하는 네 개입니다.

#### `HSStandardPage`

```text
AppBar
Page Header
Scrollable Content
```

#### `HSLearningPage`

```text
Progress
Instruction
Learning Content
Optional Bottom Action
```

#### `HSExercisePage`

```text
Progress
Question
Interaction
Feedback
Sticky CTA
```

#### `HSReadingPage`

```text
Reading max-width
Section rhythm
No sticky CTA
```

화면 30개가 있어도 실제 layout architecture는 몇 개 안 되어야 합니다.

### Golden screenshot matrix

Screenshot을 사람이 “대충 보기에 괜찮음”으로 검수하면 지금과 같은 문제가 반복됩니다.

한글소리는 동일 screen을 자동으로 다음 widths에서 캡처하는 것이 좋습니다.

```text
320
360
390
430

600
768
840

1024
1280
```

모든 실제 device를 의미하는 숫자가 아니라 **constraint boundary를 깨는 테스트 포인트**입니다.

여기에:

```text
KO
EN
DE
```

와

```text
text 100%
text 130%
text 160%
text 200%
```

를 교차 검증하십시오.

핵심 screen에 대해서만 해도 엄청난 효과가 있습니다.

예:

```text
ExerciseChoice

390 / KO / 100
390 / DE / 100
390 / KO / 160
768 / KO / 100
768 / DE / 160
```

이런 식입니다.

### Accessibility QA

Apple의 현재 accessibility guidance는 interface가 직관적이고 일관되며, 하나의 감각에만 의존하지 않고, 사용자 설정 및 더 큰 텍스트 등에 적응하도록 만드는 것을 강조합니다. citeturn0search0

한글소리 내부 기준을 다음 정도로 더 엄격하게 잡는 것을 추천합니다.

```text
Interactive target
≥ 48 × 48

Body text contrast
≥ 4.5 : 1 internal target

Large text / meaningful icons
≥ 3 : 1 internal target

Text scaling
200% functional

Color-only states
금지

Screen-reader label
interactive icon에는 필수

Decorative SVG
semantic tree 제외

Reduced motion
지원

Keyboard/focus
web/tablet에서는 필수 검수
```

### 디자인 리뷰 checklist

PR마다 다음 질문을 자동/수동으로 확인합니다.

```text
□ 새로운 raw color가 있는가?
□ 새로운 font size가 있는가?
□ 새로운 radius가 있는가?
□ 새로운 spacing 값이 있는가?
□ existing component 대신 custom container를 만들었는가?
□ 320 폭에서 깨지는가?
□ 430 폭에서는 공간이 이상하게 남는가?
□ tablet에서 너무 늘어나는가?
□ KO / EN / DE에서 모두 작동하는가?
□ text scale에서 잘리는가?
□ CTA hierarchy가 하나인가?
□ touch target이 충분한가?
□ selected/error가 color 하나에만 의존하는가?
□ SVG가 content를 방해하는가?
□ 해당 screen에 단청 장식이 정말 필요한가?
```

이 체크리스트가 **한글소리 UI/UX 품질을 지키는 실제 장치**가 됩니다.

---

## 한글소리를 위한 최종 추천안

### 제일 먼저 해야 할 일은 “리디자인”이 아니다

제가 이 프로젝트를 실제로 맡는다면 첫 작업을 홈 화면 redesign으로 시작하지 않을 것입니다.

먼저 **UI decision inventory**를 만듭니다.

현재 앱에 있는 모든:

```text
colors
font sizes
font weights
line heights
margins
paddings
radii
button heights
chip heights
card styles
app bars
bottom CTA
dividers
shadows
breakpoints
```

를 추출합니다.

가령 실제 결과가:

```text
font-size
12, 13, 14, 15, 16, 17, 18,
20, 21, 22, 24, 26, 28, 30, 32

radius
6, 8, 10, 12, 14, 16, 18,
20, 22, 24, 28, 32

padding
8, 10, 12, 14, 15, 16, 18,
20, 22, 24, 28, 30...
```

처럼 나온다면 이것을:

```text
Typography → 9 roles
Radius     → 6 tokens
Spacing    → 10 tokens
```

정도로 줄여야 합니다.

**UI cleanup의 핵심 KPI는 화면 개수가 아니라 visual decisions의 개수를 줄이는 것**입니다.

### 그다음 Foundation을 코드에 고정한다

우선순위:

| 우선순위 | 작업 | 효과 |
|---|---|---|
| Critical | color semantics | CTA 혼란 제거 |
| Critical | type scale | 가독성/위계 통일 |
| Critical | spacing tokens | “지저분한 느낌” 즉시 감소 |
| Critical | breakpoint system | tablet 대응 기반 |
| High | radius/elevation | card consistency |
| High | motion | 브랜드 polish |
| High | SVG rules | 단청 identity 통제 |

### 그 후 버튼과 pill부터 바꾼다

왜냐하면 사용자가 이미 가장 명확하게 불편을 느끼는 부분이기 때문입니다.

첫 component migration:

```text
Primary Button
Secondary Button
Filter Chip
Choice Card
Page Header
Bottom CTA
```

이 여섯 개를 먼저 교체하는 것이 좋습니다.

앱 전체의 인상이 생각보다 크게 달라집니다.

### 그다음 Exercise Shell

언어학습 앱은 일반적인 information app보다 interaction 반복이 많습니다.

사용자가 학습하는 동안:

```text
설명 읽기
→ 답 선택
→ 확인
→ 피드백
→ 다음
```

을 수십 번 반복합니다.

따라서 이 부분의 위치와 움직임이 변하지 않는 것이 중요합니다.

제가 한글소리에서 **가장 중요한 component 하나만 선택하라면 `HSExerciseScaffold`**를 선택합니다.

### 그리고 tablet

Phone UI를 확대하지 말고 다음과 같이 진화시킵니다.

#### Phone

```text
┌───────────────┐
│   CONTENT     │
│               │
│               │
│               │
├───────────────┤
│ NAVIGATION    │
└───────────────┘
```

#### Tablet

```text
┌────────┬────────────────────┐
│        │                    │
│  NAV   │      CONTENT       │
│        │     max width      │
│        │                    │
└────────┴────────────────────┘
```

#### 넓은 학습 화면

```text
┌────────┬───────────┬──────────────┐
│ NAV    │ LESSONS   │ CONTENT      │
│        │           │              │
│        │           │              │
└────────┴───────────┴──────────────┘
```

그러면 한글소리가 tablet에서 단순히 “커진 모바일 앱”이 아니라 제대로 된 학습 도구가 됩니다.

### 마지막에 브랜드 표현을 강화한다

보통 팀은 이것을 반대로 합니다.

```text
단청 배경
↓
예쁜 illustration
↓
animation
↓
spacing 정리
```

가 아니라:

```text
Layout
↓
Typography
↓
Spacing
↓
Interaction
↓
Responsive
↓
Accessibility
↓
Brand expression
```

순서여야 합니다.

그렇게 해야 단청이 문제를 숨기는 decoration이 아니라 **완성된 제품 위에 올라가는 identity**가 됩니다.

### 제가 정의한다면 한글소리 Design Principles는 이 여섯 문장입니다

**한국어가 가장 먼저 보인다.**  
장식보다 학습 대상인 한글이 항상 먼저 읽혀야 합니다.

**한 화면에는 하나의 가장 중요한 행동이 있다.**  
CTA 경쟁을 없앱니다.

**같은 의미는 항상 같은 모습이다.**  
버튼, chip, card, feedback의 semantic consistency를 절대 깨지 않습니다.

**스크롤을 두려워하지 않고 혼란을 두려워한다.**  
콘텐츠를 억지로 압축하지 않습니다. Apple 역시 작은 화면에서 모든 것을 동시에 노출하기보다 시각적 위계와 progressive disclosure를 활용하도록 안내합니다. citeturn0search2

**단청은 강조이고 한지는 공간이다.**  
단청을 모든 곳에 흩뿌리지 않습니다.

**기기가 달라도 같은 한글소리다.**  
device model이 아닌 layout constraints에 적응합니다. Apple의 현재 가이드 역시 다양한 화면 크기와 시스템 환경에 동적으로 적응하는 layout을 강조합니다. citeturn0search2

### 최종적으로 제가 목표로 잡을 한글소리의 모습

현재 상태가:

```text
Screen A ─ 자체 button
Screen B ─ 자체 filter
Screen C ─ 자체 card
Screen D ─ 자체 spacing
Screen E ─ 자체 responsive logic
```

이라면 최종 상태는:

```text
                         HANGUL SORI
                              │
                    ┌─────────┴─────────┐
                    │                   │
                 BRAND             FOUNDATION
                    │                   │
              Hanok / Dancheong    Type / Space
                    │              Color / Grid
                    │                   │
                    └─────────┬─────────┘
                              │
                         COMPONENTS
                              │
            ┌─────────────────┼─────────────────┐
            │                 │                 │
         Button             Card              Chip
         Header             Input            Progress
            │                 │                 │
            └─────────────────┼─────────────────┘
                              │
                           PATTERNS
                              │
           ┌──────────────────┼──────────────────┐
           │                  │                  │
        Lesson            Exercise          Vocabulary
           │                  │                  │
           └──────────────────┼──────────────────┘
                              │
                         PAGE TEMPLATES
                              │
                       실제 학습 화면들
```

이어야 합니다.

그렇게 되면 **새로운 화면을 만들수록 한글소리가 흐트러지는 것이 아니라 오히려 한글소리다워집니다.**

그리고 저는 이 앱의 브랜드 방향에서 **“화려한 단청색을 많이 쓰는 한국어 앱”보다는 “한옥의 질서와 여백 안에서 한국어가 아름답게 읽히고, 필요한 순간에만 단청이 피어나는 앱”** 쪽을 강하게 추천합니다.

그 방향이 더 오래가고, 한국 문화라는 소재를 superficial decoration으로 소비하지 않으며, 영어·독일어권 사용자가 보아도 성숙한 educational product로 느낄 가능성이 높습니다.

Apple이 현재 UI 지침에서 강조하는 일관된 interaction, 충분한 target size, 적응 가능한 layout, readability, alignment, visual hierarchy와도 이 방향은 잘 맞습니다. citeturn0search0turn0search2turn0search7

### 한글소리 Design Bible의 최종 목차도 처음부터 고정하는 것이 좋다

실제 프로젝트 문서로 만든다면 저는 한 파일에 모든 것을 몰아넣기보다 아래 구조를 권합니다.

```text
docs/design-system/

00_HANGUL_SORI_DESIGN_PRINCIPLES.md
01_FOUNDATIONS.md
02_COLOR_SYSTEM.md
03_TYPOGRAPHY.md
04_SPACING_GRID_RESPONSIVE.md
05_COMPONENTS.md
06_LEARNING_PATTERNS.md
07_PAGE_TEMPLATES.md
08_HANOK_DANCHEONG_BRAND.md
09_SVG_ASSET_GUIDE.md
10_LOCALIZATION_KO_EN_DE.md
11_ACCESSIBILITY.md
12_MOTION.md
13_TABLET_WEB.md
14_SCREEN_SPECIFICATIONS.md
15_DESIGN_QA_CHECKLIST.md
16_GOLDEN_TEST_MATRIX.md
```

그리고 문서마다 단순 설명이 아니라 반드시:

```text
Purpose
Do
Don't
Tokens
States
Responsive behavior
KO example
EN example
DE example
Accessibility
Code mapping
Visual example
```

을 넣습니다.

이 정도까지 가야 **“디자인 문서”가 아니라 실제 개발을 통제하는 UI/UX 바이블**이 됩니다.

## 조사 한계와 현재 확정하지 않은 부분

이번 조사에서는 연결된 GitHub를 통해 리포지토리 루트, `lib`, `lib/screens`, `docs` 및 recursive tree를 조사하고 deep-research/Screenshot 계열 파일을 탐색했지만, 최종 분석 단계 전에 **개별 소스 전체 body와 Screenshot 이미지들을 전수 렌더링해 화면별로 코드와 픽셀을 대응시키는 작업은 완료되지 않았습니다.** 따라서 위 보고서에서는 보지 못한 화면을 보았다고 가정하거나, 확인하지 않은 코드 값을 실제 값인 것처럼 기술하지 않았습니다.

또한 2026년 8월 20일 기준 플랫폼 자료 중 이번 실행에서 직접 검증 완료된 최신 공식 자료는 Apple HIG의 Layout, Typography, Accessibility, UI Design guidance입니다. Apple의 현재 문서는 iPhone/iPad 환경 변화에 대한 adaptive layout, visual hierarchy, progressive disclosure, Dynamic Type, 기본적인 44×44pt control 크기 등을 계속 강조하고 있으며, Layout 문서의 change log에는 2025년 Liquid Glass 및 iPhone 17 계열 업데이트까지 반영되어 있습니다. citeturn0search0turn0search1turn0search2

반면 **Android Material 최신 adaptive guidance, Flutter 최신 공식 adaptive API, WCAG 원문, Noto/Pretendard/SUIT의 2026년 현재 공식 라이선스, Duolingo·Babbel·Busuu·LingoDeer 등 경쟁 언어학습 앱의 2026년 현재 버전별 UI를 이번 실행에서 같은 수준으로 교차검증하지 못했습니다.** 그러므로 해당 내용을 최신 공식 사실처럼 꾸며 넣지 않고, 숫자가 필요한 부분은 “한글소리 내부 추천 규격”으로 명확히 구분했습니다.

가장 중요한 미완료 항목은 **한글소리 실제 Screenshot_ 전체에 대한 screen-by-screen redline과 실제 source code별 design-token violation inventory**입니다. 이 두 가지가 추가되면 지금 제시한 바이블은 일반적인 권장안에서 끝나는 것이 아니라, `현재 코드 값 → 위반 규칙 → 교체 컴포넌트 → 목표 화면`까지 연결된 migration specification으로 발전할 수 있습니다.