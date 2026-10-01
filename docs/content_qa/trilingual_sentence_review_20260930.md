# KO–EN–DE 학습 문장 교정: 2026-09-30 배치와 다음 검수

## 범위와 검수 상태

이 배치는 실제 앱이 읽는 문장 만들기·빈칸·어휘 예문을 고쳤다. 기준 커밋은
`9888e1b0`이다. 2026-10-01 원격 메인 `828e62e1`을 통합하고 승인 원본과
맞지 않는 A1 문항을 복구한 뒤에는 문장 만들기 문항 2,861개 중 **75개 행**이
현재 메인과 다르다.
아래 수는 수정 건수이며, 각 레벨의 **전수 언어 검수 건수나 원어민 승인 건수가 아니다**.

| 런타임 레벨 | 전체 Satz 문항 | 이번 배치 수정 |
| --- | ---: | ---: |
| A1 | 650 | 5 |
| A2 | 513 | 10 |
| B1 | 630 | 10 |
| B2 | 564 | 10 |
| C1 | 252 | 19 |
| C2 | 252 | 21 |

A1 다섯 건은 같은 작업 트리에서 앞서 시작한 교정분이다. A2–C2의 70건은 한국어의
활용·행위자·화행을 먼저 확인한 다음 영어와 독일어를 각각 다듬었다. B1의
`개통하다 전에` 같은 활용 오류는 Satz와 cloze 정답을 함께 고쳤다. C1–C2는
불확실성, 비교 가능성, 근거의 범위, 책임의 주체를 문장마다 확인했다. 예를 들어
`신뢰 구간이 넓다면 집단 간 순위 차이를 단정하기 어려워요`는 자료가 허용하지 않는
순위 단정을 피한다. `관행에 대한 호소만으로는 결정의 타당성을 입증할 수 없어요`는
영어·독일어에서도 같은 주장 강도를 유지한다.

고급 레벨의 어휘 풀이 17개를 다시 썼고, 다섯 한국어 표제어는 예문·문항까지 함께
고쳤다. 대표적으로 `공개 한계문 → 자료의 한계`, `설명 강도 → 주장의 강도`,
`청자 위치 → 청자 설정`, `관행 인용 → 관행에 대한 호소`,
`증언 위치 → 증언의 배치`다. 이 교정은 모델 검수이며 **한국어교육 전문가·영어 및
독일어 원어민의 최종 승인으로 표시하지 않는다**.

## 정본과 파생 자료

- 런타임: `assets/data/korean_vocab.csv`, `satz_sentences.json`, `cloze.json`.
  같은 문장을 쓰는 발음·음절 퍼즐·단어 관계 자료도 해당 항목을 맞췄다.
- 저작 원본: `tools/content_factory/data/packs/`와 해당 생성 스크립트.
  승인 당시의 `drafts/` 및 승인 CSV는 유지하고, 이후 앱 문구의 변경 지문만
  `tools/content_factory/review/promoted_copy_revisions_20260822.json`에 기록했다.
- 콘텐츠 연결: 어휘 행이 바뀌면 `python3 tools/content_factory/build_can_do_segments.py`
  로 `assets/data/can_do_content_authorities.json`의 지문을 갱신한다. 이를 빠뜨리면
  코스 로더가 `source vocab fingerprint mismatch`로 실패한다.
- 인물 말투의 정본은
  `tools/content_factory/canonical_scenarios/character_profiles.json`과
  `docs/CONTENT_PERSONA_VOICE.md`다. Satz의 이름 호명만으로 화자를 새로 지정하지
  않는다. 시나리오를 고칠 때는 `playerCharacterId`·실제 speaker·관계·레벨별
  말투를 먼저 확인한다. 이번 배치에서 시나리오 샤드의 대사 전체를 전수 편집하지는 않았다.

## TTS와 재현 확인

첫 교정에서 바뀐 한국어 발화의 v3 음성 캐시 **65개**를 합성해 Firebase Storage에
업로드했고, C1 `절대 건수` 문장을 다시 다듬은 뒤 새 키 **1개**를 더 올렸다.
`functions/tts/build_canonical_manifest.py`로 앱·함수의 정본 목록을
재생성했다. 2026-10-01 `generate_tts.py --verify-storage`의 키 검사 결과는
`expected 12,646 / remote 21,235 / missing 0`이었다. 이것은 저장소 키 완전성
검사이며 사람의 청취 평가나 실기기 재생 검사를 뜻하지 않는다. 원격 객체 전체에서
현재 정본 밖인 `stale` 객체는 삭제하지 않았다.

검증 명령과 결과:

```bash
python3 tools/content_factory/validate_content.py --json
python3 tools/content_factory/build_can_do_segments.py --check
python3 functions/tts/build_canonical_manifest.py --check
python3 tool/generate_tts.py --verify-storage
python3 -B -m unittest discover -s tools/content_factory -p 'test_*.py' -t .
flutter test --no-pub
flutter analyze --no-pub --no-fatal-warnings --no-fatal-infos
flutter build web --release
git diff --check
```

마지막 전체 Flutter 실행은 **8,211개 통과·53개 건너뜀·실패 0개**였다. Python
콘텐츠 전체 테스트는 **1,303개 실행·20개 건너뜀·실패 0개**였고,
`flutter analyze`와 웹 릴리스 빌드도 통과했다. 배포 여부는 Git main 반영과
별도로 판단한다.

**추가 확인(2026-10-01):** 승인 당시 Batch 09·18 초안을 현재 앱 문구와 혼동해
수정한 부분을 승인 원본으로 복구하고, 후속 카피의 정확한 지문을
`promoted_copy_revisions_20260822.json`에 따로 기록했다. 두 배치의
`validate_promoted_batch.py`는 각각 1,764건·132건으로 통과했다. Batch 31도
192건 통과했다. 이 조치는
새 문구의 사람·원어민 승인 주장이 아니다. 단어·예문 2,944개
묶음의 1차 재검토와 후속 교정 후보는
`docs/content_qa/vocab_example_review_20260930.md`, 대화·듣기는
`docs/content_qa/conversation_listening_review_20260930.md`에 기록했다.

## 다음 콘텐츠 검수 순서

1. **B1의 장면 의미를 먼저 잠근다.** `satz_a2_0222`의 `줄서다` 표기와
   줄이 생기는 시점, `satz_b1_0264`의 숙소 예약 `이월` 대상·행위자는 원문만으로
   확정하기 어렵다. 인물·예약 상태를 확인한 뒤 삼언어를 고친다.
2. **B2의 논증·절차 표현을 다시 본다.** `satz_b2_0314`의 가정과 숫자,
   `satz_b2_0317`의 반대 시나리오, `satz_b2_0324`의 상위 담당자 요청은
   실제 화행과 과제 정답을 함께 확인한다.
3. **C1·C2의 남은 직역과 단정문을 표본 검수한다.** C1의 `satz_c1_0137`
   (`지속 가능 조건`), `satz_c1_0149`(`결정 환류`), C2의 `satz_c2_0104`
   (`선택적 기억`)와 `satz_c2_0106`(`연대기 절단`)은 한국어 표제어 자체와
   EN·DE 용어를 함께 재검토한다. 어려운 단어로만 바꾸지 말고 근거 수준과
   학술·공적 장면의 말투를 맞춘다.
4. **법·정책처럼 들리는 C2 주장은 근거를 잠근 뒤 수정한다.**
   `satz_c2_0101`(권한 위임 없이 내린 결정의 효력), `satz_c2_0128`(자동 결정의
   자료 공개 의무), `satz_c2_0152`(동의 철회 후 추론 점수), `satz_c2_0155`
   (이의 기간의 자동 처리 정지)는 관할·제도·사실과 제안을 구분해야 한다.
   근거 없이 보편적 법적 의무를 새로 쓰지 않는다.
5. **페르소나 대사 전수 검수는 별도 배치로 진행한다.** A2–C2 시나리오의
   실제 화자·상대·du/Sie·한국어 높임·EN 친밀도를 관계 그래프에 대조한다.
   현재 Satz 문항 교정을 시나리오 대사 전체 승인으로 간주하지 않는다.

후속 배치도 한 문장을 고치면 KO 원문, EN·de-DE, 어휘 표제어, cloze 정답과
오답, 저작 원본, 코스 지문, TTS 캐시를 같은 단위로 갱신한다. `A2–C2 완료`나
`원어민 검수 완료`라는 상태는 전수 점검 및 해당 사람의 검수가 끝나기 전에는 쓰지
않는다.
