import type { Metadata } from "next";
import { Landing } from "../site";

export const metadata: Metadata = {
  title: "나만의 한옥에서 배우는 한국어",
  description: "호랑이와 까치와 함께 한글, 어휘, 문법, 실생활 대화를 배워보세요. 로컬 우선, 광고 없이 첫 출시 버전은 무료입니다.",
  alternates: {
    canonical: "/ko",
    languages: { "de-DE": "/de", en: "/en", ko: "/ko", "x-default": "/de" },
  },
};

export default function KoreanHome(){ return <Landing locale="ko"/>; }
