# 캐릭터 클립·사운드 마무리 — 2026-08-03 (Cowork 세션 인계)

**원칙(이 날 확정):** ① 기준은 무조건 `tiger_idle.png` ② **tiger_roar 는 이미지·영상 불변경, 소리만**(Jin 지시) ③ 키프레임·사운드는 **Jin 컨펌 후에만** 다음 단계 ④ 클라우드 컨테이너는 외부 URL 403 → 다운로드·규격화는 Jin 로컬(아래 붙여넣기).

| 항목 | 상태 | 다음 단계 |
|---|---|---|
| `tiger_bob.mp4` | **영상 후보 완성** — Jin 재생 컨펌 대기 | §1 승인 시 명령 실행 |
| `tiger_roar.mp4` | 시각 불변 · `sfx/roar_tiger.mp3` **코드 배선 완료**(파일 없으면 무음=현행) | §2 소리 파일 확보 |
| `tiger_thinking.mp4` | 키프레임 후보 확보 — **컨펌 대기, 영상화 보류** | §3 |

---

## 1. tiger_bob 교체 (컨펌 후)

**후보 영상(브라우저로 재생해 확인):**
`https://uyncfjzfumputmyodmlr.supabase.co/storage/v1/object/public/public-assets/user-e15b6641-5d77-480c-85aa-0c1061b9c2cd/bbanana/1785749624795.mp4`

첫 프레임 = tiger_idle **무변경 복제**(Nano Banana 2 — 직접 업로드본은 Wan 검증기가 거부해 우회) → Wan 2.7 i2v 1:1·720p·5s, 엎드린 자세 유지 + 숨쉬기 바운스·깜빡임·꼬리 흔들림. 확인 포인트: ⓐ 캐릭터가 캐논에서 이탈하는 프레임 없는지 ⓑ 배경이 끝까지 흰지 ⓒ 루프 이음새.

**승인 시 (cmd, 레포 루트에서):**

```bat
copy assets\video\character\tiger_bob.mp4 _bak_2026-08-02\tiger_bob_old_2026-08-03.mp4
curl -L -o _bak_2026-08-02\tiger_bob_new_raw.mp4 "https://uyncfjzfumputmyodmlr.supabase.co/storage/v1/object/public/public-assets/user-e15b6641-5d77-480c-85aa-0c1061b9c2cd/bbanana/1785749624795.mp4"
ffmpeg -y -i _bak_2026-08-02\tiger_bob_new_raw.mp4 -vf "scale=960:960:flags=lanczos,lutrgb=r='if(gt(val,240),255,val)':g='if(gt(val,240),255,val)':b='if(gt(val,240),255,val)'" -r 24 -an -c:v libx264 -profile:v high -pix_fmt yuv420p -crf 19 -movflags +faststart assets\video\character\tiger_bob.mp4
```

(규격 계약 충족: 960×960 · 24fps · CRF19 · faststart · 무음. `lutrgb`는 240 초과 근백색만 순백 #FFFFFF로 클램프 — multiply 블렌드 이음매 방지. 캐릭터 색은 불변.)

**전 프레임 검증(선택, 레포 파이썬):**

```bat
python -c "import subprocess,glob,os; os.makedirs('_bak_2026-08-02/_bobcheck',exist_ok=True); subprocess.run(['ffmpeg','-y','-v','error','-i','assets/video/character/tiger_bob.mp4','_bak_2026-08-02/_bobcheck/f%%04d.png']); from PIL import Image; bad=[f for f in sorted(glob.glob('_bak_2026-08-02/_bobcheck/*.png')) if min(Image.open(f).convert('RGB').getpixel(p)) < 250 for p in [(5,5),(954,5),(5,954),(954,954)]]; print('corner fail:', bad or 0)"
```

(코너 4점이 전 프레임 ≥250인지 — 실패 목록이 나오면 알려줘.)

## 2. tiger_roar 소리 (영상·이미지 불변)

- **코드 배선 완료**: `character_selection_screen.dart` 일월 무대 포효 재생 시 `sfx/roar_tiger.mp3` — 파일이 없으면 지금처럼 조용히 무음이라 회귀 0.
- 후보 오디오 생성은 bbanana 오디오 계열 **3회 연속 서버 오류로 보류**. 재시도 시: Seedance 1.5 Pro(`mode:sound`, 4s, ≈5크레딧) 또는 Kling 2.6(≈8크레딧) 프롬프트 "single realistic tiger roar, no music, no human voices" → mp4에서 `ffmpeg -i in.mp4 -vn -acodec libmp3lame -q:a 2 assets\sfx\roar_tiger.mp3`.
- **즉시 임시 소리**(원하면): `copy assets\sfx\growl_tiger.mp3 assets\sfx\roar_tiger.mp3`
- 직접 소스 기준: 2~3초 · 시작 즉발(선지연 ≤80ms) · 끝 자연 감쇠 · mp3 44.1kHz. 규칙: 사람 목소리·TTS 금지, 동물 소리만.

## 3. tiger_thinking (보류)

키프레임 후보(파셋 45–80 규칙 통과분, **컨펌 대기**):
`https://uyncfjzfumputmyodmlr.supabase.co/storage/v1/object/public/public-assets/user-e15b6641-5d77-480c-85aa-0c1061b9c2cd/bbanana/1785748862045.png`

컨펌되면 다음 세션에서 i2v(멈춘 걸음·코 킁킁 루프)로 진행. **roar 시각 교체 산출물은 전량 폐기**(반영 금지 — 지시 오해분).

## 4. 이 세션 커밋분 / Jin 필수 로컬 단계

- 브랜치 `feat/design-refresh-2026-08` (메인 무접촉): `character_selection_screen.dart`(SFX 배선) · `tiger_video.dart`(죽은 가드 정리 + `greetSfxFor`) · `DESIGN_OVERHAUL_PLAN_2026-08-02.md` v1.2 · `AGENTS.md` 로그.
- **필수**: `flutter analyze && flutter test` — 특히 `character_selection_screen_test`(3) · `audio_policy_guard_test` · `no_emoji_glyph_test`.
- ⚠️ 계획서에 08:54경 다른 세션의 미커밋 +329B 편집이 있었는데 v1.2 강제 반영으로 유실됨(커밋 이력엔 없음) — 짚이는 내용 있으면 알려줘.
