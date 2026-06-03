# SFX — 효과음 에셋 (UI one-shot)

`SoundService`([lib/services/sound_service.dart](../../lib/services/sound_service.dart))가 재생하는 효과음 폴더.

## ✅ 현재 상태 — 이미 채워져 있음 (`.wav` 5개)

`correct` · `wrong` · `combo` · `levelup` · `complete` 가 들어 있어 **지금 바로 소리가 난다** (실기기 `flutter run` 1회).
- `correct`/`wrong`/`combo`/`levelup`: 본 프로젝트 **자작 합성**(사인파+감쇠, 저작권 제약 0). 0.23–0.54초.
- `complete`: 받은 디지털 chime을 **1초로 잘라 페이드아웃**.
- 재생성: `afconvert -f WAVE -d LEI16 "<chime>.mp3" /tmp/chime_raw.wav && python3 tool/gen_sfx.py` ([tool/gen_sfx.py](../../tool/gen_sfx.py))
- **마음에 안 들면 교체**: 같은 파일명으로 덮어쓰기. **wav 권장**(또는 mp3 — 확장자를 바꾸면 `sound_service.dart`의 `_play('sfx/correct.wav')` 경로도 같이 수정).

> 파일이 없어도 SoundService는 조용히 무음 처리(no-op) — 햅틱·콤보 팝업은 계속 작동.

아래는 **더 나은 효과음으로 교체**하고 싶을 때의 가이드다 (현재 합성본은 단순한 사인파 톤이라, 시중 효과음이 더 풍부할 수 있다).

---

## ⚠️ 먼저 읽기 — "왜 자꾸 30초짜리 음악이 나오나"

우리가 필요한 건 **0.2~0.8초짜리 UI 효과음(one-shot sound effect)** 이다.
**음악·멜로디·배경음(BGM)이 절대 아니다.**

- **Gemini / MusicFX / Suno / Udio 같은 "음악 생성 AI" 를 쓰면 안 된다.** 이 모델들은 구조상 *곡(song/track)* 을 만들도록 설계돼 있어서, 무엇을 요청하든 수십 초짜리 음악을 뱉는다. "짧게", "0.3초"라고 적어도 무시하고 곡을 만든다. → **도구 자체가 틀린 것.**
- 효과음은 **효과음 전용 도구**로 만들어야 한다 (아래 순서대로 추천).

### 추천 도구 (위에서부터 — 1·2번이 가장 빠르고 확실)

1. **freesound.org** — 무료. 검색창에 `UI click`, `correct`, `wrong buzzer soft`, `level up`, `success chime` 입력 → 왼쪽 라이선스 필터에서 **Creative Commons 0** 선택 → 0.x초 기성 효과음 다운로드. **AI 안 거치고 바로 해결됨.**
2. **sfxr.me (jsfxr)** — 브라우저에서 프리셋 버튼 한 번이면 즉시 `.wav` 생성. 정답=`Pickup/Coin` 또는 `Powerup`, 오답=`Hit/Hurt`, 콤보=`Powerup`, 레벨업/완료=`Powerup` 여러 번 + 톤 조정. 8-bit 느낌이지만 0.2초로 완벽.
3. **Mixkit / Pixabay Sound Effects / Zapsplat** — 무료 UI 효과음 라이브러리. "game UI", "correct answer", "level up" 카테고리.
4. **ElevenLabs → "Sound Effects"** 탭 (Text-to-Music 아님!) — AI로 만들고 싶으면 *이것만* 써라. 길이를 짧게 지정할 수 있고 효과음에 특화돼 있다. **MusicFX/음악 탭은 쓰지 말 것.**

### 어떤 AI 도구든 프롬프트에 반드시 넣을 것
```
short one-shot UI sound effect, NOT music, no melody, no rhythm, no loop,
mono, dry, ends in silence, under 1 second
```
그리고 **이 단어들은 쓰지 마라** (곡을 불러옴): `music, song, track, loop, melody, beat, BGM, background`.

---

## 필요한 파일 5종 — 정확한 스펙 + 붙여넣기 프롬프트

| 파일명 | 길이 | 느낌 | 영문 프롬프트 (효과음 도구에 그대로 붙여넣기) |
|---|---|---|---|
| `correct.mp3` | **0.15–0.30초** | 밝고 짧은 "딩/팅" 정답음 | `A short, bright single 'ding' UI confirmation tone for a correct answer. One-shot, about 0.25 seconds, clean, mono, dry, ends in silence. NOT music, no melody, no loop.` |
| `wrong.mp3` | **0.15–0.30초** | 부드러운 낮은 "톡/둑" 오답음 (가혹하지 않게) | `A soft, gentle low 'thunk' UI sound for a wrong answer — friendly, not harsh, not a buzzer. One-shot, about 0.25 seconds, mono, dry, ends in silence. NOT music.` |
| `combo.mp3` | **0.25–0.40초** | 상승하는 밝은 반짝임 (연속 정답) | `A short rising sparkle / quick ascending blip for a combo streak in a game. Playful, about 0.35 seconds, one-shot, mono. NOT music, no melody loop.` |
| `levelup.mp3` | **0.50–0.80초** | 화사한 짧은 팡파레/반짝 | `A short cheerful 'level up' chime — a quick magical sparkle flourish. About 0.7 seconds, rewarding, one-shot, ends cleanly. NOT a song, no long melody, no loop.` |
| `complete.mp3` | **0.60–0.90초** | 따뜻한 성취 축하 (보스/세션 완료) | `A short warm success/achievement jingle for finishing a lesson — satisfying and positive. 0.8 seconds maximum, one-shot, mono, ends in silence. NOT background music.` |

> 표의 길이를 넘기면 학습 흐름을 끊는다. **1초를 넘는 파일이 나왔다면 도구를 잘못 쓴 것** — 위 1·2번 도구로 다시.

---

## 포맷 · 설치

- 포맷: **mp3** 권장. (wav/ogg를 받았으면 아래로 변환 — `SoundService`가 `correct.mp3` 처럼 `.mp3` 이름을 찾는다.)
- 모노(mono), 44.1kHz, 96–128kbps면 충분. 볼륨은 과하지 않게(SoundService가 0.55로 재생).
- **파일명을 정확히** (소문자, 철자 그대로):
  `correct.mp3` · `wrong.mp3` · `combo.mp3` · `levelup.mp3` · `complete.mp3`
- 위치: **이 폴더** (`assets/sfx/`). pubspec에 이미 등록돼 있어 추가 설정 불필요.
- 넣은 뒤 `flutter run` 한 번이면 적용 (pubspec asset이라 hot-reload보다 재시작 권장).

### wav/ogg → mp3 변환 + 길이 자르기 (ffmpeg)
```bash
# 형식 변환 (모노, 128kbps)
ffmpeg -i correct.wav -ac 1 -b:a 128k correct.mp3

# 너무 길면 앞부분만 잘라내기 (예: 앞 0.3초)
ffmpeg -i input.mp3 -t 0.3 -ac 1 -b:a 128k correct.mp3
```
ffmpeg 없으면 cloudconvert.com 같은 온라인 변환기 사용.

---

## 라이선스 (스토어 심사 대비)

- **상업적 사용 가능 + 저작자표시 불필요(CC0)** 음원을 권장. freesound는 라이선스 필터를 *Creative Commons 0* 로.
- 출처·라이선스를 어딘가(예: `docs/DATA_LICENSES.md`)에 기록해 두면 Play/App Store 심사 때 안전.

## 무음이어도 정상

파일이 하나도 없어도 앱은 정상이다. 효과음은 도파민 루프의 한 레이어일 뿐 — **햅틱·콤보 카운터·"N er-Combo!" 팝업·confetti 는 사운드 없이도 작동**한다. mp3는 있으면 더 좋은 보너스.
