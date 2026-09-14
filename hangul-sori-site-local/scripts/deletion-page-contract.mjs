import assert from "node:assert/strict";

const MAILBOX = "hello@hangul-sori.com";
const subjects = {
  de: "Hangul Sori Konto löschen",
  en: "Hangul Sori account deletion",
  ko: "Hangul Sori 계정 삭제",
};

function visibleMarkup(html) {
  return html.replace(/<(script|style)\b[^>]*>[\s\S]*?<\/\1>/gi, "");
}

function visibleText(html) {
  return html.replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim();
}

export function assertDeletionPageContract(html, { expectedLanguage = "de" } = {}) {
  assert.ok(subjects[expectedLanguage], `Unsupported deletion-page language: ${expectedLanguage}`);
  const markup = visibleMarkup(html);
  assert.match(markup, new RegExp(`<main\\b[^>]*\\blang=["']${expectedLanguage}["']`, "i"));

  const firstCard = markup.match(/<div\b[^>]*class=["'][^"']*\blegal-card\b[^"']*["'][^>]*>([\s\S]*?)<\/div>/i)?.[1];
  assert.ok(firstCard, "Deletion page must render a first content card.");
  const cardText = visibleText(firstCard);
  assert.match(cardText, /Hangul Sori/i, "Deletion page must visibly identify the app.");
  assert.match(cardText, /hello@hangul-sori\.com/i, "Deletion page must show the request mailbox.");

  const hrefs = [...firstCard.matchAll(/<a\b[^>]*\bhref=(["'])(.*?)\1/gi)].map((match) => match[2]);
  const mailto = hrefs.find((href) => href.toLowerCase().startsWith("mailto:"));
  assert.ok(mailto, "First content card must contain a visible email deletion action.");
  const requestUrl = new URL(mailto.replaceAll("&amp;", "&"));
  assert.equal(requestUrl.protocol, "mailto:", "Deletion request action must use mailto.");
  assert.equal(requestUrl.pathname.toLowerCase(), MAILBOX, `Deletion request action must address ${MAILBOX}.`);
  assert.equal(
    requestUrl.searchParams.get("subject"),
    subjects[expectedLanguage],
    `Deletion request action must identify Hangul Sori account deletion in ${expectedLanguage}.`,
  );
}
