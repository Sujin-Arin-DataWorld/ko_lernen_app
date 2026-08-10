import type { Metadata } from "next";
import { Landing } from "./site";

export const metadata: Metadata = {
  alternates: {
    canonical: "/de",
    languages: { "de-DE": "/de", en: "/en", ko: "/ko", "x-default": "/de" },
  },
};

export default function Home(){ return <Landing locale="de"/>; }
