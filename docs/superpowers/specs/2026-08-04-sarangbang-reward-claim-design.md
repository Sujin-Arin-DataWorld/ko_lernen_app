# 사랑방 꾸러미 수령 내구성 설계

상태: 구현 승인됨

## 1. 목표와 범위

특별 퀘스트가 이미 저장하는 미개봉 보자기(`Storage.pendingBoxes`)를 사용자가 열어
실내 장식 하나로 바꾸는 비시각적 서비스 경계를 만든다. 선택한 장식은 한 번만
보유 목록에 들어가야 하고, 보상 지급·꾸러미 소비·앱 종료가 어느 지점에서
겹쳐도 보상이 사라지거나 두 번 지급되면 안 된다.

이번 범위는 서비스와 저장 계약, 단위 테스트뿐이다. 사랑방 화면, 바텀시트,
새 ARB 문구, PNG 생성·정규화, `kAvailableDecorations` 화이트리스트는 바꾸지
않는다. 따라서 디자인/에셋 세션과 파일 소유권이 겹치지 않는다.

## 2. 후보 계약

후보 풀은 `placed_decoration.dart`의 실내 카테고리 장식만 사용한다. 마당 전용
장식은 절대 보상 후보가 되지 않는다. 풀의 정확한 순서는 아래와 같고, **기존
항목 사이 삽입·재정렬 금지, 미래 항목은 끝에만 추가**한다.

```dart
const kDecorationRewardPool = <String>[
  'decoration_chaekgado',
  'decoration_seoan',
  'decoration_munbangsau',
  'decoration_sagunja_maehwa',
  'decoration_soban',
  'decoration_gat_buchae',
  'decoration_sagunja_nan',
  'decoration_jagae_mungap',
  'decoration_pyeonaek',
  'decoration_sagunja_guk',
  'decoration_sagunja_juk',
];
```

각 알려진 퀘스트 ID는 Dart 런마다 달라질 수 있는 `hashCode`가 아니라, 코드 유닛을
사용하는 안정 해시(`hash = (hash * 31 + codeUnit) % pool.length`)로 시작점을 만든다.
거기서 원형으로 연속한 세 항목이 그 퀘스트의 결정적 후보이다. 이미 보유한 항목은
표시·수령 후보에서 뺀다. 세 항목을 모두 보유했다면 꾸러미는 소비하지 않고
`noEligibleCandidates`를 돌린다. 새 장식이 추가되어야만 다시 열 수 있다.

`kQuestById`에 없는 출처 ID는 손상된 큐로 취급한다. 후보를 만들거나 큐를 소비하지
않고 `unknownQuest`를 돌린다.

## 3. 공개 서비스 경계

`DecorationRewardService`가 UI가 쓸 유일한 보상 경계다.

```dart
static Future<DecorationRewardOffer> loadNextOffer();
static List<String> candidatesForQuest(
  String questId, {
  Iterable<String>? owned,
});
static Future<DecorationRewardClaimResult> claimNextBox(String slug);
static Future<DecorationRewardRecoveryResult> resumePendingClaim();
```

`loadNextOffer()`는 먼저 미완료 journal을 복구하고, 그 뒤에 첫 번째 큐 항목의
출처 ID와 후보를 돌려준다. UI는 `DecorationRewardOffer.state`가 `ready`일 때만
선택지를 그린다. 수령 화면은 `Storage.addOwnedDecor`, `Storage.consumePendingBox`,
`Storage.setPendingBoxes`를 직접 호출하지 않는다.

서비스는 모든 `loadNextOffer`, `claimNextBox`, `resumePendingClaim` 변이를 한
직렬 큐에서 실행해 더블 탭이나 동시에 돌아온 화면이 같은 첫 꾸러미를 중복 처리하지
못하게 한다.

## 4. 내구 journal

`Storage`에는 다음 로컬 전용 키를 추가한다.

| 키 | 값 | 역할 |
| --- | --- | --- |
| `kl_reward_boxes` | `List<String>` | 기존 FIFO 미개봉 꾸러미 출처 ID 목록 |
| `kl_reward_claim_v1` | JSON 문자열 | 선택이 끝났지만 큐 소비가 끝나지 않았을 수 있는 수령 journal |

Journal JSON은 다음 고정 스키마다.

```json
{
  "version": 1,
  "stage": "prepared",
  "sourceQuestId": "q_punggyeong",
  "decorationSlug": "decoration_sagunja_guk",
  "pendingBefore": ["q_punggyeong", "q_kite"],
  "pendingAfter": ["q_kite"]
}
```

`pendingBefore`와 `pendingAfter`를 둘 다 저장하는 이유는 출처 ID가 반복될 수 있기
때문이다. 단일 ID만 저장하고 `consumePendingBox()`를 다시 부르면 같은 ID가 반복된
큐에서 잘못된 상자를 소비할 수 있다.

정상 수령 순서는 반드시 다음과 같다.

1. 첫 pending box·출처·선택 후보를 다시 검증한다.
2. `stage: "prepared"`와 `pendingBefore` 전체 스냅샷, 첫 항목을 뺀
   `pendingAfter`를 가진 journal을 먼저 쓴다.
3. `Storage.addOwnedDecor(slug)`를 호출한다. 이 API는 이미 멱등이다.
4. journal을 `stage: "queue_commit_started"`로 갱신한다.
5. 현재 큐가 `pendingBefore`로 시작하면, 그 뒤에 새로 붙은 항목은 보존한 채 첫 항목만
   제거한 목록으로 쓴다.
6. journal을 지운다.

앱이 2~5 사이에 종료되면 복구는 다음처럼 동작한다.

- `prepared`: 현재 큐가 반드시 `pendingBefore`로 시작해야 한다. 그렇지 않으면
  `conflict`를 돌리고 **어떤 값도 바꾸지 않는다**. 시작하면 장식을 멱등 추가하고
  `queue_commit_started`로 전환한 뒤 첫 항목만 제거한다.
- `queue_commit_started`: 큐가 `pendingBefore`로 시작하면 아직 소비 전이므로 첫 항목만
  제거한다. `pendingAfter`로 시작하면 소비가 끝난 상태라 장식을 멱등 추가하고 journal만
  지운다. 특히 `pendingAfter=[]`일 때 새로 생긴 큐 항목은 소비 뒤에 추가된 suffix로 보존한다.
- JSON이 손상됐거나 stage가 알 수 없으면 `conflict`를 돌리고 **어떤 큐·보유·journal도
  바꾸지 않는다**.

뒤에 새 퀘스트가 적재한 상자는 두 접두사 규칙의 suffix로 보존된다. 이 service가
정상 흐름에서 호출하는 기존 `consumePendingBox()`는 없다.

## 5. 저장·동기화 경계

- `ownedDecor`만 기존 CloudSync의 합집합 복원 범위에 남긴다.
- 고유 ID와 충돌 정책이 없는 `pendingBoxes`와 claim journal은 동기화하지 않는다.
- `QuestTracker.persistNewCompletions`의 “보상 먼저, 완료 marker 나중” 순서는 그대로
  유지한다. 이 서비스는 그 뒤의 소비만 담당한다.
- 기존 `pendingBoxes`는 `List<String>` 형식을 유지하므로 마이그레이션이 필요 없다.

## 6. 검증 기준

1. `q_punggyeong` 후보 세 개는 재실행·기기와 무관하게 같은 순서다.
2. 이미 보유한 후보는 보이지도 수령되지도 않는다.
3. 유효한 수령은 보유 장식을 한 번 추가하고 정확히 첫 큐 항목만 소비하며 journal을 비운다.
4. 유효하지 않은 slug, 빈 큐, 알 수 없는 출처, 후보 고갈은 저장값을 바꾸지 않는다.
5. journal만 기록된 상태, 장식만 지급된 상태, 큐만 소비된 상태는 모두 멱등 복구된다.
6. unrelated pending box가 claim 도중 추가되어도 복구/수령 뒤 보존된다.
7. 손상·충돌 journal은 fail-closed이며 사용자의 기존 큐와 보유 장식을 잃지 않는다.
8. 관련 Flutter 테스트, `dart analyze` 대상 파일, `git diff --check`가 통과한다.

## 7. Claude UI/에셋 인수인계

Claude의 다음 작업은 이 서비스가 준비된 뒤의 시각 계층이다.

1. 실제 장식 6종, 보자기 2종, 빈 사랑방 PNG를 에셋 규약에 맞춰 추가한다.
2. 실재 PNG만 `kAvailableDecorations`에 추가하고 `decoration_slot_test.dart`를 통과시킨다.
3. 꾸러미 개봉 화면은 `loadNextOffer()`의 `ready` 후보만 표시하고,
   선택 시 `claimNextBox(slug)`만 호출한다.
4. 화면 진입/재개 시 `resumePendingClaim()` 또는 `loadNextOffer()`를 호출해 남은 journal을
   먼저 복구한다.
5. `Storage.addOwnedDecor`, `Storage.consumePendingBox`, raw journal 키를 UI에서 직접
   쓰지 않는다.
