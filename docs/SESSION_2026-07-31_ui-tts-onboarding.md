# 세션 기록: 2026-07-31 — TTS v3 + UI 가독성/호랑이 정리 + 온보딩 재배치 + 영상 배선

**범위:** TTS v2→v3 마이그레이션·배포 · UI 가독성/CTA 호랑이 정리 · 온보딩 순서 재배치 ·
연습/프로필 영상 배선 · Deploy Checklist 검증 · tts v2 흔적 제거.
**결과:** 전부 origin/main 반영·검증. `flutter analyze` 0 · `responsive_test` 157/157.

---

## 1. TTS v2 → v3 캐시 마이그레이션 + CF 배포 (커밋 `fc1d865`)

- **캐시 리비전 v2→v3**: client(`tts_service.dart`)·CF(`tts_contract.js`)·gen(`generate_tts.py`)·테스트 3.
  sha1 키에 voice명이 없어 v2 경로가 옛 **Aoede/Neural2** 오디오를 그대로 재사용하던 문제 →
  리비전 버스트로 해소. 로컬 캐시 파일명에도 rev 포함 → 기기 캐시도 무효화.
- **CF 의존성 v7 정렬**: `firebase-functions ^5→^7.3.2`, `firebase-admin ^12→^14.2.0`,
  `+@firebase/app ^0.15.1` — v5+firebase-tools v15 discovery timeout 해소 + v7 eager provider
  load가 요구하는 firebase-admin optional peer(@firebase/app) 보강.
- **재생성·업로드**: 1314개(여 **Zephyr** 1211 · 남 **Enceladus** 103) → Storage `tts/v3` 업로드·원격 카운트 검증.
- **CF 재배포**: `synthesize_tts` europe-west3, rev `synthesize-tts-00003` ACTIVE.
  배포 관문 해소 — IAM `actAs`(sujin.arin.park에 Service Account User 부여) + `npm install`(누락 deps).

## 2. UI 가독성 + CTA 호랑이 "까딱임" 정리 (`6f4082d`, `5ab9eec`)

- **중앙 레버**(앱 전역): `SoriButton`(lg16/md15/sm13.5) · `QuizChoice` 선택지 15→17 ·
  `SoriTextTheme`(bodySmall14·caption12.5·label13·cardSubtitle12).
- **홈 Heute 카드**: 상시 숨쉬던 마스코트 제거(`_ScenarioAvatar` 삭제) + 제목 17→19·
  "Los geht's" 13→15·eyebrow 11→12·레벨칩 10→11.
- **대기형 마스코트 `animate:false` 12곳**: consent·account_nudge·feature_coach·motivation 시트 ·
  profile·stats·character_selection·onboarding_level·onboarding_preview·listening·scenario(intro/poster/도우미).
  → 결과·게임 **축하 연출(celebrate)은 유지**.
- **문제 텍스트**: 워들 15→18 · 초성 18→20 · 번역 20→22(옵션 18→19) · luecken 20→22.

## 3. 온보딩 순서 재배치 (`56ab2ac`)

기존 `QuickOnboarding → Character → Consent → Preview → Level` →
**`QuickOnboarding → Consent → Preview(튜토리얼) → Character(쌤쌤/든든) → Level → home`**.
(캐릭터 선택을 튜토리얼 앞 → 뒤·레벨 앞으로.) 루프·이중노출 없음.

## 4. 영상 배선

- **연습(Üben) 탭 헤더**: `porch.png` → `porch.mp4` 루프(HanokHeader loopAsset) (`05b2f1a`).
- **프로필 아바타**: 선택 캐릭터 영상 — tiger→`tiger_sitting2.mp4`, magpie→`magpie_moon.mp4`
  (`02045bc` 코드 + `a892be2` 영상파일). 영상 게이트/저모션 시 정적 Mascot 폴백.

## 5. Deploy Checklist 20260730 검증 + tts v2 흔적 제거

- **체크리스트 100% 메인 반영 확인**: webm 16종 삭제 완료 · §2·§3·§8 배선(11파일에 에셋 참조) ·
  character mp4 19 + loops mp4 13 존재.
- **tts v2 흔적 전수검수**: 리비전 상수 3계층 전부 v3 · `tool/generate_tts.py` `--demo` 프로브의
  옛 "Aoede" 라벨 → "Zephyr" 교체(`06b3d6c`). **라이브 코드 v2 음성 흔적 0** (py_compile OK).
  (CLAUDE.md·SESSION_CHANGES의 v2/Aoede 언급은 과거 세션 기록 — 라이브 아님.)

---

## 검증

- `flutter analyze lib test` **0** · `flutter test test/responsive_test.dart` **157/157**(오버플로 0) ·
  각 편집 `dart analyze` 0 · `py_compile` OK.

## 미검증 (실기기 — 헤드리스 불가)

새 음성(Zephyr/Enceladus) 청취 · 홈/CTA 시각(가독성·호랑이 제거) · 온보딩 새 순서 ·
연습/프로필 영상 재생 · 동적 TTS(책한컷·내단어장, App Check 디버그 토큰 등록 필요).

## 동시세션 주의

본 세션 중 다른 세션이 `character_selection`·`onboarding_preview`·`profile`·`bookshelf`·
`learning_path`·`path_node`·`tokens`·`path_trail`를 병행 편집. 본 세션은 **명시 파일만 스테이징**했고,
일부 커밋(56ab2ac·02045bc)엔 동시세션 시각 WIP이 함께 포함됨(컴파일 OK).

## 커밋 (origin/main)

`fc1d865`(TTS v3) · `6f4082d`·`5ab9eec`(가독성/호랑이) · `56ab2ac`(온보딩) ·
`05b2f1a`(연습 헤더) · `02045bc`+`a892be2`(프로필 영상) · `06b3d6c`(tts 흔적 제거).
