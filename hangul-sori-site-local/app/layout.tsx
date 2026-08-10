import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: {
    default: "Hangul Sori | Koreanisch lernen in deiner eigenen Welt",
    template: "%s | Hangul Sori",
  },
  description: "Lerne Hangul, Wortschatz und Grammatik in deinem eigenen Hanok, begleitet von Tiger und Elster.",
  metadataBase: new URL("https://www.hangul-sori.com"),
  openGraph: {
    title: "Hangul Sori",
    description: "Dein Koreanisch. Dein Hanok.",
    type: "website",
    siteName: "Hangul Sori",
    images: [{ url: "/taego-joy-poster.jpg", width: 960, height: 540, alt: "Hangul Sori tiger and magpie" }],
  },
  twitter: { card: "summary_large_image", images: ["/taego-joy-poster.jpg"] },
  other: {
    "codex-preview": "development",
    "theme-color": "#176d62",
  },
  icons: { icon: "/icon-192.png", apple: "/hangul-sori-logo.png" },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  const applicationJsonLd = {
    "@context": "https://schema.org",
    "@type": "SoftwareApplication",
    name: "Hangul Sori",
    operatingSystem: "Android, iOS",
    applicationCategory: "EducationalApplication",
    url: "https://www.hangul-sori.com/de",
    description: "Local-first Korean learning with Hangul, vocabulary, grammar, real-life dialogue, games and a growing hanok world.",
    offers: { "@type": "Offer", price: "0", priceCurrency: "EUR" },
  };
  return <html lang="de"><body>{children}<script type="application/ld+json" dangerouslySetInnerHTML={{__html:JSON.stringify(applicationJsonLd)}}/></body></html>;
}
