import type { Metadata } from "next";
import { Landing } from "../site";

export const metadata: Metadata = {
  title: "Koreanisch lernen in deinem eigenen Hanok",
  description: "Lerne Hangul, Wortschatz, Grammatik und echte Dialoge mit Tiger und Elster. Local-first, werbefrei und zum Start kostenlos.",
  alternates: {
    canonical: "/de",
    languages: { "de-DE": "/de", en: "/en", ko: "/ko", "x-default": "/de" },
  },
};

export default function GermanHome(){ return <Landing locale="de"/>; }
