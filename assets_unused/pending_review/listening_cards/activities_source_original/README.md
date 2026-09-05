# activities 원본 아카이브 — 미승격

`assets/illustrations/activities/` 로 올라갈 후보의 **원본**을 보관한다.
런타임 자산이 아니다. 이 디렉터리의 파일은 앱에 번들되지 않는다.

## 왜 여기 있나

두 파일 모두 `assets/illustrations/` 밑 런타임 디렉터리에 직접 놓여 있었는데,
F-E-cards 가족의 시각 계약을 통과하지 못해 정본으로 승격할 수 없었다.
2026-09-05 측정(`tool/check_card_style.py`):

| 파일 | 결과 |
|---|---|
| `scenarios_source_1448x1086.png` | `fileKB 111.8 > 111`, `ivory patch g mean 226.7` 밴드 밖 |
| `Lernaktivität.png` | `ivoryFrac 0.004 < 0.352`, 상단에 평탄한 아이보리 패치 없음 |

`ivoryFrac` 이 0.004 라는 것은 아이보리 지면이 사실상 없는 풀블리드 일러스트라는
뜻이다. 800×600 리사이즈·그레인·WebP q84 를 정상 적용해도 통과하지 못한다 —
후처리가 아니라 아트 생성 규격의 문제다.

`scenarios.webp` 정본은 `origin/main` 판(91KB WebP 800×600)으로 되돌렸다.
위 PNG 는 확장자만 `.webp` 였던 미가공 원본이라 이름을 실제 형식에 맞췄다.

## 승격하려면

`docs/LISTENING_CARD_RECIPE.md` 의 아이보리 지면 규격으로 아트를 다시 만든 뒤
`scripts/finish_listening_card.sh` 로 후처리한다. 게이트를 통과하면 `--register`
가 자동으로 명부(`docs/assets/CARD_STYLE_BASELINE.json` + `STYLE_LOCK.json`
members)를 갱신한다.

**밴드는 승인된 실측이다 — 통과시키려고 넓히지 말 것.** 재생성해도 계속
실패하면 Jin 에게 묻는다.
