# Phase 5.2 Handover — stately-rising-jongga (홈 진입로 + Endpoint UI)

> ✅ **실행완료 — 코드 구현 완료** (2026-06-03 아카이브)
> 홈 진입로·Endpoint UI 코드는 끝났고 `lib/`에 반영·검증됨 (`flutter analyze` 0 · `flutter test` 218 통과).
> 남은 운영/배포(Cloud Function·Firestore rules, 실기기 QA, 스토어 등록)는 → [`../IMPROVEMENT_PLAN_2026-06-03.md`](../IMPROVEMENT_PLAN_2026-06-03.md) TRACK 0 으로 이관.

> **세션**: 2026-06-01 · Claude
> **상위 plan**: `docs/plans/stately-rising-jongga.md` §6.5 (책 한 컷)
> **상태**: 코드 작성 완료 — Phase 5.1 deferred 두 가지 처리

---

## 1. 변경 요약 (TL;DR)

Phase 5.1 에서 deferred 된 **홈 화면 진입로** 와 **Settings 의 Cloud
endpoint UI** 추가. 사용자가 책 한 컷·책장·퀘스트에 카드로 접근, Jin 이
별도 코드 없이 UI 에서 Cloud Function URL 변경 가능.

| 영역 | 파일 | 변경 |
|---|---|---|
| 홈 | `lib/screens/home_screen.dart` | `_ModulesGrid` 에 **3 신규 카드 + 1 빈 셀** 추가 — 책 한 컷, 내 책장, 특별 퀘스트 |
| 설정 | `lib/screens/settings_screen.dart` | `_endpointCtrl` (TextEditingController), `_saveEndpoint()`, "Cloud-Analyse-Endpoint" 섹션 (TextField + Save 버튼) |
| 설정 | `lib/screens/settings_screen.dart` | + `BookAnalysisService` import |

신규 파일 없음. 신규 l10n 키 없음 (Phase 5.1 에서 미리 추가됨).

---

## 2. 사용자가 본 변화

### 2.1 홈 화면 모듈 그리드 (이전 4개 → 7개)

```
┌─────────────┬─────────────┐
│ Hangul      │ Vokabeln    │   기존 1 행
├─────────────┼─────────────┤
│ Grammatik   │ Szenarien   │   기존 2 행
├─────────────┼─────────────┤
│ 📷 Buchseite│ 📚 Bücher.  │   ← 신규 (Phase 5.1 진입로)
├─────────────┼─────────────┤
│ 🏆 Quests   │             │   ← 신규 (Phase 4 진입로 + 빈 셀)
└─────────────┴─────────────┘
```

탭 → 라우트:
- 책 한 컷 → `/book`
- 내 책장 → `/bookshelf`
- 퀘스트 → `/quests`

### 2.2 Settings → "Cloud-Analyse-Endpoint" 섹션 신규

UI:
```
┌────────────────────────────────────────────┐
│ Cloud-Analyse-Endpoint                     │
│                                            │
│ URL der Cloud Function (DeepL + OKT).      │
│ Leer = nur Offline-Grammatik.              │
│                                            │
│ ┌──────────────────────────────────────┐   │
│ │ https://us-central1-…/analyze_korea… │   │
│ └──────────────────────────────────────┘   │
│                                            │
│                       [💾 Speichern]       │
└────────────────────────────────────────────┘
```

저장 동작:
1. `Storage.setBookAnalysisEndpoint(url)` — 영구 저장
2. `BookAnalysisService.setEndpoint(url)` — 즉시 적용 (재시작 안 해도 됨)
3. SnackBar 표시: "Endpoint gespeichert."

빈 입력 = 오프라인 stub 만 사용. Jin 이 Cloud Function 배포 안 한 상태에서도
앱 작동 (Phase 5 설계 그대로).

---

## 3. Closed Testing 시점에서의 사용 흐름

Jin 이 Cloud Function 배포한 후:

1. 앱 시작 → 홈 → Settings
2. "Cloud-Analyse-Endpoint" 섹션에 Functions URL 붙여넣기
   (예: `https://us-central1-ko-lernen-app.cloudfunctions.net/analyze_korean_text`)
3. [Speichern] 탭 → 즉시 적용
4. 홈 → 책 한 컷 카드 → 사진 분석 → 단어/번역 풀로 동작

배포 안 한 상태:
- 홈 → 책 한 컷 → 사진 분석 → "Server nicht erreichbar — nur
  Grammatikmuster offline erkannt" 배너 + 31 grammar 패턴만 표시
- Settings 의 endpoint TextField 비워두면 됨

---

## 4. Jin 로컬 검증

```bash
flutter pub get
flutter gen-l10n
flutter analyze
# 기대: 0 issues

flutter test
# 기대: 197+ 케이스 모두 통과 (회귀 0)
```

실기기 (SIM unlock 후):
1. 홈 진입 → 모듈 grid 에 3 신규 카드 보임 (7번째 셀은 비움)
2. 책 한 컷 카드 탭 → /book 정상 진입
3. 책장 카드 탭 → 빈 상태 (`bookshelfEmptyTitle`) + CTA 정상
4. 퀘스트 카드 탭 → /quests 정상 진입
5. Settings → 아래쪽 "Cloud-Analyse-Endpoint" 섹션 보임
6. URL 입력 + Save → SnackBar 표시 → 재실행 시 URL 보존 확인

---

## 5. 변경 파일 목록 (커밋 시)

```
수정:
  docs/plans/stately-rising-jongga-phase5_2-handover.md  (신규)
  lib/screens/home_screen.dart       (+24 lines, 3 cards + 1 empty cell)
  lib/screens/settings_screen.dart   (+50 lines, endpoint section + ctrl + _saveEndpoint)
```

---

## 6. Closed Testing 출시 직전 남은 작업

Phase 5.2 완료 → Jin 영역만 남음:

- [ ] **마스코트 백업 복원 확인** (직전 세션 완료, 시각 검증만)
- [ ] **CSV 백업 삭제 확인**
- [ ] **Firestore rules 배포** — `firebase deploy --only firestore:rules`
- [ ] **Cloud Function 배포** (선택) — DeepL 키 + `firebase deploy --only functions`
- [ ] **실기기 검증** (SIM unlock 후 8 단계 시나리오)
- [ ] **Privacy policy 업데이트** — 카메라 + DeepL 명시 (Phase 8)
- [ ] **Data Safety 업데이트** — Camera/Photos 항목 추가
- [ ] **AAB 빌드** — `flutter build appbundle --release --obfuscate ...`
- [ ] **Play Console Closed Testing 트랙** — 업로드 + 테스터 5~10명

---

**작성**: Claude
**검토 대기**: Jin
**커밋 권한**: Jin 명시 요청 시
