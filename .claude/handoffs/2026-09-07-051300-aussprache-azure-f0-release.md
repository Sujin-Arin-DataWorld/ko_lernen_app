# 2026-09-07 발음 채점(Aussprache) Azure F0 재개 + Play 비공개 릴리스 인수인계

> Jin 지시(2026-09-07): "한국어 발음 Aussprache 기능 지금 막아둔 거… 구글 API 사용료 때문인데, 우리만의 음성 생성·판정 AI 만들 수 있을까?" → 조사 뒤 결정 "1800회까지 무료면 1회 8회무료로 제한", "베타니까 내 돈 안 나갔으면", "유저가 텍스트를 음성으로 듣는 건 무조건", "리뷰는 fable 너가… sonnet한테 작업 지시", "병합승인, azure 등록완료".
> 이전 인수인계 `2026-09-07-020000-free-access-release.md`(결제 해제·최종 비공개 릴리스)를 잇는다.

## Current State Summary · 지금 상태 (한 줄)
main `5fa1f1b2`(#278 + #280)로 발음 채점이 Azure Speech F0(무료 5h/월)로 재개됐다. 함수 `assessPronunciation`은 모드·시크릿이 묶인 채 ACTIVE, 클라이언트 플래그는 저장소 변수로 켜졌고, 그 SHA가 Play 비공개 테스트에 올라갔다(아래 표). 실기기 확인은 Jin 몫.

## Decisions Made · 조사 결론 (요약 — 상세는 메모리 `own-speech-ai-feasibility-2026-09-07`)
- "구글 사용료" 전제는 오진. 발음 판정은 원래 Azure(구글 아님)였고, 구글 TTS(Chirp3-HD)는 월 100만 자 무료 안. AI 엔드포인트가 전부 죽어 있던 실제 원인은 Firestore `service_cost_controls/ai_v1` 승인 문서 부재.
- 국립국어원 기초사전 API는 발음 문자열만(음성 없음·재배포 불가), ETRI 발음평가 API·AI Hub 학습자 데이터는 국내 이용자 한정 → 독일 거주 서비스에 부적합. 자체 판정기(g2pK + wav2vec2 음소 + GOP-CTC)는 가능하나 **보류**. 온디바이스 TTS 후보 Supertonic 3은 수퍼톤 해산·아카이브 → 보류.
- 결정: Azure F0만 사용, 학습자당 하루 8회 채점(서버 강제, 공개 상한 50/일은 유지), 오프라인 불필요, 베타 중 유료 전환 없음.

## main 병합 이력 (2026-09-07, Sonnet 작성·Fable diff 직독 검수)
| PR | 내용 | main |
|---|---|---|
| #278 | `FREE_TIER_DAILY_ASSESSMENTS = 8` + `resolvePronunciationPolicy`가 `min(8, 정책 한도)`; `.env.example`; 런북 시크릿·배포 절차; CI/play_closed에 `--dart-define=ENABLE_FREE_PRONUNCIATION_ASSESSMENT=${{ vars.… }}`; iOS 빌드 스크립트 env 노브; 테스트 50/50 | `f53e987d` |
| #280 | `secrets: [AZURE_SPEECH_KEY]` **무조건 선언**(조건부 바인딩은 배포 시 절대 안 묶임 — 아래 교훈) | `5fa1f1b2` |

## 운영 완료 (전부 실측 확인)
| 항목 | 상태 |
|---|---|
| Firestore `service_cost_controls/ai_v1` | 생성. 단위=정가 USD/1000: tts 15·pronunciation 3·book 5, `dailyUnitLimit` 5000, approvedBy Jin |
| GCP 예산 알림 | 5 EUR(50/90/100%) 1건 — 중복 생성 2건은 삭제함 |
| Secret Manager `AZURE_SPEECH_KEY` | 버전 1, 84바이트, 개행 없음. 값은 어디에도 기록하지 않음 |
| 함수 `assessPronunciation`(europe-west3) | ACTIVE, updateTime 2026-09-07T02:37:53Z, env `PRONUNCIATION_ASSESSMENT_MODE=azure_f0`, `secretEnvironmentVariables`에 AZURE_SPEECH_KEY v1, 런타임 SA `573567222361-compute@…`에 secretAccessor |
| GitHub 변수 | `ENABLE_FREE_PRONUNCIATION_ASSESSMENT=true`, `PLAY_INTERNAL_RELEASE_ENABLED=false`(유지) |
| main CI | `5fa1f1b2` run 34076866206 success(03:09 UTC) |

## Android 릴리스
| sha | 트랙 | run |
|---|---|---|
| `5fa1f1b2` (발음 F0 포함) | 비공개(alpha) | 34078714115 success(03:29 UTC) — https://github.com/Sujin-Arin-DataWorld/ko_lernen_app/actions/runs/34078714115 |
versionCode는 `git rev-list --count`로 자동(5fa1f1b2 = 2260). 프로덕션 승격은 Play Console에서 Jin.

## iOS (맥 전용 — Jin)
`docs/store/APPSTORE_UPLOAD_KO.md` 절차에 `ENABLE_FREE_PRONUNCIATION_ASSESSMENT=true`를 함께 넘긴다: `ENABLE_FREE_PRONUNCIATION_ASSESSMENT=true FREE_LAUNCH=1 bash scripts/build_ios_ipa.sh`. 기본값 false라 빼면 iOS에서는 채점 버튼이 계속 꺼진다.

## Important Context · 교훈
- **Firebase CLI 디스커버리는 codebase `.env`·셸 env를 못 본다.** `secrets: 조건 ? [S] : []`는 배포 시 항상 `[]` → 함수는 ACTIVE인데 시크릿 미바인딩. 항상 정적 배열로 선언하고 읽기 여부는 런타임 게이트로. 배포 뒤 `gcloud functions describe … secretEnvironmentVariables`와 `gcloud secrets get-iam-policy`로 반드시 확인(메모리 `firebase-cli-discovery-ignores-env-secrets`).
- 윈도우 콜드 디스커버리는 10초를 넘긴다 → `FUNCTIONS_DISCOVERY_TIMEOUT=120`.
- 시크릿 입력은 `read -rs` + `printf '%s'`로(에코·개행 금지). 개행이 붙으면 HTTP 헤더가 깨져 모든 채점이 `unavailable`.
- `gh run list --template`은 run id를 부동소수로 찍는다 → `--jq '.[0].databaseId'`.
- 브리프에 "하드코딩 50을 쓰는 기존 테스트" 목록이 빠져 Sonnet 1차본이 5건 실패 → 상수 도입 시 기존 테스트의 매직 넘버 grep을 브리프에 넣을 것.

## Immediate Next Steps · Jin이 해야 할 것 (실기기 — 런북 `docs/runbooks/pronunciation-assessment.md` "Physical-device release handoff")
1. 비공개 테스트 빌드 설치 → 발음 스튜디오: 모델 음성·녹음·정지·내 녹음 재생·**"채점"** 눌러 실제 점수(음소 단위) 확인. 업로드 동의는 채점 버튼에서만 떠야 한다.
2. 같은 계정으로 9번째 채점 시 "한도 도달"(하루 8회, UTC 기준) — 로컬 재생·무채점 연습은 계속 가능해야 한다.
3. 마이크 권한 거부/허용 경로, 녹음 중·채점 대기 중 백그라운드 전환.
4. Functions 로그·Analytics·크래시 로그에 오디오/참조 문장이 남지 않는지.
5. Azure 포털 F0 사용량(5h/월)과 Firestore `service_usage/pronunciation_free_YYYY-MM` 카운터를 첫 주에 한 번 대조.
6. 결정: Play 프로덕션 승격 시점, iOS 제출(위 env 포함), Apple 제공자 설정(이전 인수인계 미완).

## 다음 세션
- `graphify update .`는 이번 세션에서 **실행하지 않았다**(변경에 md·yml이 섞여 코드 전용 경로가 아니고, 직전 인수인계 #279도 그래프 갱신 없이 병합됨). 다음 코드 세션에서 갱신.
- 워크트리 `C:/dev/hangulsori/ko_lernen_app_worktrees/aussprache-f0-20260907`(브랜치 `claude/aussprache-handoff-20260907`, git-ignored `.env`·node_modules 포함)와 로컬 브랜치 `claude/aussprache-f0-20260907`·`claude/aussprache-secret-binding-20260907`은 이 인수인계 병합 뒤 삭제 가능. 재배포 시 `.env`는 `.env.example` 복사로 재생성.
- 보류(Jin 결정): 자체 판정기 프로토타입, Supertonic/TTS 교체, Azure S0 승격. 무료 5h가 실제로 소진되면 그때 재검토.
