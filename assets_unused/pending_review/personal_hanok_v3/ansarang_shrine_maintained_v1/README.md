# 안사랑채·사당문·사당 — 승인한 2.5D 정본의 생성 원본

사람이 돌보고 사용하는 한옥의 건전한 재료·입체 공간을 보여주는 고화질 원본 3종이다. 색상 필터나 저해상도 확대가 아니라 목재·기와·창호·단청·석재를 다시 그렸다. Jin이 2026-09-14 세 이미지를 승인했다. 같은 바이트를 각각 ../canonical/ansarangchae/, ../canonical/sadangmun/, ../canonical/sadang/에 복사하고 CANONICAL_LOCK.json 및 STYLE_LOCK.json에 등록했다. 이 폴더는 생성·알파 추출 근거이며, 완성 외관의 정본은 canonical/에 있다. 완성 PNG는 같은 바이트로 Flutter 건축 시리즈의 마지막 단계에 적용했다.

| 건물 | 투명 PNG | 실제 해상도 | 유지한 공간 특성 |
|---|---|---|---|
| 안사랑채 | [완성 시안](masters/ansarangchae_maintained_front_right.png) | 1536×1024 | 정면 4칸, 왼쪽 폐쇄 공간, 후퇴한 창호, 앞·옆 툇마루, 마루 아래 깊이 |
| 사당문 | [완성 시안](masters/sadangmun_maintained_front_right.png) | 1086×1448 | 얕은 단칸문, 문틀 두께, 양쪽 문짝과 태극, 낮은 돌받침 |
| 사당 | [완성 시안](masters/sadang_maintained_front_right.png) | 1536×1024 | 정면 3칸, 원기둥, 후퇴한 창호, 단청·공포, 맞배지붕과 측벽 |

## 시각 기준

- `stylized hand-painted 2.5D architectural sprite art`를 따르며 전면·측면·바닥 상면이 함께 읽혀야 한다.
- 돌봄과 보존 상태는 건전한 목재, 온전한 기와, 정돈된 한지·회벽, 선명한 창살과 단청으로 표현한다. 방치된 마모·이끼·벗겨진 칠·긁힘을 생활감으로 사용하지 않는다.
- 생활 공간·통과하는 문·제례 공간이라는 용도 차이를 유지한다. 사당에 온돌·침구를 더하거나 사당문을 큰 대문으로 확장하지 않는다.
- 정본 사랑채 `sarangchae/stage_16_complete.png`는 마감 품질만 참조했다. 그 건물의 평면·현판·계단을 복제하는 기준이 아니다.

## 투명도와 원본 보존

현재 런타임 안사랑채 8방향 가운데 01·03·05·07의 열린 공간에 남은 밝은 배경을 알파만 수정했다. `originals/ansarang_turnarounds/`는 수정 전 8장, `alpha_corrected/`는 수정 후 8장이다. 이 수정은 격리된 작업 폴더의 기존 8방향 런타임 PNG에 적용했다. 4장의 RGB 변경은 0픽셀이고 알파 변경은 총 2,425픽셀이다. 자세한 해시·영역은 [alpha_repair.json](alpha_repair.json)을 따른다.

새 고화질 시안은 `raw/` 생성 결과에서 분홍색 임시 배경에 연결된 영역만 알파로 제거했다. 태극의 적·청색 경계와 단청 색은 순수 분홍 배경과 구분해 보존한다. 추출 과정의 RGB 변경은 0픽셀이다. 안사랑채 오른쪽 빈 툇공간은 투명하며 양쪽 기둥과 바닥은 불투명한지 좌표 검사했다. 밝고 어두운 배경 합성본은 `qa/`에 있다.

생성 첫 안사랑채의 체크무늬는 실제 알파가 아니어서 `raw/ansarangchae-v1-checkerboard.png`를 완성 파일로 쓰지 않는다. 첫 사당문의 마모가 남은 결과도 `raw/sadangmun-v1-worn.png`에만 보관한다. 승인된 파일은 위 `masters/` 3개와 그 바이트가 같은 canonical/ 복사본이다.

## 파일 구성과 재현

- [MANIFEST.json](MANIFEST.json): 실제 치수, 바이트 수, SHA-256, 알파 통계, 생성 파일 및 프롬프트 연결.
- [generation_ledger.json](generation_ledger.json): 각 생성 입력과 역할·시안 선택 이유.
- `prompts/`: 각 재생성·수정 요청의 원문.
- `repair_alpha.py`: 기존 384×512 안사랑채의 지정된 빈 공간만 수정.
- `extract_master_alpha.py`: 승인 전 고화질 시안의 배경 알파 추출. 정본 잠금이 존재하면 재실행을 차단한다. 후속 수정은 별도 버전 경로에서 한다.

```powershell
python assets_unused/pending_review/personal_hanok_v3/ansarang_shrine_maintained_v1/repair_alpha.py
python tool/validate_ansarang_shrine_design.py --write-report
```

## 공정 그림으로 이어지는 조건

설계는 `docs/assets/ildu_ansarang_shrine_construction_20260914/`의 안사랑채 14·사당문 8·사당 12단계를 따른다. 정본은 건물마다 단일 시점 1장이다. 총 34단계(중간 원화 31장과 완성 정본 3장)를 Flutter 건축 상세 및 B2 최초 완료 화면에 연결했다. 실제 치수·해시·알파 검증은 공정 폴더의 ART_MANIFEST.json을 따른다. 8방향 고화질 세트는 이 단일 시점 공정과 별도다.

완성 시안의 시점과 기단·초석·기둥·처마 위치를 먼저 고정한 뒤 단계별 그림에 그대로 연결한다. 생성 과정에서 해석된 마루 아래 가새·지붕 속 부재·벽 두께는 도면과 단면을 대조한 뒤 학습 설명에 사용한다. 이 그림 자체를 실측 복원 증거로 사용하지 않는다. 학습 완료·진도 증가는 기존 단원 최초 완료 경로만 사용한다.
