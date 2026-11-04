# R22 V4 — 실제 이미지 서사 검수

2026-11-04 · 검수자 `/root/story_contract_review`

**PASS — 실제 이미지의 서사·DE 문구·표시 상태.** 원본 PNG를 직접 `view_image`로 열고 현재 원고와 대조했다. 프리플라이트를 자동 승계하지 않았다. 사용자 승인·전체 디자인 출고·앱 완료와는 별도 판정이다.

- 이미지: `C:/Users/vjinn/.codex/generated_images/01a18406-245e-7570-9379-62120de745d6/exec-1b2908b4-98cf-4287-9ca0-7e26aec82360.png`
- 실측: **853 × 1843 px, RGB**, 2,414,846 bytes. V4의 지정 캔버스 치수와 일치하며 약 9:19.5다.
- SHA-256: `841979563167f299c86bc202e65b451b3b520935ff8935f69972fe17ea75f40c`
- 제작 프롬프트 문자열 SHA-256: `4e00d1249be8186b3e740f23351540e9c3aacc18d8851574cf24bcae8e85f084`

원고: `C:/dev/hangulsori/ko_lernen_app_worktrees/season1-content-integration-20261102/docs/learning/ildu-season1-content-20261030/manuscripts/foundation-1-v35/README.md`, 39행 C-TRY, 51행 C-UNCERTAIN, 58행 저장 확인·원 응답 보존 계약.

| 검수 항목 | 실제 관찰 및 판정 |
|---|---|
| 제목 | `Noch nicht bestätigt` 정확. 신규 시스템 상태 요약이며 인물 대사로 표현하지 않음. PASS |
| C-UNCERTAIN DE | `Es ist noch nicht bestätigt, dass dein Fortschritt gespeichert wurde. Wir prüfen es noch einmal.` 정확. 철자·움라우트·문장부호 일치. PASS |
| C-TRY DE | `Noch einmal versuchen` 정확. 골드 CTA 하나이며 추가 행동 문구 없음. PASS |
| 좌우 페이지 | 왼쪽에 먹색 `아` 한 글자, 오른쪽은 글자·이름·도장 없이 공백. 열린 책의 네 가장자리가 보임. PASS |
| 기존 결과·장면 | 낡은 책과 서안, 돌·기와·노란 꽃이 유지됨. 새 쓰기·각성·복구 완료 사건이나 학습 조작 없음. PASS |
| 저장 상태 | 미확인 안내와 재시도만 있음. 완료 체크·저장 확정·마당 복귀를 나타내지 않음. PASS |
| 캔버스 참조 혼입 | 영어 설명, 구름·구름 로고, 섬 전경, 새 건축 전경, 사랑채 라벨, 닫힌 책, 복구 0/36, 엽전 0, 설정, 첫 퀘스트·건축 이력 문구가 없음. PASS |
| 인물·보상 | 사람·동물·부분 사지·보상·재화·진도 수치·마법 효과 없음. 시스템 안내에 인물은 필요하지 않음. PASS |

관찰된 서사·문구 차단 결함은 없다. 제공된 책·서안 참조와의 시각 연속성을 확인했으며 픽셀 동일성이나 과거 사용자 승인 원본의 출처 증명으로 확대하지 않는다.

실제 연결 시 원 응답·이름·도움 상태·현재 대화 위치·복원된 `아`를 유지하며 재시도해야 한다. 저장 성공 응답을 실제로 확인한 경우에만 R23 보관 확인·마당 복귀/재개로 이어진다. PNG는 이 동작을 검증하지 않으므로 **실제 저장·재시도는 미검증**이다.

**R21b 미완료는 유지한다. R23은 이번 검수 대상이 아니다.** 실제 폰트·터치 영역·여백·safe area·원본 CTA 바이트 재사용·Flutter 및 기기 동작은 별도 검수이며, 이 서사 PASS를 사용자 승인이나 앱 완료로 표시하지 않는다.
