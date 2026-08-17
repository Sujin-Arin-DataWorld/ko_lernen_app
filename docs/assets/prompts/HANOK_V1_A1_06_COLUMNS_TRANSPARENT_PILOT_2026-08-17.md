# Hanok V1 A1-06 transparent-layer pilot — 2026-08-17

## 권리·입력 경계

- 입력은 SHA-고정된 프로젝트 소유 `sarangchae.png` 한 장뿐이다.
- 사용자 첨부 화면, Vivasam, PDF, legacy 개인 한옥, Gye 자산은 입력하지 않았다.
- 전체 대지를 생성 결과로 받지 않고 기단·목재·기둥만 있는 true-alpha layer를 요구했다.

## BBANANA 입력 오류

- task: `30t7edpv5xrmw0d01kf857sf78`
- model: Nano Banana Pro, 2K, 21:9
- prompt SHA-256: `f17626ccd68333e75b55b305e460a793b4f12bbf17980d0676e878c08fc7cd5f`
- created: `2026-08-16T23:18:48.407844Z`
- 결과: reference URL을 잘못 재구성해 provider 입력 검증 400, 생성 결과 0개
- 비용: 4 credits가 즉시 표시됐다가 전액 환불되어 순비용 0, 잔액 922.8
- 정책: 오류 task는 재시도하지 않았다.

## 승인된 ImageGen 결과

- generation: `exec-b6be1b33-42fa-4b1c-a419-510d60bd478e`
- prompt SHA-256: `a513d095686107364beb6b4e5f3de3ac21c7ae0585a2e58f22316b0517aff1a2`
- generated: `2026-08-16T23:20:25Z`
- raw: 2172×724 RGBA PNG, true alpha, transparent corners
- visual gate: 기단·초석·준비 목재·세운 기둥이 보이고 보·창방·도리·서까래·지붕·벽·창호는 없음

`tool/compose_hanok_a1_state.py`가 alpha-threshold bbox를 비율 유지 축소하고 854×309
투명 canvas의 bottom-center anchor에 정렬했다. 정규화 레이어는 alpha coverage
32.0085%, anchor pixels 905, chroma 0이다. SHA-고정 base와 합성한 1536×1152 RGB
WebP는 276,120 bytes, source socket 밖 변경 0 pixels, 최종 decode의 socket 밖 최대
채널 평균 오차 3.39195로 모든 자동 gate를 통과했다.

원본 생성 파일은 기본 생성 폴더에 그대로 두고, 복사본·정규화 레이어·QA 합성본만
`assets_unused/pending_review/`에 보존했다. 아직 runtime asset이나 `pubspec.yaml`에는
추가하지 않았다.
