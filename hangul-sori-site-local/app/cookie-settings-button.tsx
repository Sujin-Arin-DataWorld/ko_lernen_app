"use client";

const fallbackPath = {
  de: "/privacy?lang=de#cookies",
  en: "/privacy?lang=en#cookies",
  ko: "/privacy?lang=ko#cookies",
} as const;

const label = {
  de: "Cookie-Einstellungen",
  en: "Cookie settings",
  ko: "쿠키 설정",
} as const;

export function CookieSettingsButton({ locale }: { locale: "de" | "en" | "ko" }) {
  function openSettings() {
    const handled = !window.dispatchEvent(new Event("hangul-sori-open-cookie-settings", { cancelable: true }));
    if (!handled) window.location.assign(fallbackPath[locale]);
  }

  return <button className="footer-cookie-button" type="button" onClick={openSettings}>
    {label[locale]}
  </button>;
}
