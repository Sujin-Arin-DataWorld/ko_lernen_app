# Word-chain dictionary deployment

`validate_kkeunmari_word` is a separate protected HTTP function for Korean
words that are not in the bundled game pool. It validates exact Korean noun
headwords with the Korean Basic Dictionary Open API and uses the separate
Firestore quota scope `kkeunmari_dictionary_v1`; it never consumes a learner's
book-scan allowance.

## Required secret

Register a Korean Basic Dictionary Open API key, then put its real value in the
gitignored `functions/analyze_korean_text/.env` file:

```dotenv
KRDIC_API_KEY=the-real-secret-goes-here
```

Do not add this value to Flutter, a committed file, or a client-visible build
variable.

## Deploy

From the repository root, deploy from the same Python source directory as the
book-analysis function, with a different function name and entry point:

```bash
gcloud functions deploy validate_kkeunmari_word \
  --gen2 --runtime=python312 --region=europe-west3 \
  --source=functions/analyze_korean_text \
  --entry-point=validate_kkeunmari_word \
  --trigger-http --allow-unauthenticated \
  --set-env-vars "$(grep -v '^#' functions/analyze_korean_text/.env | grep -v '^$' | paste -sd, -)"
```

The HTTP layer remains protected by verified Firebase Auth and App Check. Do
not replace it with a client-side key or a debug-only bypass.

## Verify

Run the Python unit tests first. A real end-to-end call must be made from a
signed app or a configured real-device App Check debug environment because the
function rejects anonymous or unverified requests before querying the
dictionary.
