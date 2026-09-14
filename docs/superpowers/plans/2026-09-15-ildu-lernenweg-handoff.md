# 일두고택 × Lernenweg — 다음 세션 시작 문서

2026-09-15 Jin이 긴 세션을 마무리하며 계획과 인수인계 파일을 함께 main에 넣도록 직접 요청하여 작성했다. 이 문서는 확정 제품 결정과 실행 진입점을 보존한다. 최신 Git·소스·활성 작업 상태가 아래 스냅샷보다 우선한다.

## 읽을 순서

1. 현재 저장소 `AGENTS.md`와 `graphify query`.
2. [확정 제품 설계](../specs/2026-09-15-ildu-lernenweg-final-design.md).
3. [실행 순서·검증·Claude 메시지](2026-09-15-ildu-lernenweg-integration.md).
4. [149단계 unit 배정 CSV](2026-09-15-ildu-stage-allocation.csv), [파일 감사 JSON](2026-09-15-ildu-stage-allocation-audit.json).

다시 브레인스토밍하거나 아래 결정을 사용자에게 재질문하지 않는다. 새 사용자 지시나 실제 모순이 발견되면 그 부분만 수정한다. 다른 작업이 자동으로 보내는 조정 메시지를 이 사용자 목표의 취소·구현 승인으로 해석하지 않는다.

## 확정 사항

- 실제 Flutter 앱의 5탭을 유지하고 Lernenweg·결과·Hanok을 연결한다. 별도 웹사이트를 만들지 않는다.
- A1 42 / A2 36 / B1 37 / B2 34 =149. B2 완공, C1/C2는 완성된 공간의 심화 언어 활동.
- 터6→담8→대문12→사랑채16→화장실12→곳간12→중문채12→아래채12→안채14→안채창고11→안사랑채14→사당문8→사당12.
- 짧은 승인 정규평가 묶음 OR 연결된 정규 unit 검증 완료로 권리를 획득. 같은 stage ID로 중복 방지.
- 상급 진입은 같은 정규 평가의 검증된 catch-up. Placement·XP·출석으로 지급하지 않음.
- 학습 권리와 조립 적용은 분리. 이미 받은 재료는 앞 건물·팩 다운로드를 기다려도 사라지지 않음.
- 149개 시각 상태,39개 주요 조립 장면,별도 선택 생활 의뢰26개. 생활 의뢰0회로도 완공 가능.
- 선택한 태고/조이가 동행, 다른 친구는 특별 방문. 활성 평가 중 방문 개입 금지.
- 기존30스티커·36데코를 상황별로 사용. 정본·stable ID·기존 소유/배치 계약 유지.
- 일상 한국어 사용. 반닫이·소반·문방사우 같은 낯선 말은 필수 의뢰/정답에서 제외.
- 공사는 고정 시점, 완공 건물은45도8면도. 통로·앞뒤 기둥·벽 두께·방과 마루 깊이 유지.
- CP-2026과 저장·평가 출판·자산 전달을 조율. 10주 고정 약속 없이 실제 처리량으로 일정 추정,14일 안정성 관찰 유지.

## 이번에 실제로 끝난 것

- 설계와 실행 계획,13챕터 연출표,26의뢰 주제,계정/보존/접근성/상용화 게이트 작성.
- 149개 실제 stage ID와 현재36개 정규 unit ID의 배정 CSV 작성.
- 149개 파일 존재·SHA256 전부 대조. unique ID149, unique hash149, 합계269,109,572bytes (256.64MiB).
- 배분42/36/37/34,단계 수·unit 레벨·문서 형식 검증.
- 최신 main의 안사랑/사당34단계와 B2비율 투영을 반영. C7 #323의 추가 변경도 확인.
- Claude에게 전할 메시지를 실행 계획에 작성. 실제 전송하지 않음.
- 앱 기능 코드·새 이미지·새 평가 콘텐츠는 이 문서 작업에서 만들지 않음.

파일 감사 기준은 `a185bba83f1696e0f33656d02bb96d1049a55f7f`, 문서 통합 기준은 `d8776426f1936df47bed6974eeabde4324771467`. 문서 묶음 자체의 병합 SHA와 CI는 현재 `git log`/PR에서 확인한다. 이 작성 시점의 확인을 미래 CI 성공으로 재사용하지 않는다.

## 다음 첫 작업

**실행 계획 Task1:149개 실제 평가 연결·의미 검수·양쪽 도달성 증명.** CSV는 unit 배정까지 끝났고 `mappingStatus=unit_allocated_assessment_unreviewed`다.149개의 실제 평가 묶음은 아직 확정되지 않았다. 감사 JSON도 이를 명시한다.

1. 최신 origin/main을 확인하고 별도 작업 공간에서 시작한다. 현재 C8/CP 자산 전달/콘텐츠 작업의 파일 책임을 확인한다.
2. CSV의 unit ID와 현재 `canDo.ko`를 읽고 실제 정규 평가 ID·hash·revision·rubric·evaluator를 연결한다.
3. `practiceUnitIds`를 진실로 취급하지 않는다. 옛 ‘2문제×149’ 배분은 후보 수부터295/298로 모자랐고 의미 불일치도 있어 폐기했다.
4. 우선 `a1_07_contact_address`의 연락 방법, `a1_11_titles_relationships`의 음악·콘텐츠 선호를 검토한다. ID 이름으로 주제를 추정하지 않는다.
5. 없는 평가는 CP의 정규 평가 결손으로 전달한다. 미승인 productive catalog 플래그를 켜거나 한옥 전용 쉬운 진단으로 메우지 않는다.
6. 일반 학습과 상급 catch-up 양쪽에서149개 도달성을 검증한 후 전체 publish를 허용한다. 검수된 첫 묶음으로 내부 짧은 체험을 만드는 것은 가능하다.

그 다음에는 진도 보존/계정 원장, 실제 앱 진입, 첫26단계9장면을 구현한다.26단계는 최종 범위가 아니라 중간 검증이다. 현재 건축 갤러리의 ‘다음’ 버튼이나 정답 선택은 권리·조립 완료 근거가 아니다.

## 현재 소스와 보존할 WIP

일반 저장소: `C:/dev/hangulsori/ko_lernen_app`.

main의 기존 아트 정본:

- `assets/data/sarangchae_construction_v3.json`: 사랑채16.
- `assets/data/ildu_construction_art_v1.json`: 이번에 사용할4채49+안사랑/사당34. 다른 협문6·창고8은149에서 제외.
- `lib/data/ildu_turntable_catalog.dart`: 존재 여부와 최신 정본 일치 여부는 별개. 사랑채8면도 보완, 대문 최종형/문 열기 재검토 필요.

보존 대상 작업 공간:
`C:/dev/hangulsori/ko_lernen_app_worktrees/toilet-store-wall-plan-20260914`

HEAD: `e1c97d00b7c8a6db87d399e1547adc8799c21aaf`.

이 공간에는 **미커밋50단계 아트·카탈로그·Flutter 프로토타입**이 있다. main에 동일한 바이트가 있다고 간주해 삭제하거나 전체 브랜치를 병합하지 않는다. 문서 묶음의 병합/정리 승인은 이 WIP 삭제 승인이 아니다.

- `assets/data/ildu_settlement_construction_v1.json`: 터6·담8·대문12·화장실12·곳간12.
- `assets/illustrations/personal_hanok_v3/construction/{site,wall,toilet,gokgan}/`.
- `assets_unused/pending_review/personal_hanok_v3/construction_site_wall_toilet_gokgan_v1/`: 원본·제작 근거.
- 변경된 `docs/assets/ildu_sotdaeulmun_construction_20260914/construction_catalog.json`.
- `lib/models/ildu_settlement_construction.dart`, `lib/screens/ildu_settlement_screen.dart`, `lib/services/ildu_settlement_bookmark.dart`, `lib/widgets/ildu_settlement_map.dart`.
- `tool/build_ildu_settlement_catalog.py`, `tool/preview_ildu_settlement.dart`, `test/ildu_settlement_construction_test.dart`.
- main.dart, 공정 화면, pubspec, ARB/generated l10n, 테스트, UIUX inventory, graphify에도 미커밋 수정이 있다.

다음 구현에서는 아트와 필요한 데이터만 개별 검토해 가져온다. 프로토타입의 독립 진도 저장·가짜 문 열기·별도 웹 진입을 새 권한 구조로 그대로 옮기지 않는다. CSV의 `sourceRoot`는 검증한 로컬 출처이며 런타임 경로가 아니다. 다른 기기에서는 같은 파일을 확보한 후 hash로 출처를 재확인한다.

원본8장 정리에서 고유4장을 보존한 과거 변경은 `bbc0a8d119d864b0a3797574e46e68bd775c1047`로 이미 push했다. 경로는 `assets_unused/pending_review/personal_hanok_v3/references/sotdaeulmun/jin_20260914/`. 동일 작업을 다시 커밋하지 않는다.

## 꼭 지킬 기술 경계

- legacy→canonical 세대 이전은 옛 completed unit을 지울 수 있다. 보유 캡처를 그 전에 실행하며 실패를0으로 덮지 않는다.
- 현재 B2 비율34와 사랑채16 공개를 새149원장으로 전환할 때 보유를 보존한다. 그림 공개는 새 수동 조립 완료가 아니다.
- 수락 전 정상 학습도 인정한다. 의뢰 버튼이나 대화 감상이 능력 증거를 만들지 않는다.
- storage/course/account/cloud/receipt는 한 통합 담당자가 변경하고 계정 전환·재시도·삭제를 함께 검증한다.
- 평가 hash/내용 버전 갱신으로 이미 확정된 권리를 회수하지 않는다.
- 캐릭터 기본 정본을 교체하지 않고 기존 승인 포즈·클립으로 변화시킨다. 임시 소품과 영구 장식 소유를 구분한다.
- Flutter deferred components는 CP S5와 하나로 구현한다. 기본 설치 크기·팩 크기·기기 다운로드·설치 크기를 구분한다.
- telemetry에는 동의한 최소 ID/상태/오류 코드만. 답변 원문·자유 입력·녹음·평가 객체 전체 금지.

## 새 세션에 전달할 시작 문장

> `docs/superpowers/plans/2026-09-15-ildu-lernenweg-handoff.md`와 연결된 최종 설계·실행 계획을 읽고 이어서 작업해줘. 확정된149배분·정규평가ORunit·선택NPC/26생활의뢰·39조립·일상한국어·기존에셋재사용 방향을 다시 설계하지 말고, 최신main과CP작업을 확인한 뒤 Task1의 실제평가연결·의미검수·일반/catch-up149도달성부터 진행해줘. 문서 완료와 앱 구현 완료를 구분하고 미완성50단계WIP를 보존해줘.
