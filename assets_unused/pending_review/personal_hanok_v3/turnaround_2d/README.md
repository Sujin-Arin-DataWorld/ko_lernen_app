# 일두고택 사당 권역 8방향 2D 산출물

상태: `runtime_promoted_2026-08-29` (생성 근거·감사 원본은 이 pending-review 경로에 계속 보존)

2026-08-29에 일두고택 사당 권역의 세 대상을 28° 조감 시점, 45° 간격 8방향으로 제작했다.

- `ildu_sadang_v03`: 사당 본채 현재 검토본. 사용자 제공 실사와 방향별 고해상도 생성 반영
- `ildu_sadangmun_v02`: 태극문양이 있는 고유 사당문 현재 검토본. 사용자 제공 실사 반영
- `ildu_sadang_hyeopmun_v01`: 승인된 공용 협문 형식을 따르는 사당협문

거절된 사당 V01/V02와 사당문 V01은 런타임·커밋 대상에서 제외했다. 현재 세트의
`references`에 대표 비교본과 원본 해시를 남겨 개정 계보는 유지한다.

## 출력 계약

- 개별 파일: 384×512, PNG, RGBA 실알파
- 시점: 수평선에서 아래로 28° 내려다보는 고정 직교/아이소메트릭 카메라
- 방위각: `000`, `045`, `090`, `135`, `180`, `225`, `270`, `315`
- 시트: 1536×1024, 4열×2행, RGBA
- 시트 순서: 위 행 `front`, `front_right`, `right`, `rear_right`; 아래 행 `rear`, `rear_left`, `left`, `front_left`
- 방향별 고해상도 생성 세트는 동일한 최종 형상 높이와 기준선으로 정규화하며, 접촉시트 생성 세트는 하나의 축척을 사용한다. 모든 형상에 투명 안전 여백을 둔다.

## 생성 및 근거 경계

- 사당 V03과 사당문 V02는 `references/source_*.png`, 사용자 제공 `imagegen_reference_user_*.png`, 방향 일관성용 접촉시트를 사용했다. 사당협문은 승인 스프라이트만 사용했다.
- `references/blueprint_evidence_*.jpg`는 구조·치수 확인과 출처 증거용이며 모델 입력으로 사용하지 않았다.
- 생성 서비스가 반환한 미리보기 배경 포함 RGB 원본은 `generated_source`에 감사용으로 보존했다.
- 사당 V03과 사당문 V02의 최종 원본은 `generated_source/individual/*_raw.png`에 방향별로 보존한다. 접촉시트 생성본은 일관성 기준용이다.
- `prepare_turnaround_assets.py`가 연결된 미리보기 배경을 제거하고 형상을 무클리핑으로 분리한 뒤, 384×512 RGBA 파일과 시트를 만든다.
- `qa_metrics.json`에는 원본·산출물 SHA-256, 알파 범위, 내용 경계, 복사 일치 여부가 기록된다.

## 재현 및 검증

PowerShell에서 이 폴더의 상위 저장소를 작업 디렉터리로 두고 실행한다.

```powershell
python -X utf8 assets_unused\pending_review\personal_hanok_v3\turnaround_2d\prepare_turnaround_assets.py
python -X utf8 assets_unused\pending_review\personal_hanok_v3\turnaround_2d\validate_turnaround_assets.py
```

검증기는 세 세트 각각에 대해 방향 파일 8개, 384×512, RGBA, 실제 투명 픽셀, 안전 여백, 서로 다른 해시, 녹색 배경 잔재 부재, 1536×1024 시트의 픽셀 단위 재조합 일치를 검사한다.

## 런타임 승격 기록

2026-08-29 사용자 승인에 따라 세 현재 검토본의 `transparent_views` 24장을
`assets/illustrations/personal_hanok_v3/turnarounds/`로 복사하고
`lib/data/ildu_turntable_catalog.dart`에 연결했다.

- 사당 V03 → `sadang`
- 사당문 V02 → `sadang-gate`
- 사당협문 V01 공용 부재 키트 → `hyeopmun-west`, `hyeopmun-east`

런타임 사본은 384×512 RGBA 원본 픽셀을 바꾸지 않는다. 이 폴더의 생성 원본,
사용자 실사, 도면 증거, 시트와 `qa_metrics.json`은 재현·감사용이며 앱 번들에서
직접 읽지 않는다. 자동 검증 결과와 런타임 테스트 결과는 사람의 실제 기기 배치
검수와 별개의 증거로 유지한다.
