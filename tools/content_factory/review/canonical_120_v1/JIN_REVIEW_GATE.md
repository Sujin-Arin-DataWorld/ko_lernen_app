# Jin 정본 시나리오 승인·승격 영수증

## 현재 판정

- `canonical_120_v1`은 A1~C2에 정확히 20개씩, 총 120개다.
- 전체 후보 SHA-256은 `63dc5ea8743ec7f95fed04c5efb2a32dd2445c310444e87237414c0ced980060`다.
- 여섯 레벨 모두 Jin의 20개 전수 승인과 런타임 쓰기 승인을 해시로 기록했다.
- A1 → A2 → B1 → B2 → C1 → C2 순서로 승격했으며 런타임에는 정본 120개만 있다.
- 자동 편집 감사는 120개 모두 오류 0개, 경고 0개다.
- 무료 Gemini Flash 감사는 120개 모두 `pass`, 발견 사항 0개, 추정 실제 비용 USD 0이다.
- 한국어 대사에서 만든 TTS 요구 키는 레벨 합계 843개, 중복 제거 837개다. 로컬 캐시와 Firebase Storage 모두 정확한 837개가 준비됐고 누락은 0개다.
- 앱 배포 성공 여부는 이 콘텐츠 영수증과 별개다. 반드시 병합된 정확한 SHA의 CI 빌드와 배포 job을 확인한다.

## 레벨별 승인·승격

| 순서 | 레벨 | 장면 | TTS 키 | 레벨 후보 해시 | 승인 | 승격 |
|---:|---|---:|---:|---|---|---|
| 1 | A1 | 20 | 141 | `613b709038ab252ce3b9bfaee2389ed3590d732a5d9fd46da1e8649a89fc78f1` | Jin | 완료 |
| 2 | A2 | 20 | 147 | `352cd4cc99148c1abd89a18ec2a72bc786e916a769fd50ab79777b3c1d32959e` | Jin | 완료 |
| 3 | B1 | 20 | 136 | `f6a89b9f82f7cdeffd05d2e24d2b8a1b60b42fa16e9c0b7326dbd492ca0f67aa` | Jin | 완료 |
| 4 | B2 | 20 | 134 | `2dc248eb95b2b3592490edf3e7149f39ae4974bfc97c84cbcee0fec9383e1e20` | Jin | 완료 |
| 5 | C1 | 20 | 140 | `48bc01a55b77a8e37cd11c0b2b5ca83ea62995589239534b9631879cefff44b1` | Jin | 완료 |
| 6 | C2 | 20 | 145 | `837ed51cba82413a575fea9c37b74730753ebcb4281321d5b53656f1872a3e25` | Jin | 완료 |

권위 승인 원장은 `tools/content_factory/canonical_scenarios/approvals.json`이다. 각 행에는 승인 시각, 승격 시각, Jin의 런타임 쓰기 승인, 편집 감사·Gemini 감사·TTS 준비 영수증 해시가 들어 있다.

## 런타임 계약

- `assets/data/scenarios_a1.json`~`scenarios_c2.json`: 레벨당 20개
- `assets/data/curriculum_manifest.json`: `scenarioCorpusGeneration`이 `canonical_120_v1`
- 48개 코스 단원, 120개 시나리오 링크, 48개 체크포인트, 360개 시나리오 퀘스트
- 각 시나리오의 마지막 직접 산출 퀘스트만 해당 단원 개념 증거를 기록하며, 인식형 퀘스트는 숙달을 과대 판정하지 않는다.
- 기존 419개용 시나리오 ID는 역사적 초안·승인 계보에만 남고 런타임 샤드로 다시 합쳐지지 않는다.
- `dialog[].speaker == "user"` 계약은 유지하고, 화면과 TTS는 캐릭터 프로필의 플레이어 이름·음성을 사용한다.

## TTS 일치 증거

- 전체 요구 manifest: `tts_pending_manifest.json`
- 전체 Storage 영수증: `tts_ready.json`
- 첫 대사 프리페치 manifest: `assets/data/tts_first_line_manifest.json`
- 전체 고유 키: 837개
- 로컬 캐시 MP3: 837개, 예상 경로·크기·MD5 전부 일치
- Firebase Storage: 예상 837개 전부 존재, `missingCount: 0`
- 현재 대사와 키가 같으므로 재합성이나 재업로드는 하지 않는다.

## 감사 자료 해석

- `editorial_audit.json`과 `gemini_audit/summary.json`은 현재 전체 후보 해시에 결합된 감사 영수증이다.
- 각 후보 JSON의 `materialization_pending_external_audit` 표시는 생성 단계의 원본 상태다. 이후의 외부 Gemini 감사와 Jin 승인은 별도 불변 영수증으로 보존한다.
- `corpus_preflight.json`의 `runtimeWritten: false`, `releaseReady: false`는 승인 전 사전 검사 시점의 스냅샷이다. 현재 상태의 권위는 승인 원장과 런타임 샤드다.
- 자동 감사 통과는 Jin 승인이나 앱 배포 성공을 대신하지 않는다.

## 재검증 명령

```powershell
python -X utf8 -m unittest discover -s tools/content_factory -p "test_*.py"
python -X utf8 tools/content_factory/validate_content.py --json
python -X utf8 tools/content_factory/audit_canonical_scenarios.py --json-output tools/content_factory/review/canonical_120_v1/editorial_audit.json --markdown-output tools/content_factory/review/canonical_120_v1/editorial_audit.md
python -X utf8 tool/generate_tts.py --verify-storage --scenario-pending-manifest tools/content_factory/review/canonical_120_v1/tts_pending_manifest.json --verification-output tools/content_factory/review/canonical_120_v1/tts_ready.json
flutter analyze
flutter test --reporter compact --concurrency=1
git diff --check
```
