# 한글소리 에셋 배치 계획 (2026-07-29)

> 원칙: **레포 루트에 그대로 풀면 끝나는 구조**. 파일명은 기존 코드 참조와 1:1 (마스코트 enum, 헤더 파일명 ↔ 루프 mp4 동일 이름). 정지 png 교체는 코드 무변경.

---

## 1. 폴더 배치 (번들 zip 구조 = 레포 구조)

```
ko_lernen_app/
├─ assets/
│  ├─ illustrations/
│  │  ├─ mascot/                      ← [교체] 정지 9장 (mascot_v4)
│  │  │    tiger_neutral·smile·sad·sleepy·thinking / magpie_celebrate·perched·perched_alt·worry
│  │  │    ★ tiger_celebrate.png 은 번들에 없음 → 기존 하이파이브 원본 그대로 유지
│  │  └─ hanok/
│  │       kkeunmari_hero.png         ← [교체] v4 (엎드린 호랑이 + 미드홉 까치)
│  │       listening_hero.png         ← [교체] v2 (마스코트 질감 통일)
│  └─ video/
│     ├─ intro_gate_to_madang.mp4     ← [신규] 인트로 8초 (gate_entrance→gate_final)
│     ├─ loops/                       ← [신규] 풀프레임 앰비언트 13편 (mp4, 무음)
│     │    welcome_hero.mp4 · kkeunmari_hero.mp4(일어나는 최종) · listening_hero.mp4(lively 최종)
│     │    porch.mp4 · study_classroom.mp4 · study_scholar.mp4
│     │    hanok_jongga.mp4(호랑이 눕는 v2) · hanok_construction.mp4(10초 v2)
│     │    scene_cafe · scene_market · scene_hotel · scene_restaurant · scene_directions.mp4
│     └─ character/                   ← [신규] 투명 알파 webm 16편 (UI 위 재생)
│          tiger: rise · roar · celebrate_hifive · rest · bob · stretch · thinking
│                 choose · greet_pawflash · roar_seated_bonus
│          magpie: flight · celebrate · worry · perched · choose · greet_chirp
└─ docs/INTEGRATION_2026-07-29.md     ← 이 문서
```

- 스프라이트 시퀀스(3fps PNG, iOS 폴백용)는 용량 때문에 번들 제외 — part1~7 zip에 전부 있음. 필요시 `assets/anim/<name>/`에 개별 투입.
- 기존 `assets/video/tiger_greet.mp4`(640² 3D풍)는 삭제 권장 대상이지만 번들이 건드리지 않음 — 직접 정리.

## 2. 화면별 배치 매핑

| # | 화면 / 순간 | 에셋 | 형식 |
|---|---|---|---|
| 1 | 앱 실행 인트로 | intro_gate_to_madang.mp4 (풀스크린, 탭=skip, reduce-motion시 madang 정지) | mp4 |
| 2 | 캐릭터 선택 | 헤더: loops/welcome_hero.mp4 · 후보 카드: character/tiger_bob + magpie_perched · 확정: tiger_choose / magpie_choose | mp4+webm |
| 3 | 첫 인사 (말 없이) | tiger_greet_pawflash / magpie_greet_chirp (+ 추후 동물 SFX 별도 재생) | webm |
| 4 | 온보딩 설명 3카드 | ①hanok_construction ②scene_cafe ③tiger_celebrate_hifive+magpie_worry | mp4+webm |
| 5 | 홈(마당) | 배경: loops/hanok_jongga.mp4 · 마스코트 아이들: tiger_rest | mp4+webm |
| 6 | 시나리오 챕터 헤더 | scene_{key}.mp4 (poster = 기존 scenes/{key}.png) | mp4 |
| 7 | 학습 헤더 | Hangul: study_classroom · Grammar: study_scholar · Chosung/Wordle: porch · Listening: listening_hero · Kkeunmari: kkeunmari_hero | mp4 |
| 8 | 퀴즈 진행 | 생각: tiger_thinking · 대기: tiger_bob · 듣기: magpie_perched | webm |
| 9 | 정답 / 오답 | tiger_celebrate_hifive + magpie_celebrate / magpie_worry (+정지 tiger_sad) | webm |
| 10 | 레벨업·뱃지·스트릭 | tiger_roar (대안: roar_seated_bonus) · 한옥 성장 트랜지션: hanok_construction | webm+mp4 |
| 11 | 세션 완료 | tiger_stretch | webm |
| 12 | 홍보·스토어 | 쇼츠 몽타주 9:16 (번들 외, 별도 링크) | mp4 |

## 3. pubspec.yaml 추가

```yaml
  assets:
    # ...기존 항목 유지...
    - assets/video/
    - assets/video/loops/
    - assets/video/character/
```

## 4. 재생 형식 가이드

- **loops mp4**: `video_player` 루프 재생, 로딩 전 poster로 대응 png 표시. 무음이므로 오디오 세션 간섭 없음.
- **character webm(알파)**: Android·웹 OK. **iOS는 VP9 알파 미지원** → 두 가지 폴백: (a) part zip의 3fps 스프라이트 시퀀스, (b) 원하면 HEVC+alpha(.mov) 변환본 추가 제작 가능(무료, ffmpeg).
- **reduce-motion**: 모든 영상 → 대응 정지 png 1프레임.
- 마스코트 정지 교체는 emotion enum 파일명 유지라 **코드 무변경**.

## 5. 다음 코드 작업 체크리스트

1. pubspec asset 3줄 추가 → `flutter pub get`
2. `intro_gate_screen.dart`: 영상 인트로 모드(끝나면 홈 fadeScale, 탭 skip 유지)
3. `CharacterClipPlayer` 위젯 1개: webm ↔ 스프라이트 ↔ 정지png 자동 폴백
4. 선택/인사/온보딩 3카드 화면 (비평 문서 플로우 S1~S3)
5. 헤더 위젯에 "png → mp4 루프" 승격 옵션 (파일명 동일 규칙 활용)
6. 정답/오답 피드백에 webm 재생 + (추후) SFX 훅

## 6. 번들 외 자료 (링크는 최종 요약 v2 시트 참조)

스프라이트 전체(part1~7) · 쇼츠 몽타주 · SFX 데모 · 착석포효/웃는인사 등 대안 컷 · 리뷰 시트들
