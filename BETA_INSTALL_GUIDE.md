# 🚀 Hangul Sori 베타 설치 가이드

> **현재 버전**: 1.0.0 (베타) · 빌드일 2026-05-20
>
> 친구/남친에게 보낼 때 이 파일과 APK 함께 공유.

---

## 📱 어떤 APK 보내면 되나?

| 폰 종류 | 파일 |
|---|---|
| **거의 모든 안드로이드** (2017년 이후) | `app-arm64-v8a-release.apk` (23 MB) ⭐ |
| 오래된 안드로이드 (2017 이전, 저가 폰) | `app-armeabi-v7a-release.apk` (20 MB) |
| 에뮬레이터 / 인텔 태블릿 (드뭄) | `app-x86_64-release.apk` (24 MB) |

**99%는 arm64-v8a 하나면 충분합니다.** 모르겠으면 그것만 보내세요.

파일 위치:
```
/Users/sujinpark/Developer/ko_lernen_app/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

---

## 📤 APK 친구에게 보내는 방법

**옵션 A — 카카오톡** (가장 빠름)
1. 카톡 채팅창 → 첨부 아이콘 → **파일** → APK 선택 → 전송
2. 친구가 받은 파일 탭 → 안드로이드가 자동으로 설치 화면 열어줌

**옵션 B — 구글 드라이브 / 클라우드 링크**
1. 드라이브에 APK 업로드 → 공유 링크 복사
2. 친구에게 링크 전송 → 다운로드 후 설치

**옵션 C — USB 직접 연결** (남친 폰)
1. 폰 USB로 Mac 연결 → "파일 전송" 모드
2. APK 폰의 Downloads/로 복사
3. 폰에서 파일 매니저 → Downloads → APK 탭 → 설치

---

## 📲 안드로이드에서 설치 (친구가 할 일)

처음 한 번만:

1. APK 파일 탭 → **"이 출처에서 설치 허용"** 권한 요청 → 허용
   - (또는 사전에: 설정 → 보안 → "출처를 알 수 없는 앱 설치" 활성화)
2. **"설치"** 탭
3. 끝! 앱 서랍에 **"Hangul Sori"** 아이콘 (세종대왕 익선관 모양) 생김

⚠️ 첫 설치 시 Google Play Protect 경고가 뜰 수 있음:
- **"무시하고 설치"** 누르면 됨 (베타 앱이라 정상)
- "이 앱은 안전하지 않을 수 있음" = Google Play를 안 거쳐서 그런 거지 진짜 위험은 X

---

## ✅ 친구가 처음 열 때 체크 리스트

1. **레벨 선택 화면** 등장 (A1~B2) → 자기 레벨 선택 → 시작
2. **홈** 화면:
   - 상단: 🔥 streak + ⚡ XP + Lv
   - "오늘의 글자" 카드 (Daily Calligraphy)
   - "Heute empfohlen ✨" Hero 카드 → 시나리오 추천
   - 2×2 그리드: Hangul / Vocab / Grammar / Listen
   - 게임: Anlaut Quiz / Wordle
3. **시나리오 카페** 진입 → Intro → Vocab → Dialog (TTS 동작) → Grammar → 3 Quests → Result
4. **설정**:
   - 언어 (Deutsch / English / 시스템)
   - **테마 (Hell / Dunkel / Systemvorgabe)** ← 새 기능!
   - 레벨 변경 (A1~B2)
   - 데이터 초기화

---

## 🐛 알려진 한계 (베타)

- iOS 빌드 별도 (App Store 제출 필요 — 본인은 macOS 있어서 가능, 친구는 Android만)
- 한국어 TTS 품질은 폰 OS에 의존 (Galaxy = 좋음, 외산 폰 = 보통)
- AdMob 광고 = 테스트 모드 (실제 광고 안 뜸)
- Firebase 클라우드 sync는 google-services.json 없으면 자동 비활성 (로컬은 정상)
- B2 (고급) 시나리오 아직 없음 — B1까지만

---

## 💬 피드백 받는 법

친구가 사용 후 알려달라고 할 것:

1. **재미있었던 시나리오** / **어색했던 표현**
2. **마스코트** (지은/민수) 인상 어땠는지
3. **라이트 / 다크 모드** 어느 쪽 더 좋은지
4. **버그**: 크래시했거나 안 보이는 텍스트 등 → 스크린샷 + 어떤 화면인지
5. **다음 시나리오 어떤 거 보고 싶은지** (편의점 외 어떤 상황?)

---

## 🔄 새 버전 보낼 때

코드 업데이트 후:
```bash
cd /Users/sujinpark/Developer/ko_lernen_app
flutter build apk --release --split-per-abi
# → 새 APK 생성 (1-2분)
# → 친구에게 새 파일 다시 보내기
```

설치 시 기존 앱 위에 업데이트 (데이터 유지).
