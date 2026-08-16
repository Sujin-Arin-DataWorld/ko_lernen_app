# Reference Intake

이 디렉터리는 외부 참고 자료의 판독 상태와 clean-room 콘텐츠 brief를 분리해 관리한다.
원문, OCR 텍스트, 페이지 이미지, 표 셀 덤프를 저장하는 곳이 아니다.

작업 순서는 다음과 같다.

1. `source_inventory.csv`에 파일 메타데이터와 권리 경계를 기록한다.
2. 텍스트 추출과 실제 렌더를 비교한 결과를 `page_audit.csv`에 기록한다.
3. 일반화된 교육 신호만 `reference_observations.csv`에 기록한다.
4. source 추적 정보를 완전히 제거한 제품 brief를 `content_briefs.csv`에 만든다.
5. 기존 live ID와 새 draft ID의 연결을 `seed_bundle_plan.csv`에 고정한다.
6. `python3 tools/content_factory/validate_reference_intake.py`를 실행한다.

상세 열 계약과 PDF 판독 규칙은
`docs/CONTENT_REFERENCE_INTAKE_GUIDE.md`를 따른다. `content_briefs.csv`와
`seed_bundle_plan.csv`만 독립 작성 구역으로 넘어갈 수 있으며, 앞의 세 파일은 콘텐츠 생성
입력으로 사용하지 않는다.
