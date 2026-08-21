# 연구 근거와 유지보수 기준

이 문서는 규칙을 설명하거나 갱신할 때 사용한다. 논문 문구를 앱 콘텐츠로 복사하지 않는다.

## 근거 축

- **CEFR Companion Volume (Council of Europe)**: 학습자를 social agent로 보고 mediation, online interaction, plurilingual/pluricultural competence를 포함한다. 레벨을 단어 희귀도만으로 정하지 않는다.
  https://www.coe.int/en/web/common-european-framework-reference-languages/cefr-companion-volume-and-its-language-versions
- **MQM Error Typology**: Accuracy, Terminology, Linguistic Conventions, Style, Locale Conventions, Audience Appropriateness 등을 분리한다. 자연성과 정확성을 한 점수로 합치지 않는다.
  https://www.themqm.org/mqm-pillars/typology/
- **MultiPragEval (Park et al., 2024)**: 영어·독일어·한국어 등에서 문맥과 함의 추론을 별도 능력으로 평가한다.
  https://aclanthology.org/2024.genbench-1.7/
- **Korean discourse translation test set (Lee et al., 2025)**: 한국어→영어 번역에서 lexical ambiguity, zero anaphora, slang, idiom, figurative language, implicature를 문맥 현상으로 분리한다.
  https://aclanthology.org/2025.coling-main.110/
- **Lost in Literalism (Li et al., 2025)**: LLM 번역에서도 목표어답지 않은 translationese가 지속될 수 있음을 분석한다.
  https://aclanthology.org/2025.acl-long.630/
- **Specification-Aware MT (WMT 2025)**: 목적, target audience 등 번역 사양이 결과와 평가에 중요하다. Translation Brief의 근거다.
  https://aclanthology.org/2025.wmt-1.7/
- **German Modal Particles as Discourse Signals (Seemann & Scheffler, 2025)**: `ja`, `doch` 등은 담화 관계와 상호작용하며 모든 문맥에 똑같이 자연스럽지 않다.
  https://aclanthology.org/2025.dnd-16.5/
- **English-speaking learners and Korean subject honorification (Jung et al., 2025)**: 영어 L1 학습자가 `-시-`를 일반 공손 표지로 과잉 해석할 수 있음을 보고한다.
  https://doi.org/10.1017/S1366728925100813
- **국립국어원**: 한국어 규범·학습자 사전·실용 표현과 corpus 접근의 우선 출처다.
  https://www.korean.go.kr/front_eng/main.do
- **IDS Mannheim DeReKo**: 독일어 연어·장르별 실제 용례를 확인하는 reference corpus다. corpus 문장을 제품 데이터로 복제하기보다 후보 검증에 쓴다.
  https://www.ids-mannheim.de/digspra/kl/projekte/korpora/

## 증거 사용 규칙

1. 코퍼스 빈도는 의미·화용 적합성을 자동 결정하지 않는다.
2. 병렬 corpus, comparable source, monolingual corpus를 구분한다.
3. 연구 결과를 특정 개인이나 모든 영어권·독일어권 학습자에게 일반화하지 않는다.
4. 한글소리의 실제 learner feedback과 한국어/EN/DE 원어민 검수를 gold evidence로 축적한다.
5. 자동 지표는 경보 장치다. 원어민·교육 전문가 판단을 대체하지 않는다.
6. 출처의 라이선스를 확인하고 문장·ID·단원 순서를 앱 데이터로 복제하지 않는다.
