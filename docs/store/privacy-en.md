# Privacy Policy (English) — paste-ready

> This is the vetted English text that already lives in `docs/privacy.html`
> (English tab). Use it to fill the English version of the live
> hangul-sori.com/privacy page. Last updated: 31 July 2026.

## 1. Who is responsible

The operator of **Hangul Sori** is responsible for the processing described
here. Privacy and support contact: hello@hangul-sori.com. The legally required
operator details are provided in the Impressum.

> **Local-first promise.** Learning progress, custom packs, bookshelf content,
> and their managed photos stay on the device for an anonymous-only user.
> Learning-data cloud backup starts only after the user deliberately links a
> Google or Apple account.

## 2. Processing that can occur at app startup

**Anonymous Firebase identity and Remote Config.** After Firebase starts, the
app creates or reuses an anonymous Firebase Authentication user. Its random
Firebase UID is an identifier even though it has no linked name or email. The
app then contacts Firebase Remote Config to fetch a visual-configuration value.
The anonymous identity may also support optional authenticated features such as
study groups, sharing, and push-token ownership; it does not enable
learning-progress or bookshelf backup by itself.

**RevenueCat and purchases.** If a platform RevenueCat public SDK key is present
in the build, the app configures RevenueCat with the Firebase UID as its custom
app user ID and obtains customer/entitlement information. RevenueCat can
therefore process the Firebase UID, customer/entitlement information, and
purchase or transaction state. The identifier and purchase history are treated
as linked to the user. If no platform SDK key is present, RevenueCat is not
configured.

## 3. Local data and optional cloud backup

The app stores learning progress, SRS state, game results, streaks,
preferences, custom packs, bookshelf entries, notes, and managed book/word
photos locally. Local storage remains the source of truth.

When the user explicitly links a Google or Apple account, Firestore
backup/sync becomes eligible under that durable account's Firebase UID. Backup
can include learning progress, game and streak data, SRS state, custom packs,
and bookshelf text. Google or Apple sign-in can also provide the provider
association and, when supplied, email address and display name. Managed photo
references and image bytes are removed from portable payloads — linking an
account does not upload book or word photos.

## 4. Optional features

- **Tester feedback** — voluntary structured feedback plus optional free text,
  with minimal context (content/level/score, app version, platform, language).
  Stored under the current Firebase UID and removed on account deletion.
- **Analytics & crash reports** — Firebase Analytics and Crashlytics are
  separate opt-ins, off by default.
- **Notifications** — FCM auto-init is off; a token is requested only when you
  enable notifications.
- **Study groups (Gye)** — optional community feature behind a local, self-
  attested 16+ age gate.
- **Photos, OCR, analysis, translation** — images are cropped and recognized
  on-device with ML Kit; only requested OCR text and the target language are
  sent over HTTPS for analysis, and text segments may go to DeepL. Image bytes
  are never sent.
- **Pronunciation audio** — requested Korean text is sent over HTTPS to a TTS
  function and Google Cloud Text-to-Speech; audio may be cached.
- **Sharing** — a shared pack uploads a portable payload without local image
  references.

## 5. Purposes and recipients

| Recipient/service | Purpose and relevant data |
|---|---|
| Google Firebase / Google Cloud | Authentication UID; Remote Config; optional Firestore backup, tester feedback, Gye, sharing, FCM, Analytics, Crashlytics, Storage, analysis, and TTS functions. |
| Google / Apple sign-in | Optional durable account link; provider association and any email/display name supplied. |
| RevenueCat | Subscription/customer management using Firebase UID, customer/entitlement info, and purchase state when configured. |
| DeepL | Translation of user-requested OCR/text content through the analysis backend. |

The app has no advertising SDK, does not request advertising identifiers, and
does not use data for cross-app tracking. It does not request location,
contacts, or microphone access.

## 6. Security, locations, and retention

Network data is encrypted in transit using HTTPS/TLS. Gye and TTS functions,
and the default analysis endpoint, are configured for `europe-west3`. This does
not prove every service or datum is stored in the EU; live console settings
govern actual storage and retention. No fixed retention periods are stated
where they are not proven.

## 7. Choices, access, and deletion

- Keep learning data local by not linking Google or Apple.
- Withdraw Analytics, Crashlytics, or notification opt-ins in Settings.
- Reset local learning data, delete cloud backup while keeping the account, or
  delete the full account in the app.
- Request access, correction, export, or RevenueCat-side erasure help at
  hello@hangul-sori.com.

## 8. Changes

We may update this policy when the app or its service configuration changes.
The date above identifies the current document.
