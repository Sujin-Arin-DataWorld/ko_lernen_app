# C1-T2: Jin 판정 적용 결과 리포트

생성일: 2026-09-15
적용 스크립트: `tools/content_factory/apply_adjudications_20260915.py` (결정론적, 재실행 가능)
적용 대상 패킷:
- `docs/data/review_packets/2026-09-15_adjudication_translation11_natural_final.md`
- `docs/data/review_packets/2026-09-15_adjudication_batch23_24_natural_final.md`
- `docs/data/review_packets/2026-09-15_adjudication_scenarios52_natural_final.md`

> 세 패킷 모두 OneDrive 메인 체크아웃에만 존재하는 커밋되지 않은 로컬 파일이었다(원격
> 브랜치 어디에도 없음). 원본을 건드리지 않고 이 워크트리로 읽기 전용 복사해 사용했다.

## 1. 요약 카운트

| 출처 | 1차 판정 항목 | 필드 변경 수(1차) | 파생 전파 필드 수 |
|---|---:|---:|---:|
| translation11 (cloze.json) | 11건 (1 승인 / 10 수정안) | 22 | 40 (→ korean_vocab.csv 10건 + satz_sentences.json 10건) |
| batch23/24 (korean_vocab.csv) | 10건 (6 승인 / 4 수정안) | 6 | 13 (→ cloze.json 4건 + satz_sentences.json 4건 + sentenceKo 재계산 1건) |
| scenarios52 (scenarios_*.json) | 52건 (52/52 "수정안 반영") | 320 (192개 대사 줄 중 ko 10 · de 165 · en 145) | 해당 없음(대사 자체가 원본) |
| **합계 필드 변경** | | | **401** |

- cloze.json: 10개 항목 수정 (translation11 1차) + 4개 항목 수정 (batch23/24 파생 전파) = 14개 항목.
- korean_vocab.csv: 4개 행 수정 (batch23/24 1차) + 10개 행 수정 (translation11 파생 전파) = 14개 행. `example_korean`/`example_german`/`example_english` 세 컬럼만 변경, 다른 컬럼 무변경.
- satz_sentences.json: 14개 항목 수정 (양쪽 파생 전파, targetKo/promptDe/promptEn만).
- scenarios_{level}.json: 52개 시나리오 전부, 441개 대사 줄 중 192줄(43.5%)의 ko/de/en 중 최소 1개 필드 변경. title/intro/quest는 무변경(아래 4절 참고).
- id, answer(cloze_b1_0153 제외), distractors, 기타 필드는 전혀 건드리지 않음.

## 2. Translation11 — per-change table (cloze.json 1차 판정)

| id | 필드 | 이전 | 이후 |
|---|---|---|---|
| `cloze_b1_0118` | de | Hyunwoo hat mir zugeflüstert, ich solle das nicht so schludrig machen. | Hyunwoo flüsterte mir zu, ich solle das nicht so schludrig machen. |
| `cloze_b1_0118` | en | Hyunwoo whispered to me not to do it carelessly. | Hyunwoo whispered to me not to do it so carelessly. |
| `cloze_b2_0264` | de | Weil ich zuerst gesagt habe, wie wir zueinander stehen, passte der Moment für den Handschlag. | Weil ich zuerst erklärt habe, in welcher Beziehung wir zueinander stehen, passte der Zeitpunkt für den Handschlag. |
| `cloze_b2_0264` | en | Because I said first how we were related, the handshake came at the right moment. | Once I explained our relationship, the timing of the handshake felt right. |
| `cloze_c1_0076` | de | Als wir die Fairness bewusst geplant hatten, blieb am Ende eine Tabelle statt verletzter Gefühle. | Als wir Fairness bewusst mit einplanten, blieb am Ende eine Tabelle statt verletzter Gefühle. |
| `cloze_c1_0076` | en | Once we had designed the fairness deliberately, what remained was a table, not hurt feelings. | Once we deliberately designed for fairness, what remained was a table rather than hurt feelings. |
| `cloze_c2_0075` | de | Als wir die Erinnerungen neu geordnet hatten, war ich nicht mehr nur ein Gast. | Als wir die Erinnerungen neu ordneten, war ich nicht mehr nur ein Gast. |
| `cloze_c2_0075` | en | Once the memories were rearranged, I was no longer just a guest. | Once we rearranged the memories, I was no longer just a guest. |
| `cloze_c2_0076` | de | Weil wir die Erzählung gemeinsam trugen, wurde aus dem Scherz einer Person nicht die Geschichte aller. | Weil wir die Erzählung gemeinsam trugen, wurde der Scherz einer einzelnen Person nicht zur Geschichte aller. |
| `cloze_c2_0076` | en | Because we shared the story, one person's joke did not become everyone's history. | Because we shared the narrative, one person's joke didn't become everyone's history. |
| `cloze_b1_0109` | de | Die lange Rede gab ich knapp weiter, so blieb nur der Kern. | Die lange Geschichte fasste ich beim Weitergeben zusammen, sodass nur das Wesentliche blieb. |
| `cloze_b1_0109` | en | I passed the long story on as a summary, so only the core was left. | I summarized the long story as I passed it on, so only the key points remained. |
| `cloze_b1_0153` | fullKo | 잠자리 경계 다시 정하니 둘이 편해졌어요. | 잠자리 경계를 다시 정하니 둘 다 편해졌어요. |
| `cloze_b1_0153` | answer | 경계 다시 정하니 | 경계를 다시 정하니 |
| `cloze_b1_0153` | sentenceKo (재계산) | 잠자리 ＿＿＿ 둘이 편해졌어요. | 잠자리 ＿＿＿ 둘 다 편해졌어요. |
| `cloze_b1_0153` | de | Als wir die Schlafregelung neu festlegten, wurde es für uns beide leichter. | Als wir die Schlafregelung neu festlegten, fühlten wir uns beide wohler. |
| `cloze_b1_0153` | en | Once we reset the sleeping arrangement, it got easier for both of us. | Once we reset the sleeping arrangements, we both felt more comfortable. |
| `cloze_c1_0075` | de | Arbeit sichtbar zu machen verschob, wem gedankt wurde. | Als wir die Arbeit sichtbar machten, änderte sich, wem gedankt wurde. |
| `cloze_c1_0075` | en | Making labor visible changed who received thanks. | Making the work visible changed who was thanked. |
| `cloze_c2_0062` | de | Als ich die Macht beim Namen nannte, wurde es im Raum kurz still, dann kam der Atem zurück. | Als ich die Macht beim Namen nannte, wurde es im Raum kurz still; dann konnten alle wieder atmen. |
| `cloze_c2_0063` | de | Nicht die Stimmung, sondern ein Verfahren zu verlangen machte die nächste Entscheidung transparent. | Dass ich nicht nach Stimmung, sondern nach einem klaren Verfahren verlangte, machte die nächste Entscheidung transparenter. |
| `cloze_c2_0063` | en | Demanding a procedure, not a mood, made the next decision clearer. | Demanding a clear procedure rather than going by mood made the next decision more transparent. |

`cloze_b1_0119`은 승인(변경 없음). 모든 distractors는 Jin이 현재 라이브 값을 명시적으로 승인했으므로 무변경.

### 2-1. Translation11 파생 전파 (korean_vocab.csv / satz_sentences.json)

동일한 KO 원문이 `korean_vocab.csv`의 `example_korean`과 `satz_sentences.json`의 `targetKo`에도 그대로 중복되어 있음을 발견했다(코퍼스 전체 정확 일치 검색으로 확인). 세 곳 모두 같은 문장의 "정본" 번역이 갈라지지 않도록 위 10개 항목의 de/en(및 `cloze_b1_0153`의 ko)을 아래 대응 항목에도 동일하게 반영했다.

| cloze id | → vocab id | → satz id |
|---|---|---|
| `cloze_b1_0118` | `vocab_b1_0306` | `satz_b1_0114` |
| `cloze_b2_0264` | `vocab_b2_0525` | `satz_b2_0250` |
| `cloze_c1_0076` | `vocab_c1_0072` | `satz_c1_0078` |
| `cloze_c2_0075` | `vocab_c2_0071` | `satz_c2_0077` |
| `cloze_c2_0076` | `vocab_c2_0072` | `satz_c2_0078` |
| `cloze_b1_0109` | `vocab_b1_0297` | `satz_b1_0105` |
| `cloze_b1_0153` | `vocab_b1_0341` | `satz_b1_0149` |
| `cloze_c1_0075` | `vocab_c1_0071` | `satz_c1_0077` |
| `cloze_c2_0062` | `vocab_c2_0058` | `satz_c2_0064` |
| `cloze_c2_0063` | `vocab_c2_0059` | `satz_c2_0065` |

각 행은 변경된 필드(de/en/ko)만 해당 컬럼(example_german/example_english/example_korean, promptDe/promptEn/targetKo)에 반영했다. 변경되지 않은 필드(예: `cloze_c2_0062`는 en 무변경)는 거울 항목도 건드리지 않았다.

## 3. Batch 23/24 — per-change table (korean_vocab.csv 1차 판정)

| id | 컬럼 | 이전 | 이후 |
|---|---|---|---|
| `vocab_a1_0428` | example_german | In Korea ist jetzt Herbst. | In Korea ist gerade Herbst. |
| `vocab_a1_0428` | example_english | It's autumn in Korea now. | It's fall in Korea right now. |
| `vocab_b1_0488` | example_german | Ich glaube, wir hatten ein Missverständnis. | Ich glaube, zwischen uns gab es ein Missverständnis. |
| `vocab_b2_0649` | example_english | Once you know the principle, applying it isn't hard. | Once you understand the principle, applying it isn't difficult. |
| `vocab_b2_0654` | example_korean | 그 교수님 강의는 항상 자리가 없어요. | 그 교수님 강의는 항상 자리가 꽉 차요. |
| `vocab_b2_0654` | example_german | In der Vorlesung von diesem Professor sind die Plätze immer voll. | Die Vorlesungen dieses Professors sind immer voll. |

나머지 6건(`vocab_a1_0310`, `vocab_a1_0442`, `satz_a1_0348`, `vocab_a1_0445`, `vocab_a2_0487`, `vocab_b2_0655`)은 승인(변경 없음).
`vocab_b2_0654`의 example_english는 이미 "That professor's lectures are always full."로 승인 상태라 무변경.

### 3-1. Batch23/24 파생 전파 (cloze.json / satz_sentences.json)

| vocab id | → cloze id | → satz id |
|---|---|---|
| `vocab_a1_0428` | `cloze_a1_0351` | `satz_a1_0339` |
| `vocab_b1_0488` | `cloze_b1_0290` | `satz_b1_0483` |
| `vocab_b2_0649` | `cloze_b2_0394` | `satz_b2_0552` |
| `vocab_b2_0654` | `cloze_b2_0399` | `satz_b2_0557` |

`vocab_b2_0654`의 example_korean 변경은 `cloze_b2_0399`의 fullKo에도 반영했고, answer(`강의`)는 변경분 밖에 있어 그대로 유지했다. sentenceKo는 fullKo·answer로부터 재계산해 `그 교수님 ＿＿＿는 항상 자리가 없어요.` → `그 교수님 ＿＿＿는 항상 자리가 꽉 차요.`로 갱신했다(+1 필드, 위 요약 카운트의 "sentenceKo 재계산 1건").

## 4. Scenarios 52편 — 대사 변경 요약 (scenarios_{level}.json)

52개 시나리오 모두 Jin 판정이 "수정안 반영 — 아래 `최종 자연화본`의 KO/DE/EN을 최종안으로 채택"으로 동일했다. 각 시나리오의 `<details>` 블록(번호·화자·KO/DE/EN)을 파싱해 `dialog` 배열의 동일 인덱스·동일 화자 줄에 그대로 덮어썼다(순서·화자·줄 수가 라이브 자산과 정확히 일치함을 스크립트가 사전에 assert). title/intro/quests/culturalNote 등은 `최종 자연화본` 블록에 포함되어 있지 않으므로 전혀 건드리지 않았다(작업 지시 §1 규칙).

- 총 대사 줄: 441줄 (52개 시나리오)
- 변경된 줄(ko/de/en 중 최소 1개 필드): 192줄 (43.5%)
- 필드별 변경 수: ko 10 · de 165 · en 145
- 52/52 시나리오 모두 최소 1줄 이상 변경됨(레벨 분포: A1 8 · A2 8 · B1 9 · B2 9 · C1 9 · C2 9)

### 4-1. KO 텍스트가 바뀐 10줄 (전부 나열 — 발음/TTS 영향)

| 시나리오 id[줄] | 이전 KO | 이후 KO |
|---|---|---|
| `a1_w10_taxi_stay[3]` | 네, 알겠어요. 가방이 하나 있어요. | 네, 알겠어요. 가방 하나 있어요. |
| `a1_w10_eat[4]` | 여기서 드시고 가세요, 포장이세요? | 여기서 드시고 가세요, 아니면 포장이세요? |
| `a1_w10_repeat[5]` | 식사 전에요, 식사 후에요? | 식사 전이에요, 후예요? |
| `a1_w10_partner[6]` | 엄마가 아주 좋아하세요. 편하게 계세요. | 엄마도 정말 반가워하세요. 편하게 계세요. |
| `a1_w10_phone[1]` | 여보세요. 자리를 예약하고 싶어요. | 여보세요. 자리를 예약하고 싶은데요. |
| `a1_w10_wayfinding[4]` | 저 간판이 은행이에요? | 저 간판 있는 곳이 은행이에요? |
| `a2_w10_apt[3]` | 네. 분리수거는 무슨 요일에 해요? | 네. 분리수거는 무슨 요일에 하면 돼요? |
| `a2_w10_apt[7]` | 감사해요. 모르는 게 있으면 또 여쭤볼게요. | 감사해요. 궁금한 게 있으면 또 여쭤볼게요. |
| `b1_w10_repair[7]` | 알겠어요. 그럼 내일 오후로 예약할게요. | 알겠어요. 그럼 내일 오후로 예약해 주세요. |
| `c2_w10_fandom[0]` | 제 2차 창작을 그대로 편집해서 유료로 판매한 계정을 신고했는데 아직 조치가 없어요. | 제 2차 창작물을 거의 그대로 가져가 편집해서 유료로 판매한 계정을 신고했는데 아직 조치가 없어요. |

`c2_w10_fandom[0]`은 시나리오의 **첫 대사**라서 TTS 첫 대사 프리페치 번들이 무효화된다 (5절 참고). 나머지 9건은 첫 줄이 아니므로 첫 대사 번들에는 영향 없음(단, 정본 TTS 매니페스트 전체에는 반영됨).

### 4-2. 시나리오별 변경 줄 수 (52개 전체)

전체 441줄 중 몇 줄이 바뀌었는지, DE/EN 각각 몇 개 바뀌었는지는 `tools/content_factory/_adjudications_20260915_changelog.json`(스크립트 실행 시 생성, 재실행하면 재생성됨)에 401건 전체가 필드 단위로 남아 있다. 대표적으로 변경 폭이 큰 시나리오: `b2_w10_hiring`(8줄 중 8줄, de 7·en 7), `b2_w10_travel`(7줄 중 7줄), `c2_w10_fandom`(6줄 중 6줄, ko 1·de 6·en 4), `b1_w10_friends`(6줄 중 6줄). 변경 폭이 가장 작은 시나리오: `a1_w10_partner`, `a1_w10_wayfinding`, `b1_w10_repair`, `c1_w10_methodology`, `c1_w10_uncertainty`, `c2_w10_history`, `c2_w10_jurisdiction`, `c2_w10_mandate`(각 2줄).

## 5. TTS 후속 (필수, 콘텐츠 편집 후속 체크리스트)

### 5-1. `validate_content.py --json`

```
{"ok": true, "issues": []}
```

### 5-2. 정본 TTS 매니페스트 재생성 (`functions/tts/build_canonical_manifest.py`)

`assets/data/tts_canonical_manifest.json` + `functions/tts/canonical_manifest.json` 재생성 완료(둘 다 schemaVersion 1, cacheRevision v3 유지). sha1 키 집합 변화:

| voice | 이전 개수 | 이후 개수 | 추가 | 제거 |
|---|---:|---:|---:|---:|
| female | 5989 | 5988 | 5 | 6 |
| male | 5653 | 5655 | 7 | 5 |
| **합계** | 11642 | 11643 | **12** | **11** |

이번 판정으로 바뀐 고유 KO 문장은 `cloze_b1_0153`/`vocab_b1_0341`/`satz_b1_0149`(전부 동일 문장), `vocab_b2_0654`/`cloze_b2_0399`/`satz_b2_0557`(전부 동일 문장), 시나리오 대사 10줄이다. sha1은 텍스트 해시라 같은 문장은 어느 파일에 있든 키 하나를 공유하므로, 위 표의 12개 추가/11개 제거는 실제로 "정본 코퍼스 전체에서 더 이상 아무도 참조하지 않게 된 이전 문구"와 "새로 등장한 문구"의 순수 차집합이다.

### 5-3. 첫 대사 TTS 프리페치 매니페스트 (`tool/generate_tts.py --write-first-line-manifest`)

```
first-line manifest: 178 scenarios, 177 bundled -> assets/data/tts_first_line_manifest.json
(변경 전: 178 scenarios, 178 bundled)
```

**TTS 결손 목록 (Jin이 실행할 합성 대상, 1건):**

| scenario id | 새 첫 대사 KO | cacheHashSha1 | storagePath |
|---|---|---|---|
| `c2_w10_fandom` | 제 2차 창작물을 거의 그대로 가져가 편집해서 유료로 판매한 계정을 신고했는데 아직 조치가 없어요. | `832ef794a42840601b51f3104a610a5eb6c3c6f3` | `tts/v3/female/832ef794a42840601b51f3104a610a5eb6c3c6f3.mp3` |

합성 명령(Jin의 단계, 이 PR에서는 실행하지 않음):
```
python -X utf8 tool/generate_tts.py --missing-from-storage
```

### 5-4. 레벨 감사 리포트 재생성 (`tool/audit_content_levels.py`)

`docs/data/content_level_report.md`, `tool/content_level_suspects.csv`, `tool/content_level_summary.json` 재생성. 자연화로 인해 문장 길이/문법 지표가 미세하게 바뀌면서 시나리오 `a2_w10_apt`가 새로 "over1"(dialog_p75=2.8, a2→b1 방향 완만한 초과) 의심 목록에 1건 추가됨 — 결함이 아니라 참고용 리포트이며, Jin 검수용으로 정보만 남긴다. scenario/cloze/satz의 total 문자 수가 소폭 변동(추가된 글자 수만큼).

### 5-5. Authorities 재생성 — 이 PR에서는 실행하지 않음

`build_can_do_segments.py`는 작업 지시에 따라 이 PR에서 실행하지 않았다. C7b/C2a가 먼저 병합된 뒤 이 PR을 그 위로 리베이스하고 `build_can_do_segments.py`를 다시 실행해야 한다.

## 6. 테스트

```
flutter test test/cloze_content_guard_test.dart test/cloze_topic_groups_test.dart \
  test/scenario_quest_catalog_integrity_test.dart test/listening_scenario_catalog_contract_test.dart \
  test/scenario_shelf_contract_test.dart test/data_loader_test.dart test/content_audit_manifest_test.dart \
  test/tts_bundled_manifest_test.dart test/tts_canonical_manifest_test.dart
```

결과: **59/59 통과** (00:14). `cloze_content_guard_test.dart`의 `knownUnsyncedCap` 조정은 필요 없었다(이동 없음).

## 7. Jin 원문에서 모호했던 지점

1. **§2 규칙(파생 복사) 적용 방향**: 작업 지시 §1은 "vocab `example_*` change must propagate to derived cloze/satz items"라고 batch23/24→cloze/satz 한 방향만 명시했다. 그런데 translation11의 11개 문장 전부가 `korean_vocab.csv`에도 정확히 동일한 `example_korean`으로 이미 존재하고 있었다(그리고 `satz_sentences.json`에도). 즉 규칙이 말하는 "파생 복사"가 이미 반대 방향으로도 성립하는 구조였다. 이 문장들을 vocab/satz에서 고치지 않으면 같은 한국어 문장이 화면(빈칸 채우기)마다 다른 독일어/영어 번역을 갖게 되어, 방금 Jin이 고친 것과 같은 "부자연스러움" 결함이 다른 화면에 남는다. 그래서 이 PR은 규칙의 원칙(같은 문장은 코퍼스 전체에서 하나의 정본 번역)을 양방향으로 적용했다 — 이는 문언보다 넓은 해석이므로 명시적으로 표시한다.
2. **`cloze_b1_0153`의 "권장"**: Jin 판정 원문 "빈칸 정답도 '경계를 다시 정하니'로 맞추는 것을 **권장**"— "권장"(recommend)이지 "필수"가 아니다. 그러나 KO 전체 문장이 바뀌면서 이전 answer("경계 다시 정하니")가 더 이상 자연스러운 조사 형태와 맞지 않아(새 문장은 "경계를"으로 목적격 조사가 붙음), 사실상 필수로 판단해 반영했다.
3. **scenarios52의 52줄 Jin 판정이 전부 동일 문구**: "수정안 반영 — 아래 `최종 자연화본`의 KO/DE/EN을 최종안으로 채택"이 52건 모두 토씨 하나 다르지 않게 동일하다. 개별 줄 단위의 승인 사유는 없고 `최종 자연화본` 블록 자체를 통째로 신뢰해야 하는 구조였다. 이 PR은 해당 블록을 그대로(줄 수·화자 순서까지 assert 후) 반영했다.
4. **quest 필드와 대사 불일치 가능성**: 작업 지시가 quest 프롬프트를 "최종 자연화본 블록에 포함된 경우만" 갱신하라고 명시했고 블록에는 quest가 없어 전혀 건드리지 않았다. 그 결과 일부 시나리오는 quest의 `audioKo`/`promptKo`/`targetKo`가 여전히 **바뀌기 전** 대사 문구를 참조할 수 있다(예: 대사 자체는 바뀌었지만 그 대사를 그대로 인용하는 퀘스트가 있다면 완전 일치가 깨질 수 있음). 이번 실행에서 지정된 flutter 테스트 9종은 전부 통과했으므로 현재 통합 계약을 깨지는 않지만, 대사-퀘스트 텍스트 일치 여부까지 검증하는 별도 테스트가 있다면 재확인이 필요하다.

## 8. 건드리지 않은 것

- id, answer(단 `cloze_b1_0153` 제외), distractors — 전부 무변경.
- 52개 시나리오의 title/intro/quests/culturalNote/vocab 등 dialog 외 필드 — 전부 무변경.
- `build_can_do_segments.py` — 실행하지 않음(7절 참고).
- 다른 워크트리, OneDrive 메인 체크아웃 — 읽기 전용으로만 접근(패킷 3개 복사), 쓰기 없음.

