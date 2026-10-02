# 페르소나 상세 개선 검토 자료

인물 11명의 현재 사용량, 연령·역할 재배치 추천안, 관계 27개와 생활 주제 54개, 대화 초안 8개를 검토하는 자료입니다. 추천안은 정본에 적용하지 않았습니다. 준의 현재 정본은 9세이며, 16세·고1은 검토용 방향입니다.

- [인물·관계 검토 화면](review.html)
- [독립 외형 후보 5명](../persona_appearance_20261002/review.html)
- [현재 사용량 감사](PERSONA_AUDIT.md)
- [재배치 추천안](PERSONA_REDESIGN_PROPOSAL.md)

저장된 감사의 기준 HEAD와 소스 SHA-256은 `persona_usage.json`에 있습니다. 최신 체크아웃에서 다시 감사하려면 저장소 루트에서 아래 명령을 실행합니다. 갱신은 이 검토 폴더에만 기록됩니다.

```sh
python assets_unused/pending_review/persona_audit_20261002/audit_personas.py
python assets_unused/pending_review/persona_audit_20261002/validate_review.py
```

다른 체크아웃의 원본까지 대조하려면 검증 명령에 `--comparison-root <경로>`를 지정합니다. 생략하면 현재 체크아웃의 원본과 검토 자료를 검사합니다.

브라우저 검사에는 Playwright와 Chromium이 필요합니다. 검토 폴더를 로컬로 제공하고 `PERSONA_REVIEW_URL`에 인물·관계 화면의 디렉터리 URL을 지정합니다. `PLAYWRIGHT_MODULE`은 선택적인 모듈 경로이며, 생략하면 일반 `playwright` 패키지를 사용합니다.

```sh
python -m http.server 8000 --bind 127.0.0.1 --directory assets_unused/pending_review
# 다른 터미널에서 환경변수 PERSONA_REVIEW_URL=http://127.0.0.1:8000/persona_audit_20261002 설정 후:
node assets_unused/pending_review/persona_audit_20261002/qa/browser_check.cjs
```

`qa/browser_report.json`과 화면 캡처는 독립 검토 화면의 검사 결과입니다. 앱·실기기·CEFR·TTS 검수를 의미하지 않습니다. 앱 코드, 공개 인터페이스, 실사용 에셋과 기존 음성 계약을 변경하지 않았습니다.
