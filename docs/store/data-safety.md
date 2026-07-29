# Store privacy disclosure worksheet

Last repository review: **2026-07-29**

This is a release-owner worksheet for Google Play Data Safety and Apple App
Privacy. It is not a console export and is not a substitute for reviewing the
signed Android/iOS build, current SDK disclosures, live Firebase/Google/
RevenueCat configuration, contracts, and the answers already saved in each
store console.

Authoritative form guidance:

- [Google Play Data Safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)
- [Google Play account deletion](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en)
- [Apple App Privacy](https://developer.apple.com/app-store/app-privacy-details/)
- [Apple in-app account deletion](https://developer.apple.com/support/offering-account-deletion-in-your-app/)
- [RevenueCat — Google Play Data Safety](https://www.revenuecat.com/docs/platform-resources/google-platform-resources/google-plays-data-safety)
- [RevenueCat — Apple App Privacy](https://www.revenuecat.com/docs/platform-resources/apple-platform-resources/apple-app-privacy)
- [RevenueCat customer profiles](https://www.revenuecat.com/docs/dashboard-and-metrics/customer-profile)
- [RevenueCat customer identity](https://www.revenuecat.com/docs/customers/identifying-customers)

## Repository-backed behavior summary

- Firebase initializes in the background. After successful initialization, the
  app creates or reuses an anonymous Firebase Authentication user and contacts
  Firebase Remote Config.
- The anonymous Firebase UID is an identifier. It can own optional Gye,
  sharing, and push data, but does **not** authorize automatic learning-progress
  or bookshelf backup.
- Pack progress, bookshelf sync, and manual whole-app backup/restore use
  Firestore only after the user deliberately links a durable Google or Apple
  provider to a non-empty Firebase UID.
- Local storage remains the learning source of truth.
- When a platform RevenueCat public SDK key is present, RevenueCat is configured
  at startup, receives the current Firebase UID via `Purchases.logIn(uid)`,
  returns customer/entitlement information, and processes purchase/transaction
  state. It is not contacted only after a purchase.
- Firebase Analytics and Crashlytics are independent optional opt-ins and are
  disabled by default in Android/iOS native configuration.
- FCM auto-init is disabled. Permission and a registration token are requested
  only when notifications are enabled. Server token cleanup is retryable.
- Gye is an optional community feature behind a local year-only self-attested
  age gate. It is not verified identity or verified age.
- Camera/gallery images remain in app-managed local storage. ML Kit OCR runs
  on-device. Portable Firestore/shared payloads strip book thumbnails and word
  image references. User-requested analysis transmits OCR-extracted/corrected
  text, not image bytes.
- The analysis backend can send text to DeepL and can retain source segments
  and translations in a Firestore `translation_cache`. Dynamic/user-entered TTS
  text can be sent to the configured function and Google Cloud Text-to-Speech;
  generated audio can be cached in Firebase Storage.
- Android explicitly removes `AD_ID`, AdServices Ad ID, `READ_MEDIA_IMAGES`,
  and `READ_EXTERNAL_STORAGE`. There is no active ad SDK. The app does not
  request location, contacts, or microphone permission.
- Network processing uses HTTPS/TLS. The repository does not prove that every
  connection uses TLS 1.3.

## Google Play Data Safety worksheet

Interpret “optional” below as a user-controlled feature or opt-in. “Required
within feature” means that once the user chooses that feature, the data is
needed to provide it. “Shared?” remains provisional where Play’s service
provider exception or a configured integration must be checked.

| Play data type | Collected off-device? | Optional or required | Ephemeral? | Purpose(s) in release code | Shared? / review note |
|---|---:|---|---:|---|---|
| Personal info — Email address | Yes, when supplied by Google/Apple sign-in | Optional account link; required within cloud-account feature | No | Account management; cloud backup | Provisional No for provider/service processing; verify live provider configuration and contracts |
| Personal info — Name / display name | Yes, when supplied by Google/Apple sign-in | Optional account link | No | Account profile/UI | Provisional No; verify provider configuration |
| User IDs — Firebase UID and provider association | Yes | Anonymous UID is automatic after cloud startup; durable provider link is optional | No | Authentication; account management; Gye/sharing/push ownership; durable cloud-backup key; RevenueCat identity | RevenueCat receives UID when configured. Verify whether any configured RevenueCat integration changes the console “shared” answer |
| Financial info — Purchase history / transaction state | Yes, through stores and RevenueCat when purchase/restore/customer state exists | Optional purchase feature; required within purchase/restore | No | App functionality (entitlement and restore); analytics as described by RevenueCat | **Console blocker:** verify RevenueCat project integrations and use current RevenueCat Play guidance before answering “shared” |
| App activity — Learning progress, game/SRS/streak data | Yes only after Google/Apple durable link | Optional cloud-backup feature; required within backup/sync | No | App functionality; account sync/restore | Provisional No; Firebase service-provider/configuration review required |
| App activity / User-generated content — Gye group data | Yes only when Gye is used | Optional 16+ self-attested feature; required within Gye | No | Community app functionality; fraud/abuse prevention; moderation; notifications | Includes UID, nickname, membership/role, contributions, fixed feed events, reactions/stickers/cheers, reports/optional report notes, blocks, moderation/cleanup markers, and notification-outbox data |
| User-generated content / Other info — Shared-pack payload | Yes only when the user shares | Optional sharing feature; required within sharing | No | App functionality | Portable payload strips local image references; creator Firebase UID can be retained |
| User-generated content / Other info — OCR-extracted or user-entered Korean text | Yes only for requested analysis/translation/TTS | Optional feature; required within requested operation | Not always: translation source/translation and generated audio can be cached | App functionality | Processed by Google Cloud/Firebase, DeepL for translation, and Google Cloud TTS as applicable. Verify processor/service-provider treatment |
| App activity — App interactions / usage data | Yes only after Analytics opt-in | Optional | No under provider/project retention | Analytics | Default off; verify current Firebase Analytics SDK disclosure and console settings |
| App info and performance — Crash logs / diagnostics | Yes only after Crashlytics opt-in | Optional | No after transmission | App functionality; diagnostics | Turning off deletes only unsent local reports best-effort; verify current Crashlytics disclosure/retention |
| Device or other IDs — Firebase installation/SDK identifiers | Potentially yes through initialized Firebase services; Analytics-specific collection remains opt-in | Core Remote Config/auth startup and optional SDK features | Verify per SDK | App functionality; analytics where opted in | **Console blocker:** compare the signed build’s Firebase SDK disclosures and live settings |
| Device or other IDs — FCM registration token | Yes only after notification enable/permission | Optional notification feature; required within push | No while registered | App functionality (notification delivery) | Associated with Firebase UID; server deletion is retryable, not guaranteed instantaneous |
| Photos and videos — book/word photos | **No** in current app/server payloads | Local optional feature | Local only | On-device OCR and local customization | Not uploaded; do not declare broad photo collection solely because the system picker/camera is used |
| Audio files / voice recordings | No | — | — | App does not record the user | Text can be sent for TTS; that is text processing, not collection of a user audio recording |
| Advertising ID | No | — | — | No ads/tracking | Android manifest removes `AD_ID` and AdServices Ad ID |
| Location, contacts, calendar, health, microphone, browsing history | No repository evidence of collection | — | — | — | Re-check the signed build and newly added SDKs before submission |

### Play form-level answers to review

- **Encrypted in transit:** Yes — repository network endpoints use HTTPS/TLS.
- **Users can request deletion:** Yes — the app has an in-app account deletion
  path for guest/anonymous and Google/Apple-linked accounts, plus
  `https://hangul-sori.com/account-deletion.html`.
- **Account creation:** Firebase creates an anonymous account automatically; the
  account can later be linked to Google or Apple.
- **Deletion scope:** In-app deletion covers known Firestore account data,
  Firebase Authentication, local app data/media/cache, push transition, and a
  retryable Gye cleanup workflow. It does not itself cancel subscriptions or
  delete the RevenueCat customer profile.
- **Independent security review:** No repository evidence. Do not answer Yes
  without a completed external review.
- **Data sharing:** Do not copy “No” blindly. Confirm processor contracts and
  actual RevenueCat/Google/DeepL integrations using Play’s current definitions.

## Apple App Privacy worksheet

Apple categories and “linked to the user” are separate from Google Play’s form.
Because this release passes the Firebase UID to RevenueCat, the RevenueCat user
identifier and purchase history must be treated as linked to the user.

### Data linked to the user — provisional

| Apple category | Release use | Purpose |
|---|---|---|
| Contact Info — Email Address | Google/Apple sign-in when supplied | App functionality; account management |
| Contact Info — Name | Provider display name when supplied | App functionality |
| Identifiers — User ID | Firebase UID, provider association, RevenueCat app user identity | App functionality; account management; developer analytics as applicable |
| Purchases — Purchase History | Store/RevenueCat customer, entitlement, purchase and transaction state | App functionality; developer analytics |
| User Content — Other User Content | Durable cloud-backup text/custom learning content; Gye UGC; shared packs; requested OCR/text processing | App functionality; moderation |
| Usage Data — Product Interaction | Learning backup when linked; Analytics only after opt-in | App functionality; analytics |

### Data that may be collected but needs linked/not-linked confirmation

| Apple category | Why confirmation is required |
|---|---|
| Identifiers — Device ID | Firebase installation/SDK identifiers and FCM token behavior must be checked against the exact signed SDK versions and live configuration |
| Diagnostics — Crash Data / Performance Data | Crashlytics is opt-in, but current Firebase Apple disclosure and project configuration determine the final linked/not-linked answer |
| Usage Data — Product Interaction | Analytics is opt-in; verify whether current Firebase configuration links it to any account/user identifier |

### Not collected by the app as an off-device Apple category

- Photos/Videos: book and word images stay on-device and are stripped from
  portable payloads.
- Audio Data: the app does not record user audio.
- Precise or coarse location, contacts, health/fitness, browsing history, and
  advertising identifier: no release-code collection identified.

### Tracking

Provisional **No**: there is no active advertising SDK, no ATT-based tracking
flow, and no repository use of advertising identifiers. Reconfirm against the
signed iOS binary and all live SDK integrations before submission.

## Account deletion and billing disclosure

- The primary self-service route is Settings → account section → Delete
  account. It applies to guest/anonymous and Google/Apple-linked accounts.
- Local reset, cloud-backup deletion while keeping the account, and full
  account deletion are distinct actions.
- Successful full deletion creates a fresh unlinked anonymous Firebase
  identity for continued local use. It is not restoration of the deleted UID.
- Uninstalling removes local installation data but does not prove deletion of
  the old Firebase or RevenueCat identity.
- Google Play/App Store subscriptions must be cancelled separately.
- The mobile flow does not delete the RevenueCat customer profile. Processor-
  side requests go through `hello@hangul-sori.com`; do not promise deletion of
  legally required transaction records.
- Already transmitted Analytics/Crashlytics records and other provider logs are
  governed by verified live retention controls. Crashlytics opt-out only asks
  for deletion of unsent local reports on a best-effort basis.

## Location, retention, and legal-publication blockers

These items must remain open until verified by the release owner in the live
systems:

- [ ] Confirm the legal controller name and postal address that must appear in
  the public Privacy Policy/Impressum. The repository does not establish the
  owner’s current legal address or residence; do not infer it.
- [ ] Verify Firestore database location and backup/TTL settings.
- [ ] Verify Firebase Authentication, Remote Config, Analytics, Crashlytics,
  Cloud Messaging, and Storage processing locations and retention settings.
- [ ] Verify that the deployed analysis, Gye, and TTS endpoints match the
  intended release. Repository configuration/defaults use `europe-west3` for
  those functions, but source code does not prove live deployment state.
- [ ] Verify DeepL account/contract/settings and how the Play “shared” exception
  applies.
- [ ] Verify RevenueCat project, app user ID behavior, integrations, customer
  deletion route, data locations, and retention. Reconcile both store forms
  with RevenueCat’s current platform guidance.
- [ ] Verify Google/Apple sign-in console scopes and which email/name fields are
  actually supplied.
- [ ] Verify the exact signed Android manifest and iOS privacy/SDK reports after
  the final release build; update this worksheet if transitive SDK behavior
  differs.
- [ ] Confirm the published Privacy Policy and account-deletion URLs contain
  the reviewed legal operator details and match the submitted app version.

Do not replace these blockers with assumptions such as “all data is in the EU”
or fixed provider retention periods.

## Related release checks

- Google personal developer accounts that are subject to the closed-testing
  requirement must follow the current
  [Google closed-testing guidance](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en);
  account eligibility and tester-day status are console facts, not repository
  facts.
- Public policy: `https://hangul-sori.com/privacy.html`
- Public deletion page: `https://hangul-sori.com/account-deletion.html`
