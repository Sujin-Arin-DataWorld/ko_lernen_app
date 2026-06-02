# Asset Registry — key illustrations (2026-05-29 update)

This registry lists the primary living-hanok assets used by the app, their current file paths, and the build-optimized sizes. Backups stored at:
- `assets/illustrations/hanok/backup/` — gate originals
- `assets/illustrations/mascot/backup/` — tiger pre-knockout originals
- `assets/illustrations/.bg_knockout_backup/` — empty/error/scenes pre-knockout originals

---

## Hanok / Gate assets (v2 — 2026-05-29 transparency knockout)

**Why this changed**: Jin's gate PNGs shipped with opaque cream backgrounds outside the arch and opaque mountain art baked inside the doorway. The intro architecture assumes the frame's doorway is transparent (so doors and "beyond" scene show through) and the area outside the arch is transparent (so the base layer is visible). Both were violated. Result: closed gate looked static and the doors never appeared to swing — they were hidden behind a solid frame the whole time.

**Fix**: programmatic flood-fill knockout from canvas corners + doorway seed, with per-asset color tolerance. Backups saved before any change.

| Asset | Size | State | Backup |
|---|---|---|---|
| `gate_frame.png` | 941×1672 | ✅ doorway 투명 + 외부 투명 (arch + roof + dancheong + magpie + moon + 하단 산 보존) | `backup/gate_frame.orig2.png` |
| `gate_door_left.png` | 500×1450 (canonical) | ✅ 순수 좌측 문짝 panel, white bg knocked, pillar/hinge cropped | `backup/gate_door_left.orig2.png` |
| `gate_door_right.png` | 500×1450 (canonical) | ✅ 순수 우측 문짝 panel, hinges 포함, white bg knocked | `backup/gate_door_right.orig2.png` |
| `gate_final.png` | 1024×1536 | **v3 (2026-05-29 re-crop)** — courtyard 단독 scene. Jin 원본은 본인이 dancheong + 열린 doors + 처마를 포함해 gate_frame과 겹치면 "게이트 두 개"로 보였음. 중앙 마당 부분만(305..720 × 295..1480) 크롭 후 cover scale로 캔버스 채움. 압축 322KB. | `backup/gate_final.with_gate.png` (이전), `backup/gate_final.orig.png` (Jin 원본) |

**Intro 통합 (`lib/widgets/sori/hanok/gate_art.dart`)**: door registration coordinates 그대로 (frame 1080×1920 spec 비율 유지). Doors는 BoxFit.fill로 doorway rect를 정확히 채움. Frame이 TOP 레이어, doors가 하위 레이어 — doorway 투명이라 doors가 회전하며 보이고, 회전 각도가 커질수록 화면 투영이 좁아져 사라짐.

**Intro 타이밍 재설계 (`lib/screens/intro_gate_screen.dart`)**:

| Phase | t | 변경 |
|---|---|---|
| 등장 | 0.00–0.12 | easeOutCubic (이전 easeOut 0–0.10) |
| 문 열림 | 0.10–0.55 | **easeInOutCubic** (이전 easeOutCubic 0.10–0.50) — 가속/감속 부드럽게 |
| 마당 fade-in | 0.45–0.70 | 도어 50% 시점에 시작 (이전 0.30–0.60) |
| 카메라 푸시 | 0.62–0.95 | **easeInOutCubic, 최대 2.4x** (이전 easeInCubic, 4.0x) — 멀미 제거 |
| 게이트 fade | 0.82–1.00 | easeIn (이전 0.78–0.98) |
| 까치 비행 | 0.38–0.85 | 더 여유롭게 (이전 0.42–0.82) |
| Duration | 3400ms 첫실행 / 1800ms | 이전 2750ms/1600ms → 시네마틱 호흡 확보 |

---

## Mascot assets (v3 — 2026-05-29 background knockout)

**Why this changed**: 모든 tiger PNG (9장)가 (196,196,196) gray 또는 (240,240,240) white 사각형 배경을 가진 채 저장돼 있었음. 까치 PNG 5장은 이미 투명이라 정상. tiger들은 어떤 colored card/background에 올려도 회색 사각형 outline이 보였음 — 시나리오 hero card, MascotPop, FlyingMagpie, 결과 화면 모두에서.

**Fix**: multi-seed flood-fill from canvas edges + ring sampling. Per-file color signature detection (light gray/white only). Tigers' fur (orange/black/white) preserved by adaptive tolerance.

| File | Before bg | Knocked | Backup |
|---|---|---|---|
| `tiger_idle.png` | (198,198,196) gray | ~50% | `mascot/backup/tiger_idle.png` |
| `tiger_blink.png` | gray | ~49% | `mascot/backup/tiger_blink.png` |
| `tiger_smile.png` | gray | ~49% | `mascot/backup/tiger_smile.png` |
| `tiger_happy.png` | gray | ~49% | `mascot/backup/tiger_happy.png` |
| `tiger_neutral.png` | gray | 55% (2nd pass) | `mascot/backup/tiger_neutral.png` |
| `tiger_celebrate.png` | gray | ~38% | `mascot/backup/tiger_celebrate.png` |
| `tiger_sad.png` | (219,219,219) | ~61% | `mascot/backup/tiger_sad.png` |
| `tiger_sleepy.png` | (235,217,180) cream | ~67% | `mascot/backup/tiger_sleepy.png` |
| `tiger_thinking.png` | white | ~53% | `mascot/backup/tiger_thinking.png` |

까치 5장 (`magpie_*.png`)은 변경 없음 — 원래부터 정상 투명.

---

## Empty / Error / Scenes (v2 — 2026-05-29 white bg knockout)

이전엔 모두 순백(255,255,255) opaque 배경. card나 0.08 opacity backdrop 위에서 흰 사각형으로 보임. Knock out 후 자연스럽게 합성됨.

| Folder | Files | Backup |
|---|---|---|
| `empty/` | celebrate_complete · sleeping_tiger_b2 · studyroom_waiting | `.bg_knockout_backup/empty_*` |
| `error/` | lost_magpie ✓ (offline_lantern 변경 없음 — bg가 white가 아님) | `.bg_knockout_backup/error_*` |
| `scenes/` | cafe · directions · hotel · market · restaurant | `.bg_knockout_backup/scenes_*` |

---

## Restore instructions

전체 복원이 필요하면:

```bash
# Gate assets
cp assets/illustrations/hanok/backup/gate_frame.orig2.png assets/illustrations/hanok/gate_frame.png
cp assets/illustrations/hanok/backup/gate_door_left.orig2.png assets/illustrations/hanok/gate_door_left.png
cp assets/illustrations/hanok/backup/gate_door_right.orig2.png assets/illustrations/hanok/gate_door_right.png

# Tigers (전체)
cp assets/illustrations/mascot/backup/*.png assets/illustrations/mascot/

# Empty/Error/Scenes
for f in assets/illustrations/.bg_knockout_backup/empty_*.png; do
  cp "$f" "assets/illustrations/empty/${f##*/empty_}"
done
# (반복: error_, scenes_)
```

---

## Notes
- Gate knockout: Python PIL flood-fill (tolerance 35–60), 2026-05-29.
- Mascot knockout: 2-pass flood-fill, tolerance 30 then 70, with ring sampling.
- 백업 폴더는 `.gitignore`로 빌드/repo 영향 없음 (확인 필요).
- **Jin 신규 자산 교체 시**: 같은 파일명, **canvas 비율 유지**, **반드시 투명 배경으로 export**. PNG-24 + alpha 채널.
