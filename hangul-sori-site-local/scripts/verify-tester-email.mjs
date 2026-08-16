import assert from "node:assert/strict";

if (!process.argv.includes("--send")) {
  throw new Error(
    "This canary sends one real tester email. Re-run it with --send only when that is intended.",
  );
}

const originArgument = process.argv.find(
  (argument) => argument !== "--send" && /^https:\/\//i.test(argument),
);
const origin = new URL(originArgument ?? "https://hangul-sori.com").origin;
const submittedAt = new Date().toISOString();
const response = await fetch(`${origin}/api/tester-application`, {
  method: "POST",
  redirect: "manual",
  signal: AbortSignal.timeout(20_000),
  headers: {
    "content-type": "application/json",
    "origin": origin,
    "user-agent": "hangul-sori-email-canary/1.0",
    "x-hangul-sori-form": "tester-application",
  },
  body: JSON.stringify({
    locale: "en",
    name: "Hangul Sori Release Canary",
    email: "hello@hangul-sori.com",
    platform: "ios",
    device: "Automated production verification",
    osVersion: "N/A",
    explanationLanguage: "en",
    koreanLevel: "hangul-reading",
    focus: ["hangul-reading"],
    notes: `Release canary sent at ${submittedAt}. This is not a tester application.`,
    ageConfirmed: true,
    commitment: true,
    privacyAcknowledged: true,
    website: "",
  }),
});

assert.equal(
  response.status,
  201,
  `Production tester email canary failed with ${response.status}: ${await response.text()}`,
);
assert.deepEqual(await response.json(), { ok: true });

console.log(
  `Sent one tester email canary through ${origin}. Confirm its arrival in the configured tester mailbox.`,
);
