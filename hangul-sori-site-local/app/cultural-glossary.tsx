"use client";

import Link from "next/link";
import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from "react";
import type { Locale } from "./site";

type CulturalCopy = { meaning: string; story: string };
type CulturalEntry = {
  termId: string;
  ko: string;
  romanization: string;
  localizations: Record<Locale, CulturalCopy>;
};
type CulturalCatalog = { schemaVersion: number; entries: CulturalEntry[] };

const chrome = {
  de: { open: "Mehr erfahren über", meaning: "Was ist das?", story: "Warum war das wichtig?", close: "Kulturgeschichte schließen", language: "Sprache der Erklärung" },
  en: { open: "Learn more about", meaning: "What is it?", story: "Why did it matter?", close: "Close cultural story", language: "Explanation language" },
  ko: { open: "더 알아보기:", meaning: "무엇인가요?", story: "왜 중요했나요?", close: "문화 이야기 닫기", language: "설명 언어" },
} as const;

let catalogRequest: Promise<CulturalCatalog | null> | undefined;

function loadCatalog() {
  catalogRequest ??= fetch("/data/cultural_glossary.json", { cache: "force-cache" })
    .then(async (response) => {
      if (!response.ok) return null;
      const value: unknown = await response.json();
      if (!value || typeof value !== "object") return null;
      const catalog = value as Partial<CulturalCatalog>;
      if (catalog.schemaVersion !== 1 || !Array.isArray(catalog.entries)) return null;
      return catalog as CulturalCatalog;
    })
    .catch(() => null);
  return catalogRequest;
}

type CulturalGlossaryContextValue = {
  entries: Map<string, CulturalEntry>;
  locale: Locale;
  open: (termId: string, locale: Locale, opener: HTMLButtonElement) => void;
  setLocale: (locale: Locale) => void;
};

const CulturalGlossaryContext = createContext<CulturalGlossaryContextValue | null>(null);

export function CulturalGlossaryProvider({ children }: { children: React.ReactNode }) {
  const [catalog, setCatalog] = useState<CulturalCatalog | null>(null);
  const [locale, setLocale] = useState<Locale>("de");
  const [activeTermId, setActiveTermId] = useState<string | null>(null);
  const dialogRef = useRef<HTMLDialogElement>(null);
  const openerRef = useRef<HTMLButtonElement | null>(null);

  useEffect(() => {
    let current = true;
    void loadCatalog().then((next) => {
      if (current) setCatalog(next);
    });
    return () => { current = false; };
  }, []);

  const entries = useMemo(
    () => new Map((catalog?.entries ?? []).map((entry) => [entry.termId, entry])),
    [catalog],
  );
  const activeEntry = activeTermId ? entries.get(activeTermId) : undefined;

  const close = useCallback(() => {
    const dialog = dialogRef.current;
    if (dialog?.open) dialog.close();
    setActiveTermId(null);
    const opener = openerRef.current;
    requestAnimationFrame(() => {
      if (opener?.isConnected) opener.focus();
    });
  }, []);

  const open = useCallback((termId: string, nextLocale: Locale, opener: HTMLButtonElement) => {
    if (!entries.has(termId)) return;
    openerRef.current = opener;
    setLocale(nextLocale);
    setActiveTermId(termId);
  }, [entries]);

  useEffect(() => {
    const dialog = dialogRef.current;
    if (activeEntry && dialog && !dialog.open) dialog.showModal();
  }, [activeEntry]);

  const value = useMemo(
    () => ({ entries, locale, open, setLocale }),
    [entries, locale, open],
  );
  const copy = activeEntry?.localizations[locale];
  const labels = chrome[locale];

  return <CulturalGlossaryContext.Provider value={value}>
    {children}
    <dialog
      ref={dialogRef}
      className="cultural-dialog"
      aria-labelledby="cultural-dialog-title"
      onCancel={(event) => { event.preventDefault(); close(); }}
      onClick={(event) => { if (event.target === event.currentTarget) close(); }}
    >
      {activeEntry && copy ? <article className="cultural-dialog-card">
        <button className="cultural-dialog-close" type="button" aria-label={labels.close} onClick={close}>×</button>
        <header>
          <h2 id="cultural-dialog-title">{activeEntry.ko}</h2>
          <p>{activeEntry.romanization}</p>
        </header>
        <div className="cultural-dialog-copy">
          <section><h3>{labels.meaning}</h3><p>{copy.meaning}</p></section>
          <section><h3>{labels.story}</h3><p>{copy.story}</p></section>
        </div>
        <nav className="cultural-dialog-languages" aria-label={labels.language}>
          {(["de", "en", "ko"] as const).map((option) =>
            <Link key={option} href={`/${option}`} lang={option} aria-current={locale === option ? "page" : undefined}>{option.toUpperCase()}</Link>,
          )}
        </nav>
      </article> : null}
    </dialog>
  </CulturalGlossaryContext.Provider>;
}

export function CulturalLocaleSync({ locale }: { locale: Locale }) {
  const context = useContext(CulturalGlossaryContext);
  useEffect(() => context?.setLocale(locale), [context, locale]);
  return null;
}

export function CulturalTerm({ termId, locale, children }: { termId: string; locale: Locale; children: React.ReactNode }) {
  const context = useContext(CulturalGlossaryContext);
  const entry = context?.entries.get(termId);
  const label = entry ? `${chrome[locale].open} ${entry.ko}` : "";
  return <span className="cultural-term" data-cultural-term={termId}>
    {children}
    {entry ? <button
      className="cultural-help-trigger"
      type="button"
      aria-label={label}
      title={label}
      onClick={(event) => context?.open(termId, locale, event.currentTarget)}
    >?</button> : null}
  </span>;
}
