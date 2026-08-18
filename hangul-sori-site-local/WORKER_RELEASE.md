# Hangul Sori website release

The website is deployed directly from this GitHub-tracked directory to the
Cloudflare Worker `hangul-sori-redesign`. ChatGPT Sites and ZIP uploads are not
part of the release path.

## Local release

Use Node 24.18.0 from `.node-version`. A production release must be a clean,
committed `main` checkout already pushed to `origin/main`.

```bash
npm ci
npm run cloudflare:login    # one time per machine
npm run deploy              # checks, deploy, and live production verification
```

`npm run deploy:preview` uploads a version without changing production traffic.
Preview URLs must be enabled for the Worker before its alias can be opened.

## GitHub Actions production deployment

The repository `CI` workflow is the preferred production owner. A push to
`main` that changes this directory or `docs/data/cultural_glossary.json` first
passes the website release gate, then deploys from the exact commit through the
protected `cloudflare-production` environment. The one-time setup is documented
in `../docs/GITHUB_ACTIONS_CLOUDFLARE_SETUP.md`.

Do not leave a Cloudflare Workers Builds production deployment enabled after
`WEBSITE_PRODUCTION_RELEASE_ENABLED=true`. Two production owners can race the
same commit and make rollback evidence ambiguous.

## Cloudflare Workers Builds fallback

If GitHub Actions cannot be used, Workers Builds remains a supported alternative.
Connect the GitHub repository with these settings:

- Worker: `hangul-sori-redesign`
- Production branch: `main`
- Root directory: `/hangul-sori-site-local`
- Build command: `npm run deploy:check`
- Deploy command: `npm run deploy:production`
- Builds for non-production branches: disabled
- Include watch paths: `hangul-sori-site-local/*, docs/data/cultural_glossary.json`

Workers Builds installs locked dependencies before the build command and reads
Node 24.18.0 from `.node-version`. Prefer **Create new token** during setup, and
never select a token that the dashboard marks as missing Email Routing
permissions. Token creation alone is not proof: only the first successful build,
deploy, binding check, and exact live Git SHA verification proves the connection.

Disable the old Sites deployment and any build that targets the repository-root
`hangulsori` Worker. That legacy Worker serves `docs/` and is not the owner of
the production custom domains. Its historical configuration is intentionally
named `../wrangler.legacy-docs.jsonc`, so `wrangler deploy` from the repository
root cannot accidentally publish it.

`../docs/CNAME` is intentionally absent. Re-adding it would make the legacy
GitHub Pages source claim `hangul-sori.com` again.

## Verification and rollback

`npm run deploy`, the GitHub Actions release job, and the Workers Builds fallback
bake the Git
commit SHA into the Worker, deploy with Wrangler strict mode, and require that
exact SHA on both domains. They verify 11 public routes, exact plain-text 404s,
security headers, all owned public assets, binding presence, and the gated
store CTAs. If the new version fails verification and is still the active version, the
release command rolls back to the exact previously active Worker version.

For a manual or stricter check:

```bash
npm run verify:live
npm run verify:live:external  # also fetches the Apple TestFlight page
```

Then, when doing a manual release check:

1. Open `https://hangul-sori.com` and confirm the current release renders.
2. Click its App Store and Google Play CTAs. Confirm both open the tester
   application form instead of a store link — Apple and Google only let a
   tester in after we add that email, so nobody may reach a store first.
3. Open `https://www.hangul-sori.com` and repeat the render and CTA checks.

List versions through the pinned, sanitized wrapper:

```bash
npm run cf -- versions list --config wrangler.jsonc
```

Roll back with:

```bash
npm run rollback -- <VERSION_ID>
```

The tester binding check does not send mail. A real one-message delivery canary
exists separately and must be run only when an actual email is intended:

```bash
npm run verify:live:email
```

A version rollback does not recreate a deleted Custom Domain. If either apex or
`www` was removed, restore both code-declared triggers without rebuilding with:

```bash
npm run repair:domains
```

The repair command first validates the deployment contract, then applies only
the Custom Domains declared in the source `wrangler.jsonc` and runs the live
verification. It deliberately does not depend on `dist/` or a successful app
build, so it remains usable during a domain-only incident. Wrangler currently
labels its pinned trigger command experimental; that warning is expected. If
the command itself fails, repair the build and use the full `npm run deploy`.
After a rollback, repeat the manual checks above as well.
