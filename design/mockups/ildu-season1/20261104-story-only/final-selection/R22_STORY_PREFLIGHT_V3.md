# R22 V3 — 서사 생성 전 검수

검수일: 2026-11-04. 검수자: `/root/story_contract_review`.

판정: **PASS — 현재 프롬프트의 서사·문구·상태 보존 지시 범위.** V3 결과 이미지의 통과나 사용자 승인이 아니다. 입력 V2의 비율 보류도 해제하지 않는다.

## 대상과 식별

- 프롬프트 파일: `C:/dev/hangulsori/_codex_artifacts/season1-finals-20261104/R22_PROMPT_V3.json`
- id: `R22-save-unconfirmed-de-v3-aspect`
- JSON 파일 SHA-256: `5155174fe212429c397061e4f391f8f781152c07e091b7cdd2becbfb110e7d92`
- `prompt` 문자열 UTF-8 SHA-256: `3799674f673265b711df9deb3f59f046d53c67ee9d1e7aa8120c781a95dc4bc3` — 요청에 제시된 promptSHA와 일치.
- 입력 V2 이미지: `C:/Users/vjinn/.codex/generated_images/01a18406-245e-7570-9379-62120de745d6/exec-e9e41158-bd7e-4c26-9e7c-964273acb23d.png`
- 입력 이미지 SHA-256: `a25710bfd780804625f3229e29fa8d396cf585ee80111ace5bb7a80314ab3b3a`; 실제 치수 891 × 1765 px.
- V3 목표 치수: 852 × 1846 px, 9:19.5. 실제 출력 치수는 생성 후 별도 확인한다.

전체 프롬프트를 읽고 입력 V2도 직접 `view_image`로 열었다. 입력에는 왼쪽 `아`, 오른쪽 빈 페이지, 아래의 정확한 DE 안내와 재시도 CTA가 있으며 성공·보상·인물 등 새로운 서사 요소는 보이지 않는다. 이 관찰은 V3가 이어 받을 내용 확인이며 V2 전체 출고 통과가 아니다.

## 원고 대조와 보존 조건

원고: `C:/dev/hangulsori/ko_lernen_app_worktrees/season1-content-integration-20261102/docs/learning/ildu-season1-content-20261030/manuscripts/foundation-1-v35/README.md`, 39행 C-TRY, 51행 C-UNCERTAIN, 58행 저장 확인·원 응답 보존 계약.

| 항목 | V3 지시와 판정 |
|---|---|
| 상태 제목 | `Noch nicht bestätigt` — 기존 R22 신규 UI 상태 요약을 보존. 원고 대사로 주장하지 않음. PASS |
| 본문 DE | `Es ist noch nicht bestätigt, dass dein Fortschritt gespeichert wurde. Wir prüfen es noch einmal.` — C-UNCERTAIN과 정확히 일치. PASS |
| CTA DE | `Noch einmal versuchen` — C-TRY와 정확히 일치. PASS |
| 추가 문구 | 헤더 `HANGUL SORI` / `DE` 외 추가 설명·캡션·새 버튼 금지. PASS |
| 책 상태 | 기존 열린 책 전체와 비례 보존, 왼쪽 `아` 한 글자·오른쪽 공백. 새 쓰기나 복원 사건 없음. PASS |
| 프레이밍 수정 | 이미 있는 낡은 서안·돌·노란 꽃의 공간을 위아래로 연장. 책·글씨를 늘리지 않음. 새로운 서사 장소·소품을 만들라는 지시 없음. PASS |
| 저장 상태 | 명시적으로 저장 미확인. 성공 표시·보상·마법·카운터·퍼센트 없음. PASS |
| 인물과 학습화면 | 새 인물·동물·부분 사지·학습 조작 없음. 시스템 안내이므로 인물 등장 불필요. PASS |

DE 철자와 문장부호를 원고와 대조했다. 새 사건·보상·저장 확정을 추가하는 변경은 없다. KO/EN 화면은 제작·검수 범위 밖이다.

## 출력 후 확인 및 다음 조건

1. V3 이미지를 직접 열어 DE 전체 문구, 왼쪽 `아` 한 글자, 오른쪽 공백, 기존 책·서안, 인물·성공·보상 효과 부재를 다시 확인한다. 프롬프트 PASS를 결과 PASS로 승계하지 않는다.
2. 실제 저장 확인 전에는 R22 미확인 상태를 유지한다. 재시도 시 원 응답·이름·도움 상태·현재 대화 위치·복원된 `아`를 보존해야 하며, PNG로 실제 동작을 검증했다고 보고하지 않는다.
3. 실제 저장 성공 응답 이후에만 R23 보관 확인·마당 복귀/재개로 이어진다. 비율 수정은 이 전환 조건을 바꾸지 않는다.
4. R21b 반려·미완료는 유지한다. R23은 이번 작업에서 생성하거나 검수하지 않았다.
5. 실제 출력 비율, 폰트·터치 영역·여백·safe area, 원본 CTA 바이트 재사용 및 전체 UI 출고는 별도 검수다.

이 문서 외 파일·코드·이미지·런타임·메모리는 변경하지 않았다.
