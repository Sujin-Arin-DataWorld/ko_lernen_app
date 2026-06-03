# 회원·계정·개인정보 시스템 — 상용화 전수검사 & 듀오링고화 로드맵

> 작성: 2026-06-03 · 기준: `main` 브랜치 실제 코드 (grep/Read 검증, §0 — 환각 0).
> 범위: 회원계정 · 회원가입 · 로그인 · 계정삭제 · 개인정보보호 · 회원관리.
> 목적: (1) 지금 상용화 가능한 단계인지 판정 (2) 듀오링고 수준 계정 앱이 되는 단계적 계획.

---

## 0. 한 줄 결론

현재 = **익명 우선(anonymous-first) + Google 단일 링크 + "설정 속 백업 기능"으로 묻힌 계정**.

- 🟢 **Google Play 내부테스트/출시는 가능** — 계정삭제·GDPR privacy·Firestore 보안규칙 모두 충족.
- 🔴 **iOS App Store는 차단** — Google 로그인을 제공하면서 **Apple Sign-In 부재** → 가이드라인 4.8 리젝.
- 🔴 **유료구독 유실 리스크** — RevenueCat이 Firebase uid와 미연결(익명). 기기 변경·재설치 시 구독·진행도 끊김.
- 🟡 **듀오링고식 "계정 = 1급 시민" 구조와 큰 격차** — 전용 로그인/프로필/온보딩 계정 유도·자동 동기화 전무.

**판정: "MVP 상용화 가능, 그러나 리텐션·크로스플랫폼·iOS는 미완."**

---

## 1. 현재 구현 전수 (사실 — 코드 인용)

| 영역 | 상태 | 근거 (파일:라인) |
|---|---|---|
| **익명 인증** | 🟢 항상 자동 로그인 | `auth_service.dart:68` `ensureSignedIn`→`signInAnonymously` · `main.dart:143` |
| **Google 로그인(링크)** | 🟢 구현 | `auth_service.dart:79` `linkWithGoogle` (익명→link, 충돌 시 signIn 폴백) |
| **이메일/비밀번호 로그인** | 🔴 없음 | `pubspec` firebase_auth만, EmailAuthProvider 미사용 |
| **Apple 로그인** | 🔴 없음 | `sign_in_with_apple` 패키지 없음, iOS 폴더는 존재 |
| **계정 삭제** | 🟢 구현 + UI 연결 | `auth_service.dart:125` `deleteAccount`(재인증+Firestore tree+user.delete+재익명) · UI `settings_screen.dart:499-510` → `_onDeleteAccount:859` |
| **클라우드 데이터만 삭제** | 🟢 구현 (Google 링크 시만 노출) | `auth_service.dart:113` `deleteCloudData` · UI `settings_screen.dart:413-424` |
| **로그아웃** | 🟢 구현 (→ 다시 익명) | `auth_service.dart:153` `signOut` |
| **전용 로그인/회원가입 화면** | 🔴 0개 | `lib/screens/` 39개 중 login/signup/account/profile 없음 — 전부 `settings_screen` 내부 |
| **프로필 화면** | 🔴 0개 | 이름/아바타/가입일/통계 요약 한곳 없음 |
| **온보딩 계정·약관 단계** | 🔴 없음 | `onboarding_level_screen.dart:74-86` — 레벨 선택(또는 skip) 후 곧장 `/` |
| **이용약관(ToS) 동의** | 🔴 없음 | l10n에 terms/agb 키 0개 |
| **개인정보 처리방침** | 🟢 충실 (EN/DE/KO) | `docs/privacy.html` — GDPR §4 · COPPA §5 · 제3자표 §3 · `account-deletion.html` 별도 링크 |
| **앱 내 privacy 접근** | 🟡 **URL 복사만** (브라우저로 안 엶) | `settings_screen.dart:543-547` → `_copyPrivacyUrl:719` (url_launcher 미사용) |
| **클라우드 동기화** | 🟡 **수동 + 부분적** | `cloud_sync.dart:24-55` — vok/chosung/wordle/grammar/app 통계만. **packs 진행도·bookshelf·custom_packs·도장·streak 일부 누락** |
| **Firestore 보안규칙** | 🟢 견고 | `firestore.rules:27-33` users/{uid} 본인만 · gye/shared_packs/cache 격리 |
| **유료구독 ↔ 계정 연결** | 🔴 **미연결(익명)** | `premium_service.dart:56` `Purchases.configure`만, **`Purchases.logIn(uid)` 없음** |
| **Analytics/Crashlytics** | 🟢 활성 | `pubspec:48-49` · `main.dart:136-143` |
| **데이터 이동권(export)** | 🟡 수동(이메일 문의) | `privacy.html` §4 "Contact us for an export" |
| **회원관리 백오피스** | 🔴 없음 | 신고는 `gye/reports`에 쌓이나 처리 UI/CF 없음 (CLAUDE.md Tier 3f) |

### 핵심 흐름 요약
```
앱 첫 실행 → 익명 Firebase user 자동 생성 (회원가입 0단계)
          → 온보딩(레벨만) → 홈. 사용자는 "계정이 있다"고 인식 못 함.
설정 → Cloud-Backup 섹션 → Google 링크 → 수동 "백업/복원" 버튼
설정 → 맨 아래 위험영역 → "계정 삭제"(빨강)
```

---

## 2. 상용화 준비도 판정 (스토어/법규별)

| 기준 | 신호 | 근거 / 남은 것 |
|---|---|---|
| **Google Play 정책** | 🟢 출시 가능 | 계정삭제 in-app+웹 둘 다 충족(2024.5 정책) · Data Safety 문서 존재 · 광고 없음 |
| **App Store (iOS)** | 🔴 리젝 위험 | **4.8**: 제3자 소셜로그인(Google) 제공 시 Apple Sign-In 동등 제공 의무. 현재 미구현 |
| **GDPR/DSGVO** | 🟢 대체로 충족 | privacy.html 권리고지 완비 · EU(Frankfurt) 서버 · 삭제권 in-app. 🟡 이동권(export) 자동화·ToS 동의 흐름은 미흡 |
| **COPPA/연령** | 🟡 문서만 | privacy엔 13/16세 명시. **앱 내 연령 게이트·동의 UI 없음** |
| **보안** | 🟢 양호 | TLS · Firestore rules 본인격리 · 비밀번호 미저장(OAuth 위임) |
| **수익화 정합성** | 🔴 위험 | RevenueCat 익명 → **구독 복원/크로스기기 불안정**. 환불·CS 분쟁 소지 |

> **결론**: 안드로이드 단독 베타/출시는 **지금 진행 가능**. iOS 동시 출시·유료구독 본격화 전에는 §4 Tier 0~1 필수.

---

## 3. 듀오링고 갭 분석

듀오링고 계정 시스템의 본질 = **"게스트로 마찰 없이 시작 → 진행이 쌓이면 부드럽게 계정 유도 → 계정이 리텐션·소셜·결제의 허브"**.

| 듀오링고 특징 | 우리 현재 | 격차 |
|---|---|---|
| 게스트(익명) 시작 | 🟢 있음 | — |
| streak/진행 쌓이면 "저장하려면 가입" 유도 | 🔴 없음 | **리텐션 핵심 누락** |
| 이메일·Google·Apple·Facebook 다중 로그인 | 🟡 Google만 | 가입 장벽·iOS 차단 |
| 프로필(아바타·이름·가입일·통계·업적) | 🔴 없음 | 정체성·동기 부여 누락 |
| 로그인 시 **자동** 클라우드 동기화 | 🟡 수동 부분 동기화 | 기기 변경 = 데이터 유실 위험 |
| 친구/팔로우·리더보드·리그 | 🟡 계(契=그룹) 백엔드만(UI 3b까지) | 소셜 루프 미완 |
| 푸시 알림(streak 리마인더) | 🔴 없음(알림설정 칸만) | 복귀 트리거 누락 |
| 계정 설정(이메일/알림/프라이버시/삭제) | 🟡 삭제·백업만 | 관리면 빈약 |
| 데이터 export(이동권) 자동 | 🔴 이메일 수동 | GDPR 편의 |

**우리가 이미 가진 강점**: 익명 시작, Google 링크, **계정삭제(많은 인디앱이 빠뜨림)**, 견고한 보안규칙, 계(契) 그룹 백엔드 토대, streak/XP. → **토대는 좋고, "계정을 전면에 세우는" 작업이 핵심.**

---

## 4. 로드맵 — 듀오링고화 (Tier 0 → 4)

### Tier 0 · 출시 차단요소 (P0 — iOS/결제 전 필수)
| # | 작업 | 왜 | 파일 | 공수 | 리스크 |
|---|---|---|---|---|---|
| 0.1 | **Apple Sign-In** 추가 | iOS 4.8 리젝 방지 | `auth_service`, `sign_in_with_apple`, Xcode capability | M | 인증서·Apple Dev 계정(Jin) |
| 0.2 | **RevenueCat `logIn(uid)`** 연결 | 구독↔계정 바인딩, 복원 안정화 | `premium_service.dart:56`, `auth_service` link/delete 시 logIn/logOut | S | 결제 회귀 테스트 |
| 0.3 | **첫 실행 ToS+Privacy 동의 게이트** | GDPR 동의·약관 | 신규 consent 화면, `main.dart` 라우트, l10n | S | — |
| 0.4 | **privacy를 브라우저로 열기**(복사→`url_launcher`) | 접근성·심사 | `settings_screen.dart:543`, `pubspec` | XS | — |

### Tier 1 · 계정을 1급 시민으로 (P1 — 리텐션 토대)
| # | 작업 | 왜 | 파일 | 공수 |
|---|---|---|---|---|
| 1.1 | **프로필 화면 신설** (`/profile`) | 정체성·동기 | 신규 `profile_screen.dart`, 홈 진입점 | M |
| 1.2 | **온보딩 끝 "진행 저장하기" 계정 유도**(soft) | 듀오링고 핵심 루프 | `onboarding_*`, 홈 배너 | M |
| 1.3 | **자동 동기화** (백업버튼 제거, 로그인 시 자동) | 기기변경 무손실 | `cloud_sync.dart` 확장 + 트리거 | M | 데이터 정합성 |
| 1.4 | **동기화 범위 완성** (packs·bookshelf·custom·도장·streak) | 부분동기화 갭 | `cloud_sync.dart:24` payload 확장 | M |

### Tier 2 · 로그인 다양화 (P1/P2)
| # | 작업 | 왜 |
|---|---|---|
| 2.1 | **이메일/비밀번호 로그인** + 검증·비번재설정 | Google 계정 없는 사용자 |
| 2.2 | 계정 병합(merge) 처리 | 익명→이메일/Apple 충돌 |

### Tier 3 · 소셜·리텐션 (P2 — 듀오링고 차별점)
| # | 작업 | 왜 |
|---|---|---|
| 3.1 | **푸시 알림(FCM)** streak 리마인더 | 복귀 트리거 |
| 3.2 | 계(契) UI 완성(마당·스티커·리더보드) | 소셜 루프 (CLAUDE.md Tier 3c~) |
| 3.3 | 공개 프로필·팔로우 | 소셜 그래프 |

### Tier 4 · 운영·회원관리 (P3)
| # | 작업 | 왜 |
|---|---|---|
| 4.1 | 데이터 export 자동(GDPR 이동권) | 법규 편의 |
| 4.2 | 신고·모더레이션 CF + 어드민 | gye reports 처리 |
| 4.3 | 연령 게이트·COPPA 동의 흐름 | 미성년 보호 |

---

## 5. 즉시 진행 (이번 세션)

Tier 0 = 가장 작고(공수 XS~S) 출시에 직결되며 리스크 낮음.
**0.2(RevenueCat logIn) + 0.4(privacy 열기) + 0.3(동의 게이트)** 는 순수 Dart로 안전하게 구현·테스트 가능.
**0.1(Apple)** 은 코드 작성은 가능하나 인증서·실기기 검증이 Jin 환경 의존.

→ **진행 트랙은 Jin이 선택** (다음 단계에서 질문). 선택 즉시 해당 트랙을 `flutter analyze`/`flutter test` 통과까지 구현.

---

## 부록 · 검증 명령

```bash
flutter gen-l10n && flutter analyze lib/ && flutter test
# 계정 흐름 실기기(2계정): 익명→Google링크→백업→복원→삭제→재익명
# iOS: Apple Sign-In 실기기(Jin Apple Dev 계정 필요)
```
