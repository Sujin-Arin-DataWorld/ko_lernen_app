# 통합 생성기·연결 명세 작성자 외 검토

2026-11-02 14:51 Europe/Berlin. 검토자 `author_a12`는 통합 생성기·공통 문서의 작성자가 아니다. ROOT 코드·연결표·원고를 수정하지 않고 이 보고서만 작성했다.

최종 상태: **MODEL_QA_PASS — 정적 집필·연결 명세 범위**. 남은 P1/P2/P3 수정 소견은 없다. 아래 필드 명확화 권고도 ROOT가 반영한 뒤 재확인했다. 사람 원어민·교사 승인, 학습 효과, 음성 청취, 앱·기기 동작 승인으로 확대하지 않는다.

## 실제 검토 범위

- `build_package.py` 전문을 읽어 고정 BASE Git blob 입력, 기존 34단원 상속, 새 18단원 보존, 실제 콘텐츠 ID 조인, 동형어 제외, 번역 제안, 서사 원문 재사용, R16 맥락 출력과 Markdown 렌더를 검토했다. 생성기를 직접 실행해 다른 파일을 재작성하지 않았다.
- README, EVIDENCE_AND_FLOW, REFERENCE_DECISIONS 전문을 읽었다. UNIT_CONTENT_LINKS의 52행·403참조, HANOK_CONTEXT_LINKS의 128행, 번역 제안 2건과 lexical sense 86행을 대조했다.
- 선택된 20개 고유 시나리오의 원래 인물·관계·장소 및 KO/EN/DE 대화 전문을 기준 Git blob에서 읽었다. 선택은 단원 전체를 대체하는 것이 아니라 기능 일부의 선택적 현대 재연습으로 적절하다. 모든 legacy phase/game 문항 본문을 새로 의미 감사한 것은 아니다. 해당 참조에는 실행 전 전체 문장 선수 지식·뜻 검토 조건이 남아 있다.
- 52단원의 narrative_bridge 필드 전체를 같은 단원 원래 서사의 scene_title/micro_conflict/npc/player_action/visible_narrative_consequence/next_hook/spoiler_gate/recall_seed와 구조 비교했다.
- 생성된 52개 편집자용 Markdown에서 사건·행동·결과·다음 사건 원문을 검사했다. 새 18단원 233문항은 material 전체 JSON이 빠짐없이 렌더되어, 존재하는 response_scope 값도 포함됨을 확인했다. 이는 편집자 문서의 렌더 검사이며 Flutter 학습자 UI 검사와 다르다.
- source ID·해시, packet 현재 해시, R16 ID·art 해시와 원본 119파일 동결 스냅샷을 독립 읽기 전용 검사로 확인했다.

기준 SHA: `646c4658e70f594ab234a172679e29122d0f0e66`.

## 확인 결과

| 항목 | 직접 확인한 결과 |
|---|---|
| 묶음 수 | 52 = 기존 상세 34 + 새 상세 18. 새 대화 152턴·문항 233개이며 README 수와 일치 |
| 서사 원문 재사용 | 52/52 narrative_bridge가 같은 원래 단원의 8필드와 정확히 일치. 새 인물·핵심 단서를 조합해 만들지 않음 |
| 원문 QA 지위 | 원래 NPC EN/DE의 QA 미완료 지위를 그대로 포함. README·render·서사 상태 필드에서 기존 QA 자동 승격을 부인 |
| 실제 콘텐츠 ID | 403/403가 선언한 파일의 기준 SHA Git blob 안에서 실제 ID로 존재. 8개 참조 소스의 SHA-256도 모두 일치 |
| 현재 원고 | 52 packet_sha256 모두 현재 패킷 파일과 일치. 재생성 이전의 17개 오래된 패킷 해시는 최종 결과에서 해소됨 |
| 수량 개·병 | A1.2-04에서 dog/Hund `vocab_a1_0628`, illness/Krankheit `vocab_a1_0680` 참조가 제거됨. 해당 sourceVocabId에 연결된 Cloze/Satz도 이 경로에서 빠짐. excluded_lexical_matches에는 제외 이유를 보존 |
| 번역 제안 | 아니다 `vocab_a1_0759`, 걸리다 `vocab_a2_0264`의 실제 원문 German 값과 제안 source_value 일치. 각각 A1.1-06/A2.2-05의 copy_overrides_required에 연결. 적용 완료가 아닌 proposed_authoring_override_not_runtime으로 별도 기록 |
| 어휘 뜻 | 86행은 목표 형태와 뜻을 비교한 뒤 남긴 참조다. 검토한 범위에서 추가 동형어 오연결을 발견하지 못함. 드리다/계시다의 vocab_b2_* 접두사는 실제 ID이며 source level 열은 A1이라 접두사를 근거로 고치지 않음 |
| R16 | 128/128 building/process ID와 art asset/hash가 기존 카탈로그와 일치. unit construction은 process_id/owned_stage/price=null, grants_currency=false. 공정별 맥락도 소유·자격이 아닌 관계임을 명시 |
| 원본 보존 | SNAPSHOT_MANIFEST의 119파일 실제 copied_sha256 모두 일치. 추적 runtime assets/lib/web/pubspec의 BASE 대비 Git diff는 없음 |
| 편집자 렌더 | 52단원 원문 사건/행동/결과/다음 사건 표시, 신규 233문항 material 전체 렌더. 허용 답·도움이 함께 보이는 편집자 자료라고 명시 |

## 구현·증거 경계 검토

README는 집필 후보와 앱 탑재를 분리한다. EVIDENCE_AND_FLOW는 향후 구현의 제시 조건이라고 시작하며 실제 재생·저장·평가 구현을 주장하지 않는다. I/R에서 목표 번역·모형을 숨기고, 해당 능력의 답 단서 요청은 도움으로 남긴다. R은 실제 다음 날 간격과 새 자극이 확인돼야 하며 지금 재시도를 지연 회상으로 올리지 않는다. T 자유 발화는 자동 의미 채점 대상이 아니다. A2.2의 선택형 I/R 성공도 독립 한국어 산출 숙달로 부르지 않는다.

선택지 ID 판정과 short의 제한 형태 비교를 구분한다. 목록 밖 자연스러운 답은 판정 보류 또는 비채점 전이로 넘기므로 허용 문자열 목록을 모든 자연스러운 답의 배타적 정답으로 일반화하지 않는다. 오답·도움·번역 노출 뒤 성공은 최초 독립 시도 기록을 덮어쓰지 않는다.

본편 공개 상태와 학습 목표·지원 수행·독립 수행·지연 회상·건축 소유·엽전의 상태 소유자를 분리한다. lessonDone나 정답 수로 본편 사실·소유·재화를 자동 승격하지 않는다. 미공개 고택 장면 대신 현대 역할 카드에 머무는 조건과 A2.2 S1-E06.middle 조건도 명시돼 있다. 복귀는 이미 열린 지점으로 제한된다. 마이크·음성 실패 경로를 듣기/발음 성취로 대신 인증하지 않는다.

검토 범위에서 런타임 구현 완료·전반적 독립 숙달·실소유·실지급을 새로 주장한 문구를 발견하지 못했다.

## 문서 명확화 수정과 재확인

최초 검토에서는 EVIDENCE_AND_FLOW의 short 단락이 모든 short에 material.response_scope가 있는 것처럼 읽힐 수 있음을 지적했다. 실제 JSON은 A1.2 short 32개 모두에 이 필드가 있고, A2.1 short 49개는 명시적 빈칸과 lexical_base/지시로 범위를 제한한다.

ROOT가 A1.2는 material.response_scope를 상황·지시와 함께 표시하고, A2.1은 실제 필드명 material.frame_ko와 지시의 제한 범위를 제시한다고 구분했다. 수정 단락을 다시 읽어 필드명과 적용 범위가 실제 JSON에 맞음을 확인했다. 없는 필드가 전부 존재한다는 뜻이 아니며, 현재 편집자 렌더는 존재하는 material 전체를 빠짐없이 포함한다. 이 소견은 해결됐다.

추가로 validate_package.py의 고정 curriculum 선수 배열 대조, 원래 서사 8필드 동일성, 신규 원고 현재 SHA가 작성자 외 검토 문서에 존재하는지, R16 art asset/SHA 대조와 119개 동결 바이트 검사를 읽었다. 최종 VALIDATION.json은 52단원/403참조/128공정/18개 현재 원고 검토 해시에서 PASS, errors/warnings 빈 배열이다. 검토자는 이 검사기를 실행해 ROOT의 결과 파일을 다시 쓰지 않았다.

## 추가 문법 카드 연결 검토 — 14:51 Europe/Berlin

추가 범위: GRAMMAR_CARD_LINKS.json 전체 52행, 그중 회화 24단원에 선정한 81참조/76고유카드의 실제 원문 형태·수준·KO 예문·EN/DE 설명/예문/주석 및 단원별 function/reason/reuse_scope/unlinked_targets. 원래 264행 grammar.csv는 기준 SHA Git blob으로 읽었고 sparse checkout의 runtime CSV를 복원하거나 수정하지 않았다. 원래 quiz 메타데이터를 실제 실행하는 연결은 하지 않으며 quiz 선택지의 교육 적합성 전체를 이번에 승인한 것은 아니다.

결과: **MODEL_QA_PASS**. 28입문은 not_applicable, 회화24는 각각 실제 카드1~4개로 제한된다. 81개 모두 실제 ID·pattern·source_level·source_path·source_sha256이 원문과 일치한다. 원문 전체 SHA-256은 `327bc56efe4456c01eaa980b76981cacb1ae4eb38a19816f439ba616bb730cde`다. 각 카드의 quiz_binding은 not_bound_requires_separate_review이며 미학습 어휘·선수 형태·관계·기존 quiz 선택지의 사전 검토 조건을 둔다.

선정 함수는 단원 목표의 해당 기능 일부와 맞는다. 다음의 모양만 같은 기능은 동일 카드로 억지 연결하지 않는다.

- A2.1-05 목적 V-게와 방식·상태 수식 A-게는 다르므로 adverbial 카드를 제외한다.
- 독립 동사 드리다·성함의 어휘와 V-아/어 드리다 수혜 보조용언은 동일하지 않으므로 원고에 남긴다.
- 감탄 -는데요와 배경·약한 대조 -는데, 담화 추가 -고요와 행동 순서 -고는 따로 둔다.
- A2.1-04의 -아/어야 하다 카드는 원고 -아/어야 되다와 관련 의미 참고로만 연결하며 원고 허용 답을 교체하지 않는다.
- 의지·추측, 현재 진행·결과 상태, 개인 결정·상대 확인 합의, 주체 높임·청자 대우·수신자 높임의 구별을 reuse_scope에서 유지한다.

일부 원래 카드의 넓은 주석(이유 연결의 시제, -다가의 같은 주어, -네요의 지각 출처 등)을 모든 원고의 배타적 규칙으로 승격하지 않는 제한을 확인했다. 카드 예문의 학교·학원·영수증·장인어른 등 어휘와 관계를 이미 배운 것으로 가정하지 않는다. ID의 b1/b2 같은 접두사를 source_level이나 새 해금 조건으로 사용하지 않는다.

추가 생성 결과에서 81개 ID·pattern·reason이 24개 회화 review 원고의 카드 표에 모두 표시된다. 이 연결은 별도 GRAMMAR_CARD_LINKS 명세이며 기존 UNIT_CONTENT_LINKS의 403참조와 구분해 집계된다. README와 REFERENCE_DECISIONS도 설명 카드와 단계 문항·기존 퀴즈를 구분한다. 카드 원문·기존 quiz·동결52 unit JSON을 수정했다고 주장하지 않는다. 카드 열람을 대화·도움·독립 수행·지연 회상·서사·소유·보상으로 합산하지 않는 completion_scope가 있다.

최종 VALIDATION.json은 grammar_card_references=81, 기존403참조·52단원·128공정·현재 원고검토해시18개·동결파일119개에서 PASS이며 errors/warnings는 빈 배열이다. 남은 수정 소견은 없다. 이 판정은 문법 카드 연결의 의미·출처와 정적 렌더 범위이며 런타임 실행·카드 quiz 승인·사람 원어민 승인을 뜻하지 않는다.

## 검토 스냅샷

문법 카드 보강 뒤 아래 바이트로 최종 갱신했다. 이후 변경된 문구·연결은 재확인이 필요하다.

| 파일 | SHA-256 |
|---|---|
| build_package.py | `85c8b01d0c78c98b410a6b6ad0f139a7b50794198635acbab149fc14e31b8170` |
| validate_package.py | `c28fa4b96686385cd26636b9414822ca7dda8b69b756c90735a8ddaa07ad383e` |
| README.md | `04df1a1d449d00a9bc724771e695b982a02a4479e17948c4e72a697a79d393fd` |
| EVIDENCE_AND_FLOW.md | `183ab14054bde3f014df2481a4323d2745e11b11014fa50a8fa08f9c930da419` |
| REFERENCE_DECISIONS.md | `ce3fc75a247c6ecda2e3fc5358846610c12d90e6f5360b69df7110f671273077` |
| GRAMMAR_CARD_LINKS.json | `5dd53e62ca18d90f139676c60f0d12298904c64595aaf93685da9fafd8833fda` |
| UNIT_CONTENT_LINKS.json | `4fc2275760c65dce325e551122da24dde223c209984c17829e17a703042e9fe2` |
| HANOK_CONTEXT_LINKS.json | `65643828b4963f1f911acd34eb0a32042ac7ec95a5632d22b1e6e53190dfcf63` |
| TRANSLATION_PATCHES.json | `44581438994aea54b36e3dd4b54e8c26d2c17f6b2acf935017e57059287886f5` |
| VALIDATION.json | `9b50fcde69c8cc736652a14aff584914bf7e5f1db91468c7405d6b2b811569a0` |
