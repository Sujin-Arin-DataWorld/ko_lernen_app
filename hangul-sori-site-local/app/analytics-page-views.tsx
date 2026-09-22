"use client";

import { useEffect } from "react";
import { usePathname } from "next/navigation";

/** Notify after route commit; the consent-gated script owns sending and deduping. */
export function AnalyticsPageViews() {
  const pathname = usePathname();
  useEffect(() => {
    window.dispatchEvent(new Event("hangul-sori:page-view"));
  }, [pathname]);
  return null;
}
