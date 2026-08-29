# `canonical_120_v1` 현재 인수인계

## 현재 통합 상태

- 통합 작업트리: `C:\dev\hangulsori\ko_lernen_app_worktrees\scenario-main-integration-20260829`
- 통합 브랜치: `feat/canonical-120-scenarios-20260829`
- 기준 `origin/main`: `e9ab5ce4dd071b4e9e5c731b2655563dc6d1c95c`
- 기능 커밋: `f8da293303dca6a7538a447aef73bd9bb3015a40`
- 기존 더티 메인 체크아웃 `C:\dev\hangulsori\ko_lernen_app`은 건드리지 않는다.
- 리뷰 파이프라인·후보·검증 도구를 메인에 병합하는 것은 Jin이 승인했다. 후보의 런타임 승격은 별도의 Jin 전수 승인과 쓰기 승인 전까지 금지한다.

## 구현 결과

1. A1~C2 레벨당 20개, 총 120개의 한국어 원문 정본 후보와 DE/EN 독립 현지화를 만들었다.
2. 48개 기존 코스 ID와 공동 퀘스트 wire ID를 유지하면서 새 Can-do·체크포인트·링크를 사전 검증한다.
3. 한국어 장면 작성 → 학습 요소 추출 → DE/EN 현지화 → 의미·레벨 감사의 단계형 프롬프트 패킷을 만든다.
4. 7인 캐릭터 바이블, 플레이어·참여자 ID, 캐릭터 기반 TTS 성별, 현지화된 플레이어 이름 표기를 구현했다.
5. 코스·시나리오 진행만 새 세대로 초기화하고 생산 증거는 archive로 옮겨 XP·SRS·구매·획득 보상·한옥 증명을 보존한다.
6. 진행도 스키마를 v4로 올렸다. v1~v3은 v4로 이행하고, 구버전 앱은 v4를 미래 스키마로 거부하므로 새 보상 필드를 조용히 제거할 수 없다.
7. 후보 materializer는 의미 감사를 `pass`로 위조하지 않고 `pending`으로 만든다.
8. `approve-level`은 Jin이 읽은 정확한 레벨 해시와 현재 120개 전체 해시에 결합된 자동 편집·Gemini 감사 영수증을 요구한다.
9. TTS 도구는 manifest의 정확한 파일만 업로드하며 합성 실패가 하나라도 있으면 업로드 전에 중단한다. Storage 영수증은 최소 크기 이상의 객체만 준비 완료로 센다.

## 현재 잠긴 게이트

| 게이트 | 상태 |
|---|---|
| 후보 정합성 | 120개, 레벨당 20개 |
| 전체 후보 SHA | `8f9e37b4951fdc969b965ac8214d74baee874b579dab7c56918e6260a0e2614b` |
| 자동 편집 감사 | 오류 0, 경고 0. 승인 증거 아님 |
| 후보 의미 감사 | materializer 결과는 전부 `pending` |
| Gemini 감사 | 현재 해시에 결합된 성공 영수증 없음 |
| Jin 승인 | A1~C2 모두 `pending` |
| 런타임 승격 | 미실행, 기존 413개 유지 |
| TTS | 현재 837개 전부 Storage 준비, 전체·레벨별 `missingCount: 0` |
| 출시 가능 | `false` |

레벨별 현재 해시:

- A1 `e73b694986f25e19531d24167b42f5e8a10d3cc83072c88edb8b1bd94d06a173`
- A2 `c0fa2c357fdbecd43d938e62765dc31bd9faca10042e5d77c3db7d83bb8d3ddb`
- B1 `ca7bd231d9018cfa292ab0505f1faed6325d5f5b617e7ecc4c6b118455aec83a`
- B2 `fb9c2218306da513893f32676f26c12bffcce6017812c3528a885a54c41c3376`
- C1 `5c4f36fad55c2112c747d76947119be90e54746a6c75dcbbdf24b2e35449b084`
- C2 `0f0e8578ccd206a1fb77cf97f1cc032edcee576297489ac1b601631aea7fb50a`

## TTS 외부 쓰기 증거

- A1 빵집 줄의 잠긴 표현은 `아, 죄송합니다. 줄 서 계신지 몰랐어요.`다.
- 이 교체로 새로 필요해진 남성 음성 1개를 2026-08-29 로그인된 Google Cloud OAuth로 합성했다.
- 업로드 경로는 `tts/v3/male/38b61cfe152d5b9baa99c6443f2fd893e4f371c0.mp3`다.
- 객체 크기는 13,056 bytes이며, 전체 현재 manifest 837개와 A1~C2 레벨별 검증은 모두 누락 0이다.
- 기존 캐시 파일은 삭제하지 않았다.

## 승인과 승격

Jin이 A1 20개를 모두 읽고 승인한 뒤, 현재 해시의 Gemini 전체 감사 영수증이 있을 때만 다음 형식으로 승인한다.

```powershell
python -X utf8 tools/content_factory/manage_scenario_corpus.py approve-level a1 --reviewer Jin --candidate-set-sha256 e73b694986f25e19531d24167b42f5e8a10d3cc83072c88edb8b1bd94d06a173 --model-audit tools/content_factory/review/canonical_120_v1/gemini_audit/summary.json
```

승격 dry-run은 런타임을 쓰지 않는다.

```powershell
python -X utf8 tools/content_factory/manage_scenario_corpus.py promote-level a1 --tts-output tools/content_factory/review/canonical_120_v1/a1_tts_pending.json
```

실제 승격은 같은 후보 해시의 Jin 승인, TTS 누락 0 영수증, 별도 런타임 쓰기 승인 뒤에만 실행한다.

```powershell
python -X utf8 tools/content_factory/manage_scenario_corpus.py promote-level a1 --tts-output tools/content_factory/review/canonical_120_v1/a1_tts_pending.json --tts-readiness tools/content_factory/review/canonical_120_v1/a1_tts_ready.json --runtime-write-reviewer Jin --write
```

## 재검증 명령

```powershell
python -X utf8 -m unittest discover -s tools/content_factory -p "test_scenario_corpus_pipeline.py" -v
python -X utf8 -m unittest -v tool/test_generate_tts.py
python -X utf8 tools/content_factory/validate_content.py --json
python -X utf8 tools/content_factory/audit_canonical_scenarios.py --json-output tools/content_factory/review/canonical_120_v1/editorial_audit.json --markdown-output tools/content_factory/review/canonical_120_v1/editorial_audit.md
flutter analyze --no-fatal-warnings --no-fatal-infos
flutter test --reporter compact --concurrency=1
git diff --check
```

전체 Python 팩토리의 `vocab_a1_0351` stale promoted copy와 `ildu_world_manifest_v1.json` 분류 오류는 깨끗한 `origin/main`에서도 동일하게 재현된 기준선 문제다. 이번 변경과 분리해서 보고한다.
