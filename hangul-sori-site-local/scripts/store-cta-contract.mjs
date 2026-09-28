import assert from "node:assert/strict";

const ANDROID_OPEN_TEST =
  "https://play.google.com/apps/testing/com.sujinarin.ko_lernen_app";

export function assertStoreAccessCtas(html, url) {
  const storeCtas = html.match(/<a[^>]*class=["']store-button["'][^>]*>/gi) ?? [];
  assert.ok(storeCtas.length >= 2, `${url} must retain the store CTAs`);

  const iosCtas = storeCtas.filter((cta) =>
    /href=["']#tester-access["']/i.test(cta),
  );
  const androidCtas = storeCtas.filter((cta) =>
    cta.includes(`href="${ANDROID_OPEN_TEST}"`) ||
    cta.includes(`href='${ANDROID_OPEN_TEST}'`),
  );

  assert.equal(
    iosCtas.length,
    androidCtas.length,
    `${url} must offer the iOS application and Android open test equally`,
  );
  assert.equal(
    iosCtas.length + androidCtas.length,
    storeCtas.length,
    `${url} must route every store CTA to its approved destination`,
  );
}
