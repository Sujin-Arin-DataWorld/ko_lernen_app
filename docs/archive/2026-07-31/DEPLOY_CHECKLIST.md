> ⚠️ 구초안 (2026-08-01 01:27) — 최종본은 [docs/DEPLOY_CHECKLIST.md](../../DEPLOY_CHECKLIST.md) (정정 포함, 릴리스 커밋 eda4c37/7979bc8). 기록 보존용.

# 배포 체크리스트 — 한글소리 (Android / Play Console)

**대상:** `com.sujinarin.ko_lernen_app` · `version: 2.0.1+6`
**최종 점검:** 2026-08-01 (Cowork 세션, 정적 검사)
**주의:** 이 세션 컨테이너에 Flutter SDK 가 없어 `analyze`/`test`/`build` 는 **전부 Jin 이 Windows 에서** 실행해야 한다.

---

## 0. 지금 상태 요약

| 항목 | 상태 |
|---|---|
| 릴리스 서명 (`key.properties`) | ✅ 존재. debug 키 무언 폴백을 gradle 이 **막고 있음** |
| `isMinifyEnabled` / `isShrinkResources` | ✅ 둘 다 true, ProGuard 규칙 있음 |
| DEBUG UI (Premium override) | ✅ `kDebugMode` 게이트 |
| `print()` 잔재 | ✅ 0건 |
| `google-services.json` (Android) | ✅ 있음 |
| 타이포 래칫 | ✅ 해제됨 (2026-08-01) |
| `flutter analyze` / `flutter test` | ⬜ **미실행 — 1번에서 확인** |
| 미커밋 변경 | 🔴 `main` 에 **640건** |
| `assets/` 용량 | 🟡 **136 MB** |
| iOS `GoogleService-Info.plist` | ⬜ 없음 (Android 전용이면 무관) |

---

## 1. 게이트 — 여기서 하나라도 빨간불이면 멈춘다

```bash
cd C:\Users\vjinn\ELibrary\Downloads\DataSet\hangulsori\ko_lernen_app

flutter clean
flutter pub get
flutter analyze --no-fatal-warnings --no-fatal-infos   # CI 와 동일한 플래그
flutter test
```

- `analyze` 는 **error 0** 이어야 한다. warning/info 는 CI 도 허용한다.
- `test` 는 전부 통과여야 한다.

### 실패하면 볼 곳

| 증상 | 원인 · 조치 |
|---|---|
| `docs/_backup_*` 에서 수백 개 `undefined_identifier` | `analysis_options.yaml` 의 `- docs/**` 가 지워졌다. 되돌릴 것 |
| `typography_guard_test` 실패 | 새 화면이 raw `TextStyle` 을 썼다. `SoriTextTheme.of(ctx).*` 로 교체 (상한을 또 올리지 말 것) |
| `character_clip_matte_test` 실패 | 클립을 바꾸고 검사를 안 돌렸다 → `python tool/check_clip_matte.py` |
| `mascot_wiring_test` 실패 | 캐릭터 배선이 끊겼다 |

---

## 2. 버전

```bash
git tag --sort=-creatordate | head -3    # 현재 최신 태그: v1.0.1
```

`pubspec.yaml` 의 `version: 2.0.1+6` 에서 **`+6` 이 Play 의 versionCode** 다.

- [ ] **Play Console 에 이미 versionCode 6 이 올라가 있는지 확인.** 있으면 `+7` 로 올린다 — 같은 코드는 업로드가 거부된다.
- [ ] 태그가 `v1.0.1` 에서 멈춰 있다. 이번 릴리스에 `v2.0.1` 태그를 붙일 것.

---

## 3. 커밋 — 태그를 붙일 수 있는 상태로 만든다

지금 `main` 에 **미커밋 640건**이다. 이대로 빌드하면 **나중에 "무엇을 배포했는지" 재현할 수 없다.** 문제가 터져도 되돌릴 지점이 없다.

```bash
git switch -c release/v2.0.1
git add -A
git commit -m "release: v2.0.1 (versionCode 6)"
git tag v2.0.1
```

- [ ] 브랜치 분리 후 커밋
- [ ] 태그 생성

> 커밋·푸시는 Jin 이 명시적으로 요청할 때만 — 이 세션은 실행하지 않는다.

---

## 4. 빌드

```bash
flutter build appbundle --release
```

산출물: `build/app/outputs/bundle/release/app-release.aab`

- [ ] 빌드 성공
- [ ] AAB 크기 확인 — `assets/` 가 136 MB 라 **다운로드 크기가 상당**하다

### 용량 내역 (참고)

```
assets/illustrations/   74 MB   ← 가장 큼
assets/video/           50 MB     ├ loops 25M · character 19M · intro 5.9M
assets/stickers/       9.1 MB
그 외                  ~3 MB
────────────────────────────
합계                   136 MB
```

Play 의 AAB 한도(200 MB) 안이지만 첫 설치 체감이 나쁘다. **이번 배포를 막을 일은 아니고**, 다음 사이클에서 `illustrations/` 다운스케일 또는 Play Asset Delivery 를 검토할 것.

`assets_unused/` 46 MB 와 `docs/_backup_2026-07-31/` 은 `pubspec.yaml` 에 없으므로 **번들에 안 들어간다.** 레포만 무겁게 한다.

---

## 5. 실기기 스모크 테스트 (에뮬레이터로는 못 잡는 것들)

```bash
flutter install --release      # 또는 AAB → bundletool → 설치
```

**신규 설치**(앱 데이터 삭제 후)로 확인:

- [ ] 첫 실행 — 대문 인트로 영상 + **소리** 재생 (`intro_gate_to_madang.mp4`)
- [ ] 온보딩 첫 화면 — 배경과 선택지가 **구분되는지** (2026-07-31 대비 수정분)
- [ ] 캐릭터 선택 → 호랑이/까치 둘 다
- [ ] 프로필 아바타 — **핑크 사각형이 없는지** (`tiger_sitting2` 자홍 매트 교정분)
- [ ] Lernpfad — 지그재그 경로의 **모든 노드가 탭되는지**
- [ ] 게임 1개 완주 → 결과 카드 마스코트가 선택한 캐릭터인지
- [ ] TTS 한국어 발음 재생
- [ ] 로그인 / 클라우드 백업·복원
- [ ] 알림 권한 요청 흐름
- [ ] 뒤로가기로 앱 종료 → 재실행 시 진행도 유지

### 디코더 확인 (M2101K6G 등)

```bash
adb logcat | findstr /i "ExoPlayerImpl reclaim CodecException"
```

- [ ] 탭을 오가며 **Init 대비 Release 가 따라붙는지** — 순증이 계속 쌓이면 누수
- [ ] 영상이 1초 뒤 사라지는 화면이 없는지

> 배경: `docs/ADR-002` 아님 → `docs/ADR-001-video-decoder-budget.md`. 실측상 코덱 오류는 0건이고 문제는 **플레이어 수명**이다. 이번 배포의 차단 요인은 아니다.

---

## 6. Play Console 업로드

- [ ] **내부 테스트 트랙**에 먼저 올린다 (프로덕션 직행 금지)
- [ ] 릴리스 노트 작성 — 레포에 `CHANGELOG.md` 도 fastlane 도 **없다**. Console 에 직접 입력
- [ ] 데이터 보안 양식이 현재 권한과 맞는지 재확인
      (`INTERNET`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `CAMERA` 등)
- [ ] 스크린샷·설명이 2.0 UI 와 일치하는지 (홈 개편·Lernpfad 지그재그 반영본)
- [ ] 내부 테스트에서 **실기기 설치 확인** 후 프로덕션 단계 출시(예: 20%)

---

## 7. 배포 후 감시 (첫 24시간)

- [ ] Crashlytics — 신규 크래시, 특히 `MediaCodec` · `VideoPlayer` 계열
- [ ] Play Console **ANR 및 비정상 종료율**
- [ ] Firebase Analytics — 온보딩 완료율이 이전 버전 대비 떨어지지 않았는지

### 롤백 기준 (미리 정해 둔다)

| 신호 | 임계 | 조치 |
|---|---|---|
| 크래시 없는 사용자 비율 | 99% 미만 | 단계 출시 **중단** |
| 온보딩 완료율 | 직전 버전 대비 −20% | 중단 후 원인 파악 |
| 신규 `MediaCodec` 크래시 | 1건이라도 재현 | `path_trail` 의 `_NowDisc` 와 프로필 아바타를 정적 `Mascot` 으로 내림 (ADR-001 §7 롤백 레버) |

Play 단계 출시는 **비율을 낮추거나 멈출 수 있을 뿐, 이미 받은 사용자를 되돌리지 못한다.** 그래서 내부 테스트를 먼저 거치는 것이다.

---

## 8. 이번 배포에 **넣지 않는** 것

- **사운드 카테고리 설정** (`docs/ADR-002-audio-policy.md`) — 설계만 완료, 구현 보류
- **온보딩 `SoriTextTheme` 리팩터** — w800 래칫을 189 → 193 으로 임시 상향해 둠.
  리팩터하는 커밋에서 **189 로 되돌릴 것** (`test/typography_guard_test.dart` 주석에 조건 명시)
- **에셋 용량 감축** — 다음 사이클
