import type { Metadata } from "next";
import { Landing } from "./site";

export const metadata: Metadata = {
  alternates: {
    canonical: "/en",
    languages: { "de-DE": "/de", en: "/en", ko: "/ko", "x-default": "/en" },
  },
};

export default function Home(){ return <Landing locale="en"/>; }
