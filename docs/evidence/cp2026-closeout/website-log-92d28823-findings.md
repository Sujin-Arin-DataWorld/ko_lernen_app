# User-provided Cloudflare failure log

- Source filename: `hangul-sori-redesign.production.92d28823-ea17-41c3-90e2-20befa5c1dcf.build.log` (archive-only)
- Preserved copy: `user-cloudflare-92d28823.build.log` in the original local archive A/session-closeout-20260928; not included here.
- SHA-256: `b2eb8751f3bff87d638818c2293b69aa628c5cdd8c4027403c428f3e4ffec88d` (source and copy verified identical).
- Release: `7a0a09819cb4482c6e075023d9b6710ea3873a6b`; failed Worker version `55884adc-74fa-4297-9d06-b32dcbd3c8da`.
- The 2026-09-28 18:13 UTC run uploaded and deployed the website, then its live verifier raised `DOMException [TimeoutError]`. Lint had zero errors and three image warnings; the warnings were not the deployment failure.
- Automatic rollback completed at 18:13:47 UTC to Worker `78433e77-4cca-40a6-b6b4-01652a467d43` (release `78f5ce41ac94cdf2d1451996e0b3dbad93ce5d19`).
- This is a website production verification failure, not an Android AAB build failure.
- In the current follow-up turn, fresh HEAD requests to both `https://hangul-sori.com` and `https://www.hangul-sori.com` returned HTTP 200 and `x-hangul-sori-release: 7a0a09819cb4482c6e075023d9b6710ea3873a6b`. This establishes that the logged rollback is historical; it does not replace the full live verifier or prove every route/asset.
- The log does not identify the exact timed-out URL. `scripts/verify-live.mjs` has a 20-second request timeout, but this alone does not establish which request or network condition caused the failure. Follow-up: report request path, method, elapsed time and error cause without logging credentials, while retaining release/asset/security checks and rollback behavior.
- Coordinator returned successful retry Build `ad7dd1d5-7193-4962-a6c1-1c993c2a6898`, Worker `381140b4-10c9-4a8e-8b19-e4a777c5c3d7`, completed at 2026-09-28 18:29:26 UTC. Root read `site-release-7a-verification.txt` (portable copy in this directory): exact release verified on both domains, 11 routes, 23 referenced build assets, 75 owned assets, 404 behavior, tester API GET rejection/binding presence, security headers and iOS/Android CTAs. Build ID/time are coordinator-reported; receipt contents and current HTTP headers were directly checked by root. No duplicate website deployment was started in response to this file.
