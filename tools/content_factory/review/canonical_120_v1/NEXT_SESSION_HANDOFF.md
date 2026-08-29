# `canonical_120_v1` 다음 세션 인수인계

## 작업 위치와 보호선

- 작업 트리: `C:\dev\hangulsori\ko_lernen_app_worktrees\scenario-persona-repair`
- 브랜치: `session/scenario-persona-repair-2026-08-26`
- 이 문서 작성 시 작업 브랜치 기준 HEAD: `632e778619ce5a52e3ba6caefbd4b715a0bc12be`
- 이 문서 작성 시 `main`: `28d3290716d0967006b38fe5c152114770c900f0`
- 당시 분기: 작업 브랜치가 `main`보다 28개 뒤, 자체 커밋 0개 앞이다. 통합 직전에 반드시 다시 측정한다.
- 런타임 `assets/data/scenarios_a1.json`~`scenarios_c2.json`은 기존 413개이며 diff가 없다.
- 다른 세션이 만든 `graphify-out` 변경·캐시와 기존 revision/cloze 검토 파일을 삭제하거나 덮어쓰지 않는다.

## 완료된 구현

1. 콘텐츠·언어 프로필이 분리된 `LevelProfile`, `ScenarioBrief`, `ScenarioCorpusManifest`, `CharacterProfile` 스키마와 7인 캐릭터 바이블을 추가했다.
2. 한국어 장면 작성 → 실제 대사 기반 학습 요소 추출 → DE/EN 독립 현지화 → 의미·레벨 감사의 오프라인 프롬프트 파이프라인을 만들었다.
3. A1~C2 정본 후보를 레벨당 20개, 총 120개 작성했다. 회귀 세트는 두 테마 × 여섯 레벨, 총 12개다.
4. 48개 코스 ID, 48개 체크포인트, 120개 링크, 360개 퀘스트와 기존 공동 퀘스트 wire ID를 사전 조립·검증한다.
5. 런타임 `Scenario`에 플레이어·참여자 캐릭터 계약을 추가하고 화면 이름 `(나)` 표시와 캐릭터 프로필 기반 TTS 성별 해석을 구현했다.
6. 콘텐츠 세대 마이그레이션은 코스·시나리오 진행만 초기화하고 생산 증거를 보관해 기존 획득 보상·한옥을 계속 증명하도록 구현했다.
7. 자동 편집 감사는 120개 기준 오류 0, 경고 0이며 독일어 동일 화자 내 du/Sie 혼용은 0개다. 문화 노트는 런타임과 같은 다국어 `title`/`body` 형식을 검사한다.
8. 문법 추출기가 같은 레벨 항목이 없을 때 가장 가까운 하위 레벨보다 CSV의 첫 항목을 택하던 오류를 수정하고 회귀 테스트를 추가했다.
9. A1·A2의 내용·문장 난이도와 B1~C2의 화용·자연성을 수동 재검토해 빵집 줄, 카카오톡 QR 추가, 첨부파일, 택시 감속 요청, 촬영 허락, `내가 다 민망하다`, 퇴근 후 연락, 숨은 명소 장면 등을 다시 다듬었다.
10. 댄스 수업의 강사를 일반 직원과 분리하고 앱·작가 바이블의 이름·음성 계약을 함께 잠갔다.
11. TTS 도구가 레벨별 pending manifest를 정확한 작업 범위로 읽고, 원격 Storage의 누락 0을 증명하는 해시 결합 영수증을 만들 수 있게 했다. `promote-level --write`는 이 영수증과 Jin의 별도 쓰기 승인이 없으면 실패한다.
12. 마이그레이션 테스트에서 책장 노트와 사용자 단어 팩도 실제로 보존되는지 추가로 고정했다.
13. 2026-08-27 Jin의 후속 요청으로 `GOOGLE_TTS_API_KEY_2`를 실행 프로세스에만 주입해 원격 누락 825개를 합성·다운로드하고 Firebase Storage에 업로드했다.
14. Gemini 정본 감사 도구를 추가했다. 20개씩 6회 묶음, 구조화 JSON, `beyond-humanizer` 오류 코드, 장면 관계별 du/Sie, 토큰 선계산, `$2` 비용 게이트, 사용량 기록, 자동 승인 금지를 구현했다. 정확한 입력은 273,173토큰, 보수적 상한은 `$1.431082`였으나 `ko-lernen-app` Gemini 키의 선불 크레딧이 소진되어 생성은 `429 RESOURCE_EXHAUSTED`에서 중단됐다. 후보·승인·런타임은 바뀌지 않았다.

## 현재 잠긴 상태

| 게이트 | 현재 상태 |
|---|---|
| 후보 정합성 | 120개, 레벨당 20개, 후보 SHA `b9ad5b453226cb8717d769f591117e75fc035cc3bad6a65872b3c4a138bc1b5f` |
| 자동 편집 감사 | 오류 0, 경고 0. 승인 증거 아님 |
| Gemini 다국어·레벨 감사 | 도구·비용 견적 완료, 유료 생성은 선불 크레딧 소진으로 미실행 |
| Jin 승인 | A1~C2 모두 `pending`, 검토 수 0 |
| 런타임 승격 | 미실행, 기존 413개 유지 |
| TTS | 고유 한국어 문자열 837개 전부 Storage 준비, 전체·레벨별 exact 영수증 `missingCount: 0` |
| 출시 가능 | `false` |

TTS 준비는 끝났지만 Jin의 실제 전수 승인이 없으므로 이 상태에서 런타임 승격, 커밋·push·main 병합, 브랜치/워크트리 삭제까지 완료했다고 선언하면 안 된다.

## 현재 검증 증거

- 정본 파이프라인 집중 Python 테스트: 18개 통과, 실패 0.
- 전체 콘텐츠 검증기: `ok: true`, 이슈 0.
- TTS 계약 Python 테스트: 7개 통과, 실패 0.
- TTS 외부 증거: 신규 825개(21,882자, 12,644,352 bytes) 합성·업로드 성공, 기존 12개 포함 전체 837개 Storage 누락 0. 로컬 MP3 825개는 빈 파일 0, 비양수 재생 길이 0, 길이 범위 0.396~3.851초다.
- Gemini 감사 도구 테스트: 6개 통과, 실패 0. `countTokens` 6회는 생성 과금 없이 성공했고, 120개 입력 273,173토큰과 최대 예상 비용 `$1.431082`를 확인했다. 생성 결과 파일은 아직 없다.
- 관련 Flutter 집중 테스트: 109개 통과, 실패 0.
- 전체 Flutter 테스트: 4,689개 통과, 14개 건너뜀, 실패 0 (`--no-pub --reporter compact --concurrency=1`, 22분 1초).
- Flutter 정적 분석: 이슈 0.
- Dart 포맷 검사: 대상 17개 파일, 변경 0.
- 이번 작업 경로 대상 `git diff --check`: 공백 오류 0.
- 전체 Python 콘텐츠 팩토리: 263개 중 262개 통과, 아래의 기존 기준선 오류 1개. 같은 오류를 최신 `main`에서도 재현했다.

## 다음 세션 첫 검증

먼저 실제 저장소와 분기를 다시 확인한다.

```powershell
git rev-parse --show-toplevel
git branch --show-current
git status --short
git rev-list --left-right --count main...HEAD
```

후보와 검토 산출물을 재생성한다. 모두 오프라인이며 런타임을 쓰지 않는다.

```powershell
$levels = 'a1','a2','b1','b2','c1','c2'
foreach ($level in $levels) {
  python -X utf8 tools/content_factory/materialize_canonical_scenarios.py $level
  python -X utf8 tools/content_factory/materialize_canonical_scenarios.py $level --regression
  python -X utf8 tools/content_factory/manage_scenario_corpus.py render-review $level --output "tools/content_factory/review/canonical_120_v1/${level}_review.md"
  python -X utf8 tools/content_factory/manage_scenario_corpus.py preflight-level $level --output "tools/content_factory/review/canonical_120_v1/${level}_preflight.json"
}
python -X utf8 tools/content_factory/manage_scenario_corpus.py preflight-corpus --output tools/content_factory/review/canonical_120_v1/corpus_preflight.json
python -X utf8 tools/content_factory/manage_scenario_corpus.py preflight-regression --output tools/content_factory/review/canonical_120_v1/regression_preflight.json
python -X utf8 tools/content_factory/manage_scenario_corpus.py render-regression-review --output tools/content_factory/review/canonical_120_v1/regression_review.md
foreach ($level in $levels) {
  python -X utf8 tools/content_factory/manage_scenario_corpus.py tts-pending $level --output "tools/content_factory/review/canonical_120_v1/${level}_tts_pending.json"
}
python -X utf8 tools/content_factory/manage_scenario_corpus.py tts-pending-corpus --output tools/content_factory/review/canonical_120_v1/tts_pending_manifest.json
python -X utf8 tools/content_factory/audit_canonical_scenarios.py --json-output tools/content_factory/review/canonical_120_v1/editorial_audit.json --markdown-output tools/content_factory/review/canonical_120_v1/editorial_audit.md
```

기대값은 120개, 각 레벨 20개, 48개 단원, 120개 링크, 48개 체크포인트, 360개 퀘스트, 전체 고유 TTS 837개, 자동 감사 오류·경고 0개다.

## Jin 승인 이후에만 할 일

1. [JIN_REVIEW_GATE.md](JIN_REVIEW_GATE.md)의 순서로 레벨당 20개를 전부 검토한다.
2. Jin이 명시적으로 승인한 레벨만 `approve-level`로 기록한다.
3. 승인된 후보 해시가 변하지 않았음을 `preflight-level`로 다시 확인한다.
4. A1부터 순서대로 dry-run 승격을 실행하고 결과를 검토한다.
5. 현재 후보의 TTS 합성·업로드와 레벨별 누락 0 영수증은 완료됐다. 후보가 바뀌면 새 manifest 기준으로 누락분만 다시 준비한다.
6. 승인 직전 레벨별 ready 영수증의 후보·manifest 해시가 현재 파일과 일치하는지 다시 검사한다.
7. 같은 후보·TTS 해시의 영수증이 있고 Jin이 런타임 쓰기를 별도로 승인한 뒤에만 `promote-level --write`를 실행한다.

승격 명령 형식은 다음과 같다. `--write`를 뺀 실행은 dry-run이다.

```powershell
python -X utf8 tools/content_factory/manage_scenario_corpus.py promote-level a1 --tts-output tools/content_factory/review/canonical_120_v1/a1_tts_pending.json
```

TTS 준비는 완료됐다. 후보 변경 뒤 영수증을 재생성하거나 실제 런타임 쓰기를 승인받았을 때의 명령 형식은 다음과 같다.

```powershell
python -X utf8 tool/generate_tts.py --verify-storage --scenario-pending-manifest tools/content_factory/review/canonical_120_v1/a1_tts_pending.json --verification-output tools/content_factory/review/canonical_120_v1/a1_tts_ready.json
python -X utf8 tools/content_factory/manage_scenario_corpus.py promote-level a1 --tts-output tools/content_factory/review/canonical_120_v1/a1_tts_pending.json --tts-readiness tools/content_factory/review/canonical_120_v1/a1_tts_ready.json --runtime-write-reviewer Jin --write
```

## 최종 검증 순서

승격이 실제로 끝난 뒤 다음을 모두 다시 실행한다.

```powershell
python -X utf8 -m unittest discover -s tools/content_factory -p "test_scenario_corpus_pipeline.py" -v
python -X utf8 -m unittest discover -s tools/content_factory
python -X utf8 tools/content_factory/validate_content.py --json
python -X utf8 -m unittest -v tool/test_generate_tts.py
flutter analyze --no-fatal-warnings --no-fatal-infos
flutter test --reporter compact --concurrency=1
git diff --check
```

전체 Python 팩토리 스위트 263개 중 `vocab:vocab_a1_0351: stale promoted copy revision fields` 한 건이 실패한다. 같은 실패가 이 문서 작성 시 최신 `main` (`28d3290716d0967006b38fe5c152114770c900f0`)에서도 재현되어 이번 변경으로 생긴 회귀는 아니다. 통합 시점의 최신 `main`에서 다시 확인하고, 기준선이 고쳐졌다면 새 결과를 기록한다.

마이그레이션 테스트에서는 다음을 각각 증명한다.

- 초기화: 완료 단원, 일반 증거, 시나리오 체크포인트
- 보관: 기존 생산 증거 → `archivedProductiveEvidence`
- 유지: 계정, XP, 연속 학습, 단어 SRS, 노트, 구매, 획득 보상, 한옥 배치

## 통합과 정리

모든 Jin 승인, 현재 해시의 TTS 누락 0 재확인, 런타임 승격, 전체 검증이 끝난 뒤에만 다음 단계로 간다.

1. `main` 최신 상태와 작업 브랜치 분기를 다시 측정하고 최신 `main`을 손실 없이 통합한다.
2. 사용자와 다른 세션의 WIP를 제외하고 이번 작업 파일만 정확히 스테이징한다.
3. 커밋 후 원격 작업 브랜치에 push하고, `main`에 병합한 정확한 HEAD를 push한다.
4. 원격 `main`이 병합 커밋을 포함하는지 ancestry와 SHA로 검증한다.
5. CI가 정확한 `main` HEAD에서 성공했는지 확인한다.
6. 깨끗한 상태와 복구 가능한 원격 커밋을 확인한 뒤 이 작업 브랜치와 워크트리만 삭제한다.

워크트리 삭제 전에는 경로가 정확히 `C:\dev\hangulsori\ko_lernen_app_worktrees\scenario-persona-repair`인지 다시 확인한다. 다른 활성 워크트리나 `graphify-out` 소유 파일을 정리 대상으로 확대하지 않는다.
