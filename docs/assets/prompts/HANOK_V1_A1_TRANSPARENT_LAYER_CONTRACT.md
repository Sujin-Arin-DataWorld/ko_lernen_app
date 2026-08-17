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

자동 거절 조건:

- RGB/불투명 매트/체크무늬/크로마
- socket 밖 source 픽셀 변경
- 이전 레이어 footprint recall < 0.97 또는 edge drift > 2px
- 최종 WebP > 350,000 bytes

## 승격

16개 QA WebP가 모두 통과하기 전에는 runtime/pubspec에 넣지 않는다.

```bash
python tool/promote_hanok_a1_states.py
```

`--apply`는 16개가 모두 있을 때만 복사한다.
