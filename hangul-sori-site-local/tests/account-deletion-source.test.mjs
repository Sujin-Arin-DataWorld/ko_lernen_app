import assert from "node:assert/strict";
import test from "node:test";
import { assertDeletionPageContract } from "../scripts/deletion-page-contract.mjs";
import { renderSourcePage } from "./source-render-helper.mjs";

const cases = [
  { lang: undefined, expectedLang: "de", title: "Konto und Daten löschen", subject: "Hangul Sori Konto löschen", noSend: "Beim Öffnen dieser Seite", providerScope: "Löscht weder dein Google- noch dein Apple-Konto." },
  { lang: "en", expectedLang: "en", title: "Delete account and data", subject: "Hangul Sori account deletion", noSend: "Opening this page sends nothing", providerScope: "Does not delete your Google or Apple account." },
  { lang: "ko", expectedLang: "ko", title: "계정 및 데이터 삭제", subject: "Hangul Sori 계정 삭제", noSend: "이 페이지를 여는 것만으로는", providerScope: "Google 또는 Apple 계정은 삭제하지 않습니다." },
  { lang: "fr", expectedLang: "de", title: "Konto und Daten löschen", subject: "Hangul Sori Konto löschen", noSend: "Beim Öffnen dieser Seite", providerScope: "Löscht weder dein Google- noch dein Apple-Konto." },
];

for (const { lang, expectedLang, title, subject, noSend, providerScope } of cases) {
  test(`renders the ${expectedLang} deletion request from source for lang=${lang ?? "default"}`, async () => {
    const { html } = await renderSourcePage("app/account-deletion/page.tsx", lang);
    const firstCard = html.match(/<div class="legal-card">([\s\S]*?)<\/div>/)?.[1] ?? "";

    assert.match(html, new RegExp(`<main[^>]+lang="${expectedLang}"`));
    assert.match(html, new RegExp(`<h1>${title}<\\/h1>`));
    assert.match(firstCard, /hello@hangul-sori\.com/);
    assert.match(
      firstCard,
      new RegExp(`href="mailto:hello@hangul-sori\\.com\\?subject=${encodeURIComponent(subject)}"`),
    );
    assert.match(firstCard, /Hangul Sori/);
    assert.ok(firstCard.indexOf("mailto:") < firstCard.indexOf(noSend), "request action should precede the sending explanation");
    assert.ok(html.includes(providerScope), "account scope should exclude the provider account itself");
    assertDeletionPageContract(html, { expectedLanguage: expectedLang });
  });
}

test("localizes deletion metadata using the same invalid-language fallback", async () => {
  for (const { lang, title } of cases) {
    const { loaded } = await renderSourcePage("app/account-deletion/page.tsx", lang);
    const metadata = await loaded.generateMetadata({ searchParams: Promise.resolve({ lang }) });
    assert.match(metadata.title, new RegExp(title, "i"));
    assert.equal(metadata.alternates.canonical, "/account-deletion");
    assert.match(metadata.description, /Hangul Sori/i);
  }
});

test("rejects deletion pages without the visible request action", () => {
  const missingAction = '<main lang="en"><div class="legal-card">Hangul Sori hello@hangul-sori.com</div></main>';
  const scriptOnly = '<main lang="en"><div class="legal-card">Hangul Sori hello@hangul-sori.com</div><script>"mailto:hello@hangul-sori.com?subject=Hangul%20Sori%20account%20deletion"</script></main>';

  assert.throws(() => assertDeletionPageContract(missingAction, { expectedLanguage: "en" }), /email deletion action/i);
  assert.throws(() => assertDeletionPageContract(scriptOnly, { expectedLanguage: "en" }), /email deletion action/i);
});

test("rejects a deletion action sent to the wrong mailbox", () => {
  const wrongMailbox = '<main lang="en"><div class="legal-card">Hangul Sori hello@hangul-sori.com<a href="mailto:wrong@example.com?subject=Hangul%20Sori%20account%20deletion">Delete</a></div></main>';

  assert.throws(() => assertDeletionPageContract(wrongMailbox, { expectedLanguage: "en" }), /hello@hangul-sori\.com/i);
});

test("keeps the selected privacy language in deletion links", async () => {
  const english = await renderSourcePage("app/privacy/page.tsx", "en");
  const korean = await renderSourcePage("app/privacy/page.tsx", "ko");

  assert.match(english.html, /href="\/account-deletion\?lang=en"[^>]*>Delete account and data<\/a>/);
  assert.match(korean.html, /href="\/account-deletion\?lang=ko"[^>]*>계정 및 데이터 삭제<\/a>/);
});
