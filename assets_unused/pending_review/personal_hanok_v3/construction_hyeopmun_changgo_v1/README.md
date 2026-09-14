# 협문 6단계·창고 8단계 — 제작 패키지

**현재 상태: Jin 승인 정본 / 앱 학습 화면 연결.** 14장 모두 고정 캔버스의 투명 PNG이다. 중간 12장의 마젠타 배경만 추출·정리하고 리사이즈했으며 마지막 2장의 원본 바이트는 유지했다. 원화의 미세한 기둥·기단 및 창고 3→4단계 용마루 높이 차이는 남아 있다. 픽셀 단위 누적 정합을 통과했다고 주장하지 않는다.

앱 경로: /hanok/construction. 정본 등록과 해시는 promotion.json 및 assets/data/ildu_construction_art_v1.json을 따른다. 보상·건축 진행도 API는 유지한다.

## 보기

- [단계별 학습·전체 비교 화면](review.html)
- [협문 전체 6단계 비교](hyeopmun/comparison.html)
- [창고 전체 8단계 비교](changgo/comparison.html)
- [KO/EN/DE 학습 설명표](learning.md) · [CSV](learning.csv) · [JSON](learning.json)
- [원본·단계·생성 시도 해시](manifest.json)
- [도면 연결](stage_blueprints.json) · [도면 원본·해시](source_evidence.json)
- [기계 검사 결과](validation.json) · [시각 검수 기록](QA.md)

HTML은 같은 폴더 구조를 유지하면 로컬 파일로 열 수 있다. 서버로 볼 때는 패키지 폴더에서 실행한다.

~~~powershell
python -m http.server 8786 --bind 127.0.0.1
~~~

브라우저 주소: http://127.0.0.1:8786/review.html

## 정본 고정

기준 커밋: 3b6d1ca1327d7429b6bf6f244aea8f61f09bc97d.

| 건물 | 최종 파일 | 캔버스 | SHA-256 |
|---|---|---|---|
| 협문 | hyeopmun/stages/stage_06_complete.png | 1568 × 2021 | 3a6e3141f0f9c763067d40a867cf94082df04f119ba275c037b6e67645153884 |
| 창고 | changgo/stages/stage_08_complete.png | 2736 × 1536 | 867495181c3507a29bca0efc43778bf6a958018b05992caba3fa40a01a3d9488 |

두 최종 파일은 원본을 바이트 그대로 복사했다. 색 보정, 알파 수정, 재인코딩하지 않았다.

## 파일 구성

- references: 정본 복사본과 도면 8장.
- 각 건물의 raw: 생성 도구의 출력 원본. 후보와 폐기 사유는 generation_ledger.json에 있다.
- 각 건물의 prompts: 생성 요청문.
- 각 건물의 stages: 승인한 투명 공정 그림 14장.
- learning.json: 한국어를 의미 기준으로 작성한 14단계 설명과 과제. 현대 학습 장면은 역사 기록과 구분한다.
- exercise_design.json: 선택형 과제의 문장과 정답 연결. 앱 안의 선택 연습에 연결되며 보상에는 연결되지 않는다.
- glossary.json: 부재 이름의 짧은 KO/EN/DE 보조 설명.
- build_review.py: PNG를 읽어 검사하고 JSON·Markdown·CSV·HTML을 생성한다. 이미지 픽셀은 편집하지 않는다.
- prepare_runtime_art.py / promote_runtime_art.py: 승인한 후보의 마젠타 추출·리사이즈 및 런타임 복사·해시 검사.
- qa: 원본 후보의 과거 브라우저 증거, 승인 후 비교표와 로컬 서버 로그.

## 다시 검사하기

~~~powershell
python prepare_runtime_art.py
python promote_runtime_art.py
python build_review.py --check
~~~

기계 검사 결과는 86개 통과, 0개 실패다. 14장 파일·캔버스·투명 알파·최종 해시와 언어 필드·도면 연결을 검사한다. 구조의 픽셀 정합과 역사적 복원 정확도를 대신 판정하지 않는다.

원화의 작은 형태 차이는 QA.md에 기록했다. 앱 API·진행도 저장·보상은 유지하며 승인한 공정 그림과 학습 설명을 별도 런타임 카탈로그에 연결한다.

별도 학습 삽화: lessons/storage_box_cloth.png (현대 생활 예시). 프롬프트는 lesson_illustration_prompt.txt, 파일·해시는 lesson_illustrations.json에 있다. 건물 PNG와 합성하지 않았다.

## 앱 번들 용량

승인 PNG 14장은 단계 폴더에 그대로 보존한다. 앱은 중간 12장과 생활 삽화를 원본 캔버스·동일 알파의 WebP q82 method6로 사용하고, 마지막 두 PNG는 원본 바이트를 유지한다. 전체 추가 이미지 번들은 23,660,940바이트(22.56 MiB)이며, 24 MiB 상한을 테스트한다. 기존 65,296,526바이트보다 약 64% 작다. 원본과 런타임 해시는 promotion.json 및 앱 카탈로그에서 구분한다.
