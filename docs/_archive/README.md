# docs/_archive — 이미지 생성 레거시 문서 (보관용, 삭제 X)

> 정리일: 2026-06-02. 이 폴더의 문서는 **더 이상 기준이 아니다.** 흩어진 프롬프트/레지스트리를
> 아래 "현행 최종 문서"로 통합한 뒤 보관 이동한 것. 히스토리/추적용으로만 둠.
>
> **신규 이미지 작업은 절대 이 폴더를 보지 말 것.** 현행 문서만 사용.

## 현행 최종 문서 (이것만 보면 됨)

| 역할 | 파일 |
|---|---|
| **HOW** — 스타일·팔레트·마스코트·한옥·도장·스티커 생성 프롬프트 (단일 소스) | `docs/ASSET_GENERATION_BIBLE.md` |
| **WHAT** — 무엇을 만들지 + 우선순위(P1~P4) + 다크모드 폐지 | `docs/IMAGES_TO_CREATE.md` |
| **WHERE** — 어떤 PNG가 어느 코드 슬롯에 들어가는지 | `docs/assets/REGISTRY.md` |
| 부록 — 낱장 95장 개별 정확 프롬프트 (BIBLE의 상세 부록) | `docs/plans/stately-rising-jongga-assets.md` |
| (코드용) 디자인 토큰 — spacing/radius/motion/SoriColors | `docs/HANGUL_SORI_DESIGN_TOKENS.md` |

## 아카이브된 파일 → 대체

| 아카이브 파일 | 왜 보관 | 대체 |
|---|---|---|
| `HANGUL_SORI_STYLE_GUIDE.md` | 스타일 가이드 원본 | **BIBLE §1에 완전 흡수** |
| `mascot_pose_sheet_v2.md` | 마스코트 포즈 요약본 | **BIBLE §2에 완전 흡수·확장** |
| `REGISTRY.md` (구, 5/29) | 구 에셋 레지스트리 | `docs/assets/REGISTRY.md` (신, 297줄) |
| `asset_prompts_day2-5.md` | Day2~5 프롬프트. Day4 마스코트는 자체적으로 legacy 선언됨 | 마스코트→BIBLE §2 / 빈상태·헤더·feature graphic→BIBLE 템플릿 + 부록 |
| `backdrop_prompts_day1.md` | 시나리오 백드롭 5장 프롬프트 | 이미 제작 완료(`assets/illustrations/scenes/`) |
| `gate_decomposition_prompt.md` | 솟을대문 분해 프롬프트 | 이미 제작 완료(gate 세트) |
| `generated_prompts_for_missing_assets.md` | 옛 누락 자산 프롬프트 | 대부분 제작됨 / 잔여는 `IMAGES_TO_CREATE.md` |
| `living-hanok-assets.md` | gate 자산 명세 | `docs/assets/REGISTRY.md` |
| `brand.md` (5/20) | 브랜드 가이드 v1 | BIBLE §1 (팔레트·도상) |

> 충돌 해소 메모: `asset_prompts_day2-5.md`의 마스코트 프레이밍("FULL-BODY 앉은 + 턱괴기")은
> BIBLE §2(upper-body 기준 + 턱괴기 금지)와 상충했으나, 해당 파일이 스스로 Day4를 legacy로
> 선언했고 BIBLE이 최종이므로 **BIBLE §2가 유효**하다.
