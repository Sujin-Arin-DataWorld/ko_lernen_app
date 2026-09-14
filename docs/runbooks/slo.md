# SLO (Service Level Objectives)

Hangul Sori(`ko-lernen-app`)가 "상업화해도 되는 상태"인지 판단하는 기준선.
이 문서의 숫자는 목표치이지 이미 달성했다는 뜻이 아니다 — 아래 "측정 방법"
칸이 비어 있거나 "미측정"이면 아직 실측이 없다는 뜻.

| SLO | 목표 | 측정 방법 | 누가, 어떻게 |
|---|---|---|---|
| 크래시 프리 세션 | ≥ 99.5% (동의한 코호트만, 14일 롤링) | Firebase Crashlytics → Dashboard → Crash-free users/sessions, 기간 14d | **Jin, Firebase 콘솔 수동 확인.** Crashlytics는 동의(consent) 기반 수집이라 이 앱의 익명/미동의 사용자는 코호트에서 빠진다 — 비율이 좋아 보여도 전체 사용자 대표값이 아닐 수 있음을 감안한다. |
| ANR율 | < 0.47% | Play Console → 품질 → Android Vitals → ANR rate | **Jin, Play Console 수동 확인.** Android 전용 지표(iOS엔 ANR 개념 없음). |
| Firestore 작업/DAU | ≤ 40 ops/day/user | `firestore.googleapis.com/document/{read,write,delete}_count` 합계를 DAU(활성 사용자 수)로 나눔 | **미측정 — 스크립트 없음.** 이 PR은 만들지 않았다: DAU 소스(Analytics? Firestore users 컬렉션?)를 먼저 정해야 정확한 나눗셈이 된다. `tool/ops/alert_policies/05_firestore_write_surge.json`은 이 SLO와 다른 것 — 그건 "급증 감지"고 이건 "평상시 효율" 지표. |
| 함수 5xx율 | < 1% | `run.googleapis.com/request_count`, `response_code_class="5xx"` / 전체, 서비스별 | **자동 알림 있음(2% 임계치, `tool/ops/alert_policies/01_functions_5xx_rate.json`).** 주의: 알림 임계치(2%)는 SLO 목표(1%)보다 느슨하다 — 알림이 안 울려도 SLO는 이미 깨졌을 수 있다. SLO 자체의 실측은 Cloud Monitoring Metrics Explorer에서 수동 조회(월 1회 권장) 또는 향후 SLO 객체(`gcloud alpha monitoring services`)로 승격. |
| TTS `--verify-storage` 결손 | 0건 | `python -X utf8 tool/generate_tts.py --verify-storage` 실행 후 출력되는 `Storage verify — expected N, remote N, missing N, stale N` 줄의 `missing` 값. `missing`이 1 이상이면 프로세스가 exit code 1로 끝난다(`tool/generate_tts.py`의 `return 1 if missing else 0`) — 이것이 `.github/workflows/ci.yml`의 "TTS Storage completeness (content)" 잡(940번째 줄)의 step "Verify TTS Storage completeness"(976번째 줄)가 그대로 게이트로 쓰는 명령이다. | **Jin 또는 세션, 로컬 스크립트 실행(또는 CI 잡 결과 확인).** 콘텐츠 텍스트가 바뀌면 TTS가 결손되는 구조이므로(`memory/tts-verify-missing-runbook`), 콘텐츠 PR마다 실행이 전제. 이 PR은 이 스크립트를 새로 만들지 않는다 — 기존 절차를 SLO로 등재만 한다. |

## 왜 "콘솔 확인"과 "알림"을 분리했나

이 PR(B1)이 만드는 `tool/ops/alert_policies/*.json`은 **실시간 이상 감지**용
이지, SLO 자체의 정기 보고용이 아니다. 예를 들어 함수 5xx 알림은 "5분간
2%를 넘었다"는 스파이크를 잡지, "지난 30일간 평균 5xx율이 1%를 넘는
추세였다"는 SLO 위반은 잡지 않는다. 두 가지 실패 모드가 다르므로 별도
관리한다:
- **알림(alert policies)** = 지금 당장 봐야 하는 이상 → `docs/runbooks/ops-alerts.md`
- **SLO(이 문서)** = 주기적으로(권장: 월 1회 또는 릴리스마다) Jin이 콘솔에서
  훑어보고 "상업화 기준을 만족하는가"를 재확인하는 체크리스트

## 다음에 필요한 것 (이 PR 범위 밖)

- Firestore ops/DAU를 자동 계산하려면 DAU 정의와 소스를 먼저 확정해야 한다
  (별도 논의 필요 — Jin 결정 사항).
- 함수 5xx의 SLO(1%) 자체를 알림으로도 걸고 싶다면 별도 정책을 하나 더
  추가하되(임계치 1%, 더 긴 평가 창, 예: 1시간 또는 24시간), 알림 피로를
  피하려면 02번처럼 severity를 낮게 잡아야 한다 — 이 PR에서는 하지 않았다.
- Crashlytics/Vitals는 Cloud Monitoring API로 직접 못 끌어오는 지표라
  자동 알림 정책 대상이 아니다(콘솔 수동 확인만 가능). 자동화하려면
  Crashlytics BigQuery export 또는 Play Developer Reporting API 연동이
  별도로 필요하다.
