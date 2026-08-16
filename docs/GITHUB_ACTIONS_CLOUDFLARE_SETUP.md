# GitHub Actions → Cloudflare 홈페이지 자동 배포

`main`의 홈페이지 또는 공통 문화어 데이터가 기존 홈페이지 gate를 통과하면
`hangul-sori-redesign` Worker를 배포하고, 배포한 Git SHA가 실제 두 도메인에 노출되는지
검증한다. 검증 실패 시 기존 배포 스크립트의 안전한 rollback 계약을 그대로 사용한다.

## 최초 1회 설정

1. Cloudflare의 기존 **Workers Builds** Git 연결이 켜져 있다면 production 자동 배포를
   끈다. GitHub Actions와 Workers Builds를 동시에 production 배포 주체로 두지 않는다.
2. GitHub 저장소에 `cloudflare-production` Environment를 만들고 배포 브랜치를
   `main`으로 제한한다. 완전 자동 배포를 원하면 required reviewer는 설정하지 않는다.
3. 이 Environment에 아래 Secrets를 추가한다.

   - `CLOUDFLARE_API_TOKEN`: `hangul-sori-redesign` Worker와 두 Custom Domain에 필요한
     최소 권한의 Cloudflare API token
   - `CLOUDFLARE_ACCOUNT_ID`: 해당 Worker를 소유한 Cloudflare account ID

4. Repository variable `WEBSITE_PRODUCTION_RELEASE_ENABLED`를 `true`로 설정한다. 이 값이
   없거나 `true`가 아니면 production 배포 job은 안전하게 건너뛴다.

현재 저장소에는 repo-level `CLOUDFLARE_API_TOKEN`이 하나 있지만, 배포 환경에 한정된
secret으로 옮기고 현재 Worker·Custom Domain 권한을 다시 확인하는 편이 안전하다.
account ID나 token 값을 코드·문서·Actions 로그에 직접 넣지 않는다.

## 자동 배포 범위

- `hangul-sori-site-local/**`
- `docs/data/cultural_glossary.json`
- 홈페이지의 루트 배포 계약 파일

문화어 JSON은 Flutter asset이자 홈페이지 build 입력이므로 이 파일만 바뀌어도 Flutter와
홈페이지 gate가 모두 열린다. 홈페이지 gate가 성공한 뒤 release job이 다시 깨끗한 exact
commit에서 locked dependencies를 설치하고 `npm run deploy`를 실행한다. 이 명령은 build,
lint, typecheck, tests, strict dry-run, security audit, production deploy, live SHA 검증을
포함한다.

자동 실행 실패를 수정한 뒤 다시 올릴 때는 GitHub Actions의 `CI` workflow에서
`release-website`를 선택한다. 이 수동 실행도 홈페이지 gate와 enable variable을 우회하지
않는다.

## 자동화가 대신할 수 없는 확인

- 실제 Android/iOS WebView와 모바일 브라우저에서 문화어 시트의 터치·포커스 확인
- Cloudflare 대시보드의 token 범위 및 Custom Domain 소유 상태 확인
- 이메일 tester binding의 실제 메시지 발송 확인

이메일 canary는 의도치 않은 메일을 보내지 않도록 자동 배포에 포함하지 않는다.
