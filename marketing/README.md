# marketing/ — Instagram Reels 파이프라인

한글소리 인스타(**@hangulsori_learnkorean**) 릴스를 JSON 대본에서 mp4까지 만들고, 승인 게이트를 거쳐
Instagram Graph API로 발행한다. 계정 언어는 **독일어 우선**이다.

```
brand/tokens.json         팔레트·폰트·인코딩 설정 (소셜 산출물의 정본)
content/reels/*.json      릴스 대본 스펙
content/reel-bank-30.md   다음 30편 기획
build/render.mjs          JSON -> mp4 + 커버 + 캡션
build/lib/ass.mjs         ASS 자막 생성 (스타일표)
publish/instagram.mjs     승인 큐 + Graph API 발행
out/                      산출물 (git 무시)
```

## 명령

```bash
npm run render:all
```

```bash
node publish/instagram.mjs add hanok-waechst-01
```

```bash
node publish/instagram.mjs approve hanok-waechst-01
```

```bash
node publish/instagram.mjs --live
```

`--live` 없이 실행하면 항상 dry-run이다. `approved` 상태가 아닌 항목은 절대 발행되지 않는다.

## .env (publish/.env, git 무시)

```
IG_USER_ID=<Instagram 비즈니스 계정의 IG User ID>
IG_ACCESS_TOKEN=<장기 액세스 토큰>
PUBLIC_MEDIA_BASE=https://<R2 또는 Pages 공개 URL>/reels
IG_API_VERSION=v23.0
```

---

## ⛔ 가장 중요한 규칙 (v3) — 자막을 영상에 굽지 않는다

**렌더러가 만드는 건 글자가 하나도 없는 clean visual master 다.** 모든 독일어 카피는
After Effects 의 별도 텍스트 레이어로 올린다.

왜:
- 문구를 고치거나 DE/EN/KO 버전을 만들 때 **영상을 다시 만들 필요가 없다.**
- v2 까지는 ASS 로 구웠는데, 흰 글자 + 검은 굵은 외곽선을 화면 중앙에 크게 넣으니
  릴스 밈 자막처럼 보였고 호랑이 얼굴·까치·한옥 지붕 같은 핵심 비주얼을 계속 덮었다.

```bash
npm run render:all      # -> out/<id>/<id>-master-1080x1920.mp4  (글자 0)
```

```bash
npm run ae              # -> out/<id>/<id>-ae.jsx + <id>-text-spec.md
```

`ae_text[]` 가 있고 `text[]` 가 없으면 렌더러가 자동으로 clean master 모드로 돈다
(`[clean master · 자막 없음]` 로그가 뜬다). `.jsx` 는 AE 에서 컴프를 선택하고
File > Scripts > Run Script File 로 실행하면 텍스트 레이어가 위치·타이밍·애니메이션까지 생성된다.

### 타이포 규칙 (Jin 확정)

| 역할 | 폰트 | 크기 | 색 |
|---|---|---|---|
| headline | Inter SemiBold | 68 | 먹색, 왼쪽 정렬, **최대 2줄** |
| sub | Inter Medium | 38 | 먹색 80% |
| chapter | Inter Medium | 34 | 먹색 70% (짧은 라벨만, 문장 금지) |
| tag | Inter SemiBold | 26 | 녹청 사각형 위 크림, **첫 1~2초만** |
| cta | Inter SemiBold | 36 | 녹청 pill 위 크림, 작게 |

- **외곽선·검은 스트로크·드롭섀도 전부 금지.** 큰 중앙정렬 자막 금지.
- 애니메이션은 **opacity 0→100 + Y +16px→0, 0.25~0.35초**. 그게 전부다.
  단어별 등장·흔들림·줌인·타자기·바운스 금지.
- 하단 300px(y 1620~)에는 아무것도 두지 않는다.
- `.jsx` 의 문자열은 `\uXXXX` 로 이스케이프된다. ExtendScript 가 파일을 시스템 코드페이지로
  읽어도 `Tür`·`wächst` 가 깨지지 않게 하기 위해서다.

---

## 에셋 선택 규칙 (v2 — 1차 반려 후 확정)

1차 릴스 3편은 이미지가 작고 캐릭터가 작고 잘못된 클립을 골라 반려됐다. 재발 방지 규칙:

0. **⛔ `assets/illustrations/hanok_stages/stage_beams_light.png` 는 쓰지 마라.**
   12장 중 그 한 장만 **앱 화면 목업**이다 — `Stage 3`, `Beams + Rafters`, `A1 Progress 75%`,
   `16 / 21 packs cleared`, `Next Stage` UI와 영어 대사 카드, 브랜드와 다른 초록 한복 호랑이가
   그림 안에 박혀 있다. 나머지 11장은 깨끗한 씬이다.
1. **풀블리드가 기본.** 배경은 1080×1920을 꽉 채운다. 작은 카드 배치 금지.
   `hanok_stages/*.png`는 841×1870 **세로 풀스크린용**이다. 가로 카드로 넣지 마라.
2. **캐릭터는 화면 폭의 55% 이상.** 페이오프 컷은 600px 이상.
3. **렌더 전 `--sheet` 필수 통과.**
   ```bash
   node build/render.mjs <id> --sheet
   ```
   참조 미디어 전부의 시작·중간·끝 프레임이 한 장으로 나온다. **파일명만 보고 클립을 고르지 마라** —
   `magpie_bob.mp4`는 6.5초에 까치가 프레임 밖으로 날아간다. 자리를 지키는 건
   `magpie_bob2`·`magpie_perched`·`magpie_celebrate`다.
4. **가로 소스(1280×720)를 세로 풀블리드로 쓸 때**는 중앙 구도인지 먼저 확인한다.
   `welcome-hero`·`hanok_jongga`·`intro_gate_to_madang`은 중앙 구도라 cover 크롭이 안전하다.
   `taego-joy-duo`는 까치가 왼쪽에 치우쳐 세로 cover 시 잘리므로 정사각 crop이나 contain을 쓴다.
5. **`fill: "blur"` 는 쓰지 마라.** 흐린 확대본으로 화면을 채우는 방식은 큰 얼룩처럼 보인다.
   실제로 `tiger-elster-01`에서 시도했다가 폐기했다. 대신 중앙 구도 소스를 cover로 쓴다.
7. **`anchor` 로 인물을 밀 때 옆에 붙은 캐릭터가 잘리는지 확인해라.** `welcome-hero`를
   `anchor: [0.34, 0.5]` 로 오른쪽에 밀었더니 **호랑이 어깨 위 까치가 통째로 잘렸다**.
   주제가 "호랑이와 까치"인 영상에서 치명적이었다. 두 캐릭터가 붙어 있는 소스는 `anchor` 대신
   **하단 박스**(`box: [0, 640, 1080, 1280]`, `fit: "cover"`, `anchor: [0.5, 0]`)로 낮춰서
   상단을 타이포 여백으로 비운다.
8. **씬 길이가 제각각이면 `background.sequence` 를 쓰지 마라.** 시퀀스 합이 릴스 길이보다 짧으면
   뒷부분에 배경이 통째로 비는 사고가 난다(`tiger-elster-01`에서 실측). 대신 레이어를 시간순으로
   쌓고 알파 페이드로 전환한다. 배열 순서가 곧 z-order 다.
6. **JSON을 PowerShell로 치환하지 마라.** Windows PowerShell 5.1의 `Set-Content -Encoding utf8`은
   BOM을 붙여 `JSON.parse`를 깨뜨린다. Edit 도구를 쓰거나 `UTF8Encoding($false)`로 써라.

---

## 렌더러에서 반드시 지킬 것 (실측으로 확인한 함정)

1. **`blend=all_mode=multiply` 를 쓰지 마라.** 체인 끝이 `format=yuv420p`면 ffmpeg 8이 blend를
   YUV 평면에서 실행해 U/V(128 오프셋)까지 곱해버리고 **화면 전체가 형광 초록**이 된다. 양쪽 입력에
   `format=rgba`를 못 박아도 재현된다. 흰 배경 캐릭터 클립은 `matte: "white"`(colorkey + overlay)로 처리한다.
2. **브랜드 폰트는 시스템에 없다.** Pretendard는 `hangul-sori-site-local/node_modules`의 .otf를 작업폴더
   `fonts/`로 복사해 `ass=...:fontsdir=fonts`로 넘긴다. 이걸 안 하면 libass가 Arial로 폴백한다
   (기존 `docs/social/bbanana/sori-check-01-reel-1080x1920.mp4`가 그렇게 나갔다).
3. **Gowun Dodum은 아직 못 쓴다.** node_modules에 woff2만 있고 libass는 woff2를 못 읽는다.
   현재 display 폰트는 Noto Sans KR 대체다. TTF/OTF를 시스템에 설치하면 `brand/tokens.json`의
   `fonts.display`를 `"Gowun Dodum"`으로 바꾸면 된다.
4. **Reels 안전영역.** 모든 텍스트는 y 150~1600 안에 둔다. 하단 420px은 캡션·액션바가, 우측 180px은
   액션 레일이 덮는다. 스타일은 전부 Alignment=8이고 MarginV가 곧 상단으로부터의 y다.

---

# Jin이 직접 해야 하는 일 (순서대로)

## 0단계 — 지금 당장, 병렬로 (심사가 2~4주 걸린다)

- [ ] **인스타 계정을 "비즈니스"로 전환.** 크리에이터 계정은 API 발행이 **안 된다**.
      설정 → 계정 유형 → 프로페셔널 → **비즈니스**.
- [ ] 페이스북 페이지 하나 만들어 연결 (API 요구사항).
- [ ] `developers.facebook.com` → 앱 생성 → Instagram 제품 추가.
- [ ] **앱 심사 제출** — `instagram_business_basic` + `instagram_business_content_publish` 두 개를
      각각 스크린캐스트 붙여 제출. 여기서 2~4주 소요되니 제일 먼저 걸어둬라.
- [ ] 심사 통과 후 **IG User ID**와 **장기 액세스 토큰**을 받아 `publish/.env`에 넣는다.

## 1단계 — 호스팅 (심사 대기 중에)

- [ ] Cloudflare **R2 버킷** 하나 생성, 공개 읽기 허용, `reels/` 경로 확보.
      (Workers·Pages는 이미 쓰고 있으니 새 인프라는 필요 없다.)
- [ ] `PUBLIC_MEDIA_BASE`를 그 공개 URL로 설정.
- [ ] `out/<id>/*.mp4`와 `*-cover.jpg`를 업로드하는 절차 확정.
      **Reels API는 로컬 파일 업로드를 안 받는다. 공개 HTTPS URL만 받는다.**

## 2단계 — 콘텐츠 확인

- [ ] 만들어둔 3편을 폰에서 실제로 재생해 확인:
      `out/hanok-waechst-01/`, `out/bojagi-01/`, `out/schwiegermutter-01/`
- [ ] **핸들 표기 확인** — 기존 릴스 렌더에서 `@hangulsori_learnkorean`의 밑줄이 하이픈처럼 보였다.
      실제 계정명이 밑줄이 맞는지 확인하고 다르면 `brand/tokens.json`의 `handle`을 고쳐라.
- [ ] 독일어 카피 원어민 검수 (특히 003의 „Fettnäpfchen" 계열 관용 표현).

## 3단계 — 촬영·녹음 (자동화가 대신 못 하는 부분)

- [ ] **앱 실기기 화면녹화**: ① 단어팩 클리어 → 도장 찍히는 순간 ② 한옥 단계 상승 ③ 단어장 사진 → 게임 생성.
      뱅크의 🎬 표시 항목 전부가 이걸 기다린다.
- [ ] **보이스오버**: C 기둥(파트너·가족) 7편은 목소리가 붙어야 저장률이 산다. 독일어는 Jin, 한국어 문장은
      앱 TTS(female)로 뽑아 얹으면 발음 신뢰도가 생긴다.
- [ ] 얼굴 노출 편은 따로 촬영. 마스코트·화면녹화 편과 섞어 돌린다.

## 4단계 — 발행

- [ ] 첫 3편은 **수동 업로드**로 올려 훅 반응을 본다 (심사 통과 전에도 가능).
- [ ] 심사 통과 후 `add → approve → --live` 흐름으로 전환.
- [ ] 완전 무인 발행은 하지 마라. `draft → Jin 승인 → 발행` 2단계를 유지한다.

## 5단계 — 스케줄링

- [ ] GitHub Actions 크론은 **지금 못 쓴다** — 2026-08-17부터 Actions 잡이 billing/spending limit로
      시작되지 않는다. 맥 `launchd` 또는 수동 실행으로 시작하고, 결제 문제 해결 후 Actions로 옮겨라.
- [ ] API 한도는 24시간 롤링 **100건**이라 실사용엔 여유롭다.

---

## 하지 말 것

- 브라우저 자동화로 인스타 UI를 조작하는 것 — ToS 위반이고 계정 정지 위험이다. 공식 API만 쓴다.
- `docs/social/bbanana/`의 기존 산출물을 정본으로 재사용하는 것 — 폰트 폴백·흰 사각형 결함이 있다.
  포맷만 참고하고 렌더는 이 파이프라인으로 다시 뽑아라.
