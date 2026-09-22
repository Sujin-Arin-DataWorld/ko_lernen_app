# Verify Android internal publication

An AAB upload and a successful Play edit commit do not establish the release's current publication state. Use the existing Play service account to **GET** the internal release summaries; this workflow creates no edit, uploads no bundle, commits nothing and changes no track, tester, review or rollout setting.

After this workflow is reviewed and merged, dispatch **Verify Play Internal Publication** from `main` with the exact `expected_version_code`. The `google-play-internal` environment retains its main-only policy. Verification uses a separate concurrency group so it cannot cancel a pending upload in GitHub's queue. It never enables `PLAY_INTERNAL_RELEASE_ENABLED`.

The artifact contains only package, internal track, active version codes, lifecycle states, the expected version and check time. `published` requires that exact active artifact with `RELEASE_LIFECYCLE_STATE_PUBLISHED`. Review pending, approved-but-not-published, absent, unknown and failed responses are not success. Exit 3 means valid evidence with the requested version not published/found; exit 2 means verification failed. Inspect the reason before another check, without repeated polling or reuploading the same version.

Google's endpoint returns at most 20 non-obsolete releases. `not_found` therefore does not claim that the version was never uploaded. `PUBLISHED` is Play API publication evidence; it does not verify a particular tester's membership, compatible device, update eligibility or actual installation. Keep those console/device checks separate. Preserve the upload run's source SHA and AAB hash alongside this receipt; a release name alone is not source provenance.

Authentication reuses `google-auth-library` from the existing `functions/tts/package-lock.json` through `npm ci --ignore-scripts`, with the official Android Publisher OAuth scope. No dependency lock, IAM permission, service account or secret is changed. Credentials and tokens stay in the verification process; raw exceptions/responses are never printed. The only Play endpoint is the fixed GET for `com.sujinarin.ko_lernen_app/internal`, redirects are refused, and API errors do not trigger automatic retries.

References: [list release summaries](https://developers.google.com/android-publisher/api-ref/rest/v3/applications.tracks.releases/list), [lifecycle states](https://developers.google.com/android-publisher/api-ref/rest/v3/applications.tracks.releases).
