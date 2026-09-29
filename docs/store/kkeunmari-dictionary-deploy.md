# Word-chain dictionary deployment

`validate_kkeunmari_word` is a protected Gen2 HTTP function in `ko-lernen-app`,
`europe-west3`. It checks the generated positive noun index first, then uses the
Korean Basic Dictionary and Standard Korean Language Dictionary APIs for words
absent from that index when configured. Both use exact headword/noun queries
within one four-second server deadline. A positive response from either wins;
an outage or incomplete response is never evidence of an invalid word.
Absence from the index is **not** evidence that a Korean word is invalid.
Firebase Auth, App Check, and the separate `kkeunmari_dictionary_v1` quota remain
mandatory. No book-scan quota is consumed.

## Rebuild and verify

From the repository root:

```powershell
python tool/build_kkeunmari_lexicon.py --check
python -m unittest discover -s functions/analyze_korean_text -p 'test_*.py'
python functions/analyze_korean_text/verify_deployed_source.py --check-gcloud-upload --check-app-ids
```

Use the supported Python 3.12 environment. The exact runtime manifest includes
`kkeunmari_nouns.json`. `tool/build_kkeunmari_lexicon.py` generates identical mobile
and server copies from the licensed NIKL noun list, plus the independently
attributed headword `러너`. Definitions are not used or assigned to game answers.
Source: NIKL 2023 vocabulary spreadsheet (KOGL Type 1), documented in
`docs/data/level_bible/SOURCES.md`; supplement: NIKL OnTerm / KEPCO,
https://kli.korean.go.kr/term/trgtWord/indexTrgtWord.do?trgtWordNo=102155
(KOGL Type 1). Attribution is also visible in Settings.

## Runtime configuration

Use `deploy.env.yaml` for the registered Android/iOS App IDs and a runtime
service account with the existing Firebase token-verification and Firestore
quota permissions. Inspect the live account and bindings before choosing it.
Do not copy dotenv contents into a shell command or upload a dotenv file.

`KRDIC_API_KEY` and `STDICT_API_KEY` must be attached from Secret Manager, never embedded
in Flutter, the source archive, logs, or a committed file. Without that key,
bundled nouns still work; if neither key is configured, unlisted words return
503 `dictionary_unavailable`.
This is degraded operation, not complete external-dictionary coverage.

```powershell
gcloud functions deploy validate_kkeunmari_word --gen2 --runtime=python312 `
  --project=ko-lernen-app --region=europe-west3 `
  --source=functions/analyze_korean_text --entry-point=validate_kkeunmari_word `
  --trigger-http --allow-unauthenticated `
  --service-account=VERIFIED_RUNTIME_SERVICE_ACCOUNT `
  --env-vars-file=functions/analyze_korean_text/deploy.env.yaml `
  --memory=512Mi --timeout=30s --min-instances=0 --max-instances=2
```

Public HTTP invocation permits the mobile client to reach the application
boundary; it does not bypass the required Firebase Auth and App Check checks.
If an API key has been provisioned with least-privilege Secret Manager access,
add `--set-secrets=KRDIC_API_KEY=KRDIC_API_KEY:PINNED_VERSION,STDICT_API_KEY=STDICT_API_KEY:PINNED_VERSION`
using each real version. Grant this runtime account accessor access to each
individual secret only. Do not replace or redeploy `analyze_korean_text` just to deploy this
separate entry point.

## Verify the deployed revision

Verify the actual uploaded source using `verify_deployed_source.py --function
validate_kkeunmari_word --check-app-ids`. Requests without valid credentials
must remain 401. Verify the three reported words (`막내`, `러너`, `러닝`) through
a signed app with real Auth and App Check. A 401 probe proves rejection only;
it does not prove successful end-to-end lookup or device game behavior.

The new app validates the noun index offline before requesting credentials,
bounds the entire fallback request, and pauses the current turn on an outage.
The existing learning and reward ledgers are unchanged.

Provider contracts: https://krdict.korean.go.kr/kor/openApi/openApiInfo and
https://stdict.korean.go.kr/openapi/openApiInfo.do. Standard-dictionary internal
hyphens such as `노트-북` are syllable markers, while spaces, carets and affix
boundary markers remain significant. Definitions are not copied into answers.
