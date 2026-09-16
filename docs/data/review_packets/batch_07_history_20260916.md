# Batch 07: 초안·검수표·라이브 이력 감사

상태: **이력 추적 완료 구간과 해석 불가 구간을 구분한 증거 / 승인·권리·언어 검수 완료 아님**.
출발 HEAD는 `f2275489379393e7a3655dc8180e0a8b317696bb`다.
현재 초안·검수표·라이브·승인 원장과 기존 승격 검증기의 허용 범위를 바꾸지 않았다.

## 확인된 사실

최초 승격 `83b3865868ec5314de6884cb1f03d79adf947558`에서는 다섯 종류의 **1,374행 모두 당시 초안과 라이브가 같다**.
현재 검수 스냅샷으로 보관된 초안은 그 뒤 **833행이 수정**됐다. 그러므로 현재 초안을 최초 승격 원본과 같은 것으로 취급하면 안 된다.

| 종류 | 행 수 | 승격 당시 초안↔라이브 차이 | 이후 바뀐 초안 | 현재 raw 초안↔라이브 차이 | 기존 검증기상 미해명 |
|---|---:|---:|---:|---:|---:|
| vocab | 432 | 0 | 245 | 322 | 166 |
| grammar | 6 | 0 | 3 | 4 | 4 |
| smalltalk | 72 | 0 | 72 | 72 | 72 |
| cloze | 432 | 0 | 244 | 432 | 174 |
| satz | 432 | 0 | 269 | 432 | 411 |
| 합계 | 1,374 | 0 | 833 | 1,262 | 827 |

raw 차이는 relevel·기존 copy revision 등을 적용하기 전의 행 전체 비교다. 미해명 827은 기존 production validator의 정규화·정확한 이력 예외를 적용한 뒤에도 설명되지 않는 차이다. 두 숫자의 분모와 의미를 섞지 않는다.

이 감사는 승인 근거를 새로 만든 것이 아니다. strict validator는 여전히 `vocab:vocab_a1_0213: promoted value differs from reviewed draft`에서 실패한다. 전체 역사 manifest 결과도 10/24 통과·14개 실패 상태다.

## 세 갈래 이력과 공백

`b5813937792cf7993ec85f231db4fdc67d57bc36`을 first-parent 합류점으로 삼아 초안·검수 CSV·라이브를 각각 추적했다. 정상적으로 해석된 스냅샷 사이의 행 전환은 초안 842건, 검수표 592건, 라이브 3,133건이다. 한 행이 여러 번 바뀌거나 되돌아간 것도 별도 전환이다. 이 수치는 변경 행 수나 승인 건수가 아니다.

각 전환의 commit은 선택한 통합 경로에서 값이 관찰된 시점이다. merge commit을 그 문구의 최초 저작 커밋으로 주장하지 않는다.

과거 CSV의 열 수·따옴표 문제가 있는 **11개 파일 스냅샷**은 정상 행으로 추정하지 않았다. 현재 파일이 손상됐다는 뜻은 아니다.

| 커밋 | 해석 불가 파일 스냅샷 |
|---|---|
| `c5d88db5` | vocab 초안, cloze 검수표, satz 검수표 |
| `4d1e4469` | vocab 초안, cloze 검수표, satz 검수표 |
| `49545be7` | vocab 초안, vocab 라이브, cloze 검수표, satz 검수표 |
| `a5d49645` | vocab 라이브 |

전체 결과는 각 공백의 commit·원본 blob SHA-256·파싱 오류를 `unparsedSnapshots`에 저장한다. 공백을 건너뛴 다음 정상 관찰에는 `unparsedInterval`을 붙인다. 해당 track의 `historyComplete`는 false이며, 전후 값이 같더라도 사이에 변화가 없었다고 단정하지 않는다. JSON 중복 키·비표준 수치도 정상 자료로 받아들이지 않는다.

## 재현

요약·파일 해시·관찰 커밋·공백 목록은 [증거 영수증](../../../tools/content_factory/review/batch_07_history_receipt_20260916.json)에 있다. 전체 6.4 MB 보고서는 영수증의 로컬 artifact 경로에 보관했으며 아래 명령으로 같은 Git 상태에서 재생성할 수 있다. 재현에는 해당 커밋들이 포함된 로컬 Git 이력이 필요하다.

```powershell
python -B tools/content_factory/audit_review_history.py `
  --manifest tools/content_factory/drafts/batch_07_partner_family_manifest.json `
  --promotion-manifest tools/content_factory/drafts/batch_07_manifest.json `
  --promotion 83b3865868ec5314de6884cb1f03d79adf947558 `
  --integration b5813937792cf7993ec85f231db4fdc67d57bc36 `
  --head f2275489379393e7a3655dc8180e0a8b317696bb `
  --output batch07-history.json
```

도구는 기존 출력 파일을 덮어쓰지 않는다. 현재 HEAD를 검사할 때 입력 파일의 미커밋 변경이 있으면 중단한다. 과거 HEAD를 명시하면 그 Git blob만 읽으므로 이후 작업이 과거 증거를 바꾸지 않는다. 파싱 공백이 표시된 보고서의 생성 성공을 이력 완전성이나 배치 승인으로 해석하지 않는다.

## 별도 문법 검토에서 확인한 다음 교정 대상

아래 네 Batch 07 문법 행과 연결된 기존 `-시-` 문항은 **MODEL_QA_FLAG**다. 이 감사 변경에서 라이브 교정이나 새 승인으로 처리하지 않았다.

- `grammar_a1_honorific_kke`: 장인어른을 일반적인 존경 대상으로 옮긴 번역은 배우자 쪽 관계를 잃는다. `my wife's father` / `dem Vater meiner Frau`로 관계를 되살리고 focus를 맞춰야 한다.
- `grammar_a2_humble_give`: 할머니를 일반적인 존경 대상으로 바꾼 번역, 행위자를 화자로만 한정한 설명, 연장자에게 주다를 쓰면 안 된다는 절대 규칙을 교정해야 한다. `따라 주다 → 따라 드리다`의 구체적 대비가 필요하다.
- `grammar_b1_honorific_subject_kkeyseo`: 시어머니를 일반적인 존경 대상으로 바꾼 번역을 고쳐야 한다. `께서`와 `grammar_b1_honorific_si`가 서로 오답으로 배치되어 높이는 주체라는 강조 구간과 겹친다. 두 방향의 선택지를 함께 고쳐야 한다. 현 레벨에서 `께서 → grammar_b1_after`, `-시- → grammar_b1_intention` 대체안을 재검증할 수 있다.
- `grammar_b2_rather_than_direct`: `-기보다`의 일반적인 행동 비교를 완곡한 답변으로만 정의한 범위를 고쳐야 한다. `바로 거절하기보다 “다음에 말씀드릴게요.”라고 했어요.`처럼 직접 인용을 구분하고, 말씀드리다에 없는 `explain/erklären`을 `tell you/Ihnen sagen`으로 맞추며 focus에 거절 동사를 포함하는 안을 검토했다.

이 문법 검토는 네 행과 연결된 12개 보기 위치에 한정된다. 전체 827행의 언어 품질, 사람 승인, CEFR 판정 완료가 아니다. 현재 승인·권리 태그가 있는 것과 이후 변경 문구를 실제로 사람이 검수했다는 것은 별도 근거를 요구한다.

이력 감사 다음 단계는 파싱 공백의 원문 확인, 실제 언어 오류 교정, 변경 필드·정확한 before/after 해시·검토 근거의 결합이다. 그 전에는 827행을 일괄 copy exception으로 등록하거나 최초 초안으로 되돌리지 않는다.
