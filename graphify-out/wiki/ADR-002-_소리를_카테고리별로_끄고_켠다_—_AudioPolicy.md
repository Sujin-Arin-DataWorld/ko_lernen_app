# ADR-002: 소리를 카테고리별로 끄고 켠다 — AudioPolicy

> 44 nodes · cohesion 0.05

## Key Concepts

- **ADR-002: 소리를 카테고리별로 끄고 켠다 — AudioPolicy** (13 connections) — `docs/ADR-002-audio-policy.md`
- **6. 테스트 전략** (8 connections) — `docs/ADR-002-audio-policy.md`
- **3. Decision — `AudioPolicy` 단일 결정 지점** (7 connections) — `docs/ADR-002-audio-policy.md`
- **1. 지금 앱에 실제로 존재하는 소리 (실측)** (6 connections) — `docs/ADR-002-audio-policy.md`
- **11-정정. 오디오를 어디에 실을 것인가 — 결론 (2026-08-01)** (5 connections) — `docs/ADR-002-audio-policy.md`
- **5. TTS 더킹 — 발음을 소리로 덮지 않는다** (4 connections) — `docs/ADR-002-audio-policy.md`
- **7. 설정 UI** (4 connections) — `docs/ADR-002-audio-policy.md`
- **2. 문제 정의** (2 connections) — `docs/ADR-002-audio-policy.md`
- **4. 에셋 볼륨 정규화 — 29 dB 격차를 없앤다** (2 connections) — `docs/ADR-002-audio-policy.md`
- **ADR-002-audio-policy.md** (1 connections) — `docs/ADR-002-audio-policy.md`
- **10. 실기기에서 확인할 것 (에뮬레이터로 안 잡힘)** (1 connections) — `docs/ADR-002-audio-policy.md`
- **11. Open Questions — Jin 결정 필요** (1 connections) — `docs/ADR-002-audio-policy.md`
- **1-1. 소리를 내는 코드 지점 — 전부 6곳** (1 connections) — `docs/ADR-002-audio-policy.md`
- **1-2. 🔴 `SoundService.enabled` 는 스위치가 아니다** (1 connections) — `docs/ADR-002-audio-policy.md`
- **1-3. 🔴 앰비언스 배선은 있는데 죽어 있다** (1 connections) — `docs/ADR-002-audio-policy.md`
- **1-4. 영상 오디오 실측 (`ffmpeg -af volumedetect`)** (1 connections) — `docs/ADR-002-audio-policy.md`
- **1-5. 효과음 파일** (1 connections) — `docs/ADR-002-audio-policy.md`
- **2-1. 진짜 충돌: 앰비언스 × TTS** (1 connections) — `docs/ADR-002-audio-policy.md`
- **3-1. 채널 (카테고리)** (1 connections) — `docs/ADR-002-audio-policy.md`
- **3-2. API — 볼륨을 계산하는 곳은 여기 한 곳뿐** (1 connections) — `docs/ADR-002-audio-policy.md`
- **3-3. 계산식** (1 connections) — `docs/ADR-002-audio-policy.md`
- **3-4. 저장 (`Storage`, 기존 `_b`/`_d` 패턴 그대로)** (1 connections) — `docs/ADR-002-audio-policy.md`
- **3-5. 통지** (1 connections) — `docs/ADR-002-audio-policy.md`
- **3-6. `SoundService.enabled` 마이그레이션** (1 connections) — `docs/ADR-002-audio-policy.md`
- **4-1. 이 표는 손으로 쓰지 않는다 — 스크립트가 만든다** (1 connections) — `docs/ADR-002-audio-policy.md`
- *... and 19 more nodes in this community*

## Relationships

- No strong cross-community connections detected

## Source Files

- `docs/ADR-002-audio-policy.md`

## Audit Trail

- EXTRACTED: 43 (100%)
- INFERRED: 0 (0%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*
