# GitHub Actions → Google Play Internal Testing

`main`의 Flutter 변경이 기존 CI를 통과하면 서명된 AAB를 만들고 Google Play의
**내부 테스트(`internal`)** 트랙에만 자동 업로드한다.

자동화하지 않는 것:

- 비공개 테스트 (Closed Testing, Play 트랙 `alpha`)
- 공개 테스트 (Open Testing, Play 트랙 `beta`)
- Production
- iOS / TestFlight

여기서 "자동화하지 않는다"는 `main` push가 해당 트랙을 임의로 갱신하지 않는다는
뜻이다. Jin이 비공개 테스트 릴리스를 명시적으로 요청한 경우에만 별도 수동 워크플로
`.github/workflows/play_closed.yml`을 `main`의 **전체 40자 exact SHA**와 함께 실행한다.
이 워크플로는 그 SHA의 push CI 성공을 다시 확인하고, 테스터 피드백만 켠 별도 AAB를
만들어 `alpha`에 올린다. 공개 테스트와 Production은 이 경로에서도 절대 건드리지 않는다.

비공개테스트 테스터·트랙·승격은 CI가 읽지도 쓰지도 않는다. Closed Testing으로
올리려면 Play Console에서 Jin이 수동으로 한다.

## 누가 설치할 수 있나 (나만)

Play Console → 테스트 → **내부 테스트** → 테스터 이메일에 Jin 계정만 둔다.
내부 테스트 옵트인 링크를 공개 채널에 올리지 않는다. 비공개 테스트 트랙의
테스터 목록은 이 자동 업로드와 무관하다.

## 최초 1회 설정

1. Google Cloud에서 **Google Play Android Developer API**를 활성화한다.
2. 배포 전용 service account를 만들고 Play Console **사용자 및 권한**에서 Hangul
   Sori 앱의 테스트 릴리스를 관리할 수 있는 앱 한정 권한만 부여한다.
3. GitHub 저장소에 `google-play-internal` Environment를 만들고 배포 브랜치를
   `main`으로 제한한다. 완전 자동 배포를 원하면 required reviewer는 설정하지 않는다.
4. 그 Environment에 아래 Secrets를 추가한다.

   - `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`: service account JSON 전체
   - `ANDROID_UPLOAD_KEYSTORE_BASE64`: 기존 Play upload keystore의 Base64
   - `ANDROID_KEYSTORE_PASSWORD`
   - `ANDROID_KEY_ALIAS`
   - `ANDROID_KEY_PASSWORD`

5. Repository variable `PLAY_INTERNAL_RELEASE_ENABLED`를 `true`로 설정한다. 이 값이
   없거나 `true`가 아니면 배포 job은 안전하게 건너뛴다.

Windows에서 keystore 내용을 화면에 출력하지 않고 클립보드로 복사하려면:

```powershell
[Convert]::ToBase64String(
  [IO.File]::ReadAllBytes('C:\Users\vjinn\keys\upload-keystore.jks')
) | Set-Clipboard
```

service account JSON도 파일 내용을 터미널에 출력하지 않고 복사한다.

```powershell
Get-Content -LiteralPath 'C:\path\to\play-service-account.json' -Raw |
  Set-Clipboard
```

Play Console에 이 package가 아직 한 번도 등록되지 않았다면 최초 AAB 릴리스 한 번은
Console에서 수동으로 만들어야 한다. 현재 package는
`com.sujinarin.ko_lernen_app`이다.

## 이후 동작

- 앱 코드가 `main`에 push됨
- 기존 Flutter 분석·전체 테스트·웹 release build가 모두 성공함
- upload keystore로 AAB를 서명하고 Dart obfuscation symbols를 생성함
- AAB·SHA-256·symbols를 Actions artifact로 14일 보관함
- AAB를 Google Play **내부 테스트(`internal`)** 에 `completed` 상태로 업로드함
- 비공개 테스트·공개 테스트·Production 트랙은 그대로 둔다

내부 테스트 빌드는 현재 `ci.yml`과 동일하게 `ENABLE_TESTER_FEEDBACK=true`와 exact
`GIT_COMMIT`만 주입한다. 별도의 접근 해제 플래그는 사용하지 않는다. 모든 학습 콘텐츠는
구매·구독·Play 트랙과 무관하게 같은 무료 공개 런타임 계약으로 열린다.

Closed Testing 수동 빌드도 같은 두 값만 주입하며 동일한 무료 접근 계약을 사용한다.
Internal과 Closed의 차이는 업로드 트랙과 실행 방식이지 학습 콘텐츠 접근 권한이 아니다.

자동 실행 실패를 수정한 뒤 다시 올릴 때는 GitHub Actions의 `CI` workflow를 열고
`Run workflow`에서 `release-internal`을 선택한다. 이 수동 재실행도 먼저 Flutter
quality gate를 통과해야 한다.

## 자동화가 대신할 수 없는 확인

- Play Store에서 설치한 release build의 실제 실행
- Play Integrity/App Check 유효성
- 기존 설치 위 업데이트 후 로컬 학습 데이터 보존
- Play Console 정책·스토어 등록정보·계정 권한 문제

이 네 항목은 계속 실제 Internal Testing 설치로 확인한다.

홈페이지의 Cloudflare production 자동 배포 설정은
`docs/GITHUB_ACTIONS_CLOUDFLARE_SETUP.md`에 별도로 기록돼 있다.
