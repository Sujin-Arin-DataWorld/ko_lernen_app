"use client";

import { useEffect, useState } from "react";

type Locale = "de" | "en" | "ko";

type CookiebotApi = {
  hasResponse?: boolean;
  consent?: { method?: string; statistics?: boolean };
  hide?: () => void;
  runScripts?: () => void;
  submitCustomConsent?: (preferences: boolean, statistics: boolean, marketing: boolean) => void;
};

const copy = {
  de: {
    label: "Datenschutzeinstellungen",
    title: "Du entscheidest über Statistik.",
    intro: "Hangul Sori funktioniert vollständig ohne Analyse-Cookies. Nur wenn du zustimmst, hilft uns Google Analytics zu verstehen, welche Seiten genutzt werden.",
    necessaryTitle: "Notwendig",
    necessaryBody: "Cookiebot merkt sich deine Auswahl. Cloudflare liefert die Website sicher aus. Diese Funktionen sind immer aktiv.",
    statisticsTitle: "Optionale Statistik",
    statisticsBody: "Google Analytics misst Seitenaufrufe und Interaktionen. Google Ireland ist Empfänger; eine Verarbeitung in den USA ist möglich. Werbung, Google Signals und personalisierte Anzeigen sind deaktiviert.",
    details: "Details anzeigen",
    hideDetails: "Details schließen",
    privacy: "Datenschutzerklärung",
    reject: "Nur notwendige",
    accept: "Statistik erlauben",
    loading: "Datenschutzeinstellungen werden vorbereitet …",
  },
  en: {
    label: "Privacy settings",
    title: "You decide about statistics.",
    intro: "Hangul Sori works fully without analytics cookies. Only if you agree, Google Analytics helps us understand which pages are used.",
    necessaryTitle: "Necessary",
    necessaryBody: "Cookiebot remembers your choice. Cloudflare delivers the website securely. These functions are always active.",
    statisticsTitle: "Optional statistics",
    statisticsBody: "Google Analytics measures page views and interactions. Google Ireland receives the data; processing in the United States is possible. Advertising, Google Signals, and personalised ads are disabled.",
    details: "Show details",
    hideDetails: "Hide details",
    privacy: "Privacy policy",
    reject: "Necessary only",
    accept: "Allow statistics",
    loading: "Preparing privacy settings …",
  },
  ko: {
    label: "개인정보 설정",
    title: "통계 사용은 직접 선택할 수 있어요.",
    intro: "Hangul Sori는 분석 쿠키 없이도 모든 기능을 사용할 수 있습니다. 동의한 경우에만 Google Analytics로 어떤 페이지가 이용되는지 확인합니다.",
    necessaryTitle: "필수 기능",
    necessaryBody: "Cookiebot은 선택을 기억하고 Cloudflare는 웹사이트를 안전하게 제공합니다. 이 기능은 항상 활성화됩니다.",
    statisticsTitle: "선택 통계",
    statisticsBody: "Google Analytics는 페이지 조회와 상호작용을 측정합니다. 수신자는 Google Ireland이며 미국에서 처리될 수 있습니다. 광고, Google Signals, 개인 맞춤 광고는 비활성화되어 있습니다.",
    details: "자세히 보기",
    hideDetails: "자세히 닫기",
    privacy: "개인정보 처리방침",
    reject: "필수만 허용",
    accept: "통계 허용",
    loading: "개인정보 설정을 준비하고 있습니다 …",
  },
} as const;

function getLocale(): Locale {
  const params = new URLSearchParams(window.location.search);
  const requested = params.get("lang");
  if (requested === "en" || requested === "ko" || requested === "de") return requested;
  if (window.location.pathname.startsWith("/en")) return "en";
  if (window.location.pathname.startsWith("/ko")) return "ko";
  return "de";
}

function getCookiebot(): CookiebotApi | undefined {
  return (window as Window & { Cookiebot?: CookiebotApi }).Cookiebot;
}

function hasExplicitResponse(api: CookiebotApi | undefined) {
  return Boolean(api?.hasResponse && api.consent?.method === "explicit");
}

export function PrivacyConsentPanel() {
  const [locale, setLocale] = useState<Locale>("de");
  const [open, setOpen] = useState(false);
  const [details, setDetails] = useState(false);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    function syncConsent() {
      const api = getCookiebot();
      api?.hide?.();
      setLocale(getLocale());
      setReady(Boolean(api?.submitCustomConsent));
      setOpen(!hasExplicitResponse(api));
    }

    function openSettings(event: Event) {
      event.preventDefault();
      const api = getCookiebot();
      api?.hide?.();
      setReady(Boolean(api?.submitCustomConsent));
      setDetails(true);
      setOpen(true);
    }

    function hideVendorDialog() {
      getCookiebot()?.hide?.();
    }

    window.addEventListener("CookiebotOnConsentReady", syncConsent);
    window.addEventListener("CookiebotOnDialogDisplay", hideVendorDialog);
    window.addEventListener("hangul-sori-open-cookie-settings", openSettings);
    const initial = window.setTimeout(syncConsent, 0);
    const fallback = window.setTimeout(syncConsent, 1200);

    return () => {
      window.clearTimeout(initial);
      window.clearTimeout(fallback);
      window.removeEventListener("CookiebotOnConsentReady", syncConsent);
      window.removeEventListener("CookiebotOnDialogDisplay", hideVendorDialog);
      window.removeEventListener("hangul-sori-open-cookie-settings", openSettings);
    };
  }, []);

  function save(nextStatistics: boolean) {
    const api = getCookiebot();
    if (!api?.submitCustomConsent) return;
    api.submitCustomConsent(false, nextStatistics, false);
    if (nextStatistics) window.setTimeout(() => api.runScripts?.(), 0);
    setOpen(false);
  }

  if (!open) return null;
  const text = copy[locale];

  return <section className="privacy-consent-panel" role="region" aria-label={text.label}>
    <div className="privacy-consent-copy">
      <p className="privacy-consent-kicker">{text.label}</p>
      <h2>{text.title}</h2>
      <p>{text.intro}</p>
    </div>

    {details && <div className="privacy-consent-details">
      <article>
        <div>
          <b>{text.necessaryTitle}</b>
          <span className="privacy-consent-status" aria-label="always active">{locale === "de" ? "Immer aktiv" : locale === "ko" ? "항상 활성" : "Always active"}</span>
        </div>
        <p>{text.necessaryBody}</p>
      </article>
      <article>
        <div>
          <b>{text.statisticsTitle}</b>
          <span className="privacy-consent-status">{locale === "de" ? "Optional" : locale === "ko" ? "선택" : "Optional"}</span>
        </div>
        <p>{text.statisticsBody}</p>
      </article>
    </div>}

    <div className="privacy-consent-links">
      <button type="button" onClick={() => setDetails((value) => !value)} aria-expanded={details}>{details ? text.hideDetails : text.details}</button>
      <a href={`/privacy?lang=${locale}#cookies`}>{text.privacy}</a>
    </div>
    <div className="privacy-consent-actions">
      <button type="button" className="privacy-choice privacy-choice-secondary" disabled={!ready} onClick={() => save(false)}>{text.reject}</button>
      <button type="button" className="privacy-choice privacy-choice-primary" disabled={!ready} onClick={() => save(true)}>{text.accept}</button>
    </div>
    {!ready && <p className="privacy-consent-loading" role="status">{text.loading}</p>}
  </section>;
}
