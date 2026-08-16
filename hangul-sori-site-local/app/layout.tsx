import type { Metadata } from "next";
import "@fontsource/gowun-dodum/400.css";
import "pretendard/dist/web/variable/pretendardvariable-dynamic-subset.css";
import "./globals.css";
import { CookiebotConsentScripts } from "./cookiebot";
import { PrivacyConsentPanel } from "./privacy-consent-panel";
import { CulturalGlossaryProvider } from "./cultural-glossary";

export const metadata: Metadata = {
  title: {
    default: "Hangul Sori | Learn Korean and build your own hanok.",
    template: "%s | Hangul Sori",
  },
  description: "Learn Hangul, pronunciation and everyday Korean with Tiger and Magpie. Each completed lesson adds to your hanok.",
  metadataBase: new URL("https://www.hangul-sori.com"),
  openGraph: {
    title: "Hangul Sori",
    description: "Learn Korean and build your own hanok with Tiger and Magpie.",
    type: "website",
    siteName: "Hangul Sori",
    images: [{ url: "/app-assets/taego-joy-duo.png", width: 1280, height: 720, alt: "Hangul Sori tiger and magpie" }],
  },
  twitter: { card: "summary_large_image", images: ["/app-assets/taego-joy-duo.png"] },
  other: {
    "theme-color": "#1f7a6b",
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
    description: "Korean learning with Hangul, natural pronunciation, real-life dialogue, games, Gye learning circles and a growing hanok world.",
    offers: { "@type": "Offer", price: "0", priceCurrency: "EUR" },
  };
  return <html lang="de"><head>
    <CookiebotConsentScripts />
  </head><body><CulturalGlossaryProvider>{children}</CulturalGlossaryProvider><PrivacyConsentPanel /><script type="application/ld+json" dangerouslySetInnerHTML={{__html:JSON.stringify(applicationJsonLd)}}/></body></html>;
}
