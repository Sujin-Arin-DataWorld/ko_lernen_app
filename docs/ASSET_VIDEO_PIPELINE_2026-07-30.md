# 캐릭터 클립 제작·복구 파이프라인 기록 (2026-07-30 세션)

> **성격**: 트리거 조회는 `ASSET_FILE_TRIGGER_MAP.md`, 배선 서사는 `ASSET_TRIGGER_AUDIT_2026-07-30.md`.
> 이 문서는 **에셋 자체가 어떻게 만들어졌고 무엇이 고쳐졌는지**(출처·결함·재현 절차)를 남긴다.
> 같은 소스를 다시 인코딩할 사람이 이 문서만 보고 동일 결과를 재현할 수 있어야 한다.

---

## 1. 이 세션이 커밋한 것

### 1-1. 에셋 — `assets/video/character/` 16종 **전량 교체**

| | 값 |
|---|---|
| 포맷 | H.264 / yuv420p / CRF 19 / faststart, **오디오 트랙 없음** |
| 해상도 | 960×960 (예외: `tiger_roar_seated_bonus` 640×640) |
| 프레임 | 24fps · 97프레임(4.04초), `tiger_rise`·`tiger_rest`만 121프레임(5.04초) |
| 배경 | **순백 #FFFFFF** — 앱의 `ColorFiltered(BlendMode.multiply)` 전제 |
| 총량 | 18 MB (webm 원본 38MB 대비 −20MB) |

파일: `tiger_rise` `tiger_rest` `tiger_greet_pawflash` `tiger_choose` `tiger_bob`
`tiger_celebrate_hifive` `tiger_roar` `tiger_roar_seated_bonus` `tiger_stretch` `tiger_thinking`
`magpie_greet_chirp` `magpie_choose` `magpie_perched` `magpie_celebrate` `magpie_worry` `magpie_flight`

### 1-2. 코드 배선 5파일

| 파일 | 변경 |
|---|---|
| `widgets/sori/character_clip.dart` | `CharacterClips.feedbackFor(kind, emotion, {newBest})` 추가 — 감정→클립 매핑의 단일 진입점. 매칭 없으면 `null`을 돌려 호출측이 정적 `Mascot`을 쓰게 한다(강제 영상 금지) |
| `widgets/sori/game_reward.dart` | `GameOverCard` 마스코트 슬롯을 `feedbackFor` 결과에 따라 `CharacterClipPlayer`(116px) 또는 기존 `Mascot`(104px)로 분기 → 게임 7종 전체가 한 곳에서 영상화 |
| `widgets/sori/tiger_video.dart` | `greetAsset`/`paceAsset` 상수를 `video/tiger_greet.mp4`·`tiger_pace.mp4` → `video/character/tiger_rise.mp4`·`tiger_rest.mp4`로 교체. **홈 히어로와 온보딩 첫만남이 한 번에 캐논 호랑이로 승격**(두 화면 모두 이 상수를 읽는다) |
| `screens/scenarios_list_screen.dart` | 시나리오 목록 헤더에 `loopAsset: loops/hanok_jongga.mp4` 명시 — 포스터 파일명이 `madang(light).png`라 자동 유도 규칙에 안 걸림 |
| `screens/listening_screen.dart` | 듣기 완료 카드 `Mascot(magpie, celebrate)` → `CharacterClipPlayer(magpie_celebrate)` |

> 직전 세션 커밋분(`character_clip.dart` 신규, `intro_gate_screen`, `hanok_header` 루프 승격,
> `character_selection_screen` TTS 인사 제거, `pubspec` 폴더 2줄)과 합쳐 한 덩어리로 main에 흡수됨.

---

## 2. ⚠️ 발견된 결함 — 마젠타 잔광 (halo)

**증상**: 알파 webm 16종 **전부**의 다수 프레임에, 캐릭터 주위로 마젠타(#E800E8 계열)
안개가 반투명하게 남아 있었다. 흰 배경에 합성하면 **분홍 구름**으로 보인다.

**측정** (전 프레임 RGB 스캔, `R>170 & G<120 & B>170` 카운트):

| 클립 | 최악 프레임 오염 픽셀 | 화면 비율 |
|---|---:|---:|
| `magpie_greet_chirp` | 178,573 | **19.4 %** |
| `tiger_greet_pawflash` | 64,158 | 7.0 % |
| `tiger_roar` | 10,003 | 1.1 % |
| `magpie_celebrate` | 9,084 | 1.0 % |
| (나머지 12종) | 700 ~ 5,400 | < 0.6 % |

**원인**: 소스 영상의 마젠타 배경이 클립 중간에 **밝기·채도가 변한다**(생성 모델 특성).
단일 임계 `chromakey`는 그 변화를 못 따라가 밝아진 구역을 배경으로 인식하지 못하고,
알파 경계에도 마젠타가 스며든 채 남았다. 임계값을 더 조이면 이번엔 캐릭터 몸통이
투명해지는(이전 세션에서 실측: 중심 알파 47/255) 반대쪽 결함이 난다 — 임계 방식으로는
두 결함을 동시에 못 잡는다.

**해결**: 임계 키잉 대신 **채도 방향(chroma-direction) 기반 디스필**로 전환.
픽셀의 마젠타 성향을 `s = min(R−G, B−G)`로 정의하고,

1. `s ≥ 50` → 배경 글로우로 보고 알파 0
2. `30 ≤ s < 50` → 알파를 선형으로 감쇠(경계 링 방지)
3. `s ≥ 15` **이면서** 밝은 픽셀(min(R,G,B) > 150) → R·B를 G 쪽으로 당겨 잔색 제거
4. 위 처리된 RGBA를 흰색 위에 알파 합성 → yuv420p 인코딩

이 판정은 **캐릭터를 건드리지 않는다**: 호랑이 주황·크림은 `B−G < 0`, 까치 흑백·모자는
`R−G ≤ 0`, 코 분홍은 밝기 조건에서 제외, 반짝임(청록·노랑)도 전부 낮은 `s`를 갖는다.

**검증**: 재인코딩 후 전 프레임 재스캔 — **16종 모두 잔여 마젠타 0 픽셀**(임계 `s ≥ 45`).
길이·프레임수도 소스와 1:1 일치 확인. 최악 프레임을 PNG로 뽑아 육안 확인까지 마침.

**재현 절차** (컨테이너/로컬 어디서든):

```python
# vp9 알파 디코드 → 청크 단위 처리(960²×121프레임은 통짜 로드 시 OOM)
# s = min(R-G, B-G)
kill = clip((s-30)/20, 0, 1); alpha *= (1-kill)
dsp  = (s >= 15) & (min(R,G,B) > 150) & (alpha > 0)
pull = clip((s-12)*0.85, 0, None)
R = where(dsp, max(R-pull, G), R);  B = where(dsp, max(B-pull, G), B)
out = RGB*alpha + 255*(1-alpha)      # 흰 배경 합성
# → ffmpeg -f rawvideo -pix_fmt rgb24 -r 24 -c:v libx264 -crf 19 -pix_fmt yuv420p
```

> **⛔ 폐기 대상**: 이전에 전달된 `part10` 흰배경 mp4 zip과 `assets/video/character/*.webm`은
> 위 결함을 그대로 갖고 있다. 현재 레포에 있는 mp4가 유일한 정본이며, webm 16종은 삭제됨(−38MB).

---

## 3. 형식 결정 근거 (왜 alpha webm이 아니라 흰배경 mp4인가)

Flutter `video_player`는 알파 채널 합성을 기기·코덱별로 보장하지 않는다. 앱은 이미
`TigerStageVideo`에서 **흰 배경 mp4 + `ColorFiltered(BlendMode.multiply)`** 로
배경을 화면색에 흡수시키는 패턴을 쓰고 있었다(`tiger_video.dart` 주석 참조).
신규 클립도 같은 계약을 따르므로 `CharacterClipPlayer` 하나로 전부 재생된다.

- multiply는 라이트 테마 전용이지만 앱이 `themeMode.light` 고정이라 항상 성립.
- ⚠️ `saveLayer` 블렌드는 비디오가 `Texture` 레이어라 적용되지 않는다 — 반드시 `ColorFiltered`.
- 배경이 정확히 순백이어야 `out = dst`가 되어 잔상이 0이 된다(회색이면 박스가 보인다).

---

## 4. 남은 확인 사항 (2026-07-31 시점 실측)

1. **`tiger_roar_seated_bonus.mp4` 파일이 현재 폴더에 없다.** `character_clip.dart:34`의
   상수와 `feedbackFor(..., newBest: true)` 경로는 살아 있으므로, 신기록 달성 시
   초기화 실패 → 정적 마스코트 폴백(크래시 아님). 파일을 되돌리거나 매핑을
   `tigerCelebrateHifive`로 바꾸는 것 중 택일 필요.
2. **`assets/video/character/deploy_checklist_20260730.md`** — 문서가 에셋 폴더 안에 있다.
   `pubspec`이 폴더째 등록하므로 **APK에 그대로 들어간다**. `docs/`로 옮길 것.
3. 이후 세션이 추가한 `tiger_sitting2` · `magpie_moon` · `magpie_sitting` ·
   `magpie_tiger_together`는 이 파이프라인 밖에서 만들어진 것 — 위 마젠타 스캔을
   통과했는지는 별도 확인 대상.

---

*작성: 2026-07-30 세션(에셋 재생성·트리거 배선). 로컬 VM 부재로 git 조작은 Jin이 수행.*
