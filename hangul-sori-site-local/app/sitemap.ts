import type { MetadataRoute } from "next";

export default function sitemap(): MetadataRoute.Sitemap {
  const base = "https://www.hangul-sori.com";
  return ["", "/de", "/en", "/ko", "/features", "/support", "/privacy", "/terms", "/account-deletion", "/impressum", "/press"].map((path) => ({ url: `${base}${path}`, lastModified: new Date("2026-08-10"), changeFrequency: path === "" || ["/de","/en","/ko"].includes(path) ? "weekly" : "monthly", priority: path === "" ? 1 : path.length === 3 ? 0.9 : 0.7 }));
}
