# Hangul Sori website

This directory is the source of truth for `hangul-sori.com`: React/TypeScript,
styles, media, legal pages, the tester application API, and the Cloudflare
Worker configuration. The parent `ko_lernen_app` GitHub repository tracks every
source file.

There is no ZIP handoff and no ChatGPT Sites release step.

## Requirements

- Node.js 24.18.0 (pinned in `.node-version`; npm rejects a different major)
- npm
- Cloudflare authentication only when deploying

## Local development

```bash
npm ci
npm run dev
```

The terminal prints the local URL. Source lives in `app/`, Worker code in
`worker/`, and images/video in `public/`.

## Quality gates

```bash
npm run deploy:check
```

The release check runs lint, TypeScript, a clean Vinext/Cloudflare build, 16
route/privacy/security/form/release tests, Wrangler strict-mode dry-run, and a
full dependency security audit. It also rejects missing runtime source,
removed Custom Domains, a mismatched build identity, and any reintroduced
ChatGPT Sites runtime.

## Deployment

Authenticate once, then use one command:

```bash
npm run cloudflare:login
npm run deploy
```

Production deployment accepts only a clean, committed `main` checkout that
matches `origin/main`. It records the exact Git SHA in every Worker response,
updates the existing `hangul-sori-redesign` Worker, and verifies both domains,
all public routes, the exact 404 contract, security headers, every owned asset,
the tester bindings, and the gated store CTAs. If verification fails while that
new version still owns production, the command restores the previously active
version automatically. Both `hangul-sori.com` and `www.hangul-sori.com` are
declared as Custom Domains in `wrangler.jsonc`.

The normal no-CLI release path is to commit the website changes and push
`main`; the repository GitHub Actions workflow runs the same gate and protected
deployment command. It also treats `docs/data/cultural_glossary.json` as a
website release input. Direct local deployment remains available for recovery.

To also check that the TestFlight invitation link we email to accepted iOS
testers is still live:

```bash
npm run verify:live:external
```

For Git-triggered deployment and rollback details, see
[`WORKER_RELEASE.md`](WORKER_RELEASE.md).
