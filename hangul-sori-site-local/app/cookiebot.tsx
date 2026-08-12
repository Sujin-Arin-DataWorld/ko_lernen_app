const COOKIEBOT_ID = "4693fd59-1476-40b9-b6f2-091898b6732e";
const GOOGLE_ANALYTICS_ID = "G-6R9J2N1PCC";

const consentCleanupScript = `
  (function () {
    try { localStorage.removeItem('hangul-sori-analytics-consent'); } catch (error) {}

    function clearGoogleAnalyticsCookies() {
      var hostname = window.location.hostname;
      var names = document.cookie.split(';').map(function (cookie) {
        return cookie.split('=')[0].trim();
      }).filter(function (name) {
        return name === '_ga' || name.indexOf('_ga_') === 0;
      });
      var domains = [hostname, '.' + hostname];
      var parts = hostname.split('.');
      if (parts.length > 2) domains.push('.' + parts.slice(-2).join('.'));

      names.forEach(function (name) {
        document.cookie = name + '=; Max-Age=0; Path=/; SameSite=Lax; Secure';
        domains.forEach(function (domain) {
          document.cookie = name + '=; Max-Age=0; Path=/; Domain=' + domain + '; SameSite=Lax; Secure';
        });
      });
    }

    function applyCurrentConsent() {
      var statisticsAllowed = Boolean(
        window.Cookiebot &&
        window.Cookiebot.hasResponse &&
        window.Cookiebot.consent &&
        window.Cookiebot.consent.method === 'explicit' &&
        window.Cookiebot.consent.statistics
      );
      if (statisticsAllowed) return;

      if (typeof window.gtag === 'function') {
        window.gtag('consent', 'update', {
          analytics_storage: 'denied',
          ad_storage: 'denied',
          ad_user_data: 'denied',
          ad_personalization: 'denied'
        });
      }
      clearGoogleAnalyticsCookies();

      if (window.__hangulSoriAnalyticsLoaded) {
        window.location.reload();
      }
    }

    window.addEventListener('CookiebotOnConsentReady', applyCurrentConsent);
    window.addEventListener('CookiebotOnDecline', applyCurrentConsent);
  })();
`;

const analyticsScript = `
  (function () {
  if (!window.Cookiebot ||
      !window.Cookiebot.hasResponse ||
      !window.Cookiebot.consent ||
      window.Cookiebot.consent.method !== 'explicit' ||
      !window.Cookiebot.consent.statistics) return;

  window.__hangulSoriAnalyticsLoaded = true;
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  window.gtag = gtag;
  gtag('consent', 'default', {
    analytics_storage: 'granted',
    ad_storage: 'denied',
    ad_user_data: 'denied',
    ad_personalization: 'denied'
  });
  gtag('set', 'ads_data_redaction', true);
  gtag('js', new Date());
  gtag('config', '${GOOGLE_ANALYTICS_ID}', {
    allow_google_signals: false,
    allow_ad_personalization_signals: false,
    cookie_expires: 15552000,
    cookie_flags: 'SameSite=Lax;Secure'
  });

  var analyticsTag = document.createElement('script');
  analyticsTag.async = true;
  analyticsTag.src = 'https://www.googletagmanager.com/gtag/js?id=${GOOGLE_ANALYTICS_ID}';
  document.head.appendChild(analyticsTag);
  })();
`;

/**
 * Cookiebot is the consent authority. Google Analytics is deliberately kept as
 * inert text until the visitor grants the statistics category. This is Basic
 * Consent Mode: no Google request is made before opt-in.
 */
export function CookiebotConsentScripts() {
  return <>
    <script
      id="Cookiebot"
      src="https://consent.cookiebot.com/uc.js"
      data-cbid={COOKIEBOT_ID}
      data-consentmode="disabled"
      type="text/javascript"
      async
    />
    <script dangerouslySetInnerHTML={{ __html: consentCleanupScript }} />
    <script
      type="text/plain"
      data-cookieconsent="statistics"
      dangerouslySetInnerHTML={{ __html: analyticsScript }}
    />
  </>;
}
