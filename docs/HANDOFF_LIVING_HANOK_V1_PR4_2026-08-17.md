# 살아 있는 한옥 V1 PR4 — 코드 파이프라인 인수인계

작성: 2026-08-17
상태: 에셋 없는 코드 파이프라인. 이미지 생성은 Jin이 이어서 한다.

## Git

- base: PR3 `codex/hanok-v1-state-20260816` @ `64b7e24a`
- 작업 브랜치: `cursor/hanok-v1-pr4-pipeline-ef56`
- PR3 #32는 Play Internal 자동 업로드 결정 없이 병합하지 않는다.
- 로컬 Codex PR4 커밋(`67f3ce02` 이후)은 원격에 없었다. 이 브랜치는 그 계약을
  재구현하고, 끊긴 세션의 연속성 gate와 승격/썸네일 도구까지 닫았다.

## Jin이 할 일

1. 투명 RGBA 레이어만 만든다. 전체 대지 편집 금지.
2. `docs/assets/prompts/HANOK_V1_A1_TRANSPARENT_LAYER_CONTRACT.md`를 따른다.
3. raw는 `assets_unused/pending_review/a1_layers/raw/`에 둔다.
4. `tool/compose_hanok_a1_state.py`로 정규화·합성하고 `--previous-layer`로
   바로 이전 승인 레이어를 넣는다. **계보 검사는 기본으로 켜져 있다** — raw의 SHA가
   allowlist나 승인된 ledger 출력에 묶여 있어야 통과한다. 계약 밖 파일럿에서만
   `--no-require-lineage`로 끄고, 그렇게 만든 산출물은 승격 대상이 아니다.
   위로 쌓는 05–11에서 `--stack-on-previous`를 쓸 때는 `--stage <번호>`가 필수다
   (12–16은 거부된다).
5. 거절본은 `a1_layers/rejected/`에만 남긴다. runtime/pubspec에 복사하지 않는다.
6. 16개가 모두 QA를 통과한 뒤에만 `python tool/promote_hanok_a1_states.py --apply`.

## 이미 닫힌 코드

- QA composite는 `assets_unused/pending_review/reference_full_estate.png`만 읽는다.
- `A1HanokConstructionMap`는 `HanokExperienceProjection.a1ConstructionStep`만 본다.
- 디코드 창은 이전/현재/다음 최대 3장, 32MiB 이하.
- 누락 자산은 보상 권한을 바꾸지 않고 fail-visible fallback이다.
- production route에는 아직 연결하지 않았다.
