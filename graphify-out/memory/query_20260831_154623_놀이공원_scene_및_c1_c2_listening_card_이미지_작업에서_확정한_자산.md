---
type: "query"
date: "2026-08-31T15:46:23.016539+00:00"
question: "놀이공원 scene 및 C1/C2 listening card 이미지 작업에서 확정한 자산 경로, 스타일 정본, 출력 형식은 무엇인가?"
contributor: "graphify"
outcome: "useful"
source_nodes: ["ThemeParkDateBuildTest", "theme_park_date_records.py", "build_theme_park_date_smalltalk.py", "C1"]
---

# Q: 놀이공원 scene 및 C1/C2 listening card 이미지 작업에서 확정한 자산 경로, 스타일 정본, 출력 형식은 무엇인가?

## Answer

Theme Park Date 콘텐츠는 theme_park backdrop 키를 사용하며 최종 scene 자산은 assets/illustrations/scenes/theme_park.png, 1086x1448 세로 3:4 PNG이다. scene은 기존 market.png의 따뜻한 painterly Korean picture-book 스타일을 1차 기준으로 하고 Everland 사진은 활기와 구성 참고만 사용한다. bank.png와 salon.png는 같은 scene 스타일로 교체 대상이다. Chaekgado listening 카드는 scene과 다른 F-E-cards 계열이며 docs/LISTENING_CARD_RECIPE.md와 docs/assets/STYLE_LOCK.json이 정본이다. 800x600 가로 4:3 WebP로 납품하며 PNG 생성본은 확장자만 바꾸지 말고 변환한다. C1Conflict는 의견충돌이 아니라 이해충돌과 회피이며, 기존 C1 PNG 8장은 assets/illustrations/packs에 있으나 아직 런타임이 기대하는 assets/illustrations/listening/<key>.webp 형식과 경로로 승격되지 않았다. C1 누락 대상은 11개이며 현재 PNG는 C1Access, C1Attribution, C1Conflict, C1Consent, C1Critique, C1Facework, C1InvisibleLabor, C1Mediation 8개다. C1Methodology, C1Policy, C1Uncertainty는 아직 생성되지 않았다. C2 대상 12개도 아직 필요하다.

## Outcome

- Signal: useful

## Source Nodes

- ThemeParkDateBuildTest
- theme_park_date_records.py
- build_theme_park_date_smalltalk.py
- C1