# 안사랑채·사당문·사당 실제 공정 아트의 앱 연결

사용자 요구: 웹 사이트와 선 도식으로 대체하지 않는다. 승인한 완성 정본을 고정하고 건물의 입체 공간·용도 차이를 유지한 실제 공정 PNG를 Flutter 앱 학습 흐름에서 보여준다.

## 전역 조건
- 안사랑채 14, 사당문 8, 사당 12단계. 정본 마지막 3장은 기존 PNG와 바이트가 같아야 한다.
- PNG 경로: assets/illustrations/personal_hanok_v3/construction/{ansarangchae,sadangmun,sadang}/stage_NN_{stepId}.png.
- 단계 id·한국어·영어·독일어 문장과 관찰 문구는 docs/assets/ildu_ansarang_shrine_construction_20260914/construction_design.json.
- 정본 해시: ansarangchae b5f58783f01005b6babac4ac5a85a7b8a86e3f06c90154e4cbc670fee1f47497; sadangmun 336dcc5251b2f3edfaaa57d0dbd2902b0034491f36c4eda8fdc01a5c0d52be4e; sadang 8cfc8bb5ca7ce6ae652c9defd1eb0bb3b523ac29eef1cf3afc6e370223869069.
- 공통 캔버스·정본 시점과 기둥·보·서까래 접점을 유지한다. 앞뒤 공간, 안사랑채 오른쪽 투명 툇공간, 사당문 두 기둥과 두 문짝, 사당 세 칸·맞배지붕을 지킨다.
- 학습 최초 완료 시 전후 공정 → 한국어 용어 → 짧은 설명, 상세 다시 보기 KO/EN/DE. 관람·재생이 XP나 진도를 만들지 않는다.
- 커밋·푸시·병합·출시하지 않는다. 기존 사용자 작업을 보존한다.

## 작업 1: 실제 공정 원화
이미지 생성 도구로 구조 공정부터 확인하고 중간 31장을 파생한다. RGB 채색을 스크립트로 대체하지 않는다. 투명도가 생성되지 않은 결과는 사용자 승인된 알파 추출 방식만 적용한다. 실제 PNG·해시·치수·생성 프롬프트를 등록한다.

## 작업 2: Flutter 앱 연결
기존 IlDuConstructionArtCatalog, IlDuConstructionScreen, HanokLearningReceipt 흐름에 3개 시리즈를 추가한다. 앱이 실제 PNG를 소비하고 단원 최초 완료에서 해당 공정으로 이어지게 한다. existing six series preserved. 루트가 생성하는 PNG가 들어오면 실제 해시·치수로 카탈로그 데이터를 등록하는 도구를 준비하고 실행한다. 미래 파일을 가짜 해시로 등록하지 않는다.

## 작업 3: 검증과 검토
정본 해시·공정 누적·실제 파일 존재·캔버스·알파 검증, 카탈로그·앱 화면·최초 완료·재생 회귀 테스트. 가능하면 Flutter 실제 화면에서 이미지와 번역을 확인한다. 검토 결과를 반영하고 Graphify를 갱신한다.
