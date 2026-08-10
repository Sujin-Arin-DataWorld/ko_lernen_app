import Link from "next/link";
import { Footer, Header } from "./site";

type Locale = "de" | "en" | "ko";

const LANG_LABEL: Record<Locale, string> = { de: "DE", en: "EN", ko: "한국어" };

export function LegalShell({
  children,
  eyebrow,
  title,
  intro,
  locale = "de",
  langBase,
}: {
  children: React.ReactNode;
  eyebrow: string;
  title: string;
  intro: string;
  locale?: Locale;
  langBase?: string;
}) {
  return (
    <main className="legal-page" lang={locale}>
      <Header locale={locale} />
      <div className="legal-wrap">
        {langBase && (
          <div className="legal-lang" aria-label="Language">
            {(["de", "en", "ko"] as Locale[]).map((l) => (
              <Link
                key={l}
                href={l === "de" ? langBase : `${langBase}?lang=${l}`}
                className={l === locale ? "active" : ""}
                aria-current={l === locale ? "page" : undefined}
              >
                {LANG_LABEL[l]}
              </Link>
            ))}
          </div>
        )}
        <p className="eyebrow">{eyebrow}</p>
        <h1>{title}</h1>
        <p className="intro">{intro}</p>
        {children}
      </div>
      <Footer locale={locale} />
    </main>
  );
}
