# AGENTS.md — ko_lernen_app (Hangul Sori)

> 이 파일은 **모든 AI 에이전트/환경**(Codex, Claude Code, Cursor, Gemini 등)이 세션 시작 시 읽는 공통 진입점이다.
> 어떤 도구로 시작하든 아래 규칙을 먼저 따른다.

## ⛔ 필수 규칙 (예외 없음)

1. **세션 시작 시 `CLAUDE.md`를 끝까지 읽고 시작한다.** 프로젝트의 파일 맵·아키텍처·패턴·전체 세션 로그·금지 사항이 모두 거기에 있다. `CLAUDE.md`가 이 저장소의 단일 진실 원천(SSoT)이다.
2. **무엇이든(코드·데이터·에셋·설정·문서) 하나라도 변경하면 반드시 `CLAUDE.md`의 "## 세션 로그"에 항목을 남긴다** — 무엇을·왜·검증 방법·커밋 해시. 기록 없이 변경만 커밋하는 것은 금지. 로그 갱신은 같은 커밋 또는 직후 커밋에 포함한다.
3. **커밋/푸시는 Jin(사용자)이 명시적으로 요청할 때만.** 동시 세션이 흔하므로 커밋 시 **본인이 만진 파일만** 골라 스테이징한다.
4. 상세 운영 규칙(Dart 문법·로컬라이제이션·마스코트·팔레트·금지 사항 등)은 `CLAUDE.md` 참조.

## 프로젝트 한 줄 요약

독일어권 사용자를 위한 한국어 학습 Flutter 앱. 상세 = `CLAUDE.md` "앱 개요" 이하 전체.

## 최신 세션 작업 (전체 이력은 CLAUDE.md "세션 로그")

- **2026-07-31 — Cloze/데일리챌린지 정답 단어 강조 + 여유로운 반응형 선택지 (커밋 `9341b4f`)**: 독일어 번역 문장에서 정답 단어를 인라인 강조(신규 공유 위젯 `lib/widgets/sori/cloze_prompt.dart`의 `splitEmphasis`/`ClozePromptCard`/`ClozeOptionsList`), 선택지를 화면 하단까지 균등 분산. 뜻은 `korean_vocab.csv` `german` 열 런타임 조회. 배지/필 UI 미사용(Jin 선호). 검증: analyze 0 · cloze_prompt 9 + daily_challenge 9 + responsive 157 통과. 실기기 시각 검증은 Jin.
