# 콜드스타트 계측 (W2 성능 웨이브)

CP2026 P1의 기준은 Redmi Note 10급 실제 기기에서 5회 중앙값 ≤2.5초다.
기기 연결 전에는 측정 완료나 성능 통과로 판정하지 않는다. 아래 도구로 원값과
설치 버전을 함께 수집하고, 기존 내부 배포 영수증의 versionCode/SHA와 대조한다.

## 자동 수집

검수용 Android에서 학습을 저장하고 진행 중인 촬영·녹음을 끝낸 뒤 실행한다.
이 명령은 지정한 앱 프로세스를 6번 강제 종료하고 다시 시작한다. 앱 데이터·계정·
권한·측정 동의는 변경하지 않는다. 최초 설치/로그인/온보딩 상태인지도 검수 기록에
별도로 적는다. 설치·업데이트나 다른 검수 작업과 동시에 실행하지 않는다.

```powershell
adb devices
python tool/collect_android_coldstart.py --serial DEVICE_SERIAL --expected-version-code 7653 --output coldstart-7653.json
```

`7653`은 이 문서 작성 당시 내부 제공 빌드의 예다. 이후 배포에서는 검증할 실제
빌드 번호로 바꾼다. `adb`가 PATH에 없으면 `--adb`로 SDK 실행 파일 경로를 지정한다.
출력 경로의 상위 폴더는 먼저 준비하며, 기존 증거 JSON은 덮어쓰지 않는다.

- 첫 실행 1회도 원값으로 보존하되 중앙값에서 제외하고 나머지 5회를 쓴다.
  실행 사이 5초를 두며 이 간격이 Flutter 화면의 준비 완료를 증명하지는 않는다.
- 매 실행 전 force-stop 후 프로세스 부재를 확인한다. `LaunchState`가 있는 Android는
  COLD만 허용한다. 버전 불일치·debuggable 빌드·실행 실패·warm/hot 시작·시간 누락·
  측정 도중 빌드 변경은 전체 측정을 미완으로 남긴다. 느린 값을 골라 재시도하지 않는다.
- JSON에는 6회 원값, 사용한 5회 값, 중앙값, 설치 버전, 모델·OS를 기록한다.
  기기 serial, 사용자 계정, 원본 package dump나 로그캣은 저장하지 않는다.
- `numericThresholdMet`는 **이번 초기 표시 시간 수치만** 비교한다. 에뮬레이터도
  실험할 수 있지만 CP2026의 저사양 실기기 증거로 사용할 수 없다. 기기 등급,
  배포 아티팩트/SHA 연결과 실제 화면 확인은 별도이므로 `cp2026Gate`는 unverified다.

`am start -W`의 TotalTime은 초기 화면 표시(TTID) 계측이다. 로그인·동의 화면이나
스플래시가 빠르게 나왔다는 사실만으로 학습 화면이 사용 가능해졌다고 판정하지 않는다.
실제 Flutter 화면 준비(TTFD), 10분 사용·ANR, 진행도 보존은 별도 검수한다.
근거: [Android 시작 시간 계측](https://developer.android.com/topic/performance/issues/launch-time).

도구 회귀 검사는 `python -m unittest tool.test_collect_android_coldstart -v`이며,
기존 asset pipeline의 `tool/test_*.py` 전체 발견 경로에서도 실행된다.

## 명령

강제 종료 후 콜드스타트 1회:

    adb shell am force-stop com.sujinarin.ko_lernen_app
    adb shell am start -W -n com.sujinarin.ko_lernen_app/com.sujinarin.ko_lernen_app.MainActivity

`TotalTime`(ms) 을 기록한다. 5회 반복해 중앙값을 쓴다(첫 1회는 warm page cache 편차가 커서 버린다 — 6회 실행, 마지막 5회 기록).

ANR 여부는 세션 10분 사용 후:

    adb logcat -s ActivityManager:E

## 결과

| 시점 | 빌드 | TotalTime 중앙값(ms) | 5회 원값 | 비고 |
|---|---|---|---|---|
| Before (W2 착수 전, `main`/`fix/partner-jin-batch1` 기준) | TBD by Jin | TBD | TBD | Task 2-9 적용 전 |
| After (Task 2-9 적용 후) | TBD by Jin | TBD | TBD | 스플래시 게이트(Task 6)·pre-runApp 병렬화(Task 8) 반영 |

## Jin 게이트

- [ ] Before 계측 (이 플랜의 Task 2 착수 전 브랜치에서)
- [ ] After 계측 (이 플랜의 마지막 태스크 커밋 후)
- [ ] 10분 세션 ANR 0 확인
- [ ] Android 12+ 실기기에서 흰 플래시·크롭 스플래시 없음 확인 (Task 10 게이트와 동일 항목, 중복 체크 아님 — 같은 세션에서 함께 확인)

## Android 12+ 스플래시 아이콘 세이프존 — Jin 실기기 게이트 (Task 10)

- [ ] Android 12+ 실기기(예: 기존 회귀 재현 기기 M2101K6G)에서 콜드스타트 시
      로고가 잘리지 않고 전체가 보인다
- [ ] 라이트/다크 모드 양쪽에서 확인
- [ ] 흰 플래시(레이아웃 전환 시 배경색 불일치) 없음 — 배경은 시스템
      스플래시·Flutter 스플래시(Task 6, #FAF6EC)·NormalTheme 배경 3곳 모두
      시각적으로 이어져야 한다
- [ ] 문제가 재현되면 `values-v31/styles.xml`/`values-night-v31/styles.xml`
      에서 `windowSplashScreenBackground`/`windowSplashScreenAnimatedIcon`
      2개 속성만 롤백(다른 4개 화이트리스트 속성은 유지)하고, CONTENT_RATIO
      를 `tool/pad_android12_splash_icon.py` 에서 더 낮춰 재시도
