# 배포 런북 — v2.0.3+9 내부 테스트 (2026-08-03, final Android build source `6893293`)

> **목적:** "로컬·깃 최신화 이외에, 앱이 진짜 유저(내부 테스터)에게 보이기까지 해야 하는 일" 전수 리스트 + 상태 + 실행 절차.
> 게이트 상세는 [`DEPLOY_CHECKLIST.md`](DEPLOY_CHECKLIST.md), 코드 상태는 [`AUDIO_VIDEO_RELEASE_AUDIT_2026-08-02.md`](AUDIO_VIDEO_RELEASE_AUDIT_2026-08-02.md).
> 아래의 v2.0.1~v2.0.2 섹션은 과거 기록이다. 새 업로드에는 이 문서의 **§0** 산출물과 `docs/store/release-notes-v2.md`의 Build 2.0.3+9 블록만 사용한다.

---

## §0. 현재 업로드 대상 — v2.0.3+9 (versionCode 9)

**빌드 소스:** `6893293a97f68ed42cf30c01399471c8daa79081` (`pubspec.yaml` `2.0.3+9`). 이 소스에는 `6ff708a` Android OAuth/Firebase 설정과 `8fd8b1f` 캐릭터 선택/무음 포효 수정이 포함된다.

### 검증 게이트

| 게이트 | 결과 |
|---|---|
| `flutter clean` → `pub get` → `gen-l10n` | ✅ 생성 번역 변경 없음 |
| `flutter analyze --no-pub` | ✅ 0 issues |
| `flutter test --no-pub --concurrency=1` | ✅ **1,579 통과** |
| `npm --prefix functions/gye test` | ✅ **281 통과** |
| `npm --prefix functions/gye run test:rules` | ✅ **42 통과** |
| `python tool/check_clip_matte.py` | ✅ **16/16**, 실패 0 |

### 서명 산출물

빌드 플래그: `--release --obfuscate --split-debug-info=build/app/outputs/symbols --dart-define=ENABLE_TESTER_FEEDBACK=true --dart-define=BETA_UNLOCK_ALL=true`.

| 산출물 | 크기 | SHA-256 |
|---|---:|---|
| `build/app/outputs/bundle/release/app-release.aab` | **242,400,178 B (231.2 MB)** | `e1b2c7450228480b45553da0332705330899810534989b32b7bb29d0e2868e39` |
| `build/app/outputs/flutter-apk/app-release.apk` | **263,680,468 B (251.5 MB)** | `29ddfee5936c465c8aab3cbfdb6eb9a7acafd2ba1e141bd5e24fd181f49c23f3` |

- AAB: `jarsigner -verify -certs` → `jar verified` (upload key는 자체서명이며 업로드 키 체인 경고는 예상됨).
- APK: package `com.sujinarin.ko_lernen_app`, versionName `2.0.3`, versionCode `9`; APK Signature Scheme v2 확인. signer SHA-256 `f5afe836…b4faad3`.
- 번들 계약: asset payload 241개, MP4 30개, `curriculum_manifest.json` 및 `welcome-hero.mp4` 포함, `magpie_moon.mp4` 부재.

### Android 실기기 스모크

- 기기: Redmi M2101K6G / Android 12 / adb `9053622f`.
- 기존 앱 데이터를 삭제하지 않고 위 최종 APK를 `adb install -r` 성공 → `2.0.3` / versionCode 9 / APK v2 서명 확인.
- `force-stop` 후 cold launch 성공, `MainActivity` 포커스·프로세스 재기동 확인.
- 홈 → `Üben` → `Grammatik` 진입, 필터·A2 카드·한국어 예문·독일어 뜻·코치마크가 접근성 트리와 실기기 캡처에 정상 노출. 최신 logcat 2,000줄의 fatal/Flutter/app 오류는 0건이었다.
- 경계: 이번에는 Grammatik 화면을 실기기 캡처로 확인했지만, 온보딩 히어로 영상의 16:9 크롭과 피드백 카드의 실제 시각 배치는 아직 별도 육안 확인이 필요하다. 피드백 전송은 수행하지 않았다.

### iOS 및 서버 배포 경계

- iOS는 **출시 차단** 상태다. Windows에는 iOS 기기·Xcode가 없고, iOS Firebase options/`GoogleService-Info.plist`/Runner target membership/Google URL scheme/Apple Team·프로비저닝도 없다. `_initFirebase()`는 실패를 잡아 UI를 띄우지만 Firebase/Auth/App Check/동기화/피드백/프리미엄/푸시가 비활성화된다. macOS에서 [`store/ios-external-setup.md`](store/ios-external-setup.md)를 완료하고 `dart run tool/verify_ios_firebase_config.dart`, archive, 실기기 스모크를 모두 통과해야 한다.
- Functions와 Firestore 규칙의 로컬 테스트는 통과했지만, 이 세션은 Firebase 배포를 실행하지 않았다. 내부 테스터의 피드백을 실제 수신하려면 별도 승인 하에 Functions/Rules 배포를 완료해야 한다.

---

## §1. 코드측 게이트 — 전부 ✅ (이 세션에서 실측)

| 게이트 | 상태 | 근거 |
|---|---|---|
| `flutter analyze` (CI 동일 플래그) | ✅ 0 issues | 3e4a058 에서 실행 |
| `flutter test` | ✅ **1,306/1,306** (기존 1,293 + 사운드 신규 13) | 〃 |
| 래칫 | ✅ w800 193/193 · 글리프 2/2 · SoriButton 74/74 무증가 + 신규 볼륨 리터럴 래칫(0/exempt 3) + l10n parity(델타 0) | 적대적 검증 직접 계수 |
| 클립 매트 | ✅ 16/16 (클립 무변경 → 리포트 유효, `character_clip_matte_test` 포함 통과) | git status 무변경 |
| 버전 | ✅ `2.0.1+6` — **Play 최신이 4라 6 그대로 사용**(+7 불필요, 확정 2026-08-02) | pubspec:4 |
| 서명 | ✅ keystore 실존(`C:/Users/vjinn/keys/upload-keystore.jks`, 2,760B) + `android/key.properties` + gradle 하드 실패 가드 | 실측 |
| 릴리스 노트 | ✅ `docs/store/release-notes-v2.md` — +6 기준 + **이번 빌드 델타 블록(DE/EN) 추가**(사운드 설정) | 본 세션 |
| CI (origin/main) | 3e4a058 런 진행/확인 중 — 로컬 동일 게이트 green | gh run |
| TTS 서버 | ✅ tts/v3 1,314/1,314 업로드 완결 (Jin gsutil 실측) | AUDIT §4-4 |

## §2. 산출물 매니페스트 (2026-08-02 재빌드 — `flutter clean` 후 공식 절차)

> ⚠️ 직전 매니페스트(8/1, `BB20DC29…`/`FDCAE3E1…`)는 **3e4a058 의 Dart 변경(사운드 설정 등)이 없어 폐기** — 이번 빌드가 업로드 대상.

| 산출물 | 크기 | SHA-256 |
|---|---|---|
| `build/app/outputs/bundle/release/app-release.aab` | **246,949,257 B (235.5 MB)** | `599a1acbeb7b556d4b9c1fc93549b0cd701b572691688ea9a0b09c4d89d483eb` |
| `build/app/outputs/flutter-apk/app-release.apk` (실기기 스모크용) | **268,280,553 B (255.9 MB)** | `8ae02e9731a3b3818759ff8552b06e82692b19d9c23a2664e254f5839fa4f605` |

번들 계약 스팟체크(zipfile 실측): **growl_tiger.mp3 포함 ✓ · magpie_moon.mp4 부재 ✓ · mp4 30개 ✓**. 빌드: `flutter clean` → `pub get` → `build appbundle --release`(582s) → `build apk --release`(871s), 2026-08-02 16:22/16:37.

### §2-B. ⚠️ 최종 — versionCode 7 (2026-08-02 18:50, **HEAD `415541e` 커밋 완료 후 빌드**) — **이게 업로드 대상**

| 산출물 | 크기 | SHA-256 |
|---|---|---|
| `app-release.aab` (versionCode **7**) | **246,925,354 B (235.5 MB)** | `9257aaf7a491b6072ffd90aeb715671240052668f179005fb2e0def6bd3af2fe` |
| `app-release.apk` (스모크용) | **268,280,481 B (255.9 MB)** | `e071090872832bddbc65f704e207250729a67a5b09cf561d41680b4ab51cd25f` |

번들 계약: growl ✓ · magpie_moon 부재 ✓ · mp4 30 ✓. 빌드 전 `git status`로 코드 clean 실측 — **git HEAD 와 1:1 대응 보장**. (18:38 중간 빌드는 병렬 세션 미커밋 코드 혼입 가능성으로 폐기.)

**+7 포함 델타 (v6 대비):**
1. 사운드 카테고리 설정 전체 (ADR-002 — v6 재빌드분과 동일)
2. **홈 Lernpfad 지그재그** (`liveNowNode` 정적 강등 — 디코더 경합 차단)
3. **캐릭터 선택 실기기 결함 4종 수정** (병렬 세션, `df65c12`): 하얀 번쩍임(미리보기 영상→정적 Mascot) · 호랑이 인사음 반복(loop 자동 SFX 금지) · 까치 인사 무음(SFX를 grant 와 분리) · welcome-hero 크롭 + **캐릭터별 설명 신규**(DE/EN)

검수: 1:1 전수 **21/21 IMPLEMENTED**(코드 13·문서 8, `wf_a9400976-636`) + 병렬 세션 자체 검증(analyze 0·전체 1,306·적대 리뷰 0).

> ✅ **v7 Play 내부 테스트 업로드 완료** (2026-08-02 저녁, Jin).

### §2-C. 최신 — versionCode 8 (2.0.2, 2026-08-02 20:47) — **다음 업로드 대상**

**포함 델타(v7 대비): 레벨 연동 실전 커리큘럼** (`49ce0a3`/병합 `31a6e5c`, Codex 세션) — 코스 그래프·A1 미션 16·8문항 진단·개념 숙달/보정·`/course/mission` 화면·학습 데이터 재생성. 이 클론 게이트 재검증: **analyze 0 · 전체 1,350 통과**(+44 신규). 코드 clean 실측 후 빌드(HEAD `31a6e5c` + pubspec +8).

| 산출물 | 크기 | SHA-256 |
|---|---|---|
| `app-release.aab` (versionCode **8**) | **247,516,543 B (236.1 MB)** | `e00a79ae92c2ab44d02455240ce23fb8bc9975c3605991ca0d48cee6b2b46e35` |
| `app-release.apk` (스모크용) | 256.5 MB | `521db11b337008d2091d73250ffc2f1c51b1919bfae148a4e95f54e9d7c680dc` |

번들 계약: growl ✓ · magpie_moon 부재 ✓ · mp4 30 ✓ · **curriculum_manifest.json 포함 ✓**. 출시 이름: `8 · 레벨 연동 커리큘럼(코스 미션+진단)`. ⚠️ 커리큘럼은 **실기기 미검증** — 스모크에 온보딩 진단 8문항·코스 미션 진입·기존 진행도 보존 확인을 추가할 것.

## §3. 유저(테스터)에게 도달하기까지 — Jin 실행 절차 (순서대로)

### 3-1. 실기기 스모크 (업로드 전 최종 관문)

**전제: 기존 데이터는 보존한다.** 서명이 같은 경우 먼저 `adb install -r`로 업데이트한다. 앱 제거·데이터 삭제는 사용자가 명시적으로 승인한 경우에만 수행한다. MIUI `INSTALL_FAILED_USER_RESTRICTED` 시: 개발자 옵션 → "USB를 통한 설치" 허용 + MIUI 최적화 끄기(+ Mi 계정 로그인). 다른 안드로이드 기기가 있으면 그쪽이 빠름.

```powershell
# adb 는 PATH 에 없음 — SDK 전체 경로로 실행 (sdk.dir = %LOCALAPPDATA%\Android\Sdk)
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r build\app\outputs\flutter-apk\app-release.apk
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" logcat | Select-String "ExoPlayerImpl|reclaim|CodecException"
```

> PATH 에 영구 추가하려면(선택): 시스템 환경 변수 `Path` 에 `%LOCALAPPDATA%\Android\Sdk\platform-tools` 추가 후 터미널 재시작.

체크 (DEPLOY_CHECKLIST §5 10항목 + 이번 빌드 추가):
1. 인트로 영상 + **소리**(0.8) 2. 온보딩 대비 3. 프로필 핑크 사각형 없음 4. Lernpfad 전 노드 탭 5. TTS — 발음 후 캐시에 `tts_v3_*.mp3` 생성 확인(기기음성 폴백 아님) 6. 캐릭터 선택 2종 7. 게임 결과 마스코트=선택 캐릭터 8. 로그인/백업 9. 알림 권한 10. 재실행 진행도
**+ 사운드(신규, ADR-002 §10):** 설정→Ton 끄기→앱 완전 종료→재실행→꺼짐 유지 · 채널별 미리듣기(호랑이=growl) · 무음 스위치 · Spotify 재생 중 정답음(음악 안 끊김) · 블루투스 착탈 · combo/complete 볼륨 통일 체감 · listening NPC 남성 목소리 · kkeunmari/listening 카드 안 영상 이음매 없음

### 3-2. Play Console 업로드 (내부 테스트 트랙)

1. [play.google.com/console](https://play.google.com/console) → **Hangul Sori** 앱 → 좌측 **테스트 → 내부 테스트**
2. **새 릴리스 만들기** → `app-release.aab` 업로드 (§2 SHA와 대조)
3. 릴리스 노트: `docs/store/release-notes-v2.md`의 **"이번 내부 테스트 릴리스 노트" DE/EN 블록** 복붙
   - **출시 이름(Release name) 규칙(Jin 지시 2026-08-02)**: 기본값(버전명)은 릴리스끼리 구분이 안 되므로 **매 릴리스 "N · 핵심 내용 요약"** 으로 기입 (예: `7 · 사운드 설정 + 지그재그 홈 + 캐릭터화면 수정`). 내부 관리용 — 사용자에겐 안 보임.
   - **버전명 규칙**: 다음 빌드부터 versionName 도 매번 상향 — `2.0.2+8`, `2.0.3+9` … (콘솔·앱 정보·테스터 제보에서 버전 혼동 방지).
4. **저장 → 검토 → 내부 테스트로 출시** (내부 트랙은 심사 없이 수 분 내 반영)
   - ⚠️ **AD_ID 선언 불일치 오류 발생 시**(2026-08-02 실측): 매니페스트는 광고 ID 를 의도적으로 제거했는데(광고 없음) 콘솔 선언이 "사용함"으로 낡아 있던 것 → **정책 → 앱 콘텐츠 → 광고 ID → "아니요"** 로 변경·저장하면 재빌드 없이 해소. AdMob 재도입 시에만 "예"+매니페스트 remove 줄 제거.
   - 업로드 실측(2026-08-02): 신규 설치 크기 **165MB**, 다운로드 ~1분 38초, versionCode 6·minSdk 24·targetSdk 36 정상 인식.
5. App bundle explorer에서 **실제 다운로드 크기** 확인(추정 ~158MiB — 기록해 두기)

### 3-3. 테스터에게 보이게 하기

1. 내부 테스트 페이지 → **테스터** 탭 → 이메일 목록(또는 Google 그룹)에 테스터 추가 (최대 100명)
2. **참여 링크(웹 옵트인 URL) 복사** → 테스터에게 전송
3. 테스터: 링크 열기 → "테스터 되기" 수락 → Play 스토어에서 설치 (반영까지 몇 분 걸릴 수 있음)

### 3-4. Git 태그 (선택, Jin의 명시 요청 시에만)

```
git tag -a v2.0.3 -m "v2.0.3 (versionCode 9) — internal testing 2026-08-03"
git push origin v2.0.3
```

### 3-5. 첫 24시간 감시 (DEPLOY_CHECKLIST §7)

- Crashlytics 신규 크래시(특히 **MediaCodec·VideoPlayer**) · ANR · 온보딩 완료율
- 롤백 임계: 크래시 프리 <99% → 중단 · 온보딩 완료율 −20% → 중단 · MediaCodec 신규 1건 → 부분 롤백 레버(`_NowDisc`·프로필 아바타 정적 Mascot 강등, ADR-001 §7)

## §4. 이번 빌드에 들어간 것 (직전 8/1 빌드 대비 델타)

- **사운드 카테고리 설정 전체** (ADR-002 구현): 설정→Ton 섹션(마스터+5채널+미리듣기+더킹·무음스위치), AudioPolicy 단일 볼륨 결정, growl_tiger 배선, speech off 시 TTS 차단, AudioContext(타 앱 음악 mix)
- listening NPC 목소리 male(사전생성 캐시 적중) · blendColor 정합 2건(kkeunmari·listening) · 설정 화면 진입 즉시 계정 저널 admission(잠금 준비 선행)
- 문서: ADR-002 Accepted · 검수 SSoT §6/§8 · 이 런북

## §5. 이번 배포에 안 들어간 것 (알고 빼는 목록 — 다음 사이클)

- ambience 화면 배선(§9-6 — **§11-1 Jin 결정 필요: 어느 화면에 켤지**. 그 전까지 설정의 Hintergrundklänge·더킹 토글은 가청 효과 없음)
- 게인 자동화 도구(§4-1) · speech 음소거 스낵바 · ambience/cinematic 미리듣기 · 더킹 250ms 램프 · 설정 사운드 위젯 테스트
- `SoundService.levelUp()` 배선 여부 · `tiger_greet.mp3` 처분 · magpie_worry 도달 불가 경로(Q11) · 홈 히어로 인사음(Q7)
- 에셋 용량 감축(P3) · 41MiB 디버그 심볼(Q15) · 스토어 스크린샷 8장(내부 트랙은 불필요, **프로덕션 승격 전 필수**)

## §6. 리스크·주의

- **래칫 여유 0 셋**(w800·글리프·SoriButton) — 다음 Dart 작업 세션 주의
- iOS: TTS(per-player duckOthers)가 공유 세션을 덮을 가능성 — §10 실기기 확인 항목(Android 주 플랫폼은 무관)
- keystore **백업 여부 미확인**(Q16) — 유실 시 앱 업데이트 영구 불가. 백업 권장(예: 암호화 드라이브)
