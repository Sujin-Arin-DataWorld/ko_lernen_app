# Autonomous Command Execution & No Approval Needed

1. **명령어 즉시 실행 원칙 (Flutter, Git, Python 등)**
   - `flutter`, `git`, `python`, `npm`, `bash` 등 작업에 필요한 모든 터미널 명령(`run_command`)은 **사용자에게 매번 물어보거나 확인을 기다리지 않고 즉시 직접 실행**한다.
   - 단, `git commit` 및 `git push`는 AGENTS.md의 SSoT 규칙에 따라 Jin이 명시적으로 요청했을 때만 수행한다 (그 외 `git status`, `git diff`, `git log`, `git checkout` 등 조회/검증 작업은 즉시 실행).

2. **계획 및 파일 작업 승인 생략**
   - 파일 접근, 읽기, 수정, 테스트 등 모든 작업에 대해 **별도 허가를 구하지 않고 자율적으로 진행**한다.
   - `implementation_plan.md`가 필요할 때도 `RequestFeedback: false`로 설정하고 자체적으로 빠르게 실행 단계로 넘어간다.
   - 질문(`ask_question`)은 **기능 명세의 치명적인 모호성이 있어 의도를 도저히 알 수 없을 때만** 극도로 제한적으로 사용한다.
   - 사소한 결정(파일 구조, 네이밍, 구현 방식 등)은 AGENTS.md 규칙에 따라 자체 판단하여 빠르게 처리한다.
