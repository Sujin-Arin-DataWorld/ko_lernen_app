# 한글소리 웹사이트 로컬 수정 안내

이 폴더가 `hangul-sori.com`의 실제 원본입니다. React, TypeScript, CSS,
이미지·영상, 테스터 신청 API와 Cloudflare Worker 설정까지 부모
`ko_lernen_app` GitHub 저장소가 모두 추적합니다. ZIP이나 ChatGPT Sites는 사용하지
않습니다.

## 1. Mac 또는 Windows에서 열기

`.node-version`에 고정된 **Node.js 24.18.0**을 설치한 뒤 이 폴더에서 실행합니다.
다른 Node 메이저 버전이면 `npm ci`가 일부러 실패해 잘못된 환경의 배포를 막습니다.

```bash
npm ci
npm run dev
```

터미널에 표시된 로컬 주소를 브라우저에서 열면 됩니다. 종료는 `Control + C`입니다.

## 2. 자주 수정하는 파일

| 수정할 내용 | 파일 |
| --- | --- |
| 독일어·영어·한국어 메인 문구와 섹션 | `app/site.tsx` |
| 색상·글꼴·카드·모바일 디자인 | `app/globals.css` |
| 사이트 제목·검색 설명 | `app/layout.tsx` |
| 스토어·TestFlight 주소 | `app/store-links.ts` |
| 개인정보 처리방침 | `app/privacy/page.tsx` |
| 이용약관 | `app/terms/page.tsx` |
| Impressum | `app/impressum/page.tsx` |
| 고객지원 | `app/support/page.tsx` |
| 계정 삭제 안내 | `app/account-deletion/page.tsx` |
| 테스터 신청 API | `worker/tester-application.ts` |
| 로고·이미지·영상 | `public/` |

## 3. 배포 전 확인

```bash
npm run deploy:check
```

이 한 명령이 lint, TypeScript, 예전 `dist/` 제거, 새 빌드, 공개 경로,
개인정보 동의, 보안 헤더, 테스터 신청, TestFlight 링크, Worker 바인딩,
Cloudflare strict dry-run과 전체 의존성 보안 감사를 포함한 17개 자동 테스트를 모두
검사합니다. Sites 실행 파일, 필수 원본, 배포 식별자가 빠진 상태도 실패합니다.

## 4. 직접 배포

처음 한 번만 Cloudflare에 로그인합니다.

```bash
npm run cloudflare:login
```

OAuth credential은 평문 설정 파일이 아니라 운영체제 키체인(macOS Keychain 또는
Windows Credential Manager)에 저장됩니다.

직접 배포할 때는 변경을 먼저 Git에 커밋하고 `main`을 `origin/main`에 push해야 합니다.
그다음 아래 한 명령이면 빌드·테스트·dry-run·운영 배포·실제 도메인 확인이 순서대로
실행됩니다.

```bash
npm run deploy
```

이 명령은 편집 중인 미커밋 파일, `main`이 아닌 브랜치, 최신 원격 `main`보다 오래된
빌드를 운영에 올리지 않습니다. 배포된 모든 응답의 Git SHA를 확인하고, 새 버전 검증이
실패했는데 그 버전이 아직 운영을 소유하고 있으면 직전 Worker 버전으로 자동 복구합니다.

반드시 이 `hangul-sori-site-local` 폴더에서 실행하세요. 저장소 최상단의 예전
`hangulsori` 정적 Worker 설정은 `wrangler.legacy-docs.jsonc`로 격리되어 있으며,
현재 도메인 배포에는 사용하지 않습니다.

운영 트래픽을 바꾸지 않고 버전만 올리려면 `npm run deploy:preview`를 사용합니다.
Worker에서 Preview URLs가 켜져 있어야 별도 주소로 열 수 있습니다.

운영 배포 없이 현재 사이트만 다시 확인하려면 아래 명령을 사용합니다.

```bash
npm run verify:live
npm run verify:live:external  # Apple TestFlight 도착 페이지까지 확인
```

실수로 apex 또는 `www` Custom Domain을 삭제했다면 Cloudflare 화면에서 임의로
추가·삭제하지 말고 아래 한 명령으로 코드에 선언된 두 도메인을 복구합니다.

```bash
npm run repair:domains
```

이 명령은 먼저 도메인·Sites 차단 계약을 검사한 뒤 `wrangler.jsonc`에 선언된 두
Custom Domain만 다시 연결하고 운영 주소를 검증합니다. 앱 빌드가 깨졌거나 `dist/`가
없는 긴급 상황에서도 사용할 수 있습니다. Wrangler가 trigger 명령의 experimental
경고를 표시하는 것은 현재 고정 버전에서 정상입니다. 명령 자체가 실패하면 코드를
고친 뒤 전체 재배포 명령인 `npm run deploy`를 사용합니다.

## 5. Git push 자동배포

Cloudflare Workers Builds에서 GitHub 저장소를 한 번 연결합니다.

- Worker: `hangul-sori-redesign`
- Production branch: `main`
- Root directory: `/hangul-sori-site-local`
- Build command: `npm run deploy:check`
- Deploy command: `npm run deploy:production`
- Builds for non-production branches: 끔
- Watch path: `hangul-sori-site-local/*`

연결 후에는 사이트 파일 수정 → `npm run deploy:check` → 커밋 → `main` push만 하면
됩니다. 첫 Workers Build가 실제로 성공해 정확한 커밋 SHA가 두 도메인에 나타난 것을
확인하기 전에는 토큰 권한과 자동배포 완료를 가정하지 않습니다. 기존 Sites 프로젝트와
저장소 루트의 레거시 `hangulsori` Worker 자동빌드는 끕니다. 자세한 복구·롤백 절차는
`WORKER_RELEASE.md`에 있습니다.
