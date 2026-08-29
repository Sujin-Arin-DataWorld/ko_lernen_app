# 창고 8방향 2.5D QA 보고서

검토일: 2026-08-29

상태: `runtime_promoted_2026-08-29`

## 결과

- 방향별 PNG 8장: PASS
- 45° 간격(0°~315°): PASS
- 카메라 계약 28° 조감: PASS (생성 지시·메타데이터 기준)
- 2048×1536 RGBA: PASS
- 실제 투명 알파와 투명 모서리: PASS
- 안전 여백과 공통 기준선: PASS
- 한 방향당 하나의 지배적 건물 실루엣: PASS
- 녹색 크로마 잔여 픽셀: 0, PASS
- 8개 출력 SHA-256 상이: PASS
- 4×2 투명 시트의 개별 프레임 역재구성: 픽셀 일치, PASS
- 기준 이미지 대비 불투명 건물 평균 RGB 채널 편차: 최대 14, 허용 기준 20 이내, PASS

색보정이나 전체 팔레트 변환은 적용하지 않았다. 불투명 건물 본체는 생성된 색을 유지했고, 체크무늬 제거 과정에서는 반투명 가장자리 픽셀만 가장 가까운 본체색으로 정리했다.

세부 수치와 모든 입력·출력 해시는 `qa_metrics.json`에 기록되어 있다.

## 도면 대조 및 육안 검토

- 0° 정면: 6칸 판문, 7개 기둥선, 전면 철물 유지.
- 45°·315°: 전면 개구부와 닫힌 측면의 결합이 방향에 맞음.
- 90°·270°: 양 측면에 새 문·창·손잡이가 없고, 장축 지붕 깊이가 서로 대응함.
- 135°·225°: 닫힌 후면과 닫힌 측면이 방향에 맞음.
- 180° 후면: 6칸 판벽이며 전면 철물이 반복되지 않음.
- 전체 방향: 단일 장방형 몸체, 긴 맞배지붕, 회흑색 기와, 풍화 목재, 황토색 띠, 석재 기단을 유지함.
- 잘림, 체크무늬 잔존, 배경 풍경, 사람, 소품, 문자 오염 없음.

## 실행 검증

```text
python -X utf8 build_turnaround.py
PASS build: 8 RGBA 2048x1536 frames, common baseline

python -X utf8 validate_turnaround.py
PASS all: 8 distinct RGBA frames, alpha margins, palette gate,
green-residue gate, and exact 4x2 sheet verified

flutter test test/ildu_world_manifest_test.dart test/ildu_turntable_catalog_test.dart
PASS: 승인 원본 바운드와 런타임 카탈로그 바운드 각각 일치

python -X utf8 tool/promote_ildu_changgo_turntable.py --apply
PASS: 승인 SHA-256 확인 후 8 RGBA 384x512 런타임 프레임 승격

python -X utf8 -m unittest tool.test_promote_ildu_changgo_turntable
1 passed, 0 failed

flutter analyze --no-fatal-warnings --no-fatal-infos
No issues found

flutter test
5234 passed / 14 skipped / 0 failed
```

변경 전 관련 기준선은 `15 passed / 0 failed`였다. 승격 뒤 같은 범위는 창고 화면 통합 테스트가 추가되어 `16 passed / 0 failed`였고, 전체 Flutter 테스트도 위와 같이 통과했다. 전체 Python 자산 테스트 167개 중 이번 창고 테스트는 통과했으나, Windows/Python 3.13에서 기존 임시 PNG 핸들 잠금 3건과 기존 절대경로 안전 판정 2건이 실패했다. 해당 파일은 이번 변경 범위 밖이며 Linux/Python 3.12 CI를 정식 판정으로 둔다.

## 승격 결과와 남은 경계

사용자의 명시적 승인에 따라 8장 전체를 `changgo` 런타임 턴테이블과 일두고택 화면에 연결했다. 매니페스트의 창고 회전 90°는 시작 프레임 2와 대응하며, 화면에서 45° 단위로 실제 PNG만 전환한다. Firebase 업로드와 앱스토어 배포는 이번 승격 범위에 포함하지 않는다.
