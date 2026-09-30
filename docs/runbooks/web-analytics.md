# Website pageview verification

Keep GA property `538411104`, web stream `15425421435` and measurement ID
`G-6R9J2N1PCC`. Cookiebot is the only consent authority. Android/iOS SDK receipt
is a separate check.

## Publication prerequisite

Before publishing the manual pageview implementation, inspect this existing
web stream's Enhanced Measurement configuration and turn off **Page changes
based on browser history events**. Record the actual setting. Do not assume it
is disabled merely because one navigation sent no event. `send_page_view: false`
only disables the config pageview; an enabled history rule sends independently.
Leave the existing property, stream, other measurements and advertising settings
intact. Do not publish until the configuration and one-event-per-visit check
are both verified.

[Google pageview configuration](https://developers.google.com/analytics/devguides/collection/ga4/views)
documents the two separate automatic pageview controls.

## Source behavior

The root route observer signals after pathname commits. The consent-gated
script sends one explicit `page_view` for the initial current route and each
different subsequent public pathname. Repeated effects on the same route do
not duplicate a view; back/forward visits count again, including `pageshow`
restoration from bfcache. A persisted `pageshow` disables the cached tag and
reloads the document so Cookiebot re-checks consent changed elsewhere. This
listener exists even if the cached document had denied consent. Ordinary SPA
navigation does not reload. Returning through an excluded pathname also starts a
new public visit. Consent granted after
navigation records the current page only. Revocation prevents further manual
views while the existing consent cleanup reloads the page.

Queries and fragments do not identify pages. Only the fixed public route list
is accepted; unknown paths do not initialize analytics, but the observer remains
ready for a later public route. Initial configuration and
subsequent views omit query/fragment values, including deletion proof tokens.
The first external referrer is limited to its origin; later page referrers are
the previous public page. A same-page return uses an empty referrer instead of
inventing the intervening page. Page metadata uses the same
global scope before initial config and on later visits, so config does not pin
implicit events to the first page. Google Signals and all advertising consent
remain off. These checks cover our tag initialization and manual views; they do
not certify every Enhanced Measurement event payload.

## Evidence to collect

1. In a fresh browser context, make no choice, then choose necessary-only and
   visit another route: no Google tag or collection requests.
2. Explicitly allow statistics: one tag, one current-page view to the existing
   measurement ID, advertising still denied.
3. Navigate EN → KO → DE, then back/forward: exactly one view per visit, correct
   location/title and previous-page referrer; no extra view for fragment-only
   navigation or duplicate route effects.
4. Reload: one view for the reloaded page. Withdraw consent: no new views after
   cleanup/reload, including subsequent route navigation.
5. Confirm the corresponding events in the existing GA stream. HTTP 204 is
   transport evidence, not evidence of report receipt or an eligible user cohort.

The 2026-09-22 baseline reproduced ordinary `/en` page_view and scroll HTTP 204,
no new request after SPA navigation to `/ko`, and a `/ko` page_view request after
a reload (the latter response status was not retained in the minimal receipt).
This narrows the missing path; it does not prove the stream's current
history-measurement setting or complete reporting recovery.
