# Hangul Sori — 콘텐츠 UI/UX 전면 마감 계획

## Context

Jin이 8/18에 271커밋 규모로 만든 "콘텐츠 UI 바이블" 작업(PR #83)은 `01bd8849`로 main에 머지됐다. 그런데 Jin이 화면에서 확인한 결과, 요청 8건 중 상당수가 여전히 안 고쳐졌거나 아예 반영이 안 보였다.

**"하나도 안 바뀌었다"의 진짜 원인은 코드가 아니라 실행 환경이었다.** 세션 중 확인:

- 새벽 3:52 `flutter run -d chrome`(PID 14516)은 메인 저장소를 물고 있었고, 그 저장소는 PR83 작업이 없는 브랜치였다
- 오전 9:14 `flutter run -d web-server`(PID 16269)는 `.claude/worktrees/chaekgado-scroll-overflow` **워크트리**를 물고 있었다 — 역시 다른 브랜치
- PR83 코드가 있던 `ko_lernen_app-p7-scroll` 워크트리에서는 서버가 안 돌고 있었다
- 8080은 응답 없음

즉 Jin은 **한 번도 바이블 코드를 본 적이 없다.** 이 계획의 첫 실행 항목은 그 서버들을 정리하고 올바른 체크아웃에서 띄우는 것이다.

그와 별개로, 코드 리뷰로 확인된 미해결 결함이 실재한다. 아래는 전부 `origin/main`(29842a50)에서 실측한 것이다.

### 실측된 사실 (추정 아님)

**소리 — 가장 큰 원인은 TTS가 아니라 Android 오디오 라우팅이다.**
`Storage.sndRespectSilent`가 기본 `true`이고, [audio_policy.dart:204-215](lib/services/audio_policy.dart#L204-L215)가 그걸 `AudioContextConfig(respectSilence: true).buildAndroid()`에 그대로 넘긴다. Android에서 `respectSilence: true`는 `USAGE_NOTIFICATION_RINGTONE`으로 매핑된다. **프리미엄 mp3까지 포함해 앱의 모든 소리가 벨소리 스트림으로 나간다** — 진동 모드면 전부 무음이고 미디어 볼륨 슬라이더가 안 먹는다. "letter of the day 소리 안나와", "Hangul Pronounce 아예 안나온다"의 1순위 원인이다.
이 수정은 로컬 브랜치 `fix/android-audio-level-balance-2026-08-19`(f696256d)에 이미 있지만 **푸시도 PR도 안 됐다.** main에는 없다.

**"전부 das" — 텍스트가 아니라 음성이 독일어다.**
TTS 호출 70곳을 전수 확인했다. **독일어 텍스트를 speak()에 넘기는 곳은 한 군데도 없다.** 원인은 4단 폴백(`flutter_tts`)이 독일어 음성으로 한국어를 읽는 것이다:
- `_applyFallbackLanguage`가 `setLanguage`의 반환 코드를 버리고 `_fallbackLanguage`를 메모이즈한다 → ko-KR이 실패해도 성공으로 기록되고, 이후 모든 재시도가 억제된다
- `_trySelectKoreanVoice`가 `setVoice`로 음성을 고정하는데, 고정된 Voice가 이후 `setLanguage`를 무력화한다
- `getVoices` 재시도가 250ms 한 번뿐 — Chrome은 음성 목록을 비동기로 채우므로 거의 항상 빈 목록을 받고 독일어 기본 음성으로 떨어진다

**무음 — quota 소진이 폴백까지 차단한다.**
`blockSpeechFallback`이 `resource-exhausted`에서 `null`을 반환해 완전 무음이 된다. 한도는 30 synth/기기/일. 한글 탭 진입 시 자모 40개를 프리페치하고, 듣기 시나리오 한 편이 수십 줄이라 **한 세션에 하루치가 소진되고 그 뒤 24시간 전부 무음**이 된다. 게다가 실패 이유가 UI에 전혀 안 뜬다 — `TtsService.lastError`는 9곳에서 쓰이는데 **읽는 위젯이 0개**다.

**프리미엄 음성 누락은 4,000줄이 아니라 1,464쌍이다.**
마지막 검증 상태는 `53595787`에서 expected 9,997 / missing 0. 현재 코퍼스는 11,438쌍(149,213자). **누락 1,464쌍 / 30,362자.** 여기에 미수집 소스 `word_relations.json` 197쌍이 더 있다. Chirp3-HD 기준 **약 $1**. (전체 v4 재생성도 $4.48밖에 안 된다.) 자모 캐리어 5개는 이미 Storage에 있다 — 무음 원인이 아니다.

**키 드리프트.** `GrammarStudyCopy.speakKorean`은 예문을 공백으로 join하고(`'갔어요. 먹었어요. 했어요.'`), `tool/generate_tts.py:210-222`는 CSV 원본을 합성한다(`'갔어요. / 먹었어요. / 했어요.'`). sha1이 달라 영구 miss. 오늘은 214행 중 1행뿐이지만 구조적 함정이다.

**웹.** CI가 `flutter build web --release`를 main에서 돌리고 통과한다([ci.yml:233](.github/workflows/ci.yml#L233), PR에서는 skip). 컴파일은 되고 **런타임에 `File`/`getTemporaryDirectory`가 던진다** → TTS 1~3단 전부 실패, 공유는 PNG 없이 조용히 실패.

**타이포.** `lib/screens`+`lib/widgets`에 raw `TextStyle(` 463곳, `fontSize:` 리터럴 346개가 **31종** 값으로 흩어져 있다. 45%가 11~13pt(문서화된 하한 12.5 미만)이고 위쪽은 40→56→92→140으로 끊긴다. 한 글자에 **네 개의 독립 배율**이 곱해진다: `soriFillSize`(높이 비율) × `soriComfortScale`(1.0~1.10, letterSpacing까지) × `soriStudyScale`(최대 1.35) × OS 배율, 그리고 일부는 `FittedBox(scaleDown)`으로 한 번 더 줄인다. 정본 램프도 `SoriTextTheme`과 Material `TextTheme` 둘이 경쟁한다.

**문법 필터는 필터가 아니다.** 214행에 타입이 **213종**, 레벨 간 공유 타입 **0개**. Level×Type 1,278쌍 중 **1,065쌍(83%)이 0행**이고, 비어있지 않은 213쌍 중 **212쌍이 정확히 1장**이다. Apply 핸들러는 결과가 비면 **적용도 닫기도 안 하고** 열린 모달 뒤에 500ms 스낵바만 띄운다(그 스낵바는 모달이 current route라 자동 소멸 타이머가 안 걸린다).

**책갈피 토스트.** `hideCurrentSnackBar()` 직후 `showSnackBar()`는 교체가 아니라 **큐잉**이다(hide는 250ms 역방향 애니메이션을 시작할 뿐, dismissed에서야 제거된다). 연타하면 사슬처럼 쌓인다. `notify:false`는 문법·스몰톡 2곳뿐이고 듣기·복습·단어팩·초성·책결과·시나리오는 여전히 토스트를 띄운다.

**제스처 충돌.** `SoriContentFeed`가 raw `Listener(onPointerUp:)`으로 280ms 내 두 번을 세어 좋아요를 쏜다. `Listener`는 아레나 참가자가 아니라서 **스피커 버튼을 두 번 눌러 다시 듣는 자연스러운 동작이 좋아요까지 토글**한다. 스피커를 누른 채 살짝 세로로 밀면 `onNext`(앎 처리 + 다음)가 커밋된다.

**의도한 결과:** Jin이 실제로 공부하는 13개 콘텐츠 화면에서 — 소리가 정확한 프리미엄 한국어로 나오고, 글자 위계가 한 벌이며, 한국어가 어절 중간에서 안 잘리고, CTA가 녹청 하나이고, 책갈피가 채워지며 토스트가 안 뜨고, 공유가 두루마리 PNG를 낸다.

---

## 확정된 결정

| 항목 | 결정 | 근거 |
|---|---|---|
| TTS 폴백 | **4단(`flutter_tts`) 완전 제거** | Jin: "기계음 안나오고". 결함 3개(#1 setLanguage, #2 setVoice, #5 오디오 세션)가 전부 4단 내부에 산다. 티어를 지우면 결함도 같이 사라진다 |
| 프리미엄 못 받을 때 | **무음 + 보이는 사유 배너**(로봇 음성 아님) | 오프라인은 일시적·조치 가능. mp3 캐시는 영구라 한 번 들은 건 오프라인에서 계속 재생됨 |
| 문법 Listen | **보이는 예문 하나만 재생** (`speakKorean` 삭제) | UI/오디오 불일치와 키 드리프트를 동시에 해소. 모든 발화 문자열이 `splitStudyPhrases` 원소와 일치 |
| CTA | **녹청 `SoriColors.primary` #1F7A6B 하나** | `contentCta`는 이미 `primary`. 듣기 블루는 철회됨 |
| 황(gold) | **XP/스트릭 전용** | 카드에서 전부 제거 |
| 배율 | **ambient `TextScaler` 하나** | `soriStudyScale`·`soriFillSize` 삭제 |
| 브랜치 | `origin/main`(29842a50)에서 새로 딴다 | PR83 머지 완료, cursor 브랜치 정리됨 |

---

## Phase 0 — 실행 환경 정리 (코드 변경 없음, 최우선)

1. **stale 서버 2개 종료**: PID 14516(`-d chrome`, 3:52), PID 16269(`-d web-server`, 9:14). 둘 다 잘못된 브랜치를 물고 있다.
2. **이 계획서를 main에 커밋·푸시** (Jin 지시). `docs/CONTENT_UIUX_FINISH_PLAN_2026-08-19.md`로 저장해 문서 단독 커밋으로 main에 올린다. main이 보호돼 직접 push가 거부되면 문서 전용 PR을 즉시 열어 머지한다.
3. **전용 워크트리 생성** — 메인 저장소(`chore/hanok-assets-2026-08-19`, b8c6a13d, clean)는 **건드리지 않는다.** 모든 코드 작업은 이 워크트리 안에서만 한다:
   ```
   git worktree add ../ko_lernen_app-uiux -b feat/content-uiux-finish origin/main
   ```
   Phase별 PR은 전부 이 브랜치 계열에서 나간다. 메인 저장소 워크트리와 `ko_lernen_app-p7-scroll`·`.claude/worktrees/chaekgado-scroll-overflow`는 읽기 전용으로 둔다(Phase 2의 `5229be29` 회수만 예외).
4. Jin이 볼 실행 명령을 하나로 고정하고, **실행 전 항상 `git rev-parse --abbrev-ref HEAD`를 출력**해 브랜치를 눈으로 확인한다.

> ⚠️ 웹은 검증 보조 수단일 뿐이다. Android 라우팅 버그·프리미엄 mp3·공유는 **실기기에서만** 제대로 확인된다. 최종 검증은 Android 실기기로 한다.

---

## Phase 1 — 소리를 되살린다 (PR 1)

Jin의 최다 불만이고 원인이 UI 밖에 있으므로 가장 먼저 간다. 이 단계에서는 4단을 **아직 지우지 않는다** — 코퍼스가 완성되기 전에 지우면 로봇 음성 대신 무음이 된다.

**1.1 Android 라우팅** — 로컬 `fix/android-audio-level-balance-2026-08-19`(f696256d)에서 [audio_policy.dart](lib/services/audio_policy.dart) 수정을 회수한다. `buildAndroid()`에 `respectSilence`를 넘기지 않는다. iOS는 현행 유지(ambient/playback 분기).
- 래칫 추가: `AudioContextConfig(...).buildAndroid()`가 `respectSilence: true`로 생성되지 않음을 소스 스캔으로 고정.

**1.2 언어·음성 선택 정직하게** — [tts_service.dart](lib/services/tts_service.dart)
- `_applyFallbackLanguage`: `setLanguage` 반환값을 확인하고 **성공했을 때만** `_fallbackLanguage`를 메모이즈
- 언어가 바뀌면 `setVoice` 고정을 해제하거나 재발급
- `_trySelectKoreanVoice`: 250ms 단발 재시도 → 지수 백오프 폴링(최대 ~2s). 이것만으로 Chrome의 독일어 음성 문제가 사라진다

**1.3 무음을 없앤다**
- `resource-exhausted`에서 `blockSpeechFallback`으로 죽이지 않는다. quota 소진은 로봇 음성을 **써야 하는** 상황이다(4단이 살아있는 동안)
- `unavailable: "TTS audio is not available."`은 CF의 idempotency 경합이라 **일시적**이다 → 1s/2s 두 번 재시도 후 보고
- `unauthenticated`/`failed-precondition`을 명시 처리. `58379721`이 익명 인증을 pre-splash 밖으로 미뤘으므로 초기 탭이 인증과 경쟁한다 → 5s 바운드로 `ensureSignedIn` 대기 후 1회 재시도
- quota 메모: `resource-exhausted` 후 다음 UTC 자정까지 12s 왕복을 건너뛴다

**1.4 모든 읽기에 시한을 건다**
- Storage `getData` → 8s 타임아웃 후 3단으로 진행 (현재 무제한)
- 1단 파일 I/O → 2s
- callable 시퀀스 전체에 20s 예산 하나 (현재 3×12s = 36s 누적 가능)
- **해결 레이스에 데드라인 추가** — `Future.any`에 25s 팔을 하나 더 붙여 `speak()`가 반드시 정착하게 한다

**1.5 실패를 보이게 한다**
- `lastError`(읽는 위젯 0개) → `ValueNotifier<TtsUnavailable?> unavailable` + `ValueNotifier<int> resolving`
- 신규 `lib/widgets/sori/tts_unavailable_banner.dart`, 앱 셸에 1회 마운트
- ARB 키를 **두 파일 모두**에 추가: `ttsUnavailableQuota`, `ttsUnavailableOffline`, `ttsUnavailablePending`, `ttsUnavailableChannelOff`(설정→Ton 딥링크), `ttsRetry`. `test/l10n_parity_test.dart`·`test/arb_l10n_guard_test.dart`가 항상 켜져 있다
- `speak`/`speakSlow`의 `Future<bool>` 시그니처는 유지 (호출 70곳, 변경 없음)

**1.6 위생**
- `_ensureSpeechAudioContext`: `await` **전에** 플래그를 세워 재시도가 막히는 버그 수정 → 성공 후에만 설정. `speak()` 진입 시 1회 호출, `kIsWeb`이면 no-op
- `_prefetchAttempted.add(key)`가 시도 **전에** 기록해 일시적 실패가 세션 내내 그 문자열을 봉인한다 → 성공 시에만 기록(또는 60s 음성 TTL)
- 웹 런타임 가드: `_ensureCacheDir`이 `kIsWeb`이면 즉시 `null`. 1단을 메모리 LRU(≤64개/16MB)로

**검증:** Android 실기기를 **진동 모드**로 두고 오늘의 글자 → 소리가 미디어 스트림으로 나오고 미디어 볼륨 슬라이더에 반응해야 한다. 콜드 런치 직후(인증 미완료) 오늘의 글자 → 재생돼야 한다. 설정→Ton→Aussprache 끄기 → 무음이 아니라 배너가 떠야 한다.

---

## Phase 2 — 두루마리 공유 회수 (PR 2)

이미 만들어져 있고 독립적이라 싸게 이긴다. `feat/p7-share-scroll` **`5229be29`**(워크트리 clean, 커밋 완료)에 721줄 렌더러 + 272줄 테스트가 있다. 대상 5개 파일이 `origin/main`과 blob 동일이라 충돌 0.

```
git restore --source=5229be29 --worktree --staged -- \
  lib/widgets/sori/share_slip.dart \
  lib/widgets/sori/chaekgado/scroll_palette.dart \
  lib/widgets/sori/chaekgado/scroll_sheet.dart \
  lib/widgets/sori/dancheong_stamp.dart \
  lib/widgets/sori/hanok/hanji_texture.dart \
  test/content_share_slip_test.dart
```
`docs/SESSION_LOG.md` 항목은 손으로 옮긴다(cherry-pick하면 여기서 충돌). 회수는 **단독 커밋**으로 둬서 서비스 재작성과 분리 리뷰한다.

**서비스 재작성** — [content_share_service.dart](lib/services/content_share_service.dart) (38줄 → ~30줄)
- `XFile.fromData(png, mimeType: 'image/png', name: 'hangul-sori-slip.png')` — `share_plus`가 io/web 양쪽에서 처리하므로 **`kIsWeb` 분기 불필요**, `dart:io`·`path_provider` import 삭제
- **`text:` 페이로드 제거.** 이게 Jin이 본 `N에 / Direction (to where?) / hangul-sori.com`이다. 이미지가 곧 메시지다. 부수 효과로 웹 성공률이 오른다(`navigator.canShare({files, text})`를 거부하고 `{files}`만 받는 브라우저가 있다)
- `contentShareBody`를 ARB 두 파일에서 제거하고 `lib/l10n/generated/*` 재생성(손으로 고치지 말 것)
- 죽은 `shareStoryText`(호출 0) 삭제
- `catch (_) {}` → `catch (error, stack)` + `debugPrint`, 그리고 **결과를 반환**해 호출 6곳이 기존 `shareError` 문자열을 띄울 수 있게 한다

**Jin에게 확인할 것:** "이 png는 내가 만들게" — 렌더러는 **전부 절차적으로 그린다.** 넘겨받을 PNG 파일이 없다. 세 해석 중 어느 쪽인지 물어야 한다: (A) 두루마리 배경/프레임 아트를 그려주고 앱이 그 위에 글자를 흘린다, (B) 도장 PNG를 말한다(이미 `assets/illustrations/stamps/`에 있고 공유 이미지가 지금 그걸 안 쓴다), (C) 이미지가 아예 없는 줄 알았다. **미응답 시 기본값:** 절차적 렌더러를 지금 출시하고, (A)를 위한 선택적 에셋 슬롯을 남긴다.

---

## Phase 3 — 디자인 시스템 코어 (PR 3)

화면을 만지기 전에 도구부터 만든다. 이 PR만으로는 시각 변화가 거의 없다.

**3.1 배율 권한을 하나로**
- `SoriTextTheme._base`에서 `* _deviceScale` 제거(`fontSize`와 `letterSpacing` 둘 다) → `lib/main.dart`의 `MaterialApp.builder`에 `SoriTypeScale` 하나를 설치해 `textScaler = os × soriComfortScale(width)`. letterSpacing이 배율을 안 타게 되고, Material `TextTheme` 텍스트도 드디어 같이 스케일된다. `soriComfortScale` 커브 자체는 유지(`test/sori_tablet_responsive_contract_test.dart`가 고정)
- `soriStudyScale`·`SoriStudyScale`·`_StudyTextScaler` **삭제**(호출 17곳). 1.35 × 1.10이 태블릿 폭주의 원인. `SoriStudyClamp`(폭)는 정당하므로 유지
- `soriFillSize`·`soriStudyTypeScaleHeight`는 Phase 4에서 호출부(65곳)를 걷어낸 뒤 삭제
- `soriUniformFitSize`는 **유지** — 덱 전체를 실측해 한 크기를 내는 올바른 축소이고, 권한이 하나가 되면 그 실측이 비로소 정직해진다
- `lib/theme.dart::_buildTextTheme`가 `SoriTextTheme`에서 **파생**되게 한다(현재는 별개 램프를 재기술하고, `displayLarge`가 Pretendard에 없는 w900이다)

**3.2 콘텐츠 램프** — `SoriTextTheme`에 추가. 40→56→92→140 구멍을 메우고 하한을 올린다.

| 역할 | 크기 | 굵기 | height | 용도 |
|---|---|---|---|---|
| `koHero` | 56 | w700 | 1.10 | 자모/글자 한 개 (한글 카드 앞면, 오늘의 글자 140→56) |
| `koDisplay` | 30 | w700 | 1.28 | 플레이어의 한국어 블록 |
| `koDisplaySm` | 24 | w700 | 1.32 | 긴 한국어의 유일한 축소 단계 |
| `gloss` | 17 | w500 | 1.45 | 독일어·영어 뜻 |
| `glossSm` | 15 | w500 | 1.45 | 보조 뜻·노트 |
| `meta` | 12.5 | w600 | 1.35 | 진행·힌트 — **하한, 예외 없음** |

한국어 line-height 하한 1.25. 연속 배율이 아니라 **이산 3단계**다.

**3.3 한국어 줄바꿈** — [ko_wrap.dart](lib/widgets/sori/ko_wrap.dart) 재작성
현재 구현(`Wrap` + `softWrap:false` `Text` 조각들)을 전역 채택하면 안 된다: `height`를 파괴하고, 6px 고정 어절 간격이 폰트 space와 안 맞고, `maxLines`/`overflow`/선택을 죽이고, 긴 단일 토큰을 줄바꿈 대신 **페이드**시키고, **어절마다 semantics 노드를 하나씩** 만들어 TalkBack이 한국어를 단어 단위로 읽는다.
→ **단일 문단 + word-joiner 삽입**으로 재작성:
- `String soriJoinEojeol(String)` — 어절 **내부** 인접 한글 음절 사이에 `U+2060 WORD JOINER` 삽입. 실제 공백만 줄바꿈 기회로 남는다. WJ는 default_ignorable이라 글리프가 안 그려진다
- `maxWidth`보다 넓은 토큰만 joiner 없이 내보내 음절 단위로라도 접히게 한다(overflow 대신)
- `Text` 하나로 렌더하고 `semanticsLabel`에 **원본 문자열**을 준다. `maxLines`·`overflow`·`textAlign`·호출자의 `style.height`를 그대로 통과시킨다
- 파일명·클래스명 유지 → 기존 호출부(문법·스몰톡) 무수정
- ⚠️ `TextWidthBasis`는 해법이 아니다(보고되는 폭만 바꾸고 줄바꿈 기회는 안 바꾼다). 주석으로 남겨 재시도를 막는다

**3.4 단일 진입 위젯** — 신규 `lib/widgets/sori/content_type.dart`
- `SoriKoreanText(text, {max, uniformOver, maxLines, align})` — `{koHero, koDisplay, koDisplaySm}` 중 스냅, 덱 전체를 `uniformOver`로 받아 카드 간 크기를 통일(`test/vocab_pack_uniform_card_test.dart` 계약 보존), 3.3의 래퍼로 렌더, **`FittedBox` 절대 사용 안 함**
- `SoriGlossText(text)` — 길이에 따라 `gloss`/`glossSm`
- 한국어 줄 자체에 `SoriPressable`(이미 0.96 scale + elasticOut) 적용 → 바이블 §4 "단어 한 번 탭 = ?와 동일"의 듀오링고식 터치감

**3.5 피드 제스처** — [content_feed.dart](lib/widgets/sori/content_feed.dart)
`Listener`를 지우고, 제스처 표면을 기존 `Stack`의 **맨 아래(첫) 자식**으로 내린다. `RenderStack.hitTestChildren`은 앞에서 뒤로 훑다 첫 true에서 멈추므로:
- 스피커 버튼(`SoriPressable` = opaque)이 자기 44/48dp를 차지 → **두 번 탭하면 두 번 재생될 뿐 좋아요가 안 걸린다**
- 스피커 위에서 시작한 세로 드래그는 피드에 도달하지 않는다 → **임계값 조정 없이** 오작동 `onNext` 소멸
- 평문·한지는 hit-test false라 카드 본문은 여전히 아래 디텍터가 갖는다

그 디텍터 위에서 탭 지연 0을 유지하려면 **`onDoubleTap`을 쓰지 않는다** — `DoubleTapGestureRecognizer`는 아레나를 `kDoubleTapTimeout`(300ms)만큼 붙잡아 모든 자식 탭에 300ms를 더한다(바이블 <100ms 규칙 위반). 손으로 디스패치: 첫 탭 즉시 `onFlip()`, 280ms 내 두 번째 탭이면 `_fireLike()` + 두 번째 flip 억제.
- 화면 레벨의 카드 전체 탭 래퍼(`review_session:575` 등)를 제거해 아래 디텍터를 가리지 않게 한다
- `_commitPx` 64 → 88, `_commitVelocity` 700 → 850

**3.6 책갈피: 채우고, 토스트 안 띄운다** — [wordbook_add.dart](lib/widgets/sori/wordbook_add.dart)
- `addToWordbook`에서 `SnackBar` 블록과 `notify` 파라미터를 **삭제**, 반환형을 `Future<WordbookAddResult>`로. 호출 9곳 갱신
- 실패에만 `soriToast(...)` — **`removeCurrentSnackBar()`**(hide 아님)로 역방향 애니메이션을 건너뛰어 큐잉을 원천 차단, 1200ms
- 신규 공용 `SoriBookmarkStamp` — `bookmark_border_rounded` → `bookmark_rounded`(`SoriColors.like`), 180ms scale pop, `SoriMotion.reduceMotion` 게이트. `SoriContentActions`와 `AddToWordbookButton`(현재 채움 상태가 **아예 없다**) 양쪽에 사용
- `CustomPackService`에 `static final ValueNotifier<int> revision` 추가(`quickAdd`/`save`/`remove`에서 bump) → 스탬프가 `ValueListenableBuilder`로 자가 갱신. `containsKorean`은 동기·부작용 없음이라 `build`에서 안전
- `bookmarked:`를 8개 피드 호출부 전부에 전달(현재 3곳)
- ⚠️ `legacy_vocab`은 `Storage.vokFavorites`라는 **다른 저장소**를 같은 아이콘에 쓴다. 흡수는 데이터 마이그레이션이므로 **별도 후속**으로 미루고 `docs/SESSION_LOG.md`에 남긴다

**3.7 판정 라벨 · 네모 카드**
- `SoriContentFeed`에 `showJudgmentLabels`(기본 false). **`/review`만 true.** `hangul`·`vocab_pack`·`legacy_vocab`·`custom_pack_play`에서 라벨 제거. `listening_play`의 `knowLabel`은 판정이 아니라 "다음 줄"이므로 라벨 없는 `onNext`로 전환
- **접근성을 위젯 안으로.** 문법이 손으로 만든 `Semantics(customSemanticsActions:)`를 `SoriContentFeed`로 올려, 콜백이 non-null이면 `showJudgmentLabels`와 무관하게 항상 등록. 그러면 어떤 화면도 빠뜨릴 수 없다(WCAG 2.5.1 구조적 충족)
- `/review` 밖에서는 위로 플링이 SRS를 쓰지 않게 `onSkip`으로 매핑
- **네모 히어로 카드 제거** — `lib/widgets/sori/card.dart`에 `SoriCardVariant.bare`(패딩만, 면·그림자·라운드·좌측 액센트 바 없음) 추가. 플레이어 히어로에 적용. **선택 표면**(팩 그리드, `ChaekgadoShelfCase`, `ClozeOptionsList`, `_CharCell`)은 진짜 `SoriCard` 유지

**3.8 무료 정리**
- `test/typography_guard_test.dart` 6개 상한을 실측값으로 하향: w900 31→**28**, w800 155→**141**, Pretendard 94→**79**, screens raw TextStyle 409→**370**, 숫자 radius 54→**36**, screens raw AppBar 98→**84**
- 죽은 덱 위젯 삭제(호출 0): `swipe_card.dart`, `swipe_rails.dart`, `study_card_face.dart`. `deck_action_bar.dart`는 `deckActionKey()`만 `content_feed.dart`로 옮기고 삭제. 대응 테스트 4개 삭제
- 죽은 파라미터 2개: `_HangulCardFace.gradient`(호출 3곳이 서로 다른 값을 넘기는데 `build()`가 안 읽음), `StrokeCanvas.guideColor`(`_Painter`까지 전달되고 `paint()`에서 미사용)
- 고아 골든 삭제: `home_compact_360x800.png`, `home_expanded_1280x800.png`(참조하는 테스트 없음)

---

## Phase 4 — 콘텐츠 13개 화면 이관 (PR 4)

**화면당 커밋 1개**, 타이포·팔레트·bare 카드를 **한 번에** 처리해 같은 파일을 두 번 열지 않는다.

참조 구현이 이미 있다: **[listening_play_screen.dart](lib/screens/listening_play_screen.dart)는 raw `TextStyle(` 0개, `fontSize:` 0개**이고 `tt.koDisplay`/`tt.gloss`/`tt.meta`만 쓴다. 모든 커밋이 여기를 본다. `cloze_game_screen`·`satz_arcade_screen`도 이미 0이므로 확인만.

순서(부채 오름차순): `review_session`(4) → `scenario_player`(3) → `daily_char_sheet`(6) → `smalltalk`(8) → `vocab_pack`(12) → `custom_pack_play`(12) → `legacy_vocab`(15) → `hangul`(18) → `grammar`(19, Phase 5로 접음).

**화면별 체크리스트:** `soriFillSize` → `SoriKoreanText`/`tt.gloss`/`tt.meta` · 역할 텍스트를 감싼 `FittedBox(scaleDown)` 삭제 · raw `AppBar(` → `SoriAppBar`(16곳; 한글 화면은 `TabBar` bottom 슬롯 추가 필요) · `'Pretendard'` 리터럴 → 토큰 · w800/w900 → w700 · 히어로 `SoriCard` → `bare`.

**색 정리(같이 처리):**

| 위치 | 현재 | 변경 |
|---|---|---|
| `custom_pack_play:619` | `goldOnLight` (한자) | `s.textMuted` — 한자는 보상이 아니라 메타데이터 |
| `vocab_pack:676` | `tiger` (콤보 `ScorePop`) | `gold` — 보상 순간이고 카드가 아닌 떠오르는 팝 |
| `vocab_pack:1080,1111` | `warning` **보스 액센트** — Jin이 싫어한 그 황금 카드 | `primaryDark` #0E443B — "우리 컬러인 진한 그린", 더 깊게 = 더 어렵게 |
| `legacy_vocab:442,515` | `warning` 즐겨찾기 | `SoriColors.like`(석간주) — 책갈피와 같은 언어 |
| `legacy_vocab:545` | `warning` 건너뜀 칩 | `s.textMuted` |
| `legacy_vocab:1022` | `warning` reviewDue | `SoriColors.info` |
| `review_session:393` | raw gold `+N XP` | **`SoriBadge.xp(...)`** — 황은 유지(XP는 정당), raw 토큰만 제거 |
| `scenario_player:1179,1430` | `warning` 문법 액센트 | `primary` |
| `scenario_player:2183,2191` | `tiger` 롤플레이 헤더 | `contentCta` |
| `scenario_player:1049-1056` | 화자 색 5종 | 2종: `user = primary`, 나머지는 muted 잉크 말풍선. **이름**이 구분자 |

**한글 팔레트 — 3개 토큰 패밀리 7색 → 4색.** Jin이 직접 지목한 둘만 쓴다.
- **자음 = `primary` #1F7A6B**, **모음 = `info` #57799E**, 잉크 = `s.text`/`s.textMuted`, 종이 = `lightBg`
- `SoriColors.hangul` #A0524A를 [hangul_screen.dart](lib/screens/hangul_screen.dart)에서 **전부 제거**(14곳). 석간주는 앱 전역에서 `like`/하트 전용이라 카드 위 하트가 계속 읽힌다. `daily_char_sheet.dart`도 동일(4곳)
- `_DetailSheet`(:442)는 밝은 앱 위의 **거의 검정 카드**다(`darkSurface` + `darkText`) → `s.surfaceRaised` + `s.text`
- `_SectionLabel`(:313)·TabBar `unselectedLabelColor`(:227)·`_hintColor()` 중립 분기(:1505)·`_SyllableDemo`(:536,550)가 **다크 테마 토큰을 크림 위에** 쓴다 → `s.textMuted`
- **개요 탭의 `HanokHeader` 제거**(:283-287). `calligraphy.png`가 이 화면 최대 색 공급원이고(황 + `HanokColors.cheong` 초록 + 석간주), 4×N 색 그리드와 경쟁한다. eyebrow + 제목 줄로 교체. 이견 시 커밋 하나로 되돌릴 수 있다

**신규 하드 가드** `test/content_palette_guard_test.dart`: 13개 콘텐츠 파일에 `gold`·`goldOnLight`·`tiger`·`tigerOnLight`·`warning`·`darkSurface`·`darkText`·`darkTextMuted`·`darkTextDim`·`darkAccent`·`darkPrimary`·`highlight`가 **0개**. **줄어들기만 하는** `_pendingMigration` 허용목록을 두어 화면 커밋마다 한 항목씩 제거 → 첫 커밋부터 녹색. raw `TextStyle(`·raw `AppBar(`·w900·`soriFillSize(`도 같은 방식. 래칫보다 이게 낫다 — Jin이 실제로 보는 표면에 그의 규칙을 새긴다.

**깨지고 재조준할 테스트:** `vocab_pack_typography_test.dart:41-46`과 `vocab_pack_uniform_card_test.dart`가 `find.byType(FittedBox)`로 히어로를 찾는다 → `SoriKoreanText`에 `Key('deck-hero-korean')`을 주고 키로 찾는다. `accessibility_guideline_test.dart` 매트릭스에 콘텐츠 화면을 추가한다(현재 **부재** — 팔레트 변경 후 대비/터치타깃/라벨 공백).

**한글 시범 획 vs 손글씨** — 페인트 속성은 이미 같다(둘 다 #1F7A6B, 11px, round). 차이는 기하와 레이어다.
- 신규 `lib/widgets/sori/ink_path.dart`를 **양쪽 페인터가 공유** — 이게 "같아 보이게" 만드는 실체다: `soriInkFilter`(1.5px 미만 포인터 스팸 제거 + EMA α≈0.35), `soriInkPath`(내부 앵커마다 2차 필렛 — 전체 Catmull-Rom 아님, 긴 직선은 직선으로), `soriInkPartial`(호 길이 보행, `_partialPath` 대체), `const kSoriInkWidth = 11`
- 사용자 폴리라인은 **표시용으로만** 스무딩한다. `_strokes`는 원본 유지 → `evaluateStroke`(24샘플, 34px 허용) 무영향. 호출부에 명시 주석
- 가이드 데이터 변경은 **딱 하나**: [hangul_strokes.dart](lib/data/hangul_strokes.dart) ㄹ 3획 시작점 `Offset(35, 112)` → `Offset(35, 110)`. 2px 이음매는 파일 전체에서 ㄹ 하나뿐이다(ㄷ/ㅁ/ㅌ/ㅂ/ㅍ 확인). 2·3획 끝점 간격은 65px로 유지되어 `_endpointTolerance` 55px 위 → "혼동쌍 정확히 4개" 단언 무영향
- **원 반지름 버그**(`stroke_canvas.dart:212`): `st.radius * (paint.strokeWidth / 11)`이 `scale`을 `strokeWidth`에서 유도해 ghost는 9%, highlight는 18% 크다 → ㅇ/ㅎ에 동심원 3개. `scale`을 인자로 넘겨 `st.radius * scale`
- **하이라이트를 구별되게**: 지금은 같은 색에 2px 더 굵을 뿐이고, 3중 페인트(ghost 12 + live 11 + highlight 13)가 굵은 뭉툭함의 실제 원인이다 → 헤일로(`accent` α0.22, 22*scale) 후 `accent` 본선을 `kSoriInkWidth*scale`로. 시작점 점 추가로 방향 표시. 900ms 펄스(`reduceMotion` 게이트)
- ⚠️ `hangulStrokes` 자체를 스무딩하지 말 것 — 매처의 기준 기하이고 `hangul_stroke_order_test.dart`의 "혼동쌍 정확히 4개"가 실제 게이트다. `defaultStrokeTolerance`도 낮추지 말 것

---

## Phase 5 — 문법 구조 + 콘텐츠 (PR 5)

**5.1 허브 도입** — 신규 `lib/screens/grammar_index_screen.dart`
네 불만("연습이 처박힘", "필터가 안 먹음", "뒤로가면 홈") 모두 뿌리가 하나다: `/grammar`가 182장 덱에 바로 떨어뜨리고 그 위에 아무것도 없다.
- `SoriAppBar` + **페이지 최상단 전폭** `SoriButton.filled(t.grammarChoiceCta, accent: contentCta)` — 44dp 칩 줄에서 스크롤로 사라지던 `sm` 버튼에 집을 준다
- `pattern`/`typeFor(lang)`/`explanation`에 대한 **검색 필드**. 타입이 213종이므로 **검색만이 유일하게 동작하는 필터**다
- 레벨 섹션 + 개수(A1 37·A2 46·B1 46·B2 51·C1 17·C2 17), `Storage.grammarHard` 기반 "Schwer (N)" 토글 하나
- 행/레벨 헤더 탭 → 해당 범위로 스코프된 덱 push

[main.dart:651](lib/main.dart#L651)을 `courseContext == null ? GrammarIndexScreen() : GrammarScreen(courseContext:)`로 바꾸고 `/grammar/study` 추가. 코스 연습은 계속 덱으로 직행해야 한다(`course_mission_navigation.dart:168` 의존).

**그리고 [grammar_screen.dart](lib/screens/grammar_screen.dart)에서 삭제:** `_showFilterSheet`, `_dropdown`, `_types`, `_typeMatches`, `_type`, `_difficulty`, `_hasActiveFilter`, `_clearFilters`, `PopScope`와 가짜 뒤로 화살표, 레벨 칩 줄. 같이 사라지는 것들 — 적용도 닫기도 안 하는 Apply 조기 반환, 빈 결과 가드 없는 레벨 칩 경로, 하드코딩 독일어 `'Leicht'/'Schwer'`(`TODO(l10n)`), 로케일 전환 시 `DropdownButton` 단일 매치 단언 위험.
⚠️ **"Type을 Level로 좁히기"로 대체하지 말 것** — 타입이 레벨과 1:1이라 레벨당 1항목 드롭다운이 되고 여전히 212개의 1장 덱이 남는다. 차원을 지운다.
`Storage.grammarLastIdx`가 이제 스코프된 덱을 가리키므로 스코프별로 키를 나누거나 스코프 변경 시 리셋한다.

**5.2 splitter 수정** — [grammar_study_copy.dart](lib/models/grammar_study_copy.dart). 전부 실제 CSV에서 확인된 결함이다.
- **D1** `.`-at-72 컷이 말줄임표 안에서 발동: `V-(으)ㄹ수록`→`Je mehr.`/`The more.`, `V-(으)ㄹ 것 같다`→`Vermutlich wird.`, `V-(으)ㄹ 뿐만 아니라`→`Nicht nur .`, `V-다 보면`, `V-(으)ㄹ까요?`
- **D1b** 독일어 서수에서도 발동(브리프에 없던 것): `V-겠어요` → `Ich werde (Absicht der 1.` + 규칙 `Person) oder …`
- **D1c** 72자 임계가 언어 복불복 — 독일어가 72자를 넘고 영어는 안 넘어서 **같은 행이 DE/EN에서 규칙 수가 달라지는** 행이 6개
- → 문장 경계 스캔으로 교체: `...`/`…`의 일부, 앞이 숫자, 앞 토큰이 2자 이하(`z.B.`·`e.g.`·`bzw.`), 다음 비공백이 소문자면 거부. 72자 예산은 **승인된** 경계에 적용
- **D4**(신규) no-`.` 폴백이 **규칙 #1을 제목으로 훔친다** — 14행 전부에서 발생. 8행은 첫 `·` 앞에 `': '`가 있어 그게 진짜 제목 경계다 → 콜론에서 나누면 **콘텐츠 수정 0으로 규칙 #1이 복구**된다. 콜론이 없으면 제목을 내지 말고(`_Front`가 이미 `g.typeFor(lang)`로 폴백) 전부 규칙으로
- **D5**(신규) 공백 없는 `·`를 규칙 구분자로 오인 — `'ㄹ' 탈락`의 `ㄹ fällt vor ㄴ·ㅂ·ㅅ weg`가 제목 `ㄹ fällt vor ㄴ` + 규칙 `ㅂ`, `ㅅ weg`가 된다. `RegExp(r'\s+·\s+')`로 공백 구분 요구
- **D2** `_sameClause`의 양방향 `contains`. 오늘 52개 노트 중 50개는 정확한 중복(정상), 과잉은 2개뿐이지만 **짧은 `·` 절을 집필하는 순간 위험해진다** → 공백 정규화 **동치만**으로 좁힌다. 지금 고친다, 콘텐츠 착지 후가 아니라
- **D3** 잉여 gloss 조용히 버림 — 오늘 불일치 0행이므로 **패리티 계약 테스트를 콘텐츠 작업 전에 먼저 착지**시킬 수 있다. 루프를 `max(korean.length, glosses.length)`로

**5.3 퀴즈를 예문 #1만 읽게 (집필 전 필수)**
`Grammar.hasSingleExampleFocusFor`가 **셀 전체**에 `indexOf(focus)`를 하고 정확히 1회를 요구한다. 예문을 추가하면 깨진다 — 함정: `V-아/어요` focus `esse`는 독일어 *besser*에 들어있고, `N은/는` focus_en은 **한 글자 `I`**라 새 영어 문장의 아무 대문자 I나 깨뜨린다. 13행 중 12행이 `quiz_enabled=true`다.
→ `splitStudyPhrases`를 `grammar.dart`(또는 신규 `lib/models/study_phrases.dart`)로 옮기고(현 위치에서 부르면 순환), `hasSingleExampleFocusFor`와 `grammar_choice_quiz_screen.dart:342/367`이 `splitStudyPhrases(...).first`를 쓰게 한다.
그러면 **집필 규칙: "기존 문장이 예문 #1로 남는다"** → `quiz_focus_*` 무수정, focus 단언 무위험, 퀴즈 프롬프트가 214행 전부 바이트 동일.
대가: 기존 예문이 규칙 #2를 예시하는 3행(`N은/는`, `N이/가`, `V-아/어요`)은 **설명 절 순서를 바꿔야** 한다(`_Back`이 인덱스로 zip). 아래 표에 반영했다.

**5.4 (a) 13행 집필** — 신규 한국어 문장 **19개**(브리프의 ~25가 아니다: 124·149행이 +3/+3이고 `'ㄹ' 탈락`은 -1), DE·EN 포함 **57개 문자열**. 어휘는 각 행의 레벨에 묶고 고유명사 금지(`learner_copy_scan_test.dart`가 민수/철수/영희/안나를 막는다). 각 gloss는 해당 행의 `quiz_focus_de`/`quiz_focus_en`과 부분문자열 충돌을 확인했다.

세 행은 **예문 추가가 아니라 텍스트 수리**다:
- `'ㄹ' 탈락` — `·`를 쉼표로. **새 예문 0개**
- `V-(으)시-`·`V-기`·`-대요/…`·`V-다고/…` — D4 때문에 실제 규칙 수가 3·3·**4**·**4**다(2·2·3·3이 아니라) → +2·+2·**+3**·**+3**

집필 표(발췌, 전체는 구현 시 리뷰 문서로):

| 행 | 조치 |
|---|---|
| `N은/는` A1 | 설명을 **모음 우선**으로 재정렬(기존 저는이 모음 사례). KO `저는 학생이에요. / 선생님은 한국 사람이에요.` note 중복 → 비움 |
| `N이/가` A1 | 모음 우선 재정렬. KO `친구가 와요. / 가방이 커요.` |
| `V-아/어요` A1 3규칙 | **어요 우선** 재정렬(기존 먹어요). KO `먹어요. / 여기 앉아요. / 지금 공부해요.` DE `Ich esse. / Ich setze mich hierhin. / Ich lerne jetzt.` — *setze*·*lerne*에 `esse` 없음 확인 |
| `무슨/어떤 N` A1 | 어떤 gloss를 의도적으로 `Welche Art von…`/`What sort of…`로 — `Was für`/`What kind of`였으면 focus 유일성이 죽는다 |
| `-대요/…` B2 4규칙 | ex2 `Man sagt`/`They say`, ex4 `Er schlägt vor`/`He suggests` — focus `Er sagt`/`He says` 유일성 보존 |

**`_CourseCheckpointFront`([grammar_screen.dart:1118-1201](lib/screens/grammar_screen.dart#L1118))가 `g.exampleKorean`을 raw로 렌더**해서 (a) 이후 `' / '` 구분자가 화면에 노출된다 → `GrammarStudyCopy…examples.first`로 전환.
**`_Back`(:1356)은 `SoriCard` 안 순수 `Column`으로 스크롤이 없다.** 124·149행이 3→**4** `_RuleExampleRow`가 되면 390×844에서 넘친다 → 스크롤 또는 클램프 + 390×844·320×568 위젯 테스트.

**5.5 (b) 설명 재작성 — 152행이 아니라 ~31행**
브리프 전제가 틀렸다. 152행 중 둘째 문장이 있는 건 **11행**뿐이고, 그중 진짜 둘째 **규칙**을 담은 건 `A/V-(으)ㄴ/는 듯하다` 하나다. 나머지는 문체·부연 산문이다.
**작동하는 기계적 선별 신호: `note` 열이 이미 `·` 목록을 담고 있는가** — 152행 중 **65행**이 그렇다. 저자가 이미 규칙 목록을 썼고 열만 틀린 것이다. 여기에 `=` 매핑 노트 1행(`V-아/어 보다`).
그 66행 풀에 **4문항 의미 필터**를 적용해 넷 다 예면 쪼갠다:
1. `·` 절들이 **이 행 자신의** 형태/용법을 말하는가(자기 행이 따로 있는 다른 문법과의 비교가 아니라)?
2. 학습자가 절마다 **다른 한국어 문장**을 만들 것인가?
3. 각 절의 예문을 이 행 레벨 어휘로 쓸 수 있는가?
4. 결과 규칙 수가 ≤4인가(`_Back` 실질 한계)?

1번이 일을 다 한다 — 비교 노트(`밖에 vs 만`, `못 vs 안`, `고 있다 vs 아/어 있다`, `네요 vs 군요` 등)를 기각한다. 쪼개면 **다른 행의 문법 예문**이 이 행 셀에 들어가 코퍼스와 TTS 청구서를 오염시킨다. 문체 사실(`Sehr formell · Stärker als -더라도`)과 불규칙 단어 목록(`빠르다→빨라요 · 부르다→불러요 · 다르다→달라요` — 규칙 1개, 표본 3개)도 기각.

> **결과: 152행 중 ~31행(20%)만 진짜 쪼개야 한다. ~121행은 단일 개념이라 그대로 둔다.**

숨은 비용: 규칙이 0→2가 되면 예문도 1→2여야 하므로 (b)는 "설명 재작성"이 아니라 **한국어 문장 ~37개 추가(+DE +EN ≈ 111 문자열)**다. **(a)를 먼저 출시하고 (b)는 별도 승인 배치**로 다룬다.

**5.6 리뷰 게이트**
- 신규 `tools/content_factory/build_grammar_pair_review.py`(읽기 전용, 네트워크 없음, 기존 `build_tts_stale_manifest.py` 스타일): BASE/HEAD를 받아 변경 행마다 OLD vs NEW 설명, **`_Back`이 렌더할 그대로의** 규칙↔예문 zip, 그리고 ⚠ 플래그(규칙/예문 수 불일치, KO/DE/EN 수 불일치, `quiz_focus`가 ≠1회, 규칙 >4). **Jin이 읽는 단일 산출물**
- 신규 `test/grammar_pair_contract_test.dart`: 214행 전부 KO/DE/EN 구절 수 동일(**오늘 통과** — 콘텐츠 수정 전에 먼저 착지), `rules.isNotEmpty`면 `rules.length == examples.length`. 알려진 13개 ID 허용목록으로 시작해 행마다 제거 → **허용목록이 비는 것이 완료 기준**
- 계속 녹색이어야 하는 기존 게이트: `grammar_choice_quiz_test.dart`(214행·distractor·focus 유일성), `data_integrity_test.dart`, `content_audit_manifest_test.dart`, `learner_copy_scan_test.dart`
- 커밋 3분할: (1) splitter 수정 + 계약 테스트 + 퀴즈 phrase-#1 리팩터, **CSV 수정 0** → 모양이 바뀐 카드는 전부 splitter 수정임이 증명된다 (2) (a) 13행 (3) (b) 배치, 레벨별로 다시 분할

---

## Phase 6 — 프리미엄 음성 100% + 기계음 제거 (PR 6)

Phase 5가 문법 문자열을 확정한 뒤에 실행한다. 그래야 유료 합성을 두 번 안 돌린다.

**6.1 문법 재생 모델 확정** — `GrammarStudyCopy.speakKorean` **삭제**. 렌더된 예문마다 스피커 하나. 앞면은 `examples.first.korean`, 뒷면은 탭한 예문. 이걸로 "TTS랑 내용이랑 1도 안 맞다"가 해소되고, 모든 발화 문자열이 `splitStudyPhrases` 원소와 같아진다. `test/grammar_study_copy_test.dart:41`의 `speakKorean` 단언은 예문별 단언으로 교체.

**6.2 드리프트 방지 — 생산자 하나, 산출물 하나, 동치 테스트 하나**
두 번째 수집기를 만들어 비교하지 **않는다** — 그게 지금 구조이고(`generate_tts.py`가 `speakKorean`이 하는 유도를 재구현) 바로 그것이 드리프트했다.
- 신규 `tool/export_tts_corpus.dart` — `dart run` 스크립트. **화면이 부르는 바로 그 유도 코드**(`GrammarStudyCopy.fromGrammar`, `splitStudyPhrases`, `speakableJamo`, `Scenario.fromJson`, 퀘스트 엔진 규칙 등)를 호출해 `(voice, text, sourceId)`를 낸다. 이게 하중을 받는 성질이다 — 유도가 바뀌면 export가 자동으로 바뀐다
- 신규 `tool/tts_corpus.json`(커밋) — 결정적 정렬
- 신규 `test/tts_corpus_manifest_test.dart` — 인프로세스 재계산 후 매니페스트와 바이트 동치, 그리고 모든 행에 `TtsCacheKey.forRequest(...).storagePath` 일치. **`.github/scripts/select_flutter_tests.py`의 `ALWAYS_ON_TESTS`에 등록**(임포트 엣지가 없는 데이터 스캔이라, 없으면 정작 깨뜨리는 PR에서 안 돈다 — 자모 캐리어와 문법 join이 빠져나간 경로가 정확히 이것)
- `tool/generate_tts.py`에 `--corpus` 추가해 소비. `collect()`는 한 릴리스 동안 `--legacy-collect`로 교차 확인 후 삭제
- **미수집 소스 추가: `assets/data/word_relations.json`**(197 문자열, `word_web_*` 화면들이 발화)
- `tool/test_generate_tts.py`에 `RATE == 1.0`과 Chirp3-HD 음성 2종 이름을 고정. `functions/tts/tts_contract.test.js`에도 미러. 조용한 음성/속도 변경은 149k자를 통째로 무효화한다

**6.3 quota 상향 + 배포** — `functions/tts/tts_request_guard.js`

| 범위 | 현재 | 제안 | 최악/일 |
|---|---|---|---|
| 기기 | 30 | 300 | ~5,100자 ≈ $0.15 |
| 계정 | 50 | 400 | ≈ $0.20 |
| 전역 | 300 | 5,000 | ~85k자 ≈ **$2.55/일** |

`tts_request_guard.test.js` 갱신 + **Cloud Billing 예산 알림** 설정. `prefetch`의 `allowSynthesis: false`는 유지 — 안 눌린 카드의 투기적 합성은 절대 돈을 쓰면 안 된다.
⚠️ `AGENTS.md:449-451`이 기록하듯 **리뷰된 CF가 아직 배포 안 됐다**(빈 캐시 거절·환급·12초 timeout·7초 deadline·fail-closed 선점이 live에 없음). 클라이언트 오류 분류가 계약을 구현하지 않은 서버 상대로 검증되고 있다 → **먼저 배포한다.**

**6.4 유료 합성 실행 — 약 $1**

| 항목 | 쌍 | 자 |
|---|---|---|
| 마지막 검증(`53595787`) 대비 누락 | 1,464 | 30,362 |
| + word-web(수집기 공백) | 197 | 1,880 |
| + 문법 신규(Phase 5 확정 후) | ~22 | ~300 |
| **합계** | **~1,683** | **~32,500** |
| 재시도 인플레(3음절 이하 91개 × 최대 6테이크) | | +≤1,005 |
| **청구 상한** | | **~33,500자 ≈ $1.00** |

```
python3 tool/generate_tts.py --dry-run | head -2          # 인증·네트워크·쓰기 없음
python3 tool/generate_tts.py --verify-storage             # 읽기 전용, gcloud 인증 필요
GOOGLE_TTS_API_KEY_2=… python3 tool/generate_tts.py --missing-from-storage --workers 4
python3 tool/polish_tts.py --dry-run && python3 tool/polish_tts.py   # ffmpeg 필수
gcloud storage rsync -r .tts_pregen/tts/v3 \
  gs://ko-lernen-app.firebasestorage.app/tts/v3 --project ko-lernen-app
python3 tool/generate_tts.py --verify-storage             # "missing 0" 기대
```
> **5번은 생략 불가이고 기존 런북에 없다.** `main()`이 `polish_tts.py` **이전에** rsync하므로, 폴리시된 바이트를 다시 올려야 한다.

**가드레일 — 실제 사고 전력이 있다.** `docs/SESSION_LOG.md:698-701`: 따옴표 없는 heredoc 때문에 `generate_tts.py`가 인자 없이 실행돼 **178개가 승인 없이 합성·업로드**됐다. **무인자 실행 = 로컬에 없는 전부를 합성한 뒤 rsync.** 항상 `<<'PY'`를 쓰고, 모드 플래그 없이 절대 실행하지 않는다.
- 실행 전 `find .tts_pregen -name '*.mp3' -size -1k` — 잘린 파일은 크기>0 검사를 통과해 그대로 업로드된다
- `gcloud storage rsync`에 `--delete`가 없어 `.tts_pregen`의 쓰레기가 프로덕션으로 간다
- `--workers 16` 기본 + `QUOTA_BACKOFF_SECONDS`(최대 60s)라 429 폭풍은 비싸지는 게 아니라 **길어진다**. 8/17 배치는 3라운드 필요했다 → `--workers 4`, 1시간 예산
- `tools/content_factory/tts_batch_06_manifest.json`에 batch 05와 같은 `authorization` 블록(`approvedBy`·`approvedAt`·`scope`)으로 기록 — **이 블록이 이 저장소의 실제 지출 통제다**
- ⚠️ **기기 캐시는 무효화되지 않는다.** 파일명이 오디오 바이트가 아니라 텍스트를 해시하므로, 같은 경로에 재폴리시한 객체는 이미 캐시한 기기가 무시한다. QA 전 앱 저장소를 지운다

**6.5 4단 제거 (`--verify-storage`가 missing 0을 낸 뒤에만)**
- `flutter_tts`를 재생 경로와 `pubspec.yaml`에서 삭제. `_applyFallbackLanguage`·`_trySelectKoreanVoice`·`_startFallback` 통째로 사라진다(Phase 1의 미봉책도 같이)
- `koVoiceAvailable`은 `lib/` 어디서도 안 읽히므로 보존할 UI 계약이 없다
- `pubspec.yaml`, `ios/Podfile.lock`, `android/app/proguard-rules.pro:104` 동반 수정 → 클린 `pod install` + 릴리스 Android 빌드 확인
- 대체물: Phase 1.5의 배너 + 3상태 스피커(idle → 로딩 → 취소선). 오프라인은 구조적으로 완화된다 — mp3 캐시는 영구고 `prefetch`가 데우므로 한 번 들은 건 영원히 오프라인 재생된다
- **Jin이 완전 제거를 거부할 경우의 문서화된 대안:** 설정→Ton에 "Notfall-Systemstimme (klingt robotisch)" 스위치, **기본 off**, 이것만이 `flutter_tts`로 가는 유일한 경로. 조용한 자동 폴백으로는 절대 출시하지 않는다

**6.6 `tts_cache_key_test.dart` 래칫 이동** — 소스 스캔 부분이 취약하다
- `_netTimeout = 12s` 단언 → 타임아웃이 4개가 되므로 `@visibleForTesting` 상수 맵 단언으로 교체
- `'TTS audio is not available.'`·`'already in progress'` → `functions/tts/index.js`와의 **교차 파일 계약 테스트**로 이동(같은 파일 스캔이 아니라)
- `'resource-exhausted'` 소스 스캔은 삭제(동작 테스트가 이미 있다)
- `TtsSynthesisBlocked` → `TtsUnavailable`로 개명하고, 식별자 등장이 아니라 **던져지는지**를 단언
- 키 벡터와 `isUsableAudio`는 유지 — `'안녕하세요'` → `d84734f7…`는 `tool/test_generate_tts.py`·`functions/tts/tts_contract.test.js`와 공유하는 3자 고정이다

**신규 테스트:** `test/tts_no_silent_failure_test.dart` — resolver가 (a) null 반환 (b) `TtsUnavailable(quota)` 던짐 (c) 영원히 미완료일 때, 셋 다 `speak()`가 `false`로 정착하고 `unavailable.value`가 올바른 사유로 non-null이어야 한다. 더해 `TtsPlaybackPlatform`에 `startSpeech` 멤버가 없고 `lib/`에 `FlutterTts` 참조가 0임을 소스 스캔 → 4단 재도입 불가.

---

## 골든 · 래칫 요약

**재생성 6개**(전부 Phase 3.1에서 발생): `screen_settings_medium/expanded`, `screen_sori_today_medium/expanded`, `screen_vocab_packs_medium/expanded`. 800dp·1280dp에서 `soriComfortScale`이 정확히 1.10인데, 이동 후 letterSpacing이 배율을 안 타고 Material `TextTheme` 텍스트가 비로소 배율을 탄다. **CI `task=regenerate-goldens`로만** 생성한다 — Linux가 정본 기준이고 이 테스트들은 macOS에서 skip된다.

**불변:** `*_compact` 3개(360dp → 배율 1.0), `sori_card_v2`·`level_chips`·`mission_hero_states`(400dp에서 pump), `personal_hanok_map_*`.

**삭제:** `home_compact_360x800.png`, `home_expanded_1280x800.png`(고아).

**래칫:** `typography_guard_test.dart` 6개가 두 번 움직인다(Phase 3.8 따라잡기, 최종 재기준). 신규 래칫 4개(`soriFillSize(` 66→0 후 함수와 래칫 동시 삭제, `SoriStudyScale(` 17→0, `FittedBox(` in screens 20→≤12, `fontSize:` <12.5 103→≤88) + 신규 하드 가드 1개(`content_palette_guard_test.dart`, 줄어드는 허용목록).

**문서:** `docs/CONTENT_UI_BIBLE.md` §198이 아직 `contentCta = info #57799E`라고 하는데 `tokens.dart`는 `= primary #1F7A6B`다 — 수정. §13 마지막 줄이 Phase 2에서 삭제할 캡션을 요구한다 — 수정. `docs/SESSION_LOG.md`에 세션 기록(AGENTS.md 규칙).

---

## 검증

**단위·위젯** — 각 Phase 종료 시:
```
flutter analyze
flutter test
```

**실기기(최종, 필수)** — 웹으로는 라우팅·프리미엄 mp3·공유를 검증할 수 없다.
1. **Android, 진동 모드**: 오늘의 글자 → 소리가 나고 **미디어** 볼륨에 반응 (Phase 1.1)
2. **콜드 런치 직후** 오늘의 글자 → 인증 미완료 상태에서도 재생 (Phase 1.3)
3. **한글 Pronounce** 40개 자모 전부 → 프리미엄 음성, 무음 0 (Phase 1.6 + 6.4)
4. **듣기** C1 시나리오 한 편 완주 → 강제 종료 → **비행기 모드** → 재생 시 모든 줄이 캐시에서 나와야 함 (Phase 6.4)
5. **문법** 카드에서 스피커 → **보이는 예문 하나만** 재생, 두 번 눌러도 하트 안 생김 (Phase 6.1 + 3.5)
6. **설정→Ton→Aussprache 끄기** → 무음이 아니라 배너 (Phase 1.5)
7. **책갈피** 연타 → 검은 바 0개, 아이콘이 채워짐 (Phase 3.6)
8. **공유** → 두루마리 PNG가 붙고 텍스트 캡션 없음 (Phase 2)
9. **360×640 / 390×844**에서 13개 콘텐츠 화면 → 한국어가 어절 중간에서 안 잘림, 한 화면에 담김 (Phase 3.3 + 4)

**합성 검증:** `python3 tool/generate_tts.py --verify-storage` → `missing 0`.

**실행 명령(Phase 0 이후):**
```
cd ../ko_lernen_app-uiux
git rev-parse --abbrev-ref HEAD     # feat/content-uiux-finish 확인 — 매번
flutter run -d <android-device-id>  # 웹이 아니라 실기기
```

---

## 하지 말 것 (검증된 함정)

1. **카드 위에 `onDoubleTap`을 얹지 말 것** — 아레나를 300ms 붙잡아 모든 자식 탭이 느려진다. Stack 맨 아래 디텍터를 쓴다
2. **지금의 `SoriPhraseWrap`을 전역 채택하지 말 것** — 페이드 버그·line-height 손실·단어 단위 TalkBack을 전 화면에 수출한다. 먼저 재작성
3. **`TextWidthBasis`는 한국어 줄바꿈과 무관** — 보고되는 폭만 바꾼다
4. **`hangulStrokes` 자체를 스무딩하지 말 것** — 매처의 기준 기하다. 페인터에서 스무딩
5. **`defaultStrokeTolerance`를 낮추지 말 것** — 25px 지터 테스트가 34글자 전부에서 깨진다
6. **`review_session`의 XP 황을 다른 색으로 바꾸지 말 것** — 바이블이 황을 XP에 예약했다. `SoriBadge.xp`로 전환할 뿐
7. **Type을 Level로 좁혀 필터를 "고치지" 말 것** — 레벨당 1항목 드롭다운 + 212개 1장 덱이 된다. 차원을 삭제
8. **Phase 6.5(4단 제거)를 6.4(합성) 앞에 두지 말 것** — 로봇 음성 대신 무음이 된다
9. **`generate_tts.py`를 모드 플래그 없이 실행하지 말 것** — 무인자 = 전부 합성 + 업로드. 실제 사고 전력 있음
10. **래칫은 내려가기만 한다** — 중간 커밋에서 카운트가 튀지 않게 순서를 잡는다(Phase 3.8이 먼저 오고, 팔레트 가드가 하드 0 대신 줄어드는 허용목록을 쓰는 이유)

---

## Jin에게 물어야 할 것 (구현 중)

1. **"이 png는 내가 만들게"** — Phase 2 참조. 렌더러는 전부 절차적이라 넘겨받을 파일이 없다. (A) 배경 아트 / (B) 도장 PNG / (C) 아트 디렉션. 미응답 시 기본값대로 진행
2. **(b) 31행 배치** — (a) 착지 후 리뷰 문서로 별도 승인
3. **한글 개요 탭 `HanokHeader` 제거** — 색 공급원 1순위지만 되돌리기 쉽다
