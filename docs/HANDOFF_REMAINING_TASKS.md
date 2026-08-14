# 인수인계: 맥 불가 → Windows/CI 작업 목록

> **대상**: Windows 랩탑 또는 CI 환경에서 처리해야 할 잔여 작업  
> **작성**: 2026-08-14 17:00 (Antigravity, Mac 세션)  
> **기준 커밋**: `ae024af6` (main)

---

## 1. Linux 골든 재생성 (CI 전용)

### 배경
- 골든 테스트 13개가 `skip` 처리됨 — Linux 환경 정본이라 맥 폰트 렌더링과 달라 맥에서 `--update-goldens` 하면 안 됨.
- 현재 전체 스위트: **3,382 green, skip 13 (Linux 골든)**.

### 절차
```bash
# CI 도커 또는 Linux 머신에서:
cd ko_lernen_app
flutter pub get
flutter test --update-goldens test/goldens
git add test/goldens/
git commit -m 'chore: regenerate Linux goldens (ae024af6 기준)'
git push
```

### 검증
```bash
flutter test test/goldens  # 13/13 green이어야 함
flutter test               # 전체 3,382+13 = 3,395 green, skip 0
```

---

## 2. Jin 실기기 검증 항목

아래는 안드로이드 실기기에서 Jin이 직접 확인해야 할 항목:

### 2-1. 매트(크림) 배경색 (#FBF5EB)
- **확인 장소**: Today 탭, 홈 배경, 설정 화면
- **기대**: 순백이 아닌 따뜻한 크림색 매트 배경
- **위험**: 일부 AMOLED 패널에서 미세하게 달라 보일 수 있음

### 2-2. 스와이프 판정 손맛
- **확인 장소**: 
  - Legacy Vocab (`/vocab/legacy`) — 플립카드 스와이프
  - Custom Pack Play (`/custom_pack/play`) — 플립카드 스와이프
  - Review Session (AppShell 4탭 → 복습) — 탭 플립 → 스와이프
- **테스트 시나리오**:
  1. 카드 탭/플립 **전** 좌우 스와이프 → 카드 안 움직여야 함 (flipgate)
  2. 카드 탭/플립 **후** 우측 스와이프 → "알아요" 판정 + 다음 카드
  3. 카드 탭/플립 **후** 좌측 스와이프 → "몰라요" 판정 + 다음 카드
  4. 판정 후 다음 카드가 **앞면(한국어)**으로 리셋되는지

### 2-3. 한국어 카드 글씨 크기 (§C 리뷰)
- **이전 문제**: "한국어카드일때 글씨 너무 크고 독일어일때 너무 좀…" (Jin 2026-08-12)
- **수정**: 앞/뒷면 크기비를 1.3배 이내로 조정 (review_session L540–558)
- **확인**: 앞면 한국어와 뒷면 독일어가 같은 카드로 자연스럽게 보이는지

---

## 3. Jin 결정 대기 2건

### 3-1. §F-2 아바타 정지 이미지 적용 여부
- **현재**: 캐릭터 클립(영상) 유지 중
- **질문**: 프로필 등에서 정지 이미지(PNG)로 교체할지?
- **대기 상태**: Jin 재확인 필요

### 3-2. §G level·preview 무수술 승인
- **현재**: 기존 코드 유지
- **질문**: 레벨/프리뷰 화면을 현재 상태로 승인할지?
- **대기 상태**: Jin 재확인 필요

---

## 4. 배포 전제조건 체크리스트

| # | 항목 | 상태 | 비고 |
|---|---|---|---|
| 1 | 전체 테스트 green | ✅ 3,382+skip13 | Linux 골든 제외 |
| 2 | Linux 골든 재생성 | ❌ CI 필요 | §1 참조 |
| 3 | 실기기 매트 확인 | ⏳ 진행 중 | §2-1 |
| 4 | 실기기 스와이프 확인 | ⏳ 진행 중 | §2-2 |
| 5 | §F-2, §G 결정 | ❌ Jin 대기 | §3 |
| 6 | `flutter analyze` 0 issues | ✅ | 확인 완료 |

### 배포 런북 (§6.2)
배포는 위 1~6 전부 ✅ 후:
```bash
flutter build appbundle --release
# Play Console → Internal Testing → 업로드 → 프로모션
```

---

## 5. Phase 4 삭제 목록 (배포 1릴리스 후)

배포 후 안정화 확인되면 정리:
- `LegacyAppShell` (구 홈 셸)
- `home_screen.dart` (구 홈)
- `wordle_screen.dart` (구 워들)
- 기타 미사용 위젯/서비스

---

## 6. 현재 코드베이스 건강 상태

```
커밋: ae024af6 (main, pushed)
flutter analyze: 0 issues
flutter test: 3,382 green, skip 13
flipgate 센서: 8건 (3화면 × 좌우 + 2화면 리셋)
파괴-복원: 전 센서 실측 통과
```
