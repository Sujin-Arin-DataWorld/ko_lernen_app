# 한글소리 학습 흐름과 서체 비교 · 2026-09-28

`index.html`은 실제 Flutter 학습 흐름을 먼저 보여준다. `flutter-{learning,practice,feedback,result}-{de,en}.png`는 **수정한 Flutter 앱 위젯**을 390×844로 렌더링한 화면이다. `comparison-en.png`와 `comparison-de.png`만 브라우저 글꼴 목업이다. 화면의 본문과 동작 정본은 Flutter 코드다.

## 선택과 적용

GitHub의 [`nextlevelbuilder/ui-ux-pro-max-skill`](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)을 설치해 `typography`, `ux`, `flutter` 규칙을 참고했다. 같은 내용과 화면 폭에서 기존 Paperlogy+Maru Buri, Pretendard, Noto Sans KR 단독, IBM Plex Sans + Noto Sans KR을 비교했다. 2026-09-30 선택에 따라 현재 Flutter 앱은 **한국어·독일어·영어 모두 Noto Sans KR**을 쓴다. 본문은 Regular(400), 제목과 카드 문장은 Medium(500), 주요 버튼은 SemiBold(600)로 구분한다. 한글소리 텍스트 로고의 자간도 넓혔다.

비교 목업의 공항 문장은 `assets/data/scenarios_a1.json`에서 가져왔다. 실제 Flutter 학습 화면에서는 본문·다음 대화·피드백의 문장 카드 전체를 눌러 소리를 듣는다. 재생 중 소리 표시와 카드 강조가 반응하고, 선택지·진행 게이지·호랑이 동작·정답 피드백·완료 장면이 학습 단계에 따라 바뀐다. 기존 학습 흐름·진행 저장·한국어 음성 서비스를 재사용한다. 움직임 줄이기 설정에서는 반복 모션을 멈춘다.

## 글꼴 검증

Noto Sans KR 가변 파일 `assets/fonts/NotoSansKR/NotoSansKR-Variable.ttf`와 OFL을 앱에 동봉했다. 한글 완성형 11,172자와 독일어 `ÄäÖöÜüß`, 영어 글리프가 모두 있음을 폰트 cmap으로 확인했다. IBM Plex Sans 파일은 이전 시안과 비교할 수 있도록 저장소에 남기지만 앱 번들에서는 제외했다. 영어·독일어 390px Flutter 캡처와 320px 큰 글자 위젯 테스트로 학습 화면 배치를 확인한다.

원본 출처: [IBM Plex 공식 저장소](https://github.com/IBM/plex), [Noto Sans KR 공식 저장소](https://github.com/google/fonts/tree/main/ofl/notosanskr), [Pretendard 공식 저장소](https://github.com/orioncactus/pretendard). 비교용 원본과 라이선스는 `fonts/`, 실제 앱 번들은 `assets/fonts/`에 있다.
