import type { Metadata } from "next";
import { Landing } from "../site";

export const metadata: Metadata = {
  title: "Learn Korean in your own hanok world",
  description: "Learn Hangul, vocabulary, grammar and real-life dialogue with a tiger and magpie. Local-first, ad-free and free at launch.",
  alternates: {
    canonical: "/en",
    languages: { "de-DE": "/de", en: "/en", ko: "/ko", "x-default": "/de" },
  },
};

export default function EnglishHome(){ return <Landing locale="en"/>; }
