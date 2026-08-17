# A1 투명 socket 레이어 제작 계약

이 문서는 이미지를 생성하지 않는다. Jin이 로컬에서 레이어를 만들 때 compositor가
통과하는 입력만 고정한다.

## 출력

- 실제 알파가 있는 RGBA PNG. 흰 배경, 회색 체크무늬, `#00ff00` 매트 금지.
- 권장 캔버스 `2172×724` 또는 이미 정규화된 `854×309`.
- 대지, 하늘, 길, 담장, 식생, 사람, 동물, 텍스트, UI를 그리지 않는다.
- 이전 승인 단계의 기단·초석·부재 위치를 옮기거나 다시 그리지 않는다.
- 이번 공정 하나만 추가한다.

## 합성

```bash
python tool/compose_hanok_a1_state.py \
  assets_unused/pending_review/a1_layers/raw/<id>.png \
  assets_unused/pending_review/a1_states/<id>.webp \
  --normalized-layer assets_unused/pending_review/a1_layers/<id>_layer.png \
  --previous-layer assets_unused/pending_review/a1_layers/<previous>_layer.png
```

계보 검사(raw SHA가 allowlist나 승인된 ledger 출력에 묶여 있는지)는 **기본으로 켜져 있다**.
계약 밖 파일럿에서만 `--no-require-lineage`를 붙이고, 그 산출물은 승격하지 않는다.
위로 쌓는 공정 05–11에서 `--stack-on-previous`를 쓸 때는 `--stage <번호>`를 함께 준다.
안쪽을 채우는 12–16은 거부된다. stack 모드에서는 recall이 구성상 1.0이 되므로 연속성
수치는 증거가 아니고, 육안 QA가 판단 근거다.

자동 거절 조건:

- RGB/불투명 매트/체크무늬/크로마. 손실 WebP 근사 `#00ff00`
  (`max(|r|,|g-255|,|b|) <= 8`)도 거절한다. 단청 `#1F7A6B`는 통과.
- socket 밖 source 픽셀 변경
- local anchor: exclusive X와 바닥 `bbox.bottom == 309`
- 이전 레이어 footprint recall < 0.97 또는 edge drift > 2px
- 최종 WebP > 350,000 bytes

## 부품 키트 모드 (2026-08-17, `--kit-manifest`)

단계 그림을 모델에게 통째로 그리게 하지 않는다. allowlist 완성 사랑채
`sarangchae.png`가 유일한 기하 정본이며, `tool/derive_hanok_a1_kit.py`가 이를
측정해 `docs/assets/hanok_a1_kit/a1_kit_geometry.json`(기둥 8구간·밴드·초석 폴리곤·
처마선·기단 폴리곤·원근 k,d·propsZone·groundRow)과 30개 파생 부품(지붕·서까래끝·창방
밴드·기둥 8·칸 패널 7·하방·그림자·초석 8·기단)으로 **소켓의 모든 alpha 픽셀을 분할**한다.
파생 부품을 partOrder대로 다시 쌓으면 완성본과 픽셀 동일하다(테스트로 고정). 기둥 구간은
도구가 제안하고 `a1_kit_overrides.json`(Jin 확인값)이 확정한다.

```bash
python tool/derive_hanok_a1_kit.py            # geometry·parts.json·derived PNG 갱신
python tool/derive_hanok_a1_kit.py --check    # 커밋본과 재도출 비교(쓰기 없음)
python tool/compose_hanok_a1_state.py --kit-manifest docs/assets/hanok_a1_kit/stage_NN.json \
  assets_unused/pending_review/a1_kit/qa/NN.webp --normalized-layer .../NN_layer.png \
  [--previous-manifest stage_MM.json --previous-layer .../MM_layer.png]
```

kit 게이트(raw 모드 규칙을 대체): 레이어는 정확히 854×309(리사이즈 없음) ·
**anchor** = alpha bbox가 x=427을 포함하고 bottom ≥ groundRow(01·02=293, ≥03=307) ·
**포함** = 모든 픽셀 ⊆ dilate(완성 alpha,1) ∪ propsZone · **연속성** = 이전 manifest의
transient 부품을 뺀 구조 픽셀 recall == 1.0, drift ≤ 2 (이전 레이어는 이전 manifest의
재렌더와 바이트 동일해야 함) · **계보** = 파생 부품은 compose 때 재도출해 `parts.json`의
rgbaSha256과 대조, 생성 부품(`generated:<id>`)은 ledger approved(kind=part) 출력 SHA만.
chroma·소켓 밖 0·350KB·재디코드 게이트는 그대로. 보고서에 Pillow/libwebp 버전을 남긴다
(결정론 = 같은 manifest + 같은 인코더 빌드). 전역 그레인·그림자 후처리는 없다.

뒷줄 기둥·초석·창방은 `rear: true`로 원근 벡터 (−k·d·(x−427), −d), d=16, 명도 0.86 복제.
2026-08-17 기준 03·04·06·11·15가 파생 부품만으로(0 credit) 게이트를 통과했고 15는
`base ⊕ sarangchae.png`와 픽셀 동일하다. 07~10·12~14·소품은 생성 부품이 승인된 뒤 manifest에
추가한다.

## 승격

16개 QA WebP가 모두 통과하기 전에는 runtime/pubspec에 넣지 않는다.
dry-run과 `--apply` 모두 `generationLedger`에 파일 basename+sha256이
`decision=approved`로 16개 있어야 한다. 빈 ledger는 거절한다.

```bash
python tool/promote_hanok_a1_states.py
```

`--apply`는 16개가 모두 있고 ledger SHA가 일치할 때만 복사한다.
