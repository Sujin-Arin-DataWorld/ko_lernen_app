# Account transition and deletion release readiness

Last repository review: **2026-09-06**

This is an evidence checklist, not a deployment record. No function, hosting
configuration, rule, mobile build, DNS record, or store-console answer is live
merely because it exists in this repository. Keep every external item open
until the release owner attaches dated evidence from the production system.

## Current repository evidence

- [x] The public page consumes a one-time proof from a URL fragment, removes
  the fragment with `history.replaceState` before the network call, and sends
  JSON only to
  `https://hangul-sori.com/api/request-deletion-by-proof`.
- [x] The browser code uses a fixed first-party endpoint, `POST`,
  `redirect: error`, `mode: same-origin`, `credentials: omit`,
  `cache: no-store`, and `referrerPolicy: no-referrer`.
- [x] Browser output uses one neutral status for missing, malformed, invalid,
  expired, used, successful, and network-failed outcomes. It never interpolates
  a response body, exception, proof, UID, operation ID, or provider error.
- [x] Node tests cover ordering, destination, redaction, generic receipts, and
  malformed/missing fragments:
  `node --test docs/account-deletion-page.test.js`.
- [x] `firebase.json` stages a same-path Firebase Hosting rewrite to the
  `requestDeletionByProof` function in `europe-west3`.
- [x] The Apple adapter follows Apple's documented two-step protocol: it sends
  the fresh native authorization code only to
  `https://appleid.apple.com/auth/token` with
  `grant_type=authorization_code`, keeps the returned refresh token only in
  memory, and sends that token only to
  `https://appleid.apple.com/auth/revoke` with
  `token_type_hint=refresh_token`. The previous direct
  authorization-code-to-revoke design assumption was unsupported and is not
  implemented. The current native authorization request supplies no redirect
  URI, so the server does not invent one. See Apple's
  [token validation](https://developer.apple.com/documentation/signinwithapplerestapi/generate-and-validate-tokens)
  and
  [token revocation](https://developer.apple.com/documentation/signinwithapplerestapi/revoke-tokens)
  contracts.
- [x] `tool/verify_ios_firebase_config.dart` checks the tracked iOS Firebase
  option, tracked `GoogleService-Info.plist`, exact bundle/project identifiers,
  URL scheme, and Runner target membership. The accompanying fixture-only
  Flutter test covers the absent-option failure path.
- [ ] Production route evidence exists. `docs/CNAME` indicates that the public
  domain may currently be served by GitHub Pages, which does not apply the
  Firebase Hosting rewrite. Before release, prove either that the domain is
  served by Firebase Hosting or that an audited first-party proxy routes this
  exact path to the function. A static GitHub Pages 404 is not a deployment.

## Public page and HTTP security

- [ ] Serve both `account-deletion.html` and the proof endpoint with
  `Cache-Control: no-store`; verify the final browser response after every CDN
  or proxy, not only the function response.
- [ ] Serve `Referrer-Policy: no-referrer` on the HTML and endpoint. Confirm in
  browser developer tools that navigation and the proof POST emit no referrer.
- [ ] Apply a strict production CSP. Minimum intent:
  `default-src 'self'; script-src 'self'; connect-src 'self'; img-src 'self';
  style-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none';
  form-action 'self'`. Move inline code/style to local files or use reviewed
  hashes; do not weaken the policy with `unsafe-inline`.
- [ ] Add `X-Content-Type-Options: nosniff`, a restrictive
  `Permissions-Policy`, and clickjacking protection at the final edge.
- [ ] Redirect HTTP to HTTPS and verify certificate, renewal, supported TLS,
  canonical host, and no mixed content. Enable HSTS only after every affected
  host/subdomain is HTTPS-ready; record the chosen max-age and preload decision.
- [ ] Confirm no page contains an external form action, analytics tag,
  third-party script, marketing pixel, service worker cache, or outbound link
  capable of receiving the fragment.
- [ ] Confirm the proof is never placed in a query string, DOM attribute,
  rendered text, page title, local/session storage, cookie, clipboard,
  analytics event, crash report, screenshot, or support email.

## Endpoint boundary and abuse controls

- [ ] Keep the browser URL and server CORS allowlist at the exact production
  origin `https://hangul-sori.com`; reject wildcard, reflected, `null`,
  staging, `www`, and lookalike origins unless each is separately reviewed.
- [ ] Accept only `POST` with `application/json`, no query parameters, and the
  single expected JSON field. Confirm all other methods/content types/shapes
  return the same safe response body.
- [ ] Enforce the request-size limit at the outer proxy and function. Verify
  missing, malformed, negative, duplicated, and oversized `Content-Length`
  behavior plus decoded-body size; the application limit is 1,024 bytes.
- [ ] Replace any fail-closed placeholder with a durable production rate-limit
  adapter. Test per-source limits, distributed concurrency, IPv4/IPv6
  normalization, proxy-header trust, bounded storage, expiry, and safe
  behavior when the limiter is unavailable.
- [ ] Verify valid, invalid, expired, rotated, already-used, and already-deleted
  proofs all return the same generic public body. Confirm response loss and
  replay resume one operation rather than creating a second operation.
- [ ] Verify the hard proof expiry is checked transactionally and does not rely
  on a TTL cleanup job. Confirm one active proof per account and bounded
  issuance/rotation in production.
- [ ] Confirm all edge/CDN/function logs redact request bodies and authorization
  material. Disable body/query capture and sampling that could copy a proof.

## App Check, Firebase, and server configuration

- [ ] On an authorized macOS release workstation, verify the tracked,
  case-sensitive iOS bundle/Firebase configuration and Runner membership with
  `dart run tool/verify_ios_firebase_config.dart`; it must exit 0 before an iOS
  archive. Run FlutterFire only for an owner-approved registration or rotation
  in an isolated branch, and review both `lib/firebase_options.dart` and the
  tracked `GoogleService-Info.plist`. A nonzero verifier result is an open
  release gate, not a local test failure to suppress.
- [ ] Register and enforce Android Play Integrity and Apple
  App Attest/DeviceCheck for protected callables. Record production metrics
  before enforcement and test valid, missing, expired, replayed, debug, and
  wrong-project tokens.
- [ ] Keep the public proof endpoint outside the authenticated callable path;
  protect it with proof entropy, hard expiry, exact-origin checks, size limits,
  rate limits, and generic responses. Do not require users to expose an ID
  token on the public page.
- [ ] Provision the deletion-proof HMAC secret from a production secret
  manager with least-privilege access, rotation/recovery procedure, and no
  value in source, build artifacts, CI output, function environment dumps, or
  logs.
- [ ] Provision the Apple authorization-revocation configuration as four
  distinct Firebase Secret Manager secrets:
  `APPLE_REVOKE_CLIENT_ID`, `APPLE_REVOKE_TEAM_ID`,
  `APPLE_REVOKE_KEY_ID`, and `APPLE_REVOKE_PRIVATE_KEY`. The release operator
  must enter each value only through the Firebase CLI's hidden prompt or an
  equivalently reviewed secret-manager control. Do not put a value in a
  command argument, redirected file, environment dump, CI output, repository,
  support message, or deployment log. The private-key value is the complete
  reviewed Apple `.p8` key material; this repository contains no such value.
- [ ] From an authenticated release workstation, select and verify the intended
  project, then create or rotate each secret without printing its value:

  ```text
  firebase functions:secrets:set APPLE_REVOKE_CLIENT_ID --project <production-project-id>
  firebase functions:secrets:set APPLE_REVOKE_TEAM_ID --project <production-project-id>
  firebase functions:secrets:set APPLE_REVOKE_KEY_ID --project <production-project-id>
  firebase functions:secrets:set APPLE_REVOKE_PRIVATE_KEY --project <production-project-id>
  ```

  Attach dated evidence of the selected project ID and secret versions, but
  never the values.
- [ ] Deploy the reviewed revision of only
  `functions:gye-firebase-functions:completeAppleRevocation` first:

  ```text
  firebase --config firebase.json deploy --only functions:gye-firebase-functions:completeAppleRevocation --project <production-project-id>
  ```

  Confirm in the deployed function configuration that all four Apple secrets
  are bound to that callable and are not bound to
  `account_deletion_worker` or unrelated functions. The scheduled worker
  deliberately has no authorization code and only resumes after the callable
  has persisted the safe `appleRevocationComplete` checkpoint.
- [ ] In a production-equivalent Apple/Firebase staging environment, obtain a
  fresh transient authorization code through Sign in with Apple
  reauthentication and invoke the protected callable with valid, limited-use
  App Check. Record HTTP 200 from both Apple's token exchange and revocation,
  verify that the operation advances, and confirm retryable provider/network
  failures retain only
  `apple-revocation-retryable`. Inspect function, edge, Crashlytics, and alert
  records to prove that no authorization code, generated five-minute client
  secret JWT, refresh/access token, private key, request form, response body,
  header, or raw exception was captured. Source tests do not satisfy this
  external gate.
- [ ] Resolve and test the no-token fallback before release. Apple's
  [account-deletion guidance](https://developer.apple.com/documentation/technotes/tn3194-handling-account-deletions-and-revoking-tokens-for-sign-in-with-apple)
  says that when no refresh token, access token, or authorization code is
  available, the service must still delete the account data and direct the
  user to revoke the Apple authorization manually. The current app retries the
  protected exchange/revoke flow and has no reviewed manual-fallback state or
  user handoff; source success for the normal path does not close this gate.
- [ ] Verify Firebase project IDs, Android/iOS app IDs, signing fingerprints,
  Apple provider setup, OAuth clients, function regions, IAM invoker policy,
  service accounts, quotas, billing, scheduler, and alerting against the
  intended production project.
- [ ] Deploy the exact reviewed function commit and record function revision,
  region, runtime, environment, secret version, and smoke-test timestamp.
- [ ] Compile and test Firestore/Storage rules in emulators, then deploy the
  exact reviewed rules. Re-run owner/non-owner/anonymous/server tests against
  production-safe test identities.
- [ ] Verify clients cannot write deletion-operation records, delete root user
  documents, or bypass reconciliation fences. Confirm Admin-only workers have
  only the permissions they need.
- [ ] Exercise worker leases, retries, partial Gye cleanup, push-token cleanup,
  Auth user-not-found, Apple revocation pending/completion, processor cleanup,
  and terminal status in staging with production-equivalent timeouts.
- [ ] Configure monitoring for stuck phases, exhausted retries, rate-limit
  failures, App Check rejection spikes, worker lease expiry, and safe endpoint
  error codes without logging personal or secret data.

## Privacy publication and store evidence

- [ ] Publish and visually review the exact English, German, and Korean versions
  of `privacy.html` and `account-deletion.html` at:
  `https://hangul-sori.com/privacy.html` and
  `https://hangul-sori.com/account-deletion.html`.
- [ ] Confirm the published controller identity, postal address, contact,
  processor list, data categories, locations, retention statements, the
  free-access/no-purchase-SDK contract, historical store/provider retention
  limits, and account-deletion scope with legal/owner review. Do not infer live
  settings from repository defaults.
- [ ] Reconcile `docs/store/data-safety.md` with the signed Android manifest,
  iOS privacy report, SDK data disclosures, Firebase consoles, DeepL
  configuration, and actual app behavior. Verify that the signed artifacts
  contain no purchase SDK or billing-provider integration.
- [ ] Save dated screenshots/exports of Google Play Data Safety, account
  deletion URL, app access, target audience, content rating, closed-test
  eligibility/tester continuity, absence of a current in-app product or
  subscription offer, and the exact uploaded Android artifact.
- [ ] Save dated screenshots/exports of Apple App Privacy, account deletion,
  support/privacy URLs, age rating, Sign in with Apple, absence of a current
  in-app product or subscription offer, and the exact uploaded iOS
  archive/privacy manifest.
- [ ] Confirm public copy says that all learning content is free and that the
  current app has no purchase SDK, subscription product, paywall, paid gate, or
  billing-processing path. Any store/provider record limitation must be
  explicitly conditional on a transaction created by an older app version.

## Redaction and static audit

- [ ] Scan tracked source, generated web assets, source maps, build artifacts,
  CI logs, release notes, screenshots, and support templates for private keys,
  HMAC values, service-account JSON, authorization codes, ID tokens, raw
  deletion proofs, UIDs, operation IDs, and provider errors.
- [ ] Confirm the proof page has no proof-bearing query URL, third-party script,
  external form target, raw error interpolation, debug console output, or
  analytics hook.
- [ ] Review Cloud Logging, CDN/proxy access logs, Crashlytics, Analytics,
  support mailbox routing, and alert payloads with a controlled synthetic
  request. Retain only safe codes and bounded non-identifying metadata.
- [ ] Disable or protect source maps and diagnostic endpoints that expose
  deployment configuration beyond what the public browser needs.

## Manual proof-page acceptance

- [ ] In a clean browser profile, open a valid app-generated first-party link
  and record that the address bar is cleaned before the POST appears.
- [ ] In developer tools, confirm the request URL contains no fragment/query,
  the destination is the exact first-party endpoint, the body is not logged by
  the edge, no referrer is sent, redirects are rejected, and no third-party
  request occurs.
- [ ] Repeat with valid, expired, rotated, already-used, malformed, missing, and
  already-deleted cases. Public text and response bodies must not reveal which
  case occurred.
- [ ] Test refresh, back/forward, duplicate tabs, rapid replay, response loss,
  offline mode, DNS/TLS failure, endpoint 4xx/5xx, rate limit, and browser
  restart. No case may restore the fragment or claim confirmed deletion.
- [ ] Verify keyboard-only use, screen readers, small screens, English/German/
  Korean language selection, high contrast, and reduced motion.
- [ ] Verify email fallback without copying the one-time link or proof. Support
  must request only the minimum identity/verification data.

## Mobile, legacy, and rollout controls

- [ ] Run the signed Android candidate on at least one supported physical phone
  over the actual USB/debug path and as a Play closed-test install. Record
  device/OS, install source, Play Integrity/App Check result, login providers,
  process death, offline recovery, deletion resume, and a free-access smoke test
  proving representative learning content opens without a purchase,
  subscription state, or access override.
- [ ] Run the signed iOS candidate on a physical device and TestFlight. Record
  device/OS, App Attest/DeviceCheck, Sign in with Apple reauthentication and
  revocation, process death, offline recovery, deletion resume, and the same
  free-access smoke test without a purchase or subscription state.
- [ ] Treat the purchase stack as retired. Scan both signed candidates and
  runtime network traffic for a RevenueCat/purchase SDK, Play Billing or
  StoreKit purchase/restore route, customer-UID binding, subscription state,
  paywall, or entitlement-dependent learning gate. Any active hit blocks the
  release; do not run a subscription sandbox as if it were a supported feature.
- [ ] Inventory active legacy app versions and every historical old
  direct-deletion, direct-Firestore, account-switch, proof, and RevenueCat
  identity path. Define the minimum supported version and compatibility for
  any historical transaction record before rollout.
- [ ] Stage backend/rules first with old-client safety, then canary mobile
  cohorts, then broader release. Confirm old clients cannot bypass new
  server-owned authorization or corrupt in-progress operations.
- [ ] Define rollback by component. A mobile rollback must not re-enable direct
  destructive writes; a backend rollback must preserve journals, operation
  records, proof claims, worker leases, and the ability to resume safely.
- [ ] Monitor a bounded canary period and reconcile completed, blocked, pending,
  Apple-revocation, community-cleanup, and processor-cleanup operations before
  increasing rollout.

## Release decision record

- [ ] All automated Flutter, Node, rules, documentation, and static scans pass
  on the exact commit used for signed artifacts.
- [ ] An independent reviewer has resolved all release-blocking findings.
- [ ] The release owner records commit, Android artifact hash/version code, iOS
  archive/build number, Firebase revisions, rules revisions, published-page
  checksums, console evidence links, open risks, approver, and timestamp.
- [ ] Only after every applicable gate above is evidenced may public copy call
  the protected proof route and server deletion workflow live.
