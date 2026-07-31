# 세션 2026-07-31 — 온보딩 캐릭터 선택 + 책장 앱바 UI 수정

**범위:** Jin 실기기(**M2101K6G / Redmi Note 10 / Snapdragon 678 / Android 12 / MIUI**, adb `9053622f`) 스크린샷 피드백 → ① 책장 앱바 제목 잘림 ② 마스코트 선택 화면 재설계(세로·영상·확대) + "1초 보이고 한쪽만 보임" 버그.

---

## 1. 책장(Bookshelf) 앱바 제목 잘림 — 커밋 `62c8349`

- **증상:** `Mein Bücherregal`이 `Mein Büch…`로 잘림.
- **원인:** 채워진 상태 앱바가 뒤로가기 + 액션 아이콘 **4개**(검색·목록추가·다운로드·카메라)로 꽉 참 → 제목 폭 부족. 검색·목록추가는 스포트라이트 코치마크(`_searchKey`/`_createKey`) 하이라이트 타겟이라 숨길 수 없고, 카메라는 "책 한 컷" 플래그십 → **아이콘 오버플로 메뉴화 불가**.
- **수정(`lib/screens/bookshelf_screen.dart`):** 제목을 `FittedBox(fit: scaleDown, alignment: centerLeft)`로 감싸 **자르는 대신 폭에 맞춰 축소** + `titleSpacing: 0`으로 뒤로가기~제목 기본 16px 여백 회수(대부분 기기에서 원래 크기 유지). 빈/채워진 상태 앱바 **둘 다** 적용 → 마지막 팩 삭제로 상태 전환 시 제목 위치 안 튐.
- `flutter analyze lib/screens/bookshelf_screen.dart` → No issues found.

---

## 2. 마스코트 선택 화면 재설계 — 커밋 `56ab2ac`(동시 세션이 함께 커밋)

**요청:** 가로→세로 배열, 이미지 확대, 영상 사용(까치 `magpie_perched.mp4`, 호랑이 `tiger_rise.mp4`).

**변경(`lib/screens/character_selection_screen.dart`):**
- `Row` → `Column`(위 호랑이 / 아래 까치), 미리보기 **100 → 150**.
- 호랑이 카드 클립 `CharacterClips.tigerBob` → **`tigerRise`**(`assets/video/character/tiger_rise.mp4`). 까치는 이미 `CharacterClips.magpiePerched`(영상)였음 — 정적으로 보이던 건 `videoReady`/실패 시 `Mascot` **폴백**이었을 뿐.
- 상단 `HanokHeader`의 `loopAsset` 제거 → **정지 포스터**(디코더 절감).

### 🔴 핵심 버그: "동영상으로 바뀌었는데 1초 보이고 쌤쌤이(까치)만 보여"

- **근본 원인 = Android MediaCodec 디코더 reclaim.** 이 기기(SD678/MIUI)는 **동시 H.264 디코더(960×960) 2개를 못 버팀.** 나중에 뜬 영상이 먼저 뜬 것의 디코더를 회수 → 먼저 빌드된 것(호랑이, 위)이 **~1초 뒤 빈 화면**.
- **logcat 증거:** `D/MediaCodec(…): keep callback message for reclaim` + `I/ExoPlayerImpl(…): Release …`.
- 헤더 영상 제거(3개→2개)로도 **부족** — 2개도 초과.
- **해결:** 선택 전 미리보기를 **한 번에 한 캐릭터만** 영상 재생, 나머지는 호흡하는 정적 포스터(`Mascot animate:true`).
  - `_livePreview`(`MascotKind`) 상태 + `Timer.periodic(3.2s)`로 호랑이↔까치 **교대**(선택 전에만, `_selected != null`이면 정지).
  - `_CharacterCard`에 `live` 파라미터 추가: `onTap != null && live` → `CharacterClipPlayer`, 아니면 `Mascot`. 교대 시 비활성 카드의 `CharacterClipPlayer`가 dispose되며 디코더 해제.
  - **동시 디코더 항상 1개** → 어느 쪽도 사라지지 않음.

**동시 세션 병합:** 같은 파일에서 다른 세션이 `_proceed`를 `pushReplacementNamed('/')` → `OnboardingLevelScreen`으로 변경(캐릭터 선택을 튜토리얼 뒤·레벨 앞으로 재배치)하며 내 `_livePreview` 변경과 함께 `56ab2ac`로 커밋. 작업 트리 clean 확인.

> 관련 부수 커밋: `e55b733 fix(onboarding): 크림 배경 위 선택지 카드 대비 확보 (1.01:1 → 3.1:1)` — 직전 세션의 온보딩 카드 대비(`SoriColors.lightBorderStrong` 토큰 도입) 수정이 이 세션 중 동시 세션에 의해 커밋됨.

---

## 검증 / 배포

- `flutter analyze` 통과(편집 2파일). `flutter run -d 9053622f` 총 4회 배포 — 중간 1회 **기기 sleep으로 ADB drop**(`No supported devices found ... '9053622f'`) → 재연결 후 성공.
- Jin 실기기 육안 확인: 캐릭터 세로/영상/교대 재생 정상. (책장 제목 수정은 첫 배포에 포함, 육안 미확언.)
- ⚠️ **교대 간격(3.2s)** 체감·튜닝은 Jin 판단 여지.

## 배포 워크플로 메모(재현용)

- `flutter run`은 대화형 TTY가 없어 **install+launch 후 자동 detach(exit 0)**. 설치된 앱은 폰에 잔존(재실행 가능). 이 하네스에선 저장만으로 hot reload 불가 → 변경 시 재배포 필요.
- 기기 sleep/USB 끊김 시 ADB에서 사라짐 → 화면 켜고 잠금 해제 + USB 재연결(디버깅 허용) 후 재배포.

## 후속 후보

- 교대 대신 "**둘 다 정적 포스터 + 탭 시 영상**" 방식(Jin 선호 시).
- 앱 전역에서 **다중 영상 동시 재생** 지점 점검(같은 reclaim 위험) — home tiger 밴드 + 다른 클립 동시 표시 등.
- 책장 앱바를 "＋" 통합 메뉴로 정리하면 제목 항상 원래 크기 가능(코치마크 재배선 필요, 별도 작업).

**변경 파일:** `lib/screens/bookshelf_screen.dart`(커밋 `62c8349`) · `lib/screens/character_selection_screen.dart`(커밋 `56ab2ac`, 동시 세션과 공동).
