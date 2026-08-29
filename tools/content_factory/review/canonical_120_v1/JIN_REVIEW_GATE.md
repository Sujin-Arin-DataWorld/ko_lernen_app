# Jin 정본 시나리오 승인 게이트

## 현재 판정

- 검토 대상은 `canonical_120_v1`의 정본 후보 120개이며, A1~C2에 정확히 20개씩 있다.
- 후보 세트 SHA-256은 `b9ad5b453226cb8717d769f591117e75fc035cc3bad6a65872b3c4a138bc1b5f`다.
- 자동 편집 감사는 오류 0개, 경고 0개다. 이 결과는 구조적 사전 검사일 뿐 Jin의 언어 승인으로 간주하지 않는다.
- 현재 여섯 레벨 모두 `pending`이고 검토 수는 0개다.
- 런타임의 기존 413개 시나리오 샤드는 변경하지 않았다.
- 새 한국어 문자열은 전체 중복 제거 후 837개다. 2026-08-27 Jin의 요청으로 원격에 없던 825개를 `GOOGLE_TTS_API_KEY_2`로 합성·업로드했고, 기존 12개를 포함해 Storage 누락 0을 확인했다.
- 따라서 현재 `runtimeWritten: false`, `releaseReady: false`다.

## 검토 순서

각 문서의 20개 장면을 모두 읽고 장면별 체크박스를 확인한다. 한 레벨 안에서 일부만 읽은 상태로 승인하지 않는다.

| 순서 | 레벨 | 장면 | TTS 대기 | 후보 해시 | 검토 문서 |
|---:|---|---:|---:|---|---|
| 1 | A1 | 20 | 141 | `51d156bd4aec77bbf88b85b5419fa73bc9b226f637b4facb03f15ec615a455cb` | [a1_review.md](a1_review.md) |
| 2 | A2 | 20 | 147 | `b2809c1715bffd2bb41d0da908e471ae91dc670b2a53ba6254bacb03644f5dcb` | [a2_review.md](a2_review.md) |
| 3 | B1 | 20 | 136 | `9e40fa76f441ec6bc7a383b15d166c52231fa74b624537dbd7182f1a50d9bdeb` | [b1_review.md](b1_review.md) |
| 4 | B2 | 20 | 134 | `45e1db31558c828d1258493f7d156cff264cef6beb8bc007b0f0dbcc8ae7c247` | [b2_review.md](b2_review.md) |
| 5 | C1 | 20 | 140 | `cbe3df01dfc7b9ad2c03e5c824530da8adacc51d385dc01a8cfb1d07bc816a66` | [c1_review.md](c1_review.md) |
| 6 | C2 | 20 | 145 | `f385d13b738454df5149e7619b5f6a21690cba2991a97985347f4236508e6091` | [c2_review.md](c2_review.md) |

보조 자료:

- [editorial_audit.md](editorial_audit.md): 자동 자연성·레벨·화용·독일어 호칭 감사
- [regression_review.md](regression_review.md): 같은 두 테마를 A1~C2로 비교하는 비출시 회귀 세트
- [corpus_preflight.json](corpus_preflight.json): 120개, 48개 단원, 링크·퀘스트·wire ID 사전 검증
- [tts_pending_manifest.json](tts_pending_manifest.json): 전체 TTS 요구 키의 정확한 작업 범위
- [tts_ready.json](tts_ready.json): 후보·manifest 해시와 결합된 전체 837개 Storage 누락 0 영수증
- `a1_tts_pending.json`~`c2_tts_pending.json`: 레벨별 합성·Storage 검증의 정확한 범위
- `a1_tts_ready.json`~`c2_tts_ready.json`: 각 레벨의 후보·manifest 해시에 결합된 누락 0 영수증

## 장면별 승인 기준

각 장면에서 다음을 모두 확인한다.

1. 한국어 장면에 실제 사건, 각 화자의 목적, 관계와 자연스러운 말차례가 있는가.
2. 서로 이미 아는 사실을 학습자에게 설명하기 위한 대사가 없는가.
3. 해당 레벨의 내용 범위와 인지 과제에 맞는가. 문장 길이만으로 레벨을 판단하지 않는다.
4. 독일어와 영어가 한국어의 화행, 관계, 양태와 선택권을 보존하면서 각 언어에서 자연스러운가.
5. 어휘·문법·퀘스트가 실제 대사에서 추출됐고, 원문에 없는 학습 목표를 발명하지 않았는가.
6. 문화 노트가 실제 화용 차이가 있을 때만 존재하며 집단 일반화를 하지 않는가.

수정이 필요하면 검토 문서의 `Jin 메모:` 아래에 장면 ID와 원하는 표현을 적고 승인 명령을 실행하지 않는다. 후보를 수정한 뒤 전체 후보 해시와 해당 레벨 해시를 다시 생성해야 한다.

## 명시적 승인 기록

Jin이 해당 레벨 20개를 모두 읽고 승인한다고 명시한 뒤에만 아래 명령을 레벨별로 실행한다. 이 명령은 승인 기록을 남길 뿐 런타임을 쓰지 않는다.

```powershell
python -X utf8 tools/content_factory/manage_scenario_corpus.py approve-level a1 --reviewer Jin
```

이 명령의 기본 출력 대상은 권위 원장인 `tools/content_factory/canonical_scenarios/approvals.json`이다. 별도 `--output` 경로를 주면 권위 원장이 갱신되지 않으므로 승인 기록용으로 사용하지 않는다. 이후 A2, B1, B2, C1, C2도 같은 순서로 실행한다. 후보가 한 글자라도 바뀌면 기존 승인 해시와 달라져 승격이 거부되어야 한다.

## TTS 준비와 런타임 쓰기

승인된 레벨의 TTS는 해당 레벨 manifest를 정확한 작업 범위로 사용한다. 아래 dry-run은 인증·합성·업로드·로컬 파일 쓰기를 하지 않는다.

```powershell
python -X utf8 tool/generate_tts.py --dry-run --scenario-pending-manifest tools/content_factory/review/canonical_120_v1/a1_tts_pending.json
```

2026-08-27 Jin이 비용 호출과 Firebase 쓰기를 별도로 요청했다. 원격에 없던 825개(21,882자)를 합성해 `gs://ko-lernen-app.firebasestorage.app/tts/v3`에 업로드했으며, 전체 837개와 레벨별 요구 키의 `missingCount: 0` 영수증을 만들었다. 후보나 manifest가 바뀌면 현재 영수증은 폐기하고 다음 읽기 검증으로 새 영수증을 만든다.

```powershell
python -X utf8 tool/generate_tts.py --verify-storage --scenario-pending-manifest tools/content_factory/review/canonical_120_v1/a1_tts_pending.json --verification-output tools/content_factory/review/canonical_120_v1/a1_tts_ready.json
```

승격 dry-run은 런타임을 쓰지 않으며 승인 상태와 staged 콘텐츠를 검사한다.

```powershell
python -X utf8 tools/content_factory/manage_scenario_corpus.py promote-level a1 --tts-output tools/content_factory/review/canonical_120_v1/a1_tts_pending.json
```

실제 쓰기는 같은 레벨의 Jin 승인, `missingCount: 0`인 정확한 TTS 영수증, 별도의 Jin 쓰기 승인이 모두 있어야 한다.

```powershell
python -X utf8 tools/content_factory/manage_scenario_corpus.py promote-level a1 --tts-output tools/content_factory/review/canonical_120_v1/a1_tts_pending.json --tts-readiness tools/content_factory/review/canonical_120_v1/a1_tts_ready.json --runtime-write-reviewer Jin --write
```

## 승격·출시 금지선

- 각 레벨 20개 전체의 Jin 승인 전에는 그 레벨의 `promote-level --write`를 실행하지 않는다. 이전 레벨이 승격되지 않으면 다음 레벨 승격도 거부된다.
- 현재 후보 해시에서는 전체 837개 TTS 요구 키가 준비되어 있다. 후보나 음성 manifest가 바뀌면 새 누락 0 영수증 전에는 해당 레벨을 런타임에 쓰지 않는다.
- 자동 검사 통과, 승인 기록, 런타임 승격, TTS 준비, 앱 테스트는 서로 다른 증거다.
- 2026-08-27 유료 TTS 합성과 Firebase Storage 업로드를 완료했다. Gemini 정본 감사 도구와 비용 게이트도 추가했지만, `ko-lernen-app` Gemini 키는 선불 크레딧 소진으로 생성 요청이 `429 RESOURCE_EXHAUSTED`에서 중단됐다. 실패 요청은 후보를 수정하거나 승인하지 않았고, 런타임 승격과 앱 배포도 실행하지 않았다.
