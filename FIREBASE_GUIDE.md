# 🔥 Firebase 설정 가이드

Cloud-Backup (Google 로그인 + 데이터 동기화)을 활성화하려면 Firebase Console에서 1회 설정이 필요합니다. 약 10분 소요.

> 설정 안 해도 앱은 정상 동작합니다 — 단지 데이터가 로컬에만 저장됩니다.

## 1단계 — Firebase Console에서 프로젝트 만들기 (3분)

1. https://console.firebase.google.com 접속 (Google 계정 로그인)
2. **"프로젝트 추가"** 클릭
3. 프로젝트 이름: `ko-lernen-app` (또는 원하는 이름)
4. Google Analytics: **사용 안 함** 선택 (안 써도 OK, 나중에 켜기 가능)
5. **"프로젝트 만들기"** → 1–2분 대기

## 2단계 — Android 앱 등록 (2분)

1. 프로젝트 대시보드에서 안드로이드 아이콘 (🤖) 클릭
2. **Android 패키지 이름**: `com.sujinarin.ko_lernen_app` (정확히)
3. 앱 닉네임: `Koreanisch lernen` (선택)
4. SHA-1 인증서 (Google Sign-In 위해 필수):
   ```bash
   cd /Users/sujinpark/Developer/ko_lernen_app
   cd android && ./gradlew signingReport 2>/dev/null | grep -A 2 "Variant: debug" | grep SHA1
   ```
   출력된 SHA-1 (예: `A1:B2:C3:...`)을 Console에 붙여넣기
5. **"앱 등록"** → **`google-services.json` 다운로드**
6. 받은 파일을 다음 위치에 저장:
   ```
   /Users/sujinpark/Developer/ko_lernen_app/android/app/google-services.json
   ```
   ⚠️ **`.gitignore`에 이미 등록됨** — 깃에 올리지 마세요.

## 3단계 — Gradle 설정 (자동, 알림)

Firebase Console에서 안내하는 Gradle 변경:

**`android/build.gradle.kts`** (프로젝트 루트):
```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```

**`android/app/build.gradle.kts`** (이미 플러그인 적용 중인 위치 다음에):
```kotlin
plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")   // ← 추가
}
```

> 이 두 줄은 알려주시면 제가 추가하겠습니다 (단순 변경).

## 4단계 — Firebase 서비스 활성화 (3분)

Firebase Console에서:

### Authentication
1. 왼쪽 메뉴 → **"Authentication"** → **"시작하기"**
2. **"Sign-in method"** 탭
3. **"익명"** 활성화 → 저장
4. **"Google"** 활성화 → 프로젝트 지원 이메일 선택 → 저장

### Cloud Firestore
1. 왼쪽 메뉴 → **"Firestore Database"** → **"데이터베이스 만들기"**
2. **"프로덕션 모드에서 시작"** → 위치: `europe-west3 (Frankfurt)` (독일 사용자 가까움)
3. **"규칙"** 탭 → 다음으로 교체:
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```
   → **"게시"** (사용자는 자기 데이터만 읽고 쓸 수 있음)

## 5단계 — 빌드 + 테스트

```bash
cd /Users/sujinpark/Developer/ko_lernen_app
flutter clean
flutter pub get
flutter build apk --debug
```

빌드 성공 시:
1. 앱 설치 → 자동으로 익명 계정 생성
2. **Einstellungen → Cloud-Backup → "Mit Google sichern"** 탭
3. Google 계정 선택 → 익명 계정이 Google 계정과 연결됨
4. **"Jetzt sichern"** → Firestore에 데이터 저장
5. **앱 삭제 후 재설치 → 같은 Google 계정 로그인 → "Wiederherstellen"** → 데이터 복원 ✓

## 비용

Firebase **Spark Plan (무료)** 한도:
- Auth: 무제한 사용자
- Firestore: 50,000 reads/day, 20,000 writes/day
- Cloud Storage: 1GB

본인 + 남친 둘이 쓰는 한도 내. **평생 무료**.

## 문제 해결

### "Failed to find configuration file 'google-services.json'"
→ google-services.json이 `android/app/` 위치에 없음. 다운로드 후 그 위치에 저장.

### "PlatformException(sign_in_failed)"
→ SHA-1이 Console에 등록 안 됨. 2단계 SHA-1 추가 다시.

### iOS도 지원하려면
→ Firebase Console에서 iOS 앱 추가 → `GoogleService-Info.plist` 다운로드 → `ios/Runner/`에 저장 + Xcode로 프로젝트에 추가
