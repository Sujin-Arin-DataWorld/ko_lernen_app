# 인시던트 대응 런북 (incident-response)

`docs/runbooks/ops-alerts.md`의 알림 중 하나가 울렸거나, 사용자/Jin이 직접
문제를 발견했을 때 어떤 순서로 움직일지 정리한다. 이 문서는 절차만
다룬다 — 각 알림 자체의 의미와 첫 확인 항목은 `ops-alerts.md`를 본다.

## ⛔ 최우선 원칙: repo presence ≠ live

> `docs/store/firebase-backend-release-gates.md`: **"명령이 저장소에
> 있다는 사실은 배포 권한이나 live 상태를 뜻하지 않는다."**

롤백/배포 명령이 이 저장소나 이 런북에 적혀 있다는 사실 자체는 그 명령을
지금 실행해도 된다는 뜻이 아니다. 실행 전에 항상:
1. 지금 이 SHA가 실제로 origin/main에서 왔고 승인된 것인지 확인한다.
2. 해당 서비스의 CI가 그 SHA에서 green인지 확인한다(`gh run list --commit <sha>`).
3. `ko-lernen-app` 프로젝트를 정확히 선택했는지 확인한다(`gcloud config get-value project`).
4. 운영 소유자(Jin)의 명시적 승인 없이 아래 배포/스모크 명령을 실행하지
   않는다 — 이 규칙은 B1 알림 인프라뿐 아니라 이 저장소의 모든 배포에
   적용된다.

## 심각도 사다리 (Severity Ladder)

| 등급 | 정의 | 예시 | 대응 시작 시한 |
|---|---|---|---|
| **SEV1** | 학습 콘텐츠를 아예 플레이할 수 없다, 또는 사용자 데이터 손실/손상 위험 | 앱이 홈에서 크래시 루프, Firestore 쓰기가 전부 실패, 계정 삭제가 데이터를 잘못 지움 | 즉시, 다른 작업 중단 |
| **SEV2** | AI 기능 하나가 죽었지만 앱 나머지는 정상 | TTS 합성 실패(01/03번 알림), 발음 평가 전부 실패, App Check가 특정 기능만 막음(02번) | 같은 세션 내 |
| **SEV3** | 성능 저하, 일부 사용자만 영향, 워크어라운드 존재 | Firestore 쓰기 급증(05번)이지만 응답은 정상, 계정 삭제 지연(04번)이지만 재시도로 해소됨 | 다음 세션 내 |

등급 판단이 애매하면 한 단계 높여서 취급한다.

## 컴포넌트별 롤백

### Play 스테이지드 롤아웃 중단

내부/비공개 트랙이 아니라 **프로덕션 단계적 출시** 중 문제가 발견되면:
1. Play Console → 프로덕션 → 현재 릴리스 → "출시 일시중지"(Halt rollout).
   퍼센트를 더 넓히지 말고 즉시 멈춘다 — 이미 받은 사용자를 되돌리진
   못하지만 확산을 막는다.
2. 원인이 코드면 다음 버전에서 수정 후 재출시. Remote Config로 끌 수 있는
   문제면 아래 "Remote Config 킬스위치" 먼저 시도.
3. `.github/workflows/play_closed.yml`(비공개 트랙 dispatch)과 프로덕션
   트랙은 별개 — 프로덕션 중단은 Play Console에서 수동으로만 가능하다.

### Cloud Functions 이전 리비전으로 롤백

Firebase CLI에는 "이전 버전으로 롤백" 명령이 없다 — 배포는 항상 앞으로만
간다. 실질적 롤백은 둘 중 하나:

**A. 이전 커밋을 재배포(권장, 감사 추적이 남음):**
```
git checkout <이전 승인 SHA>  # 반드시 worktree에서, main 아님
firebase deploy --only functions:<codebase>:<name> --project=ko-lernen-app
```
codebase는 `firebase.json` 기준 `gye-firebase-functions` /
`tts-firebase-functions` / `pronunciation-firebase-functions` 중 하나,
`analyze_korean_text`(Python)는 `docs/store/cloud-function-deploy.md`의
`gcloud functions deploy analyze_korean_text` 절차를 따른다. Gen1
`auth_cleanup`은 별도 취급 — 같은 문서 참조.

**B. Cloud Run 트래픽을 이전 리비전으로 즉시 되돌리기(긴급, 재배포보다 빠름):**
```
gcloud run services update-traffic <service> \
  --project=ko-lernen-app --region=europe-west3 \
  --to-revisions=<이전-리비전-이름>=100
```
`gcloud run revisions list --project=ko-lernen-app --region=europe-west3
--service=<service>`로 이전 리비전 이름을 먼저 확인. 이건 코드를 되돌리는
게 아니라 트래픽만 옮기는 것 — SEV1에서 시간을 벌 때 쓰고, 이후 반드시
A 절차로 실제 코드도 되돌린다(안 그러면 다음 배포가 다시 나쁜 리비전을
100%로 만든다).

### Remote Config 킬스위치 (`palette_variant`)

`palette_variant`는 **`SoriColors` ↔ `SoriColorsTeal`(홈 팔레트) 전환만**
한다 — 일반적인 "모두 되돌리기" 스위치가 아니다
(`docs/HANGUL_SORI_DESIGN_TOKENS.md`, `docs/HOME_REDESIGN_PLAN_2026-07-31.md`
§9: "Phase 0의 하드코딩 참조 변경은 원격 롤백 불가, 앱 업데이트가 유일한
되돌리기"). 홈 화면 팔레트 관련 시각 문제가 아니면 이 스위치로 해결되지
않는다 — 다른 원격 제어가 필요한 회귀는 앱 업데이트로만 되돌릴 수 있다는
점을 사용자/Jin에게 명확히 알린다.

## 커뮤니케이션 템플릿 (테스터 공지, DE/EN)

SEV1/SEV2에서 테스터에게 알려야 할 때 사용. `[ ]` 부분만 채운다.

**Deutsch:**
> Hallo! Wir haben ein Problem mit [기능명] in Hangul Sori festgestellt
> ([짧은 증상 설명, 예: TTS-Aussprache lädt nicht]). Wir arbeiten bereits an
> einer Lösung. Betroffen: [영향받는 기능/모두]. Workaround: [있으면 기술,
> 없으면 "Bitte kurz warten und die App später erneut öffnen."]. Wir melden
> uns, sobald es behoben ist. Danke für eure Geduld!

**English:**
> Hi! We found an issue with [feature name] in Hangul Sori ([short symptom,
> e.g. TTS pronunciation not loading]). We're already working on a fix.
> Affected: [feature/everyone]. Workaround: [describe if any, otherwise
> "Please wait a bit and reopen the app later."]. We'll update you once it's
> resolved. Thanks for your patience!

## 사후 정리

원인 조치 후:
1. 관련 알림 정책이 자동으로 닫혔는지 확인(`alertStrategy.autoClose`는
   30분) — 안 닫혔으면 원인이 완전히 해소되지 않은 것.
2. `docs/runbooks/ops-alerts.md`의 "적용 영수증" 표가 최신인지 확인.
3. 근본 원인이 이 런북에 없던 새로운 실패 모드였다면, 이 파일에 항목을
   추가하거나 `tool/ops/alert_policies/`에 새 정책을 제안한다(별도 PR).
