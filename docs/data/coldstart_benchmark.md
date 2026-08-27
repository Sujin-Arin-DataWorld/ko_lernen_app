# 콜드스타트 계측 (W2 성능 웨이브)

측정 불가 환경(이 세션)에서는 명령만 고정한다. Jin 이 실기기에서 실행해 표를 채운다.

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
