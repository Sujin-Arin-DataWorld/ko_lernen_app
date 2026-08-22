# Batch 20 A1–C2 전체 콘텐츠 표면 확장

작성일: 2026-08-22

상태: Jin 통합 승인에 따른 실데이터 승격 완료

품질 경계: Beyond Humanizer v2·자동 검증 완료, 독립 원어민 검수는 미완료

## 완료 체크리스트

- [x] A1–C2 각 레벨에 새 어휘팩 1개, 카드 12개 추가
- [x] A1–C2 각 레벨에 문법 2개 추가
- [x] A1–C2 각 레벨에 시나리오 1개와 퀘스트 5개 추가
- [x] A1–C2 각 레벨에 스몰토크·빈칸·문장 만들기 각 6개 추가
- [x] A1–C2 각 레벨에 발음 문장 2개 추가
- [x] A1–C2 각 레벨에 미디어 표현·단어 관계 각 4개 추가
- [x] A1–C2 각 레벨에 문법 패턴·문화 노트 각 1개 추가
- [x] A1–C2 각 레벨에 끝말잇기 단어 8개 추가
- [x] 어휘팩 표시명·정렬·단청 문양 등록
- [x] 코스 단원·개념·Can-do·스몰토크 의미 경로 연결
- [x] 앱 실데이터, Cloud Function 문법 패턴 미러, 감사 수량 정본 갱신
- [x] 초안·리뷰 원장·매니페스트·검수 패킷 생성
- [x] PDF clean-room 경계와 2026 연구 출처 기록
- [ ] 독립 한국어·독일어 원어민 최종 검수
- [ ] 새 발음 문장의 실제 TTS 합성·업로드(이번 변경에서는 dry-run만 허용)

## 추가량

| 콘텐츠 | 이전 | 이후 | 증가 |
|---|---:|---:|---:|
| 어휘 | 2,348 | 2,420 | +72 |
| 문법 | 232 | 244 | +12 |
| 시나리오 | 407 | 413 | +6 |
| 시나리오 퀘스트 | 1,704 | 1,734 | +30 |
| 스몰토크 | 486 | 522 | +36 |
| 빈칸 | 1,769 | 1,805 | +36 |
| 문장 만들기 | 2,297 | 2,333 | +36 |
| 발음 원문 | 72 | 84 | +12 |
| 미디어 표현 | 112 | 136 | +24 |
| 단어 관계 | 90 | 114 | +24 |
| 문법 패턴 | 37 | 43 | +6 |
| 끝말잇기 | 2,680 | 2,728 | +48 |
| 문화 노트 | 30 | 36 | +6 |

핵심 초안 210개, 보조 게임 108개, 시나리오 내부 퀘스트 30개다. 음절 퍼즐은
승인된 20개×6레벨 번들을 임의로 덮어쓰지 않았다. Batch 20의 새 2–3음절
어휘는 다음 결정론적 퍼즐 재생성 때 후보가 된다.

## 레벨별 학습 축

| 레벨 | 주제 | 주요 언어 행동 |
|---|---|---|
| A1 | 도시 서비스와 이동 | 위치 묻기, 간단히 요청하기, 운영시간 확인하기 |
| A2 | 집 구하기와 계약 | 조건 확인, 허용 여부 질문, 선호를 부드럽게 말하기 |
| B1 | 취업과 근무 조건 | 조건 비교, 경험 설명, 잠정 계획과 양보 표현 |
| B2 | 주거비·이주·사회 참여 | 기준 제시, 원인과 대안 비교, 정중하게 이견 말하기 |
| C1 | AI 투명성·문화 노동 | 근거 한계 밝히기, 편향·책임·보상 구조 토론하기 |
| C2 | 인구 담론·제도 책임 | 프레임 분석, 인과 추론 비판, 구제·이의 제기 설계하기 |

문장은 특정 통계값을 외우게 하지 않고, 근거의 범위·행위자·선택 기준·책임과
구제 절차를 말하게 설계했다. 같은 의사소통 사건을 한국어·독일어·영어에서
각 언어답게 실현하되 의미, 관계, 발화행위와 CEFR 기능은 보존했다.

## 2026 주제 신호의 공식 출처

- 독일 물가·주거·에너지와 고용 주제: [독일 연방통계청 물가 보도자료](https://www.destatis.de/EN/Press/2026/08/PE26_283_611.html), [독일 연방통계청 노동시장](https://www.destatis.de/EN/Themes/Labour/Labour-Market/Unemployment/_node.html)
- AI 투명성·집행 일정: [EU 집행위원회 2026-08-02 안내](https://digital-strategy.ec.europa.eu/en/news/commission-starts-enforcing-ai-act-rules-and-new-transparency-requirements-2-august), [EU AI Act 시행 일정](https://ai-act-service-desk.ec.europa.eu/en/ai-act/eu-ai-act-implementation-timeline)
- 한국 인구·주거·가구 구조 주제: [통계청 인구주택총조사 자료](https://www.kostat.go.kr/boardDownload.es?bid=11739&list_no=439063&seq=1), [통계청 장래인구추계 2022–2072](https://www.kostat.go.kr/board.es?act=view&bid=207&list_no=428476&mid=a10301020100&ref_bid=&tag=)
- 2026 K-컬처 확산 주제: [문화체육관광부 MyK FESTA 보도자료](https://www.mcst.go.kr/english/policy/pressView.jsp?pSeq=647)

이 출처에서는 시의성 있는 교육 주제와 사고 기능만 추상화했다. 문장·대화·문제·
선택지·단원 순서·페이지 식별자는 복사하지 않았다. 연구 결과의 정확한 수치가
바뀌어도 학습 문장이 거짓이 되지 않도록 정량 주장 대신 비교·검증·논증 기능을
중심으로 만들었다.

## 재현 명령

```powershell
python tools/content_factory/promote_batch_20_full_surface.py
python tools/content_factory/validate_promoted_batch.py --manifest tools/content_factory/drafts/batch_20_manifest.json
python tools/content_factory/validate_content.py
python tools/content_factory/build_can_do_segments.py --check
python tools/content_factory/audit_game_loader_coverage.py --check
python tools/content_factory/audit_batch_live_promotion.py --check
```

생성기는 반복 실행해도 같은 ID와 실데이터 투영을 만든다. 문구가 바뀌면 새 ID를
만드는 대신 승인된 copy-revision 절차를 따르며, 의미 경로가 바뀌는 스몰토크는
새 지문과 명시적 Can-do 승인 없이는 빌드되지 않는다.
