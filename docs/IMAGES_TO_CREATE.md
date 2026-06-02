# 제작해야 할 이미지 리스트 (light 전용)

> 작성: 2026-06-02 · 기준: `종가이미지 압축` 48장 반영 후 실측 + **다크모드 폐지** 반영
> 스타일/프롬프트: `docs/ASSET_GENERATION_BIBLE.md` (최종 단일 소스). 낱장 상세 프롬프트 부록: `docs/plans/stately-rising-jongga-assets.md`
> ⚠️ **다크모드 폐지로 모든 `_dark` 변형은 제작 불필요** (한옥 24장 → light 12장으로 축소 등).
> "드롭인" = 파일만 넣으면 코드가 자동 인식 / "와이어링" = 코드 연결 추가 필요.

---

## ✅ 지금 들어와 있는 것 (참고)
- 한옥 단계(light): 10/12 — empty, foundation, pillars, **beams(신규)**, thatch, tile_partial, tile_complete, dancheong, gate, windows
- 장식: 10 · 도장: 6 · 스티커: 11 · 마스코트: 호랑이·까치 전부 · 솟을대문 gate 세트

---

## 🔴 P1 — 출시 차단/플래그십 (먼저)

| 파일 | 용도 | 규격 | 저장 경로 | 연결 |
|---|---|---|---|---|
| feature graphic | **Play Store 필수** 등록 이미지 | 1024×500 | `docs/store/` | 콘솔 업로드 |
| 스크린샷 8장 | 스토어 미디어 | 1080×1920(폰) | — | 실기기 캡처 |
| `book_empty_shelf.png` | 책 한 컷 — 빈 책장 | 사각, 투명/cream | `assets/illustrations/book/` | **와이어링 필요** |
| `book_camera_guide.png` | 책 한 컷 — 촬영 가이드 | 〃 | 〃 | 와이어링 필요 |
| `book_analyzing.png` | 책 한 컷 — 분석 중 | 〃 | 〃 | 와이어링 필요 |
| `book_success.png` | 책 한 컷 — 성공 축하 | 〃 | 〃 | 와이어링 필요 |
| `book_error.png` | 책 한 컷 — 오류 | 〃 | 〃 | 와이어링 필요 |

> 책 한 컷 일러스트 5장은 현재 화면이 **마스코트로 대체** 중. 만들면 플래그십 인상이 크게 좋아짐. 단, 코드에 경로 연결이 필요(현재 미참조) — 만들면 알려주시면 연결해 드림. 폴더 `assets/illustrations/book/` 신설 + pubspec 등록도 함께 필요.

---

## 🟠 P2 — 한옥 성장 완성 (light 2장, 드롭인)

| 파일 | 용도 | 규격 | 저장 경로 | 연결 |
|---|---|---|---|---|
| `stage_side_building_light.png` | 한옥 11단계 사랑채 | 841×1870 (기존 단계와 동일) | `assets/illustrations/hanok_stages/` | **드롭인** (자동 인식) |
| `stage_jongga_light.png` | 한옥 12단계 종갓집 완성 | 〃 | 〃 | **드롭인** |

> 없으면 마지막 두 단계가 이전 단계 이미지/단색 fallback으로 보임. B2 끝까지 간 유저에게 "종갓집 완성" 연출이 안 나옴.

---

## 🟡 P3 — 퀘스트 장식·도장 (출시 후 폴리시, 대부분 드롭인)

| 파일 | 용도 | 연결 | 비고 |
|---|---|---|---|
| `decoration_seokdeung.png` | 장명등 (발음평가 퀘스트 보상) | **드롭인** | 출시 후 획득 가능 퀘스트 |
| `decoration_sagunja_guk.png` | 사군자 국화 (4폭 완성용) | **드롭인** | 매·난·죽 3장 있음, 국화만 빠짐 |
| `stamp_mountain.png` | 단청 도장 (산) | 와이어링 가능성 | 도장 위젯 8모티프 중 7번째 |
| `stamp_plum.png` | 단청 도장 (매화) | 와이어링 가능성 | 8번째 |

저장 경로: 장식 `assets/illustrations/decorations/`, 도장 `assets/illustrations/stamps/`

---

## 🟢 P4 — v3.0(커뮤니티) 전까지 불필요 (지금 만들지 말 것)

- **계절 장식 4종**: `decoration_seollal_flag`, `decoration_chuseok_moon`, `decoration_hangeulday_plaque`, `decoration_kite` (시즌 이벤트 시)
- **돌담** `decoration_doldam.png` (친구 5명 = 계 커뮤니티 기능 = v3.0)
- **스티커 19장** (현재 11/30, 스티커 채팅은 v3.0 커뮤니티)
- **계 공동 한옥 추가 요소 8장** (v3.0)

---

## 요약
- **출시 전 꼭**: feature graphic(1) + 스크린샷(8) + (권장) 책 한 컷 5장
- **곧**: 한옥 마지막 2단계(드롭인) + 장명등·국화(드롭인)
- **나중(v3.0)**: 계절/돌담/스티커/공동한옥 = 약 31장
- 다크 변형: **전부 폐지** (제작 안 함)
